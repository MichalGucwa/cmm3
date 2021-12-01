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
proc OutputParrotscriptfile { enant ref refpdb ex tcl } {
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

    if { $enant == "1" } {
      set mtz_in "[file join $orig_pwd workdb crank.in.$tag.mtz]"
    } else {
      set mtz_in "[file join $orig_pwd workdb crank.in.$tag.oh.mtz]"
    } 

    set c $XMLParse([join "crank parameters ref_crystal" __])
    set d $XMLParse([join "crank parameters ref_dataset" __])

    set in_fp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d f" __])
    set in_sigfp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d sigf" __])

    set in_freer $XMLParse([join "crank soap run step=$step input freer_columns freer" __])

    if { [info exists XMLParse([join "crank soap run step=$step parrot ncycles" __])] } {
	set ncycles $XMLParse([join "crank soap run step=$step parrot ncycles" __])
    } else {
	set ncycles 3
    }


    if { [info exists XMLParse([join "crank soap run step=$step parrot solvent_flatten" __])] } {
	if { $XMLParse([join "crank soap run step=$step parrot solvent_flatten" __]) } {
	    set solventflatten "-solvent-flatten"
	} 
    } else {
	set solventflatten "-solvent-flatten"
    }

    if { [info exists XMLParse([join "crank soap run step=$step parrot histogram" __])] } {
	if { $XMLParse([join "crank soap run step=$step parrot histogram" __]) } {
	    set histogram "-histogram-match"
	} 
    } else {
	set histogram "-histogram-match"
    }

    # HL columns
    if { [info exists XMLParse([join "crank soap run step=$step input hl_columns hla" __])] &&
	  [string compare $XMLParse([join "crank soap run step=$step input hl_columns hla" __]) "NONE"] != 0 } {
	set in_hla $XMLParse([join "crank soap run step=$step input hl_columns hla" __])
	set in_hlb $XMLParse([join "crank soap run step=$step input hl_columns hlb" __])
	set in_hlc $XMLParse([join "crank soap run step=$step input hl_columns hlc" __])
	set in_hld $XMLParse([join "crank soap run step=$step input hl_columns hld" __])
     } else {
	crank_error "HL coefficients have not been defined"
     }

    set ncs ""
    if { [info exists XMLParse([join "crank soap run step=$step parrot use_ncs" __])] } {
	set subtag [string trim $XMLParse([join "crank soap run step=$step input substructure" __])]
	if { $XMLParse([join "crank soap run step=$step parrot use_ncs" __]) == 1 } {
            if { $enant == "1" } {
	        if { [file exists [file join $orig_pwd workdb crank.out.$subtag.substructure.pdb] ] } {
		    set ncs "-pdbin-wrk-ha [file join $orig_pwd workdb crank.out.$subtag.substructure.pdb] -ncs-average"
	        }
            } else {
	        if { [file exists [file join $orig_pwd workdb crank.out.$subtag.oh.substructure.pdb] ] } {
		    set ncs "-pdbin-wrk-ha [file join $orig_pwd workdb crank.out.$subtag.oh.substructure.pdb] -ncs-average"
	        }
	    }
	}
    }

    if { [info exists XMLParse([join "crank update solvent_content" __])] } {
	set solv $XMLParse(crank__update__solvent_content)
    } else {
	set solv $XMLParse(crank__parameters__solvent_content)
    }

    if { $tcl } {
	puts -nonewline "set script \"start -mtzin-ref $ref -pdbin-ref $refpdb -mtzin-wrk $mtz_in "
	puts -nonewline "-colin-wrk-fo /*/*/\\\\\\\[$in_fp,$in_sigfp\\\\\\\] "
	puts -nonewline "-colin-wrk-hl /*/*/\\\\\\\[$in_hla,$in_hlb,$in_hlc,$in_hld\\\\\\\] "
	puts -nonewline "-colin-wrk-free /*/*/\\\\\\\[$in_freer\\\\\\\] "
	puts -nonewline "-colin-ref-fo /*/*/\\\\\\\[FP.F_sigF.F,FP.F_sigF.sigF\\\\\\\] "
	puts -nonewline "-colin-ref-hl /*/*/\\\\\\\[FC.ABCD.A,FC.ABCD.B,FC.ABCD.C,FC.ABCD.D\\\\\\\] "
	if { [info exists ncs] } {
	    puts -nonewline "$ncs "
	}
	puts -nonewline "-colout $tag "
	puts -nonewline "-solvent-content $solv "
#	if { [info exists $solventflatten] } {
	    puts -nonewline "-solvent-flatten "
#	}
#	if { [info exists $histogram] } {
	    puts -nonewline "-histogram-match "
#	}
	puts -nonewline "-resolution 1.0 "
	puts -nonewline "-cycles $ncycles "
	puts -nonewline " \" \n"
	puts "set command \"parrot <<\$script >> parrot-logfile\""
	puts "eval exec \$command"
    } else {
	puts "parrot -stdin << end-parrot >> parrot-logfile"
	puts "pdbin-ref $refpdb"
	puts "mtzin-ref $ref"
	puts "mtzin-wrk $mtz_in"
	puts "colin-wrk-fo /*/*/\[$in_fp,$in_sigfp\] "
	puts "colin-wrk-hl /*/*/\[$in_hla,$in_hlb,$in_hlc,$in_hld\] "
	puts "colin-wrk-free /*/*/\[$in_freer\] "
	puts "colin-ref-fo /*/*/\[FP.F_sigF.F,FP.F_sigF.sigF\] "
	puts "colin-ref-hl /*/*/\[FC.ABCD.A,FC.ABCD.B,FC.ABCD.C,FC.ABCD.D\] "
	if { [info exists ncs] } {
	    puts "$ncs "
	}
	puts "colout $tag "
	puts "solvent-content $solv "
#	if { [info exists $solventflatten] } {
	    puts "solvent-flatten "
#	}
#	if { [info exists $histogram] } {
	    puts "histogram-match "
#	}
	# puts "resolution 1.0 "
	puts "cycles $ncycles "
	puts "end-parrot"
    }
}

global env

set enant    [lindex $argv 0]
set ref      [lindex $argv 1]
set refpdb   [lindex $argv 2]
set tcl      [lindex $argv 3]

source [file join $env(CRANK) bin crankutils.tcl]

if { [file exists $inputxml] == 0 } {
    crank_error "xml2parrotscript.tcl::inputxml file does not exist"
}

XMLParsefile $inputxml

OutputParrotscriptfile $enant $ref $refpdb $tcl
