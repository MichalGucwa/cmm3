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
# reindex.tcl --
# =======================================================================


#-----------------------------------------------------------------------
proc reindex_setup { typedefname arrayname } { 
#-----------------------------------------------------------------------
  upvar #0 $typedefname typedef

set typedef(_reindex_mode)	{ menu { "choosing a standard transformation"
				"entering reflection transformation" 
                                "defining new reciprocal axes" 
                                "matching reciprocal vectors"  }
					{ STD HKL AXIS MATCH } }

set typedef(_reindex_operator)  { varmenu REINDEX_OPS_MENU  {} 15 }

return 1

}


#-----------------------------------------------------------------------
proc reindex_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  return 1
}

#---------------------------------------------------------------
proc reindex_operator { arrayname } {
#---------------------------------------------------------------
  upvar #0 $arrayname array

#Update the 'standard' opreators when user selects an MTZ file

  set ops None
  if { [file exists [set filename [GetFullFileName0 $arrayname HKLIN]]] &&
    [GetParamFromFile MTZ $filename SPACE_GROUP_NAME space_group] &&
    [GetTwinData $space_group ops] } {
    set ops [linsert $ops 0 "h,k,l"]
  } else {
    set ops [list None ]
  }
  UpdateVariableMenu $arrayname initialise 0 REINDEX_OPS_MENU  $ops \
                REINDEX_OPS_ALIAS $ops

#Reset the operator only if it is not in the list of possible operators

  if {[lsearch -exact $ops $array(OPERATOR)] < 0} {
    set array(OPERATOR)  [lindex $ops 0]
  }

  if { [lsearch -regexp $ops None] < 0 } {
      reindex_update_matrix $arrayname }
}

#---------------------------------------------------------------
proc reindex_update_matrix { arrayname } {
#---------------------------------------------------------------
  upvar #0 $arrayname array
# Set the REINDEX parameters from the user selected 'standard' operator
# These are values used by reindex
  set trans [split $array(OPERATOR) ,]
  set array(REINDEX_H) [lindex $trans 0]
  set array(REINDEX_K) [lindex $trans 1]
  set array(REINDEX_L) [lindex $trans 2]
}

#----------------------------------------------------------------------
proc  reindex_task_window { arrayname } {
#----------------------------------------------------------------------

  upvar #0 $arrayname array
  
  if { [CreateTaskWindow $arrayname  \
        "Reindex Reflections" Reindex \
        [ list "Reindex Details" \
               "Advanced reindexing options" ] ] == 0 } return

  SetProgramHelpFile reindex

  OpenFolder protocol 

  CreateTitleLine line TITLE

  OpenFolder file 

  CreateInputFileLine line \
    "Enter input MTZ file name (HKLIN)" \
     "MTZ in" \
     HKLIN DIR_HKLIN \
     -fileout HKLOUT DIR_HKLOUT _reindex  \
     -command "reindex_operator $arrayname"

  CreateOutputFileLine line \
        "Enter merged/sorted MTZ file name (HKLOUT)" \
        "MTZ out" \
        HKLOUT DIR_HKLOUT 


#-----------------------------------------------------reindex
  OpenFolder 1 

  CreateLine line \
    message "Define transformation matrix (REINDEX or MATCH)" \
    help reindex \
    label "Define transformation matrix by " \
    widget REINDEX_MODE

  CreateLine line \
    message "Reindexing matrix (REINDEX)" \
    help reindex \
    label "Apply reindex matrix" \
    widget OPERATOR \
      -command "reindex_update_matrix $arrayname" \
    toggle_display REINDEX_MODE open STD

  CreateLine line \
    message "Input reindexing matrix in form like 'h -k -h/2-l/2' (REINDEX)" \
    help reindex \
    label "Use matrix h=" \
    widget REINDEX_H \
    label "  k=" \
    widget REINDEX_K \
    label "  l=" \
    widget REINDEX_L \
    toggle_display REINDEX_MODE open HKL

  CreateLine line \
    message "Input reindexing definition as applied to reciprocal axes(REINDEX)" \
    help reindex \
    label "Set a* =" \
    widget REINDEX_A \
    label "  b*=" \
    widget REINDEX_B \
    label "  c*=" \
    widget REINDEX_C \
    toggle_display REINDEX_MODE open AXIS

  CreateLine line \
    message "Input reindexing definition in terms of matching reciprocal axes(MATCH)" \
    help reindex \
    label "Match equation" \
    widget REINDEX_MATCH -width 60 \
    toggle_display REINDEX_MODE open MATCH

  CreateLine line \
    message "Specify new spacegroup for new MTZ file (SYMMETRY)" \
    help symmetry \
    widget CHANGE_SPACE_GROUP -toggleon \
    label "Change spacegroup to" \
    widget SPACE_GROUP

  CreateLine line \
    message "NO reduce allowed for merged files only (NOREDUCE)" \
    help noreduce \
    widget IFREDUCE \
    label "Reduce reflections to the asymmetric unit"

  reindex_operator $arrayname

#-----------------------------------------------------advanced
  OpenFolder 2 closed

  CreateLine line \
    message "Allow the reindexing to invert the hand (nb NORMALLY UNWISE) (LEFTHAND)" \
    widget IFLEFTHAND \
    label "Invert the hand"
}
