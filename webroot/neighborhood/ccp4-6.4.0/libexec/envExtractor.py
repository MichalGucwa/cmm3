#!/usr/bin/env python
#
#     Copyright (C) 2013 David Waterman
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
"""extract values for CCP4 variables from environment setup files."""

import sys
import os
import string
import getopt
import stat
import re
import subprocess
from socket import gethostname

__version__ = "0.3"
__author__ = "david.waterman@stfc.ac.uk"

### Function definitions ###

def usage():
    print "Usage: " + sys.argv[0] + " [options] FILE..."
    print "Options:"
    print "  -h, --help            show this help message and exit"
    print "  -o OUT, --outfile OUT write environment variable definition script to the"
    print "                        file named OUT.sh. If omitted, OUT defaults to ccp4-env"
    print
    print "This script sets a basic environment for sourcing the shell setup scripts"
    print "provided by the FILE argument(s). These scripts are then sourced by the shell"
    print "in that environment. New and changed environment variables are then identified"
    print "by inspecting the difference between the resulting and initial environments."
    print
    print "Finally, a Bourne shell script containing export commands for these variables is"
    print "written to OUT.sh. This script can be used as input to dispatcherGenerator."
    print
    print "Note, if the script(s) identified by the FILE argument(s) are not in Bourne shell"
    print "syntax then the correct shell must be identified by an initial '#!' line.\n"

### Main script ###

# Parse command line options
try:
    opts, args = getopt.getopt(sys.argv[1:], "ho:", ["help", "outfile="])
except getopt.GetoptError, err:
    # print help information and exit:
    print str(err)
    usage()
    sys.exit(2)

outfile = "ccp4-env"
for o, a in opts:
    if o in ("-h", "--help"):
        usage()
        sys.exit()
    elif o in ("-o", "--outfile"):
        outfile = a
outfile = os.path.realpath(outfile + ".sh")

# Check remaining arguments
if len(args) == 0:
    print ("\nYou must supply the path to a file containing " +
          "CCP4 environment set up commands.\n")
    usage()
    sys.exit(2)

# Check the input files exist
input_filenames = map(os.path.realpath, args[0:])
for filename in input_filenames:
    if not os.path.isfile(filename):
        print ("\nFilename " + filename +
               " does not refer to an existing file.\n")
        sys.exit(2)

# Clean the environment
init_env = os.environ.copy()
os.environ.clear()

# Re-set a few basic variables to get a sane environment for sourcing setup
# scripts. Probably not all of these are necessary. Maybe some others are?
basics = ["PATH",
          "PWD",
          "PYTHONPATH",
          "HOME",
          "HOSTNAME",
          "MANPATH",
          "OS",
          "OSTYPE",
          "USER",
          "USERNAME",
          "UID",
          "HTTP_PROXY",
          "http_proxy",
          "HTTPS_PROXY",
          "https_proxy",
          "LD_LIBRARY_PATH",
          "DYLD_LIBRARY_PATH",
          "XENVIRONMENT",
          "XFILESEARCHPATH",
          "XUSERFILESEARCHPATH",
          "TMPDIR",
          "TMP",
          "TEMP",
          "CLASSPATH",
          "OPENWINHOME"]

for key in basics:
    if key in init_env: os.environ[key]=init_env[key]

# Identify the requested shell from the hashbang line of the first file
try:
    f = open(input_filenames[0], "r")
    head = f.readline()
    f.close()
except IOError:
    msg = "Cannot open file named " + input_filenames[0]
    sys.exit(msg)

shell_executable = None
source_cmd = ". "
if head.startswith("#!"):
    shell_executable = head.lstrip("#!").strip()
    if shell_executable.endswith("csh"):
        source_cmd = "source "

# Create the command string and execute it with the chosen shell
cmd = ("".join([source_cmd + x + "; " for x in input_filenames]) +
       'echo "~~~printenv output follows~~~"; printenv')
p = subprocess.Popen(cmd, executable = shell_executable, shell=True,
                     stdout=subprocess.PIPE)
std_out = p.communicate()[0]

# Capture the printenv output and pass the rest to stdout
std_out = std_out.partition("~~~printenv output follows~~~\n")
source_cmd_out, new_env = std_out[0], std_out[2]
sys.stdout.write(source_cmd_out)

new_env = new_env.splitlines()
# List of variable, value pairs to write export commands for
var_val_pairs = []

for line in new_env:
    line = line.partition("=")
    var, val = line[0], line[2]

    # Is this variable new, or changed from the basic environment?
    # If so, keep it to write out
    keep = True
    if var in os.environ: keep = os.environ[var] != val
    if keep: var_val_pairs.append((var, val))

# Now write out the retained variable definitions
try:
    outputfile = open(outfile, 'w')
except IOError:
    msg =  "Unable to create file " + outfile
    sys.exit(msg)

header_template = string.Template("""#!/bin/sh
#
# Environment variable definitions generated by envExtractor for $HOST
#
""")
outputfile.write(header_template.safe_substitute(HOST=gethostname()))

for var, val in var_val_pairs:
    # add surrounding quotes if there is any whitespace
    if re.search("\s", val): val = "'" + val + "'"

    outputfile.write(var + "=" + val + "\n")
    outputfile.write("export " + var + "\n")

outputfile.close()

# Add execute permission
os.chmod(outfile, os.stat(outfile).st_mode | stat.S_IXUSR)
