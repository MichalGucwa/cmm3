#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
$PLOT PLOT
!$PLOT PLOT OFF
{$PLOT && $MAINCHAIN} MAINCHAIN
$RIGIDBODY RIGIDBODY 
!$RIGIDBODY RIGIDBODY OFF 
$RIGIDBODY DUBINS $DIST_BINS $PS_BINS
$RIGIDBODY DURANGE $DURANGE
$FITTLS FITTLS
!$FITTLS FITTLS OFF 
$FITTLS TLSCYCLES $TLSCYCLES
1 END

