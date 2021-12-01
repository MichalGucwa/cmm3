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

proc SubstructureCompare { crankplugins final_sub model_sub sitcom } {
    global XMLParse

    set finalsubnum 0

    set fpdb1 [open $final_sub r]
    set fpdb [open "final_sub.pdb" w]
    set frac [open "final_sub.frac" w]
    set data [read $fpdb1]
    set data [split $data "\n"]
    set oldnumber 0
    set fracx 0.0000
    set fracy 0.0000
    set fracz 0.0000

    foreach line $data {
	if { [read_pdb_atom_line $line number2 atom x y z occ bfac] } {
	    if { $number2 != $oldnumber } {
		incr finalsubnum
		write_pdb_atom_line $fpdb $number2 $atom $finalsubnum $x $y $z $occ $bfac
		orth2frac $x $y $z fracx fracy fracz
		puts $frac [format "%2s  %8.3f%8.3f%8.3f" $atom $fracx $fracy $fracz]  
	    }
	    set oldnumber $number2
	} else {
	    puts $fpdb $line
	}
    }

    close $frac
    close $fpdb
    close $fpdb1

    set foundsubnum 0
    set foundrms 0
    set gottrans 0

    if { $sitcom } {
	# see if sitcom exists
	set command "sitcom -help"
	catch {eval exec $command } output
	set err [lindex $::errorCode 0]
	if { !([string compare $err "POSIX"] == 0) } {
	    set sg $XMLParse([join "crank parameters input_spacegroup number" __])
	    runcommand [concat sitcom $model_sub "final_sub.pdb"  -sg  $sg > sitcom-logfile] 0
	    set logfile1 [open "sitcom-logfile" r]
	    set data [read $logfile1]
	    set data [split $data "\n"]
	    set hits 0
	    foreach line $data {
		regsub -all {\s+} $line " " line
		if { [regexp       {.*HITS TO REFERENCE: ......... ([0-9]*).*} $line junk numb] } {
		    if { ($numb        >= 0) } { 
			if { ($hits    >  0) } {
			    if { $numb > $foundsubnum } {
				set foundsubnum $numb
			    }
			}
			incr hits
		    }
		} 
		if { [regexp       {.*RMS DISTANCE: .............. ([0-9.]*).*} $line junk rms] } {
		    if { ($rms > 0) } {
			set foundrms $rms
		    }
		}
		if { [regexp       {.*TRANSLATION:.* } $line junk] } {
		    if { $hits > 0 } { 
			if { [regexp { .* ([-0-9.]*), ([-0-9.]*), ([-0-9.]*) .*} $line junk xx yy zz] } {
			    if { ($xx != "") && ($yy != "") && ($zz != "") } {
				set ftrans [open "translation-sub.txt" a+]
				puts $ftrans [format " %8.3f %8.3f %8.3f " $xx $yy $zz]
				close $ftrans
				set gottrans 1
			    }
			}
		    }
		}

	    }
	    close $logfile1
	}
    } else {
	# use emma
	# make model_sub.frac
	set fpdb [open $model_sub r]
	set frac [open "model_sub.frac" w]
	set data [read $fpdb]
	set data [split $data "\n"]
	set oldnumber 0
	set fracx 0.0000
	set fracy 0.0000
	set fracz 0.0000

	set i 0
	foreach line $data {
	    if { [read_pdb_atom_line $line number2 atom x y z occ bfac] } {
		if { $number2 != $oldnumber } {
		    orth2frac $x $y $z fracx fracy fracz
		    incr i
		    puts $frac [format "%2s  %8.3f%8.3f%8.3f" $atom $fracx $fracy $fracz]  
		}
		set oldnumber $number2
	    } 
	}
	close $frac
	close $fpdb

	set c $XMLParse([join "crank parameters ref_crystal" __])
	set aa $XMLParse([join "crank parameters crystal=$c cell cell_a" __]) 
	set bb $XMLParse([join "crank parameters crystal=$c cell cell_b" __]) 
	set cc $XMLParse([join "crank parameters crystal=$c cell cell_c" __])
	set alpha $XMLParse([join "crank parameters crystal=$c cell cell_alpha" __])
	set beta  $XMLParse([join "crank parameters crystal=$c cell cell_beta" __])
	set gamma $XMLParse([join "crank parameters crystal=$c cell cell_gamma" __])
	set cell "$aa  $bb  $cc  $alpha  $beta  $gamma"

	runcommand [concat [file join $crankplugins check emma-compare.py] \"$cell\" \"$XMLParse([join "crank parameters input_spacegroup name" __])\" model_sub.frac final_sub.frac > emma-logfile] 0    

	set logfile1 [open "emma-logfile" r]
	set data [read $logfile1]
	set data [split $data "\n"]
	# set foundsubnum foundrms
	foreach line $data {
	    regsub -all {\s+} $line " " line
	    if { [regexp       {.*Pairs: ([0-9]*).*} $line junk numb] } {
		if { ($numb >= 0) } { 
		    set foundsubnum $numb
		}
	    } 
	    if { [regexp       {.*rms coordinate differences: ([0-9.]*).*} $line junk rms] } {
		if { ($rms > 0) } {
		    set foundrms $rms
		}
	    }
	    if { [regexp       {.*translation: \(([\d\.e\-]+)\,\s*([\d\.e\-]+)\,\s*([\d\.e\-]+)\)} $line junk x y z] } {
		if { [info exists x] && [info exists y] && [info exists z] } {
		    set femma [open "translation-sub.txt" a+]
		    puts $femma [format " %8.3f %8.3f %8.3f " $x $y $z]
		    close $femma
		    set gottrans 1
		}
	    }    
	}
	close $logfile1
    }
	 
    set output [open "check-logfile" a+]
    puts $output "Number of substructure atoms in final substructure pdb: $finalsubnum\n"
    if { $finalsubnum > 0 } {
	puts $output "Fraction of substructure found [expr double($foundsubnum) / double($finalsubnum)]\n"
	
 	if { $foundrms > 0 } {
	    puts $output "RMS of substructure found: $foundrms\n"
	}
#	if { $gottrans } {
#	    puts $output "Using translation vector from substructure detection program\n"
#	}
    }
    close $output

    # Look at all crunch2 trials and see % successful solution

    for { set istep 1 } { [info exists XMLParse(crank__soap__run__step=$istep)] } { incr istep } {
	set program [string tolower $XMLParse([join "crank soap run step=$istep name" __])]
	if { $program == "crunch2" } {
	    set output [open "check-logfile" a+]
	    set correct 0
	    set total 0

	    for { set i 1 } { [file exists [file join .. $istep-crunch2 trial${i}a.pdb]] } { incr i } {
		if { $sitcom } {

		    runcommand [concat sitcom  [file join .. $istep-crunch2 trial${i}a.pdb] "final_sub.pdb" -sg $XMLParse([join "crank parameters input_spacegroup number" __]) > sitcom-crunch2-logfile${i} ] 0
		    incr total
		    set logfile1 [open "sitcom-crunch2-logfile${i}" r]
		    set data [read $logfile1]
		    set data [split $data "\n"]
	    
		    set hits 0
		    set foundsubnum 0
		    set foundrms 0

		    foreach line $data {
			regsub -all {\s+} $line " " line
			if { [regexp       {.*HITS TO REFERENCE: ......... ([0-9]*).*} $line junk numb] } {
			    if { ($numb >= 0) } { 
				if { ($hits > 0) } {
				    if { $numb > $foundsubnum } {
					set foundsubnum $numb
				    }
				}
				incr hits
			    }
			}  
			if { [regexp       {.*RMS DISTANCE: .............. ([0-9.]*).*} $line junk rms] } {
			    if { ($rms > 0) } {
				set foundrms $rms
			    }
			}
		    }
 		    close $logfile1
		} else {
		    if { [file exists ../$istep-crunch2/trial${i}a.XYZ] } {
			incr total
			set c $XMLParse([join "crank parameters ref_crystal" __])
			set aa $XMLParse([join "crank parameters crystal=$c cell cell_a" __]) 
			set bb $XMLParse([join "crank parameters crystal=$c cell cell_b" __]) 
			set cc $XMLParse([join "crank parameters crystal=$c cell cell_c" __])
			set alpha $XMLParse([join "crank parameters crystal=$c cell cell_alpha" __])
			set beta  $XMLParse([join "crank parameters crystal=$c cell cell_beta" __])
			set gamma $XMLParse([join "crank parameters crystal=$c cell cell_gamma" __])
			set cell "$aa  $bb  $cc  $alpha  $beta  $gamma"

			runcommand [concat [file join $crankplugins check emma-compare.py] \"$cell\" \"$XMLParse([join "crank parameters input_spacegroup name" __])\" final_sub.frac [file join .. $istep-crunch2 trial${i}a.XYZ] > emma-crunch2-logfile${i}] 0    

			set logfile1 [open "emma-crunch2-logfile${i}" r]
			set data [read $logfile1]
			set data [split $data "\n"]
			# set foundsubnum foundrms
			foreach line $data {
			    regsub -all {\s+} $line " " line
			    if { [regexp       {.*Pairs: ([0-9]*).*} $line junk numb] } {
				if { ($numb >= 0) } { 
				    set foundsubnum $numb
				}
			    } 
			    if { [regexp       {.*rms coordinate differences: ([0-9.]*).*} $line junk rms] } {
				if { ($rms > 0) } {
				    set foundrms $rms
				}
			    }
			}
			close $logfile1
		    }
		}

		#   puts $output "Number of substructure atoms in final substructure pdb: $finalsubnum\n"
		if { $finalsubnum > 0 } {
		    puts $output [format "Trial $i: Fraction of substructure found %.3f\n" [expr double($foundsubnum) / double($finalsubnum)]]
		    if { [expr double($foundsubnum) / double($finalsubnum)] >= 0.5 } {
			incr correct
		    }
		    if { [info exists foundrms] } {
			puts $output [format "Trial $i: RMS of substructure found: %.3f\n" $foundrms]
		    }
		}
	    }
	    puts $output [format "Fraction of trials that found equal to or greater than 0.5 of total substructure: %.3f\n" [expr double($correct) / double($total)]] 
	    close $output
	}
    }
}

set inputxml      [lindex $argv 0]
set crankbin      [lindex $argv 1]
set crankplugins  [lindex $argv 2]
set final_sub     [lindex $argv 3]
set model_sub     [lindex $argv 4]
set sitcom        [lindex $argv 5]

source [file join $crankbin crankutils.tcl]

if { [file exists $inputxml] == 0 } {
    crank_error "substructurecompare.tcl::inputxml file does not exist"
}

XMLParsefile $inputxml

SubstructureCompare $crankplugins $final_sub $model_sub $sitcom
