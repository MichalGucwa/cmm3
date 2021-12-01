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
# dtrek2mtz.tcl --
#
# Import a formatted reflection file from D*TREK and create multirecord
#   MTZ file - convert to SFs using truncate
#
# CCP4Interface 
# Created Oct00 by C.Ballard from scalepack2mtz
#
# =======================================================================

source [SearchPath TOP tasks truncate.tcl]


#------------------------------------------------------------------------
proc dtrek2mtz_setup { typedefname arrayname }  {
#------------------------------------------------------------------------
  upvar #0 $typedefname typedef

  truncate_setup $typedefname $arrayname

  return 1

}


#---------------------------------------------------------------------
proc dtrek2mtz_run { arrayname } {
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

#=======================================================================
proc dtrekRejects {  arrayname i } {
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
proc dtrek2mtz_task_window { arrayname } {
#-------------------------------------------------------------------------

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"dtrek2MTZ - Import Scaled d*trek Data" "dtrek" \
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
       -fileout HKLOUT DIR_HKLOUT --

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

  SetProgramHelpFile dtrek2mtz

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
