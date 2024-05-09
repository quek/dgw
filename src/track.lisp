(in-package :dgw)

(defmethod initialize-instance :after ((self track) &key)
  (let ((process-data (autowrap:alloc '(:struct (sb:vst-process-data))))
        (inputs (if (zerop (.nbus-audio-in self))
                    (cffi:null-pointer)
                    (autowrap:alloc '(:struct (sb:vst-audio-bus-buffers))
                                    (.nbus-audio-in self))))
        (outputs (if (zerop (.nbus-audio-out self))
                     (cffi:null-pointer)
                     (autowrap:alloc '(:struct (sb:vst-audio-bus-buffers))
                                     (.nbus-audio-out self))))
        (event-in (make-instance 'vst3-impl::event-list)))
    (setf (.process-data self) process-data)
    (setf (.event-in self) event-in)

    (setf (sb:vst-process-data.process-mode process-data)
          sb:+vst-process-modes-k-realtime+)
    (setf (sb:vst-process-data.symbolic-sample-size process-data)
          sb:+vst-symbolic-sample-sizes-k-sample32+)
    (setf (sb:vst-process-data.num-samples process-data)
          *frames-per-buffer*)
    (setf (sb:vst-process-data.num-inputs process-data)
          (.nbus-audio-in self))
    (setf (sb:vst-process-data.num-outputs process-data)
          (.nbus-audio-out self))
    (setf (sb:vst-process-data.inputs process-data)
          (autowrap:ptr inputs))
    (setf (sb:vst-process-data.outputs process-data)
          (autowrap:ptr outputs))
    (setf (sb:vst-process-data.output-parameter-changes process-data)
          (cffi:null-pointer))
    (setf (sb:vst-process-data.input-events process-data)
          (vst3-impl::ptr (.event-in self)))
    (setf (sb:vst-process-data.output-events process-data)
          (cffi:null-pointer))
    (setf (sb:vst-process-data.process-context process-data)
          (cffi:null-pointer))          ;TODO

    (unless (zerop (.nbus-audio-in self))
      (setf (sb:vst-audio-bus-buffers.num-channels inputs) 2)
      (setf (sb:vst-audio-bus-buffers.silence-flags inputs) 0)
      (let ((channels (autowrap:alloc :pointer 2)))
        (loop for i below 2
              do (setf (autowrap:c-aref channels i :pointer)
                       (autowrap:calloc :float *frames-per-buffer*)))
        (setf (sb:vst-audio-bus-buffers.vst-audio-bus-buffers-channel-buffers32 inputs)
              channels)))

    (unless (zerop (.nbus-audio-out self))
      (setf (sb:vst-audio-bus-buffers.num-channels outputs) 2)
      (setf (sb:vst-audio-bus-buffers.silence-flags outputs) 0)
      (let ((channels (autowrap:alloc :pointer 2)))
        (loop for i below 2
              do (setf (autowrap:c-aref channels i :pointer)
                       (autowrap:calloc :float *frames-per-buffer*)))
        (setf (sb:vst-audio-bus-buffers.vst-audio-bus-buffers-channel-buffers32 outputs)
              channels)))))

(defmethod all-note-off ((self track))
  ;; TODO
  ;; TODO
  ;; TODO
  (loop for track in (.tracks self)
        do (all-note-off track)))

(defmethod fader ((self track))
  (find-if (lambda (x) (typep x 'module-fader-track))
           (.modules self)))

(defmethod gain ((self track))
  (find-if (lambda (x) (typep x 'module-gain-track))
           (.modules self)))

(defmethod prepare ((self track))
  (setf (.module-wait-for self) nil)
  (prepare (.process-data self))
  (loop for module in (.modules self)
        do (prepare module))
  (loop for track in (.tracks self)
        do (prepare track)))

(defmethod prepare-event ((self track) start end loop-p)
  (let ((*process-data* (.process-data self)))
    (loop for lane in (.lanes self)
          do (prepare-event lane start end loop-p))
    (loop for track in (.tracks self)
          do (prepare-event track start end track))))

(defmethod process :around ((self track))
  (let ((*process-data* (.process-data self)))
    (call-next-method)))

(defmethod process ((self track))
  (loop with module-last = (car (last (.modules self)))
        for module in (.modules self)
        for module-wait-for = (.module-wait-for self)
        do (cond ((not (.start-p module))) ;continue
                 ((and module-wait-for
                       (not (eq module-wait-for module)))) ;continue
                 (t
                  (when module-wait-for
                    (setf (.module-wait-for self) nil))
                  (unless (.process-done module)
                    (when (wait-for-from-p module)
                      (setf (.module-wait-for self) module)
                      (loop-finish))
                    (swap-in-out *process-data*)
                    (process-connection module)
                    (process module))
                  (when (and (not (eq module module-last))
                             (wait-for-to-p module))
                    (setf (.module-wait-for self) module)
                    (loop-finish)))))
  (if (.module-wait-for self)
      self
      nil))

(defmethod module-add ((self track) module)
  (setf (.modules self)
        (append (butlast (.modules self))
                (list module)
                (last (.modules self))))
  (initialize module)
  (start module)
  (when (zerop (c-ref (ig:get-io) ig:im-gui-io :key-shift))
    (editor-open module)))

(defmethod module-delete ((self track) module)
  (terminate module)
  (setf (.modules self) (delete module (.modules self))))

(defmethod render ((self track))
  (ig:push-id self)
  (ig:button (.name self))
  (ig:pop-id))

(defmethod (setf .select-p) :after ((value (eql t)) (self track))
  (setf (.target-track *project*) self))

(defmethod terminate ((self track))
  (loop for module in (.modules self)
        do (stop module)
           (terminate module))
  (mapc #'terminate (.tracks self))
  (terminate (.process-data self)))

(defmethod track-add ((self track) track-new &key track-before)
  (setf (.tracks self)
        (if track-before
            (loop for track in (.tracks self)
                  if (eq track track-before)
                    collect track-new
                  collect track)
            (append (.tracks self) (list track-new))))
  (connect (car (last (.modules track-new)))
           (car (.modules self))
           (.process-data track-new)
           (.process-data self)))

(defmethod track-delete ((self track) track-delete)
  (setf (.tracks self) (delete track-delete (.tracks self)))
  ;; TODO connection
  )

(defmethod unselect-all-tracks ((self track))
  (setf (.select-p self) nil)
  (mapc #'unselect-all-tracks (.tracks self)))
