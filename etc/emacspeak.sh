#!/bin/sh
# emacspeak - execute emacs with speech enhancements
# this file needs a maintainer, I, (tv.raman.tv@gmail.com) am not presently maintaining it.
# AKA  Use at your own risk, and if it breaks, you get to keep both pieces. 
# Patches that are fully tested always welcome.
#$Id$
if [ -f /etc/emacspeak.conf ]
    then
    . /etc/emacspeak.conf
fi

CL_ALL=""
for CL in $* ; do
	if [ "$CL" = "-o" ]; then
		DTK_PROGRAM=stereo-outloud
		export DTK_PROGRAM
	elif [ "$CL" = "-m" ]; then
		DTK_PROGRAM=multispeech
		export DTK_PROGRAM
	elif [ "$CL" = "-e" ]; then
		DTK_PROGRAM=espeak
		export DTK_PROGRAM
	elif [ "$CL" = "-d" ]; then
		DTK_PROGRAM=dtk-soft
		export DTK_PROGRAM
	else
		CL_ALL="$CL_ALL $CL"
	fi
done

exec FLAVOR -l ELCDIR/lisp/emacspeak-setup.el $CL_ALL
