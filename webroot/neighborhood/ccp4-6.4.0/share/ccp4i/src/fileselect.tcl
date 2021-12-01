#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - fileselect.tcl
#
#
#====================================================================

#CCP4i_cvs_Id $Id$

#d_index_title File Selection Window (src/fileselect.tcl)
#d_intro_title File Selection Window
#d_intro The procedures in fileselect.tcl control the display of the file \
selection window.  The window can be significantly customised by the \
application programmer.
#d_intro File types, extensions and viewers are defined in etc/types.def

#--------------------------------------------------------------------
proc SelectFile { fileoutVar args } {
#--------------------------------------------------------------------
#d_sum Open a file selection window
#d_ref CCP4I programmers/SelectFile.html See Programmers Documentation
# fileselect returns the selected pathname, or {}
# if the -return flag is set then it will return a list of
# specified data
  upvar $fileoutVar fileout
  global fileselect
  global configure
  global system
  global typedef
  global preferences

  set frame .fileselect
  if {[winfo exist $frame]} {
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
       # WARNING: this is over-ridden by the last browsed-to
       # directory later on
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
       set fileselect(EXTENSION) ""
       foreach item [split $fileselect(FILTER) ", "] {
	  lappend fileselect(EXTENSION) [string range $item 1 end]
       }
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

  # Restore defaults - last directory browsed to
  if { [info exists preferences(LAST_BROWSE_DIR)] } {
      # Only restore the last directory browsed to if it's not
      # a project or data directory
      if { ![DirIsProject $preferences(LAST_BROWSE_DIR)] } {
	  set fileselect(DIR) $preferences(LAST_BROWSE_DIR)
	  set fileselect(DEFDIR) $preferences(LAST_BROWSE_DEFDIR)
      }
  }

  if { $fileselect(DIR) == {} } {
    set fileselect(DIR) [GetDefaultDirPath $fileselect(DEFDIR)]
  }

  if { $fileselect(SETFILETYPE) && $fileselect(FILTER) == "" } { fileselectFilter }

  if {$fileselect(SETFILETYPE)} { 
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

  # Define behaviour which should occur when the window manager is used
  # to delete the window
  wm protocol $frame WM_DELETE_WINDOW fileselectCancel

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


        
  if {$fileselect(IFDIRECTORY)} {
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

  set height 12
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
        -width $width ]
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
  bind $filelist <space> "fileselectTake $%W ; focus $file_line.e2"
  bind $filelist <Button-1> \
                "fileselectClick %W %y ; focus $file_line.e2"
  bind $filelist <Return> "fileselectTake %W ; fileselectOK"
  bind $filelist <Double-Button-1> \
                "fileselectClick %W %y ; fileselectOK -finish"

  bind $dirlist <Button-1> \
                "dirselectClick %W %y ; focus $file_line.e2"
  bind $dirlist <Double-Button-1> \
                "dirselectClick %W %y ; fileselectOK -finish"

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
    set quit [CreateButton $frame quit Cancel fileselectCancel]
    set ok [CreateButton $frame ok OK "fileselectOK -finish" ]
    SetMessage fileselect $quit "Exit without selecting file"
    SetMessage fileselect $ok "Exit and save the currently selected file"
  }

  SetMessage fileselect $dirlist "List of subdirectories"
  SetMessage fileselect $filelist "List of files which satisfy selection criteria"


  # Wait for the listbox to be visible so
  # we can provide feedback during the listing 
  tkwait visibility  $filelist
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
proc  fileselectDefdir { defdir dir  } {
#-------------------------------------------------------------------
#d_sum Update file list when user changes the default directory alias
#d_arg defdir  The array element for the default directory alias
#d_arg dir The array element for the file name
  global fileselect

  set fileselect($dir) [GetDefaultDirPath $fileselect($defdir)] 
  fileselectList $fileselect($dir)
}

#------------------------------------------------------------------
proc fileselectFilter { } {
#------------------------------------------------------------------
#d_sum Handle user changing the filetype selection filter

  global fileselect
  set pp [max 0 [lsearch $fileselect(ALIASLIST) \
		[GetValue fileselect FILETYPE]]]
  set fileselect(FILTER) {}
  set fileselect(EXTENSION) [lindex $fileselect(EXTLIST) $pp]
  foreach ext [lindex $fileselect(EXTLIST) $pp] {
    lappend fileselect(FILTER)  "*$ext"
  }
}

#------------------------------------------------------------------
proc fileselectViewers {} {
#------------------------------------------------------------------
#d_sum Set up the menu to allow user to select a viewer for a given file type.

  global fileselect
  if {[GetViewerList [GetValue fileselect FILETYPE] viewerlist viewercmdlist ]} {
    set fileselect(SELECT_VIEWER) 1
    UpdateVariableMenu fileselect initialise  0 VIEWER_LIST  $viewerlist \
	VIEWERCMD_LIST $viewercmdlist
    set fileselect(VIEWER) [lindex $viewerlist 0]
  } else {
    set fileselect(SELECT_VIEWER) 0
  }
}

#-----------------------------------------------------------------------
proc fileselectList { dir {input_files {}} args } {
#-----------------------------------------------------------------------
#d_sum Update list of directories and files visible to user
#d_arg dir The currently selected directory
#d_arg input_files (Optional).  Predefined list of files to be displayed.
#d_opt0 -drive
#d_opt1 Displays the list of drives when reaching the top of directory tree under windows

  global fileselect
  
 #checking if we just want to display drives
  if {[lsearch $args "-drive"]>-1} { 
    set drive 1
  } else {
    set drive 0
  }

#avoiding checking when displaying drives
  if {$drive==0} {
    if {![file isdirectory $dir]} {
      set dir [GetCurrentDir]
    }
  }

  set fileselect(DIR) $dir
  set dir_field [GetWidget fileselect DIR_CONTENTS]
  $dir_field delete 0 end
  set file_field [GetWidget fileselect FILE_CONTENTS]
  $file_field delete 0 end
  $file_field insert 0 Listing...

  update idletasks
  $file_field delete 0

  # Cache the information on files etc
  set fileselect(DATA_ALL_FILES) {}
  set fileselect(DATA_DIR_FILES) {}
  set fileselect(DATA_MTIME_CACHE) {}
  set fileselect(DATA_MTIMES) {}
 
  #we skip the setting of list of subdirectories and files when displayin drives
  #and we set it to the drives in the else condition.
  if {$drive==0} {
    # List all files
    if {[catch "glob -nocomplain {[FileJoin $fileselect(DIR) * ]}" allfiles ] } {
      WarningMessage "Can not search [FileJoin $fileselect(DIR) * ]
      Probably a protected directory"
    }
    set fileselect(DATA_ALL_FILES) $allfiles
    # List only directories
    set dirfiles [glob -types { d } -nocomplain "[FileJoin $fileselect(DIR) * ]"]
    set fileselect(DATA_DIR_FILES) $dirfiles
    set dirs {}
    set others {}
    foreach f $allfiles {
      if { [fileselectIsDirectory $f] } {
	# It's a directory
        if { $f != $fileselect(DIR) } { lappend dirs [file tail $f] }
      } else {
        # It's something else
	lappend others $f
      }
    }
    set dirs [sort_files name $dirs]
  } else {
    set dirs [file volume]
    set dirs [sort_files drive $dirs]
    set others {}
  }
  display_file_list $dir_field name $dirs

  if { [lindex $input_files 0] != {} } { 

    display_file_list $file_field [GetValue fileselect LISTINFO] $input_files

  } elseif { $fileselect(FILTER) == "" } {

    display_file_list $file_field  [GetValue fileselect LISTINFO] \
	[sort_files $fileselect(SORT) $others]

  } else {

    set filter_files {}
    foreach flt  [split $fileselect(FILTER) ", "] {
      foreach f [glob -nocomplain [FileJoin $fileselect(DIR) $flt ]] {
	if { [file exists $f] } { lappend filter_files $f }
      }
    }
    set others ""
    foreach f $filter_files { 
      if { ![fileselectIsDirectory $f] } { lappend others $f }
    }
    display_file_list $file_field [GetValue fileselect LISTINFO] \
        [sort_files $fileselect(SORT) $others]
  }
}

#----------------------------------------------------------
proc fileselectOK {args} {
#----------------------------------------------------------
#d_sum Handle user selection of a file or directory
#d_desc User has selected a file or directory from the lists, or has hit return \
in the text input widget or has clicked OK button.  This procedure checks the \
input is sensible and updates text input widget, file and directory lists. \
If the input is appropriate then fileselect(DONE) is set to true (1).  \
This variable is being 'watched' by a tkwait command and when it changes \
control returns to the SelectFile procedure which closes the file \
selection window.
#d_opt0 -finish
#d_opt1 Exit the file selection window if the input is OK.

  global fileselect
  global preferences

  if { [llength $args] > 0 && [lsearch $args "-finish"] >= 0 } {
    set finish 1
  } else { 
    set finish 0
  }
#  puts "before CheckFileInput $fileselect(FILNAM) $fileselect(DEFDIR) $fileselect(DIR)"

  if { [StringSame "$fileselect(DEFDIR)" "[GetSystemVar PATHNAME_LABEL]" ]  } {
    if { [file exists [FileJoin $fileselect(DIR) $fileselect(FILNAM)]] } {
      set fileselect(FILNAM) [FileJoin $fileselect(DIR) $fileselect(FILNAM)]
    }
  } 
  
set status [CheckFileInput fileselect FILNAM $fileselect(OPENMODE) DEFDIR \
			-ext $fileselect(EXTENSION) ]

# Store the current selection
  set preferences(LAST_BROWSE_DIR) $fileselect(DIR)
  set preferences(LAST_BROWSE_DEFDIR) $fileselect(DEFDIR)
#
# Need to sort out what DIR is
  if { ![StringSame "$fileselect(DEFDIR)" "[GetSystemVar PATHNAME_LABEL]" ] }  {
    set fileselect(DIR) [GetDefaultDirPath $fileselect(DEFDIR)]
    set path [FileJoin $fileselect(DIR) $fileselect(FILNAM)]
  } else {
    set path $fileselect(FILNAM)
    if { [file isdirectory $fileselect(FILNAM)]  } {
      set fileselect(DIR) $fileselect(FILNAM)
      set fileselect(FILNAM) ""
    } elseif { ![StringSame [file dirname $fileselect(FILNAM)] "."] && \
	 [file isdirectory [file dirname $fileselect(FILNAM)] ] } {
      set fileselect(DIR) [file dirname $fileselect(FILNAM)]
      set fileselect(FILNAM) [file tail $fileselect(FILNAM)]
    }
  }
# Its a file 

  if { $status && $fileselect(IFVIEW) } { FileViewer $path \
	-format [GetValue fileselect FILETYPE] \
	-viewer [GetValue fileselect VIEWER] -noquery }

  if { $finish && ($status || [regexp save $fileselect(OPENMODE)]) } {
    set fileselect(DONE) 1
    return
  }

#  puts "fileselectOK path $path"

# Its a directory..
  if { [file isdirectory $path] } {
    if { $fileselect(IFDIRECTORY) && $finish } {
#      set fileselect(FILNAM) $path
      set fileselect(DONE) 1
    } else {
      fileselectList $path
    }
    return
  }

# Search for file completions
  set globlist {}
  foreach ext $fileselect(EXTENSION) {
    foreach gbfile  [glob -nocomplain [file rootname $path]*$ext] {
      if { [file exists $gbfile] } { lappend globlist $gbfile }
    }
  }
  if { ![catch {sort_files $fileselect(SORT) $globlist} sortedlist ] } {
    if { ! $fileselect(IFVIEW) } {
       # Update the list to only display matches to the selection
       # - except in "View Any File" mode
       fileselectList $fileselect(DIR) $sortedlist
    }
  }
}


#--------------------------------------------------------------
proc fileselectCancel {} {
#--------------------------------------------------------------
#d_sum Handle user clicking the cancel button.
#d_desc Sets the fileselect(DONE) variable which causes control to pass to \
FileSelect procedure and to close file selection window.

	global fileselect
	set fileselect(DONE) 0
	set fileselect(FILNAM) {}
}

#--------------------------------------------------------------
proc fileselectClick { lb y } {
#--------------------------------------------------------------
#d_sum Take the file item the user clicked on in listbox
#d_arg lb listbox id
#d_arg y Y position of click in listbox

	# Take the item the user clicked on
	global fileselect
        set selection [$lb get [$lb nearest $y]]
	set fileselect(FILNAM) [lindex $selection end]
}

#--------------------------------------------------------------
proc dirselectClick { lb y } {
#--------------------------------------------------------------
#d_sum Take the directory item the user clicked on
#d_arg lb listbox id
#d_arg y Y position of click in listbox

        # Take the item the user clicked on
        global fileselect
        set selection [$lb get [$lb nearest $y]]
        set fileselect(FILNAM) $selection
        set path [FileJoin $fileselect(DIR) $fileselect(FILNAM)]
        if { [file isdirectory $path] } { fileselectOK }
}

#--------------------------------------------------------------
proc fileselectTake { lb } {
#--------------------------------------------------------------
#d_sum Take the currently selected list item
#d_arg lb listbox id

	# Take the currently selected list item
	global fileselect
	set fileselect(FILNAM) [lindex [$lb get [$lb curselection]] end]
}

#----------------------------------------------------------------
proc fileselectComplete {} {
#----------------------------------------------------------------
#d_sum Do file name completion for the file name in the input text widget

  global fileselect

  # Do file name completion
  # Nuke the space that triggered this call
  set lin [string length $fileselect(FILNAM)]
  set fileselect(FILNAM) [string trim $fileselect(FILNAM) ]

  # Figure out what directory we are looking at
  # dir is the directory
  # tail is the partial name
  if {[string match /* $fileselect(FILNAM)]} {
    set dir [file dirname $fileselect(FILNAM)]
    set tail [file tail $fileselect(FILNAM)]
  } elseif {[string match ~* $fileselect(FILNAM)]} {
    if {[catch {file dirname $fileselect(FILNAM)} dir]} {
    	return	;# Bad user
    }
    set tail [file tail $fileselect(FILNAM)]
  } else {
    set path [FileJoin $fileselect(DIR) $fileselect(FILNAM)]
    set dir [file dirname $path]
    set tail [file tail $path]
  }

  # See what files are there
  set status [catch  "glob -nocomplain $dir/$tail*" files ]
  if {[llength [split $files]] == 1 && \
    ( !$fileselect(IFDIRECTORY) || [file isdirectory $files] ) } {
    # Matched a single file
    if { $fileselect(IFDIRECTORY) } {
      set fileselect(DIR) $files
      set fileselect(FILNAM) {}
      fileselectList $fileselect(DIR)
    } else {
      set fileselect(DIR) $dir
      set fileselect(FILNAM) [file tail $files]
    }
    return
  } else {
    if {[llength [split $files]] > 1} {
    	# Find the longest common prefix
    	set l [expr {[string length $tail]-1}]
    	set miss 0
    	# Remember that files has absolute paths
    	set file1 [file tail [lindex $files 0]]
    	while {!$miss} {
    	  incr l
    	  if {$l == [string length $file1]} {
    	    # file1 is a prefix of all others
    	    break
    	  }
    	  set new [string range $file1 0 $l]
    	  foreach f $files {
    	    if {![string match $new* [file tail $f]]} {
    	      set miss 1
    	      incr l -1
    	      break
            }
    	  }
       }
    }
    if { [info exists file1 ] } {
      set fileselect(FILNAM) [string range $file1 0 $l]
    }
    fileselectList $dir $files
  }
}

#----------------------------------------------------------------
proc up_directory { } {
#----------------------------------------------------------------
#d_sum Handle user selection of the 'go up a directory' widget

  global fileselect 

  if { [llength [file split $fileselect(DIR)]] > 1 } {  
    set dir [file dirname $fileselect(DIR)]
    set fileselect(FILNAM) ""
    set fileselect(DIR) $dir
    set fileselect(DEFDIR) [GetSystemVar PATHNAME_LABEL]
    fileselectList $dir
	# adding some work if the path reach the top of directories tree
	# under linux it reach the root directory but for windows it only
	# reach the top directories of one drive. When reaching there under windows
	# we then display the different drives available.
  } else {
    if {[regexp WINDOWS [GetSystemVar OPSYS]]} {
      set fileselect(DEFDIR) [GetSystemVar PATHNAME_LABEL]
      set fileselect(DIR) ""
      set fileselect(FILNAM) ""
      fileselectList "" {} -drive
	}
  }
}

#---------------------------------------------------------------
proc sort_files { mode filelist } {
#---------------------------------------------------------------
#d_sum Sort list of files by criteria of date or name
#d_desc Return a sorted list of files - just the filename without the path
#d_arg mode The sort mode: date or name
#d_arg filelist List of files, must be full path name of the files

  if { [llength $filelist] < 1 } { return {} }
  switch $mode \
  date {
    foreach f $filelist {
       if {[file exists $f]} {
           lappend fileselect(DATA_FILE_MTIMES) [file mtime $f]}
    }
    set sorted_list [lsort -decreasing -command compare_date $filelist ]
    foreach f $sorted_list { lappend out_list [file tail $f] }
    return $out_list
  } name {
   	foreach f $filelist { lappend out_list [file tail $f] }
	return [lsort $out_list]
  } drive { 
    foreach f $filelist { lappend out_list $f }
    return [lsort $out_list]
  }
}

#---------------------------------------------------------------
proc compare_date { a b } {
#---------------------------------------------------------------
#d_sum The sorting procedure for the Tcl lsort command sorting by date

  if { [fileselectFileMtime $a] > [fileselectFileMtime $b] } {
    return 1
  } else {
    return -1
  }
}

#---------------------------------------------------------------
proc display_file_list { w mode file_list } {
#---------------------------------------------------------------
#d_sum Put list of files into display listbox
#d_arg w Listbox widget id
#d_arg mode List mode: name or details
#d_arg file_list List of files

  global fileselect
  switch $mode \
  name {
    foreach f $file_list { $w insert end $f }
  } details {
    foreach f $file_list { 
      set ff [FileJoin $fileselect(DIR) $f]
      set d [GetDate -format brief -clock [file mtime $ff]]
      set s [file size $ff]
      if {[file writable $ff]} { set ww w } else { set ww - }
      if {[file readable $ff]} { set r r } else { set r - }
      if {[file executable $ff]} { set x x } else { set x - }
      $w insert end [format %s%s%s%12i%s%s $r $ww $x $s " $d " $f]
    }
  }
}


#----------------------------------------------------------
proc fileselectIsDirectory { filename } {
#----------------------------------------------------------
#d_sum Check if file is a directory by looking it up in the cache
#d_arg filename Name of the file being checked

  global fileselect
  if { [lsearch -exact $fileselect(DATA_DIR_FILES) $filename] > -1 } {
    return 1
  } else {
    return 0
  }
}

#----------------------------------------------------------
proc fileselectFileMtime { filename } {
#----------------------------------------------------------
#d_sum Get the mtime attribute of a file
#d_desc This function wraps file mtime and caches the value that it \
gets for each file, so that subsequent queries do not need to go \
via calls to the file system.
#d_arg filename Name of the file being examined

  global fileselect
  if { [set k [lsearch $fileselect(DATA_MTIME_CACHE) $filename]] < 0 } {
    if {[file exists $filename]} {
      set mtime [file mtime $filename]
      lappend fileselect(DATA_MTIME_CACHE) $filename
      lappend fileselect(DATA_MTIMES) $mtime
    } else {
      set mtime 0
    }
  } else {
    set mtime [lindex $fileselect(DATA_MTIMES) $k]
  }
  return $mtime
}
