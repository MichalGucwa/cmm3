# $Id: contrast.tcl,v 1.11 2011/01/10 17:23:39 ccb Exp $
package provide contrast 1.0

package require palette

image create photo ::img::pixel_count_v -data "iVBORw0KGgoAAAANSUhEUgAAAA4AAABCCAIAAAGft0AHAAAABGdBTUEAAYagMeiWXwAAASFJREFUKJGtVFEWhCAINJ9H4f4n4jD7YauAA1jGT2EwAxNyMXMppZZu3bv6Q3t3iH7ob3fOPz3wdLoi7y8V1SOZp0NE02Hm7quc6VSVaokFKzMD8qKUUd0tyEQ0z1DchNQaud+JCHclzeIDOUCle7EjcA/XPZU4Klb9y2GDY68LVe8YiAihmXT052G9SQ0+m4yN2J7EZqrvnZpheMdGRLnq5/ViddTusPeux9o5G7fdsskrV9ej8rw3I80LhNUUgqmvwCY8izozZcvo5tGt1owfoGJhoEVtgcXg2da2gJa0JYESseRJ8gvyOYSGlxUkScYFoBoJB+RZrR+H2sWx2vEQrnv0pa4HYkFqF7UHrefRdjE5zQQFAp/Nqwf8XNePZ+AHq5sOPlXtupMAAAAASUVORK5CYII="

class Contrast {
    inherit Palette

    private variable bin_size "64"
    private variable border "2"
    private variable margin "60"
    private variable limit_offset "8"
    private variable width "256"
    private variable height "256"

    private variable histo ""
    private variable data {}
    private variable minimum ""
    private variable maximum ""
    private variable x_scale "1"
    private variable y_scale "1"

    private variable button ""
    private variable ungrab_queue ""

    public method reset
    public method updateHistogram
    public method plotHistogram
    private method adjustLabelsIfOverlapping
    public method colour
    public method getContrast

    public method motion
    public method clickLimit
    public method dragLimit
    public method releaseLimit

    public method getNewImage

    public method disable
    public method enable

    constructor { args } { }
}

body Contrast::constructor { args } {

    itk_component add frame {
	frame $itk_interior.f
#	    -bg black - showed through when Reset button centred
    }

    if {[tk windowingsystem] == "aqua"} {
	#Added to avoid the sideTitlebar with the name contrast_palette being written
	::tk::unsupported::MacWindowStyle style $itk_component(hull) floating noTitleBar
    }

    pack $itk_component(frame)

    itk_component add heading {
	label $itk_interior.f.heading \
	    -text "Pixel intensity histogram"
    }

    itk_component add outer_canvas {
	canvas $itk_interior.f.outer_canvas \
	    -highlightthickness 0 \
	    -bd 2 \
	    -relief raised \
	    -width [expr $width + (2 * ($border + $margin))] \
	    -height [expr $height + (2 * ($border + $margin))] \
    }

    itk_component add inner_canvas {
	canvas $itk_interior.f.inner_canvas \
	    -highlightthickness 0 \
	    -bd 0 \
	    -relief sunken \
	    -bg lightblue \
	    -width $width \
	    -height $height
    } {
	usual
	rename -background -textbackground textbackground Background
    }
    set histo $itk_component(inner_canvas)

    $itk_component(outer_canvas) create window [expr $margin + $border] [expr $margin + $border] \
	-anchor nw \
	-window $itk_component(inner_canvas)	

    pack $itk_component(outer_canvas) -padx 1 -pady [list 1 0]

    itk_component add reset {
	button $itk_interior.f.reset \
	    -highlightthickness 0 \
	    -highlightbackground "#dcdcdc" \
	    -text "Reset" \
	    -command [code $this reset]
    }
    pack $itk_component(reset) -padx 1 -pady [list 0 1]
}

body Contrast::updateHistogram { a_list } {
    set data [lrange $a_list 0 [expr 32767 / $bin_size]]
    set minimum [lindex $a_list [expr (32767 / $bin_size) + 1]]
    set maximum [lindex $a_list [expr (32767 / $bin_size) + 2]]
    plotHistogram
    enable
}

body Contrast::reset { } {
    set minimum 0
    set maximum 0
    getNewImage
}

body Contrast::plotHistogram { } {
    $itk_component(outer_canvas) delete label
    $histo delete all

    # Plot data
    set l_max_datum 0
    set i_x 0
    $histo create rectangle \
	$border [expr $border + $height] \
	[expr $border + (log($i_x+$bin_size) / log(2))] [expr ($border + $height) - log10([lindex $data 0]+1)] \
	-fill white \
	-outline {} \
	-tags [list bar bar(0)]
    if {[lindex $data 0] > $l_max_datum} {
	set l_max_datum [lindex $data 0]
    }
    set i_count 1	
    foreach i_datum [lrange $data 1 end] {
	incr i_x $bin_size
	$histo create rectangle \
	    [expr $border + (log($i_x) / log(2))] [expr $border + $height] \
	    [expr $border + (log($i_x+$bin_size) / log(2))] [expr ($border + $height) - log10($i_datum+1)] \
	    -fill white \
	    -outline {} \
	    -tags [list bar bar($i_count)]
	incr i_count
	if {$i_datum > $l_max_datum} {
	    set l_max_datum $i_datum
	}
    }
    set l_max_y [expr ($border + $height) - ceil(log10($l_max_datum+1))]

    # Plot limits
    set min $minimum
    set max $maximum
    if {$min == 0} {
	set min 1
    }
    if {$max <= $min} {
	set max [expr $min + 1]
    }
    set min [expr 2 + (log($min) / log(2))]
    set max [expr 2 + (log($max) / log(2))]
    $histo create line $min 258 $min $l_max_y \
	-fill black \
	-dash { 4 4 } \
	-tags [list limit minimum limit_black minimum_black]
    $histo create line $min 258 $min $l_max_y \
	-fill white \
	-dash { 4 4 } \
	-dashoffset 4 \
	-tags [list limit minimum limit_white minimum_white]
    $histo create line $max 258 $max $l_max_y \
	-fill white \
	-dash { 4 4 } \
	-dashoffset 4 \
	-tags [list limit maximum limit_white maximum_white]
    $histo create line $max 258 $max $l_max_y \
	-fill black \
	-dash { 4 4 } \
	-tags [list limit maximum limit_black maximum_black]

    # Scale to fit window
    set x_scale [expr double($width) / (log(32768)/log(2))]
    set y_scale [expr double($height) / (($border + $height) - $l_max_y)]
    $histo scale all 2 258 $x_scale $y_scale

    # Plot tick labels
    set l_max_power [expr ceil(log10($l_max_datum+1))]
    set i_count 0
    while {$i_count <= $l_max_power} {
	$itk_component(outer_canvas) create text \
	    [expr $border + $margin - $limit_offset] [expr $border + $margin + $border + $height - ($y_scale * $i_count)] \
	    -text "10 " \
	    -anchor e \
	    -tag [list label y_tick_label($i_count)]
	foreach { dummy y x dummy } [$itk_component(outer_canvas) bbox y_tick_label($i_count)] break
	$itk_component(outer_canvas) create text $x $y \
	    -text $i_count \
	    -anchor e \
	    -font font_t \
	    -tag label
	incr i_count
    }
    set i_count 0
    while {$i_count < 16} {
	$itk_component(outer_canvas) create text \
	    [expr $border + $margin + $border + ($x_scale * $i_count)] [expr $border + $margin + $border + $height + $border + $limit_offset] \
	    -text "2 " \
	    -anchor n \
	    -tag [list x_tick_label($i_count)]
	foreach { dummy y x dummy } [$itk_component(outer_canvas) bbox x_tick_label($i_count)] break
	$itk_component(outer_canvas) create text $x $y \
	    -text $i_count \
	    -anchor e \
	    -font font_t \
	    -tag label
	incr i_count 2
    }
    
    # plot limit labels
    $itk_component(outer_canvas) create text \
	[expr $border + $margin + $border + ((log($minimum+1)/log(2)) * $x_scale)] \
	[expr $border + $margin - $limit_offset] \
	-text " $minimum " \
	-anchor s \
	-fill black \
	-tag [list label limit minimum]

    $itk_component(outer_canvas) create text \
	[expr $border + $margin + $border + ((log($maximum+1)/log(2)) * $x_scale)] \
	[expr $border + $margin - $limit_offset] \
	-text " $maximum " \
	-anchor s \
	-fill black \
	-tag [list label limit maximum]

    # Plot title
    $itk_component(outer_canvas) create text \
	[expr $border + $margin + $border + ($width / 2)] \
	[expr $border + ($margin / 2)] \
	-text "Pixel intensity histogram" \
	-font subtitle_font \
	-anchor s

    # Plot axis labels
    $itk_component(outer_canvas) create text \
	[expr ($border * 2) + $margin + ($width / 2)] \
	[expr ($border * 3) + $margin + $height + ($margin / 2)] \
	-text "Intensity" \
	-anchor n

    $itk_component(outer_canvas) create image \
	[expr $border + ($margin / 2)] \
	[expr ($border * 2) + $margin + ($height / 2)] \
	-image ::img::pixel_count_v \
	-anchor e
    

    # adjust labels if they're overlapping
    adjustLabelsIfOverlapping

    # Colour in histogram
    colour

    bind $histo <Motion> [code $this motion %x %y]
    bind $histo <ButtonPress-1> [code $this clickLimit %x %y]
    bind $histo <Leave> [code $this motion 9999 9999]
    bind $histo <Enter> [code $this motion %x %y]
}

body Contrast::adjustLabelsIfOverlapping { } {
    # adjust labels if they would overlap
    set l_min_x [lindex [$itk_component(outer_canvas) coords minimum] 0]
    set l_max_x [lindex [$itk_component(outer_canvas) coords maximum] 0]
    set l_min_bbox [$itk_component(outer_canvas) bbox minimum]
    set l_max_bbox [$itk_component(outer_canvas) bbox maximum]
    set l_min_width [expr [lindex $l_min_bbox 2] - [lindex $l_min_bbox 0]]
    set l_max_width [expr [lindex $l_max_bbox 2] - [lindex $l_max_bbox 0]]
    set l_min_right [expr $l_min_x + (0.5 * $l_min_width)]
    set l_max_left [expr $l_max_x - (0.5 * $l_max_width)]
    if {$l_min_right > $l_max_left} {	
	$itk_component(outer_canvas) itemconfigure minimum -anchor se
	$itk_component(outer_canvas) itemconfigure maximum -anchor sw
    } else {
	$itk_component(outer_canvas) itemconfigure minimum -anchor s
	$itk_component(outer_canvas) itemconfigure maximum -anchor s
    }
}

body Contrast::colour { } {
    # Colour histogram according to limits
    set first [expr $minimum / $bin_size]
    set last [expr $maximum / $bin_size]
    if {$first == $last} {
	set step 256
    } else {
	set step [expr 256.0 / ($last - $first)]
    }

    set i_count 0
    while { $i_count < $first } {
	$histo itemconfigure bar($i_count) -fill white
	incr i_count
    }
    while { $i_count < $last } {
	$histo itemconfigure bar($i_count) -fill "\#[string repeat [format %02x [expr int(255 - (($i_count - $first) * $step))]] 3]"
	incr i_count
    }
    while { $i_count < (32768 / $bin_size) } {
	$histo itemconfigure bar($i_count) -fill "black"
	incr i_count
    }

}

#[string repeat [format %02x $i] 3]

body Contrast::getContrast { } {
    return [list $minimum $maximum]
}

body Contrast::motion { a_x a_y } {
    set l_distance "999"
    set l_search_radius "9"
    set l_chosen_limit ""
    set l_items [$histo find overlapping \
		   [expr $a_x - $l_search_radius] \
		   [expr $a_y - $l_search_radius] \
		   [expr $a_x + $l_search_radius] \
		   [expr $a_y + $l_search_radius]]
    foreach i_item $l_items {
	if {[$histo type $i_item] == "line"} {
	    set l_x_coord [lindex [$histo coords $i_item] 0]
	    if {abs($l_x_coord - $a_x) < $l_distance} {
		set l_chosen_limit $i_item
		set l_distance [expr abs($l_x_coord - $a_x)]
	    }
	}
    }
    $histo itemconfigure limit_black -fill black -width 1
    $histo itemconfigure limit_white -fill white -width 1
    $itk_component(outer_canvas) itemconfigure limit -fill black -font font_l
    if {$l_chosen_limit != ""} {
	$histo raise $l_chosen_limit
	set l_chosen_limit [lindex [$histo gettags $l_chosen_limit] 1]
	$histo itemconfigure ${l_chosen_limit}_black -width 2
	$histo itemconfigure ${l_chosen_limit}_white -width 2
	$itk_component(outer_canvas) itemconfigure $l_chosen_limit -fill black -font font_b
    }
    return $l_chosen_limit
}

body Contrast::clickLimit { a_x a_y } {
    set l_chosen_limit [motion $a_x $a_y]
    if {$l_chosen_limit != ""} {
	bind $histo <Motion> [code $this dragLimit $l_chosen_limit %x %y ]
	bind $histo <ButtonRelease-1> [code $this releaseLimit]
    }
}

body Contrast::dragLimit { a_limit a_x a_y } {
    if {$a_x < 2} {
	set a_x 2
    } elseif {$a_x > 258} {
	set a_x 258
    }
    set l_new_value [expr int(pow(2,(($a_x - $border - 1) / $x_scale) * 1.0) - 2)]
    if {$l_new_value < 0} {
	set l_new_value 0
    }
    set $a_limit $l_new_value
    if {$a_limit == "minimum"} {
	if {[set $a_limit] >= $maximum} {
	    set $a_limit [expr $maximum - 1]
	}
    }
    if {$a_limit == "maximum"} {
	if {[set $a_limit] <= $minimum} {
	    set $a_limit [expr $minimum + 1]
	}
    }
    set l_x [expr $border + ((log([set $a_limit] + 1)/log(2)) * $x_scale)]
    $histo coords ${a_limit}_black $l_x 0 $l_x 258
    $histo coords ${a_limit}_white $l_x 0 $l_x 258

    # Update label
    $itk_component(outer_canvas) coords $a_limit \
	[expr $border + $margin + $l_x] [expr $border + $margin - $limit_offset] 
    $itk_component(outer_canvas) itemconfigure $a_limit \
	-text " [set $a_limit] "

    adjustLabelsIfOverlapping

    colour
}   

body Contrast::releaseLimit { } {
    bind $histo <Motion> [code $this motion %x %y]
    bind $histo <ButtonRelease-1> {}
    getNewImage
}


body Contrast::getNewImage { } {
    set l_image [.image getImage]
    if {$l_image != ""} {
	disable
	.image openImage $l_image
    }
}

body Contrast::disable { } {
    $itk_component(reset) configure -state disabled
    $histo configure -cursor watch
    bind $histo <Motion> {}
    bind $histo <ButtonPress-1> {}
    bind $histo <Leave> {}
    bind $histo <Enter> {}
}

body Contrast::enable { } {
    bind $histo <Motion> [code $this motion %x %y]
    bind $histo <ButtonPress-1> [code $this clickLimit %x %y]
    bind $histo <Leave> [code $this motion 9999 9999]
    bind $histo <Enter> [code $this motion %x %y]
    $histo configure -cursor {}
    $itk_component(reset) configure -state normal
}

usual Contrast { }

# Pixel intensity histogram y_axis vertical label generation
if {0} {
    # Create horizontal label on canvas
    toplevel .t
    pack [canvas .t.c -highlightthickness 0]
    .t.c create text 0 0 -text "Pixel Count" -tags pixel_count
    # resize canvas to fit label and reposition label
    set l_bbox [.t.c bbox pixel_count]
    set l_x [lindex $l_bbox 0]
    set l_y [lindex $l_bbox 1]
    set l_width [expr [lindex $l_bbox 2] - $l_x]
    set l_height [expr [lindex $l_bbox 3] - $l_y]
    .t.c move pixel_count [expr - $l_x] [expr - $l_y]
    .t.c configure -width $l_width -height $l_height

    # Create image (using Img)
    image create photo ::img::pixel_count_h -format window -data .t.c

    set l_width [image width ::img::pixel_count_h]
    set l_height [image height ::img::pixel_count_h]
    set l_data [::img::pixel_count_h data]
    image create photo ::img::pixel_count_v
    for {set x 0} {$x < $l_width} {incr x} {
	for {set y 0} {$y < $l_height} {incr y} {
	    set xx [expr {$l_width - $x - 1}] 
	    set yy $y
	    ::img::pixel_count_v put [lindex $l_data $yy $xx] -to $y $x
	}
    }
}    
