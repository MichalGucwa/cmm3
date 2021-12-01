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
# pdb_restraints.tcl --
#
# CCP4Interface 
#
# =======================================================================

#---------------------------------------------------------------------
proc pdb_restraints_setup { typedefVar arrayname } {
#---------------------------------------------------------------------

  if { [catch { package require BLT } ] } {
    WarningMessage "Can not run Edit Restraints without the BLT extension to Tcl/Tk installed.  See your system manager or the CCP4i installation documentation."
    return 0
  }
  
  return 1
}

#-----------------------------------------------------------------------
proc pdb_restraints_task_window { arrayname } {
#-----------------------------------------------------------------------
  global configure
  upvar #0 $arrayname array
# In addition to the standard task array of pdb_restraints also use
# array restraints which contains the data read from PDB file and 
# displayed in tables
  global restraints

# will use pdb file utilities
  source [SearchPath TOP utils pdb_utils.tcl]

  if { ![CreateTaskWindow $arrayname  \
	"Edit Restraints in PDB File" Restraints \
	[list Information \
	"MODRES _ Modified Residues" \
	 "SSBOND - Disulphide Bonds" \
	 "LINK - Inter-Residue Bonds" \
	 "CISPEP - Cis Peptides"  ] \
	-action_buttons quit ] }  { return 0 }

# Add extra customised button for saving ot PDB
  set save [button $array(WINDOW).buttons.save -text "Save to Output File" \
        -font $configure(FONT_REGULAR) \
        -background $configure(COLOUR_PALE) \
        -command "pdb_restraints_save $arrayname restraints"  ]

# pack forget $array(WINDOW).buttons.dismiss
# pack $save $array(WINDOW).buttons.dismiss -side left
 pack $save -side left -expand 1
 
  OpenFolder file

  CreateInputFileLine line \
   "Enter name of PDB file to edit" \
   "PDB in" XYZIN DIR_XYZIN \
   -fileout XYZOUT DIR_XYZOUT -- \
   -setfileparam space_group_name SPACEGROUP \
   -command "restraints_load_pdb $arrayname restraints
		pdb_restraints_load_symops $arrayname"

  CreateOutputFileLine line \
    "Enter output file name (default as input file)" \
    "PDB out" XYZOUT DIR_XYZOUT


  CreateLine line \
    message "Default format is non-standard to accommodate all information" \
    widget STANDARD_FORMAT \
    label "Output in standard PDB format (some information may be lost)"


#-------------------------------------------------------------------information

  OpenFolder 1

  CreateLine line \
    message "Enter the space group name for a list of SymOps to use in SSBOND and LINK definitions" \
    label "The standard symmetry operations for space group" -italic \
    widget SPACEGROUP \
	-command "pdb_restraints_load_symops $arrayname" \
    label "are:"

# Create scrolling window for symmetry operators listing
   CreateText symops_id {} -height 6 -scroll
   set array(SYMOPS_WINDOW_ID) $symops_id

# List the MODRESs and LINKs defined in the dictionary

  if { [pdb_restraints_get_definitions $arrayname info_text] } { 
    CreateLine line \
      label "The MODRES Ids and LINK Modes defined in the dictionary:" -italic
    CreateText info_id $info_text -height 15 -scroll
    AppendTextWindow $info_id $info_text -init
  }


#---------------------------------------------------------------------- 
 
  OpenFolder 2

  OpenSubFrame frame

  set modres_spec [list  \
        [list modresId ID {} 5 {} \
                "ID code for this file (4 characters)" ] \
        [list modresRes ResNam {} 4 {} \
                "Residue name used in this file (3 characters)"] \
        [list modresChain Chain {} 2 {} \
                "Chain identifier( 1 character)" ] \
        [list modresSeqn SeqNum {} 5 {} \
                "Sequence number (4 figure integer)" ] \
        [list modresInsert Insert {} 2 {} \
                "Insertion code (1character)" ] \
        [list modresRename Rename logical 1 0 \
                "Rename the residue without modification? (CCP4 specific definition)"] \
        [list modresStdres LibNam {} 9 {} \
                "Standard library residue name (CCP4 specific:8 characters)"] \
        [list modresComment Comment {} 31 {} Comment \
                "Description of residue modification (30 characters)"] ]

  CreateTable $arrayname modres restraints $modres_spec $frame \
	-counter nModres

  CloseSubFrame

  OpenFolder 3

  OpenSubFrame frame

  set ssbond_spec [list  \
	[list ssbondRes1 Res1 {} 4 CYS \
		"Residue name for first residue(3 characters)" ] \
	[list ssbondChain1 Chain  {} 2 {} \
		"Chain identifier for first residue(1 character)" ] \
	[list ssbondSeqn1 SeqNum {} 5 {} \
		"Sequence number for first residue(4 figure integer)" ] \
	[list ssbondInsert1 Insert {} 2 {} \
		"Insertion code for first residue(1 character)"] \
        [list ssbondRes2 Res {} 4 CYS \
                "Residue name for second residue(3 characters)" ] \
        [list ssbondChain2 Chain  {} 2 {} \
                "Chain identifier for second residue(1 character)" ] \
        [list ssbondSeqn2 SeqNum {} 5 {} \
                "Sequence number for second residue(4 figure integer)" ] \
        [list ssbondInsert2 Insert {} 2 {} \
                "Insertion code for second residue(1 character)"] \
	[list ssbondInter "Find symm" logical 1 {} \
		"Is bond between residues in different asymmetric units?" ] \
	[list ssbondSymop1  Symop1 {} 7 {} \
	"Symmetry operation for first residue, (optional-will be found automatically)(6chars)" ]  \
        [list ssbondSymop2  Symop2 {} 7 {} \
                "Symmetry operation for second residue, (optional-will be found automatically)(6chars)" ] ]

  CreateTable $arrayname ssbond restraints $ssbond_spec $frame \
	-counter nSsbond

  CloseSubFrame

  OpenFolder 4

  OpenSubFrame frame

  set link_spec [list  \
        [list linkId Id {} 9 {} \
                "Code for link type - CCP4 specific (9 characters)" ] \
	[list linkAtom1 Atom {} 5 {} \
		"Atom name for first of linked atom(4 characters- upper case except 'Ca' for Calpha)" ] \
	[list linkAlt1 Alt {} 2 {} \
		"Atom alternate indicator code for second of linked atoms(1character)" ] \
	[list linkRes1 Res {} 5 {} \
		"Residue name for second of linked atoms(4 characters" ] \
        [list linkChain1 Chain {} 2 {} \
		"Chain identifier for second of linked atoms(1character)" ] \
        [list linkSeqn1 SeqNum {} 5 {} \
		"Sequence number for second of linked atoms(4 figure integer)" ] \
        [list linkInsert1 Insert {} 2 {} \
		"Insertion code for first of linked atoms(1 character)"] \
	[list linkAtom2 Atom {} 5 {} \
                "Atom name for second of linked atoms(4 characters - upper case except 'Ca' for Calpha)" ] \
        [list linkAlt2 Alt {} 2 {} \
                "Atom alternate indicator code for second of linked atoms(1character)" ] \
        [list linkRes2 Res {} 5 {} \
                "Residue name for second of linked atoms(4 characters" ] \
        [list linkChain2 Chain {} 2 {} \
                "Chain identifier for second of linked atoms(1character)" ] \
        [list linkSeqn2 SeqNum {} 5 {} \
                "Sequence number for second of linked atoms(4 figure integer)" ] \
        [list linkInsert2 Insert {} 2 {} \
                "Insertion code for second of linked atoms(1 character)"] \
        [list linkDistance Distance {} 10 {} \
		"Optional target distance between linked atoms" ] \
	[list linkInter "Find symm" logical 1 {} \
		"Is link between residues in different asymmetric units?" ] \
	[list linkSymop1 Symop1 {} 7 {} \
                "Symmetry operation for first residue (6 characters)" ]  \
        [list linkSymop2 Symop2 {} 7 {} \
                "Symmetry operation for second residue (6 characters)" ] ]


  CreateTable $arrayname link restraints $link_spec $frame \
	-counter nLink

  CloseSubFrame

  OpenFolder 5

  OpenSubFrame frame

  set cispep_spec [list  \
        [list cispepRes1 Res {} 5 {} \
        "Residue name for first of cis-peptide linked residues(4 characters" ] \
        [list cispepChain1 Chain {} 2 {} \
        "Chain identifier for first of cis-peptide linked residues(1character)" ] \
        [list cispepSeqn1 SeqNum {} 5 {} \
        "Sequence number for first of cis-peptide linked residues(4 figure integer)" ] \
        [list cispepInsert1 Insert {} 2 {} \
        "Insertion code for first of cis-peptide linked residues(1 character)"] \
        [list cispepRes2 Res {} 5 {} \
        "Residue name for second of cis-peptide linked residues(4 characters" ] \
        [list cispepChain2 Chain {} 2 {} \
        "Chain identifier for second of cis-peptide linked residues(1character)" ] \
        [list cispepSeqn2 SeqNum {} 5 {} \
        "Sequence number for second of cis-peptide linked residues(4 figure integer)" ] \
        [list cispepInsert2 Insert {} 2 {} \
        "Insertion code for second of cis-peptide linked residues(1 character)"] ]

  CreateTable $arrayname cispep restraints $cispep_spec $frame \
	-counter nCispep

  CloseSubFrame

# If no data is already loaded in the restraints array then initialise
  if { ![ElementExists restraints nModres] } {
    set restraints(nModres) 0
    set restraints(nSsbond) 0
    set restraints(nLink) 0
    set restraints(nCispep) 0
  } else {
# If data exists then draw the tables
    restraints_fill_tables $arrayname restraints
  }
  pdb_restraints_load_symops $arrayname

}

#-----------------------------------------------------------------------
proc restraints_load_pdb { arrayname restraintsVar } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array
  upvar #0 $restraintsVar restraints

  if { ![file exists [set pdb [GetFullFileName0 $arrayname XYZIN]]] } {
	return 0 }

  PleaseWait "Reading PDB file.."
  if { [MolReadPdbRestraints $restraintsVar $pdb ] <= 0 } { 
	PleaseWait; return 0 }

  restraints_fill_tables $arrayname $restraintsVar
  PleaseWait

}

#-----------------------------------------------------------------------
proc restraints_fill_tables { arrayname restraintsVar } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array
  upvar #0 $restraintsVar restraints

  foreach data_type [list \
	[list modres nModres] \
	[list ssbond nSsbond] \
	[list link nLink] \
	[list cispep nCispep]] {

# Delete any existing contents
    TableDeleteContents $arrayname [lindex $data_type 0]
	
    for { set n 1 } { $n <= $restraints([lindex $data_type 1]) } { incr n } {
      TableDrawRow $arrayname [lindex $data_type 0] $n
    }
  }
  update_main_scroll $array(WINDOW)
}

#-----------------------------------------------------------------------
proc pdb_restraints_save { arrayname restraintsVar } {
#-----------------------------------------------------------------------
# Save the restraints to the output PDB file
  upvar #0 $arrayname array
  upvar #0 $restraintsVar restraints

# Check if output file exists?
  set fileout [GetFullFileName0 $arrayname XYZOUT]
  if { [file exists $fileout] } {
    if { ![regexp Overwrite [ChooseOptionDialog \
     "Edit PDB Restraints" restraints \
     "Output file exists:$fileout" \
	[list "Abort Saving Restraints" Overwrite] ] ] } { return 0 }
  }

# Update the number of lines for each restraint type
  foreach data_type [list \
        [list modres nModres] \
        [list ssbond nSsbond] \
        [list link nLink] \
        [list cispep nCispep]] {
    set restraints([lindex $data_type 1]) \
	 [TableGetExtent $arrayname [lindex $data_type 0]]
  }

  if { ![MolCheckPdbRestraints $restraintsVar] } { return 0 }

  set standard ""; if { $array(STANDARD_FORMAT) } { set standard -standard }

  if { [MolWritePdbRestraints $restraintsVar \
	[GetFullFileName0 $arrayname XYZIN] \
	[set tmp_pdb [GetTmpFileName]] $standard] } {
#   puts "Written to $tmp_pdb"
   MoveFile $tmp_pdb [GetFullFileName0 $arrayname XYZOUT ] -overwrite
  } else {
   WarningMessage "Error writing data to PDB file. The temporary file
$tmp_pdb contains what has been written"
  }  
}

#-----------------------------------------------------------------------
proc pdb_restraints_load_symops { arrayname } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array

  if { $array(SPACEGROUP) != "" } {
    set symops [GetSpaceGroupSymops $array(SPACEGROUP)]
    set symm_textout \
        "Symmetry Operations for space group: $array(SPACEGROUP)\n\n"
    set n 0; foreach op $symops { incr n 
      append symm_textout "$n:   $op\n"
    }
    AppendTextWindow $array(SYMOPS_WINDOW_ID) $symm_textout -init
  }
}

#-----------------------------------------------------------------------
proc pdb_restraints_get_definitions { arrayname textoutVar } {
#-----------------------------------------------------------------------
  upvar #0 $arrayname array
  upvar $textoutVar textout

# Get the standard links and modres definitions from the cif file - don't 
# format it - we will just list it, as is, for the user.

  set libfile [FileJoin [GetEnvPath CLIBD_MON] mon_lib_com.cif] 
  append textout "The following data is taken from the file\n $libfile\n\n"

  if { ![ReadFile $libfile filetext -split -nocomments "^#" -noblank] } {
    append textout "ERROR: reading file\n"
    return 0
  }

  foreach dd [list \
   [list data_mod_list "Standard Modifications  - use in Mode column of MODRES" ] \
   [list data_link_list  "Standard Links - use in Id column of LINK" ] ] {

    if { [set fline [lsearch -regexp $filetext [lindex $dd 0] ]] > 0 } {
      if { [set lline [lsearch -regexp \
	 [lrange $filetext [expr $fline +1] end] ^data ] ] >= 0 } {
        set lline [expr $lline + $fline]
      } else {
        set lline [llength $filetext]
      }
      append textout "[lindex $dd 1]\n\n"
      foreach line [lrange $filetext $fline $lline] {
        append textout "$line\n"
      }
    }
    append textout "\n\n"
  }

  return 1

}
