(in-package :utaticl.core)

(defmethod render ((self transposer))
  (when (ig:begin "##transponser")
    (when (.dirty-p (.project self))
      (ig:text "*")
      (ig:same-line))
    (awhen (.path (.project self))
      (ig:text (file-namestring it))
      (ig:same-line))
    (button-toggle "▶" (.play-p (.project self)))
    (ig:same-line)
    (button-toggle "Loop" (.loop-p (.project self)))
    (ig:same-line)
    (ig:set-next-item-width (* (ig:get-font-size) 3))
    (ig:drag-float "BPM" (.bpm (.project self)) :min 1.0 :max 999.0 :format "%.2f")
    (ig:same-line)
    (ig:text (.audio-device-name *config*))
    (ig:same-line)
    (let* ((io (ig:get-io))
           (framerate (plus-c:c-ref io ig:im-gui-io :framerate))
           (ms (/ 1000.0  framerate)))
      (ig:text (format nil "   ~,3f ms/frame (~,1f FPS)" ms framerate)))
    (ig:text (.statistic-summary (.audio-device *app*)))
    (shortcut-common (.project self)))
  (ig:end))
