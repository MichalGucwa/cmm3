#!/usr/bin/env python
#
# Basic HTTP Server giving access to the CCP4i database
# Based on the basichttp.py example - in ""Foundations of Python Network
# Programming" (John Goerzen) Chapter 16

# This server takes requests in the form of
# http://localhost:8765/?command=...&project=...&job=... etc
# It then connects to the handler, retrieves some data and sends
# back a HTML page

#CCP4i_cvs_Id $Id: http_dbclient.py,v 1.9 2008/08/12 10:48:13 pjx Exp $

from BaseHTTPServer import HTTPServer, BaseHTTPRequestHandler
import sys
import time
import dbClientAPI

class RequestHandler(BaseHTTPRequestHandler):
    
    def _writeheaders(self):
        self.send_response(200)
        self.send_header('Content-type','text/html')
        self.end_headers()

    def do_HEAD(self):
        self._writeheaders()

    def do_GET(self):
        self._writeheaders()
        # decode the input
        data = decodeRequest(self.path)
        print "Request decoded"
        # Execute the request
        result = dbccp4i_request(data)
        print "Sending result to requester"
        self.wfile.write("""
        <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
        "http://www.w3.org/TR/html4/loose.dtd">
        <html><head><title>DbCCP4i</title><style type="text/css"><!-- /* Hide the stylesheet from older browsers */
           body { font-family: Verdana, Arial, sans-serif;
                  font-size: 17px;
                  background-color: white; }
           h1 { background-color: gray; }
           h2 { background-color: lightgray; }
           table,td,th { border-style: solid;
                         border-width: 2px;
                         border-spacing: 0;
                         border-color: gray;
                         padding: 1px;
                         font-size: 90%; }
           th { background-color: #cfcdff; }
           .report { background-color: #cfcdff; }
           .parameters { background-color: #f5f5dc;
                         font-size: 90%; }
           -->
           </style>
           </head><body>""")
        # Write the actual result
        self.wfile.write(result)
        # Report the parameters
        self.wfile.write("<div class=\"parameters\">Parameters for the request:\n")
        self.wfile.write("<ul>\n")
        for key in data.keys():
            self.wfile.write("<li>"+str(key)+" = "+str(data[key])+"</li>\n")
        self.wfile.write("</ul>\n")
        self.wfile.write("</div>\n")
        # Add a little report
        self.wfile.write("<hr /><div class=\"report\">")
        self.wfile.write("<em>Generated by http_dbclient "+\
                         dbClientAPI.ConvertTime(time.time())+\
                         "</em></div>\n")
        self.wfile.write("</body></html>\n")
        print "Request sent"
        return

def dbccp4i_request(data):
    print "Started processing request"
    # Get a connection to the handler
    db = dbClientAPI.HandlerConnection('http_dbccp4i',True)
    result = ""
    # Attempt to execute a handler request
    if not data.has_key("command"):
        # Assume that we want to list the available projects
        data["command"] = "ListProjects"
    # Available actions
    if data["command"] == "ListProjects":
        # Generate a list of projects with links to more commands
        result = "<h1>List of projects</h1>\n"
        projects = db.ListProjects()
        if len(projects) == 0:
            result += "<p>No projects available</p>"
        else:
            result += "<ul>\n"
            for project in projects:
                result += "<li><a href='"+\
                          buildRequest(\
                    {"command":"ListJobs","project": project})+\
                    "'>"+project+"</a></li>\n"
            result += "</ul>\n"
    elif data["command"] == "ListJobs":
        # Generate a list of the jobs in the project
        project = data["project"]
        result = "<h1>Project: "+str(project)+"</h1>\n"
        if data.has_key("job"):
            result += "<h2>Subjobs for job "+str(data["job"])+"</h2>\n"
        if db.OpenProject(project,readonly=True):
            if data.has_key("job"):
                records = db.GetListofRecords(project,[data["job"]],\
                                              ["DATE","STATUS","TASKNAME","TITLE"])
                result += "<p>"
                result += str(records[0][2])+": \""+str(records[0][3])+"\""
                result += "</p>\n"
                jobs = db.ListJobs(project,data["job"])
                subjobs = []
            else:
                jobs = db.ListJobs(project)
                subjobs = db.ListJobswithsubjobs(project)
            if len(jobs) == 0:
                result += "<p>There are currently no jobs in this project</p>\n"
            else:
                jobs.reverse()
                records = db.GetListofRecords(project,jobs,\
                                              ["DATE","STATUS","TASKNAME","TITLE"])
                result += """<table border=1><tr><th>ID</th><th>DATE</th>
                <th>STATUS</th><th>TASKNAME</th><th>TITLE</th>"""
                if not data.has_key("job"):
                    result += "<th>Subjobs</th></tr>\n"
                for i in range(0,len(jobs)):
                    result += "<tr>"
                    result += "<td>"+str(jobs[i])+"</td>\n"
                    j = 0
                    for item in records[i]:
                        if j == 0:
                            # Convert the DATE to a human readable form
                            item = dbClientAPI.ConvertTimeCCP4i(float(item))
                            j += 1
                        result += "<td>"+str(item)+"</td>"
                    # Indicate if there are subjobs available
                    if not data.has_key("job"):
                        try:
                            subjobs.index(jobs[i])
                            result += "<td><a href='"+\
                                      buildRequest(\
                                {"command":"ListJobs",
                                 "project":project,
                                 "job":jobs[i]})+\
                                 "'>View subjobs</a></td>"
                        except ValueError:
                            result += "<td>&nbsp;</td>"
                    result += "</tr>\n"
                result = result + "</table>\n"
            db.CloseProject(project)
        else:
            result = "<p>Unable to access the project</p>"
            
        # Links at the tail of the page

        # Refresh the view by executing the same request again
        result += "<p>"
        result += " <a href='"+buildRequest(data)+"'>[Refresh]</a>"
        # Link for subjobs to return to main job view
        if data.has_key("job"):
            result += " <a href='"+buildRequest(\
                {"command":"ListJobs","project":project})+\
                "'>[List jobs in "+str(project)+"]</a>"
        # Write a link to get back to the list of projects
        result += " <a href='"+buildRequest({"command":"ListProjects"})+\
                  "'>[Back to projects]</a>"
        result += "</p>\n"

    # Finish with the handler connection
    db.HandlerDisconnect()
    # Return the result
    print "Finished building result HTML"
    return result

# Supporting functions
def decodeRequest(url):
    """Break up a url into a set of arguments and values.

    Given a url of the form path?key1=value1&key2=value2&...
    return a dictionary where the keys are key1, key2 etc
    and the corresponding values are value1, value2 etc."""
    request = url.split("?")
    try:
        args = request[1].split("&")
    except IndexError:
        args = request
    data= {}
    for arg in args:
        try:
            key = arg.split("=")[0]
            value = arg.split("=")[1]
            data[key] = value
        except:
            print "Error decoding "+arg
    return data

def buildRequest(args):
    """Make a request string from a dictionary

    Given a dictionary of the form { 'key1':value1, 'key2':value2, ... }
    return a string of the form '?key1=value1&key2=value2&..."""
    request = []
    for key in args:
        request.append(str(key)+"="+str(args[key]))
    request.sort()
    return "?"+"&".join(request)
    
# Main program
try:
    # Start the HTTP server
    port = 8765
    serveraddr = ('', port)
    srvr = HTTPServer(serveraddr, RequestHandler)
    print "http_dbclient listening on port %d" % port
    print "Point your browser at http://localhost:%d to connect" % port
    print "Using Ctrl-C to stop the server"
    srvr.serve_forever()
except KeyboardInterrupt:
    print "Finished"
    sys.exit(0)