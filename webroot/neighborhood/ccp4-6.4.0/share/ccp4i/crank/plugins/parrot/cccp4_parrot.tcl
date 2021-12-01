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

proc parrot_proc { arrayname counter } {
    upvar #0 $arrayname array
    global all_subframes

    CreateLine line \
	label "PARROT will be used for density modification"

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
	message "Number of cycles of phase improvement to run." \
	label "Number of cycles of phase improvement" \
 	widget PARROT_NCYCLES

    CreateLine line \
       message "Do not use solvent flattening" \
        label "Do not use solvent flattening" \
        widget PARROT_NOSOLVENT \
        message "Do not use  histogram matching - Useful except in structures with metal clusters" \
        label "Do not use histogram matching" \
        widget PARROT_NOHISTOGRAM 

    CreateLine line \
	message "Do not use non-crystallographic symmetry (NCS) derived from heavy atoms" \
	label "Do not use NCS" \
  	widget PARROT_NONCS     

    CreateLine line \
	message "Phase combination algorithm." \
	label "Phase combination algorithm "\
 	widget PARROT_PHASE_COMB -width 15 

    CreateLine line \
	message "Do not apply bias correction parameter" \
	label "Do not apply bias correction parameter "\
	widget PARROT_BIAS -width 15 
    
    CreateLine line \
	message "Output the Hendrickson-Lattman coefficients from the input phasing program" \
	label "Output HL coefficients from input phasing program" \
 	widget PARROT_HLOUTPUT

    CreateLine line \
	message "Keep intermediate cycle files"  \
	label "Keep intermediate cycle files" \
	widget PARROT_KEEPMTZ

    # Set basic defaults

    if { $array(PARROT_NCYCLES,$counter) == "" } {
	set array(PARROT_NCYCLES,$counter) 20
    }
}

proc parrot_plugin_update { arrayname counter } {
}

proc parrot_setup { } {
    global programs_toggleframe_list

    # Append the DefineMenu items that follow to the list of variables
    # passed to the Program palette CreateToggleFrame function.
    lappend programs_toggleframe_list "PARROT_PHASE_COMB" 

    DefineMenu _parrot_phase_comb [list "MLHL" "DIRECT" ] \
  	[list MLHL DIRECT]
}
