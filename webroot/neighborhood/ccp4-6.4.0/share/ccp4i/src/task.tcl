#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - task.tcl
#
#
# Liz Potterton Jan97
#
#====================================================================

#CCP4i_cvs_Id $Id$

  source [SearchPath TOP src browser_utils.tcl]
  source [SearchPath TOP src utils.tcl]
  source [SearchPath TOP src qexecute.tcl]
  source [SearchPath TOP src window.tcl]
  source [SearchPath TOP src taskwindow.tcl]
  source [SearchPath TOP src util_windows.tcl]
  source [SearchPath TOP src directories.tcl]
  source [SearchPath TOP src exframe.tcl]
  source [SearchPath TOP src varmenu.tcl]
  source [SearchPath TOP src runjob.tcl]
  source [SearchPath TOP src CCP4_utils.tcl]
  source [SearchPath TOP src fileselect.tcl]
  source [SearchPath TOP src database.tcl]
  source [SearchPath TOP src fileviewer.tcl]
  source [SearchPath TOP src local.tcl]

#d_index_title The Task Mode (src/task.tcl)
#d_intro_title The Task Mode
#d_intro In task mode only one task window is visible - this is run with the \
command 'ccp4i -t taskname'  To run in this mode bin/ccp4i.tcl calls the task \
procedure in src/task.tcl  which does the necessary initialisation and opens \
the task window.

#------------------------------------------------------------------
proc task { } {
#------------------------------------------------------------------
#d_sum Initialisation to run CCP4i in task mode. 
  global moduledef
  global system
  global ccp4i_status

  set moduledef(0) ""

  CreateSessionLog
  InitialiseProject
  OpenServerPort
  InitialisePreferences status ccp4i_status
  DbInitialise
  RunTask $system(TASK)
}
