#
#     Copyright (C) 2005  Martyn Winn
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$

{ [ StringSame $PDBCUR_ACTION SUMMARISE ] } SUMMARISE
{ [ StringSame $PDBCUR_ACTION DELHYD ] } DELHYD
{ [ StringSame $PDBCUR_ACTION MOSTPROB ] } MOSTPROB
{ [ StringSame $PDBCUR_ACTION CUTOCC ] } CUTOCC $CUTOCC_CUTOFF
{ [ StringSame $PDBCUR_ACTION NOANISOU ] } NOANISOU
1 END
