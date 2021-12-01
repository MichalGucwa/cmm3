#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
{ [IfSet $THRESHHOLD] } threshhold 
- $THRESHHOLD_RMS rms 
- 1 $THRESHHOLD
- $NEGATIVES NEGATIVES
{ [IfSet $NUMPEAKS ] } numpeaks $NUMPEAKS
{ $PATTERSON_VECTORS } patterson
$IFFRACOUT output brookhaven frac
{[IfSet $BFACTOR] } bfactor $BFACTOR $OCCUPANCY
{[IfSet $RESIDUE] } residue $RESIDUE
{[IfSet $ATNAME] } atname $ATNAME
{[IfSet $CHAIN] } chain $CHAIN
{ $OUTPUT_XML } XMLOUT
