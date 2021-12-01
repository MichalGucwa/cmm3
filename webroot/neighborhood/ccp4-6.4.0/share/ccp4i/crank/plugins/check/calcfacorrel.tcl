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

proc CalcFACorrel { crankplugins step final_sub mtzin bp3_exec} {
    global XMLParse


    if { [info exists XMLParse([join "crank soap run step=$step input ea_columns ea" __])] } {
	set in_ea $XMLParse([join "crank soap run step=$step input ea_columns ea" __])
	set in_sigea $XMLParse([join "crank soap run step=$step input ea_columns sigea" __])
    }

    if { [info exists XMLParse([join "crank soap run step=$step input fa_columns fa" __])] } {
	set in_fa $XMLParse([join "crank soap run step=$step input fa_columns fa" __])
	set in_sigfa $XMLParse([join "crank soap run step=$step input fa_columns sigfa" __])
    }

    # final FA and EA

    # only SAD requested, so find crystal and data set with maximal f"
    set maxc 0
    set maxd 0
    set maxfpp 0

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
	    }
	    incr j
	}
	incr i
    }

    if { ($maxc < 1) || ($maxd < 1) } {
	crank_error "One anomalous data set is needed"
    } 

    set in_fp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd f_plus" __])
    set in_sigfp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd sigf_plus" __])
    set in_fm $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd f_minus" __])
    set in_sigfm $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd sigf_minus" __])

    set mtzout "facalc.mtz"

    set bp3_script "XTAL CRYS\n  MODL $final_sub\n  DNAM EVAL\n    COLU F+=$in_fp SF+=$in_sigfp F-=$in_fm SF-=$in_sigfm\nFHOU\nALLIN\nCYCL 0\nEND\n"
    set command "$bp3_exec HKLIN $mtzin HKLOUT $mtzout << \"$bp3_script\""
    catch {eval exec $command } output

    # calc correlations
    set sftools_script "read $mtzout\n"
    if { [info exists in_ea] } {
	set sftools_script "$sftools_script correl col $in_ea HECALC\n"
    }
    if { [info exists in_fa] } {
	set sftools_script "$sftools_script correl col $in_fa HFCALC\n"
    }
    set sftools_script "$sftools_script quit\ny\n"
    set command "sftools << \"$sftools_script\" "
    catch {eval exec $command } output
    set logfile [open "check-logfile" a]
    puts $logfile $output
    close $logfile

#    if { [file exists $mtzout] } {
#	file delete $mtzout
#    }
}

set inputxml      [lindex $argv 0]
set crankbin      [lindex $argv 1]
set crankplugins  [lindex $argv 2]
set final_sub     [lindex $argv 3]
set mtzin         [lindex $argv 4]
set bp3_exec      [lindex $argv 5]

source [file join $crankbin crankutils.tcl]

if { [file exists $inputxml] == 0 } {
    crank_error "substructurecompare.tcl::inputxml file does not exist"
}

XMLParsefile $inputxml

set step $XMLParse(crank__soap__current_step)

CalcFACorrel $crankplugins $step $final_sub $mtzin $bp3_exec
