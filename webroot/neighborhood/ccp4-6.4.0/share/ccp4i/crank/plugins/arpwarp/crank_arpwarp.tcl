#
# Copyright (C) Navraj S. Pannu and Steven Ness 2004-2005, Leiden University
# Copyright (C) Navraj S. Pannu 2006-2008, Leiden University
#
#
# All rights reserved.
#
# This file may not be copied, reproduced, modified or distributed
# in any way.
#

proc arpwarp_run { code crankbin executable crankplugins inputxml inccp4 step } {
    global XMLParse

    set t0 [clock clicks -millisec ]


    if { [info exists XMLParse([join "crank parameters version" __])] } {
	set xmlversion $XMLParse([join "crank parameters version" __])
    } else {
       crank_error "crank_arpwarp.tcl::crank XML version info does not exist"
    }

    crank_plugin_begin $step "Automated model building and refinement" "ARP/wARP" $crankplugins $xmlversion

    set verbose 0

    if { [info exists XMLParse([join "crank parameters verbose" __])] } {
       if { $XMLParse([join "crank parameters verbose" __]) >= 1 } {
	   set verbose 1
      }
    }

    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    set inputmtz [file join [pwd] workdb crank.in.$tag.mtz]
    
    if { $XMLParse([join "crank parameters residues" __]) < 1 } {
	crank_error "No protein residues in macromolecule"
    }

    set phase_restrain ""

    if { [info exists XMLParse([join "crank soap run step=$step arpwarp phase_restrain" __])] } {
       set phase_restrain $XMLParse([join "crank soap run step=$step arpwarp phase_restrain" __])
    }

    if { $phase_restrain == "DIRECT" } {
	set substructure_tag $XMLParse([join "crank soap run step=$step input substructure" __])
	set inputsubstructure [file join [pwd] workdb crank.out.$substructure_tag.substructure.pdb]
    }

    file mkdir $step-arpwarp
    cd $step-arpwarp

    #
    # Setup ARP/wARP defaults
    #
    set workdir [file join [pwd] run]
    file mkdir $workdir

    set heavyin ""

    if { $phase_restrain == "DIRECT" } {
        check_refmac_substructure $inputsubstructure heavy.pdb	
	# Set the heavyin variable to the name of the heavy.pdb file we just created.
	set heavyin [file join [pwd] heavy.pdb]
    }

    if { [info exists XMLParse([join "crank parameters sequence" __])] } {
	set seq [open sequence.pir w+]
	puts $seq ">\n"
	regsub -all {[^a-zA-Z]} $XMLParse([join "crank parameters sequence" __]) "" sequence
	for {set i 0 } { $i < [string length $sequence] } { incr i 60 } {
	    if { [expr $i + 59] <  [string length $sequence] } {
 		puts $seq "[string range $sequence $i [expr $i + 59] ]" 
	    } else {
 		puts $seq "[string range $sequence $i  end]" 
	    }
	}
	flush $seq
	close $seq
    }

    # Now generate the ARP/wARP .par input file
    runcommand [concat tclsh [file join $crankplugins arpwarp xml2arpwarp_par.tcl] $inputxml $inputmtz $crankbin $heavyin >& input.par] $verbose

    # Set dummy ccp4i def file
     set dum [open dummy.def w+]
     puts $dum "#CCP4I VERSION DUMMY\n#CCP4I PROJECT PROJECT" 
     flush $dum
     close $dum

    # Run run arpwarp
    set script [open arp_refmac-command.com w+]
    puts $script "ccp4-python [file join $crankbin run_arpwarp_refmac5.py] < input.par"
    flush $script
    close $script
    runcommand [concat sh arp_refmac-command.com] 1
    #runcommand [concat python [file join $crankbin run_arpwarp_refmac5.py] < input.par] 1

    if { [file exists 1_arp_warp.log] } {
       file copy 1_arp_warp.log arpwarp-logfile

	set log [open "arpwarp-logfile" r]
	set output [read $log]
	puts $output
	close $log

	# Copy logfile to main log directory
	file copy arpwarp-logfile [file join .. log $step-arpwarp-logfile]
	
    } else {
       crank_error "ARP/wARP + REFMAC log file not created"
    }


    if { [file exists dummy.def] } {
        file delete dummy.def
    }

    # Rename ARP/wARP output column names.

    if { [file exists 1_warpNtrace.mtz] } {
        runcommand [concat tclsh [file join $crankplugins arpwarp crank-rename-arpwarp-output.tcl] $inputxml 1_warpNtrace.mtz [file join .. workdb crank.out.$tag.mtz] $crankbin] $verbose
#	file delete 1_warpNtrace.mtz
    } else {
       crank_error "ARP/wARP + REFMAC mtz file not created"
    }

    # Copy the final ARP/wARP PDB model to the work directory
    if { [file exists heavy.pdb.ref] } {
        file copy heavy.pdb.ref [file join .. workdb crank.out.${tag}.substructure.pdb]
    }

    if { [file exists 1_warpNtrace.pdb] } {
        file copy 1_warpNtrace.pdb [file join .. workdb crank.out.$tag.pdb]
	file delete 1_warpNtrace.pdb
    } else {
       crank_error "ARP/wARP + REFMAC pdb not created"
    }

    if { [file exists 1_map_mfoDfc_warpNtrace.ext] } {
        file delete 1_map_mfoDfc_warpNtrace.ext
    } 

    if { [file exists 1_map_2mfoDfc_warpNtrace.map] } {
        file delete 1_map_2mfoDfc_warpNtrace.map
    } 

    if { [file exists 1_map_2mfoDfc_warpNtrace.ext] } {
        file delete 1_map_2mfoDfc_warpNtrace.ext
    } 
    
    if { [file exists CCP4_DATABASE] } {
       file delete CCP4_DATABASE
    }

    if { [info exists XMLParse(crank__parameters__disk_space] } {
	if { $XMLParse(crank__parameters__disk_space) == "clean" ||
	     $XMLParse(crank__parameters__disk_space) == "compress"  } {
	    compress *.log
	}
    }

    crank_plugin_end $step [expr ([clock clicks -millisec ]-$t0)/1000.]

    cd ..

}

proc arpwarp_dependencies { step } {
    global XMLParse

    # First, create and run an ARP/wARP command line
    set arp_command "arp_warp"
    set arp_script "MODE MIRBUILD\nEND\n"
    set command "$arp_command << \"$arp_script\""
    catch {eval exec $command } output 
    set err [lindex $::errorCode 0]
    # Check to see if the executable is found
    if { [string compare $err "POSIX"] == 0 } {
	crank_error "crank::crankutils.tcl::Error arp_warp executable not found.  Please install ARP/wARP or make sure it is in your PATH - see http://www.arp-warp.org/ for more info."
    }

    # Check to see if we have the correct version
    if { [regexp {.*ARP Ver. ([0-9.]*)} $output match version1]} {
	set version [string range $version1 0 2]
	if { $version >= 7.1 } {
	    puts "Found ARP/wARP version $version\n"
	} else {
	    crank_error "crank::crankutils.tcl::Error version 7.1 of ARP/wARP not installed, current version is ($version).  Please install latest version - see http://www.arp-warp.org for more info."
	}
    } else {
	crank_error "crank::crankutils.tcl::Error finding version string in arp_warp exectuable"
    }

    check_new_refmac
}

proc arpwarp_input_check { step } {
    global XMLParse

}

proc arpwarp_reference { } {
    global XMLParse

    puts "ARP/wARP:"
    puts "<B><FONT COLOR=\"\#FF0000\"><!--SUMMARY_BEGIN-->\n"
    puts "\$TEXT:Reference: \$\$ Please reference \$\$"
    puts "Perrakis A, Morris RM & Lamzin VS (1999) Automated protein"
    puts "model building combined with iterative structure refinement."
    puts "Nature Struct. Biol. 6, 458-463)"
    puts "\$\$\n"

    # General Refmac Reference
    puts "Refmac:"
    puts "\$TEXT:Reference: \$\$ Please reference \$\$"
    puts "Murshudov GN, Skubak P, Lebedev AA, Pannu NS, Steiner RA, Nicholls RA,"
    puts "Winn MD, Long F & Vagin AA (2011) REFMAC5 for the refinement of"
    puts "macromolecular crystal structures. Acta Cryst. D67, 355-367."
    puts "\$\$\n"

    for { set i 1 } { [info exists XMLParse([join "crank soap run step=$i name" __])] } { incr i } {
	set step [string tolower $XMLParse([join "crank soap run step=$i name" __])]

	if { [string compare $step "arpwarp"] == 0 } {
	    if { ($XMLParse([join "crank soap run step=$i arpwarp phase_restrain" __]) == "SADH") ||
                 ($XMLParse([join "crank soap run step=$i arpwarp phase_restrain" __]) == "SAD") } {
		# SAD function
		puts "SAD likelihood function:"
                puts "\$TEXT:Reference: \$\$ Please reference \$\$"
		puts "Skubak P, Murshudov GN & Pannu NS (2004)"
		puts "Direct incorporation of experimental phase information in model refinement"
		puts "structure refinement.  Acta Cryst. D60, 2196-2201."
                puts "\$\$\n"
		break
            } elseif { $XMLParse([join "crank soap run step=$i arpwarp phase_restrain" __]) == "MLHL" } {
		# MLHL function
		puts "MLHL likelihood function:"
                puts "\$TEXT:Reference: \$\$ Please reference \$\$"
		puts "Pannu NS, Murshudov GN, Dodson EJ & Read RJ (1998)"
		puts "Incorporation of prior phase information strengthens maximum-likelihood"
		puts "structure refinement.  Acta Cryst. D54, 1285-1294."
                puts "\$\$\n"
		break
	    }
        }
    }
    puts "<!--SUMMARY_END--></FONT></B>\n"
}

