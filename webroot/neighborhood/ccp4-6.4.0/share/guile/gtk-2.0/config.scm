;; Copyright (C) 2003, 2006 Free Software Foundation, Inc.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3 of
;; the License, or (at your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gtk-2.0 config))

(define-public gtkconf-prefix "/opt/xtal/ccp4-linux64")
(define-public gtkconf-exec-prefix "${prefix}")
(define-public gtkconf-libdir "${prefix}/lib")
(define-public gtkconf-default-version "@GTK_VERSION@")
(define-public gtkconf-version "2.0")
(define-public gtkconf-gtk-2-0 #t)
(define-public gtkconf-guile-gtk-version "2.1")
(define-public gtkconf-guilegtk-lib "-lguilegtk-2.0")
(define-public gtkconf-guile-libs " -pthread -L/opt/xtal/ccp4-linux64/lib -lguile -lltdl -L/opt/xtal/ccp4-linux64/lib -s -Wl,--hash-style=both -Wl,-rpath,$ORIGIN/lib -Wl,-rpath,$ORIGIN/../lib -lgmp -lcrypt -lm -lltdl")
(define-public gtkconf-gtk-libs "-pthread -L/opt/xtal/ccp4-linux64/lib -lgtk-x11-2.0 -lgdk-x11-2.0 -latk-1.0 -lgio-2.0 -lpangoft2-1.0 -lpangocairo-1.0 -lgdk_pixbuf-2.0 -lcairo -lpango-1.0 -lfreetype -lfontconfig -lgobject-2.0 -lgmodule-2.0 -lgthread-2.0 -lrt -lglib-2.0  ")
(define-public gtkconf-cc "gcc")
(define-public gtkconf-gtk-cflags "-pthread -I/opt/xtal/ccp4-linux64/include/gtk-2.0 -I/opt/xtal/ccp4-linux64/lib/gtk-2.0/include -I/opt/xtal/ccp4-linux64/include/atk-1.0 -I/opt/xtal/ccp4-linux64/include/cairo -I/opt/xtal/ccp4-linux64/include/gdk-pixbuf-2.0 -I/opt/xtal/ccp4-linux64/include/pango-1.0 -I/opt/xtal/ccp4-linux64/include/glib-2.0 -I/opt/xtal/ccp4-linux64/lib/glib-2.0/include -I/opt/xtal/ccp4-linux64/include/pixman-1 -I/opt/xtal/ccp4-linux64/include/libpng16 -I/usr/include/freetype2  ")
