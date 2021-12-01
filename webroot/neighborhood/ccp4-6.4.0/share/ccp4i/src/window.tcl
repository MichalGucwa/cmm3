#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - window.tcl
#
#
#
# General graphics display
#
#====================================================================


#CCP4i_cvs_Id $Id$


set system(EXFRAME_EDIT_OPEN) ""
set system(DEFDIR_WIDGET_LIST) ""

# Create a global binding to deiconify and raise any
# window that has this modalDialog tag
bind modalDialog <ButtonPress> {
  wm deiconify %W
  raise %W
}
 
#d_index_title Creating Windows (src/window.tcl)
#d_intro_title Creating Windows
#d_intro These are general window drawing procedures.  Some procedures which \
are specific to drawing task windows are in taskwindows.tcl and some procedures \
which will draw one simple utility window are defined in util_windows.tcl.

#d_intro All of the 'standard' windows in CCP4i are created with some standard \procedures:
#d_intro OpenWindow: creates the shell of a window
#d_intro CreateFrame: called after OpenWindow to create the basic internal \
folder structure and (very important) to attach an array to the window
#d_intro CreateTaskWindow: Does everything OpenWindow and CreateFrame do plus \
creating some standard action buttons and titled folders.

#d_intro The array which is attached to the window contains elements which \
are associated with the various widgets on the window and contain the \
currently entered or selected values for the parameters. These elements of the \array correspond to the parameters found in the def file for a task window or \
which must be defined by the DefineVariable command for use with CreateFrame. \
There are also elements of the array which perform a control function for \
things like the message line, the toggleable folders etc.. The elements have \
names which begin with uppercase e.g. PARAM_FRAME_nn.
#d_intro Many procedures require the name of the data array as an argument -\
almost always referred to as arrayname.  Some routines (e.g. CreateLine) do \
not require the array name to be input but get it from a saved 'system' \
variable which has been set by CreateFrame or CreateTaskWindow. This system \
variable can only be reliably used while the window is being initially \
defined. Any command which might be issued at a later time (after the user \
might have opened another window and the system variable being changed) must \
explicitly input the array name.

#-------------------------------------------------------------------
proc OpenWindow { w title icon_name args } {
#-------------------------------------------------------------------
#d_sum Open a graphical window
#d_desc This will open a window with a message bar and Help button but without \
the folder structure or default action buttons of the task window opened by\
CreatetaskWindow.  This procedure is useful for creating more customised \
graphics windows and is used mostly by the 'core' ccp4i.
#d_desc The window does not absolutely need to have an associated data array \
but will need to have an array defined if it is to support the message line.
#d_desc See also OpenGridWindow
#d_arg w Name of toplevel window.  If this window exists the procedure does nothing.
#d_arg title Title to appear at top of window
#d_arg icon_name Short title to appear if the window is iconised
#d_opt0 -help help_file
#d_opt1 Enter the name of a help file to be attached to the window help button
#d_opt0 -target help_target
#d_opt1 Set target in the help file to help_target
#d_opt0 -message arrayname
#d_opt1 Display an message line and use the standard elements of the array arrayname to contain the required message text.
#d_opt0 -class class
#d_opt1 Enter a class definition for the Tk toplevel command NOT USED
#d_opt0 -nomessage REDUNDANT
#d_opt0 -resizeable
#d_opt1 The window will be resizable by the user
#d_opt0 -parent arrayname
#d_opt1 Arrayname is the data array for a 'parent' window. If the parent window is closed then its children will also be closed
  global configure

  if { [winfo exists $w] } {
    wm withdraw $w
    wm deiconify $w
    raise $w
    return 0
  }

  set help_file ""
  set help_target ""
  set class ""
  set group ""
  set message 0
  set resizeable 0
  set arrayname ""

  set nargs [ llength $args]; set i 0
  while { $i < $nargs } {
    set comd [lindex $args $i ]
    if { $comd == "-help" } {
      incr i; set help_file [lindex $args $i ]
    } elseif { $comd == "-message" } {
      incr i; set arrayname [lindex $args $i ]
      set message 1
    } elseif { $comd == "-target" } {
      incr i; set help_target [lindex $args $i ]
    } elseif { $comd == "-class" } {
      incr i; set class [lindex $args $i ]
    } elseif { $comd == "-group" } {
      incr i; set group [lindex $args $i ]
    } elseif { $comd == "-nomessage" } {
      set message 0
    } elseif { $comd == "-resizeable" } {
      set resizeable 1
    } elseif { $comd == "-parent" } {
      incr i; set arrayname [lindex $args $i ]
      upvar #0 $arrayname array
      if { [lsearch $array(CHILDREN) $w ] < 0 } {
        lappend array(CHILDREN) $w
      }
    }
    incr i
  }

  if { $class != "" } {
    toplevel $w -class $class
  } else {
    toplevel $w 
  }
  wm title $w "[GetSystemVar VERSION] $title"
  wm iconname $w $icon_name
  wm iconbitmap $w @[SearchPath TOP icons window_icon]
  if { [ElementExists configure AUTO_POSITION] && $configure(AUTO_POSITION) } {
     wm positionfrom $w user }
  if { $group != "" } { wm group $w $group }
  if { $resizeable == 0 } { wm resizable $w 0 0 }

  if { $message } {
    upvar #0 $arrayname array
    set array(MESSAGEVAR) " "
    set array(MESSAGEBLOCK) 0
    set mesbar [ frame $w.mesbar ]
    pack $mesbar -side top -fill x
    label $mesbar.l1 \
      -font $configure(FONT_REGULAR) \
      -textvariable [subst $arrayname](MESSAGEVAR)  \
      -relief raised -fg $configure(COLOUR_BOLD)  -bg $configure(COLOUR_CONTRAST)\
      -justify left \
      -anchor w
    pack $mesbar.l1 -side left  -fill both -expand 1
#    pack propagate $mesbar.l1 0
  } else {
#    set array(MESSAGEBLOCK) 1
  }

  set cmd "open_url $help_file" 
  if { $help_target != "" } {append cmd " -target $help_target" }

  if { $message && $help_file != "" && [file exists $help_file] } {
    button $mesbar.help -text "Help" \
	-padx 7 -pady 2 -borderwidth 1  \
	-font $configure(FONT_REGULAR) \
        -command "$cmd"
    pack $mesbar.help -side right
  }
  return 1
}

#--------------------------------------------------------------------
proc OpenGridWindow { arrayname w title icon_name args }  {
#--------------------------------------------------------------------
#d_sum Similar to OpenWindow but uses grid geometry manager
#d_desc When the child frames are arranged using the grid geometry \
manager it seems to be necessary to use grid all the way through the \
window definition. This procedure is used for customised window such \
as the file browser and sketcher rather than being a proper API.
#d_desc The window is automatically created with a message bar and buttons \
frame and two additional frames called $w.main and $w.utils
#d_arg arrayname Name of data array
#d_arg w Name of toplevel window.  If this window exists the procedure does nothing.
#d_arg title Title to appear at top of window
#d_arg icon_name Short title to appear if the window is iconised
#d_opt0 -help help_file
#d_opt1 Enter the name of a help file to be attached to the window help button
#d_opt0 -target help_target
#d_opt1 Set target in the help file to help_target
#d_opt0 -class class
#d_opt1 Enter a class definition for the Tk toplevel command NOT USED
#d_opt0 -menu
#d_opt1 Create a pull-down menu frame


  upvar #0 $arrayname array
  global configure

  set array(MESSAGEVAR) " "
  set array(MESSAGEBLOCK) 0
  set help_file ""
  set help_target ""
  set class ""
  set menu 0

  set n 0; set nargs [llength $args]
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    help {
      incr n; set help_file [lindex $args $n]
    } target {
      incr n; set help_target [lindex $args $n]
    } class {
      incr n; set  class [lindex $args $n]
    } menu {
      set menu 1
      incr n; set menulist [lindex $args $n]
    } 
    incr n
  }

  if { $class != "" } {
    toplevel $w -class  $class
  } else {
    toplevel $w 
  }
  wm title $w $title
  wm iconname $w $icon_name
  wm iconbitmap $w @[SearchPath TOP icons window_icon]
  if { $configure(AUTO_POSITION) } {wm positionfrom $w user }


  if { $menu } {  set wmenu [frame $w.menu  \
                -background $configure(COLOUR_CONTRAST)] }
  set wmess [ frame $w.mesbar -borderwidth 2 -relief ridge            \
        -background $configure(COLOUR_CONTRAST) ]
  set wmain [frame $w.main]
  set wutils [frame $w.utils]
  set wbuttons [frame $w.buttons]

  if { $menu } { grid $wmenu -row 0 -column 0  -sticky we }
  grid $wmess -row [expr {0 + $menu}] -column 0  -sticky we
  grid $wmain -row [expr {1 + $menu}] -column 0  -sticky nswe
  grid $wutils -row [expr {2 + $menu}] -column 0  -sticky nswe
  grid $wbuttons -row [expr {3 + $menu}] -column 0  -sticky we

  grid columnconfigure $w 0  -weight 1
  if { $menu } {  grid rowconfigure $w 0 -weight 0 }
  grid rowconfigure $w [expr {0 + $menu}]   -weight 0
  grid rowconfigure $w [expr {1 + $menu}]   -weight 1
  grid rowconfigure $w [expr {2 + $menu}]   -weight 0
  grid rowconfigure $w [expr {3 + $menu}]   -weight 0

#
# Fill in the menubar
#
  if { $menu } {
    foreach mm $menulist {
      set m [menubutton $w.menu.[lindex $mm 0] \
                -text "[lindex $mm 1]" \
                -menu $w.menu.[lindex $mm 0].m \
                -background $configure(COLOUR_CONTRAST) \
                -underline 0 ]
      pack $m -side left
      menu $w.menu.[lindex $mm 0].m  -tearoff 0
    }
  }
#

#
# Set up the title line and help button
#
  set array(MESSAGEVAR) " "
  set array(MESSAGEBLOCK) 0

  label $wmess.l1 \
      -textvariable [subst $arrayname](MESSAGEVAR)  \
      -font $configure(FONT_REGULAR) \
      -relief raised -fg $configure(COLOUR_BOLD)  -bg $configure(COLOUR_CONTRAST)\
      -justify left \
      -anchor w
    pack $wmess.l1 -side left  -fill both -expand 1

  set cmd "open_url $help_file" 
  if { $help_target != "" } {append cmd " -target $help_target" }

  if { $help_file != "" && [file exists $help_file] } {
    if { $menu } {
      button $w.menu.help -text "Help" \
          -anchor e -borderwidth 1 \
          -command "$cmd"
      pack $w.menu.help -side right
   } else {
      button $wmess.help -text "Help" \
          -anchor e -borderwidth 1 \
          -command "$cmd"
      pack $wmess.help -side right
   }
  }
  return 1
}

#-------------------------------------------------------------------
proc CloseWindow { arrayname args } {
#-------------------------------------------------------------------
#d_sum Close a window opened by OpenWindow, OpenGridWindow or OpenTaskWindow
#d_arg arrayname Name of data array for the window
#d_opt0 -window window
#d_opt1 Set the window id (the Tk id) to override the default array(WINDOW)
#d_opt0 -unset
#d_opt1 Unset the whole of array
  global system
  upvar #0 $arrayname array

  set window ""
  set unset 0
  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    window {
      incr n; set window [lindex $args $n]
    } unset {
      set unset 1
    }
    incr n
  }
  if { $window == "" } { set window $array(WINDOW) }

  if { [winfo exists $window] } { destroy $window }
  
# Delete any traces or there will be problems when try setting variable 
# values before the window is recreated

  if { [ElementExists $arrayname TRACE_LIST ] &&
       [ llength $array(TRACE_LIST) ] > 0  } {
    foreach element $array(TRACE_LIST) {
      set trace_list [trace vinfo array($element) ]
      foreach trace $trace_list {
        set ops [lindex $trace 0]
        set command [lindex $trace 1 ]
        trace vdelete array($element) $ops $command
      }
    }
  }

# Destroy any sub window still open.  Beware the fileselect window
# which uses the task interface so has frame information in the array
# which requires call to UnsetArrayExtras

  if { [ ElementExists $arrayname CHILDREN ] } {
    foreach w $array(CHILDREN) {
      if { [winfo exists $w ] } {
        destroy $w
        set subarray [string range $w 1 end ]
        global $subarray
        if {[array exists $subarray] } {
          UnsetArrayExtras $subarray }
      }
    }
  }
  set array(CHILDREN) ""

  if { $unset } { unset array }

}

#-----------------------------------------------------------------
proc CreateFrame { w arrayname args } {
#-----------------------------------------------------------------
#d_sum Set up a frame structure (i.e. folders) in a window opened by OpenWindow
#d_desc To support the folder structure there must definitely be a data array \
associated with the window to contain the control parameters for the folders. \
By default the window will have a vertical scroll bar.
#d_arg w The window id (a Tk id)
#d_arg arrayname The data array for the window
#d_opt0 -noscroll
#d_opt1 Do not create a scroll bar.
  upvar #0 $arrayname array
# Data used in defining the contents of each frame

  set scroll 1
  if { [lsearch $args "-noscroll" ] >= 0 } { set scroll 0 }

  SetSystemVar block_scroll_update 0
  SetSystemVar frame_parent $w.main.canvas.contents
  SetSystemVar frame_array $arrayname
  SetSystemVar frame_program_help ""
  SetSystemVar current_index_counter ""
# Open the protocol folder
  SetSystemVar open_frame_name protocol
  SetSystemVar open_frame $w.main.canvas.contents.protocol
  SetSystemVar blttable -1

  set array(UNDEFINEDS) 0
  set array(FRAMES_DRAWN) 0
  set array(CHILDREN) ""
  set array(LINES_DRAWN) 0
  set array(WINDOW) $w
  set array(UPDATE_SCRIPTS) ""
  set array(TRACE_LIST) ""
  if { ![ElementExists $arrayname TASK_TITLE] } {
    set array(TASK_TITLE) ""
  }

  set wbuttons $w.buttons
  if { ![winfo exists $wbuttons] } {
    frame $wbuttons -relief raised
    pack $wbuttons -side bottom -fill x -pady 2m
  }

  if { ![winfo exists $w.main] } {
    frame  $w.main
    pack $w.main -side top -fill x
  }

  if { $scroll } {
# Make a scrolled frame...
    scrolled_frame $w.main  {
      set main $w.main.canvas.contents
      set wprotocol $main.protocol
      frame $wprotocol -relief ridge -borderwidth 1
      pack $wprotocol -side top -fill x
    }
    update_main_scroll $w

  } else {

     frame  $w.main.canvas
     pack $w.main.canvas  -side top -fill both
     set main [frame  $w.main.canvas.contents ]
     pack $w.main.canvas.contents  -side top -fill both
     set wprotocol $main.protocol
     frame $wprotocol -relief ridge -borderwidth 1
     pack $wprotocol -side top -fill both
  }
  if { [StringSame [winfo toplevel $w] $w] } {  wm deiconify $w }
}

#---------------------------------------------------------------------
proc CloseFrame { } {
#---------------------------------------------------------------------
#d_sum End the definition of a frame.
#d_desc This procedure calls update_main_scroll to set the final size of the \
scrollable frame and run_update_script which tidies up extending frames.
  run_update_script [ GetSystemVar frame_array ]
  update_main_scroll  [ GetSystemVar frame_parent ]
}


#--------------------------------------------------------------------------
proc OpenFolder { frame args } {
#--------------------------------------------------------------------------
#d_sum Begin the definition of a folder in a task window
#d_ref  CCP4I programmers/OpenFolder.html See the CCP4i Programmers Documentation

  set arrayname [GetSystemVar frame_array ]
  upvar #0 $arrayname array


  set parent [GetSystemVar frame_parent]
  if { $frame == "file" || $frame == "protocol" 
         || $frame ==  "options" } {
    set open_frame $parent.$frame
  } else {
    set open_frame $parent.param_$frame.body
  }

  SetSystemVar open_frame_name $frame
  SetSystemVar open_frame $open_frame


  if { [llength $args] == 0 } {
    return
  } elseif {  [llength $args] == 1 } {
    set array(PARAM_FRAME_$frame) $args
    update_folder_display $frame $arrayname
  } else {

    set element [lindex $args 0 ]
    set cmd "update_folder $frame $arrayname $args"


    if { [lsearch $array(TRACE_LIST) $element] < 0 }  {
        lappend array(TRACE_LIST) $element
        trace variable array($element) w "update_main_scroll $open_frame"
    }
    trace variable array($element) w $cmd


# Oh heck!  update_folder is usually invoked by the trace command which
# appends three extra arguments - so to be consistent append extra arguments here
# and ignore them in update_folder procedure

    eval "$cmd junk junk junk"
  }
}

#-----------------------------------------------------------------------------
proc update_folder { folder arrayname element args } {
#-----------------------------------------------------------------------------
#d_sum Update visibility of folder dependent on protocol defined by OpenFolder
#d_desc NB this procedure is called from the 'trace variable' function and \
has three redundant arguments appended to args
#d_arg folder The folder id 
#d_arg arrayname The name of the task array
#d_arg element The array element which controls the visibility of the folder
#d_arg args The arguments input to OpenFolder and defined in:
#d_ref  CCP4I programmers/OpenFolder.html See the CCP4i Programmers Documentation
  upvar #0 $arrayname array

# Remove deundant args
  set nargs [ expr {[llength $args] - 3} ]
  for { set n  [expr {$nargs / 2 + 1} ] } { $n >= 1  } { incr n -1 } {
    set state [lindex $args [expr {( $n * 2) - 2}  ] ]
    set ll  [expr {( $n * 2 ) -1} ]
    if { $ll >= $nargs  || \
       [lsearch  [lindex $args $ll] "$array($element)" ] >= 0 || \
       [lsearch  [lindex $args $ll] [GetValue $arrayname $element]] >= 0 } {
       set array(PARAM_FRAME_$folder) $state
    }
  }
  update_folder_display $folder $arrayname
}

#----------------------------------------------------------------
proc update_folder_display { frame arrayname { mode {} } } {
#----------------------------------------------------------------
#d_sum Switch on or off the display of folders dependent on the \
value of the switch parameter
#d_arg frame The number of a folder or 'all'
#d_arg arrayname Name of data array
#d_arg mode Optional If mode=view then scroll task window so the opened \
folder is visible (but this may not be functional).
  upvar #0 $arrayname array

  if { $frame == "all" }  {
    set first 1
    set last $array(N_PARAM_FRAME)
  } else {
    set first $frame
    set last $frame
  }

  set w $array(WINDOW).main.canvas.contents

  for { set i $first } { $i <= $last } { incr i } {
    set element "PARAM_FRAME_$i"
    set wframe $w.param_$i
    if { $array($element) == "open" } {
       pack $wframe.body  -side top -fill x
    } elseif { $array($element) == "closed" } {
       pack forget $wframe.body
    }
#    puts "update_folder_display $i $array($element)"
  }
  for { set i 1 } { $i <= $array(N_PARAM_FRAME) } { incr i } {
    pack forget $w.param_$i
  }

  for { set i 1 } { $i <= $array(N_PARAM_FRAME) } { incr i } {
    if { $array(PARAM_FRAME_$i) != "hide" } {
      pack  $w.param_$i -side top -fill x
    }
  }

  if { $mode == "view" } {

    if { ![regexp all $frame] && [regexp open $array($element)] } {
      set toth [expr {[winfo reqheight $w.protocol] + \
                        [winfo reqheight $w.file]} ]
      for { set i 1 } { $i <= $array(N_PARAM_FRAME) } { incr i } {
        if { $i == $frame } { set xtop $toth }
        set toth [ expr {$toth + [winfo reqheight $w.param_$i]} ]
      }
      $array(WINDOW).main.canvas yview moveto \
                [expr {double($xtop)/double($toth)}]
    }
  }
}

#----------------------------------------------------------------------------
proc  OpenSubFrame { framein args } {
#----------------------------------------------------------------------------
#d_sum Open a sub frame  within the context of OpenWindow/CreateFrame or CreateTaskWindow
#d_ref CCP4I programmers/OpenSubFrame.html See CCP4I Programmers Documentation
  upvar $framein frame
  set arrayname [GetSystemVar frame_array ]
  upvar #0 $arrayname array

  set appearance ""
  set toggle 0
  set blttable [list -1 {} {} {} ]

  set n 0;set nargs [llength $args]
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    appearance {
      incr n; set appearance [lindex $args $n]
    } toggle {
      set toggle 1
      incr n; set toggle_args [lrange $args $n [expr {$n + 2}]]
      incr n 2
    } table {
      set blttable [lreplace $blttable 0 0 0]
    } anchor {
      incr n; set blttable [lreplace $blttable 1 1 [lindex $args $n]]
    } columnwidth {
      incr n; set blttable [lreplace $blttable 2 2 [lindex $args $n]]
    } rowheight {
      incr n; set blttable [lreplace $blttable 3 3 [lindex $args $n]]
    }
    incr n
  }
  set frame [ GetSystemVar open_frame ]
  incr array(FRAMES_DRAWN)
  append frame ".f" $array(FRAMES_DRAWN)
  SetSystemVar open_frame $frame

  if { $appearance != ""  } {
    eval [concat frame $frame $appearance]
  } else {
    frame $frame
  }
  pack $frame -side top -fill x -expand 1 -anchor e

  if { [lindex $blttable 0] == 0 } { blt::table $frame }
  SetSystemVar blttable $blttable

  if {  $toggle } {
    toggle_frame_display $frame [lindex $toggle_args 0] \
      [lindex $toggle_args 1] [lindex $toggle_args 2]
  }

  return $frame
}

#-------------------------------------------------------------------------
proc CloseSubFrame {} {
#-------------------------------------------------------------------------
#d_sum Close a sub frame 
#d_ref CCP4I programmers/CloseSubFrame.html See CCP4I Programmers Documentation

  set frame [GetSystemVar open_frame ]
  set blttable [GetSystemVar blttable]

  if { [set nrows [lindex $blttable 0]] > 0 } {
# Apply any blt table options set in OpenSubFrame
    if { [set nwidth [llength [set width [lindex $blttable 2]] ]] > 0 } {
# Set the width of columns
      for { set ic 0 } { $ic < $nwidth } { incr ic } {
        blt::table configure $frame C$ic -width [lindex $width $ic]
      }
    }

    if { [set nheight [llength [set height [lindex $blttable 3]] ]] > 0 } {
# Set the height of rows
      for { set ir 0 } { $ir < $nheight } { incr ir } {
        blt::table configure $frame R$ir -height [lindex $height $ir]
      }
    }
  }


# Reset the current open frame to the parent of the present frame
  set ndot [string last "." $frame ]
  set frame [string range $frame 0 [expr {$ndot - 1} ] ]
  SetSystemVar open_frame $frame
  SetSystemVar blttable -1
}

#-----------------------------------------------------------------------
proc toggle_frame_display {line element hitstate hitlist {table_row -1} } {
#-----------------------------------------------------------------------
#d_sum Set up a trace command for handler controlling visibility of a line or subframe
#d_arg line Tk id of the line or frame
#d_arg element Array element controlling line/frame visibility
#d_arg hitstate  Visibility state ('open' or 'hide') if value of element matches any value in hitlist
#d_arg hitlist Tcl list of possible values for the control parameter
  set arrayname [GetSystemVar frame_array]
  upvar #0 $arrayname array

  if { $table_row >= 0 } {
    set cmd "update_table_row $line $arrayname $element {$hitlist}  \
             $hitstate $table_row [blt::table cget $line R$table_row -height]"
  } else {
    set cmd "update_frame_display $line $arrayname $element {$hitlist}  \
                                     $hitstate"
  }
  if { [lsearch $array(TRACE_LIST) $element] < 0 }  {
	lappend array(TRACE_LIST) $element
	trace variable array($element) w "update_main_scroll $line"
  }

  trace variable array($element) w $cmd

# If the controlling array element is already defined then set the 
# line display

  if { [ElementExists $arrayname $element] } { eval "$cmd" }

}

#-----------------------------------------------------------------------
proc update_frame_display { line arrayname element hitlist hitstate args } {
#-----------------------------------------------------------------------
#d_sum Handler controlling visibility of a line or subframe
#d_desc Called when user changed value of the control parameter 
#d_arg line Tk id of the line or frame
#d_arg arrayname name of data array
#d_arg element Array element controlling line/frame visibility
#d_arg hitstate  Visibility state ('open' or 'hide') if value of element matches any value in hitlist
#d_arg hitlist Tcl list of possible values for the control parameter
  upvar #0 $arrayname array

# Make sure the line still exists - it may have been closed if it is part 
# of an extending frame


  if { ![winfo exists $line ] } { return }
#  set w $array(WINDOW)

# Make sure we're using the correct array elsewhere
  SetSystemVar frame_array $arrayname

#  puts "update_frame_display element $element"
#
# decide whether to hide or open the line
# If the current value of  $array($element) is not in the hit list
# then see if the menu alias for that value is in the hit list
#
  set pp [lsearch $hitlist $array($element)]
  if { $pp < 0 } { set pp [lsearch $hitlist [GetValue $arrayname $element]] }
  if { ($pp >= 0 && $hitstate == "hide") ||
       ($pp == -1 && $hitstate == "open" )  } { 
    set operation "hide"
  } elseif { ($pp >= 0 && $hitstate == "open") ||
       ($pp == -1 && $hitstate == "hide" )  } {
    set operation "open"
  }
#  puts "update_frame_display element $element $array($element) $operation"

  if { $operation == "hide" } {

    pack forget $line

  } else {

    set parent [winfo parent $line]
    set children [winfo children $parent]
    set linenumber [lsearch $children $line]
    set nlines [llength $children]

    set command "pack $line -side top -fill x"
    set after ""
    set before ""

    if { $linenumber > 0 } {
      set i $linenumber
      while { $i > 0 && $after == "" } {
        incr i -1
        if { [ winfo manager [lindex $children $i]] == "pack" } {
          append command " -after [lindex $children $i]"
          set after " -after [lindex $children $i]"
        }
      }
    }
    set i $linenumber
    while { $i < [expr {$nlines -1}] && $before == "" } {
      incr i
      if { [ winfo manager [lindex $children $i]] == "pack" } {
        append command " -before [lindex $children $i]"
        set before  " -before [lindex $children $i]"
      }
    }

    if { [array names array LINE_$line] == "LINE_$line" } {
      set packmode $array(LINE_$line)
      if { $packmode == "MTZlabel" } {
         PackLabinLine $line $before $after
         set command ""
      } elseif { [lindex $packmode 0 ] == "template" } {
         set pack_template [lindex $packmode 1 ]
         PackByTemplate $line $pack_template
      } elseif {  [lindex $packmode 0 ] == "expand" } {
         append command " -expand 1"
      }
    }
    if { $command != "" } { eval "$command"}
  }
#  update_main_scroll $line

}

#---------------------------------------------------------------------------
proc update_table_row { table arrayname element hitlist hitstate \
		table_row height args } {
#---------------------------------------------------------------------------
#d_sum Toggle the display of a line in the table dependent on value of some varaible
#d_desc This proc is equivalent to update_frame_display but for rows \
in a table and is called when the variable is changed.  The row is made \
invisible by setting the height to zero.
#d_arg table Tk id of the table 
#d_arg arrayname name of data array
#d_arg element Array element controlling line/frame visibility
#d_arg hitstate  Visibility state ('open' or 'hide') if value of element matches any value in hitlist
#d_arg hitlist Tcl list of possible values for the control parameter
#d_arg table_row The number of the row in the table (first row = 0)
#d_arg height The normal height of the row when it is displayed
  upvar #0 $arrayname array
  if { ![winfo exists $table ] } { return }
  if { [set pp [lsearch $hitlist $array($element)]] } { 
     set pp [lsearch $hitlist [GetValue $arrayname $element]] }
  if { ($pp >= 0 && $hitstate == "hide") ||
       ($pp == -1 && $hitstate == "open" )  } {
    set operation "hide"
    blt::table configure $table R$table_row -height 0.0
  } elseif { ($pp >= 0 && $hitstate == "open") ||
       ($pp == -1 && $hitstate == "hide" )  } {
    blt::table configure $table R$table_row -height  $height
  }
}
#-----------------------------------------------------------------------
proc toggle_button_disabled { button element hitstate hitlist } {
#-----------------------------------------------------------------------
#d_sum Set up a trace command for handler controlling greying of a varbutton
#d_arg line Tk id of the line or frame
#d_arg element Array element controlling line/frame visibility
#d_arg hitstate  Visibility state ('open' or 'hide') if value of element matches any value in hitlist
#d_arg hitlist Tcl list of possible values for the control parameter
  set arrayname [GetSystemVar frame_array]
  upvar #0 $arrayname array

  #return
  set cmd "update_button_disabled $button $arrayname $element {$hitlist}  \
                                     $hitstate"

  trace variable array($element) w $cmd

# If the controlling array element is already defined then set the 
# line display
  if { [ElementExists $arrayname $element] } { eval "$cmd" }

}
#-----------------------------------------------------------------------
proc update_button_disabled { button arrayname element \
	                    hitlist hitstate args } {
#-----------------------------------------------------------------------
#d_sum Handler controlling greying out of a varbutton
#d_desc Called when user changed value of the control parameter 
#d_arg button Tk id of the button
#d_arg arrayname name of data array
#d_arg element Array element controlling line/frame visibility
#d_arg hitstate  Visibility state ('open' or 'hide') if value of element matches any value in hitlist
#d_arg hitlist Tcl list of possible values for the control parameter

  upvar #0 $arrayname array

  if { ![winfo exists $button ] } { return }
  set pp [lsearch $hitlist $array($element)]
  if { $pp < 0 } { set pp [lsearch $hitlist [GetValue $arrayname $element]] }
  if { ($pp >= 0 && $hitstate == "disabled") ||
       ($pp == -1 && $hitstate == "normal" )  } { 
    set operation "disabled"
  } elseif { ($pp >= 0 && $hitstate == "normal") ||
       ($pp == -1 && $hitstate == "disabled" )  } {
    set operation "normal"
  }
#  puts "update_button_grey element $element $array($element) $operation"

  if { $operation == "disabled" } {
    $button configure -fg gray -state $operation
  } else {
    $button configure -fg black -state $operation
  }
}


#------------------------------------------------------------------------------
proc scrolled_frame {w contents} {
#------------------------------------------------------------------------------
#d_sum Create a scrollable frame
#d_desc The mechanism for creating a scrolling frame is devious. This \
procedure will create the basic scrollable frame and scroll bar and will \
then create the required contents of the scrollable frame by evaluating \
the script which is passed into this procedure as a block of text. The \
script is actually evaluated in the variable context one level up by using \
the uplevel command.
#d_desc This is a very important procedure used by all windows with scroll bars.
#d_arg w The window id (a Tk id)
#d_arg contents The text for a script to define the contents of the frame.

    canvas $w.canvas \
            -yscrollcommand [list $w.vs set] -bd 0
    scrollbar $w.vs -command [list $w.canvas yview] -orient vertical

   pack $w.vs -side right -fill y
   pack $w.canvas -side left -fill both -expand true
   pack $w -side top -fill both -expand true

   set ww [frame $w.canvas.contents ]

    # Make the contents
    uplevel $contents

    # Now plug the scrolled area into the scroller, and set the
    # scrolling area up properly
    return [$w.canvas create window 0 0 -anchor nw -window $ww]

}
#----------------------------------------------------------------------
proc update_main_scroll { frame args } {
#----------------------------------------------------------------------
#d_sum Update the scrollable extent of a task window.
#d_desc The mechanism controlling scrolling needs to know the extent \
of the scrollable frame in the task window. This update is slow \
and is done only if the number of lines displayed \
in a task window has changed.  If the system parameter \
block_scroll_update is set to 1 (true) then update_main_scroll \
does nothing. This blocking mechanism is used to prevent any \
unnecessary and time consuming update of the scrollable extent while \
the task window is initially being drawn.
#d_arg frame The Tk frame id of any frame or widget within the task window.

  if { [GetSystemVar block_scroll_update ]  == 1 } { return }

#  puts "update_main_scroll $frame"

  update idletasks
  set top [winfo toplevel $frame]
  if { ![winfo exists $top.main.vs] } { return }
  set ww $top.main.canvas.contents
  set w $top.main

  wm geometry $top ""

  set height [winfo reqheight $ww]
  set width [winfo reqwidth $ww]
  set canvas_height [winfo height $w.canvas]
  global configure
# Expand the canvas up to $configure(CANVAS_MAX_HEIGHT) automatically but above that just
# keep it same size (or decrease if scroll area is decreasing)
  if { $canvas_height < $configure(CANVAS_MAX_HEIGHT)  } { 
    set canvas_height [min $configure(CANVAS_MAX_HEIGHT) $height] 
  } else {
    # If the canvas area becomes larger than the viewing area then
    # the window seems to "grow" at the rate of 2 pixels per call
    # to this procedure (observed with Tcl/Tk 8.3 on Mac and OSF1),
    # when $w.canvas is configured below.
    # The kludge is to knock off 2 pixels each time - PJX.
    set canvas_height [expr {[min $canvas_height $height] - 2}]
  }

  $w.canvas configure -width $width \
    -height $canvas_height \
    -scrollregion [list 0 0 $width $height]
}

#-------------------------------------------------------------------------------
proc  UnsetArrayExtras { arrayname } {
#-------------------------------------------------------------------------------
#d_sum Delete the 'extra' elements from a task window array
#d_desc The extra elements control the display of extending frames etc. \
in a task window. If a task window is deleted it is safer to delete \
these elements before possibly redrawing the task window again.
#d_arg arrayname Name of task window array

  upvar #0 $arrayname array

# just delete those bits of the array that are recreated when the window
# is drawn

  if { [array exists array] } {
    set delete_list [ concat [ array names array "WIDGET_*" ] \
                        [ array names array "LABEL_*" ] \
                        [ array names array "XF_*" ] \
                        [ array names array "HELP_*" ] \
                        [ array names array "FRAME_*" ] \
                        [ array names array "DEPVARS_*" ] \
                        [ array names array "N_DEPFRAMES_*" ] \
                        [ array names array "DEPFRAMES_*" ] \
                        [ array names array "CHILD_*" ] \
                        [ array names array "PARENT_*" ] \
                        [ array names array "VARS_*" ] ]
    foreach item $delete_list {
      unset array($item)
    }
  }
}

#--------------------------------------------------------------------
proc UnsetArrayTraces { arrayname } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array
#d_dum Unset any traces associated with the variables in the array
#d_desc The array has already been tied to an interface and \
is probably going to be tied to a new interface. \
Variables which have a trace on them are listed in TRACE_LIST. \
These traces must be deleted to avoid attempts to access widgets \
that no longer exist.
#d_arg arrayname The name of an array

  if { [ElementExists $arrayname TRACE_LIST] } {
    foreach element $array(TRACE_LIST) {
      set trace_list [trace vinfo array($element) ]
      foreach trace $trace_list {
        trace vdelete array($element) [lindex $trace 0] [lindex $trace 1 ]
      }
    }
    unset array(TRACE_LIST)
  }
}

#--------------------------------------------------------------------
proc run_update_script { arrayname } {
#--------------------------------------------------------------------
#d_sum After defining a new window tidy up the extending frames
#d_desc The array element UPDATE_SCRIPTS may contain the text for some \
commands that extending frames require to be run after the rest of the \
windows are defined.
#d_arg arrayname The data array for the window

  upvar #0 $arrayname array
  if { $array(UPDATE_SCRIPTS) != "" } {
#    puts "run_update_script UPDATE_SCRIPTS "
    append cmd  "$array(UPDATE_SCRIPTS)" "run_update_script $arrayname"
    set array(UPDATE_SCRIPTS) ""
    eval "$cmd"
  } else {
#    puts "run_update_script UPDATE_SCRIPTS empty"
  }
}
#-----------------------------------------------------------------------------
proc GetNewWindowName { root } {
#-----------------------------------------------------------------------------
#d_sum Return a unique name for an array root_$n 
#d_arg Root name for an array
  set continue 1; set n -1
  while { $continue } {
    incr n; set arrayname ""; append arrayname $root _ $n
    global $arrayname
    if { ![array exists $arrayname ]  && 
	![winfo exists .w_$arrayname] } {
      set continue 0
    }
  }
  return $arrayname
}

#d_index_title Help, Message Line and Wait Commands

#-------------------------------------------------------------------
proc SetProgramHelpFile { program_name } {
#-------------------------------------------------------------------
#d_sum Set the name of the help file for the current window
#d_ref CCP4I programmers/SetProgramHelpFile.html See CCP4i Programmers Documentation
#d_desc  The file name set using this procedure is used for all subsequent \
'help' commands in the CreateLine procedure.  If a task interface requires \
access to more than one help file then this procedure can be called multiple \
times to derefine the default help file.
#d_arg program_name Usually just the name of a ccp4 program which will be \
assumed to have a help file in $CCP4/html.  If this is not the case then \
the full path name of the help file should be given.

  if {[file exists $program_name]} {
    set help_file $program_name
  } elseif {[file exists [SearchPath HELP programs $program_name.html ]]} {
    set help_file [SearchPath HELP programs $program_name.html ]
  } else {
    set help_file [FileJoin  [GetEnvPath CCP4] html $program_name.html ]
  }
#  puts "help_file $help_file"
  SetSystemVar frame_program_help $help_file

}

#---------------------------------------------------------------------
proc KeywordHelp { help_file { help_target {} } } {
#---------------------------------------------------------------------
#d_sum Open a web browser to display a help document.
#d_arg help_file Name of html file to display
#d_arg help_target Optional target within help file
  global system
  if { $system(EXFRAME_EDIT_OPEN) != "" } { return }
  if { $help_target != "" } {
    open_url $help_file -target $help_target
  } else {
    open_url $help_file
  }
}

#-------------------------------------------------------------------------
proc SetMessage { arrayname w m } {
#-------------------------------------------------------------------------
#d_sum Bind cursor entering a widget to display help textline
#d_desc This is a generic interface to setting the inline help display.
#d_arg arrayname Name of task interface array
#d_arg w The id of a widget within the task window
#d_arg m The text message to be displayed
    bind $w <Any-Enter> "ShowHelp \"$arrayname\" $w \"$m\""
    bind $w <Any-Leave> "CancelHelp \"$arrayname\" $w"
}

#-------------------------------------------------------------------------
proc ShowHelp { arrayname w m } {
#-------------------------------------------------------------------------
#d_sum Show inline help text message
#d_desc Help messages are displayed in the message line in each CCP4i \
window. Depending on the configuration the help message will also be \
displayed as "bubble help", with the text appearing next to the \
appropriate widget after a short time delay.
#d_arg arrayname Name of task interface array
#d_arg w The id of a widget within the task window
#d_arg m The text message to be displayed
    global configure

    # Call initialisor here so it's always available
    InitialiseBubbleHelp

    # Always display messageline help
    if { $arrayname != "" } { set_message $arrayname "$m" }

    # Also show bubblehelp if enabled
    if { $configure(ENABLE_BUBBLE_HELP) } {
	global bubblehelp_info
	set bubblehelp_info($w) "$m"
	bubblehelp_pending $w
    }
}

#-------------------------------------------------------------------------
proc CancelHelp { arrayname w } {
#-------------------------------------------------------------------------
#d_sum Cancel display of inline help text message
#d_desc This is the counterpart of the ShowHelp command, which displays \
the messages in the first place.
#d_arg arrayname Name of task interface array
#d_arg w The id of a widget within the task window
    global configure

    # Always cancel messageline help
    if { $arrayname != "" } { set_message $arrayname " " }

    # Also cancel bubblehelp message if enabled
    if { $configure(ENABLE_BUBBLE_HELP) } {
	global bubblehelp_info
	bubblehelp_cancel
    }
}

#-------------------------------------------------------------------------
proc InitialiseBubbleHelp { } {
#-------------------------------------------------------------------------
#d_sum Initialise bubble help functionality
#d_desc Call this to set up the toplevel widget for bubble help.
#d_desc The toplevel widget is created and then hidden - when required \
it is filled with the appropriate text and placed in the correct position \
before being remapped to the screen.
    if { ![winfo exists .bubblehelp] } {
	global configure
	toplevel .bubblehelp \
		-borderwidth 1 \
		-background black
	label .bubblehelp.info \
		-background $configure(COLOUR_BACKGROUND)
	pack .bubblehelp.info -side left -fill y
	wm overrideredirect .bubblehelp 1
	wm withdraw .bubblehelp
    }
    return
}

#-------------------------------------------------------------------------
proc bubblehelp_pending { w } {
#-------------------------------------------------------------------------
#d_sum Initiate display of help text via bubble help
#d_desc This command is triggered when the cursor moves over the widget. \
After a delay the help message is displayed (unless cancelled e.g. by the \
cursor leaving the widget). 
#d_arg w The id of a widget within the task window
    global bubblehelp_info
    bubblehelp_cancel
    set bubblehelp_info(pending) [after 1500 [list bubblehelp_show $w]]
}

#-------------------------------------------------------------------------
proc bubblehelp_show { w } {
#-------------------------------------------------------------------------
#d_sum Display help text in a help bubble.
#d_desc Called from bubblehelp_pending after a suitable delay
#d_arg w The id of a widget within the task window
    global bubblehelp_info
    # Maximum line length for bubble help text
    set linelen 30
    if { [winfo exists $w] } {
	set help_info $bubblehelp_info($w)
        set msg ""
	set start 0
        set index 0
	set first 1
	if { [set len [string length $help_info]] <= $linelen } {
	    # Message is already shorter than the maximum length
	    set msg $help_info
	} else {
	    # Chop up the message
	    while { $len > $index } {
		# Index = the position of the end of the line
		set index [expr $start + $linelen]
		if { $index >= $len } {
		    # The remainder of the message fits into the line
		    set chunk [string range $help_info $start end]
		    set index $len
		} else {
		    # Go back to the start of the nearest word
		    set index0 [string wordstart $help_info $index]
		    if { $index0 == $start } {
			# This takes us back to the previous position
			# Go forwards instead
			set index0 [string wordend $help_info $index]
			# Check for close bracket - this is ignored by wordend
			if { [string index $help_info [incr index0]] == ")" } {
			    incr index0
			}
		    } else {
			# Check for close bracket - this is ignored by wordstart
			if { [string index $help_info $index0] == ")" } {
			    # This is really the end of a word
			    incr index0
			} else {
			    # It really is the start of a word
			    incr index0 -1
			    # Check for open bracket - also ignored by wordstart
			    if { [string index $help_info $index0] == "(" } {
				incr index0 -1
			    }
			}
		    }
		    set index $index0
		    set chunk [string range $help_info $start $index]
		}
		# Clean the line and append
		set chunk [string trim $chunk]
		if { $first } {
		    append msg $chunk
		    set first 0
		} else {
		    append msg "\n" $chunk
		}
		# Step on one for the next cycle
		set start [expr $index + 1]
	    }
	}
	# Display the message
	.bubblehelp.info configure -text $msg
	set x [expr {[winfo rootx $w] + 10}]
	set y [expr {[winfo rooty $w] + [winfo height $w]}]
	wm geometry .bubblehelp +$x+$y
	wm deiconify .bubblehelp
	raise .bubblehelp
	# Make sure that the bubble help dissappears if the
	# widget it's associated with is destroyed
	bind $w <Destroy> "bubblehelp_cancel"
    }
    unset bubblehelp_info(pending)
}

#-------------------------------------------------------------------------
proc bubblehelp_cancel { } {
#-------------------------------------------------------------------------
#d_sum Cancel display of help text via bubble help
#d_desc This command is triggered when the cursor moves out of a widget.
    global bubblehelp_info
    if { [info exists bubblehelp_info(pending)] } {
	after cancel $bubblehelp_info(pending)
	unset bubblehelp_info(pending)
    }
    wm withdraw .bubblehelp
}

#-------------------------------------------------------------------------
proc set_message { arrayname m args } {
#-------------------------------------------------------------------------
#d_sum Display the given text in the message line
#d_arg arrayname Name of task interface array
#d_arg m The text message to be displayed
#d_opt0 -block
#d_opt1 Block any subsequent attempt to set the message until the \
-unblock option is used
#d_opt0 -unblock
#d_opt1 Unset any block on updating the message line
  upvar #0 $arrayname array
  if { [lsearch $args "-block"] >= 0 } {
    set array(MESSAGEBLOCK) 1
    set array(MESSAGEVAR) "$m"
  } elseif { [lsearch $args "-unblock"] >= 0 } {
    set array(MESSAGEBLOCK) 0
  } elseif { ![ElementExists $arrayname MESSAGEBLOCK] } {
    set array(MESSAGEBLOCK) 0
    set array(MESSAGEVAR) "$m"
  } elseif { !$array(MESSAGEBLOCK) } {
    set array(MESSAGEVAR) "$m"
  }
}

#-------------------------------------------------------------------
proc PleaseWait  { { message {} } } {
#-------------------------------------------------------------------
#d_sum Display a 'Please wait' message
#d_ref CCP4I programmers/PleaseWait.html See CCP4I Programmers Documentation
  global configure
  if { $message == "" } {
    if { [winfo exists .please_wait ] } { destroy .please_wait }
    TkBusy . 1
  } else {
    TkBusy .
    if { ![winfo exists .please_wait ] } {
      toplevel .please_wait
      wm title .please_wait "CCP4I Please wait "
      wm minsize .please_wait 40 0
      label .please_wait.l -text "Please wait .. $message" \
        -background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR)
      pack .please_wait.l
    } else {
      .please_wait.l configure -text $message
    }
  }
  update idletasks
}

#----------------------------------------------------------------------
proc TkBusy' {w  d} {
#----------------------------------------------------------------------
#d_sum Iteratively set the cursor for all child windows to a watch/arrow
#d_desc This function should not be used directly - use TkBusy
#d_arg w The id for a window
#d_arg d If false (0) set cursor to watch, if true (1) then reset cursor to arrow

   global TkBusyStore

   if {$d} {
      if { [$w cget -cursor] != "" && [info exists TkBusyStore($w)]} {
        $w config -cursor $TkBusyStore($w)
      }
   } else {
      if { [$w cget -cursor] != "" && [$w cget -cursor] != "watch" } {
        set TkBusyStore($w) [$w cget -cursor]
        $w config -cursor watch
      }
   }
   foreach i [winfo children $w] {TkBusy' $i $d}
}

#----------------------------------------------------------------------
proc TkBusy {w {d 0}} {
#----------------------------------------------------------------------
#d_sum Set the cursor style for a window and all of it's children
#d_desc A watch cursor is used to indicate that the process is busy.
#d_arg w The id for a window
#d_arg d Optional, default 0. If false (0) set cursor to watch, if true (1) then reset cursor to arrow

   TkBusy' $w $d
   if {$d} {
      global TkBusyStore
      if { [info exists TkBusyStore] } { unset TkBusyStore }
   }
   update idletasks
}

#d_index_title File Selection Widgets

#---------------------------------------------------------------------------
proc CreateInputFileLine { linein message label
                        filein filein_dir args } {
#---------------------------------------------------------------------------
#d_sum Draw a line to select an input file
#d_ref  CCP4I programmers/CreateInputFileLine.html See the CCP4i Programmers Documentation
  upvar $linein line
  global configure

  set arrayname [ GetSystemVar frame_array ]
  upvar #0 $arrayname array
  set index [GetSystemVar current_index_counter]
  set help_pointer files
  set notoblig ""
  if { [lsearch -regexp  $args notob ] >= 0 } { set notoblig -notoblig }

  set file [Indxv $filein $index]
  set file_dir [Indxv $filein_dir $index]
  set ext [GetTypeInfo $arrayname $file "ext"]
  if { $array($file_dir) == "" } { 
    if { [GetCurrentProject] != "" } {
      set array($file_dir) [GetCurrentProject]
    } else {
      set array($file_dir) [GetSystemVar PATHNAME_LABEL]
    }
  }
  set parent [ GetSystemVar frame_parent ]
  set input_format [GetTypeInfo $arrayname $file format ]

  set array(PREVIOUS_$file_dir) $array($file_dir)

# NB use unindexed variable name - CreateLine will add the index

  CreateLine line 		\
    label $label                \
    message "Look in a project directory (as set up in Directories&ProjectDir)" \
    widget $filein_dir            \
       -command "update_default_dir read $arrayname $file_dir $file" \
    message $message 		\
    widget $filein	\
    message "Open a file browser" \
    button "Browse" \
    message "Display the contents of the selected file" \
    button "View"

  $line.b4 configure -font $configure(FONT_SMALL)
  $line.b5 configure -font $configure(FONT_SMALL)

  pack forget $line.b5; pack forget $line.b4; pack forget $line.e3
  pack $line.b5 $line.b4 -side right
  pack $line.e3 -expand yes -fill x -side left

# check the current initial file name and then set up binding to check
# the input file

  set file_status [CheckFileInput $arrayname $file read $file_dir $notoblig]

  bind $line.e3  <FocusOut>  \
     [list CheckFileInput $arrayname $file read $file_dir $notoblig]
  bind $line.e3  <Return> \
     [list CheckFileInput $arrayname $file read $file_dir -title "$label" $notoblig]
  bind $line.e3  <ButtonRelease-2> \
     [list CheckFileInput $arrayname $file read $file_dir -title "$label" $notoblig]
  bind $line.e3  <Tab> \
     [list CheckFileInput $arrayname $file read $file_dir -title "$label" $notoblig]

  bindtags $line.e3 [list Entry $line.e3 . all]

# Invoke the file browser

  $line.b4 configure  -command  "FileDialog open $arrayname $file $file_dir"
  $line.b5 configure -command  "CheckFileInput $arrayname $file read $file_dir
		FileViewer0 $arrayname $file"

  bind $line.b4 <Return> "FileDialog open $arrayname $file $file_dir"
  bind $line.b5 <Return> "CheckFileInput $arrayname $file read $file_dir $notoblig
                FileViewer0 $arrayname $file"

#
# Set bindings to update labels etc when user inputs file name
#
  set n_args [expr {[llength $args ] -1} ]
  set n 0

  while { $n < $n_args }  {
    set argument [lindex $args $n ]

    if { $argument == "-help" } {

        incr n; set  help_pointer [lindex $args $n ]

    } elseif { $argument == "-toggle_display" } {

       incr n; set toggle_var [lindex $args $n ]
       incr n; set toggle_state [lindex $args $n ]
       incr n; set toggle_hitlist [lindex $args $n ]
       toggle_frame_display $line $toggle_var $toggle_state $toggle_hitlist

    } elseif { $argument == "-fileout" || $argument == "-filein"  } {

      incr n; set fileout [lindex $args $n ]
      incr n; set fileout_dir [lindex $args $n ]
      incr n; set fileout_ext [lindex $args $n ]
      set cmd "UpdateOutputFilename $arrayname $file \
                        $fileout_dir  $fileout $fileout_ext"
      if { $argument == "-filein"  } { append cmd " -in" }
      add_file_command $line "$cmd"

    } elseif { $argument == "-setlabin" } {

      incr n; set label [lindex $args $n ]
      incr n; set priority_name_list [lindex $args $n ]

      add_file_command $line "SetLabin $arrayname $file \
                $label { $priority_name_list }"

#      if { $file_status } {
#        SetLabin $arrayname $file $label { $priority_name_list }
#      }
    } elseif { $argument == "-setalllabin" } {

      incr n; set label [lindex $args $n ]
      incr n; set type [lindex $args $n ]

       add_file_command $line "SetLabin $arrayname $file \
		$label {} -setallelements"


    } elseif { $argument == "-setlabinunassigned" } {

      incr n; set label [lindex $args $n ]
      add_file_command $line "SetLabinUnassigned $arrayname $label "

    } elseif { $argument == "-command" } {

       incr n; set cmd [lindex $args $n ]
       add_file_command $line "$cmd"

    } elseif { $argument == "-setfileparam" } {

       incr n; set paramtype [string toupper [lindex $args $n ]]
       incr n; set label [lindex $args $n ]

       add_file_command $line \
          "SetParamFromFile $paramtype $arrayname $input_format $file $label"

# When setting interface from saved def file we probably want to keep parameters
# in the def file rather than reset them from the MTZ file so leave this
# commented out

#       if { $file_status && $array($label) == "" } {
#         SetParamFromFile $paramtype $arrayname $input_format $file $label
#       }
    }
    incr n
  }

# Add the help binding

  set program_help [GetSystemVar frame_program_help]
  bind $line.e3 <Button-3> \
  "KeywordHelp $program_help $help_pointer"
  bind $line.b5 <Button-3> \
  "KeywordHelp [SearchPath HELP general fileselect.html ] file_icon"

}

#------------------------------------------------------------------------------
proc CreateOutputFileLine  { linein message label fileout fileout_dir args } {
#------------------------------------------------------------------------------
#d_sum Draw a line to select an output file
#d_ref  CCP4I programmers/CreateOutputFileLine.html See the CCP4i Programmers Documentation

  upvar $linein line
  global configure

# Get the details of the current open frame

  set help_pointer files
  set arrayname [ GetSystemVar frame_array ]
  upvar #0 $arrayname array

  set index [GetSystemVar current_index_counter]
  set file [Indxv $fileout $index]
  set file_dir [Indxv $fileout_dir $index]
#  puts "file_dir $file_dir value *$array($file_dir)*"
  if { $array($file_dir) == "" } {
   if { [GetCurrentProject] != "" } {
     set array($file_dir) [GetCurrentProject]
   } else {
     set array($file_dir) [GetSystemVar PATHNAME_LABEL]
   }
  }  elseif { $array($file_dir) == "MAP_DEFAULT" } {
     if {[regexp TEMPORARY [GetValue preferences MAP_OUTPUT_DEFDIR] ]} {
       set array($file_dir) TEMPORARY
     } else {
       set array($file_dir) [GetCurrentProject]
     }
  }


  set array(PREVIOUS_$file_dir) $array($file_dir)

# NB use unindexed variable name - CreateLine will add the index

  CreateLine line \
    label $label \
    message "Move to a project directory (as set up in Directories&ProjectDir)" \
    widget $fileout_dir \
      -command "update_default_dir save $arrayname $file_dir $file" \
    message $message \
    widget $fileout \
    message "Open a file browser" \
    button "Browse" \
    message "Display the contents of the selected file" \
    button "View"

  $line.b4 configure -font $configure(FONT_SMALL)
  $line.b5 configure -font $configure(FONT_SMALL)

  pack forget $line.b4; pack forget $line.e3 ; pack forget $line.b5
#  if { [lsearch $args "-info" ] >= 0 } { pack $line.b5 -side right }
  pack $line.b5 -side right
  pack $line.b4 -side right
  pack $line.e3 -expand yes -fill x -side left

  $line.b5 configure -command  "CheckFileInput $arrayname $file save $file_dir
		FileViewer0 $arrayname $file"

  $line.b4 configure   \
        -command "FileDialog save $arrayname $file $file_dir
	CheckFileInput $arrayname $file save $file_dir"

  bind $line.b4 <Return> "FileDialog save $arrayname $file $file_dir
       CheckFileInput $arrayname $file save $file_dir"
  bind $line.b5 <Return> "CheckFileInput $arrayname $file save $file_dir
                 FileViewer0 $arrayname $file"

  CheckFileInput $arrayname $file save $file_dir 

  bind $line.e3  <FocusOut>                                                 \
        " CheckFileInput $arrayname $file save $file_dir "
  bind $line.e3  <Return>                                                 \
        " CheckFileInput $arrayname $file save $file_dir "
  bind $line.e3  <ButtonRelease-2> \
        " CheckFileInput $arrayname $file save $file_dir "

  bindtags  $line.e3 [list Entry $line.e3 . all]

   set n 0; set nargs -1; if { [info exists args] } { set nargs [expr {[llength $args] - 1} ] }
   while { $n < $nargs } {
     set argument [lindex $args $n ]
     if { $argument == "-help" } {
       incr n; set  help_pointer [lindex $args $n ]

     } elseif { $argument == "-toggle_display" } {
       incr n; set toggle_var [lindex $args $n ]
       incr n; set toggle_state [lindex $args $n ]
       incr n; set toggle_hitlist [lindex $args $n ]
       toggle_frame_display $line $toggle_var  $toggle_state $toggle_hitlist
     }
     incr n
   }

   set program_help [GetSystemVar frame_program_help]
   bind $line.e3 <Button-3> \
   "KeywordHelp $program_help $help_pointer"
  bind $line.b5 <Button-3> \
  "KeywordHelp [SearchPath HELP general fileselect.html ] file_icon"
}

#------------------------------------------------------------------------
proc FileViewer0 { arrayname fileVar } {
#------------------------------------------------------------------------
#d_sum Extracts file name from a data array and passes to FileViewer
#d_desc When the file viewer functionality is part of a callback, attached \
to a button (eg the 'Browse' button), then it is necessary to extract the \
name of the file from data array at the time the command is issued.
#d_arg arrayname The data array for the window
#d_arg fileVar The element of the array containing the file name
  upvar #0 $arrayname array

  set file [GetFullFileName0 $arrayname $fileVar]

  if { [file isfile $file] && [file exists $file] } {
    set format [GetTypeInfo $arrayname $fileVar format]
    FileViewer $file -format $format
  } else {
    WarningMessage "File $file does not exist. \nCannot display this file."
    return
  }
}

#-------------------------------------------------------------------------
proc FileDialog {openmode arrayname fileVar dirVar } {
#-------------------------------------------------------------------------
#d_sum Open a file selection dialog box associated with one file input line
#d_desc This uses the SelectFile procedure to provide the file selection \
dialog but also ensure that any selection on the file input line is passed \
to SelectFile and that the returned selection is put into the correct \
variable
#d_arg openmode Should be 'open' for an input file or 'save' for an output file.#d_arg arrayname Name of task interface array
#d_arg fileVar The name of the element in the array containing the file name
#d_arg dirVar The name of the element in the array containing the directory alias

  upvar #0 $arrayname array

  if { $array($fileVar) != {} &&
      [file isdirectory $array($fileVar)]  } {
    set directory $array($fileVar)
    set array($dirVar) [GetSystemVar PATHNAME_LABEL]
  } else {
    set directory [GetDefaultDirPath $array($dirVar)]
  }

  set ext_list [split [GetTypeInfo $arrayname $fileVar "ext"] ,]
  foreach extension $ext_list {
     lappend ext "*$extension"
  }
  set format [GetTypeInfo $arrayname $fileVar "format"]
  set field_list [GetWidget $arrayname $fileVar]
  set field_class [winfo class [lindex $field_list 0 ] ]
  set default [subst $directory]
  set file ""

  switch $openmode \
  "open" {
    set title "$array(TASK_TITLE): Select Input $format File"
    set exist ""
  } "default" {
    set title "$array(TASK_TITLE): Select Ouput $format File"
    set exist "-unknown"
  }

  if { [set status [SelectFile return_file \
	-title $title -default $default -defdir "$array($dirVar)" \
       $exist  -format $format -filter $ext -parent $arrayname \
	-return [list dir filename defdir] ] ] } {

    set array($dirVar) [lindex $return_file 2]
    if { [StringSame "$array($dirVar)" "[GetSystemVar PATHNAME_LABEL]" ] } {
      set array($fileVar) [FileJoin [lindex $return_file 0] [lindex $return_file 1]]
    } else {
      set array($fileVar) [lindex $return_file 1]
    }
    set_field_colour $arrayname $fileVar $status
  } 
  return $status

}

#-------------------------------------------------------------------
proc DirBrowser { arrayname arrayindex } {
#-------------------------------------------------------------------
#d_sum Present a 'file' browser for user to select a directory
#d_desc This assumes that there is a text input widget for the directory \
path in a task interface and this procedure is called if the user clicks a \
'Browse' button.
#d_arg arrayname Name of task interface array
#d_arg arrayindex Name of an element in the array which contains the directory name

  upvar #0 $arrayname array

  set field [GetWidget $arrayname $arrayindex]
  set field_class [winfo class $field]
  set status [SelectFile dir -title "Select directory" -directory -parent $arrayname ]

  # status = 0 implies failure
  if { $status == 0 } return

  # It is possible that the user has closed the parent 
  if {![winfo exists $field]} return

  if { $field_class == "Entry" } {
    if { $dir != ""  } {
        $field delete 0 end
        $field insert 0 [lindex $dir 0]
        $field xview end
    }
    CheckDirInput $arrayname $arrayindex
#    set_field_colour $arrayname $arrayindex $status
  } else {
    set array($arrayindex) [lindex $dir 0]
  }
  return $status
}
#----------------------------------------------------------------------------
proc CheckFileInput { arrayname fileVar mode { dirVar {} } args } {
#----------------------------------------------------------------------------
#d_sum Check user input to file selection  and return 1 if OK, 0 otherwise
#d_desc The user input of a file name is OK if an input file exists or \
an output file does not exist.  For input files the procedure will attempt \
file name completion- e.g. adding an extension to a file name.
#d_arg arrayname Name of task interface array
#d_arg fileVar Name of an element in the array containing the file name
#d_arg mode  Should be 'open' for an input file or 'save' for an output file
#d_arg dirVar Name of an element in the array containing the directory alias
#d_opt0 -notoblig
#d_opt1 Entering a file name is not obligatory so field will not have a \
contrast colour if it is left blank
#d_opt0 -ext ext
#d_opt1 Enter a file extension to use in file name completion
#d_opt0 -title title
#d_opt1 If attempted file name completion finds several files which are \
consistent with input then present user with list to select correct file. \
The title is used as a title for the selection dialog box.
  upvar #0 $arrayname array
  global system
  global chain

  set oblig 1
  set n 0; set nargs [llength $args]
  while  { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    notob { set oblig 0
    } ext { incr n; set ext [lindex $args $n]
    } title { incr n; set title [lindex $args $n] }
    incr n
  }

  if { $dirVar == {} } { set dirVar DIR_$fileVar }
#  puts "CheckFileInput file $array($fileVar) dir $array($dirVar)"

# For user input filename $array($fileVar) try to construct 
# probable file name using the default directory and file extension
# appropriate to the type of the file

# mode = "read" or "save"

  set status 0

# Set default values for procedure arguments - beware the args input
# is only parsed when it is necessary
  set title ""
  set ext ""

# nothing input?
  if { [ElementExists $arrayname $fileVar] && $array($fileVar) == "" } {
    set status [expr {1 - $oblig}]
    set_field_colour $arrayname $fileVar $status
    return $status
  }


# Unix specific 
# Handle user input of ~ or an environment variable or ./ or ../
  switch -regexp $system(OPSYS) \
  UNIX {
    if { [ResolveUnixFileSymbols $array($fileVar) path] } { 
      set array($fileVar) $path }
  } WINDOWS {
    regsub -all {\\} $array($fileVar) \/ path 
    set  array($fileVar) $path
  }

# Set up the full path name - if it is still a relative path then assume 
# it is relative to the current aliased directory

  if { [regexp "absolute|volumerelative" [file pathtype $path] ] } {
    # An absolute path (for these purposes)
    set array($dirVar) [GetSystemVar PATHNAME_LABEL]
  } else {
    # A relative path
    set path [FileJoin [GetDefaultDirPath $array($dirVar)] $path]
  }

#  puts "mode $mode full path $path"

# Is a directory - check if it corresponds to a defined directory
  if {  [file exists $path] && [file isdirectory $path ] } {
#    puts "isdirectory"
    if { [IsPathADefaultDir $path alias ] } {
      set array($fileVar) ""
    } else {
      set array($fileVar) $path
    }
    set array($dirVar) $alias
    set_field_colour $arrayname $fileVar 0
    return 0
  }

# Is it a file 
  if { [file exists $path ] && [file isfile $path ] } {
#    puts "isfile"
    if {$mode == "save" } { set status 0 } else { set status 1 }
    set_field_colour $arrayname $fileVar $status
    return $status
  }

# Parse the procedure arguments - we need ot know extension and whether to
# do globing
  set n 0; set nargs [llength $args]
  while  { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    ext { incr n; set ext [lindex $args $n]
    } title { incr n; set title [lindex $args $n] }
    incr n
  }

  if { $ext == "" } { set ext [GetTypeInfo $arrayname $fileVar ext ] }

# Is it a file name with the extension missing?
  if { [file extension $path] == "" } {
    foreach ex $ext {
      set path_ext ""
      append path_ext $path $ex
      if { [file isfile $path_ext ] } {
        if {$mode == "save" } { set status 0 } else { set status 1 }
        set_field_colour $arrayname $fileVar $status
        append array($fileVar) $ex
        return $status
      }
    }
  }

# Saving a file - just assume this is the name that they mean
  if { $mode == "save" } {
# For output file just make sure that its dirctory exists
    set dir [eval file join [lreplace [file split $path ] end end ] ]
    if { ![file exists $dir] || ![file isdirectory $dir] } {
      set_field_colour $arrayname $fileVar 0
      return -1
    }
    if { [file extension $path] == "" } { 
               append array($fileVar) [lindex $ext 0]}
    set_field_colour $arrayname $fileVar 1
    return 1
  }

# Try globing for file
  if  { $title != "" } {
   set globlist {}
   foreach ex $ext {
     foreach gb [glob -nocomplain [file rootname $path]*$ex] {
       lappend globlist $gb
     }
   }
   set sortedlist [sort_files name $globlist]

    if { [llength $sortedlist] == 1 } {
      set chosen_glob_file [lindex $sortedlist 0]
      set status 1
    } elseif { [llength $sortedlist] > 0 && [llength $sortedlist] < 50  &&
        [set chosen_glob_file [ChooseOptionDialog "$title" "Choose" "Choose input file" \
	    $sortedlist -mode list -height 5 -width 40]] != "" } {
      set status 1
    }
    if { $status } {
      if { $array($dirVar) == [GetSystemVar PATHNAME_LABEL] } {
        set array($fileVar) [file join [file dirname $path] $chosen_glob_file]
      } else {
        set array($fileVar) [file tail $chosen_glob_file]
      } 
    }
  }
  set_field_colour $arrayname $fileVar $status
  MoveFileNameLeft $arrayname $fileVar
  return $status
}

#----------------------------------------------------------------
proc IsPathADefaultDir { path aliasVar } {
#----------------------------------------------------------------
#d_sum Check if explicitly entered path corresponds to a project or aliased directory.
#d_desc The user might type in a full path name rather than use the project or aliases.  It is easier for ccp4i to keep track of files if the project or alias \is used so test any input full path and convert to a project/alias if possible.
#d_arg path Full path name for file
#d_arg aliasVar Returned project/alias.
  upvar $aliasVar alias

# Does the input path name correspond to the name of any project directory
# or defined directory - return the alias for the directory or the default
# 'Full path ..'  label

  set file ""
  set splitf [file split $path]
  if { [llength $splitf] > 1 } {
    set path0 [file join [lreplace $splitf end end] ]
  } else {
    set path0 $path
  }

  foreach project [ListProjects] {
    set project_path [GetProjectPath $project]
    if { [StringSame $project_path $path] } {
      set alias $project
      return 1
    } elseif { [StringSame $project_path $path0] } {
      set alias $project
      set file [file tail $path]
      return 1
    }
  }

  foreach defdir [ListDefdirs] {
    set defdef_path [GetDefdirPath $defdir]
    if { [StringSame $defdef_path $path] } {
      set alias $defdir
      return 1
    } elseif { [StringSame $defdef_path $path0] } {
      set alias $defdir
      set file [file tail $path]
      return 1
    }
  }

  set alias [GetSystemVar PATHNAME_LABEL]
  return 0
}

#-----------------------------------------------------------------
proc ResolveDirInput { dirin } {
#-----------------------------------------------------------------
#d_sum Expand user input directory path
#d_desc Resolve ~ or environment variable specifications and \
return a full path.
#d_arg dirin The input directory path to be expanded.
    global system

    # Sort out Windows specific double separators
    set dirout {}
    if { [regexp WINDOWS $system(OPSYS) ] } {
	regsub -all {\\} $dirin \/ dir1
    } else {
	set dir1 $dirin
    }

    # Handle user input of ~ or an environment variable
    set path [file split [string trim $dir1] ]
    if {[llength $path] > 1} {
	set p1 [eval [concat file join [lrange $path 1 end ]]] 
    } else {
	set p1 ""
    }
    if {[regexp ^~ [lindex $path 0 ]]} {
	set dirout [FileJoin [glob [lindex $path 0]] $p1]
    } elseif {[regexp {^\$} [lindex $path 0]]} {
	set path1 [GetEnvPath [lindex $path 0] ]
	set dirout [FileJoin $path1 $p1 ]
    } else {
	set dirout $dirin
    }

    # Return resolved path
    return $dirout
}

#-----------------------------------------------------------------
proc CheckDirInput { arrayname dir } {
#-----------------------------------------------------------------
#d_sum Validate user input of directory path
#d_desc The procedure will handle input of ~ or environment variable
#d_desc The widget for the directory input is updated with status \
colour depending on the validity of the user input.
#d_arg arrayname Name of data array
#d_arg dir Array element containing directory path

  global system
  upvar #0 $arrayname array

  # Expand any symbols in the path
  set array($dir) [ResolveDirInput $array($dir)]

  # Check the status of the file and set the widget background
  # appropriately
  if { [file exists $array($dir)] &&
       [file isdirectory $array($dir)] } {
    set status 1
  } else {
    set status 0
  }
  set_field_colour $arrayname $dir $status
  return $status
}

#--------------------------------------------------------------------
proc update_default_dir { mode arrayname dir file } {
#--------------------------------------------------------------------
#d_sum Update the path to file name in file selection line when user \
changes default directory
#d_arg mode REDUNDANT
#d_arg arrayname Name of data array
#d_arg dir Array element containing directory alias
#d_arg file Array element containing file name
  upvar #0 $arrayname array

# User has changed the default dir so update path to any existing 
# specified file

  if { $array($dir) == $array(PREVIOUS_$dir) } { return }
  if { $array($file) == {} } { 
    set array(PREVIOUS_$dir) $array($dir) 
    return
  }

  if { [StringSame "$array($dir)" "[GetSystemVar PATHNAME_LABEL]" ] } {
    set array($file) [FileJoin [GetCurrentDir] $array($file)]
  } elseif { [StringSame "$array(PREVIOUS_$dir)" "[GetSystemVar PATHNAME_LABEL]" ] } {
    set array($file) [file tail $array($file)]
  }
#  puts "update_default_dir file $array($file)"
  set array(PREVIOUS_$dir) $array($dir) 

  if { ![catch {set com [bind [GetWidget $arrayname $file] <Return> ]}] } {
    eval $com }
}

#-------------------------------------------------------------------
proc MoveFileNameLeft { arrayname file } {
#-------------------------------------------------------------------
#d_sum For long file name move position of file name in widget
#d_arg arrayname Name of data array
#d_arg file Array element containing file name
  upvar #0 $arrayname array
  if { [ElementExists $arrayname WIDGET_$file] } {
    foreach w $array(WIDGET_$file) {
      if { [winfo exists $w] }  { 
        set view [$w xview]
        if { [lindex $view 1 ] < 1.0 } {
          $w xview moveto \
            [expr {[lindex $view 0] + ( 1.04 - [lindex $view 1 ] )} ]
        }
      }
    }
  }
}

#----------------------------------------------------------------------------
proc UpdateOutputFilename { arrayname input_fileVar output_dir 
                    output_file output_ext args } {
#----------------------------------------------------------------------------
#d_sum Derive an output file name from an input file name
#d_arg arrayname Name of data array
#d_arg input_fileVar Name of array element containing the input file name
#d_arg output_dir Name of array element containing output directory alias
#d_arg output_file Name of array element containing output filename
#d_arg output_ext An extension to the filename root (usually _taskname) \
note this is not the usually meaning of file extension
#d_opt0 -in
#d_opt1 The 'output' file is actually an input file - do file validation \
as for an input file.
  upvar #0 $arrayname array
  global typedef

  set ext [GetTypeInfo $arrayname $output_file ext]
  if { $ext  == "" } return

# Also no go if input file does not exist
  set input_file [GetFullFileName0 $arrayname $input_fileVar]
  
  if { ![file isfile $input_file ] } {return}

# build output file name from the output_dir, the input file name and 
# the output_ext (ie extension)

  set dir [GetDefaultDirPath $array($output_dir)]
  set filtmp [file rootname [file tail $input_file] ]
# Add an extension to the filename root which will usually be derived
# from the name of the task
  if { $output_ext != "--" } { 
# remove any existing task name from the file name
    if {[regexp $output_ext $filtmp]} {
      set filtmp [string range $filtmp 0 [ expr {[string last $output_ext $filtmp] -1}] ]

    } else {
      foreach oext $typedef(_mtz_ext) {
        if {[regexp $oext $filtmp]} {
          set filtmp [string range $filtmp 0 \
		[ expr {[string last $oext $filtmp] -1}] ]
        }
      }
    }
    set file [FileJoin $dir [append filtmp $output_ext]]
    set n 0 ; set continue 1
    while { $continue  } { incr n
      set fileout $file
      append fileout $n $ext
      if { ![file exists $fileout] }  { set continue 0 }
    }
  } else {
    set fileout [FileJoin $dir [append filtmp $ext] ]
  }

# Set status dependent on whether it should be output (default) 
# or input file ( denoted by procedure arg -in)
  set status [file exists $fileout]
  if { [lsearch $args "-in"] < 0 } { set status [expr {1 - $status}] }
  set array($output_file) [file tail $fileout]
  if { [string equal $array($output_dir) "Full path.."] } { set array($output_file) $fileout }
  set_field_colour $arrayname $output_file $status
}

#--------------------------------------------------------------------------
proc add_file_command { linelist  cmd } {
#--------------------------------------------------------------------------
#d_sum Bind a command to be issued after user has selected a file
#d_desc It's tricky to know when the user has finished entering a file \
name and we don't want to bind commands (which may be slow) to events such \
as one keyboard stroke cos liable to be slow.  Compromise is to bind \
commands to user hitting Return or Tab or releasing middle mouse (ie. pasting).
#d_arg linelist A Tcl list of Create*putLine lines to have bound command
#d_arg cmd Text script of command to be bound
# Warning binding to FocusOut leads to problems - eg focus hopping between
# the file input line and a pop-up menu
#  bind $line.e1 <FocusOut>  +$cmd

  foreach line $linelist {
    bind $line.e3 <Return>  +$cmd
    bind $line.e3 <ButtonRelease-2>  +$cmd
    bind $line.e3 <Tab>  +$cmd

    set comline [ $line.b4 cget -command ]
    if { $comline != "" } {append comline " ; " }
    $line.b4 configure -command " $comline  $cmd "
  }

}

#--------------------------------------------------------------------
proc SetParamFromFile { paramtype arrayname format filename element } {
#--------------------------------------------------------------------
#d_sum Handler for the -setfileparam argument to CreateInputLine
#d_desc This is called after user has selected an input file. The file \
can be MTZ, map or pdb format. The GetParamFromFile procedure is called \
to get the data from the file and this procedure puts the data into \
the array element and updates the validity status for the element.
#d_arg paramtype The name of the type of data - corresponding to element in *_file_data array
#d_arg arrayname Name of the task array
#d_arg format The file format (MTZ/PDB/MAP)
#d_arg filename The array element containing the input file name
#d_arg element The name of the element to be assigned a value
  upvar #0 $arrayname array
  set varlist [list  CELL GRID XYZLIM]
  set lengthlist [list 6 3 6]

  set file [GetFullFileName0 $arrayname $filename]
  if { ![file isfile $file] || ![file exists $file]} { return }

  if {[GetParamFromFile  $format $file  $paramtype  data]} {
    set itest [lsearch $varlist $paramtype]
    if { $itest >= 0 } {
      for { set i 1 } { $i <= [lindex $lengthlist $itest] } { incr i } {
        set varname $element
        append varname _ $i
        set  array($varname) [lindex $data [expr {$i -1}]]
        set_field_colour $arrayname $varname 1
      }
    } else {
      set array($element) $data
      set_field_colour $arrayname $element 1
    }
  }
}

#-------------------------------------------------------------------
proc GetParamFromFile { format file param datain } {
#-------------------------------------------------------------------
#d_sum Get specified type of data from a specified file header
#d_arg format The file format (MTZ/PDB/MAP)
#d_arg file The full path input file name
#d_arg param The name of the type of data - corresponding to element in *_file_data array
#d_arg datain Output.  The returned data value
  upvar $datain data
  append arrayname $format "_file_data"
  upvar #0 $arrayname array

  if {[regexp MASK $format]} { set format MAP }
  set data ""

  set utility ""; append utility "Extract" $format "Data"
  if { [$utility $file] <= 0 } { return 0 }

  if {[ElementExists $arrayname $param]} {
    set data $array($param)
    return 1
  } else {
    return 0
  }
}


#d_index_title The Generic Line Widget
#----------------------------------------------------------------
proc CreateLine { linein args } {
#----------------------------------------------------------------
#d_sum Draw a line in a window
#d_ref  CCP4I programmers/CreateLine.html See the CCP4i Programmers Documentation
  upvar $linein line
  global system
  global configure
  global typedef

# Access the array for the current task

  set arrayname [ GetSystemVar frame_array ]
  upvar #0 $arrayname array

# Get the details of the current open frame
# get id for next frame line and create it

  set folder [GetSystemVar open_frame]
  if { $folder == "" } {
    OpenFolder protocol
    set folder [GetSystemVar open_frame]
  }

  incr array(LINES_DRAWN)

# Is the current open frame a blt table frame?
  if { [set table_row [lindex [set blttable [GetSystemVar blttable]] 0]] >= 0 } {

    set line $folder
    set row [GetSystemVar current_index_counter]
    if { $row == "" } { set row  [expr {$table_row + 1}] }
    set n_atoms [expr {$row * 100}] 

  } else {

    set table_row -1
    set line $folder.l$array(LINES_DRAWN)
    frame $line
    pack $line -side top -fill x -expand 1 -anchor e
    set n_atoms 0

  }

# Zero counts for all the possible widgets

  set message ""
  set help_pointer ""
  set packmode default
  set pack_template ""
  set pack_list {}
  set index [GetSystemVar current_index_counter]
  set varmenu_name ""
  set toggle_var ""
  set toggleon 0

# OK start parsing the argument list

#  puts "args $args"

  set n_args  [llength $args ]
  set n -1; while { $n <= $n_args } {
    incr n
    set field [lindex $args $n ]
#    puts "field $field"
    set widget ""
    set widget_name ""
    set widget_command ""
    set paste_command ""
    set next 0
    set label_mode ""
    set label_text ""
    set grey_var ""
  
# label widget 

    switch -- $field \
    label {

       set widget $field
       incr n; set label_text [lindex $args $n ]
       if {[regexp ^-ital [lindex $args [expr {$n + 1}]]]} {
         incr n 
	   append label_mode "-font {$configure(FONT_ITALIC)}"
       }


# message line 

    } message {

	incr n; set message [lindex $args $n ]

# help pointer

    } help {

        incr n; set help_pointer [lindex $args $n ]

# toggle display of the line dependent on a variable

    } toggle_display {

       incr n; set toggle_var [lindex $args $n ]
       incr n; set toggle_state [lindex $args $n ]
       incr n; set toggle_hitlist [lindex $args $n ]

# the generic 'widget'
    } widget {

      set dependent0 ""
      set varmenu_name ""
      incr n; set ele [lindex $args $n ]

# Sort out the data type -  this does the same stuff as GetTypeInfo etc
# put should be more efficient that multiple calls to that routine

      set ele0 $ele
      set arrayindex $ele
      if { $index != "" } { 
         append ele0 , 0 
         append arrayindex , $index
      }
      if {[catch {set type $array(_$ele0)}]} {
        Report 3 "ERROR no type for $ele0"
        puts "ERROR no type for $ele0"
        return
      }
      if {[catch {set typelist $typedef($type)} ]} {
        Report 3 "ERROR no typedef for $type"
        puts "ERROR no typedef for $type"
        return 
      }
#      puts "ele0 $ele0 typelist $typelist"
      set typename [ lindex $typelist 0]
      set element "[subst $arrayname]($arrayindex)"
        
      if { $help_pointer == "" } { set help_pointer [string tolower $ele] }

      switch $typename  \
      int {
        set widget "entry"
        set field_width [expr {2 + [GetTypeInfo0 $typelist $arrayname $arrayindex nchar]}]
        set entry_format int
        set entry_mode [GetTypeInfo0 $typelist $arrayname $arrayindex oblig ]
      } real {
        set widget "entry"
        set field_width [expr {2 + [GetTypeInfo0 $typelist $arrayname $arrayindex nchar]}]
        set entry_format real
        set entry_mode [GetTypeInfo0 $typelist $arrayname $arrayindex oblig ]
      } logical {
        set widget "checkbutton"
        set onvalue [GetTypeInfo0 $typelist $arrayname $arrayindex onvalue]
        set offvalue [GetTypeInfo0 $typelist $arrayname $arrayindex offvalue]
        if { [lindex $args [expr {$n + 1} ] ] == "-toggleon" } {
          set toggleon 1 
          set toggleonvar $arrayindex
          incr n
        }
        if { [lindex $args [expr {$n + 1} ] ] == "label" } {
          incr n 2; set label_text [lindex $args $n]
        }
      } exframe_rb {
         set widget "radiobutton"
         set element "[subst $arrayname]($ele)"
         set value $index
      } menu {
        set widget "menubutton"
        set menulist [lindex $typelist 1 ]
        set fields ""
        foreach item $menulist { lappend fields  [string length $item] }
        set field_width [max $fields]
        set pp [lsearch $menulist $array($arrayindex)]
        if { $pp < 0 } {
          set pp [lsearch [lindex $typelist 2 ] $array($arrayindex) ]
          if { $pp < 0 } {
            set array($arrayindex) ""
          } else {
            set array($arrayindex) [lindex $menulist $pp]
          }
        }
      } postmenu {
        set widget "menubutton"
        set menulist ""
        set postmenu 1
        set field_width [expr {1 + [GetTypeInfo0 $typelist $arrayname $arrayindex nchar]}]
      } varmenu {
        create_varmenu $arrayname $arrayindex
        set field_width [expr {1 + [GetTypeInfo0 $typelist $arrayname $arrayindex nchar]}]
        set widget "menubutton" 
        set menulist [GetTypeInfo0 $typelist $arrayname $arrayindex deflist]

# Check that the current parameter value is one of the menu options -
# if it isn't then see if it is one of the aliases - if it still isn't then
# set to empty string
        set pp [lsearch $menulist $array($arrayindex) ]
        if { $pp < 0 } { 
          set pp [lsearch \
           [GetTypeInfo0 $typelist $arrayname $arrayindex aliaslist] $array($arrayindex) ] 
          if { $pp < 0 } { 
            set array($arrayindex) ""
          } else {
            set array($arrayindex) [lindex $menulist $pp]
          }
        }
      } default_dir {
        set field_width 10
        set widget "menubutton"
        set menulist [GetTypeInfo0 $typelist $arrayname $arrayindex deflist]

# Check that the current parameter value is one of the menu options -
# if it isn't then see if it is one of the aliases - if it still isn't then
# set to empty string
        if { [lsearch $menulist $array($arrayindex) ] < 0 } {
          if { [set pp [lsearch [GetTypeInfo0 \
             $typelist $arrayname $arrayindex aliaslist] $array($arrayindex) ] ] < 0 } {
            set array($arrayindex) ""
          } else {
            set array($arrayindex) [lindex $menulist $pp]
          }
        }

      } mtz_label {
        set widget "menubutton"
        set field_width 25
        set menulist  $array($arrayindex)
      } mtz_label_out {
        set widget "entry"
         set field_width 25
      } file {
        set widget "entry"
        set field_width 50
        set entry_format file
        set entry_mode OBLIG
# treat everything else as text
      } mg_selection {
        set widget "entry"
        set field_width [expr {2 + \
	  [GetTypeInfo0 $typelist $arrayname $arrayindex nchar]}]
        set entry_format text
        set entry_mode [GetTypeInfo0 $typelist $arrayname $arrayindex oblig ]
        set paste_command "mg_paste_selection $arrayname $arrayindex SELECT_RESIDUE %W %x"
      } mg_sellist {
        set widget mg_sellist
        set field_width [expr {2 + \
          [GetTypeInfo0 $typelist $arrayname $arrayindex nchar]}]
      } varbutton {
        set widget varbutton
        #set array($arrayindex) \
        #  [GetTypeInfo0 $typelist $arrayname $arrayindex text]
        #set text [GetTypeInfo0 $typelist $arrayname $arrayindex text ] 
      } default {
        set widget "entry"
        set field_width [expr {2 + [GetTypeInfo0 $typelist $arrayname $arrayindex nchar]}]
        set entry_format text
        set entry_mode [GetTypeInfo0 $typelist $arrayname $arrayindex oblig ]
      }
        


# see if there are any arguments to the widget "command"

      while { [regexp ^- [lindex $args [expr {$n +1}]]] } {
        incr n; set nextword [string range [lindex $args $n] 1 end]
        switch $nextword \
        width {
             incr n; set field_width [lindex $args $n]
        } expand {
             set packmode expand
             set packmode_template $arrayindex
        } dependentdisplay {
             Report 0 "Not properly implemented -dependentdisplay"
        } oblig {
            set entry_mode OBLIG
        } command {
            incr n; set widget_command [lindex $args $n]
        } updatevarmenu {
 	   incr n; set varmenu_name [lindex $args $n]
 	   incr n; set varmenu_element [lindex $args $n]
        } next {
           set next 1
        } grey {
          incr n; set grey_var [lindex $args $n ]
          incr n; set grey_state [lindex $args $n ]
          incr n; set grey_hitlist [lindex $args $n ]
        }
      }

    } varlabel {

       set widget $field
       incr n; set arrayindex [Indxv [lindex $args $n ] $index ]
       set label_text $array($arrayindex)
       if {[regexp ^-ital [lindex $args [expr {$n + 1}]]]} {
         incr n 
         append label_mode "-font $configure(FONT_ITALIC)"
       }

           
# radiobutton

    } radiobutton {
 
       set widget "radiobutton"
       incr n; set arrayindex  [Indxv [lindex $args $n ] $index]
       set element "[subst $arrayname]($arrayindex)"
       incr n; set value [lindex $args $n ]
       incr n; set label_text [lindex $args $n ]

# bitmap button

    } bitmap_button {

       set widget  "bitmap_button"
       incr n; set bitmap_file \
	[SearchPath TOP icons [lindex $args $n ]]


# text button

    } button {

       set widget   "button"
       incr n; set text [lindex $args $n ]
       while { [regexp ^- [lindex $args [expr {$n + 1} ]]] } {
         incr n; set nextword [lindex $args $n]
         if { $nextword == "-command" } {
           incr n; set widget_command [lindex $args $n]
         }
       }

    } format {

        incr n;set packmode [lindex $args $n ]
        if { [StringSame $packmode "template" "table"] } {
           incr n;set pack_template [lindex $args $n]
        }

    } mg_icon {

        incr n; set mg_icon_mode [lindex $args $n ]
        incr n; set mg_icon_target [lindex $args $n ]
        mg_icon $arrayname $mg_icon_mode bitmap_file \
			widget_command $mg_icon_target
        set widget bitmap_button
   } object {
        set widget object
        incr n; set ele "::CGUIWindow::[lindex $args $n ]"
   } 


# --------------------------------------------------------------------
#
# Finished parsing input - now draw the widget 
#
# --------------------------------------------------------------------

   switch $widget \
   label {

     incr n_atoms
     set widget_name $line.l$n_atoms
     eval "label $widget_name \
                -text \"$label_text\" \
                -font {$configure(FONT_REGULAR)} \
                -anchor w  \
		$label_mode"

     lappend pack_list $widget_name

   } varlabel {

     incr n_atoms
     set widget_name $line.l$n_atoms
     eval "label $widget_name \
                -text \"$label_text\" \
                -font {$configure(FONT_REGULAR)} \
                -anchor w  \
                $label_mode"

     lappend pack_list $widget_name
     trace variable array($arrayindex) w \
        "update_varlabel $arrayname $arrayindex $widget_name"
     if { [lsearch $array(TRACE_LIST) $arrayindex] < 0 }  {
       lappend array(TRACE_LIST) $arrayindex
       trace variable array($arrayindex) w "update_main_scroll $line"
     }

   } entry {

      incr n_atoms
      set widget_name $line.e$n_atoms

# deal with "obligatory" entry

       if { $entry_mode == "OBLIG" } {
         entry $widget_name  -textvariable $element \
	 	-font $configure(FONT_REGULAR) \
          	-width $field_width
         bind $widget_name <FocusOut>                                      \
            "check_input $arrayname $arrayindex $entry_format 1"
         bind $widget_name <Return> \
            "check_input $arrayname $arrayindex $entry_format 1"
#         bind $widget_name <Key> [list checkinputchange  $widget_name %K]


       } else {

# non-obligatory entry

         entry $widget_name -textvariable $element \
		-font $configure(FONT_REGULAR) \
          	-width $field_width

          bind $widget_name <FocusOut>                                      \
            "check_input $arrayname $arrayindex $entry_format"
          bind $widget_name <Return> \
            "check_input $arrayname $arrayindex $entry_format"
       }
       lappend pack_list $widget_name


       if { $paste_command == "" } {
         bind $widget_name <Shift-Button-3> \
		"paste_into_entries $arrayname $line $n_atoms"
       } else {
         bind $widget_name <<PasteSelection>> "$paste_command"
         bindtags $widget_name [list $widget_name NoPasteEntry . all ]
       }
       if {$toggleon} { bind $widget_name <KeyRelease> \
		"toggle_on $arrayname $toggleonvar" }

   } menubutton {

       incr n_atoms
       set widget_name $line.mb$n_atoms
       #Test postmenu exists - if true then we are in context of mg 
       # and will make request for the menu definition when the 
       # menu is posted
       if { [info exist postmenu] } {
         switch $system(OPSYS) \
	 WINDOWS {
           button $widget_name  -textvariable $element \
            -relief raised \
            -width $field_width \
            -font $configure(FONT_REGULAR)
           lappend pack_list $widget_name
           bind $widget_name <Button-1> "mg_post_menu $arrayname $widget_name.m $ele $index"
         } default {
           menubutton $widget_name  -textvariable $element \
            -indicatoron 1 -relief raised \
            -width $field_width \
	    -font $configure(FONT_REGULAR) \
            -menu $widget_name.m
           lappend pack_list $widget_name
           menu $widget_name.m -tearoff 0
           $widget_name.m configure \
             -postcommand "mg_post_menu $arrayname $widget_name.m $ele $index" 
         }
         unset postmenu
       } else {
         menubutton $widget_name  -textvariable $element \
          -indicatoron 1 -relief raised \
          -width $field_width \
	  -font $configure(FONT_REGULAR) \
          -menu $widget_name.m
         lappend pack_list $widget_name
         menu $widget_name.m -tearoff 0
	 if { [info exists menulist] && [llength $menulist] > 0 } {
	   set break_count 0
           foreach item $menulist {
             $widget_name.m add command -label "$item"  \
		     -font $configure(FONT_REGULAR) \
	             -columnbreak \
		     [break_menu_column break_count $configure(MENU_LENGTH)] \
		     -command "UpdateDependentParams \"$item\" $arrayname  \
		     $arrayindex"
           }
         }
       }
       if { $next } {
         set f [frame $line.mb[incr n_atoms]]
         lappend pack_list $f
         ArrowButton $f.up -dir top \
		-command "menu_rotate $widget_name $arrayname $arrayindex 1"
         ArrowButton $f.down -dir bottom \
		-command "menu_rotate $widget_name $arrayname $arrayindex -1"
         pack $f.up $f.down
       }
     
       if {$toggleon} { bind $widget_name <ButtonPress-1> \
		"toggle_on $arrayname $toggleonvar" }

   } checkbutton {

       incr n_atoms
       set widget_name $line.cb$n_atoms
       CreateCheckbutton $widget_name  \
          -variable $element \
          -anchor w -relief flat \
	  -font $configure(FONT_REGULAR) \
          -onvalue $onvalue -offvalue $offvalue \
          -text $label_text
         lappend pack_list $widget_name

   } radiobutton {

       incr n_atoms
       set widget_name $line.rb$n_atoms
       radiobutton $widget_name \
          -variable $element \
          -value $value \
          -text $label_text \
	  -font $configure(FONT_REGULAR) \
          -anchor w -relief flat
         lappend pack_list $widget_name

        if { ![regexp WINDOWS $system(OPSYS)] } {
           $line.rb$n_atoms configure -selectcolor $configure(COLOUR_BOLD) }


   } bitmap_button {

       incr n_atoms
       set widget_name $line.b$n_atoms
       button $widget_name -bitmap @$bitmap_file \
	-bg $configure(COLOUR_PALE) \
	-highlightcolor $configure(COLOUR_PALE)
         lappend pack_list $widget_name
       if  {$widget_command != "" } {
        add_command $widget_name $widget_command }

   } button {

       incr n_atoms
       set widget_name $line.b$n_atoms
       button $widget_name  -text $text \
	-background $configure(COLOUR_PALE) \
	-font $configure(FONT_REGULAR)
         lappend pack_list $widget_name
       if { $widget_command  != "" } {
         bind $widget_name <Return> $widget_command
         add_command $line.b$n_atoms $widget_command
       }

    } varbutton {

       incr n_atoms
       set widget_name $line.b$n_atoms
       button $widget_name \
        -textvariable [subst $arrayname](MGLABEL_$arrayindex) \
	-background $configure(COLOUR_PALE) \
 	-font $configure(FONT_REGULAR)
       lappend pack_list $widget_name
       if { $widget_command  != "" } {
         bind $widget_name <Return> $widget_command
         add_command $line.b$n_atoms $widget_command
       }
       if { $grey_var != "" } { 
         toggle_button_disabled $widget_name $grey_var \
                          $grey_state $grey_hitlist 
       } elseif { [ElementExists $arrayname GREY_$arrayindex] } {
         eval [concat toggle_button_disabled $widget_name \
		 $array(GREY_$arrayindex)]
       }


   } mg_sellist {

       incr n_atoms
       lappend pack_list \
	 [mg_sellist $arrayname $arrayindex $line.sl$n_atoms]
       lappend array(WIDGET_$arrayindex) $line.sl$n_atoms

   } object {
    
      incr n_atoms
      $ele draw  $line.obj$n_atoms
      lappend pack_list  $line.obj$n_atoms
   }

# Associate message with input widget

   if { $widget != "label" && $widget_name != "" } {
      if { $message != "" } { SetMessage $arrayname $widget_name $message }

# Set up binding of F1 to Help text
      set program_help [GetSystemVar frame_program_help]
      bind $widget_name <Button-3> \
	"KeywordHelp $program_help $help_pointer"
   }

# Set binding of return to 'tab' to next widget
#  if { $widget != "label" } {
#     bind $widget_name <Return> "focus [tk_focusNext [focus] ]"
#  }


# Add special bindings for widgets

   switch $field \
   widget {

      if  {$widget_command != "" } {
        add_command $widget_name $widget_command
      }

      if  {$varmenu_name != "" } {
        add_command $widget_name \
	"update_varmenu $arrayname replace $varmenu_element $varmenu_name $arrayindex"
      }

# For the widget options save the field id for the variable
      lappend array(WIDGET_$arrayindex) $widget_name
      if { $widget == "entry" && $entry_mode == "OBLIG" } {
        check_input $arrayname $arrayindex $entry_format 1
      } elseif { [GetType $arrayname $arrayindex] == "_space_group" &&
                 $array($arrayindex) != "" } {
        check_input $arrayname $arrayindex $entry_format
      } elseif { $typename == "default_dir" } {
        lappend system(DEFDIR_WIDGET_LIST) \
        [list $widget_name $arrayname $arrayindex]
      }

   } varlabel {
      lappend array(WIDGET_$arrayindex) $widget_name
   } radiobutton {
      lappend array(WIDGET_$arrayindex) $widget_name
   }
# End of loop for handling a widget/label
  }

# Only handle the following after the whole line has been drawn
#
# Special packing modes
#

  if { $table_row >= 0 } {
# Check if user has customised the layout of the widgets in the table
    if { $packmode == "table" } {
      foreach atom $pack_list col_span $pack_template {
        blt::table $folder $atom $table_row,[lindex $col_span 0]
        if { [llength $col_span] > 1  } {
          blt::table configure $folder $atom \
	   -cspan [expr {[lindex $col_span 1] - [lindex $col_span 0]+ 1}]
        }
      }
    } else {
# use a default layout of one widget per cell in the table
      set col -1; foreach atom $pack_list { incr col
        blt::table $folder $atom $table_row,$col
      }
    }
# Apply any configue options entered as args to OpenSubFrame

    if { [set nanchor [llength [set anchor [lindex $blttable 1]] ]] > 0 } {
# Set the position of each slave within its parcel using the -anchor option
# We set the parameter on a column by column basis but BLT defines for each
# separate slave
      set icmax [min [llength $pack_list] $nanchor ]
      for { set ic 0 } { $ic < $icmax } { incr ic } {
        blt::table configure $folder [lindex $pack_list $ic] \
			-anchor [lindex $anchor $ic]
      }
    }

    SetSystemVar blttable [lreplace $blttable 0 0 [incr table_row]]

  } else {
    switch $packmode \
    MTZlabel {

      PackLabinLine $line
      set array(LINE_$line) "MTZlabel"

    } template {

      if { [llength $pack_list] > 0 } {
        eval "pack $pack_list -side left -anchor e"
        PackByTemplate $line $pack_template
        set array(LINE_$line) ""
        lappend array(LINE_$line) template $pack_template
      }

    } margins  {

      if { [llength $pack_list ] == 2 } {
        pack [lindex $pack_list 0] -side left -anchor e
        pack [lindex $pack_list 1] -side right
      } else {
        eval "pack $pack_list -side left -anchor e"
      }

    } expand {

      set expand_w $array(WIDGET_$packmode_template)
      foreach w $pack_list {
        if { $w == $expand_w } { 
          pack $w -side left -anchor e -expand 1 -fill x
        } else {
          pack $w -side left -anchor e
        }
      }

    } default {

      if { [llength $pack_list] > 0 } {
        eval "pack $pack_list -side left -anchor e" }
    }
    incr table_row
  }

  if { $toggle_var != "" }  { toggle_frame_display $line \
	$toggle_var $toggle_state $toggle_hitlist [expr {$table_row -1}]}

}

#----------------------------------------------------------------
proc CreateCheckbutton { widget_name args } {
#----------------------------------------------------------------
#d_sum Create a checkbutton
#d_desc This wraps the Tk checkbutton command and sets the colours \
appropriately depending on the platform and the Tcl/Tk version. It \
accepts any argument that is also acceptable to the checkbutton \
command.
#d_desc The wrapper is necessary because the colour scheme for 8.4 \
and earlier is not compatible with that in 8.5.
#d_arg widget_name The name of the checkbutton widget
    global configure
    global system
    global tcl_version
    set checkbuttonCmd [concat checkbutton $widget_name $args]
    if { ![regexp WINDOWS $system(OPSYS)] } {
	if { [regexp "^8\.\[01234\]" $tcl_version] } {
	    # Unix platform with Tcl/Tk 8.4 or earlier
	    lappend checkbuttonCmd \
		-selectcolor $configure(COLOUR_BOLD)
	} else {
	    # Unix platform with Tcl/Tk 8.5 or greater
	    lappend checkbuttonCmd \
		-selectcolor $configure(COLOUR_VERY_PALE)
	}
    }
    set w [eval $checkbuttonCmd]
    return $w
}

#--------------------------------------------------------------------------
proc menu_rotate { mb arrayname arrayindex inc } {
#--------------------------------------------------------------------------
  upvar #0 $arrayname array
# User has clicked up/down arrow by a menu - so increment  the value 
# of the menubutton
  if { ![get_type_list $arrayname $arrayindex typelist] } { return }
  set menulist $array([lindex $typelist 1])
  if { [set n [lsearch $menulist "$array($arrayindex)" ] ] \
					< 0 } { return }
  incr n $inc; set nmax [expr {[llength $menulist] -1}]
  if { $n < 0 } { set n $nmax } elseif { $n > $nmax } { set n 0 }
  $mb.m invoke $n
}

#----------------------------------------------------------------
proc CreateLineTemplate { name xpos } {
#----------------------------------------------------------------
#d_sum Define a template for the layout of a line
#d_ref  CCP4I programmers/CreateLineTemplate.html See the CCP4i Programmers Documentation
  set arrayname [ GetSystemVar frame_array ]
  upvar #0 $arrayname array
  set array(TEMPLATE_$name) $xpos
}

#--------------------------------------------------------------------------
proc PackByTemplate { line pack_template } {
#--------------------------------------------------------------------------
#d_sum Apply the template defined by CreateLineTemplate to pack a line
#d_desc This procedure called by CreateLine for any line with command \
'format template'.  The procedure uses the Tk place command (rather than \
pack) to set the position of each widget on a line.
#d_arg line The Tk id for the line
#d_arg pack_template The name of the template to apply
  set arrayname [GetSystemVar frame_array]
  upvar #0 $arrayname array

  set packlist $array(TEMPLATE_$pack_template)
  set children [winfo children $line ]
  set nchildren [llength $children]
  set npos [llength $packlist]

  if { $nchildren > $npos } { 
    Report 0 "ERROR in template packing of line $line"
    Report 0 "Template does not have enough elements"
    return 0
  }

  for  { set pp 1 } { $pp < $nchildren } { incr pp } {
    if { [lindex $packlist $pp ] != "-" } {
      set child [lindex $children $pp ]
      if { [winfo manager $child] == "pack" } { pack forget $child }
      set xpos [lindex $packlist $pp ]
      place $child -in $line -rely 0.05 -relheight 0.9 -relx $xpos
    }
  }
}

#----------------------------------------------------------------------
proc UpdateDependentParams { selection arrayname param0   args } {
#----------------------------------------------------------------------
#d_sum Callback afer user selects item from menu update the array element
#d_desc There is a 'problem' with Tk that when a user selects the item from \
a menu the data in the array element associated with the menubutton is \
not updated.  The menubutton argument -textvariable might look like it \
will do the trick but there is an issue of which context \
the variable is defined in (i.e. in the context of a procedure or the \
global context). 
#d_arg selection The text of the selected menu item
#d_arg arrayname Name of data array
#d_arg param0 The name of the array element associated with the menubutton
  upvar #0 $arrayname array
#  puts " param0 selection $param0 $selection"

# Set the array value to the value the user selected from the list

  if { [catch { set array($param0) $selection } status ] } {
     Report 3 "WARNING: error updating parameter $param0 to $selection"
  }
}


#-------------------------------------------------------------------------
proc initialise_menu { field } {
#-------------------------------------------------------------------------
#d_sum Create a menu or reinitiallise an existing one
#d_desc This procedure used to support variable menus and CreateLabin \
(which is a special case of a variable menu)
#d_arg field The menubutton widget
  if { ![ winfo exists $field] } {
    Report 3 "initialise_menu $field does not exist - expect problems soon!"
    crash
  }
  if { ![ winfo exists $field.m] } {
    menu $field.m -tearoff 0
  } elseif { [ $field.m index end] >= 0 } {
    $field.m delete 0 end
  }
}

#-----------------------------------------------------------------------
proc UpdateVarLabel { arrayname var value } {
#-----------------------------------------------------------------------
#d_sum Update a variable label to an explicitly entered value
#d_arg arrayname Name of data array
#d_arg var Name of array element associated with the variable label widget
#d_arg value New value for variable label
  upvar #0 $arrayname array
#Update the text of a varlabel widget
  set field_list [GetWidget $arrayname $var]
  foreach field $field_list {
    if { [winfo exists $field] } { $field configure -text $value }
  }
}

#-----------------------------------------------------------------------
proc update_varlabel { arrayname arrayindex widget_name n1 n2 op } {
#-----------------------------------------------------------------------
#d_sum Update a variable label when the associated variable is changed
#d_desc The Tcl trace command is used to call this procedure whenever the \
associated variable is changed.
#d_arg arrayname Name of data array
#d_arg arrayindex Name of array element containing the variable text for the label
#d_arg widget_name Name of the widget (Tk id) to be updated
#d_arg n1,n2,op  Additional arguments added by the trace command
  upvar #0 $arrayname array
#  puts "update_varlabel $array($arrayindex)"
  $widget_name configure -text $array($arrayindex)
}

#---------------------------------------------------------------------
proc add_command { field cmd } {
#---------------------------------------------------------------------
#d_sum Bind a command to a widget which may be a menu or an entry widget
#d_desc The command will be issued when  the user changes the selected \
menu item or hits Return key or moves focus out of the entry widget
#d_desc This procedure needs to check the existing command string and \
append to it.
#d_arg field The Tk id for the widget
#d_arg cmd The command to be bound
#

  if { [winfo exists $field.m ] } {
    set nitems [[ $field cget -menu ] index last ]
    if { $nitems == "none" } { return }
    for { set i 0 } { $i <= $nitems }  {incr i } {
      set comline  [ [$field cget -menu ] entrycget $i -command ]
      if { [string first $cmd $comline] < 0 } {
        if { $comline != "" } {
          append comline " ; "
        }
        [$field cget -menu ] entryconfigure $i -command "$comline $cmd"
      }
    }

  } elseif { [string match [winfo class $field] Menubutton] } {
    # A menubutton with no currently defined menu is
    # probably from ccp4mg
    return

  } elseif { [winfo exists $field] &&
        [regexp Entry [winfo class $field]] } {

    bind $field <FocusOut> +$cmd
    bind $field <Return> +$cmd

  } elseif { [winfo exists $field] } {

    set comline [$field cget -command ]
    if { [string first $cmd $comline]<0 } {
      if { $comline != "" } {
        append comline " ; "
      }
      $field configure -command "$comline $cmd "
    }
  }
}


#-------------------------------------------------------------------------
proc paste_into_entries { arrayname line ientry } {
#-------------------------------------------------------------------------
#d_sum Paste into multiple fields
#d_ref CCP4I general/intro.html#cut_n_paste See User Documentation on Cut-n-Paste
#d_arg arrayname Name of data array
#d_arg line The Tk id of the selected line
#d_arg ientry The number of the selected entry field (n_atom in name)
  upvar #0 $arrayname array

#  puts "paste_into_entries arrayname $arrayname ientry $ientry"

  if { [catch {set input [selection get -type STRING]} ] ||
	[set n_input [llength $input] ] <= 0 } {
    WarningMessage "Nothing currently selected"
    return
  }

  set s_input [split $input \n ]
  foreach inpl $s_input {
    if { [llength $inpl] > 0 } { lappend split_input $inpl }
  }
  set nline [llength $split_input]

# Get list of entry widget on the line and the names of the param variables
  foreach widget [winfo children $line] {
    if { [winfo class $widget] == "Entry"} { lappend entry_list $widget}
  }
  set n_entry [llength $entry_list]
  foreach entry $entry_list {
    set var [lindex [ split [$entry cget -textvariable] () ] 1]
    GetIndx $var root c1 c2
    lappend param_list $root
  }
  set n_ientry [lsearch -regexp $entry_list "e$ientry$" ]
#  puts "n_entry $n_entry n_ientry $n_ientry param_list $param_list"
#
# Find the def_proc0 for the extend/toggle frame
  if { $c1 != "" } {
    set def_proc0 ""
    foreach varlist [array names array VARS_*] {
      if { [lsearch $array($varlist) $root] >= 0 } {  
         set def_proc0 [string range $varlist 5 end]
      }
    }
#    puts "def_proc0 $def_proc0"
  }


  if { $nline > 1  && $def_proc0 != "" } {

    global pasteq
    DefineVariable pasteq NSKIP _positiveint ""
    DefineVariable pasteq NMISS _positiveint ""

    OpenWindow .pasteq "Paste" Paste -message pasteq
    CreateFrame .pasteq pasteq
    CreateButton .pasteq quit Quit "continue_paste pasteq quit"
    CreateButton .pasteq paste Paste "continue_paste pasteq paste"

    OpenFolder protocol

    CreateLine line \
	label "Paste in the following $nline lines of data.." -italic

    foreach inpl $split_input {
      CreateLine line \
        label "$inpl"
    }

    CreateLine line \
      label "Skip first" \
      widget NSKIP \
      label "columns and skip the last" \
      widget NMISS \
      label "columns of input lines"

    update_main_scroll .pasteq

    vwait pasteq(CONTINUE)
    destroy .pasteq
    if { $pasteq(NSKIP) == ""} {set nskip 0} else { set nskip $pasteq(NSKIP)}
    if { $pasteq(NMISS) == ""} {set nmiss 0} else { set nmiss $pasteq(NMISS)}
    if {[regexp quit $pasteq(CONTINUE)]} { unset pasteq; return }
    unset pasteq

    set cline $c1; set counter 0
    set indexVar $array(XF_INDEX_$def_proc0)
    if { $c2 != "" } {
      set cline $c2
      set counter $c1
      append indexVar ",$counter"
    }
#    puts "cline $cline counter $counter indexVar $indexVar"

# Do we need to open more toggle/extend lines
    if { [set increment [expr {$cline + $nline - 1 - $array($indexVar)}]] > 0 } {
      if {[regexp extending $array(FRAME_TYPE_$def_proc0)]}  {
        update_extendingframe $def_proc0 $counter $arrayname $indexVar \
          $array($indexVar) $increment 1
      } else {
        update_toggleframe $def_proc0 $counter $arrayname $indexVar \
          $array($indexVar) $increment 1
      }
    }

# load the data into the array

    for {set l 0 } {$l < $nline } {incr l} {
      set inpl [lindex $split_input $l]
      set index [expr {$l + $cline}] ; set ii $nskip
      set ibeg $n_ientry
      set iend [expr {[min [expr {$ibeg + [llength $inpl] -$nskip -$nmiss} ] \
		          $n_entry ]} ]
#    puts "ibeg $ibeg iend $iend"
      if { $counter == 0 } {
        foreach param [lrange $param_list $ibeg $iend] {
          set array([Indxv $param $index]) [lindex $inpl $ii]
          check_input $arrayname [Indxv $param $index]
          incr ii
        }
#	foreach param [lrange $param_list $ibeg $iend] {
#          event generate [GetWidget $arrayname [Indxv $param $index]] \
#		 <Return>  -when tail
#        }
      } else {
        foreach param [lrange $param_list $ibeg $iend] {
          set array([Indxv $param $counter $index]) [lindex $inpl $ii]
          check_input $arrayname [Indxv $param $counter $index]
          incr ii
        }
#        foreach param [lrange $param_list $ibeg $iend] {
#          event generate [GetWidget $arrayname [Indxv $param $counter $index]]  \
#	     <Return> -when tail
#        }
      }
    }

# Handle just one line of input without pratting about
  } else {
    set n_copy [min $n_input [expr {$n_entry - $n_ientry}] ]
    set ii $n_ientry
    for { set i 0 } { $i < $n_copy } { incr i} { 
      set var [lindex [ split \
	[[lindex $entry_list $ii] cget -textvariable] () ] 1]
      set array($var) [lindex $input $i]
      check_input $arrayname $var
      incr ii
#      foreach w [GetWidget $arrayname $var] {
#        puts "generate w $w"
#        event generate $w <Return> -when now
#      }
    }
  }
}

#-------------------------------------------------------------------
proc continue_paste { arrayname mode } {
#-------------------------------------------------------------------
#d_sum Handler for user input for paste GUI
#d_arg arrayname Name of data array
#d_arg mode User's input of 'continue' mode
  upvar #0 $arrayname array
  set array(CONTINUE) $mode
}

#-------------------------------------------------------------------
proc toggle_on { arrayname toggleonvar } {
#-------------------------------------------------------------------
#d_sum Handler to toggle on a checkbutton when user inputs anywhere on a line
#d_desc Handles the -toggleon  option in CreateLine
#d_arg arrayname Name of data array
#d_arg toggleonvar Name of element in array to be toggled on
  upvar #0 $arrayname array
  set array($toggleonvar) 1
}
  
#------------------------------------------------------------------------------
proc check_input { arrayname arrayindex { format {} } { oblig 0 }  } {
#------------------------------------------------------------------------------
#d_sum Check entry widget input is consistent with data type
#d_desc Checking is not very strict - for numerical input the data type \
defines integer/real and possible range.  This procedure will try to correct \
poor input and will set the widget to the warning colour if input is wrong.
#d_arg arrayname Name of data array
#d_arg arrayindex Name of element in array
#d_arg format Optional data type for the array element
#d_arg oblig Optional 1=some data input is obligatory 
  upvar #0 $arrayname array
  global deflists

  set status 0
#  puts "check_input arrayindex $arrayindex $array($arrayindex) $format"
  if { $format == "" } { set format [GetTypeInfo $arrayname $arrayindex type] }

  if { [string trim $array($arrayindex)] == {} } {
    set status [expr {1 - $oblig}]
    set fvalue {}

   } elseif { $format == "file" } {
     return
   } elseif { $format == "text" } {

     set teststring [string trim [string toupper  $array($arrayindex)] ]
     set deflist [GetTypeInfo $arrayname  $arrayindex deflist ]

#  make sure spacegroup name appears unquoted in task window
     if { [GetType $arrayname $arrayindex] == "_space_group" } {
       set array($arrayindex) [string trim [string trim $array($arrayindex)] ']
       set teststring $array($arrayindex)
     }

     if { [ llength $deflist ] == 0 } {
       set fvalue $array($arrayindex)
       set status 1

     } elseif { [string first "@" $deflist] == 0 } {
       set defindex [string range $deflist 1 end]
       if { [lsearch $deflists($defindex) $teststring] >= 0 } {
         set fvalue $array($arrayindex)
         set status 1
       }
       
     } else {

       if { [lsearch $deflist $teststring] >= 0 } {
         set fvalue $array($arrayindex)
         set status 1
       }
     }
   } elseif { $format == "dir" } {

       set status [file isdirectory $array($dir) ]
       set fvalue $array($arrayindex)

   } else {

     switch $format \
     real {
       set status [scan $array($arrayindex) "%f"  fvalue]
     } int {
       set status [scan $array($arrayindex) "%i"  fvalue]
     } default {
       set status 0
     }
     if { $status > 0 } {
       set min_value [GetTypeInfo $arrayname $arrayindex min ]
       set max_value [GetTypeInfo $arrayname $arrayindex max ]
       if { ($min_value != "*" && $fvalue  < $min_value) ||
            ($max_value != "*" && $fvalue > $max_value ) } {
         set status 0
       }
     }
   }

#   puts "check_input status $status"
   if {$status > 0 } { set array($arrayindex) $fvalue }
   set_field_colour $arrayname $arrayindex $status
}

#---------------------------------------------------------------------
proc set_field_colour { arrayname arrayindex status } {
#---------------------------------------------------------------------
#d_sum Set the colour of an input widget dependent on validity of user input
#d_arg arrayname Name of data array
#d_arg arrayindex Name of element in array containing variable
#d_arg status validity of user input 1=valid 0=invalid
  global configure

  set field_list [GetWidget $arrayname $arrayindex]
  if {$field_list == "" } {return 0 }
  foreach field $field_list {
    if { [winfo exists $field ] } {
      if {$status > 0 } {
        $field configure -background $configure(COLOUR_BACKGROUND)
      } else {
        $field configure -background $configure(COLOUR_WAITING)
      }
    }
  }
}



#----------------------------------------------------------------------------
#proc checkinputchange { field char } {
#----------------------------------------------------------------------------
# REDUNDANT ???  Wrong solution ot problem of user Tabing to next field
#  global configure
#  if { [regexp {(Tab)} $char charout] == 0 }  {
#  $field configure -background $configure(COLOUR_WAITING)
#  }
#}
#d_index_title Other Complex Widgets

#-------------------------------------------------------------------------
proc CreateListbox { frameVar param {args} } {
#-------------------------------------------------------------------------
  upvar $frameVar frame
  global configure

  set dataarrayname ""
  set height 10
  set width 30
  set font FONT_REGULAR

  set arrayname [ GetSystemVar frame_array ]
  upvar #0 $arrayname array

# now see what input arguments we have
  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp  -- [lindex $args $n ] \
    array {
      incr n; set dataarrayname  [lindex $args $n ]
    } height {
      incr n; set height [lindex $args $n ]
    } width {
      incr n; set width [lindex $args $n ]
    } font {
      incr n; set font [lindex $args $n ]
    }
    incr n
  }

  
  incr array(LINES_DRAWN)
  set frame [GetSystemVar open_frame].l$array(LINES_DRAWN)
  lappend array(WIDGET_$param) $frame
  frame $frame
  pack $frame -side top -fill x -anchor e

  listbox $frame.list \
        -yscrollcommand [list $frame.scroll set] \
        -font $configure($font) \
	-height $height \
	-width $width 
  scrollbar $frame.scroll -command [list $frame.list yview]
  pack $frame.list -side left -fill both -expand true -anchor e
  pack $frame.scroll -side left -fill y -anchor e

  GetIndx $param root c1 c2
#  puts "frame $frame param $param root $root c1 $c1 c2 $c2"

# If there is a dataarray specified then switch to using that

  if { $dataarrayname != "" } {
    upvar #0 $dataarrayname dataarray

    if { ![ElementExists $dataarrayname $param] } {
      puts "Element does not exist $dataarrayname $param"
      return 0
    }

    if { $c1 == "0" } {
      set element_list [GetIndexedElements dataarrayname $root]
      foreach element $element_list {
        $frame.list insert end $dataarray($element)
      }
    } elseif { $c2 == "0" } {
      set element_list [GetIndexedElements dataarrayname $root $c1 ]
      foreach element $element_list {
        $frame.list insert end $dataarray($element)
      }
    } elseif { $c1 == "" && [llength $dataarray($param) ] > 0  } {
      foreach f $dataarray($param) {
        $frame.list insert end $f
      }
    }

  } else {

    if { $c1 == "0" } {
      set element_list [GetIndexedElements arrayname $root]
      foreach element $element_list {
        $frame.list insert end $array($element)
      }
    } elseif { $c2 == "0" } {
      set element_list [GetIndexedElements arrayname $root $c1 ]
      foreach element $element_list {
        $frame.list insert end $array($element)
      }
    } elseif { $c1 == "" } {
      foreach f $array($param) {
        $frame.list insert end $f
      }
    }
  }
}


#---------------------------------------------------------------------------
proc CreateButton { w name text command args } {
#---------------------------------------------------------------------------
#d_sum Create an action button in the 'button' frame of a window created by 'CreateFrame'
#d_arg w The window id (a Tk id)
#d_arg name The button name (appended to the Tk widget id)
#d_arg text Text to appear on button
#d_arg command The command to be bound to the button
#d_opt0 -message message
#d_opt1 help message to associate with button
#d_opt0 -default
#d_opt1 undocumented
  global configure

  set message ""

# parse the argument list
  set n_args  [llength $args ]
  set n -1; while { $n <= $n_args } {
    incr n
    set field [lindex $args $n ]
    switch -- $field \
      -message {
	incr n; set message [lindex $args $n ]
        set arrayname [ GetSystemVar frame_array ]
    }
  }

  button  $w.buttons.$name -text "$text" \
        -font $configure(FONT_REGULAR) \
        -background $configure(COLOUR_PALE) \
        -command "$command"
  pack $w.buttons.$name  -side right -expand 1
  if { [lsearch $args "-default"] >= 0 } {
    $w.buttons.$name configure -borderwidth 4
    bind $w <Return> "$command"
  }
  bind $w.buttons.$name <Return> "$command"

# Associate message with input widget
  if { $message != "" } { SetMessage $arrayname $w.buttons.$name $message }

  return  $w.buttons.$name
}


#-------------------------------------------------------------------
proc CreateText { textframeVar stuff { args } } {
#-------------------------------------------------------------------
#d_sum Create a Tk text widget, optionally scrollable.
#d_desc NOTE: This procedure needs an extra option to allow the user to \
edit the text.  The text probably ought to be associated with an \
array element (i.e. treated like any other widget) but there is \
question of when to update the array parameter.
#d_desc And then should be fully documented API
#d_arg textframeVar Returned Tk text widget id
#d_arg stuff Text to enter in the text widget
#d_opt0 -scroll
#d_opt1 Make widget vertically scrollable
#d_opt0 -height height
#d_opt1 Height of widget in number of text lines
#d_opt0 -arguments arguments
#d_opt1 Arguments to configure the text widget (i.e. valid Tk arguments)

  global configure
  upvar $textframeVar textframe

  set scroll 0
  set height 10
  set arguments ""
  set nargs [llength $args]
  set n -1
  while { $n < $nargs } {
    incr n
    set comd [lindex $args $n ]
    if {$comd == "-scroll" } {
      set scroll 1
    } elseif { $comd == "-height" } {
      incr n; set height [lindex $args $n ]
    } elseif { $comd == "-arguments" } {
      incr n; set arguments [lindex $args $n ]
    }
  }

  OpenSubFrame frame

  if { !$scroll } { 
    set textframe [text $frame.text -relief flat -setgrid true \
        -font $configure(FONT_FIXED) \
        -height $height \
	-state disabled ]
  } else {
    set textframe [text $frame.text -relief flat -setgrid true \
      -yscrollcommand "$frame.scroll set" \
      -wrap word \
      -font $configure(FONT_FIXED) \
      -height $height \
      -relief sunken \
      -state disabled ]
    scrollbar $frame.scroll -relief flat  \
            -command "$textframe yview" -orient vertical
    pack $frame.scroll -side right -fill y
  }
  $textframe tag configure texttag -wrap word -font $configure(FONT_ITALIC)
  pack $textframe -side left -expand true -fill both
  $textframe insert end "$stuff" texttag

  CloseSubFrame
 
  if { $arguments != "" } { eval "$textframe configure $arguments" }
}

#-------------------------------------------------------------------------
proc AppendTextWindow { w text args } {
#-------------------------------------------------------------------------
#d_sum Append text to CreateText widget
#d_arg w Tk id of the text widget
#d_arg text Text to append to widget
#d_opt0 -init
#d_opt1 Reinitialise the widget (i.e. delete any existing text)
  $w configure -state normal
  if { [lsearch $args -init] >= 0 } { $w delete 1.0 end }
  $w insert end "$text \n"
  $w configure -state disabled
}

#-------------------------------------------------------------------------
proc add_modalDialog_safeguard { w } {
#-------------------------------------------------------------------------
#d_sum Add the modalDialog bindtag to a window
#d_desc When triggered, the modalDialog binding deiconifies and raises \
the window in question. When combined with the "grab" command, this is \
used to ensure that a window doesn't get lost under other windows on the \
desktop - attempts to access functions in other windows (e.g. by clicking \
on buttons) will instead trigger the binding to bring the specified \
window to the fore.
#d_arg w Window to add the modalDialog binding to

  if { [lsearch [bindtags $w] modalDialog] < 0 } {
    bindtags $w [linsert [bindtags $w] 0 modalDialog]
  }
}

#-----------------------------------------------------------------------
proc break_menu_column { counterVar column_length } {
#-----------------------------------------------------------------------
#d_sum Internal procedure to set the -columnbreak value for items in a menu
#d_desc When invoked this procedure increments the counter for the number \
of items in the current menu column, if this exceeds the number in \
column_length then the counter is reset and 1 is returned (indicating that \
the current item should appear at the head of a new column); otherwise 0 is \
returned (indicating that the item should appear underneath the previous item \
in the same column).
#d_arg counterVar Name of a counting variable which must be set to zero in \
the calling procedure for each menu
#d_arg column_length The maximum number of items which can appear in each \
column of the menu
    upvar 1 $counterVar counter
    incr counter
    if { $counter > $column_length } {
	set counter 1
	return 1
    } else {
	return 0
    }
}
