#!/usr/bin/env tclsh
#
# Copyright (C) Navraj S. Pannu 2006,  Leiden University
#
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

proc rename_input_columns { step mtzin mtzout } {
    global XMLParse

    set nc 0
    set maxc 0
    set maxd 0
    set maxfpp 0

    # ***NSP
    set mode "PHASE"

    set i 1
    while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } {
        set j 1
        while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } {
	    if { $XMLParse([join "crank parameters crystal=$i data=$j anomalous" __]) == 1 } { 
		set k 1
		while { [info exists XMLParse([join "crank parameters crystal=$i data=$j atom=$k fprimeprime" __])] } {

		    if { $XMLParse([join "crank parameters crystal=$i data=$j atom=$k fprimeprime" __]) > $maxfpp } {
			set maxc $i
			set maxd $j
			set maxfpp $XMLParse([join "crank parameters crystal=$i data=$j atom=$k fprimeprime" __])
		    }
		    incr k
		}
	    } elseif { $XMLParse([join "crank parameters crystal=$i native" __]) == 1 } { 
		set nc $i
	    }
	    incr j
        }
        incr i
    }

    set c $XMLParse([join "crank parameters ref_crystal" __])
    set d $XMLParse([join "crank parameters ref_dataset" __])

    if { ($nc > 0) && ($maxc > 0) && ($maxd > 0) } {
	# SIRAS
	set in_f $XMLParse([join "crank soap run step=$step input exp_columns crystal=$nc data=1 f" __])
	set in_sigf $XMLParse([join "crank soap run step=$step input exp_columns crystal=$nc data=1 sigf" __])
    } elseif { ($maxc > 0) && ($maxd > 0) } { 
	# SAD
	set in_f $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd f" __])
	set in_sigf $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd sigf" __])
    } else { 
	set in_f $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d f" __])
	set in_sigf $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d sigf" __])
    }

    set outf $XMLParse([join "crank soap run step=$step output phase_columns f" __])
    set outsigf $XMLParse([join "crank soap run step=$step output phase_columns sigf" __])
    set outphib $XMLParse([join "crank soap run step=$step output phase_columns phib" __])
    set outfom $XMLParse([join "crank soap run step=$step output phase_columns fom" __])

    if { $mode == "PHASE" } {
	set outhla $XMLParse([join "crank soap run step=$step output hl_columns hla" __])
	set outhlb $XMLParse([join "crank soap run step=$step output hl_columns hlb" __])
	set outhlc $XMLParse([join "crank soap run step=$step output hl_columns hlc" __])
	set outhld $XMLParse([join "crank soap run step=$step output hl_columns hld" __])
    }

    set sftools_script "read $mtzin\n set label col $in_f \n $outf  \n set label col $in_sigf \n $outsigf \n"
    set sftools_script "$sftools_script set label col PHIB \n $outphib\n set label col FOM \n $outfom \n "
    if { $mode == "PHASE" } {
	set sftools_script "$sftools_script set label col HLA \n $outhla  \n set label col HLB \n $outhlb \n "
	set sftools_script "$sftools_script set label col HLC \n $outhlc  \n set label col HLD \n $outhld \n "
    }
    set sftools_script "$sftools_script write $mtzout col $outf $outsigf $outphib $outfom "
    if { $mode == "PHASE" } {
	set sftools_script "$sftools_script $outhla $outhlb $outhlc $outhld\n"
    }
    set sftools_script "$sftools_script quit \n"

    set command "sftools << \"$sftools_script\""
    puts $command
    catch {eval exec $command } output 
    puts $output

}

global env

set inputxml [file join .. xml input.xml]

source [file join $env(CRANK) bin crankutils.tcl]

if { [file exists $inputxml] == 0 } {
    crank_error "crank::inputxml file does not exist"
}

set mtzin  [lindex $argv 0]
set mtzout [lindex $argv 1]

XMLParsefile $inputxml

set step $XMLParse(crank__soap__current_step)

rename_input_columns $step $mtzin $mtzout

exit
