;;; emacspeak-entertain.el --- Speech enable misc games
;;; $Id: emacspeak-entertain.el,v 16.0 2002/05/03 23:31:23 raman Exp $
;;; $Author: raman $ 
;;; Description: Auditory interface to diversions
;;; Keywords: Emacspeak, Speak, Spoken Output, games
;;{{{  LCD Archive entry: 

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu 
;;; A speech interface to Emacs |
;;; $Date: 2002/05/03 23:31:23 $ |
;;;  $Revision: 16.0 $ | 
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:

;;; Copyright (c) 1995 -- 2002, T. V. Raman
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

;;{{{  Required modules

(eval-when-compile (require 'cl))
(declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-speak)
(require 'emacspeak-pronounce)
(require 'emacspeak-sounds)
(eval-when (compile)
  (condition-case nil
      (require 'tetris)
    (error nil)))

;;}}}
;;{{{  Introduction 

;;; Commentary:

;;; Auditory interface to misc games

;;}}}
            
;;{{{ doctar

(defadvice doctor-txtype (after emacspeak pre act )
  (dtk-speak
   (mapconcat
    (function (lambda (s)
                (format "%s" s)))
    (ad-get-arg 0 )
    " ")))

;;}}}
;;{{{ mpuz

(declaim (special mpuz-silent ))
(setq mpuz-silent t )
(defadvice mpuz-correct-guess (after emacspeak pre act )
               "Provide an auditory icon"
               (emacspeak-auditory-icon 'search-hit ))

(defadvice mpuz-congratulate (after emacspeak pre act )
               "Produce auditory icon"
               (emacspeak-auditory-icon 'alarm ))

;;}}}
;;{{{ dunnet 

(defadvice dun-parse (around emacspeak pre act comp)
  "Provide auditory feedback"
  (cond
   ((interactive-p)
    (let ((orig (point)))
      ad-do-it
      (emacspeak-auditory-icon 'mark-object)
      (emacspeak-speak-region orig (point))))
   (t ad-do-it))
  ad-return-value)

;;}}}
;;{{{  hangman 

(defun emacspeak-hangman-speak-statistics ()
  "Speak statistics."
  (interactive)
  (declare (special hm-win-statistics))
  (message "         Games won: %d    Games Lost: %d"
           (aref hm-win-statistics 0)
           (aref hm-win-statistics 1)))

(defun emacspeak-hangman-setup-pronunciations ()
  "Setup pronunciation dictionaries."
  (declare (special emacspeak-pronounce-pronunciation-table))
(emacspeak-pronounce-add-dictionary-entry 'hm-mode "_" ".")
(when (or (not (boundp 'emacspeak-pronounce-pronunciation-table))
            (not emacspeak-pronounce-pronunciation-table))
    (emacspeak-pronounce-toggle-use-of-dictionaries)))

(defadvice hm-self-guess-char (after eemacspeak pre act comp)
  "Speak the char."
  (when (interactive-p)
    (emacspeak-auditory-icon 'select-object)))

(defun emacspeak-hangman-speak-guess ()
  "Speak current guessed string. "
  (interactive)
  (declare (special hm-current-guess-string
                    hm-current-word))
  (let ((string (make-string  (length hm-current-word)
                              ?\))))
    (loop for i from 0 to (1- (length hm-current-word))
          do
          (aset  string  i
                 (aref hm-current-guess-string (* i 2 ))))
     (message  "%s:  %s "
             (length string)
             (downcase string))))

(defadvice hangman (after emacseak pre act comp)
  "Speech enable hangman."
  (when (interactive-p)
    (emacspeak-hangman-setup-pronunciations)
    (emacspeak-auditory-icon 'open-object)))
(declaim (special hm-map))
(when (boundp 'hm-map)
(declaim (special hm-map))
(define-key hm-map " " 'emacspeak-hangman-speak-guess)
(define-key hm-map "=" 'emacspeak-hangman-speak-statistics)
)

;;}}}
(provide 'emacspeak-entertain)
;;{{{ end of file 

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end: 

;;}}}
