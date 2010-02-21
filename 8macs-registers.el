;; 8macs-registers.el --- Set up registers
(dolist (r `((?i (file . ,(concat dotfiles-dir "init.el")))
             (?b (file . ,(concat dotfiles-dir "8macs-bindings.el")))
             (?r (file . ,(concat dotfiles-dir "8macs-registers.el")))
	     (?d (file . ,(concat dotfiles-dir "8macs-defuns.el")))
	     (?m (file . ,(concat dotfiles-dir "8macs-misc.el")))
             (?e (file . ,(concat dotfiles-dir "8macs-erc.el")))
             (?s (file . ,(concat dotfiles-dir "8macs-eshell.el")))
             (?h (file . ,(concat dotfiles-dir "8macs-hangul.el")))
             (?f (file . ,(concat dotfiles-dir "8macs-frame.el")))
             (?w (file . ,(concat dotfiles-dir "8macs-window.el")))
	     ))
  (set-register (car r) (cadr r)))

(provide '8macs-registers)
;; 8macs-registers.el ends here
