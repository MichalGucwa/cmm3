#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
#CCP4I SCRIPT TEMPLATE distang
{[IfSet $TITLE]} title $TITLE

1 distance
- $INTRA_RES all | vdw
- $INTRA_MOL intra | inter

{[IfSet $SPACE_GROUP]}  symmetry $SPACE_GROUP

{ $N_ATOM_RADII > 0 } radii
LOOP n 1 $N_ATOM_RADII
- 1 $ATOMTYPE($n) $ATOMRADIUS($n)
ENDLOOP
$IFADDRADIUS addradius $ADDRADIUS
$IFANGLE angle
$IFTORSION torsion
{[IfSet $DMIN]} dmin $DMIN

{[IfSet $FROMRANGE]} from 
CASE $FROMRANGE
CASEMATCH ATOM
- 1 atom $FROMATOM1 to $FROMATOM2
CASEMATCH RES
- 1 res $FROMRES1 to $FROMRES2
ENDCASE
- {[IfSet $FROMCHAIN]} chain $FROMCHAIN

{[IfSet $TORANGE]} to
CASE $TORANGE
CASEMATCH ATOM
- 1 atom $TOATOM1 to $TOATOM2
CASEMATCH RES
- 1 res $TORES1 to $TORES2
ENDCASE
- {[IfSet $TOCHAIN]} chain $TOCHAIN

{[StringSame $OUTPUT_MODE LPOUT PDBCONN DISTOUT]} OUTPUT 
CASE $OUTPUT_MODE
CASEMATCH LPOUT
- 1 lpout $LPOUT
CASEMATCH PDBCONN
- 1 pdbconn $PDBCONN
CASEMATCH DISTOUT
- 1 distout
ENDCASE

1 end

