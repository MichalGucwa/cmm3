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
# sortmtz.tcl --
# =======================================================================


#-----------------------------------------------------------------------
proc sortmtz_setup { typedefname arrayname } { 
#-----------------------------------------------------------------------
  upvar #0 $typedefname typedef

set typedef(_scala_sort)	{ menu {	"ascending"
						"descending" } 
					{	"ASCEND"  
						"DESCEND" } }
set typedef(_sortmtz_batch_select) { menu { "All batches" "Batch range" } 
					{ ALL RANGE } }

set typedef(_sortmtz_batch_edit) { menu { "increment by" "renumber from" } { ADD START } }

set typedef(_reindex_mode)      { menu { "choosing a standard transformation"
                                "entering reflection transformation"
                                "defining new reciprocal axes"
                                "matching reciprocal vectors"  }
                                        { STD HKL AXIS MATCH } }

set typedef(_reindex_operator)  { varmenu REINDEX_OPS_MENU REINDEX_OPS_ALIAS 15 }

return 1

}

#---------------------------------------------------------------
proc reindex_operator { arrayname } {
#---------------------------------------------------------------
  upvar #0 $arrayname array
#Update the 'standard' operators when user selects an MTZ file

  set ops None
  if { [file exists [set filename [GetFullFileName0 $arrayname HKLIN]]] &&
    [GetParamFromFile MTZ $filename SPACE_GROUP_NAME space_group] &&
    [GetTwinData $space_group ops] } {
    set ops [linsert $ops 0 "h,k,l" ]
  } else {
    set ops [list None ]
  }
  UpdateVariableMenu $arrayname initialise 0 REINDEX_OPS_MENU  $ops \
                REINDEX_OPS_ALIAS $ops
  set array(OPERATOR)  [lindex $ops 0]

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



#-----------------------------------------------------------------------
proc sortmtz_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(INPUT_FILES) ""
  if { $array(ONEINPUTFILE) } {
    set array(INPUT_FILES) HKLIN
  } else {
    set array(INPUT_FILES) ""
    for { set n 1 } { $n <= $array(N_SORT_HKLIN) } { incr n } {
      append array(INPUT_FILES) " SORT_HKLIN,$n"
    }
  }

  return 1
}

#-----------------------------------------------------------------------
proc scala_sort_hklin { arrayname counter } {
#-----------------------------------------------------------------------

    CreateInputFileLine line \
      "Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
       SORT_HKLIN DIR_SORT_HKLIN \
	-command "sortmtz_set_sort $arrayname"
}

#----------------------------------------------------------------------
proc sortmtz_set_sort { arrayname } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { $array(IFREINDEX) } {
    set ncol [GetMtzColumnList [GetFullFileName0 $arrayname HKLIN] \
			name_list type_list def_name * ] 
  } else {
    set ncol [GetMtzColumnList [GetFullFileName0 $arrayname SORT_HKLIN,1] \
		name_list type_list def_name * ] 
  }
  if { $ncol > 0 } {
    set array(SORT_KEYS) "H K L"
    if { [lsearch $name_list "M/ISYM" ] > -1 } { append array(SORT_KEYS) " M/ISYM" }
    if { [lsearch $name_list "BATCH" ] > -1 } { append array(SORT_KEYS) " BATCH" }
  } 

}

#------------------------------------------------------------------
proc Sortmtz_oneinputfile { arrayname } {
#------------------------------------------------------------------
   upvar #0 $arrayname array

  if { $array(IFREINDEX) || $array(IFREBATCH) } {
    set array(ONEINPUTFILE) 1
  } else {
    set array(ONEINPUTFILE) 0
  }
}

#----------------------------------------------------------------------
proc Sortmtz_rebatch { arrayname counter } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array

  CreateLine line \
    label "For" \
    widget BATCH_SELECT_MODE \
    widget  BATCH_EDIT_MODE \
    widget BATCH_NUMBER -oblig \
    toggle_display BATCH_SELECT_MODE,$counter open ALL


    CreateLine line \
    label "For" \
    widget BATCH_SELECT_MODE \
    widget BATCH_RANGE_1 -oblig \
    label to \
    widget BATCH_RANGE_2 -oblig \
    widget  BATCH_EDIT_MODE \
    widget BATCH_NUMBER -oblig \
    toggle_display BATCH_SELECT_MODE,$counter open RANGE

}


#----------------------------------------------------------------------
proc  sortmtz_task_window { arrayname } {
#----------------------------------------------------------------------

  upvar #0 $arrayname array
  
  if { [CreateTaskWindow $arrayname  \
        "Sort/Reindex MTZ Files" "Sort/Reindex" \
        [ list "Reindex Details" \
               "Advanced reindexing options" \
               "Edit Batch Numbers" "Sorting Details" ] ] == 0 } return


  SetProgramHelpFile reindex

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
    message "Run Reindex to change indexing and/or spacegroup" \
    widget IFREINDEX \
	-command "Sortmtz_oneinputfile $arrayname" \
    label "Change space group and/or reindex reflections"


  SetProgramHelpFile rebatch

  CreateLine line \
    message "Run Rebatch program to edit the batch numbers" \
    widget IFREBATCH \
	-command "Sortmtz_oneinputfile $arrayname" \
    label "Reset the batch number(s)"


  OpenFolder file 

  OpenSubFrame frame -toggle_display ONEINPUTFILE open 0

  SetProgramHelpFile "sortmtz"

  CreateLine line \
    label "Unsorted MTZ file(s):" \
        -italic

  CreateExtendingFrame N_SORT_HKLIN scala_sort_hklin \
    "Enter name of MTZ file to sort" \
    "Add File" \
    [list SORT_HKLIN \
	  DIR_SORT_HKLIN ]

  CloseSubFrame

  CreateInputFileLine line \
    "Enter input MTZ file name (HKLIN)" \
     "MTZ in" \
     HKLIN DIR_HKLIN \
     -fileout HKLOUT DIR_HKLOUT _sort  \
     -command "sortmtz_set_sort $arrayname"  \
     -command "reindex_operator $arrayname" \
     -toggle_display ONEINPUTFILE open 1 \
     -setfileparam space_group_name SPACE_GROUP

    CreateLine line \
    label "Output MTZ file:" -italic \
    toggle_display ONEINPUTFILE open 0

  CreateOutputFileLine line \
        "Enter merged/sorted MTZ file name (HKLOUT)" \
        "MTZ out" \
        HKLOUT DIR_HKLOUT 


#-----------------------------------------------------reindex
  OpenFolder 1 IFREINDEX open  1 hide

  SetProgramHelpFile reindex

  CreateLine line \
    message "Define transformation matrix (REINDEX or MATCH)" \
    help reindex \
    label "Define transformation matrix by defining new" \
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

#-----------------------------------------------------advanced reindex
  OpenFolder 2 IFREINDEX closed 1 hide

  CreateLine line \
    message "Allow the reindexing to invert the hand (nb NORMALLY UNWISE) (LEFTHAND)" \
    widget IFLEFTHAND \
    label "Invert the hand"

#--------------------------------------------------------------rebatch
  OpenFolder 3 IFREBATCH  open  1 hide

  CreateExtendingFrame N_BATCH Sortmtz_rebatch  \
    "Select batch range and the edit mode" \
    "Add a batch edit" \
    [list BATCH_SELECT_MODE BATCH_EDIT_MODE BATCH_NUMBER BATCH_RANGE_1 BATCH_RANGE_2 ]


#-------------------------------------------------------Sortmtz
  OpenFolder 4 

  SetProgramHelpFile sortmtz

  CreateLine line \
    label "Sort in" \
    widget SORT_ASCEND \
    label "order of" \
    widget SORT_KEYS \
	-width 30
    
  reindex_operator $arrayname
}

