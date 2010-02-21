(autoload 'hideshowvis-enable "hideshowvis" "Highlight foldable regions")

(dolist (hook (list 'emacs-lisp-mode-hook
                    'c++-mode-hook))
  (add-hook hook 'hideshowvis-enable))

(provide 'hideshowvis)
