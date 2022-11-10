;;; emacspeak-youtube-dl.el --- speech-enable youtube-dl interface  -*- lexical-binding: t; -*-
;;; Description:  Emacspeak extension to speech-enable youtube-dl
;;; Keywords: Emacspeak, Youtube, comm, multimedia
;;{{{  LCD Archive entry:

;;}}}
;;{{{  Copyright:

;;; Initial version: Author: Igor B. Poretsky <poretsky@mlbox.ru>
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
;;{{{  Introduction:

;;; Commentary:

;;; This module speech-enables youtube-dl-emacs.
;;; Youtube-dl-emacs provides an interface of youtube-dl for Emacs.  You can also
;;; call it from web browser on Emacs, like emacs-w3m.
;;; See <https://github.com/poretsky/youtube-dl-emacs/> for more info.

;;}}}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Code:

;;{{{ required modules

(require 'emacspeak-preamble)

;;}}}
;;{{{ forward declarations:

(declare-function youtube-dl--pointed-item "youtube-dl")
(declare-function youtube-dl-item-total "youtube-dl" (item))
(declare-function youtube-dl-item-progress "youtube-dl" (item))

;;}}}
;;{{{ mapping faces to personalities:

(voice-setup-add-map
 '(
   (youtube-dl-active voice-bolden-medium)
   (youtube-dl-playlist-title voice-monotone)
   (youtube-dl-slow voice-bolden-extra)
   (youtube-dl-pause voice-smoothen)
   (youtube-dl-audio-content voice-monotone-medium)
   (youtube-dl-priority voice-animate-extra)
   (youtube-dl-failure voice-bolden-and-animate)
   (youtube-dl-view-title voice-monotone)
   (youtube-dl-view-header voice-smoothen-medium)
   (youtube-dl-view-header-value voice-monotone)
   ))

;;}}}
;;{{{ advice:

(cl-loop
 for f in
 '(youtube-dl-play
   youtube-dl-w3m-play)
 do
 (eval
  `(defadvice ,f (before emacspeak pre act comp)
     "provide auditory confirmation."
     (when (ems-interactive-p)
       (dtk-stop)
       (emacspeak-auditory-icon 'button)))))

(cl-loop
 for f in
 '(youtube-dl
   youtube-dl-audio
   youtube-dl-w3m-view
   youtube-dl-w3m-dispatch)
 do
 (eval
  `(defadvice ,f (around emacspeak pre act comp)
     "provide auditory confirmation."
     (let ((emacspeak-youtube-dl-feedback t))
       ad-do-it
       ad-return-value))))

(cl-loop
 for f in
 '(youtube-dl-list-next-item
   youtube-dl-list-prev-item)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "provide auditory confirmation."
     (when (ems-interactive-p)
       (emacspeak-speak-line 1)))))

(cl-loop
 for f in
 '(youtube-dl-list-kill-log
   youtube-dl-view-quit
   youtube-dl-quit)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "provide auditory confirmation."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'close-object)
       (emacspeak-speak-mode-line)))))

(defadvice youtube-dl-customize (after emacspeak pre act comp)
  "provide auditory confirmation."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-current-buffer-name)))

(defadvice youtube-dl-list (after emacspeak pre act comp)
  "provide auditory confirmation."
  (when (or (ems-interactive-p)
            (and (boundp 'emacspeak-youtube-dl-feedback)
                 emacspeak-youtube-dl-feedback))
    (when (boundp 'emacspeak-youtube-dl-feedback)
      (setq emacspeak-youtube-dl-feedback nil))
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-line 1)))

(defadvice youtube-dl-list-log (after emacspeak pre act comp)
  "provide auditory confirmation."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)))

(defadvice youtube-dl-view (around emacspeak pre act comp)
  "provide auditory confirmation."
  (let ((interactive-p (ems-interactive-p)))
    (when interactive-p
      (emacspeak-auditory-icon 'button))
    (if (not (boundp 'emacspeak-youtube-dl-feedback))
        (let ((emacspeak-youtube-dl-feedback t))
          ad-do-it
          (when (and interactive-p
                     emacspeak-youtube-dl-feedback)
            (emacspeak-auditory-icon 'open-object)
            (emacspeak-speak-mode-line)))
      ad-do-it
      (when emacspeak-youtube-dl-feedback
        (emacspeak-auditory-icon 'open-object)
        (emacspeak-speak-mode-line)))
    ad-return-value))

(defadvice youtube-dl-view-add-w3m-bookmark (after emacspeak pre act comp)
  "Produce auditory icon."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'save-object)))

(defadvice youtube-dl-list-yank (after emacspeak pre act comp)
  "provide auditory confirmation."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'mark-object)))

(defadvice youtube-dl-list-kill (after emacspeak pre act comp)
  "provide auditory confirmation."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'delete-object)
    (emacspeak-speak-line 1)))

(defadvice youtube-dl-list-toggle-pause (after emacspeak pre act comp)
  "provide auditory confirmation."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon
     (if (youtube-dl-item-paused-p (ad-get-arg 0))
         ''off
       'on))))

(defadvice youtube-dl-list-toggle-pause-all (after emacspeak pre act comp)
  "provide auditory confirmation."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon
     (if youtube-dl-items
         (if (youtube-dl-item-paused-p (car youtube-dl-items))
             ''off
           'on)
       'warn-user))))

(defadvice youtube-dl-list-toggle-slow (after emacspeak pre act comp)
  "provide auditory confirmation."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon
     (if (youtube-dl-item-slow-p (ad-get-arg 0))
         ''off
       'on))))

(defadvice youtube-dl-list-toggle-slow-all (after emacspeak pre act comp)
  "provide auditory confirmation."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon
     (if youtube-dl-items
         (if (youtube-dl-item-slow-p (car youtube-dl-items))
             ''off
           'on)
       'warn-user))))

(defadvice youtube-dl-list-priority-up (after emacspeak pre act comp)
  "provide auditory confirmation."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'left)))

(defadvice youtube-dl-list-priority-down (after emacspeak pre act comp)
  "provide auditory confirmation."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'right)))

(defconst emacspeak-youtube-dl-progress-notification-interval 0.5)
(defvar emacspeak-youtube-dl-last-progress-notification-time (current-time))

(defadvice youtube-dl--progress (before emacspeak pre act comp)
  "provide auditory confirmation."
  (when (>= (time-to-seconds (time-subtract (current-time)
                                            emacspeak-youtube-dl-last-progress-notification-time))
            emacspeak-youtube-dl-progress-notification-interval)
    (emacspeak-auditory-icon 'progress)
    (setq emacspeak-youtube-dl-last-progress-notification-time (current-time))))

(defadvice youtube-dl--sentinel (before emacspeak pre act comp)
  "provide auditory confirmation when download is finished."
  (when (equal (ad-get-arg 1) "finished\n")
    (emacspeak-auditory-icon 'complete)))

(defadvice youtube-dl-play--sentinel (after emacspeak pre act comp)
  "provide auditory confirmation when playback is succeeded or failed."
  (let ((process (ad-get-arg 0)))
    (unless (process-live-p process)
      (emacspeak-auditory-icon
       (if (zerop (process-exit-status process))
           'close-object
         'warn-user)))))

;;}}}
;;{{{ helper functions:

(defun emacspeak-youtube-dl-speak-progress ()
  "Speak progress for current item."
  (interactive)
  (let* ((item (youtube-dl--pointed-item))
         (total (youtube-dl-item-total item))
         (progress (youtube-dl-item-progress item)))
    (emacspeak-auditory-icon 'select-object)
    (dtk-speak-and-echo
     (format "Done %s of %s total"
             (or progress "0.0%")
             (or total "unknown")))))

;;}}}
;;{{{ additional keystrokes:

(cl-declaim (special youtube-dl-list-mode-map))
(define-key youtube-dl-list-mode-map "z" #'emacspeak-youtube-dl-speak-progress)

;;}}}
(provide 'emacspeak-youtube-dl)
;;{{{ end of file 

;;; local variables:
;;; folded-file: t
;;; end: 

;;}}}
