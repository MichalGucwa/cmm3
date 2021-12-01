#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs, Alexei Vagin
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# ======================================================================
# molrep.tcl --
#
# Molecular Replacement
#
# CCP4Interface 
#
# =======================================================================

#-----------------------------------------------------------------------
proc molrep_setup { typedefVar arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $typedefVar typedef

  set typedef(_molrep_mode) { menu { "molecular replacement"
				"search in the map"
				"self rotation function"
				"fitting two molecules"
				"transform model"   
				"pure RB refinement"   
				"alignment only"   
				"HA search"  } 
			  { CROSS PRF SELF FIT TRANSFORM RB LN HA } }

  set typedef(_molrep_function) { menu { "rotation function" 
				"translation function inputting rotation peaks"
				"rotation and translation function"  }
			{ R T A } }

  set typedef(_molrep_model) { menu { "no editing"
				"only shift to origin" 
				"set all Bvalues to 20 & shift to origin" 
				"set Bvalues related to accessibility & shift to origin"
				"use B from file & B related to accessibility only for PF"
				"convert to polyalanine & shift to origin" }
			{ N O 2 Y C A } }

  set typedef(_molrep_nmr)	{ menu  { "all models in file as single model"
                                        "specific model in file"
					"NMR ensemble with averaged rotation function"
					"output single model (best solution of averaged RF and individual TFs)"
                                        "output NMR ensemble (best solution of averaged RF and TF)" }
					{ 0 -1 1 2 3 } }

  set typedef(_molrep_aniso) { menu { "Use default scaling"
		"Use isothermal scaling"
		"Use anisothermal correction and scaling"
		"Use anisothermal correction in rotation function only"
		"Use anisothermal scaling for translation function only"
                "Use scaling without using B_overall-factor" }
		{ D N Y C S K } }

  set typedef(_molrep_pseudo_trans) {  menu { "Auto" "Use" "Do not use" \
			"Check but do not use" } { A Y N C }  }

  set typedef(_molrep_dyad)	{ menu { "Do not use"    \
                                         "multi-copy search"     \
                         "dyad search (one or two different models)"   }
				{ N Y D } }
					

  set typedef(_molrep_dyad_mode) { menu { "conventional way" \
				"use all symmetry related peaks" \
				"use peaks in self-rotation function"} \
				{ USER ALL SELF} } 

  set typedef(_molrep_use_diff_sfs) { menu { "unmodified SFs"
					"SFs from masked map"
					"difference SFs"
					"vector difference SFs" }
					{ "" M P F } }

  set typedef(_molrep_use_sg_num) { menu { "Do not change"
					"check all"
					"define space group" }
					{ "" A D } }

  set typedef(_laue_space_group) { varmenu LAUE_SPGP_LIST LAUE_SPGP_ALIAS 8 }

  DefineMenu _molrep_input_sf_type [list "MTZ file" "EM map" "CIF file"] \
                                          [list HKLIN MAPIN CIFIN]

  DefineMenu _molrep_input_model_type [list "PDB file" "EM map"] \
                                          [list PDB MAP]

  DefineMenu _molrep_mode_protocol [list \
            "standard RF and TF without rigid body refinement (`fast' mode)" \
            "standard RF and advanced TF without rigid body refinement (`medium' mode)" \
            "advanced RF and TF with rigid body refinement (`slow' mode)"] \
              [list F M S]

  DefineMenu _molrep_ptf_mode [list " Phased" \
				    " Patterson"] \
      [list Y S]

  DefineMenu _molrep_dom  [list "as single body" \
				"multi-domain refinement" \
				"only information about domain structure" \
				"multi-domain refinement with constraints" \
				"create complete model using NCS"] \
      [list N Y I S C]

  DefineMenu _molrep_ha  [list "find HA by model" \
			       "Self RF for HA"  \
			       "HA search"] \
      [list N R S ]

  return 1

}


#-----------------------------------------------------------------------
proc molrep_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  # Source for input structure factors
  if { [GetValue $arrayname INPUT_SF_TYPE] == "MAPIN" } {
    set input_sf_file MAPIN
  }

  if { [GetValue $arrayname INPUT_SF_TYPE] == "CIFIN" } {
    set input_sf_file CIFIN
  }

  if { [GetValue $arrayname INPUT_SF_TYPE] == "HKLIN" } {
    set input_sf_file HKLIN
  }

  switch [GetValue $arrayname MOLREP_MODE] \
  CROSS  {  set array(INPUT_FILES) "$input_sf_file XYZIN"
    if { $array(SEQIN) != "" } { append array(INPUT_FILES) " SEQIN" } 
    if $array(IFFIXED) { append array(INPUT_FILES) " XYZFIXED" }

  } SEARCH {  set array(INPUT_FILES) "$input_sf_file XYZIN"
    if $array(IFFIXED) { append array(INPUT_FILES) " XYZFIXED" }
  } SELF {  set array(INPUT_FILES) "$input_sf_file"
  } FIT { set array(INPUT_FILES) "XYZIN XYZIN2" 
  } LN { set array(INPUT_FILES) "XYZIN SEQIN" 
  } RB { set array(INPUT_FILES) "XYZIN2" 
  } PRF { set array(INPUT_FILES) "XYZIN" 
    if $array(IFFIXED) { append array(INPUT_FILES) " XYZFIXED" }
  } HA { if { [GetValue $arrayname IHA] == "N" } { set array(INPUT_FILES) "XYZIN2" }
  } TRANSFORM { set array(INPUT_FILES) XYZIN }

  switch [GetValue $arrayname MOLREP_MODE] \
  SELF { set array(OUTPUT_FILES) ""
  } HA { set array(OUTPUT_FILES) ""   
  } default {  set array(OUTPUT_FILES) XYZOUT  }

  if { ![StringSame $array(FILE_SPACE_GROUP) \
              [GetValue $arrayname TEST_SPACE_GROUP] ] } {
    set array(SPACE_GROUP_NUMBER) [GetSpaceGroupNumber $array(TEST_SPACE_GROUP)]
  } else {
    set array(SPACE_GROUP_NUMBER) ""
  }


  if { [GetValue $arrayname INPUT_SF_TYPE] == "MAPIN" } {
    set array(SPACE_GROUP_NUMBER) ""
  }

  if { !$array(IFFIXED) } { 
   set array(USE_DIFF_SFS) "" 
   set array(PERCENT_MODEL) ""
  } 

  # Selected NMR model
  if { [GetValue $arrayname NMR_MODEL] == -1 && $array(NMR_MODEL_NUM) == "" } {
    WarningMessage "You have not specified which NMR
model to use from the input PDB file.

Please select a model number before
running the task."
    return 0
  }

  return 1

}

#-----------------------------------------------------------------------
proc Molrep_GetXmlDefaults { arrayname } {
#-----------------------------------------------------------------------
# Get the default values of some parameters from XML files, unless
# already set e.g. by re-running a job
   upvar #0 $arrayname array
   set xmlfile1 [FileJoin [GetDbDirPath] $array(XMLFILE1)]
   set xmlfile2 [FileJoin [GetDbDirPath] $array(XMLFILE2)]

   # Make sure that the xml data is reloaded from file
   XmlDataReset

   # Fetch the values from the files
   if { [file exists $xmlfile1] && $array(NMONOMERS) == 0 } {
     set array(NMONOMERS) [GetMolrepNMonomers $xmlfile1] 
   }

   if { [file exists $xmlfile2] && [GetValue $arrayname PSEUDO_TRANS_MODE] == "A" } {
     set peak_no [GetMolrepPseudoTransPeak $xmlfile2]
     if { $peak_no > 0 } {
       set array(PSEUDO_TRANS_MODE) "A"
       set array(PSEUDO_TRANS) [GetMolrepPseudoTrans $xmlfile2 $peak_no]
     }
   }
}

#-----------------------------------------------------------------------
proc Molrep_change_mode { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [StringSame [GetValue $arrayname MOLREP_MODE] SEARCH RB] && \
		$array(IFPHASES) } {
    set array(IFPHI) 1
    set array(IDYAD2) 0
  } else {
    set array(IFPHI) 0
  }
  switch [GetValue $arrayname MOLREP_MODE] \
  CROSS {
    set array(FUNCTION) "rotation and translation function" 
    set array(IFPHI) 0
    set array(IFPRF) 0
    set array(IFANOMALOUS) 0
    set array(IFDER) 0
  }
  switch [GetValue $arrayname MOLREP_MODE] \
  LN {
    set array(IFSEQ) 1 
    set array(IFPRF) 0
    set array(IDYAD2) 0
    set array(SPACE_GROUP_NUMBER) ""
    set array(USE_GROUP_NUMBER) "N" 
  }
  switch [GetValue $arrayname MOLREP_MODE] \
  HA {
    set array(IFSEQ) 0 
    set array(IFPRF) 0
  }
  switch [GetValue $arrayname MOLREP_MODE] \
  FIT {
    set array(IFFIXED) 0 
    set array(IFPRF) 0
    set array(IDYAD2) 0
    set array(SPACE_GROUP_NUMBER) ""
    set array(USE_GROUP_NUMBER) "N" 
  }
  switch [GetValue $arrayname MOLREP_MODE] \
  PRF {
    set array(IFPRF) 1 
    set array(IFPHI) 1
    set array(IDYAD2) 0
    set array(IFPHASES) 1
  } else {
    set array(IFPRF) 0
    set array(IFPHASES) 0
  }
}

#---------------------------------------------------------------------
proc molrep_set_test_space_group { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  set spgp_list {}
  set spgp_alias {}

  set laue_no [GetLaueGroupNumber $array(FILE_SPACE_GROUP)]
# update the varlabel
  set field_list [GetWidget $arrayname FILE_SPACE_GROUP]
  foreach field $field_list {
    if { [winfo exists $field] } {
      $field configure -text $array(FILE_SPACE_GROUP) }
  }


  if { $laue_no <= 0 } {
    lappend spgp_list $array(FILE_SPACE_GROUP)
    lappend spgp_alias [GetSpaceGroupNumber $array(FILE_SPACE_GROUP)]
  } else {
    set spgp_alias [GetLaueGroup $laue_no]
    foreach gp_no $spgp_alias {
      lappend spgp_list [GetSpaceGroupCode $gp_no]
    }
  }

  UpdateVariableMenu $arrayname initialise [llength $array(LAUE_SPGP_LIST)] \
        LAUE_SPGP_LIST $spgp_list \
        MODEL_ALIAS_LIST $spgp_alias

  set array(TEST_SPACE_GROUP) [GetSpaceGroupCode $array(FILE_SPACE_GROUP)]

}

#-----------------------------------------------------------------------
proc molrep_task_window {arrayname} {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow  $arrayname \
 	"Molrep - Molecular Replacement" "Molrep" \
       [list "Experimental Data (Resolution,ANISO,DIFF,BADD,INVER,DSCALE,...)" \
        "The Model (SIM,COMPL,SURF,NMR,NCSM,DSCALEM...)"  \
	"Search Parameters (NMON,NP,NPT,PST,STICK,LOCK,...)"  \
        "Multi-copy Search " \
	"Parameters for Self-Rotation Function" \
        "Parameters for RB (Nref,NSC_id,DOM)" \
        "Parameters for HA" \
        "Parameter for SEQ" \
	"Infrequently Used Parameters (MODE,SAPTF,RAD,PACK,SCORE,LMIN,NOSG)" ] ] == 0 } return

  Molrep_change_mode $arrayname

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateLine line \
    label "This interface is for version 11.2 of Molrep" -italic

  CreateTitleLine line TITLE

  CreateLine line \
    message "Choose basic operation of Molrep" \
    help molrep_mode \
    label "Do" \
    widget MOLREP_MODE \
      -command "Molrep_change_mode $arrayname" \
    toggle_display MOLREP_MODE hide [list CROSS SEARCH]

  CreateLine line \
    message "Choose basic operation of Molrep" \
    label "Do" \
    widget MOLREP_MODE \
      -command "Molrep_change_mode $arrayname" \
    label  "performing" \
    widget FUNCTION \
    toggle_display MOLREP_MODE open [list CROSS SEARCH]


  OpenSubFrame frame -toggle_display MOLREP_MODE hide [list FIT LN]

  CreateLine line \
    message "Use SF amplitudes from MTZ file or SF generated from an EM map" \
    label "Get input structure factors from" \
    widget INPUT_SF_TYPE

  CreateLine line \
    widget IFFIXED \
    label "Input fixed model"  \
    toggle_display MOLREP_MODE open  [list CROSS PRF]

  CreateLine line \
    widget IDYAD \
    label "Multi-copy search" \
    toggle_display MOLREP_MODE open  [list CROSS]

  CreateLine line \
    message "Model correction by sequence" \
    widget IFSEQ \
    label "Use sequence" \
    toggle_display MOLREP_MODE open [list CROSS LN]

  CloseSubFrame


  OpenSubFrame frame -toggle_display MOLREP_MODE open [list PRF]

  CreateLine line \
    message "MR protocol involving spherically averaged phased translation function" \
    widget USE_SPHERE_AVER \
    label "Use SAPTF" \
    toggle_display USE_SPHERE_AVER hide 1

  CreateLine line \
    message "MR protocol involving Spherically Averaged Phased Translation Function" \
    widget USE_SPHERE_AVER \
    label "Use SAPTF followd by local" \
    widget PTF_MODE \
    label "RF and Phased TF" \
    toggle_display USE_SPHERE_AVER open 1

  CloseSubFrame


#=FILES================================================================

  OpenFolder file 

  OpenSubFrame frame -toggle_display MOLREP_MODE hide [list FIT LN]

  # Subframe for HKLIN input
  OpenSubFrame frame -toggle_display INPUT_SF_TYPE open HKLIN

  CreateInputFileLine line \
	"Enter input MTZ file name (HKLIN)" \
	"MTZ in" \
	HKLIN DIR_HKLIN \
	-setfileparam space_group_name FILE_SPACE_GROUP \
	-command "molrep_set_test_space_group $arrayname"

  CreateLine line \
    label "Use" \
    widget IFINT \
    label "Intensities" 

  CreateLine line \
    label "Use" \
    widget IFANOMALOUS \
    label "anomalous data from input MTZ file" \
    toggle_display MOLREP_MODE open HA

  CreateLine line \
    label "Use" \
    widget IFDER \
    label "derivative data from input MTZ file" \
    toggle_display MOLREP_MODE open HA

  CreateLine line \
    label "Use" \
    widget IFPHASES \
      -command "Molrep_change_mode $arrayname" \
    label "experimental phases from input MTZ file" \
      toggle_display MOLREP_MODE open [ list SEARCH RB]

  OpenSubFrame frame -toggle_display IFINT open 0

  CreateLabinLine line \
    "Choose amplitude (F) and optional sigma (SIGF)" \
     HKLIN "FP"  FP  {NULL} \
     -sigma "SIGFP" SIGFP  {NULL} \
     -toggle_display IFANOMALOUS hide 1

  CreateLabinLine line \
    "Choose amplitude F(+) and optional sigma SIGF(+)" \
     HKLIN "F(+)"  FP  {NULL} \
     -sigma "SIGF(+)" SIGFP  {NULL} \
     -toggle_display IFANOMALOUS open 1

  CreateLabinLine line \
    "Choose amplitude F(-) and optional sigma SIGF(-)" \
     HKLIN "F(-)"  FPm  {NULL} \
     -sigma "SIGF(-)" SIGFPm  {NULL} \
     -toggle_display IFANOMALOUS open 1

  CreateLabinLine line \
    "Choose amplitude DP and optional sigma SIGDP" \
     HKLIN "DP"  DP  {NULL} \
     -sigma "SIGDP" SIGDP  {NULL} \
     -toggle_display IFANOMALOUS open 1

  CloseSubFrame

  OpenSubFrame frame -toggle_display IFINT open 1

  CreateLabinLine line \
    "Choose intensity (I) and optional sigma (SIGI)" \
     HKLIN "I" I  {NULL} \
      -sigma "SIGI" SIGI  {NULL} \
     -toggle_display IFANOMALOUS hide 1

  CreateLabinLine line \
    "Choose intensity I(+) and optional sigma SIGI(+)" \
     HKLIN "I(+)" I   {NULL} \
     -sigma "SIGI(+)" SIGI {NULL} \
     -toggle_display IFANOMALOUS open 1

  CreateLabinLine line \
    "Choose intensity I(-) and optional sigma SIGI(-)" \
     HKLIN "I(-)" Im   {NULL} \
     -sigma "SIGI(-)" SIGIm {NULL} \
     -toggle_display IFANOMALOUS open 1

  CloseSubFrame

  OpenSubFrame frame -toggle_display IFDER open 1

  CreateLabinLine line \
    "Choose amplitude (FD) and optional sigma (SIGFD)" \
     HKLIN "FD"  FD  {NULL} \
     -sigma "SIGFD" SIGFD  {NULL} 

#     -toggle_display IFANOMALOUS open 0

  CloseSubFrame

  CreateLabinLine line \
    "Choose phase (PH) and optional weighting factor (FOM)" \
     HKLIN "PH  " PHI   {} \
     -sigma "Weight" FOM  {} \
     -toggle_display IFPHI open 1

  CloseSubFrame

  # EM map input
  CreateInputFileLine line \
     "Enter EM map file name (MAPIN)" \
     "EM map" \
     MAPIN DIR_MAPIN \
        -toggle_display INPUT_SF_TYPE open MAPIN

  # CIF input
  CreateInputFileLine line \
     "Enter CIF file name (CIFIN)" \
     "CIF in" \
     CIFIN DIR_CIFIN \
        -toggle_display INPUT_SF_TYPE open CIFIN

  OpenSubFrame frame -toggle_display INPUT_SF_TYPE open CIFIN

  CreateLine line \
    label "Use" \
    widget IFPHASES \
      -command "Molrep_change_mode $arrayname" \
    label "experimental phases from input CIF file" \
      toggle_display MOLREP_MODE open [ list SEARCH RB PRF ]

  CloseSubFrame

  CloseSubFrame

  CreateInputFileLine line \
     "Enter input model file name (MODEL)" \
     "Model in" \
     XYZIN DIR_XYZIN \
      -toggle_display MOLREP_MODE hide [ list SELF  RB  HA] \
     -fileout XYZOUT DIR_XYZOUT _molrep

  CreateInputFileLine line \
     "Enter fixed model file name (MODEL_2)" \
     "Fixed in" \
     XYZFIXED DIR_XYZFIXED \
     -toggle_display IFFIXED open 1

  CreateInputFileLine line \
     "Enter second molecule file name (MODEL_2)" \
     "Model2 in" \
     XYZIN2 DIR_XYZIN2 \
     -toggle_display MOLREP_MODE open FIT 

  CreateInputFileLine line \
     "Enter model file name (MODEL_2)" \
     "Model in" \
     XYZIN2 DIR_XYZIN2 \
      -toggle_display MOLREP_MODE open RB 
#     -fileout XYZOUT DIR_XYZOUT _molrep

  OpenSubFrame  frame -toggle_display MOLREP_MODE open HA

  CreateInputFileLine line \
     "Enter model file name (MODEL_2)" \
     "Model in" \
     XYZIN2 DIR_XYZIN2 \
     -toggle_display IHA open N

  CloseSubFrame

  CreateInputFileLine line \
     "Enter file containing rotation and translation function solutions"  \
     "Solution file" \
     ROT_SOLUTIONS DIR_ROT_SOLUTIONS \
      -toggle_display MOLREP_MODE open TRANSFORM

  CreateInputFileLine line \
     "Enter file containing rotation function solutions"  \
     "Rot solutions" \
     ROT_SOLUTIONS DIR_ROT_SOLUTIONS \
      -toggle_display FUNCTION open T

# OpenSubFrame  frame -toggle_display IFPRF open 1
#
# CreateInputFileLine line \
#    "Enter file containing info for phased rotation function"  \
#    "Solutions (FILE_T2)" \
#    ROT_SOLUTIONS DIR_ROT_SOLUTIONS \
#     -toggle_display FUNCTION  hide T
#
# CloseSubFrame


  OpenSubFrame  frame -toggle_display IDYAD2 open 1

  CreateInputFileLine line \
     "Enter second molecule file name (FILE_M2)" \
     "Model2 in" \
     XYZIN_T2 DIR_XYZIN_T2 \
      -toggle_display IDYAD open 1

  CreateInputFileLine line \
     "Enter file containing rotation function solutions for second molecule" \
     "Rot solns for Model2" \
     ROT_SOLUTIONS2 DIR_ROT_SOLUTIONS2 \
      -toggle_display IDYAD open 1 

  CloseSubFrame

#  CreateLine line \
#    widget MODEL_MAP \
#    label "Model is the map" \
#   -toggle_display MOLREP_MODE hide [ list LN FIT ]

  OpenSubFrame  frame -toggle_display MODEL_MAP open 0

  CreateOutputFileLine line \
    "Enter name for output coordinate file (XYZOUT)" \
    "Coords out" \
    XYZOUT DIR_XYZOUT \
      -toggle_display MOLREP_MODE hide [ list SELF HA LN ]
  CloseSubFrame
     

#=PARAMETERS==========================================================

#--The atomic model-----------------------------------------------

  OpenFolder 2 MOLREP_MODE hide SELF closed 


  CreateLine line \
    message "Model correction (SURF)" \
    label "Apply" \
    help surf \
    widget MODEL_CORRECTION \
    label "to model"

#  CreateLine line \
#    message "Model correction by sequence" \
#    widget IFSEQ \
#    label "Use sequence"

#  CreateInputFileLine line \
#     "Enter name of file containing the target sequence(FILE_S)" \
#     "Seq in" \
#     SEQIN DIR_SEQIN \
#     -notoblig \
#     -toggle_display IFSEQ open 1 

  CreateLine line \
    message "Handling of input PDB files containing multiple models (NMR)" \
    help NMR \
    label "If input PDB is for NMR models then use" \
    widget NMR_MODEL

  CreateLine line \
    message "You can specify model number in the file to use (1=first etc)" \
    help NMR \
    label "Use NMR model number" \
    widget NMR_MODEL_NUM \
    label "from the input PDB file" \
    toggle_display NMR_MODEL open -1

  CreateLine line \
    message "Range from 0.2 to 1.0 - determines the Boff (COMPL)" \
    help compl \
    label "Expect" \
    widget COMPLETENESS \
    label "fraction completeness of model with" \
    message "Range from 0.1 to 1.0 - determines Badd (SIM)" \
    help sim \
    widget SIMILARITY \
    label "fraction similarity to input structure"

  CreateLine line \
    message "number of subunits in the model (only for scoring)" \
    label "number of subunits in the model NCSM" \
    widget NCSM \
    label " only for scoring (default from model Self RF)" 


  CreateLine line \
    widget MODEL_MAP \
    label "Model is the map" \
   -toggle_display MOLREP_MODE hide [ list LN FIT ]

  OpenSubFrame frame -toggle_display  MODEL_MAP open 1

  CreateLine line \
    label "Set parameters for using the map as the model:" \
    -italic

  CreateLine line \
    message "Leave blank for default 1.0" \
    label "Scale factor of correction of density cell" \
    widget DSCALEM

  CreateLine line \
    help rolim \
    message "Density below this value will not be used (ROLIM keyword)" \
    label "Minimal value of density which will be used:" \
    widget ROLIM

  CreateLine line \
    help drad \
    message "Only use density inside this radius (DRAD keyword)" \
    label "Radius of the model" \
    widget DRAD \
    label "(Angstroms)"

   CreateLine line \
    help origin \
    message "Specify a vector x,y,z in fractional units (ORIGIN keyword)" \
    label "Centre of the model in the unit cell (in fract. units)" \
    widget ORIGIN -width 30

   CreateLine line \
    help inverm \
    message "Inverted phases will be used (INVERM keyword)" \
    widget INVERM \
    label "Use inverted map (i.e. inverted phases)" 

  CloseSubFrame

#--SEARCH-------------------------------------------------------------------

  OpenFolder 3 MOLREP_MODE hide SELF closed

  CreateLine line \
    message "Expected number of monomers (NMON), 0 means automatic choice" \
    help nmon \
    label "Search for" \
    widget NMONOMERS \
    label "monomers in the asymmetric unit" \
    toggle_display MODEL_MAP hide 1

#  OpenSubFrame frame -toggle_display FUNCTION open R

  CreateLine line \
    widget LOCK \
    label "Locked Rotation Function"

  CreateLine line \
    label "Use Self Rotation function with " \
    widget CROSS_NSRF \
    label "peaks from the self-rotation function"

  CreateInputFileLine line \
     "Enter file containing self-rotation function solutions"  \
     "Self RF  solutions" \
     SROT_SOLUTIONS DIR_SROT_SOLUTIONS \

#  CloseSubFrame

  CreateLine line \
    message "Leave blank for default (NP)" \
    help np \
    label "Search for" \
    widget NPEAKS_ROT \
    label "peaks in rotation map and" \
    message "Leave blank for default (NPT)" \
    help npt \
    widget NPEAKS_TRAN \
    label "in translation function"

   CreateLine line \
    message "Pseudo translation added in translation function (PST)" \
    widget PSEUDO_TRANS_MODE \
    label "pseudo-translation vector" \
    message "Enter u,v,w - with no input will be calculated automatically (VPST)" \
    widget PSEUDO_TRANS -width 30

  CreateLine line \
    help stick \
    widget STICK \
    label "Output the closest of symmetry-equivalent monomers to the coordinates file"


#--Infrequently--------------------------------------------------------

  OpenFolder 9 MOLREP_MODE hide SELF closed

   CreateLine line \
     message "Change space group" \
     label "Change space group" \
     widget USE_GROUP_NUMBER 

  OpenSubFrame frame -toggle_display INPUT_SF_TYPE open HKLIN

#  CreateLine line \
#    message "Space group assigned in MTZ file" \
#    label "Space group read from MTZ file" \
#    varlabel FILE_SPACE_GROUP \

  CreateLine line \
    message "Space group assigned in MTZ file" \
    label "Space group read from MTZ file" \
    varlabel FILE_SPACE_GROUP \
    message "Test alternative space groups?" \
    label ". Run Molrep with test space group" \
    widget TEST_SPACE_GROUP \
    toggle_display USE_GROUP_NUMBER open [list D ]
#    toggle_display INPUT_SF_TYPE open HKLIN

  CloseSubFrame

  OpenSubFrame frame -toggle_display INPUT_SF_TYPE open CIFIN

  CreateLine line \
    message "Test alternative space groups?" \
    label "Run Molrep with test space group number" \
    widget ISPACE_GROUP_NUMBER \
    toggle_display USE_GROUP_NUMBER open [list D ]
#    toggle_display INPUT_SF_TYPE open CIFIN

  CloseSubFrame

  CreateLine line \
    message "Choose RF and TF method and refinement protocol - better is also slower (MODE)" \
    help mode \
    label "Use" \
    widget MODE_PROTOCOL

  CreateLine line \
    message "Leave blank for auto calculation from model (RADIUS)" \
    label "Search radius" \
    widget SEARCH_RADIUS

  CreateLine line \
    message "Use Packing function " \
    help pack \
    widget PACKING \
    label "Use packing function with translation function"

  CreateLine line \
    message "scoring system" \
    help list \
    widget SCORE \
    label "turn off scoring system" 

#  OpenSubFrame frame -toggle_display IFPHASES open 0
#
#  OpenSubFrame frame -toggle_display INPUT_SF_TYPE open MAPIN
#
#  CreateLine line \
#   message "phased rotation function for positions from FILE_T" \
#   widget IFPRF \
#   label "use phased rotation function"  
#
#  CloseSubFrame
#
#  CloseSubFrame
#
#  OpenSubFrame frame -toggle_display IFPHASES open 1
#
#  CreateLine line \
#    widget IFPRF \
#    label "use phased rotation function" \
#    toggle_display INPUT_SF_TYPE hide MAPIN
#
#  CloseSubFrame

  CreateLine line \
    label "number of cycles of RB refinement" \
    widget NREF \
    label "after TF" \
    widget NREFP \
    label "before TF"

  CreateLine line \
    label "Nptd" \
    widget NPEAKS_SPEC 

  CreateLine line \
    message "minimal L-index of spherical coefficients (LMIN)" \
    label "Lmin" \
    widget LMIN

#-----Multi-copy search -------------------------------------------------------

  OpenFolder 4 IDYAD hide 0 closed

  CreateLine line \
    help dyad  \
    label "Do" \
    widget DYAD 

  CreateLine line \
    widget IDYAD2 \
    label "search for two different models" \
    toggle_display DYAD hide Y


  CreateLine line \
    label "Search mode" \
    widget DYAD_MODE

  OpenSubFrame frame -toggle_display DYAD_MODE open SELF

  CreateLine line \
    help nsrf \
    label "Use information from self-rotation function" \
    widget DYAD_NSRF \
    label "peaks from the self-rotation function"

  CreateInputFileLine line \
     "Enter file containing self-rotation function solutions"  \
     "Rot solutions" \
     SROT_SOLUTIONS DIR_SROT_SOLUTIONS

  CloseSubFrame

  CreateLine line \
    label "Search range centred on chi" \
    widget DYAD_CHI \
    label "with delta chi" \
    widget DYAD_DELTA \
    toggle_display DYAD_MODE open USER

  CreateLine line \
    help dist \
    widget DYAD_DIST -toggleon \
    label "Distance between molecules minimum" \
    widget DYAD_DMIN \
    label "to maximum" \
    widget DYAD_DMAX \
    label "Maximum shift along rotation axis" \
    widget DYAD_DPAR

  CreateLine line \
    help dyad_npt \
    label Check \
    widget NPEAKS_SPEC \
    label "peaks in the Special Translation Function and" \
    widget NPEAKS_TRAN \
    label "peaks in the translation function"

  OpenSubFrame frame -toggle_display IDYAD2 open 1

  CreateLine line \
    help dyad_np2 \
    label "Number of peaks in RF of second molecule to check" \
    widget DYAD_NP2 

#    toggle_display DYAD open D


  CreateLine line \
    message "Model correction by sequence" \
    widget IFSEQ2 \
    label "Use sequence2"

  CreateInputFileLine line \
     "Enter name of file containing the target sequence(FILE_S2)" \
     "Seq in" \
     SEQIN2 DIR_SEQIN2 \
     -notoblig \
     -toggle_display IFSEQ2 open 1 

 
  CloseSubFrame

#---Experimental data----------------------------------------------------

  OpenFolder 1 closed

   OpenSubFrame frame -toggle_display IFFIXED open 1

   CreateLine line \
     label "In SAPTF or RF, fixed model can be used to modify Structure Factors;" \

   CreateLine line \
     message "Use modified structure factors" \
     help diff \
     label "Use" \
     widget USE_DIFF_SFS \
     toggle_display USE_DIFF_SFS hide [list P F]

   CreateLine line \
     message "Use modified structure factors" \
     help diff \
     label "Use" \
     widget USE_DIFF_SFS \
     label "assuming"  \
     help P2 \
     message "Enter percentage of model to modify calculated SFs" \
     widget PERCENT_MODEL \
     label "% contribution from the fixed model"  \
     toggle_display USE_DIFF_SFS open [list P F]

  CloseSubFrame


  CreateLine line \
    message "Leave blank for default (RESMAX)" \
    help resmax \
    label "Use data to maximum resolution" \
    widget MAX_RESOLUTION

   CreateLine line \
    message "Leave blank for default smooth cutoff (RESMIN)" \
    help res_r \
    label "minimum resolution" \
    widget MIN_RESOLUTION_ROT \

  CreateLine line \
    message "Scaling (ANISO)" \
    help aniso \
    widget ANISO

  CreateLine line \
    help badd \
    message "Modify SF's by additional Boverall factor" \
    widget BSCALE \
    label "Apply additional Boverall factor (Badd)" \
    widget BADD

   OpenSubFrame frame -toggle_display INPUT_SF_TYPE open MAPIN

    CreateLine line \
    message "Leave blank for default 1.0" \
    label "Scale factor of correction of density cell" \
    widget DSCALE

    CreateLine line \
    message "Leave blank for default (not used)" \
    label "minimal value of density to use" \
    widget DLIM

#   CreateLine line \
#    label "use inverted phases" \
#    widget INVER 

   CloseSubFrame

   CreateLine line \
    widget INVER \
    label "use inverted phases" \
    toggle_display IFPHASES open 1

#---SELF---------------------------------------------------------------------

  OpenFolder 5 MOLREP_MODE closed SELF hide
    
  CreateLine line \
    message "Leave blank for default radius (RADIUS)" \
    label "Search radius" \
    widget SEARCH_RADIUS

  CreateLine line \
    message "Additional angle of fourth section of rotation function (CHI) default 60" \
    label "Plot rotation function v. theta,phi for chi 180,90,120 and" \
    help chi \
    widget SELF_CHI \
    label "Scale plot by" \
    message "Maximal value of RF is SCALE*SIGMA(RF)  (SCALE) default 6" \
    help scale \
    widget SELF_SCALE

#-- RB ---------------------------------------------------------

   OpenFolder 6 MOLREP_MODE closed RB hide

  CreateLine line \
    label "Rigid Body refinement" \
    widget DOM 

  CreateLine line \
    label "number of cycles of RB refinement" \
    widget NREF 

  CreateLine line \
    label "NCS_id" \
    widget NCS 

  CreateLine line \
    label "Angles" \
    widget ANGLES -width 30 \
    label "Centre" \
    widget CENTRE -width 30

#-- HA ---------------------------------------------------------

  OpenFolder 7 MOLREP_MODE closed HA hide

  CreateLine line \
    label "Use" \
    widget IHA 

  CreateLine line \
    widget IDYAD \
    label "Multi-copy search" \
    toggle_display IHA open  S

#-- SEQ ---------------------------------------------------------

  OpenFolder 8 IFSEQ hide 0 open

#  OpenFolder 4 IDYAD hide 0 closed
#  OpenFolder 2 MOLREP_MODE hide SELF closed 

#  CreateLine line \
#    message "Model correction by sequence" \
#    widget IFSEQ \
#    label "Use sequence"

  CreateInputFileLine line \
     "Enter name of file containing the target sequence(FILE_S)" \
     "Seq in" \
     SEQIN DIR_SEQIN \
     -notoblig \
     -toggle_display IFSEQ open 1 

#-----------------------------------------------------------
  # Retrive defaults from XML file if available & requested
  source [SearchPath TOP utils xml_utils.tcl]
  if { [XmlStatus] == 1 } {
     Molrep_GetXmlDefaults $arrayname
  }
}
