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
# truncate.tcl --
#
# task interface for truncate program 
# Also uses rwcontents
#
# CCP4Interface 
#
# =======================================================================

#-------------------------------------------------------------------------
proc truncate_run { arrayname } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array

  truncate_anomalous $arrayname

  if { ![SetHarvestParams $arrayname HKLIN  -run] } { return 0 } 
  
  if { $array(CONTENTS_MODE) == "PDB" } {
    set array(INPUT_FILES) "HKLIN CONTENTS_PDB"
  } else {
    set array(INPUT_FILES) "HKLIN"
  }

  if { $array(INPUT_DATA) == "AMPLITUDES" } {
      set array(OUTPUT_FILES) ""
      set array(USE_LABOUT) 0
  }

  if { $array(USE_LABOUT) } {
    if { $array(ANOMALOUS) } {
      set array(LABOUT) "IMEAN SIGIMEAN Ip SIGIp Im SIGIm F SIGF DANO SIGDANO Fp SIGFp Fm SIGFm ISYM"
    } else { 
      set array(LABOUT) "IMEAN SIGIMEAN F SIGF"
    }
  }

  return 1
}


#---------------------------------------------------------------
proc truncate_setup { typedefVar arrayname } {
#---------------------------------------------------------------

  upvar #0 $typedefVar typedef

set typedef(_truncate_method)	{ menu	{	"French&Wilson truncate"
						"simple square-root" }
					{	WILSON
						SIMPLE } }


set typedef(_truncate_input)	{ menu {	"are intensities from Scala"
						"intensities with anomalous data"
						"intensities without anomalous data"
                                                "are amplitudes" }
					{	SCALA
						ANOMALOUS
						NO_ANOMALOUS
                                                AMPLITUDES } }


set typedef(_truncate_content_mode) { menu {  	"number of residues" \
						"PDB file of contents" \
						"atom count" } 
					   {	"NRES" \
						"PDB" \
						"COUNT" } }

set typedef(_truncate_range_mode)	{ menu { "set by program" \
						"set number of bins" \
						"set bin width" } 
						{ "default" \
						"NUMBER" \
						"WIDTH" } }

set typedef(_truncate_header)		{ menu { "no" \
						"brief" \
						"brief&history" \
						"all" } 
						{ "NONE" \
						"BRIEF" \
						"HISTORY" \
						"ALL" } }

set typedef(_truncate_batch) 		{ menu { "no" \
						"titles only of" \
						"titles&orientation of" }
						{ NONE \
						BATCH \
						ORIENTATION } }

set typedef(_truncate_falloff_plot)  { menu { horizontally vertically "no plot output" } { PLTX PLTY {} } }

  return 1

}
						

#--------------------------------------------------------------------------------
proc TruncateContents { arrayname counter } {
#--------------------------------------------------------------------------------
  upvar #0 $arrayname array

    CreateLine line \
    message "Enter type and number of atoms in asymmetric unit (CONTENTS)" \
    help "contents" \
    label "Contents element type" \
    widget CONTENTS_ATOM_TYPE \
    label "number of atoms" \
    widget CONTENTS_ATOM_COUNT

}

#--------------------------------------------------------------------------
proc truncate_options {arrayname } {
#--------------------------------------------------------------------------

  CreateLine line \
    message "Use truncate protocol or simple square root method (TRUNCATE)" \
    help "truncate" \
    label "Use" \
    widget APPLY_TRUNCATE \
    label "protocol to generate SFs"

  CreateLine line \
    message "Option to override resolution shells selected by program - discouraged (RANGES)" \
    help "ranges" \
    label "Resolution ranges" \
    widget RANGE_MODE  \
    toggle_display RANGE_MODE open default

  CreateLine line \
    message "Option to override resolution shells selected by program - discouraged (RANGES)" \
    help "ranges" \
    label "Resolution ranges" \
    widget RANGE_MODE  \
    label "to" \
    widget RANGE_NUMBER  \
    toggle_display RANGE_MODE open NUMBER


  CreateLine line \
    message "Option to override resolution shells selected by program - discouraged (RANGES)" \
    help "ranges" \
    label "Resolution ranges" \
    widget RANGE_MODE  \
    label "to" \
    widget RANGE_WIDTH  \
    toggle_display RANGE_MODE open WIDTH

  CreateLine line \
    message "Exclude reflections from scaling below and/or above resolution limit in \
                  Angstrom (RSCALE)" \
    help "rscale" \
    widget SCALE_RESOLUTION \
	-toggleon \
    label "Exclude from Wilson scaling reflections resolution less than" \
    widget SCALE_RESOLUTION_MIN \
    label "or greater than" \
    widget SCALE_RESOLUTION_MAX

  CreateLine line \
    message "Override default volume per atom (10) (VPAT)" \
    help "vpat" \
    widget CONTENTS_USE_VPAT \
	-toggleon \
    label "Set volume per atom to" \
    widget CONTENTS_VPAT

}

#-------------------------------------------------------------------------
proc  truncate_define_contents {arrayname } {
#-------------------------------------------------------------------------

  CreateLine line \
    message "Enter cell contents for calculation of scattering power(CONTENTS/NRESIDUE)" \
    help "contents" \
    label "For calculation of scattering power enter unit cell contents as" \
    widget CONTENTS_MODE

  CreateLine line \
    message "Enter number of residues in asymmetric unit (NRESIDUE)" \
    help "nresidue" \
    label "Number of residues in asymmetric unit" \
    widget CONTENTS_NRES -oblig \
    toggle_display CONTENTS_MODE open NRES

 CreateInputFileLine line \
        "Enter input PDB file name for RWCONTENTS program to analyse" \
        "PDB in" \
        CONTENTS_PDB DIR_CONTENTS_PDB \
        -toggle_display CONTENTS_MODE open PDB

  OpenSubFrame frame -toggle_display CONTENTS_MODE open COUNT

  CreateExtendingFrame N_CONTENTS TruncateContents \
        "Add element to content list" \
        "Add element" \
      [ list CONTENTS_ATOM_TYPE \
             CONTENTS_ATOM_COUNT ]

  CloseSubFrame

}

#-------------------------------------------------------------------------
proc truncate_labout { arrayname } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array

# User has entered a appendix for labouts - apply to the standard 
# label names

  if [regexp {^_} $array(LABOUT_LABEL)] {
    set tab $array(LABOUT_LABEL)
  } elseif { $array(LABOUT_LABEL) == "" } {
    set tab ""
  } else {
    set tab _$array(LABOUT_LABEL)
  }

  foreach lab [list IMEAN SIGIMEAN Ip SIGIp Im SIGIm F SIGF DANO SIGDANO Fp SIGFp Fm SIGFm ISYM ] {
    set term [string range $lab end end]
    if [regexp {p$|m$} $term]  {
      set array($lab) [string range $lab 0 [expr [string length $lab] -2] ]
      append array($lab) $tab [lindex [list (+) (-)] [lsearch [list p m] $term]]
    } else {
      set array($lab) $lab
      append array($lab) $tab
    }
  }
  set array(USE_LABOUT) 1
}

#-------------------------------------------------------------------------
proc truncate_anomalous { arrayname } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array

  case [GetValue $arrayname INPUT_DATA]  \
   SCALA {
     if [file exists [GetFullFileName0 $arrayname HKLIN]] {
       GetMtzColumnList [GetFullFileName0 $arrayname HKLIN] \
			name_list type_list default_name [list J K] {}
       if { [lsearch $name_list "I(+)"] >= 0 } {
         set array(ANOMALOUS) 1
       } else {
         set array(ANOMALOUS) 0
       }
     }
   } ANOMALOUS {
     set array(ANOMALOUS) 1
   } NO_ANOMALOUS {
     set array(ANOMALOUS) 0
   }

#   puts "truncate_anomalous $array(INPUT_DATA) $array(ANOMALOUS)"

}
      


#-------------------------------------------------------------------------
proc  truncate_task_window { arrayname } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array

  SetProgramHelpFile "truncate"

  if { [CreateTaskWindow $arrayname  \
        "Truncate - Convert Intensities to SFs" "Truncate" \
        [ list "Data Harvesting" \
	"Required Parameters"  \
	"Anisotropy Analysis" \
	"Ctruncate options" \
	"Output MTZ Labels" \
        "Infrequently Used Parameters"   \
	"Log File Output" ] ] == 0 } return

  SetHarvestParams $arrayname HKLIN -init

  OpenFolder protocol

  CreateTitleLine line TITLE
 
  CreateLine line \
    message "Type of data in input MTZ file?" \
    label "Input data" \
    widget INPUT_DATA \
	-command "truncate_anomalous $arrayname"

  CreateLine line \
    message "Use old Truncate program" \
    widget OLDPROG \
    label "Use old Truncate program"

  OpenSubFrame frame -toggle_display INPUT_DATA hide AMPLITUDES
    
  CreateLine line \
    message "Keep the input intensities in the output MTZ file" \
    widget OUTPUT_I \
    label "Keep the input intensities in the output MTZ file" \
    toggle_display OLDPROG open 1

  UniqueifyFrame1 $arrayname

  CloseSubFrame

#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
        "Enter input MTZ file name (HKLIN)" \
        "MTZ in" \
        HKLIN DIR_HKLIN \
        -fileout HKLOUT DIR_HKLOUT "_truncate" \
	-setfileparam space_group_name SPACE_GROUP \
        -setfileparam resolution_min EXCLUDE_RESOLUTION_MIN \
        -setfileparam resolution_max EXCLUDE_RESOLUTION_MAX \
        -setfileparam resolution_min SCALE_RESOLUTION_MIN \
        -setfileparam resolution_max SCALE_RESOLUTION_MAX \
	-setfileparam cell_1 CELL_1 \
	-setfileparam cell_2 CELL_2 \
	-setfileparam cell_3 CELL_3 \
	-setfileparam cell_4 CELL_4 \
	-setfileparam cell_5 CELL_5 \
	-setfileparam cell_6 CELL_6 \
	-command "truncate_anomalous $arrayname" \
        -command "UpdateHarvestMTZ $arrayname HKLIN"


  CreateLabinLine line \
    "Choose input mean intensity (IMEAN) and sigma (SIGIMEAN)" \
     HKLIN "Imean" IMEANIN  IMEAN\
     -sigma "SigImean" SIGIMEANIN  {} \
     -toggle_display INPUT_DATA hide [ list SCALA AMPLITUDES ]

  CreateLabinLine line \
    "Choose input amplitude (F) and sigma (SIGF)" \
     HKLIN "F" FMEANIN  F\
     -sigma "SigF" SIGFMEANIN  {} \
     -toggle_display INPUT_DATA open [ list AMPLITUDES ]

  OpenSubFrame frame -toggle_display INPUT_DATA open ANOMALOUS

  CreateLabinLine line \
    "Choose input anomalous intensity (I(+)) and sigma (SIGI(+))" \
     HKLIN "I(+)" Ipp  "I(+)" \
     -sigma "SigI(+)" SIGIpp  {} 

    CreateLabinLine line \
    "Choose input anomalous intensity (I(-)) and sigma (SIGI(-))" \
     HKLIN "I(-)" Imm  "I(-)" \
     -sigma "SigI(-)" SIGImm  {}

  CloseSubFrame

  UniqueifyFrame2

  OpenSubFrame frame -toggle_display INPUT_DATA hide [list AMPLITUDES]

  CreateOutputFileLine line \
      "Enter name of output MTZ file (HKLOUT)" \
      "MTZ out" \
      HKLOUT DIR_HKLOUT

  CreateLine line \
    message "Enter an identifier for this data set to append to column labels" \
    label "Identifier to append to column labels" \
    widget LABOUT_LABEL \
	-command "truncate_labout $arrayname"

  CloseSubFrame

#  CreateLaboutLine line \
#     "Enter names for MTZ columns on Truncate output" \
#        HKLOUT "PHIDM" PHIDM 
#        -sigma "FOMDM"  FOMDM

#=PARAMETERS==========================================================

  OpenFolder 1 OLDPROG open 1 hide

  CreateHarvestLine line 

  OpenFolder 2 OLDPROG open 1 hide
  truncate_define_contents $arrayname


#----------------------------------------------------------------Falloff
  OpenFolder 3 OLDPROG closed 1 hide

  CreateLine line \
    message "Falloff of mean F v. 1/resol^2 in 3 orthogonal directions (FALLOFF)" \
    help falloff \
    widget FALLOFF \
    label "Analyse anisotropy by Yorgo Modis' falloff procedure using reflections within" \
    message "Default cone 30degrees(FALLOFF CONE)" \
    widget FALLOFF_CONE \
    label "cone of axis"

  CreateLine line \
    help falloff \
    label "Outplot plot file oriented" \
    widget FALLOFF_PLOT
    
    
#----------------------------------------------------------------Ctruncate options
  OpenFolder 4 OLDPROG closed 0 hide

  CreateLine line \
    message "Anisotropy correction" \
    help anisocorr \
    widget ANISOCORR \
    label "Apply anisotropy correction" \
    
  CreateLine line \
    message "Scale using number of residues in asymmetric unit" \
    help falloff \
    widget CTRUNCATE_SCALE \
    label "Number of residues in asymmetric unit" \
    message "Number of residues in asymmetric unit" \
    widget CTRUNCATE_NRES \
    

#------------------------------------------------------------------MTZ labels
  OpenFolder 5 INPUT_DATA hide [list AMPLITUDES] closed

  CreateLine line \
    message "Use column labels defined below" \
    widget USE_LABOUT \
    label "Override default output labels"
    
  CreateLaboutLine line \
     "MTZ column labels for output F & SIGF" \
        HKLOUT "F" F \
        -sigma "SIGF" SIGF

    CreateLaboutLine line \
     "MTZ column labels for output I & SIGI" \
        HKLOUT "IMEAN" IMEAN \
        -sigma "SIGIMEAN" SIGIMEAN


  OpenSubFrame frame -toggle_display ANOMALOUS hide 0

  CreateLaboutLine line \
     "MTZ column labels for output DANO & SIGDANO" \
        HKLOUT "DANO" DANO \
        -sigma "SIGDANO" SIGDANO 

  CreateLaboutLine line \
     "MTZ column labels for output F(+) & SIGF(+)" \
        HKLOUT "F(+)" Fp \
        -sigma "SIGF(+)"  SIGFp

  CreateLaboutLine line \
     "MTZ column labels for output F(-) & SIGF(-)" \
        HKLOUT "F(-)" Fm \
        -sigma "SIGF(-)"  SIGFm

  CreateLaboutLine line \
     "MTZ column labels for output I(+) & SIGI(+)" \
        HKLOUT "I(+)" Ip \
        -sigma "SIGI(+)"  SIGIp

  CreateLaboutLine line \
     "MTZ column labels for output I(-) & SIGI(-)" \
        HKLOUT "I(-)" Im \
        -sigma "SIGI(-)"  SIGIm

  CreateLaboutLine line \
     "MTZ column labels for output ISYM" \
        HKLOUT "ISYM" ISYM 

  CloseSubFrame


#------------------------------------------------------- unusual params
  OpenFolder 6 OLDPROG closed 1 hide

  CreateLine line \
    message "Exclude reflections below and/or above resolution limit in \
                  Angstrom (RESOLUTION)" \
    help "resolution" \
    widget EXCLUDE_RESOLUTION \
	-toggleon \
    label "Exclude reflections resolution less than" \
    widget EXCLUDE_RESOLUTION_MIN \
    label "or greater than" \
    widget EXCLUDE_RESOLUTION_MAX

  CreateLine line \
    message "Space group (default as in MTZ file) (SYMMETRY)" \
    help "symmetry" \
    widget SYMMETRY \
	-toggleon \
    label "Set space group" \
    widget SPACE_GROUP

  CreateLine line \
    message "Cell dimensions (default from MTZ file) (CELL)" \
    help "cell" \
    widget CELL \
	-toggleon \
    label "Set cell a" \
    widget CELL_1 -width 8 \
    label "b" \
    widget CELL_2 -width 8 \
    label "c" \
    widget CELL_3 -width 8 \
    label "alpha" \
    widget CELL_4 -width 8 \
    label "beta" \
    widget CELL_5 -width 8 \
    label "gamma" \
    widget CELL_6 -width 8

  truncate_options $arrayname

# -------------------------------------------------------log file output
    
  OpenFolder 7 OLDPROG closed 1 hide

  CreateLine line \
    message "Plot Wilson plot to log file (PLOT)" \
    help "plot" \
    widget WILSON_PLOT \
    label "Draw Wilson plot to file"

  CreateLine line \
    message "Level of header output to log file (HEADER&BATCH)" \
    help "header" \
    label "Print" \
    widget OUTPUT_HEADER \
    label "file header info and" \
    widget OUTPUT_BATCH \
    label "batch data"
    
}



