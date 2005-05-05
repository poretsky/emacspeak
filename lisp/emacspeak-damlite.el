;;; emacspeak-damlite.el --- Speech-enable damlite
;;; $Id: emacspeak-damlite.el,v 22.0 2005/04/30 16:39:52 raman Exp $
;;; $Author: raman $
;;; Description:  Emacspeak front-end for daml  authoring mode 
;;; Keywords: Emacspeak, damlite 
;;{{{  LCD Archive entry:

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu
;;; A speech interface to Emacs |
;;; $Date: 2005/04/30 16:39:52 $ |
;;;  $Revision: 22.0 $ |
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

;;; Speech-enables package damlite --
;;; daml mode is used to author and maintain daml ontologies
;;; using RDF

;;}}}
;;{{{ required modules

;;; Code:
(require 'emacspeak-preamble)
;;}}}
;;{{{ define personalities 
(def-voice-font emacspeak-daml-class-face voice-lock-type-personality
  'daml-class-face
  "Personality used for DAML classes.")

(def-voice-font emacspeak-daml-class-ref-face
  voice-lighten
  'daml-class-ref-face
  "Personality used for class references.")

(def-voice-font emacspeak-daml-comment-face
  voice-lock-comment-personality
  'daml-comment-face
  "Personality used for DAML comments.")

(def-voice-font emacspeak-daml-keyword-face
  voice-lock-keyword-personality
  'daml-keyword-face
  "Personality for keywords in DAML.")

(def-voice-font emacspeak-daml-normal-face
  'paul
  'daml-normal-face
  "Normal face in DAML.")

(def-voice-font emacspeak-daml-other-face
  'voice-bolden-extra
  'daml-other-face
  "Personality for other elements in DAML.")

(def-voice-font emacspeak-daml-property-face
  voice-animate
  'daml-property-face
  "personality for DAML properties.")

(def-voice-font emacspeak-daml-property-ref-face
  voice-animate-extra
  'daml-property-ref-face
  "Personality for DAML property references.")

(def-voice-font emacspeak-daml-string-face
  voice-lock-string-personality
  'daml-string-face
  "Personality for DAML strings.")

(def-voice-font emacspeak-daml-substitution-face
  voice-smoothen
  'daml-substitution-face
  "Personality for substitutions in DAML.")

(def-voice-font emacspeak-daml-tag-face
  voice-bolden
  'daml-tag-face
  "Personality for tags in DAML.")
;;}}}
(provide 'emacspeak-damlite)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
