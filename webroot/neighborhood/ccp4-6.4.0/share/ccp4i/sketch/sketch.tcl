
#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
# ==================================================================== =
# sketch.tcl --
# The 3D Viewer is based on code from Leo Caves 
# with contributions from Mike Hartshorn
# University of York, January 1998
#
# CCP4Interface 
# Liz Potterton April 2000
#
# ======================================================================

  source [SearchPath TOP sketch trackball.tcl]
  source [SearchPath TOP sketch sketch_table.tcl]
  source [SearchPath TOP src vectors.tcl]
  source [SearchPath TOP utils pdb_utils.tcl]

#----------------------------------------------------------------------
proc sketch_button_add { arrayname xpick ypick } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array
  global Mol

# The handler for mouse click which applies an edit function
# The currently selected edit function is in array(edit_mode)

  set edit_mode $array(edit_mode)

# Make sure there is active atom selected if necessary

  if { $array(active_atom)  == "" && \
	![StringSame $edit_mode 0 del_bond del_atom move] && \
	$Mol(nAtoms) != 0 } {
      WarningMessage "Select an active atom with control-right mouse before trying to add fragments"
      return
  }

  if { $edit_mode == 0 } {
    WarningMessage "Select fragment type to add from menu on the left" 
    return
  }

# Get the mouse click position - or the selected atom

  scale_cursor_xy $arrayname $xpick $ypick x y
    
  set hit_atom [sketch_hit_atom $arrayname $x $y]

  switch -- $edit_mode \
  move {
  } del_bond {
# delete bond
    if { [set nb [sketch_hit_bond $arrayname $x $y]] > 0 } { 
      sketch_mol_backup $arrayname
      sketch_delete_bond $nb 
      sketch_delete_objects $arrayname  0 0 [expr $Mol(nBonds) - 1] $Mol(nBonds)
      incr Mol(nBonds) -1
      sketch_create_bond_objects $arrayname
      sketch_redisplay $arrayname
    }
  } del_atom {
    if { $hit_atom > 0 } { sketch_delete_atom $arrayname $hit_atom }

  } B {
# add bond
    if { $hit_atom > 0 } { 
      sketch_mol_backup $arrayname
      sketch_add_bond $arrayname $hit_atom 
    }

  } default {

    set array(anchor_atom) $hit_atom

    if { [sketch_add_fragment $arrayname $x $y arange brange ] } {
      sketch_update_table $arrayname -first $arange
      sketch_create_bond_objects $arrayname -first $brange
      sketch_create_atom_objects $arrayname -first $arange
      sketch_redisplay $arrayname
      set_active_atom $arrayname $Mol(nAtoms)
    }
  }
}

#-----------------------------------------------------------------------
proc sketch_button_edit_bond { arrayname xpick ypick } {
#-----------------------------------------------------------------------
# If user has clicked on bond with shift middle mouse then 
# change the bond type of the bond - cycle through 1-2-3
  global Mol

  scale_cursor_xy $arrayname $xpick $ypick x y
  if { [set nb [sketch_hit_bond $arrayname $x $y]] > 0 } {
    incr Mol(Bondtype,$nb)
    switch $Mol(Bondtype,$nb) \
    2 {
# Calculate the bond perpendicular
      scan $Mol(Bonds,$nb) "%s%s" a b
      set dx [expr [lindex [lindex $Mol(XY) $b] 0] \
		- [lindex [lindex $Mol(XY) $a] 0]]
      set dy [expr [lindex [lindex $Mol(XY) $b] 1] \
		- [lindex [lindex $Mol(XY) $a] 1]]
      set dd [expr pow($dx*$dx + $dy*$dy,0.5) ]
      set Mol(Bond_perp,$nb) [list [expr $dx / $dd] [expr $dy / $dd] ]
    } 7 {
      set Mol(Bondtype,$nb) 1 
    }
    sketch_delete_objects $arrayname 0 0 $nb $nb
    sketch_create_bond_objects $arrayname -first $nb -last $nb
    sketch_redisplay $arrayname
    sketch_label_bond_type $arrayname $nb
  }
}

#-----------------------------------------------------------------------
proc sketch_button_active { arrayname xpick ypick { mode 0} } {
#-----------------------------------------------------------------------
# Make the picked atom the active atom - or switch off
# active atom if pick is not close ot an atom
  upvar #0 $arrayname array

    scale_cursor_xy $arrayname $xpick $ypick x y
    set_active_atom $arrayname [sketch_hit_atom $arrayname $x $y] $mode
}

#-----------------------------------------------------------------------
proc sketch_change_chiral { arrayname xpick ypick  } {
#-----------------------------------------------------------------------
  global Mol
# Change the chirality of the atom (if any) at xpick,ypick
  scale_cursor_xy $arrayname $xpick $ypick x y
  if { [set hit_atom [sketch_hit_atom $arrayname $x $y]] < 1 }   { return }
  set nch [get_chiral_id $Mol(Name,$hit_atom) ]
  puts "nch $nch"
  if { $nch == 0 } {
    WarningMessage "You seem to be trying to change the chirality of an atom which is not defined as a chiral centre.  You must first define the atom as a chiral centre."
    return
  } else {
    if { $Mol(Chirality,$nch) == "+" } {
      set Mol(Chirality,$nch) "-"
    } elseif { $Mol(Chirality,$nch) == "-" } { 
      set Mol(Chirality,$nch) "+"
    }
  }
}

#--------------------------------------------------------------------
proc get_chiral_id { atname } {
#--------------------------------------------------------------------
  global Mol
# Test if input atom is already on list of chiral atoms
  set nch 0
  if { $Mol(nChiral) > 0 } {
    for { set n 1 } { $n <= $Mol(nChiral) } { incr n } {
      if { [StringSame $Mol(ChiralCentre,$n) $atname ] } {
        set nch $n
        break
      }
    }
  }
  return $nch
}


#--------------------------------------------------------------------
proc scale_cursor_xy { arrayname xin yin xVar yVar } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array
  upvar $xVar x
  upvar $yVar y
  set x [expr ($xin - $array(current_xoff))/$array(current_scale)]
  set y [expr ($yin - $array(current_yoff))/$array(current_scale)]

}


#-------------------------------------------------------------------
proc sketch_hit_atom { arrayname x y } {
#-------------------------------------------------------------------
# If position x,y close to an atom then return atom number 
  upvar #0 $arrayname array
  global Mol

  if { $Mol(nAtoms) < 1 } { return 0 }

  set hitrad [expr $array(hit_radius) / $array(current_scale)]
   
  set n 0; foreach atom_xy [lrange $Mol(XY) 1 end] { incr n
    if { [expr abs([expr $x - [lindex $atom_xy 0]])] < $hitrad  &&
         [expr abs([expr $y - [lindex $atom_xy 1]])] < $hitrad  } {
       return $n
    }
  }
  return 0
}

#------------------------------------------------------------
proc sketch_get_atom_number { name } {
#------------------------------------------------------------
  global Mol
  if { $Mol(nAtoms) < 1 } { return 0 }
  for { set n 1 } { $n <= $Mol(nAtoms) } { incr n } {
    if { $Mol(Name,$n) == $name } { return $n }
  }
  return 0
}

#------------------------------------------------------------
proc sketch_hit_bond {  arrayname xpick ypick } {
#------------------------------------------------------------
  upvar #0 $arrayname array
  global Mol
  set hits {}

  set hitrad [expr $array(hit_radius) / $array(current_scale)]
  set hitrad2 [expr $hitrad *$hitrad]

  if { $Mol(nBonds) <= 0 } { return 0 }

  set n 0; foreach xy [lrange $Mol(XY) 1 end] { incr n
    set dx($n)  [expr $xpick - [lindex $xy 0] ]
    set dy($n)  [expr $ypick - [lindex $xy 1] ]
  }

  for { set n 1 } { $n <= $Mol(nBonds) } { incr n } {
    set ii [lindex $Mol(Bonds,$n) 0]
    set jj [lindex $Mol(Bonds,$n) 1]
    if { [expr $dx($ii) * $dx($jj)] < $hitrad2 && [expr $dy($ii) * $dy($jj)] < $hitrad2 } {
#       puts "in region $n $Mol(Name,$ii) $Mol(Name,$jj)"
       lappend hits $n
    }
  }
  case [llength $hits] \
  0 { 
    return 0
  } 1 { 
    return $hits
  } default {

    set best_hit 0; set best_val 0.0; foreach n $hits {
      set ii [lindex $Mol(Bonds,$n) 0]
      set jj [lindex $Mol(Bonds,$n) 1]
      set vbond [lrange [vsub [lindex $Mol(XY) $jj] [lindex $Mol(XY) $ii]] 0 1]
      set vpick [vsub [list $xpick $ypick] [lindex $Mol(XY) $ii]]
      set costheta [expr [vdotp $vbond $vpick ]  / ( [vlen $vbond ] * [vlen $vpick] ) ]
      if { $costheta > $best_val } { set best_val $costheta; set best_hit $n }
    }
    return $best_hit
  }

}


#------------------------------------------------------------
proc sketch_add_fragment { arrayname x y arangeVar brangeVar }  {
#------------------------------------------------------------
# Create a new atom at position x,y
# Fill out all the parameters 
  upvar #0 $arrayname array
  upvar $arangeVar arange
  upvar $brangeVar brange
  global Mol
  global sketch_table

  set arange [expr $Mol(nAtoms) + 1]
  set brange [expr $Mol(nBonds) + 1]

  set pick [list $x $y ]
  set guide1 {}
  set guide2 {}
  set guide3 {}
  set mode $array(edit_mode)
#  puts "sketch_add_fragment $x $y $mode"

  if { $mode == 3  || $mode == 4 } {
    if { $array(anchor_atom) <= 0 } {
      WarningMessage "Pick a second atom in existing ring (with shift-left mouse) to attach to new fragment"
      return 0 }
    if { [lsearch -exact [getbondedatoms $array(active_atom) ] \
		$array(anchor_atom) ] < 0 } {
      WarningMessage "The second anchor atom atom is not bonded to the active atom"
      return 0
    } 
    set guide1 [sketch_get_2d_coord $arrayname $array(active_atom)]
    set guide2 [sketch_get_2d_coord $arrayname $array(anchor_atom)]
    set zz [expr \
         ( [lindex [sketch_get_3d_coord $arrayname $array(active_atom)] 2 ] + \
          [lindex [sketch_get_3d_coord $arrayname $array(anchor_atom)] 2 ] )\
           / 2 ]
    set naybr1 0; set naybr2 0
    foreach atom  [getbondedatoms $array(active_atom) ] {
    if { $atom != $array(anchor_atom)  } { set naybr1 $atom } }
    foreach atom  [getbondedatoms $array(anchor_atom) ] {
    if { $atom != $array(active_atom) } { set naybr2 $atom } }
    if { $naybr1 > 0 && $naybr2 > 0 } {
      set guide3 [vcent [sketch_get_2d_coord $arrayname $naybr1]  \
       [sketch_get_2d_coord $arrayname $naybr2] ] }
  } elseif { $mode >= 5 } {
    if { $Mol(nAtoms) ==  0 } {
      set guide1 {}
      set zz 0.0
    } else  {
      set guide1 [sketch_get_2d_coord $arrayname $array(active_atom)]
      set zz [lindex [sketch_get_3d_coord $arrayname $array(active_atom)] 2 ]
    }
    set guide2 $pick
  }  else {
    if {  $Mol(nAtoms) > 0 } {
      set zz [lindex [sketch_get_3d_coord $arrayname $array(active_atom)] 2 ]
    } else {
      set zz 0.0
    }
  }

  if { ![gettemplate $mode $pick $guide1 $guide2 $guide3 \
	tmpltype tmplxy tmplconn tmplchiral ] } { return 0 }

# We have positioned the new fragment in screen coordinates - now
# need to do the inverse of the world-to-screen transform to get
# the coordinates in world frame

  if { $array(dimension) == 3 } {
    foreach atxy $tmplxy { lappend tmplxyz [concat $atxy $zz] }
    set tmplxyz [sketch_inv_3d_rotate $arrayname $tmplxyz]
  }

  sketch_mol_backup $arrayname

  set na $Mol(nAtoms)
  set nb $Mol(nBonds)
  for  { set nt 0 } { $nt < [llength $tmpltype] } { incr nt } {
    incr na
    set Mol(Element,$na) C
    set Mol(Colour,$na) green
    set Mol(Name,$na) "C$na"
    set Mol(Type,$na) [lindex $tmpltype $nt]
    set Mol(Charge,$na) 0
    switch $array(dimension) \
    2 {
      set Mol(xy,$na) [lindex $tmplxy $nt]
    } 3 {
      lappend Mol(XY) [lindex $tmplxy $nt]
      set Mol(Coor,$na) [lindex $tmplxyz $nt]
    }
    foreach conn [lindex $tmplconn $nt] {
      switch -- $conn \
      0 {
        if { $array(active_atom) != "" } {
          incr nb; set Mol(Bonds,$nb) "$array(active_atom) $na" }
      } -1 {
        if { $array(anchor_atom) > 0 } {
          incr nb ; set Mol(Bonds,$nb) "$array(anchor_atom) $na" }
      } default {
        if { [set lat [expr $na - $conn]] > 0 }  {
          incr nb
          set Mol(Bonds,$nb) "$lat $na"
        }
      }
      set Mol(Bondtype,$nb) 1
    }
  }

# Update the message line if this was first atom
  if { $Mol(nAtoms) == 0 } { sketch_set_message $arrayname edit }

  set Mol(nAtoms) $na
  set Mol(nBonds) $nb
  set array(anchor_atom) 0
  return 1
}

#------------------------------------------------------------------
proc sketch_get_3d_coord { arrayname atno } {
#------------------------------------------------------------------
  global Mol
  upvar #0 $arrayname array

  switch $array(dimension) \
  2 {
    return [concat $Mol(xy,$atno) 0.0]
  } 3 {
#    return $Mol(Coor,$atno)
    return [lindex $Mol(XY) $atno]
  }
}

#------------------------------------------------------------------
proc sketch_get_2d_coord { arrayname atno } {
#------------------------------------------------------------------
  global Mol
  upvar #0 $arrayname array

  switch $array(dimension) \
  2 { 
    return $Mol(xy,$atno)
  } 3 { 
    return [lrange [lindex $Mol(XY) $atno] 0 1]
  }
}

#--------------------------------------------------------------------
proc sketch_convert_xy {} {
#--------------------------------------------------------------------
  global Mol
  set i 1; foreach atom [lrange $Mol(XY) 1 end] {
    set Mol(xy,$i) [lrange $atom 0 1]
    incr i
  }
}


#--------------------------------------------------------------------
proc sketch_delete_mol { arrayname } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array
  global Mol

  if { $Mol(nAtoms) > 0 } { sketch_delete_objects $arrayname }
  set array(anchor_atom) 0
  set array(active_atom) ""
  set array(edit_atom) 0
  set array(ifpdbin) 0
  set array(ifeditedplane) 0
  unset Mol
  InitialiseArray [SearchPath TOP sketch Mol.def] Mol Mol

}


#-------------------------------------------------------------------------
proc sketch_read_cifdict { file dictVar monomerVar } { 
#-------------------------------------------------------------------------
  upvar #0 $dictVar dict
  upvar $monomerVar monomer

  if { ![ReadFile $file filetext -split -nocomments "^#" -noblank] } {return 0}
  set loop ""
  set dict(Name) ""
  set dict(nbonds) 0
  set dict(nchiral) 0
  set dict(nplane) 0
  foreach pp [array names dict plane,*] { unset dict($pp) }
  foreach pp [array names dict plane_dev,*] { unset dict($pp) }
  set search_line 0
  while { $dict(Name) == ""} {
    # Try extracting the monomer name from line data_comp_xxxx
    set hit_line [lsearch -regexp [lrange $filetext $search_line end] data_comp_ ]
    if { $hit_line < 0 } { return 0 }
    incr search_line $hit_line
    regsub data_comp_ [lindex $filetext $search_line] "" found_monomer
    if { ![StringSame $found_monomer list] && \
      ( $monomer == "" || [string first $monomer $found_monomer] == 0) } {
      set dict(Name) $found_monomer
      set monomer $found_monomer
    } 
    incr search_line 1
  }
  if { [ReadCifLoop [lrange $filetext $search_line end] _chem_comp_atom \
	 properties data ] <= 0 } { return 0 }

  if { [set i_name [lsearch $properties atom_id]] < 0 ||
       [set i_type [lsearch $properties type_energy]] < 0 } {
    return 0 }
  foreach line $data {
    lappend atom_id [read_cif_name [lindex $line $i_name]]
    lappend type_energy [lindex $line $i_type]
  }
  set dict(atom_id) $atom_id
  set dict(type_energy) $type_energy

# Read partial charges if in file
  if { [set i_charge [lsearch $properties partial_charge]] >= 0 } {
    foreach line $data {
      lappend charges [expr int([lindex $line $i_charge])]
    }
    set dict(charges) $charges
  } else {
    set dict(charges) {}
  }

  set dict(nbond) 0
  if { [ReadCifLoop [lrange $filetext $search_line end] _chem_comp_bond \
         properties data ]  > 0 } {
    if { [set i_1 [lsearch $properties atom_id_1]] >= 0 &&
         [set i_2 [lsearch $properties atom_id_2]] >=  0 &&
         [set i_3 [lsearch $properties type]] >=  0 } {
      foreach line $data {
        lappend bond_1 [read_cif_name [lindex $line $i_1] ]
        lappend bond_2 [read_cif_name [lindex $line $i_2] ]
        lappend bond_type [lindex $line $i_3] 
      }
      set dict(bond_1) $bond_1
      set dict(bond_2) $bond_2
      set dict(bond_type) $bond_type
      set dict(nbond) [llength $bond_1]
    }
  }
# Get any chiral info
  if { [ReadCifLoop [lrange $filetext $search_line end] _chem_comp_chir \
         properties data ]  > 0  } {
    set i_0 [lsearch $properties atom_id_centre]
    set i_vol [lsearch $properties volume_sign]
    foreach line $data {
      lappend chiralcentre [read_cif_name [lindex $line $i_0]]
      lappend chirality [lindex $line $i_vol]
      set nebrs ""
      if { [regexp cross [lindex $line $i_vol]] } {
        set max_nn [expr 2 + [string range [lindex $line $i_vol] 5 5]]
      } else {
        set max_nn 3
      }
      for { set nn 1 } { $nn <= $max_nn } { incr nn } {
	 set ii [lsearch $properties atom_id_$nn]
         append nebrs " [read_cif_name [lindex $line $ii]]"
      }
      lappend neighbours $nebrs
      #puts "neighbours $neighbours"
    }
    set dict(chiralcentre)   $chiralcentre
    set dict(neighbours)   $neighbours
    set dict(chirality)   $chirality
    set dict(nchiral) [llength $chiralcentre]
#    puts "dict(chiralcentre) $dict(chiralcentre)"
  }

#Get the planes

  if { [ReadCifLoop [lrange $filetext $search_line end] _chem_comp_plane_atom \
         properties data ] > 0 } { 
    set i_0 [lsearch $properties plane_id]
    set i_1 [lsearch $properties atom_id]
    set i_2 [lsearch $properties dist_esd]
    foreach line $data {
      set iplane [lindex [split [lindex $line $i_0] -] 1 ]
      set dict(nplane) [max $dict(nplane) $iplane]
      lappend dict(plane,$iplane) [lindex $line $i_1]
      lappend dict(plane_dev,$iplane) [lindex $line $i_2]
    }
#    for { set n 1 } { $n <= $dict(nplane) } { incr n } { 
#      puts "plane $n $dict(plane,$n) $dict(plane_dev,$n)" }
  }

  return 1
    
}

#----------------------------------------------------------------
proc sketch_load_dict_coords { arrayname monomer ciffile libfile args } {
#----------------------------------------------------------------
  upvar #0 $arrayname array
  global Mol
# This procedure called after running libcheck in the dictionary task
# and when retrieving monomer from library

  set noh {}
  set append 0
  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    noh {
      set noh -noh
    } append {
      set append 1
    }
    incr n
  }

  if { !$append } { 
    sketch_delete_mol $arrayname
    sketch_update_table $arrayname -refresh
    sketch_update_chiral_table $arrayname -refresh
    set ifatnew 1
    set ifbdnew 1
    set ifchirnew 1
  } else {
    set ifatnew [expr $Mol(nAtoms) + 1 ]
    set ifbdnew [expr $Mol(nBonds) + 1 ]
    set ifchirnew [expr $Mol(nChiral) + 1 ]
  }
 
  if { [regexp pdb [file extension $ciffile] ] } {
    if { [lindex [MolReadPDB Mol $ciffile $noh] 0] <= 0 } { return 0 }
  } else {
    if { [MolReadCif Mol $ciffile $noh ] <= 0 } { return 0 }
  }
  sketch_3d_properties -first $ifatnew
  global tmp_dict
  if { ![sketch_read_cifdict $libfile tmp_dict monomer] } { 
    sketch_3d_bonds -first $ifatnew
  } else {
    sketch_apply_dict_bonds tmp_dict $monomer -first $ifatnew
    sketch_apply_atomtypes tmp_dict $monomer -first $ifatnew
    sketch_apply_dict_chiral tmp_dict $monomer
    sketch_apply_dict_plane tmp_dict $monomer
  }
  catch "unset tmp_dict"
  sketch_3d_bbox $arrayname -first $ifatnew
  sketch_create_name_label $arrayname
  sketch_create_bond_objects $arrayname -first $ifbdnew
  sketch_create_atom_objects $arrayname -first $ifatnew
  sketch_redisplay $arrayname
  sketch_update_table $arrayname -first $ifatnew
  sketch_update_chiral_table $arrayname -first $ifchirnew

}


#-------------------------------------------------------------------
proc ReadCifLoop { text catagory propsVar dataVar } {
#-------------------------------------------------------------------
  upvar $propsVar props
  upvar $dataVar data

#  puts "ReadCifLoop catagory $catagory"

  append catagory  "\\\."
  set props {}
  set data {}
  set nlines [llength $text]
  set line 0; set hit_line 0
  while { $hit_line >= 0 } {
    set hit_line [lsearch -regexp [lrange $text $line end] $catagory ]
    if { $hit_line >= 0 } { 
      incr line $hit_line
      lappend props [lindex [split [lindex $text $line] \.] 1] 
      incr line
    }
  }
  if { [set nprops [llength $props]] <= 0 } { return 0 }

  set inloop 1
  set leftover ""

  while { $inloop && $line < $nlines } {
    set dataline [lindex $text $line]
    if { [regexp {^#|^loop_|^data_} $dataline] } { 
      set inloop 0
    } else {
      set ndata [llength $dataline]
      while { [llength $dataline] < $nprops && $line < $nlines } {
        incr line; set dataline [concat $dataline [lindex $text $line]]
      }
      lappend data $dataline
    }
    incr line
  }

  return [llength $data]

}

#-----------------------------------------------------------------------
proc sketch_apply_dict_bonds { dictVar monomer args } {
#-----------------------------------------------------------------------
  upvar #0 $dictVar dict
# Given the bond information from a _geom.cif file then append to 
# sketcher bond data 
  global Mol
  set first 1
  set n 0; set nargs [llength $args]
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    first {
      incr n; set first [lindex $args $n]
    }
    incr n
  }
  
  if { $dict(nbond) <= 0 } { return } 
  set bond_1 $dict(bond_1)
  set bond_2 $dict(bond_2)
  set bond_type $dict(bond_type)

# Replace the atom names in the bond list with the atom number

  for { set na $first } { $na <= $Mol(nAtoms) } { incr na } {
    set atnam $Mol(Name,$na)
    while { [set i [lsearch -exact $bond_1 $atnam ] ] >= 0 } {
      set bond_1 [lreplace $bond_1 $i $i $na]
    }
    while { [set i [lsearch -exact $bond_2 $atnam ] ] >= 0 } {
      set bond_2 [lreplace $bond_2 $i $i $na]
    }
  }
#  puts "bond_1 $bond_1"
#  puts "bond_2 $bond_2"

# Beware remaining atom names in the list - probably excluded hydrogen atoms
# Just leave them out when adding bonds to the sketcher data structures

  set nb $Mol(nBonds)
  set i -1; foreach b1 $bond_1 { incr i
    if { ![regexp {[A-Z]} $b1 ] && ![regexp  {[A-Z]} [lindex $bond_2 $i]] } { 
      incr nb; set Mol(Bonds,$nb) "$b1 [lindex $bond_2 $i]"
      set ib [lsearch [list sing doub trip delo arom meta cova ] \
            [string range [lindex $bond_type $i] 0 3]  ]
      if { $ib < 0 } { set ib 0 }
      set Mol(Bondtype,$nb) [lindex [list 1 2 3 4 5 6 1] $ib]
    }
  }
  set Mol(nBonds) $nb

}


#-----------------------------------------------------------------------
proc sketch_apply_atomtypes { dictVar monomer args } {
#-----------------------------------------------------------------------
  upvar #0 $dictVar dict
  global Mol
# Use atom types read from geometry file into dict array to set the 
# atom types of molecule already loaded into the Mol array
  set first 1
  set n 0; set nargs [llength $args]
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    first {
      incr n; set first [lindex $args $n]
    }
    incr n
  }

  set atom_ids $dict(atom_id)
  set types $dict(type_energy)
  if { $dict(charges) != "" } {
    set charges $dict(charges)
  } else {
    for { set na $first } { $na <= [llength $atom_ids] } { incr na } {
      lappend charges 0
    }
  }

  for { set na $first } { $na <= $Mol(nAtoms) } { incr na } {
    if { [set n [lsearch $atom_ids $Mol(Name,$na)] ] >= 0 } {
      set Mol(Type,$na) [lindex  $types $n]
      set Mol(Charge,$na) [lindex $charges $n]
    }
 }
}

#-----------------------------------------------------------------------
proc sketch_apply_dict_chiral { dictVar monomer } {
#-----------------------------------------------------------------------
  upvar #0 $dictVar dict
  global Mol
  global sketch_data

# Use chiral data read from cif geometry file into the temporary dict array
# Append this to the Mol chiral data

  if { $dict(nchiral) == 0 } { return }
  set nch  $Mol(nChiral)
  set i -1;foreach centre $dict(chiralcentre) { incr i
    if { [set id [get_chiral_id $centre]] > 0 } {
# The chiral centre is already defined so just make sure neighbour 
# and chiral definitions are the same
      set j -1; foreach naybr [lindex $dict(neighbours) $i] { incr j
        set Mol(ChiralNaybrs,$j,$id) $naybr
      }
      for { set jj [expr $j+1] } { $jj < 8 } { incr jj }  {  
          set Mol(ChiralNaybrs,$jj,$id) "" }
      set ii [lsearch [list positiv negativ both] [lindex $dict(chirality) $i]]
      if { $ii >= 0 } {
        set Mol(Chirality,$id) [lindex $sketch_data(chirality) $ii]
      } else {
        set Mol(Chirality,$id) [lindex $dict(chirality) $i]
      }
    } else {
      incr nch
      set Mol(ChiralCentre,$nch) $centre
      set j -1; foreach naybr [lindex $dict(neighbours) $i] { incr j
        set Mol(ChiralNaybrs,$j,$nch) $naybr
      }
      for { set jj [expr $j+1] } { $jj < 8 } { incr jj }  {  
          set Mol(ChiralNaybrs,$jj,$nch) "" }
      set ii [lsearch [list positiv negativ both] [lindex $dict(chirality) $i]]
      if { $ii >= 0 } {
        set Mol(Chirality,$id) [lindex $sketch_data(chirality) $ii]
      } else {
        set Mol(Chirality,$id) [lindex $dict(chirality) $i]
      }
      set Mol(Chirality,$nch) $Mol(Chirality,$id)
    }
  }
  set  Mol(nChiral) $nch
}

#-----------------------------------------------------------------------
proc sketch_apply_dict_plane { dictVar monomer } {
#-----------------------------------------------------------------------
  upvar #0 $dictVar dict
  global Mol

# Use plane data read from cif geometry file into the temporary dict array
# Append this to the Mol plane data

  if { $dict(nplane) == 0 } { return }
  set np  $Mol(nPlane)
  for { set n 1 } { $n <= $dict(nplane) } { incr n } {
    if { [ElementExists $dictVar  plane,$n] } {
      incr np
      #puts "applying plane $n $np"
      set Mol(plane,$np) $dict(plane,$n)
      set Mol(plane_dev,$np) $dict(plane_dev,$n)
    }
  }
  set  Mol(nPlane) $np
}


#-----------------------------------------------------------------------
proc sketch_add_bond { arrayname newat } {
#-----------------------------------------------------------------------
#Handle  user picking at existing atom (with left mouse button)
  upvar #0 $arrayname array
  global Mol

  if { [lsearch -exact [getbondedatoms $array(active_atom)] $newat] >= 0 } {
    WarningMessage "Active atom and selected atom are already bonded"
    return 0
  }

  incr Mol(nBonds); set nb $Mol(nBonds)
  set Mol(Bonds,$nb) "$array(active_atom) $newat"
  set Mol(Bondtype,$nb) 1
  sketch_create_bond_objects $arrayname -first $nb
  sketch_redisplay $arrayname
}

#-----------------------------------------------------------------------
proc set_active_atom { arrayname atno { mode 0 } } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array
  global Mol

#  puts "set_active_atom $atno  $mode"

  if { $mode > 0 } {
# Can have > 1 active atoms
    if { $atno == -1 } {
      foreach atno $array(active_atom) {
        $array(current_canvas) itemconfigure name$atno -fill $Mol(Colour,$atno)
        $array(current_canvas) dtag name$atno active_atom
      }
      set array(active_atom) ""
    } elseif { $atno == 0 } {
    } elseif { $mode == 2 } {
# double click on atom so set whole fragment active
      MolFindFragments
      set ifrag $Mol(frag,$atno)
# Toggle all atoms in fragment to opposite state of the picked atom
      if  { [lsearch -exact $array(active_atom) $atno] >= 0 } {
# If atom is in fragment and in ative_atom list then remove it from 
# the active_atom list
        for { set j 1 } { $j <= $Mol(nAtoms) } { incr j } {
          if { $Mol(frag,$j) == $ifrag && 
             [set i [lsearch $array(active_atom) $j]] >= 0 } {
             set t_active [lreplace $array(active_atom) $i $i ]
             set array(active_atom) $t_active
             $array(current_canvas) dtag name$j active_atom
          }
        }
      } else {
        for { set j 1 } { $j <= $Mol(nAtoms) } { incr j } {
          if { $Mol(frag,$j) == $ifrag && \
		[lsearch $array(active_atom) $j] < 0 } {
            lappend array(active_atom) $j
            $array(current_canvas) addtag active_atom withtag name$j
          }
        }
      }
#      puts "active_atom $array(active_atom)"
    } elseif { [set iat [lsearch $array(active_atom) $atno]] >= 0 } {
# Have picked a current active atom so deactivate
      set array(active_atom) [lreplace $array(active_atom) $iat $iat]
      $array(current_canvas) itemconfigure name$atno -fill $Mol(Colour,$atno)
      $array(current_canvas) dtag name$atno active_atom
    } else {
      lappend array(active_atom) $atno
      $array(current_canvas) addtag active_atom withtag name$atno
    }
# Get the centre of the active atoms (to use in transformations)
    sketch_active_atom_centre $arrayname

    if { $array(mouse_mode) == "plane" } { 
      sketch_update_plane_table $arrayname sketch_plane
    }

  } else {

    foreach i $array(active_atom) {
      $array(current_canvas) itemconfigure name$i -fill $Mol(Colour,$i) }

# set the new active_atom
    if { $atno > 0 } {
      set array(active_atom) $atno
    } else {
      set array(active_atom) ""
    }
# Change the tag to new active atom
    $array(current_canvas) dtag active_atom active_atom
    $array(current_canvas) addtag active_atom withtag name$atno
  }

# Update the message line if we are in edit mode  
  if { [StringSame edit $array(mouse_mode)] } { sketch_set_message $arrayname edit } 
}

#-----------------------------------------------------------------------
proc getbondedatoms { aa } {
#-----------------------------------------------------------------------
  global Mol
  set atlist {}
  for { set i 1 } { $i <= $Mol(nBonds) } { incr i } {
    if { [set ii [lsearch -exact $Mol(Bonds,$i)  $aa]] >= 0 } { 
      lappend atlist [lindex $Mol(Bonds,$i) [expr 1 - $ii] ]
    }
  }
#  puts "getbondedatoms $atlist"
  return $atlist
}

#-----------------------------------------------------------------------
proc sketch_setup { typedefVar arrayname } { 
#-----------------------------------------------------------------------
  upvar #0 $typedefVar typedef

  set typedef(_mouse_buttons) { menu { 1 2 3 } }

  if { [catch { package require BLT } ] } {
    WarningMessage "Can not run Monomer Library Sketcher without the BLT extension to Tcl/Tk installed.  See your system manager or the CCP4i installation documentation."
    return 0
  }

  return 1

}

#-----------------------------------------------------------------------
proc sketch_task_window { arrayname } {
#-----------------------------------------------------------------------
# The 'main' program invoked from the main ccp4i interface
  upvar #0 $arrayname array
  global system
  global configure
  global sketch_data

# puts "sketch_task_window $arrayname"

# Initialise the data used for display (eg atom colours) and geometry
# of sketch fragments
  if { ![ElementExists sketch_data loaded] } {Initialise_sketch_data }

  set sketch_data(sketch_array) $arrayname

# Initialise the status parameters
  if { ![ElementExists $arrayname param_init ] } { 
    InitialiseArray  [SearchPath TOP sketch sketch.def] $arrayname sketch
    sketch_font $arrayname
    set array(param_init) 1
    set array(current_xoff) [expr $array(canvas_width) / 2.0 ]
    set array(current_yoff) [expr $array(canvas_height) / 2.0 ]
    set array(ifpdbin) 0
    set array(ifeditedplane) 0
# Beware divide by zero
    if { [catch {set array(current_scale) \
         [expr $array(half_winsize) / $array(mol_max_extent)]} ] } {
      set array(current_scale) 1.0
    }

# parameters controling the vitual trackball
    trackball_init $arrayname
# Initially in 2D
    set dictionary(TASK_TITLE) "Create Library Description"

  }

  set array(active_atom) ""
  set array(edit_atom) 0
  set array(edit_mode) 0
  set array(edit_widget) ""
  set array(edit_plane) 0
  set array(centring) [list 0.0 0.0 0.0]

  set array(shift_block) 0
  set array(TABLE_OPEN) 0

# Create the Viewer

  set w .sketch
  if { [winfo exists $w] } {   return 0 }
  OpenGridWindow $arrayname .sketch "Monomer Library Sketcher" sketch  \
	-menu [list [list file File] [list edit Edit] ] \
        -help [SearchPath HELP modules sketcher.html] \
	-target sketcher

  set array(CHILDREN) ""

# Make the message bar two lines heigh
  $w.mesbar.l1 configure -height 2

# Define the pull-down menus

  $w.menu.file.m add cascade -label "Read File" \
	-background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
	-menu $w.menu.file.m.read

  menu .sketch.menu.file.m.read   -tearoff 0

  $w.menu.file.m.read add command -label "Load Monomer from Library" \
        -background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
        -command "RunTask load_monomer -module sketch -def [SearchPath TOP sketch load_monomer.def] "
  $w.menu.file.m.read add command -label "Read Library File" \
        -background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
        -command "RunTask load_monomer -module sketch -def [SearchPath TOP sketch load_monomer.def] -args -onemollib"
  $w.menu.file.m.read add command -label "Read PDB File" \
	-background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
	-command "sketch_open_file $arrayname PDB"
  $w.menu.file.m.read add command -label "Read mmCIF File" \
	-background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
	-command "sketch_open_file $arrayname CIF"
  $w.menu.file.m.read add command -label "Read Sybyl MOL2/SDF File" \
        -background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
        -command "sketch_run_dictionary $arrayname 1 MOL2"
  $w.menu.file.m.read add command -label "Read SMILES File" \
        -background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
        -command "sketch_run_dictionary $arrayname 1 SMILES"
  $w.menu.file.m.read add command -label "Read CCP4i Def File" \
        -background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
        -command "sketch_open_file $arrayname DEF"
  $w.menu.file.m.read add command -label "Read Geometry File" \
        -background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
        -command "sketch_open_file $arrayname DICT"

  $w.menu.file.m add cascade -label "Save to File" \
        -background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
        -menu $w.menu.file.m.write
  menu .sketch.menu.file.m.write   -tearoff 0

    $w.menu.file.m.write add command -label "Save as CCP4i Def File" \
        -background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
        -command "sketch_write_def_file $arrayname"

    $w.menu.file.m.write add command -label "Save coordinates to CIF file" \
        -background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
        -command "sketch_open_write_file $arrayname CIF"

  $w.menu.file.m add command -label "Create Library Description" \
    -font $configure(FONT_REGULAR) \
    -background $configure(COLOUR_PALE) \
    -command "sketch_run_dictionary $arrayname 1"

  $w.menu.file.m add command -label "Add Description to Library" \
    -font $configure(FONT_REGULAR) \
    -background $configure(COLOUR_PALE) \
    -command "RunTask adddict -module sketch -def [SearchPath TOP sketch adddict.def] "


  $w.menu.file.m add command -label "Show Web Resources" \
     -background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
        -command "sketch_databases"


  $w.menu.file.m add command -label "Close Sketcher" \
        -background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
	-command "sketch_end_plane_visual $arrayname sketch_plane
                     CloseWindow $arrayname -window $w"

  $w.menu.edit.m add command -label "Edit Planar Group Definitions" \
        -background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
        -command "sketch_edit_plane $arrayname"

  $w.menu.edit.m add command -label "Regularise Structure" \
        -background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
        -command "sketch_run_dictionary $arrayname 0" 


  $w.menu.edit.m add command -label "Delete All Atoms" \
        -background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
        -command "sketch_delete_mol $arrayname
                  sketch_redisplay $arrayname
                  sketch_update_table $arrayname -refresh
                  sketch_update_chiral_table  $arrayname -refresh"

  $w.menu.edit.m add command -label Preferences \
	-background $configure(COLOUR_PALE) \
        -font $configure(FONT_REGULAR) \
        -command "sketch_edit_preferences $arrayname"


  grid columnconfigure .sketch.main 0 -weight 0
  grid columnconfigure .sketch.main 1 -weight 1
  grid columnconfigure .sketch.main 2 -weight 0
  grid rowconfigure .sketch.main  0 -weight 1
  set m [frame .sketch.main.m -relief sunken  ]
  set array(canvas_frame) [set v [frame .sketch.main.v]]
  set array(right_frame) [set r [frame .sketch.main.r -relief sunken ] ]
  grid $m -row 0 -column 0 -sticky nwe
  grid $v -row 0 -column 1 -sticky nswe
  grid columnconfigure .sketch.main.v 0 -weight 1
  grid rowconfigure .sketch.main.v 0 -weight 1
  grid $r -row 0 -column 2 -sticky nswe
  set array(edit_frame) [set e [frame .sketch.main.r.e ] ]
  set array(chiral_frame) [set c [frame .sketch.main.r.c ] ]
  grid $e -row 0 -column 0 -sticky nsew
  grid $c -row 1 -column 0 -sticky nsew
  grid columnconfigure $r 0 -weight 1
  grid rowconfigure $r 0 -weight 4
  grid rowconfigure $r 1 -weight 1
  

# Define the left hand edit menu

  set bb $m.b0
    button $bb \
     -text "Do nothing" \
     -command "sketch_update_edit_mode $arrayname 0 $bb" \
	-background $configure(COLOUR_CONTRAST) \
        -activebackground $configure(COLOUR_CONTRAST)

  grid $bb -row 0 -column 0 -sticky nwe  -columnspan 2
  SetMessage $arrayname $bb "Switch off all edit functions\n"
  set array(edit_widget) $bb

#
# Draw the edit buttons
#
  set button_scale 40x20

  set i 0; foreach pair [list \
    [list alic 1 "Add a C atom\nHold down shift key and click close to active atom with left mouse button"   bond B "Add a bond\nHold down shift key and click on atom to be bonded to active atom with left mouse button" ] \
    [list 5ring 5 "Add a 5-membered ring\nHold down shift key and click close to active atom with left mouse button" \
	3ring 3 "Append fragment of 5-membered ring to existing ring.  Active atom is one point of attachment\nHold down shift key and on other point of attachment with left mouse button" ] \
    [list 6ring 6 "Add a 6-membered ring\nHold down shift key and click close to active atom with left mouse button" \
	4ring 4 "Append fragment of 6-membered ring to existing ring. The active atom is one point of attachment\n Hold down shift key and click on other point of attachment with left mouse button"]  \
    [list delc del_atom "Delete atom\nHold down shift key and click on atom with left mouse button." delbond del_bond "Delete bond\nHold down shift key and click on bond with left mouse button." ] ] { 

    incr i

    set bb $m.l$i
    button $bb \
     -bitmap @[SearchPath TOP icons [lindex $pair 0]_$button_scale.xbm] \
     -command "sketch_update_edit_mode $arrayname [lindex $pair 1] $bb"

    grid $bb -row $i -column 0 -sticky nwe
    SetMessage $arrayname $bb "[lindex $pair 2]"

    if { [lindex $pair 2] != "" } { 
      set bb $m.r$i
      button $bb  \
       -bitmap @[SearchPath TOP icons [lindex $pair 3]_$button_scale.xbm] \
       -command "sketch_update_edit_mode $arrayname [lindex $pair 4] $bb"
       grid $bb -row $i -column 1 -sticky nwe
       SetMessage $arrayname $bb "[lindex $pair 5]"
    }
  }


  incr i; set bb $m.b$i
   button $bb \
     -text "Undo last edit" \
     -foreground gray -activeforeground gray \
     -command "sketch_undo $arrayname"

  grid $bb -row $i -column 0 -sticky nwe  -columnspan 2
  SetMessage $arrayname $bb "Undo the last edit function\n"
  set array(undo_widget) $bb

   incr i; set bb $m.b$i
   button $bb -text "Recentre View" \
    -font $configure(FONT_REGULAR) \
    -background $configure(COLOUR_PALE) \
    -command "sketch_resetview $arrayname 
		sketch_redisplay $arrayname"

  grid $bb -row $i -column 0 -sticky nwe  -columnspan 2
  SetMessage $arrayname $bb "Put monomer in centre of screen\n"

# Draw the Mouse mode buttons
  incr i 2
  set ll [label $m.b$i -text "Mouse mode"]
  grid $ll -row $i -column 0 -sticky nwe  -columnspan 2
  set array(mouse_mode_buttons) $ll

  set mouse_list [list [list "Edit Monomer" edit] \
		  [list "Move Fragment" frag] ]


  foreach mode $mouse_list {
    incr i
    set rb [radiobutton $m.rb$i \
		-text [lindex $mode 0] \
		-variable [subst $arrayname](mouse_mode) \
		-value [lindex $mode 1] \
		-command "sketch_change_mouse_mode $arrayname" \
		-anchor w \
		-font $configure(FONT_REGULAR) ]
    if { ![regexp WINDOWS $system(OPSYS)] } {
        $rb configure -selectcolor $configure(COLOUR_BOLD) }
    grid $rb -row $i -column 0 -sticky nwe  -columnspan 2
    lappend array(mouse_mode_buttons) $rb
  }

# Create the molecule display canvas 

  sketch_create_canvas $arrayname canvas1
  sketch_select_canvas $arrayname canvas1
  sketch_set_message $arrayname $array(mouse_mode)
  sketch_flash_active $arrayname 1

# Create the edit table on RHS of Sketcher window

  sketch_create_table $arrayname

# Either initialise the Mol array or draw any already loaded molecule
  global Mol
  if { ![ElementExists Mol nAtoms] } {
    InitialiseArray [SearchPath TOP sketch Mol.def] Mol Mol
  } else {
    sketch_create_name_label $arrayname
    sketch_create_bond_objects $arrayname
    sketch_create_atom_objects $arrayname
    sketch_redisplay $arrayname
    set_active_atom $arrayname $Mol(nAtoms)
  }

}

#-------------------------------------------------------------------------
proc sketch_set_offset { arrayname } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(canvas_width) [$array(current_canvas) cget -width]
  set array(canvas_height) [$array(current_canvas) cget -height]

  set array(half_winsize) [ expr [min \
		$array(canvas_width) $array(canvas_height)] / 2.0 ]

  set array(current_xoff) [expr $array(canvas_width) / 2.0 ]
  set array(current_yoff) [expr $array(canvas_height) / 2.0 ]
}

#-------------------------------------------------------------------------
proc sketch_create_canvas { arrayname cname } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array
# Create a canvas 

  set array($cname) [canvas $array(canvas_frame).$cname \
        -width $array(canvas_width) -height $array(canvas_height) \
        -bg black ]

  set c $array($cname)

# set a flag to block the trackballing if the shift button is depressed
  bind $array(canvas_frame) <Shift-Enter> \
                "trackball_keypress $arrayname press Shift"
  bind $array(canvas_frame) <Control-Enter> \
                "trackball_keypress $arrayname press Control"
  bind $array(canvas_frame) <Leave> \
                "trackball_keypress $arrayname release Shift"
  bind .sketch <KeyPress> "trackball_keypress $arrayname press %K"
  bind .sketch <KeyRelease> "trackball_keypress $arrayname release %K"


# virtual trackball binding jiggery-pokery from mjh
  bind $c <Control-Button-1> "trackball_scale $arrayname %W %x %y"
  bind $c <Control-B1-Motion> " trackball_scale_motion $arrayname  %x %y"
  bind $c <Control-ButtonRelease-1> "trackball_scale_release $arrayname %W"
  bind $c <Button-1> "trackball_rotate $arrayname %W %x %y"
  bind $c <B1-Motion> "trackball_rotate_motion $arrayname %x %y"
  bind $c <ButtonRelease-1> "trackball_rotate_release $arrayname %W"
  bind $c <Button-3> "trackball_translate $arrayname %W %x %y"
  bind $c <B3-Motion> "trackball_translate_motion $arrayname %x %y"
  bind $c <ButtonRelease-3> "trackball_translate_release $arrayname %W"

  switch $array(mouse_mode) \
  edit {
    sketch_edit_bindings $array($cname) $arrayname
  } frag {
    sketch_frag_bindings $array($cname) $arrayname
  }

}

#-----------------------------------------------------------
proc sketch_edit_bindings { cname arrayname } {
#-----------------------------------------------------------
# Shift modified means do some edit function
  bind $cname <Shift-Button-1> \
        "sketch_button_add $arrayname %x %y"
  bind $cname <Shift-Button-3>  \
        "sketch_button_edit_bond $arrayname %x %y"
  bind $cname <Control-Button-3> \
        "sketch_button_active $arrayname %x %y"
  bind $cname <Button-2> \
        "sketch_button_active $arrayname %x %y"

}

#-----------------------------------------------------------
proc sketch_frag_bindings { cname arrayname } {
#-----------------------------------------------------------
# And the fragment moving bindings
  bind $cname <Shift-Button-3> \
       "trackball_fragtran $arrayname %W %x %y"
  bind $cname <Shift-B3-Motion> \
       "trackball_fragtran_motion $arrayname %x %y"
  bind $cname <Shift-ButtonRelease-3> \
       "trackball_fragtran_release $arrayname %W"
  bind $cname <Shift-Button-1> \
       "trackball_fragrot $arrayname %W %x %y"
  bind $cname <Shift-B1-Motion> \
       "trackball_fragrot_motion $arrayname %x %y"
  bind $cname <Shift-ButtonRelease-1> \
       "trackball_fragrot_release $arrayname %W"
  bind $cname <Control-Button-3> \
        "sketch_button_active $arrayname %x %y 1"
  bind $cname <Control-Double-Button-3> \
        "sketch_button_active $arrayname %x %y  2"

}

#-----------------------------------------------------------
proc sketch_plane_bindings { cname arrayname } {
#-----------------------------------------------------------
# Shift modified means do some edit function
  bind $cname <Shift-Button-1> \
        "sketch_button_add $arrayname %x %y"
  bind $cname <Shift-Button-3>  \
        "sketch_button_edit_bond $arrayname %x %y"
  bind $cname <Control-Button-3> \
        "sketch_button_active $arrayname %x %y 1"
  bind $cname <Button-2> \
        "sketch_button_active $arrayname %x %y 1"

}



#-----------------------------------------------------------
proc sketch_select_canvas { arrayname cname } {
#-----------------------------------------------------------
  upvar #0 $arrayname array

  if { [ElementExists $arrayname current_canvas] } {
    grid forget $array(current_canvas) }
  set array(current_canvas) $array($cname)
  grid $array(current_canvas) -row 0 -column 0  -sticky nswe
}


#--------------------------------------------------------------
proc sketch_update_edit_mode { arrayname new_mode new_bb } {
#--------------------------------------------------------------
  global configure
  upvar #0 $arrayname array

  if { $array(edit_widget) != "" } {
    $array(edit_widget) configure -background $configure(COLOUR_BACKGROUND)
    $array(edit_widget) configure -activebackground $configure(COLOUR_BACKGROUND)
  }
  
  set array(edit_mode) $new_mode
  $new_bb configure -background $configure(COLOUR_CONTRAST)
  $new_bb configure -activebackground $configure(COLOUR_CONTRAST)
  set array(edit_widget) $new_bb

  sketch_set_message $arrayname $array(mouse_mode) 
}

#
#----------------------------------------------------------
proc sketch_delete_atom { arrayname atdel } {
#----------------------------------------------------------
# Delete atom number atdel
  upvar #0 $arrayname array
  global Mol

  if { $Mol(nAtoms) <= 0 } { return }

  sketch_mol_backup $arrayname

  if { $atdel < $Mol(nAtoms) } {
    for { set atno $atdel } { $atno < $Mol(nAtoms) } { incr atno } {
       set at2 [expr $atno + 1]
       set Mol(Name,$atno) $Mol(Name,$at2)
       set Mol(Element,$atno) $Mol(Element,$at2)
       set Mol(Type,$atno) $Mol(Type,$at2)
       set Mol(Charge,$atno) $Mol(Charge,$at2)
       set Mol(Colour,$atno) $Mol(Colour,$at2)
       switch $array(dimension)  \
       2 {
         set Mol(xy,$atno) $Mol(xy,$at2)
       } 3  {  
         set Mol(Coor,$atno) $Mol(Coor,$at2)
#         set Mol(XY) [lreplace $Mol(XY) $atno $atno ]
       }
       if  { [ElementExists Mol VdwRad,$atno] } {
         set Mol(VdwRad,$atno) $Mol(VdwRad,$at2)
         set Mol(BondRad,$atno) $Mol(BondRad,$at2)
       }
    }
  }

  set nbdel 0
  set nb $Mol(nBonds); while { $nb > 0 } {
    if { [lsearch -exact  $Mol(Bonds,$nb) $atdel] >= 0 } {
      sketch_delete_bond $nb
      incr nbdel
    } else {
      if { [lindex $Mol(Bonds,$nb) 0 ] > $atdel } {
        set Mol(Bonds,$nb) \
          [lreplace $Mol(Bonds,$nb) 0 0 [expr [lindex $Mol(Bonds,$nb) 0 ] -1 ] ] }
      if { [lindex $Mol(Bonds,$nb) 1 ] > $atdel } {
        set Mol(Bonds,$nb) \
          [lreplace $Mol(Bonds,$nb) 1 1 [expr [lindex $Mol(Bonds,$nb) 1 ] -1 ] ] }
    }
    incr nb -1
  }

  if { $array(active_atom) != "" && $array(active_atom) > $atdel }  {
    set_active_atom $arrayname [expr $array(active_atom) -1]
  }
# Just delete last atom & bond object since the rest will just be repositioned
  sketch_delete_objects $arrayname 1 $Mol(nAtoms) 1 $Mol(nBonds)
  incr Mol(nAtoms) -1
  incr Mol(nBonds) -$nbdel
  sketch_create_bond_objects $arrayname
  sketch_create_atom_objects $arrayname
  sketch_redisplay $arrayname
  sketch_update_table $arrayname -refresh

}

#----------------------------------------------------------
proc sketch_delete_bond { nbdel } {
#----------------------------------------------------------
  global Mol

  if { $nbdel < $Mol(nBonds) } {
    for { set nb $nbdel } { $nb < $Mol(nBonds) } { incr nb } {
      set nnb [expr $nb + 1]
      set Mol(Bonds,$nb) $Mol(Bonds,$nnb)
      set Mol(Bondtype,$nb) $Mol(Bondtype,$nnb)
    }
  }
}


#-----------------------------------------------------------------------
proc sketch_flash_active { arrayname state } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array 
  if { [winfo exists $array(current_canvas) ] } {
#Alternate atom label colour between black and white
    $array(current_canvas) itemconfigure active_atom \
	-fill [lindex [list black white ] $state]

    after $array(flash_delay) \
     [list sketch_flash_active $arrayname [expr 1 - $state]]
  }
}

#-------------------------------------------------------------------
proc sketch_open_file { arrayname filetype } {
#-------------------------------------------------------------------
  upvar #0 $arrayname array
  global dict
  global Mol

  set ifappend 0
  set ifselect 0
  set ifatnew 1
  set ifbdnew 1
  set ifchnew 1
  set table_refresh ""

# Set up the custom parameters for the file selection window
  set custom_text {}
  set custom_params {}
  if { $Mol(nAtoms) > 0 } {

    lappend custom_params [list IFINITIALISE _logical 1]
    append custom_script "CreateLine line \
          label {Read new fragment into Monomer Sketcher} -italic
        CreateLine line widget IFINITIALISE \
          message {By default new structure will be added to existing display} \
          label {Delete any currently displayed monomer} \n"
  }

  lappend custom_params [list IFHYDROGEN _logical 1]
  append custom_script "CreateLine line widget IFHYDROGEN \
          message {By default hydrogen atoms are not read} \
          label {Read in hydrogen atoms}\n"
  
  switch $filetype \
  PDB { 
    set ext *.pdb
    lappend custom_params [list SEL_RESTYPE _text {}] \
                          [list SEL_CHAIN _text {} ] \
                          [list SEL_RESID _text {} ]
    append custom_script "CreateLine line  \
                label {Select residue type} \
                widget SEL_RESTYPE -width 6 \
                label {and/or chain} \
                widget SEL_CHAIN -width 4 \
                label {residue id} \
                widget SEL_RESID -width 6\n"
  } CIF {
    set ext *.cif
  } MOL2 {
    set ext *.mol2
  } DICT {
    if { $Mol(nAtoms) <= 0 } {
      WarningMessage "You can not read the geometry file with no atoms displayed"
      return 0
    }
    set custom_params {}
    set custom_script {}
    lappend custom_params [list MONOMER _text {}]
    append custom_script "CreateLine line  \
		label {(Optional) name of monomer in the file} \
		widget MONOMER"
    set ext *.cif
  } DEF {
    set ext *.def
  }

  if { ![SelectFile fileout "Select File for Sketcher" \
        -return  [list fullpath filename defdir] \
	-format $filetype -filter $ext \
	-custom $custom_params $custom_script ]  } {
    return 0
  }

  set ii -1
  incr ii; set file [lindex $fileout $ii]
  incr ii; set filename [lindex $fileout $ii]
  incr ii; set dir [lindex $fileout $ii]

  if { [regexp DICT $filetype] } {
    incr ii; set monomer [lindex $fileout $ii]
  } else {

  if { $Mol(nAtoms) > 0 } {
    incr ii
    if { [ set ifappend [expr 1 - [lindex $fileout $ii]]] } { 
      set ifatnew [expr $Mol(nAtoms)  +1 ]
      set ifbdnew [expr $Mol(nBonds)  +1 ]
      set ifchnew [expr $Mol(nChiral)  +1 ]
    } else {
      sketch_delete_mol $arrayname 
      set table_refresh "-refresh"
    }
  }

  incr ii; if {[lindex $fileout $ii] } { 
             set nohyd ""
           } else {
             set nohyd -nohyd
           }
             
  if { [regexp PDB $filetype] } {
    incr ii; set sel_params [lrange $fileout $ii [expr $ii + 2] ]
    incr ii 2
  }

# End of the the not DICT branch
  } 

  global tmp_dict

  switch $filetype \
  PDB {
    set pdbout [MolReadPDB Mol $file -select $sel_params $nohyd]
    set status [lindex $pdbout 0]
    if { $status } {
      sketch_3d_properties -first $ifatnew
      set monomer {}
      # Either read a pre-existing geometry file or try running Libcheck
      # to create one
      if {  ([set ifgeomfile [sketch_geom_filename $file geomfile ]] &&
             [StringSame Yes [ChooseOptionDialog "Read Geometry Library File" "Read Lib" \
	  "A geometry library file exists: $geomfile
Read the geometry information from this file?" [list No Yes] -default 1]] &&
             [sketch_read_cifdict $geomfile tmp_dict monomer ] ) 
          || ( [sketch_run_libcheck $file $filetype geomfile ] &&
               [sketch_read_cifdict $geomfile tmp_dict monomer ] ) } {
        sketch_apply_atomtypes tmp_dict $monomer
        sketch_apply_dict_bonds tmp_dict $monomer -first $ifatnew
        sketch_apply_dict_chiral tmp_dict $monomer
        sketch_apply_dict_plane tmp_dict $monomer
      } else {
        # If the above fails then use sketcher code to find 
        # bonds and chiral centres
        sketch_3d_bonds -first $ifatnew
        if { [MolFindChiralCentres Mol tmp_dict] > 0 } {
          sketch_apply_dict_chiral tmp_dict {}
        }
      }
    }
    # If ther is no geometry file then offer to create one
    if { $status && !$ifgeomfile } {
      if { [StringSame Yes [ChooseOptionDialog "Run Libcheck?" "libcheck" \
        "Libcheck can generate molecule description from just the PDB file. \
         Do you want to run Libcheck now?" \
         [list "No" "Yes"] ] ] } {
        sketch_run_dictionary $arrayname 1 
      }
    }
  } CIF {
    if { [set status [MolReadCif Mol $file $nohyd]] } { 
      sketch_3d_properties -first $ifatnew
      set monomer {}
      # Either read a pre-existing geometry file or try running Libcheck
      # to create one
      if {  ([set ifgeomfile [sketch_geom_filename $file geomfile ]] &&
             [StringSame Yes [ChooseOptionDialog "Read Geometry Library File" "Read Lib" \
	  "A geometry library file exists: $geomfile
Read the geometry information from this file?" [list No Yes] -default 1]] &&
             [sketch_read_cifdict $geomfile tmp_dict monomer ] ) 
          || ( [sketch_run_libcheck $file $filetype geomfile ] &&
               [sketch_read_cifdict $geomfile tmp_dict monomer ] ) } {
        sketch_apply_atomtypes tmp_dict $monomer
        sketch_apply_dict_bonds tmp_dict $monomer -first $ifatnew
        sketch_apply_dict_chiral tmp_dict $monomer
        sketch_apply_dict_plane tmp_dict $monomer
      } else {
        sketch_3d_bonds -first $ifatnew
      }
    }
      
  } DICT {
    set monomer {}
    global tmp_dict
    if { [set status [sketch_read_cifdict $file tmp_dict monomer]] } { 
        sketch_apply_atomtypes tmp_dict $monomer
        sketch_apply_dict_bonds tmp_dict $monomer -first $ifatnew
        sketch_apply_dict_chiral tmp_dict $monomer
        sketch_apply_dict_plane tmp_dict $monomer
        set table_refresh -refresh
    }
  } DEF {
    if { $ifappend } {
      global Moltmp
      set status [InitialiseArray $file Moltmp Mol]
      sketch_append_moltmp Mol Moltmp
      unset Moltmp
    } else {
      set status [InitialiseArray $file Mol Mol]
    }
    sketch_3d_properties -first $ifatnew
  }

  catch "unset tmp_dict"

  if { !$status } {
     sketch_mol_backup $arrayname restore
  } else {
    set array(dimension) $Mol(dimension)
  }

  if { $ifatnew == 1 } { 
    if { [regexp PDB $filetype] } {
      set array(ifpdbin) 1
      set array(pdbin) $filename
      set array(dir_pdbin) $dir
      set array(pdbin_select) [lrange $pdbout 1 3]
    } else {
      set array(ifpdbin) 0
    }
  }

  sketch_3d_bbox $arrayname -first $ifatnew
  sketch_update_table $arrayname -first $ifatnew $table_refresh
  sketch_update_chiral_table $arrayname -first $ifchnew $table_refresh
  sketch_create_name_label $arrayname
  sketch_create_bond_objects $arrayname -first $ifbdnew
  sketch_create_atom_objects $arrayname -first $ifatnew
  sketch_redisplay $arrayname
}

#-------------------------------------------------------------------------
proc sketch_open_write_file { arrayname filetype } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array
  global Mol

  switch $filetype \
  PDB {
    set ext *.pdb
  } CIF {
# Prompt user to provide an id for the monomer
    if { [ElementExists Mol monomer_id ] } {
      set monomer_id $Mol(chem_comp_id)
    } else { set monomer_id {} }
    lappend custom_params [list MONOMER_ID _text $monomer_id] 
    append custom_script "CreateLine line  \
                label {Enter the library id for the monomer} \
                widget MONOMER_ID -width 6 -oblig"
    set ext *.cif
  } MOL2 {
    set ext *.mol2
  }

  if { ![SelectFile fileout "Select Output File for Sketcher" \
	-unknown \
        -format $filetype -filter $ext \
	-custom $custom_params $custom_script ] } { return 0 }

  switch $filetype \
  CIF {
    if { [lindex $fileout 1] != "" } {
      MolWriteCifCoords Mol [lindex $fileout 0] -id [lindex $fileout 1]
    } else {
      MolWriteCifCoords Mol [lindex $fileout 0]
    }
 
  }
}

#-------------------------------------------------------------------------
proc sketch_geom_filename { file geomfileVar } {
#-------------------------------------------------------------------------
  upvar $geomfileVar geomfile
# Attempt ot deduce name of cif geom description file from name of 
# coordinate file
  set geomfile [file rootname $file]_mon_lib.cif
  return [file exists $geomfile ]
}
  
#-------------------------------------------------------------------------
proc sketch_write_def_file { arrayname args } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array
  global Mol

# Write the current molecule in array Mol to a def file

  set file {}
  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    file {
      incr n; set file [lindex $args $n]
    }
    incr n
  }

# undo the centering transformation before writing out

  MolTranslate Mol [vscal -1 $array(centring)]

  if { $file == "" } { SelectFile file -unknown -filter *.def }
  if { [lindex $file 0] != "" } { SaveArray Mol [lindex $file 0] Mol }

  MolTranslate Mol $array(centring)

}

#-------------------------------------------------------------------------
proc sketch_mol_backup { arrayname { mode save } } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array
  global Mol
  global Mol_backup

  switch -regexp $mode \
  save {
    catch "unset Mol_backup"
    foreach ele [array names Mol *] {
      set Mol_backup($ele) $Mol($ele)
    }
    set array(Mol_backedup) 1
    $array(undo_widget) configure -foreground black -activeforeground black
  } restore {
    if { ![ElementExists $arrayname Mol_backedup] || !$array(Mol_backedup) } {
      return 0
    }
    catch "unset Mol"
    foreach ele [array names Mol_backup *] {
      set Mol($ele) $Mol_backup($ele)
    }
    set array(Mol_backedup) 0
    $array(undo_widget) configure -foreground gray -activeforeground gray
  }

  return 1
}

#-------------------------------------------------------------------------
proc  sketch_undo { arrayname } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array
  global Mol

  if {  [sketch_mol_backup $arrayname restore ] } {
    sketch_delete_objects $arrayname
    sketch_update_table $arrayname  -refresh
    if { $Mol(dimension) == 3 } { sketch_3d_bbox $arrayname }
    sketch_create_bond_objects $arrayname
    sketch_create_atom_objects $arrayname
    sketch_redisplay $arrayname
    set array(active_atom)  ""
  } else {
    WarningMessage  "There is no saved structure"
  }

}

#--------------------------------------------------------------------
proc sketch_3d_properties { args } {
#--------------------------------------------------------------------
  global Mol 
  global sketch_data
  set first 1
  set n 0; set nargs [llength $args]
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    first {
      incr n; set first [lindex $args $n]
    }
    incr n
  }
  for {set i $first } { $i <= $Mol(nAtoms) } {incr i} {
	set e [string trim $Mol(Element,$i)]
	if {  $e == "" || ![ElementExists sketch_data $e ] } { set e Default } 
	set Mol(Colour,$i) $sketch_data($e,Colour)
	set Mol(BondRad,$i) $sketch_data($e,BondRad)
#	set Mol(VdwRad,$i) $sketch_data($e,VdwRad)
  }
}

#--------------------------------------------------------------------
proc sketch_3d_bbox { arrayname args } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array
  global Mol

  set first 1
  set n 0; set nargs [llength $args]
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    first {
      incr n; set first [lindex $args $n]
    }
    incr n
  }

  if { $first > 1 } {

# A new fragment has been imported - first atom number is first
# Put the new fragment 'next' to the existing fragment
# shifted in +x direction

# get extent of the pre-existing atoms
    MolBoundingBox Mol minbound maxbound ave -last [expr $first -1]
    set old_extent [vsub $maxbound $minbound]

# and extent of the new atoms
    MolBoundingBox Mol minbound maxbound ave -first $first
    set new_extent [vsub $maxbound $minbound]

    set xshift [expr \
    ( [lindex $old_extent 0] + [lindex $new_extent 0] + 3.0 ) / 2.0 ]
    set centring [ vadd [vscal -1 $ave] [list $xshift 0.0 0.0 ] ]

    MolTranslate Mol $centring -first $first

  }

# Recentre all atoms

  MolBoundingBox Mol minbound maxbound ave
  set extent [vsub $maxbound $minbound]

  sketch_set_offset $arrayname
  set array(centring) [vscal -1 $ave]
  set array(mol_extent)  $extent
  set array(mol_max_extent) [eval [concat max $extent ] ]

  MolTranslate Mol $array(centring)

}


#--------------------------------------------------------------------
proc sketch_3d_bonds { args } {
#--------------------------------------------------------------------
  global Mol

  set first 1
  set last $Mol(nAtoms)
  set n 0; set nargs [llength $args]
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    first {
      incr n; set first [lindex $args $n]
    } last {
      incr n; set last [lindex $args $n]
    }
    incr n
  }

  set nB $Mol(nBonds)
  for {set i $first} {$i <= $last } {incr i} {
	set apos $Mol(Coor,$i) 
	set arad $Mol(BondRad,$i)
	for {set j [expr $i + 1]} { $j <= $last } {incr j } {
         
		set d [vdist $apos $Mol(Coor,$j)] 
		set rad [expr $Mol(BondRad,$j) + $arad]

		if { $d < $rad } {
			incr nB
			set Mol(Bonds,$nB) "$i $j"
                        set Mol(Bondtype,$nB) 1
		}
	}
  }
  set Mol(nBonds) $nB
}

#------------------------------------------------------------------
proc sketch_create_bond_objects { arrayname args } {
#------------------------------------------------------------------
  upvar #0 $arrayname array
  global configure
  global Mol

  set first 1
  set last $Mol(nBonds)
  set nargs [llength $args]; set n 0
  while  { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    first {
      incr n; set first [lindex $args $n]
    } last {
      incr n; set last [lindex $args $n]
    }
    incr n
  }

  set c $array(current_canvas)

  if { [info patch] >= 8.3 } {
    for { set i $first } { $i <= $last } { incr i } {
      if { $Mol(Bondtype,$i) <= 3 } {
        for { set j 1 } { $j <= $Mol(Bondtype,$i) } { incr  j } {
          eval $c create line 0 0 0 0 \
            -width $array(linewidth) -tags {bond$i.$j} -fill white 
        }
      } elseif  { $Mol(Bondtype,$i) == 6 } {
        eval $c create line 0 0 0 0 \
            -width $array(linewidth) -tags {bond$i.1} -fill white -dash .
      } elseif { $Mol(Bondtype,$i) == 4 } {
        eval $c create line 0 0 0 0 \
            -width $array(linewidth) -tags {bond$i.1} -fill white -dash .
        eval $c create line 0 0 0 0 \
            -width $array(linewidth) -tags {bond$i.2} -fill white -dash .
      } else {
        eval $c create line 0 0 0 0 \
            -width $array(linewidth) -tags {bond$i.1} -fill white -dash -
        eval $c create line 0 0 0 0 \
            -width $array(linewidth) -tags {bond$i.2} -fill white -dash -
      }
    }

  } else {
 
 #Version Tk does not suport -dash
 # Make line width 1 to indicate
    set thin 1
    set col yellow
    for { set i $first } { $i <= $last } { incr i } {
      if { $Mol(Bondtype,$i) <= 3 } {
        for { set j 1 } { $j <= $Mol(Bondtype,$i) } { incr  j } {
          eval $c create line 0 0 0 0 \
            -width $array(linewidth) -tags {bond$i.$j} -fill white
        }
      } elseif  { $Mol(Bondtype,$i) == 6 } {
        eval $c create line 0 0 0 0 \
            -width $thin -tags {bond$i.1} -fill $col 
      } elseif { $Mol(Bondtype,$i) == 4 } {
        eval $c create line 0 0 0 0 \
            -width $thin -tags {bond$i.1} -fill $col
        eval $c create line 0 0 0 0 \
            -width $thin -tags {bond$i.2} -fill  white 
     } else {
        eval $c create line 0 0 0 0 \
            -width $thin -tags {bond$i.1} -fill $col
        eval $c create line 0 0 0 0 \
            -width $thin -tags {bond$i.2} -fill $col 
      }
    }
  }

}

#----------------------------------------------------------------
proc sketch_create_name_label { arrayname } {
#----------------------------------------------------------------
  upvar #0 $arrayname array
  global Mol

   eval $array(current_canvas) delete monomer_name_label
   set t "Monomer $Mol(chem_comp_id) from file $Mol(filename)"

   $array(current_canvas) create text 5 10  -anchor nw -text $t  \
	   -tags {monomer_name_label} \
           -font $array(font)  \
           -fill white

}

#------------------------------------------------------------------
proc sketch_label_bond_type { arrayname ib } {
#------------------------------------------------------------------
  upvar #0 $arrayname array
  global Mol

  if { [ElementExists $arrayname unlabel_bond_id] } {
    after cancel $array(unlabel_bond_id)
  }
  set t "Bond type set to: "
  append t [lindex  \
    [list single double triple deloc aromatic metal ] \
	[expr $Mol(Bondtype,$ib) -1] ]
  $array(current_canvas) create text 5 20  -anchor w -text $t  \
   -tags {label_bond_type} \
       -font $array(font)  \
        -fill white
  set array(unlabel_bond_id) [after 5000 "sketch_unlabel_bond_type  $arrayname "]
}

#------------------------------------------------------------------
proc sketch_unlabel_bond_type { arrayname } {
#------------------------------------------------------------------
  upvar #0 $arrayname array
  if { [winfo exists $array(current_canvas)] } {
    eval $array(current_canvas) delete label_bond_type
  }
  unset array(unlabel_bond_id)
}
#------------------------------------------------------------------
proc sketch_create_atom_objects { arrayname args } {
#------------------------------------------------------------------
  upvar #0 $arrayname array
  global configure
  global Mol

  set first 1
  set last $Mol(nAtoms)
  set nargs [llength $args]; set n 0
  while  { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    first {
      incr n; set first [lindex $args $n]
    } 
    incr n
  }

  set c $array(current_canvas)

#  for { set i $first } { $i <= $last } { incr i } {
#  $c create oval 0 0 0 0 \
#     -tags [list vdw vdw$i ] -fill $Mol(Colour,$i) -outl black
#  }

  for { set i $first } { $i <= $last } { incr i } {
    eval $c create text \
         0 0   -text {$Mol(Name,$i)} \
        -font $array(font) -tag  {name$i} \
	-fill $Mol(Colour,$i)
  }
  if { $array(active_atom) != "" } {
     foreach atno $array(active_atom) {
     eval $c addtag active_atom withtag name$atno }
  }

  update idletasks
}

#------------------------------------------------------------------
proc sketch_rename_atom_objects { arrayname {first_atom 1} } {
#------------------------------------------------------------------
  upvar #0 $arrayname array
  global configure
  global Mol

  set c $array(current_canvas)

  for { set i $first_atom } { $i <= $Mol(nAtoms) } { incr i } {
    eval $c itemconfigure {name$i} -text "$Mol(Name,$i)" -fill $Mol(Colour,$i)
  }
}



#--------------------------------------------------------------------
proc sketch_delete_objects { arrayname { first_atom 1 } { last_atom {} } \
	{ first_bond 1 } {last_bond {} } } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array
  global Mol
  set c $array(current_canvas)

  if { $last_atom == "" } { set last_atom $Mol(nAtoms) }
  if { $last_bond == "" } { set last_bond $Mol(nBonds) }

  if { $last_bond > 0 } {
    for { set i $first_bond } { $i <= $last_bond } { incr i } {
      eval $c delete {bond$i.1} {bond$i.2} {bond$i.3}
    }
  }
  if { $last_atom > 0 } {
    for { set i $first_atom } { $i <= $last_atom } { incr i } {
      eval $c delete {vdw$i}
      eval $c delete {name$i}
    }
  }

  update idletasks
  
}

#--------------------------------------------------------------------
proc sketch_resetview { arrayname } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array
# Recentre monomer in display

  if { $array(dimension) != 3 } { return }
  trackball_init $arrayname -norot
  sketch_3d_bbox $arrayname
  sketch_redisplay $arrayname

}

#--------------------------------------------------------------------
proc sketch_redisplay { arrayname { button {} } args} {
#--------------------------------------------------------------------
  upvar #0 $arrayname array
  global Mol
  set c $array(current_canvas) 
#  set sepa [expr $array(bond_separation) * $array(scale) ]
  set sepa $array(bond_separation)
  set half_sepa [expr $sepa * 0.5]


  if { [StringSame $button translate] } { return }
  if { $Mol(nAtoms) <= 0 } { return }

# Apply rotation and convert 3D coords to a list of 2D coords in Mol(XY)
# For 2D coords just copy to the Mol(XY)

  switch $array(dimension) \
  3 {
    sketch_3d_rotate $arrayname
  } 2 {
    sketch_2d_xy $arrayname
  }

  for { set i 1} { $i <= $Mol(nAtoms) } { incr i } {
    eval $c coords name$i [lrange [lindex $Mol(XY) $i] 0  1]
  }

  if { $Mol(nBonds) >  0 } { 
  for { set i 1} { $i <= $Mol(nBonds) } { incr i } {
    scan $Mol(Bonds,$i) "%s %s" a b
    set xa [lindex [lindex $Mol(XY) $a] 0]
    set ya [lindex [lindex $Mol(XY) $a] 1]
    set xb [lindex [lindex $Mol(XY) $b] 0]
    set yb [lindex [lindex $Mol(XY) $b] 1]
# For bond type 1 or 3 or 6 draw a central vector
    if { [lsearch [list 1 3 6] $Mol(Bondtype,$i)] >= 0 } {
      eval $c coords bond$i.1 $xa $ya $xb $yb }
# For Bondtypes not  1 or 6 draw two vector offset by the Bond_perp 
# distance scaled by the  bond_separation and scale parameters
    if { [lsearch [list 1 6] $Mol(Bondtype,$i)] < 0 } {
      scan $Mol(Bond_perp,$i) "%s %s" dx dy
      if { $Mol(Bondtype,$i) == 3 } {
        set  dx [expr $dx * $sepa]
        set  dy [expr $dy * $sepa]
        eval $c coords bond$i.2 \
          [expr $xa + $dy] \
          [expr $ya - $dx] \
          [expr $xb + $dy] \
          [expr $yb - $dx]
        eval $c coords bond$i.3 \
          [expr $xa - $dy] \
          [expr $ya + $dx] \
          [expr $xb - $dy] \
          [expr $yb + $dx]
      } else {
        set  dx [expr $dx * $half_sepa]
        set  dy [expr $dy * $half_sepa]
        $c coords bond$i.1 \
         [expr $xa + $dy] \
         [expr $ya - $dx] \
         [expr $xb + $dy] \
         [expr $yb - $dx]
        $c coords bond$i.2 \
         [expr $xa - $dy] \
         [expr $ya + $dx] \
         [expr $xb - $dy] \
         [expr $yb + $dx]
      }
    }
  } }

  if { $array(VDW) == 1 } {

	# the z-ordering
	set zord [lsort -index 2 -real [lrange $Mol(XY) 1 end] ]

	for { set i 1} { $i <= $Mol(nAtoms) } { incr i } {
		set j [lindex [lindex $zord $i] 3]

		$c dtag vdw$j vdw
		$c raise vdw vdw$j	
		$c addtag vdw withtag vdw$j

		scan [lindex $Mol(XY) $j] "%f %f" x y

		set rad [ expr $Mol(VDWscale) * $Mol(VdwRad,$j) ]
		$c coords vdw$j [expr $x - $rad] [expr $y - $rad] \
				[expr $x + $rad] [expr $y + $rad]  
	}
  }

# Scale and translate

  if { [catch {set scale [expr ( $array(half_winsize) / \
	$array(mol_max_extent)) * $array(scale) ]} ] } {
       set scale 1.0
  }
#  $c scale all [expr $array(canvas_width) / 2 ] \
#	[expr $array(canvas_height) / 2 ]  $scale $scale
  $c scale all 0.0 0.0  $scale $scale

  set xoff [expr ($array(canvas_width) / 2.0 ) + $array(xoff)]
  set yoff [expr ($array(canvas_height) / 2.0 ) + $array(yoff)]
  $c move all $xoff $yoff 

  set array(current_scale) $scale
  set array(current_xoff) $xoff
  set array(current_yoff) $yoff

}

#--------------------------------------------------------------------
proc sketch_2d_xy { arrayname } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array
  global Mol

  set XY NULL
  for {set i 1} { $i <= $Mol(nAtoms) } {incr i} {
    lappend XY [concat $Mol(xy,$i) 0.0 ]
  }
  set Mol(XY) $XY
}


#--------------------------------------------------------------------
proc sketch_3d_rotate { arrayname } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array
# adapted from mjh's java viewer applet code
  global Mol

  set xa [expr $array(xangle) / 180. * 3.1415 ]
  set ya [expr $array(yangle) / 180. * 3.1415 ]

  set c1 [expr cos($xa)]
  set s1 [expr sin($xa)]
  set c2 [expr cos($ya)]
  set s2 [expr sin($ya)]

  set XY NULL

  for {set i 1} { $i <= $Mol(nAtoms) } {incr i} {
	scan $Mol(Coor,$i) "%s%s%s" x y z

	set xx $x
	set yy [ expr $y * $c1 - $z * $s1 ]
	set zz [ expr $y * $s1 + $z * $c1 ]

	set x [expr $xx * $c2 - $zz * $s2]
	set y $yy 
	set z [expr $xx * $s2 + $zz * $c2]

	lappend XY [list $x $y $z ] 
  }
  set Mol(XY) $XY
# Reevaluate the perpendicular to the bond for bonds of order > 1
# so the multiple bond lines can be drawn
  for { set n 1 } { $n <= $Mol(nBonds) } { incr n } {
    if { $Mol(Bondtype,$n) > 1 } {
      scan $Mol(Bonds,$n) "%s%s" a b
      set dx [expr [lindex [lindex $XY $b] 0] - [lindex [lindex $XY $a] 0]]
      set dy [expr [lindex [lindex $XY $b] 1] - [lindex [lindex $XY $a] 1]]
      set denom [expr pow($dx*$dx + $dy*$dy , 0.5)]
      if { $denom > -0.00001 && $denom < 0.00001 } {
        set Mol(Bond_perp,$n) [list 0.0 0.0 ] 
      } else {
        set Mol(Bond_perp,$n) [list [expr $dx / $denom] [expr $dy / $denom] ]
      }
    }
  }
}


#--------------------------------------------------------------------
proc sketch_inv_3d_rotate { arrayname coord } {
#--------------------------------------------------------------------
#  upvar $rotcoordVar rotcoord
  upvar #0 $arrayname array

# Apply 'inverse' ie sreen-to-world transformation to coordinates
  global Mol

  set xa [expr $array(xangle) / -180. * 3.1415 ]
  set ya [expr $array(yangle) / -180. * 3.1415 ]

  set c1 [expr cos($xa)]
  set s1 [expr sin($xa)]
  set c2 [expr cos($ya)]
  set s2 [expr sin($ya)]

  foreach co $coord {
        set xx [lindex $co 0]
        set yy [lindex $co 1]
        set zz [lindex $co 2]
	set x [expr $xx * $c2 - $zz * $s2]
	set y $yy 
	set z [expr $xx * $s2 + $zz * $c2]

	set xx $x
	set yy [ expr $y * $c1 - $z * $s1 ]
	set zz [ expr $y * $s1 + $z * $c1 ]

	lappend rotcoord [list $xx $yy $zz ] 
  }
  return $rotcoord
}

#---------------------------------------------------------------------
proc sketch_move_fragment { arrayname button } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array
  global Mol

# Apply a translation to a fragment
# use the sketch_inv_3d_rotate procedure to convert the screen frame
# translation ot the world frame translation

  if { $Mol(nAtoms) <= 0 ||
         [llength $array(active_atom)] < 1 } { return }

  set trans [sketch_inv_3d_rotate $arrayname \
     [list [list $array(fragtran_x) $array(fragtran_y) 0.0 ] ] ]

  set t [lindex $trans 0]
  set tranx [expr [lindex $t 0] / $array(current_scale) ]
  set trany [expr [lindex $t 1] / $array(current_scale) ]
  set tranz [expr [lindex $t 2] / $array(current_scale) ]
  foreach i $array(active_atom) {
    set Mol(Coor,$i) [ list [expr [lindex $Mol(Coor,$i) 0] + $tranx ] \
		[expr [lindex $Mol(Coor,$i) 1] + $trany ] \
		[expr [lindex $Mol(Coor,$i) 2] + $tranz ] ]
  }
  sketch_redisplay $arrayname
  sketch_active_atom_centre $arrayname

}

#---------------------------------------------------------------------
proc sketch_rotate_fragment { arrayname button } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array
  global Mol

# Apply rotation transformation to moving fragment

  if { $Mol(nAtoms) <= 0 || 
         [llength $array(active_atom)] < 2 } { return }

# Convert to radians and get the sin/cosines
  set xa [expr $array(cntl_xangle) / 180. * 3.1415 ]
  set ya [expr $array(cntl_yangle) / 180. * 3.1415 ]

  set c1 [expr cos($ya)]
  set s1 [expr sin($ya)]
  set r1 [list 1.0 0.0 0.0 \
         0.0 $c1 [expr $s1 * -1.0] \
         0.0 $s1  $c1 ]
  set c2 [expr cos($xa)]
  set s2 [expr sin($xa)]
  set r2 [ list $c2 0.0 [expr $s2 * -1] \
	    0.0 1.0 0.0 \
            $s2 0.0 $c2 ]

#  puts "r1 $r1 r2 $r2"

#  set rot [sketch_inv_3d_rotate $arrayname \
#     [list [list $c1 $s1 0.0] [list $c2 $s2 0.0] ] ]
#  set rr  [lindex $rot 0]
#  set r1 [lindex $r1 0]
#  set r2 [lindex $r1 1]
#  set r3 [lindex $r1 2]

# Must move fragment to origin so it is rotating about
# its own centre of mass - then appply the rotation matrices

  foreach i $array(active_atom) {
    set new_coord [vadd $array(active_atom_centre) \
	[vmatmult $r2 \
        [vmatmult $r1 \
	[vsub  $Mol(Coor,$i) $array(active_atom_centre) ] ] ] ]
    set Mol(Coor,$i) $new_coord
  }
  sketch_redisplay $arrayname
}

#---------------------------------------------------------------------
proc gettemplate { mode pick guide1 guide2 guide3 \
	tmpltypeVar tmplxyVar tmplconnVar tmplchiralVar }  {
#---------------------------------------------------------------------
  upvar $tmpltypeVar tmpltype
  upvar $tmplxyVar tmplxy
  upvar $tmplconnVar tmplconn
  upvar $tmplchiralVar tmplchiral
  global sketch_data
  set rtod [expr 180 / 3.14]
  set scale 1
  set switch_conn 0

#  puts "mode $mode pick $pick guide1 $guide1 guide2 $guide2"

  set tmpltype {}
  set tmplxy {}
  set tmplconn {}

#  If there are no guide atoms just put fragment over pick position
  
  if { $guide1 == {} } {
    set shift [vsub $pick $sketch_data(centre,$mode)]
    foreach libatom $sketch_data(template,$mode) {
      lappend tmpltype "no_type"
      lappend tmplxy [vadd  $shift [vscal $scale [lindex $libatom 1]] ]
      lappend tmplconn [lindex $libatom 2]
      lappend tmplchiral ""
    }
    return 1
  } 

# get the translation to superpose centres of mass
  set transl [vcent $guide1 $guide2 ]
  set vt [vsub [lindex $sketch_data(guide,$mode) 1] \
		[lindex $sketch_data(guide,$mode) 0]]
  set scaled_g1 [vscal $scale [lindex $sketch_data(guide,$mode) 0]]
  set scaled_g2 [vscal $scale [lindex $sketch_data(guide,$mode) 1]]

# get the angle between the vectors
# there is alternative solution at 180 - $angl - try applying both and see 
# which places template guide atom closest to the molecule guide2  atom
  set vguide [vsub $guide2 $guide1]
  if { [catch {set angl [expr acos (   [vdotp $vt $vguide ]  / \
		( [vlen $vguide] * [vlen $vt] ) ) ] } ] } { return 0 }
  set dplus1 [vdist [vadd  $transl [vrot $angl $scaled_g1]] $guide1]
  set dplus2 [vdist [vadd  $transl [vrot $angl $scaled_g2]] $guide2]
  set dminus1 [vdist [vadd  $transl [vrot -$angl $scaled_g1]] $guide1]
  set dminus2 [vdist [vadd  $transl [vrot -$angl $scaled_g2]] $guide2]
#  puts "dplus1 $dplus1 dplus2 $dplus2 dminus1 $dminus1 dminus2 $dminus2"
  set d1 [expr $dplus1 + $dplus2]
  set d2 [expr $dminus1 + $dminus2]
  if { $d2 < $d1 } { set angl [expr $angl * -1.0] }


  set mirror 0
  if { $guide3 != "" && [ElementExists sketch_data centre,$mode] } {
    set scaled_centre [vscal $scale $sketch_data(centre,$mode) ]
    set dplus [vdist [vadd  $transl [vrot $angl $scaled_centre]] $guide3]
    set dmirror [vdist [vadd  $transl [vrot $angl [vmirror $scaled_centre x]]] $guide3]
    if { $dplus < $dmirror } { set mirror 1 }
#    puts "dplus $dplus dmirror $dmirror mirror $mirror"
  } 

  foreach libatom $sketch_data(template,$mode) {
#    lappend tmpltype [lindex $libatom 0]
    lappend tmpltype no_type
    if { $mirror } {
      lappend tmplxy [vadd  $transl [vrot $angl [vscal $scale \
		[vmirror [lindex $libatom 1] x] ]]]
    } else {
      lappend tmplxy [vadd  $transl [vrot $angl  \
		[vscal $scale [lindex $libatom 1]]]]
    }
    lappend tmplconn [lindex $libatom 2]
    lappend tmplchiral ""
  }

#  puts "gettemplate tmpltype $tmpltype tmplxy $tmplxy tmplconn $tmplconn"
  return 1
}

#------------------------------------------------------------------------------
proc Initialise_sketch_data { } {
#------------------------------------------------------------------------------
  global sketch_data

  set sketch_data(loaded) 1
  set sketch_data(monomers_loaded) 0

# Set the parameters used in display
  set elements {H C N O S P Default}
  set colours {white green blue red yellow purple cyan}
#  set covrad  {0.37 0.77 0.70 0.66 1.04 1.10 1.0}
  set bondrad {0.3 0.9 0.9 0.9 1.3 1.3 1.0}
#  set vdwrad  {1.2 1.85 1.5 1.4 1.85 1.9 1.8}



  for { set i 0 } { $i < [llength $elements]} {incr i} {
    set e [lindex $elements $i]
    set sketch_data($e) $e
    set sketch_data($e,Colour) [lindex $colours $i]
    set sketch_data($e,BondRad) [lindex $bondrad $i]
#    set sketch_data($e,CovRad) [lindex $covrad $i]
#    set sketch_data($e,VdwRad) [lindex $vdwrad $i]
  }

  set sketch_data(chem_comp_type) [list "non-polymer" \
                                        "L-peptide" \
                                        "D-peptide" \
                                        "DNA" \
                                        "RNA" \
                                        "D-saccharide 1,4 and 1,4 linking" \
                                        "L-saccharide 1,4 and 1,4 linking" \
                                        "D-saccharide 1,4 and 1,6 linking" \
                                        "L-saccharide 1,4 and 1,6 linking" \
                                        "other" ]

  set sketch_data(template,1) { { CH2 {0.0 0.0} 0 } }
  set sketch_data(centre,1) { 0.0 0.0 }
  set sketch_data(template,3) { { CR15 { 1.63 1.21 } 0  } 
			{ CR15 { 2.31 0.0 } 1 }
			{ CR15 { 1.63 -1.21 } { 1 -1 } } }
  set sketch_data(guide,3) { {  0.0 0.75 } { 0.0 -0.75  } }
  set sketch_data(centre,3) { 1.50 0.0 }
  set sketch_data(template,4) { { CR16 {1.30 1.50}  0 }
                        { CR16 {2.60 0.75} 1 }
                        { CR16 {2.60 -0.75}  1 }
                         { CR16 {1.30 -1.50} { 1 -1} } }
  set sketch_data(guide,4) { {  0.0 0.75 } { 0.0 -0.75  } }
  set sketch_data(centre,4)  { 1.95 0.0 }
  set sketch_data(template,5) { { CR5  {0.0 0.75} 0}
				{ CR15 {1.21 1.63} 1 }
				{ CR15 {0.75 3.06} 1 }
				{ CR15 {-0.75 3.06} 1 }
				{ CR15 {-1.21 1.63} {1 4 } } }
  set sketch_data(guide,5) { {  0.0 -0.75 } { 0.0 0.75  } }
  set sketch_data(centre,5) { 0.0 2.3 }
  set sketch_data(template,6) { { CR6 {0.0 0.75} 0 }
                        { CR16 {1.30 1.50} 1 }
                        { CR16 {1.30 3.00} 1 }
                        { CR16 {0.0 3.75}  1 }
                         { CR16 {-1.30 3.00} 1 }
                        { CR16 {-1.30 1.50} { 1 5 } } }
  set sketch_data(guide,6) { { 0.0 -0.75 } { 0.0 0.75 } }
  set sketch_data(centre,6) { 0.0 1.5 }

  set sketch_data(chirality) [list + - both]
  set sketch_data(metal_chirality) [list cross0 cross1 cross2 cross3 \
                                    cross4 cross5 cross6]

  ReadEner_lib sketch_data
}

#------------------------------------------------------------------------
proc ReadEner_lib { sketch_dataVar } {
#------------------------------------------------------------------------
  upvar #0 $sketch_dataVar sketch_data

  if { ![ReadFile [FileJoin [GetEnvPath CLIBD_MON] ener_lib.cif] libtext -split] &&
       ![ReadFile [FileJoin [GetEnvPath CLIBD] monomers ener_lib.cif] libtext -split] } {
    WarningMessage "Error reading [FileJoin [GetEnvPath CLIBD_MON] ener_lib.cif]
Can not read allowed atom types"
    return 0
  }

  set atom_types {}
  set sketch_data(elements) {}

  foreach line $libtext {
    switch -- [string range $line 0 3] \
    \#HEA {
      if { [llength $atom_types] > 0 } {
        lappend sketch_data(atom_types,$element) [list $header $atom_types]
        set atom_types {}
      } 
      set element [string toupper [lindex $line 1]]
      if { [lsearch $sketch_data(elements) $element] < 0 } {
         lappend sketch_data(elements) $element }
      set header [lrange $line 2 end]
    } \#ATO {
      lappend atom_types  "[lrange $line 1 end]"
    } \#END {
      if { [llength $atom_types] > 0 } {
        lappend sketch_data(atom_types,$element) [list $header $atom_types]
        set atom_types {}
      }
      return 1
    }
  }
  Report 1 "WARNING: reading all of ener_lib.cif - no recognised END"

}


#-----------------------------------------------------------------
proc sketch_list_atoms { arrayname } {
#-----------------------------------------------------------------
    for { set i 1} { $i <= $Mol(nAtoms) } { incr i } {
      append text [format "%10.3f %10.3f %10.3f" [lindex $Mol(Coor,$i) 0] \
	[lindex $Mol(Coor,$i) 1] [lindex $Mol(Coor,$i) 2] ] \n  }

  foreach atom $Mol(XY) { append text $atom \n}

  WriteFile [set file [GetTmpFileName]] $text
  FileViewer $file -viewer LOGViewer
  DeleteFile $file
}

#----------------------------------------------------------------------
proc sketch_append_moltmp { MolVar tmpVar }  {
#----------------------------------------------------------------------
  upvar #0 $MolVar Mol
  upvar #0 $tmpVar tmp

# Append the atoms defined in the temporary array tmp (in usual Mol 
# array format) to the atoms in the Mol array

  set natadd [ set nat $Mol(nAtoms) ]

  for { set  n 1 } { $n <= $tmp(nAtoms) } {  incr n } {
    incr nat
    foreach param [list Name Element Type Coor Charge] {
      set Mol([subst $param],$nat) $tmp([subst $param],$n)
    }
  }
  set Mol(nAtoms) $nat

  set nb $Mol(nBonds)

  for { set  n 1 } { $n <= $tmp(nBonds) } { incr n } {
    incr nb
    foreach param [list Bonds] {
      set bond {}
      lappend bond [expr [lindex $tmp(Bonds,$n) 0] + $natadd] \
		[expr [lindex $tmp(Bonds,$n) 1] + $natadd]
      set Mol(Bonds,$nb) $bond
      set Mol(Bondtype,$nb) $tmp(Bondtype,$n)
    }
  }
  set Mol(nBonds) $nb

  set nc $Mol(nChiral)
  for { set  n 1 } { $n <= $tmp(nChiral) } { incr n } {
    incr nc
    foreach param [list ChiralCentre  Chirality] {
      set Mol([subst $param],$nc) $tmp([subst $param],$n)
    }
    for { set j 0 } { $j < 8 } { incr j } {
        set Mol(ChiralNaybrs,$j,$nc) $tmp(ChiralNaybrs,$j,$n)
    }
  }
  set Mol(nChiral) $nc
  

}

#----------------------------------------------------------------------
proc   sketch_active_atom_centre { arrayname } {
#----------------------------------------------------------------------
# Get the centre of the active atoms (to use in transformations)
  upvar #0 $arrayname array
  global Mol

  if { [llength $array(active_atom)] == 0 } { return }

  set nat 0;set comx 0.0; set comy 0.0; set comz 0.0

  foreach at $array(active_atom) {
    incr nat; set xyz $Mol(Coor,$at)
    set comx [expr $comx + [lindex $xyz 0]]
    set comy [expr $comy + [lindex $xyz 1]]
    set comz [expr $comz + [lindex $xyz 2]]
  }
  set array(active_atom_centre) [list \
      [expr $comx / $nat ] \
      [expr $comy / $nat ] \
      [expr $comz / $nat ]  ]

#  puts "centre $array(active_atom_centre)"
}

#--------------------------------------------------------------------------
proc sketch_databases { } {
#--------------------------------------------------------------------------
# Display the web page link to databases

      [expr $comz / $nat ]  ]

#  puts "centre $array(active_atom_centre)"
}

#--------------------------------------------------------------------------
proc sketch_databases { } {
#--------------------------------------------------------------------------
# Display the web page link to databases

  open_url [SearchPath TOP sketch sketch_database.html]
}

#----------------------------------------------------------------------
proc sketch_edit_preferences { arrayname  } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array
  global sketch_pref

  DefineVariable sketch_pref font_size _positiveint $array(font_size)
  DefineVariable sketch_pref linewidth _positiveint $array(linewidth)
  DefineVariable sketch_pref bond_separation _positivereal \
		$array(bond_separation)
  DefineVariable sketch_pref mouse_buttons _mouse_buttons $array(mouse_buttons)
#  DefineVariable sketch_pref display_type _logical $array(display_type)

  set w .sketch_pref
# puts "sketch_edit_preferences $w $arrayname"
  if { ![OpenWindow $w "Monomer Library Sketcher Preferences" \
	Preferences -parent $arrayname ] } { return  }

  CreateFrame $w sketch_pref -noscroll
  CreateButton $w apply Apply "sketch_pref_update $arrayname"
  CreateButton $w dismiss Dismiss "sketch_pref_update $arrayname
				        CloseWindow sketch_pref"
  OpenFolder protocol

#  CreateLine line \
#    label "Number of mouse buttons available" \
#    widget mouse_buttons

#  CreateLine line \
#    widget display_type \
#    label "Display atom energy types in atom table"

  CreateLine line \
    label "Font size for molecule display" \
    widget font_size 

  CreateLine line \
    label "Line thickness for bonds" \
    widget linewidth \
    label "separation of double bonds" \
    widget bond_separation
  
}



#----------------------------------------------------------------------
proc sketch_pref_update { arrayname } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array
  global sketch_pref
  global Mol

# Apply the sketcher preferences set by the user
    set c $array(current_canvas)

  if { $sketch_pref(font_size) != $array(font_size) } {
    set array(font_size) $sketch_pref(font_size)
    sketch_font $arrayname

    for { set n 1 } { $n <= $Mol(nAtoms) } { incr n } {
      $c  itemconfigure name$n  -font $array(font)
    }
  }

  if { $sketch_pref(bond_separation) != $array(bond_separation)  } {
    set array(bond_separation) $sketch_pref(bond_separation)
    sketch_create_bond_objects $arrayname
  }

  if { $sketch_pref(linewidth) != $array(linewidth) } {
    set array(linewidth) $sketch_pref(linewidth)
    for { set i 1 } { $i <= $Mol(nBonds) } { incr i } {
      for { set j 1 } { $j <= $Mol(Bondtype,$i) } { incr  j } {
        eval $c itemconfigure {bond$i.$j} -width $array(linewidth)
      }
    }
  }

#  if { $sketch_pref(mouse_buttons) != $array(mouse_buttons) } {
#    set array(mouse_buttons) $sketch_pref(mouse_buttons)
#    WarningMessage "Now exit from the Sketcher and reenter to reset mouse buttons"
#  }

#  if { $sketch_pref(display_type) != $array(display_type) } {
#    set array(display_type) $sketch_pref(display_type)
#    sketch_update_table $arrayname -refresh
#  }

  sketch_redisplay $arrayname
}

#----------------------------------------------------------------------
proc sketch_font { arrayname } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array
  global configure
  set ff [lreplace [split $configure(FONT_REGULAR) \-] 8 8 $array(font_size) ]
  set array(font) ""
  foreach f [lrange $ff 1 end ] { append array(font) \- $f }
}

#----------------------------------------------------------------------
proc sketch_set_message { arrayname mode } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array
  global Mol

  switch $mode \
  edit {
    switch $array(edit_mode) \
    del_bond {
      set mess "Click on bond to delete it"
    } del_atom {
      set mess "Click on atom to delete it"
    } B {
      set mess "Click on atom to bond to active atom"
    } 0 {
      set mess "Select edit mode from menu first"
    } default {
      if { $Mol(nAtoms) < 1 } {
         set mess "Click in window to add fragment"
      } elseif {  [llength $array(active_atom)] <= 0 } {
         set mess "First select an active atom"
      } else {
         set mess "Click close to active atom to add fragment"
      }
    }
    set message "MOUSE BUTTONS Left:rotate Right:drag Control-left:zoom   Control-right:Select active atom\nShift-left:$mess Shift-right:Click bond to change bond type"
  } frag {
    set message "MOUSE BUTTONS Left:rotate Right:drag Control-left:zoom   Control-right:Select active atom(s)\nShift-left:Rotate active atoms Shift-right:Drag active atoms"
  } plane {
    set message "MOUSE BUTTONS Left:rotate Right:drag Control-left:zoom   Control-right:Select active atom(s)\n"
  }

  set array(MESSAGEVAR) $message
  SetMessage $arrayname $array(current_canvas) $message
}


#----------------------------------------------------------------------
proc sketch_delete_chiral { arrayname nch } {
#----------------------------------------------------------------------
  global Mol
# Delete item number nch from list of chiral centres
#
# If nch is less than number of chiral centres then shuffle down the data
  if { $nch < $Mol(nChiral) } {
    for { set n $nch } { $n < $Mol(nChiral) } { incr n } {
      set nn [expr $n  +1 ]
      foreach data [list ChiralCentre Chirality] {
        set Mol([subst $data],$n) $Mol([subst $data],$nn)
      }
      for { set j 0 } { $j < 8 } { incr j } {
        set Mol(ChiralNaybrs,$j,$n) $Mol(ChiralNaybrs,$j,$nn)
      }
    }
  }
  set n $Mol(nChiral)
  foreach data [list ChiralCentre  Chirality] {
    unset Mol([subst $data],$n)
  }
  for  { set j 0 } { $j < 8 } { incr j } { unset Mol(ChiralNaybrs,$j,$n) }
  incr Mol(nChiral) -1
}

#----------------------------------------------------------------------
proc sketch_add_chiral { arrayname atno } {
#----------------------------------------------------------------------
  global Mol
# Add a chiral centre for atom number atno to list
  
# Find the atoms bonded to ato
  set bonded [getbondedatoms $atno] 

  set n [expr $Mol(nChiral) + 1]
  set Mol(ChiralCentre,$n) $Mol(Name,$atno)
  for { set j 0 } { $j < 8 } { incr j } { set Mol(ChiralNaybrs,$j,$n) {} }
  set j -1 foreach at $bonded { incr j
    set Mol(ChiralNaybrs,$j,$n) $Mol(Name,$at) }
  set Mol(Chirality,$n) +

  set Mol(nChiral) $n
}

#----------------------------------------------------------------------
proc sketch_run_dictionary { arrayname iflibcheck {format PDB} } { 
#----------------------------------------------------------------------
  upvar #0 $arrayname array
  global dictionary

  switch $format \
  PDB {
    if { ![sketch_check_input] } { return 0 }
    if { $array(ifpdbin) } {
      RunTask dictionary -module sketch \
        -args "-iflibcheck $iflibcheck -pdbin $array(pdbin) $array(dir_pdbin)" \
        -def [SearchPath TOP sketch dictionary.def]
    } else {
      RunTask dictionary -module sketch -args "-iflibcheck $iflibcheck" \
        -def [SearchPath TOP sketch dictionary.def]
    }
  } MOL2 {
    RunTask dictionary -module sketch \
        -args "-iflibcheck $iflibcheck -input_mode mol2" \
        -def [SearchPath TOP sketch dictionary.def]
  } SMILES {
    RunTask dictionary -module sketch \
        -args "-iflibcheck $iflibcheck -input_mode smiles" \
        -def [SearchPath TOP sketch dictionary.def]
  }
}

#------------------------------------------------------------------------
proc sketch_check_input { } {
#------------------------------------------------------------------------
  global Mol

  if { ![ElementExists Mol nAtoms] || $Mol(nAtoms) < 1 } {
    WarningMessage "You must define some atoms before trying to create dictionary entry. It is not possible to rerun Libcheck tasks."
    return 0
  }

  set text {}
  for { set n 1 } { $n <= $Mol(nAtoms) } { incr n } {
    if { $Mol(Name,$n) == "" } {
      append text "There is no name for $n th atom in the list\n" }
    for { set m [expr $n + 1] } { $m <= $Mol(nAtoms) } {  incr m } {
      if { [StringSame $Mol(Name,$n) $Mol(Name,$m) ] } {
        append text "There are two atoms with the name $Mol(Name,$m)\n"
      }
    }
  }
  #if { [set nfrag [MolFindFragments] ] > 1 } {
  #  append text "The monomer is in more than one fragment.\n"
  #}

  if { $text != "" } {
    WarningMessage "Can not create library entry for the current monomer:\n$text"
    return 0
  } else {
    return 1
  }
}

#----------------------------------------------------------------------
proc sketch_change_mouse_mode { arrayname } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array
  switch $array(mouse_mode) \
  edit {
    sketch_edit_bindings $array(current_canvas) $arrayname
# If there is > 1 active atom then deselect them all
    if { [llength $array(active_atom)] > 1 } {set_active_atom $arrayname 0 0 }
  } frag {
    sketch_frag_bindings $array(current_canvas) $arrayname
  } plane {
    sketch_plane_bindings $array(current_canvas) $arrayname
  }
  sketch_set_message $arrayname $array(mouse_mode)

  if { $array(mouse_mode) == "plane"  } {
    if { [winfo ismapped [lindex $array(mouse_mode_buttons) 1]] } {
    foreach w [lrange $array(mouse_mode_buttons) 1 end ] { grid remove $w } }
  } else { 
    if { ![winfo ismapped [lindex $array(mouse_mode_buttons) 1]] } {
      foreach w [lrange $array(mouse_mode_buttons) 1 end ] { grid $w } }
  }

}

#----------------------------------------------------------------------
proc sketch_edit_plane { arrayname } {
#----------------------------------------------------------------------
  upvar #0 $arrayname array
  global Mol
  global sketch_plane


  InitialiseArray [SearchPath TOP sketch sketch_plane.def] sketch_plane sketch_plane
  set sketch_plane(N_PLANES) $Mol(nPlane)
  for { set n 1 } { $n <= $Mol(nPlane) } { incr n } {
    set sketch_plane(PLANE_EDIT,$n) 0
    set sketch_plane(PLANE_ATOMS,$n) ""
    foreach atom $Mol(plane,$n) { append sketch_plane(PLANE_ATOMS,$n) $atom " " }
    set sketch_plane(PLANE_DEV,$n) [lindex $Mol(plane_dev,$n) 0]
  }

  set w .sketch_plane
# puts "sketch_edit_plane $w $arrayname"
  if { ![OpenWindow $w "Definition of Planes in Molecule" \
        Planes -parent $arrayname -message sketch_plane \
	-help [SearchPath HELP modules sketcher] -target planes ] } { return  }

  CreateFrame $w sketch_plane -noscroll
  CreateButton $w save "Save to File" "sketch_close_plane $arrayname sketch_plane 1
					CloseWindow sketch_plane"
  CreateButton $w cancel Cancel "sketch_close_plane $arrayname sketch_plane 0
				CloseWindow sketch_plane"
  OpenFolder protocol

  CreateLineTemplate sketch_plane [list 0.0 0.05 0.15]

  CreateLine line \
    label "Click the Edit button to (de)select the atoms in a plane visually" \
	-itallic
  CreateLine line \
    label "Then hold down Control key & click on atom(s) with right mouse button" -itallic

  CreateLine line \
    label Edit -itallic \
    label ESD -itallic \
    label "Atoms in plane" -itallic \
    format template sketch_plane

  CreateExtendingFrame N_PLANES sketch_edit_plane_plane \
	"Define Planar Groups" "Add a Plane" \
	[list PLANE_EDIT PLANE_ATOMS PLANE_DEV ] \
	-edit sketch_handle_frame_edit 

  update_extendingframe sketch_edit_plane_plane 0 sketch_plane N_PLANES  \
	0 $sketch_plane(N_PLANES)  1
    
}

#----------------------------------------------------------------------
proc sketch_close_plane {  sketchVar sketch_planeVar ifsave } {
#----------------------------------------------------------------------
  upvar #0 $sketch_planeVar sketch_plane
  upvar #0 $sketchVar sketch
  global Mol
# update the plane definitions in Mol array from the GUI

  if $ifsave {
# Prompt user for file name..
  if { ![SelectFile filn -title "Save planes definitions" \
     -filter "*.cif" -parent sketch -unknown ] } { return 0 }
# Save data to the Mol array
    set sketch(ifeditedplane) 1
    set Mol(nPlane) $sketch_plane(N_PLANES)
    for { set n 1 } { $n <= $sketch_plane(N_PLANES) } { incr n } {
      set Mol(plane,$n) ""
      set Mol(plane_dev,$n) ""
      foreach atom $sketch_plane(PLANE_ATOMS,$n) {
        lappend Mol(plane,$n) $atom
        set Mol(plane_dev,$n) $sketch_plane(PLANE_DEV,$n)
      }
    }
# Write the plane definitions to the file - this same code as should be in 
# WriteCifBonds proc.
  set text "loop_
_chem_comp_plane_atom.comp_id
_chem_comp_plane_atom.plane_id
_chem_comp_plane_atom.atom_id
_chem_comp_plane_atom.dist_esd\n"
    for { set n  1 } { $n <= $Mol(nPlane)  } { incr n } {
      foreach atom $Mol(plane,$n) {
        append text \
          "$Mol(chem_comp_id) plan-$n  [write_cif_name $atom] $Mol(plane_dev,$n)\n"
      }
    }
    WriteFile [lindex $filn 0] $text -overwrite
  }
  if { $sketch(mouse_mode) == "plane" } { 
     sketch_end_plane_visual $sketchVar $sketch_planeVar }
  return
}

#-------------------------------------------------------------------------------
proc sketch_end_plane_visual { sketchVar sketch_planeVar} {
#-------------------------------------------------------------------------------
  upvar #0 $sketch_planeVar sketch_plane
  upvar #0 $sketchVar sketch
  global Mol
# Switch off the visualisation of planes on the display

# puts "sketch_end_plane_visual $sketchVar $sketch_planeVar"
  if { $sketch(edit_plane) == 0 } { return }

  foreach atno $sketch(active_atom) {
    $sketch(current_canvas) itemconfigure name$atno -fill $Mol(Colour,$atno)
    $sketch(current_canvas) dtag name$atno active_atom
  }
  set sketch(edit_plane) 0
  set sketch(mouse_mode) edit
  set sketch(active_atom) ""
  sketch_change_mouse_mode $sketchVar
  for { set n 0 } { $n <= $sketch_plane(N_PLANES) } { incr n } { 
    set sketch_plane(PLANE_EDIT,$n) 0
  }
}


#----------------------------------------------------------------------
proc sketch_edit_plane_plane { sketch_planeVar counter } {
#----------------------------------------------------------------------

  global sketch_data
  set sketch $sketch_data(sketch_array)

  CreateLine line \
    message "Click on button to have plane indicated by flashing atoms" \
    widget PLANE_EDIT \
     -command "sketch_edit_plane_visual $sketch $sketch_planeVar $counter" \
    message "Deviation of atoms from plane" \
    widget PLANE_DEV -width 6 \
    message "Space separated list of all atoms in the plane" \
    widget PLANE_ATOMS -width 60 \
	-command "sketch_update_plane_visual $sketch $sketch_planeVar $counter" \
    format template sketch_plane

}

#----------------------------------------------------------------------
proc sketch_handle_frame_edit { sketch_planeVar counter } {
#----------------------------------------------------------------------

  global sketch_data
  set sketch $sketch_data(sketch_array)
# This procedue called when the user selects Add Plane or Edit List in 
# the window
# Switch off any visualisation on the display 
  sketch_end_plane_visual $sketch $sketch_planeVar

}

#----------------------------------------------------------------------
proc sketch_edit_plane_visual { sketchVar sketch_planeVar np } {
#----------------------------------------------------------------------
  upvar #0 $sketchVar sketch
  upvar #0 $sketch_planeVar sketch_plane
  global Mol

  if { !$sketch_plane(PLANE_EDIT,$np) } {
# Unset currently active atoms
    sketch_end_plane_visual $sketchVar $sketch_planeVar
    return
  }

  
  for { set n 1 } { $n <= $sketch_plane(N_PLANES) } { incr n } {
    if { $n != $np} { set sketch_plane(PLANE_EDIT,$n) 0 }
  }
  set sketch(edit_plane) $np
  

  set sketch(mouse_mode) plane
  sketch_change_mouse_mode $sketchVar

  sketch_update_plane_visual $sketchVar $sketch_planeVar $np

}

#-----------------------------------------------------------------------
proc sketch_update_plane_visual {  sketchVar sketch_planeVar np } {
#-----------------------------------------------------------------------
  upvar #0 $sketchVar sketch
  upvar #0 $sketch_planeVar sketch_plane
  global Mol

# Set the active atoms on the display to be the atoms in a plane

  if { $np != $sketch(edit_plane) } { return }

# Unset currently active atoms
  foreach atno $sketch(active_atom) {
    $sketch(current_canvas) itemconfigure name$atno -fill $Mol(Colour,$atno)
    $sketch(current_canvas) dtag name$atno active_atom
  }
  set sketch(active_atom) ""

# setup atoms in the plane as active atoms
  set not_found ""
  foreach atom $sketch_plane(PLANE_ATOMS,$np) {
    if { [set n [sketch_get_atom_number $atom]] > 0 } {
      lappend sketch(active_atom) $n
      $sketch(current_canvas) addtag active_atom withtag name$n
    } else {
      append not_found $atom " "
    }
  }
  if { $not_found != "" } {
    WarningMessage "The atoms selected for the plane $not_found
were not found in the molecule"
  }
}

#----------------------------------------------------------------------
proc sketch_update_plane_table { sketchVar sketch_planeVar } {
#----------------------------------------------------------------------
  upvar #0 $sketchVar sketch
  upvar #0 $sketch_planeVar sketch_plane
  global Mol

# user has updated the active atoms on display so update the table

  set np $sketch(edit_plane)

  set tmp ""
  foreach n $sketch(active_atom) { append tmp $Mol(Name,$n) " " }
  set sketch_plane(PLANE_ATOMS,$np) $tmp

}

#-------------------------------------------------------------------
proc sketch_run_libcheck { file filetype libfileVar} {
#-------------------------------------------------------------------
  global Mol
  upvar $libfileVar libfile
  PleaseWait "Running Libcheck to identify bond order and chiral centres"
  set com [FileJoin [GetDefaultDirPath TEMPORARY] sk_libcheck.com]
  set log [FileJoin [GetDefaultDirPath TEMPORARY] sk_libcheck.log]
  DeleteFile $log
  set libfile  [FileJoin [GetDefaultDirPath TEMPORARY] sk_libcheck_lib]
  DeleteFile $libfile.lib

  switch $filetype \
  PDB {
    WriteFile $com \
      "_Y\n_FILE_PDB $file\n_SRCH 0\n_FILE_O $libfile\n_END\n" -overwrite
    
  } CIF {
    WriteFile $com \
      "_Y\n_FILE_CIF $file\n_SRCH 0\n_FILE_O $libfile\n_END\n" -overwrite
  }  

  set status \
    [Execute "[BinPath libcheck]" $com program_status report -log $log]

  PleaseWait
  #puts "status $status program_status $program_status $libfile"
  if { ![file exists $libfile.lib] } {
    WarningMessage "Error running Libcheck to analyse bonds and chirality"
    return 0
  } else {
    append libfile ".lib"
    return 1
  }
}
