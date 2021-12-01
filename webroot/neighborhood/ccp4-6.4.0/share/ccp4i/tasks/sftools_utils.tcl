#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
# Utils for various interfaces to sftools - the selection tools

#---------------------------------------------------------------------
proc sftools_utils_run { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array
# Make sure resolution max/min are the right (ie. wrong) way round

  if { $array(N_SELECT_CRITERIA) >= 0 } {
    set array(SELECT_MODE,1) [GetValue $arrayname SELECT_MODE1,1]
    for { set n 1 } { $n <= $array(N_SELECT_CRITERIA) } { incr n } {
      if { [StringSame [GetValue $arrayname SELECT_CRITERIA,$n] RESO ]  } {
        switch [GetValue $arrayname SELECT_RESO_MODE,$n] \
        RANGE {
          if { ![IfSet $array(SELECT_RESO_MAX,$n)] } {
            set array(SELECT_RESO_MODE,$n) minimum
          } elseif {  ![IfSet $array(SELECT_RESO_MIN,$n)] }  {
            set array(SELECT_RESO_MODE,$n) maximum
          } elseif { $array(SELECT_RESO_MIN,$n) < $array(SELECT_RESO_MAX,$n) } {
            set tt $array(SELECT_RESO_MIN,$n)
            puts "tt $tt"
            set array(SELECT_RESO_MIN,$n) $array(SELECT_RESO_MAX,$n)
            set array(SELECT_RESO_MAX,$n) $tt
          }
        } MAX {
            set array(SELECT_RESO_MIN,$n) {}
        } MIN {
            set array(SELECT_RESO_MAX,$n) {}
        }
      }
    }
  }
  return 1
}


#---------------------------------------------------------------------
proc sftools_utils_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0  $typedefVar typedef
  upvar #0 $arrayname array

  DefineMenu _sftools_select_mode [list "and" "and not" "plus" "plus not"] \
				[list {} NOT PLUS "PLUS NOT" ]

  DefineMenu _sftools_select_mode1 [list includes excludes ] \
				[list PLUS "PLUS NOT" ]

  DefineMenu _sftools_select_criteria [list "based on column data values" \
                                   "based on comparison of column data" \
                                   "based on resolution" \
                                   "based on indices (hkl)" \
                                "which are centrosymmetric" \
                                "which are systematically absent" \
                                "outside the asymmetric unit" \
                                "centrosymmetric with illegal phase" \
                                "on an n-fold symmetry axis" \
                                "data missing in specified column" \
                                "data present in specified column" \
				"all reflections"] \
                                   [ list COL \
                                          COMPARE \
                                          RESO \
                                          INDEX \
                                        CENTRO \
                                          SYSABS \
                                          ASUERR \
                                          PHAERR \
                                          MULTI \
                                          MISSING \
                                          PRESENT \
					  ALL]


  DefineMenu _sftools_operators 	[list "equal to" \
                                      "not equal to" \
                                      "greater than" \
                                      "greater than or equal to" \
                                      "less than" \
                                      "less than or equal to" ] \
                                      [ list "=" \
                                             "<>" \
                                             ">" \
                                             ">=" \
                                             "<" \
                                             "<=" ]


  DefineMenu _sftools_resolution_mode [list maximum minimum ] \
		[list MAX MIN ]

  DefineMenu _sftools_index_operators [list "equal to" \
                                      "not equal to" \
                                      "greater than" \
                                      "greater than or equal to" \
                                      "less than" \
                                      "less than or equal to" \
                                        zone ]  \
                                      [ list "=" \
                                             "<>" \
                                             ">" \
                                             ">=" \
                                             "<" \
                                             "<=" \
                                                zone ]

  DefineMenu _sftools_index_h [list {} "+ H" "- H" ]
  DefineMenu _sftools_index_k [list {} "+ K" "- K" ]
  DefineMenu _sftools_index_l [list {} "+ L" "- L" ]

  return 1

}


#-----------------------------------------------------------------
proc SftoolsSelection { arrayname } {
#-----------------------------------------------------------------
  upvar #0 $arrayname array

  CreateExtendingFrame N_SELECT_CRITERIA SftoolsSelLine \
        "Select reflections for set" \
        "Add Selection Criteria" \
      [list  SELECT_MODE \
		SELECT_MODE1 \
		SELECT_CRITERIA \
		SELECT_COL_1 \
		SELECT_COL_2 \
		SELECT_RESO_MODE \
		SELECT_RESO_MAX \
		SELECT_RESO_MIN \
		SELECT_COL_OP \
		SELECT_COL_VAL \
		SELECT_COMPARE_OP \
		SELECT_INDEX_H \
		SELECT_INDEX_K \
		SELECT_INDEX_L \
		SELECT_INDEX_OP \
		SELECT_INDEX_SUM \
		SELECT_N_FOLD ]
}

#-----------------------------------------------------------------------
proc SftoolsSelLine { arrayname counter } {
#-----------------------------------------------------------------------
    
  if { $counter == 1 } {
    CreateLine line \
        help select_examples \
        label "Selection" \
        widget SELECT_MODE1 \
	label reflections \
        message "Choose criteria for selecting the reflections" \
        widget SELECT_CRITERIA
  } else {
    CreateLine line \
        message "Include/exclude the selected reflections" \
        help SELECT \
        widget SELECT_MODE \
        label "reflections" \
        message "Choose criteria for selecting the reflections" \
        widget SELECT_CRITERIA
  }

# Resolution selection
  OpenSubFrame frame \
        -toggle_display [Indxv SELECT_CRITERIA $counter ] open RESO

  CreateLine line \
        help SELECT \
        label "   Set resolution" \
        widget SELECT_RESO_MODE \
        widget SELECT_RESO_MIN \
        toggle_display [Indxv SELECT_RESO_MODE $counter ] open MIN

  CreateLine line \
        help SELECT \
        label "   Set resolution" \
        widget SELECT_RESO_MODE \
        widget SELECT_RESO_MAX \
        toggle_display [Indxv SELECT_RESO_MODE $counter ] open MAX

  CreateLine line \
        help SELECT \
        label "   Set resolution" \
        widget SELECT_RESO_MODE \
        label from \
        widget SELECT_RESO_MIN \
        label "to" \
        widget SELECT_RESO_MAX \
        toggle_display [Indxv SELECT_RESO_MODE $counter ] open RANGE



  CloseSubFrame

# Column value selection

  OpenSubFrame frame \
        -toggle_display [Indxv SELECT_CRITERIA $counter ] open COL

  CreateLabinLine line \
        "Choose label of column to use" \
        HKLIN "   Column" SELECT_COL_1 {}
 
  CreateLine line \
        help SELECT \
        label "   value" \
        label {} \
        message "Choose an operator" \
        widget SELECT_COL_OP \
        message "Enter value to compare with the value in the specified column" \
        widget SELECT_COL_VAL \

  CloseSubFrame

# Compare columns

  OpenSubFrame frame \
        -toggle_display [Indxv SELECT_CRITERIA $counter ] open COMPARE

  CreateLabinLine line \
        "Choose label of column to use" \
        HKLIN "   First" SELECT_COL_1 {} \
        -sigma "second" SELECT_COL_2 {} \
        -toggle_display [Indxv SELECT_CRITERIA $counter ] open COMPARE

  CreateLine line \
        message "Select reflections which satisfy criteria" \
        label "   Value in first column" \
        widget SELECT_COMPARE_OP \
        label "value in second column"

  CloseSubFrame

# Select on indices

  CreateLine line \
        help SELECT \
        label "   Select reflections satisfying " \
        message "Set constants for equality e.g. 1h-1k+0l=0 gives plane h-k=0" \
        widget SELECT_INDEX_H \
        widget SELECT_INDEX_K \
        widget SELECT_INDEX_L \
        widget SELECT_INDEX_OP \
        message "Set the right-hand side of the expression to be satisfied" \
        widget SELECT_INDEX_SUM \
	toggle_display [Indxv SELECT_CRITERIA $counter ] open INDEX


  CreateLine line \
        help SELECT \
        message "Set an integer value n for the n-fold axis" \
        label "   Specify the multiplicity n of the axis:" \
        widget SELECT_N_FOLD \
        toggle_display [Indxv SELECT_CRITERIA $counter ] open [list MULTI]


  CreateLabinLine line \
        "Select label of column to use" \
	HKLIN "   Column" SELECT_COL_1 {} \
	-toggle_display [Indxv SELECT_CRITERIA $counter ] open [list MISSING PRESENT]

}

#-----------------------------------------------------------------------
proc SftoolsList { arrayname } {
#-----------------------------------------------------------------------

    CreateLine line \
      label "Select columns to list" -italic

    CreateLabinLine line \
        "Choose columns to list" \
        HKLIN "   First" LIST_COL_1 {} \
        -sigma "second" LIST_COL_2 {}

    CreateLabinLine line \
        "Choose columns to list" \
        HKLIN "   third" LIST_COL_3 {} \
        -sigma "fourth" LIST_COL_4 {}

    CreateLabinLine line \
        "Choose columns to list" \
        HKLIN "   fifth" LIST_COL_5 {} \
        -sigma "sixth" LIST_COL_6 {}

}
