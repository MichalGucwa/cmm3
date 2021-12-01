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
proc OutputBricsscriptfile { executable pdb tcl } {
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

    set mtz_out "brics.out.mtz"
    
    if { $tcl } {
	puts "set command \"$executable HKLIN $mtz_in HKLOUT $mtz_out\""
    } else {
	puts "$executable HKLIN $mtz_in HKLOUT $mtz_out << END > brics-logfile 2>&1"
    }
    puts " "

    # Loop over all crystal/dataset pairs
    #
    # Loop over all crystal/datasets outputting XTAL/DNAME sections for each
    #

    if { $tcl } {
	puts -nonewline "set script \""
    }

    set i 1
    while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } { 

	# Start the XTAL section

	puts "XTAL crystal${i}"

	if { [info exists XMLParse([join "crank parameters crystal=$i native" __])] &&
	     $XMLParse([join "crank parameters crystal=$i native" __]) == "0"} { 

	} 

	set j 1
	while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } { 
	    # Start the DNAME section
	    set type $XMLParse([join "crank parameters crystal=$i data=$j type" __])	    

	    puts "  DNAME ${type}_${i}_${j}"
# ***NSP
	    puts "  RESOL 2.5 20"

	    # Output the columns for this dataset
	    set input_f $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j f" __])
	    set input_sigf $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j sigf" __])
		
	    puts "    COLUMN F=$input_f SF=$input_sigf"
	    incr j
	}
	incr i
    }

	
    #
    # Brics Options
    #
    if { [info exists XMLParse([join "crank soap run step=$step brics spg_trial" __])] } {
        set spg_trial $XMLParse([join "crank soap run step=$step brics spg_trial" __])
    }

    if { [info exists XMLParse([join "crank soap run step=$step brics num_monomer" __])] } {
        set num_monomer $XMLParse([join "crank soap run step=$step brics num_monomer" __])
    }

    if { [info exists XMLParse([join "crank soap run step=$step brics final_pdb" __])] } {
        if { [file exists $XMLParse([join "crank soap run step=$step brics final_pdb" __])] } {
	    set final_pdb $XMLParse([join "crank soap run step=$step brics final_pdb" __])
	}
    }

    if { [info exists XMLParse([join "crank soap run step=$step brics search" __])] } {
	if { $XMLParse([join "crank soap run step=$step brics search" __]) == "rotation" } {
	    set search "ROT"
	} elseif { $XMLParse([join "crank soap run step=$step brics search" __]) == "translation" } {
	    set search "TRN"
	} else {
	    set search "RTN"
	}
    } else {
	set search "RTN"
    }

    if { [info exists XMLParse([join "crank soap run step=$step brics rot_function algorithm" __])] } {
	if { $XMLParse([join "crank soap run step=$step brics rot_function algorithm" __]) == "correlation" } {
	    set rot_func "COR"
	} else {
	    set rot_func "GAU"
	}
    } else {
	set rot_func "GAU"
    }
    if { [info exists XMLParse([join "crank soap run step=$step brics rot_function mr_rot_min" __])] } {
        set mr_rot_min $XMLParse([join "crank soap run step=$step brics rot_function mr_rot_min" __]) }
    if { [info exists XMLParse([join "crank soap run step=$step brics rot_function mr_rot_max" __])] } {
        set mr_rot_max $XMLParse([join "crank soap run step=$step brics rot_function mr_rot_max" __]) }
    if { [info exists XMLParse([join "crank soap run step=$step brics rot_function b_max" __])] } {
        set b_max $XMLParse([join "crank soap run step=$step brics rot_function b_max" __]) }
    if { [info exists XMLParse([join "crank soap run step=$step brics rot_function seq_sim" __])] } {
        set seq_sim $XMLParse([join "crank soap run step=$step brics rot_function seq_sim" __]) }
    if { [info exists XMLParse([join "crank soap run step=$step brics rot_function aniso_cutoff_rot" __])] } {
        set aniso_cutoff_rot $XMLParse([join "crank soap run step=$step brics rot_function aniso_cutoff_rot" __]) }
    if { [info exists XMLParse([join "crank soap run step=$step brics rot_function Bsol" __])] } {
        set Bsol $XMLParse([join "crank soap run step=$step brics rot_function Bsol" __]) }
    if { [info exists XMLParse([join "crank soap run step=$step brics rot_function fsol" __])] } {
        set fsol $XMLParse([join "crank soap run step=$step brics rot_function fsol" __]) }
    if { [info exists XMLParse([join "crank soap run step=$step brics rot_function f_fr" __])] } {
        set f_fr $XMLParse([join "crank soap run step=$step brics rot_function f_fr" __]) }

    if { [info exists XMLParse([join "crank soap run step=$step brics tran_function algorithm" __])] } {
	if { $XMLParse([join "crank soap run step=$step brics tran_function algorithm" __]) == "correlation" } {
	    set trans_func "COR"
	} else {
	    set trans_func "GAU"
	}
    } else {
	set trans_func "GAU"
    }
    if { [info exists XMLParse([join "crank soap run step=$step brics tran_function mr_tr_min" __])] } {
        set mr_tr_min $XMLParse([join "crank soap run step=$step brics tran_function mr_tr_min" __]) }
    if { [info exists XMLParse([join "crank soap run step=$step brics tran_function mr_tr_max" __])] } {
        set mr_tr_max $XMLParse([join "crank soap run step=$step brics tran_function mr_tr_max" __]) }
    if { [info exists XMLParse([join "crank soap run step=$step brics tran_function aniso_cutoff_tr" __])] } {
        set aniso_cutoff_tr $XMLParse([join "crank soap run step=$step brics tran_function aniso_cutoff_tr" __]) }

    if { [info exists XMLParse([join "crank soap run step=$step brics so3_parameters bwIn" __])] } {
        set bwIn $XMLParse([join "crank soap run step=$step brics so3_parameters bwIn" __]) }
    if { [info exists XMLParse([join "crank soap run step=$step brics so3_parameters bwOut" __])] } {
        set bwOut $XMLParse([join "crank soap run step=$step brics so3_parameters bwOut" __]) }
    if { [info exists XMLParse([join "crank soap run step=$step brics so3_parameters degLim" __])] } {
        set degLim $XMLParse([join "crank soap run step=$step brics so3_parameters degLim" __]) }
    if { [info exists XMLParse([join "crank soap run step=$step brics so3_parameters bessel_nmax" __])] } {
        set bessel_nmax $XMLParse([join "crank soap run step=$step brics so3_parameters bessel_nmax" __]) }

    set mrq_text "  MRQ $pdb $search"
    if { [info exists final_pdb] } {
        set mrq_text "$mrq_text  $final_pdb"
    }
    puts "$mrq_text"
#    puts "  ROT $rot_func"
    puts "  ROT $rot_func $mr_rot_min $mr_rot_max $b_max $seq_sim $aniso_cutoff_rot $Bsol $fsol $f_fr"
#
#   puts "  ROT GAU -1 -1 12 0.5 0.1"
#    puts "  TRN $trans_func"
    puts "  TRN $trans_func $mr_tr_min $mr_tr_max $aniso_cutoff_tr PAK"
    puts "  SO3 $bwIn $bwOut $degLim $bessel_nmax"
    if { [info exists spg_trial] } {
        puts "  SPG $spg_trial"
    }
    if { [info exists num_monomer] } {
        puts "  NMN $num_monomer"
    }

    if { $tcl } {
	puts "\nEND\""
	puts ""
	puts "set command \"\$command << \\\"\$script\\\" > brics-logfile\""
	puts "eval exec \$command"
    } else {
	puts "END"
    }
}

set inputxml   [lindex $argv 0]
set pdb        [lindex $argv 1]
set executable [lindex $argv 2]
set crankbin   [lindex $argv 3]
set tcl        [lindex $argv 4]

source [file join $crankbin crankutils.tcl]

if { [file exists $inputxml] == 0 } {
    crank_error "xml2bricsscript.tcl::inputxml file does not exist"
}

if { [file exists $pdb] == 0 } {
    crank_error "xml2bricsscript.tcl::pdb file does not exist"
}

XMLParsefile $inputxml

OutputBricsscriptfile $executable $pdb $tcl
