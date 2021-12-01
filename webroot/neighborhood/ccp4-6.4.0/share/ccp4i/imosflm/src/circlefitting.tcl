# $Id: circlefitting.tcl,v 1.10 2010/12/08 12:31:36 ccb Exp $
package provide circlefitting 1.0

class CircleFit {
    inherit Marking

    private common singleton ""

    private variable frame ""
    private variable button ""
    private variable beam_check ""
    private variable backstop_check ""

    private variable centre_beam 1
    private variable centre_backstop 1

    public proc launch
    public proc clear
    public proc replot
    private proc setupCircleFitBindings
    private proc removeCircleFitBindings
    public proc raiseIcons
    public proc parseCircle

    # member variables
    private variable point_count 0
    private variable points ; # array
    private variable centre {}
    private variable radius {}  
    private variable highlighted_point ""
    private common highlighted_button ""
    
    public method click
    public method addPoint
    public method deletePoint
    public method deletePoints
    public method plot
    private method fit
    public method apply
    public method resetCircle
    public method highlightButton
    public method unhighlightButton
    public method highlightPoint
    public method unhighlightPoint
    public method parse
    private method showCircle

    
    constructor { a_canvas } { }
}

body CircleFit::launch { a_canvas } {
    if {$singleton == ""} {
	set singleton [namespace current]::[CircleFit \#auto $a_canvas]
    } else {
	$singleton resetCircle
    }
    setupCircleFitBindings
    $singleton plot
}

body CircleFit::clear { } {
    removeCircleFitBindings
    $canvas delete circle_fit($singleton)
}

body CircleFit::replot { } {
    $singleton plot
}

body CircleFit::resetCircle { } {
    set point_count 0
    array unset points *
    set centre {}
    set radius ""
}

body CircleFit::setupCircleFitBindings { } {
    $canvas configure -cursor cross
    bind $canvas <ButtonPress-1> [code $singleton click %x %y]
}

body CircleFit::removeCircleFitBindings { } {
    $canvas configure -cursor left_ptr
    bind $canvas <ButtonPress-1> {}
}

body CircleFit::constructor { a_canvas } {
    set canvas $a_canvas
    set frame [frame $canvas.frame \
		   -relief solid \
		   -bd 1 \
		   -background gold]
    set button [button $frame.button \
		    -relief solid \
		    -bd 1 \
		    -background gold \
		    -activebackground gold \
		    -highlightbackground gold \
		    -font font_b \
		    -text "Apply" \
		    -command [code $this apply]]
    set beam_check [gcheckbutton $frame.beam \
			-style flat \
			-background gold \
			-variable [scope centre_beam] \
			-font font_b \
			-text "Centre beam"]
    set backstop_check [gcheckbutton $frame.backstop \
			    -style flat \
			    -background gold \
			    -variable [scope centre_backstop] \
			    -font font_b \
			    -text "Centre backstop"]
    pack $button $beam_check $backstop_check \
	-fill x \
	-padx 2 \
	-pady 2

	    toplevel .circleFitLabel \
		-border 0
#Adding tooltip to circlefitting icons
		wm overrideredirect .circleFitLabel 1
		if {[tk windowingsystem] == "aqua"} {
#	    ::tk::unsupported::MacWindowStyle style $itk_component(data_labels) floating sideTitlebar
	    ::tk::unsupported::MacWindowStyle style .circleFitLabel help none
		}
		wm withdraw .circleFitLabel

	    label .circleFitLabel.l1 \
		-text "?"\
		-relief solid \
		-highlightthickness 0 \
		-bd 2 

		pack .circleFitLabel.l1 -fill x

#    wm deiconify .circleFitLabel
#    raise .circleFitLabel
#######################################

}

body CircleFit::click { a_x a_y } {
    # Deal with button clicks
    if {$highlighted_button == "fit_beam_headup"} {
	apply -centre_beam 1
    } elseif  {$highlighted_button == "fit_backstop_headup"} {
	apply -centre_backstop 1
    } elseif  {$highlighted_button == "clear_circle_headup"} {
	deletePoints
    } else {
	# add/remove points
	if {$highlighted_point == ""} { 
	    addPoint $a_x $a_y
	} else {
	    deletePoint $highlighted_point
	    set highlighted_point ""
	}
    }
}

body CircleFit::addPoint { a_x a_y } {
    # Unset circle
    set centre {}
    set radius ""

    # Increment the point count
    incr point_count
    
    # Create marker
    $canvas create image $a_x $a_y \
	-image ::img::circle_point7x7 \
	-tags [list circle_fit($this) \
		   circle_point($this) \
		   circle_point_${point_count}($this)]

    # Get mm coords
    set l_coords_mm [c2mCoords [list $a_x $a_y]]
    
    # Store in points list
    set points($point_count) $l_coords_mm

    # Set up point deletion binding
    $canvas bind circle_point_${point_count}($this) <Enter> [code $this highlightPoint $point_count]
    $canvas bind circle_point_${point_count}($this) <Leave> [code $this unhighlightPoint $point_count]
    $canvas bind circle_point_${point_count}($this) <1> "[code $this deletePoint $point_count] ; break"

    # Delete circle
    $canvas delete circle($this)
}


body CircleFit::deletePoint { a_point_num} {
    # Unset circle
    set centre {}
    set radius ""

    # Delete marker
    $canvas delete circle_point_${a_point_num}($this)
    
    # Store in points list
    array unset points $a_point_num

    # Delete circle
    $canvas delete circle($this)
}

body CircleFit::deletePoints { } {
    # Delete all points
    foreach i_point_num [array names points] {
	deletePoint $i_point_num
    }
}

body CircleFit::plot { } {
    # delete this circle fit's existing plots
    $canvas delete circle_fit($this)
    # plot all points
    foreach i_point [array names points] {
	$canvas create image [m2cCoords $points($i_point)] \
	    -image ::img::circle_point7x7 \
	    -tags [list circle_fit($this) \
		       circle_point($this) \
		       circle_point_${i_point}($this)]<
	$canvas bind circle_point_${i_point}($this) <Enter> [code $this highlightPoint $i_point]
	$canvas bind circle_point_${i_point}($this) <Leave> [code $this unhighlightPoint $i_point]
    }
    # plot circle if available
    if {($centre != {}) && ($radius != "")} {
	showCircle
    }
    # plot head-up controls
    set l_x [expr [winfo width $canvas] - 5]
    set l_y 5
    $canvas create image $l_x $l_y \
	-anchor ne \
	-image ::img::fit_beam_headup24x24 \
	-tags [list circle_fit($this) \
		   icon \
		   fit_beam_headup($this) ]
    incr l_y 30
    $canvas create image $l_x $l_y \
	-anchor ne \
	-image ::img::fit_backstop_headup24x24 \
	-tags [list circle_fit($this) \
		   icon \
		   fit_backstop_headup($this)]
    incr l_y 30
    $canvas create image $l_x $l_y \
	-anchor ne \
	-image ::img::clear_circle_headup24x24 \
	-tags [list circle_fit($this) \
		   icon \
		   clear_circle_headup($this)]

    $canvas bind fit_beam_headup($this) <1> [code $this apply -centre_beam 1]
    $canvas bind fit_beam_headup($this) <1> [code $this apply -centre_backstop 1]
    $canvas bind clear_circle_headup($this) <1> [code $this deletePoints]

    $canvas bind fit_beam_headup($this) <Enter> [code $this highlightButton fit_beam_headup]
    $canvas bind fit_backstop_headup($this) <Enter> [code $this highlightButton fit_backstop_headup]
    $canvas bind clear_circle_headup($this) <Enter> [code $this highlightButton clear_circle_headup]

    $canvas bind fit_beam_headup($this) <Leave> [code $this unhighlightButton fit_beam_headup]
    $canvas bind fit_backstop_headup($this) <Leave> [code $this unhighlightButton fit_backstop_headup]
    $canvas bind clear_circle_headup($this) <Leave> [code $this unhighlightButton clear_circle_headup]

#     $canvas delete circle_fit_headup
#     $canvas create window [expr [winfo width $canvas] - 5] 5 \
# 	-anchor ne \
# 	-window $frame \
# 	-tags [list circle_fit($this) \
# 		   circle_fit_headup]
    
}

body CircleFit::raiseIcons { } {
    $canvas raise icon
}

body CircleFit::highlightButton { a_button } {
    set highlighted_button $a_button
	if {$highlighted_button eq "fit_beam_headup"} {
		set tooltip_text "Fit beam from circle    "
	} elseif {$highlighted_button eq "fit_backstop_headup"} {
		set tooltip_text "Fit backstop from circle"
	} elseif {$highlighted_button eq "clear_circle_headup"} { 
		set tooltip_text "Clear points and circle "
	} else {
		set tooltip_text "?"
	}
	
    $canvas itemconfigure ${a_button}($this) -image ::img::${a_button}_highlighted24x24
    $canvas configure -cursor hand2
#Some new code to add tooltips to the three buttons for circle fitting
    set tooltipx [expr [winfo pointerx $canvas] - 100]
    set tooltipy [expr [winfo pointery $canvas] - 25]
	    .circleFitLabel.l1 configure \
		-text $tooltip_text \
		-fg black \
		-bg white \
		-anchor e

    wm geometry .circleFitLabel \+$tooltipx\+$tooltipy 
    wm deiconify .circleFitLabel
    raise .circleFitLabel

}

body CircleFit::unhighlightButton { a_button } {
    set highlighted_button ""
    $canvas itemconfigure ${a_button}($this) -image ::img::${a_button}24x24

    $canvas configure -cursor cross
	wm withdraw .circleFitLabel
}

body CircleFit::highlightPoint { a_point } {
    $canvas itemconfigure circle_point_${a_point}($this) -image ::img::circle_point_selected7x7
    set highlighted_point $a_point
}

body CircleFit::unhighlightPoint { a_point } {
    $canvas itemconfigure circle_point_${a_point}($this) -image ::img::circle_point7x7
    set highlighted_point ""
}

body CircleFit::apply { args } {
    options {-centre_beam 0 -centre_backstop 0} $args
    set centre_beam $options(-centre_beam)
    set centre_backstop $options(-centre_backstop)
    set l_points {}
    foreach i_point [array names points] {
	eval lappend l_points [m2pCoords $points($i_point)]
    }
    $::mosflm fitCircle $l_points
}

body CircleFit::parseCircle { a_dom } {
    $singleton parse $a_dom
}

body CircleFit::parse { a_dom } {
    set centre [list [$a_dom selectNodes normalize-space(/circle_fitting_response/circle_centre_x)] [$a_dom selectNodes normalize-space(/circle_fitting_response/circle_centre_y)]]
    set radius [$a_dom selectNodes normalize-space(/circle_fitting_response/radius)]

    showCircle

    if {$centre_beam} {
	[.image component beam] invoke
	$::session updateSetting beam_x [lindex $centre 0] 1 1 "User"
	$::session updateSetting beam_y [lindex $centre 1] 1 1 "User"
    }
    if {$centre_backstop} {
	[.image component masks] invoke
	$::session updateSetting backstop_x [lindex $centre 0] 1 1 "User"
	$::session updateSetting backstop_y [lindex $centre 1] 1 1 "User"
	$::session updateSetting backstop_radius $radius 1 1 "User"
    }

}

body CircleFit::showCircle { } {
    plotCircle $centre $radius \
	-outline gold \
	-tags [list circle_fit($this) \
		   circle($this)]
    foreach { l_x0 l_y0 } [m2cCoords $centre] break
    set l_r [m2c $radius]
    set l_x1 [expr $l_x0 - $l_r]
    set l_x2 [expr $l_x0 + $l_r]
    set l_y1 [expr $l_y0 - $l_r]
    set l_y2 [expr $l_y0 + $l_r]
    $canvas create line $l_x1 $l_y0 $l_x2 $l_y0 \
	-fill gold \
	-tags [list circle_fit($this) \
		   circle($this)]
    $canvas create line $l_x0 $l_y1 $l_x0 $l_y2 \
	-fill gold \
	-tags [list circle_fit($this) \
		   circle($this)]
    $canvas raise circle_point($this)
}
