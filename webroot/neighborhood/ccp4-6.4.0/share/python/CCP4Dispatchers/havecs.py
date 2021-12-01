#!/home/dust/ccp4-6.4.0/ccp4-6.4.0/libexec/python2.7
#
#     Copyright (C) 2013 David Waterman
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
"""CCP4 dispatcher for 'havecs'"""

import os
import sys
import shlex
import subprocess
from threading import Thread
from Queue import Queue, Empty
from time import sleep

if __name__ == "__main__":
    # Jiggery-pokery to import the package containing this module, even
    # when it is not included in PYTHONPATH

    me = os.path.dirname(os.path.realpath(__file__))
    my_parent = os.path.dirname(me)
    sys.path.insert(0, my_parent)
    import CCP4Dispatchers

class Dispatcher:
    """A class to handle dispatch to 'havecs'"""

    def __init__(self, capture_streams = True, stdout = None, stderr = None):

        self.prog = "havecs"

        # A string giving the command required for dispatch
        self.command = "/home/dust/ccp4-6.4.0/ccp4-6.4.0/bin/havecs"

        # This dispatcher points to the specified binary located in:
        self.prog_dir_path = "/home/dust/ccp4-6.4.0/ccp4-6.4.0/bin"

        # The default call has empty command line arguments
        self.cmd_args = []

        # The default call passes no keywords
        self.keywords = None

        # handle to the subprocess
        self.process = None

        # is the process running?
        self.isRunning = False

        # Capture stdout and stderr? If not, send output to destinations
        # (e.g. file handles) requested in the argument list
        self.capture_streams = capture_streams
        self.stdout = subprocess.PIPE if capture_streams else stdout
        self.stderr = subprocess.PIPE if capture_streams else stderr

        # stream data from the call (only used if !capture_streams)
        self.stdout_data = None
        self.stderr_data = None

        # The exit code of the executable
        self.call_val = None

        # The exception from a failed call
        self.call_err = None

        # Suppression of console windows on Windows
        try:
            self.startupinfo = subprocess.STARTUPINFO()
            try:
                self.startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
            except Exception: #Python > 2.7
                self.startupinfo.dwFlags |= subprocess._subprocess.STARTF_USESHOWWINDOW
        except Exception:
            self.startupinfo = None

    def set_env(self):
        """Method to set the environment variables"""

        # Chain up to the package-level function for this
        from _common import set_environment
        set_environment()

    def get_bin(self):
        """Method to get the path to 'havecs'"""

        return os.path.join(self.prog_dir_path, self.prog)

    def set_cmd_args(self, args):
        """Method to append arguments to the program call"""

        # If the arguments are supplied as a string, split it suitably.
        # If it is a list, pass it on untouched
        if isinstance(args, str):
            # Preserve backspace separated filenames for Windows
            self.cmd_args = shlex.split(args, posix=(os.name != "nt"))
        elif isinstance(args, list):
            self.cmd_args = args

    def set_keywords(self, kwstring):
        """Method to set keywords to pass to 'havecs'"""

        if isinstance(kwstring, list):
            kwstring = "\n".join(kwstring)

        if not kwstring.endswith("\n"):
            kwstring = kwstring + "\n"

        self.keywords = kwstring

    def call(self, wait=True):
        """
        Method to execute havecs.

        When communicating with the subprocess, wait=True avoids the
        need to repeatedly call monitor, but blocks until the subprocess
        completes.
        """

        cmd = shlex.split(os.path.expandvars(self.command),
                          posix=(os.name != "nt"))
        popenargs = cmd + self.cmd_args

        self.stdin = subprocess.PIPE if self.keywords else None
        try:
            self.process = subprocess.Popen(popenargs, stdin=self.stdin,
                                 stdout=self.stdout,
                                 stderr=self.stderr,
                                 startupinfo=self.startupinfo)
        except OSError, e:
            self.call_err = sys.exc_info()
            return self.call_err

        self.call_val = None # Reset in case this was not the first call
        self.isRunning = True

        if self.capture_streams:

            if wait:
                (self.stdout_data,
                 self.stderr_data) = self.process.communicate(
                                                          self.keywords)
                self.isRunning = False
                self.stdout_data = self.stdout_data.splitlines()
                self.stderr_data = self.stderr_data.splitlines()

            else:
                if self.keywords:
                    self.process.stdin.write(self.keywords)
                    self.process.stdin.close()

                # create lists to be populated by the monitor method
                self.stdout_data = []
                self.stderr_data = []

                # queues to buffer stdout and stderr data
                self.stdout_queue = Queue()
                self.stderr_queue = Queue()

                # start threads to read output into the queues
                self._stop_reader = False
                self._stdout_reader = Thread(target = self.__enqueue,
                                            args = (self.process.stdout,
                                            self.stdout_queue))
                self._stderr_reader = Thread(target = self.__enqueue,
                                            args = (self.process.stderr,
                                            self.stdout_queue))
                self._stdout_reader.daemon = True
                self._stderr_reader.daemon = True
                self._stdout_reader.start()
                self._stderr_reader.start()

                # set returncode if already finished
                self.process.poll()

        else:
            if self.keywords:
                self.process.stdin.write(self.keywords)
                self.process.stdin.close()

            if wait:
                self.process.wait()
                self.isRunning = False

            else:
                # start thread to monitor for completion in the background
                self._background_wait = Thread(target = self.__wait)
                self._background_wait.daemon = True
                self._background_wait.start()

        self.call_val = self.process.returncode
        return self.call_val

    def __enqueue(self, stream, queue):
        """
        Worker thread function for call with capture_streams=True and
        wait=False
        """

        while True:
            try:
                s = stream.readline()
                if s:
                    queue.put(s)
                else: # s is the empty string or None
                    if self._stop_reader: return
                    sleep(0.1) # avoid too much spinning in this loop
            except Exception: # the stream was closed, so finish
                break
        return None

    def __wait(self):
        """
        Thread to monitor for job completion and set returncode and isRunning
        status, for use with capture_streams=False and wait=False
        """

        self.process.wait()
        self.isRunning = False
        self.call_val = self.process.returncode
        return None

    def __stop_readers(self):
        """Method to cleanly stop the reader threads"""

        self.process.stdout.flush()
        self.process.stderr.flush()
        self._stop_reader = True
        if self._stdout_reader.is_alive(): self._stdout_reader.join()
        if self._stderr_reader.is_alive(): self._stderr_reader.join()
        self.process.stdout.close()
        self.process.stderr.close()

        return None

    def monitor(self):
        """
        Method to read output of havecs and check if it has finished.

        The user of this method must call it repeatedly to fill
        stdout_data and stderr_data, until call_val is set, or abort is
        called.
        """

        # use only if communicating with a running subprocess
        if not self.capture_streams: return None
        if not self.isRunning: return None

        self.call_val = self.process.poll()

        # read from the queues
        try: o = self.stdout_queue.get_nowait()
        except Empty: o = None
        try: e = self.stderr_queue.get_nowait()
        except Empty: e = None

        if o: self.stdout_data.append(o.rstrip('\r\n'))
        if e: self.stderr_data.append(e.rstrip('\r\n'))

        # process finished, clean up
        if self.call_val is not None:
            # first time in this block, end reader threads
            if not self._stop_reader:
                self.__stop_readers()
            # subsequently, check if nothing left in the queues
            elif not o and not e: self.isRunning = False
            else: pass

        return o, e

    def abort(self):
        """Method to terminate or kill the process"""

        # Use only if communicating with a running subprocess
        if not self.capture_streams: return None
        if not self.isRunning: return None

        self.process.terminate()
        if not self.process.poll() is None:
            self.process.kill()

        # ask reader threads to close
        self.__stop_readers()

        # close the streams
        self.process.stdout.close()
        self.process.stderr.close()
        self.call_val = self.process.poll()
        self.isRunning = False

if __name__ == "__main__":
    # This dispatcher is being run as a script, so go ahead and execute
    # havecs

    # Instantiate the dispatcher
    dispatcher = Dispatcher(capture_streams = False)

    # Set the environment
    dispatcher.set_env()

    # Run the program now and exit with its value, or re-raise any error
    # encountered, to exit the interpreter
    dispatcher.set_cmd_args(sys.argv[1:])
    dispatcher.call()
    if dispatcher.call_err:
        raise dispatcher.call_err[1], None, dispatcher.call_err[2]
    else:
        sys.exit(dispatcher.call_val)
