#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - directories.tcl
#
#
#
# Variable Menus
#
#====================================================================

#CCP4i_cvs_Id $Id$

#d_index_title Variable Menus (src/varmenu.tcl)
#d_intro_title Variable Menus
#d_intro This is the mechanism to handle menus whose menuitems may change \
during the lifetime of the window. For example in the AMoRe interface there \
is a menu to select a TEST_SPACE_GROUP which is must be one of the alternative \in the same Laue group as the space group of the input data.  The appropriate \
menu can only be set after the user has entered the input MTZ file which \
provides the input space group information.  To implement this there are the \
following definitions in the amore.def file:
#d_intro TEST_SPACE_GROUP        _laue_space_group       ""
#d_intro LAUE_SPGP_LIST          _list_of_text           ""
#d_intro LAUE_SPGP_ALIAS         _list_of_text           ""

#d_intro The TEST_SPACE_GROUP will be the test space group which the user \
will select from a menu which is defined in amore_setup:
#d_intro set typedef(_laue_space_group) { varmenu LAUE_SPGP_LIST LAUE_SPGP_ALIAS 8 }
#d_intro Here the datatype _laue_space_group is defined as a variable menu \
which has the menuitems taken from the parameter LAUE_SPGP_LIST and the 'alias' \
of the menuitems taken from the parameter LAUE_SPGP_ALIAS. Both of these \
parameters have been defined in the amore.def and are initially empty. When \
the user selects an input MTZ file the procedure amore_set_test_space_group \
is called which finds the appropriate Laue space groups and loads them \
into the variables LAUE_SPGP_LIST and LAUE_ALIAS_LIST and then calls the \
procedure UpdateVariableMenu to update the variable.

#d_intro In these handling procedures the datatype for the variable menu \
(e.g. LAUE_SPGP_LIST) in the above example) is referred to as the deflistVar.\
Note that is quite possible for there \
to be multiple widgets which have the same variable menu and a list of these \
is stored in array(DEPVARS_$deflistVar).

#----------------------------------------------------------------------
proc create_varmenu { arrayname depvar } {
#----------------------------------------------------------------------
#d_sum Called from CreateLine procedure to update array(DEPVARS_$deflistVar)
#d_desc array(DEPVARS_$deflistVar) is list of all variables which are attached \
to created widgets which have list of possible values $deflistVar.

#d_arg arrayname The name of the task array
#d_arg depvar The name of the variable which associated which the widget which\
 is been created.

  upvar #0 $arrayname array

# The variable menu item list is stored in element deflistVar
# This variable name is saved as a part of the type info for 
# the elements which use the variable menu.  
# This routine is called to ensure the connection is set up when 
# the task window is drawn

# arrayname
# depvar 	array element which has possible values defined by 
#		a variable menu

  set deflistVar [GetTypeInfo $arrayname $depvar deflistVar]

  if { [ElementExists $arrayname DEPVARS_$deflistVar] } {

# If the list of dependent variables is already set up then add this
# element to the list if it is not already on the list
#    puts "Initial state of  DEPVARS $array(DEPVARS_$deflistVar)"

    if { [lsearch $array(DEPVARS_$deflistVar) $depvar] < 0 } {
      lappend array(DEPVARS_$deflistVar) $depvar
    }

  } else { 

   set array(DEPVARS_$deflistVar) $depvar
 }

#  puts "create_varmenu $array(DEPVARS_$deflistVar)"

}

#-----------------------------------------------------------------------
proc UpdateVariableMenu { arrayname mode nn deflistVar input \
         { aliaslistVar {} } { alias {} } { input_command {} }  } { 
#-----------------------------------------------------------------------
#d_sum Invoked by user to update the variable menu
#d_desc The input parameters aliaslistVar and alias are optional and not \
required if an alias parameter has not been defined.
#d_arg arrayname The name of the task array
#d_arg mode Can be 'initialise', 'append' or 'replace'
#d_arg n The number of the menu item to be replaced in 'replace' mode
#d_arg deflistVar Element of array containing the list of menu item
#d_arg input  input value(s) for deflistVar
#d_arg aliaslistVar Element of array containing the aliases for menu items
#d_arg alias input value(s) for aliaslistVar

  upvar #0 $arrayname array

#  puts "UpdateVariableMenu $mode $nn $deflistVar $input"

  if { [ElementExists $arrayname $deflistVar] } {
#      puts "initial state of deflistVar $array($deflistVar)"
  }

  if { $mode == "initialise" || 
    ( $mode == "append" && ![ElementExists $arrayname $deflistVar] ) } { 
    set array($deflistVar) ""
    if { $aliaslistVar != "" } { set array($aliaslistVar) "" }
  }


  if { $mode == "append" || $mode == "initialise" } {
    foreach item $input {
      lappend array($deflistVar) $item
    }
    if { $aliaslistVar != "" } { 
      foreach item $alias {
        lappend array($aliaslistVar) $item
      }
    }

  } elseif { $mode == "replace" } {
    if { $nn <= [llength $array($deflistVar)] } {
      set n [expr {$nn - 1} ]
      set array($deflistVar) [lreplace $array($deflistVar) $n $n "$input"]
    } else {
      Report 3 "ERROR in UpdateVariableMenu nn $nn deflistVar \
                    $deflistVar $array($deflistVar)"
    }

  } elseif { $mode == "delete" } {

    set n [expr {$nn - 1} ]
    set array($deflistVar) [ lreplace $array($deflistVar) $n $n ]
  }

#  if { [ElementExists $arrayname DEPVARS_$deflistVar ]} {
#    puts "DEPVARS $array(DEPVARS_$deflistVar)"
#  }

  if { [ElementExists $arrayname DEPVARS_$deflistVar] && \
              [llength $array(DEPVARS_$deflistVar)] > 0 } {
    foreach item $array(DEPVARS_$deflistVar) {
      update_menu $arrayname $item $deflistVar $input_command
    }
  }
}

#--------------------------------------------------------------------------
proc update_varmenu { arrayname mode varmenu_element \
                            varmenu_name inputVar } {
#--------------------------------------------------------------------------
#d_sum Handler to update one item of variable menu
#d_desc This procedure is called by a trace mechanism if the user changes \
another text widget which defines an item on the variable menu.
#d_arg arrayname The name of the task array
#d_arg mode Expected to be replace
#d_arg varmenu_element The number of the menu item to be replaced in 'replace' mode
#d_arg varmenu_name Element of array containing the list of menu items
#d_arg inputVar Element of array containing the new value for the replaced menu item

  upvar #0 $arrayname array
  UpdateVariableMenu $arrayname $mode $varmenu_element $varmenu_name \
	"$array($inputVar)"
}

#----------------------------------------------------------------------------
proc update_menu { arrayname element menu_listVar { input_command {} }  } {
#----------------------------------------------------------------------------
#d_sum Called from UpdateVariableMenu to redraw the menu(s) associated with one variable.
#d_desc Because each variable could potentially be attached to more than one \
widget this procedure call update_menu0 which redraws each individual instance \
of the menu.
#d_arg arrayname The name of the task array
#d_arg element The array element which has a variable menu widget
#d_arg menu_listVar Element of array containing the list of menu items
#d_arg input_command An additional command associated with the menu

  upvar #0 $arrayname array

  set field_list [GetWidget $arrayname $element]
  if { $field_list == "" } { return 0 }

#  puts " update_menu $element menu_listVar $menu_listVar [ llength $array($menu_listVar)  ]"
  set menu_list $array($menu_listVar)
  if { [llength $menu_list] <= 0 } { return 0 }
  foreach field $field_list {
    if {[winfo exists $field]} {
      update_menu0 $field $arrayname $element $menu_list $input_command
    } else {
      Report 1 "update_menu field does not exist $field $element"
    }
  }
  return 1
}

#----------------------------------------------------------------
proc update_menu0 { field arrayname element menu_list { input_command {} } } {
#----------------------------------------------------------------
#d_sum Update each individual instance of a variable menu
#d_arg field The widget name of the menu
#d_arg arrayname The name of the task array
#d_arg element The array element attached to the variable menu widget
#d_arg menu_list The list of menu items
#d_arg input_command Optional command to be bound to an menu selection
  global configure
# Check if there is any commands associated with the menu (other than
# UpdateDependentParams) and add these to the newly created menu
  set comline  [ [$field cget -menu ] entrycget 0 -command ]
#      puts "comline $comline"
  set cmds [split $comline ";"]
  set newcomline {}; set ncmds 0
  foreach item $cmds {
    if { [string first "UpdateDependentParams" $item ] < 0 } {
      incr ncmds; if { $ncmds > 1 } { append newcomline ";" }
      append newcomline $item
    }
  }

  if { $input_command != "" } {
    if { $newcomline != "" } { append newcomline ";" }
    append newcomline "$input_command"
    incr ncmds
  }

  set break_count 0
  initialise_menu $field
  foreach item $menu_list {
    $field.m add command -label "$item"   \
	-font $configure(FONT_REGULAR) \
	-columnbreak [break_menu_column break_count $configure(MENU_LENGTH)] \
    -command "UpdateDependentParams \"$item\" $arrayname  \
                                $element"
  }
  if { $ncmds > 0 } { add_command $field $newcomline }
}

