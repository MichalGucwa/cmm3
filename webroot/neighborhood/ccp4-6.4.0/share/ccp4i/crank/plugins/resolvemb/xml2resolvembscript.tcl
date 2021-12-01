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

#
#
proc OutputRESOLVEBUILDscriptfile { subfile solc tcl } {
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

    set mtz_in "[file join .. workdb crank.in.$tag.mtz]"

    set mtz_out "resolvemb.out.mtz"

    if { $tcl } {
	puts "set command \"resolve_giant\""
	puts -nonewline "set script \""
    } else {
	puts "resolve_giant << END > resolvemb-logfile"
    }

    puts "hklin $mtz_in"

    if { [file exists seq.dat] } {
	puts "seq_file seq.dat"
    }

    if { [info exists XMLParse([join "crank soap run step=$step resolvemb ncs" __])] } {
        if { $XMLParse([join "crank soap run step=$step resolvemb ncs" __]) } {
            puts "ha_file $subfile"
        }
    }

    puts "build_only"

    if { [info exists XMLParse([join "crank soap run step=$step resolvemb type" __])] } {
	if { $XMLParse([join "crank soap run step=$step resolvemb type" __]) == "superquick" } {
            puts "superquick_build"
        } elseif { $XMLParse([join "crank soap run step=$step resolvemb type" __]) == "thorough" } {
            puts "thorough_build"
        } elseif { $XMLParse([join "crank soap run step=$step resolvemb type" __]) == "aggressive" } {
            puts "aggressive_build"
        } elseif { $XMLParse([join "crank soap run step=$step resolvemb type" __]) == "conservative" } {
            puts "conservative_build"
        }
    }

    puts "solvent_content $solc"

    #
    # Input MTZ columns
    #

    set c $XMLParse([join "crank parameters ref_crystal" __])
    set d $XMLParse([join "crank parameters ref_dataset" __])

    set in_fp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d f" __])
    set in_sigfp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d sigf" __])

    # Phase columns
    set in_phib $XMLParse([join "crank soap run step=$step input phase_columns phib" __])
    set in_fomo $XMLParse([join "crank soap run step=$step input phase_columns fom" __])

    # HL columns
    if { [info exists XMLParse([join "crank soap run step=$step input hl_columns hla" __])] &&
	  [string compare $XMLParse([join "crank soap run step=$step input hl_columns hla" __]) "NONE"] != 0 } {
	set in_hla $XMLParse([join "crank soap run step=$step input hl_columns hla" __])
	set in_hlb $XMLParse([join "crank soap run step=$step input hl_columns hlb" __])
	set in_hlc $XMLParse([join "crank soap run step=$step input hl_columns hlc" __])
	set in_hld $XMLParse([join "crank soap run step=$step input hl_columns hld" __])
     }

    puts "labin FP=$in_fp SIGFP=$in_sigfp"
    puts "labin PHIB=$in_phib FOM=$in_fomo"

#   if { [info exists XMLParse([join "crank soap run step=$step input hl_columns hla" __])] &&
#	 [string compare $XMLParse([join "crank soap run step=$step input hl_columns hla" __]) "NONE"] != 0 } {
#	puts "labin HLA=$in_hla HLB=$in_hlb"
#	puts "labin HLC=$in_hlc HLD=$in_hld"
#    } 

    puts "hklout $mtz_out"

    if { $tcl } {
	puts "\nEND\""
	puts ""
	puts "set command \"\$command << \\\"\$script\\\" > resolvemb-logfile\""
	puts "eval exec \$command"
    } else {
	puts "END"
    }
}

set inputxml [lindex $argv 0]
set subfile  [lindex $argv 1]
set crankbin [lindex $argv 2]
set solv     [lindex $argv 3]
set tcl      [lindex $argv 4]

if { [file exists $inputxml] == 0 } {
    crank_error "xml2resolvembscript.tcl::inputxml file does not exist"
}

source [file join $crankbin crankutils.tcl]

XMLParsefile $inputxml

OutputRESOLVEBUILDscriptfile $subfile $solv $tcl
