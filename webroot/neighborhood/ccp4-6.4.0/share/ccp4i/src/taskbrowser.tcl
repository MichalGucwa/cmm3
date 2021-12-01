#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - taskbrowser.tcl
#
#
#
# Create the main interface window 
#
# Liz Potterton Jan97
#
#====================================================================

#CCP4i_cvs_Id $Id$

#d_index_title The Taskbrowser (src/taskbrowser.tcl)
#d_intro_title The Taskbrowser
#d_intro The taskbrowser.tcl file contains procedures which are specific for \
running the ccp4i task browser (i.e. the usual way to run ccp4i). \
This file has a list of the other files which must be sourced \
and the procedure taskbrowser which is called from the startup bin/ccp4i.tcl

#-------------------------------------------------------------------------
proc taskbrowser { } {
#-------------------------------------------------------------------------
#d_sum Initialise CCP4i to run the taskbrowser

# Set up The System

  global system
  global preferences
  global typedef
  global moduledef
  global ccp4i_status

  SetSystemVar block_scroll_update 0

# Initialise modules list
  set moduledef(0) " "
  if { ![ ReadTaskList "moduledef" modules ] } { exit }

  InitialisePreferences status ccp4i_status
  if { [lsearch [ListModules moduledef] $ccp4i_status(CURRENT_MODULE)] < 0 } {
      set moduledef(CURRENT_MODULE) [lindex [ListModules moduledef] 0]
  } else {
      set moduledef(CURRENT_MODULE) $ccp4i_status(CURRENT_MODULE)
  }

  set moduledef(CURRENT_MODULE_TITLE) \
      [GetModuleDesc moduledef $moduledef(CURRENT_MODULE)]

  CreateTaskBrowser $moduledef(PROJECT) $moduledef(TITLE) "." moduledef

  CreateSessionLog

#-----------------------------------------------------------------------

# Open the server socket
  OpenServerPort

#Initialise database
  DbInitialise

# Initialise CCP4 stuff
  InitialiseProject

# Deal with database startup options
  InitialiseDatabaseOptions

}

#
# Top level code to source  required files before 
# kicking off taskbrowser proper
#

global system

  source [SearchPath TOP src utils.tcl]
  source [SearchPath TOP src qexecute.tcl]
  source [SearchPath TOP src runjob.tcl]
  source [SearchPath TOP src job_utils.tcl]
  source [SearchPath TOP src window.tcl]
  source [SearchPath TOP src exframe.tcl]
  source [SearchPath TOP src varmenu.tcl]
  source [SearchPath TOP src taskwindow.tcl]
  source [SearchPath TOP src util_windows.tcl]
  source [SearchPath TOP src local.tcl]
  source [SearchPath TOP src CCP4_utils.tcl]
  source [SearchPath TOP src browser_utils.tcl]
  source [SearchPath TOP src database.tcl]
  source [SearchPath TOP src fileselect.tcl]
  source [SearchPath TOP src fileviewer.tcl]
  source [SearchPath TOP src directories.tcl]
  source [SearchPath TOP src modules_utils.tcl]

  # Initialise bubble help for graphical applications
  InitialiseBubbleHelp
