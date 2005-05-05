;;; emacspeak-generic.el --- Speech enable  generic modes
;;; $Id: emacspeak-generic.el,v 22.0 2005/04/30 16:39:57 raman Exp $
;;; $Author: raman $
;;; Description:   extension to speech enable generic 
;;; Keywords: Emacspeak, Audio Desktop
;;{{{  LCD Archive entry:

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu
;;; A speech interface to Emacs |
;;; $Date: 2005/04/30 16:39:57 $ |
;;;  $Revision: 22.0 $ |
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:

;;; Copyright (C) 1995 -- 2004, T. V. Raman<raman@cs.cornell.edu>
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

;;{{{ required modules

(require 'emacspeak-preamble)
;;}}}
;;{{{  Introduction:

;;; Commentary:

;;; This module speech-enables generic.el so that modes
;;; defined using  define-generic-mode get voice locking
;;; support. Examples include apache-generic-mode and
;;; friends defined in generic-x.el

;;; Code:

;;}}}
;;{{{ voice locking 

;;}}}
;;{{{  generic setup 

(defadvice define-generic-mode (after emacspeak pre act comp)
  "Advice generated mode command to setup emacspeak extensions. "
  (let ((name (ad-get-arg 0)))
    (eval
     `(defadvice  ,name (after emacspeak pre act comp)
	"Setup Emacspeak programming mode hooks."
	(emacspeak-setup-programming-mode)))))

;;}}}
(provide 'emacspeak-generic)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
