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
# MapSlicer v2.1
#
# Program to display contoured sections from CCP4 map files
#
# Original version: Peter Briggs Oct 2000
# Updated Nov 2001: accomodate major revision of ccp4mapwish
# Updated Apr 2002: major rewrite of user interface
#
# For Tcl/Tk versions 8.0 and mapwish version 2.1
#---------------------------------------------------------------------

# Initialisations - globals taken from loggraph
global env
global system
global typedef
global configure
global data
global stuff

# Mapslicer specific preferences
global mapslicer

# CCP4I interface setup
# This should give us access to the CCP4I functions

  source [SearchPath TOP src utils.tcl]
  source [SearchPath TOP src window.tcl]
  source [SearchPath TOP src exframe.tcl]
  source [SearchPath TOP src varmenu.tcl]
  source [SearchPath TOP src fileselect.tcl]
  source [SearchPath TOP src fileviewer.tcl]
  source [SearchPath TOP src util_windows.tcl]
  source [SearchPath TOP src local.tcl]
  source [SearchPath TOP src projectdirs.tcl]
  source [SearchPath TOP etc types.def]

  # Addition procedures for MapSlicer
  source [SearchPath TOP mapslicer mapslicer_utils.tcl]
  source [SearchPath TOP mapslicer mapslicer_section.tcl]
  source [SearchPath TOP mapslicer mapslicer_contours.tcl]
  source [SearchPath TOP mapslicer mapslicer_info.tcl]
  source [SearchPath TOP mapslicer mapslicer_print.tcl]
  source [SearchPath TOP mapslicer mapslicer_zoom.tcl]
  source [SearchPath TOP mapslicer mapslicer_command.tcl]

  # Need this for the Harker sections
  source [SearchPath TOP src CCP4_utils.tcl]
  # Read the crystal parameters files
  ReadSymops [FileJoin [GetEnvPath CLIBD] symop.lib]
  ReadCrystalData [SearchPath TOP etc crystal.lib]

  #Get user preferences - may be needed for file_select window
  InitialisePreferences preferences preferences
  InitialiseDirectories
  InitialisePreferences status ccp4i_status

  #Look for mapslicer preferences
  InitialisePreferences mapslicer mapslicer

################
# PROCEDURES
################

#--------------------------------------------------------------------
# Create the main window
#
# This sets up the frames, buttons and menus
# Also initialises the canvas for contouring
#--------------------------------------------------------------------
proc create_main_win { } {
#--------------------------------------------------------------------
    global configure

    wm withdraw .
    wm title . "CCP4Interface MapSlicer"
    wm iconbitmap . @[SearchPath TOP icons window_icon]

    # Frames
    set fdisp [frame .f1]
    set fbutt [frame .f2 -background $configure(COLOUR_CONTRAST) ]
    set fcomm [frame $fdisp.f3]
    set fcont [frame $fdisp.f4]

    # Pack from the top down, so that the buttons disappear last
    pack $fbutt -side top -fill x
    pack $fdisp -side top -fill x
    pack $fcomm $fcont -side left

    #############################################################
    # Canvas
    #############################################################
    set contours [canvas $fcont.c -background white -cursor crosshair]
    pack $contours -side top

    # Canvas bindings
    # PJX I am unable to find how to bind the canvas to keypress
    # events, for example these:
    ##bind $contours <KeyPress-Up> {incr_section 1 [get_value AXIS ]}
    ##bind $contours <KeyPress-Down> {incr_section -1 [get_value AXIS] }
    # don't seem to work.

    #############################################################
    # Command display
    #############################################################
    create_command_display $fcomm

    #############################################################
    # Buttons and menu bar
    #############################################################

    # File menu
    set bfile [ menubutton $fbutt.file -text "File" \
	    -background $configure(COLOUR_CONTRAST) \
	    -menu $fbutt.file.menu]
    set filemenu [ menu $bfile.menu -tearoff 0 ]
    $filemenu add command -label "Open new map file" -command { open_file }
    $filemenu add command -label "Save section" -command { save_section }
    $filemenu add command -label "Print" -command { print_section }
    $filemenu add command -label "Exit" -command { exit_mapslicer }

    # Change section
    set bsect [ menubutton $fbutt.sect -text "Section" \
	    -background $configure(COLOUR_CONTRAST) \
	    -menu $fbutt.sect.menu ]
    set sectmenu [ menu $bsect.menu -tearoff 0 ]
    $sectmenu add command -label "Section..." -command {customise_section}
    $sectmenu add command -label "Contours..." -command {customise_contours}

    # Information: display information about the map, section, contours etc
    set binfo [ menubutton $fbutt.info -text "Info" \
	    -background $configure(COLOUR_CONTRAST) \
	    -menu $fbutt.info.menu ]
    set infomenu [menu $binfo.menu -tearoff 0 ]
    $infomenu add command -label "About map..." -command {display_map_info}
    $infomenu add command -label "About section..." -command {display_section_info}
    $infomenu add command -label "About MapSlicer..." -command {display_mapslicer_info}

    # Pack the buttons
    pack $bfile $bsect $binfo -side left

    #############################################################
    # Cursor feedback etc
    #############################################################
    set finfo [frame $fcont.f]
    pack $finfo -side top -anchor w -expand 1
    set infocoords [label $finfo.coords -text "" -width 18 -anchor w]
    set infodensity [label $finfo.density -text "" -width 20 -anchor w]
    pack $infocoords -side left
    pack $infodensity -side left

    # Store the command panel path
    set_value WIDGET_COMMAND $fcomm

    # Store the canvas path to use later on
    set_value CANVAR $contours

    # Store the cursor feedback paths too
    set_value WIDGET_INFO_COORDS $infocoords
    set_value WIDGET_INFO_DENSITY $infodensity

    # Expand the window
    wm deiconify .
}

#--------------------------------------------------------------------
# Exit procedure
#
# Put any operations that need to be performed before closing the
# application, into this procedure
#--------------------------------------------------------------------
proc exit_mapslicer { } {
#--------------------------------------------------------------------
    global mapslicer

    # Copy the preferences to the mapslicer array
    # before saving
    set mapslicer(CONTOUR_MIN) [get_value CONTOUR_MIN]
    set mapslicer(CONTOUR_MAX) [get_value CONTOUR_MAX]
    set mapslicer(CONTOUR_INTERVAL) [get_value CONTOUR_INTERVAL]
    set mapslicer(VIEW_ORIENTATION) [get_value VIEW_ORIENTATION]
    set mapslicer(CONTOUR_LINE_WIDTH) [get_value CONTOUR_LINE_WIDTH]
    set mapslicer(GRID_ON) [get_value GRID_ON]
    set mapslicer(GRID_X_SPACING) [get_value GRID_X_SPACING]
    set mapslicer(GRID_Y_SPACING) [get_value GRID_Y_SPACING]
    set mapslicer(GRID_LABEL_PREC) [get_value GRID_LABEL_PREC]

    SavePreferences mapslicer mapslicer
    exit
}

#--------------------------------------------------------------------
# Create the command display bar
#
# This sets up the interactive display/control bar on the lhs of
# the main window
#--------------------------------------------------------------------
proc create_command_display { f } {
#--------------------------------------------------------------------

  # f is the hull frame
  # Create sub frames for each of the commands

  #############################################################
  # Mode
  #############################################################
  set modef [frame $f.mode -highlightthickness 1]
  set model [label $modef.l -text "Mode:"]
  set modeb [menubutton $modef.b -text "section" -menu $modef.b.menu \
	  -relief raised -width 10 -indicatoron 1]
  set modemenu [menu $modef.b.menu -tearoff 0]
  # Mode menu: select mode and change to it
  $modemenu add command -label "section" -command "mapslicer_mode section"
  $modemenu add command -label "slab" -command "mapslicer_mode slab"
  $modemenu add command -label "harker" -command "mapslicer_mode harker"
  $modemenu add command -label "mask" -command "mapslicer_mode mask"
  pack $model $modeb -side left

  #############################################################
  # Axis
  #############################################################
  set axisf [frame $f.axis -highlightthickness 1]
  set axisl [label $axisf.l -text "Axis:"]
  set axisb [menubutton $axisf.b -text "z" -menu $axisf.b.menu \
	  -relief raised -width 3 -indicatoron 1]
  set axismenu [menu $axisf.b.menu -tearoff 0]
  # Axis menu: select an axis and change to it
  $axismenu add command -label "x" -command "change_axis_command $axisb x"
  $axismenu add command -label "y" -command "change_axis_command $axisb y"
  $axismenu add command -label "z" -command "change_axis_command $axisb z"
  pack $axisl $axisb -side left

  #############################################################
  # Greyscale
  #############################################################
  set greyf [frame $f.grey -highlightthickness 1]
  set greyc [checkbutton $greyf.c \
		 -command "change_greyscale_command $greyf.c" \
		 -variable greyscale_status]
  set greyl [label $greyf.l -text "Show greyscale view"]
  pack $greyc $greyl -side left

  #############################################################
  # Section
  #############################################################
  set sectionf [frame $f.section -highlightthickness 1]
  set sectionlabel [label $sectionf.l -text "Section:"]
  set sectionentry [entry $sectionf.e -width 4]
  # Set up the binding for the entry widget
  bind $sectionentry <Return> "jump_to_section_command $sectionentry"
  # Put in an initial value
  $sectionentry insert 0 [get_value SECTION]
  # Up and down
  set sectionbuttons [frame $sectionf.buttons]
  set sectionup [button $sectionbuttons.up \
	  -bitmap @[SearchPath TOP icons mapslicer_up.xbm] \
	  -command "next_section_command $sectionentry" \
	  -borderwidth 0]
  set sectiondown [button $sectionbuttons.down \
	  -bitmap @[SearchPath TOP icons mapslicer_down.xbm] \
	  -command "prev_section_command $sectionentry" \
	  -borderwidth 0]
  pack $sectionlabel $sectionentry $sectionbuttons -side left
  pack $sectionup $sectiondown -side top

  #############################################################
  # Slab
  #############################################################
  set slabf [frame $f.slab -highlightthickness 1]
  set slabf1 [frame $slabf.f1]
  set slabf2 [frame $slabf.f2]
  set slabl1 [label $slabf1.l1 -text "Slab start:"]
  set slabe2 [entry $slabf1.e2 -width 4]
  set slabl3 [label $slabf2.l3 -text "Depth:"]
  set slabe4 [entry $slabf2.e4 -width 3]
  set slabl5 [label $slabf2.l5 -text "Step:"]
  set slabe6 [entry $slabf2.e6 -width 3]
  # Up and down
  set slabbuttons [frame $slabf1.buttons]
  set slabup [button $slabbuttons.up \
	  -bitmap @[SearchPath TOP icons mapslicer_up.xbm] \
	  -command "next_slab_command $slabe2 $slabe4 $slabe6" \
	  -borderwidth 0]
  set slabdown [button $slabbuttons.down \
	  -bitmap @[SearchPath TOP icons mapslicer_down.xbm] \
	  -command "prev_slab_command $slabe2 $slabe4 $slabe6" \
	  -borderwidth 0]
  # Set up the bindings for the entry widgets
  bind $slabe2 <Return> "jump_to_slab_command $slabe2 $slabe4 $slabe6"
  bind $slabe4 <Return> "jump_to_slab_command $slabe2 $slabe4 $slabe6"
  bind $slabe6 <Return> "jump_to_slab_command $slabe2 $slabe4 $slabe6"
  bind $slabe6 <FocusOut> "jump_to_slab_command $slabe2 $slabe4 $slabe6"
  # Set some initial values for the entry widgets
  $slabe2 insert 0 [get_value START_SLAB]
  $slabe4 insert 0 [expr [get_value END_SLAB] - [get_value START_SLAB]]
  $slabe6 insert 0 [get_value SLAB_STEP]
  # Pack everything
  pack $slabl1 $slabe2 $slabbuttons -side left
  pack $slabl3 $slabe4 $slabl5 $slabe6 -side left
  pack $slabf1 $slabf2 -side top
  pack $slabup $slabdown -side top

  #############################################################
  # Harker sections
  #############################################################
  set harkerf [frame $f.harker -highlightthickness 1]
  set harkerf1 [frame $harkerf.f1]
  set harkerf2 [frame $harkerf.f2]
  set harkerl1 [label $harkerf1.l1 -text "Spacegroup"]
  set harkere2 [entry $harkerf1.e2 -width 5]
  set harkerb [menubutton $harkerf2.b -text "None" -menu $harkerf2.b.menu \
	  -relief raised -width 15 -indicatoron 1]
  set harkermenu [menu $harkerf2.b.menu -tearoff 0]
  # Harker menu: initially empty
  $harkermenu add command -label "None"
  # Set up the bindings for the entry widget
  bind $harkere2 <Return> "set_harker_command $harkere2 $harkerb $harkermenu"
  # Pack everything
  pack $harkerl1 $harkere2 -side left
  pack $harkerb -side left
  pack $harkerf1 $harkerf2 -side top

  #############################################################
  # Scale
  #############################################################
  set scalef [frame $f.scale -highlightthickness 1]
  set scalel [label $scalef.l -text "Scale:"]
  set scalee [entry $scalef.e -width 5]
  # Put in an initial value
  $scalee insert 0 [get_value SCALE]
  set scalem [menubutton $scalef.b -text [get_value SCALE_UNITS] -menu $scalef.b.menu \
	  -relief raised -width 8 -indicatoron 1]
  set scalemenu [menu $scalef.b.menu -tearoff 0]
  # Set the binding for the entry widget
  bind $scalee <Return> "change_scale_command $scalee"
  # Scale units menu: pixels or mm
  $scalemenu add command -label "pixels" \
	  -command "change_scale_units_command $scalem pixels"
  $scalemenu add command -label "mm" \
	  -command "change_scale_units_command $scalem mm"
  pack $scalel $scalee $scalem -side left

  #############################################################
  # Extra buttons
  #############################################################
  set extraf [frame $f.extra -highlightthickness 1]
  # Autoscale
  set autof [frame $extraf.auto]
  set autobutton [button $autof.b -text "AutoScale" -command "auto_scale" \
	  -width 20]
  pack $autobutton
  # Reset from last zoom
  set undof [frame $extraf.undo]
  set undobutton [button $undof.b -text "Undo Zoom" -command "undo_zoom" \
	  -width 20]
  pack $undobutton
  # Pack everything
  pack $autof $undof -side top

  # Pack frames
  pack $modef $axisf $sectionf $greyf $scalef $extraf \
      -side top -anchor nw -fill x

  # Store the widget names for updates later
  set_value WIDGET_MODE_BUTTON $modeb
  set_value WIDGET_AXIS $axisb
  set_value WIDGET_SECTION $sectionentry
  set_value WIDGET_SLAB_START $slabe2
  set_value WIDGET_SLAB_DEPTH $slabe4
  set_value WIDGET_SLAB_STEP $slabe6
  set_value WIDGET_HARKER_SPACEGROUP $harkere2
  set_value WIDGET_HARKER_SECTION $harkerb
  set_value WIDGET_HARKER_MENU $harkermenu
  set_value WIDGET_SCALE $scalee
  set_value WIDGET_SCALE_UNITS $scalem
  set_value WIDGET_UNDO_ZOOM $undobutton

}

#--------------------------------------------------------------------
# Initialise mapslicer variables
#
# Many of these should be reset when a map is read in
#--------------------------------------------------------------------
proc mapslicer_initialise { } {
#--------------------------------------------------------------------

    # Preferences for mapslicer
    global mapslicer

    # Get the loadable module with the commands
    # FIXME Comment this out if you're not using the loadable
    # module
    #puts stdout "About to load the ccp4map package"
    #load [file join [GetEnvPath MAPSLICER_TOP] ccp4map.so] ccp4map
    #puts stdout "ccp4map package loaded"
    # Loadable module currently broken for g77/gcc...

    # Make the window non-resizable by the user
    wm resizable . 0 0

    # Ask the window manager for the screen size
    # This will set the maximum size used in estimates later
    # when redrawing the window
    set maxsize [wm maxsize .]
    if {[llength $maxsize]==2} {
	set_value MAX_WIDTH  [lindex $maxsize 0]
	set_value MAX_HEIGHT [lindex $maxsize 1]
    } else {
	set_value MAX_WIDTH  -1
	set_value MAX_HEIGHT -1
    }

    # Default display mode
    set_value MAPSLICER_MODE "SECTION"

    # Default view orientation
    set_value VIEW_ORIENTATION $mapslicer(VIEW_ORIENTATION)

    # Default contour and grid line widths
    set_value CONTOUR_LINE_WIDTH $mapslicer(CONTOUR_LINE_WIDTH)
    set_value GRID_LINE_WIDTH    $mapslicer(GRID_LINE_WIDTH)

    # Internal parameters
    set_value USE_FRAC  1

    # Set the defaults for the section
    set_value MAPFILE          ""
    set_value SECTION          0
    set_value FRAC_SECTION     0.0
    set_value AXIS             "z"

    # Set the slab defaults
    set_value SLAB_ON          0
    set_value START_SLAB       [get_value SECTION]
    set_value START_FRAC_SLAB  [get_value FRAC_SECTION]
    set_value END_SLAB         [get_value SECTION]
    set_value END_FRAC_SLAB    [get_value FRAC_SECTION]
    set_value SLAB_STEP        1
    set_value SLAB_FRAC_STEP   [get_frac_from_grid [get_value SLAB_STEP] \
	    [get_value AXIS]]

    # Set the defaults for contouring
    set_value CONTOUR_TYPE     "sigma"
    set_value CONTOUR_LEVELS   "range"
    set_value CONTOUR_MIN      "1.0"
    set_value CONTOUR_MAX      "10.0"
    set_value CONTOUR_INTERVAL "1.0"
    set_value CONTOUR_MIN      $mapslicer(CONTOUR_MIN)
    set_value CONTOUR_MAX      $mapslicer(CONTOUR_MAX)
    set_value CONTOUR_INTERVAL $mapslicer(CONTOUR_INTERVAL)
    set_value NCONTOURS        "5"
    set ncontours [get_value NCONTOURS]
    for {set i 0} {$i<$ncontours} {incr i} {
	set_value CONTOUR_$i $i
    }
    set_value CONTOUR_NEG      "no"
    set_value CONTOUR_OFFSET   "no"
    set_value NO_NEGATIVE_DENSITY 0

    # Greyscaling
    set_value GREYSCALE        0

    # Parameters for the gridding
    set_value GRID_ON         $mapslicer(GRID_ON)
    set_value GRID_X_SPACING  $mapslicer(GRID_X_SPACING)
    set_value GRID_Y_SPACING  $mapslicer(GRID_Y_SPACING)
    set_value GRID_LABEL_PREC $mapslicer(GRID_LABEL_PREC)
    set_value GRID_LIMIT_XMIN "0.0"
    set_value GRID_LIMIT_YMIN "0.0"
    set_value GRID_LIMIT_XMAX "1.0"
    set_value GRID_LIMIT_YMAX "1.0"
    
    # Harker Sections
    set_value HARKER_SPACEGROUP 1
    set_value HARKER_NSECTIONS  0

    # Printing
    set_value PRINT_DEVICE "file"
    set_value PRINT_UNITS  "mm"
    set_value PRINT_SCALE  "2.5"
    set_value PRINT_ORIENT "portrait"
    set_value PRINT_CMD    {}

    # Miscellaneous
    set_value ORTHCODE  1
    set_value USE_WHOLE_SECTION 1

    # Set the defaults for scaling (mm/per Angstrom)
    set_value SCALE       2
    set_value SCALE_UNITS "mm"

    # Zoom
    set_value ZOOM_STACK  ""
    set_value ZOOM_ON     0
    set_value ZOOM_X      0
    set_value ZOOM_Y      0
    
    return
}

#---------------------------------------------------------------------------
# Open file
#
# Uses the file browser from CCP4i
#---------------------------------------------------------------------------
proc open_file { { format {} } { file {}}  } {
#---------------------------------------------------------------------------
    global stuff

    set status [SelectFile file "Map file" -filter "*.map"]
    
    # NB file exists will be successful even if the "file" is actually
    # a directory
    if { [file exists [lindex $file 0] ] && [file isfile [lindex $file 0]] } {
	new_map [lindex $file 0]
    }
    
    return 1
}

#--------------------------------------------------------------------
# Read in a new map
#
# Called each time a map is read into memory
#--------------------------------------------------------------------
proc new_map { mapfile } {
#--------------------------------------------------------------------

    # Check: does the map file exist?
    # NB: open_file should prevents this happening
    if ![file exists $mapfile] {
	WarningMessage "Warning: could not find $mapfile"
	return 1
    }
    if ![file isfile $mapfile] {
	WarningMessage "Warning: $mapfile is not a file"
	return 1
    }
 
    # Check: is a map already loaded?
    # If so then must delete it from memory first
    if { [mapinfo map1] == 1 } {
	# Undo any mouse motion binding for the canvas first
	set canvas_name [get_value CANVAR]
	bind $canvas_name <Motion> ""
	# Then delete the section associated with it
	if { [section s1 exists] } {
	    section s1 delete
	}
	# Now delete the map
	deletemap map1
    }
    
    # Read in the map
    readmap map1 $mapfile
    if { [mapinfo map1] != 1 }  {
	WarningMessage "Warning: could not load $mapfile"
	return 1
    }
    
    # Initialise the values from the map
    set_value NEW_MAP 1
    set_value AXIS z
    set limits [mapinfo map1 limits]
    set_value SECTION [string trim [lindex $limits 4]]
    set_value FRAC_SECTION [get_frac_from_grid [get_value SECTION] [get_value AXIS]]
    set_value USE_WHOLE_SECTION 1
    set_value MAPFILE $mapfile
    set_value MAP_SPACEGROUP [mapinfo map1 spacegroup]
    set_value HARKER_SPACEGROUP [string trim [get_value MAP_SPACEGROUP]]

    # If it's a mask then flip into mask mode automatically
    if { [mapinfo map1 type] == "mask" } {
	mapslicer_mode mask
    } elseif { [get_value MAPSLICER_MODE]=="MASK" } {
	# Switch out of mask mode for non-mask file
	mapslicer_mode section
    }

    # Start and end of slab
    set_value START_SLAB [get_value SECTION]
    set_value END_SLAB [get_value SECTION]

    # Is there negative density in the map?
    if { [mapinfo map1 minimum]<0.0 } {
	set_value NO_NEGATIVE_DENSITY 0
    } else {
	set_value NO_NEGATIVE_DENSITY 1
    }
    
    # First section and contours
    incr_section 0 [get_value AXIS]
    return
}

#--------------------------------------------------------------------
# Change section
#
# This steps i sections along the current axis, where i can be a
# +ve, -ve or zero integer. 
#--------------------------------------------------------------------
proc incr_section { i axis } {
#--------------------------------------------------------------------
#
# Increment section number
#
# This stores and contours the (new) section after incrementing the
# variable storing the current section number

    # Is there a map in memory?
    if { [mapinfo map1] != 1 } {
	WarningMessage "No map currently loaded"
	return
    }

    set section_number [ get_value SECTION ]
    incr section_number $i

    # Get limits along the current axis
    set limits [get_limits_on_axis $axis]
    if { [llength $limits]==2 } {
	set start [lindex $limits 0]
	set stop  [lindex $limits 1]
    } else {
	WarningMessage "Error in incr_section:\ncouldnt get limits on axis $axis"
	return
    }

    # If limits are out of range then reset them
    # Make it so that we can cycle round
    if {$start>$section_number} {
	set section_number $stop
    } elseif {$stop<$section_number} {
	set section_number $start
    }

    # Read in and contour new section
    new_section $axis $section_number

    # Update the internal information
    set_value SECTION      $section_number
    set_value FRAC_SECTION [get_frac_from_grid $section_number $axis]
    set_value AXIS         $axis

    # Update the information window
    update_command_display

    return
}

#--------------------------------------------------------------------
# Load new section
#
# This loads a new section (or slab, if the second argument is
# supplied) into memory, or updates an existing one
# then does the contouring by calling redraw_contours.
#--------------------------------------------------------------------
proc new_section { axis section { section1 {} } { step {} } } {
#--------------------------------------------------------------------

    # Cannot proceed unless there is a map in memory
    if { [mapinfo map1] != 1 } {
	WarningMessage "No map currently stored in memory"
	return 1
    }

    # Build the init or configure command
    set section_cmd [list "section" "s1"]

    # Is a section already stored?
    if { ![section s1 info exists] } {
	# Create a new section
	lappend section_cmd "init" "map1" $axis $section
    } else {
	# Update with new information
	lappend section_cmd "config" "-axis" $axis "-section" $section
    }

    # Is it a slab?
    if { $section1 != "" } {
	set_value SLAB_ON 1
	lappend section_cmd $section1
	if { $step != "" } { lappend section_cmd $step }
    } else {
	set_value SLAB_ON 0
    }

    # Execute the configuration command
    eval "$section_cmd"

    # Store the section limits
    set section_extent [section s1 info extent]
    if { [llength $section_extent]==4} {
	set_value SECTION_LIMIT_XMIN [lindex $section_extent 0]
	set_value SECTION_LIMIT_XMAX [lindex $section_extent 1]
	set_value SECTION_LIMIT_YMIN [lindex $section_extent 2]
	set_value SECTION_LIMIT_YMAX [lindex $section_extent 3]
    } else {
	WarningMessage "Warning: couldn't get section extent"
	set_value SECTION_LIMIT_XMIN 0
	set_value SECTION_LIMIT_XMAX 1000
	set_value SECTION_LIMIT_YMIN 0
	set_value SECTION_LIMIT_YMAX 1000
    }

    # (Re)draw the contours
    redraw_contours
}

#--------------------------------------------------------------------
# New contours
#
# This deletes any existing contours and then draws new
# contours for the currently stored section.
#
# It appears that the canvas doesn't automatically rescale to
# fit everything on. So this procedure also resets the canvas
# size appropriately (not always very successfully though).
#--------------------------------------------------------------------
proc redraw_contours { } {
#--------------------------------------------------------------------

    # Check that there is actually a section configured
    if { ![section s1 exists] } {
	return
    }

    # Fetch the canvas name
    set canvas_name [get_value CANVAR]

    # Reconfigure the section
    set section_cmd [list "section" "s1" "config"]
    
    # Grid display and gridding parameters
    set grid_on [ get_value GRID_ON ]
    set gridx [ get_value GRID_X_SPACING ]
    set gridy [ get_value GRID_Y_SPACING ]
    set prec  [ get_value GRID_LABEL_PREC ]
    lappend section_cmd "-grid" $grid_on "-gridspacing" $gridx $gridy "-precision" $prec

    # Set the axis labels
    if { [ get_value MAPSLICER_MODE ] == "HARKER" } {
	lappend section_cmd "-axislabels" "U" "V" "W"
    } else {
	lappend section_cmd "-axislabels" "X" "Y" "Z"
    }

    # Set the view orientation
    set view [ get_value VIEW_ORIENTATION ]
    lappend section_cmd "-view" $view

    #
    # Section limits
    set use_whole_section [ get_value USE_WHOLE_SECTION ]
    if {$use_whole_section==1} {
	set xlim0 [ string trim [ get_value SECTION_LIMIT_XMIN ] ]
	set ylim0 [ string trim [ get_value SECTION_LIMIT_YMIN ] ]
	set xlim1 [ string trim [ get_value SECTION_LIMIT_XMAX ] ]
	set ylim1 [ string trim [ get_value SECTION_LIMIT_YMAX ] ]
    } else {
	set xlim0 [ string trim [ get_value GRID_LIMIT_XMIN ] ]
	set ylim0 [ string trim [ get_value GRID_LIMIT_YMIN ] ]
	set xlim1 [ string trim [ get_value GRID_LIMIT_XMAX ] ]
	set ylim1 [ string trim [ get_value GRID_LIMIT_YMAX ] ]
    }
    lappend section_cmd "-limits" $xlim0 $xlim1 $ylim0 $ylim1

    eval "$section_cmd"

    # Set up the contour levels etc
    # FIXME can only cope with ranges at present
    set type [ get_value CONTOUR_TYPE ]
    set levels [ get_value CONTOUR_LEVELS ]

    # Build a command to set the contour levels
    set contour_cmd [list "section" "s1" "contours" "$type"]
    #
    if {$levels=="range"} {
	set min [ get_value CONTOUR_MIN ]
	set max [ get_value CONTOUR_MAX ]
	set interval [ get_value CONTOUR_INTERVAL ]
	lappend contour_cmd range $min $max $interval
	#
    } elseif {$levels=="list"} {
	lappend contour_cmd list
	set nlevels [ get_value NCONTOURS ]
	for { set i 0 } { $i<$nlevels } { incr i } {
	    lappend $contour_cmd [ get_value CONTOUR_$i ]
	}
	#
    } else {
	#puts stdout "Error in new_map: $levels is unrecognised"
	return
    }
    # Add negcontours if necessary
    if { [ get_value CONTOUR_NEG ]=="yes" } {
	lappend contour_cmd "-negcontours"
    }
    # Offset from the mean density?
    if { [ get_value CONTOUR_OFFSET ]=="yes" } {
	lappend contour_cmd "-meanoffset"
    }
    # Execute the command
    #puts stdout "$contour_cmd"
    eval "$contour_cmd"

    # Begin building the rendering command
    # Build it as a list
    set render_cmd [list "section" "s1" "render" "[get_value CANVAR]"]

    # Retrieve stored values
    #
    # Scale factor
    #
    set scale_units [ get_value SCALE_UNITS ]
    set scalefactor [ get_value SCALE ]
    #puts "scale_units = $scale_units"
    switch -exact -- $scale_units {
	"mm" { append scalefactor "m" }
    }
    lappend render_cmd "-scale" $scalefactor

    # In section mode greyscale view is also permissible
    if { [get_value MAPSLICER_MODE]=="SECTION" } {
	if { [get_value GREYSCALE] } {
	    lappend render_cmd "-greyscale"
	}
    }

    # Special options for mask mode
    if { [get_value MAPSLICER_MODE]=="MASK" } {
      lappend render_cmd "-nocontours" "-greyscale"
    }
    
    # Ask the user to wait
    PleaseWait "Drawing..."

    # Make the window temporarily resizable
    wm resizable . 1 1
    # Re-contour the section
    eval "$render_cmd"

    # Colour the bounding box & grid
    set grid_line_width [get_value GRID_LINE_WIDTH]
    eval $canvas_name itemconfigure bbox -fill "grey" -width $grid_line_width
    eval $canvas_name itemconfigure grid -fill "grey" -width $grid_line_width

    # Colour the contour levels
    if { [get_value GREYSCALE] && [get_value MAPSLICER_MODE]=="SECTION" } {
       eval $canvas_name itemconfigure "contours" -fill "cyan"
    } else {
       eval $canvas_name itemconfigure "contours" -fill "black"
    }       
    eval $canvas_name itemconfigure "negcontours" -fill "red"

    # Set the width of the contour lines
    set contour_line_width [get_value CONTOUR_LINE_WIDTH]
    eval $canvas_name itemconfigure "contours" -width $contour_line_width

    #set levels [section s1 contours]
    #puts "Levels = $levels"
    #set nlevels [llength $levels]
    #set i 0
    #foreach level $levels {
	#set tagid "level_$i"
	#puts "For level $level, tagid = $tagid, -fill = :[$canvas_name itemcget $tagid -fill]:"
	#if { $level < 0 } {
	    # Generate the name of the tag for this level
	    #eval $canvas_name itemconfigure $tagid -fill "red"
	#} else {
	    #eval $canvas_name itemconfigure $tagid -fill "black"
	#}
	#puts "... reset now to :[$canvas_name itemcget $tagid -fill]:"
	#incr i
    #}  

    # Stop waiting
    PleaseWait

    # Make the window non-resizable again
    #
    # Update idletasks needed to make sure that the window is
    # resized before it is prevented by the wm resizable command
    update idletasks
    wm resizable . 0 0

    # Bind the mouse motion in the canvas for cursor feedback
    bind $canvas_name <Motion> "display_cursor_coords %x %y $canvas_name ; zoom_drag %x %y $canvas_name"

    # Bind button-1 press and release for zoom start/stop
    bind $canvas_name <ButtonPress-1> "zoom_start %x %y $canvas_name"
    bind $canvas_name <ButtonRelease-1> "zoom_apply %x %y $canvas_name"

    # Update the display
    update_command_display

    return
}

#--------------------------------------------------------------------
# Update command display
#
# This updates the command  bar at the bottom of the window
# i.e. axis, section, scale
#--------------------------------------------------------------------
proc update_command_display { } {
#--------------------------------------------------------------------
   # Update the values displayed in the command side bar

   # Are we in slab mode?
   set slab        [get_value SLAB_ON]

   # Get the widget names
   set waxis [get_value WIDGET_AXIS]
   set wsection [get_value WIDGET_SECTION]
   set wslab_start [get_value WIDGET_SLAB_START]
   if { $slab } {
     set wslab_depth [get_value WIDGET_SLAB_DEPTH]
     set wslab_step  [get_value WIDGET_SLAB_STEP]
   }
   set wscale       [get_value WIDGET_SCALE]
   set wscale_units [get_value WIDGET_SCALE_UNITS]

   # Reset the widget values - entry widgets
   $wsection delete 0 end
   $wsection insert 0 [get_value SECTION]
   if { $slab } {
     $wslab_start delete 0 end
     $wslab_start insert 0 [get_value START_SLAB]
     $wslab_depth delete 0 end
     $wslab_depth insert 0 [expr [get_value END_SLAB] - [get_value START_SLAB] + 1]
     $wslab_step delete 0 end
     $wslab_step insert 0 [get_value SLAB_STEP]
   } else {
     $wslab_start delete 0 end
     $wslab_start insert 0 [get_value SECTION]
   }
   $wscale delete 0 end
   $wscale insert 0 [get_value SCALE]

   # Menubuttons
   $waxis configure -text [get_value AXIS]
   $wscale_units configure -text [get_value SCALE_UNITS]
}

#--------------------------------------------------------------------
# Update scale menu
#
# This updates the scale menu when the user changes the units
#--------------------------------------------------------------------
proc update_scale_menu { scalmenu new_units { old_units {} } } {
#--------------------------------------------------------------------

    # Generate a new list of shortcut values depending on the
    # new units
    switch -exact -- $new_units {
	"pixels" { set values [ list 2 4 6 8 10 15 25 ] }
	"mm" { set values [ list 1 2 3 4 5 6 7 ] }
	default { set values "" }
    }
    # Add entries to the menu representing these shortcuts
    set index 0
    foreach i $values {
	if { $old_units == "" } {
	    $scalmenu insert $index command -label "$i $new_units/A" \
		    -command "change_scale $i $new_units"
	} else {
	    $scalmenu entryconfigure $index -label "$i $new_units/A" \
		    -command "change_scale $i $new_units"
	}
	incr index
    }
}

#--------------------------------------------------------------------
# Display cursor coordinates and density
#
# This updates the info bar menu when the mouse moves in the section
#--------------------------------------------------------------------
proc display_cursor_coords { x y canvas_name } {
#--------------------------------------------------------------------

  # Get the paths for the elements in the information bar
  set infocoords  [get_value WIDGET_INFO_COORDS]
  set infodensity [get_value WIDGET_INFO_DENSITY]

  # Get the coordinate information from the section
  set coords [section s1 coords $canvas_name $x $y]

  set nargs [llength $coords]
  if { $nargs == 0 } {
      # No information to display
      $infocoords  configure -text ""
      $infodensity configure -text ""
      return
  }

  if { $nargs > 1 } {
      # Set the coordinates
      set orth_coords [lindex $coords 0]
      set frac_coords [lindex $coords 1]
      # Only display orth coordinates for now
      $infocoords configure -text "([change_precision [lindex $orth_coords 0] 2],[change_precision [lindex $orth_coords 1] 2])"
  }
  if { $nargs > 2 } {
      $infodensity configure -text "Density: [change_precision [lindex $coords 2] 2]"
  }
  return
}

#*************************************************************************
#  This is top level script - get things started after all the procedures
#  are defined
#*************************************************************************
mapslicer_initialise
wm withdraw .
create_main_win

# If there is a filename on the command line then open as
# a map...
if { $system(SCRIPT) != "" } {
   new_map $system(SCRIPT)
}
