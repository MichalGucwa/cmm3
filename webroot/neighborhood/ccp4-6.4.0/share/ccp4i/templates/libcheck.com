#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
1 Y
CASE $INPUT_MODE
CASEMATCH min
  1 _FILE_L $BONDLIST_FILE
  1 _MON $CHEM_COMP_ID
  { !$SEARCH} _SRCH N
CASEMATCH pdb
  1 _FILE_PDB $PDBIN
  { !$SEARCH} _SRCH 0
CASEMATCH MOL2
  1 _FILE_MOL $MOL2IN
CASEMATCH SMILES
  1 _FILE_SMILE $SMILESIN
  1 _MON $CHEM_COMP_ID
ENDCASE
$FROMCOOR _COOR Y
#$NODIST _NODIST Y
1 _FILE_O $FILE_OUT
$IFREFINE _REF
 - $IFREFMAC S
1 _END
