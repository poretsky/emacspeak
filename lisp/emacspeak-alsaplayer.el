;;; emacspeak-alsaplayer.el --- Control alsaplayer from Emacs
;;; $Id: emacspeak-alsaplayer.el 4532 2007-05-04 01:13:44Z tv.raman.tv $
;;; $Author: tv.raman.tv $
;;; Description: Controlling alsaplayer from emacs 
;;; Keywords: Emacspeak, alsaplayer
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

;;; Defines a simple derived mode for interacting with
;;; alsaplayer.
;;; alsaplayer navigation commands  work via single keystrokes.

;;; Code:

;;}}}
;;{{{  Required modules

(require 'emacspeak-preamble)
;;}}}
;;{{{ define a derived mode for alsaplayer interaction

(defvar emacspeak-alsaplayer-process nil
  "Process handle to alsaplayer." )

;;;###autoload
(define-prefix-command 'emacspeak-alsaplayer-prefix-command
  'emacspeak-alsaplayer-mode-map)

(define-derived-mode emacspeak-alsaplayer-mode fundamental-mode 
  "Alsaplayer Interaction"
  "Major mode for alsaplayer interaction. \n\n
\\{emacspeak-alsaplayer-mode-map}")

;;}}}
;;{{{ launch  emacspeak-alsaplayer

(defcustom emacspeak-alsaplayer-auditory-feedback t
  "Turn this on if you want spoken feedback and auditory icons from alsaplayer."
  :type 'boolean
  :group 'emacspeak-alsaplayer)

(defcustom emacspeak-alsaplayer-program
  "alsaplayer"
  "Alsaplayer executable."
  :type 'string
  :group 'emacspeak-alsaplayer)

(defcustom emacspeak-alsaplayer-output nil
  "Alsaplayer driver for sound output."
  :type '(choice (const :tag "default" nil)
		 (const "alsa")
		 (const "oss")
		 (const "jack")
		 (const "nas")
		 (const "sgi")
		 (const "sparc")
		 (string :tag "Driver name"))
  :group 'emacspeak-alsaplayer)

(defcustom emacspeak-alsaplayer-sound-device nil
  "Alsaplayer sound device.
Default is hw:0,0 for ALSA and /dev/dsp for OSS output."
  :type '(choice (const :tag "default" nil)
		 (string :tag "Device specification"))
  :group 'emacspeak-alsaplayer)

(defcustom emacspeak-alsaplayer-coding-system nil
  "Alsaplayer output coding system.
It is used for tags decoding."
  :type '(coding-system :size 0)
  :group 'emacspeak-alsaplayer)

(defcustom emacspeak-alsaplayer-media-directory
  (expand-file-name "~/mp3/")
  "Directory to look for media files."
  :type 'directory
  :group 'emacspeak-alsaplayer)

(defvar emacspeak-alsaplayer-buffer "*alsaplayer*"
  "Buffer for alsaplayer interaction.")

;;;###autoload
(defun emacspeak-alsaplayer-launch ()
  "Launch Alsaplayer.
user is placed in a buffer associated with the newly created
Alsaplayer session."
  (interactive)
  (declare (special emacspeak-alsaplayer-program
                    emacspeak-alsaplayer-process
                    emacspeak-alsaplayer-buffer))
  (if (and emacspeak-alsaplayer-process
           (eq 'run (process-status
                     emacspeak-alsaplayer-process)))
      (when (y-or-n-p "Stop currently playing music? ")
        (emacspeak-alsaplayer-quit)
        (setq emacspeak-alsaplayer-process nil))
    (setq emacspeak-alsaplayer-process nil))
  (let ((process-connection-type t)
        (coding-system-for-read emacspeak-alsaplayer-coding-system)
        (options (nconc (list "-r" "-i" "daemon")
                        (when emacspeak-alsaplayer-output
                          (list "-o" emacspeak-alsaplayer-output))
                        (when emacspeak-alsaplayer-sound-device
                          (list "-d" emacspeak-alsaplayer-sound-device))))
        (buffer (get-buffer-create emacspeak-alsaplayer-buffer)))
    (save-excursion
      (set-buffer buffer)
      (setq buffer-undo-list t)
      (emacspeak-alsaplayer-mode)
      (unless emacspeak-alsaplayer-process
        (setq emacspeak-alsaplayer-process
              (apply 'start-process
                     "alsaplayer"
                     (current-buffer)
                     emacspeak-alsaplayer-program
                     options))
        (accept-process-output emacspeak-alsaplayer-process)
        (erase-buffer)
        (call-process emacspeak-alsaplayer-program
                      nil t t
                      "--status")
        (goto-char (point-min))
        (when (search-forward "path: " nil t)
          (encode-coding-region (point) (line-end-position)
                                emacspeak-alsaplayer-coding-system)
          (decode-coding-region (point) (line-end-position)
                                (car default-process-coding-system)))))
    (switch-to-buffer buffer))
  (when (and emacspeak-alsaplayer-auditory-feedback (interactive-p))
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-mode-line)))

;;}}}
;;{{{  Invoke commands:

(defun emacspeak-alsaplayer-send-command(command &optional watch-pattern no-refresh)
  "Send command to Alsaplayer.
Optional second arg watch-pattern specifies line of output to
  focus on.  Optional third arg no-refresh is used to avoid
  getting status twice."
  (declare (special emacspeak-alsaplayer-program
                    emacspeak-alsaplayer-buffer))
  (save-excursion
    (set-buffer (get-buffer-create emacspeak-alsaplayer-buffer))
    (erase-buffer)
    (let ((coding-system-for-read emacspeak-alsaplayer-coding-system))
      (apply 'call-process
             emacspeak-alsaplayer-program
             nil t t
             (if (listp command)
                 command
               (list command)))
      (unless no-refresh
        (call-process
         emacspeak-alsaplayer-program
         nil t t
         "--status")))
    (goto-char (point-min))
    (when (search-forward "path: " nil t)
      (encode-coding-region (point) (line-end-position)
                            emacspeak-alsaplayer-coding-system)
      (decode-coding-region (point) (line-end-position)
                            (car default-process-coding-system))))
  (when (and watch-pattern
             (eq (current-buffer) (get-buffer emacspeak-alsaplayer-buffer)))
    (goto-char (point-min))
    (re-search-forward watch-pattern  nil t)))

(defun emacspeak-alsaplayer-add-to-queue (resource)
  "Add specified resource to queue."
  (interactive
   (list
    (read-file-name "Media Resource: "
                    (if 
                        (string-match (format "^%s"
                                              emacspeak-alsaplayer-media-directory)
                                      (expand-file-name default-directory))
                        default-directory
                      emacspeak-alsaplayer-media-directory))))
  (emacspeak-alsaplayer-send-command
   (nconc (list "--enqueue")
          (if (file-directory-p resource)
              (directory-files
               (expand-file-name resource)
               'full
               "\\([Mm][Pp][23]\\)\\|\\([Oo][Gg][Gg]\\)\\|\\([Ww][Aa][Vv]\\)$")
            (expand-file-name resource)))
   "playlist_length:")
  (when (and emacspeak-alsaplayer-auditory-feedback
             (interactive-p))
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-line)))

(defun emacspeak-alsaplayer-replace-queue (resource)
  "Replace currently playing music."
  (interactive
   (list
    (read-file-name "New Media Resource: "
                    (if 
                        (string-match (format "^%s"
                                              emacspeak-alsaplayer-media-directory)
                                      (expand-file-name default-directory))
                        default-directory
                      emacspeak-alsaplayer-media-directory))))
  (emacspeak-alsaplayer-send-command
   (nconc (list "--replace")
          (if (file-directory-p resource)
              (directory-files
               (expand-file-name resource)
               'full
               "\\([Mm][Pp][23]\\)\\|\\([Oo][Gg][Gg]\\)\\|\\([Ww][Aa][Vv]\\)$")
            (expand-file-name resource)))
   "playlist_length:")
  (when (and emacspeak-alsaplayer-auditory-feedback
             (interactive-p))
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-line)))

(defun emacspeak-alsaplayer-status ()
  "Show alsaplayer status"
  (interactive)
  (emacspeak-alsaplayer-send-command "--status"
                                     "position:"
                                     'no-refresh)
  (when (interactive-p)
    (unless (eq (current-buffer)
                (get-buffer emacspeak-alsaplayer-buffer))
      (switch-to-buffer emacspeak-alsaplayer-buffer))
    (when  emacspeak-alsaplayer-auditory-feedback
      (emacspeak-auditory-icon 'select-object)
      (emacspeak-speak-line))))

(defun emacspeak-alsaplayer-pause ()
  "Pause or resume alsaplayer"
  (interactive)
  (emacspeak-alsaplayer-send-command "--pause"
                                     "position:")
  (when (and emacspeak-alsaplayer-auditory-feedback
             (interactive-p))
    (emacspeak-auditory-icon 'button)
    (emacspeak-speak-line)))

(defun emacspeak-alsaplayer-next ()
  "Next  alsaplayer"
  (interactive)
  (emacspeak-alsaplayer-send-command "--next"
                                     "\\(title\\|path\\):")
  (when (and emacspeak-alsaplayer-auditory-feedback
             (interactive-p))
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-line)))

(defun emacspeak-alsaplayer-previous ()
  "Previous  alsaplayer"
  (interactive)
  (emacspeak-alsaplayer-send-command "--prev"
                                     "\\(title\\|path\\):")
  (when (and emacspeak-alsaplayer-auditory-feedback
             (interactive-p))
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-line)))
    
(defun emacspeak-alsaplayer-start ()
  "Start  alsaplayer"
  (interactive)
  (emacspeak-alsaplayer-send-command "--start"
                                     "position:")
  (when (and emacspeak-alsaplayer-auditory-feedback
             (interactive-p))
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-line)))

(defun emacspeak-alsaplayer-stop ()
  "Stop  alsaplayer"
  (interactive)
  (emacspeak-alsaplayer-send-command "--stop"
                                     "position:")
  (when (and emacspeak-alsaplayer-auditory-feedback
             (interactive-p))
    (emacspeak-auditory-icon 'close-object)
    (emacspeak-speak-line)))

(defun emacspeak-alsaplayer-relative (offset)
  "Relative seek  alsaplayer"
  (interactive "sOffset")
  (emacspeak-alsaplayer-send-command
   (list "--relative" offset)
   "position:")
  (when (and emacspeak-alsaplayer-auditory-feedback
             (interactive-p))
    (emacspeak-auditory-icon 'large-movement)
    (emacspeak-speak-line)))

(defun emacspeak-alsaplayer-speed (setting)
  "Set speed in alsaplayer."
  (interactive "sSpeed")
  (emacspeak-alsaplayer-send-command
   (list "--speed" setting)
   "speed:")
  (when (and emacspeak-alsaplayer-auditory-feedback
             (interactive-p))
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-line)))

(defun emacspeak-alsaplayer-volume (setting)
  "Set volume."
  (interactive "sVolume")
  (emacspeak-alsaplayer-send-command
   (list "--volume" setting)
   "volume:")
  (when (and emacspeak-alsaplayer-auditory-feedback
             (interactive-p))
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-line)))

(defun emacspeak-alsaplayer-seek (offset)
  "Absolute seek  alsaplayer"
  (interactive "sPosition")
  (emacspeak-alsaplayer-send-command
   (list "--seek" offset)
   "position:")
  (when (and emacspeak-alsaplayer-auditory-feedback
             (interactive-p))
    (emacspeak-auditory-icon 'large-movement)
    (emacspeak-speak-line)))

(defun emacspeak-alsaplayer-jump (track)
  "Jump to specified track."
  (interactive "sTrack Number:")
  (emacspeak-alsaplayer-send-command
   (list "--jump" track)
   "\\(title\\|path\\):")
  (when (and emacspeak-alsaplayer-auditory-feedback
             (interactive-p))
    (emacspeak-auditory-icon 'large-movement)
    (emacspeak-speak-line)))

(defun emacspeak-alsaplayer-clear ()
  "Clear or resume alsaplayer"
  (interactive)
  (emacspeak-alsaplayer-send-command "--clear"
                                     "playlist_length:")
  (when (and emacspeak-alsaplayer-auditory-feedback
             (interactive-p))
    (emacspeak-auditory-icon 'delete-object)
    (emacspeak-speak-line)))

(defun emacspeak-alsaplayer-quit ()
  "Quit or resume alsaplayer"
  (interactive)
  (emacspeak-alsaplayer-send-command "--quit" nil t)
  (when (eq major-mode 'emacspeak-alsaplayer-mode)
    (kill-buffer (current-buffer)))
  (when (and emacspeak-alsaplayer-auditory-feedback (interactive-p))
    (emacspeak-speak-mode-line)
    (emacspeak-auditory-icon 'close-object)))

;;}}}
;;{{{ additional temporal navigation 

(defun emacspeak-alsaplayer-forward-10-seconds ( )
  "Skip forward by  seconds."
  (interactive)
  (emacspeak-alsaplayer-send-command (list "--relative" "10")
                                     "position:")
  (when (interactive-p)
    (emacspeak-speak-line)))

(defun emacspeak-alsaplayer-backward-10-seconds()
  "Skip backward by  10 seconds."
  (interactive)
  (emacspeak-alsaplayer-send-command
   (list "--relative" "-10")
   "position:")
  (when (interactive-p)
    (emacspeak-speak-line)))

(defun emacspeak-alsaplayer-forward-minute ( minutes)
  "Skip forward by  minutes."
  (interactive "p")
  (emacspeak-alsaplayer-send-command
   (list "--relative"
           (* 60 (or minutes 1)))
   "position:")
  (when (interactive-p)
    (emacspeak-speak-line)))

(defun emacspeak-alsaplayer-backward-minute ( minutes)
  "Skip backwards by  minutes."
  (interactive "p")
  (emacspeak-alsaplayer-send-command
   (list
    "--relative"
    (format "-%s" (* 60 (or minutes 1))))
   "position:")
  (when (interactive-p)
    (emacspeak-speak-line)))

(defun emacspeak-alsaplayer-forward-ten-minutes ( minutes)
  "Skip forward by  chunks of ten minutes."
  (interactive "p")
  (emacspeak-alsaplayer-send-command
   (list
    "--relative"
    (* 600 (or minutes 1)))
   "position:")
  (when (interactive-p)
    (emacspeak-speak-line)))

(defun emacspeak-alsaplayer-backward-ten-minutes ( minutes)
  "Skip backwards by  chunks of minutes."
  (interactive "p")
  (emacspeak-alsaplayer-send-command
   (list
    "--relative"
    (format "-%s" (* 600 (or minutes 1))))
   "position:")
  (when (interactive-p)
    (emacspeak-speak-line)))

;;}}}
;;{{{  saving positions, marking and clipping:

(defvar emacspeak-alsaplayer-mark nil
  "Saved mark position.")

(defsubst emacspeak-alsaplayer-get-position ()
  "Return currently displayed position."
  (declare (special emacspeak-alsaplayer-buffer))
  (save-excursion
    (set-buffer emacspeak-alsaplayer-buffer)
    (goto-char (point-min))
    (when (search-forward "position:" nil t)
      (second
       (split-string
        (buffer-substring-no-properties
         (line-beginning-position)
         (line-end-position))
        ": ")))))

(defun emacspeak-alsaplayer-mark-position   ()
  "Mark currently displayed position."
  (interactive)
  (declare (special emacspeak-alsaplayer-mark))e
  (setq emacspeak-alsaplayer-mark
        (emacspeak-alsaplayer-get-position))
  (when (and (interactive-p)
             emacspeak-alsaplayer-mark)
    (message "mark set at %s"
             emacspeak-alsaplayer-mark)
    (emacspeak-auditory-icon 'mark-object)))

(defun emacspeak-alsaplayer-where ()
  "Speak current position and copy it to kill ring."
  (interactive)
  (let ((where (emacspeak-alsaplayer-get-position)))
    (when where
      (kill-new where)
      (emacspeak-auditory-icon 'yank-object)
      (message "%s" where))))

(defsubst emacspeak-alsaplayer-get-path ()
  "Return currently displayed path."
  (declare (special emacspeak-alsaplayer-buffer))
  (save-excursion
    (set-buffer emacspeak-alsaplayer-buffer)
    (goto-char (point-min))
    (when (search-forward "path:" nil t)
      (second
       (split-string
        (buffer-substring-no-properties
         (line-beginning-position)
         (line-end-position))
        ": ")))))

(defun emacspeak-alsaplayer-info ()
  "Speak current path and copy it to kill ring."
  (interactive)
  (let ((path (emacspeak-alsaplayer-get-path)))
    (when path
      (kill-new path)
      (emacspeak-auditory-icon 'yank-object)
      (message "%s" path))))

(defvar emacspeak-alsaplayer-mp3split-program "mp3splt"
  "Program used to clip mp3 files.")

(defun emacspeak-alsaplayer-clip (path start end)
  "Invoke mp3splt to clip selected range."
  (interactive
   (list
    (read-file-name "Path:")
    (read-minibuffer "Start: " emacspeak-alsaplayer-mark)
    (read-minibuffer "End: ")))
  (cd (file-name-directory path))
  (shell-command
   (format "%s %s %s %s"
           emacspeak-alsaplayer-mp3split-program
           path
           (format "%d.%d"
                   (/ start 60)
                   (% start 60))
           (format "%d.%d"
                   (/ end 60)
                   (% end 60)))))
           
                    

;;}}}
;;{{{ bind keys

(declaim (special emacspeak-alsaplayer-mode-map))

(loop for k in
      '(
        ("m" emacspeak-alsaplayer-mark-position)
        ("w" emacspeak-alsaplayer-where)
        ("x" emacspeak-alsaplayer-clip)
        ("." emacspeak-alsaplayer-forward-10-seconds)
        ("i" emacspeak-alsaplayer-info)
        ("," emacspeak-alsaplayer-backward-10-seconds)
        (">" emacspeak-alsaplayer-forward-minute)
        ("<" emacspeak-alsaplayer-backward-minute)
        ("]" emacspeak-alsaplayer-forward-ten-minutes)
        ("[" emacspeak-alsaplayer-backward-ten-minutes)

        ("a"
         emacspeak-alsaplayer-add-to-queue)
        ("A"
         emacspeak-alsaplayer-replace-queue)
        ("c"
         emacspeak-alsaplayer-clear)
        ("g"
         emacspeak-alsaplayer-seek)
        ("j" emacspeak-alsaplayer-jump)
        (" "
         emacspeak-alsaplayer-pause)
        ("n"
         emacspeak-alsaplayer-next)
        ("p"
         emacspeak-alsaplayer-previous)
        ("q"
         emacspeak-alsaplayer-quit)
        ("r" emacspeak-alsaplayer-relative)
        ("s"
         emacspeak-alsaplayer-start)
        ("S"
         emacspeak-alsaplayer-stop)
        ("/" emacspeak-alsaplayer-speed)
        ("?"
         emacspeak-alsaplayer-status)
        ("v" emacspeak-alsaplayer-volume)
        ("l" emacspeak-alsaplayer-launch)
        )
      do
      (emacspeak-keymap-update  emacspeak-alsaplayer-mode-map k))

;;}}}
(provide 'emacspeak-alsaplayer)
;;{{{ end of file 

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end: 

;;}}}
