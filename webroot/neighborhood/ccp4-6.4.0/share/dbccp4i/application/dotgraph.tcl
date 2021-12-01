# dotgraph
#
# Tcl functions based on dot from the graphviz package
#
# Peter Briggs CCLRC 2006-7
#
# CVS_id $Id: dotgraph.tcl,v 1.9 2008/08/12 10:48:04 pjx Exp $

# Initialise globals
set dotgraph(VERSION) "0.0.5"
set dotgraph(DOT_DIR) {}
set dotgraph(SCALE_FACTOR) 100.0

################################################################
# dotgraph commands
################################################################

#---------------------------------------------------------------
proc dotgraph_init { dot_dir } {
#---------------------------------------------------------------
    # Initialise the dotgraph functions
    global dotgraph
    global tcl_platform
    # Set the path to the graphviz package
    set dotexe [file join $dot_dir dot]
    set has_dotexe 0
    if { [file exists $dotexe] && [file executable $dotexe] } {
	# Find the dot executable
	set has_dotexe 1
    }
    if { ! $has_dotexe && [info exists tcl_platform(platform)] } {
	if { $tcl_platform(platform) == "windows" } {
	    # Try dot.exe
	    append dotexe ".exe"
	    if { [file exists $dotexe] && [file executable $dotexe] } {
		set has_dotexe 1
	    }
	}
    }
    # Return failure if nothing found
    if { ! $has_dotexe } {
	return 0
    }
    # Set the internal flags
    set dotgraph(DOT_DIR) "$dot_dir"
    set dotgraph(GRAPH_LIST) {}
    set dotgraph(INIT) 1
    return 1
}

#---------------------------------------------------------------
proc dotgraph_version { { operator "" } { version "" } } {
#---------------------------------------------------------------
    # Return or test the version of dotgraph
    # If no arguments are supplied then return the version number
    # Otherwise test the version number against the dotgraph
    # version number
    # The operator can be "<", "<=", "==", ">=" or ">"
    # Returns 1 if the test is satisfied and 0 otherwise
    global dotgraph
    # Simple test first
    if { "$operator" == "" && "$version" == "" } {
	return $dotgraph(VERSION)
    }
    # Check for a valid operator
    if { ![regexp --  "^(<|<=|==|>=|>)\$" $operator] } {
	puts "dotgraph_version: error: invalid operator \"$operator\""
	return 0
    }
    # Check for a valid version
    # This should be of the form x(.y(.z))
    if { ![regexp --  "^(\[0-9\]+)\.(\[0-9\]*)\.(\[0-9\]*)\$" $version m x y z] } {
	puts "dotgraph_version: error: invalid version \"$version\""
	return 0
    }
    # Get the components of the library version number
    regexp -- "^(\[0-9\]+)\.(\[0-9\]*)\.(\[0-9\]*)\$" $dotgraph(VERSION) m X Y Z
    # Set "empty" values to be zero
    if { $y == "" } {
	set y 0
    }
    if { $Y == "" } {
	set Y 0
    }
    if { $z == "" } {
	set z 0
    }
    if { $Z == "" } {
	set Z 0
    }
    # Build strings for comparision as numbers
    set tversion [format "%05d%05d%05d" $x $y $z]
    set dversion [format "%05d%05d%05d" $X $Y $Z]
    return [expr $dversion $operator $tversion]
}

#---------------------------------------------------------------
proc dotgraph_new { g args } {
#---------------------------------------------------------------
    # Initialise a dot graph "object" called g
    # g is just a name to act as a handle on the graph
    # (actually just an array storing data about a graph)
    #
    # Optional arguments:
    # -shape <shape>: set the default shape for nodes in
    # in the graph (choices are "ellipse","box","diamond")
    # -color <color>: set the default colour for drawing
    # the outlines of nodes etc (default is black)
    # -fillcolor <color>: set the default colour for
    # filled nodes
    # -background <color>: set the default background
    # colour for the canvas
    # -direction <dir>: set the direction of the graph
    # Choices are: "TB" (top-to-bottom - the default),
    # "BT" (bottom-to-top), "LR" (left-to-right) or
    # "RL" (right-to-left)
    # -debug: turn on debugging code (developers only)
    global dotgraph
    # Check if this name is already in use
    if { [dotgraph_exists $g] } {
	puts "dotgraph_new: a graph called \"$g\" already exists"
	return {}
    }
    # Add the graph name to the list
    lappend dotgraph(GRAPH_LIST) $g
    # Initialise the data for the components
    # Nodes
    set dotgraph([subst $g]_NODE_NAME) {}
    set dotgraph([subst $g]_NODE_LABEL) {}
    set dotgraph([subst $g]_NODE_SHAPE) {}
    set dotgraph([subst $g]_NODE_COLOR) {}
    set dotgraph([subst $g]_NODE_FILLCOLOR) {}
    set dotgraph([subst $g]_NODE_BINDINGS) {}
    # Connections (=edges)
    set dotgraph([subst $g]_EDGE_NAME) {}
    set dotgraph([subst $g]_EDGE_START) {}
    set dotgraph([subst $g]_EDGE_END) {}
    set dotgraph([subst $g]_EDGE_LABEL) {}
    set dotgraph([subst $g]_EDGE_COLOR) {}
    set dotgraph([subst $g]_EDGE_BINDINGS) {}
    # Process the extra arguments
    set n [llength $args]
    set i 0
    set shape "ellipse"
    set color "black"
    set background {}
    set fillcolor {}
    set direction "TB"
    set font {}
    set debug 0
    while { $i < $n } {
	switch -- [lindex $args $i] {
	    "-shape" {
		incr i
		set shape [lindex $args $i]
	    }
	    "-color" {
		incr i
		set color [lindex $args $i]
	    }
	    "-fillcolor" {
		incr i
		set fillcolor [lindex $args $i]
	    }
	    "-background" {
		incr i
		set background [lindex $args $i]
	    }
	    "-direction" {
		incr i
		set direction [lindex $args $i]
	    }
	    "-font" {
		incr i
		set font [string trim [lindex $args $i]]
	    }
	    "-debug" {
		set debug 1
	    }
	}
	incr i
    }
    # Set the defaults for the graph as a whole
    set dotgraph([subst $g]_SHAPE) $shape
    set dotgraph([subst $g]_COLOR) $color
    set dotgraph([subst $g]_FILLCOLOR) $fillcolor
    set dotgraph([subst $g]_BACKGROUND) $background
    set dotgraph([subst $g]_DIRECTION) $direction
    set dotgraph([subst $g]_FONT) $font
    set dotgraph([subst $g]_DEBUG) $debug
    # Somewhere to store the list of canvases
    set dotgraph([subst $g]_CANVASES) {}
    # Return the handle
    return $g
}

#---------------------------------------------------------------
proc dotgraph_exists { g } {
#---------------------------------------------------------------
    # Return 1 if a dotgraph called $g already exists
    global dotgraph
    if { [lsearch $dotgraph(GRAPH_LIST) $g] > -1 } {
	return 1
    }
    return 0
}

#---------------------------------------------------------------
proc dotgraph_delete { g } {
#---------------------------------------------------------------
    # Delete an existing dotgraph datastructure from memory
    global dotgraph
    if { [set i [lsearch $dotgraph(GRAPH_LIST) $g]] < 0 } {
	puts "dotgraph_delete: no dotgraph called \"$g\" found"
	return {}
    }
    # Find and unset all associated data
    foreach item [array names dotgraph "[subst $g]_*"] {
	unset dotgraph($item)
    }
    # Remove the graph from the list of graphs
    set dotgraph(GRAPH_LIST) [lreplace $dotgraph(GRAPH_LIST) $i $i]
    return 1
}

#---------------------------------------------------------------
proc dotgraph_add_node { g name args } {
#---------------------------------------------------------------
    # Add a node to the dot graph g
    # name is the name used as a handle for this node
    # Optional arguments are:
    # -label <text>
    # -shape <shape>
    # -color <color>
    # -fillcolor <fillcolor>
    global dotgraph
    if { ![dotgraph_exists $g] } {
	# This graph doesn't exist
	puts "dotgraph_add_node: no graph called \"$g\" found"
	return {}
    }
    if { [set i [lsearch $dotgraph([subst $g]_NODE_NAME) $name]] > -1 } {
	# Node with this name already exists
	puts "dotgraph_add_node: a node called \"$name\" already exists"
	return {}
    }
    # Process the arguments
    set label_text ""
    set shape $dotgraph([subst $g]_SHAPE)
    set color $dotgraph([subst $g]_COLOR)
    set fillcolor $dotgraph([subst $g]_FILLCOLOR)
    set font $dotgraph([subst $g]_FONT)
    set n [llength $args]
    set i 0
    while { $i < $n } {
	switch -- [lindex $args $i] {
	    "-label" {
		incr i
		# Note that labels are limited to 127 characters
		set label_text [string range \
				    [escape_newlines [lindex $args $i]] 0 126]
	    }
	    "-shape" {
		incr i
		set shape [lindex $args $i]
	    }
	    "-color" {
		incr i
		set color [lindex $args $i]
	    }
	    "-fillcolor" {
		incr i
		set fillcolor [lindex $args $i]
	    }
	    "-font" {
		incr i
		set font [string trim [lindex $args $i]]
	    }
	}
	incr i
    }
    # Check the node shape
    if { [lsearch -exact \
	      [list "ellipse" "diamond" "box"] $shape] < 0 } {
	puts "dotgraph_add_node: bad node shape \"$shape\" for $name"
	return {}
    }
    # Store the node and associated data
    lappend dotgraph([subst $g]_NODE_NAME) $name
    lappend dotgraph([subst $g]_NODE_LABEL) "$label_text"
    lappend dotgraph([subst $g]_NODE_SHAPE) $shape
    lappend dotgraph([subst $g]_NODE_COLOR) $color
    lappend dotgraph([subst $g]_NODE_FILLCOLOR) $fillcolor
    lappend dotgraph([subst $g]_NODE_FONT) $font
    # Bindings
    lappend dotgraph([subst $g]_NODE_BINDINGS) {}
    return $name
}

#---------------------------------------------------------------
proc dotgraph_add_connection { g start end args } {
#---------------------------------------------------------------
    # Add a connection between two nodes in the dotgraph g
    # Optional arguments:
    # -label <text>
    # -color <color>
    global dotgraph
    if { ![dotgraph_exists $g] } {
	# This graph doesn't exist
	puts "dotgraph_add_connection: no graph called \"$g\" found"
	return {}
    }
    # Look up the nodes
    if { [set i [lsearch $dotgraph([subst $g]_NODE_NAME) $start]] < 0 } {
	puts "dotgraph_add_connection: no start node called \"$start\""
	return {}
    }
    if { [set j [lsearch $dotgraph([subst $g]_NODE_NAME) $end]] < 0 } {
	puts "dotgraph_add_connection: no end node called \"$end\""
	return {}
    }
    # Process the arguments
    set label_text ""
    set color $dotgraph([subst $g]_COLOR)
    set font $dotgraph([subst $g]_FONT)
    set n [llength $args]
    set i 0
    while { $i < $n } {
	switch -- [lindex $args $i] {
	    "-label" {
		incr i
		set label_text [escape_newlines [lindex $args $i]]
	    }
	    "-color" {
		incr i
		set color [lindex $args $i]
	    }
	    "-font" {
		incr i
		set font [string trim [lindex $args $i]]
	    }
	}
	incr i
    }
    lappend dotgraph([subst $g]_EDGE_NAME) "[subst $start]_$end"
    lappend dotgraph([subst $g]_EDGE_START) $start
    lappend dotgraph([subst $g]_EDGE_END) $end
    lappend dotgraph([subst $g]_EDGE_LABEL) "$label_text"
    lappend dotgraph([subst $g]_EDGE_COLOR) $color
    lappend dotgraph([subst $g]_EDGE_FONT) $font
    # Bindings
    lappend dotgraph([subst $g]_EDGE_BINDINGS) {}
}

#---------------------------------------------------------------
proc dotgraph_configure_node { g name args } {
#---------------------------------------------------------------
    # Configure the display options of the named node
    # This supports the same arguments as dotgraph_add_node:
    # -label <text>
    # -shape <shape>
    # -color <color>
    # -fillcolor <fillcolor>
    # -font <font>
    global dotgraph
    if { ![dotgraph_exists $g] } {
	# This graph doesn't exist
	puts "dotgraph_configure_node: no graph called \"$g\" found"
	return {}
    }
    if { [set i [lsearch $dotgraph([subst $g]_NODE_NAME) $name]] < 0 } {
	# Couldn't find the requested node
	puts "dotgraph_configure_node: no node called \"$name\" found"
	return {}
    }
    # Initialise local variables
    set new_label_text 0
    set label_text ""
    set new_shape 0
    set shape ""
    set new_color 0
    set color ""
    set new_fillcolor 0
    set fillcolor ""
    set new_font 0
    set font ""
    # Process the arguments
    set n [llength $args]
    set j 0
    while { $j < $n } {
	switch -- [lindex $args $j] {
	    "-label" {
		incr j
		set label_text [escape_newlines [lindex $args $j]]
		set new_label_text 1
	    }
	    "-shape" {
		incr j
		set shape [lindex $args $j]
		set new_shape 1
	    }
	    "-color" {
		incr j
		set color [lindex $args $j]
		set new_color 1
	    }
	    "-fillcolor" {
		incr j
		set fillcolor [lindex $args $j]
		set new_fillcolor 1
	    }
	    "-font" {
		incr j
		set font [string trim [lindex $args $j]]
		set new_font 1
	    }
	}
	incr j
    }
    # Update the associated data for the node
    if { $new_label_text } {
	set dotgraph([subst $g]_NODE_LABEL) \
	    [lreplace $dotgraph([subst $g]_NODE_LABEL) $i $i "$label_text"]
    }
    if { $new_shape } {
	set dotgraph([subst $g]_NODE_SHAPE) \
	    [lreplace $dotgraph([subst $g]_NODE_SHAPE) $i $i $shape]
    }
    if { $new_color } {
	set dotgraph([subst $g]_NODE_COLOR) \
	    [lreplace $dotgraph([subst $g]_NODE_COLOR) $i $i $color]
    }
    if { $new_fillcolor } {
	set dotgraph([subst $g]_NODE_FILLCOLOR) \
	    [lreplace $dotgraph([subst $g]_NODE_FILLCOLOR) $i $i $fillcolor]
    }
    if { $new_font } {
	set dotgraph([subst $g]_NODE_FONT) \
	    [lreplace $dotgraph([subst $g]_NODE_FONT) $i $i $font]
    }
    return {}
}

#---------------------------------------------------------------
proc dotgraph_update_node_color { g name new_color \
				      { canvas_list {} } } {
#---------------------------------------------------------------
    # Update the (fill)colour of the named node
    # This configures the colour and also changes the
    # display of the node in the canvas widgets listed in
    # "canvas_list" (or all canvases where g is rendered,
    # if the list is empty
    global dotgraph
    if { ![dotgraph_exists $g] } {
	# This graph doesn't exist
	puts "dotgraph_update_node_color: no graph called \"$g\" found"
	return {}
    }
    if { [set i [lsearch $dotgraph([subst $g]_NODE_NAME) $name]] < 0 } {
	# Couldn't find the requested node
	puts "dotgraph_update_node_color: no node called \"$name\" found"
	return {}
    }
    # Check list of canvases
    if { [llength $canvas_list] == 0 } {
	set canvas_list $dotgraph([subst $g]_CANVASES)
    }
    # Loop over canvases and set the fillcolour
    foreach c $canvas_list {
	if { [winfo exists $c] } {
	    set itemname "_dotgraph_node_$name"
	    $c itemconfig $itemname -fill $new_color
	} else {
	    puts "dotgraph_update_node_color: canvas \"$c\" not found"
	}
    }
    # Update the data structure
    return [dotgraph_configure_node $g $name -fillcolor $new_color]
}

#---------------------------------------------------------------
proc dotgraph_decorate_node { name c items args } {
#---------------------------------------------------------------
    # Decorate a node by positioning arbitrary canvas items onto it
    #
    # The canvas items must previously have been created by the
    # calling application, which supplies a list of one or more
    # canvas item ids for decoration.
    #
    # Arguments determine the positioning of the decoration
    # with respect to the node:
    #
    # -anchor <anchorPos> (default is se)
    #      Sets which edge or corner of the node the decoration
    #      will be placed on.
    #
    # -overlap <fraction> (default is 0.5)
    #      Sets the amount of overlap in x and y the decoration
    #      will have with the node bounding box. Zero means that
    #      the decoration will be completely outside the node,
    #      1.0 means it will be completely inside it.
    #
    # -overlap_x <fraction> (default is 0.5)
    #      Sets the amount of overlap in the x direction only.
    #      Zero means that the decoration will be completely
    #      outside the node in the x direction, 1.0 means it will
    #      be completely inside it.
    #
    # -overlap_y <fraction> (default is 0.5)
    #      Sets the amount of overlap in the y direction only.
    #      Zero means that the decoration will be completely
    #      outside the node in the y direction, 1.0 means it will
    #      be completely inside it.
    #
    if { ![winfo exists $c] } {
	# This canvas doesn't exist
	puts "dotgraph_decorate_node: no canvas called \"$c\" found"
	return {}
    }
    # Get the bounding box for the node
    if { [llength [set bbox [$c bbox "_dotgraph_node_$name"]]] != 4 } {
	# Error in acquiring bounding box
	puts "dotgraph_decorate_node: error acquiring node bbox"
	return {}
    }
    # Determine centre of node
    set nodex0 [expr ( [lindex $bbox 2] - [lindex $bbox 0] ) / 2 + \
		   [lindex $bbox 0]]
    set nodey0 [expr ( [lindex $bbox 3] - [lindex $bbox 1] ) / 2 + \
		   [lindex $bbox 1]]
    # Initialise the defaults
    set anchor_pos "se"
    set overlap_x 0.5
    set overlap_y 0.5
    # Process the arguments
    set n [llength $args]
    set j 0
    while { $j < $n } {
	switch -- [lindex $args $j] {
	    "-anchor" {
		incr j
		set anchor_pos [lindex $args $j]
	    }
	    "-overlap" {
		incr j
		set overlap_x [lindex $args $j]
		set overlap_y $overlap_x
	    }
	    "-overlap_x" {
		incr j
		set overlap_x [lindex $args $j]
	    }
	    "-overlap_y" {
		incr j
		set overlap_y [lindex $args $j]
	    }
	}
	incr j
    }
    # Sort out the anchor positioning and also adjust the
    # overlap factors as appropriate
    switch -- $anchor_pos {
	"center" {
	    # Use the centre of the node
	    set nodex $nodex0
	    set nodey $nodey0
	    # Overlap is irrelevant
	    set overlap_x 0.5
	    set overlap_y 0.5
	}
	"n" {
	    # Determine position of centre of "northern" edge
	    set nodex [expr ( [lindex $bbox 2] - [lindex $bbox 0] ) / 2 + \
			   [lindex $bbox 0]]
	    set nodey [lindex $bbox 1]
	    # Adjust the overlaps
	    set overlap_x 0.5
	    set overlap_y [expr 1.0 - $overlap_y]
	}
	"e" {
	    # Determine position of centre of "eastern" edge
	    set nodex [lindex $bbox 2]
	    set nodey [expr ( [lindex $bbox 3] - [lindex $bbox 1] ) / 2 + \
			   [lindex $bbox 1]]
	    # Adjust the overlaps
	    set overlap_y 0.5
	}
	"s" {
	    # Determine position of centre of "southern" edge
	    set nodex [expr ( [lindex $bbox 2] - [lindex $bbox 0] ) / 2 + \
			   [lindex $bbox 0]]
	    set nodey [lindex $bbox 3]
	    # Adjust the overlaps
	    set overlap_x 0.5
	}
	"w" {
	    # Determine position of centre of "western" edge
	    set nodex [lindex $bbox 0]
	    set nodey [expr ( [lindex $bbox 3] - [lindex $bbox 1] ) / 2 + \
			   [lindex $bbox 1]]
	    # Adjust the overlaps
	    set overlap_x [expr 1.0 - $overlap_x]
	    set overlap_y 0.5
	}
	"ne" {
	    # Determine position of "north-eastern" corner
	    set nodex [lindex $bbox 2]
	    set nodey [lindex $bbox 1]
	    # Adjust the overlaps
	    set overlap_y [expr 1.0 - $overlap_y]
	}
	"se" {
	    # Determine position of "south-eastern" corner
	    set nodex [lindex $bbox 2]
	    set nodey [lindex $bbox 3]
	}
	"sw" {
	    # Determine position of "south-western" corner
	    set nodex [lindex $bbox 0]
	    set nodey [lindex $bbox 3]
	    # Adjust the overlaps
	    set overlap_x [expr 1.0 - $overlap_x]
	}
	"nw" {
	    # Determine position of "north-western" corner
	    set nodex [lindex $bbox 0]
	    set nodey [lindex $bbox 1]
	    # Adjust the overlaps
	    set overlap_x [expr 1.0 - $overlap_x]
	    set overlap_y [expr 1.0 - $overlap_y]
	}
	default {
	    puts "dotgraph_decorate_node: unrecognised anchor position \"$anchor_pos\""
	    return {}
	}
    }
    # Recalculate the edge of the node for ellipses and diamonds
    switch -exact [$c type _dotgraph_node_$name] {
	"rectangle" {
	    # Node is a box
	    # Nothing to do
	}
	"oval" {
	    # Node is an ellipse
	    set a [expr ( [lindex $bbox 2] - [lindex $bbox 0] )/2.0]
	    set b [expr ( [lindex $bbox 3] - [lindex $bbox 1] )/2.0]
	    set new_points [nearest_point_on_ellipse \
				$nodex0 $nodey0 $nodex $nodey $a $b]
	    set nodex [lindex $new_points 0]
	    set nodey [lindex $new_points 1]
	}
	default {
	    # Assume node is a diamond
	    set a [expr ( [lindex $bbox 2] - [lindex $bbox 0] )/2.0]
	    set b [expr ( [lindex $bbox 3] - [lindex $bbox 1] )/2.0]
	    set new_points [nearest_point_on_diamond \
				$nodex0 $nodey0 $nodex $nodey $a $b]
	    set nodex [lindex $new_points 0]
	    set nodey [lindex $new_points 1]
	}
    }
    # Reposition the decorations
    foreach item $items {
	if { [llength [set dec_bbox [$c bbox "$item"]]] != 4 } {
	    # Error in acquiring bounding box
	    puts "dotgraph_decorate_node: error acquiring decoration bbox for \"$item\""
	    return {}
	}
	# Get the centre of the decoration
	set x0 [expr ( [lindex $dec_bbox 2] - [lindex $dec_bbox 0] ) * $overlap_x + \
		    [lindex $dec_bbox 0]]
	set y0 [expr ( [lindex $dec_bbox 3] - [lindex $dec_bbox 1] ) * $overlap_y + \
		    [lindex $dec_bbox 1]]
	# Calculate offsets
	set xoffset [expr $nodex - $x0]
	set yoffset [expr $nodey - $y0]
	# Move the decoration to the bottom right-hand corner
	$c move $item $xoffset $yoffset
    }
    return {}
}

#---------------------------------------------------------------
proc dotgraph_decorate_connection { start end c items } {
#---------------------------------------------------------------
    # Decorate a connecting line by positioning arbitrary canvas
    # items onto it
    #
    # The canvas items must previously have been created by the
    # calling application, which supplies a list of one or more
    # canvas item ids for decoration.
    #
    if { ![winfo exists $c] } {
	# This canvas doesn't exist
	puts "dotgraph_decorate_connection: no canvas called \"$c\" found"
	return {}
    }
    # Acquire the id for the connection
    set name "[subst $start]_[subst $end]"
    # Acquire the coordinates in the middle of the line
    set coords [$c coords "$name"]
    # n should be the number of points (= pairs of coords)
    set n [expr [llength $coords] / 2]
    # Position the decoration centred on the "middle" point
    # of the line
    set npos [expr int ($n * 0.5)]
    set x [lindex $coords [expr $npos*2]]
    set y [lindex $coords [expr $npos*2 + 1]]
    # Initialise overlaps
    set overlap_x 0.5
    set overlap_y 0.5
    # Reposition the decorations
    foreach item $items {
	if { [llength [set dec_bbox [$c bbox "$item"]]] != 4 } {
	    # Error in acquiring bounding box
	    puts "dotgraph_decorate_connection: error acquiring decoration bbox for \"$item\""
	    return {}
	}
	# Get the centre of the decoration
	set x0 [expr ( [lindex $dec_bbox 2] - [lindex $dec_bbox 0] ) \
		    * $overlap_x + [lindex $dec_bbox 0]]
	set y0 [expr ( [lindex $dec_bbox 3] - [lindex $dec_bbox 1] ) \
		    * $overlap_y + [lindex $dec_bbox 1]]
	# Calculate offsets
	set xoffset [expr $x - $x0]
	set yoffset [expr $y - $y0]
	# Move the decoration onto the connection
	$c move $item $xoffset $yoffset
    }
    return {}
}

#---------------------------------------------------------------
proc dotgraph_delete_node { g name } {
#---------------------------------------------------------------
    # Remove the named node from the graph
    global dotgraph
    if { ![dotgraph_exists $g] } {
	# This graph doesn't exist
	puts "dotgraph_delete_node: no graph called \"$g\" found"
	return {}
    }
    if { [set i [lsearch $dotgraph([subst $g]_NODE_NAME) $name]] < 0 } {
	# Node with this name already exists
	puts "dotgraph_delete_node: no node called \"$name\" found"
	return {}
    }
    # First remove all connections to and from this node
    # Find the connections
    set start_list {}
    set end_list {}
    for { set j 0 } \
	{ $j < [llength $dotgraph([subst $g]_EDGE_NAME)] } \
	{ incr j } {
	    set start [lindex $dotgraph([subst $g]_EDGE_START) $j]
	    set end [lindex $dotgraph([subst $g]_EDGE_END) $j]
	    if { $start == $name || $end == $name } {
		# Found a connection to delete
		lappend start_list $start
		lappend end_list $end
	    }
	}
    # Delete the connections
    for { set j 0 } { $j < [llength $start_list] } { incr j } {
	set start [lindex $start_list $j]
	set end [lindex $end_list $j]
	dotgraph_delete_connection $g $start $end 
    }
    # Remove the node from the data structure
    set dotgraph([subst $g]_NODE_NAME) \
	[lreplace $dotgraph([subst $g]_NODE_NAME) $i $i]
    set dotgraph([subst $g]_NODE_LABEL) \
	[lreplace $dotgraph([subst $g]_NODE_LABEL) $i $i]
    set dotgraph([subst $g]_NODE_SHAPE) \
	[lreplace $dotgraph([subst $g]_NODE_SHAPE) $i $i]
    set dotgraph([subst $g]_NODE_COLOR) \
	[lreplace $dotgraph([subst $g]_NODE_COLOR) $i $i]
    set dotgraph([subst $g]_NODE_FILLCOLOR) \
	[lreplace $dotgraph([subst $g]_NODE_FILLCOLOR) $i $i]
    set dotgraph([subst $g]_NODE_FONT) \
	[lreplace $dotgraph([subst $g]_NODE_FONT) $i $i]
    set dotgraph([subst $g]_NODE_BINDINGS) \
	[lreplace $dotgraph([subst $g]_NODE_BINDINGS) $i $i]    
    return {}
}

#---------------------------------------------------------------
proc dotgraph_bind_node { g name sequence cmd } {
#---------------------------------------------------------------
    # Add a binding to the named node
    # Sequence can be any allowed Tk binding sequence
    global dotgraph
    if { ![dotgraph_exists $g] } {
	# This graph doesn't exist
	puts "dotgraph_bind_node: no graph called \"$g\" found"
	return {}
    }
    if { [set i [lsearch $dotgraph([subst $g]_NODE_NAME) $name]] < 0 } {
	# Node with this name already exists
	puts "dotgraph_bind_node: no node called \"$name\" found"
	return {}
    }
    # Fetch the current binding info
    set bindings [lindex $dotgraph([subst $g]_NODE_BINDINGS) $i]
    # Check to see if this sequence is already bound
    set j 0
    foreach binding $bindings {
	if { "$sequence" == "[lindex $binding 0]" } {
	    break
	}
	incr j
    }
    if { $j < [llength $bindings] } {
	# Found a match - remove this binding
	set bindings [lreplace $bindings $j $j]
    }
    # Append the new binding to the end of the list
    lappend bindings [list "$sequence" "$cmd"]
    # Update the data structure
    set dotgraph([subst $g]_NODE_BINDINGS) \
	[lreplace $dotgraph([subst $g]_NODE_BINDINGS) $i $i $bindings]
    return {}
}

#---------------------------------------------------------------
proc dotgraph_configure_connection { g start end args } {
#---------------------------------------------------------------
    # Configure the display options of the connection between
    # the specified nodes
    # This supports the same arguments as dotgraph_add_connection:
    # -label <text>
    # -color <color>
    # -font <font>
    global dotgraph
    if { ![dotgraph_exists $g] } {
	# This graph doesn't exist
	puts "dotgraph_configure_connection: no graph called \"$g\" found"
	return {}
    }
    # Look up the nodes
    set name "[subst $start]_$end"
    if { [set i [lsearch $dotgraph([subst $g]_EDGE_NAME) $name]] < 0 } {
	# Node with this name already exists
	puts "dotgraph_configure_connection: no connection found between \"$start\" and \"$end\""
	return {}
    }
    # Initialise local variables
    set new_label_text 0
    set label_text ""
    set new_color 0
    set color ""
    set new_font 0
    set font ""
    # Process the arguments
    set n [llength $args]
    set j 0
    while { $j < $n } {
	switch -- [lindex $args $j] {
	    "-label" {
		incr j
		# Labels are restricted to 127 characters
		set label_text [string range \
				    [escape_newlines [lindex $args $j]] 0 126]
		set new_label_text 1
	    }
	    "-color" {
		incr j
		set color [lindex $args $j]
		set new_color 1
	    }
	    "-font" {
		incr j
		set font [string trim [lindex $args $j]]
		set new_font 1
	    }
	}
	incr j
    }
    # Update the associated data for the connection
    if { $new_label_text } {
	set dotgraph([subst $g]_EDGE_LABEL) \
	    [lreplace $dotgraph([subst $g]_EDGE_LABEL) $i $i "$label_text"]
    }
    if { $new_color } {
	set dotgraph([subst $g]_EDGE_COLOR) \
	    [lreplace $dotgraph([subst $g]_EDGE_COLOR) $i $i $color]
    }
    if { $new_font } {
	set dotgraph([subst $g]_EDGE_FONT) \
	    [lreplace $dotgraph([subst $g]_EDGE_FONT) $i $i $font]
    }
    return {}
}

#---------------------------------------------------------------
proc dotgraph_delete_connection { g start end } {
#---------------------------------------------------------------
    # Remove the connection between the named nodes
    global dotgraph
    if { ![dotgraph_exists $g] } {
	# This graph doesn't exist
	puts "dotgraph_delete_connection: no graph called \"$g\" found"
	return {}
    }
    set name "[subst $start]_$end"
    if { [set i [lsearch $dotgraph([subst $g]_EDGE_NAME) $name]] < 0 } {
	# Node with this name already exists
	puts "dotgraph_delete_connection: no connection found between \"$start\" and \"$end\""
	return {}
    }
    # Remove the connection from the data structure
    set dotgraph([subst $g]_EDGE_NAME) \
	[lreplace $dotgraph([subst $g]_EDGE_NAME) $i $i]
    set dotgraph([subst $g]_EDGE_START) \
	[lreplace $dotgraph([subst $g]_EDGE_START) $i $i]
    set dotgraph([subst $g]_EDGE_END) \
	[lreplace $dotgraph([subst $g]_EDGE_END) $i $i]
    set dotgraph([subst $g]_EDGE_LABEL) \
	[lreplace $dotgraph([subst $g]_EDGE_LABEL) $i $i]
    set dotgraph([subst $g]_EDGE_COLOR) \
	[lreplace $dotgraph([subst $g]_EDGE_COLOR) $i $i]
    set dotgraph([subst $g]_EDGE_FONT) \
	[lreplace $dotgraph([subst $g]_EDGE_FONT) $i $i]
    set dotgraph([subst $g]_EDGE_BINDINGS) \
	[lreplace $dotgraph([subst $g]_EDGE_BINDINGS) $i $i]
    return {}
}

#---------------------------------------------------------------
proc dotgraph_bind_connection { g start end sequence cmd } {
#---------------------------------------------------------------
    # Add a binding to the named connection
    global dotgraph
    if { ![dotgraph_exists $g] } {
	# This graph doesn't exist
	puts "dotgraph_bind_connection: no graph called \"$g\" found"
	return {}
    }
    set name "[subst $start]_$end"
    if { [set i [lsearch $dotgraph([subst $g]_EDGE_NAME) $name]] < 0 } {
	# Node with this name already exists
	puts "dotgraph_bind_connection: no connection found between \"$start\" and \"$end\""
	return {}
    }
    # Fetch the current binding info
    set bindings [lindex $dotgraph([subst $g]_EDGE_BINDINGS) $i]
    # Check to see if this sequence is already bound
    set j 0
    foreach binding $bindings {
	if { "$sequence" == "[lindex $binding 0]" } {
	    break
	}
	incr j
    }
    if { $j < [llength $bindings] } {
	# Found a match - remove this binding
	set bindings [lreplace $bindings $j $j]
    }
    # Append the new binding to the end of the list
    lappend bindings [list "$sequence" "$cmd"]
    # Update the data structure
    set dotgraph([subst $g]_EDGE_BINDINGS) \
	[lreplace $dotgraph([subst $g]_EDGE_BINDINGS) $i $i $bindings]
    return {}
}

#---------------------------------------------------------------
proc dotgraph_write { g } {
#---------------------------------------------------------------
    # Generate input to the dot program
    global dotgraph
    if { ![dotgraph_exists $g] } {
	# This graph doesn't exist
	puts "dotgraph_write: no graph called \"$g\" found"
	return {}
    }
    set digraph "digraph g \{\n"
    # Set the direction
    append digraph "\trankdir=$dotgraph([subst $g]_DIRECTION);\n"
    # Add the nodes
    for { set i 0 } \
	{ $i < [llength $dotgraph([subst $g]_NODE_NAME)] } \
	{ incr i } {
	    set name [lindex $dotgraph([subst $g]_NODE_NAME) $i]
	    set label_text "[lindex $dotgraph([subst $g]_NODE_LABEL) $i]"
	    set shape [lindex $dotgraph([subst $g]_NODE_SHAPE) $i]
	    set color [lindex $dotgraph([subst $g]_NODE_COLOR) $i]
	    set fillcolor [lindex $dotgraph([subst $g]_NODE_FILLCOLOR) $i]
	    set font [lindex $dotgraph([subst $g]_NODE_FONT) $i]
	    append digraph "\t$name \[shape=$shape"
	    if { "$label_text" != "" } {
		append digraph ",label=\"$label_text\""
	    }
	    if { "$fillcolor" != "" } {
		append digraph ",style=filled,fillcolor=\"$fillcolor\""
	    }
	    if { "$color" != "" } {
		append digraph ",color=\"$color\""
	    }
	    if { "$font" != "" } {
		set fontname [font actual $font -family]
		set fontsize [font actual $font -size]
		append digraph ",fontname=$fontname,fontsize=$fontsize"
	    }
	    append digraph "\];\n"
	}
    # Add the edges
    for { set i 0 } \
	{$i < [llength $dotgraph([subst $g]_EDGE_START)] } \
	{ incr i } {
	    set tail [lindex $dotgraph([subst $g]_EDGE_START) $i]
	    set head [lindex $dotgraph([subst $g]_EDGE_END) $i]
	    append digraph "\t$tail -> $head"
	    set label_text [lindex $dotgraph([subst $g]_EDGE_LABEL) $i]
	    set color [lindex $dotgraph([subst $g]_EDGE_COLOR) $i]
	    set font [lindex $dotgraph([subst $g]_EDGE_FONT) $i]
	    append digraph " \[color=$color"
	    if { "$label_text" != "" } {
		append digraph ",label=\"$label_text\""
	    }
	    if { "$font" != "" } {
		set fontname [font actual $font -family]
		set fontsize [font actual $font -size]
		append digraph ",fontname=$fontname,fontsize=$fontsize"
	    }
	    append digraph "\];\n"
	}
    # Close the digraph
    append digraph "\}"
    return $digraph
}

#---------------------------------------------------------------
proc dotgraph_render_output { g format filen args } {
#---------------------------------------------------------------
    # Invoke dot to generate the dotgraph in the requested
    # format to the specified file
    # Acceptable formats are any of those accepted by dot
    # via it's -T command line option
    # optionally a different rendering engine can be specified
    # via the "-using" option (e.g. dot, circo, twopi, neato)
    global dotgraph
    if { ![dotgraph_exists $g] } {
	# This graph doesn't exist
	puts "dotgraph_render_output: no graph called \"$g\" found"
	return {}
    }
    #
    # Process the arguments
    set rendering_engine ""
    set n [llength $args]
    set i 0
    while { $i < $n } {
	switch -- [lindex $args $i] {
            "-using" {
		incr i
		set rendering_engine [lindex $args $i]
            }
	}
	incr i
    }
    # Set the rendering engine if not explicitly specified
    if { $rendering_engine == "" } {
	set rendering_engine "dot"
    }
    # Generate the dot input
    set dot_input [dotgraph_write $g]
    # Run the dot program
    if { [catch { exec [file join $dotgraph(DOT_DIR) $rendering_engine] \
	      -T$format << "$dot_input" -o $filen } dot_output ] } {
	# Error occurred
	puts "dotgraph_render_output: error: \"$dot_output\""
	return 0
    }
    # Return ok
    return 1
}

#---------------------------------------------------------------
proc dotgraph_render { g c args } {
#---------------------------------------------------------------
    # Render the dotgraph on the specified
    # canvas
    # Optionally scale the canvas
    global dotgraph
    if { ![dotgraph_exists $g] } {
	# This graph doesn't exist
	puts "dotgraph_render: no graph called \"$g\" found"
	return {}
    }
    # Check that there is something to render
    if { [llength $dotgraph([subst $g]_NODE_NAME)] == 0 } {
	puts "dotgraph_render: graph has no nodes"
	return {}
    }
    # Is this canvas already in the list for this graph?
    if { [lsearch $dotgraph([subst $g]_CANVASES) $c] < 0 } {
	lappend dotgraph([subst $g]_CANVASES) $c
    }
    # Start processing the arguments
    set scale_factor $dotgraph(SCALE_FACTOR)
    set shadow 0
    set font {}
    set rendering_engine ""
    set labels 1
    set n [llength $args]
    set i 0
    # Backwards compatibility - in previous versions, the
    # first optional argument was the scalefactor
    if { $n > 0 } {
	set arg1 [lindex $args 0]
	if { [string is double $arg1] } {
	    # Assume that it's a scalefactor
	    set scale_factor $arg1
	    set i 1
	}
    }
    # Process the remaining arguments
    while { $i < $n } {
	switch -- [lindex $args $i] {
	    "-scale" {
		incr i
		set scale_factor [lindex $args $i]
	    }
	    "-shadow" {
		incr i
		set shadow [lindex $args $i]
	    }
            "-using" {
		incr i
		set rendering_engine [lindex $args $i]
            }
	    "-nolabels" {
		set labels 0
	    }
	}
	incr i
    }
    # Set the rendering engine if not explicitly specified
    if { $rendering_engine == "" } {
	set rendering_engine "dot"
    }
    # Generate the dot input
    set dot_input [dotgraph_write $g]
    # Run the dot program to get the "plain" output
    if { [catch { exec [file join $dotgraph(DOT_DIR) $rendering_engine] \
	      -Tplain << "$dot_input" } dot_output ] } {
	# Error occurred
	puts "dotgraph_render: error: \"$dot_output\""
	return {}
    }
    # Store the name of the current canvas
    set dotgraph([subst $g]_CANVAS) $c
    # Mark the origin with a dot and x/y axes
    if { $dotgraph([subst $g]_DEBUG) } {
	$c create oval -0.05 -0.05 0.05 0.05 -fill black \
	    -tags { _dotgraph }
	$c create line 0 0 0.5 0 -arrow last -width 2 \
	    -tags { _dotgraph }
	$c create line 0 0 0 0.5 -arrow last -width 2 \
	    -tags { _dotgraph }
    }
    # Feed this into the graphviz_canvas procedures
    graphviz_render $g $c $dot_output
    # Render shadows
    if { $shadow } {
	dotgraph_render_shadows $c
    }
    # Scale the dotgraph items in the canvas
    $c scale _dotgraph 0 0 $scale_factor [expr -1.0*$scale_factor]
    # Fix the size to fit the components
    set bbox [$c bbox _dotgraph]
    if { [llength $bbox] == 4 } {
	set width [expr [lindex $bbox 2] - [lindex $bbox 0]]
	set height [expr [lindex $bbox 3] - [lindex $bbox 1]]
	set xoffset [expr -1.0*[lindex $bbox 0]]
	set yoffset [expr -1.0*[lindex $bbox 1]]
	$c move _dotgraph $xoffset $yoffset
	$c configure -height $height -width $width
    } else {
	puts "dotgraph_render: error: invalid bounding box returned"
    }
    # Add the bindings
    render_apply_bindings $g $c
    if { $labels } {
	# Update the fonts
	render_apply_fonts $g $c -scale $scale_factor
    } else {
	# Delete the labels
	$c delete "_dotgraph_label"
    }
}

#---------------------------------------------------------------
proc dotgraph_render_update { g c args } {
#---------------------------------------------------------------
    # Render the graph again on a canvas
    # Delete all the dotgraph items
    $c delete "_dotgraph"
    # Render it all again
    return [eval dotgraph_render $g $c $args]
}

#---------------------------------------------------------------
proc dotgraph_render_shadows { c } {
#---------------------------------------------------------------
    # Add drop shadows to all graph nodes rendered in
    # the canvas
    # c is the name of the canvas; drop shadows will added
    # to all the canvas items tagged as "_dotgraph_node".
    set shadow_depth 0.1
    set shadow_colour "grey"
    foreach node [$c find withtag "_dotgraph_node"] {
	# Make a command to create a shadow copy of the node
	set shadow_cmd "$c create [$c type $node]"
	foreach coord [$c coords $node] {
	    append shadow_cmd " $coord"
	}
	# Add colours and tags
	    append shadow_cmd " -outline $shadow_colour -fill $shadow_colour -tags \{ \"_dotgraph_shadow\"  \"_dotgraph\" \}"
	# Display the shadow
	set shadowId [eval $shadow_cmd]
	# Put the shadow below the node in the display order
	$c lower $shadowId $node
	# Move the shadow to offset it fom the node
	$c move $shadowId $shadow_depth -$shadow_depth
    }
}

################################################################
# graphviz_render commands
################################################################

#---------------------------------------------------------------
proc graphviz_render_line { g c line } {
#---------------------------------------------------------------
    # Decode a line of "plain" file and pass it off to the
    # appropriate procedure
    if { [regexp "^\[ \t\]*graph" $line] } {
	##puts "GRAPH line"
	handle_graph_line $g $c $line
	return 1
    } elseif { [regexp "^\[ \t\]*node" $line] } {
	##puts "NODE line"
	handle_node_line $g $c $line
	return 1
    } elseif { [regexp "^\[ \t\]*edge" $line] } {
	##puts "EDGE line"
	handle_edge_line $g $c $line
	return 1
    } elseif { [regexp "^\[ \t\]*stop" $line] } {
	##puts "STOP line, quitting"
	return 0
    } else {
	##puts "Unrecognised line, ignoring"
	return 0
    }
}

#---------------------------------------------------------------
proc graphviz_render { g c plain } {
#---------------------------------------------------------------
    # Parse and render the supplied text as plain
    # output from graphviz
    global dotgraph
    # Parse each line in the plain output
    set plain_text [split $plain "\n"]
    foreach line $plain_text {
	if { ![graphviz_render_line $g $c $line] } {
	    break
	}
    }
    # Set canvas background
    if { [set background $dotgraph([subst $g]_BACKGROUND)] != "" } {
	$c configure -background $background
    }
    # Correct for "upside down" coordinates
    set bbox [$c bbox all]
    if { [llength $bbox] == 4 } {
	set xoffset [expr -1.0*[lindex $bbox 0]]
	set yoffset [expr -1.0*[lindex $bbox 1]]
	$c move all $xoffset $yoffset
    } else {
	puts "graphviz_render: error: invalid bounding box"
    }
}

#---------------------------------------------------------------
proc graphviz_render_file { c plainfile } {
#---------------------------------------------------------------
    # Parse and render the contents of the specified
    # file as plain output from graphviz
    if { ! [file exists $plainfile] } {
	return
    }
    # Open the file and read a line at a time
    set fp [open $plainfile "r"]
    while { ![eof $fp] } {
	gets $fp line
	if { ![graphviz_render_line $g $c $line] } {
	    break
	}
    }
    # Close the file
    close $fp
    return
}

################################################################
# handle_* commands
################################################################

#---------------------------------------------------------------
proc handle_graph_line { g c line } {
#---------------------------------------------------------------
    # Process a line starting "graph"
    # Format is:
    # graph <scalefactor> <width> <height>
    if { [llength $line] != 4 } {
	puts "handle_graph_line: wrong number of args for GRAPH line"
	return
    }
    # Actually we don't use this information at the
    # moment
    set scalefactor [lindex $line 1]
    set width [lindex $line 2]
    set height [lindex $line 3]
    return
}

#---------------------------------------------------------------
proc handle_node_line { g c line } {
#---------------------------------------------------------------
    # Process a line starting "node"
    # Format is:
    # node <name> <x> <y> <xsize> <ysize> <label> <style> <shape> <color> <fillcolor>
    if { [llength $line] != 11 } {
	puts "handle_node_line: wrong number of args for NODE line"
	return
    }
    set name [lindex $line 1]
    set x [lindex $line 2]
    set y [lindex $line 3]
    set xsize [lindex $line 4]
    set ysize [lindex $line 5]
    set label [lindex $line 6]
    set style [lindex $line 7]
    set shape [lindex $line 8]
    set color [lindex $line 9]
    set fillcolor [lindex $line 10]
    ##puts "name $name x $x y $y xsize $xsize ysize $ysize label $label style $style shape $shape color $color fillcolor $fillcolor"
    # Draw the node on the canvas
    render_node $g $c $name $x $y $xsize $ysize $shape \
	-label "$label" \
	-style "$style" \
	-color "$color" \
	-fillcolor "$fillcolor"
}

#---------------------------------------------------------------
proc handle_edge_line { g c line } {
#---------------------------------------------------------------
    # Process a line starting "edge"
    # Format is:
    # edge <tail> <head> <n> <x1> <y1> ... <xn> <yn> [<label> <lx> <lz>] <style> <color>
    if { [llength $line] >= 3 } {
	set tail [lindex $line 1]
	set head [lindex $line 2]
	##puts "Joins \"$tail\" to \"$head\""
    }
    if { [llength $line] >= 4 } {
	set npoints [lindex $line 3]
	##puts "Number of points in bspline = $npoints"
	set vector {}
	for { set i 4 } { $i < [expr $npoints*2+4] } { incr i } {
	    if { $i < [llength $line] } {
		lappend vector [lindex $line $i]
	    } else {
		puts "handle_edge_line: error parsing EDGE"
		return
	    }
	}
	##puts "Vector = $vector"
    }
    ##puts "(Now i = $i)"
    if { [llength $line] == [expr $i+5] } {
	# Label expected
	set label [lindex $line $i]
	incr i
	set lx [lindex $line $i]
	incr i
	set ly [lindex $line $i]
	incr i
	##puts "Label = \"$label\" lx = $lx ly = $ly"
    } else {
	set label ""
	set lx ""
	set ly ""
    }
    ##puts "(Now i = $i)"
    if { [llength $line] == [expr $i+2] } {
	# Remaining two arguments
	set style [lindex $line $i]
	set color [lindex $line [expr $i+1]]
	##puts "Style = $style Color = $color"
    } else {
	set style ""
	set color ""
    }
    # Draw the line on the canvas
    if { "$label" != "" } {
	render_edge $g $c $head $tail $vector \
	    -label "$label" $lx $ly \
	    -style "$style" \
	    -color "$color"
    } else {
	render_edge $g $c $head $tail $vector \
	    -style "$style" \
	    -color "$color"
    }
    return
}

################################################################
# render_* commands
################################################################

#---------------------------------------------------------------
proc render_node { g c name x y xsize ysize shape args } {
#---------------------------------------------------------------
    # Draw the node on the canvas
    global dotgraph
    # Process the arguments
    set n [llength $args]
    set i 0
    set label_text "$name"
    set style {}
    set color "black"
    set fillcolor {}
    while { $i < $n } {
	switch -- [lindex $args $i] {
	    "-label" {
		incr i
		set label_text "[lindex $args $i]"
	    }
	    "-style" {
		incr i
		set style [lindex $args $i]
	    }
	    "-color" {
		incr i
		set color [lindex $args $i]
	    }
	    "-fillcolor" {
		incr i
		set fillcolor [lindex $args $i]
	    }
	}
	incr i
    }
    # Initialise the drawing command
    set node_cmd "$c create"
    # x,y are the centre of the node
    if { $shape == "ellipse" } {
	# Render an oval
	append node_cmd " oval \
            [expr $x-($xsize/2.0)] [expr $y-($ysize/2.0)] \
	    [expr $x+($xsize/2.0)] [expr $y+($ysize/2.0)]"
    } elseif { $shape == "box" } {
	# Render a rectangle
	append node_cmd " rectangle \
            [expr $x-($xsize/2.0)] [expr $y-($ysize/2.0)] \
	    [expr $x+($xsize/2.0)] [expr $y+($ysize/2.0)]"
    } elseif { $shape == "diamond" } {
	# Render a diamond-shaped polygon
	append node_cmd " polygon \
	    [expr $x-($xsize/2.0)] [expr $y] \
	    [expr $x] [expr $y-($ysize/2.0)] \
	    [expr $x+($xsize/2.0)] [expr $y] \
	    [expr $x] [expr $y+($ysize/2.0)]"
    }
    # Add additional options
    append node_cmd " -outline $color"
    if { "$style" == "filled" } {
	append node_cmd " -fill $fillcolor"
    } else {
	append node_cmd " -fill \{\}"
    }
    # Add the canvas tags for the node
    # One tag is the node name, another is the general "node" tag
    append node_cmd " -tags \{ \"$name\" \"_dotgraph_node\" \"_dotgraph_node_$name\" \"_dotgraph\" \}"
    # Draw the node
    eval $node_cmd
    # Add the label
    #if { [set k [lsearch $args "-label"]] > -1 } {
	#set label "[lindex $args [expr $k+1]]"
    #} else {
	#set label "$name"
    #}
    $c create text $x $y -anchor c -justify center \
	-text "$label_text" -fill $color\
	-tags [list "$name" "_dotgraph_label" "_dotgraph_label_$name" "_dotgraph"]
    # Store the node shape coordinates and size for reference
    # when extending the edge lines
    set dotgraph([subst $g]_RENDERED_NODE_DATA_$name) \
	[list $shape $x $y $xsize $ysize]
}

#---------------------------------------------------------------
proc render_edge { g c head tail vector args } {
#---------------------------------------------------------------
    # Draw the edge on the canvas
    global dotgraph
    # Set the name for this edge
    set name "[subst $tail]_[subst $head]"
    # Process the arguments
    set n [llength $args]
    set i 0
    set label_text ""
    set style {}
    set color "black"
    set fillcolor {}
    while { $i < $n } {
	switch -- [lindex $args $i] {
	    "-label" {
		incr i
		set label_text "[lindex $args $i]"
		incr i
		set lx "[lindex $args $i]"
		incr i
		set ly "[lindex $args $i]"
	    }
	    "-style" {
		incr i
		set style [lindex $args $i]
	    }
	    "-color" {
		incr i
		set color [lindex $args $i]
	    }
	}
	incr i
    }
    # Initialise the drawing command
    set line_cmd "$c create line"
    foreach x $vector {
	append line_cmd " $x"
    }
    # Extend the line to the edge of the tail node
    set last_point [extend_edge $g $head $vector]
    if { [llength $last_point] == 2 } {
	append line_cmd " [lindex $last_point 0] [lindex $last_point 1]"
    }
    # Add additional options
    # Ignore "style" for now
    append line_cmd " -fill $color -smooth yes -arrow last"
    # Set the tags
    append line_cmd " -tags \{ \"$name\" \"_dotgraph_edge\" \"_dotgraph\" \}"
    # Create the line
    eval $line_cmd

    # Add the label
    if { "$label_text" != "" } {
	$c create text $lx $ly \
	    -anchor c -text "$label_text" \
	    -tags [list "$name" "_dotgraph_label" "_dotgraph"]
    }

    # Additional diagnostic output
    if { $dotgraph([subst $g]_DEBUG) } {
	# Not properly implemented yet
    }
}

#---------------------------------------------------------------
proc extend_edge { g name vector } {
#---------------------------------------------------------------
    # Given a graph name, a node name and a vector
    # provide a last x,y point to join the line to
    # the edge of the node shape
    global dotgraph
    # Look up the node data
    if { ![info exists dotgraph([subst $g]_RENDERED_NODE_DATA_$name)] } {
	puts "extend_edge $g $name ...: node \"$name\" not found"
	return {}
    }
    set data $dotgraph([subst $g]_RENDERED_NODE_DATA_$name)
    set shape [lindex $data 0]
    set x [lindex $data 1]
    set y [lindex $data 2]
    set xsize [lindex $data 3]
    set ysize [lindex $data 4]
    # Get the last set of points from the line
    set xv [lindex $vector [expr [llength $vector]-2]]
    set yv [lindex $vector [expr [llength $vector]-1]]
    # Plot the points for debugging
    if { $dotgraph([subst $g]_DEBUG) } {
	set c $dotgraph([subst $g]_CANVAS)
	$c create oval \
	    [expr $x-0.05] [expr $y-0.05] \
	    [expr $x+0.05] [expr $y+0.05] -fill black \
	    -tags { _dotgraph }
	$c create oval \
	    [expr $xv-0.05] [expr $yv-0.05] \
	    [expr $xv+0.05] [expr $yv+0.05] -fill red \
	    -tags { _dotgraph }
	$c create line $x $y $xv $yv \
	    -tags { _dotgraph }
    }
    # Calculate the point of intersection of the line
    # joining x,y and xv,yv with the edge of the node
    ##puts "***** $name *****"
    set a [expr $xsize/2.0]
    set b [expr $ysize/2.0]
    if { $shape == "ellipse" } {
	# Get details of the ellipse
	##puts "x0,y0 = $x,$y xv,yv = $xv,$yv, xsize,ysize = $xsize,$ysize"
	##puts "xv-x = [expr $xv - $x], yv-y = [expr $yv - $y], a,b = $a,$b"
	set nearest_points [nearest_point_on_ellipse $x $y $xv $yv $a $b]
	set x1 [lindex $nearest_points 0]
	set y1 [lindex $nearest_points 1]
	##puts "x1,y1 = $x1,$y1"
	# More debugging output
	if { $dotgraph([subst $g]_DEBUG) } {
	    set c $dotgraph([subst $g]_CANVAS)
	    $c create oval \
		[expr $x1-0.05] [expr $y1-0.05] \
		[expr $x1+0.05] [expr $y1+0.05] -fill green \
		-tags { _dotgraph }
	}
	return [list $x1 $y1]
    } elseif { $shape == "box" } {
	# Box node
	set nearest_points [nearest_point_on_box $x $y $xv $yv $a $b]
	set x1 [lindex $nearest_points 0]
	set y1 [lindex $nearest_points 1]
	##puts "x1,y1 = $x1,$y1"
	# More debugging output
	if { $dotgraph([subst $g]_DEBUG) } {
	    set c $dotgraph([subst $g]_CANVAS)
	    $c create oval \
		[expr $x1-0.05] [expr $y1-0.05] \
		[expr $x1+0.05] [expr $y1+0.05] -fill green \
		-tags { _dotgraph }
	}
	return [list $x1 $y1]
    } elseif { $shape == "diamond" } {
	# Box node
	set nearest_points [nearest_point_on_diamond $x $y $xv $yv $a $b]
	set x1 [lindex $nearest_points 0]
	set y1 [lindex $nearest_points 1]
	##puts "x1,y1 = $x1,$y1"
	# More debugging output
	if { $dotgraph([subst $g]_DEBUG) } {
	    set c $dotgraph([subst $g]_CANVAS)
	    $c create oval \
		[expr $x1-0.05] [expr $y1-0.05] \
		[expr $x1+0.05] [expr $y1+0.05] -fill green \
		-tags { _dotgraph }
	}
	return [list $x1 $y1]
    }
    return [list $x $y]
}

################################################################
# "Nearest point" functions
################################################################
#
# These functions are intended to supply one extra point at the
# end of connecting lines generated by dot - the extra point is
# need to join the line to the edge of the head node (this is
# a known limitation of the "plain" output from dot:
# https://mailman.research.att.com/pipermail/graphviz-interest/2005q1/002105.html
# and will not be addressed within dot).
#
# In the case of an ellipse, essentially points are generated on
# the outline of the ellipse and the distances from each point to
# the current end of the line and to the centre of the ellipse
# is calculated. The point where these combined distances are
# minimised is returned.
#
# In the case of a box, the point can be calculated exactly as
# the intersection of a line between the box centre and the
# current line end, with the nearest end of the box.
#
# In the case of a diamond, in principle the idea of the box
# could be applied. However I have implemented a similar method
# to that used for the ellipse, except the chosen point only
# minimises the distance to the current end of the line.
#
# Hopefully these comments will make it easier to understand
# what these functions are doing in practice.

#---------------------------------------------------------------
proc nearest_point_on_ellipse { x0 y0 x1 y1 a b } {
#---------------------------------------------------------------
    # Find the nearest point to the line joing x0 y0 and x1 y1
    # on an ellipse centred on x0 y0 with major and minor axes
    # a and b
    # This is ugly and not very accurate but it is simple to
    # code and understand!
    set two_pi 6.283185307
    set nsteps 100
    set arc_step [expr $two_pi/$nsteps]
    set theta 0
    set min_x2 $x0
    set min_y2 $y0
    set min_dist2 [expr 2.0*[dist_sq $x0 $y0 $x1 $y1]]
    set target [dist $x0 $y0 $x1 $y1]
    while { $theta < $two_pi } {
	set x2 [expr $a*cos($theta) + $x0]
	set y2 [expr $b*sin($theta) + $y0]
	set dist2 [expr [dist $x1 $y1 $x2 $y2] + \
		       [dist $x0 $y0 $x2 $y2] - \
		       $target]
	if { $dist2 < $min_dist2 } {
	    set min_x2 $x2
	    set min_y2 $y2
	    set min_dist2 $dist2
	}
	set theta [expr $theta + $arc_step]
    }
    return [list $min_x2 $min_y2]
}

#---------------------------------------------------------------
proc nearest_point_on_box { x0 y0 x1 y1 a b } {
#---------------------------------------------------------------
    # Find the nearest point to x1 y1 on a box (=rectangle) centred
    # on x0 y0 with edge lengths a*2 and b*2 respectively
    # This is essentially finding the intersection of a set of
    # lines
    ##puts "x0 = $x0, y0 = $y0, x1 = $x1, y1 = $y1"
    set amax [expr $x0 + $a]
    set amin [expr $x0 - $a]
    set bmax [expr $y0 + $b]
    set bmin [expr $y0 - $b]
    # Special cases
    if { $x0 == $x1 } {
	set x2 [list $x0 $x0]
	set y2 [list $bmax $bmin]
    } elseif { $y0 == $y1 } {
	set x2 [list $amax $amin]
	set y2 [list $y0 $y0]
    } else {
	# General case
	# Equation for the line between node centre
	# and the line point
	set m [expr ($y1-$y0)/($x1-$x0)]
	set c [expr $y0 - $x0*$m]
	##puts "m = $m c = $c"
	# Intersecting sets of lines with the
	# edges of the rectangle
	# i.e. lines x=amax, x=amin, y=bmax, y=bmin
	set x2 {}
	set y2 {}
	#
	# Intersection with x = x0 + a
	set xx $amax
	set yy [expr $m*$xx+$c]
	if { $yy <= $bmax && $yy >= $bmin } {
	    # Keep this point
	    lappend x2 $xx
	    lappend y2 $yy
	}
	# Intersection with x = x0 - a
	set xx $amin
	set yy [expr $m*$xx+$c]
	if { $yy <= $bmax && $yy >= $bmin } {
	    # Keep this point
	    lappend x2 $xx
	    lappend y2 $yy
	}
	# Intersection with y = y0 + b
	set yy $bmax
	set xx [expr ($yy-$c)/$m]
	if { $xx <= $amax && $xx >= $amin } {
	    # Keep this point
	    lappend x2 $xx
	    lappend y2 $yy
	}
	# Intersection with y = y0 - b
	set yy $bmin
	set xx [expr ($yy-$c)/$m]
	if { $xx <= $amax && $xx >= $amin } {
	    # Keep this point
	    lappend x2 $xx
	    lappend y2 $yy
	}
    }
    #
    ##puts "x2 = $x2"
    ##puts "y2 = $y2"
    #
    # Determine which point is closest to x1,y1
    set min_dist2 [dist_sq $x0 $y0 $x1 $y1]
    set min_x2 $x0
    set min_y2 $y0
    for { set i 0 } { $i < [llength $x2] } { incr i } {
	set xx [lindex $x2 $i]
	set yy [lindex $y2 $i]
	##puts "$i: xx = \"$xx\" yy = \"$yy\""
	set dist2 [dist_sq $xx $yy $x1 $y1]
	if { $dist2 <= $min_dist2 } {
	    set min_x2 $xx
	    set min_y2 $yy
	    set min_dist2 $dist2
	}
    }
    # Return the nearest point
    return [list $min_x2 $min_y2]
}

#---------------------------------------------------------------
proc nearest_point_on_diamond { x0 y0 x1 y1 a b } {
#---------------------------------------------------------------
    # Find the nearest point to x1 y1 on a diamond centred
    # on x0 y0 with width a*2 and height b*2
    # This is essentially finding the intersection of a set of
    # lines but actually uses a similar brute force approach
    # to that adopted for the ellipses
    ##puts "x0 = $x0, y0 = $y0, x1 = $x1, y1 = $y1"
    set amax [expr $x0 + $a]
    set amin [expr $x0 - $a]
    set bmax [expr $y0 + $b]
    set bmin [expr $y0 - $b]
    set target [dist $x0 $y0 $x1 $y1]
    # Special cases
    if { $x0 == $x1 } {
	if { [dist_sq $x0 $bmax $x1 $y1] < [dist_sq $x0 $bmin $x1 $y1] } {
	    set min_x2 $x0
	    set min_y2 $bmax
	} else {
	    set min_x2 $x0
	    set min_y2 $bmin
	}
    } elseif { $y0 == $y1 } {
	set x2 [list $amax $amin]
	set y2 [list $y0 $y0]
	if { [dist_sq $amax $y0 $x1 $y1] < [dist_sq $amin $y0 $x1 $y1] } {
	    set min_x2 $amax
	    set min_y2 $y0
	} else {
	    set min_x2 $amin
	    set min_y2 $y0
	}
    } else {
	# Intersecting sets of lines with the
	# edges of the diamond
	set min_x2 $x0
	set min_y2 $y0
	set min_dist2 [dist_sq $x0 $y0 $x1 $y1]
	#
	# Intersection with y = m1*x + c1
	# Starts at (amax,y0) and ends at (x0,bmax)
	set m1 [expr ($bmax-$y0)/($x0-$amax)]
	set c1 [expr $y0 - $amax*$m1]
	##puts "m1 = $m1 c1 = $c1"
	set xstep [expr $a/10.0]
	set xpos $x0
	while { $xpos < $amax } {
	    set ypos [expr $m1*$xpos + $c1]
	    set dist2 [expr [dist $x1 $y1 $xpos $ypos] + \
			   [dist $x0 $y0 $xpos $ypos] - \
			   $target]
	    if { $dist2 < $min_dist2 } {
		set min_x2 $xpos
		set min_y2 $ypos
		set min_dist2 $dist2
	    }
	    # Test the point reflected in the x-axis
	    set ypos [expr 2.0*$y0 - $ypos] 
	    set dist2 [expr [dist $x1 $y1 $xpos $ypos] + \
			   [dist $x0 $y0 $xpos $ypos] - \
			   $target]
	    if { $dist2 < $min_dist2 } {
		set min_x2 $xpos
		set min_y2 $ypos
		set min_dist2 $dist2
	    }
	    # Next point
	    set xpos [expr $xpos + $xstep]
	}
	# Intersection with y = m2*x + c2
	# Starts at (x0,bmax) and ends at (amin,y0)
	set m1 [expr ($y0-$bmax)/($amin-$x0)]
	set c1 [expr $bmax - $x0*$m1]
	##puts "m1 = $m1 c1 = $c1"
	set xstep [expr $a/10.0]
	set xpos $x0
	while { $xpos > $amin } {
	    set ypos [expr $m1*$xpos + $c1]
	    set dist2 [expr [dist $x1 $y1 $xpos $ypos] + \
			   [dist $x0 $y0 $xpos $ypos] - \
			   $target]
	    if { $dist2 < $min_dist2 } {
		set min_x2 $xpos
		set min_y2 $ypos
		set min_dist2 $dist2
	    }
	    # Test the point reflected in the x-axis
	    set ypos [expr 2.0*$y0 - $ypos] 
	    set dist2 [expr [dist $x1 $y1 $xpos $ypos] + \
			   [dist $x0 $y0 $xpos $ypos] - \
			   $target]
	    if { $dist2 < $min_dist2 } {
		set min_x2 $xpos
		set min_y2 $ypos
		set min_dist2 $dist2
	    }
	    # Next point
	    set xpos [expr $xpos - $xstep]
	}
    }
    # Return the nearest point
    return [list $min_x2 $min_y2]
}

#---------------------------------------------------------------
proc dist_sq { x0 y0 x1 y1 } {
#---------------------------------------------------------------
    # Return the distance squared between two points defined
    # by coordinates x0,y0 and x1,y1
    return [expr ($x1-$x0)*($x1-$x0)+($y1-$y0)*($y1-$y0)]
}

#---------------------------------------------------------------
proc dist { x0 y0 x1 y1 } {
#---------------------------------------------------------------
    # Return the distance between two points defined
    # by coordinates x0,y0 and x1,y1
    return [expr sqrt(($x1-$x0)*($x1-$x0)+($y1-$y0)*($y1-$y0))]
}

################################################################
# Handling fonts
################################################################

#---------------------------------------------------------------
proc render_apply_fonts { g c args } {
#---------------------------------------------------------------
    # Update fonts for nodes and edges
    # The "-scale" option specifies the scaling for the
    # font
    global dotgraph
    # Process arguments
    set scale_factor 100
    set n [llength $args]
    set i 0
    while { $i < $n } {
	set arg [lindex $args $i]
	switch -- $arg {
	    "-scale" {
		incr i
		set scale_factor [lindex $args $i]
	    }
	}
	incr i
    }
    # Set the scaling for fonts
    set scale_factor [expr $scale_factor / 100.0]
    # Loop over all nodes
    for { set i 0 } \
	{ $i < [llength $dotgraph([subst $g]_NODE_NAME)] } \
	{ incr i } {
	    set name [lindex $dotgraph([subst $g]_NODE_NAME) $i]
	    # Recover the label for this node
	    set label [$c find withtag "_dotgraph_label_$name"]
	    # Recover the font for this node
	    set font [lindex $dotgraph([subst $g]_NODE_FONT) $i]
	    if { $font != "" } {
		# Create a Tk font and scale it appropriately
		set tkfont [eval font create [font actual $font]]
		set fontsize [expr int([font configure $tkfont -size] * $scale_factor)]
		font configure $tkfont -size $fontsize
		# Apply the font
		$c itemconfigure $label -font $tkfont
	    }
	}
    # Loop over all connections
    for { set i 0 } \
	{ $i < [llength $dotgraph([subst $g]_EDGE_NAME)] } \
	{ incr i } {
	    set name [lindex $dotgraph([subst $g]_EDGE_NAME) $i]
	    # Recover the label for this edge
	    set label [$c find withtag "$name"]
	    # Recover the font for this egde
	    set font [lindex $dotgraph([subst $g]_EDGE_FONT) $i]
	    if { $font != "" } {
		# Create a Tk font and scale it appropriately
		set tkfont [eval font create [font actual $font]]
		set fontsize [expr int([font configure $tkfont -size] * $scale_factor)]
		font configure $tkfont -size $fontsize
		# Apply the font
		$c itemconfigure $label -font $font
	    }
	}
    # Finished with bindings
    return
}

################################################################
# Handling bindings
################################################################

#---------------------------------------------------------------
proc render_apply_bindings { g c } {
#---------------------------------------------------------------
    # Apply any binding sequences that have been set
    # for this dotgraph
    global dotgraph
    # Loop over all nodes
    for { set i 0 } \
	{ $i < [llength $dotgraph([subst $g]_NODE_NAME)] } \
	{ incr i } {
	    set name [lindex $dotgraph([subst $g]_NODE_NAME) $i]
	    ##puts "Apply bindings for node \"$name\""
	    # Recover the bindings for this node
	    set bindings [lindex $dotgraph([subst $g]_NODE_BINDINGS) $i]
	    foreach binding $bindings {
		# Apply each binding
		set sequence [lindex $binding 0]
		set cmd [lindex $binding 1]
		##puts "\tBinding: $sequence to command \"$cmd\""
		$c bind $name "$sequence" "$cmd"
	    }
	}
    # Loop over all connections
    for { set i 0 } \
	{ $i < [llength $dotgraph([subst $g]_EDGE_NAME)] } \
	{ incr i } {
	    set name [lindex $dotgraph([subst $g]_EDGE_NAME) $i]
	    ##puts "Apply bindings for connection \"$name\""
	    # Recover the bindings for this connection
	    set bindings [lindex $dotgraph([subst $g]_EDGE_BINDINGS) $i]
	    foreach binding $bindings {
		# Apply each binding
		set sequence [lindex $binding 0]
		set cmd [lindex $binding 1]
		##puts "\tBinding: $sequence to command \"$cmd\""
		$c bind $name "$sequence" "$cmd"
	    }
	}
    # Finished with bindings
    return
}

################################################################
# Escape newlines in label text
################################################################

#---------------------------------------------------------------
proc escape_newlines { text } {
#---------------------------------------------------------------
    regsub -all -- "\n" "$text" "\\n" new_text
    return $new_text
}
