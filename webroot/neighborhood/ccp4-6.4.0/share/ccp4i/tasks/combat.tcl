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
# combat.tcl --
#
# Import a formatted reflection file (eg from DENZO) and create multirecord
#   MTZ file
#
# CCP4Interface 
# Created Oct97 by Liz Potterton
#
# =======================================================================


#------------------------------------------------------------------------
proc combat_setup { typedefname arrayname }  {
#------------------------------------------------------------------------

  upvar #0 $typedefname typedef

  set typedef(_rotaprep_format)	{ menu	{	"Standard MTZ Amplitudes" \
						"Standard MTZ Intensities" \
						"Denzo" \
						"Scalepack NoMerge (no partials)" \
						"Scalepack NoMerge (original indices)" \
						"Rigaku Texsan" \
						"Rigaku Texhkl" \
						"Rigaku Datred" \
						"MUI Xentronics&Xengen" \
						"MUF Xentronics&Xengen" \
						"XDS ASCII from Correct" \
						"Kabsch XDS Unique" \
						Saint \
						"Scalepack" \
						"RAxis Readbf of Mergefile" \
						"Madnes for050" \
						"Weiss (Japanese)" \
						"User Defined" }
					{	"MTZF" \
						MTZI \
						"DENZO" \
						"SCAL_NM" \
						"SCAL_NM2" \
						"TEXSAN" \
						"TEXHKL" \
						"DATRED_RIGAKU" \
						"MUI" \
						"MUF" \
						"XDSASCII" \
						"XDSUNIQUE" \
						SAINT \
						"SCALEPACK" \
						"RAXISDUMP" \
						"JIMS" \
						"WEISS"  \
						"USER" } }

set typedef(_rotaprep_label)  { menu {	H K L M BATCH I SIGI \
				F SIGF IPR SIGIPR FRACTION } }

return 1

}

# procedure run before script is written

#---------------------------------------------------------------------
proc combat_run { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  set format [GetValue $arrayname FORMAT]

  if [regexp MTZ $format ] {
    set array(HKLIN) $array(MTZIN)
    set array(DIR_HKLIN) $array(DIR_MTZIN)
    if [regexp MTZF $format ] {
      if { $array(USE_ANOMALOUS) } {
        set array(LABIN) "Fp SIGFp Fm SIGFm"
      } else {
        set array(LABIN) "F SIGF"
      }
    } else {
      if { $array(USE_ANOMALOUS) } {
        set array(LABIN) "Ip SIGIp Im SIGIm"
      } else {
        set array(LABIN) "I SIGI"
      }
    }
  }

  if {  [lsearch [list DENZO SCAL_NM SCAL_NM2 SAINT RAXISDUMP ] $format] >= 0 } {
    set array(USEBATCH) 0
  } elseif { [lsearch [list WEISS TEXSAN ] $format] < 0 } {
    set array(USEBATCH) 1
  }

  if { [lsearch [list DENZO SCAL_NM SCAL_NM2 SAINT RAXISDUMP WEISS TEXSAN ] \
                                       $format ] < 0 } {
    set array(ADDBATCH) ""
    set array(MISBATCH) ""
  }

  if { ![SetHarvestParams $arrayname {}  -run] } { return 0 }

  return 1
}


#=======================================================================
proc combatColumnsFrame { arrayname i } {
#=======================================================================

    CreateLine line  \
        message "Data type and label for each input field (LABOUT)"   \
	help label \
        label $i                                                        \
        widget COLUMN_NAME \
        format template "COLUMNS"
	
}


#=CREATE=WINDOW=AND=SUBWINDOWS===========================================

proc combat_task_window { arrayname } {

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Combat - Import Unscaled Data" "Combat" \
	[ list "MTZ Project & Dataset Names" \
	"Extra Information for MTZ File" \
        "Edit or Transform Input Data" \
	"Detailed Specification of Import File Format" \
	"Log File Output" ] ] == 0 } return

  SetHarvestParams $arrayname {}  -init


#=PROTOCOL==============================================================
# Choose format of file to be read

  OpenFolder protocol

  CreateTitleLine line TITLE

  CreateLine format_input  \
	message "Choose input reflection file format(INPUT) "	\
        help description \
	label "Import file in " \
	widget FORMAT \
	label " format and create multirecord MTZ file"
	
  CreateLine warning \
	message "" \
	label "Warning: the option'Denzo' may cause serious trouble further down the line. Do not use it unless you know exactly what you are doing." \
	      -italic \
	toggle_display FORMAT open DENZO

$warning.l1 configure -foreground "red"

#=FILES================================================================

# frame to enter input file name - note there are two different input lines
# depending on whether input format is mtz or other - only one line is 
# displayed at a time

  OpenFolder file

  CreateInputFileLine line \
      "Enter input reflection file name (HKLIN)" \
        "In" \
       MTZIN DIR_MTZIN \
       -fileout HKLOUT  DIR_HKLOUT -- \
       -setfileparam space_group_name SPACE_GROUP \
       -setfileparam cell_1 CELL_1 \
       -setfileparam cell_2 CELL_2 \
       -setfileparam cell_3 CELL_3 \
       -setfileparam cell_4 CELL_4 \
       -setfileparam cell_5 CELL_5 \
       -setfileparam cell_6 CELL_6 \
       -setfileparam pname HARVEST_PNAME \
       -setfileparam xname HARVEST_XNAME \
       -setfileparam dname HARVEST_DNAME \
       -toggle_display FORMAT open [list MTZF MTZI ]

    CreateLine line \
      message "Set whether input is F, or F(+)/F(-) pair" \
      widget USE_ANOMALOUS \
      label "Input reflection data are anomalous pairs" \
      toggle_display FORMAT open [list MTZF MTZI]

    OpenSubFrame frame -toggle_display FORMAT open MTZF

    CreateLabinLine line \
    "Choose amplitude (F) and optional sigma (SIGF)" \
     MTZIN "F" F  {} \
     -sigma "Sigma  " SIGF  {} \
     -toggle_display USE_ANOMALOUS open 0

    CreateLabinLine line \
    "Choose amplitude (F(+)) and optional sigma (SIGF(+))" \
     MTZIN "F(+)" Fp  {} \
     -sigma "SigmaF(+)  " SIGFp  {} \
     -toggle_display USE_ANOMALOUS open 1

    CreateLabinLine line \
    "Choose amplitude (F(-)) and optional sigma (SIGF(-))" \
     MTZIN "F(-)" Fm  {} \
     -sigma "SigmaF(-)  " SIGFm  {} \
     -toggle_display USE_ANOMALOUS open 1

    CloseSubFrame

    OpenSubFrame frame -toggle_display FORMAT open MTZI

    CreateLabinLine line \
    "Choose intensity (I) and optional sigma (SIGI)" \
     MTZIN "I" I  {} \
     -sigma "Sigma  " SIGI  {} \
     -toggle_display USE_ANOMALOUS open 0

    CreateLabinLine line \
    "Choose intensity (I(+)) and optional sigma (SIGI(+))" \
     MTZIN "I(+)" Ip  {} \
     -sigma "SigmaI(+)  " SIGIp  {} \
     -toggle_display USE_ANOMALOUS open 1

    CreateLabinLine line \
    "Choose intensity (I(-)) and optional sigma (SIGI(-))" \
     MTZIN "I(-)" Im  {} \
     -sigma "SigmaI(-)  " SIGIm  {} \
     -toggle_display USE_ANOMALOUS open 1

    CloseSubFrame


  CreateInputFileLine line \
      "Enter input reflection file name (HKLIN)" \
        "In" \
       HKLIN DIR_HKLIN \
       -fileout HKLOUT  DIR_HKLOUT -- \
       -toggle_display FORMAT hide [list MTZF MTZI ]


  CreateOutputFileLine line \
      "Enter output MTZ file name (HKLOUT)" \
       "Out" \
       HKLOUT DIR_HKLOUT \
       -info

#=PARAMETERS==========================================================

  OpenFolder 1 
  CreateHarvestLine line -noharvest

#-------------------------------------------------------------------------

  OpenFolder 2 FORMAT closed XDSASCII open

  CreateLine  line  \
	message "Enter the number code for the space group (SYMMETRY) "	\
	help "symmetry" \
	label "Space group" \
	widget SPACE_GROUP -oblig

  CreateLine  line  \
	message "Enter cell lengths(Angstrom) and angles(degs) (CELL)" \
        help "cell" \
	label "Cell dimensions " \
	widget CELL_1  -oblig \
	widget CELL_2  -oblig \
	widget CELL_3  -oblig \
	widget CELL_4  -oblig \
	widget CELL_5  -oblig \
	widget CELL_6  -oblig 

  CreateLine line \
    message "Enter detector coordinate limits (required by Scala detector scaling options (DETECTOR)" \
    help detector \
    label "Detector limits: xmin" \
    widget DETECTOR_XMIN \
    label "  xmax" \
    widget DETECTOR_XMAX \
    label "  ymin" \
    widget DETECTOR_YMIN \
    label "  ymax" \
    widget DETECTOR_YMAX

  CreateLine line \
    message "Enter a wavelength to be assigned to the output dataset (WAVELENGTH)" \
    label "Wavelength" \
    widget WAVELENGTH \
    label "(Angstroms)"

  CreateLine line \
    message "Enter a batch number for the input reflections (BATCH)" \
    label "Batch number to apply to input reflections" \
    widget BATCH -oblig \
    toggle_display FORMAT hide [list DENZO SCAL_NM SCAL_NM2 SAINT RAXISDUMP ]

  CreateLine line \
    message "Enter a batch number for the input reflections (BATCH)" \
    widget USEBATCH \
    label "Override input batch number assignment & set to" \
    widget BATCH \
    toggle_display FORMAT open [list WEISS TEXSAN ]

  CreateLine line \
    message "Transform input batch numbers (ADDBATCH)" \
    label "Add offset to input batch numbers" \
    widget ADDBATCH \
    toggle_display FORMAT open [list DENZO SCAL_NM SCAL_NM2 SAINT WEISS TEXSAN RAXISDUMP ]

  CreateLine line \
    message "Space separated list to be exclude form MTZ header (MISBATCH)" \
    label "Missing batches" \
    widget MISBATCH \
	-expand \
    toggle_display FORMAT open [list DENZO SCAL_NM SCAL_NM2 SAINT WEISS TEXSAN RAXISDUMP ]

  CreateLine line \
    message "Use anomalous data (ANOMALOUS)" \
    widget ANOMALOUS \
    label "Use anomalous data" \
    toggle_display FORMAT open SCALEPACK


#==EDIT / TRANSFORM INPUT DATA=========================================

  OpenFolder 3 closed

  CreateLine line \
    message "Set resolution limits on data (RESOLUTION)" \
    help "resolution" \
    widget RESOLUTION_RANGE \
	-toggleon \
    label "Set resolution limits to min" \
    widget RESOLUTION_MIN \
    label "and max" \
    widget RESOLUTION_MAX

  CreateLine line \
    message "Multiply input intensities by scaling factor (SCALE)" \
    label "Scale input intensities by" \
    widget SCALE

  CreateLine line \
    message  "Reindex the reflections by applying transformation (REINDEX)" \
    widget REINDEX \
	-toggleon \
    label "Reindex transformation: h=" \
    widget REINDEX_H \
    label "  k=" \
    widget REINDEX_K \
    label "  l=" \
    widget REINDEX_L

  CreateLine line \
    label "Exclude the following reflections from the output file"

 CreateExtendingFrame N_REJECTS HklRejects \
        "Define reflections to be excluded from file" \
        "Add Reject" \
      [list  REJECT1_H \
        REJECT1_K \
        REJECT1_L \
        REJECT2_H \
        REJECT2_K \
        REJECT2_L ]

#==DETAILED=FORMAT=SPEC================================================

  OpenFolder 4 FORMAT open USER closed

  CreateLine  line  \
		message "Fortran specification of the format (FORMAT)"   \
                help "format" \
		label "Fortran format"					\
		widget FORTRAN_FORMAT  -width 60
		
  CreateLine line \
	label " " \
        label "Data type and label for input fields"

#Frame to enter the column types

  CreateLineTemplate "COLUMNS" {0.0 0.04 0.5 }

  CreateExtendingFrame NCOLS combatColumnsFrame \
    "Add/remove  line to define extra column in MTZ file " \
    "Add line"  \
    [list COLUMN_NAME ]


  OpenFolder 5 closed

   CreateLine line \
     message "Write diagnostic to log file (MONITOR)" \
     help "monitor" \
     widget USE_MONITOR \
	-toggleon \
     label "Monitor every" \
     widget MONITOR \
     label "reflection"
}
