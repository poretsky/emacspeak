;;; emacspeak-gud.el --- Speech enable Emacs' debugger interface --covers GDB, JDB, and PerlDB
;;; $Id: emacspeak-gud.el,v 21.0 2004/11/25 18:45:47 raman Exp $
;;; $Author: raman $ 
;;; DescriptionEmacspeak extensions for gud interaction 
;;; Keywords:emacspeak, audio interface to emacs debuggers 
;;{{{  LCD Archive entry: 

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu 
;;; A speech interface to Emacs |
;;; $Date: 2004/11/25 18:45:47 $ |
;;;  $Revision: 21.0 $ | 
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:
;;;Copyright (C) 1995 -- 2004, T. V. Raman 
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

;;{{{  Introduction:

;;; Provide additional advice to ease debugger interaction with gud 

;;}}}
;;{{{ requires
(require 'emacspeak-preamble)

;;}}}
;;{{{  Advise key helpers:

(defadvice gud-display-line (after emacspeak pre act )
  "Speak the error line"
  (let ((marker overlay-arrow-position ))
    (emacspeak-auditory-icon 'large-movement)
    (and marker
         (marker-buffer marker )
         (marker-position marker )
         (save-excursion
           (set-buffer (marker-buffer marker ))
           (goto-char (marker-position marker ))
           (emacspeak-speak-line )))))

;;}}}
;;{{{ Advise interactive commands:

;;}}}
(provide  'emacspeak-gud)
;;{{{  emacs local variables 

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end: 

;;}}}
