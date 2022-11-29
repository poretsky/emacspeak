;;; emacspeak-python.el --- Speech enable Python development environment  -*- lexical-binding: t; -*-
;;; $Id$
;;; $Author: tv.raman.tv $
;;; Description: Auditory interface to python mode
;;; Keywords: Emacspeak, Speak, Spoken Output, python
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

;;; Copyright (c) 1995 -- 2018, T. V. Raman
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

;;{{{ Introduction

;;; Commentary:

;;; This speech-enables python-mode bundled with Emacs

;;; Code:

;;}}}
;;{{{  Required modules
(require 'cl-lib)
(cl-declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)
(eval-when-compile
  (require 'python () 'no-error))
;;}}}
;;{{{ Forward declarations

(declare-function python-beginning-of-defun "python.el" ())
(declare-function python-end-of-defun "python.el" ())

;;}}}
;;{{{ Advice interactive commands:

;;{{{  electric editing

(unless (and (boundp 'post-self-insert-hook)
             post-self-insert-hook
             (memq 'emacspeak-post-self-insert-hook post-self-insert-hook))
  (cl-loop for f in
        '(py-electric-colon
          python-electric-colon)
        do
        (eval
         `(defadvice ,f (after emacspeak pre act comp)
            "Speak what you inserted"
            (when (ems-interactive-p)
              (dtk-say " colon "))))))

(cl-loop for f in
      '(py-electric-backspace
        py-electric-delete
        python-electric-backspace
        python-electric-delete
        python-backspace)
      do
      (eval
       `(defadvice ,f (before emacspeak pre act comp)
          "Speak character you're deleting."
          (when (ems-interactive-p)
            (dtk-tone 500 30 'force)
            (emacspeak-speak-this-char (preceding-char ))))))

;;}}}
;;{{{ interactive programming

(defadvice python-check (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'task-done)))
(cl-loop
 for f in
 '(
   python-shell-send-region python-shell-send-defun
   python-shell-send-file   python-shell-send-buffer
   python-shell-send-string python-shell-send-string-no-output)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Provide auditory feedback"
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'task-done)))))

;;}}}
;;{{{  whitespace management and indentation
(defadvice python-indent-dedent-line (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-speak-line)
    (emacspeak-auditory-icon 'right)))

(defadvice  python-indent-dedent-line-backspace (around emacspeak pre act)
  "Speak character you're deleting."
  (cond
   ((ems-interactive-p)
    (let ((ws (= 32 (char-syntax (preceding-char)))))
      (dtk-tone 500 100 'force)
      (unless ws (emacspeak-speak-this-char (preceding-char)))
      ad-do-it
      (when ws (dtk-notify-speak (format "Indent %s " (current-column))))))
   (t ad-do-it))
  ad-return-value)

(defadvice python-fill-paragraph (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'fill-object)))

(defadvice python-indent-shift-left (after emacspeak pre act comp)
  "Speak number of lines that were shifted"
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'left)
    (dtk-speak
     (format "Left shifted block  containing %s lines"
             (count-lines  (region-beginning)
                           (region-end))))))
(defadvice python-indent-shift-right (after emacspeak pre act comp)
  "Speak number of lines that were shifted"
  (when (ems-interactive-p)
    (dtk-speak
     (format "Right shifted block  containing %s lines"
             (count-lines  (region-beginning)
                           (region-end))))))
(defadvice python-indent-region (after emacspeak pre act comp)
  "Speak number of lines that were shifted"
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'right)
    (dtk-speak
     (format "Indented region   containing %s lines"
             (count-lines  (region-beginning)
                           (region-end))))))

(defadvice py-comment-region (after emacspeak pre act comp)
  "Speak number of lines that were shifted"
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'section)
    (dtk-speak
     (format "Commented  block  containing %s lines"
             (count-lines  (region-beginning)
                           (region-end))))))

;;}}}
;;{{{  buffer navigation

(cl-loop
 for f in
 '(
   python-nav-up-list python-nav-if-name-main python-nav-forward-statement
   python-nav-forward-sexp-safe python-nav-forward-sexp python-nav-forward-defun
   python-nav-forward-block python-nav-end-of-statement python-nav-end-of-defun
   python-nav-end-of-block python-nav-beginning-of-statement python-nav-beginning-of-block
   python-nav-backward-up-list python-nav-backward-statement python-nav-backward-sexp-safe
   python-nav-backward-sexp python-nav-backward-defun python-nav-backward-block
   py-previous-statement py-next-statement py-goto-block-up
   py-beginning-of-def-or-class py-end-of-def-or-class
   beginning-of-python-def-or-class end-of-python-def-or-class
   python-previous-statement python-next-statement python-beginning-of-block
   python-beginning-of-def-or-class python-end-of-def-or-class
   )
 do
 (eval
  `(defadvice  ,f (after emacspeak pre act comp)
     "Provide auditory feedback."
     (when (ems-interactive-p)
       (emacspeak-speak-line)
       (emacspeak-auditory-icon 'paragraph)))))

(cl-loop for f in
      '(py-mark-block
        py-mark-def-or-class
        python-mark-block
        python-mark-def-or-class)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Speak number of lines marked"
          (when (ems-interactive-p)
            (emacspeak-auditory-icon 'mark-object)
            (dtk-speak
             (format "Marked block containing %s lines"
                     (count-lines (region-beginning)
                                  (region-end))))))))

(cl-loop for f in
      '(py-narrow-to-defun
        python-narrow-to-defun)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Provide auditory feedback."
          (when (ems-interactive-p)
            (message "%s %s lines"
                     (save-mark-and-excursion
                       (goto-char (point-min))
                       (buffer-substring (line-beginning-position)
                                         (line-end-position)))
                     (count-lines (point-min)
                                  (point-max)))))))

(cl-loop for f in
      '(py-forward-into-nomenclature
        py-backward-into-nomenclature
        python-forward-into-nomenclature
        python-backward-into-nomenclature)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Speak rest of current word"
          (when (ems-interactive-p)
            (emacspeak-speak-word 1)))))

;;}}}
;;{{{ the process buffer

(defadvice python-process-filter (around emacspeak pre act) comp
  "Make comint in Python speak its output. "
  (cl-declare (special emacspeak-comint-autospeak))
  (let ((prior (point))
        (dtk-stop-immediately nil))
    ad-do-it 
    (when (and  emacspeak-comint-autospeak
                (window-live-p
                 (get-buffer-window (process-buffer (ad-get-arg 0)))))
      (condition-case nil
          (emacspeak-speak-region prior (point))
        (error (dtk-stop)
               (emacspeak-auditory-icon 'scroll))))
    ad-return-value))

;;}}}

;;}}}
;;{{{ Additional navigation
(defun emacspeak-python-previous-block()
  "Move backward to the beginning of the current block.
If already at the beginning then move to previous block."
  (interactive)
  (let ((start (point)))
    (python-beginning-of-defun)
    (unless (eq start (point))
      (beginning-of-line)
      (emacspeak-auditory-icon 'large-movement)
      (emacspeak-speak-line))))

(defun emacspeak-python-next-block()
  "Move forward to the beginning of the next block."
  (interactive)
  (python-end-of-defun)
  (skip-syntax-forward " ")
  (forward-line 1)
  (beginning-of-line)
  (emacspeak-auditory-icon 'large-movement)
  (emacspeak-speak-line))

;;}}}
;;{{{ keybindings

(progn
  (cl-declaim (special  python-mode-map))
  (define-key python-mode-map "\M-a" 'beginning-of-python-def-or-class)
  (define-key python-mode-map "\M-e" 'end-of-python-def-or-class)
  (define-key python-mode-map "\M-n" 'python-next-statement)
  (define-key python-mode-map "\M-p" 'python-previous-statement)
  (define-key python-mode-map "\C-\M-u" 'python-goto-block-up)
  (define-key python-mode-map "\C-\M-n" 'emacspeak-python-next-block)
  (define-key python-mode-map "\C-\M-p" 'emacspeak-python-previous-block)
  )

(cl-declaim (special  py-mode-map))
(add-hook 'python-mode-hook
          (function (lambda ()
                      (cl-declare (special py-mode-map))
                      (when (and  (boundp 'py-mode-map)
                                  py-mode-map)
                        (define-key py-mode-map "\M-a" 'beginning-of-python-def-or-class)
                        (define-key py-mode-map "\M-e" 'end-of-python-def-or-class)
                        (define-key py-mode-map "\M-n" 'py-next-statement)
                        (define-key py-mode-map "\M-p" 'py-previous-statement)
                        (define-key py-mode-map "\C-\M-u" 'py-goto-block-up)
                        (define-key py-mode-map "\C-\M-n" 'emacspeak-py-next-block)
                        (define-key py-mode-map "\C-\M-p" 'emacspeak-py-previous-block)
                        ))))

;;}}}
(provide 'emacspeak-python)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
