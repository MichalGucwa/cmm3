#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
1 slvfrc $SOLVENT_FRACTION
1 mulsolv
 - $AUTO_SCALING auto
 - 1 $SOLVENT_MULTIPLIER
1 slvdens $SOLVENT_DENSITY
1 radius $SOLVENT_RADIUS
1 trunc $TRUNCATE_MIN $TRUNCATE_MAX
$EXTRUDE_MODE extrude
$EXTRUDE_MODE ptos $DENSITY_RATIO
$SOLOMON_MAPOUT mapout
1 end
