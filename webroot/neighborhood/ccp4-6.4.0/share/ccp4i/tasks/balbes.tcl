# ======================================================================
# balbes.tcl --
#
# CCP4Interface
#
# ======================================================================= 
#------------------------------------------------------------------------------
proc balbes_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable balbes]] } {
    return 0
  }
  return 1
}

#----------------------------------------------------------------------
proc balbes_setup {typedefVar arrayname } {
#----------------------------------------------------------------------
  upvar #0  $typedefVar typedef
  upvar #0  $arrayname  array

  set typedef(_balbes_mode) { menu { "Standard MR"
                                "Candidate Models Only"}
                          { STD_MR  MOL_SEL } }

  DefineMenu _input_mode [list "no input PDB" "input PDB" ] \
                         [list NO_PDB EXTRA_PDB  ] 

  DefineMenu _balbes_input_sf_type [list "MTZ file" "EM map" "CIF file"] \
                                          [list HKLIN MAPIN CIFIN]

  DefineMenu _balbes_input_model_type [list "PDB file" "EM map"] \
                                          [list PDB MAP]

  return 1
}

#---------------------------------------------------------------------
proc balbes_run { arrayname } {
#--------------------------------------------------------------------- 
  upvar #0 $arrayname array

  # Source for input structure factors
  #if { [GetValue $arrayname INPUT_SF_TYPE] == "HKLIN" } {
  #  set INPUT_SF_FILE HKLIN
  # }

  # if { [GetValue $arrayname INPUT_SF_TYPE] == "CIFIN" } {
  #  set INPUT_SF_FILE CIFIN
  #}

  # if { [GetValue $arrayname INPUT_SF_TYPE] == "MAPIN" } {
  #  set INPUT_SF_FILE MAPIN
  # }

  switch [GetValue $arrayname BALBES_MODE] \
  STD_MR {  
           # check if input files exist
           if { [file exists [GetFullFileName $array(HKLIN) $array(DIR_HKLIN) ] ] } {
                set array(INPUT_FILES) " HKLIN "
           } else {
                WarningMessage "Can not find input structure factor file." -button Cancel
                return 0
           }

           if { [file exists [GetFullFileName $array(SEQIN) $array(DIR_SEQIN) ] ] } {
                append array(INPUT_FILES) " SEQIN " 
           } else {
                WarningMessage "Can not find input target sequence file." -button Cancel
                return 0
           }
                
           set array(OUT_ROOTDIR) [GetDefaultDirPath]

           if { $array(XYZOUT) != "" } {
               set array(OUTPUT_FILES) " XYZOUT "
           } else {
               WarningMessage "Please enter the name of the output XYZ file." -button Cancel
                return 0
           }
     
 
           if { $array(HKLOUT) != "" } {
               append array(OUTPUT_FILES) " HKLOUT "
           } else {
               WarningMessage "Please enter the name of the output SF file." -button Cancel
                return 0
           }
           
           

  } default {
          WarningMessage "You need to select --Do Standard MR-- as the work mode." -button Cancel   
          return 0
  }

  return 1

}

#-----------------------------------------------------------------------
proc balbes_task_window {arrayname} {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow  $arrayname \
        "BALBES " "BALBES" \
        ] == 0 } return



#=PROTOCOL==============================================================

  OpenFolder protocol

  CreateLine line \
    label "This interface is for version 0.0.1 of BALBES" -italic

  CreateTitleLine line TITLE

  CreateLine line \
    message "Choose the basic operation of BALBES" \
    help belbes_mode \
    label "Do" \
    widget BALBES_MODE 

#=FILES================================================================

  OpenSubFrame frame -toggle_display BALBES_MODE open [list STD_MR ]

  # CreateLine line \
  #  message "Use SF amplitudes from MTZ file or SF generated from an EM map" \
  #  label "Get input structure factors from" \
  #  widget INPUT_SF_TYPE

  OpenFolder file
  
  # HKLIN input -regardless MTZ or CIF 

  CreateInputFileLine line \
        "Enter MTZ, or CIF file name " \
        "STRUCTURE FACTOR FILE (MTZ or CIF) in" \
        HKLIN DIR_HKLIN \
        -fileout HKLOUT DIR_HKLOUT "_balbes_out" \
        -fileout XYZOUT DIR_XYZOUT "_balbes_out"
        # -toggle_display INPUT_SF_TYPE open HKLIN
         
  # EM map input
  #CreateInputFileLine line \
  #      "Enter EM map file name (MAPIN)" \
  #      "EM map" \
  #      MAPIN DIR_MAPIN \
  #      -toggle_display INPUT_SF_TYPE open MAPIN

  # CIF input
  #CreateInputFileLine line \
  #      "Enter CIF file name (CIFIN)" \
  #      "CIF in" \
  #      CIFIN DIR_CIFIN \
  #      -toggle_display INPUT_SF_TYPE open CIFIN

  # Sequence input

  CreateInputFileLine line \
        "Enter name of sequence file" \
        "SEQ target in " \
        SEQIN DIR_SEQIN \
        
  CloseSubFrame

  OpenSubFrame frame -toggle_display BALBES_MODE open [list STD_MR]

  CreateOutputFileLine line \
    "Enter name for solution PDB file"  \
    "Solution PDB" \
    XYZOUT DIR_XYZOUT \
      -toggle_display BALBES_MODE open [ list  STD_MR ]

  CreateOutputFileLine line \
    "Enter name for solution structure factor file"  \
    "Solution HKL " \
    HKLOUT DIR_HKLOUT \
      -toggle_display BALBES_MODE open [ list  STD_MR ]

  CloseSubFrame


  #-------------------------------- Required parameters

}







