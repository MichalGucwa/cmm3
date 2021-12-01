#!/usr/bin/env python
# PythonDriver.py
#
#   Copyright (C) 2013 Diamond Light Source, Graeme Winter
#
#   This code is distributed under the BSD license, a copy of which is 
#   included in the root directory of this package.
#
# A driver class to launch Python subprocesses with the shared environment
# but in a new address space.

import subprocess
import os
import sys
import copy

from DefaultDriver import DefaultDriver
from DriverHelper import kill_process

class PythonDriver(DefaultDriver):

    def __init__(self):
        DefaultDriver.__init__(self)

        self._popen = None

        return

    def start(self):

        # here self._executable refers to the Python program which should be
        # executed
        
        if self._executable is None:
            raise RuntimeError, 'no executable is set.'

        if os.name == 'nt':
            # pass in CL as a list of tokens
            command_line = [sys.executable]
            command_line.append(self._executable)
            for c in self._command_line:
                command_line.append(c)
        else:
            # now pass in the command line as a string and allow the
            # shell to parse it - note well though that the tokens
            # on the command line are quoted..

            command_line = '%s %s' % (sys.executable, self._executable)
            for c in self._command_line:
                command_line += ' \'%s\'' % c

        environment = copy.deepcopy(os.environ)

        for name in self._working_environment:
            added = self._working_environment[name][0]
            for value in self._working_environment[name][1:]:
                added += '%s%s' % (os.pathsep, value)

            if name in environment and \
                   not name in self._working_environment_exclusive:
                environment[name] = '%s%s%s' % (added, os.pathsep,
                                                environment[name])
            else:
                environment[name] = added

        self._popen = subprocess.Popen(command_line,
                                       bufsize = 1,
                                       stdin = subprocess.PIPE,
                                       stdout = subprocess.PIPE,
                                       stderr = subprocess.STDOUT,
                                       cwd = self._working_directory,
                                       universal_newlines = True,
                                       env = environment,
                                       shell = True)
        
        return

    def check(self):
        '''Overload the default check method.'''

        return True

    def _input(self, record):

        if not self.check():
            raise RuntimeError, 'child process has termimated'

        self._popen.stdin.write(record)

        return

    def _output(self):
        # need to put some kind of timeout facility on this...
        
        return self._popen.stdout.readline()

    def _status(self):
        # get the return status of the process

        return self._popen.poll()

    def close(self):
        
        if not self.check():
            raise RuntimeError, 'child process has termimated'

        self._popen.stdin.close()

        return

    def kill(self):
        kill_process(self._popen)

        return

if __name__ == '__main__':
    assert('XIA2CORE_ROOT') in os.environ

    pd = PythonDriver()
    pd.set_executable(os.path.join(os.environ['XIA2CORE_ROOT'],
                                   'Test', 'ExampleProgram.py'))
    pd.start()
    pd.close_wait()

    for record in pd.get_all_output():
        print record[:-1]
    
