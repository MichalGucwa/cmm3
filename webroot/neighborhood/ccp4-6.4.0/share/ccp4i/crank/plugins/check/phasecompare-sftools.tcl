#!/usr/bin/env tclsh
#
# Copyright (C) Navraj S. Pannu 2006, Leiden University
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

proc ComparePhases { mtz_1 f_1 phi_1 mtz_2 f_2 phi_2 fom_2 type } {

# make fb = fom_2 * f_2
    set sftools_script "read $mtz_2\n calc F col FB = col $f_2 col $fom_2 * \nread $mtz_1\n"
    set sftools_script "$sftools_script  map correl FB $phi_2 $f_1 $phi_1\nphashft col $phi_2 $phi_1\nquit\ny\n"
    set command "sftools << \"$sftools_script\" "
    catch {eval exec $command } output
    set logfile [open "check-logfile" a]
    puts $logfile $output
    close $logfile
}

set mtz_1        [lindex $argv 0]
set f_1          [lindex $argv 1]
set phi_1        [lindex $argv 2]
set mtz_2        [lindex $argv 3]
set f_2          [lindex $argv 4]
set phi_2        [lindex $argv 5]
set fom_2        [lindex $argv 6]
set type         [lindex $argv 7]

ComparePhases $mtz_1 $f_1 $phi_1 $mtz_2 $f_2 $phi_2 $fom_2 $type
