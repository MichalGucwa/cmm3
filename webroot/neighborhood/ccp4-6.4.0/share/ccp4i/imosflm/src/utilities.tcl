# $Id: utilities.tcl,v 1.10 2012/03/26 16:36:39 ccb Exp $
package provide mosflm_utilities 2.0
#
# This file contains miscellaneous functions that don't belong
#    to UI objects
#
# Contents:
#
# I Misc
#
#    1 Auto-scroll
#
#    2 Number list abbreviations
#
#    3 File path abbreviation
#
#    4 List comparison
#
#
#
# II Functions for handling image files
#
#    1 Sorting functions
#
#    2 Template derivation
#
#    3 Image number extraction
#
# III Named arguments
#
#    1 Procedure to allow use of named arguments
#
#      Cursor
#
#      open_url
#
# #######################################################################
# I Misc
# #######################################################################

# #######################################################################
# I - 1 - Template derivation

###########################
# I - 1 - A - Autoscroll

proc autoscroll { scrollbar first last} {
    if {$first <= 0 && $last >= 1} {
	grid remove $scrollbar
    } else {
	grid $scrollbar
    }
    $scrollbar set $first $last
} 

# #######################################################################
# I - 2 Number list abbreviations

####################################
# I - 2 - A number list abbreviation

proc compressNumList { a_num_list { a_and ""} } {
#	set a_num_list [lsort -unique $a_num_list]
    set result [lindex $a_num_list 0]
    set current_num [lindex $a_num_list 0]
    set run_flag 0
    foreach i_num [lrange $a_num_list 1 end] {
	if {$i_num == ($current_num + 1)} {
	    set run_flag 1
	} else {
	    if {$run_flag == 1} {
		append result "-$current_num"
		set run_flag 0
	    }
	    append result ", $i_num"
	}
	set current_num $i_num
    }
    if {$run_flag == 1} {
	append result "-$current_num"
    }
    if {$a_and != ""} {
	if {$a_and == "&"} {
	    set a_and "\\&"
	}
	regsub {^(.+),([^,]+)$} $result "\\1 ${a_and}\\2" result
    }
    return $result
}

########################################
# I - 2 - B - Number list unabbreviaiton

proc uncompressNumList { a_num_list_string } {
    # replace ands/&'s with commas
    regsub -all {\&} $a_num_list_string {,} a_num_list_string
    regsub -all {and} $a_num_list_string {,} a_num_list_string

    # replace spaces with commas
    regsub -all { } $a_num_list_string {,} a_num_list_string
    
    # initialize result list
    set result {}    

    # loop through comma-separated string portions...
    foreach i_portion [split $a_num_list_string ","] {
	if {[regexp {^\s*(\d+)\s*$} $i_portion match num]} {
	    lappend result $num
	} elseif {[regexp {^\s*(\d+)\s*-\s*(\d+)\s*$} $i_portion match num1 num2]} {
	    lappend result $num1
	    incr num1
	    while {$num1 <= $num2} {
		lappend result $num1
		incr num1
	    }
	}
    }
    
    return $result
}


# #######################################################################
# I - 3 File path abbreviation

proc abbreviatePath { a_path a_length } {
    if {[string length $a_path] <= $a_length} {
	set abbreviation $a_path
    } elseif {[string length "/.../[file tail $a_path]"] >= $a_length} {
	set abbreviation "/.../[file tail $a_path]"
    } else {
	set last_char_index [expr $a_length - [string length ".../[file tail $a_path]"] - 1]
	set abbreviation "[string range $a_path 0 $last_char_index].../[file tail $a_path]"
    }
    return $abbreviation
}   

# #######################################################################
# I - 4 List comparison

proc lequal { a_list b_list } {
    set result 1
    if {[llength $a_list] == [llength $b_list]} {
	set i 0
	while {$i < [llength $a_list]} {
	    if {[lindex $a_list $i] != [lindex $b_list $i]} {
		set result 0
		break
	    }
	    incr i
	}
    } else {
	set result 0
    }
    return $result
}   

# #######################################################################
# II Functions for handling image files
# #######################################################################


# #######################################################################
# II - 1 Sorting functions

###########################
# II - 1 A - Sorting directories

proc sort_dirs { a b } {
	if {![regexp {(.*/)([^/]+/?)} $a match a_path a_tail]} {
	    # error
      return 0
   }
	if {![regexp {(.*/)([^/]+/?)} $b match b_path b_tail]} {
	    # error
      return 0
   }

   if {$a_path == $b_path} {
   	# sort by dir, then name
      set a_is_dir [file isdir $a]
      set b_is_dir [file isdir $b]
      if {$a_is_dir && !$b_is_dir} { return -1 }
      if {!$a_is_dir && $b_is_dir} { return +1 }
	}
   if {$a < $b} {return -1}
   if {$a > $b} {return +1}
   return 0
}

##############################
# II - 1 B - Sorting template types
#       Alphabetic, but "All images" goes first, and "All files goes last"

proc sort_templatefilters {a b} {
	if {[regexp {All image} $a]} {return -1}
   if {[regexp {All image} $b]} {return +1}
   if {[regexp {All files} $a]} {return +1}
   if {[regexp {All files} $b]} {return -1}
   if {$a < $b} { return -1 }
   if {$b < $a} { return +1 }
   return 0
}

##############################
# II - 1 C - Sorting project file filter types

proc sort_projectfilters { a b } {
	if {[regexp {Mosflm project files} $a]} {return -1}
   if {[regexp {Mosflm project files} $b]} {return +1}
	if {[regexp {All files} $a]} {return +1}
   if {[regexp {All files} $b]} {return -1}
	return 0
}

##############################
# II - 1 D - simple sort

proc sort_simple { a b } {
	if { $a < $b } { return -1 }
   if { $a > $b } { return +1 }
   return 0
}

# #######################################################################
# II - 2 Template derivation

proc get_template { filename } {
	# puts $filename
	set max_search 9
	set base d
	for {set i 1} {$i < $max_search} {incr i 1} {
   	if {[regexp [mk_exp $base] [file tail $filename]]} {
			for {set j -1} {$j < [expr [string length $base] - 1]} {incr j 2} {
            set expression "[string range $base 0 $j])d([string range $base [expr $j + 2] end]"
            set expression [mk_exp $expression]
            if {[regexp $expression [file tail $filename] match prefix suffix]} {
            	set numdigits [expr [string length [file tail $filename]] - \
               	[string length $prefix] - [string length $suffix]]
               set numhashes(${prefix}*${suffix}) $numdigits
               set likelihood(${prefix}*${suffix}) \
                  [llength [glob -nocomplain -directory [file dirname $filename] -- "${prefix}*${suffix}"]]
            } else {
            	# "Error in get_template (utilities.tcl)"
            }
         }
	 # puts $prefix $suffix
         set score 0
         set choice "Unchosen"
         foreach possibility [array names likelihood] {
         	if {$likelihood($possibility) > $score} {
            	set score $likelihood($possibility)
					set hashes ""
               for {set h_count 0} {$h_count < $numhashes($possibility)} {incr h_count 1} {
               	set hashes "${hashes}#"
               }
               regsub {\*} $possibility $hashes choice
            }
			}
         return $choice
	 # puts $choice
      } else {
      	set base "${base}nd"
      }
	}
	warn "Error: Could not work out template."
   return "Oh dear!"
}

proc filenameFromTemplate {a_template a_image_number} {
	set template $a_template
	set image_number $a_image_number

	regexp {\#+} $template hashes

	set hashes_length [string length $hashes]
	set image_number_length [string length $image_number]
	set zeros [string repeat "0" [expr $hashes_length - $image_number_length]]
	set numeric_part "$zeros$image_number"

	regsub $hashes $template $numeric_part image_filename

	return $image_filename
}


proc mk_exp { base } {
	regsub -all n $base "\\D+" base
	regsub -all d $base "\\d+" base
	return "(^\\D*$base\\D*\$)"
}

proc get_im_num { filename template } {
   set index [string first "#" $template]
   regexp {^\d+} [string range $filename $index end] match
   return $match
}


proc warn { message } {
	puts $message
}

# #######################################################################
# # III Named arguments
# #######################################################################

proc options {defaults arguments} {
    upvar 1 options options
    array set options $defaults
    foreach {key value} $arguments {
	if {![info exists options($key)]} {
	    error "bad option '$key', should be one of: [lsort [array names options]]"
	}
	set options($key) $value
    }
}

##################################################
# Cursor
# Global Cursor changing Function
##################################################

proc Cursor { newcursor args} {
	global env
	if {[lsearch \
		 [list X_cursor arrow based_arrow_down based_arrow_up \
		      boat bogosity bottom_left_corner bottom_right_corner \
		      bottom_side bottom_tee box_spiral center_ptr \
		      circle clock coffee_mug cross cross_reverse crosshair \
		      diamond_cross dot dotbox double_arrow draft_large \
		      draft_small draped_box exchange fleur gobbler gumby \
		      hand1 hand2 heart icon iron_cross left_ptr left_side \
		      left_tee leftbutton ll_angle lr_angle man middlebutton \
		      mouse pencil pirate plus question_arrow right_ptr \
		      right_side right_tee rightbutton rtl_logo sailboat \
		      sb_down_arrow sb_h_double_arrow sb_left_arrow \
		      sb_right_arrow sb_up_arrow sb_v_double_arrow shuttle \
		      sizing spider spraycan star target tcross top_left_arrow \
		      top_left_corner top_right_corner top_side top_tee trek \
		      ul_angle umbrella ur_angle watch xterm] $newcursor] == -1
	} {
	    if {($::tcl_platform(os) != "Darwin") &&
		($::tcl_platform(os) != "Windows NT")} {
		set newcursor "@[file join $env(MOSFLM_GUI) bitmaps $newcursor.cursor] [file join $env(MOSFLM_GUI) bitmaps $newcursor.mask] black white"
	    } else {
		set newcursor left_ptr
	    }
	}
    if {[expr [llength $args] > 0]} {
	foreach widget $args {
	    $widget configure -cursor $newcursor
	}
    } else {
	foreach widget [winfo children .] {
	    $widget configure -cursor $newcursor
	}
    }
}


#---------------------------------------------------------------------
proc open_url { url args } {
#---------------------------------------------------------------------
#d_sum Open a specified file in a browser window
#d_desc  Open a specified file in a currently open browser window
#d_arg url	full path name of file
#d_arg target	optional target within file
#d_opt0 -remote
#d_opt1 The url is not a local file     
#  global configure
#  global system
#  global tcl_platform
  # Check that a viewer is set in configure
    if {[$::session getParameterValue web_browser] != ""} {
# set via Environement variable settings window
	set WEB_BROWSER [$::session getParameterValue web_browser]
	set ::env(CCP4_BROWSER) [$::session getParameterValue web_browser]
    } {
	if { ! [info exists WEB_BROWSER] } {
	    set WEB_BROWSER $::env(CCP4_BROWSER)
	    $::session updateSetting web_browser $::env(CCP4_BROWSER) 0 0 "Processing_options"
	}
    }
#	puts $::env(CCP4_BROWSER)

  if { [regexp "^\[ \t\]*$" $WEB_BROWSER)] || $WEB_BROWSER == "" } {
	.m confirm \
	    -type "1button" \
	    -button1of1 "Dismiss" \
	    -text "The web browser is not defined in the CCP4 setup file"
#    WarningMessage "Cannot open requested URL:
#
#\"$url\"
#
#The hypertext viewer command is not set in
#the CCP4i configuration window."
    return
  }

  set target {}
  set remote 0

  # Process optional arguments 
  set nargs [llength $args]; set n 0; while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    targ {
      incr n; set target [lindex $args $n]
    } remo {
      set remote 1
    }
    incr n
  }

  if { !$remote && ![file exists $url] } {
	.m confirm \
	    -type "1button" \
	    -button1of1 "Dismiss" \
	    -text "Can not find file \n$url"
#    WarningMessage "Can not find help file $url"
    return
  }
  if { $target != "" } { append  url "#" $target }

#  TkBusy .

# check platform first

if {[regexp -nocase windows $::tcl_platform(os)]} {

    # This seems to work okay for Windows
    if { [catch "exec \"$WEB_BROWSER\" \"$url\" &" message ]
	 && ![regexp warning: "$message"] } {
	#        warning_no_netscape $url $message
	.m confirm \
	    -type "1button" \
	    -button1of1 "Dismiss" \
	    -text "$url \n$message"
    }
} elseif { ![regexp -nocase windows $::tcl_platform(os)] } {

    if { $::tcl_platform(os) == "Darwin" } {
	# for IE on make open only opens pages
	set viewer_cmd "exec open -a {$WEB_BROWSER} [lindex [split $url # ] 0 ]"
    } {
	# For non-Mac UNIX
	
	# Are we using Netscape?
	if { [regexp "netscape" $WEB_BROWSER ] } {
	    if { $::tcl_platform(os) == "Linux" } {
		# Linux only
		# Start a new netscape for each help request
		set viewer_cmd "exec $WEB_BROWSER $url &"
	    }
	    # Command to open requested URL in netscape
	    if { $remote } {
		set viewer_cmd "poll_netscape remote 500 0 $url"
	    } else {
		set viewer_cmd "poll_netscape file 500 0 $url"
	    }
	} elseif { [regexp "mozilla" $WEB_BROWSER ] || [regexp "firefox" $WEB_BROWSER ] } {
	    
	    # This seems to be necessary for Mozilla
	    if { !$remote } { set url "file://$url" }
	    # Check if browser already open cf. Netscape version above
	    catch { exec $WEB_BROWSER -remote ping() } mozilla_message
	    if { [regexp "Error" $mozilla_message ] } {
		# Command to open requested URL in new Mozilla browser
		set viewer_cmd "exec $WEB_BROWSER $url &"
	    } else {
		# Command to open requested URL in existing Mozilla browser
		set viewer_cmd "exec $WEB_BROWSER -remote openURL($url) &"
	    }
	} elseif { [regexp "konqueror" $WEB_BROWSER ] } {
	    
	    # This seems to be necessary for Konqueror
	    if { !$remote } { set url "file://$url" }
	    set viewer_cmd "exec $WEB_BROWSER $url &"
	} else {
	    # Command to open requested URL in other browser
	    set viewer_cmd "exec $WEB_BROWSER $url &"
	}
    }
}
# Attempt to open the URL if not windows system
if {![regexp -nocase windows $::tcl_platform(os)] } {
    if { [catch $viewer_cmd message] } {
	.m confirm \
	    -type "1button" \
	    -button1of1 "Dismiss" \
	    -text "$url \n$message"
    }
} 

#  PleaseWait
#  TkBusy . 1

}
