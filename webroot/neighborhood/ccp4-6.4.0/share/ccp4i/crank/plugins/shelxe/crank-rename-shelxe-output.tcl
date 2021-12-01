#!/usr/bin/env tclsh
#
# Copyright (C) Navraj S. Pannu and Steven Ness 2004-2005, Leiden University
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

proc set_global_spacegroup { orig_pwd tag invert } {
    global XMLParse
    global cell_a cell_b cell_c
    global cell_alpha cell_beta cell_gamma
    global spacegroup
    global debug

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
   
    set step $XMLParse(crank__soap__current_step)

    if { [info exists XMLParse(crank__soap__run__standalone)] } {
        set inputmtz "[file join $orig_pwd run workdb crank.in.$tag.mtz]"
    } else {        
        set inputmtz "[file join $orig_pwd workdb crank.in.$tag.mtz]"
    }

    set name ""
    set hand ""

    spacegroup_from_mtz $inputmtz name spacegroup
    
    #spacegroup is enantiomorph of original
    if { $invert == "-i" } {    
	spacegroup_enantiomorph $spacegroup hand
	set spacegroup $hand
    }
}

proc convert_phs2mtz { step hklin mtzout } {
    global cell_a cell_b cell_c
    global cell_alpha cell_beta cell_gamma
    global spacegroup

    set mtz_command "HKLIN $hklin HKLOUT $mtzout"

    set mtz_script ""
    set mtz_script "${mtz_script}TITLE PHS to MTZ\n"
    set mtz_script "${mtz_script}NAME shelxc hkl convert\n"
    set mtz_script "${mtz_script}LABOUT H  K  L  F FOM PHIB SIGF\n"
    set mtz_script "${mtz_script}CTYPE  H  H  H  F W   P    Q\n"
    set mtz_script "${mtz_script}FORMAT '(3I4,2F9.2,F8.1,F9.2)'\n"
    set mtz_script "${mtz_script}CELL $cell_a $cell_b $cell_c $cell_alpha $cell_beta $cell_gamma\n"
    set mtz_script "${mtz_script}SYMM $spacegroup\n"
    set mtz_script "${mtz_script}END\n"

    set command "f2mtz $mtz_command << \"$mtz_script\""
    catch {eval exec $command } output 
#   puts $output
}

proc rename_input_columns { step mtzin1 mtzout } {
    global XMLParse
    global debug

    set sftools_script "read $mtzin1\n"

    set in_f "F"
    set in_sigf "SIGF"
    set in_fom "FOM"
    set in_phib "PHIB"

    set out_f $XMLParse([join "crank soap run step=$step output phase_columns f" __])
    set out_sigf $XMLParse([join "crank soap run step=$step output phase_columns sigf" __])
    set out_phib $XMLParse([join "crank soap run step=$step output phase_columns phib" __])
    set out_fom $XMLParse([join "crank soap run step=$step output phase_columns fom" __])
    set out_hla $XMLParse([join "crank soap run step=$step output hl_columns hla" __])
    set out_hlb $XMLParse([join "crank soap run step=$step output hl_columns hlb" __])
    set out_hlc $XMLParse([join "crank soap run step=$step output hl_columns hlc" __])
    set out_hld $XMLParse([join "crank soap run step=$step output hl_columns hld" __])

    set sftools_script "$sftools_script set label col $in_f \n   $out_f \n"
    set sftools_script "$sftools_script set label col $in_sigf \n $out_sigf \n"
    set sftools_script "$sftools_script set label col $in_fom  \n $out_fom \n"
    set sftools_script "$sftools_script set label col $in_phib \n $out_phib \n"
    set sftools_script "$sftools_script hlconv col $out_phib $out_fom \n"
    set sftools_script "$sftools_script set label col PA\n$out_hla\n"
    set sftools_script "$sftools_script set label col PB\n$out_hlb\n"
    set sftools_script "$sftools_script calc A col $out_hlc = 0\n"
    set sftools_script "$sftools_script calc A col $out_hld = 0\n"
    set sftools_script "$sftools_script write $mtzout\nquit\n"
 
    set command "sftools << \"$sftools_script\""
    puts $command
    catch {eval exec $command } output 
    puts $output
#    file delete $mtzin1 
}

global env

set inputxml [file join .. xml input.xml]
set hklin    [lindex $argv 0]
set mtzout   [lindex $argv 1]
set invert   [lindex $argv 2]

source [file join $env(CRANK) bin crankutils.tcl]

if { [file exists $inputxml] == 0 } {
    crank_error "crank-shelxe-rename-output.tcl::inputxml file does not exist"
}


XMLParsefile $inputxml

set step $XMLParse(crank__soap__current_step)
set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]
set orig_pwd $XMLParse(crank__soap__orig_pwd)

set_global_spacegroup $orig_pwd $tag $invert
convert_phs2mtz $step $hklin crank.phs.out.mtz

rename_input_columns $step crank.phs.out.mtz $mtzout

exit
