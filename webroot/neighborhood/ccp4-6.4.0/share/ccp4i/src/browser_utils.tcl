#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#=========================================================================#
# CCP4 Interface browser_utils.tcl
#
#
# Browser utilities 
#
#=========================================================================

#d_index_title Utilities for CCP4i Main Window (src/browser_utils.tcl)
#d_intro Some utilities for CCP4i run in 'browser' i.e. normal graphical mode.

#------------------------------------------------------------------------
proc update_module_menu { m arrayname } {
#------------------------------------------------------------------------
#d_sum Populate the menu of available modules
#d_sum This creates entries in a menu corresponding to the modules loaded \
in to a data structure. Any existing entries are first deleted from the \
menu.
#d_arg m         Name of the widget with the menu
#d_arg arrayname Name of the array with the data structure (usually called \
moduledef)
  # Delete any existing entries
  $m delete 0 end
  # Populate the menu
  foreach item [ListModules $arrayname] {
      if { $item != "<separator>" } {
	  $m add command -label "[GetModuleDesc $arrayname $item]"  \
	      -command "update_module \"[GetModuleDesc $arrayname $item]\" $arrayname"
      } else {
	  $m add separator
      }
  }
  return 1
}   

#------------------------------------------------------------------------
proc GetTaskFile { taskname } {
#------------------------------------------------------------------------
#d_sum Get the Tcl file associated with a task
#d_desc This command looks up the name of the Tcl file that is associated \
with a taskname, and returns the full path to the task file (or a blank \
string if no Tcl is found).
#d_arg taskname The name of the task for which the task file is required 
    foreach modulename [list tasks sketch] {
	if { [file exists \
		  [set filen [SearchPath TOP $modulename $taskname.tcl]]] } {
	    return $filen
	}
    }
    return {}
}

#------------------------------------------------------------------------
proc GetRunCmd { taskname { title "" } } {
#------------------------------------------------------------------------
#d_sum Return the command for running a task
#d_desc Given the name of a task, return the command that should be \
executed to launch that task. The procedure checks that the task has an \
associated Tcl file, and if this is not found goes on to check whether \
the task is actually a utility program.
#d_desc If the taskname does reference either a valid task or a valid \
utility then this command returns an empty string.
#d_arg taskname The name of the task to get the command for
#d_arg title    (Optional) A title to be used for utilities
    global configure
    if { [file exists [GetTaskFile $taskname] ] } {
	# Normal task - return default format
	return "RunTask $taskname"
    }
    # No taskname.tcl found so maybe this is a utility
    # Utilities are referenced generally using "run_<utility>"
    set run_command {}
    if { [regexp ^run_ $taskname] } {
	# The preferred method of running a utility is via the
	# equivalent RUN_<UTILITY> in configure, if it exists
	set run_param [string toupper $taskname]
	if { [llength [array names configure $run_param]] == 1 } {
	    set run_command $configure($run_param)
	} else {
	    # Assume we can run the utility using
	    # <utility> as the command name
	    regexp ^(run_)(.*) $taskname m0 m1 run_command
	}
	# Generate the full RunUtility command
	if { $title == "" } { set title $taskname }
	set run_command "RunUtility \"$title\" \{ $run_command \}"
    }
    return $run_command
}

#------------------------------------------------------------------------
proc ReadTaskList { arrayname filnam } {
#------------------------------------------------------------------------
#d_sum Read the etc/$OPSYS/modules and $USER/.CCP4/$OPSYS/modules files 
#d_desc Load the list of modules and tasks into the moduledef array
#d_desc Modules and tasks are first loaded from the main CCP4i modules file \
and additional modules and/tasks are then read from the user's personal \
modules file (if it exists) and are appended to those already loaded.
#d_desc ASIDE (1): The user's .CCP4 area has subdirectories unix/windows \
where modules files are stored - in the main CCP4i area these directories \
are UNIX/WINDOWS.
#d_desc ASIDE (2): There is currently an issue that the 'internal' name of \
a task which is used for task file names etc. is also the task name seen by \
the user in the job list.  It would be better if the modules file \
had a separate definition of the 'user visible' task name.
#d_arg filnam Name of the 'modules file
#d_arg arrayname Name of array to contain data (usually moduledef)

  global system
  upvar #0 $arrayname array

  # Clear out the array
  array unset $arrayname *

  # Initialise an array modules_data from the main CCP4i modules.def file
# set filn [SearchPath TOP etc $system(OPSYS) $filnam.def]
  set filn [SearchPath TOP etc $filnam.def]
  global modules_data
  InitialiseArray $filn modules_data modules
  BuildModulesDataStruct modules_data $arrayname
  # Delete the array - we've finished with it now
  if {[info exists modules_data]} { unset modules_data }

  # Read from the user's local module file, if it exists
  # The .CCP4 directory is stored as DOT
  set dot [GetSystemVar DOT]

  # Need to convert the OPSYS to lower case - use a switch
  # statement for now
  switch $system(OPSYS) {
      UNIX { set opsys unix }
      WINDOWS { set opsys windows }
  }
  set filn [file join $dot $opsys $filnam.def]
  if { [file exists $filn] } {
      # Read in the data
      global user_modules
      InitialiseArray $filn user_modules user_modules -nocheck
      BuildModulesDataStruct user_modules $arrayname
      # Delete the array - we've finished with it now
      if {[info exists user_modules]} { unset user_modules }
  } 
  return 1
}

#-------------------------------------------------------------------------
proc UpdateModulesList { modulesname arrayname } {
#-------------------------------------------------------------------------
#d_sum Update the lists of modules and tasks
#d_desc To be filled in by pjx
#d_arg modulesname Name of the array initialise from the modules.def file
#d_arg arrayname Name of array to contain data (usually moduledef)
    upvar #0 $arrayname   array
    upvar #0 $modulesname modules

    set nmodules [llength $modules(MODULE_LIST)]
    #puts "No of modules in list is $nmodules"
    #puts "No of modules defined in the file is $modules(N_MODULES)"
    #puts "No of tasks in the file is $modules(N_TASKS)"

    if {![info exists array(MODULE_LIST)]} { set array(MODULE_LIST) "" }

    for {set i 0} {$i < $nmodules} {incr i} {
	set module_name [lindex $modules(MODULE_LIST) $i]
	#puts "Module $i is $module_name"
	# Check that this module doesn't already exist
	if {[lsearch $array(MODULE_LIST) $module_name] < 0} {
	    set module_exists 0
	} else {
	    set module_exists 1
	}
	# Loop over actual modules to find a match
	for {set j 1} {$j <= $modules(N_MODULES)} {incr j} {
	    if {$modules(MODULE_NAME,$j) == $module_name} {
		#puts "Found module $module_name: number $j"
		if {$module_exists == 0} {
		    # New module - add to the list
		    set module_title $modules(MODULE_TITLE,$j)
		    lappend array(MODULE_LIST) $module_name
		    lappend array(MODULE_TITLE_LIST) $module_title
		    set array([subst $module_name]_NTASKS) 0
		} else {
		    #puts "Module $module_name already exists - not being added"
		}
		#puts "Module list now: $array(MODULE_LIST)"
		#puts "Title list now : $array(MODULE_TITLE_LIST)"

		# Build/update task list for this module
		#puts "Tasks in this module: $modules(MODULE_TASK_LIST,$j)"
		set ntasklist [llength $modules(MODULE_TASK_LIST,$j)]
		# Loop over the tasks in this module and try to sort them
		# out
		for {set ii 0} {$ii < $ntasklist} {incr ii} {
		    set task_title [lindex $modules(MODULE_TASK_LIST,$j) $ii]
		    #puts "Task $ii is called $task_title"
		    # Check that this task doesn't already exist
		    set ntasks $array([subst $module_name]_NTASKS)
		    set task_exists 0
		    for {set jj 1} {$jj <= $ntasks} {incr jj} {
			set test_title $array([subst $module_name]_TASK_TITLE_$jj)
			#puts "Comparing with task name $jj ($test_title)"
			if { $task_title == $test_title } { set task_exists 1 }
		    }
		    # Task doesn't already exist, so try to add it
		    if { $task_exists == 0 } {
			# First - find the information in the file
			for {set jj 1} {$jj <= $modules(N_TASKS)} {incr jj} {
			    if {$modules(TASK_TITLE,$jj) == $task_title && \
				[lsearch -exact $modules(TASK_MODULE,$jj) \
				$module_name] > -1 } {
				#puts "Found task $task_title: number $jj"
				# Get the correct alias and description for
				# this task in this module
				set task_name $modules(TASK_NAME,$jj)
				set task_message $modules(TASK_DESCRIPT,$jj)
				#puts "For task $task_name:"
				#puts "----> Title: $task_title"
				#puts "----> Message: $task_message"
				incr array([subst $module_name]_NTASKS)
				set ntasks $array([subst $module_name]_NTASKS)
				set array([subst $module_name]_TASK_NAME_$ntasks) \
					$task_name
				set array([subst $module_name]_TASK_TITLE_$ntasks) \
					$task_title
				set array([subst $module_name]_TASK_STATUS_$ntasks) 0
				set array([subst $module_name]_TASK_MESSAGE_$ntasks) \
					$task_message
			    }
			    # End of tasks
			}
			# End of loop over all task references
		    }
		    # End of if-statement for new task
		}
		# End of loop over list of tasks in module
	    }
	    # End of block for particular module
	}
	# End of loop over all modules in file
    }
    # End of loop over all modules in list
    return 1
}

#-------------------------------------------------------------------------
proc  CreateTaskBrowser { input_project input_title window arrayname } {
#-------------------------------------------------------------------------
#d_sum Draw the main graphical window of ccp4i
#d_arg input_project Name of input project - used in window title
#d_arg input_title Additional input title used in communication dialog box
#d_arg window The Tk window id
#d_arg arrayname The module/task array (usually called moduledef)

  global configure
  global system
  upvar #0 $arrayname array

  wm withdraw $window
  wm title $window "$system(VERSION)"
  wm iconname $window $input_project
  wm iconbitmap $window @[SearchPath TOP icons window_icon]
  wm  protocol $window WM_DELETE_WINDOW ConfirmExitInterface
  focus $window

# Define the overall layout of the window

  set module .module
  frame $module
  grid $module 			-row 0 -column 0 -sticky nsew
  grid rowconfigure $window 0 		-weight 1
  grid columnconfigure $window 0	-weight 1

#  set title [frame $module.title]
  set mesbar [frame $module.mesbar ]
  set menu [ frame $module.menu -relief ridge -borderwidth 1 ]
  set listj [frame $module.listj -relief ridge -borderwidth 1 ]
  set right [frame $module.right -relief ridge -borderwidth 1 ]

#  grid .module.title 	-row 0 -column 0 -columnspan 3 -sticky we
  grid .module.mesbar 	-row 0 -column 0 -columnspan 3 -sticky we
  grid .module.menu 	-row 1 -column 0 -sticky ns
  grid .module.listj 	-row 1 -column 1 -sticky nsew
  grid .module.right 	-row 1 -column 2 -sticky ns

  grid columnconfigure .module 0 	-weight 0
  grid columnconfigure .module 1  -weight 1
  grid columnconfigure .module 2 	-weight 0
#  grid rowconfigure .module 0 	-weight 0
  grid rowconfigure .module 0 	-weight 0
  grid rowconfigure .module 1 	-weight 1


#==========================================================================

# Draw the title and the message bar

  # Help button
  menubutton $module.mesbar.help      -text "Help"\
			-font $configure(FONT_REGULAR) \
                        -relief raised \
                        -padx 7 -pady 2 -borderwidth 1  \
			-menu $module.mesbar.help.m

  # Menu for different help topics
  # Each topic is represented by an entry in the list, with a title
  # and a target URL
  # Blank titles will be treated as separators
  set help_topics [list \
	  [list "Welcome to CCP4i" "[SearchPath HELP index.html ]"] \
	  [list "" ""] \
	  [list "General help" "[SearchPath HELP guiframeset.html ]"] \
	  [list "Using CCP4i" "[SearchPath HELP general intro.html ]"] \
	  [list "Modules and Tasks" "[SearchPath HELP modules index.html ]"] \
	  [list "Roadmaps through CCP4" "[SearchPath HELP roadmaps index.html ]"] \
	  [list "CCP4 Tutorial" \
	  "[SearchPath CCP4 examples tutorial html index.html ]"] \
	  [list "" ""] \
	  [list "CCP4 Program Index" "[SearchPath CCP4 html INDEX.html ]"] \
	  [list "Programmers docs" "[SearchPath HELP programmers progframeset.html ]"]]

  set helpmenu [menu $module.mesbar.help.m -tearoff 0]
  foreach topic $help_topics {
      set title [lindex $topic 0]
      if { $title != "" } {
	  set url [lindex $topic 1]
	  $helpmenu add command -label "$title" \
		  -command "open_url $url" \
		  -font $configure(FONT_REGULAR)
      } else {
	  # Add a separator for a blank topic
	  $helpmenu add separator
      }
  }

  $helpmenu add separator
  $helpmenu add command \
     -font $configure(FONT_REGULAR) \
     -command "open_url http://www.ccp4.ac.uk/reportaprob.php -remote" \
     -label "Contact CCP4 BB and Help Desk"

  pack $module.mesbar.help -side right -fill y
  SetMessage $arrayname $module.mesbar.help "Open HTML help file"

  #Adding a quick way to switch between different projects.
  menubutton $module.mesbar.switchProj -text "Change Project"\
             -relief raised -padx 7 -pady 2 -borderwidth 1  \
             -font $configure(FONT_REGULAR) -menu $module.mesbar.switchProj.m
  pack $module.mesbar.switchProj -side right -fill y
  set me [menu $module.mesbar.switchProj.m -tearoff 0] 
  set system(SWITCH_MENU) $module.mesbar.switchProj.m
  DbGetCurrentProject project
  build_project_shortcut_menu $project $me
  SetMessage $arrayname $module.mesbar.switchProj "Switch between CCP4i projects"

  label $module.mesbar.l1 \
			-textvariable [subst $arrayname](MESSAGEVAR)  \
			-font $configure(FONT_REGULAR) \
			-relief raised -fg $configure(COLOUR_BOLD)  \
			-bg $configure(COLOUR_CONTRAST)\
			-anchor w
  pack $module.mesbar.l1 	-side left  -fill both -expand 1

  set_message $arrayname " " -unblock
  SetMessage $arrayname $module.mesbar.l1   "Message line help"


#===========================================================================

# Define the layout of the menu list and buttons

#  set top 	[frame $menu.top ]
#  set db 	[frame $menu.db ]
  set module 	[frame $menu.module ]
  set action 	[frame $menu.action -background $configure(COLOUR_VERY_PALE) ]
#  set bot 	[frame $menu.bot ]

#  grid $top 		-row 0 -column 0 -sticky ew
#  grid $db 		-row 1 -column 0 -sticky ew
  grid $module		-row 0 -column 0 -sticky ew
  grid $action 		-row 1 -column 0 -sticky nsew
#  grid $bot 		-row 4 -column 0 -sticky ew

#  grid rowconfigure $menu 0 	-weight 0
#  grid rowconfigure $menu 1 	-weight 0
  grid rowconfigure $menu 0 	-weight 0
  grid rowconfigure $menu 1 	-weight 1
#  grid rowconfigure $menu 4 	-weight 0
  grid columnconfigure $menu 0 	-weight 1

#============================================================================

  menubutton $module.mb	-textvariable [subst $arrayname](CURRENT_MODULE_TITLE) \
			-font $configure(FONT_REGULAR) \
			-menu $module.mb.m \
			-foreground $configure(COLOUR_BOLD) \
			-activeforeground $configure(COLOUR_BOLD) \
                        -background $configure(COLOUR_CONTRAST) \
                        -activebackground $configure(COLOUR_CONTRAST) \
			-relief raised \
			-indicatoron 1 \
			-width 34 \
                        -padx 2 -pady 2 -borderwidth 1 


  menu $module.mb.m 	-tearoff 0  \
                        -foreground $configure(COLOUR_BOLD) \
			-font $configure(FONT_REGULAR) \
                        -activeforeground $configure(COLOUR_BOLD) \
                        -background $configure(COLOUR_CONTRAST) \
                        -activebackground $configure(COLOUR_CONTRAST)

  # Populate the modules menu
  update_module_menu $module.mb.m $arrayname

  SetMessage $arrayname $module.mb "Choose module"
  bind $module.mb <Button-3> "module_help $arrayname"
  pack $module.mb -side left -fill x -expand 1

#===========================================================================

#The task list for a browser

  scrollbar $action.scroll -command [list $action.canvas yview]

  canvas $action.canvas   -yscrollcommand  [list $action.scroll set] \
                        -height 5 -width 25\
                        -selectbackground $configure(COLOUR_CONTRAST) \
                        -background $configure(COLOUR_VERY_PALE)

  pack $action.scroll     -side right -fill y

  pack $action.canvas     -side left -fill both -expand 1

  set frame [frame $action.canvas.frame -width 30 ]
  $action.canvas create window 0 0 -window $frame

  SetSystemVar TASKLISTFRAME $frame

  update_module $array(CURRENT_MODULE_TITLE) $arrayname 

#  UpdateTaskList $arrayname CURRENT_MODULE


#================================================================text Window

#The list of database jobs

#  set dblist [frame $listj.dblist]
   set dblist $listj
#  set report [frame $listj.report]

#  grid $dblist          -row 0 -column 0 -sticky nsew
#  grid $report          -row 1 -column 0 -sticky ew

#  grid rowconfigure $listj 0     -weight 1
#  grid rowconfigure $listj 1     -weight 0
#  grid columnconfigure $listj 0  -weight 1


  listbox $dblist.list    -yscroll "$dblist.scrolly set" \
                        -xscroll "$dblist.pad.scrollx set" \
                        -height 20 -width 50 -setgrid true \
			-font $configure(FONT_FIXED) \
                        -selectbackground $configure(COLOUR_CONTRAST) \
                        -selectmode extended

  scrollbar $dblist.scrolly      -command "$dblist.list yview"
  frame $dblist.pad
  scrollbar $dblist.pad.scrollx  -orient horizontal \
                                -command "$dblist.list xview"

  set pad [expr {[$dblist.scrolly cget -width] +2* \
          ([$dblist.scrolly cget -bd ] + \
	   [$dblist.scrolly cget -highlightthickness ])}]
  frame $dblist.pad.it           -width $pad -height $pad

  pack $dblist.pad               -side bottom -fill x
  pack $dblist.pad.it            -side right
  pack $dblist.pad.scrollx       -side bottom -fill x
  pack $dblist.scrolly           -side right -fill y
  pack $dblist.list              -side left -expand true -fill both

  bind $dblist.list <ButtonRelease-1> "db_handle_selection select %W"
  bind . <KeyRelease-F2> "db_handle_selection clear %W"
  bind $dblist.list <Shift-Double-Button-1> "db_handle_shiftdoubleclick"
  bind $dblist.list <Double-Button-1> "db_handle_doubleclick"

  SetMessage $arrayname $dblist.list  \
      "List of jobs for project. Double-click on a job displays the log file, shift-double-click reruns the job."

  # Right mouse click to context menu for interacting with the job db
  bind $dblist.list <Button-3> "db_context_menu %W %X %Y %y"

  SetSystemVar DBLISTFRAME $dblist.list

  $dblist.list insert end "Loading database..."

#-------------------------------------------------------report frame 

#  text $report.text    -yscroll "$report.scrolly set" \
#                        -height 5 -width 50 -setgrid true \
#			-font $configure(FONT_SMALL) \
#                        -selectbackground $configure(COLOUR_CONTRAST) \
#			-state disabled
#
#  $report.text tag configure texttag \
#                -wrap word
#
#  scrollbar $report.scrolly      -command "$report.text yview"
#
#  pack $report.scrolly		-side right -fill y
#  pack $report.text		-side left -expand true -fill both
#
#  SetMessage $arrayname  $report.text \
#	"Progress reports and error messages window"
#
#  bind $dblist.list <Button-3> \
#   "KeywordHelp [SearchPath HELP general intro.html] main_window"
#
#  SetSystemVar REPORTFRAME $report.text

#--------------------------------------------------------------database menu

  set top [frame $right.top]
  set dbmenu [frame $right.dbmenu]
  set bot [frame $right.bot]

  grid $top          -row 0 -column 0 -sticky ew
  grid $dbmenu       -row 1 -column 0 -sticky nsew
  grid $bot          -row 2 -column 0 -sticky ew

  grid rowconfigure $right 0     -weight 0
  grid rowconfigure $right 1     -weight 1
  grid rowconfigure $right 2     -weight 0
  grid columnconfigure $right 0  -weight 1

#--------------------------------------------------------------------------------------------
# Draw the menu list and buttons

#  menubutton $top.pref  -text "Preferences"     \
#			-indicatoron 1 \
#			-borderwidth 1 -relief raised \
#                        -menu $top.pref.m1
#
#  menu $top.pref.m1 -tearoff 0  -transient 1
#  $top.pref.m1 add command -label "Interface" \
#    -command "RunTask preferences -system"
#  $top.pref.m1 add command -label "$input_project Programs" \
#    -command "RunTask [subst $input_project]_preferences -array preferences"
#
#  SetMessage $arrayname  $top.pref  \
#	"Set preferences for user interface"
#
#  pack $top.pref -side top -fill x -expand 1


  button $top.projects -text "Directories&ProjectDir" \
			-font $configure(FONT_REGULAR) \
			-borderwidth 1 -relief raised \
			-command  Directories

  pack $top.projects -side top -fill x -expand 1

  SetMessage $arrayname $top.projects \
	"Set directory alias or change default project directory"

  bind $top.projects <Button-3> \
   "KeywordHelp [SearchPath HELP general database.html] setup"

  button $top.viewer -text "View Any File" \
			-font $configure(FONT_REGULAR) \
                        -borderwidth 1 -relief raised \
                        -command  "FileViewer"

  pack $top.viewer -side top -fill x -expand 1

  SetMessage $arrayname $top.viewer \
	"Display file contents for any file"
  bind $top.viewer <Button-3> \
	"KeywordHelp [SearchPath HELP general fileviewer.html]"

# This button is removed
  button $bot.comments  -text "Mail CCP4" \
			-font $configure(FONT_REGULAR) \
                        -borderwidth 1 -relief raised \
                        -command "MailHandler"

  SetMessage $arrayname $bot.comments  \
	"Please mail questions/bugs/comments to CCP4I developer"

  button $bot.exit      -text "Exit" \
			-font $configure(FONT_REGULAR) \
                        -borderwidth 1 -relief raised \
                        -command "ConfirmExitInterface exitbutton"

  SetMessage $arrayname $bot.exit  \
	"Exit from $input_title"

#---------------------------------------------------------------------------
  label $bot.available_updates -text {} \
    -font $configure(FONT_ITALIC)

#   -font $configure(FONT_REGULAR)

  button $bot.manage_updates \
    -text "Manage Updates" \
    -font $configure(FONT_REGULAR) \
    -borderwidth 1 -relief raised

  SetMessage $arrayname $bot.manage_updates   \
    "Check for, install or uninstall updates"

  frame $bot.space -borderwidth 1 -relief raised -height 4

  grid $bot.space             -column 0 -row 0 -columnspan 2 -sticky sew
  grid $bot.available_updates -column 0 -row 1 -columnspan 2 -sticky nsew
  grid $bot.manage_updates    -column 0 -row 2 -sticky nsew
  grid $bot.exit              -column 1 -row 2 -sticky nsew
  grid columnconfigure $bot 0 -weight 2 -uniform 0
  grid columnconfigure $bot 1 -weight 1 -uniform 0

  source [file join [GetEnvPath CCP4I_TOP] src ccp4_updates.tcl]
  ::CCP4_Updates::initialise $bot.available_updates $bot.manage_updates [GetTmpFileName]

#---------------------------------------------------------------------------
  scrollbar $dbmenu.scroll -command [list $dbmenu.canvas yview]

  canvas $dbmenu.canvas   -yscrollcommand  [list $dbmenu.scroll set] \
                        -height 5 -width 25\
                        -selectbackground $configure(COLOUR_CONTRAST) \
                        -background $configure(COLOUR_VERY_PALE)

  pack $dbmenu.scroll     -side right -fill y

  pack $dbmenu.canvas     -side left -fill y

  set frame [frame $dbmenu.canvas.frame]
  $dbmenu.canvas create window 0 0 -anchor nw -window $frame

  SetSystemVar DBOPTIONFRAME $frame

  focus $window
  wm deiconify $window

#---------------------------------------------------------------------------
  update idletasks

}

#------------------------------------------------------------------------
proc module_help { arrayname } {
#------------------------------------------------------------------------
#d_sum Handle user clicking for help on the Module menu
#d_desc Go to the help page for the currently open module
  upvar #0 $arrayname array
  KeywordHelp [SearchPath HELP modules $array(CURRENT_MODULE).html]
}

#------------------------------------------------------------------------
proc update_module { selection arrayname } {
#------------------------------------------------------------------------
#d_sum Update task menu when user changes modules
#d_arg selection New module
#d_arg arrayname  The module/task array (usually called moduledef)

  upvar #0 $arrayname array
  global system
  global configure

# Set the array value to the value the user selected from the list

  set array(CURRENT_MODULE_TITLE) $selection
  set array(CURRENT_MODULE) [ReverseLookupModuleName $arrayname $selection]
  set module $array(CURRENT_MODULE)

  set frame [GetSystemVar TASKLISTFRAME]
  if { ![ winfo exists $frame ] } {  return }

  set enclose $frame.t
  if { ![winfo exists $enclose] } { 
    frame $enclose 
    pack $enclose -side top
  }

  set help_file [SearchPath HELP modules $array(CURRENT_MODULE).html ]
  set disabled_help_file \
	  [SearchPath HELP general additional.html ]

  # Bitmaps for tasks in folders
  set tbar [image create bitmap -file [SearchPath TOP icons Tbar.xbm]]
  set lbar [image create bitmap -file [SearchPath TOP icons Lbar.xbm]]

  # Acquire configuration option to show or hide tasks with missing
  # prerequisites, as determined by <task_name>_prereq
  set disable_mode $configure(DISABLE_TASKS)

  foreach item [winfo children $enclose ] { destroy  $item }

  # Build the display
  set n 0
  set open_folders {}
  set closed_folders {}

  foreach item [ListModuleContents $arrayname $module] {

      incr n

      if { [GetContentType $arrayname $module $item] == "FOLDER" } {
	  # Check that there are tasks in the folder
	  set ntasks [llength [ListFolderContents $arrayname $module $item]]
	  if { $ntasks == 0 } {
	      # Skip and go to the next one
	      continue
	  }   
	  # Make the folder title bar
          set f [frame $enclose.f_[subst $n] -relief ridge -borderwidth 1 \
		     -background $configure(COLOUR_PALE)]
	  frame $f.top -relief ridge \
	      -background $configure(COLOUR_PALE)
	  set icon [label $f.icon -bitmap \
			 @[SearchPath TOP icons arrow-closed.xbm] \
			 -background $configure(COLOUR_PALE)]
	  set label [label $f.label -text \
			 "[GetFolderTitle $arrayname $item]" \
			 -font $configure(FONT_ITALIC) \
			 -background $configure(COLOUR_PALE) \
			 -width 28 -anchor w]
	  set check [CreateCheckbutton $f.button \
			 -variable array(FOLDER_CHECK_[subst $module]_$item) \
			 -relief flat -anchor w \
			 -background $configure(COLOUR_PALE) \
			 -highlightbackground $configure(COLOUR_PALE) \
			 -activebackground $configure(COLOUR_PALE) \
			 -indicatoron 1 \
			 -onvalue "open" -offvalue "closed"]
	  pack $icon -side left
	  pack $label -side left
	  pack $check -side right
	  # Bind the background, icon and the label to activate the checkbutton
	  bind $f <Button-1> "$f.button invoke"
	  bind $icon <Button-1> "$f.button invoke"
	  bind $label <Button-1> "$f.button invoke"
	  # Add the bubblehelp to the folder title bar
	  SetMessage $arrayname $f "[GetFolderDesc $arrayname $item]"
	  # Make the containers for the list of tasks
	  set folder [ frame $enclose.f_[incr n] \
			  -background $configure(COLOUR_VERY_PALE)]
	  set tasks [ frame $folder.tasks]
	  set buttons [ frame $tasks.buttons ]
	  pack $buttons -side left
	  pack $tasks -side top -anchor e
	  # Check the visibility status
	  if { [GetFolderVisibility $arrayname $module $item] == "CLOSED" } {
	      # Don't display this folder
	      lappend closed_folders $folder
	      $check configure -command \
		  "open_module_folder $arrayname $module $item $frame $f $folder"
	      # Turn off the checkbutton for the folder
	      $check deselect
	  } else {
	      # Folder is open
	      lappend open_folders $folder
	      $check configure -command \
		  "close_module_folder $arrayname $module $item $frame $f $folder"
	      # Turn on the checkbutton for the folder
	      $check select
	      # Also update the icon
	      $icon configure -bitmap \
		  @[SearchPath TOP icons arrow-open.xbm]
	  }
	  # Build the list of tasks within the folder
	  set i 0
	  foreach taskid [ListFolderContents $arrayname $module $item] {
	      # Acquire the taskname
	      set task [GetTaskName $arrayname $taskid]
	      # Get the command to run this task
	      set run_cmd [GetRunCmd $task]
	      if { $run_cmd == "" } {
		  # No command so don't draw a button
		  continue
	      }
	      # Increment frame counter
	      incr i
	      # Frame to hold the button and the image
	      set f [ frame $buttons.f_[subst $i] ]
	      # Image of "connector"
	      if { $i < $ntasks } {
		  set connector $tbar
	      } else {
		  set connector $lbar
	      }
	      set l [ label $f.l_[subst $i] -image $connector  \
			 -background $configure(COLOUR_VERY_PALE) ]
	      # Deal with prerequisites
	      set prereq_status [check_task_prereq \
				     $task [GetTaskFile $task]]
	      if { $prereq_status || ! $disable_mode } {
		  # Configure a live button
		  set button_widget "button"
		  set button_font $configure(FONT_REGULAR)
		  set button_fg "black"
		  set button_command "$run_cmd"
		  set button_url "$help_file"
		  if { ! $prereq_status } {
		      set button_font $configure(FONT_ITALIC)
		  }
		  set button_message "[GetTaskDesc $arrayname $taskid]"
	      } else {
		  # Configure a disabled "button"
		  set button_widget "label"
#                 set button_font $configure(FONT_ITALIC)
                  set button_font $configure(FONT_REGULAR)
		  set button_fg $configure(COLOUR_DISABLED)
		  set button_command {}
		  set button_message \
		      "[GetTaskDesc $arrayname $task] (disabled)"
		  set button_url "$disabled_help_file"
	      }
	      # Make the basic button for the task
	      set b [ $button_widget $f.b_[subst $i] -text \
			  "[GetTaskTitle $arrayname $taskid]" \
			  -anchor w \
			  -font $button_font \
			  -foreground $button_fg \
			  -width 27 \
			  -borderwidth 1 -pady 2]
	      # Configure and pack the button
	      if { $button_command != "" && $button_widget == "button" } {
		  # Add the command, if specified
		  $b configure -command "$button_command"
	      }
	      if { $button_widget == "label" } {
		  # Additional configuration for the disabled button
		  $b configure -padx 12 -relief raised
	      }
	      SetMessage $arrayname $b $button_message
	      bind $b <Button-3> "open_url $button_url -target $task"
	      pack $l -side left -fill both -expand 1
	      pack $b -side left -fill both
	      pack $f -side top
	  }
	  # Add a "separator" at the bottom
	  # This is just an empty frame
	  set f [ frame $folder.separator -width 100 \
		      -height 4 -borderwidth 1 \
		      -background $configure(COLOUR_VERY_PALE)]
	  pack $f -side top -expand 1 -fill x 
      } else {
	  # Add a top-level task
	  set task [GetTaskName $arrayname $item]
	  # Get the command to run this task
	  set run_cmd [GetRunCmd $task]
	  if { $run_cmd == "" } {
	      # No command so don't draw a button
	      continue
	  }
	  # Deal with prerequisites
	  set prereq_status [check_task_prereq \
				 $task [GetTaskFile $task]]
	  if { $prereq_status || ! $disable_mode } {
	      # Configure a live button
	      set button_widget "button"
	      set button_font $configure(FONT_REGULAR)
	      set button_fg "black"
	      set button_command "$run_cmd"
	      set button_url "$help_file"
	      if { ! $prereq_status } {
		  set button_font $configure(FONT_ITALIC)
	      }
	      set button_message "[GetTaskDesc $arrayname $item]"
	  } else {
	      # Configure a disabled "button"
	      set button_widget "label"
#             set button_font $configure(FONT_ITALIC)
              set button_font $configure(FONT_REGULAR)
	      set button_fg $configure(COLOUR_DISABLED)
	      set button_command {}
	      set button_message \
		  "[GetTaskDesc $arrayname $item] (disabled)"
	      set button_url "$disabled_help_file"
	  }
	  # Make the basic button for the task
	  set f [ $button_widget $enclose.f_[subst $n] -text \
			  "[GetTaskTitle $arrayname $item]" \
			  -anchor w \
			  -font $button_font \
			  -foreground $button_fg \
			  -width 31 \
			  -borderwidth 1 -pady 2]
	  # Configure and pack the button
	  if { $button_command != "" && $button_widget == "button" } {
	      # Add the command, if specified
	      $f configure -command "$button_command"
	  }
	  if { $button_widget == "label" } {
	      # Additional configuration for the disabled button
	      $f configure -padx 12 -relief raised
	  }
	  SetMessage $arrayname $f $button_message
	  bind $f <Button-3> "open_url $button_url -target $item"
      }
  }

  # Pack the elements of the menu
  if { [llength [winfo children $enclose ] ] > 0 } {
      foreach w [winfo children $enclose ] {
	  if { [lsearch $open_folders $w] > -1 } {
	      # Display open folder
	      pack $w -side top -anchor e -fill x -expand 1
	  } elseif { [lsearch $closed_folders $w] < 0 } {
	      # Display other things that aren't closed
	      pack $w -side top -fill both
	  }
      }
  }

  update idletasks
  set canvas [winfo parent $frame]
  $canvas configure -scrollregion \
     [$canvas bbox all]
  $canvas configure -width [winfo width $frame] 
  $canvas yview moveto 0.0

}

#------------------------------------------------------------------------
proc open_module_folder { arrayname module name frame container folder } {
#------------------------------------------------------------------------
#d_sum Open a module folder by (re)packing it
#d_arg arrayname The module/task array (usually called moduledef)
#d_arg module The current module holding the folder
#d_arg name   The name of the folder
#d_arg frame  The containing frame widget name
#d_arg container The widget containing the title bar
#d_arg folder The frame widget holding the list of tasks in the folder

    pack $folder -after $container -side top -anchor e -fill x -expand 1
    $container.icon configure -bitmap \
	@[SearchPath TOP icons arrow-open.xbm]
    $container.button configure -command \
	"close_module_folder $arrayname $module $name $frame $container $folder"
    # Update the visibility
    SetFolderVisibility $arrayname $module $name "OPEN"
    # Update the scroll
    update_module_scroll $frame
}

#------------------------------------------------------------------------
proc close_module_folder { arrayname module name frame container folder } {
#------------------------------------------------------------------------
#d_sum Collapse a module folder by unpacking it
#d_arg arrayname The module/task array (usually called moduledef)
#d_arg module The current module holding the folder
#d_arg name   The name of the folder
#d_arg frame  The containing frame widget name
#d_arg container The widget containing the title bar
#d_arg folder The frame widget holding the list of tasks in the folder

    pack forget $folder
    $container.icon configure -bitmap \
	@[SearchPath TOP icons arrow-closed.xbm]
    $container.button configure -command \
	"open_module_folder $arrayname $module $name $frame $container $folder"
    # Update the visibility
    SetFolderVisibility $arrayname $module $name "CLOSED"
    # Update the scroll
    update_module_scroll $frame
}

#------------------------------------------------------------------------
proc update_module_scroll { frame } {
#------------------------------------------------------------------------
#d_sum Update the scrolling region of the tasklist
#d_desc When the tasklist is redrawn e.g. after  and reposition the view
#d_arg frame  The containing frame widget name
    update idletasks
    set canvas [winfo parent $frame]
    $canvas configure -scrollregion \
	[$canvas bbox all]
    $canvas configure -width [winfo width $frame] 
    if { [winfo height $frame] < [winfo height $canvas] } {
	$canvas yview moveto 0.0
    }
}

#-----------------------------------------------------------------------
proc check_task_prereq { taskname taskfile } {
#-----------------------------------------------------------------------
#d_sum Check for prerequisites for a task
#d_desc When building the task list, check each task file for a \
procedure called taskname_prereq, and if it is found then execute it. \
The procedure should return 1 if the task can be run and 0 if not.
#d_desc The task interface author should code the necessary checks \
(for example, ensuring that required program executables are available \
on the user's path) into the taskname_prereq procedure.
#d_arg taskname The name of the task
#d_arg taskfile The full path of the task file for this interface 

  if { ![file exists $taskfile] } {
    # The file is missing so return true
    return 1
  }
  source $taskfile
  set prereq_cmd "[subst $taskname]_prereq"
  if { [llength [info procs $prereq_cmd]] == 1 } {
    if { ![ catch { $prereq_cmd } status ] } {
      return $status
    } else {
      return 0
    }
  }
  return 1
}

#-----------------------------------------------------------------------
proc MailHandler { } {
#-----------------------------------------------------------------------
#d_sum Create mail window for interface
#d_desc For Unix systems, calls the MailtoDev procedure to produce \
the mailer window. On Windows, starts up a browser pointing to the \
CCP4 on-line help page (www.ccp4.ac.uk/reportaprob.html)
  global system
  if { [regexp WINDOWS $system(OPSYS)] } {
    # Windows - open a browser
    open_url "http://www.ccp4.ac.uk/reportaprob.html" -remote
  } else {
    # Unix - call MailtoDev procedure
    MailtoDev
  }
}

#-----------------------------------------------------------------------
proc MailtoDev { } {
#-----------------------------------------------------------------------
#d_sum Define the 'Mail CCP4' dialog box
#d_desc Calls the send_mail procedure to handle 'Send Mail' command
#d_desc Mail utility - based on the Disguise (CCP11) interface mailtool
  global configure
  global mail_window
  global mail

  set w .mail

  DefineVariable mail SUBJECT _text {}
  DefineVariable mail MAIL_TO _mail_to HELP
  DefineVariable mail ATTACH _mail_attach NO
  DefineVariable mail ATTACH_JOB _positiveint ""

  OpenWindow $w "Mail to CCP4" "Mail"
  CreateFrame $w mail -noscroll

# frame at bottom contains exit and send button

  CreateButton  $w quit "Quit" "unset mail; destroy $w"
  CreateButton $w send "Send Mail" "send_mail $w.main.canvas.contents.protocol.c.t"

# frame at top for instructions

  OpenFolder protocol

  CreateLine line \
    label "Mail to" \
    widget MAIL_TO

  CreateLine line \
    label Attach \
    widget ATTACH \
    label "for job number" \
    widget ATTACH_JOB

# subject line 
  CreateLine line \
    label "Subject" \
    widget SUBJECT -expand

  $line.e2 configure -font $configure(FONT_SMALL)

  CreateLine line \
    label "Enter message in box below then press 'Send Mail'" -italic


# frame to put textbox and scrollbar into
  
  set container [frame $w.main.canvas.contents.protocol.c \
		-relief sunken \
		-borderwidth 3  ]
  text $container.t \
	-relief sunken \
	-height 15 -width 70 \
        -font $configure(FONT_SMALL) \
   	-yscrollcommand "$container.s set" \
	-wrap word
  scrollbar $container.s \
	-relief flat \
	-orient vertical \
	-command {$mail_window yview}
  pack $container.s -side right -fill y
  pack $container.t -fill both -expand 1
  pack $container -fill both -expand 1

# set up bindings for textbox
# If pointer in window then focus is in textbox

  set mail_window $container.t
  bind $container.t <Any-Enter> {focus $mail_window}

}

#----------------------------------------------------------------------
proc send_mail  { w } {
#----------------------------------------------------------------------
#d_sum Handler for MailtoDev 'Send Mail' command
#d_desc Extract text and recipient from the 'Mail CCP4' dialog box \
Use the generic SendMail procedure to send the mail
  global system
  global mail
  set nattach 0
  set aliases [list HELP GUI BB]
  set adresses [list "ccp4@ccp4.ac.uk" "ccp4gui@ccp4.ac.uk" "ccp4bb@dl.ac.uk" ]

  set tmp_file [GetTmpFileName]
  set mail_address [lindex $adresses [lsearch $aliases [GetValue mail MAIL_TO]]]
  if { $mail(SUBJECT) == "" } { set mail(SUBJECT) "No subject entered" }

#  puts "tmp_file $tmp_file"
#  puts "mail_address $mail_address"

  set attach [GetValue mail ATTACH]
  if { ![StringSame $attach NO] } {
    if { $mail(ATTACH_JOB) == "" ||
          [set task [DbGetJobData $mail(ATTACH_JOB) TASKNAME]] == "" } {
      WarningMessage "You have opted to attach files but not given a valid job number" 
      return 0
    }
    set deffile [FileJoin [GetDbDirPath] [subst $mail(ATTACH_JOB)]_$task.def ]
    if { ![file exists $deffile] } {
      WarningMessage "Def file for job number $mail(ATTACH_JOB)\n$deffile\n\not found"
    } else {
      lappend attachments $deffile
    }
    if { [regexp LOG $attach ] } {
      set logfile [GetLogFileName $mail(ATTACH_JOB)]
      if { ![file exists $logfile] } {
        WarningMessage "Log file for job number $mail(ATTACH_JOB)]\n$logfile\n\not found"
      } else {
        lappend attachments $logfile
      }
    }
    set nattach [llength $attachments]

# Get user confirmation
    set message "Confirm that you want to attach these files to your email"
    foreach file $attachments { append message \n$file }
    if { [ regexp Abort [ChooseOptionDialog "Attach files to email" Attach \
	$message [list Abort OK] ] ] } {
      return 0
    }
  }
    
    
  
  if {[WriteFile $tmp_file "\n#CCP4I OPSYS $system(OPSYS)
#CCP4 VERSION $system(CCP4_VERSION)\n#CCP4I VERSION $system(VERSION)
[$w get 1.0 end]" -overwrite ]} {

    if { $nattach > 0 } {
      foreach file $attachments {
        ReadFile $file text
# default WriteFile mode is append
        WriteFile $tmp_file $text
      }
    }

    if { [SendMail "$mail(SUBJECT)" $tmp_file $mail_address ] } {
      DeleteFile $tmp_file
      destroy [winfo toplevel $w]
      unset mail
      return 1
    }
  }
  WarningMessage "Error sending mail message"
  return 0
}

#----------------------------------------------------------------------
proc SwitchProject { project menupath } {
#----------------------------------------------------------------------
#d_sum Switch the main window to another project
#d_desc Changes to the project selected by the user from the menu \
and updates the menu contents.
#d_arg project Alias of the selected project
#d_arg menupath Path of the change project button widget

  # Switch directories
  DbChangeFile $project
  # Save the new settings to file
  SaveDirectories -lock
  DbGetCurrentProject project
  build_project_shortcut_menu $project $menupath
}

#----------------------------------------------------------------------
proc build_project_shortcut_menu { project menupath } {
#----------------------------------------------------------------------
#d_sum Build the menu of project shortcuts on the main window
#d_arg project is the name of the current project
#d_arg menupath is the path of the menu being updated

  global configure

  # Set the maximum length of a menu column before it is broken
  set collength $configure(MENU_LENGTH)
  # Update the shortcut menu
  $menupath delete 0 end
  DbGetCurrentProject project
  $menupath add command -label $project -font $configure(FONT_ITALIC)
  set break_count 1
  foreach proj [ListProjects] {
    if {$project!=$proj} {
	  $menupath add command -label $proj \
	      -command "SwitchProject $proj $menupath" \
              -font $configure(FONT_REGULAR) \
	      -columnbreak \
	      [break_menu_column break_count $collength]
    }
  }
  # Add a separator and a shortcut to the Directories&ProjectDir
  # window
  $menupath add separator
  $menupath add command -label "Add/edit project" \
      -command "Directories" \
      -font $configure(FONT_ITALIC) \
      -columnbreak \
      [break_menu_column break_count $collength]
}

#----------------------------------------------------------------------
proc ReloadTasklists { m arrayname } {
#----------------------------------------------------------------------
#d_sum Reload the data for the modules and tasklists, and redraw
#d_arg m Name of the menu widget (typically .module.menu.module.mb.m)
#d_arg arrayname Name of the array holding the tasklist data (typically \
moduledef)
  upvar #0 $arrayname array
  # Record current module
  set current_module_title $array(CURRENT_MODULE_TITLE)
  # Re-read the data from the file and rebuild the internal
  # data structures
  unset array
  ReadTaskList $arrayname modules
  # Rebuild the menus
  update_module_menu $m $arrayname
  # Check that the current module still exists, and set a new one if not
  set module_exists 0
  foreach module [ListModules $arrayname] {
      if { [string match $current_module_title [GetModuleDesc $arrayname $module]] } {
	  incr module_exists
	  break
      }
  }
  if { ! $module_exists } {
      set current_module_title \
	  [GetModuleDesc $arrayname \
	       [lindex [ListModules $arrayname] 0]]
  }
  # Redraw the tasklist for the current module
  update_module $current_module_title $arrayname
}
