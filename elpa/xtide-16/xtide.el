;;; xtide.el --- XTide display in Emacs

;; Copyright 2006, 2007, 2008, 2009, 2010 Kevin Ryde

;; Author: Kevin Ryde <user42@zip.com.au>
;; Version: 16
;; Keywords: calendar
;; URL: http://user42.tuxfamily.org/xtide/index.html
;; EmacsWiki: XTide

;; xtide.el is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 3, or (at your option) any later
;; version.
;;
;; xtide.el is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
;; more details.
;;
;; You can get a copy of the GNU General Public License online at
;; <http://www.gnu.org/licenses/>.
;;
;; Note that the data produced by XTide, and then shown by xtide.el, is NOT
;; FOR NAVIGATION.


;;; Commentary:

;; `M-x xtide' displays a tide height graph in Emacs using the "tide"
;; program from XTide (http://www.flaterco.com/xtide).
;;
;; `M-x calendar' is extended with a "T" key to display the tides for the
;; selected day (like "S" does for sunrise/sunset).
;;
;; The graph is a PNG image if your display supports that, otherwise XTide's
;; ascii-art fallback.  Left and right arrow keys move forward or back in
;; time.  The various alternative displays from xtide like "p" plain times
;; can be viewed too, see the mode help "C-h m" or the menu for the
;; possibilities.
;;
;; The location is taken from a customizable `xtide-location' variable, or
;; if that's not set then from the XTIDE_DEFAULT_LOCATION environment
;; variable which xtide uses.  If neither is set then M-x xtide starts in
;; the `xtide-location-mode' selector.  The "l" key goes there too, to go to
;; at a different place.  In the selector if you find a place close to what
;; you want then try "d" (`xtide-location-sort-distance') to sort by
;; distance from there.  If you've set `calendar-latitude' and
;; `calendar-longitude' for your location then try "C-u d" to sort by
;; distance from there.

;;; Install:

;; To make M-x xtide available put xtide.el in one of your `load-path'
;; directories and the following in your .emacs
;;
;;     (autoload 'xtide "xtide" nil t)
;;
;; To get the calendar mode "T" key bound when calendar loads, add
;;
;;     (autoload 'xtide-calendar-setups "xtide")
;;     (add-hook 'calendar-load-hook 'xtide-calendar-setups)
;;
;; There's autoload cookies the various functions below if you know how to
;; use `update-file-autoloads' and friends.  The docstring for
;; `xtide-calendar-setups' has notes on deferring xtide in calendar until
;; actually used.
;;
;; For reference, there's some sort of breakage in Emacs 23.1 and Gtk on
;; mode-defined menus in the menu-bar.  The XTide menu ends up either empty
;; or a copy of a menu from the mode you started M-x xtide.  This is a
;; general problem, you can see it for instance in tex-mode (start "emacs
;; -Q" then C-x C-f /tmp/x.tex and the TeX menu is lisp stuff).

;;; Emacsen:

;; Designed for Emacs 21 and up, works in XEmacs 21.  Mostly works in
;; Emacs 20 if you load cl.el for dolist and poe.el for make-temp-file.

;;; History:

;; Version 1 - the first version
;; Version 2 - interactive location selection
;; Version 3 - misc tweaks, incl read-only buffer, and font-lock on "+" marker
;; Version 4 - C-u d to sort from calendar location
;; Version 5 - namespace clean on xemacs bits
;; Version 6 - add menus
;; Version 7 - displayed position held in timezone-independent form
;;           - new location sort order "C-u a" by locality
;; Version 8 - utf8 locale fixes per report by Alan E. Davis
;; Version 9 - `xtide-run-switches' suggested by Alan E. Davis
;;           - new w/W width zoom
;; Version 10 - buttonize the tcd file in "a" mode
;; Version 11 - use pipe rather than pty for subprocesses
;; Version 12 - fixes for calendar key setups
;; Version 13 - propagate calendar date through location mode
;; Version 14 - better sort order for latin-1 location names
;; Version 15 - kill buffers on unload-feature
;; Version 16 - use easy-menu to have menus in xemacs

;;; Code:

;;-----------------------------------------------------------------------------
;; variables

;;;###autoload
(defgroup xtide nil "Xtide."
 :prefix "xtide-"
 :group 'applications
 :link  '(url-link :tag "xtide.el home page"
                   "http://user42.tuxfamily.org/xtide/index.html")
 :link  '(url-link :tag "XTide home page"
                   "http://www.flaterco.com/xtide"))

(defcustom xtide-location ""
  "The location for XTide tidal predictions.
This must be a place known to xtide.  Often just a first word or
two is enough to be unique.  If an empty string or nil then the
environment variable XTIDE_DEFAULT_LOCATION is used instead, if
that's set.

`xtide-location-mode' changes this variable as you go to
different places.  When you find one you like you can copy it to
your .emacs or save with \\[customize-variable] `xtide-location'
or \\[customize-group] xtide.  Customize will report
`xtide-location' has been changed outside the customize buffer
but clicking on Save still works."

  :type  'string
  :group 'xtide)

(defcustom xtide-run-switches nil
  "List of extra command line switches to pass to the xtide program.
You can use this for various xtide options not directly
controlled by xtide.el.  For example

    '(\"-fc\" \"SeaGreen\")

would set the flood colour to SeaGreen which is the same as the
ebb colour, if you don't want to see rising and falling tides in
contrasting colours.

You can set xtide options from your ~/.xtide.xml file too.  The
settings here override .xtide.xml (but of course only apply when
running from xtide.el).

For available options see the xtide README file or
URL `http://www.flaterco.com/xtide/settings.html'."

  :type  '(repeat string)
  :group 'xtide)

(defcustom xtide-mode-hook nil
  "*Hook run by `xtide-mode'."
  :type  'hook
  :group 'xtide)

(defcustom xtide-location-mode-hook nil
  "*Hook run by `xtide-location-mode'."
  :type  'hook
  :group 'xtide)

(defvar xtide-aspect-ratio 1.0) ;;  experimental!

;;-----------------------------------------------------------------------------
;; xemacs incompatibilities

(defun xtide-insert-image (image-spec)
  "As per Emacs `insert-image'.
IMAGE-SPEC is a list like (image :type png :data \"...\")"
  (if (eval-when-compile (fboundp 'insert-image))
      (insert-image image-spec) ;; emacs
    ;; xemacs21
    (insert " ")
    (setq image-spec (copy-sequence (cdr image-spec)))
    (let* ((type   (plist-get image-spec :type))
           (glyph  (make-glyph (apply 'vector type
                                      (plist-remprop image-spec :type))))
           (extent (make-extent (1- (point)) (point))))
        (set-extent-property extent 'end-glyph glyph))))

(eval-and-compile
  (defalias 'xtide-make-temp-file
    (if (eval-when-compile (fboundp 'make-temp-file))
        'make-temp-file   ;; emacs
      ;; xemacs21
      (autoload 'mm-make-temp-file "mm-util") ;; from gnus
      'mm-make-temp-file)))

(defun xtide-image-type-available-p (type)
  "As per Emacs `image-type-available-p'.
TYPE is a symbol like `png'."
  (cond ((eval-when-compile (fboundp 'image-type-available-p))
         (image-type-available-p type))                 ;; emacs21 up
        ((eval-when-compile (fboundp 'image-instantiator-format-list))
         (memq type (image-instantiator-format-list)))  ;; xemacs21
        (t  ;; emacs20
         nil)))

(defun xtide-display-images-p ()
  "As per Emacs `display-images-p'.
Return true if the current frame can display images."
  (if (eval-when-compile (fboundp 'display-images-p))
      (display-images-p)  ;; emacs
    window-system))       ;; xemacs21 approximation

(defalias 'xtide-string-make-unibyte
  (if (eval-when-compile (fboundp 'string-make-unibyte))
      'string-make-unibyte  ;; emacs
    'identity))             ;; not applicable in xemacs21

(defun xtide-easy-menu-help (str)
  "Return a list `(:help STR)' if easy-menu supports that, otherwise nil.
The old easymenu.el in XEmacs 21 doesn't allow :help."
  (and (eval-when-compile
         (string-match ":help\\b" (documentation 'easy-menu-define)))
       (list :help str)))


;;-----------------------------------------------------------------------------
;; new stuff in emacs22

(eval-and-compile
  (if (eval-when-compile (fboundp 'with-case-table))
      ;; emacs22 up
      (defalias 'xtide--with-case-table 'with-case-table)

    ;; emacs21, xemacs21
    (defmacro xtide--with-case-table (table &rest body)
      "Run BODY with a `set-case-table' of TABLE.
The previous case-table is restored with an `unwind-protect'."
      (let ((old-case-table (make-symbol "old-case-table")))
        `(let ((,old-case-table (current-case-table)))
           (unwind-protect
               (progn
                 (set-case-table ,table)
                 ,@body)
             (set-case-table ,old-case-table)))))))

(put 'xtide--with-case-table 'lisp-indent-function 1)


;;-----------------------------------------------------------------------------
;; misc

;; Xtide 2.9 and up follows a utf-8 locale for output, though maybe only
;; 2.9.4 prints the location listing in utf-8 correctly.  Past versions
;; always printed latin-1 irrespective of the locale.  Instead of figuring
;; out what it can or will do, the idea of `xtide-with-defanged-locale' is
;; to run in "C" locale which will get latin-1 in both past and present
;; xtide.  Xtide as of version 2.10 is latin-1 internally anyway, so nothing
;; is lost by not using utf-8.  If/when that's not so then something more
;; sophisticated could be needed.
;; 
;; Xtide 2.9.5 and up with the msdos visual compiler and without langinfo()
;; always uses codepage 1252 instead of looking at the locale, or something
;; like that.  cp1252 is a small superset of latin1 using the 8-bit control
;; chars 0x80 to 0x9F.  Xtide doesn't do anything with those extras, so it's
;; fine to read/write latin1 in that case too.
;;
;; Some .tcd files from March 2007 had some utf-8 which then came through to
;; the tide program output, but that was just a temporary balls-up with
;; them.
;;
(defmacro xtide-with-defanged-locale (&rest body)
  "Run BODY with locale forced to LANG=C etc."
  `(let ((process-environment (copy-sequence process-environment)))
     ;; probably forcing just LC_CTYPE is enough
     (setenv "LANG" "C")
     (setenv "LC_ALL" "C")
     (setenv "LC_CTYPE" "C")
     ,@body))

(defmacro xtide-with-errorfile (&rest body)
  "Create an `errorfile' for use by the BODY forms.
A local variable `errorfile' is bound to the filename of a newly
created temporary file.  An `unwind-protect' around BODY ensures
the file is removed no matter what BODY does."
  `(let ((errorfile (xtide-make-temp-file "xtide-el-")))
     (unwind-protect
         (progn ,@body)
       (delete-file errorfile))))

(defun xtide-unaccent-case-table ()
  "Return a case table downcasing latin-1 accented letters to ascii.
The effect is to sort accented characters in with unaccented.

xtide's own location display uses a more sophisticated collation
mapping (see moascf() in Dstr.cc), but this is close enough and
lets Emacs `sort-fold-case' do the work of mapping characters.

Currently for Emacs 21 this just returns `current-case-table',
since there's something fishy in the setups needed for it to sort
with a new case table."

  (cond
   ((eval-when-compile (fboundp 'put-case-table))
    ;; xemacs21
    (let ((table (copy-case-table (current-case-table)))
          (from  "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÑÒÓÔÕÖØÙÚÛÜÝàáâãäåæçèéêëìíîïñòóôõöøùúûüýÿ")
          (to    "aaaaaaaceeeeiiiinoooooouuuuyaaaaaaaceeeeiiiinoooooouuuuyy"))
      (dotimes (i (length from))
        (put-case-table 'downcase (aref from i) (aref to i) table))
      table))

   ((eval-when-compile (fboundp 'with-case-table))
    ;; emacs22 up
    ;; Could keep a table around permanently and just set-char-table-parent
    ;; each time.  But it's probably not used much, and `sort-subr' is slow
    ;; already, so it wouldn't speed anything up.
    (let* ((table (make-char-table 'case-table nil))
           (from  "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÑÒÓÔÕÖØÙÚÛÜÝàáâãäåæçèéêëìíîïñòóôõöøùúûüýÿ")
           (to    "aaaaaaaceeeeiiiinoooooouuuuyaaaaaaaceeeeiiiinoooooouuuuyy"))
      (dotimes (i (length from))
        (aset table (aref from i) (aref to i)))
      (set-char-table-parent table (current-case-table))
      table))

   (t
    ;; emacs21
    (current-case-table))))


;;-----------------------------------------------------------------------------
;; location chooser

(defconst xtide-location-buffer "*xtide-location*"
  "The xtide location buffer.")

(defun xtide-location-value ()
  "Return current `xtide-location' variable or env var.
`xtide-location' is preferred, otherwise the
XTIDE_DEFAULT_LOCATION environment variable is used, or if
neither then return nil.

An empty string in either is not returned, for an empty
customization or slightly botched XTIDE_DEFAULT_LOCATION
setup (where the user meant unset).  Leading and trailing
whitespace is stripped, so stray spaces in customize are
ignored."

  (let (ret)
    (dolist (location (list xtide-location (getenv "XTIDE_DEFAULT_LOCATION"))
                      ret)
      (when (and location (not ret))
        (if (string-match "\\`\\(\\s-\\|\n\\)+" location)
            (setq location (substring location (match-end 0))))
        (if (string-match "\\(\\s-\\|\n\\)+\\'" location)
            (setq location (substring location 0 (match-beginning 0))))
        (if (not (string-equal "" location))
            (setq ret location))))))

(defun xtide-insert-locations ()
  "Insert XTide's list of known locations into the current buffer."

  ;; -tw sets the terminal width, the value 110 here is meant to be enough
  ;; not to truncate any names.
  ;;
  ;; No redisplay because xtide-location-mode will jump to the current
  ;; xtide-location position or the start of the buffer, so no point drawing
  ;; as it comes out.
  ;;
  (xtide-with-defanged-locale
   (let ((coding-system-for-read 'iso-8859-1)
         (default-directory "/") ;; in case inherit non-existent
         (process-connection-type nil)) ;; pipe
     (call-process "tide"
                   nil           ;; input
                   (list t nil)  ;; output
                   nil           ;; no redisplay
                   "-tw" "110"
                   "-ml"))))

(defun xtide-location-sort-alphabetical (&optional arg)
  "Sort location names alphabetically.
With a \\[universal-argument] prefix, sort by locality first, so
for instance all the places \"..., Hawaii\" sort together.
\(Which assumes everything in Hawaii ends \", Hawaii\".
Try \"\\[xtide-location-sort-distance]\" by distance when you get near what you want.)

In Emacs 21 the few places with accented characters sort to the
start of the list.  Emacs 22 and XEmacs are ok."
  (interactive "P")

  ;; `sort-subr' here and in `xtide-location-sort-distance' below isn't
  ;; fantastically fast, but it's a lot easier than writing some special
  ;; code that might do better
  ;;
  ;; must load sort.el explicitly (not just the `sort-subr' autoload) to
  ;; define `sort-fold-case' before let-binding that variable, otherwise the
  ;; let makes it unbound again afterwards
  (require 'sort)

  (let* ((origin (buffer-substring (line-beginning-position)
                                   (line-end-position))))
    (goto-char (point-min))
    (when (looking-at "Location list.*\n*")
      (goto-char (match-end 0)))

    (let ((buffer-read-only nil)
          (sort-fold-case   t))
      (xtide--with-case-table (xtide-unaccent-case-table)
        (sort-subr nil 'forward-line 'end-of-line
                   (and arg 'xtide-location-sort-locality-key))))

    (set-buffer-modified-p nil)
    (goto-char (point-min))
    (search-forward origin nil t)
    (beginning-of-line)))

(defun xtide-location-sort-locality-key ()
  "Return a string for a \"by locality\" sort key.
Point should be on a location line in the `xtide-location-mode'
buffer.  The return is say \"Hawaii,Niihau Island,Nonopapa\" with
the locality first.  This is just a reverse of the
comma-separated parts.  Of course if location names aren't in
that style it won't be much good as a sort order."
  (let ((loc (downcase (xtide-location-mode-at-point))))
    ;; trailing " - READ http://..."
    ;; or       "(2)"
    ;; or       "(2) (sub)"
    ;; or       "(expired 1988-12-31)"
    ;; goes to start
    (if (string-match "\\(- READ.*\\|([^,]*)\\)\\'" loc)
        (setq loc (concat (match-string 0 loc)
                          ","
                          (substring loc 0 (match-beginning 0)))))
    ;; lose trailing spaces
    (if (string-match "\\s-+\\'" loc)
        (setq loc (substring loc 0 (match-beginning 0))))
    (mapconcat 'identity (nreverse (split-string loc "[ \t]*,[ \t]*"))
               ",")))

(defun xtide-great-circle-distance (lat1 long1 lat2 long2)
  "Return the great-circle angular distance from LAT1/LONG1 to LAT2/LONG2.
The arguments and return are in radians."
  ;; This is per http://williams.best.vwh.net/avform.htm#Dist
  ;; Shouldn't have to worry too much about accuracy near the poles or for
  ;; very close points, since there aren't many of either in the database.
  (* 2 (asin (sqrt (+ (expt (sin (* 0.5 (- lat1 lat2))) 2)
                      (* (cos lat1) (cos lat2)
                         (expt (sin (* 0.5 (- long1 long2))) 2)))))))
(put 'xtide-great-circle-distance 'pure t)

(defconst xtide-location-lat-long-regexp
  "[A-Za-z]+ +\\([0-9.]+\\). *\\([NS]\\), *\\([0-9.]+\\). *\\([EW]\\)$"
  "Pattern for latitude and longitude on a location line.
It matches for example \"Ref 33.9833° S, 151.2167° E\" as from
xtide Coordinates::print().  The \"Ref\" or \"Sub\" is included
in the match so it can be removed to get the location part
alone.")

(defun xtide-location-line-lat-long (line)
  "From an XTide location LINE, return a list (LATITUDE LONGITUDE) in radians.
LINE is a string like
    \"Botany Bay, Australia        Ref 33.9833° S, 151.2167° E\"
Latitude returned is positive for north, negative for south.
Longitude returned is positive for east, negative for west."
  (unless (string-match xtide-location-lat-long-regexp line)
    (error "Unrecognised xtide location line: %S" line))
  (let ((lat  (string-to-number (match-string 1 line)))
        (long (string-to-number (match-string 3 line))))
    (if (string-equal "S" (match-string 2 line))
        (setq lat (- lat)))
    (if (string-equal "W" (match-string 4 line))
        (setq lat (- lat)))
    (list (degrees-to-radians lat) (degrees-to-radians long))))

(defvar calendar-longitude) ;; in calendar.el
(defvar calendar-latitude)

(defun xtide-location-sort-distance (&optional arg)
  "Sort by distance from the location at point.
With a \\[universal-argument] prefix, sort by distance from `calendar-latitude' and
`calendar-longitude'.  This is good for seeing other locations
close to one you've found or close to your own location.

The sort order is angular distance as the crow flies, so places
in opposite directions along the coast will be intermixed, and
nearby offshore islands likewise mixed.  It'd be cute to follow a
coastline approximately in sequence, but that's too hard."

  (interactive "P")
  (when (or arg
            (xtide-location-mode-at-point))
    (let* (origin-lat origin-long)
      (if arg
          (if (and calendar-latitude calendar-longitude)
              (setq origin-lat  (degrees-to-radians calendar-latitude)
                    origin-long (degrees-to-radians calendar-longitude))
            (error "`calendar-latitude' and/or `calendar-longitude' not set"))

        (let* ((origin-str  (buffer-substring (line-beginning-position)
                                              (line-end-position)))
               (origin-latlong (xtide-location-line-lat-long origin-str)))
          (setq origin-lat  (car origin-latlong)
                origin-long (cadr origin-latlong))))

      (goto-char (point-min))
      (when (looking-at "Location list.*\n*")
        (goto-char (match-end 0)))

      (let ((buffer-read-only nil))
        (sort-subr nil 'forward-line 'end-of-line
                   (lambda ()
                     (let ((line (buffer-substring (point)
                                                   (line-end-position))))
                       (apply 'xtide-great-circle-distance
                              origin-lat origin-long
                              (xtide-location-line-lat-long line))))))

      (when (get-buffer-window (current-buffer))
        (set-window-start (get-buffer-window (current-buffer))
                          (point-min) t))
      (goto-char (point-min))
      (forward-line 2))))

(defun xtide-location-mode-at-point ()
  "Return the XTide location at point in a location list buffer.
Return nil if not on a location line."
  (save-excursion
    (beginning-of-line)
    (and (re-search-forward xtide-location-lat-long-regexp
                            (line-end-position) t)
         (goto-char (match-beginning 0))
         (skip-chars-backward " \t")
         (buffer-substring-no-properties (line-beginning-position) (point)))))

(defun xtide-location-go ()
  "View tides at the current location."
  (interactive)
  (let ((location (xtide-location-mode-at-point)))
    (when location
      (setq xtide-location location)
      (bury-buffer (current-buffer))
      (xtide-mode))))

(defvar xtide-location-mode-map
  (let ((m (make-sparse-keymap)))
    (define-key m "q"   'kill-this-buffer)
    (define-key m "a"   'xtide-location-sort-alphabetical)
    (define-key m "d"   'xtide-location-sort-distance)
    (define-key m "p"   'previous-line)
    (define-key m "n"   'next-line)
    (define-key m [?\r] 'xtide-location-go)
    m)
  "Keymap for `xtide-location-mode' display buffer.")

(easy-menu-define xtide-location-mode-menu
  xtide-location-mode-map "XTide Location Menu"
  `("XTide"
    ["Go" xtide-location-go
     ,@(xtide-easy-menu-help "View tides at location at point")]
    ["Sort Alphabetically" xtide-location-sort-alphabetical
     ,@(xtide-easy-menu-help  "Sort location names alphabetically")]
    ["Sort Alpha by Locality" ,(lambda ()
                                 (interactive)
                                 (xtide-location-sort-alphabetical t))
     :keys "\\[universal-argument] \\[xtide-location-sort-alphabetical]"
     ,@(xtide-easy-menu-help  "Sort location names alphabetically, by locality part first")]
    ["Sort by Distance" xtide-location-sort-distance
     ,@(xtide-easy-menu-help "Sort by distance from the location at point.")]
    ["Sort by Distance from You" ,(lambda ()
                                    (interactive)
                                    (xtide-location-sort-distance t))
     :keys "\\[universal-argument] \\[xtide-location-sort-distance]"
     ,@(xtide-easy-menu-help "Sort by distance from your location, as given by `calendar-latitude' and `calendar-longitude' (per C-u d)")]))

;;;###autoload
(defun xtide-location-mode ()
  "Go to the XTide location selection buffer.
Move point to a location and press \\[xtide-location-go] to see its tides.
\\[xtide-location-sort-distance] sorts by distance from the location at point, to find nearby places.
\\[xtide-location-sort-alphabetical] goes back to alphabetical.

Point starts at your `xtide-location' or XTIDE_DEFAULT_LOCATION,
if set.  The latitude and longitude are off to the right, move
point across with \\[move-end-of-line] to seem them (unless your window is very
wide).

\\{xtide-location-mode-map}"

  (interactive)
  (if (get-buffer xtide-location-buffer)
      (switch-to-buffer xtide-location-buffer)

    (switch-to-buffer xtide-location-buffer)
    (kill-all-local-variables)
    (setq buffer-read-only nil)
    (erase-buffer)
    (use-local-map xtide-location-mode-map)
    (easy-menu-add xtide-location-mode-menu)
    (buffer-disable-undo xtide-location-buffer)
    (setq major-mode     'xtide-location-mode
          mode-name      "XTide Location"
          truncate-lines t)

    (xtide-insert-locations)
    (goto-char (point-min))
    (set-buffer-modified-p nil)
    (setq buffer-read-only t)

    ;; start at selected location, if there is one
    (let ((location (xtide-location-value)))
      (when location
        (re-search-forward (concat "^" (regexp-quote location)) nil t)
        (beginning-of-line)))

    (message "Press `%s' to select location"
             (key-description (where-is-internal 'xtide-location-go
                                                 overriding-local-map t)))
    (run-hooks 'xtide-location-mode-hook)))


;;-----------------------------------------------------------------------------
;; location timezones

(defvar xtide-location-time-zone-cache nil
  "An alist of (LOCATION . TIME-ZONE-RULE-STRING).
Used by `xtide-location-time-zone'.

Currently this is never cleared out, on the assumption you'll
only normally look at a few places.")

(defun xtide-location-time-zone (location)
  "Return a time zone rule string for LOCATION.
The zone is found by running \"tide -ma -l LOCATION\", then
cached in `xtide-location-time-zone-cache'.  If LOCATION is
unknown then the return is nil."
  (or (cdr (assoc location xtide-location-time-zone-cache))
      (with-temp-buffer
        (setq default-directory "/") ;; in case inherit non-existent
        (message "Getting xtide timezone for %s ..." location)
        (when (eq 0 (xtide-with-defanged-locale
                     (let ((process-connection-type nil)) ;; pipe
                       (call-process "tide"
                                     nil        ;; stdin /dev/null
                                     (list t t) ;; stdout+stderr to buffer
                                     nil        ;; no redisplay
                                     "-ma" "-l" location))))
          (goto-char (point-min))
          (when (re-search-forward "^Time zone *\\(.*\\)" nil t)
            (add-to-list 'xtide-location-time-zone-cache
                         (cons location (match-string 1)))
            (match-string 1))))))


;;-----------------------------------------------------------------------------
;; tide display

(defconst xtide-buffer "*xtide*"
  "The xtide tides buffer.")

(defvar xtide-time nil
  "The start time of the XTide display.
In the current implementation this is `current-time' list format
in Greenwich Mean Time, and passed to xtide through
`format-time-string' in the timezone of the location shown.")

(defvar xtide-calendar-time nil
  "A value for `xtide-time' coming from `xtide-calendar-tides'.
This is used when `xtide-calendar-tides' goes first to
`xtide-location-mode' because `xtide-location' is not set.")

(defvar xtide-output-mode nil
  "The XTide output mode, as a string, eg. \"g\" for graph.")

(defun xtide-window-text-area-pixel-width ()
  "Return the width in pixels of the text portion of the current window.
This is `window-text-area-pixel-width' in XEmacs, or a fallback
calculation in GNU Emacs."
  (if (eval-when-compile (fboundp 'window-text-area-pixel-width))
      (window-text-area-pixel-width)        ;; xemacs
    (* (window-width) (frame-char-width)))) ;; emacs

(defun xtide-time-string (time)
  "Return TIME as a string for xtide \"-b\" argument.
TIME is a `current-time' style list in GMT.  The timezone used
for the return is local time at `xtide-location'."
  ;; This getenv and restore is similar to what add-log.el and time-stamp.el
  ;; do.  `display-time-world' instead always goes back to nil, but a
  ;; restore seems a much better idea.
  (let ((old-tz (getenv "TZ")))
    (set-time-zone-rule (or (xtide-location-time-zone (xtide-location-value))
                            old-tz))
    (unwind-protect
        (format-time-string "%Y-%m-%d %H:%M" time)
      (set-time-zone-rule old-tz))))

(defun xtide-run (time mode f-option)
  "Run xtide on TIME, MODE and F-OPTION.
TIME is a list in `current-time' format.
MODE is an xtide -m option string, like \"g\" for graph.
F-OPTION is either \"-ft\" for text, or \"-fp\" for png.
The output from xtide is inserted into the current buffer and the return
value is 0 for success or a string describing an error.  The string
includes anything xtide printed to stderr."

  (let ((status    nil)
        (old-point (point)))
    ;; in emacs 21 `with-temp-message' doesn't clear a message when
    ;; it's done, so don't use that
    (message "Running xtide...")

    ;; don't bother about redisplay, the database lookup takes a few
    ;; moments, but there's nothing printed to stdout while that's
    ;; happening
    ;;
    (xtide-with-errorfile
     (xtide-with-defanged-locale
      (let ((default-directory "/") ;; in case inherit non-existent
            (process-connection-type nil) ;; pipe
            (coding-system-for-read
             (if (equal f-option "-fp")
                 'binary       ;; png image
               'iso-8859-1)))  ;; text
        (setq status
              (apply 'call-process "tide"
                     nil                 ;; input
                     (list t errorfile)  ;; output
                     nil                 ;; no redisplay
                     ;; args
                     f-option
                     "-m"  mode
                     "-tw" (number-to-string (1- (window-width)))
                     "-gw" (number-to-string
                            (xtide-window-text-area-pixel-width))
                     "-b"  (xtide-time-string time)
                     (append
                      (and xtide-aspect-ratio
                           (list "-ga" (number-to-string xtide-aspect-ratio)))
                      (and (xtide-location-value)
                           (list "-l" (xtide-location-value)))
                      xtide-run-switches)))))

     ;; when the location is not found the exit status is still 0, but
     ;; there's nothing written to stdout
     (unless (and (eq 0 status)
                  (/= (point) old-point))
       (setq status
             (concat (with-temp-buffer
                       (let ((coding-system-for-read 'iso-8859-1))
                         (insert-file-contents errorfile))
                       (buffer-string))
                     "\n"
                     (if (stringp status)
                         status
                       (format "Exit %s" status))))))

    (message nil)
    status))

(defun xtide-run-insert-image (time)
  "Insert xtide output in PNG image format into the current buffer.
TIME is in a `current-time' style list.
If there's an error running xtide, its error message is inserted in the
buffer instead."
  (let* ((status nil)
         (image  (with-temp-buffer
                   (setq status (xtide-run time "g" "-fp"))
                   `(image :type png
                           :data ,(xtide-string-make-unibyte
                                   (buffer-string))))))
    (if (eq 0 status)
        (xtide-insert-image image)
      (insert status))))

(defun xtide-run-insert-text (time mode)
  "Insert xtide output in text format in the current buffer.
TIME is in a `current-time' style list.
MODE is an xtide -m option string, like \"g\" for graph.
If there's an error running xtide, its error message is inserted in the
buffer instead."
  (let* ((status (xtide-run time mode "-ft")))
    (unless (eq 0 status)
      (insert status))))

(defun xtide-forward-6hour ()
  "Go forward 6 hours in the tidal display."
  (interactive)
  (eval-and-compile ;; at compile time too to quieten the byte compiler
    (require 'time-date))
  ;; `time-add' is not in emacs 21 (only emacs 22), so go through floating
  ;; point seconds
  (setq xtide-time (seconds-to-time (+ (time-to-seconds xtide-time) 21600)))
  (xtide-mode-redraw))

(defun xtide-backward-6hour ()
  "Go back 6 hours in the tidal display."
  (interactive)
  (require 'time-date)
  (setq xtide-time (subtract-time xtide-time '(0 21600 0)))
  (xtide-mode-redraw))

(defun xtide-show-about-location ()
  "Show information about this tidal location.
If you've got tcd-format.el installed, and Emacs 22 button.el,
then the .tcd harmonics file shown is buttonized to go to the raw
data (press Tab then Ret)."
  (interactive)
  (setq xtide-output-mode "a")
  (xtide-mode-redraw))

(defun xtide-show-banner ()
  "Show horizontal text banner style graph of tides."
  (interactive)
  (setq xtide-output-mode "b")
  (xtide-mode-redraw))

(defun xtide-show-calendar ()
  "Show calendar of a few days tide times."
  (interactive)
  (setq xtide-output-mode "c")
  (xtide-mode-redraw))

(defun xtide-show-calendar-alternative ()
  "Show calendar of tide times, in alternative format of days in columns."
  (interactive)
  (setq xtide-output-mode "C")
  (xtide-mode-redraw))

(defun xtide-show-graph ()
  "Show tides in graph of height.
This is the default display mode."
  (interactive)
  (setq xtide-output-mode "g")
  (xtide-mode-redraw))

(defun xtide-show-medium-rare ()
  "Show tides in \"medium rare\" format, meaning a list of hourly heights."
  (interactive)
  (setq xtide-output-mode "m")
  (xtide-mode-redraw))

(defun xtide-show-plain-times ()
  "Show plain tide times format (including sun and moon times)."
  (interactive)
  (setq xtide-output-mode "p")
  (xtide-mode-redraw))

(defun xtide-show-raw-times ()
  "Show tide times in raw format, meaning heights against unix time."
  (interactive)
  (setq xtide-output-mode "r")
  (xtide-mode-redraw))

(defun xtide-show-statistics ()
  "Show some statistics about tide heights at this time and location."
  (interactive)
  (setq xtide-output-mode "s")
  (xtide-mode-redraw))

(defun xtide-zoom-in-horizontal ()
  "Zoom in on the tide graph, horizontally.
Experimental feature!
This goes in to see a curve in more detail, showing less time on
the screen."
  (interactive)
  (setq xtide-aspect-ratio (* xtide-aspect-ratio 1.7))
  (xtide-mode-redraw))

(defun xtide-zoom-out-horizontal ()
  "Zoom out of the tide graph, horizontally.
Experimental feature!
This goes out to see more time horizontally, squeezing up the
tidal curves."
  (interactive)
  (setq xtide-aspect-ratio (/ xtide-aspect-ratio 1.7))
  (xtide-mode-redraw))

(defconst xtide-zoom-output-modes '("b" "g")
  "The `xtide-output-mode' values where zooming does something.")

(defun xtide-tcd-goto-location (location)
  "Move point to the section for LOCATION in a tide database dump.
The current buffer should be a `tcd-format-decode' style restored
dump of a .tcd file.  LOCATION (a string) is tide station name.

Note: Don't use this function, it's likely to be renamed and
moved to tcd-format.el or a hypothetical tcd-mode.el."

  (goto-char ;; leave point unchanged if location not found
   (save-excursion

     ;; location name on a line of its own like
     ;;     Abott Harbour, Nova Scotia
     ;; or within the XML part like
     ;;     <subordinatestation name="York Harbor, Maine"
     (goto-char (point-min))
     (or (re-search-forward (concat "^\\(<subordinatestation name=\"\\)?"
                                    (regexp-quote location)
                                    "\\(\"\\|$\\)$") nil t)
         (error "Location not found: '%s'" location))

     ;; then skip back past "#" comments about the location
     (forward-line -1)
     (while (and (looking-at "#")
                 (not (bobp)))
       (forward-line -1))
     (unless (looking-at "#")
       (forward-line))

     (point)))
  (recenter 0))

(defun xtide-button-goto-tcd (button)
  "Button press action to follow link to tcd harmonics file.
This function is only meant for use when `tcd-format-decode' has
been used (`tcd' format in `format-alist'), otherwise a tcd file
is binary and can't be usefully visited."
  (find-file (button-label button))
  (xtide-tcd-goto-location (button-get button 'xtide-location)))

(defvar xtide-mode-map
  (let ((m (make-sparse-keymap "XTide")))
    ;; forward-button is new in emacs22, but bind it always since don't have
    ;; anything else to offer in emacs21 and xemacs21
    (define-key m "\t"        'forward-button)
    (define-key m "q"         'kill-this-buffer)
    (define-key m "W"         'xtide-zoom-in-horizontal)
    (define-key m "w"         'xtide-zoom-out-horizontal)
    (define-key m "s"         'xtide-show-statistics)
    (define-key m "r"         'xtide-show-raw-times)
    (define-key m "p"         'xtide-show-plain-times)
    (define-key m "m"         'xtide-show-medium-rare)
    (define-key m "l"         'xtide-location-mode)
    (define-key m "g"         'xtide-show-graph)
    (define-key m "C"         'xtide-show-calendar-alternative)
    (define-key m "c"         'xtide-show-calendar)
    (define-key m "b"         'xtide-show-banner)
    (define-key m "a"         'xtide-show-about-location)
    (define-key m " "         'xtide-forward-6hour)
    (define-key m [backspace] 'xtide-backward-6hour) ;; xemacs
    (define-key m [?\d]       'xtide-backward-6hour)
    (define-key m [left]      'xtide-backward-6hour)
    (define-key m [right]     'xtide-forward-6hour)
    m)
  "Keymap for `xtide-mode' display buffer.")

(easy-menu-define xtide-mode-menu xtide-mode-map "XTide Menu"
  `("XTide"
    ["Location" xtide-location-mode
     ,@(xtide-easy-menu-help  (documentation 'xtide-location-mode))]

    ["Forward 6 Hours" xtide-forward-6hour
     :active  (not (equal xtide-output-mode "a"))
     :keys    "<right>" ;; among the multiple keys
     ,@(xtide-easy-menu-help  (documentation 'xtide-forward-6hour))]
    ["Backward 6 Hours" xtide-backward-6hour
     :active  (not (equal xtide-output-mode "a"))
     :keys    "<left>" ;; among the multiple keys
     ,@(xtide-easy-menu-help  (documentation 'xtide-backward-6hour))]

    ["Zoom out horizontally" xtide-zoom-out-horizontal
     :active  (member xtide-output-mode xtide-zoom-output-modes)
     ,@(xtide-easy-menu-help  (documentation 'xtide-zoom-out-horizontal))]
    ["Zoom in horizontally" xtide-zoom-in-horizontal
     :active  (member xtide-output-mode xtide-zoom-output-modes)
     ,@(xtide-easy-menu-help  (documentation 'xtide-zoom-in-horizontal))]

    ["--" nil]
    ["About Location" xtide-show-about-location
     ,@(xtide-easy-menu-help (documentation 'xtide-show-about-location))
     :style     radio
     :selected  (equal xtide-output-mode "a")]
    ["Banner" xtide-show-banner
     ,@(xtide-easy-menu-help (documentation 'xtide-show-banner))
     :style     radio
     :selected  (equal xtide-output-mode "b")]
    ["Calendar" xtide-show-calendar
     ,@(xtide-easy-menu-help (documentation 'xtide-show-calendar))
     :style     radio
     :selected  (equal xtide-output-mode "c")]
    ["Calendar Alternative" xtide-show-calendar-alternative
     ,@(xtide-easy-menu-help (documentation 'xtide-show-calendar-alternative))
     :style     radio
     :selected  (equal xtide-output-mode "C")]
    ["Graph" xtide-show-graph
     ,@(xtide-easy-menu-help (documentation 'xtide-show-graph))
     :style     radio
     :selected  (equal xtide-output-mode "g")]
    ["Medium Rare" xtide-show-medium-rare
     ,@(xtide-easy-menu-help (documentation 'xtide-show-medium-rare))
     :style     radio
     :selected  (equal xtide-output-mode "m")]
    ["Plain Times" xtide-show-plain-times
     ,@(xtide-easy-menu-help (documentation 'xtide-show-plain-times))
     :style     radio
     :selected  (equal xtide-output-mode "p")]
    ["Raw Times" xtide-show-raw-times
     ,@(xtide-easy-menu-help (documentation 'xtide-show-raw-times))
     :style     radio
     :selected  (equal xtide-output-mode "r")]
    ["Statistics" xtide-show-statistics
     ,@(xtide-easy-menu-help (documentation 'xtide-show-statistics))
     :style     radio
     :selected  (equal xtide-output-mode "s")]))

(defvar xtide-mode-tool-bar-map
  (and (eval-when-compile (boundp 'tool-bar-map)) ;; not in xemacs

       ;; emacs21 doesn't have the new tool-bar-local-item-from-menu to
       ;; operate on a given keymap.  Binding `tool-bar-map' tricks
       ;; tool-bar-add-item-from-menu into operating on this new one.
       ;;
       (let ((help-list    nil)
             (tool-bar-map (copy-keymap tool-bar-map)))
         ;; tool-bar-map can be an empty keymap on a tty in emacs22
         (when (butlast tool-bar-map)
           (setq help-list    (last tool-bar-map))
           (setq tool-bar-map (butlast tool-bar-map)))

         (tool-bar-add-item-from-menu 'xtide-backward-6hour "left-arrow"
                                      xtide-mode-map)
         (tool-bar-add-item-from-menu 'xtide-forward-6hour "right-arrow"
                                      xtide-mode-map)

         (tool-bar-add-item-from-menu 'xtide-zoom-out-horizontal "zoom-out"
                                      xtide-mode-map)
         (tool-bar-add-item-from-menu 'xtide-zoom-in-horizontal "zoom-in"
                                      xtide-mode-map)

         (append tool-bar-map help-list)))

  "Keymap for tool bar in `xtide-mode' display buffer.
This is the global tool-bar map with left/right and zoom buttons
just before the help.")

(defun xtide-font-lock-plus (limit)
  "Font lock matcher for the \"+\" current time marker.
This is applied in \"g\" and \"b\" modes; in other modes it returns nil for
no match."
  (and (member xtide-output-mode '("g" "b"))
       (search-forward "+" limit t)))

(defconst xtide-font-lock-keywords
  '(xtide-font-lock-plus)
  "`font-lock-keywords' for `xtide-mode'.")

(defun xtide-mode (&optional time mode)
  "Show an XTide tide times buffer.
Note that the data shown is NOT FOR NAVIGATION.

\\{xtide-mode-map}
----
The initial graph shows now and a further day or two.  The \"+\"
marker is the current time.  If you go to a wild date or lose
track then kill the buffer and restart to get back to today.
There's no automatic redisplay as time passes, but press
\"\\[xtide-show-graph]\" to get a new graph.

Dates and times are in the timezone of the location.  This is
what you want for your local tides, and usually makes most sense
for somewhere else.

When switching location the absolute time is preserved.  If
you're looking at tides for Sydney, Australia 10am Saturday and
switch to Sydney, Nova Scotia then you see 7pm Friday because
that's the same moment in that different timezone.  When the
\"+\" marker for \"now\" is on screen you can see it stays at the
same place in the window.

The XTide home page is
  URL `http://www.flaterco.com/xtide'
The xtide.el home page is
  URL `http://user42.tuxfamily.org/xtide/index.html'

And see tcd-format.el for nosing around raw harmonics files.
  URL `http://user42.tuxfamily.org/tcd-format/index.html'"

  (if (get-buffer xtide-buffer)
      (switch-to-buffer (get-buffer xtide-buffer))
    (switch-to-buffer (get-buffer-create xtide-buffer))
    (kill-all-local-variables)

    (setq major-mode        'xtide-mode
          mode-name         "XTide"
          truncate-lines    t
          xtide-output-mode nil   ;; new buffer start in graph mode
          xtide-time        nil)  ;; new buffer start at today
    (when (eval-when-compile (boundp 'tool-bar-map)) ;; not in xemacs21
      (set (make-local-variable 'tool-bar-map)
           xtide-mode-tool-bar-map))
    (set (make-local-variable 'font-lock-defaults)
	 '(xtide-font-lock-keywords
	   t	 ;; no syntactic fontification (of strings etc)
	   nil   ;; no case-fold
	   nil)) ;; no changes to syntax table

    (use-local-map xtide-mode-map)
    (easy-menu-add xtide-mode-menu)
    (buffer-disable-undo xtide-buffer)
    (setq buffer-read-only t)

    (run-hooks 'xtide-mode-hook))

  (setq xtide-time (or time                ;; if specified
                       xtide-time          ;; else previous value
                       xtide-calendar-time ;; calendar via location selector
                       (current-time)))    ;; or initially the current time
  (setq xtide-calendar-time nil) ;; discard after xtide buffer opened
  (setq xtide-output-mode (or mode               ;; if specified
                              xtide-output-mode  ;; else previous value
                              "g"))              ;; or initially graph
  (xtide-mode-redraw))

(defun xtide-mode-redraw ()
  "Redraw contents of XTide display based on current variables."
  (let ((buffer-read-only nil))
    (erase-buffer)
    (if (and (string-equal xtide-output-mode "g")
             (xtide-display-images-p)
             (xtide-image-type-available-p 'png))
        (xtide-run-insert-image xtide-time)
      (xtide-run-insert-text xtide-time xtide-output-mode))

    ;; Buttonize the harmonics filename, when tcd-format.el is available.
    ;; If not available then don't buttonize since the .tcd is a binary file
    ;; and there's nothing can be done with it.
    ;;
    ;; `erase-buffer' above removes any previous button, so can just make a
    ;; new one here every time.
    ;;
    ;; Emacs 22 up has button.el.  XEmacs 21.4.22 has a `make-button' in
    ;; cal-compat.el, but that file doesn't seem to make a full button.el
    ;; replacement and probably isn't meant for use outside the calendar.
    ;; In particular make-button errors out unless diary-face has been
    ;; loaded from diary-lib.el, or something.
    ;;
    (when (and (string-equal xtide-output-mode "a")
               (assoc 'tcd format-alist)
               (featurep 'button)) ;; new in emacs22
      (goto-char (point-min))
      (when (re-search-forward "In file\\s-*\\(.*\\)" nil t)
        (make-button (match-beginning 1) (match-end 1)
                     'action 'xtide-button-goto-tcd
                     'xtide-location xtide-location))))

  (set-buffer-modified-p nil)
  ;; no cursor in graph mode, because a cursor on top of an image looks
  ;; pretty ordinary, in particular a blinking cursor is very annoying
  (if (eval-when-compile (boundp 'cursor-type)) ;; not in xemacs
      (setq cursor-type (if (equal "g" xtide-output-mode)
                            nil
                          t)))
  (goto-char (point-min)))

;;;###autoload
(defun xtide ()
  "Display a tides graph using XTide.
If a location has been set in either `xtide-location' or the
XTIDE_DEFAULT_LOCATION environment variable, then this function
goes straight to `xtide-mode'.  If not, then `xtide-location-mode'
is used to get a location."

  (interactive)
  (if (xtide-location-value)
      (xtide-mode)
    (xtide-location-mode)))


;;-----------------------------------------------------------------------------
;; calendar bits

;;;###autoload
(defun xtide-calendar-tides (&optional arg)
  "Display tides for the calendar cursor date.
With a prefix ARG, prompt for a date to display."
  (interactive "P")

  ;; just byte compiler checking really, already loaded in normal use
  (eval-when-compile (require 'calendar))

  ;; XTide starts its display a little before the time asked, so give
  ;; 2:30am to get the display starting at about 1:00am.  If the location
  ;; selector comes up to choose a location the requested time is still
  ;; saved so it's shown after selecting a location.
  ;;
  ;; emacs23 renames `extract-calendar-day' to `calendar-extract-day' etc,
  ;; an incompatible change which is as pointless as it is irritating.
  ;; The original names might not be fantastic, but the thing changing
  ;; them can achieve is to stop perfectly good programs from working :-(.
  ;;
  (let* ((date (if arg
                   (calendar-read-date)
                 (calendar-cursor-to-date t)))

         (time (encode-time
                0 30 2 ;; 2:30am
                (if (eval-when-compile (fboundp 'calendar-extract-day))
                    (calendar-extract-day   date)
                  (extract-calendar-day     date))
                (if (eval-when-compile (fboundp 'calendar-extract-month))
                    (calendar-extract-month date)
                  (extract-calendar-month   date))
                (if (eval-when-compile (fboundp 'calendar-extract-year))
                    (calendar-extract-year  date)
                  (extract-calendar-year    date)))))

    (if (xtide-location-value)
        (progn
          ;; xtide in top window, and calendar in the bottom remains the
          ;; selected window
          (xtide-mode time)
          (switch-to-buffer calendar-buffer)
          (display-buffer xtide-buffer))

      ;; select location in top window
      (setq xtide-calendar-time time)
      (other-window 1)
      (xtide-location-mode))))

;;;###autoload
(defun xtide-calendar-setups ()
  "Setup xtide additions to `calendar-mode'.
This binds the `T' key in the calendar to `xtide-calendar-tides'.

This function is meant for use from `calendar-load-hook', though
doing so means you load xtide immediately on starting the
calendar.  Copying the `define-key' (and the menu one too) into
your .emacs can avoid that.

Beware also that if calendar.el has already been loaded by
something else then `calendar-load-hook' doesn't run, so make
sure you `add-hook' early enough in your .emacs file."

  (define-key calendar-mode-map "T" 'xtide-calendar-tides))

;;;###autoload
(custom-add-option 'calendar-load-hook 'xtide-calendar-setups)

;; The menu entry is added unconditionally, it won't upset anyone's key
;; binding preferences.
;;
;; Must be string (eval-after-load "calendar" ...) not symbol 'calendar
;; because emacs 23.1 has (provide 'calendar) at the start of the file,
;; claiming the feature is available when it's not.
;;
;; calendar.el recommends `calendar-load-hook' for key bindings.
;; That's usually ok from your .emacs, but if calendar.el is already
;; loaded then adding to the hook from here does nothing.
;;
;; emacs21 define-key-after must be a single event, so lookup the sub-keymap
;; and act there.  That lookup is a handy spot to cope with the different
;; symbol name in emacs23 too.
;;
;; xemacs21 doesn't have `define-key-after', but menus are an incompatible
;; style there anyway.  xemacs 21.4.22 cal-xemacs.el does a direct
;; `add-menu-item', so the menu doesn't appear in calendar-mode-map and
;; `easy-menu-add-item' doesn't seem to like to add anything in that case.
;;
;;;###autoload
(when (eval-when-compile (fboundp 'define-key-after)) ;; not in xemacs21
  (eval-after-load "calendar"
    '(let ((keymap (or (lookup-key calendar-mode-map
                                   [menu-bar moon]) ;; emacs21,22
                       (lookup-key calendar-mode-map
                                   [menu-bar Sun/Moon])))) ;; emacs23
       (define-key-after keymap [xtide]
         '(menu-item "Tides" xtide-calendar-tides
                     :help "View tides for the selected day using XTide.")
         t)))) ;; add at end of keymap


;;-----------------------------------------------------------------------------

(defun xtide-unload-function ()
  "Kill xtide buffers on unloading xtide.el."
  ;; `xtide-calendar-tides' is left in the calendar mode map, but that's ok
  ;; as its an autoload
  (if (get-buffer xtide-buffer)
      (kill-buffer xtide-buffer))
  (if (get-buffer xtide-location-buffer)
      (kill-buffer xtide-location-buffer))
  nil) ;; and do normal unload-feature actions too


;; coding cookie down here instead of in the first line so as to keep it out
;; of finder-by-keyword summary
;;
;; Local variables:
;; coding: latin-1
;; End:

(provide 'xtide)

;;; xtide.el ends here
