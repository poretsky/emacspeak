;;; emacspeak-gnus.el --- Speech enable GNUS -- Fluent spoken access to imap, usenet  -*- lexical-binding: t; -*-
;;; $Id$
;;; $Author: tv.raman.tv $ 
;;; Description:  Emacspeak extension to speech enable Gnus
;;; Keywords: Emacspeak, Gnus, Advice, Spoken Output, News
;;{{{  LCD Archive entry: 

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu 
;;; A speech interface to Emacs |
;;; $Date: 2008-06-21 10:50:41 -0700 (Sat, 21 Jun 2008) $ |
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
;;{{{  Introduction:

;;; Commentary:

;;; This module advises gnus to speak. 
;;; Updating support in 2014 (Emacspeak is nearly 20 years old)
;;; Updating in 2018 as I switch to gnus as my primary mail interface.
;;; These customizations to gnus make it convenient to listen to news:
;;; You can read news mostly by using the four arrow keys.
;;; By default all article headers are hidden, so you hear the real news.

;;; Code:

;;}}}
;;{{{ requires

(require 'cl-lib)
(cl-declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)
(require 'emacspeak-hide)
(require 'emacspeak-webutils)
(require 'gnus)
(require 'gnus-art)
(require 'gnus-sum)
(require 'gm-nnir) ; for smart GMail search

;;}}}
;;{{{ Forward declarations

(declare-function gnus-group-topic-p "gnus-topic")
(declare-function gnus-group-topic-name "gnus-topic")

;;}}}
;;{{{  Customizations:

(defgroup emacspeak-gnus nil
  "Emacspeak customizations for the Gnus News/Mail/RSS reader"
  :group 'emacspeak
  :group 'gnus
  :prefix "emacspeak-gnus-")

(defcustom emacspeak-gnus-punctuation-mode  'all
  "Pronunciation mode to use for gnus buffers."
  :type '(choice
          (const  :tag "Ignore" nil)
          (const  :tag "some" some)
          (const  :tag "all" all))
  :group 'emacspeak-gnus)

(defcustom  emacspeak-gnus-large-article 100
  "*Articles having more than
emacspeak-gnus-large-article lines will be considered to be a large article.
A large article is not spoken all at once;
instead you hear only the first screenful."
  :type 'integer
  :group 'emacspeak-gnus 
  )

;;; Keybindings 
(defun emacspeak-gnus-setup-keys ()
  "Setup Emacspeak keys."
  (cl-declare (special gnus-summary-mode-map
                       gnus-group-mmode-map
                       gnus-article-mode-map))
  (define-key gnus-summary-mode-map "\C-t" 'gnus-summary-toggle-header)
  (define-key gnus-summary-mode-map "t" 'gnus-summary-toggle-header)
  (define-key  gnus-group-mode-map "?" 'gm-nnir-group-make-nnir-group)
  (define-key gnus-group-mode-map "/" 'gm-nnir-group-make-gmail-group)
  (define-key gnus-group-mode-map ";" 'emacspeak-gnus-personal-gmail-recent)
  (define-key gnus-group-mode-map ":" 'emacspeak-gnus-personal-gmail-last-week)
  (define-key gnus-group-mode-map "\C-n" 'gnus-group-next-group)
  (define-key gnus-group-mode-map "\C-p" 'gnus-group-prev-group)
  (define-key gnus-summary-wash-map "D" 'gnus-summary-downcase-article))

(add-hook 'gnus-started-hook 'emacspeak-gnus-setup-keys)

;;}}}
;;{{{  helper functions

(defun emacspeak-gnus-summary-speak-subject ()
  (dtk-speak (gnus-summary-article-subject)))

(defun emacspeak-gnus-speak-article-body ()
  (cl-declare (special emacspeak-gnus-large-article
                       voice-lock-mode dtk-punctuation-mode
                       gnus-article-buffer))
  (with-current-buffer gnus-article-buffer
    (goto-char (point-min))
    (search-forward "\n\n")
    (cond
     ((< (count-lines (point) (point-max))
         emacspeak-gnus-large-article)
      (emacspeak-speak-rest-of-buffer))
     (t (emacspeak-auditory-icon 'large-movement)
        (let ((start (point))
              (window (get-buffer-window (current-buffer))))
          (with-selected-window window
            (save-mark-and-excursion
              (move-to-window-line -1)
              (end-of-line)
              (emacspeak-speak-region start (point)))))))))

;;}}}
;;{{{ Advise top-level gnus command

;;; emacs can hang if too many message sfly by as gnus starts
(defadvice gnus (around emacspeak pre act)
  "Silence messages, produce auditory icon."
  (dtk-speak  "Starting gnus")
  (ems-with-messages-silenced ad-do-it)
  (emacspeak-auditory-icon 'news)
  (message "Gnus is ready "))

(cl-loop
 for f in
 '(gnus-group-suspend
   gnus-group-quit
   gnus-group-exit
   gnus-browse-exit
   gnus-server-exit
   gnus-edit-form-done)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Provide auditory contextual feedback."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'close-object)
       (emacspeak-speak-mode-line)))))

(cl-loop
 for f in
 '(gnus-group-edit-group-parameters
   gnus-topic-edit-parameters)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Provide auditory contextual feedback."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'open-object)
       (emacspeak-speak-mode-line)))))

(cl-loop
 for f in
 '(gnus-group-delete-group
   gnus-group-kill-group
   gnus-group-kill-region
   gnus-topic-kill-group
   gnus-topic-remove-group)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Provide auditory feedback."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'delete-object)
       (emacspeak-speak-line)))))

(cl-loop
 for f in
 '(gnus-group-yank-group
   gnus-topic-yank-group)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Provide auditory feedback."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'yank-object)
       (emacspeak-speak-line)))))

;;}}}
;;{{{  starting up:

(cl-loop
 for f in
 '(gnus-group-post-news gnus-group-mail)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Provide auditory feedback."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'open-object)
       (emacspeak-speak-line)))))

(defadvice gnus-group-get-new-news (around emacspeak pre act)
  "Temporarily silence on message"
  (dtk-speak  "Getting new  gnus")
  (ems-with-messages-silenced ad-do-it)
  (message "Gnus is ready ")
  (emacspeak-auditory-icon 'news))

(defadvice nnheader-message-maybe (around emacspeak pre act comp)
  "Silence emacspeak"
  (ems-with-messages-silenced ad-do-it))

;;}}}
;;{{{  prompts and queries:

(defadvice gnus-multiple-choice (around emacspeak pre act comp)
  "Provide auditory feedback."
  (cl-declare (special emacspeak-speak-messages emacspeak-last-message inhibit-message))
  (emacspeak-auditory-icon 'ask-short-question )
  (let ((emacspeak-speak-messages t)
        (emacspeak-last-message nil)
        (inhibit-message))
    (tts-with-punctuations 'all ad-do-it)
    ad-return-value))

;;}}}
;;{{{  Newsgroup selection

(cl-loop
 for f in
 '(gnus-group-select-group gnus-group-first-unread-group
                           gnus-group-read-group
                           gnus-group-prev-group gnus-group-next-group
                           gnus-group-prev-unread-group  gnus-group-next-unread-group
                           gnus-group-get-new-news-this-group
                           gnus-group-best-unread-group gnus-group-jump-to-group
                           gnus-group-enter-server-mode gnus-server-edit-buffer
                           gnus-server-read-server gnus-server-read-server-in-server-buffer
                           gnus-browse-select-group
                           )
 do
 (eval
  `(defadvice ,f (after emacspeak pre act)
     "Provide auditory feedback."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'select-object)
       (emacspeak-speak-line)))))

(cl-loop
 for f in
 '(gnus-topic-select-group gnus-topic-read-group)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act)
     "Provide auditory feedback."
     (when (ems-interactive-p)
       (if (gnus-group-topic-p)
           (emacspeak-auditory-icon
            (if (gnus-topic-visible-p)
                'open-object
              'close-object))
         (emacspeak-auditory-icon 'select-object)
         (emacspeak-speak-line))))))

(cl-loop
 for f in
 '(gnus-group-unsubscribe-current-group
   gnus-browse-unsubscribe-current-group
   gnus-group-unmark-group
   gnus-topic-unmark-topic)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Produce an auditory icon indicating
this group is being deselected."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'deselect-object)
       (emacspeak-speak-line)))))

(cl-loop
 for f in
 '(gnus-group-mark-group gnus-topic-mark-topic)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Produce an auditory icon indicating
this group is being marked or unmarked."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon
        (if (ad-get-arg 0)
            'deselect-object
          'mark-object))
       (emacspeak-speak-line)))))

(cl-loop
 for f in
 '(gnus-group-sort-groups
   gnus-group-sort-groups-by-alphabet
   gnus-group-sort-groups-by-unread
   gnus-group-sort-groups-by-level
   gnus-group-sort-groups-by-score
   gnus-group-sort-groups-by-rank
   gnus-group-sort-groups-by-method
   gnus-group-sort-groups-by-real-name
   gnus-group-sort-selected-groups-by-alphabet
   gnus-group-sort-selected-groups-by-unread
   gnus-group-sort-selected-groups-by-level
   gnus-group-sort-selected-groups-by-score
   gnus-group-sort-selected-groups-by-rank
   gnus-group-sort-selected-groups-by-method
   gnus-group-sort-selected-groups-by-real-name
   gnus-group-sort-selected-groups
   gnus-topic-sort-groups-by-alphabet
   gnus-topic-sort-groups-by-unread
   gnus-topic-sort-groups-by-level
   gnus-topic-sort-groups-by-score
   gnus-topic-sort-groups-by-rank
   gnus-topic-sort-groups-by-method
   gnus-topic-sort-groups-by-server
   gnus-topic-sort-groups)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Produce an auditory icon indicating task completion."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'task-done)))))

(defadvice gnus-group-catchup-current (after emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'mark-object)
    (emacspeak-speak-line)))

(defadvice gnus-group-list-groups (after emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (dtk-speak "Listing groups... done")))

(defadvice gnus-topic-mode (after emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (cl-declare (special gnus-topic-mode))
  (when (ems-interactive-p)
    (emacspeak-auditory-icon (if gnus-topic-mode 'on 'off))
    (message "Toggled topic mode %s" (if gnus-topic-mode "on" "off"))))

(defadvice gnus-topic-show-topic (after emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)))

(defadvice gnus-topic-hide-topic (after emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'close-object)))

(defadvice gnus-topic-indent (after emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon
     (if (ad-get-arg 0)
         'left
       'right))))

(defadvice gnus-topic-unindent (after emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'left)))

(defadvice gnus-article-fill-long-lines (after emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'modified-object)
    (dtk-speak "wrapped long lines")))

(defadvice gnus-group-list-all-groups (after emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (dtk-speak "Listing all groups... done")))

(defadvice gnus-group-list-all-matching (after emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (dtk-speak "Listing all matching groups... done")))

(defadvice gnus-group-list-killed (after emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (dtk-speak "Listing killed groups... done")))

(defadvice gnus-group-list-matching (after emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (dtk-speak "listing matching groups with unread articles... done")))

(defadvice gnus-group-list-zombies (after emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (dtk-speak "Listing zombie groups... done")))

(defadvice gnus-group-customize (around emacspeak pre act comp)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (if (and (gnus-topic-mode-p) (gnus-group-topic-p))
        (message "Customizing topic %s" (gnus-group-topic-name))
      (message "Customizing group %s" (gnus-group-group-name))))
  (let ((max-specpdl-size 2000))
    ad-do-it)
  ad-return-value)

;;}}}
;;{{{  summary mode 
(cl-loop
 for f in
 '(
   gnus-summary-clear-mark-backward gnus-summary-clear-mark-forward
   gnus-summary-unmark-as-processable
   ) do
 (eval
  `(defadvice   ,f (around  emacspeak pre act)
     "Speak the article  line.
 Produce an auditory icon if possible."
     (let ((saved-point (point)))
       ad-do-it
       (when (ems-interactive-p)
         (emacspeak-auditory-icon 'deselect-object)
         (if (= saved-point (point))
             (dtk-speak "No more articles")
           (emacspeak-gnus-summary-speak-subject)))
       ad-return-value))))

(cl-loop
 for f in
 '(gnus-summary-mark-as-dormant
   gnus-summary-mark-as-expirable
   gnus-summary-mark-as-processable
   gnus-summary-mark-as-read-backward
   gnus-summary-mark-as-read-forward
   gnus-summary-mark-as-unread-backward
   gnus-summary-mark-as-unread-forward
   gnus-summary-tick-article-backward
   gnus-summary-tick-article-forward)
 do
 (eval
  `(defadvice ,f  (around  emacspeak pre act comp)
     "Speak the next article subject. Produce an auditory icon if possible."
     (let ((saved-point (point)))
       ad-do-it
       (when (ems-interactive-p)
         (emacspeak-auditory-icon 'mark-object)
         (if (= saved-point (point))
             (dtk-speak "No more articles")
           (emacspeak-gnus-summary-speak-subject)))
       ad-return-value))))

(defadvice gnus-summary-mark-region-as-read (after emacspeak pre act comp)
  "Produce an auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'mark-object)
    (message "%s articles marked as read"
             (count-lines (region-beginning)
                          (region-end)))))

(cl-loop
 for f in
 '(gnus-summary-delete-article
   gnus-summary-kill-same-subject
   gnus-summary-kill-thread)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Speak the next article subject. Produce an auditory icon if possible."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon  'delete-object)
       (emacspeak-gnus-summary-speak-subject)))))

(cl-loop
 for f in
 '(
   gnus-summary-catchup-to-here gnus-summary-catchup-from-here
   ) do
 (eval
  `(defadvice  ,f (after emacspeak pre act)
     "Speak the line.
 Produce an auditory icon if possible."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon  'mark-object)
       (emacspeak-gnus-summary-speak-subject)))))

(defadvice  gnus-summary-select-article-buffer (after emacspeak pre act)
  "Speak the modeline.
Indicate change of selection with
  an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-mode-line)))

(cl-loop
 for f in
 '(gnus-summary-prev-article
   gnus-summary-next-article
   gnus-summary-prev-unread-article
   gnus-summary-next-unread-article
   gnus-summary-prev-same-subject
   gnus-summary-next-same-subject)
 do
 (eval
  `(defadvice ,f (around emacspeak pre act comp)
     "Speak the article. "
     (let ((saved-point (point)))
       ad-do-it
       (when (ems-interactive-p)
         (if (= saved-point (point))
             (dtk-speak "No more articles")
           (emacspeak-auditory-icon 'open-object)
           (emacspeak-gnus-speak-article-body)))
       ad-return-value))))

(cl-loop
 for f in
 '(gnus-summary-exit-no-update
   gnus-summary-exit
   gnus-summary-catchup-and-exit)
 do
 (eval
  `(defadvice ,f (around emacspeak pre act comp)
     "Say the next unread newsgroup. Play an auditory icon if possible."
     (let ((cur-group gnus-newsgroup-name))
       ad-do-it
       (when (ems-interactive-p)
         (emacspeak-auditory-icon 'close-object)
         (if (eq cur-group (gnus-group-group-name))
             (dtk-speak "No more unread newsgroups")
           (emacspeak-speak-line)))
       ad-return-value))))

(cl-loop
 for f in
 '(gnus-summary-prev-subject
   gnus-summary-next-subject
   gnus-summary-prev-unread-subject
   gnus-summary-next-unread-subject
   gnus-summary-goto-subject
   gnus-summary-prev-thread
   gnus-summary-next-thread
   gnus-summary-up-thread
   gnus-summary-down-thread)
 do
 (eval
  `(defadvice ,f (around  emacspeak pre act comp)
     "Speak the article subject. Produce an auditory icon if possible."
     (let ((saved-point (point)))
       ad-do-it
       (when (ems-interactive-p)
         (if (= saved-point (point))
             (dtk-speak "No more articles")
           (emacspeak-auditory-icon 'select-object)
           (emacspeak-gnus-summary-speak-subject)))
       ad-return-value))))

(cl-loop
 for f in
 '(gnus-topic-goto-next-topic
   gnus-topic-goto-previous-topic
   gnus-topic-jump-to-topic)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Provide auditory feedback."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'item)
       (emacspeak-speak-line)))))

(cl-loop
 for f in
 '(gnus-summary-mail-forward
   gnus-summary-post-news
   gnus-summary-mail-other-window)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Provide auditory feedback."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'open-object)
       (emacspeak-speak-line)))))

(cl-loop
 for f in
 '(gnus-summary-reply
   gnus-summary-reply-with-original
   gnus-summary-wide-reply
   gnus-summary-wide-reply-with-original
   gnus-summary-very-wide-reply
   gnus-summary-very-wide-reply-with-original)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Provide auditory feedback."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'open-object)))))

(defadvice gnus-summary-resend-message (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'task-done)))

(defadvice gnus-summary-kill-same-subject-and-select (after emacspeak pre act comp)
  "Speak the subject and speak the first screenful.
Produce an auditory icon
indicating the article is being opened."
  (cl-declare (special gnus-article-buffer))
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'delete-object)
    (emacspeak-gnus-summary-speak-subject)
    (sit-for 2)
    (emacspeak-auditory-icon 'open-object)
    (with-current-buffer
        gnus-article-buffer
      (let ((start  (point))
            (window (get-buffer-window (current-buffer))))
        (with-selected-window window
          (save-mark-and-excursion
            (move-to-window-line -1)
            (end-of-line)
            (emacspeak-speak-region start (point))))))))

(defadvice gnus-summary-save-article (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'save-object)))

(defadvice mm-save-part (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (emacspeak-auditory-icon 'save-object))

(defadvice gnus-summary-display-article (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (emacspeak-auditory-icon 'open-object))

(defadvice gnus-summary-toggle-header (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (cl-declare (special gnus-article-buffer))
  (when (ems-interactive-p)
    (with-current-buffer gnus-article-buffer
      (emacspeak-auditory-icon
       (if (gnus-article-hidden-text-p 'headers) 'off 'on)))))

(cl-loop
 for f in
 '(gnus-summary-first-unread-article gnus-summary-goto-last-article)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Start speaking the article. "
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'open-object)
       (emacspeak-gnus-speak-article-body)))))

(cl-loop
 for f in
 '(gnus-summary-next-page gnus-summary-prev-page)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Speak the article page content."
     (cl-declare (special gnus-article-buffer))
     (dtk-stop)
     (emacspeak-auditory-icon 'scroll)
     (with-current-buffer gnus-article-buffer
       (let ((start  (point))
             (window (get-buffer-window (current-buffer))))
         (with-selected-window window
           (save-mark-and-excursion
             (move-to-window-line -1)
             (end-of-line)
             (emacspeak-speak-region start (point)))))))))

(cl-loop
 for f in
 '(gnus-summary-beginning-of-article gnus-summary-end-of-article)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Speak the first line. "
     (cl-declare (special gnus-article-buffer))
     (with-current-buffer gnus-article-buffer
       (emacspeak-speak-line)))))

;;}}}
;;{{{  Draft specific commands

(defadvice gnus-draft-edit-message (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)))

(defadvice gnus-draft-send-message (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'task-done)))

(defadvice gnus-draft-send-all-messages (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'task-done)))

(defadvice gnus-draft-toggle-sending (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (ems-interactive-p)
    (emacspeak-auditory-icon
     (if (= (char-after (line-beginning-position)) ?\ )
         'deselect-object
       'mark-object))))

(defadvice gnus-summary-hide-all-threads (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (emacspeak-speak-line)))

;;}}}
;;{{{  Article reading

(defadvice gnus-article-describe-key-briefly (after emacspeak pre act comp)
  "Speak what you displayed."
  (when (ems-interactive-p)
    (dtk-speak ad-return-value))
  ad-return-value)

(cl-loop
 for f in
 '(gnus-article-edit-exit
   gnus-article-edit-done)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Provide auditory feedback."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'close-object)
       (emacspeak-speak-line)))))

(defadvice gnus-article-mail (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-line)))

(defadvice gnus-summary-show-article (after emacspeak pre act)
  "Start speaking the article. "
  (when (ems-interactive-p)
    (with-current-buffer gnus-article-buffer
      (emacspeak-auditory-icon 'open-object)
      (emacspeak-hide-all-blocks-in-buffer)
      (emacspeak-gnus-speak-article-body))))

(defadvice gnus-article-show-summary  (after emacspeak pre act)
  "Speak the modeline.
Indicate change of selection with
  an auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-mode-line)))

(cl-loop
 for f in
 '(gnus-article-next-page
   gnus-article-prev-page
   gnus-article-goto-next-page
   gnus-article-goto-prev-page)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Speak the current window full of news."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'scroll)
       (emacspeak-speak-current-window)))))

(defadvice gnus-article-next-button (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (ems-interactive-p)
    (let ((end (next-single-property-change
                (point) 'gnus-callback)))
      (emacspeak-auditory-icon 'large-movement)
      (message (buffer-substring
                (point)end)))))

(defadvice gnus-article-press-button (before emacspeak pre act comp)
  "Provide auditory feedback"
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'button)))

(defadvice gnus-article-mode (after emacspeak pre act comp)
  "Turn on voice lock mode."
  (voice-lock-mode (if global-voice-lock-mode 1 -1)))

(defun gnus-summary-downcase-article ()
  "Downcases the article body
Helps to prevent words from being spelled instead of spoken."
  (interactive)
  (gnus-summary-select-article-buffer)
  (article-goto-body)
  (let ((beg (point))
        (end (point-max))
        (inhibit-read-only t))
    (downcase-region beg end))
  (gnus-article-show-summary)
  (emacspeak-auditory-icon 'modified-object)
  (dtk-speak "Downcased article body"))

;;}}}
;;{{{ refreshing the pronunciation  and punctuation mode

(cl-loop
 for hook  in 
 '(
   gnus-article-mode-hook gnus-group-mode-hook gnus-summary-mode-hook
   gnus-agent-mode-hook  gnus-article-edit-mode-hook
   gnus-server-mode-hook gnus-category-mode-hook
   )
 do
 (add-hook
  hook 
  #'(lambda ()
      (dtk-set-punctuations emacspeak-gnus-punctuation-mode)
      (emacspeak-pronounce-refresh-pronunciations))))

(cl-declaim (special emacspeak-pronounce-internet-smileys-pronunciations))
(emacspeak-pronounce-augment-pronunciations 'gnus-article-mode
                                            emacspeak-pronounce-internet-smileys-pronunciations)

;;}}}
;;{{{ rdc: mapping font faces to personalities 

;; article buffer personalities

;; Since citation does not normally go beyond 4 levels deep, in my 
;; experience, there are separate voices for the first four levels
;; and then they are repeated
(voice-setup-add-map
 ;; NOTE
 ;; face names are either marked at the end of the line with a comment
 ;; consisting of the emacs version or they are unmarked.  The unmarked 
 ;; face names are for gnus shipped with emacs 22 
 ;; rdc 102206
 '(
   (gnus-cite-1 voice-bolden-medium)
   (gnus-cite-2 voice-lighten) 
   (gnus-cite-3 voice-lighten-extra)
   (gnus-cite-4 voice-smoothen)
   (gnus-cite-5 voice-smoothen-extra)
   (gnus-cite-6 voice-lighten)
   (gnus-cite-7 voice-lighten-extra)
   (gnus-cite-8 voice-bolden)
   (gnus-cite-9 voice-bolden-medium)
   (gnus-cite-10 voice-lighten)
   (gnus-cite-11 voice-lighten-extra)
   (gnus-emphasis-highlight-words voice-lighten-extra)
   (gnus-emphasis-bold voice-bolden-and-animate)
   (gnus-emphasis-strikethru voice-bolden-extra)
   (gnus-emphasis-italic voice-lighten)
   (gnus-emphasis-underline voice-brighten-extra)
   (gnus-signature voice-animate)
   (gnus-header-content voice-bolden)
   (gnus-header-name voice-animate)
   (gnus-header-from voice-bolden)
   (gnus-header-newsgroups voice-bolden)
   (gnus-header-subject voice-bolden)
   ;; ;; summary buffer personalities
   ;; since there are so many distinctions, most variations
   ;; on the same thing are given the same voice.  Any user that
   ;; uses low and high interest is sufficiently advanced to change
   ;; the voice to his own preferences
   (gnus-summary-normal-read voice-smoothen)
   (gnus-summary-high-read voice-bolden)
   (gnus-summary-low-read voice-bolden)
   (gnus-summary-normal-ticked voice-brighten-extra)
   (gnus-summary-high-ticked voice-brighten-extra)
   (gnus-summary-low-ticked voice-brighten-extra)
   (gnus-summary-normal-ancient voice-smoothen-extra)
   (gnus-summary-high-ancient voice-smoothen-extra)
   (gnus-summary-low-ancient voice-smoothen-extra)
   (gnus-summary-normal-undownloaded voice-bolden-and-animate)
   (gnus-summary-low-undownloaded voice-bolden-and-animate)
   (gnus-summary-low-unread voice-bolden-medium)
   (gnus-summary-high-unread voice-brighten-extra)
   (gnus-summary-selected voice-animate-extra)
   (gnus-summary-cancelled voice-bolden-extra)

   ;; group buffer personalities
   ;; I think the voice used for the groups in the buffer should be the 
   ;; default voice.  I might ask if there is a call for different voices 
   ;; as they are only necessary if users have persistently visible groups
   ;; in the case of empty groups, and voices for the various levels.
   (gnus-group-mail-1-empty voice-bolden-extra)
   (gnus-group-mail-2-empty voice-bolden-extra)
   
   (gnus-group-mail-3-empty  voice-bolden-extra)
   
   (gnus-group-mail-low-empty voice-bolden-extra)
   
   (gnus-group-news-1-empty voice-bolden-extra)
   
   (gnus-group-news-2-empty voice-bolden-extra)
   
   (gnus-group-news-3-empty voice-bolden-extra)
   
   (gnus-group-news-4-empty voice-bolden-extra)
   
   (gnus-group-news-5-empty voice-bolden-extra)
   
   (gnus-group-news-6-empty voice-bolden-extra)
   
   (gnus-group-news-low-empty voice-bolden-extra)
   
   
   ;; server buffer personalities

   (gnus-server-agent voice-bolden)
   (gnus-server-closed voice-bolden-medium)
   (gnus-server-denied voice-bolden-extra)
   (gnus-server-offline voice-animate)
   (gnus-server-opened voice-lighten)))

;;}}}
;;{{{ Async Gnus:

;;}}}
;;{{{ GMail Search Accelerators:

;;;###autoload
(defun emacspeak-gnus-personal-gmail-recent ()
  "Look for mail addressed personally in the last day."
  (interactive)
  (gm-nnir-group-make-gmail-group
   (format "newer_than:1d to:me -cc:%s" user-mail-address)))

;;;###autoload
(defun emacspeak-gnus-personal-gmail-last-week()
  "Look for mail addressed personally in the last week."
  (interactive)
  (gm-nnir-group-make-gmail-group
   (format
    "after:%s before:%s to:me -cc:%s"
    (format-time-string "%Y/%m/%d" (time-subtract (current-time) (* 7 86400)))
    (format-time-string "%Y/%m/%d")
    user-mail-address)))

;;}}}
(provide 'emacspeak-gnus)
;;{{{  end of file 
;;; local variables:
;;; folded-file: t
;;; end: 
;;}}}
