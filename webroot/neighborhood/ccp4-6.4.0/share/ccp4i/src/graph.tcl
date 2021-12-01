#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - graph.tcl
#
#
#
# Generate simple graphs on a canvas.
# For use when you don't have BLT.
#
# From Mike Hartshorn May 97
#
#====================================================================

#CCP4i_cvs_Id $Id$

#---------------------------------------------------------------------------
proc SimpleGraph { w graph_id args } {
#---------------------------------------------------------------------------

  global graph

  set nargs [llength $args ]

  set n -1

  if { ![winfo exists $w ] } {
    OpenWindow $w "Graphs"  "Graphs" 
    wm resizable $w
    frame $w.main
    pack $w.main -side top -fill x
    scrolled_frame $w.main {
    }
  }
  set ww $w.main.canvas.contents

  set c [canvas $ww.$graph_id \
    -borderw 0 -highlightth 0 -width 400 -height 300 ]
  pack $c -expand yes -fill both
  Graph $ww.$graph_id initialise

  while { $n < $nargs } {
    incr n
    set argument [lindex $args $n ]

    if { $argument == "-xdata" } {
      incr n; set set_no [lindex $args $n ]
      incr n; set graph($ww.$graph_id,xdata) [lindex $args $n ]
    } elseif { $argument == "-ydata" } {
#      incr n; set set_no [lindex $args $n ]
      incr n; set  graph($ww.$graph_id,ydata) [lindex $args $n ]
      set  graph($ww.$graph_id,nvalues) [llength $graph($ww.$graph_id,ydata)]
    } else  {
      incr n
      set graph($ww.$graph_id,[string range $argument 1 end]) [lindex $args $n]
    }
  }

  Graph $c plot

  update_main_scroll $w

  bind Canvas <1> {
   %W postscript -file xxx%W.ps
  }

}


proc NiceNum {x round} {
   set x	[expr {double($x)}]

   set exp	[expr {floor(log10($x))}]
   set p [expr {pow(10., $exp)} ]
   if { $p == 0 } {
     set f $x
   } else {
     set f	[expr {$x / $p} ]
   }

   if { $round } {
      if { $f < 1.5 } {
	 set nf 1.
      } elseif { $f < 3. } {
	 set nf 2.
      } elseif { $f < 7. } {
	 set nf 5.
      } else {
	 set nf 10.
      }
   } else {
      if { $f <= 1. } {
	 set nf 1.
      } elseif { $f <= 2. } {
	 set nf 2.
      } elseif { $f <= 5. } {
	 set nf 5.
      } else {
	 set nf 10.
      }
   }

   return [expr {$nf * pow(10., $exp)}]
}

proc LooseLabels {min max {ntick 5}} {
   #
   # Generate loose labels for a range of numbers.
   # min - minimum value of numbers.
   # max - maximum value of numbers.
   #
   # Graphics Gems pg 61-63

   set range	[NiceNum [expr {$max - $min}] 0]
   set d	[NiceNum [expr {$range / ($ntick - 1)}] 1]

   set gmin 	[expr {floor($min / $d) * $d}]
   set gmax 	[expr {ceil($max / $d) * $d}]

   set nfrac	[expr {-floor(log10($d))}]

   if { $nfrac < 0. } {
      set nfrac 0
   }

   set nfrac [expr {int($nfrac)}]

   set labels ""

   for {set x $gmin} {$x < [expr {$gmax + 0.5 * $d}] } {set x [expr {$x + $d}]} {
      if { $x <= $max && $x >= $min } {

	 if { $nfrac == 0 } {
	    lappend labels [format "%.4g" $x]
	 } else {
	    lappend labels [format "%.${nfrac}f" $x]
	 }
      }
   }

   return $labels
}

proc AddMarker {c yval x y} {
   $c itemconfigure current -fill cyan
   $c create text [$c canvasx $x] [expr {[$c canvasy $y] - 1}]\
       -text $yval -tags val -anchor s
}


proc AddBar {c x y} {

   global graph

   set x0 [x2c $c $x]

   set y0 [y2c $c $y]

   set y1 [y2c $c 0.0]

   if { abs($y0 - $y1) < 1.0 } {
      set fill black
      set id [$c create line \
		  [expr {$x0 - $graph($c,xstep) * $graph($c,barwidth)}] $y1 \
		  [expr {$x0 + $graph($c,xstep) * $graph($c,barwidth)}] $y1]
   } else {
      set fill $graph($c,barcolour)

      set id [$c create rectangle \
		  [expr {$x0 - $graph($c,xstep) * $graph($c,barwidth)}] $y0 \
		  [expr {$x0 + $graph($c,xstep) * $graph($c,barwidth)}] $y1]
   }

   $c itemconfigure $id -fill $fill

   $c bind $id <Enter> "AddMarker %W $y %x %y"

   $c bind $id <Leave> "%W itemconfigure current -fill $fill; %W delete val"
}

proc y2c {c y} {
   #
   # Convert a real space y-coordinate to a canvas graph
   # space coordinate.
   #
   # c - the canvas.
   # y - the y-coordinate.

   global graph

   set y0 [expr {($y - $graph($c,ymin)) / double($graph($c,yrange))}]
   set y0 [expr {($y0 * $graph($c,yplot)) + $graph($c,yborder)}]
   set y0 [expr {$graph($c,height) - $y0}]

   return $y0
}

proc x2c {c x} {
   #
   # Convert a real space x-coordinate to a canvas graph
   # space coordinate.
   #
   # c - the canvas.
   # x - the x-coordinate.

   global graph

   set x0 [expr {($x - $graph($c,xmin)) / double($graph($c,xrange))}]
   set x0 [expr {($x0 * $graph($c,xplot)) + $graph($c,xborder)}]

   return $x0
}

proc AddXLabel {c x label} {

   global graph

   set x0 [x2c $c $x]

   set y0 [expr {$graph($c,yborder) * 0.5}]

   set id [$c create text \
	       $x0 [expr {$graph($c,height) - $y0}] \
	       -justify center -text $label -anchor c \
	       -font $graph($c,xfont)]
}


proc AddYLabel {c y} {

   global graph

   set x0 [expr {$graph($c,xborder) * 0.7}]

   set y0 [expr {($y - $graph($c,ymin)) / double($graph($c,yrange))}]
   set y0 [expr {($y0 * $graph($c,yplot)) + $graph($c,yborder)}]

   set id [$c create text $x0 [y2c $c $y] \
	       -justify right -text $y -anchor e -font $graph($c,font)]

   return $id
}

proc AddYAxis {c min max} {

   global graph

   set x0 [expr {$graph($c,xborder) * 0.8}]

   $c create line $x0 [y2c $c $min] $x0 [y2c $c $max]
}

proc AddXAxis {c min max} {

   global graph

   set y0 [expr {$graph($c,height) - 1. * $graph($c,yborder)}]

   $c create line [x2c $c $min] $y0 [x2c $c $max] $y0
}

proc AddYAxisTick {c y} {

   global graph

   set x0 [expr {$graph($c,xborder) * 0.8}]
   set x1 [expr {$graph($c,xborder) * 0.75}]

   $c create line \
       $x0 [y2c $c $y] $x1 [y2c $c $y]
}

proc AddXAxisTick {c x} {

   global graph

   set x0 [x2c $c $x]
   set y0 [expr {$graph($c,height) - 1. * $graph($c,yborder)}]
   set y1 [expr {$graph($c,height) - 0.9 * $graph($c,yborder)}]

   $c create line $x0 $y0 $x0 $y1
}

proc AddTitle {c} {

   global graph

   if {[info exists graph($c,title)]} {
      set x0	[expr {$graph($c,xborder) + 0.5 * $graph($c,xplot)}]
      set y0	[expr {0.9 * $graph($c,yborder)}]

      $c create text $x0 $y0 \
	  -text $graph($c,title) -justify center -anchor s \
	  -font $graph($c,font)
   }
}

proc Graph {c option args} {

   global graph

   if { $option == "initialise" } {

      foreach entry [array names graph $c,*] {
	 unset graph($entry)
      }

      set graph($c,initialised)	1
      set graph($c,barwidth)	0.5
      set graph($c,border)	0.05
      set graph($c,barcolour)	white
      set graph($c,ntick)	5
      set graph($c,xaxislabels)	1

      bind $c <Configure> {
	 Graph %W plot
      }

   } elseif { $option == "values" } {

      if { ! [info exists graph($c,initialised)] } {
	 return -code error "Graph: plot $c doesn't appear to have been setup"
      }

      set values [lindex $args 0]

      set graph($c,values)	$values
      set graph($c,nvalues)	[llength $values]

      Graph $c plot

   } elseif { $option == "plot" } {


      if { ! [info exists graph($c,initialised)] } {
	 return -code error "graph: plot $c doesn't appear to have been setup"
      }


      if { ! [info exists graph($c,ydata)] } {
	 return
      }

      #
      # Find the range of the numbers

      set max [lindex $graph($c,ydata) 0]
      set min [lindex $graph($c,ydata) 0]

      foreach i [lrange $graph($c,ydata) 1 end] {
	 if { $i > $max } { set max $i }
	 if { $i < $min } { set min $i }
      }

      # Y coord ranges

      set graph($c,realymin)	$min
      set graph($c,realymax)	$max

      set graph($c,realyrange) \
	  [expr {$graph($c,realymax) - $graph($c,realymin)}]

      set tmp \
	  [expr {$graph($c,realyrange) * $graph($c,border)}]

      set range \
	  [expr {$graph($c,realymax) - $graph($c,realymin)}]

      set tmp \
	  [expr {$graph($c,realyrange) * $graph($c,border)}]

      set graph($c,ymin)	[expr {$min - $tmp}]
      set graph($c,ymax)	[expr {$max + $tmp}]
      set graph($c,yrange)	[expr {$graph($c,ymax) - $graph($c,ymin)}]
      if { $graph($c,yrange) == 0 } {
        return -code error "Graph: plot $c error in y range"
      }


      # X coord ranges

      set graph($c,realxmin)	1
      set graph($c,realxmax)	$graph($c,nvalues)

      set graph($c,realxrange) \
	  [expr {$graph($c,realxmax) - $graph($c,realxmin)}]

      set tmp \
	  [expr {$graph($c,realxrange) * $graph($c,border)}]

      set graph($c,xmin)	[expr {$graph($c,realxmin) - $tmp}]
      set graph($c,xmax)	[expr {$graph($c,realxmax) + $tmp}]
      set graph($c,xrange)	[expr {$graph($c,xmax) - $graph($c,xmin)}]

      update idletasks

      set graph($c,width)	[winfo width $c]
      set graph($c,height)	[winfo height $c]

      set graph($c,xborder)	[expr {2. * $graph($c,width) * 0.1}]
      set graph($c,yborder)	[expr {$graph($c,height) * 0.1}]

      set graph($c,xplot) \
	  [expr {$graph($c,width) - 1.5 * $graph($c,xborder)}]
      set graph($c,yplot) \
	  [expr {$graph($c,height) - 2. * $graph($c,yborder)}]

      set graph($c,xplotmin)	[expr {$graph($c,xborder)}]
      set graph($c,yplotmin)	$graph($c,yborder)

      set graph($c,xplotmax)	[expr {$graph($c,xborder) + $graph($c,xplot)}]
      set graph($c,yplotmax)	[expr {$graph($c,yborder) + $graph($c,yplot)}]

      $c delete all

      set graph($c,xstep) \
	  [expr {double($graph($c,xplot)) / double($graph($c,xrange))}]

      set graph($c,font) \
	  -*-helvetica-medium-r-normal--*-100-*-*-p-*-iso8859-1

      if { $graph($c,xstep) > 20 } {
	 set graph($c,xfont) \
	     -*-helvetica-medium-r-normal--*-100-*-*-p-*-iso8859-1
      } elseif { $graph($c,xstep) > 14 } {
	 set graph($c,xfont) \
	     -*-helvetica-medium-r-normal--*-80-*-*-p-*-iso8859-1
      } else {
	 set graph($c,xfont) \
	     -*-courier-medium-r-normal--*-80-*-*-m-*-iso8859-1
      }

      # Now set about building the plot

      set ipoint 1

      foreach i $graph($c,ydata) {

	 AddBar $c $ipoint $i

	 if { $graph($c,xaxislabels) } {
	    AddXLabel $c $ipoint $ipoint

	    AddXAxisTick $c $ipoint
	 }

	 incr ipoint
      }

      set labels [LooseLabels $graph($c,realymin) $graph($c,realymax) \
		      $graph($c,ntick)]

      AddYAxis $c $graph($c,realymin) $graph($c,realymax)

      if { $graph($c,xaxislabels) } {
	 AddXAxis $c $graph($c,realxmin) $graph($c,realxmax)
      }

      foreach i $labels {

	    AddYLabel $c $i
	    AddYAxisTick $c $i
      }

      AddTitle $c

   } else {
      set graph($c,$option)	[lindex $args 0]

      Graph $c plot
   }

}
