# $Id: radio.tcl,v 1.8 2010/01/21 16:02:25 rmk65 Exp $
package provide radio 1.0

set radio_off_data "R0lGODlhEAAQAKEAAJCQkAAAAP///////yH+FUNyZWF0ZWQgd2l0aCBUaGUg\nR0lNUAAh+QQBCgADACwAAAAAEAAQAAACMpyPqcsGD9p4oYa3QBVcbKV13SAk\noTiWx4mWqhO0HImwKF3H97saor+YHYSMn+SIRBQAADs="
set radio_on_data "R0lGODlhEAAQAKEAAJCQkAAAAP///////yH+FUNyZWF0ZWQgd2l0aCBUaGUg\nR0lNUAAh+QQBCgADACwAAAAAEAAQAAACNJyPqcsGD9p4oYa3QBVcbKV13SAk\nIbdxJHJagVoerQWzL3qXsZyPu2wQBReqQ5EhlCiXiAIAOw=="
set radio_off_focus_data "R0lGODlhEAAQAKEAAAAAAJCQkP///////yH+FUNyZWF0ZWQgd2l0aCBUaGUg\nR0lNUAAh+QQBCgADACwAAAAAEAAQAAACP8SMpzntD4F5oQYIq5TVyRZIwiiI\nWEiSg9B8aKqyzguzrAvU40rlOv8Z0GKnRsrYmqxkRiZmuXsEn8+EdXEoAAA7"
set radio_on_focus_data "R0lGODlhEAAQAKEAAAAAAJCQkP///////yH+FUNyZWF0ZWQgd2l0aCBUaGUg\nR0lNUAAh+QQBCgADACwAAAAAEAAQAAACQcSMpzntD4F5oQYIq5TVyRZIwiiI\nWEiSg9B86CiOKwXAm8y6dXmzrPPiqXKT4PDUSCVbk9Uv+cQ4ZY+P9JrILg4F\nADs="
set radio_off_disabled_data "R0lGODlhEAAQAMIAAJCQkAAAANzc3P///8nJydzc3Nzc3Nzc3CH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgAHACwAAAAAEAAQAAADOHi63P5QgQnimSGH+UAWoJANjheGBMmYJ6pKQeuusSyktH2/sIw3AALhJOQtBgNh0dhAIi3QaCMBADs="
set radio_on_disabled_data "R0lGODlhEAAQAMIAAJCQkAAAANzc3P///8nJydzc3Nzc3Nzc3CH5BAEKAAcALAAAAAAQABAAAAM8eLrc/lCBCeKZIYf5QBagkA2OF4YEyZjghKpS0FJgusoCBdTwhec7XoN1sg0JhKKxMRggkU1LM2qpWhkJADs="

image create photo radio_on -data $radio_on_data
image create photo radio_off -data $radio_off_data
image create photo radio_on_focus -data $radio_on_focus_data
image create photo radio_off_focus -data $radio_off_focus_data
image create photo radio_on_disabled -data $radio_on_disabled_data
image create photo radio_off_disabled -data $radio_off_disabled_data

#image create photo radiooff -file images/1.gif
#image create photo radioon -file images/2.gif
#image create photo radiooff2 -file images/3.gif
#image create photo radioon2 -file images/4.gif

class Radio {
    inherit itk::Widget
    
    public variable value "0"
    protected variable current_value ""
    private variable oldvariable ""
    
    itk_option define -command comand Command ""
    
    itk_option define -state state State "normal" {
	upvar $itk_option(-variable) var
	if {$itk_option(-state) == "normal"} {
	    bind $itk_component(button) <Button-1> [code $this invoke]
	    bind $itk_component(label) <Button-1> [code $this invoke]
	    bind $itk_component(frame) <space> [code $this invoke]
	    bind $itk_component(frame) <FocusIn> [code $this focusin]
	    bind $itk_component(frame) <FocusOut> [code $this focusout]
	    $itk_component(frame) configure -takefocus 1
	    $itk_component(label) configure -state normal
	    if {$var == $value} {
		$itk_component(button) configure -image radio_on
	    } else {
		$itk_component(button) configure -image radio_off
	    }
	} else {
	    if {[focus] == $itk_component(frame)} {
		focus [tk_focusNext $itk_component(frame)]
	    }
	    bind $itk_component(button) <Button-1> {}
	    bind $itk_component(label) <Button-1> {}
	    bind $itk_component(frame) <space> {}
	    bind $itk_component(frame) <FocusIn> {}
	    bind $itk_component(frame) <FocusOut> {}
	    $itk_component(frame) configure -takefocus 0
	    $itk_component(label) configure -state disabled
	    if {$var == $value} {
		$itk_component(button) configure -image radio_on_disabled
	    } else {
		$itk_component(button) configure -image radio_off_disabled
	    }
	}
    }
    
    
    itk_option define -variable variable Variable "" {
	if {$oldvariable != ""} {
	    uplevel #0 [list trace vdelete old_variable w [code $this change]]
	}
	set oldvariable $itk_option(-variable)
	if {$itk_option(-variable) != ""} {
	    uplevel #0 [list trace variable $itk_option(-variable) w [code $this change]]
	    upvar \#0 $itk_option(-variable) l_variable
	    set value $l_variable
	}
    }
    
    public method change
    public method invoke
    public method updateImage
    public method execute
    public method focusin
    public method focusout

    constructor { args } { }
}

body Radio::constructor { args } {
    
    itk_component add frame {
	frame $itk_interior.f \
	    -takefocus 1 \
	    -highlightthickness 0
    } {
	usual
	rename -highlightbackground -background background Background
    }
    pack $itk_component(frame) -side left
    
    itk_component add button {
	label $itk_interior.f.b \
	    -image radio_off \
	    -borderwidth 0
    } {
	keep -background
    }
    pack $itk_component(button) -side left
    
    itk_component add label {
	label $itk_interior.f.l
    } {
	keep -background -foreground
	keep -disabledforeground
	keep -text
	keep -font
    }
    pack $itk_component(label) -side left
    
    eval itk_initialize $args
    
}    

usual Radio {
    keep -background -foreground
    keep -font -cursor
}

body Radio::change { name1 name2 op } {
    if {$name1 != "radio$value"} {
	upvar \#0 $itk_option(-variable) l_variable
	set current_value $l_variable
	updateImage
	execute
    }
}

body Radio::invoke { } {
    focus $itk_component(frame)
    set current_value $value
    if {$itk_option(-variable) != ""} {
	upvar \#0 $itk_option(-variable) radio$value
	set radio$value $value
    }
    updateImage
    execute
}

body Radio::execute { } {
    if {$itk_option(-command) != ""} {
	uplevel \#0 $itk_option(-command) $current_value
    }
}

body Radio::updateImage { args } {
    if {$current_value == $value} {
	if {[focus] == $itk_component(frame)} {
	    $itk_component(button) configure -image radio_on_focus
	} elseif {$itk_option(-state) == "disabled"} {
	    $itk_component(button) configure -image radio_on_disabled
	} else {
	    $itk_component(button) configure -image radio_on
	}
    } else {
	if {[focus] == $itk_component(frame)} {
	    $itk_component(button) configure -image radio_off_focus
	} elseif {$itk_option(-state) == "disabled"} {
	    $itk_component(button) configure -image radio_off_disabled
	} else {
	    $itk_component(button) configure -image radio_off
	}
    }
}

body Radio::focusin { } {
    upvar $itk_option(-variable) var
    if {$var == $value} {
	$itk_component(button) configure -image radio_on_focus
    } else {
	$itk_component(button) configure -image radio_off_focus
    }
}

body Radio::focusout { } {
    upvar $itk_option(-variable) var
    if {$var == $value} {
	$itk_component(button) configure -image radio_on
    } else {
	$itk_component(button) configure -image radio_off
    }
}
