(in-package :dgw)

(defmethod initialize-instance :after ((sceen-matrix sceen-matrix) &key)
  (sceen-add sceen-matrix (make-instance 'sceen)))

(defmethod clip-playing ((sceen-matrix sceen-matrix) (lane lane))
  (loop for sceen in (.sceens sceen-matrix)
        for clip = (gethash lane (.clips sceen))
          thereis (and clip (.play-p clip) clip)))

(defmethod enqueue ((sceen-matrix sceen-matrix) (clip clip))
  (push clip (.queue sceen-matrix))
  (unless (.play-p (.project sceen-matrix))
    (setf (.play-p (.project sceen-matrix)) t)))

(defmethod .offset-x ((sceen-matrix sceen-matrix))
  (.offset-x (.arrangement (.project sceen-matrix))))

(defmethod (setf .play-p) (value (sceen-matrix sceen-matrix))
  (unless value
    (loop for sceen in (.sceens sceen-matrix)
          do (setf (.play-p sceen) nil))
    (setf (.queue sceen-matrix) nil)))

(defmethod prepare-event ((sceen-matrix sceen-matrix) start end loop-p offset-samples)
  (loop for clip in (nreverse (.queue sceen-matrix))
        for lane = (.lane clip)
        for clip-playing = (clip-playing sceen-matrix lane)
        if clip-playing
          collect (setf (.clip-next clip-playing) clip)
        else
          do (setf (.will-start clip) t))
  (setf (.queue sceen-matrix) nil)

  (loop for sceen in (.sceens sceen-matrix)
        do (prepare-event sceen start end loop-p offset-samples)))

(defmethod render ((sceen-matrix sceen-matrix))
  (ig:with-styles ((ig:+im-gui-style-var-item-spacing+ (@ .0 .0)))
    (ig:with-begin ("##sceen-matrix" :flags ig:+im-gui-window-flags-no-scrollbar+)
      (ig:with-begin-child ("##canvas" :window-flags ig:+im-gui-window-flags-horizontal-scrollbar+)
        (loop for y = .0 then (+ y (.height sceen))
              for sceen in (.sceens sceen-matrix)
              do (render-sceen sceen-matrix sceen y)
              finally (render-sceen-add-button sceen-matrix y))))))

(defmethod render-sceen ((sceen-matrix sceen-matrix) (sceen sceen) y)
  (ig:with-id (sceen)
    (ig:set-cursor-pos (@ .0 y))
    (ig:text (.name sceen))
    (render-sceen-track sceen-matrix sceen (.master-track (.project sceen-matrix))
                        (.offset-x sceen-matrix)
                        y)))

(defmethod render-sceen-add-button ((sceen-matrix sceen-matrix) y)
  (ig:set-cursor-pos (@ .0 y))
  (when (ig:button "+" (@ (.offset-x sceen-matrix) .0))
    ;; TODO commnad にする
    (sceen-add sceen-matrix (make-instance 'sceen))))

(defmethod render-sceen-track ((sceen-matrix sceen-matrix) (sceen sceen) (track track) x y)
  (ig:with-id (track)
    (ig:set-cursor-pos (@ x y))
    (let* ((lane (car (.lanes track)))
           (clip (gethash lane (.clips sceen))))
      (if clip
          (progn
            (when (ig:with-button-color ((if (.play-p clip)
                                             (.color-button-toggle-on *theme*)
                                             (.color-button-toggle-off *theme*)))
                    (ig:button (format nil "~:[▶~;■~]~a" (.play-p clip) (.name clip))))
              (if (.play-p clip)
                  (setf (.will-stop clip) t)
                  (enqueue sceen-matrix clip)))
            (when (and (ig:is-item-active)
                       (ig:is-mouse-double-clicked ig:+im-gui-mouse-button-left+))
              (edit clip)))
          (when (ig:button "+")
            ;; TODO command
            (clip-add sceen (make-instance 'clip-note) :lane lane))))
    (incf x (.width track))
    (when (.tracks-show-p track)
      (loop for each-track in (.tracks track)
            do (setf x (render-sceen-track sceen-matrix sceen each-track x y))))
    x))

(defmethod sceen-add ((sceen-matrix sceen-matrix) (sceen sceen) &key before)
  (setf (.sceen-matrix sceen) sceen-matrix)
  (if before
      (labels ((f (xs)
                 (if (endp xs)
                     nil
                     (if (eq (car xs) before)
                         (psetf (car xs) sceen
                                (cdr xs) (cons (car xs) (cdr xs)))
                         (f (cdr xs))))))
        (f (.sceens sceen-matrix)))
      (setf (.sceens sceen-matrix)
            (append (.sceens sceen-matrix) (list sceen)))))

