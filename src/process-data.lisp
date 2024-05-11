(in-package :dgw)

(defmethod initialize-instance :after ((self process-data) &key (num-inputs 1) (num-outputs 1))
  (let ((wrap (autowrap:alloc '(:struct (sb:vst-process-data))))
        (inputs (make-instance 'audio-bus-buffers :nbuses num-inputs))
        (outputs (make-instance 'audio-bus-buffers :nbuses num-outputs))
        (input-events (make-instance 'vst3-impl::event-list))
        (output-events (make-instance 'vst3-impl::event-list))
        (input-parameter-changes (make-instance 'vst3-impl::parameter-changes))
        (output-parameter-changes (make-instance 'vst3-impl::parameter-changes))
        (context (autowrap:calloc '(:struct (sb:vst-process-context)))))
    (setf (.wrap self) wrap)
    (setf (sb:vst-process-data.process-mode wrap)
          sb:+vst-process-modes-k-realtime+)
    (setf (sb:vst-process-data.symbolic-sample-size wrap)
          sb:+vst-symbolic-sample-sizes-k-sample32+)
    (setf (sb:vst-process-data.num-samples wrap)
          *frames-per-buffer*)

    (setf (.inputs self) inputs)
    (setf (sb:vst-process-data.num-inputs wrap) num-inputs)
    (setf (sb:vst-process-data.inputs wrap) (.ptr inputs))
    (setf (.outputs self) outputs)
    (setf (sb:vst-process-data.num-outputs wrap) num-outputs)
    (setf (sb:vst-process-data.outputs wrap) (.ptr outputs))

    (setf (.input-events self) input-events)
    (vst3-impl::add-ref input-events)
    (setf (sb:vst-process-data.input-events wrap) (vst3-impl::ptr input-events))
    (setf (.output-events self) output-events)
    (vst3-impl::add-ref output-events)
    (setf (sb:vst-process-data.output-events wrap) (vst3-impl::ptr output-events))

    (setf (.input-parameter-changes self) input-parameter-changes)
    (vst3-impl::add-ref input-parameter-changes)
    (setf (sb:vst-process-data.input-parameter-changes wrap) (vst3-impl::ptr input-parameter-changes))
    (setf (.output-parameter-changes self) output-parameter-changes)
    (vst3-impl::add-ref output-parameter-changes)
    (setf (sb:vst-process-data.output-parameter-changes wrap) (vst3-impl::ptr output-parameter-changes))

    (setf (.context self) context)
    (setf (sb:vst-process-data.process-context wrap) (autowrap:ptr context))
    (setf (sb:vst-process-context.state context) 0)
    (setf (sb:vst-process-context.sample-rate context) *sample-rate*)
    (setf (sb:vst-process-context.time-sig-numerator context) 4)
    (setf (sb:vst-process-context.time-sig-denominator context) 4)

    (sb-ext:finalize self (lambda ()
                            (log:trace "process-data finalize free" wrap)
                            (autowrap:free context)
                            (autowrap:free wrap)
                            (vst3-impl::release input-events)
                            (vst3-impl::release output-events)
                            (vst3-impl::release input-parameter-changes)
                            (vst3-impl::release output-parameter-changes)))))


(defmethod p ((self sb:vst-process-data))
  (flet ((f (label audio-bus-buffer nbuses)
           (let ((ptr (sb:vst-audio-bus-buffers.vst-audio-bus-buffers-channel-buffers32 audio-bus-buffer)))
             (unless (autowrap:wrapper-null-p ptr)
               (loop for i below nbuses
                     do (format t "~a ~b" label (sb:vst-audio-bus-buffers.silence-flags audio-bus-buffer))
                        (loop for j below 10
                              with p = (autowrap:c-aref ptr i :pointer)
                              do (format t " ~2f" (autowrap:c-aref p j :float)))
                        (terpri))))))
    (f "in" (sb:vst-process-data.inputs* self) (sb:vst-process-data.num-inputs self))
    (f "out" (sb:vst-process-data.outputs* self) (sb:vst-process-data.num-outputs self))))

(defmethod prepare ((self process-data))
  (prepare (.inputs self))
  (prepare (.outputs self))
  (prepare (.input-events self))
  (prepare (.output-events self))
  (prepare (.input-parameter-changes self))
  (prepare (.output-parameter-changes self)))

(defmethod note-off ((self process-data) key channel velocity sample-offset)
  (autowrap:with-alloc (event '(:struct (sb:vst-event)))
    (setf (sb:vst-event.bus-index event) 0) ;TODO
    (setf (sb:vst-event.sample-offset event) sample-offset)
    (setf (sb:vst-event.ppq-position event) .0d0) ;TODO
    (setf (sb:vst-event.flags event) sb:+vst-event-event-flags-k-is-live+) ;TODO
    (setf (sb:vst-event.type event) sb:+vst-event-event-types-k-note-off-event+)
    (setf (sb:vst-event.vst-event-note-off.channel event) channel)
    (setf (sb:vst-event.vst-event-note-off.pitch event) key)
    (setf (sb:vst-event.vst-event-note-off.velocity event) velocity)
    (setf (sb:vst-event.vst-event-note-off.note-id event) -1)
    (setf (sb:vst-event.vst-event-note-off.tuning event) .0)
    (vst3-impl::add-event (.input-events self) (autowrap:ptr event)))
  (setf (.notes-on self) (delete key (.notes-on self) :test #'equal))
  (values))

(defmethod note-off-all ((self process-data))
  (loop for (key . channel) in (.notes-on self)
        do (note-off self key channel 1 0))
  (setf (.notes-on self) nil))

(defmethod note-on ((self process-data) key channel velocity sample-offset)
  (autowrap:with-alloc (event '(:struct (sb:vst-event)))
    (setf (sb:vst-event.bus-index event) 0) ;TODO
    (setf (sb:vst-event.sample-offset event) sample-offset)
    (setf (sb:vst-event.ppq-position event) .0d0) ;TODO
    (setf (sb:vst-event.flags event) sb:+vst-event-event-flags-k-is-live+) ;TODO
    (setf (sb:vst-event.type event) sb:+vst-event-event-types-k-note-on-event+)
    (setf (sb:vst-event.vst-event-note-on.channel event) channel)
    (setf (sb:vst-event.vst-event-note-on.pitch event) key)
    (setf (sb:vst-event.vst-event-note-on.tuning event) .0)
    (setf (sb:vst-event.vst-event-note-on.velocity event) velocity)
    (setf (sb:vst-event.vst-event-note-on.note-id event) -1)
    (setf (sb:vst-event.vst-event-note-on.length event) 0)
    (vst3-impl::add-event (.input-events self) (autowrap:ptr event)))
  (pushnew (cons key channel) (.notes-on self) :test #'equal)
  (values))

(defmethod swap-in-out ((self process-data))
  (let ((wrap (.wrap self)))
    (psetf (.inputs self)
           (.outputs self)
           (sb:vst-process-data.inputs wrap)
           (sb:vst-process-data.outputs wrap)
           (.outputs self)
           (.inputs self)
           (sb:vst-process-data.outputs wrap)
           (sb:vst-process-data.inputs wrap)

           (.input-events self)
           (.output-events self)
           (sb:vst-process-data.input-events wrap)
           (sb:vst-process-data.output-events wrap)
           (.output-events self)
           (.input-events self)
           (sb:vst-process-data.output-events wrap)
           (sb:vst-process-data.input-events wrap)

           (.input-parameter-changes self)
           (.output-parameter-changes self)
           (sb:vst-process-data.input-parameter-changes wrap)
           (sb:vst-process-data.output-parameter-changes wrap)
           (.output-parameter-changes self)
           (.input-parameter-changes self)
           (sb:vst-process-data.output-parameter-changes wrap)
           (sb:vst-process-data.input-parameter-changes wrap))))
