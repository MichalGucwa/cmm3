#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
{[IfSet $TITLE]}  TITLE $TITLE
{[IfSet $CELL_LAMBDA]} CELL $CELL_LAMBDA $CELL_1  $CELL_2 $CELL_3 $CELL_4 $CELL_5 $CELL_6
{[IfSet $CELL_Z]} ZERR $CELL_Z $CELL_ERR_1 $CELL_ERR_2 $CELL_ERR_3 $CELL_ERR_4 $CELL_ERR_5 $CELL_ERR_6
{[IfSet $LATTICE]} LATT $LATTICE
LOOP n 1 $NSYMM
1 SYMM $SYMM($n)
ENDLOOP
1 SFAC $SFAC_LIST
1 UNIT $UNIT_LIST
1 OMIT $OMIT_S
CASE $SHELX_MODE
CASEMATCH PATTERSON
1 PATT $TRY_NVECTORS
IF { $INPUT_NVECT > 0 } 
LOOP n 1 $INPUT_NVECT
1 VECT $VECT_X($n) $VECT_Y($n) $VECT_Z($n)
ENDLOOP
ENDIF
CASEMATCH DIRECT
1 TREF 
- {[IfSet $TREF_NP] } np $TREF_NP
- {[IfSet $TREF_NE] } nE $TREF_NE
- {[IfSet $TREF_KAPSCAL] } nE $TREF_KAPSCAL
ENDCASE
ENDIF
1 HKLF $SHELX_HKLF
1 END
