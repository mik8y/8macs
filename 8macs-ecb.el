(require 'ecb)
;; (require 'ecb-autoloads)

(provide '8macs-ecb)

(setq ecb-source-path
      '(
        ("~/8macs" "8macs")
        ("~/Documents/w8" "w8")
        ("~/w8pace" "w8pace")
        ("~/Temp" "Temp")
        ("~/Documents/Developer/tfmvn/ThinkFreeOffice" "ThinkFreeOffice Maven")
        )
      ecb-vc-enable-support t
      )
(setq ecb-tip-of-the-day nil
      ecb-auto-activate nil
      ecb-layout-name "left13"
      ecb-fix-window-size 'width
      ecb-primary-secondary-mouse-buttons 'mouse-1--C-mouse-1
      )


;; (define-key ecb-mode-map (kbd "s-1") 'ecb-goto-window-directories)
;; (define-key ecb-mode-map (kbd "s-2") 'ecb-goto-window-sources)
;; (define-key ecb-mode-map (kbd "s-3") 'ecb-goto-window-methods)
;; (define-key ecb-mode-map (kbd "s-4") 'ecb-goto-window-history)
;; (define-key ecb-mode-map (kbd "s-5") 'ecb-goto-window-compilation)
;; (define-key ecb-mode-map (kbd "s-0") 'ecb-goto-window-edit1)
