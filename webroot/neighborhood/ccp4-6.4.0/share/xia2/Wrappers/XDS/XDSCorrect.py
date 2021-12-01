#!/usr/bin/env python
# XDSCorrect.py
#   Copyright (C) 2006 CCLRC, Graeme Winter
#
#   This code is distributed under the BSD license, a copy of which is
#   included in the root directory of this package.
#
# A wrapper to handle the JOB=CORRECT module in XDS.
#
# 04/JAN/07 FIXME - need to know if we want anomalous pairs separating
#                   in this module...

import os
import sys
import shutil
import math
from cctbx.uctbx import unit_cell

if not os.environ.has_key('XIA2CORE_ROOT'):
    raise RuntimeError, 'XIA2CORE_ROOT not defined'

if not os.environ.has_key('XIA2_ROOT'):
    raise RuntimeError, 'XIA2_ROOT not defined'

if not os.path.join(os.environ['XIA2CORE_ROOT'],
                    'Python') in sys.path:
    sys.path.append(os.path.join(os.environ['XIA2CORE_ROOT'],
                                 'Python'))

if not os.environ['XIA2_ROOT'] in sys.path:
    sys.path.append(os.environ['XIA2_ROOT'])

from Driver.DriverFactory import DriverFactory

# interfaces that this inherits from ...
from Schema.Interfaces.FrameProcessor import FrameProcessor

# generic helper stuff
from XDS import header_to_xds, xds_check_version_supported, xds_check_error

# specific helper stuff
from XDSCorrectHelpers import _parse_correct_lp

from Experts.ResolutionExperts import xds_integrate_hkl_to_list, \
     bin_o_tron, digest

# global flags
from Handlers.Flags import Flags
from Handlers.Streams import Debug

def XDSCorrect(DriverType = None):

    DriverInstance = DriverFactory.Driver(DriverType)

    class XDSCorrectWrapper(DriverInstance.__class__,
                            FrameProcessor):
        '''A wrapper for wrapping XDS in correct mode.'''

        def __init__(self):

            # set up the object ancestors...

            DriverInstance.__class__.__init__(self)
            FrameProcessor.__init__(self)

            # now set myself up...

            self._parallel = Flags.get_parallel()

            if self._parallel <= 1:
                self.set_executable('xds')
            else:
                self.set_executable('xds_par')

            # generic bits

            self._data_range = (0, 0)
            self._spot_range = []
            self._background_range = (0, 0)
            self._resolution_range = (0, 0)
            self._resolution_high = 0.0
            self._resolution_low = 40.0

            # specific information

            self._cell = None
            self._spacegroup_number = None
            self._anomalous = False

            self._polarization = 0.0

            self._reindex_matrix = None
            self._reindex_used = None

            self._input_data_files = { }
            self._output_data_files = { }

            self._input_data_files_list = []

            self._output_data_files_list = ['GXPARM.XDS']

            self._ice = 0
            self._excluded_regions = []

            # the following input files are also required:
            #
            # INTEGRATE.HKL
            # REMOVE.HKL
            #
            # and XDS_ASCII.HKL is produced.

            # in
            self._integrate_hkl = None
            self._remove_hkl = None

            # out
            self._xds_ascii_hkl = None
            self._results = None
            self._remove = []

            return

        # getter and setter for input / output data

        def set_anomalous(self, anomalous):
            self._anomalous = anomalous
            return

        def get_anomalous(self):
            return self._anomalous

        def set_spacegroup_number(self, spacegroup_number):
            self._spacegroup_number = spacegroup_number
            return

        def set_cell(self, cell):
            self._cell = cell
            return

        def set_ice(self, ice):
            self._ice = ice
            return

        def set_excluded_regions(self, excluded_regions):
            self._excluded_regions = excluded_regions
            return

        def set_polarization(self, polarization):
            if polarization > 1.0 or polarization < 0.0:
                raise RuntimeError, 'bad value for polarization: %.2f' % \
                      polarization
            self._polarization = polarization

        def set_reindex_matrix(self, reindex_matrix):
            if not len(reindex_matrix) == 12:
                raise RuntimeError, 'reindex matrix must be 12 numbers'
            self._reindex_matrix = reindex_matrix
            return

        def get_reindex_used(self):
            return self._reindex_used

        def set_resolution_high(self, resolution_high):
            self._resolution_high = resolution_high

        def set_resolution_low(self, resolution_low):
            self._resolution_low = resolution_low

        def set_input_data_file(self, name, data):
            self._input_data_files[name] = data
            return

        def get_output_data_file(self, name):
            return self._output_data_files[name]

        def set_integrate_hkl(self, integrate_hkl):
            self._integrate_hkl = integrate_hkl
            return

        def set_remove_hkl(self, remove_hkl):
            self._remove_hkl = remove_hkl
            return

        def get_remove(self):
            return self._remove

        def get_xds_ascii_hkl(self):
            return self._xds_ascii_hkl

        # this needs setting up from setup_from_image in FrameProcessor

        def set_data_range(self, start, end):
            self._data_range = (start, end)

        def add_spot_range(self, start, end):
            self._spot_range.append((start, end))

        def set_background_range(self, start, end):
            self._background_range = (start, end)

        def get_result(self, name):
            if not self._results:
                raise RuntimeError, 'no results'

            if not self._results.has_key(name):
                raise RuntimeError, 'result name "%s" unknown' % name

            return self._results[name]

        def run(self):
            '''Run correct.'''

            # this is ok...
            # if not self._cell:
            # raise RuntimeError, 'cell not set'
            # if not self._spacegroup_number:
            # raise RuntimeError, 'spacegroup not set'

            image_header = self.get_header()

            # crank through the header dictionary and replace incorrect
            # information with updated values through the indexer
            # interface if available...

            # need to add distance, wavelength - that should be enough...

            if self.get_distance():
                image_header['distance'] = self.get_distance()

            if self.get_wavelength():
                image_header['wavelength'] = self.get_wavelength()

            if self.get_two_theta():
                image_header['two_theta'] = self.get_two_theta()

            header = header_to_xds(image_header)

            xds_inp = open(os.path.join(self.get_working_directory(),
                                        'XDS.INP'), 'w')

            # what are we doing?
            xds_inp.write('JOB=CORRECT\n')
            xds_inp.write('MAXIMUM_NUMBER_OF_PROCESSORS=%d\n' % \
                          self._parallel)

            # check to see if we are excluding ice rings
            if self._ice != 0:
                Debug.write('Excluding ice rings')

                for record in open(os.path.join(
                    os.environ['XIA2_ROOT'],
                    'Data', 'ice-rings.dat')).readlines():

                    resol = tuple(map(float, record.split()[:2]))

                    xds_inp.write('EXCLUDE_RESOLUTION_RANGE= %.2f %.2f\n' % \
                                  resol)
            
            # exclude requested resolution ranges
            if len(self._excluded_regions) != 0:
                Debug.write('Excluding regions: %s' % `self._excluded_regions`)

                for upper, lower in self._excluded_regions:
                    xds_inp.write('EXCLUDE_RESOLUTION_RANGE= %.2f %.2f\n' % \
                                   (upper, lower))

            # postrefine everything to give better values to the
            # next INTEGRATE run
            xds_inp.write(
                'REFINE(CORRECT)=DISTANCE BEAM AXIS ORIENTATION CELL\n')

            if self._polarization > 0.0:
                xds_inp.write('FRACTION_OF_POLARIZATION=%.2f\n' % \
                              self._polarization)

            for record in header:
                xds_inp.write('%s\n' % record)

            name_template = os.path.join(self.get_directory(),
                                         self.get_template().replace('#', '?'))

            record = 'NAME_TEMPLATE_OF_DATA_FRAMES=%s\n' % \
                     name_template

            xds_inp.write(record)

            xds_inp.write('DATA_RANGE=%d %d\n' % self._data_range)
            # xds_inp.write('MINIMUM_ZETA=0.1\n')
            # include the resolution range, perhaps
            if self._resolution_high or self._resolution_low:
                xds_inp.write('INCLUDE_RESOLUTION_RANGE=%.2f %.2f\n' % \
                              (self._resolution_low, self._resolution_high))

            if self._anomalous:
                xds_inp.write('FRIEDEL\'S_LAW=FALSE\n')
                xds_inp.write('STRICT_ABSORPTION_CORRECTION=TRUE\n')
            else:
                xds_inp.write('FRIEDEL\'S_LAW=TRUE\n')

            if self._spacegroup_number:
                if not self._cell:
                    raise RuntimeError, \
                          'cannot set spacegroup without unit cell'

                xds_inp.write('SPACE_GROUP_NUMBER=%d\n' % \
                              self._spacegroup_number)
            if self._cell:
                xds_inp.write('UNIT_CELL_CONSTANTS=')
                xds_inp.write('%6.2f %6.2f %6.2f %6.2f %6.2f %6.2f\n' % \
                              tuple(self._cell))
            if self._reindex_matrix:
                xds_inp.write('REIDX=%d %d %d %d %d %d %d %d %d %d %d %d' % \
                              tuple(map(int, self._reindex_matrix)))


            xds_inp.close()

            # copy the input file...
            shutil.copyfile(os.path.join(self.get_working_directory(),
                                         'XDS.INP'),
                            os.path.join(self.get_working_directory(),
                                         '%d_CORRECT.INP' % self.get_xpid()))

            # write the input data files...

            for file in self._input_data_files_list:
                open(os.path.join(
                    self.get_working_directory(), file), 'wb').write(
                    self._input_data_files[file])

            self.start()
            self.close_wait()

            xds_check_version_supported(self.get_all_output())
            xds_check_error(self.get_all_output())

            # look for errors
            # like this perhaps
            #   !!! ERROR !!! ILLEGAL SPACE GROUP NUMBER OR UNIT CELL

            # copy the LP file
            shutil.copyfile(os.path.join(self.get_working_directory(),
                                         'CORRECT.LP'),
                            os.path.join(self.get_working_directory(),
                                         '%d_CORRECT.LP' % self.get_xpid()))

            # gather the output files

            for file in self._output_data_files_list:
                self._output_data_files[file] = open(os.path.join(
                    self.get_working_directory(), file), 'rb').read()

            self._xds_ascii_hkl = os.path.join(
                self.get_working_directory(), 'XDS_ASCII.HKL')

            # do some parsing of the correct output...

            self._results = _parse_correct_lp(os.path.join(
                self.get_working_directory(),
                'CORRECT.LP'))

            # check that the unit cell is comparable to what went in i.e.
            # the volume is the same to within a factor of 10 (which is
            # extremely generous and should only spot gross errors)

            original = unit_cell(self._cell)
            refined = unit_cell(self._results['cell'])

            if original.volume() / refined.volume() > 10:
                raise RuntimeError, 'catastrophic change in unit cell volume'

            if refined.volume() / original.volume() > 10:
                raise RuntimeError, 'catastrophic change in unit cell volume'

            # record reindex operation used for future reference... this
            # is to trap trac #419

            if 'reindex_op' in self._results:
                format = 'XDS applied reindex:' + 12 * ' %d'
                Debug.write(format % tuple(self._results['reindex_op']))
                self._reindex_used = self._results['reindex_op']

            # get the reflections to remove...
            for line in open(os.path.join(
                self.get_working_directory(),
                'CORRECT.LP'), 'r').readlines():
                if '"alien"' in line:
                    h, k, l = tuple(map(int, line.split()[:3]))
                    z = float(line.split()[4])
                    if not (h, k, l, z) in self._remove:
                        self._remove.append((h, k, l, z))

            return

    return XDSCorrectWrapper()

if __name__ == '__main__':

    correct = XDSCorrect()
    directory = os.path.join(os.environ['XIA2_ROOT'],
                             'Data', 'Test', 'Images')

    correct.setup_from_image(os.path.join(directory, '12287_1_E1_001.img'))

    correct.set_data_range(1, 1)
    correct.set_background_range(1, 1)
    correct.add_spot_range(1, 1)

    correct.run()
