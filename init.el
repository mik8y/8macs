(setq dotfiles-dir (file-name-directory
                    (or (buffer-file-name) load-file-name)))

(add-to-list 'load-path dotfiles-dir)
(add-to-list 'load-path (concat dotfiles-dir "/auto-install"))
(add-to-list 'load-path (concat dotfiles-dir "/8lisp"))
(add-to-list 'load-path (concat dotfiles-dir "/8lisp/emacs-w3m"))
(add-to-list 'load-path (concat dotfiles-dir "/8lisp/maxframe-el"))
(add-to-list 'load-path (concat dotfiles-dir "/8lisp/color-theme-6.6.0"))
(add-to-list 'load-path (concat dotfiles-dir "/8lisp/bbdb/lisp"))
(add-to-list 'load-path (concat dotfiles-dir "/8lisp/twilight-emacs"))
;; (add-to-list 'load-path (concat dotfiles-dir "/8lisp/emacs-jabber"))
(add-to-list 'load-path (concat dotfiles-dir "/8lisp/emacs-jabber-0.8.0"))
;; (add-to-list 'load-path (concat dotfiles-dir "/8lisp/jabber"))
(add-to-list 'load-path (concat dotfiles-dir "/8lisp/ecb"))
(add-to-list 'load-path (concat dotfiles-dir "/8lisp/cedet"))

(setq autoload-file (concat dotfiles-dir "loaddefs.el"))
(setq package-user-dir (concat dotfiles-dir "elpa"))
(setq custom-file (concat dotfiles-dir "custom.el"))

(load "cl")
(load "saveplace")
(load "ffap")
(load "uniquify")
(load "ansi-color")
(load "recentf")

;; Load up ELPA, the package manager

(load "package")
(package-initialize)
(load "8macs-elpa")

(load "8macs-auto-install")

;; Load up 8macs customizations
(load "8macs-system")
(load "8macs-defuns")
(load "8macs-bindings")
(load "8macs-hooks")
(load "8macs-misc")
(load "8macs-registers")
(load "8macs-bookmark")
(load "8macs-hangul")

(load "8macs-eshell")
(load "8macs-lisp")
;; (load "8macs-perl")
;; (load "8macs-ruby")
;; (load "8macs-js")
(load "8macs-whitespace")
(load "8macs-emms")
(load "8macs-erc")
(load "8macs-hideshowvis")
(load "8macs-cursor-chg")
(load "8macs-cua")
(load "8macs-ido")
(load "8macs-w3m")
(load "8macs-cedet")
(load "8macs-ecb")
(load "8macs-tabbar")
(load "8macs-diary")
(load "8macs-maxframe")
;; (load "8macs-color-theme")
(load "8macs-windmove")
(load "8macs-twitter")
(load "8macs-jabber")
;; (load "8macs-bbdb")

(load "8macs-menubar")
(load "8macs-frame")
(load "8macs-fringe")
(load "8macs-window")
(load "8macs-password")

(regen-autoloads)
(load custom-file 'noerror)
(garbage-collect)

;; You can keep system- or user-specific customizations here
(setq system-specific-config (concat dotfiles-dir system-name ".el")
      user-specific-config (concat dotfiles-dir user-login-name ".el")
      user-specific-dir (concat dotfiles-dir user-login-name))
(add-to-list 'load-path user-specific-dir)

(if (file-exists-p system-specific-config) (load system-specific-config))
(if (file-exists-p user-specific-config) (load user-specific-config))
(if (file-exists-p user-specific-dir)
    (mapc #'load (directory-files user-specific-dir nil ".*el$")))
