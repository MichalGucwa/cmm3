# FindFreeFlag.py
# Maintained by G.Winter
# 11th July 2008
#
# A jiffy to try and identify the FreeR column in an MTZ file - will look for
# FreeR_flag, then *free*, will check that the column type is 'I' and so
# will be useful when an external reflection file is passed in for copying
# of the FreeR column.
#

import os
import sys
import math

if not os.path.join(os.environ['XIA2CORE_ROOT'], 'Python') in sys.path:
    sys.path.append(os.path.join(os.environ['XIA2CORE_ROOT'], 'Python'))

if not os.environ['XIA2_ROOT'] in sys.path:
    sys.path.append(os.environ['XIA2_ROOT'])

from Wrappers.CCP4.Mtzdump import Mtzdump

def FindFreeFlag(hklin):
    '''Try to find the FREE column in hklin. Raise exception if no column is
    found or if more than one candidate is found.'''

    # get the information we need here...

    mtzdump = Mtzdump()
    mtzdump.set_hklin(hklin)
    mtzdump.dump()
    columns = mtzdump.get_columns()

    ctypes = { }

    for c in columns:
        ctypes[c[0]] = c[1]

    if 'FreeR_flag' in ctypes.keys():
        if ctypes['FreeR_flag'] != 'I':
            raise RuntimeError, 'FreeR_flag column found: type not I'

        return 'FreeR_flag'

    # ok, so the usual one wasn't there, look for anything with "free"
    # in it...

    possibilities = []

    for c in ctypes.keys():
        if 'free' in c.lower():
            possibilities.append(c)

    if len(possibilities) == 0:
        raise RuntimeError, 'no candidate FreeR_flag columns found'

    if len(possibilities) == 1:
        if ctypes[possibilities[0]] != 'I':
            raise RuntimeError, 'FreeR_flag column found (%s): type not I' % \
                  possibilities[0]

        return possibilities[0]

    raise RuntimeError, 'Multiple candidate FreeR_flag columns found'

if __name__ == '__main__':

    if len(sys.argv) < 2:
        raise RuntimeError, '%s hklin' % sys.argv[0]

    print FindFreeFlag(sys.argv[1])
