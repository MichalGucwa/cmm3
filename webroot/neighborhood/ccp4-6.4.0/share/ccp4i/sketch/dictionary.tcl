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
# dictionary.tcl --
#
# CCP4Interface
# Accessed from the 2d sketch window
#
# =======================================================================

#----------------------------------------------------------------------
proc dictionary_setup { typedefVar arrayname } {
#----------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  global monomer_lib
  global sketch_data

# Will need to know something about contents of monomer_lib in order
# to check that the input chem_comp_id is unique
# The contents of release monomer_lib is saved in tcl format
# as etc/monomer_lib.tcl

  if { ![ElementExists sketch_data monomers_loaded] || \
       !$sketch_data(monomers_loaded) } {
    source [SearchPath TOP sketch load_monomer.tcl]
      set sketch_data(monomers_loaded) [load_monomer_sort_library $arrayname]
  }
# set the menu which lists chemical types
  set typedef(_dictionary_chem_comp_type)  [list menu [list non-polymer D-furanose \
   polymer L-peptide RNA L-pyranose D-pyranose solvent D-saccharid L-saccharid DNA] ]

  set typedef(_libcheck_input_mode) [list menu \
                           [list "displayed structure" "PDB file" "SMILES file" "Sybyl MOL2/SDF file" ] \
                           [list min pdb smiles mol2]]
  return 1

}

#------------------------------------------------------------------------
proc dictionary_task_window { arrayname args } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array
  global Mol

  if { [CreateTaskWindow $arrayname  \
        "Create Dictionary Entry" "Dictionary" \
        {} ] == 0 } return

#  SetProgramHelpFile 
  set array(IFLIBCHECK) 1

  set nargs [llength $args]; set n 0
  while { $n <= $nargs } {
    switch -- [lindex $args $n] \
    -iflibcheck { 
      incr n; set array(IFLIBCHECK)  [lindex $args $n]
    } -pdbin {
      incr n; set array(PDBIN)  [lindex $args $n]
      incr n; set array(DIR_PDBIN)  [lindex $args $n]
      set array(INPUT_MODE) pdb
    } -input_mode {
      incr n; set array(INPUT_MODE) [lindex $args $n]
    }  
    incr n
  }

 
# If user has previously run libcheck/refmac then should have ids set up already
  if { [ElementExists Mol chem_comp_id] && $Mol(chem_comp_id) != "" &&
        $array(CHEM_COMP_ID) == "" } { 
	set array(CHEM_COMP_ID) $Mol(chem_comp_id) 
        dict_generate_filenames $arrayname
  }

  OpenFolder protocol

  CreateTitleLine line TITLE

  if { $array(IFLIBCHECK) } {

  CreateLine line \
    label "Create description from" \
    widget INPUT_MODE


  OpenSubFrame frame -toggle_display INPUT_MODE open min

    CreateLine line \
      label "Unique identifier:" \
      message "Enter a one-word identifier - unique for your dictionary (_chem_comp.id)" \
      widget CHEM_COMP_ID -width 15 -oblig \
        -command "dict_generate_filenames $arrayname" \
      label "Full name:" \
      message "Enter a full name (_chem_comp.name)" \
      widget CHEM_COMP_NAME -width 40 -oblig

    CreateLine line \
      label "Type" \
      widget CHEM_COMP_TYPE

  CloseSubFrame

#  CreateLine line \
#    message "By default do not use atom types - Licheck will redefine them from the bond description" \
#    widget USE_TYPES \
#    label "Use any defined atom energy types"

#  if { $sketch(ifeditedplane) } {
#    CreateLine line \
#      message "By default do not use planar definitions - Licheck will find planes automatically" \
#      widget USE_PLANES \
#      label "Use user-defined planar groups"
#   } else {
#      set array(USE_PLANES) 0
#   }


  CreateLine line \
    message "Take ideal geometry from PDB file" \
    widget FROMCOOR \
    label "Extract geometry from the input PDB file" \
    toggle_display INPUT_MODE open pdb

  CreateLine line \
    message "Attempt to find the monomer in the dictionary database" \
    widget SEARCH \
    label "Search the dictionary for this monomer"

  CreateLine line \
    message "Refine the coordinates by running Refmac" \
    widget IFREFMAC \
    label "Regularise the structure with Refmac"

  CreateLine line \
    widget IFHYDROGEN \
    label "Load and display hydrogen atoms"

  } else {

  CreateLine line \
    label "Enter identifier for monomer as found in the library or geometry file:" \
    message "Enter a one-word identifier(_chem_comp.id)" \
    widget CHEM_COMP_ID -width 15 -oblig \
	-command "dict_generate_filenames $arrayname"

  CreateLine line \
    widget IFHYDROGEN \
    label "Load and display hydrogen atoms"

  }

  OpenFolder file

  if { $array(IFLIBCHECK) } {

    CreateInputFileLine line \
      "PDB File containing monomer" \
       "PDB in" PDBIN DIR_PDBIN \
        -toggle_display INPUT_MODE open pdb \
        -command "dict_generate_filenames $arrayname -pdb"
 
     CreateInputFileLine line \
      "Sybyl MOL2 File " \
       "MOL2 in" MOL2IN DIR_MOL2IN \
        -toggle_display INPUT_MODE open mol2 \
        -command "dict_generate_filenames $arrayname -mol2"

     CreateInputFileLine line \
      "SMILES string file" \
       "SMILES in" SMILESIN DIR_SMILESIN \
        -toggle_display INPUT_MODE open smiles \
        -command "dict_generate_filenames $arrayname -smiles"

    OpenSubFrame frame -toggle_display  INPUT_MODE open min

      CreateLine line \
      label "Save atom types and bond list for displayed monomer to file:" -itallic

      CreateOutputFileLine line \
      "CIF file to store the atom types and bond list you have entered" \
    "  Bond file" BONDLIST_FILE DIR_BONDLIST_FILE


    CloseSubFrame

    CreateLine line \
      label "Output dictionary file containing idealised geometry parameters:" -itallic

    CreateOutputFileLine line \
      "CIF file to contain geometry description of entry" \
      "Geom file" GEOM_FILE DIR_GEOM_FILE

  } else {

   CreateLine line \
      label "Enter name of geometry file or geometry library containing description of the monomer:" -itallic

   CreateInputFileLine line \
      "Geometry file or library containing geometry description of entry" \
      "Geom file" GEOM_FILE DIR_GEOM_FILE

  }


  CreateLine line \
    label "Output coordinate file for idealised coordinates:" -itallic

  CreateOutputFileLine line \
    "CIF file to containing idealised coordinates" \
    "Coord file" COORDS_FILE DIR_COORDS_FILE


}


#------------------------------------------------------------------------------
proc dict_generate_filenames { arrayname args } {
#------------------------------------------------------------------------------
  upvar #0 $arrayname array
  global typelist
  global monomer_lib

  if { [lsearch $args -pdb] >= 0 } {
# Read the residue name from the PDB file
    set array(CHEM_COMP_ID) ""
    if { [OpenFile [GetFullFileName0 $arrayname PDBIN] f r ] } {
      set pdb_file [split [read $f] \n]
      CloseFile $f
      set nlines [llength $pdb_file]
      set nl 0; while {$nl < $nlines && $array(CHEM_COMP_ID) == "" } {
        if [regexp "^ATOM " [lindex $pdb_file $nl]] {
          ParsePDBId [lindex $pdb_file $nl] atnam resnam resid segid
          set array(CHEM_COMP_ID) $resnam
        }
        incr nl
      }
    }
  } elseif  { [lsearch $args -mol2] >= 0 } {
    set sdf_file ""
    if  { [string equal ".sdf" [file extension $array(MOL2IN)]] &&
          [ReadFile [GetFullFileName0 $arrayname MOL2IN] sdf_file -split] } {
       set array(CHEM_COMP_ID) [string trim [lindex $sdf_file 0]]    
    } else {
      set array(CHEM_COMP_ID) [FileRootName $array(MOL2IN)]
    }
  } elseif  { [lsearch $args -smiles] >= 0 } {
    set array(CHEM_COMP_ID) [FileRootName $array(SMILESIN)]
    #puts "CHEM_COMP_ID $array(CHEM_COMP_ID)"
  } else {
    set array(CHEM_COMP_ID) [RemoveMetaChars $array(CHEM_COMP_ID)]
  }
  if { $array(CHEM_COMP_ID) == "" } { return }

# If running just regularise then just need to create name for output 
# coordinate file
  if { !$array(IFLIBCHECK) } { 
    set array(COORDS_FILE) $array(CHEM_COMP_ID)_regul.pdb
    CheckFileInput $arrayname COORDS_FILE save
    if { $array(GEOM_FILE) == "" } {
      set array(GEOM_FILE) $array(CHEM_COMP_ID)_mon_lib.cif
      if { ![file exists [GetFullFileName0 $arrayname GEOM_FILE] ] } {
	set array(GEOM_FILE) "" }
    }

  } else {

# User is trying to create a new monomer description
# Is this a novel id for a monomer?
    set unique 1
    foreach type $monomer_lib(typelist) {
      if { [lsearch $monomer_lib(code,$type) $array(CHEM_COMP_ID) ] >= 0 } {
        set unique 0
      }
    }
# Field is warning colour if id non-unique
    set_field_colour $arrayname CHEM_COMP_ID $unique
 
    if { $unique } {
# Generate file names for the output files
      set array(BONDLIST_FILE) $array(CHEM_COMP_ID)_bondlist.cif
      set array(GEOM_FILE) $array(CHEM_COMP_ID)_mon_lib.cif
      set array(COORDS_FILE) $array(CHEM_COMP_ID)_libcheck.pdb
#      set array(PSFILE) $array(CHEM_COMP_ID)_libcheck.ps
      CheckFileInput $arrayname BONDLIST_FILE save 
      CheckFileInput $arrayname GEOM_FILE save 
      CheckFileInput $arrayname COORDS_FILE save 
#      CheckFileInput $arrayname PSFILE save 
    } else {
      set array(BONDLIST_FILE) ""
      set array(GEOM_FILE) ""
      set array(COORDS_FILE) ""
    }
  }

}

#-----------------------------------------------------------------------------
proc dictionary_run { arrayname } {
#-----------------------------------------------------------------------------
  upvar #0 $arrayname array
  global Mol
  global monomer_lib
  global sketch_data

  if { $array(CHEM_COMP_ID) == "" || \
	( $array(IFLIBCHECK) && \
          [StringSame [GetValue $arrayname INPUT_MODE] "min"] &&\
          $array(CHEM_COMP_NAME) == "" ) } {
    WarningMessage "You MUST enter an identifier and name before proceeding"
    return 0
  }

  if { $array(IFLIBCHECK) } { 
# check that the chem_comp_id is unique 
# monomer_lib array contains lists of monomer library contents

    set duplicate ""
    foreach type $monomer_lib(typelist) {
      if { [set hit [lsearch $monomer_lib(code,$type) $array(CHEM_COMP_ID) ]] >= 0 } {
        set duplicate [lindex $monomer_lib(name,$type) $hit ]
      }
    }
    if { $duplicate != "" } {
      if { [regexp Abort [ChooseOptionDialog Dictionary  Dictionary "The identifier is not unique - already used for\n$duplicate \n Do you want to continue and possibly overwrite the existing entry or abort and enter and alternative code?" \
        [list Abort Continue ] -default 1 ] ] } {
         return 0
      }
    }
  }

  if { $array(IFLIBCHECK) &&  \
    [file exists [GetFullFileName0 $arrayname COORDS_FILE] ] } {
   
   for { set i  0 } { $i < 10 } { incr i } {
      set bak  [GetFullFileName0 $arrayname COORDS_FILE].bak$i
      if { ![file exists $bak] } { break }
    }
    set action [ChooseOptionDialog Warning Warning \
    "PDB file [GetFullFileName0 $arrayname COORDS_FILE] already exists, do you want to delete this file or make a backup to \n\n$bak" \
    [list "Abort run" Delete Backup]  -default 2 ]
    switch $action \
    Backup {
      MoveFile  [GetFullFileName0 $arrayname COORDS_FILE] $bak
    } Delete {
      DeleteFile  [GetFullFileName0 $arrayname COORDS_FILE]
    } default {
      return 0
    }
  }


# set the input file list
  if { $array(IFLIBCHECK) } {
    switch $array(INPUT_MODE) \
    min {
      set array(INPUT_FILES)  BONDLIST_FILE
    } pdb {
      set array(INPUT_FILES) PDBIN
    } 
  } else {
    set array(IFREFMAC) 1
    set array(INPUT_FILES) TMP_COORDS
  }

# set the output file list
  set array(OUTPUT_FILES) "COORDS_FILE"
  if { $array(IFLIBCHECK) } { append array(OUTPUT_FILES) " GEOM_FILE" }


# Save the chem_comp_id - may be used in rerun of libcheck/refmac
  set Mol(chem_comp_id) $array(CHEM_COMP_ID)
  set Mol(chem_comp_name) $array(CHEM_COMP_NAME)
  set Mol(chem_comp_type) $array(CHEM_COMP_TYPE)

# As a safety measure write a backup of the Mol array
  sketch_write_def_file $sketch_data(sketch_array) \
	-file [FileJoin [GetDefaultDirPath ] $array(CHEM_COMP_ID).def]

  set types ""
  if { $array(USE_TYPES) } { set types -type }
#  if { $array(USE_PLANES) } { append types " -plane" }

  if { $array(IFLIBCHECK) } {
    set array(TMP_COORDS) {}
    set array(DIR_TMP_COORDS) {}
    set status  [WriteCifBonds Mol [GetFullFileName0 $arrayname BONDLIST_FILE] \
			$types -chiral ]
  } else {
    set array(TMP_COORDS) $array(CHEM_COMP_ID)_coords_tmp.cif
    set array(DIR_TMP_COORDS) [GetCurrentProject]
    set status  [MolWriteCifCoords Mol [GetFullFileName0 $arrayname TMP_COORDS ] \
		-id $array(CHEM_COMP_ID)]
  }

# Set up to superpose on input PDB file if appropriate
  if { [ElementExists sketch ifpdbin] && $sketch(ifpdbin)  &&
	[file exists $sketch(pdbin)] } {
    set array(SUPERPOSE) 1
    set array(SUPERPOSE_PDBIN) $sketch(pdbin)
    set array(SUPERPOSE_RES) [lindex $sketch(pdbin_select) 2]
    set array(SUPERPOSE_CHAIN) [lindex $sketch(pdbin_select) 1]
  } else {
    set array(SUPERPOSE) 0
  }

  return $status

}

#-------------------------------------------------------------------------
proc dictionary_review { arrayname job_id } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array
  global sketch_data

  if { $array(IFHYDROGEN) } { set noh {} } else { set noh -noh }
  set coordsVar COORDS_FILE

  if { [regexp FINISHED [DbGetJobData $job_id STATUS]] } {

#      if { [regexp No [ChooseOptionDialog "Display Generated Coordinates" \
#        Display "Display the PDB coordinates file generted by Libcheck?
#If the geometry of the generated structure is poor try Regularisation (Edit menu)" \
#	[list No Yes] ] ] } {
#        return
#      }
      sketch_load_dict_coords $sketch_data(sketch_array) $array(CHEM_COMP_ID) \
	[GetFullFileName0 $arrayname $coordsVar] \
	[GetFullFileName0 $arrayname  GEOM_FILE] \
        $noh
  }
}

#--------------------------------------------------------------------------
proc WriteCifBonds { MolVar filename args } {
#--------------------------------------------------------------------------
  upvar #0 $MolVar Mol

  set output_atom_types 1
  set output_chiral 0
  set output_plane 0
  set use_type 0
  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    chiral {
      set output_chiral 1
    } type {
      set use_type 1
    } plane {
      set output_plane 1
    }
    incr n 
  }

# How many atoms are typed/charged?
  set ntyped 0
  set ncharged 0
  for { set n 1 } { $n <= $Mol(nAtoms) } { incr n } {
    switch $Mol(Type,$n) \
    no_type {
      set Mol(Typeout,$n) .
    } ""  {
      set Mol(Typeout,$n) .
      set Mol(Type,$n) no_type
    } default {
      incr ntyped
      set Mol(Typeout,$n) $Mol(Type,$n)
    }
    if { $Mol(Charge,$n) != "0" } { incr ncharged }
  }

  set text "#global_
#_lib_name         mon_lib
#_lib_version      1.4
#_lib_update       28/11/96
data_comp_list
loop_
_chem_comp.id
_chem_comp.name
_chem_comp.group
_chem_comp.desc_level
$Mol(chem_comp_id)   '$Mol(chem_comp_name)'  '$Mol(chem_comp_type)'   M
#
data_comp_$Mol(chem_comp_id)
#
loop_
_chem_comp_atom.comp_id                 
_chem_comp_atom.atom_id                 
_chem_comp_atom.type_symbol\n"
  set output_list [list Element]

  if { $use_type && $ntyped > 0 } {
    append text "_chem_comp_atom.type_energy\n"
    lappend output_list Typeout
  }
  if { $ncharged > 0 } {
    append text "_chem_comp_atom.partial_charge\n"
    lappend output_list Charge
  }
  
  for { set n 1 } { $n <= $Mol(nAtoms) } { incr n } {
    append text " $Mol(chem_comp_id) [write_cif_name $Mol(Name,$n)]"
    foreach output $output_list {
      append text "  " [string toupper $Mol($output,$n)]
    }
    append text \n
  }


append text "loop_
_chem_comp_bond.comp_id                 
_chem_comp_bond.atom_id_1               
_chem_comp_bond.atom_id_2
_chem_comp_bond.type\n"

  for { set n 1 } { $n <= $Mol(nBonds)} { incr n } {
    set a1 [lindex $Mol(Bonds,$n) 0]
    set a2 [lindex $Mol(Bonds,$n) 1]
    set type [lindex [list nowt single double triple deloc aromatic metal coval] $Mol(Bondtype,$n)]
    append text " $Mol(chem_comp_id)  [write_cif_name $Mol(Name,$a1)]  [write_cif_name $Mol(Name,$a2)]  $type\n"
  }

#  puts "text $text"

  if { $output_chiral && $Mol(nChiral) > 0 } {
    set ifmetal 0
    for { set ii 0 } { $ii < $Mol(nChiral) } { incr ii } {
      if { [regexp cross $Mol(Chirality,$ii)] } { set ifmetal 1 }
    }
    append text "loop_
_chem_comp_chir.comp_id
_chem_comp_chir.id
_chem_comp_chir.atom_id_centre
_chem_comp_chir.atom_id_1
_chem_comp_chir.atom_id_2
_chem_comp_chir.atom_id_3
_chem_comp_chir.volume_sign\n"
    if { $ifmetal } {
    append text \
"_chem_comp_chir.atom_id_4
_chem_comp_chir.atom_id_5
_chem_comp_chir.atom_id_6
_chem_comp_chir.atom_id_7
_chem_comp_chir.atom_id_8\n"
    }
    for { set n 1 } { $n <= $Mol(nChiral) } { incr n } {
      if { $n < 10 } { set id 0$n } else { set id $n }
      append text "$Mol(chem_comp_id) chir_$id  [write_cif_name $Mol(ChiralCentre,$n)] "
      for { set j 0 } { $j < 3 } { incr j } {
          append text [write_cif_name $Mol(ChiralNaybrs,$j,$n)] "  " }
      switch  -- $Mol(Chirality,$n) \
      + { append text "  positiv   " 
      } - { append text "  negativ   "
      } default { 
	if {$Mol(Chirality,$n) == "" } {
          append text "  both   " 
        } else {
          append text "   $Mol(Chirality,$n)  "
        }
      }
      if { $ifmetal } { for { set j 3 } { $j < 8 } { incr j } {
          append text [write_cif_name $Mol(ChiralNaybrs,$j,$n)] "  " } }
      append text "\n"
    }
  }

# output the planar group definitions
  if { $output_plane && $Mol(nPlane) > 0 } {
    append text "loop_
_chem_comp_plane_atom.comp_id
_chem_comp_plane_atom.plane_id
_chem_comp_plane_atom.atom_id
_chem_comp_plane_atom.dist_esd\n"
    for { set n  1 } { $n <= $Mol(nPlane)  } { incr n } {
      foreach atom $Mol(plane,$n) {
        append text "$Mol(chem_comp_id) plan-$n  [write_cif_name $atom] $Mol(plane_dev,$n)\n"
      }
    }
  }
  foreach m [array names Mol Typeout] { puts "unsetting $m"; unset Mol($m) }
  return [WriteFile $filename $text -overwrite]

}
