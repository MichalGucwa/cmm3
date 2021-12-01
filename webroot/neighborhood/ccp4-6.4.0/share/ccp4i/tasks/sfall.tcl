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
# sfall.tcl --
#
# Run sfall in sfcalc mode
#
# CCP4Interface 
#
# ======================================================================

#-----------------------------------------------------------------------
proc sfall_setup { typedefVar arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array
  upvar #0 $typedefVar typedef

  set typedef(_sfall_sfcalc_mode) { menu { "a map"
					"coordinates"  }
					{ MAPIN XYZIN } }

  DefineMenu _sfall_columns_out \
	  [ list "FP SIGFP and FreeRflag" \
	         "all columns" ] \
		 [ list FPONLY ALL ]

  return 1
}
#-----------------------------------------------------------------------
proc sfall_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [GetValue $arrayname SFALL_COLUMNS_OUT] == "ALL" } {
    set array(ALLIN) 1
  } else {
    set array(ALLIN) 0
  }

  set array(INPUT_FILES) [GetValue $arrayname SFALL_SFCALC_IN]
  if { $array(SFALL_SFCALC_HKLIN) } { 
    append array(INPUT_FILES) " HKLIN"
    set array(HARVEST_INPUT_NAMES) 0

    # Check label assignments
    if { $array(ALLIN) == 0 } {
      if { [regexp "^Unassigned\$" $array(FP)] || \
           [regexp "^Unassigned\$" $array(SIGFP)] } {
        WarningMessage "No labels have been assigned
for FP and/or Sigma.

You must assign both labels
before running this task."
        return 0
      }
    } else {

      # Check if the input file contains labels that might clash with
      # those assigned by the user
      # Loop over all defined output labels
      foreach label $array(LABOUT) {
        set ncol [GetMtzColumnList [GetFullFileName0 $arrayname HKLIN] \
                  name_list type_list def_name * ]]
        # Loop over all columns in the file
        for { set n 0 } { $n < $ncol } { incr n } {
          if { [regexp "^[subst $array($label)]\$" [lindex $name_list $n]] } {
            WarningMessage "The input file 

[GetFullFileName0 $arrayname HKLIN]

already contains a column labelled

\"$array($label)\"

which clashes with the name of a new label
which will be created by this run.

You must choose a different name for the
new column in the interface, before rerunning
this task."
            return 0
          }
        # End of loop over columns
        }
      # End of loop over LABOUT labels
      }
    }

  } else {
    set array(HARVEST_INPUT_NAMES) 1
  }

  return 1
}

#-----------------------------------------------------------------------
proc sfall_set_sfcalc_scale { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [GetValue $arrayname SFALL_COLUMNS_OUT] == "ALL" } {
    set array(SFALL_SFCALC_SCALE) 0
  } else {
    set array(SFALL_SFCALC_SCALE) 1
  }

  return 1
}

#-----------------------------------------------------------------------
proc sfall_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Calculate Fs and Phases" "Sfall" \
        [ list "Crystal Parameters" \
	"Program Parameters" ] ] == 0 } return

  SetProgramHelpFile sfall
  SetHarvestParams $arrayname {}  -init

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
    label "Generate structure factors and phases from" \
    help mode \
    widget SFALL_SFCALC_IN

  CreateLine line \
    help mode_sfcalc_hklin \
    widget SFALL_SFCALC_HKLIN \
    label "Append FC and PHIC to" \
    widget SFALL_COLUMNS_OUT \
      -command "sfall_set_sfcalc_scale $arrayname" \
    label "from existing MTZ file and" \
    widget SFALL_SFCALC_SCALE \
    label "scale input FP to FCalc"


#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter PDB file name (XYZIN)" \
      "Coordinates" \
      XYZIN DIR_XYZIN \
        -toggle_display SFALL_SFCALC_IN open XYZIN \
        -help notes_on_xyzin

  CreateInputFileLine line \
      "Enter input map (MAPIN)" \
        "Map" \
        MAPIN DIR_MAPIN \
        -toggle_display SFALL_SFCALC_IN open MAPIN \
        -help notes_on_mapin

  OpenSubFrame frame -toggle_display SFALL_SFCALC_HKLIN open 1

  CreateInputFileLine line \
      "Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
       HKLIN DIR_HKLIN \
       -setfileparam space_group_name SPACE_GROUP \
	-setfileparam resolution_min RESOLUTION_MIN \
        -setfileparam resolution_max RESOLUTION_MAX \
	-setfileparam cell CELL \
	-fileout HKLOUT DIR_HKLOUT _sfall

  CreateLabinLine line \
    "Choose amplitude (FP) and sigma (SIGFP)" \
     HKLIN FP  FP  FP \
     -sigma Sigma SIGFP  SIGFP

  CreateLabinLine line \
    "Choose Free R column data (LABIN FREER)" \
    HKLIN FreeR FREE  [list FREE FreeR FreeR_flag]

  CloseSubFrame


  CreateOutputFileLine line \
      "Enter name of output file (HKLOUT)" \
       "Output" HKLOUT DIR_HKLOUT \
	-help notes_on_hklout

  CreateLaboutLine line \
    "Enter names for output column labels for calculated Fs and PHIs (LABOUT)" \
    HKLOUT Fcalc FC \
    -sigma PHIcalc PHIC
     

#=PARAMETERS==========================================================


  OpenFolder 1

  OpenSubFrame frame -toggle_display SFALL_SFCALC_HKLIN open 0

  CreateLine line \
    label "Optionally get crystal parameters from" -italic 

  CreateInputFileLine line \
      "Enter name of MTZ file from which to get crystal parameters" \
      "MTZ file" \
       HKLIN DIR_HKLIN \
       -setfileparam space_group_name SPACE_GROUP \
	-setfileparam resolution_min RESOLUTION_MIN \
        -setfileparam resolution_max RESOLUTION_MAX \
	-setfileparam cell CELL \
       -command "UpdateHarvestMTZ $arrayname HKLIN"

  CloseSubFrame

  CreateLine line \
    message "Exclude reflections below and/or above resolution limit in \
                  Angstrom (RESOLUTION)" \
    help resolution \
    widget  SFALL_RESOLUTION  -toggleon \
    label "Resolution less than" \
    widget RESOLUTION_MIN  \
    label "A or greater than" \
    widget RESOLUTION_MAX  \
    label "A"

  CreateLine line \
    message "Space group (default as in MTZ file) (SYMMETRY)" \
    label "Generate map in space group" \
    help symmetry \
    widget SPACE_GROUP 

  CreateLine line \
    message "Cell dimensions (default from MTZ file) (CELL)" \
    help "cell" \
    widget IFCELL \
        -toggleon \
    label "Set cell a" \
    widget CELL_1 -width 8 \
    label "b" \
    widget CELL_2 -width 8 \
    label "c" \
    widget CELL_3 -width 8 \
    label "alpha" \
    widget CELL_4 -width 8 \
    label "beta" \
    widget CELL_5 -width 8 \
    label "gamma" \
    widget CELL_6 -width 8 

  OpenSubFrame frame -toggle_display SFALL_SFCALC_HKLIN open 0

  CreateHarvestLine line  -noharv

  CloseSubFrame

#  CreateLine line \
#    message "Override default grid spacing" \
#    help grid \
#    label "Grid spacing x= " \
#    widget GRID_1 \
#    label " y= " \
#    widget GRID_2 \
#    label " z= " \
#    widget GRID_3
#
#  OpenFolder 2
#
#  CreateExtendingFrame NCHAINS MapCorrelChains \
#        "Add/remove line to define extra protein chain" \
#        "Add chain" \
#        [ list CHAIN_NAME \
#		CHAIN_RES1 \
#		CHAIN_RES2 ]
  

  OpenFolder 2 -closed

  CreateLine line \
    message "Resolution dependent (Sfall VDWR)" \
    label "Maximum atomic radius used to build atom/residue mask" \
    help vdwr \
    widget SFALL_VDWR 

  CreateLine line \
    message "Add smearing factor (NOT recommended) (Sfall BADD)" \
    label "add to atomic Bfactors" \
    help badd \
    widget SFALL_BADD

}
