#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
# =====================================================================
# graphics.tcl --
# The 3D Viewer is based on code from Leo Caves
# with contributions from Mike Hartshorn
# University of York, January 1998
#
# CCP4Interface
# Liz Potterton April 2000
#
# ======================================================================

#------------------------------------------------------------------
proc trackball_init { arrayname args } {
#------------------------------------------------------------------
  upvar #0 $arrayname array
    set array(transforming) 0
    set array(shift_block) 0
    set array(cursor_x) 0
    set array(cursor_y) 0
    set array(cursor_cntl_x) 0
    set array(cursor_cntl_y) 0
    set array(xoff) 0.0
    set array(yoff) 0.0
    set array(fragtran_x) 0.0
    set array(fragtran_y) 0.0
    set array(scale) 1.0
# Recentering fragment does not require the rotation to be 
# reinitialised - use -norot argument
    if { [lsearch -regexp $args norot] < 0 } {
      set array(xangle) 0.0
      set array(yangle) 0.0
      set array(cntl_xangle) 0.0
      set array(cntl_yangle) 0.0
    }
}

#------------------------------------------------------------------
proc trackball_keypress { arrayname mode key } {
#------------------------------------------------------------------
  upvar #0 $arrayname array

# Handle press or release of a keyboard key within the sketch window
# We are only interested in Control and Shift keys which control the mouse_mode
# This procedure is also called when the user moves mouse into the 
# molecule window with the Shift or the Control key (or both) depressed
  if { ![regexp Control|Shift $key] } { return }

# Set shift_block which will block the usual transformation mouse
# bindings which have no modifier key
  set array(shift_block) [regexp press $mode]

}


# virtual trackball bind-ing jiggery-pokery from mjh
#------------------------------------------------------------------
proc trackball_scale { arrayname W x y } {
#------------------------------------------------------------------
   global system
   upvar #0 $arrayname array 
   set array(transforming) 1
   if { ![regexp WINDOWS $system(OPSYS)] } {
     $W configure -cursor {double_arrow red };
   }
   set array(cursor_x) $x;
   set array(cursor_y) $y;
}

#------------------------------------------------------------------
proc trackball_scale_motion { arrayname x y   } {
#------------------------------------------------------------------
   upvar #0 $arrayname array 
   if { !$array(transforming) } { return }
   set array(scale) [expr ($array(scale) +  0.05 * ($y - $array(cursor_y))) ];
   if { $array(scale) <= 0 } { set array(scale) 0.0001 }

   set array(cursor_x) $x;
   set array(cursor_y) $y;

   sketch_redisplay $arrayname scale
}


#------------------------------------------------------------------
proc trackball_scale_release { arrayname W } {
#------------------------------------------------------------------
  global system
  upvar #0 $arrayname array 
  if { ![regexp WINDOWS $system(OPSYS)] } {
    $W configure -cursor {};
  }
  set array(transforming) 0
  sketch_redisplay $arrayname scale_release
}

#------------------------------------------------------------------
proc trackball_rotate {  arrayname W x y } {
#------------------------------------------------------------------
   global system
   upvar #0 $arrayname array 
   if { $array(shift_block) } { return }
   set array(transforming) 1
   if { ![regexp WINDOWS $system(OPSYS)] } {
     $W configure -cursor {exchange red }
   }
   set array(cursor_x) $x
   set array(cursor_y) $y
}


#------------------------------------------------------------------
proc trackball_rotate_motion { arrayname x y } { 
#------------------------------------------------------------------
   upvar #0 $arrayname array 
   if { $array(shift_block) } { return }
   set array(yangle) [expr ($array(yangle) +  ($x - $array(cursor_x))) ]
   set array(xangle) [expr ($array(xangle) +  ($y - $array(cursor_y))) ]
   set array(cursor_x) $x
   set array(cursor_y) $y
   set array(transforming) 1

   sketch_redisplay $arrayname rotate_motion
}

#------------------------------------------------------------------
proc trackball_rotate_release { arrayname W } {
#------------------------------------------------------------------
  global system
  upvar #0 $arrayname array 
  if { ![regexp WINDOWS $system(OPSYS)] } {
    $W configure -cursor {};
  }
  if { $array(shift_block) } { return }
  sketch_redisplay $arrayname rotate_release
  set array(transforming) 0
}

#------------------------------------------------------------------
proc trackball_fragrot {  arrayname W x y } {
#------------------------------------------------------------------
   global system
   upvar #0 $arrayname array 
#   puts "trackball_cntl_b2"
   set array(transforming) 1
   if { ![regexp WINDOWS $system(OPSYS)] } {
     $W configure -cursor {exchange blue }
   }
   set array(cursor_cntl_x) $x
   set array(cursor_cntl_y) $y
}


#------------------------------------------------------------------
proc trackball_fragrot_motion { arrayname x y } { 
#------------------------------------------------------------------
   upvar #0 $arrayname array 
   if { !$array(transforming) } { return }
   set array(cntl_xangle) [expr $array(cursor_cntl_x) -$x]
   set array(cntl_yangle) [expr $array(cursor_cntl_y) -$y]
   set array(cursor_cntl_x) $x 
   set array(cursor_cntl_y) $y 

   sketch_rotate_fragment $arrayname motion
}

#------------------------------------------------------------------
proc trackball_fragrot_release { arrayname W } {
#------------------------------------------------------------------
  global system
  upvar #0 $arrayname array 
  if { ![regexp WINDOWS $system(OPSYS)] } {
    $W configure -cursor {};
  }
  sketch_rotate_fragment $arrayname release
}


#------------------------------------------------------------------
proc trackball_translate { arrayname W x y } {
#------------------------------------------------------------------
   global system
   upvar #0 $arrayname array 
   if { $array(shift_block) } { return }
   if { ![regexp WINDOWS $system(OPSYS)] } { 
     $W configure -cursor { fleur red }
   }
   set array(cursor_x) $x
   set array(cursor_y) $y
   set array(transforming) 1

   sketch_redisplay $arrayname translate
}

#------------------------------------------------------------------
proc trackball_translate_motion { arrayname x y }  {
#------------------------------------------------------------------
   upvar #0 $arrayname array 
   if { $array(shift_block) } { return }
   # Apply the XY translation.
   # Note y is opposite because origin is top left.

   set array(xoff) [expr $array(xoff) + ($x - $array(cursor_x))] 
   set array(yoff) [expr $array(yoff) - ($array(cursor_y) - $y)] 

   set array(cursor_x) $x;
   set array(cursor_y) $y;

   set array(transforming) 1
   sketch_redisplay $arrayname translate_motion
}

#------------------------------------------------------------------
proc trackball_translate_release { arrayname W } {
#------------------------------------------------------------------
  global system
  upvar #0 $arrayname array 
  if { ![regexp WINDOWS $system(OPSYS)] } {
    $W configure -cursor {};
  }
  if { $array(shift_block) } { return }
  set array(transforming) 0
  sketch_redisplay $arrayname translate_release
}


#------------------------------------------------------------------
proc trackball_fragtran { arrayname W x y } {
#------------------------------------------------------------------
   global system
   upvar #0 $arrayname array 
   if { ![regexp WINDOWS $system(OPSYS)] } {
     $W configure -cursor { fleur red }
   }
   set array(cursor_cntl_x) $x
   set array(cursor_cntl_y) $y
   set array(transforming) 1

   sketch_redisplay $arrayname tran
}

#------------------------------------------------------------------
proc trackball_fragtran_motion { arrayname x y }  {
#------------------------------------------------------------------
   upvar #0 $arrayname array 
   if { !$array(transforming) }  { return }
   # Apply the XY translation.
   # Note y is opposite because origin is top left.

   set array(fragtran_x) [expr $x - $array(cursor_cntl_x)] 
   set array(fragtran_y) [expr $y - $array(cursor_cntl_y)] 

   set array(cursor_cntl_x) $x;
   set array(cursor_cntl_y) $y;

   set array(transforming) 1
   sketch_move_fragment $arrayname motion
}

#------------------------------------------------------------------
proc trackball_fragtran_release { arrayname W } {
#------------------------------------------------------------------
  global system
  upvar #0 $arrayname array 
  if { ![regexp WINDOWS $system(OPSYS)] } {
    $W configure -cursor {};
  }
  set array(transforming) 0
  sketch_move_fragment $arrayname release
}

