#!/usr/bin/env python
# Mtz2various.py
#   Copyright (C) 2006 CCLRC, Graeme Winter
#
#   This code is distributed under the BSD license, a copy of which is
#   included in the root directory of this package.
#
# 27th October 2006
#
# A wrapper for the CCP4 program mtz2various, for converting mtz files
# to .sca format.
#

import os
import sys

if not os.environ.has_key('XIA2CORE_ROOT'):
    raise RuntimeError, 'XIA2CORE_ROOT not defined'

sys.path.append(os.path.join(os.environ['XIA2CORE_ROOT'],
                             'Python'))

from Driver.DriverFactory import DriverFactory
from Decorators.DecoratorFactory import DecoratorFactory

def Mtz2various(DriverType = None):
    '''A factory for Mtz2variousWrapper classes.'''

    DriverInstance = DriverFactory.Driver(DriverType)
    CCP4DriverInstance = DecoratorFactory.Decorate(DriverInstance, 'ccp4')

    class Mtz2variousWrapper(CCP4DriverInstance.__class__):
        '''A wrapper for Mtz2various, using the CCP4-ified Driver.'''

        def __init__(self):
            # generic things
            CCP4DriverInstance.__class__.__init__(self)

            self.set_executable(os.path.join(
                os.environ.get('CBIN', ''), 'mtz2various'))

            # this will allow extraction of specific intensities
            # from a multi-set reflection file
            self._dataset_suffix = ''

            return

        def set_suffix(self, suffix):
            if suffix:
                self._dataset_suffix = '_%s' % suffix
            else:
                self._dataset_suffix = suffix
            return

        def convert(self):
            '''Convert the input reflection file to .sca format.'''

            self.check_hklin()
            self.check_hklout()

            self.start()

            labin = 'I(+)=I(+)%s SIGI(+)=SIGI(+)%s ' % \
                    (self._dataset_suffix, self._dataset_suffix)
            labin += 'I(-)=I(-)%s SIGI(-)=SIGI(-)%s' % \
                     (self._dataset_suffix, self._dataset_suffix)

            self.input('output scal')
            self.input('labin %s' % labin)

            self.close_wait()

            output = self.get_all_output()

            try:
                self.check_for_errors()
                self.check_ccp4_errors()

            except RuntimeError, e:
                try:
                    os.remove(self.get_hklout())
                except:
                    pass
            return

        def convert_shelx(self, unmerged = False):
            '''Convert the input reflection file to SHELX hklf4 format.'''

            self.check_hklin()
            self.check_hklout()

            self.start()

            if self._dataset_suffix or unmerged:
                labin = 'I=I%s SIGI=SIGI%s' % \
                        (self._dataset_suffix, self._dataset_suffix)

            else:
                labin = 'I=IMEAN SIGI=SIGIMEAN'

            self.input('output shelx')
            self.input('labin %s' % labin)

            self.close_wait()

            output = self.get_all_output()

            try:
                self.check_for_errors()
                self.check_ccp4_errors()

            except RuntimeError, e:
                try:
                    os.remove(self.get_hklout())
                except:
                    pass
            return

    return Mtz2variousWrapper()

if __name__ == '__main__':
    # then run a test...

    for hklin in sys.argv[1:]:
        m2v = Mtz2various()
        m2v.set_hklin(hklin)
        m2v.set_hklout('%s.sca' % hklin[:-4])
        m2v.convert()
