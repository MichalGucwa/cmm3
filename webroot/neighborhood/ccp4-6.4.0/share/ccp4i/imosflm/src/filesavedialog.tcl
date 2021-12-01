# $Id: filesavedialog.tcl,v 1.9 2010/01/21 16:02:24 rmk65 Exp $
package provide filesavedialog 0.1

option add *Filesavedialog.background grey widgetDefault
option add *Filesavedialog.textbackground white widgetDefault
option add *Filesavedialog.font font_b

class Filesavedialog {
    inherit Dialog

    itk_option define -locationtext locationtext Text "Look in:" {
	[$itk_component(fileopen) component dirlabel] configure -text $itk_option(-locationtext)
    }
    itk_option define -filevariable fileVariable Variable ""

    constructor {args} {
	
	wm iconbitmap $itk_component(hull) [wm iconbitmap .]
	wm iconmask $itk_component(hull) [wm iconmask .]
	
	itk_component add fileopen {
	    Fileopen $itk_interior.fileopen \
         	-multi 0 \
		-selectallbutton 0 \
		-buttontext Save \
		-command [code $this save] \
		-cancelcommand [code $this cancel] \
		-filtersort "sort_projectfilters" \
		-filters ::projectfilters
	} {
	    usual
	}
	
	[$itk_component(fileopen) component filterlabel] configure -text "Save as:"
	
	pack $itk_component(fileopen)
	
	eval itk_initialize $args
    }
    
    public method save
    public method cancel
}

body Filesavedialog::cancel { } {
    dismiss 0
}

body Filesavedialog::save { } {
    if {[regexp {Mosflm project file} \
	     [$itk_component(fileopen) cget -current_filter] ]} {
	set extension ".mpr"
    } else {
	set extension ""
    }
    upvar $itk_option(-filevariable) filevar
    set filevar [$itk_component(fileopen) selection]
    if {[string match *$extension $filevar] == 0} {
	set filevar $filevar$extension
    }
    if {![file exists $filevar]} {
	dismiss 1
    } else {
	if {![winfo exists .m]} {
	    Message .m
	}
	.m configure \
	    -type "2button" \
	    -title "Overwrite?" \
	    -text "File \"$filevar\" already exists.\n\nOverwrite?" \
	    -button1of2 "Yes" \
	    -button2of2 "No"
      if {[.m confirm]} {
	  dismiss 1
      }
   }
}
