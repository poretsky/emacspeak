;;; emacspeak-transmission.el --- speech-enable Transmission interface  -*- lexical-binding: t; -*-
;;; Description:  Emacspeak extension to speech-enable Transmission torrent client
;;; Keywords: Emacspeak, torrent, comm, download, magnet link
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
;;{{{  Introduction:

;;; Commentary:

;;; This module speech-enables transmission-el package that
;;; provides Emacs interface to a Transmission session.

;;}}}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Code:

;;{{{ required modules

(require 'emacspeak-preamble)

;;}}}
;;{{{ advice:

(cl-loop
 for f in
 '(transmission
   transmission-files
   transmission-find-file
   transmission-find-file-other-window
   transmission-display-file
   transmission-info
   transmission-peers)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "provide auditory feedback."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'open-object)
       (emacspeak-speak-mode-line)))))

(cl-loop
 for f in
 '(transmission-files-want
   transmission-copy-filename-as-kill
   transmission-copy-magnet
   transmission-toggle-mark)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "produce auditory icon."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'mark-object)))))

(cl-loop
 for f in
 '(transmission-files-unwant
   transmission-unmark-all)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "produce auditory icon."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'deselect-object)))))

(defadvice transmission-quit (after emacspeak pre act comp)
  "provide auditory confirmation."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (emacspeak-speak-mode-line)))

;;}}}
(provide 'emacspeak-transmission)
;;{{{ end of file 

;;; local variables:
;;; folded-file: t
;;; end: 

;;}}}
