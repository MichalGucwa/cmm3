#
# dbccp4i_test_client.py
#
# A simple Python test client application
#
# Usage:
# > python dbccp4i_test_client.py
#
#Cvs_Id $Id: dbccp4i_test_client.py,v 1.7 2008/08/12 10:48:30 pjx Exp $
#--------------------------------------------------------------

# Say hello
print "============================"
print "dbccp4i_test_client"
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

# Open a connection to the handler

# Commented out test code for MrBUMP
# This should probably be shifted to a separate test
##directories_mr = os.path.join(ccp4i.GetDotCCP4(),"directories_mr.def")

try:
    # Commented out test code for MrBUMP
    ##conn = dbClientAPI.HandlerConnection('test_directories_mr', \
    ##                                     directories=directories_mr)
    conn = dbClientAPI.HandlerConnection('dbccp4i_test_client')

except exceptions.Exception,e:
    print "dbccp4i_test_client.py: connection failed with exception:"
    print str(e)
    sys.exit(1)

# Do some stuff
try:
    # List projects
    projects = conn.ListProjects()
    print "Projects = "+str(projects)
except exceptions.Exceptions,e:
    # Intentionally don't trap the error
    print "dbccp4i_test_client.py: unable to list projects"
    print str(e)
    sys.exit(1)

# Disconnect and exit
conn.HandlerDisconnect()
print "Disconnected... finished"
sys.exit(0)
