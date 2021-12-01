#
# test_directories_mr.py
#
# A simple Python test client application that attempts to
# use the directories_mr.def file
#
# Usage:
# > python test_directories_mr.py
#
#Cvs_Id $Id: test_directories_mr.py,v 1.2 2008/08/12 10:48:30 pjx Exp $
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
print "test_directories_mr"
print "============================"

# Open a connection to the handler

directories_mr = os.path.join(ccp4i.GetDotCCP4(),"directories_mr.def")

try:
    conn = dbClientAPI.HandlerConnection('test_directories_mr', \
                                         directories=directories_mr)

except exceptions.Exception,e:
    print "test_directories_mr.py: connection failed with exception:"
    print str(e)
    sys.exit(1)

# Try talking to the handler
try:
    # List projects
    projects = conn.ListProjects()
    print "Projects = "+str(projects)
except:
    # Intentionally don't trap the error
    raise

# Disconnect and exit
conn.HandlerDisconnect()
print "Disconnected... finished"
sys.exit(0)



