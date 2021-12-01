#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#     Original shelxd interface written by Thomas Pape & Thomas R. Schneider
#     Extended for CCP4 by Peter Briggs
#
#CCP4i_cvs_Id $Id$
#======================================================================
# shelx.tcl --
#
# Run shelx program for direct methods or heavy atom search
#
# CCP4Interface
#
#======================================================================

#------------------------------------------------------------------------------
proc shelxd_setup { typedefVar arrayname } {
#------------------------------------------------------------------------------
  
  upvar #0 $typedefVar typedef

  set typedef(_shelx_mode) { menu { "HA substructure" "Direct Methods" }
				{ HEAVY_ATOM DIRECT } }

  set typedef(_shelx_lattice) { menu { "primitive" "body centred" "face centred" \
				"A-face centred" "B-face centred" "C-face centred" }
				{ -1 -2 -4 -5 -6 -7 } }

  set typedef(_input_heavy_atoms) { menu { "from HA file" "from pdb file" "entered below" }
                                         { HAFILE PDBFILE LIST } }

  return 1

}


#------------------------------------------------------------------------------
proc  shelxd_run { arrayname } {
#------------------------------------------------------------------------------

  upvar #0 $arrayname array
  global configure

  if { [ regexp MTZ [GetValue $arrayname INPUT_FORMAT ]] } {
    set array(INPUT_FILES) MTZIN
    set array(LABIN) "FP SIGFP"
    if { [regexp isomorphous [GetValue $arrayname DATA_TYPE] ] } {
      append array(LABIN) " FPH SIGFPH"
    } else {
      append array(LABIN) " DP SIGDP"
    }
  } else {
    set array(INPUT_FILES) HKLIN
  }

  set SHELX_MODE [GetValue $arrayname SHELX_MODE]

  if {$SHELX_MODE == "HEAVY_ATOM"} {

    set array(SFAC_LIST) "$array(HEAVY_TYPE)"
    set array(UNIT_LIST) "$array(NHEAVY)"

  }

  if {$SHELX_MODE == "DIRECT"} {

    set array(SFAC_LIST) "$array(ATOM_TYPE_LIST)"
    set array(UNIT_LIST) "$array(NATOMS_LIST)"

  }

  if { [ElementExists configure SHELX] && $configure(SHELX) != "" } {
    set array(SHELX_PROGRAM) $configure(SHELX)
  }

  # If title is blank then reset to a sensible default immediately prior
  # to running the task

  if { $array(TITLE) == "" } {
    if { [GetValue $arrayname SHELX_MODE] == "HEAVY_ATOM" } {
      set array(TITLE) "SHELXD substructure solution"
    } else {
      set array(TITLE) "SHELXD direct methods"
    }
  }

  return 1
}

#----------------------------------------------------------------------
proc shelxd_set_lattice { arrayname } {
#----------------------------------------------------------------------

   upvar #0 $arrayname array

   SetValue $arrayname LATTICE \
	[GetLatticeFromSpaceGp $array(SPACE_GROUP) -shelx ]
}


#-----------------------------------------------------------------------
proc direct_methods_seed { arrayname counter } {
#-----------------------------------------------------------------------

  upvar #0 $arrayname array

  CreateLine line \
    widget DM_SEED_USE -width 6 -oblig \
    widget DM_SEED_AT -width 7 -oblig \
    widget DM_SEED_X -width 7 -oblig \
    widget DM_SEED_Y -width 7 -oblig \
    widget DM_SEED_Z -width 7 -oblig \
    widget DM_SEED_B -width 7 -oblig \
    format template DM_SEEDS

}


#-----------------------------------------------------------------------
proc shelxd_task_window { arrayname } {
#-----------------------------------------------------------------------

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"SHELXD - Heavy Atom Search" "Shelx" \
	[ list "Cell Parameters" \
	"SHELXD Direct Methods Parameters" \
        "SHELXD Heavy Atom Parameters" \
        "SHELXD Advanced Options" ] ] == 0 } return

  SetProgramHelpFile "shelxd"
  
  WriteCredits [list "Thomas Pape & Thomas R. Schneider"] \
    -link "SHELXD web-site: www.shelx.org" http://shelx.uni-ac.gwdg.de/SHELX/ \
    -label "SHELXD-Interface Authors"


#=PROTOCOL==============================================================

  OpenFolder protocol

  CreateLine line \
    label "NOTE : This task uses the Shelxd program which is not distributed with CCP4 - click Help for details" -italics

  CreateTitleLine line TITLE

  CreateLine line \
     message "Choose method to solve structure - heavy atom substructure or direct methods" \
     label "SHELXD method to solve structure" \
     widget SHELX_MODE

#  if {$SHELX_MODE == "HEAVY_ATOM"} {set MDIS 3.5}
#  if {$SHELX_MODE == "DIRECT"} {set MDIS 1.0}

#=FILES================================================================

  OpenFolder file

  CreateInputFileLine line \
      "Enter input MTZ file name (MTZIN)" \
      "MTZ in" \
       MTZIN DIR_MTZIN \
        -fileout HAOUT DIR_HAOUT _shelxd_ \
        -fileout PDBOUT DIR_PDBOUT _shelxd_ \
        -setfileparam resolution_min EXCLUDE_RESOLUTION_MIN \
        -setfileparam resolution_max EXCLUDE_RESOLUTION_MAX \
        -setfileparam cell CELL \
        -setfileparam space_group_name SPACE_GROUP \
        -command "shelxd_set_lattice $arrayname"

  CreateLabinLine line \
    "Native data amplitude (FP) and optional sigma (SIGFP)" \
     MTZIN FP FP [list FP F] \
     -sigma SigmaFP SIGFP  {} \
     -toggle_display SHELX_MODE open DIRECT

  # to_do: FM is not selected as the default when using HA substructure method
  # don't know why not...

  CreateLabinLine line \
    "DeltaF or FA amplitude (FH) and sigma (SIGFH)" \
    MTZIN FH FP [list FM] \
    -sigma SIGFH SIGFP [list SIGFM] \
    -toggle_display SHELX_MODE open HEAVY_ATOM

  OpenSubFrame frame -toggle_display SHELX_MODE open HEAVY_ATOM

  CreateLine line \
  label "Heavy atom file to be written.."  -italic

  CreateOutputFileLine line \
   "Enter output heavy atom file name (HAOUT)" \
   "HA out" \
    HAOUT DIR_HAOUT

  CloseSubFrame

  OpenSubFrame frame -toggle_display SHELX_MODE open DIRECT

  CreateLine line \
  label "Output pdb-file file to be written.."  -italic

  CreateOutputFileLine line \
   "Enter output pdb file name (PDBOUT)" \
   "PDB out" \
    PDBOUT DIR_PDBOUT

  CloseSubFrame


#--------------------------------------------------------------------

  OpenFolder 1

  SetProgramHelpFile shelx

  CreateLine line \
    message "Cell dimensions (default from MTZ file) (CELL)" \
    help cell \
    label "Set cell a" \
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

  CreateLine line \
    message "Space group (default as in MTZ file) (SYMMETRY)" \
    label "Space group : " \
    help symmetry \
    widget SPACE_GROUP -oblig -command "shelxd_set_lattice $arrayname" \
    label "   Wavelength : " \
    widget CELL_LAMBDA -oblig

#-----------------------------------------------------------------------------------

  OpenFolder 2 SHELX_MODE open DIRECT hide

  CreateLineTemplate DM_SEEDS { 0 0.125 0.25 0.375 0.5 0.625 }

#  CreateLine line \
#    label "Non-hydrogen atoms present in the asymmetric unit :" -italic

  CreateLine line \
    message "Expected number of residues per asymmetric unit." \
    label "Number of residues per asymmetric unit : " \
    widget RESIDUES_AU -width 5 -oblig
  
  CreateLine line \
    message "Input known atom positions to be used as seed for Direct Methods." \
    widget DM_SEED_ONOFF \
    label "Use known atom positions"  \
    widget DM_SEED_METHOD \
    label "as seed."

  OpenSubFrame frame -toggle_display DM_SEED_ONOFF open 1

  OpenSubFrame frame -toggle_display DM_SEED_METHOD open LIST

  CreateLine line \
    label "Use atom" \
    label "atom type" \
    label "  Xfrac" \
    label "  Yfrac" \
    label "  Zfrac" \
    label "  isoU" \
    format template DM_SEEDS

  CreateExtendingFrame DM_SEED_NATOMS direct_methods_seed \
        "Add another atom as seed." \
        "Add atom" \
        [ list DM_SEED_USE \
               DM_SEED_AT \
               DM_SEED_X \
               DM_SEED_Y \
               DM_SEED_Z \
               DM_SEED_B ]

  CloseSubFrame

  OpenSubFrame frame -toggle_display DM_SEED_METHOD open HAFILE

  CreateInputFileLine line \
      "Enter heavy atom data file (.ha)" \
      "HA in" \
       DM_HA_FILE  DIR_DM_HA_FILE

  CloseSubFrame

  OpenSubFrame frame -toggle_display DM_SEED_METHOD open PDBFILE

  CreateInputFileLine line \
      "Enter pdb-file (.pdb)" \
      "PDB in" \
       DM_PDB_FILE  DIR_DM_PDB_FILE

  CloseSubFrame

  CloseSubFrame

  CreateLine line \
    message "Limit number of attempts to be made by SHELXD (NTRY-keyword)" \
    label "Limit number of tries to"  \
    widget NTRY -width 5 -oblig \
    label "." \
    toggle_display DM_SEED_ONOFF open 0

#-----------------------------------------------------------------------------------

  OpenFolder 3 SHELX_MODE open HEAVY_ATOM hide

  CreateLine line \
    message "Exclude reflections below and/or above resolution limit in \u00c5 \
             (SHEL-keyword)" \
    help resolution \
    label "Resolution less than" \
    widget SHEL_DMIN -oblig -width 5 \
    label "\u00c5 or greater than" \
    widget SHEL_DMAX -oblig -width 6 \
    label "\u00c5."

  CreateLine line \
    message "Enter number and type of atoms to search for (FIND keyword)" \
    label "Search for" \
    widget NHEAVY -width 4 -oblig \
    label "atoms of" \
    widget HEAVY_TYPE -width 3 -oblig \
    label "."

  CreateLine line \
    message "Choose whether or not starting atoms should be found from the Patterson" \
    widget PATS_ONOFF \
    label "Run a Patterson-search to find a starting set of atoms."
  
  CreateLine line \
    message "Limit number of attempts to be made by SHELXD (NTRY-keyword)" \
    label "Limit number of tries to"  \
    widget NTRY -width 5 -oblig \
    label "."

#-----------------------------------------------------------------------------------

  OpenFolder 4 closed

  CreateLine line \
    message "Set Minimum E values to be used in SHELXD (ESEL)" \
    widget ESEL_ONOFF -toggleon\
    label "Mimimum E-value : "  \
    widget ESEL_EMIN -width 5

  CreateLine line \
    message "Set the random number seed, useful for reproducing identical results (SEED)" \
    widget SEED_ONOFF -toggleon\
    label "Random number SEED :"  \
    widget SEED_NRAND -width 7

  CreateLine line \
    message "Set the shortest distance allowed between atoms" \
    label "Minimum allowed distance between atoms : "  \
    widget MDIS_DM -width 5 \
    label "\u00c5" \
    toggle_display SHELX_MODE open DIRECT

  CreateLine line \
    message "Set the shortest distance allowed between atoms" \
    label "Minimum allowed distance between atoms : "  \
    widget MDIS_HA -width 5 \
    label "\u00c5" \
    toggle_display SHELX_MODE open HEAVY_ATOM

  CreateLine line \
    message "Set this to -0.1 to allow atoms on special positions." \
    label "Minimum allowed distance between symmetry equivalents : "  \
    widget MDEQ -width 5 \
    label "\u00c5"

#  CreateLine line \
#    message "Define how many steps of peak list optimization per round (PLOP)" \
#    label "Number of steps for peak list optimization : " \
#    widget PLOP_STEPS -width 5 \
#    toggle_display SHELX_MODE open DIRECT

}
