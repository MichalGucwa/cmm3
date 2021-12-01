#!/usr/bin/env tclsh

# Copyright (C) Navraj S. Pannu 2007, Leiden University
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

global XMLParse
global env

set inputxml [file join .. xml input.xml]

set hat      [open [lindex $argv 0] r]
set inputmtz [lindex $argv 1]
set pdb      [open [lindex $argv 2] w]

source [file join $env(CRANK) bin crankutils.tcl]

XMLParsefile $inputxml

while { [gets $hat line] >= 0} {
    if { [regexp {SFAC (.*) *}  $line full element] } {
	break
    }
    if { [regexp {UNIT.*}  $line full] } {
	break
    }
}

set atomnum 1

set i 1
set orthx 0.0000
set orthy 0.0000
set orthz 0.0000

while { [info exists XMLParse([join "crank parameters crystal=$i native" __])] } {
    if { $XMLParse([join "crank parameters crystal=$i native" __]) == "0"} {
	if { [info exists XMLParse([join "crank parameters crystal=$i substructure atom_name" __])] } {
	    set inputatom [string toupper $XMLParse([join "crank parameters crystal=$i substructure atom_name" __])]  
	} else {
	    crank_error "crankutils.tcl::no substructure atom"
	}
	if { [info exists XMLParse([join "crank parameters crystal=$i data=1 bfactor" __])] } {
	    set b $XMLParse([join "crank parameters crystal=$i data=1 bfactor" __])  
	} else {
	    set b 25.0
	}
    }
    incr i
}

set c 1
while { [info exists XMLParse([join "crank parameters crystal=$c native" __])] } {
    if { [info exists XMLParse([join "crank parameters crystal=$c substructure atom_name" __])] } {
         break
    } else {
        incr c
    }
}

set aa $XMLParse([join "crank parameters crystal=$c cell cell_a" __])
set bb $XMLParse([join "crank parameters crystal=$c cell cell_b" __])
set cc $XMLParse([join "crank parameters crystal=$c cell cell_c" __])
set alpha $XMLParse([join "crank parameters crystal=$c cell cell_alpha" __])
set beta  $XMLParse([join "crank parameters crystal=$c cell cell_beta" __])
set gamma $XMLParse([join "crank parameters crystal=$c cell cell_gamma" __])

set name ""
set number ""

spacegroup_from_mtz $inputmtz name number

# put cryst card.
puts $pdb [format "CRYST1%9.3f%9.3f%9.3f%7.2f%7.2f%7.2f %10s"  $aa  $bb  $cc  $alpha  $beta  $gamma  $name]

set i 1

while { [gets $hat line] >= 0} {
    regsub -all {\s+} $line " " line
    regexp {([A-Z0-9a-z]*) *([0-9]*) *([-0-9.]*) *([-0-9.]*) *([-0-9.]*) *([-0-9.]*) *} \
	$line full atomname num x y z occ;
    if { ($x != "") && ($occ > 0) } {
	frac2orth $x $y $z orthx orthy orthz
	write_pdb_atom_line $pdb $i $inputatom $i $orthx $orthy $orthz $occ $b
	incr i
    }
}

puts $pdb "END"
close $pdb
