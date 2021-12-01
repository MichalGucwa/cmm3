# $Id: gwidgets.tcl,v 1.8 2010/01/21 16:02:24 rmk65 Exp $
package provide gwidgets 1.0

# ###############################################################################
# CHECK BUTTON
# ###############################################################################

set check_on_in_data "R0lGODlhEAAQAMIAAAAAAJCQkP///8nJyQDM/wDM/wDM/wDM/yH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgAEACwAAAAAEAAQAAADRQikvN4kyEmnACDgzfEQRAQIZGl+mGaa4xeq69XKMIsJrniVG4lmo1vPB9J1TrS RTFnK1ZjNZAz5GlivWKtsOg01vo9FAgA7"
set check_on_out_data "R0lGODlhEAAQAMIAAJCQkP///wAAAMnJyQDM/wDM/wDM/wDM/yH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgAEACwAAAAAEAAQAAADPki63AowyhieuDiLUQkQQSiOnDWOYOmBZ3AF6tdicCez7lubLx3GIA3JxvKJgCLckdgaPgbQqBTaaTYdWEYCADs="
set check_off_in_data "R0lGODlhEAAQAMIAAAAAAJCQkP///8nJyQDM/wDM/wDM/wDM/yH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgAEACwAAAAAEAAQAAADPgikvN4kyEmnACDgzfEQRAQIZGl+mGauwheqbIlmY0y6on1ftN6COd0MZsMRY8NaERgYOJ9QJ89nCjWuj0UCADs="
set check_off_out_data "R0lGODlhEAAQAMIAAJCQkP///wAAAMnJyQDM/wDM/wDM/wDM/yH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgAEACwAAAAAEAAQAAADNEi63AowyhieuDiLUQkQQSiOnDWeQemBqKh+rdvBcTqz8Yu3em2btV5wNigaj8WOb+RoMhIAOw=="
set check_on_in_dis_data "R0lGODlhEAAQAMIAAAAAAJCQkP///8nJydzc3KmpqQAAAAAAACH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgAHACwAAAAAEAAQAAADSwinvN4nyEmnACDgzfEQRwQQZGl+mGaaBfGF6koULZqNK12D4lzqJJuKNiMGeUNdqyTEAU9InG/VlEFhg6x2m70ABOCwWBxqmB+LBAA7"
set check_on_out_dis_data "R0lGODlhEAAQAMIAAJCQkP///wAAAMnJydzc3KmpqQAAAAAAACH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgAHACwAAAAAEAAQAAADRHi63AowyhieuDiLUQ8QRCiOnDWOBVF64EkU6fq5cNzNaViHMgi/P97NV8sJTUDjkSVSLmcukWxArVqpnYB2y+U6vowEADs="
set check_off_in_dis_data "R0lGODlhEAAQAMIAAAAAAJCQkP///8nJydzc3AAAAAAAAAAAACH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgAHACwAAAAAEAAQAAADQQinvN4nyEmnACDgzfEQRwQQZGl+mGauxBeqbIlmY0y6on1ftN6COd0MZsMRY8NaERgYOJ9QJ09ArVqtoYb2sUgAADs="
set check_off_out_dis_data "R0lGODlhEAAQAMIAAJCQkP///wAAAMnJydzc3AAAAAAAAAAAACH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgAHACwAAAAAEAAQAAADN3i63AowyhieuDiLUQ8QRCiOnDWeROmBqKh+rdvBcTqz8Yu3em2btV5wNigaj8VOYMlsNh1QRgIAOw=="


image create photo check_on_in -data $check_on_in_data
image create photo check_on_out -data $check_on_out_data
image create photo check_off_in -data $check_off_in_data
image create photo check_off_out -data $check_off_out_data
image create photo check_on_in_dis -data $check_on_in_dis_data
image create photo check_on_out_dis -data $check_on_out_dis_data
image create photo check_off_in_dis -data $check_off_in_dis_data
image create photo check_off_out_dis -data $check_off_out_dis_data

class gcheckbutton {
    inherit itk::Widget
    
    protected variable value 0
    protected variable oldvariable ""
    private variable check_on_in ""
    private variable check_on_out ""
    private variable check_off_in ""
    private variable check_off_out ""
    private variable check_on_in_dis ""
    private variable check_on_out_dis ""
    private variable check_off_in_dis ""
    private variable check_off_out_dis ""
    
    itk_option define -command command Command ""
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
	updateImage
    }
    itk_option define -state state State "normal" {
	if {$itk_option(-state) == "normal"} {
	    $itk_component(frame) configure -takefocus 1
	    bind $itk_component(button) <ButtonPress-1> [code $this invoke]
	    bind $itk_component(label) <Button-1> [code $this invoke]
	    bind $itk_component(frame) <space> [code $this invoke]
	    bind $itk_component(frame) <FocusIn> [code $this focusin]
	    bind $itk_component(frame) <FocusOut> [code $this focusout]
	    if {$value == 1} {
		$itk_component(button) configure -image check_on_out
	    } else {
		$itk_component(button) configure -image check_off_out
	    }
	} else {
	    $itk_component(frame) configure -takefocus 0
	    bind $itk_component(button) <ButtonPress-1> {}
	    bind $itk_component(label) <Button-1> {}
	    bind $itk_component(frame) <space> {}
	    bind $itk_component(frame) <FocusIn> {}
	    bind $itk_component(frame) <FocusOut> {}
	    if {$value == 1} {
		$itk_component(button) configure -image check_on_out_dis
	    } else {
		$itk_component(button) configure -image check_off_out_dis
	    }
	}
    }

    itk_option define -style style Style "normal" {
	if {$itk_option(-style) == "normal"} {
	    set check_on_in ::img::check_on_focused16x16
	    set check_on_out ::img::check_on_unfocused16x16
	    set check_off_in ::img::check_off_focused16x16
	    set check_off_out ::img::check_off_unfocused16x16
	    set check_on_in_dis ::img::check_on_focused_disabled16x16
	    set check_on_out_dis ::img::check_on_unfocused_disabled16x16
	    set check_off_in_dis ::img::check_off_focused_disabled16x16
	    set check_off_out_dis ::img::check_off_unfocused_disabled16x16
	} elseif {$itk_option(-style) == "flat"} {
	    set check_on_in ::img::flat_check_on_focused16x16
	    set check_on_out ::img::flat_check_on_unfocused16x16
	    set check_off_in ::img::flat_check_off_focused16x16
	    set check_off_out ::img::flat_check_off_unfocused16x16
	    # NB no flat checks will be disabled, so I haven't created those imaegs
	    set check_on_in_dis ::img::check_on_focused_disabled16x16
	    set check_on_out_dis ::img::check_on_unfocused_disabled16x16
	    set check_off_in_dis ::img::check_off_focused_disabled16x16
	    set check_off_out_dis ::img::check_off_unfocused_disabled16x16
	}
    }

    public method change
    public method execute
    public method updateImage
    public method query
    public method invoke
    public method focusin
    public method focusout

   constructor { args } {

      itk_option add hull.background hull.relief hull.borderwidth
      $itk_component(hull) configure -borderwidth 0

      itk_component add frame {
         frame $itk_interior.f \
            -borderwidth 0 \
            -highlightthickness 0 \
            -takefocus 1 \
      } {
         usual
         rename -highlightbackground -background background Background
      }
      pack $itk_component(frame) -side left

      itk_component add button {
         label $itk_interior.f.b \
            -borderwidth 0 \
            -padx 0 \
            -pady 0
            #-image check_off_out
      } {
         keep -background
      }
      pack $itk_component(button) -side left

      itk_component add label {
         label $itk_interior.f.l \
            -borderwidth 0 \
            -padx 1 \
            -pady 0 \
      } {
         keep -background -foreground
         keep -text
         keep -font
      }
      pack $itk_component(label) -side left

      bind $itk_component(button) <ButtonPress-1> [code $this invoke]
      bind $itk_component(label) <Button-1> [code $this invoke]
      bind $itk_component(frame) <space> [code $this invoke]
      bind $itk_component(frame) <FocusIn> [code $this focusin]
      bind $itk_component(frame) <FocusOut> [code $this focusout]
      
      eval itk_initialize $args
      updateImage
  }    
}

usual gcheckbutton {
   keep -background -foreground
   keep -font -cursor
}

body gcheckbutton::query { } {
    return $value
}

body gcheckbutton::invoke { } {
    focus $itk_component(frame)
    if {$value == 0} {
	set value 1
    } else {
	set value 0
    }
     if {$itk_option(-variable) != ""} {
	 upvar \#0 $itk_option(-variable) l_variable
	 set l_variable $value
     }
    updateImage
    execute    
}

body gcheckbutton::change { args } {
    upvar \#0 $itk_option(-variable) l_variable
    set value $l_variable
    updateImage
    #execute
}

body gcheckbutton::updateImage { } {
    if {$value == 0} {
	if {[focus] == $itk_component(frame)} {
	    $itk_component(button) configure -image $check_off_in
	} else {
	    $itk_component(button) configure -image $check_off_out
	}
    } else {
	if {[focus] == $itk_component(frame)} {
	    $itk_component(button) configure -image $check_on_in
	} else {
	    $itk_component(button) configure -image $check_on_out
	}
    }
}

body gcheckbutton::execute { } {
    if {$itk_option(-command) != ""} {
	if {[catch {uplevel \#0 $itk_option(-command) $value} result]} {
	    puts "gcheckbutton::execute had an error: $result"
	}   
    }    
}

body gcheckbutton::focusin { } {
    if {$value == 0} {
	$itk_component(button) configure -image $check_off_in
    } else {
	$itk_component(button) configure -image $check_on_in
    }
}

body gcheckbutton::focusout { } {
    if {$value == 0} {
	$itk_component(button) configure -image $check_off_out
    } else {
	$itk_component(button) configure -image $check_on_out
    }
}

# ###############################################################################
# EMBEDDED CHECK BUTTON
# ###############################################################################

set embedded_check_on_data "R0lGODlhDAAMAKEAAAAAAP///////////yH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgACACwAAAAADAAMAAACGoSPF8tt7cKDElSqnl3q6ukhztYx4DZSY8IWADs="
set embedded_check_off_data "R0lGODlhDAAMAKEAAAAAAP///////////yH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgACACwAAAAADAAMAAACF4SPF8ttDcOLbFIJ7rKURw+BTqYlplEAADs="
image create photo ::img::embed_check_on -data $embedded_check_on_data
image create photo ::img::embed_check_off -data $embedded_check_off_data

class gEmbeddedCheck {
    inherit itk::Widget
    
    private variable value 0
    
    itk_option define -command command Command ""
    
    public method setValue
    public method invoke
    
    constructor { args } { }
}

body gEmbeddedCheck::constructor { { a_value 0 } args } {
    itk_component add icon {
	label $itk_interior.icon \
	    -borderwidth 0 \
	    -padx 0 \
	    -pady 0
    } {
	rename -background -textbackground textbackground Background
    }
    pack $itk_component(icon)
    
    bind $itk_component(icon) <ButtonPress-1> [code $this invoke]

    set value $a_value
    if {$value == "0"} {
	$itk_component(icon) configure -image ::img::embed_check_off
    } else {
	$itk_component(icon) configure -image ::img::embed_check_on
    }
    
    eval itk_initialize $args
}

usual gEmbeddedCheck {
   keep -background -foreground
   keep -font -cursor
}

body gEmbeddedCheck::setValue { a_value } {
    if {$a_value == 1} {
	set value 1
	$itk_component(icon) configure -image ::img::embed_check_on
    } elseif {$a_value == 0} {
	set value 0
	$itk_component(icon) configure -image ::img::embed_check_off
    } else {
	error "Attempt to set embedded checkbutton's value to $a_value"
    }
    if {$itk_option(-command) != ""} {
	uplevel #0 $itk_option(-command) $value
    }
}

body gEmbeddedCheck::invoke { } {
    if {$value == 0} {
	set value 1
	$itk_component(icon) configure -image ::img::embed_check_on
    } else {
	set value 0
	$itk_component(icon) configure -image ::img::embed_check_off
    }
    if {$itk_option(-command) != ""} {
	uplevel #0 $itk_option(-command) $value
    }
}

# ###############################################################################
# EMBEDDED CHECK AND SPINNIT BUTTON
# ###############################################################################

# image create photo ::img::left_spinnit -file [file join $env(MOSFLM_GUI_ROOT) ../images/left_spinnit.gif]
# image create photo ::img::right_spinnit -file [file join $env(MOSFLM_GUI_ROOT) ../images/right_spinnit.gif]
# image create photo ::img::left_spinnit_off -file [file join $env(MOSFLM_GUI_ROOT) ../images/left_spinnit_off.gif]
# image create photo ::img::right_spinnit_off -file [file join $env(MOSFLM_GUI_ROOT) ../images/right_spinnit_off.gif]

# image create bitmap ::img::marker(\#000000,square) \
#     -file [file join $env(MOSFLM_GUI_ROOT) ../images/markers/square.xbm] \
#     -maskfile [file join $env(MOSFLM_GUI_ROOT) ../images/markers/square.xbm] \
#     -foreground black

# class gEmbeddedCheckSpinnit {
#     inherit itk::Widget
    
#     private variable state 0
#     private variable number ""

#     itk_option define -command command Command ""

#     itk_option define -max max Max "9" {
# 	if {$number > $itk_option(-max)} {
# 	    set number $itk_option(-max)
# 	}
#     }
    
#     itk_option define -colour colour Colour "\#000000" {
# 	$itk_component(canvas) itemconfigure line -fill $itk_option(-colour)
# 	set itk_option(-symbol) $itk_option(-symbol)
#     }
    
#     itk_option define -symbol symbol Symbol "square" {
# 	image create bitmap ::img::marker($itk_option(-colour),$itk_option(-symbol)) -file $::env(MOSFLM_GUI)/images/markers/$itk_option(-symbol).xbm -maskfile $::env(MOSFLM_GUI)/images/markers/$itk_option(-symbol).xbm -foreground $itk_option(-colour)
# 	$itk_component(canvas) itemconfigure symbol -image ::img::marker($itk_option(-colour),$itk_option(-symbol))
#     }
    
#     public method setNumber
#     public method toggle
#     public method increment
#     public method decrement
    
#     constructor { args } { }
# }

# body gEmbeddedCheckSpinnit::constructor { { a_value 0 } args } {

#     itk_component add canvas {
# 	canvas $itk_interior.canvas \
# 	    -width 70 \
# 	    -height 12 \
# 	    -borderwidth 0 \
# 	    -highlightthickness 0 \
# 	    -bg white
#     } {
# 	keep -background
#     }

#     pack $itk_component(canvas)

#     eval itk_initialize $args
    
#     $itk_component(canvas) create image 0 0 -image ::img::embed_check_off -anchor nw -tags checkbox
#     $itk_component(canvas) create rectangle 24 0 35 11 -fill "white" -tags {numbox}
#     $itk_component(canvas) create image 22 6 -image ::img::left_spinnit -anchor e -tags {left spinnit}
#     $itk_component(canvas) create image 38 6 -image ::img::right_spinnit -anchor w -tags {right spinnit}
#     $itk_component(canvas) create text 30 6 -text $number -font font_tb -tags {number}
#     $itk_component(canvas) bind checkbox <ButtonPress-1> [code $this toggle]

#     $itk_component(canvas) create line 48 6 68 6 -fill $itk_option(-colour) -capstyle round -tags {line} 
#     $itk_component(canvas) create image 58 6 -image ::img::marker($itk_option(-colour),$itk_option(-symbol)) -tags {symbol}

#     setNumber $a_value
    
# }

# usual gEmbeddedCheckSpinnit {
# }

# body gEmbeddedCheckSpinnit::setNumber { a_value } {
#     if {$a_value == 0} {
# 	set state 0
# 	$itk_component(canvas) itemconfigure checkbox -image ::img::embed_check_off
# 	$itk_component(canvas) itemconfigure left -image ::img::left_spinnit_off
# 	$itk_component(canvas) itemconfigure right -image ::img::right_spinnit_off
# 	$itk_component(canvas) itemconfigure number -fill "\#a9a9a9"
# 	$itk_component(canvas) itemconfigure numbox -outline "\#a9a9a9"
# 	$itk_component(canvas) bind left <ButtonPress-1> {}
# 	$itk_component(canvas) bind right <ButtonPress-1> {}
#     } elseif {$a_value <= $itk_option(-max)} {
# 	set state 1
# 	set number $a_value
# 	$itk_component(canvas) itemconfigure checkbox -image ::img::embed_check_on
# 	$itk_component(canvas) itemconfigure left -image ::img::left_spinnit
# 	$itk_component(canvas) itemconfigure right -image ::img::right_spinnit
# 	$itk_component(canvas) itemconfigure number -fill "black" -text $number
# 	$itk_component(canvas) itemconfigure numbox -outline "black"
# 	$itk_component(canvas) bind left <ButtonPress-1> [code $this decrement]
# 	$itk_component(canvas) bind right <ButtonPress-1> [code $this increment]
#     } else {
# 	error "Attempt to set embedded checkbutton spinnit's value to $a_value"
#     }
#     if {$itk_option(-command) != ""} {
# 	uplevel #0 $itk_option(-command) $a_value
#     }
# }

# body gEmbeddedCheckSpinnit::toggle { } {
#     if {$state == 0} {
# 	if {$number == ""} {
# 	    setNumber 1
# 	} else {
# 	    setNumber $number
# 	}
# 	set l_output $number
#     } else {
# 	setNumber 0
# 	set l_output 0
#     }
#     if {$itk_option(-command) != ""} {
# 	uplevel #0 $itk_option(-command) $l_output
#     }
# }

# body gEmbeddedCheckSpinnit::increment { } {
#     if {$number < $itk_option(-max)} {
# 	incr number
# 	setNumber $number
#     } else {
# 	setNumber 1
#     }
# }

# body gEmbeddedCheckSpinnit::decrement { } {
#     if {$number > 1} {
# 	incr number -1
# 	setNumber $number
#     } else {
# 	setNumber $itk_option(-max)
#     }
# }

# ###############################################################################
# ENTRY
# ###############################################################################

class gEntry {
    inherit Balloonwidget

    itk_option define -image image Image "" {
	if {$itk_option(-image) != ""} {
	    $itk_component(icon) configure \
		-image $itk_option(-image) \
		-width [expr [image width $itk_option(-image)] + 4] \
		-height [expr [image height $itk_option(-image)] + 4]
	}
    }

    itk_option define -padxy padXY Pad 0 {
	$itk_component(padding) configure -borderwidth $itk_option(-padxy)
    }
    itk_option define -disabledbackground disabledBackground Background "#dcdcdc"
    itk_option define -disabledforeground disabledForeground DisabledForeground "#a9a9a9"
    itk_option define -foreground foreground Foreground "#000000" {
	if {$itk_option(-state) != "disabled"} {
	    $itk_component(entry) configure -foreground $itk_option(-foreground)
	}
    }
    itk_option define -textbackground textBackground Background "#ffffff" {
	if {$itk_option(-state) != "disabled"} {
	    $itk_component(entry) configure -background $itk_option(-textbackground)
	    $itk_component(icon) configure -background $itk_option(-textbackground)
	}
	$itk_component(frame) configure -background $itk_option(-textbackground)
    }
    itk_option define -entryfont entryFont Font font_e {
	$itk_component(entry) configure -font $itk_option(-entryfont)
    }
    itk_option define -state state State "normal" {
	if {$itk_option(-state) == "disabled"} {
	    $itk_component(entry) configure \
		-state disabled \
		-background $itk_option(-disabledbackground) \
		-foreground $itk_option(-disabledforeground)
	    $itk_component(frame) configure \
		-background $itk_option(-disabledbackground)
	    $itk_component(icon) configure \
		-background $itk_option(-disabledbackground)
	} else {
	    $itk_component(entry) configure \
		-state normal \
		-background $itk_option(-textbackground) \
		-foreground $itk_option(-foreground)
	    $itk_component(frame) configure \
		-background $itk_option(-textbackground)
	    $itk_component(icon) configure \
		-background $itk_option(-textbackground)
	}
    }
    itk_option define -type type Type "string"
    itk_option define -defaultvalue defaultValue DefaultValue ""
    itk_option define -precision precision Precision "2"
    itk_option define -maximum maximum Maximum ""
    itk_option define -minimum minimum Minimum ""
    itk_option define -allowblank allowBlank AllowBlank "1"
    itk_option define -linkcommand linkCommand Command ""
    itk_option define -editcommand editCommand Command ""
    itk_option define -command command Command ""

    public method validate
    public method focusOut
    public method update
    public method query
    public method keystroke

    constructor { args } {
	
	itk_component add padding {
	    frame $itk_interior.p \
		-relief flat \
	    }
	pack $itk_component(padding) -fill x
	
	itk_component add frame {
	    frame $itk_interior.p.f \
		-borderwidth 2 \
		-relief sunken
	} {
	    usual
 	    keep -borderwidth
 	    keep -relief
	}
	pack $itk_component(frame) -fill x
	
	itk_component add icon {
	    label $itk_interior.p.f.icon \
		-anchor c \
		-padx 0 \
		-pady 0 \
		-bd 0
	}
	pack $itk_component(icon) -side left

	itk_component add entry {
	    entry $itk_interior.p.f.entry \
		-relief flat \
		-borderwidth 0 \
		-highlightthickness 0 \
		-selectborderwidth 0 \
		-validate all \
		-validatecommand [code $this validate %V %P]
	    } {
		keep -insertbackground -insertborderwidth -insertwidth
		keep -insertontime -insertofftime
		keep -selectbackground -selectforeground
		keep -textvariable
		keep -width
		keep -justify
		keep -show
	    }
	pack $itk_component(entry) -side right -fill x -expand true
	
	bind $itk_component(entry) <FocusOut> [code $this focusOut]
	bind $itk_component(entry) <Return> [code $this focusOut]
	bind $itk_component(entry) <KeyPress> [code $this keystroke]

	eval itk_initialize $args
    }
    
}

body gEntry::query { } {
    return [$itk_component(entry) get]
}

body gEntry::update { a_value } {
    if {[validate "focusout" $a_value]} {
	$itk_component(entry) configure -state normal
	$itk_component(entry) delete 0 end
	$itk_component(entry) insert 0 $a_value
	$itk_component(entry) configure -state $itk_option(-state)	
	focusOut -nolink
    }
}

body gEntry::validate { reason new_string } {
    switch -- $reason {
	key {
	    switch -- $itk_option(-type) {
		real {
		    if {[regexp -- {^-?\d*\.?\d*$} $new_string]} {
			return 1
		    } else {
			bell
			return 0
		    }
		}
		int {
		    if {[regexp -- {^-?\d*$} $new_string]} {
			return 1
		    } else {
			bell
			return 0
		    }
		}
		default {
		    return 1
		}
	    }
	}
	forced {
	    # Trust myself to only force it to accept well-formed values
	    return 1
	}
	focusout {
	    switch -- $itk_option(-type) {
		real {
		    if {[regexp -- {^-?\.?$} $new_string]} {set new_string ""}
		    if {$new_string == ""} {
			if {$itk_option(-allowblank)} {
			    return 1
			} elseif {$itk_option(-defaultvalue) != ""} {
			    set new_string $itk_option(-defaultvalue)
			} else {
			    set new_string 0
			}
		    }
		    if {$itk_option(-maximum) != ""} {
			if {$new_string > $itk_option(-maximum)} {
			    set new_string $itk_option(-maximum)
			}
		    }
		    if {$itk_option(-minimum) != ""} {
			if {$new_string < $itk_option(-minimum)} {
			    set new_string $itk_option(-minimum)
			}
		    }
		    $itk_component(entry) delete 0 end
		    $itk_component(entry) insert 0 [format %.$itk_option(-precision)f $new_string]
		    # Need to turn valistaion back on, as setting the entry content
		    #  here will have turned it off.
		    after idle [list $itk_component(entry) configure -validate all]
		    return 1
		}
		int {
		    if {[regexp -- {^-?$} $new_string]} {set new_string ""}
		    if {$new_string == ""} {
			if {$itk_option(-allowblank)} {
			    return 1
			} elseif {$itk_option(-defaultvalue) != ""} {
			    set new_string $itk_option(-defaultvalue)
			} else {
			    set new_string 0
			}
		    }
		    if {$itk_option(-maximum) != ""} {
			if {$new_string > $itk_option(-maximum)} {
			    set new_string $itk_option(-maximum)
			}
		    }
		    if {$itk_option(-minimum) != ""} {
			if {$new_string < $itk_option(-minimum)} {
			    set new_string $itk_option(-minimum)
			}
		    }
		    $itk_component(entry) delete 0 end
		    $itk_component(entry) insert 0 $new_string
		    # Need to turn validation back on, as setting the entry content
		    #  here will have turned it off.
		    after idle [list $itk_component(entry) configure -validate all]
		    return 1
		}
		default {
		    return 1
		}
	    }
	}
	default {
	    return 1
	}
    }
}

body gEntry::focusOut { { a_link "-link" } } {
    $itk_component(entry) selection clear
    if {$itk_option(-command) != ""} {
	uplevel #0 [list $itk_option(-command) "[$itk_component(entry) get]"]
    }
    if { $a_link != "-nolink" } {
	if {$itk_option(-linkcommand) != ""} {
	    uplevel #0 $itk_option(-linkcommand)
	}
    }
}

body gEntry::keystroke { } {
    if  {$itk_option(-editcommand) != ""} {
	uplevel #0 $itk_option(-editcommand)
    }
}

usual gEntry {
   #rename -disabledbackground -background background Background
   keep -textbackground -background
   keep -selectforeground -selectbackground
   keep -disabledbackground -disabledforeground
   keep -entryfont
   keep -padxy
}

# ###############################################################################
# FILEENTRY
# ###############################################################################

class Fileentry {
    inherit gEntry

    itk_option define -command command Command ""
    itk_option define -onlinecommand onlinecommand Command ""

    public variable root "/"

    public method complete
    public method execute
    public method onlineExecute
    public method tab
    
    constructor { args } {
	
	itk_component add image {
	    label $itk_interior.p.f.image \
         	-borderwidth 0 \
         	-image ::img::directory_closed16x16
	} {
      	rename -background -textbackground textBackground Background
	}
	pack $itk_component(image) -side left -fill y
	
	bind $itk_component(entry) <Key-Right> [code $this complete ]
	bind $itk_component(entry) <Return> [code $this execute]
	bind $itk_component(entry) <KeyRelease> [code $this onlineExecute]
	bind $itk_component(entry) <Tab> [code $this tab]
	#bind $itk_component(entry) <FocusOut> [code $this update]
	
	eval itk_initialize $args
    }
}

usual Fileentry {
	usual gEntry
}

body Fileentry::tab { } {
	upvar [$itk_component(entry) cget -textvariable] value
   if {[file isdirectory $value]} {
      focus [tk_focusNext $itk_component(hull)]
   } else {
      complete
   }
}

#body Fileentry::update { } {
#	$this configure -value $value
#}


body Fileentry::execute { } {
    upvar [$itk_component(entry) cget -textvariable] value
    if {[file isdirectory $value]} {
	if {$itk_option(-command) != ""} {
	    uplevel #0 $itk_option(-command) $value
	    #set value ""
	}
    } else {
   	complete
    }
}

body Fileentry::onlineExecute { } {
    upvar [$itk_component(entry) cget -textvariable] value
    if {$itk_option(-onlinecommand) != ""} {
	uplevel #0 $itk_option(-onlinecommand) $value
    }
}

body Fileentry::complete { } {

	upvar [$itk_component(entry) cget -textvariable] value
	if {[catch {glob -types d ${value}*} results]} {
      set value [string range $value 0 {end-1}]
		if {$value != ""} {
         $this complete
      }
   } else {
		if {[llength $results] == 1} {
      	if {[file isdirectory $results]} {
         	set value "${results}/"
         } else {
         	set value $results
         }
      } else {
      	set stem ""
      	for {set i 0} { 1 } {incr i 1} {
         	foreach poss $results {
            	if {[string index $poss $i] == ""} break
            }
            set letter [string index [lindex $results 0] $i]
            set missmatch 0
            foreach poss [lrange $results 1 end] {
            	if {[string index $poss $i] != $letter} {
               	set missmatch 1
               }
            }
            if {$missmatch == 1} {
            	break
            } else {
            	set stem "$stem$letter"
            }
            set value $stem
         }
      }
   }
   $itk_component(entry) icursor end
}

#configbody Fileentry::value {
#	if {$itk_option(-textvariable) != ""} {
#      upvar $itk_option(-textvariable) variable
#      set variable $value
#   }
#}



# ###############################################################################
# LABEL
# ###############################################################################

# usual Label {
#     keep -background -cursor -foreground
#     keep -highlightcolor -highlightthickness
#     rename -highlightbackground -background background Background
#     rename -font -labelfont labelFont Font
# }

# ###############################################################################
# BUTTON
# ###############################################################################

usual Button {
    rename -font -labelfont labelFont Font
    keep -background -cursor -foreground
    keep -activeforeground -disabledforeground
    keep -highlightcolor
    rename -activebackground -background background Background
    rename -highlightbackground -background background Background
}

# ###############################################################################
# MENU
# ###############################################################################

usual Menu {
    keep -background -cursor -foreground -font
    keep -disabledforeground
    keep -selectcolor
    rename -activebackground -selectbackground selectBackground Foreground
    rename -activeforeground -selectforeground selectForeground Background
}

usual Menubutton {
    rename -activebackground -background background Background
    rename -activeforeground -foreground foreground Foreground
}

# ###############################################################################
# CANVAS
# ###############################################################################

usual Canvas {
#    rename -background -textbackground textBackground Background
#    keep -borderwidth
}

# ###############################################################################
# LISTBOX
# ###############################################################################

usual Listbox {
    keep -cursor -foreground
    keep -highlightcolor
    rename -font -entryfont entryFont Font
    rename -background -textbackground textBackground Background
    rename -highlightbackground -background background Background
    keep -selectborderwidth
    keep -selectbackground
}

# ###############################################################################
# gRECORD
# ###############################################################################

class gRecord {
    inherit itk::Widget

    constructor { args } {
	
	itk_option add hull.relief hull.background hull.borderwidth

	#$itk_component(hull) configure -borderwidth 2

	itk_component add label {
	    label $itk_interior.l
	} {
	    usual
	    keep -text
	}

	itk_component add entry {
	    entry $itk_interior.e \
		-state disabled \
		-relief flat \
		-justify right \
		-borderwidth 0
	} {
	    usual
	    #rename -textbackground -background background Background
	    rename -width -entrywidth entrywidth Entrywidth
	    rename -font -entryfont entryFont Font
	    keep -textvariable
	}

	pack $itk_component(label) -side left
	pack $itk_component(entry) -side right

	eval itk_initialize $args
    }
}

usual gRecord {
    keep -background -cursor -foreground -font -entryfont
    keep -highlightcolor -highlightthickness
    keep -borderwidth
    keep -selectbackground -selectborderwidth -selectforeground
}

# ###############################################################################
# gSection
# ###############################################################################

class gSection {
    inherit itk::Widget

    constructor { args } {
	
	#itk_option add hull.relief hull.background hull.borderwidth

	itk_component add label {
	    label $itk_interior.l
	} {
	    usual
	    keep -text
	}

	itk_component add entry {
	    frame $itk_interior.f \
		-bd 2 \
		-height 2 \
		-relief sunken \
	}

	pack $itk_component(label) -side left
	pack $itk_component(entry) -side right -fill x -expand 1 -padx 2

	eval itk_initialize $args
    }
}

usual gSection {
    keep -background -cursor -foreground -font
}

