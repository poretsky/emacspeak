;;; emacspeak-jabber.el --- Speech-Enable jabber
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

;;; Copyright (c) 1995 -- 2015, T. V. Raman
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

(require 'emacspeak-preamble)
(require 'jabber "jabber" 'no-error)

;;}}}
;;{{{ Forward declarations

(declare-function jabber-muc-sender-p "ext:jabber-muc.el" (jid))
(declare-function jabber-jid-resource "ext:jabber-util.el" (string))
(declare-function jabber-jid-displayname "ext:jabber-util.el" (string))
(declare-function jabber-jid-user "ext:jabber-util.el" (string))
(declare-function jabber-display-roster "ext:jabber-roster.el" ())

;;}}}
;;{{{ map voices

(voice-setup-add-map
 '(
   (jabber-activity-face        voice-animate)
   (jabber-chat-error           voice-bolden-and-animate)
   (jabber-chat-prompt-foreign  voice-animate-medium)
   (jabber-chat-prompt-local    voice-bolden-medium)
   (jabber-chat-prompt-system   voice-brighten-extra)
   (jabber-chat-text-foreign    voice-animate)
   (jabber-chat-text-local      voice-smoothen)
   (jabber-rare-time-face       voice-animate-extra)
   (jabber-roster-user-away     voice-smoothen-extra)
   (jabber-roster-user-chatty   voice-brighten)
   (jabber-roster-user-dnd      voice-lighten-medium)
   (jabber-roster-user-error    voice-bolden-and-animate)
   (jabber-roster-user-offline  voice-lighten-extra)
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

(loop for f in
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
;;{{{ silence keepalive messages and image type errors

(loop
 for f in
 '(
   image-type jabber-process-roster jabber-keepalive-got-response
   jabber-keepalive-do jabber-fsm-handle-sentinel jabber-xml-resolve-namespace-prefixes
   )
 do
 (eval
  `(defadvice ,f (around emacspeak pre act comp)
     "Silence  messages."
     (ems-with-messages-silenced ad-do-it
                                 ad-return-value))))

;;}}}
;;{{{ jabber activity:

(defadvice jabber-activity-switch-to (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-mode-line)))

;;}}}
;;{{{ chat buffer:

(defadvice jabber-chat-buffer-send (after emacspeak pre act comp)
  "Produce auditory icon."
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'close-object)))

;;}}}
;;{{{ roster buffer:

(loop for f in
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

(loop for f in
      '(jabber-go-to-next-jid
        jabber-go-to-previous-jid)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Provide auditory feedback."
          (when (ems-interactive-p)
            (emacspeak-auditory-icon 'large-movement)
            (emacspeak-speak-text-range 'jabber-jid)))))

(loop for f in
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
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'open-object)
    (message "Sent default presence.")))

(defadvice jabber-send-away-presence (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'close-object)
    (message "Set to be away.")))

(defadvice jabber-send-xa-presence (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'close-object)
    (message "Set extended  away.")))

(defadvice jabber-presence-default-message (around emacspeak pre
                                                   act comp)
  "Allow emacspeak to control if the message is spoken."
  (cond
   (emacspeak-jabber-speak-presence-alerts
    (let ((emacspeak-speak-messages t))
      ad-do-it))
   (t (let ((emacspeak-speak-messages nil))
        ad-do-it)))
  ad-return-value)

;;;this is what I use as my jabber alert function:
(defun emacspeak-jabber-message-default-message (from buffer text)
  "Speak the message."
  (declare (special jabber-message-alert-same-buffer))
  (when (or jabber-message-alert-same-buffer
            (not (memq (selected-window) (get-buffer-window-list buffer))))
    (emacspeak-auditory-icon 'progress)
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
  (declare (special jabber-roster-buffer jabber-roster-show-bindings *jabber-connected*))
  (unless *jabber-connected* (call-interactively 'jabber-connect))
  (unless (buffer-live-p jabber-roster-buffer) (call-interactively 'jabber-display-roster))
  (pop-to-buffer jabber-roster-buffer)
  (goto-char (point-min))
  (forward-line (if jabber-roster-show-bindings 15 4))
  (emacspeak-auditory-icon 'select-object)
  (emacspeak-speak-line))
(defadvice jabber-connect-all (after emacspeak pre act comp)
  "switch to roster so we give it a chance to update."
  (when (ems-interactive-p)
    (switch-to-buffer jabber-roster-buffer)))
(defadvice jabber-roster-update (around emacspeak    pre act  comp)
  "Make this operation a No-Op unless the roster is visible."
  (when (get-buffer-window-list jabber-roster-buffer)
    ad-do-it))

(defadvice jabber-display-roster (around emacspeak    pre act  comp)
  "Make this operation a No-Op unless called interactively."
  (when (ems-interactive-p) ad-do-it))

(add-hook 'jabber-post-connect-hook 'jabber-switch-to-roster-buffer)

;;}}}

;;}}}
;;{{{ Pronunciations

(declaim (special emacspeak-pronounce-internet-smileys-pronunciations))
(emacspeak-pronounce-augment-pronunciations 'jabber-chat-mode
                                            emacspeak-pronounce-internet-smileys-pronunciations)
(emacspeak-pronounce-augment-pronunciations 'jabber-mode
                                            emacspeak-pronounce-internet-smileys-pronunciations)

;;}}}
;;{{{ Browse chat buffers:

;;; Relies on jabber prompt pattern.
;;; Search forward/back for "^[", check prompt face to determine
;;; local/foreign, then speak  text in appropriate face.

(defun emacspeak-jabber-chat-speak-this-message ()
  "Speaks message starting on current line.
Assumes point is at the front of the message.
Returns a cons (start . end) that delimits the message."
  (interactive)
  (unless (eq major-mode 'jabber-chat-mode)
    (error "Not in a Jabber chat buffer."))
  (let ((start nil)
        (end nil))
    (save-excursion
      (when (ems-interactive-p )
        (unless (looking-at "^\\[")
          (re-search-backward "^\\[" nil t)))
      (setq start
            (goto-char
             (next-single-property-change (point) 'face)))
      (setq end
            (goto-char
             (next-single-property-change (point) 'face)))
      (emacspeak-speak-region start end))
    (cons start end)))

(defun emacspeak-jabber-chat-next-message ()
  "Move forward to and speak the next message in this chat
session."
  (interactive)
  (unless (eq major-mode 'jabber-chat-mode)
    (error "Not in a Jabber chat buffer."))
  (re-search-forward "^\\["nil t)
  (let ((extent (emacspeak-jabber-chat-speak-this-message)))
    (emacspeak-auditory-icon 'large-movement)
    (goto-char (cdr extent))))

(defun emacspeak-jabber-chat-previous-message ()
  "Move backward to and speak the previous message in this chat
session."
  (interactive)
  (unless (eq major-mode 'jabber-chat-mode)
    (error "Not in a Jabber chat buffer."))
  (forward-line 0)
  (re-search-backward "^\\["nil t)
  (let ((extent (emacspeak-jabber-chat-speak-this-message)))
    (emacspeak-auditory-icon 'large-movement)
    (goto-char (car extent))))

(when (boundp 'jabber-chat-mode-map)
  (loop for k in
        '(
          ("M-n" emacspeak-jabber-chat-next-message)
          ("M-p" emacspeak-jabber-chat-previous-message)
          ("M-SPC " emacspeak-jabber-chat-speak-this-message))
        do
        (emacspeak-keymap-update  jabber-chat-mode-map k)))

;;}}}
(provide 'emacspeak-jabber)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: nil
;;; end:

;;}}}
