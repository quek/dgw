(in-package :dgw)

(defmethod handle-mouse ((self arrangement))
  (let* ((io (ig:get-io))
         (mouse-pos (ig:get-mouse-pos))
         (clip-at-mouse (.clip-at-mouse self)))
    (cond ((ig:is-mouse-double-clicked ig:+im-gui-mouse-button-left+)
           (if clip-at-mouse
               (cmd-add *project* 'cmd-clip-delete :clip-id (.neko-id clip-at-mouse))
               (multiple-value-bind (time lane) (world-pos-to-time-lane self mouse-pos)
                 (setf time (time-grid-applied self time :floor))
                 (when (and (not (minusp time)) lane)
                   (cmd-add *project* 'cmd-clip-add
                            :time time :lane-id (.neko-id lane)
                            :execute-after (lambda (cmd)
                                             (edit (find-neko (.clip-id cmd))))))))))
    (zoom-x-update self io)))

(defmethod lane-height ((self arrangement) (lane lane))
  (sif (gethash lane (.lane-height-map self))
       it
       (setf it (+ (.default-lane-height self)
                   (* (c-ref (ig:get-style) ig:im-gui-style :item-spacing :y)
                      2)))))

(defmethod render ((self arrangement))
  (setf (.clip-at-mouse self) nil)

  (ig:with-begin ("##arrangement" :flags ig:+im-gui-window-flags-no-scrollbar+)
    (render-grid self)
    (ig:with-begin-child ("##canvas" :window-flags ig:+im-gui-window-flags-horizontal-scrollbar+)

      (render-time-ruler self)

      (let ((pos (ig:get-cursor-pos))
            (scroll-y (ig:get-scroll-y))
            (window-pos (ig:get-window-pos)))

        (ig:set-cursor-pos (@+ pos (@ (ig:get-scroll-x) (- scroll-y))))

        (ig:with-clip-rect ((@+ window-pos (@ .0 (- (.y pos) scroll-y 3)))
                            (@+ window-pos (ig:get-window-size)))
          (ig:begin-group)
          (render-track self (.master-track *project*))
          (ig:end-group)))

      (draw-horizontal-line (ig:get-cursor-pos))

      (let ((pos (ig:get-cursor-pos)))
        (ig:set-cursor-pos (@+ pos (@ (ig:get-scroll-x) 0.0)))
        (ig:set-next-item-shortcut (logior ig:+im-gui-mod-ctrl+ ig:+im-gui-key-t+))
        (when (ig:button "+" (@ (.offset-x self) 0.0))
          (cmd-add *project* 'cmd-track-add
                   :track-id-parent (.neko-id (.master-track *project*)))))

      (render-clip self (.master-track *project*) nil nil (.time-ruler-height self))

      (handle-mouse self))
    (shortcut-common)))

(defmethod render-clip ((self arrangement) (track track) (lane null) (clip null) y)
  (loop for lane in (.lanes track)
        do (setf y (render-clip self track lane nil y)))
  (loop for track in (.tracks track)
        do (setf y (render-clip self track nil nil y)))
  y)

(defmethod render-clip ((self arrangement) (track track) (lane lane) (clip null) y)
  (loop for clip in (.clips lane)
        do (render-clip self track lane clip y))
  ;; この 4.0 は意味わかんない
  (+ y (lane-height self lane) 4.0))

(defmethod render-clip ((self arrangement) (track track) (lane lane) (clip clip) y)
  (let* ((draw-list (ig:get-window-draw-list))
         (x1 (time-to-local-x self (.time clip)))
         (x2 (time-to-local-x self (+ (.time clip) (.duration clip))))
         (scroll-pos (@ (ig:get-scroll-x) (ig:get-scroll-y)))
         (pos1 (@ x1 y))
         (pos2 (@ x2 (+ y (lane-height self lane))))
         (window-pos (ig:get-window-pos))
         (mouse-pos (ig:get-mouse-pos)))
    (ig:set-cursor-pos pos1)
    (ig:text (format nil "  ~a" (.name clip)))

    (let ((pos1 (@+ pos1 window-pos (@- scroll-pos)))
          (pos2 (@+ pos2 window-pos (@- scroll-pos))))
      (ig:add-rect-filled draw-list
                          pos1
                          (@+ pos2 (@ .0 -1.0))
                          (.color clip)
                          :rounding 3.0)
      (when (contain-p mouse-pos pos1 pos2)
        (setf (.clip-at-mouse self) clip)))))

(defmethod render-track ((self arrangement) track)
  (ig:with-id (track)
    (draw-horizontal-line (@- (ig:get-cursor-pos) (@ (ig:get-scroll-x) 0.0)))
    (let ((pos (ig:get-cursor-pos)))
      (ig:text (format nil "  ~a" (.name track)))
      (ig:set-cursor-pos pos)
      (let ((color (color+ (.color track)
                           (if (.select-p track)
                               (color #x30 #x30 #x30 #x00)
                               (color 0 0 0 0)))))
        (ig:with-button-color (color)
          (when (ig:button "##_" (@ (.offset-x self)
                                    (lane-height self (car (.lanes track)))))
            (let ((io (ig:get-io)))
              (when (zerop (c-ref io ig:im-gui-io :key-ctrl))
                (unselect-all-tracks *project*))
              (setf (.select-p track) t))))))
    (loop for x in (.tracks track)
          do (render-track self x))))

(defmethod .track-height ((self arrangement) track)
  ;; TODO
  60.0)

(defmethod world-pos-to-time-lane ((self arrangement) pos)
  (let* ((time (world-x-to-time self (.x pos)))
         (lane (world-y-to-lane self (.y pos))))
    (values time lane)))

(defmethod world-x-to-time ((self arrangement) x)
  (+ (/ (- x (.x (ig:get-window-pos)) (.offset-x self))
        (.zoom-x self))
     (ig:get-scroll-x)))

(defmethod world-y-to-lane ((self arrangement) y)
  (let ((local-y (+ (- y (.y (ig:get-window-pos)) (.time-ruler-height self))
                    (ig:get-scroll-y))))
    (labels ((f (track height)
               (or (loop for lane in (.lanes track)
                           thereis (and (< local-y (incf height (lane-height self lane))) lane))
                   (loop for track in (.tracks track)
                           thereis (f track height)))))
      (f (.master-track *project*) 0))))
