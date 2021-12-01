# $Id: combo.tcl,v 1.8 2010/01/21 16:02:24 rmk65 Exp $
package provide combo 0.2

namespace eval img {}
set ::img::combobutton "R0lGODlhDAAKAIAAAAAAAAAAACH5BAEKAAEALAAAAAAMAAoAAAIPjI+pywYP\ngYpywRYq3nwVADs="


class Combo {
    inherit itk::Widget
    
    private variable selection 0
    private variable expanded 0
    private variable listheight 0
    
    itk_option define -textbackground textBackground Background "\#ffffff" {
	if {$itk_option(-state) == "normal"} {
	    $itk_component(entry) configure \
		-background $itk_option(-textbackground) \
		-disabledbackground $itk_option(-textbackground)
	}
    }
    
    itk_option define -disabledbackground disabledBackground Background "\#dcdcdc" {
	if {$itk_option(-state) == "disabled"} {
	    $itk_component(entry) configure -disabledbackground $itk_option(-disabledbackground)
	}
    }

    itk_option define -command command Command ""
    
    itk_option define -state state State "normal" {
	if {$itk_option(-state) == "disabled"} {
	    $itk_component(entry) configure \
		-state disabled \
		-takefocus 0 \
		-disabledbackground  $itk_option(-disabledbackground) \
		-disabledforeground "\#a9a9a9"
	    bind $itk_component(button) <ButtonPress-1> {}
	    bind $itk_component(entry) <Down> {}
	    bind $itk_component(entry) <Return> {}
	    bind $itk_component(entry) <Escape> {}
	    bind $itk_component(entry) <FocusIn> {}
	    bind $itk_component(entry) <FocusOut> {}
	    set tags [bindtags $itk_component(entry)]
	    set i [lsearch -exact $tags togglepoint$itk_component(entry)]
	    if {$i>=0} {
		bindtags $itk_component(entry) [lreplace $tags $i $i]
	    }
	} elseif {$itk_option(-state) == "normal"} {
	    bind $itk_component(button) <ButtonPress-1> [code $this toggle]
	    bind $itk_component(entry) <Down> [code $this expand]
	    bind $itk_component(entry) <Return> [code $this execute] ; # collapse?
	    bind $itk_component(entry) <Escape> [code $this collapse]
	    bind $itk_component(entry) <FocusOut> [list $itk_component(entry) selection clear]
	    $itk_component(entry) configure \
		-foreground #000000
	    if {$itk_option(-editable)} {
		$itk_component(entry) configure \
		    -background $itk_option(-textbackground) \
		    -state normal \
		    -takefocus 1 \
		    -cursor xterm
	    } else {
		$itk_component(entry) configure \
		    -state disabled \
		    -disabledbackground $itk_option(-textbackground) \
		    -disabledforeground "\#000000" \
		    -takefocus 1 \
		    -cursor ""
		bindtags $itk_component(entry) \
		    [lsort -unique \
			 [concat togglepoint$itk_component(entry) \
			      [bindtags $itk_component(entry)]]]
	    }
	} else {
	    puts "Error: Combo's state must be normal or disabled"
	}
    }

    itk_option define -items items Items [list ] {
	set listheight 0
	set selection 0
	foreach item [winfo children $itk_component(menu)] {
	    destroy $item
	}
	if {[llength $itk_option(-items)] == 0} {
	    if {$itk_option(-editable) != 1} {
		set $itk_option(-state) disabled
	    }
	    
	} else {
	    for {set i 0} {$i < [llength $itk_option(-items)]} {incr i} {
		itk_component add item$i {
		    label $itk_interior.menu.item$i \
			-text [lindex $itk_option(-items) $i] \
			-anchor w \
			-takefocus 1 \
			-borderwidth 0 \
			-font font_l
		} {
		    keep -foreground
		    rename -background -textbackground textBackground Background
		    rename -font -entryfont entryFont Font
		}
		bind $itk_component(item$i) <Enter> [code $this highlight $i]
		bind $itk_component(item$i) <Leave> [code $this unhighlight $i]
		bind $itk_component(item$i) <ButtonRelease-1> [code $this choose $i]
		bind $itk_component(item$i) <ButtonPress-1> [code $this choose $i]
		bind $itk_component(item$i) <Return> [code $this choose $i]
		bind $itk_component(item$i) <Down> [code $this scroll Down]
		bind $itk_component(item$i) <Up> [code $this scroll Up]
		bind $itk_component(item$i) <Escape> [code $this collapse]
		bind $itk_component(item$i) <FocusIn> [code $this highlight $i]
		pack $itk_component(item$i) -anchor w -fill x
		set listheight [expr $listheight + [winfo reqheight $itk_component(item$i)]]
	    }
	    set listheight [expr $listheight + [expr 2 * [$itk_component(menu) cget -borderwidth]]]
	}
    }
    
    itk_option define -editable editable Editable 1 {
	if $itk_option(-editable) {
	    $itk_component(entry) configure -state normal -cursor xterm
	    set tags [bindtags $itk_component(entry)]
	    set i [lsearch -exact $tags togglepoint$itk_component(entry)]
	    if {$i>=0} {
		bindtags $itk_component(entry) [lreplace $tags $i $i]
	    }
	    $itk_component(frame) configure \
         	-highlightcolor [$itk_component(frame) cget -highlightbackground]
	} else {
	    $itk_component(entry) configure \
		-disabledbackground $itk_option(-textbackground) \
		-state disabled \
		-cursor ""
	    if {$itk_option(-state) == "normal"} {
		$itk_component(entry) configure -disabledforeground "\#000000"
	    } else {
		$itk_component(entry) configure -disabledforeground "\#a3a3a3"
	    }
	    bindtags $itk_component(entry) \
		[lsort -unique \
		     [concat togglepoint$itk_component(entry) \
			  [bindtags $itk_component(entry)]]]
	    $itk_component(frame) configure -highlightcolor $itk_option(-highlightcolor)
	}
    }
    
    itk_option define -highlightcolor highlightColor HighlightColor black {
   	if $itk_option(-editable) {
	    $itk_component(frame) configure \
         	-highlightcolor [$itk_component(frame) cget -highlightbackground]
	} else {
	    $itk_component(frame) configure -highlightcolor $itk_option(-highlightcolor)
	}
    }

    public method expand
    public method collapse { args }
    public method choose { number }
    public method highlight { number }
    public method unhighlight { number }
    public method scroll { direction }
    public method toggle
    public method hidemenus
    public method execute
    
    
    constructor { args } {
	
	image create photo combobutton -data $::img::combobutton
	
	itk_component add frame {
	    frame $itk_interior.f \
         	-relief sunken \
		-highlightthickness 1 \
		-borderwidth 2 \
		-background red
	} {
	    rename -highlightbackground -background background Background
	    rename -background -textbackground textBackground Background
	}
	pack $itk_component(frame) -fill both -expand true
	
	itk_component add entry {
         entry $itk_interior.f.entry \
	     -relief flat \
	     -borderwidth 0 \
	     -highlightthickness 0 \
	     -selectbackground #3399ff \
	     -takefocus 1
      } {
	  keep -width
	  keep -textvariable
	  keep -selectbackground
	  keep -selectborderwidth
	  keep -foreground
	  keep -selectforeground
	  #rename -background -textbackground textBackground Background
	  rename -font -entryfont entryFont Font
      }
	
	bind $itk_component(entry) <Down> [code $this expand]
	bind $itk_component(entry) <Return> [code $this execute] ; # collapse?
	bind $itk_component(entry) <Escape> [code $this collapse]
	bind $itk_component(entry) <FocusOut> [list $itk_component(entry) selection clear]
	
	pack $itk_component(entry) -side left -fill both -expand true

	itk_component add button {
	    label $itk_interior.f.button \
         	-relief raised \
		-borderwidth 2 \
		-image combobutton
	} {
	    keep -background
	}
	pack $itk_component(button) -fill y -side left
	
	bind $itk_component(button) <ButtonPress-1> [code $this toggle]
	
	itk_component add menu {
	    toplevel $itk_interior.menu \
         	-relief sunken \
		-highlightthickness 1
	} {
	    keep -borderwidth
	    rename -highlightbackground -background background Background
	    rename -highlightcolor -background background Background
	    rename -background -textbackground textBackground Background
	}
	wm overrideredirect $itk_component(menu) 1
	wm transient $itk_component(menu) [winfo toplevel $itk_component(hull)]
	wm group [winfo toplevel $itk_component(hull)] $itk_component(menu)
	wm resizable $itk_component(menu) 0 0
	wm withdraw $itk_component(menu)
	
	bindtags [winfo toplevel $itk_component(hull)] \
	    [concat hidepoint$itk_component(hull) \
		 [bindtags [winfo toplevel $itk_component(hull)]] ]
	bind hidepoint$itk_component(hull) <Expose> [code $this hidemenus]
	bind togglepoint$itk_component(entry) <ButtonPress-1> [code $this toggle]
	
	eval itk_initialize $args
	
	#$itk_component(hull) configure -relief flat -borderwidth 0
    }
    
}

usual Combo {
    keep -background
    keep -foreground
    keep -textbackground
    keep -selectbackground
    keep -selectforeground
    keep -selectborderwidth
    keep -entryfont
}

body Combo::execute { } {
    if {$itk_option(-command) != ""} {
	uplevel #0 $itk_option(-command) [list [$itk_component(entry) get]]
# 	set value ""
    }
}

body Combo::toggle { } {
    if {$expanded} {
	collapse
    } else {
   	expand
    }
}

body Combo::scroll { direction } {
    set max [expr [llength $itk_option(-items)] - 1]
    switch -- $direction {
   	Up {
	    if {[expr $selection > 0]} {
         	highlight [expr $selection - 1]
	    } else {
         	highlight $max
	    }
	}
	Down {
	    if {[expr $selection >= $max]} {
         	highlight 0
	    } else {
         	highlight [expr $selection + 1]
	    }
	}
    }
}

body Combo::choose { number } {
    set state [$itk_component(entry) cget -state]
    $itk_component(entry) configure -state normal
    $itk_component(entry) delete 0 end
    $itk_component(entry) insert end [lindex $itk_option(-items) $number]
    $itk_component(entry) configure -state $state
    collapse
    execute
}

body Combo::highlight { number } {
    set counter 0
    foreach item $itk_option(-items) {
	unhighlight $counter
	incr counter
    }
    set selection $number
    focus $itk_component(item$number)
    $itk_component(item$number) configure \
   	-background $itk_option(-selectbackground) \
   	-foreground $itk_option(-selectforeground) \
	;#-font font_b
}

body Combo::unhighlight { number } {
    $itk_component(item$number) configure \
   	-background $itk_option(-textbackground) \
   	-foreground $itk_option(-foreground) \
	;#-font font_l
}

body Combo::expand { } {
    if {[llength $itk_option(-items)] > 0} { 
	set expanded 1
	
	set x [expr [winfo rootx $itk_component(frame)]]
	set y [expr [winfo rooty $itk_component(frame)] \
		   + [winfo height $itk_component(frame)]]
	set width [winfo width $itk_component(frame)]
	regexp -- {^.+x(.+)\+.+\+.+$} [wm geometry $itk_component(menu)] \
	    geo height
	set newgeo "${width}x${listheight}+${x}+${y}"
	wm geometry $itk_component(menu) $newgeo
	
	wm deiconify $itk_component(menu)
	catch {grabber set $itk_component(menu)}
	catch {grabber release $itk_component(menu)}
	# raise $itk_component(menu) $itk_component(hull)
	raise $itk_component(menu)
	foreach window [concat [namespace tail $this] \
			    [winfo toplevel [namespace tail $this]] \
			    [winfo children [winfo toplevel [namespace tail $this]]]] {
	    bindtags $window \
		[concat collapsepoint [bindtags $window]]
	}
	bind collapsepoint <ButtonPress-1> [code $this collapse]
	if {[lsearch [array names itk_component] item$selection] >= 0} {	
	    highlight $selection
	}
    }
}

body Combo::collapse { } {
    set expanded 0
    bind all <ButtonPress-1>
    wm withdraw $itk_component(menu)
    foreach window [concat [namespace tail $this] \
			[winfo toplevel [namespace tail $this]] \
			[winfo children [winfo toplevel [namespace tail $this]]]] {
	set tags [bindtags $window]
      set i [lsearch -exact $tags collapsepoint]
	if {$i>=0} {
	    bindtags $window [lreplace $tags $i $i]
	}
   }
    focus $itk_component(entry)
}

body Combo::hidemenus { } {
    set focuspoint [focus]
    set expanded 0
    wm withdraw $itk_component(menu)
    foreach window [concat [namespace tail $this] \
			[winfo toplevel [namespace tail $this]] \
			[winfo children [winfo toplevel [namespace tail $this]]]] {
	set tags [bindtags $window]
	set i [lsearch -exact $tags collapsepoint]
	if {$i>=0} {
	    bindtags $window [lreplace $tags $i $i]
	}
    }
    while {$focuspoint != "" && ![winfo viewable $focuspoint]} {
   	set focuspoint [winfo parent $focuspoint]
	focus $focuspoint
    }
    if {$focuspoint != ""} {
	if {[winfo class $focuspoint] == "Combo"} {
	    focus $focuspoint.f.entry
	}
    }
}

proc combo { name args } {
    return [Combo $name $args]
}
