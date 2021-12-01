echo off
::creating input file for fofcmap example as the input depend on environment variable

echo TITLE Fc and Phic calculation from %TOXD%\toxd.pdb > %SCRIPTWIN%\fofcmap1.dat
echo MODE SFCALC HKLIN XYZIN >> %SCRIPTWIN%\fofcmap1.dat
echo RESOLUTION 10.0 2.7 >> %SCRIPTWIN%\fofcmap1.dat
echo GRID 100 60 32 >> %SCRIPTWIN%\fofcmap1.dat
echo LABIN FP=FTOXD3 SIGFP=SIGFTOXD3 FREE=FreeR_flag >> %SCRIPTWIN%\fofcmap1.dat
echo LABOUT FC=TOXFC PHIC=TOXPHIC >> %SCRIPTWIN%\fofcmap1.dat
echo END >> %SCRIPTWIN%\fofcmap1.dat

::creating input file for bulk example as the input depend on environment variable

echo %TOXD%\toxd.pdb > bulk3.dat
echo %TEMPRES%\toxd_table1.tab >> bulk3.dat
echo %TEMPRES%\toxd_tabling.log >> bulk3.dat
echo %TEMPRES%\toxd_table1.tabs >> bulk3.dat
echo %TEMPRES%\toxd_bulking.inp >> bulk3.dat
echo 0.35         ! value of ksol >> bulk3.dat
echo 50.0         ! value of Bsol >> bulk3.dat
echo 1.4          ! value of the solvent radius used for mask >> bulk3.dat

::creating input file for oasis_sir example as the input depend on environment variable

echo read %TEMPRES%\rnase_mod.mtz > %SCRIPTWIN%\oasis_sir2.dat
echo calc D col DIFFPTNCD25 = col FPTNCD25 col FNAT - >> %SCRIPTWIN%\oasis_sir2.dat
echo calc Q col SIGDIFFPTNCD25 = col SIGFPTNCD25 2 ** col SIGFNAT 2 ** + 0.5 ** >> %SCRIPTWIN%\oasis_sir2.dat
echo write %TEMPRES%\rnase_sir.mtz >> %SCRIPTWIN%\oasis_sir2.dat
echo y >> %SCRIPTWIN%\oasis_sir2.dat
echo exit >> %SCRIPTWIN%\oasis_sir2.dat

::creating input file for rsps example as the input depend on environment variable

echo # read spacegroup, file names and cell parameters > %SCRIPTWIN%\rsps2.dat
echo # >> %SCRIPTWIN%\rsps2.dat
echo spacegroup 19                        ! must be before file names >> %SCRIPTWIN%\rsps2.dat
echo # reset origin peak to zero >> %SCRIPTWIN%\rsps2.dat
echo patfile %TEMPRES%\toxd_aupatt.map type CCP4 reset origin 10.0 0    >> %SCRIPTWIN%\rsps2.dat
echo scorfile %TEMPRES%\rsps.map >> %SCRIPTWIN%\rsps2.dat
echo pick patterson >> %SCRIPTWIN%\rsps2.dat
echo # >> %SCRIPTWIN%\rsps2.dat
echo # Harker scan of asymmetric unit >> %SCRIPTWIN%\rsps2.dat
echo # Allow one low peak >> %SCRIPTWIN%\rsps2.dat
echo # >> %SCRIPTWIN%\rsps2.dat
echo vectorset single atoms ; low 0 ; reject 1.0 ; scan au >> %SCRIPTWIN%\rsps2.dat
echo pick scoremap 50 >> %SCRIPTWIN%\rsps2.dat
echo write positions %TEMPRES%\rsps_harker.pdb >> %SCRIPTWIN%\rsps2.dat
echo vlist site 1 10 >> %SCRIPTWIN%\rsps2.dat

::creating input file for sortmtz example as the input depend on environment variable

echo H K L M/ISYM BATCH > %SCRIPTWIN%\sortmtz4.dat
echo %TEMPRES%\aucn_1.mtz >> %SCRIPTWIN%\sortmtz4.dat
echo %TEMPRES%\aucn_2.mtz >> %SCRIPTWIN%\sortmtz4.dat
echo %TEMPRES%\aucn_3.mtz >> %SCRIPTWIN%\sortmtz4.dat

::creating input files for beast example as the input depend on environment variables

echo LABIN F=FTOXD3 > %SCRIPTWIN%\beast1.dat
echo MOLECULE mol1 1.0 >> %SCRIPTWIN%\beast1.dat
echo MODEL mol1 %DATA%\1BIK.pdb IDENT 0.377 >> %SCRIPTWIN%\beast1.dat
echo SEARCH mol1 ROTATE FULL 15. >> %SCRIPTWIN%\beast1.dat
echo BEST 20 0 >> %SCRIPTWIN%\beast1.dat
echo END >> %SCRIPTWIN%\beast1.dat

echo LABIN F=FTOXD3 > %SCRIPTWIN%\beast2.dat
echo MOLECULE mol1 1.0 >> %SCRIPTWIN%\beast2.dat
echo MODEL mol1 %TOXD%\toxd.pdb IDENT 1.00 >> %SCRIPTWIN%\beast2.dat
echo SEARCH mol1 ROTATE AROUND 0.0 0.0 0.0 15.0 >> %SCRIPTWIN%\beast2.dat
echo END >> %SCRIPTWIN%\beast2.dat

echo LABIN F=FTOXD3 > %SCRIPTWIN%\beast3.dat
echo MOLECULE mol1 1.0 >> %SCRIPTWIN%\beast3.dat
echo MODEL mol1 %DATA%\1D0D_B.pdb IDENT 0.364 >> %SCRIPTWIN%\beast3.dat
echo MODEL mol1 %DATA%\1BIK_2_1D0D_B.pdb IDENT 0.377 >> %SCRIPTWIN%\beast3.dat
echo SEARCH mol1 ROTATE FULL 15.0 >> %SCRIPTWIN%\beast3.dat
echo END >> %SCRIPTWIN%\beast3.dat

echo LABIN F=FTOXD3 > %SCRIPTWIN%\beast4.dat
echo MOLECULE mol1 1.0 >> %SCRIPTWIN%\beast4.dat
echo MODEL mol1 %DATA%\1D0D_B.pdb IDENT 0.364 >> %SCRIPTWIN%\beast4.dat
echo SEARCH mol1 ROTATE AROUND LIST 3.0 1.0 >> %SCRIPTWIN%\beast4.dat
echo RLIST mol1 146.38  23.86 197.31 >> %SCRIPTWIN%\beast4.dat
echo RLIST mol1 130.15  17.99 219.53 >> %SCRIPTWIN%\beast4.dat
echo RLIST mol1 138.39  20.92 205.97 >> %SCRIPTWIN%\beast4.dat
echo END >> %SCRIPTWIN%\beast4.dat

echo LABIN F=FTOXD3 > %SCRIPTWIN%\beast5.dat
echo MOLECULE mol1 1.0 >> %SCRIPTWIN%\beast5.dat
echo MODEL mol1 %DATA%\1BIK.pdb IDENT 0.377 >> %SCRIPTWIN%\beast5.dat
echo SEARCH mol1 ROTATE 171.26 17.99 226.09 TRANSLATE REGION 0.0 0.5 0.0 0.5 0.0 0.5 1.5 >> %SCRIPTWIN%\beast5.dat
echo END >> %SCRIPTWIN%\beast5.dat

echo LABIN F=FTOXD3 > %SCRIPTWIN%\beast6.dat
echo MOLECULE mol1 1.0 >> %SCRIPTWIN%\beast6.dat
echo MODEL mol1 %DATA%\1D0D_B.pdb IDENT 0.364 >> %SCRIPTWIN%\beast6.dat
echo SEARCH mol1 ROTATE LIST TRANSLATE REGION 0.0 0.5 0.0 0.5 0.0 0.5 0.8 0.2 >> %SCRIPTWIN%\beast6.dat
echo RLIST mol1 143.55  22.57 200.87 >> %SCRIPTWIN%\beast6.dat
echo RLIST mol1 128.86  18.42 219.80 >> %SCRIPTWIN%\beast6.dat
echo RLIST mol1 130.15  17.99 219.53 >> %SCRIPTWIN%\beast6.dat
echo END >> %SCRIPTWIN%\beast6.dat

echo LABIN F=FTOXD3 > %SCRIPTWIN%\beast7.dat
echo MOLECULE mol1 1.00 >> %SCRIPTWIN%\beast7.dat
echo MODEL mol1 %DATA%\1BIK.pdb IDENT 0.377 >> %SCRIPTWIN%\beast7.dat
echo SEARCH mol1 ROTATE AROUND 171.26 17.99 226.09 1.0 0.3 TRANSLATE AROUND 0.4931 0.0842 0.0425 0.4 0.1 >> %SCRIPTWIN%\beast7.dat
echo BEST 10 3 >> %SCRIPTWIN%\beast7.dat
echo END >> %SCRIPTWIN%\beast7.dat

::creating input file for restrain example as the input depend on environment variable

echo TITLE  TOXD at 2.3A. > %SCRIPTWIN%\restrain.dat
echo XYZIN  %DATA%\toxd_in.pdb >> %SCRIPTWIN%\restrain.dat
echo HKLIN  %TOXD%\toxd.mtz >> %SCRIPTWIN%\restrain.dat
echo LABIN  FP=FTOXD3 SIGFP=SIGFTOXD3 FREE=FreeR_flag >> %SCRIPTWIN%\restrain.dat
echo XYZOUT %TEMPRES%\toxd_out.pdb >> %SCRIPTWIN%\restrain.dat
echo HKLOUT %TEMPRES%\toxd_out.mtz >> %SCRIPTWIN%\restrain.dat
echo LABOUT FC=FCTOXD3 PHIC=PHICTOXD3 >> %SCRIPTWIN%\restrain.dat
echo ! Must supply extra distance restraints for disulphides: >> %SCRIPTWIN%\restrain.dat
echo XTRD    7.CB 57.SG 3.034 .033  ! These are from Engh and Huber. >> %SCRIPTWIN%\restrain.dat
echo XTRD    7.SG 57.SG 2.03  .008 >> %SCRIPTWIN%\restrain.dat
echo XTRD    7.SG 57.CB 3.034 .033 >> %SCRIPTWIN%\restrain.dat
echo XTRD   16.CB 40.SG 3.034 .033 >> %SCRIPTWIN%\restrain.dat
echo XTRD   16.SG 40.SG 2.03  .008 >> %SCRIPTWIN%\restrain.dat
echo XTRD   16.SG 40.CB 3.034 .033 >> %SCRIPTWIN%\restrain.dat
echo XTRD   32.CB 53.SG 3.034 .033 >> %SCRIPTWIN%\restrain.dat
echo XTRD   32.SG 53.SG 2.03  .008 >> %SCRIPTWIN%\restrain.dat
echo XTRD   32.SG 53.CB 3.034 .033 >> %SCRIPTWIN%\restrain.dat
echo ! Use PDB file occupancies of 20 atoms starting at 61 O1. >> %SCRIPTWIN%\restrain.dat
echo OCCU   61.O1 20 SO4s           ! 4 sulphates. >> %SCRIPTWIN%\restrain.dat
echo STEER >> %SCRIPTWIN%\restrain.dat
echo ! Following items are in NAMELIST format (name=value list). >> %SCRIPTWIN%\restrain.dat
echo NCYC=5         ! Do 5 cycles with bulk solvent correction. >> %SCRIPTWIN%\restrain.dat
echo REPEL=t        ! Activate VDW repulsion restraints just in case. >> %SCRIPTWIN%\restrain.dat
echo OCCREF=f       ! No occupancy refinement. >> %SCRIPTWIN%\restrain.dat
echo SCHEME=2       ! Better than weighting scheme 1 and uses SIGF. >> %SCRIPTWIN%\restrain.dat

:: Creating input files for dtrek2scala example as its input depend on environment variable

echo TITLE      'dtrek2scala example data set' > %SCRIPTWIN%\dtrek2scala1.dat
echo SYMMETRY   96 >> %SCRIPTWIN%\dtrek2scala1.dat
echo CRYSTAL    1 >> %SCRIPTWIN%\dtrek2scala1.dat
echo PNAME      HEWL >> %SCRIPTWIN%\dtrek2scala1.dat
echo DNAME      Dtrek2scala test  >> %SCRIPTWIN%\dtrek2scala1.dat
echo TOOFAR     2.0 2.0 0.5 >> %SCRIPTWIN%\dtrek2scala1.dat
echo # >> %SCRIPTWIN%\dtrek2scala1.dat
echo BATCH      1 >> %SCRIPTWIN%\dtrek2scala1.dat
echo FILE       %DATA%\dtprofit.ref >> %SCRIPTWIN%\dtrek2scala1.dat
echo HFILE      %DATA%\dtintegrate.head >> %SCRIPTWIN%\dtrek2scala1.dat
echo BTITLE     HEWL-test >> %SCRIPTWIN%\dtrek2scala1.dat
echo PROCESS >> %SCRIPTWIN%\dtrek2scala1.dat

echo H K L M/ISYM BATCH > %SCRIPTWIN%\dtrek2scala2.dat
echo %TEMPRES%\HEWL-test.dtrek2scala.mtz >> %SCRIPTWIN%\dtrek2scala2.dat

::creating input file for watncs example as the input depend on environment variable

echo pdb %TEMPRES%\rnase_wat.pdb > %SCRIPTWIN%\watncs2.dat
echo out %TEMPRES%\rnase_out.pdb >> %SCRIPTWIN%\watncs2.dat
echo relate >> %SCRIPTWIN%\watncs2.dat
echo      0.970  -0.048   -0.238  >> %SCRIPTWIN%\watncs2.dat
echo      0.238   0.384    0.892 >> %SCRIPTWIN%\watncs2.dat
echo      0.049  -0.922    0.384 >> %SCRIPTWIN%\watncs2.dat
echo  -33.27858  21.14615  19.01986 >> %SCRIPTWIN%\watncs2.dat
echo error 0.6 >> %SCRIPTWIN%\watncs2.dat
echo least 1 >> %SCRIPTWIN%\watncs2.dat

::creating input file for mtzMadMode example as the input depend on environment variable

echo read %RNASE%\rnase25.mtz col FNAT SIGFNAT > %SCRIPTWIN%\mtzMad2.dat
echo read %TEMPRES%\rnase25_madmod.mtz >> %SCRIPTWIN%\mtzMad2.dat
echo write %TEMPRES%\rnase25_all.mtz >> %SCRIPTWIN%\mtzMad2.dat
echo exit >> %SCRIPTWIN%\mtzMad2.dat

::creating input files for beast-various example as the input depend on environment variables

echo LABIN F=FTOXD3 > %SCRIPTWIN%\beastvar1.dat
echo MOLECULE mol1 1.0 >> %SCRIPTWIN%\beastvar1.dat
echo MODEL mol1 %DATA%\1D0D_B.pdb IDENT 0.364 >> %SCRIPTWIN%\beastvar1.dat
echo MODEL mol1 %DATA%\1BIK_2_1D0D_B.pdb IDENT 0.377 >> %SCRIPTWIN%\beastvar1.dat
echo SEARCH mol1 ROTATE AROUND 143.75  21.02 200.76  1.0 0.3 \ >> %SCRIPTWIN%\beastvar1.dat
echo             TRANSLATE AROUND 0.3789  0.2222  0.4427   0.4 0.1 >> %SCRIPTWIN%\beastvar1.dat
echo BEST 20 0 >> %SCRIPTWIN%\beastvar1.dat
echo END >> %SCRIPTWIN%\beastvar1.dat

echo LABIN F=FTOXD3 > %SCRIPTWIN%\beastvar2.dat
echo MOLECULE mol1 1.0 >> %SCRIPTWIN%\beastvar2.dat
echo MODEL mol1 %DATA%\1BIK_2_1D0D_B.pdb IDENT 0.377 >> %SCRIPTWIN%\beastvar2.dat
echo SEARCH mol1  >> %SCRIPTWIN%\beastvar2.dat
echo @%DATA%\toxd.molrep_rf >> %SCRIPTWIN%\beastvar2.dat
echo REPORT ALL >> %SCRIPTWIN%\beastvar2.dat
echo END >> %SCRIPTWIN%\beastvar2.dat

echo LABIN F=FTOXD3 > %SCRIPTWIN%\beastvar3.dat
echo MOLECULE mol1 1.0 >> %SCRIPTWIN%\beastvar3.dat
echo MODEL mol1 %DATA%\1D0D_B.pdb IDENT 0.364 >> %SCRIPTWIN%\beastvar3.dat
echo MODEL mol1 %DATA%\1BIK_2_1D0D_B.pdb IDENT 0.377 >> %SCRIPTWIN%\beastvar3.dat
echo SEARCH mol1 ROTATE FULL 8. >> %SCRIPTWIN%\beastvar3.dat
echo BEST 20 >> %SCRIPTWIN%\beastvar3.dat
echo END >> %SCRIPTWIN%\beastvar3.dat

echo LABIN F=FTOXD3 > %SCRIPTWIN%\beastvar4.dat
echo MOLECULE mol1 1.0 >> %SCRIPTWIN%\beastvar4.dat
echo MODEL mol1 %DATA%\1D0D_B.pdb IDENT 0.364 >> %SCRIPTWIN%\beastvar4.dat
echo MODEL mol1 %DATA%\1BIK_2_1D0D_B.pdb IDENT 0.377 >> %SCRIPTWIN%\beastvar4.dat
echo SEARCH mol1 ROTATE AROUND LIST 3.5 1. >> %SCRIPTWIN%\beastvar4.dat
echo RLIST  mol1 137.29  21.41 206.63 >> %SCRIPTWIN%\beastvar4.dat
echo RLIST  mol1 140.14  14.88 206.72 >> %SCRIPTWIN%\beastvar4.dat
echo RLIST  mol1 130.05  21.41 220.92 >> %SCRIPTWIN%\beastvar4.dat
echo RLIST  mol1 138.95  27.95 209.05 >> %SCRIPTWIN%\beastvar4.dat
echo END >> %SCRIPTWIN%\beastvar4.dat

echo LABIN F=FTOXD3 > %SCRIPTWIN%\beastvar5.dat
echo MOLECULE mol1 1.0 >> %SCRIPTWIN%\beastvar5.dat
echo MODEL mol1 %DATA%\1D0D_B.pdb IDENT 0.364 >> %SCRIPTWIN%\beastvar5.dat
echo MODEL mol1 %DATA%\1BIK_2_1D0D_B.pdb IDENT 0.377 >> %SCRIPTWIN%\beastvar5.dat
echo SEARCH mol1 ROTATE 143.75  21.02 200.76  \ >> %SCRIPTWIN%\beastvar5.dat
echo             TRANSLATE REGION 0.0 0.5  0.0 0.5  0.0 0.5 >> %SCRIPTWIN%\beastvar5.dat
echo END >> %SCRIPTWIN%\beastvar5.dat

::creating input files for cpirate example as the input depend on environment variables

echo mtzin-ref %TEMPRES%\ref.mtz > %SCRIPTWIN%\cpirate1.dat
echo colin-ref-fo /*/*/[FP.F_sigF.F,FP.F_sigF.sigF] >> %SCRIPTWIN%\cpirate1.dat
echo colin-ref-hl /*/*/[FC.ABCD.A,FC.ABCD.B,FC.ABCD.C,FC.ABCD.D] >> %SCRIPTWIN%\cpirate1.dat
echo mtzin-wrk %TEMPRES%\toxd_phase_mir.mtz >> %SCRIPTWIN%\cpirate1.dat
echo colin-wrk-fo /*/*/[FTOXD3,SIGFTOXD3] >> %SCRIPTWIN%\cpirate1.dat
echo colin-wrk-hl /*/*/[HLA,HLB,HLC,HLD] >> %SCRIPTWIN%\cpirate1.dat
echo colin-wrk-free /*/*/[FreeR_flag] >> %SCRIPTWIN%\cpirate1.dat
echo mtzout %TEMPRES%\toxd_phase_mir_pirate1.mtz >> %SCRIPTWIN%\cpirate1.dat
echo colout pirate >> %SCRIPTWIN%\cpirate1.dat
echo ncycles 3 >> %SCRIPTWIN%\cpirate1.dat
echo weight-expllk 0.5 >> %SCRIPTWIN%\cpirate1.dat
echo weight-mapllk 0.1 >> %SCRIPTWIN%\cpirate1.dat
echo stats-radius 9.0,3.0 >> %SCRIPTWIN%\cpirate1.dat
echo skew-content 0.0,0.0 >> %SCRIPTWIN%\cpirate1.dat
echo auto-content >> %SCRIPTWIN%\cpirate1.dat

echo mtzin %TEMPRES%\toxd_phase_mir_pirate1.mtz > %SCRIPTWIN%\cpirate2.dat
echo colin-fc /*/*/[pirate.F_phi.F,pirate.F_phi.phi] >> %SCRIPTWIN%\cpirate2.dat
echo mapout %TEMPRES%\toxd_phase_mir_pirate1_fft1.map >> %SCRIPTWIN%\cpirate2.dat
echo stats >> %SCRIPTWIN%\cpirate2.dat
echo stats-radius 4.0 >> %SCRIPTWIN%\cpirate2.dat