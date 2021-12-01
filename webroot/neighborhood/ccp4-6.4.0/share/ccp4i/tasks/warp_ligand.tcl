# ======================================================================
# warp_ligand.tcl --
#
# =======================================================================

#----------------------------------------------------------------------
proc warp_ligand_prereq {} {
#----------------------------------------------------------------------
    if { [GetEnvPath warpbin 0] == "" } {
        return 0
    } else {
        return 1
    }
}

#----------------------------------------------------------------------
proc warp_ligand_run { arrayname } {
#----------------------------------------------------------------------

# procedure run before script is written

    upvar #0 $arrayname array

# First check if version 6 is installed
#
    set arpkey "0"
#
    set out_file [GetTmpFileName ]
    catch { exec [FileJoin [GetEnvPath warpbin] arp_warp ] -v ] > $out_file}
    #
    if { [ReadFile $out_file out_text] && \
	    [ExtractTextLine $out_text  "73010312" 0 all line1 ] } {
	set arpkey [expr [lindex $line1 0] ]
    }
    
if { $arpkey != "73010312" } {
    WarningMessage "The version of ARP/wARP you have installed is NOT 7.3.0 or ARP/wARP could not be found at all. Make sure you have modified your .cshrc so as it contain the definition for warpbin and has the right path, or please get and install version 7.3.0 from http://www.arp-warp.org/"
    return 0
}
#
#
# Now check if we like the refmac version as well !
#
  set out_file [GetTmpFileName]
  catch { exec [FileJoin [GetEnvPath CBIN ] refmac5 ] -i > $out_file }
  # Initialise
  set patch_version ""
  set minor_version ""
  set major_version ""
  # Extract the information from the output of refmac5 -i
  if { [ReadFile $out_file out_text] && \
       [ExtractTextLine $out_text "refmac5" 0 all line ] } {
    if { [llength $line] < 4 } {
      WarningMessage "Cannot extract Refmac version number!"
      return 0
    }
    # This will get the version number x.y.z
    set refkey [lindex $line 3]
    set lrefkey [split $refkey .]
    if { [llength $lrefkey] > 2 } {
      set patch_version [scan [lindex $lrefkey 2] %d]
    }
    if { [llength $lrefkey] > 1 } {
      set minor_version [scan [lindex $lrefkey 1] %d]
    }
    if { [llength $lrefkey] > 0 } {
      set major_version [scan [lindex $lrefkey 0] %d]
    }
  }
#
      if { $major_version <= 5 } {
        if { $minor_version <= 1 } {
          if { $patch_version <= 18 } {
            WarningMessage "You need Refmac5 version 5.1.19 (or higher) to run ARP/wARP 7.3.0. Please install the latest CCP4 version"
            return 0
          }
        }
      }

if { [file exists [GetFullFileName1 $array(HKLIN) $array(DIR_HKLIN) ] ] } {
    set array(INPUT_FILES) " HKLIN "		
} else {
    WarningMessage "Can not open MTZ input file
    Aborting run"
    return 0
}

if { [file exists [GetFullFileName1 $array(PROTEININ) $array(DIR_PROTEININ) ] ] } {
    append array(INPUT_FILES) " PROTEININ "		
} else {
    WarningMessage "Can not open protein PDB input file
    Aborting run"
    return 0
}


if { [file exists [GetFullFileName1 $array(LIGANDIN) $array(DIR_LIGANDIN) ] ] } {
    append array(INPUT_FILES) " LIGANDIN "		
} else {
    WarningMessage "Can not open ligand PDB input file
    Aborting run"
    return 0
}

if { [regexp PRIORBUILD [GetValue $arrayname LIGAND_FIND_MODE] ] } { \
    if { [file exists [GetFullFileName1 $array(LIGANDREF) $array(DIR_LIGANDREF) ] ] } {
	append array(INPUT_FILES) " PROTEININ "		
    } else {
	WarningMessage "Can not open previous ligand reference PDB input file
        Aborting run"
	return 0
    }
}

if { $array(TOGGLE_TEST) } {
    if { [file exists [GetFullFileName1 $array(LIGANDTEST) $array(DIR_LIGANDTEST) ] ] } {
	append array(INPUT_FILES) " LIGANDTEST "		
    } else {
	WarningMessage "Can not open ligand PDB input file
        Aborting run"
	return 0
    }
}

if { $array(FP) == "Unassigned" || $array(FP) == "" } {
    WarningMessage "FP is not assigned to an mtz label
    Aborting run"
    return 0
}

if { $array(SIGFP) == "Unassigned" || $array(SIGFP) == "" } {
    WarningMessage "SIGFP is not assigned to an mtz label
    Aborting run"
    return 0
}  

combine_wilson_xyz $arrayname

if { $array(LIBINSHOW) == "0" } {
    set array(EXTRA_LIBRARY) ""
    set array(DIR_EXTRA_LIBRARY) ""
}

if { [regexp Y [GetValue $arrayname EXCLUDE_FREER] ] && \
	$array(FREE) == "Unassigned" } {
    WarningMessage "
    FreeRflag is not assigned to an mtz label
    Please assign FreeRflag in Refmac Parameters panel
    Aborting run"
    return 0
}

#
    if { [regexp AUTO [GetValue $arrayname WEIGHT_MODE] ]  } {
	set array(WEIGHT) "AUTO"
	set array(WEIGHTVAL) " " 
    } else {
	set array(WEIGHT) "MATRIX"
	set array(WEIGHTVAL) "$array(WMAT)"
    }
#
#
set njob [expr [DbGetJobData ""  NJOBS] +1 ]
set workdir [GetDefaultDirPath]
#
# Here we set parameters to be written out to warp.par file style ...
#

set array(XYZLIM) "$array(XYZLIM_1) $array(XYZLIM_2) $array(XYZLIM_3)\
	$array(XYZLIM_4) $array(XYZLIM_5) $array(XYZLIM_6) " 

set array(DAMP) "$array(DAMP_P) $array(DAMP_B) "

set array(RESOL) "$array(EXCLUDE_RESOLUTION_MIN) $array(EXCLUDE_RESOLUTION_MAX) "

if { [regexp Y [GetValue $arrayname EXCLUDE_FREER] ]  } {
    set array(FREELABIN) "FREE=$array(FREE)"
} else {
    set array(FREELABIN) " "
}


if { [regexp AUBUILD [GetValue $arrayname LIGAND_FIND_MODE] ] } {
    set array(KNOWNLIGPOS) 0
    set array(LIGANDREF) " "
    set array(DIR_LIGANDREF) " "
    set array(LIGRAD) " "
    set array(LIGXYZ) " "
}
    
if { [regexp PRIORBUILD [GetValue $arrayname LIGAND_FIND_MODE] ] } {
    set array(KNOWNLIGPOS) 2
    set array(LIGRAD) " "
    set array(LIGXYZ) " "
}

if { [regexp XYZBUILD [GetValue $arrayname LIGAND_FIND_MODE] ] } {
    set array(KNOWNLIGPOS) 1
    set array(LIGANDREF) " "
    set array(DIR_LIGANDREF) " "
    set array(LIGXYZ) " $array(XLIG) $array(YLIG) $array(ZLIG) "
}


if { [regexp Y [GetValue $arrayname REFMAC_REF_SET] ]  } {
    set array(SCALML) "SCAL MLSC FREE"
} else {
	set array(SCALML) "SCAL MLSC "
}

# Only use the value of NPARTIAL if we are doing partial ligand building
if { ! $array(TOGGLE_PARTIAL) } {
    set array(NPARTIAL) 0
}

set array(RESOL) " $array(EXCLUDE_RESOLUTION_MIN) $array(EXCLUDE_RESOLUTION_MAX) "


return 1

}

#--------------------------------------------------------------------
proc warp_ligand_setup { typedefVar arrayname } {
#--------------------------------------------------------------------

upvar #0  $typedefVar typedef
global env

    # Confirm that the user has sourced the arpwarp setup script
    if { [info exists env(warpbin)] == 0 } {
        WarningMessage "Please check your shell startup file does source ARP/wARP 7.3. Then open another terminal window and re-launch CCP4i."
        return 0
    }

set typedef(_ligand_find_mode) { 
    menu   
    {       
	"in the most likely place of the complete asymmetric unit"
	"around the same approximate place as a previous ligand"
	"around an approximate XYZ position"
    }
    {
	AUBUILD
	PRIORBUILD
	XYZBUILD
}   }


set typedef(_ref_mode) { 
    menu   
    {       
	"Fast"
	"Slow"
    }
    {
	REFFAST
	REFSLOW
}   }

set typedef(_weight_mode) { 
    menu   
    {       
	"Automatic"
	"Manual"
    }
    {
	AUTO
	MANUAL
}   }


set typedef(_refmac_ref_set) { 
    menu     
    {       
	"working"
	"free" 
    }
    {   
	N
	Y 
}   }

set typedef(_exclude_freer) { 
    menu     
    {       
	"not use"
	"use" 
    }
    {   
	N
	Y
}   }

set typedef(_scale) { 
    menu     
    {       
	"BULK"
	"SIMPLE" 
    }
    {   
	BULK
	SIMPLE
}   }

set typedef(_scanis) { 
    menu     
    {       
	"isotropic"
	"anisotropic" 
    }
    {   
	N
	Y
}   }



  return 1
}

#--------------------------------------------------------------------
proc refmac_scale { arrayname }  {

  upvar #0 $arrayname array

    set checkflag [GetValue $arrayname EXCLUDE_FREER]

    if { [regexp Y $checkflag]  } {
	SetValue $arrayname REFMAC_REF_SET Y
    } else {
	SetValue $arrayname REFMAC_REF_SET N
    }
}




#--------------------------------------------------------------------
proc set_refmac_protocole { arrayname } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array

    if { $array(EXCLUDE_RESOLUTION_MAX) > 2.0 } {
	SetValue $arrayname REF_MODE REFSLOW
	set array(NCYCLES) 3
	set array(DAMP_P) 0.4
	set array(DAMP_B) 0.4
	SetValue $arrayname PHASE_RESTRAIN N
    }


}

#--------------------------------------------------------------------
proc arp_get_assym { arrayname } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array

  set space_group  [GetSpaceGroupNumber $array(SPACE_GROUP)] 

  PleaseWait "Finding ARP/wARP asymmetric unit"

  set tmp_file [GetTmpFileName]
  OpenFile $tmp_file f w
  puts $f "MODE UPDATE ALLATOMS \nSYMM $space_group  \nend"
  CloseFile $f
  set out_file [GetTmpFileName ]

  catch "exec [FileJoin [GetEnvPath warpbin] arp_warp] < $tmp_file > $out_file"
  if { [ReadFile $out_file out_text] && \
	  [ExtractTextLine $out_text  "Asymmetric unit" 0 all line  ] } {
    eval "set lim2 \[ expr double([lindex $line 3]) / double([lindex $line 5]) \]"
    eval "set lim4 \[ expr double([lindex $line 6]) / double([lindex $line 8]) \]"
    eval "set lim6 \[ expr double([lindex $line 9]) / double([lindex $line 11])\]"

    set array(XYZLIM_1) 0.0
    set array(XYZLIM_3) 0.0
    set array(XYZLIM_5) 0.0
    set array(XYZLIM_2) [maxdecimal $lim2 4]
    set array(XYZLIM_4) [maxdecimal $lim4 4]
    set array(XYZLIM_6) [maxdecimal $lim6 4]
} else {
    WarningMessage "Cannot extract ARP/wARP asymmetric unit limits \nThe job will fail if run"
  }

  PleaseWait
}

#--------------------------------------------------------------------
    proc combine_wilson_xyz { arrayname } {

	arp_get_assym $arrayname
	get_wilson $arrayname
    }


#--------------------------------------------------------------------
proc get_wilson { arrayname } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array

  set fobs $array(FP)
  set sig $array(SIGFP)
  set rexcl $array(EXCLUDE_RESOLUTION)
  set rmin $array(EXCLUDE_RESOLUTION_MIN)
  set rmax $array(EXCLUDE_RESOLUTION_MAX)
  set mtzfile [GetFullFileName0 $arrayname HKLIN]    
  set pdbfile [GetFullFileName0 $arrayname PROTEININ]    

# Dont' try to do the calcualtion if any of the required parameters are undefined
  if { $fobs == "" || $fobs == "Unassigned" || \
       $sig == "" || $sig == "Unassigned"  || \
       ![file exists $pdbfile] || ![file exists $mtzfile] } { return }

# Don't repeat the calculation if has been done already with same parameters
  if { $array(WILSON_B) != "" && [ElementExists $arrayname WILSON_PARAMS] && \
     [StringSame $fobs [lindex $array(WILSON_PARAMS) 0]] && \
     [StringSame $sig  [lindex $array(WILSON_PARAMS) 1]] && \
     [StringSame $rexcl [lindex $array(WILSON_PARAMS) 2]] && \
     [StringSame $rmin [lindex $array(WILSON_PARAMS) 3]] && \
     [StringSame $rmax [lindex $array(WILSON_PARAMS) 4]] && \
     [StringSame $pdbfile [lindex $array(WILSON_PARAMS) 5]] && \
     [StringSame $mtzfile [lindex $array(WILSON_PARAMS) 6]] } {  return }
  
  PleaseWait "Calculating Wilson B, solvent content and number of atoms"
       
  set tmp_file [GetTmpFileName]
  OpenFile $tmp_file f w

  puts $f "MODE WILSON NRES 99\nFILES CCP4 HKLIN=$mtzfile XYZIN=$pdbfile\nLABELS FP=$fobs SIGFP=$sig FUSE=$fobs \nRESO $array(EXCLUDE_RESOLUTION_MIN) $array(EXCLUDE_RESOLUTION_MAX)\nend"

  CloseFile $f

  set out_file [GetTmpFileName ]

  catch "exec [FileJoin [GetEnvPath warpbin] arp_warp] < $tmp_file > $out_file"

#  puts "out_file $out_file"
# Want to grab wilson b from here ....

  if { [ReadFile $out_file out_text] && \
       [ExtractTextLine $out_text  "Bfactor" 0 all line1  ] } {
    set wilsonb [expr [lindex $line1 3] ]

    set array(WILSON_B) [maxdecimal $wilsonb 2]

}

  if { [ReadFile $out_file out_text] && \
       [ExtractTextLine $out_text  "Solvent content" 0 all line2  ] } {
    set solventc [expr [lindex $line2 2]  ]

    set array(SOLVENTC) [maxdecimal $solventc 2 ]
  }

    set array(WILSON_PARAMS) [list $fobs $sig $rexcl $rmin $rmax $pdbfile $mtzfile]
#    check_input $arrayname WILSON_PARAMS

  PleaseWait

}


#--------------------------------------------------------------------
proc set_ref_protocol { arrayname }  {
#--------------------------------------------------------------------

    upvar #0 $arrayname array
 
    case [GetValue $arrayname REF_MODE] \
	    REFFAST {
	set array(NCYCLES) 1
	SetValue $arrayname PHASE_RESTRAIN N
    } REFSLOW {
	set array(NCYCLES) 3
	SetValue $arrayname PHASE_RESTRAIN N
    }

}


#--------------------------------------------------------------------
proc warp_ligand_task_window { arrayname } {
#--------------------------------------------------------------------

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
        "ARP/wARP Version 7.3.0: Ligand Build" "ARP/wARP Ligand Building interface" \
	    [ list "Parameters"\
        "Refmac parameters"\
        "Crystal parameters"\
        "Test and comparison parameters"  ] ] == 0 } return 

  set help_source [file join [GetEnvPath warpdoc] ligand.htm ]
  SetProgramHelpFile $help_source


#=PROTOCOL==============================================================

  OpenFolder protocol

  CreateTitleLine line TITLE
   set arplogo [image create photo -file [ FileJoin [GetEnvPath warpbin] ARP_logo_small.gif ] ]
   set logo [label $line.log -image $arplogo]
   pack $logo

  CreateLine line \
    label "Build the ligand " \
    message "Choose if you want to check for ligand everywhere or on predefined places " \
    widget LIGAND_FIND_MODE \


#=Toggle folder depending on mode ====================================================


  OpenFolder file 


    CreateInputFileLine line \
      "Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
       HKLIN DIR_HKLIN \
       -setlabin FREE [list FREE FreeR FreeR_flag] \
       -setfileparam space_group_name SPACE_GROUP \
        -setfileparam resolution_min EXCLUDE_RESOLUTION_MIN \
        -setfileparam resolution_max EXCLUDE_RESOLUTION_MAX \
        -setfileparam resolution_max DATA_RESOLUTION \
        -setfileparam cell_1 CELL_1 \
        -setfileparam cell_2 CELL_2 \
        -setfileparam cell_3 CELL_3 \
        -setfileparam cell_4 CELL_4 \
        -setfileparam cell_5 CELL_5 \
        -setfileparam cell_6 CELL_6 \
        -command "combine_wilson_xyz $arrayname" 

  CreateLabinLine line \
    "Choose Fobs amplitude (Fobs) and sigma (Sigma)" HKLIN \
      "Fobs    " FP  [list FP F_P F ] \
     -command "get_wilson $arrayname" \
     -sigma "Sigma  " SIGFP [list SIGFP SIGF_P SIGF ]

  CreateInputFileLine line \
      "Enter name of file containing molecule coordinates" \
      "Protein model without ligand " \
       PROTEININ DIR_PROTEININ \
      -command "get_wilson $arrayname" 
 
  CreateInputFileLine line \
      "Enter name of file containing ligand coordinates" \
      "Ligand molecule coordinates " \
      LIGANDIN DIR_LIGANDIN \
       -fileout LIGANDOUT DIR_LIGANDOUT "_fitted_" 

  OpenSubFrame frame -toggle_display LIGAND_FIND_MODE open PRIORBUILD
  CreateInputFileLine line \
      "PDB file to use for the place of the previous ligand" \
      "Previous ligand coordinates  " \
      LIGANDREF DIR_LIGANDREF
  CloseSubFrame


  CreateOutputFileLine line \
      "Enter name of file for fitted ligand coordinates" \
      "Ligand output file " \
       LIGANDOUT DIR_LIGANDOUT  

  OpenSubFrame frame -toggle_display LIBINSHOW open 1 closed
  CreateInputFileLine line \
    "Enter user defined geometry library" \
    "User Library" \
    EXTRA_LIBRARY DIR_EXTRA_LIBRARY 
  CloseSubFrame




#=PARAMETERS==========================================================

  OpenFolder 1 open
#
  CreateLine line \
    label "Use with REFMAC5 the" \
    message "Fast/Slow protocoles: 1/3 internal refmac cycle(s), 1.0/0.4 damps on fractional shifts. " \
    widget REF_MODE \
    -command "set_ref_protocol $arrayname"\
    label " protocol and do "\
    message "Include or exclude the reflections flagged for Free R" \
    widget EXCLUDE_FREER \
    -command "refmac_scale $arrayname"\
    label " the Free R flag"

CreateLine line \
      label "Search for ligand around X" \
      message "Define approximate position and radius to look for new ligand" \
      widget XLIG \
      label "Y" \
      widget YLIG \
      label "Z" \
      widget ZLIG \
      label ", in a radius of " \
      widget LIGRAD \
      toggle_display LIGAND_FIND_MODE open XYZBUILD

CreateLine line \
      widget LIGCYCLES \
      -width 2 \
      label "Ligand building cycles " \
      message "Iterate ligand building to create more likely solutions" 

CreateLine line \
    message "If the ligand is present but parts are missing due to disorder" \
    widget TOGGLE_PARTIAL \
    label "Assume partial occupancy of ligand"

OpenSubFrame frame -toggle_display TOGGLE_PARTIAL open 1 closed
  CreateLine line \
      widget NPARTIAL \
      -width 2 \
      label "Minimum number of atoms present in partially occupied ligands " \
      message "Minimum number of atoms present in partially occupied ligands" 
  CloseSubFrame

CreateLine line \
    message "Do not remove waters before calculating difference map" \
    widget KEEP_WATERS \
    label "Keep waters"

#------------------------------------------------------


OpenFolder 2 closed


CreateLine line \
        message "Number of cycles of refinement for Refmac run" \
        widget NCYCLES \
        -width 2 \
        label "cycles of refinement with Refmac."

CreateLine line \
        message "Manual or automatic weighting for Xray/geometry terms" \
        widget WEIGHT_MODE \
        label "matrix weighting for Xray / Geometry "

CreateLine line \
        message "The relative matrix weight for xray versus geometrical terms ?" \
        label "Matrix weight for Xray / Geometry " \
        widget WMAT \
        toggle_display WEIGHT_MODE hide AUTO

CreateLine line \
        label "Data with free R label "  \
        message "Label of data in input MTZ file (LABIN FREE)" \
        widget FREE \
        label " are excluded from refinement."  \
        toggle_display EXCLUDE_FREER hide N

CreateLine line \
        message "Determines if Rfree reflections will be used in scaling and sigmaa calculations" \
        label "For scaling and sigmaa calculations use the" \
        widget REFMAC_REF_SET \
        toggle_display EXCLUDE_FREER hide N  \
        label "set of reflections."

CreateLine line \
        message "User defined library with new monomer definitions" \
        widget LIBINSHOW \
        label "Input a user-defined library file." 



#------------------------------------------------------

OpenFolder 3  closed

  CreateLine line \
    message "Space group (default as in MTZ file) (SYMMETRY)" \
    label "Generate map in space group" \
    help symmetry \
    varlabel SPACE_GROUP

  CreateLine line \
    message "Cell dimensions (default taken from MTZ file" \
    help cell \
    label "Cell a="   \
    varlabel CELL_1 \
    label "b=" \
    varlabel CELL_2 \
    label "c=" \
    varlabel CELL_3 \
    label "alpha=" \
    varlabel CELL_4 \
    label "beta=" \
    varlabel CELL_5 \
    label "gamma=" \
    varlabel CELL_6

  CreateLine line \
    message "ARP/wARP asymmetric unit limits (derived when you select MTZ)" \
    label "ARP/wARP asymmetric unit" \
    varlabel XYZLIM_1 \
    varlabel XYZLIM_2 \
    varlabel XYZLIM_3 \
    varlabel XYZLIM_4 \
    varlabel XYZLIM_5 \
    varlabel XYZLIM_6

  CreateLine line \
    message "Wilson B factor and solvent content (derived when you select MTZ)" \
    label "Wilson B factor" \
    varlabel WILSON_B  \
    label "  Solvent content" \
    varlabel SOLVENTC  


  CreateLine line \
    message "Refine with reflections below and/or above resolution limit in \
                  Angstrom (RESOLUTION)" \
    help resolution \
    widget EXCLUDE_RESOLUTION \
    label "Use reflections between" \
    widget EXCLUDE_RESOLUTION_MIN \
    label "and" \
    widget EXCLUDE_RESOLUTION_MAX \
    -command "get_wilson $arrayname" \
    label "Angstrom" 
   
CloseSubFrame


#------------------------------------------------------

OpenFolder 4 closed

  CreateLine line \
    message "Compare with an already fitted ligand for validation or testing" \
    widget TOGGLE_TEST \
    label "Compare with an already fitted ligand for validation or testing"

  OpenSubFrame frame -toggle_display TOGGLE_TEST open 1 closed
  CreateInputFileLine line \
    "Enter name of file containing ligand coordinates" \
    "Correctly fitted ligand for test " \
      LIGANDTEST DIR_LIGANDTEST 
  CloseSubFrame

CloseSubFrame

#------------------------------------------------------

}
