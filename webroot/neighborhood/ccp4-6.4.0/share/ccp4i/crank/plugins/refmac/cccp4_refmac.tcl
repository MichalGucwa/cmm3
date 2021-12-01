#
# Copyright (C) Navraj S. Pannu 2008, Leiden University
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

proc refmac_proc { arrayname counter } {
    upvar #0 $arrayname array
    global all_subframes

    CreateLine line \
	label "REFMAC will be used for substructure refinement and phasing"

    OpenSubFrame frame -toggle_display SHOW_ALL_PIPELINE_INPUT open 1

    lappend all_subframes $frame

    CreateLine line \
	label "Input Experimental Columns" \
	widget INPUT_EXPERIMENTAL_COLUMNS -width 55

    CreateLine line \
        label "Input FREER Column" \
        widget INPUT_FREER_COLUMNS -width 25

    CreateLine line \
	label "Input Substructure" \
	widget INPUT_SUBSTRUCTURE -width 55

    CloseSubFrame

    CreateLine line \
	label "Number of refinement cycles" \
	message "Number of refinement cycles" \
	widget REFMAC_CYCLES

    CreateLine line \
	label "Do not generate phases for enantiomorph" \
	message "Click on if you do not want a HKLOUT file for the enantiomorph substructure" \
	widget REFMAC_NOHAND

    CreateLine line \
	label "Bulk solvent" \
	message "Click on if you want to model bulk solvent" \
	widget REFMAC_SOLVENT

    CreateLine line \
	label "Stop the crank job if the FOM is less than" \
	widget REFMAC_STOP_FOM \
	message "Stop criteria for a REFMAC job" 

    CreateLine line \
	label "Do not refine: atomic coordinates " \
	message "Click on if you do not want to refine atomic coordinates" \
	widget REFMAC_XYZNREF \
	label " B-factors " \
	message "Click on if you do not want to refine B-factors" \
	widget REFMAC_BFACNREF \
	label " Occupancies " \
	message "Click on if you do not want to refine Occupancies" \
	widget REFMAC_OCCUNREF

    if { $array(REFMAC_STOP_FOM,$counter) == "" } {
        set array(REFMAC_STOP_FOM,$counter) 0.19
    }

    if { $array(REFMAC_CYCLES,$counter) == "" } {
        set array(REFMAC_CYCLES,$counter) 30
    }
}

proc refmac_plugin_update { arrayname counter } {
    upvar #0 $arrayname array
}

proc refmac_setup { } {
    global programs_toggleframe_list

    # Append the DefineMenu items that follow to the list of variables
    # passed to the Program palette CreateToggleFrame function.
    lappend programs_toggleframe_list "REFMAC_MODE"

    DefineMenu _refmac_mode [list PHASE RIGID REFINE ]

}
