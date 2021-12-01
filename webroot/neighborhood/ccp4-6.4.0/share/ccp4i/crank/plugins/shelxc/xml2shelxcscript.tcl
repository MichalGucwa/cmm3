#!/usr/bin/env tclsh

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

proc OutputShelxcscript { tcl } {
    global XMLParse

    set step $XMLParse(crank__soap__current_step)
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]
    set orig_pwd $XMLParse(crank__soap__orig_pwd)

    # Set atom name as the first atom name we encounter while looping over all crystals
    set i 1
    while { ![info exists XMLParse([join "crank parameters crystal=$i substructure natoms" __])] } { 
	if { $i > 10 } {
	    crank_error "xml2shelxcscript.tcl:Got to crystal=10 without finding a heavy atom, something is wrong"
	}
	incr i
    }
    set natoms $XMLParse([join "crank parameters crystal=$i substructure natoms" __])
    set atom_name $XMLParse([join "crank parameters crystal=$i substructure atom_name" __])

    if { $tcl } {
	puts "set command \"shelxc crank\""

	puts -nonewline "set script \""
    } else {
	puts "shelxc crank <<EOF > shelxc-logfile"
    }

    set c 1
    while { [info exists XMLParse([join "crank parameters crystal=$c native" __])] } {
	if { [info exists XMLParse([join "crank parameters crystal=$c substructure atom_name" __])] } {
	    break
	} else {
	    incr c
	}
    }

    set aa $XMLParse([join "crank parameters crystal=$c cell cell_a" __])
    set bb $XMLParse([join "crank parameters crystal=$c cell cell_b" __])
    set cc $XMLParse([join "crank parameters crystal=$c cell cell_c" __])
    set alpha $XMLParse([join "crank parameters crystal=$c cell cell_alpha" __])
    set beta  $XMLParse([join "crank parameters crystal=$c cell cell_beta" __])
    set gamma $XMLParse([join "crank parameters crystal=$c cell cell_gamma" __])

    set output [format "CELL %-10.5f%-10.5f%-10.5f%-10.5f%-10.5f%-10.5f" $aa $bb $cc $alpha $beta $gamma ]
		
    puts $output

    if { [string compare $XMLParse([join "crank soap run step=$step name" __]) "SHELXD"] == 0 ||
	 [string compare $XMLParse([join "crank soap run step=$step name" __]) "SHELXE"] == 0 || 
	 [string compare $XMLParse([join "crank soap run step=$step name" __]) "CRUNCH2"] == 0  } {
	puts "SAD crank_fa.hkl"
    } else {
	set i 1
	while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } { 
	    set j 1
	    while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } { 
		set type $XMLParse([join "crank parameters crystal=$i data=$j type" __])
		set anomalous $XMLParse([join "crank parameters crystal=$i data=$j anomalous" __])
		
		# A few simple rules of how to convert Crank column types into SHELXC dataset descriptors.
		# We based a lot of the Crank column types on SHELXC, so it's a pretty straightforward mapping.
		if { [string compare $type "NATIVE"] == 0 } {
		    set shelxc_type "NAT"
		} elseif { [string compare $type "DERVIATIVE"] == 0 } {
		    if { $anomalous == 1 } {
			set shelxc_type "SIRA"
		    } else {
			set shelxc_type "SIR"
		    }
		} elseif { [string compare $type "OTHER"] == 0 } {
		    set shelxc_type "SAD"
		} else {
		    set shelxc_type $type
		}

		if { [string compare $XMLParse([join "crank parameters input_intensity" __]) "1"] == 0 } {
		    puts "$shelxc_type crank_${i}_${j}.sca"
		} else {
		    puts "$shelxc_type -f crank_${i}_${j}.hkl"
		}
		
		# Output the columns for this dataset
		if { $XMLParse([join "crank parameters crystal=$i data=$j anomalous" __]) == 0 } { 
		}
		incr j
	    }
	    incr i
	}

    }

    if { [file exists [file join .. workdb crank.in.$tag.mtz] ] } {
      set inputmtz "[file join .. workdb crank.in.$tag.mtz]"
    } else {
      set inputmtz "[file join .. workdb crank.out.IN.mtz]"
    }

    set name ""
    set number ""

    spacegroup_from_mtz $inputmtz name number

    puts "SPAG $name"

    puts "FIND $natoms"
	
    # Minimum distance between heavy atoms and if atoms are allowed to be on special positions
    if { [info exists XMLParse([join "crank soap run step=$step shelx mind" __])] } {
	set mind -[expr abs($XMLParse([join "crank soap run step=$step shelx mind" __]))]
    } else {
	set mind -3.5
    }
    puts "MIND $mind"
    
    # Number of tries
    if { [info exists XMLParse([join "crank soap run step=$step shelx ntry" __])] } {
	set ntry $XMLParse([join "crank soap run step=$step shelx ntry" __])
    } else {
	set ntry 100
    }
    puts "NTRY $ntry"

    # random number seed
#    if { [info exists XMLParse([join "crank soap run step=$step shelx random_seed" __])] } {
#        puts "SEED $XMLParse([join "crank soap run step=$step shelx random_seed" __])"
#    } 

    # Low resolution cutoff
    if { [info exists XMLParse([join "crank soap run step=$step shelx lo_res" __])] } {
	set shel_min $XMLParse([join "crank soap run step=$step shelx lo_res" __])
    } else {
	set shel_min 50.0
    }

    # High resolution cutoff
    if { [info exists XMLParse([join "crank soap run step=$step shelx hi_res" __])] } {
        set shel_max $XMLParse([join "crank soap run step=$step shelx hi_res" __])
    } else {
        if { [info exists XMLParse([join "crank update sub_hires" __])] } {
            set shel_max $XMLParse([join "crank update sub_hires" __])
        } 
    }

    if { [info exists shel_max] } {
	puts "SHEL $shel_min $shel_max"
    }

    puts "SFAC $atom_name"

    if { [info exists XMLParse([join "crank soap run step=$step shelx dsul" __])] } {
	if { $XMLParse([join "crank soap run step=$step shelx dsul" __]) > 0 } {
	    set dsul $XMLParse([join "crank soap run step=$step shelx dsul" __])
	    puts "DSUL $dsul"
	}
    }

    if { [info exists XMLParse([join "crank soap run step=$step shelx pats" __])] } {
	set tmpstr [string toupper $XMLParse([join "crank soap run step=$step shelx pats" __])]
	if { [string compare $tmpstr "ON" ] == 0 } {
	    puts "PATS"
	}
    }

    if { [info exists XMLParse([join "crank soap run step=$step shelx weed" __])] } {
	if { $XMLParse([join "crank soap run step=$step shelx weed" __]) > 0 } {
	    set weed $XMLParse([join "crank soap run step shelx weed" __])
	    puts "WEED $weed"
	}
    }

    if { $tcl } {
	puts "\""
	puts ""
	puts "set command \"\$command << \\\"\$script\\\" > shelxc-logfile\""
	puts "eval exec \$command"
    } else {
	puts "EOF"
    }
}

global env

set inputxml [file join .. xml input.xml]
set tcl      [lindex $argv 0]

source [file join $env(CRANK) bin crankutils.tcl]

if { [file exists $inputxml] == 0 } {
    crank_error "xml2shelxcscript.tcl::inputxml file does not exist"
}

XMLParsefile $inputxml

OutputShelxcscript $tcl
