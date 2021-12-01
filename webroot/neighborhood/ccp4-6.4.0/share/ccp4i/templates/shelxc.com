#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
IF { [StringSame $SHELXC_EXPT MAD] }
  { [IfSet $SCALIN_NAT] }  NAT $SCALIN_NAT
  { [IfSet $SCALIN_PEAK] } PEAK $SCALIN_PEAK
  { [IfSet $SCALIN_INFL] } INFL $SCALIN_INFL
  { [IfSet $SCALIN_LREM] } LREM $SCALIN_LREM
  { [IfSet $SCALIN_HREM] } HREM $SCALIN_HREM
ENDIF
IF { [StringSame $SHELXC_EXPT SAD] }
  { [IfSet $SCALIN_NAT] }  NAT $SCALIN_NAT
  1 $SHELXC_EXPT $SCALIN_HA
ENDIF
IF { [StringSame $SHELXC_EXPT SIR SIRA] }
  1 NAT $SCALIN_NAT
  1 $SHELXC_EXPT $SCALIN_HA
ENDIF
1 CELL $CELL_LAMBDA $CELL_1 $CELL_2 $CELL_3 $CELL_4 $CELL_5 $CELL_6
1 SPAG $SHELX_SPACE_GROUP
IF { [IfSet $MIND] }
  IF { $ALLOW_SPECIAL_POS }
    1 MIND -$MIND -0.1
  ELSE
    1 MIND -$MIND
  ENDIF
ENDIF
{ [IfSet $NTRY] } NTRY $NTRY
{ [IfSet $SFAC] } SFAC $SFAC
{ [IfSet $FIND] } FIND $FIND
IF { ! $USE_SHELXC_RESO }
  1 SHEL $MIN_RESO $MAX_RESO
ENDIF

