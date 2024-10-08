(in-package :utaticl.core)

#|
VST_SDK/vst3sdk/public.sdk/source/vst/vstpresetfile.h

   VST 3 Preset File Format Definition
   ===================================

0   +---------------------------+
    | HEADER                    |
    | header id ('VST3')        |       4 Bytes
    | version                   |       4 Bytes (int32)
    | ASCII-encoded class id    |       32 Bytes
 +--| offset to chunk list      |       8 Bytes (int64)
 |  +---------------------------+
 |  | DATA AREA                 |<-+
 |  | data of chunks 1..n       |  |
 |  ...                       ...  |
 |  |                           |  |
 +->+---------------------------+  |
    | CHUNK LIST                |  |
    | list id ('List')          |  |    4 Bytes
    | entry count               |  |    4 Bytes (int32)
    +---------------------------+  |
    |  1..n                     |  |
    |  +----------------------+ |  |
    |  | chunk id             | |  |    4 Bytes
    |  | offset to chunk data |----+    8 Bytes (int64)
    |  | size of chunk data   | |       8 Bytes (int64)
    |  +----------------------+ |
EOF +---------------------------+

|#

(defconstant +preset-vst3-version+ 1)
(defconstant +preset-vst3-cid-pos+ 8)
(defconstant +preset-vst3-list-offset-pos+ 40)

(defmethod cid ((self preset-vst3))
  (let ((buffer (.buffer self))
        (cid (make-array 16 :element-type '(unsigned-byte 8))))
    (setf (vst3-impl::.cursor buffer) +preset-vst3-cid-pos+)
    (loop for i in '(3 2 1 0 5 4 7 6 8 9 10 11 12 13 14 15)
          for n = (parse-integer (vst3-impl::read-string buffer 2) :radix 16)
          do (setf (aref cid i) n))
    cid))

(defmethod preset-vst3-from-base64 (base64)
  (let* ((vec (qbase64:decode-string base64))
         (bstream (make-instance 'vst3-impl::bstream :buffer vec)))
    (make-instance 'preset-vst3 :buffer bstream)))

(defmethod preset-vst3-to-base64 ((self preset-vst3))
  (let ((vec (vst3-impl::.buffer (.buffer self))))
    (qbase64:encode-bytes (subseq vec 0
                                  (vst3-impl::.tail (.buffer self))))))

(defmethod preset-save ((self preset-vst3) module)
  (let ((buffer (.buffer self))
        (chunks nil))
    (setf (vst3-impl::.cursor buffer) 0)
    (setf (vst3-impl::.tail buffer) 0)
    ;; HEAD
    (vst3-impl::write-string$ buffer "VST3")
    (vst3-impl::write-integer buffer +preset-vst3-version+ 4)
    (vst3-impl::write-string$ buffer
                              (with-output-to-string (out)
                                (loop for i in '(3 2 1 0 5 4 7 6 8 9 10 11 12 13 14 15)
                                      do (format out "~2,'0X" (aref (.id module) i)))))
    (vst3-impl::write-integer buffer 0 8)
    ;; Component State
    (let ((offset (vst3-impl::.cursor buffer))
          (result (vst3-ffi::get-state (.component module) (vst3-impl::ptr buffer))))
      (case result
        (#.sb:+k-result-ok+
         (push (list "Comp" offset (- (vst3-impl::.cursor buffer) offset))
               chunks))
        (#.sb:+k-not-implemented+)      ;ignore
        (t (report "Error get-state ~d ~a ~a" result self module))))
    ;; Controller State
    (let ((offset (vst3-impl::.cursor buffer))
          (result (vst3-ffi::get-state (.controller module) (vst3-impl::ptr buffer))))
      (case result
        (#.sb:+k-result-ok+
         (push (list "Cont" offset (- (vst3-impl::.cursor buffer) offset))
               chunks))
        (#.sb:+k-not-implemented+)      ;ignore
        (t (report "Error get-state ~d ~a ~a" result self module))))
    ;; offset to chunk list
    (let ((pos (vst3-impl::.cursor buffer)))
      (setf (vst3-impl::.cursor buffer) +preset-vst3-list-offset-pos+)
      (vst3-impl::write-integer buffer pos 8)
      (setf (vst3-impl::.cursor buffer) pos))
    (vst3-impl::write-string$ buffer "List")
    (vst3-impl::write-integer buffer (length chunks) 4)
    (loop for (id offset size) in chunks
          do (vst3-impl::write-string$ buffer id)
             (vst3-impl::write-integer buffer offset 8)
             (vst3-impl::write-integer buffer size 8))))

(defmethod preset-load ((self preset-vst3) module)
  (let ((buffer (.buffer self))
        (pos 0)
        (chunks nil))
    (setf (vst3-impl::.cursor buffer) +preset-vst3-list-offset-pos+)
    (setf pos (vst3-impl::read-integer buffer 8))
    (setf (vst3-impl::.cursor buffer) pos)
    (unless (string= (vst3-impl::read-string buffer 4)
                     "List")
      (report "Invalid preset. No List. ~a ~a" self module))
    (loop repeat (vst3-impl::read-integer buffer 4) ;entry count
          do (push (list (vst3-impl::read-string buffer 4)
                         (vst3-impl::read-integer buffer 8)
                         (vst3-impl::read-integer buffer 8))
                   chunks))
    (let ((chunk (find "Comp" chunks :key #'car :test #'string=)))
      (when chunk
        (let* ((start (cadr chunk))
               (end (+ (cadr chunk) (caddr chunk)))
               (buffer (vst3-impl::bstream-subseq buffer start end)))
          (let ((result (vst3-ffi::set-state (.component module) (vst3-impl::ptr buffer))))
            (unless (= result sb:+k-result-ok+)
              (report "Error set-state ~d ~a ~a" result self module)))
          (setf (vst3-impl::.cursor buffer) 0)
          (let ((result (vst3-ffi::set-component-state (.controller module) (vst3-impl::ptr buffer))))
            (unless (or (= result sb:+k-result-ok+)
                        (= result sb:+k-not-implemented+))
              (report "Error set-component-state ~d ~a ~a" result self module))))))
    (let ((chunk (find "Cont" chunks :key #'car :test #'string=)))
      (when chunk
        (let* ((start (cadr chunk))
               (end (+ (cadr chunk) (caddr chunk)))
               (buffer (vst3-impl::bstream-subseq buffer start end)))
          (let ((result (vst3-ffi::set-state (.controller module) (vst3-impl::ptr buffer))))
            (unless (or (= result sb:+k-result-ok+)
                        (= result sb:+k-not-implemented+))
              (report "Error set-state(controller) ~d ~a ~a" result self module))))))))
