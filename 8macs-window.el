(when window-system
  (setq frame-title-format '(buffer-file-name "%f" ("%b")))
  (tooltip-mode -1)
  (mouse-wheel-mode t)
  (blink-cursor-mode -1)
  (scroll-bar-mode -1)
  (setq global-hl-line-mode nil)
  (set-face-font 'modeline "Helvetica-11")
  )

(provide '8macs-window)
