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
# patterson.tcl --
#
# Run fft to generate a Patterson map 
#
# CCP4Interface 
#
# =======================================================================

#----------------------------------------------------------------------
proc patterson_setup { typedefVar arrayname } {
#----------------------------------------------------------------------
  return 1
}

#----------------------------------------------------------------------
proc patterson_run { arrayname } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(OUTPUT_FILES) ""
  set array(INPUT_FILES) ""

  set mode [GetValue $arrayname PATTERSON_MODE]
  
  if { $array(RUN_FFT) } {
    lappend array(INPUT_FILES) HKLIN
    lappend array(OUTPUT_FILES) MAPOUT 
  } else {
    lappend array(INPUT_FILES) MAPOUT
  }

  if { $array(FFT_MAP_FORMAT) != "CCP4" } {
    lappend array(OUTPUT_FILES) "EXPORT_FILE" }

  if [regexp "PATTERSON\$" $mode ] {
    set array(LABIN) "F1 SIG1"
  } elseif [regexp PATTERSONI $mode ] {
    set array(LABIN) "I SIGI"
  } elseif [regexp DANO $mode ] {
     set array(F1) $array(DANO)
     set array(SIG1) $array(SIGDANO)
     if $array(DANO_EXCL) {
       set array(F2) $array(FPH1)
       set array(SIG2) $array(SIGFPH1)
       set array(LABIN) "F1 SIG1 F2 SIG2"
     } else {
       set array(LABIN) "F1 SIG1"
     }
  } else {
    set array(LABIN) "F1 SIG1 F2 SIG2"
  }

  if { $array(IFXYZLIM) } { 
    set array(IFXYZLIMASU) 0
  } else {
    set array(IFXYZLIMASU) 1
  }

  if { $array(IFPEAKSEARCH) } { 
    append array(OUTPUT_FILES) " PEAK_FILE" 
    set array(XYZ_FILE) $array(PEAK_FILE)
    set array(DIR_XYZ_FILE) $array(DIR_PEAK_FILE)
  }

  if { $array(RUN_NPO)  && \
     [regexp FILE [GetValue $arrayname COORDS_MODE]] } {
    append array(INPUT_FILES)  " XYZ_FILE"
  }

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

  if { [StringSame [GetValue $arrayname PATTERSON_MODE] PATTERSON PATTERSONI] } {
    # Set flag to indicate whether or not F2 label will be used for FFT
    set array(USE_F2) 0
  } else {
    set array(USE_F2) 1
  }

  return 1

}

#------------------------------------------------------------------------
proc vectors_read_pdb { arrayname } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  if {![SelectFile file -title "Select PDB File"  -filter "*.pdb" \
          -defdir [GetCurrentProject]] } { return }



  PleaseWait "Reading PDB file and redrawing window.."
  if { ![ReadFile [lindex $file 0] pdbfile -split] } { PleaseWait; return 0 }

  set n 0
  foreach line $pdbfile {
    if [regexp "^ATOM " $line] {
      incr n
      set array(VECTORS_ATOM_NAME,$n) [string trim [string range $line 12 15]]
      set array(VECTORS_ATOM_X,$n) [string trim [string range $line 30 37]]
      set array(VECTORS_ATOM_Y,$n) [string trim [string range $line 38 45]]
      set array(VECTORS_ATOM_Z,$n) [string trim [string range $line 46 53]]
    }
  }
  set array(VECTORS_NATOMS) $n
  puts "VECTORS_NATOMS $n"

  ReCreateTaskWindow CURRENT patterson $array(WINDOW) $arrayname
  PleaseWait
  return $n
}



#-----------------------------------------------------------------
proc PattersonMapmask { arrayname counter } {
#-----------------------------------------------------------------

  SetProgramHelpFile "npo"

  CreateLine line \
      message "Set output axis order for map (AXIS)" \
      help sectns \
      label "Plot sections on" \
      widget SECTION_AXIS  \
      label "axis from" \
      message "First section to plot" \
      widget F_SECTION  \
      label "to" \
      message "Last section to plot (large number => plot all sections)" \
      widget L_SECTION \
      label "in steps of" \
      message "Gap between plotted sections" \
      widget SKIP_SECTION \
          -width 3  \
      toggle_display  SECTION_FRAC  open 0

  CreateLine line \
      message "Set output axis order for map (AXIS)" \
      help sectns \
      label "Plot sections on" \
      widget SECTION_AXIS  \
      label "axis from" \
      message "First section to plot- fractional coordinates" \
      widget FRAC_F_SECTION  \
      label "to" \
      message "Last section to plot- fractional coordinates" \
      widget FRAC_L_SECTION \
      label "in steps of" \
      message "Gap between plotted sections" \
      widget FRAC_SKIP_SECTION \
          -width 3  \
      toggle_display  SECTION_FRAC  open 1

}

#-------------------------------------------------------------
proc PattersonExcludeBySigma { arrayname } {
#-------------------------------------------------------------
  upvar #0 $arrayname array

  switch [GetValue $arrayname  PATTERSON_MODE]  \
  PATTERSON {
    set array(EXCLUDE_BYSIGMA_1) 3.0
    set array(EXCLUDE_BYSIGMA_2) ""
    set array(SCALE_AMPL_2) ""
    set array(EXCLUDE_BYSIGMA) 1
    set array(EXCLUDE_BYDIFF) 1
  } DIFFERENCE {
    set array(EXCLUDE_BYSIGMA_1) 3.0
    set array(EXCLUDE_BYSIGMA_2) 3.0
    set array(SCALE_AMPL_2) ""
    set array(EXCLUDE_BYSIGMA) 1
    set array(EXCLUDE_BYDIFF) 1
  } ANOMALOUS {
    set array(EXCLUDE_BYSIGMA_1) 3.0
    set array(EXCLUDE_BYSIGMA_2) 3.0
    set array(SCALE_AMPL_2) ""
    set array(EXCLUDE_BYSIGMA) 1
    set array(EXCLUDE_BYDIFF) 1
  } DANO {
    set array(EXCLUDE_BYSIGMA_1) 0.0
    set array(EXCLUDE_BYSIGMA_2) 3.0
    set array(SCALE_AMPL_2) 0.000001
    set array(EXCLUDE_BYSIGMA) 1
    set array(EXCLUDE_BYDIFF) 1
  } PATTERSONI {
    set array(EXCLUDE_BYSIGMA) 0
    set array(EXCLUDE_BYDIFF) 0
  }

}

#--------------------------------------------------------------------
proc PattersonVectorAtoms { arrayname counter } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array
   SetProgramHelpFile vectors

   set array(VECTORS_ATOM_NAME,$counter) [lindex \
     [list 0 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z]  \
     [iremainder  $counter 26] ]

   CreateLine line \
     message "Enter atom name and coordinates" \
     help atom \
     label "Atom name" \
     widget VECTORS_ATOM_NAME \
     label "X" \
     widget VECTORS_ATOM_X \
     label "Y" \
     widget VECTORS_ATOM_Y \
     label "Z" \
     widget VECTORS_ATOM_Z
}

#=CREATE=WINDOW=AND=SUBWINDOWS===========================================

proc patterson_task_window { arrayname } {

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Patterson - Generate Patterson Map" "Patterson" \
        [ list "Define Map"  \
        "Exclude Reflections" \
	"Infrequently Used Patterson Options"  \
	"Crystal Parameters" \
	"Select Plot Sections" \
	"Peak Search Details" \
        "Inter-Atomic Vectors" \
	"Plot Details" ] ] == 0 } return

  SetDefaultMapFormat $arrayname FFT_MAP_FORMAT -noxtal

  SetProgramHelpFile "fft"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
     message "Select type of map to generate" \
     help fft \
     widget RUN_FFT \
     label "Run FFT to generate" \
     help labin \
     widget PATTERSON_MODE \
	-command "PattersonExcludeBySigma $arrayname" \
     label "map in" \
    message "Generate map in alternative format?" \
    widget FFT_MAP_FORMAT  \
    label "format"

  SetProgramHelpFile "peakmax"

  CreateLine line \
     message "Run peakmax to list peaks in map" \
     widget IFPEAKSEARCH \
     label "List peaks to file"

  SetProgramHelpFile "npo"

  CreateLine line \
    message "Generate postscript file of 2d plots (NPO)?" \
    help description \
    widget RUN_NPO \
    label "Plot" \
    widget PLOT_SECTIONS_MODE \
    label "map sections with " \
    message "Display coordinates on plot?" \
    widget COORDS_MODE 

#=FILES================================================================

  SetProgramHelpFile "fft"

  OpenFolder file 

  OpenSubFrame frame -toggle_display RUN_FFT open 1

  CreateInputFileLine line \
      "Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
       HKLIN DIR_HKLIN \
       -fileout MAPOUT DIR_MAPOUT _patterson  \
       -fileout PEAK_FILE DIR_PEAK_FILE _peaks  \
	-setfileparam resolution_min EXCLUDE_RESOLUTION_MIN \
        -setfileparam resolution_max EXCLUDE_RESOLUTION_MAX \
        -setfileparam space_group_name SPACE_GROUP 


  CreateLabinLine line \
    "Choose derivative (F1) and optional sigma (SIG1)" \
     HKLIN F1 F1  {Fm} \
     -sigma SigmaF1 SIG1  {} \
     -toggle_display PATTERSON_MODE open [list PATTERSON DIFFERENCE ]

  CreateLabinLine line \
    "Choose F+ (F1) and optional sigma (SIG1)" \
     HKLIN F1 F1  {Fp} \
     -sigma SigmaF1 SIG1  {} \
     -toggle_display PATTERSON_MODE open ANOMALOUS


    CreateLabinLine line \
    "Choose anomalous diff. (F1) and optional sigma (SIG1)" \
     HKLIN AnomDif DANO  {} \
     -sigma SigmaD SIGDANO  {} \
     -toggle_display PATTERSON_MODE open DANO


  CreateLabinLine line \
    "Choose native data (F2) and optional sigma (SIG2)" \
     HKLIN F2 F2  {FP} \
     -sigma SigmaF2 SIG2  {SIGFP} \
     -toggle_display PATTERSON_MODE open DIFFERENCE

  CreateLabinLine line \
    "Choose F- (F2) and optional sigma (SIG2)" \
     HKLIN F2 F2  {Fm} \
     -sigma SigmaF2 SIG2  {} \
     -toggle_display PATTERSON_MODE open ANOMALOUS

  CreateLabinLine line \
     "Choose I and optional sigma (SIGI)" \
      HKLIN I I {} \
      -sigma SigmaI SIGI {} \
      -toggle_display PATTERSON_MODE open PATTERSONI

  OpenSubFrame frame -toggle_display PATTERSON_MODE open DANO

  CreateLine line \
    widget DANO_EXCL \
    label "Use isomorphous data to exclude reflections with large sigma"

  CreateLabinLine line \
    "Choose FPH and optional sigma (SIGFPH)" \
     HKLIN FPH FPH1  {} \
     -sigma SigmaFPH SIGFPH1  {}

  CloseSubFrame


  CreateOutputFileLine line \
      "Enter map file name (MAPOUT)" \
      "Map" \
      MAPOUT DIR_MAPOUT

  CloseSubFrame

  CreateInputFileLine line \
      "Enter map file name (MAPOUT)" \
      "Map" \
       MAPOUT DIR_MAPOUT \
     -toggle_display RUN_FFT hide 1

  CreateOutputFileLine line \
      "Enter PDB file name (XYZOUT)" \
      "Peak coord" \
      PEAK_FILE DIR_PEAK_FILE \
     -toggle_display IFPEAKSEARCH open 1

  OpenSubFrame frame -toggle_display RUN_NPO open 1

  CreateInputFileLine line \
      "Enter PDB file name (XYZIN)" \
      "Plot coords" \
      XYZ_FILE DIR_XYZ_FILE \
     -toggle_display COORDS_MODE open [list FILE ]

  CloseSubFrame

  CreateOutputFileLine line \
      "Enter name for O/Quanta map file" \
      "Export map" \
      EXPORT_FILE DIR_EXPORT_FILE \
     -toggle_display FFT_MAP_FORMAT hide CCP4

#=PARAMETERS==========================================================


  SetProgramHelpFile "fft"

  OpenFolder 1 RUN_FFT  hide 0  open

  CreateLine line \
    message "Scale amplitudes (SCALE) for both datasets" \
    help "scale" \
    label "Scale amplitudes for set 1 " \
    widget SCALE_AMPL_1 \
    label  "and set 2 " \
    widget SCALE_AMPL_2 \
    toggle_display PATTERSON_MODE open [list DANO ANOMALOUS DIFFERENCE ]

  CreateLine line \
    message "Generate map with default extent or .. " \
    label "Extent " \
    help xyzlim \
    radiobutton IFXYZLIM 0  "asymmetric unit " \
    message " .. or enter map limits (xyzlim). See Help for restrictions" \
    radiobutton IFXYZLIM 1  "or range x" \
    widget XYZLIM_1 -width 6\
    widget XYZLIM_2 -width 6\
    label "y"       \
    widget XYZLIM_3 -width 6\
    widget XYZLIM_4 -width 6\
    label "z"       \
    widget XYZLIM_5 -width 6\
    widget XYZLIM_6 -width 6


#=EXCLUDE=REFLECTIONS======================================================

  OpenFolder 2 RUN_FFT  hide 0 open

  CreateLine line \
    help excl_diff \
    message "Exclude reflections with large differences between F1 and F2" \
    widget EXCLUDE_BYDIFF \
    label "Exclude reflections with difference between F1 and F2 > " \
    message "Leave blank for automatic calculation of optimum value" \
    widget EXCLUDE_BYDIFF_DIFF \
    toggle_display PATTERSON_MODE hide [list PATTERSON PATTERSONI ]

  ##############################################
  # EXCLUDE for F1 and F2
  ##############################################

  CreateLineTemplate "EXCLUDE" {0.0 0.6 0.8}

  OpenSubFrame frame -toggle_display PATTERSON_MODE hide { PATTERSON PATTERSONI }

  CreateLine line \
   label "Exclude reflections - parameters for " \
	-italic \
   label "set 1   and" \
	-italic \
   label "set 2" \
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

  # Options relevant for Patterson from structure factors

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

  CloseSubFrame

  ##############################################
  # EXCLUDE for F1 only
  ##############################################

  CreateLineTemplate "EXCLUDE1" {0.0 0.6}

  OpenSubFrame frame -toggle_display PATTERSON_MODE open { PATTERSON PATTERSONI }

  CreateLine line \
   label "Exclude reflections - parameters for " \
	-italic \
   label "set 1" \
	-italic \
   format template "EXCLUDE1"

  CreateLine line \
    message "Exclude reflections with Fs which are small compared to sigma F" \
    help excl_sig \
    widget EXCLUDE_BYSIGMA \
	-toggleon \
    label "F less than n * sigmaF where n is " \
    widget EXCLUDE_BYSIGMA_1 \
    format template "EXCLUDE1" \
    toggle_display PATTERSON_MODE hide [list PATTERSONI ]

  # Options relevant for Patterson from structure factors

  OpenSubFrame frame -toggle_display PATTERSON_MODE hide [list PATTERSONI]

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

  CloseSubFrame

  # Options relevant for Patterson from intensities

  OpenSubFrame frame -toggle_display PATTERSON_MODE open [list PATTERSONI]

  CreateLine line \
    message "Exclude reflections with small absolute intensity values" \
    help excl_min \
    widget EXCLUDE_MINIMUM \
	-toggleon \
    label "I absolute value less than " \
    widget EXCLUDE_MINIMUM_1 \
    format template "EXCLUDE1"

  CreateLine line \
    message "Exclude reflections with large absolute intensity values" \
    help excl_max \
    widget EXCLUDE_MAXIMUM \
	-toggleon \
    label "I absolute value greater than " \
    widget EXCLUDE_MAXIMUM_1 \
    format template "EXCLUDE1" 

  CloseSubFrame

  CloseSubFrame

  CreateLine line \
    message "Exclude reflections below and/or above resolution limit in \
                  Angstrom (RESOLUTION)" \
    help resolution \
    widget EXCLUDE_RESOLUTION \
	-toggleon \
    label "Resolution less than " \
    widget EXCLUDE_RESOLUTION_MIN \
    label "A or greater than " \
    widget EXCLUDE_RESOLUTION_MAX \
    label "A"


#=Unusual Options========================================================

  OpenFolder 3 RUN_FFT hide 0 closed

  CreateLine line \
    message "Space group (appropriate default derived from MTZ file) (FFTSPACEGROUP)" \
    help "fftspgp" \
    label "Generate map in space group" \
    widget FFT_SPACE_GROUP   \
    label "(the Patterson space group)"

  CreateLine line \
    message "Scale map to set max (and optionally min) density value (RHOLIM)" \
    help rholim \
    widget IFRHOLIM \
	-toggleon \
    label "Scale map to set density maximum" \
    widget RHOLIM_MAX \
    label "and minimum" \
    widget RHOLIM_MIN

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
    message "Apply scaling to B-factors" \
    help scale_bfac \
    widget BFACTOR_SCALING \
	-toggleon \
    label "Apply B-factor scaling to set 1" \
    widget  SCALE_BFACTOR_1 \
    label " and set 2" \
    widget SCALE_BFACTOR_2 \
      toggle_display PATTERSON_MODE open [list DIFFERENCE ANOMALOUS ]

  CreateLine line \
    message "Apply scaling to B-factors" \
    help scale_bfac \
    widget BFACTOR_SCALING \
	-toggleon \
    label "Apply B-factor scaling to set 1" \
    widget  SCALE_BFACTOR_1 \
      toggle_display PATTERSON_MODE hide [ list DIFFERENCE ANOMALOUS ]

#=========================================================crystal parameters

  OpenFolder 4 RUN_FFT hide 1 open

  CreateLine line \
    message "Enter space group symmetry of the atoms (not the Patterson) (SYMMETRY)" \
    help symmetry \
    label "Crystal (not Patterson) space group" \
    widget SPACE_GROUP -oblig

  
#---------------------------------------------------------NPO define sections

  OpenFolder 5 PLOT_SECTIONS_MODE hide HARKER open

  CreateLine line \
    message "Define sections in fractional or grid coordinates (SECTION)" \
    help section \
    label "Define sections in" \
    widget SECTION_FRAC

  CreateExtendingFrame N_SECTIONS PattersonMapmask \
    "Specify sections to plot" \
    "Add sections"  \
         [list  SECTION_AXIS \
		F_SECTION \
                L_SECTION \
                SKIP_SECTION ] 

#-----------------------------------------------------------Peaksearch
  OpenFolder 6 COORDS_MODE hide [list NO FILE VECTORS ] closed

  SetProgramHelpFile "peakmax"

  CreateLine line \
    label "Coordinates of peaks will be saved in coordinate file & plotted" \
	-italic

  CreateLine line \
    message "Fractional coordinates for input to Mlphare (OUTPUT FRAC)" \
    help output \
    widget IFFRACOUT \
    label "Also output peaks in fractional coordinates"

  CreateLine line \
    message "Set criteria for peaks search (THRESHOLD NEGATIVES)" \
    help threshold \
    label "Search for peaks greater than" \
    widget THRESHHOLD \
    label "sigma  " \
    widget NEGATIVES \
    label "Search for negative peaks"

  CreateLine line \
    message "Maximum number of peaks (NUMPEAKS)" \
    label "Number of peaks output to list  " \
    widget NUMPEAKS \
    message "Output Patterson vector lengths" \
    label "    " \
    widget PATTERSON_VECTORS \
    label "List Patterson vector lengths"

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

#-----------------------------------------------------------Vectors
  OpenFolder 7 COORDS_MODE hide [list NO FILE PEAKS] open

  SetProgramHelpFile "vectors"

  CreateLine line \
    label "Patterson space vectors between atoms will be calculated, saved to coordinate file & plotted" \
     -italic

    CreateLine line \
       message "Calculate vector for data from file or listed below" \
       label "Use atom coordinate data" \
       widget VECTOR_ATOM_MODE

  OpenSubFrame frame -toggle_display VECTOR_ATOM_MODE open FILE

  CreateInputFileLine line \
      "Enter input HA file name (format ATOM <id> <frac_x> <frac_y> <frac_z>)" \
      "HA in" \
       VECTOR_ATOM_FILE DIR_VECTOR_ATOM_FILE

  CloseSubFrame

  OpenSubFrame frame -toggle_display VECTOR_ATOM_MODE open LIST

  CreateExtendingFrame VECTORS_NATOMS PattersonVectorAtoms \
    "Find vectors for atoms" \
    "Add Atom"  \
              [list VECTORS_ATOM_NAME \
		VECTORS_ATOM_X \
		VECTORS_ATOM_Y \
		VECTORS_ATOM_Z ]
  CloseSubFrame


#=Run NPO================================================================

  OpenFolder 8 RUN_NPO hide 0 closed

  SetProgramHelpFile "npo"

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

  CreateLine line \
    label "Customise plot appearance:"

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

#=END=======================================================================
