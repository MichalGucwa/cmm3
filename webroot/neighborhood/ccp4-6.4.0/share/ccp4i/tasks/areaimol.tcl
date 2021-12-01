#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# ======================================================================
# areaimol.tcl --
#
# CCP4Interface 
#
# =======================================================================

#CCP4i_cvs_Id $Id$

# PDB utils required for "PdbGetChain"
source [SearchPath TOP utils pdb_utils.tcl]

#-----------------------------------------------------------------------
proc areaimol_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  # Set up parameters for different protocols
  set protocol [GetValue $arrayname AREAIMOL_PROTOCOL]
  switch -- $protocol {
    ASA {
      # Accessible area calculation
      set array(DIFFMODE) "OFF"
    }
    IMOL_OLIG {
      # Differences due to oligomer formation
      set array(DIFFMODE) "IMOL"
      set array(USE_TRANSLATIONS) 0
    }
    IMOL_XTAL {
      # Differences due to xtallographic contacts
      set array(DIFFMODE) "IMOL"
      set array(SYMM_SOURCE) "SPGRP"
      set array(USE_TRANSLATIONS) 1
    }
    LIGAND {
      # Differences due to ligand binding
      set array(DIFFMODE) "COMPARE"
      # User specifies chains for ligand - work out which
      # chains define the protein
      PdbGetChains [GetFullFileName0 $arrayname XYZIN] pdb_chains chain_res
      set ligand_chains [split $array(LIGAND_CHAINS) ", "]
      set protein_chains {}
      foreach chain $pdb_chains {
	if { [lsearch $ligand_chains $chain] < 0 } {
	   lappend protein_chains $chain
	}
      }
      if { [llength $protein_chains] < 1 } {
        # No chains to define protein - nothing to do
        WarningMessage "Cannot generate list of chains
to define the protein!

Please check the input PDB file and
the ligand or subunit definition."
        return 0
      } elseif { [llength $protein_chains] == [llength $pdb_chains] } {
        WarningMessage "None of the chains defining the
ligand or subunit are present in the
input PDB file.

Please check the input PDB file and
the ligand or subunit definition."
        return 0
      }
      set array(PROTEIN_CHAINS) $protein_chains
    }
    MOLECULES {
      # Area differences between two molecules defined by the
      # user (this is a variation on the LIGAND mode above)
      set array(DIFFMODE) "COMPARE"
      PdbGetChains [GetFullFileName0 $arrayname XYZIN] pdb_chains chain_res
      if { $array(NMOLS) < 2 } {
        WarningMessage "You need to define at least two
molecules in order to get area
differences between them."
        return 0
      }
      for { set i 1 } { $i <= $array(NMOLS) } { incr i } {
	if { [string trim $array(MOL_NAME,$i)] == "" } {
	  set array(MOL_NAME,$i) "Molecule$i"
	}
	set mol_chains [split $array(MOL_CHAINS,$i) ", "]
	if { [llength $mol_chains] == 0 } {
          WarningMessage "Error in definition of molecule $i:

No chains supplied for this molecule

Please check the molecule definitions."
          return 0
        }
	foreach chn $mol_chains {
	  if { [set k [lsearch -exact $pdb_chains $chn]] < 0 } {
	    # Chain no found - either because it doesn't exist
	    # or because it is duplicated between molecules
	    WarningMessage "Error in definition of molecule $i:

Problem with chain $chn

This chain is either not in the input PDB
file, or is defined in more than one
molecule.

Please check the molecule definitions."
            return 0
	  }
	  set pdb_chains [lreplace $pdb_chains $k $k]
	}
	# Checks completed
      }
    }
    WATERS {
      # Differences due to presence of waters
      set array(DIFFMODE) "WATERS"
    }
    FILES {
      # Differences between coordinates in two different files
      set array(DIFFMODE) "COMPARE"
    }
  }

  # Files
  set array(INPUT_FILES) "XYZIN"
  if { $array(WRITE_OUTPUT_FILE) } {
    set array(OUTPUT_FILES) "XYZOUT"
  } else {
    set array(OUTPUT_FILES) ""
  }
  if { [StringSame [GetValue $arrayname AREAIMOL_PROTOCOL] FILES] } {
    append array(INPUT_FILES) " XYZIN2"
  }
  return 1
}

# procedure which is run automatically before drawing the interface
# used to set up variables, menus etc
#---------------------------------------------------------------------
proc areaimol_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0  $typedefVar typedef
  upvar #0 $arrayname array

  DefineMenu _areaimol_protocol [list "accessible surface area" \
          "area differences due to oligomer formation" \
	  "area differences due to crystal contacts" \
	  "area differences due to ligand/subunit binding" \
	  "pairwise area differences between molecules" \
          "area differences for waters" \
          "area differences between coordinates in two files"] \
          [list ASA IMOL_OLIG IMOL_XTAL LIGAND MOLECULES WATERS FILES]

  DefineMenu _areaimol_mode [list "protein atoms only" \
          "waters only (treated as solvent)" \
          "waters only (treated as protein)"] \
          [list NOHOH HOH HOHALL]

  DefineMenu _areaimol_symm_source [ list "list of operators" \
          "spacegroup" ] \
          [ list LIST SPGRP ]

  return 1
}

# procedure to draw task window
#---------------------------------------------------------------------
proc areaimol_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
        "Calculate Accessible Surface Areas" "AreaIMol" \
        [ list "Molecule Definitions" \
        "Ligand Definition" \
        "Intermolecular Contacts" \
        "Crystallographic Contacts" \
        "Van der Waals Radii" \
	"Other Parameters" \
        "Output Options" \
	] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "areaimol"

#=PROTOCOL==============================================================

  OpenFolder protocol

  CreateTitleLine line TITLE

  CreateLine line \
        help diffmode \
        message "Choose AreaIMol protocol (DIFFMODE)" \
	label "Run AreaIMol to calculate" \
	widget AREAIMOL_PROTOCOL \
            -command "areaimol_update_imol $arrayname"

  OpenSubFrame frame -toggle_display AREAIMOL_PROTOCOL hide [list IMOL_OLIG IMOL_XTAL]

  CreateLine line \
        help mode \
        message "Choose whether protein or solvent atoms will be used (MODE)" \
        label "Calculate areas for" \
        widget WATERS_MODE \
        toggle_display AREAIMOL_PROTOCOL open [list ASA]

  CreateLine line \
        help smode \
        message "Account for intermolecular contacts (SMODE)" \
        widget SYMMETRY_MODE \
            -command "areaimol_update_imol $arrayname" \
        label "Generate symmetry-related atoms to include intermolecular contacts"

  CloseSubFrame

#=FILES================================================================ 

  OpenFolder file

  # Input Coordinate File
  CreateInputFileLine line \
        "Enter name of input coordinate file (PDB)" \
	"XYZIN" \
	XYZIN DIR_XYZIN \
	-fileout XYZOUT DIR_XYZOUT "_areaimol" \
        -setfileparam space_group_name SPACE_GROUP

  CreateInputFileLine line \
        "Enter name of second input coordinate file (PDB)" \
	"XYZIN2" \
	XYZIN2 DIR_XYZIN2 \
        -toggle_display AREAIMOL_PROTOCOL open [list FILES]

  # Output Coordinate File
  OpenSubFrame frame -toggle_display AREAIMOL_PROTOCOL hide MOLECULES

  CreateLine line \
	help output \
	message "Write ASA for each atom to an output PDB file? (OUTPUT keyword)" \
	widget WRITE_OUTPUT_FILE \
	label "Write an output PDB file with accessible areas on each atom" \
	toggle_display AREAIMOL_PROTOCOL open [list OFF]

  CreateLine line \
	help output \
	message "Write ASA for each atom to an output PDB file? (OUTPUT keyword)" \
	widget WRITE_OUTPUT_FILE \
	label "Write an output PDB file with accessible area differences on each atom" \
	toggle_display AREAIMOL_PROTOCOL hide [list OFF]

  CreateOutputFileLine line \
	"Output coordinate file - B factor column will contain ASA for each atom" \
	"PDB out" \
	XYZOUT DIR_XYZOUT \
	-toggle_display WRITE_OUTPUT_FILE hide [list 0]

  CloseSubFrame

#-------------------------------------------------- DEFINE MOLECULES
# Options to select chains from the input PDB file to define the molecule(s)

    OpenFolder 1 AREAIMOL_PROTOCOL open [list MOLECULES] hide

    CreateExtendingFrame NMOLS areaimol_define_molecule \
      "Define molecules in terms of chains in the PDB file" \
      "Add molecule definition" [ list MOL_CHAINS ]

#-------------------------------------------------- DEFINE LIGAND
# Options to select chains from the input PDB file to define the ligand(s)

    OpenFolder 2 AREAIMOL_PROTOCOL open [list LIGAND] hide

    CreateLine line \
      message "Give a comma-separated list of chains to include e.g. A,B,S" \
      label "Ligand or subunit consists of chains" \
      widget LIGAND_CHAINS -width 15 \
      label "from the input file"

#-------------------------------------------------- INTERMOLECULAR CONTACTS
# Set up for intermolecular contacts (including oligomer contacts)

    OpenFolder 3 IMOL_CONTACTS hide { NONE IMOL_XTAL } open

    CreateLine line \
      help symmetry \
      message "Select method for entering symmetry operations" \
      label "Use" \
      widget SYMM_SOURCE \
      label "to define symmetry operations" \
      toggle_display IMOL_CONTACTS open { IMOL }

    CreateLine line \
      help symmetry \
      message "Select method for entering symmetry operations" \
      label "Use" \
      widget SYMM_SOURCE \
      label "to define symmetry operations for generating oligomers" \
      toggle_display IMOL_CONTACTS open { IMOL_OLIG }

    CreateLine line \
      help symmetry \
      message "Enter spacegroup name or number (SYMMETRY)" \
      label "Use spacegroup:" \
      widget SPACE_GROUP \
      toggle_display SYMM_SOURCE open { SPGRP }

    OpenSubFrame frame \
          -toggle_display SYMM_SOURCE open { LIST }

    CreateLine line \
      label "List of individual symmetry operators:"

    CreateExtendingFrame NSYMM areaimol_add_symop \
      "Add to the list of individual symmetry operations" \
      "Add symmetry operation" [ list SYMOP ]

    CloseSubFrame

    CreateLine line \
      help trans \
      message "Generate the crystal lattice (TRANS keyword)" \
      widget USE_TRANSLATIONS \
      label "Include all possible lattice translations" \
      toggle_display IMOL_CONTACTS open { IMOL } 

#-------------------------------------------------- CRYSTALLOGRAPHIC CONTACTS
# Set up for intermolecular contacts within crystal lattice

    OpenFolder 4 AREAIMOL_PROTOCOL open [list IMOL_XTAL] hide

    CreateLine line \
      help symmetry \
      message "Specify spacegroup which defines crystal symmetry (SYMM)" \
      label "Generate crystallographic contacts using symmetry operators of spacegroup" \
      widget SPACE_GROUP

#-------------------------------------------------- ATOMIC RADII
# (Re)define Van der Waals radii for atoms

    OpenFolder 5 closed

    CreateLine line \
       label "Add or change the Van der Waals radius associated with an atom type" \
         -italic

    CreateExtendingFrame N_ATOMS areaimol_define_atom \
      "Set Van der Waals radii for specific atom types" \
      "Add atom" \
      [list ATOM_NAME ATOM_NUMBER ATOM_RADIUS]

#-------------------------------------------------- OPTIONAL PARAMETERS
# This folder sets the optional parameters

    OpenFolder 6 closed

    CreateLine line \
            help probe \
	    message "Change the probe radius used in the calculation (PROBE)" \
	    label "Radius of probe solvent molecule is" \
	    widget PROBE_RADIUS \
	    label "Angstroms"

    CreateLine line \
            help pntden \
	    message "Number of surface points per surface area (PNTDEN)" \
	    label "Use" \
	    widget PNTDEN \
	    label "surface points per square Angstrom in accessible area calculations"

#-------------------------------------------------- OUTPUT OPTIONS
# This folder has the settings for controlling the output

    OpenFolder 7 closed

  CreateLine line \
      help report \
      message "Set whether to also report contact areas in logfile" \
      widget REPORT_CONTACT \
      label "Report contact area calculations"

  CreateLine line \
      help report \
      message "Set whether to report areas per residue" \
      widget REPORT_RESAREA \
      label "Report area for each residue"

}

#-----------------------------------------------------------------------
proc areaimol_update_imol { arrayname } {
#-----------------------------------------------------------------------
# If protocol is "ASA" and intermolecular contacts are (un)selected then
# change the visibility of the "Intermolecular contacts" folder
  upvar #0 $arrayname array
  set array(IMOL_CONTACTS) "NONE"
  set areaimol_protocol [GetValue $arrayname AREAIMOL_PROTOCOL]
  if { $areaimol_protocol == "ASA" \
          || $areaimol_protocol == "LIGAND" \
          || $areaimol_protocol == "MOLECULES" } {
    if { $array(SYMMETRY_MODE) == 1 } {
      set array(IMOL_CONTACTS) "IMOL"
    }
  } elseif { $areaimol_protocol == "IMOL_XTAL"  \
	  || $areaimol_protocol == "IMOL_OLIG" } {
    set array(IMOL_CONTACTS) $areaimol_protocol
  }
  return
}

#-----------------------------------------------------------------------
proc areaimol_define_atom { arrayname counter } {
#-----------------------------------------------------------------------
# Draw one line of the "define atom" extending frame
  CreateLine line \
      help atom \
      message "Element name (as it appears in columns 13-14 of the pdb file) (ATOM)" \
      label "Atom name" widget ATOM_NAME \
      message "Corresponding atomic number from the periodic table (ATOM)" \
      label "(atomic number" widget ATOM_NUMBER \
      message "Radius in Angstroms to use in the calculation for this atom type (ATOM)" \
      label ") van der Waals radius" widget ATOM_RADIUS
}

#---------------------------------------------------------------------
proc areaimol_add_symop { arrayname counter } {
#---------------------------------------------------------------------
# Draw one line of the "define symmetry operation" extending frame

  CreateLine line \
      message "Add a symmetry operation in format eg X+1/2, Y+1/2, -Z (SYMM keyword)" \
      help symmetry \
      label "Operation" \
      label $counter \
      widget SYMOP -width 20
}

#---------------------------------------------------------------------
proc areaimol_define_molecule { arrayname counter } {
#---------------------------------------------------------------------
# Draw one line of the "define molecule" extending frame

    CreateLine line \
      message "Enter a name to identify this molecule" \
      label "Molecule \#$counter: name" \
      widget MOL_NAME \
      message "Give a comma-separated list of chains to include e.g. A,B,S" \
      label "consists of chains" \
      widget MOL_CHAINS -width 15
}
