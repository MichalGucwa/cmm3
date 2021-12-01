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
# prephadata.tcl -- convert Fs to Is for direct methods
# =======================================================================

#-----------------------------------------------------------------------
proc prephadata_setup { typedefVar arrayname } {
#-----------------------------------------------------------------------

  DefineMenu  _prephadata_input [ list "MAD data as F+ F-" \
				"MAD data as Dano" \
				"SAD data as F+ F-" \
				"SAD data as Dano" \
				"SIR data" \
				"native data" ] \
			    [ list MADFS MADDS SADFS SADDS SIR NATIVE]

  DefineMenu _prephadata_output [ list "SHELXS" "SHELXD" "Es (Rantan/Acorn)" "RSPS" ] \
				[ list SHELX SHELXD RANTAN CCP4 ]

  return 1
} 


#-----------------------------------------------------------------------
proc prephadata_run { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [StringSame [GetValue $arrayname REVISE_OUTPUT] CCP4] &&
       [StringSame [GetValue $arrayname REVISE_INPUT ] SADFS SADDS SIR ]  } {
    WarningMessage "No data preparation necessary for SAD or SIR
data input to RSPS.   Will not run task." 
    return 0
  }

  if { [StringSame [GetValue $arrayname REVISE_INPUT] MADFS MADDS ] } {
     if { $array(N_WAVELENGTHS) < 2 } {
        WarningMessage "You need at least two wavelengths for MAD.
Will not run task."
      return 0
     }

     if { $array(USE_REVISE_RESO_CUTOFF) &&
        ![regexp -- "^(\[0-9\]?)(\[\.\])(\[0-9\]*)$" $array(REVISE_RESOLUTION_MAX)]} {
        WarningMessage "Invalid value for high resolution cutoff.
Task run aborted."
        return 0
     }
  }

  if { [StringSame [GetValue $arrayname REVISE_OUTPUT] SHELX SHELXD ] } {
    set array(OUTPUT_FILES) HKLOUT
  } else {
    set array(OUTPUT_FILES) MTZOUT
  }

  return 1
}

#---------------------------------------------------------------------
proc prephadata_anom_labin { arrayname counter } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

   CreateLabinLine line \
    "Choose amplitude (FPH+n) and sigma (SIGFPH+n) for wavelength $counter" \
     MTZIN "FPH+$counter" FPHp  [list FPH+$counter \
                "*+*[subst $counter]*" "*[subst $counter]*+*" ] \
     -sigma "SigFPH+$counter" SIGFPHp  {}

   CreateLabinLine line \
    "Choose amplitude (FPH-n) and sigma (SIGFPH-n) for wavelength $counter" \
     MTZIN "FPH-$counter" FPHm  [list FPH-$counter \
                "*-*[subst $counter]*" "*[subst $counter]*-*" ] \
     -sigma "SigFPH-$counter" SIGFPHm  {}

}

#---------------------------------------------------------------------
proc prephadata_dano_labin { arrayname counter } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

   CreateLabinLine line \
     "Choose FPH(n) and  SIGFPH(n) for wavelength $counter" \
     MTZIN "FPH$counter" FPH  [list FPH$counter ] \
     -sigma "SigFPH$counter" SIGFPH  {}

   CreateLabinLine line \
     "Choose DPH(n) and  SIGDPH(n) for wavelength $counter" \
     MTZIN "DPH$counter" DPH  [list DPH$counter ] \
     -sigma "SigDPH$counter" SIGDPH  {}

}


# two equivalent procedures prephadata_anom_wavelengths/prephadata_dano_wavelengths 
# so have two diferent dependent frames for the two case MADFS and MADDS input

#---------------------------------------------------------------------
proc prephadata_anom_wavelengths { arrayname counter } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  CreateLine line \
    message "Enter wavelength dataset $counter collected at (Revise WAVE)" \
    label "Data set $counter collected at wavelength"  \
    widget LAMBDA \
    label "with estimated F'" \
    message"Enter the F' and F'' for this wavelength (WAVE FPR FDP)"\
    widget FPRIME -oblig \
    label "and F''" \
    widget FDPRIME -oblig

}

#---------------------------------------------------------------------
proc prephadata_dano_wavelengths { arrayname counter } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  CreateLine line \
    message "Enter wavelength dataset $counter collected at (Revise WAVE)" \
    label "Data set $counter collected at wavelength"  \
    widget LAMBDA \
    label "with estimated F'" \
    message"Enter the F' and F'' for this wavelength (WAVE FPR FDP)"\
    widget FPRIME -oblig \
    label "and F''" \
    widget FDPRIME -oblig

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
proc  prephadata_update_revise_input { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [StringSame [GetValue $arrayname REVISE_INPUT] SADFS SADDS ] } {
    set array(ECALC_EXCLUDE_CENTRIC) 1
  } else {
    set array(ECALC_EXCLUDE_CENTRIC) 0
  }
}

#-----------------------------------------------------------------------
proc  prephadata_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname \
	"Prephadata - Prepare and/or Normalise Reflection Data for Experimental Phasing Programs" "PrepHaData" \
        [ list "Anomalous Data" \
	"Exclude Data when Calculating Es" \
            "Exclude data when converting to Shelx format" ]  ] == 0 } return

  SetProgramHelpFile revise

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
    label "Input" \
    widget REVISE_INPUT  \
     -command "prephadata_update_revise_input $arrayname" \
    label "and prepare data for" \
    widget REVISE_OUTPUT


#------------------------------------------------------------------Files
  OpenFolder file 

  CreateInputFileLine line \
      "Enter input MTZ file name (MTZIN)" \
      "MTZ in" \
       MTZIN DIR_MTZIN \
       -fileout MTZOUT DIR_MTZOUT _prephadata  \
       -fileout HKLOUT DIR_HKLOUT -- \
       -setfileparam space_group_name SPACE_GROUP \
       -setfileparam resolution_min EXCLUDE_RESOLUTION_MIN \
       -setfileparam resolution_max EXCLUDE_RESOLUTION_MAX \
       -setfileparam resolution_max REVISE_RESOLUTION_MAX \
       -command "set_res_max_limit $arrayname 3.0"

  CreateLabinLine line \
    "Choose native SFs (FP) and optional sigma (SIGFP)" \
      MTZIN FP FP {} \
      -sigma SIGFP SIGFP {} \
      -toggle_display REVISE_INPUT open NATIVE

  OpenSubFrame frame -toggle_display REVISE_INPUT open SIR

  CreateLabinLine line \
    "Choose native SFs (FP) and optional sigma (SIGP)" \
     MTZIN FP FP  {} \
     -sigma SIGFP SIGFP  {}

   CreateLabinLine line \
    "Choose derivative SFs, Dano or Diso  (FPH) and optional sigma (SIGPH)" \
     MTZIN FPH ECALC_FPH  {} \
     -sigma SIGFPH ECALC_SIGFPH  {}

   CloseSubFrame

  OpenSubFrame frame -toggle_display REVISE_INPUT open SADDS

    CreateLabinLine line \
    "Choose anomalous difference Dano (DPH) and optional sigma (SIGDPH)" \
     MTZIN DPH ECALC_DPH0  {} \
     -sigma SIGDPH ECALC_SIGDPH0  {}

  CloseSubFrame

  OpenSubFrame frame -toggle_display REVISE_INPUT open SADFS

   CreateLabinLine line \
    "Choose amplitude (FPH+) and sigma (SIGFPH+)" \
     MTZIN "FPH+" FPHp0  [list FPH+ "*+*"]  \
     -sigma "SigFPH+" SIGFPHp0  {}

   CreateLabinLine line \
    "Choose amplitude (FPH-) and sigma (SIGFPH-)" \
     MTZIN "FPH-" FPHm0  [list FPH- "*-*" ] \
     -sigma "SigFPH-" SIGFPHm0  {}

  
  CloseSubFrame


  OpenSubFrame frame -toggle_display REVISE_INPUT open MADFS

  CreateExtendingFrame N_WAVELENGTHS prephadata_anom_labin \
	"Add data for another wavelength" \
	"Add another wavelength" \
	[list FPHp SIGFPHp FPHm SIGFPHm ] \
	-dependentframe prephadata_anom_wavelengths

  CloseSubFrame

  OpenSubFrame frame -toggle_display REVISE_INPUT open MADDS

  CreateExtendingFrame N_WAVELENGTHS prephadata_dano_labin \
        "Add data for another wavelength" \
        "Add another wavelength" \
        [list FPH SIGFPH DPH SIGDPH ] \
        -dependentframe prephadata_dano_wavelengths

  CloseSubFrame


  CreateOutputFileLine line \
      "Output MTZ (MTZOUT)" \
      "Output MTZ" \
      MTZOUT DIR_MTZOUT \
	-toggle_display REVISE_OUTPUT hide [list SHELX SHELXD]


  CreateOutputFileLine line \
      "Output Shelx format HKL (HKLOUT)." \
      "Output HKL" \
      HKLOUT DIR_HKLOUT \
	-toggle_display REVISE_OUTPUT open [list SHELX SHELXD]


#=PARAMETERS==========================================================

  OpenFolder 1  REVISE_INPUT open [list MADFS MADDS ] hide

  OpenSubFrame frame -toggle_display REVISE_INPUT open MADDS

  CreateExtendingFrame N_WAVELENGTHS prephadata_dano_wavelengths \
        "Input estimated wavelength" \
        " " [list LAMBDA FPRIME FDPRIME ] \
        -noaddline

  CloseSubFrame

  OpenSubFrame frame -toggle_display REVISE_INPUT open MADFS

  CreateExtendingFrame N_WAVELENGTHS prephadata_anom_wavelengths \
	"Input estimated wavelength" \
	" " [list LAMBDA FPRIME FDPRIME ] \
	-noaddline

  CloseSubFrame

  CreateLine line \
    help reso \
    message "Use high resolution cutoff? (RESO)" \
    widget USE_REVISE_RESO_CUTOFF \
    label "Exclude reflections with resolution higher than" \
    message "High resolution cutoff (Angstroms) for Revise (RESO)" \
    widget REVISE_RESOLUTION_MAX \
    label "A"

  CreateLine line \
    message "Exclude data which has DISO or FPH > Riso (EXCL RISO)" \
    label "Exclude data Diso/FPH >" \
    help EXCL \
    widget RISO \
    message "Exclude data which has DANO or FPH > Rano (EXCL RANO)"  \
    label "or Dano/FPH >" \
    widget RANO \
    message "Exclude data which has SIGFPH or FPH < sigm (EXCL SIGM)"  \
    label "or FPH/SIGFPH <" \
    widget SIGM

  
#----------------------------------------------exclude data

  OpenFolder 2 REVISE_OUTPUT close [list RANTAN] hide

  SetProgramHelpFile ecalc

  CreateLine line \
    message "Exclude data when using Ecalc to calculate Es" \
    help exclude \
    label "Exclude data with FP <" \
    widget ECALC_EXCLUDE_SIGP \
    label "*SigFP    or FPH <" \
    widget ECALC_EXCLUDE_SIGPH \
    label "*SigFPH   or FP-FPH >" \
    widget ECALC_EXCLUDE_DIFF

  CreateLine line \
    message "Exclude data when using Ecalc to calculate Es" \
    help exclude \
    widget EXCLUDE_RESOLUTION \
    label "Exclude reflections with resolution higher than" \
    message "High resolution cutoff (Angstroms) for Ecalc (RESO)" \
    widget EXCLUDE_RESOLUTION_MAX \
    label "A" \
    toggle_display REVISE_INPUT open [ list SADFS SADDS SIR ]

  CreateLine line \
    message "Exclude centric data when calculating Es from anomalous differences" \
    help exclude \
    widget ECALC_EXCLUDE_CENTRIC \
    label "Exclude all centric reflections" \
    toggle_display REVISE_INPUT open [ list SADFS SADDS ]

#--------------------------------------------------mtz2various exclude

  OpenFolder 3 REVISE_OUTPUT close [list SHELX SHELXD] hide

  source [SearchPath TOP tasks mtz2var_exclude.tcl ]

}

