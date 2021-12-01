#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - util_windows.tcl
#
#
#
# General Utility Windows
#
#====================================================================

#CCP4i_cvs_Id $Id$

#d_index_title General Utility Windows (src/util_windows.tcl)
#d_intro_title General Utility Windows
#d_intro  These are a collection of 'super-widgets' to display stuff \
like warning messages and for some simple user input. \
 Most of these widgets block input \
to all other ccp4i windows until the user has closed this widget.  Programmers\
 should be careful when using these that they do not create two blocking \
windows simultaneously - it usually freezes the interface.  The WarningMessage \
function does test if a warning message window is already open and appends to \
it if possible.
#d_intro  The Tcl 'grab' command is used to grab the input focus for the \
window.  The use of this command does seem to cause occasional error messages \
when running ccp4i - but the interface usually seems to continue without \
problems.  Once the window has grabbed the focus then the Tcl code is blocked \
by a vwait command - ccp4i will not process the user input until \
the user clicks an option to close the window.  The 'close' command will \
call a procedure such as warning_message_command which releases the 'grab' \
and sets the vwait parameter (e.g. warning_message_flag) which allows \
the main procedure (eg. WarningMessage) to continue and exit.

#------------------------------------------------------------------------
proc WarningMessage { message args } {
#------------------------------------------------------------------------
#d_sum Output a 'warning' message to the user - the one default action \
is 'Dismiss' to close the window.
#d_arg message Text string to be displayed.
#d_opt0 -help help_file
#d_opt1 Link a help button in the warning message window to this html file.
#d_opt0 -title title
#d_opt1 A title for the warning message window
#d_opt0 -nostop
#d_opt1 Do not block the procedure waiting for user input - this is probably \
not a good idea
#d_opt0 -transient delay
#d_opt1 If there is no user input close the window after a given delay \
(delay in seconds)
#d_opt0 -button button_text
#d_opt1 Set the text of the 'Dismiss' button to button_text
#d_opt0 -command command
#d_opt1 When the user clicks the 'Dismiss' button then issue the command
#d_opt0 -centre window
#d_opt1 Centre the WarningMessage on the named window (otherwise centring \
is relative to the screen)
#d_opt0 -nograb
#d_opt1 Disable grabbing of the input focus for the window
#d_opt0 -image imagefile
#d_opt1 Display an image at the top of the WarningMessage window
#d_opt0 -font fontname
#d_opt1 Display the message text using the specified font
#d_opt0 -color color
#d_opt1 Display the message text using the specified color

  global configure
  global warning_message_flag

  set title "Warning"
  set w ".warning"
  set help_file ""
  set button_text "Dismiss"
  set stop 1
  set transient 0
  set command "warning_message_command chooseopt dismiss"
  set centre ""
  set nograb 0
  set image_file ""
  set font_name ""
  set color ""

  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    set comd [lindex $args $n]
    if { $comd == "-help" } {
      incr n; set help_file [lindex $args $n]
    } elseif { $comd == "-title" } {
      incr n; set title [lindex $args $n]
    } elseif { $comd == "-nostop" } {
      set stop 0
    } elseif { $comd == "-transient" } {
      set transient 1
    } elseif { $comd == "-button" } {
      incr n; set button_text [lindex $args $n]
    } elseif { $comd == "-command" } {
      incr n; append command "; [lindex $args $n]"
    } elseif { $comd == "-centre" } {
      incr n; set centre [lindex $args $n]
    } elseif { $comd == "-nograb" } {
      set nograp 1
    } elseif { $comd == "-image" } {
      incr n; set image_file [lindex $args $n]
    } elseif { $comd == "-font" } {
      incr n; set font_name [lindex $args $n]
    } elseif { $comd == "-color" } {
      incr n; set color [lindex $args $n]
    }
    incr n
  }

# If there is already a warning message up then just add in the extra message

  set n 0
  while {[winfo exists $w.main.canvas.contents.text_$n]} { incr n }

  if { $n == 0 } {
    OpenWindow $w  $title $title -help $help_file
    CreateFrame $w chooseopt -noscroll
    CreateButton $w dismiss $button_text "$command"
    # Define behaviour which should occur when the window manager is used
    # to delete the window
    wm protocol $w WM_DELETE_WINDOW "$command"
  }

  # Set up the font
  if { $font_name == "" } {
    # Default font
    if { [string length $message ] > 200 } {
      set font  $configure(FONT_SMALL)
    } else {
      set font $configure(FONT_REGULAR)
    }
  } else {
    # User defined font
    # See the Tk font command for information on font families etc
    set font $font_name
  }

  # Add image if specified
  if { [file exists $image_file] } {    
    # Guess the image type
    switch -regexp [file extension $image_file] {
	xbm|XBM {
          set image_type "bitmap"
        }
        gif|GIF|ppm|PPM|pgm|PGM {
          set image_type "photo"
        }
        default {
          set image_type [file extension $image_file]
        }
    }  
    # Check that this is a usable type
    if { [lsearch [image types] $image_type] < 0 } {
      # Image type not supported
      Report 3 "WarningMessage: unsupported image type \"$image_type\""
    } else {
      # Make a new image?
      if { [catch \
	      { set image_name [image create $image_type -file $image_file] } \
	      errmsg] } {
        # Image creation failed
        Report 3 "WarningMessage: failed to make image \"$errmsg\""
      } else {
        # Display the image
        set limg [label $w.main.canvas.contents.image_$n -image $image_name]
        pack $limg -side top -fill x
      }
    }
    # End of block for adding image
  }

  set tw  [label $w.main.canvas.contents.text_$n   \
        -wraplength "15 c" \
        -justify left \
        -font $font \
        -text "$message" ]
  pack $tw -side top -fill x

  # Colour the text?
  if { $color != "" } {
    $tw configure -fg $color
  }
  update idletasks
  wm deiconify $w
  raise $w

  if { $n > 0 } { return }

  if { $centre != "" } {
    CentreWindow $w $centre
  } else {
    CentreWindow $w SCREEN
  }
  if { $nograb == 0 }  {
    catch "grab $w"
    add_modalDialog_safeguard $w
  }
  if { $stop } { 
    vwait warning_message_flag
  } elseif { $transient} {
    set delay [ expr {1000 *     \
     [ lindex $args [expr {[lsearch $args "-transient" ] + 1} ] ]} ]
    after $delay "$command"
  }

}

#---------------------------------------------------------------------
proc warning_message_command { arrayname returntext } {
#---------------------------------------------------------------------
#d_sum Handler for exit button on the warning message window
#d_arg arrayname Name of data array
#d_arg returntext The command from the action button
  upvar #0 $arrayname array
  global warning_message_flag
  catch "grab release $array(WINDOW)"
  CloseWindow $arrayname
  update idletasks
  set warning_message_flag $returntext
}


#--------------------------------------------------------------------
proc ChooseOptionDialog { title icon message options args } {
#--------------------------------------------------------------------
#d_sum Give user multiple choice  with one button per option
#d_desc The window contains a message text and any number of buttons (4 is \
probably the reasonable maximum) - clicking a button will make the user's \
choice and close the dialog box. The text from the button clicked by the user \
is returned by the procedure.
#d_desc The items in the input list of options are displayed right to left.
#d_arg title Title for the window
#d_arg icon Name for the window icon
#d_arg message Text message to appear in the window
#d_arg  options A list of the text strings to appear in the buttons.
#d_opt0 help help_file
#d_opt1 Link a help button in the warning message window to this html file.
#d_opt0 parent parent_window_array
#d_opt1 The arrayname of the parent task interface.  \
If that task interface window \
is closed by the user then this window will also be closed automatically.
#d_opt0 -default n
#d_opt1 Set the  n'th item in the list of options as the default
#d_opt0 mode mode
#d_opt1 button or listbox (default button)  The options can be listed \
in a listbox (not certain this is functional)
#d_opt0 -height height
#d_opt1 Height of listbox (number of lines)
#d_opt0 -width width
#d_opt1 Width of listbox (number of characters)

  global configure
  global moduledef
  global choose_option_flag

  set w ".chooseoption"
  set help ""
  set parent ""
  set default 0
  set mode buttons
  set height 10
  set width 40
  set centre ""

  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    help {
      incr n; set help [lindex $args $n]
    } parent {
      incr n; set parent [lindex $args $n]
    } default {
      incr n; set default [expr {[lindex $args $n] + 1} ]
    } mode {
      incr n; set mode [lindex $args $n]
    } height {
      incr n; set height [lindex $args $n]
    } width {
      incr n; set width [lindex $args $n]
    } centre {
       incr n; set centre  [lindex $args $n]
    }
    incr n
  }

  set cmd "set status \[OpenWindow $w \"$title\" \"$icon\" -resizeable"
  if { $help != "" } { append cmd " -help $help" }
  if { $parent != "" } { append cmd " -parent $parent" }
  append cmd "\]"
  eval "$cmd"
  if { !$status } { return }

  # Define behaviour which should occur when the window manager is used
  # to delete the window
  wm protocol $w WM_DELETE_WINDOW \
       "choose_opt_command chooseopt \"[lindex $options $default]\""

  wm withdraw $w
  CreateFrame $w chooseopt -noscroll

  if { [string length $message ] > 200 } {
    set font  $configure(FONT_SMALL)
  } else {
    set font $configure(FONT_REGULAR)
  }

  set tw [label $w.main.canvas.contents.text   \
	-wraplength "15 c" \
	-justify left \
	-font $font \
	-text "$message" ]
  pack $tw -side top -fill x


  if {[regexp butt $mode ]} {
    set n 0
    foreach item $options {
      incr n
      if { $n == $default } { set def "-default" } else { set def "" }
      CreateButton $w b$n "$item" \
  	"choose_opt_command chooseopt \"$item\"" $def
    }
  } else {
    listbox $tw.list \
        -yscrollcommand [list $tw.scroll set] \
        -font $configure(FONT_REGULAR) \
        -height $height -width $width
    scrollbar $tw.scroll -command [list $tw.list yview]
    pack $tw.list -side left -fill both -expand true -anchor e
    pack $tw.scroll -side left -fill y -anchor e
    foreach item $options {
      $tw.list insert end "$item"
    }
    bind $tw.list <Button-1> "choose_opt_sel chooseopt %W %y"
    CreateButton $w quit Quit "choose_opt_command chooseopt {}"
  }

  wm deiconify $w 
  raise $w
  update idletasks
  if { $centre != "" } { CentreWindow $w $centre }
  catch "grab set $w"
  add_modalDialog_safeguard $w
  vwait  choose_option_flag
  return $choose_option_flag
}

#---------------------------------------------------------------------
proc choose_opt_command { arrayname returntext } {
#---------------------------------------------------------------------
#d_sum Handler for action buttons on the choose option window
#d_arg arrayname Name of data array
#d_arg returntext The command from the action button

  upvar #0 $arrayname array
  global choose_option_flag
  catch "grab release $array(WINDOW)"
  CloseWindow $arrayname
  update idletasks
  set choose_option_flag $returntext
}

#---------------------------------------------------------------------
proc choose_opt_sel { arrayname lb y } {
#---------------------------------------------------------------------
#d_sum handler for listbox selection in ChooseOptionDialog listbox mode
#d_arg arrayname Name of data array
#d_arg lb Tk id of listbox widget
#d_arg y Position of mouse pick in listbox
  upvar #0 $arrayname array
  global choose_option_flag
  set window [winfo toplevel $lb]
  set choose_option_flag [$lb get [$lb nearest $y]]
  catch "grab release $window"
  CloseWindow $arrayname
  update idletasks
}


#---------------------------------------------------------------------
proc InputParamDialog { title icon arrayname entry_list args } {
#---------------------------------------------------------------------
#d_sum Present user dialog box with simple list of variables to edit
#d_desc The dialog box is laid out with one variable per line. Each line has  \
a label to define the parameter and a input widget for the user to enter \
a value or edit the default value.  The input default parameters should \
be defined in a global array (usually this will be a task interface array) \
and the output values are returned in the array.
#d_desc The user has the options to exit the dialog box with 'OK' (the \
procedure returns 1)  or 'Quit' (the procedure returns 0 and returns the \
variables in the array are unaltered).
#d_arg title Title for the window
#d_arg icon Name for the window icon
#d_arg arrayname Name of array containing the input/output parameter values
#d_arg entry_list A list with one item for each variable  - each item is a \
list: the name of the element in the array, the text to appear in the label, \
the parameter type (optional, default is _text).

  global system
  global choose_option_flag
  global configure
  upvar #0 $arrayname array
  global input_param

  set w .input_param
  set centre ""

  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -- [lindex $args $n] \
    -centre {
      incr n; set centre   [lindex $args $n]
    }
    incr n
  }

#  Open window with quit or  OK buttons

  OpenWindow $w  $title $icon

  # Define behaviour which should occur when the window manager is used
  # to delete the window
  wm protocol $w WM_DELETE_WINDOW "choose_opt_command input_param quit"

  CreateFrame  $w input_param -noscroll

  CreateButton $w dismiss Quit "choose_opt_command input_param quit"
  CreateButton $w accept OK "choose_opt_command input_param OK" -default

# Draw label and entry box for every element in list entry_list
# Assume data type text unless specified

  OpenFolder protocol

  foreach entry $entry_list {
    set var [lindex $entry 0]
    set text [lindex $entry 1 ]
    set value ""
    set type _text
    if { [llength $entry ] > 2 } { 
      set type [lindex $entry 2 ] 
    }  else {
      set type text
    }
    DefineVariable input_param $var $type $array($var)

    CreateLine line \
      label "$text"

    if { [regexp logical $type ] } {
      CreateCheckbutton $line.w -variable input_param($var) \
		-font $configure(FONT_REGULAR)
    } else {
      set width [GetTypeInfo $arrayname $var nchar]
      if { $width == {} } { set width 8 }
      set field_width [expr {2 + $width}]
      entry $line.w -textvariable input_param($var) \
    	-width $field_width \
	-font $configure(FONT_REGULAR)
    }
    pack $line.w -side right
  }

  update idletasks
  if { $centre != "" } { CentreWindow $w $centre }
  catch "grab $w"
  vwait  choose_option_flag
  if { $choose_option_flag == "quit" } { 
    unset input_param
    return 0 
  } else { 
    foreach entry $entry_list {
      set var [lindex $entry 0]
      set array($var) $input_param($var)
    }
    unset input_param
    return 1 
  }
}

#---------------------------------------------------------------
proc EditComFile { comlineVar file } {
#---------------------------------------------------------------
#d_sum Display a program command script and command line for user to edit
#d_desc This procedure is run as part of the ccp4i graphical main process \
if this process receives a request from a run process which is running a\
 script.    The command line is passed to (and returned from) this \
procedure explicitly but the command script is in a file which is read \
and then overwritten by the updated script if the user edits the script.
#d_arg comlineVar Input/Output The text of the program command line
#d_arg file Name of the file containing the file script

  upvar $comlineVar comline

  global edit_com_file_status

  if { $file != "" } {
    if { [OpenFile $file fd r ] != 1 } {
      Report 3 "ERROR opeing file $file"
      return 0
    }
    set newText [read $fd]
    CloseFile $fd
    set fileOK 1
  } else { 
    set newText " "
    set fileOK 0
  }

  # Use this rather than "file root" to avoid problems if the filename
  # contains multiple dots, e.g. foo.bar.mtz (rather than foobar.mtz)
  if { ![regexp -- "^(\[^.\]*)\.*" [file tail "$file"] m fileroot] } {
    set fileroot [file tail "$file"]
  }
  set w .edit_$fileroot
  if { [winfo exists $w ] } { return 0 }
  toplevel $w

  # Define behaviour which should occur when the window manager is used
  # to delete the window
  wm protocol $w WM_DELETE_WINDOW "handle_edit_com_file continue"

  if { [wm title $w] != "View Command File" } {
    wm title $w "View Command File"
    wm positionfrom $w user
    wm iconname $w "Edit"
    set wbuttons [frame $w.buttons -relief raised]
    set title1 [ label $w.title1 -text "Command Line" ]
    set wcom [frame  $w.com]
    set title2 [ label $w.title2 -text "Script from File $file" ]
    set wmain [frame  $w.main]

    grid $title1 -row 0 -column 0  -sticky we
    grid $wcom -row 1 -column 0  -sticky nswe
    grid $title2 -row 2 -column 0  -sticky we
    grid $wmain -row 3 -column 0  -sticky nswe
    grid $wbuttons -row 4 -column 0  -sticky we

    grid columnconfigure $w 0  -weight 1
    grid rowconfigure $w 0   -weight 0
    grid rowconfigure $w 1   -weight 1
    grid rowconfigure $w 2   -weight 0
    grid rowconfigure $w 3   -weight 1
    grid rowconfigure $w 4   -weight 0

    button $wbuttons.action -text "Continue"  \
     -command "handle_edit_com_file edit "
    pack $wbuttons.action  -side left -expand 1

# Set continue as the default
    $wbuttons.action configure -borderwidth 4
 
    button $wbuttons.dismiss -text "Abort" \
     -command "handle_edit_com_file abort"
    pack $wbuttons.dismiss  -side right -expand 1

   button $wbuttons.continue -text "Continue without display" \
     -command "handle_edit_com_file continue"
   pack $wbuttons.continue -side right -expand 1


    set comframe [text $wcom.text \
        -relief sunken \
        -setgrid true \
        -yscrollcommand "$wcom.scroll set" \
        -wrap word \
        -height 4 \
        -width 60 ]
    scrollbar $wcom.scroll -relief flat  \
            -command "$comframe yview" -orient vertical

    grid $wcom.text -row 0 -column 0 -sticky nswe
    grid $wcom.scroll -row 0 -column 1 -sticky ns
    grid columnconfigure $wcom 0 -weight 1
    grid columnconfigure $wcom 1 -weight 0
    grid rowconfigure $wcom 0 -weight 1

#    pack $wcom.scroll -side right -fill y
#    pack $comframe -side left -expand true -fill both


    set textframe [text $wmain.text \
	-relief sunken \
	-setgrid true \
	-yscrollcommand "$wmain.scroll set" \
	-wrap word \
	-height 20 \
	-width 60 ]
    scrollbar $wmain.scroll -relief flat  \
            -command "$textframe yview" -orient vertical

    grid $wmain.text -row 0 -column 0 -sticky nswe
    grid $wmain.scroll -row 0 -column 1 -sticky ns
    grid columnconfigure $wmain 0 -weight 1
    grid columnconfigure $wmain 1 -weight 0
    grid rowconfigure $wmain 0 -weight 1


#    pack $wmain.scroll -side right -fill y
#    pack $textframe -side left -expand true -fill both

  } else {
    set comframe ".com.text"
    set textframe ".main.text"
    set title ".title2"
    $comframe delete 1.0 end
    $textframe delete 1.0 end
    $title configure -text "Script from File $file"
  }

  wm deiconify $w
  $comframe insert end $comline
  $textframe insert end $newText

  vwait  edit_com_file_status

  if { $fileOK && [regexp {edit|cont} $edit_com_file_status] } {
    set newText [ $textframe get 1.0 end ]
    set comline [ string trim [ $comframe get 1.0 end ] ]
    WriteFile $file $newText -overwrite
  } 
  destroy $w
  return [expr {-1 + [lsearch [list abort continue edit] $edit_com_file_status]}]
}

#-----------------------------------------------------------------
proc handle_edit_com_file { mode  } {
#-----------------------------------------------------------------
#d_sum Handler for action button in EditComFile
#d_desc The EditComFile script will continue from the vwait command \
after edit_com_file_status is changed.
#d_arg mode The action mode - dependent on which button was clicked
  global edit_com_file_status
  set edit_com_file_status $mode
}

#d_intro_title Code for Uniqueify, Harvesting and HKL Rejects
#d_intro The same interface to either Uniqueify of Harvesting \
appear in several task windows so they are defined in the following \
procedures. For examples see scalepack2mtz (Uniqueify and HKL rejects) \
and truncate \
(harvesting).  The def file and com files for the task also need \
to be modified, for example, for harvesting:
#d_intro The taskname.def file for the task should contain the line
#d_intro @ [FileJoin [GetEnvPath CCP4I_TOP] tasks harvest.def]
#d_intro to initialise parameters defined in harvest.def. And the \
taskname.com file should contain
#d_intro AT { [FileJoin [GetEnvPath CCP4I_TOP] templates harvest.com ] }
#d_intro which will interpret the parameters into the program script.

#-----------------------------------------------------------------
proc UniqueifyFrame1 { arrayname } {
#-----------------------------------------------------------------
#d_sum Uniqueify interface - a fragment of several task interfaces
#d_desc See scalepack2mtz for example of use
#d_arg arrayname Name of task interface array

  CreateLine line \
    message "Ensure unique reflect data for CCP4 asymm unit, add FreeR" \
    widget UNIQUEIFY -command "set_copy_freer $arrayname" \
    label "Ensure unique data & add FreeR column for" \
    widget UNIQUEIFY_FREERFRAC \
    label "fraction of data." \
    widget COPY_FREER \
    label "Copy FreeR from another MTZ" \
    toggle_display UNIQUEIFY open 1

  CreateLine line \
    message "Ensure unique reflect data for CCP4 asymm unit, add FreeR" \
    widget UNIQUEIFY -command "set_copy_freer $arrayname" \
    label "Ensure unique data & add FreeR column for" \
    widget UNIQUEIFY_FREERFRAC \
    label "fraction of data." \
    toggle_display UNIQUEIFY open 0

  CreateLine line \
    message "Extend reflection data to higher resolution" \
    widget UNIQUEIFY_EXTEND \
    label "Extend reflections to higher resolution:" \
    widget UNIQUEIFY_MAXRES \
    toggle_display UNIQUEIFY open 1

}

#-----------------------------------------------------------------
proc  UniqueifyFrame2 {} {
#-----------------------------------------------------------------
#d_sum Uniqueify interface - a fragment of several task interfaces
#d_desc See scalepack2mtz for example of use

  CreateInputFileLine line \
      "Enter input MTZ containing FreeR column" \
      "MTZ with FreeR" \
      COPY_FREER_MTZ DIR_COPY_FREER_MTZ \
      -setlabin COPY_FREER_LABEL { FREE FreeR FreeR_flag FreeRflag } \
      -toggle_display COPY_FREER open 1

  CreateLine line  \
        message "Use FreeR from an existing MTZ file" \
       help description \
       label "Copy FreeR data from " \
       widget COPY_FREER_LABEL  \
       toggle_display COPY_FREER open 1
}

#-------------------------------------------------------------------------
proc set_copy_freer { arrayname } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array
  if { !$array(UNIQUEIFY) }  { set array(COPY_FREER) 0 }
}


#-------------------------------------------------------------------------
proc SetHarvestParams { arrayname filename mode } {
#-------------------------------------------------------------------------
#d_sum Initialise parameters for tasks which interface to harvesting mechanism
#d_desc This is called at the beginning of **_task_window procedure \
(with mode=init) to initialise the harvest mode and PNAME if they \
are not already setor in the **_run procedure (with mode=run) to check \
the user entered values are consistent with MTZ contents.
#d_arg arrayname Name of data array
#d_arg filename Name of array element containing file name
#d_arg mode Mode, valid values init or run
  upvar #0 $arrayname array
  global preferences

  if { $filename == "" } {
    set file ""
  } else {
    set file [GetFullFileName0 $arrayname $filename]
  }

  switch -regexp -- $mode \
  init {
# Initialise the harvest mode and PNAME if they are not already set
# - they may be set already if the user is rerunning job
    if { ![ElementExists $arrayname HARVEST_MODE] ||
	  $array(HARVEST_MODE) == "" } {
      set array(HARVEST_MODE) $preferences(HARVEST_MODE)
      if { $file == "" } { set array(HARVEST_PNAME) [GetCurrentProject] }
      truncate_harvestnames $arrayname
    }
  } run {
    set array(HARVEST_PRIVATE) $preferences(HARVEST_PRIVATE)
    set array(HARVEST_RSIZE) $preferences(HARVEST_RSIZE)
    if { $file != "" &&
	[GetParamFromFile  MTZ $file  PNAME  pname] &&
	[GetParamFromFile  MTZ $file DNAME dname ] &&
        [StringSame $pname $array(HARVEST_PNAME)] &&
	[StringSame $dname $array(HARVEST_DNAME)] } {
        set array(HARVEST_INPUT_NAMES) 0
     } else {

      if { $array(HARVEST_PNAME) == "" } {
       set action [ ChooseOptionDialog "No harvest project name given" "No pname" \
    "It is highly recommended that you give a harvest project name. Do you want to abort this task run and enter the harvest project name before rerunning?" \
         [list "Continue" "Abort Run" ]  \
         -help [SearchPath HELP general harvesting.html] \
         -default 1 ]
       if { "$action" == "Abort Run" } { return 0 } 
      }

      if { $array(HARVEST_DNAME) == "" } {
       set action [ ChooseOptionDialog "No harvest dataset name given" "No dname" \
    "It is highly recommended that you give a harvest dataset name. Do you want to abort this task run and enter the harvest dataset name before rerunning?" \
         [list "Continue" "Abort Run" ]  \
         -help [SearchPath HELP general harvesting.html] \
         -default 1 ]
       if { "$action" == "Abort Run" } { return 0 } 
      }

      set array(HARVEST_INPUT_NAMES) 1
     }
  }

  return 1

}

#-------------------------------------------------------------------------
proc util_set_harvesthome { arrayname } {
#-------------------------------------------------------------------------
#d_sum Set the HARVESTHOME environmental variable
#d_desc This is called to set the harvesting directory to be either the project \
harvesting directory, or a central harvesting directory, as specified by the user
#d_arg arrayname Name of the data array
    upvar #0 $arrayname array

    global env

    if { $array(HARVEST_MODE) == "Create harvest file in project harvesting directory" } {
	set array(HARVESTHOME) [ GetDefaultDirPath ]
	set env(HARVESTHOME) [ GetDefaultDirPath ]
    } elseif { $array(HARVEST_MODE) == "Create harvest file in central harvesting directory" } {
	set array(HARVESTHOME) [ GetCentralDeposit ]
	set env(HARVESTHOME) [ GetCentralDeposit ]
    }
}
#-------------------------------------------------------------------------
proc util_fix_harvestnames { arrayname } {
#-------------------------------------------------------------------------
#d_sum Call RemoveMetaChars to ensure valid project/crystal/dataset names.
#d_desc The call to RemoveMetaChars replaces e.g. spaces with underscores.
#d_arg arrayname Name of the data array
    upvar #0 $arrayname array

  set array(HARVEST_PNAME) [RemoveMetaChars $array(HARVEST_PNAME)]
  set array(HARVEST_XNAME) [RemoveMetaChars $array(HARVEST_XNAME)]
  set array(HARVEST_DNAME) [RemoveMetaChars $array(HARVEST_DNAME)]
  truncate_harvestnames $arrayname

}
#-------------------------------------------------------------------------
proc truncate_harvestnames { arrayname } {
#-------------------------------------------------------------------------
#d_sumTruncates harvest names 
#d_desc Truncates harvest names to the length set by variable HARVEST_LENSTR \
as it currently necessary for Refmac (18/09/2012)
#d_arg arrayname Name of the data array
    upvar #0 $arrayname array

  if { [string length [array names array -exact HARVEST_LENSTR]] } {
     set last [expr $array(HARVEST_LENSTR) - 1 ]
#    puts "last $last"
     foreach x { PNAME XNAME DNAME } {
        if { [string length [array names array -exact HARVEST_$x]] } {
#          puts [array names array -exact HARVEST_$x]
           set array(HARVEST_$x) [string range $array(HARVEST_$x) 0 $last ]
#          puts "HARVEST_$x $array(HARVEST_$x)"
        }
     }
  }
}
#-------------------------------------------------------------------------
proc CreateHarvestLine { lineVar args } {
#-------------------------------------------------------------------------
#d_sum Draw the three line interface to dataset/harvesting commands
#d_arg lineVar Returned. The Tk line id for the final line.
#d_opt0 -noha
#d_opt1 do not draw the harvesting mode line
#d_opt0 -dnam
#d_opt1  always draw the pname/xname/dname lines (eg scalepack2mtz)

  upvar lineVar line
  set arrayname [ GetSystemVar frame_array ]
  upvar #0 $arrayname array

  if { [lsearch -regexp $args noharv ] < 0 } {

    CreateLine line \
      message "Select where to place harvest file, or to disable harvesting" \
      widget HARVEST_MODE -command "util_set_harvesthome $arrayname"

  }
# set initial value of HARVESTHOME
  util_set_harvesthome $arrayname

  if { [lsearch -regexp $args noha ] < 0 &&
       [lsearch -regexp $args dnam ] < 0 } {

    CreateLine line \
      help pname \
      message "Project name for Data Harvesting" \
      label "Harvest project name" \
      widget HARVEST_PNAME -oblig -command "util_fix_harvestnames $arrayname" \
      help dname \
      message "Dataset name for Data Harvesting" \
      label "and dataset name" \
      widget HARVEST_DNAME -oblig -command "util_fix_harvestnames $arrayname" \
      toggle_display HARVEST_MODE hide NOHARVEST

  } else {

    CreateLine line \
      help name \
      message "Crystal name as it will appear in the MTZ file" \
      label "Crystal " \
      widget HARVEST_XNAME -oblig -command "util_fix_harvestnames $arrayname" \
      help name \
      message "Project name as it will appear in the MTZ file" \
      label "belonging to Project " \
      widget HARVEST_PNAME -oblig -command "util_fix_harvestnames $arrayname"

    CreateLine line \
      help name \
      message "Dataset name as it will appear in the MTZ file" \
      label "Dataset name " \
      widget HARVEST_DNAME -oblig -command "util_fix_harvestnames $arrayname"

  }

}

#----------------------------------------------------------------------
proc UpdateHarvestMTZ { arrayname filename } {
#----------------------------------------------------------------------
#d_sum Fill in default project and dataset name when the user selects MTZ
#d_desc This command should be added as an argument to CreateInputFile \
command for the input MTZ file in form:
#d_desc -command "UpdateHarvestMTZ $arrayname HKLIN"
#d_arg arrayname Name of data array
#d_arg filename array element containing the name of the MTZ file
  upvar #0 $arrayname array

  SetParamFromFile PNAME $arrayname MTZ $filename HARVEST_PNAME
  SetParamFromFile XNAME $arrayname MTZ $filename HARVEST_XNAME
  SetParamFromFile DNAME $arrayname MTZ $filename HARVEST_DNAME
#  SetParamFromFile DNAMES $arrayname MTZ $filename HARVEST_DNAME_MENU

  if { $array(HARVEST_PNAME) == ""  } {
#    set array(DNAME_IN_MTZ) 0
    set array(HARVEST_PNAME) [GetCurrentProject]
    check_input $arrayname HARVEST_PNAME
  } else {
#    set array(DNAME_IN_MTZ) 1
  }
  truncate_harvestnames $arrayname
}

#-------------------------------------------------------------------------
proc HklRejects {  arrayname i } {
#-------------------------------------------------------------------------
#d_sum Define one line of extending frame for rejects in combat/scalepack2mtz/d*trek
#d_arg arrayname Name of task interface array
#d_arg i Counter for extending frame
  CreateLine line \
    message "Enter h,k,l for refection to be excluded from output file" \
    help "reject"   \
    label "Reject reflection(s) h" \
    widget REJECT1_H \
    label "k" \
    widget REJECT1_K \
    label "l" \
    widget REJECT1_L \
    label "   and h" \
    widget REJECT2_H \
    label "k" \
    widget REJECT2_K \
    label "l" \
    widget REJECT2_L
}

#--------------------------------------------------------------------------
proc CentreWindow {  w { parent {} } } { 
#--------------------------------------------------------------------------
  # Centre a window over parent window (parent) or if parent
  # is undefined in the centre of the screen
  # The window must have been drawn so that it has known geometry

  set wgeom [split [wm geometry $w] {x+}]
  
  if { $parent != "" && [winfo exists $parent] } {
    set pgeom  [split [wm geometry $parent] {x+}]
  } else {
    set pgeom [list [winfo screenwidth $w] [winfo screenheight $w] 0 0 ]
  }
  #puts "wgeom $wgeom pgeom $pgeom"

  set xx [expr {([lindex $pgeom 0]/2) + [lindex $pgeom 2] - \
                      ([lindex $wgeom 0]/2)} ]

  set yy [expr {([lindex $pgeom 1]/2) + [lindex $pgeom 3] - \
                      ([lindex $wgeom 1]/2)} ]

  #puts "xx $xx yy $yy"

  wm geometry $w "[lindex $wgeom 0]x[lindex $wgeom 1]+$xx+$yy"

}
