# $Id: trace.tcl,v 1.8 2010/01/21 16:02:26 rmk65 Exp $
proc f { x n1 n2 op } {
    puts "n1: $n1, n2: $n2, op: $op, x: $x"
}

set x 1

trace variable x w [list f {$x}]
