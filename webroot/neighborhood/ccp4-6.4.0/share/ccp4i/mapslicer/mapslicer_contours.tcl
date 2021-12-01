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
# mapslicer_contours.tcl
#
# Windows and procedures to set parameters for contours in MapSlicer
#---------------------------------------------------------------------

#-----------------------------------------------------------------------
# Customise contours
#
# Presents the user with a window to change the contour levels
#-----------------------------------------------------------------------
proc customise_contours { } {
#-----------------------------------------------------------------------

    # Open another window
    set w .contours
    if ![OpenWindow $w "Set Contour Levels" "Contours" -message ] { return }

    # Make the frame and the exit, add and apply buttons
    CreateFrame  $w customise
    CreateButton $w dismiss "Exit"  "unset customise ; destroy $w"
    CreateButton $w apply   "Apply" "apply_custom_contours customise"

    # Define menus used for this window
    # "type" i.e. sigma levels, absolute values or fractional values
    DefineMenu _mapslice_type [ list \
	    "sigma levels" \
	    "absolute values" \
	    "fractions of the maximum density" ] \
	    [ list "sigma" "abs" "frac" ]
    #
    # "levels" i.e. whether we want a range or list of values
    # FIXME the option for a list is not implemented at present
    DefineMenu _mapslice_levels [ list "range" "list" ] 

    # Set the parameters to be editted
    DefineVariable customise contour_type _mapslice_type [get_value CONTOUR_TYPE]
    DefineVariable customise contour_lvl  _mapslice_levels [get_value CONTOUR_LEVELS]
    DefineVariable customise contour_min  _real   [get_value CONTOUR_MIN]
    DefineVariable customise contour_max  _real   [get_value CONTOUR_MAX]
    DefineVariable customise contour_int  _real   [get_value CONTOUR_INTERVAL]
    DefineVariable customise ncontours    _int    [get_value NCONTOURS]

    # Equivalent negative contours
    if { [get_value CONTOUR_NEG] == "yes" } {
	set negcontours 1
    } else {
	set negcontours 0
    }
    DefineVariable customise contour_neg    _logical $negcontours
    DefineVariable customise no_neg_density _logical [get_value NO_NEGATIVE_DENSITY]
    # Update for equivalent negative contours
    check_negative_min customise

    # Offset contours by mean density
    if { [get_value CONTOUR_OFFSET] == "yes" } {
	set offset 1
    } else {
	set offset 0
    }
    DefineVariable customise contour_offset _logical $offset

    # Contour line width
    DefineVariable customise contour_line_width _positiveint \
	[get_value CONTOUR_LINE_WIDTH]

    # Need to collect the list of contours currently set
    # FIXME list of contours currently set is not required here
    #get_list_of_contours customise

    # Draw the widgets in the window
    # Contour levels specified as sigma levels etc
    # FIXME the option to use a list of levels is not implemented
    #CreateLine line label "Contour levels specified as a" \
    #	    widget contour_lvl  label "of"\
    #	    widget contour_type -command "update_list_of_contours customise"
    ##CreateLine line label "Contour levels specified as a range of"\
	##    widget contour_type

    # Subframe for entering levels as a RANGE
    OpenSubFrame frame \
	    -toggle_display contour_lvl open [list "range"]
    ##CreateLine line label "Contour levels as a range of values" -italic
    CreateLine line label "Contour levels specified as a range of sigma levels" -italic
    CreateLine line label "Contour levels from" \
	    widget contour_min -command "check_negative_min customise" \
	    label "to" widget contour_max \
	    label "in intervals of" widget contour_int
    # Bind entry widgets to apply when enter is pressed
    bind $line.e2 <Return> "apply_custom_contours customise"
    bind $line.e4 <Return> "apply_custom_contours customise"
    bind $line.e6 <Return> "apply_custom_contours customise"
    CloseSubFrame

    # Subframe for entering levels as a LIST
    # FIXME entering contour levels as a list is not implemented yet
    OpenSubFrame frame \
        -toggle_display contour_lvl open [list "list"]
    CreateLine line label "List of values not implemented" -italic
    CloseSubFrame

    # Equivalent negative contours
    CreateLine line widget contour_neg \
	    -command "apply_custom_contours customise" \
	    label "Include equivalent negative contours" \
	    toggle_display no_neg_density open [list 0]

    # Offset by mean density
    CreateLine line widget contour_offset \
	    -command "apply_custom_contours customise" \
	    label "Generate contour levels starting from the mean density in the map"

    # Set width of lines for contours
    CreateLine line label "Contour Lines" -italic
    CreateLine line label "Set contour line width to" \
	widget contour_line_width \
	label "pixels"

    # Must always do this at the end
    CloseFrame
    return
}

#-----------------------------------------------------------------------
# Get a list of contour levels
#
# The contours are stored as a list in memory
#-----------------------------------------------------------------------
proc get_list_of_contours { customiseVar } {
#-----------------------------------------------------------------------
    upvar #0 $customiseVar customise

    # Get number and value of contour levels held in memory
    set customise(NCONTOURS) [contourinfo nlevels]
    set contourlevels [contourinfo levels]
    set i 0
    foreach level $contourlevels {
	incr i
	set customise([Indxv ABSLEVEL $i]) $level
    }

    # Update the list so that the levels are scaled correctly
    # i.e. units of sigma, fractional etc
    update_list_of_contours customise

    return
}

#-----------------------------------------------------------------------
# Update the list of contour levels
#
# The contours are stored as a list in memory but we must convert to the
# appropriate values for display
#-----------------------------------------------------------------------
proc update_list_of_contours { customiseVar } {
#-----------------------------------------------------------------------
    upvar #0 $customiseVar customise

    # The levels are on an ABSOLUTE scale and include +ve and -ve levels
    set ncontours $customise(NCONTOURS)

    # Do conversion
    set type [GetValue customise contour_type]
    if {$type=="abs"} {
	# No scaling necessary
	for {set i 1} {$i<=$ncontours} {incr i} {
	    set customise([Indxv LEVEL $i]) $customise([Indxv ABSLEVEL $i])
	    #puts stdout "Level $i is $customise([Indxv LEVEL $i])"
	}
    } elseif {$type=="sigma"} {
	# Need to divide each value by sigma
	set sigma [mapinfo map1 rms]
	for {set i 1} {$i<=$ncontours} {incr i} {
	    set customise([Indxv LEVEL $i]) \
		    [expr $customise([Indxv ABSLEVEL $i]) / $sigma ]
	    #puts stdout "Level $i is $customise([Indxv LEVEL $i]) * sigma"
	}
	#foreach level $contourlevels {
	#    lappend sigmalevels [expr $level / $sigma]
	#}
	#set contourlevels $sigmalevels
    } elseif {$type=="frac"} {
	# Need to divide levels by maximum
	set maxp [mapinfo map1 maximum]
	for {set i 1} {$i<=$ncontours} {incr i} {
	    set customise([Indxv LEVEL $i]) \
		    [expr $customise([Indxv ABSLEVEL $i]) / $maxp ]
	    #puts stdout "Level $i is $customise([Indxv LEVEL $i]) * max"
	}
	#foreach level $contourlevels {
	#    lappend fraclevels [expr $level / $maxp]
	#}
	#set contourlevels $fraclevels
    }
    return
}

#-----------------------------------------------------------------------
# Apply customised contours
#
# Updates the contour levels according to the values supplied in
# the customise contours window
#-----------------------------------------------------------------------
proc apply_custom_contours { customiseVar } {
#-----------------------------------------------------------------------
    upvar #0 $customiseVar customise

    # Check for negative density flag
    check_negative_min $customiseVar
    if {$customise(no_neg_density)==1} {
	set customise(contour_neg) 0
    }

    # Do some checks for range of values
    if {[GetValue customise contour_lvl]=="range"} {
	# Min must be less than max
	set mini $customise(contour_min)
	set maxi $customise(contour_max)
	#puts "maxi = $maxi and mini = $mini"
	if {$maxi <= $mini} {
	    WarningMessage "Maximum is less than minimum"
	    return
	}
	# If minimim is less than zero don't ask for equivalent
	# negative contours
	if {$mini<0} {
	    set customise(contour_neg) 0
	}
	# Step must be greater than zero
	set step $customise(contour_int)
	if {$step<=0} {
	    WarningMessage "Contouring interval must be > 0.0"
	    return
	}
	# Check for execessive numbers of contours
	set range [expr $maxi - $mini]
	set ncontours [expr $range / $step]
	if {$customise(contour_neg) == 1} {
	    set ncontours [expr $ncontours * 2 - 1]
	}
	if {$ncontours > 500} {
	    WarningMessage "These settings will result in an excessive\nnumber of contour levels (>500)"
	    return
	}
    }

    # Update the values in the main array
    set_value CONTOUR_TYPE     [GetValue customise contour_type]
    set_value CONTOUR_MIN      $customise(contour_min)
    set_value CONTOUR_MAX      $customise(contour_max)
    set_value CONTOUR_INTERVAL $customise(contour_int)
    if { $customise(contour_neg) == 1} {
	set_value CONTOUR_NEG  "yes"
    } else {
	set_value CONTOUR_NEG  "no"
    }
    if { $customise(contour_offset) == 1} {
	set_value CONTOUR_OFFSET "yes"
    } else {
	set_value CONTOUR_OFFSET "no"
    }
    set_value CONTOUR_LINE_WIDTH $customise(contour_line_width)

    # Redraw the section with the new values
    redraw_contours

}

#-----------------------------------------------------------------------
# Check for negative minimum
#
# Called when lower range limit is updated
#-----------------------------------------------------------------------
proc check_negative_min { customiseVar } {
#-----------------------------------------------------------------------
    upvar #0 $customiseVar customise

    # Is the minimum value < 0?
    if {$customise(contour_min)<0} {
	set customise(no_neg_density) 1
    } else {
	set customise(no_neg_density) [get_value NO_NEGATIVE_DENSITY]
    }
    return
}

#--------------------------------------------------------------------
# Change the scaling units
#
# Brings up a window to allow the user to set the scaling units for
# the section
#--------------------------------------------------------------------
proc change_scale_units { } {
#--------------------------------------------------------------------

    # Open another window
    set w .scaleunits
    if ![OpenWindow $w "Set Scaling Units" "Scaling Units" -message ] { return }

    # Make the frame and the exit, add and apply buttons
    CreateFrame  $w scaleunits
    CreateButton $w dismiss "Exit"  "unset scaleunits ; destroy $w"
    CreateButton $w apply   "Apply" "apply_scale_units scaleunits"

    # Define menus used in this window
    DefineMenu _mapslice_units [ list "mm" "pixels" ]

    # Set the parameters to be edited
    DefineVariable scaleunits units _mapslice_units [get_value SCALE_UNITS]

    # Draw the widgets in the window
    CreateLine line label "Set default scaling to use units of" \
	    widget units label "per Angstrom"

    # Must always do this at the end
    CloseFrame
    return
}



#--------------------------------------------------------------------
# Apply change of scale factor units
#--------------------------------------------------------------------
proc apply_scale_units { scaleVar } {
#--------------------------------------------------------------------
    upvar #0 $scaleVar scale

    set old_units [get_value SCALE_UNITS]
    update_scale_menu [get_value SCALEMENU] $scale(units) $old_units

    # Update the scale
    change_scale [get_value SCALE] $scale(units)
    return
}

#--------------------------------------------------------------------
# Set scaling manually
#
# Brings up a window to allow the user to set the scaling of the map
# manually
#--------------------------------------------------------------------
proc set_manual_scale { } {
#--------------------------------------------------------------------

    # Open another window
    set w .scale
    if ![OpenWindow $w "Set Scaling" "Scaling" -message ] { return }

    # Make the frame and the exit, add and apply buttons
    CreateFrame  $w scale
    CreateButton $w dismiss "Exit"  "unset scale ; destroy $w"
    CreateButton $w apply   "Apply" "apply_scale scale"

    # Define menus used in this window
    DefineMenu _mapslice_units [ list "mm" "pixels" ]

    # Set the parameters to be edited
    DefineVariable scale scalefac _positivereal [get_value SCALE]
    DefineVariable scale units    _mapslice_units [get_value SCALE_UNITS]

    # Draw the widgets in the window
    CreateLine line label "Scaling" -italic
    CreateLine line label "Use scale factor of" \
	    widget scalefac \
	    widget units \
	    label "per Angstrom"

    # Must always do this at the end
    CloseFrame
    return

}

#--------------------------------------------------------------------
# Apply new scale factor
#
# Called from proc set_manual_scale
#--------------------------------------------------------------------
proc apply_scale { scaleVar } {
#--------------------------------------------------------------------

    upvar #0 $scaleVar scale
    set scalefac $scale(scalefac)

    # Scale factor must be positive
    if {$scalefac<=0} {
	WarningMessage "Scalefactor must be greater than zero"
	set scale(scalefac) [get_value SCALE]
	return
    }

    # Update the scale
    change_scale $scale(scalefac) $scale(units)
    return
}

#--------------------------------------------------------------------
# Change scaling
#
# Changes the scale (i.e. units/pixel) and redraws the current
# section.
#--------------------------------------------------------------------
proc change_scale { scalefac units } {
#--------------------------------------------------------------------

    # Estimate the size of the new window
    # If is likely to be larger than the screen then calculate
    # a more acceptable scalefactor

    # Update the scalefactor in storage
    set_value SCALE $scalefac
    set_value SCALE_UNITS $units

    # Update the "last set scale" for use with zoom
    set_value LAST_SET_SCALE $scalefac

    # Update the information
    update_command_display

    # Redraw the section
    redraw_contours
    return
}
