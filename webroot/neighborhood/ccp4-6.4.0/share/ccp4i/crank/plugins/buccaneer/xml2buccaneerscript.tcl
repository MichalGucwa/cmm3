#!/usr/bin/env tclsh
#
# Copyright (C) Navraj S. Pannu 2006-2007, Leiden University
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
#
proc OutputBuccaneerscriptfile { tcl inccp4 } {
    global XMLParse
    global env

    set step $XMLParse(crank__soap__current_step)
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]

    if { [file exists [file join .. workdb crank.in.$tag.mtz] ] } {
	set mtz_in "[file join .. workdb crank.in.$tag.mtz]"
    } else {
	crank_error "xml2buccaneerscript.tcl::input mtz file does not exist"
    }

    set c $XMLParse([join "crank parameters ref_crystal" __])
    set d $XMLParse([join "crank parameters ref_dataset" __])

    if { [info exists XMLParse([join "crank soap run step=$step buccaneer phase_restrain" __])] } {
       set phase_restrain $XMLParse([join "crank soap run step=$step buccaneer phase_restrain" __])
    } else {
       set phase_restrain "MLHL"
    }

    set in_fp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d f" __])
    set in_sigfp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d sigf" __])

	if { $phase_restrain == "DIRECT"} {
	    # Set parameters specific to the SAD/SIRAS target
	    # only SAD/SIRAS at the moment for refmac, so find crystal and data set with maximal f"
	    set maxc 0
	    set maxd 0
	    set maxfpp 0
	    set nc 0

	    set i 1
	    while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } {
		set j 1
		while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } {
		    if { $XMLParse([join "crank parameters crystal=$i data=$j anomalous" __]) == 1 } { 
			set k 1
			while { [info exists XMLParse([join "crank parameters crystal=$i data=$j atom=$k name" __])] } {
			    if { $XMLParse([join "crank parameters crystal=$i data=$j atom=$k fprimeprime" __]) > $maxfpp } {
				set maxc $i
				set maxd $j
				set maxfpp $XMLParse([join "crank parameters crystal=$i data=$j atom=$k fprimeprime" __])
			    }
			    incr k
 			}
		    } elseif { $XMLParse([join "crank parameters crystal=$i native" __]) == 1 } {
			set nc $i
		    }
		    incr j
		}
		incr i
	    }

	    if { ($maxc < 1) || ($maxd < 1) } {
		crank_error "Only SAD or SIRAS data is supported in refmac at the moment, so one anomalous data set is needed"
	    }

	    if { ($nc > 0) } {
   		set in_fp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$nc data=1 f" __])
		set in_sigfp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$nc data=1 sigf" __])
	    } else {
		set in_fp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd f" __])
		set in_sigfp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd sigf" __])
	    }
	    
	    if { [info exists XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd f_plus" __]) ] } {
		set in_f_plus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd f_plus" __])
		set in_sigf_plus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd sigf_plus" __])
		set in_f_minus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd f_minus" __])
		set in_sigf_minus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd sigf_minus" __])
	    } else {
		 crank_error "SAD/SIRAS function requested with non-anomalous reference data set"
	    }
	}

    # Sequence file

    set in_seq ""
    if { [file exists input.seq ] } {
	set in_seq "[file join input.seq]"
	set reliable 0.95
	if { [info exists XMLParse([join "crank soap run step=$step buccaneer sequence_match" __])] } {
	    set reliable $XMLParse([join "crank soap run step=$step buccaneer sequence_match" __])
	}
    }	

    # Initial model

    if { [info exists XMLParse([join "crank soap run step=$step use_pdb" __])] &&
         [info exists XMLParse([join "crank soap run step=$step input pdb" __])]  } {
        if { $XMLParse([join "crank soap run step=$step buccaneer use_pdb" __]) == "1" } {
	    set pdb_tag $XMLParse([join "crank soap run step=$step input pdb" __])
	    if { [file exists [file join .. workdb crank.out.$pdb_tag.pdb] ] } {
                set input_pdb [file join .. workdb crank.out.$pdb_tag.pdb]
            }
        }
    }

    set atomname ""

    if { [info exists XMLParse([join "crank soap run step=$step input substructure" __])]  &&
         ($phase_restrain == "DIRECT") } {
 	set sub_tag $XMLParse([join "crank soap run step=$step input substructure" __])
	    if { [file exists [file join .. workdb crank.out.$sub_tag.substructure.pdb] ] &&
                ![file exists heavy.pdb] } {
                set sub_in [file join .. workdb crank.out.$sub_tag.substructure.pdb]
		check_refmac_substructure $sub_in heavy.pdb
	    }
    }

    # HL columns

    if { [info exists XMLParse([join "crank soap run step=$step input hl_columns hla" __])] &&
	  [string compare $XMLParse([join "crank soap run step=$step input hl_columns hla" __]) "NONE"] != 0 } {
	set in_hla $XMLParse([join "crank soap run step=$step input hl_columns hla" __])
	set in_hlb $XMLParse([join "crank soap run step=$step input hl_columns hlb" __])
	set in_hlc $XMLParse([join "crank soap run step=$step input hl_columns hlc" __])
	set in_hld $XMLParse([join "crank soap run step=$step input hl_columns hld" __])
     } 
     
    if { [info exists XMLParse([join "crank soap run step=$step input phase_columns phib" __])] } {
	set in_phib $XMLParse([join "crank soap run step=$step input phase_columns phib" __])
	set in_fom $XMLParse([join "crank soap run step=$step input phase_columns fom" __])
    } else {
	crank_error "no phase information is input!"
    }

    # Free R column

    if { [info exists XMLParse([join "crank soap run step=$step input freer_columns freer" __])] } {
        set in_freer $XMLParse([join "crank soap run step=$step input freer_columns freer" __])
    } else {
        set in_freer ""
    }

    if { [info exists XMLParse([join "crank soap run step=$step buccaneer nousefreer" __])] } {
        if { $XMLParse([join "crank soap run step=$step buccaneer nousefreer" __]) } {
            set in_freer ""
        }
    } 


    # options

    set fragments 20
    if { [info exists XMLParse([join "crank soap run step=$step buccaneer fragments" __])] } {
	if { $XMLParse([join "crank soap run step=$step buccaneer fragments" __]) > 0 } {
	    set fragments $XMLParse([join "crank soap run step=$step buccaneer fragments" __])
	}
    }
    
    set numcycles 5

    if { [info exists XMLParse([join "crank soap run step=$step buccaneer num_cycles" __])] } {
	if { $XMLParse([join "crank soap run step=$step buccaneer num_cycles" __]) } {
	    set numcycles $XMLParse([join "crank soap run step=$step buccaneer num_cycles" __])
	}
    }

    set initial_cycles 3

    if { [info exists XMLParse([join "crank soap run step=$step buccaneer initial_cycles" __])] } {
	if { $XMLParse([join "crank soap run step=$step buccaneer initial_cycles" __]) } {
	    set initial_cycles $XMLParse([join "crank soap run step=$step buccaneer initial_cycles" __])
	}
    }

    set subsequent_cycles 2

    if { [info exists XMLParse([join "crank soap run step=$step buccaneer subsequent_cycles" __])] } {
	if { $XMLParse([join "crank soap run step=$step buccaneer subsequent_cycles" __]) } {
	    set subsequent_cycles $XMLParse([join "crank soap run step=$step buccaneer subsequent_cycles" __])
	}
    }

    set fastbuild 0

    if { [info exists XMLParse([join "crank soap run step=$step buccaneer fast_build" __])] } {
	if { $XMLParse([join "crank soap run step=$step buccaneer fast_build" __]) } {
	    set fastbuild 1
	}
    }

    if { $tcl } {
	puts "\#!/usr/bin/env tclsh" 
    } else {
	puts "\#!/bin/sh" 
    }

    puts " "

    if { [file exists [file join $env(CLIBD) reference_structures reference-1ajr.mtz]] } {
	set ref [file join $env(CLIBD) reference_structures] 
    } else {
	crank_error "crank::runbuccaneer:: no reference-1ajr.mtz found in subdirectory reference_structures of $CLIBD"
    } 

    if { $fastbuild } {

	puts "buccaneer -stdin << end-buccaneer > buccaneer-logfile"
	puts "mtzin-ref [file join $ref reference-1ajr.mtz]"
	puts "pdbin-ref [file join $ref reference-1ajr.pdb]"
	puts "colin-ref-fo /*/*/\[FP.F_sigF.F,FP.F_sigF.sigF\] "
	puts "colin-ref-hl /*/*/\[FC.ABCD.A,FC.ABCD.B,FC.ABCD.C,FC.ABCD.D\] "
	puts "mtzin-wrk $mtz_in"
	puts "colin-wrk-fo /*/*/\[$in_fp,$in_sigfp\] "
 	if { [info exists in_hla] } {
	    puts "colin-wrk-hl /*/*/\[$in_hla,$in_hlb,$in_hlc,$in_hld\] "
	} 
	
	if { [info exists in_fom] } {
	    puts "colin-wrk-phifom /*/*/\[$in_phib,$in_fom\] "
	}

	if { $in_freer != "" } {
	    puts "colin-wrk-free /*/*/\[$in_freer\] "
	}
	if { $in_seq != "" } {
	    puts "seqin-wrk $in_seq\nsequence\nsequence-reliability $reliable"
	}
	puts "find\ngrow\njoin\ncorrect\nprune\nrebuild "
	puts "fragments-per-100-residues $fragments "
	puts "end-buccaneer"
    } else {
	if { $tcl } {
 	    puts "set command \"ccp4-python -u [file join $env(CCP4) bin ccp4_pipeline_simple] < buccaneer-script > buccaneer-logfile\""
	    puts "eval exec \$command"
	} else {
 	    puts "ccp4-python -u [file join $env(CCP4) bin ccp4_pipeline_simple] < buccaneer-script > buccaneer-logfile"
	}

	set scr [open "buccaneer-script" w+ ]
	puts $scr "%loop-cyc $numcycles"
	puts $scr "%copy-pre $mtz_in temporary_refmac.mtz"
	if { [info exists input_pdb] } {
	    puts $scr "%copy-pre $input_pdb temporary_refmac.pdb"
	}
	puts $scr "%prgm-loop buccaneer cbuccaneer %exit"
 	if { $phase_restrain == "DIRECT"} {
	    if { $nc <= 0 } {
	      if { $inccp4 == "1" } {
			set add_heavy "add_heavy"
			set get_heavy "get_heavy"
			set del_heavy "del_heavy"
	      } else {
			set add_heavy [file join $env(CRANK) bin add_heavy]
			set get_heavy [file join $env(CRANK) bin get_heavy]
			set del_heavy [file join $env(CRANK) bin del_heavy]
	      }
		puts $scr "%prgm-loop join $add_heavy %exit"
	    }
		puts $scr "%prgm-loop check ccp4-python %exit"
	    puts $scr "%prgm-loop refmac refmac5 %exit"
	    if { $nc <= 0 } {
		puts $scr "%prgm-loop grab $get_heavy %exit"
	    }
	} else {
		puts $scr "%prgm-loop check ccp4-python %exit"
 	    puts $scr "%prgm-loop refmac refmac5 %exit"
	}
	puts $scr "%prgm-loop sft sftools %exit"
 	if { $phase_restrain == "DIRECT" && $nc <= 0 } {
		puts $scr "%prgm-loop delete $del_heavy %exit"
	}
	puts $scr "%copy-post temporary_refmac.pdb buccaneer.out.pdb"
	puts $scr "buccaneer %arg -stdin"
#	puts "buccaneer title [No title given]"
	puts $scr "buccaneer pdbin-ref [file join $ref reference-1ajr.pdb]"
	puts $scr "buccaneer mtzin-ref [file join $ref reference-1ajr.mtz]"
	puts $scr "buccaneer colin-ref-fo /*/*/\[FP.F_sigF.F,FP.F_sigF.sigF\]"
	puts $scr "buccaneer colin-ref-hl /*/*/\[FC.ABCD.A,FC.ABCD.B,FC.ABCD.C,FC.ABCD.D\]"
	puts $scr "buccaneer colin-wrk-fo /*/*/\[$in_fp,$in_sigfp\] "
#	if { [info exists in_hla] } {
#    puts $scr "buccaneer:0 colin-wrk-hl /*/*/\[$in_hla,$in_hlb,$in_hlc,$in_hld\] "
#} 
	if { [info exists in_fom] } {
	    puts $scr "buccaneer:0 colin-wrk-phifom /*/*/\[$in_phib,$in_fom\] "
	}
	puts $scr "buccaneer mtzin-wrk temporary_refmac.mtz"
	if { $in_freer != "" } {
	    puts $scr "buccaneer colin-wrk-free /*/*/\[$in_freer\] "
	}
	if { $in_seq != "" } {
	    puts $scr "buccaneer seqin-wrk $in_seq\nbuccaneer sequence"
	}
# 	if { $phase_restrain == "MLHL"} {
	    puts $scr "buccaneer:1-* colin-wrk-phifom /*/*/\[PHCOMB,FOM\]"
#	} else {
#	    puts $scr "buccaneer:1-* colin-wrk-phifom /*/*/\[PHWT,FOM\]"
#	}
	if { [info exists input_pdb] } {
	    puts $scr "buccaneer:0 pdbin-wrk temporary_refmac.pdb"
	}
	puts $scr "buccaneer:1-* pdbin-wrk temporary_refmac.pdb"
	puts $scr "buccaneer pdbout-wrk temporary_buccaneer.pdb"
	puts $scr "buccaneer find"
	puts $scr "buccaneer grow"
	puts $scr "buccaneer join"
	puts $scr "buccaneer link"
	puts $scr "buccaneer correct"
	puts $scr "buccaneer filter"
	puts $scr "buccaneer ncsbuild"
	puts $scr "buccaneer prune"
	puts $scr "buccaneer rebuild"
	puts $scr "buccaneer:0 cycles $initial_cycles"
	if { $in_seq != "" } {
	    puts $scr "buccaneer:0 sequence-reliability $reliable"
	}
	puts $scr "buccaneer:1-* cycles $subsequent_cycles"
	puts $scr "buccaneer:1-* correlation-mode"
	if { $in_seq != "" } {
	    puts $scr "buccaneer:1-* sequence-reliability $reliable"
	}
	puts $scr "buccaneer new-residue-name UNK"
	puts $scr "buccaneer resolution 2.0"
 	if { ($phase_restrain == "DIRECT") && ($nc <= 0) } {
	    puts $scr "join %arg temporary_buccaneer.pdb heavy.pdb"
    }
    # if no model is built then Crank won't crash later with unclear error message
    # but report that no model could be built instead
	set check_zero_res_path "[file join $env(CRANK) bin check_zero_res.py]"
	if { ![file exists $check_zero_res_path] } {
	  set check_zero_res_path "[file join $env(CCP4) bin check_zero_res.py]"
	}
	if { ![file exists $check_zero_res_path] } {
	  set check_zero_res_path "[file join $env(CCP4) share ccp4i bin check_zero_res.py]"
	}
	set temp_buc_full_path "[file join temporary_buccaneer.pdb]"
	set temp_buc_full_path "[file join temporary_buccaneer.pdb]"
	puts $scr "check %arg $check_zero_res_path $temp_buc_full_path"
	puts $scr "refmac %arg HKLIN $mtz_in"
	puts $scr "refmac %arg XYZIN temporary_buccaneer.pdb"
	puts $scr "refmac %arg HKLOUT temporary_refmac_aux.mtz"
	puts $scr "refmac %arg XYZOUT temporary_refmac.pdb"
 	if { ($phase_restrain == "DIRECT") && ($nc > 0) } {
	puts $scr "refmac %arg XYZIN2 heavy.pdb"
	puts $scr "refmac %arg XYZOUT2 heavy.pdb"
	}
#	puts "refmac title [No title given]"
	puts $scr "refmac weight MATRIX 0.1"
	puts $scr "refmac PHOUT"
	puts $scr "refmac labin FP=$in_fp SIGFP=$in_sigfp -"
	if { $in_freer != "" } {
	    puts $scr "refmac FREE=$in_freer -"
	} 
	if { $phase_restrain == "DIRECT"} {
  	  if { ($nc > 0) && ($maxc > 0) && ($maxd > 0) } {
	  # SIRAS function    
		set target SRAS
		puts $scr "refmac F_1=$in_fp SIGF_1=$in_sigfp F_2=$in_f_plus SIGF_2=$in_sigf_plus F_3=$in_f_minus SIGF_3=$in_sigf_minus"
		puts $scr "refmac    DATA DERI 0"
		puts $scr "refmac    DATA DERI 1 PLUS"
		puts $scr "refmac    DATA DERI 1 MINUS"
	  } else {
		set target SADH
		puts $scr "refmac F_1=$in_f_plus SIGF_1=$in_sigf_plus F_2=$in_f_minus SIGF_2=$in_sigf_minus"
	  }

	  puts $scr "refmac refi $target XNON NO"
	  set k 1
	  while { [info exists XMLParse([join "crank parameters crystal=$maxc data=$maxd atom=$k name" __])] } {
			set atomname $XMLParse([join "crank parameters crystal=$maxc data=$maxd atom=$k name" __])
		    set fprime $XMLParse([join "crank parameters crystal=$maxc data=$maxd atom=$k fprime" __])
		    set fprimeprime $XMLParse([join "crank parameters crystal=$maxc data=$maxd atom=$k fprimeprime" __])
		    puts $scr "refmac ANOM FORM $atomname $fprime $fprimeprime"
		    incr k
		}
 	} elseif { [info exists in_hla] } {
 	    puts $scr "refmac HLA=$in_hla  HLB=$in_hlb HLC=$in_hlc HLD=$in_hld"
	    puts $scr "refmac refi type REST PHASE SCBL 1.0 BBLU 0.0 resi MLKF meth CGMAT bref ISOT"
 	}
	puts $scr "refmac phout"
	puts $scr "refmac make check NONE"
	puts $scr "refmac make hydrogen YES hout NO peptide NO cispeptide YES ssbridge YES symmetry YES sugar YES connectivity NO link NO"
	puts $scr "refmac ncyc 10"
	puts $scr "refmac scal type SIMP LSSC ANISO EXPE"
	puts $scr "refmac solvent YES VDWProb 1.4 IONProb 0.8 RSHRink 0.8"
	puts $scr "refmac monitor MEDIUM torsion 10.0 distance 10.0 angle 10.0 plane 10.0 chiral 10.0 bfactor 10.0 bsphere 10.0 rbond 10.0 ncsr 10.0"
#	if { $phase_restrain == "MLHL"} {
	    puts $scr "refmac labout FC=FC FWT=FWT PHIC=PHIC PHWT=PHWT DELFWT=DELFWT PHDELWT=PHDELWT FOM=FOM PHCOMB=PHCOMB"
#	} else {
#	    puts $scr "refmac labout FC=FC FWT=FWT PHIC=PHIC PHWT=PHWT DELFWT=DELFWT PHDELWT=PHDELWT FOM=FOM"
#	}
	puts $scr "refmac PNAME buccaneer"
	puts $scr "refmac DNAME buccaneer"
	puts $scr "refmac RSIZE 80"
	puts $scr "refmac END"
	if { ($phase_restrain == "DIRECT") && ($nc <= 0) } {
	    puts $scr "grab %arg temporary_refmac.pdb heavy.pdb $atomname"
	}  
	puts $scr "sft %arg "
	puts $scr "sft read temporary_refmac_aux.mtz"
	puts $scr "sft delete col $in_fp $in_sigfp"
	puts $scr "sft read $mtz_in col $in_fp $in_sigfp"
	puts $scr "sft write temporary_refmac.mtz"
	puts $scr "sft Y"
	puts $scr "sft quit"
	puts $scr "sft Y"
	if { ($phase_restrain == "DIRECT") && ($nc <= 0) } {
	    puts $scr "delete %arg temporary_refmac.pdb temporary_refmac.pdb $atomname"
		puts $scr "check %arg $mtz_in $in_fp $in_sigfp $in_phib $in_fom"
	}  

	flush $scr
	close $scr
    }
}

global env

set inccp4   [lindex $argv 0]
set tcl      [lindex $argv 1]

set inputxml [file join .. xml input.xml]

source [file join $env(CRANK) bin crankutils.tcl]

if { [file exists $inputxml] == 0 } {
    crank_error "xml2buccaneerscript.tcl::inputxml file does not exist"
}


XMLParsefile $inputxml

OutputBuccaneerscriptfile $tcl $inccp4
