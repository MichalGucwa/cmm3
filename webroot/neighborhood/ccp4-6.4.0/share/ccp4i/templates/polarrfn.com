#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
{ [ IfSet $TITLE ] } title  $TITLE

##################################################
# compulsory keywords
##################################################

1 SELF 
 - { [ IfSet $SELF_ARAD ] } $SELF_ARAD
 - { [ IfSet $SELF_EPS ] } $SELF_EPS
1 CRYSTAL FILE 1
 - { [ IfSet $CRYSTAL_BFAC ] } BFAC $CRYSTAL_BFAC
1 LABIN FILE 1
  LABELLINE - "F SIGF"

##################################################
# optional keywords
##################################################

{ [ IfSet $RESHIGH ] } RESOLUTION $RESHIGH
 - { [ IfSet $RESLOW ] } $RESLOW
$POLARRFN_MAP MAP
$POLARRFN_PLOT PLOT
 - { [ IfSet $PLOT_CSTART ] } $PLOT_CSTART
 - { [ IfSet $PLOT_CINT ] } $PLOT_CINT
$POLARRFN_FIND FIND
 - { [ IfSet $FIND_PEAK ] } $FIND_PEAK
 - { [ IfSet $FIND_MAXPEAK ] } $FIND_MAXPEAK
 - $FIND_RMS RMS

$POLARRFN_LIMITS LIMITS
 - 1 $PHI_START $PHI_STOP $DEL_PHI
 - 1 $OMEGA_START $OMEGA_STOP $DEL_OMEGA
 - 1 $KAPPA_START $KAPPA_STOP $DEL_KAPPA

IF $LPRINT 
  1 PRINT $IPRINT
ELSE
  1 NOPRINT
ENDIF

1 END

