# ======================================================================
# arp_solvent.tcl --
#
# =======================================================================

#----------------------------------------------------------------------
proc arp_solvent_prereq {} {
#----------------------------------------------------------------------
    if { [GetEnvPath warpbin 0] == "" } {
        return 0
    } else {
        return 1
    }
}

#----------------------------------------------------------------------
proc arp_solvent_run { arrayname } {
#----------------------------------------------------------------------

# procedure run before script is written

    upvar #0 $arrayname array

# First check the version
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

    
if { [file exists [GetFullFileName1 $array(HKLIN) $array(DIR_HKLIN) ] ] } {
    set array(INPUT_FILES) " HKLIN "		
} else {
    WarningMessage "Can not open MTZ input file." -button Cancel
    return 0
}


if { [file exists [GetFullFileName1 $array(XYZIN) $array(DIR_XYZIN) ] ] } {
    append array(INPUT_FILES) " XYZIN "		
} else {
    WarningMessage "Can not open PDB input file." -button Cancel
    return 0
}

    set array(OUTPUT_FILES) " XYZOUT "		

if { $array(LIBINSHOW) == "1" } { 
    if { [file exists [GetFullFileName1 $array(EXTRA_LIBRARY) $array(DIR_EXTRA_LIBRARY) ] ] } {
	append array(INPUT_FILES) " EXTRA_LIBRARY "	
    } else {
	WarningMessage "Can not open user supplied library input file." -button Cancel
	return 0
    }
} else {
    set array(EXTRA_LIBRARY) ""
    set array(DIR_EXTRA_LIBRARY) ""
}

if { $array(TLSONOFF) == "0" } {
    set array(TLSIN) ""
    set array(DIR_TLSIN) ""
}

if { $array(FP) == "Unassigned" || $array(FP) == "" } {
    WarningMessage "FP is not assigned to an mtz label." -button Cancel
    return 0
}

if { $array(SIGFP) == "Unassigned" || $array(SIGFP) == "" } {
    WarningMessage "SIGFP is not assigned to an mtz label." -button Cancel
    return 0
}  

if { [regexp Y [GetValue $arrayname EXCLUDE_FREER] ] && \
	 $array(FREE) == "Unassigned" } {
    WarningMessage "FreeRflag is not assigned to an mtz label. Please assign FreeRflag in Refmac Parameters panel." -button Cancel
    return 0
} 
#else {
#    set array(FREE) ""
#}

#
set njob [expr [DbGetJobData ""  NJOBS] +1 ]
set workdir [GetDefaultDirPath]
#
# Here we set parameters to be written out to warp.par file style ...
#  On 08.03.2010 VL changed   set array(FREELABIN) "FREE=$array(FREE)"
#                   to        set array(FREELABIN) "$array(FREE)"
#
set array(XYZLIM) "$array(XYZLIM_1) $array(XYZLIM_2) $array(XYZLIM_3)\
	$array(XYZLIM_4) $array(XYZLIM_5) $array(XYZLIM_6) " 
#
if { [regexp Y [GetValue $arrayname EXCLUDE_FREER] ]  } {
    set array(FREELABIN) "$array(FREE)"
}
#
if { [regexp AUTO [GetValue $arrayname WEIGHT_MODE] ]  } {
	set array(WEIGHT) "AUTO"
	set array(WEIGHTVAL) "AUTO" 
} else {
	set array(WEIGHT) "MATRIX"
	set array(WEIGHTVAL) "$array(WMAT)"
}

set array(RESOL) " $array(EXCLUDE_RESOLUTION_MIN) $array(EXCLUDE_RESOLUTION_MAX) "

set array(SCALEOPT) "$array(SCALE)"
if { [regexp Y [GetValue $arrayname SCANIS] ]  } {
    append array(SCALEOPT) " LSSC ANIS"
}

return 1

}

#--------------------------------------------------------------------
proc arp_solvent_setup { typedefVar arrayname } {
#--------------------------------------------------------------------

upvar #0  $typedefVar typedef
global env

    # Confirm that the user has sourced the arpwarp setup script
    if { [info exists env(warpbin)] == 0 } {
        WarningMessage "Please check your shell startup file does source ARP/wARP 7.3. Then open another terminal window and re-launch CCP4i."
        return 0
    }

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
proc set_wmat { arrayname } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array

    set currentmode [GetValue $arrayname ARP_MODE]

    if { $array(EXCLUDE_RESOLUTION_MAX) > 0.11 } {
	set array(WMAT) 2.5
    }

    if { $array(EXCLUDE_RESOLUTION_MAX) > 1.11 } {
	set array(WMAT) 1.2
    }

    if { $array(EXCLUDE_RESOLUTION_MAX) > 1.41 } {
	set array(WMAT) 0.7
    }

    if { $array(EXCLUDE_RESOLUTION_MAX) > 1.71 } {
	set array(WMAT) 0.5
    }

    if { $array(EXCLUDE_RESOLUTION_MAX) > 2.01 } {
	set array(WMAT) 0.3
    }

    if { $array(EXCLUDE_RESOLUTION_MIN) > 20.0} {
	set array(EXCLUDE_RESOLUTION_MIN) 20.0
    }

    SetValue $arrayname WEIGHT_MODE AUTO  

    set restemp [ expr $array(EXCLUDE_RESOLUTION_MAX) - 2.8 ]
    set restemp2 [ expr $restemp * $restemp ]
    set restemp3 [ expr 0.6 * ( 1 + $restemp2) ]

    if { $array(EXCLUDE_RESOLUTION_MAX) > 2.00 } {
	set array(REMATOM_SIGMA) [maxdecimal $restemp3 2]
    }

    if { $array(EXCLUDE_RESOLUTION_MAX) > 2.80 } {
	set array(REMATOM_SIGMA) 0.6
    }

}

#--------------------------------------------------------------------
proc arp_get_assym { arrayname } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array

  set space_group  [GetSpaceGroupNumber $array(SPACE_GROUP)] 

#  puts $space_group

  PleaseWait "Finding ARP/wARP asymmetric unit"

  set_wmat $arrayname
  
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

	get_wilson $arrayname
	arp_get_assym $arrayname
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
proc get_wilson { arrayname } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array

  set fobs $array(FP)
  set sig $array(SIGFP)
  set rexcl $array(EXCLUDE_RESOLUTION)
  set rmin $array(EXCLUDE_RESOLUTION_MIN)
  set rmax $array(EXCLUDE_RESOLUTION_MAX)
  set mtzfile [GetFullFileName0 $arrayname HKLIN]    
  set pdbfile [GetFullFileName0 $arrayname XYZIN]    

  set residues 99
  if {![file exists $pdbfile] } {return}

# Dont' try to do the calcualtion if any of the required parameters are undefined
  if { $fobs == "" || $fobs == "Unassigned" || \
       $sig == "" || $sig == "Unassigned" || \
       $residues == "" || \
       ![file exists $mtzfile] } { return }

# Don't repeat the calculation if has been done already with same parameters
  if { $array(WILSON_B) != "" && [ElementExists $arrayname WILSON_PARAMS] && \
     [StringSame $fobs [lindex $array(WILSON_PARAMS) 0]] && \
     [StringSame $sig  [lindex $array(WILSON_PARAMS) 1]] && \
     [StringSame $residues [lindex $array(WILSON_PARAMS) 2]] && \
     [StringSame $rexcl [lindex $array(WILSON_PARAMS) 3]] && \
     [StringSame $rmin [lindex $array(WILSON_PARAMS) 4]] && \
     [StringSame $rmax [lindex $array(WILSON_PARAMS) 5]] && \
     [StringSame $pdbfile [lindex $array(WILSON_PARAMS) 6]] && \
     [StringSame $mtzfile [lindex $array(WILSON_PARAMS) 7]] } {  return }
  
  PleaseWait "Calculating Wilson B, solvent content and number of atoms"
       
  set tmp_file [GetTmpFileName]
  OpenFile $tmp_file f w

  puts $f "MODE WILSON NRES $residues\nFILES CCP4 HKLIN=$mtzfile XYZIN=$pdbfile\nLABELS FP=$fobs SIGFP=$sig FUSE=$fobs \nRESO $array(EXCLUDE_RESOLUTION_MIN) $array(EXCLUDE_RESOLUTION_MAX)\nend"

  CloseFile $f

  set out_file [GetTmpFileName ]

  catch "exec [FileJoin [GetEnvPath warpbin] arp_warp] < $tmp_file > $out_file"

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

    set array(WILSON_PARAMS) [list $fobs $sig $residues $rexcl $rmin $rmax $pdbfile $mtzfile]
#    check_input $arrayname WILSON_PARAMS

  PleaseWait

}

#--------------------------------------------------------------------
proc arp_solvent_task_window { arrayname } {
#--------------------------------------------------------------------

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
        "ARP/wARP Version 7.3.0: Solvent Building" "ARP/wARP" \
        [ list "Required parameters"\
        "ARP/wARP flow parameters " \
        "Refmac parameters"\
        "Crystal parameters"  ] ] == 0 } return 

  set help_source [file join [GetEnvPath warpdoc] solvent.htm ]
  SetProgramHelpFile $help_source


#=PROTOCOL==============================================================

  OpenFolder protocol

  CreateTitleLine line TITLE
   set arplogo [image create photo -file [ FileJoin [GetEnvPath warpbin] ARP_logo_small.gif ] ]
   set logo [label $line.log -image $arplogo]
   pack $logo

#=Toggle folder depending on mode ====================================================

  OpenFolder file 

  OpenSubFrame frame -toggle_display ARP_MODE open { WARPNTRACEMODEL WARPNTRACEPHASES MOLREP SOLVENT QUICKTRACE }
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
        "Fobs    " FP  {} \
     -command "get_wilson $arrayname" \
     -sigma "Sigma  " SIGFP  {} 
  CloseSubFrame

  CreateInputFileLine line \
      "Enter name of file containing molecule coordinates (XYZIN)" \
      "Starting model in " \
      XYZIN DIR_XYZIN \
      -command "get_wilson $arrayname" \
      -fileout XYZOUT DIR_XYZOUT "_warp_solvent_" 

  OpenSubFrame frame -toggle_display TLSONOFF open 1 closed
  CreateInputFileLine line \
    "Enter user defined TLS definitions" \
    "TLS file" \
    TLSIN DIR_TLSIN 
  CloseSubFrame

  OpenSubFrame frame -toggle_display LIBINSHOW open 1 closed
  CreateInputFileLine line \
    "Enter user defined geometry library" \
    "User Library" \
    EXTRA_LIBRARY DIR_EXTRA_LIBRARY 
  CloseSubFrame

 CreateOutputFileLine line \
      "Enter name of output file with solvent milecules" \
      "Output model " \
       XYZOUT DIR_XYZOUT  

#=PARAMETERS==========================================================

  OpenFolder 1 ARP_MODE open 
#
  CreateLine line \
    message "The number of ARP/wARP refinement cycles that will be performed " \
    label "Do" \
    widget SMALL_CYCLES -oblig \
    -width 3 \
    label "ARP/REFMAC refinement cycles of the model." 

  CreateLine line \
    label "For REFMAC5 refinement do"\
    message "Include or exclude the reflections flagged for Free R" \
    widget EXCLUDE_FREER \
    -command "refmac_scale $arrayname"\
    label " the Free R flag"

CreateLine line \
        label "Determines the free R label for reflections to be excluded from refinement"  \
        message "Label for the free set of data in input MTZ file" \
        widget FREE \
        toggle_display EXCLUDE_FREER hide N

#------------------------------------------------------

OpenFolder 2 ARP_MODE closed 
  
  CreateLine line \
    message "The density levels, in sigmas' for addition and deletion of model atoms" \
    label "Add atoms in density above" \
    widget ADDATOM_SIGMA \
    label "sigma, and remove atoms in density below" \
    widget REMATOM_SIGMA \
    label "sigma."

  CreateLine line \
    message "You might want skip the Wilson statistics warning if you are fed up with them ..." \
    widget CHECK_WILSON \
    label "Disable Wilson plot statistics checks." 

#------------------------------------------------------

OpenFolder 3 closed

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
        message "Tronrud-like scaling (BULK) or a simple scaling factor"\
        label "Use for scaling the "\
        widget SCALE \
        label "scaling model, with an "\
        message "Use anisotropic scaling factors or isotropic ones"\
        widget SCANIS \
        label "scaling B factor."
#
#CreateLine line \
#        label "Determines the free R label for reflections to be excluded from refinement"  \
#        message "Label for the free set of data in input MTZ file" \
#        widget FREE \
#        toggle_display EXCLUDE_FREER hide N

CreateLine line \
        label "Scaling and sigmaa calculation will be done with the" \
        message "Determines if Rfree reflections will be used in scaling and sigmaa calculations" \
        widget REFMAC_REF_SET \
        toggle_display EXCLUDE_FREER hide N  \
        label "set of reflections   "

CreateLine line \
        message "Determines if TLS refinement will be used" \
        widget TLSONOFF \
        label "Do TLS refinement."

CreateLine line \
        message "User defined library with new monomer definitions" \
        widget LIBINSHOW \
        label "Input a user-defined library file."


#------------------------------------------------------

OpenFolder 4 ARP_MODE  closed

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

}
