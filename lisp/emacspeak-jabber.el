;;; emacspeak-jabber.el --- Speech-Enable jabber
;;; $Id: emacspeak-jabber.el 5222 2007-08-26 01:28:19Z tv.raman.tv $
;;; $Author: tv.raman.tv $
;;; Description: speech-enable jabber
;;; Keywords: Emacspeak, jabber
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

;;; Copyright (c) 1995 -- 2007, T. V. Raman
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
  (when (interactive-p)
    (emacspeak-auditory-icon 'on)))

(defadvice jabber-disconnect (after emacspeak pre act comp)
  "Provide auditory icon if possible."
  (when (interactive-p)
    (emacspeak-auditory-icon 'off)))

(defadvice jabber-customize (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (interactive-p)
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
	  (declare (special voice-lock-mode))
	  (emacspeak-pronounce-refresh-pronunciations)
	  (setq voice-lock-mode t))))

;;}}}
;;{{{ silence keepalive

(loop for f in
      '(jabber-keepalive-do
        jabber-keepalive-got-response)
      do
      (eval
       `(defadvice ,f (around emacspeak pre act comp)
          "Silence keepalive messages."
          (let ((emacspeak-speak-messages nil))
            ad-do-it
            ad-return-value))))

;;}}}
;;{{{  silence image type errors

(defadvice image-type (around emacspeak pre act comp)
  (let ((emacspeak-speak-messages nil)
        (emacspeak-use-auditory-icons nil))
    ad-do-it))

;;}}}
;;{{{ jabber activity:

(defadvice jabber-activity-switch-to (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-mode-line)))

;;}}}
;;{{{ chat buffer:

(defadvice jabber-chat-buffer-send (after emacspeak pre act comp)
  "Produce auditory icon."
  (when (interactive-p)
    (emacspeak-auditory-icon 'close-object)))
(loop for f in
      '(jabber-chat-with
        jabber-chat-with-jid-at-point)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Silence keepalive messages."
          (when (interactive-p)
            (emacspeak-auditory-icon 'open-object)
            (emacspeak-speak-mode-line)))))

;;}}}
;;{{{ roster buffer:

(defadvice jabber-go-to-next-jid (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (interactive-p)
    (emacspeak-auditory-icon 'large-movement)
    (dtk-speak (buffer-substring
                (previous-single-property-change
                 (1+ (point)) 'jabber-jid)
                (next-single-property-change
                 (point) 'jabber-jid)))))

;;}}}
;;{{{ alerts

(defcustom emacspeak-jabber-speak-presence-alerts nil
  "Set to T if you want to hear presence alerts."
  :type  'boolean
  :group 'emacspeak-jabber)

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
(defun emacspeak-jabber-message-default-message (from buffer
                                                      text)
  "Speak the message."
  (declare (special jabber-message-alert-same-buffer))
  (when (or jabber-message-alert-same-buffer
            (not (memq (selected-window) (get-buffer-window-list buffer))))
    (if (jabber-muc-sender-p from)
        (format "Private message from %s in %s"
                (jabber-jid-resource from)
                (jabber-jid-displayname (jabber-jid-user from)))
      (format "%s: %s" (jabber-jid-displayname from) text))))

;;{{{ interactive commands:

(defun emacspeak-jabber-popup-roster ()
  "Pop to Jabber roster."
  (interactive)
  (declare (special jabber-roster-buffer
                    *jabber-connected*))
  (unless (buffer-live-p jabber-roster-buffer)
    (jabber-display-roster))
  (unless *jabber-connected*
    (call-interactively 'jabber-connect))
  (pop-to-buffer jabber-roster-buffer)
  (goto-char (point-min))
  (emacspeak-auditory-icon 'select-object)
  (emacspeak-speak-mode-line))

;;}}}

;;}}}
;;{{{ Pronunciations
(declaim (special emacspeak-pronounce-internet-smileys-pronunciations))
(emacspeak-pronounce-augment-pronunciations 'jabber-chat-mode
                                            emacspeak-pronounce-internet-smileys-pronunciations)
(emacspeak-pronounce-augment-pronunciations 'jabber-mode
                                            emacspeak-pronounce-internet-smileys-pronunciations)

;;}}}
(provide 'emacspeak-jabber)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
