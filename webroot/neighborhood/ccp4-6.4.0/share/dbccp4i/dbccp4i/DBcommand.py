#
#     Copyright (C) 2006
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#     
#====================================================================
# Commands for Def & SQLite backend - DBcommand.py
#
# Wanjuan Yang March 06
#
#====================================================================

#CCP4i_cvs_Id $Id: DBcommand.py,v 1.9 2008/08/12 10:48:09 pjx Exp $

######################################################################


__version__ = "$Revision: 1.9 $"

#######################################################################
# Import modules that this module depends on
#######################################################################
import xml.dom.minidom
import xml.sax.saxutils as su
import exceptions
import os

try:
    import ccp4i
    from manager import *
except exceptions.Exception,x:
    print "Not support .def backend"
    print str(x)

#----------------------------------------------------------------
#    Section 1: This section is the commands for central sql db, tables include
#    'Project', 'Job'
#----------------------------------------------------------------
def do_sql_newrecord_command(mydb,command,argu,useragent):
    """ commands for create a new record in a table """
    
    if command == 'NewRecord':
        # Generic command for creating a new record in a table 
        try:
            if len(argu) < 1:
                result = 'Argument should be: tablename [column1 value1 ...]'
                status = 'ERROR'
            else:
                table = get_argument(argu[0])
                itemlist = []
                valuelist = []
                # get other arguments
                for i in range((argu_num-1)/2):
                    item = get_argument(argu[i*2+1])
                    itemlist.append(item)
                    value = get_argument(argu[i*2+2])
                    valuelist.append(value)

                no = mydb.new_record(table,itemlist,valuelist)
                if 'DB exception: ' not in no:
                    status = 'OK'
                else:
                    status = 'ERROR'
                result = no

        except exceptions.Exception,x:
            print '# Handler message: catch exception:',str(x)
            status = 'ERROR'
            result = 'Handler exception:' + str(x)
        value = [result,status,table,no]
        return value
		    
    elif command == 'NewProject':
        # Create a new record in table 'Project'
        
        no = 0  # initial no
        try:
            if len(argu) < 1:
                result = 'Argument should be: projectname'
                status ='ERROR'
            else:
                projectname = get_argument(argu[0])
            
                #check if there is the same projectname already
                condition = 'where ProjectName = \''+projectname+'\''
                a = mydb.get_table_primary_key('Project',condition)
                if a == []:		
                    no = mydb.new_record('Project')
                    mydb.set_table_attribute('Project',no,'ProjectName',projectname)
                    result = no
                    status = 'OK'
                elif a == 'DB not open yet' or 'error' in a:
                    result = a
                    status = 'ERROR'
                else:
                    result = 'Project exists'
                    status = 'ERROR'
		
        except exceptions.Exception,x:
            print '# Handler message: catch exception when New project:',str(x)
            status = 'ERROR'
            result = 'Handler exception:' + str(x)
	    
        value = [result,status,'Project',no]
        return value

    elif command == 'NewJob':
        # Create a new record in table 'Job' 
        
        no = 0 # initial no
        try:
            if len(argu) < 1:
                result = 'Arugment should be: projectname'
                status = 'ERROR'
            else:
                projectname = get_argument(argu[0])
                condition = 'where ProjectName = \''+projectname+'\''
                pid = mydb.get_table_primary_key('Project',condition)
	    
                if pid !=  'DB not open yet' and 'error' not in pid:		
                    no = mydb.new_record('Job')
                        
                    mydb.set_table_attribute('Job',no,'ProjectId',pid)
                    result = no
                    status = 'OK'
                else:
                    result = 'no such project'
                    status = 'ERROR'
	    
        except exceptions.Exception,x:
            print '# Handler message: catch exception when New job:',str(x)
            status = 'ERROR'
            result = 'Handler exception:' + str(x)
	    
        value = [result,status,'Job',no]
        return value
    
    else:
        status = 'FAILED'
        result = 'No implement yet'
        response = response_wrapper(status,result,id)
        return response
    
def do_sql_setdata_command(mydb,command,argu,useragent):
    """ commands for updating record in a table """
    
    if command == 'SetJobData':
        # update a job record in table 'Job'
        
        try:
            argu_num = len(argu)
            if argu_num < 3:
                result = 'Arguments should be : jobid item value [item1 value1 ...]'
                status = 'ERROR'
            else:
                result = []
                jobid = get_argument(argu[0])
                for i in range((argu_num-1)/2):
                    item = get_argument(argu[i*2+1])
                    value = get_argument(argu[i*2+2])
            
                    result.append(mydb.set_table_attribute('Job',jobid,item,value)) 
                    #check the result and assign status 
                for value in result:
                    if False in value:
                        status = 'ERROR'
                        break
                else:
                    status = 'OK'

        except exceptions.Exception,x:
            print '# Handler message: catch exception when set data:',str(x)
            status = 'ERROR'
            result = 'Handler exception: '+ str(x)
	
        value = [result,status,'Job',jobid]
        return value

    elif command == 'SetData':
        # update record in a given table
        
        try:
            argu_num = len(argu)
            if argu_num < 4:
                result = 'Arguments should be: table recordid attribute value [attribute1 value2...]'
                status ='ERROR'
            else:
                table = get_argument(argu[0])
                id = get_argument(argu[1])
                result = []
                for i in range((argu_num-2)/2):
                    attribute = get_argument(argu[i*2+2])
                    value = get_argument(argu[i*2+3])
                    result.append(mydb.set_table_attribute(table,id,attribute,value))
                #check the result and assign status 
                for value in result:
                    if False in value:
                        status = 'ERROR'
                        break
                else:
                    status = 'OK'

        except exceptions.Exception,x:
            print '# Handler message: catch exception:',str(x)
            status = 'ERROR'
            result = 'Handler exception:' + str(x)
            
        value = [result,status,table,id]
        return value
    
    else:
        status = 'FAILED'
        result = 'No implement yet'
        response = response_wrapper(status,result,id)
        return response
       
def do_sql_command(mydb,command,argu,id,useragent):
    """ retrieve data from a table """
    
    if command == 'GetJobData':
        # get a job attribute value in the table 'Job'
        
        try:
            argu_num = len(argu)
            if argu_num < 2:
                result = 'Arguments should be: jobid item [item1 ...]'
                status = 'ERROR'
            else:
                jobid = get_argument(argu[0])
                result = []

                for i in range(argu_num-1):
                    item = get_argument(argu[i+1])
                    result.append(mydb.get_table_attribute('Job',jobid,item))

                # check the result and assign the status
                for value in result: 
                    if 'error' in value or value == 'DB not open yet':
                        status = 'ERROR'
                        break
                else:
                    status = 'ERROR'

        except exceptions.Exception,x:
            print '# Handler message: catch exception when get data:',str(x)
            status = 'ERROR'
            result = 'Handler exception:' + str(x)
            
        response = response_wrapper(status,result,id)
        return response    

    elif command == 'GetProjectList':
        # Get a list of projects
        try:
            result = mydb.GetProjectList()
            if result != 'error' and result !='DB not open yet':
                status = 'OK'
            else:
                status = 'ERROR'

        except exceptions.Exception,x:
            print '# Handler message: catch exception when set data:',str(x)
            status = 'ERROR'
            result = 'Handler exception:' + str(x)
            
        response = response_wrapper(status,result,id)
        return response
        
    elif command == 'GetJobList':
        # get a list of jobs.
        try:
            if len(argu) < 1:
                result = 'Argument should be: projectname'
                status = 'ERROR'
            else:
                projectname = get_argument(argu[0])
                projectid = mydb.GetProjectId(projectname)
                if projectid != 'error' and projectid !='DB not open yet':
		
                    result = mydb.GetJobList(projectid)
                    if result != 'error' and result !='DB not open yet':
                        status = 'OK'
                    else:
                        status = 'ERROR'

                else:
                    result = projectid
                    status = 'ERROR'
			
        except exceptions.Exception,x:
            print '# Handler message: catch exception:',str(x)
            status = 'ERROR'
            result = 'Handler exception:' + str(x)
            
        response = response_wrapper(status,result,id)
        return response
    
    elif command == 'GetTableSchema':
        # get attributes of a table
        try:
            if len(argu) < 1:
                result = 'Argument should be: tablename'
                status = 'ERROR'
            else:
                table = get_argument(argu[0])
                result = mydb.GetTableSchema(table)
	
                if result !='no such table':
                    status = 'OK'
                else:
                    status = 'ERROR'
			
        except exceptions.Exception,x:
            print '# Handler message: catch exception:',str(x)
            status = 'ERROR'
            result = 'Handler exception: '+str(x)
            
        response = response_wrapper(status,result,id)
        return response 
        
    elif command == 'GetRowofTable':
        # get all of the records in a table
        try:
            if len(argu) < 2:
                result = 'Argument should be: table recordid'
                status = 'ERROR'
            else:
                table = get_argument(argu[0])
                tid = get_argument(argu[1])
                result = mydb.GetRowofTable(table,tid)
	
                if result !='DB not open' or 'error' not in result:
                    status = 'OK'
                else:
                    status = 'ERROR'
			
        except exceptions.Exception,x:
            print '# Handler message: catch exception:',str(x)
            status = 'ERROR'
            result = 'Handler exception: '+str(x)
            
        response = response_wrapper(status,result,id)
        return response
    
    elif command == 'GetData':
        # Generic command to get data from a given table.
        try:
            argu_num = len(argu)
            if argu_num < 3:
                result = 'Arguments should be: tablename recordid attribute [attribute2 ...]'
                status = 'ERROR'
            else:
                table = get_argument(argu[0])
                id = get_argument(argu[1])
                result = []

                for i in range(argu_num-2):
                    attribute = get_argument(argu[i+2])
		
                    result.append(mydb.get_table_attribute(table,id,attribute))
            
                if result != 'error' and result !='DB not open yet' and result != []:
                    status = 'OK'
                else:
                    status = 'ERROR'

        except exceptions.Exception,x:
            print '# Handler message: catch exception when get data:',str(x)
            status = 'ERROR'
            result = 'Handler exception: ' + str(x)
            
        response = response_wrapper(status,result,id)
	    
        return response    
    
    elif command == 'GetProjectId':
        # Given a project name, get the project id.
        try:
            if len(argu) < 1:
                result = 'Argument should be: projectname'
                status = 'ERROR'
            else:
                projectname = get_argument(argu[0])
                result = mydb.GetProjectId(projectname)
                if result != 'error' and result !='DB not open yet' and result != []:
                    status = 'OK'
                else:
                    status = 'ERROR'

        except exceptions.Exception,x:
            print '# Handler message: catch exception when set data:',str(x)
            status = 'ERROR'
            result = 'Handler exception: '+str(x)
            
        response = response_wrapper(status,result,id)
        return response    
    
    elif command == 'CloseDB':
        # close the central SQLite db
        try:
            result = mydb.CloseDB()
            
        except exceptions.Exception,x:
            print '# Handler message: catch exception when close DB:',str(x)
            status = 'ERROR'
            result = 'Handler exception: '+str(x)

        if result == True:
            status = 'OK'
        else:
            status = 'ERROR'
                
        response = response_wrapper(status,result,id)

        return response

    else:
        status = 'FAILED'
        result = 'No implement yet'
        response = response_wrapper(status,result,id)
        return response

#-------------------------------------------------------------------
# Section 2: This section is the commands for def file
#-------------------------------------------------------------------
def do_def_readdir_command(command,argu,id):
    """ commands for reading directories.def data """
    
    if command == 'GetDataDir':
        # Return the directory corresponding to a def dir name
        try:
            if len(argu) < 1:
                result = 'Arguments should be: def_dir'
                status = 'ERROR'
            else:
                def_dir = get_argument(argu[0])
                result = ProjectManager().directory.defdir(def_dir)
                if result != "":
                    status = 'OK'
                else:
                    status ='ERROR'
        except exceptions.Exception,x:
            result = 'Handler exception: '+str(x)
            status ='ERROR'

        response = response_wrapper(status,result,id)
        return response

    elif command == 'GetProjectDir':
        # Return the directory corresponding to a project name
        try:
            if len(argu) < 1:
                result = 'Arguments should be: projectname'
                status = 'ERROR'
            else:
                projectname = get_argument(argu[0])
                result = ProjectManager().directory.projectdir(projectname)
                if result != "":
                    status = 'OK'
                else:
                    status ='ERROR'
        except exceptions.Exception,x:
            result = 'Handler exception: '+str(x)
            status ='ERROR'
               
        response = response_wrapper(status,result,id)
        return response
         
    elif command == 'ListDataDirs':
        # Return a list of the user's default directories
        try:
            result = ProjectManager().directory.listdefdirs()
            status = 'OK'
        except exceptions.Exception,x:
            result = 'Handler exception: '+str(x)
            status ='ERROR'

        response = response_wrapper(status,result,id)
        return response

    elif command == 'GetNProjects':
        # Return the number of projects
        try:
            result = ProjectManager().directory.n_projects()
            status = 'OK'
                    
        except exceptions.Exception,x:
            result = 'Handler exception: '+str(x)
            status = 'ERROR'

        response = response_wrapper(status,result,id)
        return response

    elif command == 'ListProjects':
        # Return a list of the user's projects
        try:
            result = ProjectManager().directory.listprojects()
            status = 'OK'
                    
        except exceptions.Exception,x:
            result = 'Handler exception: '+str(x)
            status = 'ERROR'

        response = response_wrapper(status,result,id)
        return response

    elif command == 'GetProjectDBDir':
        # Return the database directory for the specified project
        try:
            projectname = get_argument(argu[0])
            result = ProjectManager().directory.projectdb(projectname)
            status = 'OK'

        except exceptions.Exception,x:
            result = 'Handler exception: '+str(x)
            status = 'ERROR'

        response = response_wrapper(status,result,id)
        return response

    elif command == 'IsProjectDir':
        # Return the project with the same directory path as that supplied
        try:
            projectdir = get_argument(argu[0])
            result = ProjectManager().directory.isprojectdir(projectdir)
            status = 'OK'

        except exceptions.Exception,x:
            result = 'Handler exception: '+str(x)
            status = 'ERROR'

        response = response_wrapper(status,result,id)
        return response

    elif command == 'IsDataDir':
        # Return the data dir with the same directory path as that supplied
        try:
            datadir = get_argument(argu[0])
            # Nb the name of this method is not a typo
            result = ProjectManager().directory.isdefdirdir(datadir)
            status = 'OK'

        except exceptions.Exception,x:
            result = 'Handler exception: '+str(x)
            status = 'ERROR'

        response = response_wrapper(status,result,id)
        return response

    elif command == 'GetDirectoriesData':
        # Fetch arbitrary data about projects and datadirs
        # Intended to allow clients to retrieve a lot of data in
        # a single request
        # Syntax: GetDirectoriesData <keyword> <alias> [<keyword> <alias> ...]
        # For each keyword-alias pair, return the corresponding value
        # Keywords can be: ProjectDir, ProjectDBDir and DataDir
        try:
            result = []
            alias = ''
            status = 'OK'
            read_alias = False
            for i in range(0,len(argu)):
                arg = get_argument(argu[i])
                if not read_alias:
                    # Acquire the keyword
                    keyword = arg
                    # Flip the flag so the next arg is an alias
                    read_alias = True
                else:
                    # Acquire the alias
                    alias = arg
                    # Acquire the data value
                    if keyword == 'ProjectDir':
                        value = ProjectManager().directory.projectdir(alias)
                    elif keyword == 'ProjectDBDir':
                        value = ProjectManager().directory.projectdb(alias)
                    elif keyword == 'DataDir':
                        value = ProjectManager().directory.defdir(alias)
                    else:
                        value = ''
                    # Append to the result list
                    result.append(value)
                    # Flip the flag so the next arg is a keyword
                    read_alias = False
            # If we're still waiting for an alias after
            # running out of arguments then append a blank
            # value
            if read_alias: result.append('')

        except exceptions.Exception,x:
            result = 'Handler exception: '+str(x)
            status = 'ERROR'

        response = response_wrapper(status,result,id)
        return response

    else:
        status = 'FAILED'
        result = 'No implement yet'
        response = response_wrapper(status,result,id)
        return response
    
#----------------------------------------------------------------------
#  Section 3: This section is the commands for writing data in database.def
#-----------------------------------------------------------------------

def process_writedb_command(p,command,argu,id,useragent,client):        
    """ process the commands for writing data in database.def file """                   
    if command == 'DbNewJob':
        # create a new job in the project
        try:
            argu_num = len(argu)
            if argu_num < 1:
                result = ''
                status = 'ERROR'
            else:
                # Collect arguments
                projectname = get_argument(argu[0])
                job_taskname = ""
                if argu_num > 1:
                    # Taskname also specified
                    job_taskname = get_argument(argu[1])
                job_status = ""
                if argu_num > 2:
                    # Status specified
                    job_status = get_argument(argu[2])
                job_title = ""
                if argu_num > 3:
                    # Title specified
                    job_title = get_argument(argu[3])

                # Create the new job
                jobid = p.fileobj.newjob(taskname=job_taskname,
                                          status=job_status,
                                          title=job_title)
                if jobid == False or jobid == -1:
                    status = 'ERROR'
                else:
                    # Successfully created a new job
                    result = jobid
                    # Store user agent name, if possible
                    if p.fileobj.itemexists(jobid,"USER_AGENT"):
                        p.fileobj.setdata(jobid,"USER_AGENT",useragent)
                    # new record in def ok, then add record in sqldb
                    if p.HasSQLdb():
                        for sqldb in client.GetSQLdbs():
                            if sqldb.GetDBName() == projectname:
                                jobid = sqldb.new_record("Jobs")
                                break
                        if jobid != False:
                            # insert a job number in the record
                            result2 = sqldb.set_table_attribute("Jobs",
                                                                jobid,
                                                                "JobNumber",
                                                                result)
                            if result2 != False:
                                status = 'OK'
                            else:
                                status = 'ERROR'
                                result = 'cannot enter record in SQLdb'
                        else:
                            status = 'ERROR'
                    else:
                        status = 'OK'
               
        except exceptions.Exception,e:
            report_ignored_exception("process_writedb_command",
                                     "DbNewJob",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)

        response = response_wrapper(status,result,id)
        message = ""
            
        if status =='OK':
            message =  broadcast_wrapper("Update "+projectname+" "+str(result),
                                         projectname,str(result),
                                         "DbNewJob",useragent)
    
        return [response,message]

    elif command == 'DbDeleteJob':
        # Remove an existing job record from the project.
        try:
            if len(argu) < 2:
                result = 'Arguments should be: projectname jobid'
                status = 'ERROR'
            else:
                # get parameter
                projectname = get_argument(argu[0])
                jobid = get_argument(argu[1])
                result = p.fileobj.deletejob(jobid)

        except exceptions.Exception,x:
            report_ignored_exception("process_writedb_command",
                                     "DbDeleteJob",e,argu)
            result = 'Handler exception: '+str(x)
                       
        if result == True:
            status = 'OK'
        else:
            status = 'ERROR'
                
        response = response_wrapper(status,result,id)
        message = ""
            
        if status == 'OK':
            message = broadcast_wrapper("Update "+projectname+" "+jobid,
                                        projectname,jobid,
                                        "DbDeleteJob",useragent)

        return [response,message]

    elif command == 'DbSetData':
        # Set the value of a data item for the specified job.
        try:
            argu_num = len(argu)
            if argu_num < 4:
                # Usage error
                result = 'Arguments should be: projectname jobid item value [item1 value1 ...]'
                status = 'ERROR'
            else:
                # Get principal argument values
                projectname = get_argument(argu[0])
                jobid = get_argument(argu[1])
                if p.fileobj.hasjob(jobid):
                    # The job exists - loop over items and set
                    for i in range((argu_num-1)/2):
                        item = get_argument(argu[2*i+2])
                        value = get_argument(argu[2*i+3])
                        try:
                            result = p.fileobj.setdata(jobid,item,value)
                        except IndexError,ex:
                            # Raised if item doesn't exist
                            result = str(ex)
                            pass
                else:
                    # No such job - report error
                    status = 'ERROR'
                    result = 'Job '+str(jobid)+' not found in project'
                    
        except exceptions.Exception,e:
            report_ignored_exception("process_writedb_command",
                                     "DbSetData",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)
                
        if result == True:
            status = 'OK'
        else:
            status = 'ERROR'
                       
        response = response_wrapper(status,result,id)
        message = ""
            
        if status == 'OK':
            message = broadcast_wrapper("Update "+projectname+" "+jobid,
                                        projectname,jobid,
                                        "DbSetData",useragent)

        return [response,message]
         
    elif command == 'Updatetime':
        # Update the time of the job to be the current time.
        try:
            # get parameter
            if len(argu) < 2:
                result = 'Arguments should be: projectname jobid'
                status = 'ERROR'
            else:
                projectname =  get_argument(argu[0])
                jobid = get_argument(argu[1])
                         
                result = p.fileobj.updatetime(jobid)
                           
        except exceptions.Exception,e:
            report_ignored_exception("process_writedb_command",
                                     "Updatetime",e,argu)
            result = 'Handler exception: '+str(e)
            
        if result == True:
            status = 'OK'
        else:
            status = 'ERROR'
               
        response = response_wrapper(status,result,id)
        message = ""
            
        return [response,message]

    elif command == 'AddInputFile':
        # Add a file to the list of input files for a job.
        try:
            if len(argu) < 3:
                result = 'Arguments should be: projectname jobid fname (alias) '
                status = 'ERROR'
            else:
        
                # get parameter
                projectname =  get_argument(argu[0])
                jobid = get_argument(argu[1])
                fname = get_argument(argu[2])
                if len(argu) == 4:
                    if argu[3].hasChildNodes():
                        alias = get_argument(argu[3])
                    else:
                        alias = ""
                else:
                    alias = ""
                    
                result = p.fileobj.addinputfile(jobid,ProjectManager().directory,fname,alias)
             
        except exceptions.Exception,x:
            report_ignored_exception("process_writedb_command",
                                     "AddInputFile",x,argu)
            result = 'Handler exception: '+str(x)
          
        if result == True:
            status = 'OK'
        else:
            status = 'ERROR'
                
        response = response_wrapper(status,result,id)
        message = ""
            
        if status == 'OK':
            message = broadcast_wrapper("Update "+projectname+" "+jobid,
                                        projectname,jobid,
                                        "AddInputFile",useragent)

        return [response,message]

    elif command == 'AddOutputFile':
        # Add a file to the list of output files for a job.
        try:
            if len(argu) < 3:
                # Usage error
                result = 'Arguments should be: projectname jobid fname (alias) '
                status = 'ERROR'
            else:
                # get parameters
                projectname =  get_argument(argu[0])
                jobid = get_argument(argu[1])
                fname = get_argument(argu[2])
                if len(argu) == 4:
                    if argu[3].hasChildNodes():
                        alias = get_argument(argu[3])
                    else:
                        alias = ""
        
                else:
                    alias = ""
                if p.fileobj.hasjob(jobid):
                    # The specified job exists in the project
                    result = p.fileobj.addoutputfile(jobid,
                                                     ProjectManager().directory,
                                                     fname,alias)
                else:
                    # Job not found
                    status = 'ERROR'
                    result = 'Job '+str(jobid)+' not found in project'

        except exceptions.Exception,x:
            report_ignored_exception("process_writedb_command",
                                     "AddOutputFile",x,argu)
            result = 'Handler exception: '+str(x)
             
        if result == True:
            status = 'OK'
        else:
            status = 'ERROR'
                
        response = response_wrapper(status,result,id)
        message = ""
            
        if status == 'OK':
            message = broadcast_wrapper("Update "+projectname+" "+jobid,
                                        projectname,jobid,
                                        "AddOutputFile",useragent)

        return [response,message]

    elif command == 'AddSubJob':
        # Add a subjob to a job in the project database.
        try:
            if len(argu) < 4:
                result = 'Arguments should be: projectname jobid taskname title'
                status = 'ERROR'
            else:
                # get parameter
                projectname =  get_argument(argu[0])
                jobid = get_argument(argu[1])
                taskname = get_argument(argu[2])
                title = get_argument(argu[3])
                
                subjobid = p.fileobj.addsubjob(jobid,taskname,title)
                               
                if subjobid == False or subjobid == -1:
                    status = 'ERROR'
                else:
                    # Successfully created a new subjob
                    result = subjobid
                    # Store user agent name, if possible
                    if p.fileobj.itemexists(subjobid,"USER_AGENT"):
                        p.fileobj.setdata(subjobid,"USER_AGENT",useragent)
                    # Add record in sqldb   
                    if p.HasSQLdb():
                        for sqldb in client.GetSQLdbs():
                            if sqldb.GetDBName() == projectname:
                                tid = sqldb.new_record("Jobs")
                                break
                        if tid != False:
                            # insert a job number in the record
                            result2 = sqldb.set_table_attribute("Jobs",tid,
                                                                "JobNumber",subjobid)
                            if result2 != False:
                                status = 'OK'
                            else:
                                status = 'ERROR'
                                result = 'cannot enter record in SQLdb'
                        else:
                            status = 'ERROR'
                    else:
                        status = 'OK'
                        
        except exceptions.Exception,x:
            report_ignored_exception("process_writedb_command",
                                     "AddSubJob",x,argu)
            result = 'Handler exception: '+str(x)
            status = 'ERROR'
                
        response = response_wrapper(status,result,id)
        message = ""

             
        if status == 'OK':
            message = broadcast_wrapper("Update "+projectname+" "+jobid,
                                        projectname,subjobid,
                                        "AddSubJob",useragent)

        return [response,message]
    
    else:
        status = 'FAILED'
        result = 'No implement yet'
        response = response_wrapper(status,result,id)
        return response


def do_def_readdb_command(projectobj,command,argu,id):
    """ process commands for reading data from database.def file """
    
    if command == 'HasSQLdb':
        # check if the project has a SQLite db backend 
        try:
            if len(argu) < 1:
                result = 'Arguments should be: projectname'
                status = 'ERROR'
            else:
                result = projectobj.HasSQLdb()
                status = 'OK'
                
        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "HasSQLdb",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)
               
        response = response_wrapper(status,result,id)

        return response
    
    elif command == 'GetNJOB':
        # Return the value of the NJOBS data item.
        try:
            # call db API
            result = projectobj.fileobj.njobs()
            if result != -1:
                status = 'OK'
            else:
                status ='ERROR'
                result = 'data not loaded'
                   
        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "GetNJOB",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)
                          
        response = response_wrapper(status,result,id)
        return response
   
    elif command == 'DbGetData':
        # Retrieve the value of a data item stored for a job.
        try:
            # get parameter
            argu_num = len(argu)
            if argu_num < 3:
                # Usage error
                result = 'Arguments should be: projectname jobid item [ item2...]'
                status = 'ERROR'
            else:
                jobid = get_argument(argu[1])
                if projectobj.fileobj.hasjob(jobid):
                    # The job exists - loop over items and acquire
                    # value for each
                    result = []
                    for i in range(argu_num-2):
                        item = get_argument(argu[i+2])
                        # call db API
                        try:
                            result.append(projectobj.fileobj.getdata(jobid,item))
                        except IndexError:
                            # Raised if the item doesn't exist
                            # In this case the entire request fails
                            status = 'ERROR'
                            result = 'Item '+str(item)+' not in database'
                            break
                        # If no errors occurred then everything worked
                        status = 'OK'
                    # If only a single item was requested
                    # then convert the list
                    if len(result) == 1:
                        result = result[0]
                else:
                    # No such job - report error
                    status = 'ERROR'
                    result = 'Job '+str(jobid)+' not found in project'
                
        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "DbGetData",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)

        response = response_wrapper(status,result,id)

        return response

    elif command == 'GetFiles':
        # Return a list of files for a job.
        try:
            # get parameter
            argu_num = len(argu)
            if argu_num < 3:
                result = 'Arguments should be: projectname jobid ftype'
                ststus = 'ERROR'
            else:
                jobid = get_argument(argu[1])
                ftype = get_argument(argu[2])

                # call db API
                result = projectobj.fileobj.listfiles(jobid,ftype,ProjectManager().directory)
                status = 'OK'
                       
        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "GetFiles",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)
               
        response = response_wrapper(status,result,id)

        return response

    elif command == 'ListInputFiles':
        # Return a list of input files for a job.
        try:
            # get parameter
            argu_num = len(argu)
            if argu_num < 2:
                result = 'Arguments should be: projectname jobid'
                ststus = 'ERROR'
            else:
                jobid = get_argument(argu[1])

                # call db API
                result = projectobj.fileobj.listinputfiles(jobid,ProjectManager().directory)
                status = 'OK'
                       
        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "ListInputFiles",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)
               
        response = response_wrapper(status,result,id)

        return response
       
    elif command == 'ListOutputFiles':
        # Return a list of output files for a job.
        try:
            # get parameter
            argu_num = len(argu)
            if argu_num < 2:
                result = 'Arguments should be: projectname jobid'
                ststus = 'ERROR'
            else:
                jobid = get_argument(argu[1])
                
                # call db API
                result = projectobj.fileobj.listoutputfiles(jobid,ProjectManager().directory)
                status = 'OK'
                       
        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "ListOutputFiles",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)
               
        response = response_wrapper(status,result,id)

        return response
       
    elif command == 'DbItemExists':
        # Check for the existence of a data item for a particular job.
        try:
            # get parameter
            if len(argu) < 3:
                result = 'Arguments should be: projectname jobid item'
                status = 'ERROR'
            else:
                jobid = get_argument(argu[1])
                item = get_argument(argu[2])
                # call db API
                try:
                    result = projectobj.fileobj.itemexists(jobid,item)
                except ValueError,e:
                    result = str(e)
                    status = 'ERROR'
           
        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "DbItemExists",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)

        if result == True:
               status = 'OK'
        else:
               status = 'ERROR'
               
        response = response_wrapper(status,result,id)

        return response
    
    elif command == 'DbSelectJobs':
        # Retrieve a list of jobs based on some selection criterion.
        try:
            # get parameter
            if len(argu) < 3:
                result = 'Arguments should be: projectname item pattern'
                status = 'ERROR'
            else:
                item = get_argument(argu[1])
                pattern = get_argument(argu[2])
                # call db API
                result = projectobj.fileobj.selectjobs(item,pattern)
                status = 'OK'
                
        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "DbSelectJobs",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)

        response = response_wrapper(status,result,id)
        return response

    elif command == 'ListJobs':
        # Return the list of all jobs in the project.
        try:
            argu_num = len(argu)
            if argu_num < 1:
                result = 'Arguments should be: projectname [jobid]'
                status = 'ERROR'
            elif argu_num == 1:
                # call db API
                if projectobj.fileobj.isreadable():
                    result = projectobj.fileobj.listjobs()
                    status = 'OK'
                else:
                    result = 'Project is not readable'
                    status = 'ERROR'
                    
            else:   
                # get jobid  
                jobid = get_argument(argu[1])
                # call db API
                if projectobj.fileobj.isreadable():
                    result = projectobj.fileobj.listjobs(jobid)
                    status = 'OK'
                else:
                    result = 'Project is not readable'
                    status ='ERROR'
	   
        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "ListJobs",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)

        response = response_wrapper(status,result,id)
        return response 

    elif command == 'GetDbItems':
        # Return a list of the core data items stored for all jobs.
        try:
            # call db API
            result = projectobj.fileobj.getDbItems()
            status = 'OK'
               
        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "GetDbItems",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)

        response = response_wrapper(status,result,id)
        return response 
           
    elif command == 'DbReturnJobs':
        # Return a list of formatted strings populated with job data.
        try:               
            if len(argu) < 4:
                result = 'Arguments should be: projectname joblist itemlist formatlist'
                status = 'ERROR'
            else:
                joblist = get_argument_list(argu[1])

                itemlist = get_argument_list(argu[2])
                   
                formatlist = get_argument_list(argu[3])
            
                result = projectobj.fileobj.describe(joblist,itemlist,formatlist)
                   
                status = 'OK'

                # If only a single record was returned
                # then convert the list to a scalar
                if len(result) == 1:
                    result = result[0]
                
        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "DbReturnJobs",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)

        response = response_wrapper(status,result,id)
           
        return response

    elif command == 'DbGetListofRecords':
        # Retrieve a list of job records 
        try:
            if len(argu) < 3:
                # Usage error
                result = 'Arguments should be: projectname joblist itemlist'
                status = 'ERROR'
            else:
                joblist = get_argument_list(argu[1])      
             
                itemlist = get_argument_list(argu[2])
                result = [] # store a list of records

                if joblist != [] and itemlist != []:
                    status = 'OK'
                    for i in joblist:
                        if projectobj.fileobj.hasjob(i):
                            # The job exists
                            record = [] # store a single record
                            for j in itemlist:
                                try:
                                    record.append(projectobj.fileobj.getdata(i,j))
                                except IndexError:
                                    # Raised if the item doesn't exist
                                    # Abort the entire request
                                    status = 'ERROR'
                                    result = 'Item '+str(j)+' not in database'
                                    break
                            # Check for errors
                            if status == 'ERROR':
                                break
                        else:
                            # The job doesn't exist
                            # Don't raise an error, populate with blanks
                            record = []
                            for j in itemlist: record.append('')
                        # Append record to the result
                        result.append(record)
                        
                else:
                    # No jobs and/or items were requested
                    result = 'Job ids or items were not specified'
                    status = 'ERROR'
        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "DbGetListofRecords",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)

        # Return response for DbGetListOfRecords
        response = response_wrapper(status,result,id)
        return response
   
    elif command == 'GetNextJobList':
        #  Return a list of job ids corresponding
        # to the "children" jobs of the specified id
        try:
            if len(argu) < 2:
                result = 'Arguments should be: projectname job'
                status = 'ERROR'
            else:
                job = get_argument(argu[1])
	       
                dbhistory = ccp4i.extendedhistory(projectobj.fileobj,ProjectManager().directory)
	       
                dbhistory.construct()
               
                result = dbhistory.childrenof(job)
                status = 'OK'
	       
        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "GetNextJobList",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)

        response = response_wrapper(status,result,id)
           
        return response

    elif command == 'GetAllFileLinks':
        # Return all the links between jobs for a project
        try:	       
            dbhistory = ccp4i.extendedhistory(projectobj.fileobj,ProjectManager().directory)
            dbhistory.construct()
            joblist = projectobj.fileobj.listjobs()
            historylink = []
            for job in joblist:
                nextjobs = dbhistory.childrenof(job)
                for child in nextjobs:
                    alink = [job,child]
                    historylink.append(alink)

            result = historylink
            status = 'OK'
                
        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "GetAllFileLinks",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)

        response = response_wrapper(status,result,id)
           
        return response
          
    elif command == 'GetFileLinks':
        # Return the links between the given job ids.
        try:
            if len(argu) < 2:
                result = 'Arguments should be: projectname joblist'
                status = 'ERROR'
            else:
                # Create a new history object
                dbhistory = ccp4i.extendedhistory(projectobj.fileobj,
                                                  ProjectManager().directory)
                dbhistory.construct()
                # Loop over job ids and acquire links for each
                joblist = get_argument_list(argu[1])
                if joblist != []:
                    historylink = []
                    for job in joblist:
                        try:
                            nextjobs = dbhistory.childrenof(job)
                            for child in nextjobs:
                                alink = [job,child]
                                historylink.append(alink)
                        except IndexError:
                            # Raised if job is not found - ignore
                            pass

                    result = historylink
                    status = 'OK'
                else:
                    result = []
                    status ='OK'
                    
        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "GetFileLinks",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)

        response = response_wrapper(status,result,id)
           
        return response

    elif command == 'GetAllChildren':
        # Return all the jobs that are descendents of a particular job.
        try:
            if len(argu) < 2:
                result = 'Arguments should be: projectname jobid'
                status = 'ERROR'
            else:
                dbhistory = ccp4i.extendedhistory(projectobj.fileobj,ProjectManager().directory)
                dbhistory.construct()
                jobid = get_argument(argu[1])
               
                result = dbhistory.allchildrenof(jobid)

                status = 'OK'

        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "GetAllChildren",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)

        response = response_wrapper(status,result,id)
           
        return response
       
    elif command == 'GetAllParents':
        # Return all the jobs that are antecedents of a particular job.
        try:
            if len(argu) < 2:
                result = 'Arguments should be: projectname jobid'
                status = 'ERROR'
            else:
                dbhistory = ccp4i.extendedhistory(projectobj.fileobj,ProjectManager().directory)
                dbhistory.construct()
                jobid = get_argument(argu[1])
               
                result = dbhistory.allparentsof(jobid)

                status = 'OK'

        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "GetAllParents",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)

        response = response_wrapper(status,result,id)
           
        return response

    elif command == 'GetChildren':
        # Return the immediate children of a given job.
        try:
            if len(argu) < 2:
                result = 'Arguments should be: projectname jobid'
                status = 'ERROR'
            else:
                dbhistory = ccp4i.extendedhistory(projectobj.fileobj,ProjectManager().directory)
                dbhistory.construct()
                jobid = get_argument(argu[1])
                
                result = dbhistory.childrenof(jobid)

                status = 'OK'

        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "GetChildren",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)

        response = response_wrapper(status,result,id)
           
        return response
       
    elif command == 'GetParents':
        # Return the immediate parents of a given job.
        try:
            if len(argu) < 2:
                result = 'Arguments should be: projectname jobid'
                status = 'ERROR'
            else:
                dbhistory = ccp4i.extendedhistory(projectobj.fileobj,ProjectManager().directory)
                dbhistory.construct()
                jobid = get_argument(argu[1])
                
                result = dbhistory.parentsof(jobid)

                status = 'OK'

        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "GetParents",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)

        response = response_wrapper(status,result,id)
           
        return response

    elif command == 'GetAllParentsChildren':
        # Return all the jobs that has direct or indirect link with the given job.
        try:
            if len(argu) < 2:
                result = 'Arguments should be: projectname jobid'
                status = 'ERROR'
            else:
                dbhistory = ccp4i.extendedhistory(projectobj.fileobj,ProjectManager().directory)
                dbhistory.construct()
                jobid = get_argument(argu[1])
               
                result1 = dbhistory.allparentsof(jobid)
                result2 = dbhistory.allchildrenof(jobid)
                result = result1 + result2
                
                status = 'OK'

        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "GetAllParentsChildren",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)

        response = response_wrapper(status,result,id)
           
        return response
       
    elif command == 'GetNotebook':
        # Return the note book name with the path.
        try:
            if len(argu) < 2:
                result = 'Arguments should be: projectname jobid'
                status = 'ERROR'
            else:
                dir = projectobj.fileobj.getDbdir()
                jobid = get_argument(argu[1])
                notebookname = jobid + "_notebook.txt"
                notebook = os.path.join(dir,notebookname)
               
                if os.path.exists(notebook):
                    result = notebook
                    status = 'OK'
                else:
                    result = "no notebook exists"
                    status = 'ERROR'
                   
        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "GetNotebook",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)

        response = response_wrapper(status,result,id)
           
        return response

    elif command == 'ProjectWriteable':
        # Test if it is possible to modify and save the data.
        try:
            if len(argu) < 1:
                result = 'Arguments should be: projectname'
                status = 'ERROR'
            else:
                result = projectobj.fileobj.iswriteable()
                status = 'OK'
               
        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "ProjectWriteable",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)

        response = response_wrapper(status,result,id)
           
        return response
           
    elif command == 'ProjectReadable':
        # Test if it is possible to get data from the object.
        try:
            if len(argu) < 1:
                result = 'Arguments should be: projectname'
                status = 'ERROR'
            else:
                result = projectobj.fileobj.isreadable()
                status = 'OK'
               
        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "ProjectReadable",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)

        response = response_wrapper(status,result,id)
           
        return response

    elif command == 'ReacquireProject':
        # force to grab the project lock. 
        try:
            if len(argu) < 1:
                result = 'Arguments should be: projectname'
                status = 'ERROR'
            else:
                project = get_argument(argu[0])
                result = projectobj.fileobj.refresh(grablock= True,readonly=False)
                status = 'OK'

               # send broadcast
               #message =  "<db_broadcast><message>Got the project lock again.</message></db_broadcast>\n"
        
               #ProjectManager().broadcast(message,project)
               
        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "ReacquireProject",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)

        response = response_wrapper(status,result,id)           
        return response

    elif command == 'SelectSubJobs':
        # Retrieve a list of subjobs based on some selection criterion.
        try:
            # get parameter
            if len(argu) < 4:
                result = 'Arguments should be: projectname job item pattern'
                status = 'ERROR'
            else:
                jobid = get_argument(argu[1])
                item = get_argument(argu[2])
                pattern = get_argument(argu[3])
                # call db API
                result = projectobj.fileobj.selectsubjobs(jobid,item,pattern)
                status = 'OK'
                
        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "SelectSubJobs",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)

        response = response_wrapper(status,result,id)
        return response

    elif command == 'HasSubJobs':
        # Check if a job currently has subjobs defined.
        try:
            # get parameter
            if len(argu) < 2:
                result = 'Arguments should be: projectname job'
                status = 'ERROR'
            else:
                jobid = get_argument(argu[1])

                # call db API
                result = projectobj.fileobj.has_subjobs(jobid)
                status = 'OK'
                
        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "HasSubJobs",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)

        response = response_wrapper(status,result,id)
        return response
    
    elif command == 'ListJobswithsubjobs':
        # Return a list of the jobs which also have subjobs.
        try:
            # get parameter
            if len(argu) < 1:
                result = 'Arguments should be: projectname'
                status = 'ERROR'
            else:
                # call db API
                result = projectobj.fileobj.listjobs_withsubjobs()
                status = 'OK'
                
        except exceptions.Exception,e:
            report_ignored_exception("do_def_readdb_command",
                                     "ListJobswithsubjobs",e,argu)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)

        response = response_wrapper(status,result,id)
        return response
    
    else:
        status = 'FAILED'
        result = 'No implement yet'
        response = response_wrapper(status,result,id)
        return response

#-----------------------------------------------------------------
# Section 4: This section is the commands for sql db for a particular project
#            One project can have both a database.def and a SQLite db.
#            database.def stores job history data while SQLite stores
#            additional job data and knowledgebase data.
#----------------------------------------------------------------

def do_parallel_sqlitedb_command(projectobj,sqldb,command,argu,id,useragent):
    """ process commands that access SQLite db """
   
    if command == 'SetJobQuality':
        # Set the value of 'JobQuality' in 'Jobs' table.
        try:
            if len(argu) < 3:
                result = 'Arguments should be: projectname jobid quality'
                status = 'ERROR'
            else:
                projectname = get_argument(argu[0])
                jobid = get_argument(argu[1])
                quality = get_argument(argu[2])
                # get primary key
                # construct condition
                condition = "where JobNumber = "+ str(jobid)
                tid = sqldb.get_table_primary_key("Jobs",condition)
                if tid != False:
                    result = sqldb.set_table_attribute("Jobs",tid,"JobQuality",quality)
                else:
                    result = False
                if result == True:
                    status = 'OK'
                else:
                    status = 'ERROR'
               
        except exceptions.Exception,e:
            print '# Handler message: catch exception:', str(e)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)
               
        response = response_wrapper(status,result,id)
        message = ""
            
        if status =='OK':
            message = broadcast_wrapper("Update "+projectname+" "+str(jobid),
                                        projectname,str(jobid),
                                        "Data changed",useragent)

        return [response,message]

    elif command == 'SetSQLdbData':
        # Generic command to set data in 'Jobs' table.
        try:
            if len(argu) < 4:
                result = 'Arguments should be: projectname jobid item value'
                status = 'ERROR'
            else:
                projectname = get_argument(argu[0])
                # jobid is JobNumber
                jobid = get_argument(argu[1])
                item = get_argument(argu[2])
                value = get_argument(argu[3])
                # get primary key
                # construct condition
                condition = "where JobNumber = "+ str(jobid)
                # tid is primary key
                tid = sqldb.get_table_primary_key("Jobs",condition)
                if tid != False:
                    result = sqldb.set_table_attribute("Jobs",tid,item,value)
                else:
                    result = False
                if result == True:
                    status = 'OK'
                else:
                    status = 'ERROR'
               
        except exceptions.Exception,e:
            print '# Handler message: catch exception:', str(e)
            status = 'ERROR'
            result = 'Handler exception: '+str(e)
               
        response = response_wrapper(status,result,id)
        message = ""
            
        if status =='OK':
            message = broadcast_wrapper("Update "+projectname+" "+str(jobid),
                                        projectname,str(jobid),
                                        "Data changed",useragent)

        return [response,message]
    
    elif command == 'GetSQLdbData':
        # Generic command to get data from 'Jobs' table
        try:
            argu_num = len(argu)
            if argu_num < 3:
                result = 'Arguments should be: projectname jobid item [item1 ...]'
                status = 'ERROR'
            else:
                projectname = get_argument(argu[0])
                jobid = get_argument(argu[1])
                # get primary key
                # construct condition
                condition = "where JobNumber = "+ str(jobid)
                tid = sqldb.get_table_primary_key("Jobs",condition)
    
                if tid != False:
                    result = []
                    # get jobnumer
                    #result.append(jobid)
                    #append other item values
                    for i in range(argu_num-2):
                        item = get_argument(argu[i+2])
                        result.append(sqldb.get_table_attribute('Jobs',tid,item))                    
                    # check the result and assign the status
                    for value in result: 
                        if 'error' in value or value == 'DB not open yet':
                            status = 'ERROR'
                            break
                    else:
                        status = 'OK'
                else:
                    result = False
                    status = 'ERROR'

        except exceptions.Exception,x:
            print '# Handler message: catch exception when get data:',str(x)
            status = 'ERROR'
            result = 'no such database:' + str(x)
            
        response = response_wrapper(status,result,id)
        # no update, assign empty message
        message = ""
        return [response,message]    

    elif command == 'GetAllSQLdbData':
        # Get all the data from 'Jobs' table
        try:
            argu_num = len(argu)
            if argu_num < 2:
                result = 'Arguments should be: projectname item [item2 ...]'
                status = 'ERROR'
            else:
                projectname = get_argument(argu[0])

                itemlist = get_argument_list(argu[1])
    
                result = sqldb.GetAllRecords('Jobs',itemlist)
            
                if result != 'DB not open yet' or 'error' not in result:
                    status = 'OK'
                else:
                    status = 'ERROR'

        except exceptions.Exception,x:
            print '# Handler message: catch exception:',str(x)
            status = 'ERROR'
            result = 'catch exception: ' + str(x)
            
        response = response_wrapper(status,result,id)
        # no update, assign empty message
        message = ""
        return [response,message]    

    # The following is generic commands for parallel sqlite db
    elif command == 'NewTableRecord':
        # Generic command for inserting a record in a given table
        try:
            argu_num = len(argu)
    
            if argu_num < 2:
                result = 'Argument should be: project tablename'
                status = 'ERROR'
            else:
                table = get_argument(argu[1])
                
                itemlist = []
                valuelist = []
                # get other arguments
                for i in range((argu_num-2)/2):
                    item = get_argument(argu[i*2+2])
                
                    itemlist.append(item)
                    value = get_argument(argu[i*2+3])
                
                    valuelist.append(value)
               
                no = sqldb.new_record(table,itemlist,valuelist)
                if 'DB exception: ' not in no:
                    status = 'OK'
                else:
                    status = 'ERROR'
                result = no

        except exceptions.Exception,x:
            print '# Handler message: catch exception:',str(x)
            status = 'ERROR'
            result = 'catch exception: '+str(x)

        response = response_wrapper(status,result,id)

        # no broadcast message sent at the moment. In the future, broadcast message should be formalised to include SQL db update and send to client.
        
        message = ""
        
        return [response,message]
    
    elif command == 'DeleteTableRecord':
        # Generic command for removing a record in a given table
        try:
            argu_num = len(argu)
    
            if argu_num < 2:
                result = 'Argument should be: project tablename recordid'
                status = 'ERROR'
            else:
                table = get_argument(argu[1])
                recordid = get_argument(argu[2])
                
                result = sqldb.delete_record(table,recordid)
                
                if result == True:
                    status = 'OK'
                else:
                    status = 'ERROR'

        except exceptions.Exception,x:
            print '# Handler message: catch exception:',str(x)
            status = 'ERROR'
            result = str(x)

        response = response_wrapper(status,result,id)

        # no broadcast message sent at the moment. In the future, broadcast message should be formalised to include SQL db update and send to client.
        
        message = ""
        
        return [response,message]
    
    elif command == 'DeleteTableRecords':
        # Delete records in a table based on certain condition
        try:
            argu_num = len(argu)
    
            if argu_num < 3:
                result = 'Argument should be: project tablename condition'
                status = 'ERROR'
            else:
                table = get_argument(argu[1])
                condition = get_argument(argu[2])
                
                result = sqldb.delete_records(table,condition)
                
                if result == True:
                    status = 'OK'
                else:
                    status = 'ERROR'

        except exceptions.Exception,x:
            print '# Handler message: catch exception:',str(x)
            status = 'ERROR'
            result = str(x)

        response = response_wrapper(status,result,id)

        # no broadcast message sent at the moment. In the future, broadcast message should be formalised to include SQL db update and send to client.
        
        message = ""
        
        return [response,message]
    
    elif command == 'SetTableData':
        # Set value for a given table and its attribute
        try:
            if len(argu) < 5:
                result = 'Argument should be: project tablename recordid attribute value'
                status = 'ERROR'
            else:
                table = get_argument(argu[1])
                tableid = get_argument(argu[2])
                attribute = get_argument(argu[3])
                value = get_argument(argu[4])
                result = sqldb.set_table_attribute(table,tableid,attribute,value)               
        except exceptions.Exception,x:
            print '# Handler message: catch exception:',str(x)
            status = 'ERROR'
            result = str(x)

        if result == True:
            status = 'OK'
        else:
            status = 'ERROR'
        response = response_wrapper(status,result,id)

        # no broadcast message sent at the moment. In the future, broadcast message should be formalised to include SQL db update and send to client.
        
        message = ""
        
        return [response,message] 

    elif command == 'GetTableData':
        # Retrieve the value of a given table and attribute
        try:
            if len(argu) < 3:
                result = 'Argument should be: project tablename tableid attribute'
                status = 'ERROR'
            else:
                table = get_argument(argu[1])
                tableid = get_argument(argu[2])
                attribute = get_argument(argu[3])
             
                result = sqldb.get_table_attribute(table,tableid,attribute)
                
                if result == False:
                    status = 'ERROR'
                else:
                    status = 'OK'
            
        except exceptions.Exception,x:
            print '# Handler message: catch exception:',str(x)
            status = 'ERROR'
            result = str(x)

        response = response_wrapper(status,result,id)

        # no broadcast message sent at the moment. In the future, broadcast message should be formalised to include SQL db update and send to client.
        
        message = ""
        
        return [response,message] 

    elif command == 'GetTablePrimaryKey':
        # retrieve primary key(s) for a given table based on certain condition
        try:
            if len(argu) < 3:
                result = 'Argument should be: project tablename condition'
                status = 'ERROR'
            else:
                table = get_argument(argu[1])
                condition = get_argument(argu[2])
             
                result = sqldb.get_table_primary_key(table,condition)
                if result == 'DB not open yet' or 'error' in result:
                    status = 'ERROR'
                else:
                    status = 'OK'
        except exceptions.Exception,x:
            print '# Handler message: catch exception:',str(x)
            status = 'ERROR'
            result = str(x)

        response = response_wrapper(status,result,id)

        # no broadcast message sent at the moment. In the future, broadcast message should be formalised to include SQL db update and send to client.
        
        message = ""
        
        return [response,message]

    elif command == 'GetAllTableRecords':
        # Retrieve all the records in a given table 
        try:
            argu_num = len(argu)
            if argu_num < 3:
                result = 'Arguments should be: projectname table attributes'
                status = 'ERROR'
            else:
                projectname = get_argument(argu[0])
                table = get_argument(argu[1])
                itemlist = get_argument_list(argu[2])
    
                result = sqldb.GetAllRecords(table,itemlist)
            
                if result != 'DB not open yet' or 'error' not in result:
                    status = 'OK'
                else:
                    status = 'ERROR'

        except exceptions.Exception,x:
            print '# Handler message: catch exception:',str(x)
            status = 'ERROR'
            result = 'Handler exception: ' + str(x)
            
        response = response_wrapper(status,result,id)
        # no update, assign empty message
        message = ""
        return [response,message]    

    elif command == 'GetTableRecords':
        # Retrieve records in a given table based on certain condition
        try:
            argu_num = len(argu)
            if argu_num < 4:
                result = 'Arguments should be: projectname table attributes condition'
                status = 'ERROR'
            else:
                projectname = get_argument(argu[0])
                table = get_argument(argu[1])
                itemlist = get_argument_list(argu[2])
                condition = get_argument(argu[3])
    
                result = sqldb.GetRecords(table,itemlist,condition)
            
                if result != 'DB not open yet' or 'error' not in result:
                    status = 'OK'
                else:
                    status = 'ERROR'

        except exceptions.Exception,x:
            print '# Handler message: catch exception:',str(x)
            status = 'ERROR'
            result = 'Handler exception: ' + str(x)
            
        response = response_wrapper(status,result,id)
        # no update, assign empty message
        message = ""
        return [response,message]
    
    else:
        status = 'FAILED'
        result = 'No implement yet'
        response = response_wrapper(status,result,id)
        return response

def get_argument(arguTag):

    '''Return the value of a single XML argument

    'arguTag' is an xml.dom.minidom Element (typically returned
    from the getElementsByTagName method). This function assumes
    that the Element object contains a single node, and returns
    the associated data. An empty string is returned if there is
    an IndexError (typically this happens if there is no
    associated data i.e. an empty tag pair).'''
    try:
        return arguTag.childNodes[0].data
    except IndexError:
        return ""

def get_argument_list(arguTag):

    '''Return a Python list from an XML argument representing a list

    'arguTag' is an xml.dom.minidom Element (typically returned
    from the getElementsByTagName method). This function assumes
    that the Element object contains a number of child nodes (which
    themselves are siblings of each other).

    The function returns a list composed of the associated data for
    each child node. If there is no associated data (for example, if
    the data is essentially an empty string) then an empty string
    is returned for that list item.'''
    list = arguTag.childNodes
    items = list[0].childNodes
    argumentlist = []
    for item in items:
        try:
            data = item.childNodes[0].data
        except IndexError:
            data = ""
        argumentlist.append(data)
    return argumentlist

def report_ignored_exception(function,operation,exception,dom_elements=[]):
    """Print a report of a caught and ignored exception

    function is the name of the function that the exception
    occurs in, operation is the name of the command, and
    exception is the exception object that was raised.

    Optionally the arguments can also be passed. These are
    one or more DOM elements, and their values will be
    extracted and printed."""
    print "# Handler message: exception caught in " \
          +str(function)+" ("+str(operation)+"):"
    print "Exception: \""+str(exception)+"\" (ignored)"
    if len(dom_elements) > 0:
        print "Called with "+str(len(dom_elements))+\
              " arguments (values extracted from DOM):"
        for i in range(0,len(dom_elements)):
            try:
                print "\t* "+str(dom_elements[i].childNodes[0].data)
            except:
                print "\t* [no value for "+str(dom_elements[i])+"]"
