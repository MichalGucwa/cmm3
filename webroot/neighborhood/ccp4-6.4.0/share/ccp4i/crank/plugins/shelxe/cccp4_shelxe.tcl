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

proc shelxe_proc { arrayname counter } {
    upvar #0 $arrayname array
    global all_subframes
    
    foreach subframe $all_subframes {
	trace vdelete array(INPUT_INTENSITY) w "update_main_scroll $subframe"
	trace vdelete array(SHELXE_INPUT_PHASES,$counter) w "update_main_scroll $subframe"
	trace vdelete array(SHELXE_HAND,$counter) w "update_main_scroll $subframe"
	trace vdelete array(SHELXE_OPT,$counter) w "update_main_scroll $subframe"
	trace vdelete array(SHELXE_DENMOD,$counter) w "update_main_scroll $subframe"
	trace vdelete array(SHELXE_FREE_LUNCH,$counter) w "update_main_scroll $subframe"
    }

    CreateLine line \
	label "SHELXE will be used for substructure refinement/density modification"

    OpenSubFrame frame -toggle_display SHOW_ALL_PIPELINE_INPUT open 1

    lappend all_subframes $frame

    OpenSubFrame frame -toggle_display INPUT_INTENSITY open 1

    CreateLine line \
	label "Input I Columns" \
	widget INPUT_I_COLUMNS -width 55

    CloseSubFrame

    OpenSubFrame frame -toggle_display INPUT_INTENSITY open 0

    CreateLine line \
	label "Input F Columns" \
	widget INPUT_F_COLUMNS -width 55

    CloseSubFrame

    CreateLine line \
	label "Input Fa Columns" \
	widget INPUT_FA_COLUMNS -width 55

    CreateLine line \
	label "Input ALPHA Columns" \
	widget INPUT_ALPHA_COLUMNS -width 55

    OpenSubFrame frame -toggle_display INPUT_PDB,$counter hide [list ""]

    CreateLine line \
	label "Input Pdb" \
	widget INPUT_PDB -width 55
	 
    CloseSubFrame

    CreateLine line \
	label "Input Substructure" \
	widget INPUT_SUBSTRUCTURE -width 55

    OpenSubFrame frame -toggle_display SHELXE_INPUT_PHASES,$counter open 1
         
    CreateLine line \
	label "Input Phase Columns" \
	widget INPUT_PHASE_COLUMNS -width 55
         
    CloseSubFrame

    CloseSubFrame

    CreateLine line \
	message "Try to determine correct hand"  \
	label "Determine correct hand" \
	widget SHELXE_HAND

    OpenSubFrame frame -toggle_display SHELXE_HAND,$counter open 1

    lappend all_subframes $frame

    CreateLine line \
	message "Number of cycles of density modification to differentiate the two hands" \
	label "Number of cycles for each hand" \
 	widget SHELXE_HCYCLES
    
    CloseSubFrame

#   CreateLine line \
#message "Try to determine optimal solvent content"  \
#label "Optimize solvent content" \
#widget SHELXE_OPT

#   OpenSubFrame frame -toggle_display SHELXE_OPT,$counter open 1

#   lappend all_subframes $frame

#   CreateLine line \
#message "Number of cycles of density modification to differentiate varying solvent contents" \
#label "Number of cycles for different solvent contents" \
#	widget SHELXE_OCYCLES
    
#   CloseSubFrame

    CreateLine line \
	message "Perform density modification"  \
	label "Perform density modification" \
	widget SHELXE_DENMOD

    OpenSubFrame frame -toggle_display SHELXE_DENMOD,$counter open 1

    lappend all_subframes $frame

    CreateLine line \
	message "Cycles of density modification" \
	label "Cycles of density modification" \
	widget SHELXE_NCYCLES

    CreateLine line \
	message "Generate heavy atoms from modified density" \
	label "Generate heavy atoms from modified density" \
	widget SHELXE_GENERATE_HEAVY 

    CreateLine line \
	message "Use the Free Lunch Algorithm" \
	label "Use the Free Lunch Algorithm" \
	widget SHELXE_FREE_LUNCH

    OpenSubFrame frame -toggle_display SHELXE_FREE_LUNCH,$counter open 1
    
    CreateLine line \
	message "Free lunch algorithm resolution" \
	label "Extend the resolution to " \
	widget SHELXE_FREE_LUNCH_RESO

    CloseSubFrame

    CloseSubFrame

#   CreateLine line \
#message "Perform automated model building"  \
#label "Perform automated model building" \
#widget SHELXE_MODELBUILD

#   OpenSubFrame frame -toggle_display SHELXE_MODELBUILD,$counter open 1

#   OpenSubFrame frame -toggle_display INPUT_PDB,$counter hide  [list ""] 

#   CreateLine line \
#message "Don't use previously created Pdb model " \
#label "Don't use input pdb: " \
#	widget SHELXE_NOUSEPDB

#   CloseSubFrame

    CloseSubFrame

    if { $array(SHELXE_HAND,$counter) == "" } {
	set array(SHELXE_HAND,$counter) 1
    }

    if { $array(SHELXE_DENMOD,$counter) == "" } {
	set array(SHELXE_DENMOD,$counter) 1
    }

#   set array(SHELXE_MODELBUILD,$counter) 1
	
#    if { $array(SHELXE_HCYCLES,$counter) == "" } {
#	set array(SHELXE_HCYCLES,$counter) 5
#    }

#    if { $array(SHELXE_OCYCLES,$counter) == "" } {
#	set array(SHELXE_OCYCLES,$counter) 10
#    }

    if { $array(SHELXE_NCYCLES,$counter) == "" } {
	set array(SHELXE_NCYCLES,$counter) 100
    }

    set array(SHELXE_GENERATE_HEAVY,$counter) 1
}

proc shelxe_plugin_update { arrayname counter } {
}

proc shelxe_setup { } {
}
