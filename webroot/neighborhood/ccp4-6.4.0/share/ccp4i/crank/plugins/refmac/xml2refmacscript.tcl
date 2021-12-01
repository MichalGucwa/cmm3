#!/usr/bin/env tclsh

# Copyright (C) Navraj S. Pannu 2008, Leiden University
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
proc OutputRefmacscriptfile { pdbin run hand tcl } {
    global XMLParse
	
    set step $XMLParse(crank__soap__current_step)
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    if { [info exists XMLParse([join "crank soap run step=$step refmac mode" __]) ] } {
        set mode $XMLParse([join "crank soap run step=$step refmac mode" __])
    } else {
       set mode "PHASE"
    }

    if { [info exists XMLParse([join "crank soap run step=$step input substructure" __])] } {  
	  set subtag $XMLParse([join "crank soap run step=$step input substructure" __])
      if { [file exists $pdbin] } {
	      set substructurepdb $pdbin
 	  } else {
	    if { [file exists [file join .. workdb crank.out.$subtag.substructure.pdb] ] } {
	      set substructurepdb [file join .. workdb crank.out.$subtag.substructure.pdb]
	    } else {
	      crank_error "Substructure pdb does not exist"
	    }		 
      }
    }

    if { [info exists XMLParse([join "crank soap run step=$step input pdb" __])] } {  
	set mtag $XMLParse([join "crank soap run step=$step input pdb" __])
 	if { [file exists [file join .. workdb crank.out.$mtag.pdb] ] } {
	    set modelpdb [file join .. workdb crank.out.$mtag.pdb]
	} else {
 	    crank_error "Model pdb does not exist"
	}		 
    }

    if { ![info exists modelpdb] && ![info exists substructurepdb] } {
	crank_error "A substructure pdb or model pdb must be given to refmac"
    }

    # only SAD and SIRAS at the moment for refmac, so find crystal and data set with maximal f" and native (if exists)
    set maxa 0
    set maxc 0
    set maxd 0
    set nc 0
    set maxfpp 0
    set c $XMLParse([join "crank parameters ref_crystal" __])
    set d $XMLParse([join "crank parameters ref_dataset" __])

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
			set maxa $k
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

    if { $tcl } {
	puts "\#!/usr/bin/env tclsh"
    } else {
	puts "\#!/bin/sh"
    }
    puts " "

    if {$hand == 1} {
	set mtz_in "enantiomorph.mtz"
	set xyzout "heavy${run}.oh.pdb"
	set mtz_out "refmac.out${run}.oh.mtz"
  	set log "refmac-logfile.oh${run}"
    } else {
	set mtz_in "[file join .. workdb crank.in.$tag.mtz]"
  	set xyzout "heavy${run}.pdb"
	set mtz_out "refmac.out${run}.mtz"
  	set log "refmac-logfile${run}"
    }

    if { ( ($mode == "RIGID") || ($mode == "RESTRAIN") ) } {

	if { [info exists modelpdb] } {
	    set xin $modelpdb
	} else {
	    crank_error "A model pdb must be input for rigid or restrained refinement"
	}
    } else {
	if { $mode == "PHASE" } {
	    if {$hand == 1} {
		set xin "enantiomorph.pdb"
	    } else {
		set xin $substructurepdb
	    }
	} else {
 	    crank_error "A substructure must be input for substructure phasing"
	}
    }

    if { $tcl } { 
	puts "set command \"refmac5 HKLIN $mtz_in XYZIN $xin HKLOUT $mtz_out XYZOUT $xyzout \""
	puts " "
	puts -nonewline "set script \""
    } else { 
	puts "refmac5 HKLIN $mtz_in XYZIN $xin HKLOUT $mtz_out XYZOUT $xyzout << END > $log"
    puts " "
    }

    if { $mode == "RIGID" } {
	puts "   refi type RIGID"
	puts "   rigid ncycle 20"
  	# ***NSP need to define rigid groups!!!
    } elseif { $mode == "PHASE" } {
	puts "    SOLV NO "
#	puts "    BLIMI 2 80"
	puts "    REFI SUBS YES"
	if { ($maxc == 0) || ($maxd == 0) } {
 	    crank_error "Could not find data suitable for either SAD or SIRAS phasing"
	}
    } else {
  	puts "   refi type REST"
    }  

    # Define data for target functions
    set in_freer $XMLParse([join "crank soap run step=$step input freer_columns freer" __])

    if { ($nc > 0) && ($maxc > 0) && ($maxd > 0) } {
	# SIRAS function    
	puts "    DATA DERI 0"
	puts "    DATA DERI 1 PLUS"
	puts "    DATA DERI 1 MINUS"
	puts "    REFI SRAS SUBS YES"
	set input_f $XMLParse([join "crank soap run step=$step input exp_columns crystal=$nc data=1 f" __])
	set input_sigf $XMLParse([join "crank soap run step=$step input exp_columns crystal=$nc data=1 sigf" __])
	set input_f_plus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd f_plus" __])
	set input_sigf_plus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd sigf_plus" __])
	set input_f_minus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd f_minus" __])
	set input_sigf_minus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd sigf_minus" __])
	if { $mode == "PHASE" } {
	    puts "    LABIN FP=$input_f SIGFP=$input_sigf F_1=$input_f SIGF_1=$input_sigf F_2=$input_f_plus SIGF_2=$input_sigf_plus F_3=$input_f_minus SIGF_3=$input_sigf_minus"
	} else {
	    puts "    LABIN FP=$input_f SIGFP=$input_sigf F_1=$input_f SIGF_1=$input_sigf F_2=$input_f_plus SIGF_2=$input_sigf_plus F_3=$input_f_minus SIGF_3=$input_sigf_minus FREE=$in_freer"
	}
    } elseif {($maxc > 0) && ($maxd > 0) } { 
	# SAD
	set input_f $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd f" __])
	set input_sigf $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd sigf" __])
	set input_f_plus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd f_plus" __])
	set input_sigf_plus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd sigf_plus" __])
	set input_f_minus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd f_minus" __])
	set input_sigf_minus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd sigf_minus" __])
	if { $mode == "PHASE" } {
	    puts "    LABIN FP=$input_f SIGFP=$input_sigf F+=$input_f_plus SIGF+=$input_sigf_plus F-=$input_f_minus SIGF-=$input_sigf_minus"
	} else {
	    puts "    LABIN FP=$input_f SIGFP=$input_sigf F+=$input_f_plus SIGF+=$input_sigf_plus F-=$input_f_minus SIGF-=$input_sigf_minus FREE=$in_freer"
	}
    } else {
	set input_f $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d f" __])
	set input_sigf $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d sigf" __])
	puts "   LABIN FP=$input_f SIGFP=$input_sigf FREE=$in_freer"
    }
    
    # Output Atom Form Factors

    if {($maxc > 0) && ($maxd > 0) } {
	set k 1
	while { [info exists XMLParse([join "crank parameters crystal=$maxc data=$maxd atom=$k name" __])] } {
	    set atomname $XMLParse([join "crank parameters crystal=$maxc data=$maxd atom=$k name" __])
	    set fprime $XMLParse([join "crank parameters crystal=$maxc data=$maxd atom=$k fprime" __])
	    set fprimeprime $XMLParse([join "crank parameters crystal=$maxc data=$maxd atom=$k fprimeprime" __])
	    puts "    ANOM FORM $atomname $fprime $fprimeprime"
	    incr k
	}
    }
  
    if { [info exists XMLParse([join "crank soap run step=$step refmac cycles" __])] } {
	set cycles $XMLParse([join "crank soap run step=$step refmac cycles" __])
	if { $cycles >= 0 } {
	    puts "    NCYC  $cycles"
	} 
    }
    if { $tcl } {
	puts "\nEND\""
	puts ""
	puts "set command \"\$command << \\\"\$script\\\" > $log\""
	puts "eval exec \$command"
    } else {
	puts "END"
    }
}


global env

set inputxml   [file join .. xml input.xml]
if { ![file exist $inputxml] } {
  set inputxml   [file join .. .. xml input.xml]
}

set pdbin      [lindex $argv 0]
set run        [lindex $argv 1]
set hand       [lindex $argv 2]
set tcl        [lindex $argv 3]

source [file join $env(CRANK) bin crankutils.tcl]

if { [file exists $inputxml] == 0 } {
    crank_error "xml2refmacscript.tcl::inputxml file does not exist"
}

XMLParsefile $inputxml

OutputRefmacscriptfile $pdbin $run $hand $tcl
