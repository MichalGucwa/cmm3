#
# reaper.py
#
# Do traceback CCP4i project history
#
# Usage:
# > python reaper.py <project> <job>
#
#Cvs_Id $Id: reaper.py,v 1.2 2008/08/12 10:48:04 pjx Exp $
#--------------------------------------------------------------

"""reaper: traceback on CCP4i project history

reaper is a set of classes and methods to implement a data
harvesting utility that uses the CCP4i project history.

The core Reaper class analyses the path to a specific job in
a specific project, where possible associating each jobs in
the path with a harvesting stage, and then suggests the set of
files that should be collected for deposition.

The ProgramNames and HarvestData classes are supporting classes.
ProgramNames provides a framework for associating 'generic'
program names with specific counterparts; HarvestData provides
a framework for associating programs and tasknames with
harvesting stages."""

import sys
import os
import exceptions
import re
import copy

# Add directories with dbCCP4i python modules
if os.path.isdir(os.path.join(os.environ["DBCCP4I_TOP"])):
    dbccp4i_path = os.path.join(os.environ["DBCCP4I_TOP"],"dbccp4i")
    sys.path.append(dbccp4i_path)
    clientapi_path = os.path.join(os.environ["DBCCP4I_TOP"],"ClientAPI")
    sys.path.append(clientapi_path)
try:
    import ccp4i
    import dbClientAPI
    import smartie
except ImportError:
    print "Unable to load one or more of the DbCCP4i modules"
    sys.exit(1)

class ProgramNames:
    """Class for looking up generic program names

    Stores regular expression patterns associated with generic names.
    Specific names are compared with regular expressions and the
    generic name corresponding to the first match is returned.

    The object holds no data on creation; it is up to the application
    to populate it with the appropriate data, by using the 'addProgram'
    method.

    The 'lookup' method can be used to obtain a generic program name
    associated with an arbitrary program name supplied by the
    application."""

    def __init__(self):
        """Initialise the ProgramNames object"""
        self.__programs = dict()
        self.__patterns = dict()

    def addProgram(self,specific_name,generic_name):
        """Add a specific program name associated with a generic name

        The 'specific_name' is treated as a regular expression
        and is compiled and associated with the supplied
        'generic_name'. Note that it is possible for any number of
        regular expressions to be associated with the same generic
        name."""
        self.__programs[specific_name] = generic_name
        self.__patterns[specific_name] = re.compile(specific_name)

    def list(self):
        """List the stored name pairs

        This prints the regular expressions and their associated
        generic names."""
        for name in self.__programs.keys():
            print str(name)+" : "+str(self.__programs[name])

    def lookup(self,name):
        """Return the generic name for the specific program name

        The supplied name is tested against the stored regular
        expressions; if a match is found then the associated
        generic name is returned. If no matches are found then
        the supplied name is returned unaltered."""
        for program in self.__programs.keys():
            if self.__patterns[program].match(name):
                return self.__programs[program]
        # Not found, return the input
        return name

class HarvestData:
    """Class for storing and retrieving harvesting information"""

    def __init__(self):
        """Initialise the HarvestData object"""
        self.__harvest_aliases = dict()
        self.__harvest_programs = dict()
        self.__harvest_tasks = dict()
        self.__harvest_stages = []

    def addHarvestStage(self,name,alias):
        """Add a new harvest stage"""
        self.__harvest_programs[name] = []
        self.__harvest_tasks[name] = []
        self.__harvest_aliases[name] = str(alias)
        self.__harvest_stages.append(name)

    def addHarvestProgram(self,name,program):
        """Add a program to a harvest stage"""
        try:
            self.__harvest_programs[name].append(program)
        except KeyError:
            print "Can't add program to "+str(name)+": stage not found"

    def addHarvestTask(self,name,task):
        """Add a task to a harvest stage"""
        try:
            self.__harvest_tasks[name].append(task)
        except KeyError:
            print "Can't add task to "+str(name)+": stage not found"

    def stages(self):
        """Return a list of the harvesting stages"""
        return copy.copy(self.__harvest_stages)

    def getProgramStage(self,program):
        """Return the harvesting stage association with a program"""
        for stage in self.stages():
            try:
                i = self.__harvest_programs[stage].index(program)
                return stage
            except ValueError: pass   # Not found
        # No associated stage
        return ""

    def getTaskStage(self,task):
        """Return the harvesting stage association with a task

        Given the name of a task (typically the job TASKNAME
        from the database) check to see if it is associated
        with a harvesting stage.

        Taskname associations are kept distinct from program
        associations because a task typically runs one or
        more programs, and can thus provide the context for
        those programs."""
        
        for stage in self.stages():
            try:
                i = self.__harvest_tasks[stage].index(task)
                return stage
            except ValueError: pass   # Not found
        # No associated stage
        return ""

    def getAlias(self,name):
        """Return the alias for a harvesting stage"""
        try:
            return self.__harvest_aliases[name]
        except KeyError:
            return ""

class Reaper:
    """Harvesting analyser class

    A Reaper object is supplied with a project and starting job id,
    from it determines the path to that job."""
    
    def __init__(self,project,initial_jobid):
        """Initialise a reaper object"""
        
        # Inputs
        self.__project = project
        self.__initial_jobid = str(initial_jobid)
        # List of jobs
        self.__joblist = []
        # Harvesting stages
        self.__harvest = HarvestData()
        self.__harvest_stage = dict()
        self.__harvest_jobs = dict()
        # Program names
        self.__programs = ProgramNames()
        # Db connection
        self.__db = None
        self.__dbconnected = False
        # Initialise the object
        self._populate()

    def __del__(self):
        """Invoked when the object is destroyed

        Closes the database connection if one is established."""

        if self.__dbconnected:
            try:
                self.__db.CloseProject(self.__project)
                self.__db.HandlerDisconnect()
            except exceptions.Exception,e:
                print "reaper: exception when closing db connection:"
                print str(e)

    def _populate(self):
        """Populate the object based on input data"""
        
        # Set up the harvesting stages and associated data
        #
        self.__harvest.addHarvestStage("dataproc","Data Processing")
        self.__harvest.addHarvestProgram("dataproc","mosflm")
        self.__harvest.addHarvestProgram("dataproc","scala")
        self.__harvest.addHarvestProgram("dataproc","truncate")
        #
        self.__harvest.addHarvestStage("ha","Heavy Atom Location")
        self.__harvest.addHarvestProgram("ha","shelxd")
        #
        self.__harvest.addHarvestStage("phasing","Experimental Phasing")
        self.__harvest.addHarvestProgram("phasing","mlphare")
        self.__harvest.addHarvestProgram("phasing","bp3")
        self.__harvest.addHarvestTask("phasing","phaser_EP")
        #
        self.__harvest.addHarvestStage("mr","Molecular Replacement")
        self.__harvest.addHarvestProgram("mr","amore")
        self.__harvest.addHarvestProgram("mr","molrep")
        self.__harvest.addHarvestProgram("mr","phaser")
        self.__harvest.addHarvestTask("mr","phaser_MR")
        self.__harvest.addHarvestTask("mr","mrbump")
        #
        self.__harvest.addHarvestStage("dm","Density Improvement")
        self.__harvest.addHarvestProgram("dm","dm")
        self.__harvest.addHarvestProgram("dm","pirate")
        #
        self.__harvest.addHarvestStage("refine","Refinement")
        self.__harvest.addHarvestProgram("refine","refmac5")
        #
        # List of program names
        self.__programs.addProgram("AMORE","amore")
        self.__programs.addProgram("cbuccaneer","buccaneer")
        self.__programs.addProgram("cpirate","pirate")
        self.__programs.addProgram("MLPHARE","mlphare")
        self.__programs.addProgram("MOLREP.*","molrep")
        self.__programs.addProgram("Refmac_5.*","refmac5")
        self.__programs.addProgram("Scala","scala")
        self.__programs.addProgram("SHELXD","shelxd")
        #
        for stage in self.__harvest.stages():
            self.__harvest_jobs[stage] = None
        # Set up a connection to the database
        try:
            dbClientAPI.DbStartHandler()
            self.__db = dbClientAPI.HandlerConnection('reaper',True)
            self.__db.OpenProject(self.__project)
            self.__dbconnected = True
        except exceptions.Exception,e:
            print "reaper: connection failed with exception:"
            print str(e)
            return None
        # Find the initial job
        try:
            self.__db.ListJobs(self.__project).index(self.__initial_jobid)
        except ValueError:
            print "reaper: job "+str(self.__initial_jobid)+" not found"
            return None
        # Acquire the job list
        self.__joblist = self.getJobList()
        # Assign jobs to harvest stages
        for jobid in self.__joblist:
            self.analyseJob(jobid)
        # Review the path
        self.analysePath()

    def getJobList(self):
        """Return the parent jobs for the initial job"""
        
        try:
            history = self.__db.GetAllParents(self.__project,self.__initial_jobid)
            # Add the current job as part of the history
            history.append(self.__initial_jobid)
        except exceptions.Exception,e:
            print "reaper: failed to get job list:"
            print str(e)
            history = []
        return self.sortJobs(history)

    def getData(self,job,item):
        """Get the requested data item associated with a job"""

        try:
            return self.__db.GetData(self.__project,job,item)
        except exceptions.Exception,e:
            print "Exception in getData (job = "+str(job)+" item = "+str(item)+")"
            print str(e)
            return ""

    def getLogfile(self,job):
        """Acquire the full path to the logfile for a job"""

        try:
            logfile = self.getData(job,"LOGFILE")
            logfile = os.path.join(self.__db.GetProjectDir(self.__project),logfile)
            #if os.path.exists(logfile): return logfile
            return logfile
        except exceptions.Exception, e:
            print "Exception in getLogfile (job = "+str(job)+")"
            print str(e)
        return ""
        
    def sortJobs(self,joblist):
        """Sort jobs into date order, newest first

        Given a list of jobs, this returns a new list with the jobs
        sorted into date order."""
        
        sorted = []
        for job in joblist:
            inserted = False
            if len(sorted) == 0:
                sorted.append(job)
            else:
                for x in range(0,len(sorted)):
                    jobx = sorted[x]
                    if int(self.getData(jobx,"DATE")) < int(self.getData(job,"DATE")):
                        sorted.insert(x,job)
                        inserted = True
                        break
                if not inserted:
                    sorted.append(job)
        return sorted

    def analyseJob(self,job):
        """Analyse a job and assign a harvest stage to it"""

        # Initialise
        self.__harvest_stage[job] = None
        
        # Acquire data
        taskname = self.getData(job,"TASKNAME")
        logfile = self.getLogfile(job)

        # Context
        context = self.__harvest.getTaskStage(taskname)

        # Analyse the log with smartie
        log = smartie.parselog(logfile)
        for i in range(0,log.nprograms()):
            try:
                prog = self.__programs.lookup(log.program(i).name)
            except AttributeError:
                # No name for the program object?
                continue
            stage = self.__harvest.getProgramStage(prog)
            if stage != "":
                self.__harvest_stage[job] = stage

        # If a stage wasn't assigned then use the context
        if not self.__harvest_stage[job] and context != "":
            self.__harvest_stage[job] = context            

    def analysePath(self):
        """Determine the steps that should be harvested from the path"""

        for job in self.__joblist:
            stage = self.__harvest_stage[job]
            try:
                if not self.__harvest_jobs[stage]:
                    # No job assigned to this stage
                    self.__harvest_jobs[stage] = job
                else:
                    jobx = self.__harvest_jobs[stage]
                    if int(self.getData(jobx,"DATE")) < int(self.getData(job,"DATE")):
                        # This is the most recent job for this stage
                        self.__harvest_jobs[stage] = job
            except KeyError:
                # Stage wasn't found
                pass

    def report(self):
        """Report the current contents of the object"""
        
        print "Project: "+str(self.__project)
        print "Job    : "+str(self.__initial_jobid)

    def reportPath(self):
        """Report the current contents and the path"""

        self.report()
        print "\nPath to this job:"
        if len(self.__joblist) > 0:
            print "__________________________________________________________________"
            print "%5s   %-15s %-25s" % ("Job","Taskname","Harvesting stage")
            print "__________________________________________________________________"
        for job in self.__joblist:
            stage = self.__harvest_stage[job]
            alias = self.__harvest.getAlias(stage)
            comment = ""
            if not alias: alias = "-"
            try:
                if job == self.__harvest_jobs[stage]:
                    comment = "<<< Harvest step"
            except KeyError:
                # Stage not found
                pass
            print "%5s   %-15s %-25s %-20s" % (str(job), \
                                              str(self.getData(job,"TASKNAME")), \
                                              str(alias), \
                                              str(comment))
        if len(self.__joblist) > 0:
            print "__________________________________________________________________"

    def reportStages(self):
        """List the stages with the assigned job number"""

        print "\nHarvest stages and jobs allocated to them:"
        print "__________________________________________________________________"
        print "Job\tHarvest stage"
        print "__________________________________________________________________"
        for stage in self.__harvest.stages():
            job = self.__harvest_jobs[stage]
            print str(job)+"\t"+str(self.__harvest.getAlias(stage))
        print "__________________________________________________________________"
        
# Main program
if __name__ == "__main__":
    print "================================="
    print "REAPER: data harvesting analyser"
    print "=================================\n"

    # Read the command line
    if len(sys.argv) == 3:
        project = sys.argv[1]
        jobid = sys.argv[2]
    else:
        print "Usage: reaper <project> <job_id>"
        sys.exit(1)

    # Create reaper object
    r = Reaper(project,jobid)
    r.reportPath()
    r.reportStages()

    # Finish
    print "reaper: finished."
    sys.exit(0)

