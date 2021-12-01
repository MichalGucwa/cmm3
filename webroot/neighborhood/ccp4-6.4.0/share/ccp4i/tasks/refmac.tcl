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
# refmac.tcl --
#
# CCP4Interface 
#
# =======================================================================

#-------------------------------------------------------------------------
proc refmac_run { arrayname } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array
  global refmac_protin

  WarningMessage "Cannot run task

Protin and Refmac (version 4) have been withdrawn
as of CCP4 version 5.0.

The interfaces for these programs are provided
only to allow past runs of Protin and Refmac to be
reviewed.

Please use Refmac5 instead."

  return 0
}

#---------------------------------------------------------------------
proc refmac_setup { typedefVar arrayname } {
#---------------------------------------------------------------------

upvar #0  $typedefVar typedef

# Generally: if the arrayname is the same as the taskname then
# it is an indication that the task has been started "from scratch"
# - in this case we can stop the window being drawn.
# Tasks launched using "Rerun" have temporary arraynames so they
# should be drawn as normal.
if { $arrayname == "refmac" } {

  WarningMessage "Cannot start Refmac Task Interface

Protin and Refmac (version 4) have been withdrawn
as of CCP4 version 5.0.

The interfaces for these programs are provided
only to allow past runs of Protin and Refmac to be
reviewed.

Please use Refmac5 instead."

  return 0
}


# Initialise protin types too

set typedef(_refmac_protin_params) { menu { "currently setup in Protin window"
					    "from selected Protin def file" 
					    "from Protin project default file"
					    "from existing PROTOUT file" } 
				{	WINDOW
					FILE 
					PROJECT
					PROTOUT } }

set typedef(_refmac_input_phase) { menu {	"no phase information" 
						"phase and FOM"
					"Hendrickson-Lattman coefficients" }
					{	NO
						PHASE
						HL } }

set typedef(_refmac_residual) {  menu { "maximum likelihood"
                                        "least squares residual" }
                                      { "MLKF"
                                        "LSQF" } }

set typedef(_refmac_refine_type) { menu {       "restrained refinement"
                                                "unrestrained refinement"
                                                "rigid body refinement"
                                                "structure idealisation" }
                                        {       "REST"
                                                "UNRE"
                                                "RIGID"
                                                "IDEA" } }

set typedef(_refmac_minimisation) { menu {     "conjugate direction"
                                                "conjugate gradient" 
						"sparse matrix" }
                                          {     CDIR
                                                CGRAD
						CGMAT }}


set typedef(_refmac_b_refinement)  { menu { isotropic anisotropic overall mixed }
                                          {     ISOT ANIS OVER MIXED } }
set typedef(_refmac_split_mode)  {menu  { "into bins"
					  "by ranges" }
					{  BINS
                                           RANGES } }

set typedef(_refmac_weighting)   { menu { matrix
					  gradient }
                                        { MATRIX
					  GRADIENT } }

set typedef(_refmac_monitor_level) { menu { none few "user defined" many }
                                          { NONE FEW MEDI MANY } }

set typedef(_refmac_rigid_monitor_level) { menu { "limited" "for every cycle" }
                                          { FEW MANY } }

set typedef(_refmac_monitor_mode) { menu { "NxSigma" "absolute" }  }

set typedef(_refmac_scaling_appl) { menu {      "no" \
                                                "observed" \
                                                "calculated" }
                                        {       "NO" \
                                                "OBSE" \
                                                "CALC" } }

set typedef(_refmac_scaling) { menu {  "Bulk solvent"
					"Simple Wilson" }
				{	BULK 
                                        SIMPLE } }

set typedef(_refmac_ref_set) { menu     {       "working" \
                                                "free" }
                                        {       "WORK"
                                                "FREE" } }

set typedef(_refmac_rigid_exclude) { menu {     "no"
                                                "main chain"
                                                "side chain" }
                                         {      "NO"
                                                "MCHA"
                                                "SCHA" } }

  source [SearchPath TOP tasks protin_setup.tcl ]


set  typedef(_arp_refine_mode) { menu {         "only water atoms"
                                                "all atoms" }
                                        {       WATERS
                                                ALLATOMS } }

return 1
}
					
#-----------------------------------------------------------------------
proc RefmacRigidParams { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if [regexp RIGID [GetValue $arrayname REFINE_TYPE] ] {
    set array(B_REFINEMENT) 0
    set array(SCALING_IF_FIXB) 1
    set array(SCALING_FIXB_BBULK) 70.0
    set array(SCALING_FIXB_SCBULK) -0.75
    set array(MLSC_ON) 1
    set array(MLSC_IF_FIXB) 1
    set array(MLSC_FIXB_BBULK) 100.0
    set array(MLSC_FIXB_SCBULK) -0.1
    set array(RUN_ARP) 0
  } else {
    set array(B_REFINEMENT) 1
    set array(SCALING_IF_FIXB) 0
    set array(MLSC_ON) 0
    set array(MLSC_IF_FIXB) 0
  }
}


#-----------------------------------------------------------------------
proc RefmacPartials  { arrayname c1 } {
#-----------------------------------------------------------------------

  CreateLabinLine line \
        "Partial SF (FPART) and it's phase (PHIP)" \
        HKLIN "Partial   " FPART  {FPART} \
        -sigma "phase " PHIP  {}

  CreateLine line \
	message  "Scale partial SFs relative to FC (SCPART)" \
        help scpa \
	label "Partial SFs scaling" \
	widget PARTIAL_SCALE 
}

#--------------------------------------------------------------------
proc RefmacDomains { arrayname counter } { 
#--------------------------------------------------------------------

  OpenSubFrame frame -toggle_display  INITIALISE_RIGID  hide 0

  CreateLine line \
	message "Apply translation to domain before refinement (RIGID TRANS)" \
	help "rigi" \
	widget TRANS_ON \
	label "Apply initial translation x" \
	widget TRANS_X \
	label "y" \
	widget TRANS_Y \
	label "z" \
	widget TRANS_Z

  CreateLine line \
	message "Apply rotation to domain before refinement (RIGID EULER)" \
	help "rigi" \
	widget EULER_ON \
	label "Apply initial rotation alpha" \
	widget EULER_ALPHA \
	label "beta" \
	widget EULER_BETA \
	label "gamma" \
	widget EULER_GAMMA

  CloseSubFrame

  CreateLine line \
        message "Exclude main/side chain from refinement (RIGID EXCLUDE MCHA/SCHA)" \
        help "rigi_grou" \
        label "Exclude" \
        widget EXCLUDE_ATOMS \
        label "atoms from refinement"


  CreateExtendingFrame NGROUPS RefmacGroups \
        "List residue ranges in the domain" \
        "Add Residue Range" \
       [ list CHAIN1 \
        RES1 \
        RES2 ] \
	-counter $counter

}

#----------------------------------------------------------------------
proc RefmacGroups { arrayname c2 c1 } {
#----------------------------------------------------------------------

  CreateLine line \
	message "Enter range of residues to include in domain (RIGID GROUP)" \
	help rigi_grou \
	label "Chain" \
	widget CHAIN1 \
	label "from residue" \
	widget RES1 \
	label "to residue" \
	widget RES2

}


#---------------------------------------------------------------------
proc refmac_open_protin { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array
  global protin

  if { [regexp FILE [GetValue $arrayname PROTIN_PARAMS ]]  } {
    set protin_def_file [GetFullFileName0 $arrayname PROTIN_DEF]
    if { [file exist $protin_def_file] } { 
      InitialiseArray [SearchPath TOP tasks protin.def ] protin protin
      InitialiseArray $protin_def_file protin protin
      set protin(TASK_INPUT_DEF_FILE) $protin_def_file
    }
  }
  RunTask protin
}


#-------------------------------------------------------------------
proc refmac_set_mini { arrayname } {
#-------------------------------------------------------------------
  upvar #0 $arrayname array
  set mode [GetValue $arrayname B_REFINEMENT_MODE]
  if { [regexp ANISO [GetValue $arrayname B_REFINEMENT_MODE]] } {
    set array(MINIMISATION) "conjugate direction"
  } else {
    set array(MINIMISATION) "sparse matrix"
  }
}
 

#=CREATE=WINDOW=AND=SUBWINDOWS===========================================

proc refmac_task_window { arrayname } {

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
    	"Run Refmac" "Refmac" \
        [ list "Data Harvesting" \
	"Setup Protin" \
	"Required Parameters"  \
	"ARP/wARP Parameters" \
        "Rigid Domains Definition" \
	"Partial Structure Factors" \
	"Data Output to MTZ file" \
        "Crystal parameters" \
	"Scaling Fobs and Fc" \
	"SigmaA Estimation" \
	"Other Parameters"   \
	"Monitoring"  \
	"Geometric parameters" ] \
	-file_cleanup 0 ] == 0 } return

  SetDefaultMapFormat $arrayname MAPOUT_FORMAT
  SetHarvestParams $arrayname HKLIN -init

  if { $array(PROTIN_PARAMS) == "" ||
    [regexp WINDOW $array(PROTIN_PARAMS)] && ![array exists array] } {
    if [file exists [FileJoin [GetDbDirPath] protin.def ]] {
      set array(PROTIN_PARAMS) PROJECT
    } elseif [ array exists array] {
      set array(PROTIN_PARAMS) WINDOW
    } else {
      set array(PROTIN_PARAMS) FILE
    }
  }

  SetProgramHelpFile "refmac"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateLine line \
        label "PROTIN/REFMAC 4 have been withdrawn from CCP4 as of version 5.0 - Refmac5 should be used instead" -italic
  CreateLine line \
        label "This interface is provided to allow the review of old jobs only and, will not run the programs" -italic

  CreateTitleLine line TITLE

  CreateLine line \
        message "Refinement method (REFI TYPE)" \
	help refi_type \
        label "Do" \
        widget REFINE_TYPE \
	  -command "RefmacRigidParams $arrayname" \
	message "Choose type of phase input" \
        help labin \
        label "using" \
        widget INPUT_PHASE \
	label "input" \
	toggle_display REFINE_TYPE hide IDEA

  CreateLine line \
        message "Refinement method (REFI TYPE)" \
        help refi_type \
        label "Do" \
        widget REFINE_TYPE \
          -command "RefmacRigidParams $arrayname" \
	toggle_display REFINE_TYPE open IDEA


  SetProgramHelpFile arp_waters

  CreateLine line \
	message "Cycle with ARP/wARP 5.0 to find new atoms" \
        help mode \
	widget RUN_ARP \
	label "Cycle with ARP/wARP to analyse" \
	widget ARP_UPDATE_MODE \
	toggle_display REFINE_TYPE open [list REST UNRE ]

  SetProgramHelpFile refmac

  CreateLine line \
        message "Generate weighted mFo-DFcalc and 2mFo-DFcalc maps" \
 	widget IF_MAPOUT \
	  -toggleon \
        label "Generate weighted difference maps files in" \
        widget MAPOUT_FORMAT \
        label "format" \
        toggle_display REFINE_TYPE hide IDEA open

  CreateLine line \
        widget EXTEND_MAP \
        label "Extend map to cover molecule with border" \
        widget MAP_BORDER \
        toggle_display IF_MAPOUT open 1
        

#=FILES================================================================

  SetProgramHelpFile refmac

  OpenFolder file 

  
  OpenSubFrame frame  -toggle_display  REFINE_TYPE hide IDEA

  CreateInputFileLine line \
	"Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
       HKLIN DIR_HKLIN \
       -fileout HKLOUT DIR_HKLOUT "_refmac" \
       -setlabin FREE [list FREE FreeR FreeR_flag] \
       -setfileparam space_group_name SPACE_GROUP \
	-setfileparam cell_1 CELL_1 \
	-setfileparam cell_2 CELL_2 \
	-setfileparam cell_3 CELL_3 \
	-setfileparam cell_4 CELL_4 \
	-setfileparam cell_5 CELL_5 \
	-setfileparam cell_6 CELL_6 \
	-setfileparam resolution_min EXCLUDE_RESOLUTION_MIN \
	-setfileparam resolution_max EXCLUDE_RESOLUTION_MAX \
	-setfileparam resolution_max BULK_SCALING_RESOLUTION_MAX \
	-setfileparam resolution_min SCALING_RESOLUTION_MIN \
	-command "UpdateHarvestMTZ $arrayname HKLIN"


  CreateLabinLine line \
	"Observed amplitude (FP) and obligatory sigma (SIGFP)" \
	HKLIN "FP    " FP  [list FP F_P] \
        -sigma "Sigma  " SIGFP  [list SIGFP SIGF_P SIGP ]

  CreateLabinLine line \
	"Input phase (PHIB) and figure of merit (FOM)" \
	HKLIN "PHIB  " PHIB  PHIB \
        -sigma "FOM  " FOMB  FOM \
        -toggle_display INPUT_PHASE open PHASE

  OpenSubFrame frame  -toggle_display  INPUT_PHASE open HL

  CreateLabinLine line \
	"Hendrickson-Lattman coefficients"  \
	HKLIN "HLA" HLA  [list HLA] \
	-sigma "HLB" HLB {}

 CreateLabinLine line \
        "Hendrickson-Lattman coefficients"  \
        HKLIN "HLC" HLC  [list HLC] \
	-sigma "HLD" HLD {}

  CloseSubFrame

  CreateOutputFileLine line \
	"Output MTZ File" \
	"MTZ out" \
	HKLOUT DIR_HKLOUT

  CloseSubFrame

  CreateInputFileLine line \
        "Enter input coordinate file name (XYZIN)" \
      "PDB in" \
       XYZIN DIR_XYZIN \
       -fileout XYZOUT DIR_XYZOUT "_refmac"

  CreateOutputFileLine line \
        "Output coordinate file" \
        "PDB out" \
        XYZOUT DIR_XYZOUT


#=PARAMETERS==========================================================

  OpenFolder 1 

  CreateHarvestLine line 

#-----------------------------------------------------------------------

  SetProgramHelpFile protin

  OpenFolder 2 REFINE_TYPE hide { RIGID UNRE }

  CreateLine line \
    help description \
    label "Use geometric parameters" \
    widget PROTIN_PARAMS \
    button "Open Protin window" \
	-command "refmac_open_protin $arrayname"

  CreateInputFileLine line \
        "PROTIN def file which has been saved from PROTIN interface" \
        "Protin def file" \
         PROTIN_DEF DIR_PROTIN_DEF \
         -toggle_display PROTIN_PARAMS open FILE

  OpenSubFrame frame -toggle_display PROTIN_PARAMS open PROTOUT

  SetProgramHelpFile refmac

  CreateInputFileLine line \
        "PROTOUT file from previous run of Protin program" \
	"PROTOUT" \
	PROTOUT DIR_PROTOUT \
	-help protout

  CreateInputFileLine line \
        "PROTCOUNTS file from previous run of Protin program" \
	"PROTCOUNTS" \
	PROTCOUNTS DIR_PROTCOUNTS \
	-help protcounts

  CloseSubFrame
	

#------------------------------------------------------------------------
  OpenFolder 3

  SetProgramHelpFile refmac

  CreateLine line \
        message "Method of calculating residual (REFI RESIdual)" \
	label "Do" \
        help refi_resi \
        widget RESIDUAL \
        message "Refinement method (REFI TYPE)" \
        label "refinement using " \
        message "Minisation method (REFI METHod)" \
        help refi_meth \
        widget MINIMISATION \
        label "minimisation" \
	toggle_display REFINE_TYPE hide { RIGID IDEA }

  CreateLine line \
        message "Method of calculating residual (REFI RESIdual)" \
        label "Do" \
        help refi_resi \
        widget RESIDUAL \
        message "Refinement method (REFI TYPE)" \
        label "refinement" \
	toggle_display REFINE_TYPE open RIGID

  CreateLine line \
        label "Refine using " \
        message "Minisation method (REFI METHod)" \
        help refi_meth \
        widget MINIMISATION \
        label "minimisation" \
        toggle_display REFINE_TYPE open IDEA


  CreateLine line \
	message "Number of cycles of refinement (NCYC) for each Refmac run" \
	help ncyc \
	widget NCYCLES \
	  -width 3 \
	label "cycles of refinement in each Refmac run and" \
	message "Number of cycles of running Refmac (&Protin/ARP etc)" \
	widget EXTERNAL_NCYCLES \
	   -width 3 \
	label "cycle(s) of external refinement"  \
        toggle_display REFINE_TYPE hide RIGID

  CreateLine line \
        message "Number of cycles of refinement (NCYC) for each Refmac run" \
        help ncyc \
        widget RIGID_NCYCLES \
          -width 3 \
        label "cycles of refinement in each Refmac run and" \
        message "Number of cycles of running Refmac (&Protin/ARP etc)" \
        widget EXTERNAL_NCYCLES \
           -width 3 \
        label "cycle(s) of external refinement"  \
        toggle_display REFINE_TYPE open RIGID

  OpenSubFrame frame -toggle_display REFINE_TYPE hide IDEA

  CreateLine line \
	message "Apply resolution limits (REFI RESOlution)" \
	help refi_reso \
	widget EXCLUDE_RESOLUTION \
	  -toggleon \
	message "Minimum resolution" \
	label "Resolution range from minimum" \
	widget EXCLUDE_RESOLUTION_MIN \
	message "Maximum resolution" \
	label " to " \
	widget EXCLUDE_RESOLUTION_MAX

  OpenSubFrame frame -toggle_display REFINE_TYPE hide [list UNRE IDEA RIGID ] 

  CreateLine line \
        label "Use"  \
        message "Matrix diagonal method (as PROLSQ) or use sigma" \
        widget WEIGHTING_METHOD \
        label "scaling. Diagonal weighting term" \
        message "Matrix weighting term, default 0.5, decrease to tighten geometry" \
        help weig \
        widget MATRIX_WEIGHT \
        message "Use experimental sigmas to weight geometric/X-ray" \
        help weig \
        widget EXPERIMENTAL_WEIGHTING \
        label "Use expt sigmas to weight Xray terms" \
        toggle_display WEIGHTING_METHOD open MATRIX


  CreateLine line \
        label "Use"  \
        message "Matrix diagonal method (as PROLSQ) or use sigma" \
        widget WEIGHTING_METHOD \
        label "scaling. Gradient weighting term" \
        message "Gradient weighting term, default 1.0, decrease to tighten geometry" \
        help weig \
        widget GRADIENT_WEIGHT \
        message "Use experimental sigmas to weight geometric/X-ray" \
        help weig \
        widget EXPERIMENTAL_WEIGHTING \
        label "Use expt sigmas to weight Xray terms" \
        toggle_display WEIGHTING_METHOD open GRADIENT

  CloseSubFrame

  CreateLine line \
	message "Refine temperature factors (REFI BREF)" \
	help refi_bref \
	widget B_REFINEMENT \
	label "Refine" \
	widget B_REFINEMENT_MODE \
		-command "refmac_set_mini $arrayname" \
	label "temperature factors" \
	toggle_display REFINE_TYPE open { REST UNRE }  hide

  CreateLine line \
        message "Refine temperature factors (REFI BREF OVER )" \
        help refi_bref \
        widget B_REFINEMENT \
        label "Refine overall B-factor" \
        toggle_display REFINE_TYPE open { RIGID IDEA }  hide

  CreateLine line \
	message "Exclude data for freeR" \
	help free \
	widget EXCLUDE_FREER \
	label "Exclude data with freeR label"  \
	message "Label of data in input MTZ file (LABIN FREE)" \
	widget FREE \
	label "with value of" \
	message "value of data in freeR column in MTZ file (FREEflag)" \
	help nfree \
	widget EXCLUDE_FREER_VALUE

  CreateLine line \
    message "Add H atoms (Hgen program) and calculate FCs with Sfall" \
    widget  ADD_HYDROGENS \
    label "Include hydrogen atoms when calculating FCs"

  CloseSubFrame


#--------------------------------------------------------------------ARPP

  OpenFolder 4 RUN_ARP hide 0 open

  SetProgramHelpFile arp_waters

  CreateLine line \
    message  "Remove atoms in ARP/wARP (REMOVE)" \
    help remove \
    label "Remove" \
    widget REMOVE_ATOMS \
    label "atoms from density below" \
    widget REMOVE_CUTSIGMA  \
    label "sigma"

  CreateLine line \
    help remove \
    message "Remove close atoms (MERGE)" \
    widget REMOVE_MERGE \
    label "Merge atoms closer than" \
    widget REMOVE_MERGE_CUTOFF_WAT \
    toggle_display ARP_UPDATE_MODE open WATERS

    CreateLine line \
    help remove \
    message "Remove close atoms (MERGE)" \
    widget REMOVE_MERGE \
    label "Merge atoms closer than" \
    widget REMOVE_MERGE_CUTOFF_ALL \
    toggle_display ARP_UPDATE_MODE open ALLATOMS

  CreateLine line \
    message "Set limits to contact distances of new atoms (FDISTANCE)" \
    label "New to old atom distance greater than" \
    help fdistance \
    widget FIND_NEWOLD_MIN \
    label "less than" \
    widget FIND_NEWOLD_MAX

  CreateLine line \
    message "Set limits to contact distances of new atoms (FDISTANCE)" \
    help fdistance \
    label "Min distance between new atoms" \
    widget FIND_NEWNEW


  CreateLine line \
    message "Override program choice of number of atoms to find (FIND)" \
    help find \
    label "Find" \
    widget FIND_ATOMS \
    label "new atoms in density above" \
    widget FIND_CUTSIGMA \
    label "sigma and assign to chain" \
    widget FIND_CHAIN

  CreateLine line \
    message "Refine which atoms (usually only waters except resolution>1.0)" \
    label "Refine" \
    widget ARP_REFINE_MODE

  SetProgramHelpFile mapmask

  CreateLine line \
    message "Set map limits for map used by ARP/wARP (XYZLIM)" \
    help xyzlim \
    widget INPUT_XYZLIM \
	-toggleon \
    label "Set ARP/wARP map extent x" \
    widget XYZLIM_1  \
    widget XYZLIM_2  \
    label "y"       \
    widget XYZLIM_3  \
    widget XYZLIM_4  \
    label "z"       \
    widget XYZLIM_5  \
    widget XYZLIM_6

#----------------------------------------------------------Use partials

  SetProgramHelpFile refmac

  OpenFolder 6 REFINE_TYPE hide IDEA closed

  CreateExtendingFrame NPARTIALS RefmacPartials \
	"Define partial SFs to be used" \
	"Add partial" \
       [ list FPART \
	PHIP \
	PARTIAL_SCALE ] 

#----------------------------------------------------------------Output MTZ data

  OpenFolder 7 REFINE_TYPE hide IDEA closed

  CreateLaboutLine line \
     "Enter names for model amplitude and phases" \
        HKLOUT "Fcalc" FC \
	-sigma "PHICalc"  PHIC

  CreateLaboutLine line \
     "Enter names for difference map amplitude and phases" \
        HKLOUT "mFoDFc" DELFWT \
	-sigma "PhimFoDFc" PHDELWT

  CreateLaboutLine line \
     "Enter names for SIGMAA style difference map amplitude and phases" \
        HKLOUT "2mFoDFc" FWT \
	-sigma "Phi2mFoDFc"  PHWT

  CreateLaboutLine line \
     "Enter name for figure of merit" \
        HKLOUT "FOM" FOM 

  CreateLaboutLine line \
    "Enter name for phases combined with experimental phase" \
        HKLOUT "PhiComb"  PHCOMB \
        -toggle_display INPUT_PHASE open PHASE

#------------------------------------------------------------cell parameters

  OpenFolder 8 closed

  CreateLine line \
	message "Space group (default from MTZ) (SYMM)" \
	label "Space group" \
	widget SPACE_GROUP

  CreateLine line \
	message "Cell dimensions (default from MTZ) (CELL)" \
	label "Cell a" \
	widget CELL_1 \
	label "b" \
	widget CELL_2 \
	label "c" \
	widget CELL_3 \
	label "alpha" \
	widget CELL_4 \
	label "beta" \
	widget CELL_5 \
	label "gamma" \
	widget CELL_6

#---------------------------------------------------------Scaling Fo and Fc

  OpenFolder 9 REFINE_TYPE hide IDEA closed

  CreateLine line \
	message "Bulk solvent scaling or simple Wilson scaling (SCALe TYPE BULK|SIMP)"  \
	help scal \
        widget BULK_SOLVENT_SCALING \
	label "scaling and  " \
	message "Apply correction for crystal anisotropy (SCALE ANISO)" \
	help scal_lssc_anis \
        widget SCALING_ANISO \
	label "Apply crystal anisotropic scaling"

  CreateLine line  \
	message "Resolution limits for scaling (SCALE RESO)" \
        label "Bulk solvent scaling for resolution range" \
	help scal_lssc_reso \
	widget SCALING_RESOLUTION_MIN \
	label " to " \
	widget BULK_SCALING_RESOLUTION_MAX \
        message "Refine scaling for n cycles (SCALE NCYC)" \
        label "for" \
	help scal_lssc_ncyc \
	widget SCALING_NCYCYLES \
	label "cycles" \
        toggle_display BULK_SOLVENT_SCALING open BULK

  CreateLine line \
        message "Resolution limits for scaling (SCALE RESO)" \
        label "Simple solvent scaling for resolution range" \
	help scal_lssc_reso \
        widget SCALING_RESOLUTION_MIN \
        label " to " \
        widget SIMPLE_SCALING_RESOLUTION_MAX \
        message "Refine scaling for n cycles (SCALE NCYC)" \
        label "for" \
	help scal_lssc_ncyc \
	widget SCALING_NCYCYLES \
	label "cycles" \
        toggle_display BULK_SOLVENT_SCALING open SIMPLE

   CreateLine line \
	message "Use only FREE set of reflections or the WORKing set? (SCALE FREE)" \
        help "scal" \
	label "Determine scaling using the" \
	help scal_lssc_free \
	widget SCALING_REF_SET \
	label "set of reflections   " \
	message "Use experimental sigmas in determining scaling (SCLAE EXPE)" \
	help scal_lssc_expe \
	widget SCALING_EXPE_SIGMA \
	label "Use experimental sigmas"

   CreateLine line \
	label "For low resolution structures.." \
		-italic

  CreateLine line \
        message "For structures with non-robust wilson plot fix <B> (SCALE BAVE)"  \
	help "scal" \
        widget SCALING_IF_BAVERAGE \
	  -toggleon \
	label "Fix overall Bfactor to" \
        widget SCALING_BAVERAGE

  CreateLine line \
        message "For structures with non-robust wilson plot fix <B> (SCALE FIXB)"  \
	help "scal_lssc_fixb" \
	widget SCALING_IF_FIXB \
	  -toggleon \
	label "Fix overall scales and Bvalues for bulk to" \
	widget SCALING_FIXB_BBULK \
	label "and solvent/protein density ratio" \
        widget SCALING_FIXB_SCBULK

#-----------------------------------------------------Scaling SigmaA

  OpenFolder 10 REFINE_TYPE hide IDEA closed

  CreateLine line \
  	message "Refine determination of  SigmaA (MLSC NCYC)" \
        widget MLSC_ON \
	  -toggleon \
	label "Refine estimate of SigmaAs for" \
	help scal_mlsc_ncyc \
	widget MLSC_NCYCLES \
	label "cycles  " \
	label "Use the" \
	help scal_mlsc_work \
	widget MLSC_REF_SET \
	label "set of reflections"

   CreateLine line \
        label "For low resolution structures.." \
                -italic

  CreateLine line \
	message "Fix bulk parameters with EXTREME CARE! (SCALE MLSC FIXB)" \
	help "scal_mlsc_fixb" \
	widget MLSC_IF_FIXB \
	  -toggleon \
	label "Fix overall scales and Bvalues for bulk to" \
	widget MLSC_FIXB_BBULK \
	label "and solvent/protein density ratio" \
        widget MLSC_FIXB_SCBULK
	

#-------------------------------------------------------Other parameters

  OpenFolder 11 closed

  OpenSubFrame frame -toggle_display REFINE_TYPE hide IDEA

  CreateLine line \
        message "Split resolution range (BINS or RANGES)" \
        label "Split resolution range " \
	help bins \
        widget SPLIT_MODE \
        message "Number of bins in total resolution range (BINS)" \
        label "  Number of bins" \
        widget SPLIT_BINS \
        toggle_display SPLIT_MODE open BINS

  CreateLine line \
        message "Split resolution range (BINS or RANGES)" \
        label "Split resolution range " \
        help bins \
        widget SPLIT_MODE \
        label "  Range width" \
        message "Bin width in 4*sin**2/lambda**2 (RANGES)" \
        widget SPLIT_RANGES \
	toggle_display SPLIT_MODE open RANGES

  CreateLine line \
        message "Damp shifts (for limited data or unrestrained refinement) (DAMP)" \
        widget DAMP \
        label "Damp shifts using Pdamp" \
        widget DAMP_P \
        toggle_display REFINE_TYPE open IDEA hide

  CloseSubFrame

  CreateLine line \
        message "Set limits for Bvalues (discouraged) (BLIM)" \
	help blim \
        widget BLIM \
	  -toggleon \
        label "Limit bvalue range from" \
        widget BLIM_MIN \
        label "to" \
        widget BLIM_MAX \
	toggle_display REFINE_TYPE hide IDEA open

  CreateLine line \
        message "Damp shifts (for limited data or unrestrained refinement) (DAMP)" \
        widget DAMP \
	  -toggleon \
        label "Damp shifts using Pdamp" \
        widget DAMP_P \
        label "and Bdamp" \
        widget DAMP_B \
	toggle_display REFINE_TYPE open [list REST UNRE ]

  CreateLine line \
    message "Blurring factors for input phases (REFI PHASE SCBLUR BBLUR)" \
    label "Blurring factors for input phase FOM SC" \
    widget PHASE_SCBLUR \
    label "B" \
    widget PHASE_BBLUR \
    toggle_display INPUT_PHASE hide NO



#---------------------------------------------------Rigid Domain Definition

  OpenFolder 5 REFINE_TYPE open RIGID hide

  CreateLine line \
	widget INITIALISE_RIGID \
	label "Initialise rotation and translation parameters"


 CreateToggleFrame NDOMAINS RefmacDomains \
        "Define the independent domains" "Domain number" \
        "Add Domain Definition"  \
       [list NGROUPS \
	TRANS_ON \
	TRANS_X \
	TRANS_Y \
	TRANS_Z \
	EULER_ON \
	EULER_ALPHA \
	EULER_BETA \
	EULER_GAMMA \
	EXCLUDE_ATOMS ] \
	-child RefmacGroups
  

#---------------------------------------------------------monitoring

  OpenFolder 12 closed

  CreateLine line \
	message "Level of output of monitoring statistics (MONI)" \
	label "Output" \
	help moni \
	widget MONI_LEVEL \
	label "monitoring statistics" \
	toggle_display REFINE_TYPE hide RIGID

  CreateLine line \
        message "Output monitoring statistics and transformations(MONI)" \
        label "Output" \
        help moni \
        widget RIGID_MONI_LEVEL \
        label "monitoring statistics & transformations" \
        toggle_display REFINE_TYPE open RIGID hide


  OpenSubFrame frame -toggle_display MONI_LEVEL open MEDI

  CreateLine line \
	message "Use absolute difference or N*sigma deviations from ideal" \
	label "Use" \
	help moni \
	widget MONI_MODE \
	label "cutoffs.    " \
	widget MONI_HBOND \
	label "List possible hydrogen bonds"

  CreateLineTemplate MONITOR { 0.1 0.35 0.55 0.8 }


  OpenSubFrame frame_1 \
        -toggle_display MONI_MODE open NxSigma

  CreateLine line \
	message "List torsions greater than badtor*torsig from ideal" \
	label "Torsion cutoff" \
	help moni \
	widget MONI_BADTOR \
	message "List distances greater than 2*baddis*dissig from ideal" \
	label "Distance cutoff" \
	widget MONI_BADDIS \
	format template MONITOR

  CreateLine line \
	message "List planes differing more than badpln *plnsig from idea" \
	help moni \
	label "Plane cutoff" \
	widget MONI_BADPLN \
	message "List contact distances less than badvdw*vdwsig" \
	label "VDW cutoff" \
	widget MONI_BADVDW \
	format template MONITOR

  CloseSubFrame

  OpenSubFrame frame_2 \
        -toggle_display MONI_MODE hide NxSigma

  CreateLine line \
        message "List torsions greater than torcut from ideal" \
	help moni \
        label "Torsion cutoff" \
        widget MONI_TORCUT \
        message "List distances greater than dscut from ideal" \
        label "Distance cutoff" \
        widget MONI_DSCUT \
        format template MONITOR

  CreateLine line \
        message "List planes differing more than plcut from idea" \
	help moni \
        label "Plane cutoff" \
        widget MONI_PLCUT \
        message "List contact distances less than vdwcut" \
        label "VDW cutoff" \
        widget MONI_VDWCUT \
        format template MONITOR

## theres MONI_IHYDP and MONI_DBCUT

  CloseSubFrame

  CreateLine line \
        message "List shifts greater than badchi Angstrom" \
	help moni \
	label "Absolute shifts cutoff" \
	widget MONI_BADSHI \
	message "List restained chiral volumes differing more than badchi * chisig from ideal" \
	label "NxSigma chiral volume cutoff" \
	widget MONI_CHIRAL \
	format template MONITOR
	
#----------------------------------------------------------Geometric parameters

  OpenFolder 13 REFINE_TYPE hide { RIGID UNRE } closed

  OpenSubFrame frame 

  $frame configure -width 1000

  CreateLineTemplate TOP { 0.1 0.28 0.41 0.52 }
  CreateLineTemplate SIGMA6 { 0.0 0.28 0.41 0.52 0.64 0.76 0.88 }

  CreateLine line \
	label "Restraint" \
	label "Overall wt" \
	label "Sigmas" \
	format template TOP

  CreateLine line \
	label " " \
	label " " \
	label "bonded" \
	label "non-bond" \
	label "planar" \
	label "H-atom" \
	label "special" \
	format template SIGMA6

  CreateLine line \
	message "Enter Overall weight(WDSKAL) for distance restraints" \
        widget IFDIST -toggleon \
	label "Distance" \
	help dist \
	widget WDSKAL \
	message "Enter weight for bonded distance restraint (SIGD1)" \
	widget SIGD1 \
	message "Enter weight for non-bonded distance restraint (SIGD2)" \
	widget SIGD2 \
	message "Enter weight for planar distance restraint (SIGD3)" \
	widget SIGD3 \
	message "Enter weight for distance restraint involving an hydrogen atom (SIGD4)" \
	widget SIGD4 \
	message "Enter weight for distance restraint involving a special group (SIGD5)" \
	widget SIGD5 \
	format template SIGMA6

  CreateLine line \
        message "Enter overall weight (WBSKAL) for Bfactor restraints" \
        widget IFTMP -toggleon \
	label "Bfactor" \
	help bfac \
	widget WBSKAL \
	message "Enter weight for bonded Bfactor restraint (SIGB1)" \
	widget SIGB1 \
	message "Enter weight for non-bonded Bfactor restraint (SIGB2)" \
	widget SIGB2 \
	message "Enter weight for planar Bfactor restraint (SIGB3)" \
	widget SIGB3 \
	message "Enter weight for Bfactor restraint involving an hydrogen atom (SIGB4)" \
	widget SIGB4 \
	format template SIGMA6

  CreateLine line \
	label " " \
	label " " \
	label "peptide" \
	label "aromatic" \
	format template SIGMA6


  CreateLine line \
	message "Enter overall weight (WPSKAL) for plane restraints" \
	help plan \
        widget IFPLAN -toggleon \
	label "Plane" \
	widget WPSKAL \
	message "Enter weight for petide plane restraints (SIGPP)" \
	widget SIGPP \
	message "Enter weight for aromatic plane restraints (SIGPA)" \
	widget SIGPA \
	format template SIGMA6

  CreateLine line \
	label " " \
	label " " \
	label "chiral" \
	format template SIGMA6

  CreateLine line \
	message "Enter overall weight (WCSKAL) for chiral restraints" \
	help chir \
        widget IFCHIR -toggleon \
	label "Chiral" \
	widget WCSKAL \
	message "Enter and weight for chiral restraints (SIGC) " \
	widget SIGC \
	format template SIGMA6

  CreateLine line \
        label " " \
        label " " \
        label "special" \
	label "planar"  \
	label "staggered" \
	label "orthonormal" \
	format template SIGMA6

  CreateLine line \
        message "Enter overall weight (WTSKAL) for torsion restraints" \
	help tors \
        widget IFTORS -toggleon \
	label "Torsion" \
	widget WTSKAL \
        message "Enter weight for a pre-defined torsion restraints (SIGT1) " \
	widget SIGT1 \
        message "Enter weight for a planar torsion restraints (SIGT2) " \
	widget SIGT2 \
        message "Enter weight for a staggered torsion restraints (SIGT3) " \
	widget SIGT3 \
        message "Enter weight for a orthonormal torsion restraints (SIGT4) " \
	widget SIGT4 \
	format template SIGMA6

  CreateLine line \
	label " " \
	label " " \
	label "tight" \
	label "medium" \
	label "loose" \
	format template SIGMA6

  CreateLine line \
        message "Enter overall weight (WSSKAL) for NCS xyz & Bfactor restraints" \
	help ncsr \
	widget IFNCSR -toggleon \
	label "NCS position" \
	widget WSSKAL \
        message "Enter weight for NCS tight positional restraints (SIGSP1)" \
	widget SIGSP1 \
        message "Enter weight for NCS medium positional restraints (SIGSP1)" \
	widget SIGSP2 \
        message "Enter weight for NCS loose positional restraints (SIGSP1)" \
	widget SIGSP3 \
	format template SIGMA6

  CreateLine line \
	help ncsr \
        label "     NCS Bfactor " \
        label " " \
        message "Enter weight for NCS tight Bfactor restraints (SIGSB1)" \
        widget SIGSB1 \
        message "Enter weight for NCS medium Bfactor restraints (SIGSB2)" \
        widget SIGSB2 \
        message "Enter weight for NCS loose Bfactor restraints (SIGSB3)" \
        widget SIGSB3 \
        format template SIGMA6

# customise so changing SIGSB1/SIGSB2/SIGSB3 will toggle on the IFNCSR

   bind $line.e3 <KeyRelease> "toggle_on $arrayname IFNCSR"
   bind $line.e4 <KeyRelease> "toggle_on $arrayname IFNCSR"
   bind $line.e5 <KeyRelease> "toggle_on $arrayname IFNCSR"


  CreateLine line \
        label "VDW contacts" \
        label "Overall wt" \
        label "Sigma" \
        label "Contact distance increment" \
        format template TOP

  CreateLine line \
        label " " \
        label " " \
        label " " \
        label "1 torsion" \
        label "\>1 torsion" \
        label "Hbond" \
        format template SIGMA6
   

   CreateLine line \
        widget IFVAND -toggleon \
	label "VDW contacts" \
	message "Enter overall weight (WVSKAL) for VDW contacts" \
	help restr_vdwr \
	widget WVSKAL \
	message "Enter weight for VDW contacts (SIGV)" \
        widget SIGV \
	message "Increment to maximum contact distance across single torsions(DINC(1))" \
	widget DINC1 \
	message "Increment to maximum contact distance across multiple torsions(DINC(2))" \
	widget DINC2 \
	message "Increment to maximum contact distance for possible Hbonds(DINC(3))" \
	widget DINC3 \
	format template SIGMA6


  CreateLine line \
	label " " \
	label " " \
	label "position" \
	label "Bfactor" \
	label "occupancy" \
	format template SIGMA6

  CreateLine line \
	help hold \
        widget IFHOLD -toggleon \
	label "Shift magnitude" \
	label " " \
	message "Enter position shift magnitude restraints (PBEL)" \
	widget PBEL \
	message "Enter Bfactor shift magnitude restraints (BDEL)" \
	widget BDEL \
	message "Enter occupancy shift magnitude restraints (QDEL)" \
	widget QDEL \
	format template SIGMA6


    CreateLine line \
        label "Anisotropic refinement" \
        label " " \
        label sphericity \
        label "bond projection" \
	format template SIGMA6

  CreateLine line \
	label " " \
        label " " \
	widget SPHERICITY \
	widget RBOND \
	format template SIGMA6

  

  set width [$frame cget -width]

  CloseSubFrame

}
