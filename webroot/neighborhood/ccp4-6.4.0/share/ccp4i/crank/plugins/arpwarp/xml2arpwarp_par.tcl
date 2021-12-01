#!/usr/bin/env tclsh

# Copyright (C) Navraj S. Pannu and Steven Ness 2004-2005, Leiden University
# Copyright (C) Navraj S. Pannu 2006-2007, Leiden University
#
# All rights reserved.
# This file may not be copied, reproduced, modified or distributed
# in any way.
#
#
# From the output of mtz dump get
# 1) Resolution Range
# 2) Spacegroup
# 3) Cell dimensions
#
proc get_mtzdump_params { inputmtz } {
    global resol cell sym high
    global XMLParse

    set mtz_command "HKLIN $inputmtz"

    set mtz_script "NREF 0\nGO\nEND"
 
    set command "mtzdump $mtz_command << \"$mtz_script\""
    catch {eval exec $command } output 
    #puts $output

    if { ! [regexp {.*Resolution Range :[\n ]* *[0-9.]* *[0-9.]* *. *([0-9.]*) *- *([0-9.]*)} $output match low high]} {
	puts "xml2arpwarpparl.tcl::Resolution range::not found"
    } 

    if { ! [regexp {.*Space group.*number *([0-9]*)} $output match spacegroup_number]} {
	puts "xml2arpwarppar.tcl::Space group::not found"
    }

    set cr $XMLParse([join "crank parameters ref_crystal" __])

    set a $XMLParse([join "crank parameters crystal=$cr cell cell_a" __])
    set b $XMLParse([join "crank parameters crystal=$cr cell cell_b" __])
    set c $XMLParse([join "crank parameters crystal=$cr cell cell_c" __])
    set alpha $XMLParse([join "crank parameters crystal=$cr cell cell_alpha" __])
    set beta $XMLParse([join "crank parameters crystal=$cr cell cell_beta" __])
    set gamma $XMLParse([join "crank parameters crystal=$cr cell cell_gamma" __])

    set sftools_script "read $inputmtz\nlist dcell\nquit\ny\n"
    set command "sftools << \"$sftools_script\""
    catch {eval exec $command } output
    set data $output
    set data [split $data "\n"]
    set sftools_script "read $inputmtz"
    foreach line $data {
	regsub -all {\s+} $line " " line
	if { [regexp { *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*) *([0-9.]*) *([A-Z0-9a-z]*).*} $line junk a1 b1 c1 alpha1 beta1 gamma1 name] } {
 	    if { ($a1 != "") && ($gamma1 != "") } {
		set sftools_script "$sftools_script\n set dcell\n $a $b $c $alpha $beta $gamma $name" 
 	    }
	}
    }

    set sftools_script "$sftools_script\n write $inputmtz\ny\nquit\n"

    set command "sftools << \"$sftools_script\""
    catch {eval exec $command } output
#    puts $output

    set cell "$a $b $c $alpha $beta $gamma"

    # This should be an externally coded rule
    if { $low < 20.0 } {
	set resol "20.0 $high"
    } else {
	set resol "$low $high"
    }

    set sym $spacegroup_number
}

proc get_arpwarp_asymmetric_unit { inputmtz } {
    global xyzlim

    set name ""
    set number "" 

    spacegroup_from_mtz $inputmtz name number

    set xyzlim "" 
    arpwarp_asu $number xyzlim
}


proc OutputARPWARPcomfile { inputmtz heavyin } {
    global XMLParse
    global resol cell sym xyzlim high

    set step $XMLParse(crank__soap__current_step)
    set orig_pwd $XMLParse(crank__soap__orig_pwd)

    set workdir [file join [pwd]]
    set dummydef [file join [pwd] dummy.def]

    ############################################################
    #   Set par variables to default values from auto_warp.sh  #
    ############################################################
    #
    # This section is necessary so that we make sure we have
    # all these variables defined for when we create the parfile
    # below, Tcl doesn't like it when we try to use an undefined
    # value.  These defaults are then overwritten later by values read
    # in from the input XML file.
    #
    set par_WORKDIR "$workdir"
    set par_PROJECT "SUBMITTED_VIA_CRANK"
    set par_JOB_ID "1"
    set par_arpwarpdir "run"
    set par_CCP4I_DEFFILE "$dummydef"
    set par_datafile "$inputmtz"
    set par_phaselabin "' '"
    set par_phaseref ""
    set par_modelin "''"
    set par_seqin ""
    set par_tlsin "''"
    set par_libin "''"
    set par_protsize ""
    set par_wilsonb ""
    set par_solventc ""
    set par_fp ""
    set par_sigfp ""
    set par_fbest ""
    set par_phibest ""
    set par_fom ""
    set par_restrcyc ""
    set par_restrref ""
    set par_cgr ""
    set par_wmat "AUTO"
    set par_weightv " "
    set par_models "1"

    set par_whichtrace "1"
    if { [info exists XMLParse([join "crank soap run step=$step arpwarp use_six" __])] } {
	if { $XMLParse([join "crank soap run step=$step arpwarp use_six" __]) } {
	    set par_whichtrace "0"
	}
    }
    set par_tlsonoff "0"
    set par_solvent "0"
    set par_flatten "0"
    set par_freebuild "0"
    set par_sym ""
    set par_cell ""
    set par_scanis "Y "
    set par_xyzlim ""
    set par_damp "' 0.4 0.4  '"
    set par_resol ""
    set par_scaleopt "' BULK LSSC ANIS '"
    set par_freelabin ""
    set par_scalml "' SCAL MLSC WORK '"
    set par_scale "' BULK '"
    set par_refmax "MLKF"
    set par_refmeth "CGMAT"
    set par_freer "Y"
    set par_freerml "Y"
    set par_rrcyc "3"
    set par_phaseres "N"
    set par_phasblur "1.0"
    set par_cycskip "0"
    set par_skip "0"
    set par_flagk "1"
    set par_truncshifts "1"
    set par_multit "5"
    set par_upmore "1"
    set par_side "-1"
    set par_fsig "3.2"
    set par_rsig "1.0"
    set par_newrefmac "1"
    set par_flagf "0"
    set par_randtimes "0"
    set par_rand1 "10"
    set par_randshift1 "0.5"
    set par_bcut1 "2.0"
    set par_rand2 "20"
    set par_randshift2 "0.5"
    set par_bcut2 "2.0"
    set par_rand3 "30"
    set par_randshift3 "0.5"
    set par_bcut3 "2.0"
    set par_keepdata "WORLD"
    set par_remote "0"
    set par_remoteemail ""
    set par_ridgerestraints "0"
    set par_compareto ""
    set par_fakedata "0 0 0"
    set par_keepjunk "0"

    # The new additional parameters for refmac5
    set par_HEAVYIN ""
    set par_F_1 ""
    set par_SIGF_1 ""
    set par_F_2 ""
    set par_SIGF_2 ""
    set par_ANAF ""
    set par_HREF ""

    ############################################################
    #     Set variables based on values in input.xml file      #
    ############################################################

    ###############################
    #      Input MTZ columns     #
    ##############################

    set c $XMLParse([join "crank parameters ref_crystal" __])
    set d $XMLParse([join "crank parameters ref_dataset" __])

    # F columns
    if { [info exists XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d f" __])] } {
	set in_fp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d f" __])
	set in_sigfp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d sigf" __])
    } else {
	set in_fp ""
	set in_sigfp ""
	crank_error "xml2arpwarp_par.tcl::exp_columns__f is not set"
    }

    # Phase columns
    if { [info exists XMLParse([join "crank soap run step=$step input phase_columns phib" __])] } {
	set in_phib $XMLParse([join "crank soap run step=$step input phase_columns phib" __])
	set in_fom $XMLParse([join "crank soap run step=$step input phase_columns fom" __])
    } else {
	set in_phib ""
	set in_fom ""
	crank_error "xml2arpwarp_par.tcl::phase_columns__phib is not set"		
    }

    # HL columns
    if { [info exists XMLParse([join "crank soap run step=$step input hl_columns hla" __])] } {
	set in_hla $XMLParse([join "crank soap run step=$step input hl_columns hla" __])
	set in_hlb $XMLParse([join "crank soap run step=$step input hl_columns hlb" __])
	set in_hlc $XMLParse([join "crank soap run step=$step input hl_columns hlc" __])
	set in_hld $XMLParse([join "crank soap run step=$step input hl_columns hld" __])
    } else {
	set in_hla ""
	set in_hlb ""
	set in_hlc ""
	set in_hld ""
#	puts "xml2arpwarp_par.tcl::hla_columns__hla is not set"
    }

    # FreeR columns
    if { [info exists XMLParse([join "crank soap run step=$step input freer_columns freer" __])] } {
	set in_freer $XMLParse([join "crank soap run step=$step input freer_columns freer" __])
    } 

    # Set the par variables
    set par_fp "$in_fp"
    set par_sigfp "$in_sigfp"
    set par_fbest "$in_fp"
    set par_phibest "$in_phib"
    set par_fom "$in_fom"

    ######################################################
    # Global values calculated previously in this script #
    ######################################################

    set par_resol "'  $resol  '"
    set par_cell "' $cell '"
    set par_sym "$sym"
    set par_xyzlim "' $xyzlim  '"

    #####################################
    #   crank__parameters variables   #
    #####################################

    # Number of molecules in the asymmetric unit cell
    if { [info exists XMLParse([join "crank update nmonomers" __])] } {
	set par_cgr $XMLParse(crank__update__nmonomers)
	set par_solventc $XMLParse(crank__update__solvent_content)
    } else {
	set par_cgr $XMLParse(crank__parameters__nmonomers)
	set par_solventc $XMLParse(crank__parameters__solvent_content)
    }

    # Protein size (protsize = NRES * 8)
    # Taken directly from ARP/wARP interface
    set par_protsize [expr $XMLParse(crank__parameters__residues) * 8 * $par_cgr ]
    if { $par_protsize > 18250 } {
       set par_protsize 18250
    }
    # B-factor 
    set par_wilsonb $XMLParse(crank__parameters__bfactor)

    # Global ARP/wARP parameters 

    # ARPWARP_SIDE_AFTER

    if { [file exists [file join [pwd] sequence.pir] ] } {
	set par_seqin [file join [pwd] sequence.pir]
    }

    set par_modeccp4i "WARPNTRACEPHASES"

    if { [info exists XMLParse([join "crank soap run step=$step input pdb" __])] } {
        if { $XMLParse([join "crank soap run step=$step arpwarp no_use_pdb" __]) == "0" } {
	    set pdb_tag $XMLParse([join "crank soap run step=$step input pdb" __])
	    if { [file exists [file join $orig_pwd workdb crank.out.$pdb_tag.pdb] ] } {
                set par_modelin "[file join $orig_pwd workdb crank.out.$pdb_tag.pdb] "
		set par_modeccp4i "WARPNTRACEMODEL"
            }
        }
    }

    if { $par_seqin != "" } {
	set side $XMLParse([join "crank soap run step=$step arpwarp side_after" __])
	set par_side "$side"
    }

    # combined
	set combined 0
    if { [info exists XMLParse([join "crank soap run step=$step arpwarp combined_dmmb" __])] } {
      set combined [string trim $XMLParse([join "crank soap run step=$step arpwarp combined_dmmb" __])]
    }

    #    Required parameters     

    # ARPWARP_BIG_CYCLES and ARPWARP_SMALL_CYCLES

    set smallcycles $XMLParse([join "crank soap run step=$step arpwarp small_cycles" __])
    set bigcycles $XMLParse([join "crank soap run step=$step arpwarp big_cycles" __])
    if { $combined } {
      if { $high > 2.5 } {
        set smallcycles 1
      } else {
        set smallcycles 3
      }
    }
    set par_restrcyc "[expr $bigcycles * $smallcycles]"
    set par_restrref "$smallcycles"

    # ARPWARP_REF_MODE

    # ARPWARP_FREER

    set exclude_freer $XMLParse([join "crank soap run step=$step arpwarp exclude_freer" __])
    if { $exclude_freer == "Y" } {
	set par_freer "Y"
	set par_freelabin " FREE=$in_freer "
    } else {
	set par_freer ""
	set par_freelabin ""
    }

    if { [info exists XMLParse([join "crank soap run step=$step arpwarp cv_sigmaa" __]) ] } {
	set par_freelabin " FREE=$in_freer "
	set par_freerml $XMLParse([join "crank soap run step=$step arpwarp cv_sigmaa" __])
    } else {
	set par_freerml ""
    }

    #  ARP/wARP flow parameters  

    #  Refmac Parameters     


    #
    # ARPWARP_NCYCLES
    #
    set ncycles $XMLParse([join "crank soap run step=$step arpwarp ncycles" __])
    set par_rrcyc "$ncycles"
    #if { $combined } {
    #  set par_rrcyc "5"
    #}

    #
    # ARPWARP_PHASE_BLUR
    #
    set phase_blur $XMLParse([join "crank soap run step=$step arpwarp phase_blur" __])
    set par_phasblur "$phase_blur"

    #
    # ARPWARP_DAMP_P and ARPWARP_DAMP_B
    #
    set damp_p $XMLParse([join "crank soap run step=$step arpwarp damp_p" __])
    set damp_b $XMLParse([join "crank soap run step=$step arpwarp damp_b" __])
    set par_damp "$damp_p $damp_b"

    #
    # ARPWARP_WEIGHT_MODE and ARPWARP_WMAT
    #
    # par_wmat is not the same as ARPWARP_WMAT, it is the string "AUTO" or "MATRIX".
    # ARPWARP_WMAT gets assigned to par_weightv. 
    #
    set weight_mode $XMLParse([join "crank soap run step=$step arpwarp weight_mode" __])
    set wmat $XMLParse([join "crank soap run step=$step arpwarp phase_blur" __])
    if { $weight_mode == "AUTO" } {
	set par_wmat "AUTO"
	set par_weightv " "
    } else {
	set par_wmat "MATRIX"
	set par_weightv "$wmat"
    }

    #
    # ARPWARP_SCALE and ARPWARP_SCANIS
    #
    set scale $XMLParse([join "crank soap run step=$step arpwarp scale" __])
    set scanis $XMLParse([join "crank soap run step=$step arpwarp scanis" __])
    set par_scale "$scale"
    if { $scanis == "Y" } { 
	set par_scaleopt "$scale LSSC ANIS"
    } else {
	set par_scaleopt "$scale"
    }

    #
    # ARPWARP_REFMAC_REF_SET
    #
    set refmac_ref_set $XMLParse([join "crank soap run step=$step arpwarp refmac_ref_set" __])
    if { $refmac_ref_set == "Y" } {
	set par_scalml "SCAL MLSC"
    } else {
	set par_scalml "SCAL MLSC WORK"
    }

    #
    # ARPWARP_SOLVENT
    #
    set solvent $XMLParse([join "crank soap run step=$step arpwarp solvent" __])
    set par_solvent "$solvent"

    #
    # ARPWARP_TLSONOFF
    #
    set tlsonoff $XMLParse([join "crank soap run step=$step arpwarp tlsonoff" __])
    set par_tlsonoff "$tlsonoff"


    ##############################
    #      Phase restraints      #
    ##############################

    if { [info exists XMLParse([join "crank soap run step=$step arpwarp phase_restrain" __])] } {
	set phase_restrain $XMLParse([join "crank soap run step=$step arpwarp phase_restrain" __])
    } else {
	crank_error "xml2arpwarp_par.tcl::not found - crank soap run step=$step arpwarp phase_restrain"
    }

    if { $phase_restrain == "NO" } {
	set par_phaseres N
	set par_phaselabin "' ' "
	set par_phaseref "' ' "
    } elseif { $phase_restrain == "MLHL" } {
	set par_phaseres ML
	set par_phaselabin "' HLA=$in_hla HLB=$in_hlb HLC=$in_hlc HLD=$in_hld '"
	set par_phaseref "' PHAS SCBL 1.0 '"
    } elseif { $phase_restrain == "DIRECT" } {

	set nxtal 0
	set i 1
	while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } {
	    set j 1
	    while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } {

		if { $XMLParse([join "crank parameters crystal=$i native" __]) == "0"  } {
		    set k 1
		    while { [info exists XMLParse([join "crank parameters crystal=$i data=$j atom=$k name" __])] } {
			set heavy_atom($i,$j,$k) $XMLParse([join "crank parameters crystal=$i data=$j atom=$k name" __])
			if { [string compare $heavy_atom($i,$j,$k) "SE"] == 0 } {
			    set is_semet 1
			}
			set fprime($i,$j,$k) $XMLParse([join "crank parameters crystal=$i data=$j atom=$k fprime" __])
			set fprimeprime($i,$j,$k) $XMLParse([join "crank parameters crystal=$i data=$j atom=$k fprimeprime" __])
			incr k
		    }
		} 
		if { $XMLParse([join "crank parameters crystal=$i data=$j anomalous" __]) == "0"  } {
		    set f($i) $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=1 f" __])
		    set sigf($i) $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=1 sigf" __])
		} else {
		    set f_plus($i,$j) $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j f_plus" __])
		    set sigf_plus($i,$j) $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j sigf_plus" __])
		    set f_minus($i,$j) $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j f_minus" __])
		    set sigf_minus($i,$j) $XMLParse([join "crank soap run step=$step input exp_columns crystal=$i data=$j sigf_minus" __])
		} 
		incr j
	    }
	    incr i
	    incr nxtal
	}

	# Set the atom parameters and refinement options
	# set href "OCTE"
	set href ""

	#
	# Set the par variables
	#
	
	# Set standard ARP/wARP parameters
	set par_phaseres N
	set par_phaselabin "' '"

	if { $nxtal > 1 } {
 	    if { [info exists f_plus(2,1)] } {
		# siras function
		# set href "NO"
 		set par_phaseref "'SRAS'"
		set par_F_2 "' $f_plus(2,1) '"
		set par_SIGF_2 "' $sigf_plus(2,1) '"
		set par_F_3 "' $f_minus(2,1) '"
		set par_SIGF_3 "' $sigf_minus(2,1) '"
		set par_ANAF "' FORM $heavy_atom(2,1,1) $fprime(2,1,1) $fprimeprime(2,1,1) '"
		set par_HREF ""
		set par_HEAVYIN "'$heavyin'"
		if { [info exists f(1)] } {
		    set par_F_1 "' $f(1) '"
		    set par_SIGF_1 "' $sigf(1) '"
		} else {
 		    set par_F_1 "' $f_plus(1,1) '"
		    set par_SIGF_1 "' $sigf_plus(1,1) '"
		}
	    } elseif { [info exists f(2)] } {
  		set par_phaseref "'SIR'"
		set par_F_2 "' $f(2) '"
		set par_SIGF_2 "' $sigf(2) '"
		set par_ANAF "' FORM $heavy_atom(2,1,1) $fprime(2,1,1) $fprimeprime(2,1,1) '"
		set par_HREF ""
		set par_HEAVYIN "'$heavyin'"
		if { [info exists f(1)] } {
		    set par_F_1 "' $f(1) '"
		    set par_SIGF_1 "' $sigf(1) '"
		} else {
 		    set par_F_1 "' $f_plus(1,1) '"
		    set par_SIGF_1 "' $sigf_plus(1,1) '"
		}
	    } else {
		crank_error "xml2arpwarp_par.tcl SIRAS function expects native to be defined first"
	    }
	} else {
	    # Set parameters specific to the SAD target
	    # only SAD at the moment for refmac, so find crystal and data set with maximal f"
	    set maxa 0
	    set maxc 0
	    set maxd 0
	    set maxfpp 0

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
				set maxa $k
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
		crank_error "Only SAD data is supported in refmac at the moment, so one anomalous data set is needed"
	    }

	    set in_fp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd f" __])
	    set in_sigfp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd sigf" __])
	    if { [info exists f_plus($c,$d)] } {
		set par_F_1 "' $f_plus($maxc,$maxd) '"
		set par_SIGF_1 "' $sigf_plus($maxc,$maxd) '"
		set par_F_2 "' $f_minus($maxc,$maxd) '"
		set par_SIGF_2 "' $sigf_minus($maxc,$maxd) '"
		set k 1
		set atoms ""
		while { [info exists XMLParse([join "crank parameters crystal=$maxc data=$maxd atom=$k name" __])] } {
		    set atomname $XMLParse([join "crank parameters crystal=$maxc data=$maxd atom=$k name" __])
		    set atoms "$atoms FORM $heavy_atom($maxc,$maxd,$k) $fprime($maxc,$maxd,$k) $fprimeprime($maxc,$maxd,$k)"
  		    incr k
		}
		set par_ANAF "'$atoms'"
		set par_HREF ""
		set par_HEAVYIN "'$heavyin'"
		set par_phaseref "'SADH'"
	    } else {
		 crank_error "xml2arpwarp_par.tcl SAD function requested with non-anomalous reference data set"
	    }
	}     
    }

    ############################################################
    #                  Create .par file                        #
    ############################################################

    puts "set parfile = $par_WORKDIR/1_arp_warp.par"
    puts "set version = 7.0"
    puts "set WORKDIR = $par_WORKDIR"
    puts "set PROJECT = $par_PROJECT"
    puts "set JOB_ID = $par_JOB_ID"
    puts "set arpwarpdir = $par_arpwarpdir"
    puts "set CCP4I_DEFFILE = $par_CCP4I_DEFFILE"
    puts "set datafile = $par_datafile"
    puts "set modelin = $par_modelin"
    puts "set seqin = $par_seqin"
    puts "set tlsin = $par_tlsin"
    puts "set libin = $par_libin"
    puts "set protsize = $par_protsize"
    puts "set wilsonb = $par_wilsonb"
    puts "set solventc = $par_solventc"
    puts "set fp = $par_fp"
    puts "set sigfp = $par_sigfp"
    puts "set fbest = $par_fbest"
    puts "set phibest = $par_phibest"
    puts "set fom = $par_fom"
    puts "set restrcyc = $par_restrcyc"
    puts "set restrref = $par_restrref"
    puts "set cgr = $par_cgr"
    puts "set wmat = $par_wmat"
    puts "set weightv = $par_weightv"	
    puts "set models = $par_models"
    puts "set whichtrace = $par_whichtrace"
    puts "set tlsonoff = $par_tlsonoff"
    puts "set solvent = $par_solvent"
    puts "set flatten = $par_flatten"
    puts "set freebuild = $par_freebuild"
    puts "set sym = $par_sym"
    puts "set cell = $par_cell"
    puts "set scanis = $par_scanis"
    puts "set xyzlim = $par_xyzlim"
    puts "set damp = ' $par_damp '"
    puts "set resol = $par_resol"
    puts "set scaleopt = ' $par_scaleopt '"
    puts "set freelabin = '$par_freelabin'"
    puts "set scalml = ' $par_scalml '"
    puts "set scale = ' $par_scale '"
    puts "set phaselabin = $par_phaselabin"
    puts "set phaseref = $par_phaseref"
    puts "set albe = ' 0 '"
    puts "set refmax = $par_refmax"
    puts "set refmeth = $par_refmeth"
    puts "set freer = $par_freer"
    puts "set freerml = $par_freerml"
    puts "set rrcyc = $par_rrcyc"
    puts "set phaseres = $par_phaseres"
    puts "set phasblur = $par_phasblur"
    puts "set cycskip = $par_cycskip"
    puts "set skip = $par_skip"
    puts "set flagk = $par_flagk"
    puts "set truncshifts = $par_truncshifts"
    puts "set multit = $par_multit"
    puts "set upmore = $par_upmore"
    puts "set ridgerestraints = $par_ridgerestraints"
    puts "set compareto = $par_compareto"
    puts "set fakedata = '$par_fakedata'"
    puts "set keepjunk = $par_keepjunk"
    puts "set side = $par_side"
    puts "set fsig = $par_fsig"
    puts "set rsig = $par_rsig"
    puts "set newrefmac = $par_newrefmac"
    puts "set modeccp4i = $par_modeccp4i"
    puts "set flagf = $par_flagf"
    puts "set randtimes = $par_randtimes"
    puts "set rand1 = $par_rand1"
    puts "set randshift1 = $par_randshift1"
    puts "set bcut1 = $par_bcut1"
    puts "set rand2 = $par_rand2"
    puts "set randshift2 = $par_randshift2"
    puts "set bcut2 = $par_bcut2"
    puts "set rand3 = $par_rand3"
    puts "set randshift3 = $par_randshift3"
    puts "set bcut3 = $par_bcut3"
    puts "set keepdata = $par_keepdata"
    puts "set remote = $par_remote"
    puts "set remoteemail = $par_remoteemail"
    puts ""
    puts "set HEAVYIN = $par_HEAVYIN"
# ***NSP
    puts "set heavyin = $par_HEAVYIN"

    set is_semet 0
    set i 1
    while { [info exists XMLParse([join "crank parameters crystal=$i data=1 type" __])] } {
	set j 1
	while { [info exists XMLParse([join "crank parameters crystal=$i data=$j type" __])] } {

	    if { $XMLParse([join "crank parameters crystal=$i native" __]) == "0"  } {
		set k 1
		while { [info exists XMLParse([join "crank parameters crystal=$i data=$j atom=$k name" __])] } {
		    if { [string compare $XMLParse([join "crank parameters crystal=$i data=$j atom=$k name" __]) "SE"] == 0 } {
			set is_semet 1
		    }
		    incr k
		}
	    } 
	    incr j
	}
	incr i
    }
    puts "set is_semet = $is_semet"

    set restraints 1
    if { [info exists XMLParse([join "crank soap run step=$step arpwarp conditional_dynamics" __])] } {
	set restraints $XMLParse([join "crank soap run step=$step arpwarp conditional_dynamics" __])
    }     
    puts "set restraints = $restraints"

    set loops 1
    if { [info exists XMLParse([join "crank soap run step=$step arpwarp loops" __])] } {
	set loops $XMLParse([join "crank soap run step=$step arpwarp loops" __])
    }     
    puts "set loops = $loops"

    set twin 0

    if { [info exists XMLParse([join "crank soap run step=$step arpwarp twin" __])] } {
	set twin $XMLParse([join "crank soap run step=$step arpwarp twin" __])
    }
    if { $phase_restrain == "DIRECT" } {
	puts "set twin = 0"
    } else {
	puts "set twin = $twin"
    }

# NCS 

    if { [info exists XMLParse([join "crank soap run step=$step arpwarp ncsrestraints" __])] } {
	if { $XMLParse([join "crank soap run step=$step arpwarp ncsrestraints" __]) == "0" } {
	    puts "set ncsrestraints = 0" 
	} else {
	    puts "set ncsrestraints = 1"
	}
    } else {
	puts "set ncsrestraints = 1"
    }

    if { [info exists XMLParse([join "crank soap run step=$step arpwarp ncsextension" __])] } {
	if { $XMLParse([join "crank soap run step=$step arpwarp ncsextension" __]) == "0" } {
	    puts "set ncsextension = 0" 
	} else {
	    puts "set ncsextension = 1"
	}
    } else {
	puts "set ncsextension = 1"
    }

    if { [info exists XMLParse([join "crank soap run step=$step arpwarp hmainpostfit" __])] } {
	if { $XMLParse([join "crank soap run step=$step arpwarp hmainpostfit" __]) == "0" } {
	    puts "set hmainpostfit = 0" 
	} else {
	    puts "set hmainpostfit = 1"
	}
    } else {
	puts "set hmainpostfit = 1"
    }

    puts "set sad = 0"
    puts "set sadcard = 0"

    if { ($phase_restrain == "DIRECT") } {
        if { $par_phaseref == "'SRAS'" } {
           puts "set DATA = 'DERI 0'"
        }
	puts "set F_1 = $par_F_1"
	puts "set SIGF_1 = $par_SIGF_1"
        if { $par_phaseref == "'SRAS'" } {
           puts "set DATA = 'DERI 1 PLUS'"
        }

	puts "set F_2 = $par_F_2"
	puts "set SIGF_2 = $par_SIGF_2"

	if { $par_phaseref == "'SRAS'" } {
           puts "set DATA = 'DERI 1 MINUS'"
	   puts "set F_3 = $par_F_3"
	   puts "set SIGF_3 = $par_SIGF_3"
	}

	puts "set ANOM = $par_ANAF"
    if { $combined } {
	  puts "set DM = $par_solventc"
    }
#	puts "set HREF = $par_HREF"
    }
}

if { [lindex $argv 1] == "" } {
	puts "Usage:"
	puts "xml2arpwarp_par.tcl input.xml input.mtz heavyin"
	puts " "
	puts " Where:"
	puts "   input.xml - Input .xml file containing commands and data"
	puts "   input.mtz - Input MTZ file"
	puts "   heavyin - Input heavy atom .pdb file"
	puts ""
	puts "Copyright (c) Leiden University"
	exit
}


#
# Setup variable names
#
set inputxml [lindex $argv 0]
set inputmtz [lindex $argv 1]
set crankbin [lindex $argv 2]
set heavyin  [lindex $argv 3]

if { ![file exists $inputxml] } {
    crank_error "xml2arpwarpparcom.tcl::inputxml file $inputxml does not exist"
}

if { ![file exists $inputmtz] } {
    crank_error "xml2arpwarpparcom.tcl::inputxml file $inputmtz does not exist"
}

source [file join $crankbin crankutils.tcl]

XMLParsefile $inputxml

get_mtzdump_params $inputmtz

get_arpwarp_asymmetric_unit $inputmtz

OutputARPWARPcomfile $inputmtz $heavyin 

