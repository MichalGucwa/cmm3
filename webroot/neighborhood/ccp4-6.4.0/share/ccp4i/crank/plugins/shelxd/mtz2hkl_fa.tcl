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
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA#

set inputmtz [lindex $argv 0]
set output   [lindex $argv 1]
set fa       [lindex $argv 2]
set sigfa    [lindex $argv 3]
set alpha    [lindex $argv 4]

set args   "HKLIN $inputmtz HKLOUT $output"
set script "LABIN FP=$fa SIGFP=$sigfa IDUM1=$alpha\n OUTPUT USER '(3I4,2F8.2,I4)'\n"

set command "mtz2various $args << \"$script\""
#puts $command
catch {eval exec $command } output 
puts $output

