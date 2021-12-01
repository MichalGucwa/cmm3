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
# pdbset.tcl --
#
# CCP4Interface 
#
# =======================================================================

#-------------------------------------------------------------------------
proc pdbset_run { arrayname } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array
  if { $array(NRENUMBER) > 0 } {
    for { set n 1 } { $n <= $array(NRENUMBER) } {incr n } {
      if [regexp RENAME [GetValue $arrayname EDIT_MODE,$n]] {
        set array(RENUMBER_MODE,$n) SAME }
    }
  }
  return 1
}

#---------------------------------------------------------------------
proc pdbset_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
upvar #0  $typedefVar typedef

set typedef(_pdbset_edit_mode) { menu { "Renumber residue" \
					"Rename chain" } \
				     { RENUMBER RENAME } }

set typedef(_pdbset_renumber) { menu { "starting at" 
				    "increment by" } 
				{ INIT INC } }

# List of programs. Try to get unified task interface to pdbset and pdbcur
set typedef(_task_prg) { menu { "pdbcur" \
				    "pdbset" } \
			     { PDBCUR PDBSET }}

# This is sum of _pdbcur_action and _pdbset_action  
# It seems necessary to control visibility of folders
set typedef(_task_action) {menu \
	{"summarise contents of coordinate file" \
	 "remove hydrogen atoms" \
	 "remove alternative conformations" \
	 "remove atoms with low/zero occupancy" \
         "remove anisotropic U's"\
         "rename chains and/or renumber residues" \
         "generate chains via symmetry operations" \
         "transform / shift or rotate structure" \
         "replace atoms or residues" \
         "perform selection for output PDB file" \
	 "average main and side chain Bfactors" } \
				   { SUMMARISE DELHYD MOSTPROB CUTOCC NOANISOU \
                                     RENAME \
                                     SYMMETRY ROTATE REPLACE SELECT AVERAGE } }

set typedef(_pdbcur_action) {menu \
	{"summarise contents of coordinate file" \
	 "remove hydrogen atoms" \
	 "remove alternative conformations" \
	 "remove atoms with low/zero occupancy"  \
	 "remove anisotropic U's" } \
				   { SUMMARISE DELHYD MOSTPROB CUTOCC NOANISOU} }

set typedef(_pdbset_action) {menu \
	{"rename chains and/or renumber residues" \
         "generate chains via symmetry operations" \
         "transform / shift or rotate structure" \
         "replace atoms or residues" \
         "perform selection for output PDB file" \
	 "average main and side chain Bfactors" } \
				   { RENAME SYMMETRY ROTATE \
                                     REPLACE SELECT AVERAGE } }

set typedef(_pdbset_bfactor) {menu {"All" "minimum" "maximum" \
	"Range" "if 0.0" } \
                                   { ALL MINIMUM MAXIMUM \
				   RANGE DEFAULT }}

set typedef(_pdbset_occupancy) {menu {"All" "Minimum" "Reset" \
	"if 0.0" } \
                                     {ALWAYS MINIMUM RESET \
				     DEFAULT }}

set typedef(_pdbset_repl_mode) { menu { "residue" \
					"atom" } \
				     { REPLACE_RESIDUE \
				     REPLACE_ATOM } }

set typedef(_pdbset_ncs_isfract) {menu { "orthogonal Angstroms" \
	"fractional coordinates" } \
	{ ORTHOG FRACT }}

set typedef(_pdbset_rot_type) {menu { \
	"matrix definition" "euler angles" "polar angles" } \
	{ MATRIX EULER POLAR }}

set typedef(_pdbset_ncode) {menu { \
        "do not generate matrix " \
	"axes along a, c* x a, c* (Brookhaven standard)" \
        "axes along b, a* x b, a* " \
        "axes along c, b* x c, b* " \
        "axes along a + b, c* x (a+b), c* " \
        "axes along a*, c x a*, c (Rollet) " \
        "axes along a, b*, a x b* " \
        "axes along a*, b a* x b (TNT convention) " } \
        { CODE0 CODE1 CODE2 CODE3 CODE4 CODE5 CODE6 CODE7 } }

set typedef(_pdbset_symgen_mode) {menu { "spacegroup" \
        "individual symmetry operations" }
         { SYMGEN_SPACE SYMGEN_OP } }

set typedef(_pdbset_trans_type) {menu {"no action" "rotation"
         "translational shift" "rotation and shift" } 
	 { NONE ROTATE SHIFT BOTH } }

return 1
}

#----------------------------------------------------------------
proc pdbset_renumber { arrayname counter } {
#----------------------------------------------------------------

  OpenSubFrame frame -toggle_display EDIT_MODE,$counter open RENAME

  CreateLine line \
    message "Rename chain id and/or renumber residues (RENUMBER)" \
    help chain \
    widget EDIT_MODE \
    message "Old chain id (RENAME/RENUMBER)" \
    widget RENUMBER_CHAIN -width 4 \
    label "to" \
    message "New chain id (RENAME/RENUMBER)" \
    widget RENUMBER_NEW_CHAIN -width 4 \
    label "for (optional) residue range" \
    message "Optionally limit change of chain name to range (RENUMBER)" \
    widget RENUMBER_RANGE_1 -width 6 \
    label to \
    widget RENUMBER_RANGE_2 -width 6 

  CloseSubFrame

  OpenSubFrame frame -toggle_display EDIT_MODE,$counter open RENUMBER

  CreateLineTemplate pdbset_renumber_form \
        [list 0.0 0.25 0.35 0.45 0.5 0.65 0.8 ]

  CreateLineTemplate pdbset_renumber_form2 \
        [list 0.0 0.25 0.35 0.5 0.65 0.8 ]

  CreateLine line \
    message "Rename chain id and/or renumber residues (RENUMBER)" \
    help renumber \
    widget EDIT_MODE \
    label "initial: " \
    message "First residue in edit range (RENUMBER range)" \
    widget RENUMBER_RANGE_1 -width 6 \
    label "to" \
    message "Last residue in edit range (RENUMBER range)" \
    widget RENUMBER_RANGE_2 -width 6 \
    message "Chain id of residues in edit range (RENUMBER CHAIN)" \
    label "on chain" \
    widget RENUMBER_CHAIN -width 4 \
    format template pdbset_renumber_form

  CreateLine line \
    help chain \
    label "" \
    label "result: " \
    message "Rename chain id and/or renumber residues (RENUMBER)" \
    widget RENUMBER_MODE \
    widget RENUMBER_INIT \
    label "Rename chain" \
    message "New chain name (no change if blank) (RENUMBER new_chain)" \
    widget RENUMBER_NEW_CHAIN -width 4 \
    format template pdbset_renumber_form2 \
    toggle_display RENUMBER_MODE,$counter open [list INIT  ]

  CreateLine line \
    help chain \
    label "" \
    message "Rename chain id and/or renumber residues (RENUMBER)" \
    label "result: " \
    widget RENUMBER_MODE \
    widget RENUMBER_INC \
    label "rename chain" \
    message "New chain name (no change if blank) (RENUMBER new_chain)" \
    widget RENUMBER_NEW_CHAIN -width 4 \
    format template pdbset_renumber_form2 \
    toggle_display RENUMBER_MODE,$counter open [list INC ]

  CloseSubFrame

}

#----------------------------------------------------------------
proc pdbset_replace { arrayname counter } {
#----------------------------------------------------------------    
  OpenSubFrame frame \
	  -toggle_display REPLACE_MODE,$counter open REPLACE_RESIDUE

  CreateLine line \
    help replace \
    label "Rename " \
    message "rename residue or atom type" \
    widget REPLACE_MODE \
    label "type" \
    message "replace this residue type name" \
    widget REPLACE_RES -width 4 \
    label " as " \
    message "by this residue type name" \
    widget WITH_RES -width 4

  CloseSubFrame

  OpenSubFrame frame \
	  -toggle_display REPLACE_MODE,$counter open REPLACE_ATOM

  CreateLine line \
    help replace \
    label "Rename " \
    message "Rename residue or atom type" \
    widget REPLACE_MODE \
    label " type" \
    message "replace this atom type name " \
    widget REPLACE_ATOM -width 5 \
    label " as " \
    message "by this atom type name" \
    widget WITH_ATOM -width 5 \
    label " ( in residue " \
    message "in this residue type" \
    widget IN_RES -width 4 \
    label " )"


  CloseSubFrame
  
}				
#----------------------------------------------------------------
proc pdbset_symgen { arrayname counter} {
#----------------------------------------------------------------
  OpenSubFrame frame

  CreateLine line \
    help symgen \
    label "Symmetry operation to generate new chain: " \
    label "$counter." \
    message "Symmetry operation or NCS, eg X+1/2, Y+1/2, -Z" \
    widget SYMGEN -width 20
 
  CloseSubFrame

  OpenSubFrame frame \
	  -toggle_display SYMGEN,$counter open NCS hide

  CreateLineTemplate pdbset_ncs_matrix \
    [ list 0.0 0.05 0.15 0.25 0.35 0.5 0.63 ]

  CreateLine line \
    help transform \
    label "      " \
    message "Fractional or orthogonal angstrom" \
    label "Coordinate type: "\
    widget NCS_ISFRACT \
    label "     " \
    widget NCS_INVERT \
    label "Invert transformation"
   
  CreateLine line \
    label "" \
    message "set elements of rotation" \
    label "Rotation: " \
    widget RN_11 \
    widget RN_12 \
    widget RN_13 \
    message "set elements of translation" \
    label "Translation: " \
    widget TN_X \
    format template pdbset_ncs_matrix

  CreateLine line \
    label "" \
    message "set elements of rotation" \
    label "" \
    widget RN_21 \
    widget RN_22 \
    widget RN_23 \
    message "set elements of translation" \
    label "" \
    widget TN_Y \
    format template pdbset_ncs_matrix

  CreateLine line \
    label "" \
    message "set elements of rotation" \
    label "" \
    widget RN_31 \
    widget RN_32 \
    widget RN_33 \
    message "set elements of translation" \
    label "" \
    widget TN_Z \
    format template pdbset_ncs_matrix

  CloseSubFrame

}
#----------------------------------------------------------------
proc pdbset_chain_rename { arrayname counter } {
#----------------------------------------------------------------

  OpenSubFrame frame

  CreateLine line \
    help chain \
    message "Rename chain after symmetry operation" \
    label "Rename chain " \
    message "original chain name" \
    widget NSYM_OLD_CHAIN \
    label " as " \
    message "name after symmetry operation" \
    widget NSYM_NEW_CHAIN \
    label " generated by " \
    message "which symmetry operation" \
    widget NSYM_CHAIN_SYM \
    label " symmetry operation"
    
  CloseSubFrame
}
#----------------------------------------------------------------
proc pdbset_output_atoms { arrayname counter } {
#----------------------------------------------------------------
 
CreateLineTemplate pdbset_output_form \
   [ list 0.0 0.15 0.25 0.35 0.45 0.55 ]

  OpenSubFrame frame  
  
if {$counter == 1 } {
  CreateLine line \
    help pick \
    label "Atom types" \
    widget OUT_ATOM1 -width 4 \
    widget OUT_ATOM2 -width 4 \
    widget OUT_ATOM3 -width 4 \
    widget OUT_ATOM4 -width 4 \
    widget OUT_ATOM5 -width 4 \
    format template pdbset_output_form
} elseif {$counter > 1 && $counter <= 4 } {
  CreateLine line \
    help pick \
    label "" \
    widget OUT_ATOM1 -width 4 \
    widget OUT_ATOM2 -width 4 \
    widget OUT_ATOM3 -width 4 \
    widget OUT_ATOM4 -width 4 \
    widget OUT_ATOM5 -width 4 \
    format template pdbset_output_form
} else {
  CreateLine line \
  label "Maximum of 20"
}

  CloseSubFrame
}
#----------------------------------------------------------------
proc pdbset_output_chains { arrayname counter } {
#----------------------------------------------------------------
 
CreateLineTemplate pdbset_output_form \
   [ list 0.0 0.15 0.25 0.35 0.45 0.55 ]

  OpenSubFrame frame  
  
if {$counter == 1 } {
  CreateLine line \
    help select \
    label "Chains" \
    widget OUT_CHAIN1 -width 4 \
    widget OUT_CHAIN2 -width 4 \
    widget OUT_CHAIN3 -width 4 \
    widget OUT_CHAIN4 -width 4 \
    widget OUT_CHAIN5 -width 4 \
    format template pdbset_output_form
} elseif {$counter > 1 && $counter <= 4 } {
  CreateLine line \
    help select \
    label "" \
    widget OUT_CHAIN1 -width 4 \
    widget OUT_CHAIN2 -width 4 \
    widget OUT_CHAIN3 -width 4 \
    widget OUT_CHAIN4 -width 4 \
    widget OUT_CHAIN5 -width 4 \
    format template pdbset_output_form
} else {
  CreateLine line \
  label "Maximum of 20"
}

  CloseSubFrame
}

#-----------------------------------------------------------------
proc pdbset_update_task_action { arrayname } {
#-----------------------------------------------------------------
  upvar #0 $arrayname array

  if { [GetValue $arrayname TASK_PRG] == "PDBCUR" } {
    set array(TASK_ACTION) $array(PDBCUR_ACTION)
  } else {
    set array(TASK_ACTION) $array(PDBSET_ACTION)
  }
}

#----------------------------------------------------------------
proc pdbset_task_window { arrayname } {
#----------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
    	"Edit PDB File" "Edit PDB" \
        [ list "Cell Parameters"  \
	"Rename chains and/or renumber residues" \
        "Generate new chains by symmetry operations " \
	"Rotations and translations" \
        "Rename chains after symmetry operations" \
        "Select elements for output" \
        "Exclude elements for output" \
        "Replace atom and residue types in pdb file" \
        "Remove atoms with low/zero occupancy" ]
	] == 0 } return

  SetProgramHelpFile "pdbset"

# Special trap for backwards-compatibility
# If you are re-running an old pdbset job, from before the
# addition of pdbcur, we need to set new parameters correctly.
# Non-zero XYZIN => re-running a job
# Zero TASK_ACTION => re-running the old interface (or new job)
  if {$array(XYZIN) != "" && $array(TASK_ACTION) == ""} {
    set array(TASK_PRG) "PDBSET"
  }

# Set TASK_ACTION from PDBSET_ACTION/PDBCUR_ACTION
  pdbset_update_task_action $arrayname

#=PROTOCOL==============================================================

  OpenFolder protocol 
  
  CreateTitleLine line TITLE

  CreateLine line \
    message "Select operation to perform on PDB file (exclusive in template)" \
    label "Use " \
    widget TASK_PRG \
           -command "pdbset_update_task_action $arrayname" \
    label " to " \
    widget PDBCUR_ACTION \
           -command "pdbset_update_task_action $arrayname" \
    toggle_display TASK_PRG open [ list PDBCUR ] hide

  CreateLine line \
    message "Select operation to perform on PDB file (exclusive in template)" \
    label "Use " \
    widget TASK_PRG \
           -command "pdbset_update_task_action $arrayname" \
    label " to " \
    widget PDBSET_ACTION \
           -command "pdbset_update_task_action $arrayname" \
    toggle_display TASK_PRG open [ list PDBSET ] hide

#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
        "Enter input coordinate file name (XYZIN)" \
      "PDB in" \
       XYZIN DIR_XYZIN \
       -fileout XYZOUT DIR_XYZOUT "_pdbset" \
       -setfileparam space_group_name SPACE_GROUP \
       -setfileparam space_group_name SYMGEN_GRP  \
       -setfileparam cell CELL

  CreateLine line \
    message "Is input file from X-PLOR (XPLOR)" \
    help xplor \
    widget IFXPLOR \
    label "" \
    label "Input file is X-PLOR format" \
    toggle_display TASK_PRG open [ list PDBSET ] hide

  CreateOutputFileLine line \
        "Output coordinate file" \
        "PDB out" \
        XYZOUT DIR_XYZOUT

  CreateLine line \
    message "Output to be in X-PLOR format"  \
    help output \
    widget IFOUT_XPLOR \
    label "" \
    label "Output file X-PLOR format"  \
    toggle_display TASK_PRG open [ list PDBSET ] hide

#=PARAMETERS==========================================================


  OpenFolder 1 TASK_PRG closed [ list PDBSET ] hide

  CreateLine line \
	message "Space group (default from PDB) (SYMM)" \
        help cell \
        widget IF_CELL \
        label "Reset cell parameters:" \
        help spacegroup \
	label "  Space group" \
	widget SPACE_GROUP 

  CreateLine line \
	message "Cell dimensions (default from PDB) (CELL)" \
        help cell \
	label "Cell a" \
	widget CELL_1 \
	label "b" \
	widget CELL_2 \
	label "c" \
	widget CELL_3 \
	label "alpha" \
	widget CELL_4 \
	label "beta" \
	widget CELL_5 \
	label "gamma" \
	widget CELL_6

  CreateLine line \
        widget FROM_MTZ \
	label "Use cell and space group parameters from MTZ file.." -italic \
        toggle_display IF_CELL open 1 hide

  OpenSubFrame frame \
       -toggle_display FROM_MTZ open 1 hide

  CreateInputFileLine line \
       "Extract cell and space group parameters from MTZ file" \
      "MTZ in" \
       HKLIN DIR_HKLIN \
       -setfileparam space_group_name SPACE_GROUP \
       -setfileparam cell CELL 
      
  CloseSubFrame

  CreateLine line \
       help orthogonalization \
       message "Define code to generate orthogonalization matrix" \
       label "Define orthogonalization code: " \
       widget PDBSET_NCODE \
       toggle_display IF_CELL open 1

#=PARAMETERS2=========================================================

  OpenFolder 2 TASK_ACTION open [list RENAME ] hide

  CreateExtendingFrame NRENUMBER pdbset_renumber \
	"Renumber residues or rename chain for a range of residues" \
	"Add range of residues" \
	[list EDIT_MODE \
		RENUMBER_MODE \
		RENUMBER_INIT \
		RENUMBER_RANGE_1 \
		RENUMBER_RANGE_2 \
		RENUMBER_CHAIN \
		RENUMBER_NEW_CHAIN ]

#=PARAMETERS3=========================================================

  OpenFolder 3 TASK_ACTION open [list SYMMETRY ] hide

  CreateLine line \
    help symgen \
    message "Select method for entering symmetry operations" \
    label "Use" \
    widget SYMGEN_MODE \
    label "to define symmetry operations"

  CreateLine line \
        help symgen \
        message "Enter spacegroup name or number (SPACEGROUP)" \
        label "Spacegroup:" \
        widget SYMGEN_GRP \
        toggle_display SYMGEN_MODE open [ list SYMGEN_SPACE ]

  OpenSubFrame frame \
	  -toggle_display SYMGEN_MODE open SYMGEN_OP hide

  CreateLine line \
        label "List of individual symmetry operators:"

  CreateExtendingFrame NSYMGEN pdbset_symgen \
	  "Symmetry operations to generate new chains" \
	  "Add new symmetry operation to list"\
	  [list SYMGEN RN_11 RN_21 RN_31 RN_12 RN_22 RN_32 RN_13 \
	  RN_23 RN_33 TN_X TN_Y TN_Z NCS_ISFRACT NCS_INVERT ]

  CloseSubFrame

#=PARAMETERS4=========================================================

  OpenFolder 4 TASK_ACTION open [list ROTATE ]  hide

   CreateLine line \
    message "coordinate shift to be performed" \
    label "Apply " \
    widget TRANS_TYPE \
    label "to coordinates." \
    label "     " \
    message "Require inverse of translation" \
    widget NCS_TRAN_INVERT \
    label "Invert transformation"

  CreateLine line \
    help rotate \
    message "Matrix, Polar angles, Euler angles" \
    label "Define rotation in terms of: " \
    widget NCS_ROT_TYPE \
    toggle_display TRANS_TYPE open [list ROTATE BOTH ]

  CreateLine line \
    help rotate \
    message "Coordinate system, orthogonal angstrom or fractional" \
    label "Coordinate system: " \
    widget NCS_TRAN_ISFRACT \
    toggle_display TRANS_TYPE open [list SHIFT BOTH ]

  CreateLineTemplate pdbset_ncs_matrix \
    [ list 0.0 0.15 0.25 0.35 ]

  OpenSubFrame frame \
	   -toggle_display TRANS_TYPE open [list ROTATE BOTH ] hide

  OpenSubFrame frame \
	  -toggle_display NCS_ROT_TYPE open [list MATRIX ] hide

  CreateLine line \
    help rotate \
    message "set elements of rotation" \
    label "Rotation: " \
    widget R_11 \
    widget R_12 \
    widget R_13 \
    format template pdbset_ncs_matrix

  CreateLine line \
    help rotate \
    message "set elements of rotation" \
    label "" \
    widget R_21 \
    widget R_22 \
    widget R_23 \
    format template pdbset_ncs_matrix

  CreateLine line \
    help rotate \
    message "set elements of rotation" \
    label "" \
    widget R_31 \
    widget R_32 \
    widget R_33 \
    format template pdbset_ncs_matrix

  CloseSubFrame


  OpenSubFrame frame \
	  -toggle_display NCS_ROT_TYPE open [list EULER] hide

  CreateLine line \
    help rotate \
    message "set elements of rotation" \
    label "Eulerian angles: " \
    label "Alpha Beta Gamma" \
    widget R_ALPHA \
    widget R_BETA \
    widget R_GAMMA \
    format template pdbset_ncs_matrix


  CloseSubFrame


  OpenSubFrame frame \
	  -toggle_display NCS_ROT_TYPE open [list POLAR] hide

  CreateLine line \
    help rotate \
    message "set elements of rotation" \
    label "Polar angles: " \
    label "Omega Phi Kappa" \
    widget R_OMEGA \
    widget R_PHI \
    widget R_KAPPA \
    format template pdbset_ncs_matrix

  CloseSubFrame

  CloseSubFrame


  OpenSubFrame frame \
	  -toggle_display TRANS_TYPE open [list SHIFT BOTH ] hide

  CreateLine line \
    help shift \
    message "set elements of translation" \
    label "Translation: " \
    label "x-axis y-axis z-axis" \
    widget T_X \
    widget T_Y \
    widget T_Z \
    format template pdbset_ncs_matrix

  CloseSubFrame


#=PARAMETERS5=========================================================

  OpenFolder 5 TASK_ACTION open [list SYMMETRY ] hide

  CreateExtendingFrame NSYM_CHAIN_RENAME pdbset_chain_rename \
	  "Rename symmetry operation generated chains" \
	  "Add to list of renamed chains" \
	  [list NSYM_CHAIN_SYM NSYM_OLD_CHAIN NSYM_NEW_CHAIN ]

#=PARAMETERS6=========================================================

  OpenFolder 6 TASK_ACTION open [list SELECT ] hide

  CreateLine line \
    help pick \
    message "Select specified atom types" \
    widget OUTPUT_PICK \
    label "" \
    label "Select by atom type for inclusion in pdb file." 

  OpenSubFrame frame \
       -toggle_display OUTPUT_PICK open 1 hide

  CreateExtendingFrame NOUT_ATOMS pdbset_output_atoms \
    "Select atom type(s), case sensitive"  \
    "Add further atom types (max. 20)" \
    [list OUT_ATOM1 OUT_ATOM2 OUT_ATOM3 OUT_ATOM4 \
          OUT_ATOM5 ]

  CloseSubFrame


  CreateLine line \
    help select \
    message "Select only specified chains" \
    widget OUTPUT_CHAIN \
    label "" \
    label "Select by chain name." 

  OpenSubFrame frame \
       -toggle_display OUTPUT_CHAIN open 1 hide

  CreateExtendingFrame NOUT_CHAINS pdbset_output_chains \
    "Select chain(s), case sensitive"  \
    "Add further chains (max. 20)" \
    [list OUT_CHAIN1 OUT_CHAIN2 OUT_CHAIN3 OUT_CHAIN4 \
          OUT_CHAIN5 ]

  CloseSubFrame


  CreateLine line \
    help select \
    message "Selection based on occupancy" \
    widget OUTPUT_OCCUPANCY \
    label "" \
    label "Select only atoms with occupancy greater than minimum." 

  CreateLine line \
    message "Select atoms with occupancy greater than value" \
    label "Occupancy greater than" \
    widget OUTPUT_SEL_OCC -width 6 \
    toggle_display OUTPUT_OCCUPANCY open 1


  CreateLine line \
    help select \
    message "Selection based on B-factor" \
    widget OUTPUT_BFACTOR \
    label "" \
    label "Select only atoms with B-factor less than maximum."

  CreateLine line \
    message "Select atoms with B less than value" \
    label "B-factor less than" \
    widget OUTPUT_SEL_BFACT -width 6 \
    toggle_display OUTPUT_BFACTOR open 1


#=PARAMETERS7=========================================================

  OpenFolder 7 TASK_ACTION open [list SELECT ] hide

  CreateLine line \
    help exclude \
    message "Exclude header information, useful for merging pdb files" \
    widget EXCLUDE_HEADER \
    label "" \
    label "Exclude header information from pdb file." \
    message "Exclude side chains, beyond CB" 

  CreateLine line \
    help exclude \
    message "Exclude side chains from pdb file." \
    widget EXCLUDE_SIDE \
    label "" \
    label "Exclude side chains." 

  CreateLine line \
    help exclude \
    message "Exclude water groups from pdb file" \
    widget EXCLUDE_WATER \
    label "" \
    label "Exclude water molecules."
    
#=PARAMETERS8=========================================================

  OpenFolder 8 TASK_ACTION open [list REPLACE ] hide

  CreateExtendingFrame NREPLACE pdbset_replace \
   "Replace residues or atoms" "Add to list of replacements" \
   [list REPLACE_MODE REPLACE_RES WITH_RES  \
          IN_RES REPLACE_ATOM WITH_ATOM]

  SetProgramHelpFile "pdbcur"
    
#=CUTOCC PARAMETERS9=================================================

  OpenFolder 9 TASK_ACTION open [list CUTOCC ] hide

  CreateLine line \
    help cutocc \
    message "Delete all atoms with an occupancy less than or equal to cutoff." \
    label "Delete all atoms with an occupancy less than or equal to " \
    widget CUTOCC_CUTOFF

}

