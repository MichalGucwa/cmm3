#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - exframe.tcl
#
#
# Library routines & support routines for extending and toggle frames
#
#====================================================================

#CCP4i_cvs_Id $Id$

#d_index_title Extending and Toggle Frames (src/exframe.tcl)
#d_intro_title Extending and Toggle Frames
#d_intro Read the Programmers Guide in main CCP4i Documentation.
#d_ref CCP4I programmers/task_windows.html#extending_and_toggle_frames See here.
#d_intro The application programmer must provide a procedure which draws one \
'row' of the extending or toggle frame (it may be more than one line).  The \
name of this procedure is used as a reference for the parameters used to \
support this functionality (eg array(XF_INDEX_$def_proc0) where def_proc0 is \
the name of the defining procedure.

#d_intro Either extending or toggle frames can have a 'child' extending \
frame nested inside the 'parent' frames.  Many of the following procedures \
have an argument 'counter' which is the number of the parent frame for a \
child frame.  This parameter is set to 0 if the frame is not nested within \
another frame.

#---------------------------------------------------------------------
proc CreateToggleFrame { indexVar def_proc0 message title \
         add_text indexed_parameters args } {
#---------------------------------------------------------------------
#d_sum Create a toggle frame widget
#d_desc A toggle frame widget differs from an extending frame in that each 'row' \
of the widget has a title line, similar to a folder title line, which may be \
clicked on to toggle the visibility of the 'row'.
#d_arg indexVar Name of array element which is the counter for the number of open toggle frames.
#d_arg def_proc0 Name of procedure which defines the content of one 'row'
#d_arg message The message line associated with the 'Add whatever' button
#d_arg title Title line for each toggle frame
#d_arg add_text Text to appear in the  'Add whatever' button
#d_arg indexed_parameters A list of all of the parameters which are referenced in the def_proc0 procedure
#d_opt0 -depend dependent_frame
#d_opt1 The name of the defining procedure for another toggle frame or \
extending frame widget which is incremented and edited in sync with the \
'master' widget.
#d_opt0 -child child_frame
#d_opt1 The name of the defining procedure for another toggle frame \
or extending frame widget which is nested within this 'master' widget.
#d_opt0 -noadd
#d_opt1 Do not draw the Edit menu button and increment button for this widget.  \This implies that this widget is dependent on another 'master' widget.
#d_opt0 -edit_proc edit_procedure
#d_opt1 When the user increments or edits the rows in the widget call the \
procedure edit_procedure.  This procedure should be defined in the \
taskname.tcl file.
#d_opt0 -justify side
#d_opt1 Set the justification of the subframes. 'Side' can be left, right or \
center. The default is center.
  set arrayname [ GetSystemVar frame_array ]
  upvar #0 $arrayname array

  set counter 0
  set ndep 0
  set noaddline 0
  set depframes ""
  set children ""
  set edit_proc ""
  set anchor n

  set nargs [llength $args] ; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n ] \
    depend {
       incr ndep
       incr n
       lappend depframes "[lindex $args $n ]"
    } child {
       incr n
       lappend children [lindex $args $n ]
    } noadd {
       set noaddline 1
    } edit_proc {
       incr n; set edit_proc [lindex $args $n ]
    } justify {
       incr n
       set justify [lindex $args $n ]
       switch -exact -- $justify {
	 left {
	   set anchor nw
	 }
	 right {
	   set anchor ne
	 }
	 center {
	   set anchor n
	 }
       }
    }
    incr n
  }

  OpenSubFrame top_frame
  OpenSubFrame frame

  frame $frame.dummy -height 1
  pack $frame.dummy -side top

  append def_proc $def_proc0 _ $counter

# The following parameters are referenced by def_proc and are unique
# for each instance of the toggle frame
  set array(FRAME_$def_proc) $frame
  set array(XF_EDIT_$def_proc) ""
  set array(XF_SELECT_$def_proc) ""

# The following params are refenced bu def_proc0 and are common between all
# instances of the toggle frame
  set array(CHILD_$def_proc0) $children
  foreach child $children {
    set array(PARENT_$child) $def_proc0
  }
  if {$noaddline} {
    set array(N_DEPFRAMES_$def_proc0)  -1
    set array(DEPFRAMES_$def_proc0)  ""
  } else {
    set array(N_DEPFRAMES_$def_proc0) $ndep
    set array(DEPFRAMES_$def_proc0) $depframes
  }
  set array(XF_INDEX_$def_proc0) $indexVar
  set array(FRAME_TYPE_$def_proc0) toggle
  set array(FRAME_TITLE_$def_proc0) $title
  set array(FRAME_ANCHOR_$def_proc0) $anchor
  set array(EDIT_PROC_$def_proc0) $edit_proc
  set array(HELP_$def_proc0) [GetSystemVar frame_program_help]
  set array(VARS_$def_proc0) $indexed_parameters

  if {$array(N_DEPFRAMES_$def_proc0) >= 0 && $array($indexVar) > 0 } {
    append array(UPDATE_SCRIPTS) \
   "update_toggleframe $def_proc0 0 $arrayname $indexVar 0 $array($indexVar) 0\n"
  }
  CloseSubFrame

  if { $noaddline == 0 } {
    create_addline_command line $message $indexVar update_toggleframe0  \
         $def_proc0 0  $add_text 1 
    set array(XF_COMLINE_$def_proc) $line
  }
  CloseSubFrame
}
#---------------------------------------------------------------------
proc update_toggleframe0 { def_proc0 counter arrayname indexVar increment \
                                          update_scroll } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array
  update_toggleframe $def_proc0 $counter $arrayname $indexVar \
	$array($indexVar) $increment $update_scroll
}

#---------------------------------------------------------------------
proc update_toggleframe { def_proc0 counter arrayname indexVar \
	current increment update_scroll } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

# If the 'new' frame index is same as the current frame then do nothing
  SetSystemVar frame_program_help $array(HELP_$def_proc0)
  set maxlines [GetTypeInfo $arrayname $indexVar max ]
  set minlines [GetTypeInfo $arrayname $indexVar min ]
  set nlines [max $minlines [min $maxlines  \
                   [expr {$current + $increment}] ] ]
  append def_proc $def_proc0 _ $counter

  if { $increment < 0 } {
    if { $current <= $minlines } { return }
    delete_frame $arrayname $def_proc0 $counter $current
  } elseif { $increment  > 0 } {
    if { $current >= $maxlines } { return }
# create the array elements
    for { set c1 [expr {$current +1} ] } { $c1 <= $nlines } { incr c1 } {
      append_toggle_frame $arrayname $def_proc0 0 $c1
    }

    if { $array(N_DEPFRAMES_$def_proc0) > 0 } {
      foreach dep_proc0 $array(DEPFRAMES_$def_proc0) {
        if {[regexp extending $array(FRAME_TYPE_$dep_proc0)]}  {
          update_extendingframe $dep_proc0 $counter $arrayname $indexVar \
		$current $increment $update_scroll
        } else {
          update_toggleframe $dep_proc0 $counter $arrayname $indexVar \
                $current $increment $update_scroll
        }
      }
    }
  }

  if { $array(N_DEPFRAMES_$def_proc0) >= 0 } {
    set array($indexVar) $nlines
    SetSystemVar block_scroll_update 0
    if { $update_scroll } { update_main_scroll $array(FRAME_$def_proc) }
  }

  # If there is a user defined procedure to run after editing then run it now
  if { $array(EDIT_PROC_$def_proc0) != "" } {
    if { [info exists array(PARENT_$def_proc0)] } {
      GetIndx $indexVar root c1 c2
      eval "$array(EDIT_PROC_$def_proc0) $arrayname $c1 $array($indexVar)"
    } else {
      eval "$array(EDIT_PROC_$def_proc0) $arrayname $array($indexVar)"
    }
  }
}

#-------------------------------------------------------------------------
proc create_toggle_button { frame arrayname def_proc0 counter c1 } {
#-------------------------------------------------------------------------
#d_sum Create the title line for the toggle frame
#d_arg frame Tk id for the toggle frame
#d_arg arrayname Name of array
#d_arg def_proc0 Name of procedure which defines the content of one 'row'
#d_arg counter The 'row' number for the top level of nesting if this is a \
nested toggle frame (is 0 for a top level toggle frame).
#d_arg c1 The 'row' number for the toggle frame.

  global configure
  global system
  upvar #0 $arrayname array

  append def_proc $def_proc0 _ $counter
#  puts "create_toggle_button def_proc $def_proc c1 $c1"
  set array([Indxv FRAME_TOGGLE_$def_proc $c1]) "open"
  set array([Indxv FRAME_$def_proc $c1]) $frame
  set title $array(FRAME_TITLE_$def_proc0)

  frame $frame.top \
	-background $configure(COLOUR_VERY_PALE)

  label $frame.top.l1 -text "   $title $c1"\
        -font $configure(FONT_ITALIC) \
	-background $configure(COLOUR_VERY_PALE)
  CreateCheckbutton $frame.top.b1                                         \
        -variable [subst $arrayname](FRAME_TOGGLE_[subst $def_proc],[subst $c1]) \
        -relief flat -anchor w  \
	-background $configure(COLOUR_VERY_PALE) \
        -highlightbackground $configure(COLOUR_VERY_PALE) \
        -indicatoron 1   \
        -onvalue "open" -offvalue "closed"  \
        -command "update_subframe_display $arrayname $def_proc $c1 "

  if { "$system(OPSYS)" != "NT" } {
    $frame.top.b1 configure -selectcolor $configure(COLOUR_BOLD) }

  label $frame.top.l2 -text "  " \
	-background $configure(COLOUR_VERY_PALE)

  pack $frame.top  -side top -fill x 
  pack $frame.top.l1  -side left
  pack $frame.top.l2  -side right
  pack $frame.top.b1  -side right

#  pack forget $frame.top.l1
#  place $frame.top.l1 -in $frame.top  -relheight 0.9 -relx 0.1
#  pack forget $frame.top.b1 
#  place $frame.top.b1 -in $frame.top  -relheight 0.9 -relx 0.90

}
#----------------------------------------------------------------
proc SetToggleTitle { arrayname def_proc0 c1 title } {
#----------------------------------------------------------------
#d_sum Reset the title for a toggle frame
#d_arg arrayname Name of array
#d_arg def_proc0 Name of procedure which defines the content of one 'row'
#d_arg c1 The 'row' number for the toggle frame
#d_arg title New title for the toggle frame

  upvar #0 $arrayname array
# Assume there is only one instance of a toggle frame
  append def_proc $def_proc0 _ 0
  set frame $array([Indxv FRAME_$def_proc $c1])
  if { ![winfo exists $frame ] } { return 0 }
  $frame.top.l1 configure -text $title
  return 1
}


#-------------------------------------------------------------------------------
proc update_subframe_display { arrayname def_proc counter } {
#-------------------------------------------------------------------------------
#d_sum Update the visibility of a toggle frame.
#d_desc The visibility is dependent on the (FRAME_TOGGLE_....) parameter which \
is controlled by the checkbutton on toggle frame title line.
#d_arg arrayname Name of array
#d_arg def_proc Name of procedure which defines the content of one 'row'
#d_arg counter  The 'row' number

  upvar #0 $arrayname array

  set status $array(FRAME_TOGGLE_[subst $def_proc],$counter)
  set frame $array(FRAME_[subst $def_proc],$counter)
#  puts "update_subframe_display $status $frame"

  if { $status == "open" } {
    pack $frame.body -side top
  } else {
    pack forget $frame.body
  }
  update_main_scroll $frame
}

#-------------------------------------------------------------------
proc CreateExtendingFrame { indexVar0 def_proc0 message \
            add_text indexed_parameters args } {
#-------------------------------------------------------------------
#d_arg indexVar Name of array element which is the counter for the number of open toggle frames.
#d_arg def_proc0 Name of procedure which defines the content of one 'row'
#d_arg message The message line associated with the 'Add whatever' button
#d_arg add_text Text to appear in the  'Add whatever' button
#d_arg indexed_parameters A list of all of the parameters which are \
referenced in the def_proc0 procedure
#d_opt0 -depend dependent_frame
#d_opt1 The name of the defining procedure for another \
extending frame widget which is incremented and edited in sync with the \
'master' widget.
#d_opt0 -child child_frame
#d_opt1 The name of the defining procedure for another toggle frame \
or extending frame widget which is nested within this 'master' widget.
#d_opt0 -noadd
#d_opt1 Do not draw the Edit menu button and increment button for this widget.  \This implies that this widget is dependent on another 'master' widget.
#d_opt0 -edit_proc edit_procedure
#d_opt1 When the user increments or edits the rows in the widget call the \
procedure edit_procedure.  This procedure should be defined in the \
taskname.tcl file.

  set arrayname [ GetSystemVar frame_array ]
  upvar #0 $arrayname array

  set indexVar $indexVar0
  set del_text ""
  set noaddline 0
  set ndep 0
  set depframes ""
  set edit_proc ""
  set children ""
  set counter 0

#  puts "CreateExtendingFrame $def_proc0"
  set nargs [llength $args]
  set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n ] \
    dependent {
       incr ndep
       incr n; lappend depframes "[lindex $args $n]"
    } child {
       incr n; lappend children [lindex $args $n]
    } edit {
       incr n; lappend edit_proc [lindex $args $n]
    } noadd {
       set noaddline 1
    } delete {
       incr n; set del_text [lindex $args $n ]
    } counter {
       incr n; set counter  [lindex $args $n ]
    }
    incr n
  }

  OpenSubFrame top_frame
 
  append def_proc $def_proc0 _ $counter

  set array(XF_EDIT_$def_proc) ""
  set array(XF_SELECT_$def_proc) ""
  set array(XF_COMLINE_$def_proc) ""

  if { $counter <= 1 } {
    set array(CHILD_$def_proc0) $children
    foreach child $children {
      set array(PARENT_$child) $def_proc0
    }
    if {$noaddline} {
      set array(N_DEPFRAMES_$def_proc0) -1
      set array(DEPFRAMES_$def_proc0)  ""
    } else {
      set array(N_DEPFRAMES_$def_proc0) $ndep
      set array(DEPFRAMES_$def_proc0) $depframes
    }

    set array(XF_INDEX_$def_proc0) $indexVar
    set array(EDIT_PROC_$def_proc0) $edit_proc
    set array(FRAME_TYPE_$def_proc0) extending
    set array(FRAME_TITLE_$def_proc0) ""
    set array(HELP_$def_proc0) [GetSystemVar frame_program_help]
    set array(VARS_$def_proc0) $indexed_parameters
  }

  if { $counter > 0 } {append indexVar , $counter }

  OpenSubFrame frame

# Add a dummy line so when all other lines are deleted this one
# will determine the size of the remaining space (ie small)

  frame $frame.dummy -height 1
  pack $frame.dummy -side top

  set array(FRAME_$def_proc) $frame

  if { $array(N_DEPFRAMES_$def_proc0) >= 0 \
       && $counter == 0 && $array($indexVar) > 0 } {
#    puts "append UPDATE_SCRIPTS $def_proc0"
    append array(UPDATE_SCRIPTS) \
    "update_extendingframe $def_proc0 $counter $arrayname $indexVar \
		0 $array($indexVar) 0\n"
  }

  CloseSubFrame

  if { $noaddline == 0 } {
    set remo_text "Remove last line"
    create_addline_command line $message $indexVar \
	update_extendingframe0 $def_proc0 $counter $add_text 1 
    set array(XF_COMLINE_$def_proc) $line
  }

  CloseSubFrame

}

#-------------------------------------------------------------------
proc UpdateExtendingFrame { def_proc0 counter arrayname increment } {
#-------------------------------------------------------------------
#d_sum Explicit programmer command to add or remove lines from an \
extending frame
#d_desc This is called after the programmer has explicitly changed the \
data for an extending frame; for example after reading a file and loading \
default data.  Note that the programmer is responsible for ensuring that \
the data is consistent - particularly that all parameters are set for every \
new line to be added. BUT the value of the index variable should NOT \
be updated.
#d_arg def_proc0 Name of procedure which defines the content of one 'row'
#d_arg counter For child frames: the frame number of the parent
#d_arg arrayname The name of the array
#d_arg increment The increment to the index variable (i.e. the number of \
lines to be added or deleted).
  upvar #0 $arrayname array

  set indexVar  $array(XF_INDEX_$def_proc0)
  if { $counter == 0   } {
    update_extendingframe $def_proc0 $counter $arrayname $indexVar \
        $array($indexVar) $increment 1
  } else {
    update_extendingframe $def_proc0 $counter $arrayname [subst $indexVar],$counter \
        $array([subst $indexVar],$counter) $increment 1
  }
}

#-------------------------------------------------------------------
proc update_extendingframe0 { def_proc0 counter arrayname indexVar \
                increment update_scroll } {
#-------------------------------------------------------------------
  upvar #0 $arrayname array

  update_extendingframe $def_proc0 $counter $arrayname $indexVar \
	$array($indexVar) $increment $update_scroll
}
#-------------------------------------------------------------------
proc update_extendingframe { def_proc0 counter arrayname indexVar \
	current increment update_scroll } {
#-------------------------------------------------------------------
  upvar #0 $arrayname array
# Update an extending frame - should only get here if increment> 0
# so basically need to call append_extend_frame

# This procedure ought to become dedundant with remaining functionality
# put into append_extend_frame

# Trap for bad values of current
  if { [catch { expr {$current} }] } {
    # Non-numerical value
    set type [GetType $arrayname $indexVar]
    if { ![regexp "^_positiveint" $type] } {
      puts "update_extendingframe: indexVar $indexVar has bad type $type"
    }
  }

  append def_proc $def_proc0 _ $counter
  set maxlines [GetTypeInfo $arrayname $indexVar max ]
  set minlines [GetTypeInfo $arrayname $indexVar min ]
  set nlines [max $minlines [min $maxlines [expr {$current + $increment}]]]

  set frame $array(FRAME_$def_proc)
  SetSystemVar frame_program_help $array(HELP_$def_proc0)
#  puts "update_extendingframe $def_proc0 $current $increment"

# If the 'new' frame index is same as the current frame then do nothing

  if { $increment < 0 } {
    Report 2 "WARNING update-extending frame called with increment $increment"
    if { $current <= $minlines } { return }
    for { set i $increment } { $i < 0 } { incr i } {
      delete_frame $arrayname $def_proc0 $counter
    }

  } elseif { $increment > 0 } {

    if { $current >= $maxlines } { return }
# If necessary create the next instance of the subframe
    for { set c1 [expr {$current +1} ] } \
		{ $c1 <= $nlines } { incr c1 } {
      append_extend_frame $arrayname $def_proc0 $counter $c1
    }
  }
  if { $array(N_DEPFRAMES_$def_proc0) > 0 } {
    foreach dep_proc0 $array(DEPFRAMES_$def_proc0) {
        if {[regexp extending $array(FRAME_TYPE_$dep_proc0)]}  {
          update_extendingframe $dep_proc0 $counter $arrayname $indexVar \
                $current $increment $update_scroll
        } else {
          update_toggleframe $dep_proc0 $counter $arrayname $indexVar \
                $current $increment $update_scroll
        }
    }
  }

  if {$array(N_DEPFRAMES_$def_proc0) >= 0 } { 
    set array($indexVar) $nlines
    SetSystemVar block_scroll_update 0
    if { $update_scroll } { 
      update_main_scroll $frame 
    }
  }
  # If there is a user defined procedure to run after editing then run it now
  if { $array(EDIT_PROC_$def_proc0) != "" } {
    if { [info exists array(PARENT_$def_proc0)] } {
      GetIndx $indexVar root c1 c2
      eval "$array(EDIT_PROC_$def_proc0) $arrayname $c1 $array($indexVar)"
    } else {
      eval "$array(EDIT_PROC_$def_proc0) $arrayname $array($indexVar)"
    }
  }
#  puts "def_proc $def_proc indexVar $array($indexVar)"
}

#----------------------------------------------------------------------------
proc set_open_frame { frame arrayname args } {
#----------------------------------------------------------------------------
#d_sum Save information on the currently open frame (i.e. the one \
currently being drawn) to the systemvar array.
#d_desc  This is used by CreateLine and other general widget drawing procedures.#d_arg frame Tk id of currently open frame
#d_arg arrayname The name of the array

  SetSystemVar frame_array $arrayname
  SetSystemVar parent [winfo toplevel $frame]
  SetSystemVar open_frame $frame
}

#----------------------------------------------------------------------
proc create_addline_command { lineVar message c1 command def_proc0 counter \
   add_text  ifedit } {
#---------------------------------------------------------------------------
#d_sum Draw the Edit menubutton and the increment button for toggle frames \
and extending frames.
#d_arg lineVar Return the Tk id for the line
#d_arg message The message line to be associated with the increment button
#d_arg indexVar The name of the element containing the number of\
 toggle/extending frame created.
#d_arg command The appropriate command to update i.e. update_extendingframe0 or update_toggleframe0
#d_arg def_proc0 Name of procedure which defines the content of one 'row'
#d_arg counter For child frames the frame number of the parent
#d_arg add_text The text which appears on the increment button
#d_arg ifedit Logical value 0/1 which indicates if the 'Edit' menu should have \the usual edit functions (or if =0, will just have 'Delete Last Line' option).

  upvar $lineVar line
  global configure

  set arrayname [ GetSystemVar frame_array ]
  upvar #0 $arrayname array
  append def_proc $def_proc0 _ $counter

  if { $ifedit } {
    CreateLine line \
	message $message \
        button  $add_text
    pack forget $line.b1

    frame $line.b2
    pack $line.b1 $line.b2 -side right

    menubutton $line.b2.edit \
	  -text "Edit list" \
          -indicatoron 1 -relief raised \
          -width 18 \
	  -background $configure(COLOUR_PALE) \
	  -font $configure(FONT_REGULAR) \
          -menu $line.b2.edit.m
    pack $line.b2.edit -side right

    button $line.b2.quit -text "Quit Edit" \
	-relief raised \
	-width 18  \
        -font $configure(FONT_REGULAR) \
	-background $configure(COLOUR_PALE) \
	-command "exframe_select quit $arrayname $def_proc0 $counter"

    bind $line.b2.quit <Return> "exframe_select quit $arrayname $def_proc0 $counter"

   SetMessage $arrayname $line.b2.quit "Abort the edit"
   SetMessage $arrayname $line.b2.edit "Remove or copy a line"

    $line.b1 configure -command \
        "$command $def_proc0 $counter $arrayname $c1 1 1" \
	-background $configure(COLOUR_PALE)

    bind $line.b1 <Return> "$command $def_proc0 $counter $arrayname $c1 1 1"

    menu $line.b2.edit.m -tearoff 0 \
	-font $configure(FONT_REGULAR)

    $line.b2.edit.m add command -label "Delete last item" \
	-font $configure(FONT_REGULAR) \
	-command "SetSystemVar block_scroll_update 1
		delete_frame $arrayname $def_proc0 $counter
                SetSystemVar block_scroll_update 0
		update_main_scroll $array(FRAME_$def_proc)"

    $line.b2.edit.m add command -label "Delete selected item" \
	-font $configure(FONT_REGULAR) \
	-command "exframe_select delete $arrayname $def_proc0 $counter"

    $line.b2.edit.m add command -label "Copy selected item" \
	-font $configure(FONT_REGULAR) \
	-command "exframe_select copy $arrayname $def_proc0 $counter"


  } else {

    CreateLine line \
        message $message \
        button  $add_text \
	button "Delete last item" 
    pack forget $line.b1; pack forget $line.b2
    pack $line.b1 $line.b2 -side right

    $line.b1 configure -command \
        "$command $def_proc0 $counter $arrayname $c1 1 1 " \
	-background $configure(COLOUR_PALE)

    $line.b2 configure -command \
        "delete_frame $arrayname $def_proc0 $counter" \
        -background $configure(COLOUR_PALE)

  }

  # Label for displaying help text next to the buttons
  # when selecting for copy or delete operations
  frame $line.l1 -background black
  label $line.l1.padding -padx 5
  label $line.l1.msg 
  $line.l1.msg config \
	  -text {} \
	  -font $configure(FONT_SMALL) \
	  -background $configure(COLOUR_BACKGROUND) \
	  -padx 2
  pack $line.l1.padding $line.l1 -side right

  return
}

#--------------------------------------------------------------------------
proc exframe_select { mode arrayname def_proc0 counter} {
#--------------------------------------------------------------------------
#d_sum Update the edit menu button after the user has selected a row for editing
#d_desc The menu options and the message line are updated when the user \
deletes or copies rows within the toggle or extending frames.
#d_arg mode The edit mode: quit/delete/copy
#d_arg arrayname Name of array
#d_arg def_proc0 Name of procedure which defines the content of one 'row'
#d_arg counter For child frames the frame number of the parent

  global system
  upvar #0 $arrayname array
  append def_proc $def_proc0 _ $counter
#  puts "exframe_select $mode def_proc $def_proc"
  if { [catch {set line $array(XF_COMLINE_$def_proc)}] || \
		![winfo exists $line] } {
    puts "ERROR in exframe_select:line does not exist"
    return
  }
  ##puts "Cursor = [. config -cursor]"
  if {[regexp quit $mode ]} {
    pack forget $line.b2.quit
    $line.l1.msg config -text ""
    pack forget $line.l1.msg
    pack $line.b2.edit -side right
    set_message $arrayname "" -unblock
    set array(XF_EDIT_$def_proc) ""
    set array(XF_SELECT_$def_proc) ""
  } else {
# If we are enabling an edit then disable any previously enabled one
# But beware window/array could have beed closed/unset
    if { $system(EXFRAME_EDIT_OPEN) != "" } {
      set dp $system(EXFRAME_EDIT_OPEN)
      set system(EXFRAME_EDIT_OPEN) ""
      eval "exframe_select quit $arrayname $dp"
    }
    pack forget $line.b2.edit
    pack $line.b2.quit -side right
    pack $line.l1.msg -side right
    set array(XF_EDIT_$def_proc) $mode
    set array(XF_SELECT_$def_proc) ""
    if { [regexp delete $mode ] } {
      set help_text "Use RIGHT mouse button to click on a widget in the line to delete"
      set_message $arrayname "$help_text" -block
      $line.l1.msg config -text "$help_text"
    } else {
      set help_text "Use RIGHT mouse button to click on a widget in the line to copy"
      set_message $arrayname "$help_text" -block
      $line.l1.msg config -text "$help_text"
    }
    set system(EXFRAME_EDIT_OPEN) "$def_proc0 $counter"
    set system(EXFRAME_EDIT_ARRAY) $arrayname
  }
}

#-------------------------------------------------------------------------
proc exframe_edit { arrayname def_proc0 counter c1 args } {
#-------------------------------------------------------------------------
#d_sum Handle mouse click tied to editing extending frames
#d_desc  User has clicked right mouse in a widget in an extending frame. If \
they are in edit mode  then $array(XF_EDIT_$def_proc) specifies the edit mode.
#d_arg arrayname Name of data array
#d_arg def_proc0 Procedure name and name for this frame
#d_arg counter For child frames the frame number of the parent
#d_arg c1 The number of the selected row
#d_opt0 -parent parent_def_proc
#d_opt1 For child frame the name of the procedure drawing the parent frame
#d_opt0 -before
#d_opt1 Insert before the selected row
 
  upvar #0 $arrayname array
  append def_proc $def_proc0 _ $counter
  set indexVar $array(XF_INDEX_$def_proc0)
  if { $counter > 0 } { append indexVar , $counter }
  set p_def_proc ""
  set before 0
#  puts "exframe_edit $def_proc0 $counter $c1"
  set n 0; set nargs [llength $args]
  while { $n <= $nargs } {
    switch -regexp -- [lindex $args $n] \
    parent {
      incr n; set p_def_proc [lindex $args $n]
    } before  {
      set before 1
    }
    incr n
  }

# Line for help text
  if { [catch {set line $array(XF_COMLINE_$def_proc)}] || \
		![winfo exists $line] } {
    puts "ERROR in exframe_select:line does not exist"
    return
  }

# User has clicked in frame with right mouse button but they may
# not be trying to edit

  if { $array(XF_EDIT_$def_proc) == "" } { 

# The extending frame is not currently being edited - test if it's 
# parent toggle/extending frame is being edited
    if { $p_def_proc != "" } { 
      if { $before } {
        exframe_edit $arrayname $p_def_proc 0 $counter -before
      } else {
        exframe_edit $arrayname $p_def_proc 0 $counter
      }
    }
    return

# DELETING A SELECTED LINE

  } elseif {[regexp delete $array(XF_EDIT_$def_proc)]} {
     SetSystemVar block_scroll_update 1
     delete_frame $arrayname $def_proc0 $counter $c1
     SetSystemVar block_scroll_update 0
     update_main_scroll $array(FRAME_$def_proc)
     exframe_select quit $arrayname $def_proc0 $counter

# COPYING 

  } elseif {[regexp copy $array(XF_EDIT_$def_proc)]} {

# This is first line user has selected so just save its id and prompt 
# for a second pick

    if { $array(XF_SELECT_$def_proc) == "" } {
      set array(XF_SELECT_$def_proc) $c1
      set_message $arrayname \
        "Click RIGHT mouse button to insert below line, SHIFT- RIGHT mouse to insert above" -block
      $line.l1.msg config -text "RIGHT mouse button inserts below a line, SHIFT-RIGHT inserts above"

    } else { 
# Now we have two lines selected so do the copy
# Draw a new frame 

      if { $array(FRAME_TYPE_$def_proc0) == "extending" } {
        append_extend_frame $arrayname $def_proc0  $counter
      } else {
        append_toggle_frame $arrayname $def_proc0  $counter
      }
# Draw any dependent frames

      if { $array(N_DEPFRAMES_$def_proc0) > 0 } {
         foreach dep_proc0 $array(DEPFRAMES_$def_proc0) {
           if {[regexp extending  $array(FRAME_TYPE_$dep_proc0)]} {
             append_extend_frame $arrayname $dep_proc0 $counter
           } else {
             append_toggle_frame $arrayname $dep_proc0 $counter
           }
        }
      }
# Copy parameters
      set to $c1; if { !$before } { incr to }
      copy_frame $arrayname $def_proc0 $counter $array(XF_SELECT_$def_proc) $to
      if { $array(N_DEPFRAMES_$def_proc0) > 0 } {
        foreach dep_proc0 $array(DEPFRAMES_$def_proc0) {
          copy_frame $arrayname $dep_proc0 $counter $array(XF_SELECT_$def_proc) $to
        }
      }

# Increment the line index and draw to screen
      incr array($indexVar)
      SetSystemVar block_scroll_update 0
      update_main_scroll $array(FRAME_$def_proc)
      exframe_select quit $arrayname $def_proc0 $counter
    }
  }
# If there is a user defined procedure to run after editing then run it now"
  if { $array(EDIT_PROC_$def_proc0) != "" } {
    if { [info exists array(PARENT_$def_proc0)] } {
      GetIndx $indexVar root c1 c2
      eval "$array(EDIT_PROC_$def_proc0) $arrayname $c1 $array($indexVar)"
    } else {
      eval "$array(EDIT_PROC_$def_proc0) $arrayname $array($indexVar)"
    }
  }
}

#--------------------------------------------------------------------------
proc delete_frame { arrayname def_proc0 counter { dframe {} } } {
#--------------------------------------------------------------------------
#d_sum Delete a frame
#d_desc In practice the graphical object corresponding to the highest number \
frame is deleted.  The data is shuffled up to overwrite the data in the \
frame selected for deletion.
#d_arg arrayname Name of array
#d_arg def_proc0 Name of procedure which defines the content of one 'row'
#d_arg counter For child frames the frame number of the parent
#d_arg dframe The number of the frame to be deleted

  upvar #0 $arrayname array
  append def_proc $def_proc0 _ $counter
  set indexVar $array(XF_INDEX_$def_proc0)
  if { $counter > 0 } { append indexVar , $counter }
  set nlines $array($indexVar)
  if { $nlines <=  [GetTypeInfo $arrayname $indexVar min ] } { return }
  if { $dframe == "" } { set dframe $nlines }

  delete_frame_data $arrayname $def_proc0 $counter $dframe

# Destroy the last graphical frame (and all it's decendents)
  SetSystemVar block_scroll_update 1
# Remember the first child frame is a dummy
  set w [lindex [winfo children $array(FRAME_$def_proc)] $nlines ]
  if { [winfo exists $w] } { destroy $w }

# If there is user defined procedure to handle editing then call
# it now
  set undo_proc undo_$def_proc0
  if {[ regexp $undo_proc [info procs "$undo_proc"]]} {
    eval "$undo_proc $arrayname [expr {$nlines - 1}] " }

# Unset the parameters so they don't reappear if user extends 
# the frame in future

  unset_child_indexed_params $arrayname $def_proc0 $counter $nlines
  if { $counter == 0 } { 
    UnsetIndexedParam $arrayname $array(VARS_$def_proc0) $nlines
  } else {
    UnsetIndexedParam $arrayname $array(VARS_$def_proc0) $counter $nlines
  }

# Now repeat the process for any dependent frames 
# (good thing recursion works!)
  if { $array(N_DEPFRAMES_$def_proc0) > 0 } {
   foreach dep_proc0 $array(DEPFRAMES_$def_proc0) {
     delete_frame $arrayname $dep_proc0 $counter $dframe
   }
  }

# If this is the 'master' frame (cf a dependent) then
# update the index parameter
  if {$array(N_DEPFRAMES_$def_proc0) >= 0 } {
    set array($indexVar) [expr {$nlines - 1}]
  }

# If there is a user defined procedure to run after editing then run it now
  if { $array(EDIT_PROC_$def_proc0) != "" } {
    if { [info exists array(PARENT_$def_proc0)] } {
      GetIndx $indexVar root c1 c2
      eval "$array(EDIT_PROC_$def_proc0) $arrayname $c1 $array($indexVar)"
    } else {
      eval "$array(EDIT_PROC_$def_proc0) $arrayname $array($indexVar)"
    }
  }

}

#--------------------------------------------------------------------
proc delete_frame_data { arrayname def_proc0 counter dframe } {
#--------------------------------------------------------------------
#d_sum Delete the data when a frame is deleted
#d_arg arrayname Name of array
#d_arg def_proc0 Name of procedure which defines the content of one 'row'
#d_arg counter For child frames the frame number of the parent
#d_arg dframe The number of the frame to be deleted

  upvar #0 $arrayname array
  append def_proc $def_proc0 _ $counter
  set indexVar $array(XF_INDEX_$def_proc0)
  if { $counter > 0 } { append indexVar , $counter }
  set nlines $array($indexVar)
  if { $nlines <= 0 } { return }

# Shuffle up data from any child frames
  if { $dframe < $nlines } {
    foreach child0 $array(CHILD_$def_proc0) {
      for { set c1 $dframe } { $c1 < $nlines } { incr c1 } {
        copy_frame_c1 $arrayname $child0 [expr {$c1 +1}] $c1
      }
    }
# Shuffle up the data for the present frame level
    foreach ele $array(VARS_$def_proc0) {
      for { set i $dframe } { $i < $nlines } { incr i } {
        set ii [expr {$i + 1}]
        if { $counter != 0 } {
          set array([Indxv $ele $counter $i]) \
                $array([Indxv $ele $counter $ii])
        } else {
          set array([Indxv $ele $i]) $array([Indxv $ele $ii])
        }
      }
    }
  }
}

#--------------------------------------------------------------------
proc unset_child_indexed_params { arrayname def_proc0 counter c1 } {
#--------------------------------------------------------------------
#d_sum Unset the array variables for all the child frames of  def_proc
#d_desc This procedure used to cleanup the child frames when the user \
has opted to delete the parent extending frame
#d_arg arrayname Name of array
#d_arg def_proc0 Name of procedure which defines the content of one 'row'
#d_arg counter For child frames the frame number of the parent
#d_arg c1 The number of rows in the child frame
  upvar #0 $arrayname array
#  puts "unset_child_indexed_params $def_proc0 $counter $c1"
  append def_proc $def_proc0 $counter
  foreach child_proc0 $array(CHILD_$def_proc0) {
    set child_indexVar  $array(XF_INDEX_$child_proc0)
    append child_indexVar , $c1
    if { $array($child_indexVar) > 0 } {
      for { set i 1 } { $i <= $array($child_indexVar)} { incr i } {
        UnsetIndexedParam $arrayname $array(VARS_$child_proc0) $c1 $i
      }
    }
  }
}

#--------------------------------------------------------------------------
proc copy_frame { arrayname def_proc0 counter fromin toin } {
#--------------------------------------------------------------------------
#d_sum Copy the data in one row to another row
#d_arg arrayname Name of the data array
#d_arg def_proc0 Name of procedure which defines the content of one 'row'
#d_arg counter The id of the parent frame if this is a child frame
#d_arg fromin The source row
#d_arg toin The target row (If = 0 append the data to the end of the extending frame)
#
  upvar #0 $arrayname array
  append def_proc $def_proc0 _ $counter
  set indexVar $array(XF_INDEX_$def_proc0)
  if { $counter > 0 } { append indexVar , $counter }
  set nlines $array($indexVar)
  set from $fromin
  set to $toin
#  puts "copy_frame def_proc $def_proc from $from to $to nlines $nlines"
#  puts "CHILD $array(CHILD_$def_proc0)"

# If the new line is being inserted into the list then all the lines
# after it need to be shuffled down one

  if { $to <= $nlines  } {
    foreach child0 $array(CHILD_$def_proc0) {
      for { set c1 $nlines } { $c1 >= $to } { incr c1 -1 } {
        copy_frame_c1 $arrayname $child0 $c1 [expr {$c1 +1}]
      }
    }
    if { $counter != 0 } {
      foreach ele $array(VARS_$def_proc0) {
        for { set i $nlines } { $i >= $to } { incr i -1 } {
          set array([Indxv $ele $counter [expr {$i +1}] ]) \
		$array([Indxv $ele $counter $i])
        }
      }
    } else {
      foreach ele $array(VARS_$def_proc0) {
        for { set i $nlines } { $i >= $to } { incr i -1 } {
          set array([Indxv $ele [expr {$i+1}] ]) $array([Indxv $ele $i])
        }
      }
    }
  }

# Set the values of the new line by copying from the 'from' line
# Beware if the from line has been shuffled down!

  if { $from >= $to } { incr from }

  foreach child $array(CHILD_$def_proc0) {
    copy_frame_c1 $arrayname $child $from $to
  }
  if { $counter != 0 } {
    foreach ele $array(VARS_$def_proc0) {
      set array([Indxv $ele $counter $to]) \
		$array([Indxv $ele $counter $from])
    }
  } else {
    foreach ele $array(VARS_$def_proc0) {
      set array([Indxv $ele $to]) $array([Indxv $ele $from])
    }
  }
}

#--------------------------------------------------------------------------
proc copy_frame_c1 { arrayname def_proc0 from to } {
#--------------------------------------------------------------------------
#d_sum Copy parameters of a child frame from one parent (from) to another (to)
#d_arg arrayname Name of array
#d_arg def_proc0 Name of procedure which defines the content of one 'row'
#d_arg from Copy data from this parent frame
#d_arg to Copy data to this parent frame

  upvar #0 $arrayname array
#  puts "copy_frame_c1 $def_proc0 $from $to"
  append def_proc_from $def_proc0 _ $from
  append def_proc_to $def_proc0 _ $to
  append indexVarfrom $array(XF_INDEX_$def_proc0) , $from
  append indexVarto $array(XF_INDEX_$def_proc0) , $to
  set increment [ expr {$array($indexVarfrom) - $array($indexVarto)}]

  if  {$increment != 0} {
    update_extendingframe $def_proc0 $to $arrayname $indexVarto \
        $array($indexVarto) $increment 0
  }

  if { $array($indexVarfrom) > 0 } {
    foreach ele $array(VARS_$def_proc0) {
      for { set i 1 } { $i <=  $array($indexVarfrom) } { incr i } {
        set array([Indxv $ele $to $i]) $array([Indxv $ele $from $i])
      }
    }
  }
}

#--------------------------------------------------------------------------
proc append_extend_frame { arrayname def_proc0 counter { c1In {}} } {
#--------------------------------------------------------------------------
#d_sum Add another frame to the bottom of extending frame
#d_arg arrayname Name of array
#d_arg def_proc0 Name of procedure which defines the content of one 'row'
#d_arg counter For child frames the frame number of the parent
#d_arg c1in Optional parameter.  If set is the number for the new frame to \
be draw.  Other the new frame number is the current number of frames plus 1

  upvar #0 $arrayname array
  append def_proc $def_proc0 _ $counter
  set indexVar $array(XF_INDEX_$def_proc0)
  if { $counter > 0 } {append indexVar , $counter }
  if { $c1In == "" } {
    set c1 [expr {$array($indexVar) + 1} ]
  } else {
    set c1 $c1In
  }

#  puts "append_extend_frame def_proc $def_proc counter $counter c1 $c1"
  if { $counter == 0 } {
    SetIndexedParam $arrayname $array(VARS_$def_proc0) {} $c1
    set current_index_counter $c1
  } else {
    SetIndexedParam $arrayname $array(VARS_$def_proc0) {} $counter $c1
    set current_index_counter [subst $counter]_$c1
    set parent $array(PARENT_$def_proc0)
  }

# Run the procedure $def_proc which defines the frame

  SetSystemVar block_scroll_update 1
  set frame $array(FRAME_$def_proc)
  set_open_frame $frame $arrayname
  OpenSubFrame subframe
  SetSystemVar current_index_counter $current_index_counter
  if  { $counter > 0 } {
    eval "$def_proc0 $arrayname $c1 $counter"
  } else {
    eval "$def_proc0 $arrayname $c1"
  }
  SetSystemVar current_index_counter ""

# add the editing bindings to each widget in the frame

  set cmd "+exframe_edit $arrayname $def_proc0 $counter $c1"
  if { $counter != 0 } {
    append cmd " -parent $parent"
  }
  foreach w1 [winfo children $subframe] {
    foreach w2 [winfo child $w1] {
      bind $w2 <Shift-Button-3> "$cmd -before"
      bind $w2 <Button-3> "$cmd"
    }
  }
  CloseSubFrame

# Call append_frame_c1 which will draw any child frames
  append_frame_c1 $arrayname $def_proc0 $c1
}

#----------------------------------------------------------------------
proc append_toggle_frame { arrayname def_proc0 counter { c1In {} } } {
#----------------------------------------------------------------------
#d_sum Add another frame to the bottom of a toggle frame widget
#d_arg arrayname Name of array
#d_arg def_proc0 Name of procedure which defines the content of one 'row'
#d_arg counter For child frames the frame number of the parent
#d_arg c1in Optional parameter.  If set is the number for the new frame to \
be draw.  Other the new frame number is the current number of frames plus 1


  upvar #0 $arrayname array
  append def_proc $def_proc0 _ $counter
  set indexVar $array(XF_INDEX_$def_proc0)
  set anchor $array(FRAME_ANCHOR_$def_proc0)
  set frame $array(FRAME_$def_proc)
  if { $c1In == "" } {
    set c1 [expr {$array($indexVar) + 1} ]
  } else {
    set c1 $c1In
  }

  SetIndexedParam $arrayname $array(VARS_$def_proc0) {} $c1
  set current_index_counter $c1
  SetSystemVar block_scroll_update 1

# Create the title line and toggle button for the subframe
  set_open_frame $frame $arrayname
  OpenSubFrame subframe -appearance "-relief ridge -borderwidth 1"
  create_toggle_button $subframe $arrayname $def_proc0 $counter $c1

# Run the procedure $def_proc which defines the subframe body
  frame  $subframe.body
  # The pack arguments here define where the subframe contents
  # are positioned relative to other elements
  pack  $subframe.body -side top -anchor $anchor
  set_open_frame $subframe.body $arrayname
  SetSystemVar current_index_counter $current_index_counter
  eval "$def_proc0 $arrayname $c1"
  SetSystemVar current_index_counter ""

# Officially close the subframe
  set_open_frame $frame $arrayname
  CloseSubFrame

# Add the edit selection bindings to each widget in the subframe
  bind_edit_select $subframe.body $arrayname $def_proc0 $counter $c1

# Draw any child frames
  append_frame_c1 $arrayname $def_proc0 $c1
}

#--------------------------------------------------------------
proc append_frame_c1 { arrayname def_proc0 counter } {
#--------------------------------------------------------------
#d_sum Draw child frames when called from append_*_frame
#d_arg arrayname Name of array
#d_arg def_proc0 Name of procedure which defines the content of one 'row'

  upvar #0 $arrayname array
  if { [llength $array(CHILD_$def_proc0)] > 0 } {
    foreach child_proc0 $array(CHILD_$def_proc0) {
      set child_indexVar  $array(XF_INDEX_$child_proc0)
      append child_indexVar , $counter
      update_extendingframe $child_proc0 $counter $arrayname $child_indexVar \
                0 $array($child_indexVar) 0
    }
  }
}

#--------------------------------------------------------------
proc bind_edit_select { f arrayname def_proc0 counter c1} {
#--------------------------------------------------------------
#d_sum Add the edit function right-mouse button bindings
#d_arg arrayname Name of array
#d_arg def_proc0 Name of procedure which defines the content of one 'row'
#d_arg counter The frame number of the parent
#d_arg c1 The frame number of the child extending frame

  append def_proc $def_proc0 _ $counter
  set children [winfo children $f ]
  set cmd  "+exframe_edit $arrayname $def_proc0 $counter $c1"
  if { [llength $children ] > 0 } {
    foreach child $children {
      if {[regexp {utton|Entry} [winfo class $child] ]} {
        bind $child <Shift-Button-3> "$cmd -before"
        bind $child <Button-3> "$cmd"
      } else {
        bind_edit_select $child $arrayname $def_proc0 $counter $c1
      }
    }
  }
}

#-------------------------------------------------------------------------
proc SetIndexedParam { arrayname varlist values c1 { c2 {} } } {
#-------------------------------------------------------------------------
#d_sum Assign values to a group of indexed elements with the same index
#d_desc This is called when an extra frame is added to an extending frame \
to initialise all the array elements in that frame.  If an array element 
#d_arg arrayname Name of data array
#d_arg varlist List of the root names for the array elements
#d_arg values List of values for the array elements.  Can be an empty string.
#d_arg c1 The first index for the elements
#d_arg c2 Optional. The second index for the elements
  upvar #0 $arrayname array
# Have we got a sensible list of input values to assign to the new variables?
  set ifinput 0
  if { [llength $values] == [llength $varlist] } { set ifinput 1 }

  set i -1
  foreach item $varlist { incr i
    eval "set element [Indxv $item $c1 $c2]"
# If the array element already exists then just reinitiallise the WIDGET 
# control parameter.  We are trusting that the widget does not actually 
# exists and that this array element is an untidy leftover from the user 
# having removed the frame and then reopened it.
    if { [ElementExists $arrayname $element] } {
      set array(WIDGET_$element) ""
    } else {
      if { $ifinput } {
         set array($element) [lindex $values $i ]
      } else {
        set array($element) $array([Indxv $item 0 ])
      }
    }
  }
}

#-----------------------------------------------------------------------
proc UnsetIndexedParam { arrayname varlist c1 { c2  "" } } {
#-----------------------------------------------------------------------
#d_sum Unset the elements of array for a parameter, its data type and widget
#d_arg arrayname Name of data array
#d_arg varlist List of elements in array
#d_arg c1 The first index  number
#d_arg c2 The optional second index number

  upvar #0 $arrayname array
# use eval here so create command which does not have c2 if c2==""
#  puts "UnsetIndexedParam $c1 $c2 "
  foreach item $varlist {
    eval "set ele [Indxv $item $c1 $c2 ]"
    catch "unset array($ele)"
    catch "unset array(_$ele)"
    catch "unset array(WIDGET_$ele)"
  }
}

#d_index_title Using the BLT Table Widget
#d_intro_title Using the BLT Table Widget
#d_intro These functions require using bltwish rather than wish.  They \
draw a table with edit menu button and increment button similar to \
extending frames but are more efficient at handling larger amounts of data. \
The data for the table must be in a separate array - see the description of \
CreateTable

#--------------------------------------------------------------
proc CreateTable { arrayname table_id dataVar data_spec f args } {
#--------------------------------------------------------------
#d_sum Create a table using the BLT table function
#d_desc This widget is created very differently to the extending frames \
and toggle frames but (for a consistent interface) has similar edit menu \
button and increment button at the bottom of the table.  The table is designed \to have column titles but each element of the table is an entry widget and \
additional labels are not supported.
#d_desc See the table by the side of the Monomer Library Sketcher window or \
the Edit Restraints in PDB window for examples.
#d_arg arrayname Name of array
#d_arg table_id A unique identifying name for the table
#d_arg dataVar Array containing the tabulated data displayed in the table \
The data array is a 2-dimensional array with element names $column_name,$ir \
where $column_name is the name of the column and $ir is the row number.
#d_arg data_spec A specification of the table - a list with one list  \
item for each column.  Each list item is also a list with the items: \
  0 - name of data in the column \
  1 - column title \
  2 - data type if not represented as a simple entry widget \
  3 - width of entry widget (number of characters) \
  4 - default initial value \
  5 - message line describing the data in the column
#d_arg f The Tk id of the frame in which to create the table
#d_opt0 -scroll
#d_opt1 Put the table inside a scrolling frame with a vertical scroll bar.
#d_opt0 -noedit
#d_opt1 Do not draw the edit menu button and increment button under the table
#d_opt0 -nolabel
#d_opt1 Do not draw column titles
#d_opt0 -row row_procedure
#d_opt1 Specify the procedure to draw one row of the table

upvar #0 $arrayname array
upvar #0 $dataVar data

  set array(TABLE_$table_id,DATA) $dataVar
  set array(TABLE_$table_id,FRAME) $f
  set array(TABLE_$table_id,SPEC) $data_spec
  set array(TABLE_$table_id,ROW) {}
  set array(TABLE_$table_id,EDIT) 1
  set array(TABLE_$table_id,COUNTER) ""
  set array(TABLE_$table_id,SCROLL) window
  set scroll 0
  set ifedit 1
  set iflabel 1
  set n 0; set nargs [llength $args]
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    scroll {
      set array(TABLE_$table_id,SCROLL) table
      set scroll 1
    } row  {
      incr n; set array(TABLE_$table_id,ROW) [lindex $args $n]
    } noedit {
      set array(TABLE_$table_id,EDIT) 0
      set ifedit 0
    } nolabel {
      set iflabel 0 
    } counter {
      incr n; set array(TABLE_$table_id,COUNTER) [lindex $args $n]
    }
    incr n
  }

  if { $scroll } {
# Create scroll bar and canvas 
    grid rowconfigure $f 0 -weight 1
    if {$ifedit} { grid rowconfigure $f 1 -weight 0 }
    grid columnconfigure $f 0 -weight 1
    grid columnconfigure $f 1 -weight 0
    canvas $f.canvas \
            -yscrollcommand [list $f.vs set] -bd 0
    scrollbar $f.vs -orient vertical \
        -command [list $f.canvas yview]
    grid $f.canvas -row 0 -column 0 -sticky nswe
    grid $f.vs -row 0 -column 1 -sticky nswe
    frame $f.canvas.contents
    grid rowconfigure $f.canvas.contents 0 -weight 1
    grid columnconfigure $f.canvas.contents 0 -weight 1
    set t [frame $f.canvas.contents.table]
  } elseif { $ifedit } {
    grid rowconfigure $f 0 -weight 1
    grid rowconfigure $f 1 -weight 0
    set t [frame $f.t]
  } else {
    set t [frame $f.t]
  }
  grid $t -row 0 -column 0 -sticky nswe
  if { $ifedit } {
# extra frame below the table frame for the edit buttons
    set e [frame $f.edit]
    grid $e -row 1 -column 0 -sticky nswe
  }
  eval [GetSystemVar BLT_TABLE] $t

# put the table in th scrolable canvas
  if { $scroll } {
    $f.canvas create window 0 0 -anchor nw -window $f.canvas.contents}

  if { $ifedit } {
    table_edit_buttons $arrayname $table_id $e }

# Set up column titles
  if { $iflabel } { lappend column_title {} }
  foreach d $data_spec { lappend column_title [lindex $d 1] }
  CreateTableTitle $t $column_title

  set array(TABLE_$table_id,TABLE) $t
  return $t
}

#--------------------------------------------------------------
proc CreateTableTitle { t column_titles } {
#--------------------------------------------------------------
#d_sum Draw column titles in table
#d_arg t The Tk frame id for the table
#d_arg column_titles The list of column titles

  set cmd "[GetSystemVar BLT_TABLE] $t"
  set n -1;foreach lab $column_titles { incr n
    label $t.[subst $n]_0 -text "$lab"
    append cmd " $t.[subst $n]_0 0,$n"
  }
  eval $cmd
}

#--------------------------------------------------------------
proc table_edit_buttons { arrayname table_id frame } {
#--------------------------------------------------------------
#d_sum Draw the edit menu button and increment button under the table
#d_arg arrayname Name of array
#d_arg table_id A unique identifying name for the table
#d_arg frame  The Tk frame id for the table buttons frame

  global configure

  button $frame.b -text "Add Row" \
	-relief raised \
        -width 8 \
        -font $configure(FONT_REGULAR) \
        -background $configure(COLOUR_PALE) \
        -command "TableAddRow $arrayname $table_id end"

  SetMessage $arrayname $frame.b \
    "Append new row to the bottom of the table"

  menubutton $frame.mb \
          -text "Edit Table" \
          -indicatoron 1 -relief raised \
          -width 11 \
          -background $configure(COLOUR_PALE) \
          -font $configure(FONT_REGULAR) \
          -menu $frame.mb.m

  SetMessage $arrayname $frame.mb \
    "Add or delete rows from the table"

  pack $frame.b $frame.mb -side right

    menu $frame.mb.m -tearoff 0  \
        -font $configure(FONT_REGULAR)

  foreach item  [list \
   [list "Insert After Selected Row" "TableAddRow $arrayname $table_id query"] \
   [list "Delete Last Row" "TableDeleteRow $arrayname $table_id end"] \
   [list "Delete Selected Row" "TableDeleteRow $arrayname $table_id query" ] \
   [list "Copy Row" "TableAddRow $arrayname $table_id query copy" ] ] {
    $frame.mb.m add command -label [lindex $item 0] \
        -font $configure(FONT_REGULAR) \
        -command [lindex $item 1]
  }
  
  pack $frame.b -side right

}

#--------------------------------------------------------------
proc TableDrawRow { arrayname table_id ir } {
#--------------------------------------------------------------
#d_sum Draw one row of a table
#d_desc If the -row argument to CreateTable specified a procedure to draw \
a row then call that procedure with the arguments arrayname and ir (the row \
number).  Otherwise draw a default format row using the information on \
data type and entry widget width provided as argument to CreateTable.
#d_arg arrayname Name of array
#d_arg table_id A unique identifying name for the table
#d_arg ir The row number

  global configure
  global system
# Draw one row of a table
  upvar #0 $arrayname array
  upvar #0 $array(TABLE_$table_id,DATA) data

  if { $array(TABLE_$table_id,ROW) != "" } {
    eval "$array(TABLE_$table_id,ROW) $arrayname $ir"

  } else {

  set dataVar $array(TABLE_$table_id,DATA)
  set data_spec $array(TABLE_$table_id,SPEC)
  set t $array(TABLE_$table_id,TABLE)
  set cmd "[GetSystemVar BLT_TABLE] $t"

  set w [label $t.ll_$ir -text $ir \
	-width 2 \
	-font $configure(FONT_REGULAR) \
	-justify left ]
  append cmd " $w $ir,0"

  set ic 1; foreach d $data_spec {
    switch [lindex $d 2] \
    logical {
      set w [CreateCheckbutton $t.[subst $ic]_$ir  \
	-variable [subst $dataVar]([lindex $d 0],$ir) \
	-relief flat \
        -indicatoron 1 ]
    } default {
      set w [ entry $t.[subst $ic]_$ir \
	-textvariable [subst $dataVar]([lindex $d 0],$ir) \
        -font $configure(FONT_REGULAR) \
        -width [lindex $d 3] ]
    }
    SetMessage $arrayname $w [lindex $d 5]
    append cmd " $w $ir,$ic"
    incr ic
  }
  eval $cmd

  }
}

#--------------------------------------------------------------
proc TableAddRow { arrayname table_id row {mode {}}  } {
#--------------------------------------------------------------
#d_sum Add an extra row to the table to support the edit functions
#d_arg arrayname Name of array
#d_arg table_id A unique identifying name for the table
#d_arg row Add new row after row number row.  \
row = end => append to end of table \
row = query => query user
#d_arg mode Optional. If mode is copy then initialise the new row with \
data determined by the row argument: \
  row = query => query user \
  row = [list copy_from_row copy_to_row]

  upvar #0 $arrayname array
  upvar #0 $array(TABLE_$table_id,DATA) data

  set ifcopy [regexp copy $mode]
  set irc 0

  set t $array(TABLE_$table_id,TABLE)
  set nrow [get_table_extent $t]

# Figure out which row we are inserting after
  if { $ifcopy } {
    switch $row \
    query {
      DefineVariable $arrayname T_C_ROW _text {}
      DefineVariable $arrayname T_A_ROW _text {}
      if { ![InputParamDialog "Add After Row Number" Edit $arrayname \
              [list [list T_C_ROW "Copy row number:" ] \
                    [list T_A_ROW "Insert after row number:" ]] ]  } { return 0 }
          if { [catch { expr {int ( $array(T_A_ROW) )} } ir  ] || \
          $ir < 0  || $ir > $nrow || \
          [catch { expr {int ( $array(T_C_ROW) )} } irc  ] || \
          $irc < 1  || $ir > $nrow } { return 0 }
    } default {
      set irc [lindex $row 0]
      set ir [lindex $row 1]
    }
  } else {
    switch $row \
    end {
      set ir $nrow
    } query {
      DefineVariable $arrayname T_A_ROW _text {}
      if { ![InputParamDialog "Add After Row Number" Edit $arrayname \
              [list [list T_A_ROW "Insert after row number:" ]] ]  || \
          [catch { expr {int ( $array(T_A_ROW) )} } ir  ] || \
          $ir < 0  || $ir > $nrow } { return 0 }
    } default {
      set ir $row
    }
  }

#  puts "TableAddRow row $row nrow $nrow ir $ir ifcopy $ifcopy irc $irc"

# Extract names of data items from the data_spec
  foreach column $array(TABLE_$table_id,SPEC) {
        lappend data_names [lindex $column 0] }

# Make a copy of the 'to copy' row
  if { $ifcopy } {
    foreach column $array(TABLE_$table_id,SPEC) {
      set savdata([lindex $column 0]) $data([lindex $column 0],$irc) }
  }

# Shuffle data down the array - ir is row we are inserting after
  if { $ir < $nrow } {
    for { set n $nrow } { $n > $ir } { incr n -1} {
      set nn [expr {$n +1}]
      foreach name $data_names {
        set data($name,$nn) $data($name,$n)
      }
    }
  }

# Initialise data in the inserted row
  if { $ifcopy } {
    foreach column $array(TABLE_$table_id,SPEC) {
      set data([lindex $column 0],[expr {$ir + 1}]) \
	  $savdata([lindex $column 0]) }
  } else {
    foreach column $array(TABLE_$table_id,SPEC) {
      set data([lindex $column 0],[expr {$ir + 1}]) \
		[lindex $column 4] }
  }

# Increment the counter for number of rows 
  if { [set c $array(TABLE_$table_id,COUNTER)] != "" } {
    incr data($c) 
  }

# Draw the new, end row 
  TableDrawRow $arrayname $table_id [expr {$nrow + 1}]

  switch $array(TABLE_$table_id,SCROLL) \
  window {
    update_main_scroll $array(WINDOW)
  } table {
    TableUpdateScroll $array(TABLE_$table_id,FRAME)
  }

}

#--------------------------------------------------------------
proc TableDeleteRow { arrayname table_id { ir {}} } {
#--------------------------------------------------------------
#d_sum Delete a row from the table
#d_arg arrayname Name of array
#d_arg table_id A unique identifying name for the table
#d_arg ir The number of the row to delete or \
  ir = end => delete last row \
  ir = query => query user

  upvar #0 $arrayname array
  upvar #0 $array(TABLE_$table_id,DATA) data


  set t $array(TABLE_$table_id,TABLE)
  set nrow [get_table_extent $t]

# Figure out which row we are deleting
  switch $ir \
  end {
    set ir $nrow
  } query {
    DefineVariable $arrayname T_D_ROW _text {}
    if { ![InputParamDialog "Delete Row Number" Edit $arrayname \
	      [list [list T_D_ROW "Delete row number:" ]] ]  || \
          [catch { expr {int ( $array(T_D_ROW) )} } ir  ] || \
	  $ir < 1  || $ir > $nrow } { return 0 }
  }

# Extract names of data items from the data_spec
  foreach column $array(TABLE_$table_id,SPEC) { 
	lappend data_names [lindex $column 0] }

# Shuffle data up the array
  if { $ir < $nrow } {
    for { set n $ir } { $n < $nrow } { incr n } {
      set nn [expr {$n +1}]
      foreach name $data_names {
        set data([subst $name],$n) $data([subst $name],$nn)
      }
    }
  }

# Increment the counter for number of rows
  if { [set c $array(TABLE_$table_id,COUNTER)] != "" } {
    incr data($c) -1
  }

# Remove the last row of widgets from the table
# Delete the last row of data from array
  
  catch "destroy $t.ll_$nrow"
  set ic 0; foreach name $data_names {  incr ic
#    [GetSystemVar BLT_TABLE] forget $t.[subst $ic]_$nrow
    destroy $t.[subst $ic]_$nrow
    catch {unset data([subst $name],$nrow) }
  }

  switch $array(TABLE_$table_id,SCROLL) \
  window {
    update_main_scroll $array(WINDOW)
  } table {
    TableUpdateScroll $array(TABLE_$table_id,FRAME)
  }


}

#--------------------------------------------------------------
proc TableDeleteContents { arrayname table_id } {
#-------------------------------------------------------------
#d_sum Delete the entire contents of the table but keep the column titles.
#d_arg arrayname Name of array
#d_arg table_id A unique identifying name for the table

  upvar #0 $arrayname array
  global system
# Delete all of the data row in a table - leave to title row

  set t $array(TABLE_$table_id,TABLE)
# blt::table search command seems to require different format for different versions
  if { ![ElementExists system TK_VERSION] || $system(TK_VERSION) < 8.1 } {
    set wlist [[GetSystemVar BLT_TABLE] search $t]
  } else {
    set wlist [[GetSystemVar BLT_TABLE] search $t -span 0,[TableGetExtent $arrayname $table_id]]
  }
#  puts "TK_VERSION $system(TK_VERSION) wlist $wlist"
  foreach w $wlist {
    set cell [split [lindex [split $w .] end] _]
    if { [lindex $cell 1] > 0 } {
      destroy $w
    }
  }
}

#-------------------------------------------------------------
proc TableGetExtent { arrayname table_id } {
#-------------------------------------------------------------
#d_sum Return the Cnumber of rows in the table
#d_arg arrayname Name of array
#d_arg table_id A unique identifying name for the table

  upvar #0 $arrayname array
  set t $array(TABLE_$table_id,TABLE)
  return  [get_table_extent $t]
}


#--------------------------------------------------------------
proc get_table_extent { t } {
#--------------------------------------------------------------
#d_sum Return the Cnumber of rows in the table
#d_arg t The Tk id for the table
  global system
# scan the names of windows in the table to find the max row number
  set irmax 0
# blt::table search command seems to require different format for different versions
  if { ![ElementExists system TK_VERSION] || $system(TK_VERSION) < 8.1 } {
    set wlist [[GetSystemVar BLT_TABLE] search $t]
  } else {
    set wlist [[GetSystemVar BLT_TABLE] search $t -start 0,0 ]
  }
  foreach w $wlist {
    set cell [split [lindex [split $w .] end] _]
    set irmax [max $irmax [lindex $cell 1] ]
  }
  return $irmax
}

#--------------------------------------------------------------
proc TableUpdateScroll { f } {
#--------------------------------------------------------------
#d_sum Update the scrollable area of the table.
#d_desc Must be called after adding or deleting a row.
#d_arg f The id of the Tk frame containing the table

  update idletasks

  set height [winfo reqheight $f.canvas.contents]
  set width [winfo reqwidth $f.canvas.contents]
  set canvas_height [winfo height $f.canvas]

  $f.canvas configure \
	-width $width \
	-height $canvas_height \
	-scrollregion [list 0 0 $width $height]
}
