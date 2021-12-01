# $Id: batch.tcl,v 1.8 2010/01/21 16:02:24 rmk65 Exp $
package provide batch 1.0

#package require Expect

class BatchSubmissionDialog {
    inherit Amodaldialog

    private variable destinations {}

    public method launch
    public method ok
    private method process
    private method processExpect

    public method configureDestinations
    public method updateDestinations

    constructor { args } { }
}

body BatchSubmissionDialog::constructor { args } {

#     wm title $itk_component(hull) "Batch submission - Mosflm"
#     wm iconbitmap $itk_component(hull) @$::env(MOSFLM_GUI)/images/mosflm_inverse.xbm
#     #wm iconmask $itk_component(hull) @$::env(MOSFLM_GUI)/images/mosflm.xbm

    itk_component add script_f {
	frame $itk_interior.sf
    }

    itk_component add script_l {
	label $itk_interior.sf.sl \
	    -text "Script:" \
	    -anchor w
    }


    itk_component add script_t {
	text $itk_interior.sf.st
    } {
	usual
	rename -background -textbackground textBackground Background
    }

    itk_component add script_sb {
	scrollbar $itk_interior.sf.sb \
	    -orient vertical \
	    -command [list $itk_component(script_t) yview]
    }

    $itk_component(script_t) configure \
	-yscrollcommand [list autoscroll $itk_component(script_sb)]

    itk_component add destination_l {
	label $itk_interior.dl \
	    -text "Send to: " \
	    -anchor w
    }

    itk_component add destination_c {
	combobox::combobox $itk_interior.dc \
	    -editable 0 \
	    -width 24 \
	    -listvar [scope destinations]
    } {
	keep -background -cursor -foreground -font
	keep -selectbackground -selectborderwidth -selectforeground
	keep -highlightcolor -highlightthickness
	rename -highlightbackground -background background Background
	rename -background -textbackground textBackground Background
    }

    itk_component add config_b {
	button $itk_interior.cb \
	    -text "Configure..." \
	    -command [code $this configureDestinations]
    }

    
    itk_component add button_f {
	frame $itk_interior.bf
    }

    itk_component add ok {
	button $itk_interior.bf.ok \
	    -text "Ok" \
	    -width 7 \
	    -pady 2 \
	    -command [code $this ok]
    }
	    
    itk_component add cancel {
	button $itk_interior.bf.cancel \
	    -text "Cancel" \
	    -width 7 \
	    -pady 2 \
	    -command [code $this hide]
    }

    grid $itk_component(script_f) - - -sticky we -padx 7 -pady 7
    grid $itk_component(destination_l) $itk_component(destination_c) $itk_component(config_b) -padx {7 7} -sticky w
    grid $itk_component(button_f) - - - -sticky we
    grid columnconfigure $itk_interior 1 -weight 1
    grid rowconfigure $itk_interior 99 -weight 1

    # Script frame
    grid $itk_component(script_l) - -sticky we 
    grid $itk_component(script_t) $itk_component(script_sb) -sticky nswe
    grid columnconfigure $itk_component(script_f) 0 -weight 1

    # Button frame
    grid rowconfigure $itk_interior 1 -weight 1
    grid columnconfigure $itk_interior 3 -weight 1
    pack $itk_component(ok) $itk_component(cancel) -side right -padx {0 7} -pady [list 14 7]

    # Build destinations list
    #updateDestinations

    eval itk_initialize $args
}

body BatchSubmissionDialog::launch { a_script } {
    # Load script
    $itk_component(script_t) delete 0.0 end
    $itk_component(script_t) insert 0.0 $a_script
    # Select first target if none selected
    if {[$itk_component(destination_c) get] == ""} {
	$itk_component(destination_c) select 0
    }
    # show the dialog
    show
}

body BatchSubmissionDialog::ok { } {
    # Hide the dialog
    hide
    # Process the batch job
    process
}

body BatchSubmissionDialog::process { } {
    set l_destination [BatchDestination::getDestinationByName [$itk_component(destination_c) get]]
    $l_destination execute [$itk_component(script_t) get 0.0 end]
}

body BatchSubmissionDialog::processExpect { } {
    exp_spawn -noecho ssh $host "/home/geoff/mosflm/bin/mosflm < [file join $::mosflm_directory batch.scr]"
    expect "password"
    exp_send "$password\r"
    expect -timeout -1 eof
}

body BatchSubmissionDialog::configureDestinations { } {
    .bcd show
}

body BatchSubmissionDialog::updateDestinations { } {
    set destinations {}
    foreach i_destination [BatchDestination::getDestinations] {
	lappend destinations [$i_destination getName]
    }
    if {([$itk_component(destination_c) get] == "") ||
	([lsearch $destinations [$itk_component(destination_c) get]] < 0)} {
	$itk_component(destination_c) select 0
    }
}


#############################################################################

# Batch destination configuration

class BatchConfigDialog {
    inherit Amodaldialog

    private variable destinations_by_item ; # array
    private variable items_by_destination ; # array
    private variable current_destination ""

    private variable executable ""
    private variable host ""
    private variable username ""
    private variable command ""
    private variable protocols {}

    # methods

    private method addDestination
    private method deleteDestination
    private method newRemoteDestination
    private method newFarmDestination
    private method sortDestinations
    private method renameDestination
    private method updateSelection
    private method queueUpdateSelection

    private method updateExecutable
    private method updateHost
    private method updateUsername
    private method updateProtocol
    private method updateCommand

    public  method initialize

    constructor { args } { }

}

body BatchConfigDialog::constructor { args } {

    itk_component add destination_frame {
	frame $itk_interior.df
    }

    itk_component add destination_tree {
	treectrl $itk_interior.df.dt \
	    -showroot 0 \
	    -showrootlines 0 \
	    -showheader 0 \
	    -selectmode single \
	    -width 300 \
	    -height 100
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    }

    # Set up selection binding
    $itk_component(destination_tree) notify bind $itk_component(destination_tree) <Selection> [code $this queueUpdateSelection %S %D]
    # Set up delete binding
    bind $itk_component(destination_tree) <KeyPress-Delete> [code $this deleteDestination]

    #$itk_component(destination_tree) notify bind $itk_component(destination_tree) <Key-Delete> [code $this keyPressDelete %c]

    $itk_component(destination_tree) column create -text Destination -tag destination -justify left -expand 1 ;# -itembackground {"\#ffffff" "\#e8e8e8"} 

    $itk_component(destination_tree) element create e_icon image -image ::img::raw_solution
    $itk_component(destination_tree) element create e_text text -fill {white selected}
    $itk_component(destination_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
	
    $itk_component(destination_tree) style create s1
    $itk_component(destination_tree) style elements s1 { e_highlight e_icon e_text }
    $itk_component(destination_tree) style layout s1 e_icon -expand ns -padx {0 6} -pady {1 1}
    $itk_component(destination_tree) style layout s1 e_text -expand ns
    $itk_component(destination_tree) style layout s1 e_highlight -union [list e_text] -iexpand nse -ipadx 2
    
#     $itk_component(destination_tree) style create s2
#     $itk_component(destination_tree) style elements s2 {e_highlight e_text}
#     $itk_component(destination_tree) style layout s2 e_text -expand ns
#     $itk_component(destination_tree) style layout s2 e_highlight -union [list e_text] -iexpand nsew -ipadx 2
        
    #bind $itk_component(destination_tree) <Double-ButtonPress-1> [code $this doubleClickDestination %W %x %y]

    # Set up tags to support treectrl's "file list" bindings
    bindtags $itk_component(destination_tree) [list $itk_component(destination_tree) TreeCtrlFileList TreeCtrl [winfo toplevel $itk_component(destination_tree)] all]
    
    # Instal item editing events
    $itk_component(destination_tree) notify install <Edit-begin>
    $itk_component(destination_tree) notify install <Edit-end>
    $itk_component(destination_tree) notify install <Edit-accept>

    # List of lists: {column style element ...} specifying text elements
    # the user can edit
    TreeCtrl::SetEditable $itk_component(destination_tree) {
	{destination s1 e_text}
    }
    
    # List of lists: {column style element ...} specifying elements
    # the user can click on or select with the selection rectangle
    TreeCtrl::SetSensitive $itk_component(destination_tree) {
	{destination s1 e_icon e_text e_highlight}
    }
    
    # List of lists: {column style element ...} specifying elements
    # added to the drag image when dragging selected items
    TreeCtrl::SetDragImage $itk_component(destination_tree) {
	{destination s1 e_icon e_text}
    }
    
    # During editing, hide the text and (NOT!) selection-rectangle elements
    $itk_component(destination_tree) notify bind $itk_component(destination_tree) <Edit-begin> {
	%T item element configure %I %C e_text -draw no;# + e_highlight -draw no
    }

    # On completion of editing, call rename method
    $itk_component(destination_tree) notify bind $itk_component(destination_tree) <Edit-accept> [code $this renameDestination %I %t]


    # After editing, show the text and (STILL) selection-rectangle elements
    $itk_component(destination_tree) notify bind $itk_component(destination_tree) <Edit-end> {
	%T item element configure %I %C e_text -draw yes;# + e_highlight -draw yes
    }
    
    itk_component add destination_scroll {
	scrollbar $itk_interior.df.ds \
	    -command [code $this component destination_tree yview] \
	    -orient vertical
    }
    
    $itk_component(destination_tree) configure \
	-yscrollcommand [list autoscroll $itk_component(destination_scroll)]


#     itk_component add list {
# 	tablelist::tablelist $itk_interior.l \
# 	    -background white \
# 	    -highlightthickness 0 \
# 	    -width 0 \
# 	    -height 5 \
# 	    -showlabels 0 \
# 	    -selectborderwidth 0 \
# 	    -exportselection 0 \
# 	    -stretch 0 \
# 	    -sortcommand [code $this sortDestinations] \
# 	    -editendcommand [code $this renameDestination] \
# 	    -columns {
# 		50 "Destination"
# 	    }
#     } {
# 	keep -labelfont
# 	rename -font -entryfont entryFont Font
# 	keep -selectforeground -selectbackground
#     }
#     $itk_component(list) columnconfigure 0 -align left
#     bind $itk_component(list) <<ListboxSelect>> [code $this updateSelection]

    itk_component add button_f {
	frame $itk_interior.bf
    }


    itk_component add new_remote_b {
	button $itk_interior.bf.nrb \
	    -image ::img::new_remote16x16 \
	    -command [code $this newRemoteDestination]
    }

    itk_component add new_farm_b {
	button $itk_interior.bf.nfb \
	    -image ::img::new_farm16x16 \
	    -command [code $this newFarmDestination]
    }

    itk_component add destination_l {
	label $itk_interior.dl \
	    -text "Destination: " \
	    -anchor w
    }

    itk_component add icon_l {
	label $itk_interior.icon \
	    -anchor w
    }

    itk_component add name_l {
	label $itk_interior.name \
	    -text "" \
	    -anchor w
    }

    itk_component add executable_l {
	label $itk_interior.el \
	    -text "Executable: " \
	    -anchor w
    }

    itk_component add executable_e {
	gEntry $itk_interior.ee \
	    -textvariable [scope executable] \
	    -command [code $this updateExecutable]
    }

    itk_component add host_l {
	label $itk_interior.hl \
	    -text "Host: " \
	    -anchor w
    }

    itk_component add host_e {
	gEntry $itk_interior.he \
	    -textvariable [scope host] \
	    -command [code $this updateHost]
    }

    itk_component add username_l {
	label $itk_interior.ul \
	    -text "Username: " \
	    -anchor w
    }

    itk_component add username_e {
	gEntry $itk_interior.ue \
	    -textvariable [scope username] \
	    -command [code $this updateUsername]
    }

    itk_component add protocol_l {
	label $itk_interior.pl \
	    -text "Protocol: " \
	    -anchor w
    }

    itk_component add protocol_cb {
	combobox::combobox $itk_interior.pc \
	    -editable 0 \
	    -command [code $this updateProtocol] \
	    -listvar [scope protocols]
    } {
	keep -background -cursor -foreground -font
	keep -selectbackground -selectborderwidth -selectforeground
	keep -highlightcolor -highlightthickness
	rename -highlightbackground -background background Background
	rename -background -textbackground textBackground Background
    }
    set protocols [BatchRemote::getProtocols]

    itk_component add command_l {
	label $itk_interior.cl \
	    -text "Command: " \
	    -anchor w
    }

    itk_component add command_e {
	gEntry $itk_interior.ce \
	    -textvariable [scope command] \
	    -command [code $this updateCommand]
    }
    
    grid x $itk_component(destination_frame) - - $itk_component(button_f) -sticky nwe -pady {7 0}
    grid $itk_component(destination_tree) $itk_component(destination_scroll) -sticky nswe
    grid columnconfigure $itk_component(destination_frame) 0 -weight 1
    pack $itk_component(new_remote_b) $itk_component(new_farm_b) -padx 2 -pady {0 2}
    grid x $itk_component(destination_l) $itk_component(icon_l) $itk_component(name_l) -sticky we -pady {7 0}
    grid x $itk_component(executable_l) $itk_component(executable_e) - -sticky we -pady {7 0}
    grid x $itk_component(host_l) $itk_component(host_e) - -sticky we -pady {7 0}
    grid x $itk_component(username_l) $itk_component(username_e) - -sticky we -pady {7 0}
    grid x $itk_component(protocol_l) $itk_component(protocol_cb) - -sticky we -pady {7 0}
    grid x $itk_component(command_l) $itk_component(command_e) - -sticky we -pady {7 0}

    grid columnconfigure $itk_interior 0 -minsize 7
    grid columnconfigure $itk_interior 5 -minsize 7
    grid columnconfigure $itk_interior 3 -weight 1
    grid rowconfigure $itk_interior 99 -minsize 7 -weight 1

    eval itk_initialize $args
}

body BatchConfigDialog::addDestination { a_destination { a_edit 1 } } {

    # create new item 
    set l_item [$itk_component(destination_tree) item create]
    $itk_component(destination_tree) item style set $l_item 0 s1
    $itk_component(destination_tree) item text $l_item 0 [$a_destination getName]
    $itk_component(destination_tree) item element configure $l_item 0 e_icon -image [$a_destination getIcon]
    $itk_component(destination_tree) item lastchild root $l_item
    set destinations_by_item($l_item) $a_destination
    set items_by_destination($a_destination) $l_item

    # select new item
    $itk_component(destination_tree) selection modify $l_item all

    # sort tablist
    $itk_component(destination_tree) item sort root -command [code $this sortDestinations]

    # update batch submission dialog
    .bsd updateDestinations

    if { $a_edit } {
	# begin editing of destination name
	::TreeCtrl::FileListEdit $itk_component(destination_tree) $l_item destination e_text
    }
}

body BatchConfigDialog::deleteDestination { } {
    foreach i_item [$itk_component(destination_tree) selection get] {
	$itk_component(destination_tree) item delete $i_item
	delete object $destinations_by_item($i_item)
	array unset items_by_destination $destinations_by_item($i_item)
	array unset destinations_by_item $i_item
    }
    .bsd updateDestinations
    BatchDestination::saveProfile
}

body BatchConfigDialog::renameDestination { a_item a_name } {
    # Get the destination object
    set l_destination $destinations_by_item($a_item)
    # Try and rename it
    if {[$l_destination rename $a_name]} {
	# if succesful update tree label and destination label
	$itk_component(destination_tree) item text $a_item destination $a_name
	$itk_component(name_l) configure -text " $a_name"
	# update batch submission dialog
	.bsd updateDestinations
    } else {
	# renaming failed (due to clash with existing name)...
	# (Do nothing)
    }
}   

body BatchConfigDialog::sortDestinations { a_item b_item } {
    # foreach item...
    foreach i {a b} {
	# get the coresponding destination
	set ${i}_destination $destinations_by_item([set ${i}_item])
	# get it's class
	set ${i}_class [[set ${i}_destination] info class]
	# work out the order based on class
	if {[set ${i}_class] == "::BatchLocal"} {
	    set ${i}_class_order "a"
	} elseif {[set ${i}_class] == "::BatchRemote"} {
	    set ${i}_class_order "b"
	} else {
	    set ${i}_class_order "c"
	}
    }
    # compare by class order
    set l_comparison [string compare $a_class_order $b_class_order]
    # if the same..
    if {$l_comparison == 0} {
	# compare by name
	set l_comparison [string compare [$a_destination getName] [$b_destination getName]]
    }
    return $l_comparison
}

body BatchConfigDialog::newRemoteDestination { } {
    # generate an unsed name
    set l_used_names [BatchDestination::getDestinationNames]
    set i_count 1
    while {1} {
	if {[lsearch $l_used_names "Remote$i_count"] < 0} {
	    set l_name "Remote$i_count"
	    break
	}
	incr i_count
    }
    # Create destination
    set l_destination [BatchRemote \#auto $l_name]
    addDestination $l_destination
}

body BatchConfigDialog::newFarmDestination { } {
    # generate an unsed name
    set l_used_names [BatchDestination::getDestinationNames]
    set i_count 1
    while {1} {
	if {[lsearch $l_used_names "Farm$i_count"] < 0} {
	    set l_name "Farm$i_count"
	    break
	}
	incr i_count
    }
    # Create destination
    set l_destination [BatchFarm \#auto $l_name]
    addDestination $l_destination
}

body BatchConfigDialog::queueUpdateSelection { a_selected a_deselected } {
    # NB updateSelection executed in event loop (using after) to
    # allow any <FocusOut> events for previous destination's parameters
    # to successful compelte for "current_destination" before it is changed.
    after 0 [code $this updateSelection  $a_selected $a_deselected]
}

body BatchConfigDialog::updateSelection { a_selected a_deselected} {
    if {$a_selected != ""} {
	# get the selected destination
	set current_destination $destinations_by_item($a_selected)
	# update universally applicable settings (name, icon, executable)
	$itk_component(name_l) configure -text " [$current_destination getName]"
	$itk_component(icon_l) configure -image  [$current_destination getIcon]
	set executable [$current_destination getExecutable]
	# update class-specific widgets and settings
	if {[$current_destination isa BatchLocal]} {
	    grid remove $itk_component(host_l)
	    grid remove $itk_component(host_e)
	    grid remove $itk_component(username_l)
	    grid remove $itk_component(username_e)
	    grid remove $itk_component(protocol_l)
	    grid remove $itk_component(protocol_cb)
	    grid remove $itk_component(command_l)
	    grid remove $itk_component(command_e)
	} elseif {[$current_destination isa BatchRemote]} {
	    grid $itk_component(host_l)
	    grid $itk_component(host_e)
	    grid $itk_component(username_l)
	    grid $itk_component(username_e)
	    grid $itk_component(protocol_l)
	    grid $itk_component(protocol_cb)
	    grid remove $itk_component(command_l)
	    grid remove $itk_component(command_e)

	    set host [$current_destination getHost]
	    set username [$current_destination getUsername]
	    $itk_component(protocol_cb) select [lsearch $protocols [$current_destination getProtocol]]
	} elseif {[$current_destination isa BatchFarm]} {
	    grid remove $itk_component(host_l)
	    grid remove $itk_component(host_e)
	    grid remove $itk_component(username_l)
	    grid remove $itk_component(username_e)
	    grid remove $itk_component(protocol_l)
	    grid remove $itk_component(protocol_cb)
	    grid $itk_component(command_l)
	    grid $itk_component(command_e)
	    set command [$current_destination getCommand]
	} else {
	    error "Unrecognized destination class"
	}
    } else {
	set current_destination ""
    }
}

body BatchConfigDialog::updateExecutable { an_executable } {
    $current_destination setExecutable $an_executable
}

body BatchConfigDialog::updateHost { a_host } {
    $current_destination setHost $a_host
}

body BatchConfigDialog::updateUsername { a_username } {
    $current_destination setUsername $a_username
}

body BatchConfigDialog::updateProtocol { w a_protocol } {
    $current_destination setProtocol [$itk_component(protocol_cb) get]
}

body BatchConfigDialog::updateCommand { a_command } {
    $current_destination setCommand $a_command
}

body BatchConfigDialog::initialize { } {
    set l_local_found 0
    # Load existing destinations (created from profile)
    foreach i_destination [BatchDestination::getDestinations] {
	addDestination $i_destination 0
	# Keep watch for a local destination
	if {[$i_destination info class] == "::BatchLocal"} {
	    set l_local_found 1
	}

    }
    # If there was no local destination, create one
    if {!$l_local_found} {
	if {[catch {set l_host_name $::env(HOSTNAME)}]} {
	    set l_host_name "localhost"
	}
	set l_destination [namespace current]::[BatchLocal \#auto "$l_host_name"]
	addDestination $l_destination 0
    }
    # update batch submission dialog
    .bsd updateDestinations
}

usual BatchConfigDialog { }

# Submission methods ################################

# Generic base class

class BatchDestination {

    # I forget get the collective name for these
    private common destinationsByName ; # array
    public proc getDestinations
    public proc getDestinationNames
    public proc getDestinationByName
    public proc saveProfile

    # variables
    protected variable name ""
    protected variable icon
    protected variable executable "ipmosflm"

    # methods
    public method getName { } { return $name } 
    public method rename
    public method getIcon { } { return $icon }
    public method getExecutable { } { return $executable }
    public method setExecutable { a_executable } {
	set executable $a_executable
        saveProfile
    }


    public method execute { args } { error "Virtual method called!" }
    protected method createScript { a_script } { }

    constructor { a_name } { }

    destructor {
	array unset destinationsByName $name
    }
}

# procs

body BatchDestination::getDestinations { } {
    set l_destinations {}
    foreach { i_name i_destination } [array get destinationsByName] {
	lappend l_destinations $i_destination
    }
    return $l_destinations
}

body BatchDestination::getDestinationNames { } {
    return [array names destinationsByName]
}

body BatchDestination::getDestinationByName { a_name } {
    if {[info exists destinationsByName($a_name)]} {
	return $destinationsByName($a_name)
    } else {
	return ""
    }
}

body BatchDestination::saveProfile { } {
    .c saveProfile
}

# methods

body BatchDestination::constructor { a_name } {
    set name $a_name
    set destinationsByName($name) $this
    saveProfile
}

body BatchDestination::rename { a_name } {
    set l_existing_destination [getDestinationByName $a_name]
    if {$l_existing_destination == ""} {
	array unset destinationsByName $name
	set name $a_name
	set destinationsByName($name) $this
	# success
	saveProfile
	return 1
    } else {
	# failure
	return 0
    }
}   

body BatchDestination::createScript { a_script } {
    # Generate and open timestamped file in .mosflm directory
    set l_timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
#    set l_filename [file join $::mosflm_directory "mosflm_batch_${l_timestamp}.bat"]
    set l_filename [file join [$::session getParameterValue mtz_directory] "mosflm_batch_${l_timestamp}.bat"]
    set l_file [open $l_filename w]

    # Generate a name for the log file
    set l_logfile [file join [$::session getParameterValue mtz_directory] "mosflm_batch_${l_timestamp}.log"]
    # Generate a name for the SUMMARY file
    set l_sumfile [file join [$::session getParameterValue mtz_directory] "mosflm_batch_${l_timestamp}.sum"]

	#Generate a name for the SPOTOD file
    set l_spotodfile [file join $::mosflm_directory "mosflm_batch_${l_timestamp}.spotod"]
	
	#Generate a name for the COORDS file
    set l_coordsfile [file join $::mosflm_directory "mosflm_batch_${l_timestamp}.coords"]

	

    # Write sh script to launch mosflm
    puts $l_file "#!/bin/sh"
    puts $l_file "$executable SUMMARY $l_sumfile SPOTOD $l_spotodfile COORDS $l_coordsfile <<EOF > $l_logfile"
	puts $l_file "GENFILE [file join [$::session getParameterValue mtz_directory] "mosflm_batch_${l_timestamp}.gen"]"
	puts $l_file "NEWMAT [file join [$::session getParameterValue mtz_directory] "mosflm_batch_${l_timestamp}.mat"]"
    foreach i_line [split $a_script \n] {
	puts $l_file $i_line
    }
    puts $l_file "EOF"
    puts $l_file "date >> $l_logfile"
    puts $l_file "echo \"Batch complete\" >> $l_logfile"
#	puts $l_file "rm $l_coordsfile"
    close $l_file

    # Make batch file executable
    exec chmod u+x $l_filename

    return $l_filename
}

# Remote batch destination class

class BatchRemote {
    inherit BatchDestination

    private common protocols [list "ssh" "rsh"]
    public proc getProtocols { } { return $protocols }

    private variable host ""
    private variable username ""
    private variable protocol "ssh"

    public method setHost { a_host } { set host $a_host ; saveProfile }
    public method setUsername { a_username } { set username $a_username ; saveProfile }
    public method setProtocol { a_protocol } { set protocol $a_protocol ; saveProfile }

    public method getHost { } { return  $host }
    public method getUsername { } { return $username }
    public method getProtocol { } { return $protocol }

    public method execute

    public method serialize

    constructor { a_name } {
	BatchDestination::constructor $a_name 
    } {
	set icon ::img::remote16x16
    }
}

body BatchRemote::execute { a_script } {
    set l_result [catch {exec $protocol -l ${username} ${host} [createScript a_script] &} l_error]
    if {$l_result} {
	.m confirm \
	    -type "1button" \
	    -button1of1 "Dismiss" \
	    -title "Error" \
	    -text "Could not run batch job on ${host}:\n\n$l_error\n\nSorry!"

    } else {
    }
}

body BatchRemote::serialize { } {
    set xml "<batch_destination type=\"remote\" name=\"$name\" executable=\"$executable\" host=\"$host\" username=\"$username\" protocol=\"$protocol\"/>"
}

# local batch destination class

class BatchLocal {
    inherit BatchDestination

    public method execute
    public method serialize

    constructor { a_name } {
	BatchDestination::constructor $a_name 
    } {
	set icon ::img::local16x16
	set executable $::mosflm_executable
    }
}

body BatchLocal::execute { a_script } {
    # Run batch script
    if {[catch {exec [createScript $a_script] &} l_error]} {
	.m confirm \
	    -type "1button" \
	    -button1of1 "Dismiss" \
	    -title "Error" \
	    -text "Could not run local batch job:\n\n$l_error\n\nSorry!"
    }
}

body BatchLocal::serialize { } {
    set xml "<batch_destination type=\"local\" name=\"$name\" executable=\"$executable\"/>"
}

class BatchFarm {
    inherit BatchDestination

    private variable command ""

    public method getCommand { } { return $command } 
    public method setCommand { a_command } { set command $a_command ; saveProfile }

    public method execute

    public method serialize

    constructor { a_name } {
	BatchDestination::constructor $a_name
    } {
	set icon ::img::farm16x16
    }
}

body BatchFarm::execute { a_script } {
    if {[catch {eval exec $command [createScript $a_script] &} l_error]} {
	.m confirm \
	    -type "1button" \
	    -button1of1 "Dismiss" \
	    -title "Error" \
	    -text "Could not submit batch job to farm:\n\n$l_error\n\nSorry!"
    }
}

body BatchFarm::serialize { } {
    set xml "<batch_destination type=\"farm\" name=\"$name\" executable=\"$executable\" command=\"$command\"/>"
}
