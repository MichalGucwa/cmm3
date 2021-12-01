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
# Loggraph - program to display graphs from CCP4 log files
# Written by Darren Spruce  spruce@esrf.fr
# Updated by Liz Potterton Dec 1997
# And again by Peter Briggs during 1999
# For Tcl/Tk versions 8.0 and Blt2.4
#---------------------------------------------------------------------

global env
global system
global typedef
global configure
global loggraph
global data
global stuff

#CCP4I interface setup

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
  source [SearchPath TOP loggraph printgraph.tcl]
  source [SearchPath TOP loggraph features.tcl]
  source [SearchPath TOP loggraph bltGraph.tcl]
  source [SearchPath TOP loggraph blt_graph.def]

  CreateSessionLog
  InitialisePreferences loggraph loggraph
  InitialisePreferences preferences preferences
  InitialisePreferences status ccp4i_status
  InitialiseDirectories


# set default printers to first in the menu - the printer menu is 
# defined in $CCP4I_TOP/etc/loggraph.def
  set loggraph(COLOUR_PRINTER) [lindex [GetTypeInfo loggraph COLOUR_PRINTER deflist] 0 ]
  set loggraph(MONO_PRINTER) [lindex [GetTypeInfo loggraph MONO_PRINTER deflist] 0  ]
  set blt_library $configure(BLT_LIBRARY)

#--------------------------------------------------------------------
proc initstuff {stuffVar } {
#--------------------------------------------------------------------
  upvar #0 $stuffVar stuff
  global configure
# Initialise parameters just to say we have nothing displayed
  set stuff(currenttable) 0
  set stuff(currentgraph) 0
  set stuff(nelements) 0
  set stuff(nmarkers)  0
# Initialise for display of legend (not sure where this should go)
  set stuff(legendhide) no
  set stuff(legendanchor) ne
  set stuff(legendraised) no
  set stuff(legendopaque) ""
  set stuff(legendfont)   "*-Helvetica-Bold-R-Normal-*-12-120-*"
# Initialise font for title
  set stuff(titlefont)    "*-Helvetica-Bold-R-Normal-*-14-140-*"
# Initialise fonts for axis and tick labels
  set stuff(xaxisfont)    "*-Helvetica-Bold-R-Normal-*-12-120-*"
  set stuff(xtickfont)    "*-Helvetica-Medium-R-Normal-*-10-100-*"
  set stuff(yaxisfont)    "*-Helvetica-Bold-R-Normal-*-12-120-*"
  set stuff(ytickfont)    "*-Helvetica-Medium-R-Normal-*-10-100-*"
# Set the defaults for the file browser - these will be updated if
# the user changes directory or file type
  set stuff(defdir) TEMPORARY
  set stuff(format) LOG
}

#--------------------------------------------------------------------
proc create_main_win { } {
#--------------------------------------------------------------------
  global stuff
  global configure

  wm withdraw .
  wm title . "CCP4Interface Loggraph"
  wm iconbitmap . @[SearchPath TOP icons window_icon]
  set f [frame .f]
#  pack $f -fill both -expand yes
  grid columnconfigure . 0  -weight 1
  grid rowconfigure . 0  -weight 1
  grid $f -row 0 -column 0  -sticky nswe
  set m [frame $f.m \
	-relief raised \
	-background $configure(COLOUR_CONTRAST) \
	-bd 2]
  grid $m -row 0 -column 0  -sticky nswe
#  pack $m -fill x
  set mb [menubutton $m.file -text File \
	-menu $m.file.f \
        -background $configure(COLOUR_CONTRAST) \
	-underline 0]
  set mc [menubutton $m.com -text Appearance \
	-menu $m.com.f \
        -background $configure(COLOUR_CONTRAST) \
	-underline 0]
  pack $mb $mc -side left
  set medit [menubutton $m.edit -text "Edit" \
        -menu $m.edit.f \
        -background $configure(COLOUR_CONTRAST) \
        -underline 0]
  pack $mb $mc $medit -side left
  set mutil [menubutton $m.util -text Utilities \
        -menu $m.util.f \
        -background $configure(COLOUR_CONTRAST) \
	-underline 0]
  pack $mb $mc $medit $mutil -side left

  set mh [button $m.help -text Help \
        -bd 2 \
	-command  "open_url [ SearchPath HELP general loggraph.html] " ]
  pack $mh -side right

  

  #
  # separate screen into panes using grid
  #

  frame $f.pane
  grid $f.pane -row 1 -column 0  -sticky nswe
#  pack $f.pane -side top -fill both
  grid rowconfigure $f 0   -weight 0
  grid rowconfigure $f 1   -weight 1
  grid columnconfigure $f 0   -weight 1
  set p1 [frame $f.pane.p1]
  set p2 [frame $f.pane.p2]
  set p3 [frame $f.pane.p3]
  grid $p1 -row 0 -column 0 -sticky  nsew
  grid $p2 -row 1 -column 0 -sticky  ewns
  grid $p3 -row 2 -column 0 -sticky  ewns
  grid columnconfigure $f.pane 0 -weight 1
  grid rowconfigure $f.pane 0 -weight 1
  grid rowconfigure $f.pane 1 -weight 0
  grid rowconfigure $f.pane 2 -weight 0

  create_graph_win $p1
  create_list $p2 $p3

# Th top menu bar

  set mf [menu $m.file.f \
	-tearoff 0 ]
  $mf add command -label "Open File" \
	-command { open_file } \
	-underline 0
# PJX: command to "spawn" new viewer: commented out for now
#  $mf add command -label "Spawn New Viewer" \
#	-command { spawn_viewer } \
#	-underline 0
  $mf add command -label "Print Graph" \
	-command { create_print_win loggraph $stuff(graphframe) } \
	-underline 0
  $mf add separator
  $mf add command -label "Exit" \
      -command { ExitLoggraph } \
	-underline 0

  set mc [menu $m.com.f]
  $mc add checkbutton -label "Resolution" \
        -variable loggraph(USE_RESOLUTION) \
        -command "plot_data stuff data" \
        -selectcolor $configure(COLOUR_BOLD) \
        -underline 0
  $mc add checkbutton -label "Colour" \
	-variable loggraph(USE_COLOUR) \
        -command "configure_plot stuff" \
        -selectcolor $configure(COLOUR_BOLD) \
	-underline 0
  $mc add checkbutton -label "Linestyle" \
        -variable loggraph(USE_PATTERN) \
        -command "configure_plot stuff" \
        -selectcolor $configure(COLOUR_BOLD) \
        -underline 0
  $mc add checkbutton -label "Symbols" \
        -variable loggraph(USE_SYMBOLS) \
        -command "configure_plot stuff" \
        -selectcolor $configure(COLOUR_BOLD) \
        -underline 0
   $mc add command -label "Customise Styles" \
	-command  "customise_linestyle loggraph" \
	-underline 0

  set medit [menu $m.edit.f \
        -postcommand "select_display data $m.edit.f" \
	-tearoff 1 ]
  $medit add command -label "Title&Legend" \
        -command  {edit_titles data $stuff(currentgraph)} \
        -underline 0
  $medit add command -label "Add annotation" \
	-command  {annotate} \
        -underline 0
  $medit add command -label "Delete all annotation" \
	-command  {delete_all_annotation stuff} \
        -underline 0
  $medit add command -label "Display.." \
	-font $configure(FONT_ITALIC) \
        -underline 0

  set mutil [menu $m.util.f]
  $mutil add command -label "Zoom" \
	-command  {enable_zoom stuff} \
        -underline 0
  $mutil add command -label "Display Table" \
	-command  "display_table" \
	-underline 0  

  wm deiconify .

  crosshairs_position
}

#-------------------------------------------------------------------------
proc create_list { p2 p3 } {
#-------------------------------------------------------------------------
  #
  # Create list for the tables
  global stuff
  set select_colour "#ffcc66"
  #
  frame $p2.f1 -relief sunken
  pack $p2.f1 -side top -fill x -expand 1
  set stuff(position_label) [label $p2.f1.l1 \
	-text "Cursor:" ]
  set stuff(closest_label) [label $p2.f1.l2 \
        -text "Closest:" ]
  pack $p2.f1.l1 -side left 
  pack $p2.f1.l2 -side right 

  label $p2.title -text "Tables in File"
  pack $p2.title -side top -fill x -expand 1
  set pl [frame $p2.pl ]
  pack $pl -side top -fill both -expand 1

  set stuff(p3) $p3
  set stuff(p2) $p2

  set stuff(tablelist) [listbox $pl.lb \
	-relief sunken \
	-yscroll "$pl.sbv set" \
	-selectmode single\
	-selectbackground $select_colour \
	-height 5 ]

  bind  $stuff(tablelist) <ButtonRelease-1> \
     { expand_table_list stuff data [%W nearest %y]}
  scrollbar $pl.sbv \
	-orient vertical \
	-relief sunken \
	-width 10 \
       -command "$pl.lb yview"
  pack $pl.sbv -side right -fill y
  pack $stuff(tablelist) -side left -fill both -expand yes

  #
  # create list for the graphs
  #

  label $p3.title -text "Graphs in Selected Table"
  pack $p3.title -side top -fill x -expand 1
  set pr [frame $p3.pr ]
  pack $pr -side top -fill both -expand 1

  set stuff(graphlist) [listbox $pr.lb \
	-relief sunken \
	-yscroll "$pr.sbv set" \
	-selectmode single \
	-selectbackground $select_colour \
	-height 5 ]
  scrollbar $pr.sbv -orient vertical \
	-relief sunken \
	-width 10 \
        -command "$pr.lb yview"
  pack $pr.sbv -side right -fill y
  pack $stuff(graphlist) -side left -fill both -expand yes
}

#----------------------------------------------------------------
proc configure_plot { arrayname } {
#----------------------------------------------------------------
  upvar #0 $arrayname stuff
  global loggraph
  set g $stuff(graphframe)

  for { set counter 1 } { $counter <= $stuff(nelements) } { incr counter } {
  if $stuff(visible,$counter) {
    set style [expr $counter%$loggraph(NLINESTYLES) ]
    set name $stuff([Indxv elements $counter])
    if { $loggraph(USE_COLOUR) } {
      set colour $loggraph([Indxv LINECOLOUR $style ])
    } else {
      set colour black
    }
    if { $loggraph(USE_SYMBOLS) } {
      set symbol $loggraph([Indxv SYMBOL $style ])
      set symbolsize $loggraph([Indxv SYMBOLSIZE $style ])
      if { $symbolsize == "" } { set symbolsize $loggraph(DEF_SYMBOLSIZE) }
    } else {
      set symbol circle 
      set symbolsize $loggraph(DEF_SYMBOLSIZE)
    }
    if { $loggraph(USE_PATTERN) } {
      set linewidth $loggraph([Indxv LINEWIDTH $style ])
      if { $linewidth == "" } { set linewidth  $loggraph(DEF_LINEWIDTH) }
      set dashes [GetValue loggraph [Indxv PATTERN $style] ]
    } else {
      set linewidth $loggraph(DEF_LINEWIDTH)
      set dashes {}
    }
    # override linewidth if scatter plot
    if { $stuff(linewidth) == 0 } { set linewidth 0 }
    
    # Don't try and configure a non-existent element
    # e.g. from an empty table or graph
    if {[$g element exists $name]} {
	$g element configure $name \
		-color $colour \
		-symbol $symbol \
		-pixels $symbolsize \
		-linewidth $linewidth \
		-dashes $dashes
    }
  } }

  # Reconfigure the legend position
  $g legend configure -hide $stuff(legendhide) \
	  -anchor $stuff(legendanchor) \
          -font $stuff(legendfont) \
          -raised $stuff(legendraised) \
          -background $stuff(legendopaque) \
          -borderwidth 0

  # Set the markers for annotation
  #
  # It is best to "create" them each time
  #
  for { set counter 1 } { $counter <= $stuff(nmarkers) } { incr counter } {

    # Only create those markers associated with the current graph
    set ann_graph $stuff(ANN_GRAPH,$counter)
    set ann_name  marker_$counter
    if { $ann_graph == $stuff(currentgraph) } then {

      # Bind each marker to invoke its own edit window
      set cmd2 [list edit_annotation $counter ]
      set cmd [list $g marker bind clickon$counter <Double-1> $cmd2 ]
      eval $cmd

      # Set up temporary variables and create marker
      set ann_text  $stuff(ANN_TEXT,$counter)
      set ann_x_pos $stuff(ANN_XPOS,$counter)
      set ann_y_pos $stuff(ANN_YPOS,$counter)
      set ann_d_rot $stuff(ANN_DROT,$counter)
      set ann_colour $stuff(ANN_COLOUR,$counter)
      set ann_font   $stuff(ANN_FONT,$counter)

      $g marker create text -name $ann_name \
          -outline $ann_colour \
	  -coords { $ann_x_pos $ann_y_pos } \
          -text [subst $ann_text] \
          -bindtags clickon$counter \
          -rotate $ann_d_rot \
          -fill "" \
          -font $ann_font

    } else {
    # Better make sure that any markers not on the current graph
    # are removed
      if [ $g marker exists $ann_name ] {
        $g marker delete $ann_name
      }
    }
  }
}

#----------------------------------------------------------------
proc configure_xmgr_plot { arrayname } {
#----------------------------------------------------------------
# This is intended to override the linestyle settings that have
# been set by the user or are defaults for loggraph
  upvar #0 $arrayname stuff
  global loggraph
  global xmgr_data
  
  if { $loggraph(USE_SYMBOLS) || $loggraph(USE_PATTERN) } {
      # The user has set up some custom styles so we
      # need to reset the parameters to disable custom
      # linestyles and symbols
      set loggraph(USE_SYMBOLS) 0
      set loggraph(USE_PATTERN) 0
  }

  # Apply customised stuff for XMGR plot
  set g $stuff(graphframe)

  for { set counter 1 } { $counter <= $stuff(nelements) } { incr counter } {
  if $stuff(visible,$counter) {
    set style [expr $counter%$loggraph(NLINESTYLES) ]
    set name $stuff([Indxv elements $counter])
    set symbol none
    set symbolsize 0
    # Colours
    if { $loggraph(USE_COLOUR) } {
       set colour $loggraph([Indxv LINECOLOUR $style ])
    } else {
       set colour black
    }
    # Customise ROGUEPLOT
    if { $xmgr_data(TYPE) == "SCALA_ROGUEPLOT" } {
	# Configure the symbols for the outliers
	# to be black circles
	if { $xmgr_data(SYMBOL_$name) } {
	    set symbol circle 
	    set symbolsize 3
	    set colour black
	}
	# Configure the line colours especially for rogueplots
	# This makes the outer circle, crosshairs and scatter points
	# black and the rest red
	# It's pretty much done by black magic...
	if { $counter < 4 || $counter == 7 } {
	    set colour black
	} else {
	    set colour red
	}
    } else {
	# Other plots
	if { $xmgr_data(SYMBOL_$name) } {
	    # By default use small circles
	    set symbol circle 
	    set symbolsize 3
	}
    }
    if { $xmgr_data(LINESTYLE_$name) } {
       set linewidth $loggraph(DEF_LINEWIDTH)
    } else {
       # No lines
       set linewidth 0
    }
    set dashes {}
    
    # Don't try and configure a non-existent element
    # e.g. from an empty table or graph
    if {[$g element exists $name]} {
	$g element configure $name \
		-color $colour \
		-symbol $symbol \
		-pixels $symbolsize \
		-linewidth $linewidth \
		-dashes $dashes
    }
  } }

  # Reconfigure the legend position
  # Always put it at the bottom righthand corner
  $g legend configure -anchor se

  # Rescale the window to make it square
  # Set the shorter dimension to be the same size as the
  # the longer one
  # This is most useful for the ROGUEPLOT output of Scala
  # which displays ice rings as circles
  set height [lindex [$g configure -height] end]
  set width [lindex [$g configure -width] end]
  if { $height > $width } {
      $g configure -width $height
  } else {
      $g configure -height $width
  }

  # Set the markers for annotation
  #
  # It is best to "create" them each time
  #
  for { set counter 1 } { $counter <= $stuff(nmarkers) } { incr counter } {

    # Only create those markers associated with the current graph
    set ann_graph $stuff(ANN_GRAPH,$counter)
    set ann_name  marker_$counter
    if { $ann_graph == $stuff(currentgraph) } then {

      # Bind each marker to invoke its own edit window
      set cmd2 [list edit_annotation $counter ]
      set cmd [list $g marker bind clickon$counter <Double-1> $cmd2 ]
      eval $cmd

      # Set up temporary variables and create marker
      set ann_text  $stuff(ANN_TEXT,$counter)
      set ann_x_pos $stuff(ANN_XPOS,$counter)
      set ann_y_pos $stuff(ANN_YPOS,$counter)
      set ann_d_rot $stuff(ANN_DROT,$counter)
      set ann_colour $stuff(ANN_COLOUR,$counter)
      set ann_font   $stuff(ANN_FONT,$counter)

      $g marker create text -name $ann_name \
          -outline $ann_colour \
	  -coords { $ann_x_pos $ann_y_pos } \
          -text [subst $ann_text] \
          -bindtags clickon$counter \
          -rotate $ann_d_rot \
          -fill "" \
          -font $ann_font

    } else {
    # Better make sure that any markers not on the current graph
    # are removed
      if [ $g marker exists $ann_name ] {
        $g marker delete $ann_name
      }
    }
  }
}

#----------------------------------------------------------------
proc translate_scala_xmgr_labels { label } {
#----------------------------------------------------------------
# This attempts to turn special sequences in SCALA's XMGR labels
# (e.g. \8d\0) into text (e.g. delta)
# This is very kludgely so maybe a better fix can be implemented
    set translated_label ""
    for { set i 0 } { $i < [string length $label] } { incr i } {
	set c [string index $label $i]
	if { $c == "\\" } {
	    set c "ESC"
	}
	append translated_label $c
    }
    # For Windows: escape sequences appear to be doubled
    # So: remove double ESC...
    regsub -all "ESCESC" $translated_label "ESC" translated_label
    # Delta sequence will be "ESC8dESC0"
    regsub -- "ESC8dESC0" $translated_label "delta" translated_label
    return $translated_label
}

#-------------------------------------------------------------------------
proc expand_table_list { stuffVar dataVar it } {
#-------------------------------------------------------------------------
  upvar #0 $stuffVar stuff
  upvar #0 $dataVar data
  set currenttable [expr $it + 1 ]
  if { ![ElementExists data [Indxv TABLE_GRAPHS $currenttable] ] } { return }
  set stuff(currenttable) $currenttable
  set stuff(currentgraph) ""
  $stuff(graphlist) delete 0 end
  foreach ig $data([Indxv TABLE_GRAPHS $currenttable ]) {
    $stuff(graphlist) insert end $data([Indxv GRAPH_TITLE $ig])
  }
  plot_data0 stuff data 0
}

#-------------------------------------------------------------------------
proc create_graph_win { p } {
#-------------------------------------------------------------------------
  global system
  global stuff

  set graphframe  $p.g

  if { $system(TK_VERSION) < 8.0 } {

    set graphframe [graph $p.g \
        -plotbackground white \
        -bg white   \
        -plotrelief flat \
        -plotborderwidth 2 ]
  } else {
    set graphframe [blt::graph $p.g \
	-plotbackground white \
	-bg white   \
	-plotrelief flat \
	-plotborderwidth 2 ]
  }

  grid $graphframe -row 0 -column 0  -sticky nswe
  grid columnconfigure $p 0  -weight 1
  grid rowconfigure $p 0  -weight 1
  

  set stuff(graphframe) $graphframe
  set stuff(XLABEL) X

  $graphframe axis configure x \
	-ticklength 5 \
	-loose true

  $graphframe axis configure y \
	-ticklength 5 \
	-loose true \
	-title {}

# If can find right format this migh t be useful: -subticks 4 \

  $graphframe legend configure \
        -hide no \
        -anchor $stuff(legendanchor) \
	-position plotarea \
	-font -*-helvetica-medium-r-normal-*-10-*-*-*-*-*-*-* \
	-relief flat \
	-bg white

  #SetCrosshairs $g.g
#  SetActiveLegend $graphframe
  SetClosestPoint $graphframe
  Blt_ZoomStack $graphframe
  Blt_Crosshairs $graphframe

}

#---------------------------------------------------------------------------
proc open_file { { format {} } { file {}}  } {
#---------------------------------------------------------------------------
  global stuff

   if { $file == "" } {
    set filter "*.[string tolower $stuff(format)]"
    if { ![SelectFile file_defdir_type -title "Open File" \
        -defdir $stuff(defdir) \
        -filetype $stuff(format) graph_file_types \
        -filter $filter \
        -return {filename defdir filetype} ] } { return }
     set stuff(defdir) [lindex $file_defdir_type 1]
     set stuff(format) [lindex $file_defdir_type 2 ]
# PJX: file selection didn't work until I inverted the commenting
# on the next 3 lines -  but why was it set like this anyway?
#     set file [lindex $file_defdir_type 0]
     set file [FileJoin [GetDefaultDirPath $stuff(defdir)] \
		[lindex $file_defdir_type 0] ]
   } else {
     set stuff(format) $format
   }
   if { [file exist $file ] } {
     if { [extract_tables_from_file $file $stuff(format) data] } {
       load_listbox data }
  }

  return 1
}

#--------------------------------------------------------------------
proc load_listbox { arrayname } {
#--------------------------------------------------------------------
  upvar #0 $arrayname data
  global stuff
 
  if { $data(NTABLES) <= 0 } { return }
  $stuff(tablelist) delete 0 end
  for { set n 1 } { $n <=  $data(NTABLES) } { incr n } {
    $stuff(tablelist) insert end $data([Indxv TABLE_TITLE $n])
  }

  $stuff(graphlist) configure -selectmode single
  bind  $stuff(graphlist) <ButtonRelease-1> { 
    plot_data0 stuff data [%W nearest %y]
  }
  $stuff(graphlist) delete 0 end

# Always redisplay the first graph after loading

  if { $data(NTABLES) >= 1 } {
    set stuff(currenttable) 1
    $stuff(tablelist) selection set 0 0
    expand_table_list stuff data 0
    if { $data(NGRAPHS) == 1 } {
      set stuff(currentgraph) 1
      plot_data stuff data
      $stuff(graphlist) selection set 0 0
    }
  }

# Deal with display of the listbox

  update_listbox_display
}

#----------------------------------------------------------------------
proc update_listbox_display { } {
#----------------------------------------------------------------------
# Show or hide the listboxes with the graphs and tables depending on
# how many tables and graphs there are
  global stuff
  global data

  set p2 $stuff(p2)
  set p3 $stuff(p3)

  if { $data(NTABLES) == 1 && $data(NGRAPHS) == 1 } {
      # No need to show the listboxes - there is only
      # one graph in this file to display
      pack forget $p2.title $p2.pl
      grid forget $p3
  } else {
      pack $p2.title -after $p2.f1 -side top -fill x -expand 1
      pack $p2.pl -after $p2.title \
	  -side top -fill both -expand 1
      grid $p3 -row 2 -column 0 -sticky  ewns
  }
    
}
#----------------------------------------------------------------------
proc make_clean_list { str sp} {
#----------------------------------------------------------------------
  set parts ""
  # get rid of keyword
  set pts [lrange [split $str $sp] 1 end]
  foreach el $pts {
    if { [string length [string trim $el " "]] > 0 } { lappend parts $el }
  }
  return $parts
}

#-----------------------------------------------------------------------
proc customise_linestyle { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  set w .linestyle
  if ![OpenWindow $w "Customise Lines" "Lines" -message ] { return }

  CreateFrame $w loggraph 
  CreateButton $w apply "Apply" "configure_plot stuff"
  CreateButton $w dismiss "Save&Exit" "save_linestyle $arrayname; destroy $w"

  CreateLine line \
    message "Line width for all lines with unspecified line width" \
    label "Where unspecified default line width"  \
    widget DEF_LINEWIDTH \
	-width 2 \
    message "Symbol size for symbols with unspecified size" \
    label "default symbol size" \
    widget DEF_SYMBOLSIZE \
	-width 2

  CreateLineTemplate  LINESTYLE { 0.0 0.05 0.25 0.68 0.73 0.95  }

  CreateLine line \
    label "" \
    label "" \
    label "Line pattern & width" \
    label "" \
    label "Symbol & size" \
    label "" \
    format template LINESTYLE

  CreateExtendingFrame NLINESTYLES linestyles \
	"Define linestyles" "Add Linestyle" \
	[ list LINECOLOUR \
	LINEWIDTH \
	PATTERN \
	SYMBOL \
	SYMBOLSIZE ]

  CloseFrame
}

#--------------------------------------------------------------------
proc linestyles { arrayname counter } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array

  CreateLine line \
    label "$counter" \
    widget LINECOLOUR \
    widget PATTERN \
    widget LINEWIDTH \
	-width 2 \
    widget SYMBOL \
    widget SYMBOLSIZE \
	-width 2 \
    format template LINESTYLE
}

#------------------------------------------------------------------
proc save_linestyle {arrayname } {
#------------------------------------------------------------------
   upvar #0 $arrayname array
   SavePreferences loggraph $arrayname
   configure_plot stuff
}

#---------------------------------------------------------------------
proc enable_zoom { dataVar } {
#---------------------------------------------------------------------
#
  upvar #0 $dataVar data
  set graphframe $data(graphframe)
  Blt_EnableZoom $graphframe
}

#---------------------------------------------------------------------
proc annotate {  } {
#---------------------------------------------------------------------
#
  global stuff
  set graph $stuff(graphframe)

  # Set up bindings for selecting position in the graph
  # Button 1 to select position
    bind $graph <1> { 
        create_new_annotation %W %x %y
    }
  # Button 3 to exit - must also restore previous bindings
    bind $graph <ButtonPress-3> {
        annotate_cancel
    }
  # Set marker to issue a message
    set title "Click in window to set \n position of text"
    $graph marker create text -name "annotateTitle" -text $title \
	-bg yellow  \
        -justify left \
	-coords {-Inf Inf} -anchor nw -bg {}
}

#---------------------------------------------------------------------
proc annotate_cancel {  } {
#---------------------------------------------------------------------
#
  global stuff

  # Delete marker with info...
  set graph $stuff(graphframe)
  catch "$graph marker delete annotateTitle"

  # Restore bindings for zoom
  bind $graph <1> {  }
  bind $graph <ButtonPress-3> { Blt_ResetZoom %W }
}

#---------------------------------------------------------------------
proc create_new_annotation { graph x y } {
#---------------------------------------------------------------------
#
  global stuff

  # Delete marker with info and reset bindings
  set graph $stuff(graphframe)
  catch "$graph marker delete annotateTitle"
  bind $graph <1> {  }
  bind $graph <ButtonPress-3> { Blt_ResetZoom %W }

  # Convert x,y to correct co-ordinates
  set grxy [$graph invtransform $x $y]
  set x [format %-8.4f [lindex $grxy 0]]
  set y [format %-8.4f [lindex $grxy 1]]

  # Create new marker
  incr stuff(nmarkers)
  set i $stuff(nmarkers)
  set stuff(ANN_TEXT,$i) ""
  set stuff(ANN_XPOS,$i) $x
  set stuff(ANN_YPOS,$i) $y
  set stuff(ANN_DROT,$i) 0.0
  set stuff(ANN_COLOUR,$i) "black"
  set stuff(ANN_GRAPH,$i) $stuff(currentgraph)
  set stuff(ANN_FONT,$i) "*-Helvetica-Medium-R-Normal-*-12-120-*"

  # Open the edit window
  edit_annotation $i

}

#---------------------------------------------------------------------
proc edit_annotation { i } {
#---------------------------------------------------------------------
  global annedit stuff

  # Open a separate window for annotation
  set w .annotate
  if ![OpenWindow $w "Edit Annotation" "Annotation" ] { return }

  # Make the frame and the exit, add and apply buttons
  CreateFrame $w annedit
  CreateButton $w dismiss "Exit"      "check_visible stuff annedit ; unset annedit ; destroy $w"
  CreateButton $w apply   "Apply"     "apply_edit_annotate stuff annedit"
  CreateButton $w move    "Move"      "move_annotation"
  CreateButton $w delete  "Delete"    "delete_annotation $i stuff ; destroy $w"

  # Define the menus for different fonts etc
  # This is probably in the wrong place as it should be reuseable...eg
  # for titles, legends, axis labels etc

  # Type of font: courier, helvetica, times
#  DefineMenu _loggraph_fontname [ list \
#	  "Courier" "Helvetica" "Times" ]

  # Style of font: bold, italic or normal
#  DefineMenu _loggraph_fontstyle [ list \
#          "Normal" "Bold" "Italic" "BoldItalic" ]

  # Size of font: no of points
#  DefineMenu _loggraph_fontsize [ list \
#          "8" "10" "12" "14" "18" "24" ]

  # Set the parameters to be edited:
  DefineVariable annedit ann_count  _int  $i
  DefineVariable annedit ann_text   _text $stuff(ANN_TEXT,$i)
  DefineVariable annedit ann_xpos   _real $stuff(ANN_XPOS,$i)
  DefineVariable annedit ann_ypos   _real $stuff(ANN_YPOS,$i)
  DefineVariable annedit ann_drot   _real $stuff(ANN_DROT,$i)
  DefineVariable annedit ann_colour _colour $stuff(ANN_COLOUR,$i)

  # Deal with the font
  break_font $stuff(ANN_FONT,$i) afontname afontstyle afontsize
  DefineVariable annedit ann_fname  _fontname  $afontname
  DefineVariable annedit ann_fstyle _fontstyle $afontstyle
  DefineVariable annedit ann_fsize  _fontsize  $afontsize
#  DefineVariable annedit ann_fname  _loggraph_fontname  $afontname
#  DefineVariable annedit ann_fstyle _loggraph_fontstyle $afontstyle
#  DefineVariable annedit ann_fsize  _loggraph_fontsize  $afontsize

  CreateLine line label {Insert \\n in the text box to obtain multiple lines of text} \
                  -italic

  CreateLine line label "Text:" widget ann_text -width 70

  CreateLine line label "Position: x" widget ann_xpos \
                  label "y" widget ann_ypos \
                  label "Rotation (deg.)" widget ann_drot \
                  label "Colour" widget ann_colour

  CreateLine line label "Font" widget ann_fname widget ann_fstyle \
                  label "Size" widget ann_fsize

  CloseFrame
}

#---------------------------------------------------------------------
proc move_annotation { } {
#---------------------------------------------------------------------
 #
  global stuff
  set graph $stuff(graphframe)

  # Set up bindings for selecting position in the graph
  # Button 1 to select position
    bind $graph <1> { 
        new_position_annotation %W %x %y
    }
  # Button 3 to exit - must also restore previous bindings
    bind $graph <ButtonPress-3> {
        annotate_cancel
    }
  # Set marker to issue a message
    set title "Click in window to set \n new position of text"
    $graph marker create text -name "annotateTitle" -text $title \
	-bg yellow  \
        -justify left \
	-coords {-Inf Inf} -anchor nw -bg {}
}

#---------------------------------------------------------------------
proc new_position_annotation { graph x y } {
#---------------------------------------------------------------------
#
  global annedit stuff

  # Delete marker with info and reset bindings
  set graph $stuff(graphframe)
  catch "$graph marker delete annotateTitle"
  bind $graph <1> {  }
  bind $graph <ButtonPress-3> { Blt_ResetZoom %W }

  # Convert x,y to correct co-ordinates
  set grxy [$graph invtransform $x $y]
  set x [format %-8.4f [lindex $grxy 0]]
  set y [format %-8.4f [lindex $grxy 1]]

  # Update the position of the marker
  set annedit(ann_xpos) $x
  set annedit(ann_ypos) $y

  # Now apply the changes
  apply_edit_annotate stuff annedit

}

#---------------------------------------------------------------------
proc delete_annotation { i dataVar } {
#---------------------------------------------------------------------
  upvar #0 $dataVar data
  set g $data(graphframe)

  # First must unset this marker and the one that's going to
  # overwrite it
  #
  # First check that it exists
  if [$g marker exists marker_$i] then {
    $g marker delete marker_$i
  }

  set stacktop $data(nmarkers)

  if {$stacktop != $i} then {

  # Check that marker exists before deleting it
    if [$g marker exists marker_$stacktop] then {
      $g marker delete marker_$stacktop
    }

  # Overwrite marker i with data from the top of the stack
    set data(ANN_TEXT,$i) $data(ANN_TEXT,$stacktop)
    set data(ANN_XPOS,$i) $data(ANN_XPOS,$stacktop)
    set data(ANN_YPOS,$i) $data(ANN_YPOS,$stacktop)
    set data(ANN_DROT,$i) $data(ANN_DROT,$stacktop)
    set data(ANN_COLOUR,$i) $data(ANN_COLOUR,$stacktop)
    set data(ANN_FONT,$i)   $data(ANN_FONT,$stacktop)
    set data(ANN_GRAPH,$i)  $data(ANN_GRAPH,$stacktop)
  }

  # Reduce the number of markers by 1
  incr data(nmarkers) -1

  # Apply the changes
  configure_plot stuff
}

#---------------------------------------------------------------------
proc delete_all_annotation { dataVar } {
#---------------------------------------------------------------------
  upvar #0 $dataVar data

  # Make a list of markers in current graph
  set nomark $data(nmarkers)
  set markers ""
  if {$nomark > 0} then {
     for {set i $nomark} {$i >= 1} {incr i -1} {
        set ann_graph $data(ANN_GRAPH,$i)
        if { $ann_graph == $data(currentgraph) } { lappend markers $i }
     }
  } else {
      return
  }

  # If list is empty then nothing to do
  if { [llength $markers] == 0 } { return }

  # Before deleting, check - do you want to do this?
  set action [ChooseOptionDialog "Delete all annotation" "Loggraph" \
    "This will delete all the annotation\n in the current graph" \
    { Abort OK } -default 1 ]

  if [regexp Abort $action] { return 0 }

  # Okay then delete all annotation in the current graph
  foreach {i} $markers {
     delete_annotation $i stuff
  }
}

#---------------------------------------------------------------------
proc apply_edit_annotate { dataVar anneditVar } {
#---------------------------------------------------------------------
  upvar #0 $dataVar data
  upvar #0 $anneditVar annedit

  if {$data(nmarkers) >= 1} {
       set i $annedit(ann_count)
       set data(ANN_TEXT,$i) $annedit(ann_text)
       set data(ANN_XPOS,$i) $annedit(ann_xpos)
       set data(ANN_YPOS,$i) $annedit(ann_ypos)
       set data(ANN_DROT,$i) $annedit(ann_drot)
       set data(ANN_COLOUR,$i) $annedit(ann_colour)

       set data(ANN_FONT,$i) [ make_font $annedit(ann_fname) $annedit(ann_fstyle) $annedit(ann_fsize) ]
  }
# Commented out because apply doesn't exit...
#  unset annedit
  configure_plot stuff
}

#---------------------------------------------------------------------
proc check_visible { dataVar anneditVar } {
#---------------------------------------------------------------------
  upvar #0 $dataVar data
  upvar #0 $anneditVar annedit

# Check that the text in the marker is visible i.e. contains
# more than just spaces or tabs
  if {$data(nmarkers) >= 1} {
     set i $annedit(ann_count)
     set ann_text $data(ANN_TEXT,$i)

  # If text matches a blank line then delete the marker
    if [regexp -- "^\[ \t\]*$" $ann_text] then {
      delete_annotation $i stuff
    }
  }
}

##---------------------------------------------------------------------
#proc spawn_viewer { } {
##---------------------------------------------------------------------
#    catch { exec loggraph & } result
#    return
#}

#---------------------------------------------------------------------
proc make_font { name style size } {
#---------------------------------------------------------------------

  # This procedure builds a string to identify the font we want
  # to use, from 3 components: name (times, helvetica or courier);
  # style (normal, italic, bold, bold-italic); size (points).
  # The result is a string of the form *-Courier-Bold-R-Normal-*-12-120-*

  # The inverse procedure is in break_font, which breaks the string
  # into its components.

  set fontstr ""

  # The name first:
  append fontstr "*-" $name "-"

  # Now sort the style:
  # Is it bold?
  if [regexp "Bold" $style] then {
     append fontstr "Bold"
  } else {
     append fontstr "Medium"
  }
  # Is it italicised?
  # "Times" seems to be a special case
  if [regexp "Italic" $style] then {
    if {$name=="Times"} then {
      append fontstr "-I" 
    } else {
      append fontstr "-O"
    }
  } else {
    append fontstr "-R"
  }

  # Tail end with the size in it
  append fontstr "-Normal-*-" $size "-" $size "0-*"

  return $fontstr
}

#---------------------------------------------------------------------
proc break_font { fontstr nameVar styleVar sizeVar } {
#---------------------------------------------------------------------
  upvar $nameVar  name 
  upvar $styleVar style
  upvar $sizeVar  size

  # This procedure breaks a font string into three components, e.g.
  # *-Courier-Bold-R-Normal-*-120-* will give "Courier" (name),
  # "Bold" (style) and "12" (size)

  # It is the inverse operation to make_font, which reassembles the
  # fontstring from these components.

  set name ""
  set style ""
  set size ""

#  puts "Font string is $fontstr"

  # Identify the name
  if ![regexp {^(\*-)([^-]*)([-])} $fontstr match junk1 name junk2] { set name "Unknown" }

#  puts "Font name is $name"

  # Now sort the style:
  if ![regexp {^(\*-[^-]*[-])([^-]*)([-])(.)} $fontstr match junk1 junk2 junk3 junk4 ] then {
    set style "Unknown"
  } else {

    # Check for Bold:
    if [regexp {Bold} $junk2] then { append style "Bold" }

    # Check for Italics:
    if [regexp {[IO]} $junk4] then { append style "Italic" }

    # Check for Normal (ie anything else):
    if {$style==""} then {
      if [regexp {Medium} $junk2] then { 
        set style "Normal"
      } else { 
        set style "Unknown"
      }
    }
  }

#  puts "Font style is $style"

  # Finally get the size:
  if ![regexp {^(\*-[^\*]*)(\*-)([0-9]+)} $fontstr match junk1 junk2 junk3 ] then {
    set size "Unknown"
  } else {
    set slen [string length $junk3]
    incr slen -1
    set size [string range $junk3 0 $slen ]
  }

#  puts "Font size is $size"


  return
}

#---------------------------------------------------------------------
proc display_table { } {
#---------------------------------------------------------------------
  global loggraph_table_text
  global stuff data

  # Nb this is based on Liz Potterton's idea and suggested code
  # Thanks Liz  :)

  # Set currently selected table and graph
  set it $stuff(currenttable)
  set ig $stuff(currentgraph)
  if { $ig == "" || $ig == 0 } { 
    Report 1 "No graph currently selected"
    return 0
  }

  # Set variable to hold the tabulation
  set loggraph_table_text {}

  # Write titles for table and graph
  append loggraph_table_text "TABLE TITLE:\n" $data(TABLE_TITLE,$it) \n \n \
         "GRAPH TITLE:\n" $data(GRAPH_TITLE,$ig) \n \n

  # Find out how many lines
  set first_column [lindex $data(GRAPH_COLUMNS,$ig) 0]
  set nlines [llength $data(COLUMN_DATA,$first_column)]

  # Write the column titles and equivalent abbreviations
  append loggraph_table_text "COLUMN TITLES:\n"

  # Need to check that abbreviations have been assigned otherwise there
  # will be an error
  # If there is no abbreviation then set it to be the column label
  foreach ic $data(GRAPH_COLUMNS,$ig) {
    if ![info exists data(COLUMN_ABBREV,$ic)] {
       set data(COLUMN_ABBREV,$ic) $data(COLUMN_TITLE,$ic)
    }
    append loggraph_table_text " " [format "%-12s" $data(COLUMN_ABBREV,$ic)] \
           ": "  $data(COLUMN_TITLE,$ic) \n
  }
  append loggraph_table_text \n

  # Write the column titles in a line, in abbreviated form
    foreach ic $data(GRAPH_COLUMNS,$ig) {
    append loggraph_table_text [format "%12s" $data(COLUMN_ABBREV,$ic)]
  }
  append loggraph_table_text \n

  # Write the numbers in the columns
  for { set n 0 } { $n < $nlines } { incr n } {
    foreach ic $data(GRAPH_COLUMNS,$ig) {

  # Need to check that the data is valid
  # This is to stop errors when e.g. words appear in the columns
      set coldata [lindex $data(COLUMN_DATA,$ic) $n]
      if [regexp -- "^\[0-9.-\]*$" $coldata] then {
        append loggraph_table_text [format "%12.2f" $coldata ]
      } else {
        append loggraph_table_text "          * "
      }
    }
    append loggraph_table_text \n
  } 

  # I guess this opens a new window for displaying the tables
  DisplayTextFile {} -textinput loggraph_table_text -font FONT_FIXED \
                     -nomonitor
}

#---------------------------------------------------------------------
proc edit_titles { dataVar ig  } {
#---------------------------------------------------------------------
  upvar $dataVar data
  global tedit stuff
  if { $ig == "" || $ig == 0 } { 
    Report 1 "No graph currently selected"
    return 0
  }
  set w .edit_titles
  if ![OpenWindow $w "Edit Titles" "Titles" ] { return }

  DefineVariable tedit GRAPH_TITLE _text $data(GRAPH_TITLE,$ig)
  DefineVariable tedit YAXIS_TITLE _text $data(GRAPH_YAXIS,$ig)
  foreach col $data(GRAPH_COLUMNS,$ig) {
    DefineVariable tedit COLUMN_TITLE_$col _text $data(COLUMN_TITLE,$col)
  }

  # These next bits define menus for changing the visibility and position
  # of the legends.
  # This is probably in the wrong place but I'm not sure where else
  # it should go - in blt_graph.def maybe? - pjx

  DefineMenu _loggraph_anchor [ list \
	  top \
	  top-left \
	  top-right \
	  centre \
	  left \
	  right \
	  bottom \
	  bottom-left \
	  bottom-right] \
	  [ list n nw ne center w e s sw se]
  DefineVariable tedit LEGEND_ANCHOR _loggraph_anchor $stuff(legendanchor)

  DefineMenu _loggraph_hide [ list visible hidden ] [ list no yes ]
  DefineVariable tedit LEGEND_HIDE _loggraph_hide $stuff(legendhide)

  DefineMenu _loggraph_raised [ list under over ] [list no yes ]
  DefineVariable tedit LEGEND_RAISED _loggraph_raised $stuff(legendraised)

  DefineMenu _loggraph_opaque [ list transparent opaque ] [list "" white ]
  DefineVariable tedit LEGEND_OPAQUE _loggraph_opaque $stuff(legendopaque)

  # Define menus for fonts - these are taken from edit_annotation
  # Type of font: courier, helvetica, times
#  DefineMenu _loggraph_fontname [ list \
#	  "Courier" "Helvetica" "Times" ]

  # Style of font: bold, italic or normal
#  DefineMenu _loggraph_fontstyle [ list \
#          "Normal" "Bold" "Italic" "BoldItalic" ]

  # Size of font: no of points
#  DefineMenu _loggraph_fontsize [ list \
#          "8" "10" "12" "14" "18" "24" ]

  # Set up font variables (lots of them...)
  break_font $stuff(legendfont) lfontname lfontstyle lfontsize
#  DefineVariable tedit LEGEND_FONTNM _loggraph_fontname  $lfontname
#  DefineVariable tedit LEGEND_FONTST _loggraph_fontstyle $lfontstyle
#  DefineVariable tedit LEGEND_FONTSZ _loggraph_fontsize  $lfontsize
  DefineVariable tedit LEGEND_FONTNM _fontname  $lfontname
  DefineVariable tedit LEGEND_FONTST _fontstyle $lfontstyle
  DefineVariable tedit LEGEND_FONTSZ _fontsize  $lfontsize

  break_font $stuff(titlefont) tfontname tfontstyle tfontsize
#  DefineVariable tedit TITLE_FONTNM _loggraph_fontname  $tfontname
#  DefineVariable tedit TITLE_FONTST _loggraph_fontstyle $tfontstyle
#  DefineVariable tedit TITLE_FONTSZ _loggraph_fontsize  $tfontsize
  DefineVariable tedit TITLE_FONTNM _fontname  $tfontname
  DefineVariable tedit TITLE_FONTST _fontstyle $tfontstyle
  DefineVariable tedit TITLE_FONTSZ _fontsize  $tfontsize

  break_font $stuff(xaxisfont) xfontname xfontstyle xfontsize
#  DefineVariable tedit XTITLE_FNTNM _loggraph_fontname  $xfontname
#  DefineVariable tedit XTITLE_FNTST _loggraph_fontstyle $xfontstyle
#  DefineVariable tedit XTITLE_FNTSZ _loggraph_fontsize  $xfontsize
  DefineVariable tedit XTITLE_FNTNM _fontname  $xfontname
  DefineVariable tedit XTITLE_FNTST _fontstyle $xfontstyle
  DefineVariable tedit XTITLE_FNTSZ _fontsize  $xfontsize

  break_font $stuff(xtickfont) xtfontname xtfontstyle xtfontsize
#  DefineVariable tedit XTICK_FNTNM _loggraph_fontname  $xtfontname
#  DefineVariable tedit XTICK_FNTST _loggraph_fontstyle $xtfontstyle
#  DefineVariable tedit XTICK_FNTSZ _loggraph_fontsize  $xtfontsize
  DefineVariable tedit XTICK_FNTNM _fontname  $xtfontname
  DefineVariable tedit XTICK_FNTST _fontstyle $xtfontstyle
  DefineVariable tedit XTICK_FNTSZ _fontsize  $xtfontsize

  break_font $stuff(yaxisfont) yfontname yfontstyle yfontsize
#  DefineVariable tedit YTITLE_FNTNM _loggraph_fontname  $yfontname
#  DefineVariable tedit YTITLE_FNTST _loggraph_fontstyle $yfontstyle
#  DefineVariable tedit YTITLE_FNTSZ _loggraph_fontsize  $yfontsize
  DefineVariable tedit YTITLE_FNTNM _fontname  $yfontname
  DefineVariable tedit YTITLE_FNTST _fontstyle $yfontstyle
  DefineVariable tedit YTITLE_FNTSZ _fontsize  $yfontsize

  break_font $stuff(ytickfont) ytfontname ytfontstyle ytfontsize
#  DefineVariable tedit YTICK_FNTNM _loggraph_fontname  $ytfontname
#  DefineVariable tedit YTICK_FNTST _loggraph_fontstyle $ytfontstyle
#  DefineVariable tedit YTICK_FNTSZ _loggraph_fontsize  $ytfontsize
  DefineVariable tedit YTICK_FNTNM _fontname  $ytfontname
  DefineVariable tedit YTICK_FNTST _fontstyle $ytfontstyle
  DefineVariable tedit YTICK_FNTSZ _fontsize  $ytfontsize

  CreateFrame $w tedit
  CreateButton $w dismiss "Exit"      "unset tedit; destroy $w"
  CreateButton $w apply   "Apply"     "save_edit_titles $dataVar tedit $ig"

  CreateLine line \
    label "Graph Title" \
	-italic

  CreateLine line \
    widget GRAPH_TITLE \
	-width 70

  CreateLine line \
    label "Title font" widget TITLE_FONTNM widget TITLE_FONTST \
    label "Font size" widget TITLE_FONTSZ

  CreateLine line \
    label "Y-Axis Title" \
      -italic

  CreateLine line \
    widget YAXIS_TITLE \
	-width 70

  CreateLine line \
    label "Y-axis label font" widget YTITLE_FNTNM widget YTITLE_FNTST \
    label "Font size" widget YTITLE_FNTSZ

  CreateLine line \
    label "Y-tick label font" widget YTICK_FNTNM widget YTICK_FNTST \
    label "Font size" widget YTICK_FNTSZ

  CreateLine line \
    label "X-Axis Title (title of first column)" \
    -italic

  set col [lindex $data(GRAPH_COLUMNS,$ig) 0]
  CreateLine line \
    widget COLUMN_TITLE_$col \
	-width 70

  CreateLine line \
    label "X-axis label font" widget XTITLE_FNTNM widget XTITLE_FNTST \
    label "Font size" widget XTITLE_FNTSZ

  CreateLine line \
    label "X-tick label font" widget XTICK_FNTNM widget XTICK_FNTST \
    label "Font size" widget XTICK_FNTSZ

  CreateLine line \
    label "Legend (column titles)"  \
	-italic

  foreach col [lrange $data(GRAPH_COLUMNS,$ig) 1 end] {
    CreateLine line \
      label $col \
      widget COLUMN_TITLE_$col \
	-expand
  }

  CreateLine line \
    label "Legend font" widget LEGEND_FONTNM widget LEGEND_FONTST \
    label "Size" widget LEGEND_FONTSZ

  CreateLine line \
    label "Legend Visibility"  \
	-italic

  CreateLine line \
    label "Legend is" \
    widget LEGEND_HIDE

  OpenSubFrame frame \
    -toggle_display LEGEND_HIDE hide [list hidden]

  CreateLine line \
    label "Legend Position" -italic

  CreateLine line \
    label "Legend appears at the"  \
    widget LEGEND_ANCHOR \
    label "and is drawn" \
    widget LEGEND_RAISED \
    label "data points"

  CreateLine line \
    label "Legend background is" \
    widget LEGEND_OPAQUE

  CloseSubFrame

  CloseFrame
}

#-------------------------------------------------------------------------
proc save_edit_titles { dataVar teditVar ig } {
#-------------------------------------------------------------------------
  upvar #0 $dataVar data
  upvar #0 $teditVar tedit
  global stuff

  set data(GRAPH_TITLE,$ig) $tedit(GRAPH_TITLE)
  set data(GRAPH_YAXIS,$ig) $tedit(YAXIS_TITLE)
  foreach col $data(GRAPH_COLUMNS,$ig) {
    set data(COLUMN_TITLE,$col) $tedit(COLUMN_TITLE_$col)
  }
  set stuff(legendanchor) [GetValue tedit LEGEND_ANCHOR ]
  set stuff(legendhide)   [GetValue tedit LEGEND_HIDE ]
  set stuff(legendraised) [GetValue tedit LEGEND_RAISED ]
  set stuff(legendopaque) [GetValue tedit LEGEND_OPAQUE ]

  set stuff(legendfont) [ make_font [GetValue tedit LEGEND_FONTNM] [GetValue tedit LEGEND_FONTST] [GetValue tedit LEGEND_FONTSZ] ]
#  set stuff(legendfontnm) [GetValue tedit LEGEND_FONTNM]
#  set stuff(legendfontst) [GetValue tedit LEGEND_FONTST]
#  set stuff(legendfontsz) [GetValue tedit LEGEND_FONTSZ]

  set stuff(titlefont) [ make_font [GetValue tedit TITLE_FONTNM] [GetValue tedit TITLE_FONTST] [GetValue tedit TITLE_FONTSZ] ]
#  set stuff(titlefontnm) [GetValue tedit TITLE_FONTNM]
#  set stuff(titlefontst) [GetValue tedit TITLE_FONTST]
#  set stuff(titlefontsz) [GetValue tedit TITLE_FONTSZ]

  set stuff(xaxisfont) [ make_font [GetValue tedit XTITLE_FNTNM] [GetValue tedit XTITLE_FNTST] [GetValue tedit XTITLE_FNTSZ] ]
#  set stuff(xtitlefntnm) [GetValue tedit XTITLE_FNTNM]
#  set stuff(xtitlefntst) [GetValue tedit XTITLE_FNTST]
#  set stuff(xtitlefntsz) [GetValue tedit XTITLE_FNTSZ]

  set stuff(yaxisfont) [ make_font [GetValue tedit YTITLE_FNTNM] [GetValue tedit YTITLE_FNTST] [GetValue tedit YTITLE_FNTSZ] ]
#  set stuff(ytitlefntnm) [GetValue tedit YTITLE_FNTNM]
#  set stuff(ytitlefntst) [GetValue tedit YTITLE_FNTST]
#  set stuff(ytitlefntsz) [GetValue tedit YTITLE_FNTSZ]

  set stuff(xtickfont) [ make_font [GetValue tedit XTICK_FNTNM] [GetValue tedit XTICK_FNTST] [GetValue tedit XTICK_FNTSZ] ]
#  set stuff(xtickfntnm) [GetValue tedit XTICK_FNTNM]
#  set stuff(xtickfntst) [GetValue tedit XTICK_FNTST]
#  set stuff(xtickfntsz) [GetValue tedit XTICK_FNTSZ]

  set stuff(ytickfont) [ make_font [GetValue tedit YTICK_FNTNM] [GetValue tedit YTICK_FNTST] [GetValue tedit YTICK_FNTSZ] ]
#  set stuff(ytickfntnm) [GetValue tedit YTICK_FNTNM]
#  set stuff(ytickfntst) [GetValue tedit YTICK_FNTST]
#  set stuff(ytickfntsz) [GetValue tedit YTICK_FNTSZ]

# Don't unset tedit as save_edit_titles no longer precedes
# exit ...
#  unset tedit
  plot_data stuff $dataVar $ig
}

#------------------------------------------------------------------------
proc select_display  { dataVar mm  } {
#------------------------------------------------------------------------
  upvar #0 $dataVar data
  global stuff
  global configure

# Delete the current display select list
#
# Nb: in the following line, ?x? must be the number of items in the
# menu and ?y?=?x?+1 ...
#  if { [$mm index end] > ?x? }  { $mm delete ?y? [$mm index end] }
#
  if { [$mm index end] > 4 }  { $mm delete 5 [$mm index end] }
  set ig $stuff(currentgraph)
  if { $ig == "" || $ig < 1 } { return }
  if { [llength $data(GRAPH_COLUMNS,$ig)] > 1 } {
    set n 0; foreach ic [lrange $data(GRAPH_COLUMNS,$ig) 1 end] { incr n
      $mm add checkbutton -label "$data(COLUMN_TITLE,$ic)" \
        -selectcolor $configure(COLOUR_BOLD) \
        -variable stuff(visible,$n) \
        -command "plot_data stuff $dataVar $ig" \
        -underline 0
    }
  }
}


#---------------------------------------------------------------------------
proc extract_tables_from_file { file filetype arrayname args } {
#---------------------------------------------------------------------------
  upvar #0 $arrayname data
# refresh screen cos file selection tends to leave nasty shadow
  update idletasks

# Default is to initialise the data array unless there is arg -a(ppend)
  if { ![regexp -- -a $args] } {
    set data(FILENAME) $file
    set data(TITLE) [file rootname [file tail $file] ]
    set data(NTABLES) 0
    set data(NGRAPHS) 0
    set data(NCOLUMNS) 0

  # Need to reinitialise fonts, markers etc here
  }
  PleaseWait "..reading $file"
  if { $filetype == {} || ![ReadFile $file input] } { PleaseWait; return 0 }
  PleaseWait

  set data(PARAM_LIST) [list FILENAME TITLE NTABLES NGRAPHS NCOLUMNS TABLE,0 TABLE_PARSED,0 TABLE_TITLE,0  TABLE_GRAPHS,0 TABLE_COLUMNS,0  GRAPH_TITLE,0 GRAPH_YAXIS,0 GRAPH_RANGE,0 GRAPH_COLUMNS,0 COLUMN_TITLE,0 COLUMN_ABBREV,0 COLUMN_DATA,0 ]

  if [regexp LOG $filetype] { set filetype GRAPH }

  if { ![StringSame $filetype GRAPH DAT XMGR] } {
    tk_dialog .load_err "No Tables" "Can not read $filetype format file" \
              warning 0 { OK }

     return 0
  }

  set ntables [extract_tables_from_$filetype $input $arrayname]
  if { $ntables <= 0 } {
    tk_dialog .load_err "No Tables" "No Tables were found in this file." \
              warning 0 { OK }
  } else {
# Diagnostic dump of data to named file
#    SaveArray data "/usr/in21/people/lizp/test/data.def" data
  }
  wm title . "Loggraph [file tail $file]"

  return 1

}
   
#---------------------------------------------------------------------------
proc extract_tables_from_GRAPH  { input arrayname } { 
#---------------------------------------------------------------------------
  upvar #0 $arrayname data
  global loggraph

# Split the file input elments separated by $'s
# Scan through for elements containing words TITLE or GRAPH and parse
# these and the following elements

  set initial_ntables $data(NTABLES)
  set contents [split $input $ ]
  set c -1
  foreach el $contents {
  incr c

  if { [regexp {^TABLE} $el] }  {

    incr data(NTABLES)
    set data([Indxv TABLE_TITLE $data(NTABLES)]) [lindex [split $el :] 1 ]
    set data([Indxv TABLE_GRAPHS $data(NTABLES)])  ""
    set data([Indxv TABLE_COLUMNS $data(NTABLES)])  ""
    set data([Indxv TABLE_PARSED $data(NTABLES)])  0
   
   } elseif { [regexp GRAPHS $el] || [ regexp ^SCATTER $el ] }  {

# Get the definitions of the graphs which represent this table
    set inp [split $el :]
    for { set n 1 } { $n < [llength $inp] } { incr n 4 } {
      incr data(NGRAPHS)
      lappend data([Indxv TABLE_GRAPHS $data(NTABLES)]) $data(NGRAPHS)
#      puts "n $n $data(NGRAPHS) [lindex $inp $n]"
      set data([Indxv GRAPH_TITLE $data(NGRAPHS)]) [lindex $inp $n]
      set data([Indxv GRAPH_YAXIS $data(NGRAPHS)]) ""
      set data([Indxv GRAPH_XRESOLUTION $data(NGRAPHS)]) 0
      set data([Indxv GRAPH_RANGE $data(NGRAPHS)]) [lindex $inp [expr $n+1]]
      set data([Indxv GRAPH_COLUMNS $data(NGRAPHS)]) ""
      # determine if scatter plot
      if { [ regexp SCATTER $el ] } {
        set data([Indxv GRAPH_TYPE $data(NGRAPHS)]) "S"
      } else {
        set data([Indxv GRAPH_TYPE $data(NGRAPHS)]) "L"
      }
      foreach ele [split [lindex $inp [expr $n+2]] , ] {
        lappend data([Indxv GRAPH_COLUMNS $data(NGRAPHS)]) \
                [expr [string trim $ele] + $data(NCOLUMNS) ]
      } 
    } 
# Read the column titles
# Need to split into lines and then check if the lines can be split by white space
    set inp0 [split [lindex $contents [expr $c +2]] \n  ]
    set inp ""
    foreach line $inp0 {
      foreach ele [split $line ] {
        if { $ele != "" && [ string index $ele 0 ] == "-"} { 
           lappend inp [ string replace $ele 0 0 "" ] 
        } elseif { $ele != "" } { 
           lappend inp $ele 
        }
      }
    } 

    set i $data(NCOLUMNS)
    set jj [expr $data(NCOLUMNS) +1]
    foreach col $inp {
      if { [llength $col] > 0 } {
        incr data(NCOLUMNS)   
        #puts "col $col $data(NCOLUMNS)"
        set data([Indxv COLUMN_TITLE $data(NCOLUMNS)]) [string trim $col]
        set data([Indxv COLUMN_DATA $data(NCOLUMNS)]) ""
        lappend data([Indxv TABLE_COLUMNS $data(NTABLES)]) $data(NCOLUMNS)
      } 
    } 

# The header line contains abbreviations of the column names
    set inp [split [lindex $contents [expr $c +4]] { " " } ]
    foreach col $inp {
      if { [llength $col ] > 0 } { incr i; set data([Indxv COLUMN_ABBREV $i]) $col }
#      puts "ABBREV $i $col"
    }
    set data([Indxv TABLE $data(NTABLES)]) [lindex $contents [expr $c +6]]
    } 
  } 

  return [expr $data(NTABLES) - $initial_ntables ]

}

#---------------------------------------------------------------------------
proc extract_tables_from_DAT  { input arrayname } {
#---------------------------------------------------------------------------
  upvar #0 $arrayname data

  set contents [split $input \n ]
  if { [llength $contents ] <= 1 } { return 0 }
  set cmax 0
  foreach line $contents {
    if { [llength $line] > $cmax } { set cmax  [llength $line] }
  }
  incr data(NTABLES)
  set data([Indxv TABLE_TITLE $data(NTABLES)]) $data(TITLE)
  set data([Indxv TABLE_COLUMNS $data(NTABLES)]) ""
  incr data(NGRAPHS)
  set data([Indxv TABLE_GRAPHS $data(NTABLES)]) $data(NGRAPHS)
  set data([Indxv GRAPH_TITLE $data(NGRAPHS)]) $data(TITLE)
  set data([Indxv GRAPH_YAXIS $data(NGRAPHS)]) ""
  set data([Indxv GRAPH_XRESOLUTION $data(NGRAPHS)]) 0
  set data([Indxv GRAPH_COLUMNS $data(NGRAPHS)]) ""
  set data([Indxv GRAPH_RANGE $data(NGRAPHS)]) "A"

  set jj $data(NCOLUMNS)
  for { set c 1 } { $c <= $cmax } { incr c } { 
    incr data(NCOLUMNS)
    set data([Indxv COLUMN_TITLE $data(NCOLUMNS)]) "Column $c"
    set data([Indxv COLUMN_ABBREV $data(NCOLUMNS)]) "Column $c"
    set data([Indxv COLUMN_DATA $data(NCOLUMNS)]) ""
    lappend data([Indxv TABLE_COLUMNS $data(NTABLES)]) $data(NCOLUMNS)
    lappend data([Indxv GRAPH_COLUMNS $data(NGRAPHS)]) $data(NCOLUMNS)
  }
  set data([Indxv TABLE $data(NTABLES)]) $input
  set data([Indxv TABLE_PARSED $data(NTABLES)]) 0
  return 1
}

#---------------------------------------------------------------------------
proc extract_tables_from_XMGR  { input arrayname } {
#---------------------------------------------------------------------------
# Read XMGR file (e.g. SCALA normplot or correlplot)
  upvar #0 $arrayname data
  global xmgr_data

  # Initialise data
  set title ""
  set subtitle ""
  set legend ""
  set graph 0
  set symbol 0
  set linestyle 1
  set localdata(GRAPHS) {}
  set xlabel ""
  set ylabel ""
  set xmin ""
  set xmax ""
  set ymin ""
  set ymax ""
  set iunknown 0
  set igraph 0

  # Reset any existing XMGR styles
  foreach name [array names xmgr_data *] {
      unset xmgr_data($name)
  }
  set xmgr_data(TYPE) {}

  # Read the file contents into memory and process
  # a line at a time
  # We attempt to recognise key characteristics of the XMGR format
  # along with the actual graph data, and store these in an internal
  # data structure
  set contents [split $input \n ]
  if { [llength $contents ] <= 1 } { return 0 }
  foreach line $contents {
      # title line: @ title ...
      if { $title == "" && [regexp -- "^@ title (.+)" $line m title] } {
	  set title [string trim $title " \""]
	  # For Scala XMGR graphs also store the type for
	  # later reference
	  if { [regexp -- "Outliers on detector" $title] } {
	      # Scala ROGUEPLOT
	      set xmgr_data(TYPE) "SCALA_ROGUEPLOT"
	  } elseif { [regexp -- "Normal probability plot" $title] } {
	      # Scala NORMPLOT
	      set xmgr_data(TYPE) "SCALA_NORMPLOT"
	  } elseif { [regexp -- "DelAnom scatter plot" $title] } {
	      # Scala CORRELPLOT
	      set xmgr_data(TYPE) "SCALA_CORRELPLOT"
	  }
      }
      # subtitle: @ subtitle ...
      if { $subtitle == "" && [regexp -- "^@ subtitle (.+)" $line m subtitle] } {
	  set subtitle [string trim $subtitle " \""]
      }
      # X-axis label: @  xaxis  label ...
      if { $xlabel == ""  && [regexp -- "^@ +xaxis +label (.+)" $line m xlabel] } {
	  set xlabel [translate_scala_xmgr_labels [string trim $xlabel " \""]]
      }
      # Y-axis label: @  yaxis  label ...
      if { $ylabel == ""  && [regexp -- "^@ +yaxis +label (.+)" $line m ylabel] } {
	  set ylabel [translate_scala_xmgr_labels [string trim $ylabel " \""]]
      }
      # Limits (xmin, xmax,...)
      # e.g.: @  world xmin ...
      if { [regexp -- "^@ +world +(xmin|xmax|ymin|ymax) (.+)" $line m limit value] } {
	  set $limit $value
      }
      # legend (=column title): @ legend string <number> <legend>
      if { [regexp -- "^@  legend string +(\[0-9\]+) +(.+)" \
		$line m n legendtxt] } {
	  set localdata(LEGEND_$n) [translate_scala_xmgr_labels \
			  [string trim [lindex $legendtxt end] " \""]]
      }
      # symbol: @ <name> symbol <number>
      # Use this only to find out if there is a symbol
      if { ! $symbol && [regexp -- "^@ .* symbol" $line] } {
	  set symbol 1
      }
      # linestyle: @ <name> linestyle <number>
      # Use this only to find out if we should use lines
      if { [regexp -- "^@ .* linestyle (\[0-9\]+)" $line m linestyle] } {
	  if { $linestyle > 0 } { set linestyle 1 }
      }
      # Collect the data for a graph
      # Do this before testing to see if we have a graph
      if { $graph } {
	  if { [llength $line] >= 2 } {
	      lappend localdata(X_$legend) [lindex $line 0]
	      lappend localdata(Y_$legend) [lindex $line 1]
	  }
      }
      # Start of a graph: @type xy
      # or
      # We get a pair of numbers on a line
      if { ! $graph && [regexp -- "^@(type|TYPE) xy\$" $line] } {
	  set graph 1
	  incr igraph
	  #puts "Start of a graph..."
	  set legend "XMGR_$igraph"
	  lappend localdata(GRAPHS) $legend
	  set localdata(SYMBOL_$legend) $symbol
	  set localdata(LINE_$legend) $linestyle
      }
      if { ! $graph && [llength $line] > 1 } {
	  # See if we have a pair of numerical values
	  if { [string is double [lindex $line 0]] && \
		   [string is double [lindex $line 1]] } {
	      set graph 1
	      incr igraph
	      set legend "XMGR_$igraph"
	      lappend localdata(GRAPHS) $legend
	      set localdata(SYMBOL_$legend) $symbol
	      set localdata(LINE_$legend) $linestyle
	      lappend localdata(X_$legend) [lindex $line 0]
	      lappend localdata(Y_$legend) [lindex $line 1]
	  }   
      }
      # End of a graph: & within a graph context
      if { $graph && [regexp -- "^&\$" $line] } {
	  #puts "End of a graph."
	  # Reset the local data for next graph
	  set graph 0
	  set legend ""
	  set symbol 0
	  set linestyle 1
      }
  }
  # Build complete lists of "y" axis data for each graph
  foreach name $localdata(GRAPHS) {
      for { set i 0 } { $i < [llength $localdata(X_$name)] } { incr i } {
	  set xvalue [lindex $localdata(X_$name) $i]
	  set yvalue [lindex $localdata(Y_$name) $i]
	  lappend localdata(MASTER_X) $xvalue
	  foreach name0 $localdata(GRAPHS) {
	      if { $name == $name0 } {
		  lappend localdata(MASTER_Y_$name0) $yvalue
	      } else {
		  lappend localdata(MASTER_Y_$name0) "?"
	      }
	  }   
      }
  }
  # Squeeze the data into the internal loggraph data structures
  set i $data(NCOLUMNS)
  set ii [expr $data(NCOLUMNS) + 1]
  set j $ii
  set data([Indxv COLUMN_DATA $ii]) $localdata(MASTER_X)
  foreach name $localdata(GRAPHS) {
      incr j
      set data([Indxv COLUMN_DATA $j]) $localdata(MASTER_Y_$name)
  }
  # Deal with column titles
  incr data(NGRAPHS)
  set ncolumns [expr [llength $localdata(GRAPHS)] + 1]
  set data([Indxv COLUMN_TITLE $ii]) "$xlabel"
  set data([Indxv COLUMN_ABBREV $ii]) "xlabel"
  set data([Indxv GRAPH_COLUMNS $data(NGRAPHS)]) $ii
  incr data(NCOLUMNS)
  set igraph 0
  foreach name $localdata(GRAPHS) {
      if { [info exists localdata(LEGEND_$igraph)] } {
	  set legend $localdata(LEGEND_$igraph)
      } else {
	  set legend "NO_LEGEND_$igraph"
      }
      set j [incr data(NCOLUMNS)]
      set data([Indxv COLUMN_TITLE $j]) "$legend"
      set data([Indxv COLUMN_ABBREV $j]) "$legend"
      lappend data([Indxv GRAPH_COLUMNS $data(NGRAPHS)]) $j
      # Also store the XMGR style data
      set xmgr_data(LINESTYLE_$legend) $localdata(LINE_$name)
      set xmgr_data(SYMBOL_$legend) $localdata(SYMBOL_$name)
      incr igraph
  }
  # Set the overall data for the table
  incr data(NTABLES)
  lappend data([Indxv TABLE_COLUMNS $data(NTABLES)]) $data(NCOLUMNS)
  set data([Indxv TABLE_TITLE $data(NTABLES)]) "$title"
  set data([Indxv TABLE_COLUMNS $data(NTABLES)]) ""
  set data([Indxv TABLE_GRAPHS $data(NTABLES)]) $data(NGRAPHS)
  set data([Indxv GRAPH_TITLE $data(NGRAPHS)]) "$title"
  set data([Indxv GRAPH_YAXIS $data(NGRAPHS)]) ""
  set data([Indxv GRAPH_TYPE $data(NGRAPHS)]) "X"
  set data([Indxv GRAPH_XRESOLUTION $data(NGRAPHS)]) 0
  # Work out the limits and scaling type
  if { $xmin == "" || $ymin == "" || $xmax == "" || $ymax == "" } {
      # Incomplete limits - set scaling to be automatic
      set data([Indxv GRAPH_RANGE $data(NGRAPHS)]) "A"
  } else {
      # Explicitly set the limits
      set data([Indxv GRAPH_RANGE $data(NGRAPHS)]) \
	  "[subst $xmin]|[subst $xmax]x[subst $ymin]|[subst $ymax]"
  }
  set data([Indxv TABLE $data(NTABLES)]) ""
  set data([Indxv TABLE_PARSED $data(NTABLES)]) 1
  return 1
}

#--------------------------------------------------------------------
proc parse_table { dataVar it } {
#--------------------------------------------------------------------
upvar #0 $dataVar data
# Split up each row of the table to put one element in each column
  set inp [split $data([Indxv TABLE $it]) \n ]
  set c1 [lindex $data([Indxv TABLE_COLUMNS $it]) 0]
  set c2 [lindex $data([Indxv TABLE_COLUMNS $it]) end]
  set ll [expr $c2 - $c1 + 1 ]
#  puts "parse_table it $it c1 $c1 c2 $c2 ll $ll"
  set j $c1
  foreach line $inp { 
    foreach ele $line { 
      # See if the element is actually a number
      if { [isnumber $ele] } {
        lappend data([Indxv COLUMN_DATA $j]) $ele
        incr j; if { $j > $c2 } { set j $c1 }
      } elseif { [regexp -- "^\[\*\]+$" $ele] ||
		 [regexp -- "^\[nN\]\[aA\]\[nN\]$" $ele] } {
	# Special cases: ****** (i.e. format overflow from fortran program
        # or nan - these need to be treated as data items even though they
        # don't contain valid data
        lappend data([Indxv COLUMN_DATA $j]) $ele
        incr j; if { $j > $c2 } { set j $c1 }
      } else {
        # For now also include non-numerical characters
        # Maybe in future we will ignore those fields which
        # contain certain special characters.
        lappend data([Indxv COLUMN_DATA $j]) $ele
        incr j; if { $j > $c2 } { set j $c1 }
      }
    }
  }
  set data([Indxv TABLE_PARSED $it]) 1

  # Basic validation check
  if { $j != $c1 } {
      WarningMessage "Error parsing data in file:
The table \"$data([Indxv TABLE_TITLE $it])\"
doesn't have the correct number of data elements
This means that the data may be displayed incorrectly"
  }
}

#--------------------------------------------------------------------------
proc plot_data0 { arrayname dataVar igin } {
#--------------------------------------------------------------------------
  upvar #0 $arrayname stuff
  upvar #0 $dataVar data
# interpret a listbox pick and pass on selected graph to plot_data
  set it $stuff(currenttable)
  set ig [lindex $data([Indxv TABLE_GRAPHS $it]) $igin ]
  $stuff(tablelist) selection set [expr $it -1] 
  for { set n 1 } { $n < [llength $data(GRAPH_COLUMNS,$ig)] } {incr n } {
    set stuff(visible,$n) 1
  }
  plot_data $arrayname $dataVar $ig
}
  

#-------------------------------------------------------------------------
proc plot_data { arrayname dataVar { igin {} } } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname stuff
  upvar #0 $dataVar data
  global loggraph

  set it $stuff(currenttable)
  if { $igin != "" } {
    set ig  $igin
    set stuff(currentgraph) $ig
  } elseif { $stuff(currentgraph) != 0 && $stuff(currentgraph) != "" } {
    set ig $stuff(currentgraph)
  } else {
    return 0
  }
#  puts "plot_data it $it ig $ig $data([Indxv GRAPH_COLUMNS $ig])"
  set g $stuff(graphframe)

# Parse the table if it is not already split into columns
  if { !$data(TABLE_PARSED,$it) } { parse_table $dataVar $it }

# Delete any existing plot
  foreach el [$g element names] { $g element delete $el}

  $g configure -title $data([Indxv GRAPH_TITLE $ig]) \
               -font $stuff(titlefont)
  set xcol [lindex $data([Indxv GRAPH_COLUMNS $ig]) 0 ]
  set xtitle $data([Indxv COLUMN_TITLE $xcol])
  $g axis configure x -title $xtitle \
	-command "" \
        -tickfont $stuff(xtickfont) \
        -titlefont $stuff(xaxisfont)

  $g axis configure y -title $data([Indxv GRAPH_YAXIS $ig]) \
        -tickfont $stuff(ytickfont) \
        -titlefont $stuff(yaxisfont)

# The x data is in the first column used by the graph
  if [regexp ^XD $data([Indxv GRAPH_RANGE $ig]) ] {
    set xdata {}
    set iy [lindex $data([Indxv GRAPH_COLUMNS $ig]) 1]
    set nitems [llength $data([Indxv COLUMN_DATA $iy])]
    for { set n 1 } { $n <= $nitems } {incr n } {      lappend xdata $n
    }
  } else {
    set xdata $data([Indxv COLUMN_DATA $xcol])
  }
   
# Plot style
  if [regexp S $data([Indxv GRAPH_TYPE $ig]) ] {
# scatter
    set stuff(linewidth) 0
  } else {
# standard
    set stuff(linewidth) 1
  }
  
# Loop over all other columns used by graph for yvalues of graph elements
  set counter 0

# Initialise minimum and maximum values
  set xmax ""
  set ymax ""
  set xmin ""
  set ymin ""

# PJX: xdata is a vector holding the x-positions
# There is a problem if data elements from the table are non-numeric
# The code below is intended to deal with this in a non-fatal way
#
# Each x,y data point is loaded into xtmp,ytmp iff y is numeric
# The test for this is that it must consist only of numbers 0-9, minus
# and a decimal point.

  set warningflag 0
  foreach iy [lrange $data([Indxv GRAPH_COLUMNS $ig]) 1 end] {
    set style [expr $counter%$loggraph(NLINESTYLES)+1 ]
    incr counter
    if $stuff(visible,$counter) {
       set xtmp ""
       set ytmp ""
       set icount 0
       foreach iz [lrange $data([Indxv COLUMN_DATA $iy]) 0 end] {
          if {[isnumber $iz] && [isnumber [lindex $xdata $icount]]} then {
            lappend ytmp $iz
            lappend xtmp [lindex $xdata $icount]
          } else {
            set warningflag 1
          }
          incr icount
       }
       if {[llength $ytmp]>0} then {
          # Get or reset the max and min values
          if {$xmin == "" } { set xmin [lindex $xtmp 0] }
          if {$ymin == "" } { set ymin [lindex $ytmp 0] }
          if {$xmax == "" } { set xmax $xmin }
          if {$ymax == "" } { set ymax $ymin }
          set mnmx [max $xtmp]
          if { $mnmx > $xmax } { set xmax $mnmx }
          set mnmx [min $xtmp]
          if { $mnmx < $xmin } { set xmin $mnmx }
          set mnmx [max $ytmp]
          if { $mnmx > $ymax } { set ymax $mnmx }
          set mnmx [min $ytmp]
          if { $mnmx < $ymin } { set ymin $mnmx }
	  # Determine label to show on the legend
	  set label $data([Indxv COLUMN_TITLE $iy])
	  if { [regexp "^X" $data([Indxv GRAPH_TYPE $ig]) ] && \
		   [regexp -- "NO_LEGEND_" $label] } {
	      # For XMGR graphs, if the column label starts
	      # with "NO_LEGEND_" then set a blank legend
	      set label {}
	  }
          # Display the line
          $g element create $data([Indxv COLUMN_TITLE $iy]) \
          -xdata $xtmp \
          -ydata $ytmp \
	  -label "$label"
       }
# PJX: dialogue box was supposed to give a warning about empty columns...
# else {
#          tk_dialog .load_err "No data" "No data found in graph column" \
#          warning 0 { OK }
#       }
    }
#    puts "ydata [llength $data([Indxv COLUMN_DATA $iy])] $data([Indxv COLUMN_DATA $iy])"
    set stuff([Indxv elements $counter]) $data([Indxv COLUMN_TITLE $iy])
  } 
  set stuff(nelements) $counter

# If the warningflag is set then send a warning dialog
#  if { $warningflag } {  WarningMessage "Bad data points found"  }
# PJX: the above does funny things to my Alpha! 19-01-00

# Set the linestyle(s) for the plot
  configure_plot stuff
  #
  # Do the scaling , formats,
  # XMIN|XMAXxYMIN|YMAX or A[UTO] or N[OUGHT]
  # Beware NT crashes if set min/max to null character
  #
  # The min and max x- and y-values for the current graph are now
  # searched for in the code above, and these are used to set
  # the y limits explicitly - pjx
  # If the maximum/minimum limits are equal then
  if {[info exists xmin]} {
    if { $xmin == $xmax } {
      set xmin [expr $xmin - 1.0]
      set xmax [expr $xmax + 1.0]
    }
  }
  if {[info exists ymin]} {
    if { $ymin == $ymax } {
      set ymin [expr $ymin - 1.0]
      set ymax [expr $ymax + 1.0]
    }
  }

  if { [regexp ^N $data([Indxv GRAPH_RANGE $ig]) ] } {
    $g axis configure x -min $xmin -max $xmax
    $g axis configure y -min 0 -max $ymax
#    $g axis configure x -min {} -max {}
  } elseif { [regexp ^A $data([Indxv GRAPH_RANGE $ig]) ] } {
    $g axis configure x -min $xmin -max $xmax
    $g axis configure y -min $ymin -max $ymax
#    $g axis configure x -min {} -max {}
  } elseif { [regexp ^XD $data([Indxv GRAPH_RANGE $ig]) ] } {
#    $g axis configure y -min {} -max {}
    $g axis configure x -min 0.0 -max [expr double([expr $nitems +1])]
  } else { 
    set scaling [split $data([Indxv GRAPH_RANGE $ig]) x ]
    set xlim [split [lindex $scaling 0] |]
    set ylim [split [lindex $scaling 1] |]
    $g axis configure x -min [expr double([lindex $xlim 0])] \
                      -max [expr double([lindex $xlim 1])]
    $g axis configure y -min [expr double([lindex $ylim 0])] \
                      -max [expr double([lindex $ylim 1])]
  }

  set stuff(XLABEL) X

# convert the xaxis to resolution
  if { [regexp {4SSQ|\<s\>|resol\^2|1/d\^2} $xtitle] && $loggraph(USE_RESOLUTION) } { 
    $g axis configure x \
	-title "Resolution (A)" \
        -command resolution_tick
    set stuff(XLABEL) R
  }

# If its an Xdiscrete graph (eg probably plotted x=res no) then reset xlabels

  if [regexp ^XD $data([Indxv GRAPH_RANGE $ig]) ] {
    $g axis configure x \
      -command xdiscreet_label
    set stuff(XLABEL) L
  }
   
# Apply special formatting for XMGR plots
  if [regexp "^X" $data([Indxv GRAPH_TYPE $ig]) ] {
      configure_xmgr_plot stuff
  }

  return $counter
}

#---------------------------------------------------------------------
proc resolution_tick { widget x } {
#---------------------------------------------------------------------
  if { $x > 0.001 } {
    set r [expr pow($x,-0.5)]
  } else { 
    set r 100.0
  }
  if { $r >= 4 } {
    return [format %.1f $r]
  } else {
    return [format %.2f $r]
  }
}

#------------------------------------------------------------
proc xdiscreet_label { widget x } {
#------------------------------------------------------------
  global data
  global stuff
  set ig $stuff(currentgraph)
  set xcol [lindex $data(GRAPH_COLUMNS,$ig) 0 ]
  if [catch "set lab [lindex $data(COLUMN_DATA,$xcol) [expr $x-1]]"] {
    set lab ""
  }
  return $lab
}

#-------------------------------------------------------------
proc crosshairs_position { } {
#-------------------------------------------------------------
  global stuff
  set round 4
  set g $stuff(graphframe)
  # The check on winx,winy is for DECs - invtransform fails if
  # they are less than zero
  if [ regexp {@([^,]*),([^,]*)} [$g crosshairs cget -position] all winx winy] {
    if {$winx<0 && $winy<0} {
      set grxy [ list 0 0 ]
    } else {
      set grxy [$g invtransform $winx $winy]
    }
  }
  set y [string range [lindex $grxy 1] 0 $round]
  switch $stuff(XLABEL) \
  R {
    set x [resolution_tick w [lindex $grxy 0]]
  } L {
    set x [xdiscreet_label w [expr round([lindex $grxy 0])]]
  } default {
    set x [string range [lindex $grxy 0] 0 $round]
  }

  if [$g element closest $winx $winy closest] {
    set closey [string range $closest(y) 0 $round]
    switch $stuff(XLABEL) \
    R {
      set closex [resolution_tick w $closest(x)]
    } L {
      set closex [xdiscreet_label w [expr round($closest(x))]]
    } default {
      set closex [string range $closest(x) 0 $round]
    }
    $stuff(closest_label) configure -text "$closest(name) $closex , $closey  "
  } else {
    $stuff(closest_label) configure -text ""
  }
  $stuff(position_label) configure -text "$x,$y"

  after 100 crosshairs_position
}

#-------------------------------------------------------------
proc isnumber { str } {
#-------------------------------------------------------------
# Return 1 if the string is a valid number
# Return 0 if it isn't
  return [regexp -- "^\[+\-\]?\[0-9\]*\.?\[0-9\]*\[eE\]?\[0-9\]" $str]
}

#-------------------------------------------------------------
proc LGClientReceive { args } {
#-------------------------------------------------------------
#  puts "LGListen $args"
# Handle commands from the socket connection to main ccp4i process
# Currently only option is to open another log file
  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    open {
      incr n; eval "open_file LOG \"[lindex $args $n]\""
    }
    incr n
  }
}

#-------------------------------------------------------------
proc ExitLoggraph { } {
#-------------------------------------------------------------
# Do clean up (like saving preferences) before exiting
   SavePreferences loggraph loggraph
   exit
}

#*************************************************************************
#  This is top level script - get things started after all the procedures
#  are defined
#*************************************************************************
initstuff stuff
wm withdraw .
create_main_win
if { [ElementExists system SERVER_PORT] && $system(SERVER_PORT) != "" } {
  if { [OpenClientSocket localhost $system(SERVER_PORT) -listen LGClientReceive] } {
    PutsSocket LGServerReceive -client
  }
}
if { $system(SCRIPT) != "" } {
  if { ![ElementExists system FORMAT] || $system(FORMAT) == "" } { 
     set system(FORMAT) [GetFileFormat $system(SCRIPT) LOG ] }
  if { [extract_tables_from_file $system(SCRIPT) $system(FORMAT) data] } {
    load_listbox data }
}

# DO NOT PUT ANYTHING BELOW HERE
