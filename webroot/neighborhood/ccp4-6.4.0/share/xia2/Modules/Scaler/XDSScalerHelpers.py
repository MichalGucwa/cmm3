#!/usr/bin/env python
# XDSScalerHelpers.py
#   Copyright (C) 2007 CCLRC, Graeme Winter
#
#   This code is distributed under the BSD license, a copy of which is
#   included in the root directory of this package.
#
# 5th July 2007
#
# Code to help the scaler along - this will basically be a bunch of jiffy
# functions...
#

import os
import sys

if not os.environ.has_key('XIA2_ROOT'):
    raise RuntimeError, 'XIA2_ROOT not defined'

if not os.environ['XIA2_ROOT'] in sys.path:
    sys.path.append(os.environ['XIA2_ROOT'])

from Handlers.Streams import Debug
from lib.bits import auto_logfiler
from Wrappers.CCP4.Combat import Combat as _Combat
from Wrappers.CCP4.Pointless import Pointless as _Pointless

class XDSScalerHelper:
    '''A class which contains functions which will help the XDS Scaler
    with its work. This is implemented as a class to allow properties
    like working directories and so on to be maintained.'''

    def __init__(self):
        self._working_directory = os.getcwd()

        return

    def Combat(self):
        '''Create a Combat wrapper from _Combat - set the working directory
        and log file stuff as a part of this...'''
        combat = _Combat()
        combat.set_working_directory(self.get_working_directory())
        auto_logfiler(combat)
        return combat

    def Pointless(self):
        '''Create a Pointless wrapper from _Pointless - set working directory
        and log file stuff as a part of this...'''
        pointless = _Pointless()
        pointless.set_working_directory(self.get_working_directory())
        auto_logfiler(pointless)
        return pointless

    def set_working_directory(self, working_directory):
        self._working_directory = working_directory
        return

    def get_working_directory(self):
        return self._working_directory

    def parse_xscale_ascii_header(self, xds_ascii_file):
        '''Parse out the input reflection files which contributed to this
        reflection file.'''

        file_map = { }

        for line in open(xds_ascii_file, 'r').readlines():
            if not line[0] == '!':
                break

            if 'ISET' in line and 'INPUT_FILE' in line:
                set = int(line.split()[2].strip())
                input_file = line.split('=')[2].strip()

                file_map[set] = input_file

                Debug.write('Set %d is from data %s' % (set, input_file))

        return file_map

    def parse_xscale_ascii_wavelength(self, xds_ascii_file):

        wavelength_dict = { }

        for line in open(xds_ascii_file, 'r').readlines():
            if not line[0] == '!':
                break

            if 'ISET' in line and 'X-RAY_WAVELENGTH' in line:
                set = int(line.split()[2].strip())
                wavelength = float(line.split('=')[2].split()[0])

                wavelength_dict[set] = wavelength

                Debug.write('Set %d wavelength %f' % (set, wavelength))

        if len(wavelength_dict.keys()) > 1:
            raise RuntimeError, 'more than one wavelength found'

        return wavelength_dict[wavelength_dict.keys()[0]]

    def split_xscale_ascii_file(self, xds_ascii_file, prefix):
        '''Split the output of XSCALE to separate reflection files for
        each run. The output files will be called ${prefix}${input_file}.'''

        file_map = self.parse_xscale_ascii_header(xds_ascii_file)

        files = { }
        return_map = { }

        keys = file_map.keys()

        for k in keys:
            files[k] = open(os.path.join(
                self.get_working_directory(),
                '%s%s' % (prefix, file_map[k])), 'w')

            return_map[file_map[k]] = '%s%s' % (prefix, file_map[k])

        # copy the header to all of the files

        for line in open(xds_ascii_file, 'r').readlines():
            if not line[0] == '!':
                break

            for k in keys:

                if 'ISET' in line and \
                       int(line.split('ISET=')[1].split()[0]) != k:
                    continue

                files[k].write(line)

        # next copy the appropriate reflections to each file

        for line in open(xds_ascii_file, 'r').readlines():
            if line[0] == '!':
                continue

            # FIXME this will not be correct if zero-dose correction
            # has been used as this applies an additional record at
            # the end... though it should always be #9
            k = int(line.split()[9])
            files[k].write(line)


        # then write the tailer

        for k in keys:
            files[k].write('!END_OF_DATA\n')
            files[k].close()


        return return_map

    def split_and_convert_xscale_output(self, input_file, prefix,
                                        project_info, scale_factor = 1.0):
        '''Split (as per method above) then convert files to MTZ
        format via combat. The latter step will add the
        pname / xname / dname things from the dictionary supplied.'''

        data_map = self.split_xscale_ascii_file(input_file, prefix)

        for token in data_map.keys():

            if not project_info.has_key(token):
                raise RuntimeError, 'project info for %s not available' % \
                      token

            hklin = os.path.join(self.get_working_directory(),
                                 data_map[token])
            hklout = os.path.join(self.get_working_directory(),
                                  '%s.mtz' % hklin[:-4])

            wavelength = self.parse_xscale_ascii_wavelength(hklin)

            pname, xname, dname = project_info[token]

            # in here need to replace combat with pointless - which
            # will require a little juggling...

            if False:

                c = self.Combat()
                c.set_hklin(hklin)
                c.set_hklout(hklout)
                c.set_project_info(pname, xname, dname)
                if wavelength > 0.0:
                    c.set_wavelength(wavelength)

                c.run()

            else:

                p = self.Pointless()
                p.set_xdsin(hklin)
                p.set_hklout(hklout)
                p.set_project_info(pname, xname, dname)
                p.set_scale_factor(scale_factor)
                p.xds_to_mtz()

            data_map[token] = hklout

        return data_map

if __name__ == '__main__':

    xsh = XDSScalerHelper()

    input_file = os.path.join(
        os.environ['X2TD_ROOT'], 'Test', 'UnitTest',
        'Modules', 'XDSScalerHelpers', '1VR9_NAT.HKL')
    project_info = {'NATIVE_NATIVE_HR.HKL':('JCSG', '1VR9', 'NATIVE'),
                    'NATIVE_NATIVE_LR.HKL':('JCSG', '1VR9', 'NATIVE')}
    print xsh.split_and_convert_xscale_output(input_file, 'SCALED_',
                                              project_info)
