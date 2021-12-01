#
# Copyright (C) Navraj S. Pannu and Steven Ness 2004-2005, Leiden University
# Copyright (C) Navraj S. Pannu 2006-2007, Leiden University
#
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
proc afro_proc { arrayname counter } {
    upvar #0 $arrayname array

    global all_subframes

    foreach subframe $all_subframes {
	trace vdelete array(AFRO_MANUAL_RESO,$counter) w "update_main_scroll $subframe"
	trace vdelete array(AFRO_MANUAL_SIGMAS,$counter) w "update_main_scroll $subframe"
    }

    CreateLine line \
	label "AFRO will be used to determine normalized FA values." 

    OpenSubFrame frame -toggle_display SHOW_ALL_PIPELINE_INPUT open 1

    lappend all_subframes $frame

    CreateLine line \
	label "Input Experimental Columns" \
	widget INPUT_EXPERIMENTAL_COLUMNS -width 55

    CloseSubFrame

   CreateLine line \
	widget AFRO_MANUAL_RESO \
	label "Input high resolution cut-off" \
	message "Input high resolution cut-off - otherwise Afro will automatically set one" 

    OpenSubFrame frame -toggle_display AFRO_MANUAL_RESO,$counter open 1
	
    lappend all_subframes $frame

      CreateLine line \
	label "High resolution cutoff" \
	widget AFRO_HIGH_RES_CUTOFF

    CloseSubFrame

      CreateLine line \
	label "Exclude Reflections : " \
	label "FP < " \
	widget AFRO_SIGF \
	label " *SIGF" 

   CreateLine line \
	widget AFRO_MANUAL_SIGMAS \
	label "Manually set difference sigma cut-offs" \
	message "Afro will automatically choose sigma cut-offs" 

    OpenSubFrame frame -toggle_display AFRO_MANUAL_SIGMAS,$counter open 1
	
    lappend all_subframes $frame

      CreateLine line \
	  label "Exclude Reflections : " \
	  label "DANO < " \
	  widget AFRO_SANO \
	  label " * SANO" 

    CloseSubFrame

    if { $array(AFRO_SIGF,$counter) == "" } {
	set array(AFRO_SIGF,$counter) 2
    }

    if { ($array(AFRO_SANO,$counter) == "") && $array(AFRO_MANUAL_SIGMAS,$counter) } {	
	set array(AFRO_SANO,$counter) 0.5 
    }

}

proc afro_plugin_update { arrayname counter } {
}

proc afro_setup { } {

}
