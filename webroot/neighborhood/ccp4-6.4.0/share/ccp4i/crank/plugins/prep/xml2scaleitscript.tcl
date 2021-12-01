#!/usr/bin/env tclsh
#
# Copyright (C) Navraj S. Pannu 2006-2007, Leiden University
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
proc OutputSCALEITscriptfile { tcl } {
    global XMLParse

    if { $tcl } {
	puts "\#!/usr/bin/env tclsh"
    } else {
	puts "\#!/bin/sh"
    }

    puts " "

    set step $XMLParse(crank__soap__current_step)
    set orig_pwd $XMLParse(crank__soap__orig_pwd)
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]
	
    set mtz_in "output.mtz"

    set mtz_out "[file join scaleit.out.mtz]"

    if { $tcl } {
	puts -nonewline "set script \" "
    } else {
	puts "scaleit HKLIN $mtz_in HKLOUT $mtz_out << END > scaleit-logfile"
    }
 
    set n 1
    set i 1
     while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } { 
	 set j 1
	 while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } { 
	     if { $XMLParse([join "crank parameters crystal=$i data=$j anomalous" __]) == 0 } {
		 set in_anomalous($n) 0
		 set in_f($n) "IN_X${i}_D${j}_F"
		 set in_sigf($n) "IN_X${i}_D${j}_SIGF"
		 set in_i($n) "IN_X${i}_D${j}_I"
		 set in_sigi($n) "IN_X${i}_D${j}_SIGI"
	     } else {
		 set in_anomalous($n) 1
		 set in_f($n) "IN_X${i}_D${j}_F"
		 set in_sigf($n) "IN_X${i}_D${j}_SIGF"
		 set in_f_plus($n) "IN_X${i}_D${j}_F+"
		 set in_sigf_plus($n) "IN_X${i}_D${j}_SIGF+"
		 set in_f_minus($n) "IN_X${i}_D${j}_F-"
		 set in_sigf_minus($n) "IN_X${i}_D${j}_SIGF-"
		 set in_i_plus($n) "IN_X${i}_D${j}_I+"
		 set in_sigi_plus($n) "IN_X${i}_D${j}_SIGI+"
		 set in_i_minus($n) "IN_X${i}_D${j}_I-"
		 set in_sigi_minus($n) "IN_X${i}_D${j}_SIGI-"
	     }
	     incr j
	     incr n
 	 }
	 incr i
     }

    # determine if we have MAD+native!
    set mad_native 0
    set nat_cryst 0
    set mad_cryst 0

    set i 1
    while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } {
	if { $XMLParse([join "crank parameters crystal=$i native" __]) == 1 } {
	    set nat_cryst i
	} else {
	    set j 1
	    while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } {
		if {$j > 1} {
		    set mad_native 1
		    set mad_cryst $i
		}
		incr j
	    }
	}
	incr i
    }

    if {$mad_native == 1 } {
	set c $mad_cryst
	set d 1
    } else {
	set c $XMLParse([join "crank parameters ref_crystal" __])
	set d $XMLParse([join "crank parameters ref_dataset" __])
    }

    set reference_f "IN_X${c}_D${d}_F"
    set reference_sigf "IN_X${c}_D${d}_SIGF"

    puts -nonewline "LABIN FP=$reference_f SIGFP=$reference_sigf -\n"

    set intensity 0
    if { $XMLParse([join "crank parameters input_intensity" __]) == "1" } {
 	set intensity 1
    }

    # Output all the datasets, starting from the first one
    for { set j 1 } { $j < $n } { incr j } {
	if { ! (($mad_native == 1) && ($nat_cryst == $j) ) } {  
	    if { ($in_anomalous($j) == 0) } {
		puts -nonewline "      FPH$j=$in_f($j) SIGFPH$j=$in_sigf($j) "
		if { $intensity == 1 } {
		    puts -nonewline "      IMEAN$j=$in_i($j) SIGIMEAN$j=$in_sigi($j)"
		}
		if { [expr $j + 1] != $n } {
		    puts " -"
		}
	    } else {
		puts -nonewline "      FPH$j=$in_f($j) SIGFPH$j=$in_sigf($j) -\n"
		puts -nonewline "      FPH$j\(+)=$in_f_plus($j) SIGFPH$j\(+)=$in_sigf_plus($j) -\n"
		puts -nonewline "      FPH$j\(-)=$in_f_minus($j) SIGFPH$j\(-)=$in_sigf_minus($j)"
		if { $intensity == 1 } {
		    puts -nonewline " -\n"
		    puts -nonewline "      I$j\(+)=$in_i_plus($j) SIGI$j\(+)=$in_sigi_plus($j) -\n"
		    puts -nonewline "      I$j\(-)=$in_i_minus($j) SIGI$j\(-)=$in_sigi_minus($j)"
		}
		if { [expr $j + 1] != $n } {
		    puts -nonewline " -\n"
		}
	    }
	}
    }
    puts "\n"
        
    # EXCLUDE [ FP | FPH<n> ] [ SIG <nsig> ] [ FMAX <fmax> ] [ DMAX <fmax> ] [ DIFF <diffmax>]
    set i 0
    while { [info exists XMLParse([join "crank soap run step=$step prep exclude=$i" __])] } {
	 set dataset ""
	set sig ""
	set fmax ""
	set dmax ""
	set diff ""
		
	puts "END"

	if { [info exists XMLParse([join "crank soap run step=$step prep exclude dataset" __])] } {
	    set exclude_dataset $XMLParse([join "crank soap run step=$step prep exclude dataset" __]) 
	    if { $exclude_dataset == 0 } {
		set dataset "FP"
	    } elseif { $exclude_dataset == 0 } {
		set dataset "FPH$exclude_dataset"
	    }
			

	    incr i
	}

	if { [info exists XMLParse([join "crank soap run step=$step prep exclude sig" __])] } {
	    set var $XMLParse([join "crank soap run step=$step prep resolution sig" __])
	    set sig "SIG"
	}

	if { [info exists XMLParse([join "crank soap run step=$step prep exclude fmax" __])] } {
	    set var $XMLParse([join "crank soap run step=$step prep resolution fmax" __])
	    set fmax "FMAX $var"
	}

	if { [info exists XMLParse([join "crank soap run step=$step prep exclude dmax" __])] } {
	    set var $XMLParse([join "crank soap run step=$step prep resolution dmax" __])
	    set dmax "DMAX $var"
	}

	if { [info exists XMLParse([join "crank soap run step=$step prep exclude diff" __])] } {
	    set var $XMLParse([join "crank soap run step=$step prep resolution diff" __])
	    set diff "DIFF $var"
	}
		
	puts "EXCLUDE $dataset $sig $fmax $dmax $diff"

    }

    # NOWT / WEIGHT
    if { [info exists XMLParse([join "crank soap run command step=$step prep weight" __]) ] } {
	puts "WEIGHT"
    }

    if { $tcl } {
	puts "\nEND\""

	puts ""
	puts "set command \"scaleit HKLIN $mtz_in HKLOUT $mtz_out << \\\"\$script\\\" > scaleit-logfile\""
	puts "eval exec \$command"
    } else {
	puts "\nEND"
    }
}

global env

set inputxml [file join .. xml input.xml]
source       [file join $env(CRANK) bin crankutils.tcl]

set tcl      [lindex $argv 0]

if { [file exists $inputxml] == 0 } {
    crank_error "xml2scaleitscript.tcl::inputxml file does not exist"
}

XMLParsefile $inputxml

OutputSCALEITscriptfile $tcl 
