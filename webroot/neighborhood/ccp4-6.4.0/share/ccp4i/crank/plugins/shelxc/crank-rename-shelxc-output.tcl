#!/usr/bin/env tclsh
#
# Copyright (C) Navraj S. Pannu and Steven Ness 2004-2005, Leiden University
# Copyright (C) Navraj S. Pannu 2006-2007, Leiden University
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

proc set_global_spacegroup { orig_pwd tag } {
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

    set name ""
    set number ""
    set inputmtz "[file join .. workdb crank.out.IN.mtz]"

    spacegroup_from_mtz $inputmtz name number

    set spacegroup $number
}

proc convert_hkl2mtz { step hklin mtzout } {
    global XMLParse
    global cell_a cell_b cell_c
    global cell_alpha cell_beta cell_gamma
    global spacegroup

    set mtz_command "HKLIN $hklin HKLOUT $mtzout"

    set mtz_script ""
    set mtz_script "${mtz_script}TITLE HKL to MTZ\n"
    set mtz_script "${mtz_script}NAME shelxc hkl convert\n"
    if { [string compare $XMLParse([join "crank parameters input_intensity" __]) "1"] == 0 } {
	set mtz_script "${mtz_script}LABOUT H  K  L  I SIGI\n"
	set mtz_script "${mtz_script}CTYPE  H  H  H  J     Q\n"
    } else { 
	set mtz_script "${mtz_script}LABOUT H  K  L  F SIGF\n"
	set mtz_script "${mtz_script}CTYPE  H  H  H  F     Q\n"
    }
    set mtz_script "${mtz_script}FORMAT '(3I4,2F8.2)'\n"
    set mtz_script "${mtz_script}CELL $cell_a $cell_b $cell_c $cell_alpha $cell_beta $cell_gamma\n"
    set mtz_script "${mtz_script}SYMM $spacegroup\n"
    set mtz_script "${mtz_script}END\n"

    set command "f2mtz $mtz_command << \"$mtz_script\""
    catch {eval exec $command } output 
#   puts $output
}

proc convert_hklfa2mtz { step hklin mtzout } {
    global cell_a cell_b cell_c
    global cell_alpha cell_beta cell_gamma
    global spacegroup

    set mtz_command "HKLIN $hklin HKLOUT $mtzout"

    set mtz_script ""
    set mtz_script "${mtz_script}TITLE HKL to MTZ\n"
    set mtz_script "${mtz_script}NAME shelxc hkl_fa convert\n"
    set mtz_script "${mtz_script}LABOUT H  K  L  FA SIGFA ALPHA\n"
    set mtz_script "${mtz_script}CTYPE  H  H  H  F     Q    P\n"
    set mtz_script "${mtz_script}FORMAT '(3I4,2F8.2,I4)'\n"
    set mtz_script "${mtz_script}CELL $cell_a $cell_b $cell_c $cell_alpha $cell_beta $cell_gamma\n"
    set mtz_script "${mtz_script}SYMM $spacegroup\n"
    set mtz_script "${mtz_script}END\n"

    set command "f2mtz $mtz_command << \"$mtz_script\""
    catch {eval exec $command } output 
#   puts $output
}

proc rename_input_columns { step mtzin1 mtzin2 mtzout afro_exec } {
    global XMLParse
    global debug

    set cad_command "HKLIN1 $mtzin1 HKLIN2 $mtzin2 HKLOUT temp.mtz"

    set labin1 "LABIN FILE 1"
    set labin2 "LABIN FILE 2"
    set labout1 "LABOUT FILE 1"
    set labout2 "LABOUT FILE 2"

    if { [string compare $XMLParse([join "crank parameters input_intensity" __]) "1"] == 0 } {
      # I columns
       set in_i "I"
       set in_sigi "SIGI"
       set out_i $XMLParse([join "crank soap run step=$step output i_columns i" __])
       set out_sigi $XMLParse([join "crank soap run step=$step output i_columns sigi" __])
       set labin1 "$labin1 E1=$in_i E2=$in_sigi"
       set labout1 "$labout1 E1=$out_i E2=$out_sigi"
   } else { 
       # F columns
       set in_f "F"
       set in_sigf "SIGF"
       set out_f $XMLParse([join "crank soap run step=$step output f_columns f" __])
       set out_sigf $XMLParse([join "crank soap run step=$step output f_columns sigf" __])
       set labin1 "$labin1 E1=$in_f E2=$in_sigf"
       set labout1 "$labout1 E1=$out_f E2=$out_sigf"
   }

    # FA columns
    set in_fa "FA"
    set in_sigfa "SIGFA"
	
    # Alpha columns
    set in_alpha "ALPHA"

    #
    # Output
    #
	
    # FA columns
    set out_fa $XMLParse([join "crank soap run step=$step output fa_columns fa" __])
    set out_sigfa $XMLParse([join "crank soap run step=$step output fa_columns sigfa" __])

    # Alpha columns
    set out_alpha $XMLParse([join "crank soap run step=$step output alpha_columns alpha" __])

    set labin2 "$labin2 E1=$in_fa E2=$in_sigfa E3=$in_alpha"
    set labout2 "$labout2 E1=$out_fa E2=$out_sigfa E3=$out_alpha"

    #
    # Build the full CAD command
    #
    set cad_script "$labin1\n$labin2\n$labout1\n$labout2\n"
    if { [string compare $XMLParse([join "crank parameters input_intensity" __]) "1"] == 0 } {
      set cad_script "$cad_script\nCTYPIN FILE 1  E1=J E2=Q"
    } else {
      set cad_script "$cad_script\nCTYPIN FILE 1  E1=F E2=Q"
    }
    set cad_script "$cad_script\nCTYPIN FILE 2  E1=F E2=Q E3=P"
	
    #
    # Run CAD on the input provided
    #
    #puts "cad_command=($cad_command)"
    #puts "cad_script=($cad_script)"

    set command "cad $cad_command << \"$cad_script\""
#   puts $command
    catch {eval exec $command } output 
#   puts $output

    # add EA column
    set out_ea $XMLParse([join "crank soap run step=$step output ea_columns ea" __])
    set out_sigea $XMLParse([join "crank soap run step=$step output ea_columns sigea" __])

    set afro_script "XTAL CRYS\n  DNAM EVAL\n    COLU F=$out_fa SF=$out_sigfa\nLABO EA=$out_ea SGEA=$out_sigea\nEVAL\nALLIN\nEND\n"
    set command "$afro_exec HKLIN temp.mtz HKLOUT $mtzout << \"$afro_script\""
    catch {eval exec $command } output

    if { [file exists temp.mtz] } {
	file delete temp.mtz
    }
}

global env

set inputxml [file join .. xml input.xml]
set hklin    [lindex $argv 0]
set hklin2   [lindex $argv 1]
set mtzout   [lindex $argv 2]
set afro     [lindex $argv 3]

source [file join $env(CRANK) bin crankutils.tcl]

if { [file exists $inputxml] == 0 } {
    crank_error "crank-rename-shelxc-output.tcl::inputxml file does not exist"
}

XMLParsefile $inputxml

set step $XMLParse(crank__soap__current_step)
set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]
set orig_pwd $XMLParse(crank__soap__orig_pwd)

set_global_spacegroup $orig_pwd $tag
convert_hkl2mtz $step $hklin crank.out.mtz
convert_hklfa2mtz $step $hklin2 crank_fa.out.mtz

rename_input_columns $step crank.out.mtz crank_fa.out.mtz $mtzout $afro

file delete crank.out.mtz

file delete crank_fa.out.mtz
