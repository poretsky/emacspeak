;;; emacspeak-fix-interactive.el --- Tools to make  Emacs' builtin prompts   speak
;;; $Id: emacspeak-fix-interactive.el,v 18.0 2003/04/29 21:17:17 raman Exp $
;;; $Author: raman $ 
;;; Description: Fixes functions that use interactive to prompt for args.
;;; Approach suggested by hans@cs.buffalo.edu
;;; Keywords: Emacspeak, Advice, Automatic advice, Interactive
;;{{{  LCD Archive entry: 

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu 
;;; A speech interface to Emacs |
;;; $Date: 2003/04/29 21:17:17 $ |
;;;  $Revision: 18.0 $ | 
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:
;;;Copyright (C) 1995 -- 2003, T. V. Raman 
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

(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(require 'advice)
(require 'dtk-speak)
;;{{{  Introduction:

;;; Emacs commands that use the 'interactive spec
;;; to read interactive arguments are a problem for Emacspeak.
;;;  This is because the prompting for the arguments is done from C
;;; See (callint.c) in the Emacs sources.
;;; Advicing the various input functions,
;;; e.g. read-file-name therefore will not help.
;;; This module defines a function that solves this problem.
;;; emacspeak-fix-commands-that-use-interactive needs to be called
;;; To speech enable such functions. 

;;; XEmacs update:
;;; XEmacs does (interactive) better--
;;; in its case most of the code letters to interactive 
;;; make it back to the elisp layer.
;;; The exception to this appear to be the code letters for
;;; reading characters and key sequences 
;;; i.e. "c" and "k"
;;; This module has been updated to auto-advice
;;; only those interactive commands that use "c" or "k"
;;; when running XEmacs.
;;; The Search for emacspeak-xemacs-p to see the test used.

;;}}}
;;{{{  functions that are  fixed. 

(defvar emacspeak-last-command-needs-minibuffer-spoken nil 
  "Used to signal to minibuffer that the contents need to be spoken.")

(defvar emacspeak-commands-that-are-fixed 
  nil
  "Functions that have been auto-advised.
These functions have been  adviced  to make their
interactive prompts speak. ")

(defvar emacspeak-commands-dont-fix-regexp 
  (concat 
   "^ad-Orig\\|^mouse\\|^scroll-bar"
   "\\|^face\\|^frame\\|^font"
   "\\|^color\\|^timer")
  "Regular expression matching function names whose interactive spec should not be fixed.")
;;;###autoload
(defsubst emacspeak-should-i-fix-interactive-p (sym)
  "Predicate to test if this function should be fixed. "
  (declare (special emacspeak-commands-dont-fix-regexp))
  (and (commandp sym)
       (not (get  sym 'emacspeak-fixed))
       (stringp (second (ad-interactive-form (symbol-function sym))))
       (not (string-match emacspeak-commands-dont-fix-regexp (symbol-name sym)))))
 
(defun emacspeak-fix-commands-that-use-interactive ()
  "Auto advices interactive commands to speak prompts."
  (mapatoms 'emacspeak-fix-interactive-command-if-necessary ))

;;{{{  Understanding aid 

(defun emacspeak-show-interactive (sym)
  "Auto-advice interactive command to speak its prompt.  Fix
the function definition of sym to make its interactive form
speak its prompts. "
  (declare (special emacspeak-commands-that-are-fixed))
  (let ((interactive-list
         (split-string
          (second (ad-interactive-form (symbol-function sym )))
          "\n")))
                                        ; advice if necessary
    (when
        (some
         (function
          (lambda (prompt)
            (declare (special emacspeak-xemacs-p))
            (not
             (or
              (string-match  "^[@*]?[depPr]" prompt )
              (string= "*" prompt )
              (and emacspeak-xemacs-p
                   (not (string-match  "^\\*?[ck]" prompt )))))))
         interactive-list )
      (progn
        (`
         (defadvice (, sym) (before  emacspeak-auto activate  )
           "Automatically defined advice to speak interactive prompts. "
           (interactive
            (nconc  
             (,@
              (mapcar
               (function 
                (lambda (prompt)
                  (` (let
                         ((dtk-stop-immediately nil)
                          (emacspeak-last-command-needs-minibuffer-spoken t)
                          (emacspeak-speak-messages nil))
                       (tts-with-punctuations "all"
                                              (dtk-speak
                                               (,
                                                (format " %s "
                                                        (or
                                                         (if (= ?* (aref  prompt 0))
                                                             (substring prompt 2 )
                                                           (substring prompt 1 ))
                                                         "")))))
                       (call-interactively
                        '(lambda (&rest args)
                           (interactive (, prompt))
                           args) nil)))))
               interactive-list))))))))))

;;}}}
;;;###autoload
(defun emacspeak-fix-interactive (sym)
  "Auto-advice interactive command to speak its prompt.  
Fix the function definition of sym to make its interactive form
speak its prompts. "
  (declare (special emacspeak-commands-that-are-fixed))
  (let ((interactive-list
         (split-string
          (second (ad-interactive-form (symbol-function sym )))
          "\n")))
					;memoize call
    (put sym 'emacspeak-fixed t)
                                        ; advice if necessary
    (when
        (some
         (function
          (lambda (prompt)
            (declare (special emacspeak-xemacs-p
                              emacs-version))
            (not
             (or
              (string-match  "^[@*]?[depPr]" prompt )
              (string= "*" prompt )
              (and emacspeak-xemacs-p
                   (not (string-match  "^\\*?[ck]" prompt )))))))
         interactive-list )
      (eval
       (`
        (defadvice (, sym) (before  emacspeak-auto activate
                                    protect compile)
          "Automatically defined advice to speak interactive prompts. "
          (interactive
           (nconc  
            (,@
             (mapcar
              #'(lambda (prompt)
                  (` (let
                         ((dtk-stop-immediately nil)
                          (emacspeak-last-command-needs-minibuffer-spoken t)
                          (emacspeak-speak-messages nil))
                       (when (or (string-lessp emacs-version "21")
                                 (= ?c (aref  (, prompt) 0))
                                 (= ?K (aref  (, prompt) 0))
                                 (= ?k (aref  (, prompt) 0)))
			 (tts-with-punctuations "all"
						(dtk-speak
						 (,
						  (format " %s "
							  (or
							   (if (= ?* (aref  prompt 0))
							       (substring prompt 2 )
							     (substring prompt 1 ))
							   ""))))))
                       (call-interactively
                        #'(lambda (&rest args)
                            (interactive (, prompt))
                            args) nil))))
              interactive-list)))))))
      (push sym  emacspeak-commands-that-are-fixed )))
  t)

;;; inline function for use from other modules:
;;;###autoload
(defsubst  emacspeak-fix-interactive-command-if-necessary
  (command)
  "Fix command if necessary."
  (and (emacspeak-should-i-fix-interactive-p command)
       (emacspeak-fix-interactive command)))

;;}}}
;;{{{  fixing all commands defined in a given module:

;;; Code initially contributed by  Dmitry Paduchih
;;; <paduch@imm.uran.ru>
;;; Updated by <raman@cs.cornell.edu> to avoid unnecessary
;;; globals

(defun emacspeak-fix-commands-loaded-from (module)
  "Fix all commands loaded from a specified module."
  (interactive
   (list
    (read-from-minibuffer "Module:")))
  (dolist (item
           (rest (assoc module load-history)))
    (and (symbolp item)
	 (commandp item)
	 (emacspeak-fix-interactive-command-if-necessary item)))
  (when (interactive-p)
    (message "Fixed interactive commands defined in module %s" module)))

(defvar emacspeak-load-history-pointer nil
  "Internal variable used by command 
emacspeak-fix-all-recent-commands to track load-history.")

(defun emacspeak-fix-all-recent-commands ()
  "Fix recently loaded interactive commands.
This command looks through `load-history' and fixes commands if necessary.
Memoizes call in emacspeak-load-history-pointer to memoize this call. "
  (interactive)
  (declare (special load-history
                    emacspeak-load-history-pointer))
  (unless (eq emacspeak-load-history-pointer load-history)
    (let ((lh load-history)
          (emacspeak-speak-messages nil))
;;; cdr down lh till we hit emacspeak-load-history-pointer
      (while (and lh
                  (not (eq lh
                           emacspeak-load-history-pointer)))
      ;;; fix commands in this module
        (dolist (item (rest (first lh)))
          (and (symbolp item)
               (commandp item)
                                        ; so fix it if necessary
               (emacspeak-fix-interactive-command-if-necessary item)))
        (when (interactive-p)
          (message "Fixed commands in %s" (first (first lh))))
        (setq lh (rest lh)))
;;;memoize for future call
      (setq emacspeak-load-history-pointer load-history))
    (when (interactive-p)
      (message "Fixed recently defined  interactive commands")))
  t)

;;}}}
(provide 'emacspeak-fix-interactive)
;;{{{  end of file
;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end: 

;;}}}
