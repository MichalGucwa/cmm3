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
# dmmulti.tcl --
#
# Rum DMMulti
#
# CCP4Interface 
#
# =======================================================================


#--------------------------------------------------------------------
proc dmmulti_setup { typedefVar arrayname } {
#--------------------------------------------------------------------

upvar #0 $typedefVar typedef

set typedef(_dm_phase_comb)     {menu  { "omit" \
                                        "perturbation" }
                                        { OMIT
                                          "PERT" } }

set typedef(_dm_scheme)		{ menu { "automated phase extension"
					"phase extension in resolution steps"
					"phase extension in magnitude steps"
					"phase extension in FOM steps" }
					{ AUTO RES MAG FOM } }

set typedef(_dm_wang_mode)	{ menu { "constant"
					 "w=1-(r/R) Wang's method"
					 "w=1-(r/R)**2" } 
					{ 0 1 2 } }

set typedef(_dm_skel_cycles)            { int 3 2 100 NOTOBLIG {} }

set typedef(_dm_ncs_nops)               { int 3 1 12 NOTOBLIG {} }

set typedef(_dm_ndomains)               { int 3 0 6 NOTOBLIG {} }

set typedef(_dm_vuout_format)		{ menu { O XtalView } { vu odat } }

set typedef(_dmmulti_dom_menu)		{ varmenu DMMULTI_DOM_MENU 1 3 }

set typedef(_dm_ncross)			{ menu { "changing random set of hkl"
						"fixed set of hkl run separately"
						"multiple free-R sets" }
					{ RANDOM FIXED MULTI } }

  return 1

}

#--------------------------------------------------------------------
proc dmmulti_run { arrayname } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(INPUT_FILES) ""
  set array(OUTPUT_FILES) ""
  for { set n  1 } { $n <= $array(NCRYSTALS) } { incr n } {
    if $array(SOLVENT_MASK_MODE,$n)  {
      append array(INPUT_FILES) "HKLIN,$n  SOLIN,$n "
      append array(OUTPUT_FILES) "HKLOUT,$n "
    } else {
      append array(INPUT_FILES) "HKLIN,$n "
      append array(OUTPUT_FILES) "HKLOUT,$n SOLOUT,$n "
    }
    set array(LABIN,$n) "FP SIGFP PHIO FOMO"
    set array(LABOUT,$n) "PHIDM FOMDM"
    if { $array(USE_HL,$n) } { 
      append array(LABIN,$n) " HLA HLB HLC HLD" 
#      append array(LABOUT,$n) " HLADM HLBDM HLCDM HLDDM"
    }
  }
  for { set n  1 } { $n <= $array(NDOMAINS) } { incr n } {
    if { [file exists [GetFullFileName0 $arrayname MASKIN,$n]] } {
      append array(INPUT_FILES) "MASKIN,$n "
    }
  }

  set id $array(LABOUT_ID)
  set array(PHIDM) "PHI$id"
  set array(FOMDM) "FOM$id"
  set array(HLADM) "HLA$id"
  set array(HLBDM) "HLB$id"
  set array(HLCDM) "HLC$id"
  set array(HLDDM) "HLD$id"

  return 1

}


#======================================================================
proc DmDomainFrame { arrayname counter } {
#======================================================================
  upvar #0 $arrayname array

# update the variable menu used in the xtal definitions
  if { $counter == 1 } { set mode initialise } else { set mode append }
  UpdateVariableMenu $arrayname $mode $counter DMMULTI_DOM_MENU  $counter

  CreateInputFileLine line \
        "Enter name of optional domain mask file " \
        "Domain mask" \
        MASKIN DIR_MASKIN \
	-help files \
	-toggle_display NCSMASK hide 1  \
	-notoblig 

}


# ==================================================================
proc DmDomainOpsFrame { arrayname counter domain  } {
# ==================================================================
  upvar #0 $arrayname array

#  puts "DmDomainOpsFrame domain $domain"
  if { $counter == 1 && $domain == 1 } {
    set array(NCS_OP_DOM,1_$counter) 1
    set array(NCS_OP_ALPHA,1_$counter) 0.0
    set array(NCS_OP_BETA,1_$counter) 0.0
    set array(NCS_OP_GAMMA,1_$counter) 0.0
    set array(NCS_OP_XTRAN,1_$counter) 0.0
    set array(NCS_OP_YTRAN,1_$counter) 0.0
    set array(NCS_OP_ZTRAN,1_$counter) 0.0
  }

   CreateLine ops_frame \
        message "Enter Averaging Operator (ROTA EULER & TRAN)" \
	help average \
        widget NCS_OP_DOM \
        widget NCS_OP_ALPHA -oblig \
        widget NCS_OP_BETA -oblig \
        widget NCS_OP_GAMMA -oblig \
        widget NCS_OP_XTRAN -oblig \
        widget NCS_OP_YTRAN -oblig \
        widget NCS_OP_ZTRAN -oblig \
	format template NCSOPS

}

#----------------------------------------------------------------
proc DmCrystalFrame { arrayname counter } {
#----------------------------------------------------------------

  CreateLine line \
    label "Crystal number $counter" -italic

  CreateLine line \
    message "Use  pre-determined solvent mask (SOLIN) " \
    help files \
    widget SOLVENT_MASK_MODE \
    label "Input a solvent mask   " \
    help labin \
    widget USE_HL \
    label "Input Hendrickson-Lattman coefficients"


  CreateInputFileLine line \
    "Enter input MTZ file name (HKLIN$counter)" \
    "MTZ in" \
    HKLIN DIR_HKLIN \
    -help files \
    -fileout HKLOUT,$counter DIR_HKLOUT,$counter "_dmmulti" \
    -fileout SOLOUT,$counter DIR_SOLOUT,$counter "_dmmulti"

  CreateLabinLine line \
    "Choose amplitude (FP) and essential sigma (SIGFP)" \
     HKLIN,$counter "FP"  FP  {} \
     -sigma "SIGFP" SIGFP  {} \
     -help labin

  CreateLabinLine line \
    "Choose phase (PHIO) and essential weighting factor (FOMO)" \
     HKLIN,$counter "PHIO" PHIO  {} \
     -sigma "Weight" FOMO  {} \
     -help labin

  OpenSubFrame frame \
        -toggle_display USE_HL,$counter open 1

  CreateLabinLine line \
    "Choose Hendrickson-Lattman coefficients" \
     HKLIN,$counter "HLA" HLA  HLA\
     -sigma "HLB" HLB  HLB \
     -help labin

  CreateLabinLine line \
    "Choose Hendrickson-Lattman coefficients" \
     HKLIN,$counter "HLC" HLC  HLC\
     -sigma "HLD" HLD  HLD \
     -help labin

  CloseSubFrame

  CreateOutputFileLine line \
      "Enter name of output MTZ file (HKLOUT$counter)" \
      "MTZ out" \
      HKLOUT DIR_HKLOUT \
     -help files

  CreateInputFileLine line \
        "Enter name of input solvent mask file (SOLIN$counter)" \
        "Solvent in" \
        SOLIN DIR_SOLIN \
        -help files \
        -toggle_display SOLVENT_MASK_MODE,$counter hide 0

  CreateOutputFileLine line \
      "Enter name of output solvent mask file (SOLOUT$counter)" \
        "Solvent out" \
        SOLOUT DIR_SOLOUT \
        -toggle_display SOLVENT_MASK_MODE,$counter hide 1 \
        -help files

}

#--------------------------------------------------------------------
proc DmSolvent { arrayname counter } {
#--------------------------------------------------------------------

  CreateLine line \
    label "Describe Crystal $counter" -italic

  CreateLine line \
    message "Set maximum range of the phase extension (RESOLUTION)" \
    help resolution \
    label "Use reflections in range" \
    widget RESOLUTION_MIN \
    label to \
    widget RESOLUTION_MAX \

  CreateLine line \
    message "Fraction of unit cell which is solvent (SOLC)" \
    help solc \
    label "Fraction solvent content" \
    widget SOLVENT_FRAC -oblig 

  CreateLine line \
    widget XTAL_REFINE_OP \
    label "Refine the averaging operators for this crystal"

  CreateLine line \
    help average \
    label domain -italic \
    label "alpha" -italic \
    label "beta" -italic \
    label "gamma" -italic \
    label "xtran" -italic \
    label "ytran" -italic \
    label "ztran" -italic \
    format template NCSOPS

  CreateExtendingFrame NCS_NOPS DmDomainOpsFrame \
        "Add/remove line to define extra averaging operator" \
        "Add operator" \
        [ list NCS_OP_DOM \
        NCS_OP_ALPHA \
        NCS_OP_BETA \
        NCS_OP_GAMMA \
        NCS_OP_XTRAN \
        NCS_OP_YTRAN \
        NCS_OP_ZTRAN ] \
        -counter $counter


}

#--------------------------------------------------------------------
proc DmSolventMasks { arrayname counter } {
#--------------------------------------------------------------------

  CreateLine line \
    label "Creating solvent mask for crystal $counter" -italic

  CreateLine line \
    message "Set alternative mask volumes for histogram matching and solvent flattening" \
    help solc_mask \
    label "Histogram and solvent flattening mask solvent fraction" \
    widget SOLC_MASK_SOLV \
    label "and protein fraction" \
    widget SOLC_MASK_PROT

  CreateLine line \
    message "Set mean density for solvent and protein regions(SOLC MEAN)" \
    label "Mean density of solvent" \
    help solc_mean \
    widget SOLC_MEAN_SOLVVAL \
    label "and protein" \
    widget SOLC_MEAN_PROTVAL

}


#--------------------------------------------------------------------
proc dmmulti_task_window {arrayname} {
#--------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow  $arrayname \
 	"Run DmMulti - Multi-Crystal Density Modification" "DmMulti" \
        [list "Describe Domains" \
	"Describe Crystals" \
	"Solvent Mask Options" \
	"Infrequently Used Parameters" ] ] == 0 } return

#  WriteCredits [list {Kevin Cowtan}] -link "Kevin's Home Page" \
#	"http://www.ysbl.york.ac.uk/~cowtan" 

  SetDefaultMapFormat $arrayname MAPOUT_FORMAT
  CreateLineTemplate NCSOPS [list 0.0 0.10 0.25 0.40 0.55 0.70 0.85]
  CreateLineTemplate NCSREF [list 0.0 0.6 0.65]


#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
        message "Choose the mode(s) of density modification (MODE)" \
        label "Select density modification modes" \
                -italic

  CreateLine line \
        message "Choose the mode(s) of density modification (MODE)" \
        help mode \
        widget DM_SOLVENT \
        label "Solvent" \
        widget DM_HISTOGRAM \
        label "Histogram" \
	widget DM_AVERAGING \
	label Averaging

  CreateLine line \
    message "Choose phase extension scheme (SCHEME)" \
    help scheme \
    label Do \
    widget DM_SCHEME \
    toggle_display DM_SCHEME open AUTO

  CreateLine line \
    message "Choose phase extension scheme (SCHEME)" \
    help scheme_res \
    label Do \
    widget DM_SCHEME \
    label "starting at resolution" \
    widget DM_SCHEME_RES -oblig \
    toggle_display DM_SCHEME open RES

  CreateLine line \
    message "Choose phase extension scheme (SCHEME)" \
    help scheme_frac \
    label Do \
    widget DM_SCHEME \
    label "starting with "  \
    widget DM_SCHEME_FRAC -oblig \
    label "fraction of reflections" \
    toggle_display DM_SCHEME hide [list RES AUTO]

  CreateLine line \
    message "Number of cycles of phase extension (NCYCLE)" \
    help ncycle \
    label Do \
    widget DM_NCYCLES \
    label "cycles of phase extension using FreeR set:" \
    widget DM_NCROSS_MODE \
    widget DM_NCROSS_NSETS \
    toggle_display DM_NCROSS_MODE open MULTI

  CreateLine line \
    message "Number of cycles of phase extension (NCYCLE)" \
    help ncycle \
    label Do \
    widget DM_NCYCLES \
    label "cycles of phase extension using FreeR set:" \
    widget DM_NCROSS_MODE \
    toggle_display DM_NCROSS_MODE hide MULTI

  CreateLine line \
    message "Enter text for output label (eg entering 'DM' gives output labels 'FDM' etc)" \
    help labout \
    label "Output label identifier" \
    widget LABOUT_ID
   


#=FILES================================================================

  OpenFolder file 

  CreateExtendingFrame NCRYSTALS DmCrystalFrame \
    "Enter names of one MTZ file  per crystal" \
    "Add MTZ File" \
    [ list HKLIN DIR_HKLIN HKLOUT DIR_HKLOUT SOLIN DIR_SOLIN \
	SOLOUT DIR_SOLOUT SOLVENT_MASK_MODE USE_HL  \
	LABIN FP SIGFP PHIO FOMO HLA HLB HLC HLD ] \
	-dependentframe DmSolvent \
	-dependentframe DmSolventMasks


#----------------------------------------------------------Domain definitions

  OpenFolder 1

  CreateToggleFrame  NDOMAINS  DmDomainFrame \
                "Open another domain frame"  "Domain number" \
                "Add domain" \
              [list MASKIN \
                DIR_MASKIN ]

#----------------------------------------------------------Xtal definitions

  OpenFolder 2

 CreateExtendingFrame NCRYSTALS DmSolvent  \
    "Solvent content of each crystal" \
    " " [list SOLVENT_FRAC SOLC_MASK_SOLV SOLC_MASK_PROT \
        SOLC_MEAN_PROTVAL SOLC_MEAN_SOLVVAL \
	RESOLUTION_MIN RESOLUTION_MAX XTAL_REFINE_OP NCS_NOPS ] -noaddline \
	-child DmDomainOpsFrame


#--------------------------------------------------------------Solvent mask
  OpenFolder 3 DM_SOLVENT closed 1 hide

  CreateLine line \
    message "Default enter no radius and program will derive value" \
    help wang \
    label "Use Wang with radius" \
    widget WANG_RADIUS \
    label "and weighting scheme" \
    widget WANG_MODE

  CreateLine line \
    message "Set a rho max to truncate heavy atoms" \
    help wang \
    label "set rho cutoffs, minimum" \
    widget WANG_RHO_MIN \
    label maximum \
    widget WANG_RHO_MAX


 CreateExtendingFrame NCRYSTALS DmSolventMasks  \
    "Creating solvent masks" \
    " " [list SOLC_MASK_SOLV SOLC_MASK_PROT \
        SOLC_MEAN_PROTVAL SOLC_MEAN_SOLVVAL ] \
	-noaddline 

    
#------------------------------------------------------------------Infrequent
  OpenFolder 4 closed

  CreateLine line \
    message "NOT recommended to override the scale! (SCALE)" \
    help scale \
    label "Overide internal scaling for histogram maps, Bfactor" \
    widget SCALE_BFAC \
    label "and scale" \
    widget SCALE_SCALE

  CreateLine line \
        message "Use non-default map grid (GRID)" \
	help grid \
	widget GRID \
	-toggleon \
	label "Map grid  nx"\
	widget GRID_1 \
	label "ny" \
	widget GRID_2 \
	label "nz" \
	widget GRID_3

}
