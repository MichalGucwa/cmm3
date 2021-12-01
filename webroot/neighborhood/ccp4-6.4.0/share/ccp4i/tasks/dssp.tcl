#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# ======================================================================
# dssp.tcl --
#
# Create DSSP secondary structure assignment for a PDB file
#
# CCP4Interface 
# Created Jan 2013 by Robbie P. Joosten
#
# =======================================================================

#------------------------------------------------------------------------
proc dssp_prereq { } {
#------------------------------------------------------------------------
# Check that dssp executable is available
  if { ![file exists [FindExecutable mkdsspX]] } {
    return 0
  }
  return 1
}

#---------------------------------------------------------------------
# procedure to draw task window
#---------------------------------------------------------------------
proc dssp_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
        "Calculate Secondary Structure" "DSSP" \
               {} ] == 0 } return

  SetProgramHelpFile "dssp"

  set array(INITIALISED) 0

#=PROTOCOL==============================================================

  OpenFolder protocol

  CreateTitleLine line TITLE

#=FILES================================================================ 

  OpenFolder file

  CreateInputFileLine line \
      "Enter input coordinate file name" \
        "PDB In" \
       XYZIN DIR_XYZIN \
      -fileout DSSPOUT DIR_DSSPOUT "--"

  CreateOutputFileLine line \
      "Enter output DSSP file" \
       "DSSP Out" \
       DSSPOUT DIR_DSSPOUT
}

