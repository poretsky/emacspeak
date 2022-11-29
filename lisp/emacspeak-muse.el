;;; emacspeak-muse.el --- Speech-enable Muse  -*- lexical-binding: t; -*-
;;; $Id$
;;; $Author: tv.raman.tv $
;;; Description:  Speech-enable Muse
;;; Keywords: Emacspeak,  Audio Desktop Muse
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
;;;Copyright (C) 1995 -- 2018, T. V. Raman 
;;; Copyright (c) 1994, 1995 by Digital Equipment Corporation.
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

;;{{{  introduction

;;; Commentary:
;;; Speech enable Muse

;;}}}
;;{{{  Required modules

;;; Code:

(cl-declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)
(require 'browse-url)
(require 'emacspeak-outline)

;;}}}
;;{{{ Voice definitions:
(voice-setup-add-map
 '(
   (muse-bad-link-face voice-bolden-and-animate)
   (muse-emphasis-1 voice-lighten)
   (muse-emphasis-2 voice-lighten-medium)
   (muse-emphasis-3 voice-lighten-extra)
   (muse-header-1 voice-bolden)
   (muse-header-2 voice-bolden-medium)
   (muse-header-3 voice-bolden-extra)
   (muse-header-4 voice-bolden-extra)
   (muse-header-5 voice-bolden-extra)
   (muse-header-6 voice-bolden-extra)
   (muse-link-face voice-brighten)
   (muse-verbatim-face voice-monotone)
   (muse-header-1-face voice-bolden)
   (muse-header-2-face voice-bolden-medium)
   (muse-header-3-face voice-bolden-extra)
   (muse-header-4-face voice-bolden-extra)
   (muse-header-5-face voice-bolden-extra)
   (muse-header-6-face voice-bolden-extra)
   (muse-bad-link voice-bolden-and-animate)
   (muse-link voice-brighten)
   (muse-verbatim voice-monotone)
   ))

;;}}}
;;{{{ advice interactive commands

(defadvice muse-mode (after emacspeak pre act comp)
  "Setup Emacspeak extensions."
  (voice-lock-mode (if global-voice-lock-mode 1 -1))
  (dtk-set-punctuations 'all))

(cl-loop for f in
      '(muse-next-reference muse-previous-reference)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Provide speech feedback."
          (when (ems-interactive-p)
            (if (muse-link-at-point)
                (progn
                  (emacspeak-auditory-icon 'large-movement)
                  (emacspeak-speak-text-range 'keymap))
              (emacspeak-auditory-icon 'warn-user)
              (dtk-speak-and-echo "No links on this page"))))))

(cl-loop for f in
      '(muse-edit-link-at-point
        muse-insert-relative-link-to-file
        muse-insert-url)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Provide speech feedback."
          (when (ems-interactive-p)
            (emacspeak-auditory-icon 'yank-object)
            (when (sit-for 0.1)
              (save-mark-and-excursion
                (backward-char)
                (emacspeak-speak-text-range 'keymap)))))))

(cl-loop for f in
      '(muse-follow-name-at-point
        muse-follow-name-at-point-other-window
        muse-index)
      do
      (eval
       `(defadvice   ,f (after emacspeak pre act comp)
          "Provide auditory feedback."
          (when (ems-interactive-p)
            (emacspeak-auditory-icon 'open-object)
            (emacspeak-speak-mode-line)))))

(defadvice muse-project-find-file (around emacspeak pre act comp)
  "Provide auditory feedback."
  (when (listp (ad-get-arg 0))
    (ad-set-arg 0 (car (ad-get-arg 0))))
  ad-do-it
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-mode-line))
  ad-return-value)

(cl-loop for f in
      '(muse-project-publish
        muse-project-publish-this-file
        muse-publish-this-file)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Produce an auditory icon if possible."
          (when (ems-interactive-p)
            (emacspeak-auditory-icon 'save-object)))))

(defadvice muse-insert-tag (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'yank-object)
    (emacspeak-speak-line)))

(defadvice muse-insert-list-item (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'item)
    (emacspeak-speak-line)))

(defadvice muse-decrease-list-item-indentation (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'left)
    (emacspeak-speak-line)))

(defadvice muse-increase-list-item-indentation (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'right)
    (emacspeak-speak-line)))

(defadvice muse-colors-toggle-inline-images (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (cl-declare (special muse-colors-inline-images))
  (when (ems-interactive-p)
    (emacspeak-auditory-icon (if muse-colors-inline-images 'on 'off))))

;;}}}
(provide 'emacspeak-muse)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
