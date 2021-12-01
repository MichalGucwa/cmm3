#!/usr/bin/env tclsh

# Copyright (C) Navraj S. Pannu 2006,  Leiden University
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
    global debug

    set sftools_script "read $mtzin\n"

    set i 1
    while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } { 
	set j 1
	while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } { 
	    if { [string compare $XMLParse([join "crank parameters crystal=$i data=$j anomalous" __]) "0"] == 0 } {
		set in_f "IN_X${i}_D${j}_F"
		set in_sigf "IN_X${i}_D${j}_SIGF"

		set out_f $XMLParse([join "crank soap run step=$step output exp_columns crystal=$i data=$j f" __])
		set out_sigf $XMLParse([join "crank soap run step=$step output exp_columns crystal=$i data=$j sigf" __])

 		set sftools_script "$sftools_script set label col $in_f\n $out_f\n set label col $in_sigf\n$out_sigf\n"

		if { [string compare $XMLParse([join "crank parameters input_intensity" __]) "1"] == 0 } {
 		    set in_i "IN_X${i}_D${j}_I"
		    set in_sigi "IN_X${i}_D${j}_SIGI"

		    set out_i $XMLParse([join "crank soap run step=$step output exp_columns crystal=$i data=$j i" __])
		    set out_sigi $XMLParse([join "crank soap run step=$step output exp_columns crystal=$i data=$j sigi" __])

		    set sftools_script "$sftools_script set label col $in_i\n\$out_i\n set label col $in_sigi\n$out_sigi\n"
		}

	    } else {
		set in_f "IN_X${i}_D${j}_F"
		set in_sigf "IN_X${i}_D${j}_SIGF"
		set in_f_plus "IN_X${i}_D${j}_F+"
		set in_sigf_plus "IN_X${i}_D${j}_SIGF+"
		set in_f_minus "IN_X${i}_D${j}_F-"
		set in_sigf_minus "IN_X${i}_D${j}_SIGF-"
				
		set out_f $XMLParse([join "crank soap run step=$step output exp_columns crystal=$i data=$j f" __])
		set out_sigf $XMLParse([join "crank soap run step=$step output exp_columns crystal=$i data=$j sigf" __])
		set out_f_plus $XMLParse([join "crank soap run step=$step output exp_columns crystal=$i data=$j f_plus" __])
		set out_sigf_plus $XMLParse([join "crank soap run step=$step output exp_columns crystal=$i data=$j sigf_plus" __])
		set out_f_minus $XMLParse([join "crank soap run step=$step output exp_columns crystal=$i data=$j f_minus" __])
		set out_sigf_minus $XMLParse([join "crank soap run step=$step output exp_columns crystal=$i data=$j sigf_minus" __])

		set sftools_script "$sftools_script set label col $in_f\n$out_f\nset label col $in_sigf\n$out_sigf\n"
		set sftools_script "$sftools_script set label col $in_f_plus\n$out_f_plus\nset label col $in_sigf_plus\n$out_sigf_plus\n"
		set sftools_script "$sftools_script set label col $in_f_minus\n$out_f_minus\nset label col $in_sigf_minus\n$out_sigf_minus\n"

		if { [string compare $XMLParse([join "crank parameters input_intensity" __]) "1"] == 0 } {

 		    set in_i "IN_X${i}_D${j}_I"
		    set in_sigi "IN_X${i}_D${j}_SIGI"
		    set in_i_plus "IN_X${i}_D${j}_I+"
		    set in_sigi_plus "IN_X${i}_D${j}_SIGI+"
		    set in_i_minus "IN_X${i}_D${j}_I-"
		    set in_sigi_minus "IN_X${i}_D${j}_SIGI-"
		    
		    set sftools_script "$sftools_script delete col $in_i $in_sigi\n"
		    set out_i_plus $XMLParse([join "crank soap run step=$step output exp_columns crystal=$i data=$j i_plus" __])
		    set out_sigi_plus $XMLParse([join "crank soap run step=$step output exp_columns crystal=$i data=$j sigi_plus" __])
		    set out_i_minus $XMLParse([join "crank soap run step=$step output exp_columns crystal=$i data=$j i_minus" __])
		    set out_sigi_minus $XMLParse([join "crank soap run step=$step output exp_columns crystal=$i data=$j sigi_minus" __])
		    set sftools_script "$sftools_script set label col $in_i_plus\n$out_i_plus\n set label col $in_sigi_plus\n$out_sigi_plus\n"
		    set sftools_script "$sftools_script set label col $in_i_minus\n$out_i_minus\n set label col $in_sigi_minus\n$out_sigi_minus\n"
		}
	    }
	    incr j
	}
	incr i
    }

    set sftools_script "$sftools_script delete col IN_FREER\nwrite $mtzout\n quit\n"

    set command "sftools << \"$sftools_script\""
#   puts $command
    catch {eval exec $command } output 
#   puts $output
}

global env

set inputxml [file join .. xml input.xml]
source       [file join $env(CRANK) bin crankutils.tcl]

if { [file exists $inputxml] == 0 } {
    crank_error "xml2scaleitscript.tcl::inputxml file does not exist"
}

set step     [lindex $argv 0]
set mtzin    [lindex $argv 1]
set mtzout   [lindex $argv 2]

if { [file exists $inputxml] == 0 } {
    crank_error "crank::inputxml file does not exist"
}

XMLParsefile $inputxml

rename_input_columns $step $mtzin $mtzout