# $Id: advancedsessionsettings.tcl,v 1.9 2010/12/08 12:31:33 ccb Exp $
# package name
package provide advancedsessionsettings 1.0

# Class
class Advancedsessionsettings {
    inherit Amodaldialog
    
    # variables
    ###########
    
    # none #

    # methods
    #########

    public method tabbing
    public method show
    public method hide
    public method promptBeamSpecification
    constructor { args } { }
}

# Bodies

body Advancedsessionsettings::constructor { args } {

    #wm iconbitmap $itk_component(hull) [wm iconbitmap .]
    #wm iconmask $itk_component(hull) [wm iconmask .]

    # Main frame ###########################################################

    itk_component add frame {
        frame $itk_interior.f  -relief raised -borderwidth 2
    } {
        usual
    }
    pack $itk_component(frame) -fill both -expand 1

    # Close button #########################################################

    itk_component add button {
        button $itk_interior.f.button  -highlightthickness 0  -takefocus 0  -text "Close"  -command [code $this hide]
    }
    pack $itk_component(button) -side bottom -pady {0 5}

#     # tab notebook #########################################################

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
#     # Hack to fix bug since tcl 8.4 in iwidgets::tabnotebook
     [$itk_component(tabs) component tabset] component hull configure -padx 0 -pady 0
     pack $itk_component(tabs) -side top -fill both -expand 1 -padx 7 -pady 7

     $itk_component(tabs) add -label "Experiment"
     set experiment_tab [$itk_component(tabs) childsite 0]

     $itk_component(tabs) add -label "Detector"
     set detector_tab [$itk_component(tabs) childsite 1]


# 03.07.2007 - HRP not implemented in XML yet - needs changes to Mosflm as 
# well! 
    if  {$::env(EXPERTDETECTORSETTINGS) == 1} {
#	$itk_component(tabs) add -label "Extra"
#	set adjustable_detector_tab [$itk_component(tabs) childsite 2]

	$itk_component(tabs) add -label "Developers"
	set hidden_detector_tab [$itk_component(tabs) childsite 2]
    }
#     $itk_component(tabs) add -label "Results"
#     set results_tab [$itk_component(tabs) childsite 2]

    # select first tab
    $itk_component(tabs) select 0

     bind $itk_component(tabs).canvas.tabset <FocusIn> [code $this tabbing highlight]
     bind $itk_component(tabs).canvas.tabset <FocusOut> [code $this tabbing unhighlight]
     bind $itk_component(tabs).canvas.tabset <Tab> [code focus [tk_focusNext [$itk_component(tabs) component tabset]]]
     bind $itk_component(tabs).canvas.tabset <Right> [code $this tabbing right]
     bind $itk_component(tabs).canvas.tabset <Left> [code $this tabbing left]
     bind $itk_component(tabs).canvas.tabset <Enter> {}
     bind $itk_component(tabs).canvas.tabset.canvas <ButtonPress-1> [code $this tabbing highlight]

    # Detector options #########################################################

    itk_component add detector {
        BespokeDetectorSettings $detector_tab.detector
    }

    pack $itk_component(detector) -fill both -expand 1

    # Session options #########################################################

    itk_component add session {
        Sessionsettings $experiment_tab.session
    }
    pack $itk_component(session) -fill both -expand 1

	


    if  {$::env(EXPERTDETECTORSETTINGS) == 1} {
	# Adjustable Detector options #########################################
# 03.07.2007 - HRP not implemented in XML yet - needs changes to Mosflm as 
# well! See above...
#
#	itk_component add adjustable_detector_tab {
#	    AdjustableDetectorSettings $adjustable_detector_tab.detector
#	}
#	pack $itk_component(adjustable_detector_tab) -fill both -expand 1
	# Hidden Detector options #############################################

	itk_component add hidden_detector_tab {
	    HiddenDetectorSettings $hidden_detector_tab.detector
	}
	pack $itk_component(hidden_detector_tab) -fill both -expand 1
	
    }

    # Experiment settings #####################################################
    # hrp 20.03.2007
    # goes into same tab as Session for the moment 
    itk_component add experiment {
        Experimentparameters $experiment_tab.experiment
    }
    pack $itk_component(experiment) -fill both -expand 1

    # Results #################################################################

#      itk_component add results {
#        Results $results_tab.results
#      }
#      pack $itk_component(results) -fill both -expand 1

    # End of construction ##################################################

    # raise notebook part of tabnotebook to fix 'tabbing' order
    #raise $itk_component(tabs).canvas.notebook

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

#    set heightexperiment [winfo reqheight $itk_component(experiment)]
#    set heightsession [winfo reqheight $itk_component(session)]
    set height [expr [winfo reqheight $itk_component(experiment)] + [winfo reqheight $itk_component(session)]]
     set width [winfo reqwidth $itk_component(experiment)]
     #set width [winfo reqwidth $itk_component(results)]

     set height [expr $height + [winfo reqheight [$itk_component(tabs) component tabset]] + (2 * $margin)]
     set width [expr $width + (2 * $margin)]
     $itk_component(tabs) configure -width $width -height $height

}

# Tabbing method ##########################################################

 body Advancedsessionsettings::tabbing { event } {
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

body Advancedsessionsettings::show { } {
    set ::show_dialogs(index) 1
    Amodaldialog::show
    raise $itk_component(hull)
}

body Advancedsessionsettings::hide { } {
    set ::show_dialogs(index) 0
    Amodaldialog::hide
}
# Special methods ################################################

body Advancedsessionsettings::promptBeamSpecification { } {
    show
    [$itk_component(tabs) component tabset] select "Experiment"
    focus [$itk_component(experiment) component beam_x_entry]
}
