;;; emacspeak-dbus.el --- DBus On Emacspeak Desktop -*- lexical-binding: t; -*-
;;; $Id: emacspeak-dbus.el 4797 2007-07-16 23:31:22Z tv.raman.tv $
;;; $Author: tv.raman.tv $
;;; Description:  DBus Tools For The Emacspeak Desktop
;;; Keywords: Emacspeak,  Audio Desktop dbus
;;{{{  LCD Archive entry:

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu
;;; A speech interface to Emacs |
;;; $Date: 2007-05-03 18:13:44 -0700 (Thu, 03 May 2007) $ |
;;;  $Revision: 4532 $ |
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:
;;;Copyright (C) 1995 -- 2017, T. V. Raman
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
;;; MERCHANTABILITY or FITNDBUS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Emacs; see the file COPYING.  If not, write to
;;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;}}}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;{{{  introduction

;;; Commentary:
;;; Set up Emacspeak to respond to DBus notifications
;;; @subsection Overview
;;;
;;; This module provides integration via DBus  for the following:
;;; @itemize @bullet
;;; @item Respond to network coming up or going down.
;;; @item Respond to screen getting locked/unlocked by gnome-screen-saver
;;; @item Respond to laptop  going to sleep or waking up.
;;; @end itemize
;;; See relevant hooks for customizing behavior.
;;; Note that each of the  sleep/wake-up and network/up-down
;;; can be separately enabled/disabled, and the actions customized
;;; via appropriately named hook functions.
;;;
;;}}}
;;{{{  Required modules

(require 'cl-lib)
(cl-declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)
(eval-when-compile
  (require 'amixer)
(require 'sox-gen)
(require 'derived)
(require 'dbus))
(require 'nm "nm" 'no-error)

;;}}}
;;{{{ Forward Declarations:

(declare-function soundscape-restart "soundscape" (&optional device))
(declare-function jabber-connect-all "jabber-core" (&optional arg))
(declare-function jabber-disconnect "jabber-core" (&optional arg))
(declare-function twittering-start "twittering-mode" nil)
(declare-function twittering-stop "twittering-mode" nil)

;;}}}
;;{{{ ScreenSaver Mode:

(define-derived-mode emacspeak-screen-saver-mode special-mode
  "Screen Saver Mode"
  "A light-weight mode for the `*Emacspeak Screen Saver *' buffer.
This is a hidden buffer that is made current so we automatically
switch to a screen-saver soundscape."
  t)
(defvar emacspeak-screen-saver-saved-configuration  nil
  "Record window configuration when screen-saver was launched.")

(defun emacspeak-screen-saver ()
  "Launch Emacspeak screen-saver."
  (cl-declare (special emacspeak-screen-saver-saved-configuration))
  (setq emacspeak-screen-saver-saved-configuration (current-window-configuration))"Initialize screen-saver buffer  if needed, and switch to  it."
  (let ((buffer (get-buffer-create "*Emacspeak Screen Saver*")))
    (with-current-buffer buffer (emacspeak-screen-saver-mode))
    (funcall-interactively #'switch-to-buffer buffer)
    (delete-other-windows)))

;;}}}
;;{{{ NM Handlers

(defun emacspeak-dbus-nm-connected ()
  "Announce  network manager connection.
Startup  apps that need the network."
  (cl-declare (special emacspeak-speak-network-interfaces-list))
  (setq emacspeak-speak-network-interfaces-list
        (mapcar #'car (network-interface-list)))
  (run-at-time
   30 nil
   #'(lambda ()
       (when (featurep 'jabber) (jabber-connect-all))
       (when (featurep 'twittering-mode) (twittering-start))))
  (emacspeak-play-auditory-icon 'network-up)
  (dtk-notify-speak
   (mapconcat #'identity emacspeak-speak-network-interfaces-list "")))


(defun emacspeak-dbus-nm-disconnected ()
  "Announce  network manager disconnection.
Stop apps that use the network."
  (cl-declare (special emacspeak-speak-network-interfaces-list))
  (when (featurep 'jabber) (jabber-disconnect))
  (when (featurep 'twittering-mode) (twittering-stop))
  (setq emacspeak-speak-network-interfaces-list
        (mapcar #'car (network-interface-list)))
  (emacspeak-auditory-icon 'network-down)
  (message (mapconcat #'identity emacspeak-speak-network-interfaces-list "")))

(add-hook 'nm-connected-hook 'emacspeak-dbus-nm-connected)
(add-hook 'nm-disconnected-hook 'emacspeak-dbus-nm-disconnected)

;;}}}
;;{{{ Sleep/Resume:

(defun emacspeak-dbus-login1-sleep-p ()
  "Test if login1 service  sleep signal is available."
  (member
   "PrepareForSleep"
   (dbus-introspect-get-signal-names
    :system
    "org.freedesktop.login1" "/org/freedesktop/login1"
    "org.freedesktop.login1.Manager")))

(defvar emacspeak-dbus-sleep-hook nil
  "Functions called when machine is about to sleep (suspend or hibernate). ")

(defvar emacspeak-dbus-resume-hook nil
  "Functions called when machine is resumed (from suspend or hibernate).")

(defun emacspeak-dbus-sleep-signal-handler()
  (message "Sleeping")
  (run-hooks 'emacspeak-dbus-sleep-hook))

(defun emacspeak-dbus-resume-signal-handler()
  (message "Waking Up")
  (run-hooks 'emacspeak-dbus-resume-hook))

(defvar emacspeak-dbus-sleep-registration nil
  "List holding sleep registration.")

(defun emacspeak-dbus-sleep-register()
  "Register signal handlers for sleep/resume. Return list of
signal registration objects."
  (cond
   ((emacspeak-dbus-login1-sleep-p)
    (message "Registering sleep/resume handlers.")
    (list
     (dbus-register-signal
      :system "org.freedesktop.login1" "/org/freedesktop/login1"
      "org.freedesktop.login1.Manager" "PrepareForSleep"
      #'(lambda(sleep)
          (if sleep
              (emacspeak-dbus-sleep-signal-handler)
            (emacspeak-dbus-resume-signal-handler))))))
   (t (error "org.freedesktop.login1 has no PrepareForSleep signal."))))

;;; Enable integration
(defun emacspeak-dbus-sleep-enable()
  "Enable integration with Login1. Does nothing if already enabled."
  (interactive)
  (cl-declare (special emacspeak-dbus-sleep-registration))
  (unless emacspeak-dbus-sleep-registration
    (setq emacspeak-dbus-sleep-registration (emacspeak-dbus-sleep-register)))
    (message "Enabled integration with login1 daemon."))

;;; Disable integration
(defun emacspeak-dbus-sleep-disable()
  "Disable integration with login1 daemon. Does nothing if
already disabled."
  (interactive)
  (cl-declare (special emacspeak-dbus-sleep-registration))
  (while emacspeak-dbus-sleep-registration
    (dbus-unregister-object (car emacspeak-dbus-sleep-registration))
    (setq emacspeak-dbus-sleep-registration
          (cdr emacspeak-dbus-sleep-registration)))
  (message "Disabled integration with Login1 daemon."))

(defun emacspeak-dbus-sleep ()
  "Emacspeak  hook for -sleep signal from Login1."
  (save-some-buffers t))

(add-hook  'emacspeak-dbus-sleep-hook#'emacspeak-dbus-sleep)

(defun emacspeak-dbus-resume ()
  "Emacspeak hook for Login1-resume."
  (cl-declare (special amixer-alsactl-config-file))
  (amixer-restore amixer-alsactl-config-file )
  (when (featurep 'soundscape) (soundscape-restart))
  (when (featurep 'xbacklight) (xbacklight-black))
  (run-at-time  30 nil
                #'(lambda ()
                    (when (nm-connected-p) (emacspeak-dbus-nm-connected))))
  (when
      (dbus-call-method
       :session
       "org.gnome.ScreenSaver" "/org/gnome/ScreenSaver"
       "org.gnome.ScreenSaver" "GetActive")
    (dtk-say "Enter password to unlock screen. ")
    (emacspeak-auditory-icon 'help))
  (message "Successfully ran resume hook."))

(add-hook 'emacspeak-dbus-resume-hook #'emacspeak-dbus-resume)

;;}}}
;;{{{ Watch Screensaver:

(defvar emacspeak-dbus-screen-lock-handle nil
  "Handle to DBus signal registration for watching screenlock.")

(defun emacspeak-dbus-watch-screen-lock ()
  "Register a handler to watch screen lock/unlock."
  (cl-declare (special emacspeak-dbus-screen-lock-handle
                    emacspeak-screen-saver-saved-configuration))
  (setq emacspeak-dbus-screen-lock-handle
        (dbus-register-signal
         :session
         "org.gnome.ScreenSaver" "/org/gnome/ScreenSaver"
         "org.gnome.ScreenSaver" "ActiveChanged"
         #'(lambda(lock)
             (if lock
                 (progn
                   (sox-tones 1.5 1.5)
                   (emacspeak-screen-saver))
               (progn
                 (when (eq major-mode 'emacspeak-screen-saver-mode)(quit-window))
                 (sox-tones)
                 (when (window-configuration-p emacspeak-screen-saver-saved-configuration)
                   (set-window-configuration emacspeak-screen-saver-saved-configuration))
                 (dtk-notify-say "Unlocking screen")
                 (emacspeak-speak-mode-line)))))))

(defun emacspeak-dbus-unwatch-screen-lock ()
  "De-Register a handler to watch screen lock/unlock."
  (cl-declare (special emacspeak-dbus-screen-lock-handle))
  (dbus-unregister-object emacspeak-dbus-screen-lock-handle)
  (setq emacspeak-dbus-screen-lock-handle nil)
  (message "Unregistered screen-lock signal handler"))

;;}}}
(provide 'emacspeak-dbus)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
