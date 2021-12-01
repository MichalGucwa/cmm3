#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2007 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#
# Script to test internet connectivity for MrBUMP
# Ronan Keegan 3/12/07
#

import os, string, sys, time
import shutil
import urllib
import time


class Test_connection:
   """ A class to test proxy settings and internet connectivity. """

   def __init__(self): 

      self.connect=False
      self.pdbid=""
      self.code=""
      self.local_file=""
      self.proxy=""

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False
 
   def test(self, pdbid, download_urls):
      """ Test the connection to the PDB servers. """

      # Check to see if the http_proxy has been set
      sys.stdout.write("#################################################\n")
      sys.stdout.write("Checking to see if the http_proxy has been set...\n")
      sys.stdout.write("#################################################\n")
      sys.stdout.write("\n")
      
      try:
         self.proxy=os.environ["http_proxy"]
      except:
         self.proxy=""
   
      if self.proxy == "":
         sys.stdout.write("Proxy has not been set...\n")
         sys.stdout.write("\n")
      else:
         sys.stdout.write("Proxy is set to: %s\n" % self.proxy)
         sys.stdout.write("\n")
         

      # Set the name of the PDB file to download
      self.pdbid=pdbid.lower()

      # Set the identifier character code (middle two characters in PDB name)
      self.code=self.pdbid[1:3]

      # Set the local file name to download the file to (scratch space or else cwd) 
      if os.access(os.environ["CCP4_SCR"], os.W_OK):
         self.local_file=os.path.join(os.environ["CCP4_SCR"], self.pdbid + ".pdb")
      elif os.access(os.getcwd(), os.W_OK):
         self.local_file=os.path.join(os.getcwd(), self.pdbid + ".pdb")
      else:
         sys.stdout.write("Error: Cannot write to CCP4_SCR or current working directory for the\n")
         sys.stdout.write("       PDB file download test.\n")
         sys.stdout.write("       Current working directory: %s.\n" % os.getcwd())
         sys.stdout.write("       CCP4_SCR directory: %s.\n" % os.environ["CCP4_SCR"])
         sys.stdout.write("\n")
   
      # Try the EBI server
      try:
         url=download_urls["EBI"].url + "pdb" + self.pdbid + ".ent"
         if self.debug:
            sys.stdout.write("Download location 1 (EBI): %s\n" % url)
            sys.stdout.write("\n")
         start=time.time()
         urllib.urlretrieve(url, self.local_file)
         end=time.time()
         urllib.urlcleanup()

         download_urls["EBI"].con_time=end-start 
         self.connect=True

         # Tidy up the downloads
         if self.debug == False:
            os.remove(self.local_file)
         else:
            shutil.move(self.local_file, self.local_file + "_EBI")

      except:
         download_urls["EBI"].con_time=20000.0
         sys.stdout.write("Warning: Problem downloading PDB file from source 1 (EBI server)\n")
         sys.stdout.write("\n")
       
      # Try the WWPDB server
      try:
         url=download_urls["WWPDB"].url + "pdb" + self.pdbid + ".ent.gz"
         if self.debug:
            sys.stdout.write("Download location 2 (WWPDB): %s\n" % url)
            sys.stdout.write("\n")
         start=time.time()
         urllib.urlretrieve(url, self.local_file + ".gz") 
         end=time.time()
         urllib.urlcleanup()

         download_urls["WWPDB"].con_time=end-start 
         self.connect=True

         # Tidy up the downloads
         if self.debug == False:
            os.remove(self.local_file + ".gz")
         else:
            shutil.move(self.local_file + ".gz", self.local_file + "_WWPDB.gz")

      except:
         download_urls["WWPDB"].con_time=20000.0 
         sys.stdout.write("Warning: Problem downloading PDB file from source 2 (RCSB server)\n")
         sys.stdout.write("\n")
       
      # Try the Osaka server in Japan
      try:
         url=download_urls["JAPAN"].url + "pdb" + self.pdbid + ".ent.gz"
         if self.debug:
            sys.stdout.write("Download location 3 (JAPAN): %s\n" % url)
            sys.stdout.write("\n")
         start=time.time()
         urllib.urlretrieve(url, self.local_file + ".gz")
         end=time.time()
         urllib.urlcleanup()

         download_urls["JAPAN"].con_time=end-start 
         self.connect=True

         # Tidy up the downloads
         if self.debug == False:
            os.remove(self.local_file)
         else:
            shutil.move(self.local_file + ".gz", self.local_file + "_JAPAN.gz")

      except:
         download_urls["JAPAN"].con_time=20000.0 
         sys.stdout.write("Warning: Problem downloading PDB file from source 3 (JAPAN server)\n")
         sys.stdout.write("\n")
      
      # Try the OCA server
      try:
         url=download_urls["OCA"].url + self.pdbid
         if self.debug:
            sys.stdout.write("Download location 4 (OCA): %s\n" % url)
            sys.stdout.write("\n")
         urllib.urlretrieve(url, self.local_file)
         urllib.urlcleanup()
         self.connect=True

         # Tidy up the downloads
         if self.debug == False:
            os.remove(self.local_file)
         else:
            shutil.move(self.local_file, self.local_file + "_OCA")

      except:
         sys.stdout.write("Warning: Problem downloading PDB file from source 4 (OCA server)\n")
         sys.stdout.write("\n")
      
      # Rank the servers (closest first)
      self.orderSERVERS(download_urls)

      if self.connect==False:
         sys.stdout.write("Error: Could not establish connection to any of the PDB file servers.\n")
         sys.stdout.write("       MrBUMP requires an internet connection to retrieve PDB files.\n")
         sys.stdout.write("       Also, do you need to set a proxy server to connect to the web?\n")
         sys.stdout.write("\n")

      sys.stdout.write("#################################################\n")
      sys.stdout.write("\n")
      time.sleep(2)

   def orderSERVERS(self, download_urls):
      """ Rank the servers according to their connection times. """

      for source in download_urls.keys():
         if self.debug:
            sys.stdout.write("Connection time for: %s = %.3lf\n" % (source, download_urls[source].con_time))
            sys.stdout.write("\n")

      # this is cluncky and a bit rigid, will need to come up with a better way if more servers are to be added
      if download_urls["EBI"].con_time < download_urls["WWPDB"].con_time:
         if download_urls["EBI"].con_time < download_urls["JAPAN"].con_time:
            download_urls["EBI"].rank = 1
            if download_urls["WWPDB"].con_time < download_urls["JAPAN"].con_time:
               download_urls["WWPDB"].rank = 2
               download_urls["JAPAN"].rank = 3
            else:
               download_urls["JAPAN"].rank = 2
               download_urls["WWPDB"].rank = 3
         else:
            download_urls["JAPAN"].rank = 1
            download_urls["EBI"].rank = 2
            download_urls["WWPDB"].rank = 3
      else:
         if download_urls["WWPDB"].con_time < download_urls["JAPAN"].con_time:
            download_urls["WWPDB"].rank = 1
            if download_urls["EBI"].con_time < download_urls["JAPAN"].con_time:
               download_urls["EBI"].rank = 2
               download_urls["JAPAN"].rank = 3
            else:
               download_urls["JAPAN"].rank = 2
               download_urls["EBI"].rank = 3
         else:
            download_urls["JAPAN"].rank = 1
            download_urls["WWPDB"].rank = 2
            download_urls["EBI"].rank = 3

      if self.debug:
         sys.stdout.write("Ordering for PDB download attempts from servers:\n")
         num_servers=len(download_urls)
         for i in range(num_servers):
            for source in download_urls.keys():
               if download_urls[source].rank==i:
                  sys.stdout.write("Rank %d --> %s\n" % (i, source))
         sys.stdout.write("\n")

if __name__ == "__main__":
 
  T=Test_connection()
  T.debug=True
  T.test("1nio")
