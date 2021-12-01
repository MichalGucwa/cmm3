#!/usr/bin/env python
# XDSXycorr.py
#   Copyright (C) 2006 CCLRC, Graeme Winter
#
#   This code is distributed under the BSD license, a copy of which is
#   included in the root directory of this package.
#
# A wrapper to handle the JOB=XYCORR module in XDS.
#

import os
import sys
import shutil

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

def XDSXycorr(DriverType = None):

    DriverInstance = DriverFactory.Driver(DriverType)

    class XDSXycorrWrapper(DriverInstance.__class__,
                           FrameProcessor):
        '''A wrapper for wrapping XDS in xycorr mode.'''

        def __init__(self):

            # set up the object ancestors...

            DriverInstance.__class__.__init__(self)
            FrameProcessor.__init__(self)

            # now set myself up...

            self.set_executable('xds')

            # generic bits

            self._data_range = (0, 0)
            self._spot_range = []
            self._background_range = (0, 0)
            self._resolution_range = (0, 0)

            self._org = [0.0, 0.0]

            self._input_data_files = { }
            self._output_data_files = { }

            self._input_data_files_list = []

            self._output_data_files_list = ['X-CORRECTIONS.cbf',
                                            'Y-CORRECTIONS.cbf']

            return

        # getter and setter for input / output data

        def set_input_data_file(self, name, data):
            self._input_data_files[name] = data
            return

        def get_output_data_file(self, name):
            return self._output_data_files[name]

        # this needs setting up from setup_from_image in FrameProcessor

        def set_data_range(self, start, end):
            self._data_range = (start, end)

        def add_spot_range(self, start, end):
            self._spot_range.append((start, end))

        def set_background_range(self, start, end):
            self._background_range = (start, end)

        def set_beam_centre(self, x, y):
            self._org = float(x), float(y)

        def run(self):
            '''Run xycorr.'''

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
            xds_inp.write('JOB=XYCORR\n')

            for record in header:
                xds_inp.write('%s\n' % record)

            name_template = os.path.join(self.get_directory(),
                                         self.get_template().replace('#', '?'))

            record = 'NAME_TEMPLATE_OF_DATA_FRAMES=%s\n' % \
                     name_template

            xds_inp.write(record)

            xds_inp.write('DATA_RANGE=%d %d\n' % self._data_range)
            for spot_range in self._spot_range:
                xds_inp.write('SPOT_RANGE=%d %d\n' % spot_range)
            xds_inp.write('BACKGROUND_RANGE=%d %d\n' % \
                          self._background_range)

            xds_inp.write('ORGX=%f ORGY=%f\n' % \
                          tuple(self._org))
            xds_inp.close()

            # copy the input file...
            shutil.copyfile(os.path.join(self.get_working_directory(),
                                         'XDS.INP'),
                            os.path.join(self.get_working_directory(),
                                         '%d_XYCORR.INP' % self.get_xpid()))

            # write the input data files...

            for file in self._input_data_files_list:
                open(os.path.join(
                    self.get_working_directory(), file), 'wb').write(
                    self._input_data_files[file])

            self.start()
            self.close_wait()

            xds_check_version_supported(self.get_all_output())

            # check the status
            xds_check_error(self.get_all_output())

            # copy the LP file
            shutil.copyfile(os.path.join(self.get_working_directory(),
                                         'XYCORR.LP'),
                            os.path.join(self.get_working_directory(),
                                         '%d_XYCORR.LP' % self.get_xpid()))

            # gather the output files

            for file in self._output_data_files_list:
                self._output_data_files[file] = open(os.path.join(
                    self.get_working_directory(), file), 'rb').read()

            return

    return XDSXycorrWrapper()

if __name__ == '__main__':

    xycorr = XDSXycorr()
    directory = os.path.join(os.environ['XIA2_ROOT'],
                             'Data', 'Test', 'Images')


    xycorr.setup_from_image(os.path.join(directory, '12287_1_E1_001.img'))

    xycorr.set_data_range(1, 1)
    xycorr.set_background_range(1, 1)
    xycorr.add_spot_range(1, 1)

    xycorr.run()
