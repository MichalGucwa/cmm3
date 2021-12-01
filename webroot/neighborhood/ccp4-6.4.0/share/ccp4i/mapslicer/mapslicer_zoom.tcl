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
# mapslicer_zoom.tcl
#
# Windows and procedures to zoom in on a part of a section in MapSlicer
#---------------------------------------------------------------------
#
#--------------------------------------------------------------------
# zoom_start
#
# Invoked when the user clicks in the canvas
#--------------------------------------------------------------------
proc zoom_start { x y canvas_name } {
#--------------------------------------------------------------------
  if { ![get_value ZOOM_ON] && [section s1 coords $canvas_name $x $y] != "" } {
    # Switch on zoom
    set_value ZOOM_ON 1
    set_value ZOOM_X $x
    set_value ZOOM_Y $y
    # Create initial box
    $canvas_name create rectangle $x $y $x $y -tag zoom_box
    # Write the zoom instructions
    $canvas_name create text $x $y -text "Drag to select zoom area" \
         -anchor sw -tags zoom_message -fill red
  }
}

#--------------------------------------------------------------------
# zoom_drag
#
# Invoked when the user drags the mouse. If zoom mode is on then a
# rectangle is displayed showing the currently selected area.
#--------------------------------------------------------------------
proc zoom_drag { x y canvas_name } {
#--------------------------------------------------------------------
  if { ![get_value ZOOM_ON] } { return }
  $canvas_name delete zoom_box
  $canvas_name create rectangle [get_value ZOOM_X] [get_value ZOOM_Y] $x $y \
	  -tags zoom_box -width 3
}

#--------------------------------------------------------------------
# zoom_apply
#
# Invoked when the mouse button is released. If zoom mode is on then
# the section is clipped to the selected area.
#--------------------------------------------------------------------
proc zoom_apply { x y canvas_name } {
#--------------------------------------------------------------------
  ##puts "Starting ZOOM_APPLY"
  if { ![get_value ZOOM_ON] } { return }
  $canvas_name delete zoom_box zoom_message

  # Determine the upper and lower corners of the zoom area
  # Minimum x value
  if { [get_value ZOOM_X] < $x } {
    set minx [get_value ZOOM_X]
    set maxx $x
  } else {
    set minx $x
    set maxx [get_value ZOOM_X]
  }
  # Minimum y value
  if { [get_value ZOOM_Y] < $y } {
    set miny [get_value ZOOM_Y]
    set maxy $y
  } else {
    set miny $y
    set maxy [get_value ZOOM_Y]
  }
  ##puts "limits of ZOOM_BOX: $minx $miny - $maxx $maxy"

  # Determine "x" and "y" axes for current section
  set waxis [section s1 config -axis]
  if {$waxis=="x"} {
    set uaxis "y"
    set vaxis "z"
  } elseif {$waxis=="y"} {
    set uaxis "z"
    set vaxis "x"
  } elseif {$waxis=="z"} {
    set uaxis "x"
    set vaxis "y"
  }
  ##puts "Xaxis = $uaxis Yaxis = $vaxis"

  # Get the fractional coordinates for the two corners of the box
  set lower [section s1 coords $canvas_name $minx $miny]
  set upper [section s1 coords $canvas_name $maxx $maxy]

  # If neither limit is set then the box is either bigger
  # than the displayed section, or completely outside
  # In either case simply ignore and return
  if { $lower == "" && $upper == "" } {
    ##puts "Zoom box out of bounds - returning"
    set_value ZOOM_ON 0
    return
  }

  # Get currently displayed limits of section (grid units)
  set limits [section s1 config -limits]

  # Get the grid units of the corners of the box
  if { [llength $lower] > 1 } {
    set lower [lindex $lower 1]
    set minx [get_grid_from_frac [lindex $lower 0] $uaxis]
    set miny [get_grid_from_frac [lindex $lower 1] $vaxis]
  } else {
    set minx [lindex $limits 0]
    set miny [lindex $limits 2]
    ##puts "Using current minimum limits: $minx - $miny"
  }
  set upper [section s1 coords $canvas_name $maxx $maxy]
  if { [llength $upper] > 1 } {
    set upper [lindex $upper 1]
    set maxx [get_grid_from_frac [lindex $upper 0] $uaxis]
    set maxy [get_grid_from_frac [lindex $upper 1] $vaxis]
  } else {
    set maxx [lindex $limits 1]
    set maxy [lindex $limits 3]
    ##puts "Using current maximum limits: $minx - $miny"
  }
  ##puts "grid limits of ZOOM_BOX: $minx $miny - $maxx $maxy"

  # Check box has size (width _and_ height) greater than zero!
  if { $minx == $maxx || $miny == $maxy } {
    ##puts "Zoom box too small - returning"
    set_value ZOOM_ON 0
    return
  }

  # Put current values on the zoom stack
  zoom_stack_push

  # Set the limits
  # Also - reset USE_WHOLE_SECTION (so that new limits are used)
  set_value USE_WHOLE_SECTION 0
  set_value GRID_LIMIT_XMIN $minx
  set_value GRID_LIMIT_YMIN $miny
  set_value GRID_LIMIT_XMAX $maxx
  set_value GRID_LIMIT_YMAX $maxy

  # Rescale the canvas
  set current_scale [get_value SCALE]

  # Old and new dimensions
  set old_height [expr [lindex $limits 3] - [lindex $limits 2]]
  set old_width  [expr [lindex $limits 1] - [lindex $limits 0]]
  set new_height [expr [get_value GRID_LIMIT_XMAX] - [get_value GRID_LIMIT_XMIN]]
  set new_width  [expr [get_value GRID_LIMIT_YMAX] - [get_value GRID_LIMIT_YMIN]]

  # Resultant areas
  set new_area [expr $new_height * $new_width]
  set old_area [expr $old_height * $old_width]

  # Scale according to area change - seems an acceptable compromise
  # in the absence of a more sophisticated algorithm
  set area_factor  [expr [change_precision $old_area 0] / [change_precision $new_area 0]]
  set_value SCALE [change_precision [expr $current_scale * sqrt($area_factor)] 1]

  # Redraw the section with the new values
  redraw_contours

  # Switch off zoom mode
  set_value ZOOM_ON 0
}

#--------------------------------------------------------------------
# zoom_stack_push
#
# Push view attributes onto the zoom stack before performing the
# zoom operation. The attributes can be recovered later to reverse
# the zoom.
#--------------------------------------------------------------------
proc zoom_stack_push { } {
#--------------------------------------------------------------------
  # Store the current values on the stack before doing the zoom
  set zoom ""
  set zoom_list [list SCALE USE_WHOLE_SECTION GRID_LIMIT_XMIN \
	  GRID_LIMIT_YMIN GRID_LIMIT_XMAX GRID_LIMIT_YMAX ]
  foreach item $zoom_list {
    lappend zoom [get_value $item]
  }
  set stack [get_value ZOOM_STACK]
  lappend stack $zoom
  set_value ZOOM_STACK $stack
}

#--------------------------------------------------------------------
# zoom_stack_pop
#
# Pop view attributes off the zoom stack to reverse the last zoom
# operation.
#--------------------------------------------------------------------
proc zoom_stack_pop { } {
#--------------------------------------------------------------------
  # Retrieve and restore the values prior to the last zoom
  set stack [get_value ZOOM_STACK]
  if { [llength $stack] == 0 } { return 0 }
  set zoom [lindex $stack end]
  set zoom_list [list SCALE USE_WHOLE_SECTION GRID_LIMIT_XMIN \
	  GRID_LIMIT_YMIN GRID_LIMIT_XMAX GRID_LIMIT_YMAX ]
  set index 0
  foreach item $zoom_list {
    set_value $item [lindex $zoom $index]
    incr index
  }
  set_value ZOOM_STACK [lreplace $stack end end]
  return 1
}

#--------------------------------------------------------------------
# undo_zoom
#
# Reverse the last zoom operation.
#--------------------------------------------------------------------
proc undo_zoom { } {
#--------------------------------------------------------------------
  if { [zoom_stack_pop] } {
    redraw_contours
  }
}

#--------------------------------------------------------------------
# auto_scale
#
# Restore the display of the section to the default values
# i.e. whole section scaled at 2mm/Angstrom
#--------------------------------------------------------------------
proc auto_scale { } {
#--------------------------------------------------------------------
  # Reset the display to show the whole section
  set_value USE_WHOLE_SECTION 1

  # Reset the scaling
  set_value SCALE 2
  set_value SCALE_UNITS "mm"

  # Redraw the section
  redraw_contours
}
