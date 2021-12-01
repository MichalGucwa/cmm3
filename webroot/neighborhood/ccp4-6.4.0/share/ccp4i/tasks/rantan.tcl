#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
# =====================================================================
# rantan.tcl --
# Template for task interface
# CCP4Interface 
# =======================================================================

#-----------------------------------------------------------------------
proc rantan_setup { typedefVar arrayname } {
#-----------------------------------------------------------------------

  DefineMenu _rantan_data [list "isomorphous or anomalous difference" \
			       "estimates of FH or FA" ] [list ISO ANO ]

  DefineMenu  _rantan_mode [list FASTAN \
		   "weighted tangent formula" ] \
			[list  FASTAN SWTR ]
  return 1
} 


#-----------------------------------------------------------------------
proc rantan_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  return 1
}

#---------------------------------------------------------------------
proc rantan_data_params { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if [regexp ISO [GetValue $arrayname RANTAN_DATA ] ] {
     set array(WFOM) 1
     set array(WABS) 0.3
     set array(WPSI) 0.1
     set array(WRES) 0.6
     set array(EMAX) 6
  } else { 
     set array(WFOM) 0
     set array(WABS) 0.1
     set array(WPSI) 0.4
     set array(WRES) 0.5
     set array(EMAX) 6
  }

}

#-----------------------------------------------------------------------
proc set_res_max_limit { arrayname limit  } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { $array(EXCLUDE_RESOLUTION_MAX) == "" } { return }
  set array(EXCLUDE_RESOLUTION_MAX) [max $limit \
	$array(EXCLUDE_RESOLUTION_MAX)]
}

#-----------------------------------------------------------------------
proc  rantan_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname "Rantan - Direct Methods" "Rantan" \
        [ list "Running Rantan" \
		"Rantan Parameters" \
		"Map Peaks Search"   ]  ] == 0 } return

  SetProgramHelpFile rantan
  rantan_data_params $arrayname

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
    message "Default parameters will be set appropriate for type of data input" \
    label "Set optimal Rantan parameters for" \
    widget RANTAN_DATA -command "rantan_data_params $arrayname" \
    label "data"

  CreateLine line \
    message "Run FFT to generate map and Peaksearch to generate coordinate file" \
    widget RANTAN_PEAKSEARCH \
    label "generate map(s) and coordinate file listing peaks"

#------------------------------------------------------------------Files
  OpenFolder file 

  CreateInputFileLine line \
      "Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
       HKLIN DIR_HKLIN \
       -fileout HKLOUT DIR_HKLOUT _rantan  \
       -setfileparam space_group_name SPACE_GROUP \
       -setfileparam resolution_min EXCLUDE_RESOLUTION_MIN \
       -setfileparam resolution_max EXCLUDE_RESOLUTION_MAX \
       -command "set_res_max_limit $arrayname 3.0"

   CreateLabinLine line \
    "Choose normalised amplitude (EVAL)" \
     HKLIN Es EVAL  { EVAL E }  \
     -sigma SIGE SIGEVAL {} 

   CreateLine line \
     label "Optionally use experimental phases and FOMs..." -italic

   CreateLabinLine line \
    "Input phases (PHI & W)" \
     HKLIN "Input phase" PHI {PHI} \
     -sigma FOM W {W}

  CreateOutputFileLine line \
      "Output MTZ file (HKLOUT). Root of filename used to generate map & pdb filenames" \
      "Output MTZ" \
      HKLOUT DIR_HKLOUT

  CreateLine line \
    message "Output MTZ column labels will be this root name plus the solution number" \
    label "Output label root name for Phi" \
    widget LABOUT_PHI \
    label "Weight" \
    widget LABOUT_W


#=PARAMETERS==========================================================

  OpenFolder 1

  SetProgramHelpFile rantan

  CreateLine line \
    message "Rantan procedure (SWTR)" \
    label "Use" \
    widget SWTR  \
    label "procedure to generate" \
    widget NOUT \
    label "sets of solutions"

  CreateLine line \
    message "Use data from default resolution range (RESO)" \
    widget EXCLUDE_RESOLUTION \
	-toggleon \
    label "Use data from resolution range"  \
    widget EXCLUDE_RESOLUTION_MIN \
    label "to" \
    widget EXCLUDE_RESOLUTION_MAX


  CreateLine line \
    message "Override default limits on amplitudes (EMIN EMAX)" \
    widget IFEMAX \
	-toggleon \
    label "Override default range of E's to set Emin" \
    widget EMIN \
    label "  Emax" \
    widget EMAX

   CreateLine line \
     message "Override default weights for combining FOMs (WFOM)" \
     widget WFOM \
	-toggleon \
     label "Override default weights for combined FOM.  Wabs" \
     widget WABS \
     label " Wpsi" \
     widget WPSI \
     label " Wres" \
     widget WRES
    
#-----------------------------------------------------Rantan parameters
  OpenFolder 2 closed

  CreateLineTemplate PARAMS [list 0.0 0.85]

  CreateLine line \
    label "EPSI  Max. E used to calculate PSIZERO FOM (0.3)" \
    widget EPSI \
    format template PARAMS

  CreateLine line \
    label "KMIN  Min KAPPA for triplet (0.6)" \
    widget KMIN  \
    format template PARAMS

  CreateLine line \
    label "KMAX  Max.  KAPPA for triplet (50.0)" \
    widget KMAX \
    format template PARAMS

  CreateLine line \
    label "MAXS  Number of sets of random phases (500)" \
    widget MAXS \
    format template PARAMS

  CreateLine line \
    label "NRAN  Number of random phases in starting set (250)" \
    widget NRAN \
    format template PARAMS

  CreateLine line \
    label "NREF  Number of large Es used (600)" \
    widget NREF \
    format template PARAMS

  CreateLine line \
    label "NZRO  Number of small Es used to calculate PSIZERO (100)" \
    widget NZRO \
    format template PARAMS
    
  CreateLine line \
    label "SKIP  Skip first <skip> phase sets (0)" \
    widget SKIP \
    format template PARAMS

  CreateLine line \
    label "WMIN  Weight for random phase (0.25)" \
    widget WMIN \
    format template PARAMS

  CreateLine line \
    label "WTRI  Weight for triplet (0.1)" \
    widget WTRI \
    format template PARAMS

  CreateLine line \
    widget LIST \
    label "Extra output to log file"

#--------------------------------------------------------------------Peaksearch

 OpenFolder 3 RANTAN_PEAKSEARCH open 1 hide

   SetProgramHelpFile peakmax

   CreateLine line \
     message "Run Peakmax to find peaks in map & output to coordinate file" \
     label "Find maximum" \
     widget NUMPEAKS \
     label "peaks above" \
     widget THRESHHOLD \
     label "* RMS density"

}

