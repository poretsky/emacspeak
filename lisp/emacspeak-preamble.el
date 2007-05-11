;;; emacspeak-preamble.el --- standard  include for Emacspeak modules
;;; $Id: emacspeak-preamble.el 4151 2006-08-30 00:44:57Z tv.raman.tv $
;;; $Author: tv.raman.tv $ 
;;; Description: Standard include for various Emacspeak modules
;;; Keywords: emacspeak, standard include
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
;;{{{ Required modules 

(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(require 'advice)
(require 'backquote)
(require 'custom)
(require 'widget)
(require 'wid-edit)
(require 'thingatpt)
(require 'emacspeak-load-path)
(require 'voice-setup)
(require 'dtk-speak)
(require 'emacspeak-pronounce)
(require 'emacspeak-speak)
(require 'emacspeak-keymap)
;;}}}
;;{{{ Utilities:
(defsubst emacspeak-url-encode (str)
  "URL encode string."
  (mapconcat '(lambda (c)
                (cond ((= c 32) "+")
                      ((or (and (>= c ?a) (<= c ?z))
                           (and (>= c ?A) (<= c ?Z))
                           (and (>= c ?0) (<= c ?9)))
                       (char-to-string c))
                      (t (upcase (format "%%%02x" c)))))
             str
             ""))
;;}}}
(provide  'emacspeak-preamble)
;;{{{  emacs local variables 

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end: 

;;}}}
