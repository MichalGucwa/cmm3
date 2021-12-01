#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# ======================================================================
# r500.tcl --
#
# CCP4Interface 
#
# =======================================================================
#------------------------------------------------------------------------
proc r500_prereq { } {
#------------------------------------------------------------------------
# Check that r500 executables are available
  # r500
  if { ![file exists [FindExecutable r500ccp4]] } {
    return 0
  }
  return 1
}

#---------------------------------------------------------------------
proc r500_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0  $typedefVar typedef
  upvar #0 $arrayname array

  return 1
}

# procedure to draw task window
#---------------------------------------------------------------------
proc r500_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
        "PDB Remark 500 checker" "R500" \
               {} ] == 0 } return

  SetProgramHelpFile "r500"

  set array(INITIALISED) 0

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

#=FILES================================================================ 

  OpenFolder file

  CreateLine line \
	  label "Run r500 to check the geometry in a PDB file" \
	  -italic

  CreateInputFileLine line \
        "Enter name of input coordinate file" \
        "PDB file" \
        XYZIN DIR_XYZIN 
#		-fileout XYZOUT DIR_XYZOUT "_baverage" \
#		-fileout RMSTAB DIR_RMSTAB "_bavrmstab"
		
#CreateOutputFileLine line \
#      "Enter output PDB file name (XYZOUT)" \
#       "PDB out" \
#       XYZOUT DIR_XYZOUT
#	   
#CreateOutputFileLine line \
#      "Enter output rms table file name (RMSTAB)" \
#       "RMS out" \
#       RMSTAB DIR_RMSTAB

}

#--------------------------------------------------------------
proc r500_run { arrayname } {
#--------------------------------------------------------------
  global system

  # Check for r500
  if { [FindExecutable [ string tolower "r500" ] ] == "" } {
         # Not found
         WarningMessage "Error: r500ccp4 not found in system path."
         return 0
     }
  
  return 1
}
