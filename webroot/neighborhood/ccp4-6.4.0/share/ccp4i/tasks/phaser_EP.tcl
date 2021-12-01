# =======================================================================
# phaser_EP.tcl --
#
# Phaser SAD pipeline
#
# CCP4Interface
#
# =======================================================================

#------------------------------------------------------------------------------
proc phaser_EP_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable phaser]] } {
    return 0
  }
  return 1
}

#------------------------------------------------------------------------
  proc phaser_EP_setup { typedefVar arrayname } {
#------------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname array

  DefineMenu _mode_ep [list "Single-wavelength anomalous dispersion (SAD)" \
                            "SAD with molecular replacement partial structure"] \
                      [list "SAD" "MRSAD"]

  DefineMenu _composition_option \
    [ list "average solvent content for protein crystal" "solvent content of protein crystal" "components in asymmetric unit" ] \
    [ list "AVERAGE" "SOLVENT" "COMPONENT" ]

  DefineMenu _protnucleic \
    [list "protein" "nucleic acid" ] [list "PROTEIN" "NUCLEIC" ]

  DefineMenu _rmsid_option \
   [list "rms difference" "sequence identity" ] [list "RMS" "IDENT" ]

  DefineMenu _clash_option \
    [list "by optical resolution" "by fixed distance" ] [list "DEFAULT" "DISTANCE" ]

  DefineMenu _coord_frac \
    [list "fractional" "orthogonal" ] [list "FRAC" "ORTH" ]

  DefineMenu _llgc_complete \
    [list "on: all atom types" "off" "on: select atom types" ] [list "DEFAULT" "OFF" "ON" ]

  DefineMenu _scat_edge\
    [list "only if near edge" "off" "on" ] [list "EDGE" "OFF" "ON" ]

  DefineMenu _llgc_method \
    [list "all atomtype LLG-maps" "imaginary LLG-map only"] [list "ATOMTYPE" "IMAGINARY" ]

  DefineMenu _pdb_mtz_option \
    [list "pdb" "mtz"] [list "PDB" "MTZ" ]

  DefineMenu _atom_search_option \
    [list "SHELXD" "HYSS"] [list "SHELXD" "HYSS" ]

  DefineMenu _scat_option \
    [list "at CuK-alpha wavelength" "at other wavelength" "by fluorescence scan" "explicitly by atomtype"]  [list "CUKA" "LAMBDA" "MEASURED" "ATOMTYPE"]

  DefineMenu _atom_option \
    [list "run phenix.hyss" "run ShelxC/D" "in PDB file" "in HA file" "in SOL file" "entered below"] \
    [list "HYSS" "SHELXD" "PDB" "HA" "SOL" "MANUAL" ]

  DefineMenu _atom_option_short \
    [list "in PDB file" "in HA file" "in SOL file" "entered below"] \
    [list "PDB" "HA" "SOL" "MANUAL" ]

  DefineMenu _bfactor_option \
    [list "Wilson B" "Entered" ] \
    [list "WILSON" "VALUE" ]

  DefineMenu _rms_option \
   [list "rms difference" "sequence identity" ] [list "RMS" "IDENT" ]

  DefineMenu _hand_option \
   [list "Original" "Change" "Both"] [list "OFF" "ON" "BOTH" ]

  set typedef(_onoff) \
    { menu { "on" "off" } { ON OFF } }

  set typedef(_mwseqnres_option) \
    { menu  { "molecular weight"  "sequence file" "number of residues" } { "MW"  "FASTA" "NRES"} }

  set typedef(_protocol) \
    { menu  { "default"  "none (fix)"  "custom" "all (ref)"} { "DEFAULT" "OFF" "CUSTOM" "ALL"} }

  set typedef(_hyss_search) \
    { menu  { "fast"  "full"} { "FAST" "FULL"} }

  set typedef(_mtz_label_fo)      { mtz_label {F} Unassigned H }


  return 1
  }

#------------------------------------------------------------------------
proc phaser_EP_run { arrayname } {
#------------------------------------------------------------------------

  upvar #0 $arrayname array

  set array(RUNHYSS) 0
  set array(RUNSHELXD) 0

  if { ([GetValue $arrayname RUNBUCCANEER] == "1") || [GetValue $arrayname EP_SAMR] == "1"}  {
    if { ($array(FPwrk) == "Unassigned")} {
       WarningMessage "F mtz column is Unassigned"
       return 0
    }
    if { ($array(SIGFPwrk) == "Unassigned")} {
       WarningMessage "SIGF mtz column is Unassigned"
       return 0
    }
    if { ($array(FREER) == "Unassigned")} {
       WarningMessage "Free R flag mtz column is Unassigned"
       return 0
    }
  }

  if { [GetValue $arrayname EP_SAMR] == "0"}  {
    if { ($array(Fp_SAD) == "Unassigned") || ($array(Fn_SAD) == "Unassigned") } {
       WarningMessage "F mtz column is Unassigned"
       return 0
    }
    if { ($array(SIGFp_SAD) == "Unassigned") || ($array(SIGFn_SAD) == "Unassigned") } {
       WarningMessage "SIGF mtz column is Unassigned"
       return 0
    }
  }

  if { [GetValue $arrayname EP_MODE] == "SAD" && [GetValue $arrayname HA_SITES_OPTION_SAD] == "HYSS" } {
     set array(RUNHYSS) 1
     if { ![file exists [FindExecutable phenix.hyss]] } {
       WarningMessage "phenix.hyss not installed"
        return 0
    } }
#puts "$array(RUNHYSS)"

  if { [GetValue $arrayname EP_MODE] == "SAD" && [GetValue $arrayname HA_SITES_OPTION_SAD]  == "SHELXD" } {
     set array(RUNSHELXD) 1
     if { ![file exists [FindExecutable shelxd]] } {
       WarningMessage "shelxd not installed"
        return 0
    }
     if { ![file exists [FindExecutable shelxc]] } {
       WarningMessage "shelxc not installed"
        return 0
    } }

#Define data

  if { $array(HKLIN) == "" } {
     WarningMessage "NOT SET: mtz reflection data file"
     return 0
  }

  if { ($array(WAVELENGTH) == 0) } {
     WarningMessage "NOT SET: Wavelength must be greater than zero"
     return 0
  }

  if { ([GetValue $arrayname TOG_SCAT_MEASURED] == "1") } {
    if { ([GetValue $arrayname SCAT_TYPE] == "")} {
       WarningMessage "NOT SET: scattering type for fluorescence scan"
       return 0
     }
    if { ([GetValue $arrayname SCAT_FP] == "")} {
       WarningMessage "NOT SET: f\' value for fluorescence scan"
       return 0
     }
    if { ([GetValue $arrayname SCAT_FDP] == "")} {
       WarningMessage "NOT SET: f\" value for fluorescence scan"
       return 0
     } }


#Define Atoms

  if { ([GetValue $arrayname EP_MODE] == "SAD") } {
  if { ([GetValue $arrayname HA_SITES_OPTION_SAD] == "MANUAL") } {
  for { set n 1 } { $n <= $array(N_HA_SAD) } { incr n } {
    if { $array(HA_ATOM_TYPE_SAD,$n) == "" } {
       WarningMessage "NOT SET: atom type or cluster name for site # $n"
       return 0
     }
    if { ($array(HA_ATOM_X_SAD,$n) == "")
      || ($array(HA_ATOM_Y_SAD,$n) == "")
      || ($array(HA_ATOM_Z_SAD,$n) == "") } {
       WarningMessage "NOT SET: coordinates for site # $n"
       return 0
     }
    if { $array(HA_ATOM_O_SAD,$n) == "" } {
       WarningMessage "NOT SET: occupancy for site # $n"
       return 0
     } } } }

  if { ([GetValue $arrayname EP_MODE] == "MRSAD") } {
  if { ([GetValue $arrayname HA_SITES_OPTION_MRSAD] == "MANUAL") } {
  for { set n 1 } { $n <= $array(N_HA_MRSAD) } { incr n } {
    if { $array(HA_ATOM_TYPE_MRSAD,$n) == "" } {
       WarningMessage "NOT SET: atom type or cluster name for site # $n"
       return 0
     }
    if { ($array(HA_ATOM_X_MRSAD,$n) == "")
      || ($array(HA_ATOM_Y_MRSAD,$n) == "")
      || ($array(HA_ATOM_Z_MRSAD,$n) == "") } {
       WarningMessage "NOT SET: coordinates for site # $n"
       return 0
     }
    if { $array(HA_ATOM_O_MRSAD,$n) == "" } {
       WarningMessage "NOT SET: occupancy for site # $n"
       return 0
     } } } }

  if { ([GetValue $arrayname EP_MODE] == "SAD") } {
  if { ([GetValue $arrayname HA_SITES_OPTION_SAD] == "HA") } {
    if { $array(HA_FILE_HA_SAD) == "" } {
       WarningMessage "NOT SET: HA file for sites"
       return 0
     } }
  if { ([GetValue $arrayname HA_SITES_OPTION_SAD] == "PDB") } {
    if { $array(HA_FILE_PDB_SAD) == "" } {
       WarningMessage "NOT SET: PDB file for sites"
       return 0
     } }
  if { ([GetValue $arrayname HA_SITES_OPTION_SAD] == "SOL") } {
    if { $array(HA_FILE_SOL_SAD) == "" } {
       WarningMessage "NOT SET: SOL file for sites"
       return 0
     } } }

  if { ([GetValue $arrayname EP_MODE] == "MRSAD") } {
  if { ([GetValue $arrayname TOG_ADDITIONAL_ATOMS] == "1") } {
  if { ([GetValue $arrayname HA_SITES_OPTION_MRSAD] == "HA") } {
    if { $array(HA_FILE_HA_SAD) == "" } {
       WarningMessage "NOT SET: HA file for sites"
       return 0
     } }
  if { ([GetValue $arrayname HA_SITES_OPTION_MRSAD] == "PDB") } {
    if { $array(HA_FILE_PDB_SAD) == "" } {
       WarningMessage "NOT SET: PDB file for sites"
       return 0
     } }
  if { ([GetValue $arrayname HA_SITES_OPTION_MRSAD] == "SOL") } {
    if { $array(HA_FILE_SOL_SAD) == "" } {
       WarningMessage "NOT SET: SOL file for sites"
       return 0
     } }
     } }

#--- shelx checks
 
  if { ([GetValue $arrayname EP_MODE] == "SAD")} { 
    if { ([GetValue $arrayname RUNSHELXD] == "1")} { 
    if { ([GetValue $arrayname HYSS_TYPE] == "")} { 
     WarningMessage "NOT SET: ShelxD atom type"
     return 0
  } } }

  if { ([GetValue $arrayname EP_MODE] == "SAD")} { 
    if { ([GetValue $arrayname RUNSHELXD] == "1")} { 
    if { ([GetValue $arrayname N_HYSS] == "")} { 
     WarningMessage "NOT SET: Number of sites to find"
     return 0
  } } } 

  if { ([GetValue $arrayname EP_MODE] == "SAD")} { 
    if { ([GetValue $arrayname RUNHYSS] == "1")} { 
    if { ([GetValue $arrayname N_HYSS] == "")} { 
     WarningMessage "NOT SET: Number of sites to find"
     return 0
    }
    if { ([GetValue $arrayname HYSS_TYPE] == "")} { 
     WarningMessage "NOT SET: Atom type for hyss"
     return 0
    }
  } } 

#Define atoms ----partial structure checks

  if { ([GetValue $arrayname EP_MODE] == "MRSAD") } {
    if { ([GetValue $arrayname PART_PDB_MTZ] == "PDB")} {
    if { ([GetValue $arrayname PARTPDB] == "")} {
     WarningMessage "NOT SET: Partial PDB file"
     return 0
  } }
    if { ([GetValue $arrayname PART_PDB_MTZ] == "MTZ")} {
    if { ([GetValue $arrayname PARTMTZ] == "")} {
     WarningMessage "NOT SET: Partial MTZ file"
     return 0
  } }
    if { ([GetValue $arrayname PARTIAL_RMSID_OPTION] == "IDENT")} {
    if { ([GetValue $arrayname PARTIAL_RMSID] == "")} {
     WarningMessage "NOT SET: sequence identity for the partial structure"
     return 0
  } }
    if { ([GetValue $arrayname PARTIAL_RMSID_OPTION] == "RMS")} {
    if { ([GetValue $arrayname PARTIAL_RMSID] == "")} {
     WarningMessage "NOT SET: rms difference for the partial structure"
     return 0
  } } }
 
#----Cluster checks
  if { ([GetValue $arrayname EP_MODE] == "SAD") } {
  if { ([GetValue $arrayname TOG_CLUSTER] == "1") } {
  if { ([GetValue $arrayname CLUSTER_FILE_PDB] == "") } {
     WarningMessage "NOT SET: Cluster PDB file"
     return 0
  } } }

  if { ([GetValue $arrayname EP_MODE] == "MRSAD") } {
  if { ([GetValue $arrayname TOG_CLUSTER_MR] == "1") } {
  if { ([GetValue $arrayname CLUSTER_FILE_PDB_MR] == "") } {
     WarningMessage "NOT SET: Cluster PDB file"
     return 0
  } } }
 
#Define atoms ---- LLG completion checks

  if { ([GetValue $arrayname TOG_LLGC_SAD] == "1") } {
  if { ([GetValue $arrayname LLGC_COMPLETE_SAD] == "ON") } {
  if { ([GetValue $arrayname EP_MODE] == "MRSAD") } {
     if { ([GetValue $arrayname TOG_LLGC_SAD_ATOM] == "0") &&
          ([GetValue $arrayname TOG_LLGC_SAD_ANOM] == "0") && 
          ([GetValue $arrayname TOG_LLGC_SAD_REAL] == "0") } {
     WarningMessage "NOT SET: Completion method"
     return 0
  } } } } 

  if { ([GetValue $arrayname TOG_LLGC_SAD] == "1") } {
  if { ([GetValue $arrayname LLGC_COMPLETE_SAD] == "ON") } {
  if { ([GetValue $arrayname TOG_LLGC_SAD_ATOM] == "1") } {
  if { ([GetValue $arrayname LLGC_FIRST_TYPE] == "") } {
     WarningMessage "NOT SET: Completion atom type (array empty)"
     return 0
  }
  for { set n 1 } { $n <= $array(N_LLGC) } { incr n } {
    if { ($array(LLGC_TYPE,$n) == "") } {
     WarningMessage "NOT SET: Completion atom type"
     return 0
  } } } } }

#Hyss and Shelx folder
 
  if { ([GetValue $arrayname HA_SITES_OPTION_SAD] == "HYSS") } {
  if { ([GetValue $arrayname TOG_HYSS_SOLVENT] == "1") } {
     if { ([GetValue $arrayname SCATTERING_SOLVENT] == "") } {
     WarningMessage "NOT SET: solvent content in for phenix.hyss"
     return 0
  } } }

  if { ([GetValue $arrayname HA_SITES_OPTION_SAD] == "SHELXD") } {
    if { ([GetValue $arrayname TOG_NTRY] == "1") && ([GetValue $arrayname NTRY] == "") } {
       WarningMessage "NOT SET: Number of trys for SHELXD"
       return 0
    } 
  }

  if { ([GetValue $arrayname HA_SITES_OPTION_SAD] == "HYSS") || ([GetValue $arrayname HA_SITES_OPTION_SAD] == "SHELXD") } {
    if { ([GetValue $arrayname TOG_MIND] == "1") && ([GetValue $arrayname MIND] == "") } {
      WarningMessage "NOT SET: minimum distance between heavy atoms"
      return 0
    }
    if { ([GetValue $arrayname TOG_SHELXC_RESO] == "1") && ([GetValue $arrayname MIN_RESO] == "") } {
      WarningMessage "NOT SET: resolution for heavy atom search"
      return 0
    }
    if { ([GetValue $arrayname TOG_SHELXC_RESO] == "1") && ([GetValue $arrayname MAX_RESO] == "") } {
      WarningMessage "NOT SET: resolution for heavy atom search"
      return 0
  } }

# Composition of the ASU
 
  if { ([GetValue $arrayname SCATTERING] == "ASU") } {
  for { set n 1 } { $n <= $array(N_COMPONENT) } { incr n } {
    if { $array(COMP_OPTION,$n) == "sequence file" &&  $array(COMP_FILE,$n) == "" } {
       WarningMessage "NOT SET: sequence file for component # $n"
       return 0
     }
    if { $array(COMP_OPTION,$n) == "molecular weight" &&  $array(MW,$n) == "" } {
       WarningMessage "NOT SET: molecular weight for component # $n"
       return 0
     } } }

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

  if { ([GetValue $arrayname SCATTERING] == "COMPONENT") } {
  for { set n 1 } { $n <= $array(N_COMPONENT) } { incr n } {
    if { $array(COMP_OPTION,$n) == "sequence file" &&  $array(COMP_FILE,$n) == "" } {
       WarningMessage "NOT SET: sequence file for component # $n"
       return 0
     }
    if { $array(COMP_OPTION,$n) == "molecular weight" &&  $array(MW,$n) == "" } {
       WarningMessage "NOT SET: molecular weight for component # $n"
       return 0
     } } }


# Accessory Parameters

  if { ([GetValue $arrayname TOG_SCAT_RESTRAIN] == "1") } {
     if { ([GetValue $arrayname SCAT_RESTRAIN] == "ON") } {
     if { ([GetValue $arrayname SCAT_SIGMA] == "") } {
     WarningMessage "NOT SET: No Sigma for scattering restraint"
    } } }
 
# Files 

  set array(INPUT_FILES) "HKLIN"

  if {([GetValue $arrayname EP_MODE] == "SAD") } {
  if {([GetValue $arrayname HA_SITES_OPTION_SAD] == "HA") &&  ([GetValue $arrayname HA_FILE_HA_SAD] != "") } {
    append array(INPUT_FILES) " HA_FILE_HA_SAD"
  }
  if {([GetValue $arrayname HA_SITES_OPTION_SAD] == "SOL") &&  ([GetValue $arrayname HA_FILE_SOL_SAD] != "") } {
    append array(INPUT_FILES) " HA_FILE_SOL_SAD"
  }
  if {([GetValue $arrayname HA_SITES_OPTION_SAD] == "PDB") && ([GetValue $arrayname HA_FILE_PDB_SAD] != "") } {
    append array(INPUT_FILES) " HA_FILE_PDB_SAD"
  } 
  if { ([GetValue $arrayname TOG_CLUSTER] == "1") && ([GetValue $arrayname CLUSTER_FILE_PDB] != "") } {
    append array(INPUT_FILES) " CLUSTER_FILE_PDB"
  } }

  if {([GetValue $arrayname EP_MODE] == "MRSAD") } {
  if {([GetValue $arrayname PART_PDB_MTZ] == "PDB") &&  ([GetValue $arrayname PARTPDB] != "") } {
    append array(INPUT_FILES) " PARTPDB"
  }
  if {([GetValue $arrayname PART_PDB_MTZ] == "MTZ") &&  ([GetValue $arrayname PARTMTZ] != "") } {
    append array(INPUT_FILES) " PARTMTZ"
  }
  if {([GetValue $arrayname HA_SITES_OPTION_MRSAD] == "HA") &&  ([GetValue $arrayname HA_FILE_HA_SAD] != "") } {
    append array(INPUT_FILES) " HA_FILE_HA_SAD"
  }
  if {([GetValue $arrayname HA_SITES_OPTION_MRSAD] == "SOL") &&  ([GetValue $arrayname HA_FILE_SOL_SAD] != "") } {
    append array(INPUT_FILES) " HA_FILE_SOL_SAD"
  }
  if {([GetValue $arrayname HA_SITES_OPTION_MRSAD] == "PDB") && ([GetValue $arrayname HA_FILE_PDB_SAD] != "") } {
    append array(INPUT_FILES) " HA_FILE_PDB_SAD"
  } 
  if { ([GetValue $arrayname TOG_CLUSTER_MR] == "1") && ([GetValue $arrayname CLUSTER_FILE_PDB_MR] == "") } {
    append array(INPUT_FILES) " CLUSTER_FILE_PDB_MR"
  } }

  if { ([GetValue $arrayname SCATTERING] == "COMPONENT") } {
  for { set n 1 } { $n <= $array(N_COMPONENT) } { incr n } {
    if { $array(COMP_OPTION,$n) == "sequence file" } {
        append array(INPUT_FILES) " COMP_FILE,$n"
     } } }

  if { ![SetHarvestParams $arrayname HKLIN  -run] } { return 0 }

  if { ([GetValue $arrayname RUNBUCCANEER] == "1") || ([GetValue $arrayname RUNPARROT] == "1") }  {
    if { ([GetValue $arrayname SCATTERING] != "COMPONENT") } {
      WarningMessage "NOT SET: sequence file for parrot/buccaneer\nEnter sequence"
      return 0
  }   
  }   

  if { ([GetValue $arrayname RUNBUCCANEER] == "1") || ([GetValue $arrayname RUNPARROT] == "1") }  {
    if { ($array(COMP_OPTION,1) != "sequence file")} {
       WarningMessage "NOT SET: sequence file for parrot/buccaneer\nEnter composition by sequence"
       return 0
    }
    if { ($array(COMP_FILE,1) == "") } {
      WarningMessage "NOT SET: sequence file for parrot/buccaneer\nEnter sequence"
      return 0
    }
  }

# All output files with the user specified root will be saved to the project dir
  return 1
  }

#------------------------------------------------------------------------
 proc phaser_EP_component { arrayname counter_component } {
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
      label "Component #$counter_component" \
      widget PROTDNA \
      message "Enter the file containing sequence in single letter code or fasta format" \
      label "" \
      widget COMP_OPTION -oblig \
      message "Enter the number of copies of component #$counter_component in the asu" \
      label "Number in asymmetric unit" \
      widget ASYM -oblig \
     toggle_display COMP_OPTION,$counter_component open FASTA hide

  CreateInputFileLine line \
      "Select the sequence file" "SEQ file" COMP_FILE DIR_COMP_FILE \
     -toggle_display COMP_OPTION,$counter_component open FASTA hide

  CreateLine line \
      message "Select for protein or DNA/RNA as a component of the asymmetric unit" \
      label "Component #$counter_component" \
      widget PROTDNA \
      message "Enter the number of residues of protein/nucleic acid #$counter_component" \
      label "" \
      widget COMP_OPTION -oblig \
      widget COMP_NRES -oblig \
      message "Enter the number of copies of component #$counter_component in the asymmetric unit" \
      label "Number in asymmetric unit" \
      widget ASYM -oblig \
     toggle_display COMP_OPTION,$counter_component open NRES hide

  }

#------------------------------------------------------------------------
 proc phaser_EP_atomsearch { arrayname } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array
  if { [GetValue $arrayname ATOMSEARCH] == "SHELXD" && [GetValue $arrayname TOG_ATOMSEARCH] == "1" } {
     set array(HA_SITES_OPTION_SAD) "run ShelxC/D" 
  } elseif { [GetValue $arrayname ATOMSEARCH] == "HYSS" && [GetValue $arrayname TOG_ATOMSEARCH] == "1" } {
     set array(HA_SITES_OPTION_SAD) "run phenix.hyss" 
  } elseif { [GetValue $arrayname TOG_ATOMSEARCH] == "0" } {
     set array(HA_SITES_OPTION_SAD) "in PDB file" 
  }

  if { [GetValue $arrayname HYSS_INSTALLED] == "1"  && \
       [GetValue $arrayname ATOMSEARCH] == "HYSS" && \
       [GetValue $arrayname EP_MODE] == "SAD" } {
     set array(SHOW_HYSS) 1
  } else {
     set array(SHOW_HYSS) 0
  }

  if { [GetValue $arrayname SHELXD_INSTALLED] == "1"  && \
       [GetValue $arrayname ATOMSEARCH] == "SHELXD" && \
       [GetValue $arrayname EP_MODE] == "SAD" } {
     set array(SHOW_SHELX) 1
  } else {
     set array(SHOW_SHELX) 0
  }

}

#------------------------------------------------------------------------
 proc phaser_EP_updatevarlabel { arrayname FILE_SPACEGROUP } {
#------------------------------------------------------------------------
# procedure to update the FILE_SPACEGROUP varlabel
  upvar #0 $arrayname array
  set field_list [GetWidget $arrayname FILE_SPACEGROUP]
  foreach field $field_list {
    if { [winfo exists $field] } { $field configure -text $array(FILE_SPACEGROUP) } }
  }

#---------------------------------------------------------------------
proc phaser_EP_dwave { arrayname } {
#---------------------------------------------------------------------
# 
  # Get cell information based on HKLIN and F label
  upvar \#0 $arrayname array

  # Acquire actual values of task parameters
  set filen [GetFullFileName0 $arrayname HKLIN]
  set label [GetValue $arrayname "Fp_SAD"]

  # Extract xtal and dataset names, given filename and a column name
  if { ![GetMtzDatasetFromLabel $filen $label xtal dataset] } {
      return 0
  }

  # Get crystal cell for the specific crystal/dataset
  if { ![GetMtzParamFromDataset $filen $xtal $dataset DWAVES dwave] }  {
      return 0
  }
  
  set array(WAVELENGTH) $dwave
  set_field_colour $arrayname WAVELENGTH 1

  return
}

#------------------------------------------------------------------------
 proc phaser_EP_ha {  arrayname counter_a } {
#------------------------------------------------------------------------
# Procedure to define a anomalous atom site manually
  upvar #0 $arrayname array

  CreateLine line \
      message "Add new atom site manually" \
      widget HA_ATOM_TYPE_SAD -oblig -width 30 \
      widget HA_ATOM_FRAC_SAD \
      widget HA_ATOM_X_SAD -oblig \
      widget HA_ATOM_Y_SAD -oblig \
      widget HA_ATOM_Z_SAD -oblig \
      widget HA_ATOM_O_SAD -oblig \
      widget HA_ATOM_B_SAD 
  }

#------------------------------------------------------------------------
 proc phaser_EP_hamr {  arrayname counter_a } {
#------------------------------------------------------------------------
# Procedure to define a anomalous atom site manually
  upvar #0 $arrayname array

  CreateLine line \
      message "Add new atom site manually" \
      widget HA_ATOM_TYPE_MRSAD -oblig -width 30 \
      widget HA_ATOM_FRAC_MRSAD \
      widget HA_ATOM_X_MRSAD -oblig \
      widget HA_ATOM_Y_MRSAD -oblig \
      widget HA_ATOM_Z_MRSAD -oblig \
      widget HA_ATOM_O_MRSAD -oblig \
      widget HA_ATOM_B_MRSAD 
  }

#------------------------------------------------------------------------
 proc phaser_EP_llgc {  arrayname counter_f } {
#------------------------------------------------------------------------
# Procedure to define a scattering for  atom manually
  upvar #0 $arrayname array
  CreateLineTemplate BB { 0 0.2 0.45 }
  CreateLine line \
      message "Atomtypes for LLG-maps" \
      label "" label "or with atom type" \
      widget LLGC_TYPE \
         -command "phaser_EP_llgc_sad_toggle_update $arrayname " \
      format template BB
  }
#------------------------------------------------------------------------
  proc phaser_EP_maca { arrayname counter_s } {
#------------------------------------------------------------------------
  global configure
  upvar #0 $arrayname array
  CreateLine line \
      label "Refine: Anisotropic" \
      widget MACA_ANIS \
      label "Bins" \
      widget MACA_BINS \
      label "SolK" \
      widget MACA_SOLK \
      label "SolB" \
      widget MACA_SOLB \
      label "Number of Cycles" \
      widget MACA_NCYC
  }

#------------------------------------------------------------------------
  proc phaser_EP_macs { arrayname counter_s } {
#------------------------------------------------------------------------
  global configure
  upvar #0 $arrayname array

  CreateLine line \
      message "Overall Occupancy Scale" \
      widget TOG_MACSAD_K \
      message "Overall B-factor" \
      widget TOG_MACSAD_B \
      message "Overall Sigma Scale" \
      widget TOG_MACSAD_SIGMA \
      message "Atom positions" \
      widget TOG_MACSAD_XYZ \
      message "Atom occupancy" \
      widget TOG_MACSAD_OCC \
      message "Atom B-factor" \
      widget TOG_MACSAD_BFAC \
      message "Atom F double prime" \
      widget TOG_MACSAD_FDP \
      message "Variance Real part of D-phi" \
      widget TOG_MACSAD_SA \
      message "Variance Imaginary part of D-phi" \
      widget TOG_MACSAD_SB \
      message "Variance Sigma-Plus" \
      widget TOG_MACSAD_SP \
      message "Variance Sigma-Delta" \
      widget TOG_MACSAD_SD \
      message "Number of Cycles" \
      widget MACSAD_NCYCL \
      format template MACSAD_TEMPLATE
  }
#------------------------------------------------------------------------
  proc phaser_EP_macs_part { arrayname counter_s } {
#------------------------------------------------------------------------
  global configure
  upvar #0 $arrayname array

  CreateLine line \
      message "Overall Occupancy Scale" \
      widget TOG_MACSAD_K \
      message "Overall B-factor" \
      widget TOG_MACSAD_B \
      message "Overall Sigma Scale" \
      widget TOG_MACSAD_SIGMA \
      message "Atom positions" \
      widget TOG_MACSAD_XYZ \
      message "Atom occupancy" \
      widget TOG_MACSAD_OCC \
      message "Atom B-factor" \
      widget TOG_MACSAD_BFAC \
      message "Atom F double prime" \
      widget TOG_MACSAD_FDP \
      message "Variance Real part of D-phi" \
      widget TOG_MACSAD_SA \
      message "Variance Imaginary part of D-phi" \
      widget TOG_MACSAD_SB \
      message "Variance Sigma-Plus" \
      widget TOG_MACSAD_SP \
      message "Variance Sigma-Delta" \
      widget TOG_MACSAD_SD \
      message "Partial Structure Scale" \
      widget TOG_MACSAD_PK \
      message "Partial Structure B-factor" \
      widget TOG_MACSAD_PB \
      message "Number of Cycles" \
      widget MACSAD_NCYCL \
      format template MACSAD_PART_TEMPLATE
  }

#------------------------------------------------------------------------
 proc phaser_EP_show_labin_F { arrayname } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(LABIN_F) 0
  if { [GetValue $arrayname RUNBUCCANEER] == "1" || [GetValue $arrayname EP_SAMR] == "1" } {
     set array(LABIN_F) 1
  }
  }
#------------------------------------------------------------------------
 proc phaser_EP_mode_update { arrayname } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [GetValue $arrayname EP_MODE] == "SAD" } {
     set array(TOG_ADDITIONAL_ATOMS) 0
  } elseif { [GetValue $arrayname EP_MODE] == "MRSAD" && [GetValue $arrayname TOG_ADDITIONAL_ATOMS_BAK] == "1"} {
     set array(TOG_ADDITIONAL_ATOMS) 1
  } elseif { [GetValue $arrayname EP_MODE] == "MRSAD" && [GetValue $arrayname TOG_ADDITIONAL_ATOMS_BAK] == "0"} {
     set array(TOG_ADDITIONAL_ATOMS) 0
  }


  if { [GetValue $arrayname EP_MODE] == "SAD" && [GetValue $arrayname TOG_LLGC_SAD] == "0" } {
     set array(LLGC_COMPLETE_SAD) "on: all atom types"
  } elseif { [GetValue $arrayname EP_MODE] == "MRSAD" && [GetValue $arrayname TOG_LLGC_SAD] == "0" } {
     set array(LLGC_COMPLETE_SAD) "on: select atom types"
  }

  if { [GetValue $arrayname HYSS_INSTALLED] == "1"  && \
       [GetValue $arrayname HA_SITES_OPTION_SAD] == "HYSS" && \
       [GetValue $arrayname EP_MODE] == "SAD" } {
     set array(SHOW_HYSS) 1
  } else {
     set array(SHOW_HYSS) 0
  }

  if { [GetValue $arrayname SHELXD_INSTALLED] == "1"  && \
       [GetValue $arrayname HA_SITES_OPTION_SAD] == "SHELXD" && \
       [GetValue $arrayname EP_MODE] == "SAD" } {
     set array(SHOW_SHELX) 1
  } else {
     set array(SHOW_SHELX) 0
  }

  if { [GetValue $arrayname HA_SITES_OPTION_SAD] == "HYSS" } {
     set array(TOG_ATOMSEARCH) 1
     set array(ATOMSEARCH) "HYSS"
  } elseif { [GetValue $arrayname HA_SITES_OPTION_SAD] == "SHELXD" } {
     set array(TOG_ATOMSEARCH) 1
     set array(ATOMSEARCH) "SHELXD"
  } else {
     set array(TOG_ATOMSEARCH) 0
  }
  
  }

#------------------------------------------------------------------------
 proc phaser_EP_atom_toggle_update { arrayname } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [GetValue $arrayname TOG_ADDITIONAL_ATOMS] == "1"} {
     set array(TOG_ADDITIONAL_ATOMS_BAK) 1
  } elseif { [GetValue $arrayname TOG_ADDITIONAL_ATOMS] == "0"} {
     set array(TOG_ADDITIONAL_ATOMS_BAK) 0
  }

  if { [GetValue $arrayname HYSS_INSTALLED] == "1"  && \
       [GetValue $arrayname HA_SITES_OPTION_SAD] == "HYSS" && \
       [GetValue $arrayname EP_MODE] == "SAD" } {
     set array(SHOW_HYSS) 1
  } else {
     set array(SHOW_HYSS) 0
  }
  
  if { [GetValue $arrayname SHELXD_INSTALLED] == "1"  && \
       [GetValue $arrayname HA_SITES_OPTION_SAD] == "SHELXD" && \
       [GetValue $arrayname EP_MODE] == "SAD" } {
     set array(SHOW_SHELX) 1
  } else {
     set array(SHOW_SHELX) 0
  }

  if { [GetValue $arrayname HA_SITES_OPTION_SAD] == "HYSS" && [GetValue $arrayname HYSS_INSTALLED] == "1" } {
     set array(TOG_ATOMSEARCH) 1
     set array(ATOMSEARCH) HYSS
  } elseif { [GetValue $arrayname HA_SITES_OPTION_SAD] == "SHELXD" && [GetValue $arrayname SHELXD_INSTALLED] == "1" } {
     set array(TOG_ATOMSEARCH) 1
     set array(ATOMSEARCH) SHELXD
  } else {
     set array(TOG_ATOMSEARCH) 0
  }
  
  }

#------------------------------------------------------------------------
 proc phaser_EP_reso_toggle_update { arrayname } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(TOG_RESOLUTION) 1
  if { [GetValue $arrayname RESOLUTION_DMAX] == ""} {
     set array(TOG_RESOLUTION) 0
  }
  if { [GetValue $arrayname RESOLUTION_DMIN] == ""} {
     set array(TOG_RESOLUTION) 0
  }

  }

#------------------------------------------------------------------------
 proc phaser_EP_llgc_toggle_update { arrayname } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [GetValue $arrayname TOG_LLGC_SAD] == "0"  } {
     set array(TOG_LLGC_SAD_ATOM) 0
     set array(TOG_LLGC_SAD_ANOM) 0
     set array(TOG_LLGC_SAD_REAL) 0
  }
  }

#------------------------------------------------------------------------
 proc phaser_EP_llgc_sad_toggle_update { arrayname } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(TOG_LLGC_SAD) 0
  if { [GetValue $arrayname TOG_LLGC_SAD_ATOM] == "1"  } {
     set array(TOG_LLGC_SAD) 1
  }
  if { [GetValue $arrayname TOG_LLGC_SAD_REAL] == "1"  } {
     set array(TOG_LLGC_SAD) 1
  }
  if { [GetValue $arrayname TOG_LLGC_SAD_ANOM] == "1"  } {
     set array(TOG_LLGC_SAD) 1
  }
  for { set n 1 } { $n <= $array(N_LLGC) } { incr n } {
    if { !($array(LLGC_TYPE,$n) == "") } {
     set array(TOG_LLGC_SAD) 1
     set array(TOG_LLGC_SAD_ATOM) 1
  }
  }
  }

#------------------------------------------------------------------------
  proc phaser_EP_task_window {arrayname} {
#------------------------------------------------------------------------
  upvar #0 $arrayname array
  global configure


  if { [CreateTaskWindow $arrayname \
        "Maximum Likelihood Experimental Phasing"\
        "Phaser" \
        [ list "Define data" \
               "Define atoms" \
               "phenix.hyss parameters" \
               "Shelx parameters" \
               "Composition of the asymmetric unit" \
               "Accessory parameters" \
               "Output control" \
               "Expert parameters" ] \
       ] == 0 } return

  SetHarvestParams $arrayname HKLIN -init

  if { ![file exists [FindExecutable phenix.hyss]] } { set array(HYSS_INSTALLED) "0" }
  if { ![file exists [FindExecutable mtz2sca]] } { set array(SHELXD_INSTALLED) "0" }
  if { ![file exists [FindExecutable shelxc]] } { set array(SHELXD_INSTALLED) "0" }
  if { ![file exists [FindExecutable shelxd]] } { set array(SHELXD_INSTALLED) "0" }
  if { ![file exists [FindExecutable shelxd]] && ![file exists [FindExecutable phenix.hyss]] } {
    set array(ATOMSEARCH_INSTALLED) "0"
  }
  if { ![file exists [FindExecutable shelxd]] || ![file exists [FindExecutable phenix.hyss]] } {
    set array(ATOMSEARCH_BOTH_INSTALLED) "0"
  }
  
  if { [GetValue $arrayname SHELXD_INSTALLED] == "1" && [GetValue $arrayname HYSS_INSTALLED] == "0" } {
     set array(ATOMSEARCH) "SHELXD"
  }
  if { [GetValue $arrayname SHELXD_INSTALLED] == "0" && [GetValue $arrayname HYSS_INSTALLED] == "1" } {
     set array(ATOMSEARCH) "HYSS"
  }

  if {  [GetValue $arrayname ATOMSEARCH_INSTALLED] == "1" && \
        [GetValue $arrayname TOG_ATOMSEARCH] == "1" &&  \
        [GetValue $arrayname SHELXD_INSTALLED] == "1" && \
        [GetValue $arrayname ATOMSEARCH] == "SHELXD"  } {
        set array(HA_SITES_OPTION_SAD) "run ShelxC/D"
        }
  if {  [GetValue $arrayname ATOMSEARCH_INSTALLED] == "1" && \
        [GetValue $arrayname TOG_ATOMSEARCH] == "1" &&  \
        [GetValue $arrayname HYSS_INSTALLED] == "1" && \
        [GetValue $arrayname ATOMSEARCH] == "HYSS"  } {
        set array(HA_SITES_OPTION_SAD) "run phenix.hyss" 
        }

  if { [GetValue $arrayname HYSS_INSTALLED] == "1"  && \
       [GetValue $arrayname HA_SITES_OPTION_SAD] == "HYSS" && \
       [GetValue $arrayname EP_MODE] == "SAD" } {
     set array(SHOW_HYSS) 1
  } else {
     set array(SHOW_HYSS) 0
  }

  if { [GetValue $arrayname SHELXD_INSTALLED] == "1"  && \
       [GetValue $arrayname HA_SITES_OPTION_SAD] == "SHELXD" && \
       [GetValue $arrayname EP_MODE] == "SAD" } {
     set array(SHOW_SHELX) 1
  } else {
     set array(SHOW_SHELX) 0
  }

# SetProgramHelpFile phaser

#=PROTOCOL===============================================================

  OpenFolder protocol

  CreateTitleLine line TITLE

  CreateLine line \
      label "Mode for experimental phasing" \
      widget EP_MODE \
         -command "phaser_EP_mode_update $arrayname "

  CreateLine line \
     label "Phaser SAD pipeline" -italic

  OpenSubFrame frame -toggle_display EP_MODE open SAD hide MRSAD 

  OpenSubFrame frame -toggle_display ATOMSEARCH_INSTALLED open 1 hide 

  CreateLine line \
      message "Run Heavy Atom Location before Phaser SAD" \
      widget TOG_ATOMSEARCH -toggleon -width 4 \
      -command "phaser_EP_atomsearch $arrayname " \
      label "Run " \
      widget ATOMSEARCH  -command "phaser_EP_atomsearch $arrayname " \
      label " before Phaser" \
      toggle_display ATOMSEARCH_BOTH_INSTALLED open 1 hide

  OpenSubFrame frame -toggle_display ATOMSEARCH_BOTH_INSTALLED open 0 hide 

  CreateLine line \
      message "Run Heavy Atom Location before Phaser SAD" \
      widget TOG_ATOMSEARCH -toggleon -width 4 \
      -command "phaser_EP_atomsearch $arrayname " \
      label "Run " \
      widget ATOMSEARCH  -command "phaser_EP_atomsearch $arrayname " \
      label " before Phaser" \
      label " mtz2sca/shelxc/shelxd are not installed or path not set" -italic \
      toggle_display SHELXD_INSTALLED open 0 hide

  CreateLine line \
      message "Run Heavy Atom Location before Phaser SAD" \
      widget TOG_ATOMSEARCH -toggleon -width 4 \
      -command "phaser_EP_atomsearch $arrayname " \
      label "Run " \
      widget ATOMSEARCH  -command "phaser_EP_atomsearch $arrayname" \
      label " before Phaser" \
      label " phenix.hyss is not installed or path not set" -italic \
      toggle_display HYSS_INSTALLED open 0 hide

  CloseSubFrame
   
  CloseSubFrame

  CloseSubFrame

  CreateLine line \
      message "Run Density Modification and Model Building after Phaser  SAD" \
      widget RUNPARROT -width 4 \
      label "Run Parrot (density modification) after Phaser" \
      widget RUNBUCCANEER -width 4 \
      -command "phaser_EP_show_labin_F $arrayname" \
      label "Run Buccaneer (model building) after Parrot"



#========================================================================
# The "Define data" folder

  OpenFolder 1 

  CreateInputFileLine line \
      "Enter MTZ file name (HKLIN)" \
      "MTZ in " \
      HKLIN DIR_HKLIN \
        -setfileparam resolution_min RESOLUTION_DMAX \
        -setfileparam resolution_max RESOLUTION_DMIN \
        -setfileparam resolution_min MIN_RESO \
        -setfileparam resolution_max MAX_RESO \
        -setfileparam space_group_name FILE_SPACEGROUP \
        -setfileparam cell_1 CELL_1 \
        -setfileparam cell_2 CELL_2 \
        -setfileparam cell_3 CELL_3 \
        -setfileparam cell_4 CELL_4 \
        -setfileparam cell_5 CELL_5 \
        -setfileparam cell_6 CELL_6 \
        -setlabin Fp_SAD [list "*+*" ] \
        -setlabin SIGFp_SAD [list "*+*"] \
        -setlabin Fn_SAD [list "*-*"] \
        -setlabin SIGFn_SAD [list "*-*"] \
        -setlabin FPwrk {} \
        -setlabin SIGFPwrk [list SIGF "*SIG*"] \
        -setlabin FREE [list FREER FreeR FreeR_flag] \
        -command "UpdateHarvestMTZ $arrayname HKLIN" \
        -command "phaser_EP_dwave $arrayname"

  CreateHarvestLine line  -noharv

  OpenSubFrame frame -toggle_display EP_SAMR open 0 hide 

  CreateLabinLine line \
      "Select anomalous amplitude F+ and anomalous sigma SIGF+" \
      HKLIN "F(+)" Fp_SAD [list "*+*" ] \
      -sigma "SIGF(+)" SIGFp_SAD [list "*+*"] \
      -command "phaser_EP_dwave $arrayname"

  CreateLabinLine line \
      "Select anomalous amplitude F- and anomalous sigma SIGF-" \
      HKLIN "F(-)" Fn_SAD [list "*-*"] \
      -sigma "SIGF(-)" SIGFn_SAD [list "*-*"] 

  CloseSubFrame

  OpenSubFrame frame -toggle_display LABIN_F open 1 hide 
  
  CreateLabinLine line \
      "Observed amplitude (FP) and sigma (SIGFP)" \
      HKLIN "FP"  FPwrk {} \
      -sigma "SIGFP" SIGFPwrk [list SIGF "*SIG*"]

  CreateLabinLine line \
      "Free R flags" \
      HKLIN "FREER"  FREER {} \

  CloseSubFrame

  CreateLine line \
      message "Default is to take all data" \
      widget TOG_RESOLUTION \
      label "Resolution" widget RESOLUTION_DMAX -command "phaser_EP_reso_toggle_update $arrayname" \
      label "A to"  widget RESOLUTION_DMIN -command "phaser_EP_reso_toggle_update $arrayname" \
      label "A;      " \
      message "Wavelength of the SAD data" \
      label "Wavelength" \
      widget WAVELENGTH -oblig

  CreateLine line \
      message "Space group read from mtz file." \
      label "Space group read from mtz file" \
      varlabel FILE_SPACEGROUP \
      toggle_display EP_MODE open MRSAD hide SAD

  CreateLine line \
      message "Space group read from mtz file." \
      label "Space group read from mtz file" \
      varlabel FILE_SPACEGROUP \
      label ";" \
      message "Keep or change enantiomorph of input sites" \
      widget TOG_HAND_OPTION -toggleon label "Enantiomorph choice"  widget HAND_ONOFF \
      toggle_display EP_MODE open SAD hide MRSAD

  CreateLine line \
      widget TOG_SCAT_MEASURED \
      label "Enter scattering from fluorescence scan (default is to calculate f' and f\" from wavelength)"

  CreateLine line \
      message "Enter measured f' and f''" \
      label "type" widget SCAT_TYPE -oblig \
      label "FP ="  widget SCAT_FP  -oblig \
      label "FDP =" widget SCAT_FDP  -oblig \
      message "Phaser will determine if near edge" \
      label "Refine Fdp" widget SCAT_REF \
      toggle_display TOG_SCAT_MEASURED open 1 hide

#======================================================================== 
# The "Define atoms " folder

  OpenFolder 2 

  OpenSubFrame frame -toggle_display EP_MODE open MRSAD hide 

  CreateLine line \
      label "Partial structure input as" \
      widget PART_PDB_MTZ \
      label "file (real scattering only)"

  CreateInputFileLine line \
      "Select a PDB file for starting partial structure" \
      "PDB in " \
      PARTPDB DIR_PARTPDB \
      -toggle_display PART_PDB_MTZ open PDB hide

  CreateInputFileLine line \
      "Select a MTZ file for starting partial structure" \
      "MTZ in " \
      PARTMTZ DIR_PARTMTZ \
      -toggle_display PART_PDB_MTZ open MTZ hide

  CreateLine line \
      message "Specify RMS error in Angstrom, or \
               via the sequence identity (percentage or a fraction)" \
      label "Similarity of partial structure to the target structure" \
      widget PARTIAL_RMSID_OPTION \
      widget PARTIAL_RMSID -oblig \
      toggle_display EP_MODE open MRSAD hide

  CreateLine line \
      widget TOG_ADDITIONAL_ATOMS -command "phaser_EP_atom_toggle_update $arrayname" \
      label "Positions of (some) anomalous scatterers are known"

   CloseSubFrame

# Define the scattering atoms  long form=================
 
  OpenSubFrame frame -toggle_display EP_MODE open SAD hide 

  CreateLine line \
     message "Select how you wish to define the atom sites" \
     label "Atom sites" widget HA_SITES_OPTION_SAD -command "phaser_EP_mode_update $arrayname" \
     toggle_display HA_SITES_OPTION_SAD open [list PDB SOL HA MANUAL] hide

  OpenSubFrame frame -toggle_display HA_SITES_OPTION_SAD open HYSS hide

  CreateLine line \
     message "Select how you wish to define the atom sites" \
     label "Atom sites" widget HA_SITES_OPTION_SAD -command "phaser_EP_mode_update $arrayname" \
     toggle_display HYSS_INSTALLED open 1 hide

  CreateLine line \
     message "Select how you wish to define the atom sites" \
     label "Atom sites" widget HA_SITES_OPTION_SAD -command "phaser_EP_mode_update $arrayname" \
     label "phenix.hyss is not installed or path not set" -italic \
     toggle_display HYSS_INSTALLED open 0 hide

  CloseSubFrame

  OpenSubFrame frame -toggle_display HA_SITES_OPTION_SAD open SHELXD hide

  CreateLine line \
     message "Select how you wish to define the atom sites" \
     label "Atom sites" widget HA_SITES_OPTION_SAD -command "phaser_EP_atom_toggle_update $arrayname" \
     toggle_display SHELXD_INSTALLED open 1 hide

  CreateLine line \
     message "Select how you wish to define the atom sites" \
     label "Atom sites" widget HA_SITES_OPTION_SAD -command "phaser_EP_atom_toggle_update $arrayname" \
      label "mtz2sca/shelxc/shelxd are not installed or path not set" -italic \
     toggle_display SHELXD_INSTALLED open 0 hide

  CloseSubFrame

  CreateLine line \
     label "Find" widget N_HYSS -oblig \
     label "heavy atoms of type" widget HYSS_TYPE -oblig \
     toggle_display HA_SITES_OPTION_SAD open [list HYSS ] hide

  CreateLine line \
     label "Find" widget N_HYSS -oblig \
     label "heavy atoms of type " widget HYSS_TYPE -oblig \
     toggle_display HA_SITES_OPTION_SAD open [list SHELXD] hide

  CreateInputFileLine line \
      "Select the pdb file" "PDB in" HA_FILE_PDB_SAD DIR_HA_FILE_PDB_SAD \
      -toggle_display HA_SITES_OPTION_SAD open PDB hide 

  CreateInputFileLine line \
     "Select the heavy atom file" "HA  in"  HA_FILE_HA_SAD DIR_HA_FILE_HA_SAD \
     -toggle_display HA_SITES_OPTION_SAD open HA hide 

  CreateInputFileLine line \
      "Select the sol file" "SOL in" HA_FILE_SOL_SAD  DIR_HA_FILE_SOL_SAD \
      -toggle_display HA_SITES_OPTION_SAD open SOL hide 

  OpenSubFrame frame -toggle_display HA_SITES_OPTION_SAD open MANUAL hide 

  CreateLineTemplate HA { 0.0 0.37 0.56 0.65 0.74 0.83 0.92 }
  CreateLine line \
      label "Atom (or Cluster or Real/Anom)" label "Frac/Orth" label "X" label "Y" label "Z" label "O" label "B" \
      format template HA
  CreateExtendingFrame N_HA_SAD phaser_EP_ha \
      "Add another atom site" "Add another atom site" \
      [list HA_ATOM_TYPE_SAD HA_ATOM_FRAC_SAD HA_ATOM_X_SAD HA_ATOM_Y_SAD HA_ATOM_Z_SAD HA_ATOM_O_SAD HA_ATOM_B_SAD ] 

  CloseSubFrame

  OpenSubFrame frame -toggle_display HA_SITES_OPTION_SAD open [list SHELXD] hide

  CloseSubFrame

  CreateLine line \
      widget TOG_CLUSTER \
      label "Crystal contains cluster compound"
  
  OpenSubFrame frame -toggle_display TOG_CLUSTER open 1  hide

  CreateInputFileLine line \
      "Select the pdb file" "PDB in" CLUSTER_FILE_PDB DIR_CLUSTER_FILE_PDB

  CloseSubFrame

  CloseSubFrame

# define the scattering atoms short form (no hyss or shelxd) ============
 
  OpenSubFrame frame -toggle_display TOG_ADDITIONAL_ATOMS open 1 hide 

  CreateLine line \
     message "Select how you wish to define the atom sites" \
     label "Atom sites" widget HA_SITES_OPTION_MRSAD \
     toggle_display HA_SITES_OPTION_MRSAD open [list PDB SOL HA MANUAL] hide

  CreateInputFileLine line \
      "Select the pdb file" "PDB in" HA_FILE_PDB_SAD DIR_HA_FILE_PDB_SAD \
      -toggle_display HA_SITES_OPTION_MRSAD open PDB hide 

  CreateInputFileLine line \
     "Select the heavy atom file" "HA  in"  HA_FILE_HA_SAD DIR_HA_FILE_HA_SAD \
     -toggle_display HA_SITES_OPTION_MRSAD open HA hide 

  CreateInputFileLine line \
      "Select the sol file" "SOL in" HA_FILE_SOL_SAD  DIR_HA_FILE_SOL_SAD \
      -toggle_display HA_SITES_OPTION_MRSAD open SOL hide 

  OpenSubFrame frame -toggle_display HA_SITES_OPTION_MRSAD open MANUAL hide 

  CreateLineTemplate HASAD { 0.0 0.37 0.56 0.65 0.74 0.83 0.92 }
  CreateLine line \
      label "Atom (or Cluster or Real/Anom)" label "Frac/Orth" label "X" label "Y" label "Z" label "O" label "B" \
      format template HASAD
  CreateExtendingFrame N_HA_MRSAD phaser_EP_hamr \
      "Add another atom site" "Add another atom site" \
      [list HA_ATOM_TYPE_MRSAD HA_ATOM_FRAC_MRSAD HA_ATOM_X_MRSAD HA_ATOM_Y_MRSAD HA_ATOM_Z_MRSAD HA_ATOM_O_MRSAD HA_ATOM_B_MRSAD ] 

  CloseSubFrame

  CreateLine line \
      widget TOG_CLUSTER_MR \
      label "Crystal contains cluster compound (coordinates in pdb file below)"
  
  OpenSubFrame frame -toggle_display TOG_CLUSTER_MR open 1 hide

  CreateInputFileLine line \
      "Select the pdb file" "PDB in" CLUSTER_FILE_PDB_MR DIR_CLUSTER_FILE_PDB_MR

  CloseSubFrame

  CloseSubFrame

  CreateLine line \
      widget TOG_LLGC_SAD -toggleon -command "phaser_EP_llgc_toggle_update $arrayname" \
      label "LLG-map completion" \
      widget LLGC_COMPLETE_SAD
 
  CreateLine line \
     label "       " \
     widget TOG_LLGC_SAD_REAL -toggleon -command "phaser_EP_llgc_sad_toggle_update $arrayname" \
     label "Complete with purely real scatterer" \
     toggle_display LLGC_COMPLETE_SAD open ON hide

  CreateLine line \
     label "       " \
     widget TOG_LLGC_SAD_ANOM -toggleon -command "phaser_EP_llgc_sad_toggle_update $arrayname" \
     label "Complete with purely anomalous scatterer" \
     toggle_display LLGC_COMPLETE_SAD open ON hide

  CreateLine line \
     label "       " \
     widget TOG_LLGC_SAD_ATOM -toggleon -command "phaser_EP_llgc_sad_toggle_update $arrayname" \
     label "Complete with atom type     " \
     widget LLGC_FIRST_TYPE \
     toggle_display LLGC_COMPLETE_SAD open ON hide

  OpenSubFrame frame -toggle_display LLGC_COMPLETE_SAD open ON hide

  CreateExtendingFrame N_LLGC phaser_EP_llgc \
      "Add another atomtype" "Add another atomtype" \
      [list LLGC_TYPE ] 

  CloseSubFrame

#========================================================================
# The "phenix.hyss parameters" of the asymmetric unit folder

  OpenFolder 3  SHOW_HYSS  closed 1 hide

  CreateLine line \
    message "Take default cutoffs calculated automatically by phenix.hyss" \
    widget TOG_SHELXC_RESO -toggleon \
    label "Override default resolution limits: high resolution" \
    widget MAX_RESO label "A"

  CreateLine line \
    message "The minimum distance should depend on the type and clustering of the heavy atoms" \
    widget TOG_MIND -toggleon \
    label "Minimum distance between heavy atoms" \
    widget MIND \
    label "Angstrom"

  CreateLine line \
    widget TOG_HYSS_SEARCH -toggleon \
    label "Search mode" \
    widget HYSS_SEARCH

  CreateLine line \
    message "Solvent content (default: 0.55)" \
    widget TOG_HYSS_SOLVENT -toggleon \
    label "Solvent Content" \
    widget SCATTERING_SOLVENT

  CreateLine line \
    message "Useful if substructure location is difficult" \
     widget TOG_HYSS_PHASER -toggleon \
    label "Use Phaser rescoring in hyss"


#========================================================================
# The "Shelx parameters" of the asymmetric unit folder

  OpenFolder 4 SHOW_SHELX closed 1 hide

  CreateLine line \
    message "Take default cutoffs calculated automatically by SHELXC" \
    widget TOG_SHELXC_RESO -toggleon \
    label "Override default resolution limits: Use data from" \
    widget MIN_RESO label "to" widget MAX_RESO label "A"

  CreateLine line \
    message "Number of attempts at finding atoms (in some cases > 1000 tries may be required)" \
    widget TOG_NTRY -toggleon \
    label "Limit number of tries to" \
    widget NTRY

  CreateLine line \
    message "The minimum distance should depend on the type and clustering of the heavy atoms" \
    widget TOG_MIND -toggleon \
    label "Minimum distance between heavy atoms" \
    widget MIND \
    label "Angstrom"

  CreateLine line \
    message "Normally atoms on special positions will be rejected by SHELXD (sets MIND ... -0.1)" \
    widget ALLOW_SPECIAL_POS \
    label "Allow for heavy atoms lying on special positions"

#  CreateLine line \
    message "Choose whether or not starting atoms should be found from the Patterson" \
    widget PATS_ONOFF \
    label "Run a Patterson-search to find a starting set of atoms."

#========================================================================
# The "Define Composition" of the asymmetric unit folder

  OpenFolder 5 open

  CreateLine line \
      message "Total scattering of atoms in the asymmetric unit" \
      label "Total scattering determined by "\
      widget SCATTERING \
      toggle_display SCATTERING open [list AVERAGE COMPONENT ]

  CreateLine line \
      message "Total scattering of atoms in the asymmetric unit" \
      label "Total scattering determined by "\
      widget SCATTERING \
      widget SCATTERING_SOLVENT  -oblig \
      toggle_display SCATTERING open SOLVENT

  OpenSubFrame frame -toggle_display SCATTERING open COMPONENT hide

  CreateExtendingFrame N_COMPONENT phaser_EP_component \
      "Define another protein or nucleic acid component" "Define another component" \
      [list PROTDNA MW ASYM COMP_OPTION COMP_NRES COMP_FILE DIR_COMP_FILE ]

  CloseSubFrame

#======================================================================== 
# The "Accessory parameters" folder

  OpenFolder 6 closed 

  CreateLine line \
      widget TOG_SCAT_RESTRAIN -toggleon \
      label "Restrain Fdp to starting value" \
      widget SCAT_RESTRAIN \
      toggle_display SCAT_RESTRAIN open OFF

  CreateLine line \
      widget TOG_SCAT_RESTRAIN -toggleon \
      label "Restrain Fdp to starting value" \
      widget SCAT_RESTRAIN \
      label "Sigma of restraint" \
      widget SCAT_SIGMA \
      label " (times initial Fdp)" \
      toggle_display SCAT_RESTRAIN open ON

  CreateLine line \
      message "Default sigma cut-off = 6" \
      widget TOG_LLGC_SAD_SIGMA -toggleon \
      label "LLG-map sigma cut-off for adding new atom sites" \
      widget LLGC_SIGMA_SAD

  CreateLine line \
      message "Default clash distance is optical resolution" \
      widget TOG_LLGC_SAD_CLASH -toggleon \
      label "LLG-map atomic separation distance cut-off default" \
      widget LLGC_CLASH_DEFAULT \
      toggle_display LLGC_CLASH_DEFAULT open ON

  CreateLine line \
      message "Default clash distance is optical resolution" \
      widget TOG_LLGC_SAD_CLASH -toggleon \
      label "LLG-map atomic separation distance cut-off default" \
      widget LLGC_CLASH_DEFAULT \
      label "Distance" \
      widget LLGC_CLASH_DISTANCE \
      toggle_display LLGC_CLASH_DEFAULT open OFF

  CreateLine line \
      widget TOG_LLGC_SAD_NCYC -toggleon \
      label "Maximum number of LLG-map completion cycles" \
      widget LLGC_NCYC

  CreateLine line \
      widget TOG_LLGC_SAD_METH -toggleon \
      label "LLG-map completion picks peaks from " \
      widget LLGC_METHOD


#========================================================================
# The "Output control" folder

  OpenFolder 7 closed

  CreateLine line \
      message "VERBOSE: more information included in log file than by default" \
      widget TOG_VERBOSE \
      label "Verbose output to log file" \

  CreateLine line \
      message "DEBUG: debugging information included in log file than by default" \
      widget TOG_VERBOSE_EXTRA \
      label "Debug output to log file"

  CreateLine line \
      widget TOG_SCRIPT -toggleon \
      label "SOL file output" \
      widget SCRIPT_ONOFF

  CreateLine line \
      message "Controls output of PDB files containing potential solutions.\
               Default depends on mode." \
      widget TOG_XYZOUT -toggleon \
      label "PDB file output" \
      widget XYZOUT_ONOFF

  CreateLine line \
      message "Controls output of MTZ files with phase information from solutions" \
      widget TOG_HKLOUT -toggleon \
      label "MTZ file output" \
      widget HKLOUT_ONOFF

  CreateLine line \
      message "Controls output of LLG map coefficients to MTZ file" \
      widget TOG_LLGC_SAD_MAPS -toggleon \
      label "Output log-likelihood gradient map coefficients" \
      widget LLGC_MAPS

#========================================================================
# The "Expert parameters" folder

  OpenFolder 8 closed

  CreateLine line \
     message "Change input atomic B-factors to Wilson" \
     widget TOG_CHANGE_BFAC -toggleon \
     label "Set B-factors to Wilson B-factor" \
     widget CHANGE_BFAC_ONOFF

    CreateLine line \
      message "Refinement macrocyles" \
      widget TOG_ANISO -toggleon \
      label "Anisotropic refinement protocol" \
      widget MACA_PROTOCOL

    OpenSubFrame frame \
      -toggle_display MACA_PROTOCOL open CUSTOM hide
     CreateExtendingFrame N_MACA phaser_EP_maca \
        "Customize the anisotropic refinement" \
        "Add another anisotropic macrocycle" \
        [list MACA_ANIS MACA_BINS MACA_SOLK MACA_SOLB MACA_NCYC ]
    CloseSubFrame

  CreateLineTemplate MACSAD_TEMPLATE \
    { 0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 } 

  CreateLineTemplate MACSAD_PART_TEMPLATE \
    { 0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8} 

    CreateLine line \
      message "SAD refinement macrocyles" \
      widget TOG_MACSAD -toggleon label "SAD refinement" \
      widget MACSAD_OPTION 

  OpenSubFrame frame -toggle_display MACSAD_OPTION open CUSTOM hide

  OpenSubFrame frame -toggle_display EP_MODE open SAD

  CreateLine line \
        label "OK" label "OB" label "OSS" label "AX" label "AO" label "AB" label "FDP" \
        label "VA" label "VB" label "VP" label "VD" label "NCYC" \
        format template MACSAD_TEMPLATE
  CreateExtendingFrame N_MACSAD phaser_EP_macs \
        "Customize the SAD refinement" \
        "Add another SAD macrocycle" \
        [list TOG_MACSAD_K TOG_MACSAD_B TOG_MACSAD_XYZ TOG_MACSAD_OCC TOG_MACSAD_BFAC TOG_MACSAD_FDP \
              TOG_MACSAD_SA TOG_MACSAD_SB TOG_MACSAD_SP TOG_MACSAD_SD MACSAD_NCYCL ] 

  CloseSubFrame 
  
  OpenSubFrame frame -toggle_display EP_MODE open MRSAD

  CreateLine line \
        label "OK" label "OB" label "OSS" label "AX" label "AO" label "AB" label "FDP" \
        label "VA" label "VB" label "VP" label "VD" label "PK" label "PB" label "NCYC" \
        format template MACSAD_PART_TEMPLATE
  CreateExtendingFrame N_MACSAD phaser_EP_macs_part \
        "Customize the SAD refinement" \
        "Add another SAD macrocycle" \
        [list TOG_MACSAD_K TOG_MACSAD_B TOG_MACSAD_XYZ TOG_MACSAD_OCC TOG_MACSAD_BFAC TOG_MACSAD_FDP \
              TOG_MACSAD_SA TOG_MACSAD_SB TOG_MACSAD_SP TOG_MACSAD_SD TOG_MACSAD_PK TOG_MACSAD_PB MACSAD_NCYCL ] 

  CloseSubFrame 

  CloseSubFrame 

  CreateLine line \
      message "BINS: specify how the binning to all reflections will apply"\
      widget TOG_BINS -toggleon \
      label "Bins: Min" widget BINS_MIN label "Max" widget BINS_MAX label "Width" widget BINS_WIDTH \
      message "Binning function: AS^3 + BS^2 + CS\
               where S=1/reso."\
      label "Cubic: A" widget BINS_A label "B" widget BINS_B label "C" widget BINS_C

  CreateLine line \
      message "Restrain B-factors to Wilson B-factor" \
      widget TOG_WILSON -toggleon label "B-factor Wilson Restraint" widget WILSON_ONOFF \
      label "Sigma of restraint " \
      widget WILSON_SIGMA \
      toggle_display WILSON_ONOFF open ON

  CreateLine line \
      message "Restrain B-factors to Wilson B-factor" \
      widget TOG_WILSON -toggleon label "B-factor Wilson Restraint" widget WILSON_ONOFF \
      toggle_display WILSON_ONOFF open OFF

  CreateLine line \
      message "Restrain Anisotropic B-factors to be Isotropic" \
      widget TOG_SPHERICITY -toggleon label "B-factor Sphericity Restraint" widget SPHERICITY_ONOFF \
      label "Sigma of restraint " \
      widget SPHERICITY_SIGMA \
      toggle_display SPHERICITY_ONOFF open ON

  CreateLine line \
      message "Restrain Anisotropic B-factors to be Isotropic" \
      widget TOG_SPHERICITY -toggleon label "B-factor Sphericity Restraint" widget SPHERICITY_ONOFF \
      toggle_display SPHERICITY_ONOFF open OFF

  CreateLine line \
    widget TOG_CELL -toggleon \
    label "Unit Cell: a" \
    message "Cell dimensions (default from MTZ file) (CELL)" \
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
      message "OUTLIER: choose whether to reject large, unlikely E-values" \
      widget TOG_OUTLIER -toggleon \
      label "Outlier rejection" \
      widget OUTLIER_OPTION \
      label "outlier probability" \
      message "Enter cutoff probability, where outliers with a probability\
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

  CreateLine line \
      message "Single atom molecular replacement" \
      widget EP_SAMR \
      -command "phaser_EP_show_labin_F $arrayname" \
      label "Only use merged F and SIGF for phasing (single atom MR)"

  CreateLine line \
      message "TNCS: use or ignore translational NCS if present" \
      widget TOG_TNCS_USE -toggleon \
      label "Use translational NCS if present " \
      widget TNCS_USE

  OpenSubFrame frame -toggle_display TNCS_USE open ON

  CreateLine line \
      message "TNCS: translation vector in Angstroms" \
      label "TNCS: " \
      widget TOG_TNCS_TRA_VECTOR -toggleon \
      label "Fix vector " \
      widget TNCS_TRA_VECTOR_X \
      widget TNCS_TRA_VECTOR_Y \
      widget TNCS_TRA_VECTOR_Z label "Angstroms"

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
      widget TOG_TNCS_PATT_PERCENT -toggleon \
      label "Minimum percent of Patterson orgin peak " \
      widget TNCS_PATT_PERCENT

  CreateLine line \
      message "TNCS: Parameters for identifying TNCS from Patterson" \
      label "TNCS: " \
      widget TOG_TNCS_PATT_DISTANCE -toggleon \
      label "Minimum length of TNCS vector " \
      widget TNCS_PATT_DISTANCE

  CreateLine line \
      message "TNCS: Paired atom restraints" \
      label "TNCS: " \
      widget TOG_TNCS_LINK -toggleon \
      label "Use paired atom occupancy and B-factor restraint" \
      widget TNCS_LINK_RESTRAINT \
      label "Restraint sigma" \
      widget TNCS_LINK_SIGMA \
      toggle_display TNCS_LINK_RESTRAINT open ON

  CreateLine line \
      message "TNCS: Paired atom restraints" \
      label "TNCS: " \
      widget TOG_TNCS_LINK -toggleon \
      label "Use paired atom occupancy and B-factor restraint" \
      widget TNCS_LINK_RESTRAINT \
      toggle_display TNCS_LINK_RESTRAINT open OFF

  CreateLine line \
      message "TNCS: Paired atom control" \
      label "TNCS: " \
      widget TOG_TNCS_PAIR_ONLY -toggleon \
      label "Only add atoms in pairs" \
      widget TNCS_PAIR_ONLY

  CloseSubFrame

 }
