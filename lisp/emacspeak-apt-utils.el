;;; emacspeak-apt-utils.el --- speech-enable APT interface  -*- lexical-binding: t; -*-
;;; Description:  Emacspeak extension to speech-enable APT utilities
;;; Keywords: Emacspeak, apt, Debian Package Manager
;;{{{  LCD Archive entry:

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu
;;; A speech interface to Emacs |
;;; $Date: 2007-08-25 18:28:19 -0700 (Sat, 25 Aug 2007) $ |
;;;  $Revision: 4531 $ |
;;; Location undetermined
;;;

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

;;; This module speech-enables apt-utils.el
;;; that is included in the debian-el package
;;; and provides a nice interface to searching and browsing
;;; Debian packages.
;;; Code:

;;}}}
;;{{{ required modules

(require 'emacspeak-preamble)
(require 'apt-utils ()  'no-error)
;;}}}
;;{{{ Forward declarations

(declare-function apt-utils-package-at "ext:apt-utils.el" ())

;;}}}
;;{{{  Initial setup

(defun emacspeak-apt-utils-grab-package-at-point ()
  "Copy package under point to kill ring."
  (interactive)
  (unless (eq major-mode 'apt-utils-mode)
    (error "Not in APT Info buffer."))
  (let ((package (apt-utils-package-at)))
    (emacspeak-auditory-icon 'yank-object)
    (dtk-speak package)
    (kill-new package)))

(defsubst emacspeak-apt-utils-speak-package-name ()
  "Speak package name at point."
  (let ((package (apt-utils-package-at)))
    (put-text-property 0 (length package)
                       'personality (get-text-property (point) 'personality)
                       package)
    (dtk-speak package)))

(defadvice apt-utils-mode (after emacspeak pre act comp)
  "Setup Emacspeak extensions"
  (dtk-set-punctuations 'all)
  (define-key apt-utils-mode-map "y" 'emacspeak-apt-utils-grab-package-at-point))

;;}}}
;;{{{ Advice interactive commands to speak.

(cl-loop for f in
      '(apt-utils-search
	apt-utils-search-names-only
	apt-utils-search-grep-dctrl
	apt-utils-search-file-names)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
	  "Provide auditory feedback."
	  (when (ems-interactive-p)
	    (emacspeak-auditory-icon 'search-hit)))))

(cl-loop for f in
      '(apt-utils-quit
	apt-utils-kill-buffer)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
	  "Provide auditory feedback."
	  (when (ems-interactive-p)
	    (emacspeak-auditory-icon 'close-object)
	    (emacspeak-speak-mode-line)))))

(cl-loop for f in
      '(apt-utils-rebuild-package-lists
	apt-utils-toggle-package-info)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
	  "Provide auditory feedback."
	  (when (ems-interactive-p)
	    (emacspeak-auditory-icon 'task-done)))))

(cl-loop for f in
      '(apt-utils-show-package
	apt-utils-choose-package-link
	apt-utils-view-previous-package
	apt-utils-view-copyright
	apt-utils-view-readme
	apt-utils-view-debian-readme
	apt-utils-view-news
	apt-utils-view-debian-news
	apt-utils-view-changelog
	apt-utils-view-debian-changelog
        apt-utils-list-package-files
	apt-utils-follow-link)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
	  "Provide auditory feedback."
	  (when (ems-interactive-p)
	    (emacspeak-auditory-icon 'open-object)))))

(cl-loop for f in
      '(apt-utils-previous-package
	apt-utils-next-package)
      do
      (eval
       `(defadvice ,f (around emacspeak pre act comp)
	  "Provide auditory feedback."
	  (if (ems-interactive-p)
	      (let ((emacspeak-speak-messages nil))
		ad-do-it
		(emacspeak-auditory-icon 'large-movement)
		(emacspeak-speak-text-range 'apt-package))
	    ad-do-it)
	  ad-return-value)))

;;}}}
;;{{{ mapping font faces to personalities

(voice-setup-add-map
 '(
   (apt-utils-normal-package-face voice-bolden)
   (apt-utils-virtual-package-face voice-animate)
   (apt-utils-field-keyword-face voice-animate-extra)
   (apt-utils-field-contents-face voice-lighten-extra)
   (apt-utils-description-face voice-smoothen-extra)
   (apt-utils-version-face voice-lighten)
   (apt-utils-broken-face voice-bolden-and-animate)
   ))

;;}}}
(provide 'emacspeak-apt-utils)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; end:

;;}}}
