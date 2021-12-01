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
# matthews.tcl --
#
# CCP4Interface 
#
# =======================================================================

# procedure which is run automatically before drawing the interface
# used to set up variables, menus etc
#---------------------------------------------------------------------
proc matthews_setup { typedefVar arrayname } {
#---------------------------------------------------------------------

DefineMenu _matthews_mode [list \
			       "protein only" \
			       "DNA/protein complex" \
			       "DNA only" \
			       "RNA only"] \
    [list "OTHER" "COMP" "DNA" "RNA"]

DefineMenu _matthews_molwt [list \
				"entered in Daltons" \
				"estimated from number of residues" \
				"estimated from sequence file" \
				"estimated from sequence of PDB file" \
				"estimated automatically"] \
    [list MOLWT NRES SEQ PDB NONE]
return 1
}

# procedure to draw task window
#---------------------------------------------------------------------
proc matthews_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array
  global configure

# Source file containing utility calculations
  source [SearchPath TOP utils pdb_utils.tcl]

  if { [CreateTaskWindow $arrayname  \
        "Matthews - Cell Content Analysis" "Content" \
        {} \
	-action_buttons [list quit interactive ] ] == 0 } return

  set resetbutton [button $array(WINDOW).buttons.reset \
                -text "Reset" \
                -relief raised \
                -background $configure(COLOUR_PALE) \
                -font $configure(FONT_REGULAR) \
                -command "matthews_reset $arrayname"]

  pack $resetbutton -side left -expand 1

  SetProgramHelpFile "matthews_coef"


#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
    message "Perform calculation for protein, DNA or both in complex, or RNA" \
    help "mode" \
    label "Calculate Matthews coefficient for" \
    widget MATTHEWS_MODE

  CreateLine line \
    widget READ_FROM_MTZ \
    label "Read crystal parameters from MTZ file"

  CreateInputFileLine line \
        "Enter name of MTZ file containing cell and space group info" \
        "MTZ file" \
        HKLIN DIR_HKLIN \
        -setfileparam space_group_name SPACE_GROUP \
        -setfileparam cell CELL \
        -setfileparam resolution_max RESOLUTION_MAX \
        -command "matthews_toggle_use_reso $arrayname" \
        -toggle_display READ_FROM_MTZ open { 1 }

  CreateLine line \
    message "Space group (default as in MTZ file) (SYMMETRY)" \
    help "symmetry" \
    label "Space group" \
    widget SPACE_GROUP

  CreateLine line \
    message "Cell dimensions (default from MTZ file) (CELL)" \
    help "cell" \
    label "Cell a" \
    widget CELL_1 -width 8 \
    label "b" \
    widget CELL_2 -width 8 \
    label "c" \
    widget CELL_3 -width 8 \
    label "alpha" \
    widget CELL_4 -width 8 \
    label "beta" \
    widget CELL_5 -width 8 \
    label "gamma" \
    widget CELL_6 -width 8

  CreateLine line \
    message "Perform the probability calculation for a specific resolution limit" \
    widget USE_RESO -toggleon \
    message "High resolution limit for probability calculation" \
    help "reso" \
    label "High resolution limit" \
    widget RESOLUTION_MAX

  CreateLine line \
    message "Select how to specify the molecular weight of the protein" \
    label "Use molecular weight" \
    widget MOLWT_METHOD

  CreateLine line \
    message "Enter approximate molecular weight (Daltons)" \
    label "Molecular weight of protein or nucleic acid" \
    widget MOLWT \
    toggle_display MOLWT_METHOD open MOLWT

  CreateLine line \
    message "Enter the number of residues in one molecule of the protein or nucleic acid" \
    label "Number of residues" \
    widget NRES -width 8 \
    toggle_display MOLWT_METHOD open NRES

  CreateInputFileLine line \
        "Enter name of sequence file containing the protein sequence or nucleic acid" \
        "Sequence file" \
        SEQUENCE DIR_SEQUENCE \
        -toggle_display MOLWT_METHOD open SEQ

  CreateInputFileLine line \
        "Enter name of PDB file containing the protein coordinates (protein only!)" \
        "PDB file" \
        XYZIN DIR_XYZIN \
        -toggle_display MOLWT_METHOD open PDB

  CreateLine line \
    label "Solvent content analysis" -italic

  CreateText textframe " " -scroll
  set array(TEXTFRAME) $textframe

# Check and use XML
  source [SearchPath TOP utils xml_utils.tcl]
  set array(OUTPUT_XML) [XmlStatus]

}

#=================================================================
proc matthews_run { arrayname } {
#=================================================================
  upvar #0 $arrayname array

#  if { $array(MOLWT) == "" || $array(MOLWT) < 100 } {
#    WarningMessage "Molecular weight is a bit low?"
#    return 0
#  }

  set array(LOGFILE) [GetTmpFileName]
  set log [GetTmpFileName]
  set title "Calculation for $array(MATTHEWS_MODE)"

  update idletasks

  PleaseWait "Calculating.."

  set space_group [string trim $array(SPACE_GROUP) ']
  if { $space_group != "" && ![string is integer $space_group] } { 
    set space_group "\'$space_group\'" 
  }

# a fudge since matthews only recognises DNA
  set mode_arg [GetValue $arrayname MATTHEWS_MODE]
  if { $mode_arg == "RNA" } { set mode_arg "DNA" }

  set text \
"MODE $mode_arg
CELL $array(CELL_1) $array(CELL_2) $array(CELL_3) $array(CELL_4) $array(CELL_5) $array(CELL_6)
SYMM $space_group
AUTO\n"

   if { $array(OUTPUT_XML) } { append text "XMLO\n" }
   if { $array(USE_RESO) && $array(RESOLUTION_MAX) != "" } {
       append text "RESO $array(RESOLUTION_MAX)\n"
   }

   if { [StringSame [GetValue $arrayname MOLWT_METHOD] MOLWT] } {
     if { $array(MOLWT) != ""  } {
        append text "MOLWT $array(MOLWT)\n"
        append title " using molecular weight $array(MOLWT) Daltons"
     } else {
        WarningMessage "Please enter a value for the molecular weight"
        return 0
     }
   } elseif { [StringSame [GetValue $arrayname MOLWT_METHOD] NRES] } {
     if { $array(NRES) != ""  } {
        append text "NRES $array(NRES)\n"
        append title " using $array(NRES) residues"
     } else {
        WarningMessage "Please enter a value for the number of residues"
        return 0
     }
   } elseif { [StringSame [GetValue $arrayname MOLWT_METHOD] SEQ] } {
     # Run SEQWT program to get the estimated MOLWT
     if { [GetValue $arrayname MATTHEWS_MODE] == "DNA" } {
       set cmd "seqwt DNASEQUENCE [GetFullFileName0 $arrayname SEQUENCE]"
     } elseif { [GetValue $arrayname MATTHEWS_MODE] == "RNA" } {
       set cmd "seqwt RNASEQUENCE [GetFullFileName0 $arrayname SEQUENCE]"
     } else {
       set cmd "seqwt SEQUENCE [GetFullFileName0 $arrayname SEQUENCE]"
     }
     if { ![Execute $cmd {} status report -log $log ] } {
       PleaseWait
       WarningMessage "Error running seqwt program - see job log file"
       if { [file exists $log] } { TranscribeFile $log $array(LOGFILE) }
       return 0
     }
     # Extract molweight from the logfile
     if { [ReadFile $log logtext] } {
       set molwt [ExtractFromText $logtext "Total     Molecular Weight" 0 3]
       AppendTextWindow $array(TEXTFRAME) \
	   " Molecular weight estimated from sequence: $molwt Da"
       set array(MOLWT) $molwt
       append text "MOLWT $array(MOLWT)\n"
     } else {
       PleaseWait
       WarningMessage "Error reading log file $array(LOGFILE) from running seqwt program"
       return 0
     }
   } elseif { [StringSame [GetValue $arrayname MOLWT_METHOD] PDB] } {

     if { [GetValue $arrayname MATTHEWS_MODE] != "OTHER" } {
       PleaseWait
       WarningMessage "Sorry - pdbset program only works for protein sequences"
       if { [file exists $log] } { TranscribeFile $log $array(LOGFILE) }
       return 0
     }

     # Run PDBSET program to get the estimated MOLWT from sequence
     set cmd "pdbset XYZIN [GetFullFileName0 $arrayname XYZIN]"
     set seqfile [GetTmpFileName]
     WriteFile [set comfile [GetTmpFileName -ext _com ]] \
	 "SEQUENCE PDB $seqfile\nEND"
     if { ![Execute $cmd $comfile status report -log $log ] } {
       PleaseWait
       WarningMessage "Error running pdbset program - see job log file"
       if { [file exists $log] } { TranscribeFile $log $array(LOGFILE) }
       return 0
     }
     # Extract molweight from the logfile
     if { [ReadFile $log logtext] } {
       set molwt [ExtractFromText $logtext "  Molecular Weight from sequence" 0 4]
       AppendTextWindow $array(TEXTFRAME) \
	   " Molecular weight estimated from coordinate sequence: $molwt Da"
       set array(MOLWT) $molwt
       append text "MOLWT $array(MOLWT)\n"
     } else {
       PleaseWait
       WarningMessage "Error reading log file $array(LOGFILE) from running pdbset program"
       return 0
     }
   } else {
     append title " molecular weight estimated automatically"
  }

   WriteFile [set comfile [GetTmpFileName -ext _com ]] $text

   set cmd "matthews_coef "
   if { $array(OUTPUT_XML) } { 
     set array(XMLFILE) [FileJoin [GetDbDirPath] MATTHEWS_COEF.xml]
     append cmd "XMLFILE $array(XMLFILE) " 
   }
  
  # Set the title if the user hasn't
  SetDefaultTitle $arrayname $title
  
   if { ![Execute $cmd $comfile status report -log $log ] } {
     PleaseWait
     WarningMessage "Error running matthews_coef program - see job log file"
       if { [file exists $log] } { TranscribeFile $log $array(LOGFILE) }
     return 0
   }

  DeleteFile $comfile

  if { [ReadFile $log logtext] } {
    set line [ExtractFromText $logtext "Cell volume:" 0 all]
    AppendTextWindow $array(TEXTFRAME) "$line\n"
    if { $array(MOLWT) == "" } {
      set line [ExtractFromText - "Assuming 50" 0 all]
      AppendTextWindow $array(TEXTFRAME) $line
      set line [ExtractFromText - {} 1 all]
      AppendTextWindow $array(TEXTFRAME) $line
    }
  } else {
    PleaseWait
    WarningMessage "Error reading log file $array(LOGFILE) from running matthews_coef program"
    return 0
  }

  TranscribeFile $log $array(LOGFILE)
  DeleteFile $log

  set molwt_method [GetValue $arrayname MOLWT_METHOD]
  switch $molwt_method {
     MOLWT {
       set line "For given protein molecular weight: $array(MOLWT) Da"
     }
     NRES {
       set line "Molecular weight estimated from number of residues: $array(NRES)"
     }
     default {
       set molwt [ExtractFromText $logtext "The Molecular weight is estimated as:" 0 6]
       if { $molwt != "" } {
         set line "Molecular weight estimated automatically by the program: $molwt"
       }
     }
  }
  AppendTextWindow $array(TEXTFRAME) $line

  set line [ExtractFromText $logtext "Matthews Coeff" 0 all]
  AppendTextWindow $array(TEXTFRAME) "$line\n"

  set line [ExtractFromText - "" 2 all]
  while { ! [string match {*___*} $line] } {
    AppendTextWindow $array(TEXTFRAME) "$line"
    set line [ExtractFromText - "" 1 all]
  }

  AppendTextWindow $array(TEXTFRAME) "\n\n"

  PleaseWait

  return 1

}

#=================================================================
proc matthews_reset { arrayname } {
#=================================================================
# Clear the current settings and redraw the window
  upvar #0 $arrayname array
  ReCreateTaskWindow PROJECT matthews $array(WINDOW) $arrayname
}

#=================================================================
proc matthews_toggle_use_reso { arrayname } {
#=================================================================
# If a maximum resolution value is set from the MTZ file then
# toggle on the switch to use this in the calculation
  upvar #0 $arrayname array
  if { [string trim $array(RESOLUTION_MAX)] != "" } {
      set array(USE_RESO) 1
  }
}
