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

proc check_proc { arrayname counter } {
    upvar #0 $arrayname array
    global all_subframes

    CreateLine line \
	label "CHECK will be used for validating with a known structure"

    OpenSubFrame frame -toggle_display SHOW_ALL_PIPELINE_INPUT open 1

    lappend all_subframes $frame

     CreateLine line \
        label "Input Pdb" \
        widget INPUT_PDB -width 55

     CreateLine line \
        label "Input Substructure" \
        widget INPUT_SUBSTRUCTURE -width 55

    CreateLine line \
	label "Input Phase Columns" \
	widget INPUT_PHASE_COLUMNS -width 55
    
    CloseSubFrame

    CreateLine line \
	message "Place your final pdb to validate model obtained"  \
	label "Final pdb" \
	widget CHECK_PDB

}

proc check_plugin_update { arrayname counter } {
}

proc check_setup { } {
}
