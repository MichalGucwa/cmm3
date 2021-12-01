#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#=========================================================================#
# CCP4 Interface pointless_utils.tcl
#
#
# Utilities for Pointless Tasks
#
#=========================================================================

#CCP4i_cvs_Id $Id$

#d_index_title Utilities for Pointless Tasks (tasks/pointless_utils.tcl)
#d_intro Mostly used by task interfaces for Pointless.
#---------------------------------------------------------------------
proc PointlessSetup { typedefVar arrayname } {
#---------------------------------------------------------------------
#d_sum Set up menus and types common to all Pointless tasks
#d_arg typedefVar Name of the CCP4i types array
#d_arg arrayname Name of the array used to store the task parameters

  DefineMenu _pointless_resol_cutoff_mode \
      [list \
	   "a resolution range" \
	   "minimum <I>/<sigmaI>" ] \
      [list RESOLUTION ISIGLIMIT]

}

#---------------------------------------------------------------------
proc PointlessPartialsLine { arrayname } {
#---------------------------------------------------------------------
#d_sum Generate the lines for the Pointless PARTIALS keyword input
#d_arg arrayname Name of the array used to store the task parameters
  upvar #0 $arrayname array

  CreateLine line \
      label "Accept assembled partials that meet one or more of these conditions:" \
      -italic

  CreateLine line \
      message "These flags indicate that a set of parts is eg 1 of 3, 2 of 3, 3 of 3 (PARTIALS CHECK)" \
      help partials \
      widget PARTIALS_NOCHECK \
      label "Ignore requirement that MPART flags be consistent for all parts of the reflection"

  CreateLine line \
      message "Set criteria for accepting incomplete partials (PARTIALS TEST)" \
      help partials \
      widget PARTIALS_TEST -toggleon \
      label "The total fraction lies between lower limit" \
      widget PARTIALS_LOWER \
      label "and upper limit" \
      widget PARTIALS_UPPER

  CreateLine line \
      message "Set scale factor to apply to incomplete partials (PARTIALS CORRECT)" \
      help partials \
      widget PARTIALS_CORRECT -toggleon \
      label "Incomplete partials are accepted and scaled if they are >" \
      widget PARTIALS_MINIMUM

  CreateLine line \
      message "Accept partials with 1-5 parts missing in the middle (PARTIALS GAP)" \
      help partials \
      widget PARTIALS_GAP -toggleon \
      label "Accept partials with a gap of" \
      widget PARTIALS_GAP_LIMIT
}

#---------------------------------------------------------------------
proc PointlessResolLine { arrayname } {
#---------------------------------------------------------------------
#d_sum Generate the lines for the Pointless RESOLUTION/ISIGLIM keyword input
#d_arg arrayname Name of the array used to store the task parameters
  upvar #0 $arrayname array

  CreateLine line \
      help resolution \
      message "Specify explicit cutoffs to be used in the scoring" \
      widget USE_RESOL_CUTOFF -toggleon \
      label "Set the resolution cutoff(s) as" \
      widget RESOL_CUTOFF_MODE \
      label "High" \
      message "High resolution limit (RESOLUTION)" \
      widget RESMAX \
      label "Low" \
      message "Low resolution limit (optional) (RESOLUTION)" \
      widget RESMIN \
      label "(Angstroms)" \
      toggle_display RESOL_CUTOFF_MODE open { RESOLUTION }

  CreateLine line \
      help isiglimit \
      message "Specify explicit cutoffs to be used in the scoring" \
      widget USE_RESOL_CUTOFF -toggleon \
      label "Set the resolution cutoff(s) as" \
      widget RESOL_CUTOFF_MODE \
      label "of" \
      message "Used to set the maximum resolution in scoring (ISIGLIMIT)" \
      widget ISIGLIMIT \
      toggle_display RESOL_CUTOFF_MODE open { ISIGLIMIT }
}

#---------------------------------------------------------------------
proc PointlessXmloutLine { arrayname } {
#---------------------------------------------------------------------
#d_sum Generate the lines for the Pointless XMLOUT commandline input
#d_arg arrayname Name of the array used to store the task parameters
  upvar #0 $arrayname array

  CreateLine line \
      help xmlout \
      message "Results in the logfile will also be expressed in a separate XML file" \
      widget WRITE_XMLOUT \
      label "Write an XML version of the logfile"

  CreateOutputFileLine line \
      "Enter name of output XML logfile (XMLOUT)" \
      "Output XML" \
      XMLOUT DIR_XMLOUT \
      -toggle_display WRITE_XMLOUT open { 1 }
}

#---------------------------------------------------------------------
proc MtzIsMerged { filen } {
#---------------------------------------------------------------------
#d_sum Determine whether an MTZ file contains merged data
#d_desc Return 1 if the file is merged, 0 if unmerged.
#d_arg filen Full name of the MTZ file
    GetMtzParam $filen "NBATCHES" nbatches
    if { ![info exists nbatches] } {
	# Failed to acquire the batch information
	return 0
    }
    if { $nbatches != "" && $nbatches > 0 } {
	# Batch Mtz has unmerged data
	return 0
    } else {
	return 1
    }
}

#---------------------------------------------------------------------
proc PointlessMtzLabels { arrayname filevar { labinvar "" } } {
#---------------------------------------------------------------------
#d_sum Set the default MTZ label for Pointless in alternative index mode
#d_desc This picks the first label (either I or F) in the input MTZ \
file and forcibly sets the labinvar to that label.
#d_desc It doesn't seem that this should really be necessary however \
it is left here for the time being.
    upvar #0 $arrayname array

    set filen [GetFullFileName0 $arrayname $filevar]
    if { ![file exists $filen] } {
	# File not found
	return {}
    }
    foreach col [GetMtzAllCols $filen] {
	if { [StringSame [GetMtzColType $filen $col] "F" "J"] } {
	    # Found a matching intensity or amplitude
	    set array($labinvar) $col
	    return
	}
    }
    # Nothing found so do nothing
    return
}
