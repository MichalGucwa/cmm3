#---------------------------------------------------------------------
proc prosmart_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
	upvar #0 $typedefVar typedef
	upvar #0 $arrayname array

	set typedef(_chain_type) \
	{ menu { "all chains" "manual chain selection" } \
	{ ALL MANUAL } }

	set typedef(_primary_program_mode) \
	{ menu { "align structures & generate restraints" "align structures only" "generate restraints only" } \
	{ BOTH_ ALIGN_ RESTRAIN_ } }

	set typedef(_secondary_mode_align) \
	{ menu { "with reference structure(s)" "with structural fragments (e.g. secondary structural elements)" "all-on-all" "all-on-all (half-matrix)" } \
	{ STANDARD FRAGMENT ALLONALL TRIANGLE } }
						
	set typedef(_secondary_mode_restr) \
	{ menu { "reference structure(s)" "h-bonding patterns (e.g. secondary structure restraints)" "structural fragments (e.g. representative SSE conformations)" "use target structures as references (all-on-all)" } \
	{ STANDARD HBOND FRAGMENT ALLONALL } }
															
	set typedef(_target_chains1) [list varmenu MENU1 {} 10]
	set typedef(_target_chains2) [list varmenu MENU2 {} 10]

  	set typedef(_align_mode) \
	{ menu { "superpose and score fragments using all main chain atoms" "superpose and score fragments using only CA atoms" "superpose fragments using all main chain atoms, score using only CA atoms"} \
	{ ALL CA MIX } }

	set typedef(_restrain_type) \
	{ menu { "main chain atoms only" "main & side chain atoms" } \
	{ MAIN SIDE } }

	set typedef(_restrain_refmactype) \
	{ menu { "external restraints (default)" "bond-type restraints (replace existing)" "bond-type restraints (add to existing)" } \
	{ EXTERNAL REPLACE ADD } }

	set typedef(_sigma_type) \
	{ menu { "distance-dependent sigmas" "estimated constant sigmas" "default sigmas" } \
	{ SIGMA_DD SIGMA_EST SIGMA_DEFAULT } }

	set typedef(_hbond_mode) \
	{ menu { "whole main chain (all helices, sheets, loops, etc.)" "particular secondary structure types" "custom selection" } \
	{ ALL SSE CUSTOM } }

	set typedef(_hbond_ssemode) \
	{ menu { "helices & beta-sheets" "helices only" "beta-sheets only" } \
	{ ALL HELIX SHEET } }

	set typedef(_hbond_opt) \
	{ menu { "O-N and N-O (used for all-main-chain and beta-sheets)" "O-N (used for helices)"  "do not filter - allow all main-chain atom pairs" } \
	{ ONNO ON ALL } }

	return 1
}

#-------------------------------------------------------------------------
proc prosmart_run { arrayname } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array

	set array(OUTPUTS) [ FileJoin $array(DIR_OUT) "ProSMART_Results.html" ]
	set array(DIR_OUTPUTS) $array(DIR_OUT)

	return 1
}

#---------------------------------------------------------------------
proc prosmart_add_p1 { arrayname c1 } {
#---------------------------------------------------------------------
	upvar #0 $arrayname array
	  
	CreateInputFileLine line \
      "Input target structure" \
      "Input target structure" \
      P1 DIR_P1 \
			-command "prosmart_update_chain_list1 $arrayname $c1"
			
	OpenSubFrame frame -toggle_display C1_TYPE open MANUAL
	CreateExtendingFrame NC1 prosmart_add_chain1 \
			"Add another target chain" \
			"Add chain" \
			[list C1] \
			-counter $c1
  CloseSubFrame			
}

#---------------------------------------------------------------------
proc prosmart_add_p2 { arrayname c1 } {
#---------------------------------------------------------------------
	upvar #0 $arrayname array
	  
	CreateInputFileLine line \
      "Input reference structure" \
      "Input reference structure" \
      P2 DIR_P2 \
			-command "prosmart_update_chain_list2 $arrayname $c1"
			
	OpenSubFrame frame -toggle_display C2_TYPE open MANUAL
	CreateExtendingFrame NC2 prosmart_add_chain2 \
			"Add another reference chain" \
			"Add chain" \
			[list C2] \
			-counter $c1
  CloseSubFrame			
}

#---------------------------------------------------------------------
proc prosmart_add_chain1 { arrayname c1 c2 } {
#---------------------------------------------------------------------
	upvar #0 $arrayname array
	  
	CreateLine line \
		message "Select Chain. To refresh chain list, click on the appropriate target structure's filename." \
		label "Use" \
		widget C1
		
	if { ![StringSame $c1 1] } {
		prosmart_update_chain_list1 $arrayname $c2
	}
}

#---------------------------------------------------------------------
proc prosmart_add_chain2 { arrayname c1 c2 } {
#---------------------------------------------------------------------
	  
	CreateLine line \
		message "Select Chain. To refresh chain list, click on the appropriate target structure's filename." \
		label "Use" \
		widget C2
	
	if { ![StringSame $c1 1] } {
	prosmart_update_chain_list2 $arrayname $c2
	}
}

#------------------------------------------------------------------------
proc prosmart_update_chain_list1 { arrayname c1 } {
#------------------------------------------------------------------------
	upvar #0 $arrayname array
	
	set pdb_filename [GetFullFileName0 $arrayname P1,$c1]
		
	set array(PDB_CHAINS) {}
	set array(PDB_RES_RANGE) {}
	
	# Make sure PdbGetChains procedure is accessible
	source [SearchPath TOP utils pdb_utils.tcl]
	
	if {![PdbGetChains $pdb_filename array(PDB_CHAINS) array(PDB_RES_RANGE)] } { return }
		
	UpdateVariableMenu $arrayname initialise 0 MENU1 $array(PDB_CHAINS)
}

#------------------------------------------------------------------------
proc prosmart_update_chain_list2 { arrayname c1 } {
#------------------------------------------------------------------------
	upvar #0 $arrayname array
	
	set pdb_filename [GetFullFileName0 $arrayname P2,$c1]
		
	set array(PDB_CHAINS) {}
	set array(PDB_RES_RANGE) {}
	
	# Make sure PdbGetChains procedure is accessible
	source [SearchPath TOP utils pdb_utils.tcl]
	
	if {![PdbGetChains $pdb_filename array(PDB_CHAINS) array(PDB_RES_RANGE)] } { return }
		
	UpdateVariableMenu $arrayname initialise 0 MENU2 $array(PDB_CHAINS)
}

#------------------------------------------------------------------------
proc prosmart_refresh { arrayname } {
#------------------------------------------------------------------------
	upvar #0 $arrayname array

	# set primary program mode
	if { [regexp BOTH_ [GetValue $arrayname PRIMARY_MODE] ] } {
		set array(ALIGN) 1
		set array(RESTRAIN) 1
		set array(RESTRAIN_WARNING) 0
	}
	if { [regexp ALIGN_ [GetValue $arrayname PRIMARY_MODE] ] } {
		set array(ALIGN) 1
		set array(RESTRAIN) 0
		set array(RESTRAIN_WARNING) 0
	}
	if { [regexp RESTRAIN_ [GetValue $arrayname PRIMARY_MODE] ] } {
		set array(ALIGN) 0
		set array(RESTRAIN) 1
		set array(RESTRAIN_WARNING) 1
	}

	# set secondary program mode
	if { [regexp ALIGN_ [GetValue $arrayname PRIMARY_MODE] ] } {
		set array(USE_HBOND) 0
		if { [regexp STANDARD [GetValue $arrayname SECONDARY_MODE_ALIGN] ] } {
			set array(USE_LIB) 0
			set array(ALL_ON_ALL) 0
			set array(TRIANGULAR) 0
		}
		if { [regexp FRAGMENT [GetValue $arrayname SECONDARY_MODE_ALIGN] ] } {
			set array(USE_LIB) 1
			set array(ALL_ON_ALL) 0
			set array(TRIANGULAR) 0
		}
		if { [regexp ALLONALL [GetValue $arrayname SECONDARY_MODE_ALIGN] ] } {
			set array(USE_LIB) 0
			set array(ALL_ON_ALL) 1
			set array(TRIANGULAR) 0
		}
		if { [regexp TRIANGLE [GetValue $arrayname SECONDARY_MODE_ALIGN] ] } {
			set array(USE_LIB) 0
			set array(ALL_ON_ALL) 1
			set array(TRIANGULAR) 1
		}
	} else {
		set array(TRIANGULAR) 0
		if { [regexp STANDARD [GetValue $arrayname SECONDARY_MODE_RESTR] ] } {
			set array(USE_HBOND) 0
			set array(USE_LIB) 0
			set array(ALL_ON_ALL) 0
		}
		if { [regexp HBOND [GetValue $arrayname SECONDARY_MODE_RESTR] ] } {
			set array(USE_HBOND) 1
			set array(USE_LIB) 0
			set array(ALL_ON_ALL) 0
		}
		if { [regexp FRAGMENT [GetValue $arrayname SECONDARY_MODE_RESTR] ] } {
			set array(USE_HBOND) 0
			set array(USE_LIB) 1
			set array(ALL_ON_ALL) 0
		}
		if { [regexp ALLONALL [GetValue $arrayname SECONDARY_MODE_RESTR] ] } {
			set array(USE_HBOND) 0
			set array(USE_LIB) 0
			set array(ALL_ON_ALL) 1
		}
	}

	# show/hide relevant folders
	if { $array(ALL_ON_ALL) || $array(USE_LIB) || $array(USE_HBOND) } {
	  set array(HIDE_REFERENCE) 1
	} else {
	  set array(HIDE_REFERENCE) 0
	}
	
	# sanity checks
	if { [StringSame $array(DIR_OUT) ""] } {
		set array(DIR_OUT) [ FileJoin [GetDefaultDirPath] $array(OUT) ]
	}

	return 1
}

#------------------------------------------------------------------------
proc prosmart_refresh_hbond { arrayname } {
#------------------------------------------------------------------------
	upvar #0 $arrayname array

	if { [regexp SSE [GetValue $arrayname HBOND_MODE] ] } {
		set array(HBOND_DISPLAYSSE) 1
	} else {
		set array(HBOND_DISPLAYSSE) 0
	}

	if { [regexp CUSTOM [GetValue $arrayname HBOND_MODE] ] } {
		set array(HBOND_DISPLAYCUSTOM) 1
	} else {
		set array(HBOND_DISPLAYCUSTOM) 0
	}

	if { ![regexp SHEET [GetValue $arrayname HBOND_SSEMODE] ] } {
		set array(HBOND_DISPLAYHELIX) 1
	} else {
		set array(HBOND_DISPLAYHELIX) 0
	}

	if { !$array(HBOND_3) && !$array(HBOND_4) && !$array(HBOND_5) } {
	  set array(HBOND_3) 1
	  set array(HBOND_4) 1
	  set array(HBOND_5) 1
	}

	return 1
}

#------------------------------------------------------------------------
proc ProsmartRanges1 { arrayname c1 } {
#------------------------------------------------------------------------

	upvar #0 $arrayname array
	  
    	CreateLine line \
		message "PDB filename must include file extension, but exclude path. Alternatively, use ALL to apply range for all PDBs." \
		label "In PDB file" \
      		widget RANGE1PDB \
		message "Specify a single chain, or use ALL to apply range for all chains." \
		label "chain" \
      		widget RANGE1CHAIN \
		message "Residue numbers must be integer, and may not include insertion codes." \
      		label "  Allow residues in range:" \
      		widget RANGE1A \
		label "to" \
      		widget RANGE1B \
		
	return 1
}

#------------------------------------------------------------------------
proc ProsmartRanges2 { arrayname c1 } {
#------------------------------------------------------------------------

	upvar #0 $arrayname array
	  
    	CreateLine line \
		message "PDB filename must include file extension, but exclude path. Alternatively, use ALL to apply range for all PDBs." \
		label "In PDB file" \
      		widget RANGE2PDB \
		message "Specify a single chain, or use ALL to apply range for all chains." \
		label "chain" \
      		widget RANGE2CHAIN \
		message "Residue number may include an insertion code." \
      		label "  Remove residue:" \
      		widget RANGE2 \
		
	return 1
}

#------------------------------------------------------------------------
proc ProsmartRanges3 { arrayname c1 } {
#------------------------------------------------------------------------

	upvar #0 $arrayname array
	  
    	CreateLine line \
		message "PDB filename must include file extension, but exclude path. Alternatively, use ALL to apply range for all PDBs." \
		label "In PDB file" \
      		widget RANGE3PDB \
		message "Specify a single chain, or use ALL to apply range for all chains." \
		label "chain" \
      		widget RANGE3CHAIN \
		message "Residue numbers must be integer, and may not include insertion codes." \
      		label "  Allow restraints for residues in range:" \
      		widget RANGE3A \
		label "to" \
      		widget RANGE3B \
		
	return 1
}

#------------------------------------------------------------------------
proc ProsmartRanges4 { arrayname c1 } {
#------------------------------------------------------------------------

	upvar #0 $arrayname array
	  
    	CreateLine line \
		message "PDB filename must include file extension, but exclude path. Alternatively, use ALL to apply range for all PDBs." \
		label "In PDB file" \
      		widget RANGE4PDB \
		message "Specify a single chain, or use ALL to apply range for all chains." \
		label "chain" \
      		widget RANGE4CHAIN \
		message "Residue number may include an insertion code." \
      		label "  Remove restraints involving residue:" \
      		widget RANGE4 \
		
	return 1
}


#-----------------------------------------------------------------------
proc prosmart_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { ![CreateTaskWindow $arrayname  \
		"ProSMART - Procrustes Structural Matching Alignment and Restraints Tool" prosmart \
			[ list "Input target structure(s)" \
			"Input reference structure(s)" \
			"Fragment library options" \
			"Structural alignment parameters" \
			"Scoring options for comparative analysis" \
			"Rigid substructure identification parameters" \
			"External restraint generation parameters" \
			"Generic or h-bond restraint parameters (e.g. for secondary structure restraints)" \
			"Output options" \
			"Advanced" \
			] \
		{} ] }  { return 0 }
		
		prosmart_refresh $arrayname
		prosmart_refresh_hbond $arrayname

#=PROTOCOL==============================================================

  OpenFolder protocol

  CreateTitleLine line TITLE

	OpenSubFrame frame -toggle_display RESTRAIN_WARNING hide 1
    	CreateLine line \
		label "Use ProSMART to  " \
		message "Choose whether to align chain-pairs and/or generate external restraints for use in refinement by REFMAC5." \
		widget PRIMARY_MODE -command "prosmart_refresh $arrayname"
    	CloseSubFrame
    	OpenSubFrame frame -toggle_display RESTRAIN_WARNING open 1
    	CreateLine line \
		label "Use ProSMART to  " \
		message "Choose whether to align chain-pairs and/or generate external restraints for use in refinement by REFMAC5." \
		widget PRIMARY_MODE -command "prosmart_refresh $arrayname" \
		label "(warning - ProSMART alignment must already exist in out dir)"
   	CloseSubFrame

	OpenSubFrame frame -toggle_display RESTRAIN open 0
	CreateLine line \
			label "Align target structure(s)" \
			message "Select program mode." \
			widget SECONDARY_MODE_ALIGN -command "prosmart_refresh $arrayname"
	CloseSubFrame
	OpenSubFrame frame -toggle_display RESTRAIN open 1
	CreateLine line \
			label "Align and generate restraints for target structure(s) using" \
			message "Select program mode." \
			widget SECONDARY_MODE_RESTR -command "prosmart_refresh $arrayname"
	CloseSubFrame

#=FILES=================================================================

	OpenFolder file
  	CreateLine line \
      		message "Output directory - files may be overwritten if multiple jobs use the same output directory." \
      		label "Output directory" \
      		widget DIR_OUT -expand

#=TARGET FILES==========================================================
		 
	OpenFolder 1 

  CreateLine line \
			message "Target chain selection" \
      label "Use" \
			widget C1_TYPE -width 26 \
			label "for target structure(s)"
	
	CreateExtendingFrame NP1 prosmart_add_p1 \
			"Add another target structure" \
			"Add structure" \
			[list P1 DIR_P1 NC1] \
			-child prosmart_add_chain1


#=REFERENCE FILES=======================================================				
	
	OpenFolder 2 HIDE_REFERENCE hide 1 open

	    CreateLine line \
			  message "Reference chain selection" \
        label "Use" \
			  widget C2_TYPE -width 26 \
			  label "for reference structure(s)"
	
	    CreateExtendingFrame NP2 prosmart_add_p2 \
			  "Add another reference structure" \
			  "Add structure" \
			  [list P2 DIR_P2 NC2] \
			  -child prosmart_add_chain2

#=FRAGMENT LIBRARY======================================================				

	OpenFolder 3 USE_LIB closed 1 hide

	  CreateLine line \
			message "Use all fragments present in the ProSMART fragment library, as specified in the library configuration file." \
			widget LIB \
			label "Use all fragments present in library"
	
	  OpenSubFrame frame -toggle_display LIB hide 1
	
	    CreateLine line \
				message "Use the default representative alpha-helical fragment." \
			  label "Use specific fragment(s): " \
			  widget HELIX \
			  label "Helix" \
				message "Use the default representative beta-strand fragment." \
			  widget STRAND \
			  label "Strand"
	
	  CloseSubFrame	

	OpenSubFrame frame -toggle_display LIB_ADVANCED hide 1
    	CreateLine line \
		message "Advanced options - allows customisation of library fragments, and provision of custom libraries." \
      		widget LIB_ADVANCED \
		label "Advanced options"
    	CloseSubFrame
    	OpenSubFrame frame -toggle_display LIB_ADVANCED open 1
    	CreateLine line \
		message "Advanced options" \
      		widget LIB_ADVANCED \
		label "Advanced options"
	CreateLine line \
		message "Procrustes score threshold determines whether structures are considered sufficiently similar to the library fragment." \
		label "Override all library score thresholds with value:" \
      		widget LIB_SCORE
	CreateLine line \
		message "Number of residues used to represent fragment (must be odd, min 3). First N residues in the fragment file are used." \
		label "Override all library fragment lengths with value:" \
      		widget LIB_FRAGLEN
	CreateInputFileLine line \
		"Alternative library configuration file" \
		"Alternative library configuration file: " \
      		LIB_CONFIG DIR_KEYWORDS
	CreateLine line \
		message "Alternative library location (directory path)" \
		label "Alternative library location (directory path):" \
      		widget LIB_DIR
   	CloseSubFrame

#=ALIGN=================================================================				

	OpenFolder 4 ALIGN closed 1 hide

	CreateLine line \
			message "Removes residues from the input PDB files before processing alignment (note - does not modify original PDB files)" \
			widget RANGE_SHOW \
			label "Specify residue ranges used for alignment (and any subsequent analysis & restraint generation)"
	OpenSubFrame frame -toggle_display RANGE_SHOW hide 0
	CreateExtendingFrame NRANGE1 ProsmartRanges1 \
			"Add a residue range." \
			"Add residue range" \
			[list RANGE1PDB RANGE1CHAIN RANGE1A RANGE1B]
	CreateExtendingFrame NRANGE2 ProsmartRanges2 \
			"Remove an individual residue. Allows inclusion of insertion code." \
			"Remove individual residue" \
			[list RANGE2PDB RANGE2CHAIN RANGE2]
	CloseSubFrame	

	OpenSubFrame frame -toggle_display USE_LIB hide 1
	OpenSubFrame frame -toggle_display FRAGLEN_SHOW hide 1
    	CreateLine line \
		message "Number of residues per structural fragment - must be odd, minimum 3 residues." \
      		widget FRAGLEN_SHOW \
      		label "Adjust structural resolution of comparative analysis"
    	CloseSubFrame
    	OpenSubFrame frame -toggle_display FRAGLEN_SHOW open 1
    	CreateLine line \
		message "Number of residues per structural fragment - must be odd, minimum 3 residues." \
      		widget FRAGLEN_SHOW \
		label "Adjust structural resolution of comparative analysis:  Fragment length:" \
      		widget FRAGLEN \
      		label "residues"
   	CloseSubFrame
	CloseSubFrame

	OpenSubFrame frame -toggle_display ALIGN_SCORE_SHOW hide 1
    	CreateLine line \
		message "Align residues only if their local structural environments are sufficiently conserved." \
        	widget ALIGN_SCORE_SHOW \
      		label "Filter final alignment by fragment Procrustes score"
    	CloseSubFrame
    	OpenSubFrame frame -toggle_display ALIGN_SCORE_SHOW open 1
    	CreateLine line \
		message "Align residues only if their local structural environments are sufficiently conserved." \
        	widget ALIGN_SCORE_SHOW \
      		label "Filter final alignment by fragment Procrustes score:" \
		message "Residues whose 'minimum' score is less than this value will be removed." \
        	widget ALIGN_SCORE
   	CloseSubFrame

    	CreateLine line \
		message "Alignment mode" \
      		label "Alignment mode" \
      		widget ALIGN_MODE

	CreateLine line \
		message "Perform iterative fragment-based and residue-based alignment optimisation following dynamic programming" \
      		label "Refine alignment" \
      		widget REFINE_ALIGNMENT \
		message "Assume direct correspondence between residue numbers. Unexpected results may occur if this condition is not satisfied." \
      		label "  Assume sequence identical" \
      		widget SEQUENCE_IDENTICAL

    	OpenSubFrame frame -toggle_display ADJUST_HELIX hide 1
    	CreateLine line \
		message "Adjust dynamic programming penalty applied when an alignment gap occurs within an alpha-helix." \
        	widget ADJUST_HELIX \
      		label "Alter dynamic programming parameters"
    	CloseSubFrame
    	OpenSubFrame frame -toggle_display ADJUST_HELIX open 1
    	CreateLine line \
		message "Adjust dynamic programming penalty applied when an alignment gap occurs within an alpha-helix." \
        	widget ADJUST_HELIX \
      		label "Alter dynamic programming parameters: " \
		message "Dynamic programming penalty for helical fragment-pairs. Helps avoid alignment gaps in helices." \
		label "Helix penalty:" \
      		widget HELIX_PENALTY \
		message "Used to determine which fragments are sufficiently helical, only for use during alignment by dynamic programming." \
      		label " Procrustes score threshold:" \
      		widget HELIX_SCORE
   	CloseSubFrame

	OpenSubFrame frame -toggle_display REWARD_SEQ_ENABLE hide 1
	CreateLine line \
		message "Assign fragment-pair a special dissimilarity score during alignment if every residue-pair is sequence-identical." \
        	widget REWARD_SEQ_ENABLE \
      		label "Reward sequence-identical fragment-pairs"
   	CloseSubFrame
	OpenSubFrame frame -toggle_display REWARD_SEQ_ENABLE open 1
	OpenSubFrame frame -toggle_display REWARD_SEQ_SHOW hide 1
    	CreateLine line \
		message "Assign fragment-pair a special dissimilarity score during alignment if every residue-pair is sequence-identical." \
        	widget REWARD_SEQ_ENABLE \
      		label "Reward sequence-identical fragment-pairs" \
		message "The more negative the score, the higher the reward for sequence-identical fragment-pairs." \
        	widget REWARD_SEQ_SHOW \
      		label "Adjust score for sequence-identical fragment-pairs"
    	CloseSubFrame
    	OpenSubFrame frame -toggle_display REWARD_SEQ_SHOW open 1
    	CreateLine line \
		message "Assign fragment-pair a special dissimilarity score during alignment if every residue-pair is sequence-identical." \
        	widget REWARD_SEQ_ENABLE \
      		label "Reward sequence-identical fragment-pairs" \
		message "The more negative the score, the higher the reward for sequence-identical fragment-pairs." \
        	widget REWARD_SEQ_SHOW \
      		label "Adjust score for sequence-identical fragment-pairs" \
		widget REWARD_SEQ
   	CloseSubFrame
   	CloseSubFrame


#=SCORING===============================================================				
	OpenFolder 5 ALIGN closed 1 hide

	CreateLine line \
		message "Both configurations are tried; the best score is selected." \
        	label "Account for potential side chain flips during scoring" \
      		widget SCORE_FLIP

	CreateLine line \
		message "By default, side chain scores include CA but no other main chain atoms." \
        	label "Include main chain N, C and O atoms in residue-based side chain scores" \
      		widget SCORE_NCO

	CreateLine line \
		message "Display intrafragment rotational dissimilarity scores as cosine distances, instead of angular degrees." \
        	label "Display intrafragment rotational dissimilarity scores as cosine distances" \
      		widget SCORE_COSINE


#=RIGID SUBSTRUCTURE IDENTIFICATION=====================================				

	OpenFolder 6 ALIGN closed 1 hide

	CreateLine line \
		message "Perform rigid substructure identification." \
        	label "Perform rigid substructure identification" \
      		widget SUBSTRUCTURE_ID

	OpenSubFrame frame -toggle_display SUBSTRUCTURE_ID open 1
	
	OpenSubFrame frame -toggle_display RIGID_SCORE_SHOW hide 1
    	CreateLine line \
		message "Dissimilar fragments are removed prior to substructure identification. Adjust thresholds on fragment conservation." \
      		widget RIGID_SCORE_SHOW \
		label "Adjust fragment conservation score thresholds"
    	CloseSubFrame
    	OpenSubFrame frame -toggle_display RIGID_SCORE_SHOW open 1
    	CreateLine line \
		message "Dissimilar fragments are removed prior to substructure identification. Adjust thresholds on fragment conservation." \
      		widget RIGID_SCORE_SHOW \
		label "Adjust fragment conservation score thresholds:  " \
		message "Procrustes score threshold determining which fragments are used for substructure identification." \
        	label "Procrustes:" \
      		widget RIGID_SCORE \
        	message "Intrafragment rotation score threshold determining which fragments are used for substructure identification." \
        	label " Intrafragment rotation:" \
      		widget RIGID_ANGLE \
        	label "(degrees)"
   	CloseSubFrame

	OpenSubFrame frame -toggle_display RIGID_LINK_SHOW hide 1
    	CreateLine line \
		message "Main parameters determining which substructures are identified, how flexible they are, etc. Scores are cosine distances." \
      		widget RIGID_LINK_SHOW \
		label "Adjust main clustering parameters"
    	CloseSubFrame
    	OpenSubFrame frame -toggle_display RIGID_LINK_SHOW open 1
    	CreateLine line \
		message "Main parameters determining which substructures are identified, how flexible they are, etc. Scores are cosine distances." \
      		widget RIGID_LINK_SHOW \
		label "Adjust main clustering parameters:  " \
		message "Single linkage clustering threshold (cosine). Increase to increase number of identified substructures." \
        	label "Single linkage threshold:" \
      		widget RIGID_LINK \
		message "Determines number of fragments used for final substructures (cosine). Increase to tighten core superposition." \
        	label "Final cluster rigidity:" \
      		widget RIGID_RIGID \
        	label "(cosine)"
   	CloseSubFrame

	OpenSubFrame frame -toggle_display RIGID_MIN_SHOW hide 1
    	CreateLine line \
message "Minimum number of fragments in a cluster, forming the final rigid substructures. Note - fragments are allowed to overlap." \
      		widget RIGID_MIN_SHOW \
        	label "Adjust minimum size of final clusters"
    	CloseSubFrame
    	OpenSubFrame frame -toggle_display RIGID_MIN_SHOW open 1
    	CreateLine line \
		message "Minimum number of fragments in a cluster, forming the final rigid substructures. Note - fragments are allowed to overlap." \
      		widget RIGID_MIN_SHOW \
        	label "Adjust minimum size of final clusters: " \
      		widget RIGID_MIN \
        	label "fragments"
   	CloseSubFrame

	CloseSubFrame

#=RESTRAIN==============================================================				

	OpenFolder 7 RESTRAIN closed 1 hide

	CreateLine line \
			message "Tell ProSMART to only generate restraints for certain residue ranges" \
			widget RANGE3_SHOW \
			label "Specify residue ranges used for restraint generation"
	OpenSubFrame frame -toggle_display RANGE3_SHOW hide 0
	CreateExtendingFrame NRANGE3 ProsmartRanges3 \
			"Add a residue range." \
			"Add residue range" \
			[list RANGE3PDB RANGE3CHAIN RANGE3A RANGE3B]
	CreateExtendingFrame NRANGE4 ProsmartRanges4 \
			"Remove an individual residue. Allows inclusion of insertion code." \
			"Remove individual residue" \
			[list RANGE4PDB RANGE4CHAIN RANGE4]
	CloseSubFrame

	CreateLine line \
		message "Specify which type of atom-pairs to generate restraints for." \
        	label "Restrain" \
      		widget RESTRAIN_TYPE \
		message "Specify how REFMAC5 should treat the generated restraints. Generally, always leave type as external restraints." \
        	label "  and treat restraints as REFMAC5 type" \
      		widget RESTRAIN_REFMACTYPE

	CreateLine line \
		message "Either use only the most structurally similar reference chain, or use all compared chains regardless of similarity." \
        	label "Only use most structurally similar chain for restraint generation" \
      		widget RESTRAIN_BEST

	CreateLine line \
		message "Restraints between atom-pairs separated by one/two bonds will be removed (may be removed in some cases regardless)." \
        	label "Remove restraints corresponding to atom-pairs separated by bonds/angles" \
      		widget RESTRAIN_RMBONDS

	OpenSubFrame frame -toggle_display RESTRAIN_RMAX_SHOW hide 1
    	CreateLine line \
		message "Specify minimum and maximum lengths of generated restraints." \
      		widget RESTRAIN_RMAX_SHOW \
		label "Specify interatomic distance thresholds (sphere size)"
    	CloseSubFrame
    	OpenSubFrame frame -toggle_display RESTRAIN_RMAX_SHOW open 1
    	CreateLine line \
		message "Specify minimum and maximum lengths of generated restraints." \
      		widget RESTRAIN_RMAX_SHOW \
		label "Specify interatomic distance thresholds (sphere size): " \
		message "Minimum restraint length (Angstroms)." \
        	label " min:" \
      		widget RESTRAIN_RMIN \
		message "Maximum restraint length (Angstroms). Note - REFMAC5 will filter restraints further, typically max=4.2A." \
        	label " max:" \
      		widget RESTRAIN_RMAX
   	CloseSubFrame

	OpenSubFrame frame -toggle_display RESTRAIN_SCORE_SHOW hide 1
    	CreateLine line \
		message "Specify to only generate restraints in sufficiently structurally conserved regions." \
      		widget RESTRAIN_SCORE_SHOW \
        	label "Filter restraints by structural alignment scores"
    	CloseSubFrame
    	OpenSubFrame frame -toggle_display RESTRAIN_SCORE_SHOW open 1
    	CreateLine line \
		message "Specify to only generate restraints in sufficiently structurally conserved regions." \
      		widget RESTRAIN_SCORE_SHOW \
        	label "Filter restraints by structural alignment scores: " \
		message "Restraints are not generated if the residue-pair's fragment Procrustes score is worse (higher) than this value." \
        	label " Procrustes score:" \
      		widget RESTRAIN_SCORE \
		message "Restraints are not generated if the residue-pair's side chain conformation score (SideAV) is worse (higher) than this value." \
        	label " Side chain score:" \
      		widget RESTRAIN_SIDE
   	CloseSubFrame

	OpenSubFrame frame -toggle_display RESTRAIN_TYPE_SHOW hide 1
    	CreateLine line \
		message "Adjust method of sigma estimation, default and minimum values of sigma." \
      		widget RESTRAIN_TYPE_SHOW \
        	label "Specify sigma estimation parameters"
    	CloseSubFrame
    	OpenSubFrame frame -toggle_display RESTRAIN_TYPE_SHOW open 1
    	CreateLine line \
		message "Adjust method of sigma estimation, default and minimum values of sigma." \
      		widget RESTRAIN_TYPE_SHOW \
        	message "Sigma estimation type." \
        	label "Specify sigma estimation parameters: " \
      		widget RESTRAIN_SIGMATYPE
    	CreateLine line \
		message "Default value of sigmas, used if default sigmas are selected or if sigma estimation fails." \
        	label "Default sigma:" \
      		widget RESTRAIN_SIGMA \
		message "Minimum possible value of sigma, ensuring restraints are not too tight." \
        	label "  Minimum sigma:" \
      		widget RESTRAIN_SIGMAMIN \
		message "Scale all sigmas by factor." \
        	label "  Scale all sigmas by factor:" \
      		widget RESTRAIN_SCALE
   	CloseSubFrame		

	OpenSubFrame frame -toggle_display RESTRAIN_OUTLIER_SHOW hide 1
    	CreateLine line \
		message "Restraints are not generated if the restraint distance is more than X sigmas from the current distance." \
		widget RESTRAIN_OUTLIER_SHOW \
        	label "Remove restraint outliers"
    	CloseSubFrame
    	OpenSubFrame frame -toggle_display RESTRAIN_OUTLIER_SHOW open 1
    	CreateLine line \
		message "Restraints are not generated if the restraint distance is more than X sigmas from the current distance." \
		widget RESTRAIN_OUTLIER_SHOW \
        	label "Remove restraint outliers greater than" \
      		widget RESTRAIN_OUTLIER \
        	label "sigmas from the current value"
   	CloseSubFrame	

	CreateLine line \
		message "Generic self-restraints, e.g. for DNA/RNA. Ignores any reference structures." \
        	label "Alternative mode:  Generate generic self-restraints" \
      		widget RESTRAIN_GENERIC_SELF

#=RESTRAIN HBOND =======================================================

	OpenFolder 8 USE_HBOND closed 1 hide

	CreateLine line \
		message "Select type of bond restraints to generate." \
        	label "Apply generic/h-bond restraints to" \
      		widget HBOND_MODE -command "prosmart_refresh_hbond $arrayname"

	OpenSubFrame frame -toggle_display HBOND_DISPLAYSSE open 1
	CreateLine line \
		message "Select type of bond restraints to generate." \
        	label "Generate secondary structure h-bond restraints for" \
      		widget HBOND_SSEMODE -command "prosmart_refresh_hbond $arrayname"
	
	OpenSubFrame frame -toggle_display HBOND_DISPLAYHELIX open 1
	CreateLine line \
        	label "Allow O-N h-bond restraints for " \
		message "Allow O-N h-bonds between atoms separated by 3 residues." \
      		widget HBOND_3 -command "prosmart_refresh_hbond $arrayname" \
        	label "3_10-helices, " \
		message "Allow O-N h-bonds between atoms separated by 4 residues." \
      		widget HBOND_4 -command "prosmart_refresh_hbond $arrayname" \
        	label "alpha-helices,  and" \
		message "Allow O-N h-bonds between atoms separated by 5 residues." \
      		widget HBOND_5 -command "prosmart_refresh_hbond $arrayname" \
        	label "pi-helices"
   	CloseSubFrame

	CreateLine line \
		message "Use fragment library to filter residues for restraint generation (uses ideal alpha-helix and representative beta-strand)." \
        	label "Require sufficient structural similarity to library fragments" \
      		widget HBOND_STRICT
   	CloseSubFrame

	OpenSubFrame frame -toggle_display HBOND_DISPLAYCUSTOM open 1
	CreateLine line \
		message "Select residue separation range (default: 3 to infinity)" \
        	label "Allow restraints between atoms separated by " \
      		widget HBOND_MINSEP \
        	label "to" \
      		widget HBOND_MAXSEP \
        	label "residues, but not residues" \
      		widget HBOND_REMOVESEP
	CreateLine line \
		message "Select atom-pair types to be restrained" \
        	label "Allow restraints between atom-pair types" \
      		widget HBOND_OPT
	CloseSubFrame

	OpenSubFrame frame -toggle_display HBOND_ALTER hide 1
    	CreateLine line \
		message "Set target restraint value, and detection limits for identifying atom-pairs to be restrained" \
        	widget HBOND_ALTER \
		label "Customise restraint parameters"
    	CloseSubFrame
    	OpenSubFrame frame -toggle_display HBOND_ALTER open 1
    	CreateLine line \
		message "Set target restraint value, and detection limits for identifying atom-pairs to be restrained" \
        	widget HBOND_ALTER \
		label "Customise restraint parameters:" \
        	label "   Target value:" \
      		widget HBOND_TARGET \
		label "   Detection range:" \
      		widget HBOND_MIN \
		label "to" \
      		widget HBOND_MAX \
		label "Angstroms"
   	CloseSubFrame

    	OpenSubFrame frame -toggle_display HBOND_OVERRIDE hide 1
    	CreateLine line \
		message "Override max number of restraints that an atom can have (default: 1 for N, 2 for O)" \
        	widget HBOND_OVERRIDE \
      		label "Override max number of restraints per atom"
    	CloseSubFrame
    	OpenSubFrame frame -toggle_display HBOND_OVERRIDE open 1
    	CreateLine line \
		message "Override max number of restraints that an atom can have (default: 1 for N, 2 for O)" \
        	widget HBOND_OVERRIDE \
      		label "Override max number of restraints per atom" \
        	widget HBOND_OVERRIDE_VAL
   	CloseSubFrame

#=OUTPUT================================================================				

	OpenFolder 9 closed

	OpenSubFrame frame -toggle_display ALIGN hide 0

	CreateLine line \
		message "Output PDB format files corresponding to superposed chain-pairs." \
        	label "Output PDB files" \
      		widget OUTPUT_PDB

	OpenSubFrame frame -toggle_display OUTPUT_PDB hide 0
	CreateLine line \
		message "Include all chains (all ATOM/HETATM records) in output PDB files, not just the chain used for comparison." \
        	label "Include all chains in output PDB files, not just the target/reference chains" \
      		widget OUTPUT_PDB_FULL
	OpenSubFrame frame -toggle_display SUPERPOSITION_SHOW hide 1
    	CreateLine line \
		message "Excludes poor-scoring aligned fragment-pairs from being used when calculating the global superposition." \
      		widget SUPERPOSITION_SHOW \
		label "Adjust Procrustes score threshold for global superposition"
    	CloseSubFrame
    	OpenSubFrame frame -toggle_display SUPERPOSITION_SHOW open 1
    	CreateLine line \
		message "Excludes poor-scoring aligned fragment-pairs from being used when calculating the global superposition." \
      		widget SUPERPOSITION_SHOW \
		label "Adjust Procrustes score threshold for global superposition: " \
      		widget SUPERPOSITION_SCORE
   	CloseSubFrame
   	CloseSubFrame

	CreateLine line \
		message "Output Pymol format colour scripts for residue scores." \
        	label "Output colour scripts" \
      		widget OUTPUT_COLOUR

	OpenSubFrame frame -toggle_display OUTPUT_COLOUR open 1

	OpenSubFrame frame -toggle_display COLOUR_SCORE_SHOW hide 1
    	CreateLine line \
		message "Score thresholds defining complete local dissimilarity in colour scripts. Adjust scale to change colour gradients." \
        	widget COLOUR_SCORE_SHOW \
      		label "Alter colour gradients"
    	CloseSubFrame
    	OpenSubFrame frame -toggle_display COLOUR_SCORE_SHOW open 1
    	CreateLine line \
		message "Score thresholds defining complete local dissimilarity in colour scripts. Adjust scale to change colour gradients." \
        	widget COLOUR_SCORE_SHOW \
      		label "Alter colour gradient for mainchain scores:" \
        	widget COLOUR_SCORE \
      		label "sidechain scores:" \
        	widget COLOUR_SCORE_SIDE \
      		label "substructure scores:" \
        	widget RIGID_COLOUR
   	CloseSubFrame

	OpenSubFrame frame -toggle_display COLOUR_SHOW hide 1
    	CreateLine line \
		message "Change RGB colour codes representing complete (dis)similarity in output PyMOL scripts." \
        	widget COLOUR_SHOW \
      		label "Alter RGB colour codes"
    	CloseSubFrame
    	OpenSubFrame frame -toggle_display COLOUR_SHOW open 1
    	CreateLine line \
		message "Change RGB colour codes representing complete (dis)similarity in output PyMOL scripts." \
        	widget COLOUR_SHOW \
      		label "Alter RGB codes for similarity:" \
        	widget COLOUR_S1 \
		widget COLOUR_S2 \
		widget COLOUR_S3 \
		label "  and dissimilarity:" \
        	widget COLOUR_D1 \
		widget COLOUR_D2 \
		widget COLOUR_D3
   	CloseSubFrame

   	CloseSubFrame
   	CloseSubFrame

	OpenSubFrame frame -toggle_display RESTRAIN hide 0

	CreateLine line \
		message "Output extra intermediate PDB-chain restraint files (disabled to save disk space)." \
        	label "Output extra PDB-chain restraint files" \
      		widget OUTPUT_EXTRA_RESTRAINTS
	
   	CloseSubFrame


#=ADVANCED==============================================================				

	OpenFolder 10 closed

	CreateLine line \
		message "Provide any extra keywords" \
      		label "Extra ProSMART keywords" \
        	widget EXTRA_KEYWORDS -expand

  	CreateInputFileLine line \
      		"Specify external text file containing ProSMART keywords" \
      		"External keywords file" \
      		KEYWORDS DIR_KEYWORDS

	CreateLine line \
		message "Merge all chains in each PDB file, e.g. for direct comparison of oligomers/complexes. Won't work properly with residue range selection, or restraint generation." \
        	label "Merge all chains in each PDB file" \
      		widget MERGE

	OpenSubFrame frame -toggle_display THREADS_SHOW hide 1
    	CreateLine line \
      		widget THREADS_SHOW \
        	label "Performance options"
    	CloseSubFrame
    	OpenSubFrame frame -toggle_display THREADS_SHOW open 1
    	CreateLine line \
		widget THREADS_SHOW \
        	label "Performance options:  " \
		message "Maximum number of simultaneous ProSMART child processes" \
        	label "Maximum number of threads" \
      		widget THREADS
   	CloseSubFrame
        
    	OpenSubFrame frame -toggle_display XML hide 1
    	CreateLine line \
		message "Output XML file" \
        	widget XML \
      		label "Output XML file"
    	CloseSubFrame
    	OpenSubFrame frame -toggle_display XML open 1
    	CreateLine line \
		message "Output XML file" \
        	widget XML \
      		label "Output XML file" \
		message "Output XML filename" \
        	widget XML_FILE
   	CloseSubFrame

    	OpenSubFrame frame -toggle_display RESTRAIN open 1
	OpenSubFrame frame -toggle_display REFMAC_SHOW hide 1
    	CreateLine line \
		message "Name of REFMAC5 executable to be used for generation of bond list" \
      		widget REFMAC_SHOW \
        	label "Specify REFMAC5 executable name"
    	CloseSubFrame
    	OpenSubFrame frame -toggle_display REFMAC_SHOW open 1
    	CreateLine line \
		message "Name of REFMAC5 executable to be used for generation of bond list" \
      		widget REFMAC_SHOW \
        	label "Specify REFMAC5 executable name" \
      		widget REFMAC
   	CloseSubFrame
	CloseSubFrame

}
