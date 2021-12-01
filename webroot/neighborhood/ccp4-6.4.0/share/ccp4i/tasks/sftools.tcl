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
# sftools.tcl --
#
# CCP4Interface 
#
# =======================================================================

# Also source the sftools_utils.tcl file
  source [SearchPath TOP tasks sftools_utils.tcl]

#-----------------------------------------------------------------------
proc sftools_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(EXPAND_SPACEGP_NUM) [GetSpaceGroupNumber $array(SPACEGROUP_EXP)]

  SetDefaultTitle $arrayname  $array(SF_ACTION)

  if [regexp GETDANO [GetValue $arrayname SF_ACTION ] ] {
      if { [regexp "Unassigned" $array(FPLUS)] \
	       || [regexp "Unassigned" $array(SIGFPLUS)] \
	       || [regexp "Unassigned" $array(FMINUS)] \
	       || [regexp "Unassigned" $array(SIGFMINUS)] } {
	  WarningMessage "One or more input labels are unassigned.
Please check that F(+) and F(-) (and the corresponding
sigmas) are correctly set before rerunning the task"
          return 0
    }

    if { ![IfSet $array(DANO)] || ![IfSet $array(SIGDANO)] } {
      WarningMessage "The output labels for Dano and/or SigDano are not set.
Please give suitable names for these labels before rerunning"
      return 0
    }
  }

  if [regexp PURGE [GetValue $arrayname SF_ACTION ] ] {
    set array(APPLY_SELECT) 1
    return [sftools_utils_run $arrayname]
  } else {
    return 1
  }
}

# procedure which is run automatically before drawing the interface
# used to set up variables, menus etc
#---------------------------------------------------------------------
proc sftools_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0  $typedefVar typedef
  upvar #0 $arrayname array

# Define the 'format type' menu

  DefineMenu _sftools_format [list "CCP4 (mtz)" \
                                   "mdf (old BIOMOL)" \
                                   "BIOMOL ascii" \
                                   "X-PLOR" \
                                   "TNT" \
                                   "Phases" \
                                   "XtalView fin" \
                                   "XtalView phs" \
                                   "XtalView double" ] \
                                    [ list MTZ \
                                           MDF \
                                           SND \
                                           XPL \
                                           TNT \
                                           31 \
                                           FIN \
                                           PHS \
                                           DF]

  DefineMenu _sftools_action [ list "set or change header information" \
				    "reduce to asymmetric unit" \
                                    "expand to lower symmetry" \
                                    "sort reflections" \
                                    "reindex reflections" \
                                    "merge reflections" \
                                    "delete reflections" \
                                    "delete columns" \
                                    "generate Hendrickson-Lattman coeffs" \
			            "generate Dano from F(+) and F(-)" ] \
                                    [ list SET \
					   REDUCE \
                                           EXPAND \
                                           SORT \
                                           REINDEX \
                                           MERGE \
                                           PURGE \
                                           DELETE \
                                           HLCONV \
					   GETDANO ]

  DefineMenu _sftools_asunit [ list "CCP4" \
                                    "BIOMOL" \
                                    "TNT" \
                                    "user-defined" ] \
                                    [ list CCP4 \
                                           BIOMOL \
                                           TNT \
                                           MATRIX]

  DefineMenu _sftools_sort_on [ list "indices" \
                                     "resolution" \
                                     "specified column" ] \
                                     [ list HKL \
                                            RESOL \
                                            COL ]

  DefineMenu _sftools_sort_indices [ list "HKL" \
                                          "HLK" \
                                          "LHK" \
                                          "LKH" \
                                          "KHL" \
                                          "KLH" ] \
                                          [ list "h k l" \
                                                 "h l k" \
                                                 "l h k" \
                                                 "l k h" \
                                                 "k h l" \
                                                 "k l h" ]

  DefineMenu _sftools_direction [list "ascending" \
                                      "descending" ] \
                                      [ list UP \
                                             DOWN ]

  DefineMenu _sftools_merge_mode [list "only when safe" \
                                       "by averaging" ] \
                                       [ list SAFE \
                                              AVERAGE ]

  DefineMenu _sftools_purge_mode [list Keep Delete ] [list KEEP DELETE ]


  DefineMenu _sftools_column_types [list "intensity" \
                                         "structure amplitude F" \
                                         "anomalous difference" \
                                         "standard deviation" \
                                         "phase angle" \
                                         "weight factor" \
                                         "phase probability c/f" \
                                         "BATCH number" \
                                         "M/ISYM etc" \
                                         "index h,k,l" \
                                         "any other integer" \
                                         "any other real" ] \
                                         [ list J F D Q P W A B Y H I R ]

  DefineMenu _sftools_tnt_cols [list "2" "3" "4" "5" ] \
                                     [ list 2 3 4 5 ]

  sftools_utils_setup $typedefVar $arrayname

# procedure must return sucess code (1) for drawing task window to continue
  return 1
}

#---------------------------------------------------------------------
proc sftools_title_cards { arrayname counter } {
#---------------------------------------------------------------------
#procedure to draw one line of the 'title cards' extending frame
  upvar #0 $arrayname array

  CreateLine line \
        message "Enter title cards, one per line" \
        label "Line" \
        label $counter \
        widget TITLE_CARD

}


#---------------------------------------------------------------------
proc sftools_new_mtz_labels { arrayname counter } {
#---------------------------------------------------------------------
#procedure to draw one line of the 'change labels and types' extending frame
  upvar #0 $arrayname array

  CreateCadLabinLine line \
    "Choose input label and output name and type" \
     HKLIN \
     "Change" LABIN \
     "to" LABOUT \
     "of type" CTYPIN

}

#--------------------------------------------------------------------
proc sftoolssetlabel { arrayname counter } {
#--------------------------------------------------------------------
  upvar #0 #arrayname array
  puts "sftoolssetlabel"
  set array(LABOUT,$counter) $array(LABIN,$counter)

}


#---------------------------------------------------------------------
proc sftools_delete_mtz_columns { arrayname counter } {
#---------------------------------------------------------------------
#procedure to draw one line of the 'delete columns' extending frame
  upvar #0 $arrayname array

  CreateLabinLine line \
        "Select label to change" \
	HKLIN "Delete column" DEL_MTZ_LABEL {NULL}

}

# This taken from install_task.tcl
#-----------------------------------------------------------------------
proc sftools_UpdateNoaddlineFrame { arrayname CounterVar DefLineProc increment } {
#-----------------------------------------------------------------------
# Update an extending frame with a -noaddline option, when that frame
# is not a dependent frame.
# CounterVar = the parameter in the array controlling the number of lines
# in the extending frame
# DefLineProc = the procedure which creates one line of the extending frame

  upvar #0 $arrayname array

  # Redraw the extending frame manually
  if { $increment > 0 } {
    # Add frames
    for { set i 0 } { $i < $increment } { incr i } {
      append_extend_frame $arrayname $DefLineProc 0
      incr array($CounterVar)
    }
  } elseif { $increment < 0 } {
    # Delete frames
    for { set i 0 } { $i > $increment } { incr i -1 } {
      delete_frame $arrayname $DefLineProc 0
      incr array($CounterVar) -1
    }
  }

  # Update the scrollable extent of the window
  # PJX: This code borrowed from update_extendingframe in exframe.tcl
  # I'm not really sure how or why it works
  append def_proc $DefLineProc _0
  set frame $array(FRAME_$def_proc)
  SetSystemVar block_scroll_update 0
  update_main_scroll $frame 

}

#---------------------------------------------------------------------
proc sftools_update_datasetinfo { arrayname } {
#---------------------------------------------------------------------
# Update dataset info XNAME, DCELL, etc from MTZ file.
# All previous info is deleted, and datasetinfo re-read from MTZ file.
# We assume one input file only, and no option to add datasets.

  upvar #0 $arrayname array

  set n_remove [expr { - $array(N_XNAME)} ]
# remove existing frames
  sftools_UpdateNoaddlineFrame $arrayname N_XNAME \
    sftools_dcell $n_remove
  set n_remove [expr { - $array(N_DNAME)} ]
# remove existing frames
  sftools_UpdateNoaddlineFrame $arrayname N_DNAME \
    sftools_dwave $n_remove

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

  set n 0; foreach item $dnames {
    incr n; set array(DNAME,$n) $item
  }
  set n 0; foreach item $xnames {
    incr n; set array(DXNAME,$n) $item
  }

  set nxnames 0; set xname_list {}
  foreach item $xnames item1 $dcell_1 item2 $dcell_2 item3 $dcell_3 \
                   item4 $dcell_4 item5 $dcell_5 item6 $dcell_6 {

    if {[lsearch -exact $xname_list $item] < 0} {
      incr nxnames
      lappend xname_list $item
      set array(XNAME,$nxnames) $item
      set array(DCELL_1,$nxnames) $item1
      set array(DCELL_2,$nxnames) $item2
      set array(DCELL_3,$nxnames) $item3
      set array(DCELL_4,$nxnames) $item4
      set array(DCELL_5,$nxnames) $item5
      set array(DCELL_6,$nxnames) $item6
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

  GetParamFromFile MTZ [GetFullFileName0 $arrayname HKLIN] SPACE_GROUP_NAME array(SPACEGROUP_EXP)
  GetParamFromFile MTZ [GetFullFileName0 $arrayname HKLIN] SPACE_GROUP_NAME array(NEW_SPACEGROUP)

# now add current list of datasets
  sftools_UpdateNoaddlineFrame $arrayname N_XNAME \
    sftools_dcell $nxnames
# now add current list of datasets
  sftools_UpdateNoaddlineFrame $arrayname N_DNAME \
    sftools_dwave $ndnames

}

#---------------------------------------------------------------------
proc sftools_dcell { arrayname counter } {
#---------------------------------------------------------------------
# adds line to list of dataset cells
# called when interface opened, and when HKLIN read 
  upvar #0 $arrayname array

  CreateLine line \
    label " cell " \
    message "Optionally change values of crystal cell dimensions (SET DCELL)" \
    help set_dcell \
    widget DCELL_1 \
    widget DCELL_2 \
    widget DCELL_3 \
    widget DCELL_4 \
    widget DCELL_5 \
    widget DCELL_6 \
    label " for crystal $array(XNAME,$counter)" \
    format template sftools_dcell_line

}

#---------------------------------------------------------------------
proc sftools_dwave { arrayname counter } {
#---------------------------------------------------------------------
# adds line to list of dataset wavelengths
# called when interface opened, and when HKLIN read 
  upvar #0 $arrayname array

  CreateLine line \
    label " wavelength " \
    message "Optionally change value of dataset wavelength (SET DWAVE)" \
    help set_dwave \
    widget DWAVE \
    label " for dataset $array(DNAME,$counter) in crystal $array(DXNAME,$counter)" \
    format template sftools_dwave_line

}

# procedure to draw task window
#---------------------------------------------------------------------
proc sftools_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array


  if { [CreateTaskWindow $arrayname  \
        "Analyse, Manipulate and Convert Structure Factor Files" "Sftools" \
        [ list "Input for XPLOR, TNT and PHASES formats" \
               "Reduce to asymmetric unit" \
               "Sort reflections" \
               "Expand reflections to lower symmetry group" \
               "Reindex reflections" \
               "Merge reflections" \
               "Delete reflections" \
               "Change cell and spacegroup information" \
               "Change title information" \
               "Change column labels and types" \
               "Delete columns" \
               "Generate Hendrickson-Lattman coefficients" \
               "Information for XPLOR output" \
               "Information for TNT output" \
               "Information for Phases output" \
	       "Generate Dano from F(+) and F(-)" \
	       "Change dataset wavelength information"] ] == 0 } return

  InitialiseArray [SearchPath TOP tasks sftools_select.def ] \
                 $arrayname sftools_select

  CreateLineTemplate sftools_dcell_line [list 0 0.10 0.20 0.30 0.40 0.50 0.60 0.70 ]
  CreateLineTemplate sftools_dwave_line [list 0 0.10 0.20 ]

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "sftools"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
        message "Select operation to perform on reflection data" \
        label "Use sftools to" \
        widget SF_ACTION

#=FILES================================================================ 

  OpenFolder file

  CreateLine line \
        message "Select format for input reflection to import to CCP4 format" \
        help read_examples \
        label "Read in reflections from" \
        widget FORMAT_IN \
        label "format" \
        toggle_display SF_ACTION open IMPORT

  CreateInputFileLine line \
        "Enter name of input mtz file" \
        "MTZ in" \
        HKLIN DIR_HKLIN \
        -command "sftools_update_datasetinfo $arrayname" \
        -fileout HKLOUT DIR_HKLOUT _sftools

  CreateLine line \
        message "Select format for output reflection file to export from CCP4 format" \
        help read_examples \
        label "Write out reflections from" \
        widget FORMAT_OUT \
        label "format" \
        toggle_display SF_ACTION open EXPORT

  CreateOutputFileLine line \
        "Enter name of output mtz file" \
        "MTZ out" \
        HKLOUT DIR_HKLOUT


#-----------------------------------------------------READ XPLOR/TNT/PHASES folder
# This folder gets the header info required for reading in the specified formats

  OpenFolder 1 FORMAT_IN open [list XPL TNT 31 ] hide

  CreateLine line \
        label "Additional information required to read in the data:"

  CreateLine line \
        help set_examples \
        message "Enter cell dimensions in Angstroms" \
        label "a" \
        widget CELL_A \
        label "b" \
        widget CELL_B \
        label "c" \
        widget CELL_C \
        message "Enter cell angles in degrees" \
        label "alpha" \
        widget CELL_ALPHA \
        label "beta" \
        widget CELL_BETA \
        label "gamma" \
        widget CELL_GAMMA

  CreateLine line \
        help set_examples \
        message "Specify name or number for the spacegroup" \
        label "Spacegroup:" \
        widget NEW_SPACEGROUP

#-----------------------------------------------------REDUCE folder

  OpenFolder 2 SF_ACTION open [list REDUCE ] hide

  CreateLine line \
        message "Select choice of asymmetric unit" \
        help reduce_examples \
        label "Reduce reflections to" \
        widget ASYM_UNIT \
        label "asymmetric unit"

  OpenSubFrame frame \
        -toggle_display ASYM_UNIT open [list MATRIX]

  CreateLine line \
        label "The asymmetric unit is the set of reflections which maximize:"

  CreateLineTemplate sftools_reduce_matrix [ list 0.0 0.015 0.1 0.2 0.3 0.4 0.5 ]

  CreateLine line \
        message "Set elements of packing matrix for user-defined asymmetric unit" \
        help REDUCE \
        label "(" \
        widget I_1 \
        label "*h +" \
        widget I_2 \
        label "*k +" \
        widget I_3 \
        label "*l)*1024**2 +" \
        format template sftools_reduce_matrix

  CreateLine line \
        message "Set elements of packing matrix for user-defined asymmetric unit" \
        help REDUCE \
        label "(" \
        widget I_4 \
        label "*h +" \
        widget I_5 \
        label "*k +" \
        widget I_6 \
        label "*l)*1024 +" \
        format template sftools_reduce_matrix

  CreateLine line \
        message "Set elements of packing matrix for user-defined asymmetric unit" \
        help REDUCE \
        label " " \
        widget I_7 \
        label "*h +" \
        widget I_8 \
        label "*k +" \
        widget I_9 \
        label "*l" \
        format template sftools_reduce_matrix

  CloseSubFrame

#-----------------------------------------------------SORT folder

  OpenFolder 3 SF_ACTION open [list SORT ] hide

  CreateLine line \
        message "Sorting goes smallest to largest (ascending) or largest to smallest (descending)" \
        help SORT \
        label "Sort reflections in" \
        widget DIRECTION \
        message "Select different sorting criteria" \
        help sort_examples \
        label "order using" \
        widget SORT_ON \
        label "as the sorting criteria"

  CreateLine line \
        message "Reflections sorted with first index varying fastest" \
        help sort_examples \
        label "Set order of indices for sorting:" \
        widget SORT_INDICES \
        toggle_display SORT_ON open [list "indices"]

  OpenSubFrame frame \
        -toggle_display SORT_ON open [list COL]

  CreateLabinLine line \
        "Select label of column to use for sorting" \
	HKLIN "Column:" SORT_LABEL {NULL}

#  CreateLine line \
#        message "Enter number (eg 1=first) or label of column to use for sorting" \
#        help sort_examples \
#        label "Sort using column" \
#        widget SORT_COL \
#        toggle_display FORMAT_IN hide [list MTZ]

  CloseSubFrame

#-----------------------------------------------------EXPAND folder

  OpenFolder 4 SF_ACTION open [list EXPAND ] hide

  CreateLine line \
        message "Choose spacegroup to expand to" \
        help expand_examples \
        label "Expand reflections to" \
        widget SPACEGROUP_EXP \
        message "Choose asymmetric unit" \
        help EXPAND \
        label "spacegroup, using" \
        widget ASYM_UNIT \
        label "asymmetric unit"

  OpenSubFrame frame \
        -toggle_display ASYM_UNIT open [list MATRIX]

  CreateLine line \
        label "The asymmetric unit is the set of reflections which maximize:"

  CreateLine line \
        message "Set elements of packing matrix for user-defined asymmetric unit" \
        help REDUCE \
        label "(" \
        widget I_1 \
        label "*h +" \
        widget I_2 \
        label "*k +" \
        widget I_3 \
        label "*l)*1024**2 +" \
        format template sftools_reduce_matrix

  CreateLine line \
        message "Set elements of packing matrix for user-defined asymmetric unit" \
        help REDUCE \
        label "(" \
        widget I_4 \
        label "*h +" \
        widget I_5 \
        label "*k +" \
        widget I_6 \
        label "*l)*1024 +" \
        format template sftools_reduce_matrix

  CreateLine line \
        message "Set elements of packing matrix for user-defined asymmetric unit" \
        help REDUCE \
        label " " \
        widget I_7 \
        label "*h +" \
        widget I_8 \
        label "*k +" \
        widget I_9 \
        label "*l" \
        format template sftools_reduce_matrix

  CloseSubFrame

#-----------------------------------------------------REINDEX folder

  OpenFolder 5 SF_ACTION open [list REINDEX ] hide

  CreateLineTemplate sftools_reindex_matrix [ list 0.0 0.1 0.2 0.3 ]

  CreateLine line \
        message "Define the matrix used to reindex the reflections" \
        help reindex_examples \
        label "Matrix elements for transformation matrix"

  CreateLine line \
        message "Transformation matrix to change indices" \
        help REINDEX \
        label "1st row" \
        widget I_1 \
        widget I_2 \
        widget I_3 \
        format template sftools_reindex_matrix

  CreateLine line \
        help REINDEX \
        label "2nd row" \
        widget I_4 \
        widget I_5 \
        widget I_6 \
        format template sftools_reindex_matrix

  CreateLine line \
        help REINDEX \
        label "3rd row" \
        widget I_7 \
        widget I_8 \
        widget I_9 \
        format template sftools_reindex_matrix

#-----------------------------------------------------MERGE folder

  OpenFolder 6 SF_ACTION open [list MERGE ] hide

  CreateLine line \
        message "Merge reflections with identical indices either safely, or using averaging" \
        help merge_examples \
        label "Merge reflections" \
        widget MERGE_MODE

#-----------------------------------------------------PURGE folder

  OpenFolder 7 SF_ACTION open [list PURGE ] hide

  CreateLine line \
    widget PURGE_MODE \
    label "selected reflections:" -italic

  SftoolsSelection $arrayname


#-----------------------------------------------------SET folder: DCELL and SPGP

  OpenFolder 8 SF_ACTION open [list SET ] hide

  CreateLine line \
        help set_examples \
        message "Set new cell parameters" \
        widget SET_NEW_CELL \
        label "Change crystal data.   Spacegroup" \
        widget NEW_SPACEGROUP

  CreateExtendingFrame N_XNAME sftools_dcell "" "" \
     [list DCELL_1 DCELL_2 DCELL_3 DCELL_4 DCELL_5 DCELL_6 XNAME] \
	-noaddline

#-----------------------------------------------------SET folder: TITLE

  OpenFolder 9 SF_ACTION closed [list SET ] hide

  CreateLine line \
        help set_examples \
        label "Add new title lines to MTZ header" -italic

  CreateExtendingFrame NTITLES sftools_title_cards \
        "Write text to be written to as title information" \
        "Add another line" \
       [ list TITLE_CARD ]

#-----------------------------------------------------SET folder: LABELS/TYPES

  OpenFolder 10 SF_ACTION closed [list SET ] hide

  OpenSubFrame frame \
        -toggle_display FORMAT_IN open MTZ

  CreateExtendingFrame NLABIN sftools_new_mtz_labels \
        "Specify another column to be changed" \
        "Edit another label" \
       [ list LABIN \
              LABOUT \
	      CTYPIN ]

  CloseSubFrame

#-----------------------------------------------------DELETE folder

  OpenFolder 11 SF_ACTION open [list DELETE ] hide

  CreateExtendingFrame NCOLS_DEL sftools_delete_mtz_columns \
        "Add another column to the list to be deleted from MTZ file" \
        "Delete another column" \
       [ list DEL_MTZ_LABEL ]

#-----------------------------------------------------HLCONV folder

  OpenFolder 12 SF_ACTION open [list HLCONV ] hide

  CreateLine line \
    label "Generate Hendrickson-Lattman coefficients for phases" -itallic

  CreateLabinLine line \
        "Select column with phases (type P) to generate coefficients from" \
        HKLIN "Phi" HL_MTZ_PHASE {NULL} \
        -sigma "FOM" HL_MTZ_FOM {NULL} \
        -help hlconv_examples


#-----------------------------------------------------WRITE XPL folder

  OpenFolder 13 FORMAT_OUT open [list XPL ] hide

  CreateLine line \
        label "Additional information required for XPLOR output:"

#-----------------------------------------------------WRITE TNT folder

  OpenFolder 14 FORMAT_OUT open [list TNT ] hide

  CreateLine line \
        label "Additional information required for TNT output:"

  CreateLine line \
        message "Select number of columns to write to TNT output file" \
        label "Write" \
        widget N_TNT_COL \
        label "columns to TNT file"

  CreateLabinLine line \
        "Select labels for first (type F) and second (type Q) columns to output" \
	HKLIN "Column 1:" TNT_MTZ_1 {NULL} \
        -sigma "Column 2:" TNT_MTZ_2 {NULL}         

  CreateLabinLine line \
        "Select label for third column to output (must be type I)" \
	HKLIN "Column 3:" TNT_MTZ_3 {NULL} \
        -toggle_display N_TNT_COL open [ list 3 4 5 ]

  CreateLabinLine line \
        "Select label for fourth column to output (must be type P)" \
	HKLIN "Column 4:" TNT_MTZ_4 {NULL} \
        -toggle_display N_TNT_COL open [ list 4 5 ]

  CreateLabinLine line \
        "Select label for fifth column to output (must be type W)" \
	HKLIN "Column 5:" TNT_MTZ_5 {NULL} \
        -toggle_display N_TNT_COL open [ list 5 ]

#-----------------------------------------------------WRITE PHASES folder

  OpenFolder 15 FORMAT_OUT open [list 31 ] hide

  CreateLine line \
        label "Additional information required for Phases output:"

#-----------------------------------------------------GET DANO folder

  OpenFolder 16 SF_ACTION open [list GETDANO] hide

  CreateLabinLine line \
      "Select F(+) and corresponding sigma SIGF(+) to be use in Dano calculation" \
      HKLIN "F(+)" FPLUS { NULL } \
      -sigma "SigF(+)" SIGFPLUS { NULL }
       
  CreateLabinLine line \
      "Select F(-) and corresponding sigma SIGF(-) to be use in Dano calculation" \
      HKLIN "F(-)" FMINUS { NULL } \
      -sigma "SigF(-)" SIGFMINUS { NULL }

  CreateLine line \
      message "Assign labels for output Dano and SigDano columns" \
      label "Dano" widget DANO -width 25 \
      label "SigDano" widget SIGDANO -width 25

#-----------------------------------------------------SET folder: DWAVE

  OpenFolder 17 SF_ACTION closed [list SET ] hide

  CreateLine line \
        help set_examples \
      message "Set new dataset wavelength parameters" \
        widget SET_NEW_WAVE \
        label "Change dataset wavelength data." 

  CreateExtendingFrame N_DNAME sftools_dwave "" "" \
     [list DWAVE DXNAME DNAME] \
	-noaddline


}
