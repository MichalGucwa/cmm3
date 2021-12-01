#
#     Copyright (C) 2007
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# starKey.py
#
# This is a client application of db handler which outputs the job histories
# to xml file for deposition.
# 
# Wanjuan Yang Jan 07
#
#====================================================================

#CCP4i_cvs_Id $Id: starKey.py,v 1.9 2008/08/12 10:48:04 pjx Exp $

#####################################################################

# Import modules
from xml.dom.minidom import Document
import exceptions
import sys
import os
import time

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
except ImportError,ex:
    print "Unable to load one or more of the DbCCP4i modules:"
    print str(ex)
    sys.exit(1)

# Start starKey
try:
    # check argument
    if len(sys.argv) < 3:
        print 'Usage: python starKey.py output_file projectname jobid1 jobid2 ...'
        sys.exit()
    else:
        # get project name from input argument
        output_file = sys.argv[1]
        project = sys.argv[2]

        # get the joblist from input argument
        joblist = []
        for i in range(len(sys.argv)-3):
            joblist.append(int(sys.argv[i+3]))
                
except exceptions.Exception,e:
    print 'Usage: python starKey.py output_file projectname jobid1 jobid2 ...'
    print str(e)
    sys.exit()

try:
    # connect the handler
    conn = dbClientAPI.HandlerConnection('dummy',True)

except exceptions.Exception,e:
    print "connection to handler failed"
    print str(e)
    sys.exit()
    
try:    
    # open project
    conn.OpenProject(project,readonly=True)

    # get project directory
    project_dir = conn.GetDataDir(project)
    
    # get job data
    itemlist = ["TITLE","TASKNAME","DATE","LOGFILE"]
    
    records = conn.GetListofRecords(project,joblist,itemlist)
    # create a document
    doc = Document()
        
    # create a root node
    root = doc.createElement("BioXHIT_data_tracking")
    doc.appendChild(root)

    # create projectname node
    projectnode = doc.createElement("project_name")
    root.appendChild(projectnode)
        
    # add projectname
    projecttext = doc.createTextNode(project)
    projectnode.appendChild(projecttext)
    
    # add step node
    for i in range(len(joblist)):
        # get the job data 
        title = records[i][0]
        taskname = records[i][1]
        date = records[i][2]
        log_file = records[i][3]
               
        # get input_file_list 
        #input_files_list = conn.GetFileList(project,joblist[i],"INPUT")
        input_files_list = conn.ListInputFiles(project,joblist[i])   
        # get out_file_list
        output_files_list = conn.ListOutputFiles(project,joblist[i])
              
        # add job node
        jobnode = doc.createElement("step")
        root.appendChild(jobnode)
        
        step_no_node = doc.createElement("step_number")
        jobnode.appendChild(step_no_node)
            
        step_no_text = doc.createTextNode(str(joblist[i]))
        step_no_node.appendChild(step_no_text)
            
        # make a title node
        title_node = doc.createElement("step_title")
        jobnode.appendChild(title_node)
        title_text = doc.createTextNode(str(title))
        title_node.appendChild(title_text)

        # check if there are previous steps
        previous_steps = conn.GetParents(project,joblist[i])

        if len(previous_steps) >0:
            # make previous step node
            previous_step_node = doc.createElement("previous_steps")
            jobnode.appendChild(previous_step_node)
            for i in range(len(previous_steps)):
                previous_step_no_node = doc.createElement("step_number")
                previous_step_node.appendChild(previous_step_no_node)
                previous_step_text = doc.createTextNode(previous_steps[i])
                previous_step_no_node.appendChild(previous_step_text)
                                          
        # make a taskname node
        taskname_node = doc.createElement("application_task_name")
        jobnode.appendChild(taskname_node)
        taskname_text = doc.createTextNode(str(taskname))
        taskname_node.appendChild(taskname_text)
           
        # make a date_time node
        date_time_node = doc.createElement("date")
        # convert to formated time
        jobnode.appendChild(date_time_node)
        # convert to formated time
        date_time_text = doc.createTextNode(dbClientAPI.ConvertTime(float(date)))
        
        date_time_node.appendChild(date_time_text)
                
        # get the control file
        control_file = os.path.join(project_dir,"CCP4_DATABASE",str(joblist[i])+"_"+str(taskname)+".def")

        # check if exist
        if os.path.isfile(control_file):
            # make a control file node
            control_file_node = doc.createElement("application_control_file")
            jobnode.appendChild(control_file_node)
            control_file_text = doc.createTextNode(str(control_file))
            control_file_node.appendChild(control_file_text)
                    
        # make an input_file_node
        input_file_node = doc.createElement("input_files")
        jobnode.appendChild(input_file_node)
            
        # get each input file
        if len(input_files_list)>0:
            for file in input_files_list:
                if file != "":
                    file_node = doc.createElement("file")
                    input_file_node.appendChild(file_node)

                    # add file_ref node
                    file_ref_node = doc.createElement("file_ref")
                    file_node.appendChild(file_ref_node)
                    input_file_text = doc.createTextNode(str(file))
                    file_ref_node.appendChild(input_file_text)

        # make an output_file_node
        output_file_node = doc.createElement("output_files")
        jobnode.appendChild(output_file_node)
            
        # get each output file
        if len(output_files_list)>0:
            for file in output_files_list:
                if file != "":
                    file_node = doc.createElement("file")
                    output_file_node.appendChild(file_node)

                    # add file_ref node
                    file_ref_node = doc.createElement("file_ref")
                    file_node.appendChild(file_ref_node)
                    output_file_text = doc.createTextNode(str(file))
                    file_ref_node.appendChild(output_file_text)
             
        # get the logfile

        logfile_full_name = os.path.join(project_dir,str(log_file))
        # make an log file node
        logfile_node = doc.createElement("log_file")
        jobnode.appendChild(logfile_node)

        if os.path.isfile(logfile_full_name):
            # add log file
            logfile_text = doc.createTextNode(str(logfile_full_name))
            logfile_node.appendChild(logfile_text)

            # parse logfile
            log = smartie.parselog(logfile_full_name)
            n = log.nprograms()
                
            if n >0:
                # make a component_substeps node
                component_substep_node = doc.createElement("component_substeps")
                jobnode.appendChild(component_substep_node)
                        
                for i in range(n):
                    substep_node = doc.createElement("substep")
                    component_substep_node.appendChild(substep_node)

                    # add substep 
                    substep_number_node = doc.createElement("substep_number")
                    substep_node.appendChild(substep_number_node)
                    substep_number_text = doc.createTextNode(str(i+1))
                    substep_number_node.appendChild(substep_number_text)
                            
                    program_name_node = doc.createElement("program_name")
                    substep_node.appendChild(program_name_node)
                    if log.program(i).has_attribute("name"):
                        program_name_text = doc.createTextNode(str(log.program(i).name))
                    else:
                        program_name_text = doc.createTextNode("Not identified")
                    program_name_node.appendChild(program_name_text)
                    program_version_node = doc.createElement("program_version")
                    substep_node.appendChild(program_version_node)
                    if log.program(i).has_attribute("version"):
                        program_version_text = doc.createTextNode(str(log.program(i).version))
                    else:
                        program_version_text = doc.createTextNode("Not identified")
                    program_version_node.appendChild(program_version_text)
                    

                    if log.program(i).isccp4():
                    
                        # add program package
                        program_package_node = doc.createElement("program_package")
                        program_package_text = doc.createTextNode("CCP4")
                        substep_node.appendChild(program_package_node)
                        program_package_node.appendChild(program_package_text)
                        # add program version
                        program_package_version_node = doc.createElement("program_package_version")
                        program_package_version_text = doc.createTextNode(str(log.program(i).ccp4version))
                        substep_node.appendChild(program_package_version_node)
                        program_package_version_node.appendChild(program_package_version_text)
                                    
    # write to file
    outputfile = open(output_file,"w")   
    doc.writexml(outputfile)
    outputfile.close()
    print doc.toprettyxml(indent= " ")
    conn.CloseProject(project)
        
except exceptions.Exception,e:
    print 'catch exception:', str(e)

conn.HandlerDisconnect()
