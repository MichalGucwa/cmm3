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
# Python script to handle the downloading of PDB files from the various servers.
# Ronan Keegan 16/1/08

import os, sys, string
import urllib
import shutil
import subprocess, shlex

class DownloadPDB:
   """ A class to retrieve PDB files from the web. """

   def __init__(self):

      self.pdbID=""
      self.local_file=""
      self.success = False
#      self.download_urls={'EBI' : 'ftp://ftp.ebi.ac.uk/pub/databases/msd/pdb_uncompressed/',
#                          'RCSB' : 'ftp://ftp.rcsb.org/pub/pdb/data/structures/all/pdb/',
#                          'OCA' : 'http://oca.ebi.ac.uk/oca-bin/save-pdb?id=',
#                          'WWPDB' : 'ftp://ftp.wwpdb.org/pub/pdb/data/structures/all/pdb/',
#                          'JAPAN' : 'ftp://pdb.protein.osaka-u.ac.jp/pub/pdb/data/structures/all/pdb'}
                     
      if os.name == "nt":
         self.unzipEXE = "7z x -y" 
      else:
         self.unzipEXE = "gunzip -f"

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setDEBUG(self, flag):
      self.debug=flag 


   def download_PDB(self, init, pdbID, local_file):
      """ A function to download a PDB file using the various servers available. """

      num_servers=len(init.download_urls)  
 
      self.success = False
      for i in range(num_servers):
         for source in init.download_urls.keys():
            if init.download_urls[source].rank == i+1:
               self.getPDB(init, source, pdbID, local_file)
               if self.success == True:
                  break
         if self.success == True:
            break
        
   def getPDB(self, init, source, pdbID, local_file):
      """ Download the file from the server. """

      if source == "EBI":
         remote_file=init.download_urls["EBI"].url + 'pdb' + pdbID + '.ent   '
      elif source == "WWPDB":
         remote_file=init.download_urls["WWPDB"].url + 'pdb' + pdbID + '.ent.gz'
      elif source == "JAPAN":
         remote_file=init.download_urls["JAPAN"].url + 'pdb' + pdbID + '.ent.gz'
      elif source == "OCA":
         remote_file=init.download_urls["OCA"].url + pdbID.upper() + '.pdb.gz'
            
      if self.debug:
         sys.stdout.write("Download Log: Attempting to download the PDB file for %s from %s site:\n  URL: %s\n" % (pdbID, source, remote_file))  
         sys.stdout.write("Download Log: This will be saved to:\n   %s\n" % local_file) 
         sys.stdout.write("\n") 

      try:
         if source == "EBI":
            urllib.urlretrieve(remote_file, local_file)
         else:
            urllib.urlretrieve(remote_file, local_file + ".gz")
    
            # Note the current dir and change into the one where the zip file is
            cwd=os.getcwd()
            localPDBDir = os.path.split(local_file)[0]
            os.chdir(localPDBDir)

            # Unzip the pdb file
            # Set the command line
            command_line = self.unzipEXE + " " + local_file + ".gz"

            # Set the process arguments
            process_args = shlex.split(command_line)
      
            # Launch unzip
            p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                 stdout = subprocess.PIPE)
            (out, ip) = (p.stdout, p.stdin)

            ip.close()

            line=out.readline()
            while line:
               line=out.readline()
            out.close()
            # if the file has extracted in the original name move it to the correctly named file
            if os.path.isfile(os.path.join(localPDBDir, "pdb" + pdbID + ".ent")):
               os.rename(os.path.join(localPDBDir, "pdb" + pdbID + ".ent"), local_file)
            os.chdir(cwd)

            # remove the zipped version of the file
            if os.path.isfile(local_file + ".gz") and self.debug == False:
               os.remove(local_file + ".gz")

         urllib.urlcleanup()
         self.success = True
      except:
         sys.stdout.write("Download Log: Failed to retrieve PDB %s from %s site\n" % (pdbID, source))
         sys.stdout.write("\n")
         self.success = False
         
   def getlocal_PDB(self, PDBpath, pdbID, local_file):
      """ Retrieve the PDB file from a local mirror of the PDB. Assumes files are zipped and stored in 
          directories with names corresponding to middle characters in PDB ID. """
          
      pdbdir_code=pdbID[1:3]
      filename   ="pdb" + pdbID + ".ent"
 
      if self.debug:
         sys.stdout.write("Download Log: Getting file for %s from local PDB mirror\n" % pdbID) 
         sys.stdout.write("\n") 

      # Check for the existence of the local PDB mirror
      if os.path.isdir(PDBpath) == False:
         sys.stdout.write("Download log: Error - specified path to local PDB mirror does not exist\n") 
         sys.stdout.write("                      If you have not got a local PDB mirror turn this\n")
         sys.stdout.write("                      option off and re-try using the online PDB servers\n")
         sys.stdout.write("\n")
         sys.exit()
         
      # Check the path to the file
      if os.path.isfile(os.path.join(PDBpath, pdbdir_code, filename + ".gz")):
         shutil.copyfile(os.path.join(PDBpath, pdbdir_code, filename + ".gz"), local_file + ".gz")
          
         # Note the current dir and change into the one where the zip file is
         cwd=os.getcwd()
         localPDBDir = os.path.split(local_file)[0]
         os.chdir(localPDBDir)

         # Unzip the pdb file
         # Set the command line
         command_line = self.unzipEXE + " " + local_file + ".gz"

         # Set the process arguments
         process_args = shlex.split(command_line)
   
         # Launch unzip
         p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                              stdout = subprocess.PIPE)
         (out, ip) = (p.stdout, p.stdin)

         ip.close()

         line=out.readline()
         while line:
            line=out.readline()
         out.close()
         # if the file has extracted in the original name move it to the correctly named file
         if os.path.isfile(os.path.join(localPDBDir, "pdb" + pdbID + ".ent")):
            os.rename(os.path.join(localPDBDir, "pdb" + pdbID + ".ent"), local_file)
         os.chdir(cwd)

         # remove the zipped version of the file
         if os.path.isfile(local_file + ".gz") and self.debug == False:
            os.remove(local_file + ".gz")

         self.success = True
      else:
         sys.stdout.write("Download Log: Failed to retrieve PDB %s from local PDB mirror\n" % pdbID)
         sys.stdout.write("\n")
         self.success = False
         
      
if __name__ == "__main__":

   p=DownloadPDB()
   p.debug=True
   p.getlocal_PDB("/tmp/data/pdb", "1nio", "/tmp/1nio.pdb")
   p.getlocal_PDB("/tmp/data/pdb", "1ntb", "/tmp/1ntb.pdb")

