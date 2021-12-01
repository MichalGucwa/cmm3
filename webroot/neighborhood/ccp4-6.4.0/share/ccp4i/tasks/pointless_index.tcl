#
#     Copyright (C) 1999-2006  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# ======================================================================
# pointless_index.tcl --
#
# CCP4Interface 
#
# =======================================================================

#CCP4i_cvs_Id $Id$

# Get the Pointless utilities
source [SearchPath TOP tasks pointless_common.tcl]

#-----------------------------------------------------------------------
proc pointless_index_prereq { } {
#-----------------------------------------------------------------------
  if { ![file exists [FindExecutable "pointless"]] } {
    return 0
  }
  return 1
}

#-----------------------------------------------------------------------
proc pointless_index_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  # Checks for MTZ labels

  # Check that a label has been assigned for input MTZ (merged only)
  if { [GetValue $arrayname MERGED_DATA] } {
      if { [StringSame [GetValue $arrayname LABIN_DATA_TYPE] F] } {
	  # Amplitudes from input file
	  if { [GetValue $arrayname F_IN] == "Unassigned" } {
	      WarningMessage "No column label assigned for amplitudes"
	      return 0
	  }
      } else {
	  # Intensities from input file
	  if { [GetValue $arrayname I_IN] == "Unassigned" } {
	      WarningMessage "No column label assigned for intensities"
	      return 0
	  }
      }
  }

  # Check that a label has been assigned
  if { [StringSame [GetValue $arrayname LABREF_DATA_TYPE] F] } {
      # Amplitudes from reference file
      if { [GetValue $arrayname F_REF] == "Unassigned" } {
	  WarningMessage "No column label assigned for amplitudes"
	  return 0
      }
  } else {
      # Intensities from reference file
      if { [GetValue $arrayname I_REF] == "Unassigned" } {
	  WarningMessage "No column label assigned for intensities"
	  return 0
      }
  }

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

  # Sort out input and output file lists
  set array(INPUT_FILES) "HKLIN HKLREF"
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
proc pointless_index_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname array

  if { ![info exists typedef(_mtz_label_iorf)] } {
      # Define new type of MTZ label which matches I's and F's
      set typedef(_mtz_label_iorf) { mtz_label {F J} Unassigned H }
  }

  PointlessSetup $typedefVar $arrayname 
  return 1
}

# procedure to draw task window
#---------------------------------------------------------------------
proc pointless_index_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
        "Pointless: Laue determination and reindexing" "Pointless" \
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
      label "Run Pointless to test alternative indexing schemes"

  # Output file also requested?
  CreateLine line \
      message "Reindex to the best space/point group determined by the program" \
      widget WRITE_HKLOUT \
      label "Write output reflections using the best indexing scheme"

#=FILES================================================================ 

  OpenFolder file

  # Input Reflection File
  # Can contain merged or unmerged data
  CreateInputFileLine line \
      "Enter name of input reflection data file (HKLIN)" \
      "Input MTZ" \
      HKLIN DIR_HKLIN \
      -setfileparam resolution_min RESMIN \
      -setfileparam resolution_max RESMAX \
      -command "pointless_index_determine_merged $arrayname HKLIN MERGED_DATA ; PointlessMtzLabels $arrayname HKLIN F_IN" \
      -fileout HKLOUT DIR_HKLOUT "_pointless"

  OpenSubFrame frame -toggle_display MERGED_DATA open { 1 }

  CreateLabinLine line \
      "Choose either intensities, or amplitudes (which will be squared to intensities) (LABIN)" \
      HKLIN "Merged Is/Fs" F_IN { * }

  CloseSubFrame

  # Reference Reflection File
  # Can only contain merged data
  CreateInputFileLine line \
      "Enter name of the reference reflection data file (HKLREF)" \
      "Ref MTZ" \
      HKLREF DIR_HKLREF \
      -command "pointless_index_determine_merged $arrayname HKLREF MERGED_REF_DATA ; PointlessMtzLabels $arrayname HKLREF F_REF"

  OpenSubFrame frame -toggle_display MERGED_REF_DATA open { 1 }

  CreateLabinLine line \
      "Choose either intensities, or amplitudes (which will be squared to intensities) (LABREF)" \
      HKLREF "Is or Fs" F_REF { * }

  CloseSubFrame

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

  # RESOLUTION/ISIGLIMIT
  PointlessResolLine $arrayname

  # XMLOUT
  PointlessXmloutLine $arrayname
      
}

#---------------------------------------------------------------------
proc pointless_index_determine_merged { arrayname file param } {
#---------------------------------------------------------------------
    # Set parameter to 1 if file is merged, 0 otherwise
    upvar #0 $arrayname array
    if { [MtzIsMerged [GetFullFileName0 $arrayname $file]] } {
      set array($param) 1
    } else {
      set array($param) 0
    }
}

