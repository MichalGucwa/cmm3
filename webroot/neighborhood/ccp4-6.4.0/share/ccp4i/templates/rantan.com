#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
{ [IfSet $TITLE] } title  $TITLE
LABELLINE labin "EVAL" 
LABELLINE - "PHI WT"
LABELLINE labout $LABOUT

$EXCLUDE_RESOLUTION resolution $EXCLUDE_RESOLUTION_MIN $EXCLUDE_RESOLUTION_MAX
{ [regexp SWTR $SWTR]}  swtr
$LIST list

{ $WFOM && ([IfSet $WABS] || [IfSet $WPSI] || [IfSet $WRES]) } wfom
- { [IfSet $WABS] }  abs $WABS
- { [IfSet $WPSI] }  psi $WPSI
- { [IfSet $WRES] }  res $WRES

{ $IFEMAX && [IfSet $EMAX] } EMAX $EMAX
{ $IFEMAX && [IfSet $EMIN] } EMIN $EMIN
{ [IfSet $EPSI] } EPSI $EPSI
{ [IfSet $KMIN] } KMIN $KMIN
{ [IfSet $KMAX] } KMAX $KMAX 
{ [IfSet $MAXS] } MAXS $MAXS
{ [IfSet $NRAN] } NRAN $NRAN
{ [IfSet $NREF] } NREF $NREF
{ [IfSet $NZRO] } NZRO $NZRO
{ [IfSet $NOUT] } NOUT $NOUT
{ [IfSet $SKIP] } SKIP $SKIP
{ [IfSet $WMIN] } WMIN $WMIN
{ [IfSet $WTRI] } WTRI $WTRI 

1 end
