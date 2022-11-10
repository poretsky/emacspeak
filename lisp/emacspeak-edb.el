;; emacspeak-edb.el --- Speech interface for the EDB package  -*- lexical-binding: t; -*-

;; Copyright  (C)  2005  Sergei V. Fleytin <fleytin@mail.ru>

;; Version: 0.1
;; Keywords: emacspeak, database speech interface
;; Author: Sergei V. Fleytin <fleytin@mail.ru>

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
;; 02111-1307, USA.

;; Commentary: 

;; This software is my attempt to provide speech support for EDB
;; package. EDB, is another database program for Gnu Emacs. It has
;; much more features than traditional forms-mode. Currently, EDB is
;; in a very early stage of development and many of it's features are
;; not yet fully implemented but, in my opinion, it is already very
;; useful. So I decided to write a speech interface for it. Not all
;; features of EDB are supported in this release, But I will try to
;; fix it in future versions.

;; Code:

(require 'cl-lib)
(cl-declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)

(declare-function dbf-this-field-end-pos "ext:db-format.el" ())
(declare-function edb--S "ext:db-util.el" (property))

;; First, let's fix some keybindings.

(cl-declaim (special database-view-mode-map
		  database-edit-mode-map
		  emacspeak-prefix))
(define-key database-view-mode-map emacspeak-prefix 'emacspeak-prefix-command)
(define-key database-edit-mode-map emacspeak-prefix 'emacspeak-prefix-command)
(define-key database-edit-mode-map [home] 'db-beginning-of-line-or-field)
(define-key database-edit-mode-map [end] 'db-end-of-line-or-field)
(define-key database-edit-mode-map [down] 'db-next-line-or-field)
(define-key database-edit-mode-map [up] 'db-previous-line-or-field)
(define-key database-edit-mode-map [right] 'db-forward-char)
(define-key database-edit-mode-map [left] 'db-backward-char)

;; Helper functions.

(defun emacspeak-edb-speak-current-field ()
  "Speak the field under point."
  (let ((beg-pos (edb--S :fbeg)))
    (if beg-pos
        (emacspeak-speak-region beg-pos (dbf-this-field-end-pos))
      (message "Not within a field")
      (ding))))

;; Now, advising some functions.

(defadvice emacspeak-speak-current-field (around emacspeak-edb pre act comp)
  "Treat fealds appropriately in the database mode."
  (if (and (ems-interactive-p)
	   (eq major-mode 'database-mode))
      (emacspeak-edb-speak-current-field)
    ad-do-it))

(cl-loop for f in
      '(db-find-file db-summary)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
	  "Provide auditory feedback."
	  (when (ems-interactive-p)
	    (emacspeak-auditory-icon 'open-object)
	    (emacspeak-speak-mode-line)))))

(cl-loop for f in
      '(db-first-field
	db-last-field
	db-add-record
	db-copy-record)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
	  "Provide auditory feedback."
	  (when (ems-interactive-p)
	    (emacspeak-auditory-icon 'open-object)
	    (emacspeak-speak-line)))))

(cl-loop for f in
      '(db-next-field db-previous-field)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
	  "Provide auditory feedback."
	  (when (ems-interactive-p)
	    (emacspeak-auditory-icon 'select-object)
	    (emacspeak-edb-speak-current-field)))))

(defadvice db-view-mode (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'close-object)))

(cl-loop for f in
      '(db-next-record
	db-previous-record
	db-first-record
	db-last-record
	db-jump-to-record
	db-next-screen-or-record
	db-previous-screen-or-record)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
	  "Provide auditory feedback. Play auditory icon if possible."
	  (when (ems-interactive-p)
	    (dtk-stop)
	    (emacspeak-auditory-icon 'scroll)
	    (if (string-match "Database.*Summary" mode-name)
		(emacspeak-speak-next-window)
	      (emacspeak-speak-current-window))))))

(cl-loop for f in
      '(db-next-line-or-field db-previous-line-or-field)
      do
      (eval
       `(defadvice ,f (around emacspeak pre act comp)
	  "Provide auditory feedback."
	  (if (ems-interactive-p)
	      (let ((prev (edb--S :this-fidx)))
		ad-do-it
		(unless (= prev (edb--S :this-fidx))
		  (emacspeak-auditory-icon 'select-object))
		(emacspeak-speak-line))
	    ad-do-it)
	  ad-return-value)))

(defadvice dbs-view (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-current-window)))

(cl-loop for f in
      '(db-quit db-exit dbs-exit)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
	  "Provide auditory feedback."
	  (when (ems-interactive-p)
	    (emacspeak-auditory-icon 'close-object)
	    (emacspeak-speak-mode-line)))))

(cl-loop for f in
      '(db-save-database
	db-write-database-file
	db-accept-record)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
	  "Provide auditory feedback."
	  (when (ems-interactive-p)
	    (emacspeak-auditory-icon 'save-object)))))

(defadvice db-mark-record (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'mark-object)))

(cl-loop for f in
      '(db-isearch-forward db-isearch-backward)
      do
      (eval
       `(defadvice ,f (before emacspeak pre act comp)
	  "Provide auditory feedback. Stop ongoing speech first."
	  (when (ems-interactive-p)
	    (dtk-stop)
	    (emacspeak-auditory-icon 'open-object)))))

(defadvice db-search-field (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'search-hit)
    (emacspeak-speak-line)))

(defadvice db-delete-record (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'delete-object)
    (emacspeak-speak-line)))

(cl-loop for f in
      '(db-sort db-report)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
	  "Provide an auditory icon when finished."
	  (when (ems-interactive-p)
	    (emacspeak-auditory-icon 'task-done)))))

(defadvice db-newline (around emacspeak pre act comp)
  "Speak the previous line if line echo is on.
See command \\[emacspeak-toggle-line-echo].  Otherwise cue the user to
the newly created blank line or speak the next field
if we were moved to."
  (cl-declare (special emacspeak-line-echo))
  (if (ems-interactive-p)
      (if (not emacspeak-line-echo)
	  (let ((prev (edb--S :this-fidx)))
	    ad-do-it
	    (if (not (= prev (edb--S :this-fidx)))
		(emacspeak-edb-speak-current-field)
	      (when dtk-stop-immediately (dtk-stop))
	      (dtk-tone 225 120 'force)))
	(emacspeak-speak-line )
	ad-do-it)
    ad-do-it)
  ad-return-value)

(defadvice db-kill-region (around emacspeak pre act comp)
  "Indicate region has been killed.
Use an auditory icon if possible."
  (cond
   ((ems-interactive-p)
    (let ((count (count-lines (region-beginning)
                              (region-end))))
      ad-do-it
      (emacspeak-auditory-icon 'delete-object )
      (message "Killed region containing %s lines" count)))
   (t ad-do-it))
  ad-return-value)

(defadvice db-copy-region-as-kill (after emacspeak pre act comp)
  "Indicate that region has been copied to the kill ring.
Produce an auditory icon if possible."
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'mark-object )
    (message "region containing %s lines  copied to kill ring "
             (count-lines (region-beginning)
                          (region-end)))))

(defadvice db-kill-to-end (around emacspeak pre act comp)
  "Indicate region has been killed.
Use an auditory icon if possible."
  (cond
   ((ems-interactive-p)
    (let ((count (count-lines (point) (dbf-this-field-end-pos))))
      ad-do-it
      (emacspeak-auditory-icon 'delete-object )
      (message "Killed region containing %s lines" count)))
   (t ad-do-it))
  ad-return-value)

(defadvice db-kill-word (before emacspeak pre act comp)
  "Speak word before killing it."
  (when (ems-interactive-p )
    (save-excursion
      (skip-syntax-forward " ")
      (when dtk-stop-immediately (dtk-stop))
      (let ((dtk-stop-immediately nil))
        (dtk-tone 500 30)
        (emacspeak-speak-word 1 )))))

(defadvice db-backward-kill-word (before emacspeak pre act comp)
  "Speak word before killing it."
  (when (ems-interactive-p )
    (when dtk-stop-immediately (dtk-stop))
    (let ((start (point ))
          (dtk-stop-immediately nil))
      (save-excursion
        (forward-word -1)
        (dtk-tone 500 30)
        (emacspeak-speak-region (point) start )))))

(defadvice db-kill-line(before emacspeak pre act comp)
  "Speak line before killing it. "
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'delete-object)
    (when dtk-stop-immediately (dtk-stop))
    (let ((dtk-stop-immediately nil))
      (dtk-tone 500 30)
      (emacspeak-speak-line 1))))

(defadvice db-backward-delete-char (around emacspeak pre act comp)
  "Speak character you're deleting."
  (cond
   ((ems-interactive-p )
    (dtk-tone 500 30 'force)
    (emacspeak-speak-this-char (preceding-char ))
    (let ((pos (point)))
      ad-do-it
      (when (= pos (point))
	(ding))))
   (t ad-do-it))
  ad-return-value)

(defadvice db-delete-char (around emacspeak pre act comp)
  "Speak character you're deleting."
  (cond
   ((ems-interactive-p )
    (dtk-tone 500 30 'force)
    (emacspeak-speak-char t)
    ad-do-it)
   (t ad-do-it))
  ad-return-value)

(cl-loop for f in
      '(db-beginning-of-line-or-field db-end-of-line-or-field)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act)
	  "Provide auditory feedback."
	  (when (ems-interactive-p)
	    (dtk-stop)
	    (emacspeak-auditory-icon 'select-object)))))

(cl-loop for f in
      '(db-forward-char db-backward-char)
      do
      (eval
       `(defadvice ,f (around emacspeak pre act comp)
	  "Speak character moved to. Produce an auditory icon if we can not move."
	  (let ((prevpos (point)))
	    ad-do-it
	    (if (ems-interactive-p)
		(if (= (point) prevpos)
		    (emacspeak-auditory-icon 'warn-user)
		  (and dtk-stop-immediately (dtk-stop))
		  (emacspeak-speak-char t)))
	    ad-return-value))))

(defadvice db-forward-word (after emacspeak pre act)
  "Speak the word you just moved to."
  (when (ems-interactive-p)
    (skip-syntax-forward " ")
    (emacspeak-speak-word )))

(defadvice db-backward-word (after emacspeak pre act)
  "Speak the word you just moved to."
  (when (ems-interactive-p)
    (emacspeak-speak-word )))

(provide 'emacspeak-edb)

;;; local variables:
;;; end: 
