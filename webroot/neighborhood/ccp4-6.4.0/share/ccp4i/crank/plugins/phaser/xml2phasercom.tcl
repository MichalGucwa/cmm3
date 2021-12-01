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
proc OutputPhasercomfile { executable pdb } {
    global XMLParse

    set step $XMLParse(crank__soap__current_step)
    set orig_pwd $XMLParse(crank__soap__orig_pwd)
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    puts "\#!/bin/sh"
    puts " "

    set mtz_in [file join .. workdb crank.in.$tag.mtz]

    puts "$executable << END > phaser-logfile"
    puts " "
    puts "MODE MR_AUTO"
    puts "HKLIN  $mtz_in"
    puts "SGALTERNATIVE ALL"

    if { ( [info exists XMLParse([join "crank parameters ref_crystal" __])]  && 
           [info exists XMLParse([join "crank parameters ref_dataset" __])] ) } {
 	set c $XMLParse([join "crank parameters ref_crystal" __])
	set d $XMLParse([join "crank parameters ref_dataset" __])
	if { [info exists XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d f" __])] &&
	     [info exists XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d sigf" __])] } {
	    set in_f $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d f" __])
	    set in_sigf $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d sigf" __])
 	    puts "LABIN F=$in_f SIGF=$in_sigf"
	} else {
	    crank_error "reference crystal and data set does not have structure factor amplitude and/or sigma"
	}
    } else {
	set i 1
	set found 0
	while { ( [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] && 
		  [!$found] ) } { 

	    if { [info exists XMLParse([join "crank parameters crystal=$i native" __])] &&
		 $XMLParse([join "crank parameters crystal=$i native" __]) == "0"} { 

	    } 

	    set j 1
	    while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] && [!$found] } { 

		# Output the columns for this dataset
		set input_f $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j f" __])
		set input_sigf $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j sigf" __])
		
		puts "LABIN F=$input_f SIGF=$input_sigf"
		set found 1
		break
		incr j
	    }
	    incr i
	}
	if { !$found } {
	    crank_error "no structure factor amplitude found"
	}
    }

    if { [info exists XMLParse([join "crank parameters nmonomers" __])] } {
	set nmon $XMLParse([join "crank parameters nmonomers" __])
    } else {
	crank_error "number of monomers not specified"
    }

    if { [info exists XMLParse([join "crank parameters sequence" __])] } {
	        set seq [open sequence.pir w+]
        puts $seq ">\n"
        regsub -all {[^a-zA-Z]} $XMLParse([join "crank parameters sequence" __]) "" sequence
        for {set i 0 } { $i < [string length $sequence] } { incr i 60 } {
            if { [expr $i + 59] <  [string length $sequence] } {
                puts $seq "[string range $sequence $i [expr $i + 59] ]"
            } else {
                puts $seq "[string range $sequence $i  end]"
            }
        }
        flush $seq
        close $seq
	puts "COMPOSITION PROTEIN SEQ [file join [pwd] sequence.pir] "
    } else {
	if { [info exists XMLParse([join "crank parameters residues" __])] } {
	    set nres $XMLParse([join "crank parameters residues" __])
	    if { $nres > 0 } {
		puts "COMPOSITON PROTEIN NRES $nres"
	    }
	}
	if { [info exists XMLParse([join "crank parameters nucleotides" __])] } {
 	    set nnuc $XMLParse([join "crank parameters nucleotides" __])
	    puts "COMPOSITON NUCLEIC NRES $nnuc"
	}
    }

    puts "ENSEMBLE ensemble1 &"
    puts -nonewline "   PDBFILE $pdb"
    if { [info exists XMLParse([join "crank soap run step=$step phaser seq_sim" __])] } {
        set seq_sim $XMLParse([join "crank soap run step=$step phaser seq_sim" __]) 
	puts " &\n   IDENT $seq_sim"  
    } else { 
	puts ""
    }
    
    puts "SEARCH ENSEMBLE ensemble1 &"
    puts "  NUMBER $nmon"
    puts "END"
}

set inputxml [lindex $argv 0]
set pdb [lindex $argv 1]
set executable [lindex $argv 2]
set crankbin [lindex $argv 3]

# Set CRANK path
source [file join $crankbin crankutils.tcl]

#
# Check to make sure files exist
#
if { [file exists $inputxml] == 0 } {
    crank_error "xml2phasercom.tcl::inputxml file does not exist"
}

if { [file exists $pdb] == 0 } {
    crank_error "xml2phasercom.tcl::pdb file does not exist"
}

XMLParsefile $inputxml

OutputPhasercomfile $executable $pdb
