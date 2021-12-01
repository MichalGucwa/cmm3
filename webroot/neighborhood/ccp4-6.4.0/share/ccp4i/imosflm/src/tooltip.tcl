# $Id: tooltip.tcl,v 1.9 2010/12/08 12:32:08 ccb Exp $
package provide gtooltip 1.0

class ToolTip {
    inherit itk::Toplevel

    public method pop
    public method drop
    public method queue
    private method arrive

    private variable queue ""

    constructor { args } {
	wm withdraw $itk_component(hull)
	wm overrideredirect $itk_component(hull) 1
	if {[tk windowingsystem] == "aqua"} {
	    ::tk::unsupported::MacWindowStyle style $itk_component(hull) help none 
	    #::tk::unsupported::MacWindowStyle style $itk_component(hull) floating sideTitlebar
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

	eval itk_initialize $args
    }
}

body ToolTip::queue { args } {
    drop
    set queue [after 750 [eval code $this arrive $args]]
}

body ToolTip::arrive { args } {
    eval pop [winfo pointerxy $itk_component(hull)] $args
}

body ToolTip::pop { a_x a_y args } {
    # Get initial position relative to mouse
    set l_x $a_x
    set l_y [expr $a_y + 20]

    # Configur label
    eval $itk_component(label) configure $args

    # measure label and screen sizes
    set l_width [winfo width $itk_component(label)]
    set l_height [winfo height $itk_component(label)]
    set l_screenwidth [winfo screenwidth .]
    set l_screenheight [winfo screenheight .]

    # if the label won't fit in initial position, move it
    if {[expr ($l_x + $l_width) > ($l_screenwidth - 5)]} {
	set l_x [expr $l_x - $l_width - 5]
    } 
    if {[expr ($l_y + $l_height) > ($l_screenheight - 5)]} {
	set l_x [expr $l_y - $l_height - 5]
    } 
    
    # position and show window
    wm geometry $itk_component(hull) +$l_x+$l_y
    wm deiconify $itk_component(hull)
    raise $itk_component(hull)
}

body ToolTip::drop { } {
    if {$queue != ""} {
	after cancel $queue
    }
    wm withdraw $itk_component(hull)
}
