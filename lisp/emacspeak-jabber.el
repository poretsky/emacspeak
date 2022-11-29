;;; emacspeak-jabber.el --- Speech-Enable jabber  -*- lexical-binding: t; -*-
;;; $Id$
;;; $Author: tv.raman.tv $
;;; Description: speech-enable jabber
;;; Keywords: Emacspeak, jabber
;;{{{  LCD Archive entry:

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu
;;; A speech interface to Emacs |
;;; $Date: 2008-04-15 06:25:36 -0700 (Tue, 15 Apr 2008) $ |
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

;;{{{ Introduction:

;;; Commentary:
;;; emacs-jabber.el implements a  jabber client for emacs
;;; emacs-jabber is hosted at sourceforge.
;;; I use emacs-jabber with my gmail.com account

;;; Code:

;;}}}
;;{{{  Required modules

(cl-declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)
(require 'jabber () 'no-error)

;;}}}
;;{{{ Forward declarations

(declare-function jabber-muc-sender-p "ext:jabber-muc.el" (jid))
(declare-function jabber-jid-resource "ext:jabber-util.el" (string))
(declare-function jabber-jid-displayname "ext:jabber-util.el" (string))
(declare-function jabber-jid-user "ext:jabber-util.el" (string))
(declare-function jabber-activity-switch-to "ext:jabber-activity.el" (&optional jid-param))

;;}}}
;;{{{ map voices

(voice-setup-add-map
 '(
   (jabber-activity-face        voice-animate)
   (jabber-chat-error           voice-bolden-and-animate)
   (jabber-chat-prompt-foreign  voice-brighten-medium)
   (jabber-chat-prompt-local    voice-smoothen-medium)
   (jabber-chat-prompt-system   voice-brighten-extra)
   ;;;(jabber-chat-text-foreign    voice-lighten) we use default here 
   (jabber-chat-text-local      voice-smoothen)
   (jabber-rare-time-face       voice-animate-extra)
   (jabber-roster-user-away     voice-smoothen-extra)
   (jabber-roster-user-chatty   voice-brighten)
   (jabber-roster-user-dnd      voice-lighten-medium)
   (jabber-roster-user-error    voice-bolden-and-animate)
   (jabber-roster-user-offline  voice-smoothen-extra)
   (jabber-roster-user-online   voice-bolden)
   (jabber-roster-user-xa       voice-lighten)
   (jabber-title-large          voice-bolden-extra)
   (jabber-title-medium         voice-bolden)
   (jabber-title-small          voice-lighten)
   ))
;;}}}
;;{{{ Advice interactive commands:

(defadvice jabber-connect (after emacspeak pre act comp)
  "Provide auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'on)))

(defadvice jabber-disconnect (after emacspeak pre act comp)
  "Provide auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'off)))

(defadvice jabber-customize (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-line)))

(cl-loop for f in
      '(jabber-roster-mode
	jabber-chat-mode
	jabber-browse-mode)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
	  "Turn on voice lock mode."
	  (emacspeak-pronounce-refresh-pronunciations)
	  (voice-lock-mode (if global-voice-lock-mode 1 -1)))))

;;}}}
;;{{{ silence keepalive

(cl-loop
 for f in
 '(
   image-type jabber-keepalive-got-response
   jabber-keepalive-do jabber-fsm-handle-sentinel jabber-xml-resolve-namespace-prefixes)
 do
 (eval
  `(defadvice ,f (around emacspeak pre act comp)
     "Silence  messages."
     (ems-with-messages-silenced
      ad-do-it
      ad-return-value))))

(defadvice jabber-process-roster (around emacspeak pre act comp)
  "Silence  messages, but provide auditory feedback."
  (ems-with-messages-silenced
      ad-do-it
    (when (eq (ad-get-arg 2) 'initial)
      (emacspeak-auditory-icon 'on))
    ad-return-value))

;;}}}
;;{{{ jabber activity:

(defadvice jabber-activity-switch-to (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-mode-line)))

;;}}}
;;{{{ chat buffer:

(defadvice jabber-chat-buffer-send (after emacspeak pre act comp)
  "Produce auditory icon."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'close-object)))

;;}}}
;;{{{ roster buffer:

(cl-loop for f in
      '(jabber-roster-ret-action-at-point
        jabber-chat-with
        jabber-chat-with-jid-at-point
        jabber-switch-to-roster-buffer
        jabber-vcard-edit)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Provide auditory feedback."
          (when (ems-interactive-p)
            (emacspeak-auditory-icon 'open-object)
            (emacspeak-speak-mode-line)))))

(cl-loop for f in
      '(jabber-go-to-next-jid
        jabber-go-to-previous-jid)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Provide auditory feedback."
          (when (ems-interactive-p)
            (emacspeak-auditory-icon 'large-movement)
            (emacspeak-speak-text-range 'jabber-jid)))))

(cl-loop for f in
      '(jabber-roster-delete-jid-at-point
        jabber-roster-delete-at-point)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Provide auditory icon if possible."
          (when (ems-interactive-p)
            (emacspeak-auditory-icon 'delete-object)))))

(defadvice jabber-roster-toggle-binding-display (after emacspeak pre act comp)
  "Provide auditory icon if possible."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon (if jabber-roster-show-bindings 'on 'off))))

;;}}}
;;{{{ alerts

(defcustom emacspeak-jabber-speak-presence-alerts nil
  "Set to T if you want to hear presence alerts."
  :type  'boolean
  :group 'emacspeak-jabber)
(defadvice jabber-send-default-presence (after emacspeak pre act
                                               comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (message "Sent default presence.")))

(defadvice jabber-send-away-presence (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (message "Set to be away.")))

(defadvice jabber-send-xa-presence (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (message "Set extended  away.")))

(defadvice jabber-presence-default-message (around emacspeak pre
                                                   act comp)
  "Allow emacspeak to control if the message is spoken."
  (cond
   (emacspeak-jabber-speak-presence-alerts
    (let ((emacspeak-speak-messages t))
      ad-do-it))
   (t
    (ems-with-messages-silenced
     ad-do-it)))
  ad-return-value)

(defun emacspeak-jabber-presence-default-message (&rest _ignore)
  "Default presence alert used by Emacspeak.
Silently drops alerts on the floor --- Google Talk is too chatty otherwise."
  nil)

(when (boundp 'jabber-alert-presence-message-function)
  (setq
   jabber-alert-presence-message-function
   #'emacspeak-jabber-presence-default-message))

;;;this is what I use as my jabber alert function:
(defun emacspeak-jabber-message-default-message (from buffer text)
  "Speak the message."
  (cl-declare (special jabber-message-alert-same-buffer))
  (when (or jabber-message-alert-same-buffer
            (not (memq (selected-window) (get-buffer-window-list buffer))))
    (emacspeak-auditory-icon 'item)
    (dtk-notify-speak
     (if (jabber-muc-sender-p from)
         (format "Private message from %s in %s"
                 (jabber-jid-resource from)
                 (jabber-jid-displayname (jabber-jid-user from)))
       (format "%s: %s" (jabber-jid-displayname from) text)))))

;;}}}
;;{{{ interactive commands:

(defun emacspeak-jabber-popup-roster ()
  "Pop to Jabber roster."
  (interactive)
  (cl-declare (special jabber-roster-buffer jabber-roster-show-bindings jabber-connections))
  (unless jabber-connections  (call-interactively 'jabber-connect))
  (unless (buffer-live-p jabber-roster-buffer) (call-interactively 'jabber-display-roster))
  (pop-to-buffer jabber-roster-buffer)
  (goto-char (point-min))
  (forward-line (if jabber-roster-show-bindings 15 4))
  (emacspeak-auditory-icon 'select-object)
  (emacspeak-speak-line))

;;}}}
;;{{{ Pronunciations
(cl-declaim (special emacspeak-pronounce-internet-smileys-pronunciations))
(emacspeak-pronounce-augment-pronunciations 'jabber-chat-mode
                                            emacspeak-pronounce-internet-smileys-pronunciations)
(emacspeak-pronounce-augment-pronunciations 'jabber-mode
                                            emacspeak-pronounce-internet-smileys-pronunciations)

;;}}}
;;{{{ Browse chat buffers:
(defun emacspeak-jabber-chat-speak-this-message(&optional copy-as-kill)
  "Speak chat message under point.
With optional interactive prefix arg `copy-as-kill', copy it to
the kill ring as well."
  (interactive "P")
  (let ((range (emacspeak-speak-get-text-range 'face)))
    (when copy-as-kill (kill-new range))
    (dtk-speak range)))

(defun emacspeak-jabber-chat-next-message ()
  "Move forward to and speak the next message in this chat session."
  (interactive)
  (cl-assert  (eq major-mode 'jabber-chat-mode) nil  "Not in a Jabber chat buffer.")
  (end-of-line)
  (goto-char (next-single-property-change (point) 'face nil(point-max)))
  (while (and (not (eobp))
              (or (null (get-text-property (point) 'face))
                  (get-text-property (point) 'field)))
    (goto-char (next-single-property-change (point) 'face  nil  (point-max))))
  (cond
   ((eobp)
    (message "On last message")
    (emacspeak-auditory-icon 'warn-user))
   (t(emacspeak-auditory-icon 'select-object)
     (emacspeak-speak-text-range 'face))))

(defun emacspeak-jabber-chat-previous-message ()
  "Move backward to and speak the previous message in this chat session."
  (interactive)
  (cl-assert (eq major-mode 'jabber-chat-mode) nil "Not in a Jabber chat buffer.")
  (beginning-of-line)
  (goto-char (previous-single-property-change (point) 'face nil  (point-min)))
  (while  (and (not (bobp))
               (or (null (get-text-property (point) 'face))
                   (get-text-property (point) 'field)))
    (goto-char (previous-single-property-change (point) 'face  nil  (point-min))))
  (cond
   ((bobp)
    (message "On first message")
    (emacspeak-auditory-icon 'warn-user))
   (t(emacspeak-auditory-icon 'select-object)
     (emacspeak-speak-text-range 'face))))

(when (boundp 'jabber-chat-mode-map)
  (cl-loop
   for k in
   '(
     ("M-n" emacspeak-jabber-chat-next-message)
     ("M-p" emacspeak-jabber-chat-previous-message)
     ("M-SPC " emacspeak-jabber-chat-speak-this-message))
   do
   (emacspeak-keymap-update  jabber-chat-mode-map k)))

;;}}}
;;{{{ Speak recent message:
;;;###autoload
(defun emacspeak-jabber-speak-recent-message ()
  "Speak most recent message if one exists."
  (interactive)
  (cl-declare (special jabber-activity-jids))
  (cond
   (jabber-activity-jids
    (save-mark-and-excursion
      (jabber-activity-switch-to)
      (goto-char (point-max))
      (emacspeak-jabber-chat-previous-message)))
   (t (message "No recent message."))))

;;}}}
(provide 'emacspeak-jabber)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
