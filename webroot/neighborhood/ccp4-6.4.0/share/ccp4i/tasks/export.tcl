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
# export.tcl --
#
# Convert mtz file to external hkl format
#
# CCP4Interface 
#
# =======================================================================

#------------------------------------------------------------------------------
proc export_setup { typedefVar arrayname } {
#------------------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  set typedef(_export_format)     { menu {      CIF
						XPLOR
						CNS
                                                MULTAN
                                                SHELX
                                                SHELXDiff
                                                TNT
                                                MAIN
						SCALEPACK
						USER } }

  set typedef(_export_dum) { menu { "generic real" "generic int" \
                                    "FP" "SIGFP" "FPH" "SIGFPH" \
                                    "FC" "PHIC" } \
                                  { real integer FP SIGFP FPH SIGFPH \
				    FC PHIC }   }

  set typedef(_export_anomalous) { menu { "no anomalous data" \
					"from anomalous difference Fs" \
					"anomalous Fs" \
					"anomalous Is" } \
				{ NO DIFFERENCE ANOMALOUS INTENSITIES } }

  return 1

}


#------------------------------------------------------------------------------
proc  export_run { arrayname } {
#------------------------------------------------------------------------------
  upvar #0 $arrayname array

  set format  [GetValue $arrayname OUTPUT_FORMAT ]
  set array(LABIN) ""

  if { [StringSame $format CIF ] } {
    if { [regexp "^data_\$" $array(CIF_DATA_NAME)] || \
         ![regexp "^data_.+" $array(CIF_DATA_NAME)] }  {
      WarningMessage "The data block name

\"$array(CIF_DATA_NAME)\"

is not a valid CIF data block name.
Use \"data_<name>\"."
      return 0
    }
  }

  if { [StringSame $format USER ] && $array(NCOL) > 0 }  {

    set ni 0; set nr 0
    set array(LABIN) ""
    for { set n 1 } { $n <= $array(NCOL) } { incr n } {
      if { [StringSame $array([Indxv DUM_FORMAT $n]) FP ] } {
	set array(FP) $array([Indxv DUM_COLUMN $n])
	append array(LABIN) " FP"
      } elseif { [StringSame $array([Indxv DUM_FORMAT $n]) SIGFP ] } {
	set array(SIGFP) $array([Indxv DUM_COLUMN $n])
	append array(LABIN) " SIGFP"  
      } elseif { [StringSame $array([Indxv DUM_FORMAT $n]) FPH ] } {
	set array(FPH) $array([Indxv DUM_COLUMN $n])
	append array(LABIN) " FPH"   
      } elseif { [StringSame $array([Indxv DUM_FORMAT $n]) SIGFPH ] } {
	set array(SIGFPH) $array([Indxv DUM_COLUMN $n])
	append array(LABIN) " SIGFPH"  
      } elseif { [StringSame $array([Indxv DUM_FORMAT $n]) FC ] } {
	set array(FC) $array([Indxv DUM_COLUMN $n])
	append array(LABIN) " FC"  
      } elseif { [StringSame $array([Indxv DUM_FORMAT $n]) PHIC ] } {
	set array(PHIC) $array([Indxv DUM_COLUMN $n])
	append array(LABIN) " PHIC"  
      } elseif { [StringSame $array([Indxv DUM_FORMAT $n]) "generic real" ] } {
        incr nr; set array(DUM$nr) $array([Indxv DUM_COLUMN $n])
        append array(LABIN) " DUM$nr"
        lappend array(PARAM_LIST) "DUM$nr"
      } else {
        incr ni; set array(IDUM$ni) $array([Indxv DUM_COLUMN $n])
        append array(LABIN) " IDUM$ni"
        lappend array(PARAM_LIST) "IDUM$ni"
      }
    }

  } else  {
#set array(LABIN) "FP SIGFP FPH SIGFPH FC W PHIC FOM PHIB FPART PHIPART DP SIGDP FREE ISYM Fp SIGFp Fm SIGFm Ip SIGIp Im SIGIm"
    switch $format \
    XPLOR {
       set array(LABIN) "FP SIGFP FPH SIGFPH FC W PHIC FOM PHIB HLA HLB HLC HLD FPART PHIPART DP SIGDP FREE ISYM Fp SIGFp Fm SIGFm"
    } CNS {
       set array(LABIN) "FP SIGFP FPH SIGFPH FC W PHIC FOM PHIB HLA HLB HLC HLD FPART PHIPART DP SIGDP FREE ISYM Fp SIGFp Fm SIGFm"
    } CIF {
      set array(LABIN) "FP SIGFP FC W PHIC FOM Ip SIGIp Im SIGIm DP SIGDP FREE PHIB HLA HLB HLC HLD"
    } SCALEPACK {
      set array(LABIN) "Ip SIGIp Im SIGIm"
    } MAIN {
      set array(LABIN) "FP SIGFP PHIB FOM FC"
    } TNT {
      set array(LABIN) "FP SIGFP PHIB FOM FREE"
    } SHELX {
      set array(LABIN) "I SIGI FP SIGFP FPH SIGFPH FREE DP SIGDP"
    } SHELXDiff {
      set array(LABIN) "FP SIGFP FPH SIGFPH FREE DP SIGDP"
# Multan
    } default {
      set array(LABIN) "FP SIGFP FPH SIGFPH FREE DP SIGDP"
    }
  }
  return 1
}

#------------------------------------------------------------------------------
proc ExportColumns { arrayname counter } {
#------------------------------------------------------------------------------

# This is the stuff which is usually done by CreateLabin

  set fileline [GetWidget $arrayname HKLIN]
  set fileline [string range $fileline 0 [expr [string length $fileline ] -4 ] ]
  set file_status [CheckFileInput $arrayname HKLIN read ]

  CreateLine line \
    message "Select label columns in the order they appear in output (LABIN)" \
    help labin \
    label "Label column" \
    widget DUM_COLUMN \
    label "processed as" \
    widget DUM_FORMAT 

  add_file_command $fileline "SetLabin $arrayname HKLIN \
                [Indxv DUM_COLUMN $counter] {} "
  if { $file_status } { SetLabin $arrayname HKLIN  [Indxv DUM_COLUMN $counter] {} }

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
proc export_task_window { arrayname } {
#-----------------------------------------------------------------------

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Convert From MTZ" "From MTZ" \
	[ list "MTZ File Labels" \
        "User Defined Output Format" \
	"CIF Format Details" \
        "Exclude Reflections" \
	"Infrequently Used Options" ] ] == 0 } return

  SetProgramHelpFile "mtz2various"


#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE


  CreateLine line \
    message "Select file format (OUTPUT)" \
    help output \
     label "Convert MTZ to " \
     widget OUTPUT_FORMAT \
     label "format"

#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
       HKLIN DIR_HKLIN \
       -fileout EXPORT_FILE DIR_EXPORT_FILE --  \
       -setlabin EXCLUDE_FREER_LABEL [list FREE FreeR FreeR_flag] \
	-setfileparam resolution_min EXCLUDE_RESOLUTION_MIN \
        -setfileparam resolution_max EXCLUDE_RESOLUTION_MAX \
	-command "set_cif_data_name $arrayname"

  CreateOutputFileLine line \
      "Enter name for output HKL file" \
      "HKL out" \
      EXPORT_FILE DIR_EXPORT_FILE

#=====================================================================

  OpenFolder 1 OUTPUT_FORMAT hide USER open

  CreateLine line \
    message "Not all formats require all columns. See documentation for details." \
    help output \
     label "Not all columns are required. Select Unassigned to skip a column." -italics

  CreateLabinLine line \
    "Protein experimental intensities (I) and sigma (SIGI)" \
     HKLIN I I  [list I IMEAN] \
     -sigma SIGI SIGI [list SIGI SIGIMEAN]  \
     -toggle_display OUTPUT_FORMAT open SHELX

  CreateLabinLine line \
    "Protein experimental amplitude (FP) and optional sigma (SIGFP)" \
     HKLIN FP FP  [list F FP] \
     -sigma SIGFP SIGFP  {} \
     -toggle_display OUTPUT_FORMAT hide SCALEPACK

  CreateLabinLine line \
    "Derivative experimental amplitude (FPH) and optional sigma (SIGFPH)" \
     HKLIN FPH FPH [list FPH] \
     -sigma SIGFPH SIGFPH  {} \
     -toggle_display OUTPUT_FORMAT hide [list CIF SCALEPACK MAIN TNT]

  CreateLabinLine line \
    "Calculated amplitude (FC) and optional FOM" \
     HKLIN FC FC [list FC] \
     -sigma FOM FOM  {FOM} \
     -toggle_display OUTPUT_FORMAT hide  [list SHELX SHELXDiff MULTAN TNT SCALEPACK]


  CreateLabinLine line \
    "Anomalous data - will be converted to F(+) and F(-) (DP)" \
    HKLIN DP DP [list DP] \
    -sigma SIGDP SIGDP [list SIGDP] \
    -toggle_display OUTPUT_FORMAT hide [list SCALEPACK MAIN TNT]

  OpenSubFrame frame -toggle_display OUTPUT_FORMAT hide \
		[list SHELX SHELXDiff MULTAN TNT CIF SCALEPACK MAIN]

  CreateLabinLine line \
    "Anomalous data" \
    HKLIN F(+) Fp [list F(+)] \
    -sigma SIGF(+) SIGFp [list SIGFp] 

  CreateLabinLine line \
    "Anomalous data" \
    HKLIN F(-) Fm [list F(-)] \
    -sigma SIGF(-) SIGFm [list SIGFm]

  CloseSubFrame

  OpenSubFrame frame -toggle_display OUTPUT_FORMAT hide \
		[list SHELX SHELXDiff MULTAN TNT XPLOR CNS MAIN]

  CreateLabinLine line \
    "Anomalous intensity data" \
    HKLIN I(+) Ip [list I(+)] \
    -sigma SIGI(+) SIGIp [list SIGIp] 

  CreateLabinLine line \
    "Anomalous intensity data" \
    HKLIN I(-) Im [list I(-)] \
    -sigma SIGI(-) SIGIm [list SIGIm]

  CloseSubFrame



  CreateLabinLine line \
    "Calculated phases(PHIC) and optional weight (W)" \
     HKLIN PHIC PHIC {} \
     -sigma Weight W  {W} \
     -toggle_display OUTPUT_FORMAT hide  [list SHELX SHELXDiff MULTAN TNT SCALEPACK MAIN]
     

  CreateLabinLine line \
    "Best experimental phases (PHIB)" \
    HKLIN "Best PHI" PHIB {NULL} \
    -toggle_display OUTPUT_FORMAT hide [list SHELX SHELXDiff MULTAN SCALEPACK TNT]

  CreateLabinLine4 line \
      "Hendrickson-Lattman coefficients" \
      HKLIN        "HLA" HLA  [list HLA] \
      -dependent   "HLB" HLB  [list HLB] \
      -dependent   "HLC" HLC  [list HLC] \
      -dependent   "HLD" HLD  [list HLD] \
    -toggle_display OUTPUT_FORMAT hide [list SHELX SHELXDiff MULTAN SCALEPACK MAIN TNT]

  CreateLabinLine line \
    "Free R flag" \
    HKLIN "FreeR" FREE {NULL} \
	-toggle_display OUTPUT_FORMAT hide [list SCALEPACK MAIN]


#--------------------------------------------------------------------
  OpenFolder 2 OUTPUT_FORMAT open USER hide


  CreateLine line \
    message "Enter Fortran format with enclosing brackets & single quotes(OUTPUT USER)" \
    help output_user \
    label "Ouput Fortran format" \
    widget USER_FORMAT -expand

  CreateLine line \
    message "(LABIN)" \
    label "MTZ columns in same order as output file" \
	-italic

    CreateExtendingFrame NCOL ExportColumns \
    "Add/remove line to output extra column from MTZ file " \
    "Add column label"  \
              [list  DUM_COLUMN \
                DUM_FORMAT  ]

#-----------------------------------------------------------------CIF format

  OpenFolder 3 OUTPUT_FORMAT open CIF hide

  CreateLine line \
    message "Enter name for the CIF file data block" \
    help output \
    label "CIF file data block name" \
    widget CIF_DATA_NAME -width 25



#=EXCLUDE=REFLECTIONS======================================================

  OpenFolder 4 closed

  source [SearchPath TOP tasks mtz2var_exclude.tcl]


#=Unusual Options========================================================

  OpenFolder 5 closed

  CreateLine line \
	message "Ouput FP and SIGFP as intensities (FSQUARED)" \
        help fsquared \
	widget FSQUARED \
	-toggleon \
	label "Output FP as intensity scaled by (SCALE)" \
	help scale \
	widget SCALE_FACTOR

  CreateLine line \
	message "Output any missing reflections (MISS) " \
        help miss \
	widget MISS \
	-toggleon \
	label "Output missing reflections with MNF value " \
	widget MISS_VALUE

  CreateLine line \
	message "List monitoring information to log file (MONITOR) " \
	help monitor \
	widget MONITOR \
	-toggleon \
	label "Output data to log for every" \
	widget MONITOR_NMON \
	label "th reflection"
	
}

