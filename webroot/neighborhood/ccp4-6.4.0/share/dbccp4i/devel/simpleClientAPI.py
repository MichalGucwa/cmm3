# This is an attempt to make an easier-to-use client API for
# the handler.
#
# The usage model is intended to be something like:
#
# conn = simpleClientAPI.simpleConnection("user_agent") # get a handler connection
# conn.projects() # return a list of available projects
# proj = conn.project("name") # open project "name" and return a simpleProject object
# proj.jobs() # list the jobs in the project
# job = proj.newjob() # make a new job in the project
# job.STATUS  # retrieve e.g. the STATUS of the job
# job.STATUS = "FINISHED" # set e.g. the STATUS for the job
#
import dbClientAPI

# Simple db object
class simpleConnection:
    """Class for connecting to and interacting with the database handler

    The simpleConnection class provides a wrapper to the dbClientAPI
    classes and methods, with the aim of presenting a more inituitive
    object-based interface."""
    def __init__(self,user_agent):
        self.__handler = dbClientAPI.HandlerConnection(user_agent,True)
        self.__projects = {}

    def __del__(self):
        self.close()

    def handler(self):
        """Internal: return the connection object"""
        return self.__handler

    def removeProject(self,name):
        """Internal: remove a project reference from this connection"""
        if self.__projects.has_key(name):
            del(self.__projects[name])

    def close(self):
        """Close the connection to the database handler."""
        for name in self.__projects.keys():
            del(self.__projects[name])
        self.__handler.HandlerDisconnect()

    def projects(self):
        """Return the list of projects"""
        return self.__handler.ListProjects()

    def project(self,name):
        """Open a project and return a simpleProject object

        The simpleProject class provides methods for interacting
        with a project."""
        if not self.__projects.has_key(name):
            project = simpleProject(self,name)
            self.__projects[name] = project
        return self.__projects[name]

# Simple project object
class simpleProject:
    """Class for interacting with a project database

    simpleProject instances should be generated from a call to the
    appropriate simpleConnection object."""
    def __init__(self,connection,name):
        self.__connection = connection
        self.__name = name
        self.__db = connection.handler().OpenProject(name)

    def __del__(self):
        self.__connection.handler().CloseProject(self.__name)
        self.__connection.removeProject(self.__name)

    def name(self):
        """Return the name of the project"""
        return self.__name

    def connection(self):
        """Internal: reference to the 'parent' simpleConnection object"""
        return self.__connection

    def jobs(self):
        """Return a list of the jobs in the project database"""
        # Perhaps this should actually return a list of job objects?
        return self.__connection.handler().ListJobs(self.__name)

    def newjob(self,taskname,title,status):
        """Make a new job in the project and return a simpleJob object"""
        jobid = self.__connection.handler().NewJob(self.__name)
        return self.job(self,jobid)

    def job(self,jobid):
        """Return a simpleJob object for an existing job"""
        return simpleJob(self,jobid)

    def has_job(self,jobid):
        """Check whether a job exists in a project"""
        try:
            self.jobs().index(str(jobid))
            return True
        except ValueError:
            return False

class simpleJob:
    """Class for interacting with a job in a project database

    simpleJob instances should be generated using the appropriate
    methods of a simpleProject object.

    The data items associated with a job can be queried using the
    syntax 'job.ITEM', and set using 'job.ITEM = value'."""
    def __init__(self,project,jobid):
        # Explicitly set the attributes in the dictionary
        # in order to override the __getattr__ and __setattr__
        # built-ins
        # Not very pretty and possibly difficult to maintain
        self.__dict__["_simpleJob__project"] = project
        self.__dict__["_simpleJob__jobid"] = str(jobid)

    def __repr__(self):
        """Internal: generate representation of job"""
        return "Job:"+str(self.__project.name())+":"+str(self.__jobid)

    def __getattr__(self,attr):
        """Internal: override simpleJob.attribute"""
        try:
            connection = self.connection()
            return connection.handler().GetData(self.__project.name(),
                                                self.__jobid,attr)[0]
        except:
            raise AttributeError, \
                  "Couldn't fetch "+str(attr)+" for job "+str(self.__jobid)

    def __setattr__(self,attr,value):
        """Internal: override simpleJob.attribute = value"""
        if self.__dict__.has_key(attr):
            self.__dict__[attr] = value
        else:
            try:
                connection = self.connection()
                return connection.handler().SetData(self.__project.name(),
                                                    self.__jobid,attr,value)
            except:
                raise AttributeError, \
                  "Couldn't set "+str(attr)+" for job "+str(self.__jobid)

    def connection(self):
        """Internal: return the connection object for the parent project"""
        return self.__project.connection()

    def date(self):
        """Return the date formatted as a string"""
        try:
            return dbClientAPI.ConvertTime(float(self.DATE))
        except:
            raise

    def inputfiles(self):
        """Return a list of the input files for the job"""
        connection = self.connection()
        return connection.handler().ListInputFiles(self.__project.name(),
                                                   self.__jobid)

    def outputfiles(self):
        """Return a list of the output files for the job"""
        connection = self.connection()
        return connection.handler().ListOutputFiles(self.__project.name(),
                                                    self.__jobid)

    def addinputfile(self,filen,dir=""):
        """Add an input file reference to the job"""
        connection = self.connection()
        return connection.handler().AddInputFile(self.__project.name(),
                                                 self.__jobid,filen,dir)

    def addoutputfile(self,filen,dir=""):
        """Add an output file reference to the job"""
        return connection.handler().AddOutputFile(self.__project.name(),
                                                  self.__jobid,filen,dir)

    def subjobs(self):
        """Return a list of subjobs associated with the job"""
        connection = self.connection()
        return connection.handler().ListJobs(self.__project.name(),
                                             self.__jobid)

    def subjob(self,subjobid):
        """Return a simpleJob object for an existing subjob"""
        return self.__project.job(subjobid)

    def newsubjob(self,taskname,title):
        """Make a new subjob associated with the job and return a simpleJob object"""
        connection = self.connection()
        subjobid = self.__connection.handler().AddSubJob(self.__project.name(),
                                                         self.__jobid,
                                                         taskname,title)
        return self.job(self,subjobid)
            
    def id(self):
        """Return the job number"""
        return self.__jobid
