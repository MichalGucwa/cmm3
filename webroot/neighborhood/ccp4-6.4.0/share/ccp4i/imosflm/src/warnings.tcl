# $Id: warnings.tcl,v 1.11 2011/01/10 17:24:00 ccb Exp $
package provide warnings 1.0

class Warning {
    private variable type "Warning"
    private variable message "Be warned!"
    private variable fulltext ""
    private variable hint ""
    private variable note ""
    private variable icon ""

    public method getType { } { return $type }
    public method getMessage { } { return $message }
    public method getExplanation
    public method getHint
    public method getNote
    public method getIcon { } { return $icon }

    public method serialize

    constructor { a_method args } {
	if {$a_method == "build"} {
	    set type [lindex $args 0]
	    set message [lindex $args 4]
	    set fulltext [lindex $args 1]
	    set hint [lindex $args 2]
	    set note [lindex $args 3]
	} elseif {$a_method == "copy"} {
	    set type [$args getType]
	    set message [$args getMessage]
	    set fulltext [$args getExplanation]
	    set hint [$args getHint]
	    set note [$args getNote]
	} elseif {$a_method == "xml"} {
	    set type [$args getAttribute "type"]
	    set message [regsub -all -- {newline} [$args getAttribute "message"] "\n"]
	    set fulltext [regsub -all -- {newline} [$args getAttribute "fulltext"] "\n"]
	    set hint [regsub -all -- {newline} [$args getAttribute "hint"] "\n"]
	    set note [regsub -all -- {newline} [$args getAttribute "note"] "\n"]
	}
	if {$type == "Warning"} {
	    set icon ::img::status_warning_on16x16
	} else {
	    set icon ::img::status_info_on16x16
	}
    }
}

body Warning::getExplanation {} {
    if { $fulltext != ""} {
	return $fulltext
    } else {
	return "Sorry no further information"
    }
}

body Warning::getHint {} {
    if { $hint != ""} {
	return $hint
    } else {
	return "Sorry no further information"
    }
}

body Warning::getNote {} {
    if { $note != ""} {
	return $note
    } else {
	return "Sorry no further information"
    }
}

body Warning::serialize { } {
    # Not currently called - were 'regsub -all -- {\n} etc.'
    return "<warning type=\"$type\" \
			  message=\"[regsub -all {\n} $message newline]\" \
			  fulltext=\"[regsub -all {\n} $fulltext newline]\" \
			  hint=\"[regsub -all {\n} $hint newline]\" \
			  note=\"[regsub -all {\n} $note newline]\" \
			  />"
}

class WarningWidget {
    inherit itk::Widget

    itk_option define -deletecommand deleteCommand Command ""

    # warning objects
    private variable warnings {}

    # animation variables
    private variable animation_queue ""
    private variable current_icon_list {}
    
    private variable warning_icons { ::img::status_warning_on16x16 ::img::status_warning_off16x16 }
    private variable info_icons { ::img::status_info_on16x16 ::img::status_info_off16x16 }
    private variable ok_icons { ::img::status_ok16x16 }

    public method addWarning
    public method deleteWarning
    public method popSummary
    public method deleteAll
    public method clear
    public method reload
    private method updateIcon
    private method updateText

    private method animate
    private method stop
    private method loopImages

    constructor { args } { }
}

body WarningWidget::constructor { args } {

    itk_component add frame {
	frame $itk_interior.f \
	    -relief sunken \
	    -bd 2
    }

    itk_component add label {
	label $itk_interior.f.l \
	    -text "No warnings" \
	    -anchor w
    }

    itk_component add icon {
	label $itk_interior.f.i \
	    -image ::img::status_ok16x16
    }

    pack $itk_component(frame)
    pack $itk_component(label) -side left -fill both -expand 1
    pack $itk_component(icon) -side right

    bind $itk_component(label) <1> [code $this popSummary]
    bind $itk_component(icon) <1> [code $this popSummary]

    animate $ok_icons

    eval itk_initialize $args
}

body WarningWidget::updateIcon { } {
    foreach i_warning $warnings {
	if {[$i_warning getType] == "Warning"} {
	    animate $warning_icons
	    return
	}
    }
    if {[llength $warnings] > 0} {
	animate $info_icons
    } else {
	animate $ok_icons
    }
}

body WarningWidget::updateText { } {
    set l_num_warnings [llength $warnings]
    if {$l_num_warnings == 0} {
	$itk_component(label) configure -text "No Warnings "
    } elseif {$l_num_warnings == 1} {
	$itk_component(label) configure -text "1 Warning "
    } else {
	$itk_component(label) configure -text "$l_num_warnings Warnings "
    }
}

body WarningWidget::addWarning { a_warning } {
    lappend warnings $a_warning
    updateIcon
    updateText
}

body WarningWidget::deleteWarning { a_warning } {
    set l_index [lsearch $warnings $a_warning]
    set warnings [lreplace $warnings $l_index $l_index]
    updateIcon
    updateText
    stop
    if {$itk_option(-deletecommand) != ""} {
	uplevel \#0 $itk_option(-deletecommand) $a_warning
    }
}

body WarningWidget::popSummary { } {
    if {[llength $warnings] > 0} {
	stop
	if {![winfo exists .warningSummary]} {
	    WarningSummary .warningSummary
	}
	.warningSummary pop $itk_component(hull) $warnings
    }
}

body WarningWidget::clear { } {
    set warnings {}
    updateIcon
    updateText
}

body WarningWidget::deleteAll { } {
    if {[llength $warnings] > 0} {
	eval delete object $warnings
    }
    clear
}

body WarningWidget::reload { a_warnings } {
    clear
    foreach i_warning $a_warnings {
	addWarning $i_warning
    }
}

body WarningWidget::animate { a_list { a_interval "500" } } {
    stop
    set current_icon_list $a_list
    if {[llength $current_icon_list] <= 1} {
	$itk_component(icon) configure \
	    -image [lindex $current_icon_list 0]
    } else {
	loopImages 0 $a_interval
    }
}

body WarningWidget::stop { } {
    if {$animation_queue != ""} {
	after cancel $animation_queue
    }
    if {$current_icon_list != {}} {
	$itk_component(icon) configure -image [lindex $current_icon_list 0]
    }    
}

body WarningWidget::loopImages { a_index a_interval } {
    if {$a_index >= [llength $current_icon_list]} {
	set a_index 0
    }
    $itk_component(icon) configure \
	-image [lindex $current_icon_list $a_index]
    incr a_index
    set animation_queue [after $a_interval [code $this loopImages $a_index $a_interval]]
}

usual WarningWidget { }

# Summary #############################################################

class WarningSummary {
    inherit itk::Toplevel

    private variable warning_widget ""

    private variable warnings_by_item ; # array
    private variable items_by_warning ; # array

    private variable ungrab_queue ""

    public method pop
    public method drop
    public method clear
    public method addWarning
    public method wipeWarning
    public method deleteWarning
    public method clickWarning
    public method doubleClickWarning
    public method clickPopup
    public method popDetail

    constructor { args } { }
}

body WarningSummary::pop { a_widget a_warnings } {
    # Store processing wizard palette belongs to
    set warning_widget $a_widget

    # add warnings to tree
    clear
    foreach i_warning $a_warnings {
	addWarning $i_warning
    }

    # Position and show pop up
    set l_x [winfo rootx $a_widget]
    set l_widget_width [winfo reqwidth $a_widget]
    set l_popup_width [$itk_component(hull) cget -width]
    set l_x [expr $l_x + $l_widget_width - $l_popup_width]
    set l_y [expr [winfo rooty $a_widget] - [$itk_component(hull) cget -height]]
    wm geometry $itk_component(hull) +$l_x+$l_y
    wm deiconify $itk_component(hull)
    raise $itk_component(hull)
    grab $itk_component(hull)
    #set ungrab_queue [after 60000 [code $this drop]]
    bind $itk_component(hull) <ButtonPress-1> [code $this clickPopup %X %Y]

}

body WarningSummary::drop { } {
    #after cancel $ungrab_queue
    grab release $itk_component(hull)
    wm withdraw $itk_component(hull)
}

body WarningSummary::clear { } {
    foreach i_warning [array names items_by_warning] {
	wipeWarning $i_warning
    }
}

body WarningSummary::wipeWarning { a_warning } {
    set t_item $items_by_warning($a_warning)
    $itk_component(warning_tree) item delete $t_item
    array unset items_by_warning $a_warning
    array unset warnings_by_item $t_item
}
	
body WarningSummary::deleteWarning { a_warning } {
    wipeWarning $a_warning
    $warning_widget deleteWarning $a_warning
    if {[llength [array names warnings_by_item]] == 0} {
	drop
    }
}

body WarningSummary::addWarning { a_warning } {
    # create a new item
    set l_item [$itk_component(warning_tree) item create]
    # set the item's style
    $itk_component(warning_tree) item style set $l_item 0 s1
    # update the item's icon
    $itk_component(warning_tree) item element configure $l_item 0 e_icon -image [$a_warning getIcon]
    # update the item's text
    $itk_component(warning_tree) item text $l_item 0 [$a_warning getMessage]
    # add the new item to the tree
    $itk_component(warning_tree) item lastchild root $l_item
    # Store pointer to warning objects and items by number, item or object
    set warnings_by_item($l_item) $a_warning
    set items_by_warning($a_warning) $l_item
}

body WarningSummary::clickWarning { w x y } {
    set id [$w identify $x $y]
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "item"} {
	foreach {what item where arg1 arg2 arg3} $id break
	if {[lindex $id 5] == "e_delete"} {
	    deleteWarning $warnings_by_item($item)
	}
    }
}

body WarningSummary::doubleClickWarning { w x y } {
    set id [$w identify $x $y]
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "item"} {
	foreach {what item where arg1 arg2 arg3} $id break
	#puts [$warnings_by_item($item) getExplanation]
	popDetail $item
    }
}

body WarningSummary::clickPopup { a_x a_y } {
    set l_clicked_widget [winfo containing $a_x $a_y]
    #puts $l_clicked_widget
    if {($l_clicked_widget == "") || ([winfo toplevel $l_clicked_widget] != $itk_component(hull))} {
	drop
    }
}

body WarningSummary::popDetail { item } {
    if {![winfo exists .warningDetail]} {
	WarningDetail .warningDetail
    }
    #after cancel $ungrab_queue
    .warningDetail pop $itk_component(hull) [$warnings_by_item($item) getExplanation] \
	[$warnings_by_item($item) getHint] [$warnings_by_item($item) getNote]
}

body WarningSummary::constructor { args } {
    itk_option add hull.relief
    itk_option add hull.borderwidth
    itk_option add hull.width
    itk_option add hull.height
    
    $itk_component(hull) configure \
	-relief raised \
	-borderwidth 1 \
	-width 420 \
	-height 300

    grid propagate $itk_component(hull) 0
    
    wm withdraw $itk_component(hull)
    wm overrideredirect $itk_component(hull) 1
    if {[tk windowingsystem] == "aqua"} {
	::tk::unsupported::MacWindowStyle style $itk_component(hull) floating noTitleBar
    }
    
    # Warning list (tree)
    itk_component add warning_tree {
	treectrl $itk_interior.itree \
	    -showheader 0 \
	    -showroot 0 \
	    -showline 0 \
	    -showbutton 0 \
	    -selectmode single \
	    -highlightthickness 0
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    }

    $itk_component(warning_tree) column create -justify left -minwidth 200 -tag warnings
    $itk_component(warning_tree) element create e_icon image -image ::img::status_warning_on16x16
    $itk_component(warning_tree) element create e_delete image -image ::img::status_ok16x16
    $itk_component(warning_tree) element create e_text text -fill {white selected}
    $itk_component(warning_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }

    $itk_component(warning_tree) style create s1
    $itk_component(warning_tree) style elements s1 { e_highlight e_icon e_text e_delete }
    $itk_component(warning_tree) style layout s1 e_icon -expand ns -padx {4 4}
    $itk_component(warning_tree) style layout s1 e_text -expand ns -sticky w -width 320
    $itk_component(warning_tree) style layout s1 e_delete -expand ns -iexpand w -sticky e -padx {4 4}
    $itk_component(warning_tree) style layout s1 e_highlight -union [list e_icon e_text] -iexpand nse -ipadx 2
    
    bind $itk_component(warning_tree) <ButtonPress-1> [code $this clickWarning %W %x %y]
    bind $itk_component(warning_tree) <Double-ButtonPress-1> [code $this doubleClickWarning %W %x %y]

    # Scrollbar
    itk_component add scrollbar {
	scrollbar $itk_interior.scroll \
	    -command [list $itk_component(warning_tree) yview] \
	    -orient vertical
    }
    
    $itk_component(warning_tree) configure \
	-yscrollcommand [list autoscroll $itk_component(scrollbar)]
    
    grid x $itk_component(warning_tree) $itk_component(scrollbar) x -sticky news -pady 7
    grid columnconfigure $itk_component(hull) {0 3} -minsize 7
    grid columnconfigure $itk_component(hull) {1} -weight 1
    grid rowconfigure $itk_component(hull) 0 -weight 1
    eval itk_initialize $args
 }

# Details  #############################################################

class WarningDetail {
    inherit itk::Toplevel

    #private variable ungrab_queue ""

    public method clickDetail
    public method drop
    public method pop
    private variable aqua_offset
    constructor { args } { }
}

body WarningDetail::constructor { args } {
    itk_option add hull.relief
    itk_option add hull.borderwidth
    itk_option add hull.width
    itk_option add hull.height

    if {[tk windowingsystem] == "aqua"} {
	# Offset position of Details text box to allow for aqua 'traffic light' buttons
	set aqua_offset 23
    } else {
	set aqua_offset 0
    }

    $itk_component(hull) configure \
	-relief raised \
	-borderwidth 1 \
	-width 840 \
	-height [expr 315 + $aqua_offset]

    grid propagate $itk_component(hull) 0
    
    wm withdraw $itk_component(hull)
    if {[tk windowingsystem] == "aqua"} {
	::tk::unsupported::MacWindowStyle style $itk_component(hull) document closeBox
	# the following format is deprecated - see http://wiki.tcl.tk/13428
	#::tk::unsupported::MacWindowStyle style <win> <style>
    } else {
	# override window manager if not aqua on MacOS X. Clicking off the window should close
	wm overrideredirect $itk_component(hull) 1
    }
    
    # Details text box (treectrl was overkill)
    itk_component add detail_box {
	text $itk_interior.detail
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    }

    bind $itk_component(detail_box) <ButtonPress-1> [code $this clickDetail %X %Y]

    # Scrollbar
    itk_component add scrollbar {
	scrollbar $itk_interior.scroll \
	    -command [list $itk_component(detail_box) yview] \
	    -orient vertical
    }
    
    $itk_component(detail_box) configure \
	-yscrollcommand [list autoscroll $itk_component(scrollbar)]

    grid x $itk_component(detail_box) $itk_component(scrollbar) x -sticky news -pady 7
    grid columnconfigure $itk_component(hull) {0 3} -minsize 7
    grid columnconfigure $itk_component(hull) {1} -weight 1
    grid rowconfigure $itk_component(hull) 0 -weight 1
    eval itk_initialize $args
}

body WarningDetail::pop { a_widget fulltext hint note } {

    # update text box with the details etc.
    $itk_component(detail_box) insert end "Details:\n\n$fulltext\n\nHints:\n\n$hint\n\nNotes:\n\n$note\n"

    # Position and show pop up
    set l_x [expr [winfo rootx $a_widget] - [$a_widget cget -width]]
    set l_y [expr [winfo rooty $a_widget] - [$itk_component(hull) cget -height] - $aqua_offset]
    wm geometry $itk_component(hull) +$l_x+$l_y
    wm deiconify $itk_component(hull)
    raise $itk_component(hull)
    grab $itk_component(hull)
    bind $itk_component(hull) <ButtonPress-1> [code $this clickDetail %X %Y]
}

body WarningDetail::clickDetail { a_x a_y } {
    set l_clicked_widget [winfo containing $a_x $a_y]
    if { ($l_clicked_widget == $itk_component(detail_box)) || $l_clicked_widget == $itk_component(scrollbar)} {
    } else {
	drop
    }
}

body WarningDetail::drop { } {
    $itk_component(detail_box) delete 1.0 end
    grab release $itk_component(hull) 
    wm withdraw $itk_component(hull)
#    focus .warningSummary.itree
}
