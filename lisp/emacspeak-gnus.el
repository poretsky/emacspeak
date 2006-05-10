;;; emacspeak-gnus.el --- Speech enable GNUS -- Fluent spoken access to usenet
;;; $Id: emacspeak-gnus.el,v 24.0 2006/05/03 02:54:00 raman Exp $
;;; $Author: raman $ 
;;; Description:  Emacspeak extension to speech enable Gnus
;;; Keywords: Emacspeak, Gnus, Advice, Spoken Output, News
;;{{{  LCD Archive entry: 

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu 
;;; A speech interface to Emacs |
;;; $Date: 2006/05/03 02:54:00 $ |
;;;  $Revision: 24.0 $ | 
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:
;;;Copyright (C) 1995 -- 2004, T. V. Raman 
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

;;; This module advices gnus to speak. 

;;}}}
;;{{{ requires
(require 'emacspeak-preamble)
(require 'gnus)
(require 'gnus-sum)

;;}}}
;;{{{  Customizations:

;;; These customizations to gnus make it convenient to listen to news:
;;; You can read news mostly by using the four arrow keys.
;;; By default all article headers are hidden, so you hear the real news.
;;; You can expose some of the headers with "T" in summary mode.

;;; Keybindings 
(defun emacspeak-gnus-setup-keys ()
  "Setup Emacspeak keys."
  (declare (special gnus-summary-mode-map
                    gnus-group-mode-map
                    gnus-article-mode-map))
  (when (boundp 'gnus-summary-mode-map)
    (emacspeak-keymap-remove-emacspeak-edit-commands gnus-summary-mode-map))
  (when (boundp 'gnus-article-mode-map)
    (emacspeak-keymap-remove-emacspeak-edit-commands gnus-article-mode-map))
  (when (boundp 'gnus-group-mode-map)
    (emacspeak-keymap-remove-emacspeak-edit-commands gnus-group-mode-map))
  (define-key gnus-summary-mode-map "\C-t" 'gnus-summary-toggle-header)
  (define-key gnus-summary-mode-map "T" 'gnus-summary-hide-all-headers )
  (define-key gnus-summary-mode-map "t"
    'gnus-summary-show-some-headers)
  (define-key gnus-summary-mode-map '[left] 'emacspeak-gnus-summary-catchup-quietly-and-exit)
  (define-key gnus-summary-mode-map '[right] 'gnus-summary-show-article)
  (define-key gnus-group-mode-map "\C-n" 'gnus-group-next-group)
  (define-key gnus-group-mode-map [down] 'gnus-group-next-group)
  (define-key gnus-group-mode-map [up] 'gnus-group-prev-group)
  (define-key gnus-group-mode-map "\C-p" 'gnus-group-prev-group)
  (define-key gnus-group-mode-map '[right]
    'gnus-group-read-group))

(add-hook 'gnus-started-hook 'emacspeak-gnus-setup-keys)

;;}}}
;;{{{  Hiding headers

(defvar  gnus-ignored-most-headers
  (concat
   "^Path:\\|^Posting-Version:\\|^Article-I.D.:\\|^Expires:"
   "\\|^Date-Received:\\|^References:\\|^Control:\\|^Xref:"
   "\\|^Lines:\\|^Posted:\\|^Relay-Version:\\|^Message-ID:\\|^Nf-ID:"
   "\\|^Nf-From:\\|^Approved:\\|^Sender:"
   "\\|^Organization:\\|^Approved:\\|^Distribution:\\|^Apparently-To:"
   "\\|^Keywords:\\|^Copyright:\\|^X-Supersedes:\\|^ACategory: \\|^Slugword:"
   "\\|^Priority:\\|^ANPA:\\|^Codes:"
   "\\|^Originator:\\|^Comment:\\|^NNTP-Posting-Host:\\|Original-To:"
   "\\|^Followup-To:\\|^Original-Cc:\\|^Reply-To:")
  "Article headers to ignore when only important article headers are to be
spoken.
See command \\[gnus-summary-show-some-headers].")
(declaim (special gnus-ignored-headers))
(setq gnus-ignored-headers "^.*:")
(declaim (special gnus-visible-headers))
(setq gnus-visible-headers "^Subject:")

(defun gnus-summary-show-some-headers ()
  "Show only the important article headers,
i.e. sender name, and subject."
  (interactive)
  (declare (special gnus-ignored-most-headers )) 
  (let ((gnus-ignored-headers gnus-ignored-most-headers ))
    (gnus-summary-toggle-header 1)
    (gnus-summary-toggle-header -1)))

(defun gnus-summary-hide-all-headers()
  "Hide all headers in the article.
Use this command if you don't want to listen to any article headers when
reading news."
  (interactive)
  (let ((gnus-ignored-headers "^.*:"))
    (gnus-summary-toggle-header 1 )
    (gnus-summary-toggle-header -1)))

;;}}}
;;{{{  helper functions

(defsubst emacspeak-gnus-summary-speak-subject ()
  (emacspeak-dtk-sync)
  (dtk-speak (gnus-summary-article-subject )))

(defsubst emacspeak-gnus-speak-article-body ()
  (declare (special emacspeak-gnus-large-article
                    voice-lock-mode dtk-punctuation-mode))
  (save-excursion
    (set-buffer  "*Article*")
    (goto-char (point-min))
    (setq dtk-punctuation-mode 'some)
    (voice-lock-mode 1)
    (emacspeak-dtk-sync)
    (cond
     ((< (count-lines (point-min) (point-max))
         emacspeak-gnus-large-article)
      (emacspeak-speak-buffer  ))
     (t (emacspeak-auditory-icon 'large-movement )
        (let ((start (point)))
          (move-to-window-line -1)
          (end-of-line)
          (emacspeak-speak-region start (point)))))))


;;}}}
;;{{{ Advise top-level gnus command

;;; emacs can hang if too many message sfly by as gnus starts
(defadvice gnus (around emacspeak pre act )
  "Temporarily deactivate advice on message"
  (let ((startup (not (gnus-alive-p)))
	(dtk-stop-immediately nil))
    (cond
     ((and startup (interactive-p))
      (dtk-speak  "Starting gnus")
      (let ((emacspeak-speak-messages nil))
	ad-do-it)
      (emacspeak-auditory-icon 'news)
      (message "Gnus is ready ")
      (emacspeak-speak-line))
     (t				; gnus alive or non-interactive call
      ad-do-it
      (when (interactive-p)
	(emacspeak-auditory-icon 'select-object)
	(emacspeak-speak-line))))))

(defadvice gnus-group-suspend (after emacspeak pre act)
  "Provide auditory contextual feedback."
  (when (interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (emacspeak-speak-mode-line)))

(defadvice gnus-group-quit (after emacspeak pre act)
  "Provide auditory contextual feedback."
  (when (interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (emacspeak-speak-mode-line)))

(defadvice gnus-group-exit (after emacspeak pre act)
  "Provide auditory contextual feedback."
  (when (interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (emacspeak-speak-mode-line)))

;;}}}
;;{{{  starting up:

(defadvice gnus-group-post-news (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-line)))

(defadvice gnus-group-mail (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-line)))

(defadvice gnus-group-get-new-news (around emacspeak pre act )
  "Temporarily deactivate advice on message"
  (dtk-speak  "Getting new  gnus")
  (sit-for 2)
  (let ((emacspeak-speak-messages nil ))
    ad-do-it)
  (when (interactive-p)
    (emacspeak-auditory-icon 'task-done)
    (message "Done ")))



;;}}}
;;{{{  Newsgroup selection

(defadvice gnus-group-select-group (before emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (interactive-p)
    (emacspeak-auditory-icon 'open-object)))

(defadvice gnus-group-first-unread-group (after emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-line)))

(defadvice gnus-group-read-group  (after  emacspeak pre act)
  "Speak the first article line.
 Produce an auditory icon indicating 
an object has been opened."
  (when (interactive-p) 
    (emacspeak-auditory-icon 'open-object)
    (dtk-speak (gnus-summary-article-subject))))

(defadvice gnus-group-prev-group (around emacspeak pre act)
  "Speak the newsgroup line.
 Produce an auditory icon if possible."
  (let ((saved-point (point )))
    (when (interactive-p)
      (emacspeak-auditory-icon 'select-object))
    ad-do-it
    (when (interactive-p)
      (if (= saved-point (point))
          (dtk-speak "No more newsgroups ")
        (emacspeak-speak-line))))
  ad-return-value)

(defadvice gnus-group-prev-unread-group (around emacspeak pre act)
  "Speak the newsgroup line.
 Produce an auditory icon if possible."
  (let ((saved-point (point )))
    (when (interactive-p)
      (emacspeak-auditory-icon 'select-object))
    ad-do-it
    (when (interactive-p)
      (if (= saved-point (point))
          (dtk-speak "No more newsgroups ")
        (emacspeak-speak-line))))
  ad-return-value)

(defadvice gnus-group-next-group (around emacspeak pre act)
  "Speak the newsgroup line.
 Produce an auditory icon if possible."
  (let ((saved-point (point )))
    (when (interactive-p) 
      (emacspeak-auditory-icon 'select-object))
    ad-do-it
    (when (interactive-p)
      (if (= saved-point (point))
          (dtk-speak "No more newsgroups")
        (emacspeak-speak-line)))))

(defadvice gnus-group-next-unread-group (around emacspeak pre act)
  "Speak the newsgroup line.
 Produce an auditory icon if possible."
  (let ((saved-point (point )))
    (when (interactive-p)
      (emacspeak-auditory-icon 'select-object))
    ad-do-it
    (when (interactive-p)
      (if (= saved-point (point))
          (dtk-speak "No more newsgroups")
        (emacspeak-speak-line)))))

(defadvice gnus-group-best-unread-group (after emacspeak pre act comp)
  "Provide spoken feedback."
  (when (interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-line)))

(defadvice gnus-group-first-unread-group (after emacspeak pre act comp)
  "Provide spoken feedback."
  (when (interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-line)))

(defadvice gnus-group-jump-to-group (after emacspeak pre act comp)
  (when (interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-line)))

(defadvice gnus-group-unsubscribe-current-group (after emacspeak pre act)
  "Produce an auditory icon indicating
this group is being deselected."
  (when (interactive-p)
    (emacspeak-auditory-icon 'deselect-object)
    (emacspeak-speak-line )))

(defadvice gnus-group-catchup-current (after emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (emacspeak-speak-line)))

(defadvice gnus-group-yank-group (after emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (interactive-p)
    (emacspeak-auditory-icon 'yank-object)
    (emacspeak-speak-line)))

(defadvice gnus-group-get-new-news-this-group  (after emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-line)))

(defadvice gnus-group-list-groups (after emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (dtk-speak "Listing groups... done")))

(defadvice gnus-group-list-all-groups (after emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (dtk-speak "Listing all groups... done")))

(defadvice gnus-group-list-all-matching (after emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (dtk-speak "Listing all matching groups... done")))

(defadvice gnus-group-list-killed (after emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (dtk-speak "Listing killed groups... done")))

(defadvice gnus-group-list-matching (after emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (dtk-speak "listing matching groups with unread articles... done")))

(defadvice gnus-group-list-zombies (after emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (dtk-speak "Listing zombie groups... done")))

(defadvice gnus-group-customize (before emacspeak pre act)
  "Provide auditory feedback.
 Produce an auditory icon if possible."
  (when (interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (message "Customizing group %s" (gnus-group-group-name))))



;;}}}
;;{{{  summary mode 

(defadvice gnus-summary-clear-mark-backward  (around  emacspeak pre act)
  "Speak the article  line.
 Produce an auditory icon if possible."
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (if (= saved-point (point))
          (dtk-speak "No more articles")
        (progn 
          (emacspeak-auditory-icon 'select-object )
          (dtk-speak (gnus-summary-article-subject )))))
    ad-return-value ))

(defadvice gnus-summary-clear-mark-forward  (around  emacspeak pre act)
  "Speak the article  line.
 Produce an auditory icon if possible."
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (if (= saved-point (point))
          (dtk-speak "No more articles")
        (progn 
          (emacspeak-auditory-icon 'select-object )
          (dtk-speak (gnus-summary-article-subject )))))
    ad-return-value ))

(defadvice gnus-summary-mark-as-dormant (around  emacspeak pre act)
  "Speak the article  line.
 Produce an auditory icon if possible."
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (if (= saved-point (point))
          (dtk-speak "No more articles")
        (progn 
	  (emacspeak-auditory-icon 'mark-object)
	  (emacspeak-gnus-summary-speak-subject ))))
    ad-return-value ))

(defadvice gnus-summary-mark-as-expirable (around  emacspeak pre act)
  "Speak the article  line.
 Produce an auditory icon if possible."
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (if (= saved-point (point))
          (dtk-speak "No more articles")
        (progn 
	  (emacspeak-auditory-icon 'mark-object)
	  (emacspeak-gnus-summary-speak-subject ))))
    ad-return-value ))

(defadvice gnus-summary-mark-as-processable (around  emacspeak pre act)
  "Speak the article  line.
 Produce an auditory icon if possible."
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (if (= saved-point (point))
          (dtk-speak "No more articles")
        (progn 
	  (emacspeak-auditory-icon 'mark-object)
	  (emacspeak-gnus-summary-speak-subject ))))
    ad-return-value ))

(defadvice gnus-summary-unmark-as-processable (after emacspeak pre act)
  "Speak the line.
 Produce an auditory icon if possible."
  (when (interactive-p)
    (emacspeak-auditory-icon 'deselect-object)
    (emacspeak-gnus-summary-speak-subject )))

(defadvice gnus-summary-tick-article-backward (around  emacspeak pre act)
  "Speak the article  line.
 Produce an auditory icon if possible."
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (if (= saved-point (point))
          (dtk-speak "No more articles")
        (progn 
	  (emacspeak-auditory-icon 'mark-object)
	  (emacspeak-gnus-summary-speak-subject ))))
    ad-return-value ))

(defadvice gnus-summary-tick-article-forward (around  emacspeak pre act)
  "Speak the article  line.
 Produce an auditory icon if possible."
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (if (= saved-point (point))
          (dtk-speak "No more articles")
        (progn 
	  (emacspeak-auditory-icon 'mark-object)
	  (emacspeak-gnus-summary-speak-subject ))))
    ad-return-value ))

(defadvice gnus-summary-delete-article (after emacspeak pre act)
  "Speak the line.
 Produce an auditory icon if possible."
  (when (interactive-p)
    (emacspeak-auditory-icon  'delete-object)
    (emacspeak-gnus-summary-speak-subject )))

(defadvice gnus-summary-catchup-from-here (after emacspeak pre act)
  "Speak the line.
 Produce an auditory icon if possible."
  (when (interactive-p)
    (emacspeak-auditory-icon  'mark-object)
    (emacspeak-gnus-summary-speak-subject )))

(defadvice gnus-summary-catchup-to-here (after emacspeak pre act)
  "Speak the line.
 Produce an auditory icon if possible."
  (when (interactive-p)
    (emacspeak-auditory-icon  'mark-object)
    (emacspeak-gnus-summary-speak-subject )))

(defadvice  gnus-summary-select-article-buffer (after emacspeak pre act)
  "Speak the modeline.
Indicate change of selection with
  an auditory icon if possible."
  (when (interactive-p )
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-mode-line)))

(defadvice gnus-summary-prev-article (after emacspeak pre act)
  "Speak the article. "
  (when (interactive-p)
    (emacspeak-gnus-speak-article-body)))

(defadvice gnus-summary-next-article (after emacspeak pre act)
  "Speak the article. "
  (when (interactive-p)
    (emacspeak-gnus-speak-article-body)))

(defadvice gnus-summary-exit-no-update  (around emacspeak pre act)
  "Speak the modeline.
Indicate change of selection with
  an auditory icon if possible."
  (let ((cur-group gnus-newsgroup-name ))
    ad-do-it
    (when (interactive-p )
      (emacspeak-auditory-icon 'close-object)
      (if (eq cur-group (gnus-group-group-name))
          (dtk-speak "No more unread newsgroups")
        (progn 
	  (emacspeak-speak-line))))
    ad-return-value ))

(defadvice gnus-summary-exit  (around emacspeak pre act)
  "Speak the modeline.
Indicate change of selection with
  an auditory icon if possible."
  (let ((cur-group gnus-newsgroup-name ))
    ad-do-it
    (when (interactive-p )
      (emacspeak-auditory-icon 'close-object)
      (if (eq cur-group (gnus-group-group-name))
          (dtk-speak "No more unread newsgroups")
        (progn 
	  (emacspeak-speak-line))))
    ad-return-value ))

(defadvice gnus-summary-prev-subject  (around  emacspeak pre act)
  "Speak the article  line.
 Produce an auditory icon if possible."
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (if (= saved-point (point))
          (dtk-speak "No more articles ")
        (progn 
          (emacspeak-auditory-icon 'select-object )
          (dtk-speak (gnus-summary-article-subject )))))
    ad-return-value ))

(defadvice gnus-summary-next-subject  (around  emacspeak pre act)
  "Speak the article  line. 
Produce an auditory icon if possible."
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (if (= saved-point (point))
          (dtk-speak "No more articles ")
        (progn 
          (emacspeak-auditory-icon 'select-object )
          (dtk-speak (gnus-summary-article-subject )))))
    ad-return-value ))

(defadvice gnus-summary-prev-unread-subject  (around  emacspeak pre act)
  "Speak the article  line.
 Produce an auditory icon if possible."
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (if (= saved-point (point))
          (dtk-speak "No more unread articles ")
        (progn 
          (emacspeak-auditory-icon 'select-object )
          (dtk-speak (gnus-summary-article-subject )))))
    ad-return-value ))

(defadvice gnus-summary-next-unread-subject  (around  emacspeak pre act)
  "Speak the article line.
Produce an auditory icon if possible."
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (if (= saved-point (point))
          (dtk-speak "No more articles ")
        (progn 
          (emacspeak-auditory-icon 'select-object )
          (dtk-speak (gnus-summary-article-subject )))))
    ad-return-value))

(defadvice gnus-summary-goto-subject (around  emacspeak pre act)
  "Speak the article  line.
 Produce an auditory icon if possible."
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (if (= saved-point (point))
          (dtk-speak "No more articles ")
        (progn 
          (emacspeak-auditory-icon 'select-object )
          (dtk-speak (gnus-summary-article-subject )))))
    ad-return-value ))

(defadvice gnus-summary-catchup-and-exit (around emacspeak pre act)
  "Speak the newsgroup line.
 Produce an auditory icon indicating 
the previous group was closed."
  (if (interactive-p)
      (let ((dtk-stop-immediately nil)
	    (emacspeak-speak-messages t))
	ad-do-it
	(emacspeak-auditory-icon 'close-object)
	(emacspeak-speak-line ))
    ad-do-it)
  ad-return-value)

(defadvice gnus-summary-post-news (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-line)))

(defadvice gnus-summary-mail-other-window (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-line)))

(defadvice gnus-summary-reply (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'open-object)))

(defadvice gnus-summary-reply-with-original (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'open-object)))

(defadvice gnus-summary-resend-message (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'task-done)))

(defadvice gnus-summary-exit (around emacspeak pre act comp)
  "Speak the line in group buffer."
  (if (interactive-p)
      (let ((dtk-stop-immediately nil)
	    (emacspeak-speak-messages t))
	ad-do-it
	(emacspeak-auditory-icon 'close-object)
	(emacspeak-speak-line ))
    ad-do-it)
  ad-return-value)

(defadvice gnus-summary-clear-mark-forward (around emacspeak pre act comp)
  "Speak the line.
 Produce an auditory icon if possible."
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (emacspeak-auditory-icon 'deselect-object )
      (if (= saved-point (point))
          (dtk-speak "No more articles ")
	(dtk-speak (gnus-summary-article-subject ))))
    ad-return-value ))

(defadvice gnus-summary-mark-as-unread-forward (around emacspeak pre act)
  "Speak the line.
 Produce an auditory icon if possible."
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (emacspeak-auditory-icon 'mark-object )
      (if (= saved-point (point))
          (dtk-speak "No more articles ")
	(dtk-speak (gnus-summary-article-subject ))))
    ad-return-value ))

(defadvice gnus-summary-mark-as-read-forward (around emacspeak pre act)
  "Speak the line.
 Produce an auditory icon if possible."
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (emacspeak-auditory-icon 'mark-object )
      (if (= saved-point (point))
          (dtk-speak "No more articles ")
	(dtk-speak (gnus-summary-article-subject ))))
    ad-return-value ))

(defadvice gnus-summary-mark-as-unread-backward (around emacspeak pre act)
  "Speak the line.
 Produce an auditory icon if possible."
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (emacspeak-auditory-icon 'mark-object )
      (if (= saved-point (point))
          (dtk-speak "No more articles ")
	(dtk-speak (gnus-summary-article-subject ))))
    ad-return-value ))

(defadvice gnus-summary-mark-as-read-backward (around emacspeak pre act)
  "Speak the line.
 Produce an auditory icon if possible."
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (emacspeak-auditory-icon 'mark-object )
      (if (= saved-point (point))
          (dtk-speak "No more articles ")
	(dtk-speak (gnus-summary-article-subject ))))
    ad-return-value ))

(defadvice gnus-summary-mark-as-processable (around emacspeak pre act)
  "Speak the line.
 Produce an auditory icon if possible."
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (emacspeak-auditory-icon 'mark-object )
      (if (= saved-point (point))
          (dtk-speak "No more articles ")
	(dtk-speak (gnus-summary-article-subject ))))
    ad-return-value ))

(defadvice gnus-summary-unmark-as-processable (around emacspeak pre act)
  "Speak the line.
 Produce an auditory icon if possible."
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (emacspeak-auditory-icon 'deselect-object )
      (if (= saved-point (point))
          (dtk-speak "No more articles ")
	(dtk-speak (gnus-summary-article-subject ))))
    ad-return-value ))

(defadvice gnus-summary-tick-article-forward (around emacspeak pre act)
  "Speak the line.
 Produce an auditory icon if possible."
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (emacspeak-auditory-icon 'mark-object )
      (if (= saved-point (point))
          (dtk-speak "No more articles ")
	(dtk-speak (gnus-summary-article-subject ))))
    ad-return-value ))

(defadvice gnus-summary-tick-article-backward (around emacspeak pre act)
  "Speak the line.
 Produce an auditory icon if possible."
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (emacspeak-auditory-icon 'mark-object )
      (if (= saved-point (point))
          (dtk-speak "No more articles ")
	(dtk-speak (gnus-summary-article-subject ))))
    ad-return-value ))

(defadvice gnus-summary-kill-same-subject-and-select (after emacspeak pre act)
  "Speak the subject and speak the first screenful.
Produce an auditory icon
indicating the article is being opened."
  (when (interactive-p)
    (emacspeak-gnus-summary-speak-subject)
    (sit-for 2)
    (emacspeak-auditory-icon 'open-object)
    (save-excursion
      (set-buffer  "*Article*")
      (emacspeak-dtk-sync)
      (let ((start  (point ))
            (window (get-buffer-window (current-buffer ))))
        (forward-line (window-height window))
        (emacspeak-speak-region start (point ))))))

(defadvice gnus-summary-kill-same-subject (after emacspeak pre act)
  "Speak the line.
 Produce an auditory icon if possible."
  (when (interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-gnus-summary-speak-subject )))

(defadvice gnus-summary-next-thread (after emacspeak pre act)
  "Speak the line.
 Produce an auditory icon if possible."
  (when (interactive-p) 
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-gnus-summary-speak-subject )))

(defadvice gnus-summary-prev-thread (after emacspeak pre act)
  "Speak the line.
 Produce an auditory icon if possible."
  (when (interactive-p) 
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-gnus-summary-speak-subject )))

(defadvice gnus-summary-up-thread (after emacspeak pre act)
  "Speak the line.
 Produce an auditory icon if possible."
  (when (interactive-p) 
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-gnus-summary-speak-subject )))

(defadvice gnus-summary-down-thread (after emacspeak pre act)
  "Speak the line. 
Produce an auditory icon if possible."
  (when (interactive-p) 
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-gnus-summary-speak-subject )))

(defadvice gnus-summary-kill-thread (after emacspeak pre act)
  "Speak the line.
 Produce an auditory icon if possible."
  (when (interactive-p) 
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-gnus-summary-speak-subject )))

;;}}}
;;{{{  Draft specific commands

(defadvice gnus-draft-edit-message (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'open-object)))

(defadvice gnus-draft-send-message (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'task-done)))

(defadvice gnus-draft-send-all-messages (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'task-done)))

(defadvice gnus-draft-toggle-sending (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon
     (if (= (char-after (line-beginning-position)) ?\ )
	 'deselect-object
       'mark-object))))

;;}}}
;;{{{  Article reading

(defun emacspeak-gnus-summary-catchup-quietly-and-exit ()
  "Catch up on all articles in current group."
  (interactive)
  (gnus-summary-catchup-and-exit t t)
  (emacspeak-auditory-icon 'close-object))
;;; helper function:

(defvar emacspeak-gnus-large-article 30 
  "*Articles having more than
emacspeak-gnus-large-article lines will be considered to be a large article.
A large article is not spoken all at once;
instead you hear only the first screenful.")

(defadvice gnus-article-describe-key-briefly (around emacspeak pre act comp)
  "Speak what you displayed"
  (cond
   ((interactive-p)
    (let ((emacspeak-advice-advice-princ t))
      ad-do-it))
   (t ad-do-it)))

(defadvice gnus-article-edit-exit (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (emacspeak-speak-line)))

(defadvice gnus-article-edit-done (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (emacspeak-speak-line)))

(defadvice gnus-article-mail (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-line)))

(defadvice gnus-summary-save-article (after emacspeak pre act comp)
  "Produce an auditory icon if possible"
  (when (interactive-p)
    (emacspeak-auditory-icon 'save-object)))

(defadvice mm-save-part (after emacspeak pre act comp)
  "Produce an auditory icon if possible"
  (emacspeak-auditory-icon 'save-object))

(defadvice gnus-summary-display-article (after emacspeak pre act comp)
  "Produce an auditory icon if possible"
  (emacspeak-auditory-icon 'open-object))

(defadvice gnus-summary-toggle-header (after emacspeak pre act comp)
  "Produce an auditory icon if possible"
  (when (interactive-p)
    (save-excursion
      (set-buffer  "*Article*")
      (emacspeak-auditory-icon
       (if (gnus-article-hidden-text-p 'headers) 'off 'on)))))

(defadvice gnus-summary-show-article (after emacspeak pre act)
  "Start speaking the article. "
  (when (interactive-p)
    (emacspeak-gnus-speak-article-body)))

(defadvice gnus-summary-next-page (after emacspeak pre act)
  "Speak the next pageful "
  (dtk-stop)
  (emacspeak-auditory-icon 'scroll)
  (save-excursion
    (set-buffer  "*Article*")
    (let ((start  (point ))
          (window (get-buffer-window (current-buffer ))))
      (forward-line (window-height window))
      (emacspeak-speak-region start (point )))))

(defadvice gnus-summary-prev-page (after emacspeak pre act)
  "Speak the previous  pageful "
  (dtk-stop)
  (emacspeak-auditory-icon 'scroll)
  (save-excursion
    (set-buffer  "*Article*")
    (let ((start  (point ))
          (window (get-buffer-window (current-buffer ))))
      (forward-line (-  (window-height window)))
      (emacspeak-speak-region start (point )))))

(defadvice gnus-summary-beginning-of-article (after emacspeak pre act)
  "Speak the first line. "(save-excursion
                            (set-buffer "*Article*")
                            (emacspeak-speak-line )))

(defadvice gnus-summary-end-of-article (after emacspeak pre act)
  "Speak the first line. "
  (save-excursion
    (set-buffer "*Article*")
    (emacspeak-speak-line )))

(defadvice gnus-summary-next-unread-article (around emacspeak pre act)
  "Speak the article. "
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (if (= saved-point (point))
          (dtk-speak "No more articles ")
	(emacspeak-gnus-speak-article-body)))
    ad-return-value ))

(defadvice gnus-summary-prev-unread-article (around emacspeak pre act)
  "Speak the article. "
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (if (= saved-point (point))
          (dtk-speak "No more articles ")
	(emacspeak-gnus-speak-article-body)))
    ad-return-value ))

(defadvice gnus-summary-next-article (around emacspeak pre act)
  "Speak the article. "
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (if (= saved-point (point))
          (dtk-speak "No more articles ")
	(emacspeak-gnus-speak-article-body)))
    ad-return-value ))

(defadvice gnus-summary-prev-same-subject  (around emacspeak pre act)
  "Speak the article. "
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (if (= saved-point (point))
          (dtk-speak "No more articles ")
	(emacspeak-gnus-speak-article-body)))
    ad-return-value ))

(defadvice gnus-summary-next-same-subject  (around emacspeak pre act)
  "Speak the article. "
  (let ((saved-point (point )))
    ad-do-it
    (when (interactive-p)
      (if (= saved-point (point))
          (dtk-speak "No more articles ")
	(emacspeak-gnus-speak-article-body)))
    ad-return-value ))

(defadvice gnus-summary-first-unread-article (after emacspeak pre act)
  "Speak the article. "
  (when (interactive-p)
    (emacspeak-gnus-speak-article-body)))

(defadvice gnus-summary-goto-last-article (after emacspeak pre act)
  "Speak the article. "
  (when (interactive-p)
    (emacspeak-gnus-speak-article-body )))

(defadvice gnus-article-show-summary  (after emacspeak pre act)
  "Speak the modeline.
Indicate change of selection with
  an auditory icon if possible."
  (when (interactive-p )
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-mode-line)))

(defadvice gnus-article-next-page (after emacspeak pre act )
  "Speak the current window full of news"
  (when (interactive-p)
    (emacspeak-speak-current-window )))

(defadvice gnus-article-prev-page (after emacspeak pre act )
  "Speak the current window full"
  (when    (interactive-p)
    (emacspeak-speak-current-window)))

(defadvice gnus-article-next-button (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (let ((end (next-single-property-change
                (point) 'gnus-callback)))
      (emacspeak-auditory-icon 'large-movement)
      (message (buffer-substring
                (point)end )))))

(defadvice gnus-article-press-button (before emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'button)))

(defadvice gnus-article-goto-prev-page (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (interactive-p)
    (emacspeak-auditory-icon 'scroll)
    (sit-for 1)
    (emacspeak-speak-current-window)))

(defadvice gnus-article-goto-next-page (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (interactive-p)
    (emacspeak-auditory-icon 'scroll)
    (sit-for 1)
    (emacspeak-speak-current-window)))

(defadvice gnus-article-mode (after emacspeak pre act comp)
  "Turn on voice lock mode."
  (declare (special voice-lock-mode))
  (emacspeak-pronounce-refresh-pronunciations)
  (setq voice-lock-mode t))

(declaim (special emacspeak-pronounce-internet-smileys-pronunciations))
(emacspeak-pronounce-augment-pronunciations 'gnus-article-mode
					    emacspeak-pronounce-internet-smileys-pronunciations)

;;}}}

;;{{{ rdc: refreshing the pronunciation 

(add-hook 'gnus-article-mode-hook
          (function (lambda ()
                      (emacspeak-pronounce-refresh-pronunciations))))

(add-hook 'gnus-group-mode-hook
          (function (lambda ()
                      (emacspeak-pronounce-refresh-pronunciations))))

;; the following is for summary mode.  By default, the 
;; summary mode hook is defined as gnus-agent-mode

(add-hook 'gnus-agent-mode-hook
          (function (lambda ()
                      (emacspeak-pronounce-refresh-pronunciations))))

(add-hook 'message-mode-hook
          (function (lambda ()
                      (emacspeak-pronounce-refresh-pronunciations))))

(add-hook 'gnus-article-edit-mode-hook
          (function (lambda ()
                      (emacspeak-pronounce-refresh-pronunciations))))

(add-hook 'gnus-category-mode-hook
          (function (lambda ()
                      (emacspeak-pronounce-refresh-pronunciations))))

(add-hook 'gnus-score-mode-hook
          (function (lambda ()
                      (emacspeak-pronounce-refresh-pronunciations))))

(add-hook 'gnus-server-mode-hook
          (function (lambda ()
                      (emacspeak-pronounce-refresh-pronunciations))))

;;}}}
;;{{{ rdc: mapping font faces to personalities 

;; article buffer personalities

;; Since citation does not normally go beyond 4 levels deep, in my 
;; experience, there are separate voices for the first four levels
;; and then they are repeated

(def-voice-font emacspeak-gnus-cite-1-personality
  voice-bolden
  'gnus-cite-face-1
  "level 1 citation personality.")

(def-voice-font emacspeak-gnus-cite-2-personality
  voice-lighten
  'gnus-cite-face-2
  "level 2 citation personality.")

(def-voice-font emacspeak-gnus-cite-3-personality
  voice-lighten-extra
  'gnus-cite-face-3
  "level 3 citation personality.")

(def-voice-font emacspeak-gnus-cite-4-personality
  voice-bolden-medium
  'gnus-cite-face-4
  "level 4 citation personality.")

(def-voice-font emacspeak-gnus-cite-5-personality
  voice-bolden
  'gnus-cite-face-5
  "level 5 citation personality.")

(def-voice-font emacspeak-gnus-cite-6-personality
  voice-lighten
  'gnus-cite-face-6
  "level 6 citation personality.")

(def-voice-font emacspeak-gnus-cite-7-personality
  voice-lighten-extra
  'gnus-cite-face-7
  "level 7 citation personality.")

(def-voice-font emacspeak-gnus-cite-8-personality
  voice-bolden-medium
  'gnus-cite-face-8
  "level 8 citation personality.")

(def-voice-font emacspeak-gnus-cite-9-personality
  voice-bolden
  'gnus-cite-face-9
  "level 9 citation personality.")

(def-voice-font emacspeak-gnus-cite-10-personality
  voice-lighten
  'gnus-cite-face-10
  "level 10 citation personality.")

;; since this ends up getting changed when the text becomes cited,
;; it is here only for completeness

;; (def-voice-font emacspeak-gnus-cite-attribution-personality
;;   voice-bolden
;;   'gnus-cite-attribution-face
;;  " Attribution line personality")

(def-voice-font emacspeak-gnus-emphasis-bold-personality
  voice-bolden-and-animate
  'gnus-emphasis-bold
  "Personality used for speaking *bold* words.")

(def-voice-font emacspeak-gnus-emphasis-italic-personality
  voice-lighten
  'gnus-emphasis-italic
  "Personality used for /italicized/ words.")

(def-voice-font emacspeak-gnus-emphasis-underline-personality
  voice-brighten-extra
  'gnus-emphasis-underline
  "Personality used for _underlined_ text.")

(def-voice-font emacspeak-gnus-signature-personality
  voice-animate
  'gnus-signature-face
  "Personality used to highlight signatures.")

(def-voice-font emacspeak-gnus-header-content-personality
  voice-bolden
  'gnus-header-content-face
  "Personality used for header content.")

(def-voice-font emacspeak-gnus-header-name-personality
  voice-animate
  'gnus-header-name-face
  " Personality used for displaying header names.")

(def-voice-font emacspeak-gnus-header-from-personality
  voice-bolden
  'gnus-header-from-face
  " Personality used for displaying from headers.")

(def-voice-font emacspeak-gnus-header-newsgroups-personality
  voice-bolden
  'gnus-header-newsgroups-face
  "Personality used for displaying newsgroups headers. ")

(def-voice-font emacspeak-gnus-header-subject-personality
  voice-bolden
  'gnus-header-subject-face
  "Personality used for displaying subject headers. ")

;; ;; summary buffer personalities

;; since there are so many distinctions, most variations
;; on the same thing are given the same voice.  Any user that
;; uses low and high interest is sufficiently advanced to change
;; the voice to his own preferences

(def-voice-font emacspeak-gnus-summary-normal-read-personality
  voice-bolden
  'gnus-summary-normal-read-face
  "Personality used for read messages in the summary buffer.")

(def-voice-font emacspeak-gnus-summary-high-read-personality
  voice-bolden
  'gnus-summary-high-read-face
  "Personality used for high interest read articles.")

(def-voice-font emacspeak-gnus-summary-low-read-personality
  voice-bolden
  'gnus-summary-low-read-face
  "Personality used for low interest read articles.")

(def-voice-font emacspeak-gnus-summary-normal-ticked-personality
  voice-brighten
  'gnus-summary-normal-ticked-face
  "Personality used for ticked articles in the summary buffer.")

(def-voice-font emacspeak-gnus-summary-high-ticked-personality
  voice-brighten
  'gnus-summary-high-ticked-face
  "Personality used for high interest ticked articles.")

(def-voice-font emacspeak-gnus-summary-low-ticked-personality
  voice-brighten
  'gnus-summary-low-ticked-face
  "Personality used for low interest ticked articles.")

(def-voice-font emacspeak-gnus-summary-normal-ancient-personality
  voice-smoothen-extra
  'gnus-summary-normal-ancient-face
  "Personality used for normal interest ancient articles.")

(def-voice-font emacspeak-gnus-summary-high-ancient-personality
  voice-smoothen-extra
  'gnus-summary-high-ancient-face
  "Personality used for high interest ancient articles.")

(def-voice-font emacspeak-gnus-summary-low-ancient-personality
  voice-smoothen-extra
  'gnus-summary-low-ancient-face
  "Personality used for low interest ancient articles.")

;; I believe the undownloaded articles should appear as normal text

;; (def-voice-font emacspeak-gnus-summary-normal-undownloaded-personality
;;   voice-bolden
;;   'gnus-summary-normal-undownloaded-face
;;   "Personality used for normal interest uncached articles.")

;; (def-voice-font emacspeak-gnus-summary-high-undownloaded-personality
;;   voice-bolden-and-animate
;;   'gnus-summary-high-undownloaded-face
;;   "Personality used for high interest uncached articles.")

;; (def-voice-font emacspeak-gnus-summary-low-undownloaded-personality
;;   voice-bolden
;;   'gnus-summary-low-undownloaded-face
;;   "Personality used for low interest uncached articles.")

;; same with the below

;; (def-voice-font emacspeak-gnus-summary-low-unread-personality
;;   voice-bolden-extra
;;   'gnus-summary-low-unread-face
;;   "Personality used for low interest unread articles.")

;; (def-voice-font emacspeak-gnus-summary-high-unread-personality
;;   voice-bolden
;;   'gnus-summary-high-unread-face
;;   "Personality used for high interest unread articles.")

(def-voice-font emacspeak-gnus-summary-selected-personality
  voice-animate-extra
  'gnus-summary-selected-face
  "Personality used for selected articles in the summary buffer.")

(def-voice-font emacspeak-gnus-summary-cancelled-personality
  voice-bolden-extra
  'gnus-summary-cancelled-face
  "Personality used for cancelled articles.")

;; group buffer personalities

;; I think the voice used for the groups in the buffer should be the 
;; default voice.  I might ask if there is a call for different voices 
;; as they are only necessary if users have persistently visible groups
;; in the case of empty groups, and voices for the various levels.

;; (def-voice-font emacspeak-gnus-group-mail-1-empty-personality
;;   voice-smoothen-extra
;;   'gnus-group-mail-1-empty-face
;;   "Level 1 empty mailgroup personality ")

;; (def-voice-font emacspeak-gnus-group-mail-1-personality
;;   voice-bolden-extra
;;   'gnus-group-mail-1-face
;;   "Level 1 mailgroup personality ")

;; (def-voice-font emacspeak-gnus-group-mail-2-empty-personality
;;   voice-smoothen-extra
;;   'gnus-group-mail-2-empty-face
;;   "Level 2 empty mailgroup personality ")

;; (def-voice-font emacspeak-gnus-group-mail-2-personality
;;   voice-bolden
;;   'gnus-group-mail-2-face
;;   "Level 2 mailgroup personality ")

;; (def-voice-font emacspeak-gnus-group-mail-3-empty-personality
;;   voice-bolden
;;   'gnus-group-mail-3-empty-face
;;   "Level 3 empty mailgroup personality ")

;; (def-voice-font emacspeak-gnus-group-mail-3-personality
;;   voice-bolden
;;   'gnus-group-mail-3-face
;;   "Level 3 mailgroup personality ")

;; (def-voice-font emacspeak-gnus-group-mail-low-empty-personality
;;   voice-bolden
;;   'gnus-group-mail-low-empty-face
;;   "Low level empty mailgroup personality ")

;; (def-voice-font emacspeak-gnus-group-mail-low-personality
;;   voice-bolden
;;   'gnus-group-mail-low-face
;;   "Low level mailgroup personality ")

;; (def-voice-font emacspeak-gnus-group-news-1-empty-personality
;;   voice-bolden
;;   'gnus-group-news-1-empty-face
;;   "Level 1 empty newsgroup personality ")

;; (def-voice-font emacspeak-gnus-group-news-1-personality
;;   voice-bolden
;;   'gnus-group-news-1-face
;;   "Level 1 newsgroup personality ")

;; (def-voice-font emacspeak-gnus-group-news-2-empty-personality
;;   voice-bolden
;;   'gnus-group-news-2-empty-face
;;   "Level 2 empty newsgroup personality ")

;; (def-voice-font emacspeak-gnus-group-news-2-personality
;;   voice-bolden-extra
;;   'gnus-group-news-2-face
;;   "Level 2 newsgroup personality ")

;; (def-voice-font emacspeak-gnus-group-news-3-empty-personality
;;   voice-bolden
;;   'gnus-group-news-3-empty-face
;;   "Level 3 empty newsgroup personality ")

;; (def-voice-font emacspeak-gnus-group-news-3-personality
;;   voice-bolden
;;   'gnus-group-news-3-face
;;   "Level 3 newsgroup personality ")

;; (def-voice-font emacspeak-gnus-group-news-4-empty-personality
;;   voice-bolden
;;   'gnus-group-news-4-empty-face
;;   "Level 4 empty newsgroup personality ")

;; (def-voice-font emacspeak-gnus-group-news-4-face
;;   voice-bolden
;;   'gnus-group-news-4-face
;;   "Level 4 newsgroup personality ")

;; (def-voice-font emacspeak-gnus-group-news-5-empty-personality
;;   voice-bolden
;;   ' gnus-group-news-5-empty-face
;;   "Level 5 empty newsgroup personality ")

;; (def-voice-font emacspeak-gnus-group-news-5-personality
;;   voice-bolden
;;   'gnus-group-news-5-face
;;   "Level 5 newsgroup personality ")

;; (def-voice-font emacspeak-gnus-group-news-6-empty-personality
;;   voice-bolden
;;   'gnus-group-news-6-empty-face
;;   "Level 6 empty newsgroup personality ")

;; (def-voice-font emacspeak-gnus-group-news-6-personality
;;   voice-bolden-extra
;;   'gnus-group-news-6-face
;;   "Level 6 newsgroup personality ")

;; (def-voice-font emacspeak-gnus-group-news-low-empty-personality
;;   voice-bolden-extra
;;   'gnus-group-news-low-empty-face
;;   "Low level empty newsgroup personality ")

;; (def-voice-font emacspeak-gnus-group-news-low-personality
;;   voice-bolden-extra
;;   'gnus-group-news-low-face
;;   "Low level newsgroup personality ")

;; server buffer personalities

(def-voice-font emacspeak-gnus-server-agent-personality
  voice-bolden
  'gnus-server-agent-face
  "Personality used for displaying AGENTIZED servers")

(def-voice-font emacspeak-gnus-server-closed-personality
  voice-bolden-medium
  'gnus-server-closed-face
  "Personality used for displaying CLOSED servers")

(def-voice-font emacspeak-gnus-server-denied-personality
  voice-bolden-extra
  'gnus-server-denied-face
  "Personality used for displaying DENIED servers")

(def-voice-font emacspeak-gnus-server-offline-personality
  voice-animate
  'gnus-server-offline-face
  "Personality used for displaying OFFLINE servers")

(def-voice-font emacspeak-gnus-server-opened-personality
  voice-lighten
  'gnus-server-opened-face
  "Personality used for displaying OPENED servers")

;;}}}

(provide 'emacspeak-gnus)
;;{{{  end of file 

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end: 

;;}}}
