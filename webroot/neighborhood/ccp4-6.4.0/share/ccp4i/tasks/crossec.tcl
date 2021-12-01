#
#     Copyright (C) 1999-2013  CCP4
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
# ======================================================================
# crossec.tcl --
#
# CCP4Interface 
#
# =======================================================================

# procedure to draw task window
#---------------------------------------------------------------------
proc crossec_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array
  global configure

# Source file containing utility calculations
  source [SearchPath TOP utils pdb_utils.tcl]

  if { [CreateTaskWindow $arrayname  \
        "Estimate Fprime and Fpprime" "Estimate anomalous scattering" \
        {} \
        -action_buttons [list quit interactive ] ] == 0 } return

  set resetbutton [button $array(WINDOW).buttons.reset \
                -text "Reset" \
                -relief raised \
                -background $configure(COLOUR_PALE) \
                -font $configure(FONT_REGULAR) \
                -command "crossec_reset $arrayname"]

  pack $resetbutton -side left -expand 1

  SetProgramHelpFile "crossec"


#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

    CreateLine line \
        label "Atom type" \
        message "Element name of anomalous scatterer" \
        widget ATOM_TYPE -oblig

  CreateExtendingFrame N_WAVELENGTHS crossec_wavelengths \
        "Input wavelengths" \
        "add wavelength" [list WAVELENGTH ]

  CreateLine line \
    label "Anomalous scattering" -italic

  CreateText textframe " " -scroll
  set array(TEXTFRAME) $textframe

}

#=================================================================
proc crossec_run { arrayname } {
#=================================================================
  upvar #0 $arrayname array


  set array(LOGFILE) [GetTmpFileName]
  set log [GetTmpFileName]
  set title "Calculation for $array(ATOM_TYPE)"

  update idletasks

  PleaseWait "Calculating.."

  set text \
"ATOM $array(ATOM_TYPE)
NWAV $array(N_WAVELENGTHS) "

  for {set j 1} {$j <= $array(N_WAVELENGTHS)} {incr j} {
    append text "$array(WAVELENGTH,$j) "
  }
  append text "\nEND\n"

   WriteFile [set comfile [GetTmpFileName -ext _com ]] $text

   set cmd "crossec"
  
  # Set the title if the user hasn't
  SetDefaultTitle $arrayname $title

   if { ![Execute $cmd $comfile status report -log $log ] } {
     PleaseWait
     WarningMessage "Error running crossec program - see job log file"
       if { [file exists $log] } { TranscribeFile $log $array(LOGFILE) }
     return 0
   }

  DeleteFile $comfile

  if { [ReadFile $log logtext] } {
    set line [ExtractFromText $logtext "Atom_type Lambda  F" 0 all]
    set line "Atom        lambda     Fprime     Fdprime\n"
    AppendTextWindow $array(TEXTFRAME) "$line\n"
    set line [ExtractFromText - "" 3 all]
    while { ! [regexp -- "^\$\$" $line] } {
        AppendTextWindow $array(TEXTFRAME) "$line"
        set line [ExtractFromText - "" 1 all]
     }
  } else {
    PleaseWait
    WarningMessage "Error reading log file $array(LOGFILE) from running crossec program"
    return 0
  }

  TranscribeFile $log $array(LOGFILE)
  DeleteFile $log

  AppendTextWindow $array(TEXTFRAME) "\n\n"

  PleaseWait

  return 1

}

#=================================================================
proc crossec_reset { arrayname } {
#=================================================================
# Clear the current settings and redraw the window
  upvar #0 $arrayname array
  ReCreateTaskWindow PROJECT crossec $array(WINDOW) $arrayname
}

#---------------------------------------------------------------------
proc crossec_wavelengths { arrayname counter } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  CreateLine wave_frame \
        message "Enter wavelength in Angstrom" \
        label "Wavelength" \
        widget WAVELENGTH -oblig
}
