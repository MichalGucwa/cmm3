#
#     Copyright (C) 2006
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - dbClientAPI.py
#
# Classes and methods for interacting with the database handler
# 
# Wanjuan Yang and Peter Briggs
#
#====================================================================

#CCP4i_cvs_Id $Id: dbClientAPI.py,v 1.11 2008/09/29 08:30:00 pjx Exp $

##################################################################

#
#d_index_title Database Handler Client API (ClientAPI/dbClientAPI.py)
#d_intro_title Functions for applications interacting with the DB server
#
#d_intro These are the commands that can be invoked by a client of \
#the database server in order to communicate with it. The commands map onto the commands provided in the database server.

import socket
import exceptions
import sys
import os
import re
import time
import ccp4i
import dbsocket

def DbStartHandler(directories=""):
    """Start a dbccp4i handler process in background.

    Specifying the full path and name of a non-default directories.def file
    equivalent using the 'directories' argument will start a handler
    process using this file instead of the default one."""
    
    handler = os.path.join(ccp4i.GetEnvVar("DBCCP4I_TOP"),"dbccp4i","dbccp4i.py")
    # If handler path contains spaces e.g. under Windows
    # then wrap in quotes
    if handler.count(" ") > 0:
        handler = '"'+str(handler)+'"'
    # Find full path for Python
    if os.name=="nt":
       # Use no-spawn window version on windows
       pythonexe = ccp4i.FindExecutable("pythonw")
    else:
       pythonexe = ccp4i.FindExecutable("python")

    try:
       if directories == "":
           status = os.spawnl(os.P_NOWAIT,pythonexe,"python",handler)
       else:
           # Wrap the directories file in quotes
           # This is necessary for paths that might contain spaces
           # e.g. under Windows
           dirsfile = '"'+str(directories)+'"'
           status = os.spawnl(os.P_NOWAIT,pythonexe,"python",handler, \
                              "-directories",dirsfile)
    except exceptions.Exception,e:
       print "DbStartHandler: failed with exception:"
       print str(e)
       status = -1
    return status

def GetHandlerPort(nowait=False,directories=""):
    """Acquire the port number for a handler process.

    Attempts to read the port number from the handler lock file in the
    user's .CCP4 area, and returns the port number if successful (otherwise
    returns -1). Set nowait=True to prevent the function from making
    multiple attempts to get the port number before giving up.

    The 'directories' argument specifies the path of a custom
    directories.def file, if a connection to a non-default file
    directories.def file is being used."""

    # The lockfile is called dbccp4i.LOCK and has the following content:
    # port number is:4090
    if not nowait:
        ntries = 10
        wait_time = 1
    else:
        ntries = 1
        wait_time = 0
    thistry = 0
    port = -1
    rlock = re.compile(r"^port number is:([0-9]+)$")
    # Set the lockfile name
    if directories == "":
        # Lockfile is just dbccp4i.LOCK
        lockfile = os.path.join(ccp4i.GetDotCCP4(),"dbccp4i.LOCK")
    else:
        # Lockfile is <file>_dbccp4i.LOCK for <file>.def
        lockfile = os.path.join(ccp4i.GetDotCCP4(), \
                                str(os.path.basename(os.path.splitext(directories)[0])) \
                                +"_dbccp4i.LOCK")
    #print "GetHandlerPort: lockfile = "+str(lockfile)
    while thistry < ntries:
        #print "GetHandlerPort: looking for lockfile"
        if ccp4i.FileExists(lockfile):
            # Open and read the contents
            #print "GetHandlerPort: opening lockfile"
            fp = open(lockfile,"r")
            line = fp.readline().rstrip()
            #print "GetHandlerPort: line from lockfile is "+str(line)
            if rlock.match(line):
                port = int(rlock.match(line).group(1))
            fp.close()
            #print "GetHandlerPort: port "+str(port)
            # Try to connect to the port and request the
            # server status
            try:
                addr = ('localhost',port)
                sock = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
                sock.connect(addr)
                request = dbsocket.dbRequest('DbRequestStatus',[])
                sock.send(request.xml()+"\n")
                xml_response = sock.recv(4096)
                response = dbsocket.dbResponse(xml_response)
                #print "GetHandlerPort: response from handler: " \
                      #+str(response.result(0))
                request = dbsocket.dbRequest('DbDisconnect',[])
                sock.send(request.xml()+"\n")
                sock.close()
                # Check the response
                if str(response.result(0)) == 'Active':
                    # Handler is alive - return the port number
                    return port
            except exceptions.Exception,e:
                print "GetHandlerPort: connection failed with exception:"
                print str(e)
                return -1
        # Wait for a little while then retry
        time.sleep(wait_time)
        thistry = thistry + 1
    # Timeout
    print "GetHandlerPort: timed out waiting for lockfile: "+str(lockfile)
    return -1

def ConvertTime(secs):
    """ Given a time expressed in seconds, convert into formated time """
    return time.strftime("%d %b %Y  %H:%M:%S",time.localtime(secs))

def ConvertTimeCCP4i(secs):
    """ Given a time expressed in seconds, convert into CCP4i format """
    return ccp4i.FormatDate(secs)

def Report(message):
    """ write error message to a logfile """
    logfile = os.path.join(ccp4i.GetDotCCP4(),"dbClientAPI_py.log")
    f = open(logfile,"w")
    f.write(message)
    f.write("\n")
    f.close()
    return

def ResultParser1(result):
    """Parse a response from the handler for success/fail-type requests.

    ResultParser1 is used to process the response to a handler
    request, for requests where the expected outcome is either success
    or failure, i.e.: operations where new projects or jobs are created
    or where job data is updated, and 'test' operations (for example
    testing if a data item is defined).

    Compare with ResultParser2, which is used for processing other
    result types.

    It returns 1 if the response indicates a successful outcome, and
    raises a DbError exception otherwise."""
    if result[0] == 'OK':
        return 1
    else:
        raise DbError(str(result[1]))

def ResultParser2(result):
    """Parse a response from the handler for requests for data.

    ResultParser2 is used to process the response to a handler
    request, for requests where the expected outcome is some form of
    data held in the database. For example, obtaing a list of jobs or
    fetching the value of a particular data item.

    Compare with ResultParser1, which is used for processing other
    result types.

    It returns the result value the response indicates successful
    outcome, and raises a DbError exception otherwise."""
    if result[0] == 'OK':
        return result[1]
    else:
        raise DbError(str(result[1]))
   
class DbError(Exception):
    """ Exception raised when db request is not successful """
    def __init__(self,message):
        self.message = message

    def __str__(self):
        return repr(self.message)
    
class HandlerConnection:

    """Create a connection to the database handler.

    The HandlerConnection class provides commands to talk to handler,
    and access the data in the database.def and directories.def files.

    'user_agent' should specify an identifying name for the client
    program which is accessing the database.
    
    'broadcastflag' indicates whether the client program wants to
    recieve broadcast notifications from the handler when the database
    is updated (optional).

    'directories' can be used to specify the name and full path of a
    non-default directories.def file that the handler associated with
    this connection should use (optional).

    Raises exceptions if unable to connect to a database handler
    instance."""

    def __init__(self,user_agent,broadcastflag=True,directories=""):
        try:
            self.directories_file = directories
            # start Handler
            DbStartHandler(directories=self.directories_file)
            time.sleep(0.5)
            self.host = 'localhost'
            self.port = GetHandlerPort(directories=self.directories_file)
            if self.port < 0:
                # Failed to acquire a valid port number
                raise DbError("Unable to fetch a valid port number to connect")
            self.sock = dbsocket.dbsocket(self.host,self.port)
            # register to handler
            self.DbRegister(user_agent,broadcastflag)

        except exceptions.Exception,e:
            # Connection attempt failed
            print 'Connecting Handler failed with exception: '
            print str(e)
            raise
    
    def DbRegister(self,user_agent,broadcast=True):
        """ Summary: Register with handler
            Arguments: 
            user_agent: application that talks to the db handler. e.g: ccp4i
            broadcast:  flag for whether application want to receive broadcast
            message from db handler
            """
        
        user = ccp4i.GetUserId()
        argu_list = [user,user_agent,broadcast]
        return ResultParser1(self.sock.request('DbRegister',argu_list))
    
    def CheckServerStatus(self):
        """ Summary: Return handler status """
        argu_list = []
        return ResultParser2(self.sock.request('DbRequestStatus',argu_list))

    def DbSupported(self,db):
        """ Summary: Check if handler support db type
            Argument:
            db: the type of db. e.g. def, sqlite
            """
        argu_list = [db]
        return ResultParser2(self.sock.request('DbSupported',argu_list))

    def DbInfo(self):
        """ Summary: Return information about the handler version
            """
        return ResultParser2(self.sock.request('DbInfo',[]))

    def OpenProject(self,project,grablock=False,readonly=False):
        """ Summary: Open an existing project
            Arguments:
            project: project name
            grablock: when there is a lock on database, set grablock True
            can force to open the database.
            readonly: when there is a lock on database, set readonly True
            can read the data, but not allow to update the data.
            """
        if grablock == True:
            argu_list = [project,"-grablock"]
        elif readonly == True:
            argu_list = [project,"-readonly"]
        else:
            argu_list = [project]
        return ResultParser1(self.sock.request('DbOpen',argu_list))
    
    def CreateProject(self,project,dir):
        """ Summary: Create a new project
            Arguments:
            project: project name
            dir: the path of the project
            """
        argu_list = [project,dir]
        return ResultParser1(self.sock.request('NewDb',argu_list))

    def Updatetime(self,project,jobid):
        """ Summary: Update the time of a job
            Arguments:
            project: project name
            jobid: job id
            """
        argu_list = [project,jobid]
        return ResultParser1(self.sock.request('Updatetime',argu_list))

    def ListJobs(self,project,jobid = ""):
        """ Summary: List all of the jobs in a project
            Argument:
            project: project name
            jobid: job id. This is only needed when list subjobs.
            """
        if jobid == "":
            argu_list = [project]
        else:
            argu_list = [project,jobid]
    
        return ResultParser2(self.sock.request('ListJobs',argu_list))
    
    def ImportProject(self,alias,path):
        """ Summary: Import a project
            Arguments:
            alias: project name
            path: path of the project
            """
        argu_list = [alias,path]
        return ResultParser1(self.sock.request('ImportProject',argu_list))

    def DeleteProject(self,project):
        """ Summary: Delete a project reference
            Argument:
            project: project name
            """
        argu_list = [project]
        return ResultParser1(self.sock.request('DeleteProject',argu_list))
    
    def AddDataDirRef(self,def_dir,path):
        """ Summary: Add default directory reference
            Arguments:
            def_dir: default directory name
            path: the path of the default directory
            """
        argu_list = [def_dir,path]
        return ResultParser1(self.sock.request('AddDataDirRef',argu_list))

    def DeleteDataDirRef(self,def_dir):
        """ Summary: Delete default directory reference
            Argument:
            def_dir: default directory name
            """
        argu_list = [def_dir]
        return ResultParser1(self.sock.request('DeleteDataDirRef',argu_list))
    
    def GetNextJobList(self,project,jobid):
        """ Summary: Return all the jobs that link to the job
            Arguments:
            project: project name
            jobid: job id
            """
        argu_list = [project,jobid]
        return ResultParser2(self.sock.request('GetNextJobList',argu_list))

    def GetAllFileLinks(self,project):
        """ Summary: Return all the links between jobs in a project
            Argument:
            project: project name
            """
        argu_list = [project]
        return ResultParser2(self.sock.request('GetAllFileLinks',argu_list))

    def GetFileLinks(self,project,joblist):
        """ Summary: Return the links for specified jobs
            Arguments:
            project: project name
            joblist: a list of job ids
            """
        argu_list = [project,joblist]
        return ResultParser2(self.sock.request('GetFileLinks',argu_list))

    def GetAllChildren(self,project,jobid):
        """ Summary: Return all the descendents of a job
            Arguments:
            project: project name
            jobid: job id
            """
        argu_list = [project,jobid]
        return ResultParser2(self.sock.request('GetAllChildren',argu_list))

    def GetAllParents(self,project,jobid):
        """ Summary: Return all the antecedents of a job
            Arguments:
            project: project name
            jobid: job id
            """
        argu_list = [project,jobid]
        return ResultParser2(self.sock.request('GetAllParents',argu_list))

    def GetParents(self,project,jobid):
        """ Summary: Return the immediate parents of the job
            Arguments:
            project: project name
            jobid: job id
            """
        argu_list = [project,jobid]
        return ResultParser2(self.sock.request('GetParents',argu_list))
    
    def GetChildren(self,project,jobid):
        """ Summary: Return the immediate children of the job
            Arguments:
            project: project name
            jobid: job id
            """
        argu_list = [project,jobid]
        return ResultParser2(self.sock.request('GetChildren',argu_list))

    def GetAllParentsChildren(self,project,jobid):
        """ Summary: Return all the antecedents of a job
            Arguments:
            project: project name
            jobid: job id
            """
        argu_list = [project,jobid]
        return ResultParser2(self.sock.request('GetAllParentsChildren',argu_list))
    
    def GetListofRecords(self,project,joblist,itemlist):
        """ Summary: Return a list of records for a project
            Arguments:
            project: project name
            joblist: a list of job ids
            itemlist: a list of items, e.g. ["TASKNAME","TITLE","STATUS"]
            """
        argu_list = [project,joblist,itemlist]
        return ResultParser2(self.sock.request('DbGetListofRecords',argu_list))
        
    def AddInputFile(self,project,jobid,filen,projdir=""):
        """ Summary: Add a file to the list of input files for a job.
            Arguments:
            projec: project name
            jobid: job id
            filen: input file name
            projdir: project directory
        """
        if projdir == "":
            argu_list  = [project,jobid,filen]
        else:
            argu_list = [project,jobid,filen,projdir]
        return ResultParser1(self.sock.request('AddInputFile',argu_list))

    def AddOutputFile(self,project,jobid,filen,projdir=""):
        """ Summary: Add a file to the list of input files for a job.
            Arguments:
            project: project name
            jobid: job id
            filen: output file name
            projdir: project directory
            """
        if projdir == "":
            argu_list  = [project,jobid,filen]
        else:
            argu_list = [project,jobid,filen,projdir]
        return ResultParser1(self.sock.request('AddOutputFile',argu_list))

    def SetLogfile(self,project,jobid,logfile):
        """ Summary: Set the filename for the logfile for a job.
            Arguments:
            project: project name
            jobid: job id
            logfile: logfile name
            """
        # Wrap a call to SetData to set the LOGFILE parameter
        return self.SetData(project,jobid,"LOGFILE",logfile)
                   
    def GetFileList(self,project,jobid,type):
        """ Summary: Return a list of files associated with a job.
            Arguments:
            project: project name
            jobid: job id
            type:  the type of file. e.g. 'INPUT','OUTPUT'
            """
        
        argu_list = [project,jobid,type]
        return ResultParser2(self.sock.request('GetFiles',argu_list))

    def ListInputFiles(self,project,jobid):
        """ Summary: Return a list of input files for a given job.
            Arguments:
            project: project name
            jobid: job id
            """       
        argu_list = [project,jobid]
        return ResultParser2(self.sock.request('ListInputFiles',argu_list))

    def ListOutputFiles(self,project,jobid):
        """ Summary: Return a list of output files for a given job.
            Arguments:
            project: project name
            jobid: job id
            """
        argu_list = [project,jobid]
        return ResultParser2(self.sock.request('ListOutputFiles',argu_list))

    def AddSubJob(self,project,jobid,taskname,title):
        """ Summary: Add a sub jobs to a job
            Arguments:
            project: project name
            jobid: job id
            """
        argu_list = [project,jobid,taskname,title]
        return ResultParser2(self.sock.request('AddSubJob',argu_list))

    def SelectSubJobs(self,project,jobid,item,pattern):
        """ Summary: Select sub jobs from a job
            Arguments:
            project: project name
            jobid: job id
            item: item name being searched on
            pattern: Regular expression pattern to search on
            """
        argu_list = [project,jobid,item,pattern]
        return ResultParser2(self.sock.request('SelectSubJobs',argu_list))

    def HasSubJobs(self,project,jobid):
        """ Summary: Check if the job has sub jobs
            Arguments:
            project: project name
            jobid: job id
            """
        argu_list = [project,jobid]
        return ResultParser2(self.sock.request('HasSubJobs',argu_list))

    def ListJobswithsubjobs(self,project):
        """ Summary: List jobs that have subjobs
            Arguments:
            project: project name
            """
        argu_list = [project]
        return ResultParser2(self.sock.request('ListJobswithsubjobs',argu_list))
    
    def HandlerDisconnect(self):
        """ Summary: Disconnect from handler """
        argu_list = []
        self.sock.request('DbDisconnect',argu_list)
        try:
            self.sock.close()
        except:
            print "Exception in HandlerDisconnect"
        
    def ShutDown(self):
        """ Summary: Shut down the handler """
        argu_list = []
        self.sock.request('Shutdown',argu_list)
        self.sock.close()

    def CloseProject(self,project):
        """ Summary: Close a project
            Argument:
            project: project name
            """
        argu_list = [project]
        return ResultParser1(self.sock.request('DbClose',argu_list))
    
    def NewJob(self,project):
        """ Summary: Create a job in a project
            Argument:
            project: project name
            """
        argu_list = [project]
        return ResultParser2(self.sock.request('DbNewJob',argu_list))

    def DeleteJob(self,project,job_id):
        """ Summary: Delete a job in a project
            Arguments:
            project: project name
            job_id: job id
            """
        argu_list = [project,job_id]
        return ResultParser1(self.sock.request('DbDeleteJob',argu_list))

    def ItemExists(self,project,job_id,item):
        """ Summary: Check if an item exist for a project
            Arguments:
            project: project name
            job_id: job id
            item: item name. e.g. TITLE, TASKNAME
            """
        argu_list = [project,job_id,item]
        return ResultParser1(self.sock.request('DbItemExists',argu_list))

    def SetData(self,project,job_id,*args):
        """ Summary: Set item value pairs for the same job in a project
            Arguments:
            project: project name
            job_id: job id
            *args: a list of item-value pairs. e.g. TASKNAME mlphare TITLE Refining Se sites
            """
        argu_list = [project,job_id]
        for arg in args:
            argu_list.append(arg)
        return ResultParser1(self.sock.request('DbSetData',argu_list))

    def GetData(self,project,job_id,*items):
        """ Summary: Return value for job data items in a project
            Arguments:
            project: project name
            job_id: job id
            *items: one or more items, e.g. "TITLE" "TASKNAME"
            """
        argu_list = [project,job_id]
        for item in items:
            argu_list.append(item)
        return ResultParser2(self.sock.request('DbGetData',argu_list))
 
    def SetTaskname(self,project,jobid,taskname):
        """ Summary: Set taskname for a job
            Arguments:
            project: project name
            jobid: job id
            taskname: taskname for the job. This taskname cannot contain space."""
        if ' ' in taskname:
            raise NameError,'Taskname can not contain space'
        else:
            return self.SetData(project,jobid,'TASKNAME',taskname)

    def SetTitle(self,project,jobid,title):
        """ Summary: Set title for a job
            Arguments:
            project: project name
            jobid: job id
            title: title for the job.
            """
        return self.SetData(project,jobid,'TITLE',title)

    def SetStatus(self,project,jobid,status):
        """ Summary: Set status for a job
            Arguments:
            project: project name
            jobid: job id
            status: status for the job.
            """
        return self.SetData(project,jobid,'STATUS',status)

    def GetDescription(self,project,job_list,db_display,db_display_format):
        """ Summary: Return the description of a job in a project
            Arguments:
            project: project name
            job_list: a list of job ids
            db_display: a list of the database parameters to be displayed
            db_display_format: a list of the field widths (as integers) to use for displaying the items in the db_display list
            """
        argu_list = [project,job_list,db_display,db_display_format]
        return ResultParser2(self.sock.request('DbReturnJobs',argu_list))
    
    def SelectJobs(self,project,item,pattern):
        """ Summary: Retrieve a list of jobs based on some selection criterion
            Arguments:
            project: project name
            item: item name being searched on
            pattern: Regular expression pattern to search on
            """
        argu_list = [project,item,pattern]
        return ResultParser2(self.sock.request('DbSelectJobs',argu_list))

    def ListProjects(self):
        """ Summary: List all the user's projects """
        argu_list = []
        return ResultParser2(self.sock.request('ListProjects',argu_list))

    def GetProjectDir(self,project):
        """ Summary: Return the directory corresponding to a project name
            Argument:
            project: project name
            """
        argu_list = [project]
        return ResultParser2(self.sock.request('GetProjectDir',argu_list))

    def ListDataDirs(self):
        """ Summary: Return a list of the user's default directories """
        argu_list = []
        return ResultParser2(self.sock.request('ListDataDirs',argu_list))

    def GetDataDir(self,def_dir):
        """  Summary: Return the directory corresponding to a def dir name
             Argument:
             def_dir: the default directory name
             """
        argu_list = [def_dir]
        return ResultParser2(self.sock.request('GetDataDir',argu_list))

    def GetDirectoriesData(self,*items):
        """  Summary: Return multiple data items for many different aliases
             Argument:
             One or more keyword-alias pairs. A keyword can be 'ProjectDir'
             (fetches the corresponding project directory for the
             subsequent alias), 'ProjectDBDir' (the corresponding database
             directory) or 'DataDir' (the corresponding data directory).
             """
        argu_list = items
        return ResultParser2(self.sock.request('GetDirectoriesData',argu_list))

    def GetNJOB(self,project):
        """ Summary: Return the highest job number in the project
            Argument:
            project: project name
            """
        argu_list = [project]
        return ResultParser2(self.sock.request('GetNJOB',argu_list))

    def GetNProjects(self):
        """ Summary: Return the number of projects """
        argu_list = []
        return ResultParser2(self.sock.request('GetNProjects',argu_list))

    def GetNotebook(self,project,jobid):
        """ Summary: Return the notebook
            Arguments:
            project: project name
            jobid: job id
            """
        argu_list = [project,jobid]
        return ResultParser2(self.sock.request('GetNotebook',argu_list))

    def ProjectWriteable(self,project):
        """ Summary: Check if the project is writeable
            Arugment:
            project: project
            """
        argu_list = [project]
        return ResultParser1(self.sock.request('ProjectWriteable',argu_list))
    
    def ProjectReadable(self,project):
        """ Summary: Check if the project is writeable
            Argument:
            project: project name
            """
        argu_list = [project]
        return ResultParser1(self.sock.request('ProjectReadable',argu_list))

    def ReacquireProject(self,project):
        """ Summary: Re grab the lock
            Argument:
            project: project name
            """
        argu_list = [project]
        return ResultParser1(self.sock.request('ReacquireProject',argu_list))

    def BroadcastReporter(self):
        """ Summary: Checks for broadcast messages and print them to stdout """
        dbsocket.report_broadcast(self.sock)

    def SetJobQuality(self,project,jobid,quality):
        """ Summary: Set Job quality data
            Arguments:
            project: project name
            jobid: job id
            quality: quality of the job solution. Could be '1','0' or '-1'.
            '1' means 'good', '0' means 'marginal', '-1' means 'bad'
            """
        argu_list = [project,jobid,quality]
        return ResultParser1(self.sock.request('SetJobQuality',argu_list))

    def GetJobQuality(self,project,jobid):
        """ Summary: Get Job quality data
            Arguments:
            project: project name
            jobid: job id
            """
        return self.GetSQLdbData(project,jobid,"JobQuality")
    
    def GetSQLdbData(self,project,jobid,*items):
        """ Summary: Return value for a given job given items from sql db
            Arguments:
            project: project name
            jobid: job id
            *itmes: one or more items. e.g. JobNumber, JobQuality
            """
        argu_list = [project,jobid]
        for item in items:
            argu_list.append(item)
        return ResultParser2(self.sock.request('GetSQLdbData',argu_list))

    def GetAllSQLdbData(self,project,itemlist):
        """ Summary: Return all values of given items from sql db
            Arguments:
            project: project name
            itemlist: a list of items. e.g. ["JobNumber","JobQuality"]
            """
        argu_list = [project,itemlist]
        return ResultParser2(self.sock.request('GetAllSQLdbData',argu_list))

    def HasSQLdb(self,project):
        """ Summary: Check if the project has SQL db
            Argument:
            project: project name
            """
        argu_list = [project]
        return ResultParser2(self.sock.request('HasSQLdb',argu_list))

    def NewTableRecord(self,project,table,*args):
        """ Summary: Create a new record in a table
            Argument:
            project: project name
            table: table name
            *args: a list of item-value pairs. 
            """
        
        argu_list = [project,table]
        for arg in args:
            argu_list.append(arg)
            
        return ResultParser2(self.sock.request('NewTableRecord',argu_list))

    def SetTableData(self,project,table,tableid,attribute,value):
        """ Summary: Set a value of an attribute in a table 
            Argument:
            project: project name
            table: table name
            tableid: the primary key for the record
            attribute: the attribute of the value belong to
            value: the value being set
            """
        argu_list = [project,table,tableid,attribute,value]
        return ResultParser1(self.sock.request('SetTableData',argu_list))

    def GetTableData(self,project,table,tableid,attribute):
        """ Summary: Get a value of an attribute in a table 
            Argument:
            project: project name
            table: table name
            tableid: the primary key for the record
            attribute: the attribute of the value belong to
            """
        argu_list = [project,table,tableid,attribute]
        return ResultParser2(self.sock.request('GetTableData',argu_list))

    def GetTablePrimaryKey(self,project,table,condition):
         """ Summary: Get a value of an attribute in a table 
            Argument:
            project: project name
            table: table name
            condition: the condition of getting the key, it is where clause of SQL language
            """
         argu_list = [project,table,condition]
         return ResultParser2(self.sock.request('GetTablePrimaryKey',argu_list))
    
class db:
    """  create a SQLite db object """
    def __init__(self,con):
        self.conn = con

    def sendrequest(self,command,argu_list):
        """ send request to handler and return response """
        response = self.conn.sock.request('',argu_list)
        return ResultParser2(response)

    def OpenDB(self,dbname,dir):
        """ Open a database """
        argu_list = [dbname,dir]
        return self.sendrequest('OpenDB',argu_list)

    def NewDB(self,dbname,dir):
        """ Create a database """
        argu_list = [dbname,dir]
        return self.sendrequest('NewDB',argu_list)
    
    def CloseDB(self):
        """ Close a database  """
        argu_list = []
        return self.sendrequest('CloseDB',argu_list)

    def NewRecord(self,table,*args):
        """ New a record in a given table 
            Arguments:
            table: table name
            *args: a list of item-value pairs.
            """
        argu_list = [table]
        for arg in args:
            argu_list.append(arg)        
        return self.sendrequest('NewRecord',argu_list)
    
    def SetData(self,table,id,attribute,value):
        """ Set attribute value in a table's record """
        argu_list = [table,id,attribute,value]
        return self.sendrequest('SetData',argu_list)

    def GetData(self,table,id,attribute):
        """ Return the attribute value in a table """
        argu_list = [table,id,attribute]
        return self.sendrequest('GetData',argu_list)

    def GetProjectList(self):
        """ Return a project list """
        argu_list = []
        return self.sendrequest('GetProjectList',argu_list)

    def GetJobList(self,projectname):
        """ Return joblist in a project """
        argu_list = [projectname]
        return self.sendrequest('GetJobList',argu_list)
    
    def GetRowofTable(self,table,rid):
        """ Return a record in a table """
        argu_list = [table,rid]
        return self.sendrequest('GetRowofTable',argu_list)

    
class Project:
    """ create a project object, have methods to set and get project attributes """

    def __init__(self,db):
        self.db = db

    def newProject(self,projectname):
        """ Create a project """
        argu_list = [projectname]
        return self.db.sendrequest('NewProject',argu_list)
    
    def setOwner(self,pid,owner):
        """ Set attribute owner """
        return self.db.SetData('Project',pid,'Owner',owner)
      
    def setPath(self,pid,path):
        """ Set attribute path """
        return self.db.SetData('Project',pid,'Path',path)
      
    def getProjectId(self,projectname):
        """ Get project id """
        argu_list = [projectname]
        return self.db.sendrequest('GetProjectId',argu_list)

    def getOwner(self,pid):
        """ Get attribute owner """
        return self.db.GetData('Project',pid,'Owner')

    def getPath(self,pid):
        """ Get attribute path """
        return self.db.GetData('Project',pid,'Path')

class Job:

    """ create a job object. have methods of set & get job attributes """
    
    def __init__(self,db):
        self.db = db

    def newJob(self,projectname):
        """ Create a new job """
        argu_list = [projectname]
        return self.db.sendrequest('NewJob',argu_list)
    
    def setData(self,jobid,item,value):
        """ Set job attribute """
        argu_list = [jobid,item,value]
        return self.db.sendrequest('SetJobData',argu_list)
    
    def getData(self,jobid,item):
        """ Get job attribute """
        argu_list = [jobid,item]
        return self.db.sendrequest('GetJobData',argu_list)

    def setStatus(self,jobid,status):
        """ Set attribute status """
        argu_list = ['Job',jobid,'Status',status]
        return self.db.sendrequest('SetData',argu_list)
        
    def getStatus(self,jobid):
        """ Get attribute status """
        argu_list=['Job',jobid,'Status']
        return self.db.sendrequest('GetData',argu_list)

    def setApplication(self,JobId,Application):
        """ Set attribute application """
        argu_list = ['Job',JobId,'Application',Application]
        return self.db.sendrequest('SetData',argu_list)

    def getApplication(self,JobId):
        """ Get attribute application """
        argu_list = ['Job',JobId,'Application']
        return self.db.sendrequest('GetData',argu_list)

    def setTaskname(self,jobid,taskname):
        """ Set taskname """
        argu_list = ['Job',jobid,'Taskname',taskname]
        return self.db.sendrequest('SetData',argu_list)

    def getTaskname(self,jobid):
        """ Get taskname """
        argu_list = ['Job',jobid,'Taskname']
        return self.db.sendrequest('GetData',argu_list)

    def setTitle(self,jobid,title):
        """ Set title """
        argu_list = ['Job',jobid,'Title',title]
        return self.db.sendrequest('SetData',argu_list)

    def getTitle(self,jobid):
        """ Get title """
        argu_list = ['Job',jobid,'Title']
        return self.db.sendrequest('GetData',argu_list)
    
    def setLastModified(self,jobid,time):
        """ Set lastmodified """
        argu_list = ['Job',jobid,'LastModified',time]
        return self.db.sendrequest('SetData',argu_list)

    def getLastModified(self,jobid):
        """Get lastmodified """
        argu_list = ['Job',jobid,'LastModified']
        return self.db.sendrequest('GetData',argu_list)

    def setLogFile(self,jobid,logfile):
        """ Set logfile """
        argu_list = ['Job',jobid,'LogFile',logfile]
        return self.db.sendrequest('SetData',argu_list)

    def getLogFile(self,jobid):
        """ Get logfile """
        argu_list = ['Job',jobid,'LogFile']
        return self.db.sendrequest('GetData',argu_list)

    def setControlFile(self,JobId,ControlFile):
        """ set controlfile """
        argu_list = ['Job',JobId,'ControlFile',ControlFile]
        return self.db.sendrequest('SetData',argu_list)

    def getControlFile(self,JobId):
        """ Get control file """
        argu_list = ['Job',JobId,'ControlFile']
        return self.db.sendrequest('GetData',argu_list)

    def setNotebookFile(self,JobId,NotebookFile):
        """ Set notebook """
        argu_list = ['Job',JobId,'NotebookFile',NotebookFile]
        return self.db.sendrequest('SetData',argu_list)

    def getNotebookFile(self,JobId):
        """ Get notebook """
        argu_list = ['Job',JobId,'NotebookFile']
        return self.db.sendrequest('GetData',argu_list)


class File:

    """ create a file object. have methods set & get file attributes """

    def __init__(self,db):
        self.db = db
 
    def newFile(self):
        argu_list = ['File']
        return self.db.sendrequest('NewRecord',argu_list)

    def setName(self,FileId,Name):
        argu_list = ['File',FileId,'Name',Name]
        return self.db.sendrequest('SetData',argu_list)

    def getName(self,FileId):
        argu_list = ['File',FileId,'Name']
        return self.db.sendrequest('GetData',argu_list)
    
    def setPath(self,FileId,Path):
        argu_list = ['File',FileId,'Path',Path]
        return self.db.sendrequest('SetData',argu_list)

    def getPath(self,FileId):
        argu_list = ['File',FileId,'Path']
        return self.db.sendrequest('GetData',argu_list)

    def setFormat(self,FileId,Format):
        argu_list = ['File',FileId,'Format',Format]
        return self.db.sendrequest('SetData',argu_list)

    def getFormat(self,FileId):
        argu_list = ['File',FileId,'Format']
        return self.db.sendrequest('GetData',argu_list)
   
    def setLastModified(self,FileId,LastModified):
        argu_list = ['File',FileId,'LastModified',LastModified]
        return self.db.sendrequest('SetData',argu_list)

    def getLastModified(self,FileId):
        argu_list = ['File',FileId,'LastModified']
        return self.db.sendrequest('GetData',argu_list)

    def setNote(self,FileId,Note):
        argu_list = ['File',FileId,'Note',Note]
        return self.db.sendrequest('SetData',argu_list)

    def getNote(self,FileId):
        argu_list = ['File',FileId,'Note']
        return self.db.sendrequest('GetData',argu_list)


class JobFile:
    """ create a JobFile object, have methods set & get JobFile attributes """
 
    def __init__(self,db):
        self.db = db
 
    def newJobFile(self):
        argu_list = ['JobFile']
        return self.db.sendrequest('NewRecord',argu_list)

    def setFileId(self,JobFileId,FileId):
        argu_list = ['JobFile',JobFileId,'FileId',FileId]
        return self.db.sendrequest('SetData',argu_list)

    def getFileId(self,JobFileId):
        argu_list = ['JobFile',JobFileId,'FileId']
        return self.db.sendrequest('GetData',argu_list)

    def setType(self,JobFileId,Type):
        argu_list = ['JobFile',JobFileId,'Type',Type]
        return self.db.sendrequest('SetData',argu_list)

    def getType(self,JobFileId):
        argu_list = ['JobFile',JobFileId,'Type']
        return self.db.sendrequest('GetData',argu_list)

class JobLink:
    """ create a JobLink object, have methods set & get JobLink attributes """
    
    def __init__(self,db):
        self.db = db
 
    def newJobLink(self):
        argu_list = ['JobLink']
        return self.db.sendrequest('NewRecord',argu_list)

    def setNextJobId(self,JobLinkId,NextJobId):
        argu_list = ['JobLink',JobLinkId,'NextJobId',NextJobId]
        return self.db.sendrequest('SetData',argu_list)
    
    def getNextJobId(self,JobLinkId):
        argu_list = ['JobLink',JobLinkId,'NextJobId']
        return self.db.sendrequest('GetData',argu_list)

    def setNote(self,JobLinkId,Note):
        argu_list = ['JobLink',JobLinkId,'Note',Note]
        return self.db.sendrequest('SetData',argu_list)

    def getNote(self,JobLinkId):
        argu_list = ['JobLink',JobLinkId,'Note']
        return self.db.sendrequest('GetData',argu_list)

    def setType(self,JobLinkId,Type):
        argu_list = ['JobLink',JobLinkId,'Type',Type]
        return self.db.sendrequest('SetData',argu_list)
    
    def getType(self,JobLinkId):
        argu_list = ['JobLink',JobLinkId,'Type']
        return self.db.sendrequest('GetData',argu_list)
    
