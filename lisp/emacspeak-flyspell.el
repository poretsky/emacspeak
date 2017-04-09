;;; emacspeak-ispell.el --- Speech enable Ispell -- Emacs' interactive spell checker  -*- lexical-binding: t; -*-
;;; $Id$
;;; $Author: tv.raman.tv $ 
;;; Description:  Emacspeak extension to speech enable flyspell
;;; Keywords: Emacspeak, Ispell, Spoken Output, fly spell checking
;;{{{  LCD Archive entry: 

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu 
;;; A speech interface to Emacs |
;;; $Date: 2007-08-25 18:28:19 -0700 (Sat, 25 Aug 2007) $ |
;;;  $Revision: 4532 $ | 
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:
;;;Copyright (C) 1995 -- 2015, T. V. Raman 
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

;;{{{  Introduction:

;;; Commentary:

;;; This module speech enables flyspell.
;;; it loads flyspell-correct if available,
;;; And when loading flyspell-correct sets up that module
;;; to use  ido-style corrections.
;;; Another alternative is to use flyspell-correct-popup ---
;;; Use Customization emacspeak-flyspell-correct-interface to pick between ido and popup.


;;; Code:

;;}}}
;;{{{ Requires

(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)
(require 'flyspell "flyspell" 'no-error)

;;}}}
;;{{{  define personalities

(defgroup emacspeak-flyspell nil
  "Emacspeak support for on the fly spell checking."
  :group 'emacspeak
  :group 'flyspell
  :prefix "emacspeak-flyspell-")

(voice-setup-add-map
 '(
   (flyspell-incorrect voice-bolden)
   (flyspell-duplicate voice-monotone)))

;;}}}
;;{{{ advice

(declaim (special flyspell-delayed-commands))
(when (fboundp 'emacspeak-self-insert-command)
  (push 'emacspeak-self-insert-command flyspell-delayed-commands))

(defadvice flyspell-auto-correct-word (around emacspeak pre act comp)
  "Speak the correction we inserted"
  (cond
   ((ems-interactive-p)
    (ems-with-messages-silenced
     ad-do-it
     (dtk-speak (car  (flyspell-get-word nil)))
     (when (sit-for 1) (emacspeak-speak-message-again))
     (emacspeak-auditory-icon 'select-object)))
   (t ad-do-it))
  ad-return-value)

(defadvice flyspell-unhighlight-at (before debug pre act comp)
  (let ((overlay-list (overlays-at pos))
        (o nil))
    (while overlay-list 
      (setq o (car overlay-list))
      (when (flyspell-overlay-p o)
        (put-text-property (overlay-start o)
                           (overlay-end o)
                           'personality  nil))
      (setq overlay-list (cdr overlay-list)))))

;;}}}
;;{{{ use flyspell-correct if available:

(defcustom emacspeak-flyspell-correct  
  (cond
   ((locate-library "flyspell-correct-popup") 'flyspell-correct-popup)
   ((locate-library "flyspell-correct-ido") 'flyspell-correct-ido)
   (t nil))
  "Correction style to use with flyspell."
  :type 'symbol)
   
;;; flyspell-correct is available on melpa:

(when (locate-library "flyspell-correct")
  (define-key flyspell-mode-map (kbd "C-;") 'flyspell-correct-previous-word-generic)
  (require emacspeak-flyspell-correct))

(cl-loop
 for f in
 '(flyspell-correct-word-generic flyspell-correct-previous-word-generic)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
    "Speak word."
    (when (ems-interactive-p)
      (dtk-speak (car (flyspell-get-word nil)) )))))

;;}}}
(provide 'emacspeak-flyspell)
;;{{{  emacs local variables 

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: nil
;;; end: 

;;}}}
