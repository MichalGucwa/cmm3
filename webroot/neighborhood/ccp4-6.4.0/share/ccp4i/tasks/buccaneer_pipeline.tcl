# ======================================================================
# buccaneer_pipeline.tcl --
#
# CCP4Interface 
#
# =======================================================================

#------------------------------------------------------------------------------
proc buccaneer_pipeline_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable cbuccaneer]] } {
    return 0
  }
  if { ![file exists [FindExecutable refmac5]] } {
    return 0
  }
  if { ![file exists [FindExecutable ccp4-python]] } {
    return 0
  }
  return 1
}

#------------------------------------------------------------------------
proc buccaneer_pipeline_setup { typedefname arrayname }  {
#------------------------------------------------------------------------

  upvar #0 $typedefname typedef

  set typedef(_phasing_source) { menu { "experimental phasing" "molecular replacement" } { "EP" "MR" } }
  set typedef(_seq_reliability) { menu { "definite" "probable" "possible" } { 0.99 0.95 0.80 } }
  set typedef(_ramachan_filter) { menu { "all" "helix" "strand" "nonhelix" } }
  set typedef(_ref_structureid) { menu { "1tqw" "1ajr" } }

  return 1
}

#------------------------------------------------------------------------------
proc buccaneer_pipeline_run { arrayname } {
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
  if { $array(USEKNOWN) == 1 && $array(USEXYZIN) == 0 } {
          WarningMessage "Known structure specified but no initial model given.
Please provide an initial model to be extended."
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

  set files "HKLINwrk SEQINwrk"
  if { $array(USEXYZIN) == 1 } {
    set files "$files XYZINwrk"
  }
  set array(INPUT_FILES) "$files"

  return 1
}

#----------------------------------------------------------------------
proc buccaneer_buccaneer_keyword { arrayname counter } {
#----------------------------------------------------------------------
  CreateLine line \
      label "    Additional keyword: " \
      widget BUC_KEYS
}

#----------------------------------------------------------------------
proc buccaneer_refine_keyword { arrayname counter } {
#----------------------------------------------------------------------
  CreateLine line \
      label "    Additional keyword: " \
      widget REF_KEYS
}

#---------------------------------------------------------------------
proc buccaneer_pipeline_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [ CreateTaskWindow $arrayname  \
	 "Chain tracing/refinement using Buccaneer/Refmac" "Buccaneer/Refmac" \
	     [ list \
	       "Options" \
	       "Molecular replacement parameters" \
	       "Model building parameters" \
	       "Refinement parameters" \
	       "Advanced" \
	      ] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "cbuccaneer"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
      message "Run density modification first after experimental phasing." \
      label "Perform model building/reginement starting from " \
      widget PHASINGSRC \
      label " phases."

#=FILES================================================================

  OpenFolder file 

  CreateLine line \
      label "Data for (unsolved) work structure:" -italic \
      label "         (Note: perform phase improvement/density modification first)"

  CreateLine line \
      message "Add new chains, residues or sequence to an exisiting model" \
      widget USEXYZIN -width 4 \
      label "Specify an initial model to be extended.        "

  CreateInputFileLine line \
      "Enter input coordinate file name for (unsolved) work structure" \
      "Work PDB in" \
      XYZINwrk DIR_XYZINwrk \
      -toggle_display USEXYZIN open 1

  CreateInputFileLine line \
      "Enter input sequence file name for (unsolved) work structure" \
      "Work SEQ in" \
      SEQINwrk DIR_SEQINwrk

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
      label "Calculation options:" -italic \

  CreateLine line \
      message "Number of cycles of building/refinement to run" \
      help cycles \
      label "Number of cycles of building/refinement to run:" \
      widget NCYCLE -width 4

  CreateLine line \
      message "Use multiple CPUs or CPU cores to speed up the calculation" \
      help jobs \
      widget USEJOBS -width 4 \
      label "Use" \
      widget NJOBS -width 4 \
      label "CPUs for calculation.                 " \
      message "Use fastest rather than best methods" \
      help fast \
      widget DOFAST -width 4 \
      label "Use fastest methods."

#-----------------------------------------------------

  OpenFolder 2 PHASINGSRC open MR closed 

  CreateLine line \
      message "Select this option when rebuilding after MR to reduce bias." \
      widget REF_MLHL -width 4 \
      label "Use phases in refinement (disable to reduce bias)."

  CreateLine line \
      message "The new model will be built in the same place with the same chain IDs." \
      widget USEXYZMR -width 4 \
      label "Specify an MR model to determine placement of the new model."

  CreateInputFileLine line \
      "Enter input coordinate file name for molecular replacement model" \
      "MR model PDB in" \
      XYZINmr DIR_XYZINmr \
      -toggle_display USEXYZMR open 1

#-----------------------------------------------------

  OpenFolder 3 closed

  CreateLine line \
      label "Parameters for first Buccaneer cycle:"  -italic

  CreateLine line \
      message "Number of internal cycles of building to run" \
      help cycles \
      label "    Number of internal cycles of building to run:" \
      widget BUC_NCYCLE_0 -width 4

  CreateLine line \
      message "Use correlation mode for completion after MR or initial build" \
      help correlation-mode \
      label "    Use correlation target function: " \
      widget BUC_USECORR_0 -width 4 \
      label "(use after MR or for model completion)" -italic

  CreateLine line \
      message "Sequence docking can be cautious, pragmatic, or reckless" \
      help sequence-reliability \
      label "    Assign sequence when a " \
      widget BUC_SEQREL_0 \
      label " match is found."

  CreateLine line \
      label "Parameters for subsequent Buccaneer cycles:"  -italic

  CreateLine line \
      message "Number of internal cycles of building to run" \
      help cycles \
      label "    Number of internal cycles of building to run:" \
      widget BUC_NCYCLE_N -width 4

  CreateLine line \
      message "Use correlation mode for completion after MR or initial build" \
      help correlation-mode \
      label "    Use correlation target function: " \
      widget BUC_USECORR_N -width 4 \
      label "(use after MR or for model completion)" -italic

  CreateLine line \
      message "Sequence docking can be cautious, pragmatic, or reckless." \
      help sequence-reliability \
      label "    Assign sequence when a " \
      widget BUC_SEQREL_N \
      label " match is found."

  CreateLine line \
      label "General parameters:"  -italic

  CreateLine line \
      message "Using data beyond 2.0A is slow and seldom helps. (No effect if data resolution is lower than this limit.)" \
      help resolution \
      label "    Truncate data beyond resolution limit/Angstroms:" \
      widget BUC_RESOLN_MAX -width 4

  CreateLine line \
      message "Grown residues will be give this residue name in the output." \
      label "    Residue name for unsequenced residues:" \
      widget BUC_NEWRESNM -width 4

  CreateLine line \
      message "Fix the position of the model in the ASU" \
      help fix-position \
      label "    " \
      widget DOFIXPOS -width 4 \
      label "Build the new model in the same place as the input model." \
      toggle_display USEXYZIN open 1

  CreateLine line \
      message "Use to preserve known structure, e.g. heavy atoms/nucleotides." \
      label "    " \
      widget USEKNOWN -width 4 \
      label "Specify atoms from the initial model to keep."

  CreateLine line \
      message "The specified atoms will be kept. If a radius is given, this region will be excluded from new building." \
      label "        Chain/residue/atom ids:" \
      widget BUC_KNOWN_ID -width 12 \
      label "  Radius:" \
      widget BUC_KNOWN_RAD \
      toggle_display USEKNOWN open 1

  CreateLine line \
      message "A heavy atom or MR model can help with sequencing." \
      label "    " \
      widget USEXYZSQ -width 4 \
      label "Specify a heavy atom or MR model to help with sequencing."

  CreateInputFileLine line \
      "Enter input coordinate file name for heavy atom/MR structure to help with sequencing" \
      "        Sequence PDB in" \
      XYZINseq DIR_XYZINseq \
      -toggle_display USEXYZSQ open 1

  CreateLine line \
      label "Data for (solved) reference structure:" -italic

  CreateLine line \
      message "The default is a good choice." \
      label "    Library reference structure to use: " \
      widget REFCODE \
      label " (unless user-defined)."

  CreateLine line \
      message "Select this if you want to use your own reference structure data for an unusual problem." \
      label "    " \
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

#-----------------------------------------------------

  OpenFolder 4 closed

  CreateLine line \
      message "Twin refinement can give better results if the data is twinned, but disables phases." \
      widget REF_TWIN -width 4 \
      label "Refine against twinned data (REQUIRES REFMAC UPDATE)."

  CreateLine line \
      message "Select this option when rebuilding after MR to reduce bias." \
      widget REF_MLHL -width 4 \
      label "Use phases in refinement (disable to reduce bias)."

  CreateLine line \
      message "Select to use different Hendrickson-Lattman coefficients in refinement, e.g. non-density modified phases." \
      widget REF_HLCOLS -width 4 \
      label "Specify different Hendrickson-Lattman coefficients for use in refinement."

  CreateLabinLine4 line \
      "Choose Hendrickson-Lattman coefficients for use in refinement." \
      HKLINwrk     "HLA" REF_HLAwrk  [list HLA] \
      -dependent   "HLB" REF_HLBwrk  [list HLB] \
      -dependent   "HLC" REF_HLCwrk  [list HLC] \
      -dependent   "HLD" REF_HLDwrk  [list HLD] \
      -toggle_display REF_HLCOLS open 1

  CreateLine line \
      message "Automatic is safest, otherwise low values preserve geometry at the expense of R-factor." \
      label "Automatic weighting of restraints:" \
      widget REF_MXAUTO -width 4 \
      label " or weight value:" \
      widget REF_MXWGHT -width 4

#-----------------------------------------------------

  OpenFolder 5 closed

  CreateLine line \
      label "Additional Model Building Keywords:" -italic

  CreateExtendingFrame N_BUC_KEYS buccaneer_buccaneer_keyword \
        "Add/remove line to define extra keyword" \
        "Add keyword" \
        [ list BUC_KEYS ]

  CreateLine line \
      label "Additional Refinement Keywords:" -italic

  CreateExtendingFrame N_REF_KEYS buccaneer_refine_keyword \
        "Add/remove line to define extra keyword" \
        "Add keyword" \
        [ list REF_KEYS ]
}
