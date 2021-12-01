#!/usr/bin/env tclsh

# Copyright (C) Navraj S. Pannu and RAG de Graaff 2006-2009,  Leiden University
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
proc OutputCRUNCH2scriptfile { inccp4 ico iter bp3 maxtrials tcl } {
    global XMLParse
    global env

    set step $XMLParse(crank__soap__current_step)

    if { $inccp4 } {
        set executable [file join $env(CBIN) crunch2]
    } else {
        set executable [file join $env(CRANK) bin crunch2]
    }

    if { $tcl } {

	puts "\#!/usr/bin/env tclsh"
	puts " "

	set commandline "$executable HKLIN crunch2.drear" 
	
	if { $ico == 1 } {
	    set commandline "$commandline MODELIN patterson.xyz"
	}

	if { $iter > 1 } {
	    set commandline "$commandline HITS crunch2.out$iter.hits"
	} else {
	    set commandline "$commandline HITS crunch2.out$iter.hits"
	}

	puts "set command \"$commandline\""
    } else {
	puts -nonewline "\#!/bin/sh\n\n$executable HKLIN crunch2.drear " 
	
	if { $ico == 1 } {
	    puts -nonewline "MODELIN patterson.xyz "
	}

	if { $iter > 1 } {
	    puts "HITS crunch2.out$iter.hits << END >> crunch2-full-logfile"
	} else {
	    puts "HITS crunch2.out$iter.hits << END > crunch2-full-logfile"
	}
    }

    # Set atom name as the first atom name we encounter while looping over all crystals
    set i 0
    while { ![info exists XMLParse([join "crank parameters crystal=$i substructure natoms" __])] } { 
	incr i
    }

    if { $tcl } {
	puts -nonewline "set script \""
    }

    puts "TRY $iter $iter" 

    if { [info exists XMLParse([join "crank parameters crystal=$i substructure natoms" __]) ] } {
	set natoms $XMLParse([join "crank parameters crystal=$i substructure natoms" __])
	if { $natoms <= 3 } {
	    puts "KLEIn $natoms"
	    set natoms 3
	}
    }

    # ncycles - Number of cycles
    if { [info exists XMLParse([join "crank soap run step=$step crunch2 ncycles" __])] } {
	set ncycles $XMLParse([join "crank soap run step=$step crunch2 ncycles" __])
    } else {
	set ncycles 400
    }

    if { [info exists XMLParse([join "crank soap run step=$step crunch2 spec" __])] } {
	if { $XMLParse([join "crank soap run step=$step crunch2 spec" __]) == 1 } {
	    puts "NOSPC 1"
	}
    }

    if { [info exists XMLParse([join "crank soap run step=$step crunch2 hi_res" __])] } {
	set reso $XMLParse([join "crank soap run step=$step crunch2 hi_res" __])
	set stlm [expr 1.0/(2.0*$reso)]
	puts "STLM $stlm" 
    }

    puts "NCYC $ncycles"

    puts "ICOO $ico"

    set c 1
    while { [info exists XMLParse([join "crank parameters crystal=$c native" __])] } {
	if { [info exists XMLParse([join "crank parameters crystal=$c substructure atom_name" __])] } {
	    break
	} else {
	    incr c
	}
    }

    set cell_a $XMLParse([join "crank parameters crystal=$c cell cell_a" __])
    set cell_b $XMLParse([join "crank parameters crystal=$c cell cell_b" __])
    set cell_c $XMLParse([join "crank parameters crystal=$c cell cell_c" __])
    set cell_alpha $XMLParse([join "crank parameters crystal=$c cell cell_alpha" __])
    set cell_beta $XMLParse([join "crank parameters crystal=$c cell cell_beta" __])
    set cell_gamma $XMLParse([join "crank parameters crystal=$c cell cell_gamma" __])

    puts "CELL $cell_a $cell_b $cell_c $cell_alpha $cell_beta $cell_gamma"

    puts "SYMM $XMLParse(crank__parameters__input_spacegroup__number)"
    puts "NATOM $natoms"
	
    set scattering_power $XMLParse([join "crank soap run step=$step crunch2 scattering_power" __])
    puts "SCATT $scattering_power"

    if { $tcl } {
	puts "\nEND\""
	puts ""
	if { $iter > 1 } {
	    puts "set logfile \[open \"crunch2-full-logfile\" a\]"
	} else {
	    puts "set logfile \[open \"crunch2-full-logfile\" w+\]"
	}
	puts "set command \"\$command << \\\"\$script\\\"\""
	puts "catch \{eval exec \$command\} output"
	puts "puts \$logfile \$output"
	puts "close \$logfile"
    } else {
	puts "END"
    }
    # puts "set command \"\$command << \\\"\$script\\\" >> crunch2-full-logfile\""
    # puts "eval exec \$command"
}

if { [lindex $argv 1] == "" } {
    exit
}

global env

#
set inccp4     [lindex $argv 0]
set ico        [lindex $argv 1]
set iter       [lindex $argv 2]
set bp3        [lindex $argv 3]
set maxtrials  [lindex $argv 4]
set tcl        [lindex $argv 5]

set inputxml   [file join .. xml input.xml]

source [file join $env(CRANK) bin crankutils.tcl]

if { [file exists $inputxml] == 0 } {
    crank_error "xml2crunch2script.tcl::inputxml file does not exist"
}

XMLParsefile $inputxml

OutputCRUNCH2scriptfile $inccp4 $ico $iter $bp3 $maxtrials $tcl
