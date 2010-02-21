;;; xtide-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads (xtide-calendar-setups xtide-calendar-tides xtide
;;;;;;  xtide-location-mode xtide) "xtide" "xtide.el" (19327 33497))
;;; Generated autoloads from xtide.el

(let ((loads (get 'xtide 'custom-loads))) (if (member '"xtide" loads) nil (put 'xtide 'custom-loads (cons '"xtide" loads))))

(autoload 'xtide-location-mode "xtide" "\
Go to the XTide location selection buffer.
Move point to a location and press \\[xtide-location-go] to see its tides.
\\[xtide-location-sort-distance] sorts by distance from the location at point, to find nearby places.
\\[xtide-location-sort-alphabetical] goes back to alphabetical.

Point starts at your `xtide-location' or XTIDE_DEFAULT_LOCATION,
if set.  The latitude and longitude are off to the right, move
point across with \\[move-end-of-line] to seem them (unless your window is very
wide).

\\{xtide-location-mode-map}

\(fn)" t nil)

(autoload 'xtide "xtide" "\
Display a tides graph using XTide.
If a location has been set in either `xtide-location' or the
XTIDE_DEFAULT_LOCATION environment variable, then this function
goes straight to `xtide-mode'.  If not, then `xtide-location-mode'
is used to get a location.

\(fn)" t nil)

(autoload 'xtide-calendar-tides "xtide" "\
Display tides for the calendar cursor date.
With a prefix ARG, prompt for a date to display.

\(fn &optional ARG)" t nil)

(autoload 'xtide-calendar-setups "xtide" "\
Setup xtide additions to `calendar-mode'.
This binds the `T' key in the calendar to `xtide-calendar-tides'.

This function is meant for use from `calendar-load-hook', though
doing so means you load xtide immediately on starting the
calendar.  Copying the `define-key' (and the menu one too) into
your .emacs can avoid that.

Beware also that if calendar.el has already been loaded by
something else then `calendar-load-hook' doesn't run, so make
sure you `add-hook' early enough in your .emacs file.

\(fn)" nil nil)

(custom-add-option 'calendar-load-hook 'xtide-calendar-setups)

(when (eval-when-compile (fboundp 'define-key-after)) (eval-after-load "calendar" '(let ((keymap (or (lookup-key calendar-mode-map [menu-bar moon]) (lookup-key calendar-mode-map [menu-bar Sun/Moon])))) (define-key-after keymap [xtide] '(menu-item "Tides" xtide-calendar-tides :help "View tides for the selected day using XTide.") t))))

;;;***

;;;### (autoloads nil nil ("xtide-pkg.el") (19327 33497 214404))

;;;***

(provide 'xtide-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; xtide-autoloads.el ends here
