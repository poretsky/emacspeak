;;; emacspeak-perl.el --- Speech enable Perl Mode  -*- lexical-binding: t; -*- 
;;; $Id$
;;; $Author: tv.raman.tv $ 
;;; Description: Emacspeak extensions for perl-mode
;;; Keywords: emacspeak, audio interface to emacs perl
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
;;;Copyright (C) 1995 -- 2017, T. V. Raman 
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

;;{{{  Introduction:
;;; Commentary:
;;; Provide additional advice to perl-mode 
;;; Code:
;;}}}
;;{{{ requires
(require 'emacspeak-preamble)

;;}}}
;;{{{  Advice electric insertion to talk:

(unless (and (boundp 'post-self-insert-hook)
             post-self-insert-hook
             (memq 'emacspeak-post-self-insert-hook post-self-insert-hook))
  (cl-loop for f in
        '(electric-perl-terminator perl-electric-terminator)
        do
        (eval
         `(defadvice ,f  (after emacspeak pre act comp )
            "Speak what you inserted."
            (when (ems-interactive-p)
              (emacspeak-speak-this-char last-input-event))))))

;;}}}
;;{{{  Program structure:

(cl-loop for f in
      '(mark-perl-function perl-mark-function)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Provide auditory feedback"
          (when (ems-interactive-p)
            (emacspeak-auditory-icon 'mark-object)
            (message "Marked procedure")))))

(defadvice perl-beginning-of-function (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'large-movement)
    (emacspeak-speak-line)))

(defadvice perl-end-of-function (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'large-movement)))

;;}}}

(provide  'emacspeak-perl)
;;{{{  emacs local variables 

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: nil
;;; end: 

;;}}}
