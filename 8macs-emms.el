(autoload 'emms-setup "emms-setup" "" t nil)
;; (emms-minimalist)
;; (emms-standard)
;; (emms-all)
(emms-devel)
(emms-default-players)
(setq emms-source-file-default-directory "~/Music/"
      emms-stream-bookmarks-file (concat dotfiles-dir "emms-streams")
      emms-player-mpg321-command-name "mpg321"
      emms-player-mplayer-command-name "mplayer"
      emms-player-mplayer-playlist-command-name "mplayer"
      ibuffer-truncate-lines t
      ibuffer-use-other-window nil
      emms-stream-info-format-string "NS: %s"
      emms-stream-default-action "play"
      emms-stream-popup-default-height 120
      )

(provide '8macs-emms)