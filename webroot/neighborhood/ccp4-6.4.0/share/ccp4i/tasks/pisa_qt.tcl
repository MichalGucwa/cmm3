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
# pisa_qt.tcl --
#
# This is a dummy interface file that launches Qt-PISA
#
# CCP4Interface 
#
# =======================================================================

#--------------------------------------------------------------------
proc pisa_qt_setup { typedefVar arrayname } {
#--------------------------------------------------------------------
  global env

  set workdir [GetDefaultDirPath]
  set cmd "[BinPath qtpisa] $workdir &"
  set app [file join $env(CCP4) qtpisa.app Contents MacOS qtpisa]
  if { [file isfile $app] } { set cmd "$app $workdir &" }

  set status [Execute $cmd {} program_status report ]
  return 0
}

#--------------------------------------------------------------------
proc pisa_qt_task_window { typedefVar arrayname } {
#--------------------------------------------------------------------
# Dummy procedure required for startup only.
}
