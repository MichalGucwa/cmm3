#!/usr/bin/env tclsh

# Copyright (C) Navraj S. Pannu 2007, Leiden University
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

set anomalous       [lindex $argv 0]
set mtz2hklcommand  [lindex $argv 1]
set inputmtz        [lindex $argv 2]
set output          [lindex $argv 3]
set fp              [lindex $argv 4]
set sigfp           [lindex $argv 5]

if { $anomalous == "0" } { 

    set mtz_script "XTAL xtal1\n DNAME data1 \n COLUmn F=$fp SF=$sigfp\nOUTH\nOUTPut $output\nEND\n"

    set command "$mtz2hklcommand HKLIN $inputmtz << \"$mtz_script\""
    catch {eval exec $command } output 
    puts $output

} else {
    set fm        [lindex $argv 6]
    set sigfm     [lindex $argv 7]

    set mtz_script "XTAL xtal1\n DNAME data1 \n COLUmn F+=$fp SF+=$sigfp F-=$fm SF-=$sigfm\nOUTH\nOUTPut $output\nEND\n"

    set command "$mtz2hklcommand HKLIN $inputmtz << \"$mtz_script\""
    catch {eval exec $command } output 
    puts $output
}
