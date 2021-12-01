#
# Copyright (C) Navraj S. Pannu and Steven Ness 2004-2005, Leiden University
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

proc resolvedm_proc { arrayname counter } {
    upvar #0 $arrayname array
    global all_subframes

    CreateLine line \
	label "RESOLVEDM will be used for density modification"

    OpenSubFrame frame -toggle_display SHOW_ALL_PIPELINE_INPUT open 1

    lappend all_subframes $frame

     CreateLine line \
        label "Input Substructure" \
	widget INPUT_SUBSTRUCTURE -width 55

    CreateLine line \
	label "Input Experimental Columns" \
	widget INPUT_EXPERIMENTAL_COLUMNS -width 55

    CreateLine line \
	label "Input HL Columns" \
	widget INPUT_HL_COLUMNS -width 55
	
    CloseSubFrame

    CreateLine line \
	message "Find and use NCS"  \
	label "Find and use NCS" \
	widget RESOLVEDM_NCS

    
    CreateLine line \
	message "Output the Hendrickson-Lattman coefficients from the input phasing program" \
	label "Output HL coefficients from input phasing program" \
 	widget RESOLVEDM_HLOUTPUT

    # Set basic defaults

    if { $array(RESOLVEDM_NCS,$counter) == "" } {
       set array(RESOLVEDM_NCS,$counter) 1
    }

    if { $array(RESOLVEDM_HLOUTPUT,$counter) == "" } {
       set array(RESOLVEDM_HLOUTPUT,$counter) 1
    }
}

proc resolvedm_plugin_update { arrayname counter } {
}

proc resolvedm_setup { } {
}
