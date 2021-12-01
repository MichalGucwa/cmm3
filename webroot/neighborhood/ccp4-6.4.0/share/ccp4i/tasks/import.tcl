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
# import.tcl --
#
# Import a formatted reflection file (eg from Xplor) and create MTZ file
#
# CCP4Interface 
# Created Jan97 by Liz Potterton
#
# =======================================================================

source [SearchPath TOP tasks truncate.tcl]

#-----------------------------------------------------------------------
proc import_setup { typedefVar arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $typedefVar typedef

  set typedef(_imprfx_format)     { menu  {MTZ
				  "ascii MTZ"
                                  X-PLOR/CNS
                                  SHELX
                                  MULTAN
                                  TNT
                                  mmCIF
                                  "user defined" }
                                { MTZ
				  MTZNA4
                                  X-PLOR/CNS
                                  SHELX
                                  MULTAN
                                  TNT
                                  CIF
                                  USER } }

  set typedef(_freer_mode) { menu { "keep existing FreeR data" \
			     "import FreeR data from another MTZ file" \
			     "generate FreeR data" } { 1 3 2 } }

  set typedef(_column_name_lines) {int 4 5 20 NOTOBLIG { } }
  
  set typedef(_import_truncate_prog) { menu { "Ctruncate" \
                                         "old Truncate" }
                                       { CTRUNCATE TRUNCATE } }

  truncate_setup $typedefVar $arrayname
  
  return 1

}

#-----------------------------------------------------------------------
proc import_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

# procedure run before script is written
  ArrayToList $arrayname NCOL COLUMN_NAME LABOUT
  ArrayToList $arrayname NCOL COL_TYPE CTYPOUT

  if { $array(FORTRAN_FORMAT) != "" } {
    set tt [string trim [string trim $array(FORTRAN_FORMAT) ' ] () ]
    set array(FORTRAN_FORMAT) "'($tt)'"
    # Unset the fortran format if the string is empty
    # This forces f2mtz to use "free" format
    if { $array(FORTRAN_FORMAT) == "'()'" } {
	set array(FORTRAN_FORMAT) ""
    }
  }

  set format [GetValue $arrayname FORMAT]
  if [regexp MTZ$ $format ] {
    set array(INPUT_FILES) MTZ_INPUT_FILE
  } elseif [regexp TNT $format ] {
    set array(INPUT_FILES) TNT_INPUT_FILE
  } elseif [regexp CIF $format ] {
    set array(INPUT_FILES) CIF_INPUT_FILE
    set array(LABIN_FREER) $array(LABIN_FREER_1)
  } else {
    set array(INPUT_FILES) HKL_INPUT_FILE
  }

# pname/dname is optional for mmCIF as it should be extracted from
# _entry.id and _diffrn.id  A more advanced interface would check the file
  if [regexp CIF $format ] {
    if { $array(HARVEST_PNAME) != "" && $array(HARVEST_DNAME) != "" } { 
      if { ![SetHarvestParams $arrayname {} -run] } { return 0 }
    }
  } else {
    if { ![SetHarvestParams $arrayname {} -run] } { return 0 }
  }

  return 1

}

#--------------------------------------------------------------------
proc import_default_format { arrayname } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array

  if { $array(FORMAT) == "MTZ" } {
    set array(FORTRAN_FORMAT) "" 
  } elseif { $array(FORMAT) == "X-PLOR/CNS" } {
    InitialiseArray [SearchPath TOP tasks import_cns.def ] $arrayname import
  } elseif { $array(FORMAT) == "SHELX" } {
    InitialiseArray [SearchPath TOP tasks import_shelx.def ] $arrayname import
  } elseif { $array(FORMAT) == "MULTAN" } {
    InitialiseArray [SearchPath TOP tasks import_multan.def ] $arrayname import
  } elseif { $array(FORMAT) == "TNT" } {
    InitialiseArray [SearchPath TOP tasks import_tnt.def ] $arrayname import
  } elseif { $array(FORMAT) == "mmCIF" } {
    InitialiseArray [SearchPath TOP tasks import_cif.def ] $arrayname import
  } elseif { $array(FORMAT) == "user defined" } {
    InitialiseArray [SearchPath TOP tasks import_user.def ] $arrayname import
  }

  set w $array(WINDOW)
  if [winfo exist $w ] {
    DeleteTaskWindow $w $arrayname import -noexit }
  UnsetArrayExtras $arrayname
  RunTask  import -array $arrayname

  if [StringSame $array(FORMAT) SHELX MULTAN USER] {
    set array(RUN_TRUNCATE) 1
  } else {
    set array(RUN_TRUNCATE) 0
  }

}

#---------------------------------------------------------------------
proc import_update_freermode { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array
  global typedef

  if { [llength $array(COLUMNLABELS_LABIN_FREER)] > 1 } {
    set array(FREER_MODE)  [lindex [lindex $typedef(_freer_mode) 1 ] 0]
  } elseif { [GetValue $arrayname FREER_MODE] == 1 } {
    set array(FREER_MODE) [lindex [lindex $typedef(_freer_mode) 1 ] 2]
  }
}

#---------------------------------------------------------------------
proc import_launch_edit_datasets { arrayname } {
#---------------------------------------------------------------------
# User really wants to edit dataset information so close
# the current window and launch the appropriate task for them
  upvar #0 $arrayname array

  set w $array(WINDOW)
  if [winfo exist $w ] {
    DeleteTaskWindow $w $arrayname import -noexit }
  UnsetArrayExtras $arrayname
  RunTask  edit_dname
}

#=======================================================================
proc ImportColumnsFrame { arrayname i } {
#=======================================================================

    CreateLine line  \
        message "Data type and label for each input field (CTYPOUT & LABOUT)"   \
	help labout \
        label $i                                                        \
        widget COL_TYPE \
        widget COLUMN_NAME \
        format template "COLUMNS"

}


#=CREATE=WINDOW=AND=SUBWINDOWS===========================================

proc import_task_window { arrayname } {

  upvar #0 $arrayname array
  global configure

  if { [CreateTaskWindow $arrayname  \
	"Convert to/modify/extend MTZ" "To MTZ" \
	[ list "MTZ Project, Crystal & Dataset Names" \
        "MTZ Project, Crystal, Dataset Names & Data Harvesting" \
	"Cell and Spacegroup to be saved in MTZ file" \
	"Detailed specification of import file format" \
	"Convert Is to Fs" \
	"Creating full/unique dataset"  ] ] == 0 } return

  SetProgramHelpFile "f2mtz"
  SetHarvestParams $arrayname {}  -init
  
#=PROTOCOL==============================================================
# Choose format of file to be read

  OpenFolder protocol

  CreateTitleLine line TITLE

  CreateLine format_input  \
	message "Choose input reflection file format "	\
	help description \
	label "Import reflection file in "		\
	widget FORMAT 					\
		-command "import_default_format $arrayname"	\
	label " format and create MTZ file"

  SetProgramHelpFile cif2mtz

  CreateLine line \
    message "Convert hkl / -h-k-l pairs to F(+) / F(-) columns" \
    help anom \
    widget ANOMALOUS \
    label "Input file contains anomalous data as hkl / -h-k-l pairs" \
    toggle_display FORMAT open [list CIF ]

  SetProgramHelpFile truncate

  CreateLine line \
    message "Convert input intensities to structure factors" \
    widget RUN_TRUNCATE \
    label "Run" \
    widget IMPORT_TRUNCATE_PROG \
    label "to convert Is to Fs" \
    toggle_display FORMAT open [list SHELX MULTAN USER ]
    
  SetProgramHelpFile unique

  # Uniquiefy is only optional for non-MTZ input
  OpenSubFrame frame -toggle_display FORMAT hide MTZ 

  CreateLine line \
	message "Use uniqueify script to run unique and/or freerflag" \
	help description \
	widget RUN_UNIQUE  				\
	label "Create full unique set of reflections" \
        toggle_display RUN_UNIQUE open { 0 }

  CreateLine line \
	message "Use uniqueify script to run unique and/or freerflag" \
	help description \
	widget RUN_UNIQUE  				\
	label "Create full unique set of reflections and" \
        widget FREER_MODE \
        toggle_display RUN_UNIQUE open { 1 }

  CloseSubFrame

  # Always run uniqueify for MTZ input
  CreateLine line \
	message "Use uniqueify script to run unique and/or freerflag" \
	help description \
	label "Create full unique set of reflections and" \
        widget FREER_MODE \
        toggle_display FORMAT open MTZ

#  SetProgramHelpFile sftools

#  CreateLine line \
#	message "Run Sftools to check validity of reflection data" \
#	help checkhkl \
#        widget CHECKHKL \
#	label "Run Sftools checkhkl to validate data"


#=FILES================================================================

# frame to enter input file name - note there are two different input lines
# depending on whether input format is mtz or other - only one line is 
# displayed at a time

  SetProgramHelpFile f2mtz

  OpenFolder file

  CreateInputFileLine line \
      "Enter input MTZ file name " \
        "In" \
       MTZ_INPUT_FILE DIR_MTZ_INPUT_FILE \
       -fileout HKLOUT  DIR_HKLOUT _unique \
       -setlabin LABIN_FREER { FREE FreeR FreeR_flag FreeRflag} \
       -setfileparam resolution_max RESOLUTION_MAX \
       -command "import_update_freermode $arrayname" \
       -command "UpdateHarvestMTZ $arrayname MTZ_INPUT_FILE" \
       -toggle_display FORMAT open MTZ

  CreateInputFileLine line \
      "Enter input reflection file name (HKLIN)" \
        "In" \
       CIF_INPUT_FILE DIR_CIF_INPUT_FILE \
       -fileout HKLOUT  DIR_HKLOUT -- \
       -toggle_display FORMAT open CIF 

  CreateInputFileLine line \
      "Enter input reflection file name (HKLIN)" \
        "In" \
       HKL_INPUT_FILE DIR_HKL_INPUT_FILE \
       -fileout HKLOUT  DIR_HKLOUT -- \
       -toggle_display FORMAT hide [ list MTZ CIF ]

#       -setlabinunassigned LABIN_FREER \

  CreateInputFileLine line \
      "Enter second (FreeR) reflection file name (TNT_INPUT_FILE)" \
        "TNT FreeR file" \
       TNT_INPUT_FILE DIR_TNT_INPUT_FILE \
       -toggle_display FORMAT open TNT

  CreateInputFileLine line \
      "Enter MTZ file name for FreeR data" \
        "Import FreeR MTZ" \
       IMPORT_FREER_MTZ DIR_IMPORT_FREER_MTZ \
       -setlabin IMPORT_FREER_LABIN { FREE FreeR FreeR_flag FreeRflag } \
       -toggle_display FREER_MODE open 3


  CreateOutputFileLine line \
      "Enter output MTZ file name (HKLOUT)" \
       "Out" \
       HKLOUT DIR_HKLOUT \
       -info

#=PARAMETERS==========================================================

  OpenFolder 1 RUN_TRUNCATE open 0 hide
 
  OpenSubFrame frame -toggle_display FORMAT hide { MTZ }
 
     CreateHarvestLine line  -noharvest 

  CloseSubFrame

  OpenSubFrame frame -toggle_display FORMAT open { MTZ }

  # Display the project/dataset information but don't allow
  # the user to edit it
  CreateLine line \
    label "Note that this information cannot be edited here - use Edit MTZ Datasets:" -italic \
    button "Launch Edit MTZ Datasets" -command "import_launch_edit_datasets $arrayname"

  CreateLine line \
    label "Crystal" \
    varlabel HARVEST_XNAME \
    label "belonging to Project" \
    varlabel HARVEST_PNAME

  $line.l2 config -width 20 -background $configure(COLOUR_BACKGROUND) \
	  -relief groove
  $line.l4 config -width 20 -background $configure(COLOUR_BACKGROUND) \
	  -relief groove

  CreateLine line \
    label "Dataset name" \
    varlabel HARVEST_DNAME

  $line.l2 config -width 20 -background $configure(COLOUR_BACKGROUND) \
	  -relief groove

  CloseSubFrame

  OpenFolder 2 RUN_TRUNCATE open 1 hide

  CreateHarvestLine line  -dname

#----------------------------------------------------------------------------

  OpenFolder 3 FORMAT hide [list MTZ MTZNA4 ] open [list CIF USER] closed

  CreateLine  line  \
	message "Enter a space group as found in syminfo.lib (SYMMETRY) "	\
	help symmetry \
	label "Space group name or number" \
	widget SPACE_GROUP -oblig

  CreateLine  line  \
	message "Enter cell lengths(Angstrom) and angles(degs) (CELL)"	\
	help cell \
	label "Cell dimensions a" \
        widget CELL_1 -width 8 -oblig \
        label "b" \
        widget CELL_2 -width 8 -oblig \
        label "c" \
        widget CELL_3 -width 8 -oblig \
        label "alpha" \
        widget CELL_4 -width 8 -oblig \
        label "beta" \
        widget CELL_5 -width 8 -oblig \
        label "gamma" \
        widget CELL_6 -width 8 -oblig 


#==DETAILED=FORMAT=SPEC================================================

  OpenFolder 4 FORMAT hide [list MTZ MTZNA4 CIF] open [list USER X-PLOR/CNS] closed
		
  CreateLine line \
	" " \
        label "X-plor/CNS formats are variable. Please check this line:" -italic \
        toggle_display FORMAT open X-PLOR/CNS

  CreateLine  line  \
	message "Fortran specification of the format (FORMAT)"   \
	help format \
	label "Fortran format"					\
	widget FORTRAN_FORMAT  -width 25  -expand \
        message "Skip number of lines at top of file (SKIP)" \
	help skip \
	label " Skip first"					\
	widget SKIPLINE  -width 5 \
		label "lines"
		
  CreateLine line \
	" " \
        label "Data type and label for input fields"

#Frame to enter the column types

  CreateLineTemplate "COLUMNS" {0.0 0.04 0.5 }

  CreateExtendingFrame NCOL ImportColumnsFrame \
    "Add/remove  line to define extra column in MTZ file " \
    "Add column label"  \
       	      [ list COL_TYPE \
		COLUMN_NAME  ]

#--------------------------------------------------------truncate

  OpenFolder 5 RUN_TRUNCATE open 1 hide 

  SetProgramHelpFile "truncate"

  CreateLine line \
    message "Labels should correspond to those defined in format above (LABIN)" \
    help "labin" \
    label "Input labels Imean" \
    widget IMEANIN \
	-width 20 \
    label "SigmaI" \
    widget SIGIMEANIN \
	-width 20

  truncate_define_contents $arrayname

  truncate_options $arrayname

  
 
#=UNIQUE/FULL=DATASET====================================================

  OpenFolder 6 RUN_UNIQUE  open [list 1 ] hide 

  SetProgramHelpFile "freerflag"


  OpenSubFrame frame -toggle_display FREER_MODE open 1

    CreateLine line  \
       message "Use existing FreeR"      \
       label "FreeR column label" \
       widget LABIN_FREER   \
       toggle_display  FORMAT open MTZ

    CreateLine line  \
       message "New FreeR column name"      \
       label "FreeR column label" \
       widget LABIN_FREER_1   \
       toggle_display  FORMAT hide MTZ

  CloseSubFrame

  CreateLine line  \
        message "Use FreeR from an existing MTZ file" \
       help description \
       label "Copy FreeR data from " \
       widget IMPORT_FREER_LABIN  \
       toggle_display FREER_MODE open 3

  CreateLine line	 \
    message " ..or choose fraction of reflections for freeR"	\
    help freerfrac \
    label  "Set FreeR for fraction of reflections"  \
    widget FREER_FRACTION \
    toggle_display FREER_MODE open 2

  SetProgramHelpFile cad

  CreateLine line   \
	message "Include systematic absences in the full unique dataset?" \
	help sysab \
	widget INCL_SYS_ABS \
	label "Include systematic absences"

  CreateLine line \
	message "Extend resolution" \
	help resolution \
	widget EXTEND_RESOLUTION \
	  -toggleon \
	label "Extend resolution to" \
	widget RESOLUTION_MAX
}

