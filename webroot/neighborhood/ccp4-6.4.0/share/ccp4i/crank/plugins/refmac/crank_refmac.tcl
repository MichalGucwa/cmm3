#
# Copyright (C) Navraj S. Pannu 2008, Leiden University
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

proc refmac_run { code crankbin executable crankplugins inputxml inccp4 step } {
    global XMLParse
    global env

    set t0 [clock clicks -millisec ]

    if { [info exists XMLParse([join "crank parameters version" __])] } {
       set xmlversion $XMLParse([join "crank parameters version" __])
    } else {
       crank_error "crank_refmac.tcl::crank XML version info does not exist"
    }

    set mode "PHASE"

    if { [info exists XMLParse([join "crank soap run step=$step refmac mode" __])] } {
	if { $XMLParse([join "crank soap run step=$step refmac mode" __]) == "RIGID" } {
 	    crank_plugin_begin $step "Rigid body refinement" "Refmac" $crankplugins $xmlversion
	} elseif { $XMLParse([join "crank soap run step=$step refmac mode" __]) == "PHASE" } {
	    crank_plugin_begin $step "Substructure phasing and refinement" "Refmac" $crankplugins $xmlversion
	    set mode "PHASE"
	} elseif { $XMLParse([join "crank soap run step=$step refmac mode" __]) == "RESTRAIN" } {
	    crank_plugin_begin $step "Model refinement" "Refmac" $crankplugins $xmlversion
	} else {
	    crank_error "crank_refmac.tcl::refmac mode not defined"
	}
    }

    set verbose 0

    if { [info exists XMLParse([join "crank parameters verbose" __])] } {
       if { $XMLParse([join "crank parameters verbose" __]) >= 1 } {
	   set verbose 1
      }
    }   

    file mkdir $step-refmac
    cd $step-refmac
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    set run 1
    # Generate the refmac command file
    runcommand [concat tclsh [file join $crankplugins refmac xml2refmacscript.tcl] "none" $run 0 0 >& refmac-command$run.com] $verbose
    runcommand [concat tclsh [file join $crankplugins refmac xml2refmacscript.tcl] "none" $run 0 1 >& refmac-command$run.tcl] $verbose

    runcommand [concat tclsh refmac-command$run.tcl] 1

    if { [file exists refmac-logfile$run] } {
	set log [open "refmac-logfile$run" r]
	set output [read $log]
	puts $output
	close $log

	file copy refmac-logfile$run [file join .. log $step-refmac-logfile$run]
    } else {
	crank_error "crank_refmac.tcl::refmac did not finish successfully"
    }


    # detection of new heavy atoms from anomalous difference map for SAD

    if { [ info exists XMLParse([join "crank soap run step=$step refmac difference_map" __])] } { 
	set diff $XMLParse([join "crank soap run step=$step refmac difference_map" __])
    } else {
	set diff 1
    }

    if { $diff } { 
	  source [file join $crankbin crankutils.tcl]

	  if { [ info exists XMLParse([join "crank soap run step=$step refmac difference_map_threshold" __])] } { 
	    set thres $XMLParse([join "crank soap run step=$step refmac difference_map_threshold" __])
	  } else {
        # at the moment setting treshold high so that only performing 2 refmac refinements
        # wrong peaks can make the phases worse, it seems to be safer to try new peaks in combined phasing+DM+MB
	    set thres 100.0
	  }
	  
      set find_atoms 1
      set refine 2
      while { $find_atoms && $run<2 } {
        set find_atoms [find_atoms_from_map_and_refine refmac $tag $run $step $thres $crankplugins 1 $refine $verbose]
        if { $find_atoms } {
		  incr run
        }
  	    set refine 1
      }
	}

    # other hand
    if { [info exists XMLParse([join "crank soap run step=$step refmac no_hand" __])] && ($mode == "PHASE") } {

 	if { $XMLParse([join "crank soap run step=$step refmac no_hand" __]) == "0" } { 

	    set sg_number $XMLParse([join "crank parameters input_spacegroup number" __])

	    if { [file exists heavy${run}.pdb] } {
		enantiomorph_pdb "heavy${run}.pdb" "enantiomorph.pdb" $sg_number
	    } else {
		enantiomorph_pdb  [file join .. workdb crank.out.$substructure_tag.substructure.pdb] "enantiomorph.pdb" $sg_number
	    }

	    set mtz_in [file join .. workdb crank.in.$tag.mtz]

            enantiomorph_mtz $mtz_in "enantiomorph.mtz" $sg_number

            if { ![file exists enantiomorph.mtz] } {
               file copy $mtz_in enantiomorph.mtz
            }

 	    runcommand [concat tclsh [file join $crankplugins refmac xml2refmacscript.tcl] "none" $run 1 0 >& refmac-command$run.oh.com] $verbose
 	    runcommand [concat tclsh [file join $crankplugins refmac xml2refmacscript.tcl] "none" $run 1 1 >& refmac-command$run.oh.tcl] $verbose

	    runcommand [concat tclsh refmac-command$run.oh.tcl] 1
    
	    if { [file exists refmac-logfile.oh$run] } {
		set log [open "refmac-logfile.oh$run" r]
		set output [read $log]
		puts $output
		close $log

		file copy refmac-logfile.oh$run [file join .. log $step-refmac-logfile.oh$run]
	    } else {
		crank_error "crank_refmac.tcl::refmac did not finish successfully"
	    }
	}
    }


    # Rename output columns to the names specified in the XML
    if { [file exists refmac.out${run}.mtz] } {
	runcommand [concat tclsh [file join $crankplugins refmac crank-rename-refmac-output.tcl] refmac.out${run}.mtz rename.out.mtz] $verbose
	file copy rename.out.mtz [file join .. workdb crank.out.$tag.mtz]
	file delete rename.out.mtz
#	file delete refmac.out${run}.mtz
    } else {
	crank_error "crank_refmac.tcl: refmac did not finish successfully"
    }

    # For other hand calculation - if it was run
    if { [file exists refmac.out${run}.oh.mtz] } {
	runcommand [concat tclsh [file join $crankplugins refmac crank-rename-refmac-output.tcl] refmac.out${run}.oh.mtz rename.out.mtz] $verbose
	file copy rename.out.mtz [file join .. workdb crank.out.$tag.oh.mtz]
	file delete rename.out.mtz
#	file delete refmac.out${run}.oh.mtz
    }

    if { [file exists heavy${run}.pdb] } {
	file copy heavy${run}.pdb [file join .. workdb crank.out.$tag.substructure.pdb]
    } 

    if { [file exists heavy${run}.oh.pdb] } {
	file copy heavy${run}.oh.pdb [file join .. workdb crank.out.$tag.oh.substructure.pdb]
    } 

    crank_plugin_end $step [expr ([clock clicks -millisec ]-$t0)/1000.]

    cd ..
}

proc refmac_dependencies { step } {
    global XMLParse

}

proc refmac_input_check { step } {
    global XMLParse

}

proc refmac_reference { } {
    global XMLParse

    # General Refmac Reference
    puts "Refmac:"
    puts "\$TEXT:Reference: \$\$ Please reference \$\$"
    puts "Murshudov GN, Skubak P, Lebedev AA, Pannu NS, Steiner RA, Nicholls RA,"
    puts "Winn MD, Long F & Vagin AA (2011) REFMAC5 for the refinement of"
    puts "macromolecular crystal structures. Acta Cryst. D67, 355-367."
    puts "\$\$\n"
    
}
