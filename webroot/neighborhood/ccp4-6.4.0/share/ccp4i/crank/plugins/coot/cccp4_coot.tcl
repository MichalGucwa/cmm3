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

proc coot_proc { arrayname counter } {
    upvar #0 $arrayname array
    global all_subframes

    foreach subframe $all_subframes {
        trace vdelete array(INPUT_PDB,$counter) w "update_main_scroll $subframe"
        trace vdelete array(INPUT_PHASE_COLUMNS,$counter) w "update_main_scroll $subframe"
        trace vdelete array(INPUT_SUBSTRUCTURE,$counter) w "update_main_scroll $subframe"
    }

    CreateLine line \
	label "Coot will be used for visualization"

    OpenSubFrame frame -toggle_display SHOW_ALL_PIPELINE_INPUT open 1

    lappend all_subframes $frame

    CreateLine line \
	label "Input Pdb" \
	widget INPUT_PDB -width 55	

    CreateLine line \
	label "Input Substructure" \
	widget INPUT_SUBSTRUCTURE -width 55	

    CreateLine line \
	label "Input Experimental Columns" \
	widget INPUT_EXPERIMENTAL_COLUMNS -width 55

    CreateLine line \
	label "Input Phase Columns" \
	widget INPUT_PHASE_COLUMNS -width 55	

    CreateLine line \
	label "Input FreeR Columns" \
	widget INPUT_FREER_COLUMNS -width 55
	     
    CloseSubFrame

    CreateLine line \
	label "Display substructure, map and/or model " 
# message "Display substructure" \
# 	widget COOT_SUBSTRUCTURE

#     OpenSubFrame frame -toggle_display INPUT_PHASE_COLUMNS hide ""

#     CreateLine line \
# 	label "Display map" \
# 	message "Display map" \
# 	widget COOT_MAP

 #    CloseSubFrame

#     OpenSubFrame frame -toggle_display INPUT_PDB open ""

#     lappend all_subframes $frame

#     CreateLine line \
# 	label "Display pdb" \
# 	message "Display pdb" \
# 	widget COOT_PDB

#     CloseSubFrame

#   puts "INPUT_PHASE_COLUMNS is $array(INPUT_PHASE_COLUMNS,$counter)"
#   puts "INPUT_SUBSTRUCTURE is $array(INPUT_SUBSTRUCTURE,$counter)"
#   puts "INPUT_PDB is $array(INPUT_PDB,$counter)"

    set array(COOT_MAP,$counter) 1
    set array(COOT_PDB,$counter) 1
    set array(COOT_SUBSTRUCTURE,$counter) 1
}

proc coot_plugin_update { arrayname counter } {
}

proc coot_setup { } {
}
