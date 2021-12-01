#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# =======================================================================
# pref.tcl --
#
# Interface for user to set preferences the interface
#
# CCP4Interface 
# Created Apr87 by Liz Potterton
#
# =======================================================================

#------------------------------------------------------------------------------
proc pref_setup { typedefVar arrayname } {
#------------------------------------------------------------------------------
 upvar #0 $typedefVar typedef
 upvar #0 $arrayname array

  set typedef(_manage_updates) {
    menu {
      "do nothing" \
      "notify only" \
      "start updater" \
    } {
      disable \
      notify \
      manage  \
    }
  }

  # Set up a menu of map viewers
  GetViewerList "MAP" viewer_list viewercmd_list
  DefineMenu _mapviewer_default $viewer_list $viewercmd_list

  # Set up a menu of PDB viewers
  GetViewerList "PDB" viewer_list viewercmd_list
  DefineMenu _pdbviewer_default $viewer_list $viewercmd_list

  # Set up a menu of MTZ viewers
  GetViewerList "MTZ" viewer_list viewercmd_list
  DefineMenu _mtzviewer_default $viewer_list $viewercmd_list

  return 1
}

#------------------------------------------------------------------------------
proc pref_task_window { arrayname } {
#------------------------------------------------------------------------------
 upvar #0 $arrayname array
 global configure

  set helpfile [SearchPath HELP general preferences.html ]
  InitialisePreferences preferences $arrayname

  set folderList [list \
     "Update" \
     "Delete/Archive Files" \
     "File Selection" \
     "Creating Maps" \
     "Default Viewers" \
     "Logfile Annotation (Baubles)" \
     "Data Harvesting" \
     "Exit Behaviour" \
     "XML Output"\
  ]

  source [SearchPath TOP src qtrview.tcl]
  if { [qtrview::isAvailable] } {
     lappend folderList "Display Qt Report Page"
  }


  if { [CreateTaskWindow $arrayname  \
        "Set Preferences for CCP4Interface" "Prefernces" \
        $folderList \
	-action_buttons quit \
	-help_file $helpfile ] == 0 } return

  set savebutton [menubutton $array(WINDOW).buttons.save \
		-text "Save" \
		-indicatoron 1 -relief raised  \
		-background $configure(COLOUR_PALE) \
		-font $configure(FONT_REGULAR) \
          	-menu $array(WINDOW).buttons.save.m1 ]

  menu $savebutton.m1 -tearoff 0

  $savebutton.m1 add command -label "Save to installation file" \
		-font $configure(FONT_REGULAR) \
	-command " SaveInstallPreferences preferences $arrayname 
  	       InitialisePreferences preferences preferences
                       ::CCP4_Updates::preferences_saved"

  $savebutton.m1 add command -label "Save to user's home directory" \
		-background $configure(COLOUR_PALE) \
		-font $configure(FONT_REGULAR) \
       		 -command " SavePreferences preferences $arrayname
                       InitialisePreferences preferences preferences
                       ::CCP4_Updates::preferences_saved"

  # checking /Applications/ccp4-6.3.0/share/ccp4i/etc/unix/preferences.def
  global env
  set fl [file join $env(CCP4I_TOP) etc]
  if {
     [file readable $fl] && [file writable $fl] && ! [file exists [set fl [file join $fl unix]]] ||
     [file readable $fl] && [file writable $fl] && ! [file exists [set fl [file join $fl preferences.def]]] ||
     [file readable $fl] && [file writable $fl] 
  } {} else {
     $savebutton.m1 entryconfigure 0 -state disabled
  }

  bind $savebutton <Button-3> "KeywordHelp $helpfile saving_preferences"

  pack  $savebutton  -side left -expand 1
  SetProgramHelpFile [SearchPath HELP general preferences.html ]

  OpenFolder 1
  if { ! $::CCP4_Updates::update_off } {
    CreateLine line \
      message "Defines how ccp4i treates new updates" \
      label "If there are new updates " \
      widget MANAGE_UPDATES

    CreateLine line \
      message "Sets timeout for background Update check" \
      label "Cancel background Update check after" \
      widget UPDATE_CHECK_TIMEOUT \
      label "seconds"
  }

  OpenFolder 2

  CreateLine line \
    label "Default option in 'Delete/Archive Files..'" \
    widget CLEANUP_DEFAULT

  CreateLine line \
    widget CLEANUP_DIR_WARNING \
    label "Show warning message when removing directory"

  OpenFolder 3 closed

  CreateLine line \
    message "Set default mode for listing files in file selection" \
    label "In file selection list files by" \
    widget FILESELECT_DEFAULT

  OpenFolder 4 closed

  CreateLine line \
    label "By default create maps in" \
    widget MAP_OUTPUT_FORMAT \
    label "format in" \
    widget MAP_OUTPUT_DEFDIR \
    label directory

  CreateLine line \
    widget MAPMAN_NORMALISE \
    label "Normalise maps output by Mapman for O program"

  CreateLine line \
    help "Alternatively map names will be generated automatically" \
    widget IFMAPNAME \
    label "In Refmac5 interface give output map names explicitly"

  OpenFolder 5 closed

  CreateLine line \
    label "Set the default PDB viewer to" \
    widget PDBVIEWER_DEFAULT

  CreateLine line \
    label "Set the default map viewer to" \
    widget MAPVIEWER_DEFAULT

  CreateLine line \
    label "Set the default mtz viewer to" \
    widget MTZVIEWER_DEFAULT

  OpenFolder 6 closed

  CreateLine line \
    message "If unselected then annotated logs are not regenerated each time they're vieweed" \
    widget DYNAMIC_ANNOTATION \
    label "Generate annotated logfiles dynamically by running Baubles on demand"

  OpenFolder 7 closed

  CreateLine line \
    message "Set default mode of operation for harvesting mechanism" \
    label "By default" \
    widget HARVEST_MODE -command "util_set_harvesthome $arrayname"

  CreateLine line \
    message "Private directories are viewable only by owner" \
    widget HARVEST_PRIVATE \
    label "Create harvest directories to be private"

  CreateLine line \
    label "Maximum width of a row in the deposit file" \
    widget HARVEST_RSIZE

  OpenFolder 8 closed

  CreateLine line \
    label "Prompt for confirmation of exit" \
    widget PROMPT_ON_EXIT

  OpenFolder 9 closed

  CreateLine line \
    label "Warning: this is a developmental option" -italic

  CreateLine line \
    widget XML_OUTPUT \
    label "Switch on XML output for tasks which support it"

  if { [qtrview::isAvailable] } {

    OpenFolder 10

    CreateLine line \
      label "Warning: this is a developmental option" -italic

    CreateLine line \
      widget QTREPORT_YES \
      label "Generate Qt Report Pages"
  }
}

