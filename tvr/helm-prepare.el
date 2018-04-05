;; -*- lexical-binding: nil; -*-
(require 'cl-lib)
;;; Taken from http://tuhdo.github.io/helm-intro.html
(eval-after-load
    "helm"
  `(progn
     (setq helm-split-window-in-side-p           t ; open helm buffer inside current window, not occupy whole other window
           helm-move-to-line-cycle-in-source     t ; move to end or beginning of source when reaching top or bottom of source.
           helm-ff-search-library-in-sexp        t ; search for library in `require' and `declare-function' sexp.
           helm-scroll-amount                    8 ; scroll 8 lines other window using M-<next>/M-<prior>
           helm-ff-file-name-history-use-recentf t)
     (when (executable-find "curl") (setq helm-google-suggest-use-curl-p t))

;;; Use hyper-, as the helm prefix 
     (global-set-key (kbd "C-x @h,") 'helm-command-prefix)

                                        
;;; Insert on desktop 
     (global-set-key (kbd "<insert>") 'helm-command-prefix)
     (global-unset-key (kbd "C-x c"))
     (require 'helm-config)
     (cl-loop
      for b in
      '(
        ("," helm-mode)
        ("g" helm-google-suggest)
        ("o" helm-mini))
      do
      (define-key helm-command-map (cl-first b) (cl-second b)))

     (define-key helm-map (kbd "C-s") 'helm-toggle-suspend-update)
                                        ;(helm-mode 1)
     ))
