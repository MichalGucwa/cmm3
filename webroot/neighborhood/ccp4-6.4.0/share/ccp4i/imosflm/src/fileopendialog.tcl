# $Id: fileopendialog.tcl,v 1.8 2010/01/21 16:02:24 rmk65 Exp $
package provide fileopendialog 0.1

class Fileopendialog {
    inherit Dialog

    itk_option define -filevariable fileVariable Variable ""
    
    constructor {args} {

	wm iconbitmap $itk_component(hull) [wm iconbitmap .]
	wm iconmask $itk_component(hull) [wm iconmask .]

	itk_component add fileopen {
	    Fileopen $itk_interior.fileopen \
         	-multi 0 \
		-selectallbutton 0 \
		-locationtext "Look in:" \
		-buttontext "Open" \
		-command [code $this open] \
		-cancelcommand [code $this cancel] \
		-filtersort "sort_projectfilters" \
		-filters ::filters::projectfiles
	    }
	pack $itk_component(fileopen)
	
	eval itk_initialize $args
    }
    
    public method open
    public method cancel
}

body Fileopendialog::cancel { } {
    dismiss 0
}

body Fileopendialog::open { } {
    # De-reference the filename variable passes as an option
    upvar $itk_option(-filevariable) filevar
    # Get the filename selected in the Fileopen widget
    set filevar [$itk_component(fileopen) selection]
    # Check if the file really exists...
    if {[file exists $filevar]} {
	# ...if so, dismiss the dialog returning 1 for success
	dismiss 1
    } else {
	# ...otherwise warn the user.
	if {![winfo exists .m]} {
	    Message .m
	}
	.m confirm -type "1button" \
	    -title "File not found" \
	    -text "File \"$filevar\" not found." \
	    -button1of1 "Dismiss"
    }
}
