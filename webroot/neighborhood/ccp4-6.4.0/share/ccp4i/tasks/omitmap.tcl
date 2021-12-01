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
# omitmap.tcl --
#
# Run sfcheck to generate an omit map
#
# CCP4Interface 
#
# ======================================================================
#-----------------------------------------------------------------------
proc omitmap_setup { typedefVar arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname array
  global loggraph

  set typedef(_omitmap_data) { menu { "Structure Factor" \
					"Intensity" }
			{ SF I } }

  return 1
}


#-----------------------------------------------------------------------
proc omitmap_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  # Set up input and output files
  set array(INPUT_FILES) ""
  append array(INPUT_FILES) "XYZIN " 
  append array(INPUT_FILES) "HKLIN " 

  set array(OUTPUT_FILES) ""
  append array(OUTPUT_FILES) "MAPOUT_FILE " 
  append array(OUTPUT_FILES) HKLOUT 


  return 1
}

#-----------------------------------------------------------------------
proc omitmap_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Use Sfcheck to calculate omit map" "Omitmap" \
	[list "Sfcheck Parameters"]  ] == 0 } return


  OpenFolder protocol 

  CreateTitleLine line TITLE


  CreateLine line \
    label "Run Sfcheck using" \
    widget SFCHECK_DATA \
      -command "omitmap_update_files $arrayname" \
    label data \
    toggle_display USE_LABELS open 1

  OpenFolder file 

  CreateInputFileLine line \
      "Enter name of input coordinate file" \
      "Coords in" \
      XYZIN DIR_XYZIN \
       -fileout MAPOUT_FILE  DIR_MAPOUT_FILE  _sfcheck \
       -fileout HKLOUT  DIR_HKLOUT  _sfcheck \


  CreateInputFileLine line \
      "Enter input MTZ file name" \
      "MTZ in" \
       HKLIN DIR_HKLIN  \

  OpenSubFrame frame -toggle_display USE_LABELS open 1

  CreateLabinLine line \
    "Choose amplitude (F) and optional sigma (SIGF)" \
     HKLIN "F  " F1  {} \
     -sigma "Sigma  " SIGF1  {} \
     -toggle_display SFCHECK_DATA open SF

  CreateLabinLine line \
    "Choose intensity (I) and optional sigma (SIGI)" \
     HKLIN I I1  {I} \
     -sigma Sigma SIGI1  {} \
     -toggle_display SFCHECK_DATA open I 


  CloseSubFrame

  CloseSubFrame

  CreateOutputFileLine line \
      "Enter output map file name" \
      "Map out" \
      MAPOUT_FILE DIR_MAPOUT_FILE \

  CreateOutputFileLine line \
      "Enter output hkl file name" \
      "HKL out" \
      HKLOUT DIR_HKLOUT \


  OpenFolder 1 open

  CreateLine line \
    message "Enter number of omit cycles" \
    label "Number of omit cycles" \
    widget NOMIT                             

# Update the file display
  omitmap_update_files $arrayname

}

#-----------------------------------------------------------------------
proc omitmap_update_files { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  # Update the internal parameters which determine
  # which files need to be input
  omitmap_need_hklinlabels $arrayname
}

#-----------------------------------------------------------------------
proc omitmap_need_hklinlabels { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  # Determine whether the user needs to set any MTZ
  # labels
  
	if { [GetValue $arrayname SFomitmap_MODE] != "STRUCTURE" } {
      set array(USE_LABELS) 1
    } else {
      set array(USE_LABELS) 0
    }
}

