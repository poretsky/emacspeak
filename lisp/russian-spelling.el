;;; russian-spelling.el --- Russian spelling data  -*- lexical-binding: t; coding: utf-8 -*-
;;; Description:  Module to set up spelling table for Russian letters
;;; Keywords: Voice, Multispeech
;;{{{  LCD Archive entry:

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

;;{{{ Required modules

(require 'emacspeak-speak)

;;}}}

;;; Code:

(unless (featurep 'russian-spelling)
  (nconc emacspeak-char-to-phonetic-table
         '(
           ("а" . "анна")
           ("б" . "борис")
           ("в" . "вася")
           ("г" . "гоша")
           ("д" . "дима")
           ("е" . "елена")
           ("ё" . "ёлка")
           ("ж" . "жора")
           ("з" . "зяма")
           ("и" . "иван")
           ("й" . "иван краткий")
           ("к" . "киловатт")
           ("л" . "лев")
           ("м" . "маша")
           ("н" . "нина")
           ("о" . "ольга")
           ("п" . "павел")
           ("р" . "рома")
           ("с" . "соня")
           ("т" . "таня")
           ("у" . "ульяна")
           ("ф" . "федя")
           ("х" . "хрен")
           ("ц" . "центр")
           ("ч" . "чаша")
           ("ш" . "шура")
           ("щ" . "щука")
           ("ъ" . "твердый знак")
           ("ы" . "ы")
           ("ь" . "мягкий знак")
           ("э" . "эдик")
           ("ю" . "юра")
           ("я" . "яша")
           ("А" . "анна большая")
           ("Б" . "борис большой")
           ("В" . "вася большой")
           ("Г" . "гоша большой")
           ("Д" . "дима большой")
           ("Е" . "елена большая")
           ("Ё" . "ёлка большая")
           ("Ж" . "жора большой")
           ("З" . "зяма большой")
           ("И" . "иван большой")
           ("Й" . "иван краткий большой")
           ("К" . "киловатт большой")
           ("Л" . "лев большой")
           ("М" . "маша большая")
           ("Н" . "нина большая")
           ("О" . "ольга большая")
           ("П" . "павел большой")
           ("Р" . "рома большой")
           ("С" . "соня большая")
           ("Т" . "таня большая")
           ("У" . "ульяна большая")
           ("Ф" . "федя большой")
           ("Х" . "хрен большой")
           ("Ц" . "центр большой")
           ("Ч" . "чаша большая")
           ("Ш" . "шура большой")
           ("Щ" . "щука большая")
           ("Ъ" . "твердый знак большой")
           ("Ы" . "ы большая")
           ("Ь" . "мягкий знак большой")
           ("Э" . "эдик большой")
           ("Ю" . "юра большой")
           ("Я" . "яша большой")
           )))

(provide 'russian-spelling)
