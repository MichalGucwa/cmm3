#
#
#     Copyright (C) 2010 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#
# ======================================================================
# dimple.tcl --
#
# CCP4Interface 
#
# =======================================================================

proc dimple_prereq { } {
  if { ![file exists [FindExecutable dimple] ] || ![file exists [FindExecutable ccp4-python] ] } {
    return 0
  }
  return 1
}

############################################################################
proc dimple_setup { typedefVar arrayname } {
############################################################################
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname array

  #set program_menu {}
  #set program_alias {}

  return 1
}

############################################################################
proc dimple_run { arrayname } {
############################################################################
  upvar #0 $arrayname array

# Sanity Checks:

  # Check for refmac5 
  if { [FindExecutable "refmac5"] == "" } {
         # Not found
         WarningMessage "Input Error: refmac5 not found in system path."
         return 0
     }

  # Check for cad 
  if { [FindExecutable "cad"] == "" } {
         # Not found
         WarningMessage "Input Error: Cad not found in system path."
         return 0
     }

  # Set the root directory
  set array(ROOTDIR) [GetDefaultDirPath]
  
  return 1
}

############################################################################
proc dimple_task_window { arrayname } {
############################################################################
  global configure

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname \
       "DIMPLE: Automated Difference Map Pipeline" \
       [ list "Additional Options" \
       ] ] == 0 } return

  SetProgramHelpFile "dimple"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLineLink line TITLE \
      "http://ccp4wiki.org/~ccp4wiki/wiki/index.php?title=Automated_difference_map_generation_with_DIMPLE" \
      "DIMPLE User Guide"

#=FILES================================================================ 

  OpenFolder file

  # Input MTZ file
  CreateInputFileLine line \
     "Enter name of the target MTZ file" \
     "MTZ in" \
     HKLIN DIR_HKLIN \
      -fileout HKLOUT DIR_HKLOUT "_dimple_soln" \
      -fileout XYZOUT DIR_XYZOUT "_dimple_soln" 

  CreateLabinLine line \
	"Observed intensities (IMEAN) and obligatory sigma (SIGIMEAN)" \
        HKLIN "Imean" IMEAN  {}\
        -sigma "SigImean" SIGIMEAN  {}

  CreateInputFileLine line \
      "Enter coordinate file" \
      "PDB in" \
      XYZIN DIR_XYZIN
  
#  CreateLabinLine line \
	"Observed amplitude (FP) and obligatory sigma (SIGFP)" \
	HKLIN "F    " F  [list F F.F_sigF.F] \
        -sigma "Sigma  " SIGF  [list F F.F_sigF.sigF ]

#  CreateLabinLine line \
      "Choose Free-R flag" \
      HKLIN "Free-R" FreeR_flag  [list FreeR_flag]

  CreateOutputFileLine line \
      "Output MTZ File for solution" \
      "MTZ out" \
      HKLOUT DIR_HKLOUT

  CreateOutputFileLine line \
      "Output PDB File for solution" \
      "PDB out" \
      XYZOUT DIR_XYZOUT

#  CreateLine line \
#      message "Debug mode (gives more verbose output)" \
#      help debug \
#      widget DEBUG -width 4 \
#      label "Use debug mode." \
#      label "Gives a more verbose output" -italic

######################################################################

#=Refinement Options======================================================== 

#  OpenFolder 1 
#
#  CreateLine line \
#      message "Number of cycles of rigid body refinement in Refmac" \
#      help ncycrb \
#      label "Number of cycles of rigid body refinement in Refmac:" \
#      widget NCYCRB -width 3 
#
#
#  CreateLine line \
#      message "Number of cycles of restrained refinement in Refmac" \
#      help ncycrr \
#      label "Number of cycles of restrained refinement in Refmac:" \
#      widget NCYCRR -width 3 
#
#=Additional Options======================================================== 

#  OpenFolder 1 closed 
#
#  CreateLine line \
      message "Debug mode (gives more verbose output)" \
      help debug \
      widget DEBUG -width 4 \
      label "Use debug mode." \
      label "Gives a more verbose output" -italic

}
