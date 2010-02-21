(when enable-multibyte-characters   ; if this emacs is compiled with leim
  (set-language-environment "Korean")
  (prefer-coding-system 'euc-kr)
  )
(setq default-input-method "korean-hangul") ; no funky input for normal editing
(set-fontset-font "fontset-default" 'hangul '("AppleGothic" . "unicode-bmp")) ; Korean

(set-keyboard-coding-system 'utf-8)
(set-clipboard-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(setq locale-coding-system 'utf-8)
(set-selection-coding-system 'utf-8)
(setq default-input-method "korean-hangul") ; no funky input for normal editing
(setq read-quoted-char-radix 11)         ; use decimal, not octal

(provide '8macs-hangul)
