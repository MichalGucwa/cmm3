#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
##################################################
# SFCHECK: COMMAND SCRIPT
##################################################
1 DOC Y

IF { [StringSame $SFCHECK_MODE BOTH EXPERIMENT] }
  1 LABIN
  CASE $SFCHECK_DATA
  CASEMATCH SF
    - 1 F=$F1
    - { ![StringSame $SIGF1 "Unassigned" ] } SIGF=$SIGF1
  CASEMATCH SF_ANOM
    - 1 F=$F1
    - { ![StringSame $SIGF1 "Unassigned" ] } SIGF=$SIGF1
    - 1 F(-)=$F2
    - { ![StringSame $SIGF2 "Unassigned" ] } SIGF(-)=$SIGF2
  CASEMATCH I
    - 1 I=$I1
    - { ![StringSame $SIGI1 "Unassigned" ] } SIGI=$SIGI1
  CASEMATCH I_ANOM
    - 1 I=$I1
    - { ![StringSame $SIGI1 "Unassigned" ] } SIGI=$SIGI1
    - 1 I(-)=$I2
    - { ![StringSame $SIGI2 "Unassigned" ] } SIGI(-)=$SIGI2
  ENDCASE
    - { ![StringSame $FREE "Unassigned" ] } FREE=$FREE
  $SFCHECK_ANISOTHERMAL_CORR OUT A
ENDIF
