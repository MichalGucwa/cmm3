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
# watertidy.tcl --
#
# CCP4Interface 
#
# =======================================================================

# procedure which is run automatically before drawing the interface
# used to set up variables, menus etc
#---------------------------------------------------------------------
proc watertidy_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array
  upvar #0 $typedefVar typedef

  DefineMenu _watertidy_symm_mode [ list "list of operators" \
                                       "spacegroup" ] \
                                [ list LIST \
                                       SPGRP ]

  return 1
}

#---------------------------------------------------------------------
proc watertidy_run { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [regexp SPGRP [GetValue $arrayname SYMM_MODE] ] && 
       ![IfSet $array(SPACE_GROUP)] }  {
      WarningMessage "You must enter a space group before running the program" 
      return 0
  }
  if {![IfSet $array(WATIN_ID)] }  {
      WarningMessage "You must enter a water chain id before running the program" 
      return 0     
  } 

  return 1
 
}

# procedure for adding to the list of symmetry operations
#---------------------------------------------------------------------
proc watertidy_add_symop { arrayname counter } {
#---------------------------------------------------------------------

  CreateLine line \
    message "Add a symmetry operator in format eg X+1/2, Y+1/2, -Z (SYMM keyword)" \
    help symm \
    label "Operator" \
    label $counter \
    widget SYMOP  -width 30

}

#---------------------------------------------------------------------
proc watertidy_radius { arrayname counter } {
#---------------------------------------------------------------------

  CreateLine line \
        help radii \
        message "Enter search radii for atom types (RADII)" \
        label "Atom type" \
        widget ATOMTYPE \
        label "search radius" \
        widget ATOMRADIUS

}



# procedure for adding chains to the list
#---------------------------------------------------------------------
proc watertidy_add_chain { arrayname counter } {
#---------------------------------------------------------------------
  CreateLine line \
        help chnid \
        message "Host chain identifier" \
        label "Protein chain id" \
        widget CHAIN_ID -width 5 -oblig \
        label "residue range" \
        widget CHAIN_RES_1 \
	label to \
	widget CHAIN_RES_2


#        message "Output water chain id as it will appear in output file" \
#        label "chain id for nearby waters" \
#        widget WATOUT_ID -width 5 -oblig

}
# procedure to draw task window
#---------------------------------------------------------------------
proc watertidy_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

 if { [CreateTaskWindow $arrayname  \
        "Rationalise waters at end of refinement" "Watertidy" \
        [ list "Symmetry for Distang and Watertidy" \
               "Search radii for atom types (Distang)" \
               "Chain details (pdb file input/output)" \
               "Other parameters" ] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "watertidy"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
        help shell \
        message "Default mode is to run three cycles to find shells 1 to 3" \
        label "Run multiple cycles to find water in shells" \
        widget FIRST_SHELL \
	label to \
	widget LAST_SHELL

#=FILES================================================================ 

  OpenFolder file

  CreateInputFileLine line \
        "Enter name of input pdb file" \
        "PDB in" \
        XYZIN DIR_XYZIN \
	-setfileparam space_group_name SPACE_GROUP \
        -fileout XYZOUT DIR_XYZOUT _watertidy \
	-command  "WaterTidyReadPdb $arrayname"

  CreateOutputFileLine line \
        "Enter output pdb file name" \
        "PDB out" \
        XYZOUT DIR_XYZOUT

#--------------------------------------------------SYMMETRY folder
  OpenFolder 1 

  CreateLine line \
        message "Select method for entering symmetry operations" \
        label "Use" \
        widget SYMM_MODE \
        label "to define symmetry operations"

  CreateLine line \
        help symmetry \
        message "Enter spacegroup name or number (SPACEGROUP)" \
        label "Spacegroup:" \
        widget SPACE_GROUP -oblig \
        toggle_display SYMM_MODE open [ list SPGRP ]

  OpenSubFrame frame \
        -toggle_display SYMM_MODE open [ list LIST ]

  CreateLine line \
        label "List of individual symmetry operators:" -italic

  CreateExtendingFrame NSYMM watertidy_add_symop \
        "Add to the list of individual symmetry operations" \
        "Add symmetry operation" \
        [ list SYMOP ]
   
  CloseSubFrame
#--------------------------------------------------SEARCH RADII
# This folder sets the radii for the contacts routine

  OpenFolder 2  closed

  CreateExtendingFrame N_ATOM_RADII watertidy_radius \
    "Set atomic radius" \
    "Add new atom type" \
    [list  ATOMTYPE ATOMRADIUS ]
  
    
#--------------------------------------------------CHAIN IDS
# This folder sets the chain ids

  OpenFolder 3

  CreateExtendingFrame NHOST_CHAIN watertidy_add_chain \
        "Add to the list of host chains" \
        "Add host chain" \
        [ list CHAIN_ID CHAIN_RES_1 CHAIN_RES_2 WATOUT_ID ]

  CreateLine line \
        help watid \
        message "Chain identifier for unassigned waters" \
        label "Water chain id as it appears in the input file: " \
        widget WATIN_ID -oblig

#--------------------------------------------------OTHER PARAMTERS
# This folder sets the Keys ACCEPT, HBOND and OCCW. 

  OpenFolder 4 closed

  CreateLine line \
        help accept \
        message "Specify extra acceptors: single character atom types" \
        label "Specify extra acceptors: " \
        widget ACCEPTORS \
        label "(default O N )"

  CreateLine line \
        help hbond \
        message "Maximum number of waters bonded to one atom" \
        label "Maximum number of H-bonds per atom: " \
        widget HBOND \
        label "(4)"

  CreateLine line \
        help occw \
        message "Occupancy for secondary sites. If 0.0 not output." \
        label "Occupancy for secondary sites: " \
        widget OCCW \
        label "(0.01)"

}

#-------------------------------------------------------------------
proc WaterTidyReadPdb { arrayname } {
#-------------------------------------------------------------------
  upvar #0 $arrayname array

  source  [SearchPath TOP utils pdb_utils.tcl]

  if { [PdbGetChains [GetFullFileName0 $arrayname XYZIN]  chains chain_res -nowat] \
      && [llength $chains] > 0  } {
    set increment [expr [llength $chains] - $array(NHOST_CHAIN) ]
    update_extendingframe watertidy_add_chain 0 $arrayname NHOST_CHAIN \
                $array(NHOST_CHAIN) $increment 1
    for { set n 1 } { $n <= $array(NHOST_CHAIN) } { incr n } {
       set array(CHAIN_ID,$n) [lindex $chains [expr $n -1] ]
       set array(CHAIN_RES_1,$n) [lindex [lindex $chain_res [expr $n -1] ] 0]
       set array(CHAIN_RES_2,$n) [lindex [lindex $chain_res [expr $n -1] ] 1]
       set_field_colour $arrayname CHAIN_ID,$n 1
    }
  }

}

