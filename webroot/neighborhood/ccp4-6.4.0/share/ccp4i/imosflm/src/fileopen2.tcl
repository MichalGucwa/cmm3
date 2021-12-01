# $Id: fileopen2.tcl,v 1.12 2012/05/21 13:23:39 ccb Exp $
package provide fileopen 2.0

class Fileopen {
    inherit itk::Toplevel

    itk_option define -type type Type "open" {
	updateType
    }
    itk_option define -initialfile initialFile InitialFile "" {}
    itk_option define -initialdir initialDir InitialDir "$::env(HOME)" {}
    itk_option define -defaultextension defaultExtension DefaultExtension "" {}
    itk_option define -filtertypes filterTypes FilterTypes {{"All Files" {.*}}} {
	updateFilterTypes
    }
    itk_option define -title title Title "Open" {
	wm title $itk_component(hull) $itk_option(-title)
    }

    private variable singleimage 
    private variable response ""

    private variable filters ; # N.B. array - do not initialize
    private variable filter_descriptions {}
    private variable filter ""
    private variable current_directory ""
    private variable current_drive "C:/"
    private variable previous_drive ""
    private variable top_level 0
    private variable filename ""
    private variable files_by_item ; # N.B. array - do not initialize
    private variable last_selected "0"
    private variable last_range 0
    private variable select_list ""

    private method updateType
    private method updateFilterTypes

    public method get

    public method centre

    public method loadDir

    public method cancel
    public method select
    public method upDir
    public method homeDir

    public method Click
    public method shiftClick
    public method controlClick
    public method doubleClick
    public method keyReturn
    public method selectAll

    public method getFilenamesSelected
    public method updateSelection

    public method fillDirCombo
    public method updateFilter

    private method sortFiles
    private method sortFiles2

    private method setMinsize
	
    public method getSingleImage
    private method setSingleImage

    constructor { args } { }
}

body Fileopen::constructor { args } {
    
    wm withdraw $itk_component(hull)
    wm iconbitmap $itk_component(hull) [wm iconbitmap .]
    wm iconmask $itk_component(hull) [wm iconmask .]
    wm protocol $itk_component(hull) \
	WM_DELETE_WINDOW [code $this cancel]
    
    itk_component add dir_label {
	label $itk_interior.dirlabel \
	    -text "Look in: "
    } {
	usual 
    }
    
    itk_component add dir_combo {
	Combo $itk_interior.dircombo \
	    -textvariable [scope current_directory] \
	    -items { } \
	    -editable 1 \
	    -command [code $this loadDir]
    }
    
    #itk_component add buttonframe {
    #   frame $itk_interior.bf ;#-borderwidth 0
    #}
    
    itk_component add updir {
	button $itk_interior.updir \
	    -image ::img::updir \
	    -highlightthickness 1 \
	    -command [code $this upDir]
    }
    
    itk_component add home {
	button $itk_interior.home \
	    -image ::img::homedir \
	    -highlightthickness 1 \
	    -command [code $this homeDir]
    }

    #This checkbox was for a single image. Now re-purposed for selecting individual images (bug 69)
    itk_component add single_image_check {
    checkbutton $itk_interior.check \
	    -text "Selected images only" \
	    -variable [scope singleimage]
    }

    itk_component add file_frame {
 	frame $itk_interior.f
    }
    itk_component add file_tree {
	treectrl $itk_interior.f.filetree \
	    -height 180 \
	    -width  360 \
	    -highlightthickness 0 \
	    -showroot no \
	    -showbuttons no \
	    -showlines no \
	    -itemheight 18 \
	    -selectmode single \
	    -showheader no \
	    -xscrolldelay "500 50" \
	    -yscrolldelay "500 50"
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    }

    $itk_component(file_tree) column create -widthhack yes
    
    $itk_component(file_tree) element create e_icon image -image ::img::file16x16
    $itk_component(file_tree) element create e_text text -fill { white {selected} black {}} -lines 1
    $itk_component(file_tree) element create e_rect rect -fill {\#3399ff {selected focus} gray {selected !focus}} -showfocus yes

    $itk_component(file_tree) style create s1
    $itk_component(file_tree) style elements s1 {e_rect e_icon e_text}
    $itk_component(file_tree) style layout s1 e_icon -expand ns
    $itk_component(file_tree) style layout s1 e_text -squeeze x -expand ns -padx {2 0}
    $itk_component(file_tree) style layout s1 e_rect -union [list e_text] -iexpand ns -ipadx 2

    bind $itk_component(file_tree) <ButtonPress-1> [code $this Click %W %x %y]
    bind $itk_component(file_tree) <Shift-ButtonPress-1> [code $this shiftClick %W %x %y]
    bind $itk_component(file_tree) <Control-ButtonPress-1> [code $this controlClick %W %x %y]
    bind $itk_component(file_tree) <Double-ButtonPress-1> [code $this doubleClick %W %x %y]
    bind $itk_component(file_tree) <Return> [code $this keyReturn]
    $itk_component(file_tree) notify bind $itk_component(file_tree) <Selection> [code $this updateSelection %S]

    if {[tk windowingsystem] == "aqua"} {
	bind $itk_component(hull) <Command-a> [code $this selectAll]
    } else {
	bind $itk_component(hull) <Control-a> [code $this selectAll]
    }

    itk_component add scroll {
	scrollbar $itk_interior.f.scroll \
	    -command [code $this component file_tree yview] \
	    -orient vertical \
	    -takefocus 0
    }
    
    $itk_component(file_tree) configure \
	-yscrollcommand [list autoscroll $itk_component(scroll)]

    itk_component add filename_label {
	label $itk_interior.filenamelabel -text "File name: "
    }
    
    itk_component add filename_entry {
	gEntry $itk_interior.filenameentry \
	    -textvariable [scope filename]
    }
    
    itk_component add filter_label {
	label $itk_interior.filterlabel -text "File type: "
    }
    
    itk_component add filter_combo {
	Combo $itk_interior.filenamecombo \
	    -textvariable [scope filter] \
	    -editable 0 \
	    -command [code $this updateFilter]
    }
    
    itk_component add button {
	button $itk_interior.button -width 7 -pady 2 \
	    -highlightthickness 1 \
	    -command [code $this select]
    }
    
    itk_component add cancel {
	button $itk_interior.cancel \
	    -text Cancel -width 7 -pady 2 \
	    -highlightthickness 1 \
	    -command [code $this cancel]
    }

    set margin 7

    grid $itk_component(dir_label) -row 0 -column 0 -sticky w -padx [list $margin 0] -pady [list $margin 0]
    grid $itk_component(dir_combo) -row 0 -column 1 -sticky we -pady [list $margin 0]
    grid $itk_component(updir) -row 0 -column 2 -padx [list $margin 0] -pady [list $margin 0]
    grid $itk_component(home) -row 0 -column 3 -padx [list 0 $margin] -pady [list $margin 0]
    grid $itk_component(file_frame) -row 1 -column 0 -columnspan 4 -sticky nswe -padx [list $margin [expr $margin + 1]] -pady $margin
    grid columnconfigure $itk_component(file_frame) 0 -weight 1 -minsize 270 
    grid rowconfigure $itk_component(file_frame) 0 -weight 1 -minsize 180 
    grid $itk_component(file_tree) -column 0 -row 0 -stick nsew
    grid $itk_component(scroll) -column 1 -row 0 -sticky ns
    grid $itk_component(filename_label) -row 2 -column 0 -sticky w -padx [list $margin 0]
    grid $itk_component(filename_entry) -row 2 -column 1 -sticky we
    grid $itk_component(button) -row 2 -column 2 -columnspan 2 -sticky nsew  -padx $margin
    grid $itk_component(filter_label) -row 3 -column 0 -sticky w -padx [list $margin 0] -pady [list 0 $margin]
    grid $itk_component(filter_combo) -row 3 -column 1 -sticky we -pady [list 0 $margin]
    grid $itk_component(cancel) -row 3 -column 2 -columnspan 2 -sticky nsew  -padx $margin -pady [list 0 $margin]
    grid $itk_component(single_image_check) -row 4 -column 0 -columnspan 2 -sticky w -padx [list $margin 0]
    grid columnconfigure $itk_component(hull) 1 -weight 1
    grid rowconfigure $itk_component(hull) 1 -weight 1

    eval itk_initialize $args
	# we don't want the single image check button to appear in save dialog boxes
	# so remove it from the layout
	if {$itk_option(-type) != "image_open"} {
		grid remove $itk_component(single_image_check)
	}

    bind $itk_component(hull) <Map> [code $this setMinsize]

}

body Fileopen::getSingleImage { } {
	return $singleimage
}

body Fileopen::setSingleImage {a_bool} {
	set singleimage $a_bool
}


body Fileopen::setMinsize { } {
    bind $itk_component(hull) <Map> {}
    # following line only needed on MS-Windows, does no harm for other systems.
    update idletasks
    wm minsize $itk_component(hull) [winfo reqwidth $itk_component(hull)] [winfo reqheight $itk_component(hull)]
}

body Fileopen::loadDir { a_dir } {
    # unbind file tree double click, to disable it during reloading
    bind $itk_component(file_tree) <Double-ButtonPress-1> {}
    # Show busy cursor
    $itk_component(file_tree) configure -cursor watch
    #update
    set t0 [clock clicks -milliseconds]
    if {![file isdirectory $a_dir]} {
	# ignore!
    } else {
	# hrp 28.02.2007
	# the windows stuff here works but isn't quite right - if you're at the
	# top of the directory structure  you need to double click the "up" button. 
	# update the record of the current directory for Windows only
	if {$::tcl_platform(os) == "Windows NT" && $a_dir == "."} {
	    set current_directory ""
	    set current_drive ""
	    set top_level 1
	} else {
	    set current_directory $a_dir
	}
	# get a list of files in the directory
	set l_file_list [glob -nocomplain -directory $current_directory *]
	#puts "glob file list: $l_file_list"
	# initialize list of files to show
	set l_files_to_show {}
	# first test for Windows and drives -
	set previous_drive $current_drive
	set current_drive ""
	if { $::tcl_platform(os) == "Windows NT" } {
	    if { $top_level == 0 } {
		set current_drive [lindex [file split $current_directory] 0]
	    }
	    if { $previous_drive == $current_directory } {
		set top_level 1
		set current_directory ""
	    } else {
		set top_level 0
	    }
	    # if this is the top level, re-write the list of files as 
	    # the list of drives
	    if { $top_level == 1 } {
		set l_file_list ""
		foreach i_file [file volume] {
		    if { [file exists $i_file] } {
			lappend l_file_list $i_file
		    }
		}
		set l_files_to_show $l_file_list
	    }
	}
	# loop through directory listing... 
	if { $top_level == 0 } {
	    foreach i_file $l_file_list {
		if {[file isdirectory $i_file]} {
		    # keep directories
		    lappend l_files_to_show $i_file
		} else {
		    # keep non-directories which match the filter
		    if {[regexp $filters($filter) $i_file]} {
			lappend l_files_to_show $i_file
		    }
		}
	    }
	}
	# sort the files
	set t1 [clock clicks -milliseconds]
	set l_files_to_show [lsort -command [code $this sortFiles2] $l_files_to_show]
	set t2 [clock clicks -milliseconds]
	# clear the file tree
	$itk_component(file_tree) item delete all
	# clear array of shown files
	array unset files_by_item *
	# loop through the files to show
	foreach i_file $l_files_to_show {
	    # create an item
	    set t_item [$itk_component(file_tree) item create]
	    $itk_component(file_tree) item style set $t_item 0 s1
	    if {[file isdirectory $i_file]} {
		$itk_component(file_tree) item element configure $t_item 0 e_icon -image ::img::directory_closed16x16
	    } else {
		$itk_component(file_tree) item element configure $t_item 0 e_icon -image ::img::file16x16
	    }
	    # toplevel is only ever not 0 for Windows
	    if { $top_level == 0 } {
		$itk_component(file_tree) item text $t_item 0 [file tail $i_file]
	    } else {
		$itk_component(file_tree) item text $t_item 0 $i_file
	    }

	    $itk_component(file_tree) item lastchild root $t_item
	    # store the full filename in an array indexed by item
	    set files_by_item($t_item) $i_file
	}
	$itk_component(file_tree) yview moveto 0
	# Activate the first item in the new tree
	if {[$itk_component(file_tree) item firstchild root] != ""} {
	    $itk_component(file_tree) activate [$itk_component(file_tree) item firstchild root]
	}
	# update the directory combo
	fillDirCombo
	set t3 [clock clicks -milliseconds]
    }
    # rebind file tree double click
    bind $itk_component(file_tree) <Double-ButtonPress-1> [code $this doubleClick %W %x %y]
    # Show normal cursor
    $itk_component(file_tree) configure -cursor left_ptr
} 

body Fileopen::fillDirCombo { } {
    set l_dir_list {}
    set t_dir $current_directory
    while {$t_dir != [file dirname $t_dir]} {
	set t_dir [file dirname $t_dir ]
	lappend l_dir_list $t_dir
    }
    $itk_component(dir_combo) configure -items $l_dir_list
}

body Fileopen::updateFilter { a_filter } {
    set filter $a_filter
    loadDir $current_directory
}

body Fileopen::upDir { } {
    #puts "Updir to: [file dirname $current_directory]"
    loadDir [file dirname $current_directory]
}

body Fileopen::homeDir { } {
    loadDir $::env(HOME)
}

body Fileopen::shiftClick { w x y } {
    set id [$w identify $x $y]
    if {[lindex $id 0] eq "item"} {
	set curr_selected [lindex $id 1]
	# ignore double click on unselected item, as it must really be a single click(!)
	if {![file isdirectory $files_by_item($curr_selected)]} {
    # select range from last selected
    #	    puts "Last selection: $last_selected"
    #	    puts "This selection: $curr_selected"
	    set range [expr $curr_selected - $last_selected]
    #    puts "Range: $range Last range: $last_range"
    #	    puts "Range: $range"
	    if {$range > 0} {
		for { set i [expr $last_selected+1] } { $i <= $curr_selected } { incr i } {
		    if {[$itk_component(file_tree) item state get $i selected]} {
			$itk_component(file_tree) selection clear $i
			set posn [lsearch -exact $select_list $i]
			set select_list [lreplace $select_list $posn $posn]
		    } else {
			$itk_component(file_tree) selection add $i
			lappend select_list $i
		    }
		}
	    }
	    if {$range < 0} {
		for { set i [expr $last_selected-1] } { $i > $curr_selected } { incr i -1 } {
		    if {[$itk_component(file_tree) item state get $i selected]} {
			$itk_component(file_tree) selection clear $i
			set posn [lsearch -exact $select_list $i]
			set select_list [lreplace $select_list $posn $posn]
		    } else {
			$itk_component(file_tree) selection add $i
			lappend select_list $i
		    }
		}
	    }
	    set last_range $range
	    # ensure current selected remains selected
	    if {![$itk_component(file_tree) item state get $curr_selected selected]} {
		$itk_component(file_tree) selection add $curr_selected
		lappend select_list $curr_selected
	    }
	    set filename "[getFilenamesSelected $select_list]"
	    set last_selected $curr_selected
	    #puts $select_list
	}
    }
}

body Fileopen::Click { w x y } {
    set id [$w identify $x $y]
    if {[lindex $id 0] eq "item"} {
	set curr_selected [lindex $id 1]
	if {![file isdirectory $files_by_item($curr_selected)]} {
	    if {![$itk_component(file_tree) item state get $curr_selected selected]} {
		# just select the image
		$itk_component(file_tree) selection add $curr_selected
	    }
	    if {[llength $select_list] > 0} {
		set select_list ""
	    }
	    lappend select_list $curr_selected
	    set filename "[getFilenamesSelected $select_list]"
	    set last_selected $curr_selected
	    set last_range 0
	    # puts $select_list
	}
    }
}

body Fileopen::controlClick { w x y } {
    set id [$w identify $x $y]
    if {[lindex $id 0] eq "item"} {
	set curr_selected [lindex $id 1]
	if {![file isdirectory $files_by_item($curr_selected)]} {
	    if {![$itk_component(file_tree) item state get $curr_selected selected]} {
		# just select the image
		$itk_component(file_tree) selection add $curr_selected
		if {[lsearch -exact $select_list $curr_selected] < 0} {
		    lappend select_list $curr_selected
		}
	    } else {
		$itk_component(file_tree) selection clear $curr_selected
		set posn [lsearch -exact $select_list $curr_selected]
		set select_list [lreplace $select_list $posn $posn]
	    }
	    set filename "[getFilenamesSelected $select_list]"
	    set last_selected $curr_selected
	    set last_range 0
	    #puts $select_list
	}
    }
}

body Fileopen::doubleClick { w x y } {
    set id [$w identify $x $y]
    if {[lindex $id 0] eq "item"} {
	# ignore double click on unselected item, as it must really be a single click(!)
	if {[$itk_component(file_tree) item state get [lindex $id 1] selected]} {
	    if {[file isdirectory $files_by_item([lindex $id 1])]} {
		loadDir $files_by_item([lindex $id 1])
	    } else {
		set filename [file tail $files_by_item([lindex $id 1])]
		$itk_component(button) invoke
	    } 
	} else {
	    # just select the image
	    $itk_component(file_tree) selection modify [lindex $id 1] all
	}
    }
}

body Fileopen::getFilenamesSelected { list } {
    # Given list of selected items by number, return sorted list of file names
    set listoffiles {}
    if { [llength $list] > 0 } {
	set listofitems [lsort -integer $list]
	foreach i $listofitems {
	    lappend listoffiles [file tail $files_by_item($i)]
	}
    } else {
    }
    return $listoffiles
}

body Fileopen::keyReturn { } {
    set l_active [$itk_component(file_tree) index active]
    set filename [getFilenamesSelected $select_list]
    #puts "keyReturn: $filename"
    if {$l_active != ""} {
	if {[$itk_component(file_tree) item state get $l_active selected]} {
	    $itk_component(button) invoke
	}
    }
}

body Fileopen::selectAll { } {
    set i 0
    set select_list {}
    focus $itk_component(file_tree)
    foreach item [array names files_by_item] {
	$itk_component(file_tree) selection add $item
	lappend select_list $item
    }
    set filename [getFilenamesSelected $select_list]
}

body Fileopen::updateSelection { s } {
    if {$s != ""} {
	if {![file isdirectory $files_by_item($s)]} {
	    # set filename [file tail $files_by_item($s)]
	}
    }
}

body Fileopen::cancel { } {
    set response ""
}

body Fileopen::get { args } {
    eval configure $args
    bind $itk_component(hull) <Configure> [code $this centre]
    set filename [file tail $itk_option(-initialfile)]
    loadDir $itk_option(-initialdir)
    wm deiconify $itk_interior
    grabber set $itk_component(hull)
    tkwait variable [scope response]
    grabber release $itk_component(hull)
    wm withdraw $itk_component(hull)
    set itk_option(-initialfile) ""
    set itk_option(-initialdir) "$current_directory"
    #puts "$this response: $response"
    return $response
}

body Fileopen::centre { } {
    # Calculate the desired geometry
    set width [winfo reqwidth $itk_component(hull)]
    set height [winfo reqheight $itk_component(hull)]
    # following binds to centre of screen - bloody annoying if you have a big screen
    #    set x [expr { ( [winfo vrootwidth  $itk_component(hull)] - $width  ) / 2 }]
    #    set y [expr { ( [winfo vrootheight $itk_component(hull)] - $height ) / 2 }]
    # this binds the popup to the top left of the main imosflm window - close to where the
    # button is pushed. 
    set x [ expr [winfo rootx .] + 120 ]
    set y [ expr [winfo rooty .] + 84 ]
    # Hand the geometry off to the window manager
    wm geometry $itk_component(hull) ${width}x${height}+${x}+${y}
    # Unbind <Configure> so that this procedure is
    # not called again when the window manager finishes
    # centering the window - 
    #	update
    bind $itk_component(hull) <Configure> {}
    raise $itk_component(hull)
    return
}

body Fileopen::select { } {
    #    $filename = short form filename
    #    $current_directory = cwd, includes current volume on Windows
    #    [file volume] gives the list of drives available - only really 
    #                  useful on windows
    #puts "$this filename $filename"
    if {$filename == ""} {
	# hrp 26.02.2007
	# ignore except if this is Windows, when it could be the drive name
	# $::tcl_platform(os) = "Windows NT" for this test
    } else {
	set l_full_name [file join $current_directory $filename]
	if {[file isdirectory $l_full_name]} {
	    loadDir $l_full_name
	} else {
	    #puts "$this fullname $l_full_name"
	    # Test for only blanks in filename field
	    set file_tail [file tail $l_full_name]
	    #puts "$this file_tail $file_tail"
	    if {[regexp {^ +$} $file_tail]} {
		.m configure \
		    -type "1button" \
		    -button1of1 "Ok" \
		    -title "Blank filename given" \
		    -text "Please check your filename"
		.m confirm
		return
	    }

	    # On Windows glob -nocomplain returns the name inside braces
	    set globbit [glob -nocomplain $l_full_name]
	    #puts "$this glob -nocomplain fullname $globbit"
	    # Trim off the braces (they do not occur on Linux)
	    set globtrim [string trim $globbit \{\}]
	    #puts "$this glob  trimmed    fullname $globtrim"

	    if {$itk_option(-type) == "save"} {
		if {$globtrim  == $l_full_name} {
		    YesNo .yn
		    if {[.yn query -title "Save As" -text "$l_full_name already exists.\nDo you want to replace it?"]} {
			set response $l_full_name
		    }
		    delete object .yn
		} else {
		    set response $l_full_name
		}
	    } elseif {$itk_option(-type) == "open"} {
		if { $globtrim != $l_full_name} {
		    .m configure \
			-type "1button" \
			-button1of1 "Ok" \
			-title "Open" \
			-text "$l_full_name does not exist.\nPlease check your filename"
		    .m confirm
		} else {
		    set response $l_full_name
		}
	    } else {
		set response $l_full_name
	    }
	}
    }
}

body Fileopen::updateType { } {
    if {$itk_option(-type) == "open" || $itk_option(-type) == "image_open" } {
	#wm title $itk_component(hull) "Open"
	$itk_component(dir_label) configure -text "Directory: "
	#$itk_component(filter_label) configure -text "Files of type: "
	$itk_component(button) configure -text "Open"
    } elseif { $itk_option(-type) == "mtz_open"} {
	$itk_component(dir_label) configure -text "Look in: "
	#$itk_component(filter_label) configure -text "Files of type: "
	$itk_component(button) configure -text "Run"
	#grid $itk_component(pointless_only_check) -row 5 -column 0 -sticky w	
    } else {
	#wm title $itk_component(hull) "Save As"
	$itk_component(dir_label) configure -text "Save in: "
	#$itk_component(filter_label) configure -text "Save as type: "
	$itk_component(button) configure -text "Save"
    }
}	

body Fileopen::updateFilterTypes { } {
    # Clear filters array
    array unset filters *
    # Clear filter description list (used to preserve order)
    set filter_descriptions {}
    # Loop through filter types
    foreach i_filter $itk_option(-filtertypes) {
	# Extract name and extension list
	foreach {t_name t_extensions} $i_filter break
	# Begin description and regexp construction
	set t_description "$t_name ("
	set t_regexp "^.*\.("
	# Loop through extension list
	foreach i_ext $t_extensions {
	    # incrementally construct description
	    append t_description "*$i_ext,"
	    # incrementally construct regexp
	    append t_regexp "[string map {* [^\.]*} $i_ext]|"
	}
	# finish constructing description
	set t_description "[string range $t_description 0 end-1])"
	# finish constructing regexp
	set t_regexp "[string range $t_regexp 0 end-1])$"
	# Store regexp in filter array indexed by description
	set filters($t_description) $t_regexp
	# store descriptions in list (used to preserve order)
	lappend filter_descriptions $t_description
    }
    # Put filter descriptions into filter combo's list
    $itk_component(filter_combo) configure -items $filter_descriptions
    # Put first filter description into filter combo's entry
    set filter [lindex $filter_descriptions 0]
    # Refresh the currently displayed directory to re-filter it
    loadDir $current_directory
}

body Fileopen::sortFiles { a b } {
    set l_file_a $files_by_item($a)
    set l_file_b $files_by_item($b)
    return [sort_dirs $l_file_a $l_file_b]
}

body Fileopen::sortFiles2 { a b } {
    if {([file isdirectory $a]) && (![file isdirectory $b])} {
	return -1
    } elseif {(![file isdirectory $a]) && ([file isdirectory $b])} {
	return 1
    } elseif {$a < $b} {
	return -1
    } elseif {$b < $a} {
	return 1
    } else {
	return 0
    }
}

image create photo ::img::warning -data "R0lGODlhIAAgAKEAAAAAAP//AJmZmf///yH+FUNyZWF0ZWQgd2l0aCBUaGUg\nR0lNUAAh+QQBCgADACwAAAAAIAAgAAACjpyPB5vtb0CYAFonJxW3j6wBAuc9\noBaIZJmc4ci26KzGyozWtovrrLvIwX60xcnXARqFqwvPCBw6e0tmEpeqWi28\nbJAmxWC9XaRs/O2FEd1QO7WOjClv82dOx5vf+K28n4YmxUemN0RYaMiBmNUH\nt+gYuTHCKKkCKal4CMXZ6bkwEooQSlpqehqHqopqUAAAOw=="

class YesNo {
    inherit itk::Toplevel

    itk_option define -image image Image ::img::warning {
	$itk_component(icon) configure -image $itk_option(-image)
    }
 
    itk_option define -title title Title "" {
	wm title $itk_component(hull) $itk_option(-title)
    }
 
    private variable response

    private method yes
    private method no
    private method queryInternal
    public method query

    constructor { args } { }
}

body YesNo::constructor { args } {	
    
    wm withdraw $itk_component(hull)
    wm iconbitmap $itk_component(hull) [wm iconbitmap .]
    wm iconmask $itk_component(hull) [wm iconmask .]
    wm protocol $itk_component(hull) \
	WM_DELETE_WINDOW [code $this no]
    wm resizable $itk_component(hull) 0 0
           
    itk_component add message_frame {
	frame $itk_interior.mf
    }
    
    itk_component add icon {
	label $itk_interior.mf.icon
    }
    
    itk_component add message {
	label $itk_interior.mf.message \
	    -anchor w \
	    -justify left
    } {
	usual
	keep -text
    }
    
    itk_component add yes {
	button $itk_interior.yes \
	    -text "Yes" \
	    -command [code $this yes] \
	    -highlightthickness 1 \
	    -width 7 \
	    -pady 2
    }

    itk_component add no {
	button $itk_interior.no \
	    -text "No" \
	    -command [code $this no] \
	    -highlightthickness 1 \
	    -width 7 \
	    -pady 2
    }
    
    set margin 7
    grid $itk_component(message_frame) - -pady $margin -sticky nsew
    pack $itk_component(icon) -side left -anchor c -padx $margin
    pack $itk_component(message) -side right -fill both -expand 1 -padx $margin
    grid $itk_component(yes) $itk_component(no) -pady $margin
    grid $itk_component(yes) -sticky e -padx [list $margin [expr $margin / 2]]
    grid $itk_component(no) -sticky w -padx [list [expr $margin / 2] $margin]

    eval itk_initialize $args
}

body YesNo::yes { } {
    set response 1
}

body YesNo::no { } {
    set response 0
}

body YesNo::query  { args } {
    eval configure $args
    bind $itk_component(hull) <Map> [code $this queryInternal]
    wm deiconify $itk_component(hull)
    tkwait variable [scope response]
    grabber release $itk_component(hull)
    wm withdraw $itk_component(hull)
    return $response
}

body YesNo::queryInternal { } {
    bind $itk_component(hull) <Map> {}
    grabber set $itk_component(hull)
}
