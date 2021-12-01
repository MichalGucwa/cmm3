# $Id: history.tcl,v 1.12 2012/05/21 13:23:39 ccb Exp $
package provide history 1.0

# CLASS Event ###################################################

class Event {
    
    # Member variables

    protected variable name "Unknown"
    protected variable subcategory "Unknown"
    protected variable category "Unknown"
    protected variable reason "Unknown"
    protected variable state "done"

    # Methods

    public method undo
    public method redo

    protected method makeInverse { } { } ; # virtual
    protected method makeDuplicate { } { } ; # virtual
    protected method reverse { } { } ; # virtual
    protected method repeat { } { } ; # virtual

    public method isDone
    public method isReversible
    public method isRepeatable

    public method getName 
    public method getSubcategory
    public method getCategory
    public method getDescription ; # virtual

    public method getEventIcon
    public method getSubcategoryIcon
    public method getCategoryIcon

    public method serialize ; # virtual

    constructor { } { }
}

body Event::undo { } {
    # Reverse the effect of the event
    reverse
    # Mark state as "undone"
    set state "undone"
}

body Event::redo { } {
    # Repeat the effect of the event
    repeat
    # Mar state as "done"
    set state "done"
}

body Event::isDone { } {
    if {$state == "done"} {
	return 1
    } else {
	return 0
    }
}

body Event::isReversible { } {
    # events will NOT be reversable, unless explicitly overridden
    return 0
}

body Event::isRepeatable { } {
    # events will NOT be repeatable, unless explicitly overridden
    return 0
}

body Event::getName { } { return $name }
body Event::getSubcategory { } { return [regsub -all {_} $subcategory { }] } 
body Event::getCategory { } {return $category }

body Event::getEventIcon { } { return [getSubcategoryIcon] }
body Event::getSubcategoryIcon { } { return  ::img::event_icon($subcategory,cat,done)} 
body Event::getCategoryIcon { } {return ::img::event_icon($category,done) }

# CLASS ImageAddEvent ###########################################

class ImageAddEvent {
    inherit Event
    
    # member variables
    private variable image_files {}

    # Methods    
    public method reverse
    public method repeat
    public method makeInverse
    public method makeDuplicate
    public method isReversible
    public method isRepeatable
    public method getDescription
    public method serialize

    public method getSubcategoryIcon

    constructor { a_method args } {
	if {$a_method == "build"} {
	    set reason [lindex $args 0]
	    foreach i_image [lindex $args 1] {
		set new_image_file [$i_image getFullPathName]
		lappend image_files $new_image_file
	    }
	} elseif {$a_method == "xml"} {
	    set reason [$args getAttribute reason]
	    set state [$args getAttribute state]
	    set image_files [split [$args getAttribute image_files]]
	} else {
	    error "Bad method of building ImageAddEvent!"
	}
	set category "Images"
	set subcategory "Added images"
	set name "[file tail [lindex $image_files 0]]"
    }
}

body ImageAddEvent::reverse { } {
    # delete the images that were added
    $::session deleteImages $image_files
}

body ImageAddEvent::repeat { } {
    # add the images that were previously added
    foreach i_image_file $image_files {
	$::session addImage $i_image_file
    }
}

body ImageAddEvent::makeInverse { } {
    # get list of image objects added
    set l_images {}
    foreach i_image_file $image_files {
	lappend l_images [Image::getImageByPath $i_image_file]
    }
    # Create ImageDeleteEvent with same images
    return [namespace current]::[ImageDeleteEvent \#auto "build" "User" $l_images]
}

body ImageAddEvent::makeDuplicate { } {
    # get a list of image objects added
    set l_images {}
    foreach i_image_file $image_files {
	lappend l_images [Image::getImageByPath $i_image_file]
    }
    # Create ImageAddEvent with same iamges
    return [namespace current]::[ImageAddEvent \#auto "build" "User" $l_images]
}

body ImageAddEvent::isReversible { } {
    # Reversable if all images still exists in session
    foreach i_image_file $image_files {
	if {[Image::getImageByPath $i_image_file] == ""} {
	    return 0
	}
    }
    return 1
}

body ImageAddEvent::isRepeatable { } {
    # Repeatable if all images have been deleted from session
    foreach i_image_file $image_files {
	if {[Image::getImageByPath $i_image_file] != ""} {
	    return 0
	}
    }
    return 1
}

body ImageAddEvent::getDescription { } {
    # Build a list of image numbers from the images added
    set num_list {}

# hrp 13.09.2007
# I don't understand - "image_files" only ever seems to have a single image in it, and 
# the following code is unnecessary!
#    foreach i_image_file $image_files {
#	puts "History(1): [escapeWhiteSpace $i_image_file]"
#	lappend num_list [lindex [Image::parseFilename $i_image_file] 1]
#	puts "num_list is now $num_list"
#    }
    lappend num_list [lindex [Image::parseFilename $image_files] 1]
#    set l_first_image_file [lindex $image_files 0]
    set l_first_image_file $image_files
    # Begin description with template..
    set description "Added [lindex [Image::parseFilename $l_first_image_file] 0] image"
    # Pluralize "image" if necessary
    if {[llength $image_files] > 1} {
	append description "s"
    }
    # Add abbreivated number list (could use utitlity proc???)
    append description " [lindex $num_list 0]"
    set current_num [lindex $num_list 0]
    set l_run 0
    foreach i_num [lrange $num_list 1 end] {
	if {$i_num == ($current_num + 1)} {
	    set l_run 1
	} else {
	    if {$l_run == 1} {
		append description "-$current_num"
		set l_run 0
	    }
	    append description ", $i_num"
	}
	set current_num $i_num
    }
    if {$l_run == 1} {
	append description "-$current_num"
    }
    # replace last comma in abbreviated list with "and"
    regsub {^(.+),([^,]+)$} $description {\1 and\2} description
    append description "."
    return $description
}

body ImageAddEvent::serialize { } {
    # hrp 13.09.2007. I _really_ don't understand this! image_files is supposed to
    # to be a list, but it never has more than one member. Or does it? Anyway, to 
    # avoid having the {} that confuse the parser when reading in a save file, 
    # my plan is just to use the first item in the list all the time.
    return "<event type=\"ImageAddEvent\" reason=\"$reason\" state=\"$state\" image_files=\"[lindex $image_files 0]\"/>"
}

body ImageAddEvent::getSubcategoryIcon { } {
    return ::img::add_image
}

# CLASS ImageDeleteEvent ###########################################

class ImageDeleteEvent {
    inherit Event
    
    # member variables
    private variable image_files {}

    # methods
    public method reverse
    public method repeat
    public method makeInverse
    public method makeDuplicate
    public method isReversible
    public method isRepeatable
    public method getDescription
    public method serialize

    public method getSubcategoryIcon

    constructor { a_method args } {
	if {$a_method == "build"} {
	    set reason [lindex $args 0]
	    foreach i_image [lindex $args 1] {
		set new_image_file [$i_image getFullPathName]
		lappend image_files $new_image_file
	    }
	} elseif {$a_method == "xml"} {
	    set reason [$args getAttribute reason]
	    set state [$args getAttribute state]
	    set image_files [split [$args getAttribute image_files]]
	}
	set category "Images"
	set subcategory "Deleted images"
	set name "[file tail [lindex $image_files 0]]"
    }
}

body ImageDeleteEvent::reverse { } {
    $::session deleteImages $image_files
}

body ImageDeleteEvent::repeat { } {
    foreach i_image_file $image_files {
	$::session addImage $i_image_file
    }
}

body ImageDeleteEvent::makeInverse { } {
    set l_images {}
    foreach i_image_file $image_files {
	lappend l_images [Image::getImageByPath $i_image_file]
    }
    return [namespace current]::[ImageAddEvent \#auto "build" "User" $l_images]
}

body ImageDeleteEvent::makeDuplicate { } {
    set l_images {}
    foreach i_image_file $image_files {
	lappend l_images [Image::getImageByPath $i_image_file]
    }
    return [namespace current]::[ImageDeleteEvent \#auto "build" "User" $l_images]
}

body ImageDeleteEvent::isReversible { } {
    # Reversable if all images are still deleted
    foreach i_image_file $image_files {
	if {[Image::getImageByPath $i_image_file] != ""} {
	    return 0
	}
    }
    return 1
}

body ImageDeleteEvent::isRepeatable { } {
    # Repeatable if all images exists
    foreach i_image_file $image_files {
	if {[Image::getImageByPath $i_image_file] == ""} {
	    return 0
	}
    }
    return 1
}

body ImageDeleteEvent::getDescription { } {
    set num_list {}
    foreach i_image_file $image_files {
	lappend num_list [lindex [Image::parseFilename $i_image_file] 1]
    }
    set l_first_image_file [lindex $image_files 0]
    set description "Removing [lindex [Image::parseFilename $l_first_image_file] 0] image"
    if {[llength $image_files] > 1} {
	append description "s"
    }
    append description " [lindex $num_list 0]"
    set current_num [lindex $num_list 0]
    set l_run 0
    foreach i_num [lrange $num_list 1 end] {
	if {$i_num == ($current_num + 1)} {
	    set l_run 1
	} else {
	    if {$l_run == 1} {
		append description "-$current_num"
		set l_run 0
	    }
	    append description ", $i_num"
	}
	set current_num $i_num
    }
    if {$l_run == 1} {
	append description "-$current_num"
    }
    regsub {^(.+),([^,]+)$} $description {\1 and\2} description
    append description "."
    return $description
}

body ImageDeleteEvent::serialize { } {
    return "<event type=\"ImageDeleteEvent\" reason=\"$reason\" state=\"$state\" image_files=\"$image_files\"/>"
}

body ImageDeleteEvent::getSubcategoryIcon { } {
    return ::img::delete_image
}


# CLASS ParameterUpdateEvent ####################################


class ParameterUpdateEvent {
    inherit Event
    
    private common parameter_group
    private common parameter_name
    public proc initializeGroupsAndNames
    
    # member variables
    private variable group ""
    private variable parameter ""
    private variable old_value ""
    private variable new_value ""
    
    # Methods    
    public method reverse
    public method repeat
    public method makeInverse
    public method makeDuplicate
    public method isReversible
    public method isRepeatable
    public method getDescription
    public method serialize

    public method getEventIcon
    public method getParameter

    constructor { a_method args } {
	if {$a_method == "build"} {
	    set reason [lindex $args 0]
	    set group [lindex $args 1]
	    set parameter [lindex $args 2]
	    set old_value [lindex $args 3]
	    set new_value [lindex $args 4]
	} elseif {$a_method == "xml"} {
	    set reason [$args getAttribute reason]
	    set group [$args getAttribute group]
	    set parameter [$args getAttribute parameter]
	    set old_value [$args getAttribute old_value]
	    set new_value [$args getAttribute new_value]
	}
	set category $reason
	set subcategory $parameter_group($parameter)
	set name $parameter_name($parameter)
    }

}

body ParameterUpdateEvent::initializeGroupsAndNames { } {
    set parameter_group(project) Experiment_settings
    set parameter_group(crystal) Experiment_settings
    set parameter_group(dataset) Experiment_settings
    set parameter_group(title) Experiment_settings
    set parameter_group(xray_source) Experiment_settings
    set parameter_group(beam_x) Experiment_settings
    set parameter_group(beam_y) Experiment_settings
    set parameter_group(beam_y_corrected) Experiment_settings
    set parameter_group(distance) Experiment_settings
    set parameter_group(divergence_x) Experiment_settings
    set parameter_group(divergence_y) Experiment_settings
    set parameter_group(dispersion) Experiment_settings
    set parameter_group(polarization) Experiment_settings
    set parameter_group(two_theta) Experiment_settings
    set parameter_group(pixel_size) Experiment_settings
    set parameter_group(header_size) Experiment_settings
    set parameter_group(image_height) Experiment_settings
    set parameter_group(image_width) Experiment_settings
    set parameter_group(gain) Experiment_settings
    set parameter_group(adcoffset) Experiment_settings
    set parameter_group(bias) Experiment_settings
    set parameter_group(yscale) Experiment_settings
    set parameter_group(tilt) Experiment_settings
    set parameter_group(twist) Experiment_settings
    set parameter_group(tangential_offset) Experiment_settings
    set parameter_group(radial_offset) Experiment_settings
    set parameter_group(ccomega) Experiment_settings
    set parameter_group(wavelength) Experiment_settings
    set parameter_group(reverse_phi) Experiment_settings
    set parameter_group(detector_manufacturer) Experiment_settings
    set parameter_group(detector_omega) Experiment_settings
    set parameter_group(detector_model) Experiment_settings
    set parameter_group(detector_serno) Experiment_settings
    set parameter_group(spiral) Experiment_settings
    set parameter_group(invertx) Experiment_settings
    #    set parameter_group(expert_detector) Experiment_settings
    set parameter_group(overload_cutoff) Experiment_settings
    
    set parameter_group(mosaicity) Crystal
    set parameter_group(mosaicblock) Crystal
    
    set parameter_group(backstop_x) Processing_options
    set parameter_group(backstop_y) Processing_options
    set parameter_group(backstop_radius) Processing_options
    
    set parameter_group(threshold) Processing_options
    set parameter_group(search_area_min_radius) Processing_options
    set parameter_group(search_area_max_radius) Processing_options
    set parameter_group(spot_separation_x) Processing_options
    set parameter_group(spot_separation_y) Processing_options
    set parameter_group(fix_separation) Processing_options
    set parameter_group(separation_close) Processing_options
    set parameter_group(spot_splitting_x) Processing_options
    set parameter_group(spot_splitting_y) Processing_options
    set parameter_group(spot_size_min_x) Processing_options
    set parameter_group(spot_size_min_y) Processing_options
    set parameter_group(spot_size_max_x) Processing_options
    set parameter_group(spot_size_max_y) Processing_options
    set parameter_group(exclusion_segment_horizontal) Processing_options
    set parameter_group(exclusion_segment_vertical) Processing_options
    set parameter_group(bbox_orientation) Processing_options
    set parameter_group(bbox_offset) Processing_options
    set parameter_group(minpix) Processing_options
    set parameter_group(local_background) Processing_options
    set parameter_group(local_background_box_size_x) Processing_options
    set parameter_group(local_background_box_size_y) Processing_options
    set parameter_group(max_unresolved_peaks) Processing_options
    set parameter_group(auto_resolution) Processing_options
    set parameter_group(auto_ring) Processing_options
    set parameter_group(spot_rms_var) Processing_options
    set parameter_group(spot_anisotropy) Processing_options
    
    set parameter_group(exclude_ice) Processing_options
    set parameter_group(exclude_auto) Processing_options
    set parameter_group(fix_distance_indexing) Processing_options
    set parameter_group(fix_cell_indexing) Processing_options
    set parameter_group(fix_max_cell_edge) Processing_options
    set parameter_group(max_cell_edge) Processing_options
    set parameter_group(sigma_cutoff) Processing_options
    set parameter_group(i_sig_i) Processing_options
    set parameter_group(auto_thresh_indexing) Processing_options
    set parameter_group(auto_thresh_value) Processing_options
    set parameter_group(i_sig_i_delta) Processing_options
    set parameter_group(beamsearch_stepsize) Processing_options
    set parameter_group(beamsearch_stepnumx) Processing_options
    set parameter_group(beamsearch_stepnumy) Processing_options
    
    
    set parameter_group(anomalous) Processing_options
    
    set parameter_group(block_size) Processing_options
    set parameter_group(mtz_file) Processing_options
    set parameter_group(mtz_directory) Processing_options
    set parameter_group(auto_update_mtz) Processing_options
    set parameter_group(batch_number) Processing_options
    set parameter_group(low_resolution_limit) Processing_options
    set parameter_group(high_resolution_limit) Processing_options
    set parameter_group(resolution_cutoff) Processing_options
    set parameter_group(resolution_exclude_ice) Processing_options
    set parameter_group(view_predictions_during_processing) Processing_options
    set parameter_group(nullpix) Processing_options
    set parameter_group(raster_nxs) Processing_options
    set parameter_group(raster_nys) Processing_options
    set parameter_group(raster_nc) Processing_options
    set parameter_group(raster_nrx) Processing_options
    set parameter_group(raster_nry) Processing_options
    set parameter_group(max_refl_width) Processing_options
    set parameter_group(postref_refl_intensity_thresh) Processing_options
    set parameter_group(postref_refl_count_thresh) Processing_options
    set parameter_group(mosaic_safety_factor) Processing_options
    set parameter_group(images_mosaic_smooth) Processing_options
    set parameter_group(ref_refl_count_thresh) Processing_options
    set parameter_group(profile_overload_cutoff) Processing_options
    set parameter_group(threshold_spot_inclusion) Processing_options
    set parameter_group(profile_tolerance_min) Processing_options
    set parameter_group(profile_tolerance_max) Processing_options
    set parameter_group(profile_refl_count_av_thresh) Processing_options
    set parameter_group(profile_rmsbg_thresh) Processing_options
    set parameter_group(profile_optimise_central) Processing_options
    set parameter_group(profile_optimise_standard) Processing_options
    set parameter_group(optimise_box_size) Processing_options

    set parameter_group(ice_ring_width) Processing_options
    set parameter_group(prcutval) Processing_options
    set parameter_group(excl_near_ice) Processing_options

    set parameter_group(use_mosflm_symmetry) Processing_options
    set parameter_group(treat_anomalous_data) Processing_options
    
    set parameter_group(bgratio) Processing_options
    set parameter_group(pkratio) Processing_options
    set parameter_group(rejection_gradient_integration) Processing_options
    set parameter_group(rejection_gradient_refinement) Processing_options
    set parameter_group(smaller_partials_fraction) Processing_options
    
    set parameter_group(pickbox_size_x) Processing_options
    set parameter_group(pickbox_size_y) Processing_options

    set parameter_group(size_central_region) Processing_options
    set parameter_group(max_weighted_residual) Processing_options
    set parameter_group(max_number_reflections) Processing_options
    set parameter_group(donot_refine_detector) Processing_options
    set parameter_group(smooth_refined_detector) Processing_options
    set parameter_group(use_overloads_in_refining_detector) Processing_options
    set parameter_group(nsm1) Processing_options
    set parameter_group(nsm2) Processing_options
    
    set parameter_group(cell_refinement_fix_beam) Processing_options
    set parameter_group(cell_refinement_fix_distance) Processing_options
    set parameter_group(cell_refinement_fix_yscale) Processing_options
    set parameter_group(cell_refinement_fix_tilt) Processing_options
    set parameter_group(cell_refinement_fix_twist) Processing_options
    set parameter_group(cell_refinement_fix_radial_offset) Processing_options
    set parameter_group(cell_refinement_fix_tangential_offset) Processing_options
    set parameter_group(cell_refinement_fix_ccomega) Processing_options
    
    set parameter_group(cell_ref_postrefinement_check) Processing_options
    set parameter_group(cell_refinement_fix_cell_a) Processing_options
    set parameter_group(cell_refinement_fix_cell_b) Processing_options
    set parameter_group(cell_refinement_fix_cell_c) Processing_options
    set parameter_group(cell_refinement_fix_cell_alpha) Processing_options
    set parameter_group(cell_refinement_fix_cell_beta) Processing_options
    set parameter_group(cell_refinement_fix_cell_gamma) Processing_options
    set parameter_group(cell_refinement_fix_mosaicity) Processing_options
    
    set parameter_group(integration_fix_beam) Processing_options
    set parameter_group(integration_fix_distance) Processing_options
    set parameter_group(integration_fix_yscale) Processing_options
    set parameter_group(integration_fix_tilt) Processing_options
    set parameter_group(integration_fix_twist) Processing_options
    set parameter_group(integration_fix_radial_offset) Processing_options
    set parameter_group(integration_fix_tangential_offset) Processing_options
    set parameter_group(integration_fix_ccomega) Processing_options
    
    set parameter_group(integration_postrefinement_check) Processing_options
    set parameter_group(integration_fix_cell_a) Processing_options
    set parameter_group(integration_fix_cell_b) Processing_options
    set parameter_group(integration_fix_cell_c) Processing_options
    set parameter_group(integration_fix_cell_alpha) Processing_options
    set parameter_group(integration_fix_cell_beta) Processing_options
    set parameter_group(integration_fix_cell_gamma) Processing_options
    set parameter_group(integration_fix_mosaicity) Processing_options
    set parameter_group(wait_length) Processing_options
    set parameter_group(wait_activation) Processing_options
    set parameter_group(multiple_mtz_files) Processing_options
    set parameter_group(pointless_live) Processing_options
#
# environment variables
    set parameter_group(mosflm_exec) Processing_options
    set parameter_group(web_browser) Processing_options
    set parameter_group(ccp4_bin)    Processing_options
    set parameter_group(mosdir)     Processing_options
    set parameter_group(mosflm_logging)       Processing_options
    
    set parameter_name(project) "Project name"
    set parameter_name(crystal) "Crystal name"
    set parameter_name(dataset) "Dataset name"
    set parameter_name(xray_source) "Beam x"
    set parameter_name(beam_x) "Beam x"
    set parameter_name(beam_y) "Beam y"
    set parameter_name(beam_y_corrected) "Beam y"
    set parameter_name(distance) "Distance"
    set parameter_name(divergence_x) "Divergence x"
    set parameter_name(divergence_y) "Divergence y"
    set parameter_name(two_theta) "2\u03b8"
    set parameter_name(gain) "Gain"
    set parameter_name(adcoffset) "ADC Offset"
    set parameter_name(yscale) "Y-scale"
    set parameter_name(tilt) "Tilt"
    set parameter_name(twist) "Twist"
    set parameter_name(tangential_offset) "Tangential offset"
    set parameter_name(radial_offset) "Radial offset"
    set parameter_name(ccomega) "CCOmega"
    set parameter_name(wavelength) "Wavelength"
    set parameter_name(reverse_phi) "Reverse phi"
    set parameter_name(detector_manufacturer) "Detector manufacturer"
    set parameter_name(detector_omega) "Detector omega"
    set parameter_name(detector_model) "Detector model"
    set parameter_name(detector_serno) "Detector serno"
#    set parameter_name(expert_detector) "Expert Detector mode"
    set parameter_name(overload_cutoff) "Overload cutoff value"
    set parameter_name(profile_overload_cutoff) "Profile fitting overload"
	set parameter_name(threshold_spot_inclusion) "Threshold for spot inclusion"
    set parameter_name(spiral) "Spiral readout"
    set parameter_name(invertx) "Invert X scan"
    set parameter_name(title) "Title"
    set parameter_name(dispersion) "Wavelength dispersion"
    set parameter_name(polarization) "Beam polarization"
    set parameter_name(pixel_size) "Detector pixel size"
    set parameter_name(header_size) "Header size"
    set parameter_name(image_height) "Image height"
    set parameter_name(image_width) "Image width"
    set parameter_name(bias) "Detector bias"

    set parameter_name(mosaicity) "Mosaicity"
	set parameter_name(mosaicblock) "Mosaic Block Size"

    set parameter_name(backstop_x) "Backstop x position"
    set parameter_name(backstop_y) "Backstop y position"
    set parameter_name(backstop_radius) "Backstop radius"

    set parameter_name(threshold) "Threshold"
    set parameter_name(search_area_min_radius) "Search area min radius"
    set parameter_name(search_area_max_radius) "search area max radius"
    set parameter_name(spot_separation_x) "Peak separation min x"
    set parameter_name(spot_separation_y) "Peak separation min y"
    set parameter_name(fix_separation) "Fix spot separation"
    set parameter_name(separation_close) "Spots \"close\""
    set parameter_name(spot_splitting_x) "Peak separation max x"
    set parameter_name(spot_splitting_y) "Peak separation max y"
    set parameter_name(spot_size_min_x) "Spot size min x"
    set parameter_name(spot_size_min_y) "Spot size min y"
    set parameter_name(spot_size_max_x) "Spot size max x"
    set parameter_name(spot_size_max_y) "Spot size max y"
    set parameter_name(exclusion_segment_horizontal) "Exclusion segment horizontal height"
    set parameter_name(exclusion_segment_vertical) "Exclusion segment vertical width"
    set parameter_name(bbox_orientation) "Background box orientation"
    set parameter_name(bbox_offset) "Background box offset"
    set parameter_name(minpix) "Minimum pixels per spot in spotfinding"
    set parameter_name(local_background) "Local background determination"
    set parameter_name(local_background_box_size_x) "Local background box size x"
    set parameter_name(local_background_box_size_y) "Local background box size y"
    set parameter_name(max_unresolved_peaks) "Max number of unresolved peaks"
    set parameter_name(auto_resolution) "Automatic resolution reduction"
    set parameter_name(auto_ring) "Automatic ice/powder ring exclusion"
    set parameter_name(spot_rms_var) "Spot rms variation"
    set parameter_name(spot_anisotropy) "Spot anisotropy"

    set parameter_name(exclude_ice) "Exclude ice rings in spotfinding option"
    set parameter_name(exclude_auto) "Exclude rings automatically option"
    set parameter_name(exclude_specific) "Exclude specific rings option"
    set parameter_name(fix_distance_indexing) "Fix distance during indexing"
    set parameter_name(fix_cell_indexing) "Fix cell during indexing"
    set parameter_name(fix_max_cell_edge) "Fix max cell edge"
    set parameter_name(max_cell_edge) "Max cell edge"
    set parameter_name(sigma_cutoff) "Sigma cutoff"
    set parameter_name(i_sig_i) "I/sig(I) indexing threshold"
    set parameter_name(auto_thresh_indexing) "Automatically set indexing threshold"
    set parameter_name(auto_thresh_value) "Estimated indexing threshold"	
    set parameter_name(i_sig_i_delta) "I/sig(I) change for retry"
    set parameter_name(beamsearch_stepsize) "Beam-centre search step size"	
    set parameter_name(beamsearch_stepnumx) "Beam-centre search max steps in x"	
    set parameter_name(beamsearch_stepnumy) "Beam-centre search max steps in y"	

    set parameter_name(anomalous) "Optimize strategy for anomalous data"

    set parameter_name(block_size) "Block size"
    set parameter_name(mtz_file) "MTZ file"
    set parameter_name(mtz_directory) "MTZ directory"
    set parameter_name(auto_update_mtz) "MTZ file name auto-generation"
    set parameter_name(batch_number) "Batch number"
    set parameter_name(low_resolution_limit) "Min resolution"
    set parameter_name(high_resolution_limit) "Max resolution"
    set parameter_name(resolution_cutoff) "Resolution cutoff"
    set parameter_name(resolution_exclude_ice) "Exclude ice rings during processing"
    set parameter_name(view_predictions_during_processing) "Show predictions on images during processing"
    set parameter_name(nullpix) "Null pixel thresold"
    set parameter_name(raster_nxs) "Raster box width"
    set parameter_name(raster_nys) "Raster box height"
    set parameter_name(raster_nc) "Raster corner cutoff"
    set parameter_name(raster_nrx) "Raster border width"
    set parameter_name(raster_nry) "Raster border height"
    set parameter_name(max_refl_width) "Reflection width limit (in \u03c6)"
    set parameter_name(postref_refl_intensity_thresh) "Postrefinement reflection intensity threshold"
    set parameter_name(postref_refl_count_thresh) "Postrefinement reflection count threshold"
    set parameter_name(mosaic_safety_factor) "Mosaic spread safety factor"
    set parameter_name(images_mosaic_smooth) "Images used to smooth mosaic spread"
    set parameter_name(ref_refl_count_thresh) "Refinement relflection count threshold"
    set parameter_name(profile_tolerance_min) "Profile tolerance minimum"
    set parameter_name(profile_tolerance_max) "Profile tolerance maximum"
    set parameter_name(profile_refl_count_av_thresh) "Profile averaging reflection count threshold"
    set parameter_name(profile_rmsbg_thresh) "Profile RMS background threshold"
    set parameter_name(profile_optimise_central) "Optimise for central profile option"
    set parameter_name(profile_optimise_standard) "Optimise for standard profiles option"
    set parameter_name(optimise_box_size) "Optimise overall box size option"	

    set parameter_name(ice_ring_width) "Width of resolution shells for ice rings"
    set parameter_name(prcutval) "Fraction of strongest reflections excluded"
    set parameter_name(excl_near_ice) "Exclude reflections lying near ice rings"
    
    set parameter_name(use_mosflm_symmetry) "Use iMosflm symmetry"	
    set parameter_name(treat_anomalous_data) "Treat anomalous data"	

    set parameter_name(bgratio) "Badspots background ratio"
    set parameter_name(pkratio) "Badspots peak ratio"
    set parameter_name(rejection_gradient_integration) "Badspots gradient"
    set parameter_name(rejection_gradient_refinement) "Badspots gradient"
    set parameter_name(smaller_partials_fraction) "Smaller fraction for summed partials"

    set parameter_name(pickbox_size_x) "Width of pick box in pixels"
    set parameter_name(pickbox_size_y) "Height of pick box in pixels"

    set parameter_name(size_central_region) "Size of central region"
    set parameter_name(max_weighted_residual) "Maximum weighted residual"
    set parameter_name(max_number_reflections) "Maximum number of reflections"
    set parameter_name(donot_refine_detector) "Do not refine detector parameters"
    set parameter_name(smooth_refined_detector) "Smooth refined detector parameters"
    set parameter_name(use_overloads_in_refining_detector) "Use overloaded reflections when detector parameters"
    set parameter_name(nsm1) "Number of images (CCOM, YSCALE, DIST)"
    set parameter_name(nsm2) "Number of images (other params)"

    set parameter_name(cell_refinement_fix_beam) "Fix beam"
    set parameter_name(cell_refinement_fix_distance) "Fix distance"
    set parameter_name(cell_refinement_fix_yscale) "Fix yscale"
    set parameter_name(cell_refinement_fix_tilt) "Fix tilt"
    set parameter_name(cell_refinement_fix_twist) "Fix twist"
    set parameter_name(cell_refinement_fix_radial_offset) "Fix radial offset"
    set parameter_name(cell_refinement_fix_tangential_offset) "Fix tangential offset"
    set parameter_name(cell_refinement_fix_ccomega) "Fix ccomega"
    
    set parameter_name(cell_ref_postrefinement_check) "Postrefinement option"
    set parameter_name(cell_refinement_fix_cell_a) "Fix a"
    set parameter_name(cell_refinement_fix_cell_b) "Fix b"
    set parameter_name(cell_refinement_fix_cell_c) "Fix c"
    set parameter_name(cell_refinement_fix_cell_alpha) "Fix alpha"
    set parameter_name(cell_refinement_fix_cell_beta) "Fix beta"
    set parameter_name(cell_refinement_fix_cell_gamma) "Fix gamma"
    set parameter_name(cell_refinement_fix_mosaicity) "Fix mosaicity"
    
    set parameter_name(integration_fix_beam) "Fix beam"
    set parameter_name(integration_fix_distance) "Fix distance"
    set parameter_name(integration_fix_yscale) "Fix yscale"
    set parameter_name(integration_fix_tilt) "Fix tilt"
    set parameter_name(integration_fix_twist) "Fix twist"
    set parameter_name(integration_fix_radial_offset) "Fix radial offset"
    set parameter_name(integration_fix_tangential_offset) "Fix tangential offset"
    set parameter_name(integration_fix_ccomega) "Fix ccomega"
    
    set parameter_name(integration_postrefinement_check) "Postrefinement option"
    set parameter_name(integration_fix_cell_a) "Fix a"
    set parameter_name(integration_fix_cell_b) "Fix b"
    set parameter_name(integration_fix_cell_c) "Fix c"
    set parameter_name(integration_fix_cell_alpha) "Fix alpha"
    set parameter_name(integration_fix_cell_beta) "Fix beta"
    set parameter_name(integration_fix_cell_gamma) "Fix gamma"
    set parameter_name(integration_fix_mosaicity) "Fix mosaicity"
    set parameter_name(wait_length) "Time to wait for images (sec)"
    set parameter_name(wait_activation) "Waiting for images"
    set parameter_name(multiple_mtz_files) "One MTZ per block"
    set parameter_name(pointless_live) "Feed MTZ to Pointless"
#
# environment variables
    set parameter_name(mosflm_exec) "Mosflm executable"
    set parameter_name(web_browser) "Web browser for Baubles"
    set parameter_name(ccp4_bin)    "Directory containing CCP4 executables"
    set parameter_name(mosdir)     "Working directory"
    set parameter_name(mosflm_logging) "Comprehensive log file"
}

# Call class's initialization procedure
ParameterUpdateEvent::initializeGroupsAndNames

body ParameterUpdateEvent::reverse { } {
    # update parameter in session with old value, and update interface,
    #  but don't record in history
    set l_record_in_history_flag 0
    set l_update_interface_flag 1
    $::session updateSetting $parameter $old_value $l_record_in_history_flag $l_update_interface_flag
}

body ParameterUpdateEvent::repeat { } {
    # update parameter in session with new value, and update interface,
    # but don't record in history
    set l_record_in_history_flag 0
    set l_update_interface_flag 1
    $::session updateSetting $parameter $new_value $l_record_in_history_flag $l_update_interface_flag
}

body ParameterUpdateEvent::makeInverse { } {
    # get the current paramter's value from the session
    set l_current_parameter_value [$::session getParameterValue $parameter]
    # Create new event with current session's value as old value and event's old value as new value
    set l_new_event [namespace current]::[ParameterUpdateEvent \#auto "build" "User" $group $parameter $l_current_parameter_value $old_value]
    return $l_new_event
}

body ParameterUpdateEvent::makeDuplicate { } {
    # get the current parameter's value from the session
    set l_current_parameter_value [$::session getParameterValue $parameter]
    # Create a new event with the current session's value as old value and even't new value as new value again
    set l_new_event [namespace current]::[ParameterUpdateEvent \#auto "build" "User" $group $parameter $l_current_parameter_value $new_value]
    return $l_new_event
}

body ParameterUpdateEvent::isReversible { } {
    # parameter update events are always reversible
    return 1
}

body ParameterUpdateEvent::isRepeatable { } {
    # parameter update events are always repeatable
    return 1
}

body ParameterUpdateEvent::getDescription { } {
    # Get old and new values subsituting "" for blanks
    if {$old_value == ""} {
	set print_old_value "\"\""
    } else {
	set print_old_value $old_value
    }
    if {$new_value == ""} {
	set print_new_value "\"\""
    } else {
	set print_new_value $new_value
    }
#    return  "$parameter_name($parameter) set to $print_new_value (from $print_old_value)"
    return  " set to $print_new_value (from $print_old_value)"
}

body ParameterUpdateEvent::serialize { } {
    set xml "<event type=\"ParameterUpdateEvent\" reason=\"$reason\" group=\"$group\" parameter=\"$parameter\" old_value=\"$old_value\" new_value=\"$new_value\" state=\"$state\"/>"
    return $xml
}

body ParameterUpdateEvent::getEventIcon { } {
    if {$parameter == "mosaicity"} {
	return ::img::event_icon(Mosaicity,done)
    } else {
	return [Event::getEventIcon]
    }
}

body ParameterUpdateEvent::getParameter { } {
    return $parameter
}

# CLASS CellUpdateEvent ####################################


class CellUpdateEvent {
    inherit Event
    
    # member variables
    protected variable old_cell ""
    protected variable new_cell ""
    
    # Methods    
    public method reverse
    public method repeat
    public method makeInverse
    public method makeDuplicate
    public method isReversible
    public method isRepeatable
    public method getDescription
    public method serialize
    
    public method getEventIcon { } {return ::img::event_icon(Cell,done)}

    constructor { a_method args } {
	if {$a_method == "build"} {
	    set reason [lindex $args 0]
	    # Create cell objects by copying ones passed to constructor
	    set old_cell [namespace current]::[Cell \#auto "copy" "old" [lindex $args 1]]
	    set new_cell [namespace current]::[Cell \#auto "copy" "new" [lindex $args 2]]
	} elseif {$a_method == "xml"} {
	    # Create cell objects by parsing xml
	    set reason [$args getAttribute reason]
	    set l_old_cell_node [$args selectNodes {cell[@name='old']}]
	    set l_new_cell_node [$args selectNodes {cell[@name='new']}]
	    set old_cell [namespace current]::[Cell \#auto "xml" "old" $l_old_cell_node]
	    set new_cell [namespace current]::[Cell \#auto "xml" "new" $l_new_cell_node]
	}
	set category $reason
	set subcategory "Crystal"
	set name "Cell"
    }

    destructor {
	delete object $old_cell $new_cell
    }

}

body CellUpdateEvent::reverse { } {
    # Update session with old cell, don't record in history, but
    #  update interface
    $::session updateCell "No reason!" $old_cell 0 1
}

body CellUpdateEvent::repeat { } {
    # Update session with new cell, don't record in history, but
    #  update interface
    $::session updateCell "No reason!" $new_cell 0 1
}

body CellUpdateEvent::makeInverse { } {
    # Create new event with current session's cell and event's old cell
    set l_new_event [namespace current]::[CellUpdateEvent \#auto "build" "User" [$::session getCell] $old_cell]
    return $l_new_event
}

body CellUpdateEvent::makeDuplicate { } {
    # Create new event with current session's cell and event's new cell
    set l_new_event [namespace current]::[CellUpdateEvent \#auto "build" "User" [$::session getCell] $new_cell]
    return $l_new_event
}

body CellUpdateEvent::isReversible { } {
    # always reversible
    return 1
}

body CellUpdateEvent::isRepeatable { } {
    # always repeatable
    return 1
}

body CellUpdateEvent::getDescription { } {
    return "Cell set to [$new_cell reportCell] (from [$old_cell reportCell])"
}

body CellUpdateEvent::serialize { } {
    set xml "<event type=\"CellUpdateEvent\" reason=\"$reason\" state=\"$state\">[$old_cell serialize][$new_cell serialize]</event>"
    return $xml
}

# CLASS TargetCellUpdateEvent #############################################

# class TargetCellUpdateEvent {

#     inherit CellUpdateEvent

#     # Methods    
#     public method reverse
#     public method repeat
#     public method makeInverse
#     public method makeDuplicate
#     public method getDescription
#     public method serialize

#     public method getEventIcon { } {return ::img::event_icon(Cell,done)}

#     constructor { args } {
# 	eval CellUpdateEvent::constructor $args
#     } {
# 	set subcategory "Indexing_settings"
# 	set name "Target cell"
#     }
# }

# body TargetCellUpdateEvent::reverse { } {
#     $::session updateTargetCell "No reason!" $old_cell 0 1
# }

# body TargetCellUpdateEvent::repeat { } {
#     $::session updateTargetCell "No reason!" $new_cell 0 1
# }

# body TargetCellUpdateEvent::makeInverse { } {
#     set l_new_event [namespace current]::[TargetCellUpdateEvent \#auto "build" "User" [$::session getTargetCell] $old_cell]
#     return $l_new_event
# }

# body TargetCellUpdateEvent::makeDuplicate { } {
#     set l_new_event [namespace current]::[TargetCellUpdateEvent \#auto "build" "User" [$::session getTargetCell] $new_cell]
#     return $l_new_event
# }

# body TargetCellUpdateEvent::getDescription { } {
#     return "Target Cell set to [$new_cell reportCell] (from [$old_cell reportCell])"
# }

# body TargetCellUpdateEvent::serialize { } {
#     set xml "<event type=\"TargetCellUpdateEvent\" reason=\"$reason\" state=\"$state\">[$old_cell serialize][$new_cell serialize]</event>"
#     return $xml
# }

    
# CLASS SpacegroupUpdateEvent ####################################


class SpacegroupUpdateEvent {
    inherit Event
    
    # member variables
    protected variable old_spacegroup ""
    protected variable new_spacegroup ""
    
    # Methods    
    public method reverse
    public method repeat
    public method makeInverse
    public method makeDuplicate
    public method isReversible
    public method isRepeatable
    public method getDescription
    public method serialize
    
    public method getEventIcon { } {return ::img::spacegroup}

    constructor { a_method args } {
	if {$a_method == "build"} {
	    set reason [lindex $args 0]
	    # Build spacegroup objects by copying ones passed to constructor
	    set old_spacegroup [namespace current]::[Spacegroup \#auto "copy" "old" [lindex $args 1]]
	    set new_spacegroup [namespace current]::[Spacegroup \#auto "copy" "new" [lindex $args 2]]
	} elseif {$a_method == "xml"} {
	    set reason [$args getAttribute reason]
	    # Build pacegroup objects by passing xml
	    set l_old_spacegroup_node [$args selectNodes {spacegroup[@name='old']}]
	    set l_new_spacegroup_node [$args selectNodes {spacegroup[@name='new']}]
	    set old_spacegroup [namespace current]::[Spacegroup \#auto "xml" "old" $l_old_spacegroup_node]
	    set new_spacegroup [namespace current]::[Spacegroup \#auto "xml" "new" $l_new_spacegroup_node]
	}
	set category $reason
	set subcategory "Crystal"
	set name "Spacegroup"
    }

    destructor {
	delete object $old_spacegroup $new_spacegroup
    }
}

body SpacegroupUpdateEvent::reverse { } {
    # update session with old spacegroup, without adding event to history,
    #  but updating interface
    $::session updateSpacegroup "No reason!" $old_spacegroup 0 1
}

body SpacegroupUpdateEvent::repeat { } {
    # update session with new spacegroup, without adding event to history,
    #  but updating interface
    $::session updateSpacegroup "No reason!" $new_spacegroup 0 1
}

body SpacegroupUpdateEvent::makeInverse { } {
    set l_new_event [namespace current]::[SpacegroupUpdateEvent \#auto "build" "User" [$::session getSpacegroup] $old_spacegroup]
    return $l_new_event
}

body SpacegroupUpdateEvent::makeDuplicate { } {
    set l_new_event [namespace current]::[SpacegroupUpdateEvent \#auto "build" "User" [$::session getSpacegroup] $new_spacegroup]
    return $l_new_event
}

body SpacegroupUpdateEvent::isReversible { } {
    return 1
}

body SpacegroupUpdateEvent::isRepeatable { } {
    return 1
}

body SpacegroupUpdateEvent::getDescription { } {
    return "Spacegroup set to [$new_spacegroup reportSpacegroup] (from [$old_spacegroup reportSpacegroup])"
}

body SpacegroupUpdateEvent::serialize { } {
    set xml "<event type=\"SpacegroupUpdateEvent\" reason=\"$reason\" state=\"$state\">[$old_spacegroup serialize][$new_spacegroup serialize]</event>"
    return $xml
}

# CLASS TargetSpacegroupUpdateEvent #############################################

# class TargetSpacegroupUpdateEvent {

#     inherit SpacegroupUpdateEvent

#     # Methods    
#     public method reverse
#     public method repeat
#     public method makeInverse
#     public method makeDuplicate
#     public method getDescription
#     public method serialize

#     public method getEventIcon { } {return ::img::spacegroup}
#     constructor { args } {
# 	eval SpacegroupUpdateEvent::constructor $args
#     } {
# 	set subcategory "Indexing_settings"
# 	set name "Target spacegroup"
#     }
# }

# body TargetSpacegroupUpdateEvent::reverse { } {
#     $::session updateTargetSpacegroup "No reason!" $old_spacegroup 0 1
# }

# body TargetSpacegroupUpdateEvent::repeat { } {
#     $::session updateTargetSpacegroup "No reason!" $new_spacegroup 0 1
# }

# body TargetSpacegroupUpdateEvent::makeInverse { } {
#     set l_new_event [namespace current]::[TargetSpacegroupUpdateEvent \#auto "build" "User" [$::session getTargetSpacegroup] $old_spacegroup]
#     return $l_new_event
# }

# body TargetSpacegroupUpdateEvent::makeDuplicate { } {
#     set l_new_event [namespace current]::[TargetSpacegroupUpdateEvent \#auto "build" "User" [$::session getTargetSpacegroup] $new_spacegroup]
#     return $l_new_event
# }

# body TargetSpacegroupUpdateEvent::getDescription { } {
#     return "TargetSpacegroup set to [$new_spacegroup reportSpacegroup] (from [$old_spacegroup reportSpacegroup])"
# }

# body TargetSpacegroupUpdateEvent::serialize { } {
#     set xml "<event type=\"TargetSpacegroupUpdateEvent\" reason=\"$reason\" state=\"$state\">[$old_spacegroup serialize][$new_spacegroup serialize]</event>"
#     return $xml
# }

# CLASS MatrixUpdateEvent ####################################


class MatrixUpdateEvent {
    inherit Event
    
    # member variables
    private variable template ""
    private variable old_matrix ""
    private variable new_matrix ""
    
    # Methods    
    public method reverse
    public method repeat
    public method makeInverse
    public method makeDuplicate
    public method isReversible
    public method isRepeatable
    public method getDescription
    public method serialize
    
    public method getEventIcon { } {return ::img::orientation}
    constructor { a_method args } {
	if {$a_method == "build"} {
	    set reason [lindex $args 0]
	    set template [lindex $args 1]
	    set old_matrix [namespace current]::[Matrix \#auto "copy" [lindex $args 2]]
	    set new_matrix [namespace current]::[Matrix \#auto "copy" [lindex $args 3]]
	} elseif {$a_method == "xml"} {
	    set reason [$args getAttribute reason]
	    set template [$args getAttribute template]
	    set l_old_matrix_node [$args selectNodes {old_matrix/matrix}]
	    set l_new_matrix_node [$args selectNodes {new_matrix/matrix}]
	    set old_matrix [namespace current]::[Matrix \#auto "xml" $l_old_matrix_node]
	    set new_matrix [namespace current]::[Matrix \#auto "xml" $l_new_matrix_node]
	}
	set category $reason
	set subcategory "Crystal"
	set name "Matrix"
    }

    destructor {
	delete object $old_matrix $new_matrix
    }
}

body MatrixUpdateEvent::reverse { } {
    [$::session getSectorByTemplate $template] updateMatrix "No reason!" $old_matrix 0 1
}

body MatrixUpdateEvent::repeat { } {
    [$::session getSectorByTemplate $template] updateMatrix "No reason!" $new_matrix 0 1
}

body MatrixUpdateEvent::makeInverse { } {
    set l_new_event [namespace current]::[MatrixUpdateEvent \#auto "build" "User" $template [[$::session getSectorByTemplate $template] getMatrix] $old_matrix]
    return $l_new_event
}

body MatrixUpdateEvent::makeDuplicate { } {
    set l_new_event [namespace current]::[MatrixUpdateEvent \#auto "build" "User" $template [[$::session getSectorByTemplate $template] getMatrix] $new_matrix]
    return $l_new_event
}

body MatrixUpdateEvent::isReversible { } {
    return 1
}

body MatrixUpdateEvent::isRepeatable { } {
    return 1
}

body MatrixUpdateEvent::getDescription { } {
    return "Orientation matrix for sector $template set to [$new_matrix getName] (from [$old_matrix getName])"
}

body MatrixUpdateEvent::serialize { } {
    set xml "<event type=\"MatrixUpdateEvent\" reason=\"$reason\" template=\"$template\" state=\"$state\"><old_matrix>[$old_matrix serialize]</old_matrix><new_matrix>[$new_matrix serialize]</new_matrix></event>"
    return $xml
}


# CLASS SpotAddEvent ###########################################

class SpotAddEvent {
    inherit Event

    # Member variables
    private variable image_path ""
    private variable spot ""

    # Methods    
    public method reverse
    public method repeat
    public method makeInverse
    public method makeDuplicate
    public method isReversible
    public method isRepeatable
    public method getDescription
    public method serialize
    
    public method getSubcategoryIcon
    public method getEventIcon

    constructor { a_method args } {
	if {$a_method == "build"} {
	    set reason [lindex $args 0]
	    set image_path [lindex $args 1]
	    set spot [namespace current]::[Spot \#auto "copy" [lindex $args 2]]
	} elseif {$a_method == "xml"} {
	    set reason [$args getAttribute reason]
	    set image_path [$args getAttribute image_path]
	    set t_spot_node [$args selectNodes spot]
	    set spot [namespace current]::[Spot \#auto "xml" $t_spot_node]
	    set state [$args getAttribute state]
	}
	set category "Spotfinding"
	set subcategory "[file tail $image_path]"
	set name "Added spot"
    }
    
    destructor {
	delete object $spot
    }
} 

body SpotAddEvent::reverse { } {
    # get the image object from the session for this event's image (by file path) 
    set l_image [Image::getImageByPath $image_path]
    if {$l_image != ""} {
	# get the images' spotlist
	set l_spotlist [$l_image getSpotlist]
	if {$l_spotlist != ""} {
	    # delete the spot from the spotlist 
	    set l_id [$l_spotlist deleteSpot "position" [$spot getXpixels] [$spot getYpixels]]
	    # delete cross from image viewer canvases if necessary
	    if {$l_image == [.image getImage]} {
		foreach i_canvas [.image getCanvases] {
		    $i_canvas delete "cross$l_id"
		}
	    }
	} else {
	    # Cannot undo, should not be possible!
	    error "Could not find image's spotlist ($l_image)."
	}
    } else {
	# Cannot undo, should not be possible!
	error "Could not find image with path $image_path when trying to undo spot search."
    }
}

body SpotAddEvent::repeat { } {
    # get the image object from the session for this event's image (by file path) 
    set l_image [Image::getImageByPath $image_path]
    if {$l_image != ""} {
	# get the images' spotlist
	set l_spotlist [$l_image getSpotlist]
	if {$l_spotlist != ""} {
	    # copy the spot to the spotlist, and get the name of the newly created spot
	    set l_new_spot [$l_spotlist addSpot $spot]
	    if {$l_new_spot != ""} {
		# if the image is displayed....
		if {$l_image == [.image getImage]} {
		    # plot the new spot (in pixel position)
		    foreach i_canvas [.image getCanvases] {
			$l_new_spot plot $i_canvas
		    }
		    # and position in correctly
		    .image positionSpots "cross[$l_new_spot getId]"
		}
		# update spot fnding summary in the indexing wizard
		[.c component indexing] updateSpotlists $l_image
	    }
	} else {
	    # Cannot undo, should not be possible!
	    error "Could not find image's spotlist ($l_image)."
	}
    } else {
	# Cannot undo, should not be possible!
	error "Could not find image with path $image_path when trying to redo spot search."
    }
}

body SpotAddEvent::makeInverse { } {
    set l_new_event [namespace current]::[SpotDeleteEvent \#auto "build" "User" $image_path $spot]
    return $l_new_event
}

body SpotAddEvent::makeDuplicate { } {
    set l_new_event [namespace current]::[SpotAddEvent \#auto "build" "User" $image_path $spot]
    return $l_new_event
}

body SpotAddEvent::isReversible { } {
    # get the image object from the session for this event's image (by file path) 
    set l_image [Image::getImageByPath $image_path]
    if {$l_image != ""} {
	# get the images' spotlist
	set l_spotlist [$l_image getSpotlist]
	if {$l_spotlist != ""} {
	    # Is a spot creation -> spot must exist to be reversible
	    if {[$l_spotlist spotExists [$spot getXpixels] [$spot getYpixels]]} {
		return 1
	    }
	}
    }
    return 0
}
    
body SpotAddEvent::isRepeatable { } {
    # get the image object from the session for this event's image (by file path) 
    set l_image [Image::getImageByPath $image_path]
    if {$l_image != ""} {
	# get the images' spotlist
	set l_spotlist [$l_image getSpotlist]
	if {$l_spotlist != ""} {
	    # Is a spot creation -> spot must not exist to be repeatable
	    if {![$l_spotlist spotExists [$spot getXpixels] [$spot getYpixels]]} {
		return 1
	    }
	}
    }
    return 0
}

body SpotAddEvent::getDescription { } {
    set l_image [Image::getImageByPath $image_path]
    return "Added spot at [$spot getXpixels],[$spot getYpixels]"
}
    
body SpotAddEvent::serialize { } {
    set xml "<event type=\"SpotAddEvent\" reason=\"$reason\" image_path=\"$image_path\" state=\"$state\">[$spot serialize]</event>"
    return $xml
}

body SpotAddEvent::getSubcategoryIcon { } {
    return ::img::event_icon(Images,done)
}

body SpotAddEvent::getEventIcon { } {
    return ::img::event_icon(add_spot,done)
}
  

# CLASS SpotDeleteEvent ###########################################

class SpotDeleteEvent {
    inherit Event

    # Member variables
    private variable image_path ""
    private variable spot ""

    # Methods    
    public method reverse
    public method repeat
    public method makeInverse
    public method makeDuplicate
    public method isReversible
    public method isRepeatable
    public method getDescription
    public method serialize

    public method getSubcategoryIcon
    public method getEventIcon

    constructor { a_method args } {
	if {$a_method == "build"} {
	    set reason [lindex $args 0]
	    set image_path [lindex $args 1]
	    set spot [namespace current]::[Spot \#auto "copy" [lindex $args 2]]
	} elseif {$a_method == "xml"} {
	    set reason [$args getAttribute reason]
	    set image_path [$args getAttribute image_path]
	    set t_spot_node [$args selectNodes spot] 
	    set spot [namespace current]::[Spot \#auto "xml" $t_spot_node]
	    set state [$args getAttribute state]
	}
	set category "Spotfinding"
	set subcategory "[file tail $image_path]"
	set name "Deleted spot"
    }

    destructor {
	delete object $spot
    }
} 

body SpotDeleteEvent::repeat { } {
    # get the image object from the session for this event's image (by file path) 
    set l_image [Image::getImageByPath $image_path]
    if {$l_image != ""} {
	# get the images' spotlist
	set l_spotlist [$l_image getSpotlist]
	if {$l_spotlist != ""} {
	    # delete the spot from the spotlist 
	    set l_id [$l_spotlist deleteSpot "position" [$spot getXpixels] [$spot getYpixels]]
	    # delete cross from image viewer canvases if necessary
	    if {$l_image == [.image getImage]} {
		foreach i_canvas [.image getCanvases] {
		    $i_canvas delete "cross$l_id" 
		}
	    }
	} else {
	    # Cannot repeat, should not be possible!
	    error "Could not find image's spotlist ($l_image)."
	}
    } else {
	# Cannot repeat, should not be possible!
	error "Could not find image with path $image_path when trying to undo spot search."
    }
}

body SpotDeleteEvent::reverse { } {
    # get the image object from the session for this event's image (by file path) 
    set l_image [Image::getImageByPath $image_path]
    if {$l_image != ""} {
	# get the images' spotlist
	set l_spotlist [$l_image getSpotlist]
	if {$l_spotlist != ""} {
	    # copy the spot to the spotlist, and get the name of the new spot
	    set l_new_spot [$l_spotlist addSpot $spot]
	    if {$l_new_spot != ""} {
		# if the image is displayed ...
		if {$l_image == [.image getImage]} {
		    # plot the spot ...
		    foreach i_canvas [.image getCanvases] {
			$l_new_spot plot $i_canvas
		    }
		    # and position it.
		    .image positionSpots "cross[$l_new_spot getId]"
		}
		# update the indexwizard's spot search summary info
		[.c component indexing] updateSpotlists $l_image
	    }
	} else {
	    # Cannot undo, should not be possible!
	    error "Could not find image's spotlist ($l_image)."
	}
    } else {
	# Cannot undo, should not be possible!
	error "Could not find image with path $image_path when trying to redo spot search."
    }
}

body SpotDeleteEvent::makeInverse { } {
    set l_new_event [namespace current]::[SpotAddEvent \#auto "build" "User" $image_path $spot]
    return $l_new_event
}

body SpotDeleteEvent::makeDuplicate { } {
    set l_new_event [namespace current]::[SpotDeleteEvent \#auto $action "User" $image_path $spot]
    return $l_new_event
}

body SpotDeleteEvent::isReversible { } {
    # get the image object from the session for this event's image (by file path) 
    set l_image [Image::getImageByPath $image_path]
    if {$l_image != ""} {
	# get the images' spotlist
	set l_spotlist [$l_image getSpotlist]
	if {$l_spotlist != ""} {
	    # Is a spot creation -> spot must exist to be reversible
	    if {![$l_spotlist spotExists [$spot getXpixels] [$spot getYpixels]]} {
		return 1
	    }
	}
    }
    return 0
}
    
body SpotDeleteEvent::isRepeatable { } {
    # get the image object from the session for this event's image (by file path) 
    set l_image [Image::getImageByPath $image_path]
    if {$l_image != ""} {
	# get the images' spotlist
	set l_spotlist [$l_image getSpotlist]
	if {$l_spotlist != ""} {
	    # Is a spot creation -> spot must not exist to be repeatable
	    if {[$l_spotlist spotExists [$spot getXpixels] [$spot getYpixels]]} {
		return 1
	    }
	}
    }
    return 0
}

body SpotDeleteEvent::getDescription { } {
    set l_image [Image::getImageByPath $image_path]
    return "Deleted spot at [$spot getXpixels],[$spot getYpixels]"
}

body SpotDeleteEvent::serialize { } {
    set xml "<event type=\"SpotDeleteEvent\" reason=\"$reason\" image_path=\"$image_path\" state=\"$state\">[$spot serialize]</event>"
    return $xml
}
    
body SpotDeleteEvent::getSubcategoryIcon { } {
    return ::img::event_icon(Images,done)
}

body SpotDeleteEvent::getEventIcon { } {
    return ::img::event_icon(delete_spot,done)
}
  
  

# CLASS SpotEvent #########################################

class SpotSearchEvent {
    inherit Event
    
    private variable image_path ""
    private variable old_spotlist ""
    private variable new_spotlist ""

    # Methods    
    public method reverse
    public method repeat
    public method makeInverse
    public method makeDuplicate
    public method isReversible
    public method isRepeatable
    public method getDescription
    public method serialize

    public method getSubcategoryIcon
    public method getEventIcon

    constructor { a_method args } {
    } {
	if {$a_method == "build"} {
	    set reason [lindex $args 0]
	    set image_path [lindex $args 1]
	    set t_old_spotlist [lindex $args 2]
	    set t_new_spotlist [lindex $args 3]   
	    if {$t_old_spotlist != ""} {
		set old_spotlist [namespace current]::[Spotlist \#auto "copy" $t_old_spotlist]
	    }
	    if {$t_new_spotlist != ""} {
		set new_spotlist [namespace current]::[Spotlist \#auto "copy" $t_new_spotlist]
	    }
	} elseif {$a_method == "xml"} {
	    set reason [$args getAttribute reason]
	    set image_path [$args getAttribute image_path]
	    set old_spotlist_node [$args selectNodes {spotlist[@name='old']}]
	    if {$old_spotlist != ""} {
		set old_spotlist [namespace current]::[Spotlist \#auto "xml" $old_spotlist_node]
	    }
	    set new_spotlist_node [$args selectNodes {spotlist[@name='new']}]
	    if {$new_spotlist_node != ""} {
		set new_spotlist [namespace current]::[Spotlist \#auto "xml" $new_spotlist_node]
	    }
	    set state [$args getAttribute state]
	}
	set category "Spotfinding"
	set subcategory "[file tail $image_path]"
	if { $reason == "Input"} {
	    set name "File input"
	} else {
	    set name "Spot search"
	}
    }

    destructor {
	if {$old_spotlist != ""} {
	    delete object $old_spotlist
	}
	if {$new_spotlist != ""} {
	    delete object $new_spotlist
	}
    }
}

body SpotSearchEvent::reverse { } {
    # get the image object from the session for this event's image (by file path) 
    set l_image [Image::getImageByPath $image_path]
    if {$l_image != ""} {
	if {$old_spotlist != ""} {
	    # Create a copy of the 'old' spotlist and give it to the image
	    $l_image setSpotlist [namespace current]::[Spotlist \#auto "copy" $old_spotlist]
	} else {
	    $l_image setSpotlist ""
	}
	# If the image is displayed, re-plot the spots
	if {$l_image == [.image getImage]} {
	    .image plotSpots
	}
	[.c component indexing] updateSpotlists $l_image
    } else {
	# Cannot undo, should not be possible!
	error "Could not find image with path $image_path when trying to reverse spot search."
    }
}

body SpotSearchEvent::repeat { } {
    # get the image object from the session for this event's image (by file path) 
    set l_image [Image::getImageByPath $image_path]
    if {$l_image != ""} {
	# Update the image's spotlist with copied or null spotlist
	if {$new_spotlist != ""} {
	    # Create a copy of the 'old' spotlist and give it to the image
	    $l_image setSpotlist [namespace current]::[Spotlist \#auto "copy" $new_spotlist]
	} else {
	    $l_image setSpotlist ""
	}
	# If the image is displayed, re-plot the spots
	if {$l_image == [.image getImage]} {
	    .image plotSpots
	}
	[.c component indexing] updateSpotlists $l_image
    } else {
	# Cannot undo, should not be possible!
	error "Could not find image with path $image_path when trying to reverse spot search."
    }
}

body SpotSearchEvent::makeInverse { } {
    # Get the image object from the session for this event's image (by path)
    set l_image [Image::getImageByPath $image_path]
    if {$l_image != ""} {	
	set l_current_spotlist [$l_image getSpotlist]
	set l_new_event [namespace current]::[SpotSearchEvent \#auto "build" "User" $image_path $l_current_spotlist $old_spotlist]
    } else {
	error "Could not find image with path $image_path when trying to make inverse spot search."
    }
    return $l_new_event
}

body SpotSearchEvent::makeDuplicate { } {
    # Get the image object from the session for this event's image (by path)
    set l_image [Image::getImageByPath $image_path]
    if {$l_image != ""} {
	set l_current_spotlist [$l_image getSpotlist]
	set l_new_event [namespace current]::[SpotSearchEvent \#auto "build" "User" $image_path $l_current_spotlist $new_spotlist]
    } else {
	error "Could not find image with path $image_path when trying to make duplicate spot search."
    }
    return $l_new_event
}

body SpotSearchEvent::isReversible { } {
    # Get the image object from the session for this event's image (by path)
    set l_image [Image::getImageByPath $image_path]
    if {$l_image != ""} {
	set l_result 1
    } else {
	set l_result 0
    }
    return $l_result
}
    
body SpotSearchEvent::isRepeatable { } {
    return [isReversible]
}

body SpotSearchEvent::getDescription { } {
    set l_image [Image::getImageByPath $image_path]
    if {$old_spotlist == ""} {
	set l_old_value 0
    } else {
	set l_old_value [$old_spotlist getTotal]
    }
    if {$new_spotlist == ""} {
	set l_new_value 0
    } else {
	set l_new_value [$new_spotlist getTotal]
    }
    return "Spot list now has $l_new_value spots (was $l_old_value)"
}

body SpotSearchEvent::serialize { } {
    set xml "<event type=\"SpotSearchEvent\" reason=\"$reason\" image_path=\"$image_path\" state=\"$state\">"
    if {$old_spotlist != ""} {
	append xml [$old_spotlist serialize "old"]
    }
    if {$new_spotlist != ""} {
	append xml [$new_spotlist serialize "new"]
    }
    append xml "</event>"
    return $xml
}

body SpotSearchEvent::getSubcategoryIcon { } {
    return ::img::event_icon(Images,done)
}

body SpotSearchEvent::getEventIcon { } {
    return ::img::event_icon(Spotsearch,done)
}

# CLASS Solution event ##########################################

class SolutionEvent {
    inherit Event
    
    private variable solution ""

    # Methods    
    public method reverse
    public method repeat
    public method makeInverse
    public method makeDuplicate
    public method isReversible
    public method isRepeatable
    public method getDescription
    public method serialize

    public method getSubcategoryIcon
    public method getEventIcon

    constructor { a_method args } {
    } {
	if {$a_method == "build"} {
	    set reason [lindex $args 0]
	    if {[[lindex $args 1] isa RefinedSolution]} {
		set solution [namespace current]::[RefinedSolution \#auto "copy" [lindex $args 1]]
	    } else {
		set solution [namespace current]::[Solution \#auto "copy" [lindex $args 1]]
	    }
	} elseif {$a_method == "xml"} {
	    set reason [$args getAttribute reason]
	    set solution_node [$args selectNodes {solution}]
	    if {$solution_node != ""} {
		set solution [namespace current]::[Solution \#auto "xml" $solution_node]
	    } else {
		set solution_node [$args selectNodes {refined_solution}]
		set solution [namespace current]::[RefinedSolution \#auto "xml" $solution_node]
	    }
	    set state [$args getAttribute state]
	}
	set category "Indexing"
	set subcategory "Solutions"
	set name "Solution [$solution getNumber]"
    }

    destructor {
	delete object $solution
    }
}

body SolutionEvent::reverse { } {
    # No need!
}

body SolutionEvent::repeat { } {
     # update the cell
    $::session updateCell "User" [$solution getCell] 1 1 0
    # Get a list of sectors used
    set l_sectors_to_update {}
    foreach i_image [$solution getImages] {
	set l_template [$i_image getTemplate]
	set l_sector [$::session getSectorByTemplate [$i_image getTemplate]]
	if {[lsearch $l_sectors_to_update $l_sector] < 0} {
	    lappend l_sectors_to_update $l_sector
	}
    }
    # update all used sectors with new matrix
    foreach i_sector $l_sectors_to_update {
	eval $i_sector updateMatrix "User" [$solution getMatrix] 1 1 0
    }
    
    # update the spacegroup
    set l_spacegroup [namespace current]::[Spacegroup \#auto "initialize" "unnamed" [$solution getSpacegroup]]
    $::session updateSpacegroup "User" $l_spacegroup 1 1 0
    delete object $l_spacegroup
    
    # if the solution was refined (so the beam was changed)...
    if {[$solution isa RefinedSolution]} {
	# update the beam position
	foreach { l_beam_x l_beam_y } [$solution getBeam] break
	$::session updateSetting beam_x $l_beam_x 1 1 "User" 0
	$::session updateSetting beam_y $l_beam_y 1 1 "User" 0
    }
    $::session updateSetting beam_y_corrected [expr $beam_y * $yscale] 1 1 "User" 0
    $::session updatePredictions
}

body SolutionEvent::makeInverse { } {
    return ""
}

body SolutionEvent::makeDuplicate { } {
    return ""
}

body SolutionEvent::isReversible { } {
    return 0
}
    
body SolutionEvent::isRepeatable { } {
    return 1
}

body SolutionEvent::getDescription { } {
    set l_description "[$solution getLattice];"
    foreach i_datum [[$solution getCell] listCell] {
	append l_description " [format %6.2f $i_datum]"
    }
    if {[$solution isa RefinedSolution]} {
	append l_description "; beam: [$solution getBeam]"
    }
    return $l_description
}

body SolutionEvent::serialize { } {
    return "<event type=\"SolutionEvent\" reason=\"$reason\" state=\"$state\">[$solution serialize]</event>"
}

body SolutionEvent::getSubcategoryIcon { } {
    if {[$solution isa RefinedSolution]} {
	set l_image ::img::ref_solution
    } else {
	set l_image ::img::reg_solution
    }
    return $l_image
}

body SolutionEvent::getEventIcon { } {
    return [getSubcategoryIcon]
}

# CLASS Processing event ##########################################

class ProcessingEvent {
    inherit Event
    
    protected variable type ""
    protected variable results ""

    # Methods    
    public method isReversible { } { return 0 }
    public method isRepeatable { } { return 1 }
    public method makeDuplicate { } { return "" }
    public method getDescription { } { return "" }
    
    public method serialize

    public method categorize { } { }
    public method copyResults ; # virtual
    public method parseResults ; # virtual

    constructor { a_method args } {
    } {
	if {$a_method == "build"} {
	    set reason [lindex $args 0]
	    set results [copyResults [lindex $args 1]]
	} elseif {$a_method == "xml"} {
	    set reason [$args getAttribute reason]
	    set results [parseResults $args]
	    set state [$args getAttribute state]
	} else {
	    error "Unknown constructor method"
	}
	categorize
    }

    destructor {
	delete object $results
    }
}

body ProcessingEvent::categorize { } {
    error "Virtual function called!"
}

body ProcessingEvent::serialize { } {
    return "<event type=\"$type\" reason=\"$reason\" state=\"$state\">[$results serialize]</event>"
}

# CLASS CellrefinementEvent ######################################
class CellrefinementEvent {
    inherit ProcessingEvent
    
    # Methods    
    public method copyResults
    public method parseResults
    public method getDescription
    public method categorize
    public method repeat

    constructor { args } {
	eval ProcessingEvent::constructor $args
    } {
	set type "CellrefinementEvent"
    }
}

body CellrefinementEvent::copyResults { a_result } {
    return [namespace current]::[Cellrefinementresults \#auto "copy" $a_result]
}

body CellrefinementEvent::parseResults { a_node } {
    set results_node [$a_node selectNodes cell_refinement_results]
    return [namespace current]::[Cellrefinementresults \#auto "xml" $results_node]
}

body CellrefinementEvent::categorize { } {
    set category "Cell_refinement"
    set subcategory "Cell_refinement"
    set name "Cell_refinement"
}

body CellrefinementEvent::getDescription { } {
    set l_num_list {}
    foreach i_image [$results getImages] {
	lappend l_num_list [$i_image getNumber]
    }
    set l_description "Refining cell using images: [compressNumList $l_num_list &]"
    return $l_description
}

body CellrefinementEvent::repeat { } {
    [.c component cell_refinement] loadResults $results
    .c showStage cell_refinement
}

# CLASS IntegrationEvent ######################################

class IntegrationEvent {
    inherit ProcessingEvent
    
    # Methods    
    public method copyResults
    public method parseResults
    public method getDescription
    public method categorize
    public method repeat

    constructor { args } {
	eval ProcessingEvent::constructor $args
    } {
	set type "IntegrationEvent"
    }
}

body IntegrationEvent::copyResults { a_result } {
    return [namespace current]::[Integrationresults \#auto "copy" $a_result]
}

body IntegrationEvent::parseResults { a_node } {
    set results_node [$a_node selectNodes integration_result]
    return [namespace current]::[Integrationresults \#auto "xml" $results_node]
}

body IntegrationEvent::categorize { } {
    set category "Integration"
    set subcategory "Integration"
    set name "Integration"
}

body IntegrationEvent::getDescription { } {
    set l_num_list {}
    foreach i_image [$results getImages] {
	lappend l_num_list [$i_image getNumber]
    }
    set l_description "Integrating images: [compressNumList $l_num_list &]"
    return $l_description
}

body IntegrationEvent::repeat { } {
    [.c component integration] loadResults $results
    .c showStage integration
}

# CLASS Phi update event  ###########################################

class PhiUpdateEvent {
    inherit Event
    
    # member variables
    private variable image_file ""
    private variable new_phi_start ""
    private variable new_phi_end ""
    private variable old_phi_start ""
    private variable old_phi_end ""

    # Methods    
    public method reverse
    public method repeat
    public method makeInverse
    public method makeDuplicate
    public method isReversible
    public method isRepeatable
    public method getDescription
    public method serialize

    public method getSubcategoryIcon

    constructor { a_method args } {
	if {$a_method == "build"} {
	    set reason [lindex $args 0]
	    set image_file [[lindex $args 1] getFullPathName]
	    set new_phi_start [lindex $args 2]
	    set new_phi_end [lindex $args 3]
	    set old_phi_start [lindex $args 4]
	    set old_phi_end [lindex $args 5]
	} elseif {$a_method == "xml"} {
	    set reason [$args getAttribute reason]
	    set state [$args getAttribute state]
	    set image_file [$args getAttribute image_file]
	    set new_phi_start [$args getAttribute new_phi_start]
	    set new_phi_end [$args getAttribute new_phi_end]
	    set old_phi_start [$args getAttribute old_phi_start]
	    set old_phi_end [$args getAttribute old_phi_end]
	} else {
	    error "Bad method of building PhiUpdateEvent!"
	}
	set category "Images"
	set subcategory "Edited phi values"
	set name "[file tail $image_file]"
    }
}

body PhiUpdateEvent::reverse { } {
    # restore old phi values
    [Image::getImageByPath $image_file] setPhi $old_phi_start $old_phi_end 0 1
}

body PhiUpdateEvent::repeat { } {
    # reapply new phi values
    [Image::getImageByPath $image_file] setPhi $new_phi_start $new_phi_end 0 1
}

body PhiUpdateEvent::makeInverse { } {
    # Create PhiUpdateEvent with opposite values
    return [namespace current]::[PhiUpdateEvent \#auto "build" "User" [Image::getImageByPath $image_file] $old_phi_start $old_phi_end $new_phi_start $new_phi_end]
}

body PhiUpdateEvent::makeDuplicate { } {
    # Create PhiUpdateEvent with identical values
    return [namespace current]::[PhiUpdateEvent \#auto "build" "User" [Image::getImageByPath $image_file] $new_phi_start $new_phi_end $old_phi_start $old_phi_end]
}

body PhiUpdateEvent::isReversible { } {
    # Reversible if image still exists in session
    if {[Image::getImageByPath $image_file] == ""} {
	return 0
    }
    return 1
}

body PhiUpdateEvent::isRepeatable { } {
    # Repeatable if image still exists in session
    if {[Image::getImageByPath $image_file] != ""} {
	return 0
    }
    return 1
}

body PhiUpdateEvent::getDescription { } {
    set description "Set image $name's phi range to $new_phi_start-$new_phi_end (from $old_phi_start-$old_phi_end)"
    return $description
}

body PhiUpdateEvent::serialize { } {
    return "<event type=\"PhiUpdateEvent\" reason=\"$reason\" state=\"$state\" image_file=\"$image_file\" new_phi_start=\"$new_phi_start\" new_phi_end=\"$new_phi_end\" old_phi_start=\"$old_phi_start\" old_phi_end=\"$old_phi_end\"/>"
}

body PhiUpdateEvent::getSubcategoryIcon { } {
    return ::img::add_image
}


# CLASS Misset update event  ###########################################

class MissetUpdateEvent {
    inherit Event
    
    # member variables
    private variable image_file ""
    private variable new_phi_x ""
    private variable new_phi_y ""
    private variable new_phi_z ""
    private variable old_phi_x ""
    private variable old_phi_y ""
    private variable old_phi_z ""

    # Methods    
    public method reverse
    public method repeat
    public method makeInverse
    public method makeDuplicate
    public method isReversible
    public method isRepeatable
    public method getDescription
    public method serialize

    public method getSubcategoryIcon

    constructor { a_method args } {
	if {$a_method == "build"} {
	    set reason [lindex $args 0]
	    set image_file [[lindex $args 1] getFullPathName]
	    set new_phi_x [lindex $args 2]
	    set new_phi_y [lindex $args 3]
	    set new_phi_z [lindex $args 4]
	    set old_phi_x [lindex $args 5]
	    set old_phi_y [lindex $args 6]
	    set old_phi_z [lindex $args 7]
	} elseif {$a_method == "xml"} {
	    set reason [$args getAttribute reason]
	    set state [$args getAttribute state]
	    set image_file [$args getAttribute image_file]
	    set new_phi_x [$args getAttribute new_phi_x]
	    set new_phi_y [$args getAttribute new_phi_y]
	    set new_phi_y [$args getAttribute new_phi_z]
	    set old_phi_x [$args getAttribute old_phi_x]
	    set old_phi_y [$args getAttribute old_phi_y]
	    set old_phi_y [$args getAttribute old_phi_z]
	} else {
	    error "Bad method of building MissetUpdateEvent!"
	}
	set category "Images"
	set subcategory "Updated missetting angles"
	set name "[file tail $image_file]"
    }
}

body MissetUpdateEvent::reverse { } {
    # restore old phi values
    set l_record_in_history 0
    set l_update_interface 1
    [Image::getImageByPath $image_file] updateMissets $old_phi_x $old_phi_y $old_phi_z $l_record_in_history $l_update_interface
}

body MissetUpdateEvent::repeat { } {
    # reapply new phi values
    set l_record_in_history 0
    set l_update_interface 1
    [Image::getImageByPath $image_file] updateMissets $new_phi_x $new_phi_y $new_phi_z $l_record_in_history $l_update_interface
}

body MissetUpdateEvent::makeInverse { } {
    # Create MissetUpdateEvent with opposite values
    return [namespace current]::[MissetUpdateEvent \#auto "build" "User" [Image::getImageByPath $image_file] $old_phi_x $old_phi_y $old_phi_z $new_phi_x $new_phi_y $new_phi_z]
}

body MissetUpdateEvent::makeDuplicate { } {
    # Create MissetUpdateEvent with identical values
    return [namespace current]::[MissetUpdateEvent \#auto "build" "User" [Image::getImageByPath $image_file] $new_phi_x $new_phi_y $new_phi_z $old_phi_x $old_phi_y $old_phi_z]
}

body MissetUpdateEvent::isReversible { } {
    # Reversible if image still exists in session
    if {[Image::getImageByPath $image_file] == ""} {
	return 0
    }
    return 1
}

body MissetUpdateEvent::isRepeatable { } {
    # Repeatable if image still exists in session
    if {[Image::getImageByPath $image_file] != ""} {
	return 0
    }
    return 1
}

body MissetUpdateEvent::getDescription { } {
    set description "Set image $name's missets to $new_phi_x,$new_phi_y,$new_phi_z (from $old_phi_x,$old_phi_y,$old_phi_z)"
    return $description
}

body MissetUpdateEvent::serialize { } {
    return "<event type=\"MissetUpdateEvent\" reason=\"$reason\" state=\"$state\" image_file=\"$image_file\" new_phi_x=\"$new_phi_x\" new_phi_y=\"$new_phi_y\" new_phi_z=\"$new_phi_z\" old_phi_x=\"$old_phi_x\" old_phi_y=\"$old_phi_y\" old_phi_z=\"$old_phi_z\"/>"
}

body MissetUpdateEvent::getSubcategoryIcon { } {
    return ::img::add_image
}


# CLASS WarningEvent  ###########################################

class WarningEvent {
    inherit Event
    
    # member variables
    private variable warning

    # Methods    
    public method reverse
    public method repeat
    public method getDescription
    public method serialize

    public method getSubcategoryIcon

    constructor { a_method args } {
	if {$a_method == "build"} {
	    set reason [lindex $args 0]
	    set warning [namespace current]::[Warning \#auto "copy" [lindex $args 1]]
	} elseif {$a_method == "xml"} {
	    set reason [$args getAttribute reason]
	    set state [$args getAttribute state]
	    set warning [namespace current]::[Warning \#auto "xml" [$args selectNodes {warning}]]
	} else {
	    error "Bad method of building WarningEvent!"
	}
	set category $reason
	set subcategory "[$warning getType]"
	set name "[$warning getType]"
    }

    destructor {
	delete object $warning
    }
}

body WarningEvent::reverse { } {
    # Nothing to be done!
}

body WarningEvent::repeat { } {
    # Nothing to be done!
}

body WarningEvent::getDescription { } {
    set description "[$warning getMessage]"
    return $description
}

body WarningEvent::serialize { } {
    set xml "<event type=\"WarningEvent\" reason=\"$reason\" state=\"$state\">"
    append xml [$warning serialize]
    append xml "</event>"
    return $xml
}

body WarningEvent::getSubcategoryIcon { } {
    return [$warning getIcon]
}

# CLASS History #################################################

class History {

    # Member variables
    private variable events {}
    private variable horizon "-1"

    # Methods
    public method parseDom
    public method addEvent 
    public method addEventQuickly 
    public method undo
    public method redo
    public method reverse
    public method repeat

    public method getEvents
    public method getHorizon
    public method getCurrentEvent

    private method recordNewEvent

    public method serialize

    public method hasParameterBeenUpdated
    public method getMostRecentEvent

    constructor { { history_node "" } } {
	if {$history_node != ""} {
	    parseDom $history_node
	}
    }

    destructor {
	eval delete object $events
    }

}

body History::addEvent { event_class args } {
    eval addEventQuickly $event_class $args
    # Automatically save the session everytime something changes!
    $::session writeToFile
}

body History::addEventQuickly { event_class args } {
    set l_args [linsert $args 0 "build"]
    set l_new_event [namespace current]::[eval $event_class \#auto $l_args]
    recordNewEvent $l_new_event
}

body History::recordNewEvent { a_event } {
    if {[llength $events] > ($horizon + 1)} {
	foreach i_event [lrange $events [expr $horizon + 1] end] {
	    [.c component history] eraseEvent $i_event
	    delete object $i_event
	}
	set events [lrange $events 0 $horizon]
    }
    lappend events $a_event
    incr horizon
    [.c component history] recordEvent $a_event
}	

body History::reverse { a_event } {
    set l_new_event [$a_event makeInverse]
    $a_event reverse
    if {$l_new_event != ""} {
	recordNewEvent $l_new_event
    }
    $::session writeToFile
}

body History::repeat { a_event } {
    set l_new_event [$a_event makeDuplicate]
    $a_event repeat
    if {$l_new_event != ""} {
	recordNewEvent $l_new_event
    }
    $::session writeToFile
}

body History::undo { } {
    if {$horizon > -1} {
	set current_event [lindex $events $horizon]
	$current_event undo
	incr horizon -1
    }

    [.c component history] markUndone $current_event
}

body History::redo { } {
    if {$horizon < ([llength $events] - 1)} {
	set next_event [lindex $events [expr $horizon + 1]]
	$next_event redo
	incr horizon
    }

    [.c component history] markDone $next_event
}

body History::getEvents { {an_index ""} } {
    if {$an_index == ""} {
	return $events
    } else {
	return [lindex $events $an_index]
    }
}

body History::getHorizon { } {
    return $horizon
}

body History::getCurrentEvent { } {
    if {$horizon > -1} {
	set l_current_event [lindex $events $horizon]
    } else {
	set l_current_event ""
    }
    return $l_current_event
}

body History::serialize { } {

    set xml "<history horizon=\"$horizon\">"
    foreach i_event $events {
	append xml [$i_event serialize]
    }
    append xml "</history>"

    return $xml
}

body History::parseDom { history_node } {
    if {[llength $events] != 0} {
	eval delete object $events
	set events {}
    }
    foreach i_event_node [$history_node selectNodes event] {
	set l_new_event [namespace current]::[[$i_event_node getAttribute type] \#auto "xml" $i_event_node]
	lappend events $l_new_event
	[.c component history] recordEvent $l_new_event
    }
    set horizon [$history_node getAttribute horizon]
}

body History::hasParameterBeenUpdated { a_parameter } {
    set l_result 0
    foreach i_event $events {
	if {[$i_event isa ParameterUpdateEvent]} {
	    if {[$i_event isDone] && [$i_event getParameter] == $a_parameter} {
		set l_result 1
	    }
	}
    }
    return $l_result
}

body History::getMostRecentEvent { an_event_class } {
    set l_event ""
    set l_num_events [llength $events]
    set i_event_index [expr $l_num_events - 1]
    while {$i_event_index >= 0} {
	if {[[lindex $events $i_event_index] isa $an_event_class]} {
	    set l_event [lindex $events $i_event_index]
	    break
	}
	incr i_event_index -1
    }
    return $l_event
}

# CLASS HistoryViewer ##########################################

class HistoryViewer {
    inherit itk::Widget
    
    # member variables

    private variable history ""
    
    private variable events_by_item ; # array
    private variable items_by_event ; # array
    
    private variable search_term ""
    private variable search_direction "forwards"
    private variable current_search_position "0.0"
	private variable mosflm_keyword ""

    # methods

    public method updateButtons

    public method recordEvent
    public method eraseEvent
    public method markUndone
    public method markDone

    private method undo
    private method redo
    private method reverse
    private method repeat

    public method changeHistory

    private method updateEventSelection

    public method monitor

    private method tabbing

    public method launch
    public method hide
    
    public method clickText
    public method showSearchPanel
    public method hideSearchPanel
    public method searchLog
    public method newSearch
#added by luke
private method stopAutoscroll
private method startAutoscroll
private variable autoscrollbool 1

public method sendKeyword
public method showKeywordPanel
public method hideKeywordPanel

###############


    constructor { args } { }
}

body HistoryViewer::constructor { args } {
    
    #wm title $itk_component(hull) "History"

    itk_component add heading_f {
	frame $itk_interior.hf \
	    -bd 1 \
	    -relief solid 
    }

    itk_component add heading_l {
	label $itk_interior.hf.fl \
	    -text "History" \
	    -font title_font \
	    -anchor w
    } {
	usual
	ignore -font
    }

    pack $itk_component(heading_f) -side top -fill x -padx 7 -pady {7 0}
    pack $itk_component(heading_l) -side left -padx 5 -pady 5 -fill both -expand 1


    # tab notebook #########################################################

    itk_component add tabs {
        iwidgets::tabnotebook $itk_interior.tabs \
	    -tabpos s  \
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

    $itk_component(tabs) add -label "History"
    set history_tab [$itk_component(tabs) childsite 0]
    $itk_component(tabs) add -label "Log"
    set log_tab [$itk_component(tabs) childsite 1]

    $itk_component(tabs) select 0

    bind $itk_component(tabs).canvas.tabset <FocusIn> [code $this tabbing highlight]
    bind $itk_component(tabs).canvas.tabset <FocusOut> [code $this tabbing unhighlight]
    bind $itk_component(tabs).canvas.tabset <Tab> [code focus [tk_focusNext [$itk_component(tabs) component tabset]]]
    bind $itk_component(tabs).canvas.tabset <Right> [code $this tabbing right]
    bind $itk_component(tabs).canvas.tabset <Left> [code $this tabbing left]
    bind $itk_component(tabs).canvas.tabset <Enter> {}
    bind $itk_component(tabs).canvas.tabset.canvas <ButtonPress-1> [code $this tabbing highlight]

    # History tab ######################################################

    itk_component add event_frame {
	frame $history_tab.ef
    }


    itk_component add event_tree {
	treectrl $history_tab.ef.et \
	    -showline 1 \
	    -showbuttons 1 \
	    -selectmode single \
	    -width 800 \
	    -height 414
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    }

    $itk_component(event_tree) notify bind $itk_component(event_tree) <Selection> [code $this updateEventSelection %S %D]

    $itk_component(event_tree) column create -text Event -tag event -justify left -width 300 -expand 1 ;# -itembackground {"\#ffffff" "\#e8e8e8"} 
    $itk_component(event_tree) column create -text Description -tag description -justify left -expand 1 -visible 1 ;#-itembackground {"\#ffffff" "\#e8e8e8"}

    $itk_component(event_tree) state define DONE

    $itk_component(event_tree) element create e_icon image
    $itk_component(event_tree) element create e_text text -fill {white selected lightgrey !DONE }
    $itk_component(event_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
	
    $itk_component(event_tree) style create s1
    $itk_component(event_tree) style elements s1 { e_highlight e_icon e_text }
    $itk_component(event_tree) style layout s1 e_icon -expand ns -padx {0 6} -pady {1 1}
    $itk_component(event_tree) style layout s1 e_text -expand ns
    $itk_component(event_tree) style layout s1 e_highlight -union [list e_text] -iexpand nse -ipadx 2
    
    $itk_component(event_tree) style create s2
    $itk_component(event_tree) style elements s2 {e_highlight e_text}
    $itk_component(event_tree) style layout s2 e_text -expand ns
    $itk_component(event_tree) style layout s2 e_highlight -union [list e_text] -iexpand nsew -ipadx 2

    itk_component add scrollbar {
	scrollbar $history_tab.ef.scroll \
	    -orient vertical \
	    -highlightthickness 0 \
	    -command [list $itk_component(event_tree) yview]
    }

    $itk_component(event_tree) configure \
	-treecolumn 0 \
	-yscrollcommand [list $itk_component(scrollbar) set]

#     if {[package present treectrl] < 2} {
# 	$itk_component(event_tree) configure \
# 	    -treecolumn event
#     }
	

    itk_component add reverse {
	button $history_tab.reverse \
	    -text Reverse \
	    -command [code $this reverse] \
	    -state "disabled"
    }

    itk_component add repeat {
	button $history_tab.repeat \
	    -text Reload \
	    -command [code $this repeat] \
	    -state "disabled"
    }

    itk_component add undo {
	button $history_tab.undo \
	    -text Undo \
	    -command [code $this undo] \
	    -state "disabled"
    }

    itk_component add redo {
	button $history_tab.redo \
	    -text Redo \
	    -command [code $this redo] \
	    -state "disabled"
    }

    pack $itk_component(event_tree) -side left -fill both -expand 1
    pack $itk_component(scrollbar) -side right -fill y

    set margin 7
    grid $itk_component(event_frame) -row 1 -column 1 -columnspan 9 -sticky nswe
    grid $itk_component(reverse) -row 3 -column 2 -sticky we
    grid $itk_component(repeat) -row 3 -column 4 -sticky we
    grid $itk_component(undo) -row 3 -column 6 -sticky we
    grid $itk_component(redo) -row 3 -column 8 -sticky we

    grid columnconfigure $history_tab {0 10} -minsize $margin
    grid columnconfigure $history_tab {1 3 5 7 9} -weight 1

    grid rowconfigure $history_tab {0 2 4} -minsize $margin
    grid rowconfigure $history_tab 1 -weight 1
    

    # Log tab ##########################################################
# this makes the display look like a Tektronix 4010!
    itk_component add text {
	text $log_tab.text \
	    -bg "\#003300" \
	    -fg "\#00cc00" \
	    -selectborderwidth 0 \
	    -state disabled \
	    -takefocus 1 \
 	    -selectbackground "\#00cc00" \
 	    -selectforeground "\#003300"
    } {
	usual
	ignore -background -foreground
	ignore -selectbackground -selectforeground -selectborderwidth
	ignore -highlightthickness
	rename -font entryfont entryFont Font
    }
    $itk_component(text) tag configure found \
	-background "\#00cc00" \
	-foreground "\#003300"
    bind $itk_component(text) <Up> {%W yview scroll -1 unit}
    bind $itk_component(text) <Down> {%W yview scroll +1 unit}
    bind $itk_component(text) <Prior> {%W yview scroll -1 page}
    bind $itk_component(text) <Next> {%W yview scroll +1 page}
    bind $itk_component(text) <1> [code $this clickText %x %y]
    bind $itk_component(text) <Control-f> [code $this searchLog forwards]
    bind $itk_component(text) <Control-g> [code $this searchLog backwards]
    bind $itk_component(text) <Escape> [code $this hideSearchPanel]
#added by luke
#key bindings for logviewer to stop and start autoscrolling
	bind $itk_component(text) <Control-Up> [code $this stopAutoscroll]
	bind $itk_component(text) <Control-Down> [code $this startAutoscroll]
	bind $itk_component(text) <Control-k> [code $this showKeywordPanel]
##############

    itk_component add text_scroll {
	scrollbar $log_tab.scroll \
	    -command [code $this component text yview] \
	    -orient vertical \
	    -takefocus 0 \
	    -highlightthickness 1
    } {
	usual
	ignore -highlightthickness
	ignore -takefocus
    }
    
    $itk_component(text) configure\
	-yscrollcommand [list autoscroll $itk_component(text_scroll)]

    itk_component add search_f {
	frame $log_tab.sf
    }

    itk_component add search_l {
	label $log_tab.sf.sl \
	    -text "Find: "
    }

    itk_component add search_e {
	gEntry $log_tab.sf.se \
	    -textvariable [scope search_term]
    }
    bind [$itk_component(search_e) component entry] <Control-f> [code $this searchLog forwards]
    bind [$itk_component(search_e) component entry] <Control-g> [code $this searchLog backwards]
    bind [$itk_component(search_e) component entry] <Escape> [code $this hideSearchPanel]
    trace add variable [scope search_term] write [code $this newSearch]

    itk_component add find_next_tb {
	Toolbutton $log_tab.sf.fn \
	    -type "amodal" \
	    -image ::img::find_next_16x16 \
	    -command [code $this searchLog forwards]
    }

    itk_component add find_previous_tb {
	Toolbutton $log_tab.sf.fp \
	    -type "amodal" \
	    -image ::img::find_previous_16x16 \
	    -command [code $this searchLog backwards]
    }

    itk_component add hide_search_tb {
	Toolbutton $log_tab.sf.hs \
	    -type "amodal" \
	    -image ::img::dismiss_16x16 \
	    -command [code $this hideSearchPanel]
    }

	itk_component add keyword_f {
		frame $log_tab.kf 
	}

    itk_component add keyword_l {
	label $log_tab.kf.kl \
	    -text "Mosflm Keyword: "
    }

    itk_component add keyword_e {
	gEntry $log_tab.kf.ke \
		-textvariable [scope mosflm_keyword]
    }
    bind [$itk_component(keyword_e) component entry] <Return> [code $this sendKeyword]
	
    itk_component add hide_keyword_tb {
	Toolbutton $log_tab.kf.hk \
	    -type "amodal" \
	    -image ::img::dismiss_16x16 \
	    -command [code $this hideKeywordPanel]
    }



    grid x $itk_component(text) $itk_component(text_scroll) x \
	-sticky nswe \
	-pady 7
    grid x $itk_component(search_f) - x \
	-sticky we \
	-pady [list 0 7]
#    grid remove $itk_component(search_f)
    grid columnconfigure $log_tab { 0 3 } -minsize 7
    grid columnconfigure $log_tab { 1 } -weight 1
    grid rowconfigure $log_tab { 0 } -weight 1
	
    pack $itk_component(search_l) $itk_component(search_e) $itk_component(find_next_tb) $itk_component(find_previous_tb) $itk_component(hide_search_tb) -side left
    pack $itk_component(search_e) -fill x -expand 1

#	pack $itk_component(keyword_f) 	
	grid x $itk_component(keyword_f) - x \
	-sticky we \
	-pady [list 0 7]
    grid remove $itk_component(search_f)
#	grid remove $itk_component(keyword_f)
	pack $itk_component(keyword_l) $itk_component(keyword_e) $itk_component(hide_keyword_tb)  -side left
	pack $itk_component(keyword_e) -fill x -expand 1
	grid remove $itk_component(keyword_f)
#	grid x $itk_component(keyword_e)

    eval itk_initialize $args

}

body HistoryViewer::updateButtons { } {
    # Enable undo button if there is a first event and it's 'done'
    set enable_undo 0
    set l_first_category [$itk_component(event_tree) item firstchild root]
    if {$l_first_category != ""} {
	set l_first_subcategory [$itk_component(event_tree) item firstchild $l_first_category]
	set l_first_event $events_by_item([$itk_component(event_tree) item firstchild $l_first_subcategory])
	if {[$l_first_event isDone]} {
	    set enable_undo 1
	}
    }
    if {$enable_undo} {
	$itk_component(undo) configure -state "normal"
    } else {
	$itk_component(undo) configure -state "disabled"
    }
    # Enable redo button if there is a last event and it's 'undone'
    set enable_redo 0 
    set l_last_category [$itk_component(event_tree) item lastchild root]
    if {$l_last_category != ""} {
	set l_last_subcategory [$itk_component(event_tree) item lastchild $l_last_category]
	set l_last_event $events_by_item([$itk_component(event_tree) item lastchild $l_last_subcategory])
	if {![$l_last_event isDone]} {
	    set enable_redo 1
	}
    }
    if {$enable_redo} {
	$itk_component(redo) configure -state "normal"
    } else {
	$itk_component(redo) configure -state "disabled"
    }
}


body HistoryViewer::recordEvent { an_event } {
    # Get category and subcategory of current event
    set l_current_category_item [$itk_component(event_tree) item lastchild root]
    if {$l_current_category_item != ""} {
	set l_current_category [$itk_component(event_tree) item text $l_current_category_item 0]
	set l_current_subcategory_item [$itk_component(event_tree) item lastchild $l_current_category_item]
	if {$l_current_subcategory_item != ""} {
	    set l_current_subcategory [$itk_component(event_tree) item text $l_current_subcategory_item 0]
	} else {
	    set l_current_subcategory ""
	}
    } else {
	set l_current_category ""
	set l_current_subcategory ""
    }

    # Get category and subcategory of new event
    set l_new_category [$an_event getCategory]
    set l_new_subcategory [$an_event getSubcategory]
    set l_new_event_name [$an_event getName]
    set l_new_event_description [$an_event getDescription]

    if {($l_new_category == "") ||
	($l_new_subcategory == "") ||
	($l_new_event_name == "") ||
	($l_new_event_description == "")} {
	error "Cat: \"$l_new_category\", subcat: \"$l_new_subcategory\", name: \"$l_new_event_name\", description: \"$l_new_event_description\""
    }

    set l_new_category_flag 0
    # If a new category is required create it
    if {$l_new_category != $l_current_category} {
	set l_new_category_flag 1
	# collapse old category
	if {$l_current_category != ""} {
	    $itk_component(event_tree) item collapse $l_current_category_item
	}
	# collapse old subcategory
	if {$l_current_subcategory != ""} {
	    $itk_component(event_tree) item collapse $l_current_subcategory_item
	}
	set l_current_category_item [$itk_component(event_tree) item create -button 1]
	$itk_component(event_tree) item style set $l_current_category_item 0 s1 1 s2
	$itk_component(event_tree) item text $l_current_category_item 0 $l_new_category
	$itk_component(event_tree) item element configure $l_current_category_item 0 e_icon -image [list [$an_event getCategoryIcon] DONE [$an_event getCategoryIcon] !DONE ]
	$itk_component(event_tree) item state set $l_current_category_item { DONE }
	$itk_component(event_tree) item lastchild root $l_current_category_item
	set events_by_item($l_current_category_item) ""

	set l_current_category $l_new_category
    }

    # If a new subcategory is required create it (including if a new
    #    category was just created!)
    if {($l_new_subcategory != $l_current_subcategory) || $l_new_category_flag} {
	# collapse old subcategory
	if {$l_current_subcategory != ""} {
	    $itk_component(event_tree) item collapse $l_current_subcategory_item
	}
	set l_current_subcategory_item [$itk_component(event_tree) item create -button 1]
	$itk_component(event_tree) item style set $l_current_subcategory_item 0 s1 1 s2
	$itk_component(event_tree) item text $l_current_subcategory_item 0 "$l_new_subcategory"
	$itk_component(event_tree) item element configure $l_current_subcategory_item 0 e_icon -image [list [$an_event getSubcategoryIcon] DONE [$an_event getSubcategoryIcon] !DONE ]
	$itk_component(event_tree) item state set $l_current_subcategory_item { DONE }
	$itk_component(event_tree) item lastchild $l_current_category_item $l_current_subcategory_item	
	set events_by_item($l_current_subcategory_item) ""

	set l_current_subcategory $l_new_subcategory
    }
    
    # Create a new event item and add it to the tree
    set l_event_item [$itk_component(event_tree) item create]
    $itk_component(event_tree) item style set $l_event_item 0 s1 1 s2
    $itk_component(event_tree) item text $l_event_item 0 $l_new_event_name 1 $l_new_event_description
    $itk_component(event_tree) item element configure $l_event_item 0 e_icon -image [list [$an_event getEventIcon] DONE [$an_event getEventIcon] !DONE ]
    $itk_component(event_tree) item state set $l_event_item { DONE }
    $itk_component(event_tree) item lastchild $l_current_subcategory_item $l_event_item
    set events_by_item($l_event_item) $an_event
    set items_by_event($an_event) $l_event_item

    # enable undo and disable redo
    $itk_component(undo) configure -state "normal"
    $itk_component(redo) configure -state "disabled"
}

body HistoryViewer::eraseEvent { an_event } {
    # Get event's subcategory and category items
    set l_subcategory [$itk_component(event_tree) item parent $items_by_event($an_event)]
    set l_category [$itk_component(event_tree) item parent $l_subcategory]
    # Delete the event item
    $itk_component(event_tree) item delete $items_by_event($an_event)
    # If the subcategory is now empty, delete it
    if {[$itk_component(event_tree) item numchildren $l_subcategory] == 0} {
	$itk_component(event_tree) item delete $l_subcategory
	# If the category is now empty, delete it
	if {[$itk_component(event_tree) item numchildren $l_category] == 0} {
	    $itk_component(event_tree) item delete $l_category
	}
    }
}

body HistoryViewer::markDone { a_event } {
    # set event item's state to done
    $itk_component(event_tree) item state set $items_by_event($a_event) DONE
    # if it's the first in the subcategory...
    if {[$itk_component(event_tree) item prevsibling $items_by_event($a_event)] == ""} {
	# set subcategory's state to DONE
	set l_subcategory [$itk_component(event_tree) item parent $items_by_event($a_event)]
	$itk_component(event_tree) item state set $l_subcategory DONE
	# if it's the first subcategory in the category...
	if {[$itk_component(event_tree) item prevsibling $l_subcategory] == ""} {
	    # set category's state to DONE
	    set l_category [$itk_component(event_tree) item parent $l_subcategory]
	    $itk_component(event_tree) item state set $l_category DONE
	}
    }
}

body HistoryViewer::markUndone { a_event } {
    # set event item's state to done
    $itk_component(event_tree) item state set $items_by_event($a_event) !DONE
    # if it's the first in the subcategory...
    if {[$itk_component(event_tree) item prevsibling $items_by_event($a_event)] == ""} {
	# set subcategory's state to !DONE
	set l_subcategory [$itk_component(event_tree) item parent $items_by_event($a_event)]
	$itk_component(event_tree) item state set $l_subcategory !DONE
	# if it's the first subcategory in the category...
	if {[$itk_component(event_tree) item prevsibling $l_subcategory] == ""} {
	    # set category's state to !DONE
	    set l_category [$itk_component(event_tree) item parent $l_subcategory]
	    $itk_component(event_tree) item state set $l_category !DONE
	}
    }
}

body HistoryViewer::undo { } {
    $history undo
    updateButtons
}

body HistoryViewer::redo { } {
    $history redo
    updateButtons
}

body HistoryViewer::reverse { } {
    foreach i_item [$itk_component(event_tree) selection get] {
	set l_event $events_by_item($i_item)
	if {$l_event != ""} {
	    $history reverse $l_event
	}
    }
}

body HistoryViewer::repeat { } {
    foreach i_item [$itk_component(event_tree) selection get] {
	set l_event $events_by_item($i_item)
	if {$l_event != ""} {
	    $history repeat $l_event
	}
    }
}

body HistoryViewer::changeHistory { a_history } {
    set history $a_history
    # Rebuild event tree
    $itk_component(event_tree) item delete all
    foreach i_event [$history getEvents] {
	recordEvent $i_event
	if {[$i_event isDone]} {
	    $itk_component(event_tree) item state set $items_by_event($i_event) { DONE }
	} else {
	    $itk_component(event_tree) item state set $items_by_event($i_event) { !DONE }
	}
    }
    updateButtons
}

body HistoryViewer::updateEventSelection { a_selected a_deselected } {
    if {$a_selected == ""} {
	$itk_component(reverse) configure -state "disabled"
	$itk_component(repeat) configure -state "disabled"
    } else {
	set l_event_count 0
	set l_unreversible_count 0
	set l_unrepeatable_count 0
	foreach i_item [$itk_component(event_tree) selection get] {
	    set l_event $events_by_item($i_item)
	    if {$l_event != ""} {
		incr l_event_count
		if {![$l_event isReversible]} { incr l_unreversible_count }
		if {![$l_event isRepeatable]} { incr l_unrepeatable_count }
	    }
	}
	if {($l_event_count > 0) && ($l_unreversible_count == 0)} {
	    $itk_component(reverse) configure -state "normal"
	} else {
	    $itk_component(reverse) configure -state "disabled"
	}
	if {($l_event_count > 0) && ($l_unrepeatable_count == 0)} {
	    $itk_component(repeat) configure -state "normal"
	} else {
	    $itk_component(repeat) configure -state "disabled"
	}
    }
}

body HistoryViewer::monitor { } {
    # Try and read from pipe
    if {[eof $::mosflm_pipe] || [catch {gets $::mosflm_pipe line}]} {
	# reading failed -> turn off monitoring
	fileevent $::mosflm_pipe readable {}
    } else {
	$itk_component(text) configure -state normal
	$itk_component(text) insert end "$line\n"
	$itk_component(text) configure -state disabled
#added by luke 
#test whether autoscrolling of the logviewer should be on or off
#relevant methods are HistoryViewer::stopAutoscroll and
#HistoryViewer::startAutoscroll
	if {$autoscrollbool == 1} {
		$itk_component(text) yview -pickplace end
	}
#########
    }
}

# Tabbing method ##########################################################

body HistoryViewer::tabbing { event } {
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

body HistoryViewer::launch { } {

    # Show stage
    grid $itk_component(hull) -row 0 -column 1 -sticky nswe

    # display associated toolbar
    # TO DO...

}

body HistoryViewer::hide { } {
    grid forget $itk_component(hull)
}

body HistoryViewer::showKeywordPanel { } {
	if {![winfo ismapped $itk_component(keyword_f)]} {
		grid $itk_component(keyword_f)
    	focus [$itk_component(keyword_e) component entry]
	}
}

body HistoryViewer::hideKeywordPanel { } {
		grid remove $itk_component(keyword_f)
    	focus $itk_component(text)
}


# Log search ###########################################################
body HistoryViewer::clickText { x y } {
    focus $itk_component(text)
    set current_search_position [$itk_component(text) index @$x,$y]
}

body HistoryViewer::showSearchPanel { } {
    grid $itk_component(search_f)
    focus [$itk_component(search_e) component entry]
    [$itk_component(search_e) component entry] selection range 0 end
}

body HistoryViewer::hideSearchPanel { } {
    # Remove tag (highlight) from any previous found term.
    $itk_component(text) tag delete found 
    grid remove $itk_component(search_f)
    focus $itk_component(text)
}
#added by luke
#The two methods below toggle an instance variable that is checked in the
#HistoryViewer::monitor method. The check is used to stop and start the 
#logviewer autoscrolling. The bound keys are Control-Up and Control-Down
#and these are set 
body HistoryViewer::stopAutoscroll {} {
	set autoscrollbool 0
}

body HistoryViewer::startAutoscroll {} {
	set autoscrollbool 1
}
#####################

body HistoryViewer::sendKeyword { } {
	if {$mosflm_keyword != ""} {
		$::mosflm sendCommand "$mosflm_keyword" 
	}
	set mosflm_keyword ""
#	$::mosflm sendCommand "luke"
#	puts "you pressed enter"
}



body HistoryViewer::searchLog { { a_direction "" } { a_new_term "no" } } {
    # Update search direction if necessary
    if {$a_direction != ""} {
	set search_direction $a_direction
    }
    # Get current search_position
    if {[$itk_component(text) tag ranges found] != {}} {
	set l_found [$itk_component(text) index found.first]
	regexp  {(\d+)\.(\d+)} $l_found l_match l_line l_char
	if {($search_direction == "forwards") && ($a_new_term == "no") } {
	    incr l_char
	}
	set current_search_position ${l_line}.$l_char
    } else {
	if {$search_direction == "forwards"} {
	    set current_search_position "0.0"
	} else {
	    set current_search_position end
	}
    }
    # Remove tag (highlight) from any previous found term.
    $itk_component(text) tag delete found 
    if {$search_term != ""} {
# 	if {$search_direction == "forwards"} {
# 	    set l_stop_index "end"
# 	} else {
# 	    set l_stop_index "0.0"
# 	}
	if {[string equal $search_term [string tolower $search_term]]} {
	    set l_loc [$itk_component(text) search -nocase -$search_direction -count l_characters -- $search_term $current_search_position]
	} else {
	    set l_loc [$itk_component(text) search -$search_direction -count l_characters -- $search_term $current_search_position]
	}
	if {$l_loc != ""} {
	    $itk_component(search_e) configure -textbackground white
	    regexp {(\d+)\.(\d+)} $l_loc l_match l_line l_char
	    incr l_char $l_characters
	    $itk_component(text) tag add found $l_loc ${l_line}.$l_char
	    $itk_component(text) tag configure found \
		-background "\#00cc00" \
		-foreground "\#003300"
	    after idle [list $itk_component(text) see $l_loc]
	} else {
	    $itk_component(search_e) configure -textbackground pink
	}
    }
    if {![winfo ismapped $itk_component(search_f)]} {
	showSearchPanel
    }
    focus [$itk_component(search_e) component entry]
}    

body HistoryViewer::newSearch { args } {
    searchLog forwards new_term
}

# Usual options

usual HistoryViewer {} 
