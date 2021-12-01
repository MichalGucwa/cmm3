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
# baverage.tcl --
#
# CCP4Interface 
#
# =======================================================================

#---------------------------------------------------------------------
proc baverage_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0  $typedefVar typedef
  upvar #0 $arrayname array

  return 1
}

# procedure to draw task window
#---------------------------------------------------------------------
proc baverage_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
        "Temperature Factor Analysis" "Baverage" \
               {} ] == 0 } return

  SetProgramHelpFile "baverage"

  set array(INITIALISED) 0

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

#=FILES================================================================ 

  OpenFolder file

  CreateLine line \
	  label "Run baverage to generate graphs of average B-factor versus residue for each chain in the PDB file" \
	  -italic

  CreateInputFileLine line \
        "Enter name of input coordinate file" \
        "PDB file" \
        XYZIN DIR_XYZIN \
		-fileout XYZOUT DIR_XYZOUT "_baverage" \
		-fileout RMSTAB DIR_RMSTAB "_bavrmstab"
		
CreateOutputFileLine line \
      "Enter output PDB file name (XYZOUT)" \
       "PDB out" \
       XYZOUT DIR_XYZOUT
	   
CreateOutputFileLine line \
      "Enter output rms table file name (RMSTAB)" \
       "RMS out" \
       RMSTAB DIR_RMSTAB

}

#--------------------------------------------------------------
proc baverage_run { arrayname } {
#--------------------------------------------------------------
  global system
  return [StartLoggraph]
}

#-----------------------------------------------------------------
proc baverage_review { arrayname job_id } {
#-----------------------------------------------------------------
  upvar #0 $arrayname array
# This procedure called after baverage has completed successfully
# Will try to update loggraph - there may be aproblem if baverage
# has been faster than loggraph which should have send message to
# LGServerReceive

# To give loggraph a chance to get started use UpdateLoggraph to
# call inself recursively
# MDW 23/01/06  Have increased finally parameter as this
# was failing on fast machines.  

  UpdateLoggraph [GetLogFileName $job_id] 0 1000 100001

  return 1
}
