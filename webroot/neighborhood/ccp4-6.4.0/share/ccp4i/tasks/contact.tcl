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
# contact.tcl --
#
# CCP4Interface 
#
# =======================================================================

# procedure which is run automatically before drawing the interface
# used to set up variables, menus etc
#---------------------------------------------------------------------
proc contact_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0  $typedefVar typedef
  upvar #0 $arrayname array

# List of programs. Try to get unified task interface to all contact-finding
# programs.

  DefineMenu _task_prg [ list "NCONT" \
                                 "CONTACT / ACT" ] \
                                [ list NCONT \
                                       CONTACT ]

# Overall mode-list to control interface - updated from individual
# contact and ncont lists

  DefineMenu _task_mode [ list "running ncont" \
                                  "all" \
                                  "inter chain" \
                                  "inter residue" \
                                  "metal-ligand"  \
				  "intermolecular (symmetry generated)" ] \
                             [ list NCONT \
                                    ALL \
                                    ISUB \
                                    IRES \
                                    METAL \
				    AUTO ]

# Keyword CELLS of NCONT defines extent of search

  DefineMenu _ncont_mode   [ list "file contents only" \
                                  "primary unit cell" \
                                  "+/- one unit cells" \
				  "+/- two unit cells" \
				  "symmetry contacts only" \
				  "all interchain contacts" ] \
                             [ list OFF \
                                    0 \
                                    1 \
                                    2 \
                                    SYMM \
				    INTER ]

# The contact_mode are the different MODE keywords
# nb except METAL which seems to replace MODE

  DefineMenu _contact_mode [ list "all" \
                                  "inter chain" \
                                  "inter residue" \
                                  "metal-ligand"  \
				  "intermolecular (symmetry generated)" ] \
                             [ list ALL \
                                    ISUB \
                                    IRES \
                                    METAL \
				    AUTO ]

# The contact_symm_mode is the method for entering the symmetry operations
# in modes IMOL or AUTO, or for METAL option

  DefineMenu _contact_symm_mode [ list "list of operators" \
                                       "spacegroup" ] \
                                [ list LIST \
                                       SPGRP ]

# The contact_type defines whether we use ATOMs or RESIDUEs as the source/
# target

  DefineMenu _contact_type [ list "selected range of atoms" \
                                  "selected range of residues"  \
				  "all residues in PDB" ] \
                           [ list ATOMS RESIDUES ALL ]
 
# The contact_search defines the search volume for mode AUTO

  DefineMenu _contact_search [ list "one" \
                                    "two" ] \
                             [ list SMALL \
                                    BIG ] 

  DefineMenu _contact_atype [ list "any atom type" \
                                   "atom type O and N" \
                                   "Calpha atoms" ] \
                            [ list ALL \
                                   ONS \
                                   CA ]

# procedure must return sucess code (1) for drawing task window to continue
  return 1
}

# procedure for adding to the list of symmetry operations
#---------------------------------------------------------------------
proc contact_add_symop { arrayname counter } {
#---------------------------------------------------------------------

  CreateLine line \
    message "Add a symmetry operation in format eg X+1/2, Y+1/2, -Z (SYMM keyword)" \
    help symm \
    label "Operation" \
    label $counter \
    widget SYMOP \
    label "Title:" \
    widget SYMTIT

}

#-----------------------------------------------------------------
proc contact_update_task_mode { arrayname } {
#-----------------------------------------------------------------
  upvar #0 $arrayname array

  if { [GetValue $arrayname TASK_PRG] == "NCONT" } {
    set array(TASK_MODE) "NCONT" 
    contact_update_atom_selection $arrayname
  } else {
    set array(TASK_MODE) $array(CONTACT_MODE)
  }
}

#-----------------------------------------------------------------
proc contact_update_atom_selection  { arrayname } {
#-----------------------------------------------------------------
  upvar #0 $arrayname array

  # chain IDs or wild card
  if {$array(SOURCE_CHN) != ""} {
    set array(NCONT_SOURCE) "$array(SOURCE_CHN)"
  } else {
    set array(NCONT_SOURCE) "*"
  }

  # residue numbers or wild card
  if {$array(SOURCE_NUMR1) != "" && $array(SOURCE_NUMR2) != ""} {
    set array(NCONT_SOURCE) "$array(NCONT_SOURCE)/$array(SOURCE_NUMR1)-$array(SOURCE_NUMR2)"
  } elseif {$array(SOURCE_NUMR1) != ""} {
    set array(NCONT_SOURCE) "$array(NCONT_SOURCE)/$array(SOURCE_NUMR1)"
  } else {
    set array(NCONT_SOURCE) "$array(NCONT_SOURCE)/*"
  }

  # atom name and element type
  if {$array(SOURCE_ANAME) != "" || $array(SOURCE_ELEM) != ""} {
    set array(NCONT_SOURCE) "$array(NCONT_SOURCE)/"
  }
  if {$array(SOURCE_ANAME) != ""} {
    set array(NCONT_SOURCE) "$array(NCONT_SOURCE)$array(SOURCE_ANAME)"
  }
   if {$array(SOURCE_ELEM) != ""} {
    set array(NCONT_SOURCE) "$array(NCONT_SOURCE)\[$array(SOURCE_ELEM)\]"
  }
   

  # chain IDs or wild card
  if {$array(TARGET_CHN) != ""} {
    set array(NCONT_TARGET) "$array(TARGET_CHN)"
  } else {
    set array(NCONT_TARGET) "*"
  }

  # residue numbers or wild card
  if {$array(TARGET_NUMR1) != "" && $array(TARGET_NUMR2) != ""} {
    set array(NCONT_TARGET) "$array(NCONT_TARGET)/$array(TARGET_NUMR1)-$array(TARGET_NUMR2)"
  } elseif {$array(TARGET_NUMR1) != ""} {
    set array(NCONT_TARGET) "$array(NCONT_TARGET)/$array(TARGET_NUMR1)"
  } else {
    set array(NCONT_TARGET) "$array(NCONT_TARGET)/*"
  }

  # atom name and element type
  if {$array(TARGET_ANAME) != "" || $array(TARGET_ELEM) != ""} {
    set array(NCONT_TARGET) "$array(NCONT_TARGET)/"
  }
  if {$array(TARGET_ANAME) != ""} {
    set array(NCONT_TARGET) "$array(NCONT_TARGET)$array(TARGET_ANAME)"
  }
   if {$array(TARGET_ELEM) != ""} {
    set array(NCONT_TARGET) "$array(NCONT_TARGET)\[$array(TARGET_ELEM)\]"
  }

}

#------------------------------------------------------------------------
proc contact_update_chain_list { arrayname } {
#------------------------------------------------------------------------
# Update the chain list (CHAIN_LIST) 
  upvar #0 $arrayname array

  if { [llength [info procs PdbGetChains]] <= 0 } {
	source [SearchPath TOP utils pdb_utils.tcl] }
  if { ![file exists [GetFullFileName0 $arrayname XYZIN]]  ||
   ![PdbGetChains [GetFullFileName0 $arrayname XYZIN] chains chainranges] } {
	return 0 }

  set array(CHAIN_LIST) $chains

}

# procedure to draw task window
#---------------------------------------------------------------------
proc contact_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
        "Compute contacts in protein structures" "Contact/Act" \
        [ list "Symmetry operations" \
               "Metal contact parameters" \
               "Contact distances" \
               "Atom selection" \
	       "B-factor Monitoring" \
	       "Other NCONT parameters" ] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "ncont"

# Special trap for backwards-compatibility
# If you are re-running an old contact job, from before the
# addition of ncont, we need to set new parameters correctly.
# Check for obsolete parameters (these are not in latest .def file)
  if { [ElementExists $arrayname CONTACT_PRG] && 
       [ElementExists $arrayname CONTACT_TYPE] } {
    if { $array(CONTACT_PRG) != "" } {set array(TASK_PRG) $array(CONTACT_PRG)}
    if { $array(CONTACT_TYPE) != "" } {set array(CONTACT_MODE) $array(CONTACT_TYPE)}
    contact_update_task_mode $arrayname
  }

  CreateLineTemplate NCONT_ATOM_SEL { 0.0 0.17 0.31 0.41 0.50 0.54 0.63 0.75 0.82 0.92}

# If we are re-running, need to update chain list from XYZIN
  contact_update_chain_list $arrayname

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
        message "Select type of contacts to find (CELLS)" \
        help cells \
        label "Use" \
        widget TASK_PRG \
           -command "contact_update_task_mode $arrayname" \
        label "to find contacts in" \
        widget NCONT_MODE \
        toggle_display TASK_PRG open [ list NCONT ] hide

  CreateLine line \
        message "Select type of contacts to find (MODE)" \
        help mode \
        label "Use" \
        widget TASK_PRG \
           -command "contact_update_task_mode $arrayname" \
        label "program to look for" \
        widget CONTACT_MODE \
           -command "contact_update_task_mode $arrayname" \
        label "contacts" \
        toggle_display TASK_PRG open [ list CONTACT ] hide

#=FILES================================================================ 

  OpenFolder file

  CreateInputFileLine line \
        "Enter name of input pdb file" \
        "PDB in" \
        XYZIN DIR_XYZIN \
	-setfileparam space_group_name SPACE_GROUP \
	-command "contact_update_chain_list $arrayname"

#--------------------------------------------------SYMMETRY folder
# This folder sets the symmetry operations or spacegroup
# Only needed in modes AUTO or METAL in CONTACT.
# Used in all cases for ACT (mode ALL).
# Used in all cases for NCONT.

  OpenFolder 1 TASK_MODE \
            open [ list NCONT AUTO METAL ALL ] hide 

  OpenSubFrame frame \
        -toggle_display TASK_MODE open [list AUTO METAL ] 

  CreateLine line \
        message "Select method for entering symmetry operations" \
        label "Use" \
        widget SYMM_MODE \
        label "to define symmetry operations"

  CreateLine line \
        help spacegroup \
        message "Enter spacegroup name or number (SPACEGROUP)" \
        label "Spacegroup:" \
        widget SPACE_GROUP \
        toggle_display SYMM_MODE open [ list SPGRP ]

  OpenSubFrame frame \
        -toggle_display SYMM_MODE open [ list LIST ]

  CreateLine line \
        label "List of individual symmetry operators:"

  CreateExtendingFrame NSYMM contact_add_symop \
        "Add to the list of individual symmetry operations" \
        "Add symmetry operation" \
        [ list SYMOP SYMTIT ]

  CloseSubFrame

  CreateLine line \
        help bigcontact \
        message "Select search volume for crystallographic contacts (BIGSEARCH)" \
        label "Search up to" \
        widget SEARCH_VOL \
        label "lattice vectors in all directions for crystallographic contacts" \
        toggle_display TASK_MODE open [ list AUTO ]

  CloseSubFrame

  OpenSubFrame frame \
        -toggle_display TASK_MODE open [ list ALL ] 

  CreateLine line \
        help spacegroup \
        message "Enter spacegroup name or number (SPACEGROUP)" \
        label "Spacegroup:" \
        widget SPACE_GROUP

  CloseSubFrame

  OpenSubFrame frame \
        -toggle_display TASK_MODE open [ list NCONT ] 

  CreateLine line \
        help symmetry \
        message "Enter spacegroup name (SYMMETRY)" \
        label "Spacegroup:" \
        widget SPACE_GROUP \
        toggle_display NCONT_MODE hide [list OFF]

  CreateLine line \
        help symmetry \
        label "no symmetry information required" \
        toggle_display NCONT_MODE open [list OFF]

  CloseSubFrame
 
#--------------------------------------------------METAL folder
# This folder sets the parameters for the METAL search

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "contact"

  OpenFolder 2 TASK_MODE open [ list METAL ] hide

  CreateLine line \
        help metal \
        message "Select atom name for metal of interest" \
        label "Look for contacts between metal atom" \
        widget METAL_NAME \
        message "Set distance for flagging metal-ligand contacts" \
        label "with metal-ligand distance" \
        widget METAL_LIGAND_DIST

#--------------------------------------------------LIMITS folder
# This folder sets the limits for defining the contacts

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "ncont"

  OpenFolder 3 

  CreateLine line \
        help limits \
        message "Set minimum and maximum distance for contact to be output (LIMITS)" \
        label "Report contact distances between minimum" \
        widget MIN_DIST \
        label "and maximum" \
        widget MAX_DIST -oblig

  CreateLine line \
        message "Set value for flagging close contacts (ACT)" \
        label "Flag contacts closer than" \
        widget ACT_SHORT \
        toggle_display TASK_MODE open [list ALL ]

#--------------------------------------------------FROM/TO folder
# This folder selects which atoms/residues will be used
# as source and target atoms for the contact calculations

  OpenFolder 4 TASK_MODE open [list NCONT ISUB IRES AUTO METAL ] hide

  OpenSubFrame frame \
        -toggle_display TASK_MODE open [list NCONT ] 

  CreateLine line \
    label "Write atom selection directly (for detailed control): " -italic

  CreateLine line \
    label "Find contacts between " \
    message "Use atom selection syntax, see documentation" \
    widget NCONT_SOURCE \
    label " and " \
    widget NCONT_TARGET

  CreateLine line \
    label "or use boxes (and optionally edit above): " -italic

  CreateLine line \
    label "(available chains are: " \
    varlabel CHAIN_LIST \
    label ")"

  CreateLine line \
    label "Source: chain(s) " \
    message "Enter single chain identifier or comma-separated list" \
    widget SOURCE_CHN \
    -command "contact_update_atom_selection $arrayname" \
    label " residues " \
    message "Enter first residue in range" \
    widget SOURCE_NUMR1 -width 7 \
    -command "contact_update_atom_selection $arrayname" \
    label " to " \
    message "Enter last residue in range" \
    widget SOURCE_NUMR2 -width 7 \
    -command "contact_update_atom_selection $arrayname" \
    label " atom name " \
    message "Enter atom name e.g. CG1 or leave blank" \
    widget SOURCE_ANAME -width 6 \
    -command "contact_update_atom_selection $arrayname" \
    label " element " \
    message "Enter element name e.g. C or leave blank" \
    widget SOURCE_ELEM -width 4 \
    -command "contact_update_atom_selection $arrayname" \
    format  template NCONT_ATOM_SEL

  CreateLine line \
    message "Atom selection string will be auto-generated from your choices" \
    label "Target: chain(s) " \
    message "Enter single chain identifier or comma-separated list" \
    widget TARGET_CHN \
    -command "contact_update_atom_selection $arrayname" \
    label " residues " \
    message "Enter first residue in range" \
    widget TARGET_NUMR1 -width 7 \
    -command "contact_update_atom_selection $arrayname" \
    label " to " \
    message "Enter last residue in range" \
    widget TARGET_NUMR2 -width 7 \
    -command "contact_update_atom_selection $arrayname" \
    label " atom name " \
    message "Enter atom name e.g. CG1 or leave blank" \
    widget TARGET_ANAME -width 6 \
    -command "contact_update_atom_selection $arrayname" \
    label " element " \
    message "Enter element name e.g. C or leave blank" \
    widget TARGET_ELEM -width 4 \
    -command "contact_update_atom_selection $arrayname" \
    format  template NCONT_ATOM_SEL

  CloseSubFrame

  OpenSubFrame frame \
        -toggle_display TASK_MODE open [list ISUB IRES AUTO METAL ] 

  CreateLine line \
    label "Find contacts between " \
    widget SOURCE_ATYPE \
    label "in the range.."


  CreateLine line \
        message "Select source atoms (FROM)" \
        widget SOURCE_TYPE \
        label "from" \
        widget SOURCE_NUMA1 -oblig \
        label "to" \
        widget SOURCE_NUMA2 -oblig \
        toggle_display SOURCE_TYPE open [ list ATOMS ]


  CreateLine line \
        message "Select source residues (FROM)" \
        widget SOURCE_TYPE \
        label "chain" \
        widget SOURCE_CHN -width 5 -oblig \
        label residue \
        widget SOURCE_NUMR1 -oblig \
        label "to" \
        widget SOURCE_NUMR2 -oblig \
        toggle_display SOURCE_TYPE open [ list RESIDUES ]

   CreateLine line \
        message "Select source residues (FROM)" \
        widget SOURCE_TYPE \
        toggle_display SOURCE_TYPE open ALL

  CreateLine line \
    label "and"  \
    widget TARGET_ATYPE \
    label "in the range.."


 CreateLine line \
        message "Select target atoms (TO)" \
        widget TARGET_TYPE \
        label "from" \
        widget TARGET_NUMA1 -oblig \
        label "to" \
        widget TARGET_NUMA2 -oblig \
        toggle_display TARGET_TYPE open [ list ATOMS ]

  CreateLine line \
        message "Select target atoms/residues (TO)" \
        widget TARGET_TYPE \
        label "in chain" \
         widget TARGET_CHN -width 5 -oblig \
        label residue \
        widget TARGET_NUMR1 -oblig \
        label "to" \
        widget TARGET_NUMR2 -oblig \
        toggle_display TARGET_TYPE open [ list RESIDUES ]

    CreateLine line \
        message "Select target atoms/residues (TO)" \
        widget TARGET_TYPE \
        toggle_display TARGET_TYPE open ALL

  CreateLine line \
        help hexclude \
        message "Choose whether to exclude hydrogens (HEXCLUDE)" \
        widget HEXCLUDE \
        label "Ignore all hydrogen atoms in the input file"

  CloseSubFrame

#--------------------------------------------------ACT-BMONI folder
# This folder should only be visible for those options which
# run the ACT program
# This controls parameters for B-value monitoring (BMONI keyword)

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "act"

  OpenFolder 5 TASK_MODE closed [list ALL ] hide

  CreateLine line \
    widget ACT_IFBMONI -toggleon \
    label "Monitor atoms with B-values greater than" \
    widget ACT_BMONI

#--------------------------------------------------NCONT folder

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "ncont"

  OpenFolder 6 TASK_MODE closed [list NCONT ] hide

  CreateLine line \
    widget SET_SEQDIST -toggleon \
    label "set minimum sequence distance along chain for contacts" \
    widget SEQDIST

  CreateLine line \
    widget SET_GEOM -toggleon \
    label "set cell parameters" \
    widget CELL_A \
    widget CELL_B \
    widget CELL_C \
    widget CELL_ALPHA \
    widget CELL_BETA \
    widget CELL_GAMMA

}
