#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
{ [IfSet $TITLE] } title  $TITLE
{ [IfSet $FFT_SPACE_GROUP ] } fftspacegroup $FFT_SPACE_GROUP
$IFXYZLIM xyzlim $XYZLIM_1 $XYZLIM_2 $XYZLIM_3 $XYZLIM_4 $XYZLIM_5 $XYZLIM_6
$IFXYZLIMASU xyzlim asu

$IFTRANSLATION PHTRANSLATION $WHICH_HAND
$IFPATTERSON PATTERSON

$IFRHOLIM rholim $RHOLIM_MAX 
 - 1 $RHOLIM_MIN

{[IfSet $SCALE_AMPL_1]}  scale F1 $SCALE_AMPL_1
- $BFACTOR_SCALING $SCALE_BFACTOR_1
{ $USE_F2 && [IfSet $SCALE_AMPL_2]}  scale F2 $SCALE_AMPL_2 
- $BFACTOR_SCALING $SCALE_BFACTOR_2

$EXCLUDE_RESOLUTION resolution $EXCLUDE_RESOLUTION_MIN $EXCLUDE_RESOLUTION_MAX

$EXCLUDE_FREER FREERFLAG $EXCLUDE_FREER_VALUE

IF { $EXCLUDE_BYSIGMA || $EXCLUDE_MINIMUM || $EXCLUDE_MAXIMUM || $EXCLUDE_BYDIFF }
1 exclude
- $EXCLUDE_BYSIGMA 
-- {[IfSet $EXCLUDE_BYSIGMA_1] && ![StringSame $PATTERSON_MODE PATTERSONI]} sig1 $EXCLUDE_BYSIGMA_1 
-- { $USE_F2 && [IfSet $EXCLUDE_BYSIGMA_2] && ![StringSame $PATTERSON_MODE PATTERSONI]} sig2 $EXCLUDE_BYSIGMA_2
- $EXCLUDE_MINIMUM 
-- {[IfSet $EXCLUDE_MINIMUM_1]} f1lim $EXCLUDE_MINIMUM_1 
-- { $USE_F2 && [IfSet $EXCLUDE_MINIMUM_2]} f2lim $EXCLUDE_MINIMUM_2
- $EXCLUDE_MAXIMUM 
-- {[IfSet $EXCLUDE_MAXIMUM_1]} f1max $EXCLUDE_MAXIMUM_1 
-- { $USE_F2 && [IfSet $EXCLUDE_MAXIMUM_2]} f2max $EXCLUDE_MAXIMUM_2
- { $EXCLUDE_BYDIFF && [IfSet $EXCLUDE_BYDIFF_DIFF]} diff $EXCLUDE_BYDIFF_DIFF
ENDIF

$SCALE_MAP VF000 $SCALE_VOLUME $SCALE_F000
$GRID grid $GRID_1 $GRID_2 $GRID_3

1 labin
LABELLINE - $LABIN
 - $EXCLUDE_FREER  FREE= $EXCLUDE_FREER_LABEL

1 end
