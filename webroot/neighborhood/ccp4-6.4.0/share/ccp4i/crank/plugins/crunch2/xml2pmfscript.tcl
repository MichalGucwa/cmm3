#!/usr/bin/env tclsh

# Copyright (C) Navraj S. Pannu and RAG de Graaff 2006, Leiden University
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
proc OutputPMFscriptfile { inccp4 tcl } {
    global XMLParse
    global env

    if { $tcl } {
	puts "\#!/usr/bin/env tclsh"
    } else {
	puts "\#!/bin/sh"
    }

    puts " "

    set step $XMLParse(crank__soap__current_step)

    # Set input DREAR and output coordinaten file names
    #
    set ref_in "crunch2.drear"
    set model_out "patterson.xyz"

    #
    # Run PMF.  This is the first line in the command script
    #
	
    if { $inccp4 } {
	set executable [file join $env(CBIN) pmf]
    } else {
	set executable [file join $env(CRANK) bin  pmf]
    }


    if { $tcl } {
	puts "set command \"$executable HKLIN $ref_in XYZOUT $model_out\""
	puts -nonewline "set script \""
    } else { 
	puts "$executable HKLIN $ref_in XYZOUT $model_out << END > pmf-logfile"
    }
    #
    # ntrials - Number of trials
    #
    if { [info exists XMLParse([join "crank soap run step=$step crunch2 patt_trials" __])] } {
	set ntrials $XMLParse([join "crank soap run step=$step crunch2 patt_trials" __])
    } else {
	set ntrials 150
    }
    puts "TRY 1 $ntrials"
	
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
    # 
    set i 0
    while { ![info exists XMLParse([join "crank parameters crystal=$i substructure natoms" __])] } { 
	incr i
    }
    set natoms $XMLParse([join "crank parameters crystal=$i substructure natoms" __])

    if { $natoms < 5 } {
	puts "NCOO 10"
        puts "# for less than 5 atoms, look for only one atom"
        puts "NATOM 1"
    } elseif { $natoms > 25 } {
	puts "NCOO 1"
        puts "# for greater than 25 atoms, look for 10% of the total atoms requested"
        puts "NATOM $natoms"
    } else {
	puts "NCOO 3"
        puts "# for 5 to 25 atoms, look for 30% of the total atoms requested"
        puts "NATOM $natoms"
    }

    set hi_res 4.0
        
#    set hi_res $XMLParse([join "crank soap run step=$step pmf hi_res" __])
    if { ( $hi_res != 4.0 ) } {
    puts "ISTL [expr 10*$hi_res]"
    }
    
    set scattering_power $XMLParse([join "crank soap run step=$step crunch2 scattering_power" __])
    puts "SCATT $scattering_power"

    if { $tcl } {
	puts "\nEND\""
	puts ""
	puts "set command \"\$command << \\\"\$script\\\" > pmf-logfile\""
	puts "eval exec \$command"
    } else {
	puts "END"
    }
}

global env

set inputxml [file join .. xml input.xml]

set inccp4 [lindex $argv 0]
set tcl    [lindex $argv 1]

source [file join $env(CRANK) bin crankutils.tcl]

if { [file exists $inputxml] == 0 } {
    crank_error "xml2pmfscript.tcl::inputxml file does not exist"
}

XMLParsefile $inputxml

OutputPMFscriptfile $inccp4 $tcl