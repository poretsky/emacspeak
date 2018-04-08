;;; emacspeak-dictionary.el --- speech-enable dictionaries  -*- lexical-binding: t; -*- 
;;; $Id$
;;; $Author: tv.raman.tv $
;;; Description:   Speech enable dictionary mode
;;; Keywords: Emacspeak, Audio Desktop
;;{{{  LCD Archive entry:

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu
;;; A speech interface to Emacs |
;;; $Date: 2007-08-25 18:28:19 -0700 (Sat, 25 Aug 2007) $ |
;;;  $Revision: 4532 $ |
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:

;;; Copyright (C) 1995 -- 2017, T. V. Raman<raman@cs.cornell.edu>
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

;;{{{ required modules

(cl-declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)
;;}}}
;;{{{  Introduction:
;;; Commentary:
;;; Speech-enables emacs client for accessing dictionary
;;; server at dict.org:2628
;;; Code:
;;}}}
;;{{{ Helper functions.

(defun referenced-p ()
  "Return t if the call was caused by selecting a link."
  (cl-declare (special referenced-p))
  (when (and (boundp 'referenced-p) referenced-p)
    (setq referenced-p nil)
    t))

;;}}}
;;{{{ Advice interactive commands to speak.
(defadvice link-selected (around emacspeak pre act comp)
  "Get referenced calls to be recognizable."
  (let ((referenced-p t))
    ad-do-it)
  ad-return-value)

(defadvice dictionary (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-mode-line)))
(defadvice dictionary-close (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (or (ems-interactive-p) (referenced-p))
    (emacspeak-auditory-icon 'close-object)
    (when (and (boundp 'dictionary-window-configuration)
               (boundp 'dictionary-selected-window))
      (let ((window-configuration dictionary-window-configuration)
            (selected-window dictionary-selected-window))
        (replace-buffer-in-windows)
        (when window-configuration
          (set-window-configuration window-configuration))
        (when selected-window
          (select-window selected-window))))
    (emacspeak-speak-mode-line)))
(defadvice dictionary-restore-state (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (referenced-p)
    (emacspeak-auditory-icon 'close-object)
    (emacspeak-speak-mode-line)))
(defadvice dictionary-select-dictionary (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (or (ems-interactive-p) (referenced-p))
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-line)))
(defadvice dictionary-select-strategy (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (or (ems-interactive-p) (referenced-p))
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-line)))

(defadvice dictionary-set-dictionary (around emacspeak pre act comp)
  "Provide auditory feedback."
  (if (not (referenced-p))
      ad-do-it
    (emacspeak-auditory-icon 'select-object)
    (let ((emacspeak-speak-messages t))
      ad-do-it))
  ad-return-value)

(defadvice dictionary-set-strategy (around emacspeak pre act comp)
  "Provide auditory feedback."
  (if (not (referenced-p))
      ad-do-it
    (emacspeak-auditory-icon 'select-object)
    (let ((emacspeak-speak-messages t))
      ad-do-it))
  ad-return-value)

(defadvice dictionary-search (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (or (ems-interactive-p) (referenced-p))
    (emacspeak-auditory-icon 'search-hit)
    (emacspeak-speak-line)))
(defadvice dictionary-new-search (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (or (ems-interactive-p) (referenced-p))
    (emacspeak-auditory-icon 'search-hit)
    (emacspeak-speak-line)))
(defadvice dictionary-lookup-definition (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'search-hit)
    (emacspeak-speak-line)))

(defadvice dictionary-match-words (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (or (ems-interactive-p) (referenced-p))
    (emacspeak-auditory-icon 'search-hit)
    (emacspeak-speak-line)))

(defadvice dictionary-previous (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'large-movement)
    (emacspeak-speak-line)))
(defadvice dictionary-prev-link (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'large-movement)
    (emacspeak-speak-text-range 'link-function)))

(defadvice dictionary-next-link (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'large-movement)
    (emacspeak-speak-text-range 'link-function)))

;;}}}
;;{{{ mapping font faces to personalities 

(voice-setup-add-map
 '(
   (dictionary-button-face voice-bolden)
   (dictionary-word-entry-face voice-animate)
   (dictionary-reference-face voice-bolden)
   ))

;;}}}
(provide 'emacspeak-dictionary)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
