;;; emacspeak-sigbegone.el --- Speech-enable sigbegone
;;; $Id: emacspeak-sigbegone.el,v 20.0 2004/05/01 01:16:23 raman Exp $
;;; $Author: raman $
;;; Description:  Emacspeak module for SIGBEGONE --signature exorciser 
;;; Keywords: Emacspeak, sigbegone 
;;{{{  LCD Archive entry:

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu
;;; A speech interface to Emacs |
;;; $Date: 2004/05/01 01:16:23 $ |
;;;  $Revision: 20.0 $ |
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:

;;; Copyright (C) 1999 T. V. Raman <raman@cs.cornell.edu>
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

;;; Commentary:
;;{{{  Introduction:

;;; Speech-enables package sigbegone --voiceify sigs in email and news

;;}}}
;;{{{ required modules

;;; Code:
(require 'emacspeak-preamble)
;;}}}
;;{{{ define personalities 
(def-voice-font emacspeak-sigbegone-exorcized-personality
  voice-smoothen-extra
  'sigbegone-exorcized-face
  "Personality for signatures.")

;;}}}
(provide 'emacspeak-sigbegone)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
