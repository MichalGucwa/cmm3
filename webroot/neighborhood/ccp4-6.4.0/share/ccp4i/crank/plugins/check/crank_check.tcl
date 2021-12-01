#
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

proc check_run { code crankbin executable crankplugins inputxml inccp4 step } {
    global XMLParse

    set t0 [clock clicks -millisec ]

    if { [info exists XMLParse([join "crank parameters version" __])] } {
       set xmlversion $XMLParse([join "crank parameters version" __])
    } else {
       crank_error "crank_check.tcl::crank XML version info does not exist"
    }

    crank_plugin_begin $step "Checking against a known model" "Sitcom and clipper apps" $crankplugins $xmlversion

    set verbose 0

    if { [info exists XMLParse([join "crank parameters verbose" __])] } {
       if { $XMLParse([join "crank parameters verbose" __]) >= 1 } {
	   set verbose 1
      }
    }

    file mkdir $step-check
    cd $step-check

    if { [info exists XMLParse([join "crank parameters description" __])] } {
	set description $XMLParse([join "crank parameters description" __])
	set output "Check step for job: $description"
	set log [open "check-logfile" w]
	puts $log $output
	close $log
    } 

    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    if { [info exists XMLParse([join "crank soap run step=$step check final_pdb" __])] } {
	if { [file exists $XMLParse([join "crank soap run step=$step check final_pdb" __])] } {
	    set final_pdb $XMLParse([join "crank soap run step=$step check final_pdb" __])
	} else {
	    crank_error "Defined final pdb does not exist"
	}
    } 

    if { [info exists XMLParse([join "crank soap run step=$step check keep_mtz" __])] } {
	set keep_mtz $XMLParse([join "crank soap run step=$step check keep_mtz" __])
    } else {
 	set keep_mtz 0
    }

    if { [info exists XMLParse([join "crank soap run step=$step check no_trans" __])] } {
	set no_trans $XMLParse([join "crank soap run step=$step check no_trans" __])
    } else {
 	set no_trans 0
    }
    
    # calculate correlation of FA's

    set mtzin [file join .. workdb crank.in.$tag.mtz]

    if { [info exists XMLParse([join "crank soap run step=$step check final_substructure" __])] } {

	if { [file exists $XMLParse([join "crank soap run step=$step check final_substructure" __])] } {
	    set final_sub $XMLParse([join "crank soap run step=$step check final_substructure" __])
	} else {
 	    crank_error "Defined final substructure does not exist"
	}
    }

    if { $inccp4 } {
       set  bp3_exec [file join $env(CBIN) bp3 ]
    } else {
       set  bp3_exec [file join $crankbin  bp3 ]
    }

    if { ( ([info exists XMLParse([join "crank soap run step=$step input ea_columns ea" __])] ||
	    [info exists XMLParse([join "crank soap run step=$step input ea_columns ea" __])]   ) && [info exists final_sub]) } {
	runcommand [concat tclsh [file join $crankplugins check calcfacorrel.tcl] $inputxml $crankbin $crankplugins $final_sub $mtzin $bp3_exec] $verbose
    }


    # compare substructures

    if { [info exists XMLParse([join "crank soap run step=$step input substructure" __])] } {
	set sub_tag $XMLParse([join "crank soap run step=$step input substructure" __])
	set model_sub [file join .. workdb crank.out.$sub_tag.substructure.pdb]
    } 
	
    set sitcom 1

    if { [info exists XMLParse([join "crank soap run step=$step check emma" __])] } {
	if { $XMLParse([join "crank soap run step=$step check emma" __]) == "1" } {
	    set sitcom 0
	}
    }

    if { [info exists model_sub] && [info exists final_sub] } {
	runcommand [concat tclsh [file join $crankplugins check substructurecompare.tcl] $inputxml $crankbin $crankplugins $final_sub $model_sub $sitcom] $verbose
    }

    # get translation vector (if not already obtained)
    if { !$no_trans && [info exists final_pdb] } {
	runcommand [concat tclsh [file join $crankplugins check gettranslation.tcl] $inputxml $crankbin $step $tag $final_pdb] $verbose
    }

    # put final_pdb on correct origin and calculate phases from it

    if { [info exists final_pdb] } {
	if { !$no_trans } {
	    set x ""
	    set y ""
	    set z ""

 	    if { [file exists translation-sub.txt] } {
  		set file1 "translation-sub.txt"
	    } elseif { [file exists translation-cphasematch.txt] } {
 		set file1 "translation-cphasematch.txt"
	    }

	    if { [info exists file1] } {
  		set logfile1 [open $file1 r]

		set data [read $logfile1]
		set data [split $data "\n"]	    
		
		foreach line $data {
		    regsub -all {\s+} $line " " line
		    if { [regexp {.* ([-0-9.]*) ([-0-9.]*) ([-0-9.]*) .*} $line junk x y z] } {
			break
		    }
		}
		close $logfile1
		if { ($x != "") && ($y != "") && ($z != "") } {
		    set lsqkab_script "ROTAT EULER 0 0 0\nTRAN FRAC $x $y $z\n"
		    set command "lsqkab XYZIN2 $final_pdb XYZOUT final_rotated.pdb << \"$lsqkab_script\" "
		    catch {eval exec $command } output
		}
	    }
	} else {
	    file copy $final_pdb final_rotated.pdb
	}
    }

    # calculate final amplitudes/phases
    set inphases 0
    if { [file exists [file join .. workdb crank.in.$tag.mtz] ] } {
        if { [info exists XMLParse([join "crank soap run step=$step input phase_columns f" __])] } {
            set in_f $XMLParse([join "crank soap run step=$step input phase_columns f" __])
            set in_sigf $XMLParse([join "crank soap run step=$step input phase_columns sigf" __])
            set in_phib $XMLParse([join "crank soap run step=$step input phase_columns phib" __])
            set in_fom $XMLParse([join "crank soap run step=$step input phase_columns fom" __])
            set inphases 1
        }
    }

    if { $inphases && [file exists final_rotated.pdb] } {
       set sfall_script "mode sfcalc xyzin hklin\nlabin FP = $in_f SIGFP = $in_sigf\n"
       set sfall_script "$sfall_script labout FC=FC PHIC=PHIC\n"
       set command "sfall XYZIN final_rotated.pdb HKLIN [file join .. workdb crank.in.$tag.mtz] HKLOUT final1.mtz << \"$sfall_script\" "
       catch {eval exec $command } output

       set sftools_script "read final1.mtz\nwrite final.mtz col FC PHIC\nquit\n"
       set command "sftools << \"$sftools_script\" "
       catch {eval exec $command } output
       file delete final1.mtz
    }

    # compare phases
    if { [file exists final.mtz] } {
	runcommand [concat tclsh [file join $crankplugins check allphasecompare.tcl] $inputxml $crankbin $crankplugins $step $tag $keep_mtz $no_trans] $verbose
    }

    # this is for comparing pdb's

    if { [file exists final_rotated.pdb] } {
	for { set istep 1 } { [info exists XMLParse(crank__soap__run__step=$istep)] } { incr istep } {
	    if { [info exists XMLParse([join "crank soap run step=$istep output pdb" __])] } {
		set pdb_tag $XMLParse([join "crank soap run step=$istep output pdb" __])
		set name $XMLParse([join "crank soap run step=$istep name" __])
		if { [file exists [file join .. workdb crank.out.$pdb_tag.pdb] ] } {
		    set crankpdb [file join .. workdb crank.out.$pdb_tag.pdb]

		    set output "\nModel building statistics from $name"
		    set log [open "check-logfile" a]
		    puts $log $output
		    close $log

		     runcommand [concat tclsh [file join $crankplugins check compare-pdbs.tcl] final_rotated.pdb $crankpdb $crankplugins >> check-logfile] $verbose
		}  
	    }
	}
    }    

    if { [file exists final.mtz] } {
	file delete final.mtz
    }

    if { [file exists check-logfile] } {
        set log [open "check-logfile" r]
        set output [read $log]
        puts $output
        close $log
	file copy check-logfile [file join .. log $step-check-logfile]
	runcommand [concat cat check-logfile] $verbose
    } else {
        crank_error "check-logfile not created"
    }

    crank_plugin_end $step [expr ([clock clicks -millisec ]-$t0)/1000.]

    cd ..
}

proc check_dependencies { step } {
    global XMLParse

}

proc check_input_check { step } {
    global XMLParse

}

proc check_reference { } {
    global XMLParse
    
    puts "CHECK:"
    puts "<B><FONT COLOR=\"\#FF0000\"><!--SUMMARY_BEGIN-->\n"
    puts "Cowtan, K: Clipper utilities & Ness, S.R. & Skubak, P: Unpublished"
    puts "Dall'Antonia, F. & Schneider T.R. (2006) SITCOM: a program for comparing"
    puts "sites in macromolecular substructures. J. Appl. Cryst. 39, 618-619.\n"
    puts "<!--SUMMARY_END--></FONT></B>\n"
} 
