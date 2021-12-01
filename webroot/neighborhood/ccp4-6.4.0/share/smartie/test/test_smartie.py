"""This module provides unit tests to verify that functions in the module
smartie.py are behaving correctly."""

__version__ = "$Revision: 1.1 $"

import sys
# Allows test to be run from smartie directory,
# or from the test directory
sys.path.append("..")
sys.path.append(".")
import unittest
import smartie

class PatternMatchTest(unittest.TestCase):

    def testIsCCP4Banner6099a(self):
        """Test matching a CCP4 6.0.99a banner."""
        
        text = """ 
 ###############################################################
 ###############################################################
 ###############################################################
 ### CCP4 6.0.99a: SORTMTZ            version 6.0.99a   : 06/09/05##
 ###############################################################
 User: pjx  Run date: 20/12/2007 Run time: 09:14:21 


 Please reference: Collaborative Computational Project, Number 4. 1994.
 "The CCP4 Suite: Programs for Protein Crystallography". Acta Cryst. D50, 760-763.
 as well as any specific reference in the program write-up.

        """
        self.assertNotEqual(len(smartie.patternmatch().isccp4banner(text)),0)
        
    def testIsCCP4Banner599(self):
        """Test matching a standard CCP4 5.99 banner."""
        
        text = "\n ###############################################################\n ###############################################################\n ###############################################################\n ### CCP4 5.99: SORTMTZ            version 5.99      : 06/09/05##\n ###############################################################\n User: pjx  Run date: 31/ 1/2006 Run time: 16:02:55\n\n Please reference: Collaborative Computational Project, Number 4. 1994.\n \"The CCP4 Suite: Programs for Protein Crystallography\". Acta Cryst. D50, 760-763.\n as well as any specific reference in the program write-up.\n\n"
        self.assertNotEqual(len(smartie.patternmatch().isccp4banner(text)),0)

    def testIsCCP4Banner60(self):
        """Test matching a standard CCP4 6.0 banner."""
        
        text = " ###############################################################\n ###############################################################\n ###############################################################\n ### CCP4 6.0: dm                 version 6.0       :         ##\n ###############################################################\n User: pjx  Run date: 30/ 4/2007 Run time: 17:15:44"
        self.assertNotEqual(len(smartie.patternmatch().isccp4banner(text)),0)

    def testIsCCP4Banner41(self):
        """Test matching a standard CCP4 4.1 banner."""
        
        text = "1###############################################################\n ###############################################################\n ###############################################################\n ### CCP4 4.1: OASIS              version 4.1       : 12/02/01##\n ###############################################################\n User: pjx  Run date: 14/ 5/01  Run time:15:24:36\n"
        self.assertNotEqual(len(smartie.patternmatch().isccp4banner(text)),0)

    def testIsPhaserBanner133(self):
        """Test matching a banner from Phaser 1.3.3."""

        text = "#####################################################################################\n#####################################################################################\n#####################################################################################\n### CCP4 PROGRAM SUITE: Phaser                                              1.3.3 ###\n#####################################################################################\nUser:         mdw\nRun time:     Thu Feb 15 19:47:29 2007\nVersion:      1.3.3\nRelease Date: Wed Oct 18 09:19:13 2006\n"
        self.assertNotEqual(len(smartie.patternmatch().isccp4banner(text)),0)

    def testIsPhaserBanner132(self):
        """Test matching a banner from Phaser 1.3.2."""

        text = "#####################################################################################\n#####################################################################################\n#####################################################################################\n### CCP4 PROGRAM SUITE: Phaser                                              1.3.2 ###\n#####################################################################################\nUser:         pjx\nRun time:     Wed May 17 09:27:42 2006\nVersion:      1.3.2\nOS type:      linux\nRelease Date: Sun Feb  5 17:29:18 2006\n"
        self.assertNotEqual(len(smartie.patternmatch().isccp4banner(text)),0)

if __name__ == "__main__":
    unittest.main()
