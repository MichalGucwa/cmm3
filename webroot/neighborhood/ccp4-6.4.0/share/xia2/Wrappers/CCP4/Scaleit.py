#!/usr/bin/env python
# Scaleit.py
#   Copyright (C) 2006 CCLRC, Graeme Winter
#
#   This code is distributed under the BSD license, a copy of which is
#   included in the root directory of this package.
#
# 27th October 2006
#
# A wrapper for the CCP4 program scaleit, for use when scaling together
# multiple data sets from a single crystal.
#
# 15/JAN/07 FIXME - need to be able to cope with a native data set
#                   scaled together with anomalous derivatives.
#
#

import os
import sys

if not os.environ.has_key('XIA2CORE_ROOT'):
    raise RuntimeError, 'XIA2CORE_ROOT not defined'

if not os.path.join(os.environ['XIA2CORE_ROOT'], 'Python') in sys.path:
    sys.path.append(os.path.join(os.environ['XIA2CORE_ROOT'],
                                 'Python'))

from Driver.DriverFactory import DriverFactory
from Decorators.DecoratorFactory import DecoratorFactory

# locally required wrappers

from Mtzdump import Mtzdump

def Scaleit(DriverType = None):
    '''A factory for ScaleitWrapper classes.'''

    DriverInstance = DriverFactory.Driver(DriverType)
    CCP4DriverInstance = DecoratorFactory.Decorate(DriverInstance, 'ccp4')

    class ScaleitWrapper(CCP4DriverInstance.__class__):
        '''A wrapper for Scaleit, using the CCP4-ified Driver.'''

        def __init__(self):
            # generic things
            CCP4DriverInstance.__class__.__init__(self)

            self.set_executable(os.path.join(
                os.environ.get('CBIN', ''), 'scaleit'))

            self._columns = []

            self._statistics = { }

            self._anomalous = False

            return

        def set_anomalous(self, anomalous):
            self._anomalous = anomalous
            return

        def find_columns(self):
            '''Identify columns to use with scaleit.'''

            # run mtzdump to get a list of columns out and also check that
            # this is a valid merged mtz file....

            self.check_hklin()

            md = Mtzdump()
            md.set_hklin(self.get_hklin())
            md.dump()

            # get information to check that this is merged

            # next get the column information - check that F columns are
            # present

            column_info = md.get_columns()

            columns = []

            j = 0
            groups = 0

            # assert that the columns for F, SIGF, DANO, SIGDANO for a
            # particular group will appear in that order if anomalous,
            # F, SIGF if not anomalous

            while j < len(column_info):
                c = column_info[j]
                name = c[0]
                type = c[1]

                if type == 'F' and name.split('_')[0] == 'F' and \
                       self._anomalous:
                    groups += 1
                    for i in range(4):
                        columns.append(column_info[i + j][0])

                    j += 4

                elif type == 'F' and name.split('_')[0] == 'F' and \
                       not self._anomalous:
                    groups += 1
                    for i in range(2):
                        columns.append(column_info[i + j][0])

                    j += 2
                else:
                    j += 1


            # ok that should be all of the groups identified

            self._columns = columns

            return columns

        def check_scaleit_errors(self):
            return

        def scaleit(self):
            '''Run scaleit and get some interesting facts out.'''

            self.check_hklin()

            # need to have a HKLOUT even if we do not want the
            # reflections...

            self.check_hklout()

            if not self._columns:
                self.find_columns()


            self.start()
            self.input('nowt')
            self.input('converge ncyc 4')
            self.input('converge abs 0.001')
            self.input('converge tolr -7')
            self.input('refine anisotropic wilson')
            self.input('auto')

            labin = 'labin FP=%s SIGFP=%s' % \
                    (self._columns[0], self._columns[1])

            if self._anomalous:
                groups = len(self._columns) // 4
            else:
                groups = len(self._columns) // 2

            for j in range(groups):

                if self._anomalous:
                    labin += ' FPH%d=%s' % (j + 1, self._columns[4 * j])
                    labin += ' SIGFPH%d=%s' % (j + 1, self._columns[4 * j + 1])
                    labin += ' DPH%d=%s' % (j + 1, self._columns[4 * j + 2])
                    labin += ' SIGDPH%d=%s' % (j + 1, self._columns[4 * j + 3])
                else:
                    labin += ' FPH%d=%s' % (j + 1, self._columns[2 * j])
                    labin += ' SIGFPH%d=%s' % (j + 1, self._columns[2 * j + 1])

            self.input(labin)

            self.close_wait()

            # check for errors

            try:
                self.check_for_errors()
                self.check_ccp4_errors()
                self.check_scaleit_errors()

            except RuntimeError, e:
                try:
                    os.remove(self.get_hklout())
                except:
                    pass

                raise e

            output = self.get_all_output()

            # generate mapping from derivative number to data set

            self._statistics['mapping'] = { }

            for j in range(groups):
                if self._anomalous:
                    self._statistics['mapping'][
                        j + 1] = self._columns[4 * j].replace('F_', '')
                else:
                    self._statistics['mapping'][
                        j + 1] = self._columns[2 * j].replace('F_', '')

            # now get some interesting information out...

            j = 0

            r_values = []

            while j < len(output):
                line = output[j]

                if 'APPLICATION OF SCALES AND ANALYSIS OF DIFFERENCES' in line:
                    current_derivative = -1

                    while not 'SUMMARY_END' in line:
                        list = line.split()
                        if 'Derivative' in list:
                            if not self._statistics.has_key('b_factor'):
                                self._statistics['b_factor'] = { }
                            self._statistics['b_factor'][int(list[1])] = {
                                'scale':float(list[2]),
                                'b':float(list[3]),
                                'dname':self._statistics[
                                'mapping'][int(list[1])]}
                            current_derivative = int(list[1])

                        if 'The equivalent isotropic' in line:
                            self._statistics['b_factor'][
                                current_derivative]['b'] = float(list[-1])

                        j += 1
                        line = output[j]

                if 'acceptable differences are less than' in line and \
                       groups == 1:
                    max_difference = float(line.split()[-1])
                    if max_difference > 0.01:
                        self._statistics['max_difference'] = max_difference

                if 'THE TOTALS' in line:
                    r_values.append(float(line.split()[6]))

                j += 1

            # transform back the r values to the statistics

            for j in range(len(r_values)):
                d = j + 1
                self._statistics['b_factor'][d]['r'] = r_values[j]


            return

        def get_statistics(self):
            '''Get the statistics from the Scaleit run.'''

            return self._statistics

    return ScaleitWrapper()

if __name__ == '__main__':
    s = Scaleit()

    if len(sys.argv) == 1:

        hklin = os.path.join(
            os.environ['X2TD_ROOT'],
            'Test', 'UnitTest', 'Wrappers', 'Scaleit',
            'TS03_INTER_RD.mtz')

    else:

        hklin = sys.argv[1]

    s.set_hklin(hklin)
    s.set_hklout('junk.mtz')
    s.set_anomalous(True)

    print s.find_columns()

    s.scaleit()

    stats = s.get_statistics()

    print stats['b_factor']

    if stats.has_key('max_difference'):
        print stats['max_difference']
