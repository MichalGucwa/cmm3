#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#=========================================================================
# CCP4 Interface Utils.tcl
#
#
#
# General utilities
#
#====================================================================

#CCP4i_cvs_Id $Id$

#d_index_title Handling Data Types
#d_intro_title Handling Data Types
#d_into Data types are stored in etc/types.def file or may be defined \
locally within task window setups by DefineVariable command. Internally  \
this information is stored in the typedef array. The name of the typedef \
element is either a data type or a data type class (see below) and the content \
of th element is a list which defines the data type (or class). Note \
that the data type must be defined before a def file which references \
that data type is read.  This means that it should be done in the \
taskname_setup procedure. Every data type must belong to one of the data \
type classes defined at the top of the types.def file.  The data type \
class determines the widget used to represent the parameter.  These \
currently are: \
#d_intro entry wiget: int, real, text, word
#d_intro toggle button: logical
#d_intro menu: menu varmenu
#d_intro Create*putLine widget: default_dir & file
#d_intro CreateLabin widget: mtz_label 
#d_intro Not represented graphically: list datalist 

#d_intro Each data type has properties which are \
dependent on its class and the properties of each class are defined \
at the top of the types.def file.


#----------------------------------------------------------------
proc GetType { arrayname element } {
#----------------------------------------------------------------
#d_sum Returns the data type for an input array element
#d_desc Returns a zero length string if does not find a datatype definition.
#d_desc The data type is stored in the array element with the name \
_$element. For the 'indexed' elements (eg root,4 or root,4_2) which \
correspond to extending frames \
the data type is only stored once as _root,0 where root is the root of the \
element name.  
#d_arg Name of data array
#d_arg element Name of element of array.
  upvar #0 $arrayname array

  if { [llength [set l [split $element ,] ] ] > 1 } {
    if { ![info exists array(_[lindex $l 0],0)] } { return "" }
    return $array(_[lindex $l 0],0)
  } else {
    if { ![info exists array(_$element)] } { return "" }
    return $array(_$element)
  }
}

#---------------------------------------------------------------------------
proc Indxv { name c1 { c2 {} } } {
#---------------------------------------------------------------------------
#d_sum Generate the element name for multi-dimensional data
#d_desc Return string of form name,c1 or name,c1_c2
#d_arg name The element name
#d_arg c1 The first index number for the element
#d_arg c2 Optional. The second index number for the element
  set element $name
  if { $c1 != "" } { append element "," $c1 }
  if { $c2 != "" } { append element "_" $c2 }
  return $element
}

#---------------------------------------------------------------------------
proc GetIndx { element rootVar c1Var c2Var } {
#---------------------------------------------------------------------------
#d_sum Parse the name of a dimensioned element
#d_arg element Input element name
#d_arg rootVar Return the root of the element name
#d_arg c1Var Return the first index number
#d_arg c2Var Return the second index number
  upvar $rootVar root
  upvar $c1Var c1
  upvar $c2Var c2

  set c1 ""
  set c2 ""

  if { ![regexp {([^,]*),([^,]*)} $element tt root indx ] } {
    set root $element
    return
  }
  if { ![regexp {([^_]*)_([^_]*)} $indx tt c1 c2 ] } {
    set c1 $indx
  }
  return
}

#--------------------------------------------------------------------
proc Indxv0 { name } {
#--------------------------------------------------------------------
#d_sum For indexed element names (eg root,4) return the zero index (eg root,0)
#d_desc For 'indexed' elements (which are used in extending frames) the \
data type is stored only once as array(_root,0).  
#d_sum name Name of an array element 
  if { [llength [set l [split $name ,] ] ] > 1 } {
    return [lindex $l 0],0 
  } else {
    return $l
  }
}


#-----------------------------------------------------------------
proc GetTypeInfo  { arrayname element type { warning warning } } {
#-----------------------------------------------------------------
#d_sum Return some information which is a property of the data type of an element
#d_desc The valid properties of any given data type are defined as a list in \
the typedef($class) parameter where class is the class of the data type
#d_arg arrayname Name of data array
#d_arg element The name of an array element for which a property value is required
#d_arg type The property whose value is required. Or 'type' to return the data type class (yes it should be called class)
#d_arg warning Optionally the argument is the word 'warning' to indicate that a warning message should be output is the property is not found 

  upvar #0 $arrayname array

  set typelist {}
  set data ""

  if { [get_type_list $arrayname  $element typelist] == 0 } {
    if { $warning == "warning" } {
      Report 3 "ERROR no type for $element in $arrayname"
      get_type_info_error $arrayname $element
    }
    return ""
  }

  return [GetTypeInfo0 $typelist $arrayname $element $type]

}

#-----------------------------------------------------------------
proc GetTypeInfo0 { typelist arrayname element type { warning warning } } {
#-----------------------------------------------------------------
  global typedef
  upvar #0 $arrayname array

  set datatype [lindex $typelist 0 ] 
  set data ""

# If user just wants to know the datatype then return that

  if  { $type == "type" } { return  $datatype }

# User wants to know the default list or number of items in deflist 
#  or the maximum  character width  or the items on the list

  if { $type == "deflist" || $type == "nitems" || $type == "width" } {

    if { $datatype == "default_dir" } {

      set deflist [GetDefdirMenu]

    } elseif { $datatype != "varmenu" } {

      set pp  [lsearch $typedef($datatype)  deflist ]
      if { $pp <= 0 } {
         if { $warning == "warning" } {
           Report 3 "ERROR No deflist data found for \
              $element in $arrayname which is a $datatype"
           get_type_info_error $arrayname $element
         }
         return $data
      } else  {
        set deflist [lindex $typelist $pp ]
      }

    } else {

      set pp [lsearch $typedef($datatype) deflistVar]
      set deflistVar [ lindex $typelist $pp ]
      if { [ElementExists $arrayname $deflistVar] } {
         set deflist $array($deflistVar)
      } else {
        if { $warning == "warning" } {
          Report 3 "ERROR no variable $deflistVar in $arrayname for variable menu"
	  get_type_info_error $arrayname $element
        }
        return ""
      }
#      Report 3 "deflistVar $deflistVar deflist $deflist"
    }

    if { $type == "deflist" } {
 
      return $deflist

    } elseif { $type == "nitems" } {

      return [llength $deflist]
  
    } elseif { $type == "width" } {

      set maxlength 0
      foreach item $deflist {
        set length  [string length $item ]
        if { $length > $maxlength } { set maxlength $length }
      }
      return $maxlength
    }

  } elseif { $type == "aliaslist" } {
 
   if { $datatype == "default_dir" } {

     set aliaslist [GetCurrentDir]
     foreach defdir [ListDefdirs] {
       lappend aliaslist [GetDefdirPath $defdir]
     }

   } elseif { $datatype == "menu" || $datatype == "postmenu" } {

     set pp  [lsearch $typedef($datatype)  aliaslist ]
     set aliaslist [lindex $typelist $pp ]

   } elseif { $datatype == "varmenu" } {

     set pp  [lsearch $typedef($datatype)  aliaslistVar ]
     set aliaslistVar [lindex $typelist $pp ]
     if { $aliaslistVar != "" } { 
       if { [ElementExists $arrayname $aliaslistVar] } {
         set aliaslist $array($aliaslistVar) 
       } else {
         if { $warning == "warning" } {
           Report 3 "ERROR no variable $aliaslistVar in $arrayname for variable menu"
           get_type_info_error $arrayname $element
         }
         return ""
       }
     } else { 
	set aliaslist ""
     }
   }

     if {$aliaslist == "" } {
       set pp  [lsearch $typedef($datatype)  deflist ]
       set aliaslist [lindex $typelist $pp ]
     } 
     return $aliaslist

  } elseif { $type == "filetypes" } {

     set pp [lsearch $typedef($datatype)  format]
     set format [lindex $typelist $pp ]
     if { $format != "" } {
       set data $typedef(_[subst $format]_filetypes)
     } else {
       set data ""
     }

  } else {

    set pp  [lsearch $typedef($datatype)  $type ]
    if { $pp > 0 } {
        set data [lindex $typelist $pp ]
        if { $type == "max" } {
          if {$data == "*" } { set data 99999999 }
        } elseif { $type == "min" } {
	  if {$data == "*" } { set data -99999999 }
        }
    } else { 
      if { $warning == "warning" } {
        Report 3 "ERROR Data type $type not recognised for $arrayname \
                 $element which is a $datatype"
        get_type_info_error $arrayname $element
	set data ""
      }
    }
  }

  return $data
}

#----------------------------------------------------------------
proc get_type_list { arrayname element typelistin } {
#----------------------------------------------------------------
#d_sum Get the full list of properties of the data type of an array element
#d_arg arrayname Name of data array
#d_arg element The name of an array element for which the property values are required
#d_arg typelistin Returned. The full list of properties of the data type

  global typedef
  upvar #0 $arrayname array
  upvar $typelistin typelist

  set typelist {}
  if { [llength [set l [split $element ,] ] ] > 1 } {
    set status [catch {set type $array(_[lindex $l 0],0)}]
  } else {
    set status [catch {set type $array(_$element)}]
  }

  if { !$status && $type != "" && [info exists typedef($type)] } {
    set typelist $typedef($type)
    return 1
  }  else {
    return 0
  }
}

#-----------------------------------------------------------------------------
proc get_type_info_error { arrayname element } {
#-----------------------------------------------------------------------------
#d_sum Output warning message when fail to find type information
#d_desc The problems are almost always due to not having the element \
defined in the def file or the data type defined in types.def (or elssewhere).  \
And this is almost always due to a typo.
#d_sum Get the full list of properties of the data type of an array element
#d_arg arrayname Name of data array
#d_arg element The name of an array element for which information not available.

  upvar #0 $arrayname array

  if { [ElementExists $arrayname TASK ] } {
    set taskname $array(TASK)
    
    if { [string first "," $element] < 0 } {
      Report 3 "Check the file $taskname.def contains parameter $element"
    } else {
      Report 3 "Check the file $taskname.def contains parameter \
                   [string range $element 0 [expr {[string first "," $element] -1}]],0"
    }
    Report 3 "and that this parameter has a type which is defined in type.def"
  } else {
    Report 3 "Parameter $element not of defined type"
  }

}

#-----------------------------------------------------------------
proc GetWidget  { arrayname arrayindex } {
#-----------------------------------------------------------------
#d_sum Return the Tk id of the widget representing an array element
#d_desc This information is stored as array(WIDGET_$element)
#d_arg arrayname Name of data array
#d_arg arrayindex The name of an array element

  upvar #0 $arrayname array
  if { [array names array "WIDGET_$arrayindex" ]  == "WIDGET_$arrayindex" } {
     return $array(WIDGET_$arrayindex)
  } else {
     return ""
  }
}

#------------------------------------------------------------------------
proc DefineVariable { arrayname var type init } {
#------------------------------------------------------------------------
#d_sum Define the data type and initial value of a variable 
#d_desc This does what reading the def files usually does - is usually done \
in task_setup procedure
#d_arg arrayname Name of array
#d_arg var Name of element in array
#d_arg type Data type for array element
#d_arg init Initial value for array element
  upvar #0 $arrayname array
  GetIndx $var root c1 c2
  if { $c1 == "" } {
    set array(_$var) $type
  } else {
    set array([Indxv _$root 0]) $type
  }
  if {[regexp FROM_MENU $init ]} {
    set array($var) [lindex [GetTypeInfo $arrayname $var deflist ] 0 ]
  } else {
    set array($var) $init
  }
}

#------------------------------------------------------------------------
proc DefineMenu { name menulist { aliaslist "" } } {
#------------------------------------------------------------------------
#d_sum Define a data type which is of class menu
#d_desc Menu item aliases are the text which is written to a def file \
and passed to the run script.  They are usually the keyword required by the \
program rather than the text presented to the user
#d_arg name Name of the data type
#d_arg menulist A list of the menu items. A Tcl list.
#d_arg aliaslist Optional. A list of the aliases for the menu items. A Tcl list.
  global typedef
  if { $aliaslist != "" } {
    eval "set typedef($name) { menu {$menulist} {$aliaslist} }"
  } else {
     eval "set typedef($name) { menu {$menulist} }"
  }
}

#-------------------------------------------------------------------------
proc GetValue { arrayname element } {
#-------------------------------------------------------------------------
#d_arg Return the value of an array element
#d_desc This is most useful when the array element may be of a menu type, \
when it returns the menu alias rather than the actual value of the element.
#d_arg arrayname Name of array
#d_arg element Name of array element
  upvar #0 $arrayname array
  set datatype [GetTypeInfo $arrayname $element type no_warning ]

  if { $datatype == "menu" ||  $datatype == "varmenu" || $datatype == "postmenu" } {
    GetMenuValue $arrayname $element
  } elseif { $datatype ==  "file" } {
    return [GetFullFileName0 $arrayname $element]
  } elseif { [info exist array($element) ] } {
    return "$array($element)"
  } else {
    return {}
  }
}

#-------------------------------------------------------------------------
proc GetMenuValue { arrayname element } {
#-------------------------------------------------------------------------
#d_sum Return the alias for the value of an array element which is a menu
#d_arg arrayname Name of array
#d_arg element Name of array element

  upvar #0 $arrayname array

  set aliaslist [GetTypeInfo $arrayname $element aliaslist ]
  if { [llength $aliaslist ] <= 0 } {
    return $array($element)
  } elseif { [lsearch $aliaslist $array($element)] >= 0 } {
    return $array($element)
  } else {
    set pp [ lsearch [GetTypeInfo $arrayname $element deflist] \
              $array($element) ]
    return [lindex $aliaslist $pp]
  }
}

#-------------------------------------------------------------------------
proc GetMenuText { arrayname element value } {
#-------------------------------------------------------------------------
#d_sum Return the text which appears on the menu  for given value of parameter
#d_desc The array element must be associated with a menu widget  \
this procedure returns the menu text associated with a given value \
of the element.
#d_arg arrayname  Array name
#d_arg element    The element of the array - must have a menu type
#d_arg value	The one-word value of the array element

  upvar #0 $arrayname array

  set aliaslist [GetTypeInfo $arrayname $element aliaslist ]
  if { [set pp [ lsearch $aliaslist $value]] >= 0 } {
    return [lindex [GetTypeInfo $arrayname $element deflist] $pp]
  } else {
    return ""
  }
}

#-------------------------------------------------------------------------
proc SetValue { arrayname element alias } {
#-------------------------------------------------------------------------
#d_arg Set a menu array element to the value for a specified alias value
#d_arg arrayname  Array name
#d_arg element    The element of the array - must have a menu type
#d_arg value    The one-word value of the array element

  upvar #0 $arrayname array

  set pp [lsearch [GetTypeInfo $arrayname $element aliaslist ] $alias ]
  if { $pp >= 0 } {
    set array($element) [lindex [GetTypeInfo $arrayname $element deflist ] $pp ]
  } else {
    set array($element) ""
  }
}

#d_index_title Handling Arrays

#-------------------------------------------------------------------------
proc GetIndexedElements {arrayname element { c1 "" }} {
#-------------------------------------------------------------------------
#d_sum Return all the indexed elements in an array with a given root
#d_desc Or optionally all the elements with a given root and first index. \
The returned list does NOT include the 'zero' element which is root,0 or \
root,n for elements with two indices.
#d_arg arrayname Name of array
#d_arg element The root of  an element name
#d_arg c1 Optional. The first index of the element
  upvar #0 $arrayname array

  if { $c1 == "" } {
    set elements [array names array $element,*]
    set pp [lsearch $elements [subst $element],0 ]
  } else { 
    set elements [array names array [subst $element],[subst $c1]_* ]
    set pp [lsearch $elements [subst $element],[subst $c1] ]
  }

  if { $pp >= 0 } { set elements [lreplace $elements $pp $pp ] }

#  puts "GetIndexedElements elements $elements pp $pp"

  return $elements

}

#-------------------------------------------------------------------------
proc GetIndexedElements0 {arrayname element { c1 "" }} {
#-------------------------------------------------------------------------
#d_sum Return all the indexed elements in an array with a given root
#d_desc Or optionally all the elements with a given root and first index. \
The returned list DOES include the 'zero' element which is root,0 or \
root,n for elements with two indices.
#d_arg arrayname Name of array
#d_arg element The root of  an element name
#d_arg c1 Optional. The first index of the element
  upvar #0 $arrayname array
  if { $c1 == "" } {
    set elements [array names array $element,*]
  } else {
    set elements [array names array [subst $element],[subst $c1]_* ]
  }
  return $elements
}

#-----------------------------------------------------------------------------
proc ArrayToList { arrayname nelements indexname listout }  {
#-----------------------------------------------------------------------------
#d_sum Copy data values from all the instaces of an indexed element to a list
#d_desc Only used in tasks/import.tcl.  
#d_arg arrayname Name of array
#d_arg The name of the element  which is the counter for the indexed element indexname
#d_arg The name of an indexed array element
#d_arg The name of an array element to contain the list of values

  upvar #0 $arrayname array
  set array($listout) ""
  set type0 [GetTypeInfo $arrayname [subst $indexname],1 type]
  for { set j 1 } { $j <= $array($nelements) } {incr j } {
    set value [GetValue $arrayname [subst $indexname],[subst $j] ]
    if { $value == "" } {break}
    lappend array($listout) $value
  }
#  puts " list0 $array($listout) "
}
  
#---------------------------------------------------------------------
proc CopyArray { arrayname arrayname1 } {
#---------------------------------------------------------------------
#d_sum Copy all elements of arrayname in array(PARAM_LIST) to arrayname1
#d_desc Only used in pre5.0 Refmac to copy from protin array
#d_arg arrayname Name of source array
#d_arg arrayname1 Name of target array
  upvar #0 $arrayname array
  upvar #0 $arrayname1 array1
#  puts " CopyArray arrayname $arrayname arrayname1 $arrayname1"

  foreach item $array(PARAM_LIST) {
    set type [GetType $arrayname $item ]

    GetIndx $item root c1 c2
    if { $c1 == "0" } {
      set varlist $item
      append varlist " " [GetIndexedElements $arrayname $root ]
    } elseif { $c1 == "" } {
      set varlist $item
    } else {
      set varlist ""
    }

    foreach var $varlist {
      set value "[GetValue $arrayname $var]"
      DefineVariable $arrayname1 $var $type "$value"
    }
  }
  if {![ElementExists $arrayname1 PARAM_LIST] } { 
     set array1(PARAM_LIST) "" }
  append array1(PARAM_LIST) " " $array(PARAM_LIST)
}

#---------------------------------------------------------------------
proc SimpleCopyArray { arrayname arrayname1 } {
#---------------------------------------------------------------------
#d_sum Copy all elements of arrayname to arrayname1
#d_desc Differs from CopyArray in that it copies the values directly \
and for all elements in the source array
#d_arg arrayname Name of source array
#d_arg arrayname1 Name of target array
  upvar #0 $arrayname array
  upvar #0 $arrayname1 array1
  foreach item [array names array] {
      set array1($item) $array($item)
  }
}

#--------------------------------------------------------------------------
proc CheckUnique { arrayname var nmax } {
#--------------------------------------------------------------------------
#d_sum Check that all instances of an indexed variable are unique
#d_arg arrayname Name of array
#d_arg var Root of indexed array element name
#d_arg nmax The number of instances of the indexed element
  upvar #0 $arrayname array
  if { $nmax < 2 } { return 0 }
  for { set n 1 } { $n < $nmax } { incr n } {
    for { set m [expr {$n +1}] } { $m <= $nmax } { incr m } {
      if {[StringSame $array($var,$n) $array($var,$m) ]} { 
        WarningMessage "The name $array($var,$m) is not unique.
Please enter a new name"
        set array($var,$m) ""
        return $m 
      }
    }
  }
  return 0
}

#----------------------------------------------------------------------
proc CreateNewArray { root } {
#----------------------------------------------------------------------
#d_sum  Create new unique global array with name $root_$n 
#d_desc Returns a unique name which is root_n which n in positive integer.
#d_arg root  A root name for the array
# Find lowest unused value for n
  set continue 1; set n 0
  while { $continue } {
    incr n; set arrayname [subst $root]_$n
    upvar #0 $arrayname array
    if { [array exists array] } {
      if { [ElementExists $arrayname WINDOW] &&
		![winfo exists $array(WINDOW)]} { set continue 0 }
    } else {
      global $arrayname
      set continue 0
    }
  }
  return $arrayname
}

#----------------------------------------------------------------
proc ArraySearch { arrayname var text } {
#----------------------------------------------------------------
#d_sum Return the name of an indexed element with a value of 'text'
#d_arg arrayname Name of data array
#d_arg var Element name for indexed elements
#d_arg text The search text
  upvar #0 $arrayname array

# Search array for element with a value of 'text'
# Expect the array element name to take the form array(var,index)

  set elements [GetIndexedElements $arrayname $var ]

  foreach element $elements {
    if { [StringSame $text $array($element) ] } { return $element }
  }

  return ""
}


#---------------------------------------------------------------------
proc DeleteArray { arrayname } {
#---------------------------------------------------------------------
#d_sum Delete an array
#d_arg arrayname Name of array
  upvar #0 $arrayname array
  if { [array exists array] } { unset array }
}


#----------------------------------------------------------------------
#d_index_title Simple Mathematical Functions
#----------------------------------------------------------------------

#----------------------------------------------------------------
proc max { args } {
#----------------------------------------------------------------
#d_sum Return the maximum value of the values in the argument list

  set m [lindex [lindex $args 0 ] 0 ]
  foreach ll $args {
    foreach l $ll {
      if { $l > $m } { set m $l }
    }
  }
  return  $m
}

#----------------------------------------------------------------
proc min { args } {
#----------------------------------------------------------------
#d_sum Return the minimum value of the values in the argument list

  set m [lindex [lindex $args 0 ] 0 ]
  foreach ll $args {
    foreach l $ll {
      if { $l < $m } { set m $l }
    }
  }
  return  $m
}

#----------------------------------------------------------------
proc iremainder { n m } {
#----------------------------------------------------------------
#d_sum Return the mod of n and m
#d_desc Could be replaced by expr fmod (? implemented in 8.0)

# and we just hope it all stays in integer ..
  set i [expr {$n / $m} ]
  set ii [expr {$n - ($m * $i)} ]
  return $ii
}

#----------------------------------------------------------------
proc push { stackVar levelVar value } {
#----------------------------------------------------------------
#d_sum Push a parameter onto a stack (i.e. append to list)
#d_arg stackVar Input/output the stack variable - a Tcl list
#d_arg levelVar Input/output the number of levels on the stack
#d_arg value Input value to push onto stack
  upvar $levelVar level
  upvar $stackVar stack
  lappend stack $value
  incr level
}

#----------------------------------------------------------------
proc pop { stackVar levelVar } {
#----------------------------------------------------------------
#d_sum Pop a parameter off a stack (i.e. append to list)
#d_arg stackVar Input/output the stack variable - a Tcl list
#d_arg levelVar Input/output the number of levels on the stack
#d_arg value Output value from top of stack
  upvar $levelVar level
  upvar $stackVar stack
  if { [llength $stack ] == 0 } {
    set value ""
  } else {
    set value [lindex $stack end]
    incr level -1
    set stack [lreplace $stack end end ]
  } 
  return $value
}

#----------------------------------------------------------------
proc maxdecimal { input prec } {
#----------------------------------------------------------------
#d_sum Round an input number to given number of decimal places
#d_arg input Input real number
#d_arg Maximum number of decimal places output
  set bignum [expr {pow( 10,$prec )}]
  set out [expr {int($bignum * $input)/$bignum} ]
  if { $out < $input } { set out [expr {$out + pow(10,-$prec )}] }
  return $out
}
  

#---------------------------------------------------------
proc sortorder { listin orderVar { mode {} } } {
#---------------------------------------------------------
#d_sum Sort a list using Tcl lsort and return a list of offsets to position in input list
#d_desc This function is used when you want to reorder one 'target' list \
based on sorting of another 'sortable' list which has a one-to-one matching \
with the target list.  The target list is input to sortorder and the sorting \
mode can be anything supported by Tcl lsort command.  The returned 'order' \
list is the positions in the input list of the items in sorted order. This \
order list can be used to pick out items from the target list to reorder that \
list.
#d_arg listin Input 'sortable' list
#d_arg orderVar Output list of item position in listin for sorted list
#d_arg mode (Optional) mode argument to Tcl lsort

  upvar $orderVar order

# listin is a list of whatevers - return a list order
# which is the offsets to position in listin for sorted
# This is grossly inefficient!

# mode is standard arguments to the sort function

  set cmd "set ll \[lsort $mode \$listin\]"
  eval "$cmd"

# Handle multiple instances of a value 
# in the input list 

  set order {}
  set ilast {}
  foreach item $ll {
    if { $item == $ilast } {
      set ii [expr {$i + 1} ]
    } else {
      set ii 0
    }
    set i [expr {$ii + [lsearch [lrange $listin $ii end] $item ]} ]
    lappend order $i
    set ilast $item
  }
}

#d_index_title String Handling

#---------------------------------------------------------------------
proc IfSet { args } {
#---------------------------------------------------------------------
#d_sum Test if input argument(s) are not blank strings
#d_desc This procedure is most used in interpreting com file by CreateComScript \
In that context the IfSet command is usually wrapped by a catch command which \
will safely handle the case where the variable input to IfSet is completely \
undefined.
#d_arg var Any number of input arguments

  foreach param $args {
    if { $param == "" } { return 0 }
  }
  return 1
}


#-------------------------------------------------------------------
proc StringSame { args } {
#-------------------------------------------------------------------
#d_sum String comparison - is the first argument the same as any of the other arguments
#d_desc Return true (1) if the first argument is the same as any subsequent argument
#d_arg test Test string
#d_arg compare Any number of text strings for comparison

  set case 1
  set nargs [expr {[llength $args ] -1} ]; set n 0
  if { [lindex $args 0 ] == "-case" } { set case 0 ; incr n }
  set string1 [lindex $args $n]; incr n
  if { $case } { set string1 [string toupper $string1] }

  foreach string2 [lrange $args $n $nargs ] {
    if { $case } { set string2 [string toupper $string2] }
    if { [string compare $string1 $string2 ] == 0 }  { return 1 }
  }
  return 0
}


#------------------------------------------------------------------------
proc RemoveMetaChars { namein args } {
#------------------------------------------------------------------------
#d_sum Return text string with non-alphanumeric characters & leading/trailing spaces removed
#d_desc The removed characters (excluding leading/trailing spaces) are replaced with an underscore
#d_arg namein Input text string
#d_opt0 -space
#d_opt1 Allow spaces in the text (default is to remove)
#d_opt0 -title
#d_opt1 For title text also allow - _ , . ( ) /
#d_opt0 -report
#d_opt1 Give warning message to user
  set nospace 1
  set report 0
  set title 0
  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    spa {
      set nospace 0
    } title {
      set title 1
    } report {
      set report 1
    }
    incr n
  }

  set changed 0

  set name "[string trim $namein]"
  if {$title} {
    while { [regsub -nocase {[^a-z^0-9^_^-^ ^(^)^/^.^,]} $name _ name1] > 0 } {
      set changed 1
      set name $name1
    }
  } elseif {$nospace} {
    while { [regsub -nocase {[^a-z^0-9^_^-]} $name _ name1] > 0 } { 
      set changed 1
      set name $name1 
    }
  } else {
    while { [regsub -nocase {[^a-z^0-9^_^-^ ]} $name _ name1] > 0 } {
      set changed 1
      set name $name1
    }
  }
# For some reason the preious regsub does not catch ^
  while { [regsub {\^} $name _ name1] > 0 } { 
    set changed 1
    set name $name1 
  }

  if { $changed && $report } {
    WarningMessage "Input text changed to $name.\nName must only have alphanumeric characters or underscore _"
  }
  return $name
}

#-------------------------------------------------------------------
proc ResolveUnixFileSymbols { path retpathVar } {
#-------------------------------------------------------------------
#d_sum Interpret tilde or environment variable, or a relative path
#d_desc The input to this procedure is the first component of a file name. \
The procedure will return the full path name for this component.  The return \
status is 1 = substitution successful, 0 = no substitution necessary or \
-1 = error in input
#d_arg path Input first component of a file path name
#d_arg retpathVar Output the full expansion of the input path.
  upvar $retpathVar retpath
# Input the first component of a path name to check if it is a tilda or
# an environment variable, or a relative path.  Return the full path in retpath
# return status 1 = substitution successful
#               0 = no subs necessary
#              -1 = error in input

  set path_list [file split $path]
  set p0 [ lindex $path_list 0 ]
  

# tilda
  if { [regexp {^~} $p0 ] } {
    if { [catch {glob $p0} dd] } {
      set status -1
    } else {
      set path0  $dd
      set path_list [lreplace $path_list 0 0]
      set status 1
    }
# environment variable
  } elseif { [regsub {^\$} $p0 "" p0] } {
    if { [GetEnvPath $p0 ] == "" } {
      set status -1
    } else {
      set path0 [GetEnvPath $p0 ]
      set path_list [lreplace $path_list 0 0]
      set status 1
    }
# current directory
  } elseif { $p0 == "." } {
    set path0 [GetCurrentDir]
    set path_list [lreplace $path_list 0 0]
    set status 1

# parent directory(? of the working directory)
  } elseif { $p0 == ".." } {
    set path0 [file split [GetCurrentDir]]
    while { [llength $path0] > 1  && [lindex $path_list 0] == ".." } { 
      set path0 [lreplace $path0 end end]
      set path_list [lreplace $path_list 0 0]
    }
# the user could still be trying to go up when we've run out of directories
    if { [lindex $path_list 0] == ".." } { set status 0 } else { set status 1 }
  } else {
    set status 0
  }
  if { $status == 1 } { 
#    puts "path0 $path0"
    set retpath [eval [concat FileJoin $path0 $path_list ]]
  } else {
    set retpath $path
  }
#  puts "retpath $retpath"
  return $status
}

#------------------------------------------------------------------------
proc FeedListbox { boxlist job_list display display_format} {
#------------------------------------------------------------------------
#d_sum Colourise the entries of a listbox
#d_desc Each entry is processed to see if its content correspond to a \
colour-coding present in the configuration.
#d_arg boxlist the listbox whose entries are to be colourised
#d_arg job_list the list of jobs that will be filled in the listbox

  global configure
  global archive
  DbGetCurrentProject project
  set njobs [llength $job_list]
  set counter 0
  
  for { set n 0 } { $n < $njobs } { incr n} {
  
    set job_id [lindex $job_list $n]
    set item [DbJobDescription $project $job_id $display $display_format]
    $boxlist insert end "$item"

    # Applying Color if necessary
    if { [GetValue configure IFCOLOUR] } {
	# Use colour settings specified by user
	set jobdata [DbGetJobData $job_id STATUS TASKNAME TITLE]
	set status [lindex $jobdata 0]
	set taskname [lindex $jobdata 1]
	set title [lindex $jobdata 2]
	set colours [get_job_display_colours $taskname $status $title $counter]
	$boxlist itemconfigure end -foreground [lindex $colours 0] \
	    -background [lindex $colours 1]
    } else {
	# No colourisation
	# Stripe the joblist instead
	if { ! $counter } {
	    $boxlist itemconfigure end -background "\#ebecf6"
	} else {
	    $boxlist itemconfigure end -background "white"
	}
    }
    lappend archive(DISPLAY_LIST) $job_id
    # Flip the counter for striping
    set counter [expr $counter?0:1]
  }
}

#------------------------------------------------------------------------
proc get_job_display_colours { task status title { counter 0 } } {
#------------------------------------------------------------------------
#d_sum Return the colours to display the job with
#d_desc Returns a list of two values - the first is the foreground colour \
i.e. that used for the text, the second is the background colour, \
according to the settings specified in the configure array.
#d_desc The optional argument counter can be used to indicate which of the \
striped backgrounds should be used, but is over-ridden if an explicit
#d_arg task   The name of the task
#d_arg status The job status
#d_arg title  The job title
#d_arg counter (optional) Used for job striping
  global configure

  # Defaults
  set foreground ""
  if { ! $counter } {
      set background "\#ebecf6"
  } else {
      set background "white"
  }

  if { ![GetValue configure IFCOLOUR] } {
    # Colourisation disabled - nothing to do
    return [list $foreground $background]
  }

  # Acquire foreground colour setting
  set colour_mode [GetValue configure COLOUR_MODE]  
  set text_default [GetValue configure "TEXT_DEFAULT"]

  switch $colour_mode {
      "status" {
	  # Foreground colour determined by job status
	  set colour_param "COLOUR_$status"
	  if { [info exists configure($colour_param)] } {
	      # There is a setting for this status
	      set foreground [GetValue configure $colour_param]
	  } else {
	      # No setting so use the default
	      set foreground $text_default
	  }
      }
      "task" {
	  # Foreground colour determined by taskname
	  set n_tasks [GetValue configure N_COLOUR_TASK]
	  #For each entries we check if its task is related to one colourised
	  for { set m 0 } { $m <= $n_tasks } { incr m } {
	      set name [string tolower [GetValue configure TASK_NAME,$m]]
	      if { $name == $task } {
		  set foreground [GetValue configure "COLOUR_TASK,$m"]
		  break
	      }
	  }
	  # if it is not than the default colour is used
	  if { $foreground == "" } {
	      set foreground $text_default
	  }
      }
      "title" {
	  # Foreground colour determined by a match to a title
	  # For each entry check if its title is related to one "colour word"
	  set n_words [GetValue configure N_COLOUR_WORD]
	  for { set m 0 } { $m <= $bond } { incr m } {
	      set word [string tolower [GetValue configure WORD_TITLE,$m]]
	      if { [string first $word $title] > -1 } {
		  set foreground [GetValue configure "COLOUR_WORD,$m"]
		  break
	      }
	  }
	  # if it is not than the default colour is used
	  if { $foreground == "" } {
	      set foreground $text_default
	  }
      }
      default {
	  # Everything else - use the default text colour
	  if { $foreground == "" } {
	      set foreground $text_default
	  }
      }
  }

  # Acquire background colour setting
  set colour_mode [GetValue configure BG_COLOUR_MODE]  
  set bg_default [GetValue configure "BG_DEFAULT"]

  switch $colour_mode {
      "status" {
	  # Background colour determined by job status
	  set colour_param "COLOUR_BG_$status"
	  if { [info exists configure($colour_param)] } {
	      # There is a setting for this status
	      set background [GetValue configure $colour_param]
	  } else {
	      # No setting so use the default
	      set background $bg_default
	  }
      }
      "task" {
	  # Background colour determined by taskname
	  set n_tasks [GetValue configure N_COLOUR_BG_TASK]
	  #For each entries we check if its task is related to one colourised
	  for { set m 0 } { $m <= $n_tasks } { incr m } {
	      set name [string tolower [GetValue configure TASK_NAME_BG,$m]]
	      if { $name == $task } {
		  set background [GetValue configure "COLOUR_BG_TASK,$m"]
		  break
	      }
	  }
	  # if it is not than the default colour is used
	  if { $background == "" } {
	      set background $bg_default
	  }
      }
      "title" {
	  # Background colour determined by a match to a title
	  # For each entry check if its title is related to one "colour word"
	  set n_words [GetValue configure N_BG_COLOUR_WORD]
	  for { set m 0 } { $m <= $bond } { incr m } {
	      set word [string tolower [GetValue configure WORD_TITLE_BG,$m]]
	      if { [string first $word $title] > -1 } {
		  set background [GetValue configure "COLOUR_BG_WORD,$m"]
		  break
	      }
	  }
	  # if it is not than the default colour is used
	  if { $background == "" } {
	      set background $bg_default
	  }
      }
      default {
	  # Everything else - use the default background colour
	  if { $background == "" } {
	      set background $bg_default
	  }
      }
  }

  # Return the values
  return [list $foreground $background]
}

#d_index_title Handling Data Harvesting "Central Deposit" Location

#------------------------------------------------------------------------
proc SetCentralDeposit { central_deposit } {
#------------------------------------------------------------------------
#d_sum Set the CENTRAL_DEPOSIT location for data harvesting
#d_desc Set the value of the CENTRAL_DEPOSIT parameter, which specifies \
a "central" directory for the user's harvesting files.
#d_arg central_deposit The directory path for the CENTRAL_DEPOSIT location
    global user_directories
    set user_directories(CENTRAL_DEPOSIT) $central_deposit
    return $user_directories(CENTRAL_DEPOSIT)
}

#------------------------------------------------------------------------
proc GetCentralDeposit { } {
#------------------------------------------------------------------------
#d_sum Fetch the current CENTRAL_DEPOSIT location for data harvesting
#d_desc Return the previously stored value of CENTRAL_DEPOSIT, or {} \
if no value is currently stored.
    global user_directories
    if { [ElementExists user_directories CENTRAL_DEPOSIT] } {
	return $user_directories(CENTRAL_DEPOSIT)
    }
    return {}
}
