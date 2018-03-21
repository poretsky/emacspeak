;;; voice-setup.el --- Setup voices for voice-lock  -*- lexical-binding: t; -*-
;;; $Id$
;;; $Author: tv.raman.tv $
;;; Description:  Voice lock mode for Emacspeak
;;{{{  LCD Archive entry:
;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu
;;; A speech interface to Emacs |
;;; $Date: 2007-09-01 15:30:13 -0700 (Sat, 01 Sep 2007) $ |
;;;  $Revision: 4672 $ |
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
;;{{{ Introduction

;;; Commentary:

;;; A voice is to audio as a font is to a visual display.
;;; A personality is to audio as a face is to a visual display.
;;;
;; Voice-lock-mode is a minor mode that causes your comments to be
;; spoken in one personality, strings in another, reserved words in another,
;; documentation strings in another, and so on.
;;
;; Comments will be spoken in `emacspeak-voice-lock-comment-personality'.
;; Strings will be spoken in `emacspeak-voice-lock-string-personality'.
;; Function and variable names (in their defining forms) will be
;;  spoken in `emacspeak-voice-lock-function-name-personality'.
;; Reserved words will be spoken in `emacspeak-voice-lock-keyword-personality'.
;;
;; To make the text you type be voiceified, use M-x voice-lock-mode.
;; When this minor mode is on, the voices of the current line are
;; updated with every insertion or deletion.
;;

;;

;;; How faces map to voices: TTS engine specific modules e.g.,
;;; dectalk-voices.el and outloud-voices.el define a standard set
;;; of voice names.  This module maps standard "personality"
;;; names to these pre-defined voices.  It does this via special
;;; form def-voice-font which takes a personality name, a voice
;;; name and a face name to set up the mapping between face and
;;; personality, and personality and voice.
;;; Newer Emacspeak modules should use voice-setup-add-map when
;;; defining face->personality mappings.
;;; Older code calls def-voice-font directly, but over time those
;;; calls will be changed to the more succinct form provided by
;;; voice-setup-add-map. For use from other modules, also see
;;; function voice-setup-map-face which is useful when mapping a
;;; single face.
;;; Both voice-setup-add-map and voice-setup-map-face call
;;; special form def-voice-font.

;;; Special form def-voice-font sets up the personality name to
;;; be available via custom.  new voices can be defined using CSS
;;; style specifications see special form defvoice Voices defined
;;; via defvoice can be customized via custom see the
;;; documentation for defvoice.
;;; Code:

;;}}}
;;{{{ Required modules

(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(eval-when-compile (require 'easy-mmode))
(require 'custom)
(require 'acss-structure)
(require 'tts)
(require 'outloud-voices)
(require 'mac-voices)
(require 'espeak-voices)
(require 'dectalk-voices)
(require 'emacspeak-sounds)

;;}}}
;;{{{ Forward declarations

(declare-function tts-list-voices "dectalk-voices")

;;}}}
;;{{{ customization groups

(defgroup voice-fonts nil
  "Customization group for setting voices."
  :group 'emacspeak)

(defgroup personalities nil
  "Customization group for assignment voices to faces."
  :group 'voice-fonts)

(defcustom voice-lock-global-modes t
  "Modes for which Voice Lock mode is automagically turned on.
Global Voice Lock mode is controlled by the command `global-voice-lock-mode'.
If nil, means no modes have Voice Lock mode automatically turned on.
If t, all modes that support Voice Lock mode have it automatically turned on.
If a list, it should be a list of `major-mode' symbol names for which Voice Lock
mode should be automatically turned on.  The sense of the list is negated if it
begins with `not'.  For example:
 (c-mode c++-mode)
means that Voice Lock mode is turned on for buffers in C and C++ modes only."
  :type '(choice (const :tag "none" nil)
                 (const :tag "all" t)
                 (set :menu-tag "mode specific" :tag "modes"
                      :value (not)
                      (const :tag "Except" not)
                      (repeat :inline t (symbol :tag "mode"))))
  :group 'voice-lock)

;;}}}
;;{{{  helper for voice custom items:

(unless (fboundp 'tts-list-voices)
  (fset 'tts-list-voices #'dectalk-list-voices))

(defun voice-setup-custom-menu ()
  "Return a choice widget used in selecting voices."
  (declare (special voice-setup-personality-table))
  (let ((menu
         (mapcar
          #'(lambda (voice)
              (list 'const voice))
          (loop for k being the hash-keys of voice-setup-personality-table
                collect   k))))
    (push '(const default) menu)
    (push '(const inaudible) menu)
    (cons 'choice menu)))

(defun voice-setup-read-personality (&optional prompt)
  "Read name of a pre-defined personality using completion."
  (let ((table (mapcar
                #'(lambda (v)
                    (cons
                     (format "%s" v)
                     (format "%s" v)))
                (tts-list-voices))))
    (read
     (completing-read
      (or prompt "Personality: ")
      table))))

;;}}}
;;{{{ map faces to voices

(defvar voice-setup-face-voice-table (make-hash-table)
  "Hash table holding face to voice mapping.")

(defsubst voice-setup-set-voice-for-face (face voice)
  "Map face --a symbol-- to relevant voice."
  (declare (special  voice-setup-face-voice-table))
  (puthash face voice voice-setup-face-voice-table))

(defsubst voice-setup-get-voice-for-face (face)
  "Map face --a symbol-- to relevant voice."
  (declare (special voice-setup-face-voice-table
                    voice-setup-personality-table))
  (let ((voice (gethash face voice-setup-face-voice-table)))
    (if (eq voice 'inaudible)
        voice
      (gethash voice voice-setup-personality-table))))

(defun voice-setup-show-rogue-faces ()
  "Return list of voices that map to non-existent faces."
  (declare (special voice-setup-face-voice-table))
  (loop for f being the hash-keys of voice-setup-face-voice-table
        unless (facep f) collect f))

;;}}}
;;{{{ special form def-voice-font

(defmacro  def-voice-font (personality voice face doc &rest args)
  "Define personality and map it to specified face."
  (let ((documentation
         (concat
          doc
          (if (or (eq voice 'default)
                  (eq voice 'inaudible))
              (format "\nThis personality originally uses %s voice." voice)
            (format "\nThis personality originally uses %s whose effect\ncan be changed globally by customizing %s-settings."
                    voice  voice))
          "\nYou can choose another voice here.")))
    `(progn
       (unless (boundp ',personality)
;;; New Personality
         (defcustom  ,personality
           ',voice
           ,documentation
           :type (voice-setup-custom-menu)
           :group 'personalities
           :set '(lambda (sym val)
                   (voice-setup-set-voice-for-face ,face val)
                   (set-default sym val))
           ,@args)))))

(defsubst voice-setup-name-personality (face-name)
  "Compute personality name to use."
  (let ((name nil))
    (setq name
          (or
           (replace-regexp-in-string "face$" "personality" face-name)
           face-name))
    (setq name
          (or
           (replace-regexp-in-string "font" "voice" name)
           name))
    (when (string-equal name face-name)
      (setq name (format "%s-voice" name)))
    (concat "emacspeak-" name)))

(defun voice-setup-map-face (face voice)
  "Invoke def-voice-font with appropriately generated personality name."
  (let ((doc (format "Personality used for %s" face))
        (personality
         (intern (voice-setup-name-personality (symbol-name face)))))
    (eval
     `(def-voice-font ,personality ,voice  ',face  ,doc))))

(defun voice-setup-add-map (fv-alist)
  "Sets up face to voice mapping given in fv-alist."
  (loop
   for fv in fv-alist
   do
   (voice-setup-map-face (first fv) (second fv))))

;;}}}
;;{{{  special form defvoice

(defvar voice-setup-personality-table (make-hash-table)
  "Maps personality names to ACSS  settings.
Keys are personality names.")

(defsubst voice-setup-personality-from-style (personality style-list)
  "Define a personality given a list of speech style settings."
  (declare (special voice-setup-personality-table))
  (let ((voice
         (acss-personality-from-speech-style
          (make-acss
           :family (nth 0 style-list)
           :average-pitch (nth 1 style-list)
           :pitch-range (nth 2 style-list)
           :stress (nth 3 style-list)
           :richness (nth 4  style-list)
           :punctuations (nth 5  style-list)))))
    (when personality
      (puthash personality voice voice-setup-personality-table))
    voice))

;;; note that for now we dont use  gain settings

(defmacro defvoice (personality settings doc)
  "Define voice using CSS setting.  Setting is a list of the form
(list paul 5 5 5 5 'all) which defines a standard male voice
that speaks `all' punctuations.  Once
defined, the newly declared personality can be customized by calling
command \\[customize-variable] on <personality>-settings.. "
  `(progn
     (defvar ,personality nil
       ,(concat
         doc
         (format "Customize this overlay via %s-settings."
                 personality)))
     (defcustom ,(intern (format "%s-settings"  personality))
       ,settings
       ,doc
       :type  '(list
                (choice :tag "Family"
                        (const :tag "Unspecified" nil)
                        (const  :tag "Paul" paul)
                        (const :tag "Harry" harry)
                        (const :tag "Betty" betty))
                (choice :tag "Average Pitch"
                        (const :tag "Unspecified" nil)
                        (integer :tag "Number"))
                (choice :tag "Pitch Range"
                        (const :tag "Unspecified" nil)
                        (integer :tag "Number"))
                (choice :tag "Stress"
                        (const :tag "Unspecified" nil)
                        (integer :tag "Number"))
                (choice :tag "Richness"
                        (const :tag "Unspecified" nil)
                        (integer :tag "Number"))
                (choice :tag "Punctuation Mode "
                        (const :tag "Unspecified" nil)
                        (const :tag "All punctuations" all)
                        (const :tag "Some punctuations" some)
                        (const :tag "No punctuations" none)))
       :group 'voice-fonts
       :set
       '(lambda  (sym val)
          (setq ,personality
                (voice-setup-personality-from-style ',personality val))
          (set-default sym val)))))

;;}}}                                   ; ; ; ;
;;{{{ voices defined using ACSS         

;;; these voices are device independent 

(defvoice  voice-punctuations-all (list nil nil nil nil  nil 'all)
  "Turns current voice into one that  speaks all punctuations.")

(defvoice  voice-punctuations-some (list nil nil nil nil  nil 'some)
  "Turns current voice into one that  speaks some punctuations.")

(defvoice  voice-punctuations-none (list nil nil nil nil  nil "none")
  "Turns current voice into one that  speaks no punctuations.")

(defvoice  voice-monotone (list nil nil 0 0 nil 'all)
  "Turns current voice into a monotone and speaks all punctuations.")

(defvoice  voice-monotone-light (list nil nil 2 2  nil 'all)
  "Turns current voice into a light monotone.")

(defvoice  voice-monotone-medium (list nil nil 1  1  nil 'all)
  "Turns current voice into a medium monotone.")

(defvoice voice-animate (list nil 7 7 4)
  "Animates current voice.")

(defvoice voice-animate-medium (list nil 6 6  5)
  "Adds medium animation  current voice.")

(defvoice voice-animate-extra (list nil 8 8 6)
  "Adds extra animation  to current voice.")

(defvoice voice-smoothen (list nil nil nil 3 4)
  "Smoothen current voice.")

(defvoice voice-smoothen-extra (list nil nil nil 2 2)
  "Extra smoothen current voice.")

(defvoice voice-smoothen-medium (list nil nil nil 3 3)
  "Add medium smoothen current voice.")

(defvoice voice-brighten-medium (list nil nil nil 5 6)
  "Brighten  (medium) current voice.")

(defvoice voice-brighten (list nil nil nil 6 7)
  "Brighten current voice.")

(defvoice voice-brighten-extra (list nil nil nil 7 8)
  "Extra brighten current voice.")

(defvoice voice-bolden (list nil 3 6 6  nil)
  "Bolden current voice.")

(defvoice voice-bolden-medium (list nil 2 6 7  nil)
  "Add medium bolden current voice.")

(defvoice voice-bolden-extra (list nil 1 6 7 8)
  "Extra bolden current voice.")

(defvoice voice-lighten (list nil 6 6 2   nil)
  "Lighten current voice.")

(defvoice voice-lighten-medium (list nil 7 7 3  nil)
  "Add medium lightness to  current voice.")

(defvoice voice-lighten-extra (list nil 9 8 7   nil)
  "Add extra lightness to  current voice.")

(defvoice voice-bolden-and-animate (list nil 3 8 8 8)
  "Bolden and animate  current voice.")

(defvoice voice-womanize-1 (list 'betty 5 nil nil nil nil)
  "Apply first female voice.")

;;}}}
;;{{{  indentation and annotation

(defvoice voice-indent (list nil nil 3 1 3)
  "Indicate indentation .")

(defvoice voice-annotate (list nil nil 4 0 4)
  "Indicate annotation.")

;;}}}
;;{{{ voice overlays

;;; these are suitable to use as "overlay voices".
(defvoice voice-lock-overlay-0
  (list nil 8 nil nil nil nil)
  "Overlay voice that sets dimension 0 of ACSS structure to 8.")

(defvoice voice-lock-overlay-1
  (list nil nil 8 nil nil nil)
  "Overlay voice that sets dimension 1 of ACSS structure to 8.")

(defvoice voice-lock-overlay-2
  (list nil nil nil 8 nil nil)
  "Overlay voice that sets dimension 2 of ACSS structure to 8.")

(defvoice voice-lock-overlay-3
  (list nil  nil nil nil 8 nil)
  "Overlay voice that sets dimension 3 of ACSS structure to 8.")

;;}}}
;;{{{  Define some voice personalities:

(voice-setup-add-map
 '(
   (shr-link voice-bolden)
   (bold voice-bolden)
                                        ;(variable-pitch voice-animate) ; this is often the default
   (bold-italic voice-bolden-and-animate)
   (button voice-bolden)
   (link voice-bolden)
   (link-visited voice-bolden-medium)
   (success voice-bolden)
   (error voice-animate)
   (warning voice-bolden-and-animate)
   (fixed-pitch voice-monotone)
   (font-lock-builtin-face voice-bolden)
   (font-lock-comment-face voice-monotone)
   (font-lock-comment-delimiter-face voice-smoothen-medium)
   (font-lock-regexp-grouping-construct voice-smoothen)
   (font-lock-regexp-grouping-backslash voice-smoothen-extra)
   (font-lock-negation-char-face voice-brighten-extra)
   (font-lock-constant-face voice-lighten)
   (font-lock-doc-face voice-monotone-medium)
   (font-lock-function-name-face voice-bolden-medium)
   (font-lock-keyword-face voice-animate)
   (font-lock-preprocessor-face voice-monotone-medium)
   (shadow voice-monotone-medium)
   (font-lock-string-face voice-lighten-extra)
   (font-lock-type-face voice-smoothen)
   (font-lock-variable-name-face voice-bolden)
   (font-lock-warning-face voice-bolden-and-animate)
   (help-argument-name voice-smoothen)
   (query-replace voice-bolden)
   (match voice-lighten)
   (isearch voice-bolden)
   (highlight voice-animate)
   (italic voice-animate)
   (match voice-animate)
   (region voice-brighten)
   (underline voice-lighten-extra)
   ))

;;}}}
;;{{{ new light-weight voice lock

;;;###autoload
(define-minor-mode voice-lock-mode
  "Toggle voice lock mode."
  t nil nil
  (when (ems-interactive-p)
    (let ((state (if voice-lock-mode 'on 'off)))
      (when (ems-interactive-p)
        (emacspeak-auditory-icon state)))))

;;;###autoload
(defun turn-on-voice-lock ()
  "Turn on Voice Lock mode ."
  (interactive)
  (unless voice-lock-mode (voice-lock-mode)))

;;;###autoload
(defun turn-off-voice-lock ()
  "Turn off Voice Lock mode ."
  (interactive)
  (when voice-lock-mode (voice-lock-mode -1)))

;;;### autoload
(defun voice-lock-toggle ()
  "Interactively toggle voice lock."
  (interactive)
  (if voice-lock-mode
      (turn-off-voice-lock)
    (turn-on-voice-lock))
  (when (called-interactively-p 'interactive)
    (message "Turned %s voice lock mode in buffer. " 
             (if voice-lock-mode " on " " off "))
    (emacspeak-auditory-icon (if voice-lock-mode 'on 'off))))

;;;###autoload
(defvar global-voice-lock-mode t
  "Global value of voice-lock-mode.")

(define-globalized-minor-mode global-voice-lock-mode
  voice-lock-mode turn-on-voice-lock
  :initialize 'custom-initialize-delay
  :init-value (not (or noninteractive emacs-basic-display))
  :group 'voice-lock
  :version "24.1")

;; Install ourselves:
(declaim (special text-property-default-nonsticky))
(unless (assq 'personality text-property-default-nonsticky)
  (push  (cons 'personality t) text-property-default-nonsticky))

(unless (assq 'voice-lock-mode minor-mode-alist)
  (setq minor-mode-alist (cons '(voice-lock-mode " Voice") minor-mode-alist)))

;;}}}
;;{{{ list-voices-display

(defcustom voice-setup-sample-text
  "Emacspeak --- The Complete Audio Desktop!"
  "Sample text used  when displaying available voices."
  :type 'string
  :group 'voice-fonts)

(defun voice-setup-list-voices (pattern)
  "Show all defined voice-face mappings  in a help buffer.
Sample text to use comes from variable
  `voice-setup-sample-text'. "
  (interactive (list (and current-prefix-arg
                          (read-string "List faces matching regexp: "))))
  (declare (special voice-setup-sample-text
                    list-faces-sample-text))
  (let ((list-faces-sample-text voice-setup-sample-text))
    (list-faces-display pattern)
    (message "Displayed voice-face mappings in other window.")))

;;}}}
;;{{{ interactively silence personalities 

(defvar voice-setup-buffer-face-voice-table (make-hash-table)
  "Hash table used to store buffer local face->personality mappings.")
;;;###autoload
(defun voice-setup-toggle-silence-personality ()
  "Toggle audibility of personality under point  .
If personality at point is currently audible, its
face->personality map is cached in a buffer local variable, and
its face->personality map is replaced by face->inaudible.  If
personality at point is inaudible, and there is a cached value,
then the original face->personality mapping is restored.  In
either case, the buffer is refontified to have the new mapping
take effect."
  (interactive)
  (declare (special voice-setup-buffer-face-voice-table))
  (let* ((face (get-text-property (point) 'face))
         (personality (gethash face voice-setup-face-voice-table))
         (orig (gethash face voice-setup-buffer-face-voice-table)))
    (cond
     ((eq personality  'inaudible)
      (voice-setup-set-voice-for-face face  orig)
      (emacspeak-auditory-icon 'open-object))    
     (t (voice-setup-set-voice-for-face face 'inaudible)
        (puthash face personality voice-setup-buffer-face-voice-table)
        (emacspeak-auditory-icon 'close-object)))
    (when (buffer-file-name)
      (normal-mode))))

;;}}}
(provide 'voice-setup)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: nil
;;; end:

;;}}}
