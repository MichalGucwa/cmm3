# $Id: imagefileopendialog.tcl,v 1.8 2010/01/21 16:02:24 rmk65 Exp $
package provide imagefileopen 0.2

class Imagefileopendialog {
    inherit Dialog

    public variable directory ""
    public variable template ""
    
    itk_option define -imagesvariable imagesVariable Variable ""
    
    constructor {args} {
	
	wm iconbitmap $itk_component(hull) [wm iconbitmap .]
	wm iconmask $itk_component(hull) [wm iconmask .]
	
	# tab notebook #########################################################
	
	itk_component add tabs {
	    iwidgets::tabnotebook $itk_interior.tabs \
		-tabpos n \
		-background \#dcdcdc \
		-tabbackground \#bbbbbb \
		-foreground black \
		-tabforeground black \
		-backdrop grey40 \
		-angle 15 \
		-bevelamount 2 \
		-margin 2 \
		-start 4 \
		-gap overlap \
		-padx 5 \
		-font font_l \
		-borderwidth 0 \
		-width 424 \
		-height 320 \
		
	} {
	    keep -background
	}
	# Hack to fix bug since tcl 8.4 in iwidgets::tabnotebook
	[$itk_component(tabs) component tabset] component hull configure -padx 0 -pady 0

	# red -> #a9a9a9
	# green -> #dcdcdc
	# blue -> lightgrey

	grid $itk_component(tabs) -row 0 -column 0 -sticky nsew
	
	$itk_component(tabs) add -label "Select by file"
	set file_tab [$itk_component(tabs) childsite 0]
	$itk_component(tabs) add -label "Select by template"
	set template_tab [$itk_component(tabs) childsite 1]
	
	$itk_component(tabs) select 0
	
	bind $itk_component(tabs).canvas.tabset <FocusIn> [code $this tabbing highlight]
	bind $itk_component(tabs).canvas.tabset <FocusOut> [code $this tabbing unhighlight]
	bind $itk_component(tabs).canvas.tabset <Tab> [code focus [tk_focusNext [$itk_component(tabs) component tabset]]]
	bind $itk_component(tabs).canvas.tabset <Right> [code $this tabbing right]
	bind $itk_component(tabs).canvas.tabset <Left> [code $this tabbing left]
	bind $itk_component(tabs).canvas.tabset <Enter> {}
	bind $itk_component(tabs).canvas.tabset.canvas <ButtonPress-1> [code $this tabbing highlight]


	# file tab #############################################################

	itk_component add fileopen {
	    Fileopen $file_tab.fileopen \
         	-multi 1 \
		-selectallbutton 1 \
		-locationtext "Look in:" \
		-buttontext "Add" \
		-command [code $this addImages] \
		-cancelcommand [code $this cancel] \
		-filtersort "sort_templatefilters" \
		-filters ::filters::imagefiles
	}
	pack $itk_component(fileopen)
	
	# template tab #########################################################
	
	itk_component add directory_l {
	    label $template_tab.dl \
		-text "Directory:" \
		-anchor w
	}

	itk_component add directory_e {
	    Fileentry $template_tab.de \
         	-onlinecommand [code $this preview] \
		-textvariable [scope directory]
	}
	
	itk_component add template_l {
	    label $template_tab.tl \
		-text "Template:" \
		-anchor w
	}

	itk_component add template_e {
	    Templateentry $template_tab.te \
         	-onlinecommand [code $this preview] \
		-textvariable [scope template]
	}
	
	itk_component add preview_l {
	    label $template_tab.pl \
		-text "Preview:" \
		-anchor nw
	}

	itk_component add preview_tl {
	    tablelist::tablelist $template_tab.ptl \
		-background white \
		-highlightthickness 0 \
		-width 0 \
		-height 6 \
		-selectborderwidth 0 \
		-exportselection 0 \
		-showlabels 0 \
		-columns {
		    999 "Images"}
	} {
	    keep -labelfont
	    rename -font -entryfont entryFont Font
	    keep -selectforeground -selectbackground
	}
	
	itk_component add scrollbar {
	    scrollbar $template_tab.sb \
		-orient vertical \
		-command [code $itk_component(preview_tl) yview] \
		-troughcolor #a9a9a9 \
		-highlightthickness 0 \
		-takefocus 0
	} {
	    keep -borderwidth
	    keep -background
	    rename -activebackground -background background Background
	}

	$itk_component(preview_tl) configure -yscrollcommand [list autoscroll $itk_component(scrollbar)]

	itk_component add buttons {
	    frame $template_tab.buttons
	}
		
	itk_component add okay {
	    button $template_tab.buttons.okay \
         	-text Ok -width 7 -pady 2 \
		-command [code $this okay] \
		-highlightthickness 1
	} {
	    keep -background
	    keep -borderwidth
	    rename -highlightbackground -background background Background
	    rename -activebackground -background background Background
	}
	
	itk_component add cancel {
	    button $template_tab.buttons.cancel \
         	-text "Cancel" -width 7 -pady 2 \
		-command [code $this cancel] \
		-highlightthickness 1
	} {
	    keep -background
	    keep -borderwidth
	    rename -highlightbackground -background background Background
	    rename -activebackground -background background Background
	}

	itk_component add help {
	    button $template_tab.buttons.help \
         	-text Help -width 7 -pady 2 \
         	-state disabled  \
		-command [code $this help] \
		-highlightthickness 1
	} {
	    keep -background
	    keep -borderwidth
	    rename -highlightbackground -background background Background
	    rename -activebackground -background background Background
	}
		
	pack $itk_component(okay) -side right
	pack $itk_component(cancel) -side right -padx 7
	pack $itk_component(help) -side right
	
	grid $itk_component(directory_l) $itk_component(directory_e) - -sticky we -padx 7 -pady 7
	grid $itk_component(template_l) $itk_component(template_e) - -sticky we -padx 7
	grid $itk_component(preview_l) $itk_component(preview_tl) $itk_component(scrollbar) -sticky nswe -padx 7 -pady 7
	grid $itk_component(buttons) - - -sticky e -padx 7

	grid columnconfigure $template_tab 1 -weight 1
	grid rowconfigure $template_tab 2 -weight 1
	grid rowconfigure $template_tab 4 -minsize 7 

	#############################################################################
	
	eval itk_initialize $args
    }
    
    private method stamp
    public method preview
    public method okay
    public method cancel
    public method help
    
    public method addImages

    public method scrolling

    public method tabbing
}

body Imagefileopendialog::stamp { } {
    
    # initialize list of images to be returned
    set l_images {}

    # substitue #'s to make regular expression
    regsub -- {\#+} $template "\\d+" t_template
    set t_template "^$t_template$"

    # loop through files in specified directory
    foreach i_file [glob -nocomplain [file join $directory *]] {
	# if they match the template append them to the list
	if {[regexp $t_template [file tail $i_file]]} {
	    lappend l_images $i_file
	}
    }

    # sort the list
    set l_images [lsort $l_images]
    
    # return the list
    return $l_images
}

body Imagefileopendialog::preview { args } {
	
    # get list of matching files
    set l_images [stamp]

    # Display them in the tablelist
    $itk_component(preview_tl) delete 0 end
    foreach i_image $l_images {
	$itk_component(preview_tl) insert end [file tail $i_image]
	$itk_component(preview_tl) cellconfigure end,0 -image ::img::plain_image
    }
}

body Imagefileopendialog::okay { } {
    set l_image_files [stamp]
    upvar $itk_option(-imagesvariable) imagelist
    set imagelist [concat $imagelist $l_image_files]
    set imagelist [lsort -unique $imagelist]
    dismiss 1
}


body Imagefileopendialog::help { } {
}

body Imagefileopendialog::addImages { } {
    upvar $itk_option(-imagesvariable) imagelist
    set imagelist [concat $imagelist [$itk_component(fileopen) selection]]
    set imagelist [lsort -unique $imagelist]
    dismiss 1
}

body Imagefileopendialog::cancel { } {
    dismiss 0
    #uplevel #0 $itk_option(-cancelcommand)
}

proc autoscroll { scrollbar first last} {
    if {$first <= 0 && $last >= 1} {
	grid remove $scrollbar
    } else {
	grid $scrollbar
    }
    $scrollbar set $first $last
} 

# ###########################################
# Tabset customization function
# ###########################################

body Imagefileopendialog::tabbing { event } {
    switch -- $event {
	highlight {
	    $itk_component(tabs) configure -font font_l
	    [$itk_component(tabs) component tabset] tabconfigure [$itk_component(tabs) view] -font font_u
         focus $itk_component(tabs).canvas.tabset
	}
	unhighlight {
	    $itk_component(tabs) configure -font font_l
	}
	right {
	    $itk_component(tabs) configure -font font_l
	    [$itk_component(tabs) component tabset] next
	    [$itk_component(tabs) component tabset] tabconfigure [$itk_component(tabs) view] -font font_u
	}
	left {
	    $itk_component(tabs) configure -font font_l
	    [$itk_component(tabs) component tabset] prev
	    [$itk_component(tabs) component tabset] tabconfigure [$itk_component(tabs) view] -font font_u
	}
    }
}
