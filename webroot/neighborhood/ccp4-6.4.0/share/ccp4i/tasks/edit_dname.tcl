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
# edit_dname.tcl --
#
# Run CAD program to edit the datasets in an MTZ file, and to change
# dataset assignments of columns
#
# CCP4Interface 
#
# =======================================================================

#----------------------------------------------------------------------
proc edit_dname_setup { typedefVar arrayname } {
#----------------------------------------------------------------------
  upvar #0 $typedefVar typedef

set typedef(_mtz_assoc)     { varmenu DNAME_MENU {} 30 }
return 1

}

#----------------------------------------------------------------------
proc edit_dname_run { arrayname } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array

  for { set i 1 } { $i <= $array(NLABIN) } { incr i } {
      set array(ASSOCX,$i) [lindex $array(ASSOC,$i) 0]
      set array(ASSOCD,$i) [lindex $array(ASSOC,$i) 1]
  }

  # Set a flag to indicate that the parameters shouldn't be
  # updated on rerun
  set array(EDIT_DNAME_NO_UPDATE) 1

  return 1
}

#---------------------------------------------------------------------
proc edit_dname_update_menu { arrayname counter } {
#---------------------------------------------------------------------
# update DNAME_MENU when XNAME/DNAME fields are changed

  upvar #0 $arrayname array

  set array(PNAME,$counter) [RemoveMetaChars $array(PNAME,$counter)]
  set array(XNAME,$counter) [RemoveMetaChars $array(XNAME,$counter)]
  set array(DNAME,$counter) [RemoveMetaChars $array(DNAME,$counter)]
  if { $array(PNAME,$counter) != "" } { set status 1 } else { set status 0}
  set_field_colour $arrayname PNAME,$counter $status
  if { $array(XNAME,$counter) != "" } { set status 1 } else { set status 0}
  set_field_colour $arrayname XNAME,$counter $status
  if { $array(DNAME,$counter) != "" } { set status 1 } else { set status 0}
  set_field_colour $arrayname DNAME,$counter $status

  for { set i 1 } { $i <= $array(NLABIN) } { incr i } {
    if {$array(ASSOC,$i) == [lindex $array(DNAME_MENU) [expr $counter - 1] ]} {
       set array(ASSOC,$i) \
          "$array(XNAME,$counter) $array(DNAME,$counter)"
    }
  }
  UpdateVariableMenu $arrayname replace $counter DNAME_MENU  \
      "$array(XNAME,$counter) $array(DNAME,$counter)"

}

#---------------------------------------------------------------------
proc edit_dname_dname { arrayname counter } {
#---------------------------------------------------------------------
# adds line to list of datasets
# called when interface opened, when HKLIN read and upon Add dataset name

# Add initial value of _ to DNAME_MENU
  UpdateVariableMenu $arrayname append $counter DNAME_MENU _

  CreateLine line \
    label "Dataset id $counter :" \
    label "belongs to crystal" \
    message "Enter one-word crystal name (one for each crystal/derivative) (DRENAME)" \
    help drename \
    widget XNAME -oblig \
	-command "edit_dname_update_menu $arrayname $counter" \
    label "in project" \
    message "Enter one-word project name (usually only one name per MTZ) (DPNAME)" \
    help dpname \
    widget PNAME -oblig \
	-command "edit_dname_update_menu $arrayname $counter" \
    format template edit_dname_dname_1

  CreateLine line \
    label " " \
    label "dataset name" \
    message "Enter one-word dataset name (one for each dataset/wavelength) (DRENAME)" \
    help drename \
    widget DNAME -oblig \
	-command "edit_dname_update_menu $arrayname $counter" \
    format template edit_dname_dname_1

  CreateLine line2 \
    label " " \
    label "cell" \
    message "Enter cell parameters if different from preceding datasets (DCELL)" \
    help dcell \
    widget DCELL_1 \
    widget DCELL_2 \
    widget DCELL_3 \
    widget DCELL_4 \
    widget DCELL_5 \
    widget DCELL_6 \
    message "Enter wavelength if different from preceding datasets (DWAVELENGTH)" \
    help dwave \
    label "wavelength" \
    widget DWAVE \
    format template edit_dname_dname_2

}

#--------------------------------------------------------------------
proc edit_edit_dname_dname { arrayname counter } {
#--------------------------------------------------------------------
# when user has edited the dname list with "Edit List" then this 
# routine is called to update the dname_menu

  upvar #0 $arrayname array

  set menu ""
  if { $counter > 0 } {
  for { set i 1 } { $i <= $counter } { incr i } {
    lappend menu "$array(XNAME,$i) $array(DNAME,$i)"
  } }


  UpdateVariableMenu $arrayname initialise $counter DNAME_MENU $menu
}



#---------------------------------------------------------------------
proc edit_dname_update_dnames { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { ![ GetParamFromFile MTZ [GetFullFileName0 $arrayname HKLIN] SETID setid] ||
       ![ GetParamFromFile MTZ [GetFullFileName0 $arrayname HKLIN] PNAMES pnames] ||
       ![ GetParamFromFile MTZ [GetFullFileName0 $arrayname HKLIN] XNAMES xnames] ||
       ![ GetParamFromFile MTZ [GetFullFileName0 $arrayname HKLIN] DNAMES dnames] ||
     [set ndnames [llength $setid]] <= 0 ||
     [set ndnames [llength $pnames]] <= 0 ||
     [set ndnames [llength $xnames]] <= 0 ||
     [set ndnames [llength $dnames]] <= 0 } {
    set ndnames 0
    set setid  {}
    set pnames {}
    set xnames {}
    set dnames {}
    set dcell_1 {}
    set dcell_2 {}
    set dcell_3 {}
    set dcell_4 {}
    set dcell_5 {}
    set dcell_6 {}
    set dwaves {}
  } else {
    GetParamFromFile MTZ [GetFullFileName0 $arrayname HKLIN] DCELL_1 dcell_1
    GetParamFromFile MTZ [GetFullFileName0 $arrayname HKLIN] DCELL_2 dcell_2
    GetParamFromFile MTZ [GetFullFileName0 $arrayname HKLIN] DCELL_3 dcell_3
    GetParamFromFile MTZ [GetFullFileName0 $arrayname HKLIN] DCELL_4 dcell_4
    GetParamFromFile MTZ [GetFullFileName0 $arrayname HKLIN] DCELL_5 dcell_5
    GetParamFromFile MTZ [GetFullFileName0 $arrayname HKLIN] DCELL_6 dcell_6
    GetParamFromFile MTZ [GetFullFileName0 $arrayname HKLIN] DWAVES dwaves
  }

  set increment [expr $ndnames - $array(N_DNAME) ]
  update_extendingframe edit_dname_dname 0 $arrayname N_DNAME \
	$array(N_DNAME) $increment 1

  
  set n 0; foreach item $setid {
    incr n; set array(SETID,$n) $item
  }

  set n 0; foreach item $pnames {
    incr n; set array(PNAME,$n) $item
  }

  set n 0; foreach item $xnames {
    incr n; set array(XNAME,$n) $item
  }

  set n 0; foreach item $dnames {
    incr n; set array(DNAME,$n) $item
  }

  for { set n 1 } { $n <= $array(N_DNAME) } { incr n } {
    if { $array(PNAME,$n) != "" } { set status 1 } else { set status 0}
    set_field_colour $arrayname PNAME,$n $status
    if { $array(XNAME,$n) != "" } { set status 1 } else { set status 0}
    set_field_colour $arrayname XNAME,$n $status
    if { $array(DNAME,$n) != "" } { set status 1 } else { set status 0}
    set_field_colour $arrayname DNAME,$n $status
  }


  set n 0; foreach item1 $dcell_1 item2 $dcell_2 item3 $dcell_3 \
                   item4 $dcell_4 item5 $dcell_5 item6 $dcell_6 {
    incr n
    if { $item1 == "" || $item1 == "{}"} {
      set array(DCELL_1,$n) ""
      set array(DCELL_2,$n) ""
      set array(DCELL_3,$n) ""
      set array(DCELL_4,$n) ""
      set array(DCELL_5,$n) ""
      set array(DCELL_6,$n) ""
    } else {
      set array(DCELL_1,$n) $item1
      set array(DCELL_2,$n) $item2
      set array(DCELL_3,$n) $item3
      set array(DCELL_4,$n) $item4
      set array(DCELL_5,$n) $item5
      set array(DCELL_6,$n) $item6
    }
  }

  set n 0; foreach item $dwaves {
    incr n
    if { $item == "" || $item == "{}"} {
      set array(DWAVE,$n) ""
    } else {
      set array(DWAVE,$n) $item
    }
  }

  set names ""
  foreach item1 $xnames item2 $dnames {
    lappend names "$item1 $item2"
  }

  UpdateVariableMenu $arrayname initialise $ndnames DNAME_MENU $names
}

  
#---------------------------------------------------------------------
proc edit_dname_labels  { arrayname counter } {
#---------------------------------------------------------------------
# adds line to list of columns
# called when interface opened, when HKLIN read and upon Add label

  CreateLine line \
    varlabel LABIN \
    label "is associated with dataset " \
    message "Select from the datasets defined above (identified by crystal name and dataset name)" \
    widget ASSOC \
    format template edit_dname_labels

}

#---------------------------------------------------------------------
proc edit_dname_update_labels { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [set ncol [GetMtzColumnList [GetFullFileName0 $arrayname HKLIN] \
	name_list type_list def_name * ]] <= 0  } { return }

  # Remove the H K L columns if present
  set n 0
  while { $n < [llength $name_list] } {
    if { [lindex $type_list $n] == "H" } {
      set name_list [lreplace $name_list $n $n]
      set type_list [lreplace $type_list $n $n]
      incr ncol -1
    } else {
      incr n
    }
  }

  set increment [expr $ncol - $array(NLABIN) ]
  update_extendingframe edit_dname_labels 0 $arrayname NLABIN \
	$array(NLABIN) $increment 1

  set n 0; foreach item $name_list {
    incr n; set array(LABIN,$n) $item
    set field_list [GetWidget $arrayname LABIN,$n]
    foreach field $field_list {
      if { [winfo exists $field] } { $field configure -text $array(LABIN,$n) }
    }
  }

  if { [GetParamFromFile MTZ [GetFullFileName0 $arrayname HKLIN] \
			ASSOC assoc ] <= 0 } { return }
  GetParamFromFile MTZ [GetFullFileName0 $arrayname HKLIN] SETID setid
  GetParamFromFile MTZ [GetFullFileName0 $arrayname HKLIN] PNAMES pnames
  GetParamFromFile MTZ [GetFullFileName0 $arrayname HKLIN] XNAMES xnames
  GetParamFromFile MTZ [GetFullFileName0 $arrayname HKLIN] DNAMES dnames

# loop over columns
  set n 0; foreach item $assoc { incr n
    set m [lsearch $setid $item]
    set array(ASSOC,$n) "[lindex $xnames $m ] [lindex $dnames $m ]"
  }

}

#---------------------------------------------------------------------
proc edit_dname_restore_labels { arrayname } {
#---------------------------------------------------------------------
  # Restore the xtal/dataset assignments already made by the user
  # in a previous run of the task

  upvar #0 $arrayname array

# loop over columns

  for { set n 1 } { $n <= $array(NLABIN) } { incr n } {
    set array(ASSOC,$n) "$array(ASSOCX,$n) $array(ASSOCD,$n)"
  }

}

#----------------------------------------------------------------------
proc edit_dname_task_window { arrayname } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array

# def files are read here
  if { [CreateTaskWindow $arrayname  \
	"Edit MTZ Datasets" "Edit_dname" \
	  [list "Dataset properties" \
                "Column labels and their dataset association" ] ] == 0 } return

  SetProgramHelpFile "cad"
  CreateLineTemplate edit_dname_labels  [list 0 0.2 0.5]
  CreateLineTemplate edit_dname_dname_1 [list 0 0.15 0.35 0.60 0.72]
  CreateLineTemplate edit_dname_dname_2 [list 0 0.15 0.23 0.32 0.41 0.50 0.59 0.68 0.78 0.90]
  set array(DNAME_MENU) ""

  OpenFolder protocol 

  CreateTitleLine line TITLE

  OpenFolder file 

  CreateInputFileLine line \
    "Enter input MTZ file name (HKLIN)" \
    "MTZ in" \
     HKLIN DIR_HKLIN \
     -fileout HKLOUT DIR_HKLOUT "_editdname" \
     -help files \
     -command "edit_dname_update_dnames $arrayname" \
     -command "edit_dname_update_labels $arrayname"


    CreateOutputFileLine line \
      "Enter OUTPUT MTZ file name or click file browser icon (HKLOUT)" \
      "Output MTZ" \
      HKLOUT DIR_HKLOUT \
        -help files

#-------------------------------------------------------------------------------

  OpenFolder 1 

  CreateLine line \
    label "Datasets defined in MTZ file.." -italic


  CreateExtendingFrame N_DNAME edit_dname_dname \
    "Add a new dataset to the MTZ file - you will then need to associate columns with this dataset" "Add dataset" \
     [list PNAME XNAME DNAME DCELL_1 DCELL_2 DCELL_3 DCELL_4 DCELL_5 DCELL_6 DWAVE] \
	-edit edit_edit_dname_dname

#-------------------------------------------------------------------------------

  OpenFolder 2 

  CreateLine line \
    label "Columns in MTZ file.." -italic


  CreateLine line \
    label "H, K, L" \
    label "are associated with the base dataset HKL_base" \
    message "This association is fixed and cannot be changed." 


  CreateExtendingFrame NLABIN edit_dname_labels \
   "MTZ labels" "Add label" \
    [list LABIN ASSOC ] \
	-noaddline

  set array(N_DEPFRAMES_edit_dname_labels) 0
  set array(DEPFRAMES_edit_dname_labels) {}
  update_extendingframe edit_dname_labels  0 $arrayname NLABIN \
                0 $array(NLABIN) 1


#-------------------------------------------------------------------------------

#  OpenFolder 3 "closed" 

#  CreateLine line \
#    label "Batches in MTZ file.." -italic

  if { $array(HKLIN) != "" } {
    ExtractMTZData [GetFullFileName0 $arrayname HKLIN]
    if { $array(EDIT_DNAME_NO_UPDATE) } {
      edit_dname_restore_labels $arrayname
    } else {
      edit_dname_update_dnames $arrayname
      edit_dname_update_labels $arrayname
    }
  }

}

