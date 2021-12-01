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
# mapslicer_print.tcl
#
# Windows and procedures for printing in MapSlicer
#---------------------------------------------------------------------

#--------------------------------------------------------------------
# Print section
#
# This prints the section to file
#--------------------------------------------------------------------
proc print_section { } {
#--------------------------------------------------------------------

    # Cannot print if no section is displayed
    if { ![section s1 exists] } {
	WarningMessage "No section to print"
	return
    }

    # Open another window
    set w .anysection
    if ![OpenWindow $w "Print Section" "Print" ] { return }

    # Make the frame and the cancel and apply buttons
    CreateFrame   $w print_section
    CreateButton  $w dismiss "Cancel" "unset print_section ; destroy $w"
    CreateButton  $w print   "Print"  "apply_print_section print_section"

    # Define the menus used for this window
    DefineMenu _mapslicer_device [list "file" ]
    DefineMenu _mapslicer_orient [list "portrait" "landscape" ]

    # Set the parameters to be edited
    DefineVariable print_section device _mapslicer_device [get_value PRINT_DEVICE]
    DefineVariable print_section orient _mapslicer_orient [get_value PRINT_ORIENT]
    DefineVariable print_section scale  _positivereal     [get_value PRINT_SCALE]
    DefineVariable print_section file   _ps_file          ""
    DefineVariable print_section dirs   _default_dirs     ""
    DefineVariable print_section prncmd _text             [get_value PRINT_CMD]

    # Draw the widgets in the window
    CreateLine line label "Print current section to" widget device
    CreateInputFileLine line "Name of postscript file" "PS file" \
	    file dirs -toggle_display device open [list "file"]
    CreateLine line label "Printer command:" widget prncmd -oblig \
	    toggle_display device open [list "printer"]
    CreateLine line label "Scale of printout is" widget scale \
	    label "mm per Angstrom, orientated in" widget orient label "mode"

    # Must always do this at the end
    CloseFrame
    return
}

#--------------------------------------------------------------------
# Apply printing command
#
# This utilises the canvas postscript options.
# Useful options: -pageheight <size>[c|i|m|p]
#                 -pagewidth  <size>[c|i|m|p]
#                 -rotate <boolean> default is portrait, otherwise
#                                   landscape
#                 -colormode <mode> mode is color,gray,mono
#--------------------------------------------------------------------
proc apply_print_section { printVar } {
#--------------------------------------------------------------------
    upvar #0 $printVar print

    # Sort out the options from the user
    set device $print(device)

    # Determine orientation
    set orient $print(orient)
    if {$orient=="portrait"} {
	set rotate 0
    } elseif {$orient=="landscape"} {
	set rotate 1
    } else {
	WarningMessage "Unrecognised orientation: \"$orient\""
	return
    }

    # Execute command to print the canvas to file
    if {$device=="file"} {
	set file $print(file)
	if {[string length $file]>0} {

	    # Build full filename and path
	    #puts stdout "File is $print(file)"
	    #puts stdout "Dirs is $print(dirs)"
	    set dirs $print(dirs)
	    set filename [GetFullFileName $file $dirs]
	    #puts stdout "Full filename is $filename"

	    # Are you overwriting an existing file?
	    if [file exists $filename] {
		set action [ ChooseOptionDialog   "File Exists" "File Exists" \
			"File exists: $filename \nThis file will be overwritten. Do you want to continue or abort the print?" \
			[list "Continue" "Cancel" ]  \
			-default 1 ]
		if {"$action"=="Cancel"} {
		    return
		}
	    }
	    # Do the printing
	    print_rerender $print(scale) $rotate $filename
	} else {
	    WarningMessage "Output postscript file not specified"
	    return
	}
	if {![file exists $filename]} {
	    WarningMessage "Error: output file $filename\ndoesn't appear to have been written"
	}
	# Print to printer using user-supplied command
	# FIXME this option is not implemented at the moment
    }

    return
}

#--------------------------------------------------------------------
# Save section
#
# This is a shortcut to printing the section to a postscript file
#--------------------------------------------------------------------
proc save_section { } {
#--------------------------------------------------------------------

    # Cannot save if no section is displayed
    if { ![section s1 exists] } {
	WarningMessage "No section to save"
	return
    }

    # Open another window
    set w .savesection
    if ![OpenWindow $w "Save Section" "Save" ] { return }

    # Make the frame and the cancel and apply buttons
    CreateFrame   $w save_section
    CreateButton  $w dismiss "Cancel" "unset save_section ; destroy $w"
    CreateButton  $w save    "Save to File"  "apply_save_section save_section"

    # Define the menus used for this window
    DefineMenu _mapslicer_orient [list "portrait" "landscape" ]

    # Set the parameters to be edited
    DefineVariable save_section orient _mapslicer_orient [get_value PRINT_ORIENT]
    DefineVariable save_section scale  _positivereal     [get_value PRINT_SCALE]
    DefineVariable save_section file   _ps_file          ""
    DefineVariable save_section dirs   _default_dirs     ""

    # Draw the widgets in the window
    CreateInputFileLine line "Name of postscript file" "PS file"  file dirs
    CreateLine line label "Scale of printout is" widget scale \
	    label "mm per Angstrom, orientated in" widget orient label "mode"

    # Must always do this at the end
    CloseFrame
    return
}

#--------------------------------------------------------------------
# Apply save command
#
#--------------------------------------------------------------------
proc apply_save_section { saveVar } {
#--------------------------------------------------------------------
    upvar #0 $saveVar save

    # Determine orientation
    set orient $save(orient)
    if {$orient=="portrait"} {
	set rotate 0
    } elseif {$orient=="landscape"} {
	set rotate 1
    } else {
	WarningMessage "Unrecognised orientation: \"$orient\""
	return
    }

    # Execute command to print the canvas to file
    set dirs $save(dirs)
    set file $save(file)
    set filename [GetFullFileName $file $dirs]

    # Check the file name
    if { [string trim $filename] == "" } {
	WarningMessage "Output postscript file not specified"
	return
    }

    # Are you overwriting an existing file?
    if [file exists $filename] {
	set action [ ChooseOptionDialog   "File Exists" "File Exists" \
		"File exists: $filename \nThis file will be overwritten. Do you want to continue or abort the print?" \
		[list "Continue" "Cancel" ]  \
		-default 1 ]
	if {"$action"=="Cancel"} {
	    return
	}
    }
    # Do the printing
    print_rerender $save(scale) $rotate $filename

    if {![file exists $filename]} {
	WarningMessage "Error: output file $filename\ndoesn't appear to have been written"
    }
    return
}

#--------------------------------------------------------------------
# Re-render section in a new window and print to specified file
#
# This utilises the canvas postscript options.
# Useful options: -pageheight <size>[c|i|m|p]
#                 -pagewidth  <size>[c|i|m|p]
#                 -rotate <boolean> default is portrait, otherwise
#                                   landscape
#                 -colormode <mode> mode is color,gray,mono
#--------------------------------------------------------------------
proc print_rerender { scale rotate filename } {
#--------------------------------------------------------------------
    # The idea here is to set up a second canvas in a toplevel window
    # and render the section again with the specified scaling set for
    # printing.
    # Then use the canvas postscript options to print

    # Create a new toplevel frame
    if { [info exists .printbox] } {
	puts "Printing window already exists"
	return
    }
    set printbox [toplevel .printbox]
    #wm withdraw $printbox
    set printcanvas [canvas $printbox.c]
    pack $printcanvas
    
    # Render the section in the new canvas
    set print_render_cmd [list "section" "s1" "render" $printcanvas "-scale"]
    lappend print_render_cmd "[set scale]m"
    puts "Print rendering command is: $print_render_cmd"
    eval $print_render_cmd
    update idletasks
    update

    # Build and execute the print command
    set printcmd [list $printcanvas "postscript" "-file" "$filename" \
	    "-rotate" "$rotate"]
    puts "Printing: $printcmd"
    catch [eval "$printcmd"]

    # Get rid of the top-level frame with the copy of the section
    destroy $printbox
    return
}
