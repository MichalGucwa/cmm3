#
# Copyright (C) Navraj S. Pannu 2006-2009, Leiden University
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

proc GetTranslation { step tag final_pdb } {
    global XMLParse
    
    if { [file exists [file join .. workdb crank.in.$tag.mtz] ] } {
        if { [info exists XMLParse([join "crank soap run step=$step input phase_columns f" __])] } {

            set in_f $XMLParse([join "crank soap run step=$step input phase_columns f" __])
            set in_sigf $XMLParse([join "crank soap run step=$step input phase_columns sigf" __])
            set in_phib $XMLParse([join "crank soap run step=$step input phase_columns phib" __])
            set in_fom $XMLParse([join "crank soap run step=$step input phase_columns fom" __])

	    set sfall_script "mode sfcalc xyzin hklin\nlabin FP = $in_f SIGFP = $in_sigf\n"
	    set sfall_script "$sfall_script labout FC=FC PHIC=PHIC\n"
	    set command "sfall XYZIN $final_pdb HKLIN [file join .. workdb crank.in.$tag.mtz] HKLOUT temp1.mtz << \"$sfall_script\" "
	    catch {eval exec $command } output
#	    puts $output

	    set sftools_script "read temp1.mtz\nwrite temp2.mtz col FC PHIC\nquit\n"
	    set command "sftools << \"$sftools_script\" "
	    catch {eval exec $command } output
#	    puts $output

	    file delete temp1.mtz
	
	    set sftools_script "read [file join .. workdb crank.in.$tag.mtz]\n calc F col FB = col $in_f col $in_fom * \nread temp2.mtz\nwrite temp.mtz\nquit\n"
	    set command "sftools << \"$sftools_script\" "
	    catch {eval exec $command } output
#	    puts $output

	    file delete temp2.mtz

	    set script "start -mtzin temp.mtz -colin-fo /*/*/\\\[$in_f,$in_sigf\\\] -colin-fc-1 /*/*/\\\[FB,$in_phib\\\] -colin-fc-2 /*/*/\\\[FC,PHIC\\\]"
	    set command "cphasematch <<$script > translation-logfile"
#	    puts $script
	    catch {eval exec $command} output
#	    puts $output
	   
	    set log [open "translation-logfile" r]
	    set data [read $log]
	    set data [split $data "\n"]	    

	    foreach line $data {
		if { [regexp {.*Change or origin\: uvw = \( *([-0-9.]*), *([-0-9.]*), *([-0-9.]*).*} $line junk xx yy zz] } {
		    if { [info exists xx] && [info exists yy] && [info exists zz] } {

# compare with substructure translation
			if { [file exists translation-sub.txt] } {
			    set logfile1 [open "translation-sub.txt" r]
			    set data [read $logfile1]
			    set data [split $data "\n"]	    

			    set x ""
			    set y ""
			    set z ""

			    foreach line $data {
				regsub -all {\s+} $line " " line
				if { [regexp {.* ([-0-9.]*) ([-0-9.]*) ([-0-9.]*) .*} $line junk x y z] } {
				    break
				}
			    }
			    close $logfile1
			    if { ($x != "") && ($y != "") && ($z != "") } {
				    set logfile [open "check-logfile" a+]
				# turn negative into positive in order to compare properly
				if {$x<0} {set x [expr $x+1.]}
				if {$y<0} {set y [expr $y+1.]}
				if {$z<0} {set z [expr $z+1.]}
				if {$xx<0} {set xx [expr $xx+1.]}
				if {$yy<0} {set yy [expr $yy+1.]}
				if {$zz<0} {set zz [expr $zz+1.]}
				if { [expr sqrt( pow($x - $xx, 2) + pow($y - $yy, 2) + pow($z - $zz, 2) ) ] > 0.1 } {
				    puts $logfile "\nTranslation vector from sitcom/emma and cphasematch disagree\n"
				}
				puts $logfile [format "Translation vector from sitcom:      %8.3f %8.3f %8.3f\n" $x $y $z]
				puts $logfile [format "Translation vector from cphasematch: %8.3f %8.3f %8.3f\n" $xx $yy $zz]
				close $logfile
			    }
			}			

			set ftrans [open "translation-cphasematch.txt" a+]
			puts $ftrans [format " %8.3f %8.3f %8.3f " $xx $yy $zz]
			close $ftrans
		    }
		}
	    }
	    close $log
	    file delete temp.mtz
 	}
    }
}

set inputxml  [lindex $argv 0]
set crankbin  [lindex $argv 1]
set step      [lindex $argv 2]
set tag       [lindex $argv 3]
set final_pdb [lindex $argv 4]

source [file join $crankbin crankutils.tcl]

if { [file exists $inputxml] == 0 } {
    crank_error "gettranslation.tcl::inputxml file does not exist"
}

XMLParsefile $inputxml

GetTranslation $step $tag $final_pdb
