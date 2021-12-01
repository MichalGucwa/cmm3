#
#     Copyright (C) 2006
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#====================================================================
# CCP4 Interface - dbsocket.py
#
# Classes and methods for handling pseudo-asynchronous communications
# with the db handler
# 
# Peter Briggs
#
#====================================================================

#CCP4i_cvs_Id $Id: dbsocket.py,v 1.9 2008/08/12 10:47:59 pjx Exp $

#####################################################################

import socket
import select
import time
import threading
import Queue
import re
import exceptions
import xml.dom.minidom
import xml.sax.saxutils as su

# Module globals
_request_id = 0
_debug = False
#_debug = True
# The idea is that the client API should use this as the way to
# communicate with the handler.
# The client would need to implement its own listener to
# check for broadcast messages - this would be important for a
# visualiser application which would need to respond to changes
# in the db content

class dbRequest:
    """Class representing a handler request."""

    def __init__(self,command,arguments):
        """Command is the base command being issued; arguments is
        a tuple of appropriate options"""
        self.__command = command
        self.__arg_list = arguments
        self.__id = get_request_id()

    def __str__(self):
        """Print the string representation of the dbRequest object."""
        text = str(self.__command)
        if len(self.__arg_list) !=0:
            for arg in self.__arg_list:
                text = text + " " + str(arg)
        return text

    def xml(self):
        """Transform the request into XML"""
        xml_request = "<db_request><command>"+su.escape(str(self.__command))+"</command>"
        if len(self.__arg_list) !=0:
            for arg in self.__arg_list:
                if type(arg) == list:
                    xml_request = xml_request + "<argument><list>"
                    for item in arg:
                        xml_request = xml_request + "<item>"+ su.escape(str(item))+"</item>"
                    xml_request = xml_request + "</list></argument>"
                else:
                    xml_request = xml_request + \
                              "<argument>"+su.escape(str(arg))+"</argument>"
        xml_request = xml_request + \
                      "<request_id>"+self.__id+"</request_id></db_request>"
        return xml_request

    def request_id(self):
        """Return the request id string."""
        return self.__id

class dbResponse:
    """Class representing a response from the handler.

    The object is initialised with the raw XML returned by the
    handler, and is classified as either a response to request
    or as a broadcast."""

    def __init__(self,xml_response):
        """xml_response is the raw response from the handler"""
        self.__xml_response = xml_response
        # Parameters for response
        self.__xml_line = []
        self.__is_response = []
        self.__status = []
        self.__result = []
        self.__id = []
        # Parameter for broadcast
        self.__is_broadcast = []
        self.__broadcast = []
        ###
        self.__message = []
        self.__project = []
        self.__jobid = []
        self.__operation = []
        self.__agent = []
        ###
        # Check for multiple lines
        response_list = xml_response.split("\n")
        # Counter
        self.__count = 0
        # Parse the input
        for xml_line in response_list:
            # Initialise the parameters
            self.__is_response.append(False)
            self.__status.append("")
            self.__result.append("")
            self.__id.append("")
            self.__is_broadcast.append(False)
            self.__broadcast.append("")
            self.__message.append("")
            self.__project.append("")
            self.__jobid.append("")
            self.__operation.append("")
            self.__agent.append("")
            # Process the line
            if self.parse(xml_line):
                self.__xml_line.append(xml_line)
                # Increment the counter
                self.__count = self.__count+1

    def __str__(self):
        """String representation of the response object."""
        for i in range(1,self.__count):
            if self.is_broadcast(i):
                return "Broadcast: "+str(self.broadcast(i))
            elif self.is_response(i):
                return "Response: "+str(self.status(i))+" "+str(self.result(i))
            else:
                return "Unrecognised: "+str(self.__xml_response[i])

    def parse(self,xml_line):
        """Attempt to process the XML and extract the components.

        Return False if the extraction fails, and True otherwise."""
        
        # Check for empty string
        if xml_line == "":
            ##print "Empty string in dbResponse parse method"
            return False

        # Set index for lists
        i = self.__count

        # Test for broadcast first
        if '<db_broadcast>' in xml_line:
            self.__is_broadcast[i] = True
            try:
                doc = xml.dom.minidom.parseString(xml_line)
                # Extract the message components
                message = self.getBroadcastElement(doc,"message")
                project = self.getBroadcastElement(doc,"project")
                jobid = self.getBroadcastElement(doc,"jobid")
                operation = self.getBroadcastElement(doc,"operation")
                agent = self.getBroadcastElement(doc,"agent")
                self.__message[i] = message
                self.__project[i] = project
                self.__jobid[i] = jobid
                self.__operation[i] = operation
                self.__agent[i] =  agent
                self.__broadcast[i] = [self.__message[i],
                                       self.__project[i],
                                       self.__jobid[i],
                                       self.__operation[i],
                                       self.__agent[i]]
                return True
        
            except exceptions.Exception,e:
                # Parsing failed
                print "Exception in dbResponse parse method"
                print "Input xml: "+str(xml_line)
                print "response.parse (broadcast): Exception: "+str(e)
                raise
            
        elif '<db_response>' in xml_line:
            # Process response
            try:
                doc = xml.dom.minidom.parseString(xml_line)
                # Status tag
                statusTag = doc.getElementsByTagName("status")
                status = statusTag[0].childNodes[0].data
                # Result tag
                resultTag = doc.getElementsByTagName("result")
                # Id tag
                # if single value, append to resultlist, else retrive
                # items from nested tag
                if resultTag[0].childNodes[0].nodeType == \
                       resultTag[0].childNodes[0].TEXT_NODE:
                    result = resultTag[0].childNodes[0].data   
                else:
                    list = resultTag[0].childNodes
                    items = list[0].childNodes
                    result = self.getXMLitems(items,[])
                try:
                    responseidTag = doc.getElementsByTagName("response_id")
                    responseid = responseidTag[0].childNodes[0].data
                except IndexError:
                    # The response id is not compulsory
                    responseid = ""

                # Successfully processed the XML
                self.__status[i] = status
                self.__result[i] = result
                self.__id[i] = responseid
                self.__is_response[i] = True
                return True
        
            except exceptions.Exception,e:
                # Parsing failed
                print "Exception in dbResponse parse method"
                print "Input xml: "+str(xml_line)
                print "response.parse (response): not a response:"
                return False

        else:
            # Something unrecognised
            return False

    def getBroadcastElement(self,doc,element):
        """Return value for a broadcast element.

        'doc' is the result of a xml.dom.minidom.parseString() call on
        a string representing an XML broadcast; 'element' is a
        broadcast element name e.g. 'message', 'project', etc.

        Returns the value of text enclosed in the tags. If the
        raises an IndexError if the element is not found, unless
        the 'ignore_missing' argument is set to True."""

        resultTag = doc.getElementsByTagName(element)
        result = ""
        try:
            if resultTag[0].hasChildNodes():
                result = resultTag[0].childNodes[0].data
        except IndexError:
            # Unable to find the element - ignore
            pass
        return result

    def getXMLitems(self,items,varlist):
        """Retrieve items from an XML-wrapped result list.

        This is called from the parse method to deal with
        lists in the XML response i.e.
        <list><item>..</item>...</list> constructs."""
            
        value = varlist
        tmp = []
        for item in items:
            # check if it is nested
            try:
                if item.childNodes[0].nodeName == 'list':
                    # if find the next node is 'list', get the nested items
                    nesteditems = item.childNodes[0].childNodes
                    # call the function itself
                    self.getXMLitems(nesteditems,tmp)
                else:
                    # if it is a text, get the data from the node
                    tmp.append(item.childNodes[0].data)
            except IndexError:
                # This seems to happen when the "item" node contains no
                # data - append an empty data item
                tmp.append(u"")
        # append the tmp result to the return value
        value.append(tmp)
    
        if len(value) == 1:
            # only have one element in the list, then return the element. 
            return value[0]
        else:
            return value

    def nresponses(self):
        """Return the number of responses (lines) processed."""
        return self.__count

    def xml_line(self,i):
        """Return the i'th line of input XML."""
        return self.__xml_line[i]
    
    def is_response(self,i):
        """Check if the i'th line contains an XML response."""
        return self.__is_response[i]

    def status(self,i):
        """Return the status component of the i'th response."""
        if self.__is_response[i]:
            return self.__status[i]
        else:
            return ""

    def result(self,i):
        """Return the result component of the i'th response."""
        if self.__is_response[i]:
            return self.__result[i]
        else:
            return ""

    def response_id(self,i):
        """Return the id component of the i'th response."""
        if self.__is_response[i]:
            return self.__id[i]
        else:
            return ""

    def is_broadcast(self,i):
        """Check if the i'th object contains an XML broadcast."""
        return self.__is_broadcast[i]

    def broadcast(self,i):
        """Return the i'th broadcast message from the XML."""
        if self.__is_broadcast[i]:
            return self.__broadcast[i]
        else:
            return ""

    def message(self,i):
        """ Return the message component of the i'th broadcast"""
        if self.__is_broadcast[i]:
            return self.__message[i]
        else:
            return ""

    def project(self,i):
        """ Return the project component of the i'th broadcast"""
        if self.__is_broadcast[i]:
            return self.__project[i]
        else:
            return ""

    def jobid(self,i):
        """ Return the jobid component of the i'th broadcast"""
        if self.__is_broadcast[i]:
            return self.__jobid[i]
        else:
            return ""    
    
    def operation(self,i):
        """ Return the operation component of the i'th broadcast"""
        if self.__is_broadcast[i]:
            return self.__operation[i]
        else:
            return ""
    
    def agent(self,i):
        """ Return the agent component of the i'th broadcast"""
        if self.__is_broadcast[i]:
            return self.__agent[i]
        else:
            return ""
    
    def report(self):
        """Report the contents of the response object."""
        print "******************************************"
        print "Number of lines: "+str(self.nresponses())
        for i in range(0,self.nresponses()):
            print "Response #"+str(i)
            print "\tData line: "+str(self.__xml_line[i])
            if self.is_broadcast(i):
                print "\tBroadcast message:"
                #print "\t\t\""+str(self.message(i))+"\""
                print "\t\tmessage: "+str(self.message(i))
                print "\t\tproject: "+str(self.project(i))
                print "\t\tjobid    : "+str(self.jobid(i))
                print "\t\toperation: "+str(self.operation(i))
                print "\t\tagent    : "+str(self.agent(i))
            elif self.is_response(i):
                print "\tRequest response:"
                print "\t\tStatus: "+str(self.status(i))
                print "\t\tResult: "+str(self.result(i))
                print "\t\tId    : "+str(self.response_id(i))
            else:
                print "\tUnrecognised:"
                print "\t\t"+str(self.__xml_line[i])

class dbsocket(threading.Thread):
    """Class for handling interactions between client and handler.

    A dbsocket object is instantiated by providing it with a host name
    and port number. It then opens a socket connection to the handler
    via that host port. The client can send requests to the handler,
    (and get back the responses) using the 'request' method of the
    dbsocket object.

    The dbsocket intercepts handler broadcasts and ensures that these
    don't interfere with the client's request/response pairs. The
    client can check and collect broadcasts separately using the
    nbroadcast and getbroadcast methods.

    Responses to requests are in the form of lists: [status,result]."""
    
    def __init__(self,host,port,timeout=30):
        
        # Start
        ##print "Instantiating dbsocket object..."
        threading.Thread.__init__(self)
        self.setDaemon(True)
        self.requestQueue = Queue.Queue()
        self.responseQueue = Queue.Queue()
        self.broadcastQueue = Queue.Queue()
        # Setup the socket connection
        try:
            self.host = host
            self.port = port
            self.addr = (self.host,self.port)
            self.socket = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
            self.socket.connect(self.addr)
        except exceptions.Exception,e:
            # Connection attempt failed
            print "dbsocket: init failed with exception:"
            print str(e)
            raise
        # Start the queue
        self.active = True
        self.timeout = timeout
        self.request_id = 0
        #print "dbsocket: invoking start method"
        self.start()

    # Check that the dbsocket is still active
    def isActive(self):
        """Return True if the dbsocket is still active, False if not."""
        return self.active

    # Application should use this to send a
    # request to the handler
    def request(self,command,args):
        """Send a request to the handler.

        The request consists of a command and a list of arguments. The
        result of the request method is the response from the handler
        (or a timeout message if no response was received within the
        timeout period)."""

        global _debug
        debug = _debug
        
        request = dbRequest(command,args)
        if debug: print "dbsocket: received request \""+str(request)+"\""
        self.requestQueue.put(request)
        if debug: print "dbsocket: request placed in the queue, waiting"
        response = self.responseQueue.get()
        if debug: print "dbsocket: got the response \""+str(response)+"\""
        if debug: print "dbsocket: returning"
        return response

    # Start the dbsocket process running
    def run(self):
        """Called by start method to start the dbsocket process.

        This handles sending requests to the handler, processing
        the responses, and dealing with any broadcast messages."""
        
        global _debug
        debug = _debug
        
        # Use start_time as a flag to indicate whether we're
        # currently waiting for a request
        start_time = -1
        # Set up a loop to run whileever the dbsocket is active
        xml_response = ""
        while self.active:
            ##if debug: print "In loop..."
            if self.requestQueue.qsize() > 0 and start_time < 0:
                # Get the next request and send it
                request = self.requestQueue.get()
                xml_request = request.xml()
                if debug: print "dbsocket.run: got request: \""+str(xml_request)+"\""
                self.socket.send(str(xml_request)+"\n")
                if debug: print "dbsocket.run: request sent"
                # Get the current time in case of timeout
                start_time = time.time()
                if debug: print "dbsocket.run: start_time = "+str(start_time)
            if socket_is_readable(self.socket):
                if debug: print "dbsocket.run: socket is readable"
                # There is some data to read
                xml_response = xml_response+str(self.socket.recv(4096))
                if debug: print "dbsocket.run: read data from socket: \""+str(xml_response)+"\""
                
                # Process the response
                if xml_response != "" and xml_response[-1] == "\n":
                    response = dbResponse(xml_response)
                    for i in range(0,response.nresponses()):
                        if response.xml_line(i) == "":
                            # Empty string received from the handler
                            if debug: print "dbsocket.run: empty string received"\
                               +"from handler"
                            self.responseQueue.put(["ERROR","Empty string received"])
                            # Clear the current request
                            start_time = -1
                        elif response.is_broadcast(i):
                            # Add to the broadcast queue
                            if debug: print "dbsocket.run: detected broadcast"
                            print str(response.broadcast(i))
                            self.broadcastQueue.put(response.broadcast(i))
                            #self.broadcastQueue.put([response.message(i),response.project(i),response.jobid(i),response.operation(i),response.agent(i)])
                        elif start_time >= 0.0:
                            # Check whether this is a response to a request
                            if response.is_response(i):
                                if response.response_id(i) == request.request_id():
                                    # This is the correct response
                                    # Add it to the response queue
                                    if debug:
                                        print "dbsocket.run: response id matched request id"
                                    self.responseQueue.put([response.status(i),
                                                            response.result(i)])
                                    # Reset the timer
                                    start_time = -1
                                else:
                                    # A response but with the wrong id
                                    if debug:
                                        print "dbsocket.run: bad response received: \""\
                                              +str(xml_response)+"\" (ignored)"
                            else:
                                # Not sure what this is
                                if debug: print "dbsocket.run: error assumed"
                                report_error(response.result(i))
                    # Reset the response buffer
                    xml_response = ""
            ##if debug: print "dbsocket.run: checking for timeout..."
            if self.timeout_exceeded(start_time):
                # No response from server after timeout
                # has elapsed
                if debug: print "dbsocket.run: timeout condition reached"
                self.responseQueue.put(["ERROR","Server timed out"])
                # Clear this request
                start_time = -1

    # Close the connection
    def close(self):
        """Close the dbsocket connection.

        Terminate the socket connection to the handler and flag
        the dbsocket as inactive."""
        
        self.active = False
        ntries=0
        while self.isAlive() and ntries < 100:
            # Keep checking until the thread has terminated
            time.sleep(0.1)
            ntries=ntries+1
        if self.isAlive():
            print "dbsocket.close: warning, thread is still active"
        self.socket.close()
        return True	

    # Return true if timeout period has been exceeded
    def timeout_exceeded(self,start_time):
        """Internal method: check whether the timeout has been exceeded.

        Returns True if the elapsed time has exceeded the timeout
        period, and False if not."""
        
        if start_time < 0:
            return False
        if (time.time() - start_time) > self.timeout:
            return True
        return False

    # Return number of broadcast messages in the queue
    def nbroadcasts(self):
        """Return the number of broadcast messages waiting processing."""
        return self.broadcastQueue.qsize()
    
    # Pull the oldest broadcast message from the queue
    def getbroadcast(self):
        """Return the oldest available broadcast message for processing.

        Broadcast messages are put in a queue when received. Fetching
        a broadcast message removes it from the queue."""
        
        if self.nbroadcasts() > 0:
            print 'broadcast:'
            print self.broadcastQueue.get()
            return self.broadcastQueue.get()
        else:
            return ""

# Check and report broadcasts
class report_broadcast(threading.Thread):
    """Example of a thread process to monitor and report on broadcasts.

    Given a dbsocket object, the report_broadcast object continually
    checks for broadcast messages and prints them to stdout."""
    
    def __init__(self,dbsock):
        threading.Thread.__init__(self)
        self.setDaemon(1)
        self.socket = dbsock
        self.start()

    def run(self):
        while self.socket.isActive():
            while self.socket.nbroadcasts() > 0:
                broadcast = self.socket.getbroadcast()
                print "******************************************************"
                print "Received broadcast message:\n"
                print str(broadcast)
                print "******************************************************"

# Test whether a specific socket is readable
def socket_is_readable(socket):
    """Checks whether the specified socket object is readable.

    Returns True if data can be read from the socket, False if not."""
    
    if not socket:
        return False
    try:
        slist = select.select([socket],[],[],0.01)
        if len(slist[0]) > 0:
            # Socket is ready to read
            return True
    except exceptions.Exception,e:
        print "Exception in socket_is_readable: "+str(e)
    return False

# Generate a unique request id
def get_request_id():
    """Generate a unique identifier string for a request."""
    global _request_id
    _request_id = _request_id + 1
    requestid = "request#"+str(_request_id)
    return requestid

# Report error
def report_error(error):
    """Internal error reporting method."""
    
    print "dbsocket: error \""+str(error)+"\""
