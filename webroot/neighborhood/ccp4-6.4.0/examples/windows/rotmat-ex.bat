::!/bin/sh
::
::c  So  far program messages are:
::c    Input/Output MERLOT ALPHA  BETA   GAMMA
::c    Input/Output MERLOT THETA1 THETA2 THETA3
::c    Input/Output MERLOT PHI    PSI    KAPPA
::c    Input/Output MERLOT MATRIX
::c    Input/Output CCP4   ALPHA  BETA   GAMMA
::c    Input/Output CCP4   PHI    PSI    KAPPA
::c    Input/Output CCP4   MATRIX
::c    Input/Output XPLOR  THETA1 THETA2 THETA3
::c    Input/Output XPLOR  PHI    PSI    KAPPA
::c    Input/Output XPLOR  MATRIX
::  Keywords symm cell orth are not used fully.
::  Loads of output - not all useful! 
::   At present make sure your orthogonalising conventions are
:: the same for ALMN or MERLOT as the XPLOR one. XPLOR IS RIGID!!!
::   always NCODE = 1.  XPLOR spherical polars are defined differently 
::   to those in ALMN/MERLOT.
::

rotmat      < %SCRIPTWIN%\rotmat.dat
