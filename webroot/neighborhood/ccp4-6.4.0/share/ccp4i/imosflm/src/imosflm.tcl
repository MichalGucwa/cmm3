#!/bin/sh
# $Id: imosflm.tcl,v 1.14 2012/05/21 13:23:39 ccb Exp $
# Restart script in wish (DO NOT DELETE TRAILING BACKSLASH!) \
exec $MOSFLM_WISH "$0" ${1+"$@"} 

########################################################################
#The eight lines of code below query the auto_path variable and 
#select the path entries that contain the terms active or teapot
#(case insensitive). Each matching entry is stored in the temporary
#list auto_path_temp and once the foreach loop is complete 
#auto_path is set to auto_path_temp. This should fix the issue where
#natively installed libraries are conflicting with ActiveTcl libraries
#by including only ActiveTcl library paths in auto_path.
#if {$::tcl_platform(os) == "Linux"} {
#	set auto_path_temp {}
#	foreach i_entry $auto_path {
#		if {[regexp -nocase active|teapot $i_entry]} {
#			lappend auto_path_temp $i_entry
#		}
#	} 
#
#	set auto_path $auto_path_temp
#}
#######################################################################

# set e-mail address of current iMosflm developer and some housekeeping
# messages for pop-up windows - users should never change these values!
# 
#global ::MAINTAINER
set ::env(MAINTAINER) harry@mrc-lmb.cam.ac.uk
global ::MOSFLM_VERSION_REQUIRED
set ::env(MOSFLM_VERSION_REQUIRED) 7.0.9
global ::TKIMAGELOAD
set ::env(TKIMAGELOAD) 0
if {![info exists ::env(EXPERTDETECTORSETTINGS)]} {
    global ::EXPERTDETECTORSETTINGS
    set ::env(EXPERTDETECTORSETTINGS) 0
}
global ::SPIRAL
set ::env(SPIRAL) 0

# Setup debugging
set ::debugging 0
if {[info exists ::env(MOSFLM_DEBUG)]} {
    if {$::env(MOSFLM_DEBUG) == 1} {
	set ::debugging 1
    }
}

set TclTkver [info patchlevel]
if { $TclTkver == "8.4.13" } {
    puts "\nYour Tcl/Tk version has been determined to be $TclTkver"
    puts "Unfortunately in $TclTkver the time taken to display images"
    puts "is unacceptably long due to a faulty Img component which"
    puts "renders iMosflm unusable. Other Tcl/Tk versions from"
    puts "8.4.9 to 8.4.19 are not affected in this way."
    exit
} else {
    puts "Tcl platform is $tcl_platform(platform) $tcl_platform(machine) $tcl_platform(os) \
	$tcl_platform(osVersion)"
    puts "TclTk version from info patchlevel is [info patchlevel]"
}

if {[info exists ::env(CBIN)]} {
#	puts "CCP4 binary path is set"
} else {
#	puts "*********************************************************************"
#	puts "CCP4 binary path is not set"
#	puts "if you want to run pointless and baubles"
#	puts "please restart imosflm in a shell where you" 
#	puts "have sourced the ccp4-setup file"
#	puts "*********************************************************************"
}

if {[info exists ::env(CCP4_BROWSER)]} {
#	puts "CCP4 browser is set to $::env(CCP4_BROWSER)"
} else {
#	puts "CCP4 browser is undefined"
}

proc debug { a_message } {
    if {$::debugging} {
	puts "iMosflm: $a_message"
    }
}

# Hide window until everything is ready
wm withdraw .
# Try and load required tcl/tk package dependencies

# array storing version requirements
set package_version_req(Itcl) 3
set package_version_req(Itk) 3
set package_version_req(Iwidgets) 3
set package_version_req(img::png) 1.3
set package_version_req(img::gif) 1.3
set package_version_req(img::jpeg) 1.3
set package_version_req(treectrl) 2.1
set package_version_req(tdom) 0.8

# Include the [Incr tcl], [incr TK], and Iwidgets packages
set package_loading_result(Itcl) [catch {package require Itcl}]
set package_loading_result(Itk) [catch {package require Itk}]
set package_loading_result(Iwidgets) [catch {package require Iwidgets}]
#package require Img
namespace import itcl::*
namespace import itk::*

# Image handling packages
set package_loading_result(img::jpeg) [catch {package require img::jpeg 1.3}]
set package_loading_result(img::gif) [catch {package require img::gif 1.3}]
set package_loading_result(img::png) [catch {package require img::png 1.3}]

# treectrl
set package_loading_result(treectrl) [catch {package require treectrl 2.1}]

# xml parser
set package_loading_result(tdom) [catch {package require tdom 0.8}]

# Check for package loading success
set l_failures 0
foreach i_package [array names package_loading_result] {
    if {$package_loading_result($i_package) > 0} {
	incr l_failures
	append l_failed_packages "$i_package $package_version_req($i_package)\n"
    }
}

if {$l_failures > 0} {
    set pick_wish [tk_messageBox \
		      -type okcancel \
		      -message "Wish 8.4 could not load the following packages:\n\n$l_failed_packages\n\nPlease select the correct Wish installation to run iMosflm." \
		      -icon error
		 ]
    if {$pick_wish == "ok"} {
	set l_wish_executable [tk_getOpenFile \
				   -title "Select wish8.4 executable" \
				   -filetypes {{{All files} {*}}} \
				   -parent .
			      ]
	while {![file executable $l_wish_executable]} {
	    set try_again [tk_messageBox \
			       -type okcancel \
			       -message "\"$l_wish_executable\" is not a valid executable\n\nTry again?" \
			       -icon question \
			       -parent .
			  ]
	    if {$try_again == "cancel"} {
		exit
	    } else {
		set l_wish_executable [tk_getOpenFile \
					   -title "Select wish8.4 executable" \
					   -filetypes {{{All files} {*}}} \
					   -parent .
				      ]
	    }
	}
	# Must have found an executable!		       
	set l_shell [file tail $env(SHELL)]
	set l_rc_file "~/.${l_shell}rc"
	set update_rc [tk_messageBox \
			   -type okcancel \
			   -message "Set MOSFLM_WISH environment variable in $l_rc_file?" \
			   -icon question \
			   -parent .
		      ]
	if {$update_rc == "ok"} {
	    # Make backup of rc file
	    set l_backup "${l_rc_file}_backup[clock format [clock seconds] -format "%Y.%m.%d.%H%M"]"
	    if {![catch {file copy "$l_rc_file" "$l_backup"}]} {
		# Set up new line to be inserted
		switch $l_shell {
		    "sh" -
		    "ksh" -
		    "bash" {
			set l_new_line "export MOSFLM_WISH=$l_wish_executable"
		    }
		    "csh" -
		    "tcsh" {
			set l_new_line "setenv MOSFLM_WISH $l_wish_executable"
		    }
		}
		# Copy over file making edit when required
		set l_in_file [open $l_backup r]
		set l_out_file [open $l_rc_file w]
		set l_edited 0
		while {![eof $l_in_file]} {
		    set l_line [gets $l_in_file]
		    if {[regexp {MOSFLM_WISH} $l_line]} {
			puts $l_out_file $l_new_line
			set l_edited 1
		    } else {
			puts $l_out_file $l_line
		    }
		}
		if {!$l_edited} {
		    puts $l_out_file "# Environment variable telling iMosflm which wish8.4 executable to use"
			puts $l_out_file $l_new_line
		}
		close $l_in_file
		close $l_out_file
	    } else {
	    }
	}
	# Relaunch mosflm
	exec $l_wish_executable ./imosflm.tcl
	exit
    } else {
	exit
    }
}

# set up an environment variable pointing to location of source code
set l_script_path [file normalize [file join [pwd] [info script]]]
set env(MOSFLM_GUI) [file dir [file dir $l_script_path]]


# Set the search path to include all GUI source files and libraries
lappend auto_path $env(MOSFLM_GUI)
lappend auto_path [file join $env(MOSFLM_GUI) lib]
if { $::tcl_platform(os) == "OSF1" } {
    
    if {! [catch {load [file join $env(MOSFLM_GUI) lib alpha-osf1/tkImageLoad.so]}]} {
#	puts "tkImageLoad found and loaded for Alpha running Tru64 UNIX"
#	set ::env(TKIMAGELOAD) 1
    } else {
#	puts "Tru64 - please don't worry"
    }
} elseif { $::tcl_platform(os) == "Linux" } {
    if {![catch {load [file join $env(MOSFLM_GUI) lib tkImageLoad.so]}]} {
#	puts "tkImageLoad found and loaded for PC Linux"
#	set ::env(TKIMAGELOAD) 1
    } else {
#	puts "Linux - please don't worry"
    }
} else {
#    puts "tkImageLoad doesn't exist for this platform - don't worry, this is not an error"
}

# Load libraries for tcl package treectrl
if {[info proc TreeCtrl::SetEditable] == ""} {
    source [file join $env(MOSFLM_GUI) lib filelist-bindings.tcl]
}
usual TreeCtrl {
    rename -background -textbackground textBackground Background
    rename -font -entryfont entryFont Font
    keep -borderwidth

}


# Load bespoke packages
#package require -exact performance 2.0
# Load icons
package require iconlibrary

# Load bespoke utility packages
package require mosflm_utilities
package require mosflmGraph
package require grab 1.0
package require sessiontreedrag 1.0
package require tree 1.0

# Library widgets
package require -exact tablelist 3.7

# Bespoke generic widgets
catch {package require gtooltip} l_result
package require balloonwidget
package require activity
package require gwidgets
package require radio
package require toolbutton 4.0
package require expandbutton
package require combo
package require combobox
usual Combobox {
    rename -highlightbackground -background background Background
}
package require fileopen 2.0
package require linker
package require progressbar

# Bespoke specialized widgets
package require warnings
package require imagenumbers
package require contrast

# Generic dialogs
package require dialog
package require amodaldialog
package require pickwindow
package require message

# Interface components
package require batch
package require promptsavedialog
package require fileopendialog
package require filesavedialog
package require sessionrecoverydialog

# Data classes
package require session
package require userprofile 
package require spots
package require indexing 2.0
package require processingresults

# Session classes
package require settings2
package require settingwidgets

# Mosflm wrapper
package require mosflm 3.0

# Main interface components
package require controller 3.0
package require indexwizard
package require mosaicity

#package require template 

package require strategy
package require processingwizard
package require cellrefinementwizard
package require integrationwizard
package require pointlesswizard
package require history

# Image viewer
package require overlays
package require masking
package require circlefitting
package require imagedisplay 3.0
package require imagedata

# Experiment settings
package require sessionsettings
package require experimentparameters
package require advancedsessionsettings
package require environmentvariables
package require bespokedetectorsettings

# Processing options
package require spotfindingsettings 2.0
package require indexsettings
package require processingsettings
package require advancedrefinementsettings
package require advancedintegrationsettings
package require processingdialog

####################################################################

# Add 'usual' options for used packages

# Set up fonts used in GUI - these will be slightly configurable one day
set normal_font_size 12
if {$::tcl_platform(os) == "Windows NT"} {
    set normal_font_size 10
} elseif {$::tcl_platform(os) == "Darwin"} {
    if {[tk windowingsystem] == "aqua"} {
	# MacOS X with aqua
	set normal_font_size 14
    } else {
	# MacOS X with anything else e.g. X11
	set normal_font_size 10
    }
} else {
    set normal_font_size 12
}
set small_font_size [expr $normal_font_size -2]
set tiny_font_size [expr $normal_font_size -4]
set subtitle_font_size $normal_font_size
set title_font_size [expr $normal_font_size +4]
set huge_font_size [expr $normal_font_size +10]

font create font_l -family helvetica -size $normal_font_size -weight normal
font create font_b -family helvetica -size $normal_font_size -weight bold
font create font_i -family helvetica -size $small_font_size -weight normal -slant italic
font create font_e -family courier -size $normal_font_size -weight normal
font create font_s -family helvetica -size $small_font_size -weight normal
font create font_t -family helvetica -size $tiny_font_size -weight normal
font create font_tb -family helvetica -size $tiny_font_size -weight bold
font create font_g -family symbol -size $normal_font_size -weight normal
font create font_u -family helvetica -size $normal_font_size -weight normal -underline 1
font create subtitle_font -family helvetica -size $subtitle_font_size -weight bold
font create title_font -family helvetica -size $title_font_size -weight bold
font create huge_font -family helvetica -size $huge_font_size -weight bold

# Set global widget options

option add *font font_l
option add *labelFont font_l
option add *entryFont font_e

option add *background #dcdcdc
option add *textBackground white
option add *selectBackground #3399ff
option add *selectForeground white

option add *Frame.borderWidth 0
option add *Canvas.borderWidth 0
option add *Tabset.borderWidth 0
option add *Label.borderWidth 0
#option add *Label.padX 0
option add *Button.borderWidth 2
option add *gEntry.borderWidth 2
option add *gRecord.borderWidth 2
option add *Imagedata.borderWidth 2
option add *Linker.borderWidth 2

option add *Label.anchor w


# Decorate the main window
wm iconbitmap . @[file join $env(MOSFLM_GUI) bitmaps mosflm_inverse.xbm]
wm title . "$::env(IMOSFLM_VERSION)"

# Create utility objects
Grab grabber

# Create tooltip
ToolTip .tooltip

# Create dialogs
Message .m
Promptsavedialog .psd
OptionMessage .om
SessionRecoveryDialog .srd
Advancedsessionsettings .ass -title "Experiment settings"
ProcessingDialog .ats -title "Processing options"
MosaicityEstimation .me -title "Mosaicity estimation"
BatchSubmissionDialog .bsd -title "Batch job submission"
BatchConfigDialog .bcd -title "Batch destinations"
EnvironmentVariables .evs -title "Environment variables"
About .about -title "About iMosflm"
PickWindow .pw -title "Pixel Intensities"

#TemplateProvider .temp_prov -title "User Defined template"
#.temp_prov show

# Create the project pointer
set ::session ""

# Create the master controller (which contains all other controls)
Controller .c
pack .c -fill both -expand 1

# Create image viewer
ImageDisplay .image
wm title .image "\[No image\] - Mosflm" 

# Show main window
wm deiconify .

# initalize the controller!
debug "Initializing main controller"
.c initialize
raise .c
update
