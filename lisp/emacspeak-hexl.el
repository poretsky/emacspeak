;;; emacspeak-hexl.el --- speech-enable hexl mode  -*- lexical-binding: t; -*-
;;; Description:  Emacspeak extension to speech-enable hexl mode
;;; Keywords: Emacspeak, hexl mode, binary files editing
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

;;{{{  Introduction:

;;; Commentary:

;;; This module speech-enables hexl mode,
;;; providing auditory feedback on the most
;;; specific functions and key strokes.

;;; Code:

;;}}}
;;{{{ required modules

(require 'cl-lib)
(cl-declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)
(require 'emacspeak-speak)
(require 'emacspeak-redefine)

;;}}}
;;{{{ Forward declarations

(declare-function hexl-current-address "hexl.el" (&optional VALIDATE))

;;}}}
;;{{{ Helper functions

(defun emacspeak-hexl-speak-current-byte-code ()
  "Speak hex code of current byte."
  (interactive)
  (cl-declare (special dtk-stop-immediately))
  (and dtk-stop-immediately (dtk-stop))
  (emacspeak-speak-spell-word (buffer-substring (point) (+ (point) 2))))

(defun emacspeak-hexl-speak-current-line-address ()
  "Speak hex address of current line."
  (interactive)
  (cl-declare (special dtk-stop-immediately))
  (and dtk-stop-immediately (dtk-stop))
  (emacspeak-speak-spell-word (format "%x0" (/ (hexl-current-address) 16))))

(defun emacspeak-hexl-speak-current-position ()
  "Speak position of current byte in the line."
  (interactive)
  (cl-declare (special dtk-stop-immediately))
  (and dtk-stop-immediately (dtk-stop))
  (dtk-speak (format "0 %x" (% (hexl-current-address) 16))))

(defun emacspeak-hexl-speak-current-address ()
  "Speak address of current byte in hex format."
  (interactive)
  (cl-declare (special dtk-stop-immediately))
  (dtk-speak "current address is ")
  (let ((dtk-stop-immediately nil))
    (emacspeak-speak-spell-word (format "%x" (hexl-current-address)))))

;;}}}
;;{{{ Advising interactive commands

(defadvice hexl-self-insert-command (after emacspeak pre act comp)
  "Speak characters when typing."
  (when (and emacspeak-character-echo
	     (ems-interactive-p ))
    (when dtk-stop-immediately-while-typing (dtk-stop))
    (emacspeak-speak-this-char last-input-char )))

(defadvice hexl-forward-char (after emacspeak pre act comp)
  "Provide speech feedback."
  (when (ems-interactive-p)
    (emacspeak-hexl-speak-current-byte-code)))

(defadvice hexl-backward-char (after emacspeak pre act comp)
  "Provide speech feedback."
  (when (ems-interactive-p)
    (emacspeak-hexl-speak-current-byte-code)))

(defadvice hexl-forward-short (after emacspeak pre act comp)
  "Provide speech feedback."
  (when (ems-interactive-p)
    (emacspeak-hexl-speak-current-byte-code)))

(defadvice hexl-backward-short (after emacspeak pre act comp)
  "Provide speech feedback."
  (when (ems-interactive-p)
    (emacspeak-hexl-speak-current-byte-code)))

(defadvice hexl-forward-word (after emacspeak pre act comp)
  "Provide speech feedback."
  (when (ems-interactive-p)
    (emacspeak-hexl-speak-current-byte-code)))

(defadvice hexl-backward-word (after emacspeak pre act comp)
  "Provide speech feedback."
  (when (ems-interactive-p)
    (emacspeak-hexl-speak-current-byte-code)))

(defadvice hexl-next-line (after emacspeak pre act comp)
  "Provide speech feedback."
  (when (ems-interactive-p)
    (emacspeak-hexl-speak-current-line-address)))

(defadvice hexl-previous-line (after emacspeak pre act comp)
  "Provide speech feedback."
  (when (ems-interactive-p)
    (emacspeak-hexl-speak-current-line-address)))

(defadvice hexl-beginning-of-line (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'select-object)))

(defadvice hexl-end-of-line (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'select-object)))

(defadvice hexl-beginning-of-buffer (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'large-movement)))

(defadvice hexl-end-of-buffer (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'large-movement)))

(defadvice hexl-beginning-of-1k-page (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'large-movement)))

(defadvice hexl-end-of-1k-page (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'large-movement)))

(defadvice hexl-beginning-of-512b-page (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'large-movement)))

(defadvice hexl-end-of-512b-page (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'large-movement)))

(defadvice hexl-scroll-up (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'scroll)
    (emacspeak-hexl-speak-current-address)))

(defadvice hexl-scroll-down (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'scroll)
    (emacspeak-hexl-speak-current-address)))

(defadvice hexl-goto-address (after emacspeak pre act comp)
  "Provide speech feedback."
  (when (ems-interactive-p)
    (emacspeak-hexl-speak-current-byte-code)))

(defadvice hexl-goto-hex-address (after emacspeak pre act comp)
  "Provide speech feedback."
  (when (ems-interactive-p)
    (emacspeak-hexl-speak-current-byte-code)))

(defadvice hexl-mode (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'on)))

(defadvice hexl-mode-exit (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'off)))

(defadvice hexl-find-file (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)))

(defadvice hexlify-buffer (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)))

;;}}}
;;{{{ Keymap tweaking:

(cl-declaim (special hexl-mode-map
		  emacspeak-prefix))
(define-key hexl-mode-map emacspeak-prefix (make-sparse-keymap))
(define-key hexl-mode-map (concat emacspeak-prefix "\C-l")
  'emacspeak-hexl-speak-current-line-address)
(define-key hexl-mode-map (concat emacspeak-prefix "=")
  'emacspeak-hexl-speak-current-position)
(define-key hexl-mode-map (concat emacspeak-prefix "+")
  'emacspeak-hexl-speak-current-address)
(define-key hexl-mode-map (concat emacspeak-prefix "c")
  'emacspeak-hexl-speak-current-byte-code)
(emacspeak-rebind 'emacspeak-self-insert-command 'hexl-self-insert-command hexl-mode-map)
(emacspeak-rebind 'beginning-of-buffer 'hexl-beginning-of-buffer hexl-mode-map)
(emacspeak-rebind 'end-of-buffer 'hexl-end-of-buffer hexl-mode-map)

;;}}}

(provide 'emacspeak-hexl)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; end:

;;}}}
