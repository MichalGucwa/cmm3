echo off

echo Start: %time%

set TEMPRES=%CCP4_SCR%
set DATA=%CCP4%\examples\data
set TOXD=%CCP4%\examples\toxd
set SCRIPTWIN=%CCP4%\examples\windows
set RNASE=%CCP4%\examples\rnase

::deprecated: arp_waters-ex bplot-ex rsearch-ex  polypose-ex restrain-ex beast_various-ex beast-ex 

:: These have been taken out for now due to minor issues when running them
:: libcheck-ex toxd-RF-Es-ex molrep-ex

set-files && FOR %%i IN ( 
   mlphare-ex  3fo2fcmap-ex  act-ex  scala-ex  almn-ex angles-ex anisoanl-ex 
   axissearch-ex  baverage-ex  bulk-ex  cad-ex 
   cavenv-ex  cif2xml-ex  combat-ex  contact-ex  coordconv-ex  crossec-ex 
   cross_validate-ex  areaimol-ex  scalepack2mtz-ex surface-ex detwin-bar-ex
   distang-ex differences-ex dm-ex  dyndom-ex  ecalc-ex  sf_calc-ex  mtz2various-ex f2mtz-ex
   fffear-ex  fft-ex  fhscal-ex  findncs-ex  fofcmap-ex  fractional-orthogonal-ex
   gensym-ex  geomcalc-ex  havecs-ex  helixang-ex  hgen-ex  hklplot-ex  icoefl-ex 
   lsqkab-ex mapcorpro-ex  scaleit-ex  makedict-ex  mapmask-ex  mapcutting-ex mir-steps-ex
   mtzdump-ex  mtztona4-ex mtzutils-ex mtzMADmod-ex ncont-ex ncsmask-ex npo-ex oasis_oas-ex 
   oasis_sir-ex overlapmap-ex patterson-ex pdbcur-ex pdbset-ex phase_analysis-ex 
   phased_translation_calc-ex phistats-ex polarrfn-ex 
   rebatch-ex reindex-ex revise-ex rotamer-ex rotmat-ex solomon-ex tffc_procedure-ex
   rsps-ex rstats-ex rwcontents-ex sapi-ex sfcheck-ex sigmaa-ex sortmtz-ex
   sortwater-ex stereo-ex surface-volume-calc-ex surface_rnase-ex tracer-ex 
   sfall-ex truncate-ex unique-free-R-ex vecref-ex vectors-ex watncs-ex waterpeaks-ex watpeak-ex
   watertidy-3shells-ex wilson-ex hbond-ex refmac5_tls-ex refmac_sad-ex refmac_twin-ex compar-ex tlsanl-ex 
   cpirate-ex acorn-ex mlphare_rnase-ex cad_rnase-ex
   freerflag-ex fsearch-ex mtzmnf-ex omit-ex crunch2-ex  
   bp3-ex phaser-ex
   ) DO %%i

echo End: %time%
