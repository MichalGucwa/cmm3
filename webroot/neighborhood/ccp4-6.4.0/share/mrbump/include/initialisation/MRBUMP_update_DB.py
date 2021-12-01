# /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan 
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#
#A script to update the various search databases
#1. The PDB fasta sequence database file,
#2. The 3 PQS multimer listing files,
#3. The SCOP domain listing file.
# Ronan Keegan 27.9.05
# re-worked 14/2/07 to use modification details of files and not file sizes

import os, sys, string
import urllib
import shutil
import time


class DB_tools:
   """ A class to carry out various functions relating to the search databases. 
       It will test to see if this is the first run of MrBUMP. If this is the 
       case it will create the .ccp4_mrbump directory for storing the data files
       used in MrBUMP. 
       If this already exists (and the user selects the UPDATE keyword) it will 
       check that the data files are up to date with the server versions. This is
       done by downloading the mrbump_DB_info.txt file which contains the 
       modification times for each of the DB files. """
   
   def __init__(self):
      self.mrbump_data_dir = ""
      self.db_file_list={'pdb_ATOMseqs.txt' : 'PDB sequence DB',
                         'pqs_LIST.txt' : 'PQS list',
                         'pqs_ASALIST.txt' : 'PQS ASA list',
                         'pqs_BIOLIST.txt' : 'PQS BIO list',
                         'scop_list.txt' : 'SCOP list'}

      self.db_URL="http://www.ccp4.ac.uk/MrBUMP/data"
      self.mrbump_DB_infofile="mrbump_DB_info.txt"
 
      self.DB_old_modtime=dict([])
      self.DB_new_modtime=dict([])

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False
   
   def setDEBUG(self, flag):
      self.debug = flag  

   def setMRBUMPDataDir(self, directory):
      self.mrbump_data_dir = directory

   def test_first_run(self, environment):
      """ A function to setup directories if this is the first run ever of MRBUMP. """

      # Test for the "~/.ccp4_mrbump" folder.
   
      if os.path.isdir(environment.SETUP_DIR) == False:
         print "\n"
         print "Welcome to MRBUMP"
         print "This appears to be your first time running MRBUMP. Creating a '.ccp4_mrbump' folder in your home folder"
         print "This will hold copies of the various database files required for the template searches" 
         print "\n"

         os.mkdir(environment.SETUP_DIR) 
         for file in self.db_file_list.keys():
            shutil.copy(os.path.join(self.mrbump_data_dir, file), os.path.join(environment.SETUP_DIR, file))
      
      # If .ccp4_mrbump does exist, make sure it contains all of the DB files.
      else:
         for file in self.db_file_list.keys():
            if os.path.isfile(os.path.join(environment.SETUP_DIR, file)) == False:
               shutil.copy(os.path.join(self.mrbump_data_dir, file), os.path.join(environment.SETUP_DIR, file))
    
   def test_databases(self, environment, UPDATE):
      """ A function to update all of the databases used in the template search. """

      if UPDATE:
         # Test the database files to see if they need updating.
         sys.stdout.write("\n")
         sys.stdout.write("Database update: Checking the web to see if newer versions of the search databases exist.\n")
         sys.stdout.write("\n")

         # Check if data files have been modified
         self.check_file_modtimes(environment)

         # Update the DB files that are out of date 
         for filename in self.db_file_list.keys():
            if self.DB_old_modtime[filename] < self.DB_new_modtime[filename]:
               self.update_DB(self.db_file_list[filename], \
                              os.path.join(self.db_URL, filename), \
                              os.path.join(environment.SETUP_DIR, filename))
            else:
               sys.stdout.write("Database update: File %s is up to date.\n" % filename)
         sys.stdout.write("\n")
      else:
         print '\nDatabase update: Keyword "UPDATE" set to False. MrBUMP will not attempt a database update.'

   def update_DB(self, DB_type, url, local_file):
      """ A function to update the search databases if they are out of date."""
   
      # Make a note of the file name (without the path)
      filename=os.path.split(local_file)[-1]
      
      # If on Windows change the "C:" in the file name to "C|"
      if os.name == "nt":
         local_file="file:///" + local_file.replace(":","|")

      if self.debug:
         sys.stdout.write("DB update: remote URL: %s\n" % url)
         sys.stdout.write("DB update: local file: %s\n" % local_file)
         sys.stdout.write("DB update: old file is dated: %s\n" % time.ctime(self.DB_old_modtime[filename]))
         sys.stdout.write("DB update: new file is dated: %s\n" % time.ctime(self.DB_new_modtime[filename]))
         try:
            sys.stdout.write("HTTP proxy: %s\n" % os.environ["http_proxy"])
         except:
            sys.stdout.write("HTTP proxy not set in environment\n")
         sys.stdout.write("\n")

      # Download the latest file
      sys.stdout.write("DB update: Your " + DB_type + " file is out of date, attempting an update...\n")
      sys.stdout.write("\n")
      try:
         urllib.urlretrieve(url ,local_file)
         urllib.urlcleanup()
      except:
         sys.stdout.write("Download error: Cannot retrieve new version of " + DB_type + ". Will use old version\n")
         sys.stdout.write("\n")
      
   def check_file_modtimes(self, environment):
      """ Download and check the modification times of the files that are to be updated."""

      # Copy over the pdb_ATOMseqs.txt file from the data directory if it is newer
      if os.path.getmtime(os.path.join(environment.SETUP_DIR, 'pdb_ATOMseqs.txt')) \
           < os.path.getmtime(os.path.join(self.mrbump_data_dir, 'pdb_ATOMseqs.txt')):
           shutil.copy(os.path.join(self.mrbump_data_dir, 'pdb_ATOMseqs.txt'),os.path.join(environment.SETUP_DIR, 'pdb_ATOMseqs.txt'))

      INFOFILE=os.path.join(environment.SETUP_DIR, self.mrbump_DB_infofile)

      # Backup the old DB information file
      if os.path.exists(INFOFILE):
         shutil.move(INFOFILE, INFOFILE + ".tmp")

         # Extract the details of the modifications times to the dictionary
         file=open(INFOFILE + ".tmp", "r")

         line=file.readline()
         while line:
            filename=string.split(line)[0]
            try:
               modtime=int(string.split(line)[-1])
            except:
               modtime=0
               sys.stdout.write("Modtime Warning: (1) Couldn't extract the modification time from the old DB info file\n")
               sys.stdout.write("                 Modtime will be set to zero and files will be updated.\n")
               sys.stdout.write("                 Filename: %s\n" % filename)
               sys.stdout.write("\n")
            self.DB_old_modtime[filename]=modtime
            line=file.readline()

         file.close()

      else:
         # Otherwise initialise the DB_old_modtime to zero
         for filename in self.db_file_list.keys():
            self.DB_old_modtime[filename]=0

      try:
         # Download the latest DB information file to check the modification times
         urllib.urlretrieve(self.db_URL + "/" + self.mrbump_DB_infofile, INFOFILE)
                               
      except:
         sys.stdout.write("Problem downloading update informations. Skipping DB update...\n")
         sys.stdout.write("\n")
         #shutil.copyfile(self.mrbump_DB_infofile + ".tmp", self.mrbump_DB_infofile)

      # Extract the details of the modification times to the dictionary
      if os.path.isfile(INFOFILE):
         file=open(INFOFILE, "r")
   
         line=file.readline()
         while line:
            filename=string.split(line)[0]
            try:
               modtime=int(string.split(line)[-1])
            except:
               modtime=0
               sys.stdout.write("Modtime Warning: (2) Couldn't extract the modification time from the new DB info file\n")
               sys.stdout.write("                 Program will not attempt to update the following DB file:\n")
               sys.stdout.write("                 %s\n" % filename)
               sys.stdout.write("\n")
            self.DB_new_modtime[filename]=modtime
            line=file.readline()
   
         file.close()

      else:
         # Otherwise initialise the DB_new_modtime to zero
         for filename in self.db_file_list.keys():
            self.DB_new_modtime[filename]=0

      if self.debug:
         for filename in self.db_file_list.keys():
            sys.stdout.write("Database update: DB_old_modtime = %d \n" % self.DB_old_modtime[filename])
            sys.stdout.write("Database update: DB_new_modtime = %d \n" % self.DB_new_modtime[filename])
            if self.DB_old_modtime[filename] < self.DB_new_modtime[filename]:
               sys.stdout.write("Database update: Modification check - File %s is out of date and needs to be updated.\n" % filename)
            else:
               sys.stdout.write("Database update: Modification check - File %s is up to date.\n" % filename)
         sys.stdout.write("\n")

      # Remove the old file
      if os.path.exists(os.path.join(environment.SETUP_DIR, self.mrbump_DB_infofile + ".tmp")):
         os.remove(os.path.join(environment.SETUP_DIR, self.mrbump_DB_infofile + ".tmp"))

   def check_version(self, version):
      """ A function to check to see if a new version of MrBUMP exits."""

      download_url="http://www.ccp4.ac.uk/MrBUMP/release"

      # Retrieve the latest version number
      try:
         v=urllib.urlopen(download_url + "/version.txt")
         new_version_string=string.strip(v.readline())
         v.close()
      except:
         sys.stdout.write("New version check failed\n")
         sys.stdout.write("\n")
         return 

      # Set it as a float for comparison with current version 
      if new_version_string=="":
         new_version_string="0.0"

      head=new_version_string[0:3]
      tail=new_version_string[3:]

      try:
         new_version=float(head + tail.replace(".",""))
      except:
         sys.stdout.write("New version check failed\n")
         sys.stdout.write("\n")
         return 

      # Set the current version
      if version=="":
         version="0.0"

      head=version[0:3]
      tail=version[3:]

      cur_version=float(head + tail.replace(".",""))

      if new_version > cur_version:
         sys.stdout.write("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n")
         sys.stdout.write("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n")
         sys.stdout.write("   A newer version of MrBUMP is available (version " + new_version_string + ")\n")
         sys.stdout.write("   This can be downloaded from:\n")
         sys.stdout.write("   " + download_url + "/mrbump-" + new_version_string + ".tar.gz\n")
         sys.stdout.write("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n")
         sys.stdout.write("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n")
         sys.stdout.write("\n")


