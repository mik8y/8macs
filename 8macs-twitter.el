(autoload 'twitter-get-friends-timeline "twitter"  nil t)
(autoload 'twitter-status-edit "twitter" nil t)
(add-hook 'twitter-status-edit-mode-hook 'longlines-mode)

(setq witter-include-replies t
      twitter-username "mik8y"
      ;; twitter-password "password"
      )

;; (defun kf-twitter-*-mode-hook ()
;;   (set-face-background 'twitter-header-face "dark slate grey"))
;; (add-hook 'twitter-status-edit-mode-hook 'kf-twitter-*-mode-hook)
;; (add-hook 'twitter-timeline-view-mode-hook 'kf-twitter-*-mode-hook)

(global-set-key (kbd "s-<f1>")  'twitter-get-friends-timeline)

(provide '8macs-twitter)
