#!/usr/bin/env tclsh

# Copyright (C) Navraj S. Pannu 2008, Leiden University
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
#
proc OutputSharpcomfile { executable run substructurepdb hand } {
    global XMLParse

    set step $XMLParse(crank__soap__current_step)
    set orig_pwd $XMLParse(crank__soap__orig_pwd)
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]
    if { $hand == 0 } {
	set mtz_in sharp.data.mtz
    } else {
	set mtz_in sharp.data.oh.mtz
    }

    set sad_only 0
    set maxc 0
    set maxd 0

   if { [info exists XMLParse([join "crank soap run step=$step sharp lores" __])] } {
       set lores $XMLParse([join "crank soap run step=$step sharp lores" __])
    }

   if { [info exists XMLParse([join "crank soap run step=$step sharp hires" __])] } {
       set hires $XMLParse([join "crank soap run step=$step sharp hires" __])
    }

    # determine if we have MAD+native!
    set mad_native 0

    set sg ""
    set number ""

    spacegroup_from_mtz $mtz_in sg number

    set i 1
    while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } {
	if { $XMLParse([join "crank parameters crystal=$i native" __]) == "0" } {
	    set j 1
	    while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } {
		if {$j > 1} {
		    set mad_native 1
		}
	 	incr j
	    }
	}
	incr i
    }

    puts "DATAFILES       [file join $orig_pwd $step-sharp]" 
    puts "TITLE           None"
    puts "OBSFILE         $mtz_in"  
    puts "LEVEL           STANDARD"
    puts "MODE            REFINE RESIDUAL ELECTRON_DENSITY ESTIMATE"
    puts "CYCLES          20 1 3"
    puts "REJECT          YES 5"
    puts "NUM_BINS        20"
    puts "STRATEGY        7 15 63"
    puts "WEED            1 0.5 3"
    puts [format "CELL            %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f" $XMLParse(crank__parameters__crystal=1__cell__cell_a) $XMLParse(crank__parameters__crystal=1__cell__cell_b) $XMLParse(crank__parameters__crystal=1__cell__cell_c) $XMLParse(crank__parameters__crystal=1__cell__cell_alpha) $XMLParse(crank__parameters__crystal=1__cell__cell_beta) $XMLParse(crank__parameters__crystal=1__cell__cell_gamma)]
    puts "SYMMETRY        $sg" 
    set nmonomers $XMLParse(crank__parameters__nmonomers)
    set nnucleotides $XMLParse(crank__parameters__nucleotides)
    set nresidues $XMLParse(crank__parameters__residues)
    set ncarb [expr int(($nresidues*4.869 + $nnucleotides*9.683)*$nmonomers)]
    set nnitr [expr int(($nresidues*1.351 + $nnucleotides*3.911)*$nmonomers)]
    set noxyg [expr int(($nresidues*1.492 + $nnucleotides*6.424)*$nmonomers)]
    set nsulf [expr int($nresidues*0.051*$nmonomers)]

    puts "ATOMS \{"
    puts [format "   C %7d" $ncarb] 
    puts [format "   N %7d" $nnitr] 
    puts [format "   O %7d" $noxyg]
    puts [format "   S %7d" $nsulf]
    puts "\}"
   
    # All the G-Sites:
    puts "G-SITES \{"
    #
    #
    set gsites 0 
    set i 1
    while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } { 

  	if { [info exists XMLParse([join "crank parameters crystal=$i native" __])] &&
 	     $XMLParse([join "crank parameters crystal=$i native" __]) == "0"} { 
 	    set inputatom $XMLParse([join "crank parameters crystal=$i substructure atom_name" __])

 	    if { [info exists XMLParse([join "crank parameters crystal=$i substructure coordinate_format" __]) ] } {
 		set format $XMLParse([join "crank parameters crystal=$i substructure coordinate_format" __])
 		set j 1

 		while { [info exists XMLParse([join "crank parameters crystal=$i substructure atom=$j name" __]) ] } {
 		    incr gsites
 		    set x    $XMLParse([join "crank parameters crystal=$i substructure atom=$j x" __])
 		    set y    $XMLParse([join "crank parameters crystal=$i substructure atom=$j y" __])
 		    set z    $XMLParse([join "crank parameters crystal=$i substructure atom=$j z" __])
 		    if { ($format != "Fractional") } {
 			orth2frac $x $y $z fracx fracy fracz
 			set x $fracx  			    
 			set y $fracy   
 			set z $fracz
 		    }

 		    if { $gsites < 10 } {
 			puts "   GSITE-0$gsites X [format %9.6f $x]   REFINE Y [format %9.6f $y]   REFINE Z [format %9.6f $z]"
 		    } else {
 			puts "   GSITE-$gsites X [format %9.6f $x]   REFINE Y [format %9.6f $y]   REFINE Z [format %9.6f $z]"
 		    } 
 		    incr j
  		}
 	    } else {
 		set input [open $substructurepdb r]
 		set indata [split [read $input] "\n"]

 		foreach line  $indata { 
 		    if { [regexp {HETATM.*} $line junk] || [regexp {ATOM.*} $line junk] } {
 			scan $line "%6s%5d%*c%*c%4s%*c%3s%*c%*c%*c%*c%*c%*c%*c%*c%*c%*c%*c%8f%8f%8f%6f" label number atom residue x y z occ
 			incr gsites
			orth2frac $x $y $z fracx fracy fracz
 			set x $fracx  			    
 			set y $fracy   
 			set z $fracz

 			if { $gsites < 10 } {
 			    puts "   G-SITE-0$gsites X [format %9.6f $x]   REFINE Y [format %9.6f $y]   REFINE Z [format %9.6f $z]   REFINE"
			} else {
			    puts "   G-SITE-$gsites X [format %9.6f $x]   REFINE Y [format %9.6f $y]   REFINE Z [format %9.6f $z]   REFINE"
 			} 
  		    }
 		}
 		close $input
 	    }
 	}
  	incr i
    }
    puts "\}"

    # COMPOUND...
    puts "COMPOUND \{"
    puts "   COMPOUND-TEXT \{"
    puts "   \}"
    puts "   C-SITES \{"
    for {set g 1 } { $g <= $gsites} {incr g } {
 	if { $g < 10} {
 	    puts "      C-SITE-0$g  G-SITE-0$g   $inputatom"
 	} else {
 	    puts "      C-SITE-$g  G-SITE-$g   $inputatom"
 	}
    }
    puts "   \}"
    puts "   CRYSTAL \{"
    puts "      CRYSTAL-TEXT \{"
    puts "      \}"
    puts "      T-SITES \{"
    set tsites 0
    set d 0
    set i 1
    while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } { 

  	if { [info exists XMLParse([join "crank parameters crystal=$i native" __])] &&
 	     $XMLParse([join "crank parameters crystal=$i native" __]) == "0"} { 

 	    if { [info exists XMLParse([join "crank parameters crystal=$i substructure coordinate_format" __]) ] } {
		set format $XMLParse([join "crank parameters crystal=$i substructure coordinate_format" __])
 		set j 1

 		while { [info exists XMLParse([join "crank parameters crystal=$i substructure atom=$j name" __]) ] } {
 		    incr tsites

 		    if { $tsites < 10 } {
 			puts "         T-SITE-0$tsites \{"
 			puts "            C-SITE-0$tsites"
 			puts "            HAT_OCC      [format %7.5f $XMLParse([join "crank parameters crystal=$i substructure atom=$j occ" __])]   REFINE"
 			puts "            HAT_B        [format %9.5f $XMLParse([join "crank parameters crystal=$i substructure atom=$j bfac" __])]  REFINE"
 			puts "            HAT_B6_ADD   0.000   0.000   0.000   0.000   0.000   0.000 NOREFINE"
 			puts "         \}"
		    } else {
 			puts "         T-SITE-$tsites \{"
  			puts "            C-SITE-$tsites"
 			puts "            HAT_OCC      [format %7.5f $XMLParse([join "crank parameters crystal=$i substructure atom=$j occ" __])]   REFINE"
 			puts "            HAT_B        [format %9.5f $XMLParse([join "crank parameters crystal=$i substructure atom=$j bfac" __])]  REFINE"
 			puts "            HAT_B6_ADD   0.000   0.000   0.000   0.000   0.000   0.000 NOREFINE"
 			puts "         \}"
		    } 
		    incr j
 		}
	    } else {
		set input [open $substructurepdb r]
		set indata [split [read $input] "\n"]

		foreach line  $indata {
		    if { [regexp {HETATM.*} $line junk] || [regexp {ATOM.*} $line junk] } {
			scan $line "%6s%5d%*c%*c%4s%*c%3s%*c%*c%*c%*c%*c%*c%*c%*c%*c%*c%*c%8f%8f%8f%6f%6f" label number atom residue x y z occ bfac
			incr tsites
			if { $tsites < 10 } {
			    puts "         T-SITE-0$tsites \{"
			    puts "            C-SITE-0$tsites"
			    puts "            HAT_OCC      [format %7.5f $occ]   REFINE"
			    puts "            HAT_B        [format %9.5f $bfac]  REFINE"
			    puts "            HAT_B6_ADD   0.000   0.000   0.000   0.000   0.000   0.000 NOREFINE"
			    puts "         \}"
			} else {
			    puts "         T-SITE-$tsites \{"
			    puts "            C-SITE-$tsites"
			    puts "            HAT_OCC      [format %7.5f $occ]   REFINE"
			    puts "            HAT_B        [format %9.5f $bfac]  REFINE"
			    puts "            HAT_B6_ADD   0.000   0.000   0.000   0.000   0.000   0.000 NOREFINE"
			    puts "         \}"
			} 
 		    }
		}
		close $input
	    }
	}

	set j 1
	while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } {
	    incr d
	    puts "      WAVELENGTH \{"
	    puts "         WAVELENGTH-TEXT \{"
	    puts "         \}"
	    puts "         RESOLUTION    [format %6.3f $lores]     [format %6.3f $hires]"
	    puts "         BATCH \{"
	    puts "            BATCH-TEXT \{"
	    puts "            \}"
	    if { $d > 1 } {
		puts "            SCAL_K            1.00000   REFINE   ESTIMATE"
		puts "            SCAL_B            0.00000   REFINE   ESTIMATE"
		puts "            SCAL_B6_ADD       0.000   0.000   0.000   0.000   0.000   0.000 NOREFINE"
		puts "            NISO_BGLO         0.00000   REFINE"
		puts "            NISO_CLOC         0.00000   REFINE"
		puts "            NISO_BLOC         0.00000 NOREFINE"
		puts "            NANO_BGLO         0.00000   REFINE"
		puts "            NANO_CLOC         0.00000   REFINE"
		puts "            NANO_BLOC         0.00000 NOREFINE"
	    } else {
		puts "            SCAL_K            1.00000 NOREFINE   ESTIMATE"
		puts "            SCAL_B            0.00000 NOREFINE   ESTIMATE"
		puts "            SCAL_B6_ADD       0.000   0.000   0.000   0.000   0.000   0.000 NOREFINE"
		puts "            NISO_BGLO         0.00000 NOREFINE"
		puts "            NISO_CLOC         0.00000 NOREFINE"
		puts "            NISO_BLOC         0.00000 NOREFINE"
		puts "            NANO_BGLO         0.00000   REFINE"
		puts "            NANO_CLOC         0.00000   REFINE"
		puts "            NANO_BLOC         0.00000 NOREFINE"
	    }
	    if { $XMLParse([join "crank parameters crystal=$i native" __]) == "0"} { 
		puts "            HATOM_LABEL \{"
 		puts "               $inputatom ATOM_f'  [format %7.4f $XMLParse([join "crank parameters crystal=$i data=$j atom=1 fprime" __])] NOREFINE ATOM_f\"   [format %7.4f $XMLParse([join "crank parameters crystal=$i data=$j atom=1 fprimeprime" __])] NOREFINE"
		puts "            \}"
		puts "            OBSFILE $mtz_in"
		puts "            COLUMNS H=H K=K L=L FMID=F_${i}_${j} SMID=SIGF_${i}_${j} DANO=DANO_${i}_${j} SANO=SIGDANO_${i}_${j}"
	    } else {
		puts "            OBSFILE $mtz_in"
		puts "            COLUMNS H=H K=K L=L FMID=F_${i}_${j} SMID=SIGF_${i}_${j}"
	    }
	    puts "         \}"
	    incr j
	}
	incr i
    }

    puts "      \}"

    puts "   \}"


    #
    #
    puts "\}"
    puts "END"
}

set inputxml [lindex $argv 0]
set substructurepdb [lindex $argv 1]
set run [lindex $argv 2]
set executable [lindex $argv 3]
set hand [lindex $argv 4]
set crankbin [lindex $argv 5]

# Set CRANK path
source [file join $crankbin crankutils.tcl]

#
# Check to make sure files exist
#
if { [file exists $inputxml] == 0 } {
    crank_error "xml2sharpcom.tcl::inputxml file does not exist"
}

if { [file exists $substructurepdb] == 0 } {
    crank_error "xml2sharpcom.tcl::substructurepdb file does not exist"
}

XMLParsefile $inputxml

OutputSharpcomfile $executable $run $substructurepdb $hand
