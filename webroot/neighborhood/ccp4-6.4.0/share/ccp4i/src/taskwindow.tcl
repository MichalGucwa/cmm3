#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#=========================================================================
# CCP4 Interface - taskwindow.tcl
#
#
#
# Task windows display and command handling
#
#====================================================================

#CCP4i_cvs_Id $Id$

#d_index_title Task Window Utilities (src/taskwindow.tcl)
#d_intro_title Task Window Utilities (src/taskwindow.tcl)
#d_intro Utitlities specific to drawing task windows. \
Complements the utilities in windows.tcl which are more generic

#------------------------------------------------------------
proc RunTask { taskname args } {
#------------------------------------------------------------
#d_sum Initialise parameters for task and draw task window
#d_desc This procedure is called when the user clicks on a task in the \
modules and tasks menu.  It is also called from other context when a task \
window is to be drawn.
#d_desc This procedure initialises parameters from the tasks/taskname.def file \sources the taskname.tcl file and runs the foo_setup and foo_task_window procedures.
#d_arg taskname The name of the task
#d_opt0 -array arrayname
#d_opt1 By default the task parameters are placed in an array called \
taskname_project. An alternative arrayname can be specified here.
#d_opt0 -args argstring
#d_opt1 The text string argstring appended as argument when calling the \
taskname_run procedure
#d_opt0 -subsiduary subsiduary_taskname
#d_opt1 Also open a subsidiary task window for subsiduary_taskname by calling RunTask
#d_opt0 -def deffile
#d_opt1 The default def file defining initial parameters is ccp4i/tasks/taskname.def and this file will always be read if it exists.  The optional deffile will be read after this default df file.
#d_opt0 -module module
#d_opt1 By default the taskname.tcl file which defines the interface should \
be in ccp4i/tasks directory but if module is defined then it will be expected to be in ccp4i/module/ directory

  global system
  set arrayname "[subst $taskname]_[GetCurrentProject]"
  set argstring {}
  set subsiduary {}
  set def 0
  set deffile {}
  set module {}
  set force_init 0

  set nargs [expr {[llength $args] -1} ]; set n 0
  while  { $n <= $nargs } {
    switch -regexp -- [lindex $args $n] \
    array {
      incr n; set arrayname [lindex $args $n]
    } args {
      incr n; append argstring " " [lindex $args $n]
    } subsiduary {
      incr n; set subsiduary [lindex $args $n]
    } def {
      set def 1
      incr n; set deffile [lindex $args $n]
    } module {
      incr n; set module [lindex $args $n]
    } init {
      set force_init 1
    }
    incr n
  }

  global $arrayname

  set w .w_[subst $arrayname]
  if { [winfo exist $w ] > 0 } {
    if { $force_init } {
# apply same commands as if closing the window
      UnsetArrayExtras $arrayname
      DeleteTaskWindow $w $arrayname $taskname
    } else {
      wm iconify $w
      wm deiconify $w
      return 0
    }
  }
  set [subst $arrayname](WINDOW) $w
  set [subst $arrayname](TASK) $taskname
  SetSystemVar frame_program_help ""

  if { $def && [file exists $deffile] } {
    if  { [InitialiseArray [SearchPath TOP tasks $taskname.def ] \
                 $arrayname $taskname] } {
      InitialiseArray $deffile $arrayname $taskname -noinitparamlist
    } else {
      InitialiseArray $deffile $arrayname $taskname
    }
  }

  PleaseWait "..drawing task window $taskname"
  if { $module == "" || [catch {
    source [SearchPath TOP $module $taskname.tcl ] } ] } {
    foreach module [list tasks sketch ] {
      if { [file exist [SearchPath TOP $module $taskname.tcl ]] } {
         source [SearchPath TOP $module $taskname.tcl ] 
         break
      }
    }
  }

  # If we can't find the task_window startup procedure then it is
  # not possible to start the task
  if { [lsearch [info procs [subst $taskname]_task_window] \
	  [subst $taskname]_task_window] < 0} {
    PleaseWait
    WarningMessage \
"Cannot start task \"$taskname\"

It appears there is no such task in this
version of CCP4i"
    return 0
  }

  set task_setup [subst $taskname]_setup
  if { [StringSame [ info procs "$task_setup" ] "$task_setup" ] } {
    if { ![$task_setup typedef $arrayname] } {
      PleaseWait
      return
    }
#    if {  [$task_setup typedef] <= 0 } { 
#      Report 2 "ERROR running setup procedure $task_setup"
#      PleaseWait
#      return 
#    }
  }

  SetSystemVar block_scroll_update 1
  append cmd [subst $taskname]_task_window " " $arrayname $argstring
  eval "$cmd"
  draw_task_window $arrayname
  PleaseWait

  if { $subsiduary != "" } { RunTask $subsiduary }
}

#----------------------------------------------------------------------
proc draw_task_window { arrayname } {
#----------------------------------------------------------------------
#d_sum Procedure called at end of RunTask to actually put the window on the screen
#d_desc A major time consumer when drawing a task window is updating the \
scrollable frame controlled by the right hand side scroll bar.  Updating \
this is done by update_main_scroll which is blocked while the window is \
been defined by taskname_run but is called after taskname_run is finished. \
#d_desc This procedure also deiconifies (i.e. displays the window on the screen)

  upvar #0 $arrayname array
# This is separate prcedure so can access array
  if {[ElementExists $arrayname UPDATE_SCRIPTS]} {run_update_script $arrayname}
  set w $array(WINDOW)
  if { [winfo exist $w ] > 0 } {
    SetSystemVar block_scroll_update 0
    update_main_scroll $w
    wm deiconify $w
    set_message $arrayname "$array(TASK_TITLE)"
#    TkBusy . 1
    return 1
  } else {
    return 0
  }
}

#----------------------------------------------------------------
proc RerenderTask { w arrayname taskname } {
#----------------------------------------------------------------
#d_sum Redraw an existing task window
#d_desc This is a wrapper to RunTask, which does some cleaning up \
of the original window prior to invoking RunTask.
#d_desc Any parameters set in the array are preserved and will be \
displayed in the redrawn window.
#d_arg arrayname Name of array containing parameters for task
#d_arg w The window id for the task window
#d_arg taskname The name of the task
  if {[winfo exist $w ]} {
    # Remove the bindtag
    set destroytag "destroyTaskWindow$arrayname"
    set tags [bindtags $w]
    set itag [lsearch $tags $destroytag]
    if { $itag > -1 } {
      bindtags $w [lreplace $tags $itag $itag]
    }
    # Delete the window
    DeleteTaskWindow $w $arrayname $taskname -noexit -nounsetarray
  }
  UnsetArrayExtras $arrayname
  RunTask $taskname -array $arrayname
}

#----------------------------------------------------------------
proc CreateTaskWindow { arrayname title icon_name { frame_list {}} args } {
#----------------------------------------------------------------
#d_sum Called from taskname_run to define general appearance of task window
#d_desc The arrayname and window id set up in the procedure are 'remembered' \
and used by subsequent calls to procedures such as CreateLine  and \
CreateLabin.  This procedure creates the folders for the task window and \
the action buttons.
#d_desc Create task window taking task name and window name from \
array(TASK) and array(WINDOW)
#d_arg arrayname Name of array containing parameters for task
#d_arg title Title for task window
#d_arg icon_name Name to appear on iconised window
#d_arg folder_list A list of titles for folders in task window.
#d_opt0 -action_buttons actions
#d_opt1 Enter a list of action buttons to appear at the bottom of the \
widow.  Options are: quit, reset, save, interactive, run, exit
#d_opt0 -default_button default_action
#d_opt1 Specify default_action as the default action button
#d_opt0 -title
#d_opt1 REDUNDANT
#d_opt0 mode
#d_opt1 REDUNDANT
#d_opt0 -help_file help_file
#d_opt1 The default help file is the file for the curr

# Create task window taking task name and window name from
# array(TASK) and array(WINDOW)
# Initialise task window parameters in arrayname
# If the PARAM_LIST element is not set then read the interface 
# parameters from def file

  upvar #0 $arrayname array

  global system
  global configure
  global moduledef

  set w $array(WINDOW)
  if { [winfo exist $w ] > 0 } {
    wm iconify $w
    wm deiconify $w
    return 0
  }

  TkBusy .

  if {[ElementExists moduledef CURRENT_MODULE ]} {
    set array(MODULE) $moduledef(CURRENT_MODULE)
    set array(MODULE_TASK_NUMBER) [GetSystemVar module_task_number]
    set help_file [SearchPath HELP modules $array(MODULE).html ]
  } else {
    set help_file ""
  }

  set taskname $array(TASK)
  set actions [list quit save run]
  set default_action ""
  set mode task

  set n 0; set nargs [expr {[llength $args] - 1}]
  while { $n <=  $nargs } {
    set cmd [lindex $args $n]
    if { $cmd == "-action_buttons" } {
      incr n; set actions  [lindex $args $n]
    } elseif { $cmd == "-default_button" } {
       incr n; set default_action [lindex $args $n]
    } elseif { $cmd == "-title" } {
       incr n; append title [lindex $args $n]  " "
    } elseif { $cmd == "-mode" } {
       incr n; set mode [lindex $args $n] 
    } elseif { $cmd == "-help_file" } {
       incr n; set help_file [lindex $args $n] 
    }
    incr n
  }


  set array(TASK_TITLE) "$title"

# Initialise the data array if the PARAM_LIST index has not
# been set

  if { ![ElementExists $arrayname PARAM_LIST ] } {
    foreach module [list tasks sketch ] {
      if { [file exists [SearchPath TOP $module $taskname.def]] } {
        InitialiseArray [SearchPath TOP $module $taskname.def ] \
	    $arrayname $taskname
        break
      }
    }
    if {[file exists [FileJoin [GetDbDirPath] $taskname.def ]]} {
      InitialiseArray [FileJoin [GetDbDirPath] $taskname.def ] \
	$arrayname $taskname -noinitparamlist
    }
  }

#  if {  $mode == "task" } { ChainCopyArray $arrayname  }

# Data used in defining the contents of each frame

  if { [GetSystemVar frame_program_help] == "" } {
    SetProgramHelpFile $taskname
  }

  SetSystemVar frame_parent $w.main.canvas.contents
  SetSystemVar frame_array $arrayname
  SetSystemVar current_index_counter ""

  set array(CHILDREN) ""
  set array(UNDEFINEDS) 0
  set array(FRAMES_DRAWN) 0
  set array(LINES_DRAWN) 0
  set array(UPDATE_SCRIPTS) ""
  set array(TRACE_LIST) ""


  OpenWindow $w $array(TASK_TITLE) $icon_name -help $help_file \
		-target $taskname -message $arrayname

  redraw_task_window_title $arrayname

# Fix width but allow user to change height of window
  wm resizable $w 0 1
# Hide it till its done
  wm withdraw $w

  set wbuttons $w.buttons
  frame $wbuttons -relief raised 
  pack $wbuttons -side bottom -fill x -pady 2m

  frame  $w.main -width 100
  pack $w.main -side top -fill x
# Make a scrolled frame...
  scrolled_frame $w.main  {

  set main $w.main.canvas.contents

  set wprotocol $main.protocol
  frame $wprotocol -relief ridge -borderwidth 1

  set wfile $main.file
  frame $wfile -relief ridge -borderwidth 1

  pack $wprotocol -side top -fill x
  pack $wfile -side top -fill x

  set array(N_PARAM_FRAME)  [llength $frame_list ] 
  set n -1

  for {set i 1} { $i <= $array(N_PARAM_FRAME) } {incr i} {

    incr n; set item [lindex $frame_list $n ]
#    incr i; set array(PARAM_FRAME_$i) [lindex $frame_list $n]
    set array(PARAM_FRAME_$i) "open"
    set wframe $main.param_$i
    frame $wframe -relief ridge -borderwidth 1
    pack $wframe -side top -fill x -expand 1 -anchor e
    frame $wframe.top -relief ridge \
	-background $configure(COLOUR_PALE)
    frame $wframe.body 
    pack $wframe.top $wframe.body  -side top -fill x  


    label $wframe.top.lab -text $item \
        -font $configure(FONT_ITALIC) \
	-background $configure(COLOUR_PALE) 
    CreateCheckbutton $wframe.top.but                                         \
        -variable [subst $arrayname](PARAM_FRAME_$i)                    \
        -relief flat -anchor w        \
	-background $configure(COLOUR_PALE) \
	-highlightbackground $configure(COLOUR_PALE) \
	-activebackground $configure(COLOUR_PALE) \
	-indicatoron 1							\
        -onvalue "open" -offvalue "closed"				\
        -command "update_folder_display $i $arrayname view
		  update_main_scroll $w"

    pack $wframe.top.lab  -side left
    pack $wframe.top.but  -side right

    bind $wframe.top <Button-1> "$wframe.top.but invoke"
    bind $wframe.top.lab <Button-1> "$wframe.top.but invoke"
  }
# End of scrolled list
  } 

#  update_folder_display $arrayname all
#
# Set up the action buttons
#
#---------------------------------------------------------------------
# Dismiss button
#-----------------------------------------------------------------------

  if { [lsearch $actions quit] >= 0 } {

  if { $system(RUN_MODE) == "task" } {
    set dismiss Exit
  } else {
    set dismiss Close
  }
  button $wbuttons.dismiss -text $dismiss 			\
	-font $configure(FONT_REGULAR) \
	-background $configure(COLOUR_PALE) \
	-command "UnsetArrayExtras $arrayname
		  DeleteTaskWindow $w $arrayname $taskname"

  # Bind destroy event to be consistent with the use of the
  # Dismiss button above
  # NB 
  # You can't just do "bind $w <Destroy> "..."" because all the
  # children of $w also inherit the binding - so this construct
  # (borrowed from Harrison and McLennan's "Effective Tcl/Tk
  # Programming") defines a new bindtag and gives this to $w only
  # Make a unique bindtag for this event & this window
  set destroytag "destroyTaskWindow$arrayname"
  bind $destroytag <Destroy> \
      "UnsetArrayExtras $arrayname
       DeleteTaskWindow $w $arrayname $taskname"
  set tags [bindtags $w]
  bindtags $w [linsert $tags 0 $destroytag]

  pack $wbuttons.dismiss -side right -expand 1
  SetMessage $arrayname $wbuttons.dismiss "Exit without any action"

  if { $default_action == "quit" } {
    $wbuttons.dismiss configure -borderwidth 4
    $w bind <Return> \
    "UnsetArrayExtras $arrayname
                  DeleteTaskWindow $w $arrayname $taskname"
  }

  } elseif { [lsearch $actions reset ] >= 0 } {

  }

#---------------------------------------------------------------------
# Save and restore parameters button
#---------------------------------------------------------------------
  
  if { [lsearch $actions save] >= 0 } {

  menubutton $wbuttons.defaults -text "Save or Restore" \
	  -font $configure(FONT_REGULAR) \
	  -background $configure(COLOUR_PALE) \
	  -indicatoron 1 -relief raised  \
          -width 15  \
          -menu $wbuttons.defaults.m1

#  menu $wbuttons.defaults.m1 -tearoff 0 -transient 1
  menu $wbuttons.defaults.m1 -tearoff 0 \
	  -background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR)
  $wbuttons.defaults.m1 add cascade -label "Save to File"        \
	  -background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
    -menu $wbuttons.defaults.m1.m2
  $wbuttons.defaults.m1 add cascade -label "Restore from File"        \
	  -background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
    -menu $wbuttons.defaults.m1.m3
  $wbuttons.defaults.m1 add command -label "Restore Default Parameters"  \
	  -background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
    -command " ReCreateTaskWindow DEFAULT $taskname $w $arrayname "
  $wbuttons.defaults.m1 add command -label "Unset Project Defaults.."  \
	  -background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
    -command "UnsetProjectDefault $taskname $w $arrayname "

#  menu $wbuttons.defaults.m1.m2 -tearoff 0 -transient 1
  menu $wbuttons.defaults.m1.m2 -tearoff 0 \
	  -background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR)
    $wbuttons.defaults.m1.m2 add command -label "Current Project Default"  \
	  -background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
    -command "SaveProjectDef  $taskname $arrayname"
    $wbuttons.defaults.m1.m2 add command -label "User's Defaults Directory"  \
          -background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
    -command "SaveProjectDef  $taskname $arrayname -user"
    $wbuttons.defaults.m1.m2 add command -label "Select File Name"  \
	  -background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
    -command "SaveUserDefinedDef $taskname $arrayname $wbuttons.defaults.m1.m2"


#  menu $wbuttons.defaults.m1.m3 -tearoff 0 -transient 1
  menu $wbuttons.defaults.m1.m3 -tearoff 0 \
	  -background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR)
    $wbuttons.defaults.m1.m3 add command -label "User's Defaults Directory"  \
          -background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
    -command " ReCreateTaskWindow USER $taskname $w $arrayname "
    $wbuttons.defaults.m1.m3 add command -label "Current Project Default"  \
	  -background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
    -command " ReCreateTaskWindow PROJECT $taskname $w $arrayname "
    $wbuttons.defaults.m1.m3 add command -label "Select File Name"  \
	-font $configure(FONT_REGULAR) \
    -command " ReCreateTaskWindow USER_DEFINED $taskname $w $arrayname  $wbuttons.defaults.m1.m2"
    $wbuttons.defaults.m1.m3 add command -label "Select Job Number"  \
    -command " ReCreateTaskWindow JOB_NUMBER $taskname $w $arrayname"



  SetMessage $arrayname $wbuttons.defaults.m1.m2 \
	"Save the current parameters to a file"
  SetMessage $arrayname $wbuttons.defaults.m1.m3 \
	"Reset the current parameters from a file"
  SetMessage $arrayname $wbuttons.defaults \
   "Save the current parameters or restore parameters from file "


  pack $wbuttons.defaults -side right -expand 1

  }

#------------------------------------------------------------------

  if { [lsearch $actions interactive ] >= 0 } {

   button $wbuttons.interactive \
	  -background $configure(COLOUR_PALE) \
	-text "Run Now" \
	-font $configure(FONT_REGULAR) \
	-relief raised \
	-command "run_command interactive $taskname $arrayname" 

   pack $wbuttons.interactive -side right -expand 1


  } elseif { [lsearch $actions run] >= 0 } {
    if { ![ElementExists $arrayname ACTION_MODE ] ||  \
     $array(ACTION_MODE) != "review" } {
      DrawRunButton $wbuttons $taskname $w $arrayname 
    }
  }

  if { [lsearch $actions run] >= 0 && $system(RUN_MODE) == "task" } {

  menubutton $wbuttons.log -text "Show Log File" \
	  -background $configure(COLOUR_PALE) \
	  -font $configure(FONT_REGULAR) \
          -indicatoron 1 -relief raised  \
          -width 14  \
          -menu $wbuttons.log.m1

  menu $wbuttons.log.m1 -tearoff 0 \
	-font $configure(FONT_REGULAR)

  $wbuttons.log.m1 add command -label "List Log File" \
	  -background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
	-command "task_display_log list [DbGetNJOBS]"

  $wbuttons.log.m1 add command -label "Show Log Graphs"  \
	  -background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
	-command "task_display_log graphs [DbGetNJOBS]"

  pack  $wbuttons.log -side right -expand 1
  }

#----------------------------------------------------------------------
  if { [lsearch $actions exit ] >= 0 } {
#----------------------------------------------------------------------

    button $wbuttons.exit -text "Save&Exit"  \
	  -background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
        -command "SaveProjectDef $taskname $arrayname -input
		  UnsetArrayExtras $arrayname
                  DeleteTaskWindow $w $arrayname $taskname"
    pack $wbuttons.exit -side right -expand 1
    SetMessage $arrayname  $wbuttons.exit \
	"Close window and save parameters to project default for $taskname"

    if { $default_action == "exit" } {
      $wbuttons.exit configure -borderwidth 4
      bind $w <Return> \
      "SaveProjectDef $taskname $arrayname -input
      UnsetArrayExtras $arrayname
      DeleteTaskWindow $w $arrayname $taskname"
    }
  }
  return 1
}

#--------------------------------------------------------------------------
proc DrawRunButton { wbuttons taskname w arrayname } {
#--------------------------------------------------------------------------
#d_sum Draw the 'Run' button for task windows
#d_desc Draw the default run button with option to 'Run Remote' etc.
#d_arg wbuttons The Tk frame id for the 'buttons' frame
#d_arg taskname The task name
#d_arg w The window id for the task window
#d_arg arrayname Name of array containing parameters for task

  global system
  global configure
  menubutton $wbuttons.run -text "Run" 	\
	  -background $configure(COLOUR_PALE) \
	  -font $configure(FONT_REGULAR) \
	  -indicatoron 1 -relief raised  \
          -width 18  \
          -menu $wbuttons.run.m1
  menu $wbuttons.run.m1 -tearoff 0

  $wbuttons.run.m1 add command -label "Run Now"        \
	  -background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
	-command "run_command background $taskname $arrayname"

  $wbuttons.run.m1 add command -label "Run&View Com File"        \
	  -background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
        -command "run_command edit $taskname $arrayname"

  $wbuttons.run.m1 add command -label "Run Remote/Batch/Later" \
	  -background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR) \
        -command "run_command remote $taskname $arrayname"

#  if { $system(RUN_MODE) != "task" } {
#    $wbuttons.run.m1 add command -label "Append to Script"        \
#	-font $configure(FONT_REGULAR) \
#        -command "run_command chain $taskname $arrayname"
#  }

  pack $wbuttons.run -side left -expand 1
  SetMessage $arrayname  $wbuttons.run "Run the job"

}

#--------------------------------------------------------------------
proc UnsetProjectDefault { taskname w arrayname } {
#--------------------------------------------------------------------
#d_sum Handle 'Unset Project default' option on Save or Restore menubutton
#d_desc Give user option to delete current task defaults file or move it. \
The task project defaults are in the project directory CCP4_DATABASE/taskname.def
#d_arg taskname The task name
#d_arg w The window id for the task window
#d_arg arrayname Name of array containing parameters for task

  set file [FileJoin [GetDbDirPath] $taskname.def]

  if { ![file exists $file] } { return }

  set action [ChooseOptionDialog "Unset project default" "Unset" \
    "Project defaults currently saved in the file $file
Delete this file or save to new file name?" \
	[list "Quit" "Delete file" "Save to new file"  ] ]

  switch $action \
  Delete { 
    DeleteFile $file
  } Save {
    set fileout ""
    if {[SelectFile fileout -title "Save current project default for $taskname" \
			-defdir [GetCurrentProject] -unknown ]} {
      if { ![file exists [lindex $fileout 0]] } {
        MoveFile $file [lindex $fileout 0]
      } elseif  {[ regexp Overwrite \
        [ ChooseOptionDialog "Overwrite" "Overwrite" \
	  "Overwrite file $fileout" [list Quit Overwrite ] ] ]} {
        DeleteFile [lindex $fileout 0]
        MoveFile $file [lindex $fileout 0]
      }
    }
  }
}
        
#--------------------------------------------------------------------
proc task_display_log { mode old_njobs } {
#--------------------------------------------------------------------
#d_sum Handle option to 'Display Log Files' which is presented to user in 'task' mode of running ccp4i.
#d_arg mode May be 'list' or 'graphs' to display listing or log graphs.
#d_arg old_njobs The number of jobs in the project database when the task \
is first created. Log files will only be displayed for jobs run subsequently.

  set job_id [DbGetNJOBS] 
  if { $job_id > $old_njobs } {
    if { $mode == "graphs" } {
      LogGraph [GetLogFileName $job_id ]
    } else {
      DisplayTextFile [GetLogFileName $job_id ] \
	-monitor -terminater "CCP4I TERM"
    }
  }
}

#----------------------------------------------------------------------
proc redraw_task_window_title { arrayname } {
#----------------------------------------------------------------------
#d_sum Redraw task window title with information on the origin of the initial parameters
#d_arg arrayname The name of the task array
  upvar #0 $arrayname array
  set title $array(TASK_TITLE)
  if { [ElementExists $arrayname INITIAL_DEF] && $array(INITIAL_DEF) != "" } {
    append title " Initial parameters from $array(INITIAL_DEF)"
  }
  wm title $array(WINDOW)  "$title"
}


#-----------------------------------------------------------------------
proc SaveUserDefinedDef { taskname arrayname field} {
#-----------------------------------------------------------------------
#d_sum Handler to save current parameters to user specified file
#d_arg taskname The task name
#d_arg arrayname Name of array containing parameters for task
#d_arg field REDUNDANT

  upvar #0 $arrayname array

  if {[SelectFile file -title "Save Parameters for $taskname" \
        -defdir [GetCurrentProject] -filter "*.def" \
        -parent $arrayname -unknown ]} {
    SaveArray $taskname [lindex $file 0] $arrayname  -query_overwrite 
  }
}



#-----------------------------------------------------------------------
proc SaveProjectDef { taskname arrayname args } {
#-----------------------------------------------------------------------
#d_sum Handler to save current parameters to the user or the project default file.
#d_desc By default this procedure saves the defaults for the project in \
the file project_directory/CCP4_DATABASE/taskname.def.  \
Alternatively the 'user' defaults are saved in \
\$HOME/.CCP4/tasks/taskname.def. For some specific context the defaults \
may be saved to a file named defined in the task array as \
array(TASK_INPUT_DEF_FILE).
#d_arg taskname The task name
#d_arg arrayname Name of array containing parameters for task
#d_opt0 -input
#d_opt1 Save to file specified in array(TASK_INPUT_DEF_FILE) parameter
#d_opt0 -user
#d_opt1 Save to the 'user' defaults file

  upvar #0 $arrayname array
# Save the parameters for taskname in array arrayname
# Beware the extra args is to handle this command being called from
# trace variabe command
#  puts "SaveProjectDef arrayname $arrayname"
#  if { ![array exists $arrayname] } {puts "$arrayname array does not exist?"; return } 

  set mode project

  set nargs [llength $args]; set n 0
  while { $n < $nargs } { 
    switch -regexp -- [lindex $args $n] \
    input {
      set mode input 
    } user {
      set mode user 
    }
    incr n
  }

  switch $mode \
  user {
    set fileout [FileJoin [GetSystemVar DOT] CCP4I_TOP tasks $taskname.def]
  } input {
    if { [ElementExists $arrayname TASK_INPUT_DEF_FILE] && \
        $array(TASK_INPUT_DEF_FILE) != ""  && \
          [file exists $array(TASK_INPUT_DEF_FILE) ] } {
       set fileout $array(TASK_INPUT_DEF_FILE)
    } else {
      set fileout [FileJoin [GetDbDirPath] $taskname.def]
    }
  } default {
     set fileout [FileJoin [GetDbDirPath] $taskname.def]
  }
  SaveArray $taskname $fileout $arrayname -query_overwrite  -save_types

  Report 1 "Saving parameters for $taskname to $fileout"

}

#-----------------------------------------------------------------------
proc RedrawTaskWindow { arrayname taskname } {
#-----------------------------------------------------------------------
#d_sum Redraw a task window from scratch after destroying existing window.
#d_desc After destroying the window the UnsetArrayExtras procedure removes \
all parameters in the array which are set up to control the window. These \
will be redefined when the window is redrawn.

  upvar #0 $arrayname array

  set w $array(WINDOW)
  if {[winfo exist $w ]} {
    DeleteTaskWindow $w $arrayname $taskname -noexit }
  UnsetArrayExtras $arrayname
  RunTask  $taskname -array $arrayname
}


#----------------------------------------------------------------------
proc ReCreateTaskWindow { mode taskname w arrayname { field {}} } {
#----------------------------------------------------------------------
#d_sum Load parameters from a def file and redraw the task window.
#d_desc After reloading parameters there are often major changes in a window \
particularly in the number of extending frames and such like.  It is easiest \
to redraw the window from scratch.
#d_arg mode May be: JOB_NUMBER - prompt user for number of job from which \
parameters should be taken, USER_DEFINED - prompt user for def file name, \
CURRENT  - reset from ccp4i default parameters, PROJECT - user parameters \
from the project default file.
#d_arg taskname The task name
#d_arg w The window id for the task window
#d_arg arrayname Name of array containing parameters for task

  upvar #0 $arrayname array

# handle the task window option to restore data from a def file

# prompt user to select a def file

  if { $mode == "JOB_NUMBER" } {
    global job_no
    set job_no(JOB_NO) ""
    set job_no(_JOB_NO) _positiveint
    set retval [InputParamDialog "Choose Job" "Choose Job" job_no \
       { { JOB_NO {Use parameters from job number} } }  ]
    set job_id $job_no(JOB_NO); unset job_no
    if { $retval && [DbGetJobData $job_id STATUS] != "" } {
      set task [lsearch [DbGetJobData $job_id TASKNAME ] $taskname] 
      if { $task < 0 } {
        Report 2 "This job does not use task $taskname"
        return 0
      } else {
        set file [ DefFileName $job_id ]
        Report 1 "Using def file $file"
        if { ![file exists $file] } {
          Report 2 "The def file $file does not exist??"
          return 0
        }
      }
    } else {
      return 0
    }
  } elseif { $mode == "USER_DEFINED" } {
    if  { ![SelectFile file -title "Restore Parameters for $taskname" \
        -defdir [GetCurrentProject] -filter "*.def" \
        -parent $arrayname ] } { return }
  }

  TkBusy .
  if { [winfo exist $w ] } { 
    DeleteTaskWindow $w $arrayname $taskname -noexit }
  
  if { $mode == "CURRENT" } {
    UnsetArrayExtras $arrayname
  } else {
    catch "unset array"
    InitialiseArray [SearchPath TOP tasks $taskname.def] $arrayname $taskname

    if { $mode == "PROJECT" } {
      InitialiseArray [FileJoin [GetDbDirPath] $taskname.def] \
        $arrayname $taskname -reportlabel
    } elseif { $mode == "USER" } {
      InitialiseArray \
        [FileJoin [GetSystemVar DOT ] CCP4I_TOP tasks $taskname.def] \
        $arrayname $taskname -reportlabel
    } elseif { $mode == "USER_DEFINED" || $mode == "JOB_NUMBER" } {
      InitialiseArray  [lindex $file 0] $arrayname $taskname -reportlabel
    }
    InitialiseParamFromFile all
  }
  if { $mode == "USER_DEFINED" } {
    set array(TASK_INPUT_DEF_FILE) [lindex $file 0] }

  TkBusy . 1
  RunTask  $taskname -array $arrayname
  PleaseWait ""
}

#-------------------------------------------------------------------
proc DeleteTaskWindow { w arrayname taskname args } {
#-------------------------------------------------------------------
#d_sum Close a task window cleanly.
#d_desc If a taskname_close procedure exists then invoke it.  \
Close the window and exit the interface if running in task mode.
#d_arg w The window id for the task window
#d_arg arrayname Name of array containing parameters for task
#d_arg taskname The task name
#d_opt0 -noexit
#d_opt1 Don't exit if running in stand alone mode
#d_opt0 -nounsetarray
#d_opt1 Don't unset the array

  upvar #0 $arrayname array
  global moduledef
  global system

  set task_close_script [subst $taskname]_close
  if { [StringSame [ info procs "$task_close_script" ] \
             $task_close_script ] } {
    set status [$task_close_script $arrayname ]
  }

  CloseWindow $arrayname


# If running task stand alone version of interface then exit

  if { $system(RUN_MODE) == "task" && [lsearch $args "-noexit"] < 0 } { 
     ExitInterface }

# If there is a routine taskname then run it
  append cmd $taskname "_close" 
  if { [info procs "$cmd"] == "$cmd" } {
    append cmd " " $arrayname
    eval "$cmd"
  }

  if { [regexp "dbtmp_" $arrayname] && [lsearch $args "-nounsetarray"] < 0 } {
    unset array
  }
}

#-----------------------------------------------------------------
proc SaveOnProgramExit { taskname arrayname } {
#-----------------------------------------------------------------
#d_sum Specify a task array which will be saved to a def file if the user \
exits the interface.
#d_desc Currently only used for mr_database.

#d_arg arrayname Name of array containing parameters for task
#d_arg taskname The task name

  global system

  trace variable system(TERMINATE) r \
	"SaveProjectDef $taskname $arrayname"
}

#--------------------------------------------------------------------
proc LockInterface { } {
#--------------------------------------------------------------------
#d_sum "Lock" the interface to prevent it from exiting
#d_desc This command can be called to place a lock on the interface \
to prevent it from exiting before an operation is finished.
  global system
  set system(INTERFACE_LOCKED) 1
  return
}

#--------------------------------------------------------------------
proc UnlockInterface { } {
#--------------------------------------------------------------------
#d_sum Unlock the interface after a call to LockInterface
  global system
  if { [info exists system(INTERFACE_LOCKED)] } {
    set system(INTERFACE_LOCKED) 0
  }
}

#--------------------------------------------------------------------
proc InterfaceIsLocked { } {
#--------------------------------------------------------------------
#d_sum Check whether the interface is locked and prevented from exiting
  global system
  if { [info exists system(INTERFACE_LOCKED)] } {
    return $system(INTERFACE_LOCKED)
  } else {
    return 0
  }
}

#--------------------------------------------------------------------
proc ConfirmExitInterface { { source "" } } {
#--------------------------------------------------------------------
#d_sum Prompt for user confirmation before exiting the interface
#d_desc This is a wrapper to ExitInterface which pops up a \
confirmation dialog before exiting, and allows the user to change \
their mind.
#d_desc The source argument can be used to indicate which interface \
component has triggered the call to exit the interface, as this may \
affect whether or not the user should be prompted to confirm the \
exit operation. Currently only "*exit*" (e.g. "exitbutton") is \
recognised, and indicates that the "Exit" button from the main \
CCP4i window was used to trigger the exit process.
#d_arg source (optional) A keyword indicating the source of the exit \
request.
  global preferences

  set mode [GetValue preferences PROMPT_ON_EXIT]
  set prompt_user 1
  switch $mode {
      "NEVER" {
	  # Don't prompt the user, ever
	  set prompt_user 0
      }
      "NOT_EXIT_BUTTON" {
	  # Only prompt if the user didn't press
	  # the exit button on the main window
	  if { [regexp -- exit $source] } {
	      # Source was the main interface exit button
	      set prompt_user 0
	  }
      }
      default {
	  # By default coming through this route
	  # we always want to prompt the user
      }
  }
  if { ! $prompt_user } {
      # Exit without a confirmation
      ExitInterface
  }
  # Still here? Then prompt the user
  set action [ChooseOptionDialog "Confirm CCP4i Exit" "Exit CCP4i" \
		  "Are you sure you want to exit CCP4i?" \
		  [list "Yes" "No" ] ]
  switch $action {
      Yes { 
	  # User agreed, let's exit
	  ExitInterface
      }
      No {
	  # User decided not to exit
	  return
      }
  } 
}

#--------------------------------------------------------------------
proc ExitInterface { } {
#--------------------------------------------------------------------
#d_sum On exiting the interface save the status file and database file
#d_desc The system(TERMINATE) parameter is also reset so any procedure \
attached to the trace set by SaveOnProgramExit will be called.

  global system
  global ccp4i_status
  global moduledef

# Check whether the interface is locked
  if { [InterfaceIsLocked] } {
    # Wait for 10 seconds
    PleaseWait "CCP4i is currently busy"
    after 10000 { PleaseWait ; ExitInterface }
    return
  }

#  puts "ExitInterface"
  set system(TERMINATE) 1
  if {[ElementExists moduledef CURRENT_MODULE]} {
    set ccp4i_status(CURRENT_MODULE) $moduledef(CURRENT_MODULE)
    SavePreferences status ccp4i_status
  }

# Beware - if this procedure ever does more than just save the
# database it may need to be called when user exits interface because
# there is a lock on the log file

# Remove lock on directories.def
  set filename [datapath directories.def.LOCK -user -domain]
  DeleteLock $filename

# Close the database
  DbClose
  exit 0
}


#----------------------------------------------------------------
proc CreateTitleLine { lineVar element } {
#----------------------------------------------------------------
#d_sum Draw the title line which is standard at top of task window.
#d_arg lineVar Return the Tk frame id for the line
#d_arg element The name of the parameter holding the title text.

# Draw a standard title line
  upvar $lineVar line

  set arrayname [ GetSystemVar frame_array ]

  CreateLine line \
    message "Enter job title (use only alphanumeric, spaces, brackets and underscores)" \
    help  title \
    label "Job title" \
    widget $element  -expand \
      -command "check_title_line $arrayname $element"
}


#----------------------------------------------------------------
proc CreateTitleLineLink { lineVar element urlLink linkString } {
#----------------------------------------------------------------
#d_sum Draw the title line which is standard at top of task window \
and provide a link button to a url address.
#d_arg lineVar Return the Tk frame id for the line
#d_arg element The name of the parameter holding the title text.
#d_arg urlLink The url address for the link button (e.g. "http://www.ccp4.ac.uk").
#d_arg linkString The description string to be displayed on the button (e.g. "Mtzdump user guide").

  global configure

  # Draw a standard title line
    upvar $lineVar line

    set arrayname [ GetSystemVar frame_array ]

    CreateLine line \
      message "Enter job title (use only alphanumeric, spaces, brackets and underscores)" \
      help  title \
      label "Job title" \
      widget $element  -width 65 \
        -command "check_title_line $arrayname $element"

    set link_target $urlLink
    set urlbrowser [button $line.urlbrowser \
          -text $linkString \
          -command "open_url $link_target -remote"]

    $urlbrowser configure -font $configure(FONT_SMALL)
    pack $urlbrowser -side left
}


#------------------------------------------------------------------
proc check_title_line { arrayname element } {
#------------------------------------------------------------------
#d_sum Hander when user enters title line test to remove 'bad' characters
#d_arg arrayname Name of array containing parameters for task
#d_arg element The name of the parameter holding the title text.

  upvar #0 $arrayname array
  set array($element)  [RemoveMetaChars $array($element) -title]
}


#--------------------------------------------------------------------
proc WriteCredits { author_list args } {
#--------------------------------------------------------------------
#d_sum Write author credits at bottom of task window
#d_arg author_list A list of authors (NB should be Tcl list)
#d_opt0 -link link_text link_target
#d_opt1 A URL link to be added to credits line.
#d_opt0 -label lab
#d_opt1 Override the default text 'Program author'

  global configure

  set arrayname [ GetSystemVar frame_array ]
  upvar #0 $arrayname array
  set line $array(WINDOW).credit

  set iflink 0
  set lab "Program author"
  if { [llength $author_list] > 1 } { append lab s }

  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    link { 
      set iflink 1
      incr n; set link_text [lindex $args $n]
      incr n; set link_target [lindex $args $n]
    } label {
      incr n; set lab [lindex $args $n]
    }
    incr n
  }

  frame $line
  pack $line -side bottom -before $array(WINDOW).buttons \
		-fill x -expand 1 -anchor e

  label $line.ll -text "[subst $lab]:" \
	-font $configure(FONT_SMALL) \
        -anchor w
  lappend pack_list $line.ll

  set n 0;foreach author $author_list { incr n
    label $line.a$n -text "$author" \
	-font $configure(FONT_SMALL) \
        -anchor w
    lappend pack_list $line.a$n
  }
  eval "pack $pack_list -side left -anchor e"

  if {$iflink} {
    label $line.link -text $link_text \
                -font $configure(FONT_ITALIC) \
                -foreground blue \
                -anchor w
    pack $line.link -side left -anchor e

    bind $line.link <Button-3> "open_url $link_target -remote"
    bind $line.link <Button-1> "open_url $link_target -remote"

    # Change the cursor to a pointing hand when over the link
    bind $line.link <Enter> "$line.link config -cursor hand2"
    bind $line.link <Leave> "$line.link config -cursor {}"
  }
}

#--------------------------------------------------------------------
proc WriteImage { linein args } {
#---------------------------------------------------------------------
#d_sum Write an image into a task window
#d_desc WriteImage accepts images as either files or as Tcl images \
(created using the Tcl image command). If using an image file then \
the command will try to determine the type (currently either bitmap \
or photo) from the filename extension. To over-ride this, use the \
-type option to explicitly set the type.
#d_desc See the Tcl image command for more information on images.
#d_arg linein Return the Tk frame id for the line
#d_opt0 -file
#d_opt1 File name specifying the image. Not required if using the \
-image option.
#d_opt0 -type
#d_opt1 Image type as recognised by the Tcl image command. Not \
required if using the -image option.
#d_opt0 -image
#d_opt1 Identifier of an image already created by the Tcl image command. \
Not required if using the -file option.

  upvar $linein line

  # Initialise
  set image_type ""
  set image_file ""
  set image_name ""

  # Read the args
  set n_args [llength $args ]
  set n 0; while { $n < $n_args } {
    set option [lindex $args $n]
    switch -- $option {
      -file {
         incr n
         if { $n < $n_args } { set image_file [lindex $args $n] }
      }
      -type {
         incr n
         if { $n < $n_args } { set image_type [lindex $args $n] }
      }
      -image {
         incr n
         if { $n < $n_args } { set image_name [lindex $args $n] }
      }
      default {
	 # Report an unknown option
         Report 3 "WriteImage: unknown option \"$option\""
         return 0
      }
    }
    # Next argument
    incr n
  }

  # If an image file was specified then sort this out first
  if { $image_file != "" } {
    if { [file exists $image_file] } {
      # What is the image type?
      if { $image_type == "" } {
        # Type not explicitly set so try to guess
        switch -regexp [file extension $image_file] {
	  xbm|XBM {
            set image_type "bitmap"
          }
          gif|GIF|ppm|PPM|pgm|PGM {
            set image_type "photo"
          }
          default {
            set image_type "unknown"
          }
        }
      }
      
      # Check that this is a usable type
      if { [lsearch [image types] $image_type] < 0 } {
        # Image type not supported
        Report 3 "WriteImage: unsupported image type \"$image_type\""
	return 0
      }
    }
  }

  # Do we need to make a new image?
  if { $image_name != "" || [lsearch [image names] $image_name] < 0 } {
    # Image doesn't exist - make a new one
    if { [file exists $image_file] } {
      if { [catch \
	      { set image_name [image create $image_type -file $image_file] } \
	      errmsg] } {
        # Image creation failed
        Report 3 "WriteImage: failed to make image \"$errmsg\""
        return 0
      }
    }
  }

  # Display the image
  CreateLine line
  set limg [label $line.image -image $image_name]
  pack $limg

  return 1
}

#--------------------------------------------------------------------
proc RunUtility { utilname run_command } {
#--------------------------------------------------------------------
#d_sum Start up a utility using the specified command
#d_desc This procedure is called when the user clicks on a utility in the \
modules and tasks menu.
#d_desc This command may ultimately be better placed elsewhere in the \
CCP4i source code, however it is loosely analogous to RunTask - which is \
why it appears here for now.
#d_arg utilname    The name of the utility as it appears on the \
launch button
#d_arg run_command Command to be executed to start the utility
  set status [expr {1 - [ catch { eval exec $run_command & } errmsg ]} ]
  if { !$status } {
    WarningMessage "ERROR could not start $utilname
$errmsg

This may be due to a configuration  problem
Check the settings in System Administration/Configure
Interface"
    return 0
  }
  return 1
}
