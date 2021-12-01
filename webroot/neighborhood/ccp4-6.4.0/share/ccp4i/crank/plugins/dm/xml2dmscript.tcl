#!/usr/bin/env tclsh
#
# Copyright (C) Navraj S. Pannu 2006, Leiden University
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
proc OutputDMscriptfile { enant solc tcl } {
    global XMLParse

    if { $tcl } {
	puts "\#!/usr/bin/env tclsh"
    } else {
	puts "\#!/bin/sh"
    }
    puts " "

    set step $XMLParse(crank__soap__current_step)
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    if { $enant == "1" } {
      set mtz_in "[file join .. .. workdb crank.in.$tag.mtz]"
    } else {
      set mtz_in "[file join .. .. workdb crank.in.$tag.oh.mtz]"
    } 

    set mtz_out "dm.out.mtz"

    if { $tcl } {
	puts "set command \"dm HKLIN $mtz_in HKLOUT $mtz_out\""

	puts -nonewline "set script \""
    } else {
	puts "dm HKLIN $mtz_in HKLOUT $mtz_out << END > dm-logfile"
    }

    set mode_solv $XMLParse([join "crank soap run step=$step dm mode_solv" __])
    set mode_hist $XMLParse([join "crank soap run step=$step dm mode_hist" __])

    set mode ""
    if { [string compare $mode_solv 1] == 0 } {
	set mode "SOLV "
    }
    if { [string compare $mode_hist 1] == 0 } {
	 set mode "${mode}HIST"
    }

    if { [string compare $mode_solv 1] == 0 || [string compare $mode_hist 1] == 0 } {
	puts "mode $mode"
    }

    # 	set combine $XMLParse([join "crank soap run step=$step dm combine" __])
    # 	puts "combine $combine"
    
    # 	set scheme $XMLParse([join "crank soap run step=$step dm scheme" __])
    # 	puts "scheme $scheme"

    set ncycles $XMLParse([join "crank soap run step=$step dm ncycles" __])
    puts "ncycles $ncycles"

    puts "solc $solc"
	
    if { [info exists XMLParse([join "crank soap run step=$step dm ncsmask" __])] } {
	puts "ncsmask"
    }

    #
    # Input MTZ columns
    #

    set c $XMLParse([join "crank parameters ref_crystal" __])
    set d $XMLParse([join "crank parameters ref_dataset" __])

    set in_fp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d f" __])
    set in_sigfp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d sigf" __])

    set in_hla $XMLParse([join "crank soap run step=$step input hl_columns hla" __])
    set in_hlb $XMLParse([join "crank soap run step=$step input hl_columns hlb" __])
    set in_hlc $XMLParse([join "crank soap run step=$step input hl_columns hlc" __])
    set in_hld $XMLParse([join "crank soap run step=$step input hl_columns hld" __])
    #
    # Output 
    #

    # HL columns
    set out_hla $XMLParse([join "crank soap run step=$step output hl_columns hla" __])
    set out_hlb $XMLParse([join "crank soap run step=$step output hl_columns hlb" __])
    set out_hlc $XMLParse([join "crank soap run step=$step output hl_columns hlc" __])
    set out_hld $XMLParse([join "crank soap run step=$step output hl_columns hld" __])
	
    puts "LABIN  FP=$in_fp SIGFP=$in_sigfp HLA=$in_hla HLB=$in_hlb HLC=$in_hlc HLD=$in_hld"
    puts "LABOUT  FDM=FDM PHIDM=PHIDM FOMDM=FOMDM HLADM=HLADM HLBDM=HLBDM HLCDM=HLCDM HLDDM=HLDDM"

    if { $tcl } {
	puts "\nEND\""
	puts ""
	puts "set command \"\$command << \\\"\$script\\\" > dm-logfile\""
	puts "eval exec \$command"
    } else {
	puts "END"
    }
}

global env

if { [file exists [file join .. xml input.xml] ] } { 
    set inputxml     [file join .. xml input.xml]
} elseif { [file exists [file join .. .. xml input.xml] ] } { 
    set inputxml     [file join .. .. xml input.xml]
} else {
    crank_error "crank::xml2dmscript.tcl:: input.xml file not found"
}

set enant    [lindex $argv 0]
set solv     [lindex $argv 1]
set tcl      [lindex $argv 2]

source [file join $env(CRANK) bin crankutils.tcl]

XMLParsefile $inputxml

OutputDMscriptfile $enant $solv $tcl
