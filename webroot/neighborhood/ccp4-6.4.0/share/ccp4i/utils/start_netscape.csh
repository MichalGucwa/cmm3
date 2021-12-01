#!/bin/csh
setenv MOZILLA_HOME /usr/local/netscape
# Its advisable to undo what was done in ccp4.setup
setenv XUSERFILESEARCHPATH " "
setenv XFILESEARCHPATH " "
netscape file:$CCP4I_TOP/help/index.html >& /dev/null &
#netscape30 file:$CCP4I_TOP/help/start.html >& /dev/null &
