#
#     Copyright (C) 2006-8
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4i database visualiser - viewer.tcl
#
# Usage: wish viewer.tcl
#
# Wanjuan Yang and Peter Briggs 2006-08
#
#====================================================================

#CCP4i_cvs_Id $Id: viewer.tcl,v 1.15 2008/09/19 10:47:53 pjx Exp $

######################################################################
#d_index_title CCP4i database visualiser 
#d_intro_title Client application for database handler
#d_intro This is an application which displays ccp4i job database(i.e. database.def file). It requires db handler running in order to access job database.

# source API
source [file join $env(DBCCP4I_TOP) ClientAPI dbClientAPI.tcl]
namespace import ::dbClientAPI::*

# get the full path of starKey.py
set starKey [file join $env(DBCCP4I_TOP) application starKey.py]

# Hide the Tk window
if { [lsearch -exact [package names] tk] >= -1 } {
    wm withdraw .
}
. configure -background "black"
#
#----------------------------------------------------------------
proc GetEnvPath { var } {
#----------------------------------------------------------------
  global system
  global env

  # Get environment variable - cope with whether input var has
  # leading '$' or not

  regsub {^\$} $var  {} var1

  # On NT change the separators to unix style /

  if { [regexp WINDOWS $system(OPSYS)] } {
    set status [catch { global env;
      regsub -all {\\} $env($var1) \/ path } nc ]
  } else {
    set status [catch {global env; set p1 $env($var1)} path ]
  }
  if { $status == 1 } {
    set path ""
    WarningMessage "Cannot get environment variable for $var"
  }
  return $path
}

# Source startup.tcl appropriate for operating system

set system(OPSYS) [string toupper $tcl_platform(platform)]
source [file join $env(CCP4I_TOP) bin $system(OPSYS) startup.tcl]

# Edit the RUN_MODE to be the name of the current application
set system(RUN_MODE)            dbviewer
set system(TK_VERSION)          $tk_version

source [file join $env(CCP4I_TOP) src system.tcl]
source [file join $env(CCP4I_TOP) src utils.tcl]
source [file join $env(CCP4I_TOP) src window.tcl]
source [file join $env(CCP4I_TOP) src database.tcl]
source [SearchPath TOP etc types.def]
source [SearchPath TOP src exframe.tcl]
source [SearchPath TOP src varmenu.tcl]
source [SearchPath TOP src fileselect.tcl]
source [SearchPath TOP src fileviewer.tcl]
source [SearchPath TOP src CCP4_utils.tcl]
source [SearchPath TOP src util_windows.tcl]
source [SearchPath TOP src local.tcl]
source [SearchPath TOP src taskwindow.tcl]
source [SearchPath TOP src runjob.tcl]
source [SearchPath TOP src plugins.tcl]
source [SearchPath TOP src job_utils.tcl]

# If there is an autoconfigure procedure for the system parameters
# and this opsys then run it
if { [llength [info proc autoconf_[subst $system(OPSYS)]_system]] > 0 } {
      autoconf_[subst $system(OPSYS)]_system system }

InitialiseDotCCP4
global configure

InitialisePreferences configure configure
InitialisePreferences preferences preferences
InitialisePreferences status ccp4i_status

# Show the Tk window
wm deiconify .


######################################################################
# Global parameters
######################################################################
#
# These are stored as elements in an array
set ccp4i_db_viz(USER_TITLE) {}
set ccp4i_db_viz(VERSION) 0.4.11
set ccp4i_db_viz(CANVAS) {}
set ccp4i_db_viz(INFO) {}
set ccp4i_db_viz(GRAPH) {}
set ccp4i_db_viz(JOB_LIST) {}
set ccp4i_db_viz(SELECTION) {}
set ccp4i_db_viz(PROJECT) {}
set ccp4i_db_viz(SUBJOB) {}
set ccp4i_db_viz(FINISHED_FILTER) 0
set ccp4i_db_viz(LINKED_FILTER) 0
set ccp4i_db_viz(CURRENT_XVIEW) 0
set ccp4i_db_viz(CURRENT_YVIEW) 0
set ccp4i_db_viz(REFRESH_INTERVAL) 2000
set ccp4i_db_viz(REFRESH) 0
set ccp4i_db_viz(LAST_CLICK_JOBID) 0
set ccp4i_db_viz(IGNORE_NEXT_CLICK) 0
set ccp4i_db_viz(SHADOWS) 1
set ccp4i_db_viz(RENDERING_ENGINE) "dot"
set ccp4i_db_viz(SQLDB) 0

#--------------------------------------------------------------------
proc dbviewer_initialise { } {
#---------------------------------------------------------------------
# initialise the dbviewer preferences
    global ccp4i_db_viz
    global dbviewer

    set ccp4i_db_viz(DIRECTION) $dbviewer(ORIENTATION)
    set ccp4i_db_viz(SHAPE) $dbviewer(SHAPE)
    set ccp4i_db_viz(COLOR) $dbviewer(COLOR)
    set ccp4i_db_viz(BACKGROUND) $dbviewer(BACKGROUND)
    set ccp4i_db_viz(FILLCOLOR) $dbviewer(FILLCOLOR)

    set ccp4i_db_viz(MAXWIDTH) $dbviewer(MAXWIDTH)
    set ccp4i_db_viz(MAXHEIGHT) $dbviewer(MAXHEIGHT)
    set ccp4i_db_viz(MINWIDTH) $dbviewer(MINWIDTH)
    set ccp4i_db_viz(MINHEIGHT) $dbviewer(MINHEIGHT)
    set ccp4i_db_viz(BORDER) $dbviewer(BORDER)
    set ccp4i_db_viz(SCALE) $dbviewer(SCALE)
    set ccp4i_db_viz(NODE_TASKNAME) $dbviewer(NODE_TASKNAME)
    set ccp4i_db_viz(NODE_TITLE) $dbviewer(NODE_TITLE)

    # Selection mechanism
    set ccp4i_db_viz(SELECTION_LIST) [list {}]
    set ccp4i_db_viz(SELECTION_POINTER) 0
}

#--------------------------------------------------------------------
proc dbviewer_set_title { user_title } {
#--------------------------------------------------------------------
# Set a title string to display on the viewer
    global ccp4i_db_viz
    set ccp4i_db_viz(USER_TITLE) $user_title
}

#--------------------------------------------------------------------
proc dbviewer_initialise_preferences { } {
#--------------------------------------------------------------------
# Load the preferences for the viewer
#
# Note: this procedure is a substitute for InitialisePreferences
# from the main CCP4i code.
# We have to use a local version as the template preferences file
# for the viewer is not in $CCP4I_TOP/... but in the dbccp4i area.
# This should be fixed to use InitialisePreferences again when
# dbccp4i is integrated with CCP4i.

    global dbviewer

    # Load the template preferences file
    # This is in $DBCCP4I_TOP/etc or equivalent
    set dist_dbviewer_def [file join [GetEnvPath DBCCP4I_TOP] \
			       etc dbviewer.def.dist]
    if { [file exists $dist_dbviewer_def] } {
	InitialiseArray $dist_dbviewer_def dbviewer dbviewer
    } else {
	# Can't find template preferences file
	return 0
    }

    # Load the user's preferences, if it exists
    set user_dbviewer_def [datapath dbviewer.def -username -domain]
    if { [file exists $user_dbviewer_def] } {
	InitialiseArray $user_dbviewer_def dbviewer dbviewer
    }
    return 1
}

#--------------------------------------------------------------------
proc save_preferences { }  {
#--------------------------------------------------------------------
# save dbviewer preferences to file
    global ccp4i_db_viz
    global dbviewer

    set dbviewer(CURRENT_PROJECT) $ccp4i_db_viz(PROJECT)

    set dbviewer(ORIENTATION) $ccp4i_db_viz(DIRECTION)
    set dbviewer(SHAPE) $ccp4i_db_viz(SHAPE)
    set dbviewer(COLOR) $ccp4i_db_viz(COLOR)
    set dbviewer(BACKGROUND) $ccp4i_db_viz(BACKGROUND)
    set dbviewer(FILLCOLOR) $ccp4i_db_viz(FILLCOLOR)

    set dbviewer(MAXWIDTH) $ccp4i_db_viz(MAXWIDTH)
    set dbviewer(MAXHEIGHT) $ccp4i_db_viz(MAXHEIGHT)
    set dbviewer(MINWIDTH) $ccp4i_db_viz(MINWIDTH)
    set dbviewer(MINHEIGHT) $ccp4i_db_viz(MINHEIGHT)
    set dbviewer(BORDER) $ccp4i_db_viz(BORDER)
    set dbviewer(SCALE) $ccp4i_db_viz(SCALE)
    set dbviewer(NODE_TITLE) $ccp4i_db_viz(NODE_TITLE)
    set dbviewer(NODE_TASKNAME) $ccp4i_db_viz(NODE_TASKNAME)

    SavePreferences dbviewer dbviewer
}

#--------------------------------------------------------------------
proc dbviewer_exit { } {
#-------------------------------------------------------------------
# Save the preferences and exit the viewer
    save_preferences
    # destroy the root window
    destroy .
    # disconnect from the handler
    DbHandlerDisconnect   
    # Exit the process
    exit
}

############################################################
# General display procedures
############################################################

#---------------------------------------------------------------
proc create_main_window { } {
#----------------------------------------------------------------
# This sets up the widgets for the main display
    global ccp4i_db_viz
    # "configure" is CCP4i's global configuration
    # array which contains font and colour information
    global configure
    # Need env for the environment variables
    global env
   
    # Set up the canvas, buttons etc
    set f  [frame .f]
    set f1 [frame $f.f1]

    #########################################
    # Canvas, scrollbars and information line
    #########################################
    set view [frame $f1.view]
    set c [canvas $view.c -background $ccp4i_db_viz(BACKGROUND)]
    set pad [frame $view.pad]
    set scrolly [scrollbar $view.scrolly -orient vertical -command "$c yview"]
    $c configure -yscrollcommand "$scrolly set"
    set scrollx [scrollbar $view.pad.scrollx -orient horizontal -command "$c xview"]
    $c configure -xscrollcommand "$scrollx set"
    set padsize [expr {[$view.scrolly cget -width] +2* \
			   ([$view.scrolly cget -bd ] + \
				[$view.scrolly cget -highlightthickness ])}]
    set padit [frame $view.pad.it -width $padsize -height $padsize]
    set info [label $view.info -text "Message line" \
		  -relief sunken -anchor w]

    pack $view.info -side bottom -fill x
    pack $view.pad -side bottom -fill x
    pack $view.pad.it -side right
    pack $view.pad.scrollx -side bottom -fill x
    pack $view.scrolly -side right -fill y
    pack $view.c -fill both -expand yes
    # Store the name of the canvas and info lines for later
    set ccp4i_db_viz(CANVAS) $c
    set ccp4i_db_viz(INFO) $info
    
    ###########
    # Menu bar
    ###########
    set fmbar [frame .fmbar -background $configure(COLOUR_CONTRAST)]

    #"File" menu
    set bfile [ menubutton $fmbar.file -text "File" \
		    -background $configure(COLOUR_CONTRAST) \
		    -menu $fmbar.file.menu]
    set filemenu [ menu $bfile.menu -tearoff 0 ]

    # add menu
    $filemenu add command -label "Output graph" -command "output_graph"
    $filemenu add command -label "Output Tracking XML" -command "output_xml_window"
    if { [bioxhit_db_exists] } {
	# Present option to interact with demo db
	$filemenu add command -label "Access demo SQLite db" -command "bioxhit_db"
    }
    $filemenu add command -label "Exit" -command  { dbviewer_exit } 
    
    pack $bfile -side left

    # "Project" menu
    set bproj [ menubutton $fmbar.project -text "Project" \
		    -background $configure(COLOUR_CONTRAST) \
		    -menu $fmbar.project.menu]
    set projectmenu [ menu $bproj.menu -tearoff 0 ]
    #get list of projects & populate the menu
    populate_projectmenu $projectmenu
    pack $bproj -side left

    # "Filter" menu
    set bfilter [menubutton $fmbar.filter -text "Filters" \
		   -background $configure(COLOUR_CONTRAST) \
		   -menu $fmbar.filter.menu]
    set filtermenu [ menu $bfilter.menu -tearoff 0 ]
    $filtermenu add checkbutton -variable ccp4i_db_viz(FINISHED_FILTER) \
                    -label "Show only finished jobs"  \
                    -command "display_job_db"

    $filtermenu add checkbutton -variable ccp4i_db_viz(LINKED_FILTER) \
                    -label "Show only linked jobs"  \
                    -command "display_job_db"

    pack $bfilter -side left

    # "Appearance" menu
    set bview [menubutton $fmbar.view -text "Appearance" \
		   -background $configure(COLOUR_CONTRAST) \
		   -menu $fmbar.view.menu]
    set viewmenu [ menu $bview.menu -tearoff 0 ]
   
    # Orientation
    $viewmenu add cascade -label "Graph direction.." -menu $viewmenu.direction
    menu $viewmenu.direction -tearoff 0
    add_radiobutton $viewmenu.direction DIRECTION TB "Top-to-bottom" { display_job_db }
    add_radiobutton $viewmenu.direction DIRECTION LR "Left-to-right" { display_job_db }
    add_radiobutton $viewmenu.direction DIRECTION BT "Bottom-to-top" { display_job_db }
    add_radiobutton $viewmenu.direction DIRECTION RL "Right-to-left" { display_job_db }
    
    # Build the menu for choosing the scale factor (percent scaling) 
    $viewmenu add cascade -label "Scale.." -menu $viewmenu.scale
    menu $viewmenu.scale -tearoff 0
    add_radiobutton $viewmenu.scale SCALE 150 "150%" { display_job_db }
    add_radiobutton $viewmenu.scale SCALE 125 "125%" { display_job_db }
    add_radiobutton $viewmenu.scale SCALE 100 "100%" { display_job_db }
    add_radiobutton $viewmenu.scale SCALE  75  "75%" { display_job_db }
    add_radiobutton $viewmenu.scale SCALE  50  "50%" { display_job_db }
    add_radiobutton $viewmenu.scale SCALE  25  "25%" { display_job_db }
 
    # Node shape 
    $viewmenu add cascade -label "Shape for job nodes.." -menu $viewmenu.shape
    menu $viewmenu.shape -tearoff 0
    add_radiobutton $viewmenu.shape SHAPE box     "Box"     { display_job_db }
    add_radiobutton $viewmenu.shape SHAPE ellipse "Ellipse" { display_job_db }
    add_radiobutton $viewmenu.shape SHAPE diamond "Diamond" { display_job_db }

    pack $bview -side left

    # "Data" menu
    set bdata [menubutton $fmbar.data -text "Data" \
		   -background $configure(COLOUR_CONTRAST) \
		   -menu $fmbar.data.menu]
    set datamenu [ menu $bdata.menu -tearoff 0 ]
    $datamenu add checkbutton -label "Show title" \
	-variable ccp4i_db_viz(NODE_TITLE) -command { display_job_db }
    $datamenu add checkbutton -label "Show taskname" \
	-variable ccp4i_db_viz(NODE_TASKNAME) -command { display_job_db }

    pack $bdata -side left
    
    ###########
    # Tool bar
    ###########
    set tbar [frame .tbar -background $configure(COLOUR_CONTRAST)]
    
    set back [button .tbar.back \
		  -bitmap @[file join $env(DBCCP4I_TOP) icons left_arrow.xbm] \
		  -command "prev_selection" \
                  -state disabled \
                  -activeforeground green \
                  -foreground darkgreen \
                  -disabledforeground darkgray ]

    set forward [button .tbar.forward \
		  -bitmap @[file join $env(DBCCP4I_TOP) icons right_arrow.xbm] \
		  -command "next_selection" \
                  -state disabled \
                  -activeforeground green \
                  -foreground darkgreen \
                  -disabledforeground darkgray ]

    # Make the "up" (back to parent project) button
    set up [button .tbar.up \
		  -bitmap @[file join $env(DBCCP4I_TOP) icons up_arrow.xbm] \
                  -activeforeground green \
                  -foreground darkgreen \
                  -disabledforeground darkgray ]

    # Make the "zoom-in" and "zoom-out" buttons
    set bzoomin [button .tbar.zoomin \
		     -bitmap @[file join $env(DBCCP4I_TOP) icons magnify-plus.xbm] \
		     -command "scale_job_display 10"]

    set bzoomout [button .tbar.zoomout \
		     -bitmap @[file join $env(DBCCP4I_TOP) icons magnify-minus.xbm] \
		     -command "scale_job_display -10"]

    # Buttons for viewing all jobs or just subsets
    set bview1 [button .tbar.view1 \
		    -bitmap @[file join $env(DBCCP4I_TOP) icons show-subset.xbm] \
		    -command "show_selected_jobs"]
    set bview2 [button .tbar.view2 \
		    -bitmap @[file join $env(DBCCP4I_TOP) icons show-all.xbm] \
		    -command "show_all_jobs"]

    # Button for refresh the view from the database
    set brefresh [button .tbar.refresh \
		      -bitmap @[file join $env(DBCCP4I_TOP) icons refresh.xbm] \
		      -foreground black \
		      -command "display_job_db"]

    # Exit button
    set bexit [button .tbar.exit -text "Exit" \
		   -command " dbviewer_exit "]

    # Add balloon help (tooltips) to the menu bar and tool bar items
    set_balloonhelp $back "Back to last selection"
    set_balloonhelp $forward "Forward to next selection"
    set_balloonhelp $up "View jobs in the parent project"

    set_balloonhelp $bfilter "Apply filters to the current view"
    set_balloonhelp $bview1 "Show only the selected jobs"
    set_balloonhelp $bview2 "Show all jobs"

    set_balloonhelp $bfile "File-related options for output"
    set_balloonhelp $bview "Configure the appearance of the\nnodes and the displayed data"
    set_balloonhelp $brefresh "Force the display to be updated\nfrom the database"
    set_balloonhelp $bproj "Select the project to be displayed"

    set_balloonhelp $bzoomin "Zoom in"
    set_balloonhelp $bzoomout "Zoom out"
    set_balloonhelp $bexit "Exit the program"
    
    # Pack the tool bar widgets
    pack $brefresh $back $forward $bzoomin $bzoomout $bfilter $bview1 $bview2 $bexit \
	-side left

    ###########################
    # Information message line
    ###########################
 
    # Pack everything so that it is visible
    pack $fmbar $tbar -side top -fill x
    pack $f -side top -fill both -expand yes
   
    pack $view -fill both -expand yes
    pack $f1 -side left -fill both -expand yes
  
    # Bind the canvas to scroll when clicked and dragged
    bind $c <ButtonPress-1> "drag_canvas_start $c %X %Y"
    bind $c <ButtonRelease-1> "drag_canvas_cancel $c"
    # Bind canvas resizing to centre the displayed graph
    bind $c <Configure> "centre_graph_in_view $c"

}

#----------------------------------------------------------------
proc populate_projectmenu { menu } {
#----------------------------------------------------------------
# This function get a list of projects from handler and populate to the project menu
    # delete menu list if it is not empty
    $menu delete 0 end
    # Maximum number of projects per column in the menu
    set maxcollen 30
    # Acquire project names
    set projects [lsort [ListProjects ]]
    set curr_col 0
    if { [llength $projects] > 0  } {
	foreach project $projects {
	    incr curr_col
	    if { $curr_col > $maxcollen } {
		set colbreak 1
		set curr_col 0
	    } else {
		set colbreak 0
	    }
	    add_radiobutton $menu SELECTEDPROJECT \
		$project "$project" "select_project_db $project" \
		-columnbreak $colbreak
	}
    } else { 
	$menu add command -label "No projects available"
    }
}


#----------------------------------------------------------------
proc scale_job_display { adjustment } {
#----------------------------------------------------------------
    # Adjusts the scaling of the display and then updates
    # The adjustmenu is the amount to change the scale factor by
    # and can be positive or negative
    global ccp4i_db_viz
    set ccp4i_db_viz(SCALE) [expr $ccp4i_db_viz(SCALE) + $adjustment]
    if { $ccp4i_db_viz(SCALE) <= 0 } {
	# Reset to 5
	set ccp4i_db_viz(SCALE) 5
    }
    display_job_db
}

#----------------------------------------------------------------
proc clear_job_display { c g } {
#----------------------------------------------------------------
    # Clears the current display ready for (re)rendering
    # c = the name of the canvas widget displaying the jobs
    # g = the name of the dotgraph holding the graph
    global ccp4i_db_viz

    # Store the current view position
    set ccp4i_db_viz(CURRENT_XVIEW) [lindex [$c xview] 0]
    set ccp4i_db_viz(CURRENT_YVIEW) [lindex [$c yview] 0]

    # Delete the canvas and the graph
    $c delete all
    if { [ dotgraph_exists $g ] } {
	dotgraph_delete $g
    }

    # Ensure that no bubbles are left behind onscreen
    bubblehelp_for_job_cancel
}

#----------------------------------------------------------------
proc get_job_colours { job_id fgVar bgVar} {
#----------------------------------------------------------------
    # Return the colours for the job depending on its status
    # fgVar and bgVar are the names of variables in the calling
    # procedure in which the foreground and background colours
    # respectively will be returned.
    # If the user has specified the use of custom job list
    # colours in CCP4i then these will be returned, otherwise
    # the "standard" dbviewer colours will be returned

    global configure

    # Associate local variables to pass back the results
    upvar $fgVar fg_colour
    upvar $bgVar bg_colour
  
    if { $configure(IFCOLOUR) } {
	# Use the user-defined colours specified in CCP4i
	set status [getdata $job_id STATUS]
	set taskname [getdata $job_id TASKNAME]
	set title [getdata $job_id TITLE]
	set colours [get_job_display_colours $taskname $status $title]
	set fg_colour [lindex $colours 0]
	set bg_colour [lindex $colours 1]
    } else {
	# Use the default viewer colours
	set fg_colour "black"
	switch [getdata $job_id STATUS] {
	    FINISHED { set bg_colour "\#9DD05B" }
	    FAILED   { set bg_colour "\#E7573B" }
	    KILLED   { set bg_colour "\#648DC7" }
	    RUNNING  { set bg_colour "\#FEF886" }
	    default  { set bg_colour gray }
	}
    }
    return
}

#---------------------------------------------------------------
proc output_graph { } {
#---------------------------------------------------------------
    global ccp4i_db_viz
    
    # if no graph loaded, give warning message
    if { $ccp4i_db_viz(GRAPH) == {} } {
	WarningMessage "No graph to print"
	return }

    # Open another window
    set w .anysection
    if ![OpenWindow $w "Print Graph" "Print" ] { return }

    # Make the frame and the cancel and apply buttons
    CreateFrame   $w output_graph
    CreateButton  $w dismiss "Cancel" "unset output_graph ; destroy $w"
    CreateButton  $w output  "Output" "apply_output_graph output_graph"

    # Define the menus used for this window
    DefineMenu _viewer_format [list "JPEG" "GIF" "Postscript" "PNG"] \
	[list "jpg" "gif" "ps" "png"]

    # Set parameters to change
    DefineVariable output_graph FORMAT _viewer_format "ps"
    DefineVariable output_graph OUTPUT_FILE   _any_file          ""
    DefineVariable output_graph DIR_OUTPUT_FILE   _default_dirs     ""

    # Draw the widgets in the window
    CreateLine line \
	label "Output graph to file as" \
	widget FORMAT
    CreateOutputFileLine line "Name of file to write to" \
	"Output file" \
	OUTPUT_FILE DIR_OUTPUT_FILE
    CloseFrame

}


#--------------------------------------------------------------------
proc apply_output_graph { outputVar } {
#--------------------------------------------------------------------
    upvar \#0 $outputVar output_graph 
   
    global ccp4i_db_viz
 
    # Get the format & file name
    set format [GetValue $outputVar FORMAT]
    set name [GetFullFileName0 $outputVar OUTPUT_FILE]

    if { [file exists $name ]} {
      
	set action [ ChooseOptionDialog "File Exists" "File Exists" \
			 "File exists: $name \nThis file will be overwritten. Do you want to continue or abort the output operation?" \
			 [list "Cancel" "Continue"]  \
			 -default 0 ]
	if {"$action"=="Cancel"} {
	    # Graph output cancelled
	    return
	}
    }
	
    if { ! [dotgraph_render_output $ccp4i_db_viz(GRAPH) $format $name \
	-using $ccp4i_db_viz(RENDERING_ENGINE)] } {
	WarningMessage "print file failed"
	return
    } else {
	# check the file create
	if { [file exists $name] } { 
	    WarningMessage "a file $name has been output"
	    destroy .anysection 
	} else {
	    WarningMessage "print file faied"
	    return
	}
    }
}

#--------------------------------------------------------------
proc output_xml_window { } {
#---------------------------------------------------------------
    # Display a window to allow the user to specify a file
    # to write tracking XML data to

    # Open a window
    set w .outputfile_entry
    if ![OpenWindow $w "Output XML" "Output"] { return }

    # Make the frame and the cancel and apply buttons
    CreateFrame $w output_xml
    CreateButton $w dismiss "Cancel" "unset output_xml; destroy $w"
    CreateButton $w apply "Output XML" "output_xml output_xml"

    # Set parameters to change
    DefineVariable output_xml OUTPUT_FILE _any_file ""
    DefineVariable output_xml DIR_OUTPUT_FILE _default_dirs ""

    # Draw the widgets in the window
    CreateLine line \
	label "Generate an XML file with information taken from the current view" \
	-italic
    CreateOutputFileLine line "Name of file to write to" \
	"XML file" \
	OUTPUT_FILE DIR_OUTPUT_FILE
    CloseFrame
       
}

#---------------------------------------------------------------
proc output_xml { outputfileVar } {
#---------------------------------------------------------------
    # Generate an XML tracking file by running the
    # starKey program
    upvar \#0 $outputfileVar outputfile
    global ccp4i_db_viz
    global starKey

    # Get filename
    set filen [GetFullFileName0 $outputfileVar OUTPUT_FILE]

    # check if exists
    if { [file exists $filen ] } {
	set action [ ChooseOptionDialog "File Exists" "File Exists" \
			 "File exists: $filen \nThis file will be overwritten. Do you want to continue or abort the output operation?" \
			 [list "Cancel" "Continue"] \
			 -default 0 ]
	if {"$action"=="Cancel"} {
	    destroy .outputfile_entry
	    return
	}
	# Delete the file
	file delete $filen
    }
  
    # do output
    set jobs $ccp4i_db_viz(JOB_LIST)

    PleaseWait "Writing XML file...may take a few moments"
    set starkeyCmd [list exec python "$starKey" "$filen" \
			$ccp4i_db_viz(PROJECT)]
    set starkeyCmd [concat $starkeyCmd $jobs]
    set status [catch { eval $starkeyCmd } result]
    PleaseWait

    if { $status } {
	# Caught an error
	WarningMessage "Failed to generate XML file:

$filen

Error message:

$result"
    } else {
	# No error from catch
	if { [file exists $filen] } {
	    # Give the user the opportunity to look at the
	    # file in a browser
	    set action [ ChooseOptionDialog "View XML" "View XML File" \
			     "Successfully created tracking XML file:

$filen

Do you want to view the file?" \
			     [list "Cancel" "View"] \
			     -default 0 ]
	    if {"$action"=="View"} {
		# Try to display the file in a web browser
		open_url $filen
	    }
	} else {
	    # StarKey ran but there's no output file?
	    WarningMessage "Failed to generate output XML file:

$filen

$result"
	}
    }
    # Remove the window
    destroy .outputfile_entry
    return
}

#-----------------------------------------------------------------
proc harvesting_analysis { project job } {
#-----------------------------------------------------------------
    # Run the reaper program to analyse the backtrace for the job
    global env
    global ccp4i_db_viz

    set reaperPy [file join $env(DBCCP4I_TOP) application reaper.py]
    set reaperCmd  [list exec python "$reaperPy" "$project" $job]

    PleaseWait "Analysing path to this job...may take a few moments"
    set status [catch { eval $reaperCmd } result]
    PleaseWait

    if { $status } {
	# Caught an error
	WarningMessage "Failed to perform analysis

Output from reaper program:
$result"
	return
    }
    # No error from catch - analyse the output from reaper
    set harvest_stages {}
    set line [ExtractFromText $result "Job\tHarvest stage" 2 all]
    while { $line != "" && [llength $line] > 1 } {
	lappend harvest_stages [list \
				    [lindex $line 0] \
				    [lrange $line 1 end]]
	set line [ExtractFromText - "" 1 all]
    }
    # Generate harvesting interface to show the results
    harvesting_window $project $job $harvest_stages
    # Update the display to select the path
    PleaseWait "Updating display.."
    set c $ccp4i_db_viz(CANVAS)
    clear_selection $c
    select_all_parents $c $job
    show_selected_jobs
    PleaseWait
}

#-----------------------------------------------------------------
proc harvesting_window { project initial_job harvest_stages } {
#-----------------------------------------------------------------
    # Generate a window and populate with the harvest results
    # from running reaper
    global configure
    
    # Open a window
    set w .harvesting
    if { [winfo exists $w] } { destroy $w }
    OpenWindow $w "Data Harvesting Analysis" "Data Harvesting"
    CreateFrame $w harvesting
    CreateButton $w dismiss "Dismiss" "unset harvesting ; destroy $w"

    # Preamble
    CreateLine line \
	label "Data harvesting analysis for path to job $initial_job in project" \
	label "$project" -italic

    # Loop over the harvest stages and create a folder
    # for each one
    foreach stage $harvest_stages {
	# Get information
	set job [lindex $stage 0]
	set title [lindex $stage 1]
	# Title bar for folder
	CreateLine line label "$title" -italic
	$line configure -background $configure(COLOUR_PALE) \
	    -relief ridge -borderwidth 1
	$line.l1 configure -background $configure(COLOUR_PALE) \
	    -width 50
	OpenSubFrame frame
	# Folder contents
	if { $job != "None" } {
	    # Basic data
	    set title [getdata $job TITLE]
	    set taskname [getdata $job TASKNAME]
	    set status [getdata $job STATUS]
	    set date [GetDate -format brief -clock [getdata $job DATE]]
	    # Files associated with the job
	    set logfile [file join [GetProjectDir $project] [getdata $job LOGFILE]]
	    set outputfiles [ListOutputFiles $project $job]
	    # Write data to the window
	    CreateLine line label "Job $job" \
		label "$taskname" -italic \
		label "$date $status"
	    CreateLine line \
		label "$title" -italic
	    CreateLine line \
		label "Logfile:" -italic label "$logfile"
	    CreateLine line label "Output files.." -italic
	    foreach filen $outputfiles {
		CreateLine line label "\t$filen"
	    }
	} else {
	    CreateLine line label "No job found"
	}
	CloseSubFrame
    }
    CloseFrame
}

#-----------------------------------------------------------------
proc update_application_title { { project "" } { subjob "" } } {
#-----------------------------------------------------------------
    # (Re)set the title in the application window title bar
    # "project" is the name of the current project, "subjob" is
    # text that will be displayed if the view is a set of subjobs
    # within the project
    global ccp4i_db_viz
    set title "CCP4Idbviewer $ccp4i_db_viz(VERSION)"
    if { $ccp4i_db_viz(USER_TITLE) != "" } {
	append title " $ccp4i_db_viz(USER_TITLE)"
    }
    if { $project != "" } {
	append title " Project: \"$project\""
	if { $subjob != "" } {
	    append title " Job: $subjob"
	}
    }
    wm title . $title
}

#-----------------------------------------------------------------
proc update_info { } {
#-----------------------------------------------------------------
    # Update the information displayed at the bottom of
    # the viewer window

    global ccp4i_db_viz

    # Build the line - start with the project name
    set text "Project: $ccp4i_db_viz(PROJECT)"

    # Add information on the subjob being viewed
    set subjob $ccp4i_db_viz(SUBJOB)
    if { $subjob != {} } {
	append text " Job $subjob"
    }
    
    # Add info on read-write mode
    set mode ""
    if { [ProjectReadable $ccp4i_db_viz(PROJECT)] && \
	     ![ProjectWriteable $ccp4i_db_viz(PROJECT)] } {
	append text " (readonly)"
    }
    
    # Information on the filter status

    # Filter only showing finished jobs
    append text "    Finished filter:"
    if { $ccp4i_db_viz(FINISHED_FILTER) == 1 } {
	append text " ON"
    } else {
	append text " OFF"
    }

    # Filter only showing linked jobs
    append text " Linked filter:"
    if { $ccp4i_db_viz(LINKED_FILTER) == 1 } {
	append text "ON"
    } else {
	append text "OFF"
    }

    # Update the information bar
    $ccp4i_db_viz(INFO) configure -text "$text"

    # Update the window title bar
    update_application_title $ccp4i_db_viz(PROJECT) $subjob
}

#----------------------------------------------------------------
proc display_message { message { c "" } } {
#----------------------------------------------------------------
    # Display a message directly on the canvas
    global ccp4i_db_viz
    global configure

    if { $c == "" } {
	set c $ccp4i_db_viz(CANVAS)
    }

    $c delete all

    $c create text 0 0 -text "$message" \
	-font $configure(L_FONT_ITALIC) \
	-justify center \
	-anchor nw -tags { message_text }
    set bbox [$c bbox message_text]
    set boxcoords [list \
		       [expr [lindex $bbox 0] - 10] \
		       [expr [lindex $bbox 1] - 10] \
		       [expr [lindex $bbox 2] + 10] \
		       [expr [lindex $bbox 3] + 10]]
		       
    eval $c create rectangle $boxcoords \
	-fill $configure(COLOUR_BACKGROUND) -outline \{\} -tags { message_box }
    $c raise message_text message_box
    # Reset the maximum scrollable region
    set bbox [$c bbox all]
    $c configure -scrollregion $bbox
    centre_graph_in_view $c
}

#----------------------------------------------------------------
proc centre_graph_in_view { c } {
#----------------------------------------------------------------
    # If the graph is smaller than the viewing area
    # in either the x or y (or both) directions, then
    # attempt to centre it in the view
    set bbox [$c bbox all]
    if { [llength $bbox] != 4 } { return }
    # Get dimensions and location of graph
    set graph_x [lindex $bbox 0]
    set graph_y [lindex $bbox 1]
    set graph_height [expr [lindex $bbox 3] - [lindex $bbox 1]]
    set graph_width [expr [lindex $bbox 2] - [lindex $bbox 0]]
    # Get the canvas size
    set height [winfo height $c]
    set width [winfo width $c]
    # X-direction
    if { $width > $graph_width } {
	# Width of graph is smaller than width of view
	# Attempt to centre it
	set xoffset [expr ( $width - $graph_width ) / 2 - $graph_x]
	$c move all $xoffset 0
    }
    # Y-direction
    if { $height > $graph_height } {
	# Height of graph is smaller than height of view
	# Attempt to centre it
	set yoffset [expr ( $height - $graph_height ) / 2 - $graph_y]
	$c move all 0 $yoffset
    }
}

############################################################
# Procedures for moving the canvas by doing "click and drag"
############################################################

#----------------------------------------------------------------
proc drag_canvas_start { c start_x start_y } {
#----------------------------------------------------------------
    # Invoked when user clicks on the canvas
    # Any dragging motion will trigger the next binding, to scroll
    # the canvas
    global ccp4i_db_viz
    if { $ccp4i_db_viz(IGNORE_NEXT_CLICK) } {
	# IGNORE_NEXT_CLICK is set to prevent the drag being initiated
	# in certain circumstances
	# This cancels it for the next click after this one
	set ccp4i_db_viz(IGNORE_NEXT_CLICK) 0
	return
    }
    bind $c <Motion> "drag_canvas_scroll $c $start_x $start_y %X %Y"
    # Change cursor to a cross - this indicates to
    # the user that the function of the mouse has changed
    $c config -cursor fleur
}

#----------------------------------------------------------------
proc drag_canvas_scroll { c start_x start_y x y } {
#----------------------------------------------------------------
    # Invoked following click-drag operation on the canvas
    # Scroll the viewable region as the mouse is dragged around
    if { [lindex [$c xview] 0] != 0 || [lindex [$c xview] 1] != 1 } {
	$c xview scroll [expr ($x - $start_x)] "units"
    }
    if { [lindex [$c yview] 0] != 0 || [lindex [$c yview] 1] != 1 } {
	$c yview scroll [expr ($y - $start_y)] "units"
    }
    bind $c <Motion> "drag_canvas_scroll $c $x $y %X %y"
}


#----------------------------------------------------------------
proc drag_canvas_cancel { c } {
#----------------------------------------------------------------
    # Invoked when the mouse button is released
    # Cancels the scrolling operation on the canvas view
    bind $c <Motion> {}
    # Change cursor back to default
    $c config -cursor {} 
}

############################################################
# Procedures for building application menus
############################################################

#----------------------------------------------------------------
proc add_radiobutton { m param value text cmd args } {
#----------------------------------------------------------------
    # m is the name of the menu to add the button to
    # param is the name of a parameter in the global array to
    # be set when the entry is selected and value is the
    # value to set it to when it's checked
    # text is the text to display on the menu next to the radiobutton
    # cmd is a command to be invoked when the entry is
    # selected
    # args are any other arguments normally accepted by the menu
    # command
    set button_cmd [list $m add radiobutton \
			-variable ccp4i_db_viz($param) \
			-value $value \
			-label "$text" \
			-command "$cmd"]
    if { [llength $args] > 0 } {
	set button_cmd [concat $button_cmd $args]
    }
    eval $button_cmd
}

############################################################
# Procedures for displaying job information
############################################################

#----------------------------------------------------------------
proc display_job_data { id } {
#----------------------------------------------------------------
    # Placeholder: invoked when mouse enters node
    # In a full application this could display the
    # job information e.g. in a separate panel or as ballon
    # information
    global ccp4i_db_viz
    $ccp4i_db_viz(INFO) configure \
	-text "Job $id: [getdata $id TASKNAME] \"[getdata $id TITLE]\""
}

#----------------------------------------------------------------
proc clear_job_data { } {
#----------------------------------------------------------------
    # Remove the job data displayed in the line at
    # the bottom of the screen
    $ccp4i_db_viz(INFO) configure -text {}
}


############################################################
# Procedures for displaying options on a right mouse click
############################################################

#----------------------------------------------------------------
proc display_job_options { c x y id } {
#----------------------------------------------------------------
    # Invoked when right mouse clicked on a particular job
    # giving options to view files, run plugins and perform
    # selections
    global ccp4i_db_viz
    global configure

    # Acquire data
    set project $ccp4i_db_viz(PROJECT)
    set taskname [getdata $id TASKNAME]
    set infiles [ListInputFiles $project $id]
    set outfiles [ListOutputFiles $project $id]

    # Make a pop-up menu
    set m "$c.popup"
    if { [winfo exists $m] } {
	destroy $m
    }
    menu $m -tearoff 0
    $m add command -label "For job $id.." -font $configure(FONT_ITALIC)
    $m add separator

    # Logfiles and graphs
    set logfile [getdata $id LOGFILE]
    set path [GetProjectDir $project]
    
    # Get full path
    set logfilefullpath [file join $path $logfile]

    # view logfile
    if { [file isfile "$logfilefullpath"] } {
	$m add command -label "View Log File" \
	    -font $configure(FONT_REGULAR) \
	    -command "DisplayTextFile \"$logfilefullpath\" -monitor -summary"
        $m add command -label "View Log Graphs" \
	    -font $configure(FONT_REGULAR) \
	    -command "LogGraph \"$logfilefullpath\""
    }
    # Check for annotated logfile
    set annotatedlog [subst $logfilefullpath].html
    if { [file isfile "$annotatedlog"] } {
	$m add command -label "View Annotated Log in Web Browser" \
	    -font $configure(FONT_REGULAR) \
	    -command "open_url $annotatedlog"
    } elseif { [file isfile "$logfilefullpath"] } {
	$m add command -label "Generate and view annotated Log" \
	    -font $configure(FONT_REGULAR) \
	    -command "CreateAnnotatedLogfile \"$logfilefullpath\" ; open_url $annotatedlog"
    }

    # Input and output files
    $m add cascade -label "Input and output files .."  \
	-font $configure(FONT_ITALIC) \
	-menu $m.filemenu
    menu $m.filemenu -tearoff 0

    $m.filemenu add command -label "Input files..." \
	-font $configure(FONT_ITALIC)
    foreach file $infiles {
	if { [ file exists "$file" ] } {
	    $m.filemenu add command -label "[file tail $file]" \
		-command "FileViewer \"$file\" -noquery"
	}
    }
    $m.filemenu add command -label "Output files..." \
	-font $configure(FONT_ITALIC)
    foreach file $outfiles {
	if { [ file exists "$file" ] } {
	    $m.filemenu add command -label "[file tail $file]" \
		-command "FileViewer \"$file\" -noquery"
	}
    }

    # Plugins
    if { [llength [set plugins [GetPlugins $taskname $outfiles]]] > 0 } {
	$m add separator
	foreach plugin $plugins {
	    $m add command -label "[lindex $plugin 0]" \
		-font $configure(FONT_REGULAR) \
		-command "[lindex $plugin 1]"
	}
    }
    
    # view notebook
    set notebook [GetNotebook $ccp4i_db_viz(PROJECT) $id]
    if { $notebook != "" } {
	$m.filemenu add command -label "View notebook" \
	    -command "DisplayTextFile $notebook"
    }

    # Append job selection options
    $m add separator
    $m add command -label "Select all children" \
	-font $configure(FONT_REGULAR) \
	-command "select_all_children $c $id"
    $m add command -label "Select all parents" \
	-font $configure(FONT_REGULAR) \
	-command "select_all_parents $c $id"
    $m add command -label "Select all related jobs" \
	-font $configure(FONT_REGULAR) \
	-command "select_all_related_jobs $c $id"

    # Append reaper option
    $m add separator
    $m add command -label "Run Reaper for Data Harvesting" \
	-font $configure(FONT_REGULAR) \
	-command "harvesting_analysis $ccp4i_db_viz(PROJECT) $id"

    #$m add separator
    #$m add command -label "rerun the job" -command "rerun_job $id"
    #$m add separator
    #$m add command -label "delete the job" -command "delete_job $id"
    # Pop-up the menu
    tk_popup $m $x $y
    
}

############################################################
# Procedures for decorating jobs
############################################################

#----------------------------------------------------------------
proc jobquality_decorations { jobs c } {
#----------------------------------------------------------------
    # Code originally abstracted from render_jobs
    # "jobs" is a list of job ids, "c" is the name of the canvas
    # on which they are being rendered.
    # For each job this function checks for the existence of a
    # "job quality" indicator, and attempts to decorate the node
    # according to its value.
    # This was originally intended as a way to display the "job
    # solution quality" from MrBump jobs, with the job quality
    # indicator being stored in the SQLite database.
    global ccp4i_db_viz
    if { $add_decorations } {
	# Loop over all the jobs again
	foreach id $jobs {
	    # Node name
	    set name "Job$id"
	    # For each node, add the job id to the node
	    # First, make a canvas text item with the job id
	    if { $ccp4i_db_viz(SQLDB) == 1 } {
		set quality [ get_extension_data JobQuality $id ]
		if { $quality == "1" } {
		    set tick [$c create line 30 40 35 45 40 33 -width 2]
		   
		    #set decoration1 [$c create bitmap 50 150 -bitmap @[file join [GetEnvPath DBCCP4I_TOP] icons SmileyFaceBigEyes.xbm]]
		    # Now make a little rectangle
		    set box [$c create rectangle 0 0 15 15 \
					 -fill white -outline black]
		    # Place the text over the rectangle
		    $c raise $tick $box
		    #Decorate the node
		    dotgraph_decorate_node $name $c [list $box $tick] \
			-anchor se -overlap 0.85
		    # add bubble help here
		    $c bind $tick <Enter> \
			"bubblehelp_for_decoration $id \"The solution is good\" %X %Y %x %y" 
		}  elseif { $quality == "-1" } {
		set cross [$c create line 30 34 35 39 40 34 30 44 35 39 40 44 -width 2]
	
		set box [$c create rectangle 0 0 15 15 \
			     -fill white -outline black]
		# Place the text over the rectangle
		$c raise $cross $box
		
		#Decorate the node
		dotgraph_decorate_node $name $c [list $cross $box] \
		    -anchor se -overlap 0.85
		# add bubble help here
     
		$c bind $cross <Enter> \
		    "bubblehelp_for_decoration $id \"The solution is bad\" %X %Y %x %y" 
		    
		} elseif { $quality == "0" } {
		    set box [$c create rectangle 0 0 15 15 \
				 -fill white -outline black]
		    set text [$c create text 0 0 -text "?" \
				  -width 2 -font {-size 15 -weight bold}] 
		    # Place the text over the rectangle
		    $c raise $text $box
		    #Decorate the node
		    dotgraph_decorate_node $name $c [list $text $box] \
			-anchor se -overlap 0.85
		    # add bubble help here
		    
		    $c bind $text <Enter> \
			"bubblehelp_for_decoration $id \"The solution is marginal\" %X %Y %x %y" 
		}
		
	    } 
	}
    }
}

############################################################
# Procedures for selecting/deselecting jobs
############################################################

#----------------------------------------------------------------
proc select_job { c id } {
#----------------------------------------------------------------
    # Invoked on left mouse click to perform job selection
    #
    # If the job is not already selected then deselect
    # any existing selection and then select this job
    # If the job is selected then deselect it and all others
    global ccp4i_db_viz
    # Check that this job is not already in the selection
    if { [set i [lsearch $ccp4i_db_viz(SELECTION) $id]] < 0 } {
	# Not found = not selected
	# Clear existing selection     
	clear_selection $c
	# Add this job
	lappend ccp4i_db_viz(SELECTION) $id
       
	# store last_click_jobid
	set ccp4i_db_viz(LAST_CLICK_JOBID) $id
       
	# Change the colour
	update_colour $c $id "cyan"

    } else {
	# Job is already selected - so remove it and all others

	#clear selection 
	clear_selection $c
    }
    # Prevent the generic single click being triggered
    set ccp4i_db_viz(IGNORE_NEXT_CLICK) 1
}

#----------------------------------------------------------------
proc select_multiple_jobs { c id } {
#----------------------------------------------------------------
    # Invoked on left mouse click with control to add
    # or remove a job to/from a multiple job selection
    #
    # If the job is not already selected then add it
    # to any existing selection
    # If the job is selected then deselect it
    global ccp4i_db_viz
   
    # Check that this job is not already in the selection
    if { [set i [lsearch $ccp4i_db_viz(SELECTION) $id]] < 0 } {
	# Not found = not selected
	# Add this job
	lappend ccp4i_db_viz(SELECTION) $id
 
	# Change the colour
	update_colour $c $id "cyan"
    } else {
	# Job is already selected - so remove it
	# from the selection
	get_job_colours $id fg_colour bg_colour
	# Configure the item
	update_colour $c $id $bg_colour
	# Remove from the selection list
	set ccp4i_db_viz(SELECTION) [lreplace $ccp4i_db_viz(SELECTION) $i $i]
    }
    # Prevent the generic single click being triggered
    set ccp4i_db_viz(IGNORE_NEXT_CLICK) 1
}

#--------------------------------------------------------------------
proc select_all_children { c id { no_clear 0 } } {
#--------------------------------------------------------------------
    # select all the children of a specific job
    global ccp4i_db_viz

    # Clear the existing selection
    if { ! $no_clear } {	
	clear_selection $c
    }
    # Select the current job (if not already selected)
    if { [lsearch $ccp4i_db_viz(SELECTION) $id] < 0 } {
	lappend ccp4i_db_viz(SELECTION) $id
    }
    update_colour $c $id "cyan"

    # Fetch all child nodes & update colours
    # FIXME some nodes may not be in the current display
    # which will raise a warning from dotgraph
    set children [GetAllChildren $ccp4i_db_viz(PROJECT) $id]
    foreach child $children {
	update_colour $c $child "cyan"
	lappend ccp4i_db_viz(SELECTION) $child
    }
}

#--------------------------------------------------------------------
proc select_all_parents { c id { no_clear 0 } } {
#--------------------------------------------------------------------
# select all the parents of a specific job
    global ccp4i_db_viz

    # Clear the existing selection
    if { ! $no_clear } {
	clear_selection $c
    }
    # Select the current job (if not already selected)
    if { [lsearch $ccp4i_db_viz(SELECTION) $id] < 0 } {
	lappend ccp4i_db_viz(SELECTION) $id
    }
    update_colour $c $id "cyan"

    # Fetch all parent nodes & update colours
    # FIXME some nodes may not be in the current display
    # which will raise a warning from dotgraph
    set parents [GetAllParents $ccp4i_db_viz(PROJECT) $id]
    foreach parent $parents {
	update_colour $c $parent "cyan"
	lappend ccp4i_db_viz(SELECTION) $parent
    }
}

#--------------------------------------------------------------------
proc select_all_related_jobs { c id { no_clear 0 } } {
#--------------------------------------------------------------------
# select all related jobs of a specific job

    global ccp4i_db_viz
    # Clear the existing selection
    if { ! $no_clear } {
	clear_selection $c
    }

    # Select the current job (if not already selected)
    if { [lsearch $ccp4i_db_viz(SELECTION) $id] < 0 } {
	lappend ccp4i_db_viz(SELECTION) $id
    }
    update_colour $c $id "cyan"

    # Fetch all parent and child nodes & update colours
    # FIXME some nodes may not be in the current display
    # which will raise a warning from dotgraph
    set relatedjobs [GetAllParentsChildren $ccp4i_db_viz(PROJECT) $id]
    foreach job $relatedjobs {
	update_colour $c $job "cyan"
	lappend ccp4i_db_viz(SELECTION) $job
    }
}

#----------------------------------------------------------------
proc return_selection { } {
#----------------------------------------------------------------
    # Return the current list of selected jobs
    global ccp4i_db_viz
    return $ccp4i_db_viz(SELECTION)
}


#----------------------------------------------------------------
proc clear_selection { c } {
#----------------------------------------------------------------
    # Clear the list of selected jobs
    global ccp4i_db_viz
    
    # Loop over all currently selected job ids
    # and restore the colour
    foreach id $ccp4i_db_viz(SELECTION) {
	# Set the colour according to the status
	get_job_colours $id fg_colour bg_colour
	# Configure the item
	update_colour $c $id $bg_colour
    }

    # Erase the list of jobs
    set ccp4i_db_viz(SELECTION) {}
    
    return $ccp4i_db_viz(SELECTION)
}


#----------------------------------------------------------------
proc update_colour { c id newcolor } {
#----------------------------------------------------------------
    # Change the colour of a node on the fly to the selected
    # colour
    global ccp4i_db_viz
    set g $ccp4i_db_viz(GRAPH)
    set name "Job[transform_jobid $id]"
    dotgraph_update_node_color $g "$name" $newcolor $c
}


############################################################
# Procedures for dealing with the setting and retrieving
# job selections
############################################################

#----------------------------------------------------------------
proc show_selected_jobs { } {
#----------------------------------------------------------------
    # Add the set of jobs currently selected **in the
    # display** to the selection list, then update the
    # display to show those jobs
    set jobs [return_selection]
    if { [llength $jobs] == 0 } {
	# Nothing to do
	return
    } else {
	# Add the selected jobs and redraw
	add_selection $jobs
    }
}

#----------------------------------------------------------------
proc show_all_jobs { } {
#----------------------------------------------------------------
    # Reset the display to show all the jobs in the
    # project (not just those previously selected)
    add_selection {}
}

#----------------------------------------------------------------
proc get_selection { } {
#----------------------------------------------------------------
    # Return the current selection from the list of
    # stored selections
    global ccp4i_db_viz
    set ptr $ccp4i_db_viz(SELECTION_POINTER)
    return [lindex $ccp4i_db_viz(SELECTION_LIST) $ptr]
}

#----------------------------------------------------------------
proc add_selection { selection } {
#----------------------------------------------------------------
    # Insert a new selection in the selection list
    # after the current position
    global ccp4i_db_viz
    set selection_list $ccp4i_db_viz(SELECTION_LIST)
    set selection_ptr $ccp4i_db_viz(SELECTION_POINTER)
    # Clear the remaining selections
    set selection_list [lrange $selection_list 0 $selection_ptr]
    lappend selection_list $selection
    incr selection_ptr
    # Store the updated values
    set ccp4i_db_viz(SELECTION_LIST) $selection_list
    set ccp4i_db_viz(SELECTION_POINTER) $selection_ptr
    # Set the forward and back selection button states
    set_forward_button_state disabled
    set_back_button_state normal
    # Invoke redraw
    display_job_db
}

#----------------------------------------------------------------
proc next_selection { } {
#----------------------------------------------------------------
    # Retrieve the next selection in the list
    global ccp4i_db_viz
    # Advance the pointer
    incr ccp4i_db_viz(SELECTION_POINTER)
    # Enable the previous selection button
    set_back_button_state normal
    # Disable the forward button if this is the last
    # selection
    if { [expr $ccp4i_db_viz(SELECTION_POINTER)+1] >= 
	 [llength $ccp4i_db_viz(SELECTION_LIST)] } {
	set_forward_button_state disabled
	# Stop the pointer from falling off the end
	# Reset pointer back to previous value and jump out
	if { $ccp4i_db_viz(SELECTION_POINTER) == 
	     [llength $ccp4i_db_viz(SELECTION_LIST)] } {
	    incr ccp4i_db_viz(SELECTION_POINTER) -1
	    return
	}
    } else {
	set_forward_button_state normal
    }
    # Invoke redraw
    display_job_db
}

#----------------------------------------------------------------
proc prev_selection { } {
#----------------------------------------------------------------
    # Retrieve the previous selection in the list
    global ccp4i_db_viz
    # Step the pointer back
    incr ccp4i_db_viz(SELECTION_POINTER) -1
    # Check if we're at the start of the list
    if { $ccp4i_db_viz(SELECTION_POINTER) <= 0 } {
	# Disable the back selection button
	set_back_button_state disabled
	# Stop the pointer going back too far
	if { $ccp4i_db_viz(SELECTION_POINTER) < 0 } {
	    # Reset to zero and jump out
	    set ccp4i_db_viz(SELECTION_POINTER) 0
	    return
	}
    }
    # Enable the forward selection button
    set_forward_button_state normal
    # Invoke redraw
    display_job_db
}

#----------------------------------------------------------------
proc reset_selections { } {
#----------------------------------------------------------------
    # Reset the selection list and pointer
    global ccp4i_db_viz
    set ccp4i_db_viz(SELECTION_LIST) [list {}]
    set ccp4i_db_viz(SELECTION_POINTER) 0
    # Disable the forward and back buttons
    set_forward_button_state disabled
    set_back_button_state disabled
}

#----------------------------------------------------------------
proc set_back_button_state { state } {
#----------------------------------------------------------------
    # Set the state of the "back" button on the menubar
    # state should be either "normal" or "disabled"
    .tbar.back configure -state $state
}

#----------------------------------------------------------------
proc set_forward_button_state { state } {
#----------------------------------------------------------------
    # Set the state of the "forward" button on the menubar
    # state should be either "normal" or "disabled"
    .tbar.forward configure -state $state
}

#----------------------------------------------------------------
proc hide_up_button { } {
#----------------------------------------------------------------
    # Hide the button on the menubar that ascends up from a
    # subjob database
    pack forget .tbar.up
}

#----------------------------------------------------------------
proc show_up_button { } {
#----------------------------------------------------------------
    # Show the button on the menubar that ascends up from
    # a subjob database
    # configure it to return to the parent project
    global ccp4i_db_viz
    .tbar.up configure -command "select_project_db $ccp4i_db_viz(PROJECT)"
    pack .tbar.up -side left -after .tbar.forward
}

############################################################
# Procedures for displaying "bubble help"
############################################################

#----------------------------------------------------------------
proc bubblehelp_for_decoration { id text X Y x1 y1 } {
#----------------------------------------------------------------
# display bubblehelp information for decoration
    global ccp4i_db_viz
    set w $ccp4i_db_viz(CANVAS)
    # Set the name for the node
    set name "Job[transform_jobid $id]"
    
    .nodeinfo.label configure -text $text -justify left
    set x2 [string trim [format %-6.0f [$w canvasx $x1]]]
    set y2 [string trim [format %-6.0f [$w canvasy $y1]]]

    # Get the bounding box coordinates of the current node
    # These are in the same coordinate frame as x2,y2
    set bbox [$w bbox $name]

    # Get the bottom LH corner of the box as x3,y3
    set x3 [lindex $bbox 0]
    set y3 [lindex $bbox 3]

    # Calculate shifts from x2,y2 to x3,y3
    set xshift [expr $x3 - $x2]
    set yshift [expr $y3 - $y2]
    
    # Apply shifts to the absolute screen coordinates X,Y (plus
    # some extra padding)
    set padding 5
    set x [expr $X + $xshift + $padding]
    set y [expr $Y + $yshift + $padding]

    # Move the bubblehelp to this position and make visible
    wm geometry .nodeinfo +$x+$y
    wm deiconify .nodeinfo
    raise .nodeinfo   
}

#----------------------------------------------------------------
proc bubblehelp_for_job { id X Y x1 y1 } {
#----------------------------------------------------------------
# display bubblehelp information for specific job
    global ccp4i_db_viz
    set w $ccp4i_db_viz(CANVAS)

    # Get the node name based on the job id
    # This is the tag created by dotgraph and used for the
    # canvas item representing the job

    # Check that the job data is cached
    if { ![job_exists_in_cache $id] } {
	# Give up
	return
    }

    # check if it is a subjob
    set name "Job[transform_jobid $id]"

    # Generate the text to display and load into the label
    set title [getdata $id TITLE]
    set re_format_title [format_title "Title: $title" 40]
    set date [getdata $id DATE]
    set taskname [getdata $id TASKNAME]
    set status [getdata $id STATUS]

    set re_format_date [GetDate -format brief -clock $date]
    set label "Job $id:\t$taskname\nStatus:\t$status\nDate:\t$re_format_date\n$re_format_title"
    .nodeinfo.label configure -text "$label" -justify left

    # Calculate the position to display the bubble on the screen
    # This is not straightforward because we have three different
    # coordinate systems:
    # * X and Y are the absolute screen coordinates
    # * x1 and y1 are coordinates relative to the *viewport* origin
    # * canvasx and canvasy translate the viewport coordinates into
    #   coordinates relative to the *canvas* origin
    # * bbox command gives the bounding box of the items relative to
    #   the canvas origin
    #
    # So the procedure is:
    # 1. Get the mouse position in the canvas, by transforming x1,y1
    #    into x2,y2 using the canvasx and canvasy commands
    # 2. Get the coordinates of the box around the node (also in
    #    canvas coordinates) using the bbox command
    # 3. Get the coordinates of the bottom left-hand corner of the
    #    bounding box in canvas coordinates, as x3,y3
    # 4. Calculate the shift from the mouse position x2,y3 to the
    #    corner of the box x3,y3
    # 5. Apply this shift (plus some extra) to the mouse position in
    #    absolute coordinates to get the screen position of theGetDb_extensionData 
    #    bubble
    
    # Now do it for real:

    # Get the mouse position in the canvas coordinate system
    # Turn these values into integers
    set x2 [string trim [format %-6.0f [$w canvasx $x1]]]
    set y2 [string trim [format %-6.0f [$w canvasy $y1]]]

    # Get the bounding box coordinates of the current node
    # These are in the same coordinate frame as x2,y2
    set bbox [$w bbox $name]

    # Get the bottom LH corner of the box as x3,y3
    set x3 [lindex $bbox 0]
    set y3 [lindex $bbox 3]

    # Calculate shifts from x2,y2 to x3,y3
    set xshift [expr $x3 - $x2]
    set yshift [expr $y3 - $y2]
    
    # Apply shifts to the absolute screen coordinates X,Y (plus
    # some extra padding)
    set padding 5
    set x [expr $X + $xshift + $padding]
    set y [expr $Y + $yshift + $padding]

    # Move the bubblehelp to this position and make visible
    wm geometry .nodeinfo +$x+$y
    wm deiconify .nodeinfo
    raise .nodeinfo   
}
    
#----------------------------------------------------------------
proc bubblehelp_for_job_cancel { } {
#----------------------------------------------------------------
# destroy bubblehelp for specific job

    if { [winfo exists .nodeinfo] } {
	wm withdraw .nodeinfo
	.nodeinfo.label configure -text ""
    }
}

#----------------------------------------------------------------
proc format_title { title { maxlen 30 } } {
#----------------------------------------------------------------
    # Format a title string into multiple lines such that no line
    # is longer than maxlen characters
    set re_format_title ""
    set line ""
    foreach word [split $title] {
	set old_line $line
	append line " " $word
	set line [string trim $line]
	if { [string length $line] > $maxlen } {
	    append re_format_title "\n" $old_line
	    set line $word
	} else {
	    set word ""
	}
    }
    if { $line != "" } {
	append re_format_title "\n" $line
    }
    return [string trim $re_format_title]

}

#-----------------------------------------------------------------
proc set_balloonhelp { w text } {
#-----------------------------------------------------------------
    # Set up the bindings for balloon help on arbitrary widgets
    # The widget name is "w" and "text" is the help message to be
    # shown when the mouse moves over that widget
    bind $w <Enter> "balloonhelp_show $w \"$text\""
    bind $w <Leave> "balloonhelp_cancel"   
}

#-----------------------------------------------------------------
proc balloonhelp_cancel { } {
#-----------------------------------------------------------------
    global bhInfo
    wm withdraw .balloonhelp
}

#-----------------------------------------------------------------
proc balloonhelp_show {win msg} {
#-----------------------------------------------------------------
    #global bhInfo
   
    .balloonhelp.info configure -text $msg
    set  x [expr [winfo rootx $win]+10]
    set y [expr [winfo rooty $win]+[winfo height $win]]
    wm geometry .balloonhelp +$x+$y
    wm deiconify .balloonhelp
    raise .balloonhelp
}

#################################################################
#
# Functions for dealing with extensions to the .def database
#
#################################################################

#-----------------------------------------------------------
proc GetDb_extensionData { project itemlist } {
#-----------------------------------------------------------
# procedure to get extension database data
# ext_database used to store data from extenstion database

    global database_extension
    global ccp4i_db_viz

    # get the records from handler
    set records [ GetAllSQLdbData $project $itemlist]
   
    # get the length of itemlist
    set len [llength $itemlist]
    set value ""

    # store the records in database_extension array
    foreach record $records {
	for { set n 1 } { $n < $len } { incr n } {
	    # get the item name
	    set item [ lindex $itemlist $n ]
	    # get the value for that item
	    set value [ lindex $record $n ]
	    # store in the array
	    set database_extension($item,[lindex $record 0]) $value
	}
    }
    # set sqldb flag
    set ccp4i_db_viz(SQLDB) 1
}

#-------------------------------------------------------------
proc get_extension_data { item id } {
#-------------------------------------------------------------
# procedure to get the data from database_extension array
    global database_extension
 
    if { [info exists database_extension([subst $item],$id)] == 1 } {
	return $database_extension([subst $item],$id)
    } else {
	return ""
    }
}

#################################################################
#
# Functions for selecting project and generating display
#
#################################################################

#----------------------------------------------------------------
proc select_project_db { project { jobid {} } } {
#----------------------------------------------------------------
    # Change to a new project or subjob
    global ccp4i_db_viz

    # Check if we need to change the project
    if { $ccp4i_db_viz(PROJECT) != $project } {
	# New project: close current project, if open
	if { $ccp4i_db_viz(PROJECT) != "" } {
	    CloseProject $ccp4i_db_viz(PROJECT)
	    # reset SQL flag
	    set ccp4i_db_viz(SQLDB) 0
	    set ccp4i_db_viz(PROJECT) {}
	}
	# Open the new project
	if { ! [OpenProject $project msg] } {
	    if { $msg == "data is locked" } {
		# Attempt to open as read-only
		if { [OpenProject $project -readonly] } {
		    WarningMessage "Project $project has been opened
in read-only mode."
		}
	    }
	}
	# Clear the display and put up a message
	$ccp4i_db_viz(CANVAS) delete all
	bubblehelp_for_job_cancel
	display_message "Loading data for project $project\nPlease wait.."

	# Reset the context
	# FIXME we should check here for whether we have access
	# to the database
	set ccp4i_db_viz(PROJECT) $project
	set ccp4i_db_viz(SUBJOB) {}
    }
    # Deal with subjob db
    if { $ccp4i_db_viz(SUBJOB) != $jobid } {
	if { $jobid != "" } {
	    # FIXME we should check here that this job has a
	    # subjob db associated with it
	    # Prevent the generic single click being triggered
	    # after descending into subjob db
	    set ccp4i_db_viz(IGNORE_NEXT_CLICK) 1
	}
	# Reset the subjob db context
	set ccp4i_db_viz(SUBJOB) $jobid

    }
    # Re-initialise the database cache
    initialise_database_cache $ccp4i_db_viz(PROJECT) $ccp4i_db_viz(SUBJOB)

    # Reset the selections
    reset_selections
    set ccp4i_db_viz(SELECTION) {}

    # Reset the selected project
    set ccp4i_db_viz(SELECTEDPROJECT) $ccp4i_db_viz(PROJECT)

    # Regenerate the display
    display_job_db
}

#----------------------------------------------------------------
proc display_job_db { } {
#----------------------------------------------------------------
    # Draw the display based on the current context
    global ccp4i_db_viz

    # Collect the context
    set project $ccp4i_db_viz(PROJECT)
    set jobid $ccp4i_db_viz(SUBJOB)
    
    # Get a list of jobs
    if { $jobid == "" } {
	set joblist [ListJobs $project]
    } else {
	set joblist [ListJobs $project $jobid]
    }

    # Deal with selections
    set selection [get_selection]

    # If there is a selection then weed the joblist
    # to ensure that the no non-existance jobs are left
    # in the selection
    if { [llength $selection] > 0 } {
	set updated_list {}
	foreach job $selection {
	    if { [lsearch $joblist $job] > -1 } {
		lappend updated_list $job
	    } else {
		puts "Warning job $job is in selection but no longer in the project"
	    }
	}
	set joblist $updated_list
    }

    # Deal with filters
    if { $ccp4i_db_viz(FINISHED_FILTER) } {
	set joblist [filter_finished_jobs $joblist]
    }
    if { $ccp4i_db_viz(LINKED_FILTER) } {
	set joblist [filter_linked_jobs $joblist]
    }

    # Do the display
    if { [llength $joblist] < 1 } {
	# No jobs to display
	set ccp4i_db_viz(JOB_LIST) {}
	display_message "Currently there are no jobs\nto display"
    } else {
	# Generate the display
	render_job_list $joblist
    }

    # Update the button for leaving subjob db
    if { $jobid == "" } {
	hide_up_button
    } else {
	show_up_button
    }
}

#----------------------------------------------------------------
proc render_job_list { jobs } {
#----------------------------------------------------------------
    # Given a list of jobs, update the display to
    # show them
    global ccp4i_db_viz
  
    # "configure" is CCP4i's global configuration
    # array which contains font and colour information
    global configure

    # Initialise parameters for display
    set maxwidth $ccp4i_db_viz(MAXWIDTH)
    set maxheight $ccp4i_db_viz(MAXHEIGHT)
    set minwidth $ccp4i_db_viz(MINWIDTH)
    set minheight $ccp4i_db_viz(MINHEIGHT)
    set border $ccp4i_db_viz(BORDER)

    # Project name
    set project $ccp4i_db_viz(PROJECT)

    # Collect canvas name
    set c $ccp4i_db_viz(CANVAS)

    # Get the current height and width
    set current_height [$c cget -height] 
    set current_width [$c cget -width]

    # Fetch info for the old graph and set the name
    # for the new graph
    set oldg $ccp4i_db_viz(GRAPH)
    if { $oldg == "g1" } {
	set g "g0"
    } else {
	set g "g1"
    }

    # Create the new dotgraph
    # We can do this before we delete the old one
    set newg [dotgraph_new $g \
	       -direction $ccp4i_db_viz(DIRECTION) \
	       -background $ccp4i_db_viz(BACKGROUND) \
	       -shape $ccp4i_db_viz(SHAPE) \
	       -color $ccp4i_db_viz(COLOR) \
	       -fillcolor $ccp4i_db_viz(FILLCOLOR) ]
    
    # Store the name of the graph for later
    set ccp4i_db_viz(GRAPH) $newg

    # Write out the nodes (= jobs)
    foreach id $jobs {
	
	# Set the colour depending on the status     
	get_job_colours $id fg_colour bg_colour
	
	# Create a node for this job
	set name "Job[transform_jobid $id]"
	
	# Generate the data to be displayed for the job
	set taskname ""
	set title ""
	if { $ccp4i_db_viz(NODE_TASKNAME) } {
	    # Set the taskname for display
	    set taskname [getdata $id TASKNAME]
	}
	if { $ccp4i_db_viz(NODE_TITLE) } {
	    # Set the title for display
	    append title "[getdata $id TITLE]"
	    if { $taskname != "" } {
		append taskname "\n"
	    }
	}
	# Create the node for this job
	dotgraph_add_node $g $name \
	    -label "$id: [subst $taskname][format_title $title 30]" \
	    -shape $ccp4i_db_viz(SHAPE) -fillcolor $bg_colour \
	    -color $fg_colour -font $configure(FONT_REGULAR)
	
	####################################
	# Add bindings for node
	####################################
	
	# Bindings that are invoked when the mouse enters and leaves
	# a displayed job
	dotgraph_bind_node $g $name <Enter> "bubblehelp_for_job $id %X %Y %x %y"
	dotgraph_bind_node $g $name <Leave> "bubblehelp_for_job_cancel"
	
	# Selection
	# Ctrl-Button1 selects multiple jobs
	dotgraph_bind_node $g $name <Button-1> "select_job $c $id"
	dotgraph_bind_node $g $name <Control-Button-1> "select_multiple_jobs $c $id"
	
	# Right mouse click on a job to give a menu of options
	dotgraph_bind_node $g $name <Button-3> "display_job_options $c %X %Y $id"
    }
    set connection [GetFileLinks $project $jobs]
    
    foreach link $connection {
	set id_1 [lindex $link 0]
	set id_2 [lindex $link 1]
	
	# check the id in link also in jobs list
	if { [lsearch $jobs $id_1]> -1 && [lsearch $jobs $id_2] >-1 } {
	    # Create a link
	    set node1 "Job[transform_jobid $id_1]"
	    set node2 "Job[transform_jobid $id_2]"
	    dotgraph_add_connection $g $node1 $node2
	}
    }

    # Delete the old graph
    clear_job_display $c $oldg 
    
    # Display the graph
    # check the scale
    if { $ccp4i_db_viz(SCALE) == 0 } {
	set ccp4i_db_viz(SCALE) 25
    }
    
    if { $ccp4i_db_viz(SCALE) > 250 } {
	set ccp4i_db_viz(SCALE) 250
    }
    
    dotgraph_render $g $c -shadow $ccp4i_db_viz(SHADOWS) \
	-using $ccp4i_db_viz(RENDERING_ENGINE) -scale $ccp4i_db_viz(SCALE)
    
    # Reset the height and width of the canvas
    set bbox [$c bbox all]
    
    set new_height [expr [lindex $bbox 3] - [lindex $bbox 1] + 2 * $border]
    if { $new_height < $current_height } {
	set new_height $current_height
    } elseif { $new_height > $maxheight } {
	set new_height $maxheight
    } elseif { $new_height < $minheight } {
	set new_height $minheight
    }
    $c configure -height $new_height
    
    set new_width [expr [lindex $bbox 2] - [lindex $bbox 0] + 2 * $border]
    if { $new_width < $current_width } {
	set new_width $current_width
    } elseif { $new_width > $maxwidth } {
	set new_width $maxwidth
    } elseif { $new_width < $minwidth } {
	set new_width $minwidth
    }
    $c configure -width $new_width
    
    # Reset the maximum scrollable region
    set bbox [$c bbox all]
    $c configure -scrollregion [list \
				    [expr [lindex $bbox 0] - $border] \
				    [expr [lindex $bbox 1] - $border] \
				    [expr [lindex $bbox 2] + $border] \
				    [expr [lindex $bbox 3] + $border]]
    
    # Reset the view
    $c xview moveto $ccp4i_db_viz(CURRENT_XVIEW)
    $c yview moveto $ccp4i_db_viz(CURRENT_YVIEW)
    
    centre_graph_in_view $c
    
    # Store the list of rendered jobs
    set ccp4i_db_viz(JOB_LIST) $jobs
    
    #################################################
    # Add decorations to jobs which have subjob db's
    set jobswithsubjobs [ListJobswithsubjobs $project]

    foreach id $jobs {
	if { [lsearch $jobswithsubjobs $id] != -1 } {
	    # add * to the node
	    set nodename "Job$id"
	    set star [$c create text 0 0 -text "*" -width 2 \
			  -font {-size 20 -weight bold}] 
	    # Place the text over the rectangle
	    $c raise $star
	    # Decorate the node
	    dotgraph_decorate_node $nodename $c $star -anchor nw -overlap 1
	    # add bubble help here    
	    $c bind $star <Enter> "bubblehelp_for_decoration $id \"This job has associated subjobs\nDouble click to view them\" %X %Y %x %y" 
	    $c bind $star <Leave> "bubblehelp_for_job_cancel"
	    $c bind $star <Double-Button-1> "select_project_db $project $id"
	}
    }

    # Update the message line
    update_info
}

#################################################################
#
# Filtering functions
#
#################################################################

#----------------------------------------------------------------
proc filter_finished_jobs { jobs } {
#----------------------------------------------------------------
    # Given a list of jobs, return a new list that comprises
    # only the ones that have STATUS set to FINISHED
    set filtered_jobs {}
    foreach job $jobs {
	if { [getdata $job STATUS] == "FINISHED" } {
	    lappend filtered_jobs $job
	}
    }
    return $filtered_jobs
}

#----------------------------------------------------------------
proc filter_linked_jobs { jobs } {
#----------------------------------------------------------------
    # Given a list of jobs, return a new list that comprises
    # only the ones that have links to another job
    global ccp4i_db_viz

    # Acquire list of jobs with links#
    set links [GetFileLinks $ccp4i_db_viz(PROJECT) $jobs]
    set linked_jobs {}
    foreach link $links {
	set start [lindex $link 0]
	set end [lindex $link 1]
	if { [lsearch $jobs $start] > -1 && [lsearch $jobs $end] > -1 } {
	    # Connection contained in the selection
	    lappend linked_jobs $start $end
	}
    }

    # Do the filtering
    set filtered_jobs {}
    foreach job $jobs {
	if { [lsearch $linked_jobs $job] > -1 } {
	    lappend filtered_jobs $job
	}
    }
    return $filtered_jobs
}

#################################################################
#
# Internal database caching functions
#
#################################################################

#----------------------------------------------------------------
proc initialise_database_cache { project { jobid "" } } {
#----------------------------------------------------------------
# Create a cache of the current project or subjob database
    global dbviewer_cache
    
    # Clear the existing cache data
    if { [array exists dbviewer_cache] } {
	array unset dbviewer_cache *
    }

    # Acquire list of jobs
    if { $jobid == "" } {
	set joblist [ListJobs $project]
    } else {
	set joblist [ListJobs $project $jobid]
    }
    # List of items in the database
    # Only cache the ones we need frequently
    set itemlist [list DATE TASKNAME TITLE STATUS]
    set dbviewer_cache(DBITEMS) $itemlist

    # Populate the cache
    if { $joblist != {} } {
	# get a list records from handler
	set records [GetListofRecords $project $joblist $itemlist ]
	if { [llength $records] > 0 } {
	    # Store the records in the cache database
	    foreach id $joblist {
		# get index of item
		set i [lsearch $joblist $id]
		# get record for the jobid 
		set record [lindex $records $i]
		foreach item $itemlist {
		    # get index of id
		    set j [lsearch $itemlist $item]
		    # get the item from the record
		    set dbviewer_cache($item,$id) [lindex $record $j]
		}
	    }
	}
    }
}

#----------------------------------------------------------------
proc update_database_cache { broadcast } {
#----------------------------------------------------------------
# Update the cache in response to a broadcast from the handler
    global dbviewer_cache
    global ccp4i_db_viz
    if { [llength $broadcast] != 5 } {
	# Broadcast doesn't have correct format
	puts "Warning: incorrect format for broadcast? $broadcast"
	return
    }
    # Unwrap the broadcast
    set project [lindex $broadcast 1]
    set job_id [lindex $broadcast 2]
    set operation [lindex $broadcast 3]
    # Reject operations on different projects
    if { $project != $ccp4i_db_viz(PROJECT) } {
	if { $project != "" } {
	    puts "Warning: broadcast for $project but this is $ccp4i_db_viz(PROJECT)"
	}
	return
    }

    # Update according to the broadcast operation
    switch $operation {
	DbNewJob {
	    update_database_cache_addjob $project $job_id
	}
	DbDeleteJob {
	    update_database_cache_deletejob $project $job_id
	}
	DbSetData {
	    update_database_cache_updatejob $project $job_id
	}
	AddOutputFile {
	    update_database_cache_updatejob $project $job_id
	}
	AddInputFile {
	    update_database_cache_updatejob $project $job_id
	}
	AddSubJob {
	    update_database_cache_addsubjob $project $job_id
	}
	DirectoriesReadonly|NewProject|DeleteProject|ImportProject {
	    # Ignore
	}
	AddDataDirRef|DeleteDataDirRef {
	    # Ignore
	}
	DbReadonly {
	    # Ignore
	}
	default {
	    puts "Warning: unrecognised operation: $operation"
	}
    }
}

#----------------------------------------------------------------
proc update_database_cache_addjob { project job_id } {
#----------------------------------------------------------------
# Add data for a new job to the cache
    global dbviewer_cache
    # Wrapper to updatejob
    update_database_cache_updatejob $project $job_id
}

#----------------------------------------------------------------
proc update_database_cache_deletejob { project job_id } {
#----------------------------------------------------------------
# Remove data for a deleted job from the cache
    global dbviewer_cache
    # Get the list of items to be deleted
    set itemlist $dbviewer_cache(DBITEMS)
    # Remove them from the cache for this job
    foreach item itemlist {
	if { [info exists dbviewer_cache([subst $item],$job_id)] } {
	    unset dbviewer_cache([subst $item],$job_id)
	}
    }
}

#----------------------------------------------------------------
proc update_database_cache_updatejob { project job_id } {
#----------------------------------------------------------------
# Update the data for a job in the cache
    global dbviewer_cache
    # Check that the job exists
    if { ![ItemExists $project $job_id STATUS] } {
	puts "Warning: job $job_id no longer in database?"
	return
    }
    # Get the list of items to be updated
    set itemlist $dbviewer_cache(DBITEMS)
    # Get the data
    set records [GetListofRecords $project [list $job_id] $itemlist]
    # Nb GetListofRecords always returns a list
    set record [lindex $records 0]
    for { set i 0 } { $i < [llength $itemlist] } { incr i } {
	# Add the key-value pair
	set key "[lindex $itemlist $i],$job_id"
	set value [lindex $record $i]
	set dbviewer_cache($key) $value
    }
}

#----------------------------------------------------------------
proc update_database_cache_addsubjob { project job_id } {
#----------------------------------------------------------------
# Add data for a new subjob in the cache
# The job id will be that of the subjob (not the parent)
    global ccp4i_db_viz
    if { $project == $ccp4i_db_viz(PROJECT) } {
	set parent [lindex [split $job_id .] 0]
	if { $parent == $ccp4i_db_viz(SUBJOB) } {
	    update_database_cache_updatejob $project $job_id
	}
    }
}

#----------------------------------------------------------------
proc getdata { jobid item } {
#----------------------------------------------------------------
# Return the value of a data item from the cache
    global dbviewer_cache
    global ccp4i_db_viz
    if { [info exists dbviewer_cache([subst $item],$jobid)] } {
	return $dbviewer_cache([subst $item],$jobid)
    }
    # Not in the cache - fetch from the handler
    return [GetData $ccp4i_db_viz(PROJECT) $jobid $item]
}

#----------------------------------------------------------------
proc job_exists_in_cache { jobid } {
#----------------------------------------------------------------
# Check if the requested job exists in the cache
    global dbviewer_cache
    return [info exists dbviewer_cache(STATUS,$jobid)]
}

#################################################################
#
# Functions for handling responses to broadcasts from
# the database handler
#
#################################################################

#----------------------------------------------------------------
proc handlebroadcast { broadcast } {
#----------------------------------------------------------------
    global ccp4i_db_viz
    # Handle broadcast message from the database handler
    # Update the cached data
    update_database_cache $broadcast
    # Schedule a refresh of the display
    schedule_refresh
}

#----------------------------------------------------------------
proc schedule_refresh { } {
#----------------------------------------------------------------
    # Set the refresh flag to tell the viewer to update
    # on the next iteration
    global ccp4i_db_viz
    set ccp4i_db_viz(REFRESH) 1
}

#----------------------------------------------------------------
proc refresh_viewer { } {
#----------------------------------------------------------------
    # If the refresh flag is set then rerender the display
    global ccp4i_db_viz
    if { $ccp4i_db_viz(REFRESH) } {
	# Update the display and reset the flag
	set ccp4i_db_viz(REFRESH) 0
	display_job_db
    }
    # Schedule the next call of this procedure
    after $ccp4i_db_viz(REFRESH_INTERVAL) refresh_viewer
}

#################################################################
#
# Functions for operating on the database
#
#################################################################

#---------------------------------------------------------------
proc delete_job { jobid } {
#---------------------------------------------------------------
# delete a job. This need to have more though to implement it fully. Currently not is use.
    global ccp4i_db_viz

    set action [ ChooseOptionDialog "Delete Job" "Delete Job" \
			 "You choose to delete the job. Do you want to continue or abort the operation?" \
			 [list "Cancel" "Continue"]  \
			 -default 0 ]
	if {"$action"=="Cancel"} {
	    return
	}

    if { [DeleteRecord $ccp4i_db_viz(PROJECT) $jobid] == 0 } {
	WarningMessage "Failed to delete the job"
  }

}


#--------------------------------------------------------------
proc rerun_job { jobid } {
#--------------------------------------------------------------
# rerun the job.
# not implement properly, need more thought
    global ccp4i_db_viz

    set taskname [getdata $jobid TASKNAME]
    set filename [append filename $jobid _ $taskname .def]
    set path [GetProjectDir $ccp4i_db_viz(PROJECT)]
    set path [file join $path CCP4_DATABASE]
    set fullpath [file join $path $filename]

    set arrayname [CreateNewArray dbtmp]
    InitialiseArray [SearchPath TOP tasks $taskname.def ] \
	$arrayname $taskname
    InitialiseArray $fullpath $arrayname $taskname
    upvar #0 $arrayname array

    set array(RERUN_JOBID) $jobid
    DefineVariable $arrayname OVERWRITE_JOB _logical 0

    # Create the task interface
    RunTask $taskname -array $arrayname
}

#################################################################
#
# Functions for handling job/subjob id strings
#
#################################################################

#--------------------------------------------------------------------
proc jobid_is_subjob { jobid } {
#--------------------------------------------------------------------
# Identify if a jobid is actually a subjob
# i.e. does it consist of two digits separated by a dot?
    return [regexp "(\[0-9\]+)\\.(\[0-9\]+)" $jobid]
}

#--------------------------------------------------------------------
proc transform_jobid { jobid } {
#--------------------------------------------------------------------
# change subjob id dot "." to "_"
    regsub "\\." $jobid "_" newjobid
    return $newjobid
}

#################################################################
#
# Functions for demonstration of CCP4i SQLite knowledge base
#
#################################################################

#--------------------------------------------------------------------
proc bioxhit_db_exists { } {
#--------------------------------------------------------------------
# Check that the interface files are available for this option
    if { ! [DbSupported sqlite] } {
	# No support for SQLite db
	return 0
    }
    # Test for interface files in CCP4i tasks area
    if { [file exists [file join [GetEnvPath CCP4] ccp4i tasks bioxhit_db.tcl]] &&
	 [file exists [file join [GetEnvPath CCP4] ccp4i tasks bioxhit_db.def]] } {
	return 1
    } else {
	# Interface files are missing
	return 0
    }
}

#--------------------------------------------------------------------
proc bioxhit_db { } {
#--------------------------------------------------------------------
# Launch the CCP4i task to access the demonstration SQLite db
# This function is required for BIOXHIT deliverable D 5.2.16
    if { [catch { exec "[file join [GetEnvPath CCP4I_TCLTK] wish]" "[file join [GetEnvPath CCP4] ccp4i bin ccp4i.tcl]" -t bioxhit_db & } err] } {
	WarningMessage "Failed to launch the demonstration interface:\n\n$err"
    }
}

############################################################
# TOP-LEVEL SCRIPT CODE
############################################################

# Initialise the dotgraph package
set dotgraph_dir [file join $env(DBCCP4I_TOP) application]

# Find the Graphviz dot program
set dot [FindExecutable dot]
if { [file exists $dot] } {
    set dot_dir [file dirname $dot]
} else {
    puts "Graphviz \"dot\" program not found, stopping."
    exit 1
}

if { ![file exists [file join $dotgraph_dir dotgraph.tcl]] } {
    puts "Failed to locate dotgraph.tcl in $dotgraph_dir"
    exit 1
}
source [file join $dotgraph_dir dotgraph.tcl]
if { ![dotgraph_init $dot_dir] } {
    puts "Failed to initialise the dotgraph package"
    puts "Maybe you need to reset the variable \"dot_dir\" to point to your"
    puts "local version of the graphviz \"dot\" program?"
    exit 1
}
if { [dotgraph_version < 0.0.2] } {
    # Needs dotgraph or better 0.0.2
    puts "Needs dotgraph 0.0.2 - this is version [dotgraph_version]"
    exit
}

# get dbviewer preferences
if { ![dbviewer_initialise_preferences] } {
    puts "Failed to load preferences, quitting."
    exit 1
}

# Collect the command line arguments
set project {}
set jobid {}
set dirsfile {}
set hostname "localhost"
set user_title {}
set i 0
while { $i < [llength $argv] } {
    set arg [lindex $argv $i]
    switch -exact -- $arg {
	"-directories" {
	    # Specify a non-default directories.def file
	    incr i
	    set dirsfile [lindex $argv $i]
	}
	"-remote" {
	    # Should be followed by a hostname and port specification
	    # i.e. <host>:<port>
	    incr i
	    if { [regexp -- "(\[A-Za-z0-9\.\]+):(\[0-9\]+)" \
		      [lindex $argv $i] m remotehost port] } {
		puts "Remote host = $remotehost"
		puts "Port = $port"
		set hostname $remotehost
	    } else {
		puts "Failed to match: [lindex $argv $i]"
	    }
	}
	"-title" {
	    # Should be followed by a title string
	    incr i
	    set user_title [lindex $argv $i]
	}
	default {
	    if { $i == 0 } {
		# First argument is project name
		set project $arg
	    } elseif { $i == 1 } {
		# Second argument is jobid
		set jobid $arg
	    } else {
		puts "Unrecognised argument \"$arg\""
	    }
	}
    }
    incr i
}

# Connect to the database server
set connectCmd [list DbHandlerConnect dbviewer -broadcastHandler handlebroadcast]
if { $dirsfile != "" } {
    lappend connectCmd "-directories" "$dirsfile"
}
if { $hostname != "localhost" } {
    lappend connectCmd "-host" "$hostname" "-port" "$port"
}
if { ![eval $connectCmd] } {
    WarningMessage "Failed to connect to the handler"
    exit 1
}

# Initialise directories data for use by CCP4i components
if { [llength [info procs InitialiseDirectories]] != 1 } {
    # Use this for CCP4i pre-2.0
    InitialisePreferences directories directories
} else {
    # Use this for CCP4i 2.0
    InitialiseDirectories
}

# initialise dbviewer
dbviewer_initialise

# set the window title
dbviewer_set_title $user_title
update_application_title

# Create the main application window
create_main_window

# Info display
toplevel .nodeinfo -borderwidth 1 -background black
label .nodeinfo.label -background white
pack .nodeinfo.label -side left -fill y
wm overrideredirect .nodeinfo 1
wm withdraw .nodeinfo

 #balloonhelp 
toplevel .balloonhelp -borderwidth 1 -background black 
label .balloonhelp.info -background white
pack .balloonhelp.info -side left -fill y
wm overrideredirect .balloonhelp 1
wm withdraw .balloonhelp

if { $project == "" } {
    # is there a current project defined in the
    # preferences?
    if { $dbviewer(CURRENT_PROJECT) != "" } {
	set project $dbviewer(CURRENT_PROJECT)
    }
}
set projects [ListProjects]
if { [lsearch $projects $project] < 0 } {
    # get the first project
    if { $projects != 0 } {
	set project [ lindex $projects 0 ]
    } else {
	WarningMessage "No projects found"
    }
}
if { $jobid != "" } {
    select_project_db $project $jobid
} else {
    select_project_db $project
}

# Start the periodic check for updates
after $ccp4i_db_viz(REFRESH_INTERVAL) refresh_viewer
