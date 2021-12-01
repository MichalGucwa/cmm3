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
# sketch_table.tcl --
#
# Code for the atom edit table on side of 3D sketcher
#
# CCP4Interface
# Liz Potterton April 2000
#
# ======================================================================

#-----------------------------------------------------------------
proc sketch_create_table { arrayname } {
#-----------------------------------------------------------------
  global system
  upvar #0 $arrayname array
  global Mol

# Draw the atoms editor table
  set edit_table_spec [list  \
	[list Element Element ] \
	[list Name Name] \
	[list Ox Charge] ]

  if { $array(display_type) } { lappend edit_table_spec  [list Type Type] }

  set array(edit_table) [CreateTable $arrayname \
	Edit Mol $edit_table_spec $array(edit_frame) \
	-scroll -noedit  -nolabel -row sketch_table_create_row ]

  SetMessage $arrayname $array(edit_table) \
   "Edit Table for definition of atom element type, name, energy type and oxidation state"

  if { [ElementExists Mol nAtoms] && $Mol(nAtoms) > 0 } {
    for { set i 1 } { $i <= $Mol(nAtoms) } { incr i } {
      sketch_table_create_row $arrayname $i
    }
  }


# Draw the chirality table

  set chiral_table_spec [list \
        [list ChiralCentre Centre ] \
        [list Chirality Sign] \
        [list ChiralNaybrs,0 B/3] \
        [list ChiralNaybrs,1 F/4] \
        [list ChiralNaybrs,2 1/5] \
        [list ChiralNaybrs,3 2/6] \
        [list ChiralNaybrs,4 {}] \
        [list ChiralNaybrs,5 {}] \
        [list ChiralNaybrs,6 {}] \
        [list ChiralNaybrs,7 {}] \
         ]

  set array(chiral_table) [CreateTable $arrayname \
        Chiral Mol $chiral_table_spec $array(chiral_frame) \
	-scroll \
	-counter nChiral \
	-row sketch_chiral_create_row ]

  SetMessage $arrayname $array(chiral_table) \
   "Chiral Table for definition of chiral centres"

  if { [ElementExists Mol nChiral] && $Mol(nChiral) > 0 } {
    for { set i 1 } { $i <= $Mol(nChiral) } { incr i } {
      sketch_chiral_create_row $arrayname $i
    }
  }

# For some reason the window layout is better if defer setting the table 
# scroll for edit table until after defining the chiral menu

  TableUpdateScroll $array(edit_frame)
  TableUpdateScroll $array(chiral_frame)

}

#-----------------------------------------------------------------------------
proc sketch_update_table { arrayname args } {
#-----------------------------------------------------------------------------
  upvar #0 $arrayname array
  global Mol

  set refresh 0
  set first 1
  set last $Mol(nAtoms)
  set nargs [llength $args]; set n 0
  while  { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    first {
      incr n; set first [lindex $args $n]
    } refresh {
      set refresh 1
    }
    incr n
  }
  
  if { $refresh } {
    destroy $array(edit_table)
    set t [frame $array(edit_frame).canvas.contents.table]
    grid $t -row 0 -column 0 -sticky nswe
    eval [GetSystemVar BLT_TABLE] $t
    if { $array(display_type) } {
      CreateTableTitle $t [list Element Name Ox Type ] 
    } else {
      CreateTableTitle $t [list Element Name Ox ] 
    }
  }

  if { $last >= $first } { 
    for { set atno $first } { $atno <= $last } { incr atno } {
      sketch_table_create_row $arrayname $atno
    }
  }
  TableUpdateScroll $array(edit_frame)
}



#-----------------------------------------------------------------------------
proc sketch_update_chiral_table { arrayname args } {
#-----------------------------------------------------------------------------
  upvar #0 $arrayname array
  global Mol

  set refresh 0
  set first 1
  set last $Mol(nChiral)
  set nargs [llength $args]; set n 0
  while  { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    first {
      incr n; set first [lindex $args $n]
    } refresh {
      set refresh 1
    }
    incr n
  }

  if { $refresh } {
    destroy $array(chiral_table)
    set t [frame $array(chiral_frame).canvas.contents.table]
    grid $t -row 0 -column 0 -sticky nswe
    eval [GetSystemVar BLT_TABLE] $t
      CreateTableTitle $t [list {} Centre Sign B/3 F/4 1/5 2/6]
  }

  if { $last >= $first } { 
    for { set chno $first } { $chno <= $last } { incr chno } {
      sketch_chiral_create_row $arrayname $chno
    }
  }
  TableUpdateScroll $array(chiral_frame)
}



#-----------------------------------------------------------------------------
proc sketch_table_create_row { arrayname atno } {
#-----------------------------------------------------------------------------
  upvar #0 $arrayname array
  global configure
  global Mol
  global sketch_data

  set t $array(edit_table)

  set nameid [entry $t.2_$atno -textvariable Mol(Name,$atno) \
    -font $configure(FONT_REGULAR) \
    -width 6  ]

  SetMessage $arrayname $nameid "Change the atom name\n "

  bind $nameid <FocusOut> "sketch_update_name $arrayname $atno"
  bind $nameid <Return> "sketch_update_name $arrayname $atno"

  set eleid [menubutton $t.1_$atno -textvariable Mol(Element,$atno) \
	-indicatoron 1 -relief raised \
        -width  4 \
        -font $configure(FONT_REGULAR) \
        -menu $t.1_$atno.m ]

  SetMessage $arrayname $eleid "Change element type\n "

  menu $eleid.m -tearoff 0
  foreach item  $sketch_data(elements) {
    $eleid.m add command -label "$item"  \
     -font $configure(FONT_REGULAR) \
     -command  "sketch_update_element $arrayname $atno \"$item\""
  }
  $eleid.m add command -label More \
    -font $configure(FONT_REGULAR) \
    -command "sketch_periodic_table $arrayname $atno"

  if { $array(display_type) } {

# Load the atom type menu for this element

    set typeid [menubutton $t.4_$atno -textvariable Mol(Type,$atno) \
    -indicatoron 1 -relief raised \
    -font $configure(FONT_REGULAR) \
    -width 6 \
    -menu $t.4_$atno.m ]

    SetMessage $arrayname $typeid "Set the atom type - or leave as no_type to be assigned by program\n "

    set array(typemenu,$atno) [menu $typeid.m  -tearoff 0]

    sketch_table_atomtype_menu $atno $Mol(Element,$atno) $array(typemenu,$atno)

  }

  set chargeid [menubutton $t.3_$atno -textvariable Mol(Charge,$atno) \
    -indicatoron 1 -relief raised \
    -font $configure(FONT_REGULAR) \
    -width 1 \
    -menu $t.3_$atno.m ]

  SetMessage $arrayname $chargeid "Set the oxidation state of the atom\n "

  menu $chargeid.m -tearoff 0

  foreach item [list 6 5 4 3 2 1 0 -1 -2 ] {
    $chargeid.m add command -label "$item"  \
         -font $configure(FONT_REGULAR) \
         -command "sketch_update_param $atno Charge \"$item\" "
  }

  if { $array(display_type) } {
    eval [GetSystemVar BLT_TABLE] $t \
      $eleid $atno,0 \
      $nameid $atno,1 \
      $chargeid $atno,2 \
      $typeid $atno,3
  } else {
    eval [GetSystemVar BLT_TABLE] $t \
      $eleid $atno,0 \
      $nameid $atno,1 \
      $chargeid $atno,2
  }

}


#-------------------------------------------------------------------------
proc  sketch_table_atomtype_menu { atno element menu_id } {
#-------------------------------------------------------------------------
  global sketch_data
  global configure

  if { [winfo exists $menu_id] } { 
    foreach w [winfo children $menu_id] { destroy $w }
    $menu_id delete 0 end 
  } else {
    menu $menu_id -tearoff 0
  }

  if { ![ElementExists sketch_data atom_types,$element] } {
    set type_menu [list [list $element ] ]
    set def_type $element
  } else {
    set type_menu $sketch_data(atom_types,$element)
    set def_type "no_type"
  }
  if { [llength $type_menu] == 1 } {
    foreach item [concat no_type [lindex [lindex $type_menu 0] 1]] {
       $menu_id add command -label "$item"  \
         -font $configure(FONT_REGULAR) \
         -command "sketch_update_param $atno Type \"$item\" "
    }
   } else {

#     $menu_id add command -label no_type \
#          -font $configure(FONT_REGULAR) \
#          -command "sketch_update_param $atno Type no_type "

# Kludge.  Make n_type a cascade menu so this cascade menu tends to get 
# opened rather than the P2 menus which are large and often are placed over
# the top of the parent menu

     $menu_id add cascade -label no_type \
	-font $configure(FONT_REGULAR) \
          -menu $menu_id.m0
       menu $menu_id.m0 -tearoff 0
       $menu_id.m0 add command -label no_type \
         -font $configure(FONT_REGULAR) \
         -command "sketch_update_param $atno Type no_type "


     set i 1; foreach item $type_menu {
       set header [lindex $item 0]
       set types [lindex $item 1]
       incr i
       $menu_id add cascade -label "$header" \
          -font $configure(FONT_REGULAR) \
	  -menu $menu_id.m$i
       menu $menu_id.m$i -tearoff 0
       foreach t $types {
         $menu_id.m$i add command -label "$t" \
	 -font $configure(FONT_REGULAR) \
         -command "sketch_update_param $atno Type \"$t\" "
       }
     }
  }

  return $def_type
}


#-------------------------------------------------------------------
proc sketch_update_element { arrayname atno new_element  } {
#-------------------------------------------------------------------
# user has changed the atom element - also update the atom name
  upvar #0 $arrayname array
  global Mol
  global configure
  global sketch_data

  set old_element $Mol(Element,$atno)
  set Mol(Element,$atno) $new_element
  if { [ElementExists sketch_data $new_element,Colour ] } {
    set Mol(Colour,$atno) $sketch_data($new_element,Colour)
  } else {
    set Mol(Colour,$atno) $sketch_data(Default,Colour)
  }

  set old_ele [lindex [split $old_element _] 0]
  set new_ele [lindex [split $new_element _] 0]
  if [regsub $old_ele $Mol(Name,$atno) $new_ele new_name] {
    sketch_update_name $arrayname $atno $new_name
  }

  if { $array(display_type) } {
    set Mol(Type,$atno) [sketch_table_atomtype_menu \
	$atno $Mol(Element,$atno) $array(typemenu,$atno) ]
  }

}


#-------------------------------------------------------------------
proc sketch_update_name { arrayname atno { new_name "" } } {
#-------------------------------------------------------------------
# user has changed the atom name - redraw with new name
  upvar #0 $arrayname array
  global Mol
  global Atom

  set old_name $Mol(Name,$atno)
  if { $new_name != ""} {
    set Mol(Name,$atno) $new_name
  } else {
    set new_name $Mol(Name,$atno)
  }

  # Update the Chirality info
  if { $Mol(nChiral) > 0 } {
    for { set n 1 } { $n <= $Mol(nChiral) } { incr n } {
      if { [StringSame $Mol(ChiralCentre,$n) $old_name] } {
        set  Mol(ChiralCentre,$n) $new_name
        break
      }
      for { set m 0 } { $m < 8 } { incr m } {
        if  { [StringSame $Mol(ChiralNaybrs,$m,$n) $old_name] } {
          set  Mol(ChiralNaybrs,$m,$n) $new_name
          break
        }
      }
    }
  }
 
          

#  set warning 1
#
## Warn user if already atom of same name - but don't block the change
## Beware that can end up with ccp4i frozen if the user changes the focus
## to the other atom of the same name
#  set current [split [focus] .]
#  if { [ regexp warning [lindex $current end]] } { set warning 0 }
#  if { ![regsub name [lindex $current end] {} current_atno ] } { 
#	set current_atno 0 }
##  puts "focus $current current_atno $current_atno"
#  set n 0; while { $warning && $n <  $Mol(nAtoms)} {incr n
#    if { [StringSame $new_name $Mol(Name,$n)] && \
#			$n != $atno && $n != $current_atno} {
#      WarningMessage "There is already an atom with name $new_name"
#      set warning 0
#    }
#  }

  eval $array(current_canvas) itemconfigure {name$atno} -text {$new_name} \
	-fill $Mol(Colour,$atno)

}


#------------------------------------------------------------------------
proc sketch_periodic_table { arrayname atno } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array
# puts "sketch_periodic_table $arrayname"
  set w .sketch_period
  OpenWindow $w "Select Element Type" Periodic -parent $arrayname -nomessage

  set t [frame $w.t]; pack $t
  eval [GetSystemVar BLT_TABLE] $t
  set ir -1; set n 0
  foreach row [list \
	[list H {} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {} HE ] \
	[list LI BE {} {} {} {} {} {} {} {} {} {} B C N O F NE ] \
        [list NA MG {} {} {} {} {} {} {} {} {} {} Al Si P S Cl Ar ] \
        [list K CA SC TI  V CR MN FE CO NI CU ZN GA GE AS SE BR KR ] \
        [list RB SR Y ZR NB MO TC RU RH  PD AG CD IN SN SB TE I XE ] \
        [list CS BA {} HF TA W RE OS IR PT AU HG TL  PB BI PO AT RN ] \
        [list FR RA {} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {} ] \
        [list {} {} {} LA CE PR ND PM SM EU GD TB DY HO ER TM YB LU ] \
        [list {} {} {} AC TH  PA U NP PU AM CM BK CF ES FM MD  NO LR] ] { 
    incr ir; set ie -1
    set cmd "[GetSystemVar BLT_TABLE] $t"
    foreach ele $row {  incr ie; incr n
      if { $ele != "" } {
        button $t.$n -text $ele  \
    	  -width 2 \
	  -command "sketch_set_ele $arrayname $atno $ele"
        append cmd " $t.$n $ir,$ie"
      }
    }
    eval $cmd
  }

  frame $w.b -relief raised; pack $w.b -side bottom
  button $w.b.q -text Quit \
   -command "destroy .sketch_period"
  pack $w.b.q 
  
}

#------------------------------------------------------------------------
proc sketch_set_ele { arrayname atno { ele {} }  } {
#------------------------------------------------------------------------
# Set the element type to that selected from periodic table

  if { $ele != "" } {
    sketch_update_element $arrayname $atno $ele
  }
  destroy .sketch_period

}

#------------------------------------------------------------------------
proc sketch_chiral_create_row { arrayname chno } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array
  global configure
  global Mol
  global sketch_data

  set t $array(chiral_table)

  set labid [label $t.ll_$chno -text $chno \
	-font $configure(FONT_REGULAR) ]

  set atid [entry $t.1_$chno -textvariable Mol(ChiralCentre,$chno) \
    -font $configure(FONT_REGULAR) \
    -width 6 ]
  SetMessage $arrayname $atid "Enter the name of the chiral atom\n "

# chirality menu
  set signid [ menubutton $t.2_$chno -textvariable Mol(Chirality,$chno) \
        -indicatoron 1 -relief raised \
    -font $configure(FONT_REGULAR) \
    -width 4 \
    -menu $t.2_$chno.m ]

  menu $signid.m -tearoff 0
  foreach state \
      [concat $sketch_data(chirality) $sketch_data(metal_chirality)] { 
    $signid.m add command -label $state \
        -font $configure(FONT_REGULAR) \
        -command "sketch_update_chiral $t $chno $state"
  }

  SetMessage $arrayname $signid "Set the sign of the chiral centre\n"



  for { set i 0 } { $i < 8 } { incr i } {
    entry $t.[expr $i+3]_$chno \
      -textvariable Mol(ChiralNaybrs,$i,$chno) \
      -font $configure(FONT_REGULAR) \
      -width 5
    SetMessage $arrayname $t.[expr $i+3]_$chno \
              "Enterthe name of chiral neighbours"
  }


  set row [expr $chno*2]
  eval  [GetSystemVar BLT_TABLE] $t \
    $labid $row,0 \
    $atid $row,1 \
    $signid $row,2 \
    $t.3_$chno $row,3 \
    $t.4_$chno $row,4 \
    $t.5_$chno $row,5 \
    $t.6_$chno $row,6

  eval  [GetSystemVar BLT_TABLE] arrange $t
  sketch_update_chiral $t $chno $Mol(Chirality,$chno) 4

}

#-------------------------------------------------------------------------
proc sketch_update_chiral  { t chno state {nold {}} } {
#-------------------------------------------------------------------------
  global Mol
  
  if { $nold == "" } {
      set nold [sketch_get_n_naybrs $Mol(Chirality,$chno)] }
  set Mol(Chirality,$chno) [lindex $state 0]
  set nnew [sketch_get_n_naybrs $state]

  #puts "nnew $nnew nold $nold"

  if { $nnew < $nold } {
    for { set j $nnew } { $j < $nold } { incr j } {
       set jj [expr $j+3]
       eval  [GetSystemVar BLT_TABLE] forget $t.[subst $jj]_$chno 
    }
  } elseif { $nnew > $nold } {
    set row [expr $chno*2]
    if { $nnew > 4 } { set jmax 4 } else {set jmax $nnew } 
    for { set j $nold } { $j < $jmax } { incr j } {
      set jj [expr $j+3]
      [GetSystemVar BLT_TABLE] $t $t.[subst $jj]_$chno $row,$jj
    }
    incr row
    for { set j 4 } { $j < $nnew } { incr j } {
      [GetSystemVar BLT_TABLE] $t $t.[expr $j+3]_$chno $row,[expr $j-1]
    }
  }    
   
}

#------------------------------------------------------------------------
proc sketch_get_n_naybrs { chirality } {
#------------------------------------------------------------------------
  switch -- $chirality  \
  cross0 {
    set nn 2
  } cross2 {
    set nn 4
  } cross3 {
    set nn 5
  } cross4 {
    set nn 6 
  } cross5 {
    set nn 7
  } cross6 {
    set nn 8
  } default {
    set nn 3 
  }
  return $nn
}


#-------------------------------------------------------------------------
proc sketch_update_param  { id mode { value {} } } {
#-------------------------------------------------------------------------
  global Mol
  set Mol([subst $mode],$id) [lindex $value 0]
}
#------------------------------------------------------------------------
proc sketch_update_type { atno  { new_type "" } } {
#------------------------------------------------------------------------
  global Mol
  if { $new_type != ""} {
    set Mol(Type,$atno) [lindex $new_type 0]
  } else {
    set new_type $Mol(Type,$atno)
  }

}

