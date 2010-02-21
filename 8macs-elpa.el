;;; 8macs-elpa.el --- Install a base set of packages automatically.
 
(defvar 8macs-packages (list 'idle-highlight
			     'ruby-mode
			     'inf-ruby
			     'css-mode
			     'gist)
  "Libraries that should be installed by default.")
 
(defun 8macs-elpa-install ()
  "Install all 8macs packages that aren't installed."
  (interactive)
  (dolist (package 8macs-packages)
    (unless (or (member package package-activated-list)
                (functionp package))
      (message "Installing %s" (symbol-name package))
      (package-install package))))
 
(defun 8ms-online? ()
  "See if we're online.
 
Windows does not have the network-interface-list function, so we
just have to assume it's online."
  ;; TODO how could this work on Windows?
  (if (and (functionp 'network-interface-list)
           (network-interface-list))
      (some (lambda (iface) (unless (equal "lo" (car iface))
                         (member 'up (first (last (network-interface-info
                                                   (car iface)))))))
            (network-interface-list))
    t))
 
;; On your first run, this should pull in all the base packages.
(when (8ms-online?)
  (unless package-archive-contents (package-refresh-contents))
  (8macs-elpa-install))
 
;; Workaround for an ELPA bug that people are reporting but I've been
;; unable to reproduce:
(autoload 'paredit-mode "paredit")
 
(provide '8macs-elpa)
