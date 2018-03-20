;;; emacspeak-eww.el --- Speech-enable EWW  -*- lexical-binding: t; -*-
;;; $Id: emacspeak-eww.el 4797 2007-07-16 23:31:22Z tv.raman.tv $
;;; $Author: tv.raman.tv $
;;; Description: Speech-enable EWW An Emacs Interface to eww
;;; Keywords: Emacspeak, Audio Desktop eww
;;{{{ LCD Archive entry:

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu
;;; A speech interface to Emacs |
;;; $Date: 2007-05-03 18:13:44 -0700 (Thu, 03 May 2007) $ |
;;; $Revision: 4532 $ |
;;; Location undetermined
;;;

;;}}}
;;{{{ Copyright:
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
;;; MERCHANTABILITY or FITNEWW FOR A PARTICULAR PURPOSE. See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Emacs; see the file COPYING. If not, write to
;;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;}}}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;{{{ introduction

;;; Commentary:
;;; EWW == Emacs Web Browser
;;; EWW is a light-weight Web browser built into Emacs 24.4.
;;; This module speech-enables EWW.
;;; It implements additional interactive commands for navigating the DOM.
;;; It also provides a set of filters for interactively filtering the DOM by various attributes such as id, class and role.

;;; Code:
;;}}}
;;{{{ Required modules

(require 'cl)
(declaim (optimize (safety 0) (speed 3)))

(eval-when-compile (require 'eww "eww" 'no-error))
(require 'dom)
(require 'dom-addons)
(eval-when-compile (require 'emacspeak-feeds "emacspeak-feeds" 'no-error))
(require 'emacspeak-preamble)
(require 'emacspeak-we)
(require 'emacspeak-webutils)
(require 'emacspeak-google)

;;}}}
;;{{{ Forward declarations

(declare-function eww "ext:eww.el" (URL))
(declare-function eww-save-history "ext:eww.el" ())
(declare-function eww-restore-history "ext:eww.el" (elem))
(declare-function eww-update-header-line-format "ext:eww.el" ())
(declare-function shr-insert-document "ext:shr.el" (dom))

(declare-function shr-expand-url "shr.el")
(declare-function shr-generic "shr.el")

;;}}}
;;{{{ Declare generated functions:

(declare-function emacspeak-eww-current-dom "emacspeak-eww" nil)
(declare-function emacspeak-eww-current-url "emacspeak-eww" nil)
(declare-function emacspeak-eww-current-title "emacspeak-eww" nil)
(declare-function emacspeak-eww-set-dom "emacspeak-eww" (dom))
(declare-function emacspeak-eww-set-url "emacspeak-eww" (url))
(declare-function emacspeak-eww-set-title "emacspeak-eww" (title))

;;}}}

;;{{{ Compatibility Helpers:

;;; For compatibility between Emacs 24 and Emacs 25
;;; eww in emacs-24 used eww-current-title etc as variables.
;;; eww in emacs 25 groups these as properties on eww-data.
;;; Emacspeak-eww defines wrapper functions to hide this difference.

(loop
 for name in
 '(title url source dom)
 do
 (cond
  ((or  (= emacs-major-version 25)
        (boundp 'eww-data))
   (eval
    `(defsubst
       ,(intern (format "emacspeak-eww-current-%s" name)) ()
       , (format "Return eww-current-%s." name)
         (declare (special eww-data))
         (plist-get eww-data
                    ,(intern (format ":%s" name))))))
  (t
   (eval
    `(defsubst
       ,(intern (format "emacspeak-eww-current-%s" name))
       ()
       , (format "Return eww-current-%s." name)
         ,(intern (format "eww-current-%s" name)))))))

(loop
 for name in
 '(title url source dom)
 do
 (cond
  ((boundp 'eww-data)
   (eval
    `(defun
         ,(intern (format "emacspeak-eww-set-%s" name)) (value)
       , (format "Set eww-current-%s." name)
         (assert (boundp 'eww-data) nil "Not a EWW rendered page.")
         (plist-put eww-data
                    ,(intern (format ":%s" name))
                    value))))
  (t ;;; emacs 24
   (eval
    `(defun
         ,(intern (format "emacspeak-eww-set-%s" name)) (value)
       , (format "Set eww-current-%s." name)
         (setq ,(intern (format "eww-current-%s" name)) value))))))

;;}}}
;;{{{ Inline Helpers:

(defsubst emacspeak-eww-prepare-eww ()
  "Ensure that we are in an EWW buffer that is well set up."
  (declare (special major-mode  emacspeak-eww-cache-updated))
  (unless (eq major-mode 'eww-mode) (error "Not in EWW buffer."))
  (unless (emacspeak-eww-current-dom) (error "No DOM!"))
  (unless emacspeak-eww-cache-updated
    (eww-update-cache (emacspeak-eww-current-dom))))

(defsubst emacspeak-eww-post-render-actions ()
  "Post-render actions for setting up emacspeak."
  (emacspeak-eww-prepare-eww)
  (emacspeak-pronounce-toggle-use-of-dictionaries t))

;;}}}
;;{{{ Viewing Page metadata: meta, links

(defun emacspeak-eww-links-rel ()
  "Display Link tags of type rel.  Web pages for which alternate links
are available are cued by an auditory icon on the header line."
  (interactive)
  (emacspeak-eww-prepare-eww)
  (let ((alt (dom-alternate-links (emacspeak-eww-current-dom)))
        (base (emacspeak-eww-current-url)))
    (cond
     ((null alt) (message "No alternate links."))
     (t
      (with-temp-buffer
        (insert "<table><th>Type</th><th>URL</th></tr>\n")
        (loop
         for a in alt do
         (insert "<tr>")
         (insert
          (format "<td>%s</td>\n"
                  (or (dom-attr a 'title)
                      (dom-attr a 'type)
                      (dom-attr a 'media)
                      "")))
         (insert
          (format "<td><a href='%s'>%s</td>\n"
                  (shr-expand-url (dom-attr a 'href) base)
                  (shr-expand-url (dom-attr a 'href) base)))
         (insert "</tr>\n"))
        (insert "</table>\n")
        (browse-url-of-buffer))))))

;;}}}
;;{{{ Setup EWW Initialization:

;;; Inform emacspeak-webutils about EWW:

(add-hook
 'eww-mode-hook
 #'(lambda ()
     (outline-minor-mode nil)
     (setq
      emacspeak-webutils-document-title #'emacspeak-eww-current-title
      emacspeak-webutils-url-at-point
      #'(lambda ()
          (let ((url (get-text-property (point) 'help-echo)))
            (cond
             ((and url
                   (stringp url)
                   (string-prefix-p
                    (emacspeak-google-result-url-prefix) url))
              (emacspeak-google-canonicalize-result-url url))
             ((and url (stringp url))url)
             (t (error "No URL under point.")))))
      emacspeak-webutils-current-url #'emacspeak-eww-current-url)))

(defvar emacspeak-eww-masquerade t
  "Says if we masquerade as a mainstream browser.")

(defun emacspeak-eww-masquerade ()
  "Toggle masquerade state."
  (interactive)
  (declare (special emacspeak-eww-masquerade))
  (setq emacspeak-eww-masquerade (not emacspeak-eww-masquerade))
  (message "Turned %s masquerade"
           (if emacspeak-eww-masquerade "on" "off"))
  (emacspeak-auditory-icon (if emacspeak-eww-masquerade 'on 'off)))

(defcustom  emacspeak-eww-masquerade-as
  (format "User-Agent: %s %s %s\r\n"
          "Mozilla/5.0 (X11; Linux i686 (x86_64)) "
          "AppleWebKit/537.36 (KHTML, like Gecko) "
          "Chrome/53.0.2785.8-1 Safari/537.36")
  "User Agent string that is  sent when masquerading is on."
  :type 'string
  :group 'emacspeak-eww)

;;; Advice note: Setting ad-return-value in one arm of the cond
;;; appears to perculate to both arms.

(defadvice url-http-user-agent-string (around emacspeak pre act comp)
  "Respond to user  asking us to masquerade."
  (cond
   ((and emacspeak-eww-masquerade
         (eq browse-url-browser-function 'eww-browse-url))
    (setq ad-return-value emacspeak-eww-masquerade-as))
   (t (setq ad-return-value "User-Agent: URL/Emacs \r\n"))))

(defun emacspeak-eww-setup ()
  "Setup keymaps etc."
  (declare (special eww-mode-map eww-link-keymap
                    shr-inhibit-images
                    emacspeak-pronounce-common-xml-namespace-uri-pronunciations
                    emacspeak-eww-masquerade
                    emacspeak-pronounce-load-pronunciations-on-startup))
  (when emacspeak-pronounce-load-pronunciations-on-startup
    (emacspeak-pronounce-augment-pronunciations
     'eww-mode emacspeak-pronounce-common-xml-namespace-uri-pronunciations)
    (emacspeak-pronounce-add-dictionary-entry
     'eww-mode
     emacspeak-speak-rfc-3339-datetime-pattern
     (cons 're-search-forward 'emacspeak-speak-decode-rfc-3339-datetime)))
;;; turn off images
  (setq shr-inhibit-images t)
                                        ; remove "I" "o" from
                                        ; eww-link-keymap
  (loop
   for c in
   '(?I ?o)
   do
   (when (assoc  c eww-link-keymap)
     (delete (assoc  c eww-link-keymap) eww-link-keymap)))
  (define-key eww-link-keymap  "k" 'shr-copy-url)
  (define-key eww-link-keymap ";" 'emacspeak-webutils-play-media-at-point)
  (define-key eww-link-keymap "U" 'emacspeak-webutils-curl-play-media-at-point)
  (define-key eww-link-keymap "\C-o" 'emacspeak-feeds-opml-display)
  (define-key eww-link-keymap "\C-r" 'emacspeak-feeds-rss-display)
  (define-key eww-link-keymap "\C-a" 'emacspeak-feeds-atom-display)
  (define-key eww-link-keymap  "y" 'emacspeak-m-player-youtube-player)
  (loop
   for binding  in
   '(
     (":" emacspeak-eww-tags-at-point)
     ("'" emacspeak-speak-rest-of-buffer)
     ("*" eww-add-bookmark)
     ("," emacspeak-eww-previous-h)
     ("." emacspeak-eww-next-h)
     ("1" emacspeak-eww-next-h1)
     ("2" emacspeak-eww-next-h2)
     ("3" emacspeak-eww-next-h3)
     ("4" emacspeak-eww-next-h4)
     ("=" dtk-toggle-punctuation-mode)
     ("/" emacspeak-eww-filter-map)
     ("?" emacspeak-webutils-google-similar-to-this-page)
     ("A" eww-view-dom-having-attribute)
     ("C" eww-view-dom-having-class)
     ("C-e" emacspeak-prefix-command)
     ("C-t" emacspeak-eww-transcode)
     ("E" eww-view-dom-having-elements)
     ("G" emacspeak-google-command)
     ("I" eww-view-dom-having-id)
     ("J" emacspeak-eww-next-element-like-this)
     ("K" emacspeak-eww-previous-element-like-this)
     ("M-SPC" emacspeak-eww-speak-this-element)
     ("M-0" emacspeak-eww-previous-h)
     ("M-1" emacspeak-eww-previous-h1)
     ("M-2" emacspeak-eww-previous-h2)
     ("M-3" emacspeak-eww-previous-h3)
     ("M-4" emacspeak-eww-previous-h4)
     ("M-a" eww-view-dom-not-having-attribute)
     ("M-c" eww-view-dom-not-having-class)
     ("M-e" eww-view-dom-not-having-elements)
     ("M-i" eww-view-dom-not-having-id)
     ("M-r" eww-view-dom-not-having-role)
     ("L" emacspeak-eww-links-rel)
     ("N" emacspeak-eww-next-element-from-history)
     ("O" emacspeak-eww-previous-li)
     ("P" emacspeak-eww-previous-element-from-history)
     ("Q" emacspeak-kill-buffer-quietly)
     ("R" eww-view-dom-having-role)
     ("T" emacspeak-eww-previous-table)
     ("[" emacspeak-eww-previous-p)
     ("DEL" emacspeak-eww-restore)
     ("]" emacspeak-eww-next-p)
     ("b" shr-previous-link)
     ("e" emacspeak-we-xsl-map)
     ("f" shr-next-link)
     ("k" eww-copy-page-url)
     ("n" emacspeak-eww-next-element)
     ("o" emacspeak-eww-next-li)
     ("p" emacspeak-eww-previous-element)
     ("s" eww-readable)
     ("t" emacspeak-eww-next-table)
     )
   do
   (emacspeak-keymap-update eww-mode-map binding)))

(when (boundp 'eww-mode-map)
  (emacspeak-eww-setup))

;;}}}
;;{{{ Map Faces To Voices:

(voice-setup-add-map
 '(
   (eww-invalid-certificate  voice-bolden-and-animate)
   (eww-valid-certificate voice-bolden)
   (eww-form-submit voice-animate)
   (eww-form-checkbox voice-monotone)
   (eww-form-select voice-annotate)
   (eww-form-text voice-lighten)))

;;}}}
;;{{{ Advice Interactive Commands:

(loop
 for f in
 '(eww-up-url eww-top-url
              eww-next-url eww-previous-url
              eww-back-url eww-forward-url)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Provide auditory feedback"
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'open-object)
       (dtk-speak (emacspeak-eww-current-title))))))

(defvar emacspeak-eww-style nil
  "Record if we applied an  xsl style in this buffer.")

(make-variable-buffer-local 'emacspeak-eww-style)

(defvar emacspeak-eww-feed nil
  "Record if this eww buffer is displaying a feed.")

(make-variable-buffer-local 'emacspeak-eww-feed)

(defvar emacspeak-eww-url-template nil
  "Record if this eww buffer is displaying a url-template.")

(make-variable-buffer-local 'emacspeak-eww-url-template)

;;;Check cache if URL already open, otherwise cache.

(defadvice eww-reload (around emacspeak pre act comp)
  "Check buffer local settings for feed buffers.
If buffer was result of displaying a feed, reload feed.
If we came from a url-template, reload that template.
Retain previously set punctuations  mode."
  (let () (add-hook 'emacspeak-web-post-process-hook 'emacspeak-eww-post-render-actions)
       (cond
        ((and (emacspeak-eww-current-url)
              emacspeak-eww-feed
              emacspeak-eww-style)
                                        ; this is a displayed feed
         (lexical-let
             ((p dtk-punctuation-mode)
              (r dtk-speech-rate)
              (u (emacspeak-eww-current-url))
              (s emacspeak-eww-style))
           (kill-buffer)
           (add-hook
            'emacspeak-web-post-process-hook
            #'(lambda ()
                (dtk-set-punctuations p)
                (dtk-set-rate r)
                (emacspeak-dtk-sync))
            'at-end)
           (emacspeak-feeds-feed-display u s 'speak)))
        ((and (emacspeak-eww-current-url) emacspeak-eww-url-template)
                                        ; this is a url template
         (lexical-let
             ((n emacspeak-eww-url-template)
              (p dtk-punctuation-mode)
              (r dtk-speech-rate))
           (add-hook
            'emacspeak-web-post-process-hook
            #'(lambda nil
                (dtk-set-punctuations p)
                (dtk-set-rate r)
                (emacspeak-dtk-sync))
            'at-end)
           (kill-buffer)
           (emacspeak-url-template-open (emacspeak-url-template-get  n))))
        (t ad-do-it))))

(loop
 for f in
 '(eww eww-reload eww-open-file)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Provide auditory feedback"
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'open-object)))))

(defvar emacspeak-eww-rename-result-buffer t
  "Result buffer is renamed to document title.")

(defun emacspeak-eww-after-render-hook ()
  "Setup Emacspeak for rendered buffer. "
  (let ((title (emacspeak-eww-current-title))
        (alt (dom-alternate-links (emacspeak-eww-current-dom))))
    (when (= 0 (length title)) (setq title "EWW: Untitled"))
    (when emacspeak-eww-rename-result-buffer (rename-buffer title 'unique))
    (when alt
      (put-text-property 0 2 'auditory-icon 'mark-object  header-line-format))
    (cond
     (emacspeak-web-post-process-hook
      (emacspeak-webutils-run-post-process-hook))
     (t (emacspeak-speak-mode-line)))))

(cond
 ((or (= emacs-major-version 25)
      (boundp  'eww-after-render-hook))      ; emacs 25
  (add-hook 'eww-after-render-hook 'emacspeak-eww-after-render-hook))
 (t
  (defadvice eww-render (after emacspeak pre act comp)
    "Setup Emacspeak for rendered buffer."
    (emacspeak-eww-after-render-hook))))

(defadvice eww-add-bookmark (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p) (emacspeak-auditory-icon 'mark-object)))

(defadvice eww-beginning-of-text (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'large-movement)))

(defadvice eww-end-of-text(after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p) (emacspeak-auditory-icon 'mark-object)))

(defadvice eww-bookmark-browse (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p) (emacspeak-auditory-icon 'open-object)))

(defadvice eww-bookmark-kill (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p) (emacspeak-auditory-icon 'delete-object)))

(defadvice eww-bookmark-quit (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p) (emacspeak-auditory-icon 'close-object)))

(defadvice eww-bookmark-yank(after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p) (emacspeak-auditory-icon 'yank-object)))

(defadvice eww-list-bookmarks(after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p) (emacspeak-auditory-icon 'open-object)))

(loop
 for f in
 '(eww-next-bookmark eww-previous-bookmark)
 do
 (eval
  `(defadvice ,f(after emacspeak pre act comp)
     "Provide auditory feedback."
     (when (ems-interactive-p) (emacspeak-auditory-icon 'select-object))
     (emacspeak-speak-line))))

(defadvice eww-quit(after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p) (emacspeak-auditory-icon 'close-object)))

(loop
 for f in
 '(eww-change-select
   eww-toggle-checkbox
   eww-submit)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Provide auditory feedback."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'button)))))

(loop
 for f in
 '(shr-next-link shr-previous-link)
 do
 (eval
  `(defadvice ,f (around emacspeak pre act comp)
     "Provide auditory feedback."
     (ems-with-messages-silenced ad-do-it)
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'button)
       (emacspeak-speak-region
        (point)
        (next-single-property-change (point) 'help-echo
                                     nil (point-max)))))))

;;; Handle emacspeak-we-url-executor

(defadvice eww-follow-link (around emacspeak pre act comp)
  "Respect emacspeak-we-url-executor if set."
  (emacspeak-auditory-icon 'button)
  (cond
   ((and (ems-interactive-p)
         (boundp 'emacspeak-we-url-executor)
         (fboundp emacspeak-we-url-executor)
         (y-or-n-p "Use custom executor? "))
    (let ((url (get-text-property (point) 'shr-url)))
      (unless url (error "No URL  under point"))
      (funcall emacspeak-we-url-executor url)))
   (t ad-do-it)))

;;}}}
;;{{{ xslt transform on request:

(defadvice eww-display-html (before emacspeak pre act comp)
  "Apply XSLT transform if requested."
  (declare (special emacspeak-web-pre-process-hook))
  (let ((orig (point)))
    (cond
     (emacspeak-web-pre-process-hook (emacspeak-webutils-run-pre-process-hook))
     ((and emacspeak-we-xsl-p emacspeak-we-xsl-transform)
      (emacspeak-xslt-region
       emacspeak-we-xsl-transform (point) (point-max)
       emacspeak-we-xsl-params)))
    (goto-char orig)))

;;}}}
;;{{{ DOM Structure In Rendered Buffer:

(loop
 for  tag in
 '(h1 h2 h3 h4 h5 h6 div                    ; sectioning
      ul ol dl                     ; Lists
      li dt dd p                   ; block-level: bullets, paras
      form blockquote              ; block-level
      a b it em span               ; in-line
      br hr                        ; separators
      th tr table)
 do
 (eval
  `
  (defadvice ,(intern (format "shr-tag-%s" tag)) (around emacspeak pre act comp)
    (let ((orig (point)))
      ad-do-it
      (let ((start
             (if (char-equal (following-char) ?\n)
                 (min (point-max) (1+ orig))
               orig))
            (end
             (if (> (point) orig)
                 (1- (point))
               (point))))
        (put-text-property start end
                           (quote ,tag) 'eww-tag)
        (when (memq (quote ,tag) '(h1 h2 h3 h4 h5 h6))
          (put-text-property start end 'h 'eww-tag)))))))

;;}}}
;;{{{ Advice readable
(defadvice eww-readable (around emacspeak pre act comp)
  "Speak contents."
  (let ((inhibit-read-only t))
    ad-do-it
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-speak-buffer)))

;;}}}
;;{{{  Customize image loading:

(defcustom emacspeak-eww-silence-images t
  "Set to nil if you want EWW to load images."
  :type 'boolean
  :group 'emacspeak-eww)

(defadvice eww-display-image (around emacspeak pre act comp)
  "Dont load images if asked to silence them."
  (unless emacspeak-eww-silence-images ad-do-it))

;;}}}
;;{{{ element, class, role, id caches:

(defvar emacspeak-eww-cache-updated nil
  "Records if caches are updated.")

(make-variable-buffer-local 'emacspeak-eww-cache-updated)

;;; Mark cache to be dirty if we restore history:

(defadvice eww-restore-history (after emacspeak pre act comp)
  "mark cache dirty."
  (setq emacspeak-eww-cache-updated nil)
  (emacspeak-eww-prepare-eww))

(defvar eww-id-cache nil
  "Cache of id values. Is buffer-local.")

(make-variable-buffer-local 'eww-id-cache)

(defvar eww-class-cache nil
  "Cache of class values. Is buffer-local.")

(make-variable-buffer-local 'eww-class-cache)

(defvar eww-role-cache nil
  "Cache of role values. Is buffer-local.")

(make-variable-buffer-local 'eww-role-cache)

(defvar eww-itemprop-cache nil
  "Cache of itemprop values. Is buffer-local.")

(make-variable-buffer-local 'eww-itemprop-cache)

(defvar eww-property-cache nil
  "Cache of property values. Is buffer-local.")

(make-variable-buffer-local 'eww-property-cache)

;;; Holds element names as strings.

(defvar eww-element-cache nil
  "Cache of element names. Is buffer-local.")

(make-variable-buffer-local 'eww-element-cache)

(defun eww-update-cache (dom)
  "Update element, role, class and id cache."
  (declare (special eww-element-cache eww-id-cache
                    eww-property-cache eww-itemprop-cache
                    eww-role-cache eww-class-cache emacspeak-eww-cache-updated))
  (when (listp dom)                     ; build cache
    (let ((id (dom-attr dom 'id))
          (class (dom-attr dom 'class))
          (role (dom-attr dom 'role))
          (itemprop (dom-attr dom 'itemprop))
          (property (dom-attr dom 'property))
          (el (symbol-name (dom-tag dom)))
          (children (dom-children dom)))
      (when id (pushnew id eww-id-cache))
      (when class (pushnew class eww-class-cache))
      (when itemprop (pushnew itemprop eww-itemprop-cache))
      (when role (pushnew role eww-role-cache))
      (when property (pushnew property eww-property-cache))
      (when el (pushnew el eww-element-cache))
      (when children (mapc #'eww-update-cache children)))
    (setq emacspeak-eww-cache-updated t)))

;;}}}
;;{{{ Filter DOM:

(defun emacspeak-eww-tag-article (dom)
  "Tag article, then render."
  (let ((start (point)))
    (shr-generic dom)
    (put-text-property start (point) 'article 'eww-tag)))

(defvar eww-shr-render-functions
  '((article . emacspeak-eww-tag-article)
    (title . eww-tag-title)
    (form . eww-tag-form)
    (input . eww-tag-input)
    (textarea . eww-tag-textarea)
    (body . eww-tag-body)
    (select . eww-tag-select)
    (link . eww-tag-link)
    (a . eww-tag-a))
  "Customize shr rendering for EWW.")

(defun eww-dom-keep-if (dom predicate)
  "Return filtered DOM  keeping nodes that match  predicate.
 Predicate receives the node to test."
  (cond
   ((not (listp dom)) nil)
   ((funcall predicate dom) dom)
   (t
    (let ((filtered
           (delq nil
                 (mapcar
                  #'(lambda (node) (eww-dom-keep-if node predicate))
                  (dom-children dom)))))
      (when filtered
        (push (dom-attributes dom) filtered)
        (push (dom-tag dom) filtered))))))

(defun eww-dom-remove-if (dom predicate)
  "Return filtered DOM  dropping  nodes that match  predicate.
 Predicate receives the node to test."
  (cond
   ((not (listp dom)) dom)
   ((funcall predicate dom) nil)
   (t
    (let
        ((filtered
          (delq nil
                (mapcar #'(lambda (node) (eww-dom-remove-if  node predicate))
                        (dom-children dom)))))
      (when filtered
        (push (dom-attributes dom) filtered)
        (push (dom-tag dom) filtered) filtered)))))

(defun eww-attribute-list-tester (attr-list)
  "Return predicate that tests for attr=value from members of
attr-value list for use as a DOM filter."
  (eval
   `#'(lambda (node)
        (let (attr  value found)
          (loop
           for pair in (quote ,attr-list)
           until found
           do
           (setq attr (first pair)
                 value (second pair))
           (setq found (string= (dom-attr  node attr) value)))
          (when found node)))))

(defun eww-attribute-tester (attr value)
  "Return predicate that tests for attr=value for use as a DOM filter."
  (eval
   `#'(lambda (node)
        (when
            (string= (dom-attr node (quote ,attr)) ,value) node))))

(defun eww-elements-tester (element-list)
  "Return predicate that tests for presence of element in element-list
for use as a DOM filter."
  (eval
   `#'(lambda (node)
        (when (memq (dom-tag node) (quote ,element-list)) node))))

(defun emacspeak-eww-view-helper  (filtered-dom)
  "View helper called by various filtering viewers."
  (declare (special emacspeak-eww-rename-result-buffer
                    eww-shr-render-functions))
  (let ((emacspeak-eww-rename-result-buffer nil)
        (url (emacspeak-eww-current-url))
        (title  (format "%s: Filtered" (emacspeak-eww-current-title)))
        (inhibit-read-only t)
        (shr-external-rendering-functions eww-shr-render-functions))
    (eww-save-history)
    (erase-buffer)
    (goto-char (point-min))
                                        ;(setq shr-base (shr-parse-base url))
    (shr-insert-document filtered-dom)
    (emacspeak-eww-set-dom filtered-dom)
    (emacspeak-eww-set-url url)
    (emacspeak-eww-set-title title)
    (set-buffer-modified-p nil)
    (goto-char (point-min))
    (setq buffer-read-only t))
  (eww-update-header-line-format)
  (emacspeak-auditory-icon 'open-object)
  (emacspeak-speak-buffer))

(defun ems-eww-read-list (reader)
  "Return list of values  read using reader."
  (let (value-list  value done)
    (loop
     until done
     do
     (setq value (funcall reader))
     (cond
      (value (pushnew   value value-list))
      (t (setq done t))))
    value-list))

(defsubst ems-eww-read-id ()
  "Return id value read from minibuffer."
  (declare (special eww-id-cache))
  (unless eww-id-cache (error "No id to filter."))
  (let ((value (completing-read "Value: " eww-id-cache nil 'must-match)))
    (unless (zerop (length value)) value)))

(defun eww-view-dom-having-id (&optional multi)
  "Display DOM filtered by specified id=value test.
Optional interactive arg `multi' prompts for multiple ids."
  (interactive "P")
  (emacspeak-eww-prepare-eww)
  (let ((dom (emacspeak-eww-current-dom))
        (filter (if multi #'dom-by-id-list #'dom-by-id))
        (id  (if multi
                 (ems-eww-read-list 'ems-eww-read-id)
               (ems-eww-read-id))))
    (setq dom (funcall filter dom id))
    (when dom
      (emacspeak-eww-view-helper
       (dom-html-from-nodes dom (emacspeak-eww-current-url))))))

(defun eww-view-dom-not-having-id (&optional multi)
  "Display DOM filtered by specified nodes not passing  id=value test.
Optional interactive arg `multi' prompts for multiple ids."
  (interactive "P")
  (emacspeak-eww-prepare-eww)
  (let ((dom
         (eww-dom-remove-if
          (emacspeak-eww-current-dom)
          (eww-attribute-list-tester
           (if multi
               (loop
                for i in (ems-eww-read-list 'ems-eww-read-id)
                collect (list 'id i))
             (list (list 'id (ems-eww-read-id))))))))
    (when dom (emacspeak-eww-view-helper (dom-html-add-base dom)))))

(defun ems-eww-read-attribute-and-value ()
  "Read attr-value pair and return as a list."
  (declare (special eww-id-cache eww-class-cache eww-role-cache
                    eww-property-cache eww-itemprop-cache))
  (unless (or eww-role-cache eww-id-cache eww-class-cache
              eww-itemprop-cache eww-property-cache)
    (error "No attributes to filter."))
  (let(attr-names attr value)
    (when eww-class-cache (push "class" attr-names))
    (when eww-id-cache (push "id" attr-names))
    (when eww-itemprop-cache (push "itemprop" attr-names))
    (when eww-property-cache (push "property" attr-names))
    (when eww-role-cache (push "role" attr-names))
    (setq attr (completing-read "Attr: " attr-names nil 'must-match))
    (unless (zerop (length attr))
      (setq attr (intern attr))
      (setq value
            (completing-read
             "Value: "
             (cond
              ((eq attr 'id) eww-id-cache)
              ((eq attr 'itemprop) eww-itemprop-cache)
              ((eq attr 'property) eww-property-cache)
              ((eq attr 'class)eww-class-cache)
              ((eq attr 'role)eww-role-cache))
             nil 'must-match))
      (list attr value))))

(defun eww-view-dom-having-attribute (&optional multi)
  "Display DOM filtered by specified attribute=value test.
Optional interactive arg `multi' prompts for multiple classes."
  (interactive "P")
  (emacspeak-eww-prepare-eww)
  (let ((dom
         (eww-dom-keep-if
          (dom-child-by-tag (emacspeak-eww-current-dom) 'html)
          (eww-attribute-list-tester
           (if multi
               (ems-eww-read-list 'ems-eww-read-attribute-and-value)
             (list  (ems-eww-read-attribute-and-value)))))))
    (when dom
      (dom-html-add-base dom   (emacspeak-eww-current-url))
      (emacspeak-eww-view-helper dom))))

(defun eww-view-dom-not-having-attribute (&optional multi)
  "Display DOM filtered by specified nodes not passing  attribute=value test.
Optional interactive arg `multi' prompts for multiple classes."
  (interactive "P")
  (emacspeak-eww-prepare-eww)
  (let ((dom
         (eww-dom-remove-if
          (dom-child-by-tag (emacspeak-eww-current-dom) 'html)
          (eww-attribute-list-tester
           (if multi
               (ems-eww-read-list 'ems-eww-read-attribute-and-value)
             (list  (ems-eww-read-attribute-and-value)))))))
    (when dom
      (dom-html-add-base dom   (emacspeak-eww-current-url))
      (emacspeak-eww-view-helper dom))))

(defsubst ems-eww-read-class ()
  "Return class value read from minibuffer."
  (declare (special eww-class-cache))
  (unless eww-class-cache (error "No class to filter."))
  (let ((value (completing-read "Value: " eww-class-cache nil 'must-match)))
    (unless (zerop (length value)) value)))

(defun eww-view-dom-having-class (&optional multi)
  "Display DOM filtered by specified class=value test.
Optional interactive arg `multi' prompts for multiple classes."
  (interactive "P")
  (emacspeak-eww-prepare-eww)
  (let ((dom  (emacspeak-eww-current-dom))
        (filter (if multi #'dom-by-class-list #'dom-by-class))
        (class  (if multi
                    (ems-eww-read-list 'ems-eww-read-class)
                  (ems-eww-read-class))))
    (setq dom (funcall filter dom class))
    (when dom
      (emacspeak-eww-view-helper
       (dom-html-from-nodes dom (emacspeak-eww-current-url))))))

(defun eww-view-dom-not-having-class (&optional multi)
  "Display DOM filtered by specified nodes not passing   class=value test.
Optional interactive arg `multi' prompts for multiple classes."
  (interactive "P")
  (emacspeak-eww-prepare-eww)
  (let ((dom
         (eww-dom-remove-if
          (emacspeak-eww-current-dom)
          (eww-attribute-list-tester
           (if multi
               (loop
                for c in (ems-eww-read-list 'ems-eww-read-class)
                collect (list 'class c))
             (list (list 'class (ems-eww-read-class))))))))
    (when dom (emacspeak-eww-view-helper   (dom-html-add-base dom)))))

(defsubst ems-eww-read-role ()
  "Return role value read from minibuffer."
  (declare (special eww-role-cache))
  (unless eww-role-cache (error "No role to filter."))
  (let ((value (completing-read "Value: " eww-role-cache nil 'must-match)))
    (unless (zerop (length value)) value)))

(defsubst ems-eww-read-property ()
  "Return property value read from minibuffer."
  (declare (special eww-property-cache))
  (unless eww-property-cache (error "No property to filter."))
  (let ((value (completing-read "Value: " eww-property-cache nil 'must-match)))
    (unless (zerop (length value)) value)))

(defsubst ems-eww-read-itemprop ()
  "Return itemprop value read from minibuffer."
  (declare (special eww-itemprop-cache))
  (unless eww-itemprop-cache (error "No itemprop to filter."))
  (let ((value (completing-read "Value: " eww-itemprop-cache nil 'must-match)))
    (unless (zerop (length value)) value)))

(defun eww-view-dom-having-role (multi)
  "Display DOM filtered by specified role=value test.
Optional interactive arg `multi' prompts for multiple classes."
  (interactive "P")
  (emacspeak-eww-prepare-eww)
  (let ((dom (emacspeak-eww-current-dom))
        (filter  (if multi #'dom-by-role-list #'dom-by-role))
        (role  (if multi
                   (ems-eww-read-list 'ems-eww-read-role)
                 (ems-eww-read-role))))
    (setq dom (funcall filter dom role))
    (when dom
      (emacspeak-eww-view-helper
       (dom-html-from-nodes dom (emacspeak-eww-current-url))))))

(defun eww-view-dom-not-having-role (multi)
  "Display DOM filtered by specified  nodes not passing   role=value test.
Optional interactive arg `multi' prompts for multiple classes."
  (interactive "P")
  (declare (special  eww-shr-render-functions))
  (emacspeak-eww-prepare-eww)
  (let ((dom
         (eww-dom-remove-if
          (emacspeak-eww-current-dom)
          (eww-attribute-list-tester
           (if multi
               (loop
                for r in (ems-eww-read-list 'ems-eww-read-role)
                collect (list 'role r))
             (list (list 'role (ems-eww-read-role))))))))
    (when dom (emacspeak-eww-view-helper (dom-html-add-base dom)))))

(defun eww-view-dom-having-property (multi)
  "Display DOM filtered by specified property=value test.
Optional interactive arg `multi' prompts for multiple classes."
  (interactive "P")
  (emacspeak-eww-prepare-eww)
  (let ((dom (emacspeak-eww-current-dom))
        (filter  (if multi #'dom-by-property-list #'dom-by-property))
        (property  (if multi
                       (ems-eww-read-list 'ems-eww-read-property)
                     (ems-eww-read-property))))
    (setq dom (funcall filter dom property))
    (when dom
      (emacspeak-eww-view-helper
       (dom-html-from-nodes dom (emacspeak-eww-current-url))))))

(defun eww-view-dom-not-having-property (multi)
  "Display DOM filtered by specified  nodes not passing   property=value test.
Optional interactive arg `multi' prompts for multiple classes."
  (interactive "P")
  (declare (special  eww-shr-render-functions))
  (emacspeak-eww-prepare-eww)
  (let ((dom
         (eww-dom-remove-if
          (emacspeak-eww-current-dom)
          (eww-attribute-list-tester
           (if multi
               (loop
                for r in (ems-eww-read-list 'ems-eww-read-property)
                collect (list 'property r))
             (list (list 'property (ems-eww-read-property))))))))
    (when dom (emacspeak-eww-view-helper (dom-html-add-base dom)))))

(defun eww-view-dom-having-itemprop (multi)
  "Display DOM filtered by specified itemprop=value test.
Optional interactive arg `multi' prompts for multiple classes."
  (interactive "P")
  (emacspeak-eww-prepare-eww)
  (let ((dom (emacspeak-eww-current-dom))
        (filter  (if multi #'dom-by-itemprop-list #'dom-by-itemprop))
        (itemprop  (if multi
                       (ems-eww-read-list 'ems-eww-read-itemprop)
                     (ems-eww-read-itemprop))))
    (setq dom (funcall filter dom itemprop))
    (when dom
      (emacspeak-eww-view-helper
       (dom-html-from-nodes dom (emacspeak-eww-current-url))))))

(defun eww-view-dom-not-having-itemprop (multi)
  "Display DOM filtered by specified  nodes not passing   itemprop=value test.
Optional interactive arg `multi' prompts for multiple classes."
  (interactive "P")
  (declare (special  eww-shr-render-functions))
  (emacspeak-eww-prepare-eww)
  (let ((dom
         (eww-dom-remove-if
          (emacspeak-eww-current-dom)
          (eww-attribute-list-tester
           (if multi
               (loop
                for r in (ems-eww-read-list 'ems-eww-read-itemprop)
                collect (list 'itemprop r))
             (list (list 'itemprop (ems-eww-read-itemprop))))))))
    (when dom (emacspeak-eww-view-helper (dom-html-add-base dom)))))
(defsubst ems-eww-read-element ()
  "Return element  value read from minibuffer."
  (declare (special eww-element-cache))
  (let ((value (completing-read "Value: " eww-element-cache nil 'must-match)))
    (unless (zerop (length value)) (intern value))))

(defun eww-view-dom-having-elements (&optional multi)
  "Display DOM filtered by specified elements.
Optional interactive prefix arg `multi' prompts for multiple elements."
  (interactive "P")
  (emacspeak-eww-prepare-eww)
  (let ((dom (emacspeak-eww-current-dom))
        (filter  (if multi #'dom-by-tag-list #'dom-by-tag))
        (tag (if multi
                 (ems-eww-read-list 'ems-eww-read-element)
               (ems-eww-read-element))))
    (setq dom (funcall filter dom tag))
    (cond
     (dom
      (emacspeak-eww-view-helper
       (dom-html-from-nodes dom (emacspeak-eww-current-url))))
     (t (message "Filtering failed.")))))

(defun eww-view-dom-not-having-elements (multi)
  "Display DOM filtered by specified nodes not passing   el list.
Optional interactive prefix arg `multi' prompts for multiple elements."
  (interactive "P")
  (emacspeak-eww-prepare-eww)
  (let ((dom
         (eww-dom-remove-if
          (emacspeak-eww-current-dom)
          (eww-elements-tester
           (if multi
               (ems-eww-read-list 'ems-eww-read-element)
             (list  (ems-eww-read-element)))))))
    (when dom (emacspeak-eww-view-helper  (dom-html-add-base dom)))))

(defun emacspeak-eww-restore ()
  "Restore buffer to pre-filtered canonical state."
  (interactive)
  (declare (special eww-history eww-history-position))
  (eww-restore-history(elt eww-history eww-history-position))
  (emacspeak-speak-mode-line)
  (emacspeak-auditory-icon 'open-object))

;;}}}
;;{{{ Filters For Non-interactive  Use:

(defun eww-display-dom-filter-helper (filter arg)
  "Helper for display filters."
  (emacspeak-eww-prepare-eww)
  (let ((dom (funcall  filter  (emacspeak-eww-current-dom)arg)))
    (when dom (emacspeak-eww-view-helper (dom-html-from-nodes dom (emacspeak-eww-current-url))))))

(defun eww-display-dom-by-id (id)
  "Display DOM filtered by specified id."

  (eww-display-dom-filter-helper #'dom-by-id  id))

(defun eww-display-dom-by-id-list (id-list)
  "Display DOM filtered by specified id-list."

  (eww-display-dom-filter-helper #'dom-by-id-list  id-list))

(defun eww-display-dom-by-class (class)
  "Display DOM filtered by specified class."

  (eww-display-dom-filter-helper #'dom-by-class  class))

(defun eww-display-dom-by-class-list (class-list)
  "Display DOM filtered by specified class-list."

  (eww-display-dom-filter-helper #'dom-by-class-list  class-list))

(defun eww-display-dom-by-element (tag)
  "Display DOM filtered by specified tag."
  (eww-display-dom-filter-helper #'dom-by-tag  tag))

(defun eww-display-dom-by-element-list (tag-list)
  "Display DOM filtered by specified element-list."

  (eww-display-dom-filter-helper #'dom-by-tag-list  tag-list))

(defun eww-display-dom-by-role (role)
  "Display DOM filtered by specified role."
  (eww-display-dom-filter-helper #'dom-by-role  role))

(defun eww-display-dom-by-role-list (role-list)
  "Display DOM filtered by specified role-list."
  (eww-display-dom-filter-helper #'dom-by-role-list  role-list))

;;}}}
;;{{{ Element Navigation:
;;; Try only storing symbols, not strings.

(defvar emacspeak-eww-element-navigation-history nil
  "History for element navigation.")
(defsubst emacspeak-eww-icon-for-element (el)
  "Return auditory icon for element `el'."
  (cond
   ((memq el '(li dt)) 'item)
   ((memq el '(h h1 h2 h3 h4 h5 h6)) 'section)
   ((memq el '(p ul ol dd dl)) 'paragraph)
   (t 'large-movement)))

(defun emacspeak-eww-next-element (el)
  "Move forward to the next specified element."
  (interactive
   (list
    (progn
      (emacspeak-eww-prepare-eww)
      (intern
       (completing-read "Element: "
                        eww-element-cache nil 'must-match
                        nil 'emacspeak-eww-element-navigation-history)))))
  (declare (special eww-element-cache emacspeak-eww-element-navigation-history))
  (let*
      ((start
        (or
         (when (get-text-property (point) el)
           (next-single-property-change (point) el))
         (point)))
       (next (next-single-property-change start  el)))
    (cond
     (next
      (goto-char next)
      (setq emacspeak-eww-element-navigation-history
            (delq el emacspeak-eww-element-navigation-history))
      (push  el emacspeak-eww-element-navigation-history)
      (emacspeak-auditory-icon (emacspeak-eww-icon-for-element el))
      (emacspeak-speak-region next (next-single-property-change next el)))
     (t (message "No next %s" el)))))

(defun emacspeak-eww-previous-element (el)
  "Move backward  to the previous  specified element."
  (interactive
   (list
    (progn
      (emacspeak-eww-prepare-eww)
      (intern
       (completing-read "Element: " eww-element-cache nil 'must-match
                        nil 'emacspeak-eww-element-navigation-history)))))
  (declare (special eww-element-cache
                    emacspeak-eww-element-navigation-history))
  (let* ((start
          (or
           (when (get-text-property  (point) el)
             (previous-single-property-change (1+ (point)) el))
           (point)))
         (previous (previous-single-property-change  start  el)))
    (cond
     (previous
      (goto-char (or (previous-single-property-change previous el) (point-min)))
      (setq emacspeak-eww-element-navigation-history
            (delq el emacspeak-eww-element-navigation-history))
      (push  el emacspeak-eww-element-navigation-history)
      (emacspeak-auditory-icon (emacspeak-eww-icon-for-element el))
      (emacspeak-speak-region (point) previous))
     (t (message "No previous  %s" el)))))

(defun emacspeak-eww-next-element-from-history ()
  "Uses element navigation history to decide where we jump."
  (interactive)
  (declare (special emacspeak-eww-element-navigation-history))
  (cond
   (emacspeak-eww-element-navigation-history
    (emacspeak-eww-next-element
     (car emacspeak-eww-element-navigation-history)))
   (t (error "No elements in navigation history"))))

(defun emacspeak-eww-previous-element-from-history ()
  "Uses element navigation history to decide where we jump."
  (interactive)
  (declare (special emacspeak-eww-element-navigation-history))
  (cond
   (emacspeak-eww-element-navigation-history
    (emacspeak-eww-previous-element
     (car emacspeak-eww-element-navigation-history)))
   (t (error "No elements in navigation history"))))

(defsubst emacspeak-eww-here-tags ()
  "Return list of enclosing tags at point."
  (let* ((eww-tags (text-properties-at (point))))
    (loop
     for i from 0 to (1- (length eww-tags)) by 2
     if (eq (plist-get eww-tags (nth i eww-tags)) 'eww-tag)
     collect (nth i eww-tags))))

(defsubst emacspeak-eww-read-tags-like-this(&optional prompt)
  "Read tag for like-this navigation."
  (let ((tags (emacspeak-eww-here-tags)))
    (cond
     ((null tags) (error "No enclosing element here."))
     ((= 1 (length tags))  (first tags))
     (t (intern
         (completing-read
          (or prompt "Jump to: ")
          (mapcar #'symbol-name tags)
          nil t
          nil emacspeak-eww-element-navigation-history))))))

(defun emacspeak-eww-next-element-like-this (element)
  "Moves to next element like current.
Prompts if content at point is enclosed by multiple elements."
  (interactive
   (list (emacspeak-eww-read-tags-like-this)))
  (emacspeak-eww-next-element  element))

(defun emacspeak-eww-previous-element-like-this (element)
  "Moves to next element like current.
Prompts if content at point is enclosed by multiple elements."
  (interactive
   (list (emacspeak-eww-read-tags-like-this)))
  (emacspeak-eww-previous-element  element))

(defun emacspeak-eww-speak-this-element (element)
  "Speaks  to next element like current.
Uses most recently navigated structural unit.
Otherwise, prompts if content at point is enclosed by multiple elements."
  (interactive
   (list
    (or (car emacspeak-eww-element-navigation-history)
        (emacspeak-eww-read-tags-like-this "Read: "))))
  (let ((start (point)))
    (save-excursion
      (emacspeak-eww-next-element  element)
      (emacspeak-auditory-icon 'select-object)
      (emacspeak-speak-region start (point)))))

(loop
 for  f in
 '(h h1 h2 h3 h4 h5 h6 li table ol ul p)
 do
 (eval
  `(defun ,(intern (format "emacspeak-eww-next-%s" f)) (&optional speak)
     ,(format "Move forward to the next %s.
Optional interactive prefix arg speaks the structural unit." f)
     (interactive "P")
     (funcall 'emacspeak-eww-next-element (intern ,(format "%s" f)))
     (when speak
       (emacspeak-eww-speak-this-element (intern ,(format "%s" f))))))
 (eval
  `(defun ,(intern (format "emacspeak-eww-previous-%s" f)) (&optional speak)
     ,(format "Move backward to the next %s.
Optional interactive prefix arg speaks the structural unit." f)
     (interactive "P")
     (funcall 'emacspeak-eww-previous-element (intern ,(format "%s" f)))
     (when speak
       (emacspeak-eww-speak-this-element (intern ,(format "%s" f)))))))

;;}}}
;;{{{ Google Search  fixes:

(loop
 for f in
 '(url-retrieve-internal  url-truncate-url-for-viewing eww)
 do
 (eval
  `
  (defadvice ,f (before cleanup-url  pre act comp)
    "Canonicalize Google search URLs."
    (let ((u (ad-get-arg 0)))
      (cond
       ((and u (stringp u)
             (string-prefix-p (emacspeak-google-result-url-prefix) u))
        (ad-set-arg 0 (emacspeak-google-canonicalize-result-url u))))))))

(defadvice shr-copy-url (around emacspeak pre act comp)
  "Canonicalize Google URLs"
  ad-do-it
  (when (ems-interactive-p)
    (let ((u (car kill-ring)))
      (when
          (and u (stringp u)
               (string-prefix-p (emacspeak-google-result-url-prefix) u))
        (kill-new  (emacspeak-google-canonicalize-result-url u))))))

;;}}}
;;{{{ Masquerade

;;}}}
;;{{{  Google Knowledge Card:

(defun emacspeak-eww-google-knowledge-card ()
  "Show just the knowledge card.
Warning, this is fragile, and depends on a stable id for the
  knowledge card."
  (interactive)
  (declare (special eww-shr-render-functions emacspeak-eww-masquerade))
  (unless emacspeak-eww-masquerade
    (error "Turn on  masquerade mode for knowledge cards."))
  (unless (eq major-mode 'eww-mode)
    (error "This command is only available in EWW"))
  (unless  emacspeak-google-toolbelt
    (error "This doesn't look like a Google results page."))
  (let*
      ((emacspeak-eww-rename-result-buffer nil)
       (value "rhs_block")
       (media "rg_meta")
       (inhibit-read-only t)
       (dom
        (eww-dom-remove-if
         (eww-dom-keep-if
          (emacspeak-eww-current-dom) (eww-attribute-tester 'id value))
         (eww-attribute-tester 'class media)))
       (shr-external-rendering-functions eww-shr-render-functions))
    (cond
     (dom
      (eww-save-history)
      (erase-buffer)
      (goto-char (point-min))
      (shr-insert-document dom)
      (set-buffer-modified-p nil)
      (flush-lines "^ *$")
      (goto-char (point-min))
      (setq buffer-read-only t)
      (emacspeak-speak-buffer))
     (t (message "Knowledge Card not found.")))
    (emacspeak-auditory-icon 'open-object)))

(define-key emacspeak-google-keymap "k" 'emacspeak-eww-google-knowledge-card)
(define-key emacspeak-google-keymap "e" 'emacspeak-eww-masquerade)
;;}}}
;;{{{ Speech-enable EWW buffer list:

(defsubst emacspeak-eww-speak-buffer-line ()
  "Speak EWW buffer line."
  (assert (eq major-mode 'eww-buffers-mode) nil "Not in an EWW buffer listing.")
  (let ((buffer (get-text-property (line-beginning-position) 'eww-buffer)))
    (if buffer
        (dtk-speak (buffer-name buffer))
      (message "Cant find an EWW buffer for this line. "))))

(defadvice eww-list-buffers (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'open-object)
    (emacspeak-eww-speak-buffer-line)))

(defadvice eww-buffer-kill (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'close-object)
    (emacspeak-eww-speak-buffer-line)))

(defadvice eww-buffer-select (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-speak-mode-line)
    (emacspeak-auditory-icon 'open-object)))

(loop
 for f in
 '(eww-buffer-show-next eww-buffer-show-previous)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act comp)
     "Provide auditory feedback."
     (when (ems-interactive-p)
       (emacspeak-auditory-icon 'select-object)
       (emacspeak-eww-speak-buffer-line)))))

;;}}}
;;{{{  EWW Filtering shortcuts:

(defun emacspeak-eww-transcode ()
  "Apply appropriate transcoding rules to current DOM."
  (interactive)
  (declare (special eww-element-cache eww-role-cache))
  (emacspeak-eww-prepare-eww)
  (let ((dom (emacspeak-eww-current-dom))
        (article-p (member "article" eww-element-cache))
        (main-p (member "main" eww-role-cache)))
    (cond
     (article-p
      (message "articles")
      (setq dom (dom-by-tag dom 'article))
      (emacspeak-eww-view-helper
       (dom-html-from-nodes dom (emacspeak-eww-current-url))))
     (main-p
      (message "role.main")
      (setq dom (dom-by-role dom "main"))
      (emacspeak-eww-view-helper
       (dom-html-from-nodes dom (emacspeak-eww-current-url))))
     (t
      (message "headers and paragraphs")
      (setq dom (dom-by-tag-list dom '(p h1 h2 h3 h4)))
      (emacspeak-eww-view-helper
       (dom-html-from-nodes dom (emacspeak-eww-current-url)))))))

;;}}}
;;{{{ Tags At Point:

(defun emacspeak-eww-tags-at-point ()
  "Display tags at point."
  (interactive)
  (emacspeak-eww-prepare-eww)
  (let ((props (text-properties-at (point)))
        (tags nil))
    (setq tags
          (loop
           for i from 0 to (length props) by 2
           if (eq 'eww-tag (elt  props (+ 1 i))) collect (elt props i)))
    (print tags)
    (dtk-speak-list tags)))

;;}}}
;;{{{ Phantom:

(defvar emacspeak-eww-phantom-get
  (expand-file-name "phantom/pget.js" emacspeak-directory)
  "Name of PhantomJS script that implements wget-like retrieval.")
(defvar emacspeak-eww-phantom-js
  (executable-find "phantomjs")
  "Name of PhantomJS executable.")

(defun emacspeak-eww-phantom (url)
  "Retrieve `url'  using PhantomJS and render with EWW."
  (interactive
   (list
    (emacspeak-webutils-read-this-url)))
  (assert emacspeak-eww-phantom-js  nil "Please install phantomjs first.")
  (assert emacspeak-eww-phantom-get nil "PhantomJS script not found.")
  (with-temp-buffer
    (shell-command
     (format "%s %s '%s' 2> /dev/null "
             emacspeak-eww-phantom-js emacspeak-eww-phantom-get url)
     (current-buffer))
    (goto-char (point-min))
    (insert
     (format "<base href='%s'/>" url))
    (browse-url-of-buffer)))

;;}}}
;;{{{ Handling Media (audio/video)

;;; This should ideally be handled through mailcap.
;;; At present, EWW sets  eww-use-external-browser-for-content-type
;;; to match audio/video (only) and hands those off to eww-browse-with-external-browser.
;;; Below, we advice eww-browse-with-external-browser to use emacspeak-m-player instead.
(defadvice eww-browse-with-external-browser(around emacspeak pre act comp)
  "Use our m-player integration."
  (let ((url (ad-get-arg 0))
        (media-p (string-match emacspeak-media-extensions url)))
    (emacspeak-m-player url (not media-p))))

;;}}}
(provide 'emacspeak-eww)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
