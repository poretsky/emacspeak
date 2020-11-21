;;; emacspeak-websearch.el --- search utilities  -*- lexical-binding: t; -*-
;;; $Id$
;;; $Author: tv.raman.tv $
;;; Description:  Emacspeak extension to make Web searching convenient
;;; Keywords: Emacspeak, WWW interaction
;;{{{  LCD Archive entry:

;;; LCD Archive Entry:
;;; emacspeak| T. V. Raman |raman@cs.cornell.edu
;;; A speech interface to Emacs |
;;; $Date: 2008-08-14 11:23:31 -0700 (Thu, 14 Aug 2008) $ |
;;;  $Revision: 4625 $ |
;;; Location undetermined
;;;

;;}}}
;;{{{  Copyright:
;;;Copyright (C) 1995 -- 2018, T. V. Raman
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

;;{{{ required modules
(require 'cl-lib)
(cl-declaim  (optimize  (safety 0) (speed 3)))
(require 'emacspeak-preamble)
(require 'emacspeak-feeds)
(require 'emacspeak-webutils)
(require 'eww)
(require 'emacspeak-eww)
(require 'emacspeak-google)
(require 'gweb)
(require  'emacspeak-we)
(require 'calendar)

;;}}}
;;{{{  Introduction:

;;; Commentary:

;;; This module provides utility functions for searching the WWW

;;; Code:

;;}}}
;;{{{ Forward Declarations:
(defvar emacspeak-websearch-curl-program
  (executable-find "curl")
  "Curl executable.")

(defvar emacspeak-wizards-personal-portfolio)

(declare-function gweb-google-autocomplete "gweb" (&optional prompt))
(declare-function calendar-astro-date-string "cal-julian" (&optional date))
;;}}}
;;{{{ searcher table
;;;###autoload
(defgroup emacspeak-websearch nil
  "Websearch tools for the Emacspeak desktop."
  :group 'emacspeak)
(defvar emacspeak-websearch-table (make-hash-table)
  "Table holding mapping from search engine names to appropriate searcher functions.")

(defun emacspeak-websearch-set-searcher  (engine searcher)
  (cl-declare (special emacspeak-websearch-table))
  (setf (gethash engine emacspeak-websearch-table) searcher))

(defun emacspeak-websearch-get-searcher (engine)
  (cl-declare (special emacspeak-websearch-table))
  (gethash engine emacspeak-websearch-table))

;;}}}
;;{{{ Key table

(defvar emacspeak-websearch-keytable (make-hash-table)
  "Table holding mapping from keys to appropriate search engine names.")

(defun emacspeak-websearch-set-key  (key engine)
  (cl-declare (special emacspeak-websearch-keytable))
  (setf (gethash key emacspeak-websearch-keytable) engine))

(defun emacspeak-websearch-get-engine (key)
  (cl-declare (special emacspeak-websearch-keytable))
  (gethash key emacspeak-websearch-keytable))

;;}}}
;;{{{ top-level dispatch
;;;###autoload
(defun emacspeak-websearch-help ()
  "Displays key mapping used by Emacspeak Websearch."
  (interactive)
  (let ((map (cl-loop for key being the hash-keys of
                      emacspeak-websearch-keytable
                      collect
                      (cons key (gethash key emacspeak-websearch-keytable)))))
    (setq map (sort map
                    #'(lambda (a b)
                        (< (car a)
                           (car b)))))
    (with-output-to-temp-buffer "*Help*"
      (with-current-buffer "*Help*"
        (princ "Websearch Keys:\n\n")
        (cl-loop for m in map
                 do
                 (princ (key-description (list (car m))))
                 (move-to-column 16)
                 (princ "`")
                 (princ (emacspeak-websearch-get-searcher (cdr m)))
                 (princ "'")
                 (princ "\n"))
        (help-setup-xref
         (list #'emacspeak-websearch-help)
         (called-interactively-p 'interactive))))
    (pop-to-buffer "*Help*")
    (help-mode)
    (goto-char (point-min))
    (emacspeak-speak-line)
    (emacspeak-auditory-icon 'help)))

(emacspeak-websearch-set-searcher  'help
                                   'emacspeak-websearch-help)

(emacspeak-websearch-set-key ?? 'help)
;;;###autoload
(defun emacspeak-websearch-dispatch  ()
  " Press `?' to list available search engines.
When using supported browsers,  this interface attempts to speak the most relevant information on the result page."
  (interactive)
  (let ((engine nil)
        (searcher nil))
    (while (null engine)
      (setq engine
            (emacspeak-websearch-get-engine
             (read-char
              (concat "Websearch? "
                      (documentation this-command))))))
    (setq searcher (emacspeak-websearch-get-searcher engine))
    (if searcher
        (call-interactively searcher)
      (error "I do not know how to search using %s" engine))))

;;}}}
;;{{{ helpers

;;{{{ helpers to read the query

(defvar emacspeak-websearch-history nil
  "Holds history of search queries.")

(defun emacspeak-websearch-read-query (prompt &optional
                                              default
                                              initial)
  (let ((answer
         (read-from-minibuffer
          prompt
          initial  nil nil
          (car emacspeak-websearch-history)
          (or default (word-at-point)))))
    (cl-pushnew answer  emacspeak-websearch-history :test #'string=)
    answer))

;;}}}
;;{{{ post processer hook

;;}}}

;;}}}
;;{{{ websearch utilities

;;{{{ Computer Science Bibliography

(emacspeak-websearch-set-searcher 'biblio
                                  'emacspeak-websearch-biblio-search)

(emacspeak-websearch-set-key 2 'biblio)

(defvar emacspeak-websearch-biblio-uri
  "http://liinwww.ira.uka.de/searchbib/index?partial=on&case=on&results=citation&maxnum=200&query="
  "URI to search the Computer Science Bibliographies.")

;;;###autoload
(defun emacspeak-websearch-biblio-search (query)
  "Search Computer Science Bibliographies."
  (interactive
   (list
    (emacspeak-websearch-read-query "Search CS Bibliographies  for: ")))
  (cl-declare (special emacspeak-websearch-biblio-uri))
  (browse-url
   (concat emacspeak-websearch-biblio-uri
           (url-hexify-string query)))
  (emacspeak-webutils-post-process
   query
   'emacspeak-speak-line))

;;}}}
;;{{{ CiteSeer Citation index

(defvar emacspeak-websearch-citeseer-uri
  "http://citeseer.nj.nec.com/cs?"
  "URI for searching CiteSeer index. ")

(defvar emacspeak-websearch-citeseer-citation-options
  "cs=1&submit=Search+Citations&cf=Any&co=Citations&cm=50"
  "* Options for performing a citation search on CiteSeer.")

(defvar emacspeak-websearch-citeseer-article-options
  "cs=1&cf=Author&co=Citations&cm=50&submit=Search+Indexed+Articles&af=Any&ao=Citations&am=50"
  "* Options for performing an article search on CiteSeer. ")

(emacspeak-websearch-set-searcher 'citeseer

                                  'emacspeak-websearch-citeseer-search)

(emacspeak-websearch-set-key 3 'citeseer)

;;;###autoload
(defun emacspeak-websearch-citeseer-search(term)
  "Perform a CiteSeer search. "
  (interactive
   (list
    (emacspeak-websearch-read-query
     "Enter CiteSeer query term:")))
  (cl-declare (special emacspeak-websearch-citeseer-uri
                       emacspeak-websearch-citeseer-citation-options
                       emacspeak-websearch-citeseer-article-options))
  (let ((options nil)
        (type-char
         (read-char
          "a Articles c Citations")))
    (setq options
          (cl-case type-char
            (?a
             emacspeak-websearch-citeseer-article-options)
            (?c emacspeak-websearch-citeseer-citation-options)))
    (browse-url
     (concat emacspeak-websearch-citeseer-uri
             "q="
             (url-hexify-string term)
             "&"
             options))
    (cond
     ((char-equal type-char ?a)
      (emacspeak-webutils-post-process "documents found"
                                       'emacspeak-speak-line))
     ((char-equal ?c type-char)
      (emacspeak-webutils-post-process "citations found" 'emacspeak-speak-line)))))

;;}}}
;;{{{ FolDoc

(emacspeak-websearch-set-searcher 'foldoc
                                  'emacspeak-websearch-foldoc-search)
(emacspeak-websearch-set-key ?f 'foldoc)

(defvar emacspeak-websearch-foldoc-uri
  "http://foldoc.org/"
  "*URI for launching a FolDoc  search.")

;;;###autoload
(defun emacspeak-websearch-foldoc-search (query)
  "Perform a FolDoc search. "
  (interactive
   (list
    (emacspeak-websearch-read-query "Computing Dictionary Query: ")))
  (cl-declare (special emacspeak-websearch-foldoc-uri))
  (browse-url
   (concat emacspeak-websearch-foldoc-uri
           (url-hexify-string query)))
  (emacspeak-webutils-post-process
   query
   'emacspeak-speak-line))

;;}}}
;;{{{ Lookup company news at Yahoo

(emacspeak-websearch-set-searcher 'company-news
                                  'emacspeak-websearch-company-news)
(emacspeak-websearch-set-key ?c 'company-news)

(defvar emacspeak-websearch-company-news-uri
  "http://finance.yahoo.com/q"
  "*URI for launching a company news lookup")

(defvar emacspeak-websearch-yahoo-charts-uri
  "http://chart.yahoo.com/t?"
  "*URI for locating historical chart data.")

(defvar emacspeak-websearch-yahoo-csv-charts-uri
  "http://itable.finance.yahoo.com/table.csv?"
  "*URI for locating historical chart data.")

(defvar emacspeak-websearch-yahoo-company-news-quotes-uri
  "http://finance.yahoo.com/q?d=t&o=t"
  "URI for looking up detailed quote information. ")

;;;###autoload
(defun emacspeak-websearch-company-news (ticker &optional prefix)
  "Perform an company news lookup.
Retrieves company news, research, profile, insider trades,  or upgrades/downgrades."
  (interactive
   (list
    (emacspeak-websearch-read-query
     "Enter stock ticker of company to lookup: ")
    current-prefix-arg))
  (cl-declare (special emacspeak-websearch-company-news-uri))
  ;;; invert sense of prefix --- since Yahoo APIs are gone:
  (setq prefix (not prefix))
  (let ((type-char
         (read-char
          "b basic, c Upgrades, h history, i insider, n news, o options, r Research, p profile, q Quotes, t technical")))
    (cond
     ((char-equal type-char ?h)
      (emacspeak-websearch-yahoo-historical-chart ticker prefix)
      (emacspeak-auditory-icon 'select-object)
      (message "Fetching data --just a minute."))
     (t
      (browse-url
       (concat emacspeak-websearch-company-news-uri
               (format "%s?"
                       (cl-case type-char
                         (?n "/h")
                         (?p "/pr")
                         (?r "/ae")
                         (?c "/ao")
                         (?i "/it")
                         (?q "")
                         (?k "/ks")
                         (?b "/bc")
                         (?t "/ta")
                         (?e "/ce")
                         (?o "/op")
                         (?s "/sec")))
               (format "s=%s" ticker)))
      (emacspeak-webutils-post-process
       (format-time-string "%Y")
       'emacspeak-speak-line)))))

(defun emacspeak-websearch-view-csv-data (process state)
  "Process csv data and put it in emacspeak table mode. "
  (message "state: %s" state)
  (when (string-match "^finished" state)
    (emacspeak-auditory-icon 'select-object)
    (emacspeak-table-view-csv-buffer (process-buffer process))))

;;;###autoload
(defun emacspeak-websearch-yahoo-historical-chart (ticker
                                                   &optional as-html)
  "Look up historical stock data.
Optional second arg as-html processes the results as HTML rather than data."
  (interactive
   (list
    (emacspeak-websearch-read-query "Stock ticker:")
    current-prefix-arg))
  (cl-declare (special emacspeak-websearch-curl-program
                       emacspeak-websearch-yahoo-charts-uri
                       emacspeak-websearch-yahoo-csv-charts-uri))
  (let ((start-month
         (read-from-minibuffer "Start Month: "
                               (format-time-string "%m")))
        (start-date
         (read-from-minibuffer "Start Date: "
                               (format-time-string  "%d")))
        (start-year
         (read-from-minibuffer "Start Year: "
                               (format-time-string "%y")))
        (end-month
         (read-from-minibuffer "End Month: "
                               (format-time-string "%m")))
        (end-date (read-from-minibuffer "End Date: "
                                        (format-time-string
                                         "%d")))
        (end-year
         (read-from-minibuffer "End Year: "
                               (format-time-string "%y")))
        (period
         (format "%c"
                 (read-char
                  "Daily: d Weekly: w Monthly: m"))))
    (cond
     ((not as-html)
      (let ((uri (concat emacspeak-websearch-yahoo-csv-charts-uri
                         (format "a=%s" start-month)
                         (format "&b=%s" start-date)
                         (format "&c=%s" start-year)
                         (format "&d=%s" end-month)
                         (format "&e=%s" end-date)
                         (format "&f=%s" end-year)
                         (format "&g=%s" period)
                         (format "&s=%s" ticker)
                         "&q=q&x=.csv"))
            (results (format "*%s*" ticker))
            (process nil))
        (setq process
              (start-process   "curl"
                               results
                               emacspeak-websearch-curl-program
                               "--silent" "--location"
                               uri))
        (set-process-sentinel process 'emacspeak-websearch-view-csv-data)))
     (t (browse-url
         (concat emacspeak-websearch-yahoo-charts-uri
                 (format "a=%s" start-month)
                 (format "&b=%s" start-date)
                 (format "&c=%s" start-year)
                 (format "&d=%s" end-month)
                 (format "&e=%s" end-date)
                 (format "&f=%s" end-year)
                 (format "&g=%s" period)
                 (format "&s=%s" ticker)))
        (emacspeak-webutils-post-process
         "Open"
         'emacspeak-speak-line)))))

;;}}}
;;{{{ source forge

(emacspeak-websearch-set-searcher 'software
                                  'emacspeak-websearch-software-search)

(emacspeak-websearch-set-key ?s 'software)

(defvar emacspeak-websearch-sourceforge-search-uri
  "http://sourceforge.net/search/?"
  "URI for searching the SourceForge site.")

;;;###autoload
(defun emacspeak-websearch-sourceforge-search (query)
  "Search SourceForge Site. "
  (interactive
   (list
    (emacspeak-websearch-read-query "Search SourceForge for: ")))
  (cl-declare (special emacspeak-websearch-sourceforge-search-uri))
  (emacspeak-we-extract-table-by-match "Description"
                                       (concat
                                        emacspeak-websearch-sourceforge-search-uri
                                        "type_of_search=soft"
                                        "&exact=1"
                                        "&words="
                                        (url-hexify-string query))))

(defvar emacspeak-websearch-ctan-search-uri
  "http://www.ctan.org/tools/filesearch?action=/search/&filename="
  "URI for searching CTAN archives for tex and latex utilities. ")

;;;###autoload
(defun emacspeak-websearch-ctan-search (query)
  "Search CTAN Comprehensive TeX Archive Network   Site. "
  (interactive
   (list
    (emacspeak-websearch-read-query
     "Lookup Comprehensive TEX Archive for: ")))
  (cl-declare (special emacspeak-websearch-ctan-search-uri))
  (browse-url
   (concat emacspeak-websearch-ctan-search-uri
           (url-hexify-string query)))
  (emacspeak-webutils-post-process
   query
   'emacspeak-speak-line))

(defvar emacspeak-websearch-cpan-search-uri
  "http://search.cpan.org/search?mode=module&query="
  "URI for searching CPAN  archives for perl modules . ")

;;;###autoload
(defun emacspeak-websearch-cpan-search (query)
  "Search CPAN  Comprehensive Perl Archive Network   Site. "
  (interactive
   (list
    (emacspeak-websearch-read-query
     "Locate PERL Module: ")))
  (cl-declare (special emacspeak-websearch-cpan-search-uri))
  (browse-url
   (concat emacspeak-websearch-cpan-search-uri
           (url-hexify-string query)))
  (emacspeak-webutils-post-process
   query
   'emacspeak-speak-line))

(defvar emacspeak-websearch-software-sites
  "p Perl s SourceForge t TEX cap"
  "Sites searched for open source software. ")

;;; top level dispatcher for searching source locations
;;;###autoload
(defun emacspeak-websearch-software-search  ()
  "Search SourceForge, Freshmeat and other sites. "
  (interactive)
  (cl-declare (special emacspeak-websearch-software-sites))
  (let ((site
         (read-char emacspeak-websearch-software-sites)))
    (cl-case site
      (?p (call-interactively 'emacspeak-websearch-cpan-search))
      (?s (call-interactively 'emacspeak-websearch-sourceforge-search))
      (?t (call-interactively 'emacspeak-websearch-ctan-search))
      (otherwise (message emacspeak-websearch-software-sites)))))

;;}}}
;;{{{ Gutenberg

(emacspeak-websearch-set-searcher 'gutenberg
                                  'emacspeak-websearch-gutenberg)
(emacspeak-websearch-set-key ?G 'gutenberg)

(defvar emacspeak-websearch-gutenberg-uri
  "http://digital.library.upenn.edu/webbin/book/search?"
  "*URI for Gutenberg search")

;;;###autoload
(defun emacspeak-websearch-gutenberg (type query)
  "Perform an Gutenberg search"
  (interactive
   (list
    (read-char "Author a, Title t")
    (emacspeak-websearch-read-query "Gutenberg query: ")))
  (cl-declare (special emacspeak-websearch-gutenberg-uri))
  (browse-url
   (concat emacspeak-websearch-gutenberg-uri
           (cl-ecase type
             (?a "author=")
             (?t "title="))
           (url-hexify-string query)))
  (emacspeak-webutils-post-process
   query
   'emacspeak-speak-line))

;;}}}
;;{{{ google



(emacspeak-websearch-set-searcher 'google
                                  'emacspeak-websearch-google)
(emacspeak-websearch-set-key ?g 'google)
(emacspeak-websearch-set-key ?i 'google-with-toolbelt)
(emacspeak-websearch-set-key ?g 'google)
(emacspeak-websearch-set-searcher 'google-with-toolbelt
                                  'emacspeak-websearch-google-with-toolbelt)
(emacspeak-websearch-set-key ?m 'google-mobile)
(emacspeak-websearch-set-searcher 'google-mobile 'emacspeak-websearch-google-mobile)

(defcustom emacspeak-websearch-google-number-of-results 25
  "Number of results to return from google search."
  :type 'number
  :group 'emacspeak-websearch)

(defvar emacspeak-websearch-google-uri-template
  "www.google.com/search?source=hp&q="
  "*URI for Google search")

(defun emacspeak-websearch-google-uri ()
  "Return URI end-point for Google search."
  (cl-declare (special emacspeak-google-use-https
                       emacspeak-websearch-google-uri-template))
  (concat
   (if emacspeak-google-use-https
       "https://"
     "http://")
   emacspeak-websearch-google-uri-template))

(defcustom emacspeak-websearch-google-options nil
  "Additional options to pass to Google e.g. &xx=yy..."
  :type '(choice
          (const :tag "None" nil)
          (string :tag "Options"))
  :group 'emacspeak-websearch)

(defadvice gweb-google-autocomplete (after emacspeak pre act comp)
  "Cache the query."
  (cl-declare (special emacspeak-google-query))
  (setq emacspeak-google-query ad-return-value))

;;;###autoload
(defun emacspeak-websearch-google (query &optional flag)
  "Perform a Google search.  First optional interactive prefix arg
`flag' prompts for additional search options. Second interactive
prefix arg is equivalent to hitting the I'm Feeling Lucky button on Google. "
  (interactive (list (gweb-google-autocomplete) current-prefix-arg))
  (cl-declare (special emacspeak-google-query emacspeak-google-toolbelt
                       emacspeak-websearch-google-options emacspeak-websearch-google-number-of-results))
  (setq emacspeak-google-toolbelt nil)
  (let ((toolbelt (emacspeak-google-toolbelt))
        (search-url nil)
        (add-toolbelt (and flag  (consp flag) (= 4 (car flag))))
        (lucky (and flag  (consp flag) (= 16 (car flag)))))
    (emacspeak-webutils-cache-google-query query)
    (emacspeak-webutils-cache-google-toolbelt toolbelt)
    (if lucky
        (emacspeak-webutils-autospeak)
      (emacspeak-webutils-post-process "Results" 'emacspeak-speak-line))
    (setq search-url
          (concat
           (emacspeak-websearch-google-uri)
           query
           (format "&num=%s%s"          ; acumulate options
                   emacspeak-websearch-google-number-of-results
                   (or emacspeak-websearch-google-options ""))
           (when lucky
             (concat
              "&btnI="
              (url-hexify-string "I'm Feeling Lucky")))))
    (cond
     (add-toolbelt (emacspeak-google-toolbelt-change))
     (lucky (browse-url search-url))
     (t                                 ; always just show results
      (emacspeak-we-extract-by-id-list
       '("center_col" "nav" "rhs_block")
       search-url 'speak)))))

;;;###autoload
(defun emacspeak-websearch-google-mobile (query &optional flag)
  "Perform a Google Mobile search.  First optional interactive prefix arg
`flag' prompts for additional search options. Second interactive
prefix arg is equivalent to hitting the I'm Feeling Lucky button on Google. "
  (interactive (list (gweb-google-autocomplete) current-prefix-arg))
  (cl-declare (special emacspeak-websearch-google-options))
  (let ((emacspeak-websearch-google-options "&deb=0mobile"))
    (funcall-interactively #'emacspeak-websearch-google query flag)))

;;{{{ IMFA

(emacspeak-websearch-set-searcher 'agoogle
                                  'emacspeak-websearch-accessible-google)

(emacspeak-websearch-set-key ?a 'agoogle)
;;}}}

(defvar emacspeak-websearch-accessible-google-url
                                        ;"https://www.google.com/search?esrch=SearchLite::OptIn&site=&q=%s&num=25&gbv=1&sei=L8kNVI_kKJWpyATPv4Aw"
  "https://www.google.com/search?num=25&lite=90586&q=%s"
  "Using experimental Google Lite.")

;;;###autoload
(defun emacspeak-websearch-accessible-google(query &optional options)
  "Use Google Lite (Experimental).
Optional prefix arg prompts for toolbelt options."
  (interactive
   (list
    (gweb-google-autocomplete "AGoogle: ")
    current-prefix-arg))
  (cl-declare (special emacspeak-eww-masquerade
                       emacspeak-websearch-accessible-google-url emacspeak-google-toolbelt))
  (setq emacspeak-google-toolbelt nil)
  (let ((emacspeak-eww-masquerade t)
        (toolbelt (emacspeak-google-toolbelt)))
    (emacspeak-webutils-cache-google-query query)
    (emacspeak-webutils-cache-google-toolbelt toolbelt)
    (cond
     (options (emacspeak-google-toolbelt-change))
     (t
      (emacspeak-we-extract-by-id-list
       '("center_col" "nav" "rhs_block")
       (format emacspeak-websearch-accessible-google-url query)
       'speak)))))

;;;###autoload
(defun emacspeak-websearch-google-with-toolbelt (query)
  "Launch Google search with toolbelt."
  (interactive (list (gweb-google-autocomplete "AGoogle: ")))
  (emacspeak-websearch-accessible-google query 'use-toolbelt))
(emacspeak-websearch-set-searcher 'google-lucky
                                  'emacspeak-websearch-google-feeling-lucky)

(emacspeak-websearch-set-key ?\  'google-lucky)

;;;###autoload
(defun emacspeak-websearch-google-feeling-lucky (query)
  "Do a I'm Feeling Lucky Google search."
  (interactive
   (list
    (gweb-google-autocomplete "Google Lucky Search: ")))
  (emacspeak-websearch-google query '(16)))

(emacspeak-websearch-set-searcher 'google-specialize
                                  'emacspeak-websearch-google-specialize)

(emacspeak-websearch-set-key ?, 'google-specialize)

;;;###autoload
(defun emacspeak-websearch-google-specialize (specialize query)
  "Perform a specialized Google search. See the Google site for
  what is possible here:
https://www.google.com/options/specialsearches.html "
  (interactive
   (list
    (emacspeak-websearch-read-query
     "Specialize google Search On: ")
    (emacspeak-websearch-read-query
     "Google for:")))
  (let ((emacspeak-websearch-google-uri-template
         (format "www.google.com/%s?q="
                 specialize)))
    (emacspeak-websearch-google query)))

;;;###autoload
(defun emacspeak-websearch-google-search-in-date-range ()
  "Use this from inside the calendar to do Google date-range searches."
  (interactive)
  (cl-declare (special calendar-mark-ring))
  (let ((query (emacspeak-websearch-read-query "Google for: "))
        (from (read (calendar-astro-date-string (calendar-cursor-to-date t))))
        (to (read (calendar-astro-date-string (or (car calendar-mark-ring)
                                                  (error "No mark set in this buffer"))))))
    (emacspeak-websearch-google
     (concat
      (url-hexify-string query)
      (format "+daterange:%s-%s"
              (min from to)
              (max from to))))))

(when (featurep 'calendar)
  (cl-declaim (special calendar-mode-map))
  (define-key calendar-mode-map "gg"
    'emacspeak-websearch-google-search-in-date-range))

;;}}}
;;{{{ Google News

(emacspeak-websearch-set-searcher 'google-news
                                  'emacspeak-websearch-google-news)

(emacspeak-websearch-set-key ?n 'google-news)

;;;###autoload
(defun emacspeak-websearch-google-news ()
  "Invoke Google News url template."
  (interactive)
  (let ((name "Google News Search"))
    (emacspeak-url-template-open
     (emacspeak-url-template-get name))))

;;}}}
;;{{{ Google Category news:

(emacspeak-websearch-set-searcher
 'google-category-news
 'emacspeak-websearch-google-category-news)
(emacspeak-websearch-set-key ?u 'google-category-news)
(emacspeak-websearch-set-key 14 'google-category-news)

;;;###autoload
(defun emacspeak-websearch-google-category-news ()
  "Browse Google News by category."
  (interactive)
  (let ((name   "Google Category News"))
    (emacspeak-url-template-open (emacspeak-url-template-get name))))

;;}}}
;;{{{ Google Regional News:

(emacspeak-websearch-set-searcher
 'google-regional-news
 'emacspeak-websearch-google-regional-news)

(emacspeak-websearch-set-key ?r 'google-regional-news)

;;;###autoload
(defun emacspeak-websearch-google-regional-news ()
  "Browse Google News by region."
  (interactive)
  (let ((name   "Google Regional News"))
    (emacspeak-url-template-open (emacspeak-url-template-get name))))

;;}}}
;;{{{  Ask Jeeves

(emacspeak-websearch-set-searcher 'jeeves
                                  'emacspeak-websearch-ask-jeeves)
(emacspeak-websearch-set-key ?j 'jeeves)

(defvar emacspeak-websearch-jeeves-uri
  "http://www.ask.com/web?qsrc=0&o=0&ASKDSBHO=0&q="
  "URI for Ask Jeeves  search")

;;;###autoload
(defun emacspeak-websearch-ask-jeeves (query)
  "Ask Jeeves for the answer."
  (interactive
   (list (emacspeak-websearch-read-query "Ask Jeeves for: ")))
  (cl-declare (special emacspeak-websearch-jeeves-uri))
  (browse-url
   (concat emacspeak-websearch-jeeves-uri
           (url-hexify-string query)))
  (emacspeak-webutils-post-process query 'emacspeak-speak-line))

;;}}}
;;{{{  news yahoo

(emacspeak-websearch-set-searcher 'news-yahoo
                                  'emacspeak-websearch-news-yahoo)
(emacspeak-websearch-set-key ?N 'news-yahoo)

(defvar emacspeak-websearch-news-yahoo-uri
  "http://search.news.yahoo.com/search/news?"
  "*URI for launching a Yahoo News search")

(defvar emacspeak-websearch-news-yahoo-rss-uri
  "http://news.search.yahoo.com/news/rss?"
  "*RSS URI for launching a Yahoo News search")

;;;###autoload
(defun emacspeak-websearch-news-yahoo (query &optional rss)
  "Perform an Yahoo News search.
Optional prefix arg  avoids scraping  information from HTML."
  (interactive
   (list
    (emacspeak-websearch-read-query "Yahoo News Query: ")
    current-prefix-arg))
  (add-hook 'emacspeak-web-post-process-hook
            #'(lambda nil
                (cl-declare (special  emacspeak-we-url-rewrite-rule
                                      emacspeak-websearch-news-yahoo-rss-uri
                                      emacspeak-we-class-filter))
                (setq emacspeak-we-class-filter "article"
                      emacspeak-we-url-rewrite-rule
                      '("$" "&printer=1"))))
  (cond
   (rss                       ;use rss feed
    (emacspeak-feeds-rss-display
     (concat emacspeak-websearch-news-yahoo-rss-uri
             (format "p=%s&n=20&c=news"
                     (url-hexify-string query)))))
   (t
    (emacspeak-we-xslt-filter
     "//ol"
     (concat emacspeak-websearch-news-yahoo-uri
             (format "p=%s&n=20&c=news"
                     (url-hexify-string query)))
     'speak-result))))

;;}}}
;;{{{  Open Directory

(emacspeak-websearch-set-searcher 'open-directory
                                  'emacspeak-websearch-open-directory-search)
(emacspeak-websearch-set-key ?o 'open-directory)

(defvar emacspeak-websearch-open-directory-uri
  "http://search.dmoz.org/cgi-bin/search?search="
  "*URI for launching a Open Directory search")

;;;###autoload
(defun emacspeak-websearch-open-directory-search (query)
  "Perform an Open Directory search"
  (interactive
   (list
    (emacspeak-websearch-read-query
     "Search Open Directory for: ")))
  (cl-declare (special emacspeak-websearch-open-directory-uri))
  (browse-url
   (concat emacspeak-websearch-open-directory-uri
           (url-hexify-string query)))
  (emacspeak-webutils-post-process
   "Search results"
   'emacspeak-speak-line))

;;}}}
;;{{{ Merriam Webster

(emacspeak-websearch-set-searcher 'merriam-webster
                                  'emacspeak-websearch-merriam-webster-search)
(emacspeak-websearch-set-key ?d 'merriam-webster)

(defvar emacspeak-websearch-merriam-webster-uri
  "http://www.m-w.com/cgi-bin/dictionary?va="
  "URI for searching the Merriam Webster dictionary.")

;;;###autoload
(defun emacspeak-websearch-merriam-webster-search (query)
  "Search the Merriam Webster Dictionary."
  (interactive
   (list
    (emacspeak-websearch-read-query "Lookup word in Webster:")))
  (cl-declare (special emacspeak-websearch-merriam-webster-uri))
  (browse-url
   (concat emacspeak-websearch-merriam-webster-uri
           (url-hexify-string query)))
  (emacspeak-webutils-post-process
   "Main Entry"
   'emacspeak-speak-line))

;;}}}
;;{{{ wikipedia

(emacspeak-websearch-set-searcher 'wikipedia
                                  'emacspeak-websearch-wikipedia-search)

(emacspeak-websearch-set-key 23 'wikipedia)

;;;###autoload
(defun emacspeak-websearch-wikipedia-search (query)
  "Search Wikipedia using Google."
  (interactive
   (list (emacspeak-websearch-read-query "Search Wikipedia: ")))

  (emacspeak-websearch-google
   (url-hexify-string (format "site:wikipedia.org %s"query))))

;;}}}
;;{{{ yahoo

(emacspeak-websearch-set-searcher 'yahoo
                                  'emacspeak-websearch-yahoo)
(emacspeak-websearch-set-key ?Y 'yahoo)

(defvar emacspeak-websearch-yahoo-uri
  "http://search.yahoo.com/bin/search?p="
  "*URI for launching a Yahoo  search")

;;;###autoload
(defun emacspeak-websearch-yahoo (query)
  "Perform an Yahoo  search"
  (interactive
   (list (emacspeak-websearch-read-query "Yahoo Query: ")))
  (cl-declare (special emacspeak-websearch-yahoo-uri))
  (browse-url
   (concat emacspeak-websearch-yahoo-uri
           (url-hexify-string query)))
  (emacspeak-webutils-post-process
   "
Results"
   'emacspeak-speak-line))

;;}}}
;;{{{ YouTube Search:

(emacspeak-websearch-set-searcher 'youtube-search
                                  'emacspeak-websearch-youtube-search)

(emacspeak-websearch-set-key ?y 'youtube-search)

(defvar emacspeak-websearch-youtube-search-uri
  "https://www.google.com/search?num=25&lite=90586&q=youtube+%s"
  "REST end-point for YouTube Search.")

;;;###autoload
(defun emacspeak-websearch-youtube-search (query)
  "YouTube search."
  (interactive (list (gweb-youtube-autocomplete)))
  (cl-declare (special emacspeak-websearch-youtube-search-uri))
  (emacspeak-we-extract-by-id-list
   '("center_col" "nav" "rhs_block")
   (format emacspeak-websearch-youtube-search-uri (url-hexify-string query))
   'speak))

;;}}}
;;{{{ Shopping at Amazon

(emacspeak-websearch-set-searcher 'amazon-search
                                  'emacspeak-websearch-amazon-search)

(emacspeak-websearch-set-key 1 'amazon-search)

(defvar emacspeak-websearch-amazon-search-form
  "http://www.amazon.com/access"
  "Form for Amazon store search.")

;;;###autoload
(defun emacspeak-websearch-amazon-search ()
  "Amazon search."
  (interactive)
  (cl-declare (special emacspeak-websearch-amazon-search-form))
  (browse-url emacspeak-websearch-amazon-search-form))

;;}}}
;;{{{  site-specific search tools

;;; Load site-specific searchers

;;}}}
;;}}}
(provide 'emacspeak-websearch)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: t
;;; end:

;;}}}
