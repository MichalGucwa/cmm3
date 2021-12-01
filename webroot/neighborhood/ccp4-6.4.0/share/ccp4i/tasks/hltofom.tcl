# ======================================================================
# hltofom.tcl --
#
# CCP4Interface 
#
# =======================================================================
#------------------------------------------------------------------------------
proc hltofom_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable chltofom]] } {
    return 0
  }
  return 1
}
#------------------------------------------------------------------------
proc hltofom_setup { typedefname arrayname }  {
#------------------------------------------------------------------------

  upvar #0 $typedefname typedef

  set typedef(_hltofom_convert) { menu { "from HL coeffs to phi/fom" \
                                         "from phi/fom to HL coeffs" } \
                                       { HLTOFOM FOMTOHL } }
  return 1
}

#---------------------------------------------------------------------
proc hltofom_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [ CreateTaskWindow $arrayname  \
	     "Convert between HL coeffs and phi/fom" "HLtoFOM" \
	     "" ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "chltofom"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line  \
        message "Convert "  \
        label "Convert " \
        widget CONVERT

#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter input MTZ file name" \
      "MTZ in" \
      HKLIN DIR_HKLIN \

  CreateLabinLine4 line \
      "Choose Hendrickson-Lattman coefficients" \
      HKLIN       "HLA" HLA  [list HLA obs.ABCD.A] \
      -dependent  "HLB" HLB  [list HLB obs.ABCD.B] \
      -dependent  "HLC" HLC  [list HLC obs.ABCD.C] \
      -dependent  "HLD" HLD  [list HLD obs.ABCD.D] \
      -toggle_display CONVERT open HLTOFOM

  CreateLabinLine line \
      "Choose phi/fom" \
      HKLIN    "PHI" PHI  [list PHIB obs.Phi_fom.phi] \
      -sigma   "FOM" FOM  [list FOM  obs.Phi_fom.fom] \
      -toggle_display CONVERT open FOMTOHL

  CreateOutputFileLine line \
      "Output MTZ File" \
      "Work MTZ out" \
      HKLOUT DIR_HKLOUT

  CreateLine line \
        message "Output column label prefix (colout)" \
        help colout \
        label "Output column label prefix" \
        widget COLOUT -width 12

}


