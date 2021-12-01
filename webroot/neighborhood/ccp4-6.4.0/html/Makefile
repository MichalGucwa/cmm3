# CVS Id $Id$
#
# Makefile for generating INDEX, FUNCTION, whatis and REFERENCES
#
# **** Not intended for public release ****
#
SHELL=/bin/sh

# search path for dependencies
VPATH=../man/man1:../man/man3:../man/man5:../unsupported/man/man1
.SUFFIXES: .html .1 .3 .5

.1.html:
	perl ./man2html.perl < $< > $@

.3.html:
	perl ./man2html.perl < $< > $@

.5.html:
	perl ./man2html.perl < $< > $@

# default rule
.DEFAULT:

all: supported unsupported

# expands to "gmake abscale.html absurd.html ....."
supported:
	echo "Html files are now master copies; you do not want to make them."

#	gmake `\
#		cd ../man; ( cd man1; ls *.[1-9l]; ) \
#	      | sed -e 's/.$$/html/' ` 

unsupported:
	echo "Html files are now master copies; you do not want to make them."

#	gmake `\
#		cd ../unsupported/man; ( cd man1; ls *.[1-9l]; ) \
#	      | sed -e 's/.$$/html/' ` 

indices:
	./makeindices.pl *.html ../INSTALL ./ccp4i_installation.html ../examples/tutorial/html/index.html ../share/ccp4i/help/roadmaps/index.html pxmaths/index.html C_library/*.html

reference:
	./makereference
