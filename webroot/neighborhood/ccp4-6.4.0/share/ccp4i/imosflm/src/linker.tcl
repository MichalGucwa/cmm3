# $Id: linker.tcl,v 1.8 2010/01/21 16:02:25 rmk65 Exp $
package provide linker 1.0

option add *Linker.width 1
option add *Linker.height 1

class Linker {
    inherit itk::Widget

    itk_option define -orient orient Orient "vertical" {
	if {($itk_option(-orient) != "vertical") && ($itk_option(-orient) != "horizontal")} {
	    error "Option '-orient' must be 'vertical' or 'horizontal'"
	} else {
	    draw
	}
    }

    itk_option define -state state State "closed" {
	updateSwitch
    }

    itk_option define -command command Command ""

    itk_option define -pad pad Pad 0 {
	draw
    }

    public method draw
    public method updateSwitch
    public method toggle
    public method enter
    public method leave
    public method query

    constructor { args } {
	
	itk_component add canvas {
	    canvas $itk_interior.c \
		-highlightthickness 0 \
	} {
	    keep -width -height
	    keep -background
	    keep -borderwidth
	}

	pack $itk_component(canvas) -fill both -expand true

	eval itk_initialize $args
	
	bind $itk_component(canvas) <Enter> [code $this enter]
	bind $itk_component(canvas) <Leave> [code $this leave]
	bind $itk_component(canvas) <ButtonPress-1> [code $this toggle]
	bind $itk_component(canvas) <Configure> [code $this draw]

    }
}

body Linker::draw { } {

    set height [winfo height $itk_component(canvas)]
    set width [winfo width $itk_component(canvas)]

    $itk_component(canvas) delete all
    $itk_component(canvas) create rectangle 0 0 $width $height \
	-width 0 \
	-fill [$itk_component(canvas) cget -background] \
	-tag background

    if {$itk_option(-orient) == "vertical"} {
	set y1 [expr $itk_option(-pad) + [$itk_component(canvas) cget -bd]]
	set y2 [expr ($height / 2) - 3]
	set y4  [expr ($height / 2) + 3]
	set y3 [expr $y4 - 4]
	set y5 [expr $height - $itk_option(-pad) - [$itk_component(canvas) cget -bd] - 1]
	set x2 [expr $width / 2]
	set x1 [expr $x2 - 3]
	set x3 [expr $x2 + 4]
	$itk_component(canvas) create line $x1 $y1 $x2 $y1 $x2 $y2 -capstyle round -tag line1
	$itk_component(canvas) create line $x2 $y4 $x2 $y5 $x1 $y5 -capstyle round -tag line2
	$itk_component(canvas) create line $x2 $y4 $x2 $y2 -capstyle round -tag closed
	$itk_component(canvas) create line $x2 $y4 $x3 $y3 -capstyle round -tag open
    } else {
	set x1 [expr $itk_option(-pad) + [$itk_component(canvas) cget -bd]]
	set x2 [expr ($width / 2) - 3]
	set x4  [expr ($width / 2) + 3]
	set x3 [expr $x2 + 4]
	set x5 [expr $width - $itk_option(-pad) - [$itk_component(canvas) cget -bd] - 1]
	set y2 [expr $height / 2]
	set y1 [expr $y2 - 3]
	set y3 [expr $y2 + 4]
	$itk_component(canvas) create line $x1 $y1 $x1 $y2 $x2 $y2 -capstyle round -tag line1
	$itk_component(canvas) create line $x4 $y2 $x5 $y2 $x5 $y1 -capstyle round -tag line2
	$itk_component(canvas) create line $x2 $y2 $x4 $y2 -capstyle round -tag closed
	$itk_component(canvas) create line $x2 $y2 $x3 $y3 -capstyle round -tag open
    }
    updateSwitch
}

body Linker::updateSwitch { } {
    if {$itk_option(-state) == "open"} {
	$itk_component(canvas) raise open background
	$itk_component(canvas) lower closed background
    } else {
	$itk_component(canvas) raise closed background
	$itk_component(canvas) lower open background
    }
}

body Linker::toggle { } {
    if {$itk_option(-state) == "open"} {
	set itk_option(-state) "closed"
    } else {
	set itk_option(-state) "open"
    }
    updateSwitch
    if {$itk_option(-command) != ""} {
	uplevel #0 $itk_option(-command) $itk_option(-state)
    }
}

body Linker::enter { } {
    $itk_component(canvas) configure -relief raised
}

body Linker::leave { } {
    $itk_component(canvas) configure -relief flat
}

body Linker::query { } {
    if {$itk_option(-state) == "closed"} {
	return 1
    } else {
	return 0
    }
}

usual Linker {
    keep -background -cursor
}

