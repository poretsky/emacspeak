;;; File At Point  -*- lexical-binding: t; -*-

(require 'ffap)
(declare (special  ffap-bindings))
(setq ffap-bindings 
      '(
        (global-set-key  "\M-M" 'ffap-menu)
        (global-set-key "\M-L" 'ffap-next)))
(ffap-bindings)

    
