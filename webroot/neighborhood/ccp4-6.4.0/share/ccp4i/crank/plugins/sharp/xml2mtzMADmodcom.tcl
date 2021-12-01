#!/usr/bin/env tclsh

# Copyright (C) Navraj S. Pannu 2008, Leiden University
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
#
proc OutputmtzMADmodcomfile { } {
    global XMLParse

    set step $XMLParse(crank__soap__current_step)
    set orig_pwd $XMLParse(crank__soap__orig_pwd)
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]
    set mtz_in crank.in.$tag.mtz

    puts "mtzMADmod hklin [file join $orig_pwd workdb $mtz_in] hklout sharp.data.mtz << eof > mtzMADmod.log\n"

    puts "LABI - "
    set labostring "LABO -\n"
    set i 1
    set d 0
    while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } { 

	set j 1
	while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } {
	    incr d
	    if { $d != 1 } {
	      puts " -"
	      set labstring "$labostring -\n"
	    }
	    if { $XMLParse([join "crank parameters crystal=$i data=$j anomalous" __]) == "0"} { 
		set input_f $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j f" __])
		set input_sigf $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j sigf" __])
		puts -nonewline "   F$d=$input_f SIGF$d=$input_sigf"
		set labostring "$labostring   F$d=F_${i}_$j SIGF$d=SIGF_${i}_$j" 
	    } else {
		set input_f_p $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j f_plus" __])
		set input_sigf_p $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j sigf_plus" __])
		set input_f_m $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j f_minus" __])
		set input_sigf_m $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j sigf_minus" __])
		puts -nonewline "   F${d}(+)=$input_f_p SIGF${d}(+)=$input_sigf_p F${d}(-)=$input_f_m SIGF${d}(-)=$input_sigf_m"
		set labostring "$labostring   F$d=F_${i}_$j SIGF$d=SIGF_${i}_$j D$d=DANO_${i}_$j SIGD$d=SIGDANO_${i}_$j" 
	    }
	    incr j
	}
	incr i
    }
    puts "\n\n$labostring"
    puts "END\neof\n"
}

set inputxml [lindex $argv 0]
set crankbin [lindex $argv 1]

# Set CRANK path
source [file join $crankbin crankutils.tcl]

#
# Check to make sure files exist
#
if { [file exists $inputxml] == 0 } {
    crank_error "xml2mtzMADmodcom.tcl::inputxml file does not exist"
}

XMLParsefile $inputxml

OutputmtzMADmodcomfile
