#!/usr/bin/env tclsh

#
# compare-arpwarp-solution.tcl
#

#
# A Tcl script to compare the _warpNtrace.pdb file produced by
# ARP/wARP with a PDB file containing the original structure.
#
# This is more complicated than it sounds.  What should we compare?
#
# - Badger (Acta Cryst D59 823-827) outputs "statistics of the total
#    numbers of amino acids built and the numbers of CA atoms placed within
#    1A of a correct CA position", but suggests this is somewhat arbitrary.
# - I haven't found anything better yet (Jan 2005), if we come up with
#    more measures, please add them here.
#

#
# Output:
#   - # atoms found / # total atoms
#   - # residues found / # total residues
#   - # CA atoms placed within 1A of a correct CA position
#   - # CA atoms placed within 1A of a correct CA position or dummy atom
#

#
# Usage:
#   compare-arpwarp-solution.tcl model.pdb arpwarp.pdb
#

proc num_atoms { pdbfile } {
	set pdbfileid [open $pdbfile r]

	set natoms 0

	while { [gets $pdbfileid line] >= 0 } {
  		if { [regexp {^(ATOM|HETATM)} $line] } {
			incr natoms
		}
	}

	return $natoms
}

proc num_residues { pdbfile } {
	set pdbfileid [open $pdbfile r]

	set nres 0

	while { [gets $pdbfileid line] >= 0 } {
  		if { [regexp {^(ATOM|HETATM) *[0-9]* *CA *([A-Z]*)} $line throw throw res] } {
		  if { [regexp {ALA|ARG|ASN|ASP|ASX|CYS|GLN|GLU|GLX|GLY|HIS|ILE|LEU|LYS|MET|PHE|PRO|SER|THR|TRP|TYR|UNK|VAL|MSE} $res] } {
			incr nres
		  }
		}
	}

	return $nres
}

proc num_occ_residues { pdbfile } {
	set pdbfileid [open $pdbfile r]

	set nres 0

	while { [gets $pdbfileid line] >= 0 } {
  		if { [regexp {^(ATOM|HETATM) *[0-9]* *CA *([A-Z]*) *[A-Z]* *[-0-9]*[A-Z]*( *| *-)[0-9.]*( *| *-)[0-9.]*( *| *-)[0-9.]* *([-0-9]*.[0-9]{2})} $line throw throw res throw throw throw occ] } {
		  if { [regexp {ALA|ARG|ASN|ASP|ASX|CYS|GLN|GLU|GLX|GLY|HIS|ILE|LEU|LYS|MET|PHE|PRO|SER|THR|TRP|TYR|UNK|VAL|MSE} $res] } {
			set nres [expr $nres+$occ]
		  }
		}
	}

	return $nres
}

#
#   num_residues_within $modelfile $trialfile $cutoff
#
# - Make a list of the atoms and coordinates for the model
# - Make a list of the atoms and coordinates for the trial
# - For each atom in the model, search through all the atoms in the
#    trial.  If any of them are within $cutoff of the model atom
#    remove it from the trial list.
#
proc num_residues_within { modelfile trialfile cutoff } {
	global verbose 
	global rmserr
	global meanerr

	set modelfileid [open $modelfile r]
	set trialfileid [open $trialfile r]

	# Read in the transformation matrix from model pdb file
	while { [gets $modelfileid line] >= 0 } {
  		if { [regexp {CRYST1 *([-0-9.]*) *([-0-9.]*) *([-0-9.]*) *} $line full x y z] } { 
		  set modcell [list $x $y $z]
		}
  		if { [regexp {SCALE1 *([-0-9.]*) *([-0-9.]*) *([-0-9.]*) *} $line full modmat11 modmat12 modmat13] } {}
  		if { [regexp {SCALE2 *([-0-9.]*) *([-0-9.]*) *([-0-9.]*) *} $line full modmat21 modmat22 modmat23] } {}
  		if { [regexp {SCALE3 *([-0-9.]*) *([-0-9.]*) *([-0-9.]*) *} $line full modmat31 modmat32 modmat33] } {}
	}

	if { ![info exists modmat11] } {
		puts "Could not find SCALE1 card in model pdb file"
	}

	#compute inverse matrix
	set modinv33 [expr 1./$modmat33 ]
	set modinv22 [expr 1./$modmat22 ]
	set modinv23 [expr -$modmat23*$modinv22*$modinv33 ]
	set modinv11 [expr 1./$modmat11 ]
	set modinv12 [expr -$modmat12*$modinv11*$modinv22 ]
	set modinv13 [expr -$modmat12*$modinv11*$modinv23 - $modmat13*$modinv11*$modinv33 ]
	
	close $modelfileid

	# Read in CA atoms from model pdb file  

	set modelfileid [open $modelfile r]
	while { [gets $modelfileid line] >= 0 } {
		if { [regexp {^(ATOM|HETATM) *([0-9]*) *CA *(([A-Z]*) *[a-zA-Z]* *[-0-9]*[A-Z]*) *(-*[0-9.]*) *(-*[0-9.]*) *(-*[0-9.]*) *([-0-9.]*)} $line full throw atomnum atominfo res x y z] } {
		  if { [regexp {ALA|ARG|ASN|ASP|ASX|CYS|GLN|GLU|GLX|GLY|HIS|ILE|LEU|LYS|MET|PHE|PRO|SER|THR|TRP|TYR|UNK|VAL|MSE} $res] } {
#puts "$line \n"
#puts "$atomnum $atominfo $x $y $z \n"

			# Transform these coordinates to fractional
			set fx [expr $modmat11*$x + $modmat12*$y + $modmat13*$z]
			set fy [expr $modmat22*$y + $modmat23*$z]
			set fz [expr $modmat33*$z]

			# Normalize all fractional coordinates to be between 0 and 1
			while { $fx<0. } { set fx [expr $fx+1.] }
			while { $fy<0. } { set fy [expr $fy+1.] }
			while { $fz<0. } { set fz [expr $fz+1.] }
			while { $fx>1. } { set fx [expr $fx-1.] }
			while { $fy>1. } { set fy [expr $fy-1.] }
			while { $fz>1. } { set fz [expr $fz-1.] }

			set ox [expr $modinv11*$fx + $modinv12*$fy + $modinv13*$fz]
			set oy [expr $modinv22*$fy + $modinv23*$fz]
			set oz [expr $modinv33*$fz]

			set modelres [list $atomnum $ox $oy $oz $fx $fy $fz $atominfo ]
			lappend modelatoms $modelres
		  }
  		}
	}

	# Read in the transformatoin matrix from trial pdb file
	while { [gets $trialfileid line] >= 0 } {
  		if { [regexp {CRYST1 *([-0-9.]*) *([-0-9.]*) *([-0-9.]*) *} $line full x y z] } { 
		  set mod2cell [list $x $y $z]
		}
  		if { [regexp {SCALE1 *([-0-9.]*) *([-0-9.]*) *([-0-9.]*) *} $line full mod2mat11 mod2mat12 mod2mat13] } {}
  		if { [regexp {SCALE2 *([-0-9.]*) *([-0-9.]*) *([-0-9.]*) *} $line full mod2mat21 mod2mat22 mod2mat23] } {}
  		if { [regexp {SCALE3 *([-0-9.]*) *([-0-9.]*) *([-0-9.]*) *} $line full mod2mat31 mod2mat32 mod2mat33] } {}
	}

	if { ![info exists mod2mat11] } {
		puts "Could not find SCALE1 card in trial pdb file"
	}

	#compute inverse matrix
	set mod2inv33 [expr 1./$mod2mat33 ]
	set mod2inv22 [expr 1./$mod2mat22 ]
	set mod2inv23 [expr -$mod2mat23*$mod2inv22*$mod2inv33 ]
	set mod2inv11 [expr 1./$mod2mat11 ]
	set mod2inv12 [expr -$mod2mat12*$mod2inv11*$mod2inv22 ]
	set mod2inv13 [expr -$mod2mat12*$mod2inv11*$mod2inv23 - $mod2mat13*$mod2inv11*$mod2inv33 ]

	close $trialfileid

	# Read in CA atoms from trial pdb file
	set trialfileid [open $trialfile r]
	while { [gets $trialfileid line] >= 0 } {
		if { [regexp {^(ATOM|HETATM) *([0-9]*) *CA *(([A-Z]*) *[a-zA-Z]* *[-0-9]*[A-Z]*) *(-*[0-9.]*) *(-*[0-9.]*) *(-*[0-9.]*) *([-0-9.]*)} $line full throw atomnum atominfo res x y z] } {
		  if { [regexp {ALA|ARG|ASN|ASP|ASX|CYS|GLN|GLU|GLX|GLY|HIS|ILE|LEU|LYS|MET|PHE|PRO|SER|THR|TRP|TYR|UNK|VAL|MSE} $res] } {
#puts "$atomnum $atominfo \n$x \n$y \n$z \n"

			# Transform these coordinates to fractional
			set fx [expr $mod2mat11*$x + $mod2mat12*$y + $mod2mat13*$z]
			set fy [expr $mod2mat22*$y + $mod2mat23*$z]
			set fz [expr $mod2mat33*$z]

			# Normalize all fractional coordinates to be between 0 and 1
			while { $fx<0. } { set fx [expr $fx+1.] }
			while { $fy<0. } { set fy [expr $fy+1.] }
			while { $fz<0. } { set fz [expr $fz+1.] }
			while { $fx>1. } { set fx [expr $fx-1.] }
			while { $fy>1. } { set fy [expr $fy-1.] }
			while { $fz>1. } { set fz [expr $fz-1.] }

			set ox [expr $modinv11*$fx + $modinv12*$fy + $modinv13*$fz]
			set oy [expr $modinv22*$fy + $modinv23*$fz]
			set oz [expr $modinv33*$fz]

			set trialres [list $atomnum $ox $oy $oz $fx $fy $fz $atominfo ]
			lappend trialatoms $trialres
		  }
  		}
	}

	if { ![info exists modelatoms] } {
		puts "compare-arpwarp-solution.tcl::Could not find any CA atoms in modelfile ($modelfile)"
		return 0
	}

	if { ![info exists trialatoms] } {
		puts "compare-arpwarp-solution.tcl::Could not find any CA atoms in trialfile ($trialfile)"
		return 0
	}

	set nmatch 0
	set ntrial 0
	set min_dist 0
	set rmserr 0
	set meanerr 0

	# Divide model atoms into blocks to speed up the comparison
	set num_atoms_in_block 12
	set atom_in_block 0
	set blocks 0
	set  min_x 99999
	set  min_y 99999
	set  min_z 99999
	set  max_x -99999
	set  max_y -99999
	set  max_z -99999
	foreach modelatom $modelatoms {
	  incr atom_in_block
	  set mx [lindex $modelatom 1]
	  set my [lindex $modelatom 2]
	  set mz [lindex $modelatom 3]
	  if { $mx < $min_x } { set min_x $mx }
	  if { $mx > $max_x } { set max_x $mx }
	  if { $my < $min_y } { set min_y $my }
	  if { $my > $max_y } { set max_y $my }
	  if { $mz < $min_z } { set min_z $mz }
	  if { $mz > $max_z } { set max_z $mz }
	  if { $atom_in_block >= $num_atoms_in_block } { 
		incr blocks
		set atom_in_block 0
		lappend modelblocks $min_x $min_y $min_z $max_x $max_y $max_z
		set  min_x 99999
		set  min_y 99999
		set  min_z 99999
		set  max_x -99999
		set  max_y -99999
		set  max_z -99999
	  }
	}
	lappend modelblocks $min_x $min_y $min_z $max_x $max_y $max_z
	#
	# Main loop to look for matching atoms
	# - trialatoms are the atoms output from ARP/wARP or another model
	#      building program
	# - modelatoms has been symmetry expanded to include all
	#      crystallographic symmetry related copies
	#
	set mult 3
	set multcutoff [expr $mult*$cutoff]
	set x [lindex $mod2cell 0]
	set y [lindex $mod2cell 1]
	set z [lindex $mod2cell 2]
	foreach trialatom $trialatoms {
		set min_dist 10000.
		set nmodel 0

		set tx [lindex $trialatom 1]
		set ty [lindex $trialatom 2]
		set tz [lindex $trialatom 3]

		set tx_f [lindex $trialatom 4]
		set ty_f [lindex $trialatom 5]
		set tz_f [lindex $trialatom 6]

		set tmin_x [expr $tx-$multcutoff]
		set tmin_y [expr $ty-$multcutoff]
		set tmin_z [expr $tz-$multcutoff]
		set tmax_x [expr $tx+$multcutoff]
		set tmax_y [expr $ty+$multcutoff]
		set tmax_z [expr $tz+$multcutoff]

		set block_now 0
		set modelblocks_pos 0
		set atom_in_block_now 0
		foreach modelatom $modelatoms {
			incr atom_in_block_now
			# test whether current block matches the trial atom or not
			if { $atom_in_block_now == 1 } {
			  set  min_x [lindex $modelblocks $modelblocks_pos]
			  incr modelblocks_pos
			  set  min_y [lindex $modelblocks $modelblocks_pos]
			  incr modelblocks_pos
			  set  min_z [lindex $modelblocks $modelblocks_pos]
			  incr modelblocks_pos
			  set  max_x [lindex $modelblocks $modelblocks_pos]
			  incr modelblocks_pos
			  set  max_y [lindex $modelblocks $modelblocks_pos]
			  incr modelblocks_pos
			  set  max_z [lindex $modelblocks $modelblocks_pos]
			  incr modelblocks_pos
			  set use_block 1
			  # testing both usual and "corner" case (see below) here
			  if {                  $tmin_x>$max_x } { 
				if { $min_x>0 || $tmax_x<[expr $min_x+$x] } { set use_block 0 }
			  }
			  if { $use_block==1 && $tmax_x<$min_x } { 
				if { $max_x<0 || $tmin_x>[expr $max_x-$x] } { set use_block 0 }
			  }
			  if { $use_block==1 && $tmin_y>$max_y } {
				if { $min_y>0 || $tmax_y<[expr $min_y+$y] } { set use_block 0 }
			  }
			  if { $use_block==1 && $tmax_y<$min_y } {
				if { $max_y<0 || $tmin_y>[expr $max_y-$y] } { set use_block 0 }
			  }
			  if { $use_block==1 && $tmin_z>$max_z } {
				if { $min_z>0 || $tmax_z<[expr $min_z+$z] } { set use_block 0 }
			  }
			  if { $use_block==1 && $tmax_z<$min_z } {
				if { $max_z<0 || $tmin_z>[expr $max_z-$z] } { set use_block 0 }
			  }
			  
			}

			if {$atom_in_block_now>=$num_atoms_in_block} { 
			  incr block_now
			  set atom_in_block_now 0
			}
			
			if { $use_block == 0 } { 
			  incr nmodel 
			  continue 
			}

			set mx [lindex $modelatom 1]
			set my [lindex $modelatom 2]
			set mz [lindex $modelatom 3]

			set mx_f [lindex $modelatom 4]
			set my_f [lindex $modelatom 5]
			set mz_f [lindex $modelatom 6]

			# The following is to handle a strange corner-case, identified by Pavol
			# If the model atom is just on the other side of our defintion of the
			#   unit cell, it will appear to be a whole unit cell away from the atom
			#   we are matching.  Test for this.
			set change 0

			if { [expr $mx_f - $tx_f] > 0.95 } { 
				set mx_f [expr $mx_f-1.] 
				set change 1
			} elseif { [expr $mx_f-$tx_f] < -0.95 } { 
				set mx_f [expr $mx_f+1.] 
				set change 1
			}

			if { [expr $my_f-$ty_f] > 0.95 } { 
				set my_f [expr $my_f-1.] 
				set change 1
			} elseif { [expr $my_f-$ty_f] < -0.95 } { 
				set my_f [expr $my_f+1.] 
				set change 1
			}

			if { [expr $mz_f-$tz_f] > 0.95 } { 
				set mz_f [expr $mz_f-1.] 
				set change 1
			} elseif { [expr $mz_f-$tz_f] < -0.95 } { 
				set mz_f [expr $mz_f+1.] 
				set change 1
			}

			if { $change == 1 } {
#				puts "change"
				set mx [expr $modinv11*$mx_f + $modinv12*$my_f + $modinv13*$mz_f]
				set my [expr $modinv22*$my_f + $modinv23*$mz_f]
				set mz [expr $modinv33*$mz_f]
				set tx [expr $modinv11*$tx_f + $modinv12*$ty_f + $modinv13*$tz_f]
				set ty [expr $modinv22*$ty_f + $modinv23*$tz_f]
				set tz [expr $modinv33*$tz_f]
			}
			
			# Calculate the distance between the trial atom and the model atom
			set distance [expr sqrt(($mx-$tx)*($mx-$tx) + ($my-$ty)*($my-$ty) + ($mz-$tz)*($mz-$tz))]

			if { $distance < $min_dist } {
			  set min_dist $distance
#			  puts "hm3: $nmatch $nmodel $ntrial\t($mx $my $mz)\t($tx $ty $tz)\t$min_dist"
			}
			if { $distance < $cutoff } {
				if { $verbose } {
					puts "$nmatch     $ntrial [lindex $trialatom 7]     $nmodel [lindex $modelatom 7]     $distance"
				}
				break
			}

			incr nmodel
			
		}

		if { $min_dist < $cutoff } {
			incr nmatch
			set rmserr [expr $rmserr + $min_dist*$min_dist]
			set meanerr [expr $meanerr + $min_dist]
		}
		if { $min_dist >= $cutoff } {
			if { $verbose } {
				if { $min_dist >= $multcutoff } {
				  puts "  Not matching:    $ntrial [lindex $trialatom 7]     >$multcutoff " 
				} else {
				  puts "  Not matching:    $ntrial [lindex $trialatom 7]     $min_dist " 
				}
			}
#			set rmserr [expr $rmserr + 1]
		}
		incr ntrial
	}

	if { $nmatch != 0 } {
		set rmserr [expr sqrt($rmserr/$nmatch)]
		set meanerr [expr $meanerr/$nmatch]
	} else {
		set rmserr 0.0
		set meanerr 0.0
	}
	puts ""
	if { $verbose } {
		puts "RMS error of model: $rmserr, mean error: $meanerr"
	}
	return $nmatch
	
}



#  		if { [regexp {ATOM *([0-9])* *CA *[A-Z]* *[A-Z]* *[0-9]* *([-0-9.]*) *([-0-9.]*) *([-0-9.]*)} $line full atomnum x y z] } {
# 			puts -nonewline "$atomnum $x $y $z\t"
# 			puts $line
#  		}


#
# Main
#
if { [lindex $argv 1] == "" } {
	puts "Usage:"
	puts "  compare-arpwarp-solution.tcl model.pdb arpwarp.pdb \[-v\]"
	puts " "
	puts "Where:"
	puts "  model.pdb -> original PDB file"
	puts "  arpwarp.pdb -> ARP/wARP model"
	puts ""
	puts "Output:"
	puts "  arpatoms/modelatoms atoms matchingres/arpwarpres/modelres"
	puts "Where:"
	puts "  arpatoms -> Number of atoms found by ARP/wARP"
	puts "  modelatoms -> Number of atoms in the model PDB file"
	puts "  matchingres -> Number of CA atoms placed within 1A of a correct CA position"
	puts "  arpwarpres -> Number of residues found by ARP/wARP"
	puts "  modelres -> Number of residues in the model PDB file"
	puts ""
	puts " -v option:  verbose output - info about match of every residue and the distance between the matching pair"
	puts ""
	puts " Copyright/GPL March 2005-2009 Steven Ness and Pavol Skubak"
	exit
}

if { [regexp {[-]v} $::argv] } {
	set verbose 1
} else {
	set verbose 0
}


set modelfile    [lindex $argv 0]
set arpwarpfile  [lindex $argv 1]
set crankplugins [lindex $argv 2]

# Expand the model coordinates to fill the entire unit cell
set expmodelfile "${modelfile}_exp.pdb"
set output [exec [file join $crankplugins check run_pdbset] $modelfile $expmodelfile]

#
# Count number of atoms
#
set modelatoms [num_atoms $modelfile]
set arpwarpatoms [num_atoms $arpwarpfile]

#puts "model atoms = $modelatoms"
#puts "arpwarp atoms = $arpwarpatoms"

#
# Count number of residues
#
set modelresidues [num_residues $modelfile]
set modelresiduesbyocc [num_occ_residues $modelfile]
set arpwarpresidues [num_residues $arpwarpfile]

#puts "model residues = $modelresidues"
#puts "arpwarp residues = $arpwarpresidues"

#
# Count number of matching residues
#
set rmserr 0.0
set meanerr 0.0
set match [num_residues_within $expmodelfile $arpwarpfile 1.0]

if { [file exists $expmodelfile] } {
   file delete $expmodelfile
}

#puts "matching residues = $match"

#
# Output all these quantities in a compact format
#

puts ""
puts "$arpwarpatoms/$modelatoms atoms\t$match/$arpwarpresidues/$modelresidues residues (total by occupancies $modelresiduesbyocc)"
puts "Fraction built 'correctly':  [expr $match/$modelresiduesbyocc]"
