# $Id: masking.tcl,v 1.10 2012/01/26 16:28:26 ccb Exp $
package provide masking 1.0
class Mask {
    inherit Overlay

    # procedures

    public proc setupCreationBindings
    public proc removeCreationBindings
    public proc newMask
    public proc BackstopMask
    public proc deleteMask
    public proc deleteAllMasks
    public proc unselectAll
    public proc plotAll
    public proc clearAll
    public proc overMask
    public proc serializeAll
    public proc parseMasks
    public proc getMasks

    # common variables
    private common mask_count "0"
    private common masks_by_number ; #array

    # member variables
    private variable mask_number ""
    private variable anchor_count 0
    private variable anchor_image ::img::mask_anchor_green5x5

    private variable x1_mm ""
    private variable y1_mm ""
    private variable x2_mm ""
    private variable y2_mm ""
    private variable x3_mm ""
    private variable y3_mm ""
    private variable x4_mm ""
    private variable y4_mm ""

    private variable current_anchor ""

    # methods

    # creation
    private method createAnchor
    public method moveNextAnchor
    public method addAnchor
    public method cancelBuild
    public method select
#     public method freeAnchor
#     public method moveAnchor
#     public method fixAnchor
    public method plot
    public method serialize

    # editing
    public method highlightMask
    public method unhighlightMask
    public method highlight
    public method unhighlight
    public method getTip
    public method drag
    public method drop
    public method getDistance
    public method getMmCoords

    # utility
    private method getAnchorCoords

    public method getNumber { } { return $mask_number }

    # constructor
    constructor { a_method args } { }

    # destructor
    destructor {
	$canvas delete mask($mask_number)
    }
}

# Procedures #####################################

body Mask::setupCreationBindings { } {
    $canvas configure -cursor $::cursor::mask
    bind $canvas <Motion> {}
    bind $canvas <1> [list Mask::newMask %x %y]
}

body Mask::removeCreationBindings { } {
    $canvas configure -cursor left_ptr
    bind $canvas <Motion> {}
    bind $canvas <1> {}
}

body Mask::newMask { x y } {
    #puts "newMask x=$x y=$y"
    set l_new_mask [namespace current]::[Mask \#auto "build" $x $y]
}

body Mask::BackstopMask { x1 y1 x2 y2 x3 y3 x4 y4 } {
    #puts "$x1 $y1 $x2 $y2 $x3 $y3 $x4 $y4"
    set l_new_mask [namespace current]::[Mask \#auto "initialize" $x1 $y1 $x2 $y2 $x3 $y3 $x4 $y4]
}

body Mask::deleteMask { a_number } {
    # delete mask
    delete object $masks_by_number($a_number)
    # remove from mask array
    array unset masks_by_number $a_number
    # Trigger prediction
    $::session updatePredictions

}

body Mask::deleteAllMasks { } {
    # delete all masks
    foreach i_number [array names masks_by_number] {
	delete object $masks_by_number($i_number)
    }
    # remove all masks from mask array
    array unset masks_by_number *
}

body Mask::unselectAll { } {
    # Remove delete bindings
    bind $canvas <Delete> {}
    bind $canvas <BackSpace> {}
    # Hide all anchors
    $canvas itemconfigure mask_anchor -image ""
}

body Mask::plotAll { } {
    foreach i_number [array names masks_by_number] {
	$masks_by_number($i_number) plot
    }
}

body Mask::clearAll { } {
    foreach i_number [array names masks_by_number] {
	$masks_by_number($i_number) clear
    }
    set mask_count 0
}

body Mask::overMask { a_x a_y } {
    set l_overlapping [$canvas find overlapping $a_x $a_y $a_x $a_y]
    foreach i_item $l_overlapping {
	if {[lsearch [$canvas gettags $i_item] mask] != -1} {
	    foreach i_tag [$canvas gettags $i_item] {
		if {[regexp {mask.(\d+).} $i_tag l_match l_number]} {
		    return $masks_by_number($l_number)
		}
	    }
	}
    }
    return ""
}

body Mask::serializeAll { } {
    set xml "<masks>"
    foreach i_num [array names masks_by_number] {
	append xml [$masks_by_number($i_num) serialize]
    }
    append xml "</masks>"
    return $xml
}

body Mask::parseMasks { a_dom } {
    foreach i_node [$a_dom selectNodes {//mask}] {
	Mask \#auto "xml" $i_node
    }
}

body Mask::getMasks { } {
    set l_masks {}
    foreach i_num [array names masks_by_number] {
	lappend l_masks $masks_by_number($i_num)
    }
    return $l_masks
}

# Methods #####################################

body Mask::constructor { a_method args } {
    # give mask a number
    set mask_number $mask_count
    # Store mask by number in common array
    set masks_by_number($mask_number) $this
    # incr common mask count
    incr mask_count
    # if building interactively...
    if {$a_method == "build"} {
	# get the canvas coordinates
	foreach { l_canvas_x l_canvas_y } $args break
	# set the position of the first anchor
	foreach { x1_mm y1_mm } [c2mCoords [list $l_canvas_x $l_canvas_y]] break
	# Draw first anchor	
	createAnchor 1 $l_canvas_x $l_canvas_y -show 1
	# Increment the anchor count
	set anchor_count 1
	# Draw next anchor point and connecting line
	createAnchor 2 $l_canvas_x $l_canvas_y -show 1 -line 1
	# Set up bindings for mask completion
	bind $canvas <Motion> [code $this moveNextAnchor %x %y]
	bind $canvas <1> [code $this addAnchor %x %y]
	# set plotted flag
	set plotted 1
	# Turn on masks
	[.image component masks] invoke
    } elseif {$a_method == "xml"} {
	# Must have 4 anchors if it was serialized
	set anchor_count 4
	# Parse the anchor coordinates
	foreach i_anchor { 1 2 3 4 } {
	    foreach i_coord { x y } {
		set $i_coord${i_anchor}_mm [$args getAttribute "$i_coord${i_anchor}_mm"]
	    }
	}
    } elseif {$a_method == "initialize"} {
	foreach { x1 y1 x2 y2 x3 y3 x4 y4 } $args break
	#puts $args
	foreach i_anchor { 1 2 3 4 } {
	    foreach i_coord { x y } {
		eval set "$i_coord${i_anchor}_mm" $$i_coord${i_anchor}
		#puts "$i_coord${i_anchor}_mm"
		#eval puts $$i_coord${i_anchor}_mm
	    }
	    # Convert to canvas coordinates
	    foreach { x y } [m2cCoords [list [set x${i_anchor}_mm] [set y${i_anchor}_mm]]] break
	    #puts "Adding anchor $i_anchor with canvas coords. x=$x, y=$y"
	    addAnchor $x $y
	    moveNextAnchor $x $y
	    # set plotted flag
	    set plotted 1
	    # Turn on masks
	    [.image component masks] invoke
	}
    } else {
	error "Unknown Mask build method"
    }
}


body Mask::createAnchor { a_num a_x a_y args } {
    options { -show 0 -line 0 -dash {} } $args
    $canvas create image $a_x $a_y \
	-image $anchor_image \
	-tags [list mask \
		   overlay($this) \
		   mask($mask_number) \
		   mask_anchor \
		   mask_anchor($mask_number) \
		   mask_anchor_${a_num}($mask_number)]
    if {$options(-line)} {
	$canvas create line $a_x $a_y $a_x $a_y \
	    -fill green \
	    -dash { 2 2 } \
	    -tags [list mask \
		       overlay($this) \
		       mask($mask_number) \
		       mask_line($mask_number) \
		       mask_line_[expr $a_num - 1]_${a_num}($mask_number)]
    }
}

body Mask::moveNextAnchor { x y } {
    set l_next_anchor [expr $anchor_count + 1]
    # move anchor
    $canvas coords mask_anchor_${l_next_anchor}($mask_number) $x $y
    # move line
    set l_line_coords [$canvas coords mask_line_${anchor_count}_${l_next_anchor}($mask_number)]
    set l_new_line_coords [concat [lrange $l_line_coords 0 1] $x $y]
    $canvas coords mask_line_${anchor_count}_${l_next_anchor}($mask_number) $l_new_line_coords
}

body Mask::addAnchor { x y } {
    #puts "addAnchor x=$x y=$y"
    # increment the anchor count
    incr anchor_count
    # store precvious anchor in mm
    foreach  [list x${anchor_count}_mm y${anchor_count}_mm] [c2mCoords [list $x $y]] break
    # if that's not enough anchors (4)...
    if {$anchor_count < 4} {
	# Draw next anchor point and connecting line
	createAnchor [expr $anchor_count + 1] $x $y -show 1 -line 1
    } else {
	# otherwise complete mask...
	# delete lines
	$canvas delete mask_line($mask_number)
	# Create shaded polygon on canvas
	
	if {[tk windowingsystem] != "aqua"} {
	    set polygonFillColour green
	} {
	    set polygonFillColour systemTransparent
	}
	#puts "Anchor coords. [getAnchorCoords]"
	$canvas create polygon [getAnchorCoords] \
	    -fill $polygonFillColour \
	    -outline green \
	    -stipple @[file join $::env(MOSFLM_GUI) bitmaps mask.xbm] \
	    -tags [list mask \
		       overlay($this) \
		       mask($mask_number) \
		       mask($this) \
		       mask_polygon($mask_number) \
		       clickable_spotfinding_param]
	# Trigger prediction
	$::session updatePredictions
	# Reset bindings
	setupCreationBindings
    }

}

body Mask::select { } {
    # Setup delete bindings
    bind $canvas <Delete> [list Mask::deleteMask $mask_number]
    bind $canvas <BackSpace> [list Mask::deleteMask $mask_number]
    # Hide all anchors
    $canvas itemconfigure mask_anchor -image ""
    # show this mask's anchor
    $canvas itemconfigure mask_anchor($mask_number) -image ::img::mask_anchor_green5x5
    $canvas raise mask_anchor($mask_number)
}

body Mask::getAnchorCoords { } {
    set l_poly_coords {}
    set i_anchor 1
    while {$i_anchor <= $anchor_count} {
	# Build list of mask coordinates in canvas frame
	eval lappend l_poly_coords [m2cCoords [list [set x${i_anchor}_mm] [set y${i_anchor}_mm]]]
	incr i_anchor
    }
    return $l_poly_coords
}

body Mask::plot { } {
    if {[tk windowingsystem] != "aqua"} {
	set polygonFillColour green
    } {
	set polygonFillColour systemTransparent
    }

    clear
    set l_poly_coords [getAnchorCoords]
    set i_anchor 1
    foreach { i_x i_y } $l_poly_coords {
	createAnchor $i_anchor $i_x $i_y
	incr i_anchor
    }
    if {$anchor_count == 4} {
	$canvas create polygon $l_poly_coords \
	    -fill $polygonFillColour \
	    -outline green \
	    -stipple @[file join $::env(MOSFLM_GUI) bitmaps mask.xbm] \
	    -tags [list mask \
		       overlay($this) \
		       mask($mask_number) \
		       mask($this) \
		       mask_polygon($mask_number) \
		       clickable_spotfinding_param]
    } else {
	# Create lines for all exiting segments (if there are any)
	if {[llength $l_poly_coords] >= 4} {
	    $canvas create line $l_poly_coords \
		-fill green \
		-dash { 2 2 } \
		-tags [list mask \
			   overlay($this) \
			   mask($mask_number) \
			   mask_line($mask_number)]
	}
	# Add final line and anchor
	eval createAnchor [expr $anchor_count + 1] [lrange $l_poly_coords end-1 end]
	$canvas create line [concat [lrange $l_poly_coords end-1 end] [lrange $l_poly_coords end-1 end]] \
	    -fill green \
	    -dash { 2 2 } \
	    -tags [list mask \
		       overlay($this) \
		       mask($mask_number) \
		       mask_line($mask_number) \
		       mask_line_${anchor_count}_[expr $anchor_count + 1]($mask_number)]
    }
    set plotted 1
}

# Editing

body Mask::highlight { } {
    $canvas itemconfigure mask_anchor_${current_anchor}($mask_number) -image ::img::mask_anchor_gold5x5
    set highlighted_overlay $this
}

body Mask::unhighlight { } {
    $canvas itemconfigure mask_anchor($mask_number) -image ::img::mask_anchor_green5x5
    set highlighted_overlay ""
}

body Mask::getTip { } {
    return "[set x${current_anchor}_mm],[set y${current_anchor}_mm]mm"
}

body Mask::highlightMask { } {
	$canvas itemconfigure mask_polygon($mask_number) -fill pink -outline pink
}

body Mask::unhighlightMask { } {
    if {[tk windowingsystem] != "aqua"} {
	$canvas itemconfigure mask_polygon($mask_number) -fill green -outline green
    } {
	$canvas itemconfigure mask_polygon($mask_number) -fill systemTransparent -outline green
    }
}

body Mask::drag { a_x a_y a_rootx a_rooty} {
     # Move anchor
    $canvas coords mask_anchor_${current_anchor}($mask_number) $a_x $a_y
    # Store anchor coords in mm
    foreach  [list x${current_anchor}_mm y${current_anchor}_mm] [c2mCoords [list $a_x $a_y]] break
    # Move polygon
    $canvas coords mask_polygon($mask_number) [getAnchorCoords]
    popTooltip $a_rootx $a_rooty [getTip]
}

body Mask::drop { } {
    # Trigger prediction
    $::session updatePredictions
    # Restore bindings
    setupEditBindings
}

body Mask::getDistance { a_x a_y } {
    set l_min_distance 999999
# should have four points, but if the mask isn't complete we have to test for that
    if { $anchor_count == 4 } {
	foreach i_anchor { 1 2 3 4 } {
	    set l_new_distance [calcDistance [list $a_x $a_y] [$canvas coords mask_anchor_${i_anchor}($mask_number)]]
	    if {$l_new_distance < $l_min_distance} {
		set l_min_distance $l_new_distance
		set current_anchor $i_anchor
	    }
	}
    }
    return $l_min_distance
}

body Mask::getMmCoords { } {
    return [list $x1_mm $y1_mm $x2_mm $y2_mm $x3_mm $y3_mm $x4_mm $y4_mm]
}

body Mask::serialize { } {
    if {$anchor_count == 4} {
	return "<mask x1_mm=\"$x1_mm\" y1_mm=\"$y1_mm\" x2_mm=\"$x2_mm\" y2_mm=\"$y2_mm\" x3_mm=\"$x3_mm\" y3_mm=\"$y3_mm\" x4_mm=\"$x4_mm\" y4_mm=\"$y4_mm\"/>"
    } else {
	return ""
    }
}


# class imv {
#     method getMasterPixel { args } { return [list 0 0] }
# }
# imv .image

# pack [canvas .c -bg white -takefocus 1] 
# Mask::setupCreationBindings .c
