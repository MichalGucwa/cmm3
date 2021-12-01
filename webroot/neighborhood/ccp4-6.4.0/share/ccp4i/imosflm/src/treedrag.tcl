# $Id: treedrag.tcl,v 1.8 2010/01/21 16:02:26 rmk65 Exp $
package provide sessiontreedrag

proc ::TreeCtrl::FileListMotion {T x y} {
    variable Priv
    if {![info exists Priv(buttonMode)]} return
    switch $Priv(buttonMode) {
	"marquee" {
	    MarqueeUpdate $T $x $y
	    set select $Priv(selection)
	    set deselect {}

	    # Check items covered by the marquee
	    foreach list [$T marque identify] {
		set item [lindex $list 0]

		# Check covered columns in this item
		foreach sublist [lrange $list 1 end] {
		    set column [lindex $sublist 0]
		    set ok 0

		    # Check covered elements in this column
		    foreach E [lrange $sublist 1 end] {
			foreach sList $Priv(sensitive,$T) {
			    set sC [lindex $sList 0]
			    set sS [lindex $sList 1]
			    set sEList [lrange $sList 2 end]
			    if {[$T column compare $column != $sC]} continue
			    if {[$T item style set $item $sC] ne $sS} continue
			    if {[lsearch -exact $sEList $E] == -1} continue
			    set ok 1
			    break
			}
		    }
		    # Some sensitive elements in this column are covered
		    if {$ok} {

			# Toggle selected status
			if {$Priv(selectMode) eq "toggle"} {
			    set i [lsearch -exact $Priv(selection) $item]
			    if {$i == -1} {
				lappend select $item
			    } else {
				set i [lsearch -exact $select $item]
				set select [lreplace $select $i $i]
			    }
			} else {
			    lappend select $item
			}
		    }
		}
	    }
	    $T selection modify $select all
	}
	"drag" {
	    if {!$Priv(drag,motion)} {
		# Detect initial mouse movement
		if {(abs($x - $Priv(drag,click,x)) <= 4) &&
		    (abs($y - $Priv(drag,click,y)) <= 4)} return

		set Priv(selection) [$T selection get]
		set Priv(drop) ""
		$T dragimage clear
		# For each selected item, add some elements to the dragimage
		foreach I $Priv(selection) {
		    foreach list $Priv(dragimage,$T) {
			set C [lindex $list 0]
			set S [lindex $list 1]
			if {[$T item style set $I $C] eq $S} {
			    eval $T dragimage add $I $C [lrange $list 2 end]
			}
		    }
		}
		set Priv(drag,motion) 1
		TryEvent $T Drag begin {}
	    }

	    # Find the element under the cursor
	    set drop ""
	    set id [$T identify $x $y]
	    set ok 0
	    if {($id ne "") && ([lindex $id 0] eq "item") && ([llength $id] == 6)} {
		set item [lindex $id 1]
		set column [lindex $id 3]
		set E [lindex $id 5]
		foreach list $Priv(sensitive,$T) {
		    set C [lindex $list 0]
		    set S [lindex $list 1]
		    set eList [lrange $list 2 end]
		    if {[$T column compare $column != $C]} continue
		    if {[$T item style set $item $C] ne $S} continue
		    if {[lsearch -exact $eList $E] == -1} continue
		    set ok 1
		    break
		}
	    }
	    if {$ok} {
		# If the item is not in the pre-drag selection
		# (i.e. not being dragged) and it is a directory,
		# see if we can drop on it
		if {[lsearch -exact $Priv(selection) $item] == -1} {

		    # NB Check to see if target is a sector (rather than checking it's a directory in original)
		    if {[.c getObjectByItem $item] isa Sector]} {
			set drop $item

# 		    if {[$T item order $item -visible] < $Priv(DirCnt,$T)} {
# 			set drop $item
			# We can drop if dragged item isn't an ancestor
			foreach item2 $Priv(selection) {
			    if {[$T item isancestor $item2 $item]} {
				set drop ""
				break
			    }
			}
		    }
		}
	    }

	    # Select the directory under the cursor (if any) and deselect
	    # the previous drop-directory (if any)
	    $T selection modify $drop $Priv(drop)
	    set Priv(drop) $drop

	    # Show the dragimage in its new position
	    set x [expr {[$T canvasx $x] - $Priv(drag,x)}]
	    set y [expr {[$T canvasy $y] - $Priv(drag,y)}]
	    $T dragimage offset $x $y
	    $T dragimage configure -visible yes
	}
	default {
	    Motion1 $T $x $y
	}
    }
    return
}
