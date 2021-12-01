# $Id: progressbar.tcl,v 1.8 2010/01/21 16:02:25 rmk65 Exp $
package provide progressbar 1.0

class Progressbar {
    inherit itk::Widget

    # options

    itk_option define -colour colour Colour "\#3399ff" {
	update $value $label
    }

    # member variables

    private variable width "0"
    private variable height "1"
    private variable value "0"
    private variable label ""
    private variable label_mode "normal"

    # methods
    
    public method initialize
    public method calibrate
    public method update

    constructor { args } { }

}

body Progressbar::constructor { args } {

    itk_option add hull.borderwidth hull.relief

    $itk_component(hull) configure -relief sunken

    itk_component add canvas {
	canvas $itk_interior.c \
	    -bd 0 \
	    -highlightthickness 0
    } {
	keep -background
	keep -width
	keep -height
    }

    pack $itk_component(canvas) -fill both -expand true

    bind $itk_interior <Configure> [code $this calibrate]
    bind $itk_interior <Expose> [code $this initialize]

    eval itk_initialize $args

}


body Progressbar::update { a_value { a_label "<as was>"} } {

    set width [winfo width $itk_component(canvas)]
    set height [winfo height $itk_component(canvas)]
    $itk_component(canvas) delete all

    set value $a_value
    if {$value != 0} {
	$itk_component(canvas) create rectangle 0 0 [expr $width * $value]  $height \
	    -fill $itk_option(-colour) \
	    -outline $itk_option(-colour)
    }
    if {$a_label == "<percent>"} {
	set label_mode "percent"
    } elseif {$a_label != "<as was>"} {
	set label_mode "normal"
	set label $a_label
    }
    if {$label_mode == "percent"} {
	set label "[expr int($value * 100)]%"
    }
	
    if {$label != ""} {
	$itk_component(canvas) create text [expr $width / 2.0] [expr $height / 2.0] \
	    -text $label
    }
}

body Progressbar::calibrate { } {
    set width [winfo width $itk_component(canvas)]
    set height [winfo height $itk_component(canvas)]
    update $value
}
    
body Progressbar::initialize { } {
    calibrate
    bind $itk_interior <Expose> {}
}
    

usual Progressbar {}

# toplevel .t
# Progressbar .t.p -borderwidth 2 -height 20 -width 200
# pack .t.p -padx 20 -pady 20
