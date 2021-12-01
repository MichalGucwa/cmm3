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
1 labin file_number 1
LOOP n 1 $NLABIN
- 1 E$n = $LABIN($n)
ENDLOOP
1 xname file_number 1
LOOP n 1 $NLABIN
- { [IfSet $ASSOCX($n)] } E$n = $ASSOCX($n)
ENDLOOP
1 dname file_number 1
LOOP n 1 $NLABIN
- { [IfSet $ASSOCX($n)] } E$n = $ASSOCD($n)
ENDLOOP
LOOP n 1 $N_DNAME
{ [IfSet $PNAME($n)] } dpname file_number 1 $XNAME($n) $DNAME($n) $PNAME($n)
ENDLOOP
LOOP n 1 $N_DNAME
{ $DCELL_1($n) } dcell file_number 1
- 1 $XNAME($n) $DNAME($n) $DCELL_1($n) $DCELL_2($n) $DCELL_3($n) 
- 1 $DCELL_4($n) $DCELL_5($n) $DCELL_6($n)
ENDLOOP
LOOP n 1 $N_DNAME
{ $DWAVE($n) } dwave file_number 1 $XNAME($n) $DNAME($n) $DWAVE($n)
ENDLOOP
