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

proc pirate_proc { arrayname counter } {
    upvar #0 $arrayname array
    global all_subframes

    CreateLine line \
	label "PIRATE will be used for density modification"

    OpenSubFrame frame -toggle_display SHOW_ALL_PIPELINE_INPUT open 1

    lappend all_subframes $frame

    CreateLine line \
	label "Input Substructure" \
	widget INPUT_SUBSTRUCTURE -width 55	

    CreateLine line \
	label "Input Experimental Columns" \
	widget INPUT_EXPERIMENTAL_COLUMNS -width 55

    CreateLine line \
	label "Input FreeR Columns" \
	widget INPUT_FREER_COLUMNS -width 55
	 
    CreateLine line \
	label "Input HL Columns" \
	widget INPUT_HL_COLUMNS -width 55	
    
    CloseSubFrame

    CreateLine line \
	message "Use Non-crystallographic symmetry (NCS)" \
	label "Use NCS relationships from heavy atoms for phase improvement" \
  	widget PIRATE_USENCS     

    CreateLine line \
	message "Perform automatic cell content estimation" \
	label "Automatically adjust the content of the unit cell (auto-content)" \
 	widget PIRATE_AUTOCONTENT

#   CreateLine line \
#message "Perform automatic weighting of non-ncs phase information" \
#label "Automatically weight the histogram data" \
#	widget PIRATE_AUTOWEIGHT

    CreateLine line \
	message "Weight to apply to input phases to correct for bias" \
	label "Weight to apply to input phases" \
 	widget PIRATE_INPUTWEIGHT \
	message "Number of cycles" \
	label "Number of cycles" \
 	widget PIRATE_NCYCLES
    
    CreateLine line \
	message "Output the Hendrickson-Lattman coefficients from the input phasing program" \
	label "Output HL coefficients from input phasing program" \
 	widget PIRATE_HLOUTPUT

    CloseSubFrame

    # Set basic defaults

    if { $array(PIRATE_HLOUTPUT,$counter) == "" } {
	set array(PIRATE_HLOUTPUT,$counter) 1
    }
 
    if { $array(PIRATE_AUTOCONTENT,$counter) == "" } {
	set array(PIRATE_AUTOCONTENT,$counter) 1
    }

    if { $array(PIRATE_INPUTWEIGHT,$counter) == "" } {
	set array(PIRATE_INPUTWEIGHT,$counter) 1.0
    }

    if { $array(PIRATE_NCYCLES,$counter) == "" } {
	set array(PIRATE_NCYCLES,$counter) 3
    }

}

proc pirate_plugin_update { arrayname counter } {
}

proc pirate_setup { } {
}
