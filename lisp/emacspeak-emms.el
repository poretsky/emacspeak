;;; emacspeak-emms.el --- Speech-enable EMMS Multimedia UI  -*- lexical-binding: t; -*-
;;; $Id$
;;; $Author: tv.raman.tv $
;;; Description:  Emacspeak extension to speech-enable EMMS
;;; Keywords: Emacspeak, Multimedia
;;{{{  LCD Archive entry:

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu
;;; A speech interface to Emacs |
;;; $Date: 2007-08-27 17:54:54 -0700 (Mon, 27 Aug 2007) $ |
;;;  $Revision: 4150 $ |
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:

;;;Copyright (C) 1995 -- 2018, T. V. Raman
;;; All Rights Reserved.
;;;
;;; This file is not part of GNU Emacs, but the same permissions apply.
;;;
;;; GNU Emacs is free software; you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 2, or (at your option)
;;; any later version.
;;;
;;; GNU Emacs is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Emacs; see the file COPYING.  If not, write to
;;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;}}}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;{{{  Introduction

;;; Commentary:
;;;Speech-enables EMMS --- the Emacs equivalent of XMMS
;;; See
;;; http://savannah.gnu.org/project/emms
;;; EMMS is under active development,
;;; to get the current CVS version, use Emacspeak command
;;; M-x emacspeak-cvs-gnu-get-project-snapshot RET emms RET
;;;
;;; Code:

;;}}}
;;{{{ required modules

(cl-declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)
(require 'emms () 'no-error)
;;}}}
;;{{{ Forward declarations

(declare-function emms-player-pause "ext:emms.el" ())
(declare-function emms-track-name "ext:emms.el" (track))
(declare-function emms-playlist-current-selected-track "ext:emms.el" ())

;;}}}
;;{{{ module emms:

(defun emacspeak-emms-speak-current-track ()
  "Speak current track."
  (interactive)
  (message
   (emms-track-name (emms-playlist-current-selected-track))))

;;; these commands should not be made to talk since that would  interferes
;;; with real work.
(cl-loop for f in
      '(emms-start
        emms-stop
        emms-sort
        emms-shuffle
        emms-random
        emms-next
        emms-next-noerror
        emms-previous)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Provide auditory icon."
          (when (ems-interactive-p)
            (emacspeak-auditory-icon 'select-object)))))

(cl-loop for f in
      '(emms-playlist-first
        emms-playlist-last
        emms-playlist-mode-first
        emms-playlist-mode-last
        emms-tag-editor-prev-field
        emms-tag-editor-next-field
        emms-tag-editor-prev-track
        emms-tag-editor-next-track
        emms-browser-toggle-subitems
        emms-browser-collapse-all
        emms-browser-expand-to-level-2
        emms-browser-expand-to-level-3
        emms-browser-expand-to-level-4
        emms-browser-expand-all
        emms-browser-goto-random
        emms-browser-prev-non-track
        emms-browser-next-non-track)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Provide auditory feedback."
          (when (ems-interactive-p)
            (emacspeak-auditory-icon 'large-movement)
            (emacspeak-speak-line)))))

(cl-loop for f in
      '(emms
        emms-browser
        emms-browser-next-filter
        emms-browser-previous-filter
        emms-browser-view-in-dired
        emms-browse-by-artist
        emms-browse-by-album
        emms-browse-by-genre
        emms-browse-by-year
        emms-browse-by-composer
        emms-browse-by-performer
        emms-streams
        emms-stream-popup
        emms-stream-popup-revert
        emms-playlist-mode-go
        emms-playlist-mode-goto-dired-at-point
        emms-tag-editor-edit
        emms-playlist-set-playlist-buffer
        emms-metaplaylist-mode-go
        emms-metaplaylist-mode-goto-current)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Provide auditory feedback."
          (when (ems-interactive-p)
            (emacspeak-auditory-icon 'open-object)
            (emacspeak-speak-mode-line)))))

(defadvice emms-toggle-repeat-playlist (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p )
    (emacspeak-auditory-icon (if emms-repeat-playlist 'on 'off))))

(defadvice emms-toggle-repeat-track (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p )
    (emacspeak-auditory-icon (if emms-repeat-track 'on 'off))))

(cl-loop for f in
      '(emms-playlist-save
        emms-tag-editor-submit)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Provide auditory feedback."
          (when (ems-interactive-p )
            (emacspeak-auditory-icon 'save-object)))))

(cl-loop for f in
      '(emms-playlist-mode-clear
        emms-browser-clear-playlist
        emms-browser-delete-files)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Provide auditory feedback."
          (when (ems-interactive-p )
            (emacspeak-auditory-icon 'delete-object)))))

(cl-loop for f in
      '(emms-playlist-mode-add-contents
        emms-browser-add-tracks)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Provide auditory feedback."
          (when (ems-interactive-p )
            (emacspeak-auditory-icon 'yank-object)))))

;;}}}
;;{{{ Interactive playlists:

(cl-loop for f in
      '(emms-playlist-mode-kill-track
        emms-playlist-mode-kill-entire-track
        emms-stream-delete-bookmark)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Provide auditory feedback."
          (when (ems-interactive-p)
            (emacspeak-auditory-icon 'delete-object)
            (emacspeak-speak-line)))))

(defadvice emms-playlist-mode-insert-newline (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p )
    (emacspeak-speak-line)))

(defadvice emms-playlist-mode-kill (around emacspeak pre act comp)
  "Indicate region has been killed. Use an auditory icon if possible."
  (if (ems-interactive-p)
      (let ((count (count-lines (region-beginning) (region-end))))
        ad-do-it
        (emacspeak-auditory-icon 'delete-object )
        (message "Killed region containing %s lines" count))
    ad-do-it)
  ad-return-value)

(cl-loop for f in
      '(emms-playlist-mode-yank
        emms-playlist-mode-yank-pop)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Say what you yanked.
Produce an auditory icon if possible."
          (when (ems-interactive-p)
            (emacspeak-auditory-icon 'yank-object )
            (emacspeak-speak-region (mark 'force) (point))))))

(defadvice emms-playlist-mode-undo (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'unmodified-object)))

(cl-loop for f in
      '(emms-playlist-sort-by-info-composer
        emms-playlist-sort-by-list
        emms-playlist-sort-by-name
        emms-playlist-sort-by-info-artist
        emms-playlist-sort-by-info-album
        emms-playlist-sort-by-play-count
        emms-playlist-sort-by-file-extension
        emms-playlist-sort-by-last-played
        emms-playlist-sort-by-natural-order
        emms-playlist-sort-by-info-note
        emms-playlist-sort-by-info-performer
        emms-playlist-sort-by-info-title
        emms-playlist-sort-by-info-year)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Provide auditory feedback."
          (when (ems-interactive-p)
            (emacspeak-auditory-icon 'task-done)
            (emacspeak-speak-mode-line)))))

;;}}}
;;{{{ Markable playlists:

(defadvice emms-mark-forward (after emacspeak pre act comp)
  "Give speech feedback. Also provide an auditory icon."
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'mark-object )
    (emacspeak-speak-line)))

(defadvice emms-mark-unmark-forward (after emacspeak pre act comp)
  "Give speech feedback. Also provide an auditory icon."
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'deselect-object )
    (emacspeak-speak-line)))

(defadvice emms-mark-copy-marked-tracks (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'mark-object )))

(cl-loop for f in
      '(emms-mark-kill-marked-tracks
        emms-mark-delete-marked-tracks)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Produce an auditory icon if possible."
          (when (ems-interactive-p )
            (emacspeak-auditory-icon 'delete-object)))))

(defadvice emms-browser-bury-buffer (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-speak-mode-line)
    (emacspeak-auditory-icon 'close-object)))

;;}}}
;;{{{ Module emms-streaming:
(cl-declaim (special emms-stream-mode-map))
(defadvice emms-stream-mode (after emacspeak pre act comp)
  "Update keymaps."
  (define-key emms-stream-mode-map "\C-e"
    'emacspeak-prefix-command))

(defadvice emms-stream-save-bookmarks-file (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'save-object)
    (message "Saved stream bookmarks.")))

(cl-loop for f in
      '(emms-stream-quit
        emms-playlist-mode-bury-buffer
        emms-playlist-mode-current-kill
        emms-tag-editor-submit-and-exit
        emms-browser-bury-buffer)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Provide auditory feedback."
          (when (ems-interactive-p)
            (emacspeak-auditory-icon 'close-object)
            (emacspeak-speak-mode-line)))))

(cl-loop for f in
         '(emms-stream-next-line emms-stream-previous-line)
         do
         (eval
          `(defadvice ,f (after emacspeak pre act comp)
             "Provide auditory feedback."
             (when (ems-interactive-p)
               (emacspeak-speak-line)))))
(defadvice emms-playlist-mode-bury-buffer (after emacspeak pre act)
  "Announce the buffer that becomes current."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (emacspeak-speak-mode-line)))

;;}}}
;;{{{ silence chatter from info

(defadvice emms-info-really-initialize-track (around emacspeak
                                                     pre act
                                                     comp)
  "Silence messages."
  (ems-with-messages-silenced
   ad-do-it))

;;}}}
;;{{{ Browser buffer voicification:

(defadvice emms-browser-format-spec (around emacspeak pre act comp)
  "Properly voicify buffer."
  (let ((text-property-default-nonsticky (remove (assq 'personality text-property-default-nonsticky) text-property-default-nonsticky)))
    ad-do-it)
  ad-return-value)

;;}}}
;;{{{ pause/resume if needed

;;;###autoload
(defun emacspeak-emms-pause-or-resume ()
  "Pause/resume if emms is running. For use  in
emacspeak-silence-hook."
  (cl-declare (special emms-player-playing-p))
  (when (and (boundp 'emms-player-playing-p)
             (not (null emms-player-playing-p)))
    (emms-player-pause)))

(add-hook 'emacspeak-silence-hook 'emacspeak-emms-pause-or-resume)

;;}}}
;;{{{ Define personalities

(voice-setup-add-map
 '(
   (emms-metaplaylist-mode-face voice-bolden-medium)
   (emms-metaplaylist-mode-current-face voice-animate)
   (emms-playlist-track-face voice-bolden)
   (emms-playlist-selected-face voice-animate)
   (emms-stream-name-face voice-bolden)
   (emms-stream-url-face voice-lighten)
   (emms-browser-year/genre-face voice-lighten)
   (emms-browser-artist-face voice-lighten-and-animate)
   (emms-browser-composer-face voice-lighten-and-animate)
   (emms-browser-performer-face voice-lighten-and-animate)
   (emms-browser-album-face voice-bolden-medium)
   (emms-browser-track-face voice-bolden)
   ))

;;}}}
(provide 'emacspeak-emms)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
