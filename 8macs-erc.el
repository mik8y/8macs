;; joining && autojoing
;; make sure to use wildcards for e.g. freenode as the actual server
;; name can be be a bit different, which would screw up autoconnect
(setq erc-nick "mik8y")
(setq erc-port 8000)
(setq erc-prompt-for-password nil)
(setq erc-server "irc.freenode.org")

;; ERC default encoding - for HanIRC
;; (setq erc-default-coding-system '(euc-kr . undecided))
;; (setq erc-echo-notices-in-minibuffer-flag t)
;; (setq erc-default-coding-system 'euc-kr)
(setq erc-encoding-coding-alist
      '(
        (".*\\.hanirc.org" . euc-kr)
        ))

(erc-autojoin-mode t)
(setq erc-autojoin-channels-alist
      '(
        ;; ("irc.freenode.net" "#emacs" "#modest" "#lisp-korea")
        ;; ("irc.hanirc.org" "#emacs" "#ubuntu" "#kldp")
        (".*\\.freenode.net" "#emacs" "#gnu" "#gcc" "#modest" "#lisp-korea")
        (".*\\.hanirc.org" "#emacs" "#ubuntu")
        ))

;; check channels
(erc-track-mode t)
(setq erc-track-exclude-types '("JOIN" "NICK" "PART" "QUIT" "MODE"
                                "324" "329" "332" "333" "353" "477"))
;; don't show any of this
(setq erc-hide-list '("JOIN" "PART" "QUIT" "NICK"))

(defun mik8y-erc-start-or-switch ()
  "Connect to ERC, or switch to last active buffer"
  (interactive)
  (if (get-buffer "irc.freenode.net:8000") ;; ERC already active?
      (erc-track-switch-buffer 1) ;; yes: switch to last active
    (when (y-or-n-p "Start ERC? ") ;; no: maybe start ERC
      (erc :server "irc.freenode.net" :port 8000 :nick "mik8y" :full-name "mik8y")
      ;; (erc :server "irc.gimp.org" :port 6667 :nick "mik8y" :full-name "mik8y")
      (erc :server "irc.ozinger.org" :port 8080 :nick "mik8y" :full-name "mik8y")
      (erc :server "irc.hanirc.org" :port 8080 :nick "mik8y" :full-name "mik8y")
      )))

;; switch to ERC with Ctrl+c e
(global-set-key (kbd "C-c e") 'mik8y-erc-start-or-switch) ;; ERC

(defvar growlnotify-command (executable-find "growlnotify") "The path to growlnotify")

(defun growl (title message)
  (start-process "growl" " growl"
                 growlnotify-command
                 title
                 "-a" "Emacs")
  (process-send-string " growl" message)
  (process-send-string " growl" "\n")
  (process-send-eof " growl"))

(defun my-erc-hook (match-type nick message)
  "Shows a growl notification, when user's nick was mentioned. If the buffer is currently not visible, makes it sticky."
  (unless (posix-string-match "^\\** *Users on #" message)
    (growl
     (concat "ERC: name mentioned on: " (buffer-name (current-buffer)))
     message
     )))

(add-hook 'erc-text-matched-hook 'my-erc-hook)

(provide '8macs-erc)