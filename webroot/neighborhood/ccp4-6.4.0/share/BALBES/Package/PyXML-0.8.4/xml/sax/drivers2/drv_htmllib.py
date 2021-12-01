"""
A SAX 2.0 driver for htmllib.

$Id$
"""

import types, string

from xml.sax import SAXNotSupportedException, SAXNotRecognizedException
from xml.sax.xmlreader import IncrementalParser
from drv_sgmllib import SgmllibDriver

class HtmllibDriver(SgmllibDriver):

    from htmlentitydefs import entitydefs

# ---

def create_parser():
    return HtmllibDriver()
