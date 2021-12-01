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
proc refmac5_run { arrayname } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array

  set refine_type [GetValue $arrayname REFINE_TYPE ]

  if { [regexp IDEA|REVIEW $refine_type ] } {
    set array(INPUT_FILES) XYZIN
    set array(OUTPUT_FILES) XYZOUT
  } else {
    set array(INPUT_FILES) "XYZIN HKLIN"
    set array(OUTPUT_FILES) "XYZOUT HKLOUT"
  }

  if { [regexp TLS $refine_type ] } {
    if { [GetValue $arrayname TLSIN] != "" } {
      # User specified a TLS file
      append array(INPUT_FILES) " TLSIN"
    }
    append array(OUTPUT_FILES) " TLSOUT"
  } elseif { $array(IFFIXTLS) } {
    append array(INPUT_FILES) " TLSIN"
  }

  # Check to see if MAPOUT is set
  if { $array(IF_MAPOUT) } {
    if { $array(MAPOUT1) == "" } {
      WarningMessage "Input Warning: Fwt map name not specified. Will use default file name."
    }
    if { $array(MAPOUT2) == "" } {
      WarningMessage "Input Warning: DelFwt map name not specified. Will use default file name."
    }
  }
  
  if { ![regexp IDEA|REVIEW $refine_type ] } {

    # Check to see if need FREER column but it has not been set
    if { $array(EXCLUDE_FREER) } {
      if { $array(FREE) == "Unassigned" || $array(FREE) == "" } {
        WarningMessage "Free R label has not been set."
        return 0
      }
    }
  
  }  

  if { $array(MAKE_LIBRARY) != "" } { 
    append array(INPUT_FILES) " MAKE_LIBRARY" }
  append array(OUTPUT_FILES) " LIBOUT"

  set array(LABIN) "FP SIGFP"
  set array(LABOUT) "FC FWT PHIC PHWT DELFWT PHDELWT FOM"
  set phase [GetValue $arrayname INPUT_PHASE]
  if { [regexp NO $phase] } {
      if { [regexp [GetValue $arrayname TWINREF_TYPE] INTENSITIES] } {
        append array(LABIN) " IP SIGIP"
      }
  }
  if { [regexp SAD $phase] } {
    append array(LABIN) " F+ SIGF+ F- SIGF-"  
  } elseif [regexp PHASE $phase ] {
    append array(LABIN) " PHIB"
#     append array(LABOUT) " PHCOMB"
  } elseif [regexp HL $phase ] {
    if { [ RefmacCheckHLCoeffs $arrayname [list HLA HLB HLC HLD] ] == 0 } \
	    { return 0 }
    append array(LABIN) "  HLA HLB HLC HLD"
#    append array(LABOUT) " PHCOMB"
  }
    
# Sanity check - don't run Prosmart if it is not available!
  if { !$array(PROSMART_AVAIL) && ![regexp INPUT [GetValue $arrayname PROSMART_MODE] ] } { 
    set array(IFPROSMART) 0 
  }
  if { $array(IFPROSMART) && [regexp EXTERNAL [GetValue $arrayname PROSMART_MODE] ] } { 
    append array(INPUT_FILES) " EXT_XYZIN"
  }

# Make sure Coot is not on when inappropriate
  if { ![StringSame $refine_type REST UNRE] } { 
     set array(RUN_COOT_FW) 0 
  }
  if { !$array(RUN_COOT_FW) } { set array(EXTERNAL_NCYCLES) 1 }

# Check harvesting if not running idealisation or review (and harvesting is selected)
  if { ![StringSame $refine_type IDEA REVIEW] && \
	   ![StringSame [GetValue $arrayname HARVEST_MODE] NOHARVEST] } {
      if { ![SetHarvestParams $arrayname HKLIN  -run] } { return 0 } 
# refmac doesn't pick up pname/dname from MTZ file, so must use values found in GUI
      if { $array(HARVEST_PNAME) != ""  && $array(HARVEST_DNAME) != "" } {
           set array(HARVEST_INPUT_NAMES) 1
      }
  }

# Check have parameter for WEIGHT AUTO
  if { !$array(AUTO_WEIGHTING) } {
    if { $array(MATRIX_WEIGHT) == "" } {
	  WarningMessage "Set parameter for WEIGHT MATRIX or use automatic weighting"
	  return 0
    }
  }

# Set logicals for map sharpening
  if { $array(B_SHARP) == "" } { set array(IFBSHARP) 0 } else { set array(IFBSHARP) 1 }
  if { $array(AL_SHARP) == "" } { set array(IFALSHARP) 0 } else { set array(IFALSHARP) 1 }

# NCS restraints
# Check that each restraint is properly defined
  if { $array(N_NONX) > 0 } {
      set n_ncs 0
      for { set i 1 } { $i <= $array(N_NONX) } { incr i } {
	  # An NCS restraint is considered to be "defined" if the
	  # parameters are set such that keywords will be correctly
	  # generated in the keyworded script for that restraint
	  set defined 1
	  set varlist [list \
		  NONX_CHN_SRC \
		  NONX_CHN_TARG \
		  NONX_INIT_SPANS_RES1 \
		  NONX_INIT_SPANS_RES2]
	  foreach var $varlist {
	      if { $array([subst $var],$i) == "" } { set defined 0 }
	  }
	  # Additional spans
	  for { set j 1 } { $j <= $array(N_NONX_SPANS,$i) } { incr j } {
	      set varlist [list NONX_SPANS_RES1 NONX_SPANS_RES2]
	      foreach var $varlist {
		  if { $array([subst $var],[subst $i]_$j) == "" } {
		      set defined 0
		  }
	      }
	  }
	  # Additional chains
	  for { set j 1 } { $j <= $array(N_NONX_CHN,$i) } { incr j } {
	      set varlist [list NONX_CHN]
	      foreach var $varlist {
		  if { $array([subst $var],[subst $i]_$j) == "" } {
		      set defined 0
		  }
	      }
	  }
	  # Checks complete for this restraint - is it defined?
	  if { $defined } {
	      incr n_ncs
	      # Set parameters for script
	      # Actual number of chains is N_NONX_CHN + 2
	      set array(N_NONX_CHN_TOTAL,$i) [expr $array(N_NONX_CHN,$i) + 2]
	      # Actual number of spans is N_NONX_SPANS + 1
	      set array(N_NONX_SPANS_TOTAL,$i) [expr $array(N_NONX_SPANS,$i) + 1]
	  }
      }
      # Do we have the correct number of restraints?
      if { $array(N_NONX) != $n_ncs } {
	  WarningMessage "One or more NCS restraints is not properly
defined.

Check the NCS restraint definitions before
rerunning this job."
	  return 0
      }
  }

# Update the numbers of residue ranges ("spans") defined for each
# NCS restraint
#  for { set i 1 } { $i <= $array(N_NONX_NEW) } { incr i } {
#     # The number of ranges is one plus the number of additional
#     # ranges specified by the user
#     set array(N_NONX_SPANS_NEW,$i) [expr $array(N_NONX_SPANS_XTR,$i) + 1]
#  }

# Rigid domains
# Check each domain is properly defined
  if { [regexp RIGID $refine_type ] } {
      set ndomains 0
      for { set i 1 } { $i <= $array(NDOMAINS) } { incr i } {
	  # A rigid domain is considered to be "defined" if the
	  # parameters are set such that keywords will be generated
	  # in the keyworded script for this domain
	  if { $array(NGROUPS,$i) > 0 } {
	      set ngroups 0
	      for { set j 1 } { $j <= $array(NGROUPS,$i) } { incr j } {
		  if { $array(RES1,[subst $i]_[subst $j]) != "" && \
			   $array(RES2,[subst $i]_[subst $j]) != "" && \
			   $array(CHAIN1,[subst $i]_[subst $j]) != "" } {
		      # This group is defined
		      incr ngroups
		  }
	      }
	      # If all the groups in the domain are defined, then
	      # the domain is also defined
	      if { $array(NGROUPS,$i) == $ngroups } { incr ndomains }
	  }
      }
      # Check that all domains are defined
      if { $array(NDOMAINS) != $ndomains } {
	  WarningMessage "One or more rigid domains is not properly
defined.

Check the rigid domain definitions before
rerunning this job."
	  return 0
      }
  }

# File containing external restraints written by Prosmart
  if {$array(IFPROSMART)} {
    if { $array(RESTRAINTFILE) != "" } {
      set restraintfile [GetFullFileName $array(RESTRAINTFILE) \
			   $array(DIR_RESTRAINTFILE)]
      set array(RESTRAINTFILE_CMD) \
	      "@[GetFullFileName $array(RESTRAINTFILE) $array(DIR_RESTRAINTFILE)]"
      if { [regexp INPUT [GetValue $arrayname PROSMART_MODE] ] } {
        if { ![file exists $restraintfile] } {
	  WarningMessage "The specified input external restraint file
\"$restraintfile\"
does not exist"
	  return 0
        }
        append array(INPUT_FILES) " RESTRAINTFILE"
      } else {
        append array(OUTPUT_FILES) " RESTRAINTFILE"
      }
    } else {
      set array(RESTRAINTFILE_CMD) ""
    }
  }
  if { $array(PROSMART_KEYFILE) != "" } {
      set array(USE_PROSMART_KEYFILE) "1"
  } else {
      set array(USE_PROSMART_KEYFILE) "0"  
  }

# Request from Garib - allow the user to include an external keyword
# file
  if { $array(INCLUDEFILE) != "" } {
      set array(USE_INCLUDEFILE) "1"  
      set keywordfile [GetFullFileName $array(INCLUDEFILE) \
			   $array(DIR_INCLUDEFILE)]
      if { ![file exists $keywordfile] } {
	  WarningMessage "The specified external keyword file
\"$keywordfile\"
does not exist"
	  return 0
      } else {
	  set array(INCLUDEFILE_CMD) \
	      "@[GetFullFileName $array(INCLUDEFILE) $array(DIR_INCLUDEFILE)]"
	  append array(INPUT_FILES) " INCLUDEFILE"
      }
  } else {
      set array(INCLUDEFILE_CMD) ""
  }

# Set default title if not already set
  set title ""
  switch [GetValue $arrayname REFINE_TYPE] {
      REST {
	  set title "Restrained refinement"
      }
      UNRE {
	  set title "Unrestrained refinement"
      }
      RIGID {
	  set title "Rigid body refinement"
      }
      TLS {
	  set title "TLS and restrained refinement"
      }
      REVIEW {
	  set title "Review restraints"
      }
      IDEA {
	  set title "Structure idealisation"
      }
  }
  if { [StringSame [GetValue $arrayname REFINE_TYPE] REST UNRE RIGID TLS] } {
      if { $array(RUN_COOT_FW) } { append title " with Coot:findwaters " }
      if { $array(B_REFINEMENT) } {
	  append title " using $array(B_REFINEMENT_MODE) B factors"
      }
  }
  SetDefaultTitle $arrayname $title

  return 1
}

#---------------------------------------------------------------------
proc refmac5_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
upvar #0  $typedefVar typedef

set typedef(_refmac_input_phase) { menu {	"no prior phase information" 
						"phase and FOM"
					"Hendrickson-Lattman coefficients" 
					"SAD data directly" }
					{	NO
						PHASE
						HL 
                                                SAD } }

set typedef(_refmac_autoncs) {  menu { "local NCS restraints"
                                        "global NCS restraints" }
                                      { "LOCAL"
                                        "GLOBAL" } }

set typedef(_refmac_residual) {  menu { "maximum likelihood"
                                        "least squares residual" }
                                      { "MLKF"
                                        "LSQF" } }

set typedef(_refmac_refine_type) { menu {       "review restraints"
						"restrained refinement"
                                                "unrestrained refinement"
                                                "rigid body refinement"
                                                "structure idealisation" 
						"TLS & restrained refinement"}
                                        {       REVIEW REST UNRE RIGID IDEA TLS } }


set typedef(_refmac_b_refinement)  { menu { "isotropic"
                                            "anisotropic"
                                            "overall"
                                            "mixed (isotropic/anisotropic)" }
                                          {     ISOT ANIS OVER MIXED } }
set typedef(_refmac_split_mode)  {menu  { "into bins"
					  "by ranges" }
					{  BINS
                                           RANGES } }

set typedef(_refmac_weighting)   { menu { matrix
					  gradient }
                                        { MATRIX
					  GRADIENT } }

set typedef(_refmac_monitor_level) { menu { none few medium  many }
                                          { NONE FEW MEDIUM MANY } }

set typedef(_twinref_type) { menu { "no" "intensity based"  "amplitude based" }
                                          { NO INTENSITIES AMPLITUDES } }
   
set typedef(_refmac_scaling_appl) { menu {      "no" \
                                                "observed" \
                                                "calculated" }
                                        {       "NO" \
                                                "OBSE" \
                                                "CALC" } }

set typedef(_refmac_scaling) { menu {  "Babinet"
					"simple" }
				{	BULK 
                                        SIMPLE } }

set typedef(_refmac_ref_set) { menu     {       "working" \
                                                "free" }
                                        {       "WORK"
                                                "FREE" } }

set typedef(_refmac_rigid_exclude) { menu {     "no"
                                                "side chain" }
                                         {      "NO"
                                                "SCHA" } }

set typedef(_refmac_nonx_code)  { menu { "tight" \
                                        "tight main chain & medium side chain" \
					"tight main chain & loose side chain" \
                                        "medium" \
                                        "medium main chain & loose side chain" \
                                        "loose" }
                                        { 1 2 3 4 5 6 } }

set typedef(_prosmart_mode) { menu {  "no"
                        "to generate external restraints to reference structure"
                        "to generate h-bond restraints (e.g. secondary structure restraints)" 
                        "to generate fragment restraints (e.g. secondary structure element conformations)" 
                        "input existing restraints file" }
				{	NO
                    EXTERNAL 
                    HBOND 
                    SECSTR 
                    INPUT } }

set typedef(_chain_id_menu)     { varmenu CHAIN_ID_MENU {} 4 }

set typedef(_residue_id)        { text 4 NOTOBLIG }

set typedef(_refmac_make_link)  { menu { "defined in file or residues are close" \
					"defined in file only" \
					"residues are close only" }
					{ YES NO D } }

set typedef(_refmac_make_hydrogen)  { menu  { "use if present in file" \
					"ignore even if present in file" \
					"generate all hydrogens" } \
					{ YES NO ALL } }

set typedef(_refmac_make_check) { menu { \
	"Check all monomers against Refmac's dictionary description" \
	"Only check ligands against Refmac's dictionary description" \
	"Rely on user's naming convention" } \
				{ ALL LIGAND NONE } }

return 1
}

#---------------------------------------------------------------------
proc RefmacCheckHLCoeffs { arrayname labellist } {
#---------------------------------------------------------------------
# Procedure to check that the names supplied for input
# Hendrickson-Lattman coefficients have been uniquely assigned. If not
# then a warning dialogue is issued allowing the user to either proceed
# with the non-unique assignments (in which case 1 is returned) \
# or abort the run (0 is returned).
# A copy of this procedure also appears in the dm interface.

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
	set action [ChooseOptionDialog "Hendrickson-Lattman Coefficients" "Refmac5" \
"Labels for the Hendrickson-Lattman coefficients taken from\nthe input file have not been set uniquely\n\nYou can proceed with the current assignments, or abort the run\nand reassign the labels" \
        { Abort OK } -default 1 ]
    if [regexp Abort $action] { return 0 }
    }
    return 1
}

					
#-----------------------------------------------------------------------
proc RefmacProtocolParams { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { ![StringSame [GetValue $arrayname REFINE_TYPE] REST UNRE] } {
    set array(RUN_COOT_FW) 0
  }

  if [regexp RIGID [GetValue $arrayname REFINE_TYPE] ] {
    set array(SCALING_FIXB_BBULK) ""
  }

  if [regexp REVIEW|IDEA|TLS [GetValue $arrayname REFINE_TYPE] ] {
    set array(IFFIXTLS) 0
  }

  # If we're now in "Review" mode then relaunch the interface
  # in this mode
  if { $array(PREVIOUS_REFINE_TYPE) == "REVIEW" } {
      if { ![regexp REVIEW [GetValue $arrayname REFINE_TYPE]] } {
	  # We were in review mode, and now we're not
	  # Redraw as the standard refmac5 interface
	  set w $array(WINDOW)
	  RerenderTask $w $arrayname refmac5
      }
  } else {
      if { [regexp REVIEW [GetValue $arrayname REFINE_TYPE]] } {
	  # We weren't in review mode, and now we are
	  # Redraw as the refmac5 review mode interface
	  set w $array(WINDOW)
	  RerenderTask $w $arrayname refmac5_review
      }
  }
}

#--------------------------------------------------------------------
proc RefmacDomains { arrayname counter } { 
#--------------------------------------------------------------------

  CreateLine line \
	widget INITIALISE_RIGID \
	label "Initialise rotation and translation parameters for this domain"

  OpenSubFrame frame -toggle_display  INITIALISE_RIGID,$counter  hide 0

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

#------------------------------------------------------------------------
proc refmac_update_chain_menu { arrayname } {
#------------------------------------------------------------------------
# Update the chain variable menu (CHAIN_ID_MENU) which is used in 
# defining non-xtal symmetry restraints
  if { [llength [info procs PdbGetChains]] <= 0 } {
	source [SearchPath TOP utils pdb_utils.tcl] }
  if { ![file exists [GetFullFileName0 $arrayname XYZIN]]  ||
   ![PdbGetChains [GetFullFileName0 $arrayname XYZIN] chains chainranges] } {
	return 0 }

  UpdateVariableMenu $arrayname initialise 0 CHAIN_ID_MENU  $chains

}

#------------------------------------------------------------------------
proc atom_proc { arrayname c1 } {
#------------------------------------------------------------------------

  CreateLine line  \
      message "Input f' and f'' for anomalous atom in pdb file" \
        label "Anomalous atom" \
        widget ATOM \
        label " f' " \
        widget ATOM_FP \
        label " f'' " \
        widget ATOM_FPP
}

#------------------------------------------------------------------------
proc RefmacNonX { arrayname c1 } {
#------------------------------------------------------------------------

  CreateLine line \
      label "NCS restrain chain" \
      widget NONX_CHN_SRC \
      label ", residues" \
      widget NONX_INIT_SPANS_RES1 \
      label "to" \
      widget NONX_INIT_SPANS_RES2 \
      label "with" \
      widget NONX_INIT_SPANS_CODE \
      label "restraints"

  CreateExtendingFrame N_NONX_SPANS RefmacNonXSpans \
        "Specify range of residues restrained by non-crystallographic symmetry" \
        "Add residue range" \
        [list NONX_SPANS_RES1 \
              NONX_SPANS_RES2 \
              NONX_SPANS_CODE ] -counter $c1

  CreateLine line \
      label "                to chain" \
      widget NONX_CHN_TARG \
      label "(same residue ranges as defined above)"

  CreateExtendingFrame N_NONX_CHN RefmacNonXChain \
         "Specify chains restrained by non-crystallographic symmetry" \
         "Add chain" \
       [list  NONX_CHN ] \
         -counter $c1
}
 
#------------------------------------------------------------------------
proc RefmacNonXSpans { arrayname c1 c2 } {
#------------------------------------------------------------------------

  CreateLine line \
    help ncsr \
    message "Enter range of residues with equal weight of NCS restraints applied" \
    label "                                                  residues" \
    widget NONX_SPANS_RES1 \
    label "to" \
    widget NONX_SPANS_RES2 \
    label "with" \
    widget NONX_SPANS_CODE \
    label "restraints"
}

#------------------------------------------------------------------------
proc RefmacNonXChain { arrayname c1 c2 } {
#------------------------------------------------------------------------

  CreateLine line \
    message "Enter names of non-crystallographic symmetry related chains" \
    label "                to chain" \
    widget NONX_CHN
}

#------------------------------------------------------------------------
proc set_prosmart_mode { arrayname } {
#------------------------------------------------------------------------

    upvar #0 $arrayname array
    if { [regexp NO [GetValue $arrayname PROSMART_MODE] ] } {
        set array(IFPROSMART) 0
    } else {
        set array(IFPROSMART) 1
    }
    set array(PROSMART_HBOND) 1
    return 1
}

#------------------------------------------------------------------------
proc set_prosmart_hbond { arrayname } {
#------------------------------------------------------------------------

    upvar #0 $arrayname array
    if { !$array(PROSMART_HBONDHELIX3) && !$array(PROSMART_HBONDHELIX4) && !$array(PROSMART_HBONDHELIX5) && !$array(PROSMART_HBONDSHEET) } {
        set array(PROSMART_HBOND) 1
        set array(PROSMART_HBONDHELIX3) 1
        set array(PROSMART_HBONDHELIX4) 1
        set array(PROSMART_HBONDHELIX5) 1
        set array(PROSMART_HBONDSHEET) 1
    }
    return 1
}

#-------------------------------------------------------------------
proc refmac5_task_window { arrayname } {
#-------------------------------------------------------------------
  upvar #0 $arrayname array
  global preferences
  global configure

  if { [CreateTaskWindow $arrayname  \
    	"Run Refmac5" "Refmac5" \
        [ list "Data Harvesting" \
	"TLS Parameters" \
	"Refinement Parameters"  \
        "Idealisation Parameters" \
	"Setup Geometric Restraints" \
	"Setup Non-Crystallographic Symmetry (NCS) Restraints" \
	"External Restraints" \
	"Coot Parameters" \
        "Rigid Domains Definition" \
	"Monitoring and Output Options" \
	"Scaling" \
	"Geometric parameters" ] \
	-file_cleanup 0 ] == 0 } return

  SetDefaultMapFormat $arrayname MAPOUT_FORMAT
  SetHarvestParams $arrayname HKLIN -init
# Look for the user defined library in expected place
  if { $array(MAKE_LIBRARY) == "" } {
    if { [file exists [FileJoin [GetSystemVar DOT] ener_lib.cif]] } {
      set array(MAKE_LIBRARY) [FileJoin [GetSystemVar DOT] ener_lib.cif]
      set array(DIR_MAKE_LIBRARY) [GetSystemVar PATHNAME_LABEL]
    }
  }
# If XYZIN set e.g. re-running then initialise chain list
  refmac_update_chain_menu $arrayname

# catch for ATOM compatibility between 6.1.0 and 6.1.1
  catch {
  if { $array(ATOM) != "" } {
    set array(NATOMS) 1
    set array(ATOM,1) $array(ATOM)
    set array(ATOM_FP,1) $array(ATOM_FP)
    set array(ATOM_FPP,1) $array(ATOM_FPP)
#   set array(ATOM,0) $array(ATOM)
#   set array(ATOM_FP,0) $array(ATOM_FP)
#   set array(ATOM_FPP,0) $array(ATOM_FPP)
    }
    unset array(ATOM)
    unset array(ATOM_FP)
    unset array(ATOM_FPP)
# have to update PARAM_LIST element too, this may need watching
    regsub -all -- {ATOM ATOM_FP ATOM_FPP} $array(PARAM_LIST) { } array(PARAM_LIST)
  }

  set array(IFMAPNAME) $preferences(IFMAPNAME)

  # See if Prosmart package installed and available
  if { [file exists [FindExecutable prosmart]] &&
       [file exists [FindExecutable prosmart_align]] &&
       [file exists [FindExecutable prosmart_restrain]] } {
    set array(PROSMART_AVAIL) 1
  } else {
    set array(PROSMART_AVAIL) 0
  }

  set help_source [file join [GetEnvPath CHTML] refmac5 ]

  SetProgramHelpFile [file join $help_source keywords xray-principal.html]

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
        message "Refinement method (REFI TYPE)" \
	help refi_type \
        label "Do" \
        widget REFINE_TYPE \
	  -command "RefmacProtocolParams $arrayname" \
	message "Choose type of phase input" \
        help labin \
        label "using" \
        widget INPUT_PHASE \
	label "input" \
	toggle_display REFINE_TYPE hide [ list REVIEW IDEA]

  CreateLine line \
        message "Refinement method (REFI TYPE)" \
        help refi_type \
        label "Do" \
        widget REFINE_TYPE \
          -command "RefmacProtocolParams $arrayname" \
	toggle_display REFINE_TYPE open [list REVIEW IDEA]

  SetProgramHelpFile [file join $help_source usage tls_usage.html]

  CreateLine line \
	message "Input previously determined TLS values but do not refine them." \
        help tls_meaning \
	widget IFFIXTLS \
	label "Input fixed TLS parameters" \
	toggle_display REFINE_TYPE hide [list REVIEW IDEA TLS ]

  OpenSubFrame frame -toggle_display INPUT_PHASE open NO

  CreateLine line \
      message "Perform no, intensity or amplitude based twin refinement" \
      widget TWINREF_TYPE \
      label "twin refinement"

  CloseSubFrame
 
  OpenSubFrame frame  -toggle_display PROSMART_AVAIL open 1

  CreateLine line \
        message "Generate external or secondary structure restraints (only recommended for low resolution or poor density)" \
        label "Use Prosmart: " \
        widget PROSMART_MODE -command "set_prosmart_mode $arrayname" \
        label "(low resolution refinement)" \
        toggle_display REFINE_TYPE open [list REST TLS ]

  CloseSubFrame
 
  CreateLine line \
        message "You have Coot installed, so use it to add/remove waters to PDB file" \
        widget RUN_COOT_FW \
        label "Run Coot:findwaters to automatically add/remove waters to refined structure" \
        toggle_display REFINE_TYPE open [list REST UNRE ]

  SetProgramHelpFile [file join $help_source keywords xray-principal.html]


#=FILES================================================================

  SetProgramHelpFile [file join $help_source files input-script.html]

  OpenFolder file 

  OpenSubFrame frame  -toggle_display  REFINE_TYPE hide [list REVIEW IDEA]

  CreateInputFileLine line \
	"Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
       HKLIN DIR_HKLIN \
       -fileout HKLOUT DIR_HKLOUT "_refmac" \
       -setlabin FREE [list FREE FreeR FreeR_flag] \
	-setfileparam resolution_min EXCLUDE_RESOLUTION_MIN \
	-setfileparam resolution_max EXCLUDE_RESOLUTION_MAX \
	-command "UpdateHarvestMTZ $arrayname HKLIN"

  SetProgramHelpFile [file join $help_source keywords xray-principal.html]

  OpenSubFrame frame -toggle_display INPUT_PHASE open SAD

    CreateLabinLine4 line \
      "F" \
      HKLIN "F+" F+ [list F+ F_(+)] \
      -sigma "SIGF+" SIGF+ [list SIGF+ SIGF_(+)] \
      -dependent "F-" F-  [list F- F_(-)] \
      -sigma "SIGF-" SIGF- [list SIGF- SIGF_(-)] 

  CreateLine line  \
        message "Input X-ray wavelength data to calculate anomalous scattering factors" \
        label "Wavelength " \
        widget WAVELENGTH \
        message "Refine substructure occupancy" \
        label "Refine substructure occupancy " \
        widget REF_SUBOCC

  CreateToggleFrame NATOMS atom_proc \
      "Add another atomic form factor" \
      "Atomic form factors" \
      "Add Atom" \
      [list  ATOM \
         ATOM_FP \
         ATOM_FPP ]  

  CloseSubFrame

  OpenSubFrame frame -toggle_display INPUT_PHASE hide SAD

  OpenSubFrame frame -toggle_display INPUT_PHASE open NO

  CreateLabinLine line \
      "Observed intensity (IP) and obligatory sigma (SIGIP)" \
      HKLIN "IP    " IP  [list IP I_P] \
        -sigma "Sigma  " SIGIP  [list SIGIP SIGI_P SIGI ] \
        -toggle_display TWINREF_TYPE open INTENSITIES
      
  CreateLabinLine line \
      "Observed amplitude (FP) and obligatory sigma (SIGFP)" \
      HKLIN "FP    " FP  [list FP F_P] \
        -sigma "Sigma  " SIGFP  [list SIGFP SIGF_P SIGP ] \
        -toggle_display TWINREF_TYPE open AMPLITUDES 
      
  CreateLabinLine line \
      "Observed amplitude (FP) and obligatory sigma (SIGFP)" \
      HKLIN "FP    " FP  [list FP F_P] \
        -sigma "Sigma  " SIGFP  [list SIGFP SIGF_P SIGP ]  \
        -toggle_display TWINREF_TYPE open NO
    
  CloseSubFrame 
     
  OpenSubFrame frame -toggle_display INPUT_PHASE hide NO
    
  CreateLabinLine line \
	"Observed amplitude (FP) and obligatory sigma (SIGFP)" \
	HKLIN "FP    " FP  [list FP F_P] \
        -sigma "Sigma  " SIGFP  [list SIGFP SIGF_P SIGP ]

  CloseSubFrame

  CreateLabinLine line \
	"Input phase (PHIB) and figure of merit (FOM)" \
	HKLIN "PHIB  " PHIB  PHIB \
        -sigma "FOM  " FOMB  FOM \
        -toggle_display INPUT_PHASE open PHASE

  OpenSubFrame frame -toggle_display INPUT_PHASE open HL  

  CreateLabinLine4 line \
    "Hendrickson-Lattman coefficients" \
    HKLIN "HLA" HLA  [list HLA] \
     -dependent "HLB" HLB [list HLB] \
     -dependent "HLC" HLC [list HLC] \
     -dependent "HLD" HLD [list HLD] \
     -toggle_display INPUT_PHASE open HL

  CloseSubFrame

  CloseSubFrame

  SetProgramHelpFile [file join $help_source files input-script.html]

  CreateOutputFileLine line \
	"Output MTZ File" \
	"MTZ out" \
	HKLOUT DIR_HKLOUT

  CloseSubFrame

  CreateInputFileLine line \
        "Enter input coordinate file name (XYZIN)" \
      "PDB in" \
       XYZIN DIR_XYZIN \
       -fileout XYZOUT DIR_XYZOUT "_refmac" \
       -fileout TLSOUT DIR_TLSOUT "_refmac" \
       -fileout LIBOUT DIR_LIBOUT -- \
       -fileout RESTRAINTFILE DIR_RESTRAINTFILE "_res" \
	-command "refmac_update_chain_menu $arrayname"

  CreateOutputFileLine line \
        "Output coordinate file (XYZOUT)" \
        "PDB out" \
        XYZOUT DIR_XYZOUT

  CreateInputFileLine line \
    "Enter additional user-defined geometry library (LIBIN)" \
    "LIB in" MAKE_LIBRARY DIR_MAKE_LIBRARY \
	-notoblig \
	-toggle_display REFINE_TYPE hide { RIGID UNRE }

  # add extra button to launch merge_monomers task
  button $line.extra -text "Merge LIBINs" \
	          -background $configure(COLOUR_PALE) \
	          -font $configure(FONT_REGULAR)
  SetMessage [ GetSystemVar frame_array ] $line.extra \
          "Launch Merge monomer libraries task to prepare a single LIBIN file"
  add_command $line.extra "RunTask merge_monomers"
  pack $line.extra -side right

  CreateOutputFileLine line \
	"Enter a name for any extra geometry library created by Refmac5 (LIBOUT)" \
        "Output lib" LIBOUT DIR_LIBOUT \
      -toggle_display REFINE_TYPE hide { RIGID UNRE }

  OpenSubFrame frame -toggle_display  REFINE_TYPE open { TLS } 

  CreateInputFileLine line \
        "Specify file with TLS groups (TLSIN), or leave blank for Refmac5 to generate them automatically" \
      "TLS in (optional) " \
       TLSIN DIR_TLSIN \
       -fileout TLSOUT DIR_TLSOUT "_refmac" \
       -notoblig

  # add extra button to launch merge_monomers task
  button $line.extra -text "Create TLSIN" \
	          -background $configure(COLOUR_PALE) \
	          -font $configure(FONT_REGULAR)
  SetMessage [ GetSystemVar frame_array ] $line.extra \
          "Launch Create/Edit TLS file task to prepare the TLSIN file"
  add_command $line.extra "RunTask edit_tls"
  pack $line.extra -side right

  CreateOutputFileLine line \
        "Output coordinate file (TLSOUT)" \
        "TLS out" \
        TLSOUT DIR_TLSOUT

  CloseSubFrame

  OpenSubFrame frame -toggle_display IFFIXTLS open 1

  CreateInputFileLine line \
        "Enter input TLS file name (TLSIN)" \
      "TLS in" \
       TLSIN DIR_TLSIN 

  CloseSubFrame
 
  OpenSubFrame frame -toggle_display IFPROSMART open 1

  CreateInputFileLine line \
      "Enter PDB file name for reference/external structure" \
      "Reference PDB in" \
       EXT_XYZIN DIR_EXT_XYZIN \
       -toggle_display PROSMART_MODE open { EXTERNAL }

  CreateInputFileLine line \
      "Enter name of file (.txt) where external restraints will be written" \
      "Prosmart restraints out" \
       RESTRAINTFILE DIR_RESTRAINTFILE \
       -toggle_display PROSMART_MODE hide { INPUT }

  CreateInputFileLine line \
      "Enter name of file (.txt) containing external" \
      "Prosmart restraints in" \
       RESTRAINTFILE DIR_RESTRAINTFILE \
       -toggle_display PROSMART_MODE open { INPUT }

  CreateInputFileLine line \
      "Specify a keyword file (.txt) to be used by Prosmart at runtime" \
      "Prosmart keyword file" \
      PROSMART_KEYFILE DIR_PROSMART_KEYFILE \
       -toggle_display PROSMART_MODE hide { INPUT } \
       -notoblig

  CloseSubFrame

#----------------------------------------------------------Developers options

  CreateInputFileLine line \
      "Specify a keyword file to be included in the Refmac command script at runtime" \
      "Refmac keyword file" \
      INCLUDEFILE DIR_INCLUDEFILE \
      -notoblig

#----------------------------------------------------------

#=PARAMETERS==========================================================

  SetProgramHelpFile [file join $help_source keywords harvesting.html]

  OpenFolder 1 REFINE_TYPE hide { REVIEW RIGID IDEA } closed

  CreateHarvestLine line 

#-----------------------------------------------------------------------Geometric Restraints

  OpenFolder 5 REFINE_TYPE hide { RIGID UNRE } open REVIEW closed

  SetProgramHelpFile [file join $help_source keywords restraints.html]

  OpenSubFrame frame -toggle_display  REFINE_TYPE hide REVIEW 

  CreateLine line \
    message "Report if amino acids do not match dictionary descriptions" \
    help  makecif \
    label "Checking against dictionary:" \
    widget MAKE_CHECK

  CreateLine line \
    label "If the following features are found in coordinate file then make restraints to maintain them:"  \
	-italic

  CreateLine line \
    help  makecif \
    message "If D-peptides found in structure use D-peptide description(MAKE PEPTIDE)" \
    widget MAKE_PEPTIDE \
    label "D-peptide " \
    message "If cis-peptides found in structure use cis-peptide description(MAKE CISP)" \
    widget MAKE_CISPEPTIDE \
    label "cis-peptide" \
    message "If links between symmetry related atoms found in structure(MAKE SYMM)" \
    widget MAKE_SYMMETRY \
    message "(MAKE CHAIN)" \
    label "Links between symmetry related atoms"

  CreateLine line \
    label "Make links between:" -italics

  CreateLine line \
    help  makecif \
    message "Use restraints between neighbouring amino acid/DNA/RNA residues (MAKE CONN)" \
    label "Amino acids and DNA/RNA if" \
    widget MAKE_CONNECTIVITY

  CreateLine line \
    help makecif \
    message "Use restraints between neighbouring sugars or sugar/peptide residues (MAKE SUGAR)" \
    label "Sugar-sugar and sugar-peptide if" \
    widget MAKE_SUGAR

  CreateLine line \
    help makecif \
    message "Use restraints between neighbouring non sugar/peptide/DNA/RNA residues (MAKE LINK)" \
    label "All others if" \
    widget MAKE_LINK

  CloseSubFrame

  OpenSubFrame frame -toggle_display  REFINE_TYPE open REVIEW 

  CreateLine line \
    message "Report if amino acids do not match dictionary descriptions" \
    help  makecif \
    label "Checking against dictionary:" \
    widget REVIEW_MAKE_CHECK

  CreateLine line \
    label "If the following features are found in coordinate file then make restraints to maintain them:"  \
	-italic

  CreateLine line \
    help  makecif \
    message "If D-peptides found in structure use D-peptide description(MAKE PEPTIDE)" \
    widget REVIEW_MAKE_PEPTIDE \
    label "D-peptide " \
    message "If cis-peptides found in structure use cis-peptide description(MAKE CISP)" \
    widget REVIEW_MAKE_CISPEPTIDE \
    label "cis-peptide" \
    message "If links between symmetry related atoms found in structure(MAKE SYMM)" \
    widget REVIEW_MAKE_SYMMETRY \
    message "(MAKE CHAIN)" \
    label "Links between symmetry related atoms"

  CreateLine line \
    label "Make links between:" -italics

  CreateLine line \
    help  makecif \
    message "Use restraints between neighbouring amino acid/DNA/RNA residues (MAKE CONN)" \
    label "Amino acids and DNA/RNA if" \
    widget REVIEW_MAKE_CONNECTIVITY

  CreateLine line \
    help makecif \
    message "Use restraints between neighbouring sugar or sugar/peptide residues (MAKE SUGAR)" \
    label "Sugar-sugar and sugar-peptide if" \
    widget REVIEW_MAKE_SUGAR

  CreateLine line \
    help makecif \
    message "Use restraints between neighbouring non sugar/peptide/DNA/RNA residues (MAKE LINK)" \
    label "All others if" \
    widget REVIEW_MAKE_LINK

  CloseSubFrame
#---------------------------------------------------------------NCS restraints
  OpenFolder 6 REFINE_TYPE hide { RIGID UNRE } open

  CreateLine line \
      message "Use automatically generated NCS restraints (NCSR)" \
      widget IFAUTONCS \
      label "use automatically generated" \
      widget AUTONCS_MODE \
      label "NCS restraints"

  OpenSubFrame frame -toggle_display IFAUTONCS hide 1

  # Message to display when no restraints have been added so far
  CreateLine line \
      label "No NCS restraints are currently defined" -italic \
      toggle_display N_NONX open { 0 }

  CreateToggleFrame N_NONX RefmacNonX \
                "Open another NCS restraint" \
                "Non-Crystallographic Symmetry restraint" \
                "Add NCS restraint" \
             [list N_NONX_CHN \
                   N_NONX_SPANS \
                   NONX_CHN_SRC \
		   NONX_CHN_TARG \
                   NONX_INIT_SPANS_RES1 \
                   NONX_INIT_SPANS_RES2 \
                   NONX_INIT_SPANS_CODE] \
      -child RefmacNonXChain \
      -child RefmacNonXSpans

  CloseSubFrame

#------------------------------------------------------------------------Refinement parameters
  OpenFolder 3 REFINE_TYPE hide { REVIEW IDEA } closed

  SetProgramHelpFile [file join $help_source keywords xray-principal.html]

  # For RESTRAINED and UNRESTRAINED refinement we are allowed to cycle with coot
  OpenSubFrame frame -toggle_display REFINE_TYPE open { REST }

  CreateLine line \
	message "Number of cycles of refinement (NCYC) for each Refmac run" \
	help ncyc \
        label "Do" \
	widget NCYCLES \
	  -width 3 \
	label "cycles of maximum likelihood restrained refinement in each Refmac run and" \
	message "Number of cycles of running Refmac (Coot etc)" \
	widget EXTERNAL_NCYCLES \
	   -width 3 \
	label "cycle(s) of Coot:findwaters"  \
      toggle_display RUN_COOT_FW open { 1 }

  CreateLine line \
        message "Number of cycles of refinement (NCYC) for each Refmac run" \
        help ncyc \
        label "Do" \
        widget NCYCLES \
          -width 3 \
        label "cycles of maximum likelihood restrained refinement" \
      toggle_display RUN_COOT_FW open { 0 }

  CloseSubFrame

  OpenSubFrame frame -toggle_display REFINE_TYPE open { UNRE }

  CreateLine line \
	message "Number of cycles of refinement (NCYC) for each Refmac run" \
	help ncyc \
        label "Do" \
	widget NCYCLES \
	  -width 3 \
	label "cycles of maximum likelihood unrestrained refinement in each Refmac run and" \
	message "Number of cycles of running Refmac (Coot etc)" \
	widget EXTERNAL_NCYCLES \
	   -width 3 \
	label "cycle(s) of Coot:findwaters"  \
      toggle_display RUN_COOT_FW open { 1 }

  CreateLine line \
        message "Number of cycles of refinement (NCYC) for each Refmac run" \
        help ncyc \
        label "Do" \
        widget NCYCLES \
          -width 3 \
        label "cycles of maximum likelihood unrestrained refinement" \
      toggle_display RUN_COOT_FW open { 0 }

  CloseSubFrame

  # For RIGID BODY refinement
  CreateLine line \
        message "Number of cycles of refinement (NCYC) for each Refmac run" \
        help ncyc \
        label "Do" \
        widget RIGID_NCYCLES \
          -width 3 \
        label "cycles of maximum likelihood rigid body refinement" \
        toggle_display REFINE_TYPE open RIGID

  # For TLS
  CreateLine line \
        message "Number of cycles of refinement (NCYC) for each Refmac run" \
        help ncyc \
        label "Do" \
        widget NCYCLES \
          -width 3 \
        label "cycles of maximum likelihood restrained refinement after TLS refinement" \
        toggle_display REFINE_TYPE open TLS

  SetProgramHelpFile [file join $help_source keywords restraints.html]

  CreateLine line \
    help  makecif \
    message "Select how to represent hydrogen atoms(MAKE HYDR)" \
    label "Use hydrogen atoms:" \
    widget MAKE_HYDROGEN \
    message "Output hydrogen atoms to coordinate  file?(MAKE HOUT)" \
    label "and" \
    widget MAKE_HOUT \
    label "output to coordinate file"

  SetProgramHelpFile [file join $help_source keywords xray-principal.html]

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

  SetProgramHelpFile [file join $help_source keywords xray-principal.html]

  # Only use MATRIX weighting ie. no GRADIENT
  CreateLine line \
        message "WEIGHT AUTO will attempt to set the geometric/X-ray weighting automatically" \
        help weig \
        widget AUTO_WEIGHTING \
        label "Use automatic weighting" \
        message "Use experimental sigmas to weight geometric/X-ray" \
        help weig \
        widget EXPERIMENTAL_WEIGHTING \
        label "Use experimental sigmas to weight Xray terms"

  # Only use MATRIX weighting ie. no GRADIENT
  CreateLine line \
        label "Use weighting term" \
        message "Matrix weighting term: decrease to increase geometric restraints and tighten geometry" \
        help weig \
        widget MATRIX_WEIGHT -oblig \
	toggle_display AUTO_WEIGHTING open { 0 }

  CreateLine line \
	message "May be useful at early stages or at low resolution (RIDG DIST)" \
	widget IFJELLY \
	label "use jelly-body refinement with sigma" \
	widget JELLY_SIGMA \
	toggle_display REFINE_TYPE open { REST TLS }  hide

  CreateLine line \
	message "Refine temperature factors (REFI BREF)" \
	help refi_bref \
	label "Refine" \
	widget B_REFINEMENT_MODE \
	label "temperature factors" \
	toggle_display REFINE_TYPE open { REST UNRE TLS }  hide

  CreateLine line \
        message "Refine temperature factors (REFI BREF OVER )" \
        help refi_bref \
        label "Refine overall B-factor" \
        toggle_display REFINE_TYPE open { RIGID IDEA }  hide

  SetProgramHelpFile [file join $help_source keywords xray-general.html]

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

  # Need this for rerunning REFMAC5 task, to make sure that the
  # FreeR menu is updated automatically
  if { $array(FREE) != "Unassigned" && $array(FREE) != "" } {
    SetLabin $arrayname HKLIN FREE $array(FREE)
  } else {
    SetLabin $arrayname HKLIN FREE [list FREE FreeR FreeR_flag]
  }

  CreateLine line \
    message "Blurring factors for input phases (REFI PHASE SCBLUR BBLUR)" \
    help phas \
    label "Blurring factors for input phase FOM SC" \
    widget PHASE_SCBLUR \
    label "B" \
    widget PHASE_BBLUR \
      toggle_display INPUT_PHASE open [list PHASE HL]


#-------------------------------------------------------External Restraints
  OpenFolder 7 REFINE_TYPE hide { RIGID UNRE } closed

  CreateLine line \
        message "Use Prosmart to generate helix restraints (-helix)" \
        widget PROSMART_HELIX \
        label "Apply Prosmart helix restraints, and" \
        message "Use Prosmart to generate strand restraints (-strand)" \
        widget PROSMART_STRAND \
        label "Apply Prosmart strand restraints" \
        toggle_display PROSMART_MODE open { SECSTR }
  
  CreateLine line \
        message "Use Prosmart to generate all main chain h-bond restraints (-h)" \
        widget PROSMART_HBOND \
        label "Apply all Prosmart main chain h-bond restraints" \
        toggle_display PROSMART_MODE open { HBOND }
              
  CreateLine line \
        label "Apply Prosmart h-bond restraints only for" \
        message "Use Prosmart to generate h-bond 3_10 helix restraints (-3_10)" \
        widget PROSMART_HBONDHELIX3 -command "set_prosmart_hbond $arrayname" \
        label "3_10 helices," \
        message "Use Prosmart to generate h-bond alpha helix restraints (-alpha)" \
        widget PROSMART_HBONDHELIX4 -command "set_prosmart_hbond $arrayname" \
        label "alpha helices," \
        message "Use Prosmart to generate h-bond pi helix restraints (-pi)" \
        widget PROSMART_HBONDHELIX5 -command "set_prosmart_hbond $arrayname" \
        label "pi helices, and" \
        message "Use Prosmart to generate h-bond beta sheet restraints (-h_sheet)" \
        widget PROSMART_HBONDSHEET -command "set_prosmart_hbond $arrayname" \
        label "beta-sheets" \
        toggle_display PROSMART_HBOND open { 0 }

  CreateLine line \
	message "Apply any external restraints (e.g. generated by Prosmart) with weight (EXTERNAL WEIGHT SCALE)" \
	widget IFEXTREST_SCALE \
	label "Apply external restraints with weight" \
	widget EXTREST_SCALE \
        label "and" \
        message "parameter of Geman-McClure function - weights down outliers (EXTERNAL WEIGHT GMWT)" \
        widget IFEXTREST_GMWT \
        label "apply Geman-McClure weight" \
	widget EXTREST_GMWT

  CreateLine line \
        message "Ignore all distance restraints for which target value is larger than dmax (EXTERNAL DMAX)" \
        widget IFEXTREST_DMAX \
        label "Apply maximum external restraint distance" \
	widget EXTREST_DMAX \
        label "and" \
        message "main chain only (recommended, EXTERNAL USE MAIN)" \
        widget IFEXTREST_USEMAIN \
        label " apply to main chain only"

#------------------------------------------------------Idealisation  parameters

  OpenFolder 4 REFINE_TYPE open { IDEA } hide

  SetProgramHelpFile [file join $help_source keywords xray-principal.html]

  CreateLine line \
	message "Number of cycles of refinement (NCYC) for each Refmac run" \
	help ncyc \
        label "Do" \
	widget NCYCLES \
	  -width 3 \
	label "cycles of idealisation"

  SetProgramHelpFile [file join $help_source keywords restraints.html]

  CreateLine line \
    help  makecif \
    message "Select how to represent hydrogen atoms(MAKE HYDR)" \
    label "Use hydrogen atoms:" \
    widget MAKE_HYDROGEN \
    message "Output hydrogen atoms to coordinate  file?(MAKE HOUT)" \
    label "and" \
    widget MAKE_HOUT \
    label "output to coordinate file"

#--------------------------------------------------------------------COOT

  OpenFolder 8 RUN_COOT_FW hide 0 open

  CreateLine line \
    message  "Add waters with Coot:findwaters" \
    label "Add waters where DELFWT map greater than " \
    widget COOT_SIGMA_ADD  \
    label "sigma"

  CreateLine line \
    message  "Remove waters with Coot:findwaters" \
    label "Remove waters where FWT map less than " \
    widget COOT_SIGMA_REMOVE  \
    label "sigma"

# -----------------------------------------------------------------TLS parameters
  SetProgramHelpFile [file join $help_source keywords xray-general.html]

  OpenFolder 2 REFINE_TYPE open [list TLS] hide

  CreateLine line \
    help tlsc \
    message "Set number of cycles of TLS refinement (TLSC)" \
    label "Number of cycles of TLS refinement" \
    widget TLS_NCYCLES

  SetProgramHelpFile [file join $help_source keywords restraints.html]

  CreateLine line \
    message "Set starting value of Bfactors for subsequent refinement." \
    widget IFBFAC_SET \
    label "Set initial Bfactors to" \
    varlabel BFAC_SET \
    label "(numeric value unimportant)" 

  CreateLine line \
    message "Gives full B and U in XYZOUT, suitable for analysis/deposition but NOT for further refinement cycles" \
    widget IFADDU \
    label "Add TLS contribution to XYZOUT (B factors and ANISOU lines)"

#----------------------------------------------------------------Output MTZ data

  OpenFolder 10 REFINE_TYPE hide [list REVIEW IDEA] closed

  SetProgramHelpFile [file join $help_source files input-script.html]

  CreateLine line \
        message "Output map coefficients in HKLOUT are modified to give sharper map (MAPC SHAR)" \
        widget IFSHARP \
        label "Perform map sharpening. Manually set B value" \
        widget B_SHARP \
        label "and/or alpha value" \
        widget AL_SHARP \
        toggle_display REFINE_TYPE hide [list REVIEW IDEA] open

  CreateLine line \
	message "Level of output of monitoring statistics (MONI)" \
	label "Output" \
	help moni \
	widget MONI_LEVEL \
	label "monitoring statistics" \
	toggle_display REFINE_TYPE hide RIGID

  OpenSubFrame frame -toggle_display REFINE_TYPE hide [list UNRE]

  CreateLineTemplate MONITOR { 0.0 0.2 0.4 0.6 0.8 }

  CreateLine line \
    label "Sigma cutoffs for monitoring levels.." -itallic

  CreateLine line \
    label Torsion \
    label Distance \
    label Angle \
    label Planarity \
    label vanDerWaals \
    format  template MONITOR
    
  CreateLine line \
	message "List torsions greater than moni_torsion*torsig from ideal" \
	help moni \
	widget MONI_TORSION \
	message "List distances greater than moni_distance*dissig from ideal" \
	widget MONI_DISTANCE \
	message "List angles greater than moni_angle*angsig from ideal" \
	widget MONI_ANGLE \
	message "List deviations from plane greater than moni_plane*planesig from ideal" \
	widget MONI_PLANE \
	message "List VDW restraints greater than moni_vanderwaal*vdwsig from ideal" \
	widget MONI_VANDERWAAL \
	format template MONITOR

  CreateLine line \
    label Chiral \
    label Bfactor \
    label Bsphere \
    label Rbond \
    label NCSr \
    format template MONITOR


  CreateLine line \
	help moni \
        message "List chiral volumes greater than moni_chiral*chiralsig from ideal" \
	widget MONI_CHIRAL \
        message "List bonded atoms with differences in B > moni_bfactor*sig(bfactor)" \
        widget MONI_BFACTOR \
        message "List anisotropy deviating from sphere > moni_sphere*sigma(sphere)" \
        widget MONI_BSPHERE \
        message "List rigid body restraint deviating from ideal by moni_rbond*sigma(rbond)" \
	widget MONI_RBOND \
        message "List coords or Bs deviating from NCS equivalent by > moni_ncs*sigma(ncs)"  \
	widget MONI_NCSR \
	format template MONITOR

   CloseSubFrame

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

#  CreateLaboutLine line \
#    "Enter name for phases combined with experimental phase" \
#        HKLOUT "PhiComb"  PHCOMB \
#        -toggle_display INPUT_PHASE open PHASE

  CreateLine line \
        message "Generate weighted mFo-DFcalc and 2mFo-DFcalc maps" \
 	widget IF_MAPOUT \
	  -toggleon \
        label "Generate weighted difference maps files in" \
        widget MAPOUT_FORMAT \
        label "format" \
        toggle_display REFINE_TYPE hide [list REVIEW IDEA] open

  OpenSubFrame frame -toggle_display IF_MAPOUT open 1

  CreateLine line \
        widget EXTEND_MAP \
        label "Extend map to cover molecule with border" \
        widget MAP_BORDER 

      CreateOutputFileLine line \
        "Enter name for output Fwt maps" \
         "Fwt map" MAPOUT1 DIR_MAPOUT1

      CreateOutputFileLine line \
        "Enter name for output DelFwt maps" \
         "DelFwt map" MAPOUT2 DIR_MAPOUT2

    CloseSubFrame


#---------------------------------------------------------Scaling Fo and Fc

  OpenFolder 11 REFINE_TYPE hide [list REVIEW IDEA] closed
  SetProgramHelpFile [file join $help_source keywords xray-principal.html]

  CreateLine line \
        message "Bulk solvent scaling or simple Wilson scaling (SCALe TYPE BULK|SIMP)"  \
	help scal \
        label "Use" \
        widget BULK_SOLVENT_SCALING \
	label "scaling"

  CreateLine line  \
	message "Resolution limits for scaling (SCALE RESO)" \
        label "Bulk solvent scaling for resolution range" \
	help scal_lssc_reso \
	widget BULK_SCALING_RESOLUTION_MIN \
	label " to " \
	widget BULK_SCALING_RESOLUTION_MAX \
        toggle_display BULK_SOLVENT_SCALING open BULK

  CreateLine line \
        message "Resolution limits for scaling (SCALE RESO)" \
        label "Simple solvent scaling for resolution range" \
	help scal_lssc_reso \
        widget SIMPLE_SCALING_RESOLUTION_MIN \
        label " to " \
        widget SIMPLE_SCALING_RESOLUTION_MAX \
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
        message "Set the parameters for the solvent mask calculation" \
        help "solv" \
        widget IF_SOLVENT -toggleon \
        label "Calculate the contribution from the solvent region"

  OpenSubFrame frame -toggle_display IF_SOLVENT open 1

  CreateLine line \
        label "For the solvent mask calculation:" -italic

  CreateLine line \
        message "Non-ion atoms include carbons (default 1.2)" \
        help "solv" \
        label "     Increase VDW radius of non-ion atoms by" \
        widget SOLVENT_VDWPROB

  CreateLine line \
        message "Atoms which can be ions, or which can participate in Coulombic interactions (default 0.8)" \
        help "solv" \
        label "     Increase ionic radius of potential ion atoms by" \
        widget SOLVENT_IONPROB

  CreateLine line \
        message "Shrink the mask by this value and set mask region to a constant value (default 0.8)" \
        help "solv" \
        label "     Shrink the area of the mask by" \
        widget SOLVENT_RSHRINK \
        label "after calculation"

  CloseSubFrame

  CreateLine line \
        message "For structures with non-robust Wilson plot fix <B>" \
        help "scal_lssc_fixb" \
        widget SCALING_IF_FIXB -toggleon \
        label "For low resolution structures, fix the B values of Babinet's bulk solvent to" \
        widget SCALING_FIXB_BBULK \
        toggle_display BULK_SOLVENT_SCALING open BULK

#---------------------------------------------------Rigid Domain Definition

  SetProgramHelpFile [file join $help_source keywords xray-general.html]

  OpenFolder 9 REFINE_TYPE open RIGID hide

 CreateToggleFrame NDOMAINS RefmacDomains \
        "Define the independent domains, or let Refmac make automatic choice" \
        "Domain number" \
        "Add Domain Definition"  \
       [list NGROUPS \
        INITIALISE_RIGID \
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
  

#----------------------------------------------------------Geometric parameters

  OpenFolder 12 REFINE_TYPE hide { RIGID UNRE } closed

  SetProgramHelpFile [file join $help_source keywords restraints.html]

  OpenSubFrame frame 

  $frame configure -width 1000

  CreateLineTemplate TOP { 0.1 0.28 0.41 0.52 }
  CreateLineTemplate SIGMA6 { 0.0  0.28 0.41 0.52 0.64 0.76 0.88 }

  CreateLine line \
	label "Restraint" -italic \
	label "Overall wt" -italic \
	label "Sigmas" -italic \
	format template TOP

  CreateLine line \
	message "Enter Overall weight(WDSKAL) for distance restraints" \
        widget IFDIST -toggleon \
	label "Distance" \
	help dist \
	widget WDSKAL \
	format template SIGMA6

  CreateLine line \
        message "Enter Overall weight (ANGLE_SCALE) for angle restraints" \
        widget IFANGL -toggleon \
        label "Angle" \
        help angl \
        widget ANGLE_SCALE \
        format template SIGMA6

  CreateLine line \
	label " " \
	label " " \
	label "main chain" -italic \
	label "main chain" -italic \
	label "side chain" -italic \
	label "side chain" -italic \
	format template SIGMA6

  CreateLine line \
	label " " \
	label " " \
	label "bond" -italic \
	label "angle" -italic \
	label "bond" -italic \
	label "angle" -italic \
	format template SIGMA6

  CreateLine line \
        message "Enter overall weight (WBSKAL) for Bfactor restraints" \
        widget IFTMP -toggleon \
	label "Bfactor" \
	help bfac \
	widget WBSKAL \
	message "Enter weight for main chain bonded Bfactor restraint (SIGB1)" \
	widget SIGB1 \
	message "Enter weight for main chain non-bonded Bfactor restraint (SIGB2)" \
	widget SIGB2 \
	message "Enter weight for side chain bonded Bfactor restraint (SIGB3)" \
	widget SIGB3 \
	message "Enter weight for side chain non-bonded Bfactor restraint (SIGB4)" \
	widget SIGB4 \
	format template SIGMA6

  CreateLine line \
	label " " \
	label " " \
	label "peptide" -italic \
	label "aromatic" -italic \
	format template SIGMA6


  CreateLine line \
	message "Enter overall weight (WPSKAL) for plane restraints" \
	help plan \
        widget IFPLAN -toggleon \
	label "Plane" \
	widget WPSKAL \
	message "Enter weight for peptide plane restraints (SIGPP)" \
	widget SIGPP \
	message "Enter weight for aromatic plane restraints (SIGPA)" \
	widget SIGPA \
	format template SIGMA6

  CreateLine line \
	label " " \
	label " " \
	label "chiral" -italic \
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
        message "Enter overall weight (WTSKAL) for torsion restraints" \
	help tors \
        widget IFTORS -toggleon \
	label "Torsion" \
	widget WTSKAL \
	format template SIGMA6

  CreateLine line \
	label " " \
	label " " \
	label "tight" -italic \
	label "medium" -italic \
	label "loose" -italic \
	format template SIGMA6

  CreateLine line \
        message "Enter overall weight (WSSKAL) for NCS xyz & Bfactor restraints" \
	help ncsr \
	widget IFNCSR -toggleon \
	label "NCS position" \
	widget WSSKAL \
        message "Enter weight for NCS tight positional restraints (SIGSP1) - fill in all values" \
	widget SIGSP1 \
        message "Enter weight for NCS medium positional restraints (SIGSP1) - fill in all values" \
	widget SIGSP2 \
        message "Enter weight for NCS loose positional restraints (SIGSP1) - fill in all values" \
	widget SIGSP3 \
	format template SIGMA6

  CreateLine line \
	help ncsr \
        label "     NCS Bfactor " \
        label " " \
        message "Enter weight for NCS tight Bfactor restraints (SIGSB1) - fill in all values" \
        widget SIGSB1 \
        message "Enter weight for NCS medium Bfactor restraints (SIGSB2) - fill in all values" \
        widget SIGSB2 \
        message "Enter weight for NCS loose Bfactor restraints (SIGSB3) - fill in all values" \
        widget SIGSB3 \
        format template SIGMA6

# customise so changing SIGSB1/SIGSB2/SIGSB3 will toggle on the IFNCSR

   bind $line.e3 <KeyRelease> "toggle_on $arrayname IFNCSR"
   bind $line.e4 <KeyRelease> "toggle_on $arrayname IFNCSR"
   bind $line.e5 <KeyRelease> "toggle_on $arrayname IFNCSR"

  CreateLine line \
        label "VDW contacts" -italic

   CreateLine line \
        widget IFVAND -toggleon \
	label "VDW contacts" \
	message "Enter overall weight (WVSKAL) for VDW contacts" \
	help restr_vdwr \
	widget WVSKAL \
        format template SIGMA6

   CreateLine line \
     label "Sigmas for types of non-bonding interaction.." -italic

   CreateLine line \
     message "Set sigma for non-bonded atom pair(VDW SIGMA VDW)" \
     label "Non-bonding" \
     widget WAND_SIGMA_VDW \
     message "Set sigma for possible hydrogen-bonded atom pair(VDW SIGMA HBOND)" \
     label "H-bonding" \
     widget WAND_SIGMA_HBOND \
     message "Set sigma for metal or ion interactions(VDW SIGMA METAL)" \
     label "metal-ion interactions" \
     widget WAND_SIGMA_METAL \
     label "1-4 atoms in torsion" \
     message "Set sigma for atoms either side or torsion (VDW SIGMA TORS)" \
     widget WAND_SIGMA_TORS

  CreateLine line \
    label "Set increments for non-bonded interactions.." -italic

  CreateLine line \
     label "1-4 atoms in torsion" \
     message "Set increment for atoms either side or torsion (VDW INCR TORS)" \
     widget WAND_INCR_TORS \
     label "H-bond pair (not hydrogen atom)" \
     message "Set increment for H-bond pair(VDW INCR ADHB)" \
     widget WAND_INCR_ADHB \
     label "H-bonded pair (one is hydrogen atom)" \
     message "Set increment for H-bond pair(VDW INCR AHHB)" \
     widget WAND_INCR_AHHB 

  # Options for anisotropic b-factors
  OpenSubFrame frame -toggle_display REFINE_TYPE open { REST UNRE }

    CreateLine line \
	widget IFISO -toggleon \
        label "Anisotropic refinement" \
        label " " \
        label sphericity \
        label "bond projection" \
	format template SIGMA6 \
        toggle_display B_REFINEMENT_MODE open { ANIS MIXED }

    CreateLine line \
	label " " \
        label " " \
	widget SPHERICITY \
	widget RBOND \
	format template SIGMA6 \
        toggle_display B_REFINEMENT_MODE open { ANIS MIXED }

  CloseSubFrame

  set width [$frame cget -width]

  CloseSubFrame

  CreateLine line \
        label "Set limits for B values.." \
           -italic

  CreateLine line \
        message "Set limits for Bvalues (discouraged) (BLIM)" \
	help blim \
        widget BLIM \
	  -toggleon \
        label "Limit B value range from" \
        widget BLIM_MIN \
        label "to" \
        widget BLIM_MAX \
	toggle_display REFINE_TYPE hide IDEA open

}
