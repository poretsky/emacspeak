;;; emacspeak-wiki.el --- speech-enable emacs-wiki  -*- lexical-binding: t; -*-
;;; Description:  Emacspeak extension to speech-enable emacs-wiki package
;;; Keywords: Emacspeak, Emacs wiki, html publishing
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;{{{ required modules

(require 'emacspeak-preamble)
;;}}}
;;{{{  Introduction:

;;; Commentary:

;;; This module speech-enables emacs-wiki package
;;; that allows to construct hypertext documents
;;; and publish it as html pages.

;;}}}
;;{{{ Advice interactive commands to speak.

(defadvice emacs-wiki-find-file (around emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (if (not (ems-interactive-p))
      ad-do-it
    (ad-set-arg 0 (car (ad-get-arg 0)))
    ad-do-it
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-mode-line))
  ad-return-value)

(defadvice emacs-wiki-follow-name-at-point (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-mode-line)))

(defadvice emacs-wiki-index (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-mode-line)))

(defadvice emacs-wiki-next-reference (after emacspeak pre act comp)
  "Provide speech feedback."
  (when (ems-interactive-p)
    (if (emacs-wiki-link-at-point)
        (progn
          (emacspeak-auditory-icon 'large-movement)
          (emacspeak-speak-text-range 'keymap))
      (emacspeak-auditory-icon 'warn-user)
      (dtk-speak-and-echo "No links on this page"))))

(defadvice emacs-wiki-previous-reference (after emacspeak pre act comp)
  "Provide speech feedback."
  (when (ems-interactive-p)
    (if (emacs-wiki-link-at-point)
        (progn
          (emacspeak-auditory-icon 'large-movement)
          (emacspeak-speak-text-range 'keymap))
      (emacspeak-auditory-icon 'warn-user)
      (dtk-speak-and-echo "No links on this page"))))

(defadvice emacs-wiki-publish (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'save-object)))

;;}}}
;;{{{ mapping font faces to personalities 

(voice-setup-add-map
 '(
   (emacs-wiki-link-face voice-bolden)
   (emacs-wiki-bad-link-face voice-lighten)
   (emacs-wiki-header-1-face voice-brighten)
   (emacs-wiki-header-2-face voice-brighten)
   (emacs-wiki-header-3-face voice-brighten)
   (emacs-wiki-header-4-face voice-brighten)
   (emacs-wiki-header-5-face voice-brighten)
   (emacs-wiki-header-6-face voice-brighten)
   ))

;;}}}
(provide 'emacspeak-wiki)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; end:

;;}}}
