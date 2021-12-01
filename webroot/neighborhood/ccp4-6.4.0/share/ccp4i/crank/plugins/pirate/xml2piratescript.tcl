#!/usr/bin/env tclsh
#
# Copyright (C) Navraj S. Pannu 2006-2007 Leiden University
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
proc OutputPiratetclfile { enant ref } {
    global XMLParse

    puts "\#!/usr/bin/env tclsh"
    puts " "

    set step $XMLParse(crank__soap__current_step)
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    if { $enant == "1" } {
      set mtz_in "[file join .. .. workdb crank.in.$tag.mtz]"
    } else {
      set mtz_in "[file join .. .. workdb crank.in.$tag.oh.mtz]"
    } 

    set c $XMLParse([join "crank parameters ref_crystal" __])
    set d $XMLParse([join "crank parameters ref_dataset" __])

    set in_fp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d f" __])
    set in_sigfp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d sigf" __])

    set in_freer $XMLParse([join "crank soap run step=$step input freer_columns freer" __])

    if { [info exists XMLParse([join "crank soap run step=$step pirate ncycles" __])] } {
	set ncycles $XMLParse([join "crank soap run step=$step pirate ncycles" __])
    } else {
	set ncycles 3
    }

    if { [info exists XMLParse([join "crank soap run step=$step pirate inweight" __])] } {
	set expllk $XMLParse([join "crank soap run step=$step pirate inweight" __])
    } else {
	set expllk 1.0
    }

    if { [info exists XMLParse([join "crank soap run step=$step pirate autocontent" __])] } {
	if { $XMLParse([join "crank soap run step=$step pirate autocontent" __]) } {
	    set autocontent "-auto-content"
	} else {
	    set autocontent " "
	}
    } else {
	set autocontent "-auto-content"
    }

    # HL columns
    if { [info exists XMLParse([join "crank soap run step=$step input hl_columns hla" __])] &&
	  [string compare $XMLParse([join "crank soap run step=$step input hl_columns hla" __]) "NONE"] != 0 } {
	set in_hla $XMLParse([join "crank soap run step=$step input hl_columns hla" __])
	set in_hlb $XMLParse([join "crank soap run step=$step input hl_columns hlb" __])
	set in_hlc $XMLParse([join "crank soap run step=$step input hl_columns hlc" __])
	set in_hld $XMLParse([join "crank soap run step=$step input hl_columns hld" __])
     }

    set ncs " "

    if { [info exists XMLParse([join "crank soap run step=$step pirate use_ncs" __])] } {
	set subtag [string trim $XMLParse([join "crank soap run step=$step input substructure" __])]
	if { $XMLParse([join "crank soap run step=$step pirate use_ncs" __]) == 1 } {
	    if { $enant == "1" } {
		if { [file exists [file join $orig_pwd workdb crank.out.$subtag.substructure.pdb] ] } {
		    set ncs "-pdbin-ha [file join $orig_pwd workdb crank.out.$subtag.substructure.pdb] -auto-ncsllk"
		}
	    } else {
		if { [file exists [file join $orig_pwd workdb crank.out.$subtag.oh.substructure.pdb] ] } {
		    set ncs "-pdbin-ha [file join $orig_pwd workdb crank.out.$subtag.oh.substructure.pdb] -auto-ncsllk"
		} 
	    }
	}
    }

    puts -nonewline "set script \"start -mtzin-ref $ref -mtzin-wrk $mtz_in $ncs "
    puts -nonewline "-colin-wrk-fo /*/*/\\\\\\\[$in_fp,$in_sigfp\\\\\\\] "
    puts -nonewline "-colin-wrk-hl /*/*/\\\\\\\[$in_hla,$in_hlb,$in_hlc,$in_hld\\\\\\\] "
    puts -nonewline "-colin-wrk-free /*/*/\\\\\\\[$in_freer\\\\\\\] "
    puts -nonewline "-colin-ref-fo /*/*/\\\\\\\[FP.F_sigF.F,FP.F_sigF.sigF\\\\\\\] "
    puts -nonewline "-colin-ref-hl /*/*/\\\\\\\[FC.ABCD.A,FC.ABCD.B,FC.ABCD.C,FC.ABCD.D\\\\\\\] "
    puts -nonewline "-colout $tag "
    puts -nonewline "-ncycles $ncycles "
    puts -nonewline "-weight-expllk $expllk "
    puts -nonewline "-auto-mapllk "
    puts -nonewline " $autocontent \""
    puts ""
    puts "set command \"cpirate <<\$script > pirate-logfile\""
    puts "eval exec \$command"
}

global env

if { [file exists [file join .. xml input.xml] ] } { 
    set inputxml     [file join .. xml input.xml]
} elseif { [file exists [file join .. .. xml input.xml] ] } { 
    set inputxml     [file join .. .. xml input.xml]
} else {
    crank_error "crank::xml2piratescript.tcl:: input.xml file not found"
}

set enant    [lindex $argv 0]
set ref      [lindex $argv 1]

source [file join $env(CRANK) bin crankutils.tcl]

XMLParsefile $inputxml

OutputPiratetclfile $enant $ref 
