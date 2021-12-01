#!/usr/bin/env tclsh

# Copyright (C) Navraj S. Pannu 2006,  Leiden University
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

proc DetermineSolvent { step tag inputxml crankbin crankplugins inccp4 enant } {
    global XMLParse
    global env
    
    if { $inccp4 } {
	set gcx_ex [file join $env(CBIN) gcx]
    } else {
	set gcx_ex [file join $crankbin  gcx]
    }

    set orig_pwd $XMLParse(crank__soap__orig_pwd)

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
	regsub -all {\s+} $line " " line
	if {       [regexp { *([0-9]*) *([-0-9.]*) *([-0-9.]*) *([0-1].*).*} $line junk number matthews sol prob ] } {
	    if { $number != "" } {
		set listmatt($number) $matthews
		set listsolv($number) $sol
		set listprob($number) $prob
		set num $number
	    }
	} elseif { [regexp { *([0-9]*) *([-0-9.]*) *([-0-9.]*) *([0-1].*).*} $line junk number matthews sol prob ] } {
	    if { $number != "" } {
		set listmatt($number) $matthews
		set listsolv($number) $sol
		set listprob($number) $prob
		set num $number
	    }
	}
    }

    set minprob 0.01

    if { $num > 1 } {
	foreach {key solv} [array get listsolv] {
	    if { ($listprob($key) > $minprob) && ($solv > 0.1) && ($solv < 0.9) } {
		file mkdir dm-$solv
		cd dm-$solv
		runcommand [concat [file join $crankplugins dm xml2dmcom.tcl] $inputxml $enant $crankbin $solv >& dm-command.com]
		runcommand [concat [file join $crankplugins dm xml2dmtcl.tcl] $inputxml $enant $crankbin $solv >& dm-command.tcl]
#	        runcommand [concat chmod ugo+x ./dm-command.com]
#	        runcommand [concat ./dm-command.com]
		runcommand [concat tclsh dm-command.tcl]
		cd ..
	    }
	}
    
	set allsolvent [glob dm-0.*]

	array set rfree {}
	array set content {}
	set run 0
	set number 0    
	set num1 25

	foreach solvent $allsolvent { 
	    set logfile [open "[file join $solvent dm-logfile]" r]
	    set content($run) [string trimleft $solvent "dm-"] 
	    puts "Statistics from the final cycle with solvent content set to $content($run)\n"

	    set data [read $logfile]
	    set data [split $data "\n"]

	    set number 0

	    foreach line $data {
		regsub -all {\s+} $line " " line
		if { [regexp { *([0-9]*) 0.000 *([-0-9.]*).*} $line junk number trfree] } {
		    if { $number != "" } {
			puts "Real space Free R in cycle $number is $trfree\n"
			set rfree($run,$number) $trfree
			if { $num1 > $number } {
			    set num1 $number
			}

		    }
		}	    
	    }

	    close $logfile
	    incr run
	}

	# Find the solvent content with least rfree
	set minrfree 0
	set optimal 0
	for { set j 0 } { $j < $run } { incr j } {
	    if { $rfree($j,$num1)  < $minrfree } {
		set minrfree $rfree($j,$num1)
 		set optimal $j 
	    }
	}

	set monomers $XMLParse(crank__parameters__nmonomers)
	puts "Choosing solvent content $content($optimal)\n"

	foreach {key solv} [array get listsolv] {
	    if {$listsolv($key) == $content($optimal) } {
		set monomers $key
		puts  "Corresponding to $key monomers\n"
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

    }
}

set inputxml     [lindex $argv 0]
set crankbin     [lindex $argv 1]
set crankplugins [lindex $argv 2]
set version      [lindex $argv 3]
set enant        [lindex $argv 4]

source [file join $crankbin crankutils.tcl]

if { [file exists $inputxml] == 0 } {
    crank_error "dmoptimize.tcl::inputxml file does not exist"
}

XMLParsefile $inputxml

set step $XMLParse(crank__soap__current_step)
set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

DetermineSolvent $step $tag $inputxml $crankbin $crankplugins $version $enant 
