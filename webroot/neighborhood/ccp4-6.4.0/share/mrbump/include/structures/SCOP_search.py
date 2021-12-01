#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Martyn Winn 
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# scop_search.py
# Unmaintained by Martyn Winn
# 1st July 2005

import os
import sys
import string
import subprocess, shlex

import Get_SCOP

# Test for CCP4 & CBIN
if not os.environ.has_key('CCP4'):
    raise RuntimeError, 'CCP4 not found'
if not os.environ.has_key('CBIN'):
    raise RuntimeError, 'CBIN not found'

scratch_dir=os.environ['CCP4_SCR']

class Domain_struct:
   """Domain structures for a PDB structure"""   

   def __init__(self):
     self.pdbcurEXE = os.environ['CBIN'] + '/pdbcur'
     self.pdbid = ''
     self.no_of_hits = 0
     self.no_of_ranges = 0
     self.sid = []
     self.res_range = []
     self.range_list = []
     try:
        self.debug=eval(os.environ['MRBUMP_DEBUG'])
     except:
        self.debug=False

   def setDEBUG(self, flag):
      self.debug(flag) 

   def setSCOPFile(self, filename):
      self.SCOPFile = filename

   def setNumofRanges(self, number):
      self.no_of_ranges = number

   def get_SCOP_file(self, filename): 
      """ A function to call the SCOP retrieval class to get the latest SCOP list. """

      # Retrieve the scop list
      scop=Get_SCOP.Get_SCOP()

      scop.get_scop_details(scratch_dir + '/scop_url.html')
      scop.get_scop_list(filename)

   def findDomains(self, filename, pdbid):

     # This searches the SCOP file "filename" for instances
     # of the PDB id "pdbid"
     # Appropriate domains are added to arrays in memory.
     # Domains must be smaller than whole chains, since whole
     # chains are already included in list of templates

     self.pdbid = pdbid

     file = open(filename,'r')
     logline = file.readline()

     # This while loop assumes the format of the SCOP file

     while logline:
       if pdbid in logline:
         l = string.split(logline)
         # sanity check for PDB id
         if self.pdbid == l[4]:
           # exclude cases where domain is whole chain, i.e. no residue range given
           if '-' in l[5]: 
             # exclude cases where domain is whole PDB entry
             if l[5] != '-':
               if l[3][5:6] != '_':
                  self.sid.append(pdbid + "_" + l[3][5:7])
               else:
                  self.sid.append(pdbid + "_" + "a" + l[3][6:7])
               self.res_range.append(l[5])
               if self.debug:
                  sys.stdout.write("PDB entry %s has domain %s with residue range %s\n" % (l[4],l[3],l[5]))
               self.no_of_hits = self.no_of_hits + 1
       logline = file.readline()

     if self.debug:
        sys.stdout.write("\n")

     if self.no_of_hits == 0: 
       print "No domains found for %s" % self.pdbid
     file.close()

     return self.sid

   def getDomainRanges(self, res_range):
     """ Function to extract the residue ranges for a domain from the res_range limits. 
         Sets: Number of ranges of residues,
               List of ranges."""

     residue_ranges=[]
     self.range_list=[]

     # We need to extract the residues are in the domain making sure to
     # remove any gaps in this range of residues.

     # Split the residue line into individual ranges. If there is more than
     # one range then we need to exclude the gaps between them.
     print res_range
     split_up = string.split(res_range, ',')
     if ':' in split_up[0]:
        chain_code = string.split(split_up[0], ':')[0]
     else:
        chain_code = 'A'

     # Get the first and last residue index for the entire domain
     for i in split_up:
        if ':' in i:
           r=string.split(i,":")
           residue_ranges.append(r[1])
        else:
           residue_ranges.append(i)

     # Find out how many gaps there are in the domain
     self.setNumofRanges(len(residue_ranges))

     # Work out the residue ranges that are parts of the domains
     for i in residue_ranges:
        res_list=string.split(i,"-")
        a=[]

        # The starting residues
        if res_list[0] == "":
           a.append(-int(res_list[1]))
        else:
           a.append(int(res_list[0]))

        # The final residues
        if res_list[-2] == "":
           a.append(-int(res_list[-1]))
        else:
           a.append(int(res_list[-1]))

        # Update the list of ranges
        self.range_list.append(a)

   def getDomainCoordinates(self, sid, res_range, pdb_file, scop_dir='.'):

     # For a particular SCOP domain, the domain definition is applied
     # to the PDB file using program PDBCUR, resulting in a new
     # PDB file and associated program log file

     # Test to see if the scop directory for storing the pdb exists
     if os.path.isdir(scop_dir) == False:
        print "SCOP log message: Could not find directory: %s" % scop_dir
        sys.exit(1)

     residue_ranges=[]
     self.range_list=[]

     # We need to extract the residues are in the domain making sure to
     # remove any gaps in this range of residues.

     # Split the residue line into individual ranges. If there is more than
     # one range then we need to exclude the gaps between them.
     split_up = string.split(res_range, ',')
     if ':' in split_up[0]:
        chain_code = string.split(split_up[0], ':')[0]
     else:
        if (string.split(split_up[0], "-")[-1][-1]).isalpha():
           chain_code=string.split(split_up[0], "-")[-1][-1]
        else:
           chain_code = 'A'

     # Get the first and last residue index for the entire domain
     
     for i in split_up:
        if ':' in i:
           r=string.split(i,":")
           residue_ranges.append(r[1])
        else:
           if (string.split(split_up[0], "-")[-1][-1]).isalpha():
              residue_ranges.append(i.replace(chain_code, ''))
           else:
              residue_ranges.append(i)

     # Find out how many gaps there are in the domain
     self.setNumofRanges(len(residue_ranges))

     # Work out the residue ranges that are parts of the domains
     for i in residue_ranges:
        res_list=string.split(i,"-")
        a=[]

        # The starting residues
        if res_list[0] == "":  
           a.append(-int(res_list[1]))
        else:
           a.append(int(res_list[0]))

        # The final residues
        if res_list[-2] == "":
           a.append(-int(res_list[-1]))
        else:
           a.append(int(res_list[-1]))

        # Update the list of ranges
        self.range_list.append(a)
    
     # Create a keyword line for pdbcur
     pc_key =  'lvres /1/' + chain_code + '/' + `self.range_list[0][0]` + '-' + `self.range_list[-1][1]` + '\n'

     # Create a keyword line for pdbcur to remove the "gap" residues
     if self.no_of_ranges > 1:
        for i in range(self.no_of_ranges - 1):
            pc_key +=  'delres /1/' + chain_code + '/' + `self.range_list[i][1]+1` + '-' + `self.range_list[i+1][0]-1` + '\n'   
     
     # Finish the key file for pdbcur
     pc_key += 'end\n'

     if self.debug:
        # Ouput the te details of the pdbcur job to text file
        key_file=os.path.join(scop_dir, sid + "_pdbcur_details.txt")
        kf=open(key_file, "w")

        kf.write("\n")
        kf.write("Pdbcur keywords for " + sid + ":\n")
        kf.write(pc_key)
        kf.write("Output PDB: " + os.path.join(scop_dir, sid +".pdb") + "\n")
        kf.close()

     # Run pdbcur to extract domain residues
     ### Place choice of paths here ###
     ### This assumes original PDB file in current directory
     termination=False

     # Set the command line
     command_line = self.pdbcurEXE + ' xyzin ' + pdb_file + ' xyzout ' + os.path.join(scop_dir, sid +'.pdb')
 
     # Launch
     if os.name == "nt":
        process_args = shlex.split(command_line, posix=False)
        p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                                 stdout = subprocess.PIPE)
     else:
        process_args = shlex.split(command_line)
        p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                           stdout = subprocess.PIPE)

     (o, i) = (p.stdout, p.stdin)
 
     # Enter the keywords
     i.write(pc_key)
     i.close()

     # Watch the output for successful termination
     out=o.readline()
     pc_log=out
     while out:
        if 'Normal termination' in out:
           termination=True
        out=o.readline()
        pc_log += out
     o.close()

     if not termination:
        print "pdbcur failed for %s" % sid
        if self.debug:
           print "Logfile:"
           print pc_log
        return 1
     else:
        return 0
        

# tested with 1fsv, 1iml, 1ne7, 1o9l

def run():
 
  if len(sys.argv) == 2:
     pdb_ID = sys.argv[1] 
  else:
     usage()

  domains = Domain_struct()
  domains.findDomains('scop_list.txt', pdb_ID)
  print "Found %d domains" % domains.no_of_hits
  for i in range(domains.no_of_hits):
    domains.getDomainCoordinates(domains.sid[i],domains.res_range[i], pdb_ID + ".pdb")

def usage():
  print "Usage: scop_search.py <PDB_ID>"
  sys.exit(1) 

 
if (__name__ == "__main__"):
  run()

# returns page listing 2 domains of 1o9l
#wget --output-document="scop.html" "http://scop.mrc-lmb.cam.ac.uk/scop/search.cgi?pdb=1o9l"

# returns PDB file of domain fragment
#wget --output-document="astral.pdb" "http://astral.berkeley.edu/pdbstyle.cgi?id=d1emn_1&output=text"
