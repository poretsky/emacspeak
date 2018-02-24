;;; emacspeak-package.el --- Speech-enable PACKAGE
;;; $Id: emacspeak-package.el 4797 2007-07-16 23:31:22Z tv.raman.tv $
;;; $Author: tv.raman.tv $
;;; Description:  Speech-enable PACKAGE An Emacs Interface to package
;;; Keywords: Emacspeak,  Audio Desktop package
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
;;; MERCHANTABILITY or FITNPACKAGE FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Emacs; see the file COPYING.  If not, write to
;;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;}}}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;{{{  introduction

;;; Commentary:
;;; PACKAGE == package.el
;;; Manage Emacs packages.
;;; This module speech-enables package.el with a few convenience commands.

;;}}}
;;{{{  Required modules

(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)
(eval-when-compile
  (require 'package "package" 'no-error))

;;}}}
;;{{{ Additional Commands 

(defun emacspeak-package-summarize-line ()
  "Succinct Summary."
  (interactive)
  (let* ((entry   (get-text-property (point) 'tabulated-list-entry))
         (name (copy-sequence (first (aref entry 0))))
         (desc (aref entry 4))
         (state (aref entry 2)))
    (cond
     ((string= state "installed")
      (emacspeak-auditory-icon 'select-object))
     ((string= state "built-in")
      (emacspeak-auditory-icon 'mark-object))
     ((string= state "dependency")
      (emacspeak-auditory-icon 'close-object))
     ((string= state "obsolete")
      (emacspeak-auditory-icon 'deselect-object))
     ((string= state "incompat")
      (emacspeak-auditory-icon 'warn-user))
     (t (emacspeak-auditory-icon 'item)))
    (put-text-property 0 (length name)
                       'personality voice-bolden-medium name)
    (dtk-speak-and-echo  (concat name ": "desc))))

(defun emacspeak-package-next-line ()
  "Move to next line and speak it."
  (interactive)
  (next-line)
  (emacspeak-package-summarize-line))

(defun emacspeak-package-previous-line ()
  "Move to next line and speak it."
  (interactive)
  (previous-line)
  (emacspeak-package-summarize-line))

(defun emacspeak-package-mode-hook ()
  "Emacspeak setup hook for package-mode."
  (define-key package-menu-mode-map " " 'emacspeak-package-summarize-line)
  (define-key package-menu-mode-map "n" 'emacspeak-package-next-line)
  (define-key package-menu-mode-map "p" 'emacspeak-package-previous-line)
  (emacspeak-pronounce-add-buffer-local-dictionary-entry
   emacspeak-pronounce-date-yyyymmdd-pattern
   (cons 're-search-forward 'emacspeak-pronounce-yyyymmdd-date)))

(add-hook 'package-menu-mode-hook 'emacspeak-package-mode-hook)

;;}}}
;;{{{ Managing packages:

(defadvice package-menu-execute(around emacspeak pre act comp)
  "Silence messages while installing packages. "
  (ems-with-messages-silenced ad-do-it))

(defadvice package-menu--perform-transaction (around emacspeak pre act comp)
  "Silence messages."
  (ems-with-messages-silenced ad-do-it))

;;}}}
(provide 'emacspeak-package)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
