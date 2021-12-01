#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$

1 OUTPUT SCALEPACK
1 LABIN F(+) = $Fp_SAD SIGF(+) = $SIGFp_SAD F(-) = $Fn_SAD SIGF(-) = $SIGFn_SAD
1 FSQUAR
1 SCALE $MTZTOVAR_SCALE
1 END
