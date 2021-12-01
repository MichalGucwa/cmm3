#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - directories.tcl
#
#
#
# Interface for user to define directory aliases and select project
# directory
#
# Liz Potterton, Peter Briggs 1997-2008
#
#====================================================================

#CCP4i_cvs_Id $Id$

#d_index_title Projects and Directories Interface (src/directories.tcl)
#d_intro_title Projects and Directories Interface
#d_intro This is the interface which is found under the \
'Projects and Directories' button.
#d_intro The window maintains a variable menu called PROJECT_MENU which is \
a list of the currently defined projects from which the user can select \
the current project.
#d_intro The complications with this window come mostly from the requirement \
to keep up to date the current project database and the menus listing \
the defined projects and aliases which appear on every file selection line. \
These are not updated until the user exits the window.

#-------------------------------------------------------------------
proc directories { } {
#-------------------------------------------------------------------
#d_sum Initialise interface if user open the 'Directories' window stand alone.
#d_desc This will be used for user command 'ccp4i -d'

  global system
  global typedef
  source [SearchPath TOP etc types.def]
  InitialisePreferences configure configure
  wm withdraw .

  source [SearchPath TOP src utils.tcl]
  source [SearchPath TOP src window.tcl]
  source [SearchPath TOP src fileselect.tcl]
  source [SearchPath TOP src exframe.tcl]
  source [SearchPath TOP src varmenu.tcl]
  source [SearchPath TOP src database.tcl]
  source [SearchPath TOP src util_windows.tcl]
  source [SearchPath TOP src projectdirs.tcl]

  set system(RUN_MODE) directories
  if { [ InitialiseDirectories ] == 1 } {
    Directories init
  } else {
    Directories
  }
}

#-----------------------------------------------------------------
proc check_directory_alias {  arrayname param counter } {
#-----------------------------------------------------------------
#d_sum Check  that user input project or directory alias is unique
#d_desc Also ensure that it does not contain unallowed characters
#d_arg arrayname Name of the data array (probably 'directories')
#d_arg param  Name of the parameter to check (probably PROJECT or ALIAS)
#d_arg counter The counter for the parameter

  upvar #0 $arrayname array

  set array([Indxv $param $counter]) \
	[RemoveMetaChars $array([Indxv $param $counter]) -report ]
  CheckUnique $arrayname $param $counter
}

#-----------------------------------------------------------------
proc DefineDirectory { arrayname counter } {
#-----------------------------------------------------------------
#d_sum Create the graphics for defining one directory
#d_desc Part of the CreateExtendingFrame mechanism
#d_arg arrayname Name of the data array (probably 'directories')
#d_arg counter Counter for number of directories

  upvar #0 $arrayname array
  global configure

  if { $counter == 1 } {

  CreateLine line               \
    help directories \
    label "Alias: " \
    label "TEMPORARY " \
    message "Enter full path name of directory" \
    label "for directory:" \
    widget DEF_DIR_PATH -expand \
    message "Use file browser to define path name of directory" \
    button "Browse.."


  } else {

  CreateLine line               \
    message "Enter one-word alias for a directory" \
    help directories \
    label "Alias:" \
    widget DEF_DIR_ALIAS \
        -command "check_directory_alias $arrayname DEF_DIR_ALIAS $counter" \
        -width 10 \
    message "Enter full path name of directory" \
    label "for directory:" \
    widget DEF_DIR_PATH -expand \
    message "Use file browser to define path name of directory" \
    button "Browse.."


# check that a alias entered in the entry box is OK
    set cmd "make_one_word $arrayname DEF_DIR_ALIAS,$counter"
    bind  $line.e2 <KeyRelease> +$cmd
  }

# check that a path name  entered in the entry box is OK
    add_command $line.e4 "CheckDirInput $arrayname DEF_DIR_PATH,$counter"
    $line.b5 configure -font $configure(FONT_SMALL)
# bind picking of file browser icon to directory browser utility
    set cmd "DirBrowser $arrayname DEF_DIR_PATH,$counter"
    add_command $line.b5 $cmd

}


#-----------------------------------------------------------------
proc DefineProject { arrayname counter } {
#-----------------------------------------------------------------
#d_sum Create the graphics for defining one project
#d_desc Part of the CreateExtendingFrame mechanism
#d_arg arrayname Name of the data array (probably 'directories')
#d_arg counter Counter for number of projects

  upvar #0 $arrayname array
  global configure

  if { $counter > 1 } { set mode append } else { set mode initialise }
  UpdateVariableMenu $arrayname $mode 0 PROJECT_MENU \
                   [list $array(PROJECT_ALIAS,$counter) ]

  CreateLine line               \
    message "Enter one-word alias for project" \
    help directories \
    label "Project" \
    widget PROJECT_ALIAS \
	-command "check_directory_alias $arrayname PROJECT_ALIAS $counter" \
	-updatevarmenu PROJECT_MENU $counter  \
        -width 10 \
    message "Enter full path name of directory" \
    label "uses directory:" \
    widget PROJECT_PATH \
    message "Use file browser to define path name of directory" \
    button "Browse.."

    $line.b5 configure -font $configure(FONT_SMALL)

# set the default project dir 
  set cmd "make_one_word $arrayname PROJECT_ALIAS,$counter"
  bind $line.e2 <KeyRelease> +$cmd

# check that a path name entered in the entry box is OK
  set cmd "CheckDirInput $arrayname PROJECT_PATH,$counter"
  add_command $line.e4 $cmd

# bind picking of file browser icon to directory browser utility
  set cmd "DirBrowser $arrayname PROJECT_PATH,$counter"
  add_command $line.b5 $cmd

}


#-----------------------------------------------------------------------
proc undo_DefineProject { arrayname counter } {
#-----------------------------------------------------------------------
#d_sum Handler when user removes project definition from the extending frame list
#d_desc Procedure found automatically by the extending frames edit
#d_arg arrayname Name of the task array
#d_arg counter The updated number of projects
  upvar #0 $arrayname array
# Update the menu with the list of currently defined directory aliases
  set ll ""
  if { $counter > 0 } { for { set n 1 } { $n <= $counter } { incr n } {
      lappend ll $array(PROJECT_ALIAS,$n)
  } }
  UpdateVariableMenu $arrayname initialise 0 PROJECT_MENU $ll  \
        {} {} 
}


#----------------------------------------------------------------------------
proc Directories { {mode edit} } {
#----------------------------------------------------------------------------
#d_sum Draw the 'Projects and Directories' window
#d_desc The initialisation stuff should probably be part of an autoconf \
procedure rather than here
#d_arg mode Default is edit, or init mode which will set some initial defaults.

  global configure
  global edit_directories

  # Initialise from directories.def but set lock flag so that
  # a lock will be tested and recreated.  InitialisePreferences will
  # return 0 if the file is locked - so abort edit
  if { ![InitialiseDirectories -lock] } { return }

  # Do initialisations
  InitialiseCCP4ITemp

  DefineMenu _log_directory [list temporary "current project" ] [list TEMPORARY PROJECT]

  #Set up user interface
  set w .edit_directories
  if { ![OpenWindow $w "Directories & Project Directory" "Directory"  \
		-help [SearchPath HELP general intro.html] \
		-target directories \
                -message directories ] } { return }
  CreateFrame $w edit_directories

  SetProgramHelpFile [SearchPath HELP general intro.html]

  # Set up parameters in the edit_directories array

  # Projects
  DefineVariable edit_directories N_PROJECTS      _positiveint1 0
  DefineVariable edit_directories PROJECT_ALIAS,0 _text ""
  DefineVariable edit_directories PROJECT_PATH,0  _dir ""
  # Keep a list of projects on setup
  DefineVariable edit_directories PROJECT_LIST    _list_of_text {}
  # Currently selected project
  DefineVariable edit_directories SELECTED_PROJECT _default_project ""
  # Defdirs
  DefineVariable edit_directories N_DEF_DIRS      _positiveint1 0
  DefineVariable edit_directories DEF_DIR_ALIAS,0 _text ""
  DefineVariable edit_directories DEF_DIR_PATH,0  _dir ""
  # Keep a list of defdirs on setup
  DefineVariable edit_directories DEF_DIR_LIST    _list_of_text {}
  # Are we running in init mode?
  DefineVariable edit_directories INIT_MODE _logical 0

  # Populate the data items for the projects and defdirs
  populate_directories_window edit_directories

  CreateButton $w quit \
    "Quit" "apply_directories quit edit_directories $w ; unset edit_directories"
  CreateButton $w apply \
    "Apply" "apply_directories apply edit_directories $w"
  CreateButton $w save \
    "Apply&Exit" "apply_directories save edit_directories $w ; unset edit_directories"

  CreateLine line \
      label "Enter one-word alias and full directory path for your Project directory(s)." -italic

  CreateLine line \
      label "Deleting these project definitions will not delete the actual directories." -itallic

  if { $mode == "init" } {
    CreateLine line \
      label "The interface will create a sub-directory called CCP4_DATABASE and save files there." -italic
    CreateLine line \
      label "To change projects or directories in future use the 'Directories&ProjectDir' button." -italic
    set edit_directories(INIT_MODE) 1
   }

  CreateExtendingFrame N_PROJECTS DefineProject \
        "Add another project"  \
        "Add project" \
      { PROJECT_ALIAS \
        PROJECT_PATH  }

  CreateLine line1 \
        help directories \
        message "Choose working project from list of aliases entered below" \
        label "Project for this session of [GetSystemVar VERSION]" \
        widget SELECTED_PROJECT

  CreateLine line \
      label "Enter one-word alias and full directory path for other directories you use regularly." -italic

  CreateExtendingFrame N_DEF_DIRS DefineDirectory \
        "Add an alias for another directory that you use regularly"  \
        "Add directory alias" \
      { DEF_DIR_ALIAS \
        DEF_DIR_PATH  }

  CloseFrame

  run_update_script edit_directories
  update_main_scroll $w

}

#-----------------------------------------------------------------------
proc populate_directories_window { arrayname } {
#-----------------------------------------------------------------------
#d_sum Populate the parameters of the Directories window
#d_desc Internal procedure to be called when setting up the Directories \
and ProjectDirs window (procedure Directories).
#d_arg arrayname Name of the array associated with the Directories window

  upvar #0 $arrayname array

  # Populate the data itmes for the projects
  set array(N_PROJECTS) 0
  set array(PROJECT_LIST) [ListProjects]
  if { [llength $array(PROJECT_LIST)] > 0 } {
      set no_projects 0
  } else {
      set no_projects 1
  }
  if { ! $no_projects } {
      # Populate with the directories the user actually has
      foreach project $array(PROJECT_LIST) {
	  set n [incr array(N_PROJECTS)]
	  set array(PROJECT_ALIAS,$n) $project
	  set array(PROJECT_PATH,$n) [GetProjectPath $project]
      }
  } else {
      # Make a mock project for the user to change
      # This will be called PROJECT and be set to the current directory
      set n [incr array(N_PROJECTS)]
      set array(PROJECT_ALIAS,$n) "PROJECT"
      set array(PROJECT_PATH,$n) [GetCurrentDir]
      set array(PROJECT_LIST) [list PROJECT]
  }
  # Project menu and selected menu
  if { ! $no_projects } {
      set array(SELECTED_PROJECT) [GetCurrentProject]
      set array(PROJECT_MENU) [ListProjects]
  } else {
      set array(SELECTED_PROJECT)  "PROJECT"
      set array(PROJECT_MENU) [list "PROJECT"]
  }
  # Populate the data items for the defdirs
  set array(DEF_DIR_LIST) [ListDefdirs]
  set array(N_DEF_DIRS) 0
  foreach defdir $array(DEF_DIR_LIST) {
      set n [incr array(N_DEF_DIRS)]
      set array(DEF_DIR_ALIAS,$n) $defdir
      set array(DEF_DIR_PATH,$n) [GetDefdirPath $defdir]
  }   
  return
}

#-----------------------------------------------------------------------
proc InitialiseCCP4ITemp { } {
#-----------------------------------------------------------------------
#d_sum Initialise the CCP4i TEMPORARY data directory 
  # Check for and set up TEMPORARY defdir
  if { [GetDefdirPath TEMPORARY] == "" } {
      AddDefdir TEMPORARY [GetEnvPath CCP4_SCR]
  } else {
      if { [ResolveUnixFileSymbols [GetDefdirPath TEMPORARY] path ] } {
	  # Delete the existing TEMPORARY and replace with an updated value
	  DeleteDefdir TEMPORARY
          AddDefdir TEMPORARY $path
      }
  }
}

#-----------------------------------------------------------------------
proc apply_directories { mode arrayname w } { 
#-----------------------------------------------------------------------
#d_sum Handle updates on applying the changes in the window
#d_desc Invokes DbChangeFile which updates the project database if necessary \
and update_defdir_menu which updates the directory alias menu which appears \
in all file selection lines.
#d_arg mode One of quit, apply or save
#d_arg arrayname Name of the array with the directories data
#d_arg w The name of the directories window

  upvar #0 $arrayname array
  global system

  # If using the handler check that the connection is still available
if { ![regexp quit $mode] && [using_dbccp4i] } {
      if { ![dbccp4i_verify_connection] } {
	  WarningMessage "The connection to the database server has been
lost.

It is not possible to apply the requested changes.

Sorry for the inconvenience - please try restarting
CCP4i and applying your changes again. If you still
have problems please report them to the CCP4
developers."
	  return
      }
  }
  
  if { $array(INIT_MODE) } {
      return [apply_directories_init $mode $arrayname $w]
  }

  set ierror 0

  if {[regexp {save|apply} $mode ]} {

      # Determine what changes the user made to the projects
      set new_projs {}
      set del_projs {}
      set dif_projs {}

      # Explicitly update each of the projects from the array
      set nprojects $array(N_PROJECTS)
      for { set i 1 } { $i <= $nprojects } { incr i } {
	  set project [string trim $array(PROJECT_ALIAS,$i)]
	  if { $project == "" } {
	      # Ignore
	  } elseif { [lsearch $array(PROJECT_LIST) $project] < 0 } {
	      # New project definition
	      lappend new_projs $i
	  } else {
	      # Check for changes
	      if { $array(PROJECT_PATH,$i) != [GetProjectPath $project] } {
		  # The path for the project has changed
		  lappend dif_projs $i
	      }
	  }
      }
      # Look for deleted projects
      # These are projects that are no longer in the user's list
      foreach project $array(PROJECT_LIST) {
	  set delete 1
	  for { set i 1 } { $i <= $nprojects } { incr i } {
	      if { $project == $array(PROJECT_ALIAS,$i) } {
		  set delete 0
		  break
	      }
	  }
	  if { $delete } {
	      lappend del_projs $project
	  }
      }

      # Do the updates
      # Deleted projects
      foreach project $del_projs {
	  if { $project == [GetCurrentProject] } {
	      # If we're not in init mode then this is an error
	      if { ! $array(INIT_MODE) } {
		  WarningMessage "ERROR

You are trying to delete the project

\"$project\"

but CCP4i is currently using this project."
		  incr ierror
	      }

	  } elseif { ![DeleteProject $project] } {
	      WarningMessage "ERROR

Unable to successfully delete the project

\"$project\"

This may be because another application is
currently using it."
	      incr ierror
	  }
      }
      # New project definitions
      foreach i $new_projs {
	  set project $array(PROJECT_ALIAS,$i)
	  if { ![AddProject $project $array(PROJECT_PATH,$i)] } {
	      WarningMessage "Error adding project \"$project\"
with directory
\"$array(PROJECT_PATH,$i)\""
	      incr ierror
	  }
      }
      # Updated projects
      foreach i $dif_projs {
	  # Special case: if there are no real projects defined
	  # this is permissible
	  if { [llength [ListProjects]] == 0 } {
	      # This is really an addition
	      if { ![AddProject $project $array(PROJECT_PATH,$i)] } {
		  WarningMessage "ERROR

Unable to add the project \"$project\"
with directory

\"$array(PROJECT_PATH,$i)\""
		  incr ierror
	      }
	  } else {
	      set project $array(PROJECT_ALIAS,$i)
	      # Check - we shouldn't do this for the current project
	      if { $project == [GetCurrentProject] } {
		  WarningMessage "ERROR

You are trying to change the directory of
the project

\"$project\"

but CCP4i is currently using this project."
		  incr ierror
	      } else {
		  # Prompt the user and tell them you think that this
		  # may not be a great idea
		  if { [regexp OK [ChooseOptionDialog "Changing Project Dir" \
				       "Project Dir" \
				       "You are trying to change the location of the
project directory

\"$project\"

Changing this may have undesirable side effects
when reviewing or rerunning old jobs.

Do you still wish to make this change?" \
				       [list OK Dismiss] -default 1]] } {
		      if { ![SetProjectPath $project $array(PROJECT_PATH,$i)] } {
			  # Failed to make the change
			  WarningMessage "ERROR

Unable to change the directory of project
\"$project\"

to
\"$array(PROJECT_PATH,$i)\"

This may be because the project is currently
being used by another program."
			  incr ierror
		      }
		  } else {
		      # Reset the path to the original value
		      set array(PROJECT_PATH,$i) [GetProjectPath $project]
		      incr ierror
		  }
	      }
	  }
      }

      # Determine what changes the user made to the defdirs
      set new_defdirs {}
      set del_defdirs {}
      set dif_defdirs {}
      
      # Explicitly update each of the defdirs from the array
      set ndefdirs $array(N_DEF_DIRS)
      for { set i 1 } { $i <= $ndefdirs } { incr i } {
	  set defdir $array(DEF_DIR_ALIAS,$i)
	  if { [lsearch $array(DEF_DIR_LIST) $defdir] < 0 } {
	      # New defdir definition
	      lappend new_defdirs $i
	  } else {
	      # Check for changes to the directory
	      if { $array(DEF_DIR_PATH,$i) != [GetDefdirPath $defdir] } {
		  # The path for the defdir has changed
		  lappend dif_defdirs $i
	      }
	  }
      }
      # Look for deleted defdirs
      # These are aliases that are no longer in the user's list
      foreach defdir $array(DEF_DIR_LIST) {
	  set delete 1
	  for { set i 1 } { $i <= $ndefdirs } { incr i } {
	      if { $defdir == $array(DEF_DIR_ALIAS,$i) } {
		  set delete 0
		  break
	      }
	  }
	  if { $delete } {
	      lappend del_defdirs $defdir
	  }
      }

      # Do the updates
      # Deleted defdirs
      foreach defdir $del_defdirs {
	  if { ![DeleteDefdir $defdir] } {
	      WarningMessage "ERROR

Unable to successfully delete data directory

 \"$defdir\""
	      incr ierror
	  }
      }
      # New defdir definitions
      foreach i $new_defdirs {
	  set defdir $array(DEF_DIR_ALIAS,$i)
	  if { ![AddDefdir $defdir $array(DEF_DIR_PATH,$i)] } {
	      WarningMessage "ERROR

Unable to add data directory \"$defdir\"
with directory

\"$array(DEF_DIR_PATH,$i)\""
	  }
	  incr ierror
      }
      # Updated defdirs
      foreach i $dif_defdirs {
	  set defdir $array(DEF_DIR_ALIAS,$i)
	  if { [regexp OK [ChooseOptionDialog "Changing Data Dir" "Data Dir" \
			       "You have changed the location for the data directory
\"$defdir\"

which may have side effects for rerunning old jobs.

Do you wish to continue?" \
			       [list OK Dismiss] -default 1]] } {
	      SetDefdirPath $array(DEF_DIR_ALIAS,$i) $array(DEF_DIR_PATH,$i)
	  } else {
	      # Reset the path to the original value
	      set array(DEF_DIR_PATH,$i) [GetDefdirPath $defdir]
	  }
      }

      # Verify selected project is still valid
      set projects [ListProjects]
      if { [lsearch $projects $array(SELECTED_PROJECT)] < 0 } {
	  if { [llength $projects] > 0 } {
	      set array(SELECTED_PROJECT) [lindex $projects 0]
	  }
      }

      # Attempt to change to new project
      if { ![DbChangeFile $array(SELECTED_PROJECT) ] } { return }
      DbGetCurrentProject project
      SwitchProject $project $system(SWITCH_MENU)
      # Reset init mode flag
      set array(INIT_MODE) 0
  }

  # Update or close the window
  directories_update_window $mode $arrayname $w $ierror
}

#-----------------------------------------------------------------------
proc apply_directories_init { mode arrayname w } {
#-----------------------------------------------------------------------
#d_sum Apply user changes to the projects for a new user
#d_desc This is a specialised version of apply_directories which is \
used when a user sets up their projects on the first run of CCP4i. \
Subsequently the code in the main body of apply_directories will be \
used.
#d_arg mode One of quit, apply or save
#d_arg arrayname Name of the array with the directories data
#d_arg w The name of the directories window

  upvar #0 $arrayname array
  global system

  # In init mode everything the user has should be new
  set new_projects 0
  set ierror 0

  # Add projects
  set nprojects $array(N_PROJECTS)
  for { set i 1 } { $i <= $nprojects } { incr i } {
      set project [string trim $array(PROJECT_ALIAS,$i)]
      set project_path [string trim $array(PROJECT_PATH,$i)]
      if { $project != "" && $project_path != "" } {
	  if { ![AddProject $project $project_path] } {
	      set ierror 1
	  } else {
	      incr new_projects
	  }
      }
  }

  # Add the defdirs
  set ndefdirs $array(N_DEF_DIRS)
  for { set i 1 } { $i <= $ndefdirs } { incr i } {
      set defdir $array(DEF_DIR_ALIAS,$i)
      set defdir_path $array(DEF_DIR_PATH,$i)
      if { $defdir != "TEMPORARY" } {
	  if { ![AddDefdir $defdir $defdir_path] } {
	      # Error adding the defdir
	      set ierror 1
	  }
      }
  }

  # Did any projects get added?
  if { $new_projects == 0 } {
      WarningMessage "No projects were added!"
  }
  if { $new_projects != $nprojects } {
      # Fewer projects added than expected
      set ierror 1
  }
  
  # Check the selected project
  set projects [ListProjects]
  if { [lsearch  $projects $array(SELECTED_PROJECT)] < 0 } {
      set array(SELECTED_PROJECT) [lindex $projects 0]
  }

  # Attempt to change to new project
  # Set the current project to blank, to fool DbChangeFile
  # into opening it for us
  SetCurrentProject {}
  if { ![DbChangeFile $array(SELECTED_PROJECT) ] } { return }
  DbGetCurrentProject project
  SwitchProject $project $system(SWITCH_MENU)

  # Reset init mode flag
  set array(INIT_MODE) 0

  # Update or close the window
  directories_update_window $mode $arrayname $w $ierror
}

#-----------------------------------------------------------------------
proc directories_update_window { mode arrayname w { redraw 0 } } {
#-----------------------------------------------------------------------
#d_sum Update, redraw or exit the directories window
#d_desc This command is invoked to update the directories window after \
changes have been applied, or to close it.
#d_desc If the redraw flag is set to a non-zero value then this will \
force the directories window to be destroyed and regenerated from \
scratch. Otherwise the window is just updated.
#d_arg mode One of quit, apply or save
#d_arg arrayname Name of the array with the directories data
#d_arg w The name of the directories window
#d_arg redraw (Optional) Completely redraw the window rather just \
updating it.

  global system
  upvar #0 $arrayname array

  # Deal with the window
  if { ![regexp apply $mode ] } {
      CloseWindow $arrayname
      if {[regexp directories $system(RUN_MODE) ]} { exit } 
  } else {
      if { $redraw } {
	  # Some error occured, so the window contents are no longer
	  # in sync with the actual data - completely destroy and redraw
	  # the window to "resynchronise"
	  CloseWindow $arrayname
	  Directories
      } else {
	  # Do a basic update of the window data
	  run_update_script $arrayname
	  update_main_scroll $w
	  set array(PROJECT_LIST) [ListProjects]
	  set array(DEF_DIR_LIST) [ListDefdirs]
      }
  }
}

#-----------------------------------------------------------------------
proc make_one_word { arrayname  var } {
#-----------------------------------------------------------------------
#d_sum Force all project and directory aliases to be one word
#d_desc And remove disallowed characters
#d_arg arrayname Name of the data array (probably 'directories')
#d_arg var Name of the array element containing the alias

  upvar #0 $arrayname array
  set array($var) [RemoveMetaChars $array($var)]
}

#-----------------------------------------------------------------------
proc init_mg_directories { } {
#-----------------------------------------------------------------------
#d_sum Invoked on MG startup to ensure MG_CURRENT_PROJECT parameter exists
  global ccp4i_status
  if { ![ElementExists ccp4i_status MG_CURRENT_PROJECT] } { 
    set ccp4i_status(MG_CURRENT_PROJECT) $ccp4i_status(CURRENT_PROJECT)
    lappend ccp4i_status(PARAM_LIST) MG_CURRENT_PROJECT
  } elseif { [StringSame $ccp4i_status(MG_CURRENT_PROJECT) "PROJECT"] &&
      ![StringSame $ccp4i_status(CURRENT_PROJECT) "PROJECT"] } {
    set ccp4i_status(MG_CURRENT_PROJECT) $ccp4i_status(CURRENT_PROJECT)
  }
}
