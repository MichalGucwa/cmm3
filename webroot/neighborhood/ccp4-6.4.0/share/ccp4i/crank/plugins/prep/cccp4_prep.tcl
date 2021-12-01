#
# Copyright (C) Navraj S. Pannu and Steven Ness 2005, Leiden University
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
#
proc prep_proc { arrayname counter } {
    upvar #0 $arrayname array
    global all_subframes

    foreach subframe $all_subframes {
	trace vdelete array(PREP_INPUT_RFREE,$counter) w "update_main_scroll $subframe"
    }

    CreateLine line \
	label "Scaleit will be used for scaling the data sets."
    OpenSubFrame frame -toggle_display SHOW_ALL_PIPELINE_INPUT open 1

    lappend all_subframes $frame

    CreateLine line \
	label "Input Experimental Columns" \
	widget INPUT_EXPERIMENTAL_COLUMNS -width 55 \


    CloseSubFrame

    OpenSubFrame frame -toggle_display INPUT_INTENSITY,$counter open 0

    lappend all_subframes $frame

    CreateLine line \
	message "Scale amplitudes absolute to expected number of residues/nucleotides" \
	label "Apply absolute scaling to F "  \
	widget PREP_RESCALE_F 

    CloseSubFrame
}

proc prep_plugin_update { arrayname counter } {
}


proc prep_setup { } {

}
