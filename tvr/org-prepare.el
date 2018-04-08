;;;$Id: org-prepare.el 6727 2011-01-14 23:22:20Z tv.raman.tv $  -*- lexical-binding: nil; -*-

;(load-library "org-autoloads")
(eval-after-load "org"
  `(progn
     (define-key global-map "\C-cl" 'org-store-link)
     (define-key global-map "\C-ca" 'org-agenda)
     (define-key global-map "\C-cb" 'org-switchb)
     (define-key global-map "\C-cc" 'org-capture)
     (setq org-directory "~/.org/")
     (setq org-default-notes-file (expand-file-name "notes.org"  org-directory))
     (require 'emacspeak-muggles-autoloads)
     (define-key org-mode-map (kbd "C-c C-SPC") 'emacspeak-muggles-org-nav/body)
     (define-key org-mode-map (kbd "C-c t") 'emacspeak-muggles-org-table/body)
     (define-key org-mode-map (kbd "C-c DEL") 'hydra-ox/body)
     ))
