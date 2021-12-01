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
# mapslicer_utils.tcl
#
# Utility procedures for MapSlicer
#---------------------------------------------------------------------

#--------------------------------------------------------------------
# Set the value of a variable stored in the main array "stuff"
#
# This should prevent the need to transfer "stuff" to every routine
#--------------------------------------------------------------------
proc set_value { name value } {
#--------------------------------------------------------------------
    global stuff
    set stuff($name) $value
    return
}

#--------------------------------------------------------------------
# Return the value of a variable stored in the main array "stuff"
#
# This should prevent the need to transfer "stuff" to every routine
#--------------------------------------------------------------------
proc get_value { name } {
#--------------------------------------------------------------------
    global stuff
    set value "?"
    catch [set value $stuff($name)]
    if {$value=="?"} {puts stdout "get_value: couldn't find $name"}
    return $value
}

#--------------------------------------------------------------------
# Get fractional position from a grid coordinate
#
# Requires the grid number and the axis
#--------------------------------------------------------------------
proc get_frac_from_grid { ngrid axis } {

    # Default value
    set frac 0.0

   # Check if we have a map
    if { [mapinfo map1] != 1 } {
	return $frac
    }

    # Get the xyz grid spacings for all axes
    set mxyz [mapinfo map1 grid]

    # Select the spacing for the requested axis
    if {$axis=="x" } {
	set maxis [ string trim [lindex $mxyz 0] ]
    } elseif {$axis=="y" } {
	set maxis [ string trim [lindex $mxyz 1] ]
    } elseif {$axis=="z" } {
	set maxis [ string trim [lindex $mxyz 2] ]
    } else {
	#puts stdout "Bad axis: $axis in get_frac_from_grid"
	return $frac
    }

    # Convert grid to frac
    # Need to make sure that grid and maxis are floats not ints
    # otherwise division is nonesense
    set frac [expr [change_precision $ngrid 0] / [change_precision $maxis 0] ]
    #puts stdout "frac_from_grid: section: $ngrid axis: $axis"
    #puts stdout "frac_from_grid: frac: $frac"

    # Limit the precision to 4dp
    set frac [change_precision $frac 4]

    return $frac
}

#--------------------------------------------------------------------
# Get grid position from a fractional coordinate
#
# Requires the fractional position along the axis, and the axis
# specification (x,y or z)
#--------------------------------------------------------------------
proc get_grid_from_frac { nfrac axis } {

    # Default value
    set grid 0.0

   # Check if we have a map
    if { [mapinfo map1] != 1 } {
	return $grid
    }

    # Get the xyz grid spacings for all axes
    set mxyz [mapinfo map1 grid]

    # Select the spacing for the requested axis
    if {$axis=="x" } {
	set maxis [ string trim [lindex $mxyz 0] ]
    } elseif {$axis=="y" } {
	set maxis [ string trim [lindex $mxyz 1] ]
    } elseif {$axis=="z" } {
	set maxis [ string trim [lindex $mxyz 2] ]
    } else {
	#puts stdout "Bad axis: $axis in get_frac_from_grid"
	return $grid
    }

    # Convert frac to grid
    # Need to make sure that frac and maxis are floats not ints
    # otherwise division is nonesense
    set grid [expr [change_precision $nfrac 0] * [change_precision $maxis 0] ]

    # Convert to integer
    set grid [change_precision $grid -1]

    return $grid
}

#--------------------------------------------------------------------
# Get limits along axis
#
# Supply an axis (x,y,z) - returns the min and max grid units along
# that axis.
#--------------------------------------------------------------------
proc get_limits_on_axis { axis } {
#--------------------------------------------------------------------

    # Index the axis
    if {$axis=="x"} {
	set istart 0
	set istop  1
    } elseif {$axis=="y"} {
	set istart 2
	set istop  3
    } elseif {$axis=="z"} {
	set istart 4
	set istop  5
    } else {
	WarningMessage "get_limits_on_axis:\n supplied bad axis $axis"
	return -1
    }

    # Check if a map is stored
    if { [mapinfo map1]!=1 } {
	WarningMessage "get_limits_on_axis:\n no map currently stored"
	return -1
    }

    # Get the limits in map units
    set limits [mapinfo map1 limits]
    set start  [string trim [lindex $limits $istart]]
    set stop   [string trim [lindex $limits $istop]]

    return [list $start $stop]
}

#--------------------------------------------------------------------
# Check if section is in range
#
# Given a section number and axis, return 0 if the section is in the
# map and -1 if it is out of range.
#
# Section number can be in grid or fractional units, but should be
# indicated by the optional argument units (either "grid" or "frac")
# Otherwise grid units are assumed.
#--------------------------------------------------------------------
proc section_is_in_limits { section_in axis { units {} } } {
#--------------------------------------------------------------------
    
    # Check if we have fractional units
    if { $units == "frac" } {
	set section [get_grid_from_frac $section_in $axis]
    } else {
	set section $section_in
    }

    # Get the limits along the axis
    set limits [get_limits_on_axis $axis]

    # Check if section is in range
    set ierror 0
    if { [llength $limits]==2 } {
	set start [lindex $limits 0]
	set stop  [lindex $limits 1]
	# If limits are out of range then don't proceed
	if {$start>$section || $stop<$section} {
	    set ierror -1
	}
    } else {
	WarningMessage "section_is_in_limits:\n couldnt get limits on axis"
	set ierror -1
    }
    return $ierror
}

#--------------------------------------------------------------------
# Change the precision of decimal numbers
#
# This procedure will truncate decimal numbers to the required number
# of decimal places, rounding the last digit if necessary.
# Some examples:
#   0.8977665 to 4dp -> 0.8978  (rounding up) 
#   123.83    to 1dp -> 123.8   (rounding down)
#   123.83    to 3dp -> 123.83  (only return as many dp as supplied)
#   .223      to 2dp -> 0.22    (prepends "0")
#   123.      to 1dp -> 123.0   (appends "0")
#
# If zero dp are requested then the input value is "cleaned" (removal
# of leading/trailing whitespace, appending/prepending 0's etc) but
# otherwise is unchanged. 
# If -ve dp are requested then the input value is returned as an
# integer.
#
# Not much testing so far so I'm not sure if there is peculiar
# behaviour in some cases.
#--------------------------------------------------------------------
proc change_precision { number places } {
#--------------------------------------------------------------------

    # Clean all leading and trailing spaces
    set number [ string trim $number ]

    # Check we are dealing with a number of the correct format
    # i.e. contains only digits 0-9, zero or one "." and zero or one
    # leading "-"
    # This will also separate the number into components
    if ![regexp -- "^(-?)(\[0-9\]*)(\[\.\]?)(\[0-9\]*)" $number junk sign \
        leading point trailing] {
        puts stdout "change_precision: $number not in correct format"
        return $number
    }

    # Check that places has been supplied as an integer
    if ![regexp -- "\[0-9\]+" $places ] {
        puts stdout "change_precision: no of dp = $places is not a positive integer"
        return $number
    }

    # Begin rebuilding the number string from the lhs
    set number $sign

    # Leading digits
    # Numbers with no leading digits - prepend "0"
    set nlead [string length $leading]
    if {$nlead==0} {
        append number "0"
    } else {
        append number $leading
    }

    # Trailing digits
    set ntrail [string length $trailing]

    # If places=0 then set it to be one greater than ntrail
    # This means that only basic "tidying" operations will be
    # performed
    # Use this to convert integers to floats
    if {$places==0} { set places [expr $ntrail + 1] }

    # If places<0 then convert to an integer
    if {$places<0} {
	# Are there any trailing digits to round up/down?
	if {$ntrail>0} {
	    set rounding_digit [string index $trailing 0]
	    if {$rounding_digit>=5} {
		incr number
	    }
	}
	return $number
    }

    # Numbers with no trailing digits - add ".0"
    if {$ntrail==0} {
        append number ".0"

    # Insufficient trailing digits for requested precision
    } elseif {$ntrail<=$places} {
        append number "." $trailing

    # Truncation required
    # Check the last digit before truncation to determine
    # whether to round up or down
    } else {
        set rounding_digit [string index $trailing $places]
        incr places -1
        set last_digit [string index $trailing $places]
        # Round up
        if {$rounding_digit>=5} { incr last_digit }
        # Build output string
        incr places -1
        append number "." [string range $trailing 0 $places] $last_digit
    }

    # Finished - return new value of number
    return $number
}

#------------------------------------------------------------------------
# DefineVarMenu
#
# Attempted fudge to get a variable menu....
# This is version of DefineMenu from the main ccp4i source code
# name = name of the array variable used to store the variables
# nchar = field width (no of characters)
# menuVar = name of variable which holds the menu list
# aliasVar = name of varaiable holding the list of aliases (optional)
#------------------------------------------------------------------------
proc DefineVarMenu { name nchar menuVar { aliasVar "" } } {
#------------------------------------------------------------------------
  global typedef
  if { $aliasVar != "" } {
    eval "set typedef($name) { varmenu $menuVar $aliasVar $nchar }"
  } else {
    eval "set typedef($name) { varmenu $menuVar {} $nchar }"
  }
}

