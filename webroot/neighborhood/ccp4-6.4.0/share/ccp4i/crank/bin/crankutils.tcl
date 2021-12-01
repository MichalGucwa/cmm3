#!/usr/bin/env tclsh
#
# Copyright (C) 2003-2004 Steven Ness and Navraj S. Pannu, Leiden University
# Copyright (C) 2004-2007 Navraj S. Pannu, Leiden University
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

global tcl_platform
global system
global env
set system(OPSYS) [string toupper $tcl_platform(platform)]

if { [file exists [file join $env(CRANK) bin system.tcl] ] } {
    source [file join $env(CRANK) bin system.tcl]
} elseif { [info exists env(CCP4I_TOP)] } {
    source [file join $env(CCP4I_TOP) src system.tcl] 
}

if { [file exists [file join $env(CRANK) bin xml_utils.tcl] ] } {
    source [file join $env(CRANK) bin xml_utils.tcl]
} elseif { [info exists env(CCP4I_TOP)] } {
    source [file join $env(CCP4I_TOP) utils xml_utils.tcl] 
}

proc join_all_sftools { nextstep enant } {
    global XMLParse

# When we have enantiomorphic spacegroups, the spacegroup can
# change.  This is change is transferred through the crank via mtz
# files.  When sftools writes an mtz file, it takes the spacegroup of
# the first mtz file read in.  Hence, look for columns that are created
# on the last crank jobs first.
# ***NSP this is a rather bad hack.

    set script ""
    set mtz 0

    # Check for <phase_columns>
    if { [info exists XMLParse([join "crank soap run step=$nextstep input phase_columns phib" __])] } {
 	set input [string trim $XMLParse([join "crank soap run step=$nextstep input phase_columns phib" __])]
	if { [regexp {([0-9_A-Za-z]*)_PHIB} $input all id] } {
	    incr mtz
	    set script "$script read $mtz.mtz\n"
	    if { $enant } {
		set sftools_script "read crank.out.$id.oh.mtz\nwrite $mtz.mtz col "
	    } else {
		set sftools_script "read crank.out.$id.mtz\nwrite $mtz.mtz col "
	    }
	    set sftools_script "$sftools_script [format "%s%s" $id "_F"]"
	    set sftools_script "$sftools_script [format "%s%s" $id "_SIGF"]"
	    set sftools_script "$sftools_script [format "%s%s" $id "_PHIB"]"
	    set sftools_script "$sftools_script [format "%s%s" $id "_FOM"]\n "
	    set sftools_script "$sftools_script quit\n"
	    set command "sftools << \"$sftools_script\""
#           puts $command
	    catch {eval exec $command } output 
#           puts $output
#           puts "<phase_columns>::appending($id)."
	} else {
	    crank_error "crankutils.tcl::Could not match phase_columns=($input)"
	}
    }

    # Check for <hl_columns>
    if { [info exists XMLParse([join "crank soap run step=$nextstep input hl_columns hla" __])] } {
	set input [string trim $XMLParse([join "crank soap run step=$nextstep input hl_columns hla" __])]
	if { [regexp {([0-9_A-Za-z]*)_HLA} $input all id] } {
	    incr mtz
	    set script "$script read $mtz.mtz\n"
	    if { $enant } {
		set sftools_script "read crank.out.$id.oh.mtz\nwrite $mtz.mtz col "
	    } else {
		set sftools_script "read crank.out.$id.mtz\nwrite $mtz.mtz col "
	    }
	    set sftools_script "$sftools_script [format "%s%s" $id "_HLA"]"
	    set sftools_script "$sftools_script [format "%s%s" $id "_HLB"]"
	    set sftools_script "$sftools_script [format "%s%s" $id "_HLC"]"
	    set sftools_script "$sftools_script [format "%s%s" $id "_HLD"]\n"
	    set sftools_script "$sftools_script quit\n"
	    set command "sftools << \"$sftools_script\""
#	    puts $command
	    catch {eval exec $command } output 
#	    puts $output
#	    puts "<hl_columns>::appending($id)."
	} else {
	    crank_error "crankutils.tcl::Could not match hl_columns=($input)"
	}
    }

    # Check for <f_columns>
    if { [info exists XMLParse([join "crank soap run step=$nextstep input f_columns f" __])] } {
	set input [string trim $XMLParse([join "crank soap run step=$nextstep input f_columns f" __])]
	if { [regexp {([0-9_A-Za-z]*)_X1_D1_F} $input all id] } {
#	    puts "<f_columns>::appending($id)."
	    incr mtz
	    set script "$script read $mtz.mtz\n"
	    set sftools_script "read crank.out.$id.mtz\nwrite $mtz.mtz col "
	    set sftools_script "$sftools_script [format "%s%s" $id "_X1_D1_F"]"
	    set sftools_script "$sftools_script [format "%s%s" $id "_X1_D1_SIGF"]\n"
	    set sftools_script "$sftools_script quit\n"
	    set command "sftools << \"$sftools_script\""
#	    puts $command
	    catch {eval exec $command } output 
#	    puts $output
	} elseif { [regexp {([0-9_A-Za-z]*)_F} $input all id] } {
	    incr mtz
	    set script "$script read $mtz.mtz\n"
	    set sftools_script "read crank.out.$id.mtz\nwrite $mtz.mtz col "
	    set sftools_script "$sftools_script [format "%s%s" $id "_F"]"
	    set sftools_script "$sftools_script [format "%s%s" $id "_SIGF"]\n"
	    set sftools_script "$sftools_script quit\n"	    
	    set command "sftools << \"$sftools_script\""
#	    puts $command
	    catch {eval exec $command } output 
#	    puts $output
#	    puts "<f_columns>::appending($id)."
	} else {
	    crank_error "crankutils.tcl::Could not match f_columns=($input)"
	}
    }

    # Check for <i_columns>
    if { [info exists XMLParse([join "crank soap run step=$nextstep input i_columns i" __])] } {
	set input [string trim $XMLParse([join "crank soap run step=$nextstep input i_columns i" __])]
	if { [regexp {([0-9_A-Za-z]*)_I} $input all id] } {
	    incr mtz
	    set script "$script read $mtz.mtz\n"
	    set sftools_script "read crank.out.$id.mtz\nwrite $mtz.mtz col "
	    set sftools_script "$sftools_script [format "%s%s" $id "_I"]"
	    set sftools_script "$sftools_script [format "%s%s" $id "_SIGI"]\n"
	    set sftools_script "$sftools_script quit\n"	    
	    set command "sftools << \"$sftools_script\""
#	    puts $command
	    catch {eval exec $command } output 
#	    puts $output
#	    puts "<i_columns>::appending($id)."
	} else {
	    crank_error "crankutils.tcl::Could not match i_columns=($input)"
	}
    }
	
    # Check for <ea_columns>
     if { [info exists XMLParse([join "crank soap run step=$nextstep input ea_columns ea" __])] } {
	 set input [string trim $XMLParse([join "crank soap run step=$nextstep input ea_columns ea" __])]
	 if { [regexp {([0-9_A-Za-z]*)_EA} $input all id] } {
	    incr mtz
	    set script "$script read $mtz.mtz\n"
	    set sftools_script "read crank.out.$id.mtz\nwrite $mtz.mtz col "
	    set sftools_script "$sftools_script [format "%s%s" $id "_EA"]"
	    set sftools_script "$sftools_script [format "%s%s" $id "_SIGEA"]\n"
	    set sftools_script "$sftools_script quit\n"	    
	    set command "sftools << \"$sftools_script\""
#	    puts $command
	    catch {eval exec $command } output 
#	    puts $output
#	    puts "<ea_columns>::appending($id)."
	 } else {
	     crank_error "crankutils.tcl::Could not match ea_columns=($input)"
	 }
     } 

    # Check for <fa_columns>
    if { [info exists XMLParse([join "crank soap run step=$nextstep input fa_columns fa" __])] } {
	set input [string trim $XMLParse([join "crank soap run step=$nextstep input fa_columns fa" __])]
	if { [regexp {([0-9_A-Za-z]*)_FA} $input all id] } {
	    incr mtz
	    set script "$script read $mtz.mtz\n"
	    set sftools_script "read crank.out.$id.mtz\nwrite $mtz.mtz col "
	    set sftools_script "$sftools_script [format "%s%s" $id "_FA"]"
	    set sftools_script "$sftools_script [format "%s%s" $id "_SIGFA"]\n"
	    set sftools_script "$sftools_script quit\n"
	    set command "sftools << \"$sftools_script\""
#	    puts $command
	    catch {eval exec $command } output 
#	    puts $output
#	    puts "<fa_columns>::appending($id)."
	} else {
	    crank_error "crankutils.tcl::Could not match fa_columns=($input)"
	}
    }
	
    # Check for <alpha_columns>
    if { [info exists XMLParse([join "crank soap run step=$nextstep input alpha_columns alpha" __])] } {
	set input [string trim $XMLParse([join "crank soap run step=$nextstep input alpha_columns alpha" __])]
	if { [regexp {([0-9_A-Za-z]*)_ALPHA} $input all id] } {
	    incr mtz
	    set script "$script read $mtz.mtz\n"
	    set sftools_script "read crank.out.$id.mtz\nwrite $mtz.mtz col "
	    set sftools_script "$sftools_script [format "%s%s" $id "_ALPHA"]\n"
	    set sftools_script "$sftools_script quit\n"
	    set command "sftools << \"$sftools_script\""
#	    puts $command
	    catch {eval exec $command } output 
#	    puts $output
#	    puts "<alpha_columns>::appending($id)."
	} else {
	    crank_error "crankutils.tcl::Could not match alpha_columns=($input)"
	}
    }

    # Check for <exp_columns> amplitude columns
    if { [info exists XMLParse([join "crank soap run step=$nextstep input exp_columns crystal=1 data=1 f" __])] } {
	set inputf [string trim $XMLParse([join "crank soap run step=$nextstep input exp_columns crystal=1 data=1 f" __])]
	if { [regexp {([0-9_A-Za-z]*)_X1_D1_F} $inputf all id] } {
	    set i 1
	    while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } { 
		set j 1
		while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } { 
		    incr mtz
		    set script "$script read $mtz.mtz\n"
		    set sftools_script "read crank.out.$id.mtz\nwrite $mtz.mtz col "

		    set id2 [format "%s%s%s%s%s" $id "_X" $i "_D" $j] 

		    set sftools_script "$sftools_script [format "%s%s" $id2 "_F"]"
		    set sftools_script "$sftools_script [format "%s%s" $id2 "_SIGF"]"

		    if { $XMLParse([join "crank parameters crystal=$i data=$j anomalous" __]) == "1" } {
			set sftools_script "$sftools_script [format "%s%s" $id2 "_F+"]"
			set sftools_script "$sftools_script [format "%s%s" $id2 "_SIGF+"]"
			set sftools_script "$sftools_script [format "%s%s" $id2 "_F-"]"
			set sftools_script "$sftools_script [format "%s%s" $id2 "_SIGF-"]\n"
		    } else {
			set sftools_script "$sftools_script \n"
		    }
		    set command "sftools << \"$sftools_script\""
#		    puts $command
		    catch {eval exec $command } output 
#		    puts $output

		    incr j
		}
		incr i
	    }
#	    puts "<exp_columns>::appending($id)."
	} else {
	    crank_error "crankutils.tcl::Could not match exp_columns=($inputf)"
	}
    }

    # Check for <exp_columns> intensity columns
    set expi 0

    if { [info exists XMLParse([join "crank soap run step=$nextstep input exp_columns crystal=1 data=1 i" __])] } {
	set inputi [string trim $XMLParse([join "crank soap run step=$nextstep input exp_columns crystal=1 data=1 i" __])]
	if { [regexp {([0-9_A-Za-z]*)_X1_D1_I} $inputi all id] } {
	    set expi 1
	} else {
	    crank_error "crankutils.tcl::Could not match exp_columns=($inputi)"
	}

    } elseif { [info exists XMLParse([join "crank soap run step=$nextstep input exp_columns crystal=1 data=1 i_plus" __])] } {
	set inputi [string trim $XMLParse([join "crank soap run step=$nextstep input exp_columns crystal=1 data=1 i_plus" __])]
	if { [regexp {([0-9_A-Za-z]*)_X1_D1_I+} $inputi all id] } {
	    set expi 1
	} else {
	    crank_error "crankutils.tcl::Could not match exp_columns=($inputi)"
	}
    }

    if { $expi == 1 } {
	set i 1
	while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } { 
	    set j 1
	    while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } { 
		incr mtz
		set script "$script read $mtz.mtz\n"
		set sftools_script "read crank.out.$id.mtz\nwrite $mtz.mtz col "

		set id2 [format "%s%s%s%s%s" $id "_X" $i "_D" $j] 

		if { [string compare $XMLParse([join "crank parameters crystal=$i data=$j anomalous" __]) "0"] == 0 } {
		    set sftools_script "$sftools_script [format "%s%s" $id2 "_I"]"
		    set sftools_script "$sftools_script [format "%s%s" $id2 "_SIGI"]\n"
		} else {
		    set sftools_script "$sftools_script [format "%s%s" $id2 "_I+"]"
		    set sftools_script "$sftools_script [format "%s%s" $id2 "_SIGI+"]"
		    set sftools_script "$sftools_script [format "%s%s" $id2 "_I-"]"
		    set sftools_script "$sftools_script [format "%s%s" $id2 "_SIGI-"]\n"
		}
		set command "sftools << \"$sftools_script\""
#		puts $command
		catch {eval exec $command } output 
#		puts $output
#		puts "<exp_columns>::appending($id)."
	 	incr j
	    }
	    incr i
	}
    }
	
    # Check for <phic_columns>
    if { [info exists XMLParse([join "crank soap run step=$nextstep input phic_columns fc" __])] } {
	set input [string trim $XMLParse([join "crank soap run step=$nextstep input phic_columns fc" __])]
	if { [regexp {([0-9_A-Za-z]*)_FC} $input all id] } {
	    incr mtz
	    set script "$script read $mtz.mtz\n"
	    set sftools_script "read crank.out.$id.mtz\nwrite $mtz.mtz col "
	    set sftools_script "$sftools_script [format "%s%s" $id "_FC"]"
	    set sftools_script "$sftools_script [format "%s%s" $id "_PHIC"]\n"
	    set sftools_script "$sftools_script quit\n"
	    set command "sftools << \"$sftools_script\""
#	    puts $command
	    catch {eval exec $command } output 
#	    puts $output
#	    puts "<phic_columns>::appending($id)."
	} else {
	    crank_error "crankutils.tcl::Could not match phic_columns=($input)"
	}
    }
    
    # Check for <freer_columns>
    if { [info exists XMLParse([join "crank soap run step=$nextstep input freer_columns freer" __])] } {
	set input [string trim $XMLParse([join "crank soap run step=$nextstep input freer_columns freer" __])]
	if { [regexp {([0-9_A-Za-z]*)_FREER} $input all id] } {
	    incr mtz
	    set freertag [format "%s%s" $id "_FREER"]
	    set script "$script read $mtz.mtz\nselect col $freertag absent\ncalc col $freertag = 1\nselect all\n"
	    set sftools_script "read crank.out.$id.mtz\nwrite $mtz.mtz col "
	    set sftools_script "$sftools_script $freertag\n"
	    set sftools_script "$sftools_script quit\n"
	    set command "sftools << \"$sftools_script\""
#	    puts $command
	    catch {eval exec $command } output 
#	    puts $output
#	    puts "<freer_columns>::appending($id)."
	} else {
	    crank_error "crankutils.tcl::Could not match freer_columns=($input)"
	}
    }

    if { $script != "" } {
	set tag [string trim $XMLParse([join "crank soap run step=$nextstep tag" __])]
	if { $enant } {
 	    set script "$script write crank.in.$tag.oh.mtz\nquit\n"
	} else {
	    set script "$script write crank.in.$tag.mtz\nquit\n"
	}
	set command "sftools << \"$script\""
#	puts $command
	catch {eval exec $command } output 
#	puts $output
	for { set i 1 } { $i <= $mtz } { incr i } {
	    file delete $i.mtz
	}
    } else {
	puts "no columns to join."
    }
}

proc read_pdb_atom_line { line numberin atomin xin yin zin occin bfacin } {

    # return 0 if line does not exist or if it is not a proper HETATM/ATOM card.

    if { [info exists line] } {
	if { [regexp {^HETATM.*} $line junk] || [regexp {^ATOM.*} $line junk] } {
	    if { ([string length $line] > 64)  } {
 		upvar $numberin number
		upvar $atomin   atom
		upvar $xin      x
		upvar $yin      y
		upvar $zin      z
		upvar $occin    occ
		upvar $bfacin   bfac

		set number [string range $line 6  10]
		set atoms  [string range $line 12 14]
		regsub -all {[ \t]+} $atoms "" atom
		set x      [string range $line 30 37]
		set y      [string range $line 38 45]
		set z      [string range $line 46 53]
		set occ    [string range $line 54 59]
		set bfac   [string range $line 60 65]
		return 1
	    } else {
		return 0
	    }
	} else {
	    return 0
	}
    } else {
	return 0
    }
}

proc write_pdb_atom_line { output number1 atom number2 x y z occ bfac } {
    # write out a HETATM card: note that I write out the atom name in the residue slot.

    set residue $atom

    if { [string compare $atom "I"] == 0 } {
	set residue "IOD"
    } elseif { [string compare $atom "S"] == 0 } {
	set atom "S"
	set residue "SO4"
    }

    if { [info exists output] } {
	puts $output [format "HETATM%5d %-4s %3s   %3d    %8.3f%8.3f%8.3f%6.2f%6.2f" $number1 $atom $residue $number2 $x $y $z $occ $bfac]
    } else {
	crank_error "write_pdb_atom_line::output pdb file does not exist"
    }
}

proc get_cryst_card_from_pdb { input_pdb linein } {
    global XMLParse
    upvar $linein line1
    
    set got_cryst 0

    if { [file exists $input_pdb] } {
	set input [open $input_pdb r]
	set indata [split [read $input] "\n"]
	foreach line  $indata {
	    if { [regexp {^CRYST1.*} $line junk ] } {
		set line1 $line
		set got_cryst 1
		break
	    } 
	}
    }
    return $got_cryst
}

proc add_remove_atoms { input_pdb1 input_pdb2 output_pdb } {
    global XMLParse
    global env
    
    # remove atoms from input_pdb1 with low occupancy
    set MIN_OCC_CUT_OFF 0.03
    # add atoms from input_pdb2 with high rms
    # PS: this treshold is already set in bp3/refmac plugins!
    set GRAD_OCC_CUT_OFF 3
    # returns if the output_pdb is different from input_pdb1
    set changes 0

    if { ![file exists $input_pdb1] } {
	crank_error "crankutils.tcl::Input pdb does not exist"
    }

    set i 1
    while { [info exists XMLParse([join "crank parameters crystal=$i native" __])] } {
	if { $XMLParse([join "crank parameters crystal=$i native" __]) == "0"} {
	    if { [info exists XMLParse([join "crank parameters crystal=$i substructure atom_name" __])] } {
		set inputatom [string toupper $XMLParse([join "crank parameters crystal=$i substructure atom_name" __])] 
	    } else {
		crank_error "crankutils.tcl::no substructure atom"
	    }
	    if { [info exists XMLParse([join "crank parameters crystal=$i data=1 bfactor" __])] } {
		set b $XMLParse([join "crank parameters crystal=$i data=1 bfactor" __])  
	    } else {
		set b 25.0
	    }
	}
	incr i
    }

#   if { [file exists [file join $env(CRANK) bin dummy remove_dummy] ] } {
#catch {eval exec [file join $env(CRANK) bin dummy remove_dummy] $input_pdb1 $input_pdb2} output
#puts $output
#   }

    set output [open $output_pdb w]
    set input [open $input_pdb1 r]
    set indata [split [read $input] "\n"]
    
    if { [get_cryst_card_from_pdb $input_pdb1 line] } {
	if { [info exists line] } {
	  puts $output $line
	}
    }

    set i 0
    foreach line  $indata {
	if { [read_pdb_atom_line $line number atom x y z occ bfac] } {
	    incr i
	    if { $occ > $MIN_OCC_CUT_OFF } {
 		write_pdb_atom_line $output $number $atom      $i $x $y $z $occ $bfac 
	    } 
	} 
    }
    close $input

    if { [file exists $input_pdb2] } {
      set input [open $input_pdb2 r]
      set indata [split [read $input] "\n"]

      foreach line  $indata {
	  if { [read_pdb_atom_line $line number atom x y z occ bfac] } {
	    incr i
	    if { $occ > $GRAD_OCC_CUT_OFF } {
		write_pdb_atom_line $output $i $inputatom $i $x $y $z "0.10" $b    
		set changes 1
 	    }
	  } 
      }
      close $input
    }
    puts $output "END"    
    close $output

    return $changes
}

proc check_refmac_substructure { input_pdb output_pdb } {
    global XMLParse
    global env    

    set input [open $input_pdb r]
    set indata [split [read $input] "\n"]
    set output [open $output_pdb w]
    
    if { [get_cryst_card_from_pdb $input_pdb line] } {
	if { [info exists line] } {
	    puts $output $line
	}
    }

    set i 0
    foreach line  $indata {
	if { [read_pdb_atom_line $line number atom x y z occ bfac] } {
	    incr i
	    write_pdb_atom_line $output $number $atom      $i $x $y $z $occ $bfac 
	} 
    }
    close $input

    puts $output "END"    
    close $output
}

proc check_space_group { input_pdb } {
    global XMLParse
    set c 1
    
    if { [info exists XMLParse([join "crank parameters crystal=$c cell cell_a" __]) ] } {
	set aa $XMLParse([join "crank parameters crystal=$c cell cell_a" __])
	set bb $XMLParse([join "crank parameters crystal=$c cell cell_b" __])
	set cc $XMLParse([join "crank parameters crystal=$c cell cell_c" __])
	set alpha $XMLParse([join "crank parameters crystal=$c cell cell_alpha" __])
	set beta  $XMLParse([join "crank parameters crystal=$c cell cell_beta" __])
	set gamma $XMLParse([join "crank parameters crystal=$c cell cell_gamma" __])
    } 

    if { [file exists $input_pdb] } {
	set input [open $input_pdb r]
	set indata [split [read $input] "\n"]
	foreach line  $indata {
	    regsub -all {\s+} $line " " line
	    if { [regexp {^CRYST1 *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*).*} $line junk pdba pdbb pdbc pdbal pdbbe pdbga] } {
		break
	    } 
	}
    }

    if { [info exists aa] && [info exists pdba] && [info exists gamma] && [info exists pdbga] } {
	set part1 [expr pow(($aa - $pdba),2) + pow(($bb - $pdbb),2) + pow(($cc - $pdbc),2)]
	set part2 [expr pow(($alpha - $pdbal),2) + pow(($beta - $pdbbe),2) + pow(($gamma - $pdbga),2)]
	set rms [expr sqrt($part1 + $part2)]

	if { $rms > 2.0 } {
	    puts "Cell from pdb $pdba $pdbb $pdbc $pdbal $pdbbe $pdbga"
	    puts "Cell from xml $aa $bb $cc $alpha $beta $gamma"
	    crank_error "cell dimensions from input substructure pdb and crank xml file differ"
 	}
    } 
}

proc check_atom { input_pdb output_pdb detect print logfile} {
    global XMLParse
    
    # Some substructure detection programs do not know about the atoms
    # they are trying to find.  This routine will change the atom names
    # to the one's that are looked for.

    if { ![file exists $input_pdb] } {
	crank_error "crankutils.tcl::Input pdb does not exist"
    }

    if { $detect } {
	set i 1
	while { [info exists XMLParse([join "crank parameters crystal=$i native" __])] } {
	    if { $XMLParse([join "crank parameters crystal=$i native" __]) == "0"} {
		if { [info exists XMLParse([join "crank parameters crystal=$i substructure atom_name" __])] } {
		    set inputatom [string toupper $XMLParse([join "crank parameters crystal=$i substructure atom_name" __])] 
		} else {
		    crank_error "crankutils.tcl::no substructure atom"
		}
		if { [info exists XMLParse([join "crank parameters crystal=$i data=1 bfactor" __])] } {
		    set b $XMLParse([join "crank parameters crystal=$i data=1 bfactor" __])  
		} else {
		    set b 25.0
		}
	    }
	    incr i
	}
    }

    set input [open $input_pdb r]
    set indata [split [read $input] "\n"]
    set output [open $output_pdb w]

    set natoms 0

    if { $print } {
	set log [open $logfile a]
	puts $log "\n\$TABLE : Atom number versus occupancy:"
	puts $log "\$SCATTER"
	puts $log " : Atom number versus occupancy :A:1,2:"
	puts $log "\$\$"
	puts $log "Number  Occupancy   \$\$ \$\$"
    }	

    set i 0
    foreach line  $indata {
	if { [read_pdb_atom_line $line number atom x y z occ bfac ] } {
            incr i
	     
	    if { $detect } {
		write_pdb_atom_line $output $number $inputatom $i $x $y $z $occ $b
	    } else {
 		write_pdb_atom_line $output $number $atom      $i $x $y $z $occ $bfac
	    }
	    if { $print } {
		puts $log [format "  %3d       %5.3f" $number $occ]
	    }
	    incr natoms
	} else {
	    puts $output $line
	}
    }

    if { $print } {
	puts $log "\$\$\n"
	close $log
    }	

    if { $natoms == 0 } {
	crank_error "crankutils.tcl::no substructure atoms output"
    }
    
    close $input
    close $output
}

proc enantiomorph_mtz { input_mtz output_mtz sg_number } {
 
   spacegroup_enantiomorph $sg_number hand_number    
 
   if { $sg_number != $hand_number } {
       set mtz_in $input_mtz
       set script "read $mtz_in \n set spacgroup \n $hand_number \n write $output_mtz \n quit \n"
       set command "sftools << \"$script\""
       catch {eval exec $command} output
#	puts $output
   } 
}

proc enantiomorph_pdb { input_pdb output_pdb sg_number} {
    
    # make pdb file for enantiomorph

    if { ![file exists $input_pdb] } {
	crank_error "crankutils.tcl::Input pdb does not exist"
    }

    set input [open $input_pdb r]
    set indata [split [read $input] "\n"]
    set output [open $output_pdb w]
    set i 0

    foreach line  $indata {
	if { [read_pdb_atom_line $line number atom x y z occ bfac] } {
	    if { ([info exists x] && [info exists y] && [info exists z]) } {
		incr i
		orth2frac $x $y $z fracx fracy fracz 
		if { $sg_number        == 81  } {
		    set fracx [expr 1.0  - $fracx]
		    set fracy [expr 0.5  - $fracy]
		    set fracz [expr 1.0  - $fracz]
		} elseif { $sg_number == 98  } {
		    set fracx [expr 1.0  - $fracx]
		    set fracy [expr 0.5  - $fracy]
		    set fracz [expr 0.25 - $fracz]
		} elseif { $sg_number == 210 } {
		    set fracx [expr 0.25 - $fracx]
		    set fracy [expr 0.25 - $fracy]
		    set fracz [expr 0.25 - $fracz]
		} else {
		    set fracx [expr -1.0 * $fracx ]
		    set fracy [expr -1.0 * $fracy ]
		    set fracz [expr -1.0 * $fracz ]
		}
		frac2orth $fracx $fracy $fracz orthx orthy orthz
		write_pdb_atom_line $output $number $atom $i $orthx $orthy $orthz $occ $bfac
	    }
	} else {
	    puts $output $line
	}
    }
    
    close $input
    close $output
}

proc pdb2shelxres { pdbfile insfile outputres } {

    set pdb [open $pdbfile   r]
    set ins [open $insfile   r]
    set res [open $outputres w]

    set done 0
    while { [gets $ins line] >= 0 && !$done } {
	if { [regexp {UNIT} $line full path] } {
	    set done 1
	}
	puts $res $line
    }
    close $ins

    set fracx 0.0000
    set fracy 0.0000
    set fracz 0.0000

    set i 1
    foreach line [split [read $pdb] "\n"] {
	if { [read_pdb_atom_line $line number atom x y z occ bfac] } {
	    orth2frac $x $y $z fracx fracy fracz
	    puts $res [format "%1s%03i%4i%10.6f%10.6f%10.6f%9.4f%5.1f" "P" $i 1 $fracx $fracy $fracz $occ 0.2]
 	    incr i
	} 
    }
    puts $res "HKLF 3"
    puts $res "END "

    close $pdb
    close $res
}

proc solomongraph { log1 log2 mlog1 mlog2 margin hcycle } {

# parses solomon logfile, outputs graphs and analyzes hand
 
    if { [file exists $log1] } {
	set logfile1 [open $log1 r]

	set data [read $logfile1]
	set data [split $data "\n"]
 
	set number 1
	array set contrast1 {}
	array set cor1 {} 
	array set fom1 {}

	foreach line $data {
	    if { [regexp       {Too unrepresentative free.*} $line junk] } {
		set number 1
	    }
	    if { [regexp       {Inverse contrast is* *([0-9.]*).*} $line junk con] } {
		if { $con < 0 } {
		     puts "Error contrast is negative\n"
		} else { 
		    set contrast1($number) [expr 1.0/$con ] 
		}
	    }
	    if { [regexp       { Overall MEAN FOM is* *([0-9.]*).*} $line junk fomcycle] } {
		set fom1($number) $fomcycle
	    }
	    if { [regexp       { Overall MEAN W is* *([0-9.]*).*} $line junk fomcycle] } {
		set fom1($number) $fomcycle
	    }
	    if { [regexp       {.*([0-9]*) Reflections is *([0-9.]*).*} $line junk refs correl] } {
		set cor1($number) $correl 
		incr number
	    }
	    if { [regexp       { Overall Correlation is* *([0-9.]*).*} $line junk correl] } {
		set cor1($number) $correl 
		incr number
	    }
	}

 	set ncycles [expr $number - 1]

	close $logfile1
    } else {
	crank_error "solomongraph::solomon logfile does not exist"
    }
	
	
    if { [file exists $log2] } {
	set logfile2 [open $log2 r]

	set data [read $logfile2]
	set data [split $data "\n"]

	set number 1
	array set contrast2 {}
	array set cor2 {} 
	array set fom2 {}
    
	foreach line $data {
	    if { [regexp       {Too unrepresentative free.*} $line junk] } {
		set number 1
	    }
	    if { [regexp       {Inverse contrast is* *([0-9.]*).*} $line junk con] } {
		if { $con < 0 } {
		    puts "Error contrast is negative\n"
		} else {
		    set contrast2($number) [expr 1.0/$con ] 
		}
	    }
	    if { [regexp       { Overall MEAN FOM is* *([0-9.]*).*} $line junk fomcycle] } {
		set fom2($number) $fomcycle
	    }
	    if { [regexp       { Overall MEAN W is* *([0-9.]*).*} $line junk fomcycle] } {
		set fom2($number) $fomcycle
	    }
	    if { [regexp       {.*([0-9]*) Reflections is *([0-9.]*).*} $line junk refs correl] } {
		set cor2($number) $correl 
		incr number
	    }
	    if { [regexp       { Overall Correlation is* *([0-9.]*).*} $line junk correl] } {
		set cor2($number) $correl 
		incr number
	    }
	}

	set ncycles [expr $number - 1]
    set h1_score 0
    set h2_score 0

	close $logfile2

	puts "\n\ \$TABLE : Fom and contrast of each hand per cycle:"
	puts "\$GRAPHS    : Contrast*Correlation for each hand per cycle :A:1,6,7:"
	puts "           : Contrast for each hand per cycle :A:1,4,5:"
	puts "           : FOM for each hand per cycle :A:1,2,3:"
	puts "\$\$"
	puts "Cycle  FOM_Hand1    FOM_Hand2    Contrast_Hand1    Contrast_Hand2    Corr*Contrast_Hand1    Corr*Contrast_Hand2  \$\$ \$\$"
	for {set i 1} {$i <= $ncycles} {incr i} {
        if { [info exists fom1($i)] } {
	      puts [format "%3d      %5.3f        %5.3f          %5.3f            %5.3f                %5.3f                  %5.3f    " $i $fom1($i) $fom2($i) $contrast1($i) $contrast2($i) [expr $cor1($i) * $contrast1($i)] [expr $cor2($i) * $contrast2($i)]]
	      if { [expr $contrast1($i)*$cor1($i) - $contrast2($i)*$cor2($i) ] > $margin } {
            set h1_score [expr $h1_score+1]
          } else {
		    if { [expr $contrast2($i)*$cor2($i) - $contrast1($i)*$cor1($i) ] > $margin } {
              set h2_score [expr $h2_score+1]
            }
          }
        }
	}
	puts "\$\$\n\n"

    # now have a look at mapro results
    if { [file exists $mlog1] && [file exists $mlog2] } {
      set cld1 0
      set cld2 0
	  set logfile1 [open $mlog1 r]
	  set data [read $logfile1]
	  set data [split $data "\n"]
	  foreach line $data {
	    if { [regexp {Correlation of the map with its local deviation is* *([0-9e\-.]*).*} $line junk cld] } {
	      set cld1 $cld
	    }
      }
	  set logfile2 [open $mlog2 r]
	  set data [read $logfile2]
	  set data [split $data "\n"]
	  foreach line $data {
	    if { [regexp {Correlation of the map with its local deviation is* *([0-9e\-.]*).*} $line junk cld] } {
	      set cld2 $cld
	    }
      }
	  if { $cld1 > $cld2 } {
        set h1_score [expr $h1_score+7]
      } else { 
	    if { $cld2 > $cld1 } {
          set h2_score [expr $h2_score+7]
        }
      }
    }

	set enantin 0
   
	#if {  [expr $contrast1($hcycle)*$cor1($hcycle)] >= [expr $contrast2($hcycle)*$cor2($hcycle)] }
	if { $h1_score >= $h2_score } {
	    set enantin 1
	} else {
	    set enantin 2
	}

	if { ($enantin == 0) } {
	    if { [expr $contrast1(1)*$cor1(1) - $contrast2(1)*$cor2(1) ] > $margin  } {
		set enantin 1
	    } elseif { [expr $contrast2(1)*$cor2(1) - $contrast1(1)*$cor1(1) ] > $margin } {
		set enantin 2
	    }
	}

	if {       ($enantin == 1) } {
	    set result "The input hand has a higher score."
	} elseif { ($enantin == 2) } {
	    set result "The inverted hand has a higher score."
	} else {
	    crank_error "solomongraph::Correct hand could not be determined\n"
	}
	
	puts "\$TEXT:Result: \$\$ Final result \$\$"
	puts "$result"
	#puts [format "CC*contrast for Hand 1 %5.3f for Hand 2 %5.3f at cycle $hcycle"  [expr $cor1($hcycle) * $contrast1($hcycle)] [expr $cor2($hcycle) * $contrast2($hcycle)]] 
    puts [ format "Combined DM correlation*contrast and phasing CLD score for Hand 1 is %5i and for Hand 2 is %5i" $h1_score $h2_score ]
    
	puts "\$\$\n"
    } else {
 	puts "\n\ \$TABLE : Fom and contrast for input hand:"
	puts "\$GRAPHS    : Contrast*Correlation for input hand per cycle :A:1,4:"
	puts "           : Contrast for input hand per cycle :A:1,3:"
	puts "           : FOM for input hand per cycle :A:1,2:"
	puts "\$\$"
	puts "Cycle  FOM_Hand1    Contrast_Hand1    Corr*Contrast_Hand1  \$\$ \$\$"
	for {set i 1} {$i <= $ncycles} {incr i} {
            if { [info exists fom1($i)] } {
	      puts [format "%3d      %5.3f        %5.3f                 %5.3f     " $i $fom1($i) $contrast1($i) [expr $cor1($i) * $contrast1($i)] ]
	    }
        }
	puts "\$\$\n\n"
    }
}


proc orth2frac { orthx orthy orthz fracxin fracyin fraczin } {
    global XMLParse
    upvar $fracxin fracx
    upvar $fracyin fracy
    upvar $fraczin fracz

    set a     0.000000
    set b     0.000000
    set c     0.000000
    set alpha 0.000000
    set beta  0.000000
    set gamma 0.000000

    set i 1
    while { [info exists XMLParse([join "crank parameters crystal=$i native" __])] } {
	if { $XMLParse([join "crank parameters crystal=$i native" __]) == "0"  } {
    
	    set a $XMLParse([join "crank parameters crystal=$i cell cell_a" __])
	    set b $XMLParse([join "crank parameters crystal=$i cell cell_b" __])
	    set c $XMLParse([join "crank parameters crystal=$i cell cell_c" __])
	    set alpha $XMLParse([join "crank parameters crystal=$i cell cell_alpha" __])
	    set beta  $XMLParse([join "crank parameters crystal=$i cell cell_beta" __])
	    set gamma $XMLParse([join "crank parameters crystal=$i cell cell_gamma" __])
	    break
	}
	incr i
    }

    if { !($a > 0.0 ) } {
	crank_error "crankutils.tcl::orth2frac unit cell edges not determined correctly"
    }

    set degreetorad 0.01745329251994329576924
    set cosalpha [expr cos($alpha*$degreetorad) ]
    set cosbeta  [expr cos($beta*$degreetorad) ]
    set sinbeta  [expr sin($beta*$degreetorad) ]
    set cosgamma [expr cos($gamma*$degreetorad) ]
    set singamma [expr sin($gamma*$degreetorad) ]

    set arg1     [expr ($cosbeta*$cosgamma - $cosalpha)/($sinbeta*$singamma)]

    set arg2     [expr sqrt(1.00000000 - $arg1*$arg1)]

    set or2frac00 [expr 1.00000000/$a]
    set or2frac01 [expr -$cosgamma/($singamma*$a)]
    set or2frac02 [expr -(($cosgamma*$sinbeta*$arg1+$cosbeta*$singamma)/($sinbeta*$arg2*$singamma*$a)) ]

    set or2frac11 [expr 1.000000000/($singamma*$b)]
    set or2frac12 [expr $arg1/($arg2*$singamma*$b)]

    set or2frac22 [expr 1.00000000/($sinbeta*$arg2*$c)]

    set fracx     [expr $orthx*$or2frac00 + $orthy*$or2frac01 + $orthz*$or2frac02]

    while { $fracx > 1.0  } {
	set fracx [expr $fracx - 1.0]
    }

    while { $fracx < -1.0 } {
	set fracx [expr $fracx + 1.0]
    }

    set fracy     [expr                     $orthy*$or2frac11 + $orthz*$or2frac12]

    while { $fracy > 1.0  } {
	set fracy [expr $fracy - 1.0]
    }

    while { $fracy < -1.0 } {
	set fracy [expr $fracy + 1.0]
    }

    set fracz     [expr                                         $orthz*$or2frac22] 

    while { $fracz > 1.0  } {
	set fracz [expr $fracz - 1.0]
    }

    while { $fracz < -1.0 } {
	set fracz [expr $fracz + 1.0]
    }

}

proc frac2orth { fracx fracy fracz orthxin orthyin orthzin  } {
    global XMLParse
    upvar $orthxin orthx
    upvar $orthyin orthy
    upvar $orthzin orthz

    set a     0.000000
    set b     0.000000
    set c     0.000000
    set alpha 0.000000
    set beta  0.000000
    set gamma 0.000000

    set i 1
    while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } {
	if { [info exists XMLParse([join "crank parameters crystal=$i native" __])] &&
	     $XMLParse([join "crank parameters crystal=$i native" __]) == "0"  } {
    
	    set a $XMLParse([join "crank parameters crystal=$i cell cell_a" __])
	    set b $XMLParse([join "crank parameters crystal=$i cell cell_b" __])
	    set c $XMLParse([join "crank parameters crystal=$i cell cell_c" __])
	    set alpha $XMLParse([join "crank parameters crystal=$i cell cell_alpha" __])
	    set beta  $XMLParse([join "crank parameters crystal=$i cell cell_beta" __])
	    set gamma $XMLParse([join "crank parameters crystal=$i cell cell_gamma" __])
	}
	incr i
    }

    if { !($a > 0.0 ) } {
	crank_error "crankutils.tcl::orth2frac unit cell edges not determined correctly"
    }

    set degreetorad 0.01745329251994329576924
    set cosalpha [expr cos($alpha*$degreetorad) ]
    set cosbeta  [expr cos($beta*$degreetorad) ]
    set sinbeta  [expr sin($beta*$degreetorad) ]
    set cosgamma [expr cos($gamma*$degreetorad) ]
    set singamma [expr sin($gamma*$degreetorad) ]
    set arg1     [expr ($cosbeta*$cosgamma - $cosalpha)/($sinbeta*$singamma)]
    set arg2     [expr sqrt(1.0000000 - $arg1*$arg1)]

    set frac2or00 $a
    set frac2or01 [expr $cosgamma*$b]
    set frac2or02 [expr $cosbeta*$c ]

    set frac2or11 [expr $singamma*$b]
    set frac2or12 [expr -$sinbeta*$c*$arg1]

    set frac2or22 [expr $sinbeta*$c*$arg2]


    set orthx     [expr $fracx*$frac2or00 + $fracy*$frac2or01 + $fracz*$frac2or02]

    set orthy     [expr                     $fracy*$frac2or11 + $fracz*$frac2or12]

    set orthz     [expr                                         $fracz*$frac2or22]
 
}

proc spacegroup_from_mtz { inputmtz name number } {

    upvar $name namein
    upvar $number numberin

# give the spacegroup name and number of an mtz file
    set sftools_script "read $inputmtz \nlist \nquit \ny"
    set command "sftools << \"$sftools_script\""
    catch {eval exec $command } output

    if { ![regexp {.*Space group name    *: *([A-Z])* *([0-9]*) *([0-9]*) *([0-9]*).*} $output full namein n1 n2 n3] } {
	puts "Search string not found"
    }

    set namein "$namein$n1$n2$n3"
    if { ![regexp {.*Space group number  *: *([0-9]*).* } $output full numberin] } {
	puts "Search string not found"
    }
}

proc make_one_mtz_file { mtzout } {

    # store only input columns into one mtz file

    global XMLParse    

    if { [string compare $XMLParse([join "crank parameters input_intensity" __]) "1"] == 0 } {
	set intensity 1
    } else {
	set intensity 0
    }

    # check to see if we just have one big mtz
    set onemtz 0
    set multimtz 0
    set scain 0

    set i 1
    while { [info exists XMLParse([join "crank input_files file=$i type" __]) ] } {
	set type $XMLParse([join "crank input_files file=$i type" __])
 	if { [string compare [string toupper $type] "MTZ"] == 0 } {
	    if { [info exists XMLParse([join "crank input_files file=$i name" __]) ] } {
		set inputmtz $XMLParse([join "crank input_files file=$i name" __])
		if { ![file exists $inputmtz] } {
		    crank_error "Could not find inputfile ($inputfile)"
		} else {
		    set mtzin $inputmtz
		}
		set onemtz 1
		set mtzn $i
	    } elseif { [info exists XMLParse([join "crank input_files file=$i crystal=1 data=1 name" __]) ] } {
		set multimtz 1
		set mtzn $i
	    } else {
		crank_error "Could not find single or multiple mtz files"
	    }
	} elseif { [string compare [string toupper $type] "SCA"] == 0 } {
	    if { [info exists XMLParse([join "crank input_files file=$i crystal=1 data=1 name" __]) ] } {
		set scain $i
	    }
	}
	incr i
    }

    if { ( !($onemtz) && !($multimtz) && !($scain) ) } {
	crank_error "No reflection input files given"
    }

    set mtz 0
    set hlin 0
    set script ""

    set i 1
    while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } {
	set j 1
	while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } { 
 	    incr mtz	 	    

	    if { $multimtz} {
		set mtzin "[file join $XMLParse([join "crank input_files file=$mtzn crystal=$i data=$j name" __])]"
	    } elseif { $scain != 0} {
		# call scalepack2mtz
		crank_error "No support for inputting scafiles at the moment"
	    }
	    
	    if { [string last ".mtz" $mtzin ] != [expr [string length $mtzin] - 4 ] } {
	       set sftoolsfile "read $mtzin\nmtz\n"
            } else {
	       set sftoolsfile "read $mtzin\n"
            }


# experimental data

	    if { [string compare $XMLParse([join "crank parameters crystal=$i data=$j anomalous" __]) "0"] == 0 } { 

		if { $intensity == 1 } {
		    if { $scain } {
			set in_i "I"
			set in_sigi "SIGI"
		    } else {
			set in_i $XMLParse([join "crank input_files file=$mtzn crystal=$i data=$j i" __])
			set in_sigi $XMLParse([join "crank input_files file=$mtzn crystal=$i data=$j sigi" __])
		    }
		    set sftoolsfile "$sftoolsfile set label col \"$in_i\" \n IN_X${i}_D${j}_I\n"
		    set sftoolsfile "$sftoolsfile set label col \"$in_sigi\" \n IN_X${i}_D${j}_SIGI\n"
		    set sftoolsfile "$sftoolsfile purge nodata\ny\nreduce ccp4\n"
		    set sftoolsfile "$sftoolsfile write temp.mtz col IN_X${i}_D${j}_I IN_X${i}_D${j}_SIGI\nquit\n"
		} else {
 		    set in_f $XMLParse([join "crank input_files file=$mtzn crystal=$i data=$j f" __])
		    set in_sigf $XMLParse([join "crank input_files file=$mtzn crystal=$i data=$j sigf" __])
		    set sftoolsfile "$sftoolsfile set label col \"$in_f\" \n IN_X${i}_D${j}_F\n"
		    set sftoolsfile "$sftoolsfile set label col \"$in_sigf\" \n IN_X${i}_D${j}_SIGF\n"
		    set sftoolsfile "$sftoolsfile purge nodata\ny\nreduce ccp4\n"
		    set sftoolsfile "$sftoolsfile write temp.mtz col IN_X${i}_D${j}_F IN_X${i}_D${j}_SIGF\nquit\n"
		}
	    } else {
		if { $intensity == 1 } {
		    if { $scain } {
			set in_ip "I+"
			set in_sigip "SIGI+"
			set in_im "I-"
			set in_sigim "SIGI-"
		    } else {
			set in_ip $XMLParse([join "crank input_files file=$mtzn crystal=$i data=$j i_plus" __])
			set in_sigip $XMLParse([join "crank input_files file=$mtzn crystal=$i data=$j sigi_plus" __])
			set in_im $XMLParse([join "crank input_files file=$mtzn crystal=$i data=$j i_minus" __])
			set in_sigim $XMLParse([join "crank input_files file=$mtzn crystal=$i data=$j sigi_minus" __])
		    }
		    set sftoolsfile "$sftoolsfile calc J col IN_X${i}_D${j}_I = col \"$in_ip\" col \"$in_im\" + 0.5 *\n"
		    set sftoolsfile "$sftoolsfile calc Q col IN_X${i}_D${j}_SIGI = col \"$in_sigip\" 2 ** col \"$in_sigim\" 2 ** +\n"
		    set sftoolsfile "$sftoolsfile calc Q col IN_X${i}_D${j}_SIGI = col IN_X${i}_D${j}_SIGI 0.5 **\n"
		    set sftoolsfile "$sftoolsfile calc Q col IN_X${i}_D${j}_SIGI = col IN_X${i}_D${j}_SIGI 0.5 *\n"
		    set sftoolsfile "$sftoolsfile select col IN_X${i}_D${j}_I = absent\n"
		    set sftoolsfile "$sftoolsfile calc J col IN_X${i}_D${j}_I = col \"$in_ip\"\n"
		    set sftoolsfile "$sftoolsfile calc Q col IN_X${i}_D${j}_SIGI = col \"$in_sigip\"\n"
		    set sftoolsfile "$sftoolsfile select all\n"
		    set sftoolsfile "$sftoolsfile select col IN_X${i}_D${j}_I = absent\n"
		    set sftoolsfile "$sftoolsfile calc J col IN_X${i}_D${j}_I = col  \"$in_im\"\n"
		    set sftoolsfile "$sftoolsfile calc Q col IN_X${i}_D${j}_SIGI = col \"$in_sigim\"\n"
		    set sftoolsfile "$sftoolsfile select all\n"
		    set sftoolsfile "$sftoolsfile set label col \"$in_ip\"\n"
		    set sftoolsfile "$sftoolsfile IN_X${i}_D${j}_I+\n"
		    set sftoolsfile "$sftoolsfile set label col \"$in_sigip\"\n"
		    set sftoolsfile "$sftoolsfile IN_X${i}_D${j}_SIGI+ \n"
		    set sftoolsfile "$sftoolsfile set label col \"$in_im\"\n"
		    set sftoolsfile "$sftoolsfile IN_X${i}_D${j}_I-\n"
		    set sftoolsfile "$sftoolsfile set label col \"$in_sigim\"\n"
		    set sftoolsfile "$sftoolsfile IN_X${i}_D${j}_SIGI-\n"
		    set sftoolsfile "$sftoolsfile purge nodata\ny\nreduce ccp4\n"
		    set sftoolsfile "$sftoolsfile write temp.mtz col IN_X${i}_D${j}_I+ IN_X${i}_D${j}_SIGI+ IN_X${i}_D${j}_I- IN_X${i}_D${j}_SIGI-\n"
		    set sftoolsfile "$sftoolsfile write temp2.mtz col IN_X${i}_D${j}_I IN_X${i}_D${j}_SIGI\nquit\n"
		} else {
 		    set in_fp $XMLParse([join "crank input_files file=$mtzn crystal=$i data=$j f_plus" __])
		    set in_sigfp $XMLParse([join "crank input_files file=$mtzn crystal=$i data=$j sigf_plus" __])
 		    set in_fm $XMLParse([join "crank input_files file=$mtzn crystal=$i data=$j f_minus" __])
		    set in_sigfm $XMLParse([join "crank input_files file=$mtzn crystal=$i data=$j sigf_minus" __])
		    set sftoolsfile "$sftoolsfile calc F col IN_X${i}_D${j}_F = col \"$in_fp\" col \"$in_fm\" + 0.5 *\n"
		    set sftoolsfile "$sftoolsfile calc Q col IN_X${i}_D${j}_SIGF = col \"$in_sigfp\" 2 ** col \"$in_sigfm\" 2 ** +\n"
		    set sftoolsfile "$sftoolsfile calc Q col IN_X${i}_D${j}_SIGF = col IN_X${i}_D${j}_SIGF 0.5 **\n"
		    set sftoolsfile "$sftoolsfile calc Q col IN_X${i}_D${j}_SIGF = col IN_X${i}_D${j}_SIGF 0.5 *\n"
		    set sftoolsfile "$sftoolsfile select col IN_X${i}_D${j}_F = absent\n"
		    set sftoolsfile "$sftoolsfile calc F col IN_X${i}_D${j}_F = col \"$in_fp\"\n"
		    set sftoolsfile "$sftoolsfile calc Q col IN_X${i}_D${j}_SIGF = col \"$in_sigfp\"\n"
		    set sftoolsfile "$sftoolsfile select all\n"
		    set sftoolsfile "$sftoolsfile select col IN_X${i}_D${j}_F = absent\n"
		    set sftoolsfile "$sftoolsfile calc F col IN_X${i}_D${j}_F = col  \"$in_fm\"\n"
		    set sftoolsfile "$sftoolsfile calc Q col IN_X${i}_D${j}_SIGF = col \"$in_sigfm\"\n"
		    set sftoolsfile "$sftoolsfile select all\n"
		    set sftoolsfile "$sftoolsfile set label col \"$in_fp\" \n IN_X${i}_D${j}_F+\n"
		    set sftoolsfile "$sftoolsfile set label col \"$in_sigfp\" \n IN_X${i}_D${j}_SIGF+\n"
		    set sftoolsfile "$sftoolsfile set label col \"$in_fm\" \n IN_X${i}_D${j}_F-\n"
		    set sftoolsfile "$sftoolsfile set label col \"$in_sigfm\" \n IN_X${i}_D${j}_SIGF-\n"
		    set sftoolsfile "$sftoolsfile purge nodata\ny\nreduce ccp4\n"
		    set sftoolsfile "$sftoolsfile write temp.mtz col IN_X${i}_D${j}_F+ IN_X${i}_D${j}_SIGF+ IN_X${i}_D${j}_F- IN_X${i}_D${j}_SIGF-\n"
 		    set sftoolsfile "$sftoolsfile write temp2.mtz col IN_X${i}_D${j}_F IN_X${i}_D${j}_SIGF\nquit\n"
		}
	    }

# phase data, if any ***NSP
	    if { [info exists XMLParse([join "crank input_files file=$mtzn crystal=$i data=$j hl_columns hla" __]) ] } {
		if { $hlin } {
		    crank_error "Only one set of Hendrickson-Lattmann coefficients can be defined at the moment"
		} 
		set hlin 1
		set in_hla $XMLParse([join "crank input_files file=$mtzn crystal=$i data=$j hl_columns hla" __])
		set in_hlb $XMLParse([join "crank input_files file=$mtzn crystal=$i data=$j hl_columns hlb" __])
		set in_hlc $XMLParse([join "crank input_files file=$mtzn crystal=$i data=$j hl_columns hlc" __])
		set in_hld $XMLParse([join "crank input_files file=$mtzn crystal=$i data=$j hl_columns hld" __])
		set sftoolsphase "read $mtzin\n set label col $in_hla \n IN_HLA\n"
		set sftoolsphase "$sftoolsphase set label col $in_hlb \n IN_HLB\n"
		set sftoolsphase "$sftoolsphase set label col $in_hlc \n IN_HLC\n"
		set sftoolsphase "$sftoolsphase set label col $in_hld \n IN_HLD\n"
		set sftoolsphase "$sftoolsphase write hl.mtz col IN_HLA IN_HLB IN_HLC IN_HLD\nquit\n"
		set command "sftools << \"$sftoolsphase\""
#		puts $command
		catch {eval exec $command } output
#		puts $output
		set script "$script read hl.mtz\n"
	    }

	    set sfile [open "sftools.script" w]
	    puts $sfile $sftoolsfile
	    close $sfile
	    set command "sftools < sftools.script "
	    catch {eval exec $command } output 
#     	    puts $output
	    if { [file exists sftools.script] } {
		file delete sftools.script
	    } else {
		crank_error "Problem with reading input mtz file"
	    }

	    if { [file exists hl.mtz] } {
		set command "sftools << \"read temp.mtz\nread temp2.mtz\nread hl.mtz\npurge nodata\ny\nwrite $mtz.mtz\nquit\n\" "
		catch {eval exec $command } output 
		file delete hl.mtz
	    } else {
		set command "sftools << \"read temp.mtz\nread temp2.mtz\npurge nodata\ny\nwrite $mtz.mtz\nquit\n\" "
		catch {eval exec $command } output 
	    }
#	    puts $output
	    file delete temp.mtz
	    if { [file exists temp2.mtz] } {
		file delete temp2.mtz
	    }

	    set script "$script read $mtz.mtz\n"
	    incr j
	}
	incr i
    }

    # check to see if user wants to specify an R-free column
    set inrfree 0
    for { set step 1 } { [info exists XMLParse(crank__soap__run__step=$step)] } { incr step } {
 	set program [string tolower $XMLParse([join "crank soap run step=$step name" __])]
	if { $program == "prep" } {
	    if { [info exists XMLParse([join "crank soap run step=$step prep input_rfree" __])] } {
		if { $XMLParse([join "crank soap run step=$step prep input_rfree" __]) &&
		     [info exists XMLParse([join "crank soap run step=$step prep rfree_label" __])] } {
 		    set inrfree 1
		}
	    }
	    if { $inrfree } {
		set out "IN_FREER"
		set freercol $XMLParse([join "crank soap run step=$step prep rfree_label" __])
		set rscript "read $inputmtz \n set label col $freercol \n $out \n"
		set rscript "$rscript write rfree.mtz col $out \n quit \n"
		set command "sftools << \"$rscript\""
		catch {eval exec $command } output
#		puts $output
		set script "$script read rfree.mtz\n"
	    }
	    break
	}
    }

    set script "$script write $mtzout\nquit\n"
    set command "sftools << \"$script\""
    catch {eval exec $command } output 
#    puts $output

    for { set i 1 } { $i <= $mtz } { incr i } {
	file delete $i.mtz
    }

    if { [file exists rfree.mtz] } {
	file delete rfree.mtz
    }
}

proc mtz2hkl { mtz2hklcommand inputmtz output d sigd intensity } {

    if { $intensity == "1" } {

	set mtz_script "XTAL xtal1\n DNAME data1 \n COLUmn LABIN I=$d SI=$sigd\nOUTH\nOUTPut $output\nEND\n"

	set command "$mtz2hklcommand HKLIN $inputmtz << \"$mtz_script\""
	catch {eval exec $command } output
	#    puts $output
    } else {
	set mtz_script "XTAL xtal1\n DNAME data1 \n COLUmn LABIN F=$d SF+=$sigd\nOUTH\nOUTPut $output\nEND\n"

	set command "$mtz2hklcommand HKLIN $inputmtz << \"$mtz_script\""
	catch {eval exec $command } output
	#    puts $output
    }
}

proc mtz2hkl_fa { inputmtz output fa sigfa alpha } {

    set args   "HKLIN $inputmtz HKLOUT $output"
    set script "LABIN FP=$fa SIGFP=$sigfa IDUM1=$alpha\n OUTPUT USER '(3I4,2F8.2,I4)'\n"

    set command "mtz2various $args << \"$script\""
    #puts $command
    catch {eval exec $command } output
    #puts $output
}

proc mtz2phs { inputmtz output f fom alpha sigf } {

    set args   "HKLIN $inputmtz HKLOUT $output"
    set script "LABIN DUM1=$f DUM2=$fom DUM3=$alpha DUM4=$sigf\n OUTPUT USER '(3I4,1F9.2,1F8.4,1F8.1,1F8.2)'\n"

    set command "mtz2various $args << \"$script\""
#    puts $command
    catch {eval exec $command } output 
#    puts $output
}

proc spacegroup_enantiomorph { number hand } {

    upvar $hand enant

#  return enantiomorph space group

    set enant $number

    if { $number       == 76 }  {        
	# P41
	set enant 78
    } elseif { $number == 78 }  {        
	# P43
	set enant 76
    } elseif { $number == 91 }  { 
	# P4122
	set enant 95
    } elseif { $number == 95 }  {  
	# P4322
	set enant 91
    } elseif { $number == 92 }  {
	# P41212
	set enant 96
    } elseif { $number == 96 }  {
	# P43212
	set enant 92
    } elseif { $number == 144 } {
	# P31
	set enant 145 
    } elseif { $number == 145 } {
	# P32
	set enant 144 
    } elseif { $number == 151 } {
	# P3112
	set enant 153 
    } elseif { $number == 153 } {
	# P3212
	set enant 151 
    } elseif { $number == 152 } {
	# P3121
	set enant 154 
    } elseif { $number == 154 } {
	# P3221
	set enant 152 
    } elseif { $number == 169 } {
	# P61
	set enant 170 
    } elseif { $number == 170 } { 
        # P65
	set enant 169 
    } elseif { $number == 171 } {
	# P62
	set enant 172 
    } elseif { $number == 172 } {
	# P64
	set enant 171 
    } elseif { $number == 178 } {
	# P6122
	set enant 179 
    } elseif { $number == 179 } {
	# P6522
	set enant 178 
    } elseif { $number == 180 } {
	# P6222
	set enant 181 
    } elseif { $number == 181 } {
	# P6422
	set enant 180 
    } elseif { $number == 212 } { 
	# P4332
	set enant 213 
    } elseif { $number == 213 } {
	 # P4132
	set enant  212 
    }
}

proc difference_maps { mtz_in f phi thres log pdb verbose } {
    global env

    # write a pdb file with peaks above a threshold
    set script  "xyzlim asu\nlabin F1=$f PHI=$phi\nend"
    set command "fft HKLIN $mtz_in MAPOUT diff.map << \"$script\""
    catch {eval exec $command} output
    if { $verbose } {
	puts $log $output
    }
    
    if { [file exists diff.map] } {
	set script  "numpeaks 50\nthreshold rms 2 NEGATIVES\noutput brookhaven\nRESI DUM \nATNA DUM \nend"
	set command "peakmax MAPIN diff.map XYZOUT temp.pdb << \"$script\""
	catch {eval exec $command} output
	if { $verbose } {
	    puts $log $output
	}
 	file delete diff.map
    }

    if { [file exists temp.pdb] } {
	set input [open temp.pdb r]
	set output [open $pdb w]
    
	if { [get_cryst_card_from_pdb $input line] } {
	    if { [info exists line] } {
		puts $output $line
	    }
	}

	set abovethres 0
	set indata [split [read $input] "\n"]
	foreach line  $indata {
 	    if { [read_pdb_atom_line $line number atom x y z occ bfac] } {
		if { $occ > $thres } {
		    incr abovethres
		    write_pdb_atom_line $output $number $atom $abovethres $x $y $z $occ $bfac
		} 
	    }
	}
	puts $output "END"
	close $output
	close $input

	puts $log "\nDifference map evaluation:"
	puts $log "$abovethres peak(s) found above $thres RMS\n"
	close $log
	file delete temp.pdb
    return $abovethres
    }	
    return 0
}

proc find_atoms_from_map_and_refine { prog tag run step thres crankplugins inccp4 refine verbose } {
    global env
    global XMLParse
	#cd $step-$prog

    set refined 0
	set gradlog [open "difference-logfile_$run" w]
    set heavy_suffix $run

    # find atoms in difference maps assuming the mtz files have been created already by program $prog
    if { [string compare $prog "refmac" ] == 0 } {
      set found [difference_maps refmac.out${run}.mtz "DELFAN" "PHDELAN" $thres $gradlog "gradient_${run}.pdb" $verbose]
    } elseif { [string compare $prog "bp3" ] == 0 } {
	  set found [difference_maps crank.out.${tag}-${run}.mtz "${tag}_FDIFF" "${tag}_PDIFF" $thres $gradlog "gradient_${run}.pdb" $verbose]
      set heavy_suffix "${run}-1"
      if { ![file exists heavy${heavy_suffix}.pdb] } {
        set heavy_suffix "${run}-2"
      }
    } else {
      crank_error "crankutils.tcl::Unexpected internal error: wrong program $prog"
	}

    # if new atoms were found then add them and refine the new model
	if { [add_remove_atoms heavy${heavy_suffix}.pdb gradient_${run}.pdb update_${run}.pdb] || $refine>1 } {
	  if { $refine && [file exists update_$run.pdb] } {
        set run_prev $run
		incr run
        if { [string compare $prog "refmac" ] == 0 } {
		  runcommand [concat tclsh [file join $crankplugins refmac xml2refmacscript.tcl] "update_${run_prev}.pdb" $run 0 0 >& $prog-command${run}.com ] $verbose
		  runcommand [concat tclsh [file join $crankplugins refmac xml2refmacscript.tcl] "update_${run_prev}.pdb" $run 0 1 >& $prog-command${run}.tcl ] $verbose
        } else {
		  runcommand [concat tclsh [file join $crankplugins bp3 xml2bp3script.tcl] $inccp4 "update_${run_prev}.pdb" $run 0 0 >& $prog-command${run}.com ] $verbose
		  runcommand [concat tclsh [file join $crankplugins bp3 xml2bp3script.tcl] $inccp4 "update_${run_prev}.pdb" $run 0 1 >& $prog-command${run}.tcl ] $verbose
        }
		runcommand [concat tclsh $prog-command${run}.tcl ] 1
        set refined 1

		if { [file exists $prog-logfile$run] } {
		  set log [open "$prog-logfile$run" r]
		  set output [read $log]
		  puts $output

		  # Copy logfile to main log directory
          if {$step} {
		    file copy $prog-logfile$run [file join .. log $step-$prog-logfile$run]
          }
		}
	  }
	}
	return $refined
}

proc arpwarp_asu { number xyz } {

#  return arpwarp asymmetric unit

    set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 1.00000"

    if { $number       == 1      } {
	# P1
	set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 1.00000"  
    } elseif { $number == 3      } { 
	# P2
	set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 0.50000"  
    } elseif { $number == 4      } { 
	# P21
	set xyzlim "0.00000 1.00000 0.00000 0.50000 0.00000 1.00000"  
    } elseif { $number == 5      } { 
	# C2
	set xyzlim "0.00000 0.50000 0.00000 1.00000 0.00000 0.50000"  
    } elseif { $number == 16     } { 
	# P222
	set xyzlim "0.00000 0.50000 0.00000 1.00000 0.00000 0.50000"  
    } elseif { $number == 17     } { 
	# P2221
	set xyzlim "0.00000 0.50000 0.00000 1.00000 0.00000 0.50000"  
    } elseif { $number == 18     } { 
	# P21212
	set xyzlim "0.00000 1.00000 0.00000 0.25000 0.00000 1.00000"  
    } elseif { $number == 19     } { 
	# P212121
	set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 0.25000"  
    } elseif { $number == 20     } {
	# C2221
	set xyzlim "0.00000 0.50000 0.00000 0.50000 0.00000 0.50000"  
    } elseif { $number == 21     } { 
	# C222
	set xyzlim "0.00000 0.25000 0.00000 0.50000 0.00000 1.00000"  
    } elseif { $number == 22     } {
	# F222
	set xyzlim "0.00000 1.00000 0.00000 0.25000 0.00000 0.25000"  
    } elseif { $number == 23     } { 
	# I222
	set xyzlim "0.00000 0.50000 0.00000 0.50000 0.00000 0.50000"  
    } elseif { $number == 24     } { 
	# I212121
	set xyzlim "0.00000 0.50000 0.00000 0.50000 0.00000 0.50000"  
    } elseif { $number == 75     } { 
	# P4
	set xyzlim "0.00000 0.50000 0.00000 0.50000 0.00000 1.00000"  
    } elseif { $number == 76     } { 
	# P41
	set xyzlim "0.00000 0.50000 0.00000 0.50000 0.00000 1.00000"  
    } elseif { $number == 77     } { 
	# P42
	set xyzlim "0.00000 0.50000 0.00000 0.50000 0.00000 1.00000"  
    } elseif { $number == 78     } { 
	# P43
	set xyzlim "0.00000 0.50000 0.00000 0.50000 0.00000 1.00000"  
    } elseif { $number == 79     } { 
	# I4
	set xyzlim "0.00000 0.50000 0.00000 0.50000 0.00000 0.50000"  
    } elseif { $number == 80     } { 
	# I41
	set xyzlim "0.00000 1.00000 0.00000 0.50000 0.00000 0.25000"  
    } elseif { $number == 89     } { 
	# P422
	set xyzlim "0.00000 0.50000 0.00000 0.50000 0.00000 0.50000"  
    } elseif { $number == 90     } {
	# P4212
	set xyzlim "0.00000 0.50000 0.00000 0.50000 0.00000 0.50000"  
    } elseif { $number == 91     } { 
	# P4122
	set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 0.12500"  
    } elseif { $number == 92     } { 
	# P41212
	set xyzlim "0.00000 0.50000 0.00000 0.50000 0.00000 0.50000"  
    } elseif { $number == 93     } { 
	# P4222
	set xyzlim "0.00000 1.00000 0.00000 0.50000 0.00000 0.25000"  
    } elseif { $number == 94     } { 
	# P42212
	set xyzlim "0.00000 0.50000 0.00000 0.50000 0.00000 0.50000"  
    } elseif { $number == 95     } { 
	# P4322
	set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 0.12500"  
    } elseif { $number == 96     } { 
	# P43212
	set xyzlim "0.00000 0.50000 0.00000 0.50000 0.00000 0.50000"  
    } elseif { $number == 97     } { 
	# I422
	set xyzlim "0.00000 0.50000 0.00000 0.50000 0.00000 0.25000"  
    } elseif { $number == 98     } { 
	# I4122
	set xyzlim "0.00000 1.00000 0.00000 0.25000 0.00000 0.25000"  
    } elseif { $number == 143    } { 
	# P3
	set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 1.00000"  
    } elseif { $number == 144    } {
	# P31
	set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 0.33334"  
    } elseif { $number == 145    } { 
	# P32
	set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 0.33334"  
    } elseif { $number == 146    } {
	# R3
	set xyzlim "0.00000 0.33334 0.00000 0.33334 0.00000 1.00000"  
    } elseif { $number == 149    } {
	# P312
	set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 0.50000"  
    } elseif { $number == 150    } {
	# P321
	set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 0.50000"  
    } elseif { $number == 151    } { 
	# P3112
	set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 0.16667"  
    } elseif { $number == 152    } { 
	# P312
	set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 0.16667"  
    } elseif { $number == 153    } { 
	# P3212
	set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 0.16667"  
    } elseif { $number == 154    } { 
	# P3221
	set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 0.16667"  
    } elseif { $number == 155    } { 
	# R32
	set xyzlim "0.00000 0.33334 0.00000 0.33334 0.00000 0.50000"  
    } elseif { $number == 168    } {
	# P6
	set xyzlim "0.00000 1.00000 0.00000 0.50000 0.00000 1.00000"  
    } elseif { $number == 169    } { 
	# P61
	set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 0.16667"  
    } elseif { $number == 170    } { 
	# P65
	set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 0.16667"  
    } elseif { $number == 171    } { 
	# P62
	set xyzlim "0.00000 1.00000 0.00000 0.50000 0.00000 0.33334"  
    } elseif { $number == 172    } { 
	# P64
	set xyzlim "0.00000 1.00000 0.00000 0.50000 0.00000 0.33334"  
    } elseif { $number == 173    } { 
	# P63
	set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 0.50000"  
    } elseif { $number == 177    } { 
	# P622
	set xyzlim "0.00000 1.00000 0.00000 0.50000 0.00000 0.50000"  
    } elseif { $number == 178    } { 
	# P6122
	set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 0.08334"  
    } elseif { $number == 179    } { 
	# P6522
	set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 0.08334"  
    } elseif { $number == 180    } { 
	# P6222
	set xyzlim "0.00000 1.00000 0.00000 0.50000 0.00000 0.16667"  
    } elseif { $number == 181    } { 
	# P6422
	set xyzlim "0.00000 1.00000 0.00000 0.50000 0.00000 0.16667"  
    } elseif { $number == 182    } { 
	# P6322
	set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 0.25000"  
    } elseif { $number == 195    } { 
	# P23
	set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 0.50000"  
    } elseif { $number == 196    } { 
	# F23
	set xyzlim "0.00000 1.00000 0.00000 0.50000 0.00000 0.50000"  
    } elseif { $number == 197    } { 
	# I23
	set xyzlim "0.00000 0.50000 0.00000 0.50000 0.00000 1.00000"  
    } elseif { $number == 198    } { 
	# P213
	set xyzlim "0.00000 0.50000 0.00000 0.50000 0.00000 1.00000"  
    } elseif { $number == 199    } { 
	# I213
	set xyzlim "0.00000 0.50000 0.00000 0.50000 0.00000 1.00000"  
    } elseif { $number == 207    } { 
	# P432
	set xyzlim "0.00000 0.50000 0.00000 0.50000 0.00000 1.00000"  
    } elseif { $number == 208    } { 
	# P4232
	set xyzlim "0.00000 1.00000 0.00000 0.50000 0.00000 0.50000"  
    } elseif { $number == 209    } { 
	# F432
	set xyzlim "0.00000 0.50000 0.00000 0.50000 0.00000 0.50000"  
    } elseif { $number == 210    } { 
	# F4132
	set xyzlim "0.00000 0.50000 0.00000 0.75000 0.00000 0.66667"  
    } elseif { $number == 211    } { 
	# I432
	set xyzlim "0.00000 0.25000 0.00000 0.75000 0.00000 0.66667"  
    } elseif { $number == 212    } { 
	# P4332
	set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 1.00000"  
    } elseif { $number == 213    } { 
	# P4132
	set xyzlim "0.00000 1.00000 0.00000 1.00000 0.00000 1.00000"  
    } elseif { $number == 214    }  { 
	# I4132
	set xyzlim "0.00000 0.66667 0.00000 0.75000 0.00000 1.00000"  
    }

    uplevel 1 [list set $xyz $xyzlim]
}

# do some checks on the data

proc check_data { } {
    global XMLParse

    # at least one anomalous data set or two data sets

    set substructure 0
    set num_datasets 0
    set num_anom_dataset 0

    set i 1
    while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } {
	if { [info exists XMLParse([join "crank parameters crystal=$i substructure atom_name" __])] } {
	    incr substructure
	}
        set j 1
        while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } {
	    incr num_datasets 
	    if { $XMLParse([join "crank parameters crystal=$i data=$j anomalous" __]) == 1 } { 
		incr num_anom_dataset
	    }
	    incr j
        }
        incr i
    }

    set i 1
    set model 0

    while { [info exists XMLParse([join "crank input_files file=$i type" __])] } {
	if { $XMLParse([join "crank input_files file=$i type" __]) == "PDB" } {
	    incr model
	}
	incr i
    }

    if { ($substructure == 0) && ($model == 0) } {
	crank_error "No substructure or model defined"
    }

    if { ($num_datasets == 0) } {
	crank_error "No dataset defined"
    }

    if { ($num_anom_dataset == 0) && ($num_datasets == 1) && ($model == 0) } {
	crank_error "Only one non-anomalous dataset defined and no model is given"
    }
}

#
# Check if all the necessary programs are present, and that
# we have at least a good known working version
#

proc all_necessary_programs { } {
    global XMLParse

    set need_ccp4 1
    #
    # CCP4 version at least 6.0?
    # 
    if { $need_ccp4 } {
	# First, create and run a CCP4 command line.  
	# The "-i flag gives version information"
	set mtz_command "scaleit -i"
	set mtz_script "\nEND\n"
	set command "$mtz_command << \"$mtz_script\""
	catch {eval exec $command } output 
	set err [lindex $::errorCode 0]

	# Check to see if the executable is found
	if { [string compare $err "POSIX" ] == 0 } {
 	    crank_error "crank::crankutils.tcl::Error ccp4 executables not found"
	}

	# Check to see if we have the correct version
	if { [regexp {patch level\s+([0-9.]*)} $output match version1]} {
	    set version [string range $version1 0 2]
	    if { $version < 5.9 } {
		crank_error "crank::crankutils.tcl::Error version CCP4 is not greater than 5.9, current version is $version"
	    }
	    puts "CCP4 version is $version"
	} else {
	    crank_error "crank::crankutils.tcl::Error finding version string from scaleit exectuable: $output"
	}
    }
}

proc check_new_refmac {} {

    # create and run refmac5D command line
    set refmac_command "refmac5 -i"
    set refmac_script "\nEND\n"
    set command "$refmac_command << \"$refmac_script\""
    catch {eval exec $command } output 
    set err [lindex $::errorCode 0]
	
    # Check to see if the executable is found
    if { [string compare $err "POSIX"] == 0 } {
	crank_error "crank::crankutils.tcl::Error Please download the refmac5 version 5.5 or greater from http://www.ysbl.york.ac.uk/~garib/refmac/latest_refmac.html, name the binary refmac5 and make sure it is in your path!"
    }

    # Check to see if we have the correct version
    if { [regexp {.*refmac5; version *([0-9.]*)} $output match version1]} {
	set version [string range $version1 0 2]
	if { $version >= 5.5 } {
	    puts "Found refmac5 version $version\n"
	} else { 
	    crank_error "crank::crankutils.tcl::Error Refmac version is not greater than or equal to 5.5, current version is $version.\n  Please download the correct version from http://www.ysbl.york.ac.uk/~garib/refmac/latest_refmac.html, name the binary refmac5 and make sure it is in your path!"
	}
    } else {
	crank_error "crank::crankutils.tcl::Error finding version string from refmac5 exectuable"
    }
}

proc crank_plugin_begin { step type program crankplugins xmlversion} {
	
    if { [file exists [file join $crankplugins .. VERSION] ] } {
	set version [open [file join $crankplugins .. VERSION] r]
	set data [read $version]
	regsub -all {\s+} $data "" data
	if { [string compare $xmlversion $data] != 0 } {
	    crank_error "crank:crankutils.tcl::plugin and crank XML version do not match"
	}
    } else {
	crank_error "crank:crankutils.tcl:: VERSION file could not be found"
    }

    puts "<B><FONT COLOR=\"\#FF0000\"><!--SUMMARY_BEGIN-->\n"
    puts "Running step \# $step: $type"
    puts "Program used: $program\n"
    puts "<!--SUMMARY_END--></FONT></B>\n"
}

proc crank_plugin_end { step time } {

    puts "<B><FONT COLOR=\"\#FF0000\"><!--SUMMARY_BEGIN-->\n"
    puts "End of step \# $step"
    if {$time > 60.0} {
	set minutes [expr int([expr $time/60.0])]
	set seconds [expr round(fmod($time,60.0))]
    } else {
	set minutes "0"
	set seconds [expr round($time)]
    }
    if { $seconds < 10.0 } {
	set seconds "0$seconds"
    }

    puts "Times: Elapsed: $minutes:$seconds\n"
    puts "<\!--SUMMARY_END--></FONT></B>\n"
}

proc crank_ccp4_plugin_end { step program time } {

    puts "<B><FONT COLOR=\"\#330044\"><!--SUMMARY_BEGIN-->\n"
    if { $step > 0 } {
	puts "End of step \# $step\n"
    }
    puts "$program: Normal termination"
    if {$time > 60.0} {
	set minutes [expr int([expr $time/60.0])]
	set seconds [expr round(fmod($time,60.0))]
    } else {
	set minutes "0"
	set seconds [expr round($time)]
    }
    if { $seconds < 10.0 } {
	set seconds "0$seconds"
    }

    puts [format "Times: User: %9.1fs System:    0.0s Elapsed: %5d:$seconds\n" $time $minutes ]
    puts "<!--SUMMARY_END--></FONT></B>\n"
}

proc crank_ccp4_banner { program version } {

    puts "<B><FONT COLOR=\"#FF0000\"><!--SUMMARY_BEGIN-->"
    puts "<pre>\n"
    puts " ###############################################################"
    puts " ###############################################################"
    puts " ###############################################################"
    puts [format " ### CCP4 %3s: %-17s  %-18s: %-8s##"  "6.1" $program "version $version" " " ]
    puts " ###############################################################"
    set date [clock format [clock seconds] -format %e/%m/%Y]
    set time [clock format [clock seconds] -format %H:%M:%S]
    puts " User: crank  Run date: $date Run time: $time" 
    puts "<!--SUMMARY_END--></FONT></B>\n\n"
}

proc crank_error { message } {

    puts "<B><FONT COLOR=\"\#FF0000\"><!--SUMMARY_BEGIN-->"
    puts "<hr>"
    puts "\ncrank->Error:$message\n"
#    puts "Exitting."
    puts "<!--SUMMARY_END--></FONT></B>\n"
    error $message
    exit 1
}

#
# runcommand - Execute an outside program
#
# Run a command using an "exec" wrapped with "catch".  If the external
# command fails, catch the error and return a string describing the
# error message, specifically:
#
# SUCCESS     - Command succeeded
# CHILDKILLED - Child process was killed
# CHILDSTATUS - Child exited with a non-zero error status
# CHILDSUSP   - Child was suspended
# POSIX       - One of the kernel calls to launch the command failed
#                (e.g. file could not be found)
#
# To output more debugging information, such as the output of the 
# command, set debug 1
#
#
proc runcommand { command verbose } {

    global tcl_platform
    set os $tcl_platform(os)

    if { $verbose } {
	puts "--------------------------------------------------------------------------------"
	puts "Crank is now running the program:"
	puts "$command"
    }

    set t0 [clock clicks -millisec ]

    # Run the command
    set rcstatus [catch {eval exec $command } output ]

    if { [string last "tclsh shelx" $command] >= 0 } { 
	set shelx 1
    } else {
	set shelx 0
    }

    if { [string last "tclsh molrep-command.tcl" $command] >= 0 } { 
	set molrep_run 1
    } else {
	set molrep_run 0
    }

    if { [string last "tclsh brics-command.tcl" $command] >= 0 } { 
	set brics_run 1
    } else {
	set brics_run 0
    }

    if { $rcstatus == 0 } {
	# The command succeeded, and wrote nothing to stderr.
	# $output contains what it wrote to stdout, unless you
	# redirected it.
	# puts $output
	set returnval "SUCCESS"	
    } elseif { ( ($rcstatus == 1) && ($shelx == 1 ) ) } {
	# shelx run in tcl gives a status of 1 when the job is successful!
 	# puts $output
	set returnval "SUCCESS"
    } elseif { ( ($molrep_run == 1) || ($brics_run == 1) )  } {
	# shelx run in tcl gives a status of 1 when the job is successful!
 	# puts $output
	set returnval "SUCCESS"
    } elseif { [string equal $::errorCode NONE] } {
	# The command exited with a normal status, but wrote something
	# to stderr, which is included in $output.
 	# puts $output
	set returnval "SUCCESS"

    } else {

#	puts "Error encountered when running:"
#	puts "command:($command)"
#	puts "crank::runcommand::ERROR CODE($::errorCode)"
	switch -exact -- [lindex $::errorCode 0] {

	    CHILDKILLED {
                # A child process, whose process ID was $pid,
                # died on a signal named $sigName.  A human-
                # readable message appears in $msg.
                foreach { - pid sigName msg } $::errorCode break
#				puts "pid=($pid)"
#				puts "sigName=($sigName)"
#				puts "msg=($msg)"
#				puts "crank::runcommand::STATUS:CHILDKILLED - child killed"
				set returnval "CHILDKILLED"

            }

            CHILDSTATUS {
                # A child process, whose process ID was $pid,
                # exited with a non-zero exit status, $code.
                foreach { - pid code } $::errorCode break
#		puts "crank::runcommand::STATUS:CHILDSTATUS - child exited with non-zero exit status"
		set returnval "CHILDSTATUS"

	    }

            CHILDSUSP {
                # A child process, whose process ID was $pid,
                # has been suspended because of a signal named
                # $sigName.  A human-readable description of the
                # signal appears in $msg.
                foreach { - pid sigName msg } $::errorCode break
#		puts "crank::runcommand::STATUS:CHILDSUSP - child was suspended"
		set returnval "CHILDSUSP"
            }


            POSIX {
		# One of the kernel calls to launch the command
		# failed.  The error code is in $errName, and a
		# human-readable message is in $msg.
		foreach { - errName msg } $::errorCode break
		set returnval "POSIX"
	    }
	}
 	puts $output
	crank_error "running: $command\nmessage:\n $output"
    }

    if { [string compare $returnval SUCCESS] != 0 } {
	crank_error "running: $command\n message:\n $output"
    }

    if { $verbose } {

	if { [string first "tclsh " $command] != -1 } {
	    set command_just_run [lindex $command 1]
	} else {
	    set command_just_run "[lindex $command 0] [lindex $command 1]"
	}

	puts "crank::command ($command_just_run) run time:[expr ([clock clicks -millisec ]-$t0)/1000.] sec"
	puts "--------------------------------------------------------------------------------\n"
    }

    return $returnval
}

proc debug_print_xml_database { } {
    upvar XMLParse xml
	
    set allvars [array get xml]
    for { set i 0 } { $i < [llength $allvars] } { incr i } {
	puts -nonewline "[lindex $allvars $i]\t"
	incr i
	puts "[lindex $allvars $i] "
    }
}

proc XMLElementStartHandler { name attlist } {
    global xmldata
    global XMLParse
    global XMLWork

    set section_id [GetXmlAttributeValue $attlist "id"]

    if { $section_id != "" } {
	set XMLWork(section_id) $section_id
	set XMLWork(section_id_depth) $XMLWork(section_depth)
    } 

    # Add this name to the current "full" name
    set XMLWork(section_name) $name
    if { $section_id == "" } {
	lappend XMLWork(section_full_name) $name
    } else {
	lappend XMLWork(section_full_name) "${name}=${section_id}"
    }
    set XMLWork(section_cat_name) [join $XMLWork(section_full_name) "__"]
    incr XMLWork(section_depth)
}

proc XMLElementEndHandler { name } {
    global xmldata
    global XMLParse
    global XMLWork

    set XMLWork(section_full_name) [lreplace $XMLWork(section_full_name) \
					[expr [llength $XMLWork(section_full_name)] - 1] \
					[expr [llength $XMLWork(section_full_name)] - 1]]
    incr XMLWork(section_depth) -1

    if { $XMLWork(section_depth) < $XMLWork(section_id_depth) } {
	set XMLWork(section_id) ""
	set XMLWork(section_id_depth) 0
    }
}

proc XMLCharacterHandler { data args } {
    global xmldata
    global XMLParse
    global XMLWork

    set data [string trim $data]

    if { $data != "" } {
	set fullvarname "$XMLWork(section_cat_name)"
	set XMLParse($fullvarname) $data
    }
}

proc XMLParsefile { xmlfile } {
    # Global used by the XML parser
    global xmldata
	
    # Data structure to hold actual data
    global XMLParse 
	
    # Working data structure to hold temporary work data
    global XMLWork

    set XMLWork(section_depth) 0
    set XMLWork(section_id) ""
    set XMLWork(section_id_depth) 0

    # Initialise and configure the XML parser
    set parser 0
    set parser [ xml::parser ]
    $parser configure -elementstartcommand XMLElementStartHandler
    $parser configure -elementendcommand XMLElementEndHandler
    $parser configure -characterdatacommand XMLCharacterHandler
    $parser configure -ignorewhitespace true

    # Read and parse the specified file
    if { [ReadFile $xmlfile xmltext] } {
	$parser parse $xmltext
	set xmldata(XML_FILE) $xmlfile
	set xmldata(XML_LOADED) 1
    } else {
	# Couldn't load the data
	set xmldata(XML_LOADED) 0
    }
}

#
# Check to see if $atomname is present in the file
# $CLIBD/atomsf.lib
#
proc GoodAtomName { atomname } {
    global env
	
    set atomname [string tolower $atomname]
    set atomsf "[file join $env(CLIBD) atomsf.lib]"

    set file_id [open $atomsf r]

    set done 0
    while { !$done } {
	gets $file_id line
	if { ! [regexp {AD.*} $line]} {
	    set done 1
	}
    }
	
    lappend atomlist $line
    gets $file_id line
    gets $file_id line
    gets $file_id line
    gets $file_id line

    while { [gets $file_id line] >= 0 } {
	lappend atomlist $line
	gets $file_id line
	gets $file_id line
	gets $file_id line
	gets $file_id line
    }

    set match 0
    for { set i 0 } { $i < [llength $atomlist] } { incr i } {
	if { [regexp {([A-Za-z+0-9-]*) } [lindex $atomlist $i] full atom] } {
	    set atom [string tolower $atom]
	    if { [string compare $atomname $atom] == 0 } {
		set match 1
		break
	    }
	}
    }
	
    if { $match == 1 } {
	return 1
    } else {
	return 0
    }
}

proc doplugins_nocheck { crankplugins } {
    global PluginList
    global XMLParse

    # Make a list of all the index.xml files in each directory 
    # in crank/plugins/*.
    set all_pluginxml [glob -nocomplain [file join $crankplugins * *_index.xml]]
	
    #puts "all_pluginxml($all_pluginxml)"

    # Loop over all plugin index.xml files
    foreach pluginxml $all_pluginxml {
	#puts "pluginxml=($pluginxml)"
	
	# Parse the XML from this file into the global datastructure
	XMLParsefile $pluginxml
	
	# Add the name of the plugin to the global plugin list
	set fileid [open "$pluginxml" r]
	while { [gets $fileid line] >= 0 } {		
	    
	    if { [regexp { *<name>([A-Za-z1-9._]*)</name>} $line all match ] } {
		lappend PluginList $match
	    }
	}
	close $fileid
    }
}

proc compress { file {outfile ""} } {
    set command "gzip $file"
    catch {eval exec $command} output
#    puts $output
#    package require zlib
    # Gunzip the file
    # See http://www.gzip.org/zlib/rfc-gzip.html for gzip file description
    
#    set in [open $file r]
#    fconfigure $in -translation binary -buffering none

#    set id [read $in 2]
#    if { ![string equal $id \x1f\x8b] } {
#        error "$file is not a gzip file."
#    }
#    set cm [read $in 1]
#    if { ![string equal $cm \x8] } {
#        error "$file: unknown compression method"
#    }
#    binary scan [read $in 1] b5 FLAGS
#    puts $FLAGS
#    foreach {FTEXT FHCRC FEXTRA FNAME FCOMMENT} [split $FLAGS ""] {}
#    binary scan [read $in 4] i MTIME
#    set XFL [read $in 1]
#    set OS [read $in 1]

#    if { $FEXTRA } {
#        binary scan [read $in 2] S XLEN
#        set ExtraData [read $in $XLEN]
#    }
#    set name ""
#    if { $FNAME } {     ead $in $XLEN]
#        set c [read $in 1]
#        while { $c != "\x0" } {
#            append name $c
#            set c [read $in 1]
#        }
#    }
#    set comment ""
#    if { $FCOMMENT } {
#        set c [read $in 1]
#        while { $c != "\x0" } {
#            append comment $c
#            set c [read $in 1]
#        }
#    }
#    set CRC16 ""
#    if { $FHCRC } {
#        set CRC16 [read $in 2]
#    }

 #   set cdata [read $in]
 #   close $in

 #   binary scan [string range $cdata end-7 end] ii CRC32 ISIZE

  #  set data [zlib inflate [string range $cdata 0 end-8]]

  #  if { $CRC32 != [zlib crc32 $data] } {
  #      error "gunzip Checksum mismatch."
  #  }
  #  if { $outfile == "" } {
  #      set outfile $file
  #      if { [string equal -nocase [file extension $file] ".gz"] } {
  #          set outfile [file rootname $file]
  #      }
  #  }
  #  if { [string equal $outfile $file] } {
  #      error "Will not overwrite input file. sorry."
  #  }
  #  set out [open $outfile w]
  #  fconfigure $out -translation binary -buffering none
  #  puts -nonewline $out $data
  #  close $out
  #  file mtime $outfile $MTIME
}

proc reference_crank { } {
    puts "Crank:"
    puts "<B><FONT COLOR=\"\#330044\"><!--SUMMARY_BEGIN-->\n"
    puts "\$TEXT:Reference: \$\$ Please reference \$\$"
    puts "Pannu NS, Waterreus WJ,  Skubak P, Sikharulidze I, Abrahams JP &"
    puts "de Graaff RAG (2011) Recent advances in the CRANK software suite"
    puts "for experimental phasing. Acta Cryst. D67, 331-337."
    puts "\$\$\n"
    puts "<!--SUMMARY_END--></FONT></B>\n"
}

proc show_parameters { } {
}

proc print_banner { version } {		  
    global tcl_platform
    global env

    crank_ccp4_banner "crank" $version
 
    puts "-------------------------------------------------------------------------------"
    puts "                         ___   _ __   __ _   _ __   | | __ "
    puts "                        / __| | '__| / _` | | '_ \\  | |/ / "
    puts "                       | (__  | |   | (_| | | | | | |   <  "
    puts "                        \\___| |_|    \\__,_| |_| |_| |_|\\_\\ "
    puts ""
    puts "                              Crank - Version $version"
    puts ""
    puts "                           Leiden University (c) - 2004-2007"
    puts ""
    puts "                              LIC, Gorlaeus Laboratories"
    puts "                              Leiden University"
    puts "                              PO Box 9502, 2300 RA Leiden"
    puts "                              The Netherlands"
    puts "    "
    puts "                    http://www.bfsc.leidenuniv.nl/software/crank/"
    puts "\n"
    if { [info exists env(CRANK) ] } {
	puts "Using Crank located in $env(CRANK)"
    }
    if { [info exists env(CCP4)] } {
	puts "Using CCP4  located in $env(CCP4)"
    }
    if { [file exists [file join $env(CRANK) bin gcx] ] } {
       puts "This Crank is not distributed with CCP4\n"
    } else {
   	puts "This Crank is distributed with CCP4\n"
    }
    puts "Please report any bugs or problems to crank@chem.leidenuniv.nl\n"
    puts ""
    puts "Tcl Version information: [info patchlevel]"
    parray tcl_platform
    puts ""
}

#
proc print_info_summary { } {

    #
    puts "This Crank run is now complete."
    puts ""
    puts "<!--SUMMARY_END--></FONT></B>"
    puts "</pre>"
}

#
proc print_data_summary { } {
}

# Show the reference list for all plugins
proc show_references { } {
    global XMLParse
    
    puts "References:"
    puts "----------"
    reference_crank
   
    for { set i 1 } { [info exists XMLParse(crank__soap__run__step=$i)] } { incr i } {
	set program [string tolower $XMLParse(crank__soap__run__step=$i)]
	    
	if { [info exists XMLParse(crank__plugin=${program}__name)] } {
	    ${program}_reference
	} else {
	    crank_error "No name for program ($program)"
	}
    }
}
