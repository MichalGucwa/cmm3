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
# check.tcl --
#
# Run sfcheck to compare structure and SF data
# or procheck to check structure geometry
#
# CCP4Interface 
#
# ======================================================================
#-----------------------------------------------------------------------
proc check_setup { typedefVar arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname array
  global loggraph

  set typedef(_check_data) { menu { "native SF" \
					"anomalous SF" \
					"native intensity" \
					"anomalous intensity" } 
			{ SF SF_ANOM I I_ANOM } }

  set typedef(_check_sfcheck_mode) { menu { "structure against experimental data" \
                                            "experimental data only" \
				            "structure only" } 
                        { BOTH EXPERIMENT STRUCTURE } }

  return 1
}


#-----------------------------------------------------------------------
proc check_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

 # Check for Rampage program. If it is not found, we switch off the option.
 # If it was the only option, script will fail with next check.
 if { $array(RUN_RAMPAGE) == 1 } {
   if { [FindExecutable "rapper"] == "" } {
      WarningMessage "Input Error: Rapper_Rampage program not found in system path."
      set array(RUN_RAMPAGE) 0
    }
  }

  # Make sure there is actually something to do
  if { ! $array(RUN_PROCHECK) && ! $array(RUN_SFCHECK) && ! $array(RUN_RAMPAGE) } {
    WarningMessage "No programs selected to run and
analyse data!

Please select at least one of either Procheck
or Sfcheck to be run."
    return 0
  }

  # Check resolution set for procheck
  if { $array(RUN_PROCHECK) && $array(RESOLUTION) == "" } {
     WarningMessage "Procheck requires the maximum resolution to be specified."
     return 0
  }

  # Set up input and output files
  set array(INPUT_FILES) ""
  if $array(USE_XYZIN) { append array(INPUT_FILES) "XYZIN " }

  # Check if HKLIN has actually been used for Procheck
  # Max res has already been extracted, so this is just for posterity
  if { $array(RUN_PROCHECK) } {
    if { ! $array(RUN_SFCHECK) || $array(SFCHECK_MODE) == "STRUCTURE" } {
      if { $array(HKLIN) != "" } { append array(INPUT_FILES) "HKLIN" }
    }
  } elseif { $array(RUN_SFCHECK) && $array(SFCHECK_MODE) != "STRUCTURE" } {
    if $array(USE_HKLIN) { append array(INPUT_FILES) "HKLIN" }
  }

  set array(OUTPUT_FILES) ""
  if $array(RUN_SFCHECK) { 
    append array(OUTPUT_FILES) " ANALYSIS_FILE"
    # Details of output for anisothermally corrected SFs
    if { $array(USE_ANISOTHERMAL_CORR) && $array(SFCHECK_ANISOTHERMAL_CORR) } {
	append array(OUTPUT_FILES) " HKLOUT"
    }
  }
  if $array(RUN_RAMPAGE) { append array(OUTPUT_FILES) " PSOUT" }

  # Procheck colours
  if $array(PROCHECK_COLOUR) {
    set array(PRINT_CMD) [GetValue $arrayname COLOUR_PRINTER]
  } else {
    set array(PRINT_CMD) [GetValue $arrayname MONO_PRINTER]
  }

  return 1
}

#-----------------------------------------------------------------------
proc check_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Check - Run Sfcheck and Procheck" "Check" \
	[list "Procheck Parameters"]  ] == 0 } return

  set array(COLOUR_PRINTER) [lindex [GetTypeInfo $arrayname COLOUR_PRINTER deflist] 0 ]
  set array(MONO_PRINTER) [lindex [GetTypeInfo $arrayname MONO_PRINTER deflist] 0  ]

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
    message "Run Rampage to get Ramachandran plots" \
    widget RUN_RAMPAGE \
      -command "check_update_files $arrayname" \
    label "Run Rampage to analyse structure geometry"

  CreateLine line \
    message "Run Procheck to get geometry check (but use Rampage for Ramachandran plots)" \
    widget RUN_PROCHECK \
      -command "check_update_files $arrayname" \
    label "Run Procheck to analyse structure geometry"

    CreateLine line \
    message "Run Sfcheck to get information on data, structure and agreement between them" \
    widget RUN_SFCHECK \
      -command "check_update_files $arrayname" \
    label "Run Sfcheck to analyse" \
    widget SFCHECK_MODE \
      -command "check_update_files $arrayname"

  CreateLine line \
    label "Run Sfcheck against" \
    widget SFCHECK_DATA \
      -command "check_update_files $arrayname" \
    label data \
    toggle_display USE_LABELS open 1

  CreateLine line \
    widget SFCHECK_ANISOTHERMAL_CORR \
    label "Generate anisothermally corrected SF amplitudes" \
    toggle_display USE_ANISOTHERMAL_CORR open 1

  OpenFolder file 

  CreateInputFileLine line \
      "Enter name of input coordinate file" \
      "Coords in" \
      XYZIN DIR_XYZIN \
       -fileout ANALYSIS_FILE  DIR_ANALYSIS_FILE  _sfcheck \
       -fileout PSOUT  DIR_PSOUT  _rampage \
      -toggle_display USE_XYZIN open 1

  OpenSubFrame frame -toggle_display USE_HKLIN open 1

  CreateLine line \
    label "For Procheck: extract maximum resolution from MTZ file or enter below" -italic \
    toggle_display RUN_PROCHECK open 1

  CreateInputFileLine line \
      "Enter input MTZ file name" \
      "MTZ in" \
       HKLIN DIR_HKLIN  \
	-setfileparam resolution_max RESOLUTION \
        -fileout ANALYSIS_FILE  DIR_ANALYSIS_FILE  _sfcheck \
        -fileout HKLOUT  DIR_HKLOUT  _sfcheck_iso

  OpenSubFrame frame -toggle_display USE_LABELS open 1

  CreateLabinLine line \
    "Choose amplitude (F) and optional sigma (SIGF)" \
     HKLIN "F  " F1  {} \
     -sigma "Sigma  " SIGF1  {} \
     -toggle_display SFCHECK_DATA open [list SF SF_ANOM ]

  CreateLabinLine line \
    "Choose second amplitude (F-) and optional weighting factor (SIGF-)" \
     HKLIN F- F2  {Fm} \
     -sigma Sigma SIGF2  {} \
     -toggle_display SFCHECK_DATA open SF_ANOM

  CreateLabinLine line \
    "Choose intensity (I) and optional sigma (SIGI)" \
     HKLIN I I1  {I} \
     -sigma Sigma SIGI1  {} \
     -toggle_display SFCHECK_DATA open [list I I_ANOM ]

  CreateLabinLine line \
    "Choose second intensity (I-) and optional weighting factor (SIGI-)" \
     HKLIN I- I2  {Im} \
     -sigma "Sigma  " SIGI2  {} \
     -toggle_display SFCHECK_DATA open I_ANOM

  CreateLabinLine line \
    "Choose FreeR label (FREE)" \
     HKLIN FreeR FREE FreeRflag

  CloseSubFrame

  CloseSubFrame

  CreateOutputFileLine line \
      "Enter postscript file name for output analysis from Rampage" \
      "Rampage Output PS" \
      PSOUT DIR_PSOUT \
      -toggle_display RUN_RAMPAGE open 1

  CreateOutputFileLine line \
      "Enter postscript file name for output analysis from SFCHECK" \
      "Sfcheck Output PS" \
      ANALYSIS_FILE DIR_ANALYSIS_FILE \
      -toggle_display RUN_SFCHECK open 1

  OpenSubFrame frame -toggle_display USE_ANISOTHERMAL_CORR open 1

  CreateOutputFileLine line \
      "Output MTZ file with anisothermally corrected SF amplitudes output from Sfcheck" \
      "Output MTZ" \
      HKLOUT DIR_HKLOUT \
      -toggle_display SFCHECK_ANISOTHERMAL_CORR open 1

  CreateLine line \
      message "Set the MTZ column label for anisothermally corrected SF amplutides" \
      label "Use output column labels: F_iso" \
      widget F_ISO -width 20 \
      label "sig(F_iso)" \
      widget SIGF_ISO -width 20 \
      toggle_display SFCHECK_ANISOTHERMAL_CORR open 1

  CloseSubFrame

  OpenFolder 1 RUN_PROCHECK open 1 hide

  CreateLine line \
    message "Leave field blank for analysis of entire structure" \
    label "Do analysis for chain" \
    widget CHAIN_ID

  CreateLine line \
    message "Expected errors dependent on resolution limit of data" \
    label "Maximum resolution limit" \
    widget RESOLUTION

  CreateLine line \
    widget PROCHECK_COLOUR \
    label "Output colour Postscript plot files" \

  CreateLine line \
    widget PROCHECK_PRINT \
    label "Output plots to printer" \
    widget COLOUR_PRINTER \
    toggle_display PROCHECK_COLOUR open 1

  CreateLine line \
    widget PROCHECK_PRINT \
    label "Output plots to printer" \
    widget MONO_PRINTER \
    toggle_display PROCHECK_COLOUR open 0

# Update the file display
  check_update_files $arrayname

}

#-----------------------------------------------------------------------
proc check_update_files { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  # Update the internal parameters which determine
  # which files need to be input
  check_need_hklin $arrayname
  check_need_hklinlabels $arrayname
  check_need_anisothermal_corr $arrayname
  check_need_xyzin $arrayname
}

#-----------------------------------------------------------------------
proc check_need_hklin { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  # Determine whether the user needs to enter
  # the name of an MTZ file
  if { $array(RUN_PROCHECK) } {
    set array(USE_HKLIN) 1
  } elseif { $array(RUN_SFCHECK) == 1 && \
	   [GetValue $arrayname SFCHECK_MODE] == "STRUCTURE" } {
    set array(USE_HKLIN) 0
  } elseif { $array(RUN_SFCHECK) == 1 } {
    set array(USE_HKLIN) 1
  } else {
    set array(USE_HKLIN) 0
  }
}

#-----------------------------------------------------------------------
proc check_need_hklinlabels { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  # Determine whether the user needs to set any MTZ
  # labels
  if { $array(USE_HKLIN) == 1 } {
    if { $array(RUN_SFCHECK) == 1 && \
	   [GetValue $arrayname SFCHECK_MODE] != "STRUCTURE" } {
      set array(USE_LABELS) 1
    } else {
      set array(USE_LABELS) 0
    }
  } else {
    set array(USE_LABELS) 0
  }
}

#-----------------------------------------------------------------------
proc check_need_anisothermal_corr { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  # Determine whether the user has the option of running Sfcheck's
  # anisothermal correction
  if { $array(RUN_SFCHECK) == 1 && \
	   [GetValue $arrayname SFCHECK_MODE] != "STRUCTURE" } {
    set array(USE_ANISOTHERMAL_CORR) 1
  } else {
    set array(USE_ANISOTHERMAL_CORR) 0
  }
}

#-----------------------------------------------------------------------
proc check_need_xyzin { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  # Determine whether the user needs to enter the
  # name of a PDB file

  if { $array(RUN_PROCHECK) || $array(RUN_RAMPAGE) } {
    set array(USE_XYZIN) 1
  } elseif { $array(RUN_SFCHECK) == 1 && \
	   [GetValue $arrayname SFCHECK_MODE] != "EXPERIMENT" } {
    set array(USE_XYZIN) 1
  } else {
    set array(USE_XYZIN) 0
  }

}
