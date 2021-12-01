#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
{[IfSet $TITLE]} title $TITLE
$VERBOSE verbose

1 tabfun 
- !$TABFUN_ROTATE norotate
- !$TABFUN_TRANSLATE notranslate
- !$TABFUN_TABLE notab
- $TABFUN_HKLOUT hklout

1 model 1
- {[IfSet $BREP0]} breplace $BREP0 
- {[IfSet $BADD0]} badd $BADD0

1 sample 1 resolution $TABLE_RESOLUTION_MAX 
  - {[IfSet $TABFUN_SCALE0]} scale $TABFUN_SCALE0
  - {[IfSet $TABFUN_SHANN0]} shann $TABFUN_SHANN0
{[IfSet $CRYSTAL_CELL_1 $CRYSTAL_CELL_2 $CRYSTAL_CELL_3 $CRYSTAL_CELL_4 $CRYSTAL_CELL_5 $CRYSTAL_CELL_6]} crystal $CRYSTAL_CELL_1 $CRYSTAL_CELL_2 $CRYSTAL_CELL_3
- 1 $CRYSTAL_CELL_4 $CRYSTAL_CELL_5 $CRYSTAL_CELL_6 orth 1

