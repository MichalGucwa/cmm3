#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# ======================================================================
# ccp4mg.tcl --
#
# Run ccp4mg
#
# CCP4Interface 
#
# =======================================================================

#------------------------------------------------------------------------
proc ccp4mg_prereq { } {
#------------------------------------------------------------------------
# Check that ccp4mg is available
  global configure
  global system
  
  #Check on the variable defined in the configuration interface
  set test [FindExecutable [GetValue configure RUN_CCP4MG]]
  if { [file exists $test] && ![file isdirectory $test] } {
    return 1
	
  #Check on the standard executable
  } else {
    if { [regexp WINDOWS $system(OPSYS)] } {
	  if { [file exists [FindExecutable winccp4mg]] } {
	    set configure(RUN_CCP4MG) [FindExecutable winccp4mg]
	    return 1
      }
    } elseif { [regexp UNIX $system(OPSYS)] } {
  	  if { [file exists [FindExecutable ccp4mg]] } {
	    set configure(RUN_CCP4MG) [FindExecutable ccp4mg]
	    return 1
      }
    } else {
	  return 0
    }
  }
  return 0
}
#----------------------------------------------------------------------
proc ccp4mg_setup { typedefVar arrayname } {
#----------------------------------------------------------------------
  upvar #0  $typedefVar typedef
  upvar #0 $arrayname array

  return 1
}

#----------------------------------------------------------------------
proc ccp4mg_review { arrayname job_id } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array

  
  return 1
}

#----------------------------------------------------------------------
proc ccp4mg_task_window { arrayname } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
       "Launch CCP4mg" "CCP4mg" \
       [list "Coordinate files" \
             "Map files" \
             "MTZ files" ] \
	-action_buttons [list quit interactive ] ] == 0 } return

  SetProgramHelpFile "ccp4mg"

#=PROTOCOL==============================================================

  OpenFolder protocol

  CreateTitleLine line TITLE

  CreateLine line \
    widget NORESTORE \
    label "Do not load any data saved on last exit from CCP4mg"

#=FILES================================================================

  OpenFolder file

#=REMAINING FOLDERS====================================================

  # Proteins
  OpenFolder 1

  CreateExtendingFrame NXYZS ccp4mg_coords \
     "Specify an additional input pdb file for protein structures to display" \
     "Add input pdb file" \
     [list XYZIN DIR_XYZIN]

  # Maps
  OpenFolder 2

  CreateExtendingFrame NMAPS ccp4mg_map \
     "Specify an additional input map file for maps to display" \
     "Add input map file" \
      [list MAPIN DIR_MAPIN]


  # MTZs
  OpenFolder 3

  CreateExtendingFrame NMTZS ccp4mg_mtz \
     "Specify an additional input MTZ file for maps to display" \
     "Add input MTZ file" \
      [list MTZIN DIR_MTZIN FP SIGFP]

#=PARAMETERS==========================================================

  #OpenFolder 4 closed

  #CreateLine line \
  #   message "Set the initial contour levels for map display" \
  #  label "Contour 1:" \
  #  widget CONTOUR_LEVEL,1 \
  #   label "Contour 2:" \
  #   widget CONTOUR_LEVEL,2 \
  #   label "Contour 3:" \
  #  widget CONTOUR_LEVEL,3

}

#----------------------------------------------------------------------
proc ccp4mg_coords { arrayname counter } {
#----------------------------------------------------------------------
# Draw one line of the extending frame for protein PDB file input
  upvar #0 $arrayname array

  CreateInputFileLine line \
    "Enter input coordinate file name" \
    "Coord file $counter" \
    XYZIN DIR_XYZIN
}
#----------------------------------------------------------------------
proc ccp4mg_map { arrayname counter } {
#----------------------------------------------------------------------
# Draw one line of the extending frame for map file input
  upvar #0 $arrayname array

  CreateInputFileLine line \
    "Enter input map file name" \
    "Map file $counter" \
    MAPIN DIR_MAPIN
}
#----------------------------------------------------------------------
proc ccp4mg_mtz { arrayname counter } {
#----------------------------------------------------------------------
# Draw one line of the extending frame for MTZ file input
  upvar #0 $arrayname array

  CreateInputFileLine line \
    "Enter input MTZ file name" \
    "MTZ file $counter" \
    MTZIN DIR_MTZIN

  CreateLabinLine line \
    "Choose amplitude (FP) and essential sigma (SIGFP)" \
     MTZIN,$counter "FP"  FP  {} \
     -sigma "SIGFP" SIGFP  {}

}

#----------------------------------------------------------------------
proc ccp4mg_run { arrayname } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array
  global configure

  
  #set array(INPUT_FILES) "XYZIN,1 "
  #for { set n 2 } { $n <= $array(NXYZS) } { incr n } {
  #  append array(INPUT_FILES) "XYZIN,$n "
  #}
  #for { set n 1 } { $n <= $array(NMAPS) } { incr n } {
  #  append array(INPUT_FILES) "MAPIN,$n "
  #}
  #for { set n 1 } { $n <= $array(NMTZS) } { incr n } {
  #  append array(INPUT_FILES) "MTZIN,$n "
  #}
    
  # Set up output files
  #set array(OUTPUT_FILES) ""

  set command  "$configure(RUN_CCP4MG)"
  if $array(NORESTORE) { append command " -norestore" }
  for { set n 1 } { $n <= $array(NXYZS) } { incr n } {
    set filn [GetFullFileName0 $arrayname XYZIN,$n]
    if [file exists $filn] {
      append command " -pdb $filn"
    }
  }
  for { set n 1 } { $n <= $array(NMAPS) } { incr n } {
    set filn [GetFullFileName0 $arrayname MAPIN,$n]
    if [file exists $filn] { append command " -map $filn" }
  }
  for { set n 1 } { $n <= $array(NMTZS) } { incr n } {
    set filn [GetFullFileName0 $arrayname MTZIN,$n]
    if [file exists $filn] { 
      append command " -mtz $filn $array(FP,$n) $array(SIGFP,$n)" 
    }
  }

  #puts "command $command"
  eval "set status \[catch \{exec $command &\} \]"

  return 1
}

