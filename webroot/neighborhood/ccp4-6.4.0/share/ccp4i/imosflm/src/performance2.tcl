# $Id: performance2.tcl,v 1.8 2010/01/21 16:02:25 rmk65 Exp $
package provide performance 2.0

rename body _body

# proc body {name arglist body} {
# #    puts "New body: [concat "body_start ;" [regsub -all {([^\"])return} $body "\1body_end ; return"] "; body_end" ]"
#     uplevel \#0 [list _body $name $arglist [concat "body_start ;" [regsub -all {(\s)return(\s)} $body {\1body_end ; return\2}] "; body_end"]]
# }

proc body {name arglist body} {
 #    puts "Gonna define body as:"
#     puts ""
#     puts [list _body $name $arglist [concat "body_start ;" "set status \[catch [list $body] msg\]" "; body_end" "; return -code \$status -errorcode \$::errorCode -errorinfo \$::errorInfo \$msg"]]
#     puts ""

# exit

    uplevel \#0 [list _body $name $arglist [concat "body_start ;" "::set status \[catch [list $body] msg\]" "; body_end" "; return -code \$status -errorcode \$::errorCode -errorinfo \$::errorInfo \$msg"]]
}

proc body_start { } {
    uplevel 1 {
	::set level [info level]
	::set ::t0($level) [clock clicks -milli]
    }
}

proc body_end { } {
    uplevel 1 {
	::set level [info level]
	if {[info exists ::t0($level)]} {
	    ::set ::t1($level) [clock clicks -milli]
	    if {[info exists this]} {
		::set l_method [$this info class]::[lindex [info level 0] 0]
	    } else {
		::set l_method ::[lindex [info level 0] 0]
	    }
	    ::set l_duration [expr $::t1($level) - $::t0($level)]
	    array unset ::t0($level)
	    if {[info exists ::perf_count($l_method)]} {
		incr ::perf_count($l_method)
		::set ::perf_mean($l_method) \
		    [expr ($::perf_mean($l_method) * ($::perf_count($l_method)-1.0) / $::perf_count($l_method)) + (double($l_duration) / $::perf_count($l_method))]
	    } else {
		::set ::perf_count($l_method) 1
		::set ::perf_mean($l_method) $l_duration
	    }
	}
    }
}

proc perf { { a_sort "time" } } {
    set l_methods [array names ::perf_count]
    set l_methods [lsort -command "perf_sort_$a_sort" $l_methods]
    foreach i_method $l_methods {
	puts "$i_method[string repeat "." [expr 50 - [string length $i_method]]][format %7.0f $::perf_count($i_method)] [format %7.0f $::perf_mean($i_method)]"
    }
}

proc perf_sort_mean { a b } {
    if { $::perf_mean($a) < $::perf_mean($b) } {
	return -1
    } elseif { $::perf_mean($a) > $::perf_mean($b) } {
	return +1
    } else {
	return 0
    }
}

proc perf_sort_count { a b } {
    if { $::perf_count($a) < $::perf_count($b) } {
	return -1
    } elseif { $::perf_count($a) > $::perf_count($b) } {
	return +1
    } else {
	return 0
    }
}

proc perf_sort_time { a b } {
    set a_time [expr $::perf_count($a) * $::perf_mean($a)]
    set b_time [expr $::perf_count($b) * $::perf_mean($b)]
    if { $a_time < $b_time } {
	return -1
    } elseif { $a_time > $b_time } {
	return +1
    } else {
	return 0
    }
}

proc perfx { name } {
    set ::t0($name) [clock clicks -milli]
}

proc perfy { name } {
    set ::t1($name) [clock clicks -milli]
    set l_duration [expr $::t1($name) - $::t0($name)]
    if {[info exists ::perf_count($name)]} {
	incr ::perf_count($name)
	set ::perf_mean($name) \
	    [expr ($::perf_mean($name) * ($::perf_count($name)-1.0) / $::perf_count($name)) + (double($l_duration) / $::perf_count($name))]
    } else {
	set ::perf_count($name) 1
	set ::perf_mean($name) $l_duration
    }
}

