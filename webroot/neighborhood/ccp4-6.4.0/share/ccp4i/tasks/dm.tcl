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
# dm.tcl --
#
# Rum DM Density Modification
#
# CCP4Interface 
#
# =======================================================================


#--------------------------------------------------------------------
proc dm_setup { typedefVar arrayname } {
#--------------------------------------------------------------------

upvar #0 $typedefVar typedef

set typedef(_dm_phase_comb)     {menu  { "omit" \
                                        "perturbation" }
                                        { OMIT
                                          "PERT" } }

set typedef(_dm_scheme)		{ menu { "all reflections"
					"automated phase extension"
					"phase extension in resolution steps"
					"phase extension in magnitude steps"
					"phase extension in FOM steps" }
					{ ALL AUTO RES MAG FOM } }
set typedef(_dm_wang_mode)	{ menu { "constant"
					 "w=1-(r/R) Wang's method"
					 "w=1-(r/R)**2" } 
					{ 0 1 2 } }

set typedef(_dm_skel_cycles)            { int 3 2 100 NOTOBLIG {} }

set typedef(_dm_ncs_nops)               { int 3 1 30 NOTOBLIG {} }

set typedef(_dm_ndomains)               { int 3 0 6 NOTOBLIG {} }

set typedef(_dm_vuout_format)		{ menu { O XtalView } { odat vu } }

set typedef(_dm_ncs_op_type)            { menu { "euler angles"
					         "polar angles"
					         "rotation matrix"
                                                 "O matrix" }
                                               { EULER
                                                 POLAR
                                                 MATRIX
						   OMAT } }

  return 1

}


# procedure run before script is written

#--------------------------------------------------------------------
proc dm_run { arrayname } {
#--------------------------------------------------------------------

  upvar #0 $arrayname array

  if $array(SOLVENT_MASK_MODE)  {
    set array(INPUT_FILES) "HKLIN MASKIN"
    set array(OUTPUT_FILES) "HKLOUT"
  } else {
    set array(INPUT_FILES) "HKLIN"
    set array(OUTPUT_FILES) "HKLOUT MASKOUT"
  }

  set array(LABIN) "FP SIGFP PHIO FOMO"
  if { $array(USE_HL) } {
      # Check that the same labels have not been assigned
      # twice accidentally
      if { [ DmCheckHLCoeffs $arrayname [ list HLA HLB HLC HLD ] ] == 0 } \
	      { return 0 }
      # Add input HL coefficients to LABIN
      append array(LABIN) " HLA HLB HLC HLD"
  }

  set id $array(LABOUT_ID)
  set array(FDM) "F$id"
  set array(PHIDM) "PHI$id"
  set array(FOMDM) "FOM$id"
  set array(HLADM) "HLA$id"
  set array(HLBDM) "HLB$id"
  set array(HLCDM) "HLC$id"
  set array(HLDDM) "HLD$id"

  set array(LABOUT) "FDM PHIDM FOMDM"
  if { $array(USE_HL) } { append array(LABOUT) " HLADM HLBDM HLCDM HLDDM" }

  if { $array(IF_SOLMASK_WANG) && $array(WANG_RADIUS) == "" } {
     set array(WANG_RADIUS) -0.0
  }

  if { $array(SOLMASK_FRAC_SOLV) != "" && $array(SOLMASK_FRAC_PROT) == "" } {
   set array(SOLMASK_FRAC_PROT) [expr 1.0 - $array(SOLMASK_FRAC_SOLV)]
  }
  
  if { ![SetHarvestParams $arrayname HKLIN  -run] } { return 0 }

  return 1

}

#---------------------------------------------------------------------
proc DmCheckHLCoeffs { arrayname labellist } {
#---------------------------------------------------------------------
# Procedure to check that the names supplied for input
# Hendrickson-Lattman coefficients have been uniquely assigned. If not
# then a warning dialogue is issued allowing the user to either proceed
# with the non-unique assignments (in which case 1 is returned) \
# or abort the run (0 is returned).
# A copy of this procedure also appears in the refmac5 interface.

  upvar #0 $arrayname array

    # Check that the same labels have not been assigned
    # twice accidentally
    set hl_list "" 
    foreach label $labellist {
	if { [lsearch $hl_list $array($label)] < 0 } {
	    lappend hl_list $array($label)
	}
    }
    # If the list has less than 4 elements then they were
    # not all unique
    if { [llength $hl_list] < 4 } {
	set action [ChooseOptionDialog "Hendrickson-Lattman Coefficients" "Dm" \
"Labels for the Hendrickson-Lattman coefficients taken from\nthe input file have not been set uniquely\n\nYou can proceed with the current assignments, or abort the run\nand reassign the labels" \
        { Abort OK } -default 1 ]
    if [regexp Abort $action] { return 0 }
    }
    return 1
}

#======================================================================
proc DmDomainFrame { arrayname counter } {
#======================================================================
  upvar #0 $arrayname array

#  puts "DmDomainFrame $counter "

  CreateInputFileLine line \
        "Enter name of optional NCS mask file " \
        "NCS mask" \
        NCS_MASK_FILE DIR_NCS_MASK_FILE \
	help ncsmask \
	-toggle_display NCSMASK hide 1  \
	-notoblig

  CreateLineTemplate NCSREF [list 0.0 0.6 0.65]
  CreateLineTemplate NCSOPS [list 0.05 0.20 0.35 0.50 0.65 0.80]

  CreateLine line \
        message "Refine averaging operator for this mask? (AVERAGE REF)" \
        help keywords_averaging \
        label "Enter averaging operators below" \
        widget NCS_REFINE_OP \
        label "Refine averaging operators?" \
	format template NCSREF

  CreateLine line \
        label "alpha" -italic \
        label "beta" -italic \
        label "gamma" -italic \
        label "xtran" -italic \
        label "ytran" -italic \
        label "ztran" -italic \
        format template NCSOPS \
        toggle_display NCS_OP_TYPE open [list EULER]

  CreateLine line \
        label "omega" -italic \
        label "phi"   -italic \
        label "kappa" -italic \
        label "xtran" -italic \
        label "ytran" -italic \
        label "ztran" -italic \
        format template NCSOPS \
        toggle_display NCS_OP_TYPE open [list POLAR]

  CreateLine line \
        label "Rotation matrix in CCP4 convention:" -italic \
        toggle_display NCS_OP_TYPE open [list MATRIX]

  CreateLine line \
        label "Rotation matrix in O convention (i.e. transposed wrt to CCP4 convention):" -italic \
        toggle_display NCS_OP_TYPE open [list OMAT]

  CreateExtendingFrame NCS_NOPS DmDomainOpsFrame \
	"Add line to define extra averaging operator (max 30)" \
	"Add operator" \
        [ list NCS_OP_ALPHA \
	NCS_OP_BETA \
	NCS_OP_GAMMA \
	NCS_OP_XTRAN \
	NCS_OP_YTRAN \
	NCS_OP_ZTRAN \
        NCS_OP_R11 \
        NCS_OP_R12 \
        NCS_OP_R13 \
        NCS_OP_R21 \
        NCS_OP_R22 \
        NCS_OP_R23 \
        NCS_OP_R31 \
        NCS_OP_R32 \
        NCS_OP_R33 ] \
	-counter $counter

}

proc dm_phase_comb { arrayname } {
  upvar #0 $arrayname array
  if { [GetValue $arrayname PHASE_COMB ] == "OMIT" } {
    SetValue $arrayname DM_SCHEME ALL
    set array(DM_NCYCLES_NOT_AUTO) 0
  }
}

# ==================================================================
proc DmDomainOpsFrame { arrayname counter domain  } {
# ==================================================================
  upvar #0 $arrayname array
  CreateLineTemplate NCSOPS [list 0.05 0.20 0.35 0.50 0.65 0.80]

#  puts "DmDomainOpsFrame domain $domain"
  if { $counter == 1 } {
    set array(NCS_OP_ALPHA,[subst $domain]_$counter) 0.0
    set array(NCS_OP_BETA,[subst $domain]_$counter) 0.0
    set array(NCS_OP_GAMMA,[subst $domain]_$counter) 0.0
    set array(NCS_OP_XTRAN,[subst $domain]_$counter) 0.0
    set array(NCS_OP_YTRAN,[subst $domain]_$counter) 0.0
    set array(NCS_OP_ZTRAN,[subst $domain]_$counter) 0.0
    set array(NCS_OP_R11,[subst $domain]_$counter) "1.0"
    set array(NCS_OP_R12,[subst $domain]_$counter) "0.0"
    set array(NCS_OP_R13,[subst $domain]_$counter) "0.0"
    set array(NCS_OP_R21,[subst $domain]_$counter) "0.0"
    set array(NCS_OP_R22,[subst $domain]_$counter) "1.0"
    set array(NCS_OP_R23,[subst $domain]_$counter) "0.0"
    set array(NCS_OP_R31,[subst $domain]_$counter) "0.0"
    set array(NCS_OP_R32,[subst $domain]_$counter) "0.0"
    set array(NCS_OP_R33,[subst $domain]_$counter) "1.0"
  }

   CreateLine ops_frame \
        message "Enter Averaging Operator (ROTA EULER/POLAR & TRAN). Translation in Angstrom." \
	help keywords_averaging \
        widget NCS_OP_ALPHA -oblig \
        widget NCS_OP_BETA -oblig \
        widget NCS_OP_GAMMA -oblig \
        widget NCS_OP_XTRAN -oblig \
        widget NCS_OP_YTRAN -oblig \
        widget NCS_OP_ZTRAN -oblig \
	format template NCSOPS \
        toggle_display NCS_OP_TYPE open [ list EULER POLAR ]

   CreateLine ops_frame \
        message "Enter Averaging Operator matrix (ROTA MATRIX/OMAT)" \
        widget NCS_OP_R11 -oblig \
        widget NCS_OP_R12 -oblig \
        widget NCS_OP_R13 -oblig \
        format template NCSMAT \
        toggle_display NCS_OP_TYPE open [ list MATRIX OMAT ]

   CreateLine ops_frame \
        message "Enter Averaging Operator matrix (ROTA MATRIX/OMAT)" \
        widget NCS_OP_R21 -oblig \
        widget NCS_OP_R22 -oblig \
        widget NCS_OP_R23 -oblig \
        format template NCSMAT \
        toggle_display NCS_OP_TYPE open [ list MATRIX OMAT ]

    CreateLine ops_frame \
        message "Enter Averaging Operator matrix (ROTA MATRIX/OMAT)" \
        widget NCS_OP_R31 -oblig \
        widget NCS_OP_R32 -oblig \
        widget NCS_OP_R33 -oblig \
        format template NCSMAT \
        toggle_display NCS_OP_TYPE open [ list MATRIX OMAT ]

    CreateLine line \
        message "Enter Averaging Operator translation" \
        label "xtran" \
        widget NCS_OP_XTRAN -oblig \
        label "ytran" \
        widget NCS_OP_YTRAN -oblig \
        label "ztran" \
        widget NCS_OP_ZTRAN -oblig \
	format template NCSOPS \
        toggle_display NCS_OP_TYPE open [ list MATRIX OMAT ]
        

}

#--------------------------------------------------------------------
proc dm_task_window {arrayname} {
#--------------------------------------------------------------------

  upvar #0 $arrayname array

  if { [CreateTaskWindow  $arrayname \
 	"Run DM - Density Modification" "DM" \
        [list "Data Harvesting" \
	     "Required Parameters"  \
	     "Define NCS Symmetry"  \
	     "NCS Averaging" \
	     "Solvent Mask Options" \
	     "Infrequently Used Parameters" ] ] == 0 } return

  SetDefaultMapFormat $arrayname MAPOUT_FORMAT
  SetHarvestParams $arrayname HKLIN -init

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
        label "Averaging"

  OpenSubFrame frame -toggle_display DM_AVERAGING open 1


  CreateLine line \
        message "Use automask in NCS averaging" \
        help ncsmask \
        widget NCSMASK \
        label "Automatically generate NCS mask" 

  CreateLine line \
        message "Create file containing graphical illustration of the NCS operators" \
        widget IFVUOUT \
        label "Create file to display NCS operators in" \
        widget VUOUT_FORMAT \
        label format 

  CloseSubFrame

  CreateLine line \
    message "Phase combination scheme (COMBINE)" \
    help combine \
    label "Phase combination scheme"  \
    widget PHASE_COMB \
          -command "dm_phase_comb $arrayname" \
    label "using" \
    widget DM_SCHEME \
    toggle_display PHASE_COMB hide OMIT

    CreateLine line \
    message "Phase combination scheme (COMBINE)" \
    help combine \
    label "Phase combination scheme"  \
    widget PHASE_COMB \
          -command "dm_phase_comb $arrayname" \
    label "using all reflections" \
    toggle_display PHASE_COMB open OMIT

  CreateLine line \
    message "This option can remove model bias from MR phases if you have NCS" \
    help combine_weight \
    label "For Molecular Replacement phases:" \
    widget NOCOMBINE \
    label "Disable phase combination to remove bias."

  CreateLine line \
    message "Use  pre-determined solvent mask (SOLIN) " \
    help solin \
    widget SOLVENT_MASK_MODE \
    label "Input a solvent mask   " \
    message "These may help " \
    help labin \
    widget USE_HL \
    label "Input Hendrickson-Lattman coefficients" \
    message "e.g. from Phaser or a previous DM calculation" \
    help labin \
    widget USE_COEFFS \
    label "Input starting map coefficients"

  CreateLine line \
        message "Generate map" \
        widget IF_MAPOUT \
	  -toggleon \
        label "Create map file in" \
        widget MAPOUT_FORMAT \
        label "format"


#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
      HKLIN DIR_HKLIN \
      -fileout HKLOUT DIR_HKLOUT "_dm" \
      -fileout MASKOUT DIR_MASKOUT "_dm" \
      -setfileparam resolution_min EXCLUDE_RESOLUTION_MIN \
      -setfileparam resolution_max EXCLUDE_RESOLUTION_MAX \
      -command "UpdateHarvestMTZ $arrayname HKLIN"

  CreateLabinLine line \
    "Choose amplitude (FP) and essential sigma (SIGFP)" \
     HKLIN "FP"  FP  {} \
     -sigma "SIGFP" SIGFP  {}

  CreateLabinLine line \
    "Choose phase (PHIO) and essential weighting factor (FOMO)" \
     HKLIN "PHIO" PHIO  {} \
     -sigma "Weight" FOMO  {}

  CreateLabinLine4 line \
    "Choose Hendrickson-Lattman coefficients (turn off above, if not available)" \
    HKLIN "HLA" HLA  HLA \
     -dependent "HLB" HLB HLB \
     -dependent "HLC" HLC HLC \
     -dependent "HLD" HLD HLD \
     -toggle_display USE_HL open 1

  CreateLabinLine line \
    "Input map coefficients of the starting map (FDM, PHIDM)" \
     HKLIN "FDM" FDMIN  {} \
     -sigma "PHDM" PHIDMIN  {} \
     -toggle_display USE_COEFFS open 1

#  CreateLabinLine line \
#    "Choose FreeR parameter " \
#     HKLIN "FreeR" FREER  {}  \
#     -toggle_display PHASE_COMB hide OMIT
#
       
  CreateOutputFileLine line \
      "Enter name of output MTZ file (HKLOUT)" \
      "MTZ out" \
      HKLOUT DIR_HKLOUT

  CreateLine line \
    message "Enter text for output label (eg entering 'DM' gives output labels 'FDM' etc)" \
    label "Output label identifier" \
    widget LABOUT_ID


  CreateInputFileLine line \
        "Enter name of input solvent mask file (SOLIN)" \
	"Mask in" \
	MASKIN DIR_MASKIN \
	-help solin \
        -toggle_display SOLVENT_MASK_MODE hide 0


  CreateOutputFileLine line \
      "Enter name of output solvent mask file (SOLOUT)" \
	"Mask out" \
	MASKOUT DIR_MASKOUT \
        -toggle_display SOLVENT_MASK_MODE hide 1 \
	-help solout


#=PARAMETERS==========================================================

  OpenFolder 1
  CreateHarvestLine line

  OpenFolder 2

  CreateLine line \
        message "Fraction of unit cell which is solvent (SOLC)" \
	help solc \
	label "Fraction solvent content" \
	widget SOLVENT_FRAC -oblig

  CreateLine line \
        message "Number of cycles of phase extension (NCYCLE) default is AUTO" \
	help ncycle_auto \
        widget DM_NCYCLES_NOT_AUTO \
	  -toggleon \
        label "Fix number of cycles of phase extension to" \
	help ncycle \
        widget DM_NCYCLES \
        toggle_display PHASE_COMB hide OMIT

  CreateLine line \
    message "Resolution limit of starting set (SCHEME RES)" \
    label "Resolution of starting set in phase extension" \
    help scheme_res \
    widget DM_SCHEME_RES -oblig \
    toggle_display DM_SCHEME open RES

  CreateLine line \
    message "Fraction of reflections in starting set (SCHEME FRAC)" \
    label "Fraction of reflections in starting set" \
    help scheme_res \
    widget DM_SCHEME_FRAC -oblig \
    toggle_display DM_SCHEME hide [list RES ALL AUTO]


#========================================================================


  OpenFolder 3 DM_AVERAGING open 1 hide

  CreateLine line \
      message "Select convention for specifying the NCS operator" \
      help average \
      label "Define NCS operators in terms of" \
      widget NCS_OP_TYPE

  CreateLineTemplate NCSOPS [list 0.05 0.20 0.35 0.50 0.65 0.80]
  CreateLineTemplate NCSREF [list 0.0 0.6 0.65]
  CreateLineTemplate NCSMAT [list 0.0 0.3 0.6 ]

  CreateToggleFrame  NCS_NDOMAINS  DmDomainFrame \
                "Open another domain frame"  "Domain number" \
		"Add domain" \
              [list NCS_MASK_FILE \
                DIR_NCS_MASK_FILE \
                NCS_REFINE_OP \
                NCS_NOPS ] \
		-child DmDomainOpsFrame

#========================================================================
  OpenFolder 4 DM_AVERAGING open 1 hide


  CreateLine line \
	message "Default computed by program if you do not enter a value(NCSMASK NMER)" \
        help ncsmask_nmer \
        label "Number of monomers related by proper symmetries" \
        widget NCSMASK_NMER 

  CreateLine line \
    message "Update the averaging mask every <cyc> cycles. (NCSMASK UPDATE)" \
    help ncsmask \
    widget IF_NCSMASK_UPDATE \
	-toggleon \
    label "Update averaging mask every" \
    widget NCSMASK_UPDATE_NCYC \
    label "cycles"
 
  CreateLine line \
        message "Limits on search space over which mask formed.(NCSMASK ALIM)" \
        help ncsmask_alim \
	label "Search limits in a" \
	widget NCSMASK_ALIM_1 \
	widget NCSMASK_ALIM_2 \
        label " b" \
        widget NCSMASK_BLIM_1 \
        widget NCSMASK_BLIM_2 \
        label " c" \
        widget NCSMASK_CLIM_1 \
        widget NCSMASK_CLIM_2 \

#--------------------------------------------------------------Solvent mask
  OpenFolder 5 DM_SOLVENT closed 1 hide

  CreateLine line \
    message "Update solvent mask after a few cycles? (SOLMASK UPDATE)" \
    help solmask \
    widget IF_SOLMASK_UPDATE \
	-toggleon \
    label "Update solvent mask after" \
    widget SOLMASK_UPDATE_NCYC \
    label cycles

  CreateLine line \
    label "Set mask extent if different from solvent content above" -italic

  CreateLine line \
    message "Fraction solvent + fraction protein <= 1.0 (SOLMASK)" \
    help solmask \
    label "Fraction of cell: solvent" \
    widget SOLMASK_FRAC_SOLV   \
    label " protein:" \
    widget SOLMASK_FRAC_PROT

  CreateLine line \
    message "Use Wang" \
    help solmask \
    widget IF_SOLMASK_WANG \
	-toggleon \
    label "Use Wang with radius" \
    message "Default enter no radius and program will derive value" \
    widget WANG_RADIUS \
    label "and weighting scheme" \
    widget WANG_MODE
    


#========================================================================
  OpenFolder 6 closed

  CreateLine line \
        message "Choose the mode(s) of density modification (MODE)" \
        help mode \
        label "Additional density modification modes: " \
        widget DM_MULTI \
        label "Multi resolution" \
        widget DM_SKELETON \
        label "Skeleton" \
        widget DM_SAYRE \
        label "Sayre"

  CreateLine line \
        message "Apply resolution limits (RESOlution)" \
	help resolution \
        widget EXCLUDE_RESOLUTION \
          -toggleon \
        message "Minimum resolution (RESOlution)" \
        label "Resolution range from minimum" \
        widget EXCLUDE_RESOLUTION_MIN \
        message "Maximum resolution (RESOlution)" \
        label " to " \
        widget EXCLUDE_RESOLUTION_MAX 

  CreateLine line \
    message "Set mean density for solvent and protein regions(SOLC MEAN)" \
    label "Mean density of solvent" \
    help solc \
    widget SOLC_MEAN_SOLVVAL \
    label "and protein" \
    widget SOLC_MEAN_PROTVAL


  CreateLine line \
        message "Phase combination number of sets (COMBINE SETS <numsets>)" \
	help combine_sets \
	label "Phase combination number of sets" \
	widget DM_PHASE_COMB_NSETS

  CreateLine line \
	message "Weight given to restored missing reflections (RESTORE <restorewt>)" \
	help combine_restore \
        label "Weight assigned to restored reflections" \
        widget DM_RESTORE_WT

   CreateLine line \
     message "REALFREE subkeywords SOLV <sx><sy><sz><sr> and PROT <px><py><pz><pr>" \
     help realfree \
     widget DM_REALFREE_SUB \
     label "Input coords and radii for REALFREE spherical patches (optional)" \
     toggle_display IF_DM_REALFREE open 1
  
   CreateLine line \
     message "X-coordinate (Angstrom)" \
     help realfree \
     label "Solvent patch:  X" \
     widget DM_SX \
     message "Y-coordinate (Angstrom)" \
     label "Y" \
     widget DM_SY \
     message "Z-coordinate (Angstrom)" \
     label "Z" \
     widget DM_SZ \
     message "Patch radius (Angstrom)" \
     label "radius" \
     widget DM_SR \
     toggle_display DM_REALFREE_SUB open 1
 
   CreateLine line \
     message "X-coordinate (Angstrom)" \
     help realfree \
     label "Protein patch:  X" \
     widget DM_PX \
     message "Y-coordinate (Angstrom)" \
     label "Y" \
     widget DM_PY \
     message "Z-coordinate (Angstrom)" \
     label "Z" \
     widget DM_PZ \
     message "Patch radius (Angstrom)" \
     label "radius" \
     widget DM_PR \
     toggle_display DM_REALFREE_SUB open 1
       

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

  CreateLine line \
        label "Skeletonisation options:" -italic

  CreateLine line \
	message "Skeletonisation applied every n cycles (SKEL EVERY)" \
	help skel \
	label "Apply skeletonisation every " \
	widget DM_SKEL_CYCLES \
	label "cycles"

  CreateLine line \
        message "Length of skeleton in A/residue between density peaks (SKEL LENGTH joinlen)" \
	help skel \
	label "Length per residue of connected skeleton" \
	widget DM_SKEL_JOINLEN \
        message "Length of skeleton in A/residue to apply to trailing ends (SKEL LENGTH endlen)" \
	label "and for side chains" \
	widget DM_SKEL_ENDLEN 

  CreateLine line \
        message "temperature factor applied to sharpened map before skeletonisation (SKEL BFAC)" \
	help skel \
	label "Map smoothing temperature factor" \
	widget DM_SKEL_BFAC


}
