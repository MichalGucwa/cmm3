#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#=========================================================================#
# CCP4 Interface pdb_utils.tcl
#
#
# Coordinate Handling Utilities
#
#=========================================================================

#CCP4i_cvs_Id $Id$

#d_index_title Coordinate Handling Utilities (utils/pdb_utils.tcl)
#-------------------------------------------------------------------------
  proc GetPDBContents { pdb_file nresVar contentsVar total_heavyVar }  {
#-------------------------------------------------------------------------
#d_sum Get the atomic contents of PDB file
#d_desc Thi is based on rwcontents program
#d_desc  Return the content in the format of a nest list \
  { { element_type_1 n_atoms_type_1 } .... \
  { element_type_n n_atoms_type_n } } \
#d_arg pdb_file Input PDB file
#d_arg nresVar Returned number of residues in the file
#d_arg contentsVar Returned the content  of the PDB by element 
#d_arg total_heavyVar Returned the total number of non-hydrogen atoms

  upvar $nresVar nres
  upvar $contentsVar contents
  upvar $total_heavyVar total_heavy

  set contents ""
  set total_heavy 0
  set total_h 0
  set nres 0
  set lastid -999

  if { ![OpenFile $pdb_file f r ] } { return 0 }
  set pdb_file [split [read $f] \n]
  CloseFile $f

  for { set n 0 } { $n <= 60 } { incr n } {
    set nat($n) 0
  }

  foreach line $pdb_file {
  if [regexp "^ATOM " $line] {
    ParsePDBId $line atnam resnam resid segid
    if { $resid != $lastid } {
      set rescode [GetAminoInfo $resnam nh]
      if { $rescode <= 20 } { incr nres }
      incr total_h $nh
      set lastid $resid
    }
    ParsePDBIz $line iz
    incr nat($iz) 
    if { ![regexp "^H" $atnam] } { incr total_heavy }
  } }
  lappend contents [list  H $total_h ]
  for { set n 1 } { $n <= 60 } { incr n } {
  if { $nat($n) > 0 } {
    lappend contents [list [AtomType $n] $nat($n)]
  } }
#  puts "total_h $total_h"
#  puts "nres $nres"
#  puts "contents $contents"
  unset nat
  return 1
}

#-----------------------------------------------------------------------
proc AtomType { atomic_number } {
#-----------------------------------------------------------------------
#d_sum Return the Element name for a given atomic number
#d_arg atomic_number Atomic numer
  set type [ lindex  \
   [list H HE  \
        LI BE                               B  C  N  O  F  NE  \
        NA MG                               AL SI P  S  CL AR  \
        K  CA SC TI V  CR MN FE CO NI CU ZN GA GE AS SE BR KR \
        RB SR Y  ZR NB MO TC RU RH PD AG CD IN SN SB TE I  XE \
        CS BA LA HF TA W  RE OS IR PT AU HG TL PB BI PO AT RN  \
        FR RA AC \
        CE PR ND PM SM EU GD TB DY HO ER TM YB LU \
        TH PA U  NP PU AM CM BK CF ES FM MD NO LR ]   \
        [expr $atomic_number - 1 ] ]
  return $type
}

#-----------------------------------------------------------------------
proc GetAminoInfo { AA nhVar } {
#-----------------------------------------------------------------------
#d_sum Return some information for a given input amino acid type
#d_desc This currently will only return the number of non-hydrogen atoms \
in the residue, but could easily be extended with alternative information
#d_arg AA Input 3-letter amino acid code (upper case)
#d_arg nhVar Return the number  of non-hydrogen atoms
  upvar $nhVar nh
  set pp [lsearch { ALA ARG ASN ASP CYS CYH GLN
		    GLU GLY HIS ILE LEU LYS MET PHE PRO
		    SER THR TRP TYR VAL HEM WAT SUL } $AA ]
  if { $pp < 0 }  { set nh 0; return 0 }
  set nh [ lindex { 5   13  6   4   5   5   8
                    6   3   8   11  11  13  9   9   7
                    5   7   10  9   9   17  2   0 } $pp ]
  return [expr $pp + 1 ]
}

#------------------------------------------------------------------------
proc ParsePDBId { line atnamVar resnamVar residVar segidVar } {
#------------------------------------------------------------------------
#d_sum Extract the cards relevant to the atom id from a PDB ATOM line
#d_arg line Input line of PDB file (must be ATOM/HETATM card)
#d_arg atnamVar Returned atom name
#d_arg resnamVar Returned residue type
#d_arg residVar Returned residue id
#d_arg segidVar Returned segment id
  upvar  $atnamVar atnam
  upvar  $resnamVar resnam
  upvar $residVar resid
  upvar $segidVar segid
  set atnam [string trim [string range $line 12 15] ]
  set resnam [string trim [string range $line 17 19] ]
  set resid [string trim [string range $line 23 25] ]
  set segid [string range $line 21 21]
  
#  puts "atnam $atnam resnam $resnam resid $resid segid $segid"
}

#------------------------------------------------------------------------
proc ParsePDBIz  { line izVar } {
#------------------------------------------------------------------------
#d_sum Extract atomic number from PDB atom card (or element type from name)
#d_desc If the atomic number is missing from columns 69-70 then guesstimate \
the element type from the atom name and return the atomic number
#d_arg line Input line of PDB file (must be ATOM/HETATM card)
#d_arg izVar  Return the atomic number
  upvar $izVar iz
  set iz [string trim [string range $line 68 69 ] ]
  if { $iz == "" } { 
    set ele_list "H C N O P S"
    set atm [string trim [string range $line 12 15] ]
    set pp  [lsearch {H C N O P S} [string range $atm 0 0] ]
    if { $pp < 0 } { set iz 0; return 0 }
    set iz [lindex {1 6 7 8  15 16 } $pp]
  }
  return 1
}

#------------------------------------------------------------------------
proc PDBRemoveZeroOcc { filein fileout nzerosVar args } {
#------------------------------------------------------------------------
#d_sum Remove atoms with zero occupancy from PDB file
#d_arg filein Input PDB file name
#d_arg fileout Output PDB file name
#d_arg nzerosVar Return the number of zero occupancy atoms
#d_opt0 -chain sel_chain
#d_opt1 Apply the edit only to the specified chain


  upvar $nzerosVar nzeros

  set sel_chain ""
  set if_sel_chain 0
  set n 0; set nargs [expr [llength $args] - 1]
  while { $n <= $nargs } {
    set comd [lindex $args $n]
    if [regexp -- -chain $comd] {
      incr n; set sel_chain [lindex $args $n]; set if_sel_chain 1
    }
    incr n
  }

  set nzeros 0

  if { ![ReadFile $filein pdbfile -split] } { return 0 }
  set output ""

  foreach line $pdbfile {
    if { ![regexp "^ATOM " $line] } {
      append output $line \n
    } elseif { $if_sel_chain } {
      ParsePDBId $line atnam resnam resid chain
      if { $chain != $sel_chain || [string range $line 56 59] != "0.00" } {
        append output $line \n
      } else {
        incr nzeros
      }
    } elseif { [string range $line 56 59] != "0.00" } {
      append output $line \n
    } else {
      incr nzeros
    }
  }
  
  return [WriteFile $fileout $output]
}

#--------------------------------------------------------------------
proc ExtractPdbColumns { file column_list outputVar args } {
#--------------------------------------------------------------------
  upvar $outputVar output
#d_sum Extract columns from the ATOM records of a PDB file
#d_desc Extract columns from the ATOM records of a PDB file \
beware this assumes a very consistent PDB file format \
with spaces between all columns.
#d_arg file - input file name
#d_arg colum n_list - Tcl list of number of the column(s) to return  (NB 0=first column)
#d_arg outputVar - output as a Tcl list of lists

  if { ![ReadFile $file pdbfile -split] } { return 0 }

  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    set comd [lindex $args $n]
  }
  set output {}

  foreach line $pdbfile {
    if [regexp "^ATOM " $line] {
      set ll {}
      foreach column $column_list {
        append ll "[lindex $line $column] "
      }
      append output "[string trimright $ll]\n"
    }
  }
}

#--------------------------------------------------------------------
proc MergePdbFiles { fileout filesin } {
#--------------------------------------------------------------------
#d_sum  Merge 2 or more PDB files 
#d_desc This procedure removes the header info from the second \
and subsequent files. It does not check for unique chain names.
#d_arg fileout Output file name
#d_arg filesin A list of input files.

  WriteToLog "Merging models into file $fileout"

  set ifile 0
  if { ![OpenFile $fileout f w ] } { 
    WriteToLog "Can not open output pdb $fileout"
    return 0 
  }
  foreach file $filesin { incr ifile
    if { ![ReadFile $file text -split] } { return 0 }
    if { $ifile == 1 } {
      foreach line $text {
        if { ![regexp {^END|^MODEL} $line]} { puts $f $line }
      }
    } else {
      foreach line $text {
        if [regexp {^ATOM|^HETATM} $line] { puts $f $line }
      }
    }
  }
  CloseFile $f
  return 1
}
#----------------------------------------------------------------------------
proc PdbGetChains { file chainVar chain_rangeVar args } {
#----------------------------------------------------------------------------
#d_sum Get a list of the chains and the first & last residue ids in a PDB file
#d_desk Note: in this case first and last equate to lowest and highest numbering
#d_arg file Input PDB file
#d_arg chainVar Returned list of chain ids
#d_arg chain_rangeVar Returned nested list  of first and last residues in chains
#d_opt0 -nowat
#d_opt1 Ignore atoms of type HOH|WAT|H2O|SOL
#d_opt0 -atomid
#d_opt1 Return the ids of the first and last atoms in a chain 
  upvar $chainVar chain
  upvar $chain_rangeVar chain_range
  set chain {}
  set chain_range {}
  set last_res ""
  set first_res ""
  set water 1
  set atomid 0

  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    nowat {
      set water 0
# return the atom id (ie the atomid) rather than the residue id
    } atomid {
      set atomid 1
    }
    incr n
  }

  if { ![ReadFile $file text -split] } { 
    puts "ERROR reading file $file"
    return 0 
  }
  foreach line $text { if { [regexp {^ATOM|^HETATM} $line] } {
    if { [lsearch -exact $chain [string range $line 21 21]] < 0 } {
      lappend chain [string range $line 21 21]
      if { $last_res != "" } { 
	lappend chain_range [list $first_res [string trim $last_res]] }
      if { $atomid } {
        set first_res [string trim [string range $line 6 10]]
      } else {
        set test_res [string trim [string range $line 22 25]]
        set first_res $test_res
        set last_res $test_res
      }
      lappend restype [string trim [string range $line 17 19]]
    } else {
      if { $atomid } {
        set last_res [string range $line 6 10]
      } else {
        set test_res [string trim [string range $line 22 25]]
        if { $test_res < $first_res } { set first_res $test_res }
        if { $test_res > $last_res } { set last_res $test_res }
      }
    } 
  }}
  lappend chain_range [list $first_res [string trim $last_res]]
  if { !$water } {
    for {set n [expr [llength $restype] -1] } { $n >= 0 } { incr n -1 } {
       if { [regexp HOH|WAT|H2O|SOL [lindex $restype $n] ] } {
          set chain_range [lreplace $chain_range $n $n]
          set chain [lreplace $chain $n $n]
       }
    }
  }
#  puts "chain $chain chain_range $chain_range"
  return 1
}

#-----------------------------------------------------------------------------
proc HandleHarvestFile { mode pname dname program } {
#-----------------------------------------------------------------------------

#d_sum Add the output harvest file to the output file list for a job
#d_desc Dependent on the mode add the name of a harvest file to the \
output file list for the job. This will make the harvest file visible \
to the user.  The file name is generated automatically by the program from \
the environment variables  - see $CCP4/html/harvesting.html. \
the same file name generation is reproduced here.
#d_arg mode Harvest mode - should be NOHARVEST, PROJECT or HARVEST -see 
#d_ref CCP4_utils
#d_arg pname project name 
#d_arg dname dataset name
#d_arg program name of the program as understood by the harvest mechanism

  global job_params

  # Generate harvest filename
  set filen $dname.$program

  switch -regexp -- $mode {\
    ^NOHARVEST {
      return 1
    }
    ^CURRENTDIR {
      set filename [FileJoin [pwd] $filen]
      AddOutputFile $filename {}
    }
    ^PROJECT|HARVEST {
      set path [GetEnvPath HARVESTHOME 0]
      if { $path == "" } {
        set path [GetEnvPath HOME]
      }
      set filename [FileJoin $path DepositFiles $pname $filen]
    }
  }
  # The original harvest file may be overwritten by future runs
  # so make a copy in the current project directory & associated
  # with the current job
  set filen [file join [GetCurrentProjectDir $job_params(PROJECT)] \
		 [join [list $job_params(PROJECT) "_" $job_params(JOB_ID) \
			    "_" [file tail $filename] ".cif"] {} ]]

  CopyFile $filename $filen -overwrite

  # Add to the list of output files
  AddOutputFile $filen [GetCurrentProject]

  return 1
}


#-------------------------------------------------------------------------------
proc FindNCSTransforms { xyzin chains chain_range } {
#-------------------------------------------------------------------------------
#d_sum For multi-chain PDB find the inter-chain transformations using Lsqkab program
#d_desc The procedure useful in a job script - currently used for analysis \
in Molrep job.
#d_desc For all pairwise combinations of chains find the transformation to superpose \
the two chains and output in short table.  The full output of Lsqkab is not \
reported in the log file.
#d_arg	xyzin	Input PDB file
#d_arg	chains	A list of chain names
#d_arg	chain_range	A two element list of the first and last residue ids \
which will be superposed

  set textout "\nAnalysing transformations between the molecules\n
Angle = angle between the axis of rotation and the vector connecting the centroid of the molecules
Rot  = Angle of rotation to superpose molecules\n\n
Mol_1 Mol_2 Direction_Cosine_of_Axis      Angle     Rotation  Translation\n"

  set TMPLOG [GetTmpFileName -ext log]
  set TMPPDB [GetTmpFileName -ext pdb]
  
  for { set m 1 } {  $m < [llength $chains] } { incr m } {
    set mm [expr $m -1]

# Run pdbset to cut out one molecule 
    WriteFile [set pdbset_com [GetTmpFileName -ext com]] \
                "select chain [lindex $chains $mm]\nend" -overwrite

    set PDB_CHAIN1 [GetTmpFileName -ext chain_[lindex $chains $mm] _pdb]
    set status [Execute "[BinPath pdbset] XYZIN \"$xyzin\" XYZOUT \"$PDB_CHAIN1\""  \
        $pdbset_com program_status report -log $TMPLOG ]

    DeleteFile $TMPLOG

    set range0 [lindex $chain_range $mm]

    for { set n [expr $m + 1]  } { $n <= [llength $chains] } { incr n } {
      set nn [expr $n - 1]

      set range [lindex $chain_range $nn]
      WriteFile [set lsq_com [GetTmpFileName -ext com]] \
"fit res CA [lindex $range 0]  to [lindex $range 1] wch [lindex $chains $nn]
match res CA [lindex $range0 0] to [lindex $range0 1] rch [string toupper [lindex $chains $mm]]
output rms
end" -overwrite

      set status [Execute "[BinPath lsqkab] XYZINR \"$PDB_CHAIN1\" XYZINW \"$xyzin\" XYZOUT \"$TMPPDB\"" \
        $lsq_com program_status report -log $TMPLOG -noexit ]


# Extract the transformations from the log file
      if { $status } {
        ReadFile $TMPLOG logtext 
        DeleteFile $TMPLOG
        DeleteFile $TMPPDB

        if { [ExtractTextLine $logtext "TRANSLATION VECTOR IN fractions" \
		0 [list 7 8 9]  trans]  } {
	  ExtractTextLine  - "SPHERICAL POLARS"  0 all line
          ExtractTextLine - "SPHERICAL POLARS"  0 7 rotang
          ExtractTextLine - "DIRECTION COSINES" 0 [list 5 6 7] dircos
          ExtractTextLine - "Angle between rotation axis" 0 7 axis_angle
       
          append textout "[format \
	     "%-6s%-6s%-10.2f%-10.2f%-10.2f%-10.2f%-10.2f%-10.3f%-10.3f%-10.3f" \
	     [lindex $chains $mm] [lindex $chains $nn] \
	     [lindex $dircos 0] [lindex $dircos 1] [lindex $dircos 2] \
             $axis_angle  $rotang \
             [lindex $trans 0] [lindex $trans 1] [lindex $trans 2] ]\n"
        }
      }
    }
  }

  WriteToLog $textout
}

#d_intro_title Mol Procedures for Handling Coordinate Data
#d_intro The series of procedures Mol* are for handling coordinate data and \
are particularly used in the Sketcher module but could be helpful elsewhere.\
The coordinate data is loaded into a global array which is usually called Mol \
but the name is passed into the utility procedures so potentially different \
molecules could be loaded into different arrays.  NOTE: These utilities are \
fine for a small number of atoms but will become slow or frozen for anything \
like a real protein.  The procedures for reading the data can extract a \
specified residue from a large PDB file efficiently.

#d_intro The elements of the Mol array are indexed by the atom number na \
which  starts at 1 (not 0): 
#d_intro   Name,$na	the atom name
#d_intro   Element,$na 	the atom element type
#d_intro   Type,$na 	the atom type (default is 'no_type')
#d_intro   Charge,$na	the formal, unit charge on the atom
#d_intro   Coor,$na	the coordinates as a tcl list [list $x $y $z]
#d_intro   frag,$na	an integer indicating which fragment of the molecule the atom belongs to - this is only set after calling MolFindFragments

#d_intro The elements indexed by the bond number nb:
#d_intro   Bonds,$nb	a list of two atom number for two connected atoms
#d_intro   Bondtype,$nb	the bondtype - an integer for the formal bond order
#d_intro
#d_intro   nAtoms	number of atoms
#d_intro   nBonds	number of bonds
#d_intro   chem_comp_id the monomer id as used in CIF libraries
#d_intro   XY 		A list of coordinates - the coordinate of each atom is a 3 item list. 
#d_intro   The first item of the list is 'NULL' so the atom numbers which start at 1 can index into the list.

#--------------------------------------------------------------------
proc MolReadPDB { MolVar file args } {
#--------------------------------------------------------------------
  upvar #0 $MolVar Mol

#d_sum Read some or all atoms from a PDB file into the Mol array
#d_desc Reading the PDB file of a whole protein will be very slow. \
It is possible to read an individual residue using the select option. \
Note that the procedure sketch_open_file in sketch.tcl shows how to \
create a file selection window with extra options to select a residue.
#d_arg MolVar	The name of the global array to be loaded
#d_arg file	Name of PDB file name
#d_opt0 -select	[list restype chain_id resid_id]
#d_opt1	Read only the first residue which matches the input residue type \
(restype), chain id and residue id (resid_id).  One or two of the three \
elements in the input can be null - and there will be no requirement to \
match that identifier.
#d_opt0 -noh
#d_opt1 Do not read in hydrogen atoms.

  set select 0
  set ifhydrogen 1
  set done_reading 0
  set sel_restype ""
  set sel_chain ""
  set sel_resid ""
  set save_residue 0

  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp  -- [lindex  $args $n] \
    select {
      set select 1
      incr n; set sel [lindex $args $n]
      set sel_restype [string toupper [lindex $sel 0]]
      set sel_chain [lindex $sel 1]
      set sel_resid [lindex $sel 2]
    } noh {
      set ifhydrogen 0
    } save {
      set save_residue 1
      incr n; set save_residue_file [lindex $args $n]
      set save_residue_text ""
    }
    incr n
  }

  if { ![ReadFile $file filetext -split] } { 
    WarningMessage "ERROR reading the file $file"
    return 0
  }

  set Mol(XY) NULL

  if { [ElementExists Mol nAtoms] } {
    set na $Mol(nAtoms)
  } else {
    set na 0
  }
  set ifat [expr $na +1]

  foreach line $filetext { 
     if { [regexp {^ATOM|^HETATM} $line] } {
     if { !$select ||
      ( ( $sel_restype == "" || [string first $sel_restype $line] > 0 ) &&
        ( $sel_chain == "" ||  [regexp $sel_chain [string index $line 21] ] ) &&
        ( $sel_resid == "" || $sel_resid == \
                    [string trim [string range $line 22 25]] )) } {
       if { $sel_restype == "" } { set sel_restype [string trim [string range $line 17 19] ]}
       if { $sel_chain == "" } { set sel_chain [string index $line 21] }
       if { $sel_resid == "" } { set sel_resid [string trim [string range $line 22 25]] }
       set done_reading 1
# extract the element & atom name fields - try to figure out the atom type
       set ele [string trim [string range $line 76 77]]
       set name  [string range $line 12 15]
       if { $ele == "" } { set ele [MolPdbElement $name] }
# Possibly skip hydrogen atoms
       if { $ifhydrogen || $ele != "H" } {
         incr na; set skip 0
         if { [lsearch [list 0 1 2 3 4 5 6 7 8 9 * ' \"] \
                     [string index $name 0]] >= 0 } {
           set nam0 [string range $name 1 end]
           while  { [regsub " " $nam0  _ nam]}  { set nam0 $nam } 
           set Mol(Name,$na) $nam
           append Mol(Name,$na) [string index $name 0]
         } else {
           set Mol(Name,$na) [string trim $name]
         }
         set Mol(Element,$na) $ele
         set Mol(Type,$na) no_type
         set Mol(Charge,$na) 0
         set x [string trim [string range $line 30 37] ]
         set y [string trim [string range $line 38 45] ]
         set z [string trim [string range $line 46 53] ]
         set Mol(Coor,$na) [list $x $y $z ]
         lappend Mol(XY) [list $x $y $z ]
         if { $save_residue } { lappend save_residue_text $line }
       }  
     } elseif { $done_reading } {
# have read at least one atom but have got to non-selected atom 
# so assume we have done reading the residue
       break
     }}
  }
  set Mol(chem_comp_id) $sel_restype
  set Mol(filename) $file
  set Mol(nAtoms) $na
  set Mol(dimension) 3
  MolCheckReadFile Mol -first $ifat
  if { $save_residue } {
    WriteFile $save_residue_file $save_residue_text -overwrite
  }
  return [list $na $sel_restype $sel_chain $sel_resid]
}

#----------------------------------------------------------------
proc MolReadCif { MolVar file args } {
#----------------------------------------------------------------
  upvar #0 $MolVar Mol

#d_sum Read atoms from a CIF file into the Mol array
#d_desc Reading many atoms will be slow.
#d_arg MolVar   The name of the global array to be loaded
#d_arg file     Name of CIF file name
#d_opt0 -noh
#d_opt1 Do not read in hydrogen atoms.

  if { ![ReadFile $file filetext -split -noblank -nocomment ^# ] } {
    WarningMessage "ERROR reading file $file"
    return 0
  }

  set noh 0
  
  set nargs [llength $args]; set n 0
  while { $n <= $nargs } {
    switch -regexp -- [lindex $args $n] \
    noh {
      set noh 1
    }
    incr n
  }

# try reading the structure id from file
  if { [set id_line [lsearch -regexp $filetext data_structure_]]  < 0 ||
     [regsub data_structure_ [lindex $filetext $id_line] "" monomer_id ] <= 0 } {
    set monomer_id ""
  }

  if { [ElementExists Mol nAtoms] } {
    set na $Mol(nAtoms)
  } else {
    set na 0
  }
  set ifat [expr $na +1]
  set Mol(XY) {}; lappend Mol(XY) NULL
  set atom_site 0; set noindex 1
  foreach line $filetext {
    if { [regexp _atom_site $line] } {
# Make a list of the elements of the atom_site loop
      lappend atom_site_format [string trim [lindex [split $line .] 1 ] ]
      set atom_site 1
    } elseif { $atom_site } {
       if { [regexp loop_ $line] } { return }
       if { $noindex } {
# work out where the lements we are interested in come on the line
         set name_index [lsearch -exact $atom_site_format label_atom_id ]
         set element_index [lsearch -exact $atom_site_format type_symbol ]
         set x_index  [lsearch -exact $atom_site_format Cartn_x]
         set z_index  [lsearch -exact $atom_site_format Cartn_z]
         set noindex 0
       }
       set ele [lindex $line $element_index]
       if { $ele != "" && ( !$noh || ![StringSame H $ele] ) } {
         incr na
         set Mol(Name,$na) [read_cif_name [lindex $line $name_index]]
         set Mol(Type,$na) no_type
         set Mol(Charge,$na) 0
         set Mol(Element,$na) $ele
         set Mol(Coor,$na) [lrange $line $x_index $z_index]
         lappend Mol(XY) [concat [lrange $line $x_index $z_index] ]
       }
    }
  }
  set Mol(nAtoms) $na
  set Mol(chem_comp_id) $monomer_id
  puts "Read $na atoms from CIF file"
  set Mol(dimension) 3
# Check no whackiness in atom nsaes etc.
  MolCheckReadFile Mol -first $ifat
  return $na

}

#-------------------------------------------------------------------------
proc read_cif_name { name } {
#-------------------------------------------------------------------------
#d_sum Strip the inverted commas (quotes) from a cif atom name
#d_desc CIF definitions require quotes about any atom name containing \
a quote character.  This function returns the name stipped of \
surrounding quotes.
#d_arg	name	Atom name from CIF file

  if { [regexp ^' $name ] && [regexp '$ $name] } {
   set name [string range $name 1 [expr [string length $name] -2]] }
  
  return $name
}

#----------------------------------------------------------------
proc MolReadSybyl { MolVar file args } {
#----------------------------------------------------------------
#d_sum Read some or all atoms from a Sybyl file into the Mol array
#d_desc Reading many atoms will be slow. \
This procedure has not been seriously used or tested.
#d_arg MolVar   The name of the global array to be loaded
#d_arg file     Name of Sybyl file name
#d_opt0 -noh
#d_opt1 Do not read in hydrogen atoms.

  upvar #0 $MolVar Mol

# Read Sybyl mol2 format file 

  if { ![ReadFile $file filetext -split] } {
    WarningMessage "ERROR reading file $file"
    return 0
  }

  set noh 0
  set nargs [llength $args]; set n 0
  while { $n <= $nargs } {
    switch -regexp -- [lindex $args $n] \
    noh {
      set noh 1
    }
    incr n
  }

  if { [ElementExists Mol nAtoms] } {
    set na $Mol(nAtoms) } else { set na 0 }
  if { [ElementExists Mol nBonds] } {
    set nb $Mol(nBonds) } else { set nb 0 }
  set molnat 0
  set Mol(XY) {}; lappend Mol(XY) NULL
  set mode ""

  foreach line $filetext {
    if { [regexp {\@\<TRIPOS\>ATOM} $line] } {
      set mode atom
    } elseif  { [regexp {\@\<TRIPOS\>BOND} $line] } {
      set mode bond
    } else {
      switch $mode \
      atom {
        set ele [lindex $line 1]
        if { $ele != "H" || !$noh } { 
          incr na; incr molnat
          set Mol(Element,$na) $ele
# Set the atom name 
          set Mol(Name,$na) [subst $ele]$molnat
          set Mol(Type,$na) [MolConvertSybylType [lindex $line 5]]
          set Mol(Coor,$na) [lrange $line 2 4]
          append Mol(XY) [concat [lrange $line 2 4] ]
        }
#        puts "na $na $Mol(Element,$na) $Mol(Name,$na) $Mol(Type,$na)"
      } bond {
        set iat1 [expr [lindex $line 1] + $Mol(nAtoms)]
        set iat2 [expr [lindex $line 2] + $Mol(nAtoms)]
# Check if the bond is to a H atom 
        if { ![ElementExists Mol Type,$iat2] || $Mol(Type,$iat2) == "H" } {
          if { !$noh } {
            incr nb; set Mol(Bonds,$nb) "$iat1 $iat2"
            set Mol(Bondtype,$nb) [MolConvertSybylBond [lindex $line 3]]
# Reset the H atom name - the array nat is counter of number of H atoms
# bonded to each non-H atom
            if { [catch incr nat($iat1)] } { set nat($iat1) 1 }
            set Mol(Name,$iat2) H[subst $iat1]$nat($iat1)
#           set Mol(Type,$iat2) ??
          }
        } else {
          incr nb; set Mol(Bonds,$nb) "$iat1 $iat2"
          set Mol(Bondtype,$nb) [MolConvertSybylBond [lindex $line 3]]
        }
      }
    }
  }
  set Mol(nAtoms) $na
  set Mol(nBonds) $nb
  puts "Read $molnat atoms from Sybyl file"
  set Mol(dimension) 3
  return $molnat
}

#----------------------------------------------------------------
proc MolConvertSybylType { type } {
#----------------------------------------------------------------
#d_sum placemarker for code to convert Sybyl atom types
  set t [lindex [split $type .]  1]
  if { $t == "" } { set t H }
  return $t
}
#----------------------------------------------------------------
proc MolConvertSybylBond { type } {
#----------------------------------------------------------------
#d_sum placemarker for code to convert Sybyl bond types
  if { $type == "ar" } { set type 1 }
  return $type
}

#----------------------------------------------------------------
proc  MolBoundingBox { MolVar minboundVar maxboundVar aveVar args } {
#----------------------------------------------------------------
#d_sum Find centre of mass and bounding box for coordinates in Mol
#d_desc Useful for centering molecule in display
#d_arg MolVar	Name of Mol array
#d_arg minboundVar Returned list of minimum values of x,y,z
#d_arg maxboundVar Returned list of maximum values of x,y,z
#d_arg aveVar	Returned list of average coordinates, x,y,z (not weighted by mol wt.)

  upvar #0 $MolVar Mol
  upvar $minboundVar minbound
  upvar $maxboundVar maxbound
  upvar $aveVar ave

  set minbound {}
  set maxbound {}
  set ave {}

  if { ![ElementExists Mol nAtoms] || $Mol(nAtoms) <= 0 } { 
   lappend minbound 0.0 0.0 0.0
   lappend maxbound 0.0 0.0 0.0
   lappend ave 0.0 0.0 0.0
    return 0 
  }

  set first 1
  set last $Mol(nAtoms)

  set n 0; set nargs [llength $args]
  while { $n < $nargs } {
    switch -regexp --  [lindex $args $n] \
    first {
      incr n; set first [lindex $args $n]
    } last {
      incr n; set last [lindex $args $n]
    }
    incr n
  }

# initial bounds
  scan $Mol(Coor,$first) "%s%s%s" x y z
  set minX $x ; set maxX $minX
  set minY $y ; set maxY $minY
  set minZ $z ; set maxZ $minZ
  set aveX $x ; set aveY $y ; set aveZ $z
  set ave {}
  set bound {}
# iterate through array
  for {set i [expr $first + 1]} { $i <= $last } {incr i} {
    scan $Mol(Coor,$i) "%s%s%s" x y z
    set aveX [expr $aveX + $x ]
    set aveY [expr $aveY + $y ]
    set aveZ [expr $aveZ + $z ]
    set minX [min $minX $x] ; set maxX [max $maxX $x]
    set minY [min $minY $y] ; set maxY [max $maxY $y]
    set minZ [min $minZ $z] ; set maxZ [max $maxZ $z]
  }
  lappend minbound $minX $minY $minZ
  lappend maxbound $maxX $maxY $maxZ

  set nat [expr $last - $first + 1]
  lappend ave [expr $aveX / $nat ]\
		[expr $aveY / $nat ] \
		[expr $aveZ / $nat ]

  return 1

}

#-------------------------------------------------------------
proc MolTranslate { MolVar translate args } {
#-------------------------------------------------------------
#d_sum Apply a translation to all coordinates in Mol array
#d_arg MolVar	Name of Mol array
#d_arg translate Input list of translation vector x,y,z
#d_opt0	-first first_atom
#d_opt1 Only apply translation to range of atoms starting at first_atom
#d_opt0	-last last_atom
#d_opt1 Only apply translation to range of atoms finishing at at last_atom
  upvar #0 $MolVar Mol

  set first 1
  set last $Mol(nAtoms)
  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    first {
      incr n; set first [lindex $args $n]
    } last {
      incr n; set last [lindex $args $n]
    }
    incr n
  }
   
  set xtran [lindex $translate 0]
  set ytran [lindex $translate 1]
  set ztran [lindex $translate 2]

  for {set i $first} { $i <= $last } {incr i} {
        scan $Mol(Coor,$i) "%s%s%s" x y z
        set Mol(Coor,$i) [ list [expr $x + $xtran] \
                         [expr $y + $ytran] [expr $z + $ztran] ]
  }
}


#----------------------------------------------------------------------------
proc MolWriteCifCoords { MolVar file args } {
#----------------------------------------------------------------------------
#d_sum Write out a CIF coordinate format file
#d_desc File will have  minimal pdb style info and crystal parameters \
set arbitarilly
#d_arg MolVar	Name of Mol array
#d_arg file	Output file name
#d_opt0 -id monomer_id
#d_opt1 Put the monomer id monomer_id in the CIF file
#d_opt0 -tran translation
#d_opt1 Apply a translation given by translation - a list of ztran,ytran,ztran \
This option is NOT implemented.

  upvar #0 $MolVar  Mol
  set iftranslate 0

  if { [ElementExists Mol chem_comp_id] && $Mol(chem_comp_id) != "" } {
    set monomer_id $Mol(chem_comp_id)
  } else {
    set monomer_id [file tail [file root $file ]]
    if { [string length $monomer_id] > 4 } {
      set monomer_id [string range $monomer_id 0 3] }
  }

  set n 0; set nargs [llength $args]
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    id {
      incr n; if { [lindex $args $n] != "" } {set monomer_id [lindex $args $n]}
    } tran {
      set iftranslate 1
      for { set i 1 } { $i <= 3 } { incr i } {
        incr n; lappend translate [lindex $args $n]
      }
    }
    incr n
  }

set text "data_structure_$monomer_id
_entry.id  $monomer_id
_database_2.code_PDB  $monomer_id
_struct.title  'coordinates of $monomer_id from program: ccp4i sketcher'
_cell.entry  $monomer_id
_cell.length_a      100.000
_cell.length_b      100.000
_cell.length_c      100.000
_cell.angle_alpha    90.000
_cell.angle_beta     90.000
_cell.angle_gamma    90.000
_symmetry.entry.id  $monomer_id
_symmetry.space_group_name_H-M  'P 1'
_symmetry.Int_Tables_number  1
loop_
_symmetry_equiv.id
_symmetry_equiv.pos_as_xyz
  1   X,Y,Z
loop_
_entity.id
_entity.type
   AA   non-polymer
loop_
_struct_asym.id
_struct_asym.entity_id
   AA   AA
loop_
_atom_site.id
_atom_site.label_atom_id
_atom_site.label_alt_id
_atom_site.label_comp_id
_atom_site.label_asym_id
_atom_site.label_seq_id
_atom_site.Cartn_x
_atom_site.Cartn_y
_atom_site.Cartn_z
_atom_site.occupancy
_atom_site.B_iso_or_equiv
_atom_site.type_symbol
_atom_site.calc_flag\n"

  for { set n 1 } { $n <= $Mol(nAtoms) } { incr n } {
    if { [regexp ' [set name  $Mol(Name,$n)] ] } {
      set name "'[subst $name]'" }
    set xx [format "%7.2f %7.2f %7.2f" [lindex $Mol(Coor,$n) 0] \
                                        [lindex $Mol(Coor,$n) 1] \
                                        [lindex $Mol(Coor,$n) 2]  ]
    append text " $n [write_cif_name $Mol(Name,$n)]  .  $monomer_id  AA  1  $xx 1.0 20.0 $Mol(Element,$n) .\n"
  }

  return [WriteFile $file $text  -overwrite]

}


#----------------------------------------------------------------------
proc write_cif_name { name } { 
#----------------------------------------------------------------------
#d_sum Put quotes about name if it contains a quote character
#d_desc Function returns an atom name suitable for output ot CIF file
#d_arg name	Input atom name
  if { $name == "" } { return "." }
  if { [regexp ' $name ] } { set name "'[subst $name]'" }
  return $name
}

#----------------------------------------------------------------------------
proc MolReadPdbRestraints { MolVar file args } {
#----------------------------------------------------------------------------
#d_sum Read MODRES/SSBOND/LINK/CISPEP cards from pdb file 
#d_desc The parameters of PDB restraints cards are read into a Mol array. \
The actual name of the array is defined externally so does not have to be, \
and should not be, the same array used for coordinates. 
#d_desc The array will contain elements nModres, nSsbond, nLink and nCispep \
which are number of each restraint.  The other parameter names are best \
seen in the code.  The expected format of the PDB file is that slightly \
extended from PDB and defined in Libcheck documentationn.

  upvar #0 $MolVar Mol

  if { ![ReadFile $file pdbfile -split] } { return 0 }

set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    junk { }
    incr n
  }

  set nModres 0
  set nSsbond 0
  set nLink 0
  set nCispep 0
  set nline 0
  set continue 1
  set maxline [llength $pdbfile]
  set text ""
  while { $continue && $nline < $maxline } {
    set line [lindex $pdbfile $nline]
    switch [lindex $line 0] \
    MODRES {
      incr nModres
      if { $nModres == 1 } { set Mol(modresFirst) $nline }
      set Mol(modresId,$nModres) [string trim [string range $line 7 10]]
      set Mol(modresRes,$nModres) [string trim [string range $line 12 14]]
      set Mol(modresChain,$nModres) [string trim [string range $line 16 16]]
      set Mol(modresSeqn,$nModres) [string trim [string range $line 18 21]]
      set Mol(modresInsert,$nModres) [string trim [string range $line 22 22]]
# Just take the first word in the field as CCP4 definition extends field for 8
# characters so reading standard PDB file may include some part 
# of the comment field
      set Mol(modresStdres,$nModres) [lindex [string range $line 24 31] 0]
      set Mol(modresComment,$nModres) [string trim [string range $line 38 69]]
      if { [catch { set modmode [string trim [string range $line 71 79]] } ] || 
        $modmode == "" || $modmode == "RENAME" } {
        set Mol(modresRename,$nModres) 1
      } else {
        set Mol(modresRename,$nModres) 0
      }
    } SSBOND {
      incr nSsbond
      if { $nSsbond == 1 } { set Mol(ssbondFirst) $nline }
      set Mol(ssbondRes1,$nSsbond) [string trim [string range $line 11 13]]
      set Mol(ssbondChain1,$nSsbond) [string trim [string range $line 15 15]]
      set Mol(ssbondSeqn1,$nSsbond) [string trim [string range $line 17 20]]
      set Mol(ssbondInsert1,$nSsbond) [string trim [string range $line 21 21]]
      set Mol(ssbondRes2,$nSsbond) [string trim [string range $line 25 27]]
      set Mol(ssbondChain2,$nSsbond) [string trim [string range $line 29 29]]
      set Mol(ssbondSeqn2,$nSsbond) [string trim [string range $line 31 34]]
      set Mol(ssbondInsert2,$nSsbond) [string trim [string range $line 35 35]]
      set Mol(ssbondSymop1,$nSsbond) [string trim [string range $line 59 64]]
      set Mol(ssbondSymop2,$nSsbond) [string trim [string range $line 66 71]]
      if { ( $Mol(ssbondSymop1,$nSsbond) == "" || \
             $Mol(ssbondSymop1,$nSsbond) == "1555" ) && 
	   ( $Mol(ssbondSymop2,$nSsbond) == "" || \
             $Mol(ssbondSymop2,$nSsbond) =="1555" ) } {
        set Mol(ssbondInter,$nSsbond) 0
      } else  {
        set Mol(ssbondInter,$nSsbond) 1
      }
    } LINK {
      incr nLink
      if { $nLink == 1 } { set Mol(linkFirst) $nline }
#      set Mol(linkAtom1,$nLink) [string trim [string range $line 12 15]]
      set Mol(linkAtom1,$nLink) [string range $line 12 15]
      set Mol(linkAlt1,$nLink) [string trim [string range $line 16 16]]
      set Mol(linkRes1,$nLink) [string trim [string range $line 17 19]]
      set Mol(linkChain1,$nLink) [string trim [string range $line 21 21]]
      set Mol(linkSeqn1,$nLink) [string trim [string range $line 22 25]]
      set Mol(linkInsert1,$nLink) [string trim [string range $line 26 26]]
      set Mol(linkDistance,$nLink) [string trim [string range $line 30 39]]
#      set Mol(linkAtom2,$nLink) [string trim [string range $line 42 45]]
      set Mol(linkAtom2,$nLink) [string range $line 42 45]
      set Mol(linkAlt2,$nLink) [string trim [string range $line 46 46]]
      set Mol(linkRes2,$nLink) [string trim [string range $line 47 49]]
      set Mol(linkChain2,$nLink) [string trim [string range $line 51 51]]
      set Mol(linkSeqn2,$nLink) [string trim [string range $line 52 55]]
      set Mol(linkInsert2,$nLink) [string trim [string range $line 56 56]]
      set Mol(linkSymop1,$nLink) [string trim [string range $line 59 64]]
      set Mol(linkSymop2,$nLink) [string trim [string range $line 66 71]]
      set Mol(linkId,$nLink) [string trim [string range $line 72 79]]
      if { ( $Mol(linkSymop1,$nLink) == "" || \
             $Mol(linkSymop1,$nLink) == "1555" ) &&
           ( $Mol(linkSymop2,$nLink) == "" || \
             $Mol(linkSymop2,$nLink) =="1555" ) } {
        set Mol(linkInter,$nLink) 0
      } else  {
        set Mol(linkInter,$nLink) 1
      }

    } CISPEP {
      incr nCispep
      if { $nCispep == 1 } { set Mol(cispepFirst) $nline }
      set Mol(cispepRes1,$nCispep) [string trim [string range $line 11 13]]
      set Mol(cispepChain1,$nCispep) [string trim [string range $line 15 15]]
      set Mol(cispepSeqn1,$nCispep) [string trim [string range $line 17 20]]
      set Mol(cispepInsert1,$nCispep) [string trim [string range $line 21 21]]
      set Mol(cispepRes2,$nCispep) [string trim [string range $line 25 27]]
      set Mol(cispepChain2,$nCispep) [string trim [string range $line 29 29]]
      set Mol(cispepSeqn2,$nCispep) [string trim [string range $line 31 34]]
      set Mol(cispepInsert2,$nCispep) [string trim [string range $line 35 35]]
      set Mol(cispepModel,$nCispep) [string trim [string range $line 43 45]]
      set Mol(cispepAngle,$nCispep) [string trim [string range $line 53 58]]
    } ATOM {
      set continue 0
    }
    incr nline
  }
  set Mol(nModres) $nModres
  set Mol(nSsbond) $nSsbond
  set Mol(nLink) $nLink
  set Mol(nCispep) $nCispep
#  puts "Have read $nModres MODRES, $nSsbond SSBOND, $nLink LINK, $nCispep CISPEP lines"
  return [expr $nModres + $nSsbond + $nLink + $nCispep]

}

#----------------------------------------------------------------------------
proc MolPdbElement { atnam } {
#----------------------------------------------------------------------------
# Given the input atom name atnam (PDB ATOM card columns 13-16 untrimmed)
# make a guess at the element type

  if { [regexp {[0-9]| |\*|'|\"} [string index $atnam 0]]  } {
# first char is blank or numeric so assume second is element
    set element [string index $atnam 1]
  } else { 
# first character is alpha - so what is second?
    if { [string index $atnam 1] == "H" } {
# its H so assume element is H
      set element H
    } elseif { [regexp {[A-Z]} [string index $atnam 1]] } {
# second char is alpha
      set element [string range $atnam 0 1]
    } else {
# very wierd - first char is alpha but second is not
      set element {}
    }
  }
  return $element
}

#----------------------------------------------------------------------------
proc MolWritePdbRestraints { MolVar filein fileout args } {
#----------------------------------------------------------------------------
  upvar #0 $MolVar Mol

# Write  MODRES/SSBOND/LINK/CISPEP cards to pdb file

# Read in the rest of PDB file
  set  iffilein 0
  set standard 0
  if { [ReadFile $filein pdbfile -split] } { set iffilein 1 }

  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    standard { 
      set standard 1
    }
    incr n
  }

#  puts "MolWritePdbRestraints standard $standard"

  for { set n 1 } { $n <= $Mol(nModres) } { incr n } {
    if { $standard } {
# Nasty problem here if the modresStdres is > 3 chars as allowed for in 
# standard format (columns 25-27)
      append text [format "MODRES %4s %3s %1s %4i%1s %-8s %-38s\n" \
        $Mol(modresId,$n) \
        $Mol(modresRes,$n) \
        $Mol(modresChain,$n) \
        $Mol(modresSeqn,$n) \
        $Mol(modresInsert,$n) \
        $Mol(modresStdres,$n) \
        $Mol(modresComment,$n) ]
    } elseif { $Mol(modresRename,$n) } {
      append text [format "MODRES %4s %3s %1s %4i%1s %-8s %-38s %-8s\n" \
	$Mol(modresId,$n) \
        $Mol(modresRes,$n) \
        $Mol(modresChain,$n) \
        $Mol(modresSeqn,$n) \
        $Mol(modresInsert,$n) \
        $Mol(modresStdres,$n) \
        $Mol(modresComment,$n) \
	RENAME  ]
    } else {
      append text [format "MODRES %4s %3s %1s %4i%1s %-8s %-38s %-8s\n" \
        $Mol(modresId,$n) \
        $Mol(modresRes,$n) \
        $Mol(modresChain,$n) \
        $Mol(modresSeqn,$n) \
        $Mol(modresInsert,$n) \
        {}  \
        $Mol(modresComment,$n) \
	$Mol(modresStdres,$n) ]
    }
  }

 for { set n 1 } { $n <= $Mol(nSsbond) } { incr n } {
    if { $Mol(ssbondInter,$n) } {
      if { $Mol(ssbondSymop1,$n) == "" } { set Mol(ssbondSymop1,$n) 1555 }
      if { $Mol(ssbondSymop2,$n) == "" } { set Mol(ssbondSymop2,$n) 2555 }
    } else {
      set Mol(ssbondSymop1,$n) ""
      set Mol(ssbondSymop1,$n) ""
    }
    append text [format "SSBOND %3i %3s %1s %4i%1s   %3s %1s %4i%1s                       %6s %6s\n" \
	$n \
        $Mol(ssbondRes1,$n) \
        $Mol(ssbondChain1,$n) \
        $Mol(ssbondSeqn1,$n) \
        $Mol(ssbondInsert1,$n) \
        $Mol(ssbondRes2,$n) \
        $Mol(ssbondChain2,$n) \
        $Mol(ssbondSeqn2,$n) \
        $Mol(ssbondInsert2,$n) \
        $Mol(ssbondSymop1,$n) \
        $Mol(ssbondSymop2,$n) ]
  }

  for { set n 1 } { $n <= $Mol(nLink) } { incr n } {
    if { $Mol(linkInter,$n) } {
      if { $Mol(linkSymop1,$n) == "" } { set Mol(linkSymop1,$n) 1555 }
      if { $Mol(linkSymop2,$n) == "" } { set Mol(linkSymop2,$n) 2555 }
    } else {
      set Mol(linkSymop1,$n) ""
      set Mol(linkSymop1,$n) ""
    }
    if { $standard } {
      append text [format "LINK        %-4s%1s%3s %1s%4i%1s               %-4s%1s%3s %1s%4i%1s  %6s %6s\n"  \
        $Mol(linkAtom1,$n) \
        $Mol(linkAlt1,$n) \
        $Mol(linkRes1,$n) \
        $Mol(linkChain1,$n) \
        $Mol(linkSeqn1,$n) \
        $Mol(linkInsert1,$n) \
        $Mol(linkAtom2,$n) \
        $Mol(linkAlt2,$n) \
        $Mol(linkRes2,$n) \
        $Mol(linkChain2,$n) \
        $Mol(linkSeqn2,$n) \
        $Mol(linkInsert2,$n) \
        $Mol(linkSymop1,$n) \
        $Mol(linkSymop2,$n) ]

    } else {
      if { $Mol(linkDistance,$n) == "" } { set dist "" } else { \
		set dist [format %10.5f $Mol(linkDistance,$n)] }
      append text [format "LINK        %-4s%1s%3s %1s%4i%1s  %10s   %-4s%1s%3s %1s%4i%1s  %6s %6s%8s\n"  \
	$Mol(linkAtom1,$n) \
	$Mol(linkAlt1,$n) \
	$Mol(linkRes1,$n) \
        $Mol(linkChain1,$n) \
        $Mol(linkSeqn1,$n) \
        $Mol(linkInsert1,$n) \
        $dist \
        $Mol(linkAtom2,$n) \
        $Mol(linkAlt2,$n) \
        $Mol(linkRes2,$n) \
        $Mol(linkChain2,$n) \
        $Mol(linkSeqn2,$n) \
        $Mol(linkInsert2,$n) \
        $Mol(linkSymop1,$n) \
        $Mol(linkSymop2,$n) \
	$Mol(linkId,$n) ]
     }
  }

  for { set n 1 } { $n <= $Mol(nCispep) } { incr n } {
    if { ![ElementExists Mol cispepModel,$n] } {
      set Mol(cispepModel,$n) 0
      set Mol(cispepAngle,$n) 0.0
    }
    append text [format "CISPEP %3i %3s %1s %4i%1s   %3s %1s %4i%1s       %3i       %6.2f\n" \
	$n \
	$Mol(cispepRes1,$n) \
        $Mol(cispepChain1,$n) \
        $Mol(cispepSeqn1,$n) \
        $Mol(cispepInsert1,$n) \
	$Mol(cispepRes2,$n) \
        $Mol(cispepChain2,$n) \
        $Mol(cispepSeqn2,$n) \
        $Mol(cispepInsert2,$n) \
        $Mol(cispepModel,$n) \
        $Mol(cispepAngle,$n) ]
  }

# strip the last newline character
  if { ![regsub \n$ $text {} tt] } { set text $tt }
  if { $iffilein } {
# Remove existing restraint cards and insert new cards before first ATOM card
    set n -1;foreach line $pdbfile { incr n
      if { [regexp {^ATOM|^HETATM} $line] } {
        append textout $text
        foreach line [lrange $pdbfile $n end] {
          append textout $line\n
        }
        break
      } elseif { ![regexp {^MODRES|^LINK|^SSBOND|^CISPEP} $line ] } {
        append textout $line\n
      }
    }
    return [WriteFile $fileout $textout]
  } else {
    return [WriteFile $fileout $text]
  }
}

#----------------------------------------------------------------------------
proc MolPDBAtomeName { name } {
#----------------------------------------------------------------------------

   set atlist [list He Li Be Ne Na Mg Al Si P S Cl Ar  Ca Sc Ti Cr Mn Fe \
	Co Ni Cu Zn Ga Ge As Se Br Kr Rb Sr Zr Nb Mo Tc Ru Rh Pd Ag \
	Cd In Sn Sb Te I Xe Cs Ba Hf Ta W Re Os Ir Pt Au Hg Tl Pb \
	Bi Po At Rn Fr Ra La Ce Pr Nd Pm Sm Eu Gd Tb Dy Ho Er Tm Yb Lu \
        Ac Th Pa Np Pu Am Cm Bk Cf Es Fm Md No Lr]
}

#----------------------------------------------------------------------------
proc MolCheckPdbRestraints { restrainstVar } {
#----------------------------------------------------------------------------
#d_sum Not implemented - should check sensible restraints defined
  return 1
}


#----------------------------------------------------------------------------
proc MolCheckReadFile { MolVar args } {
#----------------------------------------------------------------------------
#d_sum Not implemented - should check sensible atom name input etc.
  upvar #0 $MolVar Mol

  return 1 

  set ifat 1
  set ilat $Mol(nAtoms)
  set n 0; set nargs [llength $args]
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    first {
      incr n; set ifat [lindex $args $n]
    }
    incr n
  }
}
 
#------------------------------------------------------------------------
proc MolFindFragments { } {
#------------------------------------------------------------------------
#d_sum Find all the separate non-bonded fragments in Mol array
#d_desc If not all bonds are defined that molecule will appear to be \
more that one fragment.  This procedure returns the number of fragments \
(ideally this should be 1) and for each atom na assigns a value to \
Mol(frag,$na) which is an integer value - all atoms with the same value \
are in the same fragment.

  global Mol

  for { set n 1 } { $n <= $Mol(nAtoms) } { incr n } {
    set frag($n) 0
  }

  set nextf 0
  set noverlap 0
# Loop over bonding list putting bonded atoms in the same fragment
  for { set n 1 } { $n <= $Mol(nBonds) } { incr n } {
    set ii [lindex $Mol(Bonds,$n) 0]
    set jj [lindex $Mol(Bonds,$n) 1]
    if { $frag($ii) == 0  && $frag($jj) == 0 } {
      incr nextf
      set frag($ii) $nextf
      set frag($jj) $nextf
    } elseif { $frag($ii) == 0 } {
      set frag($ii) $frag($jj)
    } elseif { $frag($jj) == 0 } {
      set frag($jj) $frag($ii)
    } elseif { $frag($jj) != $frag($ii) } {
# Two bonded atoms were assigned to different fragments so merge 
# the fragments
      set jf $frag($jj)
      set if $frag($ii)
      for { set m 1 } { $m <= $Mol(nAtoms) } { incr m } {
         if { $frag($m) == $jf } { set frag($m) $if }
      }
      incr noverlap
    }
  }

# Look for any atoms which are not in the bonding list
  for { set n 1 } { $n <= $Mol(nAtoms) } { incr n } {
#    puts "$Mol(Name,$n) $frag($n)"
    if { $frag($n) > 0 } {
      set Mol(frag,$n) $frag($n)
    } else {
      incr nextf
      set Mol(frag,$n) $nextf
    }
  }
  return [expr $nextf - $noverlap ]

}

#----------------------------------------------------------------------
proc MolFindChiralCentres { MolVar dictVar } {
#----------------------------------------------------------------------
  upvar #0 $MolVar Mol
  upvar #0 $dictVar dict

  set warning ""
  set nchiral 0
  set cutoff 1.0

# Set up a connectivity list - for each atom a list of atoms it is bonded to
  for { set n 1 } { $n <= $Mol(nAtoms) } { incr n } { set conn($n) {} }
  
  for { set n 1 } { $n <= $Mol(nBonds) } { incr n } { 
    set ii [lindex $Mol(Bonds,$n) 0]
    set jj [lindex $Mol(Bonds,$n) 1]
    if { $Mol(Element,$ii) == "C" && $Mol(Element,$jj) != "H" } { 
	lappend conn($ii) $jj }
    if { $Mol(Element,$jj) == "C" && $Mol(Element,$ii) !=  "H" } { 
	lappend conn($jj) $ii }
  }

# Loop through to find C atoms with 3 neighbours and calculate chiral volume
  for { set n 1 } { $n <= $Mol(nAtoms) } { incr n } {
    if { [llength $conn($n)] > 3 } {
      append warning "Atom $Mol(Name,$n) apparently bonded to more than three atoms\n"
    } elseif { [llength $conn($n)] > 2 && \
       [MolChiralVolume $MolVar $n [lindex $conn($n) 0] [lindex $conn($n) 1] \
	[lindex $conn($n) 2] volobs] && [expr abs($volobs)] > $cutoff } {
#      puts "$Mol(Name,$n) volobs $volobs"
      incr nchiral
      lappend dict(chiralcentre) $Mol(Name,$n)
      lappend dict(neighbours) [list $Mol(Name,[lindex $conn($n) 0])  \
				     $Mol(Name,[lindex $conn($n) 1])  \
				     $Mol(Name,[lindex $conn($n) 2]) ]
      if { $volobs > 0.0 } {
        lappend dict(chirality) positiv
      } else {
        lappend dict(chirality) negativ
      }
    }
  }

  if { $warning != "" } {
   WarningMessage "Checking for chiral centres - WARNING:\n$warning" }

  set dict(nchiral) $nchiral
  return $nchiral

}

#----------------------------------------------------------------------
proc MolChiralVolume { MolVar at1 at2 at3 at4 volobsVar } {
#----------------------------------------------------------------------
#d_sum Find the chiral volume of four atoms in the Mol array
#d_desc Find the chiral volume for atom at1 and its three neighbours
#d_desc This needs to give the sign of the chirality to conform with \
that used to Libcheck.  
#d_arg MolVar Name of global Mol array
#d_arg at1	Atom number of chiral centre
#d_arg at2,at3,at4 Three neighbouring atoms of chiral centre
#d_arg volobsVar returned value of chiral volume
  upvar #0 $MolVar Mol
  upvar $volobsVar volobs

# Translation of Fortran code from Alexei
#     A(1) = XX2(1)-XX1(1)
#      A(4) = XX2(2)-XX1(2)
#      A(7) = XX2(3)-XX1(3)
#      A(2) = XX3(1)-XX1(1)
#      A(5) = XX3(2)-XX1(2)
#      A(8) = XX3(3)-XX1(3)
#      A(3) = XX4(1)-XX1(1)
#      A(6) = XX4(2)-XX1(2)
#      A(9) = XX4(3)-XX1(3)

#      VOLOBS = A(1)*(A(5)*A(9)-A(8)*A(6))
#     *       - A(4)*(A(2)*A(9)-A(8)*A(3))
#     *       + A(7)*(A(2)*A(6)-A(5)*A(3))

  set a1 [expr [lindex $Mol(Coor,$at2) 0] - [lindex $Mol(Coor,$at1) 0] ]
  set a4 [expr [lindex $Mol(Coor,$at2) 1] - [lindex $Mol(Coor,$at1) 1] ]
  set a7 [expr [lindex $Mol(Coor,$at2) 2] - [lindex $Mol(Coor,$at1) 2] ]

  set a2 [expr [lindex $Mol(Coor,$at3) 0] - [lindex $Mol(Coor,$at1) 0] ]
  set a5 [expr [lindex $Mol(Coor,$at3) 1] - [lindex $Mol(Coor,$at1) 1] ]
  set a8 [expr [lindex $Mol(Coor,$at3) 2] - [lindex $Mol(Coor,$at1) 2] ]

  set a3 [expr [lindex $Mol(Coor,$at4) 0] - [lindex $Mol(Coor,$at1) 0] ]
  set a6 [expr [lindex $Mol(Coor,$at4) 1] - [lindex $Mol(Coor,$at1) 1] ]
  set a9 [expr [lindex $Mol(Coor,$at4) 2] - [lindex $Mol(Coor,$at1) 2] ]

  set volobs [ expr $a1 * ( $a5 * $a9 - $a8 * $a6 ) \
	         -  $a4 * ( $a2 * $a9 - $a8 * $a3 ) \
                 +  $a7 * ( $a7 * $a2 - $a5 * $a3 ) ]

  return 1

}

#--------------------------------------------------------------------
proc MolSaveParam { MolVar store paramlist }  {
#--------------------------------------------------------------------
#d_sum Make a backup of Mol array values
#d_desc Save some of the current Mol params to the Mol element store
#d_arg MolVar  the name of the global Mol array
#d_arg store	the name of the element used to store the parameters
#d_arg paramlist the list parameters to be stored.
  upvar #0 $MolVar Mol

# Save some of the current Mol params (as listed in paramlist) to the 
# Mol element store

  for { set n 1 } { $n <= $Mol(nAtoms) } { incr n } {
    set t {}
    foreach param $paramlist {
      lappend t $Mol([subst $param],$n)
    }
    lappend tt $t
  }
  set Mol($store) $tt
  puts "store $Mol($store)"
}
