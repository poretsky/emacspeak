;;; emacspeak-asm.el --- Speech enable Asm Mode  -*- lexical-binding: t; -*-
;;; Author: Igor B. Poretsky <poretsky@mlbox.ru>
;;; Description: Emacspeak extensions for asm-mode
;;; Keywords: emacspeak, audio interface to emacs asm mode
;;{{{  LCD Archive entry: 

;;}}}
;;{{{  Copyright:
;;;Copyright (C) 2005, Igor B. Poretsky <poretsky@mlbox.ru>
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

;;; Provide additional advice to asm-mode 

;;}}}
;;{{{ requires
(require 'emacspeak-preamble)

;;}}}
;;{{{  Advice interactive functions:

(defadvice asm-newline (around emacspeak pre act comp)
  "Speak the previous line if line echo is on.
See command \\[emacspeak-toggle-line-echo].
Otherwise cue user to the line just created."
  (cl-declare (special emacspeak-line-echo ))
  (cond
   ((ems-interactive-p)
    (cond
     (emacspeak-line-echo
      (emacspeak-speak-line )
      ad-do-it)
     (t ad-do-it
        (dtk-speak-using-voice voice-annotate
                               (format
                                "indent %s"
                                (current-column)))
        (dtk-force))))
   (t ad-do-it))
  ad-return-value)

(cl-loop for f in
      '(asm-colon asm-comment)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
	  "Provide speech feedback"
	  (when (ems-interactive-p)
	    (emacspeak-speak-line)))))

;;}}}

(provide  'emacspeak-asm)
;;{{{  emacs local variables 

;;; local variables:
;;; folded-file: t
;;; end: 

;;}}}
