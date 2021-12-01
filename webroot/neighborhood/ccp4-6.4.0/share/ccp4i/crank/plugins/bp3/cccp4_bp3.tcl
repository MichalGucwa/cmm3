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

proc bp3_proc { arrayname counter } {
    upvar #0 $arrayname array
    global all_subframes

    CreateLine line \
	label "BP3 will be used for refinement and phasing"

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
	label "Faster phasing" \
	message "Use the PHASE keyword in BP3 to do fast phasing" \
	widget BP3_PHASE

    CreateLine line \
	label "Do not generate phases for enantiomorph" \
	message "Click on if you do not want a HKLOUT-oh file for the enantiomorph substructure" \
	widget BP3_NOHAND

    CreateLine line \
	label "Do not find and refine potential sites from gradient maps" \
	message "Click on if you do not automated gradient map analysis and another round of refinement" \
	widget BP3_NODIFF

    CreateLine line \
	label "Stop the crank job if the FOM is less than" \
	widget BP3_STOP_FOM \
	message "Stop criteria for a BP3 job" 

    CreateLine line \
	label "Do not refine: atomic coordinates " \
	message "Click on if you do not want to refine atomic coordinates" \
	widget BP3_XYZNREF \
	label " B-factors " \
	message "Click on if you do not want to refine B-factors" \
	widget BP3_BFACNREF \
	label " Occupancies " \
	message "Click on if you do not want to refine Occupancies" \
	widget BP3_OCCUNREF

#    CreateLine line \
#	label " Error parameters " \
#	message "Which parameters to refine in BP3" \
#	widget BP3_ERRREF \ 

    if { $array(BP3_STOP_FOM,$counter) == "" } {
        set array(BP3_STOP_FOM,$counter) 0.19
    }
}

proc bp3_plugin_update { arrayname counter } {
    upvar #0 $arrayname array
}

proc bp3_setup { } {
}
