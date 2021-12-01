#!/usr/bin/tclsh

puts "
CREATE INDEX idx_id_assemblies          ON assemblies(id);
CREATE INDEX idx_id_molecules           ON molecules(id);
CREATE INDEX idx_id_cavities            ON cavities(id);
CREATE INDEX idx_id_cdhit_chains        ON cdhit_chains(id);
CREATE INDEX idx_id_symop_chains        ON symop_chains(id);
CREATE INDEX idx_id_residues            ON residues(id);
CREATE INDEX idx_id_neighbors           ON neighbors(id);
CREATE INDEX idx_id_atoms               ON atoms(id);
CREATE INDEX idx_id_ligand_bondangles   ON ligand_bondangles(id);
CREATE INDEX idx_id_ion_bondvalences    ON ion_bondvalences(id);
CREATE INDEX idx_id_water_bondvalences  ON water_bondvalences(id);
CREATE INDEX idx_id_ion_bindingsites    ON ion_bindingsites(id);

CREATE INDEX idx_residuetype_residues           ON residues(residuetype);
CREATE INDEX idx_neighbortype_neighbors         ON neighbors(neighbortype);
CREATE INDEX idx_atomtype_atoms                 ON atoms(atomtype);
CREATE INDEX idx_atomid_ligand_bondangles       ON ligand_bondangles(pdbfileid,atomid_lig);
CREATE INDEX idx_protons_ion_bondvalences       ON ion_bondvalences(protons_ion,protons_lig);
CREATE INDEX idx_protons_water_bondvalences     ON water_bondvalences(pdbfileid,protons_lig);
CREATE INDEX idx_protons_ion_bindingsites       ON ion_bindingsites(protons_ion);
";

# CREATE INDEX idx_neighborid_neighbors ON neighbors(neighborid);
# CREATE INDEX idx_id_atomneighbors ON atomneighbors(id);
# CREATE INDEX idx_atomneighborid_atomneighbors ON atomneighbors(atomneighborid);
# CREATE INDEX idx_residueid_atomneighbors ON atomneighbors(residueid_a, residueid_b);
# CREATE INDEX idx_atomneighbortype_atomneighbors ON atomneighbors(atomneighbortype);

set residue_list [list { 1 "01" gly  1  2} \
                       { 3 "03" ala  1  4} \
                       { 5 "05" val  1  6} \
                       { 7 "07" leu  1  8} \
                       { 9 "09" ile  1 10} \
                       {11 "11" ser  1 12} \
                       {13 "13" thr  1 14} \
                       {15 "15" cys  1 16} \
                       {17 "17" met  1 18} \
                       {19 "19" pro  1 20} \
                       {21 "21" asp  1 22} \
                       {23 "23" asn  1 24} \
                       {25 "25" glu  1 26} \
                       {27 "27" gln  1 28} \
                       {29 "29" lys  1 30} \
                       {31 "31" arg  1 32} \
                       {33 "33" his  1 34} \
                       {35 "35" phe  1 36} \
                       {37 "37" tyr  1 38} \
                       {39 "39" trp  1 40} \
                       {41 "41" unk -1 -1} \
                       {42 "42" dna  1 -1} \
                       {43 "43" wat -1 -1} \
                       {44 "44" ion  1 47} \
                       {48 "48" lig  1 53}]
set atom_list [list { 1 "01" mc4n      } \
                    { 2 "02" mc4ca     } \
                    { 3 "03" mc4c      } \
                    { 4 "04" mc4o      } \
                    { 5 "05" sc4cb     } \
                    { 6 "06" sc4c      } \
                    { 7 "07" sc4narg   } \
                    { 8 "08" sc4oamide } \
                    { 9 "09" sc4namide } \
                    {10 "10" sc4ocarbo } \
                    {11 "11" sc4scys   } \
                    {12 "12" sc4cring  } \
                    {13 "13" sc4nhis   } \
                    {14 "14" sc4nlys   } \
                    {15 "15" sc4ntrp   } \
                    {16 "16" sc4smet   } \
                    {17 "17" sc4ohydro } \
                    {18 "18" sc4ophenol} \
                    {19 "19" sc4se     } \
                    {20 "20" sc4ohet   } \
                    {21 "21" dr4nhet   } \
                    {22 "22" dr4shet   } \
                    {23 "23" dr4xhet   } \
                    {24 "24" dr4c      } \
                    {25 "25" dr4n      } \
                    {26 "26" dr4o      } \
                    {27 "27" dr4p      } \
                    {28 "28" wt4o      } \
                    {29 "29" lg4c      } \
                    {30 "30" lg4n      } \
                    {31 "31" lg4o      } \
                    {32 "32" lg4p      } \
                    {33 "33" lg4s      } \
                    {34 "34" lg4h      } \
                    {35 "35" hydro     } \
                    {36 "36" alkali    } \
                    {37 "37" alkaline  } \
                    {38 "38" halogen   } \
                    {39 "39" light     } \
                    {40 "40" heavy     } \
                    {41 "41" other     }]

foreach residue_record $residue_list {
  set num_type     [lindex $residue_record 0]
  set txt_type     [lindex $residue_record 1]
  set res_name     [lindex $residue_record 2]
  set need_resname [lindex $residue_record 3]
  set need_another [lindex $residue_record 4]
  set table_name "residues${txt_type}_$res_name"
  puts -nonewline "CREATE TABLE $table_name AS (SELECT id, pdbfileid, residueid, chainid, resseq";
  if {$need_resname == 1}  {puts -nonewline ", resname"}
  if {$need_another != -1} {puts -nonewline ", residuetype"}
  if {$num_type<=41} { puts -nonewline ", next_residueid"; }
  puts -nonewline " FROM residues WHERE residuetype"
  if {$need_another == -1} {
    puts -nonewline "=$num_type"
  } elseif {[expr $need_another-$num_type] == 1} {
    puts -nonewline "=$num_type OR residuetype=$need_another"
  } elseif {[expr $need_another-$num_type] > 1} {
    puts -nonewline ">=$num_type AND residuetype<=$need_another"
  }
  puts ");"
  puts "ALTER TABLE $table_name ADD PRIMARY KEY (pdbfileid, residueid);"
}

foreach residue_record_1 $residue_list {
  set num_type_1     [lindex $residue_record_1 0]
  set txt_type_1     [lindex $residue_record_1 1]
  set res_name_1     [lindex $residue_record_1 2]
  set need_resname_1 [lindex $residue_record_1 3]
  set need_another_1 [lindex $residue_record_1 4]
  foreach residue_record_2 $residue_list {
  set num_type_2     [lindex $residue_record_2 0]
  set txt_type_2     [lindex $residue_record_2 1]
  set res_name_2     [lindex $residue_record_2 2]
  set need_resname_2 [lindex $residue_record_2 3]
  set need_another_2 [lindex $residue_record_2 4]
    if {$num_type_1 <= $num_type_2} {
      set table_name "neighbors$txt_type_1${txt_type_2}_${res_name_1}_$res_name_2"
      if {[string equal $res_name_2 "unk"]} {
        if {[string equal $res_name_1 "gly"]} {
          set table_name "neighbors$txt_type_1${txt_type_2}_kno_$res_name_2"
        } elseif {[string equal $res_name_1 "unk"]} {
        } else { continue; }
      } elseif {[string equal $res_name_1 "unk"]} {
        if {[string equal $res_name_2 "ion"] || [string equal $res_name_2 "lig"]} {
          set table_name "neighbors$txt_type_1${txt_type_2}_all_$res_name_2"
          set need_resname_1 1
        }
      }
      set table_type [expr 100*$num_type_1+$num_type_2]
      puts -nonewline "CREATE TABLE $table_name AS (SELECT id, pdbfileid, neighborid, residueid_a, residueid_b, atomid_a, atomid_b, atomname_a, atomname_b, atomneighbortype, contact_flag, distance, bfactor_correlation"
      if {$need_resname_1 == 1} {puts -nonewline ", resname_a"}
      if {$need_resname_2 == 1} {puts -nonewline ", resname_b"}
      if {!([string equal $res_name_1 "dna"] && [string equal $res_name_2 "dna"]) && ($need_resname_1 == 1 || $need_resname_2 == 1)} {puts -nonewline ", neighbortype"}
      if {[string equal $res_name_2 "unk"]} {
        if {[string equal $res_name_1 "gly"]} {
          puts -nonewline " FROM neighbors WHERE neighbortype=$table_type"
          for {set i [expr $num_type_1+1]} {$i<$num_type_2} {incr i} {
            set table_type [expr 100*$i+$num_type_2]
            puts -nonewline " OR neighbortype=$table_type"
          }
        } else {
          puts -nonewline " FROM neighbors WHERE neighbortype=$table_type"
        }
      } elseif {[string equal $res_name_1 "unk"] && ([string equal $res_name_2 "ion"] || [string equal $res_name_2 "lig"])} {
        set higher_limits [expr ($num_type_1+1)*100]
        puts -nonewline " FROM neighbors WHERE neighbortype<$higher_limits"
        puts -nonewline " AND neighbortype%100>=$num_type_2 AND neighbortype%100<=$need_another_2"
      } elseif {[expr $need_another_1-$num_type_1] > 1 && [expr $need_another_2-$num_type_2] > 1} {
        set table_type_up [expr 100*$num_type_1+$need_another_2]
        puts -nonewline " FROM neighbors WHERE (neighbortype>=$table_type AND neighbortype<=$table_type_up)"
        for {set i [expr $num_type_1+1]} {$i<=$need_another_1} {incr i} {
          set table_type    [expr 100*$i+$num_type_2]
          set table_type_up [expr 100*$i+$need_another_2]
          puts -nonewline " OR (neighbortype>=$table_type AND neighbortype<=$table_type_up)"
        }
      } elseif {[expr $need_another_1-$num_type_1] > 1} {
        set table_type_up [expr 100*$need_another_1+$num_type_2]
        puts -nonewline " FROM neighbors WHERE neighbortype=$table_type"
        for {set i [expr $table_type+100]} {$i<=$table_type_up} {incr i 100} {
          puts -nonewline " OR neighbortype=$i"
        }
        if {$need_another_2 != -1} {
          set table_type    [expr 100*$num_type_1+$need_another_2]
          set table_type_up [expr 100*$need_another_1+$need_another_2]
          puts -nonewline " OR neighbortype=$table_type"
          for {set i [expr $table_type+100]} {$i<=$table_type_up} {incr i 100} {
            puts -nonewline " OR neighbortype=$i"
          }
        }
      } elseif {[expr $need_another_2-$num_type_2] > 1} {
        set table_type_up [expr 100*$num_type_1+$need_another_2]
        puts -nonewline " FROM neighbors WHERE (neighbortype>=$table_type AND neighbortype<=$table_type_up)"
        if {$need_another_1 != -1} {
          set table_type    [expr 100*$need_another_1+$num_type_2]
          set table_type_up [expr 100*$need_another_1+$need_another_2]
          puts -nonewline " OR (neighbortype>=$table_type AND neighbortype<=$table_type_up)"
        }
      } else {
        puts -nonewline " FROM neighbors WHERE neighbortype=$table_type"
        if {$need_another_1 != -1} {
          set table_type [expr 100*$need_another_1+$num_type_2]
          puts -nonewline " OR neighbortype=$table_type"
        }
        if {$need_another_2 != -1} {
          set table_type [expr 100*$num_type_1+$need_another_2]
          puts -nonewline " OR neighbortype=$table_type"
        }
        if {$need_another_1 != -1 && $need_another_2 != -1} {
          set table_type [expr 100*$need_another_1+$need_another_2]
          puts -nonewline " OR neighbortype=$table_type"
        }
      }
      puts ");"
#     puts "ALTER TABLE $table_name ADD PRIMARY KEY (pdbfileid, residueid_a, residueid_b);"
      puts "CREATE INDEX idx_$table_name ON ${table_name}(pdbfileid, residueid_a, residueid_b);"
#     puts "create index idxa_$table_name on ${table_name}(pdbfileid, residueid_a);"
#     puts "create index idxb_$table_name on ${table_name}(pdbfileid, residueid_b);"
    }
  }
}

foreach atom_record $atom_list {
  set num_type      [lindex $atom_record 0]
  set txt_type      [lindex $atom_record 1]
  set atom_name     [lindex $atom_record 2]
# set need_restrict [lindex $atom_record 3]
# set need_another  [lindex $atom_record 4]
  set table_name "atoms${txt_type}_$atom_name"
  puts -nonewline "CREATE TABLE $table_name AS (SELECT id, pdbfileid, atomid, residueid, atomname FROM atoms WHERE atomtype=$num_type";
# if {$need_another != -1}  {puts -nonewline " OR atomtype=$need_another"}
# if {$need_restrict != -1} {puts -nonewline " AND $need_restrict"}
  puts ");"
  puts "ALTER TABLE $table_name ADD PRIMARY KEY (pdbfileid, atomid);"
}
