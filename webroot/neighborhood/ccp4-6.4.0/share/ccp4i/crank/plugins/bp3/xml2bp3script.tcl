#!/usr/bin/env tclsh

# Copyright (C) Navraj S. Pannu 2006-2008, Leiden University
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
proc OutputBP3scriptfile { inccp4 run substructurepdb crunch2 tcl } {
    global XMLParse
    global env

    set step $XMLParse(crank__soap__current_step)
    set orig_pwd $XMLParse(crank__soap__orig_pwd)
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    set sad_only 0
    set maxc 0
    set maxd 0

    if { [info exists XMLParse([join "crank soap run step=$step bp3 sad_only" __])] } {
	set sad_only $XMLParse([join "crank soap run step=$step bp3 sad_only" __])

	if { $sad_only == 1} {
  	    # only SAD requested, so find crystal and data set with maximal f"
	    set maxc 0
	    set maxd 0
	    set maxfpp 0

	    set i 1
	    while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } {
		set j 1
		while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } {
		    if { $XMLParse([join "crank parameters crystal=$i data=$j anomalous" __]) == 1 } { 
			set k 1
		        while { [info exists XMLParse([join "crank parameters crystal=$i data=$j atom=$k fprimeprime" __])] } {
			    if { $XMLParse([join "crank parameters crystal=$i data=$j atom=$k fprimeprime" __]) > $maxfpp } {
			        set maxc $i
			        set maxd $j
			        set maxfpp $XMLParse([join "crank parameters crystal=$i data=$j atom=$k fprimeprime" __])
			    }
			    incr k
			}
		    }
		    incr j
		}
		incr i
	    }

	    if { ($maxc < 1) || ($maxd < 1) } {
		crank_error "One anomalous data set is needed if SAD only is requested"
	    } 
	}
    }

    if { $tcl } {
	puts "\#!/usr/bin/env tclsh"
    } else {
	puts "\#!/bin/sh"
    }

    puts " "

    set mtz_in "[file join .. workdb crank.in.$tag.mtz]"

    set mtz_out "crank.out.${tag}-${run}.mtz"

    if { $inccp4 } {
       set executable [file join $env(CBIN) bp3]
    } else {
       set executable [file join $env(CRANK) bin  bp3]
    }

    if { $tcl } {
	puts "set command \"$executable HKLIN $mtz_in HKLOUT $mtz_out\""
	puts -nonewline "set script \""
    } else {
	puts "$executable HKLIN $mtz_in HKLOUT $mtz_out << END > bp3-logfile-${run}"
    }

    set lastrun [expr $run - 1]
    if { [file exists heavy${lastrun}.sh] } {
	# read output of previous bp3 job to start the next one.
	set input [open  heavy${lastrun}.sh r]
	set data  [read $input]
	set data  [split $data  "\n"]
	set insub 1
	foreach line $data {
	    regsub -all {\s+} $line " " line
	    if { [regexp {.*bp3 .*} $line junk ]   || [regexp {^SITE .*} $line junk ] || 
		 [regexp {.*BISO .*} $line junk]   || [regexp {.*OCCU .*} $line junk ] || 
		 [regexp {.*REFAll.*} $line junk] || 
		 [regexp {eof.*} $line junk ]      || [regexp {.*!/bin/sh.*} $line junk ] } {
 		# do nothing
 	    } elseif { [regexp {.*ATOM .*} $line junk] } {
		if { $insub } {
		    puts " MODL $substructurepdb"
		    set insub 0
		}
	    } else {
		puts $line
 	    }
	}
	close $input
	
    } else {

	puts " "

	# determine if we have MAD+native!
	set mad_native 0

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

	# Loop over all crystal/dataset pairs
	#
	# Loop over all crystal/datasets outputting XTAL/DNAME sections for each
	#

	set i 1
	while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } { 

	    if { !( ($mad_native == 1) && ($XMLParse([join "crank parameters crystal=$i native" __]) == "1") ) } {

		if { ($sad_only == 1 ) && ($i != $maxc) } {
		    incr i
		    continue
		}

		# Start the XTAL section

		puts "XTAL crystal${i}"

		if { [info exists XMLParse([join "crank parameters crystal=$i native" __])] &&
		     $XMLParse([join "crank parameters crystal=$i native" __]) == "0"} { 

		    if { [info exists XMLParse([join "crank parameters crystal=$i substructure coordinate_format" __]) ] } {
			set format $XMLParse([join "crank parameters crystal=$i substructure coordinate_format" __])
			set j 1

			while { [info exists XMLParse([join "crank parameters crystal=$i substructure atom=$j name" __]) ] } {
			    set x    $XMLParse([join "crank parameters crystal=$i substructure atom=$j x" __])
			    set y    $XMLParse([join "crank parameters crystal=$i substructure atom=$j y" __])
			    set z    $XMLParse([join "crank parameters crystal=$i substructure atom=$j z" __])
			    # Atom name
			    puts "   atom $XMLParse([join "crank parameters crystal=$i substructure atom=$j name" __])"
			    if { ($format == "Fractional") } {
				puts -nonewline "    xyz "
				puts -nonewline [format "%8.4f " $x]
				puts -nonewline [format "%8.4f " $y]
				puts -nonewline [format "%8.4f " $z]
			    } else {
				orth2frac $x $y $z fracx fracy fracz
				puts -nonewline "    xyz "
				puts -nonewline [format "%8.4f " $fracx]
				puts -nonewline [format "%8.4f " $fracy]
				puts -nonewline [format "%8.4f " $fracz]
			    }

			    if {  [info exists XMLParse([join "crank parameters crystal=$i substructure atom=$j noref_x" __])] &&
				  [info exists XMLParse([join "crank parameters crystal=$i substructure atom=$j noref_y" __])] &&
				  [info exists XMLParse([join "crank parameters crystal=$i substructure atom=$j noref_z" __])] } {
				if { $XMLParse([join "crank parameters crystal=$i substructure atom=$j noref_x" __]) ||
				     $XMLParse([join "crank parameters crystal=$i substructure atom=$j noref_y" __]) ||
				     $XMLParse([join "crank parameters crystal=$i substructure atom=$j noref_z" __]) } {
				    puts -nonewline "NOREF "
				    if { $XMLParse([join "crank parameters crystal=$i substructure atom=$j noref_x" __]) } {
					puts -nonewline "X "
				    }
				    if { $XMLParse([join "crank parameters crystal=$i substructure atom=$j noref_y" __]) } {
					puts -nonewline "Y "
				    }
				    if { $XMLParse([join "crank parameters crystal=$i substructure atom=$j noref_z" __]) } {
					puts -nonewline "Z "
				    }
				}
			    }
			    puts ""
			    puts -nonewline [format "    occu %10.3f" $XMLParse([join "crank parameters crystal=$i substructure atom=$j occ" __])]

			    if {  [info exists XMLParse([join "crank parameters crystal=$i substructure atom=$j noref_occ" __])] } {
				if { $XMLParse([join "crank parameters crystal=$i substructure atom=$j noref_occ" __]) } {
				    puts -nonewline "NOREF "
				}
			    }
			    puts ""
			    puts -nonewline "    biso $XMLParse([join "crank parameters crystal=$i substructure atom=$j bfac" __])"
			    if {  [info exists XMLParse([join "crank parameters crystal=$i substructure atom=$j noref_bfac" __])] } {

				if { $XMLParse([join "crank parameters crystal=$i substructure atom=$j noref_bfac" __]) } {
				    puts -nonewline "NOREF "
				} 
			    }
			    puts ""
			    incr j
			}
		    } else {
			puts "  MODL $substructurepdb"
		    }
		}

		set j 1
		while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } { 
		    # Start the DNAME section
		    set type $XMLParse([join "crank parameters crystal=$i data=$j type" __])

		    if { ( ($sad_only == 1 ) && ($j != $maxd) ) } {
			incr j
			continue
		    }

		    puts "  DNAME ${type}_${i}_${j}"
		    # Output the columns for this dataset
		    if { $XMLParse([join "crank parameters crystal=$i data=$j anomalous" __]) == 0 } { 
			# Build up labin and labout for non-anomalous data
			set input_f $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j f" __])
			set input_sigf $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j sigf" __])
		
			puts "    COLUMN F=$input_f SF=$input_sigf"
		    } else {
			set input_f_plus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j f_plus" __])
			set input_sigf_plus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j sigf_plus" __])
			set input_f_minus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j f_minus" __])
			set input_sigf_minus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j sigf_minus" __])
				
			# Output COLUMN identifier
			puts "    COLUMN F+=$input_f_plus SF+=$input_sigf_plus F-=$input_f_minus SF-=$input_sigf_minus"
	               	
			# Output Atom Form Factors
			set k 1
			while { [info exists XMLParse([join "crank parameters crystal=$i data=$j atom=$k name" __])] } { 

			    # Output Atom Form Factors
			    set atomname $XMLParse([join "crank parameters crystal=$i data=$j atom=$k name" __])
			    set fprime $XMLParse([join "crank parameters crystal=$i data=$j atom=$k fprime" __])
			    set fprimeprime $XMLParse([join "crank parameters crystal=$i data=$j atom=$k fprimeprime" __])
			    puts "    FORM $atomname FP=$fprime FPP=$fprimeprime"
			    incr k
			}
		    }
		    incr j
		}
	    }
	    incr i
	}


    }

    #
    # BP3 Options
    #

    puts "OUTP heavy${run}"
#   puts "VERBOSE 3"  

#   if { !$crunch2 } {
#      puts "NOUP"
#   }
#   puts "NOREF XYZ"
#    puts "NOREF OCCU"
#   puts "NOREF BFAC"
#   puts "MXYZ 0.05"

    if { [info exists XMLParse([join "crank soap run step=$step bp3 nohand" __])] } {
	if { $XMLParse([join "crank soap run step=$step bp3 nohand" __]) == "1" } {
	    puts "NOHAnd"
	}
    }

    if { [info exists XMLParse([join "crank soap run step=$step bp3 noref_xyz" __])] } {
       if { $XMLParse([join "crank soap run step=$step bp3 noref_xyz" __]) == "1" } {
          puts "NOREf XYZ"
       }
    }

    if { [info exists XMLParse([join "crank soap run step=$step bp3 noref_bfac" __])] } {
	if { $XMLParse([join "crank soap run step=$step bp3 noref_bfac" __]) == "1" } {
	    puts "NOREf BFAC"
	}
    }

    if { [info exists XMLParse([join "crank soap run step=$step bp3 noref_occ" __])] } {
	if { $XMLParse([join "crank soap run step=$step bp3 noref_occ" __]) == "1" } {
	    puts "NOREf OCCU"
	}
    }

    if { [info exists XMLParse([join "crank soap run step=$step bp3 ncycles" __])] } {
	if { $XMLParse([join "crank soap run step=$step bp3 ncycles" __]) != "0" } {
	    set cycle $XMLParse([join "crank soap run step=$step bp3 ncycles" __])
	    puts "cycle $cycle"
	}
    }

    if { [info exists XMLParse([join "crank soap run step=$step bp3 phase" __])] } {
	if { $XMLParse([join "crank soap run step=$step bp3 phase" __]) != "0" } {
	    puts "phase"
	}
    }
    puts "LABO F=${tag}_F SIGF=${tag}_SIGF FB=${tag}_FB PHIB=${tag}_PHIB FOM=${tag}_FOM HLA=${tag}_HLA HLB=${tag}_HLB \\"
    puts "     HLC=${tag}_HLC HLD=${tag}_HLD FDIFF=${tag}_FDIFF PDIFF=${tag}_PDIFF "
    if { $crunch2 == 1 } {
	puts "check"
    }

    if { $tcl } {
        puts "\nEND\""
        puts ""
	puts "set command \"\$command << \\\"\$script\\\" > bp3-logfile${run}\""
	puts "eval exec \$command"
    } else {
        puts "END"
    }
}

global env 

set inccp4          [lindex $argv 0]
set substructurepdb [lindex $argv 1]
set run             [lindex $argv 2]
set crunch2         [lindex $argv 3]
set tcl             [lindex $argv 4]

source [file join $env(CRANK) bin crankutils.tcl]

set inputxml [file join .. xml input.xml]

if { [file exists $inputxml] == 0 } {
    crank_error "xml2bp3script.tcl::inputxml file does not exist"
}

if { [file exists $substructurepdb] == 0 } {
    crank_error "xml2bp3script.tcl::substructurepdb file does not exist"
}

XMLParsefile $inputxml

OutputBP3scriptfile $inccp4 $run $substructurepdb $crunch2 $tcl
