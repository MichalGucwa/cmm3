#
# Copyright (C) Navraj S. Pannu and Jan Pieter Abrahams 2006,  Leiden University
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#

proc solomon_proc { arrayname counter } {
    upvar #0 $arrayname array
    global all_subframes

    foreach subframe $all_subframes {
	trace vdelete array(SOLOMON_HAND,$counter) w "update_main_scroll $subframe"
	trace vdelete array(SOLOMON_OPT,$counter) w "update_main_scroll $subframe"
	trace vdelete array(SOLOMON_DENMOD,$counter) w "update_main_scroll $subframe"
    }

    CreateLine line \
	label "SOLOMON will be used to determine hand and/or density modification"

    OpenSubFrame frame -toggle_display SHOW_ALL_PIPELINE_INPUT open 1

    lappend all_subframes $frame

    CreateLine line \
	label "Input Experimental Columns" \
	widget INPUT_EXPERIMENTAL_COLUMNS -width 55

    CreateLine line \
	label "Input HL Columns" \
	widget INPUT_HL_COLUMNS -width 55

        CreateLine line \
        label "Input Substructure" \
        widget INPUT_SUBSTRUCTURE -width 55
	
    CloseSubFrame

    CreateLine line \
	message "Try to determine correct hand"  \
	label "Determine correct hand" \
	widget SOLOMON_HAND

    OpenSubFrame frame -toggle_display SOLOMON_HAND,$counter open 1

    lappend all_subframes $frame

    CreateLine line \
	message "Number of cycles of density modification to differentiate the two hands" \
	label "Number of cycles for each hand" \
 	widget SOLOMON_HCYCLES

    CreateLine line \
        message "The least acceptable difference between the contrast to distinguish the correct hand" \
        label "Minimum difference between the contrast " \
        widget SOLOMON_MARGIN

    CloseSubFrame

#    CreateLine line \
#	message "Try to determine optimal solvent content"  \
#	label "Optimize solvent content" \
#	widget SOLOMON_OPT

#    OpenSubFrame frame -toggle_display SOLOMON_OPT,$counter open 1

#    lappend all_subframes $frame

#    CreateLine line \
#	message "Number of cycles of density modification to differentiate varying solvent contents" \
#	label "Number of cycles for different solvent contents" \
# 	widget SOLOMON_OCYCLES

#    CloseSubFrame

    CreateLine line \
 	message "Perform density modification"  \
 	label "Perform density modification" \
 	widget SOLOMON_DENMOD

    OpenSubFrame frame -toggle_display SOLOMON_DENMOD,$counter open 1

    lappend all_subframes $frame
     
    CreateLine line \
	message "Number of cycles of density modifications" \
	label "Number of cycles of density modification" \
 	widget SOLOMON_NCYCLES

    CloseSubFrame

    CreateLine line \
	message "Phase combination algorithm." \
	label "Phase combination algorithm "\
	widget SOLOMON_PHASE_COMB -width 15 

    CreateLine line \
	message "Do not apply bias correction parameter" \
	label "Do not apply bias correction parameter "\
	widget SOLOMON_BIAS -width 15 

#    OpenSubFrame frame -toggle_display SOLOMON_BIAS,$counter open 1

#    lappend all_subframes $frame

#    CreateLine line \
#	message "Use bias parameter" \
#	label "Use bias parameter " \
#	widget SOLOMON_BETA 

#    CloseSubFrame
    
    CreateLine line \
	message "Output the Hendrickson-Lattman coefficients from the input phasing program" \
	label "Output HL coefficients from input phasing program" \
 	widget SOLOMON_HLOUTPUT

    CreateLine line \
	message "Truncate protein density" \
	label "Truncate protein density for regions below " \
	widget SOLOMON_TRUNC_LOW \
	label " or above " \
	widget SOLOMON_TRUNC_HIGH \
	label " of density range"

    CreateLine line \
	message "Solvent analysis radius" \
	label "Solvent analysis radius " \
	widget SOLOMON_RADIUS 

    CreateLine line \
	message "Keep intermediate cycle files"  \
	label "Keep intermediate cycle files" \
	widget SOLOMON_KEEPMTZ

    # Set basic defaults

#   set array(SOLOMON_HAND,$counter) 1

    if { $array(SOLOMON_DENMOD,$counter) == "" } {
	set array(SOLOMON_DENMOD,$counter) 1
    }

    if { $array(SOLOMON_HLOUTPUT,$counter) == "" } {
	set array(SOLOMON_HLOUTPUT,$counter) 1
    }

    if { $array(SOLOMON_MARGIN,$counter) == "" } {
        set array(SOLOMON_MARGIN,$counter) 0.0025
    }

    if { $array(SOLOMON_HCYCLES,$counter) == "" } {
	set array(SOLOMON_HCYCLES,$counter) 10
    }

    if { $array(SOLOMON_BIAS,$counter) == "" } {
	set array(SOLOMON_BIAS,$counter) 1.0
    }

#   if { $array(SOLOMON_OCYCLES,$counter) == "" } {
#set array(SOLOMON_OCYCLES,$counter) 5
#   }

    if { $array(SOLOMON_NCYCLES,$counter) == "" } {
	set array(SOLOMON_NCYCLES,$counter) 20
    }

    if { $array(SOLOMON_TRUNC_LOW,$counter) == "" } {
        set array(SOLOMON_TRUNC_LOW,$counter) 0.4
    }

    if { $array(SOLOMON_TRUNC_HIGH,$counter) == "" } {
        set array(SOLOMON_TRUNC_HIGH,$counter) 1.0
    }

    if { $array(SOLOMON_RADIUS,$counter) == "" } {
        set array(SOLOMON_RADIUS,$counter) 3
    }
}

proc solomon_plugin_update { arrayname counter } {

}

proc solomon_setup { } {
    global programs_toggleframe_list

    # Append the DefineMenu items that follow to the list of variables
    # passed to the Program palette CreateToggleFrame function.
    lappend programs_toggleframe_list "SOLOMON_PHASE_COMB" 

    DefineMenu _solomon_phase_comb [list "MLHL" "DIRECT" ] \
 	[list MLHL DIRECT]
}
