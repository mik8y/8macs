(when window-system
  (set-fontset-font "fontset-default" 'hangul '("AppleGothic" . "unicode-bmp")) ; Korean
  ;; (set-default-font mik8y-font) ; English
  (set-fontset-font "fontset-default" 'hangul '("AppleGothic" . "unicode-bmp")) ; Korean
  ;; (set-fontset-font "fontset-default" 'kana '("Hiragino Maru Gothic Pro" . "unicode-bmp"))
  (set-fontset-font "fontset-default" 'han '("SimSun" . "unicode-bmp")) ; Chinese
  ;; (set-fontset-font "fontset-default" 'cjk-misc '("AppleGothic" . "unicode-bmp"))
  (set-face-font 'modeline "Helvetica-11")
  )

(provide '8macs-fonts)
