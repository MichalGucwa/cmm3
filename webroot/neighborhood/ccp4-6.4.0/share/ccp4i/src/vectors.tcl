#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - vectors.tcl
#
#
#
#  Vector arithmetic
#
#====================================================================

#CCP4i_cvs_Id $Id$

#============================================================================
#  MATHS FUNCTIONS
#============================================================================

#d_index_title Vector and Matrix Arithmetic (src/vector.tcl)

#-------------------------------------------------------------------------
proc vmult { a b } {
#-------------------------------------------------------------------------
#d_sum  return vector (a list) which is vector a multiplied by factor b
#d_arg a arbitrary length vector 
#d_arg b any numerical value
  foreach aa $a {
    lappend p [expr {$aa * $b}]
  }
  return $p
}
  

#-------------------------------------------------------------------------
proc vdotp { a b } {
#-------------------------------------------------------------------------
#d_sum return the dot product of two vectors
#d_arg a,b vectors (Tcl lists) of the same, but any, length

  set p 0.0
  for { set i 0 } { $i < [llength $a] } { incr i } {
    set p [expr {$p + ([lindex $a $i] * [lindex $b $i])}]
  }
  return $p
}

#------------------------------------------------------------------------
proc vlen { a } {
#------------------------------------------------------------------------
#d_sum return the magnitude of the vector
#d_arg a arbitrary length vector
  set l 0.0
  for { set i 0 } { $i < [llength $a] } { incr i } {
    set l [expr {$l + pow([lindex $a $i],2)}]
  }
  return [expr {sqrt($l)}]
}

#------------------------------------------------------------------------
proc vdist { a b } {
#------------------------------------------------------------------------
#d_sum return the distance between two points
#d_arg a,b two vectors (Tcl lists) of the same, but any, length which would \
usually be length 3 and represent two points in space
  return [vlen [vsub $a $b]]
}

#-----------------------------------------------------------------------
proc vadd { a b } {
#-----------------------------------------------------------------------
#d_sum return the sum of two vectors
#d_arg a,b two vectors (Tcl lists) of the same, but any, length 
  set c {}
  for { set i 0 } { $i < [llength $a] } { incr i } {
    lappend c [expr {[lindex $a $i] + [lindex $b $i]}]
  }
  return $c
}

#-----------------------------------------------------------------------
proc vsub { a b } {
#-----------------------------------------------------------------------
#d_sum return the difference of two vectors
#d_arg a,b two vectors (Tcl lists) of the same, but any, length 
  set c {}
  for { set i 0 } { $i < [llength $a] } { incr i } {
    lappend c [expr {[lindex $a $i] - [lindex $b $i]}]
  }
  return $c
}

#-----------------------------------------------------------------------
proc vcent { args } {
#-----------------------------------------------------------------------
#d_sum return the average coordinate of a list of 2D coordinates
#d_arg a,b,c..  Any number of 2D coordinates (i.e. Tcl lists of two items)
  set x 0.0
  set y 0.0
  set n 0
  foreach v $args  {
    incr n
    set x [expr {$x + [lindex $v 0]}]
    set y [expr {$y + [lindex $v 1]}]
  }
  return [list [expr {$x / $n}] [expr {$y / $n}] ]
}

#------------------------------------------------------------------------
proc vscal { s v } {
#------------------------------------------------------------------------
#d_sum  return vector (a list) which is vector v scaled by factor s
#d_arg s any numerical value
#d_arg v arbitrary length vector
  foreach  i $v {
    lappend b [expr {$i * $s}]
  }
  return $b
}

#------------------------------------------------------------------------
proc vrot { angl a } {
#------------------------------------------------------------------------
#d_sum Apply a rotation to a 2D coordinate
#d_arg angl rotation angle (radians)
#d_arg a 2D coordinate (a Tcl list)

  set ax [lindex $a 0]
  set ay [lindex $a 1]
  lappend b [expr {($ax * cos($angl)) - ( $ay * sin($angl))} ]
  lappend b [expr {($ax * sin($angl)) + ( $ay * cos($angl))} ]
  return $b
}

#------------------------------------------------------------------------
proc vmatmult { rmat a } {
#------------------------------------------------------------------------
#d_sum apply rotation matrix rmat to vector a
#d_arg rmat a 3*3 matrix (a Tcl list of lists)
#d_arg a  a vector of length 3  (a Tcl list)
  set b {}
  foreach j [list 0 3 6 ] {
    set rr [lrange $rmat $j end]
    lappend b [expr {[lindex $rr 0] * [lindex $a 0] + \
                  [lindex $rr 1] * [lindex $a 1] + \
                  [lindex $rr 2] * [lindex $a 2]} ]
  }
  return $b
}

#------------------------------------------------------------------------
proc vmirror { a axis } {
#------------------------------------------------------------------------
#d_sum apply a mirror transformation in x or y axis
#d_arg a a 2D coordinate (a Tcl list)
#d_arg axis choice of axis for mirror inversion (should be 'x' or 'y')

  switch $axis \
  x {
    lappend b [expr {[lindex $a 0] * -1}] [lindex $a 1]
  } y {
    lappend b [lindex $a 0] [expr {[lindex $a 1] *-1}]
  }
  return $b
}

