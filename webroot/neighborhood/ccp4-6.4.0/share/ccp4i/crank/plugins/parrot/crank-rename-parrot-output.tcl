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

proc rename_input_columns { step mtzin mtzout bias ncycles } {
    global XMLParse
   
    set c $XMLParse([join "crank parameters ref_crystal" __])
    set d $XMLParse([join "crank parameters ref_dataset" __])
    set in_fp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d f" __])
    set in_sigfp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d sigf" __])

    set outf $XMLParse([join "crank soap run step=$step output phase_columns f" __])
    set outsigf $XMLParse([join "crank soap run step=$step output phase_columns sigf" __])
    set outphib $XMLParse([join "crank soap run step=$step output phase_columns phib" __])
    set outfom $XMLParse([join "crank soap run step=$step output phase_columns fom" __])

    set outhla $XMLParse([join "crank soap run step=$step output hl_columns hla" __])
    set outhlb $XMLParse([join "crank soap run step=$step output hl_columns hlb" __])
    set outhlc $XMLParse([join "crank soap run step=$step output hl_columns hlc" __])
    set outhld $XMLParse([join "crank soap run step=$step output hl_columns hld" __])

    set sftools_script "read temp.mtz\n set label col $in_fp \n $outf \n set label col $in_sigfp \n $outsigf \n"

    if { $bias } {
	file copy parrot.mtz temp.mtz
	#file delete parrot.mtz
 	set script "read parrot.mtz\n set label col PHIB \n $outphib\n set label col FOM \n $outfom \n write temp1.mtz col $outphib $outfom\n quit\n"
        set command "sftools << \"$script\""
#        puts $command
        catch {eval exec $command } output 
        # puts $output
    } else {
	# first run chltofom to get fom/phi from hl-coefficients
	set script "start -mtzin $mtzin -mtzout temp.mtz -colin-hl /*/*/\\\[${step}_PARROT.ABCD.A,${step}_PARROT.ABCD.B,${step}_PARROT.ABCD.C,${step}_PARROT.ABCD.D\\\] -colout /*/*/\\\[$outphib,$outfom\\\]"
	set command "chltofom <<$script"
	catch {eval exec $command} output
    }

    set phasingcoefficients 1

    if { [info exists XMLParse([join "crank soap run step=$step parrot hlphasing_coefficients " __])] } {
	set phasingcoefficients $XMLParse([join "crank soap run step=$step parrot hlphasing_coefficients" __])
    } 

    if { $phasingcoefficients } {
	set temptag [string trim $XMLParse([join "crank soap run step=$step input hl_columns hla" __])]
	set phasingtag [string trim $temptag _HLA]
	set hla _HLA
	set hlb _HLB
	set hlc _HLC
	set hld _HLD
	set sftools_script "$sftools_script set label col [format "%s%s" $phasingtag $hla] \n $outhla  \n"
	set sftools_script "$sftools_script set label col [format "%s%s" $phasingtag $hlb] \n $outhlb  \n"
	set sftools_script "$sftools_script set label col [format "%s%s" $phasingtag $hlc] \n $outhlc  \n"
	set sftools_script "$sftools_script set label col [format "%s%s" $phasingtag $hld] \n $outhld  \n"
    } else {
	if { $bias } {
	    set sftools_script "$sftools_script set label col HLA \n $outhla\n set label col HLB \n $outhlb \n"
	    set sftools_script "$sftools_script set label col HLC \n $outhlc\n set label col HLD \n $outhld \n "
	} else { 
	    set sftools_script "$sftools_script set label col ${step}_PARROT_ABCD.A \n $outhla\n set label col ${step}_PARROT_ABCD.B \n $outhlb \n"
	    set sftools_script "$sftools_script set label col ${step}_PARROT_ABCD.C \n $outhlc\n set label col ${step}_PARROT_ABCD.D\n $outhld \n "
	}
    }

    if { $bias } {
	set sftools_script "$sftools_script read temp1.mtz\n"
    }
    set sftools_script "$sftools_script write $mtzout col $outf $outsigf $outphib $outfom $outhla $outhlb $outhlc $outhld\n"
    set sftools_script "$sftools_script quit \n"

    set command "sftools << \"$sftools_script\""
#    puts $command
    catch {eval exec $command } output 
#    puts $output
    file delete temp.mtz
    if { [file exists temp1.mtz] } {
       file delete temp1.mtz
    }
}

global env

source [file join $env(CRANK) bin crankutils.tcl]

if { [file exists [file join .. xml input.xml] ] } {
    set inputxml     [file join .. xml input.xml]
} elseif { [file exists [file join .. .. xml input.xml] ] } {
    set inputxml     [file join .. .. xml input.xml]
} else {
    crank_error "crank::crank-rename-parrot-output.tcl:: input.xml file not found"
}

set mtzin     [lindex $argv 0]
set mtzout    [lindex $argv 1]
set bias      [lindex $argv 2]
set ncycles   [lindex $argv 3]



XMLParsefile $inputxml

set step $XMLParse(crank__soap__current_step)

rename_input_columns $step $mtzin $mtzout $bias $ncycles


