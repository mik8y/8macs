(setq initial-frame-alist
      '(
        (width . 81)  ; Width set to 81 characters
        (height . 90) ; Height set to 60 lines
        ;; (top . 0)
        ;; (left . 700)
        ;; (cursor-type . bar)
        (cursor-color . "red")
        (font . "Monaco-11")
        (alpha 100 100)
        (horizontal-scroll-bars . nil)
        (vertical-scroll-bars . nil)
        ))
(setq default-frame-alist (copy-alist initial-frame-alist))

(provide '8macs-frame)
