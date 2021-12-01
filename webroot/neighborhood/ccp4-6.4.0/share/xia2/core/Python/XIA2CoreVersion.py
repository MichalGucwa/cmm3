#!/usr/bin/env python
# XIA2CoreVersion.py
#
#   Copyright (C) 2006 CCLRC, Graeme Winter
#
#   This code is distributed under the BSD license, a copy of which is 
#   included in the root directory of this package.
#
# 6th June 2006
# 
# A file containing the version number of the current xia2 core.

VersionNumber = "0.3.5.1"

Version = "XIA2 Core %s" % VersionNumber
CVSTag = "xia2core-%s" % VersionNumber.replace('.', '_')
Directory = "xia2core-%s" % VersionNumber

if __name__ == '__main__':
    print 'This is XIA 2 Core version %s' % VersionNumber
    print 'This should be in a directory called "%s"' % Directory
    print 'And should be CVS tagged as "%s"' % CVSTag

    
