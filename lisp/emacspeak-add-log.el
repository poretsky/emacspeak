;;; emacspeak-add-log.el --- Speech-enable add-log
;;; $Id: emacspeak-add-log.el 4151 2006-08-30 00:44:57Z tv.raman.tv $
;;; $Author: tv.raman.tv $
;;; Description:  speech-enable change-log-mode
;;; Keywords: Emacspeak,  Audio Desktop ChangeLogs
;;{{{  LCD Archive entry:

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu
;;; A speech interface to Emacs |
;;; $Date: 2006-08-29 17:44:57 -0700 (Tue, 29 Aug 2006) $ |
;;;  $Revision: 4151 $ |
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:
;;;Copyright (C) 1995 -- 2006, T. V. Raman 
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

;;{{{  introduction
;;; Commentary:

;;; speech-enables change-log-mode 
;;;Code:

;;}}}
;;{{{  Required modules

(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(require 'custom)
(require 'browse-url)
(require 'emacspeak-preamble)
(eval-when-compile
  (condition-case nil
      (require 'emacspeak-w3)
    (error nil)))

;;}}}
;;{{{ define personalities

(defgroup emacspeak-add-log nil
  "Customize Emacspeak for change-log-mode and friends."
  :group 'emacspeak)

(voice-setup-add-map
 '(
   (change-log-acknowledgement voice-smoothen)
   (change-log-conditionals voice-animate)
   (change-log-email voice-womanize-1)
   (change-log-function voice-bolden-extra)
   (change-log-file voice-bolden)
   (change-log-email voice-womanize-1)
   (change-log-list voice-lighten)
   (change-log-name voice-lighten-extra)
   ))

;;}}}

(provide 'emacspeak-add-log)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
