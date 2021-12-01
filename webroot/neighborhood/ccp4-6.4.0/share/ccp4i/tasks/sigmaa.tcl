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
# sigmaa.tcl --
#
# CCP4Interface
#
# ======================================================================

#-----------------------------------------------------------------------
proc sigmaa_setup { typedefVar arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array
  upvar #0 $typedefVar typedef

  set typedef(_sigmaa_calc_type) {menu { \
                     "phase using partial structure information" \
                     "combine isomorphous phase with partial structure" \
                     "combine two sets of MIR phases" } \
                     { PART COMB_PART COMB_MIR } }

  return 1
}

#-----------------------------------------------------------------------
proc sigmaa_nps_labout { arrayname counter } {
#-----------------------------------------------------------------------

    if {$counter >  2 } {
       set array(NPS) 2
       return
    }

  CreateLabinLine line \
     "Computed amplitude (FC) and sigma (PHIC)" \
     HKLIN Fcalc  FCN  FCN \
     -sigma Phase PHICN  PHICN

  CreateLine line \
      message "default value 1.0" \
      label "Damping for additional partial structure" \
      widget DAMPN

}
#-----------------------------------------------------------------------
proc sigmaa_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
        "Improved Fourier coefficients using calculated phases" "Sigmaa" \
        [ list "Additional Partial Structures" \
	"Program Parameters" \
        "Output MTZ Column Labels" \
	"Output and monitoring" \
        ] ] == 0 } return

  SetProgramHelpFile sigmaa

#=PROTOCOL==============================================================

  OpenFolder protocol

  CreateTitleLine line TITLE

  CreateLine line \
    label "Combination required " \
    widget SIGMAA_ACTION

  CreateLine line \
    widget USE_HL \
    label "Input Hendrickson-Lattman coefficients" \
    toggle_display SIGMAA_ACTION open [list COMB_PART COMB_MIR] 

  CreateLine line \
    widget USE_SFALL \
    label "Generate structure factors using SFALL" \
    toggle_display SIGMAA_ACTION open [list PART COMB_PART]

#=FILES================================================================

  OpenFolder file


  CreateInputFileLine line \
    "Enter input MTZ file name (HKLIN)" \
    "MTZ in" \
    HKLIN DIR_HKLIN \
     -setfileparam space_group_name SIGMAA_SPACE_GROUP \
     -setfileparam resolution_min RESOLUTION_MIN \
     -setfileparam resolution_max RESOLUTION_MAX \
     -setfileparam cell CELL \
     -fileout HKLOUT DIR_HKLOUT _sigmaa

  CreateLabinLine line \
    "Choose amplitude (FP) and sigma (SIGFP)" \
    HKLIN FP  FP  FP \
     -sigma Sigma SIGFP  SIGFP

  OpenSubFrame frame -toggle_display SIGMAA_ACTION open  COMB_PART

  CreateLabinLine line \
    "MIR phase (PHIBP) and weight (WP)" \
    HKLIN PHIBP  PHIBP PHIBP \
     -sigma FoM WP  WP \

   OpenSubFrame frame -toggle_display USE_HL open 1

   CreateLabinLine line \
     "Hendrickson-Lattman probability coeffs." \
     HKLIN A HLA HLA \
     -sigma B HLB HLB

    CreateLabinLine line \
     "Hendrickson-Lattman probability coeffs." \
     HKLIN C HLC HLC \
     -sigma D HLD HLD

   CloseSubFrame

  CloseSubFrame

  OpenSubFrame frame -toggle_display SIGMAA_ACTION open [list PART COMB_PART]

    CreateLabinLine line \
      "Computed amplitude (FC) and sigma (PHIC)" \
      HKLIN Fcalc  FC  FC \
       -sigma Phase PHIC  PHIC \
       -toggle_display USE_SFALL open 0

    CreateLabinLine line \
      "Choose Free R column data (LABIN FREER)" \
      HKLIN FreeR FREE  [list FREE FreeR FreeR_flag]


  OpenSubFrame frame -toggle_display USE_SFALL open 1

  CreateInputFileLine line \
    "Enter input coordinate file name (XYZIN)" \
    "PDB in" \
    XYZIN DIR_XYZIN \

    CreateLaboutLine line \
      "Enter names for output column labels for calculated Fs and PHIs (LABOUT)"\
      HKLOUT Fcalc SFALL_FC \
       -sigma PHIcalc SFALL_PHIC

    CloseSubFrame
  CloseSubFrame


  OpenSubFrame frame -toggle_display SIGMAA_ACTION open COMB_MIR

    CreateLine line \
     label "Data for first MIR phases" -italics

    CreateLabinLine line \
      "Centroid phase (PHIBP) and figure of merit (WP)" \
      HKLIN "PhiB"  PHIBP PHIBP \
       -sigma FoM WP  WP
   
    OpenSubFrame frame -toggle_display USE_HL open 1

    CreateLabinLine line \
     "Hendrickson-Lattman probability coeffs." \
     HKLIN A HLA HLA \
     -sigma B HLB HLB

    CreateLabinLine line \
     "Hendrickson-Lattman probability coeffs." \
     HKLIN C HLC HLC \
     -sigma D HLD HLD

    CloseSubFrame


    CreateLine line \
      label "Data for second MIR phases" -italics

    CreateLabinLine line \
      "Centroid phase and FoM for second set" \
      HKLIN "PhiB" PHIB2 PHIB2 \
       -sigma FoM W2  W2

    OpenSubFrame frame -toggle_display USE_HL open 1

    CreateLabinLine line \
     "Hendrickson-Lattman probability coeffs." \
     HKLIN A HLA2 HLA2 \
     -sigma B HLB2 HLB2

    CreateLabinLine line \
     "Hendrickson-Lattman probability coeffs." \
     HKLIN C HLC2 HLC2 \
     -sigma D HLD2 HLD2

   CloseSubFrame

  CloseSubFrame

  CreateOutputFileLine line \
    "Enter name of output file (HKLOUT)" \
    "Output" HKLOUT DIR_HKLOUT \
     -help notes_on_hklout


#=PARAMETERS2=========================================================

  OpenFolder 1 SIGMAA_ACTION closed COMB_PART hide

    CreateExtendingFrame NPS sigmaa_nps_labout \
      "Partial structures" "Add partial structure (max. 2)" \
      [list FCN PHICN DAMPN ]


  OpenFolder 2

  CreateLine line \
    message "Exclude reflections below and/or above resolution limit in \
                  Angstrom (RESOLUTION)" \
    help resolution \
    widget  SIGMAA_RESOLUTION  -toggleon \
    label "Resolution less than" \
    widget RESOLUTION_MIN  \
    label "A or greater than" \
    widget RESOLUTION_MAX  \
    label "A"

  CreateLine line \
    message "Space group (default as in MTZ file) (SYMMETRY)" \
    label "Generate map in space group" \
    help symmetry \
    widget SIGMAA_SPACE_GROUP

  CreateLine line \
    message "Number of resolution bins (max. 50)" \
    label "Number of bins " \
    widget RANGES_NBIN 

  OpenSubFrame frame -toggle_display SIGMAA_ACTION open [list COMB_PART PART ]
  CreateLine line \
    message "default value 1.0" \
    label "Damping for partial structure" \
    widget DAMP 

  CloseSubFrame

  OpenSubFrame frame -toggle_display USE_SFALL open 1

  CreateLine line \
    message "Cell dimensions (default from MTZ file) (CELL)" \
    help "cell" \
    widget IFCELL \
        -toggleon \
    label "Set cell a" \
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

  CloseSubFrame

#=====================================================================

  OpenFolder 3 closed
  OpenSubFrame frame -toggle_display SIGMAA_ACTION open PART

    CreateLaboutLine line \
      "Figure of merit m (Sim weight)" \
      HKLOUT "FoM " WCMB

    CreateLaboutLine line \
      "Fourier Amplitude for difference map (mFo-DFc)" \
      HKLOUT "mF-Df " DELFWT

    CreateLaboutLine line \
      "Fourier Amplitude for 2Fo-Fc map (2mFo-DFc)" \
      HKLOUT "2mF-Df " FWT

  CloseSubFrame

  OpenSubFrame frame -toggle_display SIGMAA_ACTION open COMB_MIR

    CreateLaboutLine line \
      "Combined phase angle and weight" \
      HKLOUT "Phase " PHCMB \
       -sigma "FoM " WCMB

  OpenSubFrame frame -toggle_display USE_HL open 1

    CreateLaboutLine line \
      "Hendrick-Lattman Coeff" \
      HKLOUT "A " HLAC \
       -sigma "B " HLBC

    CreateLaboutLine line \
      "Hendrick-Lattman Coeff" \
      HKLOUT "C " HLCC \
       -sigma "D " HLDC

  CloseSubFrame
  CloseSubFrame

  OpenSubFrame frame -toggle_display SIGMAA_ACTION open COMB_PART

    CreateLaboutLine line \
      "Combined Phase and weight" \
      HKLOUT "Phase " PHCMB \
       -sigma "FoM " WCMB

    CreateLaboutLine line \
      "Fourier Amplitude for difference map (mFo-DFc) and Phase" \
      HKLOUT "mF-Df " DELFWT \
       -sigma "Phase " PHDELFWT

    CreateLaboutLine line \
      "Fourier Amplitude for 2Fo-Fc map (2mFo-DFc) and Phase" \
      HKLOUT "2mF-Df " FWT \
       -sigma "Phase " PHFWT

  CloseSubFrame


#=PARAMETERS3=========================================================

  OpenFolder 4  closed

  CreateLine line \
    message "Output every nth reflection" \
    label "Monitoring interval" \
    widget RANGES_MON 

  CreateLine line \
    message "Estimate the rms coordinate error" \
    widget SIGMAA_ERROR \
    label "Undertake error analysis"

}

