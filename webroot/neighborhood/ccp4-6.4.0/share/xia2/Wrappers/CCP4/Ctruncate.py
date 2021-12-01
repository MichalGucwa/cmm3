#!/usr/bin/env python
# Ctruncate.py
#   Copyright (C) 2006 CCLRC, Graeme Winter
#
#   This code is distributed under the BSD license, a copy of which is
#   included in the root directory of this package.
#
# 26th October 2006
#
# A wrapper for the CCP4 program Ctruncate, which calculates F's from
# I's and gives a few useful statistics about the data set.
#
# FIXME 26/OCT/06 this needs to be able to take into account the solvent
#                 content of the crystal (at the moment it will be assumed
#                 to be 50%.)
#
# FIXME 16/NOV/06 need to be able to get the estimates B factor from the
#                 Wilson plot and also second moment stuff, perhaps?
#
# FIXME 02/FEB/11 read the number of reflections excluded from the data set
#                 as systematic absences and verify that this is equal to
#                 the number of reflections going in - number coming out.

import os
import sys

if not os.environ.has_key('XIA2CORE_ROOT'):
    raise RuntimeError, 'XIA2CORE_ROOT not defined'

if not os.path.join(os.environ['XIA2CORE_ROOT'], 'Python') in sys.path:
    sys.path.append(os.path.join(os.environ['XIA2CORE_ROOT'],
                                 'Python'))

if not os.environ.has_key('XIA2_ROOT'):
    raise RuntimeError, 'XIA2_ROOT not defined'

if not os.path.join(os.environ['XIA2_ROOT']) in sys.path:
    sys.path.append(os.path.join(os.environ['XIA2_ROOT']))

from Driver.DriverFactory import DriverFactory
from Decorators.DecoratorFactory import DecoratorFactory
from lib.bits import transpose_loggraph
from Handlers.Streams import Chatter, Debug

def Ctruncate(DriverType = None):
    '''A factory for CtruncateWrapper classes.'''

    DriverInstance = DriverFactory.Driver(DriverType)

    class CtruncateWrapper(DriverInstance.__class__):
        '''A wrapper for Ctruncate, using the regular Driver.'''

        def __init__(self):
            # generic things
            DriverInstance.__class__.__init__(self)

            self.set_executable(os.path.join(
                os.environ.get('CBIN', ''), 'ctruncate'))

            self._anomalous = False
            self._nres = 0

            self._b_factor = 0.0
            self._moments = None

            # numbers of reflections in and out, and number of absences
            # counted

            self._nref_in = 0
            self._nref_out = 0
            self._nabsent = 0

            return

        def set_hklin(self, hklin):
            self._hklin = hklin
            return

        def set_hklout(self, hklout):
            self._hklout = hklout
            return

        def set_nres(self, nres):
            self._nres = nres
            return

        def set_anomalous(self, anomalous):
            self._anomalous = anomalous
            return

        def truncate(self):
            '''Actually perform the truncation procedure.'''

            if not self._hklin:
                raise RuntimeError, 'hklin not defined'
            if not self._hklout:
                raise RuntimeError, 'hklout not defined'

            self.add_command_line('-hklin')
            self.add_command_line(self._hklin)
            self.add_command_line('-hklout')
            self.add_command_line(self._hklout)

            if self._nres:
                self.add_command_line('-nres')
                self.add_command_line('%d' % self._nres)

            if self._anomalous:
                self.add_command_line('-colano')
                self.add_command_line('/*/*/[I(+),SIGI(+),I(-),SIGI(-)]')
            
	    self.add_command_line('-colin')
            self.add_command_line('/*/*/[IMEAN,SIGIMEAN]')
    
            self.start()
            self.close_wait()

            try:
                self.check_for_errors()

            except RuntimeError, e:
                try:
                    os.remove(self._hklout)
                except:
                    pass

                raise RuntimeError, 'ctruncate failure'

            nref = 0

            for record in self.get_all_output():
                if 'Number of reflections:' in record:
                    nref = int(record.split()[-1])

                if 'B =' in record and 'intercept' in record:
                    self._b_factor = float(record.split()[2])

            self._nref_in, self._nref_out = nref, nref
            self._nabsent = 0
            
            results = self.parse_ccp4_loggraph()
            if 'Acentric moments of E using Truncate method' in results:
                moments = transpose_loggraph(
                    results['Acentric moments of E using Truncate method'])
            elif 'Acentric moments of E' in results:
                moments = transpose_loggraph(
                    results['Acentric moments of E'])
            else:
                raise RuntimeError, 'Acentric moments of E not found'
                
            self._moments = moments

            return

        def get_b_factor(self):
            return self._b_factor

        def get_moments(self):
            return self._moments

        def get_nref_in(self):
            return self._nref_in

        def get_nref_out(self):
            return self._nref_out

        def get_nabsent(self):
            return self._nabsent

        def parse_ccp4_loggraph(self):
            '''Look through the standard output of the program for
            CCP4 loggraph text. When this is found store it in a
            local dictionary to allow exploration.'''

            # reset the loggraph store
            self._loggraph = { }

            output = self.get_all_output()

            for i in range(len(output)):
                line = output[i]
                if '$TABLE' in line:

                    n_dollar = line.count('$$')
                    
                    current = line.split(':')[1].replace('>',
                                                                  '').strip()
                    self._loggraph[current] = { }
                    self._loggraph[current]['columns'] = []
                    self._loggraph[current]['data'] = []

                    loggraph_info = ''

                    while n_dollar < 4:
                        n_dollar += line.count('$$')
                        loggraph_info += line

                        if n_dollar == 4:
                            break
                        
                        i += 1
                        line = output[i]

                    tokens = loggraph_info.split('$$')
                    self._loggraph[current]['columns'] = tokens[1].split()

                    if len(tokens) < 4:
                        raise RuntimeError, 'loggraph "%s" broken' % current
                    
                    data = tokens[3].split('\n')

                    columns = len(self._loggraph[current]['columns'])

                    for j in range(len(data)):
                        record = data[j].split()
                        if len(record) == columns:
                            self._loggraph[current]['data'].append(record)

            return self._loggraph                
        
    return CtruncateWrapper()

if __name__ == '__main__':

    ctruncate = Ctruncate()
    ctruncate.set_hklin(sys.argv[1])
    ctruncate.set_hklout(sys.argv[2])
    ctruncate.truncate()

    print ctruncate.get_nref_in(), ctruncate.get_nref_out(), \
          ctruncate.get_nabsent()
