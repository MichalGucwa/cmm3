# $Id: toolbutton.tcl,v 1.8 2010/01/21 16:02:26 rmk65 Exp $
package provide toolbutton 4.0

class Toolbutton {
    inherit Balloonwidget

    private common groups ; # array
    private proc releaseRadioGroup

    protected variable mode 0
    private variable tags {}

    private variable old_group ""

    private method enter
    private method leave
    protected method execute

    public method invoke
    public method cancel
    public method toggle
    public method query

    itk_option define -image image Image "" {
	if {$itk_option(-image) != ""} {
	    $itk_component(button) configure \
		-image $itk_option(-image) \
		-width [expr [image width $itk_option(-image)] + 4] \
		-height [expr [image height $itk_option(-image)] + 4]
	}
    }
    itk_option define -group group Group "" {
	if {$itk_option(-group) != ""} {
	    # remove from old group
	    if {$old_group != ""} {
		set l_pos [lsearch $group($old_group) $this]
		set groups($old_group) [lreplace $groups($old_group) $l_pos $l_pos]
	    }
	    # set new group
	    lappend groups($itk_option(-group)) $this
	}
    }

    itk_option define -disabledimage diabledImage Image ""
    itk_option define -activeimage activeImage Image ""
    itk_option define -type type Type "amodal"
    itk_option define -command command Command ""
    itk_option define -state state State "normal" {
	# If the toolbutton has been disabled
	if {$itk_option(-state) == "disabled"} {
	    # Show the disabled imgage (if there is one)
	    if {$itk_option(-disabledimage) != ""} {
		$itk_component(button) configure -image $itk_option(-disabledimage)
	    }
	    # Trigger "leave"
	    leave
	    # Turn the button off
	    set mode 0
	    # Remove mouse-over bindings
	    bind $itk_component(button) <Enter> {}
	    bind $itk_component(button) <Leave> {}
	    # Remove 'Button' bindings
	    set tags [bindtags $itk_component(button)]
	    set tag_pos [lsearch $tags "Button"]
	    if {$tag_pos > -1} {
		bindtags $itk_component(button) [lreplace $tags $tag_pos $tag_pos]
	    }
	} else {
	    # else it must be normal!
	    if {$itk_option(-image) != ""} {
		$itk_component(button) configure -image $itk_option(-image)
	    }
	    # Don't fiddle with mode!
	    #set mode 0
	    # Set up mouse-over bindings
	    bind $itk_component(button) <Enter> [code $this enter]
	    bind $itk_component(button) <Leave> [code $this leave]
	    # Restore 'Button' bindings
	    set tags [bindtags $itk_component(button)]
	    if {[lsearch $tags "Button"] == -1} {
		set tag_pos [lsearch $tags $itk_component(button)]
		incr tag_pos
		bindtags $itk_component(button) [linsert $tags $tag_pos "Button"]
	    }
	}  
    }

    constructor { args } { }
}

body Toolbutton::constructor { args } {
    # Remove default enter/leave bindings
    bind $itk_component(hull) <Enter> {}
    bind $itk_component(hull) <Leave> {}
    
    itk_component add button {
	button $itk_interior.button \
	    -relief flat \
	    -command [code $this execute] \
	    -takefocus 0 \
	    -highlightthickness 0
    }
    pack $itk_component(button)

    eval itk_initialize $args

}

body Toolbutton::releaseRadioGroup { a_group a_toolbutton } {
    foreach i_toolbutton $groups($a_group) {
	if {$i_toolbutton != $a_toolbutton} {
	    $i_toolbutton cancel
	}
    }
}

body Toolbutton::enter { } {
    Balloonwidget::enter
    if {($itk_option(-type) == "amodal") || ($mode == 0)} {
	$itk_component(button) configure -relief raised
    }
}

body Toolbutton::leave { } {
    Balloonwidget::leave
    if {($itk_option(-type) == "amodal") || ($mode == 0)} {
	$itk_component(button) configure -relief flat
    }
}

body Toolbutton::execute { } {
    # Take focus to force setting updates
    focus $itk_component(button)
    if {$itk_option(-type) == "modal"} {
	if {$mode == 0} {
	    set mode 1
	    $itk_component(button) configure -relief sunk -bg "\#eeeeee" -activebackground "\#eeeeee"
	    if {[tk windowingsystem] == "aqua"} {
		if {$itk_option(-activeimage) != ""} {
		    $itk_component(button) configure -image $itk_option(-activeimage)
		}
	    }
	} else {
	    set mode 0
	    $itk_component(button) configure -relief raised -bg "\#dcdcdc" -activebackground "\#dcdcdc"
	    if {[tk windowingsystem] == "aqua"} {
		if {$itk_option(-image) != ""} {
		    $itk_component(button) configure -image $itk_option(-image)
		}
	    }
	}
	if {$itk_option(-command) != ""} {
	    uplevel \#0 $itk_option(-command) $mode
	}
    } elseif  {$itk_option(-type) == "radio"} {
	if {$mode == 0} {
	    set mode 1
	    # deselect other radios in group
	    releaseRadioGroup $itk_option(-group) $this
	    $itk_component(button) configure -relief sunk -bg "\#eeeeee" -activebackground "\#eeeeee"
	    if {[tk windowingsystem] == "aqua"} {
		if {$itk_option(-activeimage) != ""} {
		    $itk_component(button) configure -image $itk_option(-activeimage)
		}
	    }
	    if {$itk_option(-command) != ""} {
		uplevel \#0 $itk_option(-command) $mode
	    }
	}	
    } else {
	if {$itk_option(-command) != ""} {
	    uplevel \#0 $itk_option(-command)
	}
    }
}

body Toolbutton::invoke { { execute "execute" } } {
    if {($itk_option(-type) != "amodal")} {
	if {$mode == 0} {
	    set mode 1
	    $itk_component(button) configure -relief sunk -bg "\#eeeeee" -activebackground "\#eeeeee"
	    if {[tk windowingsystem] == "aqua"} {
		if {$itk_option(-activeimage) != ""} {
		    $itk_component(button) configure -image $itk_option(-activeimage)
		}
	    }
	}
	if {$execute == "execute"} {
	    if {$itk_option(-command) != ""} {
		uplevel \#0 $itk_option(-command) $mode
	    }
	}
    } else {
	if {$execute == "execute"} {
	    if {$itk_option(-command) != ""} {
		uplevel \#0 $itk_option(-command)
	    }
	}
    }
}

body Toolbutton::toggle { { execute "execute" } } {
    $itk_component(button) invoke $execute
}

body Toolbutton::cancel { { execute "execute" } } {
    if {(($itk_option(-type) != "amodal") && ($mode == 1))} {
	set mode 0
	$itk_component(button) configure -relief flat -bg "\#dcdcdc" -activebackground "\#dcdcdc"
	if {[tk windowingsystem] == "aqua"} {
	    if {$itk_option(-image) != ""} {
		$itk_component(button) configure -image $itk_option(-image)
	    }
	}
	if {$execute == "execute"} {
	    if {$itk_option(-command) != ""} {
		uplevel \#0 $itk_option(-command) $mode
	    }
	}
    }
}

body Toolbutton::query { } {
    if {$itk_option(-type) != "amodal"} {
	return $mode
    } else {
	return ""
    }
}

usual Toolbutton {}
