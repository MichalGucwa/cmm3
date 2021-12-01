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

proc shelxd_proc { arrayname counter } {
    upvar #0 $arrayname array
    global all_subframes

    foreach subframe $all_subframes {
        trace vdelete array(SHELXD_EXCLUDE_RESO,$counter) w "update_main_scroll $subframe"
    }

    CreateLine line \
	label "SHELXD will be used for substructure determination"

    OpenSubFrame frame -toggle_display SHOW_ALL_PIPELINE_INPUT open 1

    lappend all_subframes $frame
    
    CreateLine line \
	label "Input FA Columns" \
	widget INPUT_FA_COLUMNS -width 55

    CreateLine line \
	label "Input Alpha Columns" \
	widget INPUT_ALPHA_COLUMNS -width 55

    CloseSubFrame

    CreateLine line \
	message "CC/weak threshold after which SHELXD is stopped" \
	label "CC/weak threshold" \
	widget SHELXD_CCWEAK_THRESHOLD \
	message "Minimum number of trials" \
	label "with a minimum number of trials of" \
	widget SHELXD_MIN_TRIALS

    CreateLine line \
	message "Number of trials to perform (NTRY)" \
	label "Num. trials" \
	widget SHELXD_NUM_TRIALS  \
	message "Perform Patterson seeding (PATS)" \
	label "Patterson seeding" \
	widget SHELXD_PATS 

    CreateLine line \
        widget SHELXD_EXCLUDE_RESO \
        label "Input high resolution cut-off" \
        message "Input high resolution cut-off"

    OpenSubFrame frame -toggle_display SHELXD_EXCLUDE_RESO,$counter open 1

    lappend all_subframes $frame

    CreateLine line \
        message "High resolution cutoff" \
        label "High resolution cutoff" \
        widget SHELXD_HIGH_RES_CUTOFF

    CloseSubFrame

    CreateLine line \
	message "Turn off occupancy refinement?  (Reduces memory requirements)" \
	label "Occupancy refinement" \
	widget SHELXD_OCCU_REFINE
	
    CreateLine line \
	message "Minimum distance between atomic pairs - Reduce this to resolve sulphurs in disuphide bonds or atoms in clusters" \
	label "Minimum distance between atoms" \
	widget SHELXD_MIND 
    
    CreateLine line \
	message "Minimum distance between symmetry equivalents - -0.1 allows special positions" \
	label "Minimum distance between symmetry equivalents" \
	widget SHELXD_MDEQ \
	message "Number of sulphurs participating in disulphide bonds in the structure." \
	label "Number of Disulphide Sulphurs?" \
	widget SHELXD_DSUL

	#

    set array(SHELXD_PATS,$counter) 1
    
    if { $array(SHELXD_CCWEAK_THRESHOLD,$counter) == "" } {
	set array(SHELXD_CCWEAK_THRESHOLD,$counter) 30.0
    }

    if { $array(SHELXD_MIN_TRIALS,$counter) == "" } {
	set array(SHELXD_MIN_TRIALS,$counter) 10
    }
	
    if { $array(SHELXD_MIND,$counter) == "" } {
	set array(SHELXD_MIND,$counter) 3.5
    }

    if { $array(SHELXD_MDEQ,$counter) == "" } {
	set array(SHELXD_MDEQ,$counter) -0.1
    }

    if { $array(SHELXD_NUM_TRIALS,$counter) == "" } {
	set array(SHELXD_NUM_TRIALS,$counter) 500
    }
	
}

proc shelxd_plugin_update { arrayname counter } {
}

proc shelxd_setup { } {
}
