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
# scalepack2mtz.tcl --
#
# Import a formatted reflection file from DENZO and create multirecord
#   MTZ file - convert to SFs using truncate
#
# CCP4Interface 
# Created Oct97 by Liz Potterton
#
# =======================================================================

source [SearchPath TOP tasks truncate.tcl]


#------------------------------------------------------------------------
proc scalepack2mtz_setup { typedefname arrayname }  {
#------------------------------------------------------------------------
  upvar #0 $typedefname typedef

  truncate_setup $typedefname $arrayname

  return 1

}


#---------------------------------------------------------------------
proc scalepack2mtz_run { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { $array(USE_LABOUT) } {
    if { $array(ANOMALOUS) } {
      set array(LABOUT) "IMEAN SIGIMEAN Ip SIGIp Im SIGIm F SIGF DANO SIGDANO Fp SIGFp Fm SIGFm ISYM"
    } else {
      set array(LABOUT) "IMEAN SIGIMEAN F SIGF"
    }
  }

  if { ![SetHarvestParams $arrayname {}  -run] } { return 0 } 
    

  return 1
}

#----------------------------------------------------------------------
proc read_scalepack_header { arrayname } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array

# Read the 3rd line of the scalepack file to get cell and perhaps spacegroup

  set filename [GetFullFileName0 $arrayname HKLIN]

  if { [file exists $filename]  && [OpenFile $filename f r ] } { 

    for { set n 1 } { $n <= 3 } { incr n } { catch "gets $f line" }
    if { [llength $line] >= 6 } {
      set ii -1; for { set i 1 } { $i <= 6 } { incr i } { incr ii
        set array(CELL_$i) [lindex $line $ii]
#        SimulateReturn $arrayname CELL_$i
      }
      if { [llength $line] >= 7 } { 
        set array(SPACE_GROUP) [lindex $line 6] 
#        SimulateReturn $arrayname SPACE_GROUP
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
}



#=======================================================================
proc ScalepackRejects {  arrayname i } {
#=======================================================================
  CreateLine line \
    message "Enter h,k,l for reflection to be excluded from output file" \
    help "reject"   \
    label "Reject reflection(s) h" \
    widget REJECT1_H \
    label "k" \
    widget REJECT1_K \
    label "l" \
    widget REJECT1_L \
    label "   and h" \
    widget REJECT2_H \
    label "k" \
    widget REJECT2_K \
    label "l" \
    widget REJECT2_L 
}

  
#-------------------------------------------------------------------------
proc scalepack2mtz_task_window { arrayname } {
#-------------------------------------------------------------------------

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Scalepack2MTZ - Import Scaled Denzo Data" "Scalepack" \
	[ list "MTZ Project & Dataset Names & Data Harvesting" \
	"MTZ Project & Dataset Names" \
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
    message "Use anomalous data (ANOMALOUS)" \
    widget ANOMALOUS \
    label "Use anomalous data" \
    toggle_display FORMAT open SCALEPACK

  SetProgramHelpFile truncate

  CreateLine line \
    message "Convert input intensities to structure factors" \
    widget RUN_TRUNCATE \
    label "Run Truncate to convert intensities to structure factors"

  UniqueifyFrame1 $arrayname


#=FILES================================================================

  CreateInputFileLine line \
      "Enter input reflection file name (HKLIN)" \
        "In" \
       HKLIN DIR_HKLIN \
       -fileout HKLOUT DIR_HKLOUT -- \
       -command "read_scalepack_header $arrayname"

  UniqueifyFrame2

  CreateOutputFileLine line \
      "Enter output MTZ file name (HKLOUT)" \
       "Out" \
       HKLOUT DIR_HKLOUT \
       -info

  CreateLine line \
    message "Enter an identifier for this data set to append to column labels" \
    label "Identifier to append to column labels" \
    widget LABOUT_LABEL \
        -command "truncate_labout $arrayname"

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

  OpenFolder 6 closed

  truncate_options $arrayname

 }
