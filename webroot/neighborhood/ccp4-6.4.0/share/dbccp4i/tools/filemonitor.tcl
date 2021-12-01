#! tclsh
#
# Filemonitor
# Watches one or more files and reports when each is modified,
# created or removed.
# The files don't have to exist when the monitoring begins.
#
if { [llength $argv] < 1 } {
    puts "Usage: tclsh filemonitor.tcl <file1> \[ <file2> \[ ... \] \]"
    exit 0
}
set files {}
foreach arg $argv {
    if { ![file exists $arg] } {
	puts "Warning: no file \"$arg\""
    }
    lappend files $arg
}
puts "Watching the following files:"
set mtimes {}
foreach filen $files {
    if { [file exists $filen] } {	
	puts "\t$filen"
	lappend mtimes [file mtime $filen]
    } else {	
	puts "\t$filen (not found)"
	lappend mtimes -1
    }
}
puts "\nStarted at [clock format [clock seconds] -format %c]"
set running 1
while $running {
    after 100
    for { set i 0 } { $i < [llength $files] } { incr i } {
	set filen [lindex $files $i]
	set mtime [lindex $mtimes $i]
	if { $mtime < 0 } {
	    if { [file exists $filen] } {
		set mtime [file mtime $filen]
		puts "[clock format $mtime -format %c]: created $filen"
	    }
	} else {
	    if { ![file exists $filen] } {
		set mtime -1
		puts "[clock format [clock seconds] -format %c]: removed $filen"
	    } elseif { [file mtime $filen] > $mtime } {
		set mtime [file mtime $filen]
		puts "[clock format $mtime -format %c]: updated $filen"
	    }
	}
	set mtimes [lreplace $mtimes $i $i $mtime]
    }
}
