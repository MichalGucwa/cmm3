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
# scaleit.tcl --
#
# Run scaleit to scale native and derivative data
#
# CCP4Interface 
#
# =======================================================================


#-------------------------------------------------------------------
proc scaleit_setup { typedefVar arrayname } {
#-------------------------------------------------------------------
  upvar #0 $typedefVar typedef


set typedef(_scale_mode)	{ menu {	"analysis only"
						"scale refinement using Scaleit"
					"scale refinement using Fhscal (Kraut's method)"
					"Fhscal scale refinement & scaleit analysis"
						"apply input scale factors" } 
					{	ANALYSIS
						SCALE
						FHSCAL
						FHSCALANAL
						APPLY } }

set typedef(_scale_refine_mode)	{ menu {	"scale only"
						"scale & isotropic Bfactor"
						"scale & anisotropic Bfactor" } 
					{	"SCALE"
						"ISOTROPIC"
						"ANISOTROPIC" } }

set typedef(_scale_exclude_apply) { varmenu DERIVS_MENU {} 12 }

set typedef(_scale_exclude_mode) { menu {	"< sigmaF *"
						"F >"
						"anomalous SD >"
						"difference from FP >" }
				         {	"SIG"
						"FMAX"
						"DMAX"
						"DIFF" } }
return 1
}

#----------------------------------------------------------------
proc scaleit_run {arrayname } {
#----------------------------------------------------------------
  upvar #0 $arrayname array

  set filename [GetFullFileName0 $arrayname HKLIN]

  if { $array(ANOMALOUS_DATA) && [file exists $filename] } {
    set n_pnames 0
    if { ![GetParamFromFile MTZ $filename PNAMES pnames] ||
      [set n_pnames [llength $pnames]] < [expr 1 +  $array(N_DERIVS)] } {
      if { [regexp Abort [ChooseOptionDialog "Warning: Scaling Anomalous Data" Warning \
"Correct scaling of anomalous data requires that the data is
grouped into datasets in the MTZ file.
The file $array(HKLIN) 
appears to contain $n_pnames datasets. This is less than the number 
of derivatives plus one (for the native dataset).
You might need to Abort and use the 'Edit MTZ Project&Dataset' task 
in 'Reflection Data Utilities' module." \
 [list Continue Abort ] ] ] } { return 0 }
    }
  }
      
    

  set array(GRAPH) [expr { $array(ANALYSE_H) || $array(ANALYSE_K) || \
		$array(ANALYSE_L) || $array(ANALYSE_MODF) } ]

  if [regexp ANALYSIS [GetValue $arrayname SCALE_MODE]] {
    set array(OUTPUT_FILES) ""
  } else {
    set array(OUTPUT_FILES) HKLOUT
  }
  if { !$array(ANOMALOUS_DATA) } { set array(DISP_DIFF) 0 }
  return 1
}


#----------------------------------------------------------------
proc ScaleitDerivs { arrayname counter } {
#----------------------------------------------------------------

  upvar #0 $arrayname array

  UpdateVariableMenu $arrayname append [expr $counter + 2 ]  \
       DERIVS_MENU [list FPH$counter]

  CreateLabinLine line \
    "Choose derivative amplitude (FPHn) and sigma (SIGFPHn)" \
     HKLIN "FPH$counter" FPH  [list FPH$counter *[subst $counter]* ] \
     -sigma "SigFPH$counter" SIGFPH  {}

  CreateLabinLine line \
    "Choose anomalous difference data (DPHn) and sigma (SIGFPHn)" \
     HKLIN "DPH$counter   " DPH  [list DPH$counter *[subst $counter]* ] \
     -sigma "SigDPH  " SIGDPH  {} \
     -toggle_display ANOMALOUS_DATA hide 0

   OpenSubFrame frame -toggle_display  ANOM_DISP_DIFF open 1 

     CreateLabinLine line \
    "Choose derivative amplitude (FPH+n) and sigma (SIGFPH+n)" \
     HKLIN "FPH+$counter" FPHp  [list FPH+$counter \
		*+*[subst $counter]* *[subst $counter]*+*] \
     -sigma "SigFPH+$counter" SIGFPHp  {}

     CreateLabinLine line \
    "Choose derivative amplitude (FPH-n) and sigma (SIGFPH-n)" \
     HKLIN "FPH-$counter" FPHm  [list FPH-$counter \
                *-*[subst $counter]* *[subst $counter]*-*] \
     -sigma "SigFPH-$counter" SIGFPHm  {}

   CloseSubFrame

}

#--------------------------------------------------------------------------------
proc edit_ScaleitDerivs { arrayname counter } {
#--------------------------------------------------------------------------------
# When a deriv is removed need to update variable menu for deriv selection
# Beware it is not necessarily the last deriv that was deleted

  set ll [list "all" "FP" ]
  if { $counter > 0 } {
  for { set n 1 } { $n <= $counter } { incr n } {
    lappend ll "FPH$counter"
  } }

  UpdateVariableMenu $arrayname initialise 1 DERIVS_MENU $ll 
}


#----------------------------------------------------------------
proc ScaleitExclude { arrayname counter } {
#----------------------------------------------------------------

  upvar #0 $arrayname array

  CreateLine line \
   message "Exclude data from scale determination or analysis (EXCLUDE)" \
	help exclude \
	label "For" \
	widget EXCLUDE_APPLY \
	label "exclude reflections" \
	widget EXCLUDE_MODE \
	help exclude_sig \
	widget EXCLUDE_SIGMAF \
        toggle_display [Indxv EXCLUDE_MODE $counter ] open SIG

  CreateLine line \
   message "Exclude data from scale determination or analysis (EXCLUDE)" \
	help exclude \
        label "For" \
        widget EXCLUDE_APPLY \
        label "exclude reflections" \
        widget EXCLUDE_MODE \
	help exclude_fmax \
        widget EXCLUDE_F \
        toggle_display [Indxv EXCLUDE_MODE $counter ] open FMAX


CreateLine line \
   message "Exclude data from scale determination or analysis (EXCLUDE)" \
	help exclude \
        label "For" \
        widget EXCLUDE_APPLY \
        label "exclude reflections" \
        widget EXCLUDE_MODE \
	help exclude_dmax \
        widget EXCLUDE_SIGMAD  \
        toggle_display [Indxv EXCLUDE_MODE $counter ] open DMAX

  CreateLine line \
   message "Exclude data from scale determination or analysis (EXCLUDE)" \
	help exclude \
        label "For" \
        widget EXCLUDE_APPLY \
        label "exclude reflections" \
        widget EXCLUDE_MODE \
	help exclude_diff \
        widget EXCLUDE_DIF_FP \
        toggle_display [Indxv EXCLUDE_MODE $counter ] open DIFF

}

#------------------------------------------------------------------
proc ScaleitInputScale  { arrayname counter } {
#------------------------------------------------------------------

  upvar #0 $arrayname array

  CreateLine line \
   message "Input scale factors to apply to on set of data" \
   help scale \
   label "Scale" \
   widget INPUT_SCALE_APPLY \
   message "Enter Biso in first column or anistotropic scale factors" \
   label "Biso/B11" \
   widget INPUT_SCALE_1 \
	-width 5 \
   label "B22" \
   widget INPUT_SCALE_2 \
	-width 5 \
   label "B33" \
   widget INPUT_SCALE_3 \
	-width 5 \
   label "B12" \
   widget INPUT_SCALE_4 \
	-width 5 \
   label "B13" \
   widget INPUT_SCALE_5 \
	-width 5 \
   label "B23" \
   widget INPUT_SCALE_6 \
	-width 5 


}

#-----------------------------------------------------------------
proc scaleit_anom_disp_diff { arrayname } {
#-----------------------------------------------------------------
  upvar #0 $arrayname array

  if { $array(ANOMALOUS_DATA) && $array(DISP_DIFF) } {
    set array(ANOM_DISP_DIFF)  1
  } else {
    set array(ANOM_DISP_DIFF)  0
  }
}

#-----------------------------------------------------------------
proc scaleittestifdnames { arrayname } {
#-----------------------------------------------------------------
  upvar #0 $arrayname array

  set filename [GetFullFileName0 $arrayname HKLIN]

  if { [file exists $filename]  &&
       [GetParamFromFile MTZ $filename PNAMES pnames]  &&
       [llength $pnames]  > 0 } {
    set array(IFDNAMES) 1
    set array(IFAUTO) 1
  } else {
    set array(IFDNAMES) 0
    set array(IFAUTO) 0
  }

}

#-----------------------------------------------------------------
proc scaleit_task_window { arrayname } {
#-----------------------------------------------------------------

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Scaleit - Scale Datasets" "Scale" \
	[ list "Parameters" \
	"Refinement Parameters" \
	"Exclude Reflections"  \
	"Analysis" \
        "Fhscal Scaling Parameters"  \
        "Input Scaling Factors" ] ] == 0 } return

  SetProgramHelpFile "scaleit"

  UpdateVariableMenu $arrayname initialise 1 DERIVS_MENU \
                           [list "all" "FP" ]

  scaleit_anom_disp_diff $arrayname



#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
    message "Scale protocol - do refinement or analysis" \
     label "Do" \
     widget SCALE_MODE

  CreateLine line \
    message "Also apply calculated scales to anomalous differences for derivative data" \
    help labin \
    widget ANOMALOUS_DATA -command "scaleit_anom_disp_diff $arrayname" \
    label "Include anomalous difference data for each derivative"

  CreateLineTemplate ANOM [list 0.01 0.05 0.5 0.55 ]

  CreateLine line \
    message "Analyse the agreement between the amplitudes for each pair of derivative datasets" \
    widget CROSS_COMPARE \
    label "Perform cross-comparison of derivative data sets" \
    message "Include the anomalous data in the cross-comparison" \
    widget DISP_DIFF -command "scaleit_anom_disp_diff $arrayname" \
    label "and analyse anomalous differences" \
    toggle_display ANOMALOUS_DATA open 1

  CreateLine line \
    message "Analyse the agreement between the amplitudes for each pair of derivative datasets" \
    widget CROSS_COMPARE \
    label "Perform cross-comparison of derivative data sets" \
    toggle_display ANOMALOUS_DATA open 0


#    message "Produce table file containing summary of data analysis" \
#    widget TABULATE_ANALYSIS \
#    label "Tabulate analysis" \
#    toggle_display ANOMALOUS_DATA open 1


#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
       HKLIN DIR_HKLIN \
	-setfileparam space_group_name SPACE_GROUP \
	-setfileparam resolution_min EXCLUDE_RESOLUTION_MIN \
        -setfileparam resolution_max EXCLUDE_RESOLUTION_MAX \
       -fileout HKLOUT DIR_HKLOUT "_scaleit" \
	-command "scaleittestifdnames $arrayname"

  CreateLabinLine line \
    "Choose protein amplitude (FP) and sigma (SIGFP)" \
     HKLIN "FP    " FP  {NULL} \
     -sigma "SigmaFP  " SIGFP  {NULL}


  CreateExtendingFrame N_DERIVS ScaleitDerivs \
	"Define MTZ labels for derivative data (FPHn SIGFPHn)" \
	"Add Derivative Data" \
	[ list FPH SIGFPH \
                FPHp SIGFPHp FPHm SIGFPHm \
		DPH SIGDPH ] \
	-edit edit_ScaleitDerivs

  CreateOutputFileLine line \
	"Enter name for output MTZ file (HKLOUT)" \
	"MTZ out" \
	HKLOUT DIR_HKLOUT _scaled \
	-toggle_display SCALE_MODE hide ANALYSIS




#=PARAMETERS==========================================================

  OpenFolder 1


  CreateLine line \
        message "Scale over limited resolution range (RESOLUTION)" \
	help resolution \
	widget EXCLUDE_RESOLUTION -toggleon \
	label "Scale over resolution range " \
	widget EXCLUDE_RESOLUTION_MIN \
	label "to" \
	widget EXCLUDE_RESOLUTION_MAX

#----------------------------------------------------------------------

# Regular Scaleit input

  OpenFolder 2 SCALE_MODE open SCALE hide { FHSCAL FHSCALANAL } closed

  CreateLine line \
  help auto \
  message "Apply scaling parameters to all structure factor data in same dataset (AUTO)" \
  widget IFAUTO \
  label "Apply scaling to all structure factor data in same dataset(s) as input data" \
  toggle_display IFDNAMES open 1

  CreateLine line \
  message "Refine the scale factors and isotropic/anomalous Bfactors (REFINE)" \
	help refine \
	label "Refine" \
	widget REFINE_MODE \
	label "and    " \
	help refine_wilson \
	widget WILSON_SCALING \
	label "apply Wilson scaling"

  CreateLine line \
  message "Weight observations for scale determination by their SDs (WEIGHT)" \
	help weight \
	widget WEIGHT_BY_SD \
	label "Weight observations by their SDs" 

#  CreateLine line \
#	label "Convergence Conditions"

  CreateLine line \
	message "Converge after <n> cycles of refinement (CONVERGE NCYC)" \
	help converge_ncyc \
	widget CONVERGE_NCYC \
	label "Converge after" \
	widget CONVERGE_NCYC_LIMIT \
	label "cycles of refinement"

  CreateLine line \
        message \
         "Converge if all absolute shifts < SD of parameter (CONVERGE ABS)" \
	help converge_abs \
	widget CONVERGE_ABS \
	label "Converge if absolute shift <" \
	widget CONVERGE_ABS_LIMIT \
	label "SDs of parameter"

  CreateLine line \
        message \
         "Convergence tolerance (CONVERGE TOL)" \
	help converge_tolr \
	widget CONVERGE_TOL \
	label "Convergence tolerance 10 to power" \
	widget CONVERGE_TOL_LIMIT \
	


#-----------------------------------------------------exclude reflection

  OpenFolder 3 SCALE_MODE  hide FHSCAL closed

  CreateExtendingFrame NEXCLUDE ScaleitExclude \
        "Exclude reflections from some or all datasets" \
        "Add Exclusion" \
        [list EXCLUDE_MODE \
                EXCLUDE_APPLY \
                EXCLUDE_SIGMAF \
                EXCLUDE_F \
                EXCLUDE_SIGMAD \
                EXCLUDE_DIF_FP ]

#----------------------------------------------------------analysis
  OpenFolder 4 SCALE_MODE  open ANALYSIS hide FHSCAL closed

  CreateLine line \
        message "Analysis v. resolution is always done, also do...(GRAPH)" \
	help graph \
        label "Include analysis against:    " \
        widget ANALYSE_H \
        label "H    " \
        widget ANALYSE_K \
        label "K    " \
        widget ANALYSE_L \
        label "L    " \
        widget ANALYSE_MODF \
        label "ModF"


#----------------------------------------------------------fhscal options

  SetProgramHelpFile "fhscal"

  OpenFolder 5 SCALE_MODE open { FHSCAL FHSCALANAL } hide

  CreateLine line \
    message  \
   "Split into resolution bins, should have >200 reflections per bin (SHELL) " \
    help shells \
    widget BINS \
    label "Split into" \
    widget N_BINS \
    label "resolution bins"

  CreateLine line \
        message "Use SDs in averaging squares of differences (BIAS)" \
	help bias \
        widget USE_SDS \
        label "Use SIGMAs in averaging squares of differences"

  CreateLine line \
        message "List reflections to output file for analysis (LIST)" \
	help list \
        widget LIST \
        label "List" \
        widget LIST_N_REF \
        label "reflections to output file"

  CreateLine line \
        message ".. all data is scaled and output (CENTRIC)" \
        widget CENTRIC \
        label "Use only centric data to compute scale factors"


#-------------------------------------------User input of scaling parameters

  SetProgramHelpFile "scaleit"

  OpenFolder 6 SCALE_MODE open APPLY hide

  CreateExtendingFrame N_INPUT_SCALES ScaleitInputScale \
        "Input scaling to apply to datasets" \
        "Add Scaling Factors" \
        [list INPUT_SCALE_APPLY \
		INPUT_SCALE_1 \
		INPUT_SCALE_2 \
		INPUT_SCALE_3 \
		INPUT_SCALE_4 \
		INPUT_SCALE_5 \
		INPUT_SCALE_6 ]

}


