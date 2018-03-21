;;; emacspeak-info.el --- Speech enable Info -- Emacs' online documentation viewer
;;; $Author: tv.raman.tv $
;;; Description:  Speech-enable Emacs Info Reader.
;;; Keywords:emacspeak, audio interface to emacs
;;{{{  LCD Archive entry:

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu
;;; A speech interface to Emacs |
;;; $Date: 2007-08-25 18:28:19 -0700 (Sat, 25 Aug 2007) $ |
;;;  $Revision: 4558 $ |
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
;;{{{ Introduction:

;;; Commentary:

;;; This module speech-enables the Emacs Info Reader.
;;; Code:

;;}}}
;;{{{ requires

(require 'emacspeak-preamble)
(require 'info)

;;}}}
;;{{{  Voices

(voice-setup-add-map
 '(
   (Info-quoted voice-lighten)
   (info-index-match 'voice-bolden-medium)
   (info-title-1 voice-bolden-extra)
   (info-title-2 voice-bolden-medium)
   (info-title-3 voice-bolden)
   (info-title-4 voice-lighten)
   (info-header-node voice-smoothen)
   (info-header-xref voice-brighten)
   (info-menu-header voice-bolden-medium)
   (info-node voice-monotone)
   (info-xref voice-animate-extra)
   (info-menu-star voice-brighten)
   (info-menu-header voice-bolden)
   (info-xref-visited voice-animate-medium)))

;;}}}
;;{{{ advice

(defcustom  emacspeak-info-select-node-speak-chunk 'node
  "*Specifies how much of the selected node gets spoken.
Possible values are:
screenfull  -- speak the displayed screen
node -- speak the entire node."
  :type '(menu-choice
          (const :tag "First screenfull" screenfull)
          (const :tag "Entire node" node))
  :group 'emacspeak-info)

(defsubst emacspeak-info-speak-current-window ()
  "Speak current window in info buffer."
  (let ((start  (point))
        (window (get-buffer-window (current-buffer))))
    (save-excursion
      (forward-line (window-height window))
      (emacspeak-speak-region start (point)))))

(defun emacspeak-info-visit-node()
  "Apply requested action upon visiting a node."
  (declare (special emacspeak-info-select-node-speak-chunk))
  (emacspeak-auditory-icon 'select-object)
  (cond
   ((eq emacspeak-info-select-node-speak-chunk 'screenfull)
    (emacspeak-info-speak-current-window))
   ((eq emacspeak-info-select-node-speak-chunk 'node)
    (emacspeak-speak-buffer))
   (t (emacspeak-speak-line))))

(loop
 for f in
 '(info info-display-manual Info-select-node
        Info-follow-reference Info-goto-node info-emacs-manual
        Info-top-node Info-menu-last-node  Info-final-node Info-up
        Info-goto-emacs-key-command-node Info-goto-emacs-command-node
        Info-history Info-virtual-index Info-directory Info-help
        Info-nth-menu-item
        Info-menu Info-follow-nearest-node
        Info-history-back Info-history-forward
        Info-backward-node Info-forward-node
        Info-next Info-prev)
 do
 (eval
  `(defadvice ,f (after emacspeak pre act)
     " Speak the selected node based on setting of
emacspeak-info-select-node-speak-chunk"
     (when (ems-interactive-p) (emacspeak-info-visit-node)))))

(defadvice Info-search (after emacspeak pre act comp)
  "Provide auditory feedback."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'search-hit)
    (emacspeak-speak-line)))

(defadvice Info-scroll-up (after emacspeak pre act)
  "Speak the screenful."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'scroll)
    (let ((start  (point))
          (window (get-buffer-window (current-buffer))))
      (save-excursion
        (forward-line (window-height window))
        (emacspeak-speak-region start (point))))))

(defadvice Info-scroll-down (after emacspeak pre act)
  "Speak the screenful."
  (when (ems-interactive-p)
    (emacspeak-auditory-icon 'scroll)
    (let ((start  (point))
          (window (get-buffer-window (current-buffer))))
      (save-excursion
        (forward-line (window-height window))
        (emacspeak-speak-region start (point))))))

(defadvice Info-exit (after emacspeak pre act)
  "Play an auditory icon to close info,
and then cue the next selected buffer."
  (when (ems-interactive-p)
    (dtk-stop)
    (emacspeak-auditory-icon 'close-object)
    (with-current-buffer (window-buffer)
      (emacspeak-speak-mode-line))))

(loop for f in
      '(Info-next-reference Info-prev-reference)
      do
      (eval
       `(defadvice ,f (after emacspeak pre act)
          "Play an auditory icon and speak the line. "
          (when (ems-interactive-p)
            (emacspeak-auditory-icon 'large-movement)
            (emacspeak-speak-line)))))

;;;###autoload
(defun emacspeak-info-wizard (node-spec)
  "Read a node spec from the minibuffer and launch
Info-goto-node.
See documentation for command `Info-goto-node' for details on
node-spec."
  (interactive
   (list
    (let ((completion-ignore-case t))
      (info-initialize)
      (completing-read "Node: "
                       (apply 'Info-build-node-completions
                                (when (fboundp 'info--manual-names)
                                  (list
                                   (completing-read "File: " (info--manual-names)
                                                    nil t))))
                       nil t))))
  (Info-goto-node node-spec)
  (emacspeak-info-visit-node))

;;}}}
;;{{{ Speak header line if hidden

(defun emacspeak-info-speak-header ()
  "Speak info header line."
  (interactive)
  (declare (special Info-use-header-line
                    Info-header-line))
  (if (and (boundp 'Info-use-header-line)
           (boundp 'Info-header-line)
           Info-use-header-line
           Info-header-line)
      (dtk-speak Info-header-line)
    (save-excursion
      (goto-char (point-min))
      (when (invisible-p (line-end-position))
        (forward-line))
      (emacspeak-speak-line))))

;;}}}
;;{{{ Inhibit spurious speech feedback

(defadvice Info-check-pointer  (around emacspeak pre act comp)
  "Silence emacspeak during call."
  (let ((emacspeak-speak-messages nil)
        (emacspeak-speak-errors nil)
        (emacspeak-use-auditory-icons nil))
    ad-do-it))

;;}}}
;;{{{ keymaps

(declaim (special Info-mode-map))
(define-key Info-mode-map "T" 'emacspeak-info-speak-header)
(define-key Info-mode-map "'" 'emacspeak-speak-rest-of-buffer)

;;}}}
(provide  'emacspeak-info)
;;{{{  emacs local variables

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: nil
;;; end:

;;}}}
