# =======================================================================
# phaser_MR.tcl --
#
# Maximum Likelihood Molecular Replacement
#
# CCP4Interface
#
# =======================================================================

#------------------------------------------------------------------------------
proc phaser_MR_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable phaser]] } {
    return 0
  }
  return 1
}

#------------------------------------------------------------------------
  proc phaser_MR_setup { typedefVar arrayname } {
#------------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname array

  DefineMenu _mode_menu [list "automated search" \
                              "rotation search" \
                              "translation search" \
                              "packing" \
                              "refinement and phasing" ] \
                        [list "AUTO" \
                              "ROT" \
                              "TRA" \
                              "PAK" \
                              "RNP" ]
 
#for backwards compatibility
  DefineMenu _mode_rot \
    [list "fast rotation function" "brute rotation function" ] [list "MR_FRF" "MR_BRF"]

#for backwards compatibility
  DefineMenu _mode_tran \
    [list "fast translation function" "brute translation function" ] [list "MR_FTF" "MR_BTF" ]

  DefineMenu _spacegroup_option \
    [list "mtz space group" "mtz space group and enantiomorph" "all alternative space groups" "alternative spacegroups (listed)"] \
    [list "SG_MTZ" "SG_ENANT" "SG_ALL" "SG_ALT" ]

  set typedef(_laue_space_group) { varmenu LAUE_SPGP_LIST LAUE_SPGP_ALIAS 8 }

  DefineMenu _composition_option \
    [ list "average solvent content for protein crystal" "solvent content of protein crystal" "components in asymmetric unit" "fraction scattering by ensemble"] \
    [ list "AVERAGE" "SOLVENT" "COMPONENT" "FRAC"]

  DefineMenu _protnucleic \
    [list "protein" "nucleic acid" ] [list "PROTEIN" "NUCLEIC" ]

  DefineMenu _rmsid_option \
   [list "rms difference" "sequence identity" "from pdb REMARK" "high rms from id" "low rms from id"] [list "RMS" "IDENT" "CARD" "IDHI" "IDLO"]

  set typedef(_mwseqnres_option) \
    { menu  { "molecular weight"  "sequence file" "number of residues"} { "MW"  "FASTA" "NRES"} }

  DefineMenu _ensemble_option \
    [list "pdb file(s)" "map (mtz file)" ] [list "PDB"  "MAP"]
 
  DefineMenu _search_type \
    [list "on" "off" ] [list "SEARCH_OR" "SEARCH_SIMPLE"]

  DefineMenu _search_method \
    [list "full" "fast" ] [list "FULL" "FAST" ]

  DefineMenu _brf_search_option \
   [list "all angles" "around an angle" ] [list "FULL" "AROUND" ]

  DefineMenu _btf_search_option \
   [list "full" "around" "region" "line"] [list "FULL" "AROUND" "REGION" "LINE"]

  DefineMenu _packing_option \
    [list "best packing (up to percent)" "best packing (up to number)" "max number of clashes" "accept all solutions" ] \
    [list "PERCENT" "BEST" "ALLOWED" "ALL"]

  set typedef(_ensemble_menu)  \
    { varmenu ENSEMBLE_MENU_LIST ENSEMBLE_MENU_ALIAS 15 }
  set typedef(_frf_target_option) \
    { menu { "Fast" "Brute"} { "LERF1" "BRUTE"} }
  set typedef(_ftf_target_option) \
    { menu { "Fast" "Brute"} { "LETF1" "BRUTE"} }
  set typedef(_peaks_option) \
   { menu  { "percentage of top peak" "sigma (Z-score) cutoff" "number of peaks" "all peaks"} \
           { "PERCENT" "SIGMA" "NUMBER" "ALL" } }
  set typedef(_macro_protocol) \
    { menu  { "default" "custom" "fix all" "refine all"} { "DEFAULT" "CUSTOM" "OFF" "ALL"} }
  set typedef(_onoff) \
    { menu { "on" "off" } { ON OFF } }
  set typedef(_tribool) \
    { menu { "on" "off" "auto" } { ON OFF NOT_SET } }
  set typedef(_coord_option) \
    { menu { "orthogonal" "fractional" } { "ORTH" "FRAC" } }

  return 1
  }

#------------------------------------------------------------------------
proc phaser_MR_run { arrayname } {
#------------------------------------------------------------------------

  upvar #0 $arrayname array

# The output file array is set up in phaser_MR.script
  set array(OUTPUT_FILES) ""

# All output files with the user specified root will be saved to the project dir
#set array(FILENAME_ROOT) [FileJoin [GetDefaultDirPath] $array(ROOT) ]

  if { $array(HKLIN_MAIN) == "" } {
     WarningMessage "NOT SET: mtz reflection data file"
     return 0
  }

  if { ([GetValue $arrayname SCATTERING] == "COMPONENT") } {
  for { set n 1 } { $n <= $array(N_COMPONENT) } { incr n } {
    if { $array(COMP_OPTION,$n) == "sequence file" &&  $array(COMP_FILE,$n) == "" } {
       WarningMessage "NOT SET: sequence file for component # $n"
       return 0
     }
    if { $array(COMP_OPTION,$n) == "molecular weight" &&  $array(MW,$n) == "" } {
       WarningMessage "NOT SET: molecular weight for component # $n"
       return 0
     }
   } }

  if { ([GetValue $arrayname SCATTERING] == "NRES")} { 
    if { ([GetValue $arrayname COMP_NRES] == "")} { 
     WarningMessage "NOT SET: number of residues in the composition"
     return 0
    } }

  if { ([GetValue $arrayname SCATTERING] == "SOLVENT")} { 
    if { ([GetValue $arrayname SCATTERING_SOLVENT] == "")} { 
     WarningMessage "NOT SET: solvent content in the composition"
     return 0
  } }

   for { set n 1 } { $n <= $array(N_ENSEMBLE) } { incr n } {
    if { [ regexp PDB [GetValue $arrayname ENSEMBLE_OPTION,$n ] ] } {
    for { set p 1 } { $p <= $array(N_PDB,$n) } { incr p } {
      if { $array(XYZIN,[subst $n]_$p) == "" } {
         WarningMessage "NOT SET: pdb file for ensemble # $n"
         return 0
      }
      if { $array(RMS_OPTION,[subst $n]_$p) != "from pdb REMARK" } {
      if { $array(RMS,[subst $n]_$p) == "" } {
         WarningMessage "NOT SET: RMS error for PDB # $p of ensemble # $n"
         return 0
      }
      }
    }
    }
    if { [ regexp MAP [GetValue $arrayname ENSEMBLE_OPTION,$n ] ] } {
      if { $array(HKLIN,$n) == "" } {
         WarningMessage "NOT SET: mtz map file for ensemble # $n"
         return 0
      }
      if { $array(ENSEMBLE_PROTMW,$n) == "" } {
         WarningMessage "NOT SET: protein molecular weight for ensemble # $n"
         return 0
      }
      if { $array(ENSEMBLE_NUCLMW,$n) == "" } {
         WarningMessage "NOT SET: nucleic acid molecular weight for ensemble # $n"
         return 0
      }
      if { ($array(ENSEMBLE_EXT_X,$n) == "") 
        || ($array(ENSEMBLE_EXT_Y,$n) == "")
        || ($array(ENSEMBLE_EXT_Z,$n) == "") } {
         WarningMessage "NOT SET: extent of the model for ensemble # $n"
         return 0
      } 
      if { $array(ENSEMBLE_RMS_MTZ,$n) == "" } {
         WarningMessage "NOT SET: RMS error of the model for ensemble # $n"
         return 0
      } 
      if { ($array(ENSEMBLE_CEN_X,$n) == "")
        || ($array(ENSEMBLE_CEN_Y,$n) == "")
        || ($array(ENSEMBLE_CEN_Z,$n) == "") } {
         WarningMessage "NOT SET: centre of the model for ensemble # $n"
         return 0 
       }
    }
   }

# Check for compulsory brute force rotation function AROUND search parameters
  if { ([GetValue $arrayname MR_MODE] == "ROT") 
    && ([GetValue $arrayname FRF_TARGET_OPTION] == "BRUTE")
    && ([GetValue $arrayname BRF_SEARCH_OPTION] == "AROUND") } { 
    if { ($array(AROUND_ALPHA) == "") || ($array(AROUND_BETA) == "")
      || ($array(AROUND_GAMMA) == "") || 
         ($array(AROUND_EULER_RANGE) == "") } {
         WarningMessage "NOT SET: rotation function search (euler angles and range)"
         return 0
    }
   }

if { (([GetValue $arrayname MR_ROT_SEARCH] == "SEARCH_SIMPLE") 
     && ( [GetValue $arrayname MR_MODE] == "ROT") 
     && ( !($array(N_SIMPLE_SEARCH) == 0 && ($array(N_ENSEMBLE) == 0))) ) } {
if { ($array(MR_ROT_SEARCH_ID) == "") } {
    WarningMessage "NOT SET: search ensemble" 
    return 0
    }
if { ([lsearch -exact $array(ENSEMBLE_MENU_LIST) $array(MR_ROT_SEARCH_ID)] < 0) } {
    WarningMessage "The search ensemble is not in the defined list of ensembles"
    return 0
    }
} 

if { (([GetValue $arrayname MR_SEARCH] == "SEARCH_SIMPLE") 
     && ( [GetValue $arrayname MR_MODE] == "AUTO") ) } {
if { $array(N_SIMPLE_SEARCH) < 1 } {
if { $array(N_ENSEMBLE) > 0 } {
    WarningMessage "NOT SET: search ensemble"
    return 0
} } }

if { (([GetValue $arrayname MR_SEARCH] == "SEARCH_SIMPLE") 
     && ( [GetValue $arrayname MR_MODE] == "AUTO") ) } {
if { $array(N_SIMPLE_SEARCH) < 1 } {
if { $array(N_ENSEMBLE) < 1 } {
if { [GetValue $arrayname SET_SOL_FILE_NOTOB] == "" } {
    WarningMessage "NOT SET: ensembles and searches must be defined in SOL file"
    return 0
} } } }


if { (([GetValue $arrayname MR_SEARCH] == "SEARCH_SIMPLE") 
     && ( [GetValue $arrayname MR_MODE] == "AUTO")
     && ( !($array(N_SIMPLE_SEARCH) == 0 && ($array(N_ENSEMBLE) == 0))) ) } {
for { set q 1 } { $q <= $array(N_SIMPLE_SEARCH) } { incr q } {
if { ($array(MR_SIMPLE_ENSEMBLE_ID,$q) == "") } {
    WarningMessage "NOT SET: search ensemble" 
    return 0
    }
if { ([lsearch -exact $array(ENSEMBLE_MENU_LIST) $array(MR_SIMPLE_ENSEMBLE_ID,$q)] < 0) } {
    WarningMessage "Search ensemble is not in the ensemble list"
    return 0
    }
    } } 

if { (([GetValue $arrayname MR_SEARCH] == "SEARCH_OR") 
     && ( [GetValue $arrayname MR_MODE] == "AUTO") ) } {
if { $array(N_SEARCH) < 1 } {
    WarningMessage "NOT SET: search ensemble"
    return 0
} }

if { (([GetValue $arrayname MR_SEARCH] == "SEARCH_OR") 
     && ( [GetValue $arrayname MR_MODE] == "AUTO") ) } {
for { set q 1 } { $q <= $array(N_SEARCH) } { incr q } {
if { ($array(MR_FIRST_OR_ENSEMBLE_ID,$q) == "") } {
    WarningMessage "NOT SET: search ensemble" 
    return 0
    }
if { ([lsearch -exact $array(ENSEMBLE_MENU_LIST) $array(MR_FIRST_OR_ENSEMBLE_ID,$q)] < 0) } {
    WarningMessage "Search ensemble is not in the ensemble list"
    return 0
    }
} } 

if { (([GetValue $arrayname MR_ROT_SEARCH] == "SEARCH_OR")
     && ( [GetValue $arrayname MR_MODE] == "ROT") ) } {
    for { set p 1 } { $p <= $array(N_ROT_SEARCH_EXTRA) } { incr p } {
if { $array(MR_ROT_SEARCH_ID_EXTRA,$p) == "" } {
    WarningMessage "NOT SET: search ensemble" 
    return 0
    }
if { ([lsearch -exact $array(ENSEMBLE_MENU_LIST) $array(MR_ROT_SEARCH_ID_EXTRA,$p)] < 0) }  {
    WarningMessage "Search ensemble is not in the ensemble list"
    return 0
    }
} }

if { (([GetValue $arrayname MR_SEARCH] == "SEARCH_OR")
     && ( [GetValue $arrayname MR_MODE] == "AUTO") ) } {
   for { set n 1 } { $n <= $array(N_SEARCH) } { incr n } {
    for { set p 1 } { $p <= $array(N_SEARCH_EXTRA,$n) } { incr p } {
if { $array(MR_EXTRA_OR_ENSEMBLE_ID,[subst $n]_$p) == "" } {
    WarningMessage "NOT SET: search ensemble" 
    return 0
    }
if { ([lsearch -exact $array(ENSEMBLE_MENU_LIST) $array(MR_EXTRA_OR_ENSEMBLE_ID,[subst $n]_$p)] < 0) }  {
    WarningMessage "Search ensemble is not in the ensemble list"
    return 0
    }
} } }


# Check for compulsory brute force translation function AROUND search parameters
  if { ([GetValue $arrayname MR_MODE] == "TRA") 
    && ([GetValue $arrayname FTF_TARGET_OPTION] == "BRUTE")
    && ([GetValue $arrayname BTF_SEARCH_OPTION] == "AROUND") } { 
    if { ($array(START_X) == "") || ($array(START_Y) == "")
      || ($array(START_Z) == "") 
      || ($array(AROUND_COORD_RANGE) == "") } {
         WarningMessage "NOT SET: translation function search (coordinates and range)" 
         return 0
    }
   }

# Check for compulsory brute force translation function REGION search parameters
  if { ([GetValue $arrayname MR_MODE] == "TRA") 
    && ([GetValue $arrayname FTF_TARGET_OPTION] == "BRUTE")
    && ([GetValue $arrayname BTF_SEARCH_OPTION] == "REGION") } { 
    if { ($array(START_X) == "") || ($array(START_Y) == "")
      || ($array(START_Z) == "") || ($array(END_X) == "")
      || ($array(END_Y) == "") || ($array(END_Z) == "") } {
         WarningMessage "NOT SET: translation function search (coordinates and range)" 
         return 0
    }
   }

# Check for compulsory brute force translation function LINE search parameters
  if { ([GetValue $arrayname MR_MODE] == "TRA") 
    && ([GetValue $arrayname FTF_TARGET_OPTION] == "BRUTE")
    && ([GetValue $arrayname BTF_SEARCH_OPTION] == "LINE") } { 
    if { ($array(START_X) == "") || ($array(START_Y) == "")
      || ($array(START_Z) == "") || ($array(END_X) == "")
      || ($array(END_Y) == "") || ($array(END_Z) == "") } {
         WarningMessage "NOT SET: translation function search (coordinates and range)" 
         return 0
    }
   }

  if { ( [GetValue $arrayname MR_MODE] == "TRA" ) && \
           ( $array(TRA_RLIST_FILE) == "" ) } {
         WarningMessage "NOT SET: translation function search (rlist file)" 
      return 0
  }

# Set up the array of input files: 1 or more mtz and maybe some pdb files
  set array(INPUT_FILES) "HKLIN_MAIN"

  for { set i 1 } { $i <= $array(N_ENSEMBLE) } { incr i } {
   if { [ regexp MAP [GetValue $arrayname ENSEMBLE_OPTION,$i ] ] } {
    append array(INPUT_FILES) " HKLIN,$i"
   }
   if { [ regexp PDB [GetValue $arrayname ENSEMBLE_OPTION,$i ] ] } {
   for { set j 1 } { $j <= $array(N_PDB,$i) } { incr j } {
    append array(INPUT_FILES) " XYZIN,[subst $i]_$j"
    }
  }
  }

  if { ([GetValue $arrayname SCATTERING] == "COMPONENT") } {
  for { set n 1 } { $n <= $array(N_COMPONENT) } { incr n } {
    if { $array(COMP_OPTION,$n) == "sequence file" } {
        append array(INPUT_FILES) " COMP_FILE,$n"
     }
   }
   }

  if { [GetValue $arrayname MR_MODE] == "TRA" } { 
        append array(INPUT_FILES) " TRA_RLIST_FILE"
  }
  if { ([GetValue $arrayname MR_MODE] == "RNP")
    || ([GetValue $arrayname MR_MODE] == "PAK") } { 
        append array(INPUT_FILES) " SET_SOL_FILE"
  }
  if { ([GetValue $arrayname MR_MODE] != "RNP")
    && ([GetValue $arrayname MR_MODE] != "PAK") 
    && ([GetValue $arrayname SET_SOL_FILE_NOTOB] != "") } { 
        append array(INPUT_FILES) " SET_SOL_FILE_NOTOB"
  }

# If a test space group other than mtz file one has been selected, then extract its space group number.
  if { ![StringSame $array(FILE_SPACEGROUP) \
              [GetValue $arrayname TEST_SPACEGROUP] ] } {
    set array(SPACGROUP_NUMBER) [GetSpaceGroupNumber $array(TEST_SPACEGROUP)]
} else {
    set array(SPACGROUP_NUMBER) ""
  }

  return 1
  }

#------------------------------------------------------------------------
 proc phaser_MR_sg { arrayname counter_sg } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array
  CreateLine line \
      label "Test space group #$counter_sg" \
      message "Select a test SG (same point group)\
               or ALL to test all.\
               NB mtz SG will NOT now be tested by default."\
      widget PHASER_TEST_SG 
}

#------------------------------------------------------------------------
 proc phaser_MR_fractional { arrayname counter_component } {
#------------------------------------------------------------------------
# The contents of the "Composition" folder, extending frame 
  upvar #0 $arrayname array

  CreateLine line \
     message "" \
      label "Ensemble " \
      widget COMP_ENSE_ID \
      label "  Fraction scattering " \
      widget COMP_ENSE_FRAC -oblig
 }

#------------------------------------------------------------------------
 proc phaser_MR_component { arrayname counter_component } {
#------------------------------------------------------------------------
# The contents of the "Composition" folder, extending frame 
  upvar #0 $arrayname array

  CreateLine line \
      message "Select for protein or DNA/RNA as a component of the asymmetric unit" \
      label "Component #$counter_component" \
      widget PROTDNA \
      message "Enter the molecular weight of protein/nucleic acid #$counter_component" \
      label "" \
      widget COMP_OPTION -oblig \
      widget MW -oblig \
      message "Enter the number of copies of component #$counter_component in the asu " \
      label "Number in asymmetric unit" \
      widget ASYM -oblig \
     toggle_display COMP_OPTION,$counter_component open MW hide

  CreateLine line \
      message "Select for protein or DNA/RNA as a component of the asymmetric unit" \
      label "Component $counter_component" \
      widget PROTDNA \
      message "Enter the file containing sequence in single letter code or fasta format" \
      label "" \
      widget COMP_OPTION -oblig \
      message "Enter the number of copies of component $counter_component in the asu" \
      label "Number in asymmetric unit" \
      widget ASYM -oblig \
     toggle_display COMP_OPTION,$counter_component open FASTA hide

  CreateInputFileLine line \
      "Select the sequence file" "SEQ file" COMP_FILE DIR_COMP_FILE \
     -toggle_display COMP_OPTION,$counter_component open FASTA hide

  CreateLine line \
      message "Select for protein or DNA/RNA as a component of the asymmetric unit" \
      label "Component $counter_component" \
      widget PROTDNA \
      message "Enter the number of residues of protein/nucleic acid $counter_component" \
      label "" \
      widget COMP_OPTION -oblig \
      widget COMP_NRES -oblig \
      message "Enter the number of copies of component $counter_component in the asymmetric unit" \
      label "Number in asymmetric unit" \
      widget ASYM -oblig \
     toggle_display COMP_OPTION,$counter_component open NRES hide

  }

#------------------------------------------------------------------------
 proc phaser_MR_ensemble { arrayname counter_ensemble } {
#------------------------------------------------------------------------
# Sets up the main ensembles definition folder, extending frame

  upvar #0 $arrayname array

# Set a default name for ENSEMBLE_ID of ensemble1, ensemble2, ensemble3 etc
  if { $array(ENSEMBLE_ID,$counter_ensemble) == "" } {
       set array(ENSEMBLE_ID,$counter_ensemble) "ensemble$counter_ensemble" }

  CreateLine line \
      message "Enter unique identifier for ensemble #$counter_ensemble" \
      label "Ensemble Name" widget ENSEMBLE_ID \
        -command "update_phaser_MR_ensemble $arrayname" \
        -oblig \
      message "Define the ensemble by PDB file(s) or MAP file" \
      label "Define ensemble via" widget ENSEMBLE_OPTION \
      toggle_display ENSEMBLE_OPTION,$counter_ensemble open MAP

  CreateLine line \
      message "Enter unique identifier for ensemble #$counter_ensemble" \
      label "Ensemble Name" widget ENSEMBLE_ID \
        -command "update_phaser_MR_ensemble $arrayname" \
        -oblig \
      message "Define the ensemble by PDB file(s) or MAP file" \
      label "Define ensemble via" widget ENSEMBLE_OPTION \
      toggle_display ENSEMBLE_OPTION,$counter_ensemble open PDB

  OpenSubFrame frame -toggle_display ENSEMBLE_OPTION,$counter_ensemble open MAP

  CreateInputFileLine line \
      "Enter MTZ map file name (HKLIN) for ensemble # $counter_ensemble" \
      "MTZ     " \
      HKLIN DIR_HKLIN

  CreateLabinLine line \
      "Select calculated amplitude (FC) and calculated phase (PHIC)" \
      HKLIN,$counter_ensemble "FC" FC [list FC] \
      -help labin \
      -sigma "PHIC" PHIC [list PHIC]

  CreateLine line \
      message "Enter molecular weight of protein in the object\
            represented by the map (from MTZ file)" \
      label "Protein MW" widget ENSEMBLE_PROTMW -oblig \
      message "Enter molecular weight of nucleic acid in the object\
               represented by the map (from MTZ file)" \
      label "Nucleic acid MW" widget ENSEMBLE_NUCLMW -oblig \
      message "Enter the extent of the model in the X, Y and Z directions" \
      label "Extent: X" widget ENSEMBLE_EXT_X -oblig \
      label "Y" widget ENSEMBLE_EXT_Y -oblig \
      label "Z" widget ENSEMBLE_EXT_Z -oblig label "Angstroms"

  CreateLine line \
      message "Similarity to the target" \
      label "RMS error" widget ENSEMBLE_RMS_MTZ -oblig \
      message "Enter coordinates of the centre of the model, in Angstroms" \
      label "Centre: X" widget ENSEMBLE_CEN_X -oblig \
      label "Y" widget ENSEMBLE_CEN_Y -oblig \
      label "Z" widget ENSEMBLE_CEN_Z -oblig label "Angstroms" 

  CloseSubFrame

# Within the Add Ensemble toggle frame, if PDB is selected for ENSEMBLE_OPTION,
#   then insert an extending frame for adding pdb files for each ensemble

  OpenSubFrame frame -toggle_display ENSEMBLE_OPTION,$counter_ensemble open PDB 

  CreateExtendingFrame N_PDB phaser_MR_pdb \
      "Add another PDB file to the ensemble" \
      "Add superimposed PDB file to the ensemble" \
      [list XYZIN DIR_XYZIN RMS_OPTION RMS ] \
       -counter $counter_ensemble

  CloseSubFrame

# Check and update the ensemble variable menu
  edit_phaser_MR_ensemble $arrayname $counter_ensemble

  }

#------------------------------------------------------------------------
 proc phaser_MR_rot_extra { arrayname counter } {
#------------------------------------------------------------------------
# An extending frame for adding extra ensembles to a FRF search
  upvar #0 $arrayname array
  CreateLine line \
      message "Select an alternative ensemble to use in this search" \
      label "               or ensemble" \
      widget MR_ROT_SEARCH_ID_EXTRA
  }


#------------------------------------------------------------------------
 proc phaser_MR_simple_search { arrayname counter_simple_search } {
#------------------------------------------------------------------------
# The auto search extending frame code for adding extra search ensembles
  upvar #0 $arrayname array

  CreateLine line \
      message "Choose an ensemble to be used for this\
               molecular replacement search" \
      label "Perform search using " \
      widget MR_SIMPLE_ENSEMBLE_ID \
      message "The number of copies of the ensemble to look for" \
      label "  Number of copies to search for" \
      widget MR_SIMPLE_ENSEMBLE_NUM
  }


#------------------------------------------------------------------------
 proc phaser_MR_or_search { arrayname counter_search } {
#------------------------------------------------------------------------
# The auto search toggle frame code for adding extra search ensembles
  upvar #0 $arrayname array

  CreateLine line \
      label "Perform search using " \
      widget MR_FIRST_OR_ENSEMBLE_ID \
      message "The number of copies of the ensemble to look for" \
      label "  Number of copies to search for" \
      widget MR_FIRST_OR_ENSEMBLE_NUM

  CreateExtendingFrame N_SEARCH_EXTRA phaser_MR_or_search_extra \
      "Add an alternative ensemble to use in the search" \
      "Add alternative ensemble to test" \
      [list MR_EXTRA_OR_ENSEMBLE_ID N_SEARCH_EXTRA] \
      -counter $counter_search 

  }

#------------------------------------------------------------------------
 proc phaser_MR_or_search_extra { arrayname counter_search_extra counter_search } {
#------------------------------------------------------------------------
# The auto search extending frame code for adding extra ensembles to a search 
  upvar #0 $arrayname array
  CreateLine line \
      label "               or ensemble" \
      widget MR_EXTRA_OR_ENSEMBLE_ID
  }

#------------------------------------------------------------------------
 proc phaser_MR_pdb { arrayname counter_pdb counter_ensemble } {
#------------------------------------------------------------------------
# The ensemble pdb extending frame lines
  upvar #0 $arrayname array

  CreateInputFileLine line \
      "Select a PDB file associated with ensemble #$counter_ensemble " \
      "PDB #$counter_pdb" \
      XYZIN DIR_XYZIN

  CreateLine line \
      message "Specify RMS error in Angstrom, or \
               via the sequence identity (percentage or a fraction)" \
      label "Similarity of PDB #$counter_pdb to the target structure" \
      widget RMS_OPTION widget RMS -oblig \
      toggle_display RMS_OPTION,[subst $counter_ensemble]_$counter_pdb open [list "sequence identity" "rms difference" "low rms from id" "high rms from id"] hide

  CreateLine line \
      message "Specify RMS error in Angstrom, or \
               via the sequence identity (percentage or a fraction)" \
      label "Similarity of PDB #$counter_pdb to the target structure" \
      widget RMS_OPTION \
      toggle_display RMS_OPTION,[subst $counter_ensemble]_$counter_pdb open [list "from pdb REMARK" ] hide

# puts $array(RMS_OPTION,[subst $counter_ensemble]_$counter_pdb)
# puts RMS_OPTION,[subst $counter_ensemble]_$counter_pdb

  }

#------------------------------------------------------------------------
 proc update_phaser_MR_ensemble { arrayname } {
#------------------------------------------------------------------------
# This is called whenever the user clicks into the widget for an
#   ensemble name 
  upvar #0 $arrayname array
# It looks like an empty (redundant) procedure but is needed to ensure
#   that $array(N_ENSEMBLE) gets handed correctly to the menu procedure
  update_phaser_MR_ensemble_menu $arrayname $array(N_ENSEMBLE)
  }

#------------------------------------------------------------------------
 proc update_phaser_MR_ensemble_menu { arrayname n_ensemble } {
#------------------------------------------------------------------------
# Updates the variable menu of ensembles
  upvar #0 $arrayname array
# Build up list for menu
  set menu {}
  for { set n 1 } { $n <= $n_ensemble } { incr n } { lappend menu $array(ENSEMBLE_ID,$n) }
# Do the update
  UpdateVariableMenu $arrayname initialise 0 ENSEMBLE_MENU_LIST $menu 
  }

#------------------------------------------------------------------------
 proc edit_phaser_MR_ensemble { arrayname counter_ensemble } {
#------------------------------------------------------------------------
# When an ensemble is removed or added, need to update the variable menu
#   for ensemble selection.
# counter_ensemble is passed from the calling procedure. It is the 
#   number of ensembles (= number of frames)
  upvar #0 $arrayname array
  set usermenu {}
  set alias {}
# Create the ensemble menu list and its alias
  for { set n 1 } { $n <= $counter_ensemble } { incr n } { lappend usermenu "$n:  $array(ENSEMBLE_ID,$n)" }
  for { set n 1 } { $n <= $counter_ensemble } { incr n } { lappend alias "$array(ENSEMBLE_ID,$n)" }

# Update ENSEMBLE_ID if an ensemble is deleted and its ENSEMBLE_ID
#   is still set to the default ensemble$counter_ensemble
#   (which will now be out by one (one too high))
# regexp as below on "ensemble1" produces j1_whole=ensemble1
#                                         j2_root=ensemble
#                                         j3_num=1

  if { $counter_ensemble > 0 } {
     for { set p 1 } { $p <= $array(N_ENSEMBLE) } { incr p } {
         if { [regexp "^(ensemble)(\[0-9\])$" $array(ENSEMBLE_ID,$p) \
                        j1_whole j2_root j3_num] } {
            # If the trailing number (j3_num) is different from 
            #   the current molecule number (p) then reset the id
            if { $j3_num != $p } { set array(ENSEMBLE_ID,$p) "ensemble$p" }
         }
     }
  }

# Update the variable menu with the list of ensemble names
  update_phaser_MR_ensemble_menu $arrayname $counter_ensemble

  }

#------------------------------------------------------------------------
 proc update_ensemble_menu { arrayname n_ensemble } {
#------------------------------------------------------------------------
# Updates the variable menu of ensembles
  upvar #0 $arrayname array
# Build list for menu
  set menu {}
  for { set n 1} {$n <= $n_ensemble } { incr n } { lappend menu $array(ENSEMBLE_ID,$n) }
  UpdateVariableMenu $arrayname initialise 0 ENSEMBLE_MENU_LIST $menu
  }


#------------------------------------------------------------------------
 proc phaser_MR_set_test_space_group { arrayname } {
#------------------------------------------------------------------------
# To set up the choice of test space groups possible (those in the same
#   point group) given the space group from the mtz file
  upvar #0 $arrayname array
  set spgp_list {}
  set spgp_alias {}
  set laue_no [GetLaueGroupNumber $array(FILE_SPACEGROUP)]
# laue_no is zero if FILE_SPACEGROUP is not in the standard list
# update the list of spacegroups varlabel
  phaser_MR_updatevarlabel $arrayname FILE_SPACEGROUP
  if { $laue_no <= 0 } {
    lappend spgp_list $array(FILE_SPACEGROUP)
    lappend spgp_alias [GetSpaceGroupNumber $array(FILE_SPACEGROUP)]
  } else {
    set spgp_alias [GetLaueGroup $laue_no]
    foreach gp_no $spgp_alias {
      lappend spgp_list [GetSpaceGroupCode $gp_no]
    }
  }
# GetLaueGroup returns a list of space groups for the given Laue Group

  UpdateVariableMenu $arrayname initialise [llength $array(LAUE_SPGP_LIST)] \
        LAUE_SPGP_LIST $spgp_list \
        MODEL_ALIAS_LIST $spgp_alias

  set array(PHASER_TEST_SG) [GetSpaceGroupCode $array(FILE_SPACEGROUP)]

}

#------------------------------------------------------------------------
 proc phaser_MR_updatevarlabel { arrayname FILE_SPACEGROUP } {
#------------------------------------------------------------------------
# procedure to update the FILE_SPACEGROUP varlabel
  upvar #0 $arrayname array
  set field_list [GetWidget $arrayname FILE_SPACEGROUP]
  foreach field $field_list {
    if { [winfo exists $field] } { $field configure -text $array(FILE_SPACEGROUP) } }
  }

#------------------------------------------------------------------------
  proc phaser_MR_tncs_use_and_valid {arrayname} {
#------------------------------------------------------------------------
  upvar #0 $arrayname array
  set array(TNCS_USE_AND_VALID) "1"
  if { [StringSame $array(MR_MODE) PAK] } { 
    set array(TNCS_USE_AND_VALID) "0"
  } elseif { [StringSame $array(TNCS_USE) OFF] } {
    set array(TNCS_USE_AND_VALID) "0"
  }

  }


#------------------------------------------------------------------------
  proc phaser_MR_set_reso {arrayname} {
#------------------------------------------------------------------------
  upvar #0 $arrayname array
  if { ( $array(RESOLUTION_DMIN) >= 2.5 ) } {
     set array(RESOLUTION_DMIN_MR) [GetValue $arrayname RESOLUTION_DMIN]
     } else {
     set array(RESOLUTION_DMIN_MR) 2.5
     }
}

#------------------------------------------------------------------------
  proc phaser_MR_maca { arrayname counter_s } {
#------------------------------------------------------------------------
  global configure
  upvar #0 $arrayname array
  CreateLine line \
      label "   Anisotropic" \
      widget MACA_ANIS \
      label "Bins" \
      widget MACA_BINS \
      label "SolK" \
      widget MACA_SOLK \
      label "SolB" \
      widget MACA_SOLB \
      label "Number of Cycles" \
      widget MACA_NCYC -width 5 
  }

#------------------------------------------------------------------------
  proc phaser_MR_macm { arrayname counter_s } {
#------------------------------------------------------------------------
  global configure
  upvar #0 $arrayname array
  CreateLine line \
      label "   Rotation" widget MACM_ROT \
      label "Tranlation" widget MACM_TRA \
      label "Bfactor" widget MACM_BFAC \
      label "Vrms" widget MACM_VRMS \
      label "EM cell" widget MACM_CELL \
      label "Last" widget MACM_LAST \
      label "NCYC" widget MACM_NCYC -width 5
  }

#------------------------------------------------------------------------
  proc phaser_MR_task_window {arrayname} {
#------------------------------------------------------------------------

  upvar #0 $arrayname array
  global configure

  if { [CreateTaskWindow $arrayname \
        "Maximum Likelihood Molecular Replacement"\
        "Phaser" \
        [ list "Define data" \
               "Define ensembles (models)" \
               "Define composition of the asymmetric unit" \
               "Search parameters " \
               "Additional Search parameters" \
               "Expert parameters" \
               "Output control" \
               "Developer parameters" ] \
       ] == 0 } return

# SetProgramHelpFile phaser


#=PROTOCOL===============================================================

  OpenFolder protocol

  CreateTitleLine line TITLE

# Sets up the central menus for choosing the mode of phaser
#   whether rotation, translation or refinement/rescoring searches

  CreateLine line \
      label "Mode for molecular replacement" \
      message "The central menu: select the molecular replacement\
               mode for phaser to run" \
      widget MR_MODE

  CreateLine line \
      message "Number of processors (parallelization)" \
      widget TOG_NJOBS -toggleon \
      label "Number of processors "\
      widget NJOBS \
      label "(only relevant if phaser compiled with openmp option)"

#=FILE===================================================================

# The "Define data" folder

  OpenFolder 1 MR_MODE 

  CreateInputFileLine line \
      "Enter MTZ file name (HKLIN)" \
      "MTZ in     " \
      HKLIN_MAIN DIR_HKLIN_MAIN \
        -setfileparam resolution_min RESOLUTION_DMAX \
        -setfileparam resolution_max RESOLUTION_DMIN \
        -setfileparam resolution_max RESOLUTION_AUTO_DMIN \
        -setfileparam cell_1 CELL_1 \
        -setfileparam cell_2 CELL_2 \
        -setfileparam cell_3 CELL_3 \
        -setfileparam cell_4 CELL_4 \
        -setfileparam cell_5 CELL_5 \
        -setfileparam cell_6 CELL_6 \
        -setfileparam space_group_name FILE_SPACEGROUP \
        -command "phaser_MR_set_test_space_group $arrayname" \
        -command "phaser_MR_set_reso $arrayname"

   CreateLabinLine line \
       "Select amplitude (F) and sigma (SIGF)" \
       HKLIN_MAIN "F" F {NULL} \
       -sigma "SIGF" SIGF {NULL}

  CreateLine line \
      message "Space group read from mtz file.\
               By default, phaser is run with this space group" \
      label "Space group read from mtz file" \
      varlabel FILE_SPACEGROUP \
      label "; " \
      widget TOG_SPACEGROUP -toggleon \
      message "Run Phaser with a different space group" \
      label "Run Phaser with space group" \
      widget TEST_SPACEGROUP \
      toggle_display MR_MODE open [list ROT RNP PAK]

  OpenSubFrame frame -toggle_display MR_MODE open [list AUTO TRA]

  CreateLine line \
      message "Space group read from mtz file." \
      label "Space group read from mtz file" \
      varlabel FILE_SPACEGROUP \
      label "; " \
      message "Specify the space group(s) to run Phaser with" \
      label "Run Phaser with" \
      widget SPACEGROUP_OPTION 

  CreateLine line \
      widget TOG_SGAL_SORT -toggleon \
      label "Test spacegroups in order of general occurrence in PDB" \
      widget SGAL_SORT_ONOFF \
      toggle_display SPACEGROUP_OPTION open [list SG_ALT SG_ALL] 

  OpenSubFrame frame -toggle_display SPACEGROUP_OPTION open SG_ALT

  CreateExtendingFrame N_SG phaser_MR_sg \
       "Add another test space group" "Add another space group" \
       [list PHASER_TEST_SG ] 

  CloseSubFrame

  CloseSubFrame

# $line.l2 configure -width 7 -background $configure(COLOUR_BACKGROUND)

#========================================================================
# The "Define ensembles" folder

  OpenFolder 2 open

  CreateToggleFrame N_ENSEMBLE phaser_MR_ensemble \
      "Define another ensemble" \
      "Ensemble #" \
      "Add ensemble" \
      [list ENSEMBLE_ID ENSEMBLE_OPTION HKLIN DIR_HKLIN ENSEMBLE_LABIN FC PHIC N_PDB ] \
       -edit_proc edit_phaser_MR_ensemble \
       -child phaser_MR_pdb

#========================================================================
# The "Define composition of the asymmetric unit" folder

  OpenFolder 3 MR_MODE hide [list PAK ] open 

  CreateLine line \
      message "Total scattering of atoms in the asymmetric unit" \
      label "Total scattering determined by "\
      widget SCATTERING \
      toggle_display SCATTERING hide SOLVENT 

  CreateLine line \
      message "Total scattering of atoms in the asymmetric unit" \
      label "Total scattering determined by "\
      widget SCATTERING \
      widget SCATTERING_SOLVENT  -oblig \
      toggle_display SCATTERING open SOLVENT 

  OpenSubFrame frame -toggle_display SCATTERING open COMPONENT hide

  CreateExtendingFrame N_COMPONENT phaser_MR_component \
      "Define another protein or nucleic acid component" "Define another component" \
      [list PROTDNA MW ASYM COMP_OPTION COMP_NRES COMP_FILE DIR_COMP_FILE ]

  CloseSubFrame

  OpenSubFrame frame -toggle_display SCATTERING open FRAC hide

  CreateExtendingFrame N_COMPONENT_FRAC phaser_MR_fractional \
      "Define another protein or nucleic acid component" "Define another component" \
      [list COMP_ENSE_ID COMP_ENSE_FRAC ]

  CloseSubFrame

#========================================================================
# The "Search parameters" folder 

  OpenFolder 4 open

  CreateLine line \
      message "A SOL file is a Phaser search results file" \
      label "Define known solutions from a SOL file" \
     toggle_display MR_MODE open [list RNP PAK] hide

  CreateInputFileLine line \
      "Define known solutions from a SOL file \
       (Phaser search results file)" \
      "SOL file" \
      SET_SOL_FILE DIR_SET_SOL_FILE \
     -toggle_display MR_MODE open [list RNP PAK] hide

  CreateLine line \
      message "A .rlist file is a Phaser rotation search results file" \
      label "Define orientations for translation search\
             and any known solutions from a .rlist file" \
     toggle_display MR_MODE open [list TRA ] hide

  CreateInputFileLine line \
      "A .rlist file is a Phaser rotation search results file" \
      ".rlist file" \
      TRA_RLIST_FILE DIR_TRA_RLIST_FILE \
     -toggle_display MR_MODE open [list TRA ] hide


  OpenSubFrame frame -toggle_display MR_MODE open [list ROT] hide

#  CreateLine line \
       label "Allow search with alternative ensembles (models) for a single component of ASU" \
       message "Set toggle on for OR search" \
       widget MR_ROT_SEARCH 

  CreateLine line \
      message "Choose an ensemble to be used for the rotation search" \
      label "Perform search using " \
      widget MR_ROT_SEARCH_ID

  OpenSubFrame frame -toggle_display MR_ROT_SEARCH open SEARCH_OR hide

  CreateExtendingFrame N_ROT_SEARCH_EXTRA phaser_MR_rot_extra \
      "Add an alternative ensemble to be searched for" \
      "Add an alternative search ensemble" \
      [list MR_ROT_SEARCH_ID_EXTRA]

  CloseSubFrame
  CloseSubFrame

  OpenSubFrame frame -toggle_display MR_MODE open AUTO hide

#  CreateLine line \
       label "Allow search with alternative ensembles (models) for a single component of ASU" \
       message "Set toggle on for OR search" \
       widget MR_SEARCH

  OpenSubFrame frame -toggle_display MR_SEARCH open SEARCH_SIMPLE hide

  CreateExtendingFrame N_SIMPLE_SEARCH phaser_MR_simple_search \
      "Add another ensemble to be searched for" \
      "Add another search" \
      [list MR_SIMPLE_ENSEMBLE_ID MR_SIMPLE_ENSEMBLE_NUM ]

  CloseSubFrame

  OpenSubFrame frame -toggle_display MR_SEARCH open SEARCH_OR hide

  CreateToggleFrame N_SEARCH phaser_MR_or_search \
      "Perform another mr auto search" \
      "Search #" \
      "Add another search" \
      [list MR_FIRST_OR_ENSEMBLE_ID MR_FIRST_OR_ENSEMBLE_NUM MR_EXTRA_OR_ENSEMBLE_ID N_SEARCH_EXTRA ] \
      -child phaser_MR_or_search_extra 

  CloseSubFrame
  CloseSubFrame

#========================================================================
# The "Additional Search parameters" folder

  OpenFolder 5 closed

  CreateLine line \
     label "No additional search parameters" -italic \
     toggle_display MR_MODE open [list PAK RNP] hide

  CreateLine line \
       label "Allow search with alternative ensembles (models) for a single component of ASU" \
       message "Set toggle on for OR search" \
       widget MR_SEARCH \
       toggle_display MR_MODE open [list AUTO] hide

  CreateLine line \
       label "Allow search with alternative ensembles (models) for a single component of ASU" \
       message "Set toggle on for OR search" \
       widget MR_ROT_SEARCH \
       toggle_display MR_MODE open [list ROT] hide

  CreateLine line \
      message "A SOL file is a Phaser search results file" \
      label "Define any known solutions from a SOL file" \
     toggle_display MR_MODE open [list AUTO ROT] hide

  CreateInputFileLine line \
      "Define known solutions from a SOL file\
       (Phaser search results file)" \
      "SOL file" \
      SET_SOL_FILE_NOTOB DIR_SET_SOL_FILE_NOTOB \
     -notoblig \
     -toggle_display MR_MODE open [list AUTO ROT] hide

  OpenSubFrame frame -toggle_display MR_MODE open [list AUTO ROT] hide

  CreateLine line \
      message "TARGET: select the rotation target function to be used" \
      widget TOG_FRF_TARGET -toggleon \
      label "Rotation target function" \
      widget FRF_TARGET_OPTION

  OpenSubFrame frame -toggle_display FRF_TARGET_OPTION open BRUTE hide

  CreateLine line \
      message "Select to perform a full or restricted search" \
      label "Search" \
      widget BRF_SEARCH_OPTION \
      message "Restrict the search to region around this set of Euler angles" \
      label "Alpha" \
      widget AROUND_ALPHA -oblig \
      label "Beta" \
      widget AROUND_BETA -oblig \
      label "Gamma" \
      widget AROUND_GAMMA -oblig \
      message "Rotational distance around the given Euler angle set" \
      label "Range" \
      widget AROUND_EULER_RANGE -oblig \
      toggle_display BRF_SEARCH_OPTION open AROUND 

  CreateLine line \
      message "Select to perform a full or restricted search" \
      label "Search" \
      widget BRF_SEARCH_OPTION \
      toggle_display BRF_SEARCH_OPTION open FULL 

  CloseSubFrame

  CloseSubFrame

  OpenSubFrame frame -toggle_display MR_MODE open [list TRA AUTO] hide

  CreateLine line \
      message "TARGET: select the translation target function to be used" \
      widget TOG_FTF_TARGET -toggleon \
      label "Translation target function" \
      widget FTF_TARGET_OPTION

  OpenSubFrame frame -toggle_display FTF_TARGET_OPTION open BRUTE hide

  CreateLine line \
      message "Select search type: full, around a point,\
              within a region, along a line or within a plane" \
      label "Perform" \
      widget BTF_SEARCH_OPTION \
      label "translation search"

  CreateLine line \
      message "Select the coordinate system" \
      label "Search point/line/volume defined in" widget COORD_SYS label "coordinates" \
      toggle_display BTF_SEARCH_OPTION hide FULL

  CreateLine line \
      label "Search around point" \
      label "X" widget START_X -oblig \
      label "Y" widget START_Y -oblig \
      label "Z" widget START_Z -oblig \
      message "Range around point to search" \
      label "with search range" widget AROUND_COORD_RANGE -oblig \
      label "Angstroms" \
      toggle_display BTF_SEARCH_OPTION open AROUND

  CreateLine line \
      label "Search box top corner" \
      label "X" widget START_X -oblig -width 6 \
      label "Y" widget START_Y -oblig -width 6 \
      label "Z" widget START_Z -oblig -width 6 \
      label "bottom corner" \
      label "X" widget END_X -oblig -width 6 \
      label "Y" widget END_Y -oblig -width 6 \
      label "Z" widget END_Z -oblig -width 6 \
      toggle_display BTF_SEARCH_OPTION open [list REGION ] hide

  CreateLine line \
      label "Search along line start" \
      label "X" widget START_X -oblig \
      label "Y" widget START_Y -oblig \
      label "Z" widget START_Z -oblig \
      label "end" \
      label "X" widget END_X -oblig \
      label "Y" widget END_Y -oblig \
      label "Z" widget END_Z -oblig \
      toggle_display BTF_SEARCH_OPTION open [list LINE] hide

  CloseSubFrame

  CloseSubFrame

 
#========================================================================
# The "Expert parameters" folder

  OpenFolder 6 closed

  CreateLine line \
      label "Warning: allow phaser to optimize the resolution" -italic \
      toggle_display MR_MODE hide [list PAK]

  CreateLine line \
      message "Default is to take all data from low resolution limit\
               to the greater of dmin and 2.5 A" \
      widget TOG_RESOLUTION -toggleon \
      label "Resolution range" \
      message "Enter dmax, in Angstroms" \
      widget RESOLUTION_DMAX \
      label "A to" \
      message "If the dataset goes to higher than 2.5 A resolution,\
               then a default dmin of 2.5 A is set." \
      widget RESOLUTION_DMIN_MR \
      label "A" \
      toggle_display MR_MODE hide [list PAK]

  CreateLine line \
      message "Default is to take all data in mtz file" \
      widget TOG_RESOLUTION_AUTO -toggleon \
      label "High resolution for final refinement" \
      message "Enter dmin, in Angstroms" \
      widget RESOLUTION_AUTO_DMIN \
      label "A" \
      toggle_display MR_MODE open [list AUTO] hide

  OpenSubFrame frame -toggle_display SEARCH_METHOD open FAST hide

  CreateLine line \
      message "Search to high resolution if high TFZ not found with default resolution" \
      widget TOG_SEARCH_HIRES -toggleon \
      label "Search high resolution if low TFZ " widget SEARCH_HIRES \
      toggle_display MR_MODE open [list AUTO] hide

  CloseSubFrame

  CreateLine line \
     label "Warning: Do not toggle checkboxes unless changing parameter from default" -italic

  OpenSubFrame frame -toggle_display MR_MODE open [list AUTO PAK] hide

  CreateLine line \
       message "Solutions with the lowest number of clashes will be saved \
               if less than the max allowed (default 10)" \
      widget TOG_PACK -toggleon \
      label "Packing criterion " \
      widget PACK_OPTION \
      label "Allow " \
      widget PACK_ALLOWED_CLASHES \
      toggle_display PACK_OPTION open BEST

  CreateLine line \
       message "All solutions will be saved no matter how many clashes" \
      widget TOG_PACK -toggleon \
      label "Packing criterion " \
      widget PACK_OPTION \
      toggle_display PACK_OPTION open ALL

  CreateLine line \
       message "Default for allowed C-alpha clashes is 10;\
                increase for low-homology models" \
      widget TOG_PACK -toggleon \
      label "Packing criterion " \
      widget PACK_OPTION \
      label "Allow " \
      widget PACK_ALLOWED_CLASHES \
      toggle_display PACK_OPTION open ALLOWED

  CreateLine line \
       message "Default for allowed C-alpha clashes is 10;\
                increase for low-homology models" \
      widget TOG_PACK -toggleon \
      label "Packing criterion " \
      widget PACK_OPTION \
      label "Allow " \
      widget PACK_ALLOWED_CLASHES \
      toggle_display PACK_OPTION open PERCENT

  CreateLine line \
      widget TOG_PACK_QUICK -toggleon \
      label "Quick Packing " \
      widget PACK_QUICK_ONOFF \
      toggle_display PACK_OPTION hide ALL

  CloseSubFrame

  OpenSubFrame frame -toggle_display MR_MODE open [list AUTO ROT] hide

  CreateLine line \
      message "Choose whether to purge the solutions from RF " \
      widget TOG_PURGE_ROT -toggleon \
      label "Purge rotation peaks" \
      widget PURGE_ROT_ONOFF \
      label " percent cutoff" \
      widget PURGE_ROT_PERCENT \
      label "but with maximum number " \
      widget PURGE_ROT_NUMBER -width 5\
      toggle_display PURGE_ROT_ONOFF open ON

  CreateLine line \
      message "Choose whether to purge the solutions from RF" \
      widget TOG_PURGE_ROT -toggleon \
      label "Purge rotation peaks" \
      widget PURGE_ROT_ONOFF \
      toggle_display PURGE_ROT_ONOFF open OFF

  CloseSubFrame

  OpenSubFrame frame -toggle_display MR_MODE open [list AUTO TRA] hide

  CreateLine line \
      message "Choose whether to purge the solutions from TF" \
      widget TOG_PURGE_TRA -toggleon \
      label "Purge translation peaks" \
      widget PURGE_TRA_ONOFF \
      label " percent cutoff" \
      widget PURGE_TRA_PERCENT \
      label "but with maximum number " \
      widget PURGE_TRA_NUMBER -width 5 \
      toggle_display PURGE_TRA_ONOFF open ON

  CreateLine line \
      message "Choose whether to purge the solutions from TF" \
      widget TOG_PURGE_TRA -toggleon \
      label "Purge translation peaks" \
      widget PURGE_TRA_ONOFF \
      toggle_display PURGE_TRA_ONOFF open OFF

  CloseSubFrame

  OpenSubFrame frame -toggle_display MR_MODE open [list AUTO] hide

  CreateLine line \
      message "Choose whether to purge the solutions from RNP" \
      widget TOG_PURGE_RNP -toggleon \
      label "Purge refinement peaks" \
      widget PURGE_RNP_ONOFF \
      label " percent cutoff" \
      widget PURGE_RNP_PERCENT \
      label "but with maximum number " \
      widget PURGE_RNP_NUMBER -width 5 \
      toggle_display PURGE_RNP_ONOFF open ON

  CreateLine line \
      message "Choose whether to purge the solutions from RNP" \
      widget TOG_PURGE_RNP -toggleon \
      label "Purge refinement peaks" \
      widget PURGE_RNP_ONOFF \
      toggle_display PURGE_RNP_ONOFF open OFF

  CreateLine line \
      message "Target for expected LLG given model completeness and RMS" \
      widget TOG_USE_ELLG -toggleon \
      label "Use \"expected LLG\" criteria in decision making" widget USE_ELLG label " Target LLG " widget ELLG_TARGET \
      toggle_display USE_ELLG open ON hide

  CreateLine line \
      message "Target for expected LLG given model completeness and RMS" \
      widget TOG_USE_ELLG -toggleon \
      label "Use \"expected LLG\" criteria in decision making" widget USE_ELLG \
      toggle_display USE_ELLG open OFF hide

  CloseSubFrame

  OpenSubFrame frame -toggle_display MR_MODE hide [list PAK] open

  CreateLine line \
      message "TNCS: use or ignore translational NCS if present" \
      widget TOG_TNCS_USE -toggleon \
      label "Use translational NCS if present " \
      widget TNCS_USE -command "phaser_MR_tncs_use_and_valid $arrayname" \
      toggle_display TNCS_USE open ON

  CreateLine line \
      label "TNCS: " \
      widget TOG_TNCS_NMOL -toggleon \
      label "Number of assemblies related by TNCS " \
      widget TNCS_NMOL \
      toggle_display TNCS_USE open ON

  CreateLine line \
      message "TNCS: Parameters for identifying TNCS from Patterson" \
      label "TNCS: " \
      widget TOG_TNCS_PATT_PERCENT -toggleon \
      label "Minimum percent of Patterson origin peak " \
      widget TNCS_PATT_PERCENT \
      toggle_display TNCS_USE open ON

  CreateLine line \
      message "TNCS: translation vector in fractional coordinates" \
      label "TNCS: " \
      widget TOG_TNCS_TRA_VECTOR -toggleon \
      label "Fix vector " \
      widget TNCS_TRA_VECTOR_X \
      widget TNCS_TRA_VECTOR_Y \
      widget TNCS_TRA_VECTOR_Z label "(fractional coordinates)" \
      toggle_display TNCS_USE open ON

  CreateLine line \
      message "TNCS: use or ignore translational NCS if present" \
      widget TOG_TNCS_USE -toggleon \
      label "Use translational NCS if present " \
      widget TNCS_USE -command "phaser_MR_tncs_use_and_valid $arrayname" \
      toggle_display TNCS_USE open OFF

  CloseSubFrame

  OpenSubFrame frame -toggle_display MR_MODE open [list AUTO ]

  CreateLine line \
     message "Use FAST if you expect the TFZ to be high for each copy" \
     widget TOG_SEARCH_METHOD -toggleon \
     label "Search method for many copies in ASU" \
     widget SEARCH_METHOD \
     label "Deep rotation search" widget SEARCH_DEEP \
        -command "update_phaser_MR_search $arrayname" \
     message "Percentage to Reduce RF peak cutoff on 2nd pass" \
     label "Down" widget SEARCH_DOWN_PERC -width 5 \
        -command "update_phaser_MR_search $arrayname" \
     label "%" \
     message "Value for reducing cutoff" \
     toggle_display SEARCH_METHOD open FAST hide

  CreateLine line \
     message "Use FAST if you expect the TFZ to be high for each copy" \
     widget TOG_SEARCH_METHOD -toggleon \
     label "Search method for many copies in ASU" \
     widget SEARCH_METHOD \
     label "Permute search order" widget PERMUTATIONS_ONOFF \
        -command "update_phaser_MR_search $arrayname" \
     toggle_display SEARCH_METHOD open FULL hide

  CloseSubFrame

  OpenSubFrame frame -toggle_display MR_MODE open [list AUTO PAK TRA]

  CreateLine line \
     message "Controls how TFZ is used in decision making" \
     widget TOG_ZSCORE -toggleon \
     label "Use Z-score (TFZ)" widget ZSCORE_USE \
     label "TFZ solved " widget ZSCORE_SOLVED \
     label "and also half highest" widget ZSCORE_HALF \
     toggle_display ZSCORE_USE open ON hide

  CreateLine line \
     message "Controls how TFZ is used in decision making" \
     widget TOG_ZSCORE -toggleon \
     label "Use Z-score (TFZ)" widget ZSCORE_USE \
     toggle_display ZSCORE_USE open OFF hide

  CloseSubFrame

#========================================================================
# The "Output control" folder

  OpenFolder 7 MR_MODE closed

  CreateLine line \
      message "VERBOSE: more information included in log file than by default" \
      widget TOG_VERBOSE \
      label "Verbose output to log file" \

  CreateLine line \
      message "DEBUG: debugging information included in log file than by default" \
      widget TOG_VERBOSE_EXTRA \
      label "Debug output to log file" 

  CreateLine line \
      message "Default number of top pdbfiles and mtzfiles is 1" \
      widget TOG_TOPF -toggleon \
      label "Number of top solutions to output as PDB and MTZ files"\
      widget XYZOUT_NPDB

  CreateLine line \
      message "Output the results in a .sol file" \
      widget TOG_KEYWDS -toggleon \
      label "SOL file output" \
      widget KEYWDS_ONOFF \
      toggle_display MR_MODE hide [list ROT]

  CreateLine line \
      message "Output the results in a .rlist file" \
      widget TOG_KEYWDS -toggleon \
      label "RLIST file output" \
      widget KEYWDS_ONOFF \
      toggle_display MR_MODE open [list ROT] hide

  CreateLine line \
      message "Controls output of PDB files containing potential solutions."  \
      widget TOG_XYZOUT -toggleon \
      label "PDB file output" \
      widget XYZOUT_ONOFF

  CreateLine line \
      message "Controls output of MTZ files with phase information from solutions." \
      widget TOG_HKLOUT -toggleon \
      label "MTZ file output" \
      widget HKLOUT_ONOFF \
      toggle_display MR_MODE hide [list PAK ]


#========================================================================
# The "Developer parameters" folder
#
  OpenFolder 8 closed

   CreateLine line \
     label "Do not alter these parameters" -italic

  OpenSubFrame frame -toggle_display MR_MODE open [list AUTO ROT] hide

  CreateLine line \
      message "Final selection criterion for peaks from rotation searches" \
      widget TOG_FINAL_ROT -toggleon \
      label "Rotation search peak selection" \
      message "Default 75 percent" \
      widget FINAL_OPTION_ROT \
      message "Enter the cutoff" \
      widget FINAL_SIGMA_ROT \
      toggle_display FINAL_OPTION_ROT hide [list ALL] open 

  CreateLine line \
      message "Final selection criterion for peaks from rotation searches" \
      widget TOG_FINAL_ROT -toggleon \
      label "Rotation search peak selection" \
      message "Default 75 percent" \
      widget FINAL_OPTION_ROT \
      toggle_display FINAL_OPTION_ROT open [list ALL] hide 

  CloseSubFrame

  OpenSubFrame frame -toggle_display MR_MODE open [list AUTO TRA] hide

  CreateLine line \
      message "Final selection criterion for peaks from translation searches" \
      widget TOG_FINAL_TRA -toggleon \
      label "Translation search peak selection" \
      message "Default 75 percent" \
      widget FINAL_OPTION_TRA \
      message "Enter the cutoff" \
      widget FINAL_SIGMA_TRA \
      toggle_display FINAL_OPTION_TRA hide [list ALL] open 

  CreateLine line \
      message "Final selection criterion for peaks from translation searches" \
      widget TOG_FINAL_TRA -toggleon \
      label "Translation search peak selection" \
      message "Default 75 percent" \
      widget FINAL_OPTION_TRA \
      toggle_display FINAL_OPTION_TRA open [list ALL] hide 

  CloseSubFrame

  CreateLine line \
      message "Select whether clustered or raw peaks are saved" \
      widget TOG_PEAKS_ROT_CLUSTER -toggleon \
      label "Rotation clustering" \
      widget PEAKS_ROT_CLUSTER \
      toggle_display MR_MODE open [list AUTO ROT]

  CreateLine line \
      message "Select whether clustered or raw peaks are saved" \
      widget TOG_PEAKS_TRA_CLUSTER -toggleon \
      label "Translation clustering" \
      widget PEAKS_TRA_CLUSTER \
      toggle_display MR_MODE open [list AUTO TRA] 


  CreateLine line \
      message "Select whether or not to rescore fast search solutions" \
      widget TOG_RESCORE_ROT -toggleon \
      label "Rescoring rotation" \
      widget RESCORE_ONOFF_ROT \
      toggle_display MR_MODE open [list AUTO ROT] hide

  CreateLine line \
      message "Select whether or not to rescore fast search solutions" \
      widget TOG_RESCORE_TRA -toggleon \
      label "Rescoring translation" \
      widget RESCORE_ONOFF_TRA \
      toggle_display MR_MODE open [list AUTO TRA] hide

  CreateLine line \
      message "BINS: specify the binning for the data reflections"\
      widget TOG_BINS -toggleon \
      label "Bins for Data:   Min" widget BINS_L label "Max" widget BINS_H label "Width" widget BINS_W \
      toggle_display MR_MODE hide [list PAK ]

  CreateLine line \
      message "BINS: specify the binning for the calculated ensemble reflections"\
      widget TOG_BINS_ENSE -toggleon \
      label "Bins for Ensemble:   Min" widget BINS_ENSE_L label "Max" widget BINS_ENSE_H label "Width" widget BINS_ENSE_W \
      toggle_display MR_MODE hide [list PAK ]

  CreateLine line \
      message "BOXSCALE: specify how finely the ensemble structure factors\
               are sampled in reciprocal space" \
      widget TOG_BOXSCALE -toggleon \
      label "Box scale factor" \
      message "The ensemble 'cell' is <BOXSCALE>*(extent of molecule)" \
      widget BOXSCALE \
      toggle_display MR_MODE hide [list PAK]

  CreateLine line \
      message "CLMN: radius for decomposition of the Patterson" \
      widget TOG_CLMN -toggleon \
      label "CLMN sphere outer radius " \
      message "Specify outer radius in Angstroms. Min acceptable value is 5 A" \
      widget CLMN_SPHERE \
      label "LMIN " \
      widget CLMN_INNER \
      label "LMAX " \
      widget CLMN_OUTER \
      toggle_display MR_MODE open [list AUTO ROT ] hide

  OpenSubFrame frame -toggle_display MR_MODE hide [list PAK] open

    CreateLine line \
      message "Refinement macrocyles" \
      widget TOG_ANISO -toggleon \
      label "Anisotropic refinement protocol" \
      widget MACA_PROTOCOL

    OpenSubFrame frame \
      -toggle_display MACA_PROTOCOL open CUSTOM hide
     CreateExtendingFrame N_MACA phaser_MR_maca \
        "Customize the anisotropic refinement" \
        "Add another anisotropic macrocycle" \
        [list MACA_ANIS MACA_BINS MACA_SOLK MACA_SOLB MACA_NCYC ]
    CloseSubFrame

  CloseSubFrame

  OpenSubFrame frame -toggle_display MR_MODE open [list AUTO RNP] hide

    CreateLine line \
      message "Refinement macrocyles" \
      widget TOG_MACM -toggleon \
      label "Molecular replacement refinement protocol" \
      widget MACM_PROTOCOL

    OpenSubFrame frame \
      -toggle_display MACM_PROTOCOL open CUSTOM hide
     CreateExtendingFrame N_MACM phaser_MR_macm \
        "Customize the MR refinement" \
        "Add another MR macrocycle" \
        [list MACM_ROT MACM_TRA MACM_BFAC MACM_VRMS MACM_CELL MACM_LAST MACM_NCYC ]
    CloseSubFrame

  CloseSubFrame

  OpenSubFrame frame -toggle_display MR_MODE hide [list PAK] open

  CreateLine line \
      message "OUTLIER: choose whether to reject large, unlikely E-values" \
      widget TOG_OUTLIER -toggleon \
      label "Outlier rejection" \
      widget OUTLIER_OPTION \
      label "outlier probability" \
      message "Outliers with a probability \
               less than the cutoff are rejected" \
      widget OUTLIER_PROB -width 10 \
      toggle_display OUTLIER_OPTION open ON 

  CreateLine line \
      message "OUTLIER: choose whether to reject large, unlikely E-values.\
               Default is ON with probability 0.00001" \
      widget TOG_OUTLIER -toggleon \
      label "Outlier rejection" \
      widget OUTLIER_OPTION \
      toggle_display OUTLIER_OPTION open OFF

  CloseSubFrame

  CreateLine line \
      message "PACKING: sampling of search space" \
      widget TOG_PACK_DISTANCE -toggleon \
      label "Distance for the packing test" \
      message "Distance between marker atoms for the clash test " \
      widget PACK_DISTANCE \
      toggle_display MR_MODE open [list AUTO PAK]

  CreateLine line \
      message "PACKING: sampling of search space" \
      widget TOG_PACK_TRACE -toggleon \
      label "Use Trace atom for packing analysis " \
      message "Use C-alphas in proteins, P for RNA/DNA for clash test" \
      widget PACK_TRACE \
      label "Trace maximum " \
      widget PACK_TRACE_MAX \
      toggle_display MR_MODE open [list AUTO PAK]

  CreateLine line \
      widget TOG_PACK_COMPACT -toggleon \
      label "Pack molecules into compact group " \
      widget PACK_COMPACT_ONOFF \
      toggle_display MR_MODE open [list AUTO PAK]

  CreateLine line \
      message "PTGROUP: tolerances for detection of model symmetry" \
      widget TOG_PTGR_SEQ -toggleon \
      label "Point Group Minimum Sequence Tolerances: Coverage" \
      widget PTGR_COVERAGE  \
      label "Identity" \
      widget PTGR_IDENTITY \
      toggle_display MR_MODE open [list AUTO RNP PAK]

  CreateLine line \
      message "PTGROUP: tolerances for detection of model symmetry" \
      widget TOG_PTGR_XYZ -toggleon \
      label "Point Group Maximum Coordinate Tolerances: RMS" \
      widget PTGR_RMSD -width 6 \
      label "Angular" \
      widget PTGR_TOL_ANG -width 6 \
      label "Spatial" \
      widget PTGR_TOL_SPC -width 6 \
      toggle_display MR_MODE open [list AUTO RNP]

  CreateLine line \
      widget TOG_SEARCH_ORDER_AUTO -toggleon \
      label "Determine ensemble search order automatically" \
      widget SEARCH_ORDER_AUTO_ONOFF \
      toggle_display MR_MODE open [list AUTO ]

  CreateLine line \
      message "SAMPLING: sampling of search space" \
      widget TOG_SAMP_ROT -toggleon \
      label "Sampling for rotation search" \
      message "Sampling for rotation search given in degrees" \
      widget SAMPLING_ROT \
      toggle_display MR_MODE open [list AUTO ROT]

  CreateLine line \
      message "SAMPLING: sampling of search space" \
      widget TOG_SAMP_TRA -toggleon \
      label "Sampling for translation search" \
      message "Sampling for translation search given in Angstroms" \
      widget SAMPLING_TRA \
      toggle_display MR_MODE open [list AUTO TRA] 

  CreateLine line \
      message "RESHARPEN: B-factor added back to map coefficients" \
      widget TOG_RESHARPEN -toggleon \
      label "Resharpening percentage " \
      message "Resharpening percentage " \
      widget RESHARPEN_PERC \
      toggle_display MR_MODE hide [list PAK] 

  CreateLine line \
      message "SOLPARAMETERS: set the solvent parameters for the ensembling" \
      widget TOG_SOLP -toggleon \
      label "Solvent parameters for SigmaA: Ksol " widget SOLP_FSOL \
      label " Bsol " widget SOLP_BSOL \
      label " Minimum " widget SOLP_SIGA_MIN \
      toggle_display MR_MODE hide [list PAK]

  CreateLine line \
      message "SOLPARAMETERS: set the solvent parameters for the ensembling" \
      widget TOG_BULK_SOLP -toggleon \
      label "Solvent parameters for Bulk Mask: Use " widget SOLP_BULK_USE \
      label " Ksol " widget SOLP_BULK_FSOL \
      label " Bsol " widget SOLP_BULK_BSOL \
      toggle_display MR_MODE hide [list PAK]

  CreateLine line \
     message "Controls how TFZ is used in decision making" \
     widget TOG_ZSCORE_HIGH -toggleon \
     label "High TFZ minimum for terminating deep search of RF peaks" widget ZSCORE_HIGH \
     toggle_display ZSCORE_USE open ON hide

  OpenSubFrame frame -toggle_display TNCS_USE_AND_VALID open 1

  CreateLine line \
      message "TNCS: refine TNCS rotation angles starting from sampling grid" \
      label "TNCS: " \
      widget TOG_TNCS_ROT_GRID -toggleon \
      label "Refine TNCS rotation starting from angles on a grid " \
      widget TNCS_ROT_GRID

  CreateLine line \
      message "TNCS: rotation angle in degrees, perturbations around X Y and Z" \
      label "TNCS: " \
      widget TOG_TNCS_ROT_ANGLE -toggleon \
      label "Initial TNCS rotation " \
      widget TNCS_ROT_ANGLE_X \
      widget TNCS_ROT_ANGLE_Y \
      widget TNCS_ROT_ANGLE_Z label "Degrees (XYZ perturbations)" \
      toggle_display TNCS_ROT_GRID open ON 

  CreateLine line \
      message "TNCS: rotation range" \
      label "TNCS: " \
      widget TOG_TNCS_ROT_RANGE -toggleon \
      label "Range of angles to sample to find initial TNCS rotation " \
      widget TNCS_ROT_RANGE \
      label "Degrees" \
      toggle_display TNCS_ROT_GRID open ON 

  CreateLine line \
      message "TNCS: rotation range" \
      label "TNCS: " \
      widget TOG_TNCS_ROT_SAMPLING -toggleon \
      label "Sampling of angles to find initial TNCS rotation " \
      widget TNCS_ROT_SAMPLING \
      label "Degrees" \
      toggle_display TNCS_ROT_GRID open ON 

  CreateLine line \
      message "TNCS: rotation angle in degrees, perturbations around X Y and Z" \
      label "TNCS: " \
      widget TOG_TNCS_ROT_ANGLE -toggleon \
      label "Fixed rotation between TNCS related molecules " \
      widget TNCS_ROT_ANGLE_X \
      widget TNCS_ROT_ANGLE_Y \
      widget TNCS_ROT_ANGLE_Z label "Degrees" \
      toggle_display TNCS_ROT_GRID open OFF

  CreateLine line \
      message "TNCS: refine rotation angles" \
      label "TNCS: " \
      widget TOG_TNCS_REFI_ROT -toggleon \
      label "Refine TNCS rotations prior to translation function " \
      widget TNCS_REFI_ROT

  CreateLine line \
      message "TNCS: RMSD between TNCS related molecules" \
      label "TNCS: " \
      widget TOG_TNCS_VAR_RMSD -toggleon \
      label "RMSD between TNCS related molecules " \
      widget TNCS_VAR_RMSD \
      label "Angstroms"

  CreateLine line \
      message "TNCS: Fraction of asymmetric unit obeying TNCS" \
      label "TNCS: " \
      widget TOG_TNCS_VAR_FRAC -toggleon \
      label "Fraction of asymmetric unit obeying TNCS " \
      widget TNCS_VAR_FRAC

  CreateLine line \
      message "TNCS: Parameters for identifying TNCS from Patterson" \
      label "TNCS: " \
      widget TOG_TNCS_PATT_RESO -toggleon \
      label "Patterson high resolution " \
      widget TNCS_PATT_HIRES \
      label "low resolution " \
      widget TNCS_PATT_LORES

  CreateLine line \
      message "TNCS: Parameters for identifying TNCS from Patterson" \
      label "TNCS: " \
      widget TOG_TNCS_PATT_DISTANCE -toggleon \
      label "Minimum length of TNCS vector " \
      widget TNCS_PATT_DISTANCE

  CloseSubFrame

  }

#use puts to output debugging info to screen
