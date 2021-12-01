#!/usr/bin/env python
#
#     Copyright (C) 2012 David Waterman
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
"""Generate dispatchers for CCP4 programs."""

import sys
import os
import string
import warnings
import getopt
import stat
import shlex
import binascii
import re

__version__ = "0.8"
__author__ = "david.waterman@stfc.ac.uk"

def usage():

    print "Usage: " + sys.argv[0] + " [options] DEFINITION BINDIR..."
    print "Options:"
    print "  -h, --help               show this help message and exit"
    print "  -v, --verbose            print lots of status information"
    print "  -n FOO, --name=FOO       name the dispatcher package FOO (omission"
    print "                           implies FOO='CCP4Dispatchers')"    
    print "  -p DIR1, --pkgdir=DIR1   create dispatcher package under existing"
    print "                           directory DIR1 (omission implies DIR1=.)"
    print "  -l DIR2, --linkdir=DIR2  create links under existing directory"
    print "                           DIR2 (omission implies DIR2=DIR1" + os.path.sep + "bin)"
    print
    print "Create dispatchers for all executable files located in directories BINDIR..."
    print "with environment variables set as defined in the text file DEFINITION. This"
    print "file should contain lines defining variables in one of the following ways:"
    print "  VARIABLE=VALUE"
    print "  export VARIABLE=VALUE"
    print "  setenv VARIABLE VALUE"
    print
    print "This syntax has been chosen so that the DEFINITION file can serve a dual"
    print "purpose, as it can be written such that it can be sourced directly in your"
    print "shell, thus providing the same environment supplied by the dispatchers."
    print "Please be aware that this file is not parsed as a shell script here, so lines"
    print "deviating from the described syntax may not be handled correctly."

# templates for code generation
licence = '''#
#     Copyright (C) 2013 David Waterman
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
'''
common_base = licence + \
'''"""Initialisation for the $PKGNAME package"""

import os, string

envlist = $ENVLIST

prog_to_dispatcher = $PROGMAP

def dispatcher_builder(program, cmd_args = None, keywords = None,
                       capture_streams = True, stdout = None, stderr = None):
    """Convenience factory function to set up and return a dispatcher in one
    line, using the original program name"""

    try:
        modulename = prog_to_dispatcher[program]
    except KeyError:
        msg = program + " is not found in the mapping to dispatchers"
        raise KeyError, msg

    _temp = __import__(modulename, globals(), locals(), ["Dispatcher"], -1)
    Dispatch = _temp.Dispatcher(capture_streams, stdout, stderr)

    if cmd_args: Dispatch.set_cmd_args(cmd_args)
    if keywords: Dispatch.set_keywords(keywords)

    return Dispatch

def call_here(program, key, cmdline, workingDIR, function=""):
    """Convenience function to set up and call a dispatcher in one line,
    writing output to files, principally for MrBump"""

    logfile = os.path.join(workingDIR, "%s%s.log" % (program, function))
    errfile = os.path.join(workingDIR, "%s%s.err" % (program, function))

    # Generate a shell script for this job
    if os.name != "nt":
        scriptfile = os.path.join(workingDIR, "%s%s.script" % (program, function))
        s = open(scriptfile,"w")
        s.write("#!/bin/sh\\n")
        s.write(program + " " + cmdline + " <<eof\\n")
        s.write(key)
        s.write("eof\\n")
        s.close()

    # Import Dispatcher from the program name (must remove '.exe' on Windows)
    Dispatch = dispatcher_builder(program, cmdline, key)
    Dispatch.call()

    # Write out the stdout to the log file
    log = open(logfile, "w")
    for line in Dispatch.stdout_data:
        log.write(line + "\\n")
    log.close()

    # Write out the stderr to the error file
    err=open(errfile, "w")
    for line in Dispatch.stderr_data:
       err.write(line + "\\n")
    err.close()

    return Dispatch

def set_environment():
    """Function to set the environment variables"""

    # Read current environment in order to do any dynamic substitutions required
    env_var_dict = os.environ.copy()

    # Set specified environment variables
    for (var, val) in envlist:

        val_template = string.Template(val)
        val_sub = val_template.safe_substitute(env_var_dict)

        # Remove any remaining $IDENTIFIERS, to behave like bash does.
        val = val_template.pattern.sub("",val_sub)
        os.environ[var]= val

    # Find the path to the CCP4Dispatcher package
    pkg_path = os.path.dirname(os.path.realpath(__file__))

    # Prepend dispatcher package to the PATH, if not included already
    try:
        curr_path = os.environ["PATH"]
    except KeyError:
        curr_path = ""
    if not pkg_path in curr_path:
        os.environ["PATH"] = (pkg_path + os.pathsep + curr_path)

    # Prepend dispatcher package to PYTHONPATH, if not included already
    try:
        curr_pythonpath = os.environ["PYTHONPATH"]
    except KeyError:
        curr_pythonpath = ""
    pkg_parent = os.path.dirname(pkg_path)
    if not pkg_parent in curr_pythonpath:
        os.environ["PYTHONPATH"] = (pkg_parent + os.pathsep + curr_pythonpath)

'''

# Code template for the dispatchers, which will be created from this by
# substituting suitable strings for the $IDENTIFIER placeholders.
dispatcher_base = "#!$THISPYTHON\n" + licence + \
'''"""CCP4 dispatcher for '$PROG'"""

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
    import $PKGNAME

class Dispatcher:
    """A class to handle dispatch to '$PROG'"""

    def __init__(self, capture_streams = True, stdout = None, stderr = None):

        self.prog = "$PROG"

        # A string giving the command required for dispatch
        self.command = "$COMMAND"

        # This dispatcher points to the specified binary located in:
        self.prog_dir_path = "$PROGDIRPATH"

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
        """Method to get the path to '$PROG'"""

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
        """Method to set keywords to pass to '$PROG'"""

        if isinstance(kwstring, list):
            kwstring = "\\n".join(kwstring)

        if not kwstring.endswith("\\n"):
            kwstring = kwstring + "\\n"

        self.keywords = kwstring

    def call(self, wait=True):
        """
        Method to execute $PROG.

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
        Method to read output of $PROG and check if it has finished.

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

        if o: self.stdout_data.append(o.rstrip('\\r\\n'))
        if e: self.stderr_data.append(e.rstrip('\\r\\n'))

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
    # $PROG

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
'''

# Parse command line options
try:
    opts, args = getopt.getopt(sys.argv[1:],
                             "hvn:p:l:",
                             ["help", "verbose", "name", "pkgdir=", "linkdir="])
except getopt.GetoptError, err:
    # Print help information and exit:
    print str(err)
    usage()
    sys.exit(2)

package_name = "CCP4Dispatchers"
verbose = False
pkgdir = "."
linkdir = None
for o, a in opts:
    if o in ("-v", "--verbose"):
        verbose = True
    elif o in ("-h", "--help"):
        usage()
        sys.exit()
    elif o in ("-n", "--name"):
        package_name = a
    elif o in ("-p", "--pkgdir"):
        pkgdir = a
    elif o in ("-l", "--linkdir"):
        linkdir = a

# check package_name is valid
if not re.match("[_A-Za-z][_a-zA-Z0-9]*$",package_name):
    print package_name + " is not a valid Python package name."
    print
    sys.exit()

if not linkdir:
    linkdir = os.path.join(pkgdir, package_name, "bin")

# Check remaining arguments
if len(args) < 2:
    print "Not enough arguments supplied."
    print
    usage()
    sys.exit(2)
else:
    ccp4_setup_file = args[0]
    bin_dirs = args[1:]

# Open ccp4_setup_file with a try / exception
try:
    input_file = open(ccp4_setup_file, 'r')
    line_list = input_file.readlines()
    input_file.close()
except Exception:
    msg =  "unable to read DEFINITION file " + ccp4_setup_file
    sys.exit(msg)

# Set up a list to put the environment variable and value pairs in
var_val_pairs = []

# Read current environment in order to $substitute for known variables
env_var_dict = os.environ.copy()

# A function to parse environment set up lines in C shell syntax
def parse_csh(line):

    line = line.partition('setenv')[2]
    line = line.partition('#')[0] # strip off trailing comments
    line = line.strip() # strip off whitespace margins
    var = line.split()[0] # break at the first whitespace
    val = line.partition(var)[2] # break after var
    val = val.strip()

    return var, val

# Process the lines read from the ccp4_setup_file
for line in line_list:

    # Clean up the line by stripping comments and whitespace margins
    line = line.partition('#')[0]
    line = line.strip()

    # Extract var, val pairs by parsing lines of shell commands that set
    # the environment
    bash_match = re.match(
           "export(\s)+(?P<var>[a-zA-Z]{1}(\w)*)=(?P<val>[^=;]*)", line)
    sh_match = re.match(
           "(?P<var>[a-zA-Z]{1}(\w)*)=(?P<val>[^=;]*)", line)
    if bash_match: var, val = bash_match.group('var','val')
    elif sh_match: var, val = sh_match.group('var','val')
    elif line.startswith("setenv"): var, val = parse_csh(line)
    else: continue # skip comment lines and irrelevant commands

    # Substitute any currently known $IDENTIFIER in the string with its
    # value
    val_template = string.Template(val)
    val_sub = val_template.safe_substitute(env_var_dict)

    # If verbose, warn if any unknown $IDENTIFIERS were present
    if verbose and not val == val_sub:
        remaining_matches = val_template.pattern.findall(val_sub)
        remaining_matches = map("".join, remaining_matches)
        for elem in remaining_matches:
            msg = ("undefined substitution: " + val_template.delimiter +
                elem + " for variable " + var)
            warnings.warn(msg)

    # Sanity check - are either var or val empty?
    if var == "":
        msg = "Empty environment variable after parsing line " + line
        sys.exit(msg)
    if val.strip() == "":
        msg = "Empty value for environment variable " + var
        warnings.warn(msg)

    # Add variable and value to env_var_dict for further substitutions
    env_var_dict[var] = val

    # Also add it to the var_val_pairs list for writing dispatchers
    var_val_pairs.append((var, val))

# Now we have an ordered list of tuples, each of which is a variable,
# value pair. From this, generate the string of commands common to all
# dispatchers for setting the CCP4 environment.

var_val_pairs = \
    [(var, "".join(shlex.split(val, posix=(os.name != "nt")))) for \
     (var, val) in var_val_pairs]

class DispatchData:

    """A class to hold information required to write a dispatcher"""

    def __init__(self, template, directory, filename):

        self.template = template

        self.bin_dir = directory

        self.target_filename = filename

        self.dispatch_command = None

        self.modulename = None

    def get_target_filename(self):
        return self.target_filename

    def get_target_directory(self):
        return self.bin_dir

    def determine_command(self):
        """
        Test the target file. If it is a valid dispatcher target, return
        the command required to run the program/script, including any
        required interpreter
        """
        target = os.path.join(self.bin_dir, self.target_filename)
        real_target = os.path.expandvars(target)

        # first decide whether the target is executable and interesting
        if not os.path.isfile(real_target): return None
        elif not os.access(real_target, os.X_OK): return None
        elif real_target.lower().endswith(".pyc"): return None
        #elif target.lower().endswith(".bat"): return None
        elif real_target.lower().endswith(".dll"): return None

        # take a snippet from the head of the file to help identify its
        # type
        f = open(real_target, "rb")
        head = f.read(160)
        f.close()

        is_ascii = all(ord(c) < 128 for c in head)

        # interpreted script with a hashbang line
        if is_ascii and head.startswith("#!"):

            # On POSIX-like systems just use the hashbang
            hashbang = head.splitlines()[0].lstrip("#!")
            if os.name is not "nt":
                self.dispatch_command = hashbang + " " + target
                return self.dispatch_command

            # otherwise, we're on Windows. Test for a known interpreter
            # and keep any options that are passed to it
            test = hashbang.rpartition("python")
            if test[1] == "python":
                self.dispatch_command = sys.executable + test[2] + \
                                        " " + target
                return self.dispatch_command

            test = hashbang.rpartition("tclsh")
            if test[1] == "tclsh":
                self.dispatch_command = test[1] + test[2] + " " + target
                return self.dispatch_command

            test = hashbang.rpartition("wish")
            if test[1] == "wish":
                self.dispatch_command = test[1] + test[2] + " " + target
                return self.dispatch_command

            test = hashbang.rpartition("perl")
            if test[1] == "perl":
                self.dispatch_command = test[1] + test[2] + " " + target
                return self.dispatch_command

        # looks like a script with no hashbang, try file ext
        if is_ascii:
            if target.lower().endswith(".py"):
                self.dispatch_command = sys.executable + " " + target
                return self.dispatch_command

            if target.lower().endswith(".sh"):
                self.dispatch_command = "sh" + " " + target
                return self.dispatch_command

            if target.lower().endswith(".csh"):
                self.dispatch_command = "csh" + " " + target
                return self.dispatch_command

            # this might not always be what is wanted (bltwish or tclsh
            # instead?)
            if target.lower().endswith(".tcl"):
                self.dispatch_command = "wish" + " " + target
                return self.dispatch_command

            if target.lower().endswith(".bat") and os.name is "nt":
                self.dispatch_command = target
                return self.dispatch_command

        # an interpreted binary format
        # java archive
        if head.startswith(binascii.unhexlify("504B0304")):
            self.dispatch_command = "java -jar" + " " + target
            return self.dispatch_command

        # java class file
        if head.startswith(binascii.unhexlify("CAFEBABE")):
            # remove '.class' (case insensitive) from the filename
            tgt = re.sub("(?i)\.class", "", target)
            self.dispatch_command = "java" + " " + tgt
            return self.dispatch_command

        # if we got this far assume it is a native executable
        self.dispatch_command = target
        return self.dispatch_command

    def set_modulename(self):

        # Strip '.exe' off the filename if present
        s = self.target_filename
        if s.lower().endswith(".exe"): s = s[:-4]

        # Ensure dispatcher has a conformant name for a Python module
        s = s.replace(".","_")
        self.modulename = s + ".py"
        return self.modulename

    def get_modulename(self):

        return self.modulename

    def get_dispatcher_string(self):
        # The directory string and dispatch command will contain '\' on
        # Windows. These must be escaped for writing to the dispatcher
        bin_dir = self.bin_dir.replace("\\","\\\\")
        cmd = self.dispatch_command.replace("\\","\\\\")
        dispatcher_string = self.template.safe_substitute(
            PKGNAME=package_name,
            THISPYTHON=sys.executable if sys.executable \
                else "/usr/bin/env python",
            PROG=self.target_filename,
            COMMAND = cmd,
            PROGDIRPATH=bin_dir)
        return dispatcher_string

# create a template for program-specific substitutions
dispatcher_template = string.Template(dispatcher_base)

# Now make the list of potential dispatchers
dispatchers = []
for bin_dir in bin_dirs:

    if verbose: print "Collecting names of the executables in", bin_dir

    for elem in os.listdir(os.path.expandvars(bin_dir)):

        # Put together the DispatchData for this target
        d = DispatchData(dispatcher_template, bin_dir, elem)

        if verbose: print "target: " + elem

        # Work out dispatch command. If elem is not an executable file
        # or is of an ignored format then skip to the next
        if not d.determine_command():
            if verbose: print "ignored"
            continue

        if verbose: print "command: " + d.dispatch_command

        # Complete the dispatcher data
        d.set_modulename()

        # save the DispatcherData for this dispatcher
        dispatchers.append(d)

# Now ready to write the dispatcher package
if not os.path.exists(pkgdir):
    msg = ("The requested directory in which to write the dispatcher" +
           "package, " + pkgdir + ", does not appear to exist. " +
           "Exiting.")
    sys.exit(msg)

package_path = os.path.join(pkgdir, package_name)

if not os.path.exists(package_path):
    try:
        os.mkdir(package_path)
    except OSError, err:
        print str(err)
        msg = ("Problem creating package directory " + package_name +
               ". Exiting.")
        sys.exit(msg)
else:
    # clear out old dispatcher package
    for dirpath, dirnames, filenames in os.walk(package_path, topdown=False):
        for f in filenames:
            try:
                os.remove(os.path.join(dirpath, f))
            except OSError, err:
                msg = ("Problem removing file from existing CCP4Dispatcher " +
                       "package: " + os.path.join(dirpath, f))
                warnings.warn(msg)
                print str(err)
        for d in dirnames:
            try:            
                os.rmdir(os.path.join(dirpath, d))
            except OSError, err:
                msg = ("Problem removing directory from existing CCP4Dispatcher " +
                       "package: " + os.path.join(dirpath, d))
                warnings.warn(msg)
                print str(err)

if not os.path.exists(linkdir):
    try:
        os.mkdir(linkdir)
    except OSError, err:
        print str(err)
        msg = ("Problem creating the directory in which to write " +
               "links, " + linkdir + ". Exiting.")
        os.rmdir(package_path)
        sys.exit(msg)

# build a mapping of canonical program names to their dispatchers, for use by
# the dispatcher_builder in _common.py
prog_to_dispatcher = {}
for d in dispatchers:

    prog = d.get_target_filename()
    # remove '.exe' from the program name on Windows
    if os.name is "nt":
        root, ext = os.path.splitext(prog)
        if ext.lower() == ".exe": prog = root

    target = d.get_modulename()[:-3] # remove '.py'

    prog_to_dispatcher[prog] = target

# create code for the package's _common.py file
common_template = string.Template(common_base)
common_string = common_template.safe_substitute(PKGNAME=package_name,
                                                ENVLIST=str(var_val_pairs),
                                                PROGMAP=str(prog_to_dispatcher))

common_file = open(os.path.join(package_path, "_common.py"), 'w')
common_file.write(common_string)
common_file.close()
init_file = open(os.path.join(package_path, "__init__.py"), 'w')
init_file.write(licence + "from _common import *\n" +
                "set_environment()\n")
init_file.close()

can_symlink = hasattr(os, "symlink")
for d in dispatchers:

    dispatcher_filename = os.path.join(package_path,
                                       d.get_modulename())
    # Check for clashes with dispatchers previously created by this loop
    if os.path.exists(dispatcher_filename):
        msg = "Overwriting file: " + dispatcher_filename
        warnings.warn(msg)

    try:
        outputfile = open(dispatcher_filename, 'w')
    except OSError, err:
            msg = ("Problem while attempting to create file '" +
                   dispatcher_filename +"'")
            warnings.warn(msg)
            print str(err)

    dispatcher_string = d.get_dispatcher_string()
    outputfile.write(dispatcher_string)
    outputfile.close()

     # Add execute permission (does nothing on Windows)
    os.chmod(dispatcher_filename,
             os.stat(dispatcher_filename).st_mode | stat.S_IXUSR)

    # Make a symlink with the bare program name if possible. For Windows
    # make a batch file that passes the dispatcher to this python
    prog = d.get_target_filename()
    if can_symlink:
        try:
            os.symlink(os.path.realpath(dispatcher_filename),
                       os.path.join(linkdir, prog))
        except OSError, err:
            msg = ("Problem while attempting to create symlink '" +
                   prog + "' in " + os.path.realpath(linkdir))
            warnings.warn(msg)
            print str(err)

    elif os.name is "nt":
        root, ext = os.path.splitext(prog)
        # don't want '.exe.bat' or '.bat.bat'. Let .exe take precedence
        # if there is a collision
        if ext.lower() == ".exe": prog = root
        if ext.lower() == ".bat":
            if not os.path.exists(os.path.join(d.get_target_directory(),
                              prog + ".exe")):
                prog = root
        try:
            batfile = open(os.path.join(linkdir, prog + ".bat"), 'w')
        except OSError, err:
            msg = ("Problem while attempting to create batch file '" +
                   prog + ".bat' in " + os.path.realpath(linkdir))
            warnings.warn(msg)
            print str(err)
            continue
        dpath = os.path.realpath(dispatcher_filename)
        temp = string.Template(sys.executable + ' "$DISPATCHER" %*')
        batfile.write(temp.substitute(DISPATCHER = dpath))
        batfile.close()

if verbose: print "Finished creating dispatcher package", package_path
