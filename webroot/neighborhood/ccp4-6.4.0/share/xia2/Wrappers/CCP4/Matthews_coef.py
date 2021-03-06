#!/usr/bin/env python
# Matthews_coef.py
#   Copyright (C) 2006 CCLRC, Graeme Winter
#
#   This code is distributed under the BSD license, a copy of which is
#   included in the root directory of this package.
#
# 5th June 2006
#
# An example of an matthews_coef CCP4 program wrapper, which can be used
# as the base for other wrappers.
#
# Provides:
#
# Solvent contents given a number of molecules, a sequence length and a unit
# cell and symmetry.

import os
import sys

if not os.environ.has_key('XIA2CORE_ROOT'):
    raise RuntimeError, 'XIA2CORE_ROOT not defined'

if not os.path.join(os.environ['XIA2CORE_ROOT'],
                    'Python') in sys.path:
    sys.path.append(os.path.join(os.environ['XIA2CORE_ROOT'],
                                 'Python'))

from Driver.DriverFactory import DriverFactory
from Decorators.DecoratorFactory import DecoratorFactory

def Matthews_coef(DriverType = None):
    '''A factory for Matthews_coefWrapper classes.'''

    DriverInstance = DriverFactory.Driver(DriverType)
    CCP4DriverInstance = DecoratorFactory.Decorate(DriverInstance, 'ccp4')

    class Matthews_coefWrapper(CCP4DriverInstance.__class__):
        '''A wrapper for Matthews_coef, using the CCP4-ified Driver.'''

        def __init__(self):
            # generic things
            CCP4DriverInstance.__class__.__init__(self)

            self.set_executable(os.path.join(
                os.environ.get('CBIN', ''), 'matthews_coef'))

            self._nmol = 1
            self._nres = 0
            self._cell = None
            self._spacegroup = None

            # results

            self._solvent = 0.0

            return

        # setters follow

        def set_nmol(self, nmol):
            self._nmol = nmol
            return

        def set_nres(self, nres):
            self._nres = nres
            return

        def set_cell(self, cell):
            self._cell = cell
            return

        def set_spacegroup(self, spacegroup):
            self._spacegroup = spacegroup
            return

        def compute_solvent(self):

            self.start()

            self.input('cell %f %f %f %f %f %f' % tuple(self._cell))

            # cannot cope with spaces in the spacegroup!

            self.input('symmetry %s' % self._spacegroup.replace(' ', ''))
            self.input('nres %d' % self._nres)
            self.input('nmol %d' % self._nmol)

            self.close_wait()

            self.check_for_errors()
            self.check_ccp4_errors()

            # get the useful information out from here...

            for line in self.get_all_output():
                if 'Assuming protein density' in line:
                    self._solvent = 0.01 * float(line.split()[-1])

            return

        def get_solvent(self):
            return self._solvent


    return Matthews_coefWrapper()

if __name__ == '__main__':

    # then run a test!

    m = Matthews_coef()

    m.set_spacegroup('P43212')
    m.set_cell((96.0, 96.0, 36.75, 90.0, 90.0, 90.0))
    m.set_nmol(2)
    m.set_nres(82)

    m.compute_solvent()

    print m.get_solvent()
