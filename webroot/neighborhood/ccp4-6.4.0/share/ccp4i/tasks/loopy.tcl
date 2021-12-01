# ======================================================================
# loopy.tcl --
#
# CCP4Interface 
#
# =======================================================================

#----------------------------------------------------------------------
proc loopy_prereq {} {
#----------------------------------------------------------------------
    if { [GetEnvPath warpbin 0] == "" } {
        return 0
    } else {
        return 1
    }
}

#---------------------------------------------------------------------
proc loopy_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
upvar #0  $typedefVar typedef
upvar $arrayname def_array
global env

    # Confirm that the user has sourced the arpwarp setup script
    if { [info exists env(warpbin)] == 0 } {
        WarningMessage "Please check your shell startup file does source ARP/wARP 7.3. Then open another terminal window and re-launch CCP4i."
        return 0
    }

set warpbin [ GetEnvPath warpbin ]
DefineMenu _loopy_fit_target [list "Weighted means" \
				    "Correlation" ] [list 0 1 ] 
DefineMenu _loopy_grid_type [list "Regular" "Random"] [list 0 1 ]

DefineMenu _mode_loopy [list "Single loop" "All loops"] [list 0 1 ]
set typedef(_loopfit_exe) { file LOOPFIT "loopfit" "executable for real-space refinement" {} {} }
set typedef(_warpbin_dir) { default_dir {$warpbin} {warpbin} }

set typedef(_nmol_int) {
    menu
    {
        "1"
        "2"
        "3"
        "4"
        "5"
        "6"
        "7"
        "8"
        "9"
        "10"
        "11"
        "12"
        "13"
        "14"
        "15"
        "16"
        "17"
        "18"
        "19"
        "20"
    }
    {
        1
        2
        3
        4
        5
        6
        7
        8
        9
        10
        11
        12
        13
        14
        15
        16
        17
        18
        19
        20
}  }

set typedef(_meth_is_seleno) {
    menu
    {
        "are"
        "are not"
    }
    {
        1
	0
}  }

set typedef(_loopy_nterm_menu)     { varmenu N_ANCHOR_ID_MENU {} 8 }
set typedef(_loopy_cterm_menu)     { varmenu C_ANCHOR_ID_MENU {} 8 }
#Below is needed, otherwise the widget N_ANCHOR and C_ANCHOR are
#  unsufficiently recognised... thus the -command option doesn't work
#  PLUS: update the menu's if the pdb was already filled in
if {[ElementExists $arrayname PDB_INPUT_FILENAME]} {
    set tmp_input [GetValue $arrayname PDB_INPUT_FILENAME]
    if { [file exists $tmp_input] } {
#	loopy_update_anchor_menus $arrayname
    } else {
	UpdateVariableMenu $arrayname initialise 0 N_ANCHOR_ID_MENU  {""}
	UpdateVariableMenu $arrayname initialise 0 C_ANCHOR_ID_MENU  {""}
	set def_array(N_ANCHOR) ""
	set def_array(C_ANCHOR) ""
    }
} else {
    UpdateVariableMenu $arrayname initialise 0 N_ANCHOR_ID_MENU  {""}
    UpdateVariableMenu $arrayname initialise 0 C_ANCHOR_ID_MENU  {""}
    set def_array(N_ANCHOR) ""
    set def_array(C_ANCHOR) ""
}


DefineMenu _map_input_mode [list "an existing map" \
				"phases from MTZ file to calculate map"] \
    [list MAP MTZ]
  
#set array(CHAIN_ID_MENU) [ list "A" ]
#DefineMenu _loopy_chain_id [GetValue array CHAIN_ID_MENU ]
return 1
}

#-----------------------------------------------------------------------
proc loopy_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { ![CreateTaskWindow $arrayname  \
       "ARP/wARP Version 7.3.0: Loop Building" "ARP/wARP" \
	     [ list "Definition of the loop(s) (required parameters)" \
		    "Settings for generating loops" \
		    "Selecting best loops" "Selecting best CAs" \
		    "Generating CAs" "Density Handling" \
		    "Crystal Parameters (obtained from map/mtz file)" \
		    "Real-space refinement" \
		    "Log files of Loopy" ] \
	     ] }  { return 0 }

  set help_source [file join [GetEnvPath warpdoc] loopy.html ]
  SetProgramHelpFile $help_source 

  set array(NO_SEQUENCE) 1
#------------------------------------------------------------------------------
  OpenFolder protocol

  CreateTitleLine line TITLE
   set arplogo [image create photo -file [ FileJoin [GetEnvPath warpbin] ARP_logo_small.gif ] ]
   set logo [label $line.log -image $arplogo]
   pack $logo

  CreateLine line \
      message "Select input mode" \
      label "For building loops use" \
      help protocol \
      widget MAP_INPUT_MODE 

  CreateLine line \
      message "Select mode for loop building: either one specific, or all" \
      label "Mode for loop building" \
      help protocol \
      widget MODE_LOOPY \
      -command "loopy_set_use_sequence $arrayname"

#------------------------------------------------------------------------------
  OpenFolder file

# Density input (either MAP or MTZ) :
  OpenSubFrame frame -toggle_display MAP_INPUT_MODE open MAP 
  CreateInputFileLine line \
      "Best current electron density map" \
      "Enter input map filename      " \
      MAP_FILENAME DIR_MAP_FILENAME \
      -fileout EXT_MAP_FILENAME DIR_EXT_MAP_FILENAME "_ext" \
      -help files \
      -setfileparam space_group_name SPACEGROUP \
      -setfileparam cell CELL \
      -command "loopy_update_spacegroup $arrayname"
  CloseSubFrame
# OR MTZ file ... (with optional FOM)
  OpenSubFrame frame -toggle_display MAP_INPUT_MODE open MTZ 
  CreateInputFileLine line \
      "Mtz file with phases for map calculation" \
      "MTZ in" \
      MTZ_FILENAME DIR_MTZ_FILENAME \
      -help files \
      -fileout MAP_FROM_MTZ DIR_MAP_FROM_MTZ "_loopy" \
      -setfileparam space_group_number SPACEGROUP \
      -setfileparam cell_1 CELL_1 \
      -setfileparam cell_2 CELL_2 \
      -setfileparam cell_3 CELL_3 \
      -setfileparam cell_4 CELL_4 \
      -setfileparam cell_5 CELL_5 \
      -setfileparam cell_6 CELL_6

  CreateLabinLine line \
      "Choose F for map calculation" MTZ_FILENAME \
      "Fmap" F1  {FWT 2FOFCWT FP F}
      
  CreateLabinLine line \
      "Choose Phi for map calculation" MTZ_FILENAME \
      "PHImap" PHI  {PHWT PH2FOFCWT PHIDM PHIDM }

  CloseSubFrame

  CreateInputFileLine line \
      "Input PDB" \
      "Protein model for loop building" \
      PDB_INPUT_FILENAME DIR_PDB_INPUT_FILENAME \
      -help files \
      -fileout SAVE_LOOP_NAME DIR_SAVE_LOOP_NAME "_loop" \
      -fileout SAVE_PROP_PDB DIR_SAVE_PROP_PDB "_proposed" \
      -fileout OUTPUT_PDB DIR_OUTPUT_PDB "_loopy" \
      -setfileparam space_group_name SPACEGROUP \
      -setfileparam cell CELL \
      -command "loopy_update_anchor_menus $arrayname ; loopy_update_spacegroup $arrayname ; loopy_update_basename $arrayname ; loopy_update_proposed_PDB $arrayname "

  OpenSubFrame frame -toggle_display MODE_LOOPY open 0 
  CreateLine line \
      message "Indicate whether a pir-file is used to define the residues in the loop" \
      label "Use pir-file to define the loop sequence" \
      help files \
      widget USE_PIR_FILE
  
  CloseSubFrame

  OpenSubFrame frame -toggle_display USE_PIR_FILE open 1 closed
  CreateExtendingFrame NSEQFILES pir_seq_in \
      "Add an input sequence as a PIR file"  \
      "Add input PIR file"  \
      [list   SEQIN  DIR_SEQIN ] \
      -dependentframe molau \
      -edit set_nrestotal

  CloseSubFrame


  OpenSubFrame frame -toggle-display MODE_LOOPY open 0 closed
  CreateOutputFileLine file_line \
      "Choose name format for the generated loop files" \
      "New loops output file" \
     SAVE_LOOP_NAME DIR_SAVE_LOOP_NAME \
       -help files
  add_file_command $file_line "loopy_update_basename $arrayname"

  CreateOutputFileLine prop_file_line \
      "Choose name format for the proposed full pdb files" \
      "Protein and new loops combined output file" \
     SAVE_PROP_PDB DIR_SAVE_PROP_PDB \
       -help files
  add_file_command $prop_file_line "loopy_update_proposed_PDB $arrayname"
  CloseSubFrame

  OpenSubFrame frame -toggle-display MODE_LOOPY open 1 closed
   CreateOutputFileLine file_line \
      "Choose the filename for the new pdb" \
      "Output file" \
      OUTPUT_PDB DIR_OUTPUT_PDB \
      -help files
  CloseSubFrame

#------------------------------------------------------------------------------
  OpenFolder 1
  #Definition of the loops

  #build all loops using pir-file
  OpenSubFrame frame -toggle_display USE_PIR_FILE open 1 closed
  CreateExtendingFrame NSEQFILES molau \
    "Number of molecules and residues in the AU" \
    " "  \
     [list NMOL \
        NRES \
        NRESMOL \
        MET_IS_SEL ] -noaddline

  CloseSubFrame

  OpenSubFrame frame -toggle_display INCLUDE_ALL open 1
  CreateLine line \
      message "Assume that all chains in the PDB represent protein, and used for loop building" \
      label "Use all the chains of the PDB" \
      help loop_def \
      widget INCLUDE_ALL \
      -command "loopy_set_include_chains $arrayname ; loopy_update_anchor_menus $arrayname"
  CloseSubFrame
  OpenSubFrame frame  -toggle_display INCLUDE_ALL open 0
  CreateLine line \
      message "Assume that all chains in the PDB represent protein, and used for loop building" \
      label "Use all the chains of the PDB" \
      help loop_def \
      widget INCLUDE_ALL \
      -command "loopy_set_include_chains $arrayname ; loopy_update_anchor_menus $arrayname" \
      message "Give the set of chains to use" \
      label "Use chains" \
      help loop_def \
      widget INCLUDE_CHAINS \
      -command "loopy_check_include_chains $arrayname ; loopy_update_anchor_menus $arrayname"
  CloseSubFrame
  

  #build a single loop setting the loop sequence by hand
  OpenSubFrame frame -toggle_display MODE_LOOPY open 0 closed

  CreateLine line \
      message "Select N-term anchor of the loop" \
      label "Build a loop between residues" \
      help loop_def \
      widget C_ANCHOR -command "loopy_update_loop_definition $arrayname" \
      label "and" \
      help loop_def \
      message "Select C-term (of protein) anchor of the loop" \
      widget N_ANCHOR -command "loopy_update_loop_definition $arrayname" \
      message "Give number of peptides INCLUDING anchors" \
      label "; the length of the loop is" \
      help loop_def \
      widget LOOP_LENGTH -width 3 -command "loopy_update_loops_to_build $arrayname"

  CreateLine line \
      message "Loop sequence INCLUDING anchors" \
      label "The loop sequence including the anchors residues above is" \
      help loop_def \
      widget LOOP_SEQUENCE -oblig \
      -command "loopy_check_sequence $arrayname" \
      toggle_display USE_PIR_FILE open 0

  CloseSubFrame

  #settings for general loop building
  
#------------------------------------------------------------------------------
  OpenFolder 2
  #Defining details for generating loops

  OpenSubFrame fram -toggle_display MODE_LOOPY open 1
  CreateLine line \
      message "Maximum number of residues per loop to build" \
      label "Build loops up to" \
      help gen_loop \
      widget MAX_LOOP_LENGTH \
      label "residues long (including anchors)"
  CreateLine line \
      message "Extend loops shorter than a given number of residues (including anchors)" \
      label "Extend loops smaller than" \
      help gen_loop \
      widget EXTEND_GAP_SMALLER_THAN \
      label "residues (including anchors)"
  CloseSubFrame

  OpenSubFrame frame -toggle_display USER_SETTING_MAX_NO_CAS open 1
  CreateLine line \
      message "Maximum number of CAs kept per node in the loop tree" \
      help gen_loop \
      widget USER_SETTING_MAX_NO_CAS \
      label "Override default for maximum number of CAs kept per node in the loop tree" \
      message "Maximum number of CAs kept per node in the loop tree" \
      help gen_loop \
      widget MAX_NO_CAS_KEPT -width 4 \
      label "\tForce minimum number of CAs" \
      help gen_loop \
      widget FORCE_MIN_CAS_KEPT -width 4
  CloseSubFrame

  OpenSubFrame frame -toggle_display USER_SETTING_MAX_NO_CAS open 0
  CreateLine line \
      message "Override the default, and variable (!) maximum number of CAs kept per node in the loop tree" \
      help gen_loop \
      widget USER_SETTING_MAX_NO_CAS \
      label "Override the default maximum number of CAs per node" \
      message "Set minimum number of CAs kept per node (overriding the threshold)" \
      label "\tForce minimum number of CAs" \
      help gen_loop \
      widget FORCE_MIN_CAS_KEPT -width 4
  CloseSubFrame


  CreateLine line \
      message "Set number of best loops to save" \
      label "Suggest " \
      help files \
      widget SAVE_BEST_NUMBER \
      toggle_display MODE_LOOPY open 0 \
      label "alternatives for each loop " 


#------------------------------------------------------------------------------
  OpenFolder 3 closed
  #Selecting best loops
  CreateLine line \
      label "Pruning aberrant loops"
  CreateLine line \
      message "Maximum distance between the (symmetry mates) of the loop anchors" \
      label "\tMaximum loop length (in A)" \
      help loop_selection \
      widget MAX_DISTANCE_BETWEEN_ANCHORS
  CreateLine line \
      message "Deviation from CA-CA bond length of end loop and connecting fragment" \
      label "\tDeviation distance loop connection" \
      help loop_selection \
      widget LOOP_RMS
  CreateLine line \
      message "Number of loops during pruning based on density correlation of CAs" \
      label "\tCA density correlation threshold" \
      help loop_selection \
      widget LOOP_DENSITY_CUTOFF_NO
  CreateLine line \
      message "Threshold according to structural likelihood connection" \
      label "\tStructural threshold" \
      help loop_selection \
      widget LOOP_STRUCTURE_THRESHOLD
  CreateLine line \
      message "Override threshold to secure a minimum of loops at this stage" \
      label "\t\tMinimum loop number for this stage " \
      help loop_selection \
      widget LOOP_STRUCTURE_MIN_NO
  CreateLine line \
      message "Maximum number of loops kept based on structure" \
      label "\t\tMaximum loop number for this stage" \
      help loop_selection \
      widget LOOP_STRUCTURE_CUTOFF_NO
  CreateLine line \
      message "Loop selection based on the density fit of planes for main-chain atoms through succesive CA-pairs" \
      label "\t\tLoops kept after building the main-chain atoms" \
      help loop_selection \
      widget MAX_LOOPS_AFTER_MC_PLANE
  CreateLine line \
      message "Number of best loops kept, selected on the density fit of the main chain (after building the loops in both directions" \
      label "\tMain chain density correlation threshold" \
      help loop_selection \
      widget LOOP_MAIN_CHAIN_DENS_NO
  
#------------------------------------------------------------------------------
  OpenFolder 4 closed
  #Selecting best CAs
  CreateLine line \
      message "Likelihood threshold for rejecting generated CAs" \
      label "Likelihood threshold" \
      help CA_selection \
      widget LIKELIHOOD_THRESHOLD -width 5 \
      message "Show weights of different aspects contributing to threshold" \
      label "\tShow details" \
      widget SHOW_DETAILS_LIKELIHOOD
  OpenSubFrame frame -toggle_display SHOW_DETAILS_LIKELIHOOD open 1
  CreateLine line \
      message "Weight for the likelihood for CA-CA distance" \
      label "\tWeight distance " \
      help CA_selection \
      widget WEIGHT_DISTANCE -width 4
  CreateLine line \
      message "Weight for the density correlation of the CA" \
      label "\tWeight density   " \
      help CA_selection \
      widget WEIGHT_DENSITY -width 4
  CreateLine line \
      message "Weight for the likelihood for the pentapeptide structure" \
      label "\tWeight structure" \
      help CA_selection \
      widget WEIGHT_STRUCTURE -width 4
  CreateInputFileLine line \
      "Probability table for pentapeptide in C-terminus direction" \
      "\tStructure table to C" \
      STRUCTURE_TO_C DIR_STRUCTURE_TO_C \
      -help CA_selection 
  CreateInputFileLine line \
      "Probability table for pentapeptide in N-terminus direction" \
      "\tStructure table to N" \
      STRUCTURE_TO_N DIR_STRUCTURE_TO_N \
      -help CA_selection  
  CloseSubFrame
  CreateLine line \
      message "Set a measure for the minimum distance between generated CAs" \
      label "Minimum distance CAs   " \
      help CA_selection \
      widget MINIMAL_DISTANCE -width 4

#------------------------------------------------------------------------------
  OpenFolder 5 closed
  #generating CAs
  OpenSubFrame frame -toggle_display GRID_TYPE open 0
  CreateLine line \
      message "Select way to generate a shell of CAs" \
      label "Select generation CA shell" \
      help CA_generation \
      widget GRID_TYPE
  CreateLine line \
      message "Number of CAs in a shell" \
      label "\tNumber of CAs" \
      help CA_generation \
      widget GRID_NUMBER -width 5
  CreateLine line \
      message "Set the distance between successive CAs" \
      label "\tCA-CA distance" \
      help CA_generation \
      widget CA_DISTANCE
  CloseSubFrame
  OpenSubFrame frame -toggle_display GRID_TYPE open 1
  CreateLine line \
      message "Select way to generate a shell of CAs" \
      label "Select generation CA shell" \
      help CA_generation \
      widget GRID_TYPE
  CreateLine line \
      message "Number of CAs in a shell" \
      label "\tNumber of CAs" \
      help CA_generation \
      widget GRID_NUMBER -width 5
  CreateLine line \
      message "Set the distance between successive CAs" \
      label "\tCA-CA distance" \
      help CA_generation \
      widget CA_DISTANCE
  CreateLine line \
      message "Set the thickness of the shell" \
      label "\tShell thickness" \
      help CA_generation \
      widget SHELL_THICKNESS -width 4
  CreateLine line \
      message "SD of the gaussian describing the distance probability" \
      label "\tSD CA-CA distance" \
      help CA_generation \
      widget CA_DISTANCE_ERROR -width 4
  CloseSubFrame
  CreateLine line \
      message "Keep CAs with a negative density halfway between CA-CA" \
      label "Keep CAs with negative density halfway" \
      help CA_generation \
      widget KEEP_NEG_DENS_HALFWAY
  
#------------------------------------------------------------------------------
  OpenFolder 6 closed
  #density handling
  OpenSubFrame frame -toggle_display SHOW_DETAILS_DENSITY open 0
  CreateLine line \
      message "Choose method to determine the density fit of the loops. Note: weighted means has a fast implementation" \
      label "Scoring the density fit of the loops by" \
      help density \
      widget FITTARGET \
      message "\tShow details density handling" \
      label "Density details" \
      widget SHOW_DETAILS_DENSITY
  CloseSubFrame
  OpenSubFrame frame -toggle_display SHOW_DETAILS_DENSITY open 1
  CreateLine line \
      message "Choose method to determine the density fit of the loops. Note: weighted means has a fast implementation" \
      label "Scoring the density fit of the loops by" \
      help density \
      widget FITTARGET \
      message "\tShow details density handling" \
      label "Density details" \
      widget SHOW_DETAILS_DENSITY
  CreateLine line \
      label "Details on density handling:"
  CreateLine line \
      message "Atom radius used to determine density correlation" \
      label "\tAtom radius" \
      help density \
      widget ATOM_RADIUS
  CreateLine line \
      message "B factor used for main chain atoms (so those in the PDB are ignored)" \
      label "\tB factor (main chain atoms)" \
      help density \
      widget B_FACTOR
  CreateLine line \
      message "B factor used for side chain atoms (so those in the PDB are ignored)" \
      label "\tB factor (side chain atoms)" \
      help density \
      widget B_FACTOR_SIDE_CHAIN
  CreateLine line \
      message "Remove atoms from the density by setting the density to -factor*density" \
      label "\tRemove atoms by factor   " \
      help density \
      widget REMOVAL_FACTOR
  CreateLine line \
      message "After loop building, check the density correlation of main chain atoms of residues" \
      label "\tDensity threshold residues " \
      help density \
      widget OVERLAP_REMOVAL_THRESHOLD
  CreateLine line \
      message "After loop building, check the density correlation of dummy atoms" \
      label "\tDensity threshold dummies" \
      help density \
      widget DUMMY_REMOVAL_THRESHOLD


  CloseSubFrame


#------------------------------------------------------------------------------
  OpenFolder 7 closed
  CreateLine line \
      message "Space group (from map)" \
      label "Space group" \
      help crystal_params \
      varlabel SPACEGROUP
  
  CreateLine line \
      message "Cell dimensions (default taken from MTZ file" \
      label "Cell          a=" \
      help crystal_params \
      varlabel CELL_1 \
      label "    b=" \
      varlabel CELL_2 \
      label "         c=" \
      varlabel CELL_3 
  CreateLine line \
      label "         alpha=" \
      help crystal_params \
      varlabel CELL_4 \
      label "beta=" \
      varlabel CELL_5 \
      label "gamma=" \
      varlabel CELL_6  

#------------------------------------------------------------------------------
  OpenFolder 8 closed
  #Real-space refinement
  CreateLine line \
      message "Choice whether to run real-space refinement on the loop regions in the output PDBs" \
      label "Apply real-space refinement" \
      help refinement \
      widget REFINEMENT

  OpenSubFrame frame -toggle_display REFINEMENT open 1

  CreateLine line \
      message "Extend the region of the real-space refinement by a number of residues on BOTH sides of the loop" \
      label "Extend the region for real-space refinement by " \
      widget EXTEND_REFINEMENT \
      label "residues" \
      help refinement
  CreateInputFileLine line \
      "Loopfit executable, used for the real-space refinemet of loop regions" \
      "Loopfit executable" \
      LOOPFIT_EXE_FILENAME DIR_LOOPFIT_EXE_FILENAME \
      -toggle REFINEMENT \
      -help refinement
  CreateOutputFileLine line \
      "Filename for the loopfit log, used for the real-space refinement of loop regions" \
      "Loopfit log" \
      LOOPFIT_LOG_FILENAME DIR_LOOPFIT_LOG_FILENAME \
      -toggle REFINEMENT \
      -help refinement
  CloseSubFrame

#------------------------------------------------------------------------------
  OpenFolder 9 closed
  #log files
  CreateLine line \
      message "Level at which to save messages from Loopy (0-9)" \
      label "Message level " \
      help logs \
      widget MESSAGE_LEVEL
  CreateLine line \
      message "Level at which to abort Loopy (0-9)" \
      label "Abort level      " \
      help logs \
      widget ABORT_LEVEL
  CreateOutputFileLine line \
      "Filename for messages" \
      "Message file    " \
      MESSAGE_FILENAME DIR_MESSAGE_FILENAME \
      -help logs
  CreateOutputFileLine line \
      "Filename for messages in XML format" \
      "XML output file" \
      XML_MESSAGE_FILENAME DIR_XML_MESSAGE_FILENAME \
      -help logs

}

#---------------------------------------------------------------------
proc loopy_run { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array
  
  #Check input map/mtz
  set tmp_input_mode [GetValue $arrayname MAP_INPUT_MODE]
  if { [StringSame $tmp_input_mode "MAP"] } {
      set array(INPUT_FILES) " MAP_FILENAME "
      if { [loopy_get_value $arrayname "MAP_FILENAME" "filename of input map" "file" tmp_input_map ] } {
	  if {![file exists $tmp_input_map] || [file isdirectory $tmp_input_map ]} {
	      WarningMessage "  In the file folder:\n  In mode MAP, please insert \n  a existing file for in the input map  "
	      return 0
	  }
      } else {
	  return 0
      }
  } else {
      if { [loopy_get_value $arrayname "MTZ_FILENAME" "filename of input mtz" "file" tmp_input_mtz] } {
      set array(INPUT_FILES) " MTZ_FILENAME "
	  if {![file exists $tmp_input_mtz] || [file isdirectory $tmp_input_mtz ]} {
	      WarningMessage "  In the file folder:\n  In mode MTZ, please insert \n  a existing file for in the input mtz  "
	      return 0
	  }
	  if {[loopy_get_value $arrayname "F1" "F" "file" tmp_f1]} {
	      if { [StringSame $tmp_f1 "Unassigned" ]} {
		  WarningMessage "  In the file folder:\n  Please enter a value for F\n  It is needed to compute the map   "
		  return 0
	      }
	  } else {
	      return 0
	  }
	  if {[loopy_get_value $arrayname "PHI" "PHI" "file" tmp_phi]} {
	      if { [StringSame $tmp_phi "Unassigned" ] } {
		  WarningMessage "  In the file folder:\n  Please enter a value for PHI\n  It is needed to compute the map  "
		  return 0
	      }
	  } else {
	      return 0
	  }
	  if {! [loopy_get_value $arrayname "MAP_FROM_MTZ" "output filename for calculated map" "file" tmp_output_map ]} {
	      return 0
	  }
      } else {
	  return 0
      }
  }

  #check presence input pdb filename
  if {[loopy_get_value $arrayname "PDB_INPUT_FILENAME" "filename input PDB" "file" tmp_input_pdb ]} {
      append array(INPUT_FILES) " PDB_INPUT_FILENAME "
      if { ![file exists $tmp_input_pdb] || [file isdirectory $tmp_input_pdb ] } {
	  WarningMessage "  In the file folder:\n  Please insert a proper filename for the input PDB  "
	  return 0
      }
  } else {
      return 0
  }

  #check presence input pir(s) if needed
  set tmp_mode_loopy [GetValue $arrayname MODE_LOOPY]
  set use_pir_file [GetValue $arrayname USE_PIR_FILE]
  if { $tmp_mode_loopy==1 } {
      if { $use_pir_file==0 } {
	  WarningMessage "  In the file folder:\n An error has occured. Please use pir files in the mode Build all Loops"
	  return 0
      }
  }
  if { $use_pir_file == 1 } {
      if {[loopy_get_value $arrayname "NSEQFILES" "number of sequence files" "file" tmp_seq_n ]} {
	  for { set n 1 } { $n <= $tmp_seq_n } {incr n } {
	      if { ![file exists [GetFullFileName1 $array(SEQIN,$n) $array(DIR_SEQIN,$n) ] ] } {
		  WarningMessage "  In the file folder:\n  Can not open Sequence input file  "
		  return 0
	      } else {
		  append array(INPUT_FILES) " SEQIN,$n "
	      }
	      if { $array(NMOL,$n) == "" } {
		  WarningMessage "  In the folder Definition of the loop(s) parameters:\n  You have to set the number of molecules  "
		  return 0
	      }
	  }
      }
  }


  if {![loopy_check_include_chains $arrayname]} {
      WarningMessage "  In the folder Definition of the loop(s):\n  The list of chains to process doesn't comply with \n  the expected format (A|B|...). Or an unexpected chain was given"
      return 0
  }


  #check crystal parameters
  set tmp_spacegroup [GetValue $arrayname SPACEGROUP ]
  if { ![ loopy_get_value $arrayname "SPACEGROUP" "spacegroup name" "Crystal Parameters" tmp_spacegroup ] } {
      return 0
  } else {
      loopy_update_spacegroup $arrayname
      if { ![GetValue $arrayname SPACEGROUP_NUMBER ]} {
	  WarningMessage "  In the folder Crystal Parameters:\n  Couldn't convert the spacegroup name to a spacegroup number.\n  Please insert a proper spacegroup name"
	  return 0
      }
  }
  if {![loopy_get_value $arrayname "CELL_1" "cell length a" "Crystal Parameters"  tmpC1] } {
      return 0
  }
  if {![loopy_get_value $arrayname "CELL_2" "cell length b" "Crystal Parameters"  tmpC2] } {
      return 0
  }
  if {![loopy_get_value $arrayname "CELL_3" "cell length c" "Crystal Parameters"  tmpC3] } {
      return 0
  }
  if {![loopy_get_value $arrayname "CELL_4" "cell angle alpha" "Crystal Parameters"  tmpC4] } {
      return 0
  }
  if {![loopy_get_value $arrayname "CELL_5" "cell angle beta" "Crystal Parameters"  tmpC5] } {
      return 0
  }
   if {![loopy_get_value $arrayname "CELL_6" "cell angle gamma" "Crystal Parameters"  tmpC6] } {
      return 0
  }
  loopy_calc_cell_volume [list $tmpC1 $tmpC2 $tmpC3 $tmpC4 $tmpC5 $tmpC6 ] tmp_volume
  if { $tmp_volume<=0 } {
      WarningMessage "  In the folder Crystal Parameters:\n  The volume of the cell is <=0\n  Please check the cell dimensions.  \n"
      return 0
  }
  if { $tmpC1<=0 || $tmpC2<=0 || $tmpC3<=0 || $tmpC4<0 || $tmpC4>180 || $tmpC5<0 || $tmpC5>180 || $tmpC6<0 || $tmpC6>180} {
      WarningMessage "  In the folder Crystal Parameters:\n  Please check the cell dimensions"
      return 0
  }

  #check loop definition
  if { $tmp_mode_loopy == 0 } {
      if {![loopy_get_value $arrayname "N_ANCHOR" "n-terminal anchor residue" "Definition of the loop(s)"  tmp_nanchor] } {
	  return 0
      }
      if {![loopy_get_value $arrayname "C_ANCHOR" "c-terminal anchor residue" "Definition of the loop(s)"  tmp_canchor] } {
	  return 0
      }

      if {![loopy_get_value $arrayname "LOOP_LENGTH" "length of the loop" "Definition of the loop(s)"  tmp_length] } {
	  return 0
      }
      set use_pir_file [GetValue $arrayname USE_PIR_FILE]
      if { !$use_pir_file } {
	  if {![loopy_get_value $arrayname "LOOP_SEQUENCE" "sequence of the loop" "Definition of the loop(s)"  tmp_sequence] } {
	  return 0
	  }
      }
      if { $tmp_length <=0 } {
	  WarningMessage "  In the folder Definition of the loop(s):\n  Please enter a loop length larger than zero.  "
	  return 0
      } else {
	  if { !$use_pir_file } {
	      if { $tmp_length != [string length $tmp_sequence] } {
		  WarningMessage "  In the folder Definition of the loop(s):\n  The loop length (${tmp_length}) and the length of the given sequence ([string length $tmp_sequence]) don't comply\n  Please check loop length and the loop sequence  "
		  return 0
	      }
	  }
      }
  } else {
      if {![loopy_get_value $arrayname "MAX_LOOP_LENGTH" "length of the loop" "Settings for generating loops"  tmp_length] } {
	  return 0
      }
      if { $tmp_length>15 } {
	      WarningMessage "  In the folder Settings for generating loops :\n  The maximum loop length (${tmp_length}) is set larger than 15. Be aware that computation of this loop length can take a lot of time and memory  " \
		-button Acknowledge
      }
  }

  #check parameters for selecting the best loops
  if {![loopy_get_value $arrayname "MAX_DISTANCE_BETWEEN_ANCHORS" "the maximum loop length (in A)" "Selecting best loops"  tmp_distance] } {
      return 0
  } else {
      if { $tmp_distance<=0 && $tmp_distance!=-1} {
	  WarningMessage "  In the folder Selecting best loops:\n  The maximum loop length (in A) should be larger than zero (or, to turn it off: -1).  "
	  return 0
      }
  }
  if {![loopy_get_value $arrayname "LOOP_RMS" "error in distance between loop CA and connecting CA" "Selecting best loops"  tmp_distance] } {
      return 0
  } else {
      if { $tmp_distance<=0 } {
	  WarningMessage "  In the folder Selecting best loops:\n  The error in the distance between the suggested loop CA  \n  and the connecting CA should be larger than zero.  "
	  return 0
      }
  }
  if {![loopy_get_value $arrayname "LOOP_STRUCTURE_THRESHOLD" "structural threshold" "Selecting best loops"  tmp_struct_threshold] } {
      return 0
  } else {
      if { $tmp_struct_threshold > 0 } {
	  set tmp_option [ ChooseOptionDialog "Positive threshold?" icon \
			   "  In the folder Selecting best loops:\n  The structure threshold is for the log of a probability, which is always negative.\n            Are you certain you want a positive threshold?" \
			   { NO YES } 1 -default ]
	  if { [StringSame $tmp_option "NO" ] } {
	      return 0;
	  }   
      }
  }
  if {![loopy_get_value $arrayname "LOOP_STRUCTURE_MIN_NO" "the minimum number of loops to keep after structure checking" "Selecting best loops"  tmp_struct_min] } {
      return 0
  } else {
      if { $tmp_struct_min < 0 } {
	  WarningMessage "  In the folder Selecting best loops:\n  The minimum number of loops to keep after checking on structure  \n  has to be >=0."
	  return 0 
      }
  }
  if {![loopy_get_value $arrayname "LOOP_STRUCTURE_CUTOFF_NO" "the maximum number of loops to keep after structure checking" "Selecting best loops"  tmp_struct_cutoff ] } {
      return 0
  } else {
      if { $tmp_struct_cutoff == 0 || $tmp_struct_cutoff<-1} {
	  WarningMessage "  In the folder Selecting best loops:\n  The maximum number of loops to keep after checking on structure  \n  has to be >0 (or -1 to set no maximum)."
	  return 0 
      }
      if { $tmp_struct_cutoff < $tmp_struct_min && $tmp_struct_cutoff!=-1 } {
	  WarningMessage "  In the folder Selecting best loops:\n  The minimum number of loops to keep after checking on structure  \n  exceeds the maximum number to keep.\n  Please check."
	  return 0 
      }
  }

  #check input folder Selecting best CAs
    #only need to check presence of a value
  if {![loopy_get_value $arrayname "LIKELIHOOD_THRESHOLD" "the likelihood threshold" "Selecting best CAs"  tmp ] } {
      return 0
  }
  if {![loopy_get_value $arrayname "WEIGHT_DISTANCE" "the weight for the distance likelihood" "Selecting best CAs"  tmp ] } {
      return 0
  }
  if {![loopy_get_value $arrayname "WEIGHT_DENSITY" "the weight for the density likelihood" "Selecting best CAs"  tmp ] } {
      return 0
  }
  if {![loopy_get_value $arrayname "WEIGHT_STRUCTURE" "the weight for the structural likelihood" "Selecting best CAs"  tmp ] } {
      return 0
  }

  #checking folder Generating CAs
  loopy_get_value $arrayname "GRID_TYPE" "type of grid" "Generating CAs" tmp_grid_type 
  if { $tmp_grid_type == 1 } {
      #random grid -> extra parameters
      if {[loopy_get_value $arrayname "SHELL_THICKNESS" "thickness of CA shell" "Generating CAs" tmp_thickness]} {
	  if { $tmp_thickness < 0 } {
	      WarningMessage "  In the folder Generating CAs:  \n  Please enter a positive value for the shell thickness."
	      return 0
	  }
      } else {
	  return 0
      }
      if {[loopy_get_value $arrayname "CA_DISTANCE_ERROR" "standard deviation in distribution distance CA-CA" "Generating CAs" tmp_distance_error]} {
	  if { $tmp_distance_error < 0 } {
	      WarningMessage "  In the folder Generating CAs:  \n  Please enter a positive value for the standard deviation in the gaussian distribution for the CA-CA distance."
	      return 0
	  }
      } else {
	  return 0
      }
  }
  if {[loopy_get_value $arrayname "GRID_NUMBER" "number of CAs per shell" "Generating CAs" tmp_number]} {
      set tmp_number [ loopy_get_fibonacci $tmp_grid_type $tmp_number ]
      if { $tmp_number <= 0 } {
	  WarningMessage "  In the folder Generating CAs:  \n  Please enter a value larger than zero for the number of CAs per shell."
	  return 0
      }
  } else {
      return 0
  }
  if {[loopy_get_value $arrayname "CA_DISTANCE" "the distance between succesive CAs" "Generating CAs" tmp_number]} {
      if { $tmp_number <= 0 } {
	  WarningMessage "  In the folder Generating CAs:  \n  Please enter a value larger than zero for the distance between successive CAs."
	  return 0
      } else {
	  set tmp_error [ expr { abs ( $tmp_number - 3.8 ) } ]
	  if { $tmp_error > 1 } {
	      set tmp_option [ ChooseOptionDialog "Expected CA-CA distance ~ 3.8 A" icon \
			   "  In the folder Generating CAs:\n  Expected a CA-CA distance of around 3.8 A. \n            Are you certain of $tmp_number A ?" \
			   { NO YES } 1 -default ]
	      if { [StringSame $tmp_option "NO" ] } {
		  return 0;
	      }
	  }
      }
  } else {
      return 0
  }

    #check whether file exists
  if {![loopy_get_value $arrayname "STRUCTURE_TO_C" "the filename for the structure table towards C terminus" "Selecting best CAs (detailed settings)"  tmp_structurefile_toc ] } {
      return 0
  } else {
      if {! [file readable $tmp_structurefile_toc ] } {
	  WarningMessage "  In the folder Selecting best CAs (detailed settings)\n  Can't read the file containing the structure table   \n  towards the C terminus. Please select a proper file."
	  return 0
      }
  }
  if {![loopy_get_value $arrayname "STRUCTURE_TO_N" "the filename for the structure table towards N terminus" "Selecting best CAs (detailed settings)"  tmp_structurefile_ton ] } {
      return 0
  } else {
      if {! [file readable $tmp_structurefile_ton ] } {
	  WarningMessage "  In the folder Selecting best CAs (detailed settings)\n  Can't read the file containing the structure table   \n  towards the N terminus. Please select a proper file."
	  return 0
      }
  }
  if {![loopy_get_value $arrayname "MINIMAL_DISTANCE" "the filename minimal distance between selected CAs" "Selecting best CAs"  tmp ] } {
      return 0
  } 
  
  if { [ loopy_get_value $arrayname "MAX_NO_CAS_KEPT" "maximum number of CAs selected" "Settings for generating loops" tmp_max_no_cas ] } {
      if { $tmp_max_no_cas <=0 } {
	  WarningMessage "  In the folder Settings for generating loops\n  Please enter a value larger than zero  \n  for the maximum number of CAs selected."
	  return 0
      }
  } else {
      return 0
  }
  if { [ loopy_get_value $arrayname "FORCE_MIN_CAS_KEPT" "the minimum number of CAs to try to keep" "Settings for generating loops" tmp_min_no_cas ] } {
      if { $tmp_max_no_cas < $tmp_min_no_cas } {
	  WarningMessage "  In the folder Settings for generating loops\n  The minimum number of CAs to keep exceeds  \n  the maximum number. Please check"
	  return 0
      }
  } else {
      return 0
  }

  #check folder density handling
  if { [ loopy_get_value $arrayname "ATOM_RADIUS" "the atom radius" "Density Handling" tmp_atom_radius ] } {
      if { $tmp_atom_radius<=0 } {
	  WarningMessage "  In the folder Density Handling\n  Please set a value larger than zero for the atom radius"
	  return 0
      }
  } else {
      return 0
  }
  if { ![ loopy_get_value $arrayname "B_FACTOR" "the b-factor for main chain atoms" "Density Handling" tmp ] } {
      return 0
  }
  if { ![ loopy_get_value $arrayname "B_FACTOR_SIDE_CHAIN" "the b-factor for side chain atoms" "Density Handling" tmp ] } {
      return 0
  }
  if { [ loopy_get_value $arrayname "REMOVAL_FACTOR" "'remove atoms by factor'" "Density Handling" tmp ] } {
      if { $tmp < 0 } {
	  WarningMessage "  In the folder Density Handling\n  A factor smaller than zero will enhance the density at the spot of the atom. Please give a positive value"
	  return 0
      }
  } else {
      return 0
  }
  if { ![ loopy_get_value $arrayname "OVERLAP_REMOVAL_THRESHOLD" "the density threshold to assume overlap of residues with the loop" "Density Handling" tmp ] } {
      return 0
  }
  if { ![ loopy_get_value $arrayname "DUMMY_REMOVAL_THRESHOLD" "the density threshold to assume overlap of a dummy with the loop" "Density Handling" tmp ] } {
      return 0
  }
  
  #check the refinement folder
  if { [loopy_get_value $arrayname "REFINEMENT" "applying real-space refinement" "Real-space refinement" tmp_refine] } {
      if { $tmp_refine==1 } {
	  if { [loopy_get_value $arrayname "LOOPFIT_EXE_FILENAME" "loopfit executable for applying real-space refinement" "Real-space refinement" tmp_exe] } {
	      if { ![file executable $tmp_exe]} {
		  WarningMessage "  In the folder Real-space refinement\n Please select the loopfit executable to apply the real-space refinement"
		  return 0
	      }
	  } else {
		  WarningMessage "  In the folder Real-space refinement\n Please select the loopfit executable to apply the real-space refinement"
		  return 0
	  }
	  if { [loopy_get_value $arrayname "EXTEND_REFINEMENT" "loopfit executable for applying real-space refinement" "Real-space refinement" tmp] } {
	      if { $tmp<0 } {
		  WarningMessage "  In the folder Real-space refinement\n Please choose a positive number of residues to extend the region for real-space refinement"
	      }
	  }
      }
  }

  #check folder log names
  if { [ loopy_get_value $arrayname "MESSAGE_LEVEL" "the level for messages" "Log files of Loopy" tmp_message_level ] } {
      if { $tmp_message_level<0 || $tmp_message_level>8} {
	  WarningMessage "  In the folder Log files for Loopy\n  The level for messages should be a value in the region\[0,8\]"
	  return 0
      }
  } else {
      return 0
  }
  if { [ loopy_get_value $arrayname "ABORT_LEVEL" "the level for terminating the program" "Log files of Loopy" tmp_abort_level ] } {
      if { $tmp_abort_level<0 || $tmp_abort_level>8} {
	  WarningMessage "  In the folder Log files for Loopy\n  The level for termination of the program should be a value in the region\[0,8\]"
	  return 0
      }
  } else {
      return 0
  }

  set tmp_message [GetFullFileName0 $arrayname MESSAGE_FILENAME]   
  set tmp_xml_message  [GetFullFileName0 $arrayname XML_MESSAGE_FILENAME]

#  if { ![ loopy_get_value $arrayname "MESSAGE_FILENAME" "the name of the message file" "Log files of Loopy" tmp_message ] } {
#      return 0
#  } else {
#      if { ![ file writable $tmp_message ] } {
#	  WarningMessage "  In the folder Log files of Loopy  \n  Can't write to the given message file.\n  Please choose another filename."
#      }
#  }
#  if { ![ loopy_get_value $arrayname "XML_MESSAGE_FILENAME" "the name of the XML message file" "Log files of Loopy" tmp_xml_message ] } {
#      return 0
#  } else {
#      if { ![ file writable $tmp_xml_message ] } {
#	  WarningMessage "  In the folder Log files of Loopy  \n  Can't write to the given XML message file.\n  Please choose another filename."
#      }
#  }
  
  #check presence name for output loops
  if { ![ loopy_get_value $arrayname "SAVE_LOOP_NAME" "the name of the output loops" "file" tmp_loop_name ] } {
      return 0
  } else {
      loopy_update_basename $arrayname
      set tmp_base_dir [ GetValue $arrayname SAVE_LOOP_DIR ]
      set tmp_base_name [ GetValue $arrayname SAVE_LOOP_BASENAME ]
      if { [string is space $tmp_base_name ] } {
	  WarningMessage "  Couldn't extract a format for the loop output.\n  Please enter a proper name for the first output file.  "
	  return 0;
      }
      if { [StringSame $tmp_base_dir "/" ] } {
	  set tmp_option [ ChooseOptionDialog "Writing to root directory?" icon \
			       "  You have chosen the root directory to save the loops.\n            Are you certain?" \
			       { NO YES } 1 -default ]
	  if { [StringSame $tmp_option "NO" ] } {
	      return 0;
	  }
      }
  }

  #check presence name for output loops
  if { ![ loopy_get_value $arrayname "SAVE_PROP_PDB" "the name of the proposed full PDBs" "file" tmp_loop_name ] } {
      return 0
  } else {
      loopy_update_proposed_PDB $arrayname
      set tmp_base_dir [ GetValue $arrayname SAVE_LOOP_PROP_DIR ]
      set tmp_base_name [ GetValue $arrayname SAVE_LOOP_PROP_BASE ]
      if { [string is space $tmp_base_name ] } {
	  WarningMessage "  Couldn't extract a format for the proposed full PDBs.\n  Please enter a proper name for the first file.  "
	  return 0;
      }
      if { [StringSame $tmp_base_dir "/" ] } {
	  set tmp_option [ ChooseOptionDialog "Writing to root directory?" icon \
			       "  You have chosen the root directory to save the loops.\n            Are you certain?" \
			       { NO YES } 1 -default ]
	  if { [StringSame $tmp_option "NO" ] } {
	      return 0;
	  }
      }
  }
  source [SearchPath TOP src execute.tcl]
  return 1
}

#---------------------------------------------------------------------
proc loopy_get_value { arrayname key description folder value  } {
#---------------------------------------------------------------------
    upvar #0 $arrayname array
    upvar $value tmp_value
    set tmp_exists 0
    set tmp_value [ GetValue $arrayname $key ]
    if { [ ElementExists $arrayname $key ] && ![ string is space $tmp_value ] } {
	set tmp_exists 1
    } else {
	WarningMessage "  In the folder $folder:\n  Please insert a value for $description."
    }
    return $tmp_exists
}

#switch the default to use the sequence with the mode of loop building
#---------------------------------------------------------------------
proc loopy_set_use_sequence { arrayname } {
#---------------------------------------------------------------------
    upvar #0 $arrayname array
    set tmp_value [ GetValue $arrayname MODE_LOOPY ]
    #with each switch to MODE_LOOPY == 1, return the value to 1... previously USE_PIR_FILE was set to MODE_LOOPY with each switch
    if { $tmp_value==1 } {
	set array(USE_PIR_FILE) $tmp_value
    }
    return 1
}

#---------------------------------------------------------------------
proc loopy_get_fibonacci { grid_type grid_no  } {
#---------------------------------------------------------------------
    if { !$grid_type } {
	#regular grid
	set number [ loopy_compute_fibonacci $grid_no ]
	return $number
    } else {
	return $grid_no
    }
}

#---------------------------------------------------------------------
proc loopy_compute_fibonacci { number  } {
#---------------------------------------------------------------------
    set tmpFibA 0
    set tmpFibB 1
    set tmpFibC [ expr { $tmpFibA + $tmpFibB } ]
    if { $number != 0 } {
	while { $tmpFibC <= $number } {
	    set tmpFibA $tmpFibB
	    set tmpFibB $tmpFibC
	    set tmpFibC [ expr { $tmpFibA + $tmpFibB } ]
	}
	return $tmpFibB
    }
    return 0
}

#---------------------------------------------------------------------
proc loopy_calc_cell_volume { cell volumeVar  } {
#---------------------------------------------------------------------
#copy paste from CCP4I_TOP/utils/map_utils.tcl... CalcCellVolume missed a closing bracket
#d_sum Calculate the cell volume
#d_arg cell Cell dimensions
#d_arg volumeVar Returned cell volume
  upvar $volumeVar volume

# cell - input list of cell parameters
# volume  - return cell volume

  set dtor  3.1415927/180.0
  set a [lindex $cell 0]
  set b [lindex $cell 1]
  set c [lindex $cell 2]
  set al [expr [lindex $cell 3] * $dtor ]
  set be [expr [lindex $cell 4] * $dtor ]
  set g [expr [lindex $cell 5] * $dtor ]

  set volume [ expr { ( $a * $b * $c ) *  ( sqrt  ( 1 +  2 * cos($al) * cos($be) * cos($g) -  pow (cos($al) ,2) -  pow (cos($be) ,2)-  pow (cos($g) ,2)  ) ) } ]
  
}


#---------------------------------------------------------------------
proc loopy_update_basename { arrayname } {
#---------------------------------------------------------------------
    upvar #0 $arrayname array
    set tmp_name [GetValue $arrayname SAVE_LOOP_NAME]
    if { ![ StringSame $tmp_name "" ] } {
	set tmp_dir [GetValue $arrayname DIR_SAVE_LOOP_NAME]
	set tmp_pos_dot [string last "." $tmp_name]
	set tmp_cur_pos [expr {$tmp_pos_dot - 1 } ]
	while { [string match {[0-9]} [string index $tmp_name $tmp_cur_pos] ] && $tmp_cur_pos > 0 } {
	    set tmp_cur_pos [expr {$tmp_cur_pos - 1 } ]
	}
	if { $tmp_cur_pos > 0 } {
	    set tmp_basename [string range $tmp_name 0 $tmp_cur_pos ]
	    if { [string is space $tmp_basename ] } {
		WarningMessage "  There are only blank spaces before the extension.\n  Please enter a proper name.  "
		set array(SAVE_LOOP_BASENAME) ""
		set array(SAVE_LOOP_DIR) ""
		return
	    }
	} else {
	    #no extension found
	    set tmp_basename $tmp_name
	    if { [string is space $tmp_basename] } {
		WarningMessage "  There are only blank spaces before the extension.\n  Please enter a proper name.  "
		set array(SAVE_LOOP_BASENAME) ""
		set array(SAVE_LOOP_DIR) ""
		return
	    }
	}
#	WarningMessage "Saving loops as:\n\n   ${tmp_basename}<i>.pdb   "
	set array(SAVE_LOOP_BASENAME) [ file tail $tmp_basename ]
	set array(SAVE_LOOP_DIR) [ file dirname $tmp_basename ]
    } else {
	set array(SAVE_LOOP_BASENAME) ""
	set array(SAVE_LOOP_DIR) ""
    }
}

#---------------------------------------------------------------------
proc loopy_update_proposed_PDB { arrayname } {
#---------------------------------------------------------------------
    upvar #0 $arrayname array
    set tmp_name [GetValue $arrayname SAVE_PROP_PDB]
    if { ![ StringSame $tmp_name "" ] } {
	set tmp_dir [GetValue $arrayname DIR_SAVE_PROP_PDB]
	set tmp_pos_dot [string last "." $tmp_name]
	set tmp_cur_pos [expr {$tmp_pos_dot - 1 } ]
	while { [string match {[0-9]} [string index $tmp_name $tmp_cur_pos] ] && $tmp_cur_pos > 0 } {
	    set tmp_cur_pos [expr {$tmp_cur_pos - 1 } ]
	}
	if { $tmp_cur_pos > 0 } {
	    set tmp_basename [string range $tmp_name 0 $tmp_cur_pos ]
	    if { [string is space $tmp_basename ] } {
		WarningMessage "  There are only blank spaces before the extension.\n  Please enter a proper name.  "
		set array(SAVE_LOOP_PROP_BASE) ""
		set array(SAVE_LOOP_PROP_DIR) ""
		return
	    }
	} else {
	    #no extension found
	    set tmp_basename $tmp_name
	    if { [string is space $tmp_basename] } {
		WarningMessage "  There are only blank spaces before the extension.\n  Please enter a proper name.  "
		set array(SAVE_LOOP_PROP_BASE) ""
		set array(SAVE_LOOP_PROP_DIR) ""
		return
	    }
	}
#	WarningMessage "Saving loops as:\n\n   ${tmp_basename}<i>.pdb   "
	set array(SAVE_LOOP_PROP_BASE) [ file tail $tmp_basename ]
	set array(SAVE_LOOP_PROP_DIR) [ file dirname $tmp_basename ]
    } else {
	set array(SAVE_LOOP_PROP_BASE) ""
	set array(SAVE_LOOP_PROP_DIR) ""
    }
}

#----------------------------------------------------------------------
proc pir_seq_in { arrayname counter } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array
  global configure

  CreateInputFileLine line \
    "Enter input sequence file $counter name" \
    "Sequence file" \
     SEQIN DIR_SEQIN \
     -command "is_pir_file $arrayname $counter" 
}

#----------------------------------------------------------------------
proc molau { arrayname counter } {
#----------------------------------------------------------------------

  CreateLine line \
    label "For sequence #$counter there are" \
    widget NMOL -oblig \
    -command "set_nres $arrayname $counter" \
    label " molecules in the AU (" \
    varlabel NRESMOL \
    label " residues per molecule, " \
    varlabel NRES \
    label " total in the AU )."
  CreateLine line \
    label "The Methionine residues of this molecule " \
    widget MET_IS_SEL \
    label " Seleno-Methionines."
}
#--------------------------------------------------------------------
proc set_nrestotal { arrayname args } {
  upvar #0 $arrayname array

  set nrestotal 0
  for { set n 1 } { $n <= $array(NSEQFILES) } {incr n } {
    if { $array(NRES,$n) != "" } {
      set nrestotal [expr $array(NRES,$n) + $nrestotal ]
    }
  }
  set array(NRESTOTAL) $nrestotal
}

#---------------------------------------------------------------------
proc loopy_check_sequence { arrayname } {
#---------------------------------------------------------------------
    upvar #0 $arrayname array
    set sequence [string trim [GetValue $arrayname LOOP_SEQUENCE ] ]
    set looplength [GetValue $arrayname LOOP_LENGTH ]
    set pos_pep {[+AVFPQMILDEKRSTYHCNQWG]}
    set array(NO_SEQUENCE) 1
    if { [string length $sequence ] != $looplength } {
	WarningMessage "Expected a sequence consisting of $looplength characters"
	set array(LOOP_SEQUENCE) ""
    } else {
	set okay 1
	set unexpected "\n  (index : character)"
	for {set i 0} {$i<$looplength} {incr i} {
	    set peptide [string index $sequence $i]
	    if { [string match -nocase $pos_pep $peptide ] == 0 } {
		set unexpected "$unexpected\n      $i    :   $peptide"
		set okay 0
	    }
	}
	if { $okay == 0 } {
	    set array(NO_SEQUENCE) 1
	    WarningMessage "Sequence contains unexpected characters:$unexpected\nPlease rectify the sequence" 
	} else {
	    set array(NO_SEQUENCE) 0
	    set array(LOOP_SEQUENCE) [string toupper [string trim [GetValue $arrayname LOOP_SEQUENCE ] ] ]
	}
    }    
}

#------------------------------------------------------------------------
proc loopy_update_spacegroup { arrayname } {
#------------------------------------------------------------------------
    upvar #0 $arrayname array
    set array(SPACEGROUP_NUMBER) [GetSpaceGroupNumber [GetValue $arrayname SPACEGROUP]]
}

#---------------------------------------------------------------------
proc loopy_update_loop_definition { arrayname } {
#---------------------------------------------------------------------
    upvar #0 $arrayname array
    set n_anchor [GetValue $arrayname N_ANCHOR]
    set n_anchor [string trim $n_anchor]
    set c_anchor [GetValue $arrayname C_ANCHOR]
    set c_anchor [string trim $c_anchor]
    set loop_length [GetValue $arrayname LOOP_LENGTH]
    if {![StringSame $n_anchor ""] && ![StringSame $c_anchor ""]} {
	set n_sep [string first " " $n_anchor]
	set n_chain [string trim [string range $n_anchor 0 $n_sep]]
	set n_res [string trim [string range $n_anchor $n_sep [string length $n_anchor] ] ]
	set c_sep [string first " " $c_anchor]
	set c_chain [string trim [string range $c_anchor 0 $c_sep]]
	set c_res [string trim [string range $c_anchor $c_sep [string length $c_anchor] ] ]
	if {[StringSame $n_chain $c_chain] && $c_res<$n_res} {
	    set loop_length [expr {$n_res - $c_res + 1}]
	    set array(LOOP_LENGTH) $loop_length
	}
	if { $loop_length > 15 } {
	    WarningMessage "The selected loop is more than 15 residues long (including anchors). Please be aware that building this loop might use a lot of memory and take a lot of time"
	}
	#update loops_to_build
	set loops_to_build "${c_chain}${c_res}(${loop_length})${n_chain}${n_res}"
	set array(LOOPS_TO_BUILD) $loops_to_build
    }
}
#---------------------------------------------------------------------
proc loopy_update_loops_to_build { arrayname } {
#---------------------------------------------------------------------
    upvar #0 $arrayname array
    set n_anchor [GetValue $arrayname N_ANCHOR]
    set n_anchor [string trim $n_anchor]
    set c_anchor [GetValue $arrayname C_ANCHOR]
    set c_anchor [string trim $c_anchor]
    set loop_length [GetValue $arrayname LOOP_LENGTH]
    if {![StringSame $n_anchor ""] && ![StringSame $c_anchor ""]} {
	set n_sep [string first " " $n_anchor]
	set n_chain [string trim [string range $n_anchor 0 $n_sep]]
	set n_res [string trim [string range $n_anchor $n_sep [string length $n_anchor] ] ]
	set c_sep [string first " " $c_anchor]
	set c_chain [string trim [string range $c_anchor 0 $c_sep]]
	set c_res [string trim [string range $c_anchor $c_sep [string length $c_anchor] ] ]
	#update loops_to_build
	set loops_to_build "${c_chain}${c_res}(${loop_length})${n_chain}${n_res}"
	set array(LOOPS_TO_BUILD) $loops_to_build
    }
}

#------------------------------------------------------------------------
proc loopy_set_include_chains { arrayname } {
#------------------------------------------------------------------------
# Set the variable INCLUDE_CHAINS according to the given pdb
    upvar #0 $arrayname array
    set tmp_all_chains [GetValue $arrayname INCLUDE_ALL]
    set tmp_include_chains ""
    if { $tmp_all_chains == 0 } {
	if { [llength [info procs PdbGetSegID]] <= 0 } {
	    source [SearchPath TOP utils pdb_utils.tcl] }
	if { ![file exists [GetFullFileName0 $arrayname PDB_INPUT_FILENAME]]  ||
	     ![PdbGetSegID [GetFullFileName0 $arrayname PDB_INPUT_FILENAME] chains chainranges] } {
	    return 0 }
	
	set tmp_size [expr {[llength $chains] -1 } ]
	if {$tmp_size>-1} {
	    set tmp_include_chains "("
	    for { set i 0 } { $i < $tmp_size } { incr i } {
		set tmp_include_chains "${tmp_include_chains}[lindex $chains $i]|"
	    }
	    set tmp_include_chains "${tmp_include_chains}[lindex $chains $tmp_size])"
	}
    }
    set array(INCLUDE_CHAINS) $tmp_include_chains
}

#------------------------------------------------------------------------
proc loopy_check_include_chains { arrayname } {
#------------------------------------------------------------------------
# Check whether the variable INCLUDE_CHAINS complies with the format
    upvar #0 $arrayname def_array
    set tmp_include_chains [GetValue $arrayname INCLUDE_CHAINS]
    set tmp_new ""
    if { $tmp_include_chains == $tmp_new } {
	return 1
    }
    #convert given string to list
    set tmp_length [string length $tmp_include_chains]
    #search start
    set tmp_start 0
    set tmp_count 0
    if { [llength [info procs PdbGetSegID]] <= 0 } {
	source [SearchPath TOP utils pdb_utils.tcl] }
    if { ![file exists [GetFullFileName0 $arrayname PDB_INPUT_FILENAME]]  ||
	 ![PdbGetSegID [GetFullFileName0 $arrayname PDB_INPUT_FILENAME] chains chainranges] } {
	return 0 }
   

    while { $tmp_start==0 && $tmp_count<$tmp_length } {
	if { [string index $tmp_include_chains $tmp_count]=="\("} {
	    set tmp_start 1
	    set tmp_new "\("
	    set tmp_count [expr {$tmp_count + 1} ]
	} elseif { [string index $tmp_include_chains $tmp_count]==" "} {
	    set tmp_count [expr {$tmp_count + 1} ]
	} else {
	    set tmp_count $tmp_length
	}
    }
    if { $tmp_start==0 } {
	WarningMessage "Please set the included chains, using the format (A|B|C|...)"
	return 0
    } else {
	set tmp_chain 0
	set tmp_sep 1
	set tmp_current ""
	while { $tmp_count<$tmp_length && [string index $tmp_include_chains $tmp_count]!="\)" } {
	    if { $tmp_chain } {
		if { [string index $tmp_include_chains $tmp_count ]=="|" } {
		    set tmp_chain 0
		    set tmp_sep 1
		} else {
		    if { [ string index $tmp_include_chains $tmp_count]!=" "} {
			set tmp_current "${tmp_current}[string index $tmp_include_chains $tmp_count]"
		    }
		} 
	    } else {
		if {$tmp_sep} {
		    if {[lsearch $chains $tmp_current]!=-1} {
			set tmp_chain 1
			set tmp_sep 0
			set tmp_new "${tmp_new}$tmp_current|"
			set tmp_current ""
		    } else {
			set tmp_chain 0
			set tmp_sep 0
			set tmp_current ""
		    }
		    if {[string index $tmp_include_chains $tmp_count]!=" " && $tmp_sep==0} {
			set tmp_chain 1
			set tmp_current "${tmp_current}[string index $tmp_include_chains $tmp_count]"
		    }
		}
	    }
	    set tmp_count [expr {${tmp_count}+1}]
	}
	if { [string index $tmp_include_chains $tmp_count]=="\)" } {
	    if { $tmp_current == "" } {
		set tmp_new "${tmp_new}\)"
	    } else {
		if {[lsearch $chains $tmp_current]!=-1} {
		    set tmp_new "${tmp_new}${tmp_current}\)"
		} else {
		    set tmp_new "${tmp_new}\)"
		}
	    }
	    return 1
	} else {
	    WarningMessage "Please set the included chains, using the format (A|B|C|...)"
	    return 0
	}
    }
}
    
#------------------------------------------------------------------------
proc loopy_get_include_chains { arrayname chain_list} {
#------------------------------------------------------------------------
# Get the list of chains to use (needed for the drop down menus for the C/N Termini).
#    upvar #0 $arrayname def_array
    upvar $chain_list include_chains
    set tmp_include_chains [GetValue $arrayname INCLUDE_CHAINS]
    set tmp_new ""
    set include_chains [list]
    if { $tmp_include_chains == $tmp_new } {
	return 1
    }
    set tmp_all [GetValue $arrayname INCLUDE_ALL]
    if { $tmp_all } {
	return 1
    }

    #convert given string to list
    set tmp_length [string length $tmp_include_chains]
    #search start
    set tmp_start 0
    set tmp_count 0  

    if { [llength [info procs PdbGetSegID]] <= 0 } {
	source [SearchPath TOP utils pdb_utils.tcl] }
    if { ![file exists [GetFullFileName0 $arrayname PDB_INPUT_FILENAME]]  ||
	 ![PdbGetSegID [GetFullFileName0 $arrayname PDB_INPUT_FILENAME] chains chainranges] } {
	return 0 }
    while { $tmp_start==0 && $tmp_count<$tmp_length } {
	if { [string index $tmp_include_chains $tmp_count]=="\("} {
	    set tmp_start 1
	    set tmp_count [expr {$tmp_count + 1} ]
	} elseif { [string index $tmp_include_chains $tmp_count]==" "} {
	    set tmp_count [expr {$tmp_count + 1} ]
	} else {
	    set tmp_count $tmp_length
	}
    }
    if { $tmp_start==0 } {
	return 1
    } else {
	set tmp_chain 0
	set tmp_sep 1
	set tmp_current ""
	while { $tmp_count<$tmp_length && [string index $tmp_include_chains $tmp_count]!="\)" } {
	    if { $tmp_chain } {
		if { [string index $tmp_include_chains $tmp_count ]=="|" } {
		    set tmp_chain 0
		    set tmp_sep 1
		} else {
		    if { [ string index $tmp_include_chains $tmp_count]!=" "} {
			set tmp_current "${tmp_current}[string index $tmp_include_chains $tmp_count]"
		    }
		} 
	    } else {
		if {$tmp_sep} {
		    if {[lsearch $chains $tmp_current]!=-1} {
			set tmp_chain 1
			set tmp_sep 0
			lappend include_chains $tmp_current
			set tmp_current ""
		    } else {
			set tmp_chain 0
			set tmp_sep 0
			set tmp_current ""
		    }
		    if {[string index $tmp_include_chains $tmp_count]!=" " && $tmp_sep==0} {
			set tmp_chain 1
			set tmp_current "${tmp_current}[string index $tmp_include_chains $tmp_count]"
		    }
		}
	    }
	    set tmp_count [expr {${tmp_count}+1}]
	}
	if { [string index $tmp_include_chains $tmp_count]=="\)" } {
	    if { $tmp_current != "" } {
		if {[lsearch $chains $tmp_current]!=-1} {
		    lappend include_chains $tmp_current
		}
	    }
	}
	return 1
    }
}

#------------------------------------------------------------------------
proc loopy_update_anchor_menus { arrayname } {
#------------------------------------------------------------------------
# Update the chain variable menu (CHAIN_ID_MENU) which is used in 
# defining non-xtal symmetry restraints
    upvar #0 $arrayname def_array
    if { ![file exists [GetFullFileName0 $arrayname PDB_INPUT_FILENAME]]  ||
	 ![PdbGetNandCTermini [GetFullFileName0 $arrayname PDB_INPUT_FILENAME] nTerms cTerms $arrayname] } {
	return 0 }
    
    UpdateVariableMenu $arrayname initialise 0 N_ANCHOR_ID_MENU  $nTerms
    UpdateVariableMenu $arrayname initialise 0 C_ANCHOR_ID_MENU  $cTerms
    set def_array(N_ANCHOR) ""
    set def_array(C_ANCHOR) ""

    set def_array(LOOP_LENGTH) 0
    set def_array(LOOP_SEQUENCE) ""
    return 1
}

#----------------------------------------------------------------------------
proc GetNoSpaceSegID { chainID segID } {
#----------------------------------------------------------------------------
#chainID chainID of the residue in the PDB
#segID segment ID of the residue in the PDB
#return the segment ID to use. If segID is empty, use the chainID. replace (right justified) spaces with the letter A
    set cur_segID [string trim $segID]
    if { $cur_segID == "" } {
	set cur_setID $chainID
    }
    set cur_segID [string toupper $cur_segID]
    set cur_segID [string map { {} A} $cur_segID]
    set cur_length [expr 4 - [string length $cur_segID]]
    set cur_append [string repeat A $cur_length]
    append cur_append $cur_segID
    return $cur_append
}

#----------------------------------------------------------------------------
proc PdbGetNandCTermini { file nTermini cTermini arrayname} {
#----------------------------------------------------------------------------
#d_sum Get a list of the chains and the first & last residue ids in a PDB file
#d_desk Note: in this case first and last equate to lowest and highest numbering
#d_arg file Input PDB file
#d_arg chainVar Returned list of chain ids
#d_arg chain_rangeVar Returned nested list  of first and last residues in chains
  upvar $nTermini nTerm
  upvar $cTermini cTerm
  upvar #0 $arrayname def_array
  set chain {}
  set current_chain ""
  set current_id ""
  set residues {}
  set current_residue ""
  set nTerm {}
  set cTerm {}
  set chainMatchSegID 1

  set chain_used [GetValue $arrayname INCLUDE_CHAINS] 
  set use_all_chains [GetValue $arrayname INCLUDE_ALL]
  set chain_list [list]
  if { $use_all_chains==0 } {
      loopy_get_include_chains $arrayname chain_list
  }

  if { ![ReadFile $file text -split] } { 
    WarningMessage "ERROR reading file $file"
    return 0 
  }
  foreach line $text { 
      if { [regexp {^ATOM|^HETATM} $line] } {
	  set current_chain [string range $line 21 21]
	  set test_id [GetNoSpaceSegID $current_chain ""]
	  set current_segid [string range $line 72 75]
	  set current_segid [GetNoSpaceSegID $current_chain $current_segid]
	  if { ![StringSame $current_chain " "] && ![StringSame $test_id $current_segid] } {
	      set chainMatchSegID 0
	  }
	  
	  #always use the chain id (except when its absent) for version 7.1. Output an error when the seg id's would differ from the chain ids according to loopy
	  set old_id $current_id
	  set current_id $current_chain
	  if { $current_chain eq " " } {
	      set current_id [string range $current_segid 3 3]
	  }
	  if { [lsearch -exact $chain $current_id] == -1 } {
	      # new chain
	      
	      set test_res [string trim [string range $line 22 25]]
	      
	      set restype [string trim [string range $line 17 19]]
	      if { ![regexp HOH|WAT|H2O|SOL|DUM|DU0|DU1 $restype] } { 
		  if { $use_all_chains==1 || [ lsearch -exact $chain_list $current_chain ]!=-1 } { 
		      if { [llength $residues] > 0} {
			  lappend cTerm [list $old_id $current_residue]
		      }
		      set residues [list $test_res]
		      set current_residue $test_res
		      lappend nTerm [list $current_id $current_residue]
		      lappend chain $current_id
		  } else {
		      set residues {}
		  }
	      }
	  } else {
	      #old chain
	      set test_res [string trim [string range $line 22 25]]
	      set restype [string trim [string range $line 17 19]]
	      if { ![regexp HOH|WAT|H2O|SOL|DUM|DU0|DU1 $restype] } {
		  if { $use_all_chains==1 || [ lsearch -exact $chain_list $current_chain ]!=-1 } { 
		      if { [lsearch -exact $residues $test_res] < 0 } {
			  lappend residues $test_res
			  set diff [expr { $test_res - $current_residue} ]
			  if { $diff != 1 } {
			      lappend cTerm [list $current_id $current_residue]
			      lappend nTerm [list $current_id $test_res]
			  }
			  set current_residue $test_res
		      }
		  }
	      }
	  } 
      }
  }
  
  if { $chainMatchSegID == 0 } {
      WarningMessage "Please ensure that the pdb only contains either chain ID's or seg ID's.\n In most other cases, loopy will probably fail to run."
      return 0
  }
  #  puts "chain $chain chain_range $chain_range"
  return 1
}

#----------------------------------------------------------------------------
proc PdbGetSegID { file chainVar chain_rangeVar args } {
#----------------------------------------------------------------------------
#d_sum Get a list of the chains and the first & last residue ids in a PDB file
#d_desk Note: in this case first and last equate to lowest and highest numbering
#d_arg file Input PDB file
#d_arg chainVar Returned list of chain ids
#d_arg chain_rangeVar Returned nested list  of first and last residues in chains
#d_opt0 -nowat
#d_opt1 Ignore atoms of type HOH|WAT|H2O|SOL
#d_opt0 -atomid
#d_opt1 Return the ids of the first and last atoms in a chain 
  upvar $chainVar chain
  upvar $chain_rangeVar chain_range
  set chain {}
  set chain_range {}
  set last_res ""
  set first_res ""
  set water 1
  set atomid 0

  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    nowat {
      set water 0
# return the atom id (ie the atomid) rather than the residue id
    } atomid {
      set atomid 1
    }
    incr n
  }

  if { ![ReadFile $file text -split] } { 
    puts "ERROR reading file $file"
    return 0 
  }

  set chainMatchSegID 1
  foreach line $text { if { [regexp {^ATOM|^HETATM} $line] } {
      set current_chain [string range $line 21 21]
      set test_id [GetNoSpaceSegID $current_chain ""]
      set current_segid [string range $line 72 75]
      set current_segid [GetNoSpaceSegID $current_chain $current_segid]
      if { ![StringSame $current_chain " "] && ![StringSame $test_id $current_segid] } {
	  set chainMatchSegID 0
      }
#      set current_chain [string range $line 21 21]
#      set current_segid [string range $line 72 75]
#      set current_segid [GetNoSpaceSegID $current_chain $current_segid]

#always use the chain id (except when its absent) for version 7.1. Output an error when the seg id's would differ from the chain ids according to loopy
      set current_id $current_chain
      if { $current_chain eq " " } {
	  set current_id [string range $current_segid 3 3]
      }
      if { [lsearch -exact $chain $current_id] < 0 } {
	lappend chain $current_id
	if { $last_res != "" } { 
	    lappend chain_range [list $first_res [string trim $last_res]] }
	if { $atomid } {
	    set first_res [string trim [string range $line 6 10]]
	} else {
	    set test_res [string trim [string range $line 22 25]]
	    set first_res $test_res
	    set last_res $test_res
	}
	lappend restype [string trim [string range $line 17 19]]
    } else {
	if { $atomid } {
	    set last_res [string range $line 6 10]
	} else {
	    set test_res [string trim [string range $line 22 25]]
	    if { $test_res < $first_res } { set first_res $test_res }
	    if { $test_res > $last_res } { set last_res $test_res }
	}
    } 
  }}
  lappend chain_range [list $first_res [string trim $last_res]]
  if { !$water } {
      for {set n [expr [llength $restype] -1] } { $n >= 0 } { incr n -1 } {
	  if { [regexp HOH|WAT|H2O|SOL [lindex $restype $n] ] } {
	      set chain_range [lreplace $chain_range $n $n]
	      set chain [lreplace $chain $n $n]
	  }
      }
  }
  if { $chainMatchSegID == 0 } {
      WarningMessage "Please ensure that the pdb only contains either chain ID's or seg ID's.\n In most other cases, loopy will probably fail to run."
      return 0
  }
  #  puts "chain $chain chain_range $chain_range"
  return 1
}
