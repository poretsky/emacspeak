;;; emacspeak-dired.el --- Speech enable Dired Mode -- A powerful File Manager
;;; $Id$
;;; $Author: tv.raman.tv $
;;; Description:  Emacspeak extension to speech enable dired
;;; Keywords: Emacspeak, Dired, Spoken Output
;;{{{  LCD Archive entry:

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu
;;; A speech interface to Emacs |
;;; $Date: 2008-07-19 16:09:43 -0700 (Sat, 19 Jul 2008) $ |
;;;  $Revision: 4532 $ |
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;{{{  Introduction:

;;; Commentary:
;;; This module speech enables dired.
;;; It reduces the amount of speech you hear:
;;; Typically you hear the file names as you move through the dired buffer
;;; Voicification is used to indicate directories, marked files etc.

;;}}}
;;{{{  required packages

;;; Code:
(require 'cl)
(require 'emacspeak-preamble)
(require 'desktop)
(require 'dired)
;;}}}
;;{{{ Define personalities

(voice-setup-add-map
 '(
   (dired-header voice-smoothen)
   (dired-mark voice-lighten)
   (dired-perm-write voice-lighten-extra)
   (dired-marked voice-lighten)
   (dired-warning voice-animate-extra)
   (dired-directory voice-bolden-medium)
   (dired-symlink voice-animate-extra)
   (dired-ignored voice-lighten-extra)
   (dired-flagged voice-animate-extra)
   ))

;;}}}
;;{{{  functions:

(defsubst emacspeak-dired-speak-line ()
  "Speak the dired line intelligently."
  (declare (special emacspeak-speak-last-spoken-word-position))
  (let ((filename (dired-get-filename 'no-dir  t ))
        (personality (dtk-get-style)))
    (cond
     (filename
      (dtk-speak (propertize (directory-file-name
                              (file-relative-name filename))
                             'personality personality))
      (setq emacspeak-speak-last-spoken-word-position (point)))
     (t (emacspeak-speak-line )))))

;;}}}
;;{{{  labeling fields in the dired buffer:

(defun emacspeak-dired-label-fields-on-current-line ()
  "Labels the fields on a dired line.
Assumes that `dired-listing-switches' contains  -l"
  (let ((start nil)
        (fields (list "permissions"
                      "links"
                      "owner"
                      "group"
                      "size"
                      "modified in"
                      "modified on"
                      "modified at"
                      "name")))
    (save-excursion
      (forward-line 0)
      (skip-syntax-forward " ")
      (while (and fields
                  (not (eolp)))
        (setq start (point))
        (skip-syntax-forward "^ ")
        (put-text-property start (point)
                           'field-name (car fields ))
        (setq fields (cdr fields ))
        (skip-syntax-forward " ")))))

(defun emacspeak-dired-label-fields ()
  "Labels the fields of the listing in the dired buffer.
Currently is a no-op  unless
unless `dired-listing-switches' contains -l"
  (interactive)
  (declare (special dired-listing-switches))
  (when
      (save-match-data
        (string-match  "l" dired-listing-switches))
    (let ((read-only buffer-read-only))
      (unwind-protect
          (progn
            (setq buffer-read-only nil)
            (save-excursion
              (goto-char (point-min))
              (dired-goto-next-nontrivial-file)
              (while (not (eobp))
                (emacspeak-dired-label-fields-on-current-line )
                (forward-line 1 ))))
        (setq buffer-read-only read-only )))))

;;}}}
;;{{{  advice:

(defadvice dired-sort-toggle-or-edit (around emacspeak pre act comp)
  "Provide auditory feedback."
  (cond
   ((ems-interactive-p )
    (let ((emacspeak-speak-messages nil))
      ad-do-it
      (emacspeak-auditory-icon 'task-done)
      (emacspeak-speak-mode-line)))
   (t ad-do-it))
  ad-return-value)

(defadvice dired-change-marks (around emacspeak pre act comp)
  "Provide auditory feedback."
  (if (ems-interactive-p)
      (let ((emacspeak-speak-messages t))
	ad-do-it
	(emacspeak-auditory-icon 'select-object))
    ad-do-it)
  ad-return-value)

(defadvice dired-do-toggle (after emacspeak pre act comp)
  "Produce auditory icon."
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'select-object)))

(loop for f in
      '(dired-flag-auto-save-files dired-flag-backup-files)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act )
	  "Produce an auditory icon indicating that files
were marked or unmarked for deletion."
	  (when (ems-interactive-p )
	    (if (ad-get-arg 0)
		(emacspeak-auditory-icon 'deselect-object)
	      (emacspeak-auditory-icon 'delete-object))))))

(loop for f in
      '(dired-mark-symlinks dired-mark-directories dired-mark-executables)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act )
	  "Produce an auditory icon indicating that files were marked or unmarked."
	  (when (ems-interactive-p )
	    (if (ad-get-arg 0)
		(emacspeak-auditory-icon 'deselect-object)
	      (emacspeak-auditory-icon 'mark-object))))))

(loop for f in
      '(dired-flag-garbage-files dired-clean-directory)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act )
	  "Produce an auditory icon indicating that files were marked for deletion."
	  (when (ems-interactive-p )
	    (emacspeak-auditory-icon 'delete-object)))))

(defadvice dired-undo  (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (if (buffer-modified-p)
        (emacspeak-auditory-icon 'modified-object)
      (emacspeak-auditory-icon 'unmodified-object ))
    (emacspeak-dired-speak-line)))

(loop for f in
      '(dired-summary dired-show-file-type)
      do
      (eval
       `(defadvice ,f (around emacspeak pre act comp)
	  "Provide auditory feedback."
	  (if (ems-interactive-p)
	      (let ((emacspeak-speak-messages t))
		(emacspeak-auditory-icon 'select-object)
		ad-do-it)
	    ad-do-it)
	  ad-return-value)))

(defadvice dired-do-search (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-line)))

(loop for f in
      '(dired-do-byte-compile dired-do-load)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
	  "Produce auditory icon."
	  (when (ems-interactive-p )
	    (emacspeak-auditory-icon 'task-done)))))

(defadvice dired-maybe-insert-subdir  (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'yank-object)
    (emacspeak-dired-speak-line)))

(defadvice dired-do-kill-lines (before emacspeak pre act comp)
  "Speak item before killing it. "
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'delete-object)
    (when dtk-stop-immediately (dtk-stop))
    (let ((dtk-stop-immediately nil))
      (dtk-tone 500 30)
      (emacspeak-dired-speak-line))))

(defadvice dired-copy-filename-as-kill (after emacspeak pre act comp)
  "Produce an auditory icon if possible."
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'mark-object )))

(defadvice dired-do-query-replace-regexp (around emacspeak pre act comp)
  "Stop message from chattering.
Turn on voice lock temporarily.
Provide auditory icon when finished."
  (declare (special voice-lock-mode
                    global-voice-lock-mode))
  (let ((voice-lock-mode global-voice-lock-mode)
        (emacspeak-speak-messages nil))
    (dtk-stop)
    (unwind-protect
        ad-do-it
      (emacspeak-auditory-icon 'task-done))))

(defadvice dired-query (before emacspeak pre act comp)
  "Produce auditory icon."
  (emacspeak-auditory-icon 'ask-short-question))

(defadvice dired-quit (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'close-object)
    (emacspeak-speak-mode-line)))

(defadvice dired-up-directory (after emacspeak pre act)
  "Produce an auditory icon."
  (when (ems-interactive-p )
    (let ((emacspeak-speak-messages nil))
      (emacspeak-dired-label-fields)
      (emacspeak-auditory-icon 'open-object )
      (emacspeak-speak-mode-line))))

(defun emacspeak-dired-initialize ()
  "Set up emacspeak dired."
  (declare (special global-voice-lock-mode))
  (voice-lock-mode (if global-voice-lock-mode 1 -1))
  (emacspeak-dired-label-fields))
(loop
 for  f in
 '(dired ido-dired
         dired-other-window dired-other-frame)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Set up emacspeak."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'open-object )
       (emacspeak-speak-mode-line)))))

(defadvice dired-omit-mode (after emacspeak pre act comp)
  "Produce an auditory icon."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon
     (if dired-omit-mode
         'on
       'off))))

(loop for f in
      '(dired-find-file
	dired-find-file-other-window
	dired-display-file
	dired-view-file)
      do
      (eval
       `(defadvice ,f  (around  emacspeak pre act comp)
          "Produce an auditory feedback."
          (cond
           ((ems-interactive-p)
            (let ((directory-p (file-directory-p (dired-get-filename t t ))))
              ad-do-it
              (when directory-p
                (emacspeak-dired-label-fields))
              (emacspeak-auditory-icon 'open-object)
              (emacspeak-speak-mode-line)))
           (t ad-do-it))
          ad-return-value)))

(loop for f in
      '(dired-next-line
        dired-previous-line)
      do
      (eval
       `(defadvice ,f  (after  emacspeak pre act comp)
          "Speak the filename."
          (when (ems-interactive-p )
            (emacspeak-auditory-icon 'select-object)
            (emacspeak-dired-speak-line)))))

(loop
 for  f in
 '(
   dired-next-subdir dired-prev-subdir
                     dired-tree-up dired-tree-down
                     dired-next-marked-file dired-prev-marked-file
                     dired-next-dirline dired-prev-dirline
                     dired-jump
                     )
 do
 (eval
  `(defadvice ,f (after emacspeak pre act)
     "Speak the filename."
     (when (ems-interactive-p  )
       (emacspeak-auditory-icon 'large-movement)
       (emacspeak-dired-speak-line)))))

(loop
 for f in
 '(dired-next-line dired-previous-line)
 do
 (eval
  `(defadvice ,f  (after emacspeak pre act)
     "Speak the filename name."
     (when (ems-interactive-p  )
       (emacspeak-auditory-icon 'select-object)
       (emacspeak-dired-speak-line)))))

;;; Producing auditory icons:
;;; These dired commands do some action that causes a state change:
;;; e.g. marking a file, and then change
;;; the current selection, ie
;;; move to the next line:
;;; We speak the line moved to, and indicate the state change
;;; with an auditory icon.

(defadvice dired-mark (after emacspeak pre act)
  "Produce an auditory icon."
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'mark-object )
    (emacspeak-dired-speak-line)))

(defadvice dired-flag-file-deletion (after emacspeak pre act )
  "Produce an auditory icon indicating that a file was marked for deletion."
  (when (ems-interactive-p  )
    (emacspeak-auditory-icon 'delete-object )
    (emacspeak-dired-speak-line )))

(loop for f in
      '(dired-unmark dired-unmark-backward)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Give speech feedback. Also provide an auditory icon."
          (when (ems-interactive-p )
            (emacspeak-auditory-icon 'deselect-object )
            (emacspeak-dired-speak-line)))))

;;}}}
;;{{{ Additional status speaking commands

(defcustom emacspeak-dired-file-cmd-options "-b"
  "Options passed to Unix builtin `file' command."
  :type '(choice
          (const :tag "Brief" "-b")
          (const :tag "Detailed" nil))
  :group 'emacspeak-dired)

(defun emacspeak-dired-show-file-type (&optional file deref-symlinks)
  "Displays type of current file by running command file.
Like Emacs' built-in dired-show-file-type but allows user to customize
options passed to command `file'."
  (interactive (list (dired-get-filename t) current-prefix-arg))
  (declare (special emacspeak-dired-file-cmd-options))
  (with-temp-buffer
    (if deref-symlinks
        (call-process "file" nil t t  "-l"
                      emacspeak-dired-file-cmd-options  file)
      (call-process "file" nil t t
		    emacspeak-dired-file-cmd-options file))
    (when (bolp)
      (backward-delete-char 1))
    (emacspeak-auditory-icon 'select-object)
    (let ((emacspeak-speak-messages t))
      (message (buffer-string)))))

(defun emacspeak-dired-speak-header-line()
  "Speak the header line of the dired buffer. "
  (interactive)
  (emacspeak-auditory-icon 'select-object)
  (save-excursion (goto-char (point-min))
                  (forward-line 2)
                  (emacspeak-speak-region (point-min) (point))))

(defun emacspeak-dired-speak-file-size ()
  "Speak the size of the current file.
On a directory line, run du -s on the directory to speak its size."
  (interactive)
  (dtk-stop)
  (let ((filename (dired-get-filename nil t))
        (size 0)
	(emacspeak-speak-messages t))
    (cond
     ((and filename
           (file-directory-p filename))
      (emacspeak-auditory-icon 'progress)
      (emacspeak-shell-command "du" "-s" filename ))
     (filename
      (setq size (nth 7 (file-attributes filename )))
                                        ; check for ange-ftp
      (when (= size -1)
        (setq size
              (nth  (if (= (char-after (line-beginning-position)) ?\ )
			4 5)
                    (split-string (thing-at-point 'line)))))
      (emacspeak-auditory-icon 'select-object)
      (message "File size %s"
               size))
     (t (message "No file on current line")))))

(defun emacspeak-dired-speak-file-modification-time ()
  "Speak modification time  of the current file."
  (interactive)
  (let ((filename (dired-get-filename nil t))
	(emacspeak-speak-messages t))
    (cond
     (filename
      (emacspeak-auditory-icon 'select-object)
      (message "Modified on : %s"
               (format-time-string
                emacspeak-speak-time-format-string
                (nth 5 (file-attributes filename )))))
     (t (message "No file on current line")))))

(defun emacspeak-dired-speak-file-access-time ()
  "Speak access time  of the current file."
  (interactive)
  (let ((filename (dired-get-filename nil t))
	(emacspeak-speak-messages t))
    (cond
     (filename
      (emacspeak-auditory-icon 'select-object)
      (message "Last accessed   on : %s"
               (format-time-string
                emacspeak-speak-time-format-string
                (nth 4 (file-attributes filename )))))
     (t (message "No file on current line")))))
(defun emacspeak-dired-speak-symlink-target ()
  "Speaks the target of the symlink on the current line."
  (interactive)
  (let ((filename (dired-get-filename nil t))
	(emacspeak-speak-messages t))
    (cond
     (filename
      (emacspeak-auditory-icon 'select-object)
      (cond
       ((file-symlink-p filename)
        (message "Target is %s"
                 (file-chase-links filename)))
       (t (message "%s is not a symbolic link" filename))))
     (t (message "No file on current line")))))
(defun emacspeak-dired-speak-file-permissions ()
  "Speak the permissions of the current file."
  (interactive)
  (let ((filename (dired-get-filename nil t))
	(emacspeak-speak-messages t))
    (cond
     (filename
      (emacspeak-auditory-icon 'select-object)
      (message "Permissions %s"
               (let ((permissions (nth 8 (file-attributes filename ))))
		 (if (string-match "^.[?]+$" permissions)
		     (nth  (if (= (char-after (line-beginning-position)) ?\ )
			       0 1)
			   (split-string (thing-at-point 'line)))
		   permissions))))
     (t (message "No file on current line")))))

(defun emacspeak-dired-speak-file-ownerships ()
  "Speak the ownerships of the current file."
  (interactive)
  (let ((filename (dired-get-filename nil t))
	(emacspeak-speak-messages t))
    (cond
     (filename
      (emacspeak-auditory-icon 'select-object)
      (message "Owned by %s/%s"
	       (nth (if (= (char-after (line-beginning-position)) ?\ )
			2 3)
		    (split-string (thing-at-point 'line)))
	       (nth (if (= (char-after (line-beginning-position)) ?\ )
			3 4)
		    (split-string (thing-at-point 'line)))))
     (t (message "No file on current line")))))

;;}}}
;;{{{  keys
(eval-when (load))

(defun emacspeak-dired-setup-keys ()
  "Add emacspeak keys to dired."
  (declare (special dired-mode-map ))
  (define-key dired-mode-map "E" 'emacspeak-dired-epub-eww)
  (define-key dired-mode-map (kbd "C-RET") 'emacspeak-dired-open-this-file)
  (define-key dired-mode-map [C-return] 'emacspeak-dired-open-this-file)
  (define-key dired-mode-map "'" 'emacspeak-dired-show-file-type)
  (define-key  dired-mode-map "/" 'emacspeak-dired-speak-file-permissions)
  (define-key  dired-mode-map "\M-/" 'emacspeak-dired-speak-file-ownerships)
  (define-key  dired-mode-map ";" 'emacspeak-dired-speak-header-line)
  (define-key  dired-mode-map "a" 'emacspeak-dired-speak-file-access-time)
  (define-key dired-mode-map "c" 'emacspeak-dired-speak-file-modification-time)
  (define-key dired-mode-map "z" 'emacspeak-dired-speak-file-size)
  (define-key dired-mode-map "\C-t" 'emacspeak-dired-speak-symlink-target)
  (define-key dired-mode-map "\C-i" 'emacspeak-speak-next-field)
  (define-key dired-mode-map  "," 'emacspeak-speak-previous-field))
(add-hook 'dired-mode-hook 'emacspeak-dired-initialize 'append)
(add-hook 'dired-mode-hook 'emacspeak-dired-setup-keys)

;;}}}
;;{{{ Advice locate:
(loop
 for f in
 '(locate locate-with-filter)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Provide auditory feedback."
     (when (ems-interactive-p)
       (emacspeak-speak-line)
       (emacspeak-auditory-icon 'open-object)))))
(load-library "locate")
(declaim (special locate-mode-map))
(define-key locate-mode-map  [C-return] 'emacspeak-dired-open-this-file)
;;}}}
;;{{{ Context-sensitive openers:

(defun emacspeak-dired-play-this-media ()
  "Plays media on current line."
  (funcall-interactively #'emacspeak-m-player (dired-get-filename)))

(defconst emacspeak-dired-opener-table
  `(("\\.epub$"  emacspeak-dired-epub-eww)
    ("\\.html" emacspeak-dired-eww-open )
    ("\\.htm" emacspeak-dired-eww-open )
    ("\\.pdf" emacspeak-dired-pdf-open)
    ("\\.csv" emacspeak-dired-csv-open)
    (,emacspeak-media-extensions emacspeak-dired-play-this-media))
  "Association of filename extension patterns to Emacspeak handlers.")

(defun emacspeak-dired-open-this-file  ()
  "Smart dired opener. Invokes appropriate Emacspeak handler on  current file in DirEd."
  (interactive)
  (let* ((f (dired-get-filename nil t))
         (ext (file-name-extension f))
         (handler nil))
    (unless f (error "No file here."))
    (unless ext (error "This entry has no extension."))
    (setq handler
          (second
           (find
            (format ".%s" ext)
            emacspeak-dired-opener-table
            :key #'car                  ; extract pattern from entry 
            :test #'(lambda (e pattern) (string-match  pattern e)))))
    (cond
     ((and handler (fboundp handler))
      (emacspeak-auditory-icon 'task-done)
      (funcall-interactively handler))
     (t (error  "No known handler")))))

(defun emacspeak-dired-eww-open ()
  "Open HTML file on current dired line."
  (interactive)
  (funcall-interactively #'eww-open-file (dired-get-filename)))

(defun emacspeak-dired-pdf-open ()
  "Open PDF file on current dired line."
  (interactive)
  (funcall-interactively #'emacspeak-wizards-pdf-open (dired-get-filename current-prefix-arg)))
(defun emacspeak-dired-epub-eww ()
  "Open epub on current line  in EWW"
  (interactive)
  (funcall-interactively #'emacspeak-epub-eww (shell-quote-argument(dired-get-filename)))
  (emacspeak-auditory-icon 'open-object))

(defun emacspeak-dired-csv-open ()
  "Open CSV file on current dired line."
  (interactive)
  (funcall-interactively #'emacspeak-table-find-csv-file (dired-get-filename current-prefix-arg)))


;;}}}

(provide 'emacspeak-dired)
;;{{{ emacs local variables

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: nil
;;; end:

;;}}}
