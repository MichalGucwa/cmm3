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
# cad.tcl --
#
# Run CAD program to merge 2+ mtz files
#
# CCP4Interface 
#
# =======================================================================

#----------------------------------------------------------------------
proc cad_setup { typedefVar arrayname } {
#----------------------------------------------------------------------
  upvar #0 $typedefVar typedef

set typedef(_cad_labin_mode)    { menu {        "all columns"
                                                "selected columns" }
                                        {       ALL
                                                SELECTED } }

set typedef(_cad_monitor)       { menu {        "no"
                                                "brief"
                                                "brief&history"
                                                "full" }
                                             {  "NONE"
                                                "BRIEF"
                                                "HIST"
                                                "FULL" } }
DefineMenu _cad_outlim_mode  [list "Laue code" "explicit hkl limits"] \
	[list SPACE_GROUP HKLLIM]

return 1
}

#----------------------------------------------------------------------
proc cad_run { arrayname } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(INPUT_FILES) ""
  for { set n 1 } { $n <= $array(NFILES) } { incr n } {
    append array(INPUT_FILES) "HKLIN,$n "
    # Set up the E labels i.e. E1, E2 etc
    set count 0
    for { set k 1 } { $k <= $array(NLABIN,$n) } { incr k } {
	if { $array(INCLUDE_COLUMN,[subst $n]_$k) } {
	    incr count
	    set array(E_LABEL,[subst $n]_$k) "E$count"
	}
    }
  }
  if { $array(KEEP_FREER_LABEL) == "Unassigned" || $array(KEEP_FREER_LABEL) == "" } {
    set array(KEEP_FREER) 0
  } else {
    set array(KEEP_FREER) 1
  }
  return 1
}

#----------------------------------------------------------------------
proc cad_update_freer_file { arrayname counter } {
#----------------------------------------------------------------------
# Invoked when a new HKLIN file is added
  upvar #0 $arrayname array

  if { $array(KEEP_FREER_LABEL) == "" || $array(KEEP_FREER_LABEL) == "Unassigned" } {
    set array(FREER_FILE) $counter
    cad_update_freer $arrayname
  }
  return 1
}


#----------------------------------------------------------------------
proc cad_update_freer { arrayname } {
#----------------------------------------------------------------------
# Invoked when user changes the number of the file to take the
# freerflag column from

  upvar #0 $arrayname array

  set array(KEEP_FREER_LABEL) "Unassigned"

  set nfile $array(FREER_FILE)
  if { ![string is integer -strict $nfile] } {
    # Not an integer
    return 0
  } elseif { $nfile < 1 || $nfile > $array(NFILES) } {
    # Out of range of possible files
    return 0
  }

  # Look for FreeRFlag column in this file
  set free_col_in [list FREE FreeR FreeR_flag FreeRflag]
  if {[set ncol [GetMtzColumnList [GetFullFileName0 $arrayname HKLIN,$nfile] \
		name_list type_list def_name * ]] <= 0 } { return }

  for { set n 0 } { $n < $ncol } { incr n } {
    if { [lsearch $free_col_in [lindex $name_list $n] ] >= 0 } {
      set array(KEEP_FREER_LABEL) [lindex $name_list $n]
    }
  }

  return 1
}

#----------------------------------------------------------------------
proc cad_hklin { arrayname counter } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array
  global configure

  CreateLine line \
    label "Input file # $counter" \
    -italic
   
  CreateInputFileLine line \
    "Enter input MTZ file name (HKLIN)" \
    "MTZ in" \
     HKLIN DIR_HKLIN \
     -help files \
     -setlabin KEEP_FREER_LABEL [list FREE FreeR FreeR_flag FreeRflag] \
     -setfileparam resolution_min INPUT_RESOLUTION_MIN,$counter \
     -setfileparam resolution_max INPUT_RESOLUTION_MAX,$counter \
     -setfileparam space_group_name INPUT_SPACE_GROUP,$counter \
     -setfileparam sort_order  INPUT_SORT_ORDER,$counter \
     -setalllabin LABIN,$counter {} \
     -command "cad_update_freer_file $arrayname $counter"

 CreateLine line \
   label " Input" \
   message "Use all or selected labelled columns from this MTZ" \
   help labin \
   widget LABIN_MODE \
   label "from this file" \
   toggle_display LABIN_MODE,$counter open ALL

 CreateLine line \
   label " Input" \
   message "Use all or selected labelled columns from this MTZ" \
   help labin \
   widget LABIN_MODE \
   label "from this file:" \
   toggle_display LABIN_MODE,$counter open SELECTED

  OpenSubFrame frame \
	-toggle_display  LABIN_MODE,$counter hide  ALL


  CreateExtendingFrame NLABIN cad_labin \
    "Enter input labels" \
    "Add column" \
     [list  LABIN \
      LABOUT \
      CTYPIN ] \
      -counter $counter

  button $array(XF_COMLINE_cad_labin_$counter).b3 -text "List All Columns" \
	-background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
        -command "cad_list_all_columns $arrayname $counter"

  pack $array(XF_COMLINE_cad_labin_$counter).b3 -side right

  CloseSubFrame
}

#----------------------------------------------------------------------
proc cad_list_all_columns { arrayname counter } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array

#  puts "cad_list_all_columns $counter $array(HKLIN,$counter)"

  if {[set ncol [GetMtzColumnList [GetFullFileName0 $arrayname HKLIN,$counter] \
		name_list type_list def_name * ]] <= 0 } { puts $ncol; return }

  # Cad cannot handle reflection indices, so remove them from the list
  set n 0
  while { $n < $ncol } {
      if { [lindex $type_list $n] == "H" } {
	  set col [lindex $name_list $n]
	  set name_list [lreplace $name_list $n $n]
	  set type_list [lreplace $type_list $n $n]
	  incr ncol -1
	  if { $def_name == $col } {
	      set def_name [lindex $name_list 0]
	  }
      } else {
	  incr n
      }
  }

  set increment [expr $ncol - $array(NLABIN,$counter) ]
  update_extendingframe cad_labin $counter $arrayname NLABIN,$counter \
                $array(NLABIN,$counter) $increment 1

  for { set n 1 } { $n <= $array(NLABIN,$counter) } { incr n } {
     set n0 [expr $n -1 ]
     set array([Indxv LABIN $counter $n]) [lindex $name_list $n0]
     set array([Indxv LABOUT $counter $n]) [lindex $name_list $n0]
     set array([Indxv CTYPIN $counter $n]) [lindex $type_list $n0]
     set array([Indxv INCLUDE_COLUMN $counter $n]) 1
  }

}

#----------------------------------------------------------------------
proc cad_scale { arrayname counter } {
#----------------------------------------------------------------------

   CreateLine line \
     label "For input file #$counter" \
	-italic

   CreateLine line \
     message "Set resolution limit for this input file (RESOLUTION FILE_NUMBER)" \
     help resolution \
     widget INPUT_RESOLUTION \
	-toggleon \
     label "Limit input resolution between" \
     widget INPUT_RESOLUTION_MIN  \
     label "and" \
     widget INPUT_RESOLUTION_MAX \
     label "  " \
     message "Scale all input MTZ parameters except PHIs (SCALE FILE_NUMBER)" \
     help scale \
     widget INPUT_SCALE \
     label "Scale input data by" \
     widget INPUT_SCALE_FACTOR
}


#----------------------------------------------------------------------
proc cad_labin { arrayname c1 file } {
#----------------------------------------------------------------------

  CreateCadLabinLine line \
    "Choose input label and output name and type (but do not include H,K,L)" \
     HKLIN,$file \
     "Read" LABIN \
     "write as" LABOUT \
     "of type" CTYPIN \
     -checkbutton INCLUDE_COLUMN
}

#----------------------------------------------------------------------
proc cad_update_hklin_title { arrayname counter } {
#----------------------------------------------------------------------

  upvar #0 $arrayname array

  set title "Input MTZ file $counter "
  append title $array(HKLIN,$counter)

  SetToggleTitle $arrayname cad_hklin $counter $title

  if { $array(SPACE_GROUP) == "" }  { 
    set array(SPACE_GROUP) $array(INPUT_SPACE_GROUP,$counter)
  }
  if { $array(OUTLIM_SPACE_GROUP) == "" }  {
    set array(OUTLIM_SPACE_GROUP) $array(INPUT_SPACE_GROUP,$counter)
  }

}

#----------------------------------------------------------------------
proc cad_task_window { arrayname } {
#----------------------------------------------------------------------

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Merge MTZ files (CAD) " "CAD" \
	[list "File completion and freeR extension" \
        "Input File(s) Scaling & Resolution Limits" \
        "Define MTZ Output"  \
	"Log File Output" ]] == 0 } return

  SetProgramHelpFile "cad"

  OpenFolder protocol 

  CreateTitleLine line TITLE

  OpenFolder file 

  CreateExtendingFrame NFILES  cad_hklin \
     "Define input MTZ file (HKLIN)"  \
     "Add input MTZ file"  \
     [list   HKLIN  \
	DIR_HKLIN \
	LABIN_MODE \
	NLABIN ] \
      -dependentframe cad_scale \
      -child cad_labin

  CreateLine line \
     message "If spacegroup permits reindexing then check and enforce consistent indexing automatically?" \
     widget AUTO_REINDEX \
     label "Automatically check and enforce consistent indexing between different files" \
     toggle_display NFILES hide [list 0 1]

    CreateOutputFileLine line \
      "Enter OUTPUT MTZ file name or click file browser icon (HKLOUT)" \
      "Output MTZ" \
      HKLOUT DIR_HKLOUT \
        -help files



# ================================================= Uniqueify

  OpenFolder 1 

  CreateLine line \
    message "Complete output MTZ file and add freeR column (uniqueify) ..." \
    widget UNIQUEIFY \
    label "Complete reflection list " \
    message "... or complete existing freeR column" \
    label "and extend freeR column " \
    widget KEEP_FREER_LABEL \
    label "from file #" \
    widget FREER_FILE \
    -command "cad_update_freer $arrayname"
       

# ================================================= Scaling & resolution

  OpenFolder 2 closed

  CreateExtendingFrame NFILES cad_scale \
    "Scaling and resolution limits for each input file" \
    " "  \
     [list INPUT_RESOLUTION \
	INPUT_RESOLUTION_MIN \
	INPUT_RESOLUTION_MAX \
	INPUT_SCALE \
	INPUT_SCALE_FACTOR \
	INPUT_SPACE_GROUP ] -noaddline
       

#======================================================Define output

  OpenFolder 3 closed

  CreateLine line \
    message "Space group (default as in MTZ file) (SYMMETRY)" \
    help symmetry \
    widget OVERRIDE_SPACE_GROUP \
	-toggleon \
    label "Override input space group in MTZ file" \
    label "and output data in space group" \
    widget SPACE_GROUP
    

  CreateLine line \
    message "Sort order - usually taken from first MTZ file (SORT)" \
    help sort \
    widget OVERRIDE_SORT_ORDER \
	-toggleon \
    label "Override sort order in MTZ file"  \
    widget SORT_ORDER

  CreateLine line \
    message "Only output centric data (CENTRIC_ONLY)" \
    help centric \
    widget CENTRIC \
    label "Output only centric data"


  CreateLine line \
    message "Exclude reflections below and/or above resolution limit in \
                  Angstrom (RESOLUTION)" \
    help resolution \
    widget EXCLUDE_RESOLUTION \
	-toggleon \
    label "Exclude reflections resolution less than" \
    widget EXCLUDE_RESOLUTION_MIN \
    label "Angstrom or greater than" \
    widget EXCLUDE_RESOLUTION_MAX \
    label "Angstrom"

  CreateLine line \
    message "Expand the data to cover more of reciprocal space (OUTLIM)" \
    help outlim \
    widget HKL_LIMITS -toggleon \
    label "Define limits for reflections in the output file using" \
    widget OUTLIM_MODE

  # Start of subframe for OUTLIM options
  OpenSubFrame frame -toggle_display HKL_LIMITS open 1

  CreateLine line \
    message "Choose a Laue code for the appropriate point group (OUTLIM SPACEGROUP)" \
    help outlim_spacegroup \
    label "      Laue code for point group" \
    widget OUTLIM_SPACE_GROUP \
    toggle_display OUTLIM_MODE open [list SPACE_GROUP]

  CreateLine line \
    message "Change hkl limits explicitly (OUTLIM HKLLIM)" \
    help outlim_hkllim \
    label "      Set hkl limits to: Hmin" \
    widget HKLLIM_1 -width 6\
    label "Hmax" \
    widget HKLLIM_2 -width 6\
    label "Kmin"       \
    widget HKLLIM_3 -width 6\
    label "Kmax"       \
    widget HKLLIM_4 -width 6\
    label "Lmin"       \
    widget HKLLIM_5 -width 6\
    label "Lmax"       \
    widget HKLLIM_6 -width 6\
    toggle_display OUTLIM_MODE open [list HKLLIM]

  # End of subframe for OUTLIM options
  CloseSubFrame


#================================================= log file

  OpenFolder 4 closed

  CreateLine line \
    message "Log MTZ header information (MONITOR) " \
    help monitor \
    label "Log " \
    widget MONITOR \
    message "Monitor reflections (REFMONITOR)" \
    help refmonitor \
    label "MTZ header info and every " \
    widget REFMONITOR \
    label "reflection"

}

