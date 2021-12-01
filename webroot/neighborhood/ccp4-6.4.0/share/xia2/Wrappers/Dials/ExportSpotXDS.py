#!/usr/bin/env python
# ExportSpotXDS.py
#   Copyright (C) 2013 Diamond Light Source, Richard Gildea
#
#   This code is distributed under the BSD license, a copy of which is
#   included in the root directory of this package.
#
# A wrapper to handle the dials.spotfinder program.
#

import os
import sys
import shutil

# We should really put these variable checks, etc in one centralised place
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
#from XDS import header_to_xds, xds_check_version_supported
from Handlers.Streams import Debug

# global flags
from Handlers.Flags import Flags

from libtbx import phil
import libtbx

master_params = phil.parse("""
""")

def ExportSpotXDS(DriverType=None, params=None):

    DriverInstance = DriverFactory.Driver(DriverType)

    class ExportSpotXDSWrapper(DriverInstance.__class__,
                            FrameProcessor):
        '''A wrapper for wrapping dials.export_spot_xds.'''

        def __init__(self, params=None):

            # set up the object ancestors...

            DriverInstance.__class__.__init__(self)
            FrameProcessor.__init__(self)

            # phil parameters

            if not params:
                params = master_params.extract()
            self._params = params

            # now set myself up...

            self.set_executable('dials.export_spot_xds')

            self._input_data_files = { }
            self._output_data_files = { }

            self._input_data_files_list = []
            self._output_data_files_list = []

        # getter and setter for input / output data

        def set_input_data_file(self, name, data):
            self._input_data_files[name] = data
            return

        def get_output_data_file(self, name):
            return self._output_data_files[name]

        def run(self):
            '''Run dials.spotfinder.'''

            self.add_command_line(self._input_data_files.keys())
            self.start()
            self.close_wait()

            # check for errors
            self.check_for_errors()

            self._output_data_files.setdefault(
                'SPOT.XDS', open(os.path.join(
                    self.get_working_directory(), 'SPOT.XDS'), 'rb').read())

            output = self.get_all_output()
            print "".join(output)

    return ExportSpotXDSWrapper(params=params)

if __name__ == '__main__':
    import sys
    from libtbx.phil import command_line

    args = sys.argv[1:]
    cmd_line = command_line.argument_interpreter(master_params=master_params)
    working_phil, files = cmd_line.process_and_fetch(
        args=args, custom_processor="collect_remaining")
    working_phil.show()
    assert len(files) > 0
    params = working_phil.extract()
    export = ExportSpotXDS(params=params)
    for f in files:
        export.set_input_data_file(f, open(f, 'rb'))
    export.run()