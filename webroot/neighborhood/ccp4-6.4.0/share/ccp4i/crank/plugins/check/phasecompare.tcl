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

proc ComparePhases { mtz_1 f_1 phi_1 mtz_2 f_2 sigf_2 phi_2 fom_2 type no_trans } {

# make fb = fom_2 * f_2
    set sftools_script "read $mtz_2\n calc F col FB = col $f_2 col $fom_2 * \nread $mtz_1\nwrite temp.mtz\nquit\n"
    set command "sftools << \"$sftools_script\" "
    catch {eval exec $command } output
    # puts $output

    set scr [open "cphasematch-${type}.com" w+]

    puts $scr "cphasematch -stdin << end-cphasematch >> check-logfile\n"
    puts $scr "mtzin temp.mtz\n"
    puts $scr "colin-fo /*/*/\[$f_2,$sigf_2\]"
    puts $scr "colin-fc-1 /*/*/\[$f_1,$phi_1\]"
    puts $scr "colin-fc-2 /*/*/\[FB,$phi_2\]"
    puts $scr "resolution-bins 12"
#    if { $no_trans} {
#	puts $scr "no_origin_match"
#    }
    puts $scr "end-cphasematch"
    flush $scr
    close $scr
}

set mtz_1        [lindex $argv 0]
set f_1          [lindex $argv 1]
set phi_1        [lindex $argv 2]
set mtz_2        [lindex $argv 3]
set f_2          [lindex $argv 4]
set sigf_2       [lindex $argv 5]
set phi_2        [lindex $argv 6]
set fom_2        [lindex $argv 7]
set type         [lindex $argv 8]
set no_trans     [lindex $argv 9]


ComparePhases $mtz_1 $f_1 $phi_1 $mtz_2 $f_2 $sigf_2 $phi_2 $fom_2 $type $no_trans
