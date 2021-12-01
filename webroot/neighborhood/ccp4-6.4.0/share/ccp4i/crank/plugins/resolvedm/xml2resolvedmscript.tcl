#!/usr/bin/env tclsh
#
# Copyright (C) Navraj S. Pannu 2006-2009, Leiden University
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
proc OutputRESOLVEDMscriptfile { subfile solc tcl } {
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

    set ha_in $subfile

    set mtz_out "resolvedm.out.mtz"

    if { $tcl } {
	puts "set command \"resolve_giant\""
	puts -nonewline "set script \""
    } else {
	puts "resolve_giant << END > resolvedm-logfile"
    }

    puts "hklin temp.mtz"

    puts "solvent_content $solc"

    puts "modify"
    puts "model $ha_in"

    if { [file exists seq.dat] } {
	puts "seq_file seq.dat"
    }

    if { [info exists XMLParse([join "crank soap run step=$step resolvedm ncs" __])] } {
	if { $XMLParse([join "crank soap run step=$step resolvedm ncs" __]) } {
	    puts "ha_file $ha_in"
	}
    }
	
    puts "no_build"

    #
    # Input MTZ columns
    #

    set c $XMLParse([join "crank parameters ref_crystal" __])
    set d $XMLParse([join "crank parameters ref_dataset" __])

    set in_fp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d f" __])
    set in_sigfp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d sigf" __])

    # HL columns
    if { [info exists XMLParse([join "crank soap run step=$step input hl_columns hla" __])] &&
	  [string compare $XMLParse([join "crank soap run step=$step input hl_columns hla" __]) "NONE"] != 0 } {
	set in_hla $XMLParse([join "crank soap run step=$step input hl_columns hla" __])
	set in_hlb $XMLParse([join "crank soap run step=$step input hl_columns hlb" __])
	set in_hlc $XMLParse([join "crank soap run step=$step input hl_columns hlc" __])
	set in_hld $XMLParse([join "crank soap run step=$step input hl_columns hld" __])
     } else {
	crank_error "No Hendrickson-Lattman coefficients have been defined"
     }

    # Phase columns
    # first run chltofom to get fom/phi from hl-coefficients
    set script "start -mtzin $mtz_in -mtzout temp.mtz -colin-hl /*/*/\\\[$in_hla,$in_hlb,$in_hlc,$in_hld\\\] -colout /*/*/\\\[PHIB,FOM\\\]"

    set command "chltofom <<$script"
    catch {eval exec $command} output

    puts "labin FP=$in_fp SIGFP=$in_sigfp"
    puts "labin PHIB=PHIB FOM=FOM"

    puts "labin HLA=$in_hla HLB=$in_hlb"
    puts "labin HLC=$in_hlc HLD=$in_hld"

    puts "hklout $mtz_out"

    if { $tcl } {
	puts "\nEND\""
	puts ""
	puts "set command \"\$command << \\\"\$script\\\" > resolvedm-logfile\""
	puts "eval exec \$command"
    } else {
	puts "END"
    }
}

global env

set inputxml [file join .. xml input.xml]

set subfile  [lindex $argv 0]
set solv     [lindex $argv 1]
set tcl      [lindex $argv 2]

source [file join $env(CRANK) bin crankutils.tcl]

if { [file exists $inputxml] == 0 } {
    crank_error "xml2resolvedmscript.tcl::inputxml file does not exist"
}

XMLParsefile $inputxml

OutputRESOLVEDMscriptfile $subfile $solv $tcl
