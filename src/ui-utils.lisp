(in-package :dgw)

(defun @ (x y)
    (list x y))

(defun @+ (&rest vec2-list)
  (labels ((add (&rest args)
             (if (endp args)
                 (list 0.0 0.0)
                 (let ((car (car args))
                       (cdr (apply #'add (cdr args))))
                   (list (+ (car car) (car cdr))
                         (+ (cadr car) (cadr cdr)))))))
    (apply #'add vec2-list)))

(defmethod .x ((self list))
  (car self))

(defmethod .y ((self list))
  (cadr self))

(defun color (r g b &optional (a #x80))
  (+ (* a #x1000000)
     (* b #x10000)
     (* g #x100)
     r))

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
         (p1 (@+ pos window-pos (@ 0.0 -3.0)))
         (p2 (@+ p1 (@ window-width 0.0))))
    (ig:add-line draw-list p1 p2 (.color-line *theme*))))