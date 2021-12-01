#
# Copyright (C) Navraj S. Pannu, Steven Ness, and RAG de Graaff, 2004-2005 Leiden University
# Copyright (C) Navraj S. Pannu and RAG de Graaff, 2006-2008 Leiden University
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

proc crunch2_run { code crankbin executable crankplugins inputxml inccp4 step } {
    global XMLParse
    global env

    set t0 [clock clicks -millisec ]

    if { [info exists XMLParse([join "crank parameters version" __])] } {
       set xmlversion $XMLParse([join "crank parameters version" __])
    } else {
       crank_error "crank_crunch2.tcl::crank XML version info does not exist"
    }

    crank_plugin_begin $step "Substructure detection" "crunch2" $crankplugins $xmlversion

    set verbose 0

    if { [info exists XMLParse([join "crank parameters verbose" __])] } {
       if { $XMLParse([join "crank parameters verbose" __]) >= 1 } {
	   set verbose 1
      }
    }

    crank_ccp4_banner "crunch2" $xmlversion

    file mkdir $step-crunch2
    cd $step-crunch2
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    set fa $XMLParse([join "crank soap run step=$step input fa_columns fa" __])
    set sigfa $XMLParse([join "crank soap run step=$step input fa_columns sigfa" __])
    set ea $XMLParse([join "crank soap run step=$step input ea_columns ea" __])
    set sigea $XMLParse([join "crank soap run step=$step input ea_columns sigea" __])

    runcommand [concat tclsh [file join $crankplugins crunch2 mtz2drear.tcl] [file join .. workdb crank.in.$tag.mtz] crunch2.drear $fa $sigfa $ea $sigea] $verbose

    set patt_search $XMLParse([join "crank soap run step=$step crunch2 patt_search" __])

    if { $patt_search == 1 }  {

	# Run PMF
	runcommand [concat tclsh [file join $crankplugins crunch2 xml2pmfscript.tcl] $inccp4 0 > pmf-command.com] $verbose
	runcommand [concat tclsh [file join $crankplugins crunch2 xml2pmfscript.tcl] $inccp4 1 > pmf-command.tcl] $verbose

	runcommand [concat tclsh pmf-command.tcl] 1

	set total_zeros 0
	if { [file exists patterson.xyz] } {
	    set coordinate_fileid [open patterson.xyz r]
	    for { set i 0 } { $i < 5 } { incr i } {
		gets $coordinate_fileid line
		if { [string compare [string trim $line " "] "0"] == 0 } {
		    incr total_zeros
		}
	    }
	    close $coordinate_fileid
	    if { $total_zeros > 3 } {
		puts "crank::pmf did not find any patterson-compliant solutions"
		file delete patterson.xyz
	    }
	}
    }

   set icol 0
    if { [file exists patterson.xyz] } {
	set icol 1
    }

    # Set atom name as the first atom name we encounter while looping over all crystals
    set i 1
    while { ![info exists XMLParse([join "crank parameters crystal=$i substructure atom_name" __])] } { 
	incr i
    }
    set atom_name [string toupper $XMLParse([join "crank parameters crystal=$i substructure atom_name" __])]

    set score_threshold $XMLParse([join "crank soap run step=$step crunch2 score_threshold" __])
    
    set deviation $XMLParse([join "crank soap run step=$step crunch2 deviation" __])

    set max_trials $XMLParse([join "crank soap run step=$step crunch2 ntrials" __])
    
    set before_bp3 $XMLParse([join "crank soap run step=$step crunch2 bp3_verify" __])

    array set score {}
    array set unoptscore {}
    array set previousindex {}
    array set cycle {}
    set testind  0
    set minscore 2.0
    set maxscore 0
    set maxindex 0
    set iter 1

    while { (![file exists done] && ($iter <= $max_trials)) } {

	runcommand [concat tclsh [file join $crankplugins crunch2 xml2crunch2script.tcl] $inccp4 $icol $iter $before_bp3 $max_trials 0 > crunch2-command$iter.com] $verbose
	runcommand [concat tclsh [file join $crankplugins crunch2 xml2crunch2script.tcl] $inccp4 $icol $iter $before_bp3 $max_trials 1 > crunch2-command$iter.tcl] $verbose
	runcommand [concat tclsh crunch2-command$iter.tcl] 1

	if { ($patt_search == 0) && [file exists sorted.xyz] } {
	    file delete sorted.xyz
	}

	if { ![file exists done] && [file exists trial1a.XYZ] } { 
	    set bp3_luzz 0.70
	    
	    set alltrials [glob trial*a.XYZ]
	    set nindex 0
	    foreach trial $alltrials {
		incr nindex
		set index [string trimleft [string trimright $trial "a.XYZ"] "trial"]
		set try [open $trial r]
		set data [read $try]
		set data [split $data "\n"]
		set lastelement [expr [llength $data] - 2]
		set score($index) [lindex $data $lastelement]
		if { $score($index) > $maxscore } {
		    set maxscore $score($index)
		    set maxindex $index
		}
		if { $score($index) < $minscore } {
		    set minscore $score($index)
		}
                close $try
	    }

	    if { ( ( $maxscore > $score_threshold) || ( ( $maxscore > [expr $deviation * $minscore] ) && ($maxscore > 0.3) ) ) } {
		set dum [open "done" w+ ]
		puts $dum "Crunch2 parameters indicates solution"
		set result "Crunch2 parameters indicates solution"
		flush $dum
		close $dum
		break
	    }

	    if { [file exists trial${max_trials}a.XYZ] } {
		set dum [open "done" w+ ]
		puts $dum "Maximum trials completed"
		set result "Maximum trials completed"
		flush $dum
		close $dum
		break
	    }		

	    set mod 0
	    if { ($iter > 1) && ($before_bp3 > 0) } {
		set mod  [expr $iter % $before_bp3]
	    }

	    set alreadytested 0

	    if {$testind > 0} {
		for { set i 1 } { $i <= $testind } { incr i } {
		    if { $previousindex($i) == $maxindex } {
			set alreadytested 1
			break
		    }
		}
	    }

	    if { ($before_bp3 > 0) && ($alreadytested == 0) && ($mod == 0) && ( ($maxscore > 0.3) || ($maxscore > [expr $minscore * 1.05]) ) && ($maxindex > [expr $iter-$before_bp3-1] ) } {
		incr testind
		set previousindex($testind) $maxindex 
		check_atom trial${maxindex}a.pdb substructure$iter.pdb 1 0 0 
                if { $inccp4 } {
                    set bp3_executable [file join $env(CBIN) bp3]
                } else {
                    set bp3_executable [file join $crankbin  bp3]    
                }
#		runcommand [concat tclsh [file join $crankplugins bp3 xml2bp3script.tcl] $inccp4 substructure$iter.pdb $iter 1 0 > bp3-command$iter.com] $verbose
		runcommand [concat tclsh [file join $crankplugins bp3 xml2bp3script.tcl] $inccp4 substructure$iter.pdb $iter 1 1 > bp3-command$iter.tcl] $verbose
		runcommand [concat tclsh bp3-command$iter.tcl] 1
		set logfile [open "bp3-logfile$iter" r]
		set data [read $logfile]
		set data [split $data "\n"]

		set luzzati 0
		set luzzatisd -1
		foreach line $data {
		    if { [regexp {average anomalous Luzzati error is *([0-9.]*).*} $line junk luzz] } {
			set luzzati $luzz
		    }
		    if { [regexp {deviation of the anomalous Luzzati error is *([0-9.]*).*} $line junk luzzsd] } {
			set luzzatisd $luzzsd
		    }
		}
		if { ($luzzati > $bp3_luzz) } {
		    set dum [open "done" w+ ]
		    puts $dum "Bp3 Luzzati parameter indicates solution"
		    set result "Bp3 Luzzati parameter indicates solution"
		    flush $dum
		    close $dum
		    if { [file exists crank.out.$tag-$iter.mtz] } {
			set gradlog [open "difference$iter-logfile" w]
			difference_maps crank.out.$tag-$iter.mtz "${tag}_FDIFF" "${tag}_PDIFF" 5 $gradlog "gradient$iter.pdb" $verbose
			if { [file exists gradient$iter.pdb] } {
			    add_remove_atoms heavy${iter}-1.pdb gradient$iter.pdb update$iter.pdb 
			}
		    }
		    break
		}
                close $logfile
	    }
	}
	incr iter
    }

    #
    if [file exists trial1a.XYZ] {

	if { [file exists crunch2-full-logfile] } {
	    set logfile [open "crunch2-full-logfile" r]
	    set data [read $logfile]
	    set data [split $data "\n"]
	    set ind 0
	    foreach line $data {
                regsub -all {\s+} $line " " line
  		if { [regexp {.*is stopped at cycle  *([0-9]*).*} $line junk cyc] } {
		    incr ind
  		    set cycle($ind) $cyc
		}
	    }   
	    close $logfile
	}

        set alltrials [glob trial*.XYZ]
	set unoptmaxscore 0
	foreach trial $alltrials {
	    set try [open $trial r]
	    set index [string trimleft [string trimright $trial ".XYZ"] "trial"]
	    set data [read $try]
	    set data [split $data "\n"]
	    set bestcycle($index) [lindex $data 0]
	    set lastelement [expr [llength $data] - 2]
	    set unoptscore($index) [lindex $data $lastelement]
	    if { $unoptscore($index) > $unoptmaxscore } {
	        set unoptmaxscore $unoptscore($index)
	        set unoptmaxindex $index 
	    }
	}
	set totaltrials 0
        set alltrials [glob trial*a.XYZ]
	set maxscore 0
	foreach trial $alltrials {
	    incr totaltrials
 	    set index [string trimleft [string trimright $trial "a.XYZ"] "trial"]
	    set try [open $trial r]
	    set data [read $try]
	    set data [split $data "\n"]
	    set lastelement [expr [llength $data] - 2]
	    set score($index) [lindex $data $lastelement]
	    if { $score($index) > $maxscore } {
	        set maxscore $score($index)
	        set maxindex $index 
	    }
	}
	if { ($maxscore < 0.1 ) } {
	   crank_error "CRUNCH2 FOM is lower than 0.1 - this probably means a solution was not found"
	}

	set smalllog [open "crunch2-logfile" w] 
	puts $smalllog "\n\$TABLE : Crunch2 FOM versus trial:"
	puts $smalllog "\$SCATTER"
	puts $smalllog " : FOM Unoptimized/Optimized per trial :A:1,2,3:"
	puts $smalllog " : Num_Cycles per trial :A:1,4:"
	puts $smalllog "\$\$"
	puts $smalllog "Trial  Unoptimized_FOM   Optimized_FOM   Best_Score_Cycle   Total_Cycles\$\$ \$\$"
	for {set i 1} {$i <= $totaltrials} {incr i} { 
	    puts $smalllog [format "  %3d       %5.3f            %5.3f          %4d               %4d" $i $unoptscore($i) $score($i) $bestcycle($i) $cycle($i)]
	}
	puts $smalllog "\$\$\n"

	if { ($unoptmaxscore > $maxscore) } {
	    puts $smalllog "\n\$TEXT:Warning: \$\$ Unoptimized FOM > Optimized FOM"

	    puts $smalllog "The Unoptimized FOM is greater than the Optimized FOM - this is not usually a good sign!"
	    puts $smalllog "\$\$\n"
	}

	puts $smalllog "\$TEXT:Result: \$\$ Final result \$\$"
	if { [info exists result] } {
	    puts $smalllog "$result"
	}
	puts $smalllog "Total number of trials: $totaltrials."
	puts $smalllog "\$\$\n"
	close $smalllog
	check_atom trial${maxindex}a.pdb crank.out.$tag.substructure.pdb 1 1 "crunch2-logfile"

	file copy crank.out.$tag.substructure.pdb [file join .. workdb crank.out.$tag.substructure.pdb]
 	file delete crank.out.$tag.substructure.pdb 

    } else {
       crank_error "No crunch2 trials have been produced"
    }

    if { [file exists crunch2-logfile] } {
	set log [open "crunch2-logfile" r]
	set output [read $log]
	puts $output
	close $log
	
	# Copy logfile to main log directory
	if { [file exists pmf-logfile] } { 
	    file copy pmf-logfile [file join .. log $step-pmf-logfile]
	}
	file copy crunch2-full-logfile [file join .. log $step-crunch2-full-logfile]
	file copy crunch2-logfile [file join .. log $step-crunch2-logfile]

    } else {
	crank_error "crank_crunch2.tcl::crunch2 did not finish successfully"
    }

    crank_ccp4_plugin_end $step "crunch2-crank" [expr ([clock clicks -millisec ]-$t0)/1000.]

    cd ..
}

proc crunch2_dependencies { step } {
    global XMLParse

}

proc crunch2_input_check { step } {
    global XMLParse

}

proc crunch2_reference { } {
    global XMLParse
    
    puts "Crunch2:"
    puts "<B><FONT COLOR=\"\#FF0000\"><!--SUMMARY_BEGIN-->\n"
    puts "\$TEXT:Reference: \$\$ Please reference \$\$"
    puts "de Graaff RAG, Hilge M, van der Plas JL & Abrahams JP (2001)"
    puts "Matrix methods for solving protein substructures of chlorine and"
    puts "sulfur from anomalous data. Acta Cryst. D57, 1857-1862."
    puts "\$\$\n"
    puts "<!--SUMMARY_END--></FONT></B>\n"
}
