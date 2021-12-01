# ======================================================================
# phasecombine.tcl --
#
# CCP4Interface 
#
# =======================================================================
#------------------------------------------------------------------------------
proc phasecombine_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable cphasecombine]] } {
    return 0
  }
  return 1
}
#---------------------------------------------------------------------
proc phasecombine_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [ CreateTaskWindow $arrayname  \
	     "Phase combination" "phasecombine" \
	     [ list \
	       "Options" \
	      ] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "cphasecombine"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter input MTZ file name" \
      "MTZ in" \
      HKLIN DIR_HKLIN \
      -fileout HKLOUT DIR_HKLOUT "_phasecombine"

  CreateLine line  \
        message "Chose the input reflection data to use."  \
        label "First set of phases from:"

  CreateLabinLine4 line \
      "Choose Hendrickson-Lattman coefficients from phasing" \
      HKLIN      "HLA" HLA1  [list HLA obs.ABCD.A] \
      -dependent "HLB" HLB1  [list HLB obs.ABCD.B] \
      -dependent "HLC" HLC1  [list HLC obs.ABCD.C] \
      -dependent "HLD" HLD1  [list HLD obs.ABCD.D]

  CreateLine line  \
        message "Chose the input reflection data to use."  \
        label "Second set of phases from:"

  CreateLabinLine4 line \
      "Choose Hendrickson-Lattman coefficients from phasing" \
      HKLIN      "HLA" HLA2  [list HLA obs.ABCD.A] \
      -dependent "HLB" HLB2  [list HLB obs.ABCD.B] \
      -dependent "HLC" HLC2  [list HLC obs.ABCD.C] \
      -dependent "HLD" HLD2  [list HLD obs.ABCD.D]

  CreateOutputFileLine line \
      "Enter output MTZ file name" \
      "MTZ out" \
      HKLOUT DIR_HKLOUT

  CreateLine line \
        message "Output column label prefix (colout)" \
        help colout \
        label "Output column label prefix" \
        widget COLOUT -width 12

#-----------------------------------------------------

  OpenFolder 1 closed

  CreateLine line \
      message "Scale the HL coeffs to change the width of the distributions" \
      help weight-hl-1 \
      label "Weight for first set of HL coeffs" \
      widget WEIGHT1 \
      help weight-hl-2 \
      label "Weight for second set of HL coeffs" \
      widget WEIGHT2

}

