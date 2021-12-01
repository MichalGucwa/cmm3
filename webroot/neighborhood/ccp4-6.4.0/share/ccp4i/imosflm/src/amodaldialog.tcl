# $Id: amodaldialog.tcl,v 1.8 2010/01/21 16:02:24 rmk65 Exp $
# package name
package provide amodaldialog 1.0

# Class
class Amodaldialog {
    inherit itk::Toplevel

    # variables
    ###########
    
    # none #

    # methods
    #########
    
    public method show
    public method hide

    constructor { args } { } 

}

# Bodies

body Amodaldialog::constructor { args } {
    wm iconbitmap $itk_component(hull) [wm iconbitmap .]
    wm iconmask $itk_component(hull) [wm iconmask .]
    wm withdraw $itk_component(hull)
    wm group $itk_component(hull) .
    wm protocol $itk_component(hull)  WM_DELETE_WINDOW [code $this hide]
    #wm resizable $itk_component(hull) 0 0
    eval itk_initialize $args
}

body Amodaldialog::show { {current_window .} } {
    wm deiconify $itk_interior
    raise $itk_interior
}

body Amodaldialog::hide { } {
    wm withdraw $itk_interior
}
