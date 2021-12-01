#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
# ======================================================================
# load_monomer.tcl --
#
# CCP4Interface
# Accessed from the sketcher window
#
# =======================================================================
#-----------------------------------------------------------------
proc load_monomer_setup { typedefVar arrayname } {
#-----------------------------------------------------------------
  upvar #0 $arrayname array
  upvar #0 $typedefVar typedef
  global monomer_lib
  if { ![ElementExists monomer_lib typelist] } {
    set monomer_lib(typelist) {}
    set monomer_lib(code,non-polymer) {}
    set monomer_lib(name,non-polymer) {}
  }
  if { ![ElementExists $arrayname DICT_TYPE] } {
    set typedef(_dict_type) { varmenu DICT_TYPE_MENU DICT_TYPE_ALIAS 20 }
    DefineVariable $arrayname DICT_TYPE _dict_type "non-polymer"
  }
  return 1

}

#-----------------------------------------------------------------
proc load_monomer_task_window { arrayname args } {
#-----------------------------------------------------------------
  upvar #0 $arrayname array
  global monomer_lib
  global sketch_data

# onefile parameter set true if user is just entering the name of a library file
# which should contain just one monomer
  set array(ONEMOLLIB) 0
  if { [llength $args] > 0 } { 
    set array(ONEMOLLIB) 1 
  } else {
# load params list of monomers from libcheck
    if { ![ElementExists sketch_data monomers_loaded] ||
         !$sketch_data(monomers_loaded) } {
      set sketch_data(monomers_loaded) [load_monomer_sort_library $arrayname]
    }
    if { $monomer_lib(typelist) != ""  } { UpdateVariableMenu $arrayname \
        initialise 0 DICT_TYPE_MENU $monomer_lib(typelist) }
  }

  if { [CreateTaskWindow $arrayname \
       "Load Monomer from Library" Monomer \
       [list "Choose Monomer" "Output Files" ]  ] == 0 } return

  #  SetProgramHelpFile

  OpenFolder file

  if { $array(ONEMOLLIB) } { 

  CreateInputFileLine line \
    "Specify the name of the library file" \
    "Library file" DICT DIR_DICT \
    -command "load_monomer_lib_name $arrayname"

  } else {

  CreateLine line \
    label "Enter name of dictionary file if NOT using default dictionary"  -italic

  CreateInputFileLine line \
    "Specify the name of the dictionary" \
    "Dictionary file" DICT DIR_DICT \
    -command "load_monomer_sort_library $arrayname -file DICT
		load_monomer_update_list $arrayname type"
  }

 CreateLine line \
    message "By default existing structure is deleted" \
    widget IFINITIALISE \
    label "Delete any currently displayed monomer" \
    message "Default is to load monomer without hydrogen atoms" \
    widget LOAD_HYDROGEN \
    label "Include all hydrogen atoms in monomer"

  CreateLine line \
    message "Enter the code name for the structure in the dictionary" \
    label "Code name for required monomer" \
    widget CHEM_COMP_ID  -oblig -command "load_monomer_chem_comp_id $arrayname" \
    varlabel SELECTED_NAME


  OpenFolder 1 ONEMOLLIB hide 1

  CreateLine line \
    message "Choose type of monomer" \
    label List  \
    widget DICT_TYPE -command "load_monomer_update_list $arrayname type" \
    label "monomers  - apply search filter:" \
    message "Filter (* matches any sequence of characters, ? matches any character)" \
    widget FILTER -width 20 \
	-command "load_monomer_update_list $arrayname filter"

  CreateListbox frame MONLIST -array  $arrayname \
	-height 10 -width 40 -font FONT_FIXED
  bind $frame.list <Button-1>  "load_monomer_select $arrayname %W %y"

  OpenFolder 2 ONEMOLLIB hide 1

  CreateLine line \
    label "Extract the library data to the files.." -itallic

  CreateOutputFileLine line \
    "CIF file to contain geometry description of entry" \
    "Geom file" GEOM_FILE DIR_GEOM_FILE

  CreateOutputFileLine line \
    "CIF file to containing idealised coordinates" \
    "Coord file" COORDS_FILE DIR_COORDS_FILE

  if { !$array(ONEMOLLIB) } { load_monomer_update_list $arrayname type }

}

#-------------------------------------------------------------------------
proc load_monomer_select { arrayname lb y} {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(CHEM_COMP_ID) [lindex [$lb get [$lb nearest $y]] 0]
  set_field_colour $arrayname CHEM_COMP_ID 1

  load_monomer_chem_comp_id $arrayname

}

#-------------------------------------------------------------------------
proc load_monomer_chem_comp_id { arrayname } {
#-------------------------------------------------------------------------
  global monomer_lib
  upvar #0 $arrayname array

# Update the varlabel which gives the full title for the monomer
  if { ![ElementExists $arrayname DICT_TYPE] || $array(DICT_TYPE) == "" } { 
      set array(DICT_TYPE) "non-polymer" }
  set type $array(DICT_TYPE)
  if { $array(CHEM_COMP_ID) != "" &&
    [set n [lsearch $monomer_lib(code,$type)  $array(CHEM_COMP_ID)]] >= 0 } {
    UpdateVarLabel $arrayname SELECTED_NAME "[lindex $monomer_lib(name,$type) $n]"
  } else {
    UpdateVarLabel $arrayname SELECTED_NAME ""
  }


  if { $array(CHEM_COMP_ID) == "" } {
    set array(COORDS_FILE) ""
    set array(GEOM_FILE) ""
  } else {
    set array(COORDS_FILE) "$array(CHEM_COMP_ID).pdb"
    if { $array(ONEMOLLIB) } {
      set array(GEOM_FILE) [GetTmpFileName -exp lib]
    } else {
      set array(GEOM_FILE) "$array(CHEM_COMP_ID)_mon_lib.cif"
    }
  }
  CheckFileInput $arrayname COORDS_FILE save
  CheckFileInput $arrayname GEOM_FILE save
 

}

#-------------------------------------------------------------------------
proc load_monomer_update_list { arrayname mode } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array
  global monomer_lib


  set field [GetWidget $arrayname MONLIST].list
  $field delete 0 end

  if { ![ElementExists $arrayname DICT_TYPE] || $array(DICT_TYPE) == "" } { 
     set array(DICT_TYPE) "non-polymer" }
  set type $array(DICT_TYPE)
  if { ![ElementExists monomer_lib code,$type] } {
    $field insert end "No $type monomers in dictionary"
    return
  }

  set codelist $monomer_lib(code,$type)

  if { $array(FILTER) == ""  } {

    set i -1; foreach mon $monomer_lib(name,$type) { incr i
      $field insert end [format %-10s%s [lindex $codelist $i] $mon]
    }

  } else {

    set nmatch 0
    set i -1; foreach name $monomer_lib(name,$type) code $monomer_lib(code,$type) { incr i
      if { [regexp -nocase "$array(FILTER)" $name] || 
		[regexp -nocase "$array(FILTER)" $code] } {
        incr nmatch
        $field insert end [format %-10s%s $code $name]
      }
    }
    if { $nmatch == 0 } { $field insert end "No matches to the filter" }
  }

}

#-------------------------------------------------------------------------
proc load_monomer_run { arrayname } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array

  if { $array(CHEM_COMP_ID) == "" } {
    WarningMessage "Enter a code name for the dictionary structure"
    return 0
  }
  if { $array(DICT) != "" } {
    set array(INPUT_FILES) DICT
    set array(NODIST) 1
  } else {
    set array(INPUT_FILES) ""
    set array(NODIST) 0
  }
  return 1
}

#-------------------------------------------------------------------------
proc load_monomer_review { arrayname job_id  } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array
  global sketch_data

# Load coords - beware give sketch as the arrayname argument to
# sketch_load_dict_coords

  if { ![file exists [GetFullFileName0 $arrayname COORDS_FILE]] } {
    WarningMessage "ERROR: The coordinate file \
[GetFullFileName0 $arrayname COORDS_FILE]
has not been created.  Libcheck did not run successfully.
Check the log file for this job."
    return 0
  }

  if { $array(IFINITIALISE) } {sketch_delete_mol $sketch_data(sketch_array)}

  if { $array(ONEMOLLIB) } {
    set geomfile [GetFullFileName0 $arrayname DICT]
  } else {
    set geomfile [GetFullFileName0 $arrayname GEOM_FILE]
  }

  if { [ReadFile [GetLogFileName $job_id] logfile -split] } {
    if { [lsearch -regexp $logfile "has the minimal description"]  > 0 } {
      WarningMessage \
"The geometry library has only a minimal description of $array(CHEM_COMP_ID).
A full description has been generated but you should check 
the geometry description in  the output file:
$geomfile"
    }
  }


  if { $array(LOAD_HYDROGEN) } {
    set noh ""
  } else {
    set noh "-noh"
  }
  if { $array(IFINITIALISE) } {
    set append ""
  } else {
    set append "-append"
  }
  
  sketch_load_dict_coords $sketch_data(sketch_array) $array(CHEM_COMP_ID) \
	[GetFullFileName0 $arrayname COORDS_FILE] \
        $geomfile  $noh $append
}


#-------------------------------------------------------------------------
proc load_monomer_sort_library { arrayname args } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array
  global system
  global monomer_lib

  set save 0
  set mode dist
  set file {}
  set nargs [llength $args]; set n 0
  while { $n < $nargs } { 
    switch -regexp -- [lindex $args $n] \
    mode {
      incr n; set mode [lindex $args $n]
    } file {
      incr n; set file [GetFullFileName0 $arrayname [lindex $args $n]]
    } save {
      set save 1
    }
    incr n
  }


  PleaseWait "Retrieving list of all monomers in library.."

  set current_dir [GetCurrentDir]
  ChangeDirectory [GetDefaultDirPath TEMPORARY]
  if { [CreateDir [set working_dir libcheck_[GetPid]]] } {
    ChangeDirectory $working_dir
  } else {
    set working_dir [GetDefaultDirPath TEMPORARY]
  }
  set comfile [GetTmpFileName]
  set logfile [GetTmpFileName]
  if { $file != "" } {
    set comtext "_Y\nFILE_L $file\n_MON *\n_NODIST Y\n_END"
  } else {
    set comtext "_Y\n _MON *\n_END"
  }
  WriteFile $comfile $comtext -overwrite
  if { ![Execute "[BinPath libcheck]" $comfile program_status report -log $logfile] } {    
   PleaseWait
   WarningMessage "Error running Libcheck program see\n $logfile
Sorry - this means we can not list the monomers in the currently selected library"
   return 0 
  }

  DeleteFile libcheck.bat
  DeleteFile $comfile

  if  { ![ReadFile $logfile logtext -split]  } {
    WarningMessage "ERROR reading Libcheck log file $logfile
Sorry - this means we can not list the monomers in the currently selected library"
    return 0
  }

  set begin [lsearch $logtext *-list-begin*]
  set end [lsearch $logtext *-list-end*]
  if { $begin < 0 || $end < 0 } {
    WarningMessage "ERROR reading Libcheck log file  $logfile
Beginning and end of list not found.
Sorry - this means we can not list the monomers in the currently selected library"
    return 0
  }
  incr begin; incr end  -1

  foreach type [set tt [array names monomer_lib code,*]] { unset monomer_lib($type) }
  foreach type [array names monomer_lib name,*] { unset monomer_lib($type) }

  foreach line [lrange $logtext $begin $end] {
    set type [string trim [string range $line 59 69]]
    lappend name($type) [string trim [string range $line 10 45]]
    lappend code($type) [string trim [string range $line 1 9]]
  }
  foreach type [array names code] { lappend typelist $type }
  set monomer_lib(typelist) $typelist
  foreach type [array names code] {
    set monomer_lib(code,$type) $code($type)
    set monomer_lib(name,$type) $name($type)
  }

  if $save {
    set textout [WriteIdentifier {} "Sorted monomer library"]\n
    append textout "set monomer_lib(typelist) \[list $typelist]\n"
    foreach type [array names code] {
      append textout "set monomer_lib(code,$type) \[list $code($type) ]
set monomer_lib(name,$type) \[list $name($type) ]\n"
    }
# If mode = system then write data file to the ccp4i source directory
# If mode = user write to the users .ccp4i directory
    switch -regexp $mode \
    own {
      set libfile [FileJoin $system(DOT) CCP4I_TOP etc monomer_lib.tcl]
    } dist {
      set libfile [FileJoin [GetEnvPath CCP4I_TOP] etc monomer_lib.tcl]
    }

    if { ![WriteFile $libfile $textout  -overwrite ]  } {
      WarningMessage "ERROR writing the sorted library file $libfile"
    }
  }

  PleaseWait
  return 1

}

#------------------------------------------------------------------------------
proc load_monomer_lib_name { arrayname } {
#------------------------------------------------------------------------------
  upvar #0 $arrayname array

# User has selected a lib file to read - extract the name of the monomer

  if { ![ReadFile [GetFullFileName0 $arrayname DICT] libtext -split ]  } {
    WarningMessage \
      "ERROR reading monomer id from [GetFullFileName0 $arrayname DICT]"
    return 0
  }
  set nmon [ReadCifLoop $libtext _chem_comp properties data ]
  if { $nmon < 1 } {
    WarningMessage \
      "ERROR reading monomer id from [GetFullFileName0 $arrayname DICT]
No _chem_comp loop found in the file"
      return 0
  } elseif { $nmon > 1 } {
    WarningMessage \
      "ERROR This file contains more than one monomer - please use the
Load Monomer from Library option"
    return 0
  }

  set ii [lsearch $properties id]
  set chem_comp_id [lindex [lindex $data 0] $ii]

  set array(CHEM_COMP_ID) $chem_comp_id
  check_input $arrayname CHEM_COMP_ID
  load_monomer_chem_comp_id $arrayname
}
