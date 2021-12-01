#!/usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan 
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#

import os, sys, string, time
import shutil
import exceptions

import dbClientAPI
import ccp4i

class Handler:
   """ A class to handle all interactions with the CCP4i DB Handler. """

   def __init__(self):

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

      self.dotdir=""
      self.dirdef_file=""

   def start(self, init, mstat):
      """ A function to start the connection to the DB Handler. """

      # Set the user name
      user=init.environment.USER
      if user == "":
         sys.stdout.write("DB Handler Log: No user name: setting to 'unknown'\n")
         user = "unknown"
      else:
         sys.stdout.write("DB Handler Log: User is '"+user+"'\n")
         
      # Get the users ".CCP4" directory
      self.dotdir=ccp4i.GetDotCCP4()

      # Set the path to the directories_mr.def file
      self.dirdef_file=os.path.join(self.dotdir, "directories_mr.def")

      sys.stdout.write("DB Handler Log: Starting connection to DB handler...\n")
      sys.stdout.write("DB Handler Log: Def file set to:\n   %s\n" % self.dirdef_file)
      sys.stdout.write("\n")

      # Try starting a connection to the DB handler
      try:
         if self.debug:
            mstat.conn = dbClientAPI.HandlerConnection('MrBump')
         else:
            mstat.conn = dbClientAPI.HandlerConnection('MrBump', broadcastflag=False)
          
         # Fetch project name and job id
         # Project name not supplied so try reverse lookup?
         for project in mstat.conn.ListProjects():
            if init.keywords.ROOTDIR == mstat.conn.GetProjectDir(project):
               init.ProjectName=project
               break
         init.JobId=init.keywords.JOBID
         sys.stdout.write("Project: "+init.ProjectName+"\n")
         sys.stdout.write("Job id : "+init.JobId)

      # Attempt to set up this project
         # Check to see if there is a previous data base here, if so, move it
         if os.path.isdir(os.path.join(init.search_dir, "logs", "CCP4_DATABASE")):
            if self.debug:
               sys.stdout.write("DB Handler Log: A previous Database has been found here. Moving it to 'OLD_CCP4_DATABASE'\n")
            shutil.move(os.path.join(init.search_dir, "logs", "CCP4_DATABASE"), \
                      os.path.join(init.search_dir, "logs", "OLD_CCP4_DATABASE"))

         # Now set up a database connection for this job
         try:
            mstat.mrbump_project=mstat.conn.OpenProject(init.ProjectName)
         except:
            sys.stdout.write("DB handler error\n")
            sys.exit(1)

      except exceptions.Exception,x:
         sys.stdout.write("dbsocket_crash: connection failed with exception:\n")
         sys.stdout.write("DBviewer error: this feature will not be used as there was an error\n")
         sys.stdout.write("                initiating the connection to the database.\n")
         sys.stdout.write("\n")
         sys.stdout.write(str(x)+"\n")
         init.keywords.DBOUT=False
         init.keywords.DBVIEW=False
   
      # If the DBviewer needs to be launched (updated to use spawnl to launch dbviewer (2.3 friendly))
      if init.keywords.DBOUT and init.keywords.DBVIEW:
         if os.name=="nt":
            wishEXE=ccp4i.FindExecutable("wish")
            os.spawnl(os.P_NOWAIT, wishEXE, "wish", os.path.join(os.environ["DBCCP4I_TOP"], "bin", "dbviewer") \
               + ' %s %s -title "MrBUMP" ' % (init.ProjectName, init.JobId))
         else:
            os.system('dbviewer %s %s -title "MrBUMP" &' % (init.ProjectName, init.JobId))

   def stop(self, mstat):
      """ A function to stop the connection to the CCP4i DB Handler. """

      if self.debug:
         sys.stdout.write("DB Handler Log: Terminating connection to DB handler...\n")

      mstat.conn.HandlerDisconnect()
