#
#     Copyright (C) 2010  Charles Ballard
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
#{ [IfSet $TITLE] } title  $TITLE
{ [IfSet $EMMODE] } MINI $EMMODE
{ [IfSet $COORDOUT] } COOR $COORDOUT
{ [IfSet $PROTONATE] } PROT $PROTONATE

1 end
