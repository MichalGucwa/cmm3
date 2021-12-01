# $Id: advancedtoolsettings.tcl,v 1.8 2010/01/21 16:02:24 rmk65 Exp $
# package name
package provide advancedsettings 2.0

# Class
class Advancedtoolsettings {
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

body Advancedtoolsettings::constructor { args } {
    wm iconbitmap $itk_component(hull) [wm iconbitmap .]
    wm iconmask $itk_component(hull) [wm iconmask .]

    # Main frame ###########################################################

    itk_component add frame {
        frame $itk_interior.f  -relief raised -borderwidth 2
    } {
        usual
    }
    pack $itk_component(frame) -fill both -expand 1

    # Close button #########################################################

    itk_component add button {
        button $itk_interior.button  -highlightthickness 0  -takefocus 0  -text "Close"  -command [code $this hide]
    }
    pack $itk_component(button) -fill x


    # tab notebook #########################################################

    itk_component add tabs {
        iwidgets::tabnotebook $itk_interior.f.tabs \
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
    pack $itk_component(tabs) -side top -fill both -expand 1 -padx 7 -pady 7

    # Add tabs ###########################################

    $itk_component(tabs) add -label "Spot finding"
    set spotfind_tab [$itk_component(tabs) childsite 0]
    $itk_component(tabs) add -label "Indexing"
    set index_tab [$itk_component(tabs) childsite 1]
    $itk_component(tabs) add -label "Processing"
    set processing_tab [$itk_component(tabs) childsite 2]

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

    set height [winfo reqheight $itk_component(spotfinding)]
    set width [winfo reqwidth $itk_component(spotfinding)]

    set height [expr $height + [winfo reqheight [$itk_component(tabs) component tabset]] + (2 * $margin)]
    set width [expr $width + (2 * $margin)]
    $itk_component(tabs) configure -width $width -height $height

}

# Refresh method ##########################################################

# body Advancedtoolsettings::refresh { } {
#     $itk_component(spotfinding) refresh
#     $itk_component(indexing) refresh
# }

# Tabbing method ##########################################################

body Advancedtoolsettings::tabbing { event } {
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

body Advancedtoolsettings::show { } {
    set ::show_dialogs(index) 1
    Amodaldialog::show
}

body Advancedtoolsettings::hide { } {
    set ::show_dialogs(index) 0
    Amodaldialog::hide
}

