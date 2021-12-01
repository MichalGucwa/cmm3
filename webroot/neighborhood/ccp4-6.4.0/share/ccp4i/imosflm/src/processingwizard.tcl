# $Id: processingwizard.tcl,v 1.17 2012/05/21 13:23:39 ccb Exp $
package provide processingwizard 1.0

# Comment the following line to get Baubles web browser output from QuickSymm and QuickScale
package require qtrv

class Processingwizard {
    inherit itk::Widget
 
    # Layout sizes
    protected variable margin "7"
    protected variable row_height "182"    

    # common to keep track of instances
    common instance_count "0"

    protected variable processing_stage

    # pointer to results object
    protected variable results ""

    # Control variables
    protected variable processing_order "continue"
    protected variable continuation_command ""

    protected variable image_numbers {}

    # processing variables
    protected variable images_being_processed {}
    protected variable block_size ""
    protected variable pass1vars ; # N.B. Array - do initialize!
    protected variable pass2vars ; # N.B. Array - do initialize!

    # arrays associating tree items with parameters
    protected variable items_by_parameter ; # N.B. Array - do not initialize!
    protected variable parameters_by_item ; # N.B. Array - do not initialize!
    
    # fixing setting variable names
    protected variable fixes_by_parameter ; # Array

    # Images used to display profile
    protected variable profile_small ""
    protected variable profile_large ""

    protected variable current_profile ""

    # canvases for graphs
    protected variable canvases_by_content ; # array
    protected variable zoomed "0"

    # location for saving detector and crystal parameters
    protected variable savedDXparam ; # array

    # treectrl tooltip queue's item
    protected variable last_tooltip_item ""

    protected variable l_numbers {}
    protected variable l_image_numbers ()

    protected variable pointless_only "1"

    # wizard navigation methods
    public method launch
    public method hide
    public method resetControls
    public method clear
    public method updateImages

    public method disable
    public method enable
    protected method toggleAbility

    public method process
    public method saveScript
    public method submitBatch
    public method splitaBatch
    public method processBatch
    protected method getScript
    private method writeScript
    private method validateMatrices
    private method saveDetectorCrystalParams
    private method testDetectorCrystalParams
    private method resetDetectorCrystalParams
    public method loadResults
    public method copyResults
    public method complete

    # Control methods
    protected method updateProcessButton
    protected method abort
    protected method pause
    protected method continueProcessing

    # Auxiliary processing methods
    public method getImageList
    protected method newResults
    protected method defaultImageSelection
    protected method clearImageSelection


    # Feedback processing methods
    public method extractBlockSize
    public method updateProcessingStatus
    public method updateProcessingData
    public method updateProfileData
    public method finishedProcessing

    # Result display methods
    protected method initializeTreesAndGraphs
    protected method updateParameterTreesAndGraphs
    protected method refreshProfileTree
    protected method updateProfileTree

    protected method paramTreeClick
    protected method plotProcessingGraph

    protected method fixDefaultParameters { } { } ; # virtual

    public method updateProfileSelection
    public method displayProfile

    # zooming methods
    protected method toggleZoom
    protected method restoreGrid
    protected method zoom

    # Tooltips for treectrls
    public method treectrlMotion
    public method treectrlLeave

    public method extractIsolatedImages
    public method runPointless
    public method runScaling
    public method getRefinementTree
    public method getPostrefinementTree
    public method getItemsByParameter

    constructor { args } { }
}

body Processingwizard::constructor { args } {
    # Build megawidget

    # Toolbars ###############################################

    itk_component add toolbar {
	frame [.c component toolbar_frame].processing[incr instance_count]
    }

    # Divider

    itk_component add divider1 {
	frame $itk_component(toolbar).div1 \
	    -width 2 \
	    -relief sunken \
	    -bd 1
    }

    itk_component add view_predictions_tb {
	SettingToolbutton $itk_component(toolbar).vptb "view_predictions_during_processing" \
	    -image ::img::view_predictions16x16 \
	    -activeimage ::img::view_predictions_on16x16 \
	    -balloonhelp "Show predictions on images during processing"
    }

    # Normal frame
    itk_component add normal_f {
	frame $itk_interior.normal
    }

    # Heading

    itk_component add heading_f {
	frame $itk_interior.normal.hf \
	    -bd 1 \
	    -relief solid
    }

    itk_component add heading_l {
	label $itk_interior.normal.hf.fl \
	    -text "" \
	    -font title_font
    } {
	usual
	ignore -font
    }

    # Image selection frame
    itk_component add image_selection_f {
	frame $itk_interior.normal.isf \
	    -bd 2 \
	    -relief raised
    } {
	usual
	keep -borderwidth
    }

    # images entry
    itk_component add images_label {
	label $itk_interior.normal.isf.il \
	    -text "Images: "
    }

    itk_component add image_numbers_frame {
	frame $itk_interior.normal.isf.inf 
    }

    itk_component add default_selection_tb {
	Toolbutton $itk_interior.normal.isf.dstb \
	    -image ::img::auto_image_selection24x24 \
	    -disabledimage ::img::auto_image_selection_disabled24x24 \
	    -type "amodal" \
	    -state "normal" \
	    -balloonhelp " Automatically select images " \
	    -command [code $this defaultImageSelection]
    }

    itk_component add clear_selection_tb {
	Toolbutton $itk_interior.normal.isf.cstb \
	    -image ::img::clear_image_selection24x24 \
	    -disabledimage ::img::clear_image_selection_disabled24x24 \
	    -type "amodal" \
	    -state "normal" \
	    -balloonhelp " Clear image selection " \
	    -command [code $this clearImageSelection]
    }

    itk_component add image_palette_tb {
	Toolbutton $itk_interior.normal.isf.iptb \
	    -image ::img::many_images24x24 \
	    -disabledimage ::img::many_images_disabled24x24 \
	    -type "modal" \
	    -state "normal" \
	    -balloonhelp " Select images... "
    }

    itk_component add image_palette {
	ImagePalette .ip\#auto $itk_component(hull) \
	    -alignwidget $itk_component(images_label)
    } { }

    $itk_component(image_palette_tb) configure \
 	-command [list $itk_component(image_palette) launch $itk_component(image_palette_tb)]	    

    itk_component add cancel {
	button $itk_interior.normal.isf.cancel \
	    -text "Abort" \
	    -width 7 \
	    -pady 2 \
	    -state "disabled" \
	    -command [code $this abort]
    }

    itk_component add process {
	ExpandButton $itk_interior.normal.isf.process \
	    -text "Process" \
	    -width 7 \
	    -pady 2 \
	    -command {} ; # To be configured on demand
    }

    $itk_component(process) add "Batch" [code $this submitBatch]
    #$itk_component(process) add "Split" [code $this splitaBatch]

    # Results frame
    itk_component add results_f {
	frame $itk_interior.normal.rf \
	    -bd 2 \
	    -relief raised
    } {
	usual
	keep -borderwidth
    }
    
    foreach i_param_class { refinement postrefinement } {
	# Variables trees
	itk_component add ${i_param_class}_tree {
	    treectrl $itk_interior.normal.rf.${i_param_class}_tree \
		-showroot 0 \
		-showline 0 \
		-showbutton 0 \
		-selectmode multiple \
		-width 284 \
		-height $row_height \
		-itemheight 15 \
		-highlightthickness 0 \
		-font font_s
	} {
	    rename -background -textbackground textBackground Background
	    #rename -font -entryfont entryFont Font
	}
	$itk_component(${i_param_class}_tree) column create -text "Parameter" -justify left -minwidth 180 -expand 1
	$itk_component(${i_param_class}_tree) column create -text "Value" -justify right -minwidth 60 -expand 1 -tag value
	$itk_component(${i_param_class}_tree) column create -text "Fix" -justify center -minwidth 30 -expand 1 -tag plot
	$itk_component(${i_param_class}_tree) state define ENABLED
	$itk_component(${i_param_class}_tree) state define CHECKED
	$itk_component(${i_param_class}_tree) element create e_text text -fill {white selected}
	$itk_component(${i_param_class}_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
	$itk_component(${i_param_class}_tree) element create e_check image -image { ::img::embed_check_on {ENABLED CHECKED} ::img::embed_check_off {ENABLED !CHECKED} ::img::embed_check_on_disabled {!ENABLED CHECKED} ::img::embed_check_off_disabled {!ENABLED !CHECKED} }
	$itk_component(${i_param_class}_tree) style create s1
	$itk_component(${i_param_class}_tree) style elements s1 { e_highlight e_text }
	$itk_component(${i_param_class}_tree) style layout s1 e_text -expand ns
	$itk_component(${i_param_class}_tree) style layout s1 e_highlight -union [list e_text] -iexpand nsew -ipadx 2
	$itk_component(${i_param_class}_tree) style create s2
	$itk_component(${i_param_class}_tree) style elements s2 {e_highlight e_check}
	$itk_component(${i_param_class}_tree) style layout s2 e_highlight -union [list e_check] -iexpand nsew -ipadx 2
	$itk_component(${i_param_class}_tree) style layout s2 e_check -expand ns -padx {2 2}
	$itk_component(${i_param_class}_tree) style create s3
	$itk_component(${i_param_class}_tree) style elements s3 {e_highlight}
	$itk_component(${i_param_class}_tree) style layout s3 e_highlight -iexpand nsew -ipadx 2

	bind $itk_component(${i_param_class}_tree) <ButtonPress-1> [code $this paramTreeClick $i_param_class %W %x %y]
	bind $itk_component(${i_param_class}_tree) <Motion> [code $this treectrlMotion $i_param_class %W %x %y]
	bind $itk_component(${i_param_class}_tree) <Leave> [code $this treectrlLeave]
	bind $itk_component(${i_param_class}_tree) <ButtonPress-1> [code $this paramTreeClick $i_param_class %W %x %y]
	$itk_component(${i_param_class}_tree) notify bind $itk_component(${i_param_class}_tree) <Selection> [code $this plotProcessingGraph $i_param_class]
	
	# Canvas
	itk_component add ${i_param_class}_canvas {
	    canvas $itk_interior.normal.rf.${i_param_class}_canvas \
		-relief sunken \
		-borderwidth 2 \
		-width 284 \
		-height $row_height \
		-highlightthickness 0
	} {
	    rename -background -textbackground textBackground Background
	}

	# store canvas in param class's graph canvas list
	set canvases_by_content($i_param_class) $itk_component(${i_param_class}_canvas)
	bind $itk_component(${i_param_class}_canvas) <4> [code $this zoom %W]
	bind $itk_component(${i_param_class}_canvas) <5> [code $this restoreGrid]
	bind $itk_component(${i_param_class}_canvas) <Control-ButtonPress-1> [code $this toggleZoom %W]
	bind $itk_component(${i_param_class}_canvas) <Shift-ButtonPress-1> [code $this toggleZoom %W]

	bind $itk_component(${i_param_class}_canvas) <Configure> [code $this plotProcessingGraph $i_param_class]
    }

    itk_component add profile_f {
	frame $itk_interior.normal.rf.pf
    }

    itk_component add profile_tree {
	treectrl $itk_interior.normal.rf.pf.lb \
	    -showbuttons 0 \
	    -showlines 0\
	    -showroot 0 \
	    -width 50 \
	    -height $row_height \
	    -highlightthickness 0 \
	    -font font_s
    } {
	rename -background -textbackground textBackground Background
	#rename -font -entryfont entryFont Font
    }

    $itk_component(profile_tree) column create -text Image -justify right -expand 1
    $itk_component(profile_tree) state define AVAILABLE
    $itk_component(profile_tree) element create e_text text -fill {white {selected AVAILABLE} lightgrey {!AVAILABLE}}
    $itk_component(profile_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
    $itk_component(profile_tree) style create s1
    $itk_component(profile_tree) style elements s1 {e_highlight e_text}
    $itk_component(profile_tree) style layout s1 e_text -expand ns
    $itk_component(profile_tree) style layout s1 e_highlight -union [list e_text] -iexpand nsew -ipadx 2

    $itk_component(profile_tree) notify bind $itk_component(profile_tree) <Selection> [code $this updateProfileSelection %S]

    itk_component add profile_sb {
	scrollbar $itk_interior.normal.rf.pf.sb \
	    -command [code $this component profile_tree yview] \
	    -orient vertical
    }

    $itk_component(profile_tree) configure \
	-yscrollcommand [list autoscroll $itk_component(profile_sb)]

    itk_component add profile_c {
	canvas $itk_interior.normal.rf.pf.c \
	    -background white \
	    -relief sunken \
	    -borderwidth 2 \
	    -height $row_height \
	    -highlightthickness 0
    }
    # store canvas in param class's graph canvas list
    set canvases_by_content(profile) $itk_component(profile_c)
    # Setup bindings to refresh profile when canvas changes
    bind $itk_component(profile_c) <Configure> [code $this displayProfile]
    bind $itk_component(profile_c) <4> [code $this zoom $itk_component(profile_f)]
    bind $itk_component(profile_c) <5> [code $this restoreGrid]
    bind $itk_component(profile_c) <Control-1> [code $this toggleZoom $itk_component(profile_f)]
    bind $itk_component(profile_c) <Shift-1> [code $this toggleZoom $itk_component(profile_f)]

    # Add alternative frame
    itk_component add alt_f {
	frame $itk_interior.alt
    }

    # Add alt canvas
    itk_component add alt_c {
	canvas $itk_interior.alt.c \
	    -bg white \
	    -relief sunken \
	    -borderwidth 2 \
	    -highlightthickness 0
    }
    bind $itk_component(alt_c) <1> [code $this dropCanvas]

    # Toolbar
    pack $itk_component(divider1) \
	-side left \
	-fill y \
	-padx 5 \
	-pady 1
    pack $itk_component(view_predictions_tb) \
	-side left \
	-padx 2

    # Layout

    # Normal frame
    pack $itk_component(normal_f) -side top -fill both -expand 1

    # Heading
    pack $itk_component(heading_f) -side top -fill x -padx 7 -pady {7 0}
    pack $itk_component(heading_l) -side left -padx 5 -pady 5

    # Image selection
    pack $itk_component(image_selection_f) -side top -fill x
    pack $itk_component(images_label) -side left -padx [list $margin 0] -anchor n -pady 10 
    pack $itk_component(image_numbers_frame) -side left -fill x -expand 1 -anchor n -pady 6
    pack $itk_component(default_selection_tb) -side left
    pack $itk_component(clear_selection_tb) -side left
    pack $itk_component(image_palette_tb) -side left
    pack $itk_component(process) -side right -pady $margin -padx $margin
    pack $itk_component(cancel) -side right -pady $margin -padx [list $margin 0]

    # Results frame
    pack $itk_component(results_f) -side top -fill both -expand 1

    grid x $itk_component(refinement_tree) x  $itk_component(refinement_canvas) x $itk_component(profile_f) x -sticky nsew -pady [list $margin 0]
    grid x $itk_component(postrefinement_tree) x $itk_component(postrefinement_canvas) x -sticky nsew -pady $margin
    grid columnconfigure $itk_component(results_f) { 0 2 4 6 } -minsize $margin
    grid columnconfigure $itk_component(results_f) { 3 5 } -weight 1
    grid rowconfigure $itk_component(results_f) { 0 1 } -weight 1

    # Profile frame
    grid $itk_component(profile_tree) $itk_component(profile_sb) $itk_component(profile_c) -sticky nswe
    grid columnconfigure $itk_component(profile_f) 2 -weight 1
    grid rowconfigure $itk_component(profile_f) 0 -weight 1
    


    # Alternative frame contents
    pack $itk_component(alt_c) -side top -fill both -expand 1 -padx $margin -pady $margin 

    # Setup information for tables and graphs
    
    # Create temporary results object to create tree items from
    set t_results [newResults]

    foreach i_param_class { refinement postrefinement } {
	foreach i_param [Processingresults::getParameters $i_param_class] {
	    # create a new item
	    set t_param_item [$itk_component(${i_param_class}_tree) item create]
	    # set the items state as enabled
	    $itk_component(${i_param_class}_tree) item state set $t_param_item ENABLED
	    # set the item's style
	    $itk_component(${i_param_class}_tree) item style set $t_param_item 0 s1 1 s1
	    if {[Processingresults::parameterIsFixable $i_param]} {
		$itk_component(${i_param_class}_tree) item style set $t_param_item 2 s2
		set fixable_parameters_by_item($i_param_class,$t_param_item) $i_param
	    } else {
		$itk_component(${i_param_class}_tree) item style set $t_param_item 2 s1
	    }
	    
	    # update the item's text
	    if { $i_param == "beam_y_corrected" } {
		$itk_component(${i_param_class}_tree) item text $t_param_item 0 "" 1 "" 
	    } {
		$itk_component(${i_param_class}_tree) item text $t_param_item 0 [$t_results getParameterName $i_param] 1 "" 
	    }
	    # add the new item to the tree
	    $itk_component(${i_param_class}_tree) item lastchild root $t_param_item
	    
	    # Store pointer to image objects and items by bumber, item or object
	    set items_by_parameter($i_param) $t_param_item
	    set parameters_by_item($i_param_class,$t_param_item) $i_param
	    #puts $i_param
	}
    }
    # delete temporary results object
    delete object $t_results
    
    # Make default graphing selection
    $itk_component(refinement_tree) selection add $items_by_parameter(beam_x) $items_by_parameter(beam_y)
    
    $itk_component(postrefinement_tree) selection add $items_by_parameter(phi_x) $items_by_parameter(phi_z)
    $itk_component(postrefinement_tree) selection add $items_by_parameter(mosaicity)

    # Fix default parameters
    fixDefaultParameters

    eval itk_initialize $args
}

# Image tree interaction methods

body Processingwizard::updateProcessButton { } {
    set l_check_count 0
    foreach i_sector [$itk_component(image_tree) item children root] {
	foreach i_image [$itk_component(image_tree) item children $i_sector] {
	    if {[$itk_component(image_tree) item state get $i_image CHECKED]} {
		incr l_check_count
	    }
	}
    }
    if {$l_check_count > 0} {
	$itk_component(process) configure -state "normal"
    } else {
	$itk_component(process) configure -state "disabled"
    }
}


# Wizard navigation methods ######################################

body Processingwizard::launch { } {

    #puts "PWlaunch: [$::session getCurrentSector] [[$::session getCurrentSector] getImages]"

    # Make default image selection whatever in case numbers left in field are not appropriate?
    if {[$itk_component(image_numbers) getContent] == {}} {
	defaultImageSelection
    }

    # Show stage
    grid $itk_component(hull) -row 0 -column 1 -sticky nswe

    # show toolbars
    pack $itk_component(toolbar) -in [.c component toolbar_frame] -side left

    # Trap for no Mosaicity set
    if { [$::session forceMosaicityEstimation] } {
	# It has worked - user sees .me launched
    } else {
	# It has failed
	.m confirm \
	    -title "Mosaicity not set" \
	    -type "1button" \
	    -button1of1 "Ok" \
	    -text "The mosaicity cannot be estimated.\nPlease return to an earlier stage of processing."
    }
    # Reset unzoomed view
    restoreGrid
}

body Processingwizard::hide { } {
    # Hide the wizard
    grid forget $itk_component(hull)
    # Hide the toolbar
    pack forget $itk_component(toolbar) 
}

body Processingwizard::resetControls { } {
    # Reset processing button
    $itk_component(process) configure \
	-text "Process" \
	-command [code $this process]	
    # Reset cancel button
    $itk_component(cancel) configure -state "disabled"
}

body Processingwizard::clear { } {
    # Clear image number widget
    $itk_component(image_numbers) clear
    foreach i_param_class { refinement postrefinement } {
	# Clear parameter values
	foreach i_item [$itk_component(${i_param_class}_tree) item children root] {
	    $itk_component(${i_param_class}_tree) item text $i_item 1 ""
	}
	# Clear graphs
	$itk_component(${i_param_class}_canvas) delete all
	bind $itk_component(${i_param_class}_canvas) <Configure> {}
    }
    # Clear profile trees
    $itk_component(profile_tree) item delete all
    $itk_component(profile_c) delete all
    bind $itk_component(profile_c) <Configure> {}
}

body Processingwizard::updateImages { an_image_list args } {

    # Build an array of lists of image numbers by template
    
    foreach i_sector [$::session getSectors] {
	set l_image_numbers_by_template([$i_sector getTemplate]) {}
    }
    foreach i_image $an_image_list {
	if { ![catch "$i_image getTemplate" message ]} {
	    #puts $message
	    lappend l_image_numbers_by_template([$i_image getTemplate]) [$i_image getNumber]
	} 
	#puts [scope $i_image]
    }
    # update the image numbers widget 
    # this needs to be done this way because of the way arrays are stored.

    set current_sector [$::session getCurrentSector]
    #puts "111 $current_sector"
    foreach i_sector [$::session getSectors] {
	set i_template [$i_sector getTemplate]
	#puts $i_template
	set l_image_numbers [compressNumList $l_image_numbers_by_template($i_template)]
	#puts $l_image_numbers
	if { $l_image_numbers != {} } {
	    $itk_component(image_numbers) updateSector $i_template $l_image_numbers
	}
    }

    # then set current working sector if integrating, not if refinement
    set i_template [$current_sector getTemplate]
    #puts "HERE IS THE TEMPLATE $i_template"
    set l_input_numbers {}
    set l_input_numbers $l_numbers 
    #puts "here we go $l_input_numbers"
    set l_input_numbers [compressNumList $l_input_numbers]
    set l_image_numbers {}
    set l_image_numbers [compressNumList $l_image_numbers_by_template($i_template)]

    if {$l_input_numbers != {} && [$::session getParameterValue "wait_activation"]} {
	#puts "WAIT IS ACTIVE"
	if {$l_image_numbers != {}} {
	    set l_image_numbers $l_input_numbers
	}	
    }
    $itk_component(image_numbers) updateSector $i_template $l_image_numbers

    #puts "222 $current_sector"
    if { $current_sector != "" && $l_image_numbers == {} } {
	set l_image_numbers {}
	foreach i_image [$current_sector getImages] {
	    lappend l_image_numbers [$i_image getNumber]
	}
	if { $l_image_numbers != {} } {
	    $itk_component(process) configure -state normal 
	    set l_image_numbers [compressNumList $l_image_numbers]
	}
	$itk_component(image_numbers) updateSector $i_template $l_image_numbers
    }

    # Enable / disable controls appropriately
    if {$an_image_list != {}} {
	if {![regexp "pause" "[$itk_component(process) cget -command]"] && ![regexp "continue" "[$itk_component(process) cget -command]"] } {
	    #puts "I DID IT"
	    # Enable processing button
	    $itk_component(process) configure \
	    	-state normal \
	    	-command [code $this process]
	}	
    } else {
	$itk_component(process) configure -state disabled
    }

    #puts [$itk_component(process) cget -command]

    #puts $l_image_numbers
}

body Processingwizard::clearImageSelection { } {
    set current_sector [$::session getCurrentSector]
    # clear all the rest first
    foreach i_sector [$::session getSectors] {
	if { $i_sector != [$::session getCurrentSector] } {
	    set i_template [$i_sector getTemplate]
	    $itk_component(image_numbers) updateSector $i_template {}
	}
    }
    # then set current working sector specifically
    $::session setCurrentSector $current_sector
    set i_template [$current_sector getTemplate]
    $itk_component(image_numbers) updateSector $i_template {}
    $itk_component(process) configure -state "disabled"
}

body Processingwizard::disable { } {
    toggleAbility "disabled"
}

body Processingwizard::enable { } {
    toggleAbility "normal"
}

body Processingwizard::toggleAbility { a_state } {
    $itk_component(image_numbers) configure -state $a_state
    $itk_component(default_selection_tb) configure -state $a_state
    $itk_component(clear_selection_tb) configure -state $a_state
    $itk_component(image_palette_tb) configure -state $a_state
    $itk_component(process) configure -state $a_state
}

body Processingwizard::saveDetectorCrystalParams { } {
    
    # Lists for saving & resetting if refined to physically unreasonable values

    #Beam X,Y, Detector distance, twist & tilt, Yscale
    #Detector two-theta (not currently refined, but may be in future)
    #Separation parameters (this can also be corrupted)
    #Raster (measurement box) parameters (ditto)
    #Mosaic spread
    set param_list { beam_x beam_y beam_y_corrected distance yscale tilt twist tangential_offset radial_offset two_theta spot_separation_x spot_separation_y raster_nxs raster_nys raster_nc raster_nrx raster_nry mosaicity }
    foreach i_param $param_list {
	# Try to get the parameter value from the session
	if {![catch {set param [$::session getParameterValue $i_param]}]} {
	    #puts "$i_param $param"
	    set savedDXparam($i_param) $param
	} else {
	    puts "no value for $i_param"
	}
    }

    #Unit cell parameters (in case this was a cell refinement run)
    set i 0
    set cell_list [$::session listCell]
    foreach i_param { cell_a cell_b cell_c cell_alpha cell_beta cell_gamma } {
	set param [lindex $cell_list $i]
	if { $param != "" } {
	    #puts "$i_param $param"
	    set savedDXparam($i_param) $param
	} else {
	    puts "no value for $i_param"
	}
	incr i
    }

    #Missets (just the current PHIX, PHIY, PHIZ)
    # Find the first image
    set l_image_field_contents [lindex [.c component $processing_stage component image_numbers getContent] 0]
    #puts "l_image_field_contents $l_image_field_contents"
    if { $l_image_field_contents != "" } {
	set local_template [lindex $l_image_field_contents 0]
	set l_local_image_numbers [lindex $l_image_field_contents 1]
	set local_first_image_number [lindex $l_local_image_numbers 0]
	set local_first_image [$::session getImageByTemplateAndNumber $local_template $local_first_image_number]
	set i 0
	set misset_list [$local_first_image getMissets]
	foreach i_param { phi_x phi_y phi_z } {
	    set param [lindex $misset_list $i]
	    if { $param != "" } {
		#puts "$i_param $param"
		set savedDXparam($i_param) $param
	    } else {
		puts "no value for $i_param"
	    }
	}
    }
}

body Processingwizard::testDetectorCrystalParams { } {

    # 1. Detector tilt and twist. Absolute magnitude greater than 0.5 degrees gives
    # initial warning, absolute magnitude greater than 0.8 gives serious warning.

    set caution_limit 0.5
    set serious_limit 0.8
    set units degrees

    set param_list { tilt twist }
    foreach i_param $param_list {
	set response_[set i_param] ""
	# Try to get the parameter value from the session
	if {![catch {set param [$::session getParameterValue $i_param]}]} {
	    if { [expr {abs($param - $savedDXparam($i_param))}] > $caution_limit } {
		set response caution
		if { [expr {abs($param - $savedDXparam($i_param))}] > $serious_limit } {
		    set response serious
		}
		set response_[set i_param] "$i_param now $param was $savedDXparam($i_param) and exceeds $response limit of [set [set response]_limit] $units\n"
	    }
	    #puts "$i_param now $param was $savedDXparam($i_param)"
	} else {
	    #puts "no value for $i_param in session"
	}
    }

    #1a. Radial_offset & tangential_offset. Cautionary should be absolute value greater than 0.3, critical
    # absolute value greater than 0.6.

    set caution_limit 0.3
    set serious_limit 0.6
    set units mm

    set param_list { tangential_offset radial_offset }
    foreach i_param $param_list {
	set response_[set i_param] ""
	# Try to get the parameter value from the session
	if {![catch {set param [$::session getParameterValue $i_param]}]} {
	    if { [expr {abs($param - $savedDXparam($i_param))}] > $caution_limit } {
		set response caution
		if { [expr {abs($param - $savedDXparam($i_param))}] > $serious_limit } {
		    set response serious
		}
		set response_[set i_param] "$i_param now $param was $savedDXparam($i_param) and exceeds $response limit of [set [set response]_limit] $units\n"
	    }
	    #puts "$i_param now $param was $savedDXparam($i_param)"
	} else {
	    #puts "no value for $i_param in session"
	}
    }

    #2. Yscale. Deviation great than 1.0 by more 0.005 gives initial warning, by
    #more than 0.01 gives serious warning.

    set caution_limit 0.005
    set serious_limit 0.01
    set units ""

    # Try to get the parameter value from the session
    set i_param yscale
    set response_[set i_param] ""
    if {![catch {set param [$::session getParameterValue $i_param]}]} {
	if { [expr {abs($param - $savedDXparam($i_param))}] > $caution_limit } {
	    set response caution
	    if { [expr {abs($param - $savedDXparam($i_param))}] > $serious_limit } {
		set response serious
	    }
	    set response_[set i_param] "$i_param now $param was $savedDXparam($i_param) and exceeds $response limit of [set [set response]_limit] $units\n"
	}
	#puts "$i_param now $param was $savedDXparam($i_param)"
    } else {
	#puts "no value for $i_param in session"
    }

    # 3. Distance. Deviation from initial value greater than 2mm gives initial
    # warning, greater than 5mm gives serious warning.

    set caution_limit 2
    set serious_limit 5
    set units mm

    # Try to get the parameter value from the session
    set i_param distance
    set response_[set i_param] ""
    if {![catch {set param [$::session getParameterValue $i_param]}]} {
	if { [expr {abs($param - $savedDXparam($i_param))}] > $caution_limit } {
	    set response caution
	    if { [expr {abs($param - $savedDXparam($i_param))}] > $serious_limit } {
		set response serious
	    }
	    set response_[set i_param] "$i_param now $param was $savedDXparam($i_param) and exceeds $response limit of [set [set response]_limit] $units\n"
	}
	#puts "$i_param now $param was $savedDXparam($i_param)"
    } else {
	#puts "no value for $i_param in session"
    }

    # All three parameters should be checked and the warning level set to the highest of the three.
    return [list $response_tilt $response_twist $response_yscale $response_distance]
}

body Processingwizard::resetDetectorCrystalParams { } {
    
    # Lists for saving & resetting if refined to physically unreasonable values

    #Beam X,Y, Detector distance, twist & tilt, Yscale
    #Detector two-theta (not currently refined, but may be in future)
    #Separation parameters (this can also be corrupted)
    #Raster (measurement box) parameters (ditto)
    #Mosaic spread
    set param_list { beam_x beam_y beam_y_corrected distance yscale tilt twist tangential_offset radial_offset two_theta spot_separation_x spot_separation_y raster_nxs raster_nys raster_nc raster_nrx raster_nry mosaicity }
    foreach i_param $param_list {
	# Reset the parameter value for the session
	if {[info exists savedDXparam($i_param)]} {
	   #puts "$i_param reset from [$::session getParameterValue $i_param] to $savedDXparam($i_param)"
	    $::session updateSetting $i_param $savedDXparam($i_param)
	} else {
	   #puts "no value stored for $i_param"
	}
    }

    #Unit cell parameters (in case this was a cell refinement run)
    set i 0
    set reset 0
    set cell_list {}
    foreach i_param { cell_a cell_b cell_c cell_alpha cell_beta cell_gamma } {
	if {[info exists savedDXparam($i_param)]} {
	    lappend cell_list $savedDXparam($i_param)
	    incr reset
	} else {
	   #puts "no value stored for $i_param"
	}
	incr i
    }
    # Check all cell parameters could be reset to stored values
    if { $reset == 6 } {
	set cell [$::session getCell]
	#puts "Old cell [$::session listCell]\nNew cell $cell_list"
	eval $cell setCell $cell_list
    }

    #Missets (just the current PHIX, PHIY, PHIZ)
    # Find the first image
    set l_image_field_contents [lindex [.c component $processing_stage component image_numbers getContent] 0]	
    #puts "l_image_field_contents $l_image_field_contents"
    set local_template [lindex $l_image_field_contents 0]
    set l_local_image_numbers [lindex $l_image_field_contents 1]

    foreach i_param { phi_x phi_y phi_z } {
	set [set i_param] 0
	if {[info exists savedDXparam($i_param)]} {
	    set [set i_param] $savedDXparam($i_param)
        } else {
	   #puts "no value stored for $i_param"
        }
    }

    foreach imageno $l_local_image_numbers {
	set l_image [$::session getImageByTemplateAndNumber $local_template $imageno]
	if {[$l_image hasMissets]} {
	    #puts "Image $imageno has missets [$l_image getMissets]"
	    $l_image updateMissets $phi_x $phi_y $phi_z 1 1 "Processing"
	    #puts "      now reset to missets [$l_image getMissets]"
	}
    }

}

# Processing methods #############################################

body Processingwizard::process { args } {

    #puts "Start: [clock format [clock seconds] -format "%H:%M:%S"] $processing_stage"

    # If no matrix for this sector disable processing stages
    if { ![[[$::session getCurrentSector] getMatrix] isValid] } {
	.m confirm \
	    -title "No valid matrix exists" \
	    -type "1button" \
	    -button1of1 "Ok" \
	    -text "No matrix for sector [[$::session getCurrentSector] getTemplate]\nCannot perform $processing_stage operation."
	#puts "No valid matrix for sector [[$::session getCurrentSector] getTemplate] - aborting $processing_stage"
	return
    }

    # Check list of images to be processed
    #puts "l_image_list at start of Process [getImageList]"

    # Save copies of detector & crystal parameters
    saveDetectorCrystalParams
    
    if {$processing_stage == "integration"} {
	$::session setIntegrationRun "0"
	$::session initialisePMon
	if {[$::session getParameterValue "wait_activation"]} {
	    set l_image_field_contents [lindex [.c component integration component image_numbers getContent] 0]	
	    set local_template [lindex $l_image_field_contents 0]
	    set l_local_image_numbers [lindex $l_image_field_contents 1]

	    set local_first_image_number [lindex $l_local_image_numbers 0]
	    set local_first_image [$::session getImageByTemplateAndNumber $local_template $local_first_image_number]
	    set local_image_directory [$local_first_image getDirectory]
	    set local_gain [$::session getParameterValue gain]

	    #puts "THE DIRECTORY is $local_image_directory"

	    foreach i_local_image_number $l_local_image_numbers {
		set i_local_image [$::session getImageByTemplateAndNumber $local_template $i_local_image_number]
		if {$i_local_image != ""} {
		    set i_local_phis [$i_local_image getPhi]
		    set i_local_phi_start [lindex $i_local_phis 0]
		    set i_local_phi_end [lindex $i_local_phis 1]					
		    #puts [$::session getImageByTemplateAndNumber $local_template $i_local_image_number]
		    #puts "image $i_local_image_number exists"
		} else {
		    set i_local_phi_slice [expr {$i_local_phi_end - $i_local_phi_start}]
		    set i_local_phi_start $i_local_phi_end
		    set i_local_phi_end [expr {$i_local_phi_start + $i_local_phi_slice}]
		    set i_local_filename [::filenameFromTemplate $local_template $i_local_image_number]
		    set i_local_full_path [file join $local_image_directory $i_local_filename]
		    set wait_xml "<?xml version='1.0'?><!DOCTYPE brief_header_response><brief_header_response><status><code>ok</code></status><image_filename>$i_local_full_path</image_filename><phi_start>      [format %.2f $i_local_phi_start]</phi_start><phi_end>      [format %.2f $i_local_phi_end]</phi_end><gain>   $local_gain</gain></brief_header_response>"
		    set wait_dom [dom parse $wait_xml]
		    $::session processWaitBriefHeaderData $wait_dom
		}
	    }
	}
	$itk_component(mtz_file_e) publicUploadToSessionIfChanged
	
	# Check against overwriting previous MTZ file
	set l_mtz_file [$::session getParameterValue mtz_file]
	if { ![$::session getParameterValue mtz_overwrite] && [file exists $l_mtz_file] } {
	    .m configure \
		-type "2button" \
		-title "File already exists" \
		-text "File $l_mtz_file exists.\nDo you want to overwrite it?" \
		-button1of2 "Yes" \
		-button2of2 "No"
    
	    if {![.m confirm]} {
		# Get new file name from user
		if {![winfo exists .chooseAuxFile]} {
		    Fileopen .chooseAuxFile \
			-type save \
			-title "Save MTZ file as" \
			-initialdir [pwd] \
			-filtertypes {{"MTZ files" {.mtz}}}
		}
		set l_mtz_file [.chooseAuxFile get]
		if { $l_mtz_file != "" } {
		    $itk_component(mtz_file_e) update [file tail $l_mtz_file]
		    $::session updateSetting "mtz_file" [file tail $l_mtz_file] 1 1
		} else {
		    # Empty MTZ filename got
		    return
		}
	    } else {
		$::session updateSetting mtz_overwrite 1 0 0 "Processing options"
	    }
	}
    }

    # Get list of images to be processed
    set l_image_list [getImageList]
    
    if {$l_image_list != {}} {

	if {$processing_stage == "cell_refinement"} {
	    set isolist {}
	    set i_template [[lindex $l_image_list 0] getTemplate]
	    # Get the number & list of any isolated images followed by the list of non-isolated images
	    set fullresult [extractIsolatedImages $l_image_list $i_template]
	    # fullresult contains n_isol isolist l_image_list
	    set n_isol [lindex $fullresult 0]
	    if { $n_isol > 0 } {
		set isolist [lrange $fullresult 1 $n_isol]
		set l_image_list [lrange $fullresult [expr $n_isol + 1] end]
		.m confirm \
		    -title "Isolated images detected" \
		    -type "1button" \
		    -button1of1 "Ok" \
		    -text "Images $isolist\nwill not be used in cell refinement.\nIf these numbers were not entered by you\nplease inform the iMosflm developers."
		#puts "$n_isol isolated images found: $isolist"
	    } else {
		# if no isolated images found then no list, not even an empty item, is returned as second item
		set l_image_list [lrange $fullresult 1 end]	
	    }
	    if { [llength $l_image_list] == 0 } {
		# dont have any images left after removal of isolated images
		return
	    }
	}

	# Make sure matrices are present, or if not use first matrix
	validateMatrices $l_image_list

	# Disable fixing checkbuttons
	foreach i_param_class { refinement postrefinement } {
	    foreach i_param [Processingresults::getParameters $i_param_class] {
		if {[Processingresults::parameterIsFixable $i_param]} {
		    $itk_component(${i_param_class}_tree) item state set $items_by_parameter($i_param) !ENABLED
		}
	    }
	}

	# Reset the processing command to continue by default
	set processing_order "continue"

	# create results object (auto initialized)
	if {$results != ""} {
            #puts "Processingwizard::process deleting object $results"
	    delete object $results
	    set results ""
	}
	set results [eval newResults $l_image_list]
	#puts "Processingwizard::process results object created $results"

	# initialize trees and graphs
	initializeTreesAndGraphs

	# Disable ALL controls
	.c disable

	# disable controls button
	#disable

	# Reconfigure process button as pause button
	$itk_component(process) configure \
	    -state "semi" \
	    -text "Pause" \
	    -command [code $this pause]

	# Enable cancel button
	$itk_component(cancel) configure -state "normal"

	# send mosflm command
	if {$processing_stage == "integration"} {
	# Update status
	    .c busy "Integrating"
	    eval $::mosflm integrate [list $l_image_list] $l_image_numbers
	} else {
	# Update status
	    .c busy "Refining cell"
	    eval $::mosflm refineCell $l_image_list
	}
	# Update the progress bar
	.c progress 0
    }
}

body Processingwizard::extractIsolatedImages { in_list template } {

    set isolist {}
    set num_ok {}
    set numlist {}
    set out_list {}
    # loop through list of images, build list of numbers
    foreach image $in_list {
	lappend numlist [$image getNumber]
    }
    # loop through list of numbers looking for neighbours
    foreach num $numlist {
	set oneless [expr $num - 1]
	set onemore [expr $num + 1]
	if { ([lsearch $numlist $onemore] >= 0) || ([lsearch $numlist $oneless] >= 0) } {
	    lappend num_ok $num
	} else {
	    lappend isolist $num
	}
    }
    # get image names from the numbers
    foreach num $num_ok {
	lappend out_list [$::session getImageByTemplateAndNumber $template $num]
    }
    return [concat [llength $isolist] $isolist $out_list]
}

body Processingwizard::runPointless {pointless_only_bool anomalous_bool} {

    # set CBIN to match Environment variable window
    if {[$::session getParameterValue ccp4_bin] != ""} {
	set ::env(CBIN) [file normalize [$::session getParameterValue ccp4_bin]]
    } {
	if { [info exists ::env(CBIN)] } {
	    $::session updateSetting ccp4_bin $::env(CBIN) 0 0 "Processing_options"
	}
    }

    #puts "CBIN set to $::env(CBIN)"
    set scaling_prog aimless
    if {[.ats component advanced_integration getUseScalaBool] == 1} { set scaling_prog scala }
    if { $pointless_only_bool == 1} {
	set proglist { pointless }
    } else {
	set proglist { pointless $scaling_prog ctruncate }
    }
    foreach prog $proglist {
	if { [catch "exec $prog" message ]} {
	    if { [regexp "couldn't execute" $message]} {
		.m confirm \
		    -type "1button" \
		    -title "Cannot execute" \
		    -button1of1 "Dismiss" \
		    -text "Could not execute the program [subst $prog]\nMake sure that the [subst $prog] binary is in your path"
		return
	    }
	}
    }

    if { [regexp -nocase windows $::tcl_platform(os)] } {
	set baubles_windows_path [file join $::env(CCP4) share smartie baubles.py]
	if {![file exists $baubles_windows_path]} {
	    .m confirm \
		-type "1button" \
		-button1of1 "Dismiss" \
		-text "Couldn't find baubles.py \nMake sure it is in the '$CCP4/share/smartie' directory"
	    return
	}
    } else {
	if { [catch "exec baubles" message ]} {
	    if { [regexp "couldn't execute" $message]} {
		.m confirm \
		    -type "1button" \
		    -button1of1 "Dismiss" \
		    -text "Couldn't execute baubles \nMake sure that baubles is in your path"
		return
	    }
	}
    }

    # Get the MTZ file name and directory
    set current_mtz_dir [$::session getMTZDirectory]	
    set current_mtz_file [$::session getMTZFilename]	
    if { ![ file exists $current_mtz_file ]} {
	.m confirm \
	    -type "1button" \
	    -button1of1 "Dismiss" \
	    -text "The file $current_mtz_file does not exist. QuickSymm or QuickScale will not proceed "
	return
    }

    set pointlesspipe [open "| pointless HKLIN $current_mtz_file HKLOUT pointless_$current_mtz_file" "r+"]
    set pointlesslog "pointandscale.log"
    set baubleshtml [ file join $current_mtz_dir "pointandscale.html" ] 
    update
    fconfigure $pointlesspipe -buffering line
    # if running QuickScale and requested to - use iMosflm symmetry
    if {[$::session getParameterValue use_mosflm_symmetry] == 1 && $pointless_only_bool != 1 } {
	if {[$::session getSpacegroup] != ""} {
	    puts $pointlesspipe "choose spacegroup [[$::session getSpacegroup] reportSpacegroup]"
	    if {[[$::session getSpacegroup]  reportSpacegroup] == "C2"} {
		puts $pointlesspipe "setting C2"
	    }
	}
    }
    puts $pointlesspipe "end"
    fileevent $pointlesspipe "readable" [runScaling $pointlesspipe $current_mtz_file $pointlesslog $baubleshtml $pointless_only_bool] 
}

body Processingwizard::runScaling { a_pipe a_mtz_file a_logfile a_baubles_htmlfile a_bool} {
    $itk_component(quick_symm_tb) configure -state disabled
    $itk_component(quick_scale_tb) configure -state disabled

    set scaling_prog aimless
    if {[.ats component advanced_integration getUseScalaBool] == 1} { set scaling_prog scala }

    set pointlesslogfileID [open $a_logfile w]
    set i "0"
    #puts "in runScaling"
    #puts [gets $a_pipe std_out]
    if {$a_bool != 1} {
	.c busy "busy scaling ..."
    } else {
	.c busy "checking symmetry with pointless ..."
    }
    while {[gets $a_pipe std_out] >= 0} {
	puts $pointlesslogfileID $std_out
	#puts $a_logfile $std_out
	incr i
	.c progress [expr $i%100]
	update
    }

    #puts "pointless has finished"
    if {$a_bool != 1} {
	set i "0"
	set scalapipe [open "| $scaling_prog HKLIN pointless_$a_mtz_file HKLOUT scala_$a_mtz_file" "r+"]
	fconfigure $scalapipe -buffering line 
	puts $scalapipe "scales rotation spacing 5  secondary 4  bfactor on   brotation  spacing 20"
	if {[$::session getParameterValue treat_anomalous_data] == 1} {
	    puts $scalapipe "anomalous on"
	} else {
	    puts $scalapipe "anomalous off"
	}
	puts $scalapipe "end"
	while {[gets $scalapipe std_out2] >= 0} {
	    puts $pointlesslogfileID $std_out2
	    incr i
	    .c progress [expr $i%100]
	    update
	}
#	puts "Scala has finished"

#	run ctruncate also
	set ctruncatepipe [open "| ctruncate -hklin scala_$a_mtz_file -hklout ctruncate_$a_mtz_file -colin \"/*/*/\[IMEAN,SIGIMEAN\]\" -colano \"/*/*/\[I(+),SIGI(+),I(-),SIGI(-)\]\"" "r+"]
	fconfigure $ctruncatepipe -buffering line 
	puts $ctruncatepipe "end"
	while {[gets $ctruncatepipe std_out2] >= 0} {
	    puts $pointlesslogfileID $std_out2
	}
    }
    close $pointlesslogfileID

    if { ![catch {qtrv::isAvailable} catchmsg] } {
        qtrv::launchReportViewer $a_logfile $a_mtz_file [expr $a_bool == 1]
        .c idle
        [.c component status_message] configure -text "Done"
    }\
    else {
        # Set the path to the baubles python script
        if { [regexp -nocase windows $::tcl_platform(os)] } {
            set baubles_windows_path [file join $::env(CCP4) share smartie baubles.py]
            if {[$::session getParameterValue web_browser] != ""} {
                # set via Environment variable settings window
                set ::env(CCP4_BROWSER) [$::session getParameterValue web_browser]
            } {
                if { [info exists ::env(CCP4_BROWSER)] } {
                    $::session updateSetting web_browser $::env(CCP4_BROWSER) 0 0 "Processing_options"
                }
            }
        } 


        if { [regexp -nocase windows $::tcl_platform(os)] } {
            set b [open "| python $baubles_windows_path $a_logfile" r] 
        } else {
            set b [open "| baubles $a_logfile" r]
        } 
        set std_out [read -nonewline $b]
        if {[eof $b]} {
            #puts "baubles has finished running"
            catch {close $b} std_err
            set baubleshmtlfileID [open $a_baubles_htmlfile w]
            puts $baubleshmtlfileID $std_out
            close $baubleshmtlfileID
            set baubles_htmlfile [file join [pwd] $a_baubles_htmlfile]
            # Added special case for windows as it seems to not work with open_url
            if { [regexp -nocase windows $::tcl_platform(os)] } {
                  exec [regsub -all \" $::env(CCP4_BROWSER) "" ] $a_baubles_htmlfile &
            } else {
                  open_url $a_baubles_htmlfile
            }
            #[.c component activity_l] idle
            .c idle
            [.c component status_message] configure -text "Done"
        }
    }

    $itk_component(quick_symm_tb) configure -state normal
    $itk_component(quick_scale_tb) configure -state normal

}

body Processingwizard::saveScript { } {

    # Get list of images to be processed
    set l_image_list [getImageList]

    # Validate matrices
    validateMatrices $l_image_list

    # Get the user to pick a new filename and location (as full path)
    if {![winfo exists .saveScript]} {
	Fileopen .saveScript  \
	    -title "Save script file" \
	    -type save \
	    -initialdir [pwd] \
	    -filtertypes {{"Mosflm script" {.msc}} {"All Files" {.*}}}
    }
    set l_script_file [.saveScript get]

    # If the user picked a file
    if {$l_script_file != ""} {
        # Write script file
	writeScript $l_script_file $l_image_list
    }
}

body Processingwizard::submitBatch { } {

    # Get list of images to be processed
    set l_image_list [getImageList]
    
    # Validate matrices
    validateMatrices $l_image_list

    set l_script [getScript $l_image_list]

    # Launch batch dialog
    .bsd launch $l_script
}

body Processingwizard::splitaBatch { } {

    set nbatch 0
    set ntosplit 20

    # Get list of images to be processed
    set l_image_list [getImageList]
    
    # Validate matrices
    validateMatrices $l_image_list

    set total [llength $l_image_list]
    if { $total > $ntosplit } {
	for { set offset 0} { $offset <= $total } { incr offset $ntosplit} {
	    incr nbatch
	    set l_script [getScript [lrange $l_image_list $offset [expr ($offset+$ntosplit-1)]]]
	    # Launch batch process
	    .bsd ok $l_script $nbatch
	}
    } else {
        set l_script [getScript $l_image_list]
    }
    #puts $l_image_list
    
    .m configure \
        -type "2button" \
        -title "Batch XML file" \
        -text "Try reading mosflm_batch.xml?" \
        -button1of2 "Yes" \
        -button2of2 "No"
    if { [.m confirm] } {
        puts "Start: [clock format [clock seconds] -format "%H:%M:%S"] reading batch XML"
        # create results object (auto initialized)
        if {$results != ""} {
            #puts "Processingwizard::splitaBatch deleting object $results"
            delete object $results
            set results ""
        }
        set results [eval newResults $l_image_list]
        #puts "$results object"

        # Test reading the mosflm_batch.xml file
        set in_file [::open [file join [$::session getParameterValue mtz_directory] "mosflm_batch.xml"] r]

        while {[gets $in_file line] >= 0} {
            if {[string range $line 0 4] == "<?xml"} {
                set dom [dom parse $line]
                processBatch $dom
            } else {
                # ignore e.g. <Mosflm version ...> header
            }
        }
        puts " Ends: [clock format [clock seconds] -format "%H:%M:%S"]"
        ::close $in_file
    } else {
	if { $nbatch == 0 } {
	    # Launch batch dialog
	    .bsd launch $l_script
	}
    }
}

body Processingwizard::processBatch { dom } {

    # keep record of where to sending processing feedback
    set processor "[.c component integration]"
    
    # read the document type
    set doctype [[$dom documentElement] nodeName]
    #puts "processBatch: $doctype"

    # Pass to appropriate object to process...
    if {$doctype == "image_response"} {
        .image parseHistogram $dom
    } elseif {$doctype == "header_response"} {
        $::session processHeaderData $dom
    } elseif {$doctype == "brief_header_response"} {
        $::session processBriefHeaderData $dom
    } elseif {$doctype == "experiment_response"} {
        $::session processExperimentData $dom
    #} elseif {$doctype == "warnings"} {
    #    $::session parseWarnings $dom
# Started processing keyword errors sent by Mosflm but probably too disruptive
# as e.g. during Integration iMosflm sends a "continue" command after each image.
#       } elseif {$doctype == "keyword_error"} {
#          $::session parseErrors $dom
    } elseif {$doctype == "spot_search_response"} {
        [.c component indexing] processSpotfindingResults $dom
    } elseif {$doctype == "preselection_index_response"} {
        [.c component indexing] processIndexingResults $dom
    } elseif {$doctype == "prerefinement_index_response"} {
        [.c component indexing] processPrerefinementResult $dom
    } elseif {$doctype == "refined_index_response"} {
        [.c component indexing] processRefinedResult $dom
    } elseif {$doctype == "mosaicity_response"} {
        .me processMosaicityEstimation $dom
    } elseif {$doctype == "mosaicity_estimation_response"} {
        .me processMosaicityFeedback $dom
    } elseif {$doctype == "prediction_response"} {
        .image processPredictions $dom
    } elseif {$doctype == "bad_spots_response"} {
        .image processBadSpots $dom
    } elseif {$doctype == "pick_region"} {
        .image processPick $dom
    } elseif {$doctype == "block_size_notification"} {
        if {$processor != "strategy"} {
            $processor extractBlockSize $dom
        }
    } elseif {$doctype == "image_process_begin"} {
        # set the processing flag, so next <done> is trapped as processing finish
        set processing_flag "1"
        $processor updateProcessingStatus "refinement" $dom
    } elseif {$doctype == "integration_positional_refinement"} {
        $processor updateProcessingData "refinement" $dom
    } elseif {$doctype == "spot_profile"} {
        $processor updateProfileData $dom
    } elseif {$doctype == "integration_postrefinement_begin"} {
        $processor updateProcessingStatus "postrefinement" $dom
    } elseif {$doctype == "integration_postrefinement"} {
        $processor updateProcessingData "postrefinement" $dom
    } elseif {$doctype == "refinement_repeat"} {
        $processor updateProcessingStatus "repeat refinement" $dom
    } elseif {$doctype == "regional_spot_profile_response"} {
        $processor updateRegionalProfileData $dom
    } elseif {$doctype == "block_integrate_begin"} {
         if {$processor eq [.c component integration]} {
                 if {[$::session getParameterValue pointless_live] == 1} {
                         $::session callPointlessProcess
                 }
         }
         $processor updateIntegrationStatus
    } elseif {$doctype == "integration_response"} {
        $processor updateIntegrationData $dom
    } elseif {$doctype == "cell_refine_response"} {
        $processor processCellRefinementSummary $dom
    } elseif {$doctype == "information_and_warnings"} {
        $::session parseInfoAndWarnings $processor $dom
    } elseif {$doctype == "strategy_response_alignment"} {
        [.c component strategy] processStrategyAlignmentResponse $dom
    } elseif {$doctype == "strategy_response"} {
        [.c component strategy] processStrategyResponse $dom
    } elseif {$doctype == "strategy_response_breakdown"} {
        [.c component strategy] processStrategyBreakdownResponse $dom
    } elseif {$doctype == "segment_setup_response"} {
        [.c component cell_refinement] processSegmentSetupResponse $dom
    } elseif {$doctype == "updated_raster_and_separation"} {
        $::session processRasterAndSeparation $dom $processor
    } elseif {$doctype == "circle_fitting_response"} {
        CircleFit::parseCircle $dom
    } elseif {$doctype == "backstop_response"} {
        ImageDisplay::parseBackstop $dom
    } elseif {$doctype == "fatal_condition_response"} {
        $::session processFatalError $dom
    } elseif {$doctype == "strategy_response_testgen"} {
        [.c component strategy] processTestgenResponse $dom
    } elseif {$doctype == "generate_response"} {
        $::session processGenerateResponse $dom
    } else {
        # Unrecognized message!!!
    }
    # Tidyup
    $dom delete
}

body Processingwizard::writeScript {  a_filename an_image_list } {
    
    if {[catch {set l_file [open $a_filename w]}]} {
	puts "Could not create script file: $a_filename"
    } else {
	puts $l_file [getScript $an_image_list]
	close $l_file
    }
    
}

body Processingwizard::getScript { an_image_list } {
    error "This method should be overwritten!"
}

body Processingwizard::validateMatrices { a_image_list } {
    # Check matrices are all present
    set l_sector_list {}
    foreach i_image $a_image_list {
	set l_sector [$i_image getSector]
	if {[lsearch $l_sector_list $l_sector] < 0} {
	    lappend l_sector_list $l_sector
	}
    }
    # Get list of sectors with invalid matrices
    set l_sectors_with_invalid_matrices {}
    foreach i_sector $l_sector_list {
	set l_matrix [$i_sector getMatrix]
	if {![$l_matrix isValid]} {
	    lappend l_sectors_with_invalid_matrices $i_sector
	}
    }
    if {[llength $l_sectors_with_invalid_matrices] > 0} {
	set l_first_matrix ""
	# Get first valid matrix in session
	foreach i_sector [$::session getSectors] {
	    set l_matrix [$i_sector getMatrix]
	    if {[$l_matrix isValid]} {
		set l_first_matrix $l_matrix
		break
	    } 
	}
	# If there is a valid matrix
	if {$l_first_matrix != ""} {
	    if {$processing_stage == "cell_refinement"} {
		set l_reason "Cell_refinement"
	    } else {
		set l_reason "Integration"
	    }
	    set l_reason
	    # updte the sectors requiring it
	    foreach i_sector $l_sectors_with_invalid_matrices {
		$i_sector updateMatrix $l_reason $l_first_matrix 1 1 0
	    }
	} else {
	    # Shouldn't be possible!
	    # warn the user that mosflm couldn't proceed.
	    .m configure \
		-type "1button" \
		-text "Cannot find a valid matrix. Sorry." \
		-button1of1 "Dismiss"
	    if {[.m confirm]} {
		return
	    }
	}
    }	    
}

body Processingwizard::loadResults { a_results } {

    # create results object (auto initialized)
    if {$results != ""} {
    #puts "Processingwizard::loadResults: results object exists  $results"
    #puts "Processingwizard::loadResults: results object deleted $results"
	delete object $results
	set results ""
    } else {
        #puts "Processingwizard::loadResults: NO results object exists $results"
    }
    set results [copyResults $a_results]
    #puts "Processingwizard::loadResults: results object created $results"

    #puts "copyResults: [$results serialize]"

    # update image numbers
    #puts "Images from $results [$results getImages]"
    updateImages [$results getImages]

    # initialize trees and graphs
    initializeTreesAndGraphs

}

body Processingwizard::getImageList { args } {
    # build image_list
    #puts "Processingwizard::getImageList $args"
    set l_image_list {}
    set l_numbers {}
    set l_nums {}
    #puts "PW \$itk_component(image_numbers) getContent [$itk_component(image_numbers) getContent]"
    foreach i_template_and_numbers [$itk_component(image_numbers) getContent] {
	foreach { l_template l_numbers } $i_template_and_numbers break
	# Sort this list unique to prevent overlapping ranges screwing-up the plots
	set l_nums [lsort -integer -uniq $l_numbers]
	foreach i_num $l_nums {
	    set l_image [$::session getImageByTemplateAndNumber $l_template $i_num]
	    if {$l_image != ""} {
		lappend l_image_list $l_image
	    }
	}
    }

    updateImages $l_image_list

    return $l_image_list
}
 
body Processingwizard::newResults { args } {
    return [namespace current]::[eval Processingresults \#auto "new" $args]
}

body Processingwizard::copyResults { a_results } {
    error "Virtual method called!"
}

body Processingwizard::initializeTreesAndGraphs { } {

    #puts "here - Processingwizard::initializeTreesAndGraphs"
    # update parameter trees and graphs
    updateParameterTreesAndGraphs

    # refresh the profile tree
    refreshProfileTree

}

body Processingwizard::updateParameterTreesAndGraphs { args } {

    # This is used for updating all graphs in both refinement
    # and integration. Similarly-named functions in other files call this.

    # if no parameter class(es) is/are specified, update both - but do we plot twice or just once?
    if {[llength $args] == 0} {
	#puts "No args to updateParameterTreesAndGraphs - initializing?"
	set l_param_classes [list refinement postrefinement]
    } else {
	set l_param_classes $args
    }
    
    foreach i_param_class $l_param_classes {
	foreach i_param [Processingresults::getParameters $i_param_class] {
	    #puts $i_param
	    if { $i_param != "beam_y_corrected" } {
		$itk_component(${i_param_class}_tree) item text $items_by_parameter($i_param) 1 [$results getDatum $i_param]
	    }
	}
	#puts "Call plotProcessingGraph for $i_param_class with list set to $l_param_classes"
	plotProcessingGraph $i_param_class
    }
}

body Processingwizard::getRefinementTree { } {
    return $itk_component(refinement_tree)
}

body Processingwizard::getPostrefinementTree { } {
    return $itk_component(postrefinement_tree)	
}

body Processingwizard::getItemsByParameter {a_param } {
    return $items_by_parameter($a_param)
}

body Processingwizard::complete { } {
    $results updateSession
    hide
}

# Control methods

body Processingwizard::abort { } {
    # Set the process processing order to be "abort" 
    set processing_order "abort"
    
    # Enable fixing checkbuttons
    foreach i_param_class { refinement postrefinement } {
	foreach i_param [Processingresults::getParameters $i_param_class] {
	    if {[Processingresults::parameterIsFixable $i_param]} {
		$itk_component(${i_param_class}_tree) item state set $items_by_parameter($i_param) ENABLED
	    }
	}
    }

}

body Processingwizard::pause { } {
    # Set the process processing order to be blank
    set processing_order ""

    # N.B. Mosflm will wait for a continue or an abort!

    # Update the control buttons
    $itk_component(process) configure \
	-text "Continue" \
	-command [code $this continueProcessing]

    # Disable the Abort button - it only works if Process-ing
    $itk_component(cancel) configure -state disabled

    # Update activity indicator
    .c pause
}

body Processingwizard::continueProcessing { } {
    # Send continue signal to mosflm
    update idletasks
    $::mosflm promptProcessing "continue"

    # set subsequent processing order to be continue too
    set processing_order "continue"

    # Update the control buttons
    $itk_component(process) configure \
	-text "Pause" \
	-command [code $this pause]

    # Enable the Abort button - so it works if Process-ing
    $itk_component(cancel) configure -state normal

    # Update activity indicator
    .c busy
}

# Feedback processing methods ######################################################################

body Processingwizard::extractBlockSize { a_dom } {
    set block_size [$a_dom selectNodes normalize-space(//block_size)]
}

body Processingwizard::updateProcessingStatus { a_reason a_dom } {

    # get the name of the image being processed
    set l_image_name [$a_dom selectNodes normalize-space(//image_name)]

    # Clear bad spot list from any previous integration done on this image
    #puts "updateProcessingStatus - clearing bad spots for $l_image_name reason $a_reason"
    set i_image [$::session getImageByName $l_image_name]
    $i_image unsetBadSpotlist


    # Update the results (truncating/padding data and returning status message)
    foreach { l_message l_update_refinement_graph l_update_postrefinement_graph } [$results updateProcessingStatus $a_reason $l_image_name] break

    # Update the status message
    .c updateStatusMessage $l_message

    # Update the progress bar
    .c progress [$results getProgress]

    # Update graphs if necessary
    if {$l_update_refinement_graph} {
	#puts "$l_update_refinement_graph plotProcessingGraph refinement $l_image_name"
	plotProcessingGraph "refinement"
    }
    if {$l_update_postrefinement_graph} {
	#puts "$l_update_postrefinement_graph plotProcessingGraph postrefinement $l_image_name"
	plotProcessingGraph "postrefinement"
    }

}

body Processingwizard::updateProcessingData { a_param_class a_dom } {

    # Check on status of task
    set status_code [$a_dom selectNodes string(/integration_postrefinement/status/code)]
    if {$status_code == "error"} {
	.m confirm \
	    -type "1button" \
	    -text "Integration post-refinement failed, sorry.\n[$a_dom selectNodes string(/integration_postrefinement/status/message)]" \
	    -button1of1 "Dismiss"
    } else {
	# prompt mosflm to continue or abort if necessary (only during refinement)
	if {$a_param_class == "refinement"} {
	    set l_image_name [$a_dom selectNodes normalize-space(//image_name)]
	    # Update the image if the update images box is checked
	    if {[$::session getParameterValue "view_predictions_during_processing"]} {
		# Get the object for current image
		set l_image [$::session getImageByName $l_image_name]
		# Tell image viewer to open current image
		.image openCurrentImage $l_image
		$::mosflm promptProcessing "head brief"
		$::mosflm promptProcessing "go"
	    }
	    # Continue, abort, or do nothing...
	    if {$processing_order == "continue"} {
		update idletasks
		$::mosflm promptProcessing "continue"
	    } elseif {$processing_order == "abort"} {
		#puts "Abort sent in $a_param_class"
		catch [$::mosflm removeJob "cell_refinement"]
		catch [$::mosflm removeJob "integration"]
		$::mosflm promptProcessing "abort"
	    } else {
		# Must be paused...
	    }
	}
	
	# Extract data and store in results object & extract sd data also if postrefining
	if {$a_param_class == "postrefinement"} {
	    foreach i_param [Processingresults::getParameters $a_param_class] {
		$results appendDatum $i_param [$a_dom selectNodes normalize-space(//$i_param)]
		$results updateStdDev ${i_param}_sd [$a_dom selectNodes normalize-space(//${i_param}_sd)]
	    }
	} else {
	    foreach i_param [Processingresults::getParameters $a_param_class] {
		$results appendDatum $i_param [$a_dom selectNodes normalize-space(//$i_param)]
	    }
	}

	# Update the parameter tree and graph
	updateParameterTreesAndGraphs $a_param_class
    
    }

}

body Processingwizard::updateProfileData { a_dom } {

    # Extract image name
    set l_image_name [$a_dom selectNodes normalize-space(//image_name)]

    # Extract and store spot profile info from xml
    $results storeProfile $l_image_name \
	[$a_dom selectNodes normalize-space(//width)] \
	[$a_dom selectNodes normalize-space(//height)] \
	[$a_dom selectNodes normalize-space(//profile)] \
	[$a_dom selectNodes normalize-space(//mask)]

    # update the profile listbox
    updateProfileTree $l_image_name

    # Calculate progress...
    .c progress [$results getProgress]
}

body Processingwizard::refreshProfileTree { } {
    # Clear previous profile tree entries
    $itk_component(profile_tree) item delete all
    array unset profile_items_by_name *
    array unset profile_names_by_item *
    set current_profile ""
    set t_item ""
    # Add entries for each image to the profile listbox
    foreach i_image_name [$results getProfileNames] {
        set l_image [$::session getImageByName $i_image_name]
        set t_item [$itk_component(profile_tree) item create]
        $itk_component(profile_tree) item style set $t_item 0 s1
        $itk_component(profile_tree) item text $t_item 0 [$l_image getNumber]
        $itk_component(profile_tree) item state set $t_item AVAILABLE
        $itk_component(profile_tree) item lastchild root $t_item
        set profile_items_by_name($i_image_name) $t_item
        set profile_names_by_item($t_item) $i_image_name
    }
    # Sort items
    $itk_component(profile_tree) item sort root -dictionary
    # Select last item if any were created
    set l_item [$itk_component(profile_tree) item lastchild root]
    if {$l_item != ""} {
        $itk_component(profile_tree) selection modify $l_item all
    }
    displayProfile
}

body Processingwizard::updateProfileTree { i_image_name } {

    # Add incoming image to the profile listbox - may be being processed again
    set t_item ""
    set last_item ""
    set curr_item ""
    set current_profile ""
    set l_image [$::session getImageByName $i_image_name]
    set last_item [$itk_component(profile_tree) item lastchild root]
    set curr_item [ expr [lsearch -exact [$results getProfileNames] $i_image_name] + 1 ]
    if { $curr_item <= $last_item } {
	#puts "Re-update of profile for $i_image_name last item still $last_item"
	# Select item being reprocessed
	$itk_component(profile_tree) selection modify $curr_item all
    } else {
	set t_item [$itk_component(profile_tree) item create]
	#puts "updateProfileTree: file $i_image_name l_image [$l_image getNumber] $l_image this_item $t_item"
	
	$itk_component(profile_tree) item style set $t_item 0 s1
	$itk_component(profile_tree) item text $t_item 0 [$l_image getNumber]
	$itk_component(profile_tree) item state set $t_item AVAILABLE
	$itk_component(profile_tree) item lastchild root $t_item
	
	# Select last item just added
	$itk_component(profile_tree) selection modify $t_item all
	
	# Scroll down
	$itk_component(profile_tree) yview moveto 1.0
    }

    #Display the new profile
    displayProfile $i_image_name
}

body Processingwizard::finishedProcessing { } {
    # Turn off activity indicator and clear status message
    .c idle

    # Enable ALL controls
    .c enable

    # Re-configure process button from pause button
    $itk_component(process) configure \
	-state "normal" \
	-text "Process" \
	-command [code $this process]
    
    # Disable cancel button
    $itk_component(cancel) configure -state "disabled"

    # Enable fixing checkbuttons
    foreach i_param_class { refinement postrefinement } {
	foreach i_param [Processingresults::getParameters $i_param_class] {
	    if {[Processingresults::parameterIsFixable $i_param]} {
		$itk_component(${i_param_class}_tree) item state set $items_by_parameter($i_param) ENABLED
	    }
	}
    }

    # update the session with the new parameter values
    $results updateSession

    # Test the detector and cell parameters vs. those in saveDetectorCrystalParams before Processing
    set warning_list [testDetectorCrystalParams]
    set messages ""
    foreach warning $warning_list {
	if { $warning != "" } {
	    # test for word serious in each warning?
	    append messages $warning
	}
    }
    if { $messages != ""} {
	#puts $messages
	# Warn the user
	.m configure \
	    -type "2button" \
	    -title "Doubtful refinement of Detector parameters" \
	    -text "The following detector parameters have refined to physically questionable values:\n\n$messages\nIt is possible that this is due to inaccurate initial cell parameters or\nincorrect choice of space group.\n\nIf you wish to continue, you are advised to reset the detector and crystal\nparameters to their initial values before attempting to correct the situation\n(e.g. re-indexing, choosing alternative indexing solution).\n" \
	    -button1of2 "Reset" \
	    -button2of2 "Ignore"
	if {[.m confirm]} {
	    resetDetectorCrystalParams
	}
    }

    #puts " Ends: [clock format [clock seconds] -format "%H:%M:%S"]"
}

body Processingwizard::paramTreeClick { a_param_class w x y } {
    # bug 61 in this vicinity
    set id [$w identify $x $y]
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "header"} {
    } else {
	$w activate [$w index [list nearest $x $y]]
	foreach {what item where arg1 arg2 arg3} $id {}
	if {[lindex $id 5] == "e_check"} {
	    if {[$w item state get $item ENABLED]} {
		set l_params $parameters_by_item($a_param_class,$item)
		if {$l_params == "beam_x"} {
		    set l_setting "${processing_stage}_fix_beam"
		    lappend l_params beam_y
		} elseif {$l_params == "beam_y"} {
		    set l_setting "${processing_stage}_fix_beam"
		    lappend l_params beam_x
		} else {
		    set l_setting "${processing_stage}_fix_$l_params"
		}
		if {[$w item state get $item CHECKED]} {
		    $::session updateSetting $l_setting "0"
		    foreach i_param $l_params {
			$w item state set $items_by_parameter($i_param) !CHECKED
		    }
		} else {
		    $::session updateSetting $l_setting "1"
		    foreach i_param $l_params {
			$w item state set $items_by_parameter($i_param) CHECKED
		    }
		}
	    }
	}
    }
}

body Processingwizard::plotProcessingGraph { a_param_class } {

    if {$results != ""} {
	#puts "plotProcessingGraph: $a_param_class results is $results"
	# Build datasets
	set l_data_sets {}
	foreach i_param [Processingresults::getParameters $a_param_class] {
	    # Don't plot beam_y, plot beam_y_corrected instead
	    if { $i_param != "beam_y" && $i_param != "beam_y_corrected" } {
		if {[$itk_component(${a_param_class}_tree) selection includes $items_by_parameter($i_param)]} {
		    set l_data_set [$results getDataSet $i_param]
		    if {[llength $l_data_set] > 0} {
			lappend l_data_sets [$results getDataSet $i_param]
		    }
		}
	    } else {
		if {[$itk_component(${a_param_class}_tree) selection includes $items_by_parameter($i_param)]} {
		    set l_data_set [$results getDataSet beam_y_corrected]
		    if {[llength $l_data_set] > 0} {
			#puts "Got $i_param [$results getDataSet beam_y] beam_y_corrected [$results getDataSet beam_y_corrected]"
			lappend l_data_sets [$results getDataSet beam_y_corrected]
		    }
		}
	    }
	}
	# See if anything should be plotted
	if {([llength [$results getImages]] == 0) || ([llength $l_data_sets] == 0)} {
	    #puts "Zero length images or datasets"
	    # Loop through canvases to plot graph on
	    foreach i_canvas $canvases_by_content($a_param_class) {
		# Delete any previous graphs
		$i_canvas delete all
	    }
	} else {
	    # Loop through canvases to plot graph on
	    foreach i_canvas $canvases_by_content($a_param_class) {
		# Calculate window
		set window [list 10 10]
		lappend window [expr [winfo width $i_canvas] - 10]
		lappend window [expr [winfo height $i_canvas] - 10]
		#puts [winfo width $i_canvas]
		#puts [winfo height $i_canvas]
		#puts "$i_canvas window $window"
		if {([lindex $window 2] > 20) && ([lindex $window 3] > 20)} {
		    # Create graph if there's room
		    set image_data_set [$results getImageDataSet]
		    #puts "Linegraph for [llength $l_data_sets] datasets $l_data_sets after $a_param_class of [llength [$results getImages]] images"
		    LineGraph \#auto $i_canvas $window "id" $image_data_set $l_data_sets
 		    # Remove the dataset objects to ease memory overheads
 		    #puts "Deleting $image_data_set"
		    delete object $image_data_set
 		    foreach ds $l_data_sets {
 			delete object $ds
 			#puts "Deleting $ds"
 		    }
		} else {
		    #puts "No room for graph $i_canvas"
		}
		bind $i_canvas <Configure> [code $this plotProcessingGraph $a_param_class]
	    }
	}
    } else {
	#puts "plotProcessingGraph: $a_param_class results is unset"
    }
}

body Processingwizard::updateProfileSelection { a_item } {
    if {$a_item != ""} {
	#puts "updateProfileSelection: $a_item - [$itk_component(profile_tree) item state get $a_item]"
	if {[$itk_component(profile_tree) item state get $a_item AVAILABLE]} {
	    set current_profile [ lindex [$results getProfileNames] [expr $a_item - 1] ]
	    displayProfile $current_profile
	}
    } else {
	$itk_component(profile_c) delete all
    }
}

body Processingwizard::displayProfile { { a_name ""} } {
    # Update current profile if one was passed
    if {$a_name != ""} {
	set current_profile $a_name
    }    
    # if there is now a current profile
    if {$current_profile != ""} {
	# Display the profile
	$results displayProfile $current_profile $itk_component(profile_c)
    }
    bind $itk_component(profile_c) <Configure> [code $this displayProfile]

}

# Graph zooming #################################################

body Processingwizard::zoom { a_widget } {
    if {!$zoomed} {
	foreach i_widget [winfo children $itk_component(results_f)] {
	    grid forget $i_widget
	}
	grid $a_widget -sticky nswe -padx $margin -pady $margin
	grid columnconfigure $itk_component(results_f) { 0 2 4 6 } -minsize 0
	grid columnconfigure $itk_component(results_f) { 3 5 } -weight 0
	grid columnconfigure $itk_component(results_f) { 0 } -weight 1
	grid rowconfigure $itk_component(results_f) { 1 2 } -weight 0
	foreach i_widget [winfo children $a_widget] {
	    event generate $i_widget <Configure>
	}
	set zoomed 1
    }
}

body Processingwizard::toggleZoom { a_widget } {
    if {$zoomed} {
	restoreGrid
    } else {
	zoom $a_widget
    }
}

body Processingwizard::restoreGrid { } {
    if {$zoomed} {
	foreach i_widget [winfo children $itk_component(results_f)] {
	    grid forget $i_widget
	}
	grid x $itk_component(refinement_tree) x  $itk_component(refinement_canvas) x $itk_component(profile_f) x -sticky nsew -pady [list $margin 0]
	grid x $itk_component(postrefinement_tree) x $itk_component(postrefinement_canvas) x -sticky nsew -pady $margin
	grid columnconfigure $itk_component(results_f) { 0 2 4 6 } -minsize $margin
	grid columnconfigure $itk_component(results_f) { 3 5 } -weight 1
	grid rowconfigure $itk_component(results_f) { 0 1 } -weight 1
	set zoomed 0
    }
}

# Treectrl tooltips ###############################################

body Processingwizard::treectrlMotion { a_param_class a_w a_x a_y } {
    set l_item ""
    # get item rolled over
    set id [$a_w identify $a_x $a_y]
    if {$id != ""} {
	if {[lindex $id 0] eq "item"} {
	    set l_item [lindex $id 1]
	}
    }

    if {$l_item == ""} {
	# cancel tooltip
	.tooltip drop
	set last_tooltip_item ""
    } elseif {$l_item != $last_tooltip_item} {
	# Item changed so queue new tooltip...
	.tooltip queue \
	    -text [Integrationresults::getLongParameterName $parameters_by_item($a_param_class,$l_item)] \
	    -bg gold \
	    -fg black
	# record item tip was queued for
	set last_tooltip_item $l_item
    }    
}

body Processingwizard::treectrlLeave { } {
    .tooltip drop
}

class ImagePalette {
    inherit Palette

    itk_option define -selectbackground selectBackground Foreground "\#3399ff"
    itk_option define -deselectbackground deselectBackground Foreground "\#dcdcdc"
    itk_option define -selectborder selectBorder Foreground "\#1c53eb"
    itk_option define -deselectborder deselectBorder Foreground "\#a9a9a9"

    # processing wizard
    private variable processing_wizard ""

    # arrays associating tree items and images
    protected variable images_by_item ; # N.B. Array - do not initialize!
    protected variable items_by_image ; # N.B. Array - do not initialize!

    # also index image_paths by item for quick sorting!!!
    protected variable image_paths_by_item ; # N.B. Array - do not initialize!

    # last cursor (for restoring cursor after button 2 & 3 use)
    protected variable last_cursor ""

    public method launch
    public method updateProcessWizard

    # Image tree interaction methods
    protected method imageTreeClick
    protected method imageTreeDoubleClick
    protected method toggleImageSelection
    protected method toggleImageInclusion
    protected method checkImageInclusion
    protected method uncheckImageInclusion

    # Segment canvas creation/positioning methods
    public method createSelectionSummary
    public method zoomIn
    public method zoomOut
    public method fitCanvas

    # Segment canvas toolbutton methods
    public method makeDefaultSelection
    public method uncheckAll
    public method checkAll
    public method toggleCheckSegmentsToolbutton
    public method toggleUncheckSegmentsToolbutton
    public method toggleGrabCanvasToolbutton

    # Segment canvas interaction methods
    public method turnSegmentPaintingOn
    public method turnSegmentPaintingOff
    public method turnSegmentWipingOn
    public method paintSegment
    public method wipeSegment
    public method grabCanvas
    public method releaseCanvas
    public method moveCanvasItems

    constructor { args } { }
}

body ImagePalette::constructor { a_processing_wizard args } {

    # Store processing wizard palette belongs to
    set processing_wizard $a_processing_wizard

    # Image list (tree)
    if {[tk windowingsystem] == "aqua"} {
	set file_chooser_width 380
    } else {
	set file_chooser_width 430
    }

    itk_component add image_tree {
	treectrl $itk_interior.itree \
	    -showroot 0 \
	    -showline 0 \
	    -showbutton 0 \
	    -selectmode single \
	    -width $file_chooser_width \
	    -itemheight 18 \
	    -highlightthickness 0
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    }

    $itk_component(image_tree) column create -text "Image" -justify left -minwidth 100 -expand 1 ;
    $itk_component(image_tree) column create -text "\u03c6 start" -justify center -minwidth 50 -tag phi_start
    $itk_component(image_tree) column create -text "\u03c6 end" -justify center -minwidth 50 -tag phi_end
    $itk_component(image_tree) column create -text "Use" -justify center -minwidth 30 -tag use

    $itk_component(image_tree) state define CHECKED

    $itk_component(image_tree) element create e_icon image -image ::img::image
    $itk_component(image_tree) element create e_text text -fill {white selected}
    $itk_component(image_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
    $itk_component(image_tree) element create e_check image -image { ::img::embed_check_on {CHECKED} ::img::embed_check_off {!CHECKED} }
	
    $itk_component(image_tree) style create s1
    $itk_component(image_tree) style elements s1 { e_highlight e_icon e_text }
    $itk_component(image_tree) style layout s1 e_icon -expand ns -padx {0 6}
    $itk_component(image_tree) style layout s1 e_text -expand ns
    $itk_component(image_tree) style layout s1 e_highlight -union [list e_icon e_text] -iexpand nse -ipadx 2
    
    $itk_component(image_tree) style create s2
    $itk_component(image_tree) style elements s2 {e_highlight e_text}
    $itk_component(image_tree) style layout s2 e_text -expand ns
    $itk_component(image_tree) style layout s2 e_highlight -union [list e_text] -iexpand nsew -ipadx 2

    $itk_component(image_tree) style create s3
    $itk_component(image_tree) style elements s3 {e_highlight e_check}
    $itk_component(image_tree) style layout s3 e_highlight -union [list e_check] -iexpand nsew -ipadx 2
    $itk_component(image_tree) style layout s3 e_check -expand ns -padx {2 2}

    bind $itk_component(image_tree) <ButtonPress-1> [code $this imageTreeClick %W %x %y]
    bind $itk_component(image_tree) <Double-ButtonPress-1> [code $this imageTreeDoubleClick %W %x %y]
    bind $itk_component(image_tree) <ButtonRelease-1> { break }

    $itk_component(image_tree) notify bind $itk_component(image_tree) <Selection> [code $this toggleImageSelection %S %D]

    # Image list scrollbar
    itk_component add image_scroll {
	scrollbar $itk_interior.iscroll \
	    -command [code $this component image_tree yview] \
	    -orient vertical
    }
    
    $itk_component(image_tree) configure \
	-yscrollcommand [list autoscroll $itk_component(image_scroll)]

    # Segment frame
    itk_component add segment_frame {
	frame $itk_interior.sf \
	    -relief sunken \
	    -bd 2
    } {
	usual
	rename -background -textbackground textBackground Background
    }    

    # Segment toolbar
    itk_component add segment_toolbar {
	frame $itk_interior.sf.stb \
	    -relief raised \
	    -bd 2
    }
    # Toolbuttons
    
    itk_component add default_selection_tb {
	Toolbutton $itk_component(segment_toolbar).dstb \
	    -image ::img::cell_refinement_default_selection \
	    -disabledimage ::img::cell_refinement_default_selection_disabled \
	    -command [code $this makeDefaultSelection] \
	    -balloonhelp "Default image selection"
    }

    itk_component add uncheck_all_tb {
	Toolbutton $itk_component(segment_toolbar).uatb \
	    -image ::img::cell_refinement_clear_selection \
	    -disabledimage ::img::cell_refinement_clear_selection_disabled \
	    -command [code $this uncheckAll] \
	    -balloonhelp "Clear image selection"
    }

    itk_component add check_all_tb {
	Toolbutton $itk_component(segment_toolbar).catb \
	    -image ::img::cell_refinement_select_all \
	    -disabledimage ::img::cell_refinement_select_all_disabled \
	    -command [code $this checkAll] \
	    -balloonhelp "Select all images"
    }

    itk_component add divider_1_tb {
	frame $itk_component(segment_toolbar).div1 \
	    -width 2 \
	    -bd 1 \
	    -relief sunken
    }

    itk_component add check_segment_tb {
	Toolbutton $itk_component(segment_toolbar).cstb \
	    -type "radio" \
	    -image ::img::image_palette_check_segments_tool \
	    -group "select_processing_images" \
	    -command [code $this toggleCheckSegmentsToolbutton] \
	    -balloonhelp "Select images"
    }

    itk_component add uncheck_segment_tb {
       Toolbutton $itk_component(segment_toolbar).ustb \
	    -type "radio" \
	    -image ::img::image_palette_uncheck_segments_tool \
	    -group "select_processing_images" \
	    -command [code $this toggleUncheckSegmentsToolbutton] \
	    -balloonhelp "Deselect images"
    }

    itk_component add grab_canvas_tb {
	Toolbutton $itk_component(segment_toolbar).gctb \
	    -type "radio" \
	    -image ::img::fleur \
	    -disabledimage ::img::fleur_disabled \
	    -group "select_processing_images" \
	    -command [code $this toggleGrabCanvasToolbutton] \
	    -balloonhelp "Move view"
    }

    itk_component add divider_2_tb {
	frame $itk_component(segment_toolbar).div2 \
	    -width 2 \
	    -bd 1 \
	    -relief sunken
    }
	    
    itk_component add zoom_in_tb {
	Toolbutton $itk_component(segment_toolbar).zitb \
	    -type "amodal" \
	    -image ::img::zoom_in \
	    -disabledimage ::img::zoom_in_disabled \
	    -command [code $this zoomIn] \
	    -balloonhelp "Zoom in"
    }

    itk_component add zoom_out_tb {
	Toolbutton $itk_component(segment_toolbar).zotb \
	    -type "amodal" \
	    -image ::img::zoom_out \
	    -disabledimage ::img::zoom_out_disabled \
	    -command [code $this zoomOut] \
	    -balloonhelp "Zoom out"
    }

    itk_component add fit_all_tb {
	Toolbutton $itk_component(segment_toolbar).fatb \
	    -type "radio" \
	    -image ::img::image_palette_fit_all \
	    -disabledimage ::img::cell_refinement_fit_all_disabled \
	    -group "select_processing_images" \
	    -command [code $this fitCanvas all] \
	    -balloonhelp "Fit all"
    }

    itk_component add fit_wedge_tb {
	Toolbutton $itk_component(segment_toolbar).fwtb \
	    -type "radio" \
	    -image ::img::image_palette_fit_sector \
	    -disabledimage ::img::cell_refinement_fit_wedge_disabled \
	    -group "select_processing_images" \
	    -command [code $this fitCanvas segment] \
	    -balloonhelp "Fit sector"
    }

    # Segment canvas
    itk_component add segment_canvas {
	canvas $itk_interior.sf.sc \
	    -borderwidth 0 \
	    -relief flat \
	    -highlightthickness 0
    } {
	rename -background -textbackground textBackground Background
    }    

    # Arrange the widgets

    if {[tk windowingsystem] == "aqua"} {
	# Add a closing X as there was a problem dismissing the pop-up on an earlier aqua
	set margin 0
	itk_component add exit_button {
	    button $itk_interior.eb -text "x" \
		-command [code $this dismiss]
	}
	grid x x x x $itk_component(exit_button)  -sticky ne
    } else {
	set margin 7
    }
    
    # Image selection frame
    grid x $itk_component(image_tree) $itk_component(image_scroll) x $itk_component(segment_frame) x -sticky news -pady $margin
    pack $itk_component(segment_toolbar) -fill x
    pack $itk_component(segment_canvas) -fill both -expand 1
    grid columnconfigure $itk_component(hull) {0 3 5} -minsize $margin
    grid columnconfigure $itk_component(hull) {1 4} -weight 1
    grid rowconfigure $itk_component(hull) 0 -weight 1
    
    pack $itk_component(check_segment_tb) -side left 
    pack $itk_component(uncheck_segment_tb) -side left 
    pack $itk_component(grab_canvas_tb) -side left 
    pack $itk_component(divider_2_tb) -side left -fill y -padx $margin 
    pack $itk_component(zoom_in_tb) -side left 
    pack $itk_component(zoom_out_tb) -side left 
    pack $itk_component(fit_all_tb) -side left 
    pack $itk_component(fit_wedge_tb) -side left

    eval itk_initialize $args
}


body ImagePalette::launch { a_button args } {
    # clear the image and tree
    $itk_component(image_tree) item delete all
    # clear arrays linking tree items and objects
    array unset images_by_item *
    array unset image_paths_by_item *
    array unset items_by_image *

    # Choose labelling method depending on number of templates
    if {[llength [$::session getSectors]] > 1} {
	set l_labelMethod "getShortName"
    } else {
	set l_labelMethod "getNumber"
    }

    # rebuild the image tree
    set i_sector [lindex [$::session getSectors] 0]
    foreach i_sector [$::session getSectors] {
	# Loop through sector's images
	foreach i_image [$i_sector getImages] {
	    # create a new item
	    set t_image_item [$itk_component(image_tree) item create]
	    # set the item's style
	    $itk_component(image_tree) item style set $t_image_item 0 s1 1 s2 2 s2 3 s3
	    # update the item's icon
	    $itk_component(image_tree) item element configure $t_image_item 0 e_icon -image ::img::image
	    # update the item's text
	    foreach {l_phi_start l_phi_end} [$i_image getPhi] break
	    set l_phi_start [format %6.2f $l_phi_start]
	    set l_phi_end [format %6.2f $l_phi_end]
	    $itk_component(image_tree) item text $t_image_item 0 [$i_image $l_labelMethod] 1 $l_phi_start 2 $l_phi_end 
	    # add the new item to the tree
	    $itk_component(image_tree) item lastchild root $t_image_item
	    set i_last_item $t_image_item
	    # Store pointer to image objects and items by number, item or object
	    set images_by_item($t_image_item) $i_image
	    set image_paths_by_item($t_image_item) [$i_image getFullPathName]
	    set items_by_image($i_image) $t_image_item
	}
    }

    # Check images listed as included in the processing wizard
    foreach i_image [$processing_wizard getImageList] {
	checkImageInclusion $items_by_image($i_image)
    }
    
    # SCroll to top of list
    $itk_component(image_tree) yview moveto 0

    # Create the summary canvas illustration
    createSelectionSummary
    bind $itk_component(segment_canvas) <Configure> [code $this createSelectionSummary]

    Palette::launch $a_button
}

body ImagePalette::imageTreeClick { w x y } {
    set id [$w identify $x $y]
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "header"} {
    } else {
	$w activate [$w index [list nearest $x $y]]
	foreach {what item where arg1 arg2 arg3} $id {}
	if {[lindex $id 5] == "e_check"} {
	    toggleImageInclusion $item
	}
    }
}

body ImagePalette::imageTreeDoubleClick { w x y } {
    set id [$w identify $x $y]
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "header"} {
    } else {
	foreach {what item where arg1 arg2 arg3} $id {}
	if {[lindex $id 5] == "e_icon"} {
	    # Open image
	    if {[info exists images_by_item($item)]} {
		.image openImage $images_by_item($item)
	    } else {
		$w item toggle $item
	    }
	} elseif {[lindex $id 5] == "e_check"} {
	    toggleImageInclusion $item
	}
    }
}

# Image selection

body ImagePalette::toggleImageSelection { a_selected { a_deselected "" } } {

    # if the selected item is checked...
    if {($a_selected != "") && [$itk_component(image_tree) item state get $a_selected CHECKED]} {
	# get its label
	set l_label [$itk_component(image_tree) item text $a_selected 0]
	# Reflect selection in canvas???
    }
    # if the deselected item is checked...
    if {($a_deselected != "") && [$itk_component(image_tree) item state get $a_deselected CHECKED]} {
	# get its label
	set l_label [$itk_component(image_tree) item text $a_deselected 0]
	# Reflect selection in canvas???
    }
}

# Image inclusion

body ImagePalette::toggleImageInclusion { an_item } {

    if {[$itk_component(image_tree) item state get $an_item CHECKED]} {
	uncheckImageInclusion $an_item
    } else {
	checkImageInclusion $an_item
    }
}


body ImagePalette::checkImageInclusion { an_item } {

    # if the spotlist is not checked don't bother!
    if {[$itk_component(image_tree) item state get $an_item CHECKED]} {
	return
    }
    # make the item  checked...
    $itk_component(image_tree) item state set $an_item CHECKED
    # get the item's label
    set l_label [$itk_component(image_tree) item text $an_item 0]
    # update the segment canvas
    $itk_component(segment_canvas) itemconfigure image($images_by_item($an_item)) \
	-fill $itk_option(-selectbackground) \
	-outline $itk_option(-selectborder) \
	-tags [list segment image($images_by_item($an_item)) checked]
    updateProcessWizard

}

body ImagePalette::uncheckImageInclusion { an_item } {

    # if the spotlist is not  checked don't bother!
    if {![$itk_component(image_tree) item state get $an_item CHECKED]} {
	return
    }
    # get the item's label
    set l_label [$itk_component(image_tree) item text $an_item 0]
    # make the item uncheked...
    $itk_component(image_tree) item state set $an_item !CHECKED
    # Update canvas...
    $itk_component(segment_canvas) itemconfigure image($images_by_item($an_item)) \
	-fill $itk_option(-deselectbackground) \
	-outline $itk_option(-deselectborder) \
	-tags [list segment image($images_by_item($an_item)) unchecked]
    updateProcessWizard
}

# Segment canvas creation/positioning methods #################################

body ImagePalette::createSelectionSummary { } {

    # clear canvas
    $itk_component(segment_canvas) delete all

    # Calculate circle position and size
    set x0 0
    set y0 0
    set x1 -500
    set x2 500
    set y1 -500
    set y2 500

    # Draw circle and labels
    $itk_component(segment_canvas) create oval $x1 $y1 $x2 $y2 -outline lightgrey -tags [list circle]
    $itk_component(segment_canvas) create text $x0 $y1 -text "0\u00b0" -fill lightgrey -anchor s
    $itk_component(segment_canvas) create text $x2 $y0 -text "90\u00b0" -fill lightgrey -anchor w
    $itk_component(segment_canvas) create text $x0 $y2 -text "180\u00b0" -fill lightgrey -anchor n
    $itk_component(segment_canvas) create text $x1 $y0 -text "270\u00b0" -fill lightgrey -anchor e

    # plot segments
    foreach i_im [$::session getImages] {
	# Get phi values
	foreach { l_phi_start l_phi_end } [$i_im getPhi] break
	# Get colours from checked
	if {[$itk_component(image_tree) item state get $items_by_image($i_im) CHECKED]} {
	    set l_fill $itk_option(-selectbackground)
	    set l_outline $itk_option(-selectborder)
	} else {
	    set l_fill $itk_option(-deselectbackground)
	    set l_outline $itk_option(-deselectborder)
	}
	# Create segment
	$itk_component(segment_canvas) create arc $x1 $y1 $x2 $y2 \
	    -start [expr 90 - $l_phi_start] \
	    -extent [expr $l_phi_start - $l_phi_end] \
	    -fill $l_fill \
	    -outline $l_outline \
	    -tags [list segment image($i_im) unchecked]
    }
    # Setup bindings
    $itk_component(uncheck_segment_tb) invoke
    $itk_component(grab_canvas_tb) invoke
    $itk_component(check_segment_tb) invoke
    bind $itk_component(segment_canvas) <ButtonPress-2> [code $this grabCanvas %x %y]
    bind $itk_component(segment_canvas) <ButtonRelease-2> [code $this releaseCanvas]
    bind $itk_component(segment_canvas) <ButtonPress-3> [code $this turnSegmentWipingOn %x %y]
    bind $itk_component(segment_canvas) <ButtonRelease-3> [code $this turnSegmentPaintingOff]
    bind $itk_component(segment_canvas) <ButtonPress-4> [code $this zoomIn]
    bind $itk_component(segment_canvas) <ButtonPress-5> [code $this zoomOut]

    $itk_component(fit_wedge_tb) invoke
}

body ImagePalette::zoomIn { args } {

    # Unbind canvas configure events
    bind $itk_component(segment_canvas) <Configure> {}
    # Cancel set-view toolbuttons
    $itk_component(fit_all_tb) cancel noexecute
    $itk_component(fit_wedge_tb) cancel noexecute
    # Zoom
    $itk_component(segment_canvas) scale all [expr [winfo width $itk_component(segment_canvas)] / 2] [expr [winfo height $itk_component(segment_canvas)] / 2] 1.1 1.1
}

body ImagePalette::zoomOut { args } {

    # Unbind canvas configure events
    bind $itk_component(segment_canvas) <Configure> {}
    # Cancel set-view toolbuttons
    $itk_component(fit_all_tb) cancel noexecute
    $itk_component(fit_wedge_tb) cancel noexecute
    # Zoom
    $itk_component(segment_canvas) scale all [expr [winfo width $itk_component(segment_canvas)] / 2] [expr [winfo height $itk_component(segment_canvas)] / 2] [expr 1.0/1.1] [expr 1.0/1.1]
}

body ImagePalette::fitCanvas { a_tag args } {

    if {$a_tag == "all"} {
	$itk_component(fit_wedge_tb) cancel noexecute
	bind $itk_component(segment_canvas) <Configure> [code $this fitCanvas all]
    } elseif {$a_tag == "segment"} {
	$itk_component(fit_all_tb) cancel noexecute
	bind $itk_component(segment_canvas) <Configure> [code $this fitCanvas segment]
    }

    foreach {x1 y1 x2 y2} [$itk_component(segment_canvas) bbox $a_tag] break
    set x_scale_factor [expr double([winfo width $itk_component(segment_canvas)]) / ($x2 - $x1)]
    set y_scale_factor [expr double([winfo height $itk_component(segment_canvas)]) / ($y2 - $y1)]

    if {$x_scale_factor < $y_scale_factor} {
	set scale_factor $x_scale_factor
    } else {
	set scale_factor $y_scale_factor
    }

    $itk_component(segment_canvas) move all [expr - $x1] [expr - $y1]
    $itk_component(segment_canvas) scale all 0 0 $scale_factor $scale_factor
    foreach {x1 y1 x2 y2} [$itk_component(segment_canvas) bbox $a_tag] break
    set x_shift [expr (([winfo width $itk_component(segment_canvas)] - $x2) - $x1) / 2]
    set y_shift [expr (([winfo height $itk_component(segment_canvas)] - $y2) - $y1) / 2]
    $itk_component(segment_canvas) move all $x_shift $y_shift
    # ... and repeat !!!
    foreach {x1 y1 x2 y2} [$itk_component(segment_canvas) bbox $a_tag] break
    set x_scale_factor [expr double([winfo width $itk_component(segment_canvas)]) / ($x2 - $x1)]
    set y_scale_factor [expr double([winfo height $itk_component(segment_canvas)]) / ($y2 - $y1)]

    if {$x_scale_factor < $y_scale_factor} {
	set scale_factor $x_scale_factor
    } else {
	set scale_factor $y_scale_factor
    }	
    $itk_component(segment_canvas) move all [expr - $x1] [expr - $y1]
    $itk_component(segment_canvas) scale all 0 0 $scale_factor $scale_factor
    foreach {x1 y1 x2 y2} [$itk_component(segment_canvas) bbox $a_tag] break
    set x_shift [expr (([winfo width $itk_component(segment_canvas)] - $x2) - $x1) / 2]
    set y_shift [expr (([winfo height $itk_component(segment_canvas)] - $y2) - $y1) / 2]
    $itk_component(segment_canvas) move all $x_shift $y_shift

}

# Segment canvas toolbutton methods ##########################################

body ImagePalette::makeDefaultSelection { } {
}

body ImagePalette::uncheckAll { } {
    foreach i_item [array names images_by_item] {
	uncheckImageInclusion $i_item
    }
}

body ImagePalette::checkAll { } {
    foreach i_item [array names images_by_item] {
	checkImageInclusion $i_item
    }
}

body ImagePalette::toggleCheckSegmentsToolbutton { args } {
    $itk_component(uncheck_segment_tb) cancel noexecute
    $itk_component(grab_canvas_tb) cancel noexecute
    foreach i_im [$::session getImages] {
	$itk_component(segment_canvas) bind $i_im <1> [code $this checkImageInclusion $items_by_image($i_im)]
    }
    bind $itk_component(segment_canvas) <ButtonPress-1> [code $this turnSegmentPaintingOn %x %y]
    bind $itk_component(segment_canvas) <ButtonRelease-1> [code $this turnSegmentPaintingOff]
    Cursor left_ptr_plus $itk_component(segment_canvas)
}

body ImagePalette::toggleUncheckSegmentsToolbutton { args } {
    $itk_component(check_segment_tb) cancel noexecute
    $itk_component(grab_canvas_tb) cancel noexecute
    foreach i_im [$::session getImages] {
       $itk_component(segment_canvas) bind $i_im <1> [code $this uncheckImageInclusion $items_by_image($i_im)]
    }
    bind $itk_component(segment_canvas) <ButtonPress-1> [code $this turnSegmentWipingOn %x %y]
    bind $itk_component(segment_canvas) <ButtonRelease-1> [code $this turnSegmentPaintingOff]
    Cursor left_ptr_minus $itk_component(segment_canvas)
}

body ImagePalette::toggleGrabCanvasToolbutton { args } {
    $itk_component(check_segment_tb) cancel noexecute
    $itk_component(uncheck_segment_tb) cancel noexecute
    
    bind $itk_component(segment_canvas) <ButtonPress-1> [code $this grabCanvas %x %y]
    bind $itk_component(segment_canvas) <ButtonRelease-1> [code $this releaseCanvas]
    $itk_component(segment_canvas) configure -cursor fleur
}

# Segment canvas interaction methods #####################################

body ImagePalette::turnSegmentPaintingOn { x y } {
    paintSegment $x $y
    bind $itk_component(segment_canvas) <Motion> [code $this paintSegment %x %y]  
}

body ImagePalette::turnSegmentPaintingOff { } {
    bind $itk_component(segment_canvas) <Motion> {}
    Cursor left_ptr_plus $itk_component(segment_canvas)
}

body ImagePalette::turnSegmentWipingOn { x y } {
    set last_cursor [$itk_component(segment_canvas) cget -cursor]
    wipeSegment $x $y
    bind $itk_component(segment_canvas) <Motion> [code $this wipeSegment %x %y]
    Cursor left_ptr_minus $itk_component(segment_canvas)
}

body ImagePalette::paintSegment { x y } {
    set l_closest_item [$itk_component(segment_canvas) find closest $x $y]
    set l_tags [$itk_component(segment_canvas) gettags $l_closest_item]
    if {[regexp {image\((\S*)\)} $l_tags match l_image]} {
	checkImageInclusion $items_by_image($l_image)
    }
}

body ImagePalette::wipeSegment { x y } {
    set l_closest_item [$itk_component(segment_canvas) find closest $x $y]
    set l_tags [$itk_component(segment_canvas) gettags $l_closest_item]
    if {[regexp {image\((\S*)\)} $l_tags match l_image]} {
	uncheckImageInclusion $items_by_image($l_image)
    }
}

body ImagePalette::grabCanvas { x y } {
    # Cancel set-view toolbuttons
    $itk_component(fit_all_tb) cancel noexecute
    $itk_component(fit_wedge_tb) cancel noexecute
    # Unbind canvas configure events
    bind $itk_component(segment_canvas) <Configure> {}
    # Store cursor for resetting after release
    set last_cursor [$itk_component(segment_canvas) cget -cursor]
    # Create marker relative to which things should be moved
    $itk_component(segment_canvas) create text $x $y -tags click_position
    # Set up motion bindings to move items
    bind $itk_component(segment_canvas) <Motion> [code $this moveCanvasItems %x %y]
    # Set the canvas cursor to the 4-way arrow
    $itk_component(segment_canvas) configure -cursor fleur
}

body ImagePalette::releaseCanvas { } {
    $itk_component(segment_canvas) delete click_position
    bind $itk_component(segment_canvas) <Motion> {}
    $itk_component(segment_canvas) configure -cursor $last_cursor
}

body ImagePalette::moveCanvasItems { x y } {
    foreach {l_x0 l_y0} [$itk_component(segment_canvas) coords click_position] break
    $itk_component(segment_canvas) move all [expr $x - $l_x0] [expr $y - $l_y0]
}

body ImagePalette::updateProcessWizard { } {
    set l_chosen_images {}
    set l_chosen_image_paths {}
    set l_sorted_image_paths {}
    foreach i_item [array names images_by_item] {
	if {[$itk_component(image_tree) item state get $i_item CHECKED]} {
	    lappend l_chosen_image_paths $image_paths_by_item($i_item)
	}
    }
    if {[llength $l_chosen_image_paths] != 0} {
	set items_in_chosen_image_paths [llength $l_chosen_image_paths]
	if {$items_in_chosen_image_paths > 1 } {
	    set l_sorted_image_paths [lsort $l_chosen_image_paths]
	} elseif {$items_in_chosen_image_paths == 1} {
	    set l_sorted_image_paths $l_chosen_image_paths
	}
    }
    
    set l_sorted_images {}
    foreach i_path $l_sorted_image_paths {
	lappend l_sorted_images [Image::getImageByPath $i_path]
    }
    $processing_wizard updateImages $l_sorted_images
}

# #########################################################
