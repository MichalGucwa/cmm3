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
#
# A python class for performing a local fasta search
# Ronan Keegan 13.9.05

import os, sys, string
import urllib
import shutil
import Scan_path


class Fasta:
   """ A class to do a Fasta search with a target sequence on a local DB. """

   def __init__(self):

      chk=Scan_path.Check_PATH()
      if chk.find_exec("fasta35"):
         self.fasta_EXE=os.path.join(chk.exe_directory, "fasta35")
      elif chk.find_exec("fasta34"):
         self.fasta_EXE=os.path.join(chk.exe_directory, "fasta34")
      elif chk.find_exec("fasta36"):
         self.fasta_EXE=os.path.join(chk.exe_directory, "fasta36")
      else:
         sys.stdout.write("Fasta Error: neither fasta35, fasta34 nor fasta36 executable found on system.\n")
         sys.stdout.write("\n")
         sys.exit()

      self.fastaDB = ''
      self.E_value = 0.0
      self.command_line = ''
      self.logfile = ''
      self.sequence = ''
      self.fastaDB_URL_1 = 'ftp://ftp.rcsb.org/pub/pdb/derived_data/pdb_ATOMseqs.txt'
      self.fastaDB_URL_2 = 'http://www.ccp4.ac.uk/ronan/bmp_data/pdb_ATOMseqs.txt'
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False
  
   def setDEBUG(self, flag):
      self.debug=flag 

   def setFastaDB(self, filename):
      self.fastaDB = filename

   def setEValue(self, value):
      self.E_value = value

   def setCommandLine(self, arg):
      self.command_line = self.command_line + " " + arg

   def setLogfile(self, filename):
      self.logfile = filename


   def get_fastaDB(self, debug=False):
      """ A function to download the latest version of the fasta DB if required. 
          Input:
          1. File name for fasta database,
          2. A debug flag (optional, default = False). 
          Returns:
          1. Booleen for success/failure of retrieval."""

      # Check the fasta DB location is set
      if self.fastaDB == '':
         print "Fasta search log: Error: Fasta DB location is not set"
         sys.exit(1) 

      # If debug is "True" give verbose output
      if self.debug == True:
         print ""
         print "------------------------------------"
         print "Fasta DB retrieval - Debugging Mode"
         print "------------------------------------"
         print ""

         print "Primary URL location: %s" % self.fastaDB_URL_1
         print "Secondary URL location: %s" % self.fastaDB_URL_2
         print "Local DB file: %s" % self.fastaDB
         print ""
           
      # Try to retrieve the latest version of the DB
      try: 
         try:
            urllib.urlretrieve(self.fastaDB_URL_1, self.fastaDB)
         except:
            print "Fasta search log: Fasta URL 1 failed, trying URL 2...."
            urllib.urlretrieve(self.fastaDB_URL_2, self.fastaDB)
         urllib.urlcleanup()
         success_flag = True
      except:
         print ""
         print "Fasta search log: Fasta DB could not be rerieved from any of the URL locations"
         success_flag = False 

      return success_flag

   def fasta_search_local(self, input_seq_file, output_file, E_value=0.02, debug=False):
      """ A function to do a local fasta search. 
          Input:
          1. Input file containing target sequence,
          2. Output results file,
          3. E value for search (optional, default = 0.02),
          4. A debug flag (optional, default = False). """

      # Check the fasta DB location is set
      if self.fastaDB == '':
         print "Fasta search log: Error: Fasta DB location is not set"
         sys.exit(2) 

      # Check the log file is set
      if self.logfile == '' and debug == False:
         print "Fasta search log: Error: Fasta search logfile is not set"
         sys.exit(3) 

      # Set the E value for the search and the logfile
      self.setEValue(E_value)
   
      # Give a verbose output if debug is "True"
      if debug == True:
         print ""
         print "-------------------------------"
         print "Fasta search - Debugging Mode"
         print "-------------------------------"
         print ""
           
         print "Input file: %s" % input_seq_file
         print "Output results file : %s" % output_file
         print "E value: %f" % self.E_value
         print ""
 
      # Set the command line arguments
      if os.name == "nt":

         # On windows we need to be in the DB folder to make it work 

         input_seq_filename=os.path.split(input_seq_file)[-1]
         fastaDB_filename=os.path.split(self.fastaDB)[-1]
         fastaDB_dir=os.path.split(self.fastaDB)[0]

         current_dir=os.getcwd()
         os.chdir(fastaDB_dir)
         shutil.copy(input_seq_file, fastaDB_dir)

         self.setCommandLine("-q -O " + output_file + " -E " + `self.E_value` + " " + input_seq_filename \
            + " " + fastaDB_filename + " 1")
         
      else:
         self.setCommandLine("-q -O " + output_file + " -E " + `self.E_value` + " " + input_seq_file \
            + " " + self.fastaDB + " 1")

      # Run the job 
      if self.debug:
         sys.stdout.write("---------------------\n")
         sys.stdout.write("FASTA command line:  \n")
         sys.stdout.write("---------------------\n")
         sys.stdout.write("\n")
         sys.stdout.write(self.fasta_EXE + " " + self.command_line + "\n")
         sys.stdout.write("\n")

      stdout=os.popen(self.fasta_EXE + " " + self.command_line)

      logfile=open(self.logfile, "w")

      if self.debug == True:
         print "--------------------------"
         print "Output from FASTA search:"
         print "--------------------------"
         print ""

      line = stdout.readline()
      while line:
         if self.debug: 
            print string.strip(line)
         logfile.write(line)
         line = stdout.readline()
      stdout.close()
      logfile.close()
  
      # If we are in Windows remove the copy of the sequence file and change back to the working dir
      if os.name == "nt":
         os.remove(input_seq_filename)
         os.chdir(current_dir)

      # Test for the output file
      if os.path.isfile(output_file) == False:
         sys.stdout.write("Fasta search log: The Fasta search for input file " \
                + "%s failed to produce a results file. Check the log file:\n" % input_seq_file)
         sys.stdout.write(self.logfile + "\n") 
         sys.stdout.write("\n") 
         sys.exit(1)

   def fasta_search_web(self, input_seq_file, output_file, E_value=0.02, debug=False):
      """ A function to do a web-based (OCA) fasta search. 
          Input:
          1. Input file containing target sequence,
          2. Output results file,
          3. E value for search (optional, default = 0.02),
          4. A debug flag (optional, default = False). """

      # Set the E value for the search and the logfile
      self.setEValue(E_value)
   
      # Give a verbose output if debug is "True"
      if self.debug == True:
         sys.stdout.write("-------------------------------\n")
         sys.stdout.write("Fasta search - Debugging Mode\n")
         sys.stdout.write("-------------------------------\n")
         sys.stdout.write("\n")
           
         sys.stdout.write("Input file: %s\n" % input_seq_file)
         sys.stdout.write("Output results file : %s\n" % output_file)
         sys.stdout.write("E value: %f\n" % self.E_value)
         sys.stdout.write("\n")
      
      # Parse the sequence file to get the target sequence
      self.parse_seq_file(input_seq_file)

      # Retrieve the OCA results.
      search_URL="http://bip.weizmann.ac.il/oca-bin/ocaids?al=on&dat=dep&ev=%s&ex=any&fa=%s&lim=40&m=du" % (self.E_value, self.sequence)

      if self.debug:
         sys.stdout.write("Fasta search log: URL for OCA query:\n   %s\n" % search_URL)
         sys.stdout.write("\n")

      try:
         urllib.urlretrieve(search_URL, output_file)
         urllib.urlcleanup()
      except:
         print "Fasta search log: Error retrieving OCA results page."
         print "If you need to use a proxy server to access the internet please ensure that you have configured your proxy settings correctly."
         sys.exit()

   def parse_seq_file(self, input_seq_file):
      """ Parse the input sequence file to extract the target sequence. 
          Input:
          1. Sequence file. """

      header = ''
 
      # Open the target sequence file
      seq_file=open(input_seq_file)

      # Read the header line
      line=seq_file.readline()
      header=string.strip(line)

      # Get the sequence
      line=seq_file.readline()
      while line:
         self.sequence = self.sequence + string.strip(line)
         line=seq_file.readline()
      seq_file.close()
      

if __name__ == '__main__':

   def usage():
      print "Usage: Fasta_search <method>" 
      print "  where method = 'web' for web-based search"
      print "  or    method = 'local' for search using local DB" 
      print ""
 
   if len(sys.argv) != 2:
      usage()
      sys.exit()
   
   if sys.argv[1] != 'web' and sys.argv[1] != 'local':
      usage()
      sys.exit()

   f=Fasta()
   if sys.argv[1] == 'local':
      f.setFastaDB("pdb_ATOMseqs.txt")
      f.get_fastaDB(debug=True)
      f.setLogfile("log.log")
      f.fasta_search_local("eg2.seq", "results.txt", debug=True)
   else:
      f.fasta_search_web("eg2.seq", "results.txt", debug=True)

