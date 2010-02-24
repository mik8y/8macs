;; (require 'idle-require)
(setq idle-require-symbols '(cedet nxml-mode)) ;; <- Specify packages here.
(idle-require 'cedet) ;; <- Or like this.
(idle-require-mode 1) ;; starts loading

(provide 'idle-require)
