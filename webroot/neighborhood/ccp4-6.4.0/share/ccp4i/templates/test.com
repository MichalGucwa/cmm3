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
LABELLINE labin $LABIN
{ [IfSet $SPACE_GROUP ] } spacegroup $SPACE_GROUP
CASE $TEST_CASE
CASEMATCH first
1 FIRST
CASEMATCH second third
1 second or third
ENDCASE
