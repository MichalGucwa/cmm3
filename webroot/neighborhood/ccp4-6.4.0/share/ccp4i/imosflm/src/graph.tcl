#!/ss3/geoff/demo/bin/wish8.4
# $Id: graph.tcl,v 1.13 2012/03/26 16:36:38 ccb Exp $

package provide mosflmGraph 1.0


#set env(MOSFLM_GUI) /home/geoff/alpha

# ##############################################################################
# CLASS: Unit ##################################################################
# ##############################################################################

class Unit {
    common units ; # array
    public proc getUnits { } { return [array names units] }
    public proc getUnit { a_symbol } { return $units($a_symbol) }

    public variable symbol ""
    public variable name ""
    public method getName { } { return $name }
    public method getSymbol { } { return $symbol }

    constructor { a_symbol a_name } {
	set symbol $a_symbol
	set name $a_name
	set units($symbol) $this
	
    }

}

Unit \#auto "" ""
Unit \#auto "mm" "mm"
Unit \#auto "\u212b" "Ang."
Unit \#auto "\u00b0" "Deg."
Unit \#auto "perc." "perc."

# ##############################################################################
# CLASS: Data ##################################################################
# ##############################################################################

class Dataset {
    private variable data {}
    private variable unit ""
    private variable long_name ""
    private variable short_name ""
    
    constructor { a_data a_unit a_long_name a_short_name args } {
	set data $a_data
	set unit $a_unit
	set long_name $a_long_name
	set short_name $a_short_name
    }
    
    public method getData { } { return $data }
    public method getUnit { } { return $unit }
    public method getLongName { } { return $long_name }
    public method getShortName { } { return $short_name }
 
}

# ##############################################################################
# CLASS: Data ##################################################################
# ##############################################################################

class Binset {
    private variable bin_name ""
    private variable units ""
    private variable tick_labels {}
    private variable bin_labels {}

    constructor { a_bin_name a_tick_labels a_bin_labels a_unit} {
	set bin_name $a_bin_name
	set tick_labels $a_tick_labels
	set bin_labels $a_bin_labels
	set units $a_unit
    }
    
    public method getBinName { } { return $bin_name } 
    public method getTickLabels { } { return $tick_labels }
    public method getBinLabels { } { return $bin_labels } 
    public method getUnits { } { return $units } 
}

# ##############################################################################
# CLASS: Axis ##################################################################
# ##############################################################################

class Axis {
    protected variable graph ""
    protected variable canvas ""
    protected variable id ""

    protected variable type "real"
    protected variable min_val ""
    protected variable max_val ""
    protected variable raw_min_val ""
    protected variable raw_max_val ""
    protected variable tick_interval ""
    protected variable precision ""
    protected variable max_ticks ""

    protected method adjustRange
    protected method getPrecision
    protected method designAxis
    
    public method getMaxTicks

    constructor { a_canvas a_graph a_id a_min_val a_max_val args } { }
}

body Axis::constructor { a_canvas a_graph a_id a_min_val a_max_val args } {
    options {-type "real"} $args
    set canvas $a_canvas
    set graph $a_graph
    set id $a_id
    set type $options(-type)
    set min_val $a_min_val
    set max_val $a_max_val
    set raw_min_val $a_min_val
    set raw_max_val $a_max_val
}

body Axis::getMaxTicks { } {
    if {$max_ticks == ""} {
	error "Trying to get axis's tick limit before it has been set"
    }
    
    return $max_ticks
}
	

body Axis::adjustRange { } {

    # Calculate value range for current units
    set l_val_range [expr $max_val - $min_val]
    
    # Make a small one if it's zero
    if {[catch {expr log10($l_val_range)}]} {
	set max_val [expr 1.01 * $max_val]
	set min_val [expr 0.99 * $min_val]
	set l_val_range [expr $max_val - $min_val]
    }
    # Check if the range is still zero (This can happen if the min and max vals are both zero).
    if {[catch {expr log10($l_val_range)}]} {
	set max_val "0.01"
	set min_val "0.00"
	set l_val_range [expr $max_val - $min_val]
    }
}

body Axis::getPrecision { } {
    if {$type == "int"} {
	set precision 0
    } else {
	# Calculate tick label precision according to tick intervals
	#  or axis range if tick interval unkown
	if {$tick_interval != ""} {
	    set l_val $tick_interval
	} else {
	    set l_val [expr $max_val - $min_val]
	}
	if {$l_val == 0} {
	    set l_val 0.01
	}
	set l_order_of_magnitude [expr log10($l_val)]
	if {$l_order_of_magnitude < 0} {
	    set precision [expr int(-floor($l_order_of_magnitude))]
	} else {
	    set precision 0
	}
    }    
}

body Axis::designAxis { { hidden 0 } } {

    # Adjust range (in case it's zero)
    adjustRange
	
    if {$max_ticks == ""} {
	error "Trying to design axis before tick limit has been set!"
    } else {
	if {$hidden || ($max_ticks == 0)} {
	    # Not enough room - just create minimal axis for scalign etc.
 	    #set min_val $raw_min_val
 	    #set max_val $raw_max_val
	    #set tick_interval [expr $raw_max_val - $raw_min_val]
	    set l_val_range [expr $max_val - $min_val]
	    set tick_interval [expr $max_val - $min_val]
	} else {
	    set l_val_range [expr $max_val - $min_val]
	    # Calculate the order of magnitude of the current units' axis
###########################################################################
#added by luke because l_val_range would come out blank in tcl/tk 8.5. Not required for tcl/tk 8.4
		if {$l_val_range == 0} {
			set l_val_range 1
#			puts $l_val_range
		}
###########################################################################
	    set l_order_of_magnitude [expr int(floor(log10($l_val_range))-1)]
	    
	    # Calculate a rouned range to 2 sig. fig.
	    set l_2sf_range [expr int(ceil(double($l_val_range) / pow(10,$l_order_of_magnitude)))]
		
	    
	    # Calculate appropriate tick intervals for the number of ticks calculate earlier
	    set l_2sf_tick_interval [expr int(ceil(double($l_2sf_range) / $max_ticks))]
	    if {$l_2sf_tick_interval >  50} {
		set l_2sf_tick_interval 100
	    } elseif {$l_2sf_tick_interval > 40} {
		set l_2sf_tick_interval 50
	    } elseif {$l_2sf_tick_interval > 25} {
		set l_2sf_tick_interval 40
	    } elseif {$l_2sf_tick_interval > 20} {
		set l_2sf_tick_interval 25
	    } elseif {$l_2sf_tick_interval > 10} {
		set l_2sf_tick_interval 20
	    } elseif {$l_2sf_tick_interval > 5} {
		set l_2sf_tick_interval 10
	    } elseif {$l_2sf_tick_interval == 3} {
		set l_2sf_tick_interval 4
	    } else {
		# leave l_2sf_tick_interval as is (1,2,4 or 5)
	    }

	    # Calculate rounded min and max values (to 2 s.f.)
	    set l_2sf_min_val [expr int(floor(double($min_val) / pow(10,$l_order_of_magnitude)))]
	    set l_2sf_max_val [expr int(ceil(double($max_val) / pow(10,$l_order_of_magnitude)))]

	    # If the new limits aren't multiples of the tick interval then correct them
	    if {($l_2sf_min_val % $l_2sf_tick_interval) != 0} {
		set l_2sf_min_val [expr ($l_2sf_min_val / $l_2sf_tick_interval) * $l_2sf_tick_interval]
	    }
	    if {($l_2sf_max_val % $l_2sf_tick_interval) != 0} {
		set l_2sf_max_val [expr (($l_2sf_max_val / $l_2sf_tick_interval) + 1) * $l_2sf_tick_interval]
	    }
	    
	    # Calculate the final value range limits for these units 
	    set min_val [expr $l_2sf_min_val * pow(10,$l_order_of_magnitude)]
	    set max_val [expr $l_2sf_max_val * pow(10,$l_order_of_magnitude)]
	    set tick_interval [expr $l_2sf_tick_interval * pow(10,$l_order_of_magnitude)]

	    if {$type == "int"} {
		set tick_interval [expr int(ceil($tick_interval))]
		# Extend min and max if not on new integer tick interval
		set min_val [expr int(floor($min_val))]
		if {$min_val % $tick_interval != 0} {
		    set min_val [expr int (ceil($min_val / $tick_interval) * $tick_interval)]
		}
		set max_val [expr int(ceil($max_val))]
		if {$max_val % $tick_interval != 0} {
		    set max_val [expr int (ceil($max_val / $tick_interval) * $tick_interval)]
		}
	    }
	}
	# Recalculate precison, now tick interval is known
	getPrecision
    }
}

# ##############################################################################
# CLASS: XAxis #################################################################
# ##############################################################################

class XAxis {
    inherit Axis

    private variable ticklabels {}

    public method post
    public method scale
    public method slide
    public method wipe
    public method guessTickLabelWidth
    
    private method calcMaxTicks
    private method draw


    constructor { a_canvas a_graph a_id a_min_val a_max_val args } {
	options {-type "real" -ticklabels {}} $args
	Axis::constructor $a_canvas $a_graph $a_id $a_min_val $a_max_val -type $options(-type)
    } {
	options {-type "real" -ticklabels {}} $args
	if {$options(-type) == "int"} {
	    set ticklabels $options(-ticklabels)
	}
    }
}

body XAxis::post { a_left_limit a_right_limit { hidden 0 } } {
    calcMaxTicks $a_left_limit $a_right_limit
    designAxis $hidden
    draw
}

body XAxis::slide { a_height } {
    # Move x-axis (and data) in y to align with available space
    $canvas move x_axis($id) 0 $a_height    
}  
  
body XAxis::wipe { } {
    $canvas delete x_axis($id)
}

body XAxis::guessTickLabelWidth { } {
    getPrecision
    $canvas create text 0 0 -text "0[format %.${precision}f $max_val]" -tags [list graph($id) temp($id) temp_x_tick_label($id)]
    set t_bbox [$canvas bbox temp_x_tick_label($id)]
    set l_width [expr [lindex $t_bbox 2] - [lindex $t_bbox 0]]
    $canvas delete temp($id)
    return $l_width
}

body XAxis::calcMaxTicks { a_left_limit a_right_limit } {

    # Generate tick labels with appropriate precision for max and min values
    getPrecision
    set t_min_tick_label [format %.${precision}f $min_val]
    set t_max_tick_label [format %.${precision}f $max_val]

    # Pick the longest one
    if {[string length $t_min_tick_label] > [string length $t_max_tick_label]} {
	set t_tick_label $t_min_tick_label
    } else {
	set t_tick_label $t_max_tick_label
    }
    # Create a label and measure its width
    $canvas create text 0 0 -text "000$t_tick_label" -tags [list graph($id) temp($id) temp_x_tick_label($id)]
    set t_bbox [$canvas bbox temp_x_tick_label($id)]
    set t_tick_label_width [expr [lindex $t_bbox 2] - [lindex $t_bbox 0]]
    $canvas delete temp($id)

    # Calculate how many would fit in the available space (limited to 10)
    
    set l_max_ticks [expr int(floor(double($a_right_limit - $a_left_limit) / $t_tick_label_width))]
    if {$l_max_ticks > 20} {
	set l_max_ticks 20
    } elseif {$l_max_ticks < 0} {
	set l_max_ticks 0
    }     
    
    set max_ticks $l_max_ticks
}  

body XAxis::draw { } {
    # Delete previously drawn axis
    $canvas delete x_axis($id)

    if {$ticklabels != {}} {
	set l_max [expr [llength $ticklabels] -1]
    }

    # Plot x axis
    $canvas create line $min_val 0 $max_val 0 -tags [list graph($id) x_axis($id) x_axis_shaft($id) axes($id)]
    
    # Get tick lengths
    set l_tick_length [$graph getTickLength]

    # Plot x axis ticks
    set i_tick_pos $min_val
    while {$i_tick_pos <= ($max_val + ( 0.5 * $tick_interval))} {
	$canvas create line $i_tick_pos 0 $i_tick_pos $l_tick_length -tags [list axes graph($id) x_tick($id) x_axis($id) axes($id)]
	if {[llength $ticklabels] > 0} {
	    if {[catch {set l_text [lindex $ticklabels [expr int($i_tick_pos)]]}]} {
		set l_text ""
	    }
	} else {
	    set l_text [format %.${precision}f [expr $i_tick_pos]]
	}
	$canvas create text $i_tick_pos 5 -text $l_text -anchor n -tags [list graph($id) x_tick($id) x_axis($id) axes($id)]
	set i_tick_pos [expr $i_tick_pos + $tick_interval]
    }
}

body XAxis::scale { a_left_limit a_right_limit } {

    # Scale x-axis and data in x to fill available space
    set l_scale_factor [expr ($a_right_limit - $a_left_limit) / ($max_val - $min_val)]
    $canvas scale x_axis($id) [expr $min_val] 0 $l_scale_factor 1

    $canvas scale data($id) [expr $min_val] 0 $l_scale_factor 1
    # Pop out data labels
    $canvas move data_label($id) [$graph getDataLabelDisplacement] 0
    # Create background boxes
    foreach i_label [$canvas find withtag data_label($id)] {
	set t_coords [$canvas bbox $i_label]
##############################################################################
#added by luke because t_coords would come out blank in tcl/tk 8.5. Not required for tcl/tk 8.4
	if {$t_coords == ""} {
	set t_coords {9 111 58 125}
#	puts "luke"
#	puts $t_coords
	}
##############################################################################
	foreach i_tag [$canvas gettags $i_label] {
	    if {[regexp {info\(([^,]+),(\d+)\)} $i_tag match t_variable t_marker]} {
		break
	    }
	}
	set t_backdrop [$canvas create rectangle $t_coords -outline $::Graph::markers(colour,$t_marker) -fill $::Graph::markers(colour,$t_marker) -tags [list graph($id) datapoint($id) datapoint($t_variable,$id) data_label_backdrop($id) data($id)]]
	$canvas raise $i_label $t_backdrop
    }

    # Move x-axis (and data) in x to align with available space
    $canvas move x_axis($id) [expr $a_left_limit - $min_val] 0
    $canvas move data($id) [expr $a_left_limit - $min_val] 0
}

# ##############################################################################
# CLASS: HistogramXAxis ########################################################
# ##############################################################################

class HistogramXAxis {

    private variable canvas ""
    private variable graph ""
    private variable id ""

    private variable num_bins ""
    private variable base_width ""
    private variable tick_labels ""
    private variable bin_labels ""

    public method post
    public method scale
    public method slide
    public method wipe
    public method guessTickLabelWidth
    
    private method calcMaxTicks
    private method draw


    constructor { a_canvas a_graph a_id a_base_width a_tick_labels a_bin_labels } { 
	set canvas $a_canvas
	set graph $a_graph
	set id $a_id
	set base_width $a_base_width
	set tick_labels $a_tick_labels
	set bin_labels $a_bin_labels
	set num_bins [llength $a_bin_labels]
	if { $num_bins == 0 } {
	    # here to avoid divide by zero error in ::scale
	    set num_bins 8
	}
    }
}

body HistogramXAxis::post { a_left_limit a_right_limit { hidden 0 } } {
    draw
}

body HistogramXAxis::slide { a_height } {
    # Move x-axis (and data) in y to align with available space
    $canvas move x_axis($id) 0 $a_height    
}  
  
body HistogramXAxis::wipe { } {
    $canvas delete x_axis($id)
}

body HistogramXAxis::guessTickLabelWidth { } {

    $canvas create text 0 0 -text "[lindex $tick_labels 0]\n[lindex $tick_labels end]" -tags [list graph($id) temp($id) temp_x_tick_label($id)]
    set t_bbox [$canvas bbox temp_x_tick_label($id)]
    set l_width [expr [lindex $t_bbox 2] - [lindex $t_bbox 0]]
    $canvas delete temp($id)
    return $l_width
}

body HistogramXAxis::draw { } {
    # Delete previously drawn axis
    $canvas delete x_axis($id)

    # Plot x axis
    $canvas create line 0 0 [expr $base_width * $num_bins] 0 -tags [list graph($id) x_axis($id) x_axis_shaft($id) axes($id)]
    
    # Get tick lengths
    set l_tick_length [$graph getTickLength]

    # Plot x axis ticks and labels
    set i_tick 0
    while {$i_tick <= $num_bins} {
	set l_tick_pos [expr $i_tick * $base_width]
	set l_bin_mid [expr ($i_tick + 0.5) * $base_width]
	$canvas create line $l_tick_pos 0 $l_tick_pos $l_tick_length -tags [list axes graph($id) x_tick($id) x_axis($id) axes($id)]
	$canvas create text $l_tick_pos 5 -text [lindex $tick_labels $i_tick] -anchor n -tags [list graph($id) x_tick($id) x_axis($id) axes($id) x_tick_label($id,$i_tick)]
	if {$i_tick < $num_bins} {
	    $canvas create text $l_bin_mid 5 -text [lindex $bin_labels $i_tick] -anchor n -tags [list graph($id) x_tick($id) x_axis($id) axes($id)]
	}
	incr i_tick
    }
}

body HistogramXAxis::scale { a_left_limit a_right_limit } {

    # Scale x-axis and data in x to fill available space
    if { ($num_bins == 0) || ($base_width == 0) } {
	puts "HistogramXAxis::scale num_bins*base_width is $num_bins*$base_width"
    }
    set l_scale_factor [expr ($a_right_limit - $a_left_limit) / ($num_bins * $base_width)]
    $canvas scale x_axis($id) 0 0 $l_scale_factor 1
    $canvas scale data($id) 0 0 $l_scale_factor 1

    # Move x-axis (and data) in x to align with available space
    $canvas move x_axis($id) $a_left_limit 0
    $canvas move data($id) $a_left_limit 0
    
    # Pare overlapping labels
    set l_last_tick_end -999
    set i_tick 0
    while {$i_tick <= $num_bins} {
	set l_bbox [$canvas bbox x_tick_label($id,$i_tick)]
	set l_tick_label_start [lindex $l_bbox 0]
	set l_tick_label_end [lindex $l_bbox 2]
	if {$l_tick_label_start < $l_last_tick_end} {
	    $canvas delete x_tick_label($id,$i_tick)
	} else {
	    set l_last_tick_end $l_tick_label_end
	}
	incr i_tick
    }
}

# ##############################################################################
# CLASS: YAxis #################################################################
# ##############################################################################

class YAxis {
    inherit Axis
    
    private variable position "left"
    private variable orientation "outer"
    private variable unit ""

    public method post
    public method scale
    public method slide
    public method wipe
    public method getWidth
    public method getPosition

    private method calcMaxTicks
    private method draw

    constructor { a_canvas a_graph a_id a_min_val a_max_val a_unit { a_position "left" } { a_orientation "outer" } } {
	Axis::constructor $a_canvas $a_graph $a_id $a_min_val $a_max_val
    } { 
	set unit $a_unit
	set position $a_position
	set orientation $a_orientation
    }
}

body YAxis::post { a_upper_limit a_lower_limit { hidden 0 } } {
    calcMaxTicks $a_upper_limit $a_lower_limit
    designAxis $hidden
    draw
}

body YAxis::slide { a_position } {
    $canvas move y_axis($position,$orientation,$id) $a_position 0
}

body YAxis::wipe { } {
    $canvas delete y_axis($position,$orientation,$id)
}

body YAxis::calcMaxTicks { a_upper_limit a_lower_limit } {
    set l_max_ticks [expr int(floor(double($a_lower_limit - $a_upper_limit) / (2.0 * [$graph getTextHeight])))]
    if {$l_max_ticks > 10} {
	set l_max_ticks 10
    } elseif {$l_max_ticks < 0} {
	set l_max_ticks 0
    }
    set max_ticks $l_max_ticks
}


body YAxis::draw { } {
    # delete previously drawn axis
    $canvas delete y_axis($position,$orientation,$id)

    # Get tick length
    set l_tick_length [$graph getTickLength]

    if {(($position == "left") && ($orientation == "outer")) || (($position == "right") && ($orientation == "inner"))} {
	set l_tick_start 0
	set l_tick_end [expr -$l_tick_length]
	set l_tick_anchor e
    } else {
	set l_tick_start 0
	set l_tick_end $l_tick_length
	set l_tick_anchor w
    }
    
    # Plot y-axis
    $canvas create line $l_tick_start [expr -$min_val] $l_tick_start [expr -$max_val] -tags [list graph($id) y_axis($position,$orientation,$id) axes($id) units([$unit getSymbol],$id) y_axis_shaft($position,$orientation,$id)]
    
    # Set first-tick flag
    set first_tick 1
    
    # Initialize tick position to bottom of axis
    set i_tick_pos [expr -$min_val]
    
    # Loop up the axis
    set t_last_tick_label ""
    while {$i_tick_pos > (-$max_val - (0.5 * $tick_interval))} {
	# add tick and label
	$canvas create line $l_tick_start $i_tick_pos $l_tick_end $i_tick_pos -tags [list graph($id) y_tick([$unit getSymbol],$id) y_axis($position,$orientation,$id) axes($id) units([$unit getSymbol],$id)]
	set t_last_tick_label [$canvas create text $l_tick_end $i_tick_pos -text [format %.${precision}f [expr 0-$i_tick_pos]] -anchor $l_tick_anchor -tags [list graph($id) y_tick([$unit getSymbol],$id) y_axis($position,$orientation,$id) axes($id) units([$unit getSymbol],$id)]]
	# increment tick position
	set i_tick_pos [expr $i_tick_pos - $tick_interval]
    }
    
    if {$t_last_tick_label != ""} {
	# Label y-axes units in same position as last tick-label
	foreach {t_x t_y} [$canvas coords $t_last_tick_label] { break }
	$canvas create  text $t_x $t_y -text "[$unit getName]" -anchor s$l_tick_anchor -tags [list graph($id) units([$unit getSymbol],$id) y_tick([$unit getSymbol],$id) y_axis_label([$unit getSymbol],$id) y_axis($position,$orientation,$id) axes($id) ]
    }	
}

body YAxis::scale { a_upper_limit a_lower_limit } {

    # Scale axis (and data) about min value to fit available space
    set l_scale_factor [expr ($a_lower_limit - $a_upper_limit) / ($max_val - $min_val)]
    if { $l_scale_factor == 0 } {
	set max_val [expr $max_val + 0.0001]
    set l_scale_factor [expr ($a_lower_limit - $a_upper_limit) / ($max_val - $min_val)]
    }
    $canvas scale units([$unit getSymbol],$id) 0 [expr -$min_val] 1 $l_scale_factor

    # Move axis (and data) in y to align min val and bottom of available space
    $canvas move units([$unit getSymbol],$id) 0 [expr $a_lower_limit + $min_val]

    # Pop up the unit label
    $canvas move y_axis_label([$unit getSymbol],$id) 0 [expr 0 - (0.5 * [$graph getTextHeight]) - [$graph getYAxisLabelDisplacement]]
    
#     # Move axis in x to align specified position
#     set t_bbox [$canvas bbox y_axis($position,$orientation,$id)]
#     if {$position == "left"} {
# 	$canvas move y_axis(left,$id) [expr [$graph getMargin left] - [lindex $t_bbox 0]] 0
#     } else {
# 	$canvas move y_axis(left,$id) [expr [$graph getMargin right] - [lindex $t_bbox 3]] 0
#     }
}  

body YAxis::getWidth { } {
    # Measure the distance from the bbox's axis shaft to the opposite bbox edge
    set l_bbox [$canvas bbox y_axis($position,$orientation,$id)]
    set l_axis_x_pos [lindex [$canvas coords y_axis_shaft($position,$orientation,$id)] 0]
    if {(($position == "left") && ($orientation == "outer")) ||
	(($position == "right") && ($orientation == "inner"))} {
	# left
	set l_width [expr $l_axis_x_pos - [lindex $l_bbox 0]]
    } else {
	# right
	set l_width [expr [lindex $l_bbox 2] - $l_axis_x_pos]	
    }
    return $l_width
}

body YAxis::getPosition { } {
    return $position
}

# ##############################################################################
# CLASS: Graph #################################################################
# ##############################################################################

class Graph {

    common unit_list {"mm" "Ang." "deg." "i_sig_i" "units"}
    common short_units 
    array set short_units {"mm" "mm" "Ang." "\u212b" "deg." "\u00b0" "i_sig_i" "I/\u03c3(I)" "units" " "}
    common long_units
    array set long_units  {"mm" "mm" "Ang." "\u212b" "deg." "deg." "i_sig_i" "I/\u3c3(I)" "units" "units"}
   # Create images for graphs markers and set up arrays with colours + symbols
    common l_symbols { square circle triangle_up triangle_down triangle_left triangle_right cross plus }
    common l_colours { "\#bb0000" "\#ffffff" "\#ffcc00" "\#000000" "\#3399ff" "\#ffffff" }
    set i_count 0
    common markers ; # array
    foreach i_symbol $l_symbols {
	foreach { i_bg_colour i_fg_colour } $l_colours {
	    set markers(symbol,$i_count) $i_symbol
	    set markers(colour,$i_count) $i_bg_colour
	    set markers(fg,$i_count) $i_fg_colour
	    image create bitmap ::img::marker($i_bg_colour,$i_symbol) -file [file join $::env(MOSFLM_GUI) bitmaps $i_symbol.xbm] -maskfile [file join $::env(MOSFLM_GUI) bitmaps $i_symbol.xbm] -foreground $i_bg_colour
	    incr i_count
	}
    }

    public variable showlabels "0"
    public variable font font_l
    public variable x_axis_limit ""

    protected variable canvas ""
    protected variable window {}
    protected variable id ""

    protected variable x_axis ""
    protected variable y_axes {}

    protected variable text_height ""
    protected variable max_data_label_width "0"

    protected variable tick_length "5"
    protected variable y_axis_label_displacement "10"
    protected variable data_label_displacement "10"

    public method getTextHeight
    public method getTickLength
    public method getYAxisLabelDisplacement
    public method getDataLabelDisplacement

    protected method calcTextHeight
    protected method plot
    protected method arrange
    protected method calcYAxisLimits 
    protected method calcXAxisLimits
    protected method getMargin

    public proc showValueLabel
    public proc moveValueLabel
    public proc hideValueLabel
    public proc raiseDatapoints

    constructor { a_canvas a_window a_id args } { }
    
}

body Graph::constructor { a_canvas a_window a_id args } {

    # set canvas, window and id 
    set canvas $a_canvas
    set window $a_window
    set id $a_id

    eval configure $args

    # Clear any previous graph with same id
    $canvas delete graph($id)

    # Calculate text height
    calcTextHeight

    return $this

}

body Graph::getYAxisLabelDisplacement { } {
    return $y_axis_label_displacement
}

body Graph::getDataLabelDisplacement { } {
    return $data_label_displacement
}

body Graph::getMargin { a_margin } {
    if {$a_margin == "left"} {
	set l_result [lindex $window 0]
    } elseif {$a_margin == "top"} {
	set l_result [lindex $window 1]
    } elseif {$a_margin == "right"} {
	set l_result [lindex $window 2]
    } elseif {$a_margin == "bottom"} {
	set l_result [lindex $window 3]
    }
    return $l_result
}

body Graph::arrange { } {

    set l_ditch_x_axis 0
    set l_ditch_y_axes 0
    # Calculate y-space available
    foreach {y0 y1} [calcYAxisLimits] break
    # If there's not much y-space...

    if {($y1 - $y0) < (2 * $text_height)} {
	#...calculate y-space available if the x-axis is dropped
	set l_ditch_x_axis 1
	foreach {y0 y1} [calcYAxisLimits -x-axis 0] break
    }
    # If there's still not much y-space...
    if {($y1 - $y0) < (2 * $text_height)} {
	#...calculate y-space available if the y-axis label is dropped
	set l_ditch_y_axes 1
	foreach {y0 y1} [calcYAxisLimits -x-axis 0 -y-axes 0] break
    }
    # If there's still virtually no space..
    if {($y1 - $y0) < 0.1} {
	# ...create a tiny bit to ensure no scale-by-zero errors
	set y1 [expr $y0 + 0.1]
    }
    # Post the y-axes
    foreach i_axis $y_axes {
	$i_axis post $y0 $y1 $l_ditch_y_axes
    }
    # Calculate x-space available
    foreach {x0 x1} [calcXAxisLimits -y-axes [expr !$l_ditch_y_axes] -x-axis [expr !$l_ditch_x_axis]] break
    # If there's not much x-space, and y-axes not ditched yet
    if {(($x1 - $x0) < 60) && (!$l_ditch_y_axes)} {
	#...calculate x-space available if the y-axes are dropped
	set l_ditch_y_axes 1
	# Re-post the y-axes???
	foreach i_axis $y_axes {
	    $i_axis post $y0 $y1 $l_ditch_y_axes
	}
	foreach {x0 x1} [calcXAxisLimits -y-axes 0] break
    }
    # If there's still virtually no space..
    if {($x1 - $x0) < 0.1} {
	# ...pretend there is a tiny bit to ensure no scale-by-zero errors
	set x1 [expr $x0 + 0.1]
    }

    # Post the x-axis
    $x_axis post $x0 $x1 $l_ditch_x_axis

    # Scale all axes
    foreach i_axis $y_axes {
	$i_axis scale $y0 $y1
    }
    $x_axis scale $x0 $x1

    # Position or ditch y-axes
    if {$l_ditch_y_axes} {
	foreach $i_axis $y_axes {
	    $i_axis wipe
	}
    } else {
	if {[llength $y_axes] < 3} {
	    [lindex $y_axes 0] slide $x0
	} else {
	    [lindex $y_axes 0] slide [expr $x0 - [[lindex $y_axes 2] getWidth]]
	    [lindex $y_axes 2] slide [expr $x0 - [[lindex $y_axes 2] getWidth]]
	}
	if {[llength $y_axes] > 3} {
	    [lindex $y_axes 1] slide [expr $x1 + [[lindex $y_axes 3] getWidth]]
	    [lindex $y_axes 3] slide [expr $x1 + [[lindex $y_axes 3] getWidth]]
	} elseif {[llength $y_axes] > 1} {
	    [lindex $y_axes 1] slide $x1
	}
    }

    # Position or ditch x-axis
    if {$l_ditch_x_axis} {
	$x_axis wipe
    } else {
	$x_axis slide $y1
    }

    # Raise the data above axes etc.
    $canvas raise data($id)

}


body Graph::calcTextHeight { } {
    $canvas create text 0 0 -text "0" -font $font -tags [list graph($id) temp($id) temp_text($id)]
    set t_bbox [$canvas bbox temp_text($id)]
    set text_height [expr [lindex $t_bbox 3] - [lindex $t_bbox 1]]
    $canvas delete temp_text($id)
}

body Graph::getTextHeight { } {
    if {$text_height == ""} {
	error "Attempt to read graph's text height before it has been calculated"
    } else {
	return $text_height
    }
}

body Graph::getTickLength { } {
    return $tick_length
}

body Graph::calcYAxisLimits { args } {
    # Check args to see which axes are included
    set l_include_x_axis 1
    set l_include_y_axes 1
    if {([llength $args] % 2) != 0} {
	error "Graph::calcYAxisLimits - Wrong number of arguments\n(Must be option-value pairs)"
    }
    foreach {opt val} $args {
	if {$opt == "-x-axis"} {
	    set l_include_x_axis $val
	} elseif {$opt == "-y-axes"} {
	    set l_include_y_axes $val
	} else {
	    error "Graph::calcYAxisLimits - Unrecognized option : $opt"
        }
    }
    # Initalize the limtis to the margins
    set l_y_axis_top_limit [getMargin top]
    set l_y_axis_bottom_limit [getMargin bottom]
    # If the x-axis are included
    if {$l_include_x_axis} {
	# allow room for the x-axis
	set l_y_axis_bottom_limit [expr $l_y_axis_bottom_limit - $text_height - $tick_length]
    } else {
	if {$l_include_y_axes} {
	    # allow room for half of the min tick-label
	    set l_y_axis_bottom_limit [expr [getMargin bottom] - (0.5 * $text_height)]
	}
    }
    if {$l_include_y_axes} {
	# allow room for half the max tick-label and the axis label
	set l_y_axis_top_limit [expr $l_y_axis_top_limit + (1.5 * $text_height) + $y_axis_label_displacement]
    }
    return [list $l_y_axis_top_limit $l_y_axis_bottom_limit]
}

body Graph::calcXAxisLimits { args } {
    # Read args to see which axes are included
    set l_include_y_axes 1
    set l_include_x_axis 1
    if {([llength $args] % 2) != 0} {
	error "Graph::calcXAxisLimits - Wrong number of arguments\n(Must be option-value pairs)"
    }
    foreach {opt val} $args {
	if {$opt == "-y-axes"} {
	    set l_include_y_axes $val
	} elseif {$opt == "-x-axis"} {
	    set l_include_x_axis $val
	} else {
	    error "Graph::calcXAxisLimits - Unrecognized option : $opt"
        }
    }
    # Set initial limits as margins
    set l_x_axis_left_limit [getMargin left]
    set l_x_axis_right_limit [getMargin right]
    # Calculate room needed for data labels
    set l_data_label_space [expr $max_data_label_width + $data_label_displacement]
    # If the y-axes are shown...
    if {$l_include_y_axes} {
	# Measure total widths of each side's y-axes
	set l_left_y_axes_widths 0
	set l_right_y_axes_widths 0
	foreach i_axis $y_axes {
	    if {[$i_axis getPosition] == "left"} {
		set l_left_y_axes_widths [expr $l_left_y_axes_widths + [$i_axis getWidth]]
	    } else {
		set l_right_y_axes_widths [expr $l_right_y_axes_widths + [$i_axis getWidth]]
	    }
	}
	# Subtract these widths from the limits
	set l_x_axis_left_limit [expr $l_x_axis_left_limit + $l_left_y_axes_widths]
	set l_x_axis_right_limit [expr $l_x_axis_right_limit - $l_right_y_axes_widths]
# 	# Allow space for the data labels
# 	set l_x_axis_right_limit [expr $l_x_axis_right_limit - $l_data_label_space]
    }
    # if the x-axis is shown
    if {$l_include_x_axis} {
	# if there is no y-axis on the left...
	if {!$l_include_y_axes} {
	    # ...allow room for half of the min y-tick label
	    set l_half_tick_label_width [expr [$x_axis guessTickLabelWidth] / 2.0]
	    set l_x_axis_left_limit [expr $l_x_axis_left_limit + $l_half_tick_label_width]
	}
	# if there's no y-axis on the right...
	if {[llength $y_axes] < 2} {
	    # allow room for half of the max x-tick label, or the data labels, whichever is biggest
	    set l_half_tick_label_width [expr [$x_axis guessTickLabelWidth] / 2.0]
	    set l_x_axis_right_limit [expr $l_x_axis_right_limit - ($l_data_label_space > $l_half_tick_label_width ? $l_data_label_space : $l_half_tick_label_width)]
	} else {
	    # Allow space for the data labels
	    set l_x_axis_right_limit [expr $l_x_axis_right_limit - $l_data_label_space]
	}
    } else {
	# Allow space for the data labels
	set l_x_axis_right_limit [expr $l_x_axis_right_limit - $l_data_label_space]
    }	
    return [list $l_x_axis_left_limit $l_x_axis_right_limit]
}    

body Graph::plot { args } {
    error "Graph::plot is a virtual function!"
}


# Graph annotiation functions
# show, move and hide...
    
body Graph::showValueLabel { a_label a_bg_colour a_fg_colour x y } {
	set t .value_label
	catch {destroy $t}
	toplevel $t
	# turning on the following with Boolean '1' means wm commands ignored
	wm overrideredirect $t 1
	if {[tk windowingsystem] == "aqua"} {
	    # If aqua on a Mac we dont want to see a sideTitleBar in the value popup
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
	# puts "\n$a_label"
	# the popup text under the cursor on the histogram
	# set rw [winfo reqwidth $t.l]
	# set sw [winfo screenwidth $t.l]
	# puts "Incoming x=$x ReqWdth=$rw ScrWdth=$sw"
	if {[expr $x + [winfo reqwidth $t.l]] > [winfo screenwidth $t.l]} {
	    set x [expr [winfo screenwidth $t.l] - [winfo reqwidth $t.l] - 2]
	}
	if {[expr $y + [winfo reqheight $t.l]] > [winfo screenheight $t.l]} {
	    set y [expr $y - 20 - [winfo reqheight $t.l] - 2]
	}
	# puts "Adjusted x=$x"
	moveValueLabel $x $y
    }

body Graph::moveValueLabel { x y } {
    catch {wm geometry .value_label "+[expr $x + 10]+[expr $y + 10]"}
}

body Graph::hideValueLabel {  } {
    catch {destroy .value_label}
}

# Line graph auxiliary methods
#  - raising datasets etc.

body Graph::raiseDatapoints { a_canvas a_id a_variable } {
    $a_canvas raise dataline($a_variable,$a_id) dataline($a_id)
    $a_canvas raise datapoint($a_variable,$a_id) datapoint($a_id)
}




# ##############################################################################
# CLASS: ScatterGraph ##########################################################
# ##############################################################################

class ScatterGraph {
    inherit Graph

    private method plot

    constructor { a_canvas a_window a_id a_x_dataset a_y_datasets args } {
	eval Graph::constructor $a_canvas [list $a_window] $a_id $args
    } {
	plot $a_x_dataset $a_y_datasets
    }
}

body ScatterGraph::plot { a_x_dataset a_y_datasets } {

    # Initialize various axes' (units') use flags and min and max vals
    foreach i_units [Unit::getUnits] {
	set units_used($i_units) 0 
 	set max_val_unset($i_units) 1
 	set min_val_unset($i_units) 1
 	set max_val($i_units) ""
 	set min_val($i_units) ""
    }
    set max_val_unset(x) 1
    set min_val_unset(x) 1
    set max_val(x) ""
    set min_val(x) ""

    # Get the x data
    set l_x_data [$a_x_dataset getData]
    set l_x_long_name [$a_x_dataset getLongName]
    set l_x_short_name [$a_x_dataset getShortName]
    set l_x_unit [$a_x_dataset getUnit]
    set l_x_unit_symbol [$l_x_unit getSymbol]
    set l_x_unit_name [$l_x_unit getName]

    # initialize dataset counter
    set i_dataset 0

    # Loop through y datasets
    foreach i_y_dataset $a_y_datasets {

	set l_y_data [$i_y_dataset getData]
	set l_y_long_name [$i_y_dataset getLongName]
	set l_y_short_name [$i_y_dataset getShortName]
	set l_y_unit [$i_y_dataset getUnit]
	set l_y_unit_symbol [$l_y_unit getSymbol]
	set l_y_unit_name [$l_y_unit getName]

	set units_used($l_y_unit_symbol) 1

	# Turn labels off, until we're sure there is data!
	set showlabels 0

	# Initialize previous position records (for joining dots)
	set l_old_x ""
	set l_old_y ""
	
	# Initialize iterator
	set i_index 0

	while {$i_index < [llength $l_y_data]} {

	    # Get coordinates
	    set l_x_pos [lindex $l_x_data $i_index]
	    set l_y_pos [lindex $l_y_data $i_index]
	    # if the coordinates are valid...
	    if { ($l_x_pos != "") && ($l_y_pos != "") && \
		[string is double -strict $l_x_pos] && [string is double -strict $l_y_pos] } {

		# We have data, so turn showlabels on
		set showlabels 1
		
		# Create a marker at the point (in negative y-space)
		set l_datapoint [$canvas create image $l_x_pos [expr -$l_y_pos] \
				    -image ::img::marker($markers(colour,$i_dataset),$markers(symbol,$i_dataset)) \
				    -tags [list \
					graph($id) \
					data($id) \
					datapoint($id) \
					datapoint($l_y_short_name,$id) \
					units($l_y_unit_symbol,$id)]]

		# Set up bindings for 'tooltip' value display
		$canvas bind $l_datapoint <Enter> [list Graph::showValueLabel "$l_x_long_name: $l_x_pos$l_x_unit_symbol, $l_y_long_name: $l_y_pos$l_y_unit_symbol" $markers(colour,$i_dataset) $markers(fg,$i_dataset) %X %Y]
		$canvas bind $l_datapoint <Motion> [list Graph::moveValueLabel %X %Y]
		$canvas bind $l_datapoint <Leave> [list Graph::hideValueLabel]
		$canvas bind $l_datapoint <ButtonPress-1> [list Graph::raiseDatapoints $canvas $id $l_y_short_name]

		# Join line to last datapoint in set
		if {($l_old_x != "") && ($l_old_y != "")} {
		    if {[expr $l_x_pos - $l_old_x] == 1} {
			# Only draw line between sequential images
			$canvas create line $l_old_x [expr -$l_old_y] $l_x_pos [expr -$l_y_pos] -fill $markers(colour,$i_dataset) -tags [list graph($id) data($id) dataline($id) dataline($l_y_short_name,$id) units($l_y_unit_symbol,$id)]			
		    }
		}

		# Check to see if current axes' limits need to be extended
		if {$max_val_unset($l_y_unit_symbol) || ($l_y_pos > $max_val($l_y_unit_symbol))} {
		    set max_val_unset($l_y_unit_symbol) 0
		    set max_val($l_y_unit_symbol) $l_y_pos
		}
		if {$min_val_unset($l_y_unit_symbol) || ($l_y_pos < $min_val($l_y_unit_symbol))} {
		    set min_val_unset($l_y_unit_symbol) 0
		    set min_val($l_y_unit_symbol) $l_y_pos
		}
	    }

	    if {$max_val_unset(x) || ($l_x_pos > $max_val(x))} {
		set max_val_unset(x) 0
		set max_val(x) $l_x_pos
	    }
	    if {$min_val_unset(x) || ($l_x_pos < $min_val(x))} {
		set min_val_unset(x) 0
		set min_val(x) $l_x_pos
	    }

	    # Record datapoint for joining line
	    set l_old_x $l_x_pos
	    set l_old_y $l_y_pos

	    # Increment the data iterator
	    incr i_index
	}

	# Show labels if required
	if {$showlabels} {
	    # Add data label
	    #puts "Scatter point $i_index for $l_y_short_name label at x=$l_x_pos, y=[expr -$l_y_pos]"
	    $canvas create text $l_x_pos [expr -$l_y_pos] \
		-text "$l_y_short_name" \
		-fill $markers(fg,$i_dataset) \
		-anchor w \
		-tags [list graph($id) data($id) units($l_y_unit_symbol,$id) data_label($l_y_short_name,$id) data_label($id) datapoint($id) datapoint($l_y_short_name,$id) info($l_y_short_name,$i_dataset)]
	    # Measure data label width
	    set t_data_label_bbox [$canvas bbox data_label($l_y_short_name,$id)]
	    set t_data_label_width [expr [lindex $t_data_label_bbox 2] - [lindex $t_data_label_bbox 0]]
	    # Keep record of widest label width
	    if {$t_data_label_width > $max_data_label_width} {
		set max_data_label_width $t_data_label_width
	    }
	    set showlabels 0
	} else {
	    set max_data_label_width 0
	}
	incr i_dataset
    }

    # Raise datapoints over connecting lines
    if {[$canvas find withtag dataline($id)] != {}} {
	$canvas raise datapoint($id) dataline($id)
    }	    
	
    # Create y-axes as necessary
    set t_axis_count 0
    foreach i_unit [Unit::getUnits] {
	if {$units_used($i_unit)} {
	    # Keep count of number of y-axes
	    incr t_axis_count
	    # Position axis according to number of axes
	    if {$t_axis_count == 1} {
		set t_position "left"
		set t_orientation "outer"
	    } elseif {$t_axis_count == 2} {
		set t_position "right"
		set t_orientation "outer"
	    } elseif {$t_axis_count == 3} {
		set t_position "left"
		set t_orientation "inner"
	    } elseif {$t_axis_count == 4} {
		set t_position "right"
		set t_orientation "inner"
	    }		    
	    # If there are no data for these axes, set the default range to be 0-1
	    if {$min_val_unset($i_unit)} {
		set min_val($i_unit) 0
	    }
	    if {$max_val_unset($i_unit)} {
		set max_val($i_unit) 1
	    }
	    lappend y_axes [namespace current]::[YAxis \#auto $canvas $this $id $min_val($i_unit) $max_val($i_unit) [Unit::getUnit $i_unit] $t_position $t_orientation]
	}
    }
    # Create x-axis if necessary
    if {$x_axis_limit == ""} {
	set x_axis_limit $max_val(x)
    }
    set x_axis [namespace current]::[XAxis \#auto $canvas $this $id $min_val(x) $x_axis_limit]
    #puts "Creating $x_axis"
    
    # Arrange the elements
    arrange

    # Remove the dataset objects to ease memory overheads
    #puts "Deleting $x_axis"
    delete object $x_axis
    foreach obj $y_axes {
	delete object $obj
	#puts "Deleting $obj"
    }

}

# ##############################################################################
# CLASS: Histogram #############################################################
# ##############################################################################


class Histogram {
    inherit Graph

    common breaker [image create bitmap ::img::breaker \
		     -data "#define v_width 9\n#define v_height 9\nstatic unsigned char v_bits[] = { 0x08, 0x01, 0x08, 0x01, 0x84, 0x00, 0x84, 0x00, 0x44, 0x00, 0x42, 0x00, 0x42, 0x00, 0x21, 0x00, 0x21, 0x00 };" \
		     -maskdata "#define v_mask_width 9\n#define v_mask_height 9\nstatic unsigned char v_mask_bits[] = { 0xf8, 0x01, 0xf8, 0x01, 0xfc, 0x00, 0xfc, 0x00, 0x7c, 0x00, 0x7e, 0x00, 0x7e, 0x00, 0x3f, 0x00, 0x3f, 0x00 };"]

    common bg_colours {"\#bb0000" "\#ffcc00" "\#3399ff" "\#00e5ac" "\#000000"}
    common fg_colours {"\#ffffff" "\#000000" "\#ffffff" "\#000000" "\#ffffff"}
    common stipple_files [list @[file join $::env(MOSFLM_GUI) bitmaps histo_stipple_0.xbm] @[file join $::env(MOSFLM_GUI) bitmaps histo_stipple_1.xbm] @[file join $::env(MOSFLM_GUI) bitmaps histo_stipple_2.xbm]]
    common stipples [list {} \
			 [image create bitmap ::img::histo_stipple_1 \
			      -data "#define stipple1_width 4\n#define stipple1_height 4\nstatic unsigned char stipple1_bits[] = { 0x09, 0x03, 0x06, 0x0c };"] \
			 [image create bitmap ::img::histo_stipple_2 \
			      -data "#define stipple2_width 1\n#define stipple2_height 4\nstatic unsigned char stipple2_bits[] = { 0x01, 0x01, 0x00, 0x00 };"]]

    private method plot

    constructor { a_canvas a_window a_id a_x_binset a_y_datasets args } {
	eval Graph::constructor $a_canvas [list $a_window] $a_id $args
    } {
	plot $a_x_binset $a_y_datasets
    }
}

body Histogram::plot { a_x_binset a_y_datasets } {

    set l_base_width 420

    # Initialize various axes' (units') use flags and min and max vals
    foreach i_units [Unit::getUnits] {
	set units_used($i_units) 0 
 	set max_val_unset($i_units) 1
 	set min_val_unset($i_units) 0
 	set max_val($i_units) ""
 	set min_val($i_units) "0"
    }

    # Get tick and bin labels
    set l_bin_name [$a_x_binset getBinName]
    set l_x_tick_labels [$a_x_binset getTickLabels]
    set l_x_bin_labels [$a_x_binset getBinLabels]
    set l_bin_units [[$a_x_binset getUnits] getSymbol]

    # Count datasets
    set l_num_datasets [llength $a_y_datasets]
    set l_bar_width [expr double($l_base_width) / $l_num_datasets] 

    # initialize dataset counter
    set i_dataset 0

    # Loop through y datasets
    foreach i_y_dataset $a_y_datasets {

	set l_y_data [$i_y_dataset getData]
	set l_y_long_name [$i_y_dataset getLongName]
	set l_y_short_name [$i_y_dataset getShortName]
	set l_y_unit [$i_y_dataset getUnit]
	set l_y_unit_symbol [$l_y_unit getSymbol]
	set l_y_unit_name [$l_y_unit getName]

	set units_used($l_y_unit_symbol) 1

	# Pick a colour
	set l_bg_colour [lindex $bg_colours [expr $i_dataset % [llength $bg_colours]]]
	set l_fg_colour [lindex $fg_colours [expr $i_dataset % [llength $fg_colours]]]
	set l_stipple [lindex $stipple_files [expr $i_dataset / [llength $bg_colours]]]

	# Initialize iterator
	set i_index 0

	while {$i_index < [llength $l_y_data]} {

	    # Get data value
	    set l_y_pos [lindex $l_y_data $i_index]

	    # if the coordinates are valid...
	    if {($l_y_pos != "") && [string is double -strict $l_y_pos]} {

		# Create a bar (in negative y-space)
		set l_datapoint [$canvas create rectangle \
				     [expr ($i_index * $l_base_width) + ($i_dataset * $l_bar_width)] 0 \
				     [expr ($i_index * $l_base_width) + ($i_dataset * $l_bar_width) + $l_bar_width] [expr -$l_y_pos] \
				     -fill $l_bg_colour \
				     -stipple $l_stipple \
				     -outline black \
				     -tags [list \
					graph($id) \
					data($id) \
					datapoint($id) \
					datapoint($l_y_short_name,$id) \
					units($l_y_unit_symbol,$id)]]

		# Create text for 'tooltip'
		set l_bin_label [lindex $l_x_bin_labels $i_index]
		if {$l_bin_label != ""} {
		    set l_tooltip "$l_bin_name $l_bin_label: $l_y_pos$l_y_unit_symbol"
		} else {
		    set l_bin_start [lindex $l_x_tick_labels $i_index] 
		    set l_bin_end [lindex $l_x_tick_labels [expr $i_index + 1]]
		    set l_tooltip "$l_bin_name $l_bin_start$l_bin_units-$l_bin_end$l_bin_units, $l_y_long_name: $l_y_pos$l_y_unit_symbol"
		}

		# Set up bindings for 'tooltip' value display
		$canvas bind $l_datapoint <Enter> [list Graph::showValueLabel $l_tooltip $l_bg_colour $l_fg_colour %X %Y]
		$canvas bind $l_datapoint <Motion> [list Graph::moveValueLabel %X %Y]
		$canvas bind $l_datapoint <Leave> [list Graph::hideValueLabel]

		# Check to see if current axes' limits need to be extended
		if {$max_val_unset($l_y_unit_symbol) || ($l_y_pos > $max_val($l_y_unit_symbol))} {
		    set max_val_unset($l_y_unit_symbol) 0
		    set max_val($l_y_unit_symbol) $l_y_pos
		}
# 		if {$min_val_unset($l_y_unit_symbol) || ($l_y_pos < $min_val($l_y_unit_symbol))} {
# 		    set min_val_unset($l_y_unit_symbol) 0
# 		    set min_val($l_y_unit_symbol) $l_y_pos
# 		}
	    } else {
		# Create axis break
		$canvas create image [expr ($i_index + 0.5) * $l_base_width] 0 \
		    -image $breaker \
		    -tags [list \
			graph($id) \
			data($id) \
			datapoint($id) \
			datapoint($l_y_short_name,$id) \
			units($l_y_unit_symbol,$id)]
	    }

	    # Increment the data iterator
	    incr i_index
	}

	# Set max data label width to zero, as there are none!
	set max_data_label_width 0

	# Loop to the next dataset
	incr i_dataset
    }

    # Create y-axes as necessary
    set t_axis_count 0
    foreach i_unit [Unit::getUnits] {
	if {$units_used($i_unit)} {
	    # Keep count of number of y-axes
	    incr t_axis_count
	    # Position axis according to number of axes
	    if {$t_axis_count == 1} {
		set t_position "left"
		set t_orientation "outer"
	    } elseif {$t_axis_count == 2} {
		set t_position "right"
		set t_orientation "outer"
	    } elseif {$t_axis_count == 3} {
		set t_position "left"
		set t_orientation "inner"
	    } elseif {$t_axis_count == 4} {
		set t_position "right"
		set t_orientation "inner"
	    }		    
	    # If there is no data for these axes, set the default range to be 0-1
	    if {$min_val_unset($i_unit)} {
		set min_val($i_unit) 0
	    }
	    if {$max_val_unset($i_unit)} {
		set max_val($i_unit) 1
	    }
	    lappend y_axes [namespace current]::[YAxis \#auto $canvas $this $id $min_val($i_unit) $max_val($i_unit) [Unit::getUnit $i_unit] $t_position $t_orientation]
	}
    }

    # Get the x data
    set l_x_tick_labels [$a_x_binset getTickLabels]
    set l_x_bin_labels [$a_x_binset getBinLabels]
    set x_axis [namespace current]::[HistogramXAxis \#auto $canvas $this $id $l_base_width $l_x_tick_labels $l_x_bin_labels]
    #puts "Creating $x_axis"
    
    # Arrange the elements
    arrange

    # Remove the dataset objects to ease memory overheads
    #puts "Deleting $x_axis"
    delete object $x_axis
    foreach obj $y_axes {
	delete object $obj
	#puts "Deleting $obj"
    }

}

# ##############################################################################
# CLASS: LineGraph #############################################################
# ##############################################################################


class LineGraph {
    inherit Graph

    private method plot

    private method convertXData

    constructor { a_canvas a_window a_id a_x_dataset a_y_datasets args } {
	eval Graph::constructor $a_canvas [list $a_window] $a_id $args
    } {
	plot $a_x_dataset $a_y_datasets
    }
}

body LineGraph::plot { a_x_dataset a_y_datasets } {

    # Initialize various axes' (units') use flags and min and max vals
    foreach i_units [Unit::getUnits] {
	set units_used($i_units) 0 
 	set max_val_unset($i_units) 1
 	set min_val_unset($i_units) 1
 	set max_val($i_units) ""
 	set min_val($i_units) ""
    }
    set max_val_unset(x) 1
    set min_val_unset(x) 1
    set max_val(x) ""
    set min_val(x) ""

    # Convert the X data
    foreach { l_new_x_dataset l_ticklabels } [convertXData $a_x_dataset] break

    # Get the x data
    set l_x_data [$a_x_dataset getData]
    #puts "X data: $l_x_data"
    set l_x_data_offset [$l_new_x_dataset getData]
    set l_x_long_name [$a_x_dataset getLongName]
    set l_x_short_name [$a_x_dataset getShortName]
    set l_x_unit [$a_x_dataset getUnit]
    set l_x_unit_symbol [$l_x_unit getSymbol]
    set l_x_unit_name [$l_x_unit getName]

    # initialize dataset counter
    set i_dataset 0

    # Loop through y datasets
    foreach i_y_dataset $a_y_datasets {
	set l_y_data [$i_y_dataset getData]
	#puts "Y data: $l_y_data"
	set l_y_long_name [$i_y_dataset getLongName]
	set l_y_short_name [$i_y_dataset getShortName]
	set l_y_unit [$i_y_dataset getUnit]
	set l_y_unit_symbol [$l_y_unit getSymbol]
	set l_y_unit_name [$l_y_unit getName]

	set units_used($l_y_unit_symbol) 1

	# Turn labels off, until we're sure there is data!
	set showlabels 0

	# Initialize previous position records (for joining dots)
	set l_old_x ""
	set l_old_y ""
	
	# Initialize iterator
	set i_index 0
	
	while {$i_index < [llength $l_y_data]} {

	    # Get coordinates
	    
	    set l_x_pos_original [lindex $l_x_data $i_index]
	    set l_x_pos [lindex $l_x_data_offset $i_index]
	    set l_y_pos [lindex $l_y_data $i_index]

	#    if {[regexp "\u03c6" $l_y_short_name]} {
	#	puts "Phi$l_y_short_name: X-posn. $l_x_pos, Y-posn. $l_y_pos"
	#    }

	    # Adjust for the summary plots which do not start with a point at x=0.
	    # Test for 'Cycle' in the short name & increment position in list by 1.
	    # OJ 29.iv.2010
	    if {[regexp Cycle $l_y_short_name]} {
	       set p_index [expr ($i_index + 1)]
	       set l_x_pos [lindex $l_x_data_offset $p_index]
	       set l_x_pos_true [lindex $l_x_data $p_index]
               set l_x_pos_original $l_x_pos_true
	    }
	    # if the coordinates are valid...
	    if { ($l_x_pos != "") && ($l_y_pos != "") && \
		[string is double -strict $l_x_pos] && [string is double -strict $l_y_pos] } {

		# We have data, so turn showlabels on
		set showlabels 1
		
		# Create a marker at the point (in negative y-space)
		set l_datapoint [$canvas create image $l_x_pos [expr -$l_y_pos] \
				    -image ::img::marker($markers(colour,$i_dataset),$markers(symbol,$i_dataset)) \
				    -tags [list \
					graph($id) \
					data($id) \
					datapoint($id) \
					datapoint($l_y_short_name,$id) \
					units($l_y_unit_symbol,$id)]]

		# Set up bindings for 'tooltip' value display
		$canvas bind $l_datapoint <Enter> [list Graph::showValueLabel "$l_x_long_name: $l_x_pos_original$l_x_unit_symbol, $l_y_long_name: $l_y_pos$l_y_unit_symbol" $markers(colour,$i_dataset) $markers(fg,$i_dataset) %X %Y]
		$canvas bind $l_datapoint <Motion> [list Graph::moveValueLabel %X %Y]
		$canvas bind $l_datapoint <Leave> [list Graph::hideValueLabel]
		$canvas bind $l_datapoint <ButtonPress-1> [list Graph::raiseDatapoints $canvas $id $l_y_short_name]

		# Join line to last datapoint in set
		# hrp 13.10.2006 (i) don't join to point at x = 0, since this is not 
		# actually associated with any image 
		# (ii) don't draw line between points for images in different sectors
		if {($l_old_x != "") && ($l_old_y != "")} {
		    if {($l_old_x > 0) && ([expr $l_x_pos_original - $l_old_x_original] == 1)} {
			$canvas create line $l_old_x [expr -$l_old_y] $l_x_pos [expr -$l_y_pos] -fill $markers(colour,$i_dataset) -tags [list graph($id) data($id) dataline($id) dataline($l_y_short_name,$id) units($l_y_unit_symbol,$id)]
		    }
		}

		# Check to see if current axes' limits need to be extended
		if {$max_val_unset($l_y_unit_symbol) || ($l_y_pos > $max_val($l_y_unit_symbol))} {
		    set max_val_unset($l_y_unit_symbol) 0
		    set max_val($l_y_unit_symbol) $l_y_pos
		}
		if {$min_val_unset($l_y_unit_symbol) || ($l_y_pos < $min_val($l_y_unit_symbol))} {
		    set min_val_unset($l_y_unit_symbol) 0
		    set min_val($l_y_unit_symbol) $l_y_pos
		}
	    }
	    
	    if {$max_val_unset(x) || ($l_x_pos > $max_val(x))} {
		set max_val_unset(x) 0
		set max_val(x) $l_x_pos
	    }
	    if {$min_val_unset(x) || ($l_x_pos < $min_val(x))} {
		set min_val_unset(x) 0
		set min_val(x) $l_x_pos
	    }

	    # Record datapoint for joining line
	    set l_old_x_original $l_x_pos_original
	    set l_old_x $l_x_pos
	    set l_old_y $l_y_pos

	    # Increment the data iterator
	    incr i_index
	}

	# Show labels if required
	if {$showlabels} {
	    # Protect against uninitialized results such as phi_x/y/z missets for first image in sector
	    if { $l_y_pos == "" } {
		set l_y_pos "0.00"
	    }
	    # Add data label
	    #puts "Graph point $i_index for $l_y_short_name label at x=$l_x_pos, y=[expr -$l_y_pos]"
	    $canvas create text $l_x_pos_original [expr -$l_y_pos] \
		-text "$l_y_short_name" \
		-fill $markers(fg,$i_dataset) \
		-anchor w \
		-tags [list graph($id) data($id) units($l_y_unit_symbol,$id) data_label($l_y_short_name,$id) data_label($id) datapoint($id) datapoint($l_y_short_name,$id) info($l_y_short_name,$i_dataset)]
	    # Measure data label width
	    set t_data_label_bbox [$canvas bbox data_label($l_y_short_name,$id)]
	    set t_data_label_width [expr [lindex $t_data_label_bbox 2] - [lindex $t_data_label_bbox 0]]
	    # Keep record of widest label width
	    if {$t_data_label_width > $max_data_label_width} {
		set max_data_label_width $t_data_label_width
	    }
	    set showlabels 0
	} else {
	    set max_data_label_width 0
	}

	incr i_dataset
    }
    	
    # Raise datapoints over connecting lines
    if {[$canvas find withtag dataline($id)] != {}} {
	$canvas raise datapoint($id) dataline($id)
    }	    
	
    # Create y-axes as necessary
    set t_axis_count 0
    foreach i_unit [Unit::getUnits] {
	if {$units_used($i_unit)} {
	    # Keep count of number of y-axes
	    incr t_axis_count
	    # Position axis according to number of axes
	    if {$t_axis_count == 1} {
		set t_position "left"
		set t_orientation "outer"
	    } elseif {$t_axis_count == 2} {
		set t_position "right"
		set t_orientation "outer"
	    } elseif {$t_axis_count == 3} {
		set t_position "left"
		set t_orientation "inner"
	    } elseif {$t_axis_count == 4} {
		set t_position "right"
		set t_orientation "inner"
	    }		    
	    # If there is no data for these axes, set the default range to be 0-1
	    if {$min_val_unset($i_unit)} {
		set min_val($i_unit) 0
	    }
	    if {$max_val_unset($i_unit)} {
		set max_val($i_unit) 1
	    }
	    lappend y_axes [namespace current]::[YAxis \#auto $canvas $this $id $min_val($i_unit) $max_val($i_unit) [Unit::getUnit $i_unit] $t_position $t_orientation]
	}
    }
    # Create x-axis if necessary
    if {$x_axis_limit == ""} {
	set x_axis_limit $max_val(x)
    }

    set x_axis [namespace current]::[XAxis \#auto $canvas $this $id $min_val(x) $x_axis_limit -type "int" -ticklabels $l_ticklabels]
    #puts "Creating $x_axis"

    # Arrange the elements
    arrange

    # Remove the dataset objects to ease memory overheads
    #puts "Deleting $x_axis"
    delete object $x_axis
    #puts "Deleting $l_new_x_dataset"
    delete object $l_new_x_dataset
    foreach obj $y_axes {
	delete object $obj
	#puts "Deleting $obj"
    }

}

body LineGraph::convertXData { a_dataset } {
    # get data
    set l_data [$a_dataset getData]
    # build list going 0,1,2...N to replace data
    set l_i 0
    set l_new_data {}
    while {$l_i < [llength $l_data]} {
	lappend l_new_data $l_i
	incr l_i
    }
    # Create new dataset
    set l_dataset [namespace current]::[Dataset \#auto $l_new_data [$a_dataset getUnit] [$a_dataset getLongName] [$a_dataset getShortName]]
    #puts "Creating $l_dataset"
    # Create labelset from orig data, replacing first label with blank
    set l_ticklabels [lreplace $l_data 0 0 ""]
    # return new dataset and labelset
    return [list $l_dataset $l_ticklabels]
}
