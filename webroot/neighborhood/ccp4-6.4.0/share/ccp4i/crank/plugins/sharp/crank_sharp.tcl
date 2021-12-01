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

proc sharp_run { code crankbin executable crankplugins inputxml inccp4 step } {
    global XMLParse
    global env

    set t0 [clock clicks -millisec ]

    if { [info exists XMLParse([join "crank parameters version" __])] } {
       set xmlversion $XMLParse([join "crank parameters version" __])
    } else {
       crank_error "crank_sharp.tcl::crank XML version info does not exist"
    }

    crank_plugin_begin $step "Substructure refinement and phasing" "Sharp" $crankplugins $xmlversion

    set verbose 0

    if { [info exists XMLParse([join "crank parameters verbose" __])] } {
       if { $XMLParse([join "crank parameters verbose" __]) >= 1 } {
	   set verbose 1
      }
    }

    file mkdir $step-sharp
    cd $step-sharp
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    set run 1
    # Generate a SHARP command file
    set substructure_tag $XMLParse([join "crank soap run step=$step input substructure" __])

    set script [open sharp-command$run.com w+]

    puts $script "\#!/bin/sh"
    puts $script " "
    puts $script "BDG_home=/usr/lab/crystal/sharp\n"
    puts $script "EXE=/usr/lab/crystal/sharp/bin/linux_exe/sharp\n"
    puts $script "SYMOP=\$BDG_home/database/symop"
    puts $script "ATOMSF=\$BDG_home/database/atomsf\n"

    puts $script "export BDG_home SYMOP ATOMSF"

    puts $script "\$EXE > LIST.html 2> STDERR"

    flush $script
    close $script

    # set mtz columns with DANO and SIGDANO

    runcommand [concat tclsh [file join $crankplugins sharp xml2mtzMADmodcom.tcl] $inputxml $crankbin >& mtzMADmod$run.com] $verbose

    runcommand [concat sh mtzMADmod$run.com] $verbose
    
    runcommand [concat tclsh [file join $crankplugins sharp xml2sharpcom.tcl] $inputxml [file join .. workdb crank.out.$substructure_tag.substructure.pdb] $run $executable 0 $crankbin >& SIN] $verbose

    file copy SIN ORI_SIN
    runcommand [concat sh sharp-command$run.com] 1
	
    # Rename output columns to the names specified in the XML
    if { [file exists eden.mtz] } {
	runcommand [concat tclsh [file join $crankplugins sharp crank-rename-sharp-output.tcl] $inputxml eden.mtz rename.out.mtz $crankbin] $verbose
	file copy rename.out.mtz [file join .. workdb crank.out.$tag.mtz]
	file delete rename.out.mtz
    } else {
	crank_error "crank_sharp.tcl: sharp did not finish successfully"
    }

    file copy hatom.pdb [file join .. workdb crank.out.$tag.substructure.pdb]

    # Other hand - if requested
    if { [info exists XMLParse([join "crank soap run step=$step sharp hand" __])] } {

	if { $XMLParse([join "crank soap run step=$step sharp hand" __]) == "1" } {
	    
	    incr run

	    set sg_number $XMLParse([join "crank parameters input_spacegroup number" __])

	    if { [file exists hatom.pdb] } {
		enantiomorph_pdb "hatom.pdb" "enantiomorph.pdb" $sg_number
	    } else {
		enantiomorph_pdb  [file join .. workdb crank.out.$substructure_tag.substructure.pdb] "enantiomorph.pdb" $sg_number
	    }

	    spacegroup_enantiomorph $sg_number hand_number

	    set mtz_in sharp.data.mtz

            if { $sg_number != $hand_number } { 	    
	       set mtz_in [file join .. workdb crank.in.$tag.mtz]
	       set script "read $mtz_in \n set spacgroup \n $hand_number \n write sharp.data.oh.mtz \n quit \n"
	       set command "sftools << \"$script\""
	       catch {eval exec $command} output
	       puts $output
	    } else {
               file copy $mtz_in sharp.data.oh.mtz
            }
	}

	runcommand [concat tclsh [file join $crankplugins sharp xml2sharpcom.tcl] $inputxml enantiomorph.pdb $run $executable 1 $crankbin >& SIN_HAND] $verbose

	file mkdir hand2
	cd hand2
	file copy [file join .. enantiomorph.pdb] enantiomorph.pdb
	file delete [file join .. enantiomorph.pdb]

	file copy [file join .. SIN_HAND] ORI_SIN
	file delete [file join .. SIN_HAND] 
	file copy ORI_SIN SIN
 
	set script [open sharp-command$run.com w+]

	puts $script "\#!/bin/sh"
	puts $script " "
	puts $script "BDG_home=/usr/lab/crystal/sharp\n"
	puts $script "EXE=/usr/lab/crystal/sharp/bin/linux_exe/sharp\n"
	puts $script "SYMOP=\$BDG_home/database/symop"
	puts $script "ATOMSF=\$BDG_home/database/atomsf\n"
	    
	puts $script "export BDG_home SYMOP ATOMSF"

	puts $script "\$EXE > LIST.html 2> STDERR"

	flush $script
	close $script

	runcommand [concat sh sharp-command$run.com] 1
	
	# Rename output columns to the names specified in the XML
	if { [file exists eden.mtz] } {
	    runcommand [concat tclsh [file join $crankplugins sharp crank-rename-sharp-output.tcl] $inputxml eden.mtz rename.out.mtz $crankbin] $verbose
	    file copy rename.out.mtz [file join .. .. workdb crank.out.$tag.oh.mtz]
	    file delete rename.out.mtz
	} else {
	    crank_error "crank_sharp.tcl: sharp did not finish successfully"
	}
	file copy hatom.pdb [file join .. .. workdb crank.out.$tag.substructure.oh.pdb]

	cd ..
    }

    crank_plugin_end $step [expr ([clock clicks -millisec ]-$t0)/1000.]

    cd ..
}

proc sharp_dependencies { step } {
    global XMLParse

}

proc sharp_input_check { step } {
    global XMLParse

}

proc sharp_reference { } {
    global XMLParse
    
    puts "Sharp"

    puts "La Fortelle, E. de & Bricogne, G. (1997) Methods in"
    puts "Enzymology, Macromolecular Crystallography, volume"
    puts "276, pp. 472-494, edited by R. M. Sweet and C. W."
    puts "Carter, Jr. New York: Academic Press.\n"
}
