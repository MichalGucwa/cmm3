# ======================================================================
# sfcalcmap.tcl --
#
# CCP4Interface 
#
# =======================================================================
#------------------------------------------------------------------------------
proc sfcalcmap_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable cinvfft]] } {
    return 0
  }
  return 1
}
#---------------------------------------------------------------------
proc sfcalcmap_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [ CreateTaskWindow $arrayname  \
	     "Structure factor calculation from map" "sfcalcmap" \
	     {} ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "cinvfft"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

#=FILES================================================================

  OpenFolder file 

  CreateLine line \
      label "Structure factors will be appended to existing MTZ file."

  CreateInputFileLine line \
      "Enter input map file name" \
      "Map in" \
      MAPIN DIR_MAPIN

  CreateInputFileLine line \
      "Enter input MTZ file name" \
      "MTZ in" \
      HKLIN DIR_HKLIN \
      -fileout HKLOUT DIR_HKLOUT "_sfcalcmap"

  CreateOutputFileLine line \
      "Enter output MTZ file name" \
      "MTZ out" \
      HKLOUT DIR_HKLOUT

  CreateLine line \
        message "Output column label prefix (colout)" \
        help colout \
        label "Output column label prefix" \
        widget COLOUT -width 12

}
