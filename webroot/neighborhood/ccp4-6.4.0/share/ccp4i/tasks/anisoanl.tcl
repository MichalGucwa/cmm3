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
# anisoanl.tcl --
#
# CCP4Interface 
#
# =======================================================================

#---------------------------------------------------------------------
proc anisoanl_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
upvar #0  $typedefVar typedef

  return 1
}

#-------------------------------------------------------------------------
proc anisoanl_run { arrayname } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(INPUT_FILES) "XYZIN"
  set array(OUTPUT_FILES) ""

  if $array(USE_TLSIN) { append array(INPUT_FILES) " TLSIN" }
  if $array(FITTLS) { append array(OUTPUT_FILES) " TLSOUT" }
  if $array(FITTLS) { append array(OUTPUT_FILES) " XYZOUT" }
  if $array(RIGIDBODY) { append array(OUTPUT_FILES) " PSOUT" }

  return 1
}
 
#----------------------------------------------------------------
proc anisoanl_task_window { arrayname } {
#----------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
    	"Analyse anisotropic U parameters" "anisoanl" \
	[ list "PLOT parameters" \
               "RIGIDBODY parameters" \
               "FITTLS parameters" ] ] == 0 } return

  SetProgramHelpFile "anisoanl"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
        message "Do you want plots of Uiso and A (PLOT)" \
	help key_plot \
        widget PLOT \
        label "Produce loggraph plots of Uiso, A, etc." 

  CreateLine line \
        message "Do rigid-body analysis (RIGIDBODY)" \
	help key_rigidbody \
        widget RIGIDBODY \
        label "Do a rigid-body analysis of ADPs " 

  CreateLine line \
        message "Fit TLS parameters to ADPs (FITTLS)" \
	help key_fittls \
        widget FITTLS \
        label "Fit TLS parameters to ADPs" 

  CreateLine line \
        message "Use TLS file or assume all atoms to be included" \
        widget USE_TLSIN \
        label "Use TLS file to set atom selection" 

#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter input coordinate file name (XYZIN)" \
      "PDB in" \
       XYZIN DIR_XYZIN \
     -fileout XYZOUT DIR_XYZOUT "_anisoanl" 

  OpenSubFrame frame -toggle_display FITTLS open { 1 } 

  CreateOutputFileLine line \
        "Output coordinate file" \
        "PDB out" \
        XYZOUT DIR_XYZOUT

  CloseSubFrame

  OpenSubFrame frame -toggle_display USE_TLSIN open { 1 } 

  CreateInputFileLine line \
      "Enter input TLS file name (TLSIN)" \
      "TLS in" \
       TLSIN DIR_TLSIN \
     -fileout TLSOUT DIR_TLSOUT "_anisoanl" 

  CloseSubFrame

  OpenSubFrame frame -toggle_display FITTLS open { 1 } 

  CreateInputFileLine line \
      "Enter output TLS file name (TLSOUT)" \
      "TLS out" \
       TLSOUT DIR_TLSOUT 

  CloseSubFrame

  OpenSubFrame frame -toggle_display RIGIDBODY open { 1 } 

  CreateOutputFileLine line \
        "Output postscript file" \
        "PSOUT" \
        PSOUT DIR_PSOUT

  CloseSubFrame

#=PARAMETERS1===========================================================

  OpenFolder 1 PLOT open { 1 } hide

  CreateLine line \
    help key_mainchain \
    message "Use main chain atoms only in plots, default is all atoms (MAINCHAIN)" \
    widget MAINCHAIN \
    label "Use main chain atoms only when calculating average values"

#=PARAMETERS2===========================================================

  OpenFolder 2 RIGIDBODY open { 1 } hide

  CreateLine line \
    help key_dubins \
    message "Use this to increase or decrease sampling of Delta (DUBINS)" \
    label "Divide Delta matrix (PSOUT) into " \
    widget PS_BINS \
    label " bins. " 

  CreateLine line \
    help key_durange \
    message "Specify form of Delta distribution plot (DURANGE)" \
    label "Distribution of Delta values over range " \
    widget DURANGE \
    message "Specify form of Delta distribution plot (DUBINS)" \
    label "divided into " \
    widget DIST_BINS \
    label "bins. " 

#=PARAMETERS3===========================================================

  OpenFolder 3 FITTLS open { 1 } hide

  CreateLine line \
    help key_tlscycles \
    message "Number of TLS fitting cycles (default OK) (TLSCYCLES)" \
    label "Do " \
    widget TLSCYCLES  \
    label "cycles of TLS fitting. "

}

