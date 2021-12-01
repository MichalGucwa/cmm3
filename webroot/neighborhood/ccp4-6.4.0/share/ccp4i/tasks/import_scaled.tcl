#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
# ======================================================================
# import_scaled.tcl --
#
# Import a formatted reflection file from either SCALEPACK or D*TREK and
# create an MTZ file with intensities - convert to SFs using truncate
#
# CCP4Interface 
# Aug01 by Peter Briggs, from the scalepack2mtz and dtrek2mtz
# tasks originally created by Liz Potterton.
#
# =======================================================================

source [SearchPath TOP tasks truncate.tcl]


#------------------------------------------------------------------------
proc import_scaled_setup { typedefname arrayname }  {
#------------------------------------------------------------------------
  upvar #0 $typedefname typedef

  truncate_setup $typedefname $arrayname

  DefineMenu _import_format [list "Scalepack (DENZO)" "d*trek"] \
	                     [ list SCALEPACK DTREK ] 

  DefineMenu _import_truncate_id [list "dataset name" \
				      "user defined identifier" ] \
                                  [ list DATASET USER ]
                                  
  DefineMenu _import_truncate_prog [list "Ctruncate" "old Truncate"] \
                         [ list CTRUNCATE TRUNCATE ]

  return 1

}


#---------------------------------------------------------------------
proc import_scaled_run { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { $array(USE_LABOUT) } {
    if { $array(ANOMALOUS) } {
      set array(LABOUT) "IMEAN SIGIMEAN Ip SIGIp Im SIGIm F SIGF DANO SIGDANO Fp SIGFp Fm SIGFm ISYM"
    } else {
      set array(LABOUT) "IMEAN SIGIMEAN F SIGF"
    }
  }

  # Set the list of INPUT_FILES to the correct logical name for the
  # type of data being imported
  if { [GetValue $arrayname IMPORT_FORMAT] == "SCALEPACK" } {
     set array(INPUT_FILES) HKLIN_SCA
  } elseif { [GetValue arrayname IMPORT_FORMAT] == "DTREK" } {
     set array(INPUT_FILES) HKLIN_REF
  }

  # suppress warnings about harvest dataset names for now because ctruncate doesn't do harvesting
  #if { ![SetHarvestParams $arrayname {}  -run] } { return 0 } 

  # Sort out the label identifiers for truncate
  if { $array(RUN_TRUNCATE) } {
    import_scaled_truncate_labout $arrayname
  } else {
    # if you don't run Truncate then have to output Is
    set array(OUTPUT_I) 1
  }

  return 1
}

#----------------------------------------------------------------------
proc read_dtrek_header { arrayname } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array

# Try and read in the cell and spacegroup from header information in
# the dtrek file
# Read the first 10 lines - then stop

  set filename [GetFullFileName0 $arrayname HKLIN_REF]

  if { [file exists $filename]  && [OpenFile $filename f r ] } { 

      for { set n 0 } { $n < 10 } { incr n } {
	  catch "gets $f line"
	  set words [ split $line = ]
	  if { [ llength $words ] == 2 } {
	      set first_word [ lindex $words 0 ]
	      if { [string match CRYSTAL_SPACEGROUP $first_word ] } {
		  set space_group [string trim [lindex $words 1] ";" ]
	      } elseif { [string match  CRYSTAL_UNIT_CELL $first_word ] } {
		  set cell_params [split [lindex $words 1] ]
		  if { [llength $cell_params] == 6 } {
		      set ii -1
		      for { set i 1 } { $i <= 6 } { incr i } {
			  incr ii
			  set cell($i) [string trim [lindex $cell_params $ii] ";"]
		      }
		  }
	      }
	  }
      }
      CloseFile $f
  }
  # Check if the information read in makes sense
  set cell_ok 1
  for { set i 1 } { $i <= 6 } { incr i } {
      # Cell parameters must be positive and non-zero
      if { ![info exists cell($i) ] } {
	  set cell_ok 0
      } elseif { $cell($i) <= 0 } {
	  set cell_ok 0
      }
  }
  # Only load the parameters if the cell checks out as reasonable
  if { $cell_ok } {
      for { set i 1 } { $i <= 6 } { incr i } {
	  set array(CELL_$i) $cell($i)
      }
      if { [info exists space_group] } { set array(SPACE_GROUP) $space_group }
  }
}

#----------------------------------------------------------------------
proc read_scalepack_header { arrayname } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array

# Read the 3rd line of the scalepack file to get cell and perhaps spacegroup
# Warning: maybe there is no header?
# We need to check that the extracted values are sensible

  set filename [GetFullFileName0 $arrayname HKLIN_SCA]

  if { [file exists $filename]  && [OpenFile $filename f r ] } { 

    for { set n 1 } { $n <= 3 } { incr n } { catch "gets $f line" }
    if { [llength $line] >= 6 } {
      set ii -1; for { set i 1 } { $i <= 6 } { incr i } { incr ii
	set cell($i) [lindex $line $ii]
      }
      if { [llength $line] >= 7 } { 
	set space_group [lindex $line 6] 
      }
    }

## read a line of reflection data - does it include anomalous (4 data columns) 
## or no anomalous (2 data columns)
#    for { set n 1 } { $n <= 3 } { incr n } { catch "gets $f line" }
#    if { [llength $line] == 5 } {
#      set array(ANOMALOUS) 0
#    } elseif { [llength $line] == 7 } {
#      set array(ANOMALOUS) 1
#    }

    CloseFile $f
  }

  # Check if the information read in makes sense
  set cell_ok 1
  for { set i 1 } { $i <= 6 } { incr i } {
      # Cell parameters must be positive and non-zero
      if { ![info exists cell($i) ] } {
	  set cell_ok 0
      } elseif { $cell($i) <= 0 } {
	  set cell_ok 0
      }
  }
  # Only load the parameters if the cell checks out as reasonable
  if { $cell_ok } {
      for { set i 1 } { $i <= 6 } { incr i } {
	  set array(CELL_$i) $cell($i)
      }
      # cannot handle r3, so switch to h3
      regsub -nocase {r3} $space_group h3 space_group
      if { [info exists space_group] } { set array(SPACE_GROUP) $space_group }
  }
}

#-------------------------------------------------------------------------
proc import_scaled_truncate_labout { arrayname } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array

  # Reset the identifier depending on whether the user wants
  # dataset name or user-defined labels
  if { [GetValue $arrayname COLUMN_ID_TYPE] == "DATASET" } {
    set array(LABOUT_LABEL) $array(HARVEST_DNAME)
  } else {
    set array(LABOUT_LABEL) $array(USER_LABOUT_LABEL)
  }

  # Update the labels
  truncate_labout $arrayname

}

#-------------------------------------------------------------------------
proc import_scaled_task_window { arrayname } {
#-------------------------------------------------------------------------

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"ImportScaled - Import Scaled Data from Denzo or d*trek" "Scalepack/dtrek" \
	[ list "MTZ Project, Crystal, Dataset Names & Data Harvesting" \
	"MTZ Project, Crystal & Dataset Names" \
	"Extra Information for MTZ File" \
        "Edit or Transform Input Data" \
	"Log File Output" \
	"Conversion to SFs Parameters" ] ] == 0 } return

  SetHarvestParams $arrayname {}  -init


#=PROTOCOL==============================================================
# Choose format of file to be read

  OpenFolder protocol

  CreateTitleLine line TITLE

  CreateLine line \
    message "Has the data come from DENZO/Scalepack or from d*trek?" \
    label "Convert scaled data output from" \
    widget IMPORT_FORMAT \
    label "into MTZ format"

  CreateLine line \
    message "Does the file contain anomalous data? (ANOMALOUS)" \
    widget ANOMALOUS \
    label "Use anomalous data"

  SetProgramHelpFile truncate

  CreateLine line \
    message "Convert input intensities to structure factors" \
    widget RUN_TRUNCATE \
    label "Run" \
    widget IMPORT_TRUNCATE_PROG \
    label "to convert intensities to structure factors"

  CreateLine line \
    message "Keep the input intensities in the output MTZ file" \
    widget OUTPUT_I \
    label "Keep the input intensities in the output MTZ file" \
    toggle_display RUN_TRUNCATE open 1

  UniqueifyFrame1 $arrayname


#=FILES================================================================
   OpenFolder file

  CreateInputFileLine line \
      "Enter input reflection file name for Scalepack data (HKLIN)" \
        "In" \
       HKLIN_SCA DIR_HKLIN_SCA \
       -fileout HKLOUT DIR_HKLOUT -- \
       -command "read_scalepack_header $arrayname" \
       -toggle_display IMPORT_FORMAT open [list SCALEPACK]

  CreateInputFileLine line \
      "Enter input reflection file name for d*trek data (HKLIN)" \
        "In" \
       HKLIN_REF DIR_HKLIN_REF \
       -fileout HKLOUT DIR_HKLOUT -- \
       -command "read_dtrek_header $arrayname" \
       -toggle_display IMPORT_FORMAT open [list DTREK]

  UniqueifyFrame2

  CreateOutputFileLine line \
      "Enter output MTZ file name (HKLOUT)" \
       "Out" \
       HKLOUT DIR_HKLOUT \
       -info

  OpenSubFrame frame -toggle_display RUN_TRUNCATE open 1

  CreateLine line \
    message "Decide how to identify columns from different datasets" \
    label "Use" \
    widget COLUMN_ID_TYPE \
        -command "import_scaled_truncate_labout $arrayname"\
    label "as identifier to append to column labels"

  CreateLine line \
    message "Enter an identifier for this data set to append to column labels" \
    label "Identifier to append to column labels" \
    widget USER_LABOUT_LABEL \
        -command "import_scaled_truncate_labout $arrayname" \
    toggle_display COLUMN_ID_TYPE hide DATASET 

  CloseSubFrame

#=PARAMETERS==========================================================

  OpenFolder 1 RUN_TRUNCATE open 1 hide

  CreateHarvestLine line  -dname

  OpenFolder 2 RUN_TRUNCATE open 0 hide
  
  CreateHarvestLine line  -noharv 


#------------------------------------------------------------------------

  OpenFolder 3

  CreateLine  line  \
	message "Enter the number code for the space group (SYMMETRY) "	\
	help "symmetry" \
	label "Space group" \
	widget SPACE_GROUP -oblig

  CreateLine  line  \
	message "Enter cell lengths(Angstrom) and angles(degs) (CELL)" \
        help "cell" \
	label "Cell dimensions " \
	widget CELL_1  -oblig \
	widget CELL_2  -oblig \
	widget CELL_3  -oblig \
	widget CELL_4  -oblig \
	widget CELL_5  -oblig \
	widget CELL_6  -oblig 

  CreateLine line \
        message "Enter wavelength (Angstroms) that this dataset was collected at (WAVE)" \
        help wave \
        label "Data collected at wavelength" \
        widget LAMBDA -oblig \
        label "Angstroms"

  SetProgramHelpFile truncate

  CreateLine line \
    label "Estimated number of residues in the asymmetric unit" \
    help NRESIDUES \
    widget CONTENTS_NRES -oblig \
    toggle_display RUN_TRUNCATE open 1




#==EDIT / TRANSFORM INPUT DATA=========================================

  OpenFolder 4 closed

  SetProgramHelpFile scalepack2mtz

  CreateLine line \
    message "Set resolution limits on data (RESOLUTION)" \
    help "resolution" \
    widget RESOLUTION_RANGE \
	-toggleon \
    label "Set resolution limits to min" \
    widget RESOLUTION_MIN \
    label "and max" \
    widget RESOLUTION_MAX

  CreateLine line \
    message "Multiply input intensities by scaling factor (SCALE)" \
    label "Scale input intensities by" \
    widget SCALE

#  CreateLine line \
#    message  "Reindex the reflections by applying transformation (REINDEX)" \
#    widget REINDEX \
#    label "Reindex transformation: h=" \
#    widget REINDEX_H \
#    label "  k=" \
#    widget REINDEX_K \
#    label "  l=" \
#    widget REINDEX_L

  CreateLine line \
    label "Exclude the following reflections from the output file" -italic

 CreateExtendingFrame N_REJECTS HklRejects \
        "Define reflections to be excluded from file" \
        "Add Reject" \
      [list  REJECT1_H \
        REJECT1_K \
        REJECT1_L \
        REJECT2_H \
        REJECT2_K \
        REJECT2_L ]


  OpenFolder 5 closed

   CreateLine line \
     message "Write diagnostic to log file (MONITOR)" \
     help "monitor" \
     widget USE_MONITOR \
	-toggleon \
     label "Monitor every" \
     widget MONITOR \
     label "reflection"

#-------------------------------------------------------------------truncate

  OpenFolder 6 IMPORT_TRUNCATE_PROG hide [list CTRUNCATE] closed

  truncate_options $arrayname

  # Initialise labels
  import_scaled_truncate_labout $arrayname
 }
