;;; emacspeak-mspools.el --- Speech enable MSpools -- Monitor multiple mail drops
;;; $Id: emacspeak-mspools.el,v 17.0 2002/11/23 01:29:00 raman Exp $
;;; $Author: raman $ 
;;; Description: Auditory interface to mail spool tracker
;;; Keywords: Emacspeak, Speak, Spoken Output, mspools
;;{{{  LCD Archive entry: 

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu 
;;; A speech interface to Emacs |
;;; $Date: 2002/11/23 01:29:00 $ |
;;;  $Revision: 17.0 $ | 
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:

;;; Copyright (c) 1995 -- 2002, T. V. Raman
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

(eval-when-compile (require 'cl))
(declaim  (optimize  (safety 0) (speed 3)))
(eval-when (compile)
  (require 'emacspeak-speak)
  (require 'voice-lock)
  (require 'emacspeak-keymap)
  (require 'emacspeak-sounds))

(eval-when (compile)
  (require 'emacspeak-fix-interactive))

;;}}}
;;{{{  Introduction

;;; Speech mspools --a package that lets you monitor
;;; multiple maildrops

;;}}}
;;{{{ advice

(defadvice mspools-show (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-mode-line)))
(defadvice mspools-quit (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (emacspeak-speak-mode-line)))

(defadvice mspools-revert-buffer (after emacspeak pre act comp)
  "Provide auditory feedback"
  (emacspeak-auditory-icon 'select-object)
  (emacspeak-speak-line))
;;}}}
;;{{{ keymaps
(declaim (special mspools-mode-map))
(eval-when (load)
  (require 'emacspeak-keymap)
  (emacspeak-keymap-remove-emacspeak-edit-commands mspools-mode-map))

;;}}}
(provide 'emacspeak-mspools)

;;{{{ end of file 

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end: 

;;}}}
