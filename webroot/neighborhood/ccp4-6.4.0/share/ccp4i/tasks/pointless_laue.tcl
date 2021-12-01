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
proc pointless_laue_prereq { } {
#-----------------------------------------------------------------------
  if { ![file exists [FindExecutable "pointless"]] } {
    return 0
  }
  return 1
}

#-----------------------------------------------------------------------
proc pointless_laue_run { arrayname } {
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

  # Check that TOLERANCE is set
  if { [GetValue $arrayname USE_TOLERANCE] } {
      set tolerance [GetValue $arrayname LATTICE_TOLERANCE]
      set tolerr 0
      if { ![string is double $tolerance] } {
	  set tolerr 1
      } elseif { $tolerance <= 0.0 } {
	  set tolerr 1
      }
      if { $tolerr } {
	  WarningMessage "The value of the maximum angular
deviation of two-fold axes is not set
to a valid value:

\"$tolerance\"

Please deselect this option or enter a
suitable value."
	  return 0
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
proc pointless_laue_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname array

  DefineMenu _pointless_laue_mode \
      [list \
          "test all possible Laue and space groups" \
	   "test a specific Laue group" ] \
      [list ALLPOSSIBLE SPECIFIC]

  DefineMenu _pointless_laue_group \
      [list "from input MTZ file" "specified below"] \
      [list HKLIN LAUEGROUPNAME]

  DefineMenu _pointless_lattice_mode \
      [list \
	   "cell dimensions in the file" \
	   "input MTZ lattice group" ] \
      [list CELL ORIGINALLATTICE]

  # Parameter typing for CHIRALITY option - commented out for now
  #DefineMenu _pointless_nonchiral \
  #    [list \
  #	   "only chiral (macromolecules)" \
  #	   "chiral and non-chiral" \
  #	   "chiral and centrosymmetric" ] \
  #      [list CHIRAL NONCHIRAL CENTROSYMMETRIC]

  PointlessSetup $typedefVar $arrayname

  return 1
}

# procedure to draw task window
#---------------------------------------------------------------------
proc pointless_laue_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
        "Pointless: Laue group determination" "Pointless" \
        [ list "Lattice Symmetry Determination" \
	      "Criteria For Accepting Partials" \
	      "Additional Options" \
	] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "pointless"

#=PROTOCOL==============================================================

  OpenFolder protocol

  CreateTitleLine line TITLE

  CreateLine line \
      message "Choose the mode for running Pointless" \
      label "Run Pointless to" \
      widget POINTLESS_LAUE_MODE

  # User wants to run with a specific spacegroup
  OpenSubFrame frame -toggle_display POINTLESS_LAUE_MODE open { SPECIFIC }

  CreateLine line \
      message "" \
      label "Use Laue group" \
      widget POINTLESS_LAUEGROUP

  CreateLine line \
      message "" \
      label "Specify Laue group as" \
      widget LAUEGROUP_NAME \
      toggle_display POINTLESS_LAUEGROUP open { LAUEGROUPNAME }

  CloseSubFrame

  # Output file also requested?
  CreateLine line \
      message "Reindex to the best space/point group determined by the program" \
      widget WRITE_HKLOUT \
      label "Write output reflections in the best space/pointgroup" \
      toggle_display POINTLESS_LAUE_MODE open { ALLPOSSIBLE }

  CreateLine line \
      message "" \
      widget WRITE_HKLOUT \
      label "Write output reflections in the selected spacegroup/pointgroup" \
      toggle_display POINTLESS_LAUE_MODE hide { ALLPOSSIBLE }

#=FILES================================================================ 

  OpenFolder file

  # Input Reflection File
  # Must contain unmerged data in mode LAUEGROUP
  CreateInputFileLine line \
      "Enter name of input data file containing unmerged reflections (HKLIN)" \
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

#-------------------------------------------------- LATTICE SYMMETRY
# Parameters controlling the determination of the lattice symmetry

  OpenFolder 1 closed

  CreateLine line \
      label "Determine lattice symmetry using" \
      widget LATTICE_MODE

  CreateLine line \
      message "POINTLESS uses 2 degrees by default if this is not specified (TOLERANCE)" \
      widget USE_TOLERANCE -toggleon \
      label "Maximum angular deviation of 2-fold axes from expected value" \
      widget LATTICE_TOLERANCE \
      label "(degrees)" \
      toggle_display LATTICE_MODE open { CELL }

#-------------------------------------------------- PARTIALS
# Options relevant to the treatment of partials

  OpenFolder 2 closed

  PointlessPartialsLine $arrayname

#-------------------------------------------------- ADDITIONAL PARAMS
# Put the additional options here which are common to
# all modes of operation

  OpenFolder 3 closed

  # ACCEPT command options
  CreateLine line \
      message "Explicity set the acceptance criterion for Laue group scores (ACCEPT)" \
      help accept \
      widget USE_ACCEPT -toggleon \
      label "Accept Laue groups with scores above" \
      widget ACCEPT_LIMIT \
      label "* highest score for all groups"

  CreateLine line \
      message "By default indistinguishable groups are not considered for processing (LAUEGROUP ALL)" \
      help lauegroup \
      widget LAUEGROUP_ALL \
      label "Accept all possible Laue groups (even those that cannot be distinguished from available data)" \
      toggle_display POINTLESS_LAUE_MODE open { ALLPOSSIBLE }

  # RESOLUTION/ISIGLIMIT
  PointlessResolLine $arrayname

  # XMLOUT
  PointlessXmloutLine $arrayname

  # CHIRALITY KEYWORD
  # Commented out for initial version
  #CreateLine line \
  #    message "Only chiral is suitable for macromolecules (CHIRALITY keyword)" \
  #    help chirality \
  #    label "Consider" \
  #    widget POINTLESS_NONCHIRAL \
  #    label "spacegroups"
      
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

Input to Pointless for Laue group determination
requires unmerged data."
      set array(HKLIN_TYPE) MERGED
    } else {
      set array(HKLIN_TYPE) UNMERGED
    }
}

