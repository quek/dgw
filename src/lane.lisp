(in-package :dgw)

(defmethod clip-add ((self lane) clip)
  (setf (.clips self)
        (sort (cons clip (.clips self))
              (lambda (x y)
                (< (.time x) (.time y))))))

(defmethod clip-delete ((self lane) clip)
  (setf (.clips self)
        (delete clip (.clips self))))

(defmethod prepare-event ((self lane) start end loop-p)
  (loop for clip in (.clips self)
        for clip-start = (.time clip)
        for clip-end = (+ clip-start (.duration clip))
        if (or (and (<= start clip-start)
                    (< clip-start end))
               (and (< start clip-end)
                    (<= clip-end end)))
          do (prepare-event start end loop-p)))
