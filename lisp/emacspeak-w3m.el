;;; emacspeak-w3m.el --- speech-enables w3m-el
;;;$Id$
;;{{{ Copyright

;;; This file is not part of Emacs, but the same terms and
;;; conditions apply.
;; Copyright (C) 2001,2002,2011  Dimitri V. Paduchih

;; Initial version: Author: Dimitri Paduchih <paduch@imm.uran.ru>
;;;author: T. V. Raman (integration with Emacspeak, and sections marked TVR)
;; Keywords: emacspeak, w3m

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;;

;;}}}

;;; Code:
;;{{{  required modules

(require 'emacspeak-preamble)
(require 'emacspeak-webutils)
(require 'emacspeak-we)
(require 'easymenu)
(require 'custom)
(require 'w3m () 'noerror)
(require 'w3m-util () 'noerror)
(require 'w3m-form () 'noerror)

;;}}}
;;{{{ Forward declarations

(declare-function w3m-anchor "ext:w3m-util.el" (&optional position))
(declare-function w3m-image "ext:w3m-util.el" (&optional position))
(declare-function w3m-find-file "ext:w3m.el" (file))
(declare-function w3m-redisplay-this-page "ext:w3m.el" (&optional arg))

;;}}}
;;{{{  custom

(defgroup emacspeak-w3m nil
  "WWW browser for the Emacspeak Desktop."
  :group 'emacspeak
  :group 'w3m
  :prefix "emacspeak-w3m-")

(defcustom emacspeak-w3m-speak-titles-on-switch t
  "Speak the document title when switching between w3m buffers.
If non-nil, switching between w3m buffers will speak the title
instead of the modeline."
  :type 'boolean
  :group 'emacspeak-w3m)

(defcustom emacspeak-w3m-text-input-field-types "email"
  "input types that should be treated as text input fields.
Several types can be specified using regular expression syntax.
This hack helps to deal with some specially designed forms."
  :type 'regexp
  :group 'emacspeak-w3m)

;;}}}
;;{{{ keybindings
(add-hook 'w3m-display-hook 'emacspeak-webutils-run-post-process-hook)
(when (boundp 'w3m-mode-map)
  (cl-declaim (special w3m-mode-map
                    emacspeak-prefix))
  (define-key w3m-mode-map emacspeak-prefix 'emacspeak-prefix-command)
  (define-key w3m-mode-map "x" 'emacspeak-we-xsl-map)
  (define-key w3m-mode-map [down] 'next-line)
  (define-key w3m-mode-map [up] 'previous-line)
  (define-key w3m-mode-map [right] 'emacspeak-forward-char)
  (define-key w3m-mode-map [left] 'emacspeak-backward-char)
  (define-key w3m-mode-map "j" 'emacspeak-webutils-jump-to-title-in-content)
  (define-key w3m-mode-map "l" 'emacspeak-webutils-play-media-at-point)
  (define-key w3m-mode-map "\C-t" 'emacspeak-webutils-transcode-current-url-via-google)
  (define-key w3m-mode-map "\M-t" 'emacspeak-webutils-transcode-via-google)
                                        ; Moved keybindings to avoid conflict with emacs org mode
                                        ; Avoid use of C-g on request of Raman due to concerns of misuse/confusion
                                        ; because C-g used for emacs quit 
                                        ; Moved google related operations to C-cg prefix, with exception of 
                                        ; google transcode operations, which are left as they were on C-t 
                                        ; and M-t. TX
  (define-key w3m-mode-map "\C-cgg" 'emacspeak-webutils-google-on-this-site)
  (define-key w3m-mode-map "\C-cgx" 'emacspeak-webutils-google-extract-from-cache)
  (define-key w3m-mode-map "\C-cgl" 'emacspeak-webutils-google-similar-to-this-page)
  (define-key w3m-mode-map (kbd "<C-return>") 'emacspeak-webutils-open-in-other-browser)

  (define-key emacspeak-we-xsl-map "B" 'emacspeak-w3m-xsl-add-submit-button)
  (define-key emacspeak-we-xsl-map "h" 'emacspeak-w3m-xsl-google-hits)
  (define-key emacspeak-we-xsl-map "l" 'emacspeak-w3m-xsl-linearize-tables)
  (define-key emacspeak-we-xsl-map "n" 'emacspeak-w3m-xsl-sort-tables)
  )

;;}}}
;;{{{ helpers

;;; The following definitions through fset are needed because at the
;;; time of compilation w3m-el may be unavailable and corresponding
;;; macros not working.

(defun emacspeak-w3m-anchor ())
(fset 'emacspeak-w3m-anchor
      (byte-compile '(lambda () (w3m-anchor))))

(defun emacspeak-w3m-get-action ())
(fset 'emacspeak-w3m-get-action
      (byte-compile '(lambda () (w3m-action))))

(defun emacspeak-w3m-form-get (form id))
(fset 'emacspeak-w3m-form-get
      (byte-compile '(lambda (form id)
                       (w3m-form-get form id))))

(defun emacspeak-w3m-form-plist (form))
(fset 'emacspeak-w3m-form-plist
      (byte-compile '(lambda (form)
                       (w3m-form-plist form))))

(defsubst emacspeak-w3m-form-arglist (args)
  "Canonicalize form arguments list."
  (if (numberp (car args))
      (cdr args)
    args))

(defun emacspeak-w3m-personalize-string (string personality)
  (let ((newstring (copy-sequence string)))
    (put-text-property 0 (length newstring)
                       'personality personality
                       newstring)
    newstring))

(defun emacspeak-w3m-url-at-point ()
  "Return the url at point in w3m."
  (or (w3m-anchor (point)) (w3m-image (point))))

(defun emacspeak-w3m-current-url ()
  "Returns the value of w3m-current-url."
  (eval 'w3m-current-url))

;;}}}
;;{{{ anchors

(defvar emacspeak-w3m-speak-action-alist
  '((w3m-form-input . emacspeak-w3m-speak-form-input)
    (w3m-form-input-checkbox . emacspeak-w3m-speak-form-input-checkbox)
    (w3m-form-input-radio . emacspeak-w3m-speak-form-input-radio)
    (w3m-form-input-select . emacspeak-w3m-speak-form-input-select)
    (w3m-form-input-textarea . emacspeak-w3m-speak-form-input-textarea)
    (w3m-form-submit . emacspeak-w3m-speak-form-submit)
    (w3m-form-input-password . emacspeak-w3m-speak-form-input-password)
    (w3m-form-reset . emacspeak-w3m-speak-form-reset))
  )

(defun emacspeak-w3m-anchor-text (&optional default)
  "Return string containing text of anchor under point."
  (if (get-text-property (point) 'w3m-anchor-sequence)
      (let* ((anchor-index  (get-text-property (point) 'w3m-anchor-sequence))
             (start (text-property-any (point-min) (+ 1 (point)) 'w3m-anchor-sequence anchor-index))
             (pos (next-single-property-change start 'w3m-anchor-sequence nil (point-max)))
             (value-at-start anchor-index)
             (value-at-pos nil)
             anchor-text)
        (save-excursion
          (goto-char start)
          (cl-loop do
                (when (and (integerp value-at-start) (not value-at-pos))
                  (push (buffer-substring start pos) anchor-text)
                  (push " " anchor-text)
                  (put-text-property 0 1 'personality
                                     (get-text-property 0 'personality  (cadr anchor-text))
                                     (car anchor-text)))
                (setq start pos
                      value-at-start value-at-pos
                      pos (next-single-property-change pos 'w3m-anchor-sequence nil (point-max)))
                (setq value-at-pos (get-text-property pos 'w3m-anchor-sequence))
                (when (or (eq start (point-max)) (and (integerp value-at-pos) (not (eq value-at-pos anchor-index))))
                  (cl-return (apply 'concat  (nreverse anchor-text)))))))
    default))

(defun emacspeak-w3m-speak-cursor-anchor ()
  (dtk-speak (emacspeak-w3m-anchor-text "Not found")))

(defun emacspeak-w3m-speak-this-anchor ()
  (let ((url (emacspeak-w3m-anchor))
        (act (emacspeak-w3m-get-action)))
    (cond
     (url (emacspeak-w3m-speak-cursor-anchor))
     ((consp act)
      (let ((speak-action (cdr (assq
                                (car act)
                                emacspeak-w3m-speak-action-alist))))
        (if (functionp speak-action)
            (apply speak-action (cdr act))
          (emacspeak-w3m-speak-cursor-anchor))))
     (t (emacspeak-w3m-speak-cursor-anchor)))))

;;}}}
;;{{{  forms

(defun emacspeak-w3m-speak-form-input (form &rest args)
  "Speak form input"
  (cl-declare (special w3m-form-personality))
  (let* ((id (car args))
         (arglist (emacspeak-w3m-form-arglist args))
         (name (car arglist))
         (type (cadr arglist))
         (value (nth 4 arglist)))
    (dtk-speak
     (format "%s input %s  %s"
             type
             name
             (emacspeak-w3m-personalize-string
              (or (emacspeak-w3m-form-get form id) value)
              w3m-form-personality)))))

(defun emacspeak-w3m-speak-form-input-checkbox (form &rest args)
  "Speak checkbox"
  (cl-declare (special w3m-form-personality))
  (let* ((id (car args))
         (arglist (emacspeak-w3m-form-arglist args))
         (name (car arglist))
         (value (cadr arglist)))
    (dtk-speak
     (format "checkbox %s is %s"
             name
             (emacspeak-w3m-personalize-string
              (if (member value (emacspeak-w3m-form-get form id))
                  "on"
                "off")
              w3m-form-personality)))))

(defun emacspeak-w3m-speak-form-input-password (form &rest args)
  "Speech-enable password form element."
  (cl-declare (special w3m-form-personality))
  (dtk-speak
   (format "password input %s  %s"
           (car (emacspeak-w3m-form-arglist args))
           (emacspeak-w3m-personalize-string
            (emacspeak-w3m-anchor-text)
            w3m-form-personality))))

(defun emacspeak-w3m-speak-form-submit (form &rest args)
  "Speak submit button."
  (cl-declare (special w3m-form-button-personality))
  (let* ((text (emacspeak-w3m-anchor-text))
         (arglist (emacspeak-w3m-form-arglist args))
         (name (car arglist))
         (value (cadr arglist)))
    (dtk-speak
     (cond
      ((and text (not (string-match "^[[:blank:]]*$" text)))
       (format "button %s" text))
      ((and value (not (string-match "^[[:blank:]]*$" value)))
       (format "button %s"
               (emacspeak-w3m-personalize-string
                value
                w3m-form-button-personality)))
      ((and name (not (string-match "^[[:blank:]]*$" name)))
       (format "button %s"
               (emacspeak-w3m-personalize-string
                name
                w3m-form-button-personality)))
      (t "submit button")))))

(defun emacspeak-w3m-speak-form-input-radio (form &rest args)
  "speech enable radio buttons."
  (cl-declare (special w3m-form-personality))
  (and dtk-stop-immediately (dtk-stop))
  (let* ((id (car args))
         (arglist (emacspeak-w3m-form-arglist args))
         (name (car arglist))
         (value (cadr arglist))
         (active (equal value (emacspeak-w3m-form-get form id)))
         (personality (if active
                          w3m-form-personality))
         (dtk-stop-immediately nil))
    (emacspeak-auditory-icon (if active 'on 'off))
    (dtk-speak
     (if (equal value "")
         (emacspeak-w3m-personalize-string
          (format "unset radio %s" name)
          personality)
       (format "%s of the radio %s"
               (emacspeak-w3m-personalize-string
                (concat "option " value)
                personality)
               name)))))

(defun emacspeak-w3m-speak-form-input-select (form &rest args)
  "speech enable select control."
  (cl-declare (special w3m-form-personality))
  (dtk-speak
   (format "select %s  %s"
           (car (emacspeak-w3m-form-arglist args))
           (emacspeak-w3m-personalize-string
            (emacspeak-w3m-anchor-text)
            w3m-form-personality))))

(defun emacspeak-w3m-speak-form-input-textarea (&rest ignore)
  "speech enable text area."
  (cl-declare (special w3m-form-personality))
  (dtk-speak
   (format "text area %s  %s"
           (or (get-text-property (point) 'w3m-form-name) "")
           (emacspeak-w3m-personalize-string
            (emacspeak-w3m-anchor-text)
            w3m-form-personality))))

(defun emacspeak-w3m-speak-form-reset (&rest ignore)
  "Reset button."
  (cl-declare (special w3m-form-button-personality))
  (let ((text (emacspeak-w3m-anchor-text)))
    (dtk-speak
     (format "button %s"
             (if (and text (not (string-match "^[[:blank:]]*$" text)))
                 text
               (emacspeak-w3m-personalize-string
                "reset"
                w3m-form-button-personality))))))

;;}}}
;;{{{  forms fix

(defadvice w3m-form-make-form-data (before emacspeak pre act comp)
  "Withstand some poorly designed forms."
  (let ((plist (emacspeak-w3m-form-plist (ad-get-arg 0))))
    (while plist
      (let* ((pair (plist-get (cadr plist) :value))
	     (value (cdr pair)))
        (when (and (consp value)
                   (null (car value))
                   (null (cdr value)))
          (setcdr pair nil))
	(setq plist (cddr plist))))))

;;}}}
;;{{{  advice interactive commands.

(cl-loop for f in
      '(w3m-goto-url
        w3m-redisplay-this-page
        w3m-reload-this-page
        w3m-bookmark-view
        w3m-weather)
      do
      (eval
       `(defadvice ,f (around emacspeak pre act comp)
          "Speech-enable W3M."
          (cond
           ((ems-interactive-p)
            (emacspeak-auditory-icon 'select-object)
            (let ((emacspeak-speak-messages nil))
              ad-do-it))
           (t ad-do-it))
          ad-return-value)))

(cl-loop for f in
      '(w3m-print-current-url
        w3m-print-this-url
        w3m-search)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Produce auditory icon."
          (when (ems-interactive-p)
            (emacspeak-auditory-icon 'select-object)))))

(cl-loop for f in
      '(w3m-edit-current-url w3m-edit-this-url)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Produce auditory icon."
          (when (ems-interactive-p)
            (emacspeak-auditory-icon 'select-object)
            (emacspeak-speak-mode-line)))))

(defadvice w3m-submit-form (after emacspeak pre act comp)
  "Produce auditory icon."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'button)))

(cl-loop for f in
      '(w3m-previous-buffer w3m-next-buffer
                            w3m-view-next-page w3m-view-previous-page
                            w3m-view-parent-page w3m-gohome)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Provide auditory feedback."
          (when (ems-interactive-p)
            (cl-declare (special w3m-current-title))
            (emacspeak-auditory-icon 'select-object)
            (if emacspeak-w3m-speak-titles-on-switch
                (dtk-speak w3m-current-title)
              (emacspeak-speak-mode-line))))))

(cl-loop for f in
      '(w3m-delete-buffer
        w3m-delete-other-buffers)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act comp)
          "Provide auditory feedback."
          (when (ems-interactive-p)
            (cl-declare (special w3m-current-title))
            (emacspeak-auditory-icon 'close-object)
            (if emacspeak-w3m-speak-titles-on-switch
                (dtk-speak w3m-current-title)
              (emacspeak-speak-mode-line))))))

(defadvice w3m-bookmark-kill-entry (around emacspeak pre act comp)
  "Resets the punctuation mode to the one before the delete"
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'ask-question)
    (let ((current-punct-mode dtk-punctuation-mode))
      ad-do-it
      (dtk-set-punctuations current-punct-mode))
    (emacspeak-auditory-icon 'delete-object)))

(defadvice w3m-bookmark-add-current-url (after emacspeak pre act comp)
  "Produce auditory icon."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'save-object)))

(defadvice w3m-bookmark-add-this-url (after emacspeak pre act comp)
  "Produce auditory icon."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'save-object)))

(cl-loop for f in
      '(w3m-next-anchor w3m-previous-anchor
                        w3m-next-image w3m-previous-image
                        w3m-next-form w3m-previous-form)
      do
      (eval
       `(defadvice ,f (around emacspeak pre act)
          "Speech-enable W3M."
          (cond
           ((ems-interactive-p)
            (let ((emacspeak-speak-messages nil))
              ad-do-it
              (emacspeak-auditory-icon 'large-movement)
              (emacspeak-w3m-speak-this-anchor)))
           (t ad-do-it))
          ad-return-value)))

(defadvice w3m-view-this-url (around emacspeak pre act comp)
  "Speech-enable W3M."
  (cond
   ((ems-interactive-p)
    (let ((url (emacspeak-w3m-anchor))
          (act (emacspeak-w3m-get-action)))
      (when url
        (emacspeak-auditory-icon 'select-object))
      ad-do-it
      (when (and (not url)
                 (consp act)
                 (memq (car act)
                       '(w3m-form-input
                         w3m-form-input-radio
                         w3m-form-input-checkbox
                         w3m-form-input-password)))
        (emacspeak-auditory-icon 'select-object)
        (emacspeak-w3m-speak-this-anchor))))
   (t ad-do-it))
  ad-return-value)

(defadvice w3m-history (around emacspeak pre act)
  "Speech-enable W3M."
  (cond
   ((ems-interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (let ((emacspeak-speak-messages nil))
      ad-do-it))
   (t ad-do-it))ad-return-value)

(defadvice w3m-antenna (around emacspeak pre act)
  "Speech-enable W3M."
  (cond
   ((ems-interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (let ((emacspeak-speak-messages nil))
      ad-do-it))
   (t ad-do-it))ad-return-value)

(cl-loop for f in
      '(w3m-scroll-up-or-next-url
        w3m-scroll-down-or-previous-url w3m-scroll-left
        w3m-shift-left w3m-shift-right
        w3m-horizontal-recenter w3m-horizontal-scroll
        w3m-scroll-right
        )
      do
      (eval
       `(defadvice ,f (around emacspeak pre act comp)
          "Speech-enable scrolling."
          (cond
           ((ems-interactive-p)
            (let ((opoint (save-excursion
                            (beginning-of-line)
                            (point))))
              ;; hide opoint from advised function
              (let (opoint) ad-do-it)
              (emacspeak-auditory-icon 'scroll)
              (emacspeak-speak-region opoint
                                      (save-excursion (end-of-line)
                                                      (point)))))
           (t ad-do-it))
          ad-return-value)))

(defadvice w3m (around emacspeak pre act)
  "Speech-enable W3M."
  (cond
   ((ems-interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (let ((emacspeak-speak-messages nil))
      ad-do-it)
    (when (eq (ad-get-arg 0) 'popup)
      (emacspeak-speak-mode-line)))
   (t ad-do-it))
  ad-return-value)

(defadvice w3m-process-stop (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'close-object)))

(defadvice w3m-close-window (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (with-current-buffer (window-buffer)
      (emacspeak-speak-mode-line))))

(defadvice w3m-quit (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (with-current-buffer (window-buffer)
      (emacspeak-speak-mode-line))))

(defadvice w3m-wget (after emacspeak pre act comp)
  "provide auditory confirmation"
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'select-object)))

(defadvice w3m-view-header (after emacspeak pre act comp)
  "Speech enable w3m"
  (when (ems-interactive-p)
    (cl-declare (special w3m-current-title
                      w3m-current-url))
    (cond
     ((string-match "\\`about://header/" w3m-current-url)
      (message"viewing header information for %s "w3m-current-title)))))

(defadvice w3m-view-source (after emacspeak pre act comp)
  "Speech enable w3m"
  (when (ems-interactive-p)
    (cl-declare (special w3m-current-title
                      w3m-current-url))
    (cond
     ((string-match "\\`about://source/" w3m-current-url)
      (message"viewing source for %s "w3m-current-title)))))

(defadvice w3m-history-store-position (after emacspeak pre act comp)
  "Speech enable w3m."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (dtk-speak "Marking page position")))

(defadvice w3m-history-restore-position (after emacspeak pre act comp)
  "Speech enable w3m."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (dtk-speak "Restoring previously marked position")))

(defadvice w3m-history (after emacspeak pre act comp)
  "Speech enable w3m"
  (when (ems-interactive-p)
    (dtk-speak "Viewing history")))

;;}}}
;;{{{ page display notification

(add-hook 'w3m-display-hook
          (lambda (url)
            (cl-declare (special w3m-current-title))
            (emacspeak-auditory-icon 'open-object)
            (when (stringp w3m-current-title)
              (dtk-speak w3m-current-title)))
          t)

;;}}}
;;{{{ webutils variables

(add-hook
 'w3m-fontify-after-hook
 #'(lambda ()
     (setq emacspeak-webutils-document-title 'w3m-current-title)
     (setq emacspeak-webutils-url-at-point 'emacspeak-w3m-url-at-point)
     (setq emacspeak-webutils-current-url 'emacspeak-w3m-current-url)))

;;}}}
;;{{{ buffer select mode

(defadvice w3m-select-buffer (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-mode-line)))

(defadvice w3m-select-buffer-show-this-line (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'scroll)
    (emacspeak-speak-other-window 1)))

(defadvice w3m-select-buffer-show-this-line-and-down (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'scroll)
    (emacspeak-speak-other-window 1)))

(defadvice w3m-select-buffer-show-this-line-and-switch (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-mode-line)))

(defadvice w3m-select-buffer-show-this-line-and-quit (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (emacspeak-speak-mode-line)))

(defadvice w3m-select-buffer-next-line (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-line)))

(defadvice w3m-select-buffer-previous-line (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-line)))

(defadvice w3m-select-buffer-delete-buffer (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'delete-object)
    (emacspeak-speak-line)))

(defadvice w3m-select-buffer-delete-other-buffers (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'delete-object)))

(defadvice w3m-select-buffer-quit (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (emacspeak-speak-mode-line)))

(defadvice w3m-e21-switch-to-buffer  (after emacspeak pre act)
  "Speak the modeline.
Indicate change of selection with
  an auditory icon if possible."
  (when (ems-interactive-p )
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-mode-line)))

;;}}}
;;{{{ input select mode

(add-hook 'w3m-form-input-select-mode-hook
          (lambda ()
            (emacspeak-auditory-icon 'select-object)
            (emacspeak-speak-line)))

(defadvice w3m-form-input-select-set (after emacspeak pre act comp)
  (when (and (ems-interactive-p) (w3m-anchor-sequence))
    (emacspeak-w3m-speak-this-anchor)))

(defadvice w3m-form-input-select-exit (after emacspeak pre act comp)
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'close-object)))

;;}}}
;;{{{ input textarea mode

(add-hook 'w3m-form-input-textarea-mode-hook
          (lambda ()
            (emacspeak-auditory-icon 'open-object)
            (dtk-speak "edit text area")))

(defadvice w3m-form-input-textarea-set (after emacspeak pre act comp)
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (emacspeak-w3m-speak-this-anchor)))

(defadvice w3m-form-input-textarea-exit (after emacspeak pre act comp)
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'close-object)))

;;}}}
;;{{{ TVR: applying XSL

(defun emacspeak-w3m-xslt-perform (xsl-name)
  "Perform XSL transformation by name on the current page."
  (let ((xsl (expand-file-name (concat xsl-name ".xsl")
                               emacspeak-xslt-directory))
        (browse-url-browser-function
         #'(lambda (&rest ignore)
             (w3m-redisplay-this-page))))
    (emacspeak-we-xslt-apply xsl)))

(defun emacspeak-w3m-xsl-add-submit-button ()
  "Add regular submit button to the current page if needed."
  (interactive)
  (emacspeak-w3m-xslt-perform "add-submit-button"))

(defun emacspeak-w3m-xsl-google-hits ()
  "Extracts Google hits from the current page."
  (interactive)
  (emacspeak-w3m-xslt-perform "google-hits"))

(defun emacspeak-w3m-xsl-linearize-tables ()
  "Linearizes tables on the current page."
  (interactive)
  (emacspeak-w3m-xslt-perform "linearize-tables"))

(defun emacspeak-w3m-xsl-sort-tables ()
  "Sorts tables on the current page."
  (interactive)
  (emacspeak-w3m-xslt-perform "sort-tables"))

(defadvice w3m-decode-buffer (before emacspeak pre act comp)
  "Apply requested transform if any before displaying the HTML. "
  (goto-char (point-min))
  (while (re-search-forward "=\"https?://[^/?]+\\(\\?\\)" nil t)
    (replace-match "/?" t t nil 1))
  (goto-char (point-min))
  (while (re-search-forward "<a[[:blank:]][^>]*?[[:blank:]]title=\"\\([^\"]*\\)\"[^>]*?>\\([[:blank:]]*?\\)</a>" nil t)
    (replace-match (match-string 1) t t nil 2))
  (when emacspeak-w3m-text-input-field-types
    (goto-char (point-min))
    (while (re-search-forward (format "<input[^>]*?[[:blank:]]type=\"\\(%s\\)\""
                                      emacspeak-w3m-text-input-field-types)
                              nil t)
      (replace-match "text" t t nil 1)))
  (cond
   (emacspeak-web-pre-process-hook (emacspeak-webutils-run-pre-process-hook))
   ((and emacspeak-we-xsl-p emacspeak-we-xsl-transform)
    (let* ((content-charset (or (ad-get-arg 1) w3m-current-coding-system))
           (emacspeak-xslt-options
            (if content-charset
                (format "%s %s %s"
                        emacspeak-xslt-options
                        "--encoding"
                        content-charset)
              emacspeak-xslt-options)))
      (emacspeak-xslt-region
       emacspeak-we-xsl-transform
       (point-min) (point-max)
       emacspeak-we-xsl-params))
    (ad-set-arg 1 'utf-8))))

;; Helper function for xslt functionality
;;;###autoload
(defun emacspeak-w3m-preview-this-buffer ()
  "Preview this buffer in w3m."
  (interactive)
  (let ((filename
         (make-temp-file
          (format "%s.html"
                  (make-temp-name "w3m")))))
    (write-region (point-min)
                  (point-max)
                  filename)
    (w3m-find-file filename)
    (delete-file filename)))

;;}}}
;;{{{  xsl keymap

(add-hook 'w3m-mode-setup-functions
          '(lambda ()
             (easy-menu-define xslt-menu w3m-mode-map
               "XSLT menu"
               '("XSLT transforming"
                 ["Enable default transforming on the fly"
                  emacspeak-we-xsl-toggle
                  :included (not emacspeak-we-xsl-p)]
                 ["Disable default transforming on the fly"
                  emacspeak-we-xsl-toggle
                  :included emacspeak-we-xsl-p]
                 ["Add regular submit button"
                  emacspeak-w3m-xsl-add-submit-button t]
                 ["Show only search hits"
                  emacspeak-w3m-xsl-google-hits t]
                 ["Linearize tables"
                  emacspeak-w3m-xsl-linearize-tables t]
                 ["Sort tables"
                  emacspeak-w3m-xsl-sort-tables t]
                 ["Select default transformation"
                  emacspeak-we-xslt-select t]
                 ["Apply specified transformation"
                  emacspeak-we-xslt-apply t]
                 )))
          t)

;;}}}
;;{{{ tvr: mapping font faces to personalities
(voice-setup-add-map
 '(
   (w3m-italic voice-animate)
   (w3m-insert voice-bolden)
   (w3m-strike-through voice-smoothen-extra)
   (w3m-history-current-url voice-bolden)
   (w3m-current-anchor voice-bolden-extra)
   (w3m-arrived-anchor voice-lighten-extra)
   (w3m-anchor voice-lighten)
   (w3m-bold voice-bolden-medium)
   (w3m-underline voice-brighten-extra)
   (w3m-header-line-location-title voice-bolden)
   (w3m-header-line-location-content voice-animate)
   (w3m-form-button voice-smoothen)
   (w3m-form-button-pressed voice-animate)
   (w3m-tab-unselected voice-monotone)
   (w3m-tab-selected voice-animate-extra)
   (w3m-form voice-brighten)
   (w3m-image voice-brighten)
   ))

(voice-setup-add-map
 '(
   (w3m-italic-face voice-animate)
   (w3m-insert-face voice-bolden)
   (w3m-strike-through-face voice-smoothen-extra)
   (w3m-history-current-url-face voice-bolden)
   (w3m-current-anchor-face voice-bolden-extra)
   (w3m-arrived-anchor-face voice-lighten-extra)
   (w3m-anchor-face voice-lighten)
   (w3m-bold-face voice-bolden-medium)
   (w3m-underline-face voice-brighten-extra)
   (w3m-header-line-location-title-face voice-bolden)
   (w3m-header-line-location-content-face voice-animate)
   (w3m-form-button-face voice-smoothen)
   (w3m-form-button-pressed-face voice-animate)
   (w3m-tab-unselected-face voice-monotone)
   (w3m-tab-selected-face voice-animate-extra)
   (w3m-form-face voice-brighten)
   (w3m-image-face voice-brighten)
   ))

(defadvice w3m-mode (after emacspeak pre act comp)
  "Set punctuation mode and refresh punctuations."
  (dtk-set-punctuations 'some)
  (emacspeak-pronounce-refresh-pronunciations))

;;}}}
(provide 'emacspeak-w3m)
;;{{{ end of file

;;; emacspeak-w3m.el ends here

;;; local variables:
;;; folded-file: t
;;; end:

;;}}}
