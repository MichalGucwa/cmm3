#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
1 READ $HKLIN
1 SELECT COL $F1 PRESENT
CASE $SF_ACTION
CASEMATCH CORREL 
1 SELECT COL $F2 PRESENT
1 CORREL COL $F1 $F2 SHELLS $NSHELLS
- $SF_RESOL RESOLUTION $MIN_RESOL $MAX_RESOL
CASEMATCH PHASHFT
1 SELECT COL $F2 PRESENT
1 PHASHFT COL $PHI1 $PHI2 SHELLS $NSHELLS
- $SF_RESOL RESOLUTION $MIN_RESOL $MAX_RESOL 
- { [StringSame $SF_COSINE COSINE] } COSINE
CASEMATCH PLOT
{ ![StringSame $SF_VERSUS RESOL] } SELECT COL $F2 PRESENT
1 PLOT COL $F1 VERSUS
- { [StringSame $SF_VERSUS RESOL] } RESOL | COL $F2
- 1 SHELLS $NSHELLS
CASEMATCH COMPLETE
1 COMPLETE SHELLS $NSHELLS
- $SF_RESOL RESOLUTION $MAX_RESOL
- 1 $SF_MODE $SF_ASUNIT COL $F1
ENDCASE
1 EXIT
1 YES