# Copyright (C) 2003-2006 Leiden University
#
# Authors: Navraj S. Pannu and Steven Ness
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
proc shelxe_run { code crankbin executable crankplugins inputxml inccp4 step } {
    global XMLParse
    global env

    set t0 [clock clicks -millisec ]

    if { [info exists XMLParse([join "crank parameters version" __])] } {
       set xmlversion $XMLParse([join "crank parameters version" __])
    } else {
       crank_error "crank_shelxe.tcl::crank XML version info does not exist"
    }

    crank_plugin_begin $step "Density modification" "Shelxe" $crankplugins $xmlversion

    set verbose 0

    if { [info exists XMLParse([join "crank parameters verbose" __])] } {
       if { $XMLParse([join "crank parameters verbose" __]) >= 1 } {
	   set verbose 1
      }
    }

    if { $inccp4 } {
	set gcx_ex [file join $env(CBIN) gcx] 
	set mtz2hklcommand [file join $env(CBIN) gcx]
    } else {
	set gcx_ex [file join $crankbin  gcx] 
	set mtz2hklcommand [file join $crankbin  gcx]
    }	

    file mkdir $step-shelxe
    cd $step-shelxe
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    set inputmtz [file join .. workdb crank.in.$tag.mtz]

    if { [file exists [file join .. workdb crank.in.$tag.oh.mtz] ] } {
	set inputohmtz [file join .. workdb crank.in.$tag.oh.mtz]
    }

    # Convert the FA, SIGFA and ALPHA columns into a crank_fa.hkl file.
    if { [info exists XMLParse([join "crank soap run step=$step input fa_columns fa" __])] } {
	set fa $XMLParse([join "crank soap run step=$step input fa_columns fa" __])
	set sigfa $XMLParse([join "crank soap run step=$step input fa_columns sigfa" __])
	set alpha $XMLParse([join "crank soap run step=$step input alpha_columns alpha" __])
	mtz2hkl_fa $inputmtz crank_fa.hkl $fa $sigfa $alpha
    } else {
	crank_error "fa column needs to be defined."
    }

    # Run SHELXC to generate SHELXE command file 
    runcommand [concat tclsh [file join $crankplugins shelxc xml2shelxcscript.tcl] 0 >& shelxc-command.com] $verbose
    runcommand [concat tclsh [file join $crankplugins shelxc xml2shelxcscript.tcl] 1 >& shelxc-command.tcl] $verbose

    runcommand [concat tclsh shelxc-command.tcl] $verbose

    # Delete the crank.hkl file that was just created, since 
    # it could mislead SHELXE
    file delete crank.hkl
    file delete crank_fa.hkl

    # Convert the FA, SIGFA and ALPHA columns into a crank_fa.hkl file.
    set fa $XMLParse([join "crank soap run step=$step input fa_columns fa" __])
    set sigfa $XMLParse([join "crank soap run step=$step input fa_columns sigfa" __])
    set alpha $XMLParse([join "crank soap run step=$step input alpha_columns alpha" __])
    mtz2hkl_fa $inputmtz "crank_fa.hkl" $fa $sigfa $alpha
    
    if { [string compare $XMLParse([join "crank parameters input_intensity" __]) "1"] == 0 } {
	# Convert the I and SIGI columns into a crank.hkl file
	set i $XMLParse([join "crank soap run step=$step input i_columns i" __])
	set sigi $XMLParse([join "crank soap run step=$step input i_columns sigi" __])
	mtz2hkl $mtz2hklcommand $inputmtz crank $i $sigi 1
    } else {
	# Convert the F and SIGF columns into a crank.hkl file
	set f $XMLParse([join "crank soap run step=$step input f_columns f" __])
	set sigf $XMLParse([join "crank soap run step=$step input f_columns sigf" __])
	mtz2hkl $mtz2hklcommand $inputmtz crank $f $sigf 0
    }

    # Convert the coordinates to .res format
    set substructure $XMLParse([join "crank soap run step=$step input substructure" __])
    set substructurepdb "[file join .. workdb crank.out.$substructure.substructure.pdb]"
    if { [file exists [file join .. workdb crank.out.$substructure.oh.substructure.pdb] ] } {
	set substructureohpdb "[file join .. workdb crank.out.$substructure.oh.substructure.pdb ]"
    }

    pdb2shelxres $substructurepdb "crank_fa.ins" "crank_fa.res"

    set inputphases 0
    if { [info exists XMLParse([join "crank soap run step=$step input phase_columns f" __])] } {
	set f $XMLParse([join "crank soap run step=$step input phase_columns f" __])
	set fom $XMLParse([join "crank soap run step=$step input phase_columns fom" __])
	set alpha $XMLParse([join "crank soap run step=$step input phase_columns phib" __])
	set sigf $XMLParse([join "crank soap run step=$step input phase_columns sigf" __])
# ***NSP disable shelxe for hand determination
# mtz2phs $inputmtz "crank.phi" $f $fom $alpha $sigf
#	set inputphases 1
#if { [file exists $inputohmtz] } {
#	    mtz2phs $inputohmtz "crankoh.phi" $f $fom $alpha $sigf
#	}
    } 


    file mkdir hand1
    cd hand1

    set invert ""

    # Solvent content
    set solv $XMLParse(crank__parameters__solvent_content)

    # Run SHELXC to generate SHELXE command file 
    runcommand [concat tclsh [file join $crankplugins shelxe xml2shelxescript.tcl] $solv "crank.phi" 0 $invert >& shelxe-command.com] $verbose
    runcommand [concat tclsh [file join $crankplugins shelxe xml2shelxescript.tcl] $solv "crank.phi" 1 $invert >& shelxe-command.tcl] $verbose

    runcommand [concat tclsh shelxe-command.tcl] 1

    cd ..

    set calchand 1
    if { [info exists XMLParse([join "crank soap run step=$step shelxe no_hand" __]) ] } {
	if { $XMLParse([join "crank soap run step=$step shelxe no_hand" __]) == "1" } {
	    set calchand 0
	}
    }
    
    if { $calchand } {
	if { ($inputphases && [file exists crankoh.phi]) || !($inputphases) } {
	    file mkdir hand2
	    cd hand2
	    set invert "-i"

	    # need to generate ins if we have a different spacegroup for hand ***NSP

	    runcommand [concat tclsh [file join $crankplugins shelxe xml2shelxescript.tcl] $solv "crankoh.phi" 0 $invert >& shelxe-command.com] $verbose
	    runcommand [concat tclsh [file join $crankplugins shelxe xml2shelxescript.tcl] $solv "crankoh.phi" 1 $invert >& shelxe-command.tcl] $verbose

	    runcommand [concat tclsh shelxe-command.tcl] 1

	    cd ..	

	    # first shelxe to determine hand

	    # determine which hand is correct
	    runcommand [concat tclsh [file join $crankplugins shelxe shelxehand.tcl] >& shelxe-logfile] $verbose
	    set invert ""
	    if { [file exists shelxe-logfile] } { 
		set logfile [open "shelxe-logfile" r]
		set data [read $logfile]
		set data [split $data "\n"]
		foreach line $data {
		    if { $line       == "First hand has higher contrast." } {
			set invert ""
			break
		    } elseif { $line == "Second hand has higher contrast." } {
			set invert "-i"
			break
		    }
		}
	    }
	}
    }

    if { [info exists XMLParse([join "crank soap run step=$step shelxe optimize_solvent" __])] } {
	if { $XMLParse([join "crank soap run step=$step shelxe optimize_solvent" __]) == "1" } {

	    if { [info exists XMLParse([join "crank soap run step=$step shelxe opt_cycles" __])] } {
		set optcycles $XMLParse([join "crank soap run step=$step shelxe opt_cycles" __])
	    } else {
		set optcycles 5
	    }

	    set initmonomers $XMLParse([join "crank parameters nmonomers" __])

	    if { [info exists XMLParse([join "crank parameters seqin filename" __]) ] } {
		set seq_in $XMLParse([join "crank parameters seqin filename" __])
		if { [string compare $XMLParse([join "crank parameters input_intensity" __]) "1"] == 0 } {
		    # Convert the I and SIGI columns into a crank.hkl file
		    set i $XMLParse([join "crank soap run step=$step input i_columns i" __])
		    set sigi $XMLParse([join "crank soap run step=$step input i_columns sigi" __])
		    set command "$gcx_ex HKLIN $inputmtz SEQIN $seq_in << \"NOUT\n XTAL DER1\n DNAME TMP\n COLU I=$i SI=$sigi\" "

		} else {
		    # Convert the F and SIGF columns into a crank.hkl file
		    set f $XMLParse([join "crank soap run step=$step input f_columns f" __])
		    set sigf $XMLParse([join "crank soap run step=$step input f_columns sigf" __])
		    set command "$gcx_ex HKLIN $inputmtz SEQIN $seq_in << \"NOUT\n XTAL DER1\n DNAME TMP\n COLU F=$f SF=$sigf\" "
		}

	    } else {
		set nresidues $XMLParse(crank__parameters__residues)

		set nnucleotides $XMLParse(crank__parameters__nucleotides)

		if { [string compare $XMLParse([join "crank parameters input_intensity" __]) "1"] == 0 } {
		    # Convert the I and SIGI columns into a crank.hkl file
		    set i $XMLParse([join "crank soap run step=$step input i_columns i" __])
		    set sigi $XMLParse([join "crank soap run step=$step input i_columns sigi" __])
		    set command "$gcx_ex HKLIN $inputmtz << \"NRES $nresidues\n NNUC $nnucleotides\n NOUT\n XTAL DER1\n DNAME TMP\n COLU I=$i SI=$sigi\" "

		} else {
		    # Convert the F and SIGF columns into a crank.hkl file
		    set f $XMLParse([join "crank soap run step=$step input f_columns f" __])
		    set sigf $XMLParse([join "crank soap run step=$step input f_columns sigf" __])
		     set command "$gcx_ex HKLIN $inputmtz << \"NRES $nresidues\n NNUC $nnucleotides\n NOUT\n XTAL DER1\n DNAME TMP\n COLU F=$f SF=$sigf\" "
		}

	    }

	    catch {eval exec $command } output	
	    set data $output
	    set data [split $data "\n"]
	    array set listmatt {}
	    array set listsolv {}
	    array set listprob {}
	    set nummon 1

	    foreach line $data {
		if       { [regexp {    *([0-9]*)         *([-0-9.]*)             *([-0-9.]*)            *([0-1].*).*} $line junk number matthews sol prob ] } {
		    if { $number != "" } {
			set listmatt($number) $matthews
			set listsolv($number) $sol
			set listprob($number) $prob
			set nummon $number
		    }
		} elseif { [regexp {   *([0-9]*)         *([-0-9.]*)             *([-0-9.]*)            *([0-1].*).*} $line junk number matthews sol prob ] } {
		    if { $number != "" } {
			set listmatt($number) $matthews
			set listsolv($number) $sol
			set listprob($number) $prob
			set nummon $number
		    }
		}
	    }

	    set minprob 0.01
	    if { $nummon > 1 } {
		foreach {key solv} [array get listsolv] {
		    if { ($listprob($key) > $minprob) && ($solv > 0.1) && ($solv < 0.9) } {
			file mkdir shelxe-$solv
			cd shelxe-$solv

			if { [info exists invert] } {
			    runcommand [concat tclsh [file join $crankplugins shelxe xml2shelxescript.tcl] $solv "crankoh.phi" 0 $invert >& shelxe-command.com] $verbose
			    runcommand [concat tclsh [file join $crankplugins shelxe xml2shelxescript.tcl] $solv "crankoh.phi" 1 $invert >& shelxe-command.tcl] $verbose
			} else {
			    runcommand [concat tclsh [file join $crankplugins shelxe xml2shelxescript.tcl] $solv "crank.phi" 0 $invert >& shelxe-command.com] $verbose
			    runcommand [concat tclsh [file join $crankplugins shelxe xml2shelxescript.tcl] $solv "crank.phi" 1 $invert >& shelxe-command.tcl] $verbose
			}
			runcommand [concat tclsh shelxe-command.tcl] 1

			cd ..
		    }
		}

		set allsolvent [glob shelxe-0.*]
	
		array set contrast {}
		array set content {}
		set run 0
		set num1 0
		set optlog [open "shelxeoptimize-logfile" w+]
		foreach solvent $allsolvent { 
		    set number 0    
		    set logfile [open "[file join $solvent shelxe-logfile]" r]
		    set content($run) [string trimleft $solvent "shelxe-"]
	    
		     set data [read $logfile]
		    set data [split $data "\n"]
		    foreach line $data {
			if { [regexp {<wt> = *([0-9.]*).*, Contrast = *([-0-9.]*).*, Connect. = *([-0-9.]*).* for dens.mod. cycle *([0-9]*).*} $line junk wt cont connect n] } {
			    set contrast($run,$number) $cont
			    incr number
			}
		    }  
		    close $logfile
		    set num1 [expr $handcycles - 1]
		    puts $optlog "Solvent content $content($run): Contrast from the final cycle is $contrast($run,$num1)"
		    incr run
		}
	
		set maxcontrast 0
		set optimal 0
		for { set j 0 } { $j < $run } { incr j } {
		    if { $contrast($j,$num1) > $maxcontrast } {
			set maxcontrast $contrast($j,$num1) 
			set optimal $j 
		    }
		}

		set monomers $XMLParse(crank__parameters__nmonomers)
		puts $optlog "\nChoosing solvent content $content($optimal)\n"
		foreach {key solv} [array get listsolv] {
		     if {$listsolv($key) == $content($optimal) } {
			 set monomers $key
			 puts $optlog "Corresponding to $key monomers"
			 break
		     }
		}
		close $optlog

		if { $monomers != $XMLParse(crank__parameters__nmonomers) } {
		    set input [open [file join .. xml input.xml] a+]
		    puts $input "<crank><update>"
		    puts $input "<nmonomers>$monomers</nmonomers>"
		    puts $input "<solvent_content>$content($optimal)</solvent_content>"
		    puts $input "</update></crank>"
		    close $input
		}
	    }
	    if { [file exists shelxeoptimize-logfile] } {
		set log [open "shelxeoptimize-logfile" r]
		set output [read $log]
		puts $output
		close $log
	    }
	}
    }

    if { $invert == "" } {
	set phs_file_name [file join hand1 crank.phs]
	set hat_file_name [file join hand1 crank.hat]
	if { $inputphases } {
	    set phs_file_name_oh [file join hand2 crank.phs]
	    set hat_file_name_oh [file join hand2 crank.hat]
	} else {
 	    set phs_file_name_oh [file join hand2 crank_i.phs]
	    set hat_file_name_oh [file join hand2 crank_i.hat]
	}
	if { [file exists [file join hand1 crank.pdb] ] } {
	    set pdb_file_name [file join hand1 crank.pdb]
	}
	if { [file exists [file join hand2 crank_i.pdb] ] } {
	    set pdb_file_name_oh [file join hand2 crank_i.pdb]
	}
	set invert_oh "-i"
    } else {
 	if { $inputphases } {
	    set phs_file_name [file join hand2 crank.phs]
	    set hat_file_name [file join hand2 crank.hat]
	} else {
	    set phs_file_name [file join hand2 crank_i.phs]
	    set hat_file_name [file join hand2 crank_i.hat]
	}
	set phs_file_name_oh [file join hand1 crank.phs]
	set hat_file_name_oh [file join hand1 crank.hat]
	if { [file exists [file join hand2 crank_i.pdb] ] } {
	    set pdb_file_name [file join hand2 crank_i.pdb]
	}
	if { [file exists [file join hand1 crank.pdb] ] } {
	    set pdb_file_name_oh [file join hand1 crank.pdb]
	}
	set invert_oh ""
	set sg_number $XMLParse([join "crank parameters input_spacegroup number" __])
	set mtz_in [file join .. workdb crank.out.IN.mtz]
	enantiomorph_mtz $mtz_in temp.mtz $sg_number
	if { [file exists temp.mtz] } {
	    file copy $mtz_in  [file join .. workdb crank.out.IN.oh.mtz]
	    file delete [file join .. workdb crank.out.IN.mtz]
	    file copy temp.mtz [file join .. workdb crank.out.IN.mtz]
	    file delete temp.mtz
	}
    }

    if { ![file exists $phs_file_name] } {
	crank_error "crank_shelxe.tcl::file ($phs_file_name) does not exist."
    }

    runcommand [concat tclsh [file join $crankplugins shelxe crank-rename-shelxe-output.tcl] $phs_file_name rename.out.mtz $invert] $verbose
    file copy rename.out.mtz [file join .. workdb crank.out.$tag.mtz]
    file delete rename.out.mtz

    if { [info exists invert_oh] } {
	runcommand [concat tclsh [file join $crankplugins shelxe crank-rename-shelxe-output.tcl] $phs_file_name_oh rename.out.mtz $invert_oh] $verbose
	file copy rename.out.mtz [file join .. workdb crank.out.$tag.oh.mtz]
	file delete rename.out.mtz
    }

    if { ![file exists $hat_file_name] } {
	if { $invert == "" } {
	    file copy $substructurepdb [file join .. workdb crank.out.$tag.substructure.pdb]
	    file copy $substructureohpdb [file join .. workdb crank.out.$tag.oh.substructure.pdb]
	} else {
 	    file copy $substructureohpdb [file join .. workdb crank.out.$tag.substructure.pdb]
	    file copy $substructurepdb [file join .. workdb crank.out.$tag.oh.substructure.pdb]
	}
    } else {
	# Revised coordinates
	runcommand [concat tclsh [file join $crankplugins shelxe shelxhat2pdb.tcl] $hat_file_name $inputmtz "temp.pdb" ] $verbose
	check_atom temp.pdb [file join .. workdb crank.out.$tag.substructure.pdb] 1 1 "shelxe-logfile"
	file delete temp.pdb
 	runcommand [concat tclsh [file join $crankplugins shelxe shelxhat2pdb.tcl] $hat_file_name_oh $inputmtz "temp.pdb" ] $verbose
	check_atom temp.pdb [file join .. workdb crank.out.$tag.oh.substructure.pdb] 1 0 0
	file delete temp.pdb

    }

    if { [info exists pdb_file_name] } {

	if { [file exists $pdb_file_name] } {
	    file copy $pdb_file_name [file join .. workdb crank.out.$tag.pdb]
	}
    }

    if { [info exists pdb_file_name_oh] } {

	if { [file exists $pdb_file_name_oh] } {
	     file copy $pdb_file_name_oh [file join .. workdb crank.out.$tag.oh.pdb]
	}
    }

    if { [file exists shelxe-logfile] } {
	set log [open "shelxe-logfile" r]
	set output [read $log]
	puts $output
	close $log
	file copy shelxe-logfile [file join .. log $step-shelxe-logfile]
    } else {
	crank_error "crank_shelxe.tcl::shelxe did not finish successfully"
    }

    crank_ccp4_plugin_end $step "shelxe" [expr ([clock clicks -millisec ]-$t0)/1000.]
	
    cd ..
}

proc shelxe_dependencies { step } {
    global XMLParse

}

proc shelxe_input_check { step } {
    global XMLParse

}

proc shelxe_reference { } {
    puts "SHELXE:"
    puts "<B><FONT COLOR=\"\#FF0000\"><!--SUMMARY_BEGIN-->\n"
    puts "\$TEXT:Reference: \$\$ Please reference \$\$"
    puts "Sheldrick GM (2002) Macromolecular phasing with "
    puts "SHELXE. Z. Kristallogr. 217, 644-650."
    puts "\$\$\n"
    puts "<!--SUMMARY_END--></FONT></B>\n"
}
