#
#     Copyright (C) 2006
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
#
# dbconsole.py
#
# A "console" client application for dbccp4i
# Allow the user to issue commands to the database via
# the dbClientAPI.
#
# Usage:  python dbconsole.py
#
#====================================================================
#
#Cvs_Id $Id: dbconsole.py,v 1.9 2008/08/12 10:48:04 pjx Exp $
#
#####################################################################

import exceptions
import sys
import os
import threading

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

def PrintResult(result):
    print 'Result:'
    print result

# Defaults
directories_file = ""

# Collect command line arguments
i = 1
nargs = len(sys.argv)-1
while i < nargs:
    arg = str(sys.argv[i])
    if arg == "-directories":
        # Non-default directories file
        i=i+1
        directories_file = str(sys.argv[i])
        print "Non-default directories file: "+str(directories_file)
    else:
        # Unrecognised option
        print "Unrecognised option: "+str(arg)
        print "Usage: "+str(usage)
        sys.exit(1)
        # Next argument
        i=i+1

# Try to connect to the handler
try:
    conn = dbClientAPI.HandlerConnection('dummy',True,directories=directories_file)
    #conn.DbRegister('dummy',True)
except exceptions.Exception,e:
    print "dbconsole: connection failed with exception:"
    print str(e)
    sys.exit(1)

def broadcast():
    conn.BroadcastReporter()
    
# Set up a broadcast reporter
#conn.BroadcastReporter()


t = threading.Thread(target = broadcast)
t.start()

# Acquire the location of the Client API source file
# Use the DBCCP4I_TOP environment variable
dbccp4i_top = os.environ.get("DBCCP4I_TOP")
if dbccp4i_top == "":
    print "DBCCP4I_TOP is not set"
    sys.exit()
dbClientAPI_file = os.path.join(dbccp4i_top,"ClientAPI","dbClientAPI.py")
f = open(dbClientAPI_file,"r")
print 'The functions in HandlerConnection class are:\n'
while 1:
    line = f.readline()
    if not line: break
    if 'class db' in line: break
    
    if 'def ' in line:
        if '__init__' in line:
            continue
        elif 'request_wrapper' in line:
            continue
        elif 'parse_response' in line:
            continue
        elif 'GetEnvVar' in line:
            continue
        elif 'DbStartHandler' in line:
            continue
        elif 'GetHandlerPort' in line:
            continue
        elif 'ConvertTime' in line:
            continue
        elif 'BroadcastReporter' in line:
            continue
        elif '#' in line:
            continue
        else:
            print line
f.close()

print 'Usage: command arg1 arg2...'
print 'For example: OpenProject MYPROJECT'
while 1:
    print '\nEnter command & arguments: (Type \'exit\' to stop) '
    input = raw_input('% ')
    if 'exit' in input:
        break
    else:
        try:
            input = ccp4i.tokenise(input)

            if input[0] == 'DbInfo':
                result = conn.DbInfo()
                PrintResult(result)
                
            elif input[0] == 'CheckServerStatus':
                result = conn.CheckServerStatus()
                PrintResult(result)
                
            elif input[0] == 'OpenProject':
                if len(input) < 2:
                    print 'Wrong argument'
                    print 'Usage: OpenProject project [grablock] [readonly]'
                    continue
                result = conn.OpenProject(input[1])
                PrintResult(result)

            elif input[0] == 'CreateProject':
                if len(input) != 3:
                    print 'Usage: CreateProject project dir'
                    continue
                result = conn.CreateProject(input[1],input[2])
                PrintResult(result)
                
            elif input[0] == 'Updatetime':
                result = conn.Updatetime(input[1],input[2])
                PrintResult(result)
            
            elif input[0] == 'ListJobs':
                if len(input) < 3:
                    result = conn.ListJobs(input[1])
                else:
                    result = conn.ListJobs(input[1],input[2])
                PrintResult(result)
                
            elif input[0] == 'ImportProject':
                result = conn.ImportProject(input[1],input[2])
                PrintResult(result)

            elif input[0] == 'DeleteProject':
                result = conn.DeleteProject(input[1])
                PrintResult(result)
            
            elif input[0] == 'AddDefDirRef':
                result = conn.AddDefDirRef(input[1],input[2])
                PrintResult(result)

            elif input[0] == 'DeleDefDirRef':
                result = conn.DeleDefDirRef(input[1])
                PrintResult(result)
                
            elif input[0] == 'GetNextJobList':
                result = conn.GetNextJobList(input[1],input[2])
                PrintResult(result)
                
            elif input[0] == 'GetAllFileLinks':
                result = conn.GetAllFileLinks(input[1])
                PrintResult(result)
                
            elif input[0] == 'GetFileLinks':
                result = conn.GetFileLinks(input[1],input[2])
                PrintResult(result)
                
            elif input[0] == 'GetAllParents':
                result = conn.GetAllParents(input[1],input[2])
                PrintResult(result)
                
            elif input[0] == 'GetAllChildren':
                result = conn.GetAllChildren(input[1],input[2])
                PrintResult(result)

            elif input[0] == 'GetParents':
                result = conn.GetParents(input[1],input[2])
                PrintResult(result)
                
            elif input[0] == 'GetChildren':
                result = conn.GetChildren(input[1],input[2])
                PrintResult(result)
                
            elif input[0] == 'GetListofRecords':
                result = conn.GetListofRecords(input[1],input[2],input[3])
                PrintResult(result)
                
            elif input[0] == 'AddInputFile':
                result = conn.AddInputFile(input[1],input[2],input[3],input[4])
                PrintResult(result)
                
            elif input[0] == 'AddOutputFile':
                result = conn.AddOutputFile(input[1],input[2],input[3],input[4])
                PrintResult(result)
                
            elif input[0] == 'SetLogfile':
                result = conn.SetLogfile(input[1],input[2],input[3])
                PrintResult(result)
                
            elif input[0] == 'GetFileList':
                result = conn.GetFileList(input[1],input[2],input[3])
                PrintResult(result)
                
            elif input[0] == 'HandlerDisconnect':
                result = conn.HandlerDisconnect()
                PrintResult(result)
                
            elif input[0] == 'ShutDown':
                result = conn.ShutDown()
                PrintResult(result)
                
            elif input[0] == 'CloseProject':
                if len(input) != 2:
                    print 'Wrong argument'
                    print 'Usage: CloseProject project'
                    continue
                result = conn.CloseProject(input[1])
                PrintResult(result)
                
            elif input[0] == 'NewJob':
                if len(input) != 2:
                    print 'Wrong argument'
                    print 'Usage: NewJob project'
                    continue
                result = conn.NewJob(input[1])
                PrintResult(result)
                
            elif input[0] == 'DeleteJob':
                if len(input) != 3:
                    print 'Wrong argument'
                    print 'Usage: DeleteJob project jobid'
                    continue
                result = conn.DeleteJob(input[1],input[2])
                PrintResult(result)
                
            elif input[0] == 'ItemExists':
                if len(input) != 4:
                    print 'Wrong argument'
                    print 'Usage: ItemExists project jobid item'
                    continue 
                result = conn.ItemExists(input[1],input[2],input[3])
                PrintResult(result)
                
            elif input[0] == 'SetData':
                if len(input) != 5:
                    print 'Wrong argument'
                    print 'Usage: SetData project jobid item value'
                    continue 
                result = conn.SetData(input[1],input[2],input[3],input[4])
                PrintResult(result)
                
            elif input[0] == 'GetData':
                if len(input) != 4:
                    print 'Wrong argument'
                    print 'Usage: GetData project jobid item'
                    continue 
                result = conn.GetData(input[1],input[2],input[3])
                PrintResult(result)
                
            elif input[0] == 'GetDescription':
                if len(input) != 5:
                    print 'Wrong argument'
                    print 'Usage: GetDescription project job_list db_display db_display_format'
                    continue 
                result = conn.GetDescription(input[1],input[2],input[3],input[4])
                PrintResult(result)
                
            elif input[0] == 'SelectJobs':
                if len(input) != 4:
                    print 'Wrong argument'
                    print 'Usage: SelectJobs project item pattern'
                    continue 
                result = conn.SelectJobs(input[1],input[2],input[3])
                PrintResult(result)

            elif input[0] == 'ListProjects':
                result = conn.ListProjects()
                PrintResult(result)
                
            elif input[0] == 'DeleteProject':
                if len(input) != 2:
                    print 'Wrong argument'
                    print 'Usage: DeleteProject project'
                    continue 
                result = conn.DeleteProject(input[1])
                PrintResult(result)
                
            elif input[0] == 'GetProjectDir':
                result = conn.GetProjectDir()
                PrintResult(result)
                
            elif input[0] == 'ListDataDirs':
                result = conn.ListDataDirs()
                PrintResult(result)
                
            elif input[0] == 'GetDataDir':
                if len(input) != 2:
                    print 'Wrong argument'
                    print 'Usage: GetDataDir def_dir'
                    continue 
                result = conn.GetDataDir(input[1])
                PrintResult(result)
                  
            elif input[0] == 'GetNJOB':
                if len(input) != 2:
                    print 'Wrong argument'
                    print 'Usage: GetNJOB project'
                    continue  
                result = conn.GetNJOB(input[1])
                PrintResult(result)
                
            elif input[0] == 'GetNProjects':
                result = conn.GetNProjects()
                PrintResult(result)

            elif input[0] == 'GetNotebook':
                result = conn.GetNotebook(input[1],input[2])
                PrintResult(result)
                
            elif input[0] == 'SetJobQuality':
                result = conn.SetJobQuality(input[1],input[2],input[3])
                PrintResult(result)

            elif input[0] == 'GetJobQuality':
                result = conn.GetJobQuality(input[1],input[2])
                PrintResult(result)
                
            elif input[0] == 'GetSQLdbData':
                argu_len = len(input)
                result = conn.GetSQLdbData(input[1],input[2],input[3])
                PrintResult(result)
            
            elif input[0] == 'GetAllSQLDbData':
                argu_len = len(input)
                result = conn.GetAllSQLdbData(input[1],input[2],input[3])
                PrintResult(result)

            elif input[0] == 'SetTaskname':
                result = conn.SetTaskname(input[1],input[2],input[3])
                PrintResult(result)

            elif input[0] == 'SetTitle':
                result = conn.SetTitle(input[1],input[2],input[3])
                PrintResult(result)

            elif input[0] == 'SetStatus':
                result = conn.SetStatus(input[1],input[2],input[3])
                PrintResult(result)
                
            elif input[0] == 'ListInputFiles':
                result = conn.ListInputFiles(input[1],input[2])
                PrintResult(result)

            elif input[0] == 'ListOutputFiles':
                result = conn.ListOutputFiles(input[1],input[2])
                PrintResult(result)

            elif input[0] == 'AddSubJob':
                result = conn.AddSubJob(input[1],input[2],input[3],input[4])
                PrintResult(result)

            elif input[0] == 'SelectSubJobs':
                result = conn.SelectSubJobs(input[1],input[2],input[3],input[4])
                PrintResult(result)

            elif input[0] == 'HasSubJobs':
                result = conn.HasSubJobs(input[1],input[2])
                PrintResult(result)

            elif input[0] == 'ListJobwithsubjobs':
                result = conn.ListJobwithsubjobs(input[1])
                PrintResult(result)
                
            else:
                print 'Wrong command, please try again.'
                continue
        except exceptions.Exception,e:
            print str(e)

conn.HandlerDisconnect()

