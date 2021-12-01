#     Copyright (C) 1999-2008  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - job_utils.tcl
#
#
# Helper commands for CCP4i jobs
#
# Peter Briggs April08
#
#====================================================================

#CCP4i_cvs_Id $Id$

#d_index_title Helper commands for CCP4i jobs (utils/job_utils.tcl)
#d_intro_title Helper commands for CCP4i jobs
#d_intro These commands are utilities which are associated with \
running jobs but which need to be shared between different parts \
of CCP4i that otherwise do not have much in common.

#---------------------------------------------------------------------
proc CreateAnnotatedLogfile { logfile } {
#---------------------------------------------------------------------
#d_sum Run the baubles program to generate an annotated logfile
#d_desc Creates an annotated logfile with the same name as the source \
logfile, but with a .html extension.
#d_arg logfile Name of the source logfile
  global configure

  set htmllogfile "$logfile.html"
  set status [expr {1 - [ catch { eval exec $configure(RUN_BAUBLES) -o "$htmllogfile" "$logfile" <<NULL } msg ]} ]
  if { !$status } {
      # Failed to generate the file
      puts "CreateAnnotatedLogfile: failed for $logfile: $msg"
      DeleteFile "$htmllogfile"
  }
  return $status
}
