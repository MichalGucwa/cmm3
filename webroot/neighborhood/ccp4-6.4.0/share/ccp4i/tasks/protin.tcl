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
# protin.tcl --
#
# Template for task interface
#
# CCP4Interface 
#
# =======================================================================


#---------------------------------------------------------------------
proc protin_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0 $typedefVar typedef


set typedef(_chain_constitution) { menu  {	protein
						non-protein
						water }
					 {      PROTEIN 
						WAT
						WAT } }

set typedef(_chain_id_menu)	{ varmenu CHAIN_ID_MENU {} 4 }

set typedef(_chain_type)	{ varmenu CHAIN_TYPE_MENU {} 4 }

set typedef(_residue_id)	{ text 4 NOTOBLIG }

set typedef(_residue_type)	{ text 4 NOTOBLIG }

set typedef(_atom_id)		{ text 4 NOTOBLIG }

set typedef(_terminal_group)	{ menu { 	"N" 
						"N-formyl"
						"N-acetyl"
						"COO" }  
					     { 3 4 5 2 } }

set typedef(_special_group_type) { menu { 	"has cis-peptide"
						"linked to carbohydrate" }
					{    CISP
					     CARBO } }

set typedef(_protin_dist_code) 	{ menu	{ 	"Bond length"
						"1-3distance"
						"Intraplanar"
						"Hbond/metal" 
						"Special" }
						 { 1 2 3 4 5 } }

set typedef(_protin_bfactor_code) { menu {	"Mainchn bond"
						"Mainchn angle"
						"Sidechn bond"
						"Sidechn angle"
						"Special" }
						{ 1 2 3 4 5 } }
						
set typedef(_protin_list)	{ menu {	all
						some
						few } }

set typedef(_protin_nonx_code)  { menu { "tight" \
					"tight main chain & medium side chain" \
					"tight main chain & loose side chain" \
					"medium" \
					"medium main chain & loose side chain" \
					"loose" }
					{ 1 2 3 4 5 6 } }

return 1
			
}

#------------------------------------------------------------------------
proc protin_set_chain_type_menu { arrayname counter } {
#------------------------------------------------------------------------
  set menu {}
  for { set n 1 } { $n <= $counter } { incr n } { lappend menu $n }
  UpdateVariableMenu $arrayname initialise  $counter CHAIN_TYPE_MENU \
        $menu
}


#------------------------------------------------------------------------
proc ProtinTypeFrame { arrayname counter } {
#------------------------------------------------------------------------

  protin_set_chain_type_menu $arrayname $counter

  CreateLine line \
	message "Define a chain type (CHNTYP <ichtyp>)" \
	help chntyp_wat \
	label "Chain constitution is" \
	widget CHAIN_CONSTITUTION

  OpenSubFrame frame  \
      -toggle_display   [Indxv CHAIN_CONSTITUTION $counter] open protein

  CreateLine line \
	message "Describe the N-terminal residue (CHNTYP NTERM)" \
        help chntyp_nterm \
	label "N-terminal residue id" \
	widget NTERM_ID \
	label "residue type" \
	widget NTERM_AA \
	label "terminal group" \
	widget NTERM_GROUP 

  CreateLine line \
        message "Describe the C-terminal residue (CHNTYP CTERM)" \
        help chntyp_cterm \
        label "C-terminal residue id" \
        widget CTERM_ID \
        label "residue type" \
        widget CTERM_AA \
        label "terminal group" \
        widget CTERM_GROUP 

  CreateLine line \
    label "Cis-peptides and carbohydrate residues" \
	-italic

  CreateExtendingFrame N_SPECIAL_GROUP ProtinSpecialFrame \
	"Define special groups (cis-peptide or carbohydrate) in the chain" \
	"Add special group"\
      [list  SPECIAL_GROUP_TYPE \
	SPECIAL_GROUP_RES ] \
	-counter $counter


  CloseSubFrame
}

#------------------------------------------------------------------------
proc ProtinSpecialFrame { arrayname c1 c2 } {
#------------------------------------------------------------------------

  CreateLine line \
	message "Specify a spcial residue type in the chain (CHNTYP SPEC)" \
	help chntyp_cispep \
	label "Residue id" \
	widget SPECIAL_GROUP_RES \
	widget SPECIAL_GROUP_TYPE

}

#------------------------------------------------------------------------
proc ProtinDisulphideFrame { arrayname c1 } {
#------------------------------------------------------------------------

  CreateLine line \
	message "Define an INTRA-chain disulphide bond (CHNTYP DISUL)" \
	help chntyp_disu \
	label "Chain type" \
	widget INTRA_DISULPHIDE_CHAIN_TYPE \
	label "Between residue" \
	widget INTRA_DISULPHIDE_RES1 \
	label "and residue" \
	widget INTRA_DISULPHIDE_RES2

}
	

#------------------------------------------------------------------------
proc ProtinChainFrame { arrayname counter } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  if { $array(CHAIN_ID,$counter) == "" } {
    set value "_"
  } else {
    set value $array(CHAIN_ID,$counter)
  }
  if { $counter == 1 } {
    set mode initialise
  } else {
    set mode append 
  }
  UpdateVariableMenu $arrayname $mode $counter CHAIN_ID_MENU  $value

  CreateLine line \
	message "Specify a chain (CHNNAM)" \
        help chnnam \
	label "Chain id" \
	widget CHAIN_ID \
	  -updatevarmenu CHAIN_ID_MENU $counter \
	label "is of chain type" \
        help chnnam_chntyp \
	widget CHAIN_TYPE \
	label "with residue offset" \
        help chnnam_roffset \
	widget CHAIN_OFFSET

}

#------------------------------------------------------------------------
proc edit_ProtinChainFrame { arrayname counter } {
#------------------------------------------------------------------------
# When user has edited the chain frames (eg deleted or copied)
# then this procedure called to update the CHAIN_ID_MENU menu
  upvar #0 $arrayname array
  set menu ""
  if { $counter > 0 } {
  for { set i 1 } { $i <= $counter } { incr i } {
    lappend menu $array(CHAIN_ID,$i)
  } }
  UpdateVariableMenu $arrayname initialise $counter CHAIN_ID_MENU $menu
}


#------------------------------------------------------------------------
proc ProtinInterDisulphideFrame {arrayname  counter } {
#------------------------------------------------------------------------

  CreateLine line \
	message "Define an INTER-chain disulphide bond(DISULPHIDE)" \
	help disulphide \
	widget INTER_DISULPHIDE_CHAIN1 \
	widget INTER_DISULPHIDE_RES1 \
	widget INTER_DISULPHIDE_CHAIN2 \
	widget INTER_DISULPHIDE_RES2 \
	format template INTER_DISULPHIDE

}

#------------------------------------------------------------------------
proc ProtinInterDist { arrayname c1 } {
#------------------------------------------------------------------------

  CreateLine line \
        message "Define an INTER-chain distance restraint (SPECIAL)" \
        help special \
        widget INTER_DIST_CHAIN1 \
		-width 4 \
        widget INTER_DIST_RES1 \
        widget INTER_DIST_ATOM1 \
        widget INTER_DIST_CHAIN2 \
		-width 4 \
        widget INTER_DIST_RES2 \
        widget INTER_DIST_ATOM2 \
	widget INTER_DIST_DIST \
	widget INTER_DIST_IKWT \
	widget INTER_DIST_IBWT \
        format template INTER_DISTANCE

}

#------------------------------------------------------------------------
proc ProtinIntraDist { arrayname c1 } {
#------------------------------------------------------------------------

  CreateLine line \
        message "Define an INTRA-chain distance restraint(CHNTYP SPEC)" \
        help chntyp_spec \
        widget INTRA_DIST_CHAIN_TYPE \
        widget INTRA_DIST_RES1 \
        widget INTRA_DIST_ATOM1 \
        widget INTRA_DIST_RES2 \
        widget INTRA_DIST_ATOM2 \
        widget INTRA_DIST_DIST \
        widget INTRA_DIST_IKWT \
        widget INTRA_DIST_IBWT \
        format template INTRA_DISTANCE

}

#------------------------------------------------------------------------
proc ProtinNonX { arrayname c1 } {
#------------------------------------------------------------------------

  CreateExtendingFrame N_NONX_CHN ProtinNonXChain \
        "Specify chains restained by non-crystallographic symmetry" \
        "Add chain" \
      [list  NONX_CHN ] \
	-counter $c1

  CreateExtendingFrame N_NONX_SPANS ProtinNonXSpans \
        "Specify range of residues restained by non-crystallographic symmetry" \
        "Add residue range" \
      [list  NONX_SPANS_RES1 \
		NONX_SPANS_RES2 \
		NONX_SPANS_CODE ] \
	       -counter $c1

}

#------------------------------------------------------------------------
proc ProtinNonXChain { arrayname c1 c2 } {
#------------------------------------------------------------------------

  if { $c1 == 1 } {
    CreateLine line \
      label "Restrain together chain" \
      widget NONX_CHN
  } else {
    CreateLine line \
      label "and" \
      widget NONX_CHN
  }

}
#------------------------------------------------------------------------
proc ProtinNonXSpans { arrayname c1 c2 } {
#------------------------------------------------------------------------

  CreateLine line \
    label "Restrain residue range" \
    widget NONX_SPANS_RES1 \
    label "to" \
    widget NONX_SPANS_RES2 \
    label "with" \
    widget NONX_SPANS_CODE \
    label "restraints"
}

#------------------------------------------------------------------------
proc ProtinExtras { arrayname counter } {
#------------------------------------------------------------------------

  CreateLine line \
    help VDWRADII \
    label "Command line" \
    widget EXTRAS  -expand

}


#=CREATE=WINDOW=AND=SUBWINDOWS===========================================

#------------------------------------------------------------------------
proc protin_task_window { arrayname } {
#------------------------------------------------------------------------

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
        "Protin Restraints" "Protin" \
	[ list "General Options" \
        "Chain Types"  \
	"IntRA-chain disulphides" \
	"IntRA-chain distance restraints" \
        "Chain Definitions"  \
	"IntER-chain disulphides"  \
	"IntER-chain distance restraints"\
	"Non-crystallographic symmetry restraints"  \
	"Extra Command Lines" ] \
	-action_buttons [list quit save exit] ] == 0 } return

  SetProgramHelpFile protin

  set ccp4 [ GetEnvPath CCP4 ]
  if { $array(DICTPROTN) == "" } {
    set array(DICTPROTN) [FileJoin $ccp4 lib data protin.dic]
  }


# Files==============================================================

  OpenFolder file

  CreateLine line \
        label "PROTIN/REFMAC 4 have been withdrawn from CCP4 as of version 5.0 - Refmac5 should be used instead" -italic
  CreateLine line \
        label "This interface is provided to allow the review of old jobs only, and will not run the programs" -italic

#  CreateInputFileLine line \
#      "Enter input PDB file name (XYZIN)" \
#      "PDB in" \
#       PROTIN_XYZIN DIR_PROTIN_XYZIN \

  CreateInputFileLine line \
      "Enter dictionary file name (DICTPROTN) " \
      "Dictionary" \
       DICTPROTN DIR_DICTPROTN \
	-help description

#=PARAMETERS==========================================================

  OpenFolder 1

  CreateLine line \
	message "Level of log output (LIST)" \
	help list \
	label "Output" \
	widget LIST \
	label "distances to log file"

  OpenFolder 2

  CreateToggleFrame  N_CHAIN_TYPES  ProtinTypeFrame \
                "Open another chain type frame" "Chain type number" \
		"Add chain type" \
               [list CHAIN_CONSTITUTION \
		NTERM_ID \
		NTERM_AA \
		NTERM_GROUP \
		CTERM_ID \
		CTERM_AA \
		CTERM_GROUP \
		N_SPECIAL_GROUP  \
		SPECIAL_GROUP_TYPE ] \
		-child ProtinSpecialFrame \
	        -edit protin_set_chain_type_menu


  OpenFolder 3 closed

  CreateExtendingFrame N_INTRA_DISULPHIDES ProtinDisulphideFrame \
        "Define INTRA-chain disulphide bonds" \
        "Add disulphide" \
      [list  INTRA_DISULPHIDE_CHAIN_TYPE \
	INTRA_DISULPHIDE_RES1 \
        INTRA_DISULPHIDE_RES2 ]

  OpenFolder 4 closed

  CreateLineTemplate INTRA_DISTANCE { 0.0 0.15 0.25 0.35 0.45 0.55 0.65 0.8 }

  CreateLine line \
        message "" \
        label "chaintype" \
        label "resid1" \
        label "atom1" \
        label "resid2" \
        label "atom2" \
        label "distance" \
        label "Distance type"  \
        label "Bfactor type"  \
        format template INTRA_DISTANCE

  CreateExtendingFrame N_INTRA_DIST ProtinIntraDist \
        "Define INTRA-chain distance constraints" \
        "Add restraint" \
      [list  INTRA_DIST_CHAIN_TYPE \
	INTRA_DIST_RES1 \
        INTRA_DIST_ATOM1 \
        INTRA_DIST_RES2 \
        INTRA_DIST_ATOM2 \
        INTRA_DIST_DIST \
        INTRA_DIST_IKWT \
        INTRA_DIST_IBWT ]

  OpenFolder 5

  CreateExtendingFrame N_CHAINS ProtinChainFrame \
                "Open another chain definition frame" \
                "Add chain" \
        [ list  CHAIN_ID \
                CHAIN_TYPE \
                CHAIN_OFFSET ] \
	-edit edit_ProtinChainFrame


  OpenFolder 6 closed

  CreateLineTemplate INTER_DISULPHIDE { 0.0 0.2 0.5 0.7 }

  CreateLine line \
	message "" \
	label "chain1" \
	label "resid1" \
	label "chain2" \
	label "resid2" \
	format template INTER_DISULPHIDE

  CreateExtendingFrame N_INTER_DISULPHIDES ProtinInterDisulphideFrame \
		"Define INTER-chain disulphide bond" \
		"Add disulphide bond" \
	[list	INTER_DISULPHIDE_CHAIN1 \
		INTER_DISULPHIDE_RES1 \
		INTER_DISULPHIDE_CHAIN2 \
		INTER_DISULPHIDE_RES2 ]

  OpenFolder 7 closed

  CreateLineTemplate INTER_DISTANCE { 0.0 0.09 0.17 0.25 0.34 0.42 0.5 0.6 0.8 }

  CreateLine line \
        message "" \
        label "chain1" \
        label "resid1" \
        label "atom1" \
        label "chain2" \
        label "resid2" \
        label "atom2" \
	label "distance" \
	label "Distance type"  \
	label "Bfactor type"  \
        format template INTER_DISTANCE


  CreateExtendingFrame N_INTER_DIST ProtinInterDist \
        "Define INTER-chain distance constraints" \
        "Add restraint" \
      [list  INTER_DIST_CHAIN1 \
	INTER_DIST_RES1 \
        INTER_DIST_ATOM1 \
	INTER_DIST_CHAIN2 \
        INTER_DIST_RES2 \
        INTER_DIST_ATOM2 \
        INTER_DIST_DIST \
        INTER_DIST_IKWT \
        INTER_DIST_IBWT  ]

  OpenFolder 8 closed

  CreateToggleFrame  N_NONX  ProtinNonX \
                "Open another non-xtallographic symmetry restraint" \
		"Non-xtallographic symmetry restraint" \
                "Add non-X restraint" \
             [list   N_NONX_CHN \
		N_NONX_SPANS ] \
		-child ProtinNonXChain \
		-child ProtinNonXSpans

  OpenFolder 9 closed

  CreateLine line \
    label "Add extra command lines not supported by the interface" -italic

  CreateExtendingFrame NEXTRAS ProtinExtras \
	"Add extra command lines not supported by the interface" \
	"Add extra command" \
	[list EXTRAS ]

  CreateLine line \
    label "Read commands from file.." -italic

  CreateInputFileLine line \
      "Enter Protin commands script" \
      "Com in" \
       EXTRA_FILE DIR_EXTRA_FILE


  

}
		
#=END=======================================================================


