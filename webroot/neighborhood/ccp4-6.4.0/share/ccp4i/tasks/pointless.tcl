#
#     Copyright (C) 2007  Phil Evans, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# ======================================================================
# pointless.tcl --
#
# CCP4Interface 
#
# =======================================================================

#CCP4i_cvs_Id $Id$

# Get the Pointless utilities
source [SearchPath TOP tasks pointless_utils.tcl]

#-----------------------------------------------------------------------
proc pointless_prereq { } {
#-----------------------------------------------------------------------
  if { ![file exists [FindExecutable "pointless"]] } {
    return 0
  }
  return 1
}

#-----------------------------------------------------------------------
proc pointless_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  # Assemble list of input files
  set array(INPUT_FILES) ""
  for { set i 1 } { $i <= $array(N_HKLINX) } { incr i } {
      if { $array(HKLIN_FILETYPE) == "MTZ file" } {
	  append array(INPUT_FILES) " HKLINX,$i"
      } elseif { $array(HKLIN_FILETYPE) == "XDS file" } {
	  append array(INPUT_FILES) " XDS_SCA_IN,$i"
      } elseif { $array(HKLIN_FILETYPE) == "SCA file" } {
	  append array(INPUT_FILES) " XDS_SCA_IN,$i"
      }
  }

  # If a reference file was also specified then include that
  if { $array(USE_HKLREF) } {
      append array(INPUT_FILES) " HKLREF"
  }
  set array(OUTPUT_FILES) ""
  if { $array(WRITE_HKLOUT) } {
      append array(OUTPUT_FILES) " HKLOUT"
  }
  if { $array(WRITE_XMLOUT) } {
      append array(OUTPUT_FILES) " XMLOUT"
  }

  # Check rest of input
  if { ![PointlessCheckRun $arrayname] } { return 0 }

  return 1
}

# procedure which is run automatically before drawing the interface
# used to set up variables, menus etc
#---------------------------------------------------------------------
proc pointless_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname array

  PointlessSetup $typedefVar $arrayname

  return 1
}

# procedure to draw task window
#---------------------------------------------------------------------
proc pointless_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  PointlessTaskWindow $arrayname
}

