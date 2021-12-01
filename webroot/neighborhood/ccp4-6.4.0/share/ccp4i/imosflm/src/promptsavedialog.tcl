# $Id: promptsavedialog.tcl,v 1.8 2010/01/21 16:02:25 rmk65 Exp $
package provide promptsavedialog 1.0

class Promptsavedialog {
    inherit Dialog

    public method confirm

    constructor { args } { }
}

body Promptsavedialog::constructor { args } {
    
    wm iconbitmap $itk_component(hull) [wm iconbitmap .]
    wm iconmask $itk_component(hull) [wm iconmask .]
	
    set warning "R0lGODlhIAAgAKEAAAAAAP//AJmZmf///yH+FUNyZWF0ZWQgd2l0aCBUaGUg\nR0lNUAAh+QQBCgADACwAAAAAIAAgAAACjpyPB5vtb0CYAFonJxW3j6wBAuc9\noBaIZJmc4ci26KzGyozWtovrrLvIwX60xcnXARqFqwvPCBw6e0tmEpeqWi28\nbJAmxWC9XaRs/O2FEd1QO7WOjClv82dOx5vf+K28n4YmxUemN0RYaMiBmNUH\nt+gYuTHCKKkCKal4CMXZ6bkwEooQSlpqehqHqopqUAAAOw=="
    image create photo warning -data $warning
    
    itk_component add messageframe {
	frame $itk_interior.mf \
	    -relief raised \
	    -borderwidth 1
    }
    pack $itk_component(messageframe) -side top -fill both -expand 1
    
    itk_component add icon {
	label $itk_interior.mf.icon \
	    -image warning \
	    -anchor center
    } {
	keep -background
    }
    pack $itk_component(icon) -side left -padx 7 -pady 14
    
    itk_component add message {
	label $itk_interior.mf.message \
	    -anchor w \
	    -justify left \
	    -text "Save session?"
    } {
	keep -background
	keep -text
    }
    pack $itk_component(message) -side left -padx 7 -pady 14
    
    itk_component add buttonframe {
	frame $itk_interior.bf \
	    -relief raised \
	    -borderwidth 1
    }
    pack $itk_component(buttonframe) -side top -fill x
    
    itk_component add yes {
	button $itk_interior.bf.yes \
	    -text "Yes" \
	    -command [code $this dismiss "Yes"] \
	    -highlightthickness 1 \
	    -width 7 \
	    -pady 2
    } {
	keep -background
	rename -activebackground -background background Background
	rename -highlightbackground -background background Background
    }
    
    itk_component add no {
	button $itk_interior.bf.no \
	    -text "No" \
	    -command [code $this dismiss "No"] \
	    -highlightthickness 1 \
	    -width 7 \
	    -pady 2 \
	} {
	    keep -background
	    rename -activebackground -background background Background
	    rename -highlightbackground -background background Background
	}
    
    itk_component add cancel {
	button $itk_interior.bf.cancel \
	    -text "Cancel" \
	    -command [code $this dismiss "Cancel"] \
	    -highlightthickness 1 \
	    -width 7 \
	    -pady 2 \
	} {
	    keep -background
	    rename -activebackground -background background Background
	    rename -highlightbackground -background background Background
	}

    grid x $itk_component(yes) x $itk_component(no) x $itk_component(cancel) x -sticky we -pady 7
    grid columnconfigure $itk_component(buttonframe) { 0 2 4 6 } -weight 1 -minsize 7
    
    eval itk_initialize $args
}


body Promptsavedialog::confirm { args } {
    eval configure $args
    Dialog::confirm
}

