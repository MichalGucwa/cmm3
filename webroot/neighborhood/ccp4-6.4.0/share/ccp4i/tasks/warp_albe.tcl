# ======================================================================
# warp_albe.tcl --
#
# =======================================================================

#----------------------------------------------------------------------
proc warp_albe_prereq {} {
#----------------------------------------------------------------------
    if { [GetEnvPath warpbin 0] == "" } {
        return 0
    } else {
        return 1
    }
}

#----------------------------------------------------------------------
proc warp_albe_run { arrayname } {
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
          if { [expr round($patch_version.0)] <= 18 } {
            WarningMessage "You need Refmac5 version 5.1.19 (or higher) to run ARP/wARP 7.3.0. Indeed it is recommended to use refmac version 5.4.0045 or higher. Please install the latest CCP4 version."
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

if { $array(PHIB) == "Unassigned" || $array(PHIB) == "" } {
    WarningMessage "PHIB is not assigned to an mtz label
    Aborting run"
    return 0
}  

if { $array(FOM) == "Unassigned" || $array(FOM) == "" } {
    set array(FOM) " "
}  

   
if { $array(NRES) == "" } {
        WarningMessage "You have to input the number of residues." -button Cancel
}   

if { $array(TOGGLE_TEST) } {
    if { [file exists [GetFullFileName1 $array(COMPARETO) $array(DIR_COMPARETO) ] ] } {
	append array(INPUT_FILES) " COMPARETO "		
    } else {
	WarningMessage "Can not open PDB test file
        Aborting run"
	return 0
    }
}

arp_get_assym $arrayname
#
set njob [expr [DbGetJobData ""  NJOBS] +1 ]
set workdir [GetDefaultDirPath]
#
#   
set tmtzfile [GetFullFileName0 $arrayname HKLIN]
#   
set tmp_file [GetTmpFileName]
OpenFile $tmp_file f w
puts $f "MODE WILSON NRES $array(NRES)\nFILES CCP4 HKLIN=$tmtzfile\nLABELS FP=$array(FP) SIGFP=$array(SIGFP) FUSE=$array(FP) \nRESO $array(EXCLUDE_RESOLUTION_MIN) $array(EXCLUDE_RESOLUTION_MAX)\nend"
#
CloseFile $f
#
set wilson_file [FileJoin [GetDefaultDirPath] ${njob}_wilson.loggraph]
set array(WILSON_LOG) $wilson_file

catch "exec [FileJoin [GetEnvPath warpbin] arp_warp] < $tmp_file > $wilson_file"

    if { [ReadFile $wilson_file out_text] && \
       [ExtractTextLine $out_text  "Bfactor" 0 all line1  ] } {
      set wilsonb [expr [lindex $line1 3] ]
      set array(WILSON_B) [maxdecimal $wilsonb 2]
    }
    if { [ReadFile $wilson_file out_text] && \
         [ExtractTextLine $out_text  "Solvent content" 0 all line2  ] } {
      set solventc [expr [lindex $line2 2]  ]
      set array(SOLVENTC) [maxdecimal $solventc 2 ]
    }
#
# Here we set parameters to be written out to warp.par file style ...
#

set array(XYZLIM) "$array(XYZLIM_1) $array(XYZLIM_2) $array(XYZLIM_3)\
	$array(XYZLIM_4) $array(XYZLIM_5) $array(XYZLIM_6) " 

set array(RESOL) " $array(EXCLUDE_RESOLUTION_MIN) $array(EXCLUDE_RESOLUTION_MAX) "

return 1

}

#--------------------------------------------------------------------
proc warp_albe_setup { typedefVar arrayname } {
#--------------------------------------------------------------------

upvar #0  $typedefVar typedef

global env

    # Confirm that the user has sourced the arpwarp setup script
    if { [info exists env(warpbin)] == 0 } {
        WarningMessage "Please check your shell startup file does source ARP/wARP 7.3. Then open another terminal window and re-launch CCP4i."
        return 0
    }

  return 1
}

#--------------------------------------------------------------------
proc arp_get_assym { arrayname } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array

  set space_group  [GetSpaceGroupNumber $array(SPACE_GROUP)] 

#  puts $space_group

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
    set array(XYZLIM_2) [maxdecimal $lim2 5]
    set array(XYZLIM_4) [maxdecimal $lim4 5]
    set array(XYZLIM_6) [maxdecimal $lim6 5]
#    puts $array(XYZLIM)
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
  set nresidues $array(NRES)
  set mtzfile [GetFullFileName0 $arrayname HKLIN]    

# Dont' try to do the calcualtion if any of the required parameters are undefined
  if { $fobs == "" || $fobs == "Unassigned" || \
       $sig == "" || $sig == "Unassigned"  || \
       $nresidues == "" || \
       ![file exists $mtzfile] } { return }

# Don't repeat the calculation if has been done already with same parameters
  if { $array(WILSON_B) != "" && [ElementExists $arrayname WILSON_PARAMS] && \
     [StringSame $fobs [lindex $array(WILSON_PARAMS) 0]] && \
     [StringSame $sig  [lindex $array(WILSON_PARAMS) 1]] && \
     [StringSame $rexcl [lindex $array(WILSON_PARAMS) 2]] && \
     [StringSame $rmin [lindex $array(WILSON_PARAMS) 3]] && \
     [StringSame $rmax [lindex $array(WILSON_PARAMS) 4]] && \
     [StringSame $nresidues [lindex $array(WILSON_PARAMS) 5]] && \
     [StringSame $mtzfile [lindex $array(WILSON_PARAMS) 6]] } {  return }
  
  PleaseWait "Calculating Wilson B, solvent content and number of atoms"
       
  set tmp_file [GetTmpFileName]
  OpenFile $tmp_file f w

  puts $f "MODE WILSON NRES $nresidues\nFILES CCP4 HKLIN=$mtzfile \nLABELS FP=$fobs SIGFP=$sig FUSE=$fobs \nRESO $array(EXCLUDE_RESOLUTION_MIN) $array(EXCLUDE_RESOLUTION_MAX)\nend"

  CloseFile $f

  set out_file [GetTmpFileName]

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

    set array(WILSON_PARAMS) [list $fobs $sig $rexcl $rmin $rmax $nresidues $mtzfile]

  PleaseWait

}


#--------------------------------------------------------------------
proc warp_albe_task_window { arrayname } {
#--------------------------------------------------------------------

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
        "ARP/wARP Version 7.3.0: Secondary Structure Recognition" "ARP/wARP secondary structure recognition interface" \
        [ list  "Parameters "\
      "Crystal parameters"\
      "Coordinate comparison"  ] ] == 0 } return 

  set help_source [file join [GetEnvPath warpdoc] albe.htm ]
  SetProgramHelpFile $help_source

#=PROTOCOL==============================================================

  OpenFolder protocol

  CreateTitleLine line TITLE
   set arplogo [image create photo -file [ FileJoin [GetEnvPath warpbin] ARP_logo_small.gif ] ]
   set logo [label $line.log -image $arplogo]
   pack $logo

  OpenFolder file 

#=Toggle folder depending on mode ====================================================

    CreateInputFileLine line \
      "Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
       HKLIN DIR_HKLIN \
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
        -fileout XYZOUT DIR_XYZOUT "_warp_albe_" \
        -command "combine_wilson_xyz $arrayname" 

  CreateLabinLine line \
    "Choose Fobs amplitude (Fobs) and sigma (Sigma)" HKLIN \
      "Fobs    " FP  [list FP F_P F ] \
     -command "get_wilson $arrayname" \
     -sigma "Sigma  " SIGFP [list SIGFP SIGF_P SIGF ] 

  CreateLabinLine line \
    "Choose phase (PHIB) and weighting factor (FOM)" \
     HKLIN "PHIB" PHIB  {} \
     -sigma "FOM" FOM  {}

  CreateOutputFileLine line \
      "Enter file name for main chain coordinates" \
      "Output PDB file " \
       XYZOUT DIR_XYZOUT  


#=PARAMETERS==========================================================

OpenFolder 1 open

  CreateLine line \
    message "The total number of residues in the asymmetric unit " \
    label "Number of residues" \
    widget NRES -oblig \
    -command "get_wilson $arrayname"

  CreateLine line \
    message "Switch of secondary structure recognition in parts" \
    widget TOGGLE_STRANDS \
    label "Do NOT build beta-strands"

OpenFolder 2  closed

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

OpenFolder 3 closed

  CreateLine line \
    message "Compare with an already deposited protein for validation or testing" \
    widget TOGGLE_TEST \
    label "Compare with an already deposited protein for validation or testing"

  OpenSubFrame frame -toggle_display TOGGLE_TEST open 1 closed
  CreateInputFileLine line \
    "Enter name of PDB file" \
    "Deposited protein for test " \
      COMPARETO DIR_COMPARETO 
  CloseSubFrame

CloseSubFrame

#------------------------------------------------------

}
