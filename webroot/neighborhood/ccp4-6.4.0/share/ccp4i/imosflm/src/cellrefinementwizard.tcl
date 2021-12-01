# $Id: cellrefinementwizard.tcl,v 1.13 2012/03/26 16:36:38 ccb Exp $
package provide cellrefinementwizard 1.0

class Cellrefinementwizard {
    inherit Processingwizard

    private variable summary_measure "RMS residual"
    private variable l_sectors_first ""
    private variable l_sectors_last ""

    # variable to indicate whether cell refinement succeeded or not
    # used to know whether to add history event in finishedProcessing
    #private variable cell_refinement_success "0"

    public method restoreGrid
    public method launch
    public method clear

    # Disabling / enabling methods
    private method toggleAbility

    # Image selection methods
    # private method requestImageSelection
    public method processSegmentSetupResponse

    # Auxiliary processing methods
    private method getScript
    private method newResults
    private method copyResults
    private method defaultImageSelection
    #public method updateSectorImages

    # Feedback processing methods
    public method processCellRefinementSummary
    public method finishedProcessing

    # Feedback processing methods
    private method initializeTreesAndGraphs
    private method refreshCells
    private method updateSummaryGraph

    constructor { args } { }
}

body Cellrefinementwizard::constructor { args } {
    set processing_stage "cell_refinement"

    # Heading
    $itk_component(heading_l) configure -text "Cell refinement"

    itk_component add exclude_ice_tb {
	SettingToolbutton $itk_component(toolbar).eitb "resolution_exclude_ice" \
	    -image ::img::exclude_ice16x16 \
	    -activeimage ::img::exclude_ice_on16x16 \
	    -balloonhelp "Exclude ice rings during cell refinement"
    }

    pack $itk_component(exclude_ice_tb) \
 	-side left \
	-padx 2

    # Add image numbers selector
    itk_component add image_numbers {
	ImagenumbersSingle $itk_component(image_numbers_frame).in \
	    -command [code $this getImageList]
    }
    pack $itk_component(image_numbers) -fill both -expand 1

    itk_component add summary_frame {
	frame $itk_interior.normal.rf.sf
    }

    itk_component add summary_combo {
	Combo $itk_interior.normal.rf.sf.sc \
	    -width 6 \
	    -items [list "RMS residual" "Distance" "Y scale"] \
	    -editable 0 \
	    -highlightcolor black \
	    -state disabled \
	    -command [code $this updateSummaryGraph]
	
    }

    itk_component add summary_graph {
	canvas $itk_interior.normal.rf.sf.sg \
	    -background white \
	    -relief sunken \
	    -height $row_height \
	    -borderwidth 2 \
	    -highlightthickness 0
    }
    bind $itk_component(summary_graph) <4> [code $this zoom $itk_component(summary_frame)]
    bind $itk_component(summary_graph) <5> [code $this restoreGrid]
    bind $itk_component(summary_graph) <Control-1> [code $this toggleZoom $itk_component(summary_frame)]
    bind $itk_component(summary_graph) <Shift-1> [code $this toggleZoom $itk_component(summary_frame)]

    itk_component add cell_tree {
	treectrl $itk_interior.normal.rf.ct \
	    -showroot 0 \
	    -showline 0 \
	    -showbutton 0 \
	    -selectmode single \
	    -width 410 \
	    -height 72 \
	    -itemheight 18
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    } 

    $itk_component(cell_tree) column create -text Cell -justify left -minwidth 100 -expand 1 ;#-itembackground {"\#ffffff" "\#e8e8e8"}
    $itk_component(cell_tree) column create -text "a" -justify right -minwidth 50 -expand 1 
    $itk_component(cell_tree) column create -text "b" -justify right -minwidth 50 -expand 1
    $itk_component(cell_tree) column create -text "c" -justify right -minwidth 50 -expand 1
    $itk_component(cell_tree) column create -text "\u03b1" -justify right -minwidth 50 -expand 1
    $itk_component(cell_tree) column create -text "\u03b2"  -justify right -minwidth 50 -expand 1
    $itk_component(cell_tree) column create -text "\u03b3"  -justify right -minwidth 50 -expand 1

    $itk_component(cell_tree) element create e_icon image -image ::img::cell
    $itk_component(cell_tree) element create e_text text -fill {white selected}
    $itk_component(cell_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }

    $itk_component(cell_tree) style create s1
    $itk_component(cell_tree) style elements s1 { e_highlight e_icon e_text }
    $itk_component(cell_tree) style layout s1 e_icon -expand ns -padx {0 6}
    $itk_component(cell_tree) style layout s1 e_text -expand ns
    $itk_component(cell_tree) style layout s1 e_highlight -union [list e_icon e_text] -iexpand nse -ipadx 2
    
    $itk_component(cell_tree) style create s2
    $itk_component(cell_tree) style elements s2 {e_highlight e_text}
    $itk_component(cell_tree) style layout s2 e_text -expand ns
    $itk_component(cell_tree) style layout s2 e_highlight -union [list e_text] -iexpand nsew -ipadx 2


    set margin 7

    grid $itk_component(summary_frame) -row 1 -column 5 -sticky news -pady $margin
    pack $itk_component(summary_combo) -fill x
    pack $itk_component(summary_graph) -fill both -expand 1

    grid x $itk_component(cell_tree) - - - - -sticky news -pady [list 0 $margin]

    eval itk_initialize $args

}

body Cellrefinementwizard::restoreGrid { } {
    if {$zoomed} {
	Processingwizard::restoreGrid
	grid $itk_component(summary_frame) -row 1 -column 5 -sticky news -pady $margin
	grid x $itk_component(cell_tree) - - - - -sticky news -pady [list 0 $margin]
    }
}

body Cellrefinementwizard::launch { } {
    
    # Make default image selection whatever in case numbers left in field are not appropriate
    if {[$itk_component(image_numbers) getContent] == {}} {
	#puts "Mosflm busy: [$::mosflm busy] cannot choose default images"
	if {![$::mosflm busy]} {
	    defaultImageSelection
	}
    }
    
    # Show stage
    grid $itk_component(hull) -row 0 -column 1 -sticky nswe

    # show toolbars
    pack $itk_component(toolbar) -in [.c component toolbar_frame] -side left

    # Reset unzoomed view
    restoreGrid
}

body Cellrefinementwizard::clear { } {

    # Clear general processing wizard components
    Processingwizard::clear

    # Clear summary graph
    $itk_component(summary_graph) delete all
    bind $itk_component(summary_graph) <Configure> {}

    # clear previous cell tree items
    $itk_component(cell_tree) item delete all
    
}

body Cellrefinementwizard::toggleAbility { a_state } {
    Processingwizard::toggleAbility $a_state
    $itk_component(default_selection_tb) configure -state $a_state
}

#body Cellrefinementwizard::requestImageSelection { } {
#    .c busy "Calculating optimal segments for cell refinement"
#    if { [llength [$::session getSectors]] > 0 } {
#	foreach i_sector [$::session getSectors] {
#	    set l_first_sector $i_sector
#	    puts "dIS: Valid sector: [$i_sector getTemplate]"
#	}
#    }
#    $::mosflm getCellRefinementSegments
#}

body Cellrefinementwizard::processSegmentSetupResponse { a_dom } {
    set l_image_list {}
    # Check on status of task
    set status_code [$a_dom selectNodes string(/segment_setup_response/status/code)]
    if {$status_code == "error"} {
	set message [$a_dom selectNodes string(/segment_setup_response/status/message)]
	#if { [string compare [string range $message 0 32] "Mosaic spread is too small (0.00)"] == 0 } {
	#    if { [$::session forceMosaicityEstimation] } {
	#	requestImageSelection
	#    } else {
	#	# Warn user
	#    }
	#} else {
	    .m confirm \
		-type "1button" \
		-button1of1 "Dismiss" \
		-text "$message"	    
	#}
    } else {
	# Loop through segments - pick up first and last tranches of images
	# get list of sectors - we use the first segment from the first sector and the 
	# last segment from the last sector
	# 
	set sector_template [$a_dom selectNodes string(/segment_setup_response/template)]
	#puts "sector_template $sector_template"

	# get list of segments
	set segment_ilist [lrange [$a_dom selectNodes //segment] 0 end]
	#puts "segment inode list: $segment_ilist"
	set node_num 0
	set num_images 0
	foreach i_node $segment_ilist {
	    incr node_num
	    set l_start [$i_node selectNodes normalize-space(start)]
	    set l_range [$i_node selectNodes normalize-space(range)]
	    #puts "Node num, start, range: $node_num, $l_start, $l_range"
	    for { set i_image_number $l_start} { $i_image_number < [expr $l_start + $l_range] } { incr i_image_number } {
		set l_image [$::session getImageByTemplateAndNumber $sector_template $i_image_number]
		incr num_images
		if { $l_image != "" } {
		    lappend l_image_list $l_image
		    #puts "$num_images: $i_image_number"
		}
	    }
	}
	# Check list is as long as the number of images returned by the segment setup response
	#puts "l_image_list should contain $num_images images"
	#puts $l_image_list
	if { [llength $l_image_list] == $num_images } {
	    updateImages $l_image_list
	}
    }
    enable
    .c idle
}

body Cellrefinementwizard::newResults { args } {
    return [namespace current]::[eval Cellrefinementresults \#auto "new" $args]
}

body Cellrefinementwizard::copyResults { a_results } {
    return [namespace current]::[Cellrefinementresults \#auto "copy" $a_results]
}

body Cellrefinementwizard::getScript { an_image_list } {
    
    set l_script ""

    # Get the first valid matrix
    set l_first_valid_matrix ""
    foreach i_sector [$::session getSectors] {
	set l_matrix [$i_sector getMatrix]
	if {[$l_matrix isValid]} {
	    set l_first_valid_matrix $l_matrix
	    break
	}
    }

    # Provide experiment settings

    # Masks
    #append l_script "limits remove all\n"
    foreach i_mask [Mask::getMasks] {
	set l_coords [$i_mask getMmCoords]
	if {[llength $l_coords] == 8} {
	    append l_script "limits quadrilateral $l_coords\n"
	}
    }

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

    append l_script "DISTORTION YSCALE [$::session getParameterValue yscale] TILT [expr [$::session getParameterValue tilt] * 100] TWIST [expr [$::session getParameterValue twist] * 100] \n"	

    if {[$::session getParameterValue "overload_cutoff"] != ""} {
	append l_script "OVERLOAD CUTOFF [$::session getParameterValue "overload_cutoff"]\n"
    }

    append l_script "dispersion [$::session getParameterValue dispersion]\n"
    if {[$::session getParameterValue "xray_source"] == "lab"} {
	append l_script "polarisation pinhole\n"
    } else {
	append l_script "polarisation synchrotron [$::session getParameterValue "polarization"]\n"
    }

    # Provide matrix and spacegroup (indexing results)

    # Matrix + spacegroup - need to be provided for when user loads a session
    #  that they've previously indexed 
    append l_script "symmetry [$::session reportSpacegroup]\n"
    append l_script "mosaicity [$::session getMosaicity] BLOCKSIZE [$::session getParameterValue mosaicblock]\n"

    set l_first [lindex $an_image_list 0]

    # Tell mosflm where to write output (hklout and genfile)
    set l_mtz_file [$::session getParameterValue mtz_file]
    if {$l_mtz_file == ""} {
	set l_mtz_file [$l_first makeAuxiliaryFileName "mtz"]
	$::session updateSetting "mtz_file" $l_mtz_file 1 1
   }
    # Tell mosflm which directory to write hklout
    set l_mtz_directory [$::session getParameterValue mtz_directory]
    if {$l_mtz_directory != ""} {
	append l_script "mtzdirectory $l_mtz_directory\n"
    }

    # Tell mosflm where to write output (hklout and genfile)
    append l_script "hklout $l_mtz_file\n"

    # Integration settings

    # Apply resolution limits
    append l_script "resolution exclude none\n"
    append l_script "[$::session getResolutionCommand]\n"

    # Profile command
    append l_script "[$::session getProfileCommand]\n"

    # Set backstop
    append l_script "[$::session getBackstopCommand]\n"
    
    # Apply separation limits
    if {[$::session separationCommandRequired]} {
	append l_script "[$::session getSeparationCommand]\n"
    }

    if {[$::session getParameterValue "donot_refine_detector"]} {
	    append l_script "NOREFINE\n"
    } else {
	    append l_script "NOREFINE OFF\n"
    }

    # Apply refinement fixes
    append l_script "[$::session getRefinementCommand cell_refinement]\n"
    # Apply postrefinement fixes
    append l_script "[$::session getPostrefinementCommand cell_refinement]\n"

    # Postrefinement command
    set l_image_image_pair_list_list [$::mosflm makeProcessingPairLists $an_image_list]
    set l_num_segments 0
    foreach i_image_image_pair_list $l_image_image_pair_list_list {
	foreach { l_image l_image_pair_list } $i_image_image_pair_list break
	foreach i_image_pair $l_image_pair_list {
	    incr l_num_segments
	}
    }
    append l_script "POSTREF SEGMENT $l_num_segments\n"

    # Loop through segments
    set l_sent_matrix 0

    foreach i_image_image_pair_list $l_image_image_pair_list_list {
	foreach { l_image l_image_pair_list } $i_image_image_pair_list break
	if {!$l_sent_matrix} {
	    set l_matrix [[$l_image getSector] getMatrix]
	    if {[$l_matrix isValid]} {
		append l_script "matrix [$l_matrix listMatrix]\n"
	    } else {
		append l_script "matrix [$l_first_valid_matrix listMatrix]\n"
	    }
	    set l_sent_matrix 1
	}
	set l_detector [$::session getFullDetectorInformation]
	if { $l_detector != "" } {
	    append l_script "$l_detector\n"
	}
    
	append l_script "directory [$l_image getDirectory]\n"
	append l_script "template [$l_image getTemplate]\n"
	foreach i_image_pair $l_image_pair_list {
	    foreach {l_start l_end} $i_image_pair {
		set t_image [$::session getImageByTemplateAndNumber [$l_image getTemplate] $l_start]
		append l_script "misset [$t_image getMissets]\n"
		foreach { l_phi_start l_phi_end } [$t_image getPhi] break
		append l_script "process $l_start $l_end start $l_phi_start angle [expr $l_phi_end - $l_phi_start]\n"
		append l_script "run\n"
	    }
	}
    }

    append l_script "exit\n"

    return $l_script
}

body Cellrefinementwizard::defaultImageSelection { } {
    disable
    .c busy "Calculating optimal segment(s) for refining cell"
    set l_sector [$::session getCurrentSector]
    #puts "getCurrentSector gives $l_sector"
    $::mosflm getCellRefinementSegments $l_sector
}

body Cellrefinementwizard::initializeTreesAndGraphs { } {

    Processingwizard::initializeTreesAndGraphs
    
    updateSummaryGraph rms_positional_error
    refreshCells

}

body Cellrefinementwizard::refreshCells { } {
    # clear previous cell tree items
    $itk_component(cell_tree) item delete all

    # for each cell type
    foreach i_cell_type { initial final } {
	set l_cell [$results getCell $i_cell_type]
	#puts "get the $i_cell_type cell from the results object - $l_cell"
	if {$l_cell != ""} {
	# if the cell was there add it to the tree	    
	    foreach { l_a l_b l_c l_alpha l_beta l_gamma } [$l_cell listCell] break
	    set l_item [$itk_component(cell_tree) item create]
	    $itk_component(cell_tree) item style set $l_item 0 s1 1 s2 2 s2 3 s2 4 s2 5 s2 6 s2
	    $itk_component(cell_tree) item text $l_item 0 "[string totitle $i_cell_type]" 1 $l_a 2 $l_b 3 $l_c 4 $l_alpha 5 $l_beta 6 $l_gamma
	    $itk_component(cell_tree) item lastchild root $l_item
	    if {$i_cell_type == "final"} {
		# if the final cell has been added, add the sd's
		foreach { l_a l_b l_c l_alpha l_beta l_gamma } [$results getCellStdDev] break
		set l_item [$itk_component(cell_tree) item create]
		$itk_component(cell_tree) item style set $l_item 0 s2 1 s2 2 s2 3 s2 4 s2 5 s2 6 s2
		$itk_component(cell_tree) item text $l_item 0 "Std dev" 1 $l_a 2 $l_b 3 $l_c 4 $l_alpha 5 $l_beta 6 $l_gamma
		$itk_component(cell_tree) item lastchild root $l_item
	    }
	}
    }
}

body Cellrefinementwizard::processCellRefinementSummary { a_dom } {

    # Check on status of task
    set status_code [$a_dom selectNodes string(/cell_refine_response/status/code)]
    if {$status_code == "error"} {
	#set cell_refinement_success "0"
	.m configure \
	    -type "1button" \
	    -text "Cell refinement failed, sorry.\n[$a_dom selectNodes string(/cell_refine_response/status/message)]" \
	    -button1of1 "Dismiss"
	if {[.m confirm]} {
	    [.c component cell_refinement] resetControls
	    # update controller status?
	    .c enable
	}
    } else {
	# extract final cell
	set l_final_cell_data {}
	lappend l_final_cell_data [$a_dom selectNodes normalize-space(//final_cell/cell/a)]
	lappend l_final_cell_data [$a_dom selectNodes normalize-space(//final_cell/cell/b)]
	lappend l_final_cell_data [$a_dom selectNodes normalize-space(//final_cell/cell/c)]
	lappend l_final_cell_data [$a_dom selectNodes normalize-space(//final_cell/cell/alpha)]
	lappend l_final_cell_data [$a_dom selectNodes normalize-space(//final_cell/cell/beta)]
	lappend l_final_cell_data [$a_dom selectNodes normalize-space(//final_cell/cell/gamma)]
	$results setFinalCell $l_final_cell_data
	
	# hrp 29.09.2006 extract AMAT
	set l_final_matrix {}
	lappend l_final_matrix [$a_dom selectNodes normalize-space(//a_matrix/a11)]
	lappend l_final_matrix [$a_dom selectNodes normalize-space(//a_matrix/a12)]
	lappend l_final_matrix [$a_dom selectNodes normalize-space(//a_matrix/a13)]
	lappend l_final_matrix [$a_dom selectNodes normalize-space(//a_matrix/a21)]
	lappend l_final_matrix [$a_dom selectNodes normalize-space(//a_matrix/a22)]
	lappend l_final_matrix [$a_dom selectNodes normalize-space(//a_matrix/a23)]
	lappend l_final_matrix [$a_dom selectNodes normalize-space(//a_matrix/a31)]
	lappend l_final_matrix [$a_dom selectNodes normalize-space(//a_matrix/a32)]
	lappend l_final_matrix [$a_dom selectNodes normalize-space(//a_matrix/a33)]
	# I don't have a clue how to set the matrix using the methods! new method 
	# setFinalMatrix
	$results setFinalMatrix $l_final_matrix

	# extract summary data
	foreach i_cycle_node [$a_dom selectNodes {//refinement_cycle}] {
	    set l_cycle [$i_cycle_node selectNodes normalize-space(cycle_number)]
	    set l_rms_residuals {}
	    set l_pixel_ratios {}
	    set l_distances {}
	    foreach i_values_node  [$i_cycle_node selectNodes refined_values] {
		lappend l_rms_residuals [$i_values_node selectNodes normalize-space(rms_positional_error)]
		lappend l_pixel_ratios [$i_values_node selectNodes normalize-space(pixel_ratio)]
		lappend l_distances [$i_values_node selectNodes normalize-space(crystal_to_detector_distance)]
	    }
	    $results recordSummaryData "rms_positional_error" $l_cycle $l_rms_residuals
	    $results recordSummaryData "pixel_ratio" $l_cycle $l_pixel_ratios
	    $results recordSummaryData "distance" $l_cycle $l_distances
	}
	$itk_component(summary_combo) configure -state normal
	$itk_component(summary_combo) choose 0

	# Update graphs
	updateSummaryGraph
	refreshCells

    }    
}

body Cellrefinementwizard::updateSummaryGraph { { a_measure "" } } {
    # Update summary measure if provided
    if {$a_measure != ""} {
	set summary_measure $a_measure
    }
    if {$summary_measure != ""} {
	# Set parameter name from description
	if {$summary_measure == "RMS residual"} {
	    set l_measure "rms_positional_error"
	} elseif {$summary_measure == "Distance"} {
	    set l_measure "distance"
	} elseif {$summary_measure == "Y scale"} {
	    set l_measure "pixel_ratio"
	} else {
	    set summary_measure "RMS residual"
	    set l_measure "rms_positional_error"
	}
	if {$results != ""} {
	    # Get datasets from results object
	    set l_data_sets [$results getSummaryDataSets $l_measure]
	    if {[llength $l_data_sets] != 0} {
		# Calculate graph window
		set window [list 10 10]
		lappend window [expr [winfo width $itk_component(summary_graph)] - 10]
		lappend window [expr [winfo height $itk_component(summary_graph)] - 10]
		# Plot Graph
		set image_data_set [$results getImageDataSet]
		LineGraph \#auto $itk_component(summary_graph) $window "id" $image_data_set $l_data_sets
		# Remove the dataset objects to ease memory overheads
		#puts "Deleting $image_data_set"
		delete object $image_data_set
		foreach ds $l_data_sets {
		    delete object $ds
		    #puts "Deleting $ds"
		}
		$itk_component(summary_combo) configure -state "normal"
	    } else {
		$itk_component(summary_graph) delete all
		$itk_component(summary_combo) configure -state "disabled"
	    }
	} else {
	    $itk_component(summary_graph) delete all
	    $itk_component(summary_combo) configure -state "disabled"
	    }   
    }
    bind $itk_component(summary_graph) <Configure> [code $this updateSummaryGraph]
}

body Cellrefinementwizard::finishedProcessing { } {
    $::session addHistoryEvent CellrefinementEvent "Cell_refinement" $results
    Processingwizard::finishedProcessing
}

usual Cellrefinementwizard { }

