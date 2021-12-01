"""This module tests functionality in the module dbsocket.py."""

__version__ = "$Revision: 1.2 $"

import unittest

# Update the python path to acquire the dbsocket module
import sys
import os,os.path
if os.path.isdir(os.path.join(os.environ["DBCCP4I_TOP"])):
    ccp4i_path = os.path.join(os.environ["DBCCP4I_TOP"],"dbccp4i")
    sys.path.append(ccp4i_path)
    clientapi_path = os.path.join(os.environ["DBCCP4I_TOP"],"ClientAPI")
    sys.path.append(clientapi_path)
import dbsocket

class XMLRequestTest(unittest.TestCase):
    
    def testSingleArgument(self):
        """Test wrapping a request with a single argument."""
        
        myRequest = dbsocket.dbRequest("DbCommand2",["arg4"])
        self.assertEqual(myRequest.xml(),
                         "<db_request><command>DbCommand2</command><argument>arg4</argument><request_id>request#3</request_id></db_request>",
                         "Failed to wrap single argument request")

    def testMultipleArguments(self):
        """Test wrapping a request with multiple arguments."""
        
        myRequest = dbsocket.dbRequest("DbCommand",["arg1","arg2","arg3"])
        self.assertEqual(myRequest.xml(),
                         "<db_request><command>DbCommand</command><argument>arg1</argument><argument>arg2</argument><argument>arg3</argument><request_id>request#1</request_id></db_request>",
                         "Failed to wrap multiple argument request")

    def testNoArguments(self):
        """Test wrapping a request with no arguments."""
        
        myRequest = dbsocket.dbRequest("DbCommand3",[])
        self.assertEqual(myRequest.xml(),
                         "<db_request><command>DbCommand3</command><request_id>request#2</request_id></db_request>",
                         "Failed to wrap request with no arguments")

class XMLResponseTest(unittest.TestCase):
    
    # Example of response unwrapping
    def testSingleItemNoId(self):
        """Test unwrapping single item result with no response id."""
        
        myXml = "<db_response><status>OK</status><result>This is a result</result></db_response>"
        myResponse = dbsocket.dbResponse(myXml)
        self.assertEqual(myResponse.nresponses(),1,"Number of responses not equal to 1")
        self.assertEqual(myResponse.is_response(0),True,"Not recognised as a response")
        self.assertEqual(myResponse.status(0),"OK","Incorrect status returned")
        self.assertEqual(myResponse.result(0),"This is a result",
                         "Incorrect result returned")
        self.assertEqual(myResponse.response_id(0),"","Incorrect id returned")
        
    def testSingleItem(self):
        """Test unwrapping a single item with a response id."""
        
        myXml = "<db_response><status>OK</status><result>True</result><response_id>request#1</response_id></db_response>"
        myResponse = dbsocket.dbResponse(myXml)
        self.assertEqual(myResponse.nresponses(),1,"Number of responses not equal to 1")
        self.assertEqual(myResponse.is_response(0),True,"Not recognised as a response")
        self.assertEqual(myResponse.status(0),"OK","Incorrect status returned")
        self.assertEqual(myResponse.result(0),"True",
                         "Incorrect result returned")
        self.assertEqual(myResponse.response_id(0),"request#1","Incorrect id returned")

    def testMultipleItems(self):
        """Test unwrapping multiple items."""
        
        myXml = "<db_response><status>OK</status><result><list><item>item1</item><item>item2</item></list></result><response_id>request#1</response_id></db_response>"
        myResponse = dbsocket.dbResponse(myXml)
        self.assertEqual(myResponse.nresponses(),1,"Number of responses not equal to 1")
        self.assertEqual(myResponse.is_response(0),True,"Not recognised as a response")
        self.assertEqual(myResponse.status(0),"OK","Incorrect status returned")
        result = myResponse.result(0)
        values = ("item1","item2")
        self.assertEqual(len(result),len(values),"Wrong number of list values returned")
        for i in range(0,len(result)):
            self.assertEqual(result[i],values[i],"Incorrect list value returned")
        self.assertEqual(myResponse.response_id(0),"request#1","Incorrect id returned")

    def testEmptyItems(self):
        """Test unwrapping a list with empty items."""
        
        myXml = "<db_response><status>OK</status><result><list><item></item><item></item></list></result><response_id>request#1</response_id></db_response>"
        myResponse = dbsocket.dbResponse(myXml)
        self.assertEqual(myResponse.nresponses(),1,"Number of responses not equal to 1")
        self.assertEqual(myResponse.is_response(0),True,"Not recognised as a response")
        self.assertEqual(myResponse.status(0),"OK","Incorrect status returned")
        result = myResponse.result(0)
        values = ("","")
        self.assertEqual(len(result),len(values),"Wrong number of list values returned")
        for i in range(0,len(result)):
            self.assertEqual(result[i],values[i],"Incorrect list value returned")
        self.assertEqual(myResponse.response_id(0),"request#1","Incorrect id returned")

class XMLBroadcastTest(unittest.TestCase):
    
    def testBroadcast(self):
        """Test unwrapping a broadcast message."""
        
        myXml = "<db_broadcast><message>Dummy broadcast message</message><project>DUMMY</project><jobid>0</jobid><operation>test</operation><agent>test_dbsocket</agent></db_broadcast>"
        myResponse = dbsocket.dbResponse(myXml)
        self.assertEqual(myResponse.nresponses(),1,"Number of responses not equal to 1")
        self.assertEqual(myResponse.is_broadcast(0),True,"Not recognised as a broadcast")
        self.assertEqual(myResponse.message(0),"Dummy broadcast message",
                         "Incorrect broadcast message returned")
        self.assertEqual(myResponse.project(0),"DUMMY",
                         "Incorrect broadcast project returned")
        self.assertEqual(myResponse.jobid(0),"0",
                         "Incorrect broadcast jobid returned")
        self.assertEqual(myResponse.operation(0),"test",
                         "Incorrect broadcast operation returned")
        self.assertEqual(myResponse.agent(0),"test_dbsocket",
                         "Incorrect broadcast agent returned")
    
    def testMinimalBroadcast(self):
        """Test unwrapping 'minimal' broadcast message."""
        
        myXml = "<db_broadcast><message>Minimal broadcast message</message></db_broadcast>"
        myResponse = dbsocket.dbResponse(myXml)
        self.assertEqual(myResponse.nresponses(),1,"Number of responses not equal to 1")
        self.assertEqual(myResponse.is_broadcast(0),True,"Not recognised as a broadcast")
        self.assertEqual(myResponse.message(0),"Minimal broadcast message",
                         "Incorrect broadcast message returned")
        self.assertEqual(myResponse.project(0),"",
                         "Incorrect broadcast project returned")
        self.assertEqual(myResponse.jobid(0),"",
                         "Incorrect broadcast jobid returned")
        self.assertEqual(myResponse.operation(0),"",
                         "Incorrect broadcast operation returned")
        self.assertEqual(myResponse.agent(0),"",
                         "Incorrect broadcast agent returned")

    def testBadBroadcast(self):
        """Test unwrapping a broadcast with no content."""
        
        myXml = "<db_broadcast></db_broadcast>"
        myResponse = dbsocket.dbResponse(myXml)
        self.assertEqual(myResponse.nresponses(),1,"Number of responses not equal to 1")
        self.assertEqual(myResponse.is_broadcast(0),True,"Not recognised as a broadcast")
        self.assertEqual(myResponse.message(0),"",
                         "Incorrect broadcast message returned")
        self.assertEqual(myResponse.project(0),"",
                         "Incorrect broadcast project returned")
        self.assertEqual(myResponse.jobid(0),"",
                         "Incorrect broadcast jobid returned")
        self.assertEqual(myResponse.operation(0),"",
                         "Incorrect broadcast operation returned")
        self.assertEqual(myResponse.agent(0),"",
                         "Incorrect broadcast agent returned")

class XMLSpecialCasesTest(unittest.TestCase):

    def testMultipleResponses(self):
        """Test processing multiple responses in a single input"""
        
        myXml = "<db_response><status>OK</status><result>True</result><response_id>request#1</response_id></db_response>\n<db_response><status>FAILED</status><result>This one failed!</result><response_id>request#2</response_id></db_response>"
        myResponse = dbsocket.dbResponse(myXml)
        #
        self.assertEqual(myResponse.nresponses(),2,"Number of responses not equal to 2")
        #
        self.assertEqual(myResponse.is_response(0),True,
                         "#1 not recognised as a response")
        self.assertEqual(myResponse.status(0),"OK","Incorrect status returned #1")
        self.assertEqual(myResponse.result(0),"True",
                         "Incorrect result returned #1")
        self.assertEqual(myResponse.response_id(0),"request#1",
                         "Incorrect id returned #1")
        #
        self.assertEqual(myResponse.is_response(1),True,
                         "#2 not recognised as a response")
        self.assertEqual(myResponse.status(1),"FAILED","Incorrect status returned #2")
        self.assertEqual(myResponse.result(1),"This one failed!",
                         "Incorrect result returned #2")
        self.assertEqual(myResponse.response_id(1),"request#2",
                         "Incorrect id returned #2")

    def testUnrecognisedXML(self):
        """Test dealing with unrecognised data."""

        myXml = "<db_command>This should be unrecognised</db_command>"
        myResponse = dbsocket.dbResponse(myXml)
        self.assertEqual(myResponse.nresponses(),0,"Number of responses not equal to 1")

if __name__ == "__main__":
    unittest.main()
