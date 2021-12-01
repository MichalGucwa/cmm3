#
#     Copyright (C) 1999-2004  Phil Evans, Peter Briggs
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
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname array

  DefineMenu _hklin_filetype \
      [list "MTZ file" "XDS file" "Scalepack file"] \
      [list "MTZ" "XDS" "SCA"]

  DefineMenu _pointless_lattice_mode \
      [list \
	   "cell dimensions in the input reflection file" \
	   "lattice group from  space group in input reflection file" ] \
      [list CELL ORIGINALLATTICE]

  DefineMenu _pointless_resol_cutoff_mode \
      [list \
	   "a resolution range" \
	   "minimum <I>/<sigmaI>" ] \
      [list RESOLUTION ISIGLIMIT]

  DefineMenu _pointless_setting_mode \
      [list \
	   "Always set primitive orthorhombic groups in cell length order (a<b<c) & allow monoclinic I2 setting of C2" \
	   "Use reference setting for primitive orthorhombic, & always use C2 rather than I2" \
	  "Set primitive orthorhombic groups in cell length order (a<b<c) but always use C2 rather than I2"] \
      [list CELL-BASED SYMMETRY-BASED C2]

  set typedef(_pointless_batch_define) { menu { "list" \
					   "range" }
                                        { LIST RANGE } }

  if { ![info exists typedef(_mtz_label_iorf)] } {
      # Define new type of MTZ label which matches I's and F's
      set typedef(_mtz_label_iorf) { mtz_label {F J} Unassigned H }
  }

  DefineMenu _pointless_choose_type \
      [list "Laue group solution number" "Laue group name" "Space group name"] \
      [list SOLUTION_NUMBER LAUE_GROUP SPACE_GROUP]

}
#-----------------------------------------------------------------------
proc PointlessCheckRun { arrayname } {
#-----------------------------------------------------------------------
# Sanity checks before run
    upvar #0 $arrayname array
    # Laue or space group names
    if { [GetValue $arrayname CHOOSE] } {
	if { [GetValue $arrayname CHOOSE_SOLUTION] &&
	    ([StringSame [GetValue $arrayname CHOOSE_TYPE] "LAUE_GROUP"] ||
	     [StringSame [GetValue $arrayname CHOOSE_TYPE] "SPACE_GROUP"]) } {
	    if { [StringSame [GetValue $arrayname CHOOSE_GROUP] ""] } {
		WarningMessage "No Laue group or space group name chosen"
		return 0
	    }
	}
	if { [GetValue $arrayname SPECIFY_LAUEGROUP] ||
	     [GetValue $arrayname SPECIFY_SPACEGROUP] } {
	    if { [StringSame [GetValue $arrayname SPECIFY_GROUP] ""] } {
		WarningMessage "No Laue group or space group name specified"
		return 0
	    }
	}
    }
    # Add initial NAME command as if modified, if there are multiple input files
    # taking the same name
    if { [GetValue $arrayname N_HKLINX] > 1 &&
	 [GetValue $arrayname SET_PXDNAME] == 0 &&
	 [GetValue $arrayname PNAME,0] != "" &&
	 [GetValue $arrayname XNAME,0] != "" &&
	 [GetValue $arrayname DNAME,0] != ""} {
	for {set N 2} {$N <= $array(N_HKLINX)} {incr N} {
	    if { $N > 1 } {
		if { $array(USE_PREV_DATASET,$N) } {
		    set array(SET_PXDNAME) 1
		}
	    }
	}
    }
    # OK
    return 1
}
#-----------------------------------------------------------------------
proc PointlessTaskWindow { arrayname } {
#-----------------------------------------------------------------------

  upvar #0 $arrayname array

# Define all the frames
  if { [CreateTaskWindow $arrayname  \
        "Pointless: prepare intensity data for scaling" "Pointless" \
	    [ list "Choose a solution" \
		  "Excluded Data"  \
		  "Lattice Symmetry Determination" \
		  "Lattice matching" \
		  "Criteria For Accepting Partials" \
		  "Additional Options" \
		 ] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "pointless"

#=PROTOCOL==============================================================

  OpenFolder protocol

  CreateTitleLine line TITLE

  CreateLine line \
      message "Check symmetry-related observations to determine Laue group & space group" \
      widget LAUE_MODE \
      label "Determine Laue group   "  \
      -command "PointlessLaue $arrayname" \
      message "Use reference file to get consistent indexing" \
      widget USE_HKLREF \
      label "Match index to reference  "  \
      -command "PointlessRef $arrayname" \
      message "Choose a previously determined solution by number or group name" \
      widget CHOOSE \
      label "Choose a previous solution" \
      -command "PointlessChoose $arrayname" \
      message "Sort one or more files & output together" \
      widget COPY \
      label "Just combine input files" \
      -command "PointlessCopy $arrayname"

#=FILES================================================================ 

  OpenFolder file

  # Input Reflection Files
  CreateLine line \
      message "Set type for input reflection file(s): MTZ, XDS or Scalepack" \
      label "Input reflection file type:" \
      widget HKLIN_FILETYPE -command "PointlessResetInputFileCount $arrayname" \
      label "    " \
      widget TEMPLATE_FILENAMES \
      label "treat filenames as Mosflm templates (ie to match multiple files)"

  # --- Branch for multiple input files (normal) rather than single (merged MTZ input file)
  OpenSubFrame frame -toggle_display MERGED_DATA open 0

  # MTZ file option
  OpenSubFrame frame -toggle_display HKLIN_FILETYPE open "MTZ"

  CreateExtendingFrame N_HKLINX PointlessHklin \
      "Enter name of MTZ file" \
      "Add File" \
      [list HKLINX \
	   DIR_HKLINX \
	   USE_PREV_DATASET PNAME XNAME DNAME]

  CloseSubFrame

  # XDS file option
  OpenSubFrame frame -toggle_display HKLIN_FILETYPE open "XDS"

  CreateExtendingFrame N_HKLINX PointlessXdsin \
      "Enter name of XDS file" \
      "Add File" \
      [list XDS_SCA_IN \
	   DIR_XDS_SCA_IN \
	   USE_PREV_DATASET PNAME XNAME DNAME] 

  CloseSubFrame

  # SCA file option
  OpenSubFrame frame -toggle_display HKLIN_FILETYPE open "SCA"

  CreateExtendingFrame N_HKLINX PointlessScain \
      "Enter name of Scalepack file" \
      "Add File" \
      [list XDS_SCA_IN \
	   DIR_XDS_SCA_IN \
	   USE_PREV_DATASET PNAME XNAME DNAME] 

  CreateLine  line  \
      message "Enter cell lengths(Angstrom) and angles(degs) (CELL)" \
      help "cell" \
      widget SHOW_CELL -toggleon \
      label "Cell dimensions " \
      widget CELL_1  -oblig \
      widget CELL_2  -oblig \
      widget CELL_3  -oblig \
      widget CELL_4  -oblig \
      widget CELL_5  -oblig \
      widget CELL_6  -oblig   

  CloseSubFrame
  CloseSubFrame

  # --- Branch for single (merged MTZ input file) rather than multiple input files (unmerged) 
  OpenSubFrame frame -toggle_display MERGED_DATA open 1

  CreateInputFileLine line \
      "Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
      HKLINX,1 DIR_HKLINX,1 \
      -command "PointlessDetermineMerged $arrayname HKLINX,1 MERGED_DATA; PointlessMtzLabels $arrayname HKLINX,1 F_IN"

     # Label assignments if merged
     CreateLabinLine line \
      "Choose either intensities, or amplitudes (which will be squared to intensities) (LABIN)" \
      HKLINX,1 "I or F label" F_IN { * } \
      -toggle_display  MERGED_DATA open { 1 }
  CloseSubFrame
  # ---

  # Optional Reference File
  OpenSubFrame frame -toggle_display USE_HKLREF open  1
    CreateLine line \
      message "Reference file MTZ or PDB" \
      widget USE_XYZIN \
      label "Reference file is coordinate file (PDB) not MTZ" \
      toggle_display USE_XYZIN  open 1

    CreateLine line \
      message "Reference file MTZ or PDB" \
      widget USE_XYZIN \
      label "Reference file is reflection file (MTZ) not PDB" \
      toggle_display USE_XYZIN open 0

    OpenSubFrame frame2 -toggle_display USE_XYZIN open 0
      CreateInputFileLine line \
        "Enter input reference MTZ file name (HKLREF)" \
        "Reference MTZ" \
        HKLREF DIR_HKLREF \
        -command "PointlessDetermineMerged $arrayname HKLREF MERGED_REF ; PointlessMtzLabels $arrayname HKLREF F_REF"
       # Label assignments if merged
      CreateLabinLine line \
        "Choose either intensities, or amplitudes (which will be squared to intensities) (LABREF)" \
        HKLREF "I or F label" F_REF { * } \
        -toggle_display  MERGED_REF open { 1 }
    CloseSubFrame
    OpenSubFrame frame2 -toggle_display USE_XYZIN open 1
      CreateInputFileLine line \
        "Enter input reference PDB file name (XYZIN)" \
        "Reference PDB" \
        XYZIN DIR_XYZIN

    CloseSubFrame

  CloseSubFrame

  # Output Reflection File
  OpenSubFrame frame -toggle_display COPY hide { 1 }
  CreateLine line \
      message "Reindex to the best space/point group determined by the program" \
      widget WRITE_HKLOUT \
      label "Write output reflections in the best space/pointgroup" \
      toggle_display LAUE_MODE open { 1 }

  CreateLine line \
      message "Reindex to the best space group from the reference file" \
      widget WRITE_HKLOUT \
      label "Write output reflections in the space group from the reference file" \
      toggle_display USE_HKLREF open { 1 }

  CreateLine line \
      message "Reindex to the chosen Laue group or space group " \
      widget WRITE_HKLOUT \
      label "Write output reflections in the chosen Laue group or space group" \
      toggle_display CHOOSE open { 1 }

  CloseSubFrame
  CreateOutputFileLine line \
      "Enter name of output reflection data file (HKLOUT)" \
      "Output MTZ" \
      HKLOUT DIR_HKLOUT \
      -toggle_display WRITE_HKLOUT open { 1 }

  # TESTFIRSTFILE & ASSUMESAMEINDEXING options for multiple inputs only
  # TESTFIRSTFILE off by default
  # ASSUMESAMEINDEXING OFF by default unless wild-cards are used
  #  (wild-cards not implemented yet)
  OpenSubFrame frame -toggle_display MULTIPLE_INPUTS open  1

  CreateLine line \
      message "Test Laue group on 1st file before indexing tests on the rest, test again on all data" \
      widget TESTFIRSTFILE \
      label "Test Laue group of 1st file before reading rest  " \
      message "Default is to test each file for consistent indexing against previous ones" \
      widget ASSUMESAMEINDEXING -command "PointlessChangedAssumeSameIndex $arrayname" \
      label "Assume all files have same indexing (faster)" \
      toggle_display LAUE_MODE open { 1 }

  CloseSubFrame

  OpenSubFrame frame -toggle_display LAUE_MODE open  1
  CreateLine line \
      message "Choose setting option: CELL-BASED or SYMMETRY-BASED" \
      widget SET_SETTING -toggleon \
      widget SETTING_CHOICE 

  CloseSubFrame


#------------------------------------------------------------------Choose Solution
  OpenFolder 1 CHOOSE hide { 0 } open
  PointlessChooseSolution $arrayname

#------------------------------------------------------------------Exclude data

  OpenFolder 2 EXCLUDE_ANY closed { 0 }

  # Excluded batches
  CreateLine line \
    label "Exclude batches:" -italic

  CreateLine line \
    help exclude_batch \
    message "Define a list or range of batches to be excluded altogether" \
    widget EXCLUDE_BATCH \
    label "Exclude selected batches"

  OpenSubFrame frame -toggle_display EXCLUDE_BATCH open 1

  CreateExtendingFrame N_EXCLUDE_BATCH PointlessExcludeBatch \
    "Select batches from the input file to be excluded altogether" \
    "Add batches" \
    [list EXCLUDE_BATCH_DEFINE \
          EXCLUDE_BATCH_LIST \
          EXCLUDE_BATCH_FIRST \
          EXCLUDE_BATCH_LAST ]

  CloseSubFrame

  # RESOLUTION/ISIGLIMIT
  PointlessResolLine $arrayname

#-------------------------------------------------- LATTICE SYMMETRY
# Parameters controlling the determination of the lattice symmetry

  OpenFolder 3 LAUE_MODE hide { 0 } closed

  CreateLine line \
      label "Determine lattice symmetry using" \
      widget LATTICE_MODE

  CreateLine line \
      message "POINTLESS uses 2 degrees by default if this is not specified (TOLERANCE)" \
      widget USE_TOLERANCE -toggleon \
      label "Tolerance for determination of crystal lattice class  " \
      widget LATTICE_TOLERANCE \
      label "(degrees or equivalent on lengths)" \
      toggle_display LATTICE_MODE open { CELL }

#-------------------------------------------------- LATTICE MATCHING
# Parameters controlling matching of the lattice

  OpenFolder 4 USE_HKLREF hide { 0 } closed

  CreateLine line \
      message "POINTLESS uses 2 degrees by default if this is not specified (TOLERANCE)" \
      widget USE_TOLERANCE -toggleon \
      label "Tolerance for matching lattices  " \
      widget LATTICE_TOLERANCE \
      label "(degrees or equivalent on lengths)" \
      toggle_display LATTICE_MODE open { CELL }

#-------------------------------------------------- PARTIALS
# Options relevant to the treatment of partials (MTZ only)

  OpenFolder 5 HKLIN_FILETYPE closed { "MTZ" } hide

  PointlessPartialsLine $arrayname

#-------------------------------------------------- Additional options

  OpenFolder 6 closed

# Cell
  CreateLine  line  \
      message "Enter cell lengths(Angstrom) and angles(degs) to override all in input" \
      help "cell" \
      widget SHOW_CELL -toggleon \
      label "Cell dimensions to override file values " \
      widget CELL_1 \
      widget CELL_2 \
      widget CELL_3 \
      widget CELL_4 \
      widget CELL_5 \
      widget CELL_6 \
      toggle_display HKLIN_FILETYPE hide { "SCA" } 

# Neighbour
  CreateLine  line  \
      message "Fraction of neighbouring intensity to subtract from axial reflections" \
      help "neighbour" \
      widget NEIGHBOUR  -toggleon \
      label "Neighbour fraction correction for axial reflections" \
      widget NEIGHBOUR_FRACTION


  # XMLOUT
  PointlessXmloutLine $arrayname
}
#-----------------------------------------------------------------------
proc PointlessResetInputFileCount { arrayname } {
#-----------------------------------------------------------------------
    upvar #0 $arrayname array
    set array(N_HKLINX) 1
    set array(MULTIPLE_INPUTS) 0
    if { $array(HKLIN_FILETYPE) != "MTZ" } {
	set array(TEMPLATE_FILENAMES) 0
    }
}
#-----------------------------------------------------------------------
proc PointlessFirstDataset { arrayname counter } {
#-----------------------------------------------------------------------
    upvar #0 $arrayname array
    # Define the first "base" dataset
    CreateLine line \
	label "Project name:" \
	widget PNAME  -command "PointlessChangedPXDname $arrayname" \
	label "crystal name:" \
	widget XNAME  -command "PointlessChangedPXDname $arrayname" \
	label "dataset name:" \
	widget DNAME  -command "PointlessChangedPXDname $arrayname"
}
#-----------------------------------------------------------------------
proc PointlessSameDataset { arrayname counter } {
#-----------------------------------------------------------------------
 upvar #0 $arrayname array
 
    # Subsequent lines allow reuse of previous dataset
    CreateLine line \
	widget USE_PREV_DATASET \
	label "Assign to the same dataset as the previous file"

    CreateLine line \
	label "     Project name:" \
	widget PNAME \
	label "crystal name:" \
	widget XNAME \
	label "dataset name:" \
	widget DNAME \
	toggle_display USE_PREV_DATASET,$counter open { 0 }
    
}

#-----------------------------------------------------------------------
proc PointlessHklin { arrayname counter } {
#-----------------------------------------------------------------------
    # Draw one line of the input file extending frame
    upvar #0 $arrayname array
  
    # Dataset info #1
    if { $counter == 1 } {
	PointlessFirstDataset  $arrayname $counter
    }

    # MTZ file
    CreateInputFileLine line \
	"Enter input MTZ file name (HKLIN)" \
	"MTZ \#$counter" \
	HKLINX DIR_HKLINX \
	-command "PointlessGetMtzStuff $arrayname $counter" \
        -fileout HKLOUT DIR_HKLOUT _pointless \
  

    # Dataset info #2
    if { $counter != 1 } {
    # Subsequent lines allow reuse of previous dataset
	PointlessSameDataset  $arrayname $counter
	set array(MULTIPLE_INPUTS) 1
    }
}

#-----------------------------------------------------------------------
proc PointlessXdsin { arrayname counter } {
#-----------------------------------------------------------------------
    # Draw one line of the input file extending frame
    upvar #0 $arrayname array
  
    # Dataset info #1
    if { $counter == 1 } {
	PointlessFirstDataset  $arrayname $counter
    }

    # XDS file
    CreateInputFileLine line \
	"Enter input XDS file name (XDSIN)" \
	"XDS \#$counter" \
	XDS_SCA_IN DIR_XDS_SCA_IN \
	-command "PointlessGetXdsDataset $arrayname $counter"

    # Dataset info #2
    if { $counter != 1 } {
	PointlessSameDataset  $arrayname $counter 
	set array(MULTIPLE_INPUTS) 1
    }
}

#-----------------------------------------------------------------------
proc PointlessScain { arrayname counter } {
#-----------------------------------------------------------------------
    # Draw one line of the input file extending frame
    upvar #0 $arrayname array
  
    # Dataset info #1
    if { $counter == 1 } {
	PointlessFirstDataset  $arrayname $counter
    }

    # SCA file
    CreateInputFileLine line \
	"Enter input Scalepack file name (SCAIN)" \
	"SCA \#$counter" \
	XDS_SCA_IN DIR_XDS_SCA_IN \
	-command "PointlessGetXdsDataset $arrayname $counter"
    

    # Dataset info #2
    if { $counter != 1 } {
	PointlessSameDataset  $arrayname $counter 
	set array(MULTIPLE_INPUTS) 1
    }
}

#---------------------------------------------------------------------
proc PointlessGetMtzStuff { arrayname n } {
#---------------------------------------------------------------------
# Various things to set up for newly assigned MTZ file

    # Fetch the project, crystal and dataset from an MTZ file
    # and populate the appropriate parameters
    upvar #0 $arrayname array
    upvar #0 $n counter

    set mtz [GetFullFileName0 $arrayname HKLINX,$n]
    set xtals [GetMtzXtals $mtz]
    if { [llength $xtals] == 0 } {
	# No data
	return
    }
    # Set crystal to first one (if there's more than one)
    # similarly for the dataset name
    set array(XNAME,$n) [lindex $xtals 0]
    set array(DNAME,$n) [lindex [GetMtzDatasetsInXtal $mtz $array(XNAME,$n)] 0]

    # Lookup the project name associated with this crystal/dataset combination
    GetMtzParamFromDataset $mtz $array(XNAME,$n) $array(DNAME,$n) "PNAME" pname
    set array(PNAME,$n) $pname

    # save current merged status
    set current_merged $array(MERGED_DATA)
    # is it merged?
    PointlessDetermineMerged $arrayname HKLINX,$n MERGED_DATA 

    if { $current_merged == 1 || $array(MERGED_DATA) == 1 } {
	if { $n > 1 } {
	    # Only one input file allowed if merged
	    # Gets here if first file(s) were unmerged but the most recent is merged
	    WarningMessage "Only one input HKLIN file allowed if it is MERGED"
	    ##	    set array(N_HKLINX) 1   ## doesn't work
	    ##	    set array(MULTIPLE_INPUTS) 0
	    # Restore unmerged status
	    set array(MERGED_DATA) 0
	    set array(HKLINX,$n) ""
	    #  FIXME: this needs some additional clean-up to remove the
	    #  offending line, but I don't know how to do this
	    return
	}
	# Get labels
	PointlessMtzLabels $arrayname HKLINX,$n F_IN
	# Force reference file
	set array(USE_HKLREF) 1
	PointlessRef $arrayname 
    }

    return
}

#---------------------------------------------------------------------
proc PointlessGetXdsDataset { arrayname n } {
#---------------------------------------------------------------------
    # Set the project, crystal and dataset from the previous ones
    upvar #0 $arrayname array

    if { $n < 2 } {
	return
    }

    set np [expr  $n - 1 ]

    # Set crystal to previous one (if there's more than one)
    # similarly for the dataset name
    set array(PNAME,$n) $array(PNAME,$np)
    set array(XNAME,$n) $array(XNAME,$np)
    set array(DNAME,$n) $array(DNAME,$np)

    return
}

#---------------------------------------------------------------------
proc PointlessLaue { arrayname } {
#---------------------------------------------------------------------
    # If Laue is set, turn off reference, choose & copy
    #  else revert to copy
    upvar #0 $arrayname array

    if { $array(LAUE_MODE) } {
	set array(USE_HKLREF) 0
	set array(USE_XYZIN) 0
	set array(CHOOSE) 0
	set array(COPY) 0
    } else {
	set array(USE_HKLREF) 0
	set array(USE_XYZIN) 0
	set array(CHOOSE) 0
	set array(COPY) 1
    }
}
#---------------------------------------------------------------------
proc PointlessRef { arrayname } {
#---------------------------------------------------------------------
    # If reference is set, then turn off choose & copy, & turn on HKLOUT
    #  else revert to Laue mode
    upvar #0 $arrayname array

    if { $array(USE_HKLREF) } {
	set array(LAUE_MODE) 0
	set array(CHOOSE) 0
	set array(COPY) 0
	set array(WRITE_HKLOUT) 1
    } else {
	set array(LAUE_MODE) 1
	set array(CHOOSE) 0
	set array(COPY) 0
    }
}

#---------------------------------------------------------------------
proc PointlessChoose { arrayname } {
#---------------------------------------------------------------------
    # If choose is set, then must have HKLOUT, unset reference
    #  else revert to Laue mode
    upvar #0 $arrayname array

    if { $array(CHOOSE) } {
	set array(WRITE_HKLOUT) 1
	set array(LAUE_MODE) 0
	set array(USE_HKLREF) 0
	set array(COPY) 0
    } else {
	set array(LAUE_MODE) 1
	set array(USE_HKLREF) 0
	set array(COPY) 0
    }
}
#---------------------------------------------------------------------
proc PointlessCopy { arrayname } {
#---------------------------------------------------------------------
    # If copy is set, then must have HKLOUT, unset reference
    upvar #0 $arrayname array

    if { $array(COPY) } {
	set array(WRITE_HKLOUT) 1
	set array(LAUE_MODE) 0
	set array(USE_HKLREF) 0
	set array(CHOOSE) 0
    } else {
	set array(LAUE_MODE) 1
	set array(CHOOSE) 0
	set array(USE_HKLREF) 0
    }
}

#---------------------------------------------------------------------
proc PointlessChooseSolution { arrayname } {
#---------------------------------------------------------------------

# Create things for solution choice frame

    upvar #0 $arrayname array

    CreateLine line \
	widget CHOOSE_SOLUTION -toggleon -command "PointlessSetChooseSolution $arrayname" \
	message "Choose a solution from the search based on a previous run" \
	label "Choose solution from search by " \
	widget CHOOSE_TYPE -command "PointlessSetChooseSolution $arrayname" \
	message "Ranked Laue group solution number from previous run" \
	widget CHOOSE_NUMBER \
	toggle_display CHOOSE_TYPE open { SOLUTION_NUMBER }

    CreateLine line \
	widget CHOOSE_SOLUTION -toggleon -command "PointlessSetChooseSolution $arrayname" \
	message "Choose a solution from the search based on a previous run" \
	label "Choose solution from search by " \
	widget CHOOSE_TYPE -command "PointlessSetChooseSolution $arrayname" \
	message "Ranked Laue group name from previous run" \
	widget CHOOSE_GROUP \
	toggle_display CHOOSE_TYPE open { LAUE_GROUP }

    CreateLine line \
	widget CHOOSE_SOLUTION -toggleon -command "PointlessSetChooseSolution $arrayname" \
	message "Choose a solution from the search based on a previous run" \
	label "Choose solution from search by " \
	widget CHOOSE_TYPE -command "PointlessSetChooseSolution $arrayname" \
	message "Space group name from previous run" \
	widget CHOOSE_GROUP \
	toggle_display CHOOSE_TYPE open { SPACE_GROUP }

    CreateLine line \
	message "Specify Laue group (no search) with reindex operator" \
	widget SPECIFY_LAUEGROUP -command "PointlessSpecifyLauegroup $arrayname" \
	label "Specify Laue group name " \
	message "Specify Space group (no search) with reindex operator" \
	widget SPECIFY_SPACEGROUP -command "PointlessSpecifySpacegroup $arrayname" \
	label "Specify Space group name              Laue or space group name " \
	message "Laue or space group name" \
	widget SPECIFY_GROUP

    OpenSubFrame frame -toggle_display CHOOSE_SOLUTION open 0

    CreateLine line \
	widget REINDEX -toggleon \
	message "Input reindexing matrix in form like 'h -k -h/2-l/2' (REINDEX)" \
	help reindex \
	label "Use reindex operator  h=" \
	widget REINDEX_H \
	label "  k=" \
	widget REINDEX_K \
	label "  l=" \
	widget REINDEX_L \
	toggle_display REINDEX_MODE open HKL
    CloseSubFrame

}
#---------------------------------------------------------------------
proc PointlessSetChooseSolution { arrayname } {
#---------------------------------------------------------------------
    upvar #0 $arrayname array
    if { $array(CHOOSE_SOLUTION) } {
	set array(SPECIFY_SPACEGROUP) 0
	set array(SPECIFY_LAUEGROUP) 0
	set array(SPECIFY_GROUP) ""
    }
}
#---------------------------------------------------------------------
proc PointlessSpecifyLauegroup { arrayname } {
#---------------------------------------------------------------------
    upvar #0 $arrayname array
    if { $array(SPECIFY_LAUEGROUP) } {
	set array(SPECIFY_SPACEGROUP) 0
	set array(CHOOSE_SOLUTION) 0
	set array(CHOOSE_GROUP) ""
    }
}
#---------------------------------------------------------------------
proc PointlessSpecifySpacegroup { arrayname } {
#---------------------------------------------------------------------
    upvar #0 $arrayname array
    if { $array(SPECIFY_SPACEGROUP) } {
	set array(SPECIFY_LAUEGROUP) 0
	set array(CHOOSE_SOLUTION) 0
	set array(CHOOSE_GROUP) ""
    }
}
#---------------------------------------------------------------------
proc PointlessChangedPXDname { arrayname } {
#---------------------------------------------------------------------
    upvar #0 $arrayname array
    set array(SET_PXDNAME) 1
}
#---------------------------------------------------------------------
proc PointlessChangedAssumeSameIndex { arrayname } {
#---------------------------------------------------------------------
    upvar #0 $arrayname array
    set array(ASSUMESAMEINDEXINGSET) 1
}
#---------------------------------------------------------------------
proc PointlessDetermineMerged { arrayname file param } {
#---------------------------------------------------------------------
    # Set parameter to 1 if file is merged, 0 otherwise
    upvar #0 $arrayname array
    if { [MtzIsMerged [GetFullFileName0 $arrayname $file]] } {
      set array($param) 1
    } else {
      set array($param) 0
    }
}
#-----------------------------------------------------------------------
proc PointlessExcludeBatch { arrayname counter } {
#-----------------------------------------------------------------------
    upvar #0 $arrayname array

  OpenSubFrame frame -toggle_display MULTIPLE_INPUTS open 0
  # single input
  CreateLine line \
    help exclude_batch \
    message "Define a list or range of batches to be excluded altogether" \
    label "Exclude a" \
    widget EXCLUDE_BATCH_DEFINE \
    label "of batches:" \
    widget EXCLUDE_BATCH_LIST \
    toggle_display EXCLUDE_BATCH_DEFINE,$counter open LIST

  CreateLine line \
    help exclude_batch \
    message "Define a list or range of batches to be excluded altogether" \
    label "Exclude a" \
    widget EXCLUDE_BATCH_DEFINE \
    label "of batches from" \
    widget EXCLUDE_BATCH_FIRST \
    label "to" \
    widget EXCLUDE_BATCH_LAST \
    toggle_display EXCLUDE_BATCH_DEFINE,$counter open RANGE
  CloseSubFrame

  OpenSubFrame frame -toggle_display MULTIPLE_INPUTS open 1
  CreateLine line \
    help exclude_batch \
    message "Define a list or range of batches to be excluded altogether" \
    label "Exclude a" \
    widget EXCLUDE_BATCH_DEFINE \
    label "of batches:" \
    widget EXCLUDE_BATCH_LIST \
    label "in file #" \
    widget EXCLUDE_BATCH_SERIES \
    toggle_display EXCLUDE_BATCH_DEFINE,$counter open LIST

  CreateLine line \
    help exclude_batch \
    message "Define a list or range of batches to be excluded altogether" \
    label "Exclude a" \
    widget EXCLUDE_BATCH_DEFINE \
    label "of batches from" \
    widget EXCLUDE_BATCH_FIRST \
    label "to" \
    widget EXCLUDE_BATCH_LAST \
    label "in file #" \
    widget EXCLUDE_BATCH_SERIES \
    toggle_display EXCLUDE_BATCH_DEFINE,$counter open RANGE
  CloseSubFrame

    if { $array(EXCLUDE_BATCH) || $array(USE_RESOL_CUTOFF) } {
	set array(EXCLUDE_ANY) 1
    } else {
	set array(EXCLUDE_ANY) 0
    }

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
      message "Specify explicit cutoffs to be used in the scoring and output" \
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
      message "Specify explicit I/sigI cutoff to be used in the scoring only" \
      widget USE_RESOL_CUTOFF -toggleon \
      label "Set the resolution cutoff for scoring as" \
      widget RESOL_CUTOFF_MODE \
      label "of" \
      message "Used to set the maximum resolution in scoring (ISIGLIMIT)" \
      widget ISIGLIMIT \
      toggle_display RESOL_CUTOFF_MODE open { ISIGLIMIT }

    if { $array(EXCLUDE_BATCH) || $array(USE_RESOL_CUTOFF) } {
	set array(EXCLUDE_ANY) 1
    } else {
	set array(EXCLUDE_ANY) 0
    }

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
#d_desc This picks the first label I or first F in the input MTZ \
file and forcibly sets the labinvar to that label.
#d_desc It doesn't seem that this should really be necessary however \
it is left here for the time being.
    upvar #0 $arrayname array

    set filen [GetFullFileName0 $arrayname $filevar]
    if { ![file exists $filen] } {
	# File not found
	return {}
    }
    #  try to find an intensity first
    foreach col [GetMtzAllCols $filen] {
	if { [StringSame [GetMtzColType $filen $col] "J"] } {
	    # Found a matching intensity or amplitude
	    set array($labinvar) $col
	    return
	}
    }
    # else find an F
    foreach col [GetMtzAllCols $filen] {
	if { [StringSame [GetMtzColType $filen $col] "F"] } {
	    # Found a matching intensity or amplitude
	    set array($labinvar) $col
	    return
	}
    }
    # Nothing found so do nothing
    return
}
