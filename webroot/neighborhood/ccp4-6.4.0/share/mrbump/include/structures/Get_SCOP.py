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
# A script to downlaod the latest SCOP database paraseable file.
# Results in the downlading of the SCOP Access Methods URL and
# the parseable scop list.
# Ronan Keegan 7.9.2005

import os, string, sys
import urllib


class Get_SCOP:
   """ A class to retrieve the latest scop parseable file for finding domains. """
 
   def __init__(self):
      self.scop_details_file = ''
      self.scop_list_file = ''
      self.scop_index_url = ''
      self.scop_list_url = ''
      self.scop_version = ''
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setDEBUG(self, flag):
      self.debug(flag) 

   def setScopDetailsFile(self, filename):
      self.scop_details_file = filename
 
   def setScopListFile(self, filename):
      self.scop_list_file = filename
 
   def setScopIndexURL(self, urlname):
      self.scop_index_url = urlname
 
   def setScopListURL(self, urlname):
      self.scop_list_url = urlname
 
   def setScopVersion(self, version):
      self.scop_version = version
 

   def get_scop_details(self, filename):
      """ A function to retrieve and parse the scop details file for the latest 
          version of the scop list. """

      # Set the scop URL and the local scop file name
      self.setScopIndexURL("http://scop.mrc-lmb.cam.ac.uk/scop/parse/index.html")
      self.setScopDetailsFile(filename)

      # Rteieve the scop url
      if os.path.isfile(self.scop_details_file) == False:
         urllib.urlretrieve(self.scop_index_url, self.scop_details_file)

      # Extract the latest verion number from the scop URL file
      file=open(self.scop_details_file, "r")
   
      found = False

      line = file.readline()
      while line:
         if "des.scop.txt_" in line:
            end=string.split(line,'_')[1]
            self.setScopVersion(string.split(end,'"')[0])
            found = True
            break
         line = file.readline()

      if found == False:
         print "Error in SCOP version retrieval: could not find version number in html"
      else:
         print "SCOP message: latest parseable list file version = " + self.scop_version
      
      # Remove the url file
      os.remove(filename)

   def get_scop_list(self, filename):
      """ A function to download the latest scop list version. """

      # Set the SCOP URL and local list file
      self.setScopListURL("http://scop.mrc-lmb.cam.ac.uk/scop/parse/dir.des.scop.txt_" + self.scop_version)
      self.setScopListFile(filename)

      # Retrieve the SCOP list
      urllib.urlretrieve(self.scop_list_url, self.scop_list_file)


if __name__ ==  '__main__':

   sc=Get_SCOP()
   sc.get_scop_details("scop_url.html")
   sc.get_scop_list("scop_list.txt")

   sys.exit()

