(in-package :dgw)

(defun @ (x y)
    (list x y))

(defun @+ (&rest vec2-list)
  (labels ((add (&rest args)
             (if (endp args)
                 (list 0.0 0.0)
                 (let ((car (car args))
                       (cdr (apply #'add (cdr args))))
                   (list (+ (.x car) (.x cdr))
                         (+ (.y car) (.y cdr)))))))
    (apply #'add vec2-list)))

(defun @- (vec2 &rest vec2-list)
  (if (endp vec2-list)
      (list (- (.x vec2)) (- (.y vec2)))
      (let ((rhs (apply #'@+ vec2-list)))
        (@ (- (.x vec2) (.x rhs))
           (- (.y vec2) (.y rhs))))))

(defmethod .x ((self list))
  (car self))

(defmethod .y ((self list))
  (cadr self))

(defun color (r g b &optional (a #x80))
  (+ (* a #x1000000)
     (* b #x10000)
     (* g #x100)
     r))

(defun color+ (a b)
  (destructuring-bind (ar ag ab aa) (color-decode a)
    (destructuring-bind (br bg bb ba) (color-decode b)
      (color (min (max (+ ar br) 0) #xff)
             (min (max (+ ag bg) 0) #xff)
             (min (max (+ ab bb) 0) #xff)
             (min (max (+ aa ba) 0) #xff)))))

(defun color-decode (c)
  (list (ldb (byte 8 0) c)
        (ldb (byte 8 8) c)
        (ldb (byte 8 16) c)
        (ldb (byte 8 24) c)))

(defmacro defshortcut ((&rest key-chord) &body body)
  `(progn
     (ig:set-next-item-shortcut (logior ,@key-chord))
     (ig:push-id)
     (when (ig:button "##_" (@ ig:+flt-min+ ig:+flt-min+))
       ,@body)
     (ig:pop-id)))

(defun draw-horizontal-line (pos)
  (let* ((draw-list (ig:get-window-draw-list))
         (window-pos (ig:get-window-pos))
         (window-width (ig:get-window-width))
         (scroll-y (ig:get-scroll-y))
         (p1 (@+ pos window-pos (@ 0.0 (- scroll-y)) (@ 0.0 -3.0)))
         (p2 (@+ p1 (@ window-width 0.0))))
    (ig:add-line draw-list p1 p2 (.color-line *theme*))))

(defun error-handler (e)
  (log:error e)
  (log:error (with-output-to-string (out)
               (sb-debug:print-backtrace :stream out)))
  (when *invoke-debugger-p*
    (with-simple-restart (continue "Return from here.")
      (invoke-debugger e))))

(defun shortcut-common ()
  (defshortcut (ig:+im-gui-key-semicolon+)
    (show (.commander *project*)))
  (defshortcut (ig:+im-gui-mod-ctrl+ ig:+im-gui-key-z+)
    (cmd-add *project* 'cmd-undo))
  (defshortcut (ig:+im-gui-mod-ctrl+ ig:+im-gui-mod-shift+ ig:+im-gui-key-z+)
    (cmd-add *project* 'cmd-redo)))
