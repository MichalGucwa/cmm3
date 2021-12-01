
proc AllPhaseCompare { crankplugins step tag keep_mtz no_trans } {
    global XMLParse
    
    for { set istep 1 } { [info exists XMLParse(crank__soap__run__step=$istep)] } { incr istep } {
	if { [info exists XMLParse([join "crank soap run step=$istep name" __])] } {

	    if { ( ($XMLParse([join "crank soap run step=$istep name" __]) == "BP3")    || 
		   ($XMLParse([join "crank soap run step=$istep name" __]) == "REFMAC") || 
	           ($XMLParse([join "crank soap run step=$istep name" __]) == "SHARP")  ||
		   ($XMLParse([join "crank soap run step=$istep name" __]) == "SHELXE")    ) } {
		set phasingstep $istep
		set phasingtag [string trim $XMLParse([join "crank soap run step=$istep tag" __])]
	    }

	    if { ($XMLParse([join "crank soap run step=$istep name" __]) == "SOLOMON") 
			 && ($XMLParse([join "crank soap run step=$istep solomon density_modify" __]) == 1 )
		  } {
		set solstep $istep
		set soltag [string trim $XMLParse([join "crank soap run step=$istep tag" __])]
	    }

	    if { ( ($XMLParse([join "crank soap run step=$istep name" __]) == "DM") ||
		   ($XMLParse([join "crank soap run step=$istep name" __]) == "PARROT") ||
           ($XMLParse([join "crank soap run step=$istep name" __]) == "RESOLVEDM") ||
		   ($XMLParse([join "crank soap run step=$istep name" __]) == "PIRATE")   ) 
	     } {
		set dmstep $istep
		set dmtag [string trim $XMLParse([join "crank soap run step=$istep tag" __])]
	    }

	}
    }

    if { ([info exists phasingtag] && [file exists final.mtz]) } {
	runcommand [concat tclsh [file join $crankplugins check phasecompare.tcl] "final.mtz" "FC" "PHIC" [file join .. workdb crank.out.$phasingtag.mtz] "${phasingtag}_F" "${phasingtag}_SIGF" "${phasingtag}_PHIB" "${phasingtag}_FOM" "phasing" $no_trans] 0
	runcommand [concat sh cphasematch-phasing.com] 0
	runcommand [concat tclsh [file join $crankplugins check phasecompare-sftools.tcl] "final.mtz" "FC" "PHIC" [file join .. workdb crank.out.$phasingtag.mtz] "${phasingtag}_F"  "${phasingtag}_PHIB" "${phasingtag}_FOM" "phasing"] 0
	if { $keep_mtz } {
	    file copy temp.mtz phasing.mtz
	}
	file delete temp.mtz
    }

    if { ([info exists phasingtag] && [file exists final.mtz] && [file exists [file join .. workdb crank.out.$phasingtag.oh.mtz]] ) } {
	runcommand [concat tclsh [file join $crankplugins check phasecompare.tcl] "final.mtz" "FC" "PHIC" [file join .. workdb crank.out.$phasingtag.oh.mtz] "${phasingtag}_F" "${phasingtag}_SIGF" "${phasingtag}_PHIB" "${phasingtag}_FOM" "phasing-oh" $no_trans] 0
	runcommand [concat sh cphasematch-phasing-oh.com] 0
	runcommand [concat tclsh [file join $crankplugins check phasecompare-sftools.tcl] "final.mtz" "FC" "PHIC" [file join .. workdb crank.out.$phasingtag.oh.mtz] "${phasingtag}_F" "${phasingtag}_PHIB" "${phasingtag}_FOM" "phasing-oh"] 0
	if { $keep_mtz } {
	    file copy temp.mtz phasing-oh.mtz
	}
	file delete temp.mtz
    }

    if { ([info exists soltag] && [file exists final.mtz]) } {
 	runcommand [concat tclsh [file join $crankplugins check phasecompare.tcl] "final.mtz" "FC" "PHIC" [file join .. workdb crank.out.$soltag.mtz] "${soltag}_F" "${soltag}_SIGF" "${soltag}_PHIB" "${soltag}_FOM" "solomon" $no_trans] 0
	runcommand [concat sh cphasematch-solomon.com] 0
 	runcommand [concat tclsh [file join $crankplugins check phasecompare-sftools.tcl] "final.mtz" "FC" "PHIC" [file join .. workdb crank.out.$soltag.mtz] "${soltag}_F" "${soltag}_PHIB" "${soltag}_FOM" "solomon"] 0
	if { $keep_mtz } {
	    file copy temp.mtz solomon.mtz
	}
	file delete temp.mtz
    }

    if { ([info exists dmtag] && [file exists final.mtz]) } {
 	runcommand [concat tclsh [file join $crankplugins check phasecompare.tcl] "final.mtz" "FC" "PHIC" [file join .. workdb crank.out.$dmtag.mtz] "${dmtag}_F" "${dmtag}_SIGF" "${dmtag}_PHIB" "${dmtag}_FOM" "denmod" $no_trans] 0
	runcommand [concat sh cphasematch-denmod.com] 0
 	runcommand [concat tclsh [file join $crankplugins check phasecompare-sftools.tcl] "final.mtz" "FC" "PHIC" [file join .. workdb crank.out.$dmtag.mtz] "${dmtag}_F" "${dmtag}_PHIB" "${dmtag}_FOM" "denmod"] 0
	if { $keep_mtz } {
	    file copy temp.mtz denmod.mtz
	}
	file delete temp.mtz
    }

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
    
    if { $inphases && [file exists final.mtz] } {


        runcommand [concat tclsh [file join $crankplugins check phasecompare.tcl] "final.mtz" "FC" "PHIC" [file join .. workdb crank.in.$tag.mtz] $in_f $in_sigf $in_phib $in_fom "final" $no_trans] 0
        runcommand [concat sh cphasematch-final.com] 0
        runcommand [concat tclsh [file join $crankplugins check phasecompare-sftools.tcl] "final.mtz" "FC" "PHIC" [file join .. workdb crank.in.$tag.mtz] $in_f $in_phib $in_fom "final"] 0

	if { $keep_mtz } {
	    file copy temp.mtz cfinal.mtz
 	}

        file delete temp.mtz
    }	
}

set inputxml     [lindex $argv 0]
set crankbin     [lindex $argv 1]
set crankplugins [lindex $argv 2]
set step         [lindex $argv 3]
set tag          [lindex $argv 4]
set keep_mtz     [lindex $argv 5]
set no_trans     [lindex $argv 6]


source [file join $crankbin crankutils.tcl]

if { [file exists $inputxml] == 0 } {
    crank_error "allphasecompare.tcl::inputxml file does not exist"
}

XMLParsefile $inputxml

AllPhaseCompare $crankplugins $step $tag $keep_mtz $no_trans
