(in-package :dgw)

(defmethod render ((self transposer))
  (when (ig:begin "##transponser")
    (when (.dirty-p *project*)
      (ig:text "* ")
      (ig:same-line))
    (awhen (.path *project*)
      (ig:text (file-namestring it))
      (ig:same-line))
    (button-toggle "▶" (.play-p *project*))
    (ig:same-line)
    (button-toggle "Loop" (.loop-p *project*))
    (ig:same-line)
    (ig:set-next-item-width (* (ig:get-font-size) 3))
    (ig:drag-float "BPM" (.bpm *project*) :format "%.2f")
    (ig:same-line)
    (let* ((io (ig:get-io))
           (framerate (c-ref io ig:im-gui-io :framerate))
           (ms (/ 1000.0  framerate)))
      (ig:text (format nil "~,3f ms/frame (~,1f FPS)" ms framerate))))
  (ig:end))
