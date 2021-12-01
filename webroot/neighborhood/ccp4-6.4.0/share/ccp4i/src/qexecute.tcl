#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - qexecute.tcl
#
#
#
# Quick Execute - baby brother to the Execute in execute.tcl
#
#====================================================================

#CCP4i_cvs_Id $Id$

#----------------------------------------------------------------------
proc Execute {  command script statusout reportout args } {
#----------------------------------------------------------------------
#Quick Execute - baby brother to the Execute in execute.tcl
# Used to run programs internal to graphical ccp4i
  upvar $statusout status
  upvar $reportout report
  set program_success 0
  set logfile {}

  set nargs [llength $args] ; set n 0
  while { $n < $nargs } {
    set comd [lindex $args $n ]
    switch -regexp -- $comd \
    success {
      incr n; set success [lindex $args $n ]
    } log {
      incr n; set logfile [lindex $args $n ]
    }
    incr n
  }

  set cmd "set status \[catch \{exec $command"
  if { $script != "" && $script != " " } { append cmd " < " $script }
  if { $logfile != "" } {
    if { [file exists $logfile ]} {
      append cmd " >> \"$logfile\"" 
    } else {
      append cmd " > \"$logfile\"" 
    }
  }
  append cmd "\} report \]"

# If in environment with Report function then just put
# out a diagnostic level report
#  if { [info procs "Report" ] == "Report" } {
#       Report 0 "Running: $command "
#  }

  eval "$cmd"

# status is the value returned by catch and 0 means command
# successful
  return [ expr {1 - $status} ]
}
