(require 'jabber)

;; (setq jabber-username "mikmy9" ;; notice: leave off the @gmail.com
;;       jabber-server "gmail.com"     ;; this is a part of your user ID, not a part of the server you will connect to.
;;       jabber-network-server "talk.google.com"  ;; this is the actual server to connect to
;;       jabber-port 5223
;;       jabber-connection-type 'ssl)

(setq jabber-account-list
      '(
        ("mikmy9@gmail.com"
         ;; (:password . "password")
         (:network-server . "talk.google.com")
         (:connection-type . ssl))))

(setq jabber-vcard-avatars-retrieve nil)

;; (jabber-connect)


;; (setq jabber-username "mikmy9" ;; notice: leave off the @gmail.com
;;       ;; jabber-password "password"
;;       jabber-nickname "emacs"               ; nickname
;;       jabber-server "gmail.com"         ;; this is a part of your user ID, not a part of the server you will connect to.
;;       jabber-network-server "talk.google.com"  ;; this is the actual server to connect to
;;       jabber-port 5223
;;       jabber-connection-type 'ssl
;;       jabber-connection-ssl-program 'gnutls
;;       ;; jabber-use-sasl nil
;;       )

;; (defcustom jabber-allow-cleartext-password nil
;;   "If t avoid yes-or-no-p dialog that warn about ability of server
;; authentificate only by transmitting password clear over network.

;; Setting this symbol to t allow attacker get your password.
;; Be aware what you do!"
;;   :group 'jabber
;;   :type 'boolean)



(defvar growl-program "/usr/local/bin/growlnotify")
(defun growl (title message &optional id)
  (if (eq id nil)
      (start-process "growl" " growl"
                     growl-program title "-w")
    (start-process "growl" " growl"
                   growl-program title "-w" "-d" id))
  (process-send-string " growl" message)
  (process-send-string " growl" "\n")
  (process-send-eof " growl"))
;; Make jabber.el notify through growl when I get a new message
(setq jabber-message-alert-same-buffer nil)
(defun pg-jabber-growl-notify (from buf text proposed-alert)
  "(jabber.el hook) Notify of new Jabber chat messages via Growl"
  (when (or jabber-message-alert-same-buffer
            (not (memq (selected-window) (get-buffer-window-list buf))))
    (if (jabber-muc-sender-p from)
        (growl (format "(PM) %s"
                       (jabber-jid-displayname (jabber-jid-user from)))
               (format "%s: %s" (jabber-jid-resource from) text)
               (format "jabber-from-%s" (jabber-jid-resource from)))
      (growl (format "%s" (jabber-jid-displayname from))
             text "jabber-from-unknown"))))
(add-hook 'jabber-alert-message-hooks 'pg-jabber-growl-notify)
;; Same as above, for groupchats
(defun pg-jabber-muc-growl-notify (nick group buf text proposed-alert)
  "(jabber.el hook) Notify of new Jabber MUC messages via Growl"
  (when (or jabber-message-alert-same-buffer
            (not (memq (selected-window) (get-buffer-window-list buf))))
    (if nick
        (when (or jabber-muc-alert-self
                  (not (string=
                        nick (cdr (assoc group *jabber-active-groupchats*)))))
          (growl (format "%s" (jabber-jid-displayname group))
                 (format "%s: %s" nick text)
                 (format "jabber-chat-%s" (jabber-jid-displayname group))))
      (growl (format "%s" (jabber-jid-displayname group))
             text "jabber-chat-unknown"))))
(add-hook 'jabber-alert-muc-hooks 'pg-jabber-muc-growl-notify)

(provide '8macs-jabber)
