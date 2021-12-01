# $Id: dialog.tcl,v 1.8 2010/01/21 16:02:24 rmk65 Exp $
package provide dialog 0.1

class Dialog {
    inherit itk::Toplevel
    
    itk_option define -title title Title "" {
	if {$itk_option(-title) != ""} {
	    wm title $itk_component(hull) $itk_option(-title)
	}
    }
    
    itk_option define -updatecommand updateCommand Command ""
    
    constructor { args } {
	wm iconbitmap $itk_component(hull) [wm iconbitmap .]
	wm iconmask $itk_component(hull) [wm iconmask .]
	wm withdraw $itk_component(hull)
	wm group $itk_component(hull) .
	wm protocol $itk_component(hull) \
	    WM_DELETE_WINDOW [code $this dismiss 0]
	wm resizable $itk_component(hull) 0 0
	after idle [code $this centreOnScreen]
	eval itk_initialize $args
    }
    
    private common responses
    
    public method confirm {}
    public method dismiss {{choice 0}}
    
    protected method centreOnScreen {}
    protected method topLeftOfWindow {}
}

body Dialog::confirm {} {
    centreOnScreen
    wm deiconify $itk_component(hull)
    raise $itk_component(hull)
    grabber set $itk_component(hull)
    #bind $itk_component(hull) <ButtonRelease-1> [list raise $itk_component(hull)]
    tkwait variable [scope responses($this)]
    #bind $itk_component(hull) <ButtonRelease-1> { }
    grabber release $itk_component(hull)
    wm withdraw $itk_component(hull)
    return $responses($this)
}

body Dialog::dismiss {{choice 0}} {
    set responses($this) $choice
}

body Dialog::centreOnScreen {} {
    update idletasks
    set wd [winfo reqwidth $itk_component(hull)]
    set ht [winfo reqheight $itk_component(hull)]
    set x [expr ([winfo screenwidth $itk_component(hull)]-$wd)/2]
    set y [expr ([winfo screenheight  $itk_component(hull)]-$ht)/2]
    #wm minsize $itk_component(hull) $wd $ht
    wm geometry $itk_component(hull) ${wd}x$ht+$x+$y
}

# following not used yet, have to think about it.
body Dialog::topLeftOfWindow {} {
    update idletasks
    set wd [winfo reqwidth $itk_component(hull)]
    set ht [winfo reqheight $itk_component(hull)]
    #wm minsize $itk_component(hull) $wd $ht
    set x [ expr [winfo rootx .] + 120 ]
    set y [ expr [winfo rooty .] + 84 ]
    wm geometry $itk_component(hull) ${wd}x$ht+$x+$y
}
