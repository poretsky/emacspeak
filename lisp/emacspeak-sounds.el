;;; emacspeak-sounds.el --- Defines Emacspeak auditory icons  -*- lexical-binding: t; -*-
;;; $Id$
;;; $Author: tv.raman.tv $
;;; Description:  Module for adding sound cues to emacspeak
;;; Keywords:emacspeak, audio interface to emacs, auditory icons
;;{{{  LCD Archive entry:

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu
;;; A speech interface to Emacs |
;;; $Date: 2007-09-01 15:30:13 -0700 (Sat, 01 Sep 2007) $ |
;;;  $Revision: 4670 $ |
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:
;;;Copyright (C) 1995 -- 2015, T. V. Raman
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
;;; This module provides the interface for generating auditory icons in emacspeak.
;;; Design goal:
;;; 1) Auditory icons should be used to provide additional feedback,
;;; not as a gimmick.
;;; 2) The interface should be usable at all times without the icons:
;;; e.g. when on a machine without a sound card.
;;; 3) General principle for when to use an icon:
;;; Convey information about events taking place in parallel.
;;; For instance, if making a selection automatically moves the current focus
;;; to the next choice,
;;; We speak the next choice, while indicating the fact that something was selected with a sound cue.
;;;  This interface will assume the availability of a shell command "play"
;;; that can take one or more sound files and play them.
;;; This module will also provide a mapping between names in the elisp world and actual sound files.
;;; Modules that wish to use auditory icons should use these names, instead of actual file names.
;;; As of Emacspeak 13.0, this module defines a themes
;;; architecture for  auditory icons.
;;; Sound files corresponding to a given theme are found in
;;; appropriate subdirectories of emacspeak-sounds-directory

;;}}}
;;{{{ required modules

;;; Code:
(eval-when-compile (require 'cl))
(declaim  (optimize  (safety 0) (speed 3)))
(require 'custom)
(eval-when (compile)
  (require 'dtk-speak))

;;}}}
;;{{{  state of auditory icons

(defvar emacspeak-use-auditory-icons t
  "Tells if emacspeak should use auditory icons.
Do not set this variable by hand,
use `emacspeak-toggle-auditory-icons' bound to
\\[emacspeak-toggle-auditory-icons].")

(make-variable-buffer-local 'emacspeak-use-auditory-icons)

;;}}}
;;{{{ Setup Audio 
;;;###autoload
(defun emacspeak-audio-setup (&optional prefix)
  "Call appropriate audio environment set command."
  (interactive "P")
  (cond
   ((executable-find "amixer")
    (funcall-interactively #'amixer prefix))
   (t (funcall-interactively #'emacspeak-aumix)))
  (emacspeak-auditory-icon 'close-object))

;;}}}
;;{{{  Setup sound themes

(defvar emacspeak-default-sound
  (expand-file-name
   "classic/button.wav"
   emacspeak-sounds-directory)
  "Default sound to play if requested icon not found.")

(defvar emacspeak-sounds-themes-table
  (make-hash-table)
  "Maps valid sound themes to the file name extension used by that theme.")

;;;###autoload
(defun emacspeak-sounds-define-theme (theme-name file-ext)
  "Define a sounds theme for auditory icons. "
  (declare (special emacspeak-sounds-themes-table))
  (setq theme-name (intern theme-name))
  (setf (gethash  theme-name emacspeak-sounds-themes-table)
        file-ext))

(defun emacspeak-sounds-theme-directory (theme)
  "Get directory path for specified sounds theme."
  (file-name-as-directory (expand-file-name theme emacspeak-sounds-directory)))

(defun emacspeak-sounds-theme-definition (theme)
  "Get sounds theme definition file path."
  (expand-file-name "define-theme.el" (emacspeak-sounds-theme-directory theme)))

(defun emacspeak-sounds-theme-p  (theme)
  "Predicate to test if theme is available."
  (file-exists-p (emacspeak-sounds-theme-definition theme)))

(defun emacspeak-sounds-get-themes ()
  "Get list of available sound themes."
  (let (themes)
    (dolist (item (directory-files emacspeak-sounds-directory nil "^[^.]") themes)
      (when (emacspeak-sounds-theme-p item)
        (add-to-list 'themes item t)))))

(defgroup emacspeak-sounds nil
  "Emacspeak auditory icons."
  :group 'emacspeak)

;;;###autoload
(defcustom emacspeak-sounds-default-theme "3d"
  "Default theme for auditory icons. "
  :type (let ((menu '(choice)))
          (dolist (item (emacspeak-sounds-get-themes) menu)
            (add-to-list 'menu (list 'const item) t)))
  :set (lambda (symbol value)
	 (custom-set-default symbol value)
	 (emacspeak-sounds-select-theme value))
  :initialize 'custom-initialize-default
  :group 'emacspeak-sounds)

;;;###autoload
(defcustom emacspeak-play-program
  (cond
   ((getenv "EMACSPEAK_PLAY_PROGRAM")
    (getenv "EMACSPEAK_PLAY_PROGRAM"))
   ((file-exists-p "/usr/bin/aplay") "/usr/bin/aplay")
   ((file-exists-p "/usr/bin/play") "/usr/bin/play")
   ((file-exists-p "/usr/bin/audioplay") "/usr/bin/audioplay")
   ((file-exists-p "/usr/demo/SOUND/play") "/usr/demo/SOUND/play")
   (t (expand-file-name emacspeak-etc-directory "play")))
  "Name of executable that plays sound files. "
  :group 'emacspeak-sounds
  :type 'string)

(defvar emacspeak-sounds-current-theme
  (emacspeak-sounds-theme-directory emacspeak-sounds-default-theme)
  "Directory path of current theme for auditory icons.
Do not set this by hand;
--use command \\[emacspeak-sounds-select-theme].")

(defsubst emacspeak-sounds-theme-get-extension (theme-name)
  "Retrieve filename extension for specified theme. "
  (declare (special emacspeak-sounds-themes-table))
  (gethash
   (intern theme-name)
   emacspeak-sounds-themes-table))

(defsubst emacspeak-sounds-define-theme-if-necessary (theme-name)
  "Define selected theme if necessary."
  (unless (emacspeak-sounds-theme-get-extension theme-name)
    (load-file (emacspeak-sounds-theme-definition theme-name))))

;;;###autoload
(defun emacspeak-sounds-select-theme  (theme)
  "Select theme for auditory icons."
  (interactive
   (list
    (completing-read "Theme: " (emacspeak-sounds-get-themes)
                     nil t nil nil
                     emacspeak-sounds-default-theme)))
  (declare (special emacspeak-sounds-current-theme emacspeak-sounds-themes-table))
  (setq theme (emacspeak-sounds-theme-directory theme))
  (unless (file-exists-p theme)
    (error "Theme %s is not installed" theme))
  (setq emacspeak-sounds-current-theme theme)
  (emacspeak-sounds-define-theme-if-necessary theme)
  (emacspeak-auditory-icon 'select-object))

(defsubst emacspeak-get-sound-filename (sound-name)
  "Retrieve name of sound file that produces  auditory icon SOUND-NAME."
  (declare (special emacspeak-sounds-themes-table
                    emacspeak-sounds-current-theme))
  (let ((f
         (expand-file-name
          (format "%s%s"
                  sound-name
                  (emacspeak-sounds-theme-get-extension emacspeak-sounds-current-theme))
          emacspeak-sounds-current-theme)))
    (cond
     ((file-exists-p f) f)
     (t
      (message "Icon %s not defined." sound-name)
      emacspeak-default-sound))))

;;}}}
;;{{{  queue an auditory icon
;;;###autoload
(defun emacspeak-queue-auditory-icon (sound-name)
  "Queue auditory icon SOUND-NAME."
  (declare (special dtk-speaker-process))
  (process-send-string dtk-speaker-process
                       (format "a %s\n"
                               (emacspeak-get-sound-filename sound-name))))

;;}}}
;;{{{  native player (
;;;###autoload
(defun emacspeak-native-auditory-icon (sound-name)
  "Play auditory icon using native Emacs player."
  (play-sound
   (list 'sound
         :file (format "%s" (emacspeak-get-sound-filename sound-name)))))

;;}}}
;;{{{  serve an auditory icon

;;;###autoload
(defun emacspeak-serve-auditory-icon (sound-name)
  "Serve auditory icon SOUND-NAME."
  (declare (special dtk-speaker-process))
  (process-send-string dtk-speaker-process
                       (format "p %s\n"
                               (emacspeak-get-sound-filename sound-name))))

;;}}}
;;{{{  Play an icon

;;;###autoload
(defcustom emacspeak-play-args nil
  "Set this to -i  if using the play program that ships on sunos/solaris.
Note: on sparc20's there is a sunos bug that causes the machine to crash if
you attempt to play sound when /dev/audio is busy.
It's imperative that you use the -i flag to play on
sparc20's."
  :type '(repeat string)
  :group 'emacspeak-sounds)

(defun emacspeak-play-auditory-icon (sound-name)
  "Produce auditory icon SOUND-NAME."
  (declare (special emacspeak-play-program emacspeak-play-args))
  (let ((process-connection-type nil)
        (default-directory (file-name-as-directory (getenv "HOME"))))
    (condition-case err
        (apply 'start-process
               emacspeak-play-program nil emacspeak-play-program
               (append emacspeak-play-args
                       (list (emacspeak-get-sound-filename sound-name))))
      (error
       (message (error-message-string err))))))

;;;###autoload
(defcustom emacspeak-soxplay-command 
  (when(executable-find "play")
    (format "%s -v 1.2 %%s  earwax &" (executable-find "play")))
  "Name of play executable from SoX"
  :group 'emacspeak-sounds
  :type 'string)
(defun emacspeak-soxplay-auditory-icon (sound-name)
  "Produce auditory icon SOUND-NAME.
This uses SoX play and is specifically for use with headphones."
  (declare (special emacspeak-soxplay-command))
  (let ((icon (emacspeak-get-sound-filename sound-name)))
    (call-process shell-file-name nil nil nil shell-command-switch
                  (format emacspeak-soxplay-command icon))))

;;}}}
;;{{{  setup play function

(defcustom emacspeak-auditory-icon-function 'emacspeak-serve-auditory-icon
  "*Function that plays auditory icons.
play : Launches play-program to play.
Serve: Send a command to the speech-server to play.
Queue : Add auditory icon to speech queue.
soxplay: Use sox to apply effect earwax for headphones.
Native : Use Emacs' builtin sound support.
Use Serve when working with remote speech servers."
  :group 'emacspeak-sounds
  :type '(choice
          (const emacspeak-play-auditory-icon)
          (const emacspeak-serve-auditory-icon)
          (const emacspeak-native-auditory-icon)
          (const emacspeak-soxplay-auditory-icon)
          (const emacspeak-queue-auditory-icon)))

;;;###autoload
(defun emacspeak-auditory-icon (icon)
  "Play an auditory ICON."
  (declare (special emacspeak-auditory-icon-function
                    emacspeak-use-auditory-icons))
  (when emacspeak-use-auditory-icons
    (funcall emacspeak-auditory-icon-function icon)))

;;}}}
;;{{{  toggle auditory icons

;;; This is the main entry point to this module:
;;;###autoload
(defun emacspeak-toggle-auditory-icons (&optional prefix)
  "Toggle use of auditory icons.
Optional interactive PREFIX arg toggles global value."
  (interactive "P")
  (declare (special emacspeak-use-auditory-icons
                    dtk-program emacspeak-auditory-icon-function))
  (require 'emacspeak-aumix)
  (cond
   (prefix
    (setq  emacspeak-use-auditory-icons
           (not emacspeak-use-auditory-icons))
    (setq-default emacspeak-use-auditory-icons
                  emacspeak-use-auditory-icons))
   (t (setq emacspeak-use-auditory-icons
            (not emacspeak-use-auditory-icons))))
  (message "Turned %s auditory icons %s"
           (if emacspeak-use-auditory-icons  "on" "off")
           (if prefix "" "locally"))
  (when emacspeak-use-auditory-icons
    (emacspeak-auditory-icon 'on)))

(defvar emacspeak-sounds-auditory-icon-players
  '("emacspeak-serve-auditory-icon"
    "emacspeak-play-auditory-icon"
    "emacspeak-native-auditory-icon")
  "Table of auditory icon players used  when selecting a player.")

(defun emacspeak-select-auditory-icon-player ()
  "Pick a player for producing auditory icons."
  (declare (special emacspeak-sounds-auditory-icon-players))
  (read
   (completing-read "Select auditory icon player: "
                    emacspeak-sounds-auditory-icon-players
                    nil nil
                    "emacspeak-")))
;;;###autoload
(defun  emacspeak-set-auditory-icon-player (player)
  "Select  player used for producing auditory icons.
Recommended choices:

emacspeak-serve-auditory-icon for  the wave device.
emacspeak-queue-auditory-icon when using software TTS."
  (interactive
   (list (emacspeak-select-auditory-icon-player)))
  (declare (special emacspeak-auditory-icon-function))
  (setq emacspeak-auditory-icon-function player)
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'select-object)))

;;}}}
;;{{{ reset local player
(defun emacspeak-sounds-reset-local-player ()
  "Ask Emacspeak to use a local audio player.
This lets me have Emacspeak switch to using audioplay on
solaris after I've used it for a while from a remote session
where it would use the more primitive speech-server based
audio player."
  (interactive)
  (declare (special emacspeak-play-program))
  (if (file-exists-p "/usr/demo/SOUND/play")
      (setq
       emacspeak-play-program "/usr/demo/SOUND/play"
       emacspeak-play-args "-i"
       emacspeak-auditory-icon-function
       'emacspeak-play-auditory-icon))
  (if (file-exists-p "/usr/bin/audioplay")
      (setq
       emacspeak-play-program "/usr/bin/audioplay"
       emacspeak-play-args "-i"
       emacspeak-auditory-icon-function 'emacspeak-play-auditory-icon)))

;;}}}
;;{{{  flush sound driver

(defcustom emacspeak-sounds-reset-snd-module-command nil
  "Command to reset sound module."
  :type '(choice
          :tag "Command to reset sound modules: "
          (const nil :tag "None")
          (string :tag "Command "))
  :group 'emacspeak-sounds)
;;;###autoload
(defun emacspeak-sounds-reset-sound  ()
  "Reload sound drivers."
  (interactive)
  (declare (special emacspeak-sounds-reset-snd-module-command))
  (when emacspeak-sounds-reset-snd-module-command
    (shell-command emacspeak-sounds-reset-snd-module-command)))

;;}}}
(provide  'emacspeak-sounds)
;;{{{  emacs local variables

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: nil
;;; end:

;;}}}
