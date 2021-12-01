# ======================================================================
# buccaneer.tcl --
#
# CCP4Interface 
#
# =======================================================================

#------------------------------------------------------------------------------
proc buccaneer_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable cbuccaneer]] } {
    return 0
  }
  return 1
}

#------------------------------------------------------------------------
proc buccaneer_setup { typedefname arrayname }  {
#------------------------------------------------------------------------

  upvar #0 $typedefname typedef

  set typedef(_seq_reliability) { menu { "definite" "probable" "possible" } { 0.99 0.95 0.80 } }
  set typedef(_ramachan_filter) { menu { "all" "helix" "strand" "nonhelix" } }
  set typedef(_ref_structureid) { menu { "1tqw" "1ajr" } }

  return 1
}

#------------------------------------------------------------------------------
proc buccaneer_run { arrayname } {
#------------------------------------------------------------------------------
  upvar #0 $arrayname array

  global env

  if { $array(USEPHIW) == 0 && ( $array(HLAwrk) == "Unassigned" || \
                                 $array(HLBwrk) == "Unassigned" || \
                                 $array(HLCwrk) == "Unassigned" || \
                                 $array(HLDwrk) == "Unassigned" ) } {
          WarningMessage "One or more input labels are unassigned.
Please check that input labels are correctly set before rerunning the task"
          return 0
     }
  if { $array(USEPHIW) == 1 && ( $array(PHIwrk) == "Unassigned" || \
                                 $array(FOMwrk) == "Unassigned" ) } {
          WarningMessage "One or more input labels are unassigned.
Please check that input labels are correctly set before rerunning the task"
          return 0
     }
  if { $array(USEFREE) == 1 && ( $array(FREEwrk) == "Unassigned" ) } {
          WarningMessage "One or more input labels are unassigned.
Please check that input labels are correctly set before rerunning the task"
          return 0
     }

  if { $array(REFUSER) == 0 } {
    set base [FileJoin [GetEnvPath CLIBD] reference_structures]
    set code "$array(REFCODE)"
    set array(HKLINref) [FileJoin "$base" "reference-$code.mtz"]
    set array(XYZINref) [FileJoin "$base" "reference-$code.pdb"]
    set array(FPref)    "FP.F_sigF.F"
    set array(SIGFPref) "FP.F_sigF.sigF"
    set array(HLAref)   "FC.ABCD.A"
    set array(HLBref)   "FC.ABCD.B"
    set array(HLCref)   "FC.ABCD.C"
    set array(HLDref)   "FC.ABCD.D"
  }

  set files "HKLINwrk"
  if { $array(DOSEQNC) == 1 } {
    set files "$files SEQINwrk"
  }
  if { $array(USEXYZIN)  == 1 } {
    set files "$files XYZINwrk"
  }
  set array(INPUT_FILES) "$files"

  return 1
}

#---------------------------------------------------------------------
proc buccaneer_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [ CreateTaskWindow $arrayname  \
	     "Chain tracing using Buccaneer" "Buccaneer" \
	     [ list \
	       "Options" \
	       "Build steps" \
	       "Optional parameters" \
	      ] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "cbuccaneer"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

#=FILES================================================================

  OpenFolder file 

  CreateLine line \
      label "Data for (unsolved) work structure:" -italic \
      label "         (Note: perform phase improvement/density modification first)"

  CreateLine line \
      message "Add new chains, residues or sequence to an exisiting model" \
      widget USEXYZIN -width 4 \
      label "Specify an initial model to be extended.        " \
      message "A heavy atom or MR model can help with sequencing" \
      widget USEXYZSQ -width 4 \
      label "Specify a heavy atom or MR model."

  OpenSubFrame pdbinwrk \
      -toggle_display USEXYZIN open 1

  CreateInputFileLine line \
      "Enter input coordinate file name for (unsolved) work structure" \
      "Work PDB in" \
      XYZINwrk DIR_XYZINwrk
  
  CloseSubFrame

  OpenSubFrame seqinwrk \
      -toggle_display DOSEQNC open 1

  CreateInputFileLine line \
      "Enter input sequence file name for (unsolved) work structure" \
      "Work SEQ in" \
      SEQINwrk DIR_SEQINwrk
  
  CloseSubFrame

  CreateInputFileLine line \
      "Enter input reflection file name for (unsolved) work structure" \
      "Work MTZ in" \
      HKLINwrk DIR_HKLINwrk \
      -fileout XYZOUT DIR_XYZOUT "_buccaneer"

  CreateLabinLine line \
      "Observed amplitude (FP) and obligatory sigma (SIGFP)" \
      HKLINwrk "FP"  FPwrk     [list FP    FP.F_sigF.F   ] \
      -sigma "SIGFP" SIGFPwrk  [list SIGFP FP.F_sigF.sigF]

  CreateLabinLine4 line \
      "Choose Hendrickson-Lattman coefficients from phase improvement (i.e. DENSITY MODIFIED PHASES)" \
      HKLINwrk     "HLA" HLAwrk  [list parrot.ABCD.A pirate.ABCD.A HLADM] \
      -dependent   "HLB" HLBwrk  [list parrot.ABCD.B pirate.ABCD.B HLBDM] \
      -dependent   "HLC" HLCwrk  [list parrot.ABCD.C pirate.ABCD.C HLCDM] \
      -dependent   "HLD" HLDwrk  [list parrot.ABCD.D pirate.ABCD.D HLDDM] \
      -toggle_display USEPHIW open 0

  CreateLabinLine line \
      "Choose phi/fom" \
      HKLINwrk "PHI" PHIwrk  [list PHIDM PHWT] \
      -sigma   "FOM" FOMwrk  [list FOMDM FOM ] \
      -toggle_display USEPHIW open 1

  CreateLabinLine line \
      "Choose F/phi" \
      HKLINwrk "F"   FMAPwrk    [list parrot.F_phi.F   pirate.F_phi.F   FWT ] \
      -sigma   "PHI" PMAPwrk    [list parrot.F_phi.phi pirate.F_phi.phi PHWT] \
      -toggle_display USEFMAP open 1

  CreateLabinLine line \
      "Choose Free-R flag" \
      HKLINwrk "Free R flag" FREEwrk  [list FreeR_flag] \
      -toggle_display USEFREE open 1

  CreateLine line \
      message "Optionally specify Free-R set" \
      help colin-wrk-free \
      label " Use Free-R flag:" \
      widget USEFREE \
      message "Optionally specify starting map coefficients" \
      help colin-wrk-fc \
      label " Use map coefficients:" \
      widget USEFMAP \
      message "Select this option if you don't have HL coefficients - e.g. after MR or SHELX" \
      help colin-wrk-phifom \
      label "                    Use PHI/FOM instead of HL coefficients:" \
      widget USEPHIW

  OpenSubFrame pdbinseq \
      -toggle_display USEXYZSQ open 1

  CreateInputFileLine line \
      "Enter input coordinate file name for heavy atom/MR structure to help with sequencing" \
      "HA/MR PDB in" \
      XYZINseq DIR_XYZINseq
  
  CloseSubFrame

  CreateOutputFileLine line \
      "Enter output pdb file name for (unsolved) work structure" \
      "Work PDB out" \
      XYZOUT DIR_XYZOUT

#-----------------------------------------------------

  OpenFolder 1 open

  CreateLine line \
      message "Correct any anisotropy in the input data" \
      help anisotropy-correction \
      widget DOANIS -width 4 \
      label "Apply anisotropy correction to input data."

  CreateLine line \
      message "Build Selenomethionine residues instead of methionine" \
      help build-semet \
      widget DOSEMET -width 4 \
      label "Build Selenomethionine " \
      label "(MSE instead of MET)." -italic

  CreateLine line \
      message "Fix the position of the model in the ASU" \
      help fix-position \
      widget DOFIXPOS -width 4 \
      label "Build the new model in the same place as the input model." \
      toggle_display USEXYZIN open 1

  CreateLine line \
      label "Calculation options:" -italic \

  CreateLine line \
      message "Use fastest rather than best methods (2-3x faster, ~5%% less model)" \
      help fast \
      widget DOFAST -width 4 \
      label "Use fastest rather than best methods."

  CreateLine line \
      message "Number of cycles of building to run" \
      help cycles \
      label "Number of cycles of building to run:" \
      widget NCYCLE -width 4

#-----------------------------------------------------

  OpenFolder 2 closed

  CreateLine line \
      message "Select how you want to use buccaneer." \
      label "Use buccaneer to:"

  CreateLineTemplate OPTIONS { 0.00 0.025 0.50 0.525 }

  CreateLine line \
      message "Find initial candidate C-alphas by 6D search in the density." \
      help grow \
      widget DOFIND -width 4 \
      label " 1. Find initial candidate C-alphas in the density." \
      message "Inserts or deletes residues if there is a sequence mismatch." \
      help correct \
      widget DOCORCT -width 4 \
      label " 6. Correct by rebuilding sequence register errors." \
      format template OPTIONS

  CreateLine line \
      message "Grow the candidate C-alphas into chain fragments." \
      help grow \
      widget DOGROW -width 4 \
      label " 2. Grow candidate C-alphas into chain fragments." \
      message "Eliminates residues in low density or sequence breaks." \
      help filter \
      widget DOFILTR -width 4 \
      label " 7. Filter out residues for which density is poor." \
      format template OPTIONS

  CreateLine line \
      message "Join the chain fragments together by merging overlaps." \
      help join \
      widget DOJOIN -width 4 \
      label " 3. Join the chain fragments together." \
      message "Improved model completeness when NCS is present." \
      help ncsbuild \
      widget DONCSRB -width 4 \
      label " 8. Use NCS to rebuild and complete related chains." \
      format template OPTIONS

  CreateLine line \
      message "Use loop fitting to try and link nearby N and C terminii." \
      help link \
      widget DOLINK -width 4 \
      label " 4. Link nearby fragments." \
      message "Prune any clashing chains." \
      help prune \
      widget DOPRUNE -width 4 \
      label " 9. Prune any clashing chains." \
      format template OPTIONS

  CreateLine line \
      message "Matches side chain density against the actual sequence." \
      help sequence \
      widget DOSEQNC -width 4 \
      label " 5. Assign a sequence to the best chains." \
      message "Without rebuilding, only N,CA,C atoms are output." \
      help build \
      widget DOBUILD -width 4 \
      label "10. Rebuild side chains and Carbonyl Oxygens." \
      format template OPTIONS

#-----------------------------------------------------

  OpenFolder 3 closed

  CreateLine line \
      message "Use correlation mode for completion after MR or initial build" \
      help correlation-mode \
      widget USECORR -width 4 \
      label "Use correlation target function " \
      label "(use after MR or for model completion)" -italic

  CreateLine line \
      message "Sequence docking can be cautious, pragmatic, or reckless" \
      help sequence-reliability \
      label "Assign sequence when a " \
      widget SEQREL \
      label " match is found."

  CreateLine line \
      message "Select principle secondary structure type." \
      help ramachandran-filter \
      label "Find secondary structure features preferentially: " \
      widget RAMAFLT

  CreateLine line \
      message "Using data beyond 2.0A is slow and seldom helps. (No effect if data resolution is lower than this limit.)" \
      help resolution \
      label "Truncate data beyond resolution limit/Angstroms:" \
      widget RESOLUTION_MAX -width 4

  CreateLine line \
      message "Number of fragments to build per 100 residues" \
      help fragments-per-100-residues \
      label "Number of fragments to build per 100 residues:" \
      widget NFRAGR -width 4

  CreateLine line \
      message "Maximum number of fragments to build" \
      help fragments \
      label "Maximum number of fragments to build:" \
      widget NFRAGS -width 4

  CreateLine line \
      message "Grown residues will be give this residue name in the output." \
      label "Residue name for unsequenced residues:" \
      widget NEWRESNM -width 4

  CreateLine line \
      label "Data for (solved) reference structure:" -italic

  CreateLine line \
      message "The default is a good choice." \
      label "Library reference structure to use: " \
      widget REFCODE \
      label " (unless user-defined)."

  CreateLine line \
      message "Select this if you want to use your own reference structure data for an unusual problem." \
      widget REFUSER -width 4 \
      label "Specify a user-defined reference structure instead of the standard library."

  OpenSubFrame refin \
      -toggle_display REFUSER open 1

  CreateInputFileLine line \
      "Enter input pdb file name for (solved) reference structure" \
      "Reference PDB in" \
      XYZINref DIR_XYZINref

  CreateInputFileLine line \
      "Enter input MTZ file name for (solved) reference structure" \
      "Reference MTZ in" \
      HKLINref DIR_HKLINref \

  CreateLabinLine line \
      "Observed amplitude (FP) and obligatory sigma (SIGFP)" \
      HKLINref "FP"  FPref     [list FP.F_sigF.F    FP   ] \
      -sigma "SIGFP" SIGFPref  [list FP.F_sigF.sigF SIGFP]

  CreateLabinLine4 line \
      "Choose Hendrickson-Lattman coefficients from final model" \
      HKLINref     "HLA" HLAref  [list FC.ABCD.A HLA] \
      -dependent   "HLB" HLBref  [list FC.ABCD.B HLB] \
      -dependent   "HLC" HLCref  [list FC.ABCD.C HLC] \
      -dependent   "HLD" HLDref  [list FC.ABCD.D HLD]

  CloseSubFrame

}
