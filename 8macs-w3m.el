(autoload 'w3m "w3m" nil t)
(autoload 'w3m-browse-url "w3m" nil t)
(if (= emacs-major-version 23)
    (require 'w3m-ems)
  (require 'w3m))

;; (setq w3m-fill-column 120)
 
;; Set this to whatever browser you use
;; (setq browse-url-browser-function 'browse-url-firefox)
;; (setq browse-url-browser-function 'browse-default-macosx-browser)
;; (setq browse-url-browser-function 'browse-default-windows-browser)
;; (setq browse-url-browser-function 'browse-default-kde)
;; (setq browse-url-browser-function 'browse-default-epiphany)
;; (setq browse-url-browser-function 'browse-default-w3m)
;; (setq browse-url-browser-function 'browse-url-generic
;; browse-url-generic-program "~/src/conkeror/conkeror")

(provide '8macs-w3m)
