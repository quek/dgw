(defpackage :utaticl.clap
  (:use :cl :anaphora :utaticl.core))

(in-package :utaticl.clap)

(defvar *host-map* (make-hash-table :weakness :value))

(cffi:defcallback gui.resize-hints-changed :void
    ((host :pointer))
  (log:trace "gui.resize-hints-changed" host)
  (resize-hints-changed (gethash (cffi:pointer-address host) *host-map*)))

(cffi:defcallback gui.request-resize :bool
    ((host :pointer)
     (width :unsigned-int)
     (height :unsigned-int))
  (log:trace "gui.request-resize" host)
  (request-resize (gethash (cffi:pointer-address host) *host-map*)
                  width height))

(cffi:defcallback gui.request-show :bool
    ((host :pointer))
  (log:trace "gui.request-show" host)
  (editor-open (gethash (cffi:pointer-address host) *host-map*))
  t)

(cffi:defcallback gui.request-hide :bool
    ((host :pointer))
  (log:trace "gui.request-hide" host)
  (editor-close (gethash (cffi:pointer-address host) *host-map*))
  t)

(cffi:defcallback gui.closed :void
    ((host :pointer)
     (was-destroyed :bool))
  (log:trace "gui.request-closed" host)
  (closed (gethash (cffi:pointer-address host) *host-map*) was-destroyed))

(cffi:defcallback host.get-extension :pointer
    ((host :pointer)
     (extension-id :string))
  (log:trace "host.get-extension" host extension-id)
  (let ((module-clap (gethash (cffi:pointer-address host) *host-map*)))
    (cond ((equal extension-id "clap.gui")
           (autowrap:ptr (.clap-host-gui module-clap)))
          (t (cffi:null-pointer)))))

(cffi:defcallback host.request-restart :void
    ((host :pointer))
  (log:trace "host.request-restart" host))

(cffi:defcallback host.request-process :void
    ((host :pointer))
  (log:trace "host.request-process" host))

(cffi:defcallback host.request-callback :void
    ((host :pointer))
  (log:trace "host.request-callback" host))

(alexandria:define-constant +host-name+ "UTATICL" :test 'equal)
(alexandria:define-constant +host-url+ "https://github.com/quek/utaticl" :test 'equal)
(alexandria:define-constant +host-version+ "0.0.1" :test 'equal)
(defvar +window-api-win32+ (cffi:foreign-string-alloc "win32"))


(defmacro call (function &rest args-and-return-type)
  `(cffi:foreign-funcall-pointer
    ,function
    ()
    :pointer (autowrap:ptr (utaticl.core::.plugin self))
    ,@args-and-return-type))

(defun get-factory (path)
  (sb-int:with-float-traps-masked (:invalid :inexact :overflow :divide-by-zero)
    (let* ((lib (cffi:foreign-funcall "LoadLibraryA" :string path :pointer))
           (clap-entry (cffi:foreign-funcall "GetProcAddress" :pointer lib :string "clap_entry" :pointer))
           (clap-entry (clap::make-clap-plugin-entry :ptr clap-entry))
           (init (clap:clap-plugin-entry.init clap-entry)))
      (cffi:foreign-funcall-pointer init ()
                                    :string path
                                    :bool)
      (let* ((factory (cffi:foreign-funcall-pointer
                       (clap:clap-plugin-entry.get-factory clap-entry) ()
                       :string "clap.plugin-factory"
                       :pointer))
             (factory (clap::make-clap-plugin-factory :ptr factory)))
        (values factory lib)))))

;(get-factory "c:/Program Files/Common Files/CLAP/Surge Synth Team/Surge XT.clap")

(defun create-plugin (factory id)
  (sb-int:with-float-traps-masked (:invalid :inexact :overflow :divide-by-zero)
    (let ((host (autowrap:alloc 'clap:clap-host-t)))
      (setf (clap:clap-host.clap-version.major host) 1
            (clap:clap-host.clap-version.minor host) 1
            (clap:clap-host.clap-version.revision host) 10)
      (setf (clap:clap-host.name host) (sb-sys:vector-sap +host-name+))
      (setf (clap:clap-host.vendor host) (sb-sys:vector-sap +host-name+))
      (setf (clap:clap-host.url host) (sb-sys:vector-sap +host-url+))
      (setf (clap:clap-host.version host) (sb-sys:vector-sap +host-version+))
      (setf (clap:clap-host.get-extension host) (cffi:callback host.get-extension))
      (setf (clap:clap-host.request-restart host) (cffi:callback host.request-restart))
      (setf (clap:clap-host.request-process host) (cffi:callback host.request-process))
      (setf (clap:clap-host.request-callback host) (cffi:callback host.request-callback))

      (let* ((plugin (cffi:foreign-funcall-pointer
                      (clap:clap-plugin-factory.create-plugin factory) ()
                      :pointer (autowrap:ptr factory)
                      :pointer (autowrap:ptr host)
                      :string id
                      :pointer)))
        (values (clap::make-clap-plugin :ptr plugin) host)))))

(defun prepare-callbacks (module-clap)
  (let ((clap-host-gui (.clap-host-gui module-clap)))
    (setf (clap:clap-host-gui.resize-hints-changed clap-host-gui)
          (cffi:callback gui.resize-hints-changed))
    (setf (clap:clap-host-gui.request-resize clap-host-gui)
          (cffi:callback gui.request-resize))
    (setf (clap:clap-host-gui.request-show clap-host-gui)
          (cffi:callback gui.request-show))
    (setf (clap:clap-host-gui.request-hide clap-host-gui)
          (cffi:callback gui.request-hide))
    (setf (clap:clap-host-gui.closed clap-host-gui)
          (cffi:callback gui.closed))))

(defun query-audio-ports (self)
  (let ((ext (.ext-audio-ports self)))
    (if ext
        (progn
          (setf (.audio-input-bus-count self)
                (call (clap:clap-plugin-audio-ports.count ext)
                                    :bool t
                                    :unsigned-int))
          (setf (.audio-output-bus-count self)
                (call (clap:clap-plugin-audio-ports.count ext)
                                    :bool nil
                                    :unsigned-int)))
        (progn
          (setf (.audio-input-bus-count self) 0)
          (setf (.audio-output-bus-count self) 0)))))

(defun query-note-ports (self)
  (let ((ext (.ext-note-ports self)))
    (if ext
        (progn
          (setf (.event-input-bus-count self)
                (call (clap:clap-plugin-note-ports.count ext)
                                    :bool t
                                    :unsigned-int))
          (setf (.event-output-bus-count self)
                (call (clap:clap-plugin-note-ports.count ext)
                                    :bool nil
                                    :unsigned-int)))
        (progn
          (setf (.event-input-bus-count self) 0)
          (setf (.event-output-bus-count self) 0)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(in-package :utaticl.core)

(defmethod initialize-instance :after ((self module-clap) &key id plugin-info-clap)
  (when (and id (not plugin-info-clap))
    (setf plugin-info-clap
          (loop for plugin-info in (plugin-info-load-all)
                  thereis (and (equal id (.id plugin-info))
                               plugin-info))))
  (when plugin-info-clap
    (multiple-value-bind (factory library)
        (utaticl.clap::get-factory (.path plugin-info-clap))
      (multiple-value-bind (plugin host)
          (utaticl.clap::create-plugin factory (.id plugin-info-clap))
        (setf (gethash (cffi:pointer-address (autowrap:ptr host))
                       utaticl.clap::*host-map*)
              self)
        (setf (.id self) (.id plugin-info-clap))
        (setf (.name self) (.name plugin-info-clap))
        (setf (.factory self) factory)
        (setf (.library self) library)
        (setf (.plugin self) plugin)
        (setf (.host self) host)
        (cffi:foreign-funcall-pointer
         (clap:clap-plugin.init plugin) ()
         :pointer (autowrap:ptr plugin)
         :bool)
        (flet ((extension (id make writer)
                 (let ((ptr (cffi:foreign-funcall-pointer
                             (clap:clap-plugin.get-extension plugin) ()
                             :pointer (autowrap:ptr plugin)
                             :string id
                             :pointer)))
                   (unless (cffi:null-pointer-p ptr)
                     (funcall writer (funcall make :ptr ptr) self)))))
          (extension "clap.audio-ports" #'clap::make-clap-plugin-audio-ports
                     (fdefinition '(setf .ext-audio-ports)))
          (extension "clap.gui" #'clap::make-clap-plugin-gui
                     (fdefinition '(setf .ext-gui)))
          (extension "clap.latency" #'clap::make-clap-plugin-latency
                     (fdefinition '(setf .ext-latency)))
          (extension "clap.note-ports" #'clap::make-clap-plugin-note-ports
                     (fdefinition '(setf .ext-note-ports)))
          (extension "clap.state" #'clap::make-clap-plugin-state
                     (fdefinition '(setf .ext-state))))))

    (utaticl.clap::prepare-callbacks self)

    (audio-buffer-setup self)
    (event-buffer-setup self)

    (params-prepare self)
    (params-value-changed self)))

(defmethod audio-buffer-setup ((self module-clap))
  (utaticl.clap::query-audio-ports self)
  (let* ((clap-process (.clap-process self))
         (audio-inputs (clap:clap-process.audio-inputs clap-process))
         (audio-outputs (clap:clap-process.audio-outputs clap-process)))
    (unless (autowrap:wrapper-null-p audio-inputs)
      ))
  (terminate-audio-buffer self))

(defmethod event-buffer-setup ((self module-clap))
  (utaticl.clap::query-note-ports self))

(defmethod closed ((self module-clap) was-destroyed)
  (when (.clap-window self)
    (utaticl.clap::call (clap:clap-plugin-gui.destroy (.ext-gui self))
                        :void)
    (let ((hwnd (clap:clap-window.win32 (.clap-window self))))
      (remhash (cffi:pointer-address hwnd) *hwnd-module-map*)
      (ftw:destroy-window hwnd))
    (autowrap:free (.clap-window self))
    (setf (.clap-window self) nil)))

(defmethod editor-close ((self module-clap))
  (utaticl.clap::call (clap:clap-plugin-gui.hide (.ext-gui self))
                      :bool)
  (win32::hide (clap:clap-window.win32 (.clap-window self)))
  (closed self t)
  t)

(defmethod editor-open ((self module-clap))
  (let ((ext (.ext-gui self))
        (clap-window (.clap-window self)))
    (if clap-window
        (progn
          (utaticl.clap::call (clap:clap-plugin-gui.show ext)
                              :bool)
          (win32::show (clap:clap-window.win32 clap-window))
          t)
        (when (and ext
                   (utaticl.clap::call (clap:clap-plugin-gui.is-api-supported ext)
                                       :pointer utaticl.clap::+window-api-win32+
                                       :bool nil
                                       :bool))
          (utaticl.clap::call (clap:clap-plugin-gui.create ext)
                              :pointer utaticl.clap::+window-api-win32+
                              :bool nil
                              :bool)
          (utaticl.clap::call (clap:clap-plugin-gui.set-scale ext)
                              :double 1d0
                              :bool)
          (let* ((resize-p (utaticl.clap::call (clap:clap-plugin-gui.can-resize ext)
                                               :bool))
                 (size (cffi:with-foreign-objects ((width :unsigned-int)
                                                   (height :unsigned-int))
                         (utaticl.clap::call (clap:clap-plugin-gui.get-size ext)
                                             :pointer width
                                             :pointer height
                                             :bool)
                         (@ (cffi:mem-ref width :unsigned-int)
                            (cffi:mem-ref height :unsigned-int))))
                 (hwnd (win32::make-window (.x size) (.y size) resize-p))
                 (clap-window (autowrap:alloc 'clap:clap-window-t)))
            (setf (gethash (cffi:pointer-address hwnd) *hwnd-module-map*)
                  self)
            (setf (.clap-window self) clap-window)
            (setf (clap:clap-window.api clap-window) utaticl.clap::+window-api-win32+)
            (setf (clap:clap-window.win32 clap-window) hwnd)
            (utaticl.clap::call (clap:clap-plugin-gui.set-parent ext)
                                :pointer (autowrap:ptr clap-window)
                                :bool)
            (utaticl.clap::call (clap:clap-plugin-gui.show ext)
                                :bool)
            t)))))

(defmethod on-resize ((self module-clap) width height)
  "called from wnd-proc wm-size"
  ;; TODO
  )

(defun plugin-scan-clap (&optional (dir "c:\\Program Files\\Common Files\\CLAP"))
  (loop for %path in (directory (merge-pathnames "**/*.clap" dir))
        for path = (namestring %path)
        for file-write-date = (file-write-date path)
        unless (uiop:directory-pathname-p path)
          nconc (multiple-value-bind (factory library) (utaticl.clap::get-factory path)
                  (unwind-protect
                       (loop for index below (cffi:foreign-funcall-pointer
                                              (clap:clap-plugin-factory.get-plugin-count factory)
                                              ()
                                              :pointer (autowrap:ptr factory)
                                              :unsigned-int)
                             for descriptor = (clap::make-clap-plugin-descriptor
                                               :ptr (cffi:foreign-funcall-pointer
                                                     (clap:clap-plugin-factory.get-plugin-descriptor factory)
                                                     ()
                                                     :pointer (autowrap:ptr factory)
                                                     :unsigned-int index
                                                     :pointer))
                             collect (make-instance 'plugin-info-clap
                                                    :descriptor descriptor
                                                    :path path
                                                    :file-write-date file-write-date))
                    (cffi:foreign-funcall "FreeLibrary" :pointer library :int)))))
;(mapc #'describe (plugin-scan-clap))

(defmethod request-resize ((self module-clap) width height)
  (when (.editor-open-p self)
    (ftw:set-window-pos (clap:clap-window.win32 (.clap-window self))
                        nil 0 0 width height
                        '(:no-zorder :no-move)))
  t)

(defmethod resize-hints-changed ((self module-clap))
  (autowrap:with-alloc (hints 'clap:clap-gui-resize-hints-t)
    (utaticl.clap::call (clap:clap-plugin-gui.get-resize-hints (.ext-gui self))
                        :pointer (autowrap:ptr hints)
                        :bool)
    ;; TODO なにするの？
    ))

(defmethod terminate ((self module-clap) &key)
  (closed self t)
  (utaticl.clap::call (clap:clap-plugin.destroy (.plugin self))
                      :void)
  (terminate (.clap-process self))
  (autowrap:free (.clap-host-gui self))
  (autowrap:free (.host self))
  (cffi:foreign-funcall "FreeLibrary" :pointer (.library self) :int))

(defmethod terminate ((self clap:clap-process) &key)
  (terminate (clap:clap-process.audio-inputs self)
             :count (clap:clap-process.audio-inputs-count self))
  (terminate (clap:clap-process.audio-outputs self)
             :count (clap:clap-process.audio-outputs-count self))
  ;; TODO event buffer
  (autowrap:free self))

(defmethod terminate ((self clap:clap-audio-buffer) &key count)
  "*data32 は process-data 管理"
  (loop for i below count
        for x = (autowrap:c-aref self i 'clap:clap-audio-buffer-t)
        do (autowrap:free (clap:clap-audio-buffer.data32 x)))
  (autowrap:free self))
