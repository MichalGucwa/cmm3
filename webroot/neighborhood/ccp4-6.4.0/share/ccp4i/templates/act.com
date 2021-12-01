#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
##################################################
# ACT: COMMAND SCRIPT
##################################################
1 symm $SPACE_GROUP
1 contact $CONTACT_MODE $MIN_DIST $MAX_DIST
{ [IfSet $ACT_SHORT ] } short $ACT_SHORT

# B-FACTOR MONITORING
# Turn this off by setting an unreasonable threshold
IF { $ACT_IFBMONI }
  1 BMONI $ACT_BMONI
ELSE
  1 BMONI 10000
ENDIF

1 END
