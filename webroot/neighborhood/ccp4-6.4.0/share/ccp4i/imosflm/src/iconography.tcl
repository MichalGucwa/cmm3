# $Id: iconography.tcl,v 1.8 2010/01/21 16:02:24 rmk65 Exp $
package provide iconography 1.0

####################################################

namespace eval img {}
image create photo ::img::defaultfile -data "R0lGODlhEAAQAOcAAIWFhYKCgn5+fnp6end3d3Nzc29vb7a2tqOjo4CAgP////v7+/f39/Ly8v7+/n9/f3t7e/r6+vb29u3t7ZGRkezs7N3d3VtbW3Z2dvn5+fX19fHx8ejo6Nra2svLy7u7uzY2NnFxcfj4+PT09PDw8PCnp/0TE/wSEm1tbUhISCQkJGxsbPPz8+/v7/CoqP4AAP4CAv4BAaYmJp96ep6enqSkpENDQ2dnZ+7u7urq6vwUFN3X19jS0rE8PKGhoaenpz4+PmJiYunp6eTk5OqXl+eUlNfX19i6uvoQEMbGxsLCwjk5OV1dXd/f39vb296VldWNjcHBwb29vTQ0NFhYWN7e3tbW1tHR0cqsrMDAwLy8vLe3ty8vL1NTU9nZ2dXV1dDQ0MzMzL+/v7KysioqKk5OTtTU1MfHx9aDg9OAgLq6urGxsa2trSUlJUlJSc/Pz8rKyvkREfgQELW1tbCwsKysrKioqCAgIMnJycXFxc98fMx5ea+vr6urqxsbG8TExLOzs6qqqqampqKiop2dnRYWFjIyMi4uLisrKycnJyMjIxwcHBgYGBUVFREREf///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////yH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgD/ACwAAAAAEAAQAAAI5wD//QMQQMAAAgUMHEAgsKHABAoiLmDQAIGDBw4FQogYQUKDCRQqWLiQEYODDBo2VODwoIOHDyAchhAxgkQJEydQXEgBQoXDFSxauHgBI4aMGTRq2HB4A0cOHTB28IDRw8cPIA6DCBlCpIiRIzGQJFGyxCGTIU2cGHny4gWUKFKmOKRSpYOVK0hgYMmiZQsXh128fAETJkYMMR+2jCHjsIwZMB7OoEmj5sAaNm0cunkDZ2wcOXPo1LFzx6ENPHmiaNGzh0+fHwj8OATyh+8WQHwCCRpEqJDDJSAMHUKUSNGdRYwaORIYEAA7"
image create photo ::img::plus -data "R0lGODlhCQAJAIAAAAAAAP///yH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAsAAAAAAkACQAAAhGEj6EbtvCgkg0iS3OOLN5TAAA7"
image create photo ::img::minus -data "R0lGODlhCQAJAIAAAAAAAP///yH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAsAAAAAAkACQAAAhCEj6EbxuteA/NMeWV8qIMCADs="

#####################################################

class Tree {

    protected variable parent ""
    protected variable children ""

    public method treeConfigure
    public method deleteItem

    protected method add
    protected method clear
    protected method print
    protected method root
    protected method getAncestor
    private method parent


    constructor { args } { 
	eval configure $args
    }

    destructor { 
	clear
    }
}

body Tree::treeConfigure { args } {
    eval configure $args
    foreach child $children {
	eval $child treeConfigure $args
    }
}

body Tree::add { a_tree } {
    $a_tree parent $this
    lappend children $a_tree
}

body Tree::deleteItem { an_item } {
    set position [lsearch $children $an_item]
    if {$position == -1} {
	foreach child $children {
	    if {[$child deleteItem $an_item]} {
		return 1
	    }
	}
	return 0
    } else {
	delete object [lindex $children $position]
	set children [lreplace $children $position $position]
	return 1
    }
} 

body Tree::parent { a_tree } {
    set parent $a_tree
}

body Tree::clear { } {
    if {$children != {}} {
	catch {eval delete object $children}
    }
}

body Tree::print { } {
    foreach child $children {
	$child print
    }
    puts $this
}

body Tree::root { } {
    if {$parent != ""} {
	return [$parent root]
    } else {
	return $this
    }
}

body Tree::getAncestor { {level 1} } {
    set a_tree $this
    while {$level > 0} {
	set a_tree [$a_tree cget -parent]
	incr level -1
    }
    return $a_tree
}

#####################################################
#####################################################

class VisualRepresentation {

    # member variables
    ##################

    # defining variables
    private variable identity ""
    private variable canvas ""
    
    # configurable options
    public variable state "open"
    public variable label ""
    public variable image  "::img::defaultfile"
    public variable altimage ""
    public variable command ""
    public variable doubleclick ""
    public variable selectcommand ""
    public variable validatenamecommand ""
    public variable click ""
    public variable ctrlclick ""
    public variable shiftclick ""
    public variable ctrlshiftclick ""
    public variable editable 0
    public variable selectable 1
    public variable selectbackground "\#909090"
    public variable ring "visible"

    #private variable icon "::img::defaultfile"
    private variable selected  0
    private variable click_queue ""
    private variable entry ""
    private variable entry_window ""
    private variable concealer ""

    # member methods
    ################

    public method getIdentity

    public method getImageHeight
    public method getImageWidth

    public method click
    public method ctrlClick
    public method shiftClick
    public method ctrlShiftClick
    public method doubleClick
    public method nameClick
    public method renameClick
    
    public method renameStart
    public method renameKeyRelease
    public method renameCancel
    public method renameComplete

    public method draw
    public method setCanvas

    public method select
    public method deselect
    public method isSelected
    public method isSelectable

    public method toggle
    public method ring
    public method unRing
    protected method erase
    protected method highlight

    constructor { a_identity a_canvas args } {
	set identity $a_identity
        set canvas $a_canvas
	eval configure $args
    }

    destructor {
        erase
	# Tell the visual item I belong to that I've been deleted
	$identity signOffVisualRep $this
    }
}

# Identity accessor ###########################

body VisualRepresentation::getIdentity { } {
    return $identity
}

# Utility functions ###########################

body VisualRepresentation::getImageHeight { } {
    if {$image != ""} {
	return [image height $image]
    } else {
	return 0
    }
}

body VisualRepresentation::getImageWidth { } {
    if {$image != ""} {
	return [image width $image]
    } else {
	return 0
    }
}

# Mouse click methods #########################

body VisualRepresentation::click { } {
    if {$click == ""} {
	select
	ring
    } else {
	uplevel \#0 $click $this
    }
}

body VisualRepresentation::ctrlClick { } {
    if {$ctrlclick == ""} {
	click
    } else {
	uplevel \#0 $ctrlclick $this
    }
}

body VisualRepresentation::shiftClick { } {
    if {$shiftclick == ""} {
	click
    } else {
	uplevel \#0 $shiftclick $this
    }
}

body VisualRepresentation::ctrlShiftClick { } {
    if {$ctrlshiftclick == ""} {
	click
    } else {
	uplevel \#0 $ctrlshiftclick $this
    }
}

body VisualRepresentation::doubleClick { } {
    after cancel $click_queue
    toggle
    if {$doubleclick != ""} {
	uplevel \#0 $doubleclick $this
    }
}

body VisualRepresentation::nameClick { } {
    if {$editable == 1 && $selected == 1} {
	set click_queue [after 500 $this renameStart]
    } else {
	click
    }
}

body VisualRepresentation::renameClick { x y } {
    if {[winfo containing $x $y] != $entry} {
	renameCancel
    }
}

# Selection methods ############################

body VisualRepresentation::select { } {
    if {$selectable == 1} {
	set selected 1
	highlight
    }
}

body VisualRepresentation::deselect { } {
    set selected 0
    highlight 0
}

body VisualRepresentation::isSelected { } {
    return $selected
}

body VisualRepresentation::isSelectable { } {
    return $selectable
}

# Renaming methods ##############################

body VisualRepresentation::renameStart { } {
    if {[winfo exists $canvas]} {
	set entry [entry ${canvas}.an_entry \
		       -bg [$canvas cget -background] \
		       -bd 0 \
		       -highlightthickness 1 \
		       -highlightbackground \#000000 \
		       -highlightcolor \#000000 \
		       -selectbackground \#3399ff \
		       -selectborderwidth 0 \
		       -selectforeground \#ffffff \
		       -font font_e \
		       -width [expr [string length $label] + 1]]
	bind $entry <KeyRelease> [code $this renameKeyRelease %K]
	bind $entry <FocusOut> [code $this renameCancel]
	set coords [$canvas bbox ${this}text]
	set coords [lreplace $coords 1 1 [expr [lindex $coords 1] - 1]]
	set concealer [$canvas create rectangle $coords \
			   -fill [$canvas cget -background] \
			   -outline [$canvas cget -background]]
	foreach {x y} [$canvas coords ${this}text] break
	set x [expr $x - 2]
	set entry_window [$canvas create window $x $y -window $entry -anchor w]
	$entry insert 0 $label
	$entry selection range 0 end
	focus $entry
	#update
	grab $entry
	bindtags $entry [concat [bindtags $entry] rename]
	bind rename <Button-1> [code $this renameClick %X %Y]
    }
}

body VisualRepresentation::renameKeyRelease { keysym } {
    switch -- $keysym {
	Return {
	    renameComplete
	}
	Escape {
	    renameCancel
	}
	default {
	    $entry configure -width [expr [string length [$entry get]] + 1]
	}
    }
}

body VisualRepresentation::renameCancel { } {
    $canvas delete $entry_window $concealer
    destroy $entry
    highlight
}

body VisualRepresentation::renameComplete { } {
    if {$validatenamecommand != ""} {
	if {[uplevel \#0 $validatenamecommand [$entry get]] == 0} {
	    bell
	}
    } else {
	set label [$entry get]
	$canvas delete $entry_window $concealer
	destroy $entry
	$canvas itemconfigure ${this}text -text $label
	highlight
	ring
    }
}

# Drawing methods ################################

body VisualRepresentation::setCanvas { a_canvas } {
    if {$canvas != ""} {
	$canvas delete all
    }
    set canvas $a_canvas
}

body VisualRepresentation::draw { x y } {

    # draw icon
	$canvas create image $x $y -anchor nw -tags $this
    if {$state == "open" || $altimage == ""} { 
	$canvas itemconfigure $this -image $image
    } else {
	$canvas itemconfigure $this -image $altimage
    }

    # draw label
    set x1 [expr $x + [image width $image] + 2]
    set y1 [expr $y + ([image height $image] / 2)]
    $canvas create text $x1 $y1 -text $label -anchor w -tags ${this}text

    # draw highlight (if necessary)
    if {$selected} {
	highlight
    }

    # set up mouse bindings
    $canvas bind $this <ButtonPress-1> [code $this click]
    $canvas bind $this <Control-ButtonPress-1> [code $this ctrlClick]
    $canvas bind $this <Control-Shift-ButtonPress-1> [code $this ctrlShiftClick]
    $canvas bind $this <Shift-ButtonPress-1> [code $this shiftClick]
    $canvas bind $this <Double-ButtonPress-1> [code $this doubleClick]
    $canvas bind ${this}text <ButtonPress-1> [code $this nameClick]
    $canvas bind ${this}text <Control-ButtonPress-1> [code $this ctrlClick]
    $canvas bind ${this}text <Shift-ButtonPress-1> [code $this shiftClick]
    $canvas bind ${this}text <Control-Shift-ButtonPress-1> [code $this ctrlShiftClick]
    $canvas bind ${this}text <Double-ButtonPress-1> [code $this doubleClick]


}

body VisualRepresentation::erase {} {
    if {$canvas != ""} {
	$canvas delete $this ${this}highlight ${this}text ${this}ring ${this}_button
    }
}

body VisualRepresentation::highlight { {on 1} } {
    if {$canvas != ""} {
	if {$on} {
	    $canvas delete ${this}highlight
	    set coords [$canvas bbox ${this}text]
	    set coords [lreplace $coords 1 1 [expr [lindex $coords 1] - 1]]
	    $canvas create rectangle $coords -fill $selectbackground -outline $selectbackground -tags ${this}highlight
	    $canvas lower ${this}highlight ${this}text
	    $canvas itemconfigure ${this}text -fill white
	} else {
	    $canvas delete ${this}highlight
	    $canvas itemconfigure ${this}text -fill black
	}
    }
}

body VisualRepresentation::ring { } {
    if {$ring == "visible"} {
	set coords [$canvas bbox ${this}text]
	set coords [lreplace $coords 1 1 [expr [lindex $coords 1] - 1]]
	$canvas create rectangle $coords -outline white -tags ${this}ring
	$canvas create rectangle $coords -outline $selectbackground -dash {1 2} -tags ${this}ring
    }
}

body VisualRepresentation::unRing { } {
    $canvas delete ${this}ring
}

body VisualRepresentation::toggle { } {
    if {$state == "open"} {
	set state "closed"
	$canvas itemconfigure $this -image $image
    } else {
	set state "open"
	if {$altimage != ""} {
	    $canvas itemconfigure $this -image $altimage
	}
    }
}
	
# Configuration callbacks #########################

configbody VisualRepresentation::label {
    if {$canvas != ""} {
	$canvas itemconfigure ${this}text -text $label
    }
    $identity configure -label $label
}

####################################################
####################################################

class VisualItem {

    public variable image ""
    public variable altimage ""
    public variable label ""
    public variable selectcommand ""

    private variable state "open"
    
    private variable visual_reps { }

    public method createVisualRep
    public method signOffVisualRep
    public method recordDisplaySettings
    public method getState
    public method getSelectCommand

    constructor { args } { }
    destructor { 
	eval delete object $visual_reps
    }

}

body VisualItem::constructor { args } {
    eval configure $args
}

body VisualItem::destructor { } {
    foreach visual_rep $visual_reps {
	delete object $visual_rep
    }
}

body VisualItem::createVisualRep { a_canvas args } {
    set new_visual_rep [namespace current]::[VisualRepresentation \#auto $this $a_canvas \
						 -image $image \
						 -state $state \
						 -selectcommand $selectcommand \
						 -label $label]
    if {$altimage != ""} {
	$new_visual_rep configure -altimage $altimage
    }
    eval $new_visual_rep configure $args

    lappend visual_reps $new_visual_rep
    return $new_visual_rep
}

body VisualItem::signOffVisualRep { a_visual_rep } { 
    set l_index [lsearch $visual_reps $a_visual_rep]
    if {$l_index > -1} {
	set visual_reps [lreplace $visual_reps $l_index $l_index]
    } else {
	error "Trying to sign deleted VisualRepresentation $a_visual_rep off from $this, but couldn't find it!"
    }
} 

body VisualItem::recordDisplaySettings { a_state a_selectcommand} {
    set state $a_state
    set selectcommand $a_selectcommand
}

body VisualItem::getState { } {
    return $state
}

body VisualItem::getSelectCommand { } {
    return $selectcommand
}

####################################################
####################################################

class VisualDisplayIndex {

    private variable visible_list {}
    private variable current ""
    private variable anchor ""

    # visibile items
    
    public method clearVisiblelist { } {
	set visible_list {}
    }

    public method appendVisiblelist { item } {
	lappend visible_list $item
    }

    public method getVisiblelist { } {
	return $visible_list
    }

    public method getVisibleRange { start end } {
	set start [lsearch $visible_list $start]
	set end [lsearch $visible_list $end]
	if {$start < $end} {
	    set range [lrange $visible_list $start $end]
	} else {
	    set range [lrange $visible_list $end $start]
	}
	return $range
    }
    
    # current item

    public method setCurrent { item } {
	if {$current != ""} {
	    $current unRing
	}
	set current $item
	$current ring
    }
    
    public method clearCurrent { } {
	set current ""
    }
    
    public method getCurrent { } {
	return $current
    }

    # anchor item

    public method getAnchor { } {
	return $anchor
    }

    public method setAnchor { item } {
	set anchor $item
    }
    
    constructor { } { }
}

####################################################
####################################################

class VisualDisplay {

    # Options
    #########
    # Colours
    public variable selectbackground ""
    public variable ring ""
    # Selection callback
    public variable selectcommand ""

    protected variable canvas ""
    protected variable index ""

    # Accessor methods
    public method getCanvas

    # Display methods
    public method display
    public method refresh
    public method draw { } { } ;# virtual

    # Key binding callbacks
    public method keyUp
    public method keyDown
    public method keyShiftUp
    public method keyShiftDown
    public method keyCtrlUp
    public method keyCtrlDown
    public method keyShiftCtrlUp
    public method keyShiftCtrlDownComm
    public method keySpace
    public method keyDelete

    private method adjustYViewUp
    private method adjustYViewDown

    # Mouse click callbacks
    public method canvasClick
    public method click
    public method ctrlClick
    public method shiftClick
    public method ctrlShiftClick
    public method doubleClick

    # Focus shifting callbacks
    public method focusIn { } { } ;# virtual
    public method focusOut { } { }  ;# virtual

    # Selection methods
    protected method executeSelectCommand
    protected method deselectAll { } { } ;# virtual
    protected method getSelection { } { } ;# virtual

    constructor { a_canvas {an_index ""} } {
	if {$an_index == ""} {	    
	    set index [namespace current]::[VisualDisplayIndex \#auto]
	} else {
	    set index $an_index
	} 
	set canvas $a_canvas
    }

    destructor {
	# Clear canvas
	$canvas delete all

	# Remove key bindings
	$canvas configure -takefocus 0
	bind $canvas <Up> {}
	bind $canvas <Down> {}
	bind $canvas <Shift-Up> {}
	bind $canvas <Shift-Down> {}
	bind $canvas <Control-Up> {}
	bind $canvas <Control-Down> {}
	bind $canvas <Shift-Control-Up> {}
	bind $canvas <Shift-Control-Down> {}
	bind $canvas <space> {}
	bind $canvas <Delete> {}
	
	# Remove focus bindings
	bind $canvas <Button-1> {}
	bind $canvas <FocusIn> {}
	bind $canvas <FocusOut> {}

	delete object $index
    }
}

# Accessor methods

body VisualDisplay::getCanvas { } {
    return $canvas
}

# Display methods

body VisualDisplay::display { } {
    $canvas delete all
    # Clear the index's list of visible items
    $index clearVisiblelist
    # Draw the entire tree
    draw 1 1
    # if there is no current item, make the first visible item current and ring it
    if {[$index getCurrent] == ""} {
	if {[llength [$index getVisiblelist]] != 0} {
	    $index setCurrent [lindex [$index getVisiblelist] 0]
	    [lindex [$index getVisiblelist] 0] ring
	    # Also set the current item as the 'click anchor'
	    #  (used for shift-click/up/down)
	    $index setAnchor [lindex [$index getVisiblelist] 0]
	}
    }
    # Set the canvas's scroll region
    if {[$canvas bbox all] != ""} {
	set bbox [lreplace [$canvas bbox all] 0 1 1 1]
	$canvas configure -scrollregion $bbox
    }
	# Set up key bindings
	$canvas configure -takefocus 1
	bind $canvas <Up> [code $this keyUp]
	bind $canvas <Down> [code $this keyDown]
	bind $canvas <Shift-Up> [code $this keyShiftUp]
	bind $canvas <Shift-Down> [code $this keyShiftDown]
	bind $canvas <Control-Up> [code $this keyCtrlUp]
	bind $canvas <Control-Down> [code $this keyCtrlDown]
	bind $canvas <Shift-Control-Up> [code $this keyShiftCtrlUp]
	bind $canvas <Shift-Control-Down> [code $this keyShiftCtrlDown]
	bind $canvas <space> [code $this keySpace]
	bind $canvas <Delete> [code $this keyDelete]
	
	# Set up focus bindings
	bind $canvas <Button-1> [code $this canvasClick]
	bind $canvas <FocusIn> [code $this focusIn]
	bind $canvas <FocusOut> [code $this focusOut]
}

body VisualDisplay::refresh { } {
    display
}

# Mouse click methods

body VisualDisplay::canvasClick { } {
    if {[focus] != $canvas} {
	focus $canvas
    }
}

body VisualDisplay::click { an_item } {
    deselectAll
    $an_item select
    $index setCurrent $an_item
    $index setAnchor $an_item
    executeSelectCommand
}

body VisualDisplay::ctrlClick { an_item } {
    if {[$an_item isSelected]} {
	$an_item deselect
    } elseif {[$an_item isSelectable]} {
	$an_item select
    }
    $index setCurrent $an_item
    $index setAnchor $an_item
    executeSelectCommand
}

body VisualDisplay::ctrlShiftClick { an_item } {
    set anchor [$index getAnchor]
    set range [$index getVisibleRange $anchor $an_item]
    foreach item $range {
	if {[$item isSelectable]} {
	    $item select
	}
    }
    $index setCurrent $an_item
    executeSelectCommand
}

body VisualDisplay::shiftClick { an_item} {
    deselectAll
    ctrlShiftClick $an_item
    executeSelectCommand
}

# Key binding methods

body VisualDisplay::keyUp { } {
    set current [$index getCurrent]
    if {$current == ""} {
	# If there is no current item, click on the top item
	if {[llength [$index getVisiblelist]] != 0} {
	    [lindex [$index getVisiblelist] 0] click
	    adjustYViewUp  [lindex [$index getVisiblelist] 0]
	}
    } else {
	# find the item above the current item, and click on it 
	set position [lsearch [$index getVisiblelist] $current]
	incr position -1
	if {$position < 0 } { set position 0 }
	[lindex [$index getVisiblelist] $position] click
	adjustYViewUp [lindex [$index getVisiblelist] $position]
    }
    executeSelectCommand
}
 
body VisualDisplay::keyDown { } {
    set current [$index getCurrent]
    if {$current == ""} {
	# If there is no current item, click on the bottom item
	if {[llength [$index getVisiblelist]] != 0} {
	    [lindex [$index getVisiblelist] end] click
	    adjustYViewDown [lindex [$index getVisiblelist] end]
	}
    } else {
	# find the item below the current item, and click on it 
	set position [lsearch [$index getVisiblelist] $current]
	incr position +1
	if {$position > [llength [$index getVisiblelist]] - 1} { set position end }
	[lindex [$index getVisiblelist] $position] click
	adjustYViewDown [lindex [$index getVisiblelist] $position]
    }
    executeSelectCommand
}

body VisualDisplay::adjustYViewUp { an_item } {
    set y_coord [lindex [$canvas coords $an_item] 1]
    set height [expr [image height [$an_item cget -image]] + 2]
    set screensize [winfo height $canvas]
    set y_max [lindex [$canvas cget -scrollregion] 3]
    set y_view [$canvas yview]
    if {$y_coord < [expr [lindex $y_view 0] * $y_max]} {
	   $canvas yview moveto [expr $y_coord / $y_max]
    }
}

body VisualDisplay::adjustYViewDown { an_item } {
    set y_coord [lindex [$canvas coords $an_item] 1]
    set height [expr [image height [$an_item cget -image]] + 2]
    set screensize [winfo height $canvas]
    set y_max [lindex [$canvas cget -scrollregion] 3]
    set y_view [$canvas yview]
    if {[expr $y_coord + $height] > [expr [lindex $y_view 1] * $y_max] && [lindex $y_view 1] < 1} {
	$canvas yview moveto [expr ($y_coord + $height - $screensize) / $y_max]
    }
}

body VisualDisplay::executeSelectCommand { } { 
    if {$selectcommand != ""} {
	uplevel \#0 $selectcommand [getSelection]
    }
}

####################################################
####################################################

class VisualTree {
    inherit VisualDisplay Tree

    public variable command ""
    public variable selectable "1"

    private variable visual_rep ""
    private variable state "open"

    public method getVisualRep
    public method draw
    public method add
    public method doubleClick
    public method execute
    public method executeSelectCommand
    public method refresh
    public method uploadOptions

    public method getSelection
    public method getSelectionRecursively
    public method deselectAll
    private method recursiveDeselect

    public method focusIn
    public method focusOut
    public method setFocusRecursively

    constructor { a_canvas a_visual_item an_index args } {
	VisualDisplay::constructor $a_canvas $an_index
    } {
	set state [$a_visual_item getState]
	set selectcommand [$a_visual_item getSelectCommand]
	eval configure $args

	set visual_rep [$a_visual_item createVisualRep $a_canvas \
			    -selectable $selectable \
			    -click [code $this click] \
			    -doubleclick [code $this doubleClick] \
			    -ctrlclick [code $this ctrlClick] \
			    -shiftclick [code $this shiftClick] \
			    -ctrlshiftclick [code $this ctrlShiftClick]]
    }

    destructor {
	eval delete object $visual_rep
	$canvas delete all
    }

}

body VisualTree::getVisualRep { } {
    return $visual_rep
}

body VisualTree::draw { x y } {
    # Draw item 
    $visual_rep draw $x $y

    # add to index's list of visible items
    $index appendVisiblelist $visual_rep
    
    if {[$index getCurrent] == $visual_rep} {
	$visual_rep ring
    }
    
    # Draw connecting line to parent and plus if it's got a parent on the canvas
    if {$parent != ""} {
	# Has parent try and get parent coords to see if it's pictured
	set x0 ""
	set y0 ""
	foreach {x0 y0} [$canvas coords [$parent getVisualRep]] { }
	if {$x0 != "" && $y0 != ""} {
	    # Parent is pictured so draw connected line
	    set x0 [expr $x0 + [$visual_rep getImageWidth] / 2]
	    set y0 [expr $y0 + [$visual_rep getImageHeight] / 2]
	    set x1 [expr $x + [$visual_rep getImageWidth] / 2]
	    set y1 [expr $y + [$visual_rep getImageHeight] / 2]
	    set line [$canvas create line $x0 $y0 $x0 $y1 $x1 $y1 -fill \#000000 -dash {1 1 1 1}]
	    if {[llength $children] > 0} {
		if {$state == "open"} {
		    $canvas create image $x0 $y1 -image ::img::minus -anchor c -tags ${visual_rep}_button
		} else {
		    $canvas create image $x0 $y1 -image ::img::plus -anchor c -tags ${visual_rep}_button
		}
		$canvas bind ${visual_rep}_button <ButtonPress-1> [list $visual_rep doubleClick]
	    }
	    $canvas lower $line
	}
    }
    
    # Deal with children recursively, keeping track of position down canvas
    if {$state == "open"} {
	incr x 18
	foreach child $children {
	    incr y [expr [$visual_rep getImageHeight]]
	    set y [$child draw $x $y]
	}
    }
    return $y
}

body VisualTree::add { a_visual_item args } {
    set new_visual_tree [namespace current]::[eval VisualTree \#auto $canvas $a_visual_item $index $args]
    Tree::add $new_visual_tree
    return $new_visual_tree
}


body VisualTree::doubleClick { a_visual_rep } {
    if {$state == "closed"} {
	set state "open"
    } elseif {$state == "open"} {
	set state "closed"
    }
    execute 
    refresh
}

body VisualTree::execute { } {
    if {$command != ""} {
	uplevel \#0 $command [$visual_rep getIdentity]
    }
}

body VisualTree::executeSelectCommand { } {
    if {[[root] cget -selectcommand] != ""} {
	uplevel \#0 [[root] cget -selectcommand] [[root] getSelection]
    }
}

body VisualTree::refresh { } {
    [root] display
}

body VisualTree::deselectAll { } {
    [root] recursiveDeselect
}

body VisualTree::recursiveDeselect { } {
    $visual_rep deselect
    foreach child $children {
	$child recursiveDeselect
    }
}    

body VisualTree::uploadOptions { } {
    catch {[$visual_rep getIdentity] recordDisplaySettings $state $selectcommand}
    foreach child $children {
	$child uploadOptions
    }
    
}

body VisualTree::getSelection { } {
    return [[root] getSelectionRecursively]
}

body VisualTree::getSelectionRecursively { } {
    set selection { }
    if {[$visual_rep isSelected]} {
	lappend selection [$visual_rep getIdentity]
    }
    foreach child $children {
	eval lappend selection [$child getSelectionRecursively]
    }
    return $selection
}

# Focus shifting callbacks

body VisualTree::focusIn { } {
    setFocusRecursively 1
    refresh
}

body VisualTree::focusOut { } {
    setFocusRecursively 0
    refresh
}
	
body VisualTree::setFocusRecursively { a_bool } {
    if {$a_bool} {
	$visual_rep configure -selectbackground "\#3399ff"
	$visual_rep configure -ring "visible"
	foreach child $children {
	    $child setFocusRecursively $a_bool
	}
    } else {
	$visual_rep configure -selectbackground "\#909090"
	$visual_rep configure -ring "invisible"
	foreach child $children {
	    $child setFocusRecursively $a_bool
	}
    }
}

####################################################
####################################################

class VisualList {
    inherit VisualDisplay
    
    private variable items {}

    public variable command ""
    public variable selectcommand ""
    public variable updatecommand ""
    public variable selectable "1"

    public method length
    public method getIdentities
    public method draw

    public method add
    public method deleteItem
    public method clear

    public method doubleClick
    public method execute
    public method executeSelectCommand
    public method executeUpdateCommand
    public method uploadOptions

    public method getSelection
    public method deselectAll

    public method focusIn
    public method focusOut
    public method setFocus

    constructor { a_canvas an_index args } {
	VisualDisplay::constructor $a_canvas $an_index
    } {
	eval configure $args
    }

    destructor {
	eval delete object $items
	$canvas delete all
    }


}

body VisualList::length { } {
    return [llength $items]
}

body VisualList::getIdentities { } {
    set identities {}
    foreach item $items {
	lappend identities [$item getIdentity]
    }
    return $identities
}

body VisualList::draw { x y } {
    foreach item $items {
	# Draw item 
	$item draw $x $y
	# add to index's list of visible items
	$index appendVisiblelist $item
	# add ring if necessary
	if {[$index getCurrent] == $item} {
	    $item ring
	}
    	# increment y
	incr y [$item getImageHeight]
    }
}

body VisualList::add { a_visual_item args } {
    set new_item [$a_visual_item createVisualRep $canvas \
		      -selectable $selectable \
		      -click [code $this click] \
		      -doubleclick [code $this doubleClick] \
		      -ctrlclick [code $this ctrlClick] \
		      -shiftclick [code $this shiftClick] \
		      -ctrlshiftclick [code $this ctrlShiftClick]]
    lappend items $new_item
    refresh
    executeUpdateCommand
    return $new_item
}

body VisualList::deleteItem { a_visual_item } {
    set i_index 0
    foreach i_item $items {
	if {[$i_item getIdentity] == $a_visual_item} {
	    break
	}
    }
    set items [lreplace $items $i_index $i_index]
    delete object $i_item
}

body VisualList::clear { } {
    if {$items != {}} {
	delete object $items
	set items {}
    }
} 

body VisualList::doubleClick { a_visual_rep } {
    execute 
    refresh
}

body VisualList::execute { } {
    if {$command != ""} {
	uplevel \#0 $command [$visual_rep getIdentity]
    }
}

body VisualList::executeSelectCommand { } {
    if {$selectcommand != ""} {
	uplevel \#0 $selectcommand [getSelection]
    }
}

body VisualList::executeUpdateCommand { } {
    if {$updatecommand != ""} {
	uplevel \#0 $updatecommand [getIdentities]
    }
}    

body VisualList::deselectAll { } {
    foreach item $items {
	$item deselect
    }
}

body VisualList::uploadOptions { } {
    foreach item $items {
	[$item getIdentity] recordDisplaySettings $state $selectcommand
    }
}

body VisualList::getSelection { } {
    set selection { }
    foreach item $items {
	if {[$item isSelected]} {
	    lappend selection [$item getIdentity]
	}
    }
    return $selection
}

# Focus shifting callbacks

body VisualList::focusIn { } {
    setFocus 1
    refresh
}

body VisualList::focusOut { } {
    setFocus 0
    refresh
}
	
body VisualList::setFocus { a_bool } {
    if {$a_bool} {
	foreach item $items {
	    $item configure -selectbackground "\#3399ff" -ring "visible"
	}
    } else {
	foreach item $items {
	    $item configure -selectbackground "\#909090" -ring "invisible"
	}
    }
}

####################################################
####################################################

