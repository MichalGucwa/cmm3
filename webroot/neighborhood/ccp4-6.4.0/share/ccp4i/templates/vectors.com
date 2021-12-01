#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
{ [IfSet $SPACE_GROUP ] } SYMMETRY $SPACE_GROUP
LOOP N 1 $VECTORS_NATOMS
{ [IfSet $VECTORS_ATOM_NAME($N) ] } ATOM $VECTORS_ATOM_NAME($N) $VECTORS_ATOM_X($N) $VECTORS_ATOM_Y($N) $VECTORS_ATOM_Z($N)
ENDLOOP
