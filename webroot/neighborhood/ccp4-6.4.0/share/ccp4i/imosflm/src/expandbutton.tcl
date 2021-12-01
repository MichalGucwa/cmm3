#!/usr/local/bin/wish8.4
# $Id: expandbutton.tcl,v 1.10 2011/01/10 17:23:41 ccb Exp $
package provide expandbutton 1.0

package require palette
package require iconlibrary

class ExpandButton {

    inherit itk::Widget

    itk_option define -state state State "normal" {
	if {$itk_option(-state) == "normal"} {
	    $itk_component(hull) configure -takefocus 1
	    $itk_component(button) configure -state "normal"
	    $itk_component(expander) configure -image ::img::expand9x9
	    bind $itk_component(expander) <1> [code $this expand]
	    bind $itk_component(hull) <Key-space> [list tk::ButtonInvoke $itk_component(button)]
	    bind $itk_component(hull) <Key-Down> [code $this expand]
	} elseif {$itk_option(-state) == "disabled"} {
	    $itk_component(hull) configure -takefocus 0
	    $itk_component(button) configure -state "disabled"
	    $itk_component(expander) configure -image ::img::expand_disabled9x9
	    bind $itk_component(expander) <1> {}
	    bind $itk_component(hull) <Key-space> {}
	    bind $itk_component(hull) <Key-Down> {}
	} elseif {$itk_option(-state) == "semi"} {
	    $itk_component(hull) configure -takefocus 1
	    $itk_component(button) configure -state "normal"
	    $itk_component(expander) configure -image ::img::expand_disabled9x9
	    bind $itk_component(expander) <1> {}
	    bind $itk_component(hull) <Key-space> [list tk::ButtonInvoke $itk_component(button)]
	    bind $itk_component(hull) <Key-Down> {}
	} else {
	    error "Invalid state for ExpandButton: $itk_option(-state)"
	}
    }
    private variable command_count 0
    private variable extra_commands ;# array
    #private variable extra_command_labels {}

    public method expand
    public method cancel
    public method add
    public method choose
    public method getCommandCount

    constructor { args } { }

}

body ExpandButton::constructor { args } {

    itk_option add hull.takefocus
    itk_option add hull.highlightbackground
    itk_option add hull.highlightcolor
    itk_option add hull.highlightthickness

    $itk_component(hull) configure \
	-takefocus 1 \
	-highlightbackground "#dcdcdc" \
	-highlightthickness 1

    itk_component add button {
	button $itk_interior.button \
	    -takefocus 0 \
	    -highlightbackground "#dcdcdc" \
	    -highlightthickness 0
    } {
	keep -text
	keep -image
	keep -command
	keep -width
	keep -pady
    }

    itk_component add expander {
	label $itk_interior.expander \
	    -image ::img::expand7x7 \
	    -takefocus 0 \
	    -highlightthickness 0 \
	    -relief raised \
	    -borderwidth 2
    }

    bind $itk_component(expander) <1> [code $this expand]

    pack $itk_component(button) -side left
    pack $itk_component(expander) -side left -fill y

    itk_component add palette {
	Palette .\#auto \
	    -alignwidget $itk_component(hull) \
	    -relief raised \
	    -borderwidth 1
    }

    # bindings

    bind $itk_component(hull) <Key-space> [list tk::ButtonInvoke $itk_component(button)]
    bind $itk_component(hull) <Key-Down> [code $this expand]

    eval itk_initialize $args
}

body ExpandButton::expand { } {
    $itk_component(palette) launch $itk_component(hull)
}

body ExpandButton::cancel { args } {
}

body ExpandButton::add { a_label a_command } {
    set extra_commands($command_count) $a_command

    itk_component add label$command_count {
	label $itk_component(palette).label$command_count \
	    -text $a_label -height 2
    } {
	keep -font
    }

    if {$command_count < 1} {
	if {[tk windowingsystem] == "aqua"} {
	    itk_component add exit_frame {
		frame $itk_component(palette).ef
	    }

	    itk_component add exit_button {
		button $itk_component(palette).ef.eb -text "x" \
		    -command [code $itk_component(palette) dismiss]
	    }
	    pack $itk_component(exit_frame) -side right -fill y
	    pack $itk_component(exit_button) -side top
	}
	pack $itk_component(label$command_count) -side right
    }

    pack $itk_component(label$command_count) -side top
    bind $itk_component(label$command_count) <Enter> [list $itk_component(label$command_count) configure -foreground \#ffffff -background \#3399ff]
    bind $itk_component(label$command_count) <Leave> [list $itk_component(label$command_count) configure -foreground \#000000 -background \#dcdcdc]
    bind $itk_component(label$command_count) <1> [code $this choose $command_count]
    bind $itk_component(label$command_count) <ButtonRelease-1> [code $this choose $command_count]
    incr command_count
}

body ExpandButton::choose { an_index } {
    $itk_component(palette) dismiss
    uplevel \#0 $extra_commands($an_index)
}

body ExpandButton::getCommandCount { } {
	return $command_count
}

usual ExpandButton { }
    
