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

proc bp3_run { code crankbin executable crankplugins inputxml inccp4 step } {
    global XMLParse
    global env

    set t0 [clock clicks -millisec ]

    if { [info exists XMLParse([join "crank parameters version" __])] } {
       set xmlversion $XMLParse([join "crank parameters version" __])
    } else {
       crank_error "crank_bp3.tcl::crank XML version info does not exist"
    }

    crank_plugin_begin $step "Substructure refinement and phasing" "Bp3" $crankplugins $xmlversion

    set verbose 0

    if { [info exists XMLParse([join "crank parameters verbose" __])] } {
       if { $XMLParse([join "crank parameters verbose" __]) >= 1 } {
	   set verbose 1
      }
    }
    
    file mkdir $step-bp3
    cd $step-bp3
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    set run 1
    # Generate the BP3 command file
    set substructure_tag $XMLParse([join "crank soap run step=$step input substructure" __])
    runcommand [concat tclsh [file join $crankplugins bp3 xml2bp3script.tcl] $inccp4 [file join .. workdb crank.out.$substructure_tag.substructure.pdb] $run 0 0 >& bp3-command$run.com ] $verbose
    runcommand [concat tclsh [file join $crankplugins bp3 xml2bp3script.tcl] $inccp4 [file join .. workdb crank.out.$substructure_tag.substructure.pdb] $run 0 1 >& bp3-command$run.tcl ] $verbose

    runcommand [concat tclsh bp3-command$run.tcl ] 1
    
    if { [file exists bp3-logfile$run] } {
	set log [open "bp3-logfile$run" r]
	set output [read $log]
	puts $output

	# Copy logfile to main log directory
	file copy bp3-logfile$run [file join .. log $step-bp3-logfile$run]

	set stop_fom $XMLParse([join "crank soap run step=$step bp3 stop_fom" __])

	if { ![regexp { .*The overall FOM is* *([0-9.]*).*} $output junk fom] } {
	    puts "Search string not found"
	}
	close $log 
   
	if { $fom < $stop_fom } {
	    crank_error "The obtained FOM is less than the minimum required FOM"
	}

    } else {
	crank_error "crank_bp3.tcl::bp3 did not finish successfully"
    }    

    set i 1
    while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } {
 	set j 1
        while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } {
	    incr j
	}
	incr i
    }

    # detection of new heavy atoms from anomalous difference map for SAD

    if { [ info exists XMLParse([join "crank soap run step=$step bp3 difference_map" __])] } { 
	set diff $XMLParse([join "crank soap run step=$step bp3 difference_map" __])
    } else {
	set diff 1
    }

    if { $diff } { 
	  source [file join $crankbin crankutils.tcl]

	  if { [ info exists XMLParse([join "crank soap run step=$step bp3 difference_map_threshold" __])] } { 
	    set thres $XMLParse([join "crank soap run step=$step bp3 difference_map_threshold" __])
	  } else {
	    set thres 6
	  }

      set find_atoms 1
      while { $find_atoms && $run < 2 } {	
        set find_atoms [find_atoms_from_map_and_refine bp3 $tag $run $step $thres $crankplugins $inccp4 1 $verbose]
        if { $find_atoms } {
		  incr run
        }
      }
	}
	
    # Rename output columns to the names specified in the XML
    if { [file exists crank.out.${tag}-${run}.mtz] } {
	file copy crank.out.${tag}-${run}.mtz [file join .. workdb crank.out.$tag.mtz]
	file delete crank.out.${tag}-${run}.mtz
    } else {
	crank_error "crank_bp3.tcl: bp3 did not finish successfully"
    }

    # For other hand calculation - if it was run
    if { [file exists crank.out.${tag}-${run}.mtz-oh] } {
	file copy  crank.out.${tag}-${run}.mtz-oh [file join .. workdb crank.out.$tag.oh.mtz]
	file delete crank.out.${tag}-${run}.mtz-oh
    }

    if { [file exists heavy${run}-1.pdb] } {
        file copy heavy${run}-1.pdb [file join .. workdb crank.out.$tag.substructure.pdb]
    } elseif { [file exists heavy${run}-2.pdb] } {
        file copy heavy${run}-2.pdb [file join .. workdb crank.out.$tag.substructure.pdb]
    }
    
    if { [file exists heavy${run}-oh-1.pdb] } {
        file copy heavy${run}-oh-1.pdb [file join .. workdb crank.out.$tag.oh.substructure.pdb]
    } elseif { [file exists heavy${run}-oh-2.pdb] } {
        file copy heavy${run}-oh-2.pdb [file join .. workdb crank.out.$tag.oh.substructure.pdb]
    }

    crank_plugin_end $step [expr ([clock clicks -millisec ]-$t0)/1000.]

    cd ..
}


proc bp3_dependencies { step } {
    global XMLParse

}

proc bp3_input_check { step } {
    global XMLParse

}

proc bp3_reference { } {
    global XMLParse
    
    set dataset 0
    set i 1
    while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } {
	set j 1
	while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } {
	    set dataset [expr $dataset + 1]
            incr j
	}
        incr i
    }

    puts "Bp3:"

    puts "<B><FONT COLOR=\"\#FF0000\"><!--SUMMARY_BEGIN-->\n"
    puts "\$TEXT:Reference: \$\$ Please reference \$\$"
    puts "Pannu NS, Waterreus WJ,  Skubak P, Sikharulidze I, Abrahams JP &"
    puts "de Graaff RAG (2011) Recent advances in the CRANK software suite"
    puts "for experimental phasing. Acta Cryst. D67, 331-337."
    puts "\$\$\n"
    puts "<!--SUMMARY_END--></FONT></B>\n"
}
