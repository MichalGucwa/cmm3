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
# polarrfn.tcl --
#
# Do self rotation function in polar coordinates
#
# CCP4Interface 
#
# =======================================================================


#----------------------------------------------------------------------
proc polarrfn_setup { typedefVar arrayname } {
#----------------------------------------------------------------------

  return 1
}


#----------------------------------------------------------------------
proc polarrfn_run { arrayname } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(OUTPUT_FILES) ""
  if { $array(POLARRFN_MAP) } { append array(OUTPUT_FILES) " MAPOUT" }
  if { $array(POLARRFN_PLOT) } { append array(OUTPUT_FILES) " PLOTFILE" }

  if { $array(FIND_PEAK) != "" && $array(FIND_MAXPEAK) != "" } {
    set array(POLARRFN_FIND) 1
  } else {
    set array(POLARRFN_FIND) 0
  }

  if { $array(DEL_PHI) != "" && $array(DEL_OMEGA) != "" && $array(DEL_KAPPA) != ""} {
    set array(POLARRFN_LIMITS) 1
  } else {
    set array(POLARRFN_LIMITS) 0
  }

  return 1
}

#=CREATE=WINDOW=AND=SUBWINDOWS===========================================

proc polarrfn_task_window { arrayname } {

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Self rotation function in polars" "Self RF" \
        [ list "Principal parameters" "Plot parameters" \
               "Peak searching parameters" "Angle limits" ] ] == 0 } return

  SetProgramHelpFile "polarrfn"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateLine line \
    label "This interface to polarrfn is currently restricted to self-rotation function only" -italic

  CreateTitleLine line TITLE

  CreateLine line \
    widget POLARRFN_PLOT \
    message "plot rotation function as a stereographic projection of each kappa section." \
    label "write rotation function to plot file."

  CreateLine line \
    widget POLARRFN_MAP \
    message "The map file may be read back later for plotting, peak searching, etc." \
    label "write rotation function to map file."


#=FILES================================================================


  OpenFolder file 

  CreateInputFileLine line \
      "Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
       HKLIN DIR_HKLIN \
       -fileout MAPOUT DIR_MAPOUT _polarrfn \
       -fileout PLOTFILE DIR_PLOTFILE _polarrfn

  CreateLabinLine line \
    "Choose native SFs (F) and associated sigma (SIGF)" \
     HKLIN F F  {} \
     -sigma sigF SIGF  {}

 CreateOutputFileLine line \
      "Enter map file name (MAPOUT)" \
      "Map out" \
      MAPOUT DIR_MAPOUT \
	-toggle_display POLARRFN_MAP open 1

 CreateOutputFileLine line \
      "Enter map file name (PLOT)" \
      "Plot file out" \
      PLOTFILE DIR_PLOTFILE \
	-toggle_display POLARRFN_PLOT open 1

#=PARAMETERS==========================================================

  OpenFolder 1

  CreateLine line \
    message "Integration radius in Patterson space (SELF)" \
    help self \
    label "Integration radius (A): " \
    widget SELF_ARAD \
    message "Radius of sphere within which the Patterson is removed (SELF)" \
    label "Radius for averaging/smoothing (A): " \
    widget SELF_EPS

  CreateLine line \
    message "Resolution limits in Angstrom (RESOLUTION)" \
    help resolution \
    label "Use data over resolution range " \
    widget RESLOW \
    label "to" \
    widget RESHIGH

  CreateLine line \
    message "This can be used to sharpen the data (CRYSTAL)" \
    help crystal \
    label "Temperature factor: " \
    widget CRYSTAL_BFAC

  OpenFolder 2 POLARRFN_PLOT open 1 hide

  CreateLine line \
    message "Contour levels for plot file (PLOT)" \
    help plot \
    label "Contour start level: " \
    widget PLOT_CSTART \
    label "Contour interval: " \
    widget PLOT_CINT

  OpenFolder 3 closed

  CreateLine line \
    message "Peak searching parameters (FIND)" \
    help find \
    label "Threshold for peaks: " \
    widget FIND_PEAK \
    label "as multiple of RMS density" \
    widget FIND_RMS 

  CreateLine line \
    message "Peak searching parameters (FIND)" \
    help find \
    label "Maximum number of peaks to find: " \
    widget FIND_MAXPEAK

  OpenFolder 4 closed

  CreateLine line \
    message "Limits on the polar angles (LIMITS) - all 3 ranges must be specified" \
    help limits \
    label "Ranges & steps in phi: " \
    widget PHI_START \
    widget PHI_STOP \
    widget DEL_PHI

  CreateLine line \
    message "Limits on the polar angles (LIMITS) - all 3 ranges must be specified" \
    help limits \
    label "Ranges & steps in omega: " \
    widget OMEGA_START \
    widget OMEGA_STOP \
    widget DEL_OMEGA

  CreateLine line \
    message "Limits on the polar angles (LIMITS) - all 3 ranges must be specified" \
    help limits \
    label "Ranges & steps in kappa: " \
    widget KAPPA_START \
    widget KAPPA_STOP \
    widget DEL_KAPPA

}
