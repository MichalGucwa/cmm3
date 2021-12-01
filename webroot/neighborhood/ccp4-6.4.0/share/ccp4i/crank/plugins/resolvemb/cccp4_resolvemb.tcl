#
# Copyright (C) Navraj S. Pannu 2006-2007, Leiden University
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

proc resolvemb_proc { arrayname counter } {
    upvar #0 $arrayname array
    global all_subframes

    foreach subframe $all_subframes {
	trace vdelete array(RESOLVEMB_HL_TOGGLE,$counter) w "update_main_scroll $subframe"
    }

    CreateLine line \
	label "RESOLVEMB will be used for model building"

    OpenSubFrame frame -toggle_display SHOW_ALL_PIPELINE_INPUT open 1

    lappend all_subframes $frame

     CreateLine line \
        label "Input Substructure" \
        widget INPUT_SUBSTRUCTURE -width 55

    CreateLine line \
	label "Input Experimental Columns" \
	widget INPUT_EXPERIMENTAL_COLUMNS -width 55

    CreateLine line \
	label "Input Phase Columns" \
	widget INPUT_PHASE_COLUMNS -width 55

    OpenSubFrame frame -toggle_display RESOLVEMB_HL_TOGGLE,$counter open 1
	 
    CreateLine line \
	label "Input HL Columns" \
	widget INPUT_HL_COLUMNS -width 55
	
    CloseSubFrame
    
    CloseSubFrame

    CreateLine line \
	message "Find and use NCS"  \
	label "Find and use NCS" \
	widget RESOLVEMB_NCS

    CreateLine line \
	message "Type of model building "  \
	label "Do a " \
	widget RESOLVEMB_BUILD \
	label " build."


    # Set basic defaults

    set array(RESOLVEMB_NCS,$counter) 1
    set array(RESOLVEMB_HL_TOGGLE,$counter) 1

}

proc resolvemb_plugin_update { arrayname counter } {
}

proc resolvemb_setup { } {
    global programs_toggleframe_list

    # Append the DefineMenu items that follow to the list of variables
    # passed to the Program palette CreateToggleFrame function.
    lappend programs_toggleframe_list "RESOLVEMB_BUILD"

    DefineMenu _resolve_type [list superquick quick thorough aggressive conservative ]
}
