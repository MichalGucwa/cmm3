#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
1 MOL1 $XYZIN1
1 MOL2 $XYZIN2
1 WRITE
1 MATCH 
CASE $TOP_MATCH_MODE
CASEMATCH RATE
- 1 rate $TOP_MATCH_RATE1 $TOP_MATCH_RATE2
CASEMATCH ABS
- 1 $TOP_MATCH_NSECSTR
CASEMATCH AUTO
- 1 auto
ENDCASE
1 END
