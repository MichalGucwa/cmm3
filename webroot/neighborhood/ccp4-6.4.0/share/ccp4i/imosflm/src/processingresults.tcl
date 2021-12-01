# $Id: processingresults.tcl,v 1.12 2012/03/26 16:36:39 ccb Exp $
package provide processingresults 1.0

class Processingresults {

    # common data variables

    common refinement_list { beam_x beam_y distance yscale tilt twist tangential_offset radial_offset global_absolute_rms_residual central_absolute_rms_residual global_weighted_rms_residual beam_y_corrected }

    common postrefinement_list { phi_x phi_y phi_z cell_a cell_b cell_c cell_alpha cell_beta cell_gamma mosaicity }

    common fixable_parameters { beam_x beam_y distance yscale tilt twist tangential_offset radial_offset cell_a cell_b cell_c cell_alpha cell_beta cell_gamma mosaicity }

    # Parameter info
    protected common name ; #array
    protected common short_name ; #array
    protected common long_name ; #array
    protected common precision ; #array
    protected common units ; #array

    # common procedures
    public proc getParameters { a_param_class } {
	return [set ${a_param_class}_list]
    }

    public proc parameterIsFixable { a_param } {
	if {[lsearch $fixable_parameters $a_param] > -1} {
	    return 1
	} else {
	    return 0
	}
    }

#    public proc getLongParameterName { a_parameter } {
#	if {[info exists long_name($a_parameter)]} {
#	    return $long_name($a_parameter)
#	} else {
#	    return ""
#	}
#    }

#these appear in the refinement and integration panes
# names appear in the parameter list and in the tool tip
    public proc initialize { } {
	set name(beam_x) "Beam x"
	set name(beam_y) "Beam y"
	set name(beam_y_corrected) "Beam y"
	set name(distance) "Distance"
	set name(yscale) "Y-scale"
	set name(tilt) "Tilt"
	set name(twist) "Twist"
	set name(tangential_offset) "Tangential offset"
	set name(radial_offset) "Radial offset"
	set name(global_absolute_rms_residual) "RMS residual"
	set name(global_weighted_rms_residual) "RMS res. (weighted)"
	set name(central_absolute_rms_residual) "RMS res. (central)"
# short names appear by the plots	
	set short_name(beam_x) "$name(beam_x)"
	set short_name(beam_y) "$name(beam_y)"
	set short_name(beam_y_corrected) "$name(beam_y_corrected)"
	set short_name(distance) "Dist"
	set short_name(yscale) "$name(yscale)"
	set short_name(tilt) "$name(tilt)"
	set short_name(twist) "$name(twist)"
	set short_name(tangential_offset) "Toff"
	set short_name(radial_offset) "Roff"
	set short_name(global_absolute_rms_residual) "RMS R"
	set short_name(global_weighted_rms_residual) "RMS R (w)"
	set short_name(central_absolute_rms_residual) "RMS R (c)"

	set units(beam_x) "mm"
	set units(beam_y) "mm"
	set units(beam_y_corrected) "mm"
	set units(distance) "mm"
	set units(yscale) ""
	set units(tilt) "\u00b0"
	set units(twist) "\u00b0"
	set units(tangential_offset) "mm"
	set units(radial_offset) "mm"
	set units(global_absolute_rms_residual) "mm"
	set units(global_weighted_rms_residual) ""
	set units(central_absolute_rms_residual) "mm"
	
	set long_name(beam_x) "Direct beam X coordinate ($units(beam_x))"
	set long_name(beam_y) "Direct beam Y coordinate ($units(beam_y))"
	set long_name(beam_y_corrected) "Direct beam Y coordinate ($units(beam_y_corrected))"
	set long_name(distance) "Detector distance ($units(distance))"
	set long_name(yscale) "Scale factor for Y coordinates"
	set long_name(tilt) "Detector tilt ($units(tilt))"
	set long_name(twist) "Detector twist ($units(twist))"
	set long_name(tangential_offset) "Misalignment parameter (spiral IP only) ($units(tangential_offset))"
	set long_name(radial_offset) "Misalignment parameter (spiral IP only) ($units(radial_offset))"
	set long_name(global_absolute_rms_residual) "RMS error in spot positions ($units(global_absolute_rms_residual))"
	set long_name(global_weighted_rms_residual) "Weighted RMS error in spot positions"
	set long_name(central_absolute_rms_residual) "RMS error in spot positions in centre of detector ($units(central_absolute_rms_residual))"

	set precision(beam_x) 2
	set precision(beam_y) 2
	set precision(beam_y_corrected) 2
	set precision(distance) 2
	set precision(yscale) 4
	set precision(tilt) 2
	set precision(twist) 2
	set precision(tangential_offset) 3
	set precision(radial_offset) 3
	set precision(global_absolute_rms_residual) 3
	set precision(global_weighted_rms_residual) 3
	set precision(central_absolute_rms_residual) 3
	

	set name(phi_x) "\u03c6(x)"
	set name(phi_y) "\u03c6(y)"
	set name(phi_z) "\u03c6(z)"
	set name(cell_a) "a"
	set name(cell_b) "b"
	set name(cell_c) "c"
	set name(cell_alpha) "\u03b1"
	set name(cell_beta) "\u03b2"
	set name(cell_gamma) "\u03b3"
	set name(mosaicity) "Mosaicity"
	
	set short_name(phi_x) "\u03c6(x)"
	set short_name(phi_y) "\u03c6(y)"
	set short_name(phi_z) "\u03c6(z)"
	set short_name(cell_a) "a"
	set short_name(cell_b) "b"
	set short_name(cell_c) "c"
	set short_name(cell_alpha) "\u03b1"
	set short_name(cell_beta) "\u03b2"
	set short_name(cell_gamma) "\u03b3"
	set short_name(mosaicity) "Mosaic"

	set units(phi_x) "\u00b0"
	set units(phi_y) "\u00b0"
	set units(phi_z) "\u00b0"
	set units(cell_a) "\u212b"
	set units(cell_b) "\u212b"
	set units(cell_c) "\u212b"
	set units(cell_alpha) "\u00b0"
	set units(cell_beta) "\u00b0"
	set units(cell_gamma) "\u00b0"
	set units(mosaicity) "\u00b0"

	set long_name(phi_x) "Missetting angle $short_name(phi_x) ($units(phi_x))"
	set long_name(phi_y) "Missetting angle $short_name(phi_y) ($units(phi_y))"
	set long_name(phi_z) "Missetting angle $short_name(phi_z) ($units(phi_z))"
	set long_name(cell_a) "$short_name(cell_a) cell parameter ($units(cell_a))"
	set long_name(cell_b) "$short_name(cell_b) cell parameter ($units(cell_b))"
	set long_name(cell_c) "$short_name(cell_c) cell parameter ($units(cell_c))"
	set long_name(cell_alpha) "$short_name(cell_alpha) cell angle ($units(cell_alpha))"
	set long_name(cell_beta) "$short_name(cell_beta) cell angle ($units(cell_beta))"
	set long_name(cell_gamma) "$short_name(cell_gamma) cell angle ($units(cell_gamma))"
	set long_name(mosaicity) "$short_name(mosaicity)ity ($units(mosaicity))"
	
	set precision(phi_x) "2"
	set precision(phi_y) "2"
	set precision(phi_z) "2"
	set precision(cell_a) "2"
	set precision(cell_b) "2"
	set precision(cell_c) "2"
	set precision(cell_alpha) "2"
	set precision(cell_beta) "2"
	set precision(cell_gamma) "2"
	set precision(mosaicity) "3"
    }

    # Member variables

    # images
    protected variable image_files_being_processed {}

    # Params refined in positional refinement
    public variable beam_x 0.000
    public variable beam_y 0.000
    public variable beam_y_corrected 0.000
    public variable distance 0.000
    public variable yscale 1.000
    public variable tilt 0.000
    public variable twist 0.000
    public variable tangential_offset 0.000
    public variable radial_offset 0.000
    public variable global_absolute_rms_residual 0.000
    public variable global_weighted_rms_residual 0.000
    public variable central_absolute_rms_residual 0.000
    public variable central_weighted_rms_residual 0.000
    
    # Params refined in postrefinement
    protected variable phi_x 0.000
    protected variable phi_x_sd 0.000
    protected variable phi_y 0.000
    protected variable phi_y_sd 0.000
    protected variable phi_z 0.000
    protected variable phi_z_sd 0.000
    protected variable cell_a 0.000
    protected variable cell_a_sd 0.000
    protected variable cell_b 0.000
    protected variable cell_b_sd 0.000
    protected variable cell_c 0.000
    protected variable cell_c_sd 0.000
    protected variable cell_alpha 0.000
    protected variable cell_alpha_sd 0.000
    protected variable cell_beta 0.000
    protected variable cell_beta_sd 0.000
    protected variable cell_gamma 0.000
    protected variable cell_gamma_sd 0.000
    protected variable mosaicity 0.000
    protected variable mosaicity_sd 0.000

    # Profile
    protected variable profiles ; # array

    # Methods

    public method updateProcessingStatus
    public method getImages
    public method getImageFiles
    public method getProgress
    public method appendDatum
    public method updateStdDev
    public method getCellStdDev
    public method getDatum
    public method getData
    public method getProfile
    public method getProfileNames
    public method getDataSet
    public method getImageDataSet
    public method getParameterName
    public method storeProfile
    public method displayProfile
    
    public method serializeVariables
    public method serializeProfiles

    protected method updateSession

    constructor { a_method args } { }
}

body Processingresults::constructor { a_method args } {
    
    if {$a_method == "new"} {
	# Build list of files being processed
	if {$args != {}} {
	    foreach i_im $args {
		lappend image_files_being_processed [$i_im getFullPathName]
	    }
	    set image_files_being_processed [lsort -dictionary $image_files_being_processed]
	}
	# initialize parameters
	foreach i_param [concat $refinement_list $postrefinement_list] {
	    # Try and get the parameter value from the session
	    if {[catch {set $i_param [$::session getParameterValue $i_param]}]} {
		# if that fails, initialize the parameter to ""
		set $i_param [list ""]
	    }
	}
	#puts "phi_x initial [getData phi_x]"
    } elseif {$a_method == "copy"} {
	# Copy list of files being processed
	set image_files_being_processed [$args getImageFiles]
	# Copy data
	foreach i_param [concat $refinement_list $postrefinement_list] {
	    set $i_param [$args getData $i_param]
	}
	#puts "phi_x copied  [getData phi_x]"
	# and sd's
	foreach i_param $postrefinement_list {
	    set ${i_param}_sd [$args getData ${i_param}_sd]
	}
	# Copy profiles
	foreach i_profile_name [$args getProfileNames] {
	    set profiles($i_profile_name) \
		[namespace current]::[Profile \#auto "copy" [$args getProfile $i_profile_name]]
	}    
    } elseif {$a_method == "xml"} {
	# Extract list of files being processed
	set image_files_being_processed [$args getAttribute image_files_being_processed]
	# not sure the image objects can be initialized from XML
	# Extract data
	foreach i_param [concat $refinement_list $postrefinement_list] {
	    set $i_param [$args getAttribute $i_param]
	}
	# and sd's
	foreach i_param $postrefinement_list {
	    set ${i_param}_sd [$args getAttribute ${i_param}_sd]
	}
	# Extract profiles
	foreach i_profile_node [$args selectNodes profile] {
	    set l_profile [namespace current]::[Profile \#auto "xml" $i_profile_node]
	    set profiles([$l_profile getLabel]) $l_profile
	}    
	if {[llength $image_files_being_processed] == 0} {
	    error "Created results object with no image files!"
	}
    }
}

body Processingresults::updateProcessingStatus { a_reason a_name } {

    # initialize update flags
    set l_update_refinement_flag 0
    set l_update_postrefinement_flag 0
    #puts "Reason $a_reason Image name $a_name"

    # Calculate number of images processed before this one
    set l_num_images_processed [lsearch -glob $image_files_being_processed \*$a_name]
    #puts "Number of images processed $l_num_images_processed"

    # Get the current image object via its filename
    set i_image_file [lindex $image_files_being_processed $l_num_images_processed]
    set i_image [Image::getImageByPath $i_image_file]
    #puts "Image $i_image"

    set l_num [$i_image getNumber]

    # Measure number of positional refinement results
    set l_num_positional_refs [expr [llength $beam_x] - 1]

    # Measure number of postrefinement results
    set l_num_postrefs [expr [llength $cell_a] - 1]

    # Pad postrefinement vars if necessary
    while {$l_num_postrefs < $l_num_images_processed} {
	foreach i_param $postrefinement_list {
	    if { [regexp phi_? $i_param] == 1 } {
		# Do not fill the first missets for the next sector with the last from this.
		# Instead use the null value from the head of the list.
		lappend $i_param [lindex [set $i_param] 0]
		#if {[llength [set $i_param]] > 2} {
		#    puts "$i_param [set $i_param]"
		#}
	    } else {
		lappend $i_param [lindex [set $i_param] end]
	    }
	}
	set l_num_postrefs [expr [llength $cell_a] - 1]
	# and set the flag to update the postrefinement graph
	set l_update_postrefinement_graph 1
    }

    # Depending on update reason....
    if {$a_reason == "postrefinement"} {
	set l_message "Postrefining image $l_num"
    } else {
	# Truncate data if necessary
	if {$l_num_positional_refs > $l_num_images_processed} {
	    # Truncate existing positional refinement data
	    foreach i_param $refinement_list {
		set $i_param [lrange [set $i_param] 0 $l_num_images_processed]
	    }
	    # If truncating set message accordingly
	    if {$a_reason == "refinement"} {
		set l_message "Returning to process image $l_num because the orientation has changed too much"
	    } else {
		# assume refinement repeat
		set l_message "Re-refining image $l_num"
	    }
	    # Set positional refinement update flag
	    set l_update_refinement_flag 1
	} else {
	    # Not truncating, therefore return simple status message
	    set l_message "Refining image $l_num"
	}
	# Truncate postrefinement data if necessary too
	if {$l_num_postrefs > $l_num_images_processed} {
	    # Truncate existing positional refinement data
	    foreach i_param $postrefinement_list {
		set $i_param [lrange [set $i_param] 0 $l_num_images_processed]
	    }
	    # Set postrefinement update flag
	    set l_update_postrefinement_flag 1
	}
    }
    # Return status message, and update flags
    #puts "$l_message $l_update_refinement_flag $l_update_postrefinement_flag"
    return [list $l_message $l_update_refinement_flag $l_update_postrefinement_flag]
}

body Processingresults::getProgress { } {
    set l_total [expr [llength $image_files_being_processed] * 2]
    set l_num_positionally_refined [expr [llength $beam_x] - 1]
    set l_num_postrefined [expr [llength $phi_x] - 1]
    set l_proportion [expr double($l_num_positionally_refined + $l_num_postrefined) / $l_total]
    set l_percent [format %.0f [expr $l_proportion * 100]]
    return $l_percent
}

body Processingresults::appendDatum { a_param a_value } {
    lappend $a_param [format %.$precision($a_param)f $a_value]
}

body Processingresults::updateStdDev { a_param a_value } {
    set $a_param $a_value
}

body Processingresults::getCellStdDev { } {
    set l_cell_std_dev [list $cell_a_sd $cell_b_sd $cell_c_sd $cell_alpha_sd $cell_beta_sd $cell_gamma_sd]
    set l_formatted_cell_std_dev {}
    foreach i_param $l_cell_std_dev {
	lappend l_formatted_cell_std_dev [format %.[Cell::getPrecision]f $i_param]
    }
    return $l_formatted_cell_std_dev
}

body Processingresults::getDatum { a_param {a_index end} } {
    return [lindex [set $a_param] $a_index]
}

body Processingresults::getData { a_param } {
    return [set $a_param]
}

body Processingresults::storeProfile { a_name a_width a_height a_data a_mask } {
    
    set l_profile [namespace current]::[Profile \#auto "new" $a_name $a_width $a_height $a_data $a_mask] 

    # If replacing a stored object we could delete the old object first to free some memory
    if {[info exists profiles($a_name)]} {
	#puts "Deleting $this $profiles($a_name)"
	delete object $profiles($a_name)
    }
    set profiles($a_name) $l_profile
    #puts "$this profiles($a_name) stores $l_profile"
}

body Processingresults::getProfile { a_name } {
    return $profiles($a_name)
}

body Processingresults::getProfileNames { } {
    return [lsort [array names profiles]]
}

body Processingresults::displayProfile { a_name a_canvas } {
    $profiles($a_name) display $a_canvas
}

body Processingresults::getDataSet { a_param } {
    set ds [namespace current]::[Dataset \#auto [set $a_param] [Unit::getUnit $units($a_param)] $name($a_param) $short_name($a_param)]
    #puts "$this $ds"
    return $ds
}

body Processingresults::getImages { } {
    set l_image_list {}
    foreach i_image_file $image_files_being_processed {
        lappend l_image_list [Image::getImageByPath $i_image_file]
    }
    return $l_image_list
}

body Processingresults::getImageFiles { } {
    return $image_files_being_processed
}

body Processingresults::getImageDataSet { } {
    set l_data {}
    foreach i_image_file $image_files_being_processed {
	set i_image [Image::getImageByPath $i_image_file]
	lappend l_data [$i_image getNumber]
    }
    # Prepends a 'zero-th' point to the data set for plotting
    set l_data [concat [expr [lindex $l_data 0] - 1] $l_data]
    set ds [namespace current]::[Dataset \#auto $l_data [Unit::getUnit ""] "Image" "Image"]
    #puts "$this $ds"
    return $ds
}

body Processingresults::getParameterName { a_param } {
    return $name($a_param)
} 

body Processingresults::updateSession { { a_reason "" } } {
    #puts "Processingresults::updateSession $a_reason"
    if {$a_reason == ""} {
	set l_reason "Processing"
    } else {
	set l_reason $a_reason
    }

    # update simple parameters in session
    foreach i_param { beam_x beam_y distance yscale tilt twist tangential_offset radial_offset mosaicity beam_y_corrected } {
	$::session updateSetting $i_param [lindex [set $i_param] end] 1 1 $l_reason
    }

    # update mis-sets as was done in r1.9
    # get index of first available misset
    set l_first_available 0
    while {([lindex $phi_x $l_first_available] == "") && 
	   ($l_first_available < [llength $image_files_being_processed])} {
	incr l_first_available
    }
    #puts "l_first_available $l_first_available"
    if {[lindex $phi_x $l_first_available] != ""} {
	set l_first_phi_x [lindex $phi_x $l_first_available]
	set l_first_phi_y [lindex $phi_y $l_first_available]
	set l_first_phi_z [lindex $phi_z $l_first_available]
	
	set i_index 1
	foreach i_image_file $image_files_being_processed {
	    if {$i_index < $l_first_available} {
		set l_phi_x $l_first_phi_x
		set phi_x [lreplace $phi_x $i_index $i_index $l_phi_x]
		set l_phi_y $l_first_phi_y
		set phi_y [lreplace $phi_y $i_index $i_index $l_phi_y]
		set l_phi_z $l_first_phi_z
		set phi_z [lreplace $phi_z $i_index $i_index $l_phi_z]
	    } else {
		set l_phi_x [lindex $phi_x $i_index]
		set l_phi_y [lindex $phi_y $i_index]
		set l_phi_z [lindex $phi_z $i_index]
	    }
	    # get session image
	    set l_image [Image::getImageByPath $i_image_file]
	    $l_image updateMissets $l_phi_x $l_phi_y $l_phi_z 1 1 $l_reason
	    incr i_index
	}
    }
}

body Processingresults::serializeVariables { } {
    set xml " image_files_being_processed=\"$image_files_being_processed\""
	foreach i_param [concat $refinement_list $postrefinement_list] {
	    append xml " $i_param=\"[set $i_param]\""
	}
    foreach i_param $postrefinement_list {
	append xml " ${i_param}_sd=\"[set ${i_param}_sd]\""
    }

    return $xml
}

body Processingresults::serializeProfiles { } {
    set xml ""
    foreach { i_profile_name i_profile } [array get profiles] {
	append xml [$i_profile serialize]
    }
    return $xml
}    

# Initialize common member variable arrays
Processingresults::initialize

# Cell-refinement results #################################

class Cellrefinementresults {
    inherit Processingresults
    
    # procedures

    public proc initialize { } {
	set name(summary_rms_positional_error) "RMS residual"
	set name(summary_pixel_ratio) "Pixel ratio"
	set name(summary_distance) "Distance"
	
	set short_name(summary_rms_positional_error) "RMS residual"
	set short_name(summary_pixel_ratio) "Pixel ratio"
	set short_name(summary_distance) "Distance"
	
	set units(summary_rms_positional_error) "mm"
	set units(summary_pixel_ratio) ""
	set units(summary_distance) "mm"
    }	

    # summary variables
    
    private variable cycles "0"
    private variable summary_rms_positional_error ; # array
    private variable summary_pixel_ratio ; # array
    private variable summary_distance ; # array
    
    private variable initial_cell ""
    private variable final_cell ""

    private variable final_matrix ""

    public method getCycles

    public method setFinalCell
    public method getCell

    public method setFinalMatrix

    public method recordSummaryData
    public method getSummaryDataSets
    public method listSummaryData

    public method serialize

    public method updateSession

    constructor { a_method args } {
	eval Processingresults::constructor $a_method $args
    } {
	
	if { $a_method == "new" } {
	    catch {set initial_cell [namespace current]::[Cell \#auto "copy" "initial" [$::session getCell]]}
	    #catch {set final_cell [namespace current]::[Cell \#auto "copy" "final" [$::session getCell]]}
	} elseif { $a_method == "copy" } {
	    set cycles [$args getCycles]
	    foreach i_summary { summary_rms_positional_error summary_pixel_ratio summary_distance } {
		array set $i_summary [$args listSummaryData $i_summary]
	    }
	    set initial_cell [namespace current]::[Cell \#auto "copy" "initial" [$args getCell "initial"]]
	    if {[$args getCell "final"] != ""} {
		set final_cell [namespace current]::[Cell \#auto "copy" "final" [$args getCell "final"]]
	    }
	} elseif { $a_method == "xml" } {
	    # Extract cycles
	    set cycles [$args getAttribute cycles]
	    # Extract summary data arrays
	    foreach i_summary { summary_rms_positional_error summary_pixel_ratio summary_distance } {
		array set $i_summary [$args getAttribute $i_summary]
	    }
	    # Extract cells
	    set initial_cell [namespace current]::[Cell \#auto "xml" "initial" [$args selectNodes {cell[@name='initial']}]]
	    set l_initial_cell_node [$args selectNodes {cell[@name='initial']}]
	    if {$l_initial_cell_node != ""} {
		set initial_cell [namespace current]::[Cell \#auto "xml" "initial" $l_initial_cell_node]
	    }
	    set l_final_cell_node [$args selectNodes {cell[@name='final']}]
	    if {$l_final_cell_node != ""} {
		set final_cell [namespace current]::[Cell \#auto "xml" "final" $l_final_cell_node]
	    }
	}
    }
}

body Cellrefinementresults::getCycles { } {
    return $cycles
}

body Cellrefinementresults::setFinalCell { a_value_list } {
    if {$final_cell == ""} {
	set final_cell [namespace current]::[Cell \#auto "blank" "final"]
    }
    eval $final_cell setCell $a_value_list
}

# hrp 03.10.2006 new code to handle matrix after refinement
# but this is private and not propagated throughout the code - but it should be. This is
# the matrix that should be used for everything after here. I don't understand...
body Cellrefinementresults::setFinalMatrix { a_value_list } {
    if {$final_matrix == ""} {
	set final_matrix [namespace current]::[Matrix \#auto "blank" "final"]
    }
    eval $final_matrix setMatrix $a_value_list
}

body Cellrefinementresults::getCell { a_type } {
    return [set ${a_type}_cell]
}
    
body Cellrefinementresults::recordSummaryData { a_measure a_cycle a_data_list } {
    set summary_${a_measure}($a_cycle) $a_data_list
    if {$a_cycle > $cycles} {
	set cycles $a_cycle
    }
}

body Cellrefinementresults::listSummaryData { a_measure } {
    return [array get $a_measure]
}

body Cellrefinementresults::getSummaryDataSets { a_measure } {
    set i_cycle 0
    set l_datasets {}
    while {$i_cycle < $cycles} {
	incr i_cycle
	lappend l_datasets [namespace current]::[Dataset \#auto [set summary_${a_measure}($i_cycle)] [Unit::getUnit $units(summary_$a_measure)] $name(summary_$a_measure) "Cycle $i_cycle"]
    }
    #puts "$this $l_datasets"
    return $l_datasets
}

body Cellrefinementresults::updateSession { } {
    Processingresults::updateSession "Cell_refinement"
    if {$final_cell != ""} {
	$::session updateCell "Cell_refinement" $final_cell
    }
#hrp 03.10.2006 - I have no idea where I should be trying to update the matrix
# it seems that it's always stored privately rather than publicly. try here...
    if {$final_matrix != ""} {
	set a11 [lindex $final_matrix 0]
	set a12 [lindex $final_matrix 1]
	set a13 [lindex $final_matrix 2]
	set a21 [lindex $final_matrix 3]
	set a22 [lindex $final_matrix 4]
	set a23 [lindex $final_matrix 5]
	set a31 [lindex $final_matrix 6]
	set a32 [lindex $final_matrix 7]
	set a33 [lindex $final_matrix 8]
    }
}

body Cellrefinementresults::serialize { } {
    set xml "<cell_refinement_results cycles=\"$cycles\""
    append xml [serializeVariables]
    foreach i_summary { summary_rms_positional_error summary_pixel_ratio summary_distance } {
	append xml " $i_summary=\"[array get $i_summary]\""
    }
    append xml ">"
    append xml [serializeProfiles]
    if {$initial_cell != ""} {
	append xml [$initial_cell serialize]
    }
    if {$final_cell != ""} {
	append xml [$final_cell serialize]
    }
    append xml "</cell_refinement_results>"
    return $xml
}

# Initialize common member variable arrays
Cellrefinementresults::initialize

# Integration results #####################################

class Integrationresults {
    inherit Processingresults

    # procedures

    public proc getLongParameterName { a_parameter } {
	if {[info exists long_name($a_parameter)]} {
	    return $long_name($a_parameter)
	} else {
	    return ""
	}
    }

    public proc initialize { } {
	set name(mean_profile_fitted) "<I/\u03c3(I)> (prf)"
	set name(mean_summation_integration) "<I/\u03c3(I)> (sum)"
	set name(total_spot_count) "Reflections"
	set name(outer_profile_fitted) "<I/\u03c3(I)> HR (prf)"
	set name(outer_summation_integration) "<I/\u03c3(I)> HR (sum)"
	set name(outer_spot_count) "Reflections HR"
	set name(overloads) "Overloads"
	set name(badspots)  "Bad spots"
	set name(soverlaps) "Spatial overlaps"

	set short_name(mean_profile_fitted) "<I/\u03c3(I)> (prf)"
	set short_name(mean_summation_integration) "<I/\u03c3(I)> (sum)"
	set short_name(total_spot_count) "Reflections"
	set short_name(outer_profile_fitted) "<I/\u03c3(I)> HR (prf)"
	set short_name(outer_summation_integration) "<I/\u03c3(I)> HR (sum)"
	set short_name(outer_spot_count) "Reflections HR"
	set short_name(overloads) "Overloads"
	set short_name(badspots)  "Bad spots"
	set short_name(soverlaps) "Spatial overlaps"

	set long_name(mean_profile_fitted) "Mean I/\u03c3(I) profile fitted intensities"
	set long_name(mean_summation_integration) "Mean I/\u03c3(I) summation integration intensities"
	set long_name(total_spot_count) "Total Number of reflections"
	set long_name(outer_profile_fitted) "Mean I/\u03c3(I) highest resolution bin (profile fitted)"
	set long_name(outer_summation_integration) "Mean I/\u03c3(I) highest resolution bin (summation integration)"
	set long_name(outer_spot_count) "Reflections in highest resolution bin"
	set long_name(overloads) "Number of overloads"
	set long_name(badspots)  "Number of bad spots"
	set long_name(soverlaps) "Number of spatial overlaps"

	set precision(mean_profile_fitted) "2"
	set precision(mean_summation_integration) "2"
	set precision(total_spot_count) "0"
	set precision(outer_profile_fitted) "2"
	set precision(outer_summation_integration) "2"
	set precision(outer_spot_count) "0"
	set precision(overloads) "0"
	set precision(badspots)  "0"
	set precision(soverlaps) "0"

	set units(mean_profile_fitted) ""
	set units(mean_summation_integration) ""
	set units(total_spot_count) ""
	set units(outer_profile_fitted) ""
	set units(outer_summation_integration) ""
	set units(outer_spot_count) ""
	set units(overloads) ""
	set units(badspots)  ""
	set units(soverlaps) ""
    }

    # common variables
    
    private common results_list { mean_profile_fitted mean_summation_integration total_spot_count outer_profile_fitted outer_summation_integration outer_spot_count overloads badspots soverlaps}

    # member variables

    # regional profiles

    private variable profile_grids ; # array

    # Integration summary feedback

    private variable total_spot_count_fulls {}
    private variable mean_profile_fitted_fulls {}
    private variable mean_summation_integration_fulls {}
    private variable total_spot_count_partials {}
    private variable mean_profile_fitted_partials {}
    private variable mean_summation_integration_partials {}

    private variable outer_spot_count_fulls {}
    private variable outer_profile_fitted_fulls {}
    private variable outer_summation_integration_fulls {}
    private variable outer_spot_count_partials {}
    private variable outer_profile_fitted_partials {}
    private variable outer_summation_integration_partials {}

    private variable overloads_fulls {}
    private variable overloads_partials {}
    private variable badspots_fulls {}
    private variable badspots_partials {}
    private variable soverlaps_fulls {}
    private variable soverlaps_partials {}

    private variable integrated_image_names {}
    private variable histograms ; # array do not initialize

    public method addProfileGrid
    public method listProfileGrids
    public method addRegionalProfile
    public method displayRegionalProfiles
    public method getNextIntegrand
    public method addHistogramData
    public method recordImageAsIntegrated
    public method listIntegratedImages
    public method listHistogramData
    public method getResultMeasures
    public method appendResult
    public method getLastResult
    public method getNthResult
    public method getResults
    public method getResultDataSets
    public method getHistogramData

    public method getProgress
    public method getIntegrationStatus

    public method updateSession
    public method serialize
    
    constructor { a_method args } { 
	eval Processingresults::constructor $a_method $args
    } {
    
	if {$a_method == "new"} {
	    # intialize results as blanks
	    foreach i_measure $results_list {
		set ${i_measure}_fulls [list ""]
		set ${i_measure}_partials [list ""]
	    }
	} elseif {$a_method == "copy"} {
	    # Copy results lists
	    foreach i_measure $results_list {
		set ${i_measure}_fulls [$args getResults $i_measure fulls]
		set ${i_measure}_partials [$args getResults $i_measure partials]
	    }
	    # Copy profile grid
	    foreach { i_block i_profile_grid } [$args listProfileGrids] {
		set profile_grids($i_block) [namespace current]::[ProfileGrid \#auto "copy" $i_profile_grid]
	    }
	    # Copy histograms
	    set integrated_image_names [$args listIntegratedImages]
	    array set histograms [$args listHistogramData]
	} elseif {$a_method == "xml"} {
	    # Extract results
	    foreach  i_measure $results_list {
		set ${i_measure}_fulls [$args getAttribute ${i_measure}_fulls]
		set ${i_measure}_partials [$args getAttribute ${i_measure}_partials]
	    }
	    # Extract profile grids
	    foreach i_node [$args selectNodes profile_grid] {
		set l_profile_grid [namespace current]::[ProfileGrid \#auto "xml" $i_node]
		set profile_grids([$l_profile_grid getBlock]) $l_profile_grid
	    }
	    # Extract histograms
	    set integrated_image_names [$args getAttribute integrated_images]
	    array set histograms [$args getAttribute histograms]
	}
    }
}

body Integrationresults::addProfileGrid { a_block a_num_x a_num_y } {
    
    set l_grid [namespace current]::[ProfileGrid \#auto "new" $a_block $a_num_x $a_num_y]

    # If replacing a stored object we could delete the old object first to free some memory - never calls the following
#    if {[info exists profile_grids($a_block)]} {
#	puts "Deleting $this $profile_grids($a_block)"
#	delete object $profile_grids($a_block)
#    }
    set profile_grids($a_block) $l_grid
    #puts "$this profile_grids($a_block) stores $l_grid"
}

body Integrationresults::addRegionalProfile { a_block a_box a_width a_height a_original_source a_averaged_source } {

    $profile_grids($a_block) addProfile $a_box $a_width $a_height $a_original_source $a_averaged_source

}

body Integrationresults::listProfileGrids { } {
    return [array get profile_grids]
}

body Integrationresults::displayRegionalProfiles { a_block a_canvas } {
    $a_canvas delete all
    $profile_grids($a_block) display $a_canvas
}

body Integrationresults::addHistogramData { a_name a_type a_data } {
    set histograms($a_name,$a_type) $a_data
}

body Integrationresults::recordImageAsIntegrated { a_name } {
    # Integration result lists begin with a blank entry so decrement count
    set l_num_integrated [expr [llength $mean_profile_fitted_fulls] - 1]
    set l_next_image_file [lindex $image_files_being_processed $l_num_integrated]
    set l_next_image_name [file tail $l_next_image_file]
    lappend integrated_image_names $l_next_image_name
    return
}

body Integrationresults::listIntegratedImages { } {
    return [lsort $integrated_image_names]
}

body Integrationresults::listHistogramData { } {
    return [array get histograms]
}

body Integrationresults::getResultMeasures { } {
    return $results_list
}

body Integrationresults::appendResult { a_result a_value } {
    regexp {(.+)_[^_]+$} $a_result match l_measure
    if { $precision($l_measure) == "" } {
	puts "Expecting a number for precision of $l_measure"
	puts "result: $a_result match: $match measure: $l_measure value: $a_value format: \%\.$precision($l_measure)f"
	lappend $a_result [format %.0f $a_value]
    } else {
	lappend $a_result [format %.$precision($l_measure)f $a_value]
    }
}    

body Integrationresults::getNthResult { a_result a_type num } {
    return [lindex [set ${a_result}_${a_type}] $num]
}

body Integrationresults::getLastResult { a_result a_type } {
    return [lindex [set ${a_result}_${a_type}] end]
}

body Integrationresults::getResults { a_result a_type } {
    return [set ${a_result}_${a_type}]
}

body Integrationresults::getResultDataSets { a_result } {
    # A hack for Overloads, Bad spots & Spatial overlaps for which processing of the partials data is skipped AND we dont want ' full' appended to the name
    if { $a_result != "overloads" && $a_result != "badspots" && $a_result != "soverlaps" } {
	set l_datasets [namespace current]::[Dataset \#auto [set ${a_result}_fulls]  [Unit::getUnit $units($a_result)] "$name($a_result) full" "$short_name($a_result) full"]
	lappend l_datasets [namespace current]::[Dataset \#auto [set ${a_result}_partials] [Unit::getUnit $units($a_result)] "$name($a_result) part" "$short_name($a_result) part"]
    } else {
	set l_datasets [namespace current]::[Dataset \#auto [set ${a_result}_fulls]  [Unit::getUnit $units($a_result)] "$name($a_result)" "$short_name($a_result)"]
    }
    #puts "$this $l_datasets"
    return $l_datasets
}

body Integrationresults::getHistogramData { a_name a_type} {
    return $histograms($a_name,$a_type)
}

body Integrationresults::getNextIntegrand { } {

    set l_num_integration_results [llength l_datasets]

    set l_num_integrated [llength $integrated_image_names]

    set l_next_image_file [lindex $image_files_being_processed $l_num_integrated]

    set l_next_image [Image::getImageByPath $l_next_image_file]

    return [$l_next_image getNumber]
}

body Integrationresults::getIntegrationStatus { } {
    set l_num_integrated [llength $integrated_image_names]
    set l_num_postrefined [expr [llength $phi_x] - 1]
    if {$l_num_integrated < $l_num_postrefined} {
	set l_last_name [lindex $integrated_image_names end]
	set l_last_image [lindex [getImages] [lsearch -glob [getImageFiles] \*$l_last_name]]
	set l_last_num [$l_last_image getNumber]
	set l_next_image_num [expr $l_last_num + 1]
	return "Integrating image number $l_next_image_num"
    } else {
	return ""
    }
}

body Integrationresults::getProgress { } {
    set l_total [expr [llength $image_files_being_processed] * 3]
    set l_num_positionally_refined [expr [llength $beam_x] - 1]
    set l_num_postrefined [expr [llength $phi_x] - 1]
    set l_num_integrated [llength $integrated_image_names]
    set l_proportion [expr double($l_num_positionally_refined + $l_num_postrefined + $l_num_integrated) / $l_total]
    set l_percent [format %.0f [expr $l_proportion * 100]]
    return $l_percent
}

body Integrationresults::updateSession { } {
    Processingresults::updateSession "Integration"
    
    set l_new_cell_data {}
    foreach i_param { cell_a cell_b cell_c cell_alpha cell_beta cell_gamma } {
	lappend l_new_cell_data [lindex [set $i_param] end]
    }
#The check to test whether the length of l_new_cell_data is zero was failing
#if the i_params were empty strings. In that case, a list of 6 empty elements
#was being created so l_new_cell_data still had a length of six. I added the join
#statement to get around this problem
    if {[expr [llength [join $l_new_cell_data]] != 0]} {
#	puts "cell length data [expr [llength $l_new_cell_data]]"
	set l_new_cell [namespace current]::[eval Cell \#auto "initialize" "foo" $l_new_cell_data]
	$::session updateCell "Integration" $l_new_cell
    }
}

body Integrationresults::serialize { } {
    set xml "<integration_result"
    append xml [serializeVariables]
    foreach i_measure $results_list {
	append xml " ${i_measure}_fulls=\"[set ${i_measure}_fulls]\""
	append xml " ${i_measure}_partials=\"[set ${i_measure}_partials]\""
    }
    append xml " integrated_images=\"$integrated_image_names\""
    append xml " histograms=\"[array get histograms]\">"
    append xml [serializeProfiles]
    foreach { i_block i_profile_grid } [array get profile_grids] {
	append xml [$i_profile_grid serialize]
    }
    append xml "</integration_result>"
}

# Initialize common member variable arrays
Integrationresults::initialize

# Profiles ################################################################

class Profile {

    # common pointers to images used for displaying profiles

    common profile_small ; # array
    common profile_large ; # array

    # member variables

    protected variable max_data_value 255
    protected variable label ""
    protected variable width ""
    protected variable height ""
    protected variable raw_data {}
    protected variable mask {}
    protected variable data {}
    protected variable edge {}

    # methods

    protected method build
    public method create
    public method int2hex
    public method post
    public method place
    public method display

    public method getLabel
    public method getWidth
    public method getHeight
    public method getMaxValue
    public method getRawData
    public method getMask

    public method serialize

    constructor { a_method args } { }
}

body Profile::constructor { a_method args } {
    if {$a_method == "new"} {
	eval build $args
    } elseif {$a_method == "copy"} {
	set label [$args getLabel]
	set max_data_value [$args getMaxValue]
	set width [$args getWidth]
	set height [$args getHeight]
	set raw_data [$args getRawData]
	set mask [$args getMask]
    } elseif {$a_method == "xml"} {
	set label [$args getAttribute label]
	set max_data_value [$args getAttribute max_data_value]
	set width [$args getAttribute width]
	set height [$args getAttribute height]
	set raw_data [$args getAttribute raw_data]
	set mask [$args getAttribute mask]
    }
    foreach { data edge } [create $raw_data $mask] break
}

body Profile::build { args } {
    if {[llength $args] > 5} {
	set max_data_value [lindex $args end]
    }
    set label [lindex $args 0]
    set width [lindex $args 1]
    set height [lindex $args 2]
    set raw_data [lindex $args 3]
    set mask [lindex $args 4]

}    

body Profile::create { a_data a_mask } {
    
    # N.B. Raster starts in bottom left, working up columns!

    set i_pixel 0
    set i_row 0
    set i_col 0
    set l_data {}
    set l_edge {}
    #set l_row {}
    set pixel "off"
    
    # Loop through each pixel in the profile
    while {$i_pixel < ($width * $height)} {

	# Calculate pixel position
	set i_row [expr ($height - 1) - ($i_pixel % $height)]
	set i_col [expr $i_pixel / $height]

	# Calculate the hex code for the colour
	if {[lindex $a_data $i_pixel] >= 0} {
	    if {[lindex $a_data $i_pixel] > $max_data_value} {
		set datum "\#ff00ff"
	    } else {
		# Test putting the int2hex conversion in a method
		#set code [format %02x [expr 255 - int(([lindex $a_data $i_pixel]) * (255.0 / $max_data_value))]]
		#set datum "\#${code}${code}${code}"
		set datum [int2hex [lindex $a_data $i_pixel] $max_data_value]
	    }
	} else {
	    set datum "\#ffcc00"
	}

	# added the pixel to the row pixel list
	lappend l_row($i_row) $datum

	# Build the mask edge line

	# if you're in the masked area...
	if {[lindex $a_mask $i_pixel] > 0} {
	    # ... but you weren't last loop
	    if {$pixel == "off"} {
		set pixel "on"
		# ... add the left hand edge of the pixel to the coords list,
		# bottom first
		set l_edge [concat \
				[expr $i_col + 1] [expr $i_row + 1] \
				$i_col [expr $i_row + 1] \
				$l_edge]
	    }
	} else {
	    # or your out of the masked area, and you were IN last loop...
	    if {$pixel == "on"} {
		set pixel "off"
		# ...add the left hand edge of the pixel, top first
		lappend l_edge \
		    $i_col [expr $i_row + 1] \
		    [expr $i_col + 1] [expr $i_row + 1]
	    }
	}
	
	# increment the counter looping through pixels
	incr i_pixel
    }

    # Add the rows to the image data
    set i_row 0 
    while {$i_row < $height} {
	lappend l_data $l_row($i_row)
	incr i_row
    }

    # Join up the edge coord list to complete the circle
    eval lappend l_edge [lrange $l_edge 0 1] 

    return [list $l_data $l_edge]

}

body Profile::int2hex { num max } {
    # Return the hex code for the pixel colour given by integer num <= max value
    set code [format %02x [expr {255 - int(($num) * (255.0 / $max))}]]
    return "\#${code}${code}${code}"
}

body Profile::post { a_canvas a_zoom } {

    # Delete existing profile images for this canvas
    catch {image delete $profile_small($a_canvas)}
    catch {image delete $profile_large($a_canvas)}
    
    # Put the image data into the tk image
    set profile_small($a_canvas) [image create photo]
    $profile_small($a_canvas) put $data
    
    # Create the large display image by scaling the small image 
    set profile_large($a_canvas) [image create photo]
    $profile_large($a_canvas) copy $profile_small($a_canvas) -zoom $a_zoom
    $a_canvas delete profile
    $a_canvas create image 0 0 -image $profile_large($a_canvas) -anchor nw -tags [list profile]

    # Create the mask edge line and scale it to fit the zoomed image
    $a_canvas delete edge
    $a_canvas create line $edge -fill "\#3399ff" -tags edge 
    $a_canvas scale edge 0 0 $a_zoom $a_zoom

    # Create a border to the image
    $a_canvas delete border
    $a_canvas create rectangle 0 0 [image width $profile_large($a_canvas)] [image height $profile_large($a_canvas)] -outline "\#3399ff" -tags border
}


body Profile::place { a_canvas { a_x "" } { a_y "" } } {
    if {($a_x == "") || ($a_y == "")} {
	# Move image and line to the centre of the canvas
	set l_canvas_width [winfo width $a_canvas]
	if {$l_canvas_width <= 1} {
	    set l_canvas_width [winfo reqwidth $a_canvas]
	}
	set l_canvas_height [winfo height $a_canvas]

	set l_x_shift [expr ([winfo width $a_canvas] - [image width $profile_large($a_canvas)]) / 2.0]
	set l_y_shift [expr ([winfo height $a_canvas] - [image height $profile_large($a_canvas)]) / 2.0]
    } else {
	set l_x_shift $a_x
	set l_y_shift $a_y
    }
    $a_canvas coords profile { 0 0}
    $a_canvas move all $l_x_shift $l_y_shift
}

body Profile::display { a_canvas } {
    
    # Set the zoom so that the largest dimension fits inside the canvas
    set l_y_zoom [expr ([winfo height $a_canvas] - (2 * [$a_canvas cget -bd])) / $height]
    if {$l_y_zoom <= 1} {
	set l_y_zoom [expr ([winfo reqheight $a_canvas] - (2 * [$a_canvas cget -bd])) / $height]
    }

    set l_x_zoom [expr ([winfo width $a_canvas] - (2 * [$a_canvas cget -bd])) / $width]
    if {$l_x_zoom <= 1} {
	set l_x_zoom [expr ([winfo reqwidth $a_canvas] - (2 * [$a_canvas cget -bd])) / $width]
    }
	set l_zoom [expr $l_y_zoom < $l_x_zoom ? $l_y_zoom : $l_x_zoom]

    post $a_canvas $l_zoom

    place $a_canvas

}

body Profile::getLabel { } {
    return $label
}

body Profile::getWidth { } {
    return $width
}

body Profile::getHeight { } {
    return $height
}

body Profile::getMaxValue { } {
    return $max_data_value
}

body Profile::getRawData { } {
    return $raw_data
}

body Profile::getMask { } {
    return $mask
}

body Profile::serialize { } {
    set xml "<profile label=\"$label\" max_data_value=\"$max_data_value\" width=\"$width\" height=\"$height\" raw_data=\"$raw_data\" mask=\"$mask\"/>"
    return $xml
}

# Regional Profile ####################################################

class RegionalProfile {
    inherit Profile

    private variable grid ""
    private variable box ""
    private variable type "" 
    private variable alt_raw_data {}
    private variable alt_mask {}
    private variable alt_data {}
    private variable alt_edge {}

    private method build
    public method post
    public method place
    public method showAlt
    public method showDefault

    public method setGrid { a_grid } { set grid $a_grid }
    public method getGrid
    public method getBox
    public method getType
    public method getAltRawData
    public method getAltMask
    
    public method serialize

    constructor { a_method args } {
	eval Profile::constructor $a_method [lrange $args 1 end]
    } {
	if {$a_method == "new"} {
	    set grid [lindex $args 0]
	} elseif {$a_method == "copy"} {
	    set grid [lindex $args 0]
	    set l_regional_profile [lindex $args 1]
	    set grid [$l_regional_profile getGrid]
	    set box [$l_regional_profile getBox]
	    set type [$l_regional_profile getType]
	    set alt_raw_data [$l_regional_profile getAltRawData]
	    set alt_mask [$l_regional_profile getAltMask]
	} elseif {$a_method == "xml"} {
	    set grid [lindex $args 0]
	    set l_node [lindex $args 1]	    
	    set box [$l_node getAttribute box]
	    set type [$l_node getAttribute type]
	    set alt_raw_data [$l_node getAttribute alt_raw_data]
	    set alt_mask [$l_node getAttribute alt_mask]
	}
	if {$type == "dual"} {
	    foreach {alt_data alt_edge} [create $alt_raw_data $alt_mask] break
	}
    }

    destructor {
    }
}

body RegionalProfile::build { args } {
    set max_data_value "10000"
    set box [lindex $args 0]
    set width [lindex $args 1]
    set height [lindex $args 2]
    set type [lindex $args 3]    
    foreach { raw_data mask } [lindex $args 4] break
    foreach { alt_raw_data alt_mask } [lindex $args 5] break
}

body RegionalProfile::post { a_canvas a_zoom } {

    # Post default view
    Profile::post $a_canvas $a_zoom

    # Re-jigger images and image items from default post 
    catch {image delete $profile_small($a_canvas,$box,default)}
    catch {image delete $profile_large($a_canvas,$box,default)}
    set profile_small($a_canvas,$box,default) $profile_small($a_canvas)
    set profile_large($a_canvas,$box,default) $profile_large($a_canvas)
    set profile_small($a_canvas) ""
    set profile_large($a_canvas) ""
    $a_canvas delete regional_profile($box,default)
    $a_canvas itemconfigure profile -tags [list regional_profile($box,default) rp($box)]
    $a_canvas delete edge($box,default)
    $a_canvas itemconfigure edge -tags [list edge($box,default) rp($box)]
    $a_canvas delete border($box)
    if {$type == "original_only"} {
	$a_canvas itemconfigure border -tags [list border($box) rp($box)] -outline "\#3399ff"
    } else {
	$a_canvas itemconfigure border -tags [list border($box) rp($box)] -outline "\#bb0000"
    }

    # If there's an alternative view, then post that too!
    if {($alt_data != "") && ($alt_edge != "")} {

	# Delete existing profile images for this canvas
	catch {image delete $profile_small($a_canvas,$box,alt)}
	catch {image delete $profile_large($a_canvas,$box,alt)}
    
	# Put the image data into the tk image
	set profile_small($a_canvas,$box,alt) [image create photo]
	$profile_small($a_canvas,$box,alt) put $alt_data
    
	# Create the large display image by scaling the small image 
	set profile_large($a_canvas,$box,alt) [image create photo]
	$profile_large($a_canvas,$box,alt) copy $profile_small($a_canvas,$box,alt) -zoom $a_zoom
	$a_canvas delete regional_profile($box,alt)
	$a_canvas create image 0 0 -image $profile_large($a_canvas,$box,alt) -anchor nw -tags [list regional_profile($box,alt) rp($box)]
	
	# Create the mask edge line and scale it to fit the zoomed image
	$a_canvas delete edge($box,alt)
	$a_canvas create line $alt_edge -fill "\#bb0000" -tags [list edge($box,alt) rp($box)]
	$a_canvas scale edge($box,alt) 0 0 $a_zoom $a_zoom
	
	# Lower alt profile below default
	$a_canvas raise regional_profile($box,default) regional_profile($box,alt)
	$a_canvas raise edge($box,default) regional_profile($box,default)
	$a_canvas raise border($box)

	#$a_canvas bind regional_profile($box,alt) <Enter> [list +puts "Original"]

	# Set up flipping bindings
	$a_canvas bind regional_profile($box,blank) <ButtonPress-1> [code $this showAlt $a_canvas %X %Y]
	$a_canvas bind regional_profile($box,blank) <ButtonRelease-1> [code $this showDefault $a_canvas image %X %Y]
# 	$a_canvas bind edge($box,default) <ButtonPress-1> [code $this showAlt $a_canvas %X %Y]
# 	$a_canvas bind edge($box,default) <ButtonRelease-1> [code $this showDefault $a_canvas %X %Y]

	# Setup tool-tip bindings
	$a_canvas bind regional_profile($box,blank) <Enter> [list +showValueLabel "Averaged (Box $box)" "\#bb0000" "white" %X %Y]
# 	$a_canvas bind regional_profile($box,blank) <Motion> [list +moveValueLabel %X %Y]
# 	$a_canvas bind regional_profile($box,blank) <Leave> [list +hideValueLabel]
    } else {
	# Unset flipping bindings (since previous rps have had same tag!)
	$a_canvas bind regional_profile($box,blank) <ButtonPress-1> {}
	$a_canvas bind regional_profile($box,blank) <ButtonRelease-1> {}
	# Set up motion and Leave bindings (same for single and doubles)
	$a_canvas bind regional_profile($box,blank) <Enter> [list +showValueLabel "Original (Box $box)" "\#3399ff" "white" %X %Y]
    }
    $a_canvas bind regional_profile($box,blank) <Motion> [list +moveValueLabel %X %Y]
    $a_canvas bind regional_profile($box,blank) <Leave> [list +hideValueLabel]
    
    # Plot blank rectangle over top (pre-bound! see above)
    #  - catches all events regardless of what's visible under
    #    mouse (i.e. image, edge etc.)
    $a_canvas create rectangle [$a_canvas bbox regional_profile($box,default)] \
	-fill {} \
	-outline {} \
	-tags [list regional_profile($box,blank) rp($box)]


    # Jigger
    if {$width < [$grid getMaxWidth]} {
	$a_canvas move rp($box) [expr 0.5 * ([$grid getMaxWidth] - $width) * $a_zoom] 0
    }
    if {$height < [$grid getMaxHeight]} {
	$a_canvas move rp($box) 0 [expr 0.5 * ([$grid getMaxHeight] - $height) * $a_zoom]
    }
}

body RegionalProfile::place { a_canvas a_x a_y } {
    $a_canvas move rp($box) $a_x $a_y
}

body RegionalProfile::showAlt { a_canvas a_x a_y} {
    $a_canvas raise regional_profile($box,alt) regional_profile($box,default)
    $a_canvas raise edge($box,alt) regional_profile($box,alt)
    $a_canvas raise border($box)
    $a_canvas raise regional_profile($box,blank)
    $a_canvas itemconfigure border($box) -outline "\#3399ff"
    #showValueLabel "Original" "\#3399ff" "white" $a_x $a_y
    after 1 [list showValueLabel "Original (Box $box)" "\#3399ff" "white" $a_x $a_y]
    
}

body RegionalProfile::showDefault { a_canvas what a_x a_y} {
    $a_canvas raise regional_profile($box,default) regional_profile($box,alt)
    $a_canvas raise edge($box,default) regional_profile($box,default)
    $a_canvas raise border($box)
    $a_canvas raise regional_profile($box,blank)
    if {$type != "original_only"} {
	$a_canvas itemconfigure border($box) -outline "\#bb0000"
    } else {
	$a_canvas itemconfigure border($box) -outline "\#3399ff"
    }
    #showValueLabel "Averaged" "\#bb0000" "white" $a_x $a_y
    after 1 [list showValueLabel "Averaged (Box $box)" "\#bb0000" "white" $a_x $a_y]
}

body RegionalProfile::getGrid { } { return $grid }
body RegionalProfile::getBox { } { return $box }
body RegionalProfile::getType { } { return $type }
body RegionalProfile::getAltRawData { } { return $alt_raw_data }
body RegionalProfile::getAltMask { } { return $alt_mask }

body RegionalProfile::serialize { } {
    set xml "<regional_profile label=\"$label\" box=\"$box\" max_data_value=\"$max_data_value\" width=\"$width\" height=\"$height\" type=\"$type\" raw_data=\"$raw_data\" mask=\"$mask\" alt_raw_data=\"$alt_raw_data\" alt_mask=\"$alt_mask\"/>"
    return $xml
}

# Profile grid ###############################################

class ProfileGrid {

    private variable block ""
    private variable num_x ""
    private variable num_y ""
    private variable max_width 0
    private variable max_height 0
    private variable profiles ; # array

    public method addProfile
    public method display
    public method getBlock { } { return $block }
    public method getNums { } { return [list $num_x $num_y] }
    public method getMaxWidth
    public method getMaxHeight
    public method listProfiles { } { return [array get profiles] }

    public method serialize

    constructor { a_method args } {
	if {$a_method == "new"} {
	    foreach { block num_x num_y } $args break
	} elseif {$a_method == "copy"} {
	    set block [$args getBlock]
	    foreach { num_x num_y } [$args getNums] break
	    set max_width [$args getMaxWidth]
	    set max_height [$args getMaxHeight]
	    foreach { i_box i_regional_profile } [$args listProfiles] {
		set l_regional_profile [namespace current]::[RegionalProfile \#auto "copy" $this $i_regional_profile]
		#puts "Copied $l_regional_profile from $i_regional_profile"
		set profiles($i_box) $l_regional_profile
		#puts "$this profiles($i_box) stores $l_regional_profile"
	    }
	} elseif {$a_method == "xml"} {
	    set block [$args getAttribute block]
	    set num_x [$args getAttribute num_x]
	    set num_y [$args getAttribute num_y]
	    set max_width [$args getAttribute max_width]
	    set max_height [$args getAttribute max_height]
	    foreach i_node [$args selectNodes regional_profile] {
		set l_regional_profile [namespace current]::[RegionalProfile \#auto "xml" $this $i_node]
		set profiles([$l_regional_profile getBox]) $l_regional_profile
		#puts "$this profiles([$l_regional_profile getBox]) stores $l_regional_profile"
	    }
	}
    }
}

body ProfileGrid::serialize { } {
    set xml "<profile_grid block=\"$block\" num_x=\"$num_x\" num_y=\"$num_y\" max_width=\"$max_width\" max_height=\"$max_height\">"
    foreach { i_num i_profile } [array get profiles] {
	#puts "$i_num $i_profile"
	append xml [$i_profile serialize]
    }
    append xml "</profile_grid>"
    return $xml
}

body ProfileGrid::getMaxWidth { } {
    return $max_width
}

body ProfileGrid::getMaxHeight { } {
    return $max_height
}

body ProfileGrid::addProfile { a_box a_width a_height a_original_source a_averaged_source } {
    if {$a_original_source == ""} {
	set type "averaged_only"
	set main_source $a_averaged_source
	set alt_source ""
    } elseif {$a_averaged_source == ""} {
	set type "original_only"
	set main_source $a_original_source
	set alt_source ""
    } else {
	set type "dual"
	set main_source $a_averaged_source
	set alt_source $a_original_source
    }

    set l_profile [namespace current]::[RegionalProfile \#auto "new" $this $a_box $a_width $a_height $type $main_source $alt_source]
    
    # If replacing a stored object we could delete the old object first to free some memory - never calls the following
#    if {[info exists profiles($a_box)]} {
#	puts "Deleting $this $profiles($a_box)"
#	delete object $profiles($a_box)
#    }
    set profiles($a_box) $l_profile
    #puts "$this profiles($a_box) stores $l_profile"

    if {$a_width > $max_width} {
	set max_width $a_width
    }
    if {$a_height > $max_height} {
	set max_height $a_height
    }
}

body ProfileGrid::display { a_canvas } {
    
    # N.B. Profiles are number from bottom left, going up each column!!! 

    set l_margin 2

    # calculate minimum required space
    set l_min_x_space [expr $num_x * $max_width]
    set l_min_y_space [expr $num_y * $max_height]
    # Calculate margin space
    set l_margin_x_space [expr ($num_x - 1) * $l_margin]
    set l_margin_y_space [expr ($num_y - 1) * $l_margin]

    # calculate maximum possible zoom
    set l_y_zoom [expr ([winfo height $a_canvas] - (2 * [$a_canvas cget -bd])) / ($l_min_y_space + $l_margin_y_space)]
    set l_x_zoom [expr ([winfo width $a_canvas] - (2 * [$a_canvas cget -bd])) / ($l_min_x_space + $l_margin_x_space)]
    
    # If it won't fit at the current canvas size, try and fit at the requested canvas size
    if {$l_y_zoom <= 1} {
	set l_y_zoom [expr ([winfo reqheight $a_canvas] - (2 * [$a_canvas cget -bd])) / ($l_min_y_space + $l_margin_y_space)]
    }
    if {$l_x_zoom <= 1} {
	set l_x_zoom [expr ([winfo reqwidth $a_canvas] - (2 * [$a_canvas cget -bd])) / ($l_min_x_space + $l_margin_x_space)]
    }
    # if it still doesn't fit, just use a zoom of 1
    if {$l_y_zoom <= 1} {
	set l_y_zoom 1
    }
    if {$l_x_zoom <= 1} {
	set l_x_zoom 1
    }
    set l_zoom [expr $l_y_zoom < $l_x_zoom ? $l_y_zoom : $l_x_zoom]

    # calcluate actual space to be allowed for each profile
    set l_x_space [expr ($max_width * $l_zoom) + $l_margin]
    set l_y_space [expr ($max_height * $l_zoom) + $l_margin]

    # Calculate position of bottom left profile
    set l_bottom_left_x_pos [expr ([winfo width $a_canvas] - (2 * [$a_canvas cget -bd]) - (($l_x_space * $num_x) - $l_margin)) / 2]
    set l_bottom_left_y_pos [expr [winfo height $a_canvas] - (([winfo height $a_canvas] - (2 * [$a_canvas cget -bd]) - (($l_y_space * $num_y) - $l_margin)) / 2) - ($max_height * $l_zoom)]

    #puts "Top left of grid should be at: $l_left_limit,$l_top_limit"

    # loop through boxes
    set i_box 1
    while {$i_box <= ($num_x * $num_y)} {
	# get grid coords (0-indexed)
	set l_row [expr ($i_box - 1) % $num_x]
	set l_col [expr ($i_box - 1) / $num_y]
	# calculate top left window
	set l_x_pos [expr $l_bottom_left_x_pos + ($l_col * $l_x_space)] 
	set l_y_pos [expr $l_bottom_left_y_pos - ($l_row * $l_y_space)] 
	#puts "Displaying profile [expr $i_box + 1] at $l_window_left, $l_window_top"
	# display image
	if {[info exists profiles($i_box)]} {
	    $profiles($i_box) post $a_canvas $l_zoom
	    $profiles($i_box) place $a_canvas $l_x_pos $l_y_pos
	}
	# loop to next box
	incr i_box
    }
}

#body ProfileGrid::puff { } { }
