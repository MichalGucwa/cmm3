#!/usr/bin/env tclsh

# Copyright (C) Navraj S. Pannu 2006 Leiden University
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
   
    set c $XMLParse([join "crank parameters ref_crystal" __])
    set d $XMLParse([join "crank parameters ref_dataset" __])
    set in_fp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d f" __])
    set in_sigfp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d sigf" __])

    set outf $XMLParse([join "crank soap run step=$step output phase_columns f" __])
    set outsigf $XMLParse([join "crank soap run step=$step output phase_columns sigf" __])
    set outphib $XMLParse([join "crank soap run step=$step output phase_columns phib" __])
    set outfom $XMLParse([join "crank soap run step=$step output phase_columns fom" __])

    set sftools_script "read $mtzin\n set label col $in_fp \n $outf \n set label col $in_sigfp \n $outsigf \n"

    set phase_restrain ""

    if { [info exists XMLParse([join "crank soap run step=$step arpwarp phase_restrain" __])] } {
       set phase_restrain $XMLParse([join "crank soap run step=$step arpwarp phase_restrain" __])
    }

    if { [string compare $phase_restrain "MLHL"] == 0 } {
	 set sftools_script "$sftools_script set label col PHCOMB \n $outphib \n"
     } else {
	 set sftools_script "$sftools_script set label col PHWT \n $outphib \n"
     }

    set sftools_script "$sftools_script set label col FOM \n $outfom \n"

    if { [info exists XMLParse([join "crank soap run step=$step input freer_columns freer" __])] } {
	set in_freer $XMLParse([join "crank soap run step=$step input freer_columns freer" __])
	set out_freer $XMLParse([join "crank soap run step=$step output freer_columns freer" __])
	set sftools_script "$sftools_script set label col $in_freer \n $out_freer \n"
 	set sftools_script "$sftools_script write $mtzout col $outf $outsigf $outphib $outfom $out_freer\n quit \n"
    } else {
	set sftools_script "$sftools_script write $mtzout col $outf $outsigf $outphib $outfom\n quit \n"
    }

    set command "sftools << \"$sftools_script\""
#   puts $command
    catch {eval exec $command } output 
#   puts $output
}

set inputxml [file join [pwd] [lindex $argv 0]]
if { [file exists $inputxml] == 0 } {
   crank_error "crank::inputxml file does not exist"
}

set mtzin [lindex $argv 1]
set mtzout [lindex $argv 2]
set crankbin [lindex $argv 3]

source [file join $crankbin crankutils.tcl]

XMLParsefile $inputxml

set step $XMLParse(crank__soap__current_step)

set orig_pwd [pwd]

rename_input_columns $step $mtzin $mtzout

exit
