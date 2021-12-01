# $Id: integrationwizard.tcl,v 1.14 2012/03/26 16:36:39 ccb Exp $
package provide integrationwizard 1.0

image create photo ::img::graph_arrow_left_off -data "R0lGODlhCQAJAIAAAAAAAAAAACH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgABACwAAAAACQAJAAACEIyPB5CxjN4zctIaV3NwnwIAOw=="

image create photo ::img::graph_arrow_left_on -data "R0lGODlhCQAJAIAAADOZ/wAAACH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgABACwAAAAACQAJAAACEIyPB5CxjN4zctIaV3NwnwIAOw=="

image create photo ::img::graph_arrow_right_off -data "R0lGODlhCQAJAIAAAAAAAAAAACH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgABACwAAAAACQAJAAACD4yPBpC6uCJzctZ5YnutFQA7"

image create photo ::img::graph_arrow_right_on -data "R0lGODlhCQAJAIAAADOZ/wAAACH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgABACwAAAAACQAJAAACD4yPBpC6uCJzctZ5YnutFQA7"

class Integrationwizard {
    inherit Processingwizard
	
    # This variable is liknked to the wait check button and 
    # will be true if we want to send a wait command
    # or false if we don't
    private variable wait_act_state 0
	
    # Layout sizes
    private variable integration_row_height "150"

    private variable block_size "10"
    private variable num_blocks "1"
    private variable current_block "1"
    private variable currently_displayed_block ""

    private variable regional_profile_numbers_by_item ; # array

    private variable histogram_names_by_item ; # array

    private variable left_histogram_arrow ; # array do not initialize
    private variable right_histogram_arrow ; # array do not initialize
    private variable histogram_title ; # array do not initialize
    private variable histogram_summary_label ; # array do not initialize
    
    # Graph datapoint images (NB arrays - don't initialize!)
    private variable markers
    private variable datapoints
    private variable colours
    private variable fgcolours

    # Variables for keeping track of current view and graph resizing
    private variable current_histogram_var "profile_fitted"
    private variable current_histogram_name ""

    # variable for keeping track of image list
    private variable an_image_list
    public method restoreGrid
    public method clear

    # Auxiliary processing methods
    private method getScript
    public method newResults
    public method copyResults
    public method updateImages
    public method defaultImageSelection
    private method disableAutoMTZGeneration

    # Result display methods
    public method initializeTreesAndGraphs
    public method refreshRegionalProfileTree
    public method updateRegionalProfileTree
    public method refreshIntegrationTreeAndGraph
    public method updateIntegrationTreeAndGraph
    public method reloadIntegrationTree
    public method refreshHistogramTree
    public method updateHistogramTree

    public method plotIntegrationGraph
    public method plotSpotMeasurementHistogram
    public method displayRegionalProfile
    public method displayHistogram

    public method updateRegionalProfileSelection
    public method updateHistogramSelection

    # Feedback processing methods
    public method updateRegionalProfileData
    public method updateIntegrationStatus
    public method updateIntegrationData
    public method finishedProcessing

    private method fixDefaultParameters

    public method getWaitState
    public method toggleWait
    public method resetCurrentBlock
    
    public method selectMTZforPointless

    protected method toggleAbility

    constructor { args } { }
}

body Integrationwizard::constructor { args } {

    set processing_stage "integration"

    # Toolbar items

    itk_component add auto_update_mtz_tb {
	SettingToolbutton $itk_component(toolbar).aumtb "auto_update_mtz" \
	    -image ::img::auto_update_mtz16x16 \
	    -activeimage ::img::auto_update_mtz_on16x16 \
	    -balloonhelp "Auto-generate MTZ file name"
    }

    itk_component add mtz_file_e {
        SettingEntry $itk_component(toolbar).me mtz_file \
	    -image ::img::mtz_file16x16 \
	    -balloonhelp "MTZ filename" \
	    -editcommand [code $this disableAutoMTZGeneration]
    }

    itk_component add exclude_ice_tb {
	SettingToolbutton $itk_component(toolbar).eitb "resolution_exclude_ice" \
	    -image ::img::exclude_ice16x16 \
	    -activeimage ::img::exclude_ice_on16x16 \
	    -balloonhelp "Exclude ice rings during integration"
    }

    itk_component add wait_e {
        SettingEntry $itk_component(toolbar).wait_e wait_length \
	    -balloonhelp "The number of seconds mosflm will wait for the appearance of an image" \
	    -type int \
		-minimum "0" \
	    -width 7 \
	    -justify right
    }
	
    itk_component add wait_check {
        SettingCheckbutton $itk_component(toolbar).wait_c wait_activation \
		-command [code $this toggleWait]
    }

    itk_component add wait_tb {
	SettingToolbutton $itk_component(toolbar).wait_tb "wait_activation" \
	    -command [code $this toggleWait] \
	    -image ::img::wait \
	    -activeimage ::img::wait_active \
	    -balloonhelp "Wait for and process images that have not been collected yet. "
    }

    itk_component add quick_symm_tb {
	Toolbutton $itk_component(toolbar).qsymmtb \
	    -balloonhelp "Run Pointless" \
	    -command [code $this runPointless "1" "0"]
	    # arguments are pointless_only_bool and treat_anomalous_bool
    }
    $itk_component(quick_symm_tb) component button configure -text "QuickSymm"

    itk_component add quick_scale_tb {
	Toolbutton $itk_component(toolbar).qscaletb \
	    -balloonhelp "Run Pointless followed by Aimless/Scala and Ctruncate" \
	    -command [code $this runPointless "0" "1"]
	    # arguments to runPointless are pointless_only_bool and treat_anomalous_bool
    }
    $itk_component(quick_scale_tb) component button configure -text "QuickScale"

    itk_component add treat_anom_tb {
	SettingToolbutton $itk_component(toolbar).tranom "treat_anomalous_data" \
	    -image ::img::effdblprime \
	    -balloonhelp "Treat anomalous data in QuickScale"
    }

    # Heading
    $itk_component(heading_l) configure -text "Integration"

    # Add image numbers selector - 
    itk_component add image_numbers {
	ImagenumbersSingle $itk_component(image_numbers_frame).in \
	    -command [code $this getImageList]
    }
    pack $itk_component(image_numbers) -fill both -expand 1


    # Add regional profiles widgets    

    itk_component add regional_profile_f {
	frame $itk_interior.normal.rf.rpf
    }

    itk_component add divider2 {
	frame $itk_component(toolbar).div2 \
	    -width 2 \
	    -relief sunken \
	    -bd 1
    }

    itk_component add regional_profile_tree {
	treectrl $itk_interior.normal.rf.rpf.t \
	    -showbuttons 0 \
	    -showlines 0\
	    -showroot 0 \
	    -width 50 \
	    -height $integration_row_height \
	    -highlightthickness 0 \
	    -font font_s
    } {
	rename -background -textbackground textBackground Background
	#rename -font -entryfont entryFont Font
    }

    $itk_component(regional_profile_tree) column create -text Block -justify right -expand 1
    $itk_component(regional_profile_tree) state define AVAILABLE
    $itk_component(regional_profile_tree) element create e_text text -fill {white {selected AVAILABLE} lightgrey {!AVAILABLE}}
    $itk_component(regional_profile_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
    $itk_component(regional_profile_tree) style create s1
    $itk_component(regional_profile_tree) style elements s1 {e_highlight e_text}
    $itk_component(regional_profile_tree) style layout s1 e_text -expand ns
    $itk_component(regional_profile_tree) style layout s1 e_highlight -union [list e_text] -iexpand nsew -ipadx 2

    $itk_component(regional_profile_tree) notify bind $itk_component(regional_profile_tree) <Selection> [code $this updateRegionalProfileSelection %S]

    itk_component add regional_profile_sb {
	scrollbar $itk_interior.normal.rf.rpf.sb \
	    -command [code $this component regional_profile_tree yview] \
	    -orient vertical
    }

    $itk_component(regional_profile_tree) configure \
	-yscrollcommand [list autoscroll $itk_component(regional_profile_sb)]

    itk_component add regional_profile_c {
	canvas $itk_interior.normal.rf.rpf.c \
	    -background white \
	    -relief sunken \
	    -borderwidth 2 \
	    -height $integration_row_height \
	    -highlightthickness 0
    }
    bind $itk_component(regional_profile_c) <4> [code $this zoom $itk_component(regional_profile_f)]
    bind $itk_component(regional_profile_c) <5> [code $this restoreGrid]
    bind $itk_component(regional_profile_c) <Control-1> [code $this toggleZoom $itk_component(regional_profile_f)]
    bind $itk_component(regional_profile_c) <Shift-1> [code $this toggleZoom $itk_component(regional_profile_f)]
    

    # Add integration results tree

    itk_component add integration_tree {
	treectrl $itk_interior.normal.rf.it \
	    -showroot 0 \
	    -showline 0 \
	    -showbutton 0 \
	    -selectmode multiple \
	    -width 284 \
	    -height $integration_row_height \
	    -itemheight 15 \
	    -highlightthickness 0 \
	    -font font_s
    } {
	rename -background -textbackground textBackground Background
	#rename -font -entryfont entryFont Font
    }
	$itk_component(integration_tree) column create -text "Parameter" -justify left -minwidth 120 -expand 1
	$itk_component(integration_tree) column create -text "Full" -justify right -minwidth 60 -expand 1 -tag full
	$itk_component(integration_tree) column create -text "Partial" -justify right -minwidth 60 -expand 1 -tag partial
	$itk_component(integration_tree) element create e_text text -fill {white selected}
	$itk_component(integration_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
	$itk_component(integration_tree) style create s1
	$itk_component(integration_tree) style elements s1 { e_highlight e_text }
	$itk_component(integration_tree) style layout s1 e_text -expand ns
	$itk_component(integration_tree) style layout s1 e_highlight -union [list e_text] -iexpand nsew -ipadx 2
	bind $itk_component(integration_tree) <Motion> [code $this treectrlMotion "integration" %W %x %y]
	bind $itk_component(integration_tree) <Leave> [code $this treectrlLeave]
	$itk_component(integration_tree) notify bind $itk_component(integration_tree) <Selection> [code $this plotIntegrationGraph]

    # Add integration results graph canvas

    itk_component add integration_canvas {
	canvas $itk_interior.normal.rf.integration_canvas \
	    -relief sunken \
	    -height $integration_row_height \
	    -borderwidth 2 \
	    -highlightthickness 0
    } {
	rename -background -textbackground textBackground Background
    }
    bind $itk_component(integration_canvas) <Configure> [code $this plotIntegrationGraph]
    bind $itk_component(integration_canvas) <4> [code $this zoom %W ]
    bind $itk_component(integration_canvas) <5> [code $this restoreGrid]
    bind $itk_component(integration_canvas) <Control-1> [code $this toggleZoom %W ]
    bind $itk_component(integration_canvas) <Shift-1> [code $this toggleZoom %W ]

    # Add histograms frame

    itk_component add histogram_f {
	frame $itk_interior.normal.rf.hf
    }

    # Add histograms tree

    itk_component add histogram_tree {
	treectrl $itk_interior.normal.rf.hf.lb \
	    -showbuttons 0 \
	    -showlines 0\
	    -showroot 0 \
	    -width 50 \
	    -height $integration_row_height \
	    -highlightthickness 0 \
	    -font font_s
    } {
	rename -background -textbackground textBackground Background
	#rename -font -entryfont entryFont Font
    }

    $itk_component(histogram_tree) column create -text Image -justify right -expand 1
    $itk_component(histogram_tree) state define AVAILABLE
    $itk_component(histogram_tree) element create e_text text -fill {white {selected AVAILABLE} lightgrey {!AVAILABLE}}
    $itk_component(histogram_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
    $itk_component(histogram_tree) style create s1
    $itk_component(histogram_tree) style elements s1 {e_highlight e_text}
    $itk_component(histogram_tree) style layout s1 e_text -expand ns
    $itk_component(histogram_tree) style layout s1 e_highlight -union [list e_text] -iexpand nsew -ipadx 2

    $itk_component(histogram_tree) notify bind $itk_component(histogram_tree) <Selection> [code $this updateHistogramSelection %S]

    itk_component add histogram_sb {
	scrollbar $itk_interior.normal.rf.hf.sb \
	    -command [code $this component histogram_tree yview] \
	    -orient vertical
    }

    $itk_component(histogram_tree) configure \
	-yscrollcommand [list autoscroll $itk_component(histogram_sb)]

    # Add histograms canvas

    itk_component add histogram_c {
	canvas $itk_interior.normal.rf.hf.c \
	    -background white \
	    -relief sunken \
	    -height $integration_row_height \
	    -borderwidth 2 \
	    -highlightthickness 0
    }
    bind $itk_component(histogram_c) <4> [code $this zoom $itk_component(histogram_f)]
    bind $itk_component(histogram_c) <5> [code $this restoreGrid]
    bind $itk_component(histogram_c) <Control-1> [code $this toggleZoom $itk_component(histogram_f)]
    bind $itk_component(histogram_c) <Shift-1> [code $this toggleZoom $itk_component(histogram_f)]

    # Arrange widgets

    set margin 7

    pack $itk_component(auto_update_mtz_tb) \
 	-side left \
	-padx 2

    pack $itk_component(mtz_file_e) \
 	-side left \
	-padx 2

    pack $itk_component(exclude_ice_tb) \
 	-side left \
	-padx 2

    pack $itk_component(wait_tb) \
 	-side left \
	-padx 2

    pack $itk_component(divider2) \
	-side left \
	-fill y \
	-padx 5 \
	-pady 1

    pack $itk_component(quick_symm_tb) \
	-side left \
	-padx 2

    pack $itk_component(quick_scale_tb) \
	-side left \
	-padx 2

    pack $itk_component(treat_anom_tb) \
	-side left \
	-padx 2

    # Grid regional profile frame 
    grid $itk_component(regional_profile_f) -row 1 -column 5 -sticky news -pady $margin
    # Gid regional profile widgets
    grid $itk_component(regional_profile_tree) $itk_component(regional_profile_sb) $itk_component(regional_profile_c) -sticky nswe
    grid columnconfigure $itk_component(regional_profile_f) 2 -weight 1
    grid rowconfigure $itk_component(regional_profile_f) 0 -weight 1
    # Grid integration row
    grid x $itk_component(integration_tree) x $itk_component(integration_canvas) x $itk_component(histogram_f) -sticky nsew -pady [list 0 $margin]
    # Grid histogram widgets
    grid $itk_component(histogram_tree) $itk_component(histogram_sb) $itk_component(histogram_c) -sticky nswe
    grid columnconfigure $itk_component(histogram_f) 2 -weight 1
    grid rowconfigure $itk_component(histogram_f) 0 -weight 1

    grid rowconfigure $itk_component(results_f) { 0 1 2 } -weight 1


    # Setup information for tables and graphs
    
    # Create temporary results object to create tree items from
    set t_results [newResults]

    foreach i_param [$t_results getResultMeasures] {
	# create a new item
	set t_param_item [$itk_component(integration_tree) item create]
	# set the item's style
	$itk_component(integration_tree) item style set $t_param_item 0 s1 1 s1 2 s1
	# update the item's text
	$itk_component(integration_tree) item text $t_param_item 0 [$t_results getParameterName $i_param] 1 "" 
	# add the new item to the tree
	$itk_component(integration_tree) item lastchild root $t_param_item
	# Store pointer to image objects and items by bumber, item or object
	set items_by_parameter($i_param) $t_param_item
	set parameters_by_item(integration,$t_param_item) $i_param
    }
    # delete temporary results object
    delete object $t_results

    # Make default graphing selection
    $itk_component(integration_tree) selection add $items_by_parameter(mean_profile_fitted)

   # Set up histogram information
    ##############################
    
    # set up mappings of graph arrows
    set left_histogram_arrow(profile_fitted) spot_count
    set right_histogram_arrow(profile_fitted) summation_integration
    set left_histogram_arrow(summation_integration) profile_fitted
    set right_histogram_arrow(summation_integration) spot_count
    set left_histogram_arrow(spot_count) summation_integration
    set right_histogram_arrow(spot_count) profile_fitted

    # set up histogram_title
    set histogram_title(profile_fitted) "Profile fits (I/\u3c3(I)) -v- Resolution (\uc5)"
    set histogram_title(summation_integration) "Summations (I/\u3c3(I)) -v- Resolution (\uc5)"
    set histogram_title(spot_count) "Spot count -v- Resolution (\uc5)"
    
    # Setup summary labels
    set histogram_summary_label(profile_fitted) "Mean"
    set histogram_summary_label(summation_integration) "Mean"
    set histogram_summary_label(spot_count) "Total"
 

    eval itk_initialize $args
    set an_image_list {}

}

body Integrationwizard::toggleWait {a_value} {
    #puts $a_value
    if {$a_value == "0"} {
	$::session updateSetting "wait_activation" $a_value 0 0 "User" 0
	$::session updateSetting "wait_length" "0" 1 1 "User" 0
	$itk_component(wait_e) configure -state disabled
	defaultImageSelection
    } else {
	$itk_component(wait_e) configure -state normal
    }
}		

body Integrationwizard::getWaitState {} {
	return $wait_act_state
}

body Integrationwizard::restoreGrid { } {

    if {$zoomed} {
	Processingwizard::restoreGrid
	# Grid regional profile frame 
	grid $itk_component(regional_profile_f) -row 1 -column 5 -sticky news -pady $margin
	# Grid integration row
	grid x $itk_component(integration_tree) x $itk_component(integration_canvas) x $itk_component(histogram_f) -sticky nsew -pady [list 0 $margin]
	grid rowconfigure $itk_component(results_f) { 0 1 2 } -weight 1
    }
}

body Integrationwizard::clear { } {

    # Clear general processing wizard components
    Processingwizard::clear
    
    # Clear regional profiles
    $itk_component(regional_profile_tree) item delete all
    $itk_component(regional_profile_c) delete all
    bind $itk_component(regional_profile_c) <Configure> {}

    # Clear results
    foreach i_item [$itk_component(integration_tree) item children root] {
	$itk_component(integration_tree) item text $i_item 1 "" 2 ""
    }
    $itk_component(integration_canvas) delete all
    bind $itk_component(integration_canvas) <Configure> {}

    # Clear histograms
    $itk_component(histogram_tree) item delete all
    $itk_component(histogram_c) delete all
    bind $itk_component(histogram_c) <Configure> {}

}    

body Integrationwizard::newResults { args } {
    return [namespace current]::[eval Integrationresults \#auto "new" $args]
}

body Integrationwizard::copyResults { a_results } {
    return [namespace current]::[Integrationresults \#auto "copy" $a_results]
}

body Integrationwizard::updateImages { an_image_list args } {

    if { $an_image_list == {} } {
	#puts "IN INTEGRATION UPDATE IMAGES with no image_list"
    }
    Processingwizard::updateImages $an_image_list [lindex $args 0]
    # Update mtz file
    set l_mtz_file [$::session getParameterValue mtz_file]
    set l_first [lindex $an_image_list 0]
    if { $l_first != "" } {
	if { ($l_mtz_file == "") || ($l_mtz_file != [$l_first makeAuxiliaryFileName "mtz"]) } {
	    if {[$itk_component(auto_update_mtz_tb) query]} {
		$itk_component(mtz_file_e) update [$l_first makeAuxiliaryFileName "mtz"]
	    }
	}
    }
}

body Integrationwizard::defaultImageSelection {} {

    # Need to set the sector number for updating - was hard-coded as 0

    updateImages [[$::session getCurrentSector] getImages]

    #puts [[$::session getCurrentSector] getImages]

}	

body Integrationwizard::disableAutoMTZGeneration { } {

    #puts [$itk_component(mtz_file_e) getValue]
    $itk_component(auto_update_mtz_tb) cancel
}

body Integrationwizard::initializeTreesAndGraphs { } {

    #puts "here - Integrationwizard::initializeTreesAndGraphs"
    Processingwizard::initializeTreesAndGraphs
    refreshRegionalProfileTree
    refreshIntegrationTreeAndGraph
    refreshHistogramTree
}

body Integrationwizard::refreshHistogramTree { } {
     # Clear previous histogram tree entries
    $itk_component(histogram_tree) item delete all
    array unset histogram_items_by_name *
    array unset histogram_names_by_item *
    set current_histogram_name ""
    $itk_component(histogram_c) delete all

    # Add entries for each image to the histogram tree
    set t_item ""
    foreach i_image_name [$results listIntegratedImages] {
        set l_image [$::session getImageByName $i_image_name]
        set t_item [$itk_component(histogram_tree) item create]
        $itk_component(histogram_tree) item style set $t_item 0 s1
        $itk_component(histogram_tree) item text $t_item 0 [$l_image getNumber]
        $itk_component(histogram_tree) item state set $t_item AVAILABLE
        $itk_component(histogram_tree) item lastchild root $t_item
        set histogram_items_by_name($i_image_name) $t_item
        set histogram_names_by_item($t_item) $i_image_name
    }
    $itk_component(histogram_tree) item sort root -dictionary
    set l_item [$itk_component(histogram_tree) item lastchild root]
    if {$l_item != ""} {
        $itk_component(histogram_tree) selection modify $l_item all
    }
}

body Integrationwizard::updateHistogramTree { l_image } {

    set current_histogram_name ""

    # Add entries for this image object to the histogram tree
    set t_item ""
    set t_item [$itk_component(histogram_tree) item create]
    $itk_component(histogram_tree) item style set $t_item 0 s1
    $itk_component(histogram_tree) item text $t_item 0 [$l_image getNumber]
    $itk_component(histogram_tree) item state set $t_item AVAILABLE
    $itk_component(histogram_tree) item lastchild root $t_item
    set histogram_names_by_item($t_item) [$l_image getShortName]

    set l_item [$itk_component(histogram_tree) item lastchild root]
    if {$l_item != ""} {
	# Modifying the selection will displayHistogram
	$itk_component(histogram_tree) selection modify $l_item all
    }
    # Scroll down
    $itk_component(histogram_tree) yview moveto 1.0
}

body Integrationwizard::getScript { an_image_list } {

    # initialize script
    set l_script ""

    #puts "$an_image_list"
    # get first image
    set l_first [lindex $an_image_list 0]
    #puts "$l_first"
    set l_directory [$l_first getDirectory]
    #puts "$l_directory"

    # Image details
    set l_detector [$::session getFullDetectorInformation]
    if { $l_detector != "" } {
	append l_script "$l_detector\n"
    }

    append l_script "directory $l_directory\n"
    append l_script "template [$l_first getTemplate]\n"

    # Provide data harvesting labels
    if {[$::session getParameterValue project] != ""} {
	append l_script "pname [$::session getParameterValue project]\n"
    }
    if {[$::session getParameterValue dataset] != ""} {
	append l_script "dname [$::session getParameterValue dataset]\n"
    }
    if {[$::session getParameterValue crystal] != ""} {
	append l_script "xname [$::session getParameterValue crystal]\n"
    }
    if {[$::session getParameterValue title] != ""} {
	append l_script "title [$::session getParameterValue title]\n"
    }

    # Masks
    foreach i_mask [Mask::getMasks] {
	set l_coords [$i_mask getMmCoords]
	if {[llength $l_coords] == 8} {
	    append l_script "limits quadrilateral $l_coords\n"
	}
    }

    # Provide experiment settings

    # Beam details
    if {![$::session getTwoTheta]} {
	append l_script "beam [$::session getBeamPosition]\n"
    } else {
	append l_script "beam swungout [$::session getBeamPosition]\n"
    }

    # Distance
    append l_script "distance [$::session getDistance]\n"
    # Wavelength
    append l_script "wavelength [$::session getWavelength]\n"
    # Two theta
    append l_script "twotheta [$::session getTwoTheta]\n"

    # Beam divergence
    append l_script "divergence [$::session getParameterValue divergence_x] [$::session getParameterValue divergence_y]\n"
    # Gain
    append l_script "gain [$::session getParameterValue "gain"]\n"

    append l_script "pixel [$::session getParameterValue "pixel_size"]\n"

    if {[$::session getParameterValue "adcoffset"] != ""} {
	append l_script "ADCOFFSET [$::session getParameterValue "adcoffset"]\n"
    }

    append l_script "DISTORTION YSCALE [$::session getParameterValue yscale] TILT [expr [$::session getParameterValue tilt] * 100] TWIST [expr [$::session getParameterValue twist] * 100]\n"	

    
    if {[$::session getParameterValue "overload_cutoff"] != ""} {
	append l_script "OVERLOAD CUTOFF [$::session getParameterValue "overload_cutoff"]\n"
    }

    append l_script "pixel [$::session getParameterValue "pixel_size"]\n"
    append l_script "dispersion [$::session getParameterValue dispersion]\n"
    if {[$::session getParameterValue "xray_source"] == "lab"} {
	append l_script "polarisation pinhole\n"
    } else {
	append l_script "polarisation synchrotron [$::session getParameterValue "polarization"]\n"
    }

    # Provide matrix and spacegroup (indexing results)

    # Matrix + spacegroup - need to be provided for when user loads a session
    #  that they've previously indexed 
    append l_script "matrix [[$l_first getSector] listMatrix]\n"
    append l_script "cell [[$::session getCell] listCell]\n"
    append l_script "symmetry [$::session reportSpacegroup]\n"
    append l_script "mosaicity [$::session getMosaicity] BLOCKSIZE [$::session getParameterValue mosaicblock]\n"

    # Integration settings

    # Tell mosflm where to write output (hklout and genfile)
    set l_mtz_file [$::session getParameterValue mtz_file]
    if { ($l_mtz_file == "") || ($l_mtz_file != [$l_first makeAuxiliaryFileName "mtz"]) } {
	set l_mtz_file [$l_first makeAuxiliaryFileName "mtz"]
	$::session updateSetting "mtz_file" $l_mtz_file 1 1
    }
    # Tell mosflm which directory to write hklout
    set l_mtz_directory [$::session getParameterValue mtz_directory]
    if {$l_mtz_directory != ""} {
	append l_script "mtzdirectory $l_mtz_directory\n"
    }
    if {[$::session getParameterValue multiple_mtz_files]} {
	append l_script "hklout $l_mtz_file multiple\n"
    } else {
	append l_script "hklout $l_mtz_file nomultiple\n"
    }

    # Apply resolution limits
    append l_script "resolution exclude none\n"
    append l_script "[$::session getResolutionCommand]\n"

    # Raster
    if {[$::session rasterIsValid]} {
	append l_script "raster [$::session getRaster]\n"
    }

    # Nullpix
    append l_script "nullpix [$::session getParameterValue nullpix]\n"

    # Reflection width limit
    append l_script "maxwidth [$::session getParameterValue "max_refl_width"]\n"

    # Profile
    append l_script "[$::session getProfileCommand]\n"

    # Set backstop
    append l_script "[$::session getBackstopCommand]\n"
    
    # Apply separation limits
    if {[$::session separationCommandRequired]} {
	append l_script "[$::session getSeparationCommand]\n"
    }
    # Apply refinement fixes
    append l_script "[$::session getRefinementCommand integration]\n"
    # Apply postrefinement fixes
    append l_script "[$::session getPostrefinementCommand integration]\n"

    # Get block size
    set l_block_size [$::session getParameterValue "block_size"] 
    if {$l_block_size == ""} {
	set l_block_subcommand ""
    } else {
	set l_block_subcommand "block $l_block_size"
    }

    # Get batch number
    set l_batch_number [$::session getParameterValue "batch_number"]
    if {$l_batch_number == ""} {
	set l_batch_number 0
    }

    # Integration commands
    set l_pair_list [$::mosflm getProcessingRuns $an_image_list]
    foreach i_pair $l_pair_list {
	foreach { i_start i_end } $i_pair {
	    set t_image [$::session getImageByTemplateAndNumber [$l_first getTemplate] $i_start]
	    if {[$t_image hasMissets]} {
		append l_script "misset [$t_image getMissets]\n"
	    }
	    foreach { l_phi_start l_phi_end } [$t_image getPhi] break
	    append l_script "process $i_start $i_end start $l_phi_start angle [expr $l_phi_end - $l_phi_start] $l_block_subcommand add $l_batch_number\n"
	}
    }
    append l_script "go\n"
    
    append l_script "exit\n"

    return $l_script
}

body Integrationwizard::updateIntegrationStatus { } {

    set l_image_number [$results getNextIntegrand]
    .c updateStatusMessage "Integrating image $l_image_number"

    # Update progress bar!
    .c progress [$results getProgress]
}

body Integrationwizard::updateIntegrationData { a_dom } {
    # prompt mosflm to continue or abort if necessary
    if {$processing_order == "continue"} {
	update idletasks
	$::mosflm promptProcessing "continue"
    } elseif {$processing_order == "abort"} {
	#puts "Ordered to $processing_order in updateIntegrationData"
	$::mosflm removeJob "integration"
	$::mosflm promptProcessing "abort"
    } else {
	# Must be paused...
    }

    # Clear integration data from any previous image
    set l_bin_resolution_limits [list "\u221e"]
    set l_spot_count_fulls {}
    set l_spot_count_partials {}
    set l_profile_fitted_fulls {}
    set l_profile_fitted_partials {}
    set l_summation_integration_fulls {}
    set l_summation_integration_partials {}
    set l_overloads {}
    set l_badspots {}
    set l_soverlaps {}
    set n_image 0
        
    # Get image name from xml
    set l_image_name [$a_dom selectNodes normalize-space(//image_name)]

    # Get overloads & badspots from xml
    set l_overloads [$a_dom selectNodes normalize-space(//overloads)]
    set l_badspots [$a_dom selectNodes normalize-space(//badspots)]
    
    # Record image as having been integrated
    $results recordImageAsIntegrated $l_image_name
    #puts "$l_image_name Overloads: $l_overloads Bad Spots: $l_badspots"

    # Get image object from name & number from object
    set l_image [$::session getImageByName $l_image_name]
    #puts "$l_image from $l_image_name"
    # Get spatial overlaps from stored list
    set n_image [$l_image getNumber]
    set l_soverlaps [$::session getSpatialOverlaps $n_image]
    #puts "Image no: $n_image Spatial overlaps: $l_soverlaps"

    # Extract results from xml
    foreach number { 1 2 3 4 5 6 7 8 9 } {
	set bin [$a_dom selectNodes //bin$number]
	lappend l_bin_resolution_limits [$bin selectNodes normalize-space(upper_limit)]
	lappend l_spot_count_fulls [$bin selectNodes normalize-space(spot_count_fulls)]
	lappend l_spot_count_partials  [$bin selectNodes normalize-space(spot_count_partials)]
	lappend l_profile_fitted_fulls  [$bin selectNodes normalize-space(profile_fitted_fulls)]
	lappend l_profile_fitted_partials [$bin selectNodes normalize-space(profile_fitted_partials)]
	lappend l_summation_integration_fulls [$bin selectNodes normalize-space(summation_integration_fulls)]
	lappend l_summation_integration_partials [$bin selectNodes normalize-space(summation_integration_partials)]
	lappend l_overloads_fulls $l_overloads
	lappend l_badspots_fulls $l_badspots
	lappend l_soverlaps_fulls $l_soverlaps
    }
    
    # Save integration results of latest image in array with all other images 
    $results addHistogramData $l_image_name bin_resolution_limits $l_bin_resolution_limits
    $results addHistogramData $l_image_name spot_count_fulls $l_spot_count_fulls
    $results addHistogramData $l_image_name spot_count_partials $l_spot_count_partials
    $results addHistogramData $l_image_name profile_fitted_fulls $l_profile_fitted_fulls
    $results addHistogramData $l_image_name profile_fitted_partials $l_profile_fitted_partials
    $results addHistogramData $l_image_name summation_integration_fulls $l_summation_integration_fulls
    $results addHistogramData $l_image_name summation_integration_partials $l_summation_integration_partials
    $results addHistogramData $l_image_name overloads_fulls $l_overloads_fulls
    # but dont bother adding a partials component
    $results addHistogramData $l_image_name badspots_fulls $l_badspots_fulls
    # but dont bother adding a partials component
    $results addHistogramData $l_image_name soverlaps_fulls $l_soverlaps_fulls
    # but dont bother adding a partials component
    
    # Save summary integration info in lists for graphing
    $results appendResult "total_spot_count_fulls" [lindex $l_spot_count_fulls end]
    $results appendResult "outer_spot_count_fulls" [lindex $l_spot_count_fulls end-1]
    $results appendResult "total_spot_count_partials" [lindex $l_spot_count_partials end]
    $results appendResult "outer_spot_count_partials" [lindex $l_spot_count_partials end-1]

    $results appendResult "mean_profile_fitted_fulls" [lindex $l_profile_fitted_fulls end]
    $results appendResult "outer_profile_fitted_fulls" [lindex $l_profile_fitted_fulls end-1]
    $results appendResult "mean_profile_fitted_partials" [lindex $l_profile_fitted_partials end]
    $results appendResult "outer_profile_fitted_partials" [lindex $l_profile_fitted_partials end-1]

    $results appendResult "mean_summation_integration_fulls" [lindex $l_summation_integration_fulls end]
    $results appendResult "outer_summation_integration_fulls" [lindex $l_summation_integration_fulls end-1]
    $results appendResult "mean_summation_integration_partials" [lindex $l_summation_integration_partials end]
    $results appendResult "outer_summation_integration_partials" [lindex $l_summation_integration_partials end-1]
    
    $results appendResult "overloads_fulls" [lindex $l_overloads_fulls end]
    # but dont bother adding a partials component
    $results appendResult "badspots_fulls"  [lindex $l_badspots_fulls end]
    # but dont bother adding a partials component
    $results appendResult "soverlaps_fulls"  [lindex $l_soverlaps_fulls end]
    # but dont bother adding a partials component

    # update tree and graph here if required per image
    updateIntegrationTreeAndGraph

    # Update histogram tree
    updateHistogramTree $l_image

    # Update status (if the next thing is going to an intgegration)
    .c updateStatusMessage [$results getIntegrationStatus]
    .c progress [$results getProgress]
}

body Integrationwizard::updateRegionalProfileData { a_dom } {

    # Extract grid dimensions
    set l_dim_x [$a_dom selectNodes normalize-space(//number_of_profiles_x)]
    set l_dim_y [$a_dom selectNodes normalize-space(//number_of_profiles_y)]

    # Create a profile grid
    $results addProfileGrid $current_block $l_dim_x $l_dim_y

    # Extract profiles and add them to the grid
    foreach i_profile_node [$a_dom selectNodes //profile] {
	set l_box [$i_profile_node selectNodes normalize-space(box)]
	#incr l_box -1
	set l_width [$i_profile_node selectNodes normalize-space(width)]
	set l_height [$i_profile_node selectNodes normalize-space(height)]
	set l_original_node [$i_profile_node selectNodes original]
	if {$l_original_node != ""} {
	    set l_original_data [$l_original_node selectNodes normalize-space(data)]
	    set l_original_mask [$l_original_node selectNodes normalize-space(mask)]
	    set l_original_source [list $l_original_data $l_original_mask]
	} else {
	    set l_original_source {}
	}
	set l_averaged_node [$i_profile_node selectNodes averaged]
	if {$l_averaged_node != ""} {
	    set l_averaged_data [$l_averaged_node selectNodes normalize-space(data)]
	    set l_averaged_mask [$l_averaged_node selectNodes normalize-space(mask)]
	    set l_averaged_source [list $l_averaged_data $l_averaged_mask]
	} else {
	    set l_averaged_source {}
	}
	$results addRegionalProfile $current_block $l_box $l_width $l_height $l_original_source $l_averaged_source
    }

    updateRegionalProfileTree $current_block

    # update graph
    if { $current_block > 1 } {
	plotIntegrationGraph
    }

    incr current_block

}

body Integrationwizard::refreshRegionalProfileTree { } {
    # Clear previous regional profile tree entries
    $itk_component(regional_profile_tree) item delete all
    array unset regional_profile_items_by_number *
    array unset regional_profile_numbers_by_item *
    #set current_regional_profile ""
    set currently_displayed_block ""

    # update the profile listbox
    set t_item ""
    foreach { i_block i_grid } [$results listProfileGrids] {
        set t_item [$itk_component(regional_profile_tree) item create]
        $itk_component(regional_profile_tree) item style set $t_item 0 s1
        $itk_component(regional_profile_tree) item text $t_item 0 $i_block
        $itk_component(regional_profile_tree) item state set $t_item AVAILABLE
        $itk_component(regional_profile_tree) item lastchild root $t_item
        set regional_profile_items_by_number($i_block) $t_item
        set regional_profile_numbers_by_item($t_item) $i_block
    }
    $itk_component(regional_profile_tree) item sort root -dictionary
    set l_item [$itk_component(regional_profile_tree) item lastchild root]
    if {$l_item != ""} {
        $itk_component(regional_profile_tree) selection modify $l_item all
    }
}

body Integrationwizard::updateRegionalProfileTree { curr_block } {

    #set current_regional_profile ""
    set currently_displayed_block ""

    # update the profile listbox
    set t_item ""
    foreach { i_block i_grid } [$results listProfileGrids] {
	if { $i_block == $curr_block } {
	    #puts "i_block i_grid $i_block $i_grid"
	    set t_item [$itk_component(regional_profile_tree) item create]
	    $itk_component(regional_profile_tree) item style set $t_item 0 s1
	    $itk_component(regional_profile_tree) item text $t_item 0 $i_block
	    $itk_component(regional_profile_tree) item state set $t_item AVAILABLE
	    $itk_component(regional_profile_tree) item lastchild root $t_item
	    set regional_profile_numbers_by_item($t_item) $i_block
	    
	    set l_item [$itk_component(regional_profile_tree) item lastchild root]
	    if {$l_item != ""} {
		$itk_component(regional_profile_tree) selection modify $l_item all
	    }
	    # Scroll down
	    $itk_component(regional_profile_tree) yview moveto 1.0
	}
    }
}

body Integrationwizard::finishedProcessing { } {

    $::session addHistoryEvent IntegrationEvent "Integration" $results
    Processingwizard::finishedProcessing

    if {[$::session getParameterValue pointless_live]} {
    # this is called the final time we run pointless for this group of images
	$::session callPointlessProcess
    }

}

body Integrationwizard::reloadIntegrationTree { item_number } {
    if {([$results listIntegratedImages] == {}) || ($item_number == "")} {
	return
    } else {
	# Clear integration tree
	foreach i_item [$itk_component(integration_tree) item children root] {
	    $itk_component(integration_tree) item text $i_item 1 "" 2 ""
	}
	# Update the results table
	foreach i_result [$results getResultMeasures] {
	    #puts "$items_by_parameter($i_result) [$results getNthResult $i_result "fulls" $item_number] [$results getNthResult $i_result "partials" $item_number]"
	    $itk_component(integration_tree) item text $items_by_parameter($i_result) 1 [$results getNthResult $i_result "fulls" $item_number] 2 [$results getNthResult $i_result "partials" $item_number]
	}
    }
}

body Integrationwizard::refreshIntegrationTreeAndGraph { } {
    if {[$results listIntegratedImages] == {}} {
        # Clear integration trees and graphs
        foreach i_item [$itk_component(integration_tree) item children root] {
            $itk_component(integration_tree) item text $i_item 1 "" 2 ""
        }
        $itk_component(integration_canvas) delete all
    } else {
        # Update the results table
        foreach i_result [$results getResultMeasures] {
            $itk_component(integration_tree) item text $items_by_parameter($i_result) 1 [$results getLastResult $i_result "fulls"] 2 [$results getLastResult $i_result "partials"]
        }
        # Update the results graph
        plotIntegrationGraph
    }
}

body Integrationwizard::updateIntegrationTreeAndGraph { } {
    #puts "updateIntegrationTreeAndGraph no.images: [llength [$results listIntegratedImages]]"
    if {[$results listIntegratedImages] != {}} {
	# Update the results table
	foreach i_result [$results getResultMeasures] {
	    #puts "$items_by_parameter($i_result) [$results getLastResult $i_result "fulls"] [$results getLastResult $i_result "partials"]"
	    $itk_component(integration_tree) item text $items_by_parameter($i_result) 1 [$results getLastResult $i_result "fulls"] 2 [$results getLastResult $i_result "partials"]
	}
	# Update the results graph
	plotIntegrationGraph
    }
}

body Integrationwizard::plotIntegrationGraph { } {
    if {$results != ""} {
	# Build datasets
	set l_data_sets {}
	foreach i_param [$results getResultMeasures] {
	    if {[$itk_component(integration_tree) selection includes $items_by_parameter($i_param)]} {
		set l_data_sets [concat $l_data_sets [$results getResultDataSets $i_param]]
	    }
	}
	# See if anything should be plotted
	if {[llength $l_data_sets] == 0} {
	    # Delete any previous graphs
	    $itk_component(integration_canvas) delete all
	} else {
	    # Calculate window
	    set l_canvas_width [winfo width $itk_component(integration_canvas)]
	    if {$l_canvas_width < 30} {
		set l_canvas_width [winfo reqwidth $itk_component(integration_canvas)]
	    }
	    set l_canvas_height [winfo height $itk_component(integration_canvas)]
	    if {$l_canvas_height < 30} {
		set l_canvas_height [winfo reqheight $itk_component(integration_canvas)]
	    }
	    set window [list 10 10 [expr {$l_canvas_width - 10}] [expr {$l_canvas_height - 10}]]
	    # Create graph
	    set image_data_set [$results getImageDataSet]
	    #puts "Scattergraph for $image_data_set for [llength $l_data_sets] datasets $l_data_sets"
	    ScatterGraph \#auto $itk_component(integration_canvas) $window "id" $image_data_set $l_data_sets

	    bind $itk_component(integration_canvas) <Configure> [code $this plotIntegrationGraph]

	    # Remove the dataset objects to ease memory overheads
	    #puts "Deleting $image_data_set"
	    delete object $image_data_set
	    foreach obj $l_data_sets {
		delete object $obj
		#puts "Deleting $obj"
	    }
	}
    }
}

body Integrationwizard::updateRegionalProfileSelection { a_item } {
    if {$a_item != ""} {
	if {[$itk_component(regional_profile_tree) item state get $a_item AVAILABLE]} {
	    set currently_displayed_block $regional_profile_numbers_by_item($a_item)
	    displayRegionalProfile
	}
    } else {
	$itk_component(regional_profile_c) delete all
    }
    
}

body Integrationwizard::displayRegionalProfile { {a_block ""} } {

    # Update current regional profile if one was passed
    if {$a_block != ""} {
	set currently_displayed_block $a_block
    }
    
    # if there is now a current profile
    if {$currently_displayed_block != ""} {

	# Display the profile
	$results displayRegionalProfiles $currently_displayed_block $itk_component(regional_profile_c)
	
	# Setup bindings to refresh profile when canvas changes
	bind $itk_component(regional_profile_c) <Configure> [code $this displayRegionalProfile]
    }

}

body Integrationwizard::updateHistogramSelection { a_item } {

    if {$a_item != ""} {
	if {[$itk_component(histogram_tree) item state get $a_item AVAILABLE]} {
	    set current_histogram_name $histogram_names_by_item($a_item)
	    displayHistogram
	}
	reloadIntegrationTree $a_item
    } else {
	$itk_component(histogram_c) delete all
    }

}

body Integrationwizard::displayHistogram { } {
    plotSpotMeasurementHistogram
}

body Integrationwizard::plotSpotMeasurementHistogram { args } {
    
    set col1 "\#bb0000"
    set col2 "\#ffcc00"

    set var $current_histogram_var
    set name $current_histogram_name

    foreach { i_param i_val } $args {
	set $i_param $i_val
	set current_histogram_$i_param $i_val
    }

    if {($var == "") || ($name == "")} {
	return
    }

    set dataset1 [$results getHistogramData $name ${var}_fulls]
    set dataset2 [$results getHistogramData $name ${var}_partials]
    set l_bin_resolution_limits [$results getHistogramData $name bin_resolution_limits]
    set left_link [code $this plotSpotMeasurementHistogram var $left_histogram_arrow($var)]
    set right_link [code $this plotSpotMeasurementHistogram var $right_histogram_arrow($var)]
    set title $histogram_title($var)
    set summary_label $histogram_summary_label($var)
    
    # Clear the canvas 
    $itk_component(histogram_c) delete all
    
    # Find the largest y-value to be plotted
    set max_y_val 0
    foreach val [concat $dataset1 $dataset2] {
	if {$val > $max_y_val} {
	    set max_y_val $val
	}
    }
     
    # Plot y axis
	 
    if {$max_y_val < 5} {
	set max_y_val 5
    }

    # Calculate sensible y-tick intervals
    set scale_factor [expr floor(log10($max_y_val))-1]
    set 2sf_max_y_val [expr int($max_y_val / pow(10,$scale_factor))]
    set 2sf_tick_interval [expr $2sf_max_y_val / 5]
    if {$2sf_tick_interval <= 5} {
	if {$2sf_tick_interval == 3} {
	    set 2sf_tick_interval 2
	} else {
	    # leave 2sf_tick_interval as is (1,2,4 or 5)
	}
    } elseif {$2sf_tick_interval <= 15} {
	set 2sf_tick_interval 10
    } else {
	set 2sf_tick_interval 20
    }
    set tick_interval [expr $2sf_tick_interval * pow(10,$scale_factor)]

    set y_axis_length [expr int(ceil(double($max_y_val)/$tick_interval)) * $tick_interval]

    $itk_component(histogram_c) create line 0 0 0 [expr -$y_axis_length] -tags [list y_axis non_tick]
    set y_tick 0
    while {$y_tick <= $y_axis_length} {
	$itk_component(histogram_c) create line 0 [expr - $y_tick] -5 [expr -$y_tick] -tags y_tick
	$itk_component(histogram_c) create text -5 [expr - $y_tick] -text $y_tick -anchor e -tags [list y_tick y_tick_label]
	set y_tick [expr int($y_tick + $tick_interval)]
    }

    # Plot X-Axis

    $itk_component(histogram_c) create line 0 0 320 0 -tags [list x_axis non_tick]
    $itk_component(histogram_c) create line 360 0 400 0 -tags [list x_axis non_tick]
    $itk_component(histogram_c) create line 340 -4 336 4 -tags [list x_tick]
    $itk_component(histogram_c) create line 344 -4 340 4 -tags [list x_tick]
    $itk_component(histogram_c) create line 320 0 338 0 -tags [list x_axis non_tick]
    $itk_component(histogram_c) create line 342 0 360 0 -tags [list x_axis non_tick]
    $itk_component(histogram_c) create line 360 0 360 5 -tags [list x_tick]
    $itk_component(histogram_c) create line 400 0 400 5 -tags [list x_tick]
    set i_ticks 0
    set i_bin_limit 0
    while {$i_ticks <= 320} {
	$itk_component(histogram_c) create line $i_ticks 0 $i_ticks 5 -tags x_tick
	if {[string is double [lindex $l_bin_resolution_limits $i_bin_limit]]} {
	    set t_x_tick_label [format %.1f [lindex $l_bin_resolution_limits $i_bin_limit]]
	} else {
	    set t_x_tick_label [lindex $l_bin_resolution_limits $i_bin_limit]
	}
	$itk_component(histogram_c) create text $i_ticks 5 -text $t_x_tick_label -anchor n -tags [list x_tick_label x_tick]
	incr i_ticks 40
	incr i_bin_limit
    }
    $itk_component(histogram_c) create text 380 5 -text $summary_label -anchor n -tags [list x_tick x_tick_label]
    
    # Plot dataset 1
    
    set x_pos 10
    set i_tag_counter 0
    foreach val $dataset1 {
	# Create bar
	set last_bar [$itk_component(histogram_c) create rectangle $x_pos 0 [expr $x_pos + 9] [expr -$val] -fill $col1 -tags [list "dataset1$i_tag_counter" non_tick]]
	# Bind value label display methods
	$itk_component(histogram_c) bind "dataset1$i_tag_counter" <Enter> [list showValueLabel "$val" $col1 white %X %Y]
	$itk_component(histogram_c) bind "dataset1$i_tag_counter" <Motion> [list moveValueLabel %X %Y]
	$itk_component(histogram_c) bind "dataset1$i_tag_counter" <Leave> [list hideValueLabel]
	incr i_tag_counter
	incr x_pos 40
    }
    $itk_component(histogram_c) move $last_bar 40 0
    
    # Plot dataset 2
    
    set x_pos 20
    foreach val $dataset2 {
	set last_bar [$itk_component(histogram_c) create rectangle $x_pos 0 [expr $x_pos + 9] [expr -$val] -fill $col2 -tags [list "dataset2$i_tag_counter" non_tick]]
	# Bind value label display methods
	$itk_component(histogram_c) bind "dataset2$i_tag_counter" <Enter> [list showValueLabel "$val" $col2 black %X %Y]
	$itk_component(histogram_c) bind "dataset2$i_tag_counter" <Motion> [list moveValueLabel %X %Y]
	$itk_component(histogram_c) bind "dataset2$i_tag_counter" <Leave> [list hideValueLabel]
	incr i_tag_counter
	incr x_pos 40
    }
    $itk_component(histogram_c) move $last_bar 40 0

    # Create title
    $itk_component(histogram_c) create text 200 "-$y_axis_length" -text $title -anchor s -tags [list non_tick title]

    
    # Space required for tick labels and title
    set y_tick_label_bbox [$itk_component(histogram_c) bbox y_tick_label] 
    set y_tick_label_width [expr [lindex $y_tick_label_bbox 2] - [lindex $y_tick_label_bbox 0]]
    set x_tick_label_bbox [$itk_component(histogram_c) bbox x_tick_label] 
    set x_tick_label_height [expr [lindex $x_tick_label_bbox 3] - [lindex $x_tick_label_bbox 1]]
    set title_bbox [$itk_component(histogram_c) bbox title] 
    set title_height [expr ([lindex $title_bbox 3] - [lindex $title_bbox 1])]
    #set title_height 0

    # Scale axes and data in x and y to fit canvas size (but not ticks!)
    $itk_component(histogram_c) scale non_tick 0 0 [expr (double([winfo width $itk_component(histogram_c)])-($y_tick_label_width + 40)) / (400)] [expr (double([winfo height $itk_component(histogram_c)])-($x_tick_label_height + $title_height + 40)) / ($y_axis_length)]


    # Scale y-ticks in y only
    $itk_component(histogram_c) scale y_tick 0 0 1 [expr (double([winfo height $itk_component(histogram_c)])-($x_tick_label_height + $title_height + 40)) / ($y_axis_length)]

    # Scale x-ticks in x only
    $itk_component(histogram_c) scale x_tick 0 0 [expr (double([winfo width $itk_component(histogram_c)])-($y_tick_label_width + 40)) / (400)] 1
    
    # Move entire graph to centre of canvas
    $itk_component(histogram_c) move all [expr 20 + $y_tick_label_width] [expr 20 + $title_height + ($y_axis_length * ((double([winfo height $itk_component(histogram_c)])-($x_tick_label_height + $title_height + 40)) / ($y_axis_length)))]

    # Move title into top margin space for nicer layout
    $itk_component(histogram_c) move title 0 -10

    # Create legend
    $itk_component(histogram_c) create text 0 0 -text "Full reflections" -anchor w -tags legend
    $itk_component(histogram_c) create rectangle -5 -5 -15 5 -fill $col1 -tags legend
    $itk_component(histogram_c) create text 0 20 -text "Partial reflections" -anchor w -tags legend
    $itk_component(histogram_c) create rectangle -5 15 -15 25 -fill $col2 -tags legend

    # Position legend
    set legend_bbox [$itk_component(histogram_c) bbox legend]
    set x_axis_bbox [$itk_component(histogram_c) bbox x_axis]
    set y_axis_bbox [$itk_component(histogram_c) bbox y_axis]
    $itk_component(histogram_c) move legend [expr [lindex $x_axis_bbox 2] - [lindex $legend_bbox 2]] [expr [lindex $y_axis_bbox 1] - [lindex $legend_bbox 1]]

    # Create arrow buttons
    $itk_component(histogram_c) create image 5 5 -image ::img::graph_arrow_left_off -anchor nw -tags graph_arrow_left
    $itk_component(histogram_c) create image [expr [winfo width $itk_component(histogram_c)] - 5] 5 -image ::img::graph_arrow_right_off -anchor ne -tags graph_arrow_right

    # Set up arrow button bindings
    $itk_component(histogram_c) bind graph_arrow_left <Enter> [list $itk_component(histogram_c) itemconfigure graph_arrow_left -image ::img::graph_arrow_left_on]
    $itk_component(histogram_c) bind graph_arrow_left <Leave> [list $itk_component(histogram_c) itemconfigure graph_arrow_left -image ::img::graph_arrow_left_off]
    $itk_component(histogram_c) bind graph_arrow_left <ButtonPress-1> $left_link
    
    $itk_component(histogram_c) bind graph_arrow_right <Enter> [list $itk_component(histogram_c) itemconfigure graph_arrow_right -image ::img::graph_arrow_right_on]
    $itk_component(histogram_c) bind graph_arrow_right <Leave> [list $itk_component(histogram_c) itemconfigure graph_arrow_right -image ::img::graph_arrow_right_off]
    $itk_component(histogram_c) bind graph_arrow_right <ButtonPress-1> $right_link

    # Bind cnavas configuration to replot histograms
    bind $itk_component(histogram_c) <Configure> [code $this plotSpotMeasurementHistogram]
}

proc showValueLabel { a_label a_bg_colour a_fg_colour x y } {

    set t .value_label
    catch {destroy $t}
    toplevel $t
    wm overrideredirect $t 1
    if {[tk windowingsystem] == "aqua"} {
	::tk::unsupported::MacWindowStyle style $t floating noTitleBar
    }
    label $t.l \
	-text "$a_label"\
	-relief groove \
	-bd 1 \
	-bg $a_bg_colour \
	-fg $a_fg_colour \
	-padx 2 \
	-pady 2
    pack $t.l -fill both
    if {[expr $x + [winfo reqwidth $t.l]] > [winfo screenwidth $t.l]} {
	set x [expr [winfo screenwidth $t.l] - [winfo reqwidth $t.l] - 2]
    }
    if {[expr $y + [winfo reqheight $t.l]] > [winfo screenheight $t.l]} {
	set y [expr $y - 20 - [winfo reqheight $t.l] - 2]
    }
    moveValueLabel $x $y
}

proc moveValueLabel { x y } {
    catch {wm geometry .value_label "+[expr $x + 10]+[expr $y + 10]"}
}

proc hideValueLabel {  } {
    catch {destroy .value_label}
}

body Integrationwizard::fixDefaultParameters { } {
    $itk_component(postrefinement_tree) item state set $items_by_parameter(cell_a) CHECKED
    $itk_component(postrefinement_tree) item state set $items_by_parameter(cell_b) CHECKED
    $itk_component(postrefinement_tree) item state set $items_by_parameter(cell_c) CHECKED
    $itk_component(postrefinement_tree) item state set $items_by_parameter(cell_alpha) CHECKED
    $itk_component(postrefinement_tree) item state set $items_by_parameter(cell_beta) CHECKED
    $itk_component(postrefinement_tree) item state set $items_by_parameter(cell_gamma) CHECKED
}

body Integrationwizard::selectMTZforPointless { } {

    # Create image-file selection dialog, if not yet created.
    set selection_dir [pwd]
    if {![winfo exists .selectMTZ]} {
	Fileopen .selectMTZ \
	    -title "Select MTZ file" \
	    -type mtz_open \
	    -initialdir $selection_dir \
	    -filtertypes {{ "MTZ files" {.mtz .MTZ }} { "All Files" {.*}}}
    }
    # get a filename and location (as full path) from the user
    set l_mtz_file [.selectMTZ get]
    # If the user picked a file
    if {$l_mtz_file != ""} {
	runPointless
    }
}


body Integrationwizard::toggleAbility { a_state } {

    Processingwizard::toggleAbility $a_state
    $itk_component(quick_symm_tb) configure -state $a_state
    $itk_component(quick_scale_tb) configure -state $a_state
}


body Integrationwizard::resetCurrentBlock { } {
	set current_block "1"
}

usual Integrationwizard { }
