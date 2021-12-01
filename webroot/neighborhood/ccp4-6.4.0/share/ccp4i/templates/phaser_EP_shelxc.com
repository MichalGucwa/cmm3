#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id: mtz2various.com,v 1.4 2005/09/09 09:41:37 mdw Exp $
1 SAD  $SCA_FILE
1 CELL $WAVELENGTH $CELL_1 $CELL_2 $CELL_3 $CELL_4 $CELL_5 $CELL_6
1 SPAG $EDIT_SPACEGROUP
1 FIND $N_HYSS
1 SFAC $HYSS_TYPE
#{ $PATS_ONOFF } PATS
IF { $TOG_MIND }
  IF { $ALLOW_SPECIAL_POS }
    1 MIND -$MIND -0.1
  ELSE
    1 MIND -$MIND
  ENDIF
ENDIF
{ $TOG_NTRY } NTRY $NTRY
{ $TOG_SHELXC_RESO } SHEL $MIN_RESO $MAX_RESO

