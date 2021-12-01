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
# sfanal.tcl --
#
# CCP4Interface 
#
# =======================================================================

# procedure which is run automatically before drawing the interface
# used to set up variables, menus etc
#---------------------------------------------------------------------
proc sfanal_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0  $typedefVar typedef
  upvar #0 $arrayname array

# Define the 'format type' menu

  DefineMenu _sftools_format_in [list "CCP4 (mtz)" \
                                      "mdf (old BIOMOL)" \
                                      "BIOMOL ascii format" \
                                      "X-PLOR" \
                                      "TNT" \
                                      "Phases formats" \
                                      "XtalView fin format" \
                                      "XtalView phs format" \
                                      "XtalView double fin" ] \
                                      [ list MTZ \
                                             MDF \
                                             SND \
                                             XPL \
                                             TNT \
                                             31 \
                                             FIN \
                                             PHS \
                                             DF]

  DefineMenu _sftools_format_out [list "CCP4 (mtz)" \
                                       "mdf (old BIOMOL)" \
                                       "BIOMOL ascii format" \
                                       "X-PLOR" \
                                       "TNT" \
                                       "Phases formats" \
                                       "XtalView fin format" \
                                       "XtalView phs format" \
                                       "XtalView double fin" ] \
                                       [ list MTZ \
                                              MDF \
                                              SND \
                                              XPL \
                                              TNT \
                                              31 \
                                              FIN \
                                              PHS \
                                              DF]

  DefineMenu _sftools_action [ list "data correlation" \
                                    "analysis of phase differences" \
                                    "plotting of data" \
                                    "data completeness analysis" ] \
                                    [ list CORREL \
                                           PHASHFT \
                                           PLOT  \
                                           COMPLETE ]

  DefineMenu _sftools_cosine [ list "phase difference in degrees" \
                                    "cosine of the phase difference" ] \
                                    [ list DEGREES COSINE ]

  DefineMenu _sftools_versus [ list "resolution" "the X-axis column" ] \
                                    [ list RESOL COL ]

  DefineMenu _sftools_mode   [ list "number of reflections per bin" \
                                    "cumulative completeness" ] \
                                    [ list NUMBERS CUMULATIVE ]

  DefineMenu _sftools_asunit [ list "CCP4" \
                                    "BIOMOL" \
                                    "TNT"  ] \
                                    [ list CCP4 \
                                           BIOMOL \
                                           TNT ]

# procedure must return success code (1) for drawing task window to continue
  return 1
}

# procedure to draw task window
#---------------------------------------------------------------------
proc sfanal_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
        "Analyse Structure Factor Files" "Sftools" \
        [ list "Data Correlation" \
               "Phase Differences" \
               "Plotting" \
               "Completeness" \
               "Settings" ] ] == 0 } return

  SetProgramHelpFile "sftools"

  set array(INITIALISED) 0

#=PROTOCOL==============================================================

  OpenFolder protocol  

  CreateTitleLine line TITLE

  CreateLine line \
    message "Select operation to perform on reflection data" \
    help examples \
    label "Perform" \
    widget SF_ACTION

#=FILES================================================================ 

  OpenFolder file

  CreateInputFileLine line \
        "Enter name of input reflection file" \
        "Input file" \
        HKLIN DIR_HKLIN \
        -setfileparam RESOLUTION_MIN MIN_RESOL \
        -setfileparam RESOLUTION_MAX MAX_RESOL

#==========================================================Correlation

  OpenFolder 1 SF_ACTION open CORREL hide

  CreateLine line \
    label "Plot the correlation and R-factor between two columns of data"

  CreateLabinLine line \
    "Choose first column" \
     HKLIN "Column1    " F1  {} \
     -help "CORREL"

  CreateLabinLine line \
    "Choose second column" \
     HKLIN "Column2    " F2  {} \
     -help "CORREL"

#==========================================================Phase Shift

  OpenFolder 2 SF_ACTION open PHASHFT hide

  CreateLine line \
    label "Plot average phase difference between two sets of phases"

  CreateLabinLine line \
    "Choose first column of phases" \
     HKLIN "Set 1    " PHI1  {} \
     -help "PHASHFT"

  CreateLabinLine line \
    "Choose second column of phases" \
     HKLIN "Set 2    " PHI2  {} \
     -help "PHASHFT"

  CreateLine line \
     help "PHASHFT" \
     message "Plot phase difference (in degrees) or its cosine" \
     label "Plot the" \
     widget SF_COSINE

#==========================================================Plotting

  OpenFolder 3 SF_ACTION open PLOT hide

  CreateLine line \
    help "PLOT" \
    message "Plot bin-wise averages of data in one column again resolution, or against another column" \
    label "Plot bin-wise averages of data in the Y-axis column against" \
    widget SF_VERSUS

  CreateLabinLine line \
    "Choose column to plot on the x-axis" \
     HKLIN "X-axis   " F2  {} \
     -toggle_display SF_VERSUS hide RESOL \
     -help "PLOT"

  CreateLabinLine line \
    "Choose column to plot on the y-axis" \
     HKLIN "Y-axis   " F1  {} \
     -help "PLOT"

#==========================================================Completeness

  OpenFolder 4 SF_ACTION open COMPLETE hide

  CreateLine line \
    help "COMPLETE" \
    message "Plot number of reflections or cumulative completeness, per resolution bin" \
    label "Analyse the" \
    widget SF_MODE

  CreateLabinLine line \
    "Choose which column to use for completeness analysis" \
     HKLIN "in column     " F1  {} \
     -help "COMPLETE"

  CreateLine line \
        message "Select asymmetric unit definition" \
        help "COMPLETE" \
        label "Only reflections in the" \
        widget SF_ASUNIT \
        label "asymmetric unit will be used."


#==========================================================Settings

  OpenFolder 5 open

  CreateLine line \
     message "Select number of bins to split the x-axis into" \
     label "Put the data into" \
     widget NSHELLS \
     label "bins for output"

  CreateLine line \
     message "Apply resolution limits" \
     widget SF_RESOL \
     message "Minimum resolution" \
     label "Resolution range from minimum" \
     widget MIN_RESOL \
     label "to" \
     message "Maximum resolution" \
     widget MAX_RESOL \
     toggle_display SF_ACTION hide [ list PLOT COMPLETE ]

  CreateLine line \
     message "Apply resolution limits" \
     widget SF_RESOL \
     label "Maximum resolution" \
     message "Maximum resolution" \
     widget MAX_RESOL \
     toggle_display SF_ACTION open COMPLETE
}

#--------------------------------------------------------------
proc sfanal_run { arrayname } {
#--------------------------------------------------------------
  return [StartLoggraph]
}


#------------------------------------------------------------------
proc sfanal_review { arrayname job_id } {
#------------------------------------------------------------------
  upvar #0 $arrayname array
# This procedure called after sftools has completed successfully
# Will try to update loggraph - there may be a problem if sftools
# has been faster than loggraph which should have send message to
# LGServerReceive

# To give loggraph a chance to get started use UpdateLoggraph to
# call itself recursively until 

  UpdateLoggraph [GetLogFileName $job_id] 0 1000 5001

  return 1
}

