;;; emacspeak-tar.el --- Speech enable Tar Mode -- Manipulate tar archives from Emacs
;;; $Id: emacspeak-tar.el 7823 2012-06-03 01:16:29Z tv.raman.tv $
;;; $Author: tv.raman.tv $ 
;;; Description: Auditory interface to tar mode
;;; Keywords: Emacspeak, Speak, Spoken Output, tar
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

;;; Copyright (c) 1995 -- 2011, T. V. Raman
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

;;{{{  Required modules

(require 'emacspeak-preamble)
(require 'tar-mode)
;;}}}
;;{{{  Introduction 

;;;Auditory interface to tar mode

;;}}}
;;{{{ Helpers

(unless (fboundp 'tar-desc-tokens)
  (defun tar-desc-tokens (x) x))

(defun emacspeak-tar-speak-line ()
  "Speak line in tar mode intelligently"
  (cond
   ((= (following-char) 0)
    (emacspeak-speak-line))
   (t
    (dtk-speak (tar-header-name
		(tar-desc-tokens (tar-current-descriptor)))))))

;;}}}
;;{{{ Advice
(defadvice tar-quit (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'close-object)
    (emacspeak-speak-mode-line)))

(defadvice deb-view-dired-view-cleanup (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (emacspeak-speak-mode-line)))

(defadvice tar-next-line (before emacspeak pre act com)
  "Produce auditory icon  if we cant move."
  (when (and (ems-interactive-p)
             (save-excursion
               (end-of-line)
               (eobp)))
    (emacspeak-auditory-icon 'warn-user)))

(defadvice tar-previous-line (before emacspeak pre act com)
  "Produce auditory icon  if we cant move."
  (when (and (ems-interactive-p)
             (save-excursion
               (beginning-of-line)
               (bobp)))
    (emacspeak-auditory-icon 'warn-user)))

(defadvice tar-next-line (after emacspeak pre act comp)
  "Provide spoken feedback"
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-tar-speak-line)))

(defadvice tar-previous-line (after emacspeak pre act comp)
  "Provide spoken feedback"
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-tar-speak-line)))

(defadvice tar-flag-deleted (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'delete-object)
    (emacspeak-tar-speak-line)))

(defadvice tar-unflag (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'deselect-object)
    (emacspeak-tar-speak-line)))

(defadvice tar-unflag-backwards (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'deselect-object)
    (emacspeak-tar-speak-line)))

(defadvice tar-extract (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-mode-line)))

(defadvice tar-extract-other-window (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-mode-line)))

(defadvice tar-view (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-mode-line)))

;;}}}
;;{{{ additional interactive commands

(defun emacspeak-tar-speak-file-permissions()
  "Speak permissions of file current entry "
  (interactive)
  (declare (special emacspeak-speak-messages))
  (unless (or (eq major-mode 'tar-mode)
	      (eq major-mode 'debview-mode))
    (error "This command should be called only in tar mode"))
  (let ((entry (tar-current-descriptor))
        (mode nil)
        (string "          ")
	(emacspeak-speak-messages t))
    (cond
     ((null entry)
      (message "No file on this line"))
     (t
      (emacspeak-auditory-icon 'select-object)
      (setq mode
            (tar-header-mode (tar-desc-tokens entry)))
      (aset string 0       (if (zerop (logand 256 mode)) ?- ?r))
      (aset string   1 (if (zerop (logand 128 mode)) ?- ?w))
      (aset string  2 (if (zerop (logand  64 mode)) ?- ?x)) 
      (aset string  3 (if (zerop (logand  32 mode)) ?- ?r))
      (aset string  4 (if (zerop (logand  16 mode)) ?- ?w))
      (aset string  5 (if (zerop (logand   8 mode)) ?- ?x))
      (aset string  6 (if (zerop (logand   4 mode)) ?- ?r))
      (aset string  7 (if (zerop (logand   2 mode)) ?- ?w))
      (aset string  8 (if (zerop (logand   1 mode)) ?- ?x))
      (if (zerop (logand 1024 mode)) nil (aset string  2 ?s))
      (if (zerop (logand 2048 mode)) nil (aset string  5 ?s))
      (message  "Permissions  %s "
                string)))))

(defun emacspeak-tar-speak-file-ownerships()
  "Speak ownerships of file current entry "
  (interactive)
  (declare (special emacspeak-speak-messages))
  (unless (or (eq major-mode 'tar-mode)
	      (eq major-mode 'debview-mode))
    (error "This command should be called only in tar mode"))
  (let ((entry (tar-current-descriptor))
	(emacspeak-speak-messages t))
    (cond
     ((null entry)
      (message "No file on this line"))
     (t (emacspeak-auditory-icon 'select-object)
	(message  "Owned by %s/%s "
                  (tar-header-uname (tar-desc-tokens
				     entry))
		  (tar-header-gname (tar-desc-tokens
				     entry)))))))

(defun emacspeak-tar-speak-file-size()
  "Speak size of file current entry "
  (interactive)
  (declare (special emacspeak-speak-messages))
  (unless (or (eq major-mode 'tar-mode)
	      (eq major-mode 'debview-mode))
    (error "This command should be called only in tar mode"))
  (let ((entry (tar-current-descriptor))
	(emacspeak-speak-messages t))
    (cond
     ((null entry)
      (message "No file on this line"))
     (t (emacspeak-auditory-icon 'select-object)
	(message  "File size %s "
                  (tar-header-size (tar-desc-tokens
                                    entry)))))))

(defun emacspeak-tar-speak-file-date()
  "Speak date of file current entry "
  (interactive)
  (declare (special emacspeak-speak-time-format-string
		    emacspeak-speak-messages))
  (unless (or (eq major-mode 'tar-mode)
	      (eq major-mode 'debview-mode))
    (error "This command should be called only in tar mode"))
  (let ((entry (tar-current-descriptor))
	(emacspeak-speak-messages t))
    (cond
     ((null entry)
      (message "No file on this line"))
     (t (emacspeak-auditory-icon 'select-object)
	(message  "Modified on: %s "
                  (format-time-string
                   emacspeak-speak-time-format-string
                   (tar-header-date
                    (tar-desc-tokens entry))))))))

(defun emacspeak-tar-setup-keys ()
  "Setup emacspeak keys for tar mode"
  (declare (special tar-mode-map))
  (define-key tar-mode-map "z" 'emacspeak-tar-speak-file-size)       
  (define-key tar-mode-map "/" 'emacspeak-tar-speak-file-permissions)
  (define-key tar-mode-map "\M-/" 'emacspeak-tar-speak-file-ownerships)
  (define-key tar-mode-map "c" 'emacspeak-tar-speak-file-date)
  )

(eval-when (load)
  (emacspeak-tar-setup-keys))

;;}}}
(provide 'emacspeak-tar)
;;{{{ end of file 

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end: 

;;}}}
