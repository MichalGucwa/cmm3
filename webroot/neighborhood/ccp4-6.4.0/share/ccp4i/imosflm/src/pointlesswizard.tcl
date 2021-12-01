# $Id: pointlesswizard.tcl,v 1.5 2012/05/21 13:23:39 ccb Exp $
package provide pointlesswizard 1.0


#Pointlesswizard class is a base class for constructing a Pointless Panel.
#However I did not manage to finish it. I leave it here for the next person
#to pick up
class Pointlesswizard {
    inherit itk::Widget

    private variable sample_dataset_x
    private variable sample_dataset_y
    private variable sample_data
    
    public method launch {}
    public method hide {}
    public method printDataset
    public method plot
    public method readXMLFile
    public method clickLink

    constructor { args } {}
    
}


body Pointlesswizard::constructor { args } {
	
#   set processing_stage "integration"
    itk_component add heading_f {
	frame $itk_interior.hf \
	    -bd 1 \
	    -relief solid 
    }

    itk_component add heading_l {
	label $itk_interior.hf.fl \
	    -text "Check Symmetry" \
	    -font title_font \
	    -anchor w
    } {
	usual
	ignore -font
    }

    itk_component add chart_frame {
	    frame $itk_interior.chartf 
    }

    itk_component add plot_c {
	canvas $itk_interior.chartf.plotc \
	    -background white \
	    -relief sunken \
	    -borderwidth 2 \
	    -highlightthickness 0
    }

    itk_component add text_frame {
	    frame $itk_interior.textf
    }
	
    itk_component add text {
	text $itk_interior.textf.text \
	    -bg white\
	    -fg black \
	    -selectborderwidth 0 
#	    -state disabled 
    } {
	usual
	ignore -background -foreground
	ignore -selectbackground -selectforeground -selectborderwidth
	ignore -highlightthickness
	rename -font entryfont entryFont Font
    }


    pack $itk_component(heading_f) -side top -fill x -padx 7 -pady {7 0}
    pack $itk_component(heading_l) -side left -padx 5 -pady 5 -fill both -expand 1
    pack $itk_component(chart_frame) -side top -expand 1 -fill both
    pack $itk_component(plot_c) -side top -fill both -expand 1 -padx 7 -pady 7
    pack $itk_component(text_frame) -side top -expand 1 -fill both
    pack $itk_component(text) -side top -padx 5 -pady 5 -expand 1 -fill both
#	grid $itk_component(chart_frame) -row 1 -column 1 -sticky news -pady 7
#	grid $itk_component(plot_c) -sticky news

    $itk_component(text) tag bind hyperlink <Button-1> [code $this clickLink %x %y]
#    itk_component add auto_update_mtz_tb {
#	SettingToolbutton $itk_component(toolbar).aumtb "auto_update_mtz" \
#	    -image ::img::auto_update_mtz16x16 \
#	    -activeimage ::img::auto_update_mtz_on16x16 \
#	    -balloonhelp "Auto-generate MTZ file name"
#   }

#   pack $itk_component(auto_update_mtz_tb) \
# 	-side left \
#	-padx 2

#    eval itk_initialize $args

}

body Pointlesswizard::launch { } {

    set sample_data [list 1 2 3 4 5 6 7 8 9]
    set sample_data_y [list 10 11 12 13 14 15 16 17 18]
    set sample_dataset_x [namespace current]::[Dataset \#auto  $sample_data [Unit::getUnit "mm"] "sd" "sample_data"]
    set sample_dataset_y [namespace current]::[Dataset \#auto  $sample_data_y [Unit::getUnit "mm"] "sd" "sample_data"]

    # Show stage
    grid $itk_component(hull) -row 0 -column 1 -sticky nswe

    printDataset $sample_dataset_x
    printDataset $sample_dataset_y
    set l_canvas_width [winfo width $itk_component(plot_c)]
    if {$l_canvas_width < 30} {
	set l_canvas_width [winfo reqwidth $itk_component(plot_c)]
    }
    set l_canvas_height [winfo height $itk_component(plot_c)]
    if {$l_canvas_height < 30} {
	set l_canvas_height [winfo reqheight $itk_component(plot_c)]
    }
    set window [list 10 10 [expr $l_canvas_width - 10] [expr $l_canvas_height - 10]]
    # Create graph
    ScatterGraph \#auto $itk_component(plot_c) $window "id" $sample_dataset_y $sample_dataset_y
    plot $window  $sample_dataset_x $sample_dataset_y

    # display associated toolbar
    # TO DO...

}

body Pointlesswizard::hide { } {
    grid forget $itk_component(hull)
}


body Pointlesswizard::printDataset {a_dataset} {
    puts $a_dataset
    puts [$a_dataset getData]
    puts [$a_dataset getUnit]
    puts [$a_dataset getShortName]
    puts [$a_dataset getLongName]
}

body Pointlesswizard::plot {a_window a_x_dataset a_y_dataset} {
    ScatterGraph \#auto $itk_component(plot_c) $a_window "id" $a_x_dataset $a_y_dataset
}

body Pointlesswizard::readXMLFile {a_filepath} {
    puts "READING XML"
    set fp [open "$a_filepath" r]
    set data [read $fp]
    close $fp
    $itk_component(text) insert end $data
}

body Pointlesswizard::clickLink {xpos ypos} {
    exec [regsub -all \" $::env(CCP4_BROWSER) "" ] "www.google.com" &	
}


usual Pointlesswizard { }

#The PointlessMonitor class contains all the methods that control Pointless
#when running in parallel to an integration run
class PointlessMonitor {
    private variable integration_run_number
    private variable mtz_filename_list {}
    private variable mtz_filename_root ""
    private variable pointless_running 0
    private variable browser_already_open "0"
    public method printIntegrationRun
    public method setupPointless
    public method initialise
    public method genInputList
    public method genInputString
    public method parseFilenameRoot
    public method parseFilenameExt
    public method readLine
    public method runPointless

    constructor { args } {}

}

body PointlessMonitor::constructor { args } {
#	puts "Constructing PointlessMonitor"
}

body PointlessMonitor::printIntegrationRun { } {
#	puts "Integration run [$::session getIntegrationRun]"
}

body PointlessMonitor::setupPointless { } {
    if {$pointless_running == 1} {
	#puts "Called runPointless and $pointless_running"
	return
    #}

    set current_mtz_dir [$::session getMTZDirectory]
    set current_mtz_file [$::session getMTZFilename]
    set integration_number [$::session getIntegrationRun]
    set pointless_number [expr $integration_number - 1 ]

    set mtz_filename_root [file rootname $current_mtz_file]
    set mtz_filename_ext [file extension $current_mtz_file]
    if {$mtz_filename_ext == ""} {
	set mtz_filename_ext ".mtz"
    }

    set pointlessinputfile [open pointless_inline.inp w]
    puts $pointlessinputfile "ASSUMESAMEINDEXING"
    puts $pointlessinputfile [genInputString $mtz_filename_root $mtz_filename_ext $pointless_number ]
    close $pointlessinputfile

    #set pointlessinput [genInputList $mtz_filename_root [$::session getIntegrationRun] ] 
    set baubleshtml [ file join $current_mtz_dir "pointless_inline.html" ]
    if { $integration_number > 1} {
	set pointless_running 1
#	set pointlesslog pointless_${integration_number}.log
	set pointlesslog "pointless_inline.log"
	set pointlesslogfileID [open $pointlesslog w]
#	set pointlesscmd "pointless HKLIN $pointlessinput  HKLOUT pointless_${integration_number}.mtz XMLOUT pointless_${integration_number}.xml"
#	set pointlesscmd "pointless HKLOUT pointless_${mtz_filename_root}_1to${pointless_number}.mtz XMLOUT pointless_${integration_number}.xml"
	set pointlesscmd "$::env(CBIN)/pointless HKLOUT pointless_${mtz_filename_root}_1to${pointless_number}.mtz "

	set f [open "| $pointlesscmd < pointless_inline.inp" r]
#	puts $f
	fconfigure $f -buffering line
	fileevent $f "readable" [code $this runPointless $f $pointlesslog $baubleshtml $pointlesslogfileID] 
#	fileevent $f readable [code $this readLine $f $pointlesslogfileID]
    }
}


body PointlessMonitor::readLine {a_pointer a_logfile} {
    if {[gets $a_pointer line] >= 0} {
#	puts "I am here"
	puts $a_logfile $line
    } else {
	if {[catch {close $a_pointer} eid]} {
	    #puts $eid
	}
	close $a_logfile
#	puts "pointless has finished"
    }
}	 


body PointlessMonitor::runPointless { a_pipe a_logfile a_baubles_htmlfile a_logfile_ptr} {

	if {[gets $a_pipe line] >= 0} {
		puts $a_logfile_ptr $line
	} else {
	    if {[catch {close $a_pipe} eid]} {
#		puts $eid
	    }
	    #close $pointlesslogfileID

#	puts "pointless has finished"
	    close $a_logfile_ptr
#	puts $pointless_running
	    set pointless_running 0
#	puts $pointless_running
#	puts $pointless_running
        if { [regexp -nocase windows $::tcl_platform(os)] } {
            set baubles_windows_path [file join $::env(CCP4) share smartie baubles.py]
#	set WEB_BROWSER $::env(CCP4_BROWSER)
        } 

	if { [regexp -nocase windows $::tcl_platform(os)] } {
	    set b [open "| python $baubles_windows_path $a_logfile" r] 
	} else {
	    set b [open "| [eval file join $::env(CCP4) etc baubles] $a_logfile" r]
	} 
	set std_out [read -nonewline $b]
	if {[eof $b]} {
	    catch {close $b} std_err
	    set baubleshmtlfileID [open $a_baubles_htmlfile w]
	    puts $baubleshmtlfileID $std_out
	    close $baubleshmtlfileID
	}

	# Set the path to the baubles python script
	set baubles_htmlfile [file join [pwd] $a_baubles_htmlfile]
	# only update the browser if this is the first time in this session we've done this.
	# The html will still be produced, but the browser will not refresh the page.
	if { $browser_already_open == "0" } {
	    # Added special case for windows as it seems to not work with open_url
	    if { [regexp -nocase windows $::tcl_platform(os)] } {
		exec [regsub -all \" $::env(CCP4_BROWSER) "" ] $a_baubles_htmlfile &
	    } else {
		open_url $a_baubles_htmlfile
	    }
	    set browser_already_open "1"
	}
	[.c component activity_l] idle
    }

}

body PointlessMonitor::initialise { } {
	set mtz_filename_list {}
}

body PointlessMonitor::parseFilenameRoot { a_filename } {
}

body PointlessMonitor::parseFilenameExt { a_filename } {
}

body PointlessMonitor::genInputList { a_file_root integr_run_num } {
    set mtz_filename_list {}
    for {set i 1} {$i <= $integr_run_num} {incr i} {
	if {[string length $i] == 1} {
	    lappend mtz_filename_list "HKLIN ${a_file_root}_00${i}.mtz \n"
	} elseif {[string length $i] == 2} {
	    lappend mtz_filename_list "HKLIN ${a_file_root}_0${i}.mtz \n"
	} else {
	    lappend mtz_filename_list "HKLIN ${a_file_root}_0${i}.mtz \N"
	}
    #puts $integr_run_num
    }
    return $mtz_filename_list
}


body PointlessMonitor::genInputString { a_file_root a_file_ext integr_run_num } {
    set mtz_filename_string ""
    for {set i 1} {$i <= $integr_run_num} {incr i} {
	if {[string length $i] == 1} {
	    append mtz_filename_string "HKLIN [file join [$::session getMTZDirectory] ${a_file_root}_00${i}${a_file_ext}] \n"
	} elseif {[string length $i] == 2} {
	    append mtz_filename_string "HKLIN [file join [$::session getMTZDirectory] ${a_file_root}_0${i}${a_file_ext}] \n"
	} else {
	    append mtz_filename_string "HKLIN [file join [$::session getMTZDirectory] ${a_file_root}_0${i}${a_file_ext}] \n"
	}
#	puts $integr_run_num
    }
    return $mtz_filename_string
}

