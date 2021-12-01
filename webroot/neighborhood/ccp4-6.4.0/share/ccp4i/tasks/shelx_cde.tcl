#
#     Copyright (C) 2004-5  CCLRC, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
# ======================================================================
# shelx_cde.tcl --
#
# Run shelxc,d,e programs for heavy atom location and phasing
#
# CCP4Interface 
#
# =======================================================================

#------------------------------------------------------------------------
proc shelx_cde_prereq { } {
#------------------------------------------------------------------------
# Check that Shelx executables are available
  # Shelxc
  if { ![file exists [FindExecutable shelxc]] } {
    return 0
  }
  # Shelxd
  if { ![file exists [FindExecutable shelxd]] } {
    return 0
  }
  # Shelxe
  if { ![file exists [FindExecutable shelxe]] } {
    return 0
  }
  return 1
}

#------------------------------------------------------------------------------
proc shelx_cde_setup { typedefVar arrayname } {
#------------------------------------------------------------------------------
  upvar \#0 $typedefVar typedef
  upvar \#0 $arrayname array

  # Look for the executables required for this interface
  set missing {}
  foreach prog [list shelxc shelxd shelxe] {
      if { ![file exists [FindExecutable $prog]] } {
	  lappend missing $prog
      }
  }
  if { [llength $missing] > 0 } {
      WarningMessage "The following programs are missing from your path:

$missing

These are required by this interface, and attempting
to run this task without them may cause problems."
  }

  # Set up interface-specific types
  DefineMenu _shelx_cde_expt_type [list "MAD" "SAD" "SIR" "SIRAS" ] \
      [list MAD SAD SIR SIRA]

  DefineMenu _shelx_cde_input_format [list MTZ Scalepack] [list MTZ SCA]

  DefineMenu _shelx_cde_mtz_input [list "intensities" "structure factors"] \
      [list INTENSITIES SFS]

  DefineMenu _shelx_cde_native_type [list "averages" \
					 "Friedel pairs" ] \
      [list AVERAGE FRIEDEL]

  DefineMenu _shelx_cde_enantiomorph \
      [list "original enantiomorph" \
           "inverted enantiomorph" \
	   "both enantiomorphs"] \
  [list ORIGINAL INVERTED BOTH]

  DefineMenu _shelxe_output_format [list "XtalView" "MTZ"] \
      [list PHS MTZ]

  set typedef(_shelx_cde_dataset) \
      [list varmenu DATASET_MENU DATASET_ALIAS 10]

  # Patch: general type _hkl_file used for output files sets extention ".hkl,.HKL,.sca", but we want to be more specific
  set typedef(_shelx_hkl_file)          { file HKL ".hkl"  "Shelx hkl-file" "" "" }

  # Set an internal/local variable to ensure that the warning
  # about running SHELXD without SHELXC is only displayed once
  set array(shelx_cde_no_shelxc_warning) 1

  return 1
}

#------------------------------------------------------------------------------
proc autotrace_available_setup {} {
#------------------------------------------------------------------------------
  catch { exec [BinPath shelxe] } shelxe_stdoe
  set shelxe_info [split $shelxe_stdoe]
  if { [set k [lsearch -exact $shelxe_info Version]] > -1 } {
    set shelxe_version [split [lindex $shelxe_info [expr $k + 1]] /]
    if { [llength $shelxe_version] == 2 } {
      set shelxe_year [lindex $shelxe_version 0]
      set shelxe_month [lindex $shelxe_version 1]
      if { [string is integer $shelxe_year] &&  [string is integer $shelxe_year] } {
        if { $shelxe_year > 2009 } {
          return 1
        }
      }
    }
  }
  return 0
}

#------------------------------------------------------------------------------
proc shelx_cde_run { arrayname } {
#------------------------------------------------------------------------------
  upvar \#0 $arrayname array
  global configure

  # Set the name of the spacegroup to use for SHELX run
  set array(SHELX_SPACE_GROUP) \
      [shelx_cde_GetShelxSpaceGroup $array(SPACE_GROUP)]

  # Check some critical parameters
  if { $array(RUN_SHELXE) } {
    # Solvent content
    if { ![shelx_cde_check_solvent_content $array(SOLVENT_CONTENT)] } {
       WarningMessage "You haven't set a valid value for
the solvent content used in the refinement
and phasing step (SHELXE).

Please set a valid value before rerunning
this task."
       return 0
    }
    # Lookup the inverted spacegroup
    if { ![ GetChangeHandData $array(SHELX_SPACE_GROUP) \
       array(INVERTED_SPACE_GROUP) cx ] } {
       WarningMessage "Couldn't get information for the inverted
enantiomorph spacegroup

This task may fail to complete if SHELXE
converts to the inverted spacegroup"
    } else {
      # If there is no inverted hand then the returned spacegroup
      # will be a blank
      if { [string trim $array(INVERTED_SPACE_GROUP)] == "" } {
        set array(INVERTED_SPACE_GROUP) $array(SHELX_SPACE_GROUP)
      }
      set array(INVERTED_SPACE_GROUP) \
	 [shelx_cde_GetShelxSpaceGroup [GetSpaceGroupStdCode \
	 $array(INVERTED_SPACE_GROUP)]]
    }
  }

  # Check there is a valid resolution range for shelxd
  if { $array(RUN_SHELXD) } {
     if { $array(RUN_SHELXC) && ! $array(USE_SHELXC_RESO) } {
       if { $array(MIN_RESO) == "" || $array(MAX_RESO) == "" } {
         WarningMessage "You haven't set a value for
either the maximum or the minimum resolution
(or both) to be used in the SHELXD run.

Please set appropriate values before rerunning."
         return 0
       }
     }
  }

  # Initialise input/output file lists
  set array(INPUT_FILES) ""
  set array(OUTPUT_FILES) ""

  #============================================================
  # Set up input file list
  #============================================================

  # Input for SHELXC step
  if { [StringSame $array(SHELX_START) SHELXC] } {
    # Scalepack input
    if { [GetValue $arrayname SHELXC_INPUT_FORMAT] == "SCA" } {
      if { [GetValue $arrayname SHELXC_EXPT] == "MAD" } {
        # For MAD we need at least two wavelengths
        # Only one of which must be PEAK or INFL
        set nfiles 0 ; set got_compulsory 0
        if { $array(SCALIN_PEAK) != "" } {
          append array(INPUT_FILES) " SCALIN_PEAK"
          incr nfiles ; set got_compulsory 1
        }
        if { $array(SCALIN_INFL) != "" } {
          append array(INPUT_FILES) " SCALIN_INFL"
          incr nfiles ; set got_compulsory 1
        }
        if { $array(SCALIN_LREM) != "" } {
          append array(INPUT_FILES) " SCALIN_LREM"
          incr nfiles
        }
        if { $array(SCALIN_HREM) != "" } {
          append array(INPUT_FILES) " SCALIN_HREM"
          incr nfiles
        }
        if { $array(SCALIN_NAT) != "" } {
          append array(INPUT_FILES) " SCALIN_NAT"
        }
        # Abort if we don't have enough to run with
        if { $nfiles < 2 } {
          WarningMessage "You haven't supplied enough wavelengths
to run a MAD experiment.

You need at least two wavelengths, one of which
must be either the peak or the inflection point data."
          return 0
        }
        # Abort if we don't have at least the peak or inflection
        if { ! $got_compulsory } {
          WarningMessage "At least one of your input files
must be the peak or the inflection point data
to run a MAD experiment"
          return 0
        } 
      } elseif { [GetValue $arrayname SHELXC_EXPT] == "SAD" } {
        # For SAD only need a single wavelength
        append array(INPUT_FILES) "SCALIN_HA"
        # Assume that we could also have a native
        if { $array(SCALIN_NAT) != "" } {
          append array(INPUT_FILES) " SCALIN_NAT"
        }
      } else {
        # For all other experiments (SIR, SIRAS)
        append array(INPUT_FILES) "SCALIN_NAT SCALIN_HA"
      }
    }
    # MTZ input
    if { [GetValue $arrayname SHELXC_INPUT_FORMAT] == "MTZ" } {
      append array(INPUT_FILES) "HKLIN"
      # Check that the native data is assigned
      if { $array(USE_NATIVE) && \
           [StringSame [GetValue $arrayname NATIVE_TYPE] "AVERAGE"] } {
        if { [StringSame [GetValue $arrayname FMEAN] "Unassigned"] || \
             [StringSame [GetValue $arrayname SIGFMEAN] "Unassigned"] } {
           WarningMessage "You need to assign MTZ columns for
the native data, or uncheck the
option to enter native data."
           return 0
        }
      } elseif { $array(USE_NATIVE) && \
           [StringSame [GetValue $arrayname NATIVE_TYPE] "FRIEDEL"] } {
        if { [StringSame [GetValue $arrayname Fp] "Unassigned"] || \
             [StringSame [GetValue $arrayname SIGFp] "Unassigned"] || \
             [StringSame [GetValue $arrayname Fm] "Unassigned"] || \
             [StringSame [GetValue $arrayname SIGFm] "Unassigned"] } {
           WarningMessage "You need to assign MTZ columns for
the native data, or uncheck the
option to enter native data."
           return 0
        }
      }
    }
  }

  # Input for SHELXD step
  if { [StringSame $array(SHELX_START) SHELXD] } {
    append array(INPUT_FILES) "SHELXD_INS SHELXD_FA"
  }

  # Input for SHELXE step
  if { [StringSame $array(SHELX_START) SHELXE] } {
    append array(INPUT_FILES) "SHELXE_NAT SHELXE_FA SHELXE_RES"
  }

  #============================================================
  # Set up output file list
  #============================================================
  if { $array(RUN_SHELXC) } {
    append array(OUTPUT_FILES) " HKL_NATIVE HKL_FA"
  }
  if { $array(RUN_SHELXD) } {
    append array(OUTPUT_FILES) " XYZOUT"
  }
  if { $array(RUN_SHELXE) } {
    if { [StringSame [GetValue $arrayname SHELXE_OUTPUT_FORMAT] PHS] } {
      if { [StringSame [GetValue $arrayname ENANTIOMORPH] ORIGINAL BOTH] } {
        append array(OUTPUT_FILES) " PHSOUT"
      }
      if { [StringSame [GetValue $arrayname ENANTIOMORPH] INVERTED BOTH] } {
        append array(OUTPUT_FILES) " PHSIOUT"
      }
    } else {
      if { [StringSame [GetValue $arrayname ENANTIOMORPH] ORIGINAL BOTH] } {
        append array(OUTPUT_FILES) " HKLOUT"
      }
      if { [StringSame [GetValue $arrayname ENANTIOMORPH] INVERTED BOTH] } {
        append array(OUTPUT_FILES) " HKLOUT_INV"
      }
    }
    if { $array(AUTOTRACE_AVAILABLE) && $array(AUTOTRACE) } {
      if { [StringSame [GetValue $arrayname ENANTIOMORPH] ORIGINAL BOTH] } {
        append array(OUTPUT_FILES) " MCOUT"
      }
      if { [StringSame [GetValue $arrayname ENANTIOMORPH] INVERTED BOTH] } {
        append array(OUTPUT_FILES) " MCIOUT"
      }
    }
  }

  #============================================================
  # Warn about running SHELXD without SHELXC
  #============================================================
  if { $array(RUN_SHELXD) && ! $array(RUN_SHELXC) } {
    if { $array(shelx_cde_no_shelxc_warning) } {
      WarningMessage "You have choosen to run SHELXD without
running SHELXC as part of this job.

Changing the SHELXD inputs without rerunning
SHELXC may result in some differences in the
final output.

See the documentation for this task for more
information."
      set array(shelx_cde_no_shelxc_warning) 0
    }
  }

  return 1
}


#-----------------------------------------------------------------------
proc shelx_cde_task_window { arrayname } {
#-----------------------------------------------------------------------
  upvar \#0 $arrayname array
  global configure

  if { [CreateTaskWindow $arrayname  \
	"Run Shelx C, D and E for Heavy Atom Search and Phasing" "ShelxC/D/E" \
	[ list "Cell Parameters and Spacegroup" \
               "Heavy Atom Search Parameters" \
               "Phasing and Density Modification" ] ] == 0 } return
  SetProgramHelpFile "shelx"

  WriteCredits [list "George Sheldrick"] \
     -label "Shelx Author" \
     -link "Please obtain the Shelx programs from http://www.shelx.de" \
           "http://www.shelx.de"

  # Check if autotrace is available in SHELXE
  set array(AUTOTRACE_AVAILABLE) [autotrace_available_setup]
  # puts "AUTOTRACE, AUTOTRACE_OLD, AUTOTRACE_AVAILABLE: $array(AUTOTRACE) $array(AUTOTRACE_OLD) $array(AUTOTRACE_AVAILABLE)"

#=PROTOCOL==============================================================

  OpenFolder protocol

  CreateTitleLine line TITLE

  CreateLine line \
     message "Set up the protocol for running the SHELX programs" \
     widget RUN_SHELXC -command "shelx_cde_set_starting_step $arrayname" \
     label "Run SHELXC to prepare FA data from a" \
     widget SHELXC_EXPT -command "shelx_cde_HAinNative $arrayname ; shelx_cde_cell_info $arrayname" \
     label "experiment using data in" \
     message "Format of the input reflection data for SHELXC" \
     widget SHELXC_INPUT_FORMAT -command "shelx_cde_cell_info $arrayname" \
     label "format"

  CreateLine line \
     message "Set up the protocol for running the SHELX programs" \
     widget RUN_SHELXD -command "shelx_cde_set_starting_step $arrayname" \
     label "Run SHELXD to search for heavy atoms"

  CreateLine line \
     message "Set up the protocol for running the SHELX programs" \
     widget RUN_SHELXE -command "shelx_cde_set_starting_step $arrayname" \
     label "Run SHELXE to perform phasing and density modification" \
     toggle_display AUTOTRACE_AVAILABLE open { 0 }

  CreateLine line \
     message "Set up the protocol for running the SHELX programs" \
     widget RUN_SHELXE -command "run_shelxe_pressed $arrayname" \
     label "Run SHELXE to perform phasing, density modification" \
     widget AUTOTRACE -command "autotrace_pressed $arrayname" \
     label "and main chain autotracing" \
     toggle_display AUTOTRACE_AVAILABLE open { 1 }

  CreateLine line \
     label "     Phase using a solvent fraction of" \
     widget SOLVENT_CONTENT -oblig \
     label "and" \
     widget ENANTIOMORPH \
     label "of the heavy atom substructure" \
     toggle_display RUN_SHELXE open { 1 }

#=FILES================================================================

  OpenFolder file

# Input files

  CreateLine line \
     label "Input files" -italic
  $line configure -background $configure(COLOUR_PALE)
  $line.l1 configure -background $configure(COLOUR_PALE)

  CreateLine line \
     label "No protocol selected" -italic \
     toggle_display SHELX_START open NONE

  #============================================================
  # Input files for SHELXC step
  #============================================================
  OpenSubFrame frame -toggle_display SHELX_START open SHELXC

  # MTZ input format
  OpenSubFrame frame -toggle_display SHELXC_INPUT_FORMAT open MTZ

     CreateInputFileLine line \
         "Enter input MTZ file name" \
         "MTZ input" \
         HKLIN DIR_HKLIN \
         -setfileparam cell_1 CELL_1 \
         -setfileparam cell_2 CELL_2 \
         -setfileparam cell_3 CELL_3 \
         -setfileparam cell_4 CELL_4 \
         -setfileparam cell_5 CELL_5 \
         -setfileparam cell_6 CELL_6 \
         -setfileparam resolution_max MAX_RESO \
         -setfileparam resolution_min MIN_RESO \
         -setfileparam space_group_name SPACE_GROUP \
         -fileout HKL_NATIVE DIR_HKL_NATIVE _shelx_nat \
         -fileout HKL_FA DIR_HKL_FA _shelx_fa \
         -fileout XYZOUT DIR_XYZOUT _shelx \
         -fileout HKLOUT DIR_HKLOUT _shelx_phs \
         -fileout HKLOUT_INV DIR_HKLOUT_INV _shelx_phs_i \
         -fileout PHSOUT DIR_PHSOUT _shelx \
         -fileout PHSIOUT DIR_PHSIOUT _shelx_i \
         -fileout MCOUT DIR_MCOUT _shelx_mc \
         -fileout MCIOUT DIR_MCIOUT _shelx_mc_i \
         -command "shelx_cde_cell_info $arrayname"

     CreateLine line \
         label "Input is in the form of" \
         widget SHELXC_MTZ_INPUT \
         -command "shelx_cde_cell_info $arrayname"

     OpenSubFrame frame -toggle_display USE_NATIVE open 1

     CreateLine line \
        widget USE_NATIVE \
        -command "shelx_cde_display_native $arrayname ; shelx_cde_cell_info $arrayname" \
        label "Use native data in the form of" \
        widget NATIVE_TYPE \
        -command "shelx_cde_display_native $arrayname ; shelx_cde_cell_info $arrayname" \
        toggle_display SHELXC_EXPT open { MAD SAD }

     CloseSubFrame

     OpenSubFrame frame -toggle_display USE_NATIVE open 0

     CreateLine line \
        widget USE_NATIVE \
        -command "shelx_cde_display_native $arrayname ; shelx_cde_cell_info $arrayname" \
        label "Use native data" \
        toggle_display SHELXC_EXPT open { MAD SAD }

     CloseSubFrame

     CreateLine line \
        label "Native data is in the form of" \
        widget NATIVE_TYPE \
        -command "shelx_cde_display_native $arrayname ; shelx_cde_cell_info $arrayname" \
        toggle_display SHELXC_EXPT hide { MAD SAD }

     ##############################################
     # MTZ INTENSITIES
     ##############################################

     OpenSubFrame frame -toggle_display SHELXC_MTZ_INPUT open INTENSITIES

     # Native intensities

     OpenSubFrame frame -toggle_display DISPLAY_NATIVE open YES

     # Friedel pairs
     CreateLabinLine4 line \
         "Native intensities I(+) and I(-), and sigmas" \
      HKLIN "Nat I(+)" Ip [list I(+)] \
      -sigma "SigI(+)" SIGIp {} \
      -dependent "Nat I(-)" Im [list I(-)] \
      -sigma "SigI(-)" SIGIm {} \
      -toggle_display NATIVE_TYPE open { FRIEDEL } \
      -command "shelx_cde_cell_info $arrayname"

      # Average intensities
     CreateLabinLine line \
         "Average native intensities and sigmas I/sigI" \
      HKLIN "Native I" IMEAN [list I] \
      -sigma "SigI" SIGIMEAN {} \
      -toggle_display NATIVE_TYPE open { AVERAGE } \
      -command "shelx_cde_cell_info $arrayname"

    CloseSubFrame

     # HA intensities
     CreateLabinLine4 line \
         "Heavy atom intensities I(+) and I(-), and sigmas" \
      HKLIN "HA I(+)" IHAp [list I(+)] \
      -sigma "SigI(+)" SIGIHAp {} \
      -dependent "HA I(-)" IHAm [list I(-)] \
      -sigma "SigI(-)" SIGIHAm {} \
      -toggle_display SHELXC_EXPT open { SAD SIR SIRAS } \
      -command "shelx_cde_cell_info $arrayname"

     # MAD intensities (peak, inflection, L & H energy remote)
     CreateLabinLine4 line \
         "Peak intensities I(+) and I(-), and sigmas" \
      HKLIN "Peak I(+)" IPEAKp [list I(+)] \
      -sigma "SigI(+)" SIGIPEAKp {} \
      -dependent "Peak I(-)" IPEAKm [list I(-)] \
      -sigma "SigI(-)" SIGIPEAKm {} \
      -toggle_display SHELXC_EXPT open MAD \
      -command "shelx_cde_cell_info $arrayname"

     CreateLabinLine4 line \
         "Inflection point intensities I(+) and I(-), and sigmas" \
      HKLIN "Infl I(+)" IINFLp [list I(+)] \
      -sigma "SigI(+)" SIGIINFLp {} \
      -dependent "Infl I(-)" IINFLm [list I(-)] \
      -sigma "SigI(-)" SIGIINFLm {} \
      -toggle_display SHELXC_EXPT open MAD \
      -command "shelx_cde_cell_info $arrayname"

     CreateLabinLine4 line \
         "High energy remote intensities I(+) and I(-), and sigmas" \
      HKLIN "HRem I(+)" IHREMp [list I(+)] \
      -sigma "SigI(+)" SIGIHREMp {} \
      -dependent  "HRem I(-)" IHREMm [list I(-)] \
      -sigma "SigI(-)" SIGIHREMm {} \
      -toggle_display SHELXC_EXPT open MAD \
      -command "shelx_cde_cell_info $arrayname"

     CreateLabinLine4 line \
         "Low energy remote intensities I(+) and I(-), and sigmas" \
      HKLIN "LRem I(+)" ILREMp [list I(+)] \
      -sigma "SigI(+)" SIGILREMp {} \
      -dependent "LRem I(-)" ILREMm [list I(-)] \
      -sigma "SigI(-)" SIGILREMm {} \
      -toggle_display SHELXC_EXPT open MAD \
      -command "shelx_cde_cell_info $arrayname"

     CloseSubFrame

     ##############################################
     # MTZ STRUCTURE FACTORS
     ##############################################

     OpenSubFrame frame -toggle_display SHELXC_MTZ_INPUT open SFS

     # Native structure factors

     OpenSubFrame frame -toggle_display DISPLAY_NATIVE open YES

     # Friedel pairs
     CreateLabinLine4 line \
         "Native structure factors F(+) and F(-) and sigmas" \
      HKLIN "Nat F(+)" Fp [list F(+)] \
      -sigma "SigF(+)" SIGFp {} \
      -dependent "Nat F(-)" Fm [list F(-)] \
      -sigma "SigF(-)" SIGFm {} \
      -toggle_display NATIVE_TYPE open { FRIEDEL } \
      -command "shelx_cde_cell_info $arrayname"

      # Average intensities
     CreateLabinLine line \
         "Average native structure factors and sigmas F/sigF" \
      HKLIN "Native F" FMEAN [list F] \
      -sigma "SigF" SIGFMEAN {} \
      -toggle_display NATIVE_TYPE open { AVERAGE } \
      -command "shelx_cde_cell_info $arrayname"

     CloseSubFrame

     # HA structure factors
     CreateLabinLine4 line \
         "Heavy atom structure factors F(+) and F(-) and sigmas" \
      HKLIN "HA F(+)" FHAp [list F(+)] \
      -sigma "SigF(+)" SIGFHAp {} \
      -dependent "HA F(-)" FHAm [list F(-)] \
      -sigma "SigF(-)" SIGFHAm {} \
      -toggle_display SHELXC_EXPT open { SAD SIR SIRAS }  \
      -command "shelx_cde_cell_info $arrayname"

     # MAD structure factors (peak, inflection, L & H energy remote)
     CreateLabinLine4 line \
         "Peak structure factors F(+) and F(-) and sigmas" \
      HKLIN "Peak F(+)" FPEAKp [list F(+)] \
      -sigma "SigF(+)" SIGFPEAKp {} \
      -dependent "Peak F(-)" FPEAKm [list F(-)] \
      -sigma "SigF(-)" SIGFPEAKm {} \
      -toggle_display SHELXC_EXPT open MAD \
      -command "shelx_cde_cell_info $arrayname"

     CreateLabinLine4 line \
         "Inflection point structure factors F(+) and F(-) and sigmas" \
      HKLIN "Infl F(+)" FINFLp [list F(+)] \
      -sigma "SigF(+)" SIGFINFLp {} \
      -dependent "Infl F(-)" FINFLm [list F(-)] \
      -sigma "SigF(-)" SIGFINFLm {} \
      -toggle_display SHELXC_EXPT open MAD \
      -command "shelx_cde_cell_info $arrayname"

     CreateLabinLine4 line \
         "High energy remote structure factors F(+) and F(-) and sigmas" \
      HKLIN "HRem F(+)" FHREMp [list F(+)] \
      -sigma "SigF(+)" SIGFHREMp {} \
      -dependent "HRem F(-)" FHREMm [list F(-)] \
      -sigma "SigF(-)" SIGFHREMm {} \
      -toggle_display SHELXC_EXPT open MAD \
      -command "shelx_cde_cell_info $arrayname"

     CreateLabinLine4 line \
         "Low energy remote structure factors F(+) and F(-) and sigmas" \
      HKLIN "LRem F(+)" FLREMp [list F(+)] \
      -sigma "SigF(+)" SIGFLREMp {} \
      -dependent "LRem F(-)" FLREMm [list F(-)] \
      -sigma "SigF(-)" SIGFLREMm {} \
      -toggle_display SHELXC_EXPT open MAD \
      -command "shelx_cde_cell_info $arrayname"

     CloseSubFrame

  CloseSubFrame

  # Scalepack input format
  OpenSubFrame frame -toggle_display SHELXC_INPUT_FORMAT open SCA

     # Native data
     CreateInputFileLine line \
         "Enter SCALEPACK file containing native data" \
         "Native" SCALIN_NAT DIR_SCALIN_NAT \
         -command "shelx_cde_read_scalepack_header $arrayname SCALIN_NAT ; shelx_cde_cell_info $arrayname" \
         -fileout HKL_NATIVE DIR_HKL_NATIVE _shelx_nat \
         -fileout HKL_FA DIR_HKL_FA _shelx_fa \
         -fileout XYZOUT DIR_XYZOUT _shelx \
         -fileout HKLOUT DIR_HKLOUT _shelx_phs \
         -fileout HKLOUT_INV DIR_HKLOUT_INV _shelx_phs_i \
         -fileout PHSOUT DIR_PHSOUT _shelx \
         -fileout PHSIOUT DIR_PHSIOUT _shelx_i

     # HA data
     CreateInputFileLine line \
         "Enter SCALEPACK file containing heavy atom data" \
         "HA data" SCALIN_HA DIR_SCALIN_HA \
      -toggle_display SHELXC_EXPT open { SAD SIR SIRAS } \
      -command "shelx_cde_read_scalepack_header $arrayname SCALIN_HA ; shelx_cde_cell_info $arrayname" \
      -fileout HKL_NATIVE DIR_HKL_NATIVE _shelx_nat \
      -fileout HKL_FA DIR_HKL_FA _shelx_fa \
      -fileout XYZOUT DIR_XYZOUT _shelx \
      -fileout HKLOUT DIR_HKLOUT _shelx_phs \
      -fileout HKLOUT_INV DIR_HKLOUT_INV _shelx_phs_i \
      -fileout PHSOUT DIR_PHSOUT _shelx \
      -fileout PHSIOUT DIR_PHSIOUT _shelx_i

     # MAD data
     CreateInputFileLine line \
         "Enter SCALEPACK file containing peak wavelength data" \
         "Peak data" SCALIN_PEAK DIR_SCALIN_PEAK \
      -toggle_display SHELXC_EXPT open MAD \
      -command "shelx_cde_read_scalepack_header $arrayname SCALIN_PEAK ; shelx_cde_cell_info $arrayname" \
      -fileout HKL_NATIVE DIR_HKL_NATIVE _shelx_nat \
      -fileout HKL_FA DIR_HKL_FA _shelx_fa \
      -fileout XYZOUT DIR_XYZOUT _shelx \
      -fileout HKLOUT DIR_HKLOUT _shelx_phs \
      -fileout HKLOUT_INV DIR_HKLOUT_INV _shelx_phs_i \
      -fileout PHSOUT DIR_PHSOUT _shelx \
      -fileout PHSIOUT DIR_PHSIOUT _shelx_i

     CreateInputFileLine line \
         "Enter SCALEPACK file containing inflection point data" \
         "Inflection" SCALIN_INFL DIR_SCALIN_INFL \
      -toggle_display SHELXC_EXPT open MAD \
      -command "shelx_cde_read_scalepack_header $arrayname SCALIN_INFL ; shelx_cde_cell_info $arrayname" \
      -fileout HKL_NATIVE DIR_HKL_NATIVE _shelx_nat \
      -fileout HKL_FA DIR_HKL_FA _shelx_fa \
      -fileout XYZOUT DIR_XYZOUT _shelx \
      -fileout HKLOUT DIR_HKLOUT _shelx_phs \
      -fileout HKLOUT_INV DIR_HKLOUT_INV _shelx_phs_i \
      -fileout PHSOUT DIR_PHSOUT _shelx \
      -fileout PHSIOUT DIR_PHSIOUT _shelx_i

     CreateInputFileLine line \
         "Enter SCALEPACK file containing high energy remote data" \
         "HE Remote" SCALIN_HREM DIR_SCALIN_HREM \
      -toggle_display SHELXC_EXPT open MAD \
      -command "shelx_cde_cell_info $arrayname"

     CreateInputFileLine line \
         "Enter SCALEPACK file containing low energy remote data" \
         "LE Remote" SCALIN_LREM DIR_SCALIN_LREM \
      -toggle_display SHELXC_EXPT open MAD \
      -command "shelx_cde_cell_info $arrayname"

  CloseSubFrame

  CloseSubFrame

  #============================================================
  # Input files for SHELXD step
  #============================================================
  OpenSubFrame frame -toggle_display SHELX_START open SHELXD

     CreateInputFileLine line \
         "Enter control file (.ins) from SHELXC as input to SHELXD" \
         "Ins file" SHELXD_INS DIR_SHELXD_INS \
         -command "shelx_cde_read_shelxd_ins_file $arrayname"

     # Need the native data if also running SHELXE
     CreateInputFileLine line \
         "Enter native data file (.hkl) from SHELXC as input to SHELXE" \
         "Native" SHELXE_NAT DIR_SHELXE_NAT \
         -toggle_display RUN_SHELXE open 1

     CreateInputFileLine line \
         "Enter FA file (.hkl) from SHELXC/XPREP as input to SHELXD" \
         "FA file" SHELXD_FA DIR_SHELXD_FA

  CloseSubFrame

  #============================================================
  # Input files for SHELXE step
  #============================================================
  OpenSubFrame frame -toggle_display SHELX_START open SHELXE

     CreateInputFileLine line \
         "Enter native data file (.hkl) from SHELXC as input to SHELXE" \
         "Native" SHELXE_NAT DIR_SHELXE_NAT

     CreateInputFileLine line \
         "Enter FA file (.hkl) from SHELXC/XPREP as input to SHELXE" \
         "FA file" SHELXE_FA DIR_SHELXE_FA

     CreateInputFileLine line \
         "Enter result file (.res) from SHELXD as input to SHELXE" \
         "Result file" SHELXE_RES DIR_SHELXE_RES

  CloseSubFrame

# Output files

  CreateLine line \
     label "Output files" -italic
  $line configure -background $configure(COLOUR_PALE)
  $line.l1 configure -background $configure(COLOUR_PALE)

  CreateLine line \
     label "No protocol selected" -italic \
     toggle_display SHELX_START open NONE

  #============================================================
  # Output files for SHELXC step
  #============================================================
  OpenSubFrame frame -toggle_display RUN_SHELXC open 1

  CreateOutputFileLine line \
      "Output HKL file containing native data from SHELXC" \
      "Native HKL" \
      HKL_NATIVE DIR_HKL_NATIVE \
      -ext ".hkl"

  CreateOutputFileLine line \
      "Output HKL file containing heavy atom Fa data from SHELXC" \
      "Fa HKL" \
      HKL_FA DIR_HKL_FA

  CloseSubFrame

  #============================================================
  # Output files for SHELXD step
  #============================================================

  CreateOutputFileLine line \
      "Output PDB file with heavy atom positions from SHELXD" \
      "Ha PDB" \
      XYZOUT DIR_XYZOUT \
      -toggle_display RUN_SHELXD open { 1 }


  #============================================================
  # Output files for SHELXE step
  #============================================================
  OpenSubFrame frame -toggle_display RUN_SHELXE open { 1 }

  OpenSubFrame frame -toggle_display AUTOTRACE_AVAILABLE open { 0 }

  CreateLine line \
      label "Output results of SHELXE in" \
      widget SHELXE_OUTPUT_FORMAT \
          -command "shelx_cde_use_header $arrayname"\
      label "format"

  CloseSubFrame

  OpenSubFrame frame -toggle_display AUTOTRACE_AVAILABLE open { 1 }

  CreateLine line \
      label "Output results of SHELXE in" \
      widget SHELXE_OUTPUT_FORMAT \
          -command "shelx_cde_use_header $arrayname"\
      label "format" \
      toggle_display AUTOTRACE open { 0 }

  CreateLine line \
      label "Output results of SHELXE in" \
      widget SHELXE_OUTPUT_FORMAT \
          -command "shelx_cde_use_header $arrayname"\
      label "and PDB formats" \
      toggle_display AUTOTRACE open { 1 }

  CloseSubFrame

  # Output file format is phases (.phs)
  OpenSubFrame frame -toggle_display SHELXE_OUTPUT_FORMAT open { PHS }

  CreateOutputFileLine line \
      "Output phases file in XtalView format for the original enantiomorph" \
      "Phases (ori)" \
      PHSOUT DIR_PHSOUT \
      -toggle_display ENANTIOMORPH open { ORIGINAL BOTH }

  CreateOutputFileLine line \
      "Output phases file in XtalView format for the inverted enantiomorph" \
      "Phases (inv)" \
      PHSIOUT DIR_PHSIOUT \
      -toggle_display ENANTIOMORPH open { INVERTED BOTH }

  CloseSubFrame

  # Output file format is MTZ
  OpenSubFrame frame -toggle_display SHELXE_OUTPUT_FORMAT open { MTZ }

  CreateOutputFileLine line \
      "Output phases file in MTZ format (both enantiomorphs, if requested)" \
      "Phases (ori)" \
      HKLOUT DIR_HKLOUT \
      -toggle_display ENANTIOMORPH open { ORIGINAL BOTH }

  CreateOutputFileLine line \
      "Output phases file in MTZ format for the inverted enantiomorph" \
      "Phases (inv)" \
      HKLOUT_INV DIR_HKLOUT_INV \
      -toggle_display ENANTIOMORPH open { INVERTED BOTH }

  CloseSubFrame

  # Autotrace

  OpenSubFrame frame -toggle_display AUTOTRACE_AVAILABLE open { 1 }

  OpenSubFrame frame -toggle_display AUTOTRACE open { 1 }

  CreateOutputFileLine line \
      "Output PDB file with the results of main-chain autotracing from SHELXE" \
      "Main chain" \
      MCOUT DIR_MCOUT \
      -toggle_display ENANTIOMORPH open { ORIGINAL BOTH }

  CreateOutputFileLine line \
      "Output PDB file with the results of main-chain autotracing from SHELXE" \
      "Main chain" \
      MCIOUT DIR_MCIOUT \
      -toggle_display ENANTIOMORPH open { INVERTED BOTH }

  CloseSubFrame

  CloseSubFrame

#--------------------------------------------------------------------
# SHELXC Cell and Spacegroup
#--------------------------------------------------------------------
  OpenFolder 1 USE_HEADER open { 1 } hide

  # Frame to display when user is not running SHELXC but some
  # form of cell and spacegroup information is required from
  # the user
  OpenSubFrame frame -toggle_display RUN_SHELXC open { 0 }

  CreateLine line \
    widget USE_HEADER_FROM_MTZ \
    label "Take spacegroup and cell parameters from MTZ file"

  CreateInputFileLine line \
    "Enter name of input MTZ file to take spacegroup and cell information from" \
    "MTZ file" MTZIN DIR_MTZIN \
         -setfileparam cell_1 CELL_1 \
         -setfileparam cell_2 CELL_2 \
         -setfileparam cell_3 CELL_3 \
         -setfileparam cell_4 CELL_4 \
         -setfileparam cell_5 CELL_5 \
         -setfileparam cell_6 CELL_6 \
         -setfileparam space_group_name SPACE_GROUP \
    -toggle_display USE_HEADER_FROM_MTZ open 1

  CreateLine line \
    message "Space group name or number" \
    label "Space group" \
    widget SPACE_GROUP

  CreateLine line \
    message "Cell dimensions and angles" \
    help cell \
    label "Set cell a" \
    widget CELL_1 -width 8 -oblig \
    label "b" \
    widget CELL_2 -width 8 -oblig \
    label "c" \
    widget CELL_3 -width 8 -oblig \
    label "alpha" \
    widget CELL_4 -width 8 -oblig \
    label "beta" \
    widget CELL_5 -width 8 -oblig \
    label "gamma" \
    widget CELL_6 -width 8 -oblig
    
  CloseSubFrame

  # Frame to display when SHELXC is being run - the user can
  # choose the source of the cell information
  OpenSubFrame frame -toggle_display RUN_SHELXC open { 1 }

  CreateLine line \
    message "Space group name or number" \
    label "Space group" \
    widget SPACE_GROUP

  CreateLine line \
    label "Use the" \
    widget CELL_DATASET \
      -command "shelx_cde_update_dcell $arrayname" \
    label "cell parameters"

  CreateLine line \
    message "Cell dimensions and angles" \
    help cell \
    label "Set cell a" \
    widget CELL_1 -width 8 -oblig \
    label "b" \
    widget CELL_2 -width 8 -oblig \
    label "c" \
    widget CELL_3 -width 8 -oblig \
    label "alpha" \
    widget CELL_4 -width 8 -oblig \
    label "beta" \
    widget CELL_5 -width 8 -oblig \
    label "gamma" \
    widget CELL_6 -width 8 -oblig \
    toggle_display CELL_DATASET open { USER }

  CloseSubFrame

#--------------------------------------------------------------------
# SHELXD Heavy Atom Search Parameters
#--------------------------------------------------------------------
  OpenFolder 2 SHELX_START hide { "SHELXE" } open

  CreateLine line \
    label "Find" \
    message "Estimated number of sites (should be within 20% of the true number)" \
    widget FIND \
    label "heavy atoms of type" \
    message "Element name of heavy atom type to search for" \
    widget SFAC

  # Configure the width of the box for entering 2 character
  # element type
  $line.e4 configure -width 4

  OpenSubFrame frame -toggle_display RUN_SHELXC open 1

  CreateLine line \
    message "Take default cutoffs calculated automatically by SHELXC" \
    widget USE_SHELXC_RESO \
    label "Use resolution limits determined from SHELXC run"

  CreateLine line \
    message "Resolution cutoffs to apply to SHELXD run" \
    label "Use data from" \
    widget MIN_RESO \
    label "to" \
    widget MAX_RESO \
    label "Angstrom resolution" \
    toggle_display USE_SHELXC_RESO open 0

  CloseSubFrame

  CreateLine line \
    message "Resolution cutoffs to apply to SHELXD run" \
    label "Use data from" \
    widget MIN_RESO \
    label "to" \
    widget MAX_RESO \
    label "Angstrom resolution" \
    toggle_display RUN_SHELXC open 0

  CreateLine line \
    message "Number of attempts at finding heavy atoms in SHELXD (nb in some cases > 1000 tries may be required)" \
    label "Limit number of tries to" \
    widget NTRY

  CreateLine line \
    message "The minimum distance should depend on the type and clustering of the heavy atoms" \
    label "Minimum distance between heavy atoms" \
    widget MIND \
    label "A"

  CreateLine line \
    message "Normally atoms on special positions will be rejected by SHELXD (sets MIND ... -0.1)" \
    widget ALLOW_SPECIAL_POS \
    label "Allow for heavy atoms lying on special positions"

  CreateLine line \
    message "Uses WEED 0.3 rather than PATS keyword in SHELXD input" \
    widget USE_WEED \
    label "Use random omit instead of Patterson seeding"

#--------------------------------------------------------------------
# SHELXE Heavy Atom Search Parameters
#--------------------------------------------------------------------

  OpenFolder 3 RUN_SHELXE open { 1 } hide

  OpenSubFrame frame -toggle_display AUTOTRACE_AVAILABLE open { 0 }

  CreateLine line \
    label "Phase structure and refine density for" \
    message "Number of cycles of density modification in SHELXE" \
    widget NCYCLES \
    label "cycles"

  CloseSubFrame

  OpenSubFrame frame -toggle_display AUTOTRACE_AVAILABLE open { 1 }

  CreateLine line \
    label "Phase structure and refine density for" \
    message "Number of cycles of density modification in SHELXE" \
    widget NCYCLES \
    label "cycles" \
    toggle_display AUTOTRACE open { 0 }

  CreateLine line \
    message "Number of SHELXE main-chain autotracing cycles" \
    label "Perform" \
    widget TRACE_NCYCLES \
    label "cycles of main-chain tracing each including" \
    message "Number of density modification cycles in each tracing cycle" \
    widget NCYCLES \
    label "cycles of density modification" \
    toggle_display AUTOTRACE open { 1 }

  CloseSubFrame

  CreateLine line \
    message "This is the case for MAD and SAD data (-h option of SHELXE)" \
    widget HA_IN_NATIVE \
    label "Native structure also contains heavy atoms"

# Initialisations
  shelx_cde_set_starting_step $arrayname
  shelx_cde_display_native $arrayname
  shelx_cde_cell_info $arrayname
# autotrace_pressed $arrayname
}

#-----------------------------------------------------------------------
proc autotrace_pressed { arrayname } {
#-----------------------------------------------------------------------
  upvar \#0 $arrayname array

  set array(AUTOTRACE_OLD) $array(AUTOTRACE)
  if { $array(AUTOTRACE) == 1 } {
    set array(RUN_SHELXE) 1
  }
  return
}

#-----------------------------------------------------------------------
proc run_shelxe_pressed { arrayname } {
#-----------------------------------------------------------------------
  upvar \#0 $arrayname array

  if { $array(RUN_SHELXE) == 1 } {
    set array(AUTOTRACE) $array(AUTOTRACE_OLD)
  } else {
    set array(AUTOTRACE) 0
  }

  shelx_cde_set_starting_step $arrayname
  return
}

#-----------------------------------------------------------------------
proc shelx_cde_set_starting_step { arrayname } {
#-----------------------------------------------------------------------
# Set the value of the internal parameter SHELX_START, which indicates
# which SHELX program the user is starting with
  upvar \#0 $arrayname array

  # If ShelxC and ShelxE are selected then also select ShelxD
  if { $array(RUN_SHELXC) && $array(RUN_SHELXE) } {
    set array(RUN_SHELXD) 1
  }

  if { $array(RUN_SHELXC) == 1 } {
    set array(SHELX_START) "SHELXC"
  } elseif { $array(RUN_SHELXD) == 1 } {
    set array(SHELX_START) "SHELXD"
  } elseif { $array(RUN_SHELXE) == 1 } {
    set array(SHELX_START) "SHELXE"
  } else {
    set array(SHELX_START) "NONE"
  }

  # Check whether this affects the header information
  shelx_cde_use_header $arrayname

  return
}

#-----------------------------------------------------------------------
proc shelx_cde_use_header { arrayname } {
#-----------------------------------------------------------------------
# Set the value of the internal parameter USE_HEADER, which indicates
# that the header information (SPACE_GROUP and CELL) is required
  upvar \#0 $arrayname array

  if { $array(RUN_SHELXC) } {
    # Require header info for SHELXC run
    set array(USE_HEADER) 1
  } elseif { $array(RUN_SHELXE) && \
             [GetValue $arrayname SHELXE_OUTPUT_FORMAT] == "MTZ" } {
    set array(USE_HEADER) 1
  } else {
    set array(USE_HEADER) 0
  }
  return
}

#-----------------------------------------------------------------------
proc shelx_cde_read_shelxd_ins_file { arrayname } {
#-----------------------------------------------------------------------
# Read the ins file specified for input into SHELXD and extract
# data to update the window with
  upvar \#0 $arrayname array

  set ins_file [GetFullFileName0 $arrayname SHELXD_INS]
  if { ![file exists $ins_file] } { return 0 }

  # Read the contents of the file into memory
  if { ![ReadFile $ins_file ins_file_text -split] } {
     # Can't read the ins file
      WarningMessage "Can't read the .ins file:

$ins_file"
     return 0
  }

  # Deal with the file a line at a time
  foreach line $ins_file_text {
    if { [llength $line] > 0 } {
      set keyword [lindex $line 0]
      switch -regexp $keyword {
        ^FIND {
	  set array(FIND) [lindex $line 1]
        }
        ^NTRY {
	  set array(NTRY) [lindex $line 1]
        }
        ^SFAC {
	  set array(SFAC) [lindex $line 1]
        }
        ^SHEL {
	  set array(MIN_RESO) [lindex $line 1]
          set array(MAX_RESO) [lindex $line 2]
        }
        ^MIND {
	  set array(MIND) [expr -1.0 * [lindex $line 1]]
	  if { [llength $line] == 3 } {
	    set array(ALLOW_SPECIAL_POS) 1
	  } else {
	    set array(ALLOW_SPECIAL_POS) 0
	  }
	}
      }
    }
    # Finished with the line
  }

  # Tidy up
  unset ins_file_text
  return 1
}

#-----------------------------------------------------------------------
proc shelx_cde_check_solvent_content { solc } {
#-----------------------------------------------------------------------
# Test whether the solvent content is a valid number (positive fraction)
# Return 1 if it's valid and 0 otherwise
    if { [string trim $solc] == "" } {
	return 0
    } elseif { ![string is double $solc] } {
	return 0
    } elseif { $solc < 0 } {
	return 0
    }
    # Passed the tests
    return 1
}
#----------------------------------------------------------------------
proc shelx_cde_read_scalepack_header { arrayname hklin_sca { cellnam "CELL_" } } {
#----------------------------------------------------------------------
# This procedure was originally taken from import_scaled.tcl
# "cellnam" is the basename to be used for the six cell parameters to assign
# the extracted values to. The names are then $cellnam1, $cellnam2 etc.
# If the basename isn't supplied then the default values CELL_1, CELL_2 etc
# are used

  upvar #0 $arrayname array

  # Read the 3rd line of the scalepack file to get cell and perhaps spacegroup
  # Warning: maybe there is no header?
  # We need to check that the extracted values are sensible

  set filename [GetFullFileName0 $arrayname $hklin_sca]

  if { [file exists $filename]  && [OpenFile $filename f r ] } { 

    for { set n 1 } { $n <= 3 } { incr n } { catch "gets $f line" }
    if { [llength $line] >= 6 } {
      set ii -1; for { set i 1 } { $i <= 6 } { incr i } { incr ii
	set cell($i) [lindex $line $ii]
      }
      if { [llength $line] >= 7 } { 
	set space_group [lindex $line 6] 
      }
    }

    CloseFile $f

  } else {

    return 0

}

  # Check if the information read in makes sense
  set cell_ok 1
  for { set i 1 } { $i <= 6 } { incr i } {
      # Cell parameters must be positive and non-zero
      if { ![info exists cell($i) ] } {
	  set cell_ok 0
      } elseif { $cell($i) <= 0 } {
	  set cell_ok 0
      }
  }
  # Only load the parameters if the cell checks out as reasonable
  if { $cell_ok } {
      for { set i 1 } { $i <= 6 } { incr i } {
	  set array([subst $cellnam]$i) $cell($i)
      }
      if { [info exists space_group] } { set array(SPACE_GROUP) $space_group }
  }

  return $cell_ok
}

#-----------------------------------------------------------------------
proc shelx_cde_HAinNative { arrayname } {
#-----------------------------------------------------------------------
# Set the default for the logical variable HA_IN_NATIVE, which indicates
# whether the "native" data also contains the heavy atoms
# Eleanor Dodson suggests that this should be on by default for MAD and
# SAD experiments, and off by default for SIR and SIRAS

  upvar \#0 $arrayname array
  set expt_type [GetValue $arrayname SHELXC_EXPT]
  switch -regexp $expt_type {
      ^MAD|SAD {
	  set array(HA_IN_NATIVE) 1
      }
      ^SIR {
	  set array(HA_IN_NATIVE) 0
      }
      default {
	  WarningMessage "Unknown experiment type \"$expt_type\"

Please report this error to the CCP4i
developers."
      }
  }
}

#-----------------------------------------------------------------------
proc shelx_cde_GetShelxSpaceGroup { spacegp } {
#-----------------------------------------------------------------------
# Attempt to shorten a long spacegroup name
# This is the algorithm:
# 1. Convert characters to uppercase
# 2. Strip off any quotes that may have been added by CCP4i,
#    then remove each element of the name which is a single "1".
#    Otherwise, keep the element but remove the leading spaces
# So e.g. 'P 1 21 1' becomes 'P21'
# Be careful of special cases like 'P 1'
  set space_group [string toupper [string trim $spacegp "'"]]
  set result [lindex $space_group 0]
  set nele [llength $space_group]
  foreach ele [lrange $space_group 1 end] {
    if { ![regexp -- "^1\$" $ele] || $nele < 3 } {
      append result $ele
    }
  }
  return $result
}


#-----------------------------------------------------------------------
proc shelx_cde_display_native { arrayname } {
#-----------------------------------------------------------------------
# Update the value of the parameter DISPLAY_NATIVE
   upvar \#0 $arrayname array

   if { [StringSame [GetValue $arrayname SHELXC_EXPT] MAD SAD] } {
       # MAD or SAD: native is optional
       if { $array(USE_NATIVE) } {
	   set array(DISPLAY_NATIVE) "YES"
       } else {
	   set array(DISPLAY_NATIVE) "NO"
       }
   } else {
       # Native data is compulsory
       set array(DISPLAY_NATIVE) "YES"
   }
   return
}

#-----------------------------------------------------------------------
proc shelx_cde_cell_info { arrayname } {
#-----------------------------------------------------------------------
# This procedure determines what cell information is available to the
# user based on the available files, mode of operation and other options
# currently selected.
# It then updates the variable menu that is used to display the options
# to the user for them to choose (if there is a choice)
    upvar \#0 $arrayname array

    # Check the relevant parameters
    set expt   [GetValue $arrayname SHELXC_EXPT]
    set format [GetValue $arrayname SHELXC_INPUT_FORMAT] 
    set reflns [GetValue $arrayname SHELXC_MTZ_INPUT]
    set native [GetValue $arrayname USE_NATIVE]
    set native_type [GetValue $arrayname NATIVE_TYPE]

    #puts "$expt $format $reflns $native $native_type"

    # Experiment type gives list of things to check
    switch -regexp $expt {
	"^MAD\$" {
	    set inputs [list NAT PEAK INFL HREM LREM]
	}
	"^SAD|SIRA|SIR\$" {
	    set inputs [list NAT HA]
	    
	}
    }

    # Initialise list of cells acquired
    set cell_alias {}

    # Split on input file format
    if { [StringSame "SCA" $format] } {
	# Scalepack input
	foreach type $inputs {
	    set scalin "SCALIN_$type"
	    set cell "CELL_$type"
	    if { [shelx_cde_read_scalepack_header $arrayname $scalin $cell] } {
		lappend cell_alias $type
	    }
	}
    } elseif { [StringSame "MTZ" $format] } {
	# MTZ format
	foreach type $inputs {
	    if { [StringSame "INTENSITIES" $reflns] } {
		set col_label "I"
	    } else {
		set col_label "F"
	    }
	    if { ![StringSame "NAT" $type] } {
		append col_label "$type"
		append col_label "p"
	    } elseif { $native } { 
		if { $native_type == "FRIEDEL" } {
		    append col_label "p"
		} else {
		    append col_label "MEAN"
		}
	    }
	    set label [GetValue $arrayname $col_label]
	    #puts "col_label $col_label label $label"
	    set cell "CELL_$type"
	    if { [shelx_cde_get_dataset_cell $arrayname HKLIN $label $cell] } {
		lappend cell_alias $type
	    }
	}
    }

    # Build the varmenu for the possible cells
    set cell_menu {}
    foreach type $cell_alias {
	switch $type {
	    NAT {
		lappend cell_menu "native"
	    }
	    PEAK {
		lappend cell_menu "peak"
	    }
	    INFL {
		lappend cell_menu "inflection"
	    }
	    HREM {
		lappend cell_menu "high remote"
	    }
	    LREM {
		lappend cell_menu "low remote"
	    }
	    HA {
		lappend cell_menu "heavy atom"
	    }
	}
    }
    # Add the default at the end
    lappend cell_alias USER
    lappend cell_menu "user-defined"

    # Update the menu - this will automatically update everywhere that the menu
    # is displayed in the task interface
    UpdateVariableMenu $arrayname initialise 0 DATASET_MENU $cell_menu \
  	DATASET_ALIAS $cell_alias

    # Set the default value if not already set
    # The preference is to use the native, if present
    # Otherwise use another "real" dataset in preference to USER
    set current [GetValue $arrayname CELL_DATASET]
    set k 0
    if { [StringSame USER $current] } {
	# Use first entry in the list
	set k 0
    } elseif { [lsearch $cell_alias $current] < 0 } {
	# Current value is no longer in the list
	set k 0
    } else {
	# "Reset" to same value
	set k [lsearch $cell_alias $current]
    }
    # Implement the reset
    set array(CELL_DATASET) [lindex $cell_menu $k]
    shelx_cde_update_dcell $arrayname
}

#-----------------------------------------------------------------------
proc shelx_cde_get_dataset_cell { arrayname hklin label cellnam } {
#-----------------------------------------------------------------------
# Analogue of shelx_cde_read_scalepack_header
    upvar \#0 $arrayname array
    set filen [GetFullFileName0 $arrayname $hklin]
    if { ![file exists $filen] } {
	return 0
    }
    if { ![GetMtzDatasetFromLabel $filen $label xtal dataset] } {
	return 0
    }
    #puts "xtal $xtal dataset $dataset"
    for { set i 1 } { $i <= 6 } { incr i } {
	if { ![GetMtzParamFromDataset $filen $xtal $dataset DCELL_$i dcell($i)] } {
	    return 0
	}
    }
    #puts "dcell $dcell(1) $dcell(2) $dcell(3) $dcell(4) $dcell(5) $dcell(6)"
    for { set i 1 } { $i <= 6 } { incr i } {
	set array([subst $cellnam]$i) $dcell($i)
    }
    return 1
}

#-----------------------------------------------------------------------
proc shelx_cde_update_dcell { arrayname } {
#-----------------------------------------------------------------------
# When the user selects the cell for a particular dataset then this
# function should be invoked to put the new cell into the appropriate
# parameters
    upvar \#0 $arrayname array
    set source [GetValue $arrayname CELL_DATASET]
    if { [StringSame USER $source] } {
	# The values are already there
	return
    }
    # Fetch the values from storage - in parameters called
    # e.g. CELL_PEAK1 or CELL_NAT6 etc
    for { set i 1 } { $i <= 6 } { incr i } {
	set cellvar "CELL_[subst $source]$i"
	set cmd "set array(CELL_$i) \$array($cellvar)"
	eval $cmd
    }
}
