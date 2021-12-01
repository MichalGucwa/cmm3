#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#     Extended by Nicholas Furnham for RAPPER 2007
#
# ======================================================================
# rapper.tcl --
#
# (Re)Build possible loop(s) into a map using a current model as a framework 
# 
#
# CCP4Interface 
#
# ======================================================================
#-----------------------------------------------------------------------
proc rapper_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array
  
  set build_type [GetValue $arrayname BUILD_TYPE ]
  set prog_type [GetValue $arrayname PROG_TYPE ] 

 # Check for RAPPER program. If it is not found, we switch off the option.
 # If it was the only option, script will fail with next check.
  if { [regexp MODEL $build_type ] && $prog_type == "RAPPER"} {
   if { [FindExecutable "rapper"] == "" } {
      WarningMessage "Input Error: RAPPER program not found in system path."
      set build_type 0
    }
  }

  if { $prog_type == "TK"} {
   if { [FindExecutable "rappertk"] == "" } {
      WarningMessage "Input Error: RAPPER program not found in system path."
      set build_type 0
    }
  }

  # Make sure there is actually something to do
  if { $build_type == 0 } {
    WarningMessage "No programs selected to run and
    analyse data!

    Please select RAPPER to be run."
    return 0
  }
  
  ##sanity checks
  # Check resolution set
  if {  $array(RESOLUTION) == "" && $array(MAP_TYPE) == "WITH" } {
     WarningMessage "Map resolution required"
     return 0
  }
  if { $array(RESOLUTION) == "" && $array(BUILD_TYPE) == "MODEL_BADFIT" } {
      WarningMessage "Map resolution required"
     return 0
  }

  # Check start id set if modelling part of structure
  if {  $array(RES_START) == "" && $array(CATRACE_TYPE) == "PART" && $array(BUILD_TYPE) == "MODEL_CATRACE"} {
     WarningMessage "Need to have a start residue ID"
     return 0
  }
  # Check stop id set if modelling part of structure
  if {  $array(RES_STOP) == "" && $array(CATRACE_TYPE) == "PART" && $array(BUILD_TYPE) == "MODEL_CATRACE"} {
     WarningMessage "Need to have a stop residue ID"
     return 0
  }
  # Check seq is filled in for loop modelling
  if {  $array(BUILD_TYPE) == "MODEL_LOOP" && $array(SEQ) == ""} {
     WarningMessage "Need to provide sequence"
     return 0
  }
  # Check have map if rebuilding bad fitting residues
  if {  $array(BUILD_TYPE) == "MODEL_BADFIT" && $array(MAP_TYPE) == "WITHOUT" } {
     WarningMessage "Input map file required"
     return 0
  }
  
  #check that loop length and seq are compatible
   

  # Set up input and output files
  set array(INPUT_FILES) ""
  if $array(USE_XYZIN) { append array(INPUT_FILES) "XYZIN " }
  if { $array(MAP_TYPE) == "WITH" } {
  if $array(USE_MAPIN) { append array(INPUT_FILES) "MAPIN " }
  }
  set array(OUTPUT_FILES) ""
  if { [regexp MODEL $build_type ] } { append array(OUTPUT_FILES) "XYZOUT" }

  # Set default title if not already set
  set title ""
  switch [GetValue $arrayname BUILD_TYPE] {
      MODEL_LOOP {
	  set title "Loop modelling"
      }
      MODEL_LOOP_BENCHMARK {
	  set title "Re-modelling loop from PDB"
      }
      MODEL_CATRACE {
	  set title "Tracing a structure using C-alpha atom positional restraints"
      }
      MODEL_BADFIT {
	  set title "Rebuild regions that fit poorly into current map"
      }
      
  }
  SetDefaultTitle $arrayname $title

  return 1
}


#---------------------------------------------------------------------
proc rapper_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
     upvar #0  $typedefVar typedef

     set typedef(_rapper_build_type) { menu {       
 	"model loop"
 	"re-model loop from PDB"
        "ca-trace"
        "Rebuild bad fitting residues"}
 	{ MODEL_LOOP MODEL_LOOP_BENCHMARK MODEL_CATRACE MODEL_BADFIT} }


     set typedef(_rapper_rotomer_lib) { menu {
	 "Richardsons" \
	 "SCL 1.0" \
	 "SCL 0.5" \
	 "SCL 0.2"}
	 {RICHARDSON SCL1 SCL2 SCL3} }

     set typedef(_rapper_catrace_type) { menu {
	 "ALL" 
	 "PART"}
	 {ALL PART} }

     set typedef(_rapper_map_type) { menu {
	 "Yes" 
	 "No"}
	 {WITH WITHOUT} }

     set typedef(_rapper_prog_type) { menu {
	 "RAPPER" 
	 "RAPPERtk"}
	 {RAPPER TK} }


     return 1
}


#-----------------------------------------------------------------------
proc rapper_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array
  global configure

# Source file containing utility calculations
  source [SearchPath TOP utils pdb_utils.tcl]  

  if { [CreateTaskWindow $arrayname  \
	"RAPPER" "rapper" \
	    [ list "Model Building Definitions" \
	      "Main chain Restraints" \
	      "Side chain Restraints" \
	      "Optional Parameters" \
	     ] \
	
      ] == 0 } return
  
 #=PROTOCOL==============================================================
 
  OpenFolder protocol 

  CreateTitleLine line TITLE
  
  ##added list
  CreateLine line \
      message "Build method " \
      label "Do" \
      widget BUILD_TYPE 

  OpenSubFrame frame 
   CreateLine line \
      label "Using a map" \
      widget MAP_TYPE \
      
  CloseSubFrame

#  OpenSubFrame frame 
#   CreateLine line \
#      label "Using " \
#      widget PROG_TYPE \
      
#  CloseSubFrame
 

#=FILES================================================================

  OpenFolder file
 
## RAPPER files ===============================================================
  OpenSubFrame frame -toggle_display PROG_TYPE hide [ list TK ]
  CreateInputFileLine line \
      "Enter input PDB file name" \
      "PDB in" \
      XYZIN DIR_XYZIN \
      -fileout XYZOUT DIR_XYZOUT "_rapper"
           
      OpenSubFrame frame -toggle_display MAP_TYPE hide [ list WITHOUT ] 
      CreateInputFileLine line \
	  "Enter input MAP file name - can be both ccp4 and CNS format" \
	  "MAP in" \
	  MAPIN DIR_MAPIN 
      CloseSubFrame
  
   CreateOutputFileLine line \
      "Enter PDB file name to write model to" \
      "PDB out" \
      XYZOUT DIR_XYZOUT 
   CloseSubFrame

## RAPPERtk files ===============================================================
  OpenSubFrame frame -toggle_display PROG_TYPE open [ list TK ]
  CreateInputFileLine line \
      "Enter input PDB file name" \
      "PDB in" \
      XYZIN DIR_XYZIN \
      -fileout XYZOUT DIR_XYZOUT "_rapper"
      
   OpenSubFrame frame -toggle_display MAP_TYPE hide [ list WITHOUT ] 
     CreateInputFileLine line \
      "Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
      HKLIN DIR_HKLIN \
      -setfileparam space_group_name SPACE_GROUP \
      -setfileparam cell CELL \
      -setfileparam resolution_max RESOLUTION_MAX
 
        CreateLine line \
    message "Space group (default as in MTZ file) (SYMMETRY)" \
    help "symmetry" \
    label "Space group" \
    widget SPACE_GROUP

  CreateLine line \
    message "Cell dimensions (default from MTZ file) (CELL)" \
    help "cell" \
    label "Cell a" \
    widget CELL_1 -width 8 \
    label "b" \
    widget CELL_2 -width 8 \
    label "c" \
    widget CELL_3 -width 8 \
    label "alpha" \
    widget CELL_4 -width 8 \
    label "beta" \
    widget CELL_5 -width 8 \
    label "gamma" \
    widget CELL_6 -width 8

  CreateLine line \
    message "High resolution limit for probability calculation (default from MTZ file)" \
    help "reso" \
    label "High resolution limit" \
    widget RESOLUTION_MAX

      CreateLabinLine line \
	"Observed amplitude (FP) " \
	HKLIN "FP    " FP  [list FP F_P] 
        
      CreateLabinLine line \
        "Calculated amplitude (FC) and calculated phase (PHIC)" \
        HKLIN FC FC [list FC] 
        
      CreateLabinLine line \
        "Experimental phase (PHIB) and associated figure of merit (FOM)" \
         HKLIN PHIB PHIB {} 
       

    CloseSubFrame
  
   CreateOutputFileLine line \
      "Enter PDB file name to write model to" \
      "PDB out" \
      XYZOUT DIR_XYZOUT 
   CloseSubFrame



#=ARGS================================================================  
#=MUST HAVES==========================================================

 OpenFolder 1 

  OpenSubFrame frame  -toggle_display  PROG_TYPE hide [list  TK ]

  ##for building a subsection of a structue =============================================================
  OpenSubFrame frame  -toggle_display  BUILD_TYPE hide [ list  MODEL_LOOP MODEL_LOOP_BENCHMARK MODEL_BADFIT ]
  CreateLine line \
      label "Select how much you want to build" \
      widget CATRACE_TYPE 
  CloseSubFrame
  
  OpenSubFrame frame  -toggle_display  BUILD_TYPE hide [ list  MODEL_BADFIT ] 
  CreateLine line \
    label "If the model contains unconnected fragments then each fragment must have a separate chain id "  \
	-italic

  CreateLine line \
    message "Chain ID for section to be rebuilt " \
    label "Chain ID" \
    widget CHAIN_ID \
    label "Residue start" \
    widget RES_START \
    label "Residue stop" \
    widget RES_STOP \
    toggle_display  BUILD_TYPE open [ list MODEL_LOOP MODEL_LOOP_BENCHMARK ] || BUILD_TYPE hide [ list  MODEL_BADFIT ] 
 
   CloseSubFrame 

  OpenSubFrame frame  -toggle_display  BUILD_TYPE open [ list  MODEL_CATRACE ] 
  

  CreateLine line \
    message "Chain ID for section to be rebuilt " \
    label "Chain ID" \
    widget CHAIN_ID \
    label "Residue start" \
    widget RES_START \
    label "Residue stop" \
    widget RES_STOP \
    toggle_display  CATRACE_TYPE open [ list PART ]
 
   CloseSubFrame 

## catracing entire structure & badfit =============================================================
 CreateLine line \
    message "cryst-d-high" \
    label "Map resolution" \
    widget RESOLUTION \
    toggle_display MAP_TYPE hide [ list WITHOUT ] ||  BUILD_TYPE hide [ list MODEL_BADFIT ] 

 CreateLine line \
    message "models" \
    label "Number of Models" \
    widget MODEL_NUM \
    toggle_display BUILD_TYPE hide [ list MODEL_BADFIT ]
 
## ab initio loop building only  =============================================================
 CreateLine line \
    message "seq" \
    label "Loop sequence (single letter code)" \
    widget SEQ \
    toggle_display BUILD_TYPE hide [list MODEL_LOOP_BENCHMARK MODEL_CATRACE MODEL_BADFIT ]

## rebuild badfit  =============================================================
 CreateLine line \
    message "edm-poor-region-threshold " \
    label "EDM poor region threshold " \
    widget EDM_POOR_TH \
    toggle_display BUILD_TYPE hide [list MODEL_LOOP_BENCHMARK MODEL_CATRACE MODEL_LOOP ]

 CreateLine line \
    message "edm-poor-region-buffer-size " \
    label "Buffer size " \
    widget EDM_BUFF_SIZE \
    toggle_display BUILD_TYPE hide [list MODEL_LOOP_BENCHMARK MODEL_CATRACE MODEL_LOOP ]

CloseSubFrame 

## RAPPERtk model defs
  OpenSubFrame frame  -toggle_display  PROG_TYPE open [list  TK ]

    ##for building a subsection of a structure =============================================================
  OpenSubFrame frame  -toggle_display  BUILD_TYPE hide [ list  MODEL_LOOP MODEL_LOOP_BENCHMARK MODEL_BADFIT ]
  CreateLine line \
      label "Select how much you want to build" \
      widget CATRACE_TYPE 
  CloseSubFrame
  
  OpenSubFrame frame  -toggle_display  BUILD_TYPE hide [ list  MODEL_BADFIT ] 
  CreateLine line \
    label "If the model contains unconnected fragments then each fragment must have a separate chain id "  \
	-italic

  CreateLine line \
    message "chain-id " \
    label "Chain ID" \
    widget CHAIN_ID \
    message "start " \
    label "Residue start" \
    widget RES_START \
    message "stop " \
    label "Residue stop" \
    widget RES_STOP \
    toggle_display  BUILD_TYPE open [ list  MODEL_LOOP ] || BUILD_TYPE hide [ list  MODEL_BADFIT ] 
 
   CloseSubFrame 

  OpenSubFrame frame  -toggle_display  BUILD_TYPE open [ list  MODEL_CATRACE ] 
  

  CreateLine line \
    message "Chain ID" \
    label "Chain-id" \
    widget CHAIN_ID \
    message "start" \
    label "Residue start" \
    widget RES_START \
    message "stop" \
    label "Residue stop" \
    widget RES_STOP \
    toggle_display  CATRACE_TYPE open [ list PART ]
 
   CloseSubFrame 
   
  OpenSubFrame frame  -toggle_display  BUILD_TYPE open [ list  MODEL_LOOP_BENCHMARK ]
  CreateLine line \
    label "NOTE RAPPERtk needs to be told the sequence thus use model loop!"  \
	-italic

  CloseSubFrame
  
  OpenSubFrame frame  -toggle_display  BUILD_TYPE open [ list  MODEL_BADFIT ]
  CreateLine line \
      label "Using RAPPERtk defaults"  \
	-italic

  CloseSubFrame

#=mainchain=================================================================
 OpenFolder 2 BUILD_TYPE hide { MODEL_LOOP || MODEL_LOOP_BENCHMARK } open

 CreateLine line \
    message "enforce-mainchain-restraints " \
    label "Mainchain Restraint" \
    widget MC_RES -toggleon \
    label "mainchain-restraint-threshold " \
    widget MC_RAD


#=sidechain=================================================================
 OpenFolder 3 
 
 CreateLine line \
    message "sidechain-mode " \
    label "Build Sidechains" \
    widget SC_BUILD 
  
  OpenSubFrame frame  -toggle_display  BUILD_TYPE hide [list  MODEL_LOOP MODEL_LOOP_BENCHMARK ]
  CreateLine line \
    message "enforce-sidechain-centroid-restraints " \
    label "Enforce virtual side chain positional restraint " \
    widget SC_RES \
    label "sidechain-centroid-restraint-threshold" \
    widget SC_RAD 
   CloseSubFrame

  CreateLine line \
      message "sidechain-library " \
      label "Rotomer Library" \
      widget ROTOMER_LIB 
  
 
#=others=============================================================
  OpenFolder 4 PROG_TYPE  hide { TK } open

OpenSubFrame frame -toggle_display MAP_TYPE hide [ list WITHOUT ]
CreateLine line \
    message "use-edm-filters  " \
    label "EDM Filters " \
    widget EDM_FILTERS \ 
    
CreateLine line \
    message "restraints-are-pass-optional - THIS IS DANGEROUS " \
    label "Restraints pass optional " \
    widget RES_OPT \

CreateLine line \
    message "enforce-mainchain-min-sigma-restraints " \
    label "Enforce mainchain ED min Sigma " \
    widget MC_SIGMA_OPT \
    message "edm-mainchain-min-sigma " \
    label "Mainchain min Sigma cutoff" \
    widget MC_SIGMA

CreateLine line \
    message "enforce-sidechain-min-sigma-restraints " \
    label "Enforce Sidechain ED min Sigma " \
    widget SC_SIGMA_OPT \
    message "edm-sidechain-min-sigma  " \
    label "Sidechain min Sigma cutoff" \
    widget SC_SIGMA 

CreateLine line \
    message "optional-edm-mainchain-restraints " \
    label "Mainchain ED restraint will be made optional " \
    widget EDM_OPT 

CloseSubFrame

OpenSubFrame frame -toggle_display BUILD_TYPE open [ list MODEL_LOOP MODEL_LOOP_BENCHMARK ]
CreateLine line \
    message "strict-anchors " \
    label "Use strict anchor geometry " \
    widget ANCHOR_OPT \ 

CreateLine line \
    message "enforce-strict-anchor-geometry " \
    label "Use really strict anchor geometry " \
    widget ANCHOR_OPT2 \ 

CreateLine line \
    message "use-contact-filters " \
    label "Use contact filters " \
    widget CONTACT_FILTERS \ 

CloseSubFrame


    


}

