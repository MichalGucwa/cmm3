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
# amore.tcl --
#
# CCP4Interface 
#
# =======================================================================

source [SearchPath TOP utils amore_utils.tcl]

#-------------------------------------------------------------------
proc amore_run { arrayname } {
#-------------------------------------------------------------------
  upvar #0 $arrayname array
  upvar #0 mr_database_[GetCurrentProject] mr_database

  set array(AMORE_DATABASE) [FileJoin [GetDbDirPath] mr_database.def ]

  set process [GetValue $arrayname PROCESS]

  if { [StringSame $process AUTO SETUP ROTFUN RESHIFT] } {
    if { $array(MODEL) == "" } { 
      WarningMessage "Select a model from menu at top of interface.
If  you have not already done so then enter details on the model(s) in the MR Database interface."
      return 0
    }
    set model [mr_get_model_number $array(MODEL)]
    if { [StringSame $process RESHIFT ] } {
      set mr_database(XYZIN,$model) $array(MODEL_XYZIN)
      set mr_database(DIR_XYZIN,$model) $array(DIR_MODEL_XYZIN)
      set mr_database(XYZSHFT,$model) $array(MODEL_XYZSHFT)
      set mr_database(DIR_XYZSHFT,$model) $array(DIR_MODEL_XYZSHFT)
    } else {
      set array(MODEL_TITLE) $mr_database(MODEL_TITLE,$model)
      set array(MODEL_MODE) $mr_database(MODEL_MODE,$model)
      set array(MODEL_HKLIN) $mr_database(HKLIN,$model)
      set array(DIR_MODEL_HKLIN) $mr_database(DIR_HKLIN,$model)
      set array(MODEL_XYZIN) $mr_database(XYZIN,$model)
      set array(DIR_MODEL_XYZIN) $mr_database(DIR_XYZIN,$model)
      set array(MODEL_XYZSHFT) $mr_database(XYZSHFT,$model)
      set array(DIR_MODEL_XYZSHFT) $mr_database(DIR_XYZSHFT,$model)
      set array(MODEL_FC) $mr_database(FC,$model)
      set array(MODEL_PHIC) $mr_database(PHIC,$model)
      set array(MODEL_SF_TABLE) $mr_database(SF_TABLE,$model)
      set array(DIR_MODEL_SF_TABLE) $mr_database(DIR_SF_TABLE,$model)
      set array(MODEL_COM_1) $mr_database(MODEL_COM_1,$model)
      set array(MODEL_COM_2) $mr_database(MODEL_COM_2,$model)
      set array(MODEL_COM_3) $mr_database(MODEL_COM_3,$model)
      set array(MODEL_EULER_1) $mr_database(MODEL_EULER_1,$model)
      set array(MODEL_EULER_2) $mr_database(MODEL_EULER_2,$model)
      set array(MODEL_EULER_3) $mr_database(MODEL_EULER_3,$model)
    }
  }

  if { $process == "SELFROT"} {
       if { $array(CRYSTAL_IRMAX) ==""} {
      WarningMessage "Sphere radius for crystal  not set for self rotation"
     return 0
     }
}
  set array(MODEL_LIST) ""
  set array(SF_TABLE_LIST) ""
  set array(XYZIN_LIST) ""
  set array(XYZSHFT_LIST) ""
  for { set n 1 } { $n <= $mr_database(N_MODELS) } { incr n } {
    lappend array(MODEL_LIST) $mr_database(MODEL_TITLE,$n)
    lappend array(SF_TABLE_LIST) \
      [list $mr_database(SF_TABLE,$n) $mr_database(DIR_SF_TABLE,$n) ]
    lappend array(XYZIN_LIST) \
       [list $mr_database(XYZIN,$n) $mr_database(DIR_XYZIN,$n)]
    lappend array(XYZSHFT_LIST) \
	[list $mr_database(XYZSHFT,$n) $mr_database(DIR_XYZSHFT,$n)]
  }



  if { [StringSame  $process RESHIFT ] } {
    set array(INPUT_FILES)  MODEL_XYZIN
    set array(OUTPUT_FILES) MODEL_XYZSHFT
  } else {
    set array(INPUT_FILES) ""
    set array(OUTPUT_FILES) ""
    if [file exists [GetFullFileName0 $arrayname HKLPCK0]] { 
      append array(INPUT_FILES) " " HKLPCK0
    } else {
      append array(INPUT_FILES) " " HKLIN
#      append array(OUTPUT_FILES) " " HKLPCK0
    }
  }

  if { [StringSame $process TRAFUN ] } {
    append  array(INPUT_FILES) " " ROT_SOLUTION_FILE
    if { ![amore_check_mr_symm $arrayname ROT_SOLUTION_FILE] } { return 0 }
  } elseif [StringSame $process FITFUN ] {
    append  array(INPUT_FILES) " " TRAN_SOLUTION_FILE
    if { ![amore_check_mr_symm $arrayname TRAN_SOLUTION_FILE] } { return 0 }
  }

  if { [StringSame $process TRAFUN ] && $array(N_SOLFIL) > 0 } {
    for { set i 1 } { $i <= $array(N_SOLFIL) } { incr i } {
      append  array(INPUT_FILES) " " [Indxv SOLFIL $i]
      if { ![amore_check_mr_symm $arrayname [Indxv SOLFIL $i]] } { return 0 }
    }
  }

  SetDefaultTitle $arrayname "Run $array(PROCESS) for $array(MODEL)"
  return 1
}


#---------------------------------------------------------------------
proc amore_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0  $typedefVar typedef
  upvar #0  $arrayname array
  upvar #0  mr_database_[GetCurrentProject] mr_database

  source [SearchPath TOP tasks mr_utils.tcl]

  set typedef(_amore_process) { menu { "auto-AMoRe"
					"sort & tabling"
					"rotation function"
					"translation function"
					"refine fitting" 
					"get origin shifted model"
					"self rotation function" }
				     {  AUTO
					SETUP
					ROTFUN
					TRAFUN
					FITFUN 
					RESHIFT 
					SELFROT  } }

  set typedef(_amore_refsolution) { menu { "all parameters"
					   "all parameters except y"
					   "all parameters except z" }
					{ "BF AL BE GA X Y Z"
					   "BF AL BE GA X Z"
					   "BF AL BE GA X Y" } }

  set typedef(_amore_rotate_mode) { menu { cross self } { CROSS SELF } }

  set typedef(_amore_translate_mode) { menu { "Crowther-Blow" \
                        "phased translation (no external phases)" \
                        "phased translation (with external phases)" \
			"Harada-Lifchitz" " correlation coefficient" } \
				{ CB PT PTF HL CC } }

  set typedef(_laue_space_group) { varmenu LAUE_SPGP_LIST LAUE_SPGP_ALIAS 8 }

# Load the MR database or open the window

  mr_open_database 

  return 1
}


#---------------------------------------------------------------------
proc amore_check_mr_symm { arrayname fileParam } {
#---------------------------------------------------------------------
# Check that the symmetry in the mr file specified by fileParam
# is consistent with that being used for this amore run
  upvar #0 $arrayname array

  set mrfile [GetFullFileName0 $arrayname $fileParam]
  if { [file exists $mrfile] } {
    set symmetry [lindex [amore_extract_mr_header $mrfile SYMMETRY] 0]
    # No symmetry info found
    if { $symmetry == "" } { return 1 }
    # Symmetry found - does it match?
    if { $symmetry != $array(TEST_SPACE_GROUP) } {
       # Doesn't match - warn the user and offer the option
       # of aborting
       if { [regexp Abort [ChooseOptionDialog "Warning: Inconsistent symmetry" Warning \
"The .mr solution file input file:

$mrfile

was produced using spacegroup [lindex $symmetry 0]
which is different from the spacegroup to be
used in this run ($array(TEST_SPACE_GROUP))

This is likely to cause severe problems!" \
	[list Continue Abort ] ] ] } { return 0 }
    }
  }
  return 1
}

#---------------------------------------------------------------------
proc amore_select_solfiles { arrayname counter } {
#---------------------------------------------------------------------

  CreateInputFileLine line \
     "Enter solution file name" \
     "Solution file" \
      SOLFIL DIR_SOLFIL

}

#-----------------------------------------------------------------------
proc amore_update_n_solfil { arrayname } {
#-----------------------------------------------------------------------
# If user changes from TRAFUN then reset N_SOLFIL to 0
  upvar #0 $arrayname array

  if { $array(N_SOLFIL) > 0 && \
        ![StringSame [GetValue $arrayname PROCESS] TRAFUN] } {

    update_extendingframe amore_select_solfiles 0 $arrayname N_SOLFIL \
        $array(N_SOLFIL) -$array(N_SOLFIL) 1

  }
}


#---------------------------------------------------------------------
proc amore_update_test_model { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array
  upvar #0 mr_database_[GetCurrentProject] mr_database

  if { $array(MODEL) == {} } { return }
  set model [mr_get_model_number $array(MODEL)]
  set array(box) ""
  for { set i 1 } { $i <= 3 } { incr i } {
    lappend array(box) $mr_database(MINIMAL_BOX_[subst $i],$model)
  }

  set array(max_dcom) $mr_database(MAX_DCOM,$model)

# Call procedure to calculate model cell
  amore_update_model_cell $arrayname

  set array(MODEL_XYZIN) $mr_database(XYZIN,$model)
  set array(DIR_MODEL_XYZIN) $mr_database(DIR_XYZIN,$model)
  set array(MODEL_HKLIN) $mr_database(HKLIN,$model)
  set array(DIR_MODEL_HKLIN) $mr_database(DIR_HKLIN,$model)
  set array(MODEL_XYZSHFT) $mr_database(XYZSHFT,$model)
  set array(DIR_MODEL_XYZSHFT) $mr_database(DIR_XYZSHFT,$model)

}

#---------------------------------------------------------------------
proc amore_update_model_cell { arrayname { mode all} } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

# This procedure uses same algorthm as amore_calc_model_cell in
# utils/amore_util.tcl - these procedures should be kept the same

# The box for the model should have been got from database when
# the user chose the model 
  if { ![ElementExists $arrayname box] || [lindex $array(box) 0] == "" ||
   ![ElementExists $arrayname max_dcom] || $array(max_dcom) == ""} { return }

# Has the user chosen a exptl data file?
  if {![file exists [GetFullFileName0 $arrayname HKLIN]] || \
	$array(CRYSTAL_CELL_1) == "" } { return }

  if [regexp all $mode ] {
#    set min_rad 9999999.9
#    foreach dim $array(box) { set min_rad [min $dim $min_rad] }
#    set irmax [expr 0.75 * $min_rad ]
    set irmax [expr 0.8 * $array(max_dcom) ]
    foreach cell_length [list $array(CRYSTAL_CELL_1) \
	$array(CRYSTAL_CELL_2) $array(CRYSTAL_CELL_3)]  {
      set dim [expr $cell_length / 2.0 ]
      if { $dim < $irmax } { set irmax $dim }
    }
    if { $array(MODEL_IRMAX) == "" } {  set array(MODEL_IRMAX) $irmax }
  }

  set i 0; foreach bx $array(box) { incr i
    set array(MODEL_CELL_[subst $i]) [expr $bx + $array(MODEL_IRMAX) + 5.0 ]
  }

}



#---------------------------------------------------------------------
proc amore_set_test_space_group { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  set spgp_list {}
  set spgp_alias {}

  set laue_no [GetLaueGroupNumber $array(FILE_SPACE_GROUP)]
# update the varlabel
  set field_list [GetWidget $arrayname FILE_SPACE_GROUP]
  foreach field $field_list {
    if { [ winfo exists $field] } { $field configure -text $array(FILE_SPACE_GROUP) }
  }


  if { $laue_no <= 0 } {
    lappend spgp_list $array(FILE_SPACE_GROUP)
    lappend spgp_alias [GetSpaceGroupNumber $array(FILE_SPACE_GROUP)]
  } else {
    set spgp_alias [GetLaueGroup $laue_no]
    foreach gp_no $spgp_alias {
      lappend spgp_list [GetSpaceGroupCode $gp_no]
    }
  }

  UpdateVariableMenu $arrayname initialise [llength $array(LAUE_SPGP_LIST)] \
        LAUE_SPGP_LIST $spgp_list \
        LAUE_ALIAS_LIST $spgp_alias

  set array(TEST_SPACE_GROUP) [GetSpaceGroupCode $array(FILE_SPACE_GROUP)]

}

#-----------------------------------------------------------------------
proc amore_set_res_max_limit { arrayname limit  } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { $array(RESOLUTION_MAX) == "" } { return }
  set array(RESOLUTION_MAX) [max $limit $array(RESOLUTION_MAX)]
}


#---------------------------------------------------------------------
proc amore_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array


  if { [CreateTaskWindow $arrayname  \
    	"AMoRe" "AMoRe" \
        [ list "Key Parameters" \
		"Reorient Trial Model" \
		"Sort & Tabling Parameters"  \
                "Modify Crystal Data for Rotation and/or Translation" \
		"Rotation Function Parameters" \
		"Translation Function Parameters" \
		"Refine Fitting Parameters" \
		"Memory Allocation"  ] \
	] == 0 } return

  mr_copy_memory mr_database $arrayname
  mr_model_menu $arrayname
  amore_update_test_model $arrayname
  SetProgramHelpFile "amore"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateLine line \
    message "Open the MR Model Database window" \
    button "Open MR Model Database window" \
        -command "RunTask mr_database"

  pack forget $line.b1
  pack $line.b1 -side right


  CreateTitleLine line TITLE

  CreateLine line \
    label "Run" \
    message "Select one AMoRe function or do 'automatic AMoRe'" \
    help function \
    widget PROCESS \
	-command "amore_update_n_solfil $arrayname"

  CreateLine line \
    widget VERBOSE \
    label "Verbose output"

#  CreateLine line \
#    widget IFKNOWN \
#    label "Enter known solutions for multi-molecule in asymmetric unit"

#---------------------------------------------------------------files
  OpenFolder file

  CreateLine line \
    label "Use trial model" \
    message "Choose one of the models from the MR database" \
    widget MODEL \
	-command "amore_update_test_model $arrayname" \
    toggle_display PROCESS hide [list SELFROT TRAFUN FITFUN ]

  CreateInputFileLine line \
     "Enter input solution file name" \
     "Rotation solution file" \
      ROT_SOLUTION_FILE DIR_ROT_SOLUTION_FILE  \
	-toggle_display PROCESS open TRAFUN

    CreateInputFileLine line \
     "Enter input solution file name" \
     "Translation solution file" \
      TRAN_SOLUTION_FILE DIR_TRAN_SOLUTION_FILE  \
        -toggle_display PROCESS open FITFUN

  OpenSubFrame frame -toggle_display PROCESS open [list TRAFUN FITFUN]

  CreateLine line \
    label "Enter solution file(s) for 'known' molecules" -italic

  CreateExtendingFrame N_SOLFIL amore_select_solfiles \
    "Select additional models to use in this run of AMoRe" \
    "Add known solutions" \
    [ list SOLFIL DIR_SOLFIL ]

  CloseSubFrame


  OpenSubFrame frame -toggle_display PROCESS hide [list RESHIFT ]

  CreateLine line \
    label "Experimental data - enter MTZ file and its derived packed data file" -italic

  CreateInputFileLine line \
      "Enter observed data MTZ file name (HKLIN)" \
      "MTZ in" HKLIN DIR_HKLIN \
        -filein HKLPCK0 DIR_HKLPCK0 -- \
        -setfileparam cell_1 CRYSTAL_CELL_1 \
        -setfileparam cell_2 CRYSTAL_CELL_2 \
        -setfileparam cell_3 CRYSTAL_CELL_3 \
        -setfileparam cell_4 CRYSTAL_CELL_4 \
        -setfileparam cell_5 CRYSTAL_CELL_5 \
        -setfileparam cell_6 CRYSTAL_CELL_6 \
        -setfileparam resolution_max RESOLUTION_MAX \
        -setfileparam resolution_max MTZ_RESOLUTION_MAX \
        -setfileparam resolution_max SORT_RESOLUTION_MAX \
        -setfileparam space_group_name FILE_SPACE_GROUP \
	-command "amore_set_test_space_group $arrayname" \
	-command "amore_set_res_max_limit $arrayname 3.0" \
	-command "amore_update_model_cell $arrayname"

 CreateLabinLine line \
        "Observed amplitude (FP) and obligatory sigma (SIGFP)" \
        HKLIN FP FP0  {FP F_P} \
        -sigma Sigma SIGFP0  {SIGFP SIGF_P SIGP }

  CreateLine line \
    label "The following input packed hkl is generated from the MTZ file on the first AMoRe run" -italic

  CreateInputFileLine line \
        "Packed hkl file (HKLPCK0)" \
        "Packed hkl file" \
        HKLPCK0 DIR_HKLPCK0 \
	-notoblig

  CloseSubFrame

  OpenSubFrame frame -toggle_display PROCESS open [list RESHIFT ]

  CreateInputFileLine line \
       "Original coords file (default from MR database) (XYZIN)" \
        "Input original coords" \
	MODEL_XYZIN DIR_MODEL_XYZIN \
	-help step_tabling 

  CreateOutputFileLine line \
        "Shifted coords file (default from MR database) (XYZOUT)" \
        "Output shifted coords" \
        MODEL_XYZSHFT DIR_MODEL_XYZSHFT \
	-help step_tabling 

  CloseSubFrame

  CreateLine line \
    message "Create a map representation of the rotation/translation result" \
    widget IFMAPOUT \
    label "Output map of the rotation and/or translation function" \
    toggle_display PROCESS open [list AUTO ROTFUN SELFROT TRAFUN]


#------------------------------------------------------------------------
  OpenFolder 1 PROCESS closed [list RESHIFT ] open

  CreateLine line \
    message "Space group assigned in MTZ file" \
    label "Space group read from file" \
    varlabel FILE_SPACE_GROUP \
    message "Test alternative space groups?" \
    label ". Run AMoRe with test space group" \
    widget TEST_SPACE_GROUP

#      -command "amore_set_test_space_group $arrayname" \

  CreateLine line \
    message "Resolution in Angstrom (minimum is the biggest number!)(GENERATE/CLMN RESOLUTION)" \
    help roting_clmn_resolution \
    label "Resolution range from minimum" \
    widget RESOLUTION_MIN \
    label "to maximum" \
    widget RESOLUTION_MAX

  CreateLine line \
    message "Enter sphere to override value derived from model extent(CLMN SPHERE)" \
    help roting_clmn_sphere \
    label "Rotation function search sphere" \
    widget MODEL_IRMAX \
	-command "amore_update_model_cell $arrayname cell" \
    message "Fitting: refine which parameters (REFSOLUTION)" \
    help fitfun_refsolution \
    label "   Fitting: refine" \
    widget REFSOLUTION \
    toggle_display PROCESS hide [list SELFROT ]


  CreateLine line \
    message "Enter sphere to override value derived from model extent(CLMN SPHERE)" \
    help roting_clmn_sphere \
    label "Rotation function search sphere" \
    widget MODEL_IRMAX -oblig \
    toggle_display PROCESS open [list SELFROT ]


  CreateLine line \
    widget UPDATE_DATABASE \
    label "Update MR Model Database from this AMoRe run"

#------------------------------------------------------------------reorient

  OpenFolder 2 PROCESS open [list RESHIFT ] closed

  CreateLine line \
    message "Default is to move model to origin and reorient (NOROTATE/NOTRANSLATE)" \
    help tabling_tabfun_norotate \
    widget TABFUN_ROTATE \
    label "Rotate and" \
    help tabfun_notranslate \
    widget TABFUN_TRANSLATE \
    label "translate model to optimal coords"

#  OpenSubFrame frame -toggle_display PROCESS closed [list RESHIFT] 
#------------------------------------------------------------------tabling

  OpenFolder 3 closed  

  CreateLine line \
    message "Default to output table file which can be used in subsequent runs(NOTAB/NOHKLOUT)" \
    help tabfun_notab \
    widget TABFUN_TABLE \
    label "Output table file and" \
    help tabfun_hklout \
    widget TABFUN_HKLOUT \
    label "ascii version of table file"

  CreateLine line \
    message "Generate table using modified B-factors(BREPLACE/BADD)" \
    label "Set Bfactors to" \
    help tabfun_model_breplace \
    widget BREP0  \
    help tabfun_model_badd \
    label "and add" \
    widget BADD0 \
    label "to input Bfactors"

  CreateLine line \
    message "Larger model cell implies finer sampling in reciprocal space(SAMPLE SCALE)" \
    label "Set model cell to" \
    help tabfun_sample_scale \
    widget TABFUN_SCALE0 \
    message "Sampling uses grid of about Dmin/(2*Shannon) (SAMPLE SHANNON)" \
    label "* minimal box and use Shannon sampling frequency" \
    help tabfun_sample_shann \
    widget TABFUN_SHANN0

#  CloseSubFrame


#----------------------------------------------modify crystal parameters
  OpenFolder 4  closed

  CreateLine line \
    message "Crystal cell parameters put in coord file header (CRYSTAL CELL_CRYST)" \
    help tabfun_crystal \
    label "Crystal cell" \
    widget CRYSTAL_CELL_1 \
    widget CRYSTAL_CELL_2 \
    widget CRYSTAL_CELL_3 \
    widget CRYSTAL_CELL_4 \
    widget CRYSTAL_CELL_5 \
    widget CRYSTAL_CELL_6

  CreateLine line \
    message "Limit range of experimental SF's in rotate/translate (CLMN CRYSTAL FMIN/FMAX)" \
    label "Limit F values to range" \
    help rotfun_clmn_flim \
    widget CRYSTAL_FMIN \
    label "to" \
    widget CRYSTAL_FMAX \
    help rotfun_clmn_sharpen \
    message "Apply sharpening Bvalue to experimental data (CLMN SHARP)" \
    label "Apply sharpening Bvalue" \
    widget CRYSTAL_BADD

  CreateLine line \
    message "Code from MTZ file put in coord file header (CRYSTAL ORTH)" \
    help tabfun_crystal_orth \
    label "Orthogonalisation code" \
    widget CRYSTAL_ORTH


#---------------------------------------------------rotation function params

  OpenFolder 5 PROCESS open [list SELFROT ] closed

  OpenSubFrame frame -toggle_display PROCESS hide [list SELFROT ]

   CreateLine line \
    label "Modify model data" -italic 

  CreateLine line \
    message "Model cell parameters used in rotation function derived from minimal box (CELL_MODEL)" \
    label "Model cell x=" \
    widget MODEL_CELL_1 \
    label "y=" \
    widget MODEL_CELL_2 \
    label "z=" \
    widget MODEL_CELL_3 \

  CreateLine line \
    message "Limit range of model SF's in rotate/translate (CLMN MODEL FMIN/FMAX)" \
    label "Limit F values to range" \
    help rotfun_clmn_flim \
    widget MODEL_FMIN \
    label "to" \
    widget MODEL_FMAX \
    message "Apply sharpening factor to model SFs (CLMN MODEL SHARP)" \
    label "Apply sharpening Bvalue" \
    help roting_clmn_sharp \
    widget ROTATE_MODEL_BADD \

  CloseSubFrame

  CreateLine line \
    message "Override radius of integration sphere derived from model extent (CLMN MODEL SPHERE)" \
    label "Calculate spherical harmonics - sphere radius for crystal" \
    help rotfun_clmn_sphere \
    widget CRYSTAL_IRMAX -oblig  \
    toggle_display PROCESS open [list SELFROT ]

  CreateLine line \
    message "Override radius of integration sphere derived from model extent (CLMN MODEL SHERE)" \
    label "Calculate spherical harmonics - sphere radius for crystal" \
    help rotfun_clmn_sphere \
    widget CRYSTAL_IRMAX    \
    toggle_display PROCESS hide [list SELFROT ]

  CreateLine line \
    label "Calculate rotation function" \
	-italic

  CreateLine line \
    message "Use Bessel spherical harmonic function  (ROTATE BESLIM)" \
    help rotfun_rotate_beslim \
    widget BESLIM \
	-toggleon \
    label "Use spherical harmonic functions between" \
    widget BESLIM_MIN  \
    label and \
    widget BESLIM_MAX

  CreateLine line \
    message "Default step size 2.5degs (ROTATE STEP)" \
    help rotfun_rotate_step \
    label "Angular step size" \
    widget ROTFUN_STEP \
    label "and maximum beta angle" \
    message "Maximum beta angle to consider (def 180)(ROTATE BMAX)" \
    help roting_rotate_bmax \
    widget ROTFUN_BMAX

  CreateLine line \
    message "Control picking of output peaks (ROTATE NPIK PKLIM)" \
    label "Find" \
    help rotfun_rotate_npic \
    widget ROTFUN_NPIC \
    label "peaks above" \
    help rotfun_rotate_pklim \
    widget ROTFUN_PKLIMC \
    label "fraction of maximum peak height" \
    toggle_display PROCESS hide [list SELFROT ]

  CreateLine line \
    message "Control picking of output peaks (ROTATE NPIK PKLIM)" \
    label "Find" \
    help rotfun_rotate_npic \
    widget ROTFUN_NPIC \
    label "peaks above" \
    help rotfun_rotate_pklim \
    widget ROTFUN_PKLIMS \
    label "fraction of maximum peak height" \
    toggle_display PROCESS open [list SELFROT ]
#-------------------------------------------translation function parameters
  OpenFolder 6 closed

  CreateLine line \
    message "Translation mode (TRAING CB|PT)" \
    help trafun_target \
    label "Use" \
    widget TRAFUN_MODE \
    label "method"

  CreateLine line \
    message "Control picking of output peaks (TRAING NPIK PKLIM)" \
    label "Find" \
    help trafun_npic \
    widget TRAFUN_NPIC \
    label "peaks above" \
    help trafun_pklim \
    widget TRAFUN_PKLIM \
    label "fraction of maximum peak height"


#-----------------------------------------------------------------refine
  OpenFolder 7 closed

  CreateLine line \
    message "Override fitting refinement parameters (FITFUN ITER/CONV)" \
    label "Refine for" \
    help fitfun_iter \
    widget FITFUN_NITER \
    label "iterations or to convergence acceptance" \
    help fitfun_conv \
    widget FITFUN_CONV

#-----------------------------------------------------------------memory

  OpenFolder 8 closed

  DrawMemoryWidgets

}

