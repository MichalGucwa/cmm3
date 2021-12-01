#!/usr/bin/env tclsh

# Copyright (C) Navraj S. Pannu 2006-2009 Leiden University
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
proc OutputAFROscriptfile { inccp4 tcl } {
    global XMLParse
    global env

    if { $tcl } {
 	puts "\#!/usr/bin/env tclsh"
    } else {
	puts "\#!/bin/sh"
    }

    if { $inccp4 } {
	set executable "[file join $env(CBIN) afro]"
    } else {
	set executable "[file join $env(CRANK) bin afro]"
    }
    
    puts " "

    set step $XMLParse(crank__soap__current_step)
    
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    set mtz_in "[file join .. workdb crank.in.$tag.mtz]"

    set mtz_out [file join .. workdb crank.out.$tag.mtz]

    if { $tcl } {
	puts "set command \"$executable HKLIN $mtz_in HKLOUT $mtz_out\""
    } else {
	puts "$executable HKLIN $mtz_in HKLOUT $mtz_out << END > afro-logfile"
    }
    # determine if we have MAD+native!
    set mad_native 0

    set i 1
    while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } {
	if { $XMLParse([join "crank parameters crystal=$i native" __]) == "0" } {
	    set j 1
	    while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } {
		if { $j > 1 } {
		    set mad_native 1
		}
		incr j
	    }
	}
	incr i
    }
    
    #
    if { $tcl } { 
      puts -nonewline "set script \""
    }
    set i 1
    while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } { 
	# Start the XTAL section

	if { !( ($mad_native == 1) && ($XMLParse([join "crank parameters crystal=$i native" __]) == "1") ) } {

	    puts "XTAL crystal${i}"
	    if { [info exists XMLParse([join "crank parameters crystal=$i substructure atom_name" __])] } {
		puts "  ATOM $XMLParse([join "crank parameters crystal=$i substructure atom_name" __])"
		puts "    NUMB $XMLParse([join "crank parameters crystal=$i substructure natoms" __])" 
		puts "    BISO $XMLParse([join "crank parameters crystal=$i data=1 bfactor" __])" 
	    }
	    set j 1
	    while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } { 
		# Start the DNAME section
		set type $XMLParse([join "crank parameters crystal=$i data=$j type" __])
		puts "  DNAME ${type}_${i}_${j}"

		# Output the columns for this dataset
		if { [string compare $XMLParse([join "crank parameters crystal=$i data=$j anomalous" __]) "0"] == 0 } { 
		    # Build up labin and labout for non-anomalous data
		    set input_f $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j f" __])
		    set input_sigf $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j sigf" __])
				
		    puts "    COLUMN F=$input_f SF=$input_sigf"
		} else {
		    set input_f_plus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j f_plus" __])
		    set input_sigf_plus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j sigf_plus" __])
		    set input_f_minus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j f_minus" __])
		    set input_sigf_minus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j sigf_minus" __])
				
		    puts "    COLUMN F+=$input_f_plus SF+=$input_sigf_plus F-=$input_f_minus SF-=$input_sigf_minus"

		    set k 1
		    while { [info exists XMLParse([join "crank parameters crystal=$i data=$j atom=$k name" __])] } { 

			# Output Atom Form Factors
			set atomname $XMLParse([join "crank parameters crystal=$i data=$j atom=$k name" __])
			set fprime $XMLParse([join "crank parameters crystal=$i data=$j atom=$k fprime" __])
			set fprimeprime $XMLParse([join "crank parameters crystal=$i data=$j atom=$k fprimeprime" __])
			puts "    FORM $atomname FP=$fprime FPP=$fprimeprime"
			incr k
		    }
		}

		if { [info exists XMLParse([join "crank soap run step=$step afro sigf" __])] } {
		    set sigf $XMLParse([join "crank soap run step=$step afro sigf " __])
		}


		if { [info exists sigf] } {
		    puts "    EXCLUDE SIGF $sigf"
		}
		incr j
	    }
	}
	incr i
    }

    if { [info exists XMLParse([join "crank soap run step=$step afro sano" __])] } {
	set sano $XMLParse([join "crank soap run step=$step afro sano " __])
	if { $sano >= 0 } {
	  puts "ANOC $sano " 
        }
    }

    if { [info exists XMLParse([join "crank soap run step=$step afro siso" __])] } {
	set sano $XMLParse([join "crank soap run step=$step afro siso " __])
	puts "ISOC $siso " 
    }

    if { [info exists XMLParse([join "crank soap run step=$step afro hires_cutoff" __])] } {
	set hires $XMLParse([join "crank soap run step=$step afro hires_cutoff" __])
	puts "HIREs $hires"
    }

    if { [info exists XMLParse([join "crank soap run step=$step afro target" __])] } {
	set target $XMLParse([join "crank soap run step=$step afro target" __])
	if { ($target == "GIAC") || ($target == "MULT") || ($target == "DELTA") || ($target == "ISOD") ||
	     ($target == "ANOD") } {
	    puts $target
	} 
    } 
    puts "LABO EA=${tag}_EA SGEA=${tag}_SIGEA FA=${tag}_FA SGFA=${tag}_SIGFA ALPH=${tag}_ALPHA"
    puts "CYCL 50\nVERBOSE \n"
    if { $tcl } {
        puts "\nEND\""
        puts ""
	puts "set command \"\$command << \\\"\$script\\\" > afro-logfile\""
	puts "eval exec \$command"
    } else {
        puts "END"
    }
}

global env

set inccp4 [lindex $argv 0]
set tcl    [lindex $argv 1]

source [file join $env(CRANK) bin crankutils.tcl]

set inputxml [file join .. xml input.xml]

if { [file exists $inputxml] == 0 } {
    crank_error "xml2afroscript.tcl::inputxml file does not exist"
}

XMLParsefile $inputxml

OutputAFROscriptfile $inccp4 $tcl
