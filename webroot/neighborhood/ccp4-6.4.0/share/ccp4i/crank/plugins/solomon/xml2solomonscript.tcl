#!/usr/bin/env tclsh
#
# Copyright (C) Navraj S. Pannu and Jan Pieter Abrahams 2006, Leiden University
#
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

#PS: to be (possibly) implemented: 
#  parrot flattening - seems not possible???
#  sigmaa (PHIBP=$in_phib WP=$in_fom) ?

proc OutputSolomonscriptfile { ncycles solv enant nomtz flattened inccp4 hand bias solomon dm_step } {
    global XMLParse
    global env

    set step $XMLParse(crank__soap__current_step)
    set orig_pwd $XMLParse(crank__soap__orig_pwd)
    set tag [string trim $XMLParse([join "crank soap run step=$step tag" __])]


    # DM program
    if { $solomon } {
      set denmod "solomon"
    } else {
      set denmod "parrot"
    }

    # input mtz
    set rel_path ""
    if { [file exists [file join .. workdb crank.in.$tag.mtz] ] } {
      set rel_path "[file join .. workdb]"
    } elseif { [file exists [file join .. .. workdb crank.in.$tag.mtz] ] } {
      set rel_path "[file join .. .. workdb]"
    } else {
      crank_error "input mtz file does not exist"
    }

    if { $enant == "1" } {
      set mtz_in "[file join $rel_path crank.in.$tag.mtz]"
    } else {
      set mtz_in "[file join $rel_path crank.in.$tag.oh.mtz]"
    } 

    # find crystal and data set with maximal f" and native (if exists)
    set maxa 0
    set maxc 0
    set maxd 0
    set nc 0
    set maxfpp 0
    set c $XMLParse([join "crank parameters ref_crystal" __])
    set d $XMLParse([join "crank parameters ref_dataset" __])
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
                        set maxa $k
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


    # program/target
    set phcomb_prog "multicomb"
    set mlhl 0
    set dm2 0
    set siras 0

    if { [info exists XMLParse([join "crank soap run step=$dm_step $denmod phase_comb" __])] && !$hand } {
      if { $XMLParse([join "crank soap run step=$dm_step $denmod phase_comb" __]) == "DIRECT" } {
        set phcomb_prog "multicomb"
      } elseif { $XMLParse([join "crank soap run step=$dm_step $denmod phase_comb" __]) == "REFMAC" } {
        set phcomb_prog "refmac"
        # refmac siras
        if { ($nc > 0) && ($maxc > 0) && ($maxd > 0) } {
          set dm2 1
          set siras 1
        }
      } elseif { $XMLParse([join "crank soap run step=$dm_step $denmod phase_comb" __]) == "SIGMAA" } {
        set phcomb_prog "sigmaa"
      } elseif { $XMLParse([join "crank soap run step=$dm_step $denmod phase_comb" __]) == "DM2" } {
        set dm2 1
      } else {
        set mlhl   1
      }
    } else {
      set mlhl 1
    }

    # binaries
    set phcomb_exec $phcomb_prog
    set denmod_exec $denmod
    if { [string compare $denmod "parrot"] == 0 } {
      set denmod_exec "cparrot"
    }
    if { [string compare $phcomb_exec "refmac"] == 0 } {
      set phcomb_exec "refmac5"
    }
    if { $inccp4 != "1" } {
      if { [string compare $phcomb_prog "multicomb"] == 0 } {
        set phcomb_exec [file join $env(CRANK) bin multicomb]
      }
      if { [string compare $denmod "solomon"] == 0 } {
        set denmod_exec [file join $env(CRANK) bin solomon]
      }
    }

    # data columns
    if { ($nc > 0) } {
      set in_fp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$nc data=1 f" __])
      set in_sigfp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$nc data=1 sigf" __])
    } else {
      set in_fp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d f" __])
      set in_sigfp $XMLParse([join "crank soap run step=$step input exp_columns crystal=$c data=$d sigf" __])
    }

    if { ($maxc > 0) && ($maxd > 0) } {
      set in_f_plus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd f_plus" __])
      set in_sigf_plus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd sigf_plus" __])
      set in_f_minus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd f_minus" __])
      set in_sigf_minus $XMLParse([join "crank soap run step=$step input exp_columns crystal=$maxc data=$maxd sigf_minus" __])
    } else {
      set mlhl 1
    }

    # HL columns
    if { [info exists XMLParse([join "crank soap run step=$step input hl_columns hla" __])] &&
	  [string compare $XMLParse([join "crank soap run step=$step input hl_columns hla" __]) "NONE"] != 0 } {
	set in_hla $XMLParse([join "crank soap run step=$step input hl_columns hla" __])
	set in_hlb $XMLParse([join "crank soap run step=$step input hl_columns hlb" __])
	set in_hlc $XMLParse([join "crank soap run step=$step input hl_columns hlc" __])
	set in_hld $XMLParse([join "crank soap run step=$step input hl_columns hld" __])
    }

    # input substructure
    set heavy_pdb ""
    if { [info exists XMLParse([join "crank soap run step=$step input substructure" __])] } {
      set subtag [string trim $XMLParse([join "crank soap run step=$step input substructure" __])]
      if { $enant == "1" } {
        set heavy_pdb "[file join $rel_path crank.out.$subtag.substructure.pdb]"
      } else {
        set heavy_pdb "[file join $rel_path crank.out.$subtag.oh.substructure.pdb]"
      }
    }
    if { !$mlhl && ![string compare $phcomb_prog "sigmaa"] == 0 } {
      if { ! [file exists $heavy_pdb] } {
        crank_error "input substructure pdb file does not exist"
      }
    }

    # fix some refmac input heavy atoms (IOD,SO4)
    if { [string compare $phcomb_prog "refmac"] == 0 && [string compare $heavy_pdb ""] != 0 } {
            check_refmac_substructure $heavy_pdb "$heavy_pdb.reffix.pdb"
			set heavy_pdb "$heavy_pdb.reffix.pdb"
    }

    # do we have combined dm+mb
	set combined 0
	set start_dm 1
    set refdm_intcyc 0
    if { $step!=$dm_step } {
      # if called from MB step then we are certainly combined and won't include initial DM in combined
      set combined 1
      set start_dm 0
	} else {
      if { [info exists XMLParse([join "crank soap run step=$dm_step $denmod combined_dmmb" __])] } {
        set combined [string trim $XMLParse([join "crank soap run step=$dm_step $denmod combined_dmmb" __])]
      }
	}

    # some combined specific parameters
    if { $combined } {
      set refdm_intcyc 1
      # Free R column
      set in_freer ""
      if { [info exists XMLParse([join "crank soap run step=$step input freer_columns freer" __])] } {
        set in_freer $XMLParse([join "crank soap run step=$step input freer_columns freer" __])
      }
      if { [info exists XMLParse([join "crank soap run step=$step buccaneer nousefreer" __])] } {
        if { $XMLParse([join "crank soap run step=$step buccaneer nousefreer" __]) } {
            set in_freer ""
        }
      }
      set buc_build_init_cyc 3
      if { [info exists XMLParse([join "crank soap run step=$step buccaneer initial_cycles" __])] } {
	    set buc_build_init_cyc $XMLParse([join "crank soap run step=$step buccaneer initial_cycles" __])
      }
      set buc_build_corr_cyc 2
      if { [info exists XMLParse([join "crank soap run step=$step buccaneer subsequent_cycles" __])] } {
	    set buc_build_corr_cyc $XMLParse([join "crank soap run step=$step buccaneer subsequent_cycles" __])
      }
      set buc_iter_mincyc 5
      if { [info exists XMLParse([join "crank soap run step=$step buccaneer num_cycles" __])] } {
	    set buc_iter_mincyc $XMLParse([join "crank soap run step=$step buccaneer num_cycles" __])
      }
      set buc_iter_maxcyc 50
      if { [info exists XMLParse([join "crank soap run step=$step buccaneer num_cycles_max" __])] } {
	    set buc_iter_maxcyc $XMLParse([join "crank soap run step=$step buccaneer num_cycles_max" __])
      }
      set buc_seq_reliab 1.0
	  # create sequence file... this should become separate routine and be used by all MB programs/plugins?
      if { [info exists XMLParse([join "crank parameters sequence" __])] } {
        set seq [open input.seq w+]
          regsub -all {[^a-zA-Z]} $XMLParse([join "crank parameters sequence" __]) "" sequence
          for {set i 0 } { $i < [string length $sequence] } { incr i 60 } {
            if { [expr $i + 59] <  [string length $sequence] } {
              puts $seq "[string range $sequence $i [expr $i + 59] ]"
            } else {
              puts $seq "[string range $sequence $i  end]"
            }
          }
        flush $seq
        close $seq
        set buc_seq_reliab 0.99
	    if { [info exists XMLParse([join "crank soap run step=$step buccaneer sequence_match" __])] } {
	      set buc_seq_reliab $XMLParse([join "crank soap run step=$step buccaneer sequence_match" __])
	    }
      }
    }

    # some program specific parameters
    set no_parr_solvflat 0
    set no_parr_histmatch 0
    set no_parr_ncs 0
    set parr_hl_comb ""
    if { [string compare $denmod "parrot"] == 0 } {
      if { [info exists XMLParse([join "crank soap run step=$dm_step parrot solvent_flatten" __])] &&
           !$XMLParse([join "crank soap run step=$dm_step parrot solvent_flatten" __]) } {
        set no_parr_solvflat 1
      }
      if { [info exists XMLParse([join "crank soap run step=$dm_step parrot histogram" __])] &&
           !$XMLParse([join "crank soap run step=$dm_step parrot histogram" __]) } {
        set no_parr_histmatch 1
      }
      if { [info exists XMLParse([join "crank soap run step=$dm_step parrot use_ncs" __])] &&
           !$XMLParse([join "crank soap run step=$dm_step parrot use_ncs" __]) } {
        set no_parr_ncs 1
      }
      set parr_hl_comb "hl_recomb=('$in_hla','$in_hlb','$in_hlc','$in_hld'),"
    }
    set sol_radius -1
    set sol_trunc_low -1
    set sol_trunc_high -1
    if { [string compare $denmod "solomon"] == 0 } {
      if { [info exists XMLParse([join "crank soap run step=$dm_step solomon radius" __])] } {
        set sol_radius $XMLParse([join "crank soap run step=$dm_step solomon radius" __])
      }
      if {    [info exists XMLParse([join "crank soap run step=$dm_step solomon trunc_low" __])] } {
        set sol_trunc_low $XMLParse([join "crank soap run step=$dm_step solomon trunc_low" __])
      }
      if {     [info exists XMLParse([join "crank soap run step=$dm_step solomon trunc_high" __])] } {
        set sol_trunc_high $XMLParse([join "crank soap run step=$dm_step solomon trunc_high" __])
      }
    }

    # now we can write the DM (or DM+MB) script
    puts "\#!/usr/bin/python"
    puts "import os,sys,shutil"
    puts "sys.path.append( os.path.join(os.getenv('CRANK'),'plugins','solomon') )"
    puts "import phdmmb\n"

    puts "solv_cont=$solv"
    puts "inp_mtz='$mtz_in'"
    puts "inp_hpdb='$heavy_pdb'"
    # heavy atoms and target
    puts "heavy_atoms=\[\]"
    if { $mlhl } {
      puts "exper=''"
    } else {
      if { $siras } {
        puts "exper='SIRAS'"
      } else {
        puts "exper='SAD'"
      }
      set k 1
      while { [info exists XMLParse([join "crank parameters crystal=$maxc data=$maxd atom=$k name" __])] } {
        set atomname $XMLParse([join "crank parameters crystal=$maxc data=$maxd atom=$k name" __])
        set fprime $XMLParse([join "crank parameters crystal=$maxc data=$maxd atom=$k fprime" __])
        set fprimeprime $XMLParse([join "crank parameters crystal=$maxc data=$maxd atom=$k fprimeprime" __])
        incr k
        puts "heavy_atoms.append( phdmmb.heavy_atom('$atomname',$fprime,$fprimeprime) )\n"
      }
    }
    puts "mtzin_col=phdmmb.mtz_cols( $parr_hl_comb hl=('$in_hla','$in_hlb','$in_hlc','$in_hld'), fsigf_o=('$in_fp','$in_sigfp') )"
    if { !$mlhl } {
      puts "mtzin_col.fsigf_op=('$in_f_plus','$in_sigf_plus')"
      puts "mtzin_col.fsigf_om=('$in_f_minus','$in_sigf_minus')"
    }
    if { $combined && [string compare $in_freer ""] != 0 } {
      puts "mtzin_col.free='$in_freer'"
    }

    set flip_inp ""
    if { $flattened } {
      set flip_inp ",flip=0"
    }
    set no_bias "0"
    if { !$bias } {
      set no_bias "1"
    }
    puts "\nshutil.copyfile(inp_hpdb, 'heavy.pdb')"
    puts "# class for DM for bias estimation"
    puts "dm_be=phdmmb.density_mod(solv_cont=solv_cont, prog='$denmod', bigcyc=4, bias_est=1, mtzinit=inp_mtz, binary='$denmod_exec' $flip_inp)"
    # DM program specific parameters
    if { $no_parr_ncs } {
      puts "dm_be.prog_pars.param\['ncs-average'\] = False"
    }
    if { $no_parr_histmatch } {
      puts "dm_be.prog_pars.param\['histogram-match'\] = False"
    }
    if { $no_parr_solvflat } { 
      puts "dm_be.prog_pars.param\['solvent-flatten'\] = False"
    }
    if { $sol_radius > 0 } {
      puts "dm_be.prog_pars.param\['radius'\] = $sol_radius"
    }
    if { $sol_trunc_low>0 && $sol_trunc_high>0 } {
      puts "dm_be.prog_pars.param\['trunc'\] = ($sol_trunc_low,$sol_trunc_high)"
    }

    puts "# class for DM"
    puts "dm=phdmmb.density_mod.from_dmbe(dm_be, bigcyc=$ncycles)"
    puts "# class for phasing and refinement"
    puts "ph=phdmmb.phase_ref(prog='$phcomb_prog', exper=exper, intcyc=$refdm_intcyc, heavy_atoms=heavy_atoms, pdb_heavy='heavy.pdb', binary='$phcomb_exec')"
    if { $combined } {
      puts "# class for MB"
      puts "mb=phdmmb.model_build(prog='cbuccaneer', minbigcyc=$buc_iter_mincyc, maxbigcyc=$buc_iter_maxcyc, intcyc=$buc_build_init_cyc, intcyc_corr=$buc_build_corr_cyc)"
      # some Buccaneer specific parameters
      if { $buc_seq_reliab<1.0 } {
        puts "mb.sequence='input.seq'"
        puts "mb.prog_pars.param\['seq_reliab'\] = $buc_seq_reliab"
      }
      puts "# class for combined dm+mb with phasing"
      puts "combined = phdmmb.comb_phdmmb(ph,dm_be,dm,mb)"
      puts "combined.Run(mtzin_col=mtzin_col, start_dm=$start_dm)"
    } else {
      puts "# class for complete DM with bias reduction"
      puts "DM_BR = phdmmb.dm_br(ph,dm_be,dm,not $nomtz)"
      puts "DM_BR.Run(mtzin_col=mtzin_col, no_bias_est=$no_bias)"
    }

    # rename the final mtz and pdb files to what the rest of Crank wants
    if { !$hand } {
      puts "\nshutil.copyfile('$phcomb_prog.mtz', '$denmod.mtz')"
    }

    # we are done; now just to call mapro in case we have hand determination
    if { $hand } {
      puts "\n# we are done; now just to call mapro in case we have hand determination"
      puts "mtzin_col=phdmmb.mtz_cols( hl=('$in_hla','$in_hlb','$in_hlc','$in_hld'), fsigf_o=('$in_fp','$in_sigfp') )"
      puts "dm.cyc=1"
      puts "dm.RunFFT(inp_mtz, 'input.map', mtzin_col)"
      puts "phdmmb.ExtRun( 'mapro', ('mapro','-mapin','input.map','-pdbin',inp_hpdb,'-cld','-skew'), '', os.getcwd() )"
    }

}

global env

set cycles   [lindex $argv 0 ]
set solv     [lindex $argv 1 ]
set enant    [lindex $argv 2 ]
set nomtz    [lindex $argv 3 ]
set flatten  [lindex $argv 4 ]
set inccp4   [lindex $argv 5 ]
set hand     [lindex $argv 6 ]
set bias     [lindex $argv 7 ]
set solomon  [lindex $argv 8 ]
set dm_step  [lindex $argv 9 ]

source [file join $env(CRANK) bin crankutils.tcl]

if { [file exists [file join .. xml input.xml] ] } {
    set inputxml     [file join .. xml input.xml]
} elseif { [file exists [file join .. .. xml input.xml] ] } {
    set inputxml     [file join .. .. xml input.xml]
} else {
    crank_error "crank::solomonhand.tcl:: input.xml file not found"
}

XMLParsefile $inputxml 

OutputSolomonscriptfile $cycles $solv $enant $nomtz $flatten $inccp4 $hand $bias $solomon $dm_step
