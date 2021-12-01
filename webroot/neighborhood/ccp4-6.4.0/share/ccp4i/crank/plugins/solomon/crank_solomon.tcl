#
# Copyright (C) Navraj S. Pannu and Jan Pieter Abrahams 2006,  Leiden University
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

proc solomon_run { code crankbin executable crankplugins inputxml inccp4 step } {
    global XMLParse

    set t0 [clock clicks -millisec ]

    if { [info exists XMLParse([join "crank parameters version" __])] } {
       set xmlversion $XMLParse([join "crank parameters version" __])
    } else {
       crank_error "crank_solomon.tcl::crank XML version info does not exist"
    }    

    crank_plugin_begin $step "Density modification" "Solomon" $crankplugins $xmlversion
    
    set verbose 0

    if { [info exists XMLParse([join "crank parameters verbose" __])] } {
       if { $XMLParse([join "crank parameters verbose" __]) >= 1 } {
	   set verbose 1
      }
    }

    crank_ccp4_banner "solomon" $xmlversion

    file mkdir $step-solomon
    cd $step-solomon
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]
    set enant 1

    set nomtz 1
    if { $XMLParse([join "crank soap run step=$step solomon keep_mtz" __]) == "1" } {
       set nomtz 0
    }

    set bias 1
    if { [ info exists XMLParse([join "crank soap run step=$step solomon bias" __]) ] } {
	if { $XMLParse([join "crank soap run step=$step solomon bias" __]) == "0" } {
	    set bias 0
	}
    }

    if { [info exists XMLParse([join "crank soap run step=$step solomon ncycles" __])] } {
	set ncycles $XMLParse([join "crank soap run step=$step solomon ncycles" __])
    } else {
	set ncycles 20
    }    

    if { [info exists XMLParse([join "crank soap run step=$step solomon hand_cycles" __])] } {
	set hcycles $XMLParse([join "crank soap run step=$step solomon hand_cycles" __])
    } else {
	set hcycles 5
    }    

    if { [info exists XMLParse([join "crank soap run step=$step solomon hand_target" __])] } {
	set hand_target $XMLParse([join "crank soap run step=$step solomon hand_target" __])
    } else {
	set hand_target "MLHL"
    }    

    set hand 0
    if { ($XMLParse([join "crank soap run step=$step solomon no_hand" __]) == "0") } {
    set hand 1

	runcommand [concat tclsh [file join $crankplugins solomon solomonhand.tcl] $hcycles $nomtz $inccp4 1 > solomon-logfile] 1

	if { ( [file exists [file join hand1 solomon.mtz]] &&
	       [file exists [file join hand2 solomon.mtz]] )  } {

	    set logfile1 [open "solomon-logfile" r]
	    set data [read $logfile1]
#	puts $data
	    set data [split $data "\n"] 	
	    set inputtag [string trim $XMLParse([join "crank soap run step=$step input substructure" __])]

	    foreach line $data {
		if { $line       == "The input hand has a higher score." } {
		    set enant 1
		    set solomonmtz "[file join hand1 solomon.mtz]"
#		    set solomonohmtz "[file join hand2 solomon.mtz]"
		    if { ! [file exists [file join .. workdb crank.out.$tag.substructure.pdb] ] } { 
			file copy [file join .. workdb crank.out.$inputtag.substructure.pdb] [file join .. workdb crank.out.$tag.substructure.pdb]
			file copy [file join .. workdb crank.out.$inputtag.oh.substructure.pdb] [file join .. workdb crank.out.$tag.oh.substructure.pdb]
		    }
		    break
		} elseif { $line == "The inverted hand has a higher score." } {
		    set enant 2
		    set solomonmtz "[file join hand2 solomon.mtz]"
#		    set solomonohmtz "[file join hand1 solomon.mtz]"
		    if { ! [file exists [file join .. workdb crank.out.$tag.substructure.pdb] ] } { 
			file copy [file join .. workdb crank.out.$inputtag.oh.substructure.pdb] [file join .. workdb crank.out.$tag.substructure.pdb]
			file copy [file join .. workdb crank.out.$inputtag.substructure.pdb] [file join .. workdb crank.out.$tag.oh.substructure.pdb]
		    }
		    break
		}
	    }
	    close $logfile1
	} else {
	    set solomonmtz "[file join hand1 solomon.mtz]"
#	    if { [file exists [file join hand2 solomon.mtz]] } {
#		set solomonohmtz "[file join hand2 solomon.mtz]"
#	    }
	    set inputtag [string trim $XMLParse([join "crank soap run step=$step input substructure" __])]

	    if { ![file exists [file join .. workdb crank.out.$tag.substructure.pdb] ] } { 
		file copy [file join .. workdb crank.out.$inputtag.substructure.pdb] [file join .. workdb crank.out.$tag.substructure.pdb]
		if { [file exists [file join .. workdb crank.out.$inputtag.oh.substructure.pdb] ] } { 
		    file copy [file join .. workdb crank.out.$inputtag.oh.substructure.pdb] [file join .. workdb crank.out.$tag.oh.substructure.pdb]
		}
	    }
	}
    }
    
    if { $XMLParse([join "crank soap run step=$step solomon density_modify" __]) == "1" } {
	set phasingphases 0
	set phasingcoefficients 0
	
	set run 1
	if { [info exists XMLParse([join "crank soap run step=$step solomon phase_comb" __])] } {
	    if { ($XMLParse([join "crank soap run step=$step solomon phase_comb" __]) == $hand_target) && [info exists solomonmtz] && ($ncycles == $hcycles)  } {
		set run 0
	    }
	}
	
	if { $run } {
	    set solv $XMLParse([join "crank parameters solvent_content" __])
	    file mkdir solomon-$solv
	    cd solomon-$solv
	    runcommand [concat tclsh [file join $crankplugins solomon xml2solomonscript.tcl] $ncycles $solv $enant $nomtz 0 $inccp4 0 $bias 1 $step >& solomon-command.py] $verbose
	    runcommand [concat ccp4-python solomon-command.py >& solomon-logfile] 1
	    cd ..	
	    catch { solomongraph [file join solomon-$solv solomon-logfile] "" "" "" 0 0 } output
	    set log [open "solomon-logfile" a+]
	    puts $log $output
	    close $log
	    set solomonmtz "[file join solomon-$solv solomon.mtz]"
	    set inputtag [string trim $XMLParse([join "crank soap run step=$step input substructure" __])]
	    if { ![file exists [file join .. workdb crank.out.$tag.substructure.pdb] ] } { 
		file copy [file join .. workdb crank.out.$inputtag.substructure.pdb] [file join .. workdb crank.out.$tag.substructure.pdb]
		if { [file exists [file join .. workdb crank.out.$inputtag.oh.substructure.pdb] ] } { 
		    file copy [file join .. workdb crank.out.$inputtag.oh.substructure.pdb] [file join .. workdb crank.out.$tag.oh.substructure.pdb]
		}
	    }
	}
    } else {
      set phasingphases 1
      set phasingcoefficients 1
    }

    if { [info exists XMLParse([join "crank soap run step=$step solomon optimize_solvent" __]) ] } {
	if { $XMLParse([join "crank soap run step=$step solomon optimize_solvent" __]) == "1" } {
	    runcommand [concat tclsh [file join $crankplugins solomon solomonoptimize.tcl] $crankplugins $inccp4 $ncycles $enant $nomtz $bias >& solomonoptimize-logfile] $verbose

	    set logfile1 [open "solomonoptimize-logfile" r]
	    set data [read $logfile1]
	    set data [split $data "\n"]
	    foreach line $data {
		if { [regexp {Choosing solvent content* *([0-9.]*).*} $line junk solvent ] } {
		    set solomonmtz [file join solomon-$solvent solomon.mtz]
		    break
		}
	    }
	    close $logfile1

	    file copy solomonoptimize-logfile [file join .. log $step-solomonoptimize-logfile]
	}
    }

    if { [info exists XMLParse([join "crank soap run step=$step solomon hlphasing_coefficients " __])] } {
	set phasingcoefficients $XMLParse([join "crank soap run step=$step solomon hlphasing_coefficients" __])
    }

    # Rename output columns to the names specified in the XML
    set temptag [string trim $XMLParse([join "crank soap run step=$step input hl_columns hla" __])]
    set phasingtag [string trim $temptag _HLA]
    set hla _HLA
    set hlb _HLB
    set hlc _HLC
    set hld _HLD

    set refmac 0
    if { [info exists XMLParse([join "crank soap run step=$step solomon phase_comb" __])] } {
       if { $XMLParse([join "crank soap run step=$step solomon phase_comb" __]) == "REFMAC" } {
  	   set refmac 1
       }
    }

    if { [file exists $solomonmtz] } {
	if { $refmac } {
	    if { $enant == 1 } {
		set mtz_in "[file join .. workdb crank.in.$tag.mtz]"
	    } else {
 		set mtz_in "[file join .. workdb crank.in.$tag.oh.mtz]"
	    }
	    set sftools_script "read $mtz_in\n write temp1.mtz col [format "%s%s" $phasingtag $hla] [format "%s%s" $phasingtag $hlb] [format "%s%s" $phasingtag $hlc] [format "%s%s" $phasingtag $hld]\n quit\n"
	    set command "sftools << \"$sftools_script\""
       	    catch {eval exec $command } output
            # puts $output	
 	    set sftools_script "read $solomonmtz\n read temp1.mtz\n"
	    
	} else {
	    set sftools_script "read $solomonmtz\n"
	}

	if { $phasingcoefficients == 1 } {
	    if { $phasingphases == 1 } { 
		set sftools_script "$sftools_script delete col PHIB FOM\n"
	    }
 	    set sftools_script "$sftools_script delete col HLA HLB HLC HLD\n"
	    set sftools_script "$sftools_script set label col [format "%s%s" $phasingtag $hla] \n HLA \n"
	    set sftools_script "$sftools_script set label col [format "%s%s" $phasingtag $hlb] \n HLB \n"
	    set sftools_script "$sftools_script set label col [format "%s%s" $phasingtag $hlc] \n HLC \n"
	    set sftools_script "$sftools_script set label col [format "%s%s" $phasingtag $hld] \n HLD \n"
	    set sftools_script "$sftools_script write temp.mtz\nquit\n"
	    set command "sftools << \"$sftools_script\""

	    # puts $command
	    catch {eval exec $command } output
	    # puts $output	
	} else {
	    file copy $solomonmtz temp.mtz
	}

 	if { $phasingcoefficients == 1 } {
	    if { $phasingphases == 1 } {
		set script "start -mtzin temp.mtz -mtzout tempa.mtz -colin-hl /*/*/\\\[HLA,HLB,HLC,HLD\\\] -colout /*/*/\\\[PHIB,FOM\\\]"
		set command "chltofom <<$script"
		catch {eval exec $command} output
		file delete temp.mtz
		 file copy tempa.mtz temp.mtz
		file delete tempa.mtz
	    }
	}

	runcommand [concat tclsh [file join $crankplugins solomon crank-rename-solomon-output.tcl] temp.mtz rename.out.mtz] $verbose
	file copy rename.out.mtz [file join .. workdb crank.out.$tag.mtz]
        if { [file exists temp1.mtz] } {
           file delete temp1.mtz
        }
        file delete temp.mtz
	file delete rename.out.mtz

    } else {
	crank_error "crank::runsolomon:: $solomonmtz not present."
    }

    if { [info exists solomonohmtz] } {
	if { $refmac } {
	    if { $enant == 2 } {
		set mtz_in "[file join .. workdb crank.in.$tag.oh.mtz]"
	    } else {
 		set mtz_in "[file join .. workdb crank.in.$tag.mtz]"
	    }
	    set sftools_script "read $mtz_in\n write temp1.mtz col [format "%s%s" $phasingtag $hla] [format "%s%s" $phasingtag $hlb] [format "%s%s" $phasingtag $hlc] [format "%s%s" $phasingtag $hld]\n quit\n"
	    set command "sftools << \"$sftools_script\""
       	    catch {eval exec $command } output
#           puts $output	
 	    set sftools_script "read $solomonohmtz\n read temp1.mtz\n"
	    
	} else {
	    set sftools_script "read $solomonohmtz\n"
	}

	if { $phasingcoefficients == 1 } {
	    set temptag [string trim $XMLParse([join "crank soap run step=$step input hl_columns hla" __])]
	    set phasingtag [string trim $temptag _HLA]
 	    if { $phasingphases == 1 } {
 		set phib _PHIB
 		set fom _FOM
  		set sftools_script "$sftools_script delete col PHIB\n"
  		set sftools_script "$sftools_script delete col FOM\n"
 		set sftools_script "$sftools_script set label col [format "%s%s" $phasingtag $phib] \n PHIB \n"
 		set sftools_script "$sftools_script set label col [format "%s%s" $phasingtag $fom] \n FOM \n"
	    }
	    set hla _HLA
	    set hlb _HLB
	    set hlc _HLC
	    set hld _HLD
  	    set sftools_script "$sftools_script delete col HLA HLB HLC HLD\n"
	    set sftools_script "$sftools_script set label col [format "%s%s" $phasingtag $hla] \n HLA  \n"
	    set sftools_script "$sftools_script set label col [format "%s%s" $phasingtag $hlb] \n HLB  \n"
	    set sftools_script "$sftools_script set label col [format "%s%s" $phasingtag $hlc] \n HLC  \n"
	    set sftools_script "$sftools_script set label col [format "%s%s" $phasingtag $hld] \n HLD  \n"
	    set sftools_script "$sftools_script write temp.mtz\nquit\n"
	} else {
	    set sftools_script "$sftools_script hlconv col PHWT FOM\n"
	    set sftools_script "$sftools_script set label col PA\nHLA\n"
	    set sftools_script "$sftools_script set label col PB\nHLB\n"
	    set sftools_script "$sftools_script calc A col HLC = 0\n"
	    set sftools_script "$sftools_script calc A col HLD = 0\n"
	    set sftools_script "$sftools_script write temp.mtz\nquit\n"
	}
	set command "sftools << \"$sftools_script\""

#        puts $command
	catch {eval exec $command } output
#        puts $output	
	runcommand [concat tclsh [file join $crankplugins solomon crank-rename-solomon-output.tcl] temp.mtz rename.out.mtz] $verbose
	file copy rename.out.mtz [file join .. workdb crank.out.$tag.oh.mtz]
	if { [file exists temp1.mtz] } {
	   file delete temp1.mtz
	}
     	file delete temp.mtz
	file delete rename.out.mtz
    }

    if { [file exists solomon-logfile] } {
	file copy solomon-logfile [file join .. log $step-solomon-logfile]
	set log [open "solomon-logfile" r]
	set output [read $log]
	puts $output
	close $log
    }

    crank_ccp4_plugin_end $step "solomon-crank" [expr ([clock clicks -millisec ]-$t0)/1000.]

    cd ..
}

proc solomon_dependencies { step } {
    global XMLParse

    set command "cfft"
    catch {eval exec $command } output 
    set err [lindex $::errorCode 0]
    # Check to see if the executable is found
    if { [string compare $err "POSIX"] == 0 } {
	crank_error "crank::crankutils.tcl::Error cfft executable not found.  Please install CCP4 with clipper enabled."
    } 

}

proc solomon_input_check { step } {
    global XMLParse

}

proc solomon_reference { } {
    global XMLParse
    
    puts "Solomon:"
    puts "<B><FONT COLOR=\"\#FF0000\"><!--SUMMARY_BEGIN-->\n"
    puts "\$TEXT:Reference: \$\$ Please reference \$\$"
    puts "Abrahams JP & Leslie AGW (1996) Methods used in the"
    puts "structure determination of bovine mitochondrial F1 ATPase."
    puts "Acta Cryst. D52, 30-42."
    puts "\$\$\n"
    puts "Multicomb:"
    puts "\$TEXT:Reference: \$\$ Please reference \$\$"
    puts "Skubak P, Waterreus WJ & Pannu NS (2010)"
    puts "Multivariate phase combination improves automated crystallographic"
    puts "model building.  Acta Cryst. D66, 783-788."
    puts "\$\$\n"
    puts "<!--SUMMARY_END--></FONT></B>\n"
} 
