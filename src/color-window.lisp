(in-package :utaticl.core)

(defun color-window (neko)
  (setf (.neko (.color-window *app*)) neko)
  (show (.color-window *app*))
  (ig:set-window-focus-str "Color"))

(defmethod hide :after ((color-window color-window))
  (setf (.neko color-window) nil))

(defmethod (setf .neko) :after ((neko neko) (color-window color-window))
  (setf (.color-before color-window) (.color neko)))

(defmethod render ((color-window color-window))
  (ig:with-begin ("Color" :open-p (.show-p color-window))
    (ig:color-picker4 "##color" (.color (.neko color-window))
                      :ref-col (.color-before color-window))
    (ig:set-next-item-shortcut ig:+im-gui-key-escape+)
    (when (ig:button "閉じる")
      (hide color-window))))
