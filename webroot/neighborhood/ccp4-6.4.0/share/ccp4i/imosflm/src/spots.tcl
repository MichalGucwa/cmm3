# $Id: spots.tcl,v 1.12 2012/03/26 16:36:39 ccb Exp $
package provide spots 1.0

# CLASS Spot ###########################################################

class Spot {

    private variable id ""
    private variable x_mm ""
    private variable y_mm ""
    private variable x_pixels ""
    private variable y_pixels ""
    private variable i ""
    private variable stdev ""
    private variable type "auto"
    private variable spot_list ""

	private variable above_isigi
	public method getAboveIsigi


    public method hasPix
    public method write
    public method plot
    public method plotSummary
    public method setId

    public method getId
    public method getType
    public method getXmm
    public method getYmm
    public method getXpixels
    public method getYpixels
    public method getLineEnds
    public method getI
    public method getStdev

    public method serialize

    constructor { a_type args } { }
#    destructor { }
}

body Spot::constructor { a_type args } {
    # Overloading: auto:   image_height,pixel_size,origin,axis_order,x_mm,y_mm,i,stdev
    #              manual: image_height,pixel_size,origin,axis_order,x_pixels,y_pixels
    #              copy:   spot
    #              xml:    xml node
	set above_isigi 0
    switch -- $a_type {
	"auto" {

	    set type $a_type
	    set x_mm [lindex $args 4]
	    set y_mm [lindex $args 5]
	    if {1 || ([lindex $args 3] == "XY")} {
		set x_temp [lindex $args 4]
		set y_temp [lindex $args 5]
	    } else {
		set x_temp [lindex $args 5]
		set y_temp [lindex $args 4]
	    }
	    if {1 || ([string index [lindex $args 2] 1] == "L")} {
		set x_pixels [expr floor($x_temp / [lindex $args 1]) - 1]
	    } else {
		set x_pixels [expr floor([lindex $args 0] - ($x_temp / [lindex $args 1])) - 1]
		# NB Hack to test bug!!!!!!!!!!!!!
		#set x_pixels [expr floor($x_temp / [lindex $args 1]) - 1]
	    }
	    if  {1 || ([string index [lindex $args 2] 0] == "U")} {
		set y_pixels [expr floor($y_temp / [lindex $args 1]) - 1]
#set y_pixels [expr $y_pixels * 0.995]
set y_pixels [expr $y_pixels * [$::session getParameterValue "yscale"]]
#puts [$::session getParameterValue "yscale"]
	    } else {
		set y_pixels [expr floor([lindex $args 0] - ($y_temp / [lindex $args 1])) - 1]
#set y_pixels [expr $y_pixels * 0.995]
set y_pixels [expr $y_pixels * [$::session getParameterValue "yscale"]]
	    }

	    set i [lindex $args 6]
	    set stdev [lindex $args 7]
	}
	"manual" {
	    set type $a_type
	    set x_pixels [lindex $args 4]
	    set y_pixels [lindex $args 5]

	    if {1 ||([string index [lindex $args 2] 1] == "L")} {
		set x_temp [expr floor($x_pixels * [lindex $args 1]) - 1]
	    } else {
		set x_temp [expr floor([lindex $args 0] - ($x_pixels * [lindex $args 1])) - 1]
	    }

	    if {1 || ([string index [lindex $args 2] 0] == "U")} {
		set y_temp [expr floor($y_pixels * [lindex $args 1]) - 1]
	    } else {
		set y_temp [expr floor([lindex $args 0] - ($y_pixels * [lindex $args 1])) - 1]
	    }

	    if {1 || ([lindex $args 3] == "XY")} {
		set x_mm $x_temp
		set y_mm $y_temp
	    } else {
		set x_mm $y_temp
		set y_mm $x_temp
	    }
	    set i 999999.9
	    set stdev 1.0
	}
	"copy" {
	    set type [$args getType]
	    set x_mm [$args getXmm]
	    set y_mm [$args getYmm]
	    set x_pixels [$args getXpixels]
	    set y_pixels [$args getYpixels]
	    set i [$args getI]
	    set stdev [$args getStdev]
	}
	"xml" {
	    foreach i_attribute { type x_mm y_mm x_pixels y_pixels i stdev } {
		set $i_attribute [$args getAttribute $i_attribute]
	    }
	}
    }
}

body Spot::hasPix { x y } {
    return [expr ($x_pixels == $x) && ($y_pixels == $y)]
}

body Spot::write { a_file a_phi oscrange} {
    # 6040 FORMAT(1X,2F10.2,F9.3,F9.3,F12.1,F10.1) in mosflm/zip/wspot.f
    puts $a_file "[format %11.2f $x_mm][format %10.2f $y_mm][format %9.3f $oscrange][format %9.3f $a_phi][format %12.1f $i][format %10.1f $stdev]"
}

body Spot::getLineEnds { x_pixels y_pixels offset } {
	
    # Calculate coords of line endings
    set hix [expr {$x_pixels - $offset}]
    set lox [expr {$x_pixels + $offset}]
    set hiy [expr {$y_pixels - $offset}]
    set loy [expr {$y_pixels + $offset}]

    return [list $hix $hiy $lox $loy]

}

body Spot::plot { a_canvas { a_threshold 0 } } {

    # Offset for drawing line
    set offset 10
    foreach { hix hiy lox loy } [getLineEnds $x_pixels $y_pixels $offset] { }

    if {$type == "auto"} {
	# Calculate colour for cross
	if {(double($i)/$stdev) > $a_threshold} {
	    set cross_colour "red"
	} else {
	    set cross_colour "gold"
	}
	# create +
	$a_canvas create rectangle $hix $hiy $lox $loy -fill {} -outline {}  -tags [list crosses cross$id auto marker info_class(spot) info_label(Spot:${x_mm}mm,${y_mm}mm\;I/sig(I):[format %.2f [expr double($i)/$stdev]]) info_colour($cross_colour)]
	$a_canvas create line $x_pixels $hiy $x_pixels $loy $x_pixels $y_pixels $lox $y_pixels $hix $y_pixels -capstyle projecting -fill $cross_colour -tags [list crosses real_crosses cross$id real_cross$id auto marker]
    } else {
	# create x
	$a_canvas create rectangle $hix $hiy $lox $loy -fill {} -outline {}  -tags [list crosses cross$id auto marker info_class(spot) info_label(Spot:${x_mm}mm,${y_mm}mm) info_colour(red)]
	$a_canvas create line $hix $hiy $lox $loy $x_pixels $y_pixels $lox $hiy $hix $loy -capstyle projecting -fill red -tags [list crosses real_crosses cross$id real_cross$id manual marker]
    }
}

body Spot::plotSummary { a_canvas a_tag a_threshold } {
    if {(double($i) / $stdev) > $a_threshold} {
	set l_colour red
	set l_threshold_tag "over"
	set above_isigi 1
    } else {
	set l_colour gold
	set l_threshold_tag "under"
	set above_isigi 0
    }
    if {$type == "auto"} {
	$a_canvas create image $x_pixels $y_pixels -image ::img::spot_${l_colour}_plus3x3 -tags [list "all$a_tag" "auto_${l_threshold_tag}$a_tag"]
    } else {
	$a_canvas create image $x_pixels $y_pixels -image ::img::spot_${l_colour}_plus3x3 -tags [list "all$a_tag" "manual_${l_threshold_tag}$a_tag"]
    }
}	

body Spot::getAboveIsigi { } {
	return $above_isigi
}

body Spot::setId { a_id } {
    set id $a_id
}

body Spot::getId { } {
    return $id
}

body Spot::getType { } {
    return $type
}

body Spot::getXmm { } {
    return $x_mm
}

body Spot::getYmm { } {
    return  $y_mm
}

body Spot::getXpixels { } {
    return $x_pixels}

body Spot::getYpixels { } {
    return $y_pixels
}

body Spot::getI { } {
    return $i
}

body Spot::getStdev { } {
    return $stdev
}

body Spot::serialize { } {
    return "<spot type=\"$type\" x_mm=\"$x_mm\" y_mm=\"$y_mm\" x_pixels=\"$x_pixels\" y_pixels=\"$y_pixels\" i=\"$i\" stdev=\"$stdev\"/>"
}

# CLASS BadSpot ###########################################################

class BadSpot {

    private variable id ""
    private variable coordx ""
    private variable coordy ""
    private variable units ""
    private variable millerh ""
    private variable millerk ""
    private variable millerl ""
    private variable intensity ""
    private variable sigma ""
    private variable ratiobgnd ""
    private variable ratiopeak ""
    private variable bgslopea ""
    private variable bgslopeb ""
    private variable bgslopec ""
    private variable summary ""
    private variable type "xml"

    public method plot
    public method setId

    public method getXmm
    public method getYmm
    public method getXpixels
    public method getYpixels
    public method getPickBoxCorners
    public method getI
    public method getStdev

    public method serialize

    constructor { a_type args } { }
#    destructor { }
}

body BadSpot::constructor { a_type args } {
    # Overloading: auto:   image_height,pixel_size,origin,axis_order,x_mm,y_mm,i,stdev
    #              manual: image_height,pixel_size,origin,axis_order,x_pixels,y_pixels
    #              copy:   spot
    #              xml:    xml node
	set above_isigi 0
    switch -- $a_type {
	"auto" {

	    set type $a_type
	    set x_mm [lindex $args 4]
	    set y_mm [lindex $args 5]
	    if {1 || ([lindex $args 3] == "XY")} {
		set x_temp [lindex $args 4]
		set y_temp [lindex $args 5]
	    } else {
		set x_temp [lindex $args 5]
		set y_temp [lindex $args 4]
	    }
	    if {1 || ([string index [lindex $args 2] 1] == "L")} {
		set x_pixels [expr floor($x_temp / [lindex $args 1]) - 1]
	    } else {
		set x_pixels [expr floor([lindex $args 0] - ($x_temp / [lindex $args 1])) - 1]
	    }
	    if  {1 || ([string index [lindex $args 2] 0] == "U")} {
		set y_pixels [expr floor($y_temp / [lindex $args 1]) - 1]
		set y_pixels [expr $y_pixels * [$::session getParameterValue "yscale"]]
	    } else {
		set y_pixels [expr floor([lindex $args 0] - ($y_temp / [lindex $args 1])) - 1]
		set y_pixels [expr $y_pixels * [$::session getParameterValue "yscale"]]
	    }

	    set i [lindex $args 6]
	    set stdev [lindex $args 7]
	}
	"copy" {
	    set type [$args getType]
	    set x_mm [$args getXmm]
	    set y_mm [$args getYmm]
	    set x_pixels [$args getXpixels]
	    set y_pixels [$args getYpixels]
	    set i [$args getI]
	    set stdev [$args getStdev]
	}
	"xml" {
		set bad_spot [dom parse [$args asXML]]
		set coordx [$bad_spot selectNodes normalize-space(//x_coordinate)]
		set coordy [$bad_spot selectNodes normalize-space(//y_coordinate)]
		set units  [$bad_spot selectNodes normalize-space(//units)]
		set millerh [$bad_spot selectNodes normalize-space(//index_h)]
		set millerk [$bad_spot selectNodes normalize-space(//index_k)]
		set millerl [$bad_spot selectNodes normalize-space(//index_l)]
		set intensity [$bad_spot selectNodes normalize-space(//intensity)]
		set sigma [$bad_spot selectNodes normalize-space(//sigma)]
		set ratiobgnd [$bad_spot selectNodes normalize-space(//background_ratio)]
		set ratiopeak [$bad_spot selectNodes normalize-space(//peak_ratio)]
		set bgslopea [$bad_spot selectNodes normalize-space(//a_slope)]
		set bgslopeb [$bad_spot selectNodes normalize-space(//b_slope)]
		set bgslopec [$bad_spot selectNodes normalize-space(//c_slope)]
		set summary [$bad_spot selectNodes normalize-space(//summary)]
		#puts "Bad spot: $coordx, $coordy, $units, $millerh, $millerk, $millerl, $intensity, $sigma, $ratiobgnd, $ratiopeak, $bgslopea, $bgslopeb, $bgslopec, $summary"
	}
    }
}

body BadSpot::getPickBoxCorners { a_x a_y offset } {
    # Calculate coords of opposite corners
    set hix [expr {$a_x - ($offset / 2) -1}]
    set lox [expr {$a_x + ($offset / 2) -1}]
    set hiy [expr {$a_y - ($offset / 2) -1}]
    set loy [expr {$a_y + ($offset / 2) -1}]
    #puts "getPickBoxCorners: $hix $hiy $lox $loy"
    return [list $hix $hiy $lox $loy]
}

body BadSpot::plot { a_canvas { a_threshold 0 } } {

    # Offset for drawing line
    set offset 20
    foreach { hix hiy lox loy } [getPickBoxCorners $coordx $coordy $offset] { }
    $a_canvas create rectangle $hix $hiy $lox $loy -fill {} -outline {}  -tags [list badspots badspot$id auto marker info_class(badspot) info_label(BadSpot:$summary) info_colour(red)]
    $a_canvas create line $hix $hiy $lox $loy -capstyle projecting -fill red -tags [list badspots real_badspots badspot$id real_badspot$id manual marker]
    $a_canvas create line $lox $hiy $hix $loy -capstyle projecting -fill red -tags [list badspots real_badspots badspot$id real_badspot$id manual marker]
}

body BadSpot::setId { a_id } {
    set id $a_id
}

body BadSpot::getXmm { } {
    foreach { x_mm y_mm } [Marking::c2mCoords [list $coordx $coordy]] break
    return $x_mm
}

body BadSpot::getYmm { } {
    foreach { x_mm y_mm } [Marking::c2mCoords [list $coordx $coordy]] break
    return  $y_mm
}

body BadSpot::getXpixels { } {
    return $coordx
}

body BadSpot::getYpixels { } {
    return $coordy
}

body BadSpot::getI { } {
    return $intensity
}

body BadSpot::getStdev { } {
    return $sigma
}

body BadSpot::serialize { } {
    return "<badspot x=\"$coordx\" y=\"$coordy\" units=\"$units\" millerh=\"$millerh\" millerk=\"$millerk\" millerl=\"$millerl\" intensity=\"$intensity\" sigma=\"$sigma\" ratiobgnd=\"$ratiobgnd\" ratiopeak=\"$ratiopeak\" bgslopea=\"$bgslopea\" bgslopeb=\"$bgslopeb\" bgslopec=\"$bgslopec\" summary=\"$summary\"/>"
}

# CLASS BadSpotlist #######################################################

class BadSpotlist {
    
    private variable max_id "0"
    private variable badspots {}

    private variable num_total "0"

    public method plotSpots
    public method plotBadSpotSummary

    public method getBadSpots

    public method copyBadSpot

    public method serialize

    public method debug

    constructor { how args } { }

    destructor {
    	foreach badspot $badspots {
		#puts "Deleting badspot object $badspot"
		delete object $badspot
	}
	}
}

body BadSpotlist::debug { } {
}

body BadSpotlist::constructor { how args } {
    # 2 ways to create a badspot list:
    #  'copy': Copy a given badspot list (args: spotfile)
    #  'xml': parse dom node

    if {$how == "empty"} {
	# set image height member
	set image_height [[lindex $args 0] getImageHeight]
	#puts $image_height
	# set phi member
	set phi [lindex $args 1]
	#puts $phi
	# set pixel size member
	set pixel_size [lindex $args 2]
	#puts $pixel_size
    } elseif {$how == "file"} {
	# set image height member
	set image_height [[lindex $args 0] getImageHeight]
	# read badspots from file
	readSpotFile [lindex $args 1]
    } elseif {$how == "copy"} {
	# copy member variables
	#set max_id [$args getMaxId]
	set phi [$args getPhi]
	set pixel_size [$args getPixelSize]
	set image_height [$args getImageHeight]
	set num_automatic [$args getAuto]
	set num_deleted [$args getDeleted]
	set num_manual [$args getManual]
	set num_total [$args getTotal]
	# copy badspots
	set l_badspots [$args getBadSpots]
	foreach i_badspot $l_badspots {
	    set new_badspot [namespace current]::[BadSpot \#auto "xml" $i_badspot]
	    incr max_id
	    $new_badspot setId $max_id
	    lappend badspots $new_badspot
	}
    } elseif {$how == "xml"} {
	set badspot_nodes [$args selectNodes bad_spot]
	foreach i_badspot_node $badspot_nodes {
	    set new_badspot [namespace current]::[BadSpot \#auto "xml" $i_badspot_node]
	    incr max_id
            #puts "Bad spot [$i_badspot_node asHTML]"
            $new_badspot setId $max_id
	    lappend badspots $new_badspot
	}
	#puts "[llength $badspots] bad spots stored"
    } else {
	error "Poor attempt to create a badspot list: $how: $args"
    }
}

body BadSpotlist::plotSpots { a_threshold args } {
    # args is list of canvases to plot on
    foreach i_canvas $args {
	foreach badspot [getBadSpots] {
	    #puts "plotSpots: $badspot threshold $a_threshold"
	    $badspot plot $i_canvas $a_threshold
	}
    }
}

body BadSpotlist::getBadSpots { } {

    return $badspots
}

body BadSpotlist::serialize { { a_name ""} } {        
    set xml "<bad_spot_list>"
    foreach i_badspot $badspots {
	append xml [$i_badspot serialize]
    }
    append xml "</bad_spot_list>"
    return $xml
}

# CLASS Spotlist #######################################################

class Spotlist {
    
    private variable max_id "0"
    private variable spots {}
    private variable phi ""
    private variable pixel_size ""
    private variable image_height ""
    
    private variable origin ""
    private variable axis_order ""

    # Variables for reporting to the user
    private variable num_automatic "0"
    private variable num_deleted "0"
    private variable num_manual "0"
    private variable num_total "0"

	private variable total_above_isigi "0"
	public method getTotalAboveIsigi
	public method setTotalAboveIsigi

    # Methods for spot creation/deletion/display
    public method addSpotManually
    public method addSpot
    public method deleteSpot
    public method writeToFile
    public method plotSpots
    public method plotSummary

    # Methods for accessing summary stats
    public method getAuto
    public method getDeleted
    public method getManual
    public method getTotal

    # Members for accessing other members (used in copy-consruction)
    public method getMaxId
    public method getSpots
    public method getPhi
    public method getPixelSize
    public method getImageHeight
    
    public method copySpot

    private method readSpotFile
    public method spotExists
    public method getSpotById

    public method serialize

    public method debug

    constructor { how args } { }

    destructor {
    	foreach spot $spots {
		delete object $spot
	}
	}
}

body Spotlist::debug { } {
}

body Spotlist::constructor { how args } {
    # 4 ways to create a spotlist:
    #  'empty': Just create an empty spotlist (args: image [for height], phi, pixel size)
    #  'file': Read spots from a file (args: image [for height], file)
    #  'copy': Copy a given spotlist (args: spotfile)
    #  'xml': parse dom node
	
    set origin [$::session getParameterValue "origin"]
    set axis_order [$::session getParameterValue "axis_order"]

    if {$how == "empty"} {
	# set image height member
	set image_height [lindex $args 0]
	#puts $image_height
	# set phi member
	set phi [lindex $args 1]
	#puts $phi
	# set pixel size member
	set pixel_size [lindex $args 2]
	#puts $pixel_size
    } elseif {$how == "file"} {
	# set image height member
	set image_height [lindex $args 0]
	# read spots from file
	readSpotFile [lindex $args 1]
    } elseif {$how == "copy"} {
	# copy member variables
	#set max_id [$args getMaxId]
	set phi [$args getPhi]
	set pixel_size [$args getPixelSize]
	set image_height [$args getImageHeight]
	set num_automatic [$args getAuto]
	set num_deleted [$args getDeleted]
	set num_manual [$args getManual]
	set num_total [$args getTotal]
	# copy spots
	set l_spots [$args getSpots]
	foreach i_spot $l_spots {
	    set new_spot [namespace current]::[Spot \#auto "copy" $i_spot]
	    incr max_id
	    $new_spot setId $max_id
	    lappend spots $new_spot
	}
    } elseif {$how == "xml"} {
	#set max_id [$args getAttribute max_id]
	set phi [$args getAttribute phi]
	set pixel_size [$args getAttribute pixel_size]
	set image_height [$args getAttribute image_height]
	set num_automatic [$args getAttribute num_automatic]
	set num_deleted [$args getAttribute num_deleted]
	set num_manual [$args getAttribute num_manual]
	set num_total [$args getAttribute num_total]
	set spot_nodes [$args selectNodes spot]
	foreach i_spot_node $spot_nodes {
	    set new_spot [namespace current]::[Spot \#auto "xml" $i_spot_node]
	    incr max_id
	    $new_spot setId $max_id
	    lappend spots $new_spot
	}
    } else {
	error "Poor attempt to create a spotlist: $how: $args"
    }
}

body Spotlist::getTotalAboveIsigi { } {
	return $total_above_isigi
}

body Spotlist::readSpotFile { a_file } {

    set in_file [open $a_file]
 
    if {[catch {gets $in_file} line]} {
	puts "Error reading from file"
	return 0
    }
    # Get the pixel size from the first line (item 3)
    regexp {^\s*\S+\s+\S+\s+(\S+)} $line match pixel_size 
    
    # get and parse line 2 info
    if {[catch {gets $in_file} line]} {
	puts "Error reading from file"
	return 0
    }
    
    # get and parse line 3 info
    if {[catch {gets $in_file} line]} {
	puts "Error reading from file"
	return 0
    }
    
    while {1} {
	if {[catch {gets $in_file} line]} {
	    puts "Error reading from file"
	    return 0
	}
	if {![regexp {^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*$} $line \
		 match x y filler phi_centre intensity stdev]} {
	    puts "Error in spot file: malformatted spot entry\n$line"
	    return 0
	}
	if { $x > -1 } {
	    # Create spot and add to list
	    set new_spot [namespace current]::[Spot \#auto "auto" $image_height $pixel_size $origin $axis_order $x $y $intensity $stdev]
	    incr max_id
	    $new_spot setId $max_id
	    incr num_automatic
	    incr num_total
	    lappend spots $new_spot
	    # set phi for spotlist with value from spot
	    set phi $phi_centre

	} else {
	    # negative values indicate end of spots for this phi_centre
	    break
	}
    }
    
    # get final line of info from file if necessary (it's not!)

    # close file
    close $in_file
}

body Spotlist::writeToFile { a_file oscrange } {
    foreach spot $spots {
	$spot write $a_file $phi $oscrange
    }
}

body Spotlist::spotExists { a_x_pixels a_y_pixels } {
    foreach spot $spots {
	if {[$spot hasPix $a_x_pixels $a_y_pixels]} {
	    return 1
	}
    }
    return 0
}

body Spotlist::getSpotById { a_id } {
    foreach i_spot $spots {
	if {[$i_spot getId] == $a_id} {
	    return $i_spot
	}
    }
    return ""
}

body Spotlist::addSpotManually { a_x_pixel a_y_pixel } {
    # args is list of canvases to plot on
    if {![spotExists $a_x_pixel $a_y_pixel]} {
	set new_spot [namespace current]::[Spot \#auto "manual" $image_height $pixel_size $origin $axis_order $a_x_pixel $a_y_pixel]
	incr max_id
	$new_spot setId $max_id
	lappend spots $new_spot
	incr num_manual
	incr num_total
	return $new_spot
    } else {
	# cannot place spot as one already exists there
	return ""
    }
}

body Spotlist::addSpot { a_spot } {
    # args is list of canvases to plot on
    # Only proceed if there isn't already a spot in the list with the same pixel location
    if {![spotExists [$a_spot getXpixels] [$a_spot getYpixels]]} {
	set new_spot [namespace current]::[Spot \#auto "copy" $a_spot]
	lappend spots $new_spot
	incr max_id
	$new_spot setId $max_id
	if {[$new_spot getType] == "auto"} {
	    incr num_deleted -1
	} else {
	    incr num_manual
	}
	incr num_total
	return $new_spot
    } else {
	# cannot place spot as one already exists there
	return ""
    }
}

body Spotlist::deleteSpot { type args } {
    # Can be delete-by-id or delete-by-pixel-position
    
    # Get the spot to delete
    set l_spot_to_delete ""
    if {$type == "id"} {
	set l_id [lindex $args 0]
	set i_index 0
	foreach i_spot $spots {
	    if {[$i_spot getId] == $l_id} {
		set l_spot_to_delete $i_spot
		break
	    }
	    incr i_index
	}
    } elseif {$type == "position"} {
	set l_x_pixels [lindex $args 0]
	set l_y_pixels [lindex $args 1]
	set i_index 0
	foreach i_spot $spots {
	    if {[$i_spot hasPix $l_x_pixels $l_y_pixels]} {
		set l_spot_to_delete $i_spot
		# get the id for deleting cross on canvas
		set l_id [$l_spot_to_delete getId]
		break
	    }
	    incr i_index
	}
    }

    # When (if) the spot to delete has been found...
    if {$l_spot_to_delete != ""} {

	# Update the spotlist's summary stats
	if {[$l_spot_to_delete getType] == "auto"} {
	    incr num_deleted
	} else {
	    incr num_manual -1
	}
	incr num_total -1
	# remove the spot from the list 
	set spots [lreplace $spots $i_index $i_index]
	# Delete the spot object
	delete object $l_spot_to_delete
	# return the id for deleting cross on canvas
	return $l_id
    } else {
	error "Could not find spot to delete!"
    }
}

body Spotlist::plotSpots { a_threshold args } {
    # args is list of canvases to plot on
    foreach i_canvas $args {
	foreach spot $spots {
	    $spot plot $i_canvas $a_threshold
	}
    }
}

body Spotlist::setTotalAboveIsigi { } {
	set total_above_isigi 0
    foreach spot $spots {
	set total_above_isigi [expr $total_above_isigi + [$spot getAboveIsigi]]
    }
}

body Spotlist::plotSummary { a_canvas a_tag a_threshold } {
	set total_above_isigi 0
    $a_canvas delete "all$a_tag"
    foreach spot $spots {
	$spot plotSummary $a_canvas $a_tag $a_threshold
	set total_above_isigi [expr $total_above_isigi + [$spot getAboveIsigi]]
    }
#	puts $total_above_isigi
}



body Spotlist::copySpot { a_spot } {
    set l_new_spot [namespace current]::[Spot \#auto "copy" $a_spot]
    lappend spots $l_new_spot
} 

body Spotlist::getAuto { } {
    return $num_automatic
}

body Spotlist::getDeleted { } {
    return $num_deleted
}

body Spotlist::getManual { } {
    return $num_manual
}

body Spotlist::getTotal { } {
    return $num_total
}

body Spotlist::getMaxId { } {
    return $max_id
}

body Spotlist::getSpots { } {
    return $spots
}

body Spotlist::getPhi { } {
    return $phi
}

body Spotlist::getPixelSize { } {
    return $pixel_size
}

body Spotlist::getImageHeight { } {
    return $image_height
}

body Spotlist::serialize { { a_name ""} } {        
    set xml "<spotlist name=\"$a_name\" phi=\"$phi\" pixel_size=\"$pixel_size\" image_height=\"$image_height\" num_automatic=\"$num_automatic\" num_deleted=\"$num_deleted\" num_manual=\"$num_manual\" num_total=\"$num_total\">"
    foreach i_spot $spots {
	append xml [$i_spot serialize]
    }
    append xml "</spotlist>"
    return $xml
}
