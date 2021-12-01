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
# demo.tcl --
#
# CCP4Interface 
#
# =======================================================================

# procedure which is run automatically before drawing the interface
# used to set up variables, menus etc
#---------------------------------------------------------------------
proc demo_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0  $typedefVar typedef
  upvar #0 $arrayname array

# Define the 'refinement type' and 'input phase' menus

  DefineMenu _demo_refine_type [list "full refinement" \
					"quick refinement" ] \
				   [ list FULL \
				          FAST ] 

  DefineMenu _demo_input_phase [list "input phases" \
				         "no phase input" ] \
				   [list PHASE \
					 NO ]

# procedure must return sucess code (1) for drawing task window to continue
  return 1
}
					
#---------------------------------------------------------------------
proc demo_run { arrayname } {
#---------------------------------------------------------------------
# this procedure is run when user clicks the 'Run' button
# used to check user input and where necessary convert parameters
# to form required by the program run script

  upvar #0 $arrayname array

#The labin depends on the INPUT_PHASE mode selected by the user
#Get the 'alias' for the currently selected value of INPUT_PHASE
# and if it matchs "PHASE" then include the phase labels in the labin

  if [regexp PHASE [GetValue $arrayname INPUT_PHASE]] {
    set array(LABIN) "FP SIGFP PHIB FOMB"
  } else {
    set array(LABIN) "FP SIGFP"
  }

# procedure must return sucess code (1) for running job to continue
  return 1
}

#---------------------------------------------------------------------
proc demo_refine_range { arrayname counter } {
#---------------------------------------------------------------------
#procedure to draw one line of the 'refinement range' extending frame
  upvar #0 $arrayname array

  CreateLine line \
        message "Enter range of residues to refine" \
        label "Chain" \
        widget CHAIN1 \
        label "from residue" \
        widget RES1 \
        label "to residue" \
        widget RES2

}

# procedure to draw task window
#---------------------------------------------------------------------
proc demo_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
    	"Task Template" "Template" \
        [ list "Required Parameters"  \
	"Define Protein Ranges to Refine" \
	"Crystal Parameters" ] ] == 0 } return

# Set the name of the CCP4 program help file to use
# (set it to refmac because it is most suitable program for this example!)
  SetProgramHelpFile "refmac"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
        message "Refinement method (REFI TYPE)" \
	help refi_type \
        label "Do" \
        widget REFINE_TYPE  \
        label "using" \
        widget INPUT_PHASE

#=FILES================================================================

  OpenFolder file 
  
  CreateInputFileLine line \
	"Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
       HKLIN DIR_HKLIN \
       -fileout HKLOUT DIR_HKLOUT "_demo" \
       -setfileparam space_group_name SPACE_GROUP \
	-setfileparam cell_4 CELL_1 \
	-setfileparam cell_4 CELL_2 \
	-setfileparam cell_4 CELL_3 \
	-setfileparam cell_4 CELL_4 \
	-setfileparam cell_5 CELL_5 \
	-setfileparam cell_6 CELL_6 \
	-setfileparam resolution_min EXCLUDE_RESOLUTION_MIN \
	-setfileparam resolution_max EXCLUDE_RESOLUTION_MAX

  CreateLabinLine line \
	"Observed amplitude (FP) and obligatory sigma (SIGFP)" \
	HKLIN FP FP  [list FP F_P] \
        -sigma Sigma SIGFP [list SIGFP SIGF_P SIGP]

  CreateLabinLine line \
	"Input phase (PHIB) and figure of merit (FOMB)" \
	HKLIN PHIB PHIB  PHIB \
        -sigma FOMB FOMB FOMB \
        -toggle_display INPUT_PHASE open PHASE

  CreateOutputFileLine line \
	"Output MTZ File" \
	"MTZ out" \
	HKLOUT DIR_HKLOUT

 CreateInputFileLine line \
        "Enter input coordinate file name (XYZIN)" \
      "PDB in" \
       XYZIN DIR_XYZIN \
       -fileout XYZOUT DIR_XYZOUT "_refmac"

  CreateOutputFileLine line \
        "Output coordinate file" \
        "PDB out" \
        XYZOUT DIR_XYZOUT

#-----------------------------------------------------Required parameters

  OpenFolder 1

  CreateLine line \
	message "Number of cycles of refinement (NCYC)" \
	help refi_ncyc \
        label "Number of refinement cycles" \
	widget NCYCLES \
	  -width 3 

  CreateLine line \
	message "Apply resolution limits (REFI RESOlution)" \
	help refi_reso \
	widget EXCLUDE_RESOLUTION \
	message "Minimum resolution" \
	label "Resolution range from minimum" \
	widget EXCLUDE_RESOLUTION_MIN \
	message "Maximum resolution" \
	label " to " \
	widget EXCLUDE_RESOLUTION_MAX

#--------------------------------------------------------refinement range

  OpenFolder 2

  CreateExtendingFrame NRANGES demo_refine_range \
        "Define range(s) of residue ranges to refine" \
        "Add Residue Range" \
       [ list CHAIN1 \
        RES1 \
        RES2 ]


#-------------------------------------------------------------cell parameters

  OpenFolder 3 closed

  CreateLine line \
	message "Space group (default from MTZ) (SYMM)" \
	label "Space group" \
	widget SPACE_GROUP

  CreateLine line \
	message "Cell dimensions (default from MTZ) (CELL)" \
	label "Cell a" \
	widget CELL_1 \
	label "b" \
	widget CELL_2 \
	label "c" \
	widget CELL_3 \
	label "alpha" \
	widget CELL_4 \
	label "beta" \
	widget CELL_5 \
	label "gamma" \
	widget CELL_6

}

