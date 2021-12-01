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
# phistats.tcl --
#
# CCP4Interface 
#
# =======================================================================

#---------------------------------------------------------------------
proc phistats_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0  $typedefVar typedef
  upvar #0 $arrayname array

  return 1
}

# procedure to draw task window
#---------------------------------------------------------------------
proc phistats_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
        "Analysis of phase set agreement" "Phistats" \
               {} ] == 0 } return

  SetProgramHelpFile "phistats"

  set array(INITIALISED) 0

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

#=FILES================================================================ 

  OpenFolder file

  CreateLine line \
	  label "Run phistats to analyse agreement between phase sets" \
	  -italic

  # Input MTZ file
  CreateInputFileLine line \
        "Enter name of input mtz file containing phase sets to be analysed" \
        "MTZ in" \
        HKLIN DIR_HKLIN

  # MTZ labels
  CreateLabinLine line \
      "Assign structure factor amplitudes (FP) and sigmas (SIGFP)" \
      HKLIN "FP" FP {NULL} \
      -sigma "SIGFP" SIGFP {NULL}

  CreateLabinLine line \
      "Assign phases (PHIBP) and weights (WP, if available) for first phase set" \
      HKLIN "PHIBP" PHIBP {NULL} \
      -sigma "WP" WP {NULL}

  CreateLabinLine line \
      "Assign phases (PHIB2) and weights (W2, if available) for second phase set" \
      HKLIN "PHIB2" PHIB2 {NULL} \
      -sigma "W2" W2 {NULL}

}

#--------------------------------------------------------------
proc phistats_run { arrayname } {
#--------------------------------------------------------------
  global system
  return [StartLoggraph]
}

#-----------------------------------------------------------------
proc phistats_review { arrayname job_id } {
#-----------------------------------------------------------------
  upvar #0 $arrayname array
# This procedure is a copied from the baverage interface
# It is called after phistats has completed successfully
# Will try to update loggraph - there may be a problem if phistats
# has been faster than loggraph which should have send message to
# LGServerReceive

# To give loggraph a chance to get started use UpdateLoggraph to
# call itself recursively until 

  UpdateLoggraph [GetLogFileName $job_id] 0 1000 5001

  return 1
}
