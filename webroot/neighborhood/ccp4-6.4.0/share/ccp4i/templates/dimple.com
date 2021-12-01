#
#
#     Copyright (C) 2010 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#
##################################################
# MrBUMP: COMMAND SCRIPT
##################################################

#1 NCYCRB $NCYCRB
#1 NCYCRR $NCYCRR

1 LABIN IMEAN=$IMEAN SIGIMEAN=$SIGIMEAN
1 END
