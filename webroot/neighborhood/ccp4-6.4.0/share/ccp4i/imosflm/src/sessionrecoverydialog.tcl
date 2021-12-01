# $Id: sessionrecoverydialog.tcl,v 1.8 2010/01/21 16:02:25 rmk65 Exp $
package provide sessionrecoverydialog 1.0

class SessionRecoveryDialog {
    inherit Dialog

    # member variables

    private variable session_file_list

    # methods

    public method confirm

    private method refresh
    private method updateButtons

    public method recover
    public method delete
    public method deleteAll
    public method cancel

    constructor { args } { }
}

body SessionRecoveryDialog::constructor { args } {
    
    wm title $itk_component(hull) "Recover session..."

    set warning "R0lGODlhIAAgAKEAAAAAAP//AJmZmf///yH+FUNyZWF0ZWQgd2l0aCBUaGUg\nR0lNUAAh+QQBCgADACwAAAAAIAAgAAACjpyPB5vtb0CYAFonJxW3j6wBAuc9\noBaIZJmc4ci26KzGyozWtovrrLvIwX60xcnXARqFqwvPCBw6e0tmEpeqWi28\nbJAmxWC9XaRs/O2FEd1QO7WOjClv82dOx5vf+K28n4YmxUemN0RYaMiBmNUH\nt+gYuTHCKKkCKal4CMXZ6bkwEooQSlpqehqHqopqUAAAOw=="
    image create photo warning -data $warning
    
    itk_component add messageframe {
	frame $itk_interior.mf \
	    -relief raised \
	    -borderwidth 1
    }
    
    itk_component add icon {
	label $itk_interior.mf.icon \
	    -image warning \
	    -anchor center
    } {
	keep -background
    }
    
    itk_component add message {
	label $itk_interior.mf.message \
	    -anchor w \
	    -justify left \
	    -text "The following unsaved sessions can be recovered:"
    } {
	keep -background
    }
    
    itk_component add list {
	tablelist::tablelist $itk_interior.mf.tl \
	    -background white \
		-activestyle underline\
	    -highlightthickness 0 \
	    -width 0 \
	    -height 5 \
	    -selectborderwidth 0 \
	    -exportselection 0 \
	    -columns {
		14 "Session"
		10 "Size"
		17 "Last modified"}
    } {
	keep -labelfont
	rename -font -entryfont entryFont Font
	keep -selectforeground -selectbackground
    }
    $itk_component(list) columnconfigure 1 -align right -labelalign left
    bind $itk_component(list) <<ListboxSelect>> [code $this updateButtons]
    
    itk_component add buttonframe {
	frame $itk_interior.bf \
	    -relief raised \
	    -borderwidth 1
    }
    
    itk_component add recover {
	button $itk_interior.bf.recover \
	    -text "Recover" \
	    -command [code $this recover] \
	    -highlightthickness 1 \
	    -width 7 \
	    -pady 2
    } {
	keep -background
	rename -activebackground -background background Background
	rename -highlightbackground -background background Background
    }
    
    itk_component add delete {
	button $itk_interior.bf.delete \
	    -text "Delete" \
	    -command [code $this delete] \
	    -highlightthickness 1 \
	    -width 7 \
	    -pady 2
    } {
	keep -background
	rename -activebackground -background background Background
	rename -highlightbackground -background background Background
    }
    
    itk_component add deleteAll {
	button $itk_interior.bf.no \
	    -text "Delete All" \
	    -command [code $this deleteAll] \
	    -highlightthickness 1 \
	    -width 7 \
	    -pady 2
    } {
	keep -background
	rename -activebackground -background background Background
	rename -highlightbackground -background background Background
    }
    

    itk_component add cancel {
	button $itk_interior.bf.cancel \
	    -text "Ignore" \
	    -command [code $this dismiss 0] \
	    -highlightthickness 1 \
	    -width 7 \
	    -pady 2
    } {
	keep -background
	rename -activebackground -background background Background
	rename -highlightbackground -background background Background
    }
    
    set margin 14

    pack $itk_component(messageframe) -side top -fill both -expand 1
    pack $itk_component(buttonframe) -side top -fill x

    grid x $itk_component(icon) x $itk_component(message) x -sticky w -pady $margin
    grid x $itk_component(list) - - x -sticky nswe
    
    grid columnconfigure $itk_component(messageframe) { 0 2 4 } -minsize $margin
    grid columnconfigure $itk_component(messageframe) 3 -weight 1
    grid rowconfigure $itk_component(messageframe) 2 -minsize $margin
    grid rowconfigure $itk_component(messageframe) 3 -weight 1


    grid x $itk_component(recover) x $itk_component(delete) x $itk_component(deleteAll) x $itk_component(cancel) x \
	-pady $margin

    grid columnconfigure $itk_component(buttonframe) { 0 8 } -minsize $margin
    grid columnconfigure $itk_component(buttonframe) { 2 4 6 } -weight 1

    eval itk_initialize $args
}

# ##################################################################### #
# Confirm                                                               #
# ##################################################################### #

body SessionRecoveryDialog::confirm { } {
    wm title $itk_component(hull) "Recover session..."
    refresh
    Dialog::confirm
}

# ##################################################################### #
# Refresh                                                               #
# ##################################################################### #

body SessionRecoveryDialog::refresh { } {

    # Store any existing selection
    set l_selection [$itk_component(list) curselection]

    # Clear the current list
    $itk_component(list) delete 0 end

    # get a list of recoverable sessions
    set session_file_list [glob -nocomplain -directory $::mosflm_directory -- *.mpr]

    if {[llength $session_file_list] == 0} {
	## if there are no recoverable sessions disable recover/delete buttons
	#$itk_component(recover) configure -state "disabled"
	#$itk_component(delete) configure -state "disabled"
	# Cancel the dialog box, as there's nothing else that can be done
	cancel
    } else {
	# sort the list according to date
	set session_file_list [lsort -command sortFilesByDate $session_file_list]
	# add the files to the tablelist display 
	foreach i_session_file $session_file_list {
	    set l_name [file tail $i_session_file]
	    set l_size "[expr int([file size $i_session_file]/1024)]k"
	    set l_date "[clock format [file mtime $i_session_file] -format "%d/%m/%y %H:%M:%S"]"
	    $itk_component(list) insert end [list $l_name $l_size $l_date]
	}
	# Update the selection
	if {$l_selection != ""} {
	    if {$l_selection > ([llength $session_file_list] -1)} {
		set l_selection end
	    }
	    $itk_component(list) selection set $l_selection $l_selection
	} else {
	   $itk_component(list) selection set 0 0
	} 
	# Update the buttons
	updateButtons
    }
}

# ##################################################################### #
# updateButtons                                                         #
# ##################################################################### #

body SessionRecoveryDialog::updateButtons { } {
    if {[$itk_component(list) curselection] != ""} {
	$itk_component(recover) configure -state "normal"
	$itk_component(delete) configure -state "normal"
    } else {
	$itk_component(recover) configure -state "disabled"
	$itk_component(delete) configure -state "disabled"
    }
}

# ##################################################################### #
# Recover                                                               #
# ##################################################################### #

body SessionRecoveryDialog::recover { } {
    set l_index [$itk_component(list) curselection]
    set l_file [lindex $session_file_list $l_index]
    dismiss $l_file
}

# ##################################################################### #
# Delete                                                                #
# ##################################################################### #

body SessionRecoveryDialog::delete { } {
    set l_index [$itk_component(list) curselection]
    set l_file [lindex $session_file_list $l_index]
    file delete $l_file
    refresh
}

# ##################################################################### #
# DeleteAll                                                             #
# ##################################################################### #

body SessionRecoveryDialog::deleteAll { } {
    foreach i_file $session_file_list {
	file delete $i_file
    }
    cancel
}

# ##################################################################### #
# Cancel                                                                #
# ##################################################################### #

body SessionRecoveryDialog::cancel { } {
    dismiss
}


# ##################################################################### #
# Sorting procedure                                                     #
# ##################################################################### #

proc sortFilesByDate { file1 file2 } {
    set date1 [file mtime $file1]
    set date2 [file mtime $file2]
    if {$date1 > $date2} {
	return 1
    } elseif {$date1 < $date2} {
	return -1
    } else {
	return 0
    }
}

