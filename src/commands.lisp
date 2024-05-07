(in-package :dgw)

(defmacro defcommand (name super slots &optional class-options)
  `(defclass ,name ,super
     ,slots
     ,@(when class-options `(, class-options))))

(defclass command ()
  ((undo-p :initarg :undo-p :initform t :accessor .undo-p)
   (execute-after :initarg :execute-after :initform nil :accessor .execute-after)))

(defmethod execute :after ((self command))
  (let ((f (.execute-after self)))
    (when f
      (setf (.execute-after self) nil)
      (funcall f self))))

(defmethod redo ((self command))
  (execute self))

(defcommand cmd-clip-add (command)
  ((time :initarg :time :accessor .time)
   (lane-id :initarg :lane-id :accessor .lane-id)
   (clip-id :accessor .clip-id)))

(defmethod execute ((self cmd-clip-add))
  (let ((lane (find-lane *project* (.lane-id self)))
        (clip (make-instance 'clip-note :time (.time self))))
    (setf (.clip-id self) (.neko-id clip))
    (clip-add lane clip)))

(defmethod undo ((self cmd-clip-add))
  (let* ((lane (find-lane *project* (.lane-id self)))
         (clip (find (.clip-id self) (.clips lane)
                     :key #'.neko-id :test #'equal)))
    (clip-delete lane clip)
    (swhen (.piano-roll *project*)
      (when (and it (eq clip (.clip it)))
        (setf it nil)))))

(defcommand cmd-module-add (command)
  ((track-id :initarg :track-id :accessor .track-id)
   (plugin-info :initarg :plugin-info :accessor .plugin-info)))

(defmethod execute ((self cmd-module-add))
  (let ((track (find-track *project* (.track-id self)))
        (module (plugin-load (.plugin-info self))))
    (module-add track module)))

(defcommand cmd-note-add (command)
  ((clip-id :initarg :clip-id :accessor .clip-id)
   (time :initarg :time :accessor .time)
   (key :initarg :key :accessor .key)
   (note-id :accessor .note-id)))

(defmethod execute ((self cmd-note-add))
  (let ((clip (find-neko (.clip-id self)))
        (note (make-instance 'note :time (.time self) :key (.key self))))
    (setf (.note-id self) (.neko-id note))
    (note-add clip note)))

(defmethod undo ((self cmd-note-add))
  (let* ((clip (find-neko (.clip-id self)))
         (note (find-neko (.note-id self))))
    (note-delete clip note)))

(defcommand cmd-module-delete (command)
  ((track-id :initarg :track-id :accessor .track-id)
   (module-id :initarg :module-id :accessor .module-id)))

(defmethod execute ((self cmd-module-delete))
  (let* ((track (find-track *project* (.track-id self)))
        (module (find (.module-id self) (.modules track) :key #'.neko-id)))
    (module-delete track module)))

(defcommand cmd-plugin-scan (command)
  ())

(defmethod execute ((self cmd-plugin-scan))
  (let ((path (merge-pathnames "user/config/plugins.lisp" *working-directory*)))
    (with-open-file (out path :direction :output :if-exists :supersede)
      (loop for plugin-info in (vst3::plugin-scan-vst3)
            do (write (serialize plugin-info) :stream out)
               (terpri out)))))

(defcommand cmd-redo (command)
  ()
  (:default-initargs :undo-p nil))

(defmethod execute ((self cmd-redo))
  (cmd-redo *project*))

(defcommand cmd-track-add (command)
  ((track-id-before :initarg :track-id-before
                    :initform nil
                    :accessor .track-id-before)
   (track-id-new :accessor .track-id-new)
   (track-id-parent :initarg :track-id-parent
                    :accessor .track-id-parent)))

(defmethod execute ((self cmd-track-add))
  (let ((track-before (find-neko (.track-id-before self)))
        (track-new (make-instance 'track :name (track-name-new *project*)))
        (track-parent (find-neko (.track-id-parent self))))
    (setf (.track-id-new self) (.neko-id track-new))
    (track-add track-parent track-new :track-before track-before)))

(defmethod undo ((self cmd-track-add))
  (let ((track-new (find-neko (.track-id-new self)))
        (track-parent (find-neko (.track-id-parent self))))
    (track-delete track-parent track-new))
  )

(defcommand cmd-undo (command)
  ()
  (:default-initargs :undo-p nil))

(defmethod execute ((self cmd-undo))
  (cmd-undo *project*))
