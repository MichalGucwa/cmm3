#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
IF {[IfSet $HARVEST_MODE]}
  IF { [StringSame $HARVEST_MODE NOHARVEST] }
    1 NOHARVEST
  ELSE
    $HARVEST_INPUT_NAMES PNAME $HARVEST_PNAME
    $HARVEST_INPUT_NAMES DNAME $HARVEST_DNAME
    1 RSIZE $HARVEST_RSIZE
    $HARVEST_PRIVATE PRIVATE
    { [ StringSame $HARVEST_MODE CURRENTDIR ] } USECWD
  ENDIF
ENDIF

