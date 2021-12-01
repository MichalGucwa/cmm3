########################################################################
#
# File Name:            implementation.py
#
#
"""
WWW: http://4suite.com/4DOM         e-mail: support@4suite.com

Copyright (c) 2000 Fourthought Inc, USA.   All Rights Reserved.
See  http://4suite.com/COPYRIGHT  for license and copyright information
"""

import os, sys, string, cStringIO
xml_path1= os.path.join(os.getenv("BALBES_ROOT"),"PyXML-0.8.4/xml/dom/")
xml_path2= os.path.join(os.getenv("BALBES_ROOT"),"PyXML-0.8.4/xml/dom/ext")
xml_path3= os.path.join(os.getenv("BALBES_ROOT"),"PyXML-0.8.4/xml/dom/ext/reader")
xml_path4= os.path.join(os.getenv("BALBES_ROOT"),"PyXML-0.8.4/xml/dom/html")
sys.path.append(xml_path1)
sys.path.append(xml_path2)
sys.path.append(xml_path3)
sys.path.append(xml_path4)

# from xml.dom import DOMImplementation
import DOMImplementation

# Add the HTML feature
DOMImplementation.FEATURES_MAP['HTML'] = 2.0

class HTMLDOMImplementation(DOMImplementation.DOMImplementation):

    def __init__(self):
        DOMImplementation.DOMImplementation.__init__(self)

    def createHTMLDocument(self, title):
        from xml.dom.html import HTMLDocument
        doc = HTMLDocument.HTMLDocument()
        h = doc.createElement('HTML')
        doc.appendChild(h)
        doc._set_title(title)
        return doc

    def _4dom_createHTMLCollection(self,list=None):
        if list is None:
            list = []
        from xml.dom.html import HTMLCollection
        hc = HTMLCollection.HTMLCollection(list)
        return hc
