# $Id: processingdialog.tcl,v 1.10 2012/03/26 16:36:39 ccb Exp $
# package name
package provide processingdialog 1.0

# Class
class ProcessingDialog {
    inherit Amodaldialog
    
    # variables
    ###########
    
    # none #

    # methods
    #########

    #public method refresh
    public method tabbing
    public method show
    public method hide

    constructor { args } { }
}

# Bodies

body ProcessingDialog::constructor { args } {
    wm iconbitmap $itk_component(hull) [wm iconbitmap .]
    wm iconmask $itk_component(hull) [wm iconmask .]

    # Main frame ###########################################################

    itk_component add frame {
        frame $itk_interior.f  -relief raised -borderwidth 2
    } {
        usual
    }
    pack $itk_component(frame) -fill both -expand 1

    itk_component add vert_sbar {
	scrollbar $itk_component(frame).vertsbar
    }
    pack $itk_component(vert_sbar) -side right -fill y

    itk_component add scroll_canvas {
	canvas $itk_component(frame).vport	
    }
    pack $itk_component(scroll_canvas) -side left -fill both -expand true

    # Close button #########################################################

    itk_component add button {
        button $itk_interior.button  -highlightthickness 0  -takefocus 0  -text "Close"  -command [code $this hide]
    }
    pack $itk_component(button) -pady {1 1} -fill y

    # tab notebook #########################################################

    itk_component add tabs {
        iwidgets::tabnotebook $itk_component(scroll_canvas).tabs \
		-tabpos n  \
	    -background "#dcdcdc" \
	    -tabbackground "#a9a9a9" \
	    -foreground "black" \
	    -tabforeground "black" \
	    -backdrop "#dcdcdc" \
	    -angle "0" \
	    -bevelamount "3" \
	    -margin "2" \
	    -start "4" \
	    -gap "4" \
	    -padx "0" \
	    -font font_l \
	    -borderwidth 2 \
	    -padx 2
    } {
        keep -background
        keep -width
    }
    # Hack to fix bug since tcl 8.4 in iwidgets::tabnotebook
    [$itk_component(tabs) component tabset] component hull configure -padx 0 -pady 0
#    pack $itk_component(tabs) -side top -fill both -expand 1 -padx 7 -pady 7


#	$itk_component(scroll_canvas) create window 0 0 -anchor nw -width 400 -height 400 -window $itk_component(tabs)
    # Add tabs ###########################################

    $itk_component(tabs) add -label "Spot finding"
    set spotfind_tab [$itk_component(tabs) childsite 0]
    $itk_component(tabs) add -label "Indexing"
    set index_tab [$itk_component(tabs) childsite 1]
    $itk_component(tabs) add -label "Processing"
    set processing_tab [$itk_component(tabs) childsite 2]
    $itk_component(tabs) add -label "Advanced\nrefinement"
    set advanced_refinement_tab [$itk_component(tabs) childsite 3]
    $itk_component(tabs) add -label "Advanced\nintegration"
    set advanced_integration_tab [$itk_component(tabs) childsite 4]

    # select first tab
    $itk_component(tabs) select 0

    # Set up tabbing bindings
    bind $itk_component(tabs).canvas.tabset <FocusIn> [code $this tabbing highlight]
    bind $itk_component(tabs).canvas.tabset <FocusOut> [code $this tabbing unhighlight]
    bind $itk_component(tabs).canvas.tabset <Tab> [code focus [tk_focusNext [$itk_component(tabs) component tabset]]]
    bind $itk_component(tabs).canvas.tabset <Right> [code $this tabbing right]
    bind $itk_component(tabs).canvas.tabset <Left> [code $this tabbing left]
    bind $itk_component(tabs).canvas.tabset <Enter> {}
    bind $itk_component(tabs).canvas.tabset.canvas <ButtonPress-1> [code $this tabbing highlight]

    # spotfinding controls #################################################

    itk_component add spotfinding {
        Spotfindingsettings $spotfind_tab.spotfinding
    }
    pack $itk_component(spotfinding) -fill both -expand 1

    # indexing controls ####################################################

    itk_component add indexing {
        Indexsettings $index_tab.indexing
    }
    pack $itk_component(indexing) -fill both -expand 1

    # processing controls ##################################################

    itk_component add processing {
        Processingsettings $processing_tab.processing
    }
    pack $itk_component(processing) -fill both -expand 1

    # processing controls ##################################################

    itk_component add advanced_refinement {
        Advancedrefinementsettings $advanced_refinement_tab.advanced_refinement
    }
    pack $itk_component(advanced_refinement) -fill both -expand 1

    itk_component add advanced_integration {
        Advancedintegrationsettings $advanced_integration_tab.advanced_integration
    }
    pack $itk_component(advanced_integration) -fill both -expand 1

    # add other panels here...

    # raise notebook part of tabnotebook to fix 'tabbing' order
    raise $itk_component(tabs).canvas.notebook

    # Process options (must take place before height calculation, as
    # fonts etc. will have impact
    ####################################################################

    eval itk_initialize $args

    # Resize tabbed notebook to fit contents ###########################
    ####################################################################

    update

    set height 0
    set width 0

    set margin 14
    set list [list spotfinding indexing processing advanced_refinement advanced_integration ]
    foreach item $list {
	set test_height [winfo reqheight $itk_component($item)]
	set test_width [winfo reqwidth $itk_component($item)]
	if { $test_height > $height } {
	    set height $test_height
	}
	if { $test_width > $width } {
	    set width $test_width
	}
    }
#    set height [winfo reqheight $itk_component(spotfinding)]
#    set width [winfo reqwidth $itk_component(spotfinding)]

    set height [expr {$height + [winfo reqheight [$itk_component(tabs) component tabset]] + [expr {4*$margin}]}]
    set width [expr {$width + (2*$margin)}]
#    $itk_component(tabs) configure -width $width -height $height
    $itk_component(scroll_canvas) configure -width $width -height $height
    $itk_component(scroll_canvas) create window 0 0 -anchor nw -width $width -height $height -window $itk_component(tabs)

    $itk_component(vert_sbar) configure -command "$itk_component(scroll_canvas) yview"
    $itk_component(scroll_canvas) configure -yscrollcommand "$itk_component(vert_sbar) set"

    set bbox [$itk_component(scroll_canvas) bbox all]
    $itk_component(scroll_canvas) configure -scrollregion $bbox -yscrollincrement 0.1i

    set button_height [winfo reqheight $itk_component(button)]
    set scrollbar_width [winfo reqwidth $itk_component(vert_sbar)]
    
    if {[tk windowingsystem] == "aqua"} {
	set button_height [expr {$button_height + 8}]
    }

    wm maxsize [winfo toplevel $itk_component(hull)] [expr {$width + $scrollbar_width}] [expr {$height + $button_height}]


}

# Refresh method ##########################################################

# body ProcessingDialog::refresh { } {
#     $itk_component(spotfinding) refresh
#     $itk_component(indexing) refresh
# }

# Tabbing method ##########################################################

body ProcessingDialog::tabbing { event } {
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

# Showing / hiding ##################################################

body ProcessingDialog::show { } {
    set ::show_dialogs(index) 1
    Amodaldialog::show
    raise $itk_component(hull)
}

body ProcessingDialog::hide { } {
    set ::show_dialogs(index) 0
    Amodaldialog::hide
}

