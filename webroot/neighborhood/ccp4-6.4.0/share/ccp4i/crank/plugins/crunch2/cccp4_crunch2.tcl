#
# Copyright (C) Navraj S. Pannu, Steven Ness and RAG de Graaff 2004-2005, Leiden University
# Copyright (C) Navraj S. Pannu and RAG de Graaff 2006-2007, Leiden University
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

proc crunch2_proc { arrayname counter } {
    upvar #0 $arrayname array

    global all_subframes

    CreateLine line \
	label "CRUNCH2 will be used for substructure determination"

    OpenSubFrame frame -toggle_display SHOW_ALL_PIPELINE_INPUT open 1

    lappend all_subframes $frame

    CreateLine line \
	label "Input FA Columns" \
	widget INPUT_FA_COLUMNS -width 55

    CreateLine line \
	label "Input EA Columns" \
	widget INPUT_EA_COLUMNS -width 55
 
    CloseSubFrame


    CreateLine line \
	label "Number of Patterson trials to generate" \
	message "Put 0 (ie. ZERO) if you don't want to generate any Patterson trials." \
	widget CRUNCH2_PATT_TRIALS

    CreateLine line \
	message "Number of trials" \
	label "Number of Crunch2 trials" \
	widget CRUNCH2_TRIALS \
	label "with " \
	message "Number of cycles per trial" \
	widget CRUNCH2_NUM_CYCLES \
	label "cycles per trial" 

    CreateLine line \
	message "CRUNCH2 score threshold after which CRUNCH2 is stopped" \
	label "Stop Crunch2 if a score is greater than" \
	widget CRUNCH2_SCORE_THRESHOLD 

    CreateLine line \
	label "or if the highest score is" \
	message "CRUNCH2 deviation" \
	widget CRUNCH2_DEVIATION \
	label "times the lowest score."

    CreateLine line \
	message "Use BP3 to verify if a solution exists" \
	label "Check using BP3 after " \
	widget CRUNCH2_BP3_VERIFY \
	label " trials if a solution exists." 

    CreateLine line \
        message "In this structure, is it possible to have heavy atoms on special positions?" \
        label "Allow Special Positions?" \
        widget CRUNCH2_SPECIAL_POSITIONS 
    #
    # Set basic defaults
    
    if { $array(CRUNCH2_BP3_VERIFY,$counter) == "" } {
        set array(CRUNCH2_BP3_VERIFY,$counter) 3
    }

    if { $array(CRUNCH2_PATT_TRIALS,$counter) == "" } {
	set array(CRUNCH2_PATT_TRIALS,$counter) 150
    }

    if { $array(CRUNCH2_SCORE_THRESHOLD,$counter) == "" } {
	set array(CRUNCH2_SCORE_THRESHOLD,$counter) 1.00
    }

    if { $array(CRUNCH2_DEVIATION,$counter) == "" } {
	set array(CRUNCH2_DEVIATION,$counter) 1.75
    }

    if { $array(CRUNCH2_NUM_CYCLES,$counter) == "" } {
	set array(CRUNCH2_NUM_CYCLES,$counter) 400
    }

    if { $array(CRUNCH2_TRIALS,$counter) == "" } {
	set array(CRUNCH2_TRIALS,$counter) 20
    }

}

proc crunch2_plugin_update { arrayname counter } {
}

proc crunch2_setup { } {

}
