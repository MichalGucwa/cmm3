# $Id: palette.tcl,v 1.11 2011/01/10 17:23:56 ccb Exp $
package provide palette 1.0

class Palette {
    inherit itk::Toplevel

    itk_option define -alignwidget alignWidget AlignWidget ""

    private variable button "" 
    private variable ungrab_queue ""

    public method launch
    public method click
    public method dismiss

    constructor { args } {
	itk_option add hull.relief
	itk_option add hull.borderwidth

	$itk_component(hull) configure \
	    -relief raised \
	    -borderwidth 1
	    
	wm withdraw $itk_component(hull)
	wm overrideredirect $itk_component(hull) 1
	if {[tk windowingsystem] == "aqua"} {
	    ::tk::unsupported::MacWindowStyle style $itk_component(hull) floating noTitleBar
	}

	eval itk_initialize $args
    }

}
    
body Palette::launch { a_widget args } {
    # Store launch button for release later
    set button $a_widget
    # Calculate position
    if {$itk_option(-alignwidget) == ""} {
	set l_x [winfo rootx $a_widget]
	set l_width [winfo reqwidth $itk_component(hull)]
	set l_limit [winfo screenwidth $a_widget]
	if {($l_x + $l_width) > $l_limit} {
	    set l_x [expr $l_limit - $l_width]
	}
    } else {
	set l_x [winfo rootx $itk_option(-alignwidget)]
	#set l_y [expr [winfo rooty $itk_option(-alignwidget)] + [winfo height $itk_option(-alignwidget)]]
	set l_width [expr [winfo rootx $a_widget] + [winfo width $a_widget] - $l_x]
    }
    set l_y [expr [winfo rooty $a_widget] + [winfo height $a_widget]]
    set l_height [winfo reqheight $itk_component(hull)]
    wm geometry $itk_component(hull) =${l_width}x$l_height+$l_x+$l_y
    wm deiconify $itk_component(hull)
    raise $itk_component(hull)
    grab -global $itk_component(hull)
    set ungrab_queue [after 60000 [code $this dismiss]]
    bind $itk_component(hull) <ButtonPress-1> [code $this click %X %Y]
}

body Palette::click { a_x a_y } {
    set l_clicked_widget [winfo containing $a_x $a_y]
    if {($l_clicked_widget == "") || ([winfo toplevel $l_clicked_widget] != $itk_component(hull))} {
	dismiss
    }
}

body Palette::dismiss { } {
    
    # hack to fix treectrl bug!!!
    if {[info exists TreeCtrl::Priv(buttonMode)]} {
	unset TreeCtrl::Priv(buttonMode)
    }

    after cancel $ungrab_queue
    wm withdraw $itk_component(hull)
    grab release $itk_component(hull)
    if {$button != ""} {
	$button cancel "noexecute"
    }
}

usual Palette {
    keep -background -borderwidth
 }
