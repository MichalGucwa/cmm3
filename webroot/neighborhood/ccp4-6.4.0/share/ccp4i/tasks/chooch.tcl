#
#     Copyright (C) 1999-2005  Liz Potterton, Peter Briggs, Francois Remacle
#
#     This code is distributed under the terms and conditions of the
#     CCP4 licence agreement as `Part 1' (Annex 2) software.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# ======================================================================
# dyndom.tcl --
#
# task interface for chooch program 
#
# CCP4Interface 
#
# =======================================================================
#------------------------------------------------------------------------
proc chooch_prereq { } {
#------------------------------------------------------------------------
# Check that chooch is available
  if { [file exists [FindExecutable chooch]] } {
    return 1
  } else {
    return 0
  }
  return 0
}
#-------------------------------------------------------------------------
proc chooch_run { arrayname } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array
  return 1
}

#---------------------------------------------------------------
proc chooch_setup { typedefVar arrayname } {
#---------------------------------------------------------------
  upvar #0  $typedefVar typedef
  upvar #0 $arrayname array
  set typedef(_raw_file) { file RAW ".raw"  "raw fluorescence data" "" ""}
  set typedef(_efs_file) { file EFS ".efs"  "Anomalous scattering factors" "" ""}
  
  DefineMenu _verbose_mode [list "No extra output" \
				                 "Some extra output" \
				                 "Many extra output" \
				                 "All output" ] \
				           [ list 0 1 2 3 ]
 return 1

}
#-------------------------------------------------------------------------
proc chooch_task_window { arrayname } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array
  global configure
  global system
  
  SetProgramHelpFile "chooch"

  if { [CreateTaskWindow $arrayname  \
        "Chooch - Determine anomalous scattering factor" "Chooch" \
        [ list "Atomic Parameters" "Energy Parameters" "Output Parameters"  ] ] == 0 } return

  CreateLineTemplate chootempl [list 0.2 0.25 0.35 0.425 0.575 0.7]
  
  OpenFolder protocol

  CreateTitleLine line TITLE
  
  set hasghostview [file exists [FindExecutable gv] ]
  
  CreateLine ps \
      message "Produce graphs in a postscript file" \
	  widget IFPS \
	  label "Generate a postscript file" 

  set n [GetValue configure N_PS_PREVIEW]
  set psview ""
  for { set i 1 } { $i <= $n } { incr i } {
    set viewer [GetValue configure PS_PREVIEW_COM]
    if {[file exists [FindExecutable $viewer]]} {
      set psview $viewer
      set i $n
      }
    }
  if {$psview==""} {
    if {[regexp WINDOWS $system(OPSYS)]} {
      if { [file exists [FindExecutable "gsview32.exe"]]} {
        set psview [FindExecutable "gsview32.exe"]
      }
  } else {
      if {[file exists [FindExecutable "gv"]]} {
        set psview [FindExecutable "gv"]
      }
    }
  }

  if {$psview!=""} {
  CreateLine ps \
	  widget IFPSVIEW \
	  label "and view it" \
	  toggle_display IFPS open 1
  set $array(USEVIEWER) $psview
    }

#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
        "Raw file containing fluorescence data" \
        "RAW in" \
        RAWIN DIR_RAWIN \
		-fileout PSOUT DIR_PSOUT "_chooch" \
		-fileout EFSOUT DIR_EFSOUT "_chooch"
    
  CreateOutputFileLine line \
        "Output file containing anomalous scattering factors" \
        "EFS File" \
        EFSOUT DIR_EFSOUT \
		
  CreateOutputFileLine line \
        "Output postscript file" \
        "PS File" \
        PSOUT DIR_PSOUT \
		-toggle_display IFPS open 1

#=PARAMETERS==========================================================

  OpenFolder 1 closed

  CreateLine xrayabs \
    message "Define energy bandwith" \
    label "Atomic element " \
    widget ATOMEL \
	label "Absorption edge " \
	widget EDGE
	
  OpenFolder 2 closed

  CreateLine energybandwidth \
    message "Define Monochromator energy resolution bandwidth" \
    label "Resolution Bandwidth " \
    widget BANDWIDTH \
	label " dE/E" \
	format template chootempl
	
  CreateLine lowupenergylow \
    message "Define lower and upper energy for fitting below edge regime" \
    label "lower energy" \
    widget LOWLOW \
	label " eV" \
	label "upper energy" \
	widget LOWUP \
	label " eV" \
	format template chootempl
	
	
  CreateLine lowupenergyup \
    message "Define lower and upper energy for fitting above edge regime" \
    label "lower energy" \
    widget UPLOW \
	label " eV" \
	label "upper energy" \
	widget UPUP \
	label " eV" \
	format template chootempl
	
  OpenFolder 3 closed
  
  CreateLine verboselv \
    message "Define the level of verbosity when running chooch" \
    label "I would like " \
    widget VERBOSE 
    
}

#-------------------------------------------------------------------------
proc chooch_review { arrayname job_id} {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array
  
   if {[GetValue $arrayname IFPSVIEW]} {
    exec "[GetValue $arrayname USEVIEWER]" [GetValue $arrayname PSOUT]
  }
}
