#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# ======================================================================
# dbviewer.tcl --
#
# This is a dummy interface file that launches the CCP4i dbviewer program 
#
# CCP4Interface 
#
# =======================================================================

#------------------------------------------------------------------------
proc dbviewer_prereq { } {
#------------------------------------------------------------------------
# Check that Shelx executables are available
  # Shelxc
  if { ![file exists [FindExecutable dot]] } {
    return 0
  }
  return 1
}

#--------------------------------------------------------------------
proc dbviewer_setup { typedefVar arrayname } {
#--------------------------------------------------------------------

  global env

  # Set the path to the python wrapper for dbviewer
  if { [info exists env(MRBUMP)] } {
        set dbview [file join $env(MRBUMP) bin/pydbviewer]
  } else {
        set dbview [file join $env(CCP4) bin/pydbviewer]
  }

  # Make sure we get rid of waiting message
  PleaseWait

  set d [exec [BinPath ccp4-python] -u $dbview &] 
  #set status [Execute $cmd program_status report]
 
  return 0
}

#--------------------------------------------------------------------
proc dbviewer_task_window { typedefVar arrayname } {
#--------------------------------------------------------------------
# Dummy procedure required for startup only.
}
