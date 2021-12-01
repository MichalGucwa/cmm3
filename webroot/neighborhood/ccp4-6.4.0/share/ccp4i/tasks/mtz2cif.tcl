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
# mtz2cif.tcl --
#
# Convert mtz file to mmCIF format for deposition
#
# CCP4Interface 
#
# =======================================================================

#------------------------------------------------------------------------------
proc mtz2cif_setup { typedefVar arrayname } {
#------------------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  return 1
}


#------------------------------------------------------------------------------
proc  mtz2cif_run { arrayname } {
#------------------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(LABIN) "FP SIGFP I SIGI FC PHIC PHIB HLA HLB HLC HLD FOM FREE"
  if $array(ANOMALOUS) { 
      append array(LABIN) " DP SIGDP Fp SIGFp Fm SIGFm Ip SIGIp Im SIGIm" 
  }
  return 1
}

#-----------------------------------------------------------------------
proc set_cif_data_name { arrayname } {
#-----------------------------------------------------------------------
# Set a default name for the cif data 
  upvar #0 $arrayname array

  if { $array(CIF_DATA_NAME) != {} } { return }
  set array(CIF_DATA_NAME)  data_
  append array(CIF_DATA_NAME) [file rootname $array(HKLIN)]
}


#-----------------------------------------------------------------------
proc mtz2cif_task_window { arrayname } {
#-----------------------------------------------------------------------

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Convert to mmCIF" "To mmCIF" \
	[ list "MTZ File Labels" \
        "CIF Format Details" \
        "Options to flag reflections" ] ] == 0 } return

  SetProgramHelpFile "mtz2various"


#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
        message "Do you wish to deposit anomalous data" \
	help labin \
        widget ANOMALOUS \
        label "include anomalous data" 

#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
       HKLIN DIR_HKLIN \
       -fileout EXPORT_FILE DIR_EXPORT_FILE --  \
       -setlabin FREER_LABEL [list FREE FreeR FreeR_flag] \
	-setfileparam resolution_min EXCLUDE_RESOLUTION_MIN \
        -setfileparam resolution_max EXCLUDE_RESOLUTION_MAX \
	-command "set_cif_data_name $arrayname"

  CreateOutputFileLine line \
      "Enter name for output mmCIF file" \
      "CIF out" \
      EXPORT_FILE DIR_EXPORT_FILE

#=====================================================================

  OpenFolder 1 

  CreateLabinLine line \
    "Protein experimental amplitude (FP) and sigma (SIGFP)" \
     HKLIN FP FP  [list F FP] \
     -sigma Sigma SIGFP  [list SIGF SIGFP]

  CreateLabinLine line \
    "Protein experimental intensity (I) and sigma (SIGI)" \
     HKLIN I I  [list I IMEAN] \
     -sigma Sigma SIGI [list SIGI SIGIMEAN]

  CreateLabinLine line \
    "Calculated amplitude (FC) and calculated phase (PHIC)" \
     HKLIN FC FC [list FC] \
     -sigma PHIC PHIC  [list PHIC]

  CreateLabinLine line \
    "Experimental phase (PHIB) and associated figure of merit (FOM)" \
     HKLIN PHIB PHIB {} \
     -sigma FOM FOM {}

  CreateLabinLine4 line \
	"Hendrickson-Lattman coefficients"  \
	HKLIN "HLA" HLA  [list HLA] \
	-sigma "HLB" HLB {} \
        -dependent "HLC" HLC {} \
	-sigma "HLD" HLD {}
 
  OpenSubFrame frame -toggle_display ANOMALOUS hide 0

  CreateLabinLine line \
    "Anomalous data - will be converted to F(+) and F(-) (DP)" \
    HKLIN DP DP [list DP] \
    -sigma SIGDP SIGDP [list SIGDP] 

  CreateLabinLine4 line \
    "Anomalous data F(+) and F(-)" \
    HKLIN F(+) Fp [list F(+)] \
    -sigma SIGF(+) SIGFp [list SIGF(+)] \
    -dependent F(-) Fm [list F(-)] \
    -sigma SIGF(-) SIGFm [list SIGF(-)]

  CreateLabinLine4 line \
    "Anomalous intensity data I(+) and I(-)" \
    HKLIN I(+) Ip [list I(+)] \
    -sigma SIGI(+) SIGIp [list SIGI(+)] \
    -dependent I(-) Im [list I(-)] \
    -sigma SIGI(-) SIGIm [list SIGI(-)]

  CloseSubFrame

  CreateLabinLine line \
    "Free R flag" \
    HKLIN "FreeR" FREE {} 

#-----------------------------------------------------------------CIF format

  OpenFolder 2 

  CreateLine line \
    message "Enter name for the CIF file data block" \
    help output \
    label "CIF file data block name" \
    widget CIF_DATA_NAME -width 25



#=EXCLUDE=REFLECTIONS======================================================

  OpenFolder 3 closed

  CreateLine line \
    message "Flag reflections below (l) or above (h) resolution limit in \
                  Angstrom (RESOLUTION)" \
    help resolution \
    widget EXCLUDE_RESOLUTION \
	-toggleon \
    label "Resolution less than" \
    widget EXCLUDE_RESOLUTION_MIN \
    label "Angstrom or greater than" \
    widget EXCLUDE_RESOLUTION_MAX \
    label "Angstrom"

  CreateLine line \
    message "Flag reflections (f) in set selected for FreeR \
                             calculation (FREERFLAG&FREE)" \
    help include_freer \
    widget FREER \
    label "FreeR label" \
    widget FREER_LABEL \
    label "of value " \
    widget FREER_VALUE

  CreateLine line \
   message "Flag FPs (<) which are small compared to sigma FP (EXCLUDE SIGP)" \
    help exclude_sigp \
    widget EXCLUDE_SIGP \
	-toggleon \
    label "FP less than n * sigmaF where n is " \
    widget EXCLUDE_SIGP_FACTOR
  	
}

