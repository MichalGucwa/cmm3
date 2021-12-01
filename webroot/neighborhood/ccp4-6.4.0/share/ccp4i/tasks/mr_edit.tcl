#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
#----------------------------------------------------------------------
proc mr_edit_task_window { arrayname } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array
# Display a solution file in a list widget 
# When user picks a line in the widget it is edited
# to add/remove the comment character (#)
  global configure

  if { ![ElementExists $arrayname FILE_MODE] } { set array(FILE_MODE) mr }
  set w $array(WINDOW)
  if { [winfo exist $w] } {
      wm iconify $w
      wm deiconify $w
      WarningMessage "You already have an MR solution file window open"
    return 0
  }

  if { ![ElementExists $arrayname SOLFIL ] || $array(SOLFIL) == "" } {
    if { ![SelectFile file -title "Select MR solution file to edit" \
	-filter "*.mr" \
	-defdir [GetCurrentProject] ] } { return 0 }
  set array(SOLFIL) [lindex $file 0]
  }

  if { ![ReadFile [GetFullFileName0 $arrayname SOLFIL] text] } {
    WarningMessage "Can not open and read file [GetFullFileName0 $arrayname SOLFIL]"
    return 0
  }

  if { [regexp mr $array(FILE_MODE) ] } {
    set help_file [SearchPath HELP modules molrepl.html]
    set array(TASK_TITLE) "Edit MR solution file"
  } else {
    set help_file [SearchPath HELP modules exptphase.html ]
    set array(TASK_TITLE) "Edit HA solution file"
  }

  set root [file root $array(SOLFIL)]

  set text_list [split $text \n]
  set ll  [ expr [llength $text_list] -1 ]
  while { $ll >= 0 && 
    [string trim [lindex $text_list $ll ] ] == "" } {
    incr ll -1
  }
  if { $ll < 0 } {
    WarningMessage "File is empty $array(SOLFIL)"
    return 
  }
  set array(EDIT_TEXT) [lrange $text_list 0 $ll]
  set array(EDIT_TEXT_LEN) $ll

  OpenGridWindow $arrayname $w $root $root \
	-help  $help_file \
	-target solution_files

# Create the main scrollable text display

  set main $w.main
  scrollbar $main.yscroll         -orient vertical \
                                -command [list $main.text yview ]

  set frame [ listbox $main.text   -width 90 -height 20 \
                                -setgrid true \
                                -yscroll [list $main.yscroll set ] \
				-font $configure(FONT_FIXED) \
				-selectmode single ]

  grid $main.text                 -row 0 -column 0 -sticky nsew
  grid $main.yscroll              -row 0 -column 1 -sticky ns
  grid columnconfigure $main 0    -weight 1
  grid columnconfigure $main 1    -weight 0
  grid rowconfigure $main 0       -weight 1

  foreach line $array(EDIT_TEXT) {
    $frame insert end "$line"
  }
  $frame yview moveto 0.0

  bind $frame <ButtonRelease-1> "mr_edit_solution_pick $arrayname %W"

  SetMessage $arrayname $frame "Click on line to add/remove initial #"

  button $w.buttons.save -text Save&Exit            \
      -command  "mr_edit_exit save $arrayname $w"
  pack $w.buttons.save -side left -expand 1
  SetMessage $arrayname $w.buttons.save "Save the edited file and exit"

# Save As

  button $w.buttons.saveas -text "Save As.." \
	-command  "mr_edit_save $arrayname"
  pack $w.buttons.saveas -side left -expand 1
  SetMessage $arrayname $w.buttons.save "Save the changes to a new file"

# Dismiss button

  button $w.buttons.dismiss -text Quit                  \
        -command  "mr_edit_exit quit $arrayname $w; ExitFileViewer"
  pack $w.buttons.dismiss -side left -expand 1

  SetMessage $arrayname $w.buttons.dismiss "Exit the editor without saving changes"

# Edit all button

  button $w.buttons.edit -text "Change All"                  \
        -command  "mr_edit_all $arrayname $main.text"
  pack $w.buttons.edit -side left -expand 1
  SetMessage $arrayname $w.buttons.edit "Change the status of all the solution lines"

# Edit columns

  if { [regexp ha $array(FILE_MODE) ] } {

    button $w.buttons.hand -text "Reverse hand" \
	-command  "mr_reverse_hand $arrayname $main.text"

    button $w.buttons.col -text "Edit Columns" \
	-command  "mr_edit_ha $arrayname $main.text"
    pack $w.buttons.hand $w.buttons.col -side left -expand 1
    SetMessage $arrayname $w.buttons.hand "Change the hand of the coordinates"
    SetMessage $arrayname $w.buttons.col "Change all the values of a column in the solution file" 
  }



}

#------------------------------------------------------------------------------
proc mr_edit_solution_pick { arrayname frame } {
#------------------------------------------------------------------------------
  upvar #0 $arrayname array
  set selection [$frame curselection]
  if { $selection == "" || $selection > $array(EDIT_TEXT_LEN) } { return }
  set line [lindex $array(EDIT_TEXT) $selection]
  if [ regexp {^#CCP4I} $line ] { return }
  if [ regexp {^#} $line ] {
    set line [string range $line 1 end ]
  } else {
    set line "#$line"
  }
  set array(EDIT_TEXT) [lreplace $array(EDIT_TEXT) $selection $selection "$line" ]
  $frame delete $selection
  $frame insert $selection "$line"
  
}

#-------------------------------------------------------------------------------
proc mr_edit_all { arrayname frame } {
#-------------------------------------------------------------------------------
# Change status of every line in file - flip from whatever
# status of first non-comment line is
  upvar #0 $arrayname array

  set mode 0; set new_text ""

  foreach line $array(EDIT_TEXT) {
    if { ![ regexp {^#CCP4I} $line ] } {
      if { $mode == 0 } {
        if [regexp {^#} $line ] { 
          set mode -1
          set line [string range $line 1 end ]
        } else {
          set mode 1
          set line "#$line"
        }
      } elseif [regexp {^#} $line ] {
        if { $mode == -1 } { set line [string range $line 1 end ] }
      } else {
        if { $mode == 1 } { set line "#$line" }
      }
    }
    lappend new_text "$line"
  }
  set array(EDIT_TEXT) $new_text
  $frame delete  0 end
  foreach line $array(EDIT_TEXT) {
    $frame insert end "$line"
  }
  $frame yview moveto 0.0

}
      


#-----------------------------------------------------------------------------------
proc mr_edit_exit { mode arrayname w } {
#-----------------------------------------------------------------------------------
  upvar #0 $arrayname array

  if [regexp save $mode ] {
    if { ![DeleteFile $array(SOLFIL) ] } {
      WarningMessage "Can not overwrite file $array(SOLFIL)
Check that you have permission to delete the file before
trying to overwrite it"
      return 0
    }
    OpenFile $array(SOLFIL) f 
    foreach line $array(EDIT_TEXT) {
      puts $f $line
    }
    CloseFile $f
  }

  destroy $w
  unset array
}

#------------------------------------------------------------------
proc  mr_edit_save { arrayname } {
#------------------------------------------------------------------
  upvar #0 $arrayname array
# Implement Save As option
# Prompt user for name of file to save data
  if { [SelectFile fileout -title "Save HA file as" \
	-filter "*.$array(FILE_MODE)" \
       -defdir [GetCurrentProject]   -unknown ] } {
    if { [file exists [lindex $fileout 0]] &&  \
      ![ regexp Overwrite \
        [ ChooseOptionDialog "Overwrite" "Overwrite" \
          "Overwrite file [lindex $fileout 0]" [list Quit Overwrite ] ] ] } {
	return 0
    }
    foreach line $array(EDIT_TEXT) { append textout "$line\n" }
    WriteFile [lindex $fileout 0] $textout -overwrite
  }
}

#------------------------------------------------------------------
proc mr_edit_ha { arrayname frame } {
#------------------------------------------------------------------
  upvar #0 $arrayname array

  set new_text ""

  set array(LOAD_ATOM_TYPE) ""
  set array(LOAD_OCC) ""
  set array(LOAD_ANOM_OCC) ""
  set array(LOAD_B) ""
  if { ![InputParamDialog "Edit Heavy Atom File" Edit \
    $arrayname [ list \
        [ list LOAD_ATOM_TYPE "Set atom names" _text ] \
        [ list LOAD_OCC "Set occupancies" _positivereal ] \
        [ list LOAD_ANOM_OCC "Set anomalous occupancies" _positivereal ] \
        [ list LOAD_B "Set temperature factors" _positivereal ] ] ] } \
	{ return 0 }


  foreach line $array(EDIT_TEXT) {
    if { [regexp ATOM $line ] } {
      set ib [ expr 1 + [lsearch $line BFAC ] ]
      if { $array(LOAD_B) != "" } { set line \
        [ lreplace $line $ib $ib $array(LOAD_B) ] }
      if { $array(LOAD_ATOM_TYPE) != "" } { set line \
	[lreplace $line 1 1 $array(LOAD_ATOM_TYPE)] }
      if { $array(LOAD_OCC) != "" } { set line \
	[lreplace $line 5 5 $array(LOAD_OCC) ] }
      if { $array(LOAD_ANOM_OCC) != "" } { 
        if { $ib > 7 } { set line \
        [ lreplace $line 6 6 $array(LOAD_ANOM_OCC) ] 
        } else { set line \
          [linsert $line 6 $array(LOAD_ANOM_OCC)]
        }
      }
    }

    lappend new_text "$line"
  }

  set array(EDIT_TEXT) $new_text
  $frame delete  0 end
  foreach line $array(EDIT_TEXT) {
    $frame insert end "$line"
  }
  $frame yview moveto 0.0
}

#----------------------------------------------------------------------
proc mr_reverse_hand { arrayname frame } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array

  set query "Enter space group if it is F4132, I4122 or I41"
  set array(SPACE_GROUP) ""

  if { ![InputParamDialog "Change Hand" Hand \
    $arrayname [ list \
        [ list SPACE_GROUP "$query" _text ] ] ] } \
        { return 0 }

  if { $array(SPACE_GROUP) == ""  ||
    ![GetChangeHandData $array(SPACE_GROUP) new_space_group cx] } {
      set cx [list 0.0 0.0 0.0]
  }

  foreach line $array(EDIT_TEXT) {
    if { [regexp ATOM $line ] } {
      set xx [expr [lindex $cx 0] - [lindex $line 2]]
      set yy [expr [lindex $cx 1] - [lindex $line 3]]
      set zz [expr [lindex $cx 2] - [lindex $line 4]]
      set line [lreplace $line 2 2 $xx]
      set line [lreplace $line 3 3 $yy]
      set line [lreplace $line 4 4 $zz]
    }
    lappend new_text "$line"
  }

  set array(EDIT_TEXT) $new_text
  $frame delete  0 end
  foreach line $array(EDIT_TEXT) {
    $frame insert end "$line"
  }
  $frame yview moveto 0.0
}
