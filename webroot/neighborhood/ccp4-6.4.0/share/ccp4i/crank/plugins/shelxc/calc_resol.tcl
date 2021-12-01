#!/usr/bin/env tclsh

set logfile [lindex $argv 0]

if { [file exists $logfile] } {
    set slogfile [open $logfile r]
    set data [read $slogfile]
    set data [split $data "\n"]
    set d 1
    set signal 1

    foreach line $data {
	regsub -all {\s+} $line " " line
	if { ([regexp { Resl. Inf - *([0-9.]*) - *([0-9.]*) - *([0-9.]*) - *([0-9.]*) - *([0-9.]*) - *([0-9.]*) - *([0-9.]*) - *([0-9.]*) - *([0-9.]*) - *([0-9.]*) - *([0-9.]*).*} $line junk reso($d,1) reso($d,2) reso($d,3) reso($d,4) reso($d,5) reso($d,6) reso($d,7) reso($d,8) reso($d,9) reso($d,10) reso($d,11) ]) && ($signal == 1) } {
	    if { $reso($d,10) == "" } {
		puts "error reading resolution"
	    }
	} elseif { ([regexp { Resl. Inf. *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*).*} $line junk reso($d,1) reso($d,2) reso($d,3) reso($d,4) reso($d,5) reso($d,6) reso($d,7) reso($d,8) reso($d,9) reso($d,10) reso($d,11) ]) && ($signal == 1) } {
	    if { $reso($d,10) == "" } {
		puts "error reading resolution"
	    } 
 	} elseif { [regexp {.*<d\"/sig> *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*).*} $line junk sig($d,1) sig($d,2) sig($d,3) sig($d,4) sig($d,5) sig($d,6) sig($d,7) sig($d,8) sig($d,9) sig($d,10) sig($d,11) ] } {
	    if { $sig($d,8) == "" } {
 		puts "error reading signal"
 	    } else {
 		incr d
 	    }
	} elseif { [regexp { Correlation coefficients \(.*} $line junk] } {
	    if { $d < 100 } {
		set d 100
	    } else {
		puts "error - more than 100 data sets!"
	    }
	} elseif { ([regexp { ([A-Z]*)/([A-Z]*) *([-0-9.]*) *([-0-9.]*) *([-0-9.]*) *([-0-9.]*) *([-0-9.]*) *([-0-9.]*) *([-0-9.]*) *([-0-9.]*) *([-0-9.]*) *([-0-9.]*) *([-0-9.]*).*} $line junk label($d,1) label($d,2) correl($d,1) correl($d,2) correl($d,3) correl($d,4) correl($d,5) correl($d,6) correl($d,7) correl($d,8) correl($d,9) correl($d,10) correl($d,11) ]) && ($d >= 100) } {
	    if { $correl($d,10) != "" } {
		incr d
	    }
	} 

    }
    # calculate 0.5 above highest resolution bin
    set hires $reso(1,11)
    for {set i 2} {$i < 10} {incr i} {
	if { [info exists reso($i,11)] } {
	    if { $hires > $reso($i,11) } {
		set hires $reso($i,11)
	    }
	} 
    }

    close $slogfile
    set slogfile [open $logfile a]

    # calculate the highest resolution when correlation is above
    if { [info exists reso(100,1) ] } {
	set lab 100
	set hicor $reso(100,1)
	for {set i 100} {$i < $d} {incr i} {
            set foundreso 0
	    puts $slogfile "\n \$TABLE: Signed anomalous difference correlation between $label($i,1) and $label($i,2)"
	    puts $slogfile "\$GRAPHS: Signed anomalous difference correlation versus resolution :N:2,3:"
	    if { [info exists correl($i,11)] } {
		puts $slogfile "\$\$\n  Bin   Reso    Correlation \$\$\n\$\$"
		for {set j 1} {$j < 12} {incr j} {
		    puts $slogfile [format "%4d   %5.2f      %5.2f    "  $j   $reso(100,$j)    $correl($i,$j) ]
		    if { ($j > 1) } {
			if { ($correl($i,$j) <= 30.0) && ($correl($i,[expr $j-1]) >= 30.0) && !($foundreso) } {
			    set tmp [expr (30 - $correl($i,$j))/($correl($i,$j) - $correl($i,[expr $j-1]))*($reso(100,$j) - $reso(100,[expr $j-1])) + $reso(100,$j)  ]
			    if { ($hicor > $tmp) && ($label($i,1) != "LREM") && ($label($i,2) != "LREM") } {
				set hicor $tmp
				set lab $i
			    }
#			    set foundreso 1
			} elseif { ($correl($i,11) >= 30.0) && ($label($i,1) != "LREM") && ($label($i,2) != "LREM") } {
			    if { $hicor > $reso(100,11) } {
				set hicor $reso(100,11)
				set lab $i
			    }
			}
		    }
		}
		puts $slogfile "\$\$\n"
	    }  
	}
	
	if { $hicor < $reso(100,1) } { 
	    puts $slogfile "\$TEXT:Result: \$\$ Final result \$\$"
	    if { [info exists hicor] } {
		puts $slogfile [format "Resolution when anomalous difference correlation goes under 0.30 is %.2f for data sets $label($lab,1) and $label($lab,2)" $hicor]
	    }
	} 
    }

    puts $slogfile "\$TEXT:Result: \$\$ Final result \$\$"

    if { [info exists hicor] && [info exists reso(100,1)] } {
	if { $hicor < $reso(100,1) } { 
	    puts $slogfile [format "Resolution when anomalous difference correlation goes under 0.30 is %.2f for data sets $label($lab,1) and $label($lab,2)" $hicor]
	}
    } 

    if { [info exists hires] } {
      puts $slogfile "HALF added to the highest resolution limit is [expr $hires + 0.5]"
    }
    puts $slogfile "\$\$"

    close $slogfile

} else {
    puts "logfile not found"
}
