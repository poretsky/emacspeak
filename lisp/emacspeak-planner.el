;;; emacspeak-planner.el --- speech-enable Planner -- a powerful organizer in Emacs  -*- lexical-binding: t; -*-
;;; Description: Emacspeak extensions for planner-mode
;;; Keywords: Emacspeak, organizer, day planner, daily schedule
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

;;; PlannerMode is an organizer and day planner for Emacs.  It helps you
;;; keep track of your pending and completed tasks, daily schedule, dates
;;; to remember, notes and inspirations. It is a powerful tool not only for
;;; managing your time and productivity, but also for keeping within easy
;;; keystroke reach all of the information you need to be productive.
;;; This module speech-enables PlannerMode.

;;}}}
;;{{{ Advice interactive commands to speak.

(cl-loop for f in
      '(plan
	planner-goto-today
	planner-goto-tomorrow
	planner-goto-yesterday
	planner-goto-next-daily-page
	planner-goto-previous-daily-page
	planner-goto
	planner-list-tasks-with-status
	planner-list-unfinished-tasks
	planner-jump-to-linked-task
	planner-accomplishments-show
	planner-timeclock-summary-show
	planner-timeclock-summary-show-range
	planner-tasks-overview
	planner-tasks-overview-jump
	planner-id-jump-to-linked-task)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
	  "Produce an auditory icon if possible."
	  (when (ems-interactive-p)
	    (emacspeak-auditory-icon 'open-object)
	    (with-current-buffer (window-buffer)
	      (emacspeak-speak-mode-line))))))

(cl-loop for f in
      '(planner-task-in-progress
	planner-task-done
	planner-task-cancelled
	planner-task-delegated
	planner-task-pending
	planner-task-open
	planner-raise-task
	planner-lower-task
	planner-raise-task-priority
	planner-lower-task-priority
	planner-id-add-task)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
	  "Produce an auditory icon if possible."
	  (when (ems-interactive-p)
	    (emacspeak-auditory-icon 'mark-object)))))

(cl-loop for f in
      '(planner-create-task-from-buffer
	planner-create-high-priority-task-from-buffer
	planner-create-medium-priority-task-from-buffer
	planner-create-low-priority-task-from-buffer
	planner-create-task
	planner-replan-task
	planner-edit-task-description
	planner-replan-note
	planner-deadline-change)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
	  "Produce an auditory icon if possible."
	  (when (ems-interactive-p)
	    (emacspeak-auditory-icon 'save-object)))))

(cl-loop for f in
      '(planner-copy-or-move-task
	planner-copy-or-move-region
	planner-update-task
	planner-sort-tasks
	planner-renumber-tasks
	planner-align-tasks
	planner-update-note
	planner-fix-tasks
	planner-accomplishments-update
	planner-tasks-overview-sort-by-date
	planner-tasks-overview-sort-by-plan
	planner-tasks-overview-sort-by-priority
	planner-tasks-overview-sort-by-status
	planner-id-add-task-id-to-all
	planner-id-update-tasks-on-page
	planner-deadline-update)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
	  "Produce an auditory icon if possible."
	  (when (ems-interactive-p)
	    (emacspeak-auditory-icon 'task-done)))))

(defadvice planner-delete-task (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'delete-object)))

(defadvice planner-seek-next-unfinished-task (after emacspeak pre act comp)
  "Provide speech feedback."
  (when (ems-interactive-p)
    (if ad-return-value
        (progn
          (emacspeak-auditory-icon 'delete-object)
          (emacspeak-speak-line))
      (emacspeak-auditory-icon 'warn-user)
      (dtk-speak-and-echo "No more unfinished tasks"))))

(defadvice planner-calendar-show (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (if ad-return-value
        (emacspeak-auditory-icon 'help)
      (emacspeak-auditory-icon 'warn-user)
      (dtk-speak-and-echo "No planner file for this date"))))

(defadvice planner-schedule-show-end-project (around emacspeak pre act comp)
  "Provide speech feedback."
  (if (ems-interactive-p)
      (let ((emacspeak-speak-messages t)
            (emacspeak-last-message nil)
            (inhibit-message nil))
	(emacspeak-auditory-icon 'select-object)
	ad-do-it)
    ad-do-it)
  ad-return-value)

;;}}}
(provide 'emacspeak-planner)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; end:

;;}}}
