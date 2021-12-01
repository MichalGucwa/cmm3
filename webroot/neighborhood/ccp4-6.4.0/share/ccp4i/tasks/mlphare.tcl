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
# mlphare.tcl --
#
# Run mlphare heavy atom refinement
#
# CCP4Interface 
#
# =======================================================================

#-----------------------------------------------------------------
proc mlphare_close { arrayname } {
#-----------------------------------------------------------------
  global logdata
  if { [array exists logdata] } { unset logdata }
}

#-----------------------------------------------------------------
proc mlphare_run { arrayname } {
#-----------------------------------------------------------------
  upvar #0 $arrayname array

  set array(INPUT_FILES) "HKLIN"

  if { $array(LABOUT_ID) == "" } { set array(LABOUT_ID) "mlphare1" }

  for { set n 1 } { $n <= $array(N_DERIVS) } { incr n } {
    set prefix [GetValue $arrayname [Indxv XYZ_REF_DATA $n] ]
    set line0 [subst $prefix]OCC 
    set line1 [subst $prefix]B 
    set mode 0
    for { set i 1 } { $i <= $array(MLPHARE_NCYCLES) } { incr i } {
      append line$mode " $i"
      set mode [expr 1 - $mode ]
    }
    set array([Indxv ALT_OCC_B $n]) ""
    append array([Indxv ALT_OCC_B $n]) $line0 " " $line1
    if { [GetValue $arrayname [Indxv DERIV_DATA_MODE $n]] == "FILE" } {
      append array(INPUT_FILES) " DERIV_DATA_FILE,$n"
    }
  }

  if { ![SetHarvestParams $arrayname HKLIN  -run] } { return 0 }

  return 1
}

#-----------------------------------------------------------------
proc mlphare_setup { typedefVar arrayname } {
#-----------------------------------------------------------------
  upvar #0 $typedefVar typedef

set typedef(_mlphare_mode)	{ menu {	"refinement"
						"phase calculation" }
						{ REFINE
						  PHASE } }



set typedef(_mlphare_stats)	{ menu {	"Lack of closure and Average FP FPH FH"
						"Average |FP| |FPH| |FH|"
						"RMS lack of closure"
						"RMS FP FPH FH"
						"First wted average lack closure"
						"First wted RMS lack of closure"
						"Second wted average lack closure"
						"Second wted RMS lack of closure" }
					{	"AVE AVF"
						"AVF"
						"RMSE"
						"RMSF"
						"W1AVE"
						"W1RMSE"
						"W2AVE"
						"W2RMSE" } }

set typedef(_mlphare_ref_data)	{ menu {	"isomorphous"
						"anomalous" } 
						{ " "  A } }


set typedef(_mlphare_occ_b_ref) { menu {	"refine occupancy"
						"refine B values"
						"alternate Occ & B" 
					        "occupancy & B"
						"not refine occ/B" }
					{	occ
						B
						alt_occ_B 
					        occ_B
						no_occ_B } }

set typedef(_mlphare_special_atom) { menu {	"normal"
						"on Y-axis" } }

set typedef(_mlphare_nstats)	   { menu {	"no"
						"one set"
						"two sets" }  
					  {	0 1 2 } }
set typedef(_mlphare_log_mode)	{ menu {	"for job number"
						"from selected log file" }
					{	JOB
						FILE } }
set typedef(_mlphare_use_deriv) { menu { 	"Do not use"
						"Phase with"
						"Refine"
						"Phase with&refine" }
					{	NONE
						PHASE
						REFINE
						BOTH } }

set typedef(_mlphare_angle) { menu { 30 20 15 12 10 8 6 5 4 } }

set typedef(_mlphare_data_entry)  { menu { "entered below" "from HA file" }
                                        { LIST FILE } }

set typedef(_mlphare_map_mode) { menu { "difference"
                                        "double difference"
                                        "anomalous"} 
					{ DIFFERENCE
                                          DOUBLE
					  ANOMALOUS } }
return 1

}

#----------------------------------------------------------------------
proc MlpharePossibleChangeHand { arrayname } {
#----------------------------------------------------------------------
# On the basis of HKLIN spacegroup, determine whether hand change
# is possible. If not, turn off ALLOW_CHANGE_HAND (controls display
# of option) and CHANGE_HAND (controls option). If it is possible,
# turn on option (ALLOW_CHANGE_HAND) but don't alter value of option.

   upvar #0 $arrayname array

   if { ![file exists [GetFullFileName0 $arrayname HKLIN]] } { 
     set array(ALLOW_CHANGE_HAND) 0
     set array(CHANGE_HAND) 0
     return 0 
   }

   GetMtzParam [GetFullFileName0 $arrayname HKLIN] SPACE_GROUP_NAME mtz_space_group
   set status [ GetChangeHandData $mtz_space_group new_space_group cx ]
   switch -- $status \
    0 {
       WriteToLog "ERROR getting data from CCP4I_TOP/etc/crystal.lib"
       set array(ALLOW_CHANGE_HAND) 0
       set array(CHANGE_HAND) 0
    } -1 {
       set array(ALLOW_CHANGE_HAND) 0
       set array(CHANGE_HAND) 0
    } default {
       set array(ALLOW_CHANGE_HAND) 1
    }
}

#----------------------------------------------------------------------
proc MlphareChangeHand { arrayname } {
#----------------------------------------------------------------------
   upvar #0 $arrayname array

# At present simply warn the user to check for consistent input
   if { $array(CHANGE_HAND) == 1 } {
     WarningMessage "You are opting to reverse the hand of the spacegroup

You should check that your input heavy atom data is consistent
with the change of hand before running the task"
   }
}

#----------------------------------------------------------------------
proc MlphareReadFrac { arrayname nd } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array

# Read the log file and look for near the end of the mlphare output
  if { ![SelectFile filename -title "Select Fractional Coordinate File"  \
      -filter "*.ha" -defdir [GetCurrentProject] ] } { return 0 }

  if { ![ReadFile [lindex $filename 0] log_text -split ] } {
    WarningMessage  "ERROR reading file: [lindex $filename 0] "
    return 0
  }
  set nin 0
  foreach line $log_text {
    if { [regexp ^ATOM $line] } { incr nin } 
  }

  set array(LOAD_NATOMS) $nin
  set array(LOAD_OVERWRITE) 0
  set array(LOAD_ATOM_TYPE) ""
  set array(LOAD_OCC) ""
  set array(LOAD_ANOM_OCC) ""
  set array(LOAD_B) ""
  if { ![InputParamDialog "Load coordinates to Mlphare" Load \
    $arrayname [ list \
	[ list LOAD_OVERWRITE "Overwrite existing atoms" _logical ] \
	[ list LOAD_NATOMS "How many atoms to load" _positiveint ] \
	[ list LOAD_ATOM_TYPE "Set atom type" _text ] \
	[ list LOAD_OCC "Override occupancy" _positivereal ] \
	[ list LOAD_ANOM_OCC "Override anomalous occupancy" _positivereal ] \
	[ list LOAD_B "Override temperature factor" _positivereal ] ] ] } { return 0 }


  PleaseWait "Loading HA file..."
  
  set nin [min $nin $array(LOAD_NATOMS)]
  set na 0
  if { $array(LOAD_OVERWRITE) } {
    set last $nin
  } else {
    if { $array(N_ATOMS,$nd) != 1 || $array([Indxv XFRAC $nd 1]) != "" } {
      set na $array(N_ATOMS,$nd)
    }
    set last [expr $na + $nin ]
  }

  UpdateExtendingFrame MlphareAtoms $nd $arrayname $nin

  foreach line $log_text {
    if { $na < $last && [regexp ^ATOM $line ] } {
      incr na
      if { $array(LOAD_ATOM_TYPE) != "" } {
        set array([Indxv ATOM_ID $nd $na]) $array(LOAD_ATOM_TYPE)
      } else {
        set array([Indxv ATOM_ID $nd $na]) [lindex $line 1 ]
      }
      set array([Indxv XFRAC $nd $na]) [lindex $line 2 ]
      set array([Indxv YFRAC $nd $na]) [lindex $line 3 ]
      set array([Indxv ZFRAC $nd $na]) [lindex $line 4 ]
      if { $array(LOAD_OCC) != "" } {
        set array([Indxv ATOM_OCC $nd $na]) $array(LOAD_OCC)
      } else {
        set array([Indxv ATOM_OCC $nd $na]) [lindex $line 5 ]
      }
      if { $array(LOAD_B) != "" } {
        set array([Indxv BFACTOR $nd $na]) $array(LOAD_B)
      } else {
        set array([Indxv BFACTOR $nd $na]) \
	  [lindex $line [expr 1 + [lsearch $line BFAC ] ] ]
      }
      if { $array(LOAD_ANOM_OCC) != "" } {
        set array([Indxv ANOMALOUS_OCC $nd $na]) $array(LOAD_ANOM_OCC)
      } elseif { ![regexp BFAC [lindex $line 6 ] ] } {
        set array([Indxv ANOMALOUS_OCC $nd $na]) [lindex $line 6 ]
      } else {
        set array([Indxv ANOMALOUS_OCC $nd $na]) 0.0
      }
      set array([Indxv USE_ANISO_B $nd $na]) 0
      set array([Indxv ANISOTROPIC_B_1 $nd $na]) ""
      set array([Indxv ANISOTROPIC_B_2 $nd $na]) ""
      set array([Indxv ANISOTROPIC_B_3 $nd $na]) ""
      set array([Indxv ANISOTROPIC_B_4 $nd $na]) ""
      set array([Indxv ANISOTROPIC_B_5 $nd $na]) ""
      set array([Indxv ANISOTROPIC_B_6 $nd $na]) ""
    }
  }
  set array(N_ATOMS,$nd) $na

  PleaseWait

#  ReCreateTaskWindow CURRENT mlphare $array(WINDOW) $arrayname

}


#--------------------------------------------------------------------
proc MlphareDeriv { arrayname counter } {
#--------------------------------------------------------------------
   global configure
  upvar #0 $arrayname array

  CreateLine line \
    message "Do you want to use this derivative in this mlphare run?" \
    widget USE_DERIV \
    message "Enter title for derivative (DERIV <title>)" \
    help derivative_deriv \
    label "derivative" \
    widget DERIV_TITLE -width 50 -expand -oblig \
	-command "mlphare_update_deriv_title $arrayname $counter"


    if { $array(DERIV_TITLE,$counter) != "" } {
      mlphare_update_deriv_title $arrayname $counter
    }

  CreateLine line \
        message "Refine against isomorphous or anomalous data in this Mlphare run (ATREF)" \
        help derivative_atref \
        label "Use" \
        widget XYZ_REF_DATA \
        label "data to" \
        message "Refine the atom coordinates? (ATREF)" \
        widget REFINE_XYZ \
        label  "refine XYZ and" \
        message "Refine Bvalues and occupancy? (ATREF)" \
        widget OCC_B_REF_MODE \
        message "Also refine the anomalous occupancy? (ATREF)" \
        widget REFINE_ANOM_OCC \
        label "Refine anom occ"\
        toggle_display [Indxv XYZ_REF_DATA $counter] hide A

  CreateLine line \
        message "Refine against isomorphous or anomalous data in this Mlphare run (ATREF)" \
        help derivative_atref \
        label "Use" \
        widget XYZ_REF_DATA \
        label "data to" \
        message "Refine the atom coordinates? (ATREF)" \
        widget REFINE_XYZ \
        label  "refine XYZ and" \
        message "Refine Bvalues and occupancy? (ATREF)" \
        widget OCC_B_REF_MODE \
        toggle_display [Indxv XYZ_REF_DATA $counter]  open A


  CreateLine line \
       message "Refine heavy atoms with data from file or listed below" \
       label "Use heavy atom site data" \
       widget DERIV_DATA_MODE

 
  CreateInputFileLine line \
      "Enter heavy atom data file (.ha)" \
      "HA in" \
       DERIV_DATA_FILE  DIR_DERIV_DATA_FILE \
       -toggle_display DERIV_DATA_MODE,$counter open FILE

  OpenSubFrame frame -toggle_display DERIV_DATA_MODE,$counter open LIST

  CreateLine line \
        label "Use atom"  \
        label "atomID" \
        label "Xfrac" \
        label "Yfrac" \
        label "Zfrac" \
        label "B" \
        label "Occ" \
        label "AnomOcc"  \
        label "AnisoBs" \
        format template HEAVY_ATOMS

#        label "Atom type" 

  CreateExtendingFrame N_ATOMS MlphareAtoms \
        "Define heavy atoms in derivative" \
        "Add Heavy Atom Site" \
      [list  USE_ATOM  \
        ATOM_ID \
        XFRAC \
        YFRAC  \
        ZFRAC \
        ATOM_OCC \
        ANOMALOUS_OCC \
        BFACTOR \
	USE_ANISO_B \
        ANISOTROPIC_B_1 \
        ANISOTROPIC_B_2 \
        ANISOTROPIC_B_3 \
        ANISOTROPIC_B_4 \
        ANISOTROPIC_B_5 \
        ANISOTROPIC_B_6  ] \
        -counter $counter

   set addline $array(XF_COMLINE_MlphareAtoms_$counter)

   button $addline.file -text "Read from HA File" \
	-font $configure(FONT_REGULAR) \
	-background $configure(COLOUR_PALE) \
        -command "MlphareReadFrac $arrayname $counter"
   pack $addline.file -side left

  CloseSubFrame

}

#--------------------------------------------------------------------
proc MlphareExclude { arrayname counter } {
#--------------------------------------------------------------------

  upvar #0 $arrayname array

  CreateLine line \
    label "For derivative number $counter $array(DERIV_TITLE,$counter) exclude reflections:" \
	-italic

  CreateLine line \
    message "Exclude reflections if FPH < cutoff * SIGMA(FPH) (EXCLUDE SIGFPH)" \
    help derivative_exclude \
    widget EXCLUDE_SIGFPH \
	-toggleon \
    label "FPH less than" \
    widget EXCLUDE_SIGFPH_CUTOFF \
    label "*sigma(FPH)          " \
    message "Exclude isomorphous reflections if (FPH-FP) > cutoff (EXCLUDE DISO)" \
    help derivative_exclude_diso \
    widget EXCLUDE_DISO \
	-toggleon \
    label "(FPH-FP) greater than" \
    widget EXCLUDE_DISO_CUTOFF

  CreateLine line \
        message "Restrict anomalous differences to range (EXCLUDE DANO)" \
	help derivative_exclude_dano \
        widget EXCLUDE_DANO \
	-toggleon \
        label "Anomalous differences less than" \
        widget EXCLUDE_DANO_MIN \
        label "or greater than" \
        widget EXCLUDE_DANO_MAX \
        toggle_display ANOMALOUS_DATA hide 0

  CreateLine line \
    message  \
    "Set resolution limits for this derivative (RESOLUTION & RESOLUTION ANO)" \
    help derivative_resolution \
    widget DERIV_EXCLUDE_RESOLUTION \
	-toggleon \
    label "Outside resolution range" \
    widget RESOLUTION_MIN \
    label "to" \
    widget RESOLUTION_MAX \
    label "or for anomalous data" \
    help derivative_resolution_ano \
    widget ANO_RESOLUTION_MIN \
    label "to" \
    widget ANO_RESOLUTION_MAX

}

#----------------------------------------------------------------------------
proc MlphareProtocol { arrayname counter } {
#----------------------------------------------------------------------------

  upvar #0 $arrayname array

  CreateLine line \
    message "Do you want to use this derivative in this mlphare run?" \
    widget USE_DERIV \
    label "derivative number $counter $array(DERIV_TITLE,$counter)" \
	-italic


  CreateLine line \
        message "Refine against isomorphous or anomalous data in this Mlphare run (ATREF)" \
	help derivative_atref \
	label "Use" \
	widget XYZ_REF_DATA \
	label "data to" \
        message "Refine the atom coordinates? (ATREF)" \
        widget REFINE_XYZ \
        label  "refine XYZ and" \
        message "Refine Bvalues and occupancy? (ATREF)" \
        widget OCC_B_REF_MODE \
        message "Also refine the anomalous occupancy? (ATREF)" \
  	widget REFINE_ANOM_OCC \
	label "Refine anom occ"\
	toggle_display [Indxv XYZ_REF_DATA $counter] hide A

  CreateLine line \
        message "Refine against isomorphous or anomalous data in this Mlphare run (ATREF)" \
	help derivative_atref \
        label "Use" \
        widget XYZ_REF_DATA \
        label "data to" \
        message "Refine the atom coordinates? (ATREF)" \
        widget REFINE_XYZ \
        label  "refine XYZ and" \
        message "Refine Bvalues and occupancy? (ATREF)" \
        widget OCC_B_REF_MODE \
	toggle_display [Indxv XYZ_REF_DATA $counter]  open A
}


#----------------------------------------------------------------------------
proc MlphareAtoms { arrayname c2 c1 } {
#----------------------------------------------------------------------------
  upvar #0 $arrayname array

  if { $c2 > 1 } {
    set clast [expr $c2 -1]
    if { $array([Indxv ATOM_ID $c1 $c2]) == ""   } {
    set array([Indxv ATOM_ID $c1 $c2]) $array([Indxv ATOM_ID $c1 $clast]) }
    if { $array([Indxv BFACTOR $c1 $c2]) == ""   } {
    set array([Indxv BFACTOR $c1 $c2]) $array([Indxv BFACTOR $c1 $clast]) }
    if { $array([Indxv ATOM_OCC $c1 $c2]) == ""   } {
    set array([Indxv ATOM_OCC $c1 $c2]) $array([Indxv ATOM_OCC $c1 $clast]) }
    if { $array([Indxv ANOMALOUS_OCC $c1 $c2]) == ""   } {
    set array([Indxv ANOMALOUS_OCC $c1 $c2]) $array([Indxv ANOMALOUS_OCC $c1 $clast]) }
  }

   CreateLine line \
	message "Is this atom to be refined in this run of Mlphare?" \
	help derivative_atom \
	widget USE_ATOM \
	message "Enter atom identifier corresponding to one in atomsf.lib" \
	widget ATOM_ID \
	message "Enter current fractional coordinates" \
	widget XFRAC \
	widget YFRAC \
	widget ZFRAC \
	message "Isotropic Bfactor" \
	widget BFACTOR \
	  -width 6 \
	message "Occupancy" \
	widget ATOM_OCC \
	  -width 6 \
	message "Anomalous occupancy" \
	widget ANOMALOUS_OCC \
	  -width 6 \
        message "Use anisotropic Bfactors for this derivative?" \
        help derivative_atom_bfac \
        widget USE_ANISO_B \
	format template  HEAVY_ATOMS

   CreateLine line \
        message "Anistotropic Bfactors for heavy atoms" \
	help derivative_atom_bfac \
	label "Aniso Bs" \
	widget ANISOTROPIC_B_1 \
	widget ANISOTROPIC_B_2 \
	widget ANISOTROPIC_B_3 \
	widget ANISOTROPIC_B_4 \
	widget ANISOTROPIC_B_5 \
	widget ANISOTROPIC_B_6 \
        toggle_display  [Indxv USE_ANISO_B $c1 $c2 ] hide 0

}

#-----------------------------------------------------------------------------
proc MlphareClosure { arrayname counter } {
#-----------------------------------------------------------------------------

  upvar #0 $arrayname array

  CreateLine line \
    label "Derivative number $counter $array(DERIV_TITLE,$counter)"

  CreateLine line \
    message "Estimated lack of closure input from previous run of mlphare" \
    help derivative_isoerror \
    label "Isomorphous" \
    widget ISOERROR_1 \
    widget ISOERROR_2 \
    widget ISOERROR_3 \
    widget ISOERROR_4 \
    widget ISOERROR_5 \
    widget ISOERROR_6 \
    widget ISOERROR_7 \
    widget ISOERROR_8 \
    format template CLOSURE

  CreateLine line \
    message "Estimated lack of closure input from previous run of mlphare" \
    help derivative_anoerror \
    label "Anomalous" \
    widget ANOERROR_1 \
    widget ANOERROR_2 \
    widget ANOERROR_3 \
    widget ANOERROR_4 \
    widget ANOERROR_5 \
    widget ANOERROR_6 \
    widget ANOERROR_7 \
    widget ANOERROR_8 \
    format template CLOSURE
}

#-----------------------------------------------------------------
proc MlphareFPH { arrayname counter } {
#-----------------------------------------------------------------

  CreateLabinLine line \
    "Choose derivative amplitude (FPH) and optional sigma (SIGFPH)" \
     HKLIN "FPH$counter" FPH  [list FPH$counter *[subst $counter]* ] \
     -sigma "SigFPH$counter" SIGFPH  {NULL} \
     -toggle_display ANOMALOUS_DATA hide 1

  CreateLabinLine4 line \
     "Choose derivative data: amplitudes (FPH/SIGFPH) and anomalous differences (DPH/SIGDPH)" \
      HKLIN "FPH$counter" FPH  [list FPH$counter *[subst $counter]* ] \
     -sigma "SigFPH$counter" SIGFPH  {NULL} \
     -dependent "DPH$counter" DPH [list DPH$counter *[subst $counter]* ]  \
     -sigma "SigDPH$counter" SIGDPH {NULL} \
     -toggle_display ANOMALOUS_DATA hide 0

}

#-----------------------------------------------------------------
proc MlphareCrossPeaks { arrayname counter } {
#-----------------------------------------------------------------

  CreateLabinLine line \
    "Choose derivative amplitude (FPH) and optional sigma (SIGFPH)" \
     HKLIN "FPH$counter" XPEAK_FPH  {} \
     -sigma "SigFPH$counter" XPEAK_SIGFPH  {NULL}

}



#-----------------------------------------------------------------
proc mlphare_update_deriv_title { arrayname counter } {
#-----------------------------------------------------------------
  upvar #0 $arrayname array
  if { $counter <= 0 } { return }
  for { set n 1 } { $n <= $counter } { incr n } {
    if [ElementExists $arrayname DERIV_TITLE,$counter] {
      set title "Derivative number $counter "
      append title $array(DERIV_TITLE,$counter)
      SetToggleTitle $arrayname MlphareDeriv $counter "$title"
    }
  }
}

#=CREATE=WINDOW=AND=SUBWINDOWS===========================================

#-----------------------------------------------------------------
proc mlphare_task_window { arrayname } {
#-----------------------------------------------------------------

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Run Mlphare" "Mlphare" \
	[ list "Data Harvesting" \
	"Key Parameters" \
        "Describe Derivatives & Refinement"  \
	"Exclude Reflections from Refinement" \
	"Estimated Lack of Closure" \
	"Output Statistics"  \
	"Detailed Refinement Options"  \
	"Output Maps Details" ] \
	-file_cleanup 0 ] == 0 } return

  SetDefaultMapFormat $arrayname MAPOUT_FORMAT
  SetHarvestParams $arrayname HKLIN -init

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE


  CreateLineTemplate DATA_OUT [list 0.0 0.5 0.54]

  CreateLine line \
    message "Is anomalous difference data available for any derivative?" \
    help general_labin \
    widget ANOMALOUS_DATA \
    label "Use anomalous difference data   " \
    message "Use externally calculated phases" \
    widget EXTERNAL_PHASES \
    label "Add phase info from externally calculated phases"

  CreateLine line \
    message "Use centric data only? (CENTRIC)" \
    widget CENTRIC \
    label "Use centric data only" \
    toggle_display ANOMALOUS_DATA hide [list 1] 

  CreateLine line \
    message "Use a subset of all the available reflections? (SKIP)" \
    help skip \
    widget USE_SKIP -toggleon \
    label "Use every" \
    widget N_SKIP \
    label "-th reflection for refinement" \
    toggle_display CENTRIC hide [list 1]

   CreateLine line \
    message "Usually apply scale after final cycle of refinement" \
    widget APPLY_SCALE \
    label "Apply calculated scale to output SFs"


  CreateLine line \
    message "Output Hendrickson-Lattman coefficients(HLOUT)" \
    help general_labout \
    widget OUTPUT_HL_COEFFS \
    label "Output Hendrickson-Lattman coefficients"


   CreateLine line \
     message "Output all maps in  selected format" \
     label "Output map(s) in" \
     widget MAPOUT_FORMAT \
     label format

  CreateLine line \
    message "Output 'final' map of FP, PHIBest, FOM" \
    label Output \
    widget IFMAPOUT \
    label "map of FP with final best Phi" \
    message "Output maps with FPH of other derivative and refined phases" \
    widget CROSS_PEAKS \
    label "cross-peaks map(s)"

   CreateLine line \
    message "Output heavy atom SFs for double difference maps" \
    widget FHOUT \
    label Generate \
    widget MAP_MODE \
    label "maps and do peak search for more heavy atoms"



#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
       HKLIN DIR_HKLIN \
       -fileout HKLOUT DIR_HKLOUT _mlphare  \
       -setfileparam resolution_min EXCLUDE_RESOLUTION_MIN \
       -setfileparam resolution_max EXCLUDE_RESOLUTION_MAX \
       -setfileparam resolution_min MAP_RESOLUTION_MIN \
       -command "MlpharePossibleChangeHand $arrayname" \
       -command "UpdateHarvestMTZ $arrayname HKLIN"

  CreateLabinLine line \
    "Choose protein amplitude (FP) and optional sigma (SIGFP)" \
     HKLIN "FP    " FP  [list FP* F_P* FNAT* ] \
     -sigma "SigmaFP  " SIGFP  {NULL}

  CreateExtendingFrame N_DERIVS  MlphareFPH \
        "Select derivative column data from MTZ file" \
        "Add Another Derivative" \
      [list  FPH \
        SIGFPH \
        DPH \
        SIGDPH ]  \
        -dependentframe MlphareDeriv \
        -dependentframe MlphareClosure \
        -dependentframe MlphareExclude


  CreateLabinLine line \
    "Enter the external calculated phases (PHIC) and weights (WC)" \
     HKLIN "PHIC   " PHIC  {} \
     -sigma "Weight " WC  {} \
     -toggle_display EXTERNAL_PHASES hide 0

  CreateLabinLine line \
    "Optional Fcalc used with PHIC for Sim weights )FC)" \
     HKLIN "FC   " FC  {}  \
     -toggle_display EXTERNAL_PHASES hide 0

  OpenSubFrame frame -toggle_display CROSS_PEAKS open 1

  CreateLine line \
    label "Choose other derivatives for cross-peaks maps" -italics

  CreateExtendingFrame N_CROSS_PEAKS MlphareCrossPeaks \
	"Select cross-peak derivative column data from MTZ file" \
        "Add Another Cross-Peak Derivative" \
      [list  XPEAK_FPH \
        XPEAK_SIGFPH ]

  CloseSubFrame


  CreateOutputFileLine line \
    "Enter name of output MTZ file (HKLOUT)" \
    "MTZ out" \
    HKLOUT DIR_HKLOUT

  CreateLine line \
    message "Enter text for output label (eg entering 'mlphare1' gives output labels 'FP_mlphare1' etc)" \
    label "Output label identifier" \
    widget LABOUT_ID

#=======================================================================

  OpenFolder 1 

  CreateHarvestLine line 
#----------------------------------------------------------------------------------

  OpenFolder 2

  CreateLine line \
    message "Convert the space group to the other hand before running Mlphare" \
    widget  CHANGE_HAND \
    -command "MlphareChangeHand $arrayname" \
    label "Change the space group to opposite hand before running Mlphare" \
    toggle_display ALLOW_CHANGE_HAND open 1

  CreateLine line \
    message "Apply resolution limits to all data (RESOLUTION)" \
    help general_resolution \
    widget EXCLUDE_RESOLUTION \
	-toggleon \
    label "Resolution limit from" \
    widget EXCLUDE_RESOLUTION_MIN \
    label "to" \
    widget EXCLUDE_RESOLUTION_MAX

 CreateLine line \
    message "Phase probability angle - small angle increases job time (ANGLE)" \
    help general_angle \
    widget USE_ANGLE \
	-toggleon \
    label "Angle interval (degrees) for phase probability curve" \
    widget ANGLE

  CreateLine line \
    message "Mlphare protocol - do refinement or just calculate phases" \
    help description \
     label "Do" \
     widget MLPHARE_MODE \
     label "for " \
     message "Number of cycles (CYCLE <ncycles>)" \
     help derivative_dcycle \
     widget MLPHARE_NCYCLES  \
     label "cycles" \
     toggle_display MLPHARE_MODE open refinement

  CreateLine line \
    message "Mlphare protocol - do refinement or just calculate phases" \
     label "Do" \
     widget MLPHARE_MODE \
     toggle_display MLPHARE_MODE hide refinement


#----------------------------------------------------------------------------
  OpenFolder 3

  CreateLineTemplate HEAVY_ATOMS { 0 0.11 0.22 0.33 0.44 0.55 0.66 0.77 0.88 }

  CreateToggleFrame N_DERIVS MlphareDeriv \
    "Define derivative crystal structure" "Derivative number" \
    "Add Another Derivative"  \
    [list DERIV_TITLE \
	DERIV_DATA_MODE \
	DERIV_DATA_FILE \
	DIR_DERIV_DATA_FILE \
	N_ATOMS  \
        USE_DERIV \
        XYZ_REF_DATA \
        REFINE_XYZ \
        OCC_B_REF_MODE \
        REFINE_ANOM_OCC \
        ALT_OCC_B] \
	-noaddline \
	-child MlphareAtoms \
	-edit_proc mlphare_update_deriv_title

#---------------------------------------------------------Exclude reflections

  OpenFolder 4 closed

  CreateLine line \
    message "Exclude reflections if FP < cutoff * SIGMA(FP) (EXCLUDE SIGFP)" \
    help general_exclude_sigfp \
    widget EXCLUDE_SIGFP \
        -toggleon \
    label "FP less than" \
    widget EXCLUDE_SIGFP_CUTOFF \
    label "*sigma(FP)"


  CreateExtendingFrame N_DERIVS MlphareExclude \
        "Exclude reflections from refinement - select for each derivative" \
        " " \
      [list DERIV_EXCLUDE_RESOLUTION \
	RESOLUTION_MIN \
        RESOLUTION_MAX \
        ANO_RESOLUTION_MIN \
        ANO_RESOLUTION_MAX \
        EXCLUDE_SIGFPH \
        EXCLUDE_SIGFPH_CUTOFF \
        EXCLUDE_DISO \
        EXCLUDE_DISO_CUTOFF \
        EXCLUDE_DANO \
        EXCLUDE_DANO_MAX \
        EXCLUDE_DANO_MIN ] -noaddline


#-----------------------------------------------------------------------------------

  OpenFolder 5 closed

  CreateLineTemplate CLOSURE [list 0.0 0.15 0.25 0.35 0.45 0.55 0.65 0.75 0.85 0.95 ]

  CreateExtendingFrame N_DERIVS MlphareClosure \
        "Use lack of closure estimates from previous Mlphare run" \
        " " \
      [list  ISOERROR_1 \
	ISOERROR_2 \
	ISOERROR_3 \
	ISOERROR_4 \
	ISOERROR_5 \
	ISOERROR_6 \
	ISOERROR_7 \
	ISOERROR_8 \
	ANOERROR_1 \
	ANOERROR_2 \
	ANOERROR_3 \
	ANOERROR_4 \
	ANOERROR_5 \
	ANOERROR_6 \
	ANOERROR_7 \
	ANOERROR_8 ]  -noaddline

#-----------------------------------------------------------------------------------

  OpenFolder 6 closed

  CreateLine line \
  message "Output statistics to log file (PRINT STATS)" \
  help general_print \
  label "Output" \
  widget PRINT_STATS \
  label "stats. First set" \
  widget PRIMARY_STATS \
  label "second set" \
  widget SECONDARY_STATS

  CreateLine line \
  message "Monitor every nth reflection (PRINT MON <nmon>)" \
  help general_print_mon \
  widget MONITOR \
	-toggleon \
  label "Monitor every" \
  widget MONITOR_NREF \
  label "reflections"

  CreateLine line \
  message "Output correlation matrix (PRINT COR)" \
  help general_print_cor \
  widget CORRELATION_MAT \
  label "Output correlation matrix"

#-----------------------------------------------------------------------------------

  OpenFolder 7 closed

  CreateLine line \
    message "Scale SigmaFP by" \
    help general_scale \
    label "Scale SigFP by" \
    widget SCALE_SIGFP


  CreateLine line \
     message "Damp large parameter shifts (THRESHOLD)" \
     help general_threshold \
     widget USE_THRESHOLD \
	-toggleon \
     label "Damp parameter shifts greater than" \
     widget THRESHOLD_CUTOFF \
     label "SD of shift by"  \
     widget THRESHOLD_DAMP

#--------------------------------------------------------------------------
  OpenFolder 8 closed

  CreateLine line \
    label "For output double difference maps or cross-peak maps..." -italic

  CreateLine line \
    widget MAP_RESOLUTION -toggleon \
    label "Use resolution range" \
    widget MAP_RESOLUTION_MIN \
    label to \
    widget MAP_RESOLUTION_MAX

}
