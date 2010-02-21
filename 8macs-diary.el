(setq diary-file (concat dotfiles-dir "diaries/diary")
      diary-file-name-prefix t
      calendar-week-start-day 1
      diary-list-include-blanks t
      )

(add-hook 'list-diary-entries-hook 'sort-diary-entries t)

;;; fancy diary
(setq view-diary-entries-initially t
      mark-diary-entries-in-calendar t
      number-of-diary-entries 7)
(add-hook 'diary-display-hook 'fancy-diary-display)
(add-hook 'today-visible-calendar-hook 'calendar-mark-today)

;;; to get rid of the ugly equal signs under the date
;; (add-hook 'fancy-diary-display-mode-hook
;;           '(lambda ()
;;              (alt-clean-equal-signs)))

;; (defun alt-clean-equal-signs ()
;;   "This function makes lines of = signs invisible."
;;   (goto-char (point-min))
;;   (let ((state buffer-read-only))
;;     (when state (setq buffer-read-only nil))
;;     (while (not (eobp))
;;       (search-forward-regexp "^=+$" nil 'move)
;;       (add-text-properties (match-beginning 0) 
;;                            (match-end 0) 
;;                            '(invisible t)))
;;     (when state (setq buffer-read-only t))))


(provide '8macs-diary)
