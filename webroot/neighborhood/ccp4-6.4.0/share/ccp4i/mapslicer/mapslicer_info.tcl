#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
#---------------------------------------------------------------------
# mapslicer_info.tcl
#
# Procedures to display information for maps & sections etc in
# MapSlicer
#---------------------------------------------------------------------

#--------------------------------------------------------------------
# Display map information
#
# Brings up a window with the map information i.e. spacegroup etc
# currently stored in memory
#--------------------------------------------------------------------
proc display_map_info { } {
#--------------------------------------------------------------------
    # Must be global to display
    global info_text

    # Is there a map to display information about?
    if { [mapinfo map1]!=1 } {
	WarningMessage "No map currently loaded"
	return
    }

    # Set a variable to hold the text
    set info_text {}

    # Write the information
    append info_text "Current mapfile: " [get_value MAPFILE] \n \n
    append info_text "Map Title: \"" [mapinfo map1 title] "\"" \n \n
    append info_text "Map type: \"" [mapinfo map1 type] "\" (mode " [mapinfo map1 mode] ")" \n \n

    # Spacegroup
    append info_text "Spacegroup: " [get_value MAP_SPACEGROUP ] \n \n

    # Cell information
    append info_text "Cell: " \n
    set cellinfo [mapinfo map1 cell]
    if { [llength $cellinfo]!=6 } {
	append info_text " unknown" \n \n
    } else {
	append info_text \
		"   a = " [change_precision [lindex $cellinfo 0] 3] \
		"    b = " [change_precision [lindex $cellinfo 1] 3] \
		"    c = " [change_precision [lindex $cellinfo 2] 3] \n
	append info_text \
		"   alpha = " [change_precision [lindex $cellinfo 3] 1] \
		"   beta = "  [change_precision [lindex $cellinfo 4] 1] \
		"   gamma = " [change_precision [lindex $cellinfo 5] 1] \n \n
    }

    # Grid information
    append info_text "Number of grid units along whole cell edges:" \n
    set gridinfo [mapinfo map1 grid]
    if { [llength $gridinfo]!=3 } {
	append info_text " unknown" \n \n
    } else {
	append info_text \
		"   Nx = " [change_precision [lindex $gridinfo 0] -1] \
		"   Ny = " [change_precision [lindex $gridinfo 1] -1] \
		"   Nz = " [change_precision [lindex $gridinfo 2] -1] \n \n
    }

    # Limits of map
    append info_text "Extent of map:" \n
    set limitinfo [mapinfo map1 limits]
    if { [llength $limitinfo]!=6 } {
	append info_text " unknown" \n \n
    } else {
	set nu1  [change_precision [lindex $limitinfo 0] -1]
	set fnu1 [get_frac_from_grid $nu1 x]
	set nu2  [change_precision [lindex $limitinfo 1] -1]
	set fnu2 [get_frac_from_grid $nu2 x]
	set nv1  [change_precision [lindex $limitinfo 2] -1]
	set fnv1 [get_frac_from_grid $nv1 y]
	set nv2  [change_precision [lindex $limitinfo 3] -1]
	set fnv2 [get_frac_from_grid $nv2 y]
	set nw1  [change_precision [lindex $limitinfo 4] -1]
	set fnw1 [get_frac_from_grid $nw1 z]
	set nw2  [change_precision [lindex $limitinfo 5] -1]
	set fnw2 [get_frac_from_grid $nw2 z]
	append info_text "  nu = " $nu1 " - " $nu2 "  ( " $fnu1 " - " $fnu2 " ) " \n
	append info_text "  nv = " $nv1 " - " $nv2 "  ( " $fnv1 " - " $fnv2 " ) " \n
	append info_text "  nw = " $nw1 " - " $nw2 "  ( " $fnw1 " - " $fnw2 " ) " \n \n
    }

    # Density info
    append info_text "Density:" \n
    append info_text \
	    "  Maximum : " [mapinfo map1 maximum] \n \
	    "  Minimum : " [mapinfo map1 minimum] \n \
	    "     Mean : " [mapinfo map1 mean] \n \
	    "      Rms : " [mapinfo map1 rms] \n

    # Limits on axes

    # Opens  new window to display the text
    DisplayTextFile {} -textinput info_text -font FONT_FIXED \
                     -nomonitor -title "MapSlicer: Map Information"
}

#--------------------------------------------------------------------
# Display section information
#
# Brings up a window with information about the section
# currently stored in memory
#--------------------------------------------------------------------
proc display_section_info { } {
#--------------------------------------------------------------------
    # Must be global to display
    global info_text

    # Is there a section to display information about?
    if { ![section s1 info exists] } {
	WarningMessage "No section currently loaded"
	return
    }

    # Set a variable to hold the text
    set info_text {}

    # Get the information
    set waxis [section s1 config -axis]
    if {$waxis=="x"} {
	set uaxis "y"
	set vaxis "z"
    } elseif {$waxis=="y"} {
	set uaxis "z"
	set vaxis "x"
    } elseif {$waxis=="z"} {
	set uaxis "x"
	set vaxis "y"
    }
    set nsec [section s1 config -section]
    if { [llength $nsec] == 2 } {
	set is_slab 1
	set nsec1 [lindex $nsec 0]
	set nsec2 [lindex $nsec 1]
	set fsec1 [get_frac_from_grid $nsec1 $waxis]
	set fsec2 [get_frac_from_grid $nsec2 $waxis]
    } else {
	set is_slab 0
	set fsec [get_frac_from_grid $nsec $waxis] 
    }
    set display_limits [section s1 info extent]
    if {[llength $display_limits]!=4} {
	WarningMessage "Error: can't get limits of the section"
	return
    } else {
	set gridx0 [string trim [lindex $display_limits 0]]
	set gridx1 [string trim [lindex $display_limits 1]]
	set gridy0 [string trim [lindex $display_limits 2]]
	set gridy1 [string trim [lindex $display_limits 3]]
	set fracx0 [get_frac_from_grid $gridx0 $uaxis]
	set fracx1 [get_frac_from_grid $gridx1 $uaxis]
	set fracy0 [get_frac_from_grid $gridy0 $vaxis]
	set fracy1 [get_frac_from_grid $gridy1 $vaxis]
    }

    # Write the information
    if { $is_slab } {
	append info_text "Current slab is " $nsec1 " (" $fsec1 ") to " $nsec2 \
		" ( " $fsec2 ") on the " $waxis " axis" \n \n
    } else {
	append info_text "Current section is " $nsec " (" $fsec ") on the " \
		$waxis " axis" \n \n
    }
    append info_text "Section extents are " $gridx0 " - " $gridx1 \
	    " (" $fracx0 " - " $fracx1 ") along " $uaxis \n
    append info_text "                   " $gridy0 " - " $gridy1 \
	    " (" $fracy0 " - " $fracy1 ") along " $vaxis \n \n

    # Write information about contour levels

    # Number of contour levels
    set contour_levels [section s1 contours]
    set ncontours [llength $contour_levels]
    if { $ncontours > 0 } {
	append info_text $ncontours " contour levels are currently set:" \n \n
	append info_text " No.   Absolute value" \n " ---------------------------" \n
	# List of contour levels
	set i 0
	foreach level $contour_levels {
	    incr i
	    append info_text " " $i "     " [change_precision $level 2] \n
	}
    } else {
	append info_text "No contour levels are currently set" \n \n
    }

    # Limits on the grid
    if {[get_value USE_WHOLE_SECTION]==1} {
	append info_text \n "The entire section is displayed" \n
    } else {
	set frac_xmin [get_value GRID_LIMIT_XMIN]
	set frac_ymin [get_value GRID_LIMIT_YMIN]
	set frac_xmax [get_value GRID_LIMIT_XMAX]
	set frac_ymax [get_value GRID_LIMIT_YMAX]
	set grid_xmin [get_grid_from_frac $frac_xmin $uaxis]
	set grid_xmax [get_grid_from_frac $frac_xmax $uaxis]
	set grid_ymin [get_grid_from_frac $frac_ymin $vaxis]
	set grid_ymax [get_grid_from_frac $frac_ymax $vaxis]
	
	append info_text \n "The limits of the displayed section are set to:" \n
	append info_text "    n" $uaxis " : " $grid_xmin " - " $grid_xmax \
		"  (" $frac_xmin " - " $frac_xmax ")" \n
	append info_text "    n" $vaxis " : " $grid_ymin " - " $grid_ymax \
		"  (" $frac_ymin " - " $frac_ymax ")" \n
    }

    # Opens  new window to display the text
    DisplayTextFile {} -textinput info_text -font FONT_FIXED \
                     -nomonitor -title "MapSlicer: Section Information"
}


#--------------------------------------------------------------------
# Display MapSlicer information
#
# Bring up a hypertext viewer window which links to the MapSlicer
# documentation in CHTML
#--------------------------------------------------------------------
proc display_mapslicer_info { } {
    open_url "[file join [GetEnvPath CHTML] mapslicer.html]"
}
