#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
# =====================================================================
# acorn.tcl --
# Template for task interface
# CCP4Interface 
# =======================================================================

#-----------------------------------------------------------------------
proc acorn_setup { typedefVar arrayname } {
#-----------------------------------------------------------------------

  DefineMenu _acorn_protocol [list "start from random atom (no prior knowledge)" \
                                   "search and phase with starting coordinates" \
                                   "phase from known starting coordinates" \
                                   "phase from starting phases" ] \
                             [list NONE SOMECOORD KNOWNCOORD SOMEPHASE ]

  DefineMenu _acorn_protocolsub [list "substructure" \
                                      "heavy atoms(s) at lower resolution" \
                                      "small molecule" ] \
                                [list NONESUB NONEHALOW NONESMALL ]

  DefineMenu _select_model [list "all atoms from coordinate file" \
                                 "one subset of fragments of specified length and starting point:" \
                                 "more than one subset of fragments of specified length:" ] \
                           [list NAFRAGALL NSTARTN NSTARTR ]

  DefineMenu _acorn_mr_mode [list "no prior MR information" \
                                  "previous MR solution(s) from ACORN" \
                                  "previous MR solution(s) from AMoRe" ] \
                            [list MRNONE MRACORN MRAMORE]

  DefineMenu _acorn_rot_mode [list "standard rotation function" "random rotation function"] \
                             [list ROTF RROT]
  DefineMenu _acorn_tra_mode [list "standard translation function" "random translation function"] \
                             [list TRAN RTRA]

  DefineMenu _select_strong [list "program default" \
                                  "total number" \
                                  "lower limit on E-value" ] \
                            [list STRONGDEF STRONGNUM STRONGVAL ]
  DefineMenu _select_weak [list "program default" \
                                "total number" \
                                "upper limit on E-value" ] \
                          [list WEAKDEF WEAKNUM WEAKVAL ]
  return 1
} 


#-----------------------------------------------------------------------
proc acorn_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { $array(ACORN_ECALC) } {
    set array(OUTPUT_FILES) "MTZECALC HKLOUT"
    if { [StringSame [GetValue $arrayname ACORN_PROTOCOL] "SOMECOORD" "KNOWNCOORD"] } { 
      set array(INPUT_FILES) "HKLIN XYZIN"
    } else {
      set array(INPUT_FILES) "HKLIN"
    }

  } else {
    set array(OUTPUT_FILES) "HKLOUT"
    if { [StringSame [GetValue $arrayname ACORN_PROTOCOL] "SOMECOORD" "KNOWNCOORD"] } {
      set array(INPUT_FILES) "HKLIN XYZIN"
    } else {
      set array(INPUT_FILES) "HKLIN"
    }
  }
  return 1
}

#---------------------------------------------------------------------
proc acorn_protocol_params { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if [regexp NONE [ GetValue $arrayname ACORN_PROTOCOL ] ] {
     set array(RATM) 1
     set array(KNOWN_FRAG) 0
     set array(IFMR) 0
  }

  if [regexp SOMEPHASE [ GetValue $arrayname ACORN_PROTOCOL ] ] {
     set array(RATM) 0
     set array(KNOWN_FRAG) 0
     set array(IFMR) 0
  }

  if [regexp SOMECOORD [ GetValue $arrayname ACORN_PROTOCOL ] ] {
     set array(RATM) 0
     set array(KNOWN_FRAG) 0
     set array(IFMR) 1
  }

  if [regexp KNOWNCOORD [ GetValue $arrayname ACORN_PROTOCOL ] ] {
     set array(RATM) 0
     set array(KNOWN_FRAG) 1
     set array(IFMR) 0
  }

  if { [regexp NONE [ GetValue $arrayname ACORN_PROTOCOL ] ]  && \
     [regexp NONESMALL [ GetValue $arrayname ACORN_PROTOCOLSUB ] ] } {
     set array(IFGRIDSMALL) 1
     set array(IFGRIDDEF) 0
#     set array(GRID) 0.5
     set array(RATM) 1
     set array(KNOWN_FRAG) 0
     set array(IFMR) 0
    } else {
     set array(IFGRIDSMALL) 0
#     set array(GRIDSMALL) 0.3
    }

  if { [regexp NONE [ GetValue $arrayname ACORN_PROTOCOL ] ] && \
     [regexp NONEHALOW [ GetValue $arrayname ACORN_PROTOCOLSUB ] ] } {
     RunTask prephadata
     set array(RATM) 1
     set array(KNOWN_FRAG) 0
     set array(IFMR) 0
     set array(EXCLUDE_RESO_HALOW) 1
     set array(EXCLUDE_RESO_HI_HALOW) 3.5
     set array(EXCLUDE_RESOLUTION) 0
    } else {
     set array(EXCLUDE_RESO_HALOW) 0
     set array(EXCLUDE_RESO_HI_HALOW) ""
    }
}

#---------------------------------------------------------------------
proc AcornContent { arrayname counter } {
#---------------------------------------------------------------------

  CreateLine line \
    message "(CONTENT)" \
    label "Unit cell contains" \
    widget CONT_NUMB \
    label "entities of element symbol" \
    widget CONT_SYMB
}

#---------------------------------------------------------------------
proc AcornTrialRuns { arrayname counter } {
# Draw one line of the trial runs extending frame
#---------------------------------------------------------------------
   CreateLine line \
      message "Set values of NCSER and NCDDM for trial run (NTRY will be set automatically)" \
      label "NCSER:" widget NCSER \
      label "NCDDM:" widget NCDDM
}

#-----------------------------------------------------------------------
proc  acorn_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname "Acorn - ab initio Phasing at Atomic Resolution" "Acorn" \
        [ list  "General Acorn Parameters" \
		"Selecting Reflection Data" \
                "Selecting Model Parameters" \
		"ACORN-MR Parameters" \
		"ACORN-PHASE Parameters" \
		"Map Peaks Search"   ]  ] == 0 } return

  SetProgramHelpFile acorn

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
    message "Default parameters will be set appropriate for requested protocol" \
    label "Set optimal Acorn parameters to" \
    widget ACORN_PROTOCOL -command "acorn_protocol_params $arrayname"

  CreateLine line \
    message "Appropriate parameters will be set for requested sub-protocol" \
    label "                                   to determine" \
    widget ACORN_PROTOCOLSUB -command "acorn_protocol_params $arrayname" \
    toggle_display ACORN_PROTOCOL open [list NONE]

  SetProgramHelpFile ecalc
  CreateLine line \
    message "Run ECALC to generate normalised structure factors from Fs" \
    widget ACORN_ECALC \
    label "generate normalised structure factors"

  SetProgramHelpFile acorn
  CreateLine line \
    message "Extend data for use with EXTEND option of Acorn" \
    widget ACORN_EXTEND \
    label "artificially extend data to 1.0A, and" \
    message "Anisotropy correction often helps and should not cause harm" \
    widget ACORN_ANIS \
    label "perform anisotropy correction" \
    toggle_display ACORN_ECALC open 1

  SetProgramHelpFile peakmax
  CreateLine line \
    message "Run FFT to generate map and Peaksearch to generate coordinate file" \
    widget ACORN_PEAKSEARCH \
    label "generate map and coordinate file listing peaks"

#------------------------------------------------------------------Files
  OpenFolder file 

 SetProgramHelpFile acorn

  CreateInputFileLine line \
      "Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
       HKLIN DIR_HKLIN \
       -fileout MTZECALC DIR_MTZECALC _ecalc  \
       -fileout HKLOUT DIR_HKLOUT _acorn  \
       -setfileparam space_group_name SPACE_GROUP \
       -setfileparam resolution_min EXCLUDE_RESOLUTION_LO \
       -setfileparam resolution_max EXCLUDE_RESOLUTION_HI

   CreateLabinLine line \
    "Choose observed structure factor (FP)" \
     HKLIN FP FP [ list FP FVA F ] \
     -sigma SIGFP SIGFP [ list SIGFP SIGFVA ]

   CreateLabinLine line \
    "Choose normalised amplitude (E)" \
     HKLIN Es E  [ list E EVAL ]  \
     -sigma SIGE SIGE [ list SIGE SIGEVAL ] \
     -toggle_display ACORN_ECALC hide 1

   CreateLabinLine line \
    "Input phases (PHIN & WTIN)" \
     HKLIN "Input phase" PHIN [ list PHIN PHI ] \
     -sigma FOM WTIN [ list WTIN WT FOM ] \
     -toggle_display ACORN_PROTOCOL open SOMEPHASE

   CreateLine line \
     message "Calculate phase errors with proper origin shifts for both enantiomorphs" \
     widget USE_PHIFT \
     label "Calculate phase errors from phases of final model"

   CreateLabinLine line \
    "Choose phases from final model for phase error calculation (PHIFT)" \
    HKLIN "Final model phases" PHIFT [list PHIFT] \
    -toggle_display USE_PHIFT open 1

  CreateInputFileLine line \
      "Enter input coordinate file name (XYZIN)" \
      "PDB in" \
       XYZIN DIR_XYZIN \
      -toggle_display ACORN_PROTOCOL open [ list SOMECOORD KNOWNCOORD ]

  SetProgramHelpFile ecalc
  CreateOutputFileLine line \
      "Output MTZ file from ECALC" \
      "Ecalc MTZ out" \
      MTZECALC DIR_MTZECALC \
      -toggle_display ACORN_ECALC open 1

  SetProgramHelpFile acorn
  CreateOutputFileLine line \
      "Output MTZ file from ACORN" \
      "Acorn MTZ out" \
      HKLOUT DIR_HKLOUT

  CreateLaboutLine line \
    "Enter names for output column labels for calculated PHIs and WTs (LABOUT)" \
    HKLOUT Phi PHIOUT \
     -sigma Weight WTOUT

#=PARAMETERS==========================================================

  OpenFolder 1 ACORN_PROTOCOLSUB open [list NONESMALL NONEHALOW] closed

  SetProgramHelpFile acorn

  CreateLine line \
    label "Enter unit cell content (not necessary for C,N,O,S):" -italic

  CreateExtendingFrame ADDCONTENT AcornContent \
        "Enter contents of unit cell (not necessary for C,N,O,S)" \
        "Add content" \
        [list CONT_NUMB CONT_SYMB ]

  CreateLine line \
    message "sampling for FFT (GRID)" \
    widget IFGRIDDEF \
        -toggleon \
    label "Use" \
    widget GRID \
    label "high-resolution-limit for grid sampling" \
    toggle_display ACORN_PROTOCOL open [list SOMEPHASE KNOWNCOORD SOMECOORD ]

  OpenSubFrame frame -toggle_display ACORN_PROTOCOL open NONE

  CreateLine line \
    message "sampling for FFT (GRID)" \
    widget IFGRIDDEF \
        -toggleon \
    label "Use" \
    widget GRID \
    label "high-resolution-limit for grid sampling" \
    toggle_display ACORN_PROTOCOLSUB open [list NONESUB NONEHALOW ]

  CreateLine line \
    message "sampling for FFT for small molecule determination (GRID), fraction of high-resolution-limit" \
    widget IFGRIDSMALL \
        -toggleon \
    label "Use" \
    widget GRIDSMALL \
    label "Angstrom grid sampling for small molecule determination" \
    toggle_display ACORN_PROTOCOLSUB open NONESMALL

  CloseSubFrame

  CreateLineTemplate PARAMS [list 0.0 0.85]

  CreateLine line \
    message "Integer seed for random number generator (SEED)" \
    widget IFSEED \
        -toggleon \
    label "SEED  for random number generator" \
    widget SEED \
    format template PARAMS

#-----------------------------------------------------Selecting Reflection Data
  OpenFolder 2 ACORN_PROTOCOLSUB open NONEHALOW closed

  CreateLine line \
    message "Use data from default resolution range (RESO)" \
    widget EXCLUDE_RESOLUTION \
	-toggleon \
    label "Use data from resolution range"  \
    widget EXCLUDE_RESOLUTION_LO \
    label "to" \
    widget EXCLUDE_RESOLUTION_HI \
    toggle_display ACORN_PROTOCOL open [list NONE SOMEPHASE SOMECOORD KNOWNCOORD ]

  CreateLine line \
    message "Use data from lower resolution range (RESO)" \
    widget EXCLUDE_RESO_HALOW \
	-toggleon \
    label "Use data from resolution range"  \
    widget EXCLUDE_RESOLUTION_LO \
    label "to" \
    widget EXCLUDE_RESO_HI_HALOW \
    toggle_display ACORN_PROTOCOLSUB open NONEHALOW

  CreateLine line \
    message "Exclude data with Fs less than SIGCUT*sigma (EXCLUDE)" \
    widget IFSIGCUT \
        -toggleon \
    label "Exclude reflections with Fs less than" \
    widget EXCLUDE \
    label "sigma"  

  CreateLine line \
    message "Override default upper limit on amplitudes (ECUT)" \
    widget IFECUT \
	-toggleon \
    label "Override default upper limit on E-values" \
    widget ECUT

  CreateLine line \
    label "Select strong reflections for phase refinement based on" \
    widget STRONGSEL -width 18 \
    toggle_display STRONGSEL open STRONGDEF

  CreateLine line \
    label "Select strong reflections for phase refinement based on" \
    widget STRONGSEL -width 18 \
    label ";use" \
    message "Number of strong reflections to be used in phase refinement (NSTRONG)" \
    widget NSTRONG -oblig \
    toggle_display STRONGSEL open STRONGNUM

  CreateLine line \
    label "Select strong reflections for phase refinement based on" \
    widget STRONGSEL -width 18 \
    label ";use" \
    message "Lower limit of E-values for strong reflections to be used in phase refinement (ESTRONG)" \
    widget ESTRONG \
    toggle_display STRONGSEL open STRONGVAL

  CreateLine line \
    label "Select weak reflections for Sayre equation refinement based on" \
    widget WEAKSEL -width 18 \
    toggle_display WEAKSEL open WEAKDEF

  CreateLine line \
    label "Select weak reflections for Sayre equation refinement based on" \
    widget WEAKSEL -width 18 \
    label ";use" \
    message "Number of weak reflections to be used in Sayre equation refinement (NWEAK)" \
    widget NWEAK -oblig \
    toggle_display WEAKSEL open WEAKNUM

  CreateLine line \
    label "Select weak reflections for Sayre equation refinement based on" \
    widget WEAKSEL -width 18 \
    label ";use" \
    message "Upper limit of E-values for weak reflections to be used in Sayre equation refinement (EWEAK)" \
    widget EWEAK \
    toggle_display WEAKSEL open WEAKVAL

#-----------------------------------------------------Selecting Model Parameters
  OpenFolder 3 ACORN_PROTOCOL open [list SOMECOORD KNOWNCOORD PREVMR ] hide

  CreateLine line \
    label "Use" \
    widget MODELSEL

  CreateLine line \
    label "Use fragment of length" \
    message "(NAFRAG)" \
    widget NAFRAG \
    label "; starting from atom" \
    message "(NSTART)" \
    widget NSTART \
    label "in the coordinate file" \
    toggle_display MODELSEL open NSTARTN

  CreateLine line \
    label "Use" \
    message "(POSI)" \
    widget POSI \
    label "subsets of fragments of length" \
    message "(NAFRAG)" \
    widget NAFRAG \
    label "(starting point will be random)" \
    toggle_display MODELSEL open NSTARTR


#-----------------------------------------------------ACORN-MR parameters
  OpenFolder 4 ACORN_PROTOCOL open [list NONE SOMECOORD PREVMR ] hide

#This should serve example 1
#Need keyword(s):
#         RATM <nratm> <percentage>
#RATM acquired new sub-keyword (percentage) OCT-2001
#no longer need keywords NAFRAG and NSTART for this protocol option

  CreateLine line \
    message "Use random atom(s) as starting point" \
    widget RATM \
        -toggleon \
    label "Generate" \
    message "number of starting sets (RATM nratm)" \
    widget NRATM \
    label "sets of single random atom fragments with" \
    message "percentage of reflections used for CC calculation (RATM percentage)" \
    widget RATM_PERC \
    label "% of reflections used for CC calculation" \
    toggle_display ACORN_PROTOCOL open [list NONE ]

#This should serve example 3,4,5
#Need keyword(s):
#         POSI
#         NAFRAG
#         NSTART

#  CreateLine line \
#    message "Use known substructure as starting point" \
#    widget KNOWN_FRAG \
#        -toggleon \
#    label "Use" \
#    message "(POSI)" \
#    widget POSI \
#    label "set(s) of randomly selecting" \
#    message "(NSTART)" \
#    widget NSTART \
#    label "th starting atom from input fragment with length" \
#    message "(NAFRAG)" \
#    widget NAFRAG \
#    toggle_display ACORN_PROTOCOL open [ list SOMECOORD PREVMR ]

#This may be used in future, if the use of previous MR solutions has
#been accepted as a good idea; might be better done via coordinates
#rather than previous solutions...
#  CreateLine line \
#    message "Prior Molecular Replacement information" \
#    widget IFPRIORMR \
#        -toggleon \
#    label "Use" \
#    message "(INITIAL/SOLUTION)" \
#    widget MRMODE \
#    label "in ACORN-MR stage" \
#    toggle_display ACORN_PROTOCOL open PREVMR
#    
#  OpenSubFrame frame -toggle_display ACORN_PROTOCOL open PREVMR
#
#  CreateInputFileLine line \
#      "Enter Acorn INITIAL solutions file name (.mr)" \
#      "Acorn solution file" \
#       SOLFIL DIR_SOLFIL \
#      -toggle_display MRMODE open MRACORN
#
#  CreateInputFileLine line \
#      "Enter AMoRe solution file name (.mr)" \
#      "AMoRe solution file" \
#       SOLFIL DIR_SOLFIL \
#      -toggle_display MRMODE open MRAMORE
#
#  CloseSubFrame

#This should serve example 5
#Need keyword(s):
#         ROTF
#         TRAN
#         RROT
#         RTRA

  CreateLine line \
    message "Molecular Replacement search" \
    widget IFMR \
        -toggleon \
    label "Use" \
    message "(ROTF/RROT)" \
    widget ROTMODE -width 25 \
    label "and" \
    message "(TRAN/RTRA)" \
    widget TRAMODE -width 27 \
    label "for MR search" \
    toggle_display ACORN_PROTOCOL open [ list SOMECOORD PREVMR ]

  OpenSubFrame frame -toggle_display IFMR open 1

    CreateLine line \
      message "Rotation Function parameters" \
      label "Rotate" \
      message "(ROTF_STEP)" \
      widget ROTF_STEP \
      label "degree steps using" \
      message "(ROTF_PERC)" \
      widget RF_PERC \
      label "% of reflections to" \
      help rotf_resor \
      message "(ROTF_RESOR)" \
      widget RF_RESOR -oblig \
      label "Angstrom resolution in first stage" \
      toggle_display ROTMODE open ROTF

    CreateLine line \
      message "Rotation Function parameters" \
      label "Generate" \
      message "(RROT_NROT)" \
      widget RROT_NROT \
      label "random orientations using" \
      message "(RROT_PERC)" \
      widget RF_PERC \
      label "% of reflections to" \
      help rrot_resor \
      message "(RROT_RESOR)" \
      widget RF_RESOR -oblig \
      label "Angstrom resolution in first stage" \
      toggle_display ROTMODE open RROT

    CreateLine line \
      message "Translation Function parameters (TRAN keyword)" \
      help tran_nsrot \
      label "Use" \
      widget TF_NSROT \
      label "solution(s) from the rotation function" \
      toggle_display TRAMODE open TRAN

    CreateLine line \
      message "Translation Function parameters" \
      label "Generate" \
      message "(RTRA_NTRAN)" \
      widget RTRA_NTRAN \
      label "sets of random shifts using" \
      message "(RTRA_PERC)" \
      widget TF_PERC \
      label "% of reflections for solution" \
      help rtra_nsrot \
      message "(RTRA_NSROT)" \
      widget TF_NSROT \
      label "from rotation function" \
      toggle_display TRAMODE open RTRA

  CloseSubFrame

#-----------------------------------------------------ACORN-PHASE parameters
  OpenFolder 5 ACORN_PROTOCOL open [list SOMEPHASE SOMECOORD KNOWNCOORD PREVMR ] closed

  CreateLineTemplate PARAMS [list 0.0 0.85]

#This should serve example 2
#Need keyword(s):
#         NTRY NCSER NCDDM

  CreateLine line \
    message "Turn this off to customise individual trials" \
    widget NTRYONLY \
    label "Set total number of trials to use, with default NCSER and NCDDM" 

  CreateLine line \
    message "Set number of trials for each set of initial phases (NTRY)" \
    label "Make" \
    widget NTRY1 \
    label "trial(s) for each set of initial phases" \
      toggle_display NTRYONLY open 1

  OpenSubFrame frame -toggle_display NTRYONLY hide 1

  CreateExtendingFrame NTRY AcornTrialRuns \
      "set values of NCSER and NCDDM (NTRY will be set automatically)" \
      "Add Another Trial Run" \
      [list NCSER NCDDM]

  CloseSubFrame

  CreateLine line \
    message "(SUPP)" \
    widget SUPP \
        -toggleon \
    label "Use the Patterson superposition function"

#This should serve example 4
#Need keyword(s):
#         MAXSET

  CreateLine line \
    message "(MAXSET)" \
    widget IFMAXSET \
        -toggleon \
    label "MAXSET - number of sets of initial phases" \
    widget MAXSET \
    format template PARAMS

  CreateLine line \
    message "(CUTDDM)" \
    widget IFCUTDDM \
        -toggleon \
    label "CUTDDM - higher limit for density in DDM" \
    widget CUTDDM \
    format template PARAMS

  CreateLine line \
    message "(PSFINISH)" \
    widget IFPSFINISH \
        -toggleon \
    label "PSFINISH - stop cycling DDM within phasing trial if phase shift becomes less than" \
    widget PSFINISH \
    format template PARAMS

  CreateLine line \
    message "(CCFINISH)" \
    widget IFCCFINISH \
        -toggleon \
    label "CCFINISH - stop refining phases if correlation coefficient for medium E-values is above" \
    widget CCFINISH \
    format template PARAMS

#--------------------------------------------------------------------Peaksearch

 OpenFolder 6 ACORN_PEAKSEARCH open 1 hide

   SetProgramHelpFile peakmax

   CreateLine line \
     message "Run Peakmax to find peaks in map & output to coordinate file" \
     label "Find maximum" \
     widget NUMPEAKS \
     label "peaks above" \
     widget THRESHHOLD \
     label "* RMS density"

}
