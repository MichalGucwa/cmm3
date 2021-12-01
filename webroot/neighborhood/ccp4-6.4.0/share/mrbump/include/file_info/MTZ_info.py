#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#

import os,sys,string
import time
import subprocess
import shlex


class Mtzdump:
  """This is a wrapper for the program mtzdump which will print the
  header of an MTZ file. Methods are provided for extracting certain
  quantities from the header"""

  def __init__(self):
    self.mtzdumpEXE=os.path.join(os.environ["CBIN"], "mtzdump")
    self.programParameters = 'END\n'
    self.logfile=""
    self.hklin=""
    try:
       self.debug=eval(os.environ['MRBUMP_DEBUG'])
    except:
       self.debug=False
  
  def setMTZdumpLogfile(self, dir):
    """ Set the name of the mtzdump logfile. Try to make it unique to the user
        by appending their username to the start of the file name. """
    if os.name == "nt":
       self.logfile = os.path.join(dir, os.environ["USERNAME"] + '_junk_mtzdump.log')
    else:
       self.logfile = os.path.join(dir, os.environ["USER"] + '_junk_mtzdump.log')
   
  def setProgramParameters(self,inputline):
    self.programParameters = inputline + '\n' + self.programParameters

  def setHklin(self, hklin):
    self.hklin = hklin

  def go(self):
     """ Run Mtzdump """

     # Set the command line
     command_line = self.mtzdumpEXE + ' HKLIN ' + self.hklin
        
     if self.debug:
        sys.stdout.write("\n")
        sys.stdout.write("======================\n")
        sys.stdout.write("MTZDUMP command line:\n")
        sys.stdout.write("======================\n")
        sys.stdout.write(command_line + "\n")
        sys.stdout.write("\n")

     # Launch
     if os.name == "nt":
        process_args = shlex.split(command_line, posix=False)
        p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                               stdout = subprocess.PIPE)
     else:
        process_args = shlex.split(command_line)
        p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                               stdout = subprocess.PIPE)

     (child_stdout, child_stdin) = (p.stdout, p.stdin)

     child_stdin.write(self.programParameters)
     child_stdin.close()         

     # Capture any error from the alignment job and print it to screen if debug mode is on
     log=open(self.logfile, "w")
     line=child_stdout.readline()
     while line:
        log.write(line)
        if self.debug:
           sys.stdout.write(line)
        line=child_stdout.readline()
     child_stdout.close()
     log.close()

     count=0
     # Wait for the logfile to be written
     while os.path.isfile(self.logfile) == False:
        time.sleep(1) 
        count=count+1
        if count > 30:
          sys.stdout.write("MTZdump Error: taking too long to write log file %s" % self.logfile)
          break

  def getCell(self):
    f = open(self.logfile,'r')
    logline = f.readline()
    # with "while logline" this loop terminates early
    # don't know why!
    while 1:
      if 'Cell Dimensions' in logline:
        logline = f.readline()
        logline = f.readline()
        cell = string.split(logline)
        f.close()
        return cell
      logline = f.readline()
    f.close()

  def getSymmetryNumber(self):
    """ Get the symmetry number. """

    f = open(self.logfile,'r')
    logline = f.readline()
    # with "while logline" this loop terminates early
    # don't know why!
    while 1:
      if 'Space group' in logline:
        l = string.split(logline)
        symmetryNumber = int(l[-1].rstrip(')'))
        f.close()
        return symmetryNumber
      logline = f.readline()
    f.close()

  def getSpacegroup(self):
    """ Get the space group """

    f = open(self.logfile,'r')
    logline = f.readline()

    while logline:
      if 'Space group' in logline:
        l = string.split(logline, "'")
        spacegroup = l[-2].replace(" ","")
        f.close()
        return spacegroup
      logline = f.readline()
    f.close()

  def getResolution(self):
    """ Get the resolution of the target MTZ file. """

    f = open(self.logfile,'r')
    logline = f.readline()
    # with "while logline" this loop terminates early
    # don't know why!
    while 1:
      if 'Resolution Range' in logline:
        logline = f.readline()
        logline = f.readline()
        resline = string.split(logline)
        resolution = float(resline[-3].rstrip(')'))
        f.close()
        return resolution
      logline = f.readline()
    f.close()

  def getColumnData(self):
    """ A function to get the column labels and types from an MTZ file. Takes in a dictionary
    to store the labels and the their corresponding column types"""

    # Open the log file for reading

    f = open(self.logfile,'r')
    logline = f.readline()

    # Loop over the lines in the logfile and save the column data information

    while logline:
      if 'Column Labels' in logline:
        logline = f.readline()
        logline = f.readline()
        col_labels = string.split(string.strip(logline))
      #if 'Column Types' in logline:
      #  logline = f.readline()
      #  logline = f.readline()
      #  ctypes = string.split(string.strip(logline))
        break
      logline = f.readline()
  
    # Fill the dictionary with the column details

    #for i in range(len(clabels)):
       #col_data[clabels[i]]=ctypes[i]

    f.close()
    return col_labels


if __name__ == "__main__":
   """ A test example or can be used to run as standalone. """

   # Check the input arguments
   if len(sys.argv) != 3:
      print "Usage: python MTZ_info.py <HKLIN> <info type>"
      print "       HKLIN     - input MTZ file"
      print "       info type - information requested"
      print "          -> cell"
      print "          -> spacegroup"
      print "          -> resolution"
      print "          -> col_data"
      sys.exit()

   # Set information type
   itype=(sys.argv[2]).lower()

   if "cell" not in itype and "spacegroup" not in itype and "resolution" not in itype and "col_data" not in itype:
      print "'%s' is not a valid argument for <info type>" % sys.argv[2]
      print "Valid arguments are:" 
      print "          -> cell"
      print "          -> spacegroup"
      print "          -> resolution"
      print "          -> col_data"
      sys.exit()

   # Instantiate the class
   md=Mtzdump()
   
   # Set the MTZ file and the output log file
   md.setHklin(sys.argv[1])
   md.setMTZdumpLogfile("./")

   # Run mtzdump
   md.go()
  
   if itype == "cell": 
      print md.getCell()
   
   if itype == "spacegroup": 
      print md.getSpacegroup()
 
   if itype == "resolution": 
      print md.getResolution()
 
   if itype == "col_data": 
      print md.getColumnData()
 

