#
#     Copyright (C) 1999-2008 Charles Ballard
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
{ [IfSet $HARVEST_PNAME] || [IfSet $HARVEST_XNAME] || [IfSet $HARVEST_DNAME] }  NAME
  - { [IfSet $HARVEST_PNAME] } PROJECT $HARVEST_PNAME
  - { [IfSet $HARVEST_XNAME] } CRYSTAL $HARVEST_XNAME
  - { [IfSet $HARVEST_DNAME] } DATASET $HARVEST_DNAME

