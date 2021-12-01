# $Id: overlays.tcl,v 1.9 2010/12/08 12:31:55 ccb Exp $
package provide overlays 1.0

class Marking {

    # Common data members ######################

    # Canvas
    protected common canvas ""

    # view information
    protected common display_size_x ""
    protected common display_size_y ""
    protected common left_x ""
    protected common top_y ""
    protected common zoom ""
    protected common pixel_size ""
    
    # Procedures ###############################
    
    # unit conversions
    protected proc m2c ;# millimetres to canvas units
    protected proc c2m ;# canvas units to millmetres

    # coordinate conversions
    protected proc m2cCoords
    public proc c2mCoords
    protected proc m2pCoords ;# millimetres to pixel

    # geometry
    protected proc calcDistance
    
    # generic shape plotting
    protected proc plotCircle
    protected proc stippleOutCircle

    # view information
    public proc updateViewInformation
}

body Marking::updateViewInformation { a_left_x a_top_y a_zoom a_pixel_size a_display_size_x a_display_size_y  a_detector_size_x a_detector_size_y} {
    set left_x $a_left_x
    set top_y $a_top_y
    set zoom $a_zoom
    set pixel_size $a_pixel_size
    set display_size_x $a_display_size_x
    set display_size_y $a_display_size_y
	
	#added by luke on 9 November 2007. 
	#This is a bit of a hack. Now that the image display window is resizable, the code in the method
	#Imagedisplay::resizeWindow changes display_size_x and ...y to the size of the main frame. Previously,
	#these variables would remain unchanged, but now, if the window is smaller than the canvas the calculations in
	#HighResLimit::stippleOutCircle are become messed up. I don't really understand the code in the method so I did the following 
	#I have added two extra arguments ie a_detector_size_x and a_detector_size_y and the if statement below. As a result,
	#the display_size variables are maintained at their full settings and are not affected when the size of the window becomes smaller
	#than the canvas.
	#I also had to change the arguments passed in Imagedisplay::updateView which calls this method and pass the 
	#detector_size variables. Now the stippling bug is fixed although at some point I will have to really tidy up
	#all the code
	if {$zoom <= 1} {
		set display_size_x [expr $a_detector_size_x * $zoom]
		set display_size_y [expr $a_detector_size_y * $zoom]
	}
	if {$zoom > 1} {
		set display_size_x $a_detector_size_x 
		set display_size_y $a_detector_size_y
	}
	############################################################################
}

body Marking::m2c { a_mm } {
    return [expr ($a_mm / $pixel_size) * $zoom]
}

body Marking::c2m { a_canvas_dist } {
    return [expr (double($a_canvas_dist)/$zoom) * $pixel_size]
}

body Marking::m2cCoords { a_coords_mm } {
    foreach { l_x_mm l_y_mm } $a_coords_mm break
    set l_x_canvas [expr (($l_x_mm / $pixel_size) - ($left_x - 1)) * $zoom]
    set l_y_canvas [expr (($l_y_mm / $pixel_size) - ($top_y - 1)) * $zoom]
    return [list $l_x_canvas $l_y_canvas]
}

body Marking::c2mCoords { a_coords_canvas } {
    foreach { l_x_canvas l_y_canvas } $a_coords_canvas break
    set l_x_mm [expr ((double($l_x_canvas)/$zoom) + ($left_x - 1)) * $pixel_size]
    set l_y_mm [expr ((double($l_y_canvas)/$zoom) + ($top_y - 1)) * $pixel_size]
    return [list $l_x_mm $l_y_mm]
}

body Marking::m2pCoords { a_coords_mm } {
    foreach { l_x_mm l_y_mm } $a_coords_mm break
#     set t_x [expr ((($l_x_mm / $pixel_size) - $left_x) * $zoom) + ($zoom / 2)] 
#     set t_y [expr ((($l_y_mm / $pixel_size) - $top_y) * $zoom) + ($zoom / 2)]
#     return [list $t_x $t_y]
    return [list [expr $l_x_mm / $pixel_size] [expr $l_y_mm / $pixel_size]]
}

body Marking::calcDistance { a_pos1 a_pos2 args } {
    options {-precision 2} $args
    foreach {l_x1 l_y1} $a_pos1 break
    foreach {l_x2 l_y2} $a_pos2 break
    set l_dist [expr sqrt(pow($l_x2 - $l_x1,2)+pow($l_y2 - $l_y1,2))]
    return [format %.$options(-precision)f $l_dist]
}
    
body Marking::plotCircle { a_centre_mm a_radius_mm args } {
    foreach {l_x_canvas l_y_canvas} [m2cCoords $a_centre_mm] break
    set l_radius_canvas [expr ($a_radius_mm / $pixel_size) * $zoom]
    set l_x1 [expr $l_x_canvas - $l_radius_canvas]
    set l_y1 [expr $l_y_canvas - $l_radius_canvas]
    set l_x2 [expr $l_x_canvas + $l_radius_canvas]
    set l_y2 [expr $l_y_canvas + $l_radius_canvas]
    return [eval $canvas create oval $l_x1 $l_y1 $l_x2 $l_y2 $args]
}

body Marking::stippleOutCircle { a_centre_mm a_radius_mm a_step args } {

    foreach {x0 y0 } [m2cCoords $a_centre_mm] break
    set r [m2c $a_radius_mm]
    set coords {}
    set ix [expr $x0 - $r]
    if {$ix < 0} {
	set ix 0
    }
    while {($ix < ($x0 + $r)) && ($ix <= $display_size_y)} {
	set t_side_squared [expr pow($r,2)-pow($ix-$x0,2)]
	if {$t_side_squared < 0} {
	    set t_side_squared 0
	}
	set iy_p [expr $y0 + sqrt($t_side_squared)]
	set iy_n [expr $y0 - sqrt($t_side_squared)]
	if {$iy_p < 0 } {
	    set iy_p 0 
	} elseif {$iy_p > $display_size_y } {
	    set iy_p $display_size_y
	}
	if {$iy_n < 0 } {
	    set iy_n 0
	} elseif {$iy_n > $display_size_y } {
	    set iy_n $display_size_y
	}
	set coords [linsert $coords 0 $ix]
	set coords [linsert $coords 1 $iy_p]
	set coords [linsert $coords end $ix]
	set coords [linsert $coords end $iy_n]
	set ix [expr $ix + $a_step]
    }

#     lappend coords [expr $x0 + $r] $y0
#     lappend coords $display_size_x $y0
#     lappend coords $display_size_x 0
#     lappend coords 0 0
#     lappend coords 0 $display_size_y
#     lappend coords $display_size_x $display_size_y
#     lappend coords $display_size_x $y0
#     lappend coords [expr $x0 + $r] $y0

    if {($x0 + $r) < $display_size_x} {
	set coords [linsert $coords 0 [expr $x0 + $r]]
	set coords [linsert $coords 1 $y0]
	set coords [linsert $coords end [expr $x0 + $r]]
	set coords [linsert $coords end $y0]
    }

    lappend coords [expr $display_size_x + 10] [expr $display_size_y / 2]
    lappend coords [expr $display_size_x + 10] -10 
    lappend coords -10 -10 
    lappend coords -10 [expr $display_size_y + 10]
    lappend coords [expr $display_size_x + 10] [expr $display_size_y + 10]
    lappend coords [expr $display_size_x + 10] [expr $display_size_y / 2]

    eval $canvas create polygon $coords $args
}


class Overlay {
    inherit Marking

    # Common data members ######################

    # overlays
    protected common overlays {}
    protected common overlays_by_parameter ; # array
    protected common dependencies ; #array

    # parameters
    protected common beam_x "0"
    protected common beam_y "0"
    protected common backstop_x "0"
    protected common backstop_y "0"
    protected common backstop_radius "5"
    protected common search_area_min_radius "0"
    protected common search_area_max_radius "0"
    protected common bbox_orientation "North"
    protected common bbox_offset "0"
    protected common low_resolution_limit ""
    protected common high_resolution_limit ""

    protected common distance ""
    protected common wavelength ""
    protected common two_theta ""

    # overlay editing
    protected common highlighted_overlay ""
    private common edit_bindings_on "0"
    private common tool_tip ""
    private common overlay_entry ""

    # Procedures ###############################
    
    # debugging
    public proc debug

    # initialization
    public proc initialize

    # related parameters
    public proc udpateParameter

    # "by parameter" accessors
    public proc plotParameter
    public proc clearParameter

    # generic resolution elipse plotting
    protected proc plotResElipse

    # overlay editing
    public proc setupEditBindings
    public proc removeEditBindings
    public proc editsBound
    public proc highlightNearest
    public proc unhighlightAll
    public proc editClick
    public proc launchEntry
    protected proc refreshAll
    protected proc plotIcons
    protected proc popTooltip
    protected proc dropTooltip

    # external updates
    public proc updateParameter

    # Member variables #########################

    # parameter
    protected variable parameter ""
    protected variable units "mm"
    protected variable group ""

    # generic overlay properties
    protected variable colour ""
    protected variable fill_colour ""
    protected variable highlight_colour "gold"
    protected variable stipple ""
    protected variable icon ""
    protected variable highlighted_icon ""
    protected variable handle_id ""

    # plotted or not flag
    protected variable plotted "0"

    # methods ##################################

    public method isPlotted { } { return $plotted }
    public method refresh
    public method plot ; # virtual
    public method isReachable
    public method plotIcon
    public method highlightIcon
    public method unhighlightIcon
    public method getTip
    public method getGroup
    public method clear
    public method highlight
    public method unhighlight
    public method beginEdit
    public method drag ; # virtual
    public method drop
    public method getDistance { a_x a_y } { error "Virtual funciton called." }

    constructor { } {
	lappend overlays $this
    }

    destructor {
	clear
	set l_index [lsearch $overlays $this]
	set overlays [lreplace $overlays $l_index $l_index]
    }
}

body Overlay::initialize { a_canvas } {
    set tool_tip [OverlayToolTip .\#auto]
    set overlay_entry [OverlayEntry .\#auto]
    set canvas $a_canvas
    MaxSearchRadius \#auto
    MinSearchRadius \#auto
    HighResLimit \#auto
    LowResLimit \#auto
    BackstopCentre \#auto
    BackstopRadius \#auto
    BeamCentre \#auto
    BackgroundBox \#auto
}

body Overlay::plotParameter { a_parameter } {
    if {[info exists overlays_by_parameter($a_parameter)]} {
	$overlays_by_parameter($a_parameter) plot
    }
}

body Overlay::clearParameter { a_parameter } {
    if {[info exists overlays_by_parameter($a_parameter)]} {
	$overlays_by_parameter($a_parameter) clear
    }
}

body Overlay::plotResElipse { a_resolution a_obj } {

    
}

body Overlay::setupEditBindings { } {
    set edit_bindings_on 1
    bind $canvas <Enter> {}
    bind $canvas <Leave> [list Overlay::unhighlightAll]
    bind $canvas <Motion> [list Overlay::highlightNearest %x %y %X %Y -halo 5]
    bind $canvas <ButtonPress-1> [list Overlay::editClick %x %y %X %Y]
    bind $canvas <ButtonRelease-1> {}
    bind $canvas <Double-ButtonPress-1> [list Overlay::launchEntry %x %y %X %Y]
    plotIcons
}

body Overlay::removeEditBindings { } {
    set edit_bindings_on 0
    bind $canvas <Enter> {}
    bind $canvas <Leave> {}
    bind $canvas <Motion> {}
    bind $canvas <ButtonPress-1> {}
    bind $canvas <ButtonRelease-1> {}
    bind $canvas <Double-ButtonPress-1> {}
    plotIcons
}

body Overlay::editsBound { } {
    return $edit_bindings_on
}

body Overlay::editClick { a_x a_y a_rootx a_rooty } {
    highlightNearest $a_x $a_y $a_rootx $a_rooty 
    if {$highlighted_overlay != ""} {
	$highlighted_overlay beginEdit $a_x $a_y $a_rootx $a_rooty
    }
}

body Overlay::launchEntry { a_x a_y a_rootx a_rooty } {
    highlightNearest $a_x $a_y $a_rootx $a_rooty 
    if {$highlighted_overlay != ""} {
	$overlay_entry launch $a_rootx $a_rooty [$highlighted_overlay getGroup]
	$highlighted_overlay unhighlight
    }
}

body Overlay::refreshAll { } {
    foreach i_overlay $overlays {
	$i_overlay refresh
    }
}

body Overlay::plotIcons { } {
    $canvas delete overlay_icon
    if {[editsBound]} {
	set l_x 5
	set l_y 5
	foreach i_overlay $overlays {
	    if {[$i_overlay isPlotted] && ![$i_overlay isReachable]} {
		if {[$i_overlay plotIcon $l_x $l_y]} {
		    incr l_y 30
		}
	    }
	}
    }
    # Raise circle fitting icons
    CircleFit::raiseIcons
}

body Overlay::popTooltip { args } {
    eval $tool_tip pop $args
}

body Overlay::dropTooltip { } {
    $tool_tip drop
}

body Overlay::highlightNearest { a_x a_y a_rootx a_rooty args } {
    options {-halo 5} $args
    set l_overlay ""
    set l_shortest_dist $options(-halo)
    foreach i_overlay $overlays {
	if {[$i_overlay isPlotted]} {
	    set l_new_dist [$i_overlay getDistance $a_x $a_y]
	    if {$l_new_dist < $l_shortest_dist} {
		set l_overlay $i_overlay
		set l_shortest_dist $l_new_dist
	    }
	} else {
	}
    }
    if {$l_overlay != ""} {
	if {($highlighted_overlay != $l_overlay) &&
	    ($highlighted_overlay != "")} {
	    $highlighted_overlay unhighlight
	}
	$l_overlay highlight
	popTooltip $a_rootx $a_rooty [$l_overlay getTip]
    } else {
	if {$highlighted_overlay != ""} {
	    $highlighted_overlay unhighlight
	    dropTooltip
	}
    }
}

body Overlay::unhighlightAll { } {
    if {$highlighted_overlay != ""} {
	$highlighted_overlay unhighlight
    }
    dropTooltip
}

body Overlay::updateParameter { a_parameter a_value } {
    set $a_parameter $a_value
    if {[info exists dependencies($a_parameter)]} {
	foreach i_overlay $dependencies($a_parameter) {
	    $i_overlay refresh
	}
    }
}

# Methods ##################################

body Overlay::refresh { } {
    if {$plotted} {
	plot
    }
}

body Overlay::isReachable { } {
    set l_items [$canvas find overlapping 5 5 [expr [winfo width $canvas] - 5] [expr [winfo height $canvas] - 5]]
    if {[lsearch $l_items $handle_id] != -1} {
	return 1
    } else {
	return 0
    }	 
}

body Overlay::plotIcon { a_x a_y } {
    $canvas create image $a_x $a_y \
	-anchor nw \
	-image $icon \
	-tag [list overlay($this) \
		  icon($this) \
		  icon \
		  overlay_icon]
    if {[editsBound]} {
	$canvas bind icon($this) <Enter> [code $this highlightIcon %X %Y]
	$canvas bind icon($this) <1> [code $this beginEdit %x %y %X %Y]
	$canvas bind icon($this) <Leave> [code $this unhighlightIcon]
    }
    return 1
}

body Overlay::highlightIcon { a_rootx a_rooty } {
    if {$highlighted_icon != ""} {
	$canvas itemconfigure icon($this) -image $highlighted_icon	
    }
    popTooltip $a_rootx $a_rooty [getTip]
}

body Overlay::unhighlightIcon { } {
    if {$highlighted_icon != ""} {
	$canvas itemconfigure icon($this) -image $icon
    }
    dropTooltip
}

body Overlay::getTip { } {
    return "[format %.2f [set $parameter]]$units"
}

body Overlay::getGroup { } {
    return $group
}

body Overlay::clear { } {
    $canvas delete overlay($this)
    set plotted 0
}

body Overlay::highlight { } {
    $canvas itemconfigure highlight($this) -outline $highlight_colour
    set highlighted_overlay $this
}

body Overlay::unhighlight { } {
    $canvas itemconfigure highlight($this) -outline $colour
    set highlighted_overlay ""
}

body Overlay::beginEdit { a_x a_y a_rootx a_rooty } {
    bind $canvas <Motion> [code $this drag %x %y %X %Y]
    bind $canvas <ButtonRelease-1> [code $this drop]
    drag $a_x $a_y $a_rootx $a_rooty
}

body Overlay::drop { } {
    $::session updateSetting $parameter [set $parameter] 1 1 "User" 1
    setupEditBindings
    dropTooltip
}

# Circular Overlays ###################################

class CircularOverlay {
    inherit Overlay

    protected variable centre_x "beam_x"
    protected variable centre_y "beam_y"

    public method getDistance
    public method drag
}


body CircularOverlay::drag { a_x a_y a_rootx a_rooty } {
    set l_point_mm [c2mCoords [list $a_x $a_y]]
    set l_new_radius_mm [calcDistance [list [set $centre_x] [set $centre_y]] $l_point_mm]
    plot -radius $l_new_radius_mm -highlight 1
    popTooltip $a_rootx $a_rooty [getTip]
}

body CircularOverlay::getDistance { a_x a_y } {
    set l_point_mm [c2mCoords [list $a_x $a_y]]
    # Calculate radius at cursor position
    set l_cursor_radius_mm [calcDistance [list [set $centre_x] [set $centre_y]] $l_point_mm]
    # return difference between cursor radius and circle radius
    return [m2c [expr abs($l_cursor_radius_mm - [set $parameter])]]
}

# Minimum spot search radius ##########################

class MinSearchRadius {
    inherit CircularOverlay

    # member variables
    
    # methods
    
    public method plot

    constructor { } { }
}

body MinSearchRadius::constructor { } {
    set parameter "search_area_min_radius"
    set group "min_search_radius"
    set overlays_by_parameter($parameter) $this
    lappend dependencies($parameter) $this
    lappend dependencies(beam_x) $this
    lappend dependencies(beam_y) $this
    
    set colour red
    set fill_colour red
    if {[tk windowingsystem] == "aqua"} {
	set fill_colour {}
    }
    set stipple  "@[file join $::env(MOSFLM_GUI) bitmaps min_search_radius.xbm]"
    set icon ::img::min_search_radius_headup24x24
    set highlighted_icon ::img::min_search_radius_headup_highlighted24x24
}

body MinSearchRadius::plot { args } {
    options [list -radius [set $parameter] -highlight 0] $args
    # update centre and radius in case passed as options
    set $parameter $options(-radius)
    # set ring colour
    if {$options(-highlight) == 0} {
	set l_colour $colour
    } else {
	set l_colour $highlight_colour
    }
    # clear existing plot from canvas
    clear
    # plot stippled out circle
    plotCircle [list $beam_x $beam_y] [set $parameter] \
	-stipple $stipple \
	-outline $l_colour \
	-fill $fill_colour \
	-tags [list overlay($this)]
    set handle_id [plotCircle [list $beam_x $beam_y] [set $parameter] \
		       -outline $l_colour \
		       -tags [list overlay($this) \
				  highlight($this)]]

    # set plotted flag
    set plotted 1
    plotIcons
}    

# Maximum spot search radius ##########################

class MaxSearchRadius {
    inherit CircularOverlay

    # member variables
    
    # methods
    
    public method plot

    constructor { } { }
}

body MaxSearchRadius::constructor { } {
    set parameter "search_area_max_radius"
    set group "max_search_radius"
    set overlays_by_parameter($parameter) $this
    lappend dependencies($parameter) $this
    lappend dependencies(beam_x) $this
    lappend dependencies(beam_y) $this
    
    set colour red
    set fill_colour red
    if {[tk windowingsystem] == "aqua"} {
	set fill_colour {}
    }
    set stipple  "@[file join $::env(MOSFLM_GUI) bitmaps max_search_radius.xbm]"
    set icon ::img::max_search_radius_headup24x24
    set highlighted_icon ::img::max_search_radius_headup_highlighted24x24
}

body MaxSearchRadius::plot { args } {
    options [list -radius [set $parameter] -highlight 0] $args
    # update centre and radius in case passed as options
    set $parameter $options(-radius)
    # set ring colour
    if {$options(-highlight) == 0} {
	set l_colour $colour
    } else {
	set l_colour $highlight_colour
    }
    # clear existing plot from canvas
    clear
    # plot stippled outside circle
    stippleOutCircle [list $beam_x $beam_y] [set $parameter] 1 \
	-stipple $stipple \
	-fill $fill_colour \
	-tags [list overlay($this) msr]
    set handle_id [plotCircle [list $beam_x $beam_y] [set $parameter] \
		       -outline $l_colour \
		       -tags [list overlay($this) \
				  highlight($this)]]
    # set plotted flag
    set plotted 1
    plotIcons
}    

# Beam centre  ########################################################

class BeamCentre {
    inherit Overlay
    
    public method plot
    public method highlight
    public method unhighlight
    public method drag
    public method drop
    public method getDistance
    public method getTip

    constructor { } { }
}

body BeamCentre::constructor { } {
    set group "beam"
    set overlays_by_parameter(beam_x) $this
    set overlays_by_parameter(beam_y) $this
    lappend dependencies(beam_x) $this
    lappend dependencies(beam_y) $this

    set icon ::img::beam_headup24x24
    set highlighted_icon ::img::beam_headup_highlighted24x24
}

body BeamCentre::plot { args } {
    set l_pos [m2cCoords [list $beam_x $beam_y]]
    clear
    set handle_id [$canvas create image $l_pos \
		       -image ::img::beam_green7x7 \
		       -tags [list overlay($this) \
				 centre($this)]]
    set plotted 1
    plotIcons
}


body BeamCentre::highlight { } {
    $canvas itemconfigure centre($this) -image ::img::beam_gold7x7
    set highlighted_overlay $this
}

body BeamCentre::unhighlight { } {
    $canvas itemconfigure centre($this) -image ::img::beam_green7x7    
    set highlighted_overlay ""
}

body BeamCentre::drag { a_x a_y a_rootx a_rooty } {
    foreach { beam_x beam_y } [c2mCoords [list $a_x $a_y]] break
    plot
    popTooltip $a_rootx $a_rooty [getTip]
}

body BeamCentre::getTip { } {
    return "[format %.2f $beam_x],[format %.2f $beam_y]mm"
}

body BeamCentre::drop { } {
    $::session updateSetting beam_x $beam_x 1 1 "User" 0
    $::session updateSetting beam_y $beam_y 1 1 "User" 1
    setupEditBindings
    dropTooltip
}

body BeamCentre::getDistance { a_x a_y } {
    # get point in mm
    set l_point_mm [c2mCoords [list $a_x $a_y]]
    # Calculate difference from beam pos and convert to canvas units
    return [m2c [calcDistance [list $beam_x $beam_y] $l_point_mm]]
}    

# Backstop centre  ########################################################

class BackstopCentre {
    inherit Overlay
    
    public method plot
    public method highlight
    public method unhighlight
    public method drag
    public method drop
    public method getDistance
    public method getTip

    constructor { } { }
}

body BackstopCentre::constructor { } {
    set group "backstop"
    set overlays_by_parameter(backstop_x) $this
    set overlays_by_parameter(backstop_y) $this
    lappend dependencies(backstop_x) $this
    lappend dependencies(backstop_y) $this
    
    set icon ::img::backstop_headup24x24
    set highlighted_icon ::img::backstop_headup_highlighted24x24
}

body BackstopCentre::plot {  } {
    set l_pos [m2cCoords [list $backstop_x $backstop_y]]
    clear
    set handle_id [$canvas create image $l_pos \
		       -image ::img::backstop_centre_green7x7 \
		       -tags [list overlay($this) \
				 centre($this)]]
    set plotted 1
    plotIcons
}


body BackstopCentre::highlight { } {
    $canvas itemconfigure centre($this) -image ::img::backstop_centre_gold7x7
    set highlighted_overlay $this
}

body BackstopCentre::unhighlight { } {
    $canvas itemconfigure centre($this) -image ::img::backstop_centre_green7x7
    set highlighted_overlay ""
}

body BackstopCentre::drag { a_x a_y a_rootx a_rooty } {
    foreach { backstop_x backstop_y } [c2mCoords [list $a_x $a_y]] break
    $canvas coords overlay($this) $a_x $a_y
    $overlays_by_parameter(backstop_radius) refresh
    popTooltip $a_rootx $a_rooty [getTip]
}

body BackstopCentre::getTip { } {
    return "[format %.2f $backstop_x],[format %.2f $backstop_y]$units"
}

body BackstopCentre::drop { } {
    $::session updateSetting backstop_x $backstop_x 1 1 "User" 0
    $::session updateSetting backstop_y $backstop_y 1 1 "User" 1
    setupEditBindings
    dropTooltip
}

body BackstopCentre::getDistance { a_x a_y } {
    # get point in mm
    set l_point_mm [c2mCoords [list $a_x $a_y]]
    # Calculate difference from backstop pos and convert to canvas units
    return [m2c [calcDistance [list $backstop_x $backstop_y] $l_point_mm]]
}

# Backstop radius  ########################################################

class BackstopRadius {
    inherit CircularOverlay
    
    public method plot
    #public method plotIcon { a_x a_y } {return 0}

    constructor { } { }
}

body BackstopRadius::constructor { } {
    set centre_x "backstop_x"
    set centre_y "backstop_y"
    set parameter "backstop_radius"
    set group "backstop"

    set overlays_by_parameter($parameter) $this
    lappend dependencies($parameter) $this
    lappend dependencies(backstop_x) $this
    lappend dependencies(backstop_y) $this
    
    set colour green
    set fill_colour green
    if {[tk windowingsystem] == "aqua"} {
	set fill_colour {}
    }
    set stipple  "@[file join $::env(MOSFLM_GUI) bitmaps backstop.xbm]"
    set icon ::img::backstop_radius_headup24x24
    set highlighted_icon ::img::backstop_radius_headup_highlighted24x24
}

body BackstopRadius::plot { args } {
    options [list -radius [set $parameter] -highlight 0] $args
    # update centre and radius in case passed as options
    set $parameter $options(-radius)
    # set ring colour
    if {$options(-highlight) == 0} {
	set l_colour $colour
    } else {
	set l_colour $highlight_colour
    }
    # clear existing plot from canvas
    clear
    # plot stippled out circle
    plotCircle [list $backstop_x $backstop_y] [set $parameter] \
	-stipple $stipple \
	-outline $l_colour \
	-fill $fill_colour \
	-tags [list overlay($this)]
    set handle_id [plotCircle [list $backstop_x $backstop_y] [set $parameter] \
		       -outline $l_colour \
		       -tags [list overlay($this) \
				  highlight($this)]]
    set plotted 1
    plotIcons
    # set plotted flag
}

# Background box #######################################################

class BackgroundBox {
    inherit Overlay

#	private variable width "20"
    private variable width "7.7"
    private variable x1 ""
    private variable y1 ""
    private variable x2 ""
    private variable y2 ""

    public method plot
    public method drag
    public method drop
    public method getDistance
    public method getTip

    public method plotIcon

    constructor { } { }
}

body BackgroundBox::constructor { } {
    set group "bbox"
    set overlays_by_parameter(bbox_orientation) $this
    set overlays_by_parameter(bbox_offset) $this
    lappend dependencies(bbox_orientation) $this
    lappend dependencies(bbox_offset) $this
    lappend dependencies(search_area_min_radius) $this
    lappend dependencies(search_area_max_radius) $this
    lappend dependencies(beam_x) $this
    lappend dependencies(beam_y) $this
    
    set colour "red"
    set fill_colour "red"
    if {[tk windowingsystem] == "aqua"} {
	set fill_colour {}
    }
    set stipple  "@[file join $::env(MOSFLM_GUI) bitmaps bbox.xbm]"
    #set icon ::img::spot_search_min_radius16x16
    #set highlighted_icon ::img::spot_search_min_radius_highlighted16x16

}

body BackgroundBox::plot { } {
    $canvas delete overlay($this)
    if {$bbox_orientation == "North"} {
	set y1 [expr $beam_y - $search_area_max_radius]
	set y2 [expr $beam_y - $search_area_min_radius]
	set x1 [expr $beam_x - ($width / 2) + $bbox_offset]
	set x2 [expr $beam_x + ($width / 2) + $bbox_offset]
    } elseif {$bbox_orientation == "South"} {
	set y1 [expr $beam_y + $search_area_min_radius]
	set y2 [expr $beam_y + $search_area_max_radius]
	set x1 [expr $beam_x - ($width / 2) + $bbox_offset]
	set x2 [expr $beam_x + ($width / 2) + $bbox_offset]
    } elseif {$bbox_orientation == "West"} {
	set x1 [expr $beam_x - $search_area_max_radius]
	set x2 [expr $beam_x - $search_area_min_radius]
	set y1 [expr $beam_y - ($width / 2) + $bbox_offset]
	set y2 [expr $beam_y + ($width / 2) + $bbox_offset]
    } elseif {$bbox_orientation == "East"} {
	set x1 [expr $beam_x + $search_area_min_radius]
	set x2 [expr $beam_x + $search_area_max_radius]
	set y1 [expr $beam_y - ($width / 2) + $bbox_offset]
	set y2 [expr $beam_y + ($width / 2) + $bbox_offset]
    } else {
	error "Bad background box orientation: $bbox_orientation"
    }
#	puts $x1
#	puts $x2
#	puts $y1
#	puts $y2
    foreach {l_x1_c l_y1_c} [m2cCoords [list $x1 $y1]] break
    foreach {l_x2_c l_y2_c} [m2cCoords [list $x2 $y2]] break
    set handle_id [$canvas create rectangle $l_x1_c $l_y1_c $l_x2_c $l_y2_c \
		       -outline $colour \
		       -fill $fill_colour \
		       -stipple $stipple \
		       -tags [list overlay($this) \
				  highlight($this)]]
    set plotted 1
    plotIcons
}

body BackgroundBox::drag { a_x a_y a_rootx a_rooty } {
    # convert point to mm
    foreach { l_x l_y } [c2mCoords [list $a_x $a_y]] break
    # Swap orientation ?
    set l_dx [expr $l_x - $beam_x]
    set l_dy [expr $l_y - $beam_y]
    if {abs($l_dx) > abs($l_dy)} {
	if {$l_dx > 0} {
	    set bbox_orientation "East"
	} else {
	    set bbox_orientation "West"
	}
    } else {
	if {$l_dy > 0} {
	    set bbox_orientation "South"
	} else {
	    set bbox_orientation "North"
	}
    }
    # Calc offset
    if {($bbox_orientation == "North") ||
	($bbox_orientation == "South")} {
	set bbox_offset $l_dx
    } else {
	set bbox_offset $l_dy
    }
    plot
    popTooltip $a_rootx $a_rooty [getTip]
}

body BackgroundBox::getTip { } {
    return "$bbox_orientation;${bbox_offset}mm"
}

body BackgroundBox::drop { } {
    $::session updateSetting bbox_orientation $bbox_orientation 1 1 "User" 0
    $::session updateSetting bbox_offset $bbox_offset 1 1 "User" 1
    setupEditBindings
    dropTooltip

}

body BackgroundBox::getDistance { a_x a_y } {
    foreach { l_x l_y } [c2mCoords [list $a_x $a_y]] break
    if {($l_x >= $x1) &&
	($l_x <= $x2) &&
	($l_y >= $y1) &&
	($l_y <= $y2)} {
	# in box so return 0
	return 0
    } else {
	# outside box - just return very large value
	return 99999
    }    
}

body BackgroundBox::plotIcon { a_x a_y } {
    # Doesn't need one!
    return 0
}

# Generic resolution limits

class ResLimit {
    inherit Overlay

    protected method chartElipse
}

# Max resolution limit ################################################

class HighResLimit {
    inherit Overlay

    private variable radius_mm ""

    public method plot
    public method drag
    public method getDistance

    constructor { } { }
}

body HighResLimit::constructor { } {
    set parameter "high_resolution_limit"
    set units "\u212b"
    set group "high_res_limit"
    set overlays_by_parameter($parameter) $this
    lappend dependencies($parameter) $this
    lappend dependencies(beam_x) $this
    lappend dependencies(beam_y) $this
    lappend dependencies(distance) $this
    lappend dependencies(wavelength) $this
    lappend dependencies(two_theta) $this
    
    set colour "blue"
    set fill_colour "blue"
    if {[tk windowingsystem] == "aqua"} {
	set fill_colour {}
    }
    set stipple  "@[file join $::env(MOSFLM_GUI) bitmaps high_res_limit.xbm]"
    set icon ::img::high_res_limit_headup24x24
    set highlighted_icon ::img::high_res_limit_headup_highlighted24x24
}

body HighResLimit::plot { args } {
    options {-highlight 0} $args
    # set ring colour
    if {$options(-highlight) == 0} {
	set l_colour $colour
    } else {
	set l_colour $highlight_colour
    }
    # clear existing plot from canvas
    clear
    # Just plot as circle if 2theta is zero
    if {[format %.2f $two_theta] == "0.00"} {
	if {[set $parameter] == "infinity"} {
	    set radius_mm 0
	} elseif {[set $parameter] == 0} {
	    set radius_mm 9999999
	} elseif {[set $parameter] == ""} {
#		$::session updateSetting $parameter 0 1 1
		set radius_mm 9999999
	} else {
	    set radius_mm [expr $distance * tan(2 * asin($wavelength / (2 * [set $parameter])))]
	}	
	# plot stippled outside circle
	stippleOutCircle [list $beam_x $beam_y] $radius_mm 1 \
	    -stipple $stipple \
	    -fill $fill_colour \
	    -tags [list overlay($this)]
	set handle_id [plotCircle [list $beam_x $beam_y] $radius_mm \
			   -outline $l_colour \
			   -tags [list overlay($this) \
				      highlight($this)]]
	set plotted 1
	plotIcons
    } else {
	if {1} {
	    puts "Cannot plot resolution when two-theta is not zero"
	} else {
	    # If just a point, or off infinite, plot as a circle
	    set l_circle_flag 0
	    if {[set $parameter] == "infinity"} {
		set radius_mm 0
	    } elseif {[set $parameter] == 0} {
		set radius_mm 9999999
		set l_circle_flag 1
	    }
	    if {$l_circle_flag} {
		# plot stippled outside circle
		stippleOutCircle [list $beam_x $beam_y] $radius_mm 1 \
		    -stipple $stipple \
		    -fill $fill_colour \
		    -tags [list overlay($this)]
		set handle_id [plotCircle [list $beam_x $beam_y] $radius_mm \
				   -outline $l_colour \
				   -tags [list overlay($this) \
					      highlight($this)]]   
	    } else {
		# Plot as elipse (To be done!)
	    }
	}
    }
}

body HighResLimit::drag { a_x a_y a_rootx a_rooty } {
    # Convert coordinates to mm
    foreach { l_x_mm l_y_mm } [c2mCoords [list $a_x $a_y]] break
    if {[format %.2f $two_theta] == "0.00"} {
	set radius_mm [expr sqrt(pow($l_x_mm - $beam_x,2)+pow($l_y_mm - $beam_y,2))]
	if {$radius_mm == 0} {
	    set high_resolution_limit 999999999
	} elseif {$distance == 0} {
	    set high_resolution_limit 0
	} else {
	    set high_resolution_limit [format %.2f [expr $wavelength / (2 * sin(0.5 * atan($radius_mm / $distance)))]]
	}
	plot -highlight 1
    } else {
	puts "Cannot plot resolution when two-theta is not zero"
    }
    popTooltip $a_rootx $a_rooty [getTip]

}

body HighResLimit::getDistance { a_x a_y } {
    # Convert coordinates to mm
    set l_cursor_coords_mm [c2mCoords [list $a_x $a_y]]
    if {[format %.2f $two_theta] == "0.00"} {
	set l_new_radius_mm [calcDistance $l_cursor_coords_mm [list $beam_x $beam_y]]
	set l_distance_mm [expr abs($radius_mm - $l_new_radius_mm)]
	
	return [m2c $l_distance_mm]
    } else {
	puts "Cannot calculate distance when two-theta is not zero"
	return 99999
    }
}


# Low resolution limit ################################################

class LowResLimit {
    inherit Overlay

    private variable radius_mm ""

    public method plot
    public method drag
    public method getDistance

    constructor { } { }
}

body LowResLimit::constructor { } {
    set parameter "low_resolution_limit"
    set units "\u212b"
    set group "low_res_limit"
    set overlays_by_parameter($parameter) $this
    lappend dependencies($parameter) $this
    lappend dependencies(beam_x) $this
    lappend dependencies(beam_y) $this
    lappend dependencies(distance) $this
    lappend dependencies(wavelength) $this
    lappend dependencies(two_theta) $this
    
    set colour "blue"
    set fill_colour "blue"
    if {[tk windowingsystem] == "aqua"} {
	set fill_colour {}
    }
    set stipple  "@[file join $::env(MOSFLM_GUI) bitmaps low_res_limit.xbm]"
    set icon ::img::low_res_limit_headup24x24
    set highlighted_icon ::img::low_res_limit_headup_highlighted24x24

}

body LowResLimit::plot { args } {
    options {-highlight 0} $args
    # set ring colour
    if {$options(-highlight) == 0} {
	set l_colour $colour
    } else {
	set l_colour $highlight_colour
    }
    # clear existing plot from canvas
    clear
    # Just plot as circle if 2theta is zero
    if {[format %.2f $two_theta] == "0.00"} {
	if {[set $parameter] == "infinity"} {
	    set radius_mm 0
	} elseif {[set $parameter] == 0} {
	    set radius_mm 9999999
	} else {
	    set radius_mm [expr $distance * tan(2 * asin($wavelength / (2 * [set $parameter])))]
	}
	# plot circle
	plotCircle [list $beam_x $beam_y] $radius_mm \
	    -outline $l_colour \
	    -stipple $stipple \
	    -fill $fill_colour \
	    -tags [list overlay($this)]
	set handle_id [plotCircle [list $beam_x $beam_y] $radius_mm \
			   -outline $l_colour \
			   -tags [list overlay($this) \
				      highlight($this)]]
	# set plotted flag
	set plotted 1
	plotIcons
    } else {
	puts "Cannot plot resolution when two-theta is not zero"
    }
}

body LowResLimit::drag { a_x a_y a_rootx a_rooty } {
    # Convert coordinates to mm
    foreach { l_x_mm l_y_mm } [c2mCoords [list $a_x $a_y]] break
    if {[format %.2f $two_theta] == "0.00"} {
	set radius_mm [expr sqrt(pow($l_x_mm - $beam_x,2)+pow($l_y_mm - $beam_y,2))]
	if {$radius_mm == 0} {
	    set low_resolution_limit 999999999
	} elseif {$distance == 0} {
	    set low_resolution_limit 0
	} else {
	    set low_resolution_limit [format %.2f [expr $wavelength / (2 * sin(0.5 * atan($radius_mm / $distance)))]]
	}
	plot -highlight 1
    } else {
	puts "Cannot plot resolution when two-theta is not zero"
    }
    popTooltip $a_rootx $a_rooty [getTip]
}

body LowResLimit::getDistance { a_x a_y } {
    # Convert coordinates to mm
    set l_cursor_coords_mm [c2mCoords [list $a_x $a_y]]
    if {[format %.2f $two_theta] == "0.00"} {
	set l_new_radius_mm [calcDistance $l_cursor_coords_mm [list $beam_x $beam_y]]
	set l_distance_mm [expr abs($radius_mm - $l_new_radius_mm)]
	
	return [m2c $l_distance_mm]
    } else {
	puts "Cannot calculate distance when two-theta is not zero"
	return 99999
    }
}

########################################################################

body Overlay::debug { } {
}

# source imosflm/src/imosflm.tcl

# #######################################################################

class OverlayToolTip {
    inherit itk::Toplevel

    public method pop
    public method drop

    constructor { args } {
	wm withdraw $itk_component(hull)
	wm overrideredirect $itk_component(hull) 1
	if {[tk windowingsystem] == "aqua"} {
	    #::tk::unsupported::MacWindowStyle style $itk_component(hull) floating sideTitlebar
	    ::tk::unsupported::MacWindowStyle style $itk_component(hull) help none 
	}

	itk_component add label {
	    label $itk_interior.label \
		-relief solid \
		-borderwidth 2 \
		-bg gold \
		-font font_b
	} {
	    usual
	    ignore -font
	}
	pack $itk_component(label)
    }
}
 

body OverlayToolTip::pop { a_x a_y a_text } {
    set l_x $a_x
    set l_y [expr $a_y + 20]
    $itk_component(label) configure -text " $a_text "
    set l_width [winfo width $itk_component(label)]
    set l_height [winfo height $itk_component(label)]
    set l_screenwidth [winfo screenwidth .]
    set l_screenheight [winfo screenheight .]
    if {[expr ($l_x + $l_width) > ($l_screenwidth - 5)]} {
	set l_x [expr $l_x - $l_width - 5]
    } 
    if {[expr ($l_y + $l_height) > ($l_screenheight - 5)]} {
	set l_x [expr $l_y - $l_height - 5]
    } 
    wm geometry $itk_component(hull) +$l_x+$l_y
    wm deiconify $itk_component(hull)
    raise $itk_component(hull)
}

body OverlayToolTip::drop { } {
    wm withdraw $itk_component(hull)
}

#################################################################

class OverlayEntry {
    inherit itk::Toplevel
    
    private variable widgets_by_group ; # array
    private variable ungrab_queue ""

    public method launch
    public method click
    public method dismiss

    constructor { args } {

	wm withdraw $itk_component(hull)
	wm overrideredirect $itk_component(hull) 1
	if {[tk windowingsystem] == "aqua"} {
	    #::tk::unsupported::MacWindowStyle style $itk_component(hull) floating sideTitlebar
	    ::tk::unsupported::MacWindowStyle style $itk_component(hull) help none 

	}

 	# beam
	itk_component add beam_x_e {
	    SettingEntry $itk_interior.bxe beam_x \
		-image ::img::beam_x16x16 \
		-balloonhelp "Beam x position" \
		-type real \
		-precision 2 \
		-width 6 \
		-justify right  \
		-relief solid \
		-borderwidth 2 \
		-padxy 0
	}

	itk_component add beam_y_e {
	    SettingEntry $itk_interior.bye beam_y \
		-image ::img::beam_y16x16 \
		-balloonhelp "Beam y position" \
		-type real \
		-precision 2 \
		-width 6 \
		-justify right  \
		-relief solid \
		-borderwidth 2 \
		-padxy 0
	}

	itk_component add backstop_x_e {
	    SettingEntry $itk_interior.x backstop_x \
		-image ::img::backstop_x16x16 \
		-type real \
		-precision 2 \
		-width 6 \
		-justify right \
		-balloonhelp " Backstop centre x " \
		-relief solid \
		-borderwidth 2 \
		-padxy 0
	}
	
	itk_component add backstop_y_e {
	    SettingEntry $itk_interior.y backstop_y \
		-image ::img::backstop_y16x16 \
		-type real \
		-precision 2 \
		-width 6 \
		-justify right \
		-balloonhelp " Backstop centre y " \
		-relief solid \
		-borderwidth 2 \
		-padxy 0
	}
	
	itk_component add backstop_r_e {
	    SettingEntry $itk_interior.bstopr backstop_radius \
		-image ::img::backstop_radius16x16 \
		-type real \
		-precision 2 \
		-width 6 \
		-justify right \
		-balloonhelp " Backstop radius " \
		-relief solid \
		-borderwidth 2 \
		-padxy 0
	}
	
	itk_component add min_radius_e {
	    SettingEntry $itk_interior.minsr search_area_min_radius \
		-image ::img::spot_search_min_radius16x16 \
		-type real \
		-precision 2 \
		-width 6 \
		-justify right \
		-relief solid \
		-borderwidth 2 \
		-padxy 0
	}
	
	itk_component add max_radius_e {
	    SettingEntry $itk_interior.maxsr search_area_max_radius \
		-image ::img::spot_search_max_radius16x16 \
		-type real \
		-precision 2 \
		-width 6 \
		-justify right \
		-relief solid \
		-borderwidth 2 \
		-padxy 0
	}
	
	itk_component add bbox_orientation_c {
	    SettingCombo $itk_interior.boRc bbox_orientation \
		-width 5 \
		-items {North South East West} \
		-editable 0 ;#   -highlightcolor black
	} {
	    usual
	    ignore -textbackground -foreground
	}

	itk_component add bbox_offset_e {
	    SettingEntry $itk_interior.bofe bbox_offset \
		-type real \
		-precision 2 \
		-width 7 \
		-justify right \
		-relief solid \
		-borderwidth 2 \
		-padxy 0
	}

	itk_component add max_res_e {
	    SettingEntry $itk_interior.maxrl high_resolution_limit \
		-image ::img::max_res16x16 \
		-type real \
		-precision 2 \
		-width 5 \
		-justify right \
		-relief solid \
		-borderwidth 2 \
		-padxy 0
	}
	
	itk_component add min_res_e {
	    SettingEntry $itk_interior.minre low_resolution_limit \
		-image ::img::min_res16x16 \
		-type real \
		-precision 2 \
		-width 5 \
		-justify right \
		-relief solid \
		-borderwidth 2 \
		-padxy 0
	}

	# Position widgets
	grid $itk_component(beam_x_e)
	grid $itk_component(beam_y_e)
	grid $itk_component(backstop_x_e)
	grid $itk_component(backstop_y_e)
	grid $itk_component(backstop_r_e)
	grid $itk_component(min_radius_e)
	grid $itk_component(max_radius_e)
	grid $itk_component(bbox_orientation_c)
	grid $itk_component(bbox_offset_e)
	grid $itk_component(min_res_e)
	grid $itk_component(max_res_e)
	
	# Store lists of widgets by group
	lappend widgets_by_group(beam) $itk_component(beam_x_e) $itk_component(beam_y_e)
	lappend widgets_by_group(backstop) $itk_component(backstop_x_e) $itk_component(backstop_y_e) $itk_component(backstop_r_e)
	lappend widgets_by_group(min_search_radius) $itk_component(min_radius_e)
	lappend widgets_by_group(max_search_radius) $itk_component(max_radius_e)
	lappend widgets_by_group(high_res_limit) $itk_component(max_res_e)
	lappend widgets_by_group(low_res_limit) $itk_component(min_res_e)
	lappend widgets_by_group(bbox) $itk_component(bbox_offset_e)
	
	# setup global bindings
	bind $itk_component(hull) <Return> [code $this dismiss]
	bind $itk_component(hull) <Escape> [code $this dismiss]

	eval itk_initialize $args
    }
}

body OverlayEntry::launch { a_x a_y a_group } {
    # Remove all widgets
    eval grid remove [winfo children $itk_interior]
    # Re-grid widgets relevant to new group
    eval grid $widgets_by_group($a_group)

    # Position window
    set l_x $a_x
    set l_y [expr $a_y + 20]
    set l_width [winfo width $itk_component(hull)]
    set l_height [winfo height $itk_component(hull)]
    set l_screenwidth [winfo screenwidth .]
    set l_screenheight [winfo screenheight .]
    if {[expr ($l_x + $l_width) > ($l_screenwidth - 5)]} {
	set l_x [expr $l_x - $l_width - 5]
    } 
    if {[expr ($l_y + $l_height) > ($l_screenheight - 40)]} {
	set l_x [expr $l_y - $l_height - 40]
    } 
    wm geometry $itk_component(hull) +$l_x+$l_y
    wm deiconify $itk_component(hull)
    raise $itk_component(hull)
    focus -force [lindex $widgets_by_group($a_group) 0]
    focus -force [lindex $widgets_by_group($a_group) 0]
    grab -global $itk_component(hull)
    focus -force [lindex $widgets_by_group($a_group) 0]
    set ungrab_queue [after 60000 [code $this dismiss]]
    focus -force [lindex $widgets_by_group($a_group) 0]
    bind $itk_component(hull) <ButtonPress-1> [code $this click %X %Y]
    focus -force [lindex $widgets_by_group($a_group) 0]

}

body OverlayEntry::click { a_x a_y } {
    set l_clicked_widget [winfo containing $a_x $a_y]
    if {($l_clicked_widget == "") || ([winfo toplevel $l_clicked_widget] != $itk_component(hull))} {
	dismiss
    }
}

body OverlayEntry::dismiss { } {
    after cancel $ungrab_queue
    wm withdraw $itk_component(hull)
    grab release $itk_component(hull)
}

usual OverlayEntry {
    keep -background -borderwidth
 }
