(in-package :utaticl.core)

(defgeneric prepare (self))
(defgeneric terminate (self &key &allow-other-keys)
  (:method ((self null) &key))
  (:method :around ((self sb-sys:system-area-pointer) &key)
    (unless (cffi:null-pointer-p self)
      (call-next-method)))
  (:method ((self list) &key)
    (loop for x in self
          do (terminate x)))
  (:method :after ((self autowrap:wrapper) &key)
    (autowrap:free self)))

(defgeneric cmd-add (project cmd-class &rest args)
  (:method ((project null) cmd-class &rest args)
    (declare (ignore args))))

(defgeneric include-p (x y)
  (:method (x y) (in-p y x))
  (:method ((x null) y) nil))

(defgeneric in-p (x y)
  (:method (x y) (include-p y x)))

(defgeneric params-prepare (module))

(defgeneric .parent (x)
  (:method ((x null))
    nil))

(defgeneric .project (x)
  (:method ((x null))))

(defgeneric realloc (x &key &allow-other-keys))

(defgeneric render (x)
  (:method ((x null))))

(defgeneric value-text (x))
