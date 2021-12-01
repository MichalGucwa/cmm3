#
# addfiles.py
#
# A simple test client application which adds the same input
# file to a job multiple times
#
# This attempts to test bug #2662.
#
# Usage:
# > python test_addfiles.py <project> <job_id> <filen>
#
# <type> should be either "input" or "output"
#
#Cvs_Id $Id: test_addfiles.py,v 1.9 2008/08/12 10:48:30 pjx Exp $
#--------------------------------------------------------------

import sys
import exceptions
import os,os.path

# Add directories with dbCCP4i python modules
if os.path.isdir(os.path.join(os.environ["DBCCP4I_TOP"])):
    dbccp4i_path = os.path.join(os.environ["DBCCP4I_TOP"],"dbccp4i")
    sys.path.append(dbccp4i_path)
    clientapi_path = os.path.join(os.environ["DBCCP4I_TOP"],"ClientAPI")
    sys.path.append(clientapi_path)
try:
    import ccp4i
    import dbClientAPI
except ImportError:
    print "Unable to load one or more of the DbCCP4i modules"
    sys.exit(1)

# Say hello
print "============================"
print "addfiles.py"
print "============================"

# Read the command line
if len(sys.argv) == 4:
    project = sys.argv[1]
    print "Project \""+project+"\""
    job_id = sys.argv[2]
    print "Jobid "+str(job_id)
    filen = sys.argv[3]
    print "File "+str(filen)
else:
    print "Usage: addfiles <project> <job_id> <filen>"
    sys.exit(1)
    
print "%s %s %s" % (project,job_id,filen)

# Open a connection to the handler
user = ccp4i.GetUserId()
if user == "":
    print "No user name: setting to 'unknown'"
    user = "unknown"
else:
    print "User is '"+user+"'"

# Try to connect to the handler
try:
    conn = dbClientAPI.HandlerConnection('dummy',True)
except exceptions.Exception,e:
    print "test_addfile.py: connection failed with exception:"
    print str(e)
    sys.exit(1)

# Do some stuff
try:    
    # open project
    if conn.OpenProject(project):
        print str(conn.GetData(project,job_id,"TITLE","TASKNAME"))
        print "Before: input files  = "+str(conn.ListInputFiles(project,job_id))
        #print "      : output files = "+str(conn.ListOutputFiles(project,job_id))
        # Add the file
        conn.AddInputFile(project,job_id,filen,"")
        print "Added file once ... try again"
        # Add again
        conn.AddInputFile(project,job_id,filen,"")
        print "After: input files  = "+str(conn.ListInputFiles(project,job_id))
        #print "      : output files = "+str(conn.ListOutputFiles(project,job_id))
except:
    raise

# Disconnect and exit
conn.HandlerDisconnect()
print "Disconnected... finished"
sys.exit(0)



