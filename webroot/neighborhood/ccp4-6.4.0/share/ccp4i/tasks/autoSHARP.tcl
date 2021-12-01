# -------------------------------------------------------------------
#
# Copyright (C) 2005-2011 by Global Phasing Limited
#
# This code is distributed under the terms and conditions of the CCP4
# Program Suite Licence Agreement as a CCP4 Application.  A copy of
# the CCP4 licence can be obtained by writing to the CCP4 Secretary,
# Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# Authors: (2005-2011) Clemens Vonrhein
#
# -------------------------------------------------------------------

#CCP4i_cvs_Id $Id$

set typedef(_RFL_file)		{ file RFL ".mtz,.sca,.hkl" "reflection data" "" "" }
set typedef(_HATOM_file)	{ file HATOM ".hatom" "hatom file" "" "" }

#--------------------------------------------------------------------

# This is called by CCP4i to check whether the necessary prerequisites
# exist on the system for this interface to run
# Returns 1 if prereqs exist, zero otherwise
proc autoSHARP_prereq { } {
    if { [GetEnvPath BDG_home 0] == "" && [GetEnvPath SHARP_home 0] == "" } {
	# No environment variable BDG_home/SHARP_home
	return 0
    } else {
	if { [GetEnvPath SHARP_home 0] != "" } {
	    set SHARP_home [GetEnvPath SHARP_home]
	    if { ! [file exists [FileJoin $SHARP_home bin sharp detect.sh] ] } {
		return 0
	    }
	} else {
	    set BDG_home [GetEnvPath BDG_home]
	    if { ! [file exists [FileJoin $BDG_home bin sharp detect.sh] ] } {
		return 0
	    }
	}
    }
    return 1
}

# procedure which is run automatically before drawing the interface
# used to set up variables, menus etc
proc autoSHARP_setup { typedefVar arrayname } {

    upvar #0 $typedefVar typedef
    upvar #0 $arrayname array

    set typedef(_RFL_file)		{ file RFL ".mtz,*.sca,*.hkl" "reflection data" "" "" }
    lappend typedef(file_types) _RFL_file
    set typedef(_HATOM_file)	        { file HATOM ".hatom" "hatom file" "" "" }
    lappend typedef(file_types) _HATOM_file

    # Define the 'autosharp_type' menu
    DefineMenu _autosharp_type [list "SAD/MAD"  "SIR(AS)/MIR(AS)" ] \
	[ list MAD MIR ] 

    # Define the 'autosharp_data_format' menu
    DefineMenu _autosharp_data_format [list "MTZ" "SCALEPACK (merged)" "SCALEPACK (unmerged)" "SHELX HKL4" "MTZ (relative scaled)"] \
	[ list MTZ SCAM SCAU HKL MTZS]

    DefineMenu _autosharp_spgr [list None P1 P2 P112 P21 I21 P1121 A2 C2 C21 P222 P2221 P21212 \
				    P21212a P21221 P22121 P212121 C2221 C2221a C222 C222a F222 F222a I222 I222a \
				    I212121 P4 P41 P42 P43 I4 I41 P422 P4212 P4122 P41212 P4222 \
				    P42212 P42212a P4322 P43212 I422 I4122 P3 P31 P32 H3 P312 P321 \
				    P3112 P3121 P3212 P3221 H32 P6 P61 P65 P62 P64 P63 P622 P6122 \
				    P6522 P6222 P6422 P6322 P23 F23 I23 I23a P213 I213 P432 P4232 \
				    F432F4132 I432 P4332 P4132 I4132] \
	[list None P1 P2 P112 P21 I21 P1121 A2 C2 C21 P222 P2221 P21212 \
	     P21212a P21221 P22121 P212121 C2221 C2221a C222 C222a F222 F222a I222 I222a \
	     I212121 P4 P41 P42 P43 I4 I41 P422 P4212 P4122 P41212 P4222 \
	     P42212 P42212a P4322 P43212 I422 I4122 P3 P31 P32 H3 P312 P321 \
	     P3112 P3121 P3212 P3221 H32 P6 P61 P65 P62 P64 P63 P622 P6122 \
	     P6522 P6222 P6422 P6322 P23 F23 I23 I23a P213 I213 P432 P4232 \
	     F432F4132 I432 P4332 P4132 I4132]

    DefineMenu _autosharp_rate [list "1 - fast" "2 - ......" "3 - ........" "4 - .........." "5 - accurate"] \
	[list 1 2 3 4 5]

    DefineMenu _autosharp_viewer [list "none" "O" "XtalView" "Coot"] [list "NONE" "O" "Xfit" "Coot"]

    DefineMenu _autosharp_entrypoint3_path [list "(1) Data analysis" "(2)  + Heavy atom detection" "(3)     + Heavy atom refinement & phasing" "(4)        + Density modification" "(5)           + Automatic model building"] \
	[list 43 53 63 73 83]
 
    DefineMenu _autosharp_detectpgm [list "SHELXD" "RANTAN"] \
	[list shelx rantan]
   return 1

}

#--------------------------------------------------------------------
# this procedure is run when user clicks the 'Run' button
# used to check user input and where necessary convert parameters
# to form required by the program run script
# proc autoSHARP_run1 { arrayname } {
#     upvar #0 $arrayname array
#     set bdg_home [ GetEnvPath BDG_home ]
#     if { ![IfSet $bdg_home] }  {
#    	WarningMessage "Environmental variable BDG_home is not set."
#    	return 0
#     }
#     if ( ![file isdirectory $bdg_home] } {
#    	WarningMessage "Environmental variable BDG_home doesn't point to a directory."
#    	return 0
#     }
#     set licence [FileJoin $BDG_home .licence ]
#     if ( ![file exists $licence] } {
#    	WarningMessage "File $licence doesn't exist."
#    	return 0
#     }
#     if ( ![file isfile $licence] } {
#    	WarningMessage "$licence is not a file."
#    	return 0
#     }
#     if ( ![file readable $licence] } {
#    	WarningMessage "File $licence is not readable."
#    	return 0
#     }
#     return 1
#}
proc autoSHARP_run { arrayname } {

    upvar #0 $arrayname array

    set sharp_home [ GetEnvPath SHARP_home ]
    if { [IfSet $sharp_home] } {
        set env(BDG_home) [GetEnvPath SHARP_home]
	set home_name "SHARP_home"
    } else {
	set home_name "BDG_home"
    }
    set bdg_home [ GetEnvPath BDG_home ]
    if { ![IfSet $bdg_home] }  {
    	WarningMessage "Environmental variable $home_name is not set."
    	return 0
    }
    if { ![file isdirectory $bdg_home] }  {
    	WarningMessage [join [list "Environmental variable $home_name (" $bdg_home ") doesn't point to a directory." ] ]
    	return 0
    }
    set licence [FileJoin $bdg_home .licence ]
    if { ![file exists $licence] } {
    	WarningMessage "File $licence doesn't exist."
    	return 0
    }
    if { ![file isfile $licence] } {
    	WarningMessage "$licence is not a file."
    	return 0
    }
    if { ![file readable $licence] } {
    	WarningMessage "File $licence is not readable."
    	return 0
    }

    return 1
}

#---------------------------------------------------------------------
proc autoSHARP_task_window { arrayname } {

    # procedure to draw task window
    upvar #0 $arrayname array

    if { [ CreateTaskWindow $arrayname "autoSHARP: automated structure solution with SHARP" "autoSHARP" \
	   [ list "General parameters" "Asymmetric Unit" "Dataset parameters" ] ] == 0 } {
	return
    }

    set bdg_help "[file join [GetEnvPath BDG_home] docs sharp manual autoSHARP2.html]"
    SetProgramHelpFile $bdg_help

    # protocol
    OpenFolder protocol

    CreateLine line \
	label "NOTE This task uses the SHARP/autoSHARP programs which are not distributed with CCP4 - see: www.globalphasing.com" -italics

    CreateLine line \
	label "NOTE The job title should be given in a format suitable to create directories from - so no space, #, / etc" -italics
    CreateTitleLine line TITLE

    CreateLine line_type \
	message "Description of autoSHARP run" \
	help "titl" \
	label "Description" \
	widget autoSHARP_titl

    CreateLine line_type \
	message "Description of autoSHARP experiment" \
	help "prepare" \
	label "Run a" \
	widget autoSHARP_type \
	label "experiment"
# with " \
	message "Number of wavelengths (SAD/MAD) or derivatives (SIR/MIR)" \
	help "prepare" \
	widget autoSHARP_nset  \
	label "wavelength(s)/derivative(s)"

    CreateLine line_format \
	message "format of input files" \
	help "prepare" \
	label "Input file(s) is/are in" \
	widget autoSHARP_data_format \
	label "format with spacegroup " \
	message "override spacegroup in files (if present) or leave at None" \
	help "symm" \
	widget autoSHARP_spgr

    CreateLine line_rate \
	message "Decide if run should be fast, accurate or a compromise of these" \
	help "prepare" \
	label "Speed vs. accurate setting of" \
	widget autoSHARP_rate

    CreateLine line_steps \
	message "Which (successive) steps to perform" \
	help "what" \
	label "Run up to (and including)" \
	widget autoSHARP_EntryPoint3_Path \
	message "Which program to use for heavy atom detection" \
	help "hatm" \
	label "using" \
	widget autoSHARP_DetectPgm \
	label "for HA detection"

    CreateLine line_viewer \
	message "Decide which viewer will be used for looking at maps/models" \
	help "viewer" \
	label "Prepare results (maps/models) for viewing with " \
	widget autoSHARP_viewer

    # general
    OpenFolder 1

    CreateLine line \
	message "Apply resolution limits" \
	help "reso" \
	widget autoSHARP_res \
	  -toggleon \
	message "Low resolution limit" \
	label "Resolution range from" \
	widget autoSHARP_resl \
	message "High resolution limit" \
	label " to " \
	widget autoSHARP_resh

    # molecular weight
    OpenFolder 2

    CreateInputFileLine line_pir \
        "PIR formatted sequence file (monomer) - this is the preferred option" \
	"Sequence (preferred)" \
	autoSHARP_pirf DIR_autoSHARP_pirf \
        -notoblig
    CreateLine line_nres \
	label "  OR :   no. of residues" \
	message "No. of residues in monomer - please use sequence file instead" \
	help "molw" \
	widget autoSHARP_nres 
    CreateLine line_mw \
	message "Molecular weight (Dalton) of monomer - please use sequence file instead" \
	help "molw" \
	label "  OR :   molecular weight" \
	widget autoSHARP_molw

    CreateLine line \
        message "Type of heavy atom" \
	help "hatm" \
        label "Atom type" \
        widget autoSHARP_hatm,0 \
        message "Number of expected sites (per monomer)" \
	help "hatm" \
        label "No. of sites" \
        widget autoSHARP_nsit,0 \
	toggle_display autoSHARP_type open [list MAD]

    CreateInputFileLine line \
	"File with known sites" \
	"hatom file" \
	autoSHARP_sitf_mad DIR_autoSHARP_sitf_mad \
	-notoblig \
	-toggle_display autoSHARP_type open [list MAD]

    # datasets
    OpenFolder 3

    CreateToggleFrame autoSHARP_nset autosharp_dataset_def \
 	"Definition of various datasets" "Dataset no." \
 	"Add another dataset" \
  	[list autoSHARP_iden autoSHARP_wave autoSHARP_hatm autoSHARP_nsit \
  	     autoSHARP_fone autoSHARP_ftwo autoSHARP_fmid \
  	     autoSHARP_smid autoSHARP_dano autoSHARP_sano autoSHARP_isym \
  	     autoSHARP_dtyp autoSHARP_data DIR_autoSHARP_data \
             autoSHARP_LABIN autoSHARP_data_mtz DIR_autoSHARP_data_mtz \
             autoSHARP_data_sca DIR_autoSHARP_data_sca autoSHARP_sitf DIR_autoSHARP_sitf]
}

#---------------------------------------------------------------------
proc autosharp_dataset_def { arrayname counter } {

    # procedure to draw dataset form
    upvar #0 $arrayname array

    set autoSHARP_type        [GetValue $arrayname autoSHARP_type]
    set autoSHARP_data_format [GetValue $arrayname autoSHARP_data_format]

    CreateLine line \
        message "Short string as identifier" \
	help "iden" \
        label "Identifier" \
        widget autoSHARP_iden \
        message "Wavelength (in Angstroem)" \
	help "wave" \
        label "Wavelength" \
        widget autoSHARP_wave \
        message "f' value for given heavy atom" \
	help "wave" \
        label "  f'  " \
        widget autoSHARP_fone \
        message "f'' value for given heavy atom" \
        label "  f''  " \
	help "wave" \
        widget autoSHARP_ftwo \
	toggle_display autoSHARP_type open [list MAD]

    if { $counter > 1 } {
	CreateLine line \
	    message "Short string as identifier" \
	    label "Identifier" \
	    widget autoSHARP_iden \
	    message "Wavelength (in Angstroem)" \
	    help "wave" \
	    label "Wavelength" \
	    widget autoSHARP_wave \
            message "f' value for given heavy atom" \
	    help "wave" \
            label "  f'  " \
            widget autoSHARP_fone \
            message "f'' value for given heavy atom" \
	    help "wave" \
            label "  f''  " \
            widget autoSHARP_ftwo \
	    message "Type of heavy atom" \
	    help "hatm" \
	    label "Atom type" \
	    widget autoSHARP_hatm \
	    message "Number of expected sites (per monomer)" \
	    help "hatm" \
	    label "No. of sites" \
	    widget autoSHARP_nsit \
	    toggle_display autoSHARP_type open [list MIR]

    } else {
	CreateLine line \
	    message "Short string as identifier (for native)" \
	    help "iden" \
	    label "Identifier" \
	    widget autoSHARP_iden \
	    toggle_display autoSHARP_type open [list MIR]
    }

    CreateInputFileLine line \
	"Input MTZ file" \
	"Datafile" \
	autoSHARP_data_mtz DIR_autoSHARP_data_mtz \
	-setfileparam space_group_name SPACE_GROUP \
	-setfileparam cell_1 CELL_1 \
	-setfileparam cell_2 CELL_2 \
	-setfileparam cell_3 CELL_3 \
	-setfileparam cell_4 CELL_4 \
	-setfileparam cell_5 CELL_5 \
	-setfileparam cell_6 CELL_6 \
	-toggle_display autoSHARP_data_format open [list MTZ MTZS]

     CreateLabinLine line \
  	"Observed amplitude (F) and sigma (SIGF)" \
 	autoSHARP_data_mtz,$counter FMID autoSHARP_fmid [list F FP autoSHARP_fmid] \
 	-sigma SMID autoSHARP_smid [list SIGF SIGFP autoSHARP_smid] \
  	-toggle_display autoSHARP_data_format open [list MTZ MTZS]

    if { $autoSHARP_type == "MAD" || $counter > 1 } {
	CreateLabinLine line \
	    "Anomalous difference (autoSHARP_dano) and sigma (SIGautoSHARP_dano)" \
	    autoSHARP_data_mtz,$counter DANO autoSHARP_dano [list autoSHARP_dano] \
	    -sigma SANO autoSHARP_sano [list SIGautoSHARP_dano autoSHARP_sano] \
	    -toggle_display autoSHARP_data_format open [list MTZ MTZS]

	CreateLabinLine line \
	    "autoSHARP_isym column" \
	    autoSHARP_data_mtz,$counter ISYM autoSHARP_isym [list autoSHARP_isym] \
	    -toggle_display autoSHARP_data_format open [list MTZ MTZS]

    }

    CreateInputFileLine line \
	"Input reflection file" \
	"Datafile" \
	autoSHARP_data_sca DIR_autoSHARP_data_sca \
	-toggle_display autoSHARP_data_format hide [list MTZ MTZS]

    CreateLine  line  \
        message "Enter cell lengths(Angstrom) and angles(degs) (CELL)" \
        help "cell" \
        label "Cell dimensions " \
        widget autoSHARP_cel1 -oblig \
        widget autoSHARP_cel2 -oblig \
        widget autoSHARP_cel3 -oblig \
        widget autoSHARP_cel4 -oblig \
        widget autoSHARP_cel5 -oblig \
        widget autoSHARP_cel6 -oblig \
	toggle_display autoSHARP_data_format open [list SCAU]


    if { $autoSHARP_type == "MIR" && $counter > 1 } {
	CreateInputFileLine line \
	    "File with known sites" \
	    "hatom file" \
	    autoSHARP_sitf DIR_autoSHARP_sitf \
	    -notoblig
    }

    return 1
}
