;;; emacspeak-facemenu.el --- Map default Emacs faces like bold to appropriate speech personalities 
;;; $Id: emacspeak-facemenu.el,v 17.0 2002/11/23 01:28:59 raman Exp $
;;; $Author: raman $ 
;;; Description: Emacspeak module to map standard faces to voices
;;; Keywords:emacspeak, audio interface to emacs rich text
;;{{{  LCD Archive entry: 

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu
;;; A speech interface to Emacs |
;;; $Date: 2002/11/23 01:28:59 $ |
;;;  $Revision: 17.0 $ | 
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:
;;;Copyright (C) 1995 -- 2002, T. V. Raman 
;;; Copyright (c) 1995 by T. V. Raman  
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

(eval-when-compile (require 'cl))
(declaim  (optimize  (safety 0) (speed 3)))
(require 'dtk-css-speech)
(require 'emacspeak-sounds)
(require 'emacspeak-speak)
;;{{{  Introduction

;;; Map standard faces such as bold and italic to voices.

;;}}}
;;{{{  advice interactive commands
(defadvice facemenu-set-face (after emacspeak pre act comp)
  "Apply voice properties as well."
  (when  mark-active
    (put-text-property
     (or (ad-get-arg 1) (region-beginning))
     (or (ad-get-arg 2) (region-end))
     'personality
     (ad-get-arg 0))
    (emacspeak-speak-line)))

(defadvice facemenu-remove-all (after emacspeak pre act comp)
  "Provide auditory feedback"
  (when (interactive-p)
    (emacspeak-auditory-icon 'button)
    (message "Removed all text properties from region")))

;;}}}
;;{{{  customize keybindings

(define-key global-map "\M-G" 'facemenu-keymap)

;;}}}
(provide  'emacspeak-facemenu)
;;{{{  emacs local variables 

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end: 

;;}}}
