(in-package :dgw)

(defclass neko ()
  ((neko-id :initarg :neko-id :accessor .neko-id)
   (name :initarg :name :initform "" :accessor .name)
   (color :initarg :color :initform (color #x80 #x80 #x80 #x80) :accessor .color)))

(defclass project (neko)
  ((arrangement :accessor .arrangement)
   (sceen-matrix :accessor .sceen-matrix)
   (dirty-p :initform nil :accessor .dirty-p)
   (piano-roll :initform nil :accessor .piano-roll)
   (commander :accessor .commander)
   (rack :accessor .rack)
   (bpm :accessor .bpm)
   (sec-per-beat :accessor .sec-per-beat)
   (samples-per-beat :accessor .samples-per-beat)
   (cmd-queue :initform nil :accessor .cmd-queue)
   (cmd-undo-stack :initform nil :accessor .cmd-undo-stack)
   (cmd-redo-stack :initform nil :accessor .cmd-redo-stack)
   (mailbox :initform (sb-concurrency:make-mailbox) :accessor .mailbox)
   (master-track :accessor .master-track)
   (path :initform nil :accessor .path)
   (play-p :initform nil :accessor .play-p)
   (play-just-stop-p :initform nil :accessor .play-just-stop-p)
   (play-start :initarg :play-start :initform .0d0 :accessor .play-start)
   (play-end :initarg :play-end :initform .0d0 :accessor .play-end)
   (loop-start :initarg :loop-start :initform .0d0 :accessor .loop-start)
   (loop-end :initarg :loop-end :initform 16.0d0 :accessor .loop-end)
   (loop-p :initarg :loop-p :initform t :accessor .loop-p)
   (transposer :accessor .transposer)
   (target-track :initform :nil :accessor .target-track)))

(defclass show-mixin ()
  ((show-p :initarg :show-p :initform nil :accessor .show-p)))

(defclass time-ruler-mixin ()
  ((loop-selecting-p :initform nil :accessor .loop-selecting-p)
   (loop-selecting-time :initform nil :accessor .loop-selecting-time)
   (time-ruler-threshold :initform 25.0 :accessor .time-ruler-threshold)))

(defclass zoom-mixin ()
  ((zoom-x :initarg :zoom-x :initform 25.0 :accessor .zoom-x)
   (zoom-x-factor :initarg :zoom-x-factor :initform .1 :accessor .zoom-x-factor)
   (zoom-x-min :initarg :zoom-x-min :initform .1 :accessor .zoom-x-min)
   (zoom-y :initarg :zoom-y :initform 50.0 :accessor .zoom-y)
   (zoom-y-factor :initarg :zoom-y-factor :initform .1 :accessor .zoom-y-factor)
   (zoom-y-min :initarg :zoom-y-min :initform .1 :accessor .zoom-y-min)))

(defclass scroll-mixin ()
  ())

(defclass offset-mixin ()
  ())

(defclass grid-mixin ()
  ((grid-snap-p :initarg :grid-snap-p :initform t :accessor .grid-snap-p)
   (grid-unit :initarg :grid-unit :initform +grid-beat+ :accessor .grid-unit)))

(defclass view ()
  ())

(defclass report-window (show-mixin view)
  ((message :initform "" :accessor .message)))

(defclass transposer (view)
  ((project :initarg :project :accessor .project)))

(defclass arrangement (time-ruler-mixin grid-mixin offset-mixin scroll-mixin zoom-mixin view)
  ((clip-at-mouse :initform nil :accessor .clip-at-mouse)
   (clip-drag-offset :initform .0 :accessor .clip-drag-offset)
   (clip-lane-map :initform (make-hash-table) :accessor .clip-lane-map)
   (clip-renaming :initform nil :accessor .clip-renaming)
   (clip-target :initform nil :accessor .clip-target)
   (clips-selected :initform nil :accessor .clips-selected)
   (clips-dragging :initform nil :accessor .clips-dragging)
   (clips-dragging-time :initform nil :accessor .clips-dragging-time)
   (clips-dragging-duration :initform nil :accessor .clips-dragging-duration)
   (dragging-source-extern :initform nil :accessor .dragging-source-extern)
   (drag-mode :initform :move :accessor .drag-mode
              :type (member :start :move :end))
   (lane-at-mouse :initform nil :accessor .lane-at-mouse)
   (offset-group :initform 5.0 :accessor .offset-group)
   (offset-y :initform 30.0 :accessor .offset-y)
   (project :initarg :project :accessor .project)
   (range-selecting-mode :initform nil :accessor .range-selecting-mode)
   (range-selecting-pos1 :initform nil :accessor .range-selecting-pos1)
   (range-selecting-pos2 :initform nil :accessor .range-selecting-pos2)
   (time-ruler-width :initform 50.0
                     :accessor .time-ruler-width
                     :accessor .offset-x)
   (track-renaming :initform nil :accessor .track-renaming))
  ;; zoom-x は使わない
  (:default-initargs :zoom-x 1.0 :zoom-y 15.0
                     :grid-unit +grid-beat+))

(defclass sceen-matrix (view neko)
  ((clip-renaming :initform nil :accessor .clip-renaming)
   (clips-selected :initform nil :accessor .clips-selected)
   (project :accessor .project)
   (queue :initform nil :accessor .queue)
   (sceen-renaming :initform nil :accessor .sceen-renaming)
   (sceens :initform nil :accessor .sceens)))

(defclass piano-roll (time-ruler-mixin grid-mixin offset-mixin scroll-mixin zoom-mixin view)
  ((clip :initarg :clip :accessor .clip)
   (drag-mode :initform :move :accessor .drag-mode
              :type (member :start :move :end))
   (note-add-pos :initform nil :accessor .note-add-pos)
   (note-at-mouse :initform nil :accessor .note-at-mouse)
   (note-default-duration :initform 1 :accessor .note-default-duration)
   (note-drag-offset :initform .0 :accessor .note-drag-offset)
   (note-target :initform nil :accessor .note-target)
   (notes-dragging :initform nil :accessor .notes-dragging)
   (notes-dragging-time :initform nil :accessor .notes-dragging-time)
   (notes-dragging-duration :initform nil :accessor .notes-dragging-duration)
   (notes-selected :initform nil :accessor .notes-selected)
   (offset-x :initform 25.0 :accessor .offset-x)
   (offset-y :initform 30.0 :accessor .offset-y)
   (range-selecting-mode :initform nil :accessor .range-selecting-mode
                         :type (member :note :region nil))
   (range-selecting-pos1 :initform nil :accessor .range-selecting-pos1)
   (range-selecting-pos2 :initform nil :accessor .range-selecting-pos2)
   (render-first-p :initform t :accessor .render-first-p)
   (project :initarg :project :accessor .project)
   (threshold-text-hide :initform 18.0 :accessor .threshold-text-hide))
  (:default-initargs :zoom-x 25.0 :zoom-y 25.0 :zoom-y-min 5.0
                     :grid-unit +grid-beat+))

(defclass rack (view)
  ((plugin-selector :accessor .plugin-selector)
   (project :initarg :project :accessor .project)))

(defclass plugin-selector (view)
  ((plugin-infos :accessor .plugin-infos)
   (rack :initarg :rack :accessor .rack)
   (query :initform "" :accessor .query)))

(defclass track (neko)
  ((lanes :initarg :lanes :initform nil :accessor .lanes)
   (event-in :accessor .event-in)
   (modules :initform nil :accessor .modules)
   (module-wait-for :initform nil :accessor .module-wait-for)
   (nbus-audio-in :initform 1 :accessor .nbus-audio-in)
   (nbus-audio-out :initform 1 :accessor .nbus-audio-out)
   (nbus-event-in :initform 1 :accessor .nbus-event-in)
   (nbus-event-out :initform 1 :accessor .nbus-event-out)
   (parent :initarg :parent :initform nil :accessor .parent)
   (process-data :accessor .process-data)
   (select-p :initform nil :accessor .select-p)
   (tracks :initform nil :accessor .tracks)
   (tracks-show-p :initform t :accessor .tracks-show-p))
  (:default-initargs :color (color #x33 #x33 #x33)))

(defclass master-track (track)
  ((project :initarg :project :initform nil :accessor .project))
  (:default-initargs :name "MASTER"))

(defclass lane (neko)
  ((clips :initarg :clips :initform nil :accessor .clips)
   (track :initarg :track :accessor .track)
   (width :initarg :width
          :initform *default-lane-width*
          :accessor .width)))

(defclass time-thing (neko)
  ((time :initarg :time :initform 0.0d0 :accessor .time)
   (duration :initarg :duration :initform 16.0d0 :accessor .duration)))

(defclass note (time-thing)
  ((key :initarg :key :initform +c4+ :accessor .key)
   (channel :initarg :channel :initform 0 :accessor .channel)
   (seq-note :initarg :seq-note :accessor .seq-note)
   (velocity :initarg :velocity :initform .8 :accessor .velocity))
  (:default-initargs :duration 1.0d0 :color (color #x30 #xc0 #x30 #x80)))

(defmethod print-object ((self note) stream)
  (print-unreadable-object (self stream :type t :identity t)
    (format stream "~d ~d ~d"
            (.key self)
            (.time self)
            (.duration self))))

(defclass clip (time-thing)
  ((clip-next :initform nil :accessor .clip-next)
   (lane :initform nil :initarg :lane :accessor .lane)
   (play-p :initform nil :accessor .play-p)
   (sceen :initarg :sceen :initform nil :accessor .sceen)
   (seq :initarg :seq :accessor .seq)
   (will-start :initform nil :accessor .will-start)
   (will-stop :initform nil :accessor .will-stop))
  (:default-initargs :name nil :color nil))

(defclass clip-audio (clip)
  ())

(defclass clip-note (clip)
  ()
  (:default-initargs :seq (make-instance 'seq-note)))

(defclass seq (time-thing)
  ((clips :initarg :clips :initform nil :accessor .clips)))

(defclass seq-audio (seq)
  ((nchannels :initform 1 :accessor .nchannels)
   (sample-rate :initform 48000 :accessor .sample-rate)
   (data :initform (make-array 0 :element-type '(unsigned-byte 8)) :accessor .data)
   (data-original :initform nil :accessor .data-original)
   (duration-original :initform nil :accessor .duration-original)
   (path :initform nil :accessor .path)
   (waveform-cache :initform nil :accessor .waveform-cache)))

(defclass seq-note (seq)
  ((notes :initarg :notes :initform nil :accessor .notes))
  (:default-initargs :color (color #x30 #xc0 #x30 #x80)))

(defclass sceen (neko)
  ((height :initarg :height :initform 30.0 :accessor .height)
   (sceen-matrix :accessor .sceen-matrix)
   (clips :initform (make-hash-table) :accessor .clips)))

(defclass plugin-info ()
  ((id :initarg :id :accessor .id)
   (name :initarg :name :accessor .name)
   (path :initarg :path :accessor .path)
   (file-write-date :initarg :file-write-date :accessor .file-write-date)))

(defclass plugin-info-vst3 (plugin-info)
  ())

(defclass module (neko)
  ((audio-input-bus-count :initarg :audio-input-bus-count
                          :initform 0
                          :accessor .audio-input-bus-count)
   (audio-output-bus-count :initarg :audio-output-bus-count
                           :initform 0
                           :accessor .audio-output-bus-count)
   (connections :initform nil :accessor .connections)
   (editor-open-p :initform nil :accessor .editor-open-p)
   (event-input-bus-count :initarg :event-input-bus-count
                          :initform 0
                          :accessor .event-input-bus-count)
   (event-output-bus-count :initarg :event-output-bus-count
                           :initform 0
                           :accessor .event-output-bus-count)
   (id :initarg :id :accessor .id)
   (latency :initform 0 :accessor .latency)
   (latency-pdc :initform 0 :accessor .latency-pdc)
   (params :initform (make-hash-table) :accessor .params)
   (process-done :initform nil :accessor .process-done)
   (start-p :initform nil :accessor .start-p)
   (track :initarg :track :initform nil :accessor .track)))

(defclass module-vst3 (module)
  ((library :initarg :library :accessor .library)
   (host-applicaiton :reader .host-applicaiton)
   (factory :initarg :factory :accessor .factory)
   (component :initarg :conponent :initform nil :accessor .component)
   (controller :initarg :controller :initform nil :accessor .controller)
   (single-component-p :initarg :single-component-p :accessor .single-component-p)
   (audio-processor :accessor .audio-processor)
   (view :initform :nil :accessor .view)
   (hwnd :initform :nil :accessor .hwnd)
   (connection-component :initform nil :accessor .connection-component)
   (connection-controller :initform nil :accessor .connection-controller)
   (parameter-changes-in :initform (make-instance 'vst3-impl::parameter-changes)
                         :accessor .parameter-changes-in)))

(defclass module-builtin (module)
  ())

(defclass module-fader (module-builtin)
  ()
  (:default-initargs :id 'module-fader :name "Fader"
                     :audio-input-bus-count 1
                     :audio-output-bus-count 1))

(defclass module-track-mixin () ()
  (:documentation "トラック備え付け"))

(defclass module-fader-track (module-track-mixin module-fader)
  ()
  (:documentation "トラック備え付け")
  (:default-initargs :id 'module-fader-track))

(defclass module-gain (module-builtin)
  ()
  (:default-initargs :id 'module-gain :name "Gain"
                     :audio-input-bus-count 1
                     :audio-output-bus-count 1))

(defclass module-gain-track (module-track-mixin module-gain)
  ()
  (:documentation "トラック備え付け")
  (:default-initargs :id 'module-gain-track))

(defclass preset () ())

(defclass preset-vst3 (preset)
  ((buffer :initarg :buffer
           :initform (make-instance 'vst3-impl::bstream)
           :accessor .buffer)))

(defclass connection (neko)
  ((from :initarg :from :accessor .from)
   (from-bus-index :initarg :from-bus-index :initform 0 :accessor .from-bus-index)
   (from-process-data :accessor .from-process-data)
   (latency-pdc :initform 0 :accessor .latency-pdc)
   (to :initarg :to :accessor .to)
   (to-bus-index :initarg :to-bus-index :initform 0 :accessor .to-bus-index)
   (pdc-buffer :initform (make-instance 'ring-buffer :size 0) :accessor .pdc-buffer)))

(defclass param (neko)
  ((id :initarg :id :initform nil :accessor .id)
   (value :initarg :value :initform .0d0 :accessor .value)))

(defclass process-data ()
  ((bpm :accessor .bpm)
   (wrap  :accessor .wrap)
   (inputs :accessor .inputs)
   (outputs :accessor .outputs)
   (input-events :accessor .input-events)
   (output-events :accessor .output-events)
   (input-parameter-changes :accessor .input-parameter-changes)
   (output-parameter-changes :accessor .output-parameter-changes)
   (context :accessor .context)
   (notes-on :initform nil :accessor .notes-on)
   (pdc-buffer :initform nil :accessor .pdc-buffer)))

(defclass audio-bus-buffers ()
  ((ptr :accessor .ptr)
   (nbuses :initarg :nbuses :initform 1 :accessor .nbuses)))

(defclass audio-device-window (view)
  ((api :initform nil :accessor .api)
   (name :initform nil :accessor .name)
   (host-apis :initform nil :accessor .host-apis)
   (device-infos :initform nil :accessor .device-infos)
   (sample-rate :initform nil :accessor .sample-rate)
   (supported-standard-sample-reates :initform nil
                                     :accessor .supported-standard-sample-reates)))

(defclass color-window (show-mixin view)
  ((neko :initform nil :accessor .neko)
   (color-before :accessor .color-before)))

(defclass commander (show-mixin)
  ((project :initarg :project :accessor .project)
   (query :initform "" :accessor .query)))

(defclass audio-device ()
  ((device-api :initarg :device-api
               :initform "ASIO"
               :accessor .device-api)
   (device-name :initarg :device-name
                :initform "Prism Sound USB Audio Class 2.0"
                :accessor .device-name)
   (handle :initform (cffi:foreign-alloc :pointer) :accessor .handle)
   (sample-format :initarg sample-format
                  :initform :float
                  :accessor .sample-format)
   (processing :initform nil :accessor .processing)
   (stream :initform nil :accessor .stream)
   (input-channels :initarg :input-channels
                   :initform 0
                   :type fixnum
                   :accessor .input-channels)
   (output-channels :initarg :output-channels
                    :initform 2
                    :type fixnum
                    :accessor .output-channels)
   (master-buffer :initform (list (make-array 1024 :element-type 'single-float :initial-element 0.0)
                                  (make-array 1024 :element-type 'single-float :initial-element 0.0))
                  :accessor .master-buffer)
   (statistic-enter-time :initform (get-internal-real-time)
                         :accessor .statistic-enter-time)
   (statistic-leave-time :initform (get-internal-real-time)
                         :accessor .statistic-leave-time)
   (statistic-count :initform 0 :accessor .statistic-count)
   (statistic-total-process-time :initform 0
                                 :accessor .statistic-total-process-time)
   (statistic-min-process-time :initform most-positive-fixnum
                               :accessor .statistic-min-process-time)
   (statistic-max-process-time :initform 0
                               :accessor .statistic-max-process-time)
   (statistic-total-interval-time :initform 0
                                  :accessor .statistic-total-interval-time)
   (statistic-min-interval-time :initform most-positive-fixnum
                                :accessor .statistic-min-interval-time)
   (statistic-max-interval-time :initform 0
                                :accessor .statistic-max-interval-time)
   (statistic-summary :initform ""
                      :accessor .statistic-summary)))

(defclass app ()
  ((audio-device :initform nil :accessor .audio-device)
   (audio-device-window :initform (make-instance 'audio-device-window)
                        :accessor .audio-device-window)
   (color-window :initform (make-instance 'color-window)
                 :accessor .color-window)
   (drop-files :initform nil :accessor .drop-files)
   (dragging-p :initform nil :accessor .dragging-p)
   (mutex :initform (sb-thread:make-mutex :name "APP") :accessor .mutex)
   (projects :initform nil :accessor .projects)
   (render-audio-device-window-p :initform nil :accessor .render-audio-device-window-p)
   (window :initarg :window :accessor .window)))
