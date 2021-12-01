#
#     Copyright (C) 1999-2006  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# ======================================================================
# pointless_laue.tcl --
#
# CCP4Interface 
#
# =======================================================================

#CCP4i_cvs_Id $Id$

# Get the Pointless utilities
source [SearchPath TOP tasks pointless_common.tcl]

#-----------------------------------------------------------------------
proc pointless_centre_prereq { } {
#-----------------------------------------------------------------------
  if { ![file exists [FindExecutable "pointless"]] } {
    return 0
  }
  return 1
}

#-----------------------------------------------------------------------
proc pointless_centre_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  # Checks for Resolution
  if { [GetValue $arrayname USE_RESOL_CUTOFF] && \
	   [StringSame [GetValue $arrayname RESOL_CUTOFF_MODE] RESOLUTION] } {
      set resmin [GetValue $arrayname RESMIN]
      set resmax [GetValue $arrayname RESMAX]
      if { $resmin != "" && $resmax != "" && $resmin < $resmax } {
	  set option [ChooseOptionDialog \
			  "Check resolution limits" \
			  "Resolution" \
			  "The resolution limits appear to have
been specified the wrong way around:

Low: $resmin High: $resmax

These can be reversed automatically before
running, left as they are, or you can choose
to abort the run of this task to deal with
the problem manually." \
			  [list "Abort" "Ignore" "Reverse"] -default 0]
	  if { [regexp -- "^Abort" $option] } {
	      return 0
	  }
	  if { [regexp -- "^Reverse" $option] } {
	      # Swap the limits
	      set $array(RESMIN) $resmax
	      set $array(RESMAX) $resmin
	  }
      }	      
  }

  # Check that HLKLIN is unmerged
  set hklin [GetFullFileName0 $arrayname HKLIN]
  if { [file exists $hklin] } {
      if { [MtzIsMerged $hklin] } {
	  WarningMessage "Input MTZ file must contain unmerged data"
	  return 0
      }
  }

  # Sort out input and output file lists
  set array(INPUT_FILES) "HKLIN"
  set array(OUTPUT_FILES) ""
  if { $array(WRITE_HKLOUT) } {
      append array(OUTPUT_FILES) " HKLOUT"
  }
  if { $array(WRITE_XMLOUT) } {
      append array(OUTPUT_FILES) " XMLOUT"
  }
  return 1
}

# procedure which is run automatically before drawing the interface
# used to set up variables, menus etc
#---------------------------------------------------------------------
proc pointless_centre_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname array

  PointlessSetup $typedefVar $arrayname

  return 1
}

# procedure to draw task window
#---------------------------------------------------------------------
proc pointless_centre_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
        "Pointless: Check centre of symmetry" "Pointless" \
        [ list "Criteria For Accepting Partials" \
	      "Additional Options" \
	] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "pointless"

#=PROTOCOL==============================================================

  OpenFolder protocol

  CreateTitleLine line TITLE

  CreateLine line \
      message "Choose the mode for running Pointless" \
      label "Run Pointless to check the centre of symmetry"

  # User wants to run with a specific Laue group
  CreateLine line \
      help lauegroup \
      message "By default the Laue group will be determined from the MTZ spacegroup (LAUEGROUP)" \
      widget RESET_SYMMETRY -toggleon \
      label "Overide MTZ Laue group and use Laue group:" \
      widget LAUEGROUP_NAME

  # Output file also requested?
  CreateLine line \
      message "Reindex to the best centre of symmetry determined by the program" \
      widget WRITE_HKLOUT \
      label "Write output reflections reindexed to the correct centre of symmetry" 

#=FILES================================================================ 

  OpenFolder file

  # Input Reflection File
  # Must contain unmerged data in mode LAUEGROUP
  CreateInputFileLine line \
      "Enter name of input reflection data file (HKLIN)" \
      "Input MTZ" \
      HKLIN DIR_HKLIN \
      -setfileparam resolution_min RESMIN \
      -setfileparam resolution_max RESMAX \
      -fileout HKLOUT DIR_HKLOUT "_pointless" \
      -command "pointless_laue_check_unmerged $arrayname HKLIN"

  # Output Reflection File
  CreateOutputFileLine line \
      "Enter name of output reflection data file (HKLOUT)" \
      "Output MTZ" \
      HKLOUT DIR_HKLOUT \
      -toggle_display WRITE_HKLOUT open { 1 }

#-------------------------------------------------- PARTIALS
# Options relevant to the treatment of partials

  OpenFolder 1 closed

  PointlessPartialsLine $arrayname

#-------------------------------------------------- ADDITIONAL PARAMS
# Put the additional options here which are common to
# all modes of operation

  OpenFolder 2 closed

  # Search grid parameters
  CreateLine line \
      help grid \
      message "By default the program searches +/-2 around the origin (GRID)" \
      widget USE_HKL_GRID \
      label "Explicitly set the size of the grid for centre of symmetry search"

  CreateLine line \
      label "     Number of grid points to search around 0,0,0:" \
      toggle_display USE_HKL_GRID open { 1 }

  CreateLine line \
      label "     H: +/-" \
      widget HGRID \
      label "K: +/-" \
      widget KGRID \
      label "L: +/-" \
      widget LGRID \
      toggle_display USE_HKL_GRID open { 1 }

  # RESOLUTION/ISIGLIMIT
  PointlessResolLine $arrayname

  # XMLOUT
  PointlessXmloutLine $arrayname
      
}

#---------------------------------------------------------------------
proc pointless_laue_check_unmerged { arrayname file } {
#---------------------------------------------------------------------
    # Issue a warning if HKLIN appears not to be an unmerged file
    upvar #0 $arrayname array
    if { [MtzIsMerged [GetFullFileName0 $arrayname $file]] } {
	WarningMessage "The input MTZ file:

[GetFullFileName0 $arrayname $file]

does not appear to contain unmerged data.

Input to Pointless for centre of symmetry check
requires unmerged data."
    }
}



