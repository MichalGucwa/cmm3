# ======================================================================
# parrot.tcl --
#
# CCP4Interface 
#
# =======================================================================

#------------------------------------------------------------------------------
proc parrot_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable cparrot]] } {
    return 0
  }
  return 1
}

#------------------------------------------------------------------------
proc parrot_setup { typedefname arrayname }  {
#------------------------------------------------------------------------

  upvar #0 $typedefname typedef

  set typedef(_ref_structureid) { menu { "1tqw" "1ajr" } }

  return 1
}

#------------------------------------------------------------------------------
proc parrot_run { arrayname } {
#------------------------------------------------------------------------------
  upvar #0 $arrayname array

  global env

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
  if { $array(USESEQINwrk) == 1 } {
    set files "$files SEQINwrk"
  }
  if { $array(USEXYZIN_ha)  == 1 } {
    set files "$files XYZIN_ha"
  }
  if { $array(USEXYZIN_mr)  == 1 } {
    set files "$files XYZIN_mr"
  }
  set array(INPUT_FILES) "$files"

  return 1
}

#----------------------------------------------------------------------
proc parrot_keyword { arrayname counter } {
#----------------------------------------------------------------------
  CreateLine line \
      label "    Additional keyword: " \
      widget KEYS
}

#---------------------------------------------------------------------
proc parrot_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [ CreateTaskWindow $arrayname  \
	     "Density modification using Parrot" "Parrot" \
	     [ list \
	       "Options" \
	       "Optional parameters" \
	      ] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "cbuccaneer"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
      message "Specify a file from which to estimate the cell contents." \
      widget USESEQINwrk -width 4 \
      label "Estimate solvent content from sequence."

  CreateLine line \
      message "Specify a heavy atom model to determine NCS operators." \
      widget USEXYZIN_ha -width 4 \
      label "Get NCS from heavy atoms.        " \
      message "Specify a molecular replacement or partial model to determine NCS operators." \
      widget USEXYZIN_mr -width 4 \
      label "Get NCS from MR/partial model."

#=FILES================================================================

  OpenFolder file 

  CreateLine line \
      label "Data for (unsolved) work structure:" -italic

  OpenSubFrame seqinwrk \
      -toggle_display USESEQINwrk open 1

  CreateInputFileLine line \
      "Enter input sequence file name for (unsolved) work structure" \
      "Work SEQ in" \
      SEQINwrk DIR_SEQINwrk
  
  CloseSubFrame

  CreateInputFileLine line \
      "Enter input reflection file name for (unsolved) work structure" \
      "Work MTZ in" \
      HKLINwrk DIR_HKLINwrk \
      -fileout HKLOUT DIR_HKLOUT "_parrot"

  CreateLabinLine line \
      "Observed amplitude (FP) and obligatory sigma (SIGFP)" \
      HKLINwrk "FP"  FPwrk     [list FP    FP.F_sigF.F   ] \
      -sigma "SIGFP" SIGFPwrk  [list SIGFP FP.F_sigF.sigF]

  CreateLabinLine4 line \
      "Choose Hendrickson-Lattman coefficients from phase improvement (i.e. DENSITY MODIFIED PHASES)" \
      HKLINwrk     "HLA" HLAwrk  [list HLA] \
      -dependent   "HLB" HLBwrk  [list HLB] \
      -dependent   "HLC" HLCwrk  [list HLC] \
      -dependent   "HLD" HLDwrk  [list HLD] \
      -toggle_display USEPHIW open 0

  CreateLabinLine line \
      "Choose phi/fom" \
      HKLINwrk "PHI" PHIwrk  [list PHIB] \
      -sigma   "FOM" FOMwrk  [list FOM ] \
      -toggle_display USEPHIW open 1

  CreateLabinLine line \
      "Choose F/phi" \
      HKLINwrk "F"   FMAPwrk    [list FWT ] \
      -sigma   "PHI" PMAPwrk    [list PHWT] \
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

  OpenSubFrame pdbinwrk \
      -toggle_display USEXYZIN_ha open 1

  CreateInputFileLine line \
      "Enter input heavy atom coordinate file to determine NCS operators." \
      "Work HA PDB in" \
      XYZIN_ha DIR_XYZIN_ha
  
  CloseSubFrame

  OpenSubFrame pdbinwrk \
      -toggle_display USEXYZIN_mr open 1

  CreateInputFileLine line \
      "Enter input molecular replacement or partial coordinate file to determine NCS operators." \
      "Work MR PDB in" \
      XYZIN_mr DIR_XYZIN_mr
  
  CloseSubFrame

  CreateLine line \
      label "Results for work structure:" -italic

  CreateOutputFileLine line \
      "Enter output mtz file name for (unsolved) work structure" \
      "Work MTZ out" \
      HKLOUT DIR_HKLOUT

  CreateLine line \
      message "Output column label prefix (colout)" \
      help colout \
      label "Output column label prefix" \
      widget COLOUT -width 12

#-----------------------------------------------------

  OpenFolder 1 open

  CreateLine line \
      message "Number of cycles of phase improvement to run" \
      help cycles \
      label "Number of cycles of phase improvement to run:" \
      widget NCYCLE -width 4

  OpenSubFrame seqinwrk \
      -toggle_display USESEQINwrk open 0

  CreateLine line \
      message "Enter solvent content as a fraction of the unit cell (between 0.00 and 1.00)" \
      label "Solvent content" \
      widget SOLC -width 4 \
      label "as a fraction of the unit cell." -italic

  CloseSubFrame

#-----------------------------------------------------

  OpenFolder 2 closed

  CreateLine line \
      message "Perform solvent flattening" \
      widget DOSOLV -width 4 \
      label "Solvent flattening.  " \
      message "Perform histogram matching" \
      widget DOHIST -width 4 \
      label "Histogram matching." \
      message "Perform NCS averaging" \
      widget DONCSA -width 4 \
      label "NCS averaging."

  CreateLine line \
      message "Correct any anisotropy in the input data" \
      help anisotropy-correction \
      widget DOANIS -width 4 \
      label "Apply anisotropy correction to input data."

  CreateLine line \
      message "It may be useful to truncate the data if high resolution data is unreliable." \
      help resolution \
      label "Truncate data beyond resolution limit/Angstroms:" \
      widget RESOLUTION_MAX -width 4

  CreateLine line \
      message "Increase this for very poor or low resolution data." \
      help ncs-filter-radius \
      label "Radius for NCS mask determination/Angstroms:" \
      widget NCSRAD -width 4

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

  CreateLine line \
      label "Additional Keywords:" -italic

  CreateExtendingFrame N_KEYS parrot_keyword \
        "Add/remove line to define extra keyword" \
        "Add keyword" \
        [ list KEYS ]
}
