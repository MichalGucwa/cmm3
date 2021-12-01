#!/usr/bin/env tclsh

# Copyright (C) Navraj S. Pannu 2006,  Leiden University
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

set inputmtz [lindex $argv 0]
set output   [lindex $argv 1]
set f        [lindex $argv 2]
set sigf     [lindex $argv 3]
set e        [lindex $argv 4]
set sige     [lindex $argv 5]


set sftools_script "read $inputmtz\n write $output format(3I5,2F9.2,2F9.3) col $f $sigf $e $sige\n"
set sftools_script "$sftools_script quit\n"

set command "sftools << \"$sftools_script\""
#puts $command
catch {eval exec $command } output 
#puts $output


