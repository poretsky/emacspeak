;;; emacspeak-load-path.el -- Setup Emacs load-path for compiling Emacspeak
;;; $Id: emacspeak-load-path.el,v 23.505 2005/11/25 16:30:50 raman Exp $
;;; $Author: raman $ 
;;; Description:  Sets up load-path for emacspeak compilation and installation
;;; Keywords: Emacspeak, Speech extension for Emacs
;;{{{  LCD Archive entry: 
;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu 
;;; A speech interface to Emacs |
;;; $Date: 2005/11/25 16:30:50 $ |
;;;  $Revision: 23.505 $ | 
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:
;;;Copyright (C) 1995 -- 2004, T. V. Raman 
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
(defvar emacspeak-directory
  (expand-file-name "../" (file-name-directory load-file-name))
  "Directory where emacspeak is installed. ")

(defvar emacspeak-lisp-directory
  (expand-file-name "lisp/" emacspeak-directory)
  "Directory containing lisp files for  Emacspeak.")  

(or (member emacspeak-lisp-directory load-path )
    (setq load-path
	  (cons emacspeak-lisp-directory 
		load-path )))

(defvar emacspeak-resource-directory (expand-file-name "~/.emacspeak")
  "Directory where Emacspeak resource files such as pronunciation dictionaries are stored. ")

(setq byte-compile-warnings
      '(redefine callargs free-vars
                 unresolved obsolete))

(provide 'emacspeak-load-path)
