(in-package :dgw)

(defmethod max-bar ((self arrangement))
  ;; TODO
  8)

(defmethod render ((self arrangement))
  (when (ig:begin "##arrangement")
    (when (ig:begin-child "##canvas")
      (render-time-ruler self)
      (render-track self (.master-track *project*))
      (draw-horizontal-line (ig:get-cursor-pos))
      (ig:set-next-item-shortcut (logior ig:+im-gui-mod-ctrl+ ig:+im-gui-key-t+))
      (when (ig:button "+" (@ (.track-width self) 0.0))
        (cmd-add *project* 'cmd-track-add)))
    (ig:end-child)
    (defshortcut (ig:+im-gui-mod-ctrl+ ig:+im-gui-key-z+)
      (cmd-add *project* 'cmd-undo))
    (defshortcut (ig:+im-gui-mod-ctrl+ ig:+im-gui-mod-shift+ ig:+im-gui-key-z+)
      (cmd-add *project* 'cmd-redo)))
  (ig:end))

(defmethod render-time-ruler ((self arrangement))
  (let* ((draw-list (ig:get-window-draw-list))
         (max-bar (max-bar self))
         (window-pos (ig:get-window-pos))
         (window-size (ig:get-window-size))
         (scroll-x (ig:get-scroll-x)))
    (ig:show-demo-window (cffi:null-pointer ))
    (loop for bar from 0 to max-bar
          for x = (+ (* bar 4 (.zoom-x self))
                     (.track-width self)
                     (- scroll-x))
          for cursor-pos = (list x 0.0)
          do (ig:set-cursor-pos cursor-pos)
             (ig:text (format nil " ~d" (1+ bar)))
             (let* ((p1 (@+ cursor-pos window-pos))
                    (p2 (@+ p1 (@ 0.0 (.y window-size)))))
               (ig:add-line draw-list p1 p2 (.color-line *theme*))))))

(defmethod render-track ((self arrangement) track)
  (ig:push-id)
  (draw-horizontal-line (ig:get-cursor-pos))
  (let ((pos (ig:get-cursor-pos)))
    (ig:text (format nil "  ~a" (.name track)))
    (ig:set-cursor-pos pos)
    (let ((color (color+ (.color track)
                         (if (.select-p track)
                             (color #x30 #x30 #x30 #x00)
                             (color 0 0 0 0)))))
      (ig:push-style-color-u32 ig:+im-gui-col-button+ color)
      (ig:push-style-color-u32 ig:+im-gui-col-button-hovered+ color)
      (ig:push-style-color-u32 ig:+im-gui-col-button-active+ color)
      (when (ig:button "##_" (@ (.track-width self)
                                (.track-height self track)))
        (setf (.select-p track) (not (.select-p track))))
      (ig:pop-style-color 3)))
  (loop for x in (.tracks track)
        do (render-track self x))
  (ig:pop-id))

(defmethod .track-height ((self arrangement) track)
  ;; TODO
  60.0)
