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
# mapslicer_section.tcl
#
# Windows and procedures to set parameters for sections in MapSlicer
#---------------------------------------------------------------------

#--------------------------------------------------------------------
# Jump to any section
#
# This presents a window with the option to go directly to any
# section on any axis
#--------------------------------------------------------------------
proc jump_to_section { } {

    # Is there a map in memory?
    if { [mapinfo map1] != 1 } {
	WarningMessage "No map currently loaded"
	return
    }
    
    # Open another window
    set w .anysection
    if ![OpenWindow $w "Jump to Any Section" "Jump" ] { return }

    # Make the frame and the cancel and apply buttons
    CreateFrame  $w jump_to_section
    CreateButton $w dismiss "Cancel" "unset jump_to_section ; destroy $w"
    CreateButton $w apply   "Apply"  "apply_jump jump_to_section"

    # Define the menus used for this window
    DefineMenu _mapslicer_axis [ list "x" "y" "z" ]
    DefineMenu _mapslicer_frac [ list "grid" "fractional" ] [ list 0 1 ]

    # Set the parameters to be edited
    DefineVariable jump_to_section use_frac    _mapslicer_frac [get_value USE_FRAC]
    DefineVariable jump_to_section new_grdsect _int            [get_value SECTION]
    DefineVariable jump_to_section new_frcsect _real           [get_value FRAC_SECTION]
    DefineVariable jump_to_section new_axis    _mapslicer_axis [get_value AXIS]

    #Draw the widgets in the window
    CreateLine line label "Section specified in" widget use_frac label "units"
    CreateLine line label "Go to section" widget new_grdsect \
	    label "on" widget new_axis label "axis" \
	    toggle_display use_frac open [ list 0 ]
    CreateLine line label "Go to section" widget new_frcsect \
	    label "on" widget new_axis label "axis" \
	    toggle_display use_frac open [ list 1 ]

    # Must always do this at the end
    CloseFrame
    return
}

#--------------------------------------------------------------------
# Apply jump to any section
#
# The jump can be to any section on any axis; need to check that it
# is a valid selection
#
# Returns 1 on success, 0 on failure
#--------------------------------------------------------------------
proc apply_jump { jumpVar } {
#--------------------------------------------------------------------

    upvar #0 $jumpVar jump

    # Are we using fractional coords? Then convert to grid units
    set axis $jump(new_axis)
    if {$jump(use_frac)=="fractional"} {
	set jump(new_grdsect) [get_grid_from_frac $jump(new_frcsect) $jump(new_axis)]
    } else {
	set jump(new_frcsect) [get_frac_from_grid $jump(new_grdsect) $jump(new_axis)]
    }
    
    # Check the limits on this axis
    set section $jump(new_grdsect)
    set ierror [section_is_in_limits $section $axis]

    if { $ierror!=0 } {
	# Get some values for the warning message
	set start [lindex [get_limits_on_axis $axis] 0]
	set stop  [lindex [get_limits_on_axis $axis] 1]
	set frcsect $jump(new_frcsect)
	set flower  [get_frac_from_grid $start $axis]
	set fupper  [get_frac_from_grid $stop  $axis]
	# Warning message gives information about the limits on the
	# current axis
	WarningMessage "Warning: section $section ($frcsect) is out-of-range\n$axis-axis goes from $start to $stop ($flower to $fupper)"
    }

    # If there was an error then restore the old values and return
    if {$ierror!=0} {
	set jump(new_axis)    [get_value AXIS]
	set jump(new_grdsect) [get_value SECTION]
	set jump(new_frcsect) [get_value FRAC_SECTION]
	return 0
    }

    # Update the values in the main array
    set_value SECTION $jump(new_grdsect)
    set_value FRAC_SECTION $jump(new_frcsect)
    set_value AXIS $jump(new_axis)

    # Collect the new section
    incr_section 0 $jump(new_axis)
    return 1
}


#--------------------------------------------------------------------
# Go to Harker section
#
# This presents a window allowing the user to set up the Harker
# sections for this map. It can't be done automatically because
# Patterson maps stored the Patterson spacegroup, and not the true
# spacegroup (which is required for generating the sections).
#--------------------------------------------------------------------
proc go_to_harker { } {
#--------------------------------------------------------------------
    # (Need this for variable menu)
    global typedef

    # Is there a map in memory?
    if { [mapinfo map1] != 1 } {
	WarningMessage "No map currently loaded"
	return
    }

    # Open another window
    set w .harkersection
    if ![OpenWindow $w "Harker Sections" "Harker" ] { return }

    # Make the frame and the buttons
    CreateFrame  $w harker
    CreateButton $w dismiss "Cancel" "unset harker ; destroy $w"
    #CreateButton $w apply   "Go to section"  "jump_to_harker harker"

    # Set up for harker sections list
    # _harker_list is the variable containing the list of 
    DefineVariable harker _harker_list _menu [list "None"]
    DefineVarMenu  _mapslicer_harker 20 _harker_list

    # Set the parameters to be edited
    #puts stdout "Stored value for HARKER_SPACEGROUP: [get_value HARKER_SPACEGROUP]"
    DefineVariable harker spacegroup _positiveint [get_value HARKER_SPACEGROUP]
    DefineVariable harker nsections  _positiveint [get_value HARKER_NSECTIONS]
    DefineVariable harker harker_section _mapslicer_harker "None"
 
    # Get the list of harker sections
    build_harker_list harker

    # Draw widgets
    CreateLine line label "Set spacegroup for generating Harker sections" -italic
    CreateLine line label "Use spacegroup" widget spacegroup \
	    -command "build_harker_list harker"

    CreateLine line label "Select Harker section to display" -italic
    CreateLine line label "Available Harker sections are" widget harker_section \
	    -command "jump_to_harker harker" \
	    toggle_display nsections hide [list 0]

    CreateLine line label "No Harker sections available for this spacegroup" \
	    toggle_display nsections open [list 0]

    # Must always do this at the end
    CloseFrame
    return

}

#--------------------------------------------------------------------
# Build menu of Harker sections
#
# Given the spacegroup this generates the available Harker sections
# and builds a menu to hold them
#--------------------------------------------------------------------
proc build_harker_list { harkerVar } {
#--------------------------------------------------------------------
    upvar #0 $harkerVar harker

    # Update the Harker spacegroup
    set_value HARKER_SPACEGROUP $harker(spacegroup)

    # Get the sections for this spacegroup
    set spacegroup $harker(spacegroup)
    set hsect_list [get_harker_sections $spacegroup]

    # How many harker sections?
    set nharker [llength $hsect_list]

    # None - then reset number and create dummy entry in menu
    if {[lindex $hsect_list 0]==0} {
	set nharker 0
	set hsect_list [list "None"]
    }
    
    # Load the sections into the menu
    UpdateVariableMenu $harkerVar initialise 0 _harker_list $hsect_list

    # Update the number of sections
    set_value HARKER_NSECTIONS $nharker
    set harker(nsections) $nharker
    set harker(harker_section) [lindex $hsect_list 0]

    # Return the first section
    return
}

#---------------------------------------------------------------------------
# Get Harker sections
#
# This return the Harker sections for the specified spacegroup
#---------------------------------------------------------------------------
proc get_harker_sections { spacegroup } {
#---------------------------------------------------------------------------

    # Get the harker sections for this spacegroup
    set hsect_list [GetHarkerSections $spacegroup]
    return $hsect_list
}

#--------------------------------------------------------------------
# Jump to specified Harker section
#
# Extracts the axis and fractional section then goes to that section
#--------------------------------------------------------------------
proc jump_to_harker { harkerVar } {
#--------------------------------------------------------------------
    upvar #0 $harkerVar harker

    # Check: are there any sections to actually go to?
    if { $harker(nsections)==0 } {
	WarningMessage "There are no Harker sections for this spacegroup"
	return
    }

    # Extract axis and section
    set section $harker(harker_section)
    if ![regexp -- "^(\[XYZ\])( = )(\[0-9\.\]+)" $section junk1 Axis junk2 frac ] {
	WarningMessage "Error: $section is in the wrong format"
	return
    }

    # Make sure axis is in lower case
    set axis [string tolower $Axis]

    # Get grid unit from fractional coord
    set nsection [get_grid_from_frac $frac $axis]

    # Check the limits on this axis
    set ierror [section_is_in_limits $nsection $axis]
    if { $ierror!=0 } {
	WarningMessage "The requested Harker section ($Axis=$frac) is not in the map"
	return
    }

    # Update the values in the main array
    set_value SECTION $nsection
    set_value FRAC_SECTION $frac
    set_value AXIS $axis

    # Collect the new section
    incr_section 0 $axis
    return
}

#--------------------------------------------------------------------
# Display slab
#
# This presents a window with options to display a slab of sections
# on any axis
#--------------------------------------------------------------------
proc display_slab { } {

    # Is there a map in memory?
    if { [mapinfo map1] != 1 } {
	WarningMessage "No map currently loaded"
	return
    }
    
    # Open another window
    set w .anysection
    if ![OpenWindow $w "Display Slab" "Slab" ] { return }

    # Make the frame and the cancel and apply buttons
    CreateFrame  $w display_slab
    CreateButton $w dismiss "Cancel" "unset display_slab ; destroy $w"
    CreateButton $w apply   "Apply"  "apply_display_slab display_slab"

    # Define the menus used for this window
    DefineMenu _mapslicer_axis [ list "x" "y" "z" ]
    DefineMenu _mapslicer_frac [ list "grid" "fractional" ] [ list 0 1 ]

    # Set the parameters to be edited
    DefineVariable display_slab use_frac _mapslicer_frac [get_value USE_FRAC]
    DefineVariable display_slab new_start_grdslab _int   [get_value START_SLAB]
    DefineVariable display_slab new_start_frcslab _real  [get_value START_FRAC_SLAB]
    DefineVariable display_slab new_end_grdslab   _int   [get_value END_SLAB]
    DefineVariable display_slab new_end_frcslab   _real  [get_value END_FRAC_SLAB]
    DefineVariable display_slab new_grdstep _positiveint [get_value SLAB_STEP]
    DefineVariable display_slab new_frcstep _positivereal  [get_value SLAB_FRAC_STEP]
    DefineVariable display_slab new_axis _mapslicer_axis [get_value AXIS]

    #Draw the widgets in the window
    CreateLine line label "Slab specified in" widget use_frac label "units"
    CreateLine line label "The slab is defined as sections" \
	    widget new_start_grdslab \
	    label "to" \
	    widget new_end_grdslab \
	    label "in steps of" \
	    widget new_grdstep \
	    label "on the" \
	    widget new_axis \
	    label "axis" \
	    toggle_display use_frac open [ list 0 ]
    CreateLine line label "The slab is defined from" \
	    widget new_start_frcslab \
	    label "to" \
	    widget new_end_frcslab \ \
	    label "in steps of" \
	    widget new_frcstep \
	    label "on the" \
	    widget new_axis label "axis" \
	    toggle_display use_frac open [ list 1 ]

    # Must always do this at the end
    CloseFrame
    return
}

#--------------------------------------------------------------------
# Apply display of slab
#
# The slab can be any number of neighbouring sections on any axis; need
# to check that it is a valid selection
#--------------------------------------------------------------------
proc apply_display_slab { displayVar } {
#--------------------------------------------------------------------

    upvar #0 $displayVar disp

    # Check that limits are small to large, and perform conversions
    # between grid and fractional
    set axis $disp(new_axis)
    if {$disp(use_frac)=="fractional"} {
	# Fractional to grid
	if { $disp(new_start_frcslab) > $disp(new_end_frcslab) } {
	    # Swap limits of slab
	    set tmp $disp(new_start_frcslab)
	    set disp(new_start_frcslab) $disp(new_end_frcslab)
	    set disp(new_end_frcslab) $tmp
	}
	# Do conversion
	set disp(new_start_grdslab) \
		[get_grid_from_frac $disp(new_start_frcslab) $disp(new_axis)]
	set disp(new_end_grdslab) \
		[get_grid_from_frac $disp(new_end_frcslab) $disp(new_axis)]
	set disp(new_grdstep) [get_grid_from_frac $disp(new_frcstep) $disp(new_axis)]
    } else {
	# Grid to fractional
	if { $disp(new_start_grdslab) > $disp(new_end_grdslab) } {
	    # Swap limits of slab
	    set tmp $disp(new_start_grdslab)
	    set disp(new_start_grdslab) $disp(new_end_grdslab)
	    set disp(new_end_grdslab) $tmp
	}
	set disp(new_start_frcslab) \
		[get_frac_from_grid $disp(new_start_grdslab) $disp(new_axis)]
	set disp(new_end_frcslab) \
		[get_frac_from_grid $disp(new_end_grdslab) $disp(new_axis)]
	set disp(new_frcstep) [get_frac_from_grid $disp(new_grdstep) $disp(new_axis)]
    }
    
    # Check the limits on this axis
    set slab_start $disp(new_start_grdslab)
    set slab_end   $disp(new_end_grdslab)
    set ierror1 [section_is_in_limits $slab_start $axis "grid"]
    set ierror2 [section_is_in_limits $slab_end $axis "grid"]

    if { $ierror1!=0 || $ierror2!=0 } {
	# Get some values for the warning message
	set start [lindex [get_limits_on_axis $axis] 0]
	set stop  [lindex [get_limits_on_axis $axis] 1]
	set frcslab_start $disp(new_start_frcslab)
	set frcslab_end   $disp(new_end_frcslab)
	set flower  [get_frac_from_grid $start $axis]
	set fupper  [get_frac_from_grid $stop  $axis]
	# Warning message gives information about the limits on the
	# current axis
	WarningMessage "Warning: slab defined by sections $slab_start ($frcslab_start) to\n$slab_end  ($frcslab_end) is out-of-range\n$axis-axis only goes from $start to $stop ($flower to $fupper)"

        # Restore the old values and return 
        set disp(new_axis)    [get_value AXIS]
	set disp(new_start_grdslab) [get_value START_SLAB]
	set disp(new_start_frcslab) [get_value START_FRAC_SLAB]
	set disp(new_end_grdslab)   [get_value END_SLAB]
	set disp(new_end_frcslab)   [get_value START_FRAC_SLAB]
	return
    }

    # Check for sensible slab step
    if { $disp(new_grdstep) <= 0 } {
	WarningMessage "Warning: step size between sections in the slab must be\nmust be greater than zero"
	set disp(new_grdstep) [get_value SLAB_STEP]
	set disp(new_frcstep) [get_value SLAB_FRAC_STEP]
	return
    }

    # Update the values in the main array
    set_value SECTION         $disp(new_start_grdslab)
    set_value FRAC_SECTION    $disp(new_start_frcslab)
    set_value START_SLAB      $disp(new_start_grdslab)
    set_value START_FRAC_SLAB $disp(new_start_frcslab)
    set_value END_SLAB        $disp(new_end_grdslab)
    set_value END_FRAC_SLAB   $disp(new_end_frcslab)
    set_value SLAB_STEP       $disp(new_grdstep)
    set_value SLAB_FRAC_STEP  $disp(new_frcstep)
    set_value AXIS $disp(new_axis)

    # Update and display the slab
    new_section $disp(new_axis) $disp(new_start_grdslab) $disp(new_end_grdslab) \
	    $disp(new_grdstep)

    # Update the command display
    update_command_display

    return
}

#-----------------------------------------------------------------------
# Customise section
#
# Presents the user with a window to change the section limits and
# grid settings
#-----------------------------------------------------------------------
proc customise_section { } {
#-----------------------------------------------------------------------

    # Open another window
    set w .contours
    if ![OpenWindow $w "Customise Grid" "Grid" -message ] { return }

    # Make the frame and the exit, add and apply buttons
    CreateFrame  $w custom_section
    CreateButton $w dismiss "Exit"  "unset custom_section ; destroy $w"
    CreateButton $w apply   "Apply" "apply_custom_section custom_section"

    # Define the menus used for this window
    DefineMenu _mapslicer_prec [ list "1" "2" "3" "4" "5"]
    DefineMenu _mapslicer_view [ list "rhs" "lhs" ]

    # Set the parameters to be edited
    DefineVariable custom_section use_whole_section \
	    _logical [get_value USE_WHOLE_SECTION]
    DefineVariable custom_section grid_on         _logical [get_value GRID_ON]
    DefineVariable custom_section grid_x_spacing  _real    [get_value GRID_X_SPACING]
    DefineVariable custom_section grid_y_spacing  _real    [get_value GRID_Y_SPACING]
    DefineVariable custom_section grid_label_prec _mapslicer_prec \
	    [get_value GRID_LABEL_PREC]
    DefineVariable custom_section grid_limit_xmin _real    [get_value GRID_LIMIT_XMIN]
    DefineVariable custom_section grid_limit_ymin _real    [get_value GRID_LIMIT_YMIN]
    DefineVariable custom_section grid_limit_xmax _real    [get_value GRID_LIMIT_XMAX]
    DefineVariable custom_section grid_limit_ymax _real    [get_value GRID_LIMIT_YMAX]
    DefineVariable custom_section view_orientation _mapslicer_view \
	[get_value VIEW_ORIENTATION]
    DefineVariable custom_section grid_line_width _positiveint \
	[get_value GRID_LINE_WIDTH]

    # Draw the widgets in the window
    #
    # Section limits
    CreateLine line label "Section Limits" -italic
    CreateLine line widget use_whole_section label "Display entire section"
    OpenSubFrame frame \
	    -toggle_display use_whole_section hide [list 1]
    CreateLine line label "Section on u-axis goes from" widget grid_limit_xmin \
	    label "to" widget grid_limit_xmax
    CreateLine line label "Section on v-axis goes from" widget grid_limit_ymin \
	    label "to" widget grid_limit_ymax
    CloseSubFrame
    #
    # Display grid
    CreateLine line label "Grid Lines" -italic
    CreateLine line widget grid_on label "Display grid lines"
    CreateLine line label "Set grid line widths to" \
	widget grid_line_width \
	label "pixel(s)" \
	toggle_display grid_on open { 1 }
    #
    # 
    #OpenSubFrame frame \
    #    -toggle_display grid_on hide [list 0]
    CreateLine line label "Grid Labels" -italic
    CreateLine line label "Spacing along u axis =" widget grid_x_spacing \
	    label "along v=" widget grid_y_spacing
    CreateLine line label "Display" widget grid_label_prec \
	    label "decimal places for grid labels"
    #CloseSubFrame

    CreateLine line label "View Orientation" -italic
    CreateLine line label "Display sections in a" \
	widget view_orientation label "view"

    # Must always do this at the end
    CloseFrame
    return
}

#-----------------------------------------------------------------------
# Apply customised grid
#
# Updates the section limits and grid according to the values supplied in
# the customise grid window
#-----------------------------------------------------------------------
proc apply_custom_section { customiseVar } {
#-----------------------------------------------------------------------
    upvar #0 $customiseVar customise

    # Update the values in the main array
    #
    # Check and update the limits
    set ierror 0
    if {$customise(use_whole_section)!=1} {
	if {$customise(grid_limit_xmin)>=$customise(grid_limit_xmax)} {
	    set ierror 1
	    #puts stdout "Error in apply_custom_section (1)"
	}
	if {$customise(grid_limit_ymin)>=$customise(grid_limit_ymax)} {
	    set ierror 1
	    #puts stdout "Error in apply_custom_section (2)"
	}
    }
    if {$ierror!=0} {
	set customise(use_whole_section) 0
    } else {
	set_value GRID_LIMIT_XMIN $customise(grid_limit_xmin)
	set_value GRID_LIMIT_XMAX $customise(grid_limit_xmax)
	set_value GRID_LIMIT_YMIN $customise(grid_limit_ymin)
	set_value GRID_LIMIT_YMAX $customise(grid_limit_ymax)
    }
    set_value USE_WHOLE_SECTION  $customise(use_whole_section)
    #
    # Check and update the grid parameters
    set_value GRID_ON $customise(grid_on)
    if {$customise(grid_x_spacing)<=0} {
	WarningMessage "Error: Grid spacing along u <= 0"
	set customise(grid_x_spacing) [get_value GRID_X_SPACING]
    } else {
	set_value GRID_X_SPACING $customise(grid_x_spacing)
    }
    if {$customise(grid_y_spacing)<=0} {
	WarningMessage "Error: Grid spacing along v <= 0"
	set customise(grid_x_spacing) [get_value GRID_Y_SPACING]
    } else {
	set_value GRID_Y_SPACING $customise(grid_y_spacing)
    }
    set_value GRID_LABEL_PREC $customise(grid_label_prec)
    #
    # Update the view orientation
    set_value VIEW_ORIENTATION $customise(view_orientation)
    #
    # Update the grid line width
    set_value GRID_LINE_WIDTH $customise(grid_line_width)

    # Redraw the section with the new values
    redraw_contours

}

#--------------------------------------------------------------------
# Change axis
#
# After changing the axis the section number is checked
# to see if it is in range along the new axis - if not
# then the limits are used
# In either case incr_section is called afterwards to
# store and contour the current section.
#--------------------------------------------------------------------
proc change_axis { newaxis } {
#--------------------------------------------------------------------

    # Retrieve existing settings
    set axis    [ get_value AXIS ]
    set section [ get_value SECTION ]

    if {$newaxis==$axis} {
	#puts stdout "Axis is the same"
	return
    }
    if {$newaxis!="x"} {
	if {$newaxis!="y"} {
	    if {$newaxis!="z"} {
		puts stdout "Bad axis $newaxis"
		exit 1
	    }
	}
    }
    set axis $newaxis
    incr_section 0 $axis

    # Update internal info
    set_value AXIS $axis

    # Update command display
    update_command_display
    return
}


