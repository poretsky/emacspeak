;;; emacspeak-ps.el --- Speech enable Ps Mode  -*- lexical-binding: t; -*-
;;; Author: Igor B. Poretsky <poretsky@mlbox.ru>
;;; Description: Emacspeak extensions for ps-mode
;;; Keywords: emacspeak, audio interface to emacs ps mode
;;{{{  LCD Archive entry: 

;;}}}
;;{{{  Copyright:
;;;Copyright (C) 2005, Igor B. Poretsky <poretsky@mlbox.ru>
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

;;{{{  Introduction:

;;; Provide additional advice to ps-mode 

;;}}}
;;{{{ requires
(require 'emacspeak-preamble)

;;}}}
;;{{{  Advice interactive functions:

(defadvice ps-mode-newline (around emacspeak pre act comp)
  "Speak the previous line if line echo is on.
See command \\[emacspeak-toggle-line-echo].
Otherwise cue user to the line just created."
  (cl-declare (special emacspeak-line-echo ))
  (cond
   ((ems-interactive-p)
    (cond
     (emacspeak-line-echo
      (emacspeak-speak-line )
      ad-do-it)
     (t ad-do-it
        (dtk-speak-using-voice voice-annotate
                               (format
                                "indent %s"
                                (current-column)))
        (dtk-force))))
   (t ad-do-it))
  ad-return-value)

(defadvice ps-mode-tabkey (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'large-movement)
    (emacspeak-speak-current-column)))

(defadvice ps-mode-backward-delete-char (around emacspeak pre act comp)
  "Speak character you're deleting."
  (cond
   ((ems-interactive-p )
    (dtk-tone 500 30 'force)
    (emacspeak-speak-this-char (preceding-char ))
    ad-do-it)
   (t ad-do-it))
  ad-return-value)

(cl-loop for f in
      '(ps-mode-r-brace ps-mode-r-angle ps-mode-r-gt)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
	  "Speak the character you inserted"
	  (when (ems-interactive-p)
	    (emacspeak-speak-this-char last-input-char)))))

(defadvice ps-mode-comment-out-region (after emacspeak pre act comp)
  "Provide spoken feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'section)
    (message "Commented region containing %s lines"
	     (count-lines (point) (mark)))))

(defadvice ps-mode-uncomment-region (after emacspeak pre act comp)
  "Provide spoken feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'section)
    (message "Uncommented region containing %s lines"
	     (count-lines (point) (mark)))))

(defadvice ps-mode-epsf-rich (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'yank-object)))

(defadvice ps-run-start (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)))

(cl-loop for f in
      '(ps-run-buffer
	ps-run-clear
	ps-run-region
	ps-run-boundingbox
	ps-mode-print-buffer)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
	  "Provide an auditory icon if possible"
	  (when (ems-interactive-p)
	    (emacspeak-auditory-icon 'task-done)))))

(cl-loop for f in
      '(ps-run-kill ps-run-quit)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
	  "Provide an auditory icon if possible"
	  (when (ems-interactive-p)
	    (emacspeak-auditory-icon 'close-object)))))

(cl-loop for f in
      '(ps-run-goto-error ps-run-mouse-goto-error)
      do
      (eval
       `(defadvice ,f (after  emacspeak pre act comp)
	  "Speak the line containing the error. "
	  (when (ems-interactive-p)
            (dtk-stop)
	    (let ((dtk-stop-immediately nil)
		  (emacspeak-show-point t))
	      (emacspeak-speak-line))))))

(defadvice ps-mode-show-version (around emacspeak pre act comp)
  "Provide speech feedback."
  (if (ems-interactive-p)
      (let ((emacspeak-speak-messages t)
            (emacspeak-last-message nil)
            (inhibit-message nil))
	ad-do-it)
    ad-do-it)
  ad-return-value)

;;}}}

(provide  'emacspeak-ps)
;;{{{  emacs local variables 

;;; local variables:
;;; folded-file: t
;;; end: 

;;}}}
