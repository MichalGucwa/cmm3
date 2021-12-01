# $Id: mosaicity.tcl,v 1.10 2012/03/26 16:36:39 ccb Exp $
package provide mosaicity 1.0

class MosaicityEstimation {
    inherit Amodaldialog

    # Member variables

    private variable image_used ""
    private variable max_mosaicity_tested "0"
    private variable mosaicity_values {}
    private variable mosaicity_intensities {}

    # methods

    public method launch
    public method updateImageCombo
    public method estimateMosaicity
    public method processMosaicityFeedback
    public method processMosaicityEstimation

    public method disable
    public method enable

    constructor { args } { }
}

body MosaicityEstimation::constructor { args } {

    # Main frame
    itk_component add main_f {
	frame $itk_interior.mf \
	    -bd 2 \
	    -relief raised
    }

    # Header frame
    itk_component add heading_f {
	frame $itk_interior.mf.hf \
	    -bd 1 \
	    -relief solid
    }

    # Header label

    itk_component add heading_l {
	label $itk_interior.mf.hf.fl \
	    -text "Mosaicity estimation" \
	    -font title_font
    } {
	usual
	ignore -font
    }

    # Activity indicator
    itk_component add activity_l {
	Activity $itk_interior.mf.hf.al
    }
    $itk_component(activity_l) idle


    # image frame
    itk_component add image_f {
	frame $itk_interior.mf.if
    }

    itk_component add image_l {
	label $itk_interior.mf.if.il \
	    -text "Image: "
    }

    itk_component add image_combo {
	combobox::combobox $itk_interior.mf.if.ic \
	    -width 20 \
	    -editable 0 \
	    -highlightcolor black \
    } {
	keep -background -cursor -foreground -font
	keep -selectbackground -selectborderwidth -selectforeground
	keep -highlightcolor -highlightthickness
	rename -highlightbackground -background background Background
	rename -background -textbackground textBackground Background
    }

    itk_component add mosaicity_graph {
	canvas $itk_interior.mf.mg \
	    -relief sunken \
	    -borderwidth 2 \
	    -highlightthickness 0
    } {
	rename -background -textbackground textBackground Background
    }

    itk_component add mosaicity_l {
	label $itk_interior.mf.ml \
	    -text "Mosaicity: "
    }

    itk_component add mosaicity_e {
	SettingEntry $itk_interior.mf.me mosaicity \
	    -image ::img::mosaicity \
	    -type real \
	    -precision 2 \
	    -width 7 \
	    -minimum 0 \
	    -maximum 10 \
	    -justify right \
	    -textbackground white
    }
    
    itk_component add estimate_b {
	button $itk_interior.mf.meb \
	    -text "Estimate" \
	    -width 7 \
	    -pady 2 \
	    -command [code $this estimateMosaicity]
    }

    ## Close button

    itk_component add close_b {
        button $itk_interior.button \
	    -highlightthickness 0 \
	    -takefocus 0 \
	    -text "Close" \
	    -command [code $this hide]
    }

    # Arrange widgets

    set margin 7
    
    pack $itk_component(main_f) -fill both -expand 1
    pack $itk_component(close_b) -side bottom -pady 4
    
    grid x $itk_component(heading_f) - - x -sticky we -pady 7
    pack $itk_component(heading_l) -side left -padx 5 -pady 5
    pack $itk_component(activity_l) -side right -padx 5 -pady 5
    
    grid x $itk_component(image_f) - - x -sticky w
    pack $itk_component(image_l) -side left
    pack $itk_component(image_combo) -side right -fill x -expand 1

    grid x $itk_component(mosaicity_graph) - - x -sticky news -pady 7
    grid x $itk_component(mosaicity_l) $itk_component(mosaicity_e) $itk_component(estimate_b) x -pady [list 0 7] -sticky w

    grid columnconfigure $itk_component(main_f) { 0 4 } -minsize 7
    grid columnconfigure $itk_component(main_f) { 3 } -weight 1
    grid rowconfigure $itk_component(main_f) { 2 } -weight 1
    
    eval itk_initialize $args
}

body MosaicityEstimation::launch { { an_image "" } } {
    # update the image combo
    updateImageCombo
    # Pick suggested image if provided
    if {$an_image != ""} {
	$itk_component(image_combo) configure -state normal -editable 1
	$itk_component(image_combo) delete 0 end
	$itk_component(image_combo) insert 0 [$an_image getShortName]
	$itk_component(image_combo) configure -editable 0
    }
    # show the dialog
    show
    # estimate mosaicity
    estimateMosaicity
}

body MosaicityEstimation::updateImageCombo { } {
    # Build list of image that have valid matrices
    set l_image_names {}
    foreach i_sector [$::session getSectors] {
	if {[[$i_sector getMatrix] isValid]} {
	    foreach i_image [$i_sector getImages] {
		lappend l_image_names [$i_image getShortName]
	    }
	}
    }
    $itk_component(image_combo) list delete 0 end
    eval $itk_component(image_combo) list insert 0 $l_image_names
}

body MosaicityEstimation::estimateMosaicity { args } {
    # Wipe existing data
    set mosaicity_values {}
    set mosaicity_intensities {}
    set l_image_name [$itk_component(image_combo) get]
    set image_used [$::session getImageByName $l_image_name]
    # Update the status indicators
    $itk_component(activity_l) busy "Estimating mosaicity"
    # Clear any previous plot
    $itk_component(mosaicity_graph) delete all
    # Disable controls
    disable
    # Tell mosflm to estimate mosaicity
    eval $::mosflm estimateMosaicity $image_used
}

body MosaicityEstimation::processMosaicityFeedback { a_dom } {

    # Check on status of task
    set status_code [$a_dom selectNodes string(//status/code)]

    if {$status_code == "error"} {

	error "[$a_dom selectNodes string(//status/message)]"

    } else {

	# Get the mosaicity and intensity from the xml
	set l_mosaicity [$a_dom selectNodes normalize-space(//mosaicity_trial_value)]
	set l_intensity [$a_dom selectNodes normalize-space(//total_intensity)]

	# Calculate desired x-axis size
	set max_mosaicity_tested [lindex $mosaicity_values end]

	# Check if we are restarting at zero again
	if { $l_mosaicity < $max_mosaicity_tested } {
	    $itk_component(mosaicity_graph) delete all
	    set mosaicity_values {}
	    set mosaicity_intensities {}
	}
	# Add the new data to the array
	lappend mosaicity_values $l_mosaicity
	lappend mosaicity_intensities $l_intensity

	# Calculate graph window
	set x0 10
	set x1 [expr [winfo width $itk_component(mosaicity_graph)] - 10]
	set y0 10
	set y1 [expr [winfo height $itk_component(mosaicity_graph)] - 10]
	set window [list $x0 $y0 $x1 $y1]

	# Calculate the max x value for the graph
	if {$max_mosaicity_tested <= 1} {
	    set l_x_max 1
	} elseif {$max_mosaicity_tested <= 2} {
	    set l_x_max 2
	} elseif {$max_mosaicity_tested <= 4} {
	    set l_x_max 4
	} elseif {$max_mosaicity_tested <= 8} {
	    set l_x_max 8
	    set t_x_step 0.4
	} else {
	    return
	    #error "Unexpected mosaicity value used during estimation ($max_mosaicity_tested)"
	}

	# Build datasets
	set l_x_dataset [namespace current]::[Dataset \#auto $mosaicity_values [Unit::getUnit ""] "Mosaic spread" "Mosaicity"]
	set l_y_dataset [namespace current]::[Dataset \#auto $mosaicity_intensities [Unit::getUnit ""] "Total measured intensity" "Intensity"]

	# Create graph
	#puts "MosaicityEstimation calling ScatterGraph for values $mosaicity_values"
	ScatterGraph \#auto $itk_component(mosaicity_graph) $window mosid $l_x_dataset $l_y_dataset -x_axis_limit $l_x_max
    }
}

body MosaicityEstimation::processMosaicityEstimation { a_dom } {
    
    # Check on status of task
    set status_code [$a_dom selectNodes string(//status/code)]
    if {$status_code == "error"} {
	# Report error if it occured
	.m confirm \
	    -type "1button" \
	    -button1of1 "Dismiss" \
	    -title "Error from Mosaicity Estimation" \
	    -text "The mosaicity estimation has not worked for some reason.\nMessage from Mosflm is - [$a_dom selectNodes string(//status/message)].\nYou should enter an estimated value to replace 0.05."
	wm withdraw .me
	# Update the session with the smallest value tested
	$::session updateSetting mosaicity "0.05" 1 1 "User" 0
    } else {
	# Get the mosaicity
	set l_mosaicity [$a_dom selectNodes normalize-space(//mosaicity_value)]
	# Update the session (but don't predict)
	$::session updateSetting mosaicity $l_mosaicity 1 1 "User" 0
	# check if the image used is currently displayed
	if {$image_used == [.image getImage]} {
	    # if so, predict
	    .image getPredictions
	} else {
	    # if not, open image
	    .image openImage $image_used
	}
	# Enable dialog
	enable
    }    
    # Update status
    $itk_component(activity_l) idle
}

body MosaicityEstimation::disable { } {
    $itk_component(image_combo) configure -state disabled
    $itk_component(mosaicity_e) configure -state disabled
    $itk_component(estimate_b) configure -state disabled
}

body MosaicityEstimation::enable { } {
    $itk_component(image_combo) configure -state normal
    $itk_component(mosaicity_e) configure -state normal
    $itk_component(estimate_b) configure -state normal
}

# #############################################################


#class SessionMosaicityEstimation { }


