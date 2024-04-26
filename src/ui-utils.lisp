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
  (+ (* r #x1000000)
     (* g #x10000)
     (* b #x100)
     a))
