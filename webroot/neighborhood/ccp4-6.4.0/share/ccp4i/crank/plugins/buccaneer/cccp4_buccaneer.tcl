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

proc buccaneer_proc { arrayname counter } {
    upvar #0 $arrayname array
    global all_subframes

    foreach subframe $all_subframes {
	trace vdelete array(BUCCANEER_PHASE_RESTRAIN,$counter) w "update_main_scroll $subframe"
	trace vdelete array(INPUT_PDB,$counter) w "update_main_scroll $subframe"
 	trace vdelete array(BUCCANEER_NOUSEFREER,$counter) w "update_main_scroll $subframe"
    }

    CreateLine line \
	label "BUCCANEER will be used for model building"

    OpenSubFrame frame -toggle_display SHOW_ALL_PIPELINE_INPUT open 1

    lappend all_subframes $frame

    CreateLine line \
	label "Input Experimental Columns" \
	widget INPUT_EXPERIMENTAL_COLUMNS -width 55

    CreateLine line \
	label "Input HL Columns" \
	widget INPUT_HL_COLUMNS -width 55	
    

    OpenSubFrame frame -toggle_display BUCCANEER_NOUSEFREER,$counter open 0

    CreateLine line \
	label "Input FreeR Columns" \
	widget INPUT_FREER_COLUMNS -width 55
	 
    CloseSubFrame

    OpenSubFrame frame -toggle_display INPUT_PDB,$counter hide [list ""]

    CreateLine line \
	label "Input Pdb" \
	widget INPUT_PDB -width 55
	 
    CloseSubFrame

    OpenSubFrame frame -toggle_display BUCCANEER_PHASE_RESTRAIN,$counter open DIRECT

    CreateLine line \
	  label "Input Substructure" \
	  widget INPUT_SUBSTRUCTURE -width 25

    CloseSubFrame

    CloseSubFrame

#    CreateLine line \
#	message "Fast build only - no recycling with refmac " \
#	label "Fast build only: " \
# 	widget BUCCANEER_FASTBUILD

    CreateLine line \
	message "Don't use Free-R flag " \
	label "Don't use Free-R flag: " \
 	widget BUCCANEER_NOUSEFREER

    OpenSubFrame frame -toggle_display INPUT_PDB,$counter hide  [list ""] 

    CreateLine line \
	message "Don't use previously created Pdb model " \
	label "Don't use input pdb: " \
 	widget BUCCANEER_NOUSEPDB

    CloseSubFrame

    CreateLine line \
	message "Number of fragments to build per 100 residues " \
	label "Number of fragments to build per 100 residues: " \
 	widget BUCCANEER_FRAGMENTS 

    CreateLine line \
	message "Number of cycles of building/refinement to run " \
	label "Number of cycles of building/refinement to run: " \
 	widget BUCCANEER_NUMCYCLES

    CreateLine line \
	message "Number of internal cycles of building to run in first macro-cycle" \
	label "Number of internal cycles of building to run in the first macro-cycle" \
 	widget BUCCANEER_INITIALCYCLES 

    CreateLine line \
	message "Number of internal cycles of building to run in later macro-cycles" \
	label "and subsequent macro-cycles: " \
 	widget BUCCANEER_SUBSEQUENTCYCLES 
    
    CreateLine line \
	message "Sequence docking reliability index" \
	label "Assign sequence with a reliability fraction of " \
 	widget BUCCANEER_SEQMATCH \

     CreateLine line \
 	message "Choose if phase restraints will be used in Refmac." \
 	label "Include "\
 	widget BUCCANEER_PHASE_RESTRAIN -width 15 \
 	label "phase restraints in Refmac"

    # Set basic defaults

    if { $array(BUCCANEER_FRAGMENTS,$counter) == "" } {
	set array(BUCCANEER_FRAGMENTS,$counter) 20
    }

    if { $array(BUCCANEER_NUMCYCLES,$counter) == "" } {
	set array(BUCCANEER_NUMCYCLES,$counter) 3
    }

    if { $array(BUCCANEER_INITIALCYCLES,$counter) == "" } {
	set array(BUCCANEER_INITIALCYCLES,$counter) 3
    }

    if { $array(BUCCANEER_SUBSEQUENTCYCLES,$counter) == "" } {
	set array(BUCCANEER_SUBSEQUENTCYCLES,$counter) 1
    }

     if { $array(BUCCANEER_SEQMATCH,$counter) == "" } {
 	set array(BUCCANEER_SEQMATCH,$counter) 0.95
     }

}

proc buccaneer_plugin_update { arrayname counter } {
}

proc buccaneer_setup { } {
    global programs_toggleframe_list

    # Append the DefineMenu items that follow to the list of variables
    # passed to the Program palette CreateToggleFrame function.
    lappend programs_toggleframe_list "BUCCANEER_PHASE_RESTRAIN"

    DefineMenu _buccaneer_phase_restrain [list NO MLHL DIRECT]

}
