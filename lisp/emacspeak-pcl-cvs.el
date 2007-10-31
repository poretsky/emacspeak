;;; emacspeak-pcl-cvs.el --- Speech enabled CVS access 
;;; $Id: emacspeak-pcl-cvs.el 4532 2007-05-04 01:13:44Z tv.raman.tv $
;;; $Author: tv.raman.tv $
;;; Description:  Emacspeak extension to speech-enable CVS
;;; access 
;;; Keywords: Emacspeak, CVS, Audio Desktop
;;{{{  LCD Archive entry:

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu
;;; A speech interface to Emacs |
;;; $Date: 2007-05-03 18:13:44 -0700 (Thu, 03 May 2007) $ |
;;;  $Revision: 4532 $ |
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:

;;; Copyright (C) 1995 -- 2007, T. V. Raman<raman@cs.cornell.edu>
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

;;{{{  Introduction:

;;; Commentary:

;;; Speech-enabled CVS access via package pcl-cvs.el

;;; Code:

;;}}}
;;{{{ required modules

(require 'emacspeak-preamble)
;;}}}
;;{{{  define voices 

(voice-setup-add-map
 '(
   (cvs-filename-face voice-bolden)

   (cvs-handled-face voice-monotone-medium)

   (cvs-header-face voice-bolden)

   (cvs-marked-face voice-brighten-medium)

   (cvs-msg-face voice-monotone-medium)

   (cvs-need-action-face voice-brighten)
   ))

;;}}}
;;{{{  speech enable interactive commands

(defsubst emacspeak-pcl-cvs-summarize-line ()
  (emacspeak-speak-line))

(defadvice cvs-mode-add (after emacspeak pre act comp)
  "Provide auditory icon if possible."
  (when (interactive-p)
    (emacspeak-auditory-icon 'select-object)))

(defadvice cvs-mode-kill-buffers (after emacspeak pre act
                                        comp)
  "Produce an auditory icon."
  (when (interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (message "Killed all temporary CVS buffers.")))

(defadvice cvs-checkout (after emacspeak pre act comp)
  "Provide an auditory icon."
  (when (interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-mode-line)))

(defadvice cvs-mode-find-file (around emacspeak pre act comp)
  "Provide an auditory icon."
  (if (and (interactive-p)
	   (not (file-directory-p (cvs-fileinfo->full-path
				   (cvs-mode-marked nil nil :one t)))))
      (progn ad-do-it
	     (emacspeak-auditory-icon 'open-object))
    ad-do-it)
  ad-return-value)

(defadvice log-edit (after emacspeak pre act comp)
  "Provide an auditory icon."
  (emacspeak-auditory-icon 'open-object))

(defadvice log-edit-done (after emacspeak pre act comp)
  "Provide an auditory icon."
  (when (interactive-p)
    (emacspeak-auditory-icon 'close-object)))

(defadvice cvs-mode-next-line (after emacspeak pre act comp)
  "Provide auditory feedback. "
  (when (interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-pcl-cvs-summarize-line)))
(defadvice cvs-mode-previous-line (after emacspeak pre act comp)
  "Provide auditory feedback. "
  (when (interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-pcl-cvs-summarize-line)))

(defadvice cvs-mode-mark (after emacspeak  pre act comp)
  "Provide auditory feedback. "
  (when (interactive-p)
    (emacspeak-auditory-icon 'mark-object)
    (emacspeak-pcl-cvs-summarize-line)))

(defadvice cvs-mode-unmark (after emacspeak  pre act comp)
  "Provide auditory feedback. "
  (when (interactive-p)
    (emacspeak-auditory-icon 'deselect-object)
    (emacspeak-pcl-cvs-summarize-line)))

(defadvice cvs-mode-add-change-log-entry-other-window (after emacspeak
							     pre act comp)
  "Provide auditory icon if possible. "
  (when (interactive-p)
    (emacspeak-auditory-icon 'yank-object)))

(defadvice cvs-status-trees (after emacspeak pre act comp)
  "Provide auditory icon if possible. "
  (when (interactive-p)
    (emacspeak-auditory-icon 'select-object)))

(defadvice cvs-status-cvstrees (after emacspeak pre act comp)
  "Provide auditory icon if possible. "
  (when (interactive-p)
    (emacspeak-auditory-icon 'select-object)))

(defadvice  cvs-sentinel (after emacspeak pre act )
  "Provide auditory feedback"
  (emacspeak-auditory-icon 'task-done))

(defadvice cvs-bury-buffer (after emacspeak pre act)
  "Produce auditory feedback."
  (when (interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (with-current-buffer (window-buffer)
      (emacspeak-speak-mode-line))))

;;}}}
(provide 'emacspeak-pcl-cvs)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
