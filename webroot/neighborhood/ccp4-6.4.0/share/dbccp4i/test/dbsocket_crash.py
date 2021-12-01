#
# dbsocket_crash.py
#
# A simple test client application which checks that the
# client API also stops when the main application crashes
#
# This attempts to cause bug #2003 reproducibly.
#
# This script contains an intentional bug, it tries to call
# a function which is not defined. If the bug is present
# then the process will not end when the bug is encountered
# and the UNIX "kill" command will be required to end the
# process.
# If the bug is fixed then the process will stop when the
# undefined function is invoked.
#
# Usage:
# > python dbsocket_crash.py <project> <job_id>
#
#Cvs_Id $Id: dbsocket_crash.py,v 1.9 2008/08/12 10:48:30 pjx Exp $
#--------------------------------------------------------------

# Say hello
print "============================"
print "dbsocket_crash"
print "============================"

# Import core language modules
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

# Read the command line
if len(sys.argv) == 3:
    project = sys.argv[1]
    print "Project \""+project+"\""
    job_id = sys.argv[2]
    print "Job id "+str(job_id)
else:
    print "Usage: dbsocket_crash <project> <job_id>"
    sys.exit(1)

# Open a connection to the handler

try:
    conn = dbClientAPI.HandlerConnection('dbsocket_crash',True)

except exceptions.Exception,e:
    print "dbsocket_crash: connection failed with exception:"
    print str(e)
    sys.exit(1)

# Do some stuff
try:    
    # open project
    if conn.OpenProject(project,readonly=True):
        # get job data
        status = NonExistantMethod(project,job_id)
except:
    # Intentionally don't trap the error
    raise

# Disconnect and exit
conn.HandlerDisconnect()
print "Disconnected... finished"
sys.exit(0)



