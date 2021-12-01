#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
#---------------------------------------------------------------------
# mapslicer_command.tcl
#
# Procedures for the interactive display in MapSlicer
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# mapslicer_mode
#
# Mode is either "section", "slab" or "harker"
# This procedure repacks the command display appropriately
#---------------------------------------------------------------------
proc mapslicer_mode { mode } {
#---------------------------------------------------------------------

  # Fetch the widget information
  set f [get_value WIDGET_COMMAND]
  set w [get_value WIDGET_MODE_BUTTON]

  # Update the text in the display to the new mode
  $w config -text $mode

  # Pack forget all the mode-specific widgets
  pack forget $f.section $f.slab $f.harker $f.axis $f.grey

  # Repack the mode-specific widgets
  switch -exact -- $mode {
      section {
        set_value MAPSLICER_MODE "SECTION"
        set_value SLAB_ON 0
        pack configure $f.axis $f.section $f.grey -after $f.mode -side top \
		-anchor nw -fill y
        jump_to_section_command [get_value WIDGET_SECTION]
      }
      slab {
        set_value MAPSLICER_MODE "SLAB"
        set_value SLAB_ON 1
        pack configure $f.axis $f.slab -after $f.mode -side top \
		-anchor nw -fill y
        jump_to_slab_command [get_value WIDGET_SLAB_START] \
		[get_value WIDGET_SLAB_DEPTH] [get_value WIDGET_SLAB_STEP] \
		-force
      }
      harker {
        set_value MAPSLICER_MODE "HARKER"
        set_value SLAB_ON 0
        pack configure $f.harker -after $f.mode -side top -anchor nw -fill y
        set_harker_command [get_value WIDGET_HARKER_SPACEGROUP] \
		[get_value WIDGET_HARKER_SECTION] [get_value WIDGET_HARKER_MENU]
      }
      mask {
	set_value MAPSLICER_MODE "MASK"
        set_value SLAB_ON 0
        pack configure $f.axis $f.section -after $f.mode -side top \
	    -anchor nw -fill y
        jump_to_section_command [get_value WIDGET_SECTION]
      }
  }

  # Update the display
  update_command_display
}

#---------------------------------------------------------------------
# change_axis_command
#
# Perform change of axis from the command display
#---------------------------------------------------------------------
proc change_axis_command { w axis } {
#---------------------------------------------------------------------
  change_axis $axis
  $w configure -text "$axis"
}

#---------------------------------------------------------------------
# change_greyscale_command
#
# Perform change of greyscale mode from the command display
#---------------------------------------------------------------------
proc change_greyscale_command { w } {
#---------------------------------------------------------------------
    global greyscale_status
    set_value GREYSCALE $greyscale_status
    redraw_contours
}

#---------------------------------------------------------------------
# jump_to_section_command
#
# Go to an arbitrary section specified in the command display
#---------------------------------------------------------------------
proc jump_to_section_command { w } {
#---------------------------------------------------------------------
  ##puts "Jump to section command"
  set new_section [string trim [$w get]]
  ##puts "New section = $new_section"

  # Validate
  if {![regexp -- "^-?(\[0-9\]*)$" $new_section]} {
    # Not a valid number
    ##puts "Not a valid section number!"
  } elseif { [section_is_in_limits $new_section [get_value AXIS]] != 0 } {
    # Section is not in range
    ##puts "Section number out of range!"
  } else {
    # Jump to the section
    set_value SECTION $new_section
    incr_section 0 [get_value AXIS]
  }
  # Update the display 
  $w delete 0 [string length [$w get]]
  $w insert 0 [get_value SECTION]
  return
}

#---------------------------------------------------------------------
# next_section_command
#
# Advance to the next section from the command display
#---------------------------------------------------------------------
proc next_section_command { w } {
#---------------------------------------------------------------------
  incr_section 1 [get_value AXIS]
  # Update the display 
  $w delete 0 [string length [$w get]]
  $w insert 0 [get_value SECTION]
  return
}

#---------------------------------------------------------------------
# prev_section_command
#
# Go to the previous section from the command display
#---------------------------------------------------------------------
proc prev_section_command { w } {
#---------------------------------------------------------------------
  incr_section -1 [get_value AXIS]
  # Update the display 
  $w delete 0 [string length [$w get]]
  $w insert 0 [get_value SECTION]
  return
}

#---------------------------------------------------------------------
# jump_to_slab_command
#
# Display an arbitrary slab invoked from the command display
# Optional argument: -force (force redraw of the slab)
#---------------------------------------------------------------------
proc jump_to_slab_command { w1 w2 w3 args } {
#---------------------------------------------------------------------
  ##puts "Jump to slab command"
  set slab_start [string trim [$w1 get]]
  set slab_depth [string trim [$w2 get]]
  set slab_step [string trim [$w3 get]]

  set force 0
  if { [llength $args] > 0 } {
    foreach arg $args {
      switch -exact -- $arg {
	  -force { set force 1 }
      }
    }
  }

  # Validate the starting section value
  ##puts "Slab_start = $slab_start"
  if {![regexp -- "^-?(\[0-9\]+)$" $slab_start]} {
    # Not a valid number
    ##puts "Not a valid section number!"
    set slab_start [get_value START_SLAB]
  } elseif { [section_is_in_limits $slab_start [get_value AXIS]] != 0 } {
    # Starting section is not in range
    ##puts "Starting section number out of range!"
    set slab_start [get_value START_SLAB]
  }

  # Validate the depth and step values
  ##puts "Slab_depth = $slab_depth"
  if {![regexp -- "^(\[0-9\]+)" $slab_depth]} {
    # Not a valid number
    ##puts "Not a valid slab depth"
    set slab_depth 1
  } elseif { $slab_depth < 1 } {
    # There must be at least one section in a slab
    ##puts "Slab depth must be >= 1"
    set slab_depth 1
  }
  ##puts "Slab_step = $slab_step"
  if {![regexp -- "^(\[0-9\]+)" $slab_step]} {
    # Not a valid number
    ##puts "Not a valid slab step"
    set slab_step 1
  }
  # Check that the step size isn't bigger than the number
  # of sections in the slab
  if { $slab_depth < $slab_step } {
    ##puts "Slab step ($slab_step) exceeds depth ($slab_depth): resetting"
    set slab_step $slab_depth
  }

  # Get the end of the slab region
  set slab_end [expr $slab_start + $slab_depth - 1]
  if { [section_is_in_limits $slab_end [get_value AXIS]] != 0 } {
    ##puts "End of slab out-of-range: resetting"
    set slab_end [lindex [get_limits_on_axis [get_value AXIS]] 1]
  }
  ##puts "Slab_end = $slab_end"

  # Has anything changed?
  if { $slab_start != [get_value START_SLAB] || $slab_end != [get_value END_SLAB] || $slab_step != [get_value SLAB_STEP] || $force } {
    # Update the settings
    set_value SECTION         $slab_start
    set_value FRAC_SECTION    [get_frac_from_grid $slab_start [get_value AXIS]]
    set_value START_SLAB      $slab_start
    set_value START_FRAC_SLAB [get_value FRAC_SECTION]
    set_value END_SLAB        $slab_end
    set_value END_FRAC_SLAB   [get_frac_from_grid $slab_end [get_value AXIS]]
    set_value SLAB_STEP       $slab_step
    set_value SLAB_FRAC_STEP  [get_frac_from_grid $slab_step [get_value AXIS]]
    # Redraw the slab
    new_section [get_value AXIS] $slab_start $slab_end $slab_step
  }

  # Update the display 
  $w1 delete 0 [string length [$w1 get]]
  $w1 insert 0 [get_value START_SLAB]
  $w2 delete 0 [string length [$w2 get]]
  $w2 insert 0 $slab_depth
  $w3 delete 0 [string length [$w3 get]]
  $w3 insert 0 [get_value SLAB_STEP]
  return
}

#---------------------------------------------------------------------
# next_slab_command
#
# Advance the start position of the slab by one section
#---------------------------------------------------------------------
proc next_slab_command { w1 w2 w3 } {
#---------------------------------------------------------------------
  # Get current starting slab
  set slab_start [string trim [$w1 get]]
  # Increment
  incr slab_start
  # Put back into the widget 
  $w1 delete 0 [string length [$w1 get]]
  $w1 insert 0 $slab_start
  # Go to the new slab
  jump_to_slab_command $w1 $w2 $w3
}

#---------------------------------------------------------------------
# prev_slab_command
#
# Move the start position of the slab back by one section
#---------------------------------------------------------------------
proc prev_slab_command { w1 w2 w3 } {
#---------------------------------------------------------------------
  # Get current starting slab
  set slab_start [string trim [$w1 get]]
  # Decrement
  incr slab_start -1
  # Put back into the widget 
  $w1 delete 0 [string length [$w1 get]]
  $w1 insert 0 $slab_start
  # Go to the new slab
  jump_to_slab_command $w1 $w2 $w3
}

#---------------------------------------------------------------------
# set_harker_command
#
# Set up the menu of Harker sections for the current setting of the
# Harker spacegroup.
#---------------------------------------------------------------------
proc set_harker_command { w1 w2 w3 } {
#---------------------------------------------------------------------
  # Called when the user sets the Harker Spacegroup
  ##puts "set_harker_command: starting"
  set harker_list [GetHarkerSections [string trim [$w1 get]]]
  ##puts "Harker sections are: $harker_list"
  # If there are none then reset
  if { [lindex $harker_list 0] == 0 } {
    set harker_list [list "None"]
  }
  # Blank any existing menu
  $w3 delete 0 end
  # Rebuild the menu
  foreach section $harker_list {
    $w3 add command -label $section -command "go_to_harker $w2 \"$section\""
  }
  # Jump to the first section if it is valid
  if { [lindex $harker_list 0] != "None" } {
    go_to_harker $w2 [lindex $harker_list 0]
  }
}

#---------------------------------------------------------------------
# go_to_harker
#
# Display the selected Harker section
#---------------------------------------------------------------------
proc go_to_harker { w section } {
#---------------------------------------------------------------------
  # Jump to a selected harker section
  if { $section == "None" } {
    return
  }
  # Extract the axis and section
  if ![regexp -- "^(\[XYZ\])( = )(\[0-9\.\]+)" $section junk1 Axis junk2 frac ] {
     ##WarningMessage "Error: $section is in the wrong format"
     return
  }
  # Make sure axis is in lower case
  set axis [string tolower $Axis]

  # Get grid unit from fractional coord
  set nsection [get_grid_from_frac $frac $axis]

  # Check the limits on this axis
  if { [section_is_in_limits $nsection $axis] != 0 } {
     WarningMessage "The Harker section $Axis = $frac
is outside the limits of the map
and cannot be displayed"
     return
  }
  # Update the values in the main array
  set_value SECTION $nsection
  set_value FRAC_SECTION $frac
  set_value AXIS $axis

  # Collect the new section
  incr_section 0 $axis

  # Reset the value on the menubutton
  $w configure -text $section
  return
}

#---------------------------------------------------------------------
# change_scale_units_command
#
# Change the units used for scaling the section, accessed from the
# command display
#---------------------------------------------------------------------
proc change_scale_units_command { w units } {
#---------------------------------------------------------------------
  ##puts "Change scale units command"
  if { $units != [get_value SCALE_UNITS] } {
    # Apply the scaling
    change_scale [get_value SCALE] $units
  }
  # Update the display
  $w configure -text [get_value SCALE_UNITS]
  return
}

#---------------------------------------------------------------------
# change_scale_command
#
# Change the scale factor used for scaling the section, accessed from
# the command display
#---------------------------------------------------------------------
proc change_scale_command { w } {
#---------------------------------------------------------------------
  ##puts "Change scale command"
  set new_scale [string trim [$w get]]
  ##puts "New scale = $new_scale"

  # Validate scale factor - positive real
  if {![regexp -- "^(\[0-9\]*)(\.?)(\[0-9\]*)$" $new_scale]} {
    # Not a valid number
    ##puts "Not a valid scale factor number!"
    set new_scale [get_value SCALE]
  }

  # Anything to do?
  if { $new_scale != [get_value SCALE] } {
    # Apply the scaling
    change_scale $new_scale [get_value SCALE_UNITS]
  }
  # Update the display
  $w delete 0 [string length [$w get]]
  $w insert 0 [get_value SCALE]
  return
}

