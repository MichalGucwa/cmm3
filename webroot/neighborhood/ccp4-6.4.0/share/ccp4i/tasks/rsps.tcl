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
# mapave.tcl --
#
# Run maprot to generate averaged map
#
# CCP4Interface 
#
# ======================================================================

#-----------------------------------------------------------------------
proc ncs_operators { arrayname counter } {
#-----------------------------------------------------------------------

   CreateLine ops_frame \
        message "Enter NCS operator (NCSROT POLAR)" \
        label "alpha" \
        widget NCS_OP_ALPHA \
        label "beta" \
        widget NCS_OP_BETA \
        label "gamma" \
        widget NCS_OP_GAMMA \
        label "xtran" \
        widget NCS_OP_XTRAN \
        label "ytran" \
        widget NCS_OP_YTRAN \
        label "ztran" \
        widget NCS_OP_ZTRAN
}


#-----------------------------------------------------------------------
proc  rsps_setup { typedefVar arrayname } {
#-----------------------------------------------------------------------
  DefineMenu _rsps_score_mode [ list "sum function" \
				"product function" \
				"harmonic mean function" ] \
			[ list SUM PRODUCT HARMONIC ]

  DefineMenu _rsps_input [ list "read from coordinate file" \
				"from scan of Patterson map" ] \
				[ list FILE SCAN ]

  DefineMenu _rsps_mode [ list "do nothing" \
			"find sets of sites with good cross vectors" \
			"find sites with good cross vectors to fixed site(s)" ] \
			[ list NOTHING GETSETS CROSSPEAKS ]
  return 1
			
}

#-----------------------------------------------------------------------
proc rsps_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  set input [GetValue $arrayname RSPS_INPUT]
  set mode [GetValue $arrayname RSPS_MODE]

  set array(INPUT_FILES) PATFILE
  set array(OUTPUT_FILES) ""
  if [StringSame $input FILE] {
    for { set n 1 } { $n <= $array(NINSITESFILE) } { incr n } {
      append array(INPUT_FILES) " "  INSITESFILE,$n
    }
  } else {
    append array(OUTPUT_FILES) HPEAKSFIL
    set array(NINSITESFILE) 1
    set array(INSITESFILE,1) $array(HPEAKSFIL)
  }

  if [StringSame $mode CROSSPEAKS] {
  append array(OUTPUT_FILES) " " XPEAKSFIL }

  return 1

}

#-----------------------------------------------------------------------
proc rsps_insites { arrayname counter } {
#-----------------------------------------------------------------------

  CreateInputFileLine line \
      "Enter input potential heavy atom sites (HPEAKSFIL)" \
      "Sites in" INSITESFILE DIR_INSITESFILE

}

#-----------------------------------------------------------------------
proc rsps_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"RSPS - Real Space Patterson Search" "RSPS" \
        [ list "Essential Parameters" \
		"Scan Patterson for Potential Vectors" \
		"Find Sets of Sites with Good Cross Vectors" \
		"Find Sites with Good Cross Vectors to Fixed Site(s)" \
		"Non-Crystallographic Symmetry Operators" \
		"Search Extent" ] ] == 0 } return

  SetProgramHelpFile rsps

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
    label "Get list of potential heavy atom sites" \
    widget RSPS_INPUT

  CreateLine line \
    label "To analyse sites" \
    widget RSPS_MODE
    
#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter input Patterson map file name (PATFILE)" \
      "Map in" PATFILE DIR_PATFILE \
	-setfileparam xyzlim XYZLIM

  CreateOutputFileLine line \
      "Save potential heavy atom sites in pseudo-PDB file (HPEAKSFIL)" \
      "Sites out" HPEAKSFIL DIR_HPEAKSFIL \
        -toggle_display RSPS_INPUT open SCAN

  OpenSubFrame frame -toggle_display RSPS_INPUT  open FILE

  CreateExtendingFrame NINSITESFILE rsps_insites \
        "Add name of file contains putative HA sites." \
        "Add sites file" \
        [ list INSITESFILE DIR_INSITESFILE]

  CloseSubFrame

  OpenSubFrame frame -toggle_display RSPS_MODE  open CROSSPEAKS 

  CreateLine line \
    label "Root name for file(s) listing Harker peaks for cross vectors" \
	-italic

  CreateOutputFileLine line \
      "Enter name for cross-peaks pseudo-PDB coordinates file (XPEAKSFIL)" \
      "Peaks out" XPEAKSFIL DIR_XPEAKSFIL

  CloseSubFrame

#--------------------------------------------------------------Essential 

  OpenFolder 1

   CreateLine line \
    message "Space group (default as in map file) (SYMMETRY)" \
    help spacegroup \
    label "Crystal (not Patterson) space group" \
    widget SPACE_GROUP -oblig


#------------------------------------------------------------harker scan
  OpenFolder 2 RSPS_INPUT closed SCAN hide

  CreateLine line \
    label "Find" \
    widget PICK_HARKER_N \
    label "potential vectors"

  CreateLine line \
    label "Pick vectors correlating to peaks >" \
    message "Leave blank for default reject criteria of 1 sigma (REJECT)" \
    widget HARKER_REJECT \
    label "sigma in map allowing" \
    message "Allow n peaks per vectors to be below rejection criteria (LOW)" \
    widget HARKER_LOW \
    label "peak(s) below threshold"

# -----------------------------------------------------------getsets

  OpenFolder 3 RSPS_MODE closed GETSETS hide

  CreateLine line \
    label "Find sets of at least" \
    widget GETSETS_MIN \
    label "sites from the first" \
    widget GETSETS_USE \
    label "in list of potential sites"

  CreateLine line \
    label "Pick sites correlating to peaks >" \
    message "Leave blank for default reject criteria of 1 sigma (REJECT)" \
    widget GETSETS_REJECT \
    label "sigma in map allowing" \
    message "Allow n peaks per site to be below rejection criteria (LOW)" \
    widget GETSETS_LOW \
    label "peak(s) below threshold"


#-----------------------------------------------------------cross peaks

  OpenFolder 4 RSPS_MODE closed CROSSPEAKS hide

  CreateLine line \
    label "Set each of the best" \
    widget N_CROSS_PEAKS \
    label "sites as fixed in turn"

  CreateLine line \
    label "Find" \
    widget PICK_CROSS_N \
    label "sites giving best cross vectors" \
    label "and list Harker vectors for"  \
    widget X_LIST_HARKER_N \
    label "best sites"

  CreateLine line \
    label "Pick sites correlating to peaks >" \
    message "Leave blank for default reject criteria of 1 sigma (REJECT)" \
    widget CROSS_REJECT \
    label "sigma in map allowing" \
    message "Allow n peaks per site to be below rejection criteria (LOW)" \
    widget CROSS_LOW \
    label "peak(s) below threshold"

 CreateLine line \
    label "Score cross peaks using" \
    message "Scoring function (SCORE)" \
    widget CROSS_SCAN_SCORE_MODE \
    label "applied to" \
    message "Leave blank for default to apply to all peaks (SCORE)" \
    widget CROSS_SCAN_SCORE_N \
    label "smallest peaks"

#------------------------------------------------------------NCS operators
  OpenFolder 5 closed

  CreateExtendingFrame NCS_NOPS ncs_operators \
        "Add/remove line to define NCS symmetry (identity NOT needed)" \
        "Add NCS operator" \
        [ list NCS_OP_ALPHA \
        NCS_OP_BETA \
        NCS_OP_GAMMA \
        NCS_OP_XTRAN \
        NCS_OP_YTRAN \
        NCS_OP_ZTRAN ]

#---------------------------------------------------------map parameters
  OpenFolder 6  closed

  CreateLine line \
    message "Change map search limits, default is asymmetric unit (LIMITS)" \
    help scan \
    widget IFXYZLIM \
	-toggleon \
    label "Search map extent x" \
    widget XYZLIM_1  \
    widget XYZLIM_2  \
    label "y"       \
    widget XYZLIM_3  \
    widget XYZLIM_4  \
    label "z"       \
    widget XYZLIM_5  \
    widget XYZLIM_6

#  CreateLine line \
#    message "Set grid values (GRID)" \
#    help grid \
#    label "Grid x=" \
#    widget GRID_1 \
#    label "y=" \
#    widget GRID_2 \
#    label "z=" \
#    widget GRID_3

}

