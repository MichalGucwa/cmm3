from dbClientAPI import *
import ccp4i
import exceptions
import sys
import os

try:
    # connect to handler
    conn = HandlerConnection("ApplicationName",True)

except exceptions.Exception,e:
    print "connection to handler failed"
    print str(e)
    sys.exit()

# Create a project
project = "testproject"
dir = '/home/wy45/tmp/testproject/'

try:
    print conn.ListProjects()
    conn.CreateProject(project,dir)
    # create a job
    id = conn.NewJob(project)

    inputfile = dir + '/abc.mtz'
    outputfile = dir + '/xyz.mtz'
    # add input file & output file
    conn.AddInputFile(project,id,inputfile)
    conn.AddOutputFile(project,id,outputfile)
    
    # add logfile
    conn.SetLogfile(project,id,'abc.log')

    print conn.ListInputFiles(project,id)
    print conn.ListOutputFiles(project,id)
    conn.CloseProject(project)
except DbError,e:
    print 'DBerror'
    print str(e)
    
except exceptions.Exception,e:
    print 'catch exception:', str(e)


conn.HandlerDisconnect()
