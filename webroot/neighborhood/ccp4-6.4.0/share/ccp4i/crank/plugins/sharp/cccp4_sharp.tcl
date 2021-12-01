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

proc sharp_proc { arrayname counter } {
    upvar #0 $arrayname array
    global all_subframes

    CreateLine line \
	label "SHARP will be used for refinement and phasing"

    OpenSubFrame frame -toggle_display SHOW_ALL_PIPELINE_INPUT open 1

    lappend all_subframes $frame

    CreateLine line \
	label "Input Experimental Columns" \
	widget INPUT_EXPERIMENTAL_COLUMNS -width 55

    CreateLine line \
	label "Input Substructure" \
	widget INPUT_SUBSTRUCTURE -width 55

    CloseSubFrame

    CreateLine line \
	label "Do not generate phases for enantiomorph" \
	message "Click on if you do not want a HKLOUT-oh file for the enantiomorph substructure" \
	widget SHARP_HAND

    CreateLine line \
	label "Stop the crank job if the FOM is less than" \
	widget SHARP_STOP_FOM \
	message "Stop criteria for a SHARP job" 

    CreateLine line \
	label "Do not refine: atomic coordinates " \
	message "Click on if you do not want to refine atomic coordinates" \
	widget SHARP_XYZNREF \
	label " B-factors " \
	message "Click on if you do not want to refine B-factors" \
	widget SHARP_BFACNREF \
	label " Occupancies " \
	message "Click on if you do not want to refine Occupancies" \
	widget SHARP_OCCUNREF

#    CreateLine line \
#	label " Error parameters " \
#	message "Which parameters to refine in SHARP" \
#	widget SHARP_ERRREF \ 

    if { $array(SHARP_STOP_FOM,$counter) == "" } {
        set array(SHARP_STOP_FOM,$counter) 0.19
    }
}

proc sharp_plugin_update { arrayname counter } {
    upvar #0 $arrayname array
}

proc sharp_setup { } {
}
