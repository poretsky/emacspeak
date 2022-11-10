;;; emacspeak-debian-bug.el --- speech-enable Debian bug reports  -*- lexical-binding: t; -*-
;;; Description:  Emacspeak extension to speech-enable bug reporting to the Debian bug tracking system
;;; Keywords: Emacspeak, apt, Debian bug tracking system
;;{{{  LCD Archive entry:

;;}}}
;;{{{  Copyright:

;;; Initial version: Author: Igor B. Poretsky <poretsky@mlbox.ru>
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

;;{{{  Introduction:

;;; Commentary:

;;; This module speech-enables debian-bug.el
;;; that is included in the debian-el package
;;; and provides convenient way to generate and submit bug reports
;;; to the Debian bug tracking system.
;;; Code:

;;}}}
;;{{{ required modules

(require 'emacspeak-preamble)

;;}}}
;;{{{ Advice interactive commands to speak.

(defadvice debian-bug (around emacspeak pre act comp)
  "Provide speech feedback."
  (let ((emacspeak-speak-messages t))
    ad-do-it))

;;}}}
(provide 'emacspeak-debian-bug)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; end:

;;}}}
