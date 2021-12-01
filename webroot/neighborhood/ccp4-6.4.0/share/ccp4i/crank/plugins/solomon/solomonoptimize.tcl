#!/usr/bin/env tclsh

# Copyright (C) 2006 Leiden University
#
# Author: Navraj S. Pannu
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

proc DetermineSolvent { step tag inccp4 ncycles enant nomtz bias } {
    global XMLParse
    global env

    set verbose 0

    set crankplugins [file join $env(CRANK) plugins]

    if { [info exists XMLParse([join "crank parameters verbose" __])] } {
       if { $XMLParse([join "crank parameters verbose" __]) >= 1 } {
	   set verbose 1
      }
    }

    if { $inccp4 }  {
	set gcx_ex [file join $env(CBIN) gcx]
    } else {
	set gcx_ex [file join $crankbin  gcx]
    }

    set orig_pwd [file join $XMLParse(crank__soap__orig_pwd)]

    if { $enant == "1" } {
	set mtz_in "[file join $orig_pwd workdb crank.in.$tag.mtz]"
    } else {
	set mtz_in "[file join $orig_pwd workdb crank.in.$tag.oh.mtz]"
    }

    set fp $XMLParse([join "crank soap run step=$step input exp_columns crystal=1 data=1 f" __])
    set sigfp $XMLParse([join "crank soap run step=$step input exp_columns crystal=1 data=1 sigf" __])

    set initmonomers $XMLParse([join "crank parameters nmonomers" __])

    if { [info exists XMLParse([join "crank parameters seqin filename" __]) ] } {
	set seq_in $XMLParse([join "crank parameters seqin filename" __])
	set command "$gcx_ex HKLIN $mtz_in SEQIN $seq_in << \"NOUT\n XTAL DER1\n DNAME TMP\n COLU F=$fp SF=$sigfp\" "
    } else {
	
	if { [info exists XMLParse([join "crank parameters residues" __]) ] } {
	    set nresidues $XMLParse(crank__parameters__residues)
	} else {
	    set nresidues 0
	}

 	if { [info exists XMLParse([join "crank parameters nucleotides" __]) ] } {
	    set nnucleotides $XMLParse(crank__parameters__nucleotides)
	} else {
 	    set nnucleotides 0
	}

	set command "$gcx_ex HKLIN $mtz_in << \"NRES $nresidues\n NNUC $nnucleotides\n NOUT\n XTAL DER1\n DNAME TMP\n COLU F=$fp SF=$sigfp\" "
    }
    
    catch {eval exec $command } output

    set data $output
    set data [split $data "\n"]
    array set listmatt {}
    array set listsolv {}
    array set listprob {}
    set num 0

    foreach line $data {
	if {       [regexp {    *([0-9]*)         *([-0-9.]*)             *([-0-9.]*)            *([0-1].*).*} $line junk number matthews sol prob ] } {
	    if { $number != "" } {
		set listmatt($number) $matthews
		set listsolv($number) $sol
		set listprob($number) $prob
		set num $number
	    }
	} elseif { [regexp {   *([0-9]*)         *([-0-9.]*)             *([-0-9.]*)            *([0-1].*).*} $line junk number matthews sol prob ] } {
	    if { $number != "" } {
		set listmatt($number) $matthews
		set listsolv($number) $sol
		set listprob($number) $prob
		set num $number
	    }
	}
    }

    if { [info exists XMLParse([join "crank soap run step=$step solomon opt_cycles" __])] } {
	set ocycles $XMLParse([join "crank soap run step=$step solomon opt_cycles" __])
    } else {
	set ocycles 2
    }

    set minprob 0.01

    if { $num > 1 } {
	foreach {key solv} [array get listsolv] {
	    if { ( ($listprob($key) > $minprob) && ($solv > 0.1) && ($solv < 0.9) ) } {
		file mkdir solomon-$solv
		cd solomon-$solv
		runcommand [concat tclsh [file join $crankplugins solomon xml2solomonscript.tcl] $ncycles $solv $enant $nomtz 0 $inccp4 0 $bias 1 $step >& solomon-command.py] $verbose
		runcommand [concat ccp4-python solomon-command.py >& solomon-logfile] 1
		cd ..
	    }
	}
    
	set allsolvent [glob solomon-0.*]

	array set contrast {}
	array set cor {} 
	array set fom {}
	array set content {}
	set run 0
	set number 1    
	set num1 0

	foreach solvent $allsolvent { 
	    puts "\n\$TABLE : Fom, Correlation coefficient and Contrast of solvent content $solvent per cycle:"
	    puts "\$SCATTER"
	    puts " : FOM, Contrast and Correlation for solvent content $solvent per cycle :A:1,2,3,4:"
	    puts "\$\$"
	    puts "Cycle  FOM     Contrast   Correlation          Correlation*Contrast  \$\$ \$\$"

 	    set logfile [open "[file join $solvent solomon-logfile]" r]
	    set content($run) [string trimleft $solvent "solomon-"] 
	    set data [read $logfile]
	    set data [split $data "\n"]

	    set number 0
	    foreach line $data {
		if { [regexp       {Inverse contrast is* *([0-9.]*).*} $line junk con] } {
		    set contrast($run,$number) [expr 1.0/$con ] 
		}
		if { [regexp       { Overall MEAN FOM is* *([0-9.]*).*} $line junk fomcycle] } {
		    set fom($run,$number) $fomcycle
		}
		if { [regexp       { Overall MEAN W is* *([0-9.]*).*} $line junk fomcycle] } {
		    set fom($run,$number) $fomcycle
		}
		if { [regexp       {.*([0-9]*) Reflections is *([0-9.]*).*} $line junk refs correl] } {
		    set cor($run,$number) $correl 
		    set i $number
		    puts [format "  %3d       %5.3f            %5.3f            %5.3f" $i $fom($run,$i) $contrast($run,$i) $cor($run,$i) [expr $contrast($run,$i)*$cor($run,$i)]]  
		    incr number
		}
                if { [regexp       { Overall Correlation is *([0-9.]*).*} $line junk correl] } {
		    set cor($run,$number) $correl 
		    set i $number
		    puts [format "  %3d       %5.3f            %5.3f            %5.3f" $i $fom($run,$i) $contrast($run,$i) $cor($run,$i) [expr $contrast($run,$i)*$cor($run,$i)]]  
		    incr number
                }
            }
	    close $logfile
	    incr run
	}

	set num1 $ocycles

	# Find the solvent content with the greatest correlation * contrast
	set maxcorrel 0
	set optimal 0
	for { set j 0 } { $j < $run } { incr j } {
	    if { [expr $contrast($j,$num1) * $cor($j,$num1) ] > $maxcorrel } {
		set maxcorrel [expr $contrast($j,$num1) * $cor($j,$num1) ]
		set optimal $j 
	    }
	}

	set monomers $XMLParse(crank__parameters__nmonomers)
	set result "Choosing solvent content $content($optimal)"

	foreach {key solv} [array get listsolv] {
	    if {$listsolv($key) == $content($optimal) } {
		set monomers $key
		set result  "$result\nCorresponding to $key monomers"
		break
	    }
	}
    
	if { $monomers != $XMLParse(crank__parameters__nmonomers) } {
	    set input [open "[file join .. xml input.xml]" a+]
	    puts $input "<crank><update>"
	    puts $input "<nmonomers>$monomers</nmonomers>"
	    puts $input "<solvent_content>$content($optimal)</solvent_content>"
	    puts $input "</update></crank>"
	    close $input
	}
	puts "\$TEXT:Result: \$\$ Final result"
	puts "$result"
	puts "\$\$\n"
    }
}

global env

set inccp4       [lindex $argv 0]
set ncycles      [lindex $argv 1]
set enant        [lindex $argv 2]
set nomtz        [lindex $argv 3]
set bias         [lindex $argv 4]

source [file join $env(CRANK) bin crankutils.tcl]

if { [file exists [file join .. xml input.xml] ] } {
    set inputxml     [file join .. xml input.xml]
} elseif { [file exists [file join .. .. xml input.xml] ] } {
    set inputxml     [file join .. .. xml input.xml]
} else {
    crank_error "crank::solomonhand.tcl:: input.xml file not found"
}

XMLParsefile $inputxml

set step $XMLParse(crank__soap__current_step)
set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

DetermineSolvent $step $tag $inccp4 $ncycles $enant $nomtz $bias
