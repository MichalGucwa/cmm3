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
# tlsanl.tcl --
#
# CCP4Interface 
#
# =======================================================================

#---------------------------------------------------------------------
proc tlsanl_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
upvar #0  $typedefVar typedef

set typedef(_tlsanl_isoout) {  menu { "total B factor"
                               "residual B factor"
                               "TLS part of B factor" }
                             { "FULL"
                               "RESI"
                               "TLSC" } }

set typedef(_tlsanl_type) { menu {  "Refmac"
				    "Anisoanl"
                                    "Restrain"}
                                 {  "REFMAC"
                                    "ANISOANL"
                                    "RESTRAIN" } }

set typedef(_tlsanl_axes) { menu {  "Molscript"
				    "mmCIF"}
                                 {  "MOLSCRIPT"
                                    "MMCIF" } }

  return 1
}

#-------------------------------------------------------------------------
proc tlsanl_run { arrayname } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [GetValue $arrayname TLSANL_TYPE] == "REFMAC" } {
    set array(BRESID) 1
  } elseif { [GetValue $arrayname TLSANL_TYPE] == "ANISOANL" } {
    set array(BRESID) 1
  } else {
    set array(BRESID) 0
  }

  if $array(AXES) {
    if $array(SKTTLS) {
      set array(OUTPUT_FILES) "XYZOUT AXESOUT SKTOUT"
    } else {
      set array(OUTPUT_FILES) "XYZOUT AXESOUT"
    }
  } else {
    if $array(SKTTLS) {
      set array(OUTPUT_FILES) "XYZOUT SKTOUT"
    } else {
      set array(OUTPUT_FILES) "XYZOUT"
    }
  }

  return 1
}
 
#----------------------------------------------------------------
proc tlsanl_task_window { arrayname } {
#----------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
    	"Analyse TLS parameters" "tlsanl" \
	[ list "AXES plot" "Other options" ] ] == 0 } return

  SetProgramHelpFile "tlsanl"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
        message "Specify source of TLS file" \
	help bresid \
        label "Analyse TLS parameters from " \
        widget TLSANL_TYPE 

  CreateLine line \
        message "Specify what is included in output Bs (ISOOUT)" \
	help isoout \
        label "Output coordinate file (XYZOUT) should contain " \
        widget ISOOUT

  CreateLine line \
        message "Request molscript or mmCIF file containing axes (AXES)" \
	help axes \
        widget AXES \
        label "Output file containing the axes for translation, libration, etc." 
  CreateLine line \
        message "Write SKTTLS validation to a separate log file (SKTTLS)" \
	help skttls \
        widget SKTTLS \
        label "Output file containing the SKTTLS validation report" 

#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter the name of TLS file output from Refmac (TLSIN)" \
      "TLS file" \
       TLSIN DIR_TLSIN \
     -fileout SKTOUT DIR_SKTOUT "_skttls" 

  CreateInputFileLine line \
      "Enter the name of the coordinate file from Refmac (XYZIN)" \
      "PDB file" \
       XYZIN DIR_XYZIN \
     -fileout XYZOUT DIR_XYZOUT "_tlsanl" 

  CreateOutputFileLine line \
        "Output coordinate file" \
        "PDB out" \
        XYZOUT DIR_XYZOUT

  OpenSubFrame frame -toggle_display AXES open { 1 } 

  CreateOutputFileLine line \
        "Output AXES file" \
        "AXES" \
        AXESOUT DIR_AXESOUT

  CloseSubFrame

   OpenSubFrame frame -toggle_display SKTTLS open { 1 } 

  CreateOutputFileLine line \
        "Output SKTTLS file" \
        "SKTTLS out" \
        SKTOUT DIR_SKTOUT

  CloseSubFrame

#=PARAMETERS===========================================================

  OpenFolder 1 AXES open { 1 } hide

  CreateLine line \
    help axes \
    message "Set output format for axes (AXES)" \
    label "Output axes in " \
    widget AXES_FORMAT \
    label " format"

  CreateLine line \
    help axes \
    message "Set scale factor for axes length (AXES)" \
    label "Lengths of axes included in AXES file are scaled by " \
    widget AXES_SCALE

#=OTHER OPTIONS===========================================================

  OpenFolder 2

  CreateLine line \
        message "Request analysis of derived atomic ADPs (ANISO)" \
	help aniso \
        widget ANISO \
        label "Analyse derived atomic ADPs and flag non-positive definite ones" 

}

