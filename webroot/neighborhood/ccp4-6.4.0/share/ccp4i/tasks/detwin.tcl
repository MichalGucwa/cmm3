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
# detwin.tcl --
#
# task interface for truncate program 
# Also uses rwcontents
#
# CCP4Interface 
#
# =======================================================================

#-------------------------------------------------------------------------
proc detwin_run { arrayname } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array

  # Check that a valid operator was selected from the list
  if { [GetValue $arrayname TWIN_OP_MODE] == "STD" && $array(OPERATOR) == "None" } {
    WarningMessage "A valid twinning operator is needed to
performing detwinning, but one has not been
specified.

This may be because there are no twinning
operators for this spacegroup."
    return 0
  }

  switch [GetValue $arrayname DETWIN_DATA] \
  SCALA { set array(LABIN) ""
  } SFS { set array(LABIN) "F SIGF"
  } FPLUS { set array(LABIN) "Fp SIGFp Fm SIGFm"
  } IMEAN { set array(LABIN) "IMEAN SIGIMEAN"
  } IPLUS { set array(LABIN) "Ip SIGIp Im SIGIm" }

  switch [GetValue $arrayname DETWIN_MODE] \
  DETWIN { set array(OUTPUT_FILES) HKLOUT
  } ANALYSIS { set array(OUTPUT_FILES) "" }

  return 1
}

#---------------------------------------------------------------
proc detwin_operator { arrayname } {
#---------------------------------------------------------------
  upvar #0 $arrayname array

  set ops None
  GetTwinData $array(SPACE_GROUP) ops
  UpdateVariableMenu $arrayname initialise 0 TWIN_OPS_MENU  $ops \
		TWIN_OPS_ALIAS $ops
  set array(OPERATOR)  [lindex $ops 0]

}


#---------------------------------------------------------------
proc detwin_setup { typedefVar arrayname } {
#---------------------------------------------------------------
  upvar #0 $typedefVar typedef

set typedef(_detwin_mode)	{ menu	{	"Do analysis to determine twinning fraction"
						"Generate detwinned data" }
					{	ANALYSIS
						DETWIN } }


set typedef(_detwin_data)	{ menu {	"default from Scala"
						"Fmean"
						"F+ and F-"
						"Imean"
						"I+ and I-" }
					{	SCALA
						SFS
						FPLUS
						IMEAN
						IPLUS } }


set typedef(_twin_op_mode)	{ menu { "choosing a standard transformation"
                                         "entering reflection transformation" }
					{ STD HKL } }

set typedef(_twin_operator)  { varmenu TWIN_OPS_MENU  {} 30 }

  return 1

}
						

#-------------------------------------------------------------------------
proc detwin_task_window { arrayname } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array

  SetProgramHelpFile "detwin"

  if { [CreateTaskWindow $arrayname  \
        "Detwin - Treat Twinned Data" "Detwin" \
        [ list "Required Parameters"  ] ] == 0 } return

  detwin_operator $arrayname

  OpenFolder protocol

  CreateTitleLine line TITLE
 
  CreateLine line \
    message "Chose mode of action" \
    widget DETWIN_MODE \
    message "Type of data in input MTZ file?" \
    label "for input data" \
    widget DETWIN_DATA


#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
        "Enter input MTZ file name (HKLIN)" \
        "MTZ in" \
        HKLIN DIR_HKLIN \
        -fileout HKLOUT DIR_HKLOUT "_detwin" \
	-setfileparam space_group_name SPACE_GROUP \
        -setfileparam resolution_min EXCLUDE_RESOLUTION_MIN \
        -setfileparam resolution_max EXCLUDE_RESOLUTION_MAX \
	-command "detwin_operator $arrayname"

  CreateLabinLine line \
    "Choose input structure amplitude (F) and sigma (SIGF)" \
     HKLIN "F" F  { F FP } \
     -sigma "SigF" SIGF  {} \
     -toggle_display DETWIN_DATA open SFS



  CreateLabinLine line \
    "Choose input mean intensity (IMEAN) and sigma (SIGIMEAN)" \
     HKLIN "Imean" IMEAN  IMEAN\
     -sigma "SigImean" SIGIMEAN  {} \
     -toggle_display DETWIN_DATA open IMEAN


  OpenSubFrame frame -toggle_display DETWIN_DATA open FPLUS

  CreateLabinLine line \
    "Choose input amplitude (F(+)) and sigma (SIGF(+))" \
     HKLIN "F(+)" Fp  "F(+)" \
     -sigma "SigF(+)" SIGFp  {} 

    CreateLabinLine line \
    "Choose input amplitude (F(-)) and sigma (SIGF(-))" \
     HKLIN "F(-)" Fm  "F(-)" \
     -sigma "SigF(-)" SIGFm  {}

  CloseSubFrame

  OpenSubFrame frame -toggle_display DETWIN_DATA open IPLUS

  CreateLabinLine line \
    "Choose input intensity (I(+)) and sigma (SIGI(+))" \
     HKLIN "I(+)" Ip  "I(+)" \
     -sigma "SigI(+)" SIGIp  {} 

    CreateLabinLine line \
    "Choose input intensity (I(-)) and sigma (SIGI(-))" \
     HKLIN "I(-)" Im  "I(-)" \
     -sigma "SigI(-)" SIGIm  {}

  CloseSubFrame


  CreateOutputFileLine line \
      "Enter name of output MTZ file (HKLOUT)" \
      "MTZ out" \
      HKLOUT DIR_HKLOUT \
	-toggle_display DETWIN_MODE open DETWIN


#=PARAMETERS==========================================================

  OpenFolder 1 open

  CreateLine line \
    message "Define transformation matrix" \
    label "Define twinning operator matrix by " \
    widget TWIN_OP_MODE

  CreateLine line \
    message "Twinning operator - indices of the reflection related to h,k,l (OPERATOR)" \
    label "For space group" \
    widget SPACE_GROUP \
	-command "detwin_operator $arrayname" \
    label "use twinning operator" \
    widget OPERATOR \
    toggle_display TWIN_OP_MODE open STD

  CreateLine line \
    message "Input twinning operator in form like 'h -k -h/2-l/2' (OPERATOR)" \
    help reindex \
    label "Use matrix h=" \
    widget TWIN_H \
    label "  k=" \
    widget TWIN_K \
    label "  l=" \
    widget TWIN_L \
    toggle_display TWIN_OP_MODE open HKL

  CreateLine line \
    message "Apply twinning fraction to detwin the data (TWIN_FRACTION)" \
    label "Twin fraction applied to untwin data"  \
    widget TWIN_FRACTION \
    toggle_display DETWIN_MODE  open DETWIN 

  CreateLine line \
    message "Test data where either Itw1 and Itw2 are greater than Fsig * SigI(SIGMA)" \
    label "Sigma cutoff for test" \
    widget SIGMA


  CreateLine line \
    message "Exclude reflections below and/or above resolution limit in \
                  Angstrom (RESOLUTION)" \
    help "resolution" \
    widget EXCLUDE_RESOLUTION \
        -toggleon \
    label "Exclude reflections resolution less than" \
    widget EXCLUDE_RESOLUTION_MIN \
    label "or greater than" \
    widget EXCLUDE_RESOLUTION_MAX


  CreateLine line \
    message "Create scatter plot of F1 v F2" \
    label "Murray Rust Plot" \
    widget PLOT

}
