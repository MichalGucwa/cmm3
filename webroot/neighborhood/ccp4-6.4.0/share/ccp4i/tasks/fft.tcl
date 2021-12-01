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
# fft.tcl --
#
# Run fft to generate a map (does not cover Pattersons)
#
# CCP4Interface 
#
# ======================================================================


#-----------------------------------------------------------------------
proc fft_setup { typedefVar arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $typedefVar typedef

  DefineMenu _fft_whichhand [list "original hand" "opposite hand"] \
      [list "" "HAND 2"]

  return 1
}

#-----------------------------------------------------------------------
proc fft_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [regexp MAP [GetValue $arrayname FFTPROGRAM ]] &&
       [ regexp INPUT [GetValue $arrayname MAP_LIMITS_MODE]] &&
       [regexp CCP4 [GetValue $arrayname FFT_MAP_FORMAT ]] &&
       !$array(IFPEAKSEARCH) && !$array(RUN_NPO) } {
     WarningMessage "This setup will not do anything!!"
     return 0
  }

  if [StringSame $array(LABIN) anomalous] {
    set array(SIG1) $array(SIGDANO)
  } else {
    set array(SIG1) $array(SIGF1)
  }

  if { [StringSame $array(LABIN) simple anomalous] } {
    # Set flag to indicate whether or not F2 label will be used for FFT
    set array(USE_F2) 0
  } else {
    set array(USE_F2) 1
  }
  
  if [regexp MAP [GetValue $arrayname FFTPROGRAM ]] {
    set array(INPUT_FILES) MAPIN
  } else {
    set array(INPUT_FILES) HKLIN
  }

  if [StringSame [GetValue $arrayname MAP_LIMITS_MODE] PDB ] {
    append array(INPUT_FILES) " " EXTEND_XYZIN }

  if { $array(IFMAPOUT) } { 
    switch [GetValue $arrayname FFT_MAP_FORMAT ] \
    CCP4 {
      set array(OUTPUT_FILES) MAPOUT
    } O {
      set array(OUTPUT_FILES) O_MAPOUT
    } QUANTA {
      set array(OUTPUT_FILES) Q_MAPOUT
    }
  } else {
    set array(OUTPUT_FILES) ""
  }

  if { $array(RUN_NPO) && \
    [regexp FILE [GetValue $arrayname COORDS_MODE]] } { 
    append array(INPUT_FILES)  " XYZ_FILE"
  } 
  if { $array(IFPEAKSEARCH) } { append array(OUTPUT_FILES) " XYZPEAKS" }

  if { $array(EXCLUDE_BYSIGMA) } {
    if { ![regexp "PATTERSONI" $array(PATTERSON_MODE)] } {
      if { [string trim $array(EXCLUDE_BYSIGMA_1)] == "" &&
           [string trim $array(EXCLUDE_BYSIGMA_2)] == "" } {
        WarningMessage "No sigma levels have been given for
excluding F less than n* sigmaF.

Please correct and rerun."
        return 0
      }
    }
  }

  return 1
}

#-----------------------------------------------------------------------
proc fft_extent { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  set mode [GetValue $arrayname MAP_LIMITS_MODE]

  if { [ GetValue $arrayname FFTPROGRAM ] == "MAP"  } {
    UpdateVariableMenu $arrayname initialise 0 MAP_LIMITS_MENU \
                        [list "as input map" \
                              "all atoms in PDB file" \
                              "extent defined by user" ] \
        MAP_LIMITS_ALIAS  [list INPUT PDB USER ]
    if { $mode == "INPUT" } { set array(MAP_LIMITS_MODE) "as input map" }
  } else {
    UpdateVariableMenu $arrayname initialise 0 MAP_LIMITS_MENU \
                        [list "asymmetric unit" \
                              "all atoms in PDB file" \
                              "extent defined by user" ] \
        MAP_LIMITS_ALIAS  [list INPUT PDB USER ]
    if { $mode == "INPUT" } { set array(MAP_LIMITS_MODE)  "asymmetric unit" }
  }
}

#----------------------------------------------------------------
proc PattersonMapmask { arrayname counter } {
#-----------------------------------------------------------------

  SetProgramHelpFile "npo"

  CreateLine line \
      message "Set output axis order for map (AXIS)" \
      help sectns \
      label "Plot sections on" \
      widget SECTION_AXIS  \
      label "axis from" \
      widget F_SECTION  \
      label "to" \
      widget L_SECTION \
      label "in steps of" \
      widget SKIP_SECTION \
          -width 3
}

#--------------------------------------------------------------
proc fft_ifpeaksearch { arrayname } {
#--------------------------------------------------------------
  upvar #0 $arrayname array
  set array(IFPEAKSEARCK) \
    [regexp PEAK [GetValue $arrayname COORDS_MODE] ]
}

#--------------------------------------------------------------
proc fft_if_mapout { arrayname  } {
#--------------------------------------------------------------
  upvar #0 $arrayname array

  if { ![regexp MAP [GetValue $arrayname FFTPROGRAM]] ||
	![regexp CCP4 [GetValue $arrayname FFT_MAP_FORMAT] ] ||
	  ![regexp INPUT [GetValue $arrayname MAP_LIMITS_MODE ] ] } {
    set array(IFMAPOUT) 1
  } else {
    set array(IFMAPOUT) 0
  }
}


#-----------------------------------------------------------------------
proc fft_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Run FFT - Create Map" "FFT" \
        [ list "Define Map"  \
	"Map Limits" \
	"Extending Map" \
        "Exclude Reflections" \
	"Select Plot Sections" \
        "Peak Search Details" \
        "Plot Details"  \
	"Infrequently Used Options" ] ] == 0 } return

  SetDefaultMapFormat $arrayname FFT_MAP_FORMAT -noxtal


  SetProgramHelpFile "fft"
   fft_extent $arrayname
   fft_if_mapout $arrayname

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
    message "Use the FFT or input existing map?" \
    help description \
    widget FFTPROGRAM  \
	-command "fft_extent $arrayname; fft_if_mapout $arrayname" \
    message "Select type of map to generate" \
    help labin \
    label "to generate" \
    widget LABIN \
    label "map"

  CreateLine line \
    message "Generate map in alternative format?" \
    label "Output map in" \
    widget FFT_MAP_FORMAT  \
	-command "fft_if_mapout $arrayname" \
    label "format" \
    label "to cover" \
    message "Choose criteria to define the extent of the map" \
    help xyzlim \
    widget MAP_LIMITS_MODE \
	-command "fft_if_mapout $arrayname"

  SetProgramHelpFile "npo"


  CreateLine line \
    message "" \
    label "Select hand for phased translation:" \
    widget WHICH_HAND \
    toggle_display LABIN open [list "phased translation"]

  CreateLine line \
    message "List peaks to PDB file" \
    widget IFPEAKSEARCH \
    label "Do peak search of map"


  CreateLine line \
    message "Generate postscript file of 2d plots (NPO)?" \
    help description \
    widget RUN_NPO \
    label "Plot" \
    label "map sections with " \
    message "Display coordinates on plot?" \
    widget COORDS_MODE -command "fft_ifpeaksearch $arrayname"


#=FILES================================================================

  OpenFolder file 

  SetProgramHelpFile "fft"

  
  OpenSubFrame frame -toggle_display FFTPROGRAM hide MAP

  CreateInputFileLine line \
      "Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
       HKLIN DIR_HKLIN \
       -fileout MAPOUT DIR_MAPOUT --  \
       -fileout O_MAPOUT DIR_O_MAPOUT --  \
       -fileout Q_MAPOUT DIR_Q_MAPOUT --  \
       -setlabin EXCLUDE_FREER_LABEL [list FREE FreeR FreeR_flag] \
       -setfileparam space_group_name SPACE_GROUP \
	-setfileparam resolution_min EXCLUDE_RESOLUTION_MIN \
        -setfileparam resolution_max EXCLUDE_RESOLUTION_MAX

  CreateLabinLine line \
    "Choose amplitude (F1) and optional sigma (SIG1)" \
     HKLIN "F1    " F1  {} \
     -sigma "Sigma  " SIGF1  {} \
     -toggle_display LABIN hide anomalous

  CreateLabinLine line \
    "Choose phase (PHI) and optional weighting factor (W)" \
     HKLIN "PHI   " PHI  {} \
     -sigma "Weight " W  {}

  CreateLabinLine line \
    "Choose anomalous amplitude (DANO) " \
     HKLIN "DANO  " DANO {}  \
     -sigma "Sigma  " SIGDANO  {} \
     -toggle_display LABIN hide  \
       [list simple nF1-mF2  {vector difference} {double difference} {phased translation}]

  CreateLabinLine line \
    "Choose second amplitude (F2) and optional weighting factor (SIG2)" \
     HKLIN "F2    " F2  {} \
     -sigma "Sigma  " SIG2  {} \
     -toggle_display LABIN hide {simple anomalous}

  CreateLabinLine line \
    "Choose second phase (PHI2) and optional weighting factor (W2)" \
     HKLIN "PHI2  " PHI2  {} \
     -sigma "Weight " W2  {} \
     -toggle_display LABIN hide \
	[list simple nF1-mF2 anomalous "double difference" ]

  CreateLabinLine line \
    "Choose heavy atom amplitude (FH)" \
     HKLIN FH FH  FH \
     -toggle_display LABIN open { "double difference" }

    CreateLabinLine line \
    "Choose heavy atom phase (PHIH)" \
     HKLIN PHIH PHIH  PHIH \
     -toggle_display LABIN open { "double difference" }

  CloseSubFrame

  SetProgramHelpFile "mapmask"

  CreateInputFileLine line \
      "Enter name of input map(MAPMASK XYZIN)" \
      "Map in" \
      MAPIN DIR_MAPIN \
       -fileout O_MAPOUT DIR_O_MAPOUT --  \
       -fileout Q_MAPOUT DIR_Q_MAPOUT --  \
      -toggle_display FFTPROGRAM open MAP

  CreateInputFileLine line \
      "Enter name of file containing molecule for map to cover (EXTEND XYZIN)" \
      "PDB file" \
      EXTEND_XYZIN DIR_EXTEND_XYZIN  \
      -toggle_display MAP_LIMITS_MODE open PDB



  SetProgramHelpFile "fft"

  OpenSubFrame frame -toggle_display IFMAPOUT open 1 

  CreateOutputFileLine line \
      "Enter map file name or click file browser icon (MAPOUT)" \
      "Map out" \
      MAPOUT DIR_MAPOUT \
	-toggle_display FFT_MAP_FORMAT open CCP4

  CreateOutputFileLine line \
      "Enter name for Quanta map file" \
      "Quanta map" \
      Q_MAPOUT DIR_Q_MAPOUT \
      -toggle_display FFT_MAP_FORMAT open QUANTA

  CreateOutputFileLine line \
      "Enter name for O map file" \
      "O map" \
      O_MAPOUT DIR_O_MAPOUT \
      -toggle_display FFT_MAP_FORMAT open O

  CloseSubFrame


    CreateOutputFileLine line \
      "Enter PDB file name (XYZOUT)" \
      "Peak coords" \
      XYZPEAKS DIR_XYZPEAKS \
     -toggle_display IFPEAKSEARCH open 1


  OpenSubFrame frame -toggle_display RUN_NPO open 1

  CreateInputFileLine line \
      "Enter PDB file name (XYZIN)" \
      "Plot coords" \
      XYZ_FILE DIR_XYZ_FILE \
     -toggle_display COORDS_MODE open [list FILE ]

  CloseSubFrame


#=PARAMETERS==========================================================

  OpenFolder 1 FFTPROGRAM open [list fft] hide


  CreateLine line \
    message "Scale amplitudes (SCALE) for both datasets" \
    help "scale" \
    label "For nF1-mF2 map set n=" \
    widget SCALE_AMPL_1 \
    label  "and m=" \
    widget SCALE_AMPL_2 \
    toggle_display  LABIN open [list nF1-mF2 "vector difference" ] 


  CreateLine line \
    message "Exclude reflections in set selected for FreeR \
                             calculation (FREERFLAG&FREE)" \
    help freerflag \
    widget EXCLUDE_FREER \
    label "Exclude set of FreeR reflections defined by MTZ label" \
    widget EXCLUDE_FREER_LABEL 

#===============================================================Map limits

  OpenFolder 2 MAP_LIMITS_MODE open USER hide

  SetProgramHelpFile mapmask

  CreateLine line \
    message "Map limits set by user (XYZLIM)" \
    help xyzlim \
    label "Map extent x" \
    widget XYZLIM_1  \
    widget XYZLIM_2  \
    label "y"       \
    widget XYZLIM_3  \
    widget XYZLIM_4  \
    label "z"       \
    widget XYZLIM_5  \
    widget XYZLIM_6


  OpenFolder 3 MAP_LIMITS_MODE open PDB hide

  CreateLine line \
    message "Border in Angstrom around atoms in coordinate file (MAPMASK BORDER)" \
    label "Border in Angstrom around atoms" \
    widget BORDER

  SetProgramHelpFile fft

#=EXCLUDE=REFLECTIONS======================================================

  OpenFolder 4 FFTPROGRAM hide MAP closed

  CreateLine line \
    message "Exclude reflections below and/or above resolution limit in \
                  Angstrom (RESOLUTION)" \
    help resolution \
    widget EXCLUDE_RESOLUTION \
	-toggleon \
    label "Resolution less than" \
    widget EXCLUDE_RESOLUTION_MIN \
    label "A or greater than" \
    widget EXCLUDE_RESOLUTION_MAX \
    label "A"

  ##############################################
  # EXCLUDE for F1 and F2
  ##############################################

  CreateLineTemplate "EXCLUDE" [list 0.0 0.6 0.8]

  OpenSubFrame frame -toggle_display LABIN hide { simple anomalous }

  CreateLine line \
   label "Exclude reflections: parameters for " \
	-italic \
   label "F1   and" \
	-italic \
   label "F2" \
	-italic \
   format template "EXCLUDE"
   
  CreateLine line \
   message "Exclude reflections with Fs which are small compared to sigma F" \
    help excl_sig \
    widget EXCLUDE_BYSIGMA \
	-toggleon \
    label "F less than n * sigmaF where n is " \
    widget EXCLUDE_BYSIGMA_1 \
    widget EXCLUDE_BYSIGMA_2 \
    format template "EXCLUDE"

  CreateLine line \
    message "Exclude reflections with small absolute values" \
    help excl_min \
    widget EXCLUDE_MINIMUM \
	-toggleon \
    label "F absolute value less than " \
    widget EXCLUDE_MINIMUM_1 \
    widget EXCLUDE_MINIMUM_2 \
    format template "EXCLUDE"

  CreateLine line \
    message "Exclude reflections with large absolute values" \
    help excl_max \
    widget EXCLUDE_MAXIMUM \
	-toggleon \
    label "F absolute value greater than " \
    widget EXCLUDE_MAXIMUM_1 \
    widget EXCLUDE_MAXIMUM_2 \
    format template "EXCLUDE"


  CreateLine line \
   message "Exclude reflections with large differences between F1 and F2" \
    help excl_diff \
    widget EXCLUDE_BYDIFF \
	-toggleon \
    label "Difference between F1 and F2 greater than" \
    widget EXCLUDE_BYDIFF_DIFF \
    format template "EXCLUDE"

  CloseSubFrame

  ##############################################
  # EXCLUDE for F1 only
  ##############################################

  CreateLineTemplate "EXCLUDE1" [list 0.0 0.6]

  OpenSubFrame frame -toggle_display LABIN open { simple anomalous }

  CreateLine line \
   label "Exclude reflections: parameters for " \
	-italic \
   label "F1" \
	-italic \
   format template "EXCLUDE1"
   
  CreateLine line \
   message "Exclude reflections with Fs which are small compared to sigma F" \
    help excl_sig \
    widget EXCLUDE_BYSIGMA \
	-toggleon \
    label "F less than n * sigmaF where n is " \
    widget EXCLUDE_BYSIGMA_1 \
    format template "EXCLUDE1"

  CreateLine line \
    message "Exclude reflections with small absolute values" \
    help excl_min \
    widget EXCLUDE_MINIMUM \
	-toggleon \
    label "F absolute value less than " \
    widget EXCLUDE_MINIMUM_1 \
    format template "EXCLUDE1"

  CreateLine line \
    message "Exclude reflections with large absolute values" \
    help excl_max \
    widget EXCLUDE_MAXIMUM \
	-toggleon \
    label "F absolute value greater than " \
    widget EXCLUDE_MAXIMUM_1 \
    format template "EXCLUDE1"


  #CreateLine line \
  # message "Exclude reflections with large differences between F1 and F2" \
   # help excl_diff \
    #widget EXCLUDE_BYDIFF \
	#-toggleon \
    #label "Difference between F1 and F2 greater than" \
    #widget EXCLUDE_BYDIFF_DIFF \
    #format template "EXCLUDE"

  CloseSubFrame
   

#=Unusual Options========================================================

  OpenFolder 8 FFTPROGRAM hide MAP closed

  CreateLine line \
    message "Space group (default as in MTZ file) (FFTSPACEGROUP)" \
    label "Generate map in space group" \
    help fftspacegroup \
    widget FFT_SPACE_GROUP

  CreateLine line \
    message "Exclude reflections in set selected for FreeR \
                             calculation (FREE)" \
    label "Exclude reflections in FreeR set with value" \
    widget EXCLUDE_FREER_VALUE

  CreateLine line \
    message "Scale map amplitudes, enter cell volume and F000" \
    help vf000 \
    widget SCALE_MAP \
	-toggleon \
    label "Scale map using cell volume" \
    widget SCALE_VOLUME \
    label "and F000" \
    widget SCALE_F000

  CreateLine line \
    message "Apply scaling to B-factors" \
    help scale_bfac \
    widget BFACTOR_SCALING \
        -toggleon \
    label "Apply B-factor scaling to F1" \
    widget  SCALE_BFACTOR_1 \
      toggle_display LABIN open { simple anomalous }

  CreateLine line \
    message "Apply scaling to B-factors" \
    help scale_bfac \
    widget BFACTOR_SCALING \
        -toggleon \
    label "Apply B-factor scaling to F1" \
    widget  SCALE_BFACTOR_1 \
    label " and F2" \
    widget SCALE_BFACTOR_2 \
      toggle_display LABIN hide { simple anomalous }

  CreateLine line \
    message "Override default grid spacing" \
    help grid \
    widget GRID \
	-toggleon \
    label "Grid spacing x= " \
    widget GRID_1 \
    label " y= " \
    widget GRID_2 \
    label " z= " \
    widget GRID_3

  CreateLine line \
    message "Change axis order in output file (AXIS)" \
    help axis \
    widget IFAXIS \
    label "Change axis order to" \
    widget AXIS


#-----------------------------------------------------------plot sections

  OpenFolder 5  RUN_NPO open 1 hide

  SetProgramHelpFile  npo

  CreateLine line \
    message "Define sections in fractional or grid coordinates (SECTION)" \
    help section \
    widget SECTION_FRAC \
    label "Define sections in fractional coordinates"


  CreateExtendingFrame N_SECTIONS PattersonMapmask \
    "Specify sections to plot" \
    "Add sections"  \
         [list  SECTION_AXIS \
                F_SECTION \
                L_SECTION \
                SKIP_SECTION ]

  CreateLine line \
    message "Contour levels for map plot (CONTRS)" \
    help group2_contrs \
    label "Map contour levels entered as a" \
    widget CONTOUR_MODE \
    label "of" \
    widget CONTOUR_PARAM

  CreateLine line \
    message "Enter list of contouring levels (max of 6) (CONTRS)" \
    help group2_contrs \
    label "Contour levels" \
    widget CONTOUR_LIST_1 \
    widget CONTOUR_LIST_2 \
    widget CONTOUR_LIST_3 \
    widget CONTOUR_LIST_4 \
    widget CONTOUR_LIST_5 \
    widget CONTOUR_LIST_6 \
    label "and" \
    widget PLOT_NEG \
    label "negative values" \
    toggle_display CONTOUR_MODE hide range

  CreateLine line \
    message "Enter range of contour levels (CONTRS)" \
    help group2_contrs \
    label "Contour levels from" \
    widget CONTOUR_RANGE_1 \
    label "to" \
    widget CONTOUR_RANGE_2 \
    label "by intervals of" \
    widget CONTOUR_RANGE_STEP \
    label "and" \
    widget PLOT_NEG \
    label "negative values" \
    toggle_display CONTOUR_MODE hide list



#-----------------------------------------------------------Peaksearch
  OpenFolder 6 IFPEAKSEARCH open 1 hide

  SetProgramHelpFile "peakmax"

  CreateLine line \
    label "Coordinates of peaks will be saved in coordinate file & plotted" \
        -italic

  CreateLine line \
    message "Create fractional coordinate file (OUTPUT FRAC)" \
    help output \
    widget IFFRACOUT \
    label "Also output peaks in fractional coordinates"


  CreateLine line \
    message "Set criteria for peaks search (THRESHOLD NEGATIVES)" \
    help threshhold \
    label "Search for peaks greater than" \
    widget THRESHHOLD \
    label "sigma  " \
    widget NEGATIVES \
    label "Search for negative peaks"

  CreateLine line \
    message "Maximum number of peaks (NUMPEAKS)" \
    label "Number of peaks output to list  " \
    widget NUMPEAKS

  CreateLine line \
    message "Define format of ATOM card in output PDB file" \
    label "PDB ATOM card with chain" \
    widget CHAIN \
        -width 4 \
    label "residue" \
    widget RESIDUE \
        -width 6 \
    label "atom" \
    widget ATNAME  \
        -width 6 \
    label "Bfactor" \
    widget BFACTOR \
        -width 6 \
    label "occupancy" \
    widget OCCUPANCY \
        -width 6

#run NPO================================================================

  OpenFolder 7 RUN_NPO hide 0 closed

  SetProgramHelpFile "npo"

  CreateLine line \
    message "Set a maximum plot size for scale to calculated automatically" \
    help group2_map_scale \
    label "Set maximum plot size" \
    widget NPO_MAX_SIZE \
    label "cms  Or define plot scale" \
    message "Set scale of plot (MAP SCALE)" \
    widget NPO_SCALE \
    label "mm/A Character size"  \
    widget NPO_CHAR_SIZE


  CreateLine line \
    message "Enter colour for plotting heavy atoms (RESIDU)" \
    help group4_colour \
    label "Colour atoms/vectors" \
    widget NPO_ATOM_COLOUR \
    label "   " \
    help group3_label \
    widget NPO_LABELS \
    label "atoms"

  CreateLine line \
    message "Define grid spacing and offset (GRID)" \
    help group2_grid \
    widget GRID_PLOT_MODE \
    label "Plot grid with spacing (" \
    widget GRID_PLOT_UNITS \
    label ") in u" \
    widget NPO_GRID_1 \
        -width 5 \
    label "and v" \
    widget NPO_GRID_2 \
        -width 5 \
    label "& offset in u" \
    widget NPO_GRID_3 \
        -width 5 \
    label "and v" \
    widget NPO_GRID_4 \
        -width 5


}

