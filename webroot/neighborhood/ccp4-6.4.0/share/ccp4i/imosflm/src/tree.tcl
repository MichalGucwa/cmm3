# $Id: tree.tcl,v 1.8 2010/01/21 16:02:26 rmk65 Exp $
package provide tree 1.0

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
