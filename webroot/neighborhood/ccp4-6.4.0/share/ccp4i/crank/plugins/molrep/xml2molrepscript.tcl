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
proc OutputMolrepscriptfile { executable pdb tcl } {
    global XMLParse
	
    set step $XMLParse(crank__soap__current_step)
    set orig_pwd $XMLParse(crank__soap__orig_pwd)
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    if { $tcl } {
	puts "\#!/usr/bin/env tclsh"
    } else {
	puts "\#!/bin/sh"
    }

    puts " "

    set mtz_in "[file join .. workdb crank.in.$tag.mtz]"

    set mtz_out "molrep.out.mtz"

    if { $tcl } {
	puts "set command \"molrep -i\""
    } else {
	puts "molrep -i <<stop > molrep-logfile"
    }
    puts " "

    # Loop over all crystal/dataset pairs
    #
    # Loop over all crystal/datasets outputting XTAL/DNAME sections for each
    #
    if { $tcl } {
	puts -nonewline "set script \""
    }

    puts "_DOC Y"
    puts "_FILE_F  $mtz_in"

    set i 1
    while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } { 

	# Start the XTAL section

	#puts "XTAL crystal${i}"

	if { [info exists XMLParse([join "crank parameters crystal=$i native" __])] &&
	     $XMLParse([join "crank parameters crystal=$i native" __]) == "0"} { 

	} 

	set j 1
	while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } { 
	    # Start the DNAME section
	    set type $XMLParse([join "crank parameters crystal=$i data=$j type" __])	    

	    #puts "  DNAME ${type}_${i}_${j}"
# ***NSP
	    #puts "  RESOL 3 8"

	    # Output the columns for this dataset
	    set input_f $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j f" __])
	    set input_sigf $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j sigf" __])
		
	    #puts "    COLUMN F=$input_f SF=$input_sigf"
        puts "_F  $input_f"
        puts "_SIGF  $input_sigf"
	    incr j
	}
	incr i
    }

	
    #
    # Molrep Options
    #
    if { [info exists XMLParse([join "crank soap run step=$step molrep spg_trial" __])] } {
        set spg_trial $XMLParse([join "crank soap run step=$step molrep spg_trial" __])  }
    if { [info exists XMLParse([join "crank soap run step=$step molrep num_monomer" __])] } {
        set num_monomer $XMLParse([join "crank soap run step=$step molrep num_monomer" __])  }
    if { [info exists XMLParse([join "crank soap run step=$step molrep seq_sim" __])] } {
        set seq_sim $XMLParse([join "crank soap run step=$step molrep seq_sim" __]) }
    if { [info exists XMLParse([join "crank soap run step=$step molrep f_fr" __])] } {
        set f_fr $XMLParse([join "crank soap run step=$step molrep f_fr" __]) }

    if { [info exists XMLParse([join "crank soap run step=$step molrep final_pdb" __])] } {
        if { [file exists $XMLParse([join "crank soap run step=$step molrep final_pdb" __])] } {
	    set final_pdb $XMLParse([join "crank soap run step=$step molrep final_pdb" __])
	}
    }

    #if { [info exists XMLParse([join "crank soap run step=$step molrep search" __])] } {
	#if { $XMLParse([join "crank soap run step=$step molrep search" __]) == "rotation" } {
	#    set search "ROT"
	#} elseif { $XMLParse([join "crank soap run step=$step molrep search" __]) == "translation" } {
	#    set search "TRN"
	#} else {
	#    set search "RTN"
	#}
    #} else {
	#set search "RTN"
    #}

    #if { [info exists XMLParse([join "crank soap run step=$step molrep rot_function" __])] } {
	#if { $XMLParse([join "crank soap run step=$step molrep rot_function" __]) == "correlation" } {
	#    set rot_func "COR"
	#} else {
	#    set rot_func "GAU"
	#}
    #} else {
	#set rot_func "GAU"
    #}

    #if { [info exists XMLParse([join "crank soap run step=$step molrep trans_function" __])] } {
	#if { $XMLParse([join "crank soap run step=$step molrep trans_function" __]) == "correlation" } {
	#    set trans_func "COR"
	#} else {
	#    set trans_func "GAU"
	#}
    #} else {
	#set trans_func "GAU"
    #}


    #if { [info exists final_pdb] } {
	#puts "  MRQ $pdb $search $final_pdb"
    #} else {
	#puts "  MRQ $pdb $search"
    #}
    
    puts "_SURF O"
    puts "_MODE F"

#    if { [info exists spg_trial] } {
#	puts "_NOSG $spg_trial"
#    }
#    if { [info exists num_monomer] } {
#	puts "_NMON $num_monomer"
#    }
#    if { [info exists seq_sim] } {
#	puts "_SIM $seq_sim"
#    }
#    if { [info exists f_fr] } {
#	puts "_COMPL $f_fr"
#    }

#_SG ALL Doesn't work in CCP4 MOLREP. CCP4 bug!
        #puts "_NOSG ALL"
        #puts "_NOSG 20"
        puts "_RESMIN  20"
        puts "_RESMAX  3"

        puts "_FILE_M  $pdb"

    if { $tcl } {
	puts "\nstop\""
	puts ""
	puts "set command \"\$command << \\\"\$script\\\" > molrep-logfile\""
	puts "eval exec \$command"
    } else {
	puts "stop"
    }
}

set inputxml   [lindex $argv 0]
set pdb        [lindex $argv 1]
set executable [lindex $argv 2]
set crankbin   [lindex $argv 3]
set tcl        [lindex $argv 4]

source [file join $crankbin crankutils.tcl]

if { [file exists $inputxml] == 0 } {
    crank_error "xml2molrepscript.tcl::inputxml file does not exist"
}

if { [file exists $pdb] == 0 } {
    crank_error "xml2molrepscript.tcl::pdb file does not exist"
}

XMLParsefile $inputxml

OutputMolrepscriptfile $executable $pdb $tcl
