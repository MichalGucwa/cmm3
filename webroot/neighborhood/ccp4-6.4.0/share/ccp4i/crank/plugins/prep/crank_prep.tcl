# Copyright (C) 2006-2007 Leiden University
#
# Authors: Navraj S. Pannu and Steven Ness 
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

proc prep_run { code crankbin executable crankplugins inputxml inccp4 step } {
    global XMLParse
    global env

    set t0 [clock clicks -millisec ]

   if { [info exists XMLParse([join "crank parameters version" __])] } {
       set xmlversion $XMLParse([join "crank parameters version" __])
    } else {
       crank_error "crank_prep.tcl::crank XML version info does not exist"
    }

    crank_plugin_begin $step "Scaling" "Truncate and scaleit" $crankplugins $xmlversion

    set verbose 0

    if { [info exists XMLParse([join "crank parameters verbose" __])] } {
       if { $XMLParse([join "crank parameters verbose" __]) >= 1 } {
	   set verbose 1
      }
    }   

    file mkdir $step-prep
    cd $step-prep
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    file copy [file join .. workdb crank.out.IN.mtz] extracted.mtz

    # Run truncate on all crystal/datasets to convert I+/I- to F+/F-
    if { [file exists [file join $env(CBIN) ctruncate] ] ||
         [file exists [file join $env(CBIN) ctruncate.exe] ] } { 
 	set ctruncate 1
    } else {
	set ctruncate 0
    }

    if { [info exists XMLParse([join "crank soap run step=$step prep old_truncate" __])] } {
	if { $XMLParse([join "crank soap run step=$step prep old_truncate" __]) } {
	    set ctruncate 0
	}
    }

    run_all_truncate $ctruncate

    if { [file exists extracted.mtz] } {
	file delete extracted.mtz
    }

    set mtzout "output.mtz"

    # FreeR factor
    # Output FREER column name
    set out_freer_column "${step}_PREP_FREER"

    set inrfree 0
    if { [info exists XMLParse([join "crank soap run step=$step prep input_rfree" __])] } {
        if { $XMLParse([join "crank soap run step=$step prep input_rfree" __]) && 
            [info exists XMLParse([join "crank soap run step=$step prep rfree_label" __])] } {
	    set inrfree 1
        }
    }	

    if { $inrfree } {
        
	# Input FREER column name
	set in_freer_column "IN_FREER"
	set sftools_script "read [file join .. workdb crank.out.IN.mtz]\n set label col $in_freer_column \n $out_freer_column \n"
	set sftools_script "$sftools_script write rfree.mtz col $out_freer_column \n quit \n"
	set command "sftools << \"$sftools_script\""
	catch {eval exec $command } output 
#  	puts $output
	set sftools_script "read $mtzout\n read rfree.mtz\n write $mtzout\ny \n quit \n"
	set command "sftools << \"$sftools_script\""
	catch {eval exec $command } output 
# 	puts $output
	file delete rfree.mtz

    } else {

	# Output FREER FRACTION

	if { [info exists XMLParse([join "crank soap run step=$step prep rfree_fraction" __])] } {	
	    set freer_fraction $XMLParse([join "crank soap run step=$step prep rfree_fraction" __])
	} else {
	    set freer_fraction 0.05
	}

	set sftools_script "read $mtzout\n calc I col $out_freer_column = rfree($freer_fraction) \n"
	set sftools_script "$sftools_script write $mtzout\ny \n quit\n"
	set command "sftools << \"$sftools_script\""
        catch {eval exec $command } output 
    }

    # ***NSP
    set scaleit -1
    set i 1
    while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } {
	set j 1
	while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } {
	    incr scaleit
	    incr j
	}
 	incr i
    }


    # Run scaling
    if { $scaleit } {
	runcommand [concat tclsh [file join $crankplugins prep xml2scaleitscript.tcl] 0 > scaleit-command.com] $verbose
	runcommand [concat tclsh [file join $crankplugins prep xml2scaleitscript.tcl] 1 > scaleit-command.tcl] $verbose
	runcommand [concat tclsh scaleit-command.tcl] 1
    } else {
	file copy output.mtz scaleit.out.mtz
    }

    file delete output.mtz

    if { [file exists scaleit.out.mtz] } {
	# Rename output columns to the names specified in the XML
	runcommand [concat tclsh [file join $crankplugins prep crank-rename-prep-output.tcl] $step scaleit.out.mtz rename.out.mtz] $verbose
	file copy rename.out.mtz [file join .. workdb crank.out.$tag.mtz]
	file delete rename.out.mtz
  	file delete scaleit.out.mtz
    } else {
	crank_error "crank_prep.tcl::scaleit did not finish successfully"
    }

    if { [file exists scaleit-logfile] } {

	set log [open "scaleit-logfile" r]
	set output [read $log]
	puts $output
	close $log
	# Copy logfile to main log directory
	file copy scaleit-logfile [file join .. log $step-prep-scaleit-logfile]
    } 

    crank_plugin_end $step [expr ([clock clicks -millisec ]-$t0)/1000.]

    cd ..
}

proc prep_dependencies { step } {
    global XMLParse

}

proc prep_input_check { step } {
    global XMLParse

}

proc prep_reference { } {
    global XMLParse

    puts "Truncate/Scaleit:"
    puts "<B><FONT COLOR=\"\#FF0000\"><!--SUMMARY_BEGIN-->\n"
    puts "\$TEXT:Reference: \$\$ Please reference \$\$"
    puts "CCP4 (1994) The CCP4 Suite: Programs for protein crystallography."
    puts "Acta Cryst. D50, 760-763."
    puts "\$\$\n"
    puts "<!--SUMMARY_END--></FONT></B>\n"
}

proc run_truncate { i j ctruncate } {
    global XMLParse
    global env

    # Setup variables
    set mtzin "extracted.mtz"
    set mtzout "truncate_${i}_${j}.mtz"

    set anomalous $XMLParse([join "crank parameters crystal=$i data=$j anomalous" __])
    set in_i "IN_X${i}_D${j}_I"
    set in_sigi "IN_X${i}_D${j}_SIGI"

    if { $anomalous == 1 } { 
	set in_ip "IN_X${i}_D${j}_I+"
	set in_sigip "IN_X${i}_D${j}_SIGI+"
	set in_im "IN_X${i}_D${j}_I-"
	set in_sigim "IN_X${i}_D${j}_SIGI-"
    }

    set in_f "IN_X${i}_D${j}_F"
    set in_sigf "IN_X${i}_D${j}_SIGF"
 
    if { $anomalous == 1 } { 
	set in_fp "IN_X${i}_D${j}_F+"
	set in_sigfp "IN_X${i}_D${j}_SIGF+"
	set in_fm "IN_X${i}_D${j}_F-"
	set in_sigfm "IN_X${i}_D${j}_SIGF-"
    }

    if { $ctruncate == 0 } { 
	set nmonomers $XMLParse(crank__parameters__nmonomers)
	set nnucleotides $XMLParse(crank__parameters__nucleotides) 
	set nresidues $XMLParse(crank__parameters__residues) 
	set nhydro [expr ($nresidues*8 + $nnucleotides*12)*$nmonomers]
	set ncarb [expr ($nresidues*4.869 + $nnucleotides*9.683)*$nmonomers]
	set nnitr [expr ($nresidues*1.351 + $nnucleotides*3.911)*$nmonomers]
	set noxyg [expr ($nresidues*1.492 + $nnucleotides*6.424)*$nmonomers]
	set nsulf [expr $nresidues*0.051*$nmonomers]
	set nphos [expr $nnucleotides*$nmonomers]
	set type $XMLParse([join "crank parameters crystal=$i data=$j type" __])

	# Create command line
	set command "HKLIN $mtzin HKLOUT $mtzout"

	# Create script
	if { $anomalous == 0 } {
	    set labin "labin IMEAN=$in_i SIGIMEAN=$in_sigi"
	    set labout "labout IMEAN=$in_i SIGIMEAN=$in_sigi F=$in_f SIGF=$in_sigf"
	}  else {
	    set labin "labin IMEAN=$in_i SIGIMEAN=$in_sigi I(+)=$in_ip SIGI(+)=$in_sigip I(-)=$in_im SIGI(-)=$in_sigim"
	    set labout "labout I(+)=$in_ip SIGI(+)=$in_sigip I(-)=$in_im SIGI(-)=$in_sigim - \n"
	    set labout "$labout F=$in_f SIGF=$in_sigf - \n"
	    set labout "$labout F(+)=$in_fp SIGF(+)=$in_sigfp F(-)=$in_fm SIGF(-)=$in_sigfm"
	}

	set script "truncate YES"
	if { $anomalous == 0 } {
	    set script "$script\nanomalous NO"
	} else {
	    set script "$script\nanomalous YES"
	}
    
	set script "$script\ncontents H $nhydro C $ncarb N $nnitr O $noxyg S $nsulf P $nphos"
	set script "$script\nplot OFF"
	set script "$script\nfalloff yes"
	set script "$script\ndname $j"
	set script "$script\nrsize 80"
	set script "$script\n$labin"
	set script "$script\n$labout"
	set script "$script\nEND\n"
	
	set run_command "[file join $env(CBIN) truncate] $command << \"$script\""
	puts $run_command
	catch {eval exec $run_command } output 
	puts $output
	set logfile [open "truncate_${i}_${j}-logfile" w]
	puts $logfile $output
	file copy truncate_${i}_${j}-logfile [file join .. log 1-prep-truncate_${i}_${j}-logfile]
	close $logfile

    } else {
	set noaniso ""
#if { [info exists XMLParse([join "crank soap run step=$step prep no_aniso" __])] } {
#    if { $XMLParse([join "crank soap run step=$step prep no_aniso" __]) } {
#	set noaniso "-no-aniso"
#    }
#}

	if { $XMLParse([join "crank parameters input_intensity" __]) } {
	    set script "-mtzin $mtzin -mtzout $mtzout $noaniso -colin /*/*/\\\[$in_i,$in_sigi\\\]"
	    if { $anomalous == 1 } {
		set script "$script -colano /*/*/\\\[$in_ip,$in_sigip,$in_im,$in_sigim\\\]"
	    }
	} else {
 	    set script "-mtzin $mtzin -mtzout $mtzout -amplitudes -colin /*/*/\\\[$in_f,$in_sigf\\\]"
	    if { $anomalous == 1 } {
		set script "$script -colano /*/*/\\\[$in_fp,$in_sigfp,$in_fm,$in_sigfm\\\]"
	    }
	}
 	set run_command "[file join $env(CBIN) ctruncate]"
        puts $run_command
	catch {eval exec $run_command $script} output 
	puts $output
	set logfile [open "ctruncate_${i}_${j}-logfile" w]
	puts $logfile $output
	file copy ctruncate_${i}_${j}-logfile [file join .. log 1-prep-ctruncate_${i}_${j}-logfile]
	close $logfile
 	# remove dano, sigdano and isym columns
	set sftools_script "read truncate_${i}_${j}.mtz\ndelete col DANO\ndelete col SIGDANO\ndelete col ISYM\n"
 	
	if { !($XMLParse([join "crank parameters input_intensity" __])) } {
	    set sftools_script "$sftools_script delete col $in_f\ndelete col $in_sigf\n"
	    if { $anomalous } {
		set sftools_script "$sftools_script delete col $in_fp\ndelete col $in_sigfp\ndelete col $in_fm\ndelete col $in_sigfm\n"
	    } 
 	} else {

	    set sftools_script "$sftools_script set label\n$in_f\n$in_sigf\n"
	    if { $anomalous == 1} {
		set sftools_script "$sftools_script $in_fp\n$in_sigfp\n$in_fm\n$in_sigfm\n\n\n\n\n\n\n"
	    } else {
		set sftools_script "$sftools_script \n\n\n"
	    }
	    set sftools_script "$sftools_script write truncate_${i}_${j}.mtz\ny\nquit\n"
	    set run_command "sftools << \"$sftools_script\""
	    catch {eval exec $run_command } output 
#	    puts $output
	}
    }
}

proc run_apply_scale { crankbin inccp4 } {
    global XMLParse
    global env

    if { $inccp4 } {
	set gcx_ex [file join $env(CBIN) gcx]
    } else {
	set gcx_ex [file join $crankbin  gcx]
    }

    set script "\nSCALE\n"

    if { [info exists XMLParse([join "crank parameters seqin filename" __]) ] } {
        set seq_in $XMLParse([join "crank parameters seqin filename" __])
        set command "$gcx_ex HKLIN extracted.mtz HKLOUT output.mtz SEQIN $seq_in "
    } else {
        if { [info exists XMLParse([join "crank parameters residues" __]) ] } {
            set script "$script NRES $XMLParse(crank__parameters__residues)\n"
        } 

        if { [info exists XMLParse([join "crank parameters nucleotides" __]) ] } {
            set script "$script NNUC $XMLParse(crank__parameters__nucleotides)\n"
        } 
        set command "$gcx_ex HKLIN extracted.mtz HKLOUT output.mtz "
    }

    set i 1
    while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } { 
	set script "$script XTAL CRYSTAL$i\n" 
	if { [info exists XMLParse([join "crank parameters crystal=$i substructure atom_name" __])] } {
	    set script "$script   ATOM $XMLParse([join "crank parameters crystal=$i substructure atom_name" __])\n"
	    set script "$script   NUMB [expr $XMLParse([join "crank parameters crystal=$i substructure natoms" __])/$XMLParse([join "crank parameters nmonomers" __])]\n"
	}
	set j 1
	while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } { 
	    set script "$script   DNAME DATASET$j\n"
	    if { $XMLParse([join "crank parameters crystal=$i data=$j anomalous" __]) == 1 } {
		set script "$script     COLU F=IN_X${i}_D${j}_F SF=IN_X${i}_D${j}_SIGF F+=IN_X${i}_D${j}_F+ SF+=IN_X${i}_D${j}_SIGF+ F-=IN_X${i}_D${j}_F- SF-=IN_X${i}_D${j}_SIGF-\n"
	    } else {
		set script "$script     COLU F=IN_X${i}_D${j}_F SF=IN_X${i}_D${j}_SIGF\n"
	    }
	    set k 1
	    while { [info exists XMLParse([join "crank parameters crystal=$i data=$j atom=$k name" __])] } { 

		set script "$script     FORM $XMLParse([join "crank parameters crystal=$i data=$j atom=$k name" __]) FP=$XMLParse([join "crank parameters crystal=$i data=$j atom=$k fprime" __]) FPP= $XMLParse([join "crank parameters crystal=$i data=$j atom=$k fprimeprime" __])\n"
		incr k
	    }
	    incr j
	}
	incr i
    }
	
    set run_command "$command << \"$script\""
    puts $run_command
    catch {eval exec $run_command } output 
#    puts $output
    set logfile [open "gcx-logfile" w]
    puts $logfile $output
    close $logfile
}

#
# Run truncate on all crystals/datasets separately to convert the
# input intensities (I's) to amplitudes (F's)
#
proc run_all_truncate { ctruncate } {
    global XMLParse

    if { !($XMLParse([join "crank parameters input_intensity" __])) } {
	file copy extracted.mtz output.mtz
    } else {
 	set i 1
	while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } { 
	    set j 1
	    while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } { 
		# Run truncate on this crystal/dataset
		run_truncate $i $j $ctruncate
		incr j
	    }
	    incr i
	}
 	# Combine all resultant datasets together and rename where necessary
	rename_input_columns 
    }
}

proc rename_input_columns { } {
    global XMLParse

    set sftools_script ""

    set i 1
    while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } { 
	set j 1
	while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } { 
	    set sftools_script "$sftools_script read truncate_${i}_${j}.mtz\n"
	    incr j
	}
	incr i
    }

    set mtzout "output.mtz"
    set sftools_script "$sftools_script write $mtzout\n\quit\n"
    set command "sftools << \"$sftools_script\""
#   puts $command
    catch {eval exec $command } output 
#   puts $output

    if { [info exists XMLParse([join "crank parameters disk_space" __])] } { 
	set i 1
	while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } { 
	    set j 1
	    if { [file exists truncate_${i}_${j}.mtz] } { 
		if { $XMLParse([join "crank parameters disk_space" __]) == "clean" } {
		    file delete truncate_${i}_${j}.mtz
		} elseif { $XMLParse([join "crank parameters disk_space" __]) == "compress" } {
		    compress truncate_${i}_${j}.mtz
		}
		incr j
	    }
	    incr i
	}
    }
}
