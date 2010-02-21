(require 'maxframe)
(defvar mik8y-fullscreen-p t "Check if fullscreen is on or off")
(setq mf-max-width 1280)  ;; Pixel width of main monitor.
(setq mf-max-height 800)  ;; Pixel height of main monitor.
(setq mf-display-padding-height 0)
(setq mf-display-padding-width 0)
(setq mf-offset-x 6)
(setq mf-offset-y 3)
(add-hook 'window-setup-hook 'maximize-frame t)

(defun 8macs-toggle-maxframe ()
  (interactive)
  (setq mik8y-fullscreen-p (not mik8y-fullscreen-p))
  (if mik8y-fullscreen-p
      (restore-frame)
    (maximize-frame)))
(global-set-key (kbd "s-<return>") '8macs-toggle-maxframe)

(provide '8macs-maxframe)
