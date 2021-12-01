#---------------------------------------------------------
proc dhm_tool_setup { typedefname arrayname } {
#---------------------------------------------------------

    upvar #0 $typedefname typedef

# Menu setup : Default Harvesting directory or current Project Directory; Drop-down menu of the validation programs that can be run
    set typedef(_dhm_tool_select) { menu { "DepositFiles (Home Directory)" "Current Project Directory" "Other Directory" } { DEFAULT OTHER } }

    set typedef(_dhm_tool_run_program) { menu { "Validate Harvest Files" "Convert CIF to XML" "Extract additonal information for deposition"} { cross_validate cif2xml pdb_extract} }

    set typedef(_dhm_tool_extract_step) { menu { "Data Scaling" "Heavy Atom Phasing" "Molecular Replacement" "Density modification" "Structure Refinement"  "Generate a data template" "Generate a complete mmCIF file for PDB deposition" } { scaling phasing replacement den_mod refinement data_template merge } }

    set typedef(_dhm_tool_extract_scaling) { menu {  "HKL" "HKL2000" "SCALEPACK" "D*trek" "SCALA" "SAINT" "3DSCALE" "OTHER PROGRAM" } { HKL HKL2000 SCALEPACK DTREK SCALA SAINT 3DSCALE OTHER } }

    set typedef(_dhm_tool_extract_phasing) { menu { "CNS" "MLPHARE" "SOLVE" "SHARP" "SnB" "BnP" "PHASES" "SHELXD" "SHELXS" "OTHER PROGRAM" } { CNS MLPHARE SOLVE SHARP SnB BnP PHASES SHELXD SHELXS OTHER } }

    set typedef(_dhm_tool_extract_replacement) { menu { "CNS" "AMoRe" "EPMR" "MolRep" "OTHER PROGRAM" } { CNS AMoRe EPMR MolRep OTHER}}

    set typedef(_dhm_tool_extract_den_mod) { menu { "CNS" "DM" "SOLOMON" "RESOLVE" "SHARP" "SHELXE" "OTHER PROGRAM" } { CNS DM SOLOMON RESOLVE SHARP SHELXE OTHER } }

    set typedef(_dhm_tool_extract_refinement) { menu { "CNS" "REFMAC5" "SHELXL" "ARP/wARP" "TNT" "RESTRAIN" "PROLSQ" "OTHER PROGRAM" } { CNS REFMAC5 SHELXL WARP TNT RESTRAIN PROLSQ OTHER} }
   
    set typedef(_dhm_tool_extract_exp_menu) { menu { "SAD" "MAD" "MIR" "SIR" "SIRAS" "MIR" "MIRAS" } { SAD MAD MIR SIR SIRAS MIR MIRAS } }

    set typedef(_any_file) { file ANY "*" "Any" "" }

    return 1

}

#--------------------------------------------------------------
proc fileselectClick2 { arrayname lb y } {
#--------------------------------------------------------------
#d_sum Take the file item the user clicked on in listbox
#d_arg lb listbox id
#d_arg y Y position of click in listbox
upvar #0 $arrayname array
	# Take the item the user clicked on
	global fileselect
        set selection [$lb get [$lb nearest $y]]
        set fileselect(FILNAM) $selection
        set path [FileJoin $fileselect(DIR) $fileselect(FILNAM)]
        if { [file isdirectory $path] } { fileselectOK }

	dhm_tool_getdatasets $arrayname $path
}



proc multiplefiles { arrayname } {
    upvar #0 $arrayname array
    global fileselect
    global filelist
    set multiple_list {}
    set filelist_selection [$filelist curselection]
#    puts "filelist_selection: $filelist_selection"
    if {[llength $filelist_selection] == 0 } {
	WarningMessage "No files highlighted"
    }
    for { set v 0 } { $v < [llength $filelist_selection] } { incr v } {
	set multiple_list [FileJoin $fileselect(DIR) [$filelist get [lindex [$filelist curselection] $v]]]
	$array(BOXNAME) insert end $multiple_list
    }
    $filelist selection clear 0 [$filelist size]
    
}


proc dhm_tool_clickOK { arrayname } {

    upvar #0 $arrayname array
    
    global fileselect
    dhm_tool_getsetsfromdir $arrayname $fileselect(DIR)
}



#--------------------------------------------------------------------
proc SelectDir { arrayname fileoutVar args } {
#--------------------------------------------------------------------
#d_sum Open a file seelction window
#d_ref CCP4I programmers/SelectFile.html See Programmers Documentation
# fileselect returns the selected pathname, or {}
# if the -return flag is set then it will return a list of
# specified data
  upvar #0 $arrayname array
  upvar $fileoutVar fileout
  global fileselect
  global configure
  global system
  global typedef
  global preferences
  global filelist

  set frame .fileselect
  if [winfo exist $frame] {
    wm iconify $frame
    wm deiconify $frame
    WarningMessage "You already have a file selection window open"
    return 0
  }


  DefineVariable fileselect FILTER _text ""
  DefineVariable fileselect DIR _text ""
  DefineVariable fileselect DEFDIR _default_dirs [GetCurrentProject]
  DefineVariable fileselect DIRENT _text ""
  DefineVariable fileselect FILNAM _text ""
  DefineVariable fileselect FILE_CONTENTS _list_of_text ""
  DefineVariable fileselect DIR_CONTENTS _list_of_text ""
  DefineVariable fileselect SORT _fileselect_sort  \
				$preferences(FILESELECT_DEFAULT)
  DefineVariable fileselect LISTINFO _fileselect_listinfo  name

# Set some defaults

  set title "File Selection"
  set default ""
  set parent ""
  set custom_script {}
  set fileselect(DIR) ""
  set fileselect(OPENMODE) read
  set fileselect(FORMAT) ""
  set fileselect(SELECT_VIEWER) 0
  set fileselect(SETFILETYPE) 0
  set fileselect(IFDIRECTORY) 0
  set fileselect(IFFILTER) 0
  set fileselect(FILTER) ""
  set fileselect(IFVIEW) 0
  set fileselect(DONE) -1
  set fileselect(FILNAM) {}
  set fileselect(EXTENSION) {}
  set fileselect(RETURN) {fullpath}
  set defformat ANY

# Now find out what the user really wants
  
  set nargs [llength $args] ; set n 0
  while { $n < $nargs  } {
    switch -regexp -- [lindex $args $n] \
    title {
       incr n; set title [lindex $args $n]
    } defdir {
       incr n; set fileselect(DEFDIR) "[lindex $args $n]"
    } default {
       incr n; set default [lindex $args $n]
       if { [file isdirectory $default] } {
         set fileselect(DIR) $default 
         set fileselect(DEFDIR) [GetSystemVar PATHNAME_LABEL]
       } else {
         set fileselect(FILNAM) [file tail $default]
       }
    } unknown {
       set fileselect(OPENMODE) save
    } format {
       incr n; set fileselect(FORMAT) [lindex $args $n]
    } directory {
       set fileselect(IFDIRECTORY) 1
    } filter {
       set fileselect(IFFILTER) 1
       incr n; set fileselect(FILTER) [lindex $args $n]
       set fileselect(EXTENSION) [string range $fileselect(FILTER) 1 end]
    } parent {
       incr n; set parent [lindex $args $n]
    } custom {
       incr n; set custom_params [lindex $args $n]
       incr n; set custom_script [lindex $args $n]
    } filetype {
# File definitions in etc/types.def usually have form:
# set typedef(file)    { file format ext description viewer viewercmd }
# but make sure we know current correct form
       set idescription [lsearch $typedef(file) description]
       set iformat [lsearch $typedef(file) format]
       set iext [lsearch $typedef(file) ext]
       incr n; set defformat [lindex $args $n]
       incr n; set typelist [lindex $args $n]
       set fileselect(SETFILETYPE) 1
       foreach  type $typedef($typelist) {
         lappend menulist "[lindex $typedef($type) $idescription]"
         lappend fileselect(ALIASLIST) [lindex $typedef($type) $iformat]
         lappend fileselect(EXTLIST) [lindex $typedef($type) $iext]
       }
       set pp [max 0 [lsearch $fileselect(ALIASLIST) $defformat]]
       set deffiletype "[lindex $menulist $pp]"
       DefineMenu _fileseltypes $menulist $fileselect(ALIASLIST)
       DefineVariable fileselect FILETYPE _fileseltypes "$deffiletype"
    } view { 
       set fileselect(IFVIEW) 1
       GetViewerList $fileselect(FILETYPE) \
		fileselect(VIEWER_LIST) fileselect(VIEWERCMD_LIST)
       DefineVariable fileselect VIEWER _fileselviewers "List file"
    } return {
       incr n;set fileselect(RETURN) [lindex $args $n]
    }
    incr n
  }

  if { $fileselect(DIR) == {} } {
    set fileselect(DIR) [GetDefaultDirPath $fileselect(DEFDIR)]
  }

  if { $fileselect(SETFILETYPE) && $fileselect(FILTER) == "" } { fileselectFilter }

  if $fileselect(SETFILETYPE) { 
    set help_file [SearchPath HELP general fileviewer.html ]
  } else {
    set help_file [SearchPath HELP general fileselect.html ]
  }

  if { $parent != "" } {
    OpenGridWindow fileselect $frame $title "File"  -help $help_file  \
          -parent $parent
  } else {
    OpenGridWindow fileselect $frame $title "File"  -help $help_file
  }
# Reset the weights of the 'main' and the 'utils' frames so the utils
# frame will stretch
  grid rowconfigure $frame 1   -weight 0
  grid rowconfigure $frame 2   -weight 1

  CreateFrame $frame fileselect -noscroll

  if  { $custom_script != "" } {
    foreach param $custom_params  {
      eval [concat DefineVariable fileselect $param]
    }
    OpenSubFrame fcustom -appearance {-relief ridge -borderwidth 1 }
    eval $custom_script
    CloseSubFrame
  }

  CreateLine line \
    message "Current directory path" \
    label "Current directory " \
    varlabel DIR


  if {  $fileselect(FORMAT) != "" } {

    CreateLine file_line \
      message "Enter file path name" \
      label "File" \
      widget FILNAM \
        -expand \
      message "View the file contents" \
      button "View" -command {FileViewer \
	[FileJoin $fileselect(DIR) $fileselect(FILNAM)] \
                -format $fileselect(FORMAT) -noquery}

    $file_line.b3 configure -font $configure(FONT_SMALL)

  } else {

    CreateLine file_line \
      message "Enter file path name" \
      label "File" \
      widget FILNAM \
	-width 50  -expand

  }

  CreateLine line \
    message "Go to pre-defined project directory" \
    label "Go to directory" \
    widget DEFDIR \
      -command "fileselectDefdir DEFDIR DIR" \
    message "Go up one directory" \
    button "Go up a directory" \
      -command up_directory

  $line.b3 configure -font $configure(FONT_SMALL)
  pack forget $line.b3
  pack $line.b3 -side right

  if $fileselect(IFDIRECTORY) {
    bind $file_line.e2 <Return> fileselectOK
  } else {
    bind $file_line.e2 <Return> "fileselectOK -finish"
  }
  bind $file_line.e2 <space> fileselectComplete

# Create entry for the filter 
  if { $fileselect(SETFILETYPE) && $fileselect(IFFILTER) } {

    CreateLine line \
      label "File type" \
      message "Select a file type from the menu" \
      widget FILETYPE \
       -command {fileselectFilter; fileselectViewers; fileselectList $fileselect(DIR)} \
      label "filename filter" \
      message "Enter a file selection filter" \
      widget FILTER

    bind $line.e4 <Return> {fileselectList $fileselect(DIR)}

    if { $fileselect(IFVIEW) } {
      CreateLine line \
        message "Choose a Viewer" \
        label Viewer \
        widget VIEWER \
        toggle_display SELECT_VIEWER hide 0
    }

  } elseif { $fileselect(IFFILTER) } {

    CreateLine line \
      message "Enter a file selection filter" \
      label "Filename filter" \
      widget FILTER

    bind $line.e2 <Return> {fileselectList $fileselect(DIR)}
	  
  }

    CreateLine line \
      message "Enter a file selection filter" \
      label "Filename filter" \
      widget FILTER

    bind $line.e2 <Return> {fileselectList $fileselect(DIR)}

  CreateLine line \
    message "Sort files by name or date" \
    label "Sort files by" \
    widget SORT \
	-command {fileselectList $fileselect(DIR)} \
    label "& list" \
    message "List name or access code,size,date,name" \
    widget LISTINFO \
	-command {fileselectList $fileselect(DIR)} \
   

# Create listbox for chain files if we have some "chain" files

#  if { [info exists chain(LENGTH) ] &&  \
#    $chain(LENGTH) >= 1 && [llength $chain(FILELIST)] >= 1 } {
#
#    CreateLine line \
#      label "Files which will be created by tasks in chain:"
#
#    CreateListbox ch FILELIST -array chain -height 5 -width 40
#    bind $ch.list <space> "fileselectTake $%W ; focus $file_line.e1"
#    bind $ch.list <Button-1> \
#                "fileselectClick %W %y ; focus $file_line.e1"
#    bind $ch.list <Return> "fileselectTake %W ; set fileselect(DONE) 1"
#    bind $ch.list <Double-Button-1> \
#                "fileselectClick %W %y ; set fileselect(DONE) 1"
#
#    CreateLine line \
#      label "Files in current directory:" \
#	-font $configure(FONT_REGULAR) 
#  }

# Reset the weights of the 'main' and the 'utils' frames so the utils
# frame will stretch
  grid rowconfigure $frame 1   -weight 0
  grid rowconfigure $frame 2   -weight 1

  set height 5
  set width 25

  set wdir [frame $frame.utils.dir]
  set wfile [frame $frame.utils.files]
  grid $wdir -row 0 -column 0  -sticky nswe
  grid $wfile -row 0 -column 1  -sticky nswe

  grid columnconfigure $frame.utils 0  -weight 1
  grid columnconfigure $frame.utils 1  -weight 5
  grid rowconfigure $frame.utils 0   -weight 1

  set dirlist [listbox $wdir.list \
        -yscrollcommand [list $wdir.scroll set] \
        -font $configure(FONT_FIXED) \
        -height $height \
        -width $width ]
  scrollbar $wdir.scroll -command [list $wdir.list yview]

  grid $wdir.list  -row 0 -column 0  -sticky nswe
  grid $wdir.scroll  -row 0 -column 1  -sticky ns
  grid columnconfigure $wdir 0  -weight 1
  grid columnconfigure $wdir 1  -weight 0
  grid rowconfigure $wdir 0   -weight 1

#  pack $wdir.list -side left -fill both -expand true -anchor e
#  pack $wdir.scroll -side left -fill y -anchor e

  $dirlist insert end $fileselect(DIR_CONTENTS)
  set fileselect(WIDGET_DIR_CONTENTS) $dirlist

 set filelist [listbox $wfile.list \
        -yscrollcommand [list $wfile.scroll set] \
        -font $configure(FONT_FIXED) \
        -height $height \
        -width $width \
	-selectmode extended ]
  scrollbar $wfile.scroll -command [list $wfile.list yview]
  grid $wfile.list  -row 0 -column 0  -sticky nswe
  grid $wfile.scroll  -row 0 -column 1  -sticky ns
  grid columnconfigure $wfile 0  -weight 1
  grid columnconfigure $wfile 1  -weight 0
  grid rowconfigure $wfile 0   -weight 1

#  pack $wfile.list -side left -fill both -expand true -anchor e
#  pack $wfile.scroll -side left -fill y -anchor e

  $filelist insert end $fileselect(FILE_CONTENTS)
  set fileselect(WIDGET_FILE_CONTENTS) $filelist

#  CreateListbox di CONTENTS -height 10 -width 40

# A single click, or <space>, puts the name in the entry
# A double-click, or <Return>, selects the name

  #bind $filelist <space> "fileselectTake $%W ; focus $file_line.e2"
  
  #bind $filelist <Button-1> \
                #"fileselectClick %W %y ; focus $file_line.e2"
 
  #bind $filelist <Return> "fileselectTake %W ; fileselectOK"
  #bind $filelist <Double-Button-1> \
                #"fileselectClick %W %y ; fileselectOK -finish"

  bind $filelist <Double-Button-1> \
	        "fileselectClick2 $arrayname %W %y  "

 # bind $filelist <>

  bind $dirlist <Button-1> \
                "dirselectClick %W %y ; focus $file_line.e2"
  #bind $dirlist <Double-Button-1> \
   #             "dirselectClick %W %y ; fileselectOK -finish"

# Cancel & OK buttons

  if { $fileselect(IFVIEW) } {
    set quit [CreateButton $frame quit Exit fileselectCancel]
    set display [CreateButton $frame display Display fileselectOK ]
    SetMessage fileselect $quit "Exit file selection"
    SetMessage fileselect $display "Display the currently selected file"
    if { ![regexp fileviewer $system(RUN_MODE) ] } {
      set ok [CreateButton $frame ok "Display&Exit" "fileselectOK -finish" ]
      SetMessage fileselect $ok "Display the currently selected file & exit file selection"
    }

  } else {
    set quit [CreateButton $frame quit Close fileselectCancel]
    #set ok [CreateButton $frame ok OK "fileselectOK -finish" ]
      set ok [CreateButton $frame ok "Select all files in this directory" "dhm_tool_clickOK $arrayname" ]
      
      set multipleok [CreateButton $frame multipleok "Select highlighted files" "multiplefiles $arrayname"]

    SetMessage fileselect $quit "Close File Browser"
    SetMessage fileselect $ok "Select all files in this directory"
  }

  SetMessage fileselect $dirlist "List of subdirectories"
  SetMessage fileselect $filelist "List of files which satisfy selection criteria"


  # Wait for the listbox to be visible so
  # we can provide feedback during the listing 
  tkwait visibility  $filelist
  fileselectList $fileselect(DIR)
  fileselectOK

  tkwait variable fileselect(DONE)
  CloseWindow fileselect
  set fileout ""
  foreach item $fileselect(RETURN) {
    switch $item \
    fullpath {
      lappend fileout [FileJoin $fileselect(DIR) $fileselect(FILNAM)]
    } dir {
      lappend fileout $fileselect(DIR)
    } filename {
      lappend fileout $fileselect(FILNAM)
    } filetype {
      lappend fileout [GetValue fileselect FILETYPE]
    } defdir {
      lappend fileout "$fileselect(DEFDIR)"
    } viewer {
      if { $fileselect(SELECT_VIEWER) } {
        lappend fileout [GetValue fileselect VIEWER ]
      } else {
        lappend fileout {}
      }
    } filter {
      lappend fileout $fileselect(FILTER)
    }
  }
  if { $custom_script != "" } {
    foreach param $custom_params {
      lappend fileout $fileselect([lindex $param 0])
    }
  }
  set done $fileselect(DONE)
  unset fileselect
  return $done
}

#-------------------------------------------------------------------
proc DirecBrowser { arrayname arrayindex } {
#-------------------------------------------------------------------
#d_sum Present a 'file' browser for user to select a directory
#d_desc This assumes that the there is an text input widget for the directory \
path in a task interface and this procedure is called if the user clicks a \
'Browse' button.
#d_arg arrayname Name of task interface array
#d_arg arrayindex Name of an element in the array which contains the directory name
  global dir
  global status

  upvar #0 $arrayname array

  set field [GetWidget $arrayname $arrayindex]
#puts "arrayindex: $arrayindex"
  if { $arrayindex == [GetCurrentProject] } {
      set status [SelectDir $arrayname dir -title "Select directory" -directory -parent $arrayname -defdir $arrayindex ]
  } else {
      set status [SelectDir $arrayname dir -title "Select directory" -directory -parent $arrayname -default $arrayindex ]
  }
  CheckDirecInput $arrayname $dir

  return $status
}

#-----------------------------------------------------------------
proc CheckDirecInput { arrayname dir } {
#-----------------------------------------------------------------
#d_sum Validate user input of directory path
#d_desc The procedure will handle input of ~ or environment variable
#d_desc The widget for the directory input is updated with status \
colour depending on the validity of the user input.
#d_arg arrayname Name of data array
#d_arg dir Array element containing directory path

  global system
  upvar #0 $arrayname array

  if { [regexp WINDOWS $system(OPSYS) ] } {
    regsub -all {\\} $dir \/ dirin 
  } else {
    set dirin $dir
  }

#  WarningMessage "dir $array($dir) dirin $dirin"

# Handle user input of ~ or an environment variable
  set path [file split [string trim $dirin] ]
  if {[llength $path] > 1} {
    set p1 [eval [concat file join [lrange $path 1 end ]]] 
  } else {
    set p1 ""
  }
  if [regexp ^~ [lindex $path 0 ]] {
    set $dir [FileJoin [glob [lindex $path 0]] $p1]
  } elseif [regexp {^\$} [lindex $path 0]] {
    set path1 [GetEnvPath [lindex $path 0] ]
    set $dir [FileJoin $path1 $p1 ]
  } else {
    set $dir $dirin
  }

  if { [file exists $dir] &&
       [file isdirectory $dir] } {
    set status 1
  } else {
    set status 0
  }
  set_field_colour $arrayname $dir $status
  return $status
}

#---------------
proc CreateListBox { boxframeVar } {
#---------------

# Drawing my own listbox (currently not available in ccp4i library). Draws box which holds items as a list. Each element in this list can be selected. Similar to Job Database in middle of main CCP4i window.

    global configure
    upvar $boxframeVar boxframe
    OpenSubFrame frame

    set boxframe [listbox $frame.list -height 10 -width 90 -yscroll "$frame.scrolly set" -xscroll "$frame.pad.scrollx set" -setgrid true -selectmode extended -font $configure(FONT_FIXED)  -selectbackground $configure(COLOUR_CONTRAST)]
    scrollbar $frame.scrolly -command "$frame.list yview"

    frame $frame.pad
    scrollbar $frame.pad.scrollx -orient horizontal -command "$frame.list xview"
    set pad [expr [$frame.scrolly cget -width] +2* \
	    ([$frame.scrolly cget -bd ] + \
	    [$frame.scrolly cget -highlightthickness ])]
    frame $frame.pad.it           -width $pad -height $pad
    
    pack $frame.pad               -side bottom -fill x
    pack $frame.pad.it            -side right
    pack $frame.pad.scrollx       -side bottom -fill x
    pack $frame.scrolly           -side right -fill y
    pack $frame.list              -side left -expand true -fill both
    


    CloseSubFrame

}

proc dhm_tool_clear { arrayname } {
    upvar #0 $arrayname array
    set clear_cursel [$array(BOXNAME) curselection]
#    puts "\n\nclear_cursel: $clear_cursel\n"
    set box_contents [ $array(BOXNAME) get 0 [ $array(BOXNAME) size ] ]
#    puts "box contents1: $box_contents\n"
    set elements {}

    for { set a 0 } { $a < [llength $clear_cursel] } { incr a } {
	lappend elements [lindex $box_contents [lindex $clear_cursel $a]]
#	puts "elements: $elements\n"
    }

    for { set b 0 } { $b < [llength $elements] } { incr b } {
	set search [lsearch $box_contents [lindex $elements $b]]
#	puts "search: $search\n"
	set box_contents [lreplace $box_contents $search $search]
#	puts "boxcontents2: $box_contents\n"
    }

    $array(BOXNAME) delete 0 [$array(BOXNAME) size]
    for { set c 0 } { $c < [llength $box_contents] } { incr c } {
	$array(BOXNAME) insert end [ lindex $box_contents $c ]
    }
}


proc dhm_tool_clearall { arrayname } {
    upvar #0 $arrayname array
    $array(BOXNAME) delete 0 [$array(BOXNAME) size]

}

proc dhm_tool_clearselection { arrayname } {
    upvar #0 $arrayname array

    $array(BOXNAME) selection clear 0 [$array(BOXNAME) size]

}



proc dhm_tool_fileview { arrayname } {
    upvar #0 $arrayname array
    set file_no [ $array(BOXNAME) curselection ]
    set numberoffiles [llength $file_no]

    if { $numberoffiles > 1 } {
	WarningMessage "Please select one file at a time"
    } elseif { $numberoffiles == 1 } {
	FileViewer [$array(BOXNAME) get $file_no]
    } elseif { $numberoffiles == 0 } {
	WarningMessage "Please choose a file to view"
    }


#Below is code to allow user to open more than one fileviewer at a time    
#    for { set viewcount 0 } { $viewcount < $numberoffiles } { incr viewcount } {
#	puts "lindex: [lindex $file_no $viewcount]"
#	puts "get: [$array(BOXNAME) get [lindex $file_no $viewcount]]"
#	FileViewer [$array(BOXNAME) get [lindex $file_no $viewcount]]
#	$array(BOXNAME) selection clear [lindex $file_no $viewcount]
#    }

}



#----------------------------------------------------------
proc dhm_tool_task_window { arrayname args } {
#----------------------------------------------------------
    
    upvar #0 $arrayname array
    global configure
    global env
    global count1
    global count2
    global preferences
    set count1 0 
    set count2 0
    

	if {$preferences(HARVEST_MODE) == "PROJECT"} {
		set array(HARVESTHOME) [FileJoin [GetDefaultDirPath] DepositFiles]
	} elseif {$preferences(HARVEST_MODE) == "HARVEST"} {
		set array(HARVESTHOME) [GetCentralDeposit]
	} else {
		set array(HARVESTHOME) [GetCurrentProject]
	}	
#	puts "HARVESTHOME: $array(HARVESTHOME)"
#	puts "dhm_tool Getdefaultdirpath: [GetDefaultDirPath $array(HARVESTHOME)]"


    DefineMenu _dhm_tool_harvestdirs [ListProjects]
    if { [ CreateTaskWindow $arrayname "Harvesting Manager" "Harvesting Manager" [ list "List of harvest files selected" "Programs" "Converting CIF to XML" "Extract information from data scaling, MR, phasing, DM, and refinement for PDB deposition" "Extracting information from reflection data scaling " "Extracting HA phasing information" "Extract molecular replacement information" "Extracting density modification information" "Extracting structure refinement information" "Generate a data_template file from the coordinate file (PDB or mmCIF format)" "Extract and merge all the information bellow to obtain a complete mmCIF file for PDB deposition" "Output"] \
	    {} -action_buttons [ list run save quit ] \
	    ] == 0 } return

# Select either default harvesting directory or current project directory
    OpenFolder protocol
    CreateTitleLine line TITLE
    set directory $array(HARVEST_DIRS)
    set select $array(SELECT)

    CreateLine line 
    button $line.mybutton -text "Open File Browser to select Harvesting Files" -command "dhm_tool_getprojects $arrayname"
    $line.mybutton configure -background $configure(COLOUR_PALE)
    SetMessage $arrayname $line.mybutton "Launch a file browser to search and select harvesting files"
    pack $line.mybutton -side top

    OpenFolder 1 open

# Draws the listbox
    CreateListBox box 
    set array(BOXNAME) $box

# Draws the drop-down menu of validation programs
    CreateLine line 
#    pack configure $line -anchor center

    button $line.clearselection -text "  Un-select all highlighted files  " -command "dhm_tool_clearselection $arrayname"
    $line.clearselection configure -background $configure(COLOUR_PALE)
    SetMessage $arrayname $line.clearselection "Un-select all highlighted files"
    pack $line.clearselection -side left

    button $line.harvclear -text "Remove selected files from box" -command "dhm_tool_clear $arrayname"
    $line.harvclear configure -background $configure(COLOUR_PALE)
    SetMessage $arrayname $line.harvclear "Remove the file selected in the box"
    pack $line.harvclear -side left
    
    CreateLine line
    button $line.harvclearall -text "    Remove all files from box     " -command "dhm_tool_clearall $arrayname"
    $line.harvclearall configure -background $configure(COLOUR_PALE)
    SetMessage $arrayname $line.harvclearall "Remove all files listed in the box"
    pack $line.harvclearall -side left

    button $line.viewharvfile -text "          View selected file           " -command "dhm_tool_fileview $arrayname" 
    $line.viewharvfile configure -background $configure(COLOUR_PALE)
    SetMessage $arrayname $line.viewharvfile "View the file selected in the box"
    pack $line.viewharvfile -side left

    OpenFolder 2 open
    CreateLine line label "Run Program to" message "Select program to run" widget RUN_PROGRAM -command "dhm_tool_control_var $arrayname "
    CreateLine line \
   	    message "Set to cross validate" \
	    widget CROSS \
	    label "Cross Validate Files" \
	    toggle_display RUN_PROGRAM open cross_validate

    OpenFolder 3 RUN_PROGRAM open cif2xml hide
    CreateOutputFileLine xml_output "Choose XML Output File Name" "File Name" XMLOUT DIR_XMLOUT 

    OpenFolder 4 RUN_PROGRAM open pdb_extract hide
    CreateLine line label "Extract information from" widget EXTRACT_STEP label "step using PDB_extract" 

    OpenFolder 5 EXTRACT_STEP open scaling hide
    CreateLine line label "Additional harvesting information will be extracted using the RCSB PDB_extract programs" -italic
    CreateLine line label "Extract information from output file of data scaling:  Select Program" widget SCALING
    CreateInputFileLine login "Declare program Log file" "LOG File   " SCALING_LOGIN DIR_SCALING_LOGIN
    CreateInputFileLine login "Declare program Log file" "LOG File   " SCALING1_LOGIN DIR_SCALING1_LOGIN
    CreateInputFileLine cifin "Declare mmCIF Harvest file from Phasing program used, if generated" "mmCIF File" SCALING_CIFIN DIR_SCALING_CIFIN
    CreateLine line label "\nOutput File"
    CreateOutputFileLine cifout "Declare output file name" "CIF File" SCALING_CIFOUT DIR_SCALING_CIFOUT
    
    OpenFolder 6 EXTRACT_STEP open phasing hide
    CreateLine line label "Additional harvesting information will be extracted using the RCSB PDB_extract programs" -italic
    CreateLine line label "Extract information from output file of phasing:  Method" widget EXP_MENU label "Select Program" widget PHASING
    CreateInputFileLine login "Declare program Log file from Phasing program used, if generated" "LOG File   " PHASING_LOGIN DIR_PHASING_LOGIN
    CreateInputFileLine login "Declare program Log file from Phasing program used, if generated" "LOG File   " PHASING1_LOGIN DIR_PHASING1_LOGIN
    CreateInputFileLine pdbin "Declare PDB file from Phasing program used, if generated" "PDB File   " PHASING_PDBIN DIR_PHASING_PDBIN
    CreateInputFileLine cifin "Declare mmCIF Harvest file from Phasing program used, if generated" "mmCIF File" PHASING_CIFIN DIR_PHASING_CIFIN
    CreateLine line label "\nOutput File"
    CreateOutputFileLine cifout "Declare output file name" "CIF File" PHASING_CIFOUT DIR_PHASING_CIFOUT


    OpenFolder 7 EXTRACT_STEP open replacement hide
    CreateLine line label "Additional harvesting information will be extracted using the RCSB PDB_extract programs" -italic
    CreateLine line label "Extract information from output file of molecular replacement:  Select Program" widget REPLACEMENT
    CreateInputFileLine login "Declare Log file from Molecular Replacement program used, if generated" "LOG File   " REPLACEMENT_LOGIN DIR_REPLACEMENT_LOGIN
    CreateInputFileLine login "Declare Log file from Molecular Replacement program used, if generated" "LOG File   " REPLACEMENT1_LOGIN DIR_REPLACEMENT1_LOGIN
    CreateInputFileLine cifin "Declare mmCIF  file from Molecular Replacement used, if generated" "mmCIF File" REPLACEMENT_CIFIN DIR_REPLACEMENT_CIFIN
    CreateLine line label "\nOutput File"
    CreateOutputFileLine cifout "Declare output file name" "CIF File" REPLACEMENT_CIFOUT DIR_REPLACEMENT_CIFOUT


    OpenFolder 8 EXTRACT_STEP open den_mod hide
    CreateLine line label "Additional harvesting information will be extracted using the RCSB PDB_extract programs" -italic
    CreateLine line label "Extract information from output file of density modification:  Select Program" widget DEN_MOD
    CreateInputFileLine login "Declare program Log file from density modification used" "LOG File   " DM_LOGIN DIR_DM_LOGIN
    CreateInputFileLine cifin "Declare mmCIF Harvest file from density modification used, if generated" "mmCIF File" DM_CIFIN DIR_DM_CIFIN
    CreateLine line label "\nOutput File"
    CreateOutputFileLine cifout "Declare output file name" "CIF File" DM_CIFOUT DIR_DM_CIFOUT


    OpenFolder 9 EXTRACT_STEP open refinement hide
    CreateLine line label "Additional harvesting information will be extracted using the RCSB PDB_extract programs" -italic
    CreateLine line label "Extract information from output file of structure refinement:  Select Program" widget REFINEMENT
    CreateInputFileLine pdbin "Declare final PDB file from Refinement program used, if generated" "PDB File   " REFINE_PDBIN DIR_REFINE_PDBIN
    CreateInputFileLine cifin "Declare mmCIF Harvest file from Refinement program used, if generated" "mmCIF File" REFINE_CIFIN DIR_REFINE_CIFIN
    CreateInputFileLine login "Declare program Log file from Refinement program used, if generated" "LOG File   " REFINE_LOGIN DIR_REFINE_LOGIN
    CreateLine line label "\nOutput File"
    CreateOutputFileLine cifout "Declare output file name" "CIF File" REFINE_CIFOUT DIR_REFINE_CIFOUT


    OpenFolder 10 EXTRACT_STEP open data_template hide
    CreateInputFileLine pdbin "Declare a data template file, if generated" "PDB File  " TEMPLATE_PDBIN DIR_TEMPLATE_PDBIN
    CreateLine line label "OR "
    CreateInputFileLine login "Declare a data template file, if generated" "mmCIF File" TEMPLATE_LOGIN DIR_TEMPLATE_LOGIN
    CreateLine line label "\nOutput File"
    CreateOutputFileLine cifout "Declare output file name" "File Name" TEMPLATE_CIFOUT DIR_TEMPLATE_CIFOUT



# For all the files (merge all the steps to generate a complete mmCIF file)
    OpenFolder 11 EXTRACT_STEP open merge hide
    CreateLine line label "Additional harvesting information will be extracted using the RCSB PDB_extract programs" -italic

#    for  scaling 
    CreateLine line label " "
    CreateLine line label "Extract information from output file of data scaling:  Select Program" widget SCALING
    CreateInputFileLine login "Declare program Log file" "LOG File   " SCALING_LOGIN DIR_SCALING_LOGIN
    CreateInputFileLine login "Declare program Log file" "LOG File   " SCALING1_LOGIN DIR_SCALING1_LOGIN
    CreateInputFileLine cifin "Declare mmCIF Harvest file from Phasing program used, if generated" "mmCIF File" SCALING_CIFIN DIR_SCALING_CIFIN
    
 #  for phasing
    CreateLine line label ""
    CreateLine line label "Extract information from output file of phasing:  Method" widget EXP_MENU label "Select Program" widget PHASING
    CreateInputFileLine login "Declare program Log file from Phasing program used, if generated" "LOG File   " PHASING_LOGIN DIR_PHASING_LOGIN
    CreateInputFileLine login "Declare program Log file from Phasing program used, if generated" "LOG File   " PHASING1_LOGIN DIR_PHASING1_LOGIN
    CreateInputFileLine pdbin "Declare PDB file from Phasing program used, if generated" "PDB File   " PHASING_PDBIN DIR_PHASING_PDBIN
    CreateInputFileLine cifin "Declare mmCIF Harvest file from Phasing program used, if generated" "mmCIF File" PHASING_CIFIN DIR_PHASING_CIFIN

#  for  mr
    CreateLine line label " "
    CreateLine line label "Extract information from output file of molecular replacement:  Select Program" widget REPLACEMENT
    CreateInputFileLine login "Declare program Log file from Molecular Replacement program used, if generated" "LOG File   " REPLACEMENT_LOGIN DIR_REPLACEMENT_LOGIN
    CreateInputFileLine login "Declare program Log file from Molecular Replacement program used, if generated" "LOG File   " REPLACEMENT1_LOGIN DIR_REPLACEMENT1_LOGIN
    CreateInputFileLine cifin "Declare mmCIF Harvest file from Molecular Replacement used, if generated" "mmCIF File" REPLACEMENT_CIFIN DIR_REPLACEMENT_CIFIN

#  for dm
    CreateLine line label " "
    CreateLine line label "Extract information from output file of density modification:  Select Program" widget DEN_MOD
    CreateInputFileLine login "Declare program Log file from density modification used" "LOG File   " DM_LOGIN DIR_DM_LOGIN
    CreateInputFileLine cifin "Declare mmCIF Harvest file from density modification used, if generated" "mmCIF File" DM_CIFIN DIR_DM_CIFIN

#  for refine
    CreateLine line label " "
    CreateLine line label "Extract information from output file of structure refinement:  Select Program" widget REFINEMENT
    CreateInputFileLine pdbin "Declare final PDB file from Refinement program used, if generated" "PDB File   " REFINE_PDBIN DIR_REFINE_PDBIN
    CreateInputFileLine cifin "Declare mmCIF Harvest file from Refinement program used, if generated" "mmCIF File" REFINE_CIFIN DIR_REFINE_CIFIN
    CreateInputFileLine login "Declare program Log file from Refinement program used, if generated" "LOG File   " REFINE_LOGIN DIR_REFINE_LOGIN

#  for data_template
    CreateLine line label " "
    CreateLine line label "Extract information from data_template file (generated from the previous step)" 
#    CreateInputFileLine pdbin "Declare data_template file" "Data_template File Name" TEMPLATE_PDBIN DIR_TEMPLATE_PDBIN
    CreateInputFileLine login "Declare data_template file" "Data_template File Name" TEMPLATE_LOGIN DIR_TEMPLATE_LOGIN
    CreateLine line label " "

    CreateLine line label " "
    CreateLine line label "Output File"
    CreateOutputFileLine cifout "Declare output file name" "Output mmCIF File" MERGE_CIFOUT DIR_MERGE_CIFOUT


    OpenFolder 12 closed
    CreateText outputframe " " -scroll
    set array(OUTPUTFRAME) $outputframe

}


#-----------------------------------------------------------
proc dhm_tool_control_var { arrayname } {
#-----------------------------------------------------------
    upvar #0 $arrayname array

    if { $array(RUN_PROGRAM) == "Convert CIF to XML" || $array(RUN_PROGRAM) == "Validate Harv. Files" } {
	set array(EXTRACT_STEP) ""
    }
}

#-----------------------------------------------------------
proc dhm_tool_getprojects { arrayname } {
#-----------------------------------------------------------
    global env
    global count1
    global count2
    global ls
    global ls2
    global x1
    global x2
    global x
    global projects
    global preferences
    global dir

    upvar #0 $arrayname array

    if { $preferences(HARVEST_MODE) == "PROJECT" } {
	if { [glob -nocomplain -dir [FileJoin [GetFullDirName [GetCurrentProject]] DepositFiles] * ] == "" } {
	    DirecBrowser $arrayname [GetCurrentProject]
	} else {
	    DirecBrowser $arrayname [FileJoin [GetFullDirName [GetCurrentProject]] DepositFiles]
	}
    } elseif { $preferences(HARVEST_MODE) == "HARVEST" } {
	DirecBrowser $arrayname [FileJoin [GetCentralDeposit] DepositFiles]
    } elseif { $preferences(HARVEST_MODE) == "CURRENTDIR" } {
	DirecBrowser $arrayname [GetCurrentProject]
    } elseif { $preferences(HARVEST_MODE) == "NOHARVEST" } {
	DirecBrowser $arrayname [GetCurrentProject]
    }

}

#------------------------------------------------------------------------
proc dhm_tool_getdatasets { arrayname dir } {
#------------------------------------------------------------------------

# After one of the projectnames is selected the list of datasets is returned as a list in the BOXNAME widget. Specifies the full pathname of the file.

    upvar #0 $arrayname array
    global x
    global d_sets
    global projects
    global status

    set filext [ list scala refmac truncate mlphare ]

#    if { $status==0 } {
#	puts "getdatasets return 0"
#	return 0
 #   } elseif { $status == 1 } {
	#puts "getdatasets return 1"
	#puts "dir: $dir"
	set d_sets {}

	lappend d_sets $dir
	
	for { set y 0 } { $y<[llength $d_sets] } { incr y } {
	    $array(BOXNAME) insert end [lindex $d_sets $y]
	}




#	for {set c 0} {$c<[llength $filext]} {incr c} {
#	    if {[catch [lappend d_sets [glob -dir $dir *.[lindex $filext $c] ]] fid ] } {
#	    }
#	}
#	if { [llength $d_sets] == 0 } {
#	    WarningMessage "No files found. Check directory path"
#	}
#    }
#    for { set y 0 } { $y<[llength $d_sets] } { incr y } {
#	$array(BOXNAME) insert end [lindex $d_sets $y]
#    }

}


proc dhm_tool_getsetsfromdir { arrayname dir2 } {

    upvar #0 $arrayname array

    set d_sets_dir {}
#    puts "dir2: $dir2"
#    puts "glob: $d_sets_dir"

#    set d_sets_dir [glob -dir $dir2 *]
    #set d_sets_dir [lsort [glob -dir $dir2 -types {f r w} * ]]

    if {[catch [set d_sets_dir [lsort [ glob -dir $dir2 -types {f r w} * ]] ] fid ] } {
	if { [llength $d_sets_dir]==0 } {
	    WarningMessage "No files in current location found"
	}	
    }
    
    for { set y 0 } { $y<[llength $d_sets_dir] } { incr y } {
	$array(BOXNAME) insert end [lindex $d_sets_dir $y]
    }
    

}

#------------------------------------------------------------------------
proc dhm_tool_run { arrayname } {
#------------------------------------------------------------------------
    upvar #0 $arrayname array

    global sel_dsets
 
#sets sel_dsets as a list rather than a string, but then converts the sel_dsets into string using 'join'. This string is then used to specify the number of files and filenames for the MMDB applications.
    set array(INFILES) ""
    set array(INPUT_FILES) ""
    set array(OUTPUT_FILES) ""
    set array(XML) 0
    set array(PDB_EXTRACT) 0
    set sel_dsets {}
    set cursel [ $array(BOXNAME) curselection ]
    set length_cursel [ llength $cursel ]
    for { set y1 0 } { $y1 < $length_cursel } { incr y1 } {
	set lindex_cursel [lindex $cursel $y1]
	lappend sel_dsets [$array(BOXNAME) get $lindex_cursel]
    }
    set array(INFILES) [join $sel_dsets]

    if { $array(RUN_PROGRAM) == "Validate Harv. Files" } {
	if { [llength [$array(BOXNAME) curselection]] < 1 } {
	    WarningMessage "Please select file(s) from above to validate"
	    return 0
	}
	for {set arx 0} {$arx < [llength $array(INFILES)]} {incr arx} {
	    set array(INFILE$arx) [lindex $array(INFILES) $arx]
	    append array(INPUT_FILES) " INFILE$arx"
	}
    }
    
    if { $array(RUN_PROGRAM) == "Convert CIF to XML" } {
	if { $array(XMLOUT) == "" } {
	    WarningMessage "Please declare an output XML file name"
	    return 0
	} else {
	    set array(INPUT_FILES) INFILES
	    set array(OUTPUT_FILES) XMLOUT
	}

	if { [llength [$array(BOXNAME) curselection]] < 1 } {
	    WarningMessage "Please select file(s) from above to convert to XML"
	    return 0
	}

	if { [llength [$array(BOXNAME) curselection]] > 1} {
	    set action [ChooseOptionDialog "Harvesting Manager Warning" "Harvesting Manager Warning" "You have selected more than one file to convert to XML. Please select only one file from list before running cif2xml" { OK } ]
	    if [regexp OK $action] {
		return 0
	    }
	}
    }

    if { $array(RUN_PROGRAM) == "Convert CIF to XML" } {
	if {[glob -nocomplain -dir [GetDefaultDirPath $array(DIR_XMLOUT)] $array(XMLOUT)]!=""} {
	    set action2 [ChooseOptionDialog "Harvesting Manager Warning" "Harvesting Manager Warning" "File already exists. Pressing Continue will overwrite,\nor you can Cancel and choose another filename" { Cancel Continue } -default 1 ]
	    if [regexp Cancel $action2] { 
		return 0 
	    }
	}
    }
    
    if { $array(RUN_PROGRAM) == "Convert CIF to XML" } {
	set array(XML) 1
    }

    if { $array(RUN_PROGRAM) == "Extract additonal information for deposition" } {

	if { $array(EXTRACT_STEP) == "Data Scaling" } {
	    if { $array(SCALING) == "" } {
		WarningMessage "No Scaling Program Selected"
		return 0
	    }
	    if { $array(SCALING_CIFOUT) == "" } {
		WarningMessage "No output CIF file declared"
		return 0
	    } else {
		set array(PDB_EXTRACT) 1
                set array(INPUT_FILES) ""

		if { $array(SCALING_CIFIN) != "" } {
		    append array(INPUT_FILES) " SCALING_CIFIN"
		}
		if { $array(SCALING_LOGIN) != "" } {
		    append array(INPUT_FILES) " SCALING_LOGIN"
		}
		if { $array(SCALING1_LOGIN) != "" } {
		    append array(INPUT_FILES) " SCALING1_LOGIN"
		}

		set array(OUTPUT_FILES) SCALING_CIFOUT
	    }
	    
	    
	}



	if { $array(EXTRACT_STEP) == "Heavy Atom Phasing" } {
	    if { $array(PHASING_CIFOUT) == "" } {
		WarningMessage "No output CIF file declared"
		return 0
	    }
            if { $array(EXP_MENU) == "" } {
		WarningMessage "No experimental method delared"
		return 0
	    }
	    if { $array(PHASING) == "" } {
		WarningMessage "No Phasing Program Selected"
		return 0
	    } else {
		set array(PDB_EXTRACT) 1
                set array(INPUT_FILES) ""

		if { $array(PHASING_PDBIN) != "" } {
		    append array(INPUT_FILES) " PHASING_PDBIN"
		}
		if { $array(PHASING_CIFIN) != "" } {
		    append array(INPUT_FILES) " PHASING_CIFIN"
		}
		if { $array(PHASING_LOGIN) != "" } {
		    append array(INPUT_FILES) " PHASING_LOGIN"
		}
		if { $array(PHASING1_LOGIN) != "" } {
		    append array(INPUT_FILES) " PHASING1_LOGIN"
		}
		set array(OUTPUT_FILES) PHASING_CIFOUT
	    }
	}

	if { $array(EXTRACT_STEP) == "Molecular Replacement" } {
	    if { $array(REPLACEMENT_CIFOUT) == "" } {
		WarningMessage "No output CIF file declared"
		return 0
	    }
	    if { $array(REPLACEMENT) == "" } {
		WarningMessage "No Molecular Replacement program selected"
		return 0
	    }
	    if { $array(REPLACEMENT_LOGIN) == "" } {
		WarningMessage "No Molecular Replacement LogFile declared"
	    } else {
		set array(PDB_EXTRACT) 1
		set array(INPUT_FILES) ""
		
		if { $array(REPLACEMENT_LOGIN) != "" } {
		    append array(INPUT_FILES) " REPLACEMENT_LOGIN"
		}
		if { $array(REPLACEMENT1_LOGIN) != "" } {
		    append array(INPUT_FILES) " REPLACEMENT1_LOGIN"
		}
		if { $array(REPLACEMENT_CIFIN) != "" } {
		    append array(INPUT_FILES) " REPLACEMENT_CIFIN"
		}
		set array(OUTPUT_FILES) REPLACEMENT_CIFOUT
	    }
	}


	if { $array(EXTRACT_STEP) == "Density modification" } {
	    if { $array(DM_LOGIN) == "" } {
		WarningMessage "No input LOG file declared"
		return 0
	    }
	    if { $array(DM_CIFOUT) == "" } {
		WarningMessage "No output CIF file declared"
		return 0
	    }
	    if { $array(DEN_MOD) == "" } {
		WarningMessage "No density modification program selected"
		return 0
	    } else {
		set array(PDB_EXTRACT) 1
		set array(INPUT_FILES) ""

		if { $array(DM_LOGIN) != "" } {
		    append array(INPUT_FILES) " DM_LOGIN"
		}
		if { $array(REPLACEMENT_CIFIN) != "" } {
		    append array(INPUT_FILES) " DM_CIFIN"
		}
		set array(OUTPUT_FILES) DM_CIFOUT
	    }
	}
	if { $array(EXTRACT_STEP) == "Structure Refinement" } {
	    if { $array(REFINE_CIFOUT) == "" } {
		WarningMessage "No output CIF file declared"
		return 0
	    }
	    if { $array(REFINEMENT) == "" } {
		WarningMessage "No refinement program selected"
		return 0
	    } else {
		set array(PDB_EXTRACT) 1
		set array(INPUT_FILES) ""
		
		if { $array(REFINE_PDBIN) != "" } {
		    append array(INPUT_FILES) " REFINE_PDBIN"
		}
		if { $array(REFINE_LOGIN) != "" } {
		    append array(INPUT_FILES) " REFINE_LOGIN"
		}
		if { $array(REFINE_CIFIN) != "" } {
		    append array(INPUT_FILES) " REFINE_CIFIN"
		}
		set array(OUTPUT_FILES) REFINE_CIFOUT
	    }
	}

	if { $array(EXTRACT_STEP) == "Generate a data template" } {
	    if { $array(TEMPLATE_CIFOUT) == "" } {
		WarningMessage "No output mmCIF file declared"
		return 0
	    }

 	    if { $array(TEMPLATE_PDBIN) == "" && $array(TEMPLATE_LOGIN) == ""} {
		WarningMessage "No input PDB (or mmCIF) file declared"
		return 0
	    }

            set array(PDB_EXTRACT) 1
            set array(INPUT_FILES) ""
		if { $array(TEMPLATE_PDBIN) != "" } {
		    append array(INPUT_FILES) " TEMPLATE_PDBIN"
		}
		if { $array(TEMPLATE_LOGIN) != "" } {
		    append array(INPUT_FILES) " TEMPLATE_LOGIN"
		}

#            set array(INPUT_FILES) TEMPLATE_PDBIN
            set array(OUTPUT_FILES) TEMPLATE_CIFOUT
	}

	if { $array(EXTRACT_STEP) == "Generate a complete mmCIF file for PDB deposition" } {
	    if { $array(MERGE_CIFOUT) == "" } {
		WarningMessage "No output CIF file declared"
		return 0
	    }
		set array(PDB_EXTRACT) 1
		set array(INPUT_FILES) ""
		
		if { $array(MERGE1_CIFIN) != "" } {
		    append array(INPUT_FILES) " MERGE1_CIFIN"
		}
		if { $array(MERGE2_CIFIN) != "" } {
		    append array(INPUT_FILES) " MERGE2_CIFIN"
		}
		if { $array(MERGE3_CIFIN) != "" } {
		    append array(INPUT_FILES) " MERGE3_CIFIN"
		}
		if { $array(MERGE4_CIFIN) != "" } {
		    append array(INPUT_FILES) " MERGE4_CIFIN"
		}
		if { $array(MERGE5_CIFIN) != "" } {
		    append array(INPUT_FILES) " MERGE5_CIFIN"
		}
		set array(OUTPUT_FILES) MERGE_CIFOUT
	    
	}


    }

    return 1

}

#--------------------------
proc dhm_tool_review { arrayname job_id } {
#--------------------------

    upvar #0 $arrayname array

#    FileViewer [GetLogFileName $job_id]
    ReadFile [GetLogFileName $job_id] logcontents
    AppendTextWindow $array(OUTPUTFRAME) $logcontents

    AppendTextWindow $array(OUTPUTFRAME) "----------------------------------------------------------------------------------"
}












