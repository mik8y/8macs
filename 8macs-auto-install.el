(require 'auto-install)

(setq auto-install-directory (concat dotfiles-dir "/auto-install/"))
;; (auto-install-update-emacswiki-package-name t)

(defalias 'aiew 'auto-install-from-emacswiki)

(provide '8macs-auto-install)
