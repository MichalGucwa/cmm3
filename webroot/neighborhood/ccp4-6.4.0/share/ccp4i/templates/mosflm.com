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
# MOSFLM: COMMAND SCRIPT
##################################################

1 TITLE $TITLE

##################################################
# GENFILE
##################################################
1 GENFILE $GENFILE

##################################################
# IMAGE PARAMETERS
##################################################
1 TEMPLATE $TEMPLATE

IF { $USE_CWD } THEN
  1 DIRECTORY .
ELSE
  # Add a DIRECTORY keyword for each directory defined by
  # the user
  LOOP N 1 $NDIRECTORIES
  1 DIRECTORY $DIRECTORY($N)
  ENDLOOP
ENDIF

##################################################
# CRYSTAL PARAMETERS
##################################################
1 SYMM $SPACEGROUP

# CELL is commented out in the script but should
# still be visible to the user
1   # CELL $CELL_1 $CELL_2 $CELL_3 
- 1 # $CELL_4 $CELL_5 $CELL_6

##################################################
# MATRIX FILE
##################################################
1 MATRIX $MATRIX_FILE

##################################################
# DETECTOR PARAMETERS
##################################################
$USE_DETECTOR DETECTOR $DETECTOR
IF { [IfSet $DETECTOR_OMEGA] }
  -- 1 OMEGA $DETECTOR_OMEGA
ENDIF
-- $DETECTOR_REVERSEPHI REVERSEPHI
1 BEAM
- $BEAM_SWUNG SWUNG_OUT
- 1 $BEAM_X $BEAM_Y
IF { [IfSet $BACKSTOP_X] && [IfSet $BACKSTOP_Y] }
  1 BACKSTOP CENTRE $BACKSTOP_X $BACKSTOP_Y
  IF { [IfSet $BACKSTOP_R] }
    - 1 RADIUS $BACKSTOP_R
  ENDIF
ENDIF
1 DISTANCE $DISTANCE 
1 TWOTHETA $TWOTHETA
IF { [IfSet $SEPARATION_X] && [IfSet $SEPARATION_Y] }
  1 SEPARATION $SEPARATION_X $SEPARATION_Y
  - $SEPARATION_CLOSE CLOSE
ENDIF
{ [IfSet $GAIN] } GAIN $GAIN
{ [IfSet $ADCOFFSET] } ADCOFFSET $ADCOFFSET
{ [IfSet $NULLPIX] } NULLPIX $NULLPIX

##################################################
# INTEGRATION PARAMETERS
##################################################
IF { [IfSet $RESOLUTION_MAX] }
1 RESOLUTION $RESOLUTION_MAX
- { [IfSet $RESOLUTION_MIN] } $RESOLUTION_MIN
ENDIF
IF { [IfSet $OVERLOAD_CUTOFF] || [IfSet $OVERLOAD_NOVER] }
1 OVERLOAD
- { [IfSet $OVERLOAD_NOVER] } NOVER $OVERLOAD_NOVER
- { [IfSet $OVERLOAD_CUTOFF] } CUTOFF $OVERLOAD_CUTOFF
ENDIF
1 PROFILE
IF { [IfSet $PROFILE_TOL_MIN] && [IfSet $PROFILE_TOL_MAX] }
- 1 TOLERANCE $PROFILE_TOL_MIN $PROFILE_TOL_MAX
ENDIF
IF { $PROFILE_USE_LINES }
  IF { [IfSet $PROFILE_XLINES_1] && [IfSet $PROFILE_XLINES_2]}
    - 1 XLINES $PROFILE_XLINES_1 $PROFILE_XLINES_2 $PROFILE_XLINES_3 $PROFILE_XLINES_4 $PROFILE_XLINES_5 $PROFILE_XLINES_6
  ENDIF
  IF { [IfSet $PROFILE_YLINES_1] && [IfSet $PROFILE_YLINES_2]}
    - 1 YLINES $PROFILE_YLINES_1 $PROFILE_YLINES_2 $PROFILE_YLINES_3 $PROFILE_YLINES_4 $PROFILE_YLINES_5 $PROFILE_YLINES_6
  ENDIF
ENDIF
- $PROFILE_OVERLOADS OVERLOADS
- $PROFILE_PARTIALS PARTIALS
- $PROFILE_FIXBOX FIXBOX
IF {! $PROFILE_OPTIMISE }
- 1 NOOPT
ENDIF

##################################################
# DISTORTION
##################################################
{[IfSet $DISTORTION_YSCAL]} DISTORTION YSCAL $DISTORTION_YSCAL
{[IfSet $DISTORTION_ROFF]} DISTORTION ROFF $DISTORTION_ROFF
{[IfSet $DISTORTION_TOFF]} DISTORTION TOFF $DISTORTION_TOFF
{[IfSet $DISTORTION_TILT]} DISTORTION TILT $DISTORTION_TILT
{[IfSet $DISTORTION_TWIST]} DISTORTION TWIST $DISTORTION_TWIST

##################################################
# MOSAICITY
##################################################
{ [IfSet $MOSAICITY] } MOSAIC $MOSAICITY

##################################################
# WAVELENGTH
##################################################
{ [IfSet $WAVELENGTH] } WAVELENGTH $WAVELENGTH

##################################################
# RASTER PARAMETERS
##################################################
$USE_RASTER RASTER $RASTER_1 $RASTER_2 $RASTER_3 $RASTER_4 $RASTER_5

##################################################
# SYNCHROTRON PARAMETERS
##################################################

IF { $SYNCHROTRON }
{ [IfSet $POLARISATION] } SYNCHROTRON POLARISATION $POLARISATION
{ [IfSet $DIVERGENCE_X] } DIVERGENCE $DIVERGENCE_X
- { [IfSet $DIVERGENCE_Y] } $DIVERGENCE_Y
{ [IfSet $DISPERSION] } DISPERSION $DISPERSION
ENDIF

##################################################
# DATA HARVESTING/DATASET INFO
##################################################

1 HARVEST 
IF { [StringSame $HARVEST_MODE NOHARVEST] }
# Turn harvesting off for MOSFLM
- 1 OFF
ELSE
# Turn harvesting on for MOSFLM
- 1 ON
AT { [FileJoin [GetEnvPath CCP4I_TOP] templates harvest.com ] }
ENDIF

1 XNAME $HARVEST_XNAME
# Write PNAME and DNAME even if harvesting is turned off
IF { [StringSame $HARVEST_MODE NOHARVEST] }
1 PNAME $HARVEST_PNAME
1 DNAME $HARVEST_DNAME
ENDIF

##################################################
# GO MOSFLM GO
##################################################

LOOP N 1 $NRUNS
  ###########################
  # POSTREFINEMENT COMMANDS
  ###########################
  $POSTREF($N) POSTREF
  IF { $POSTREF_MULTI($N) }
  - 1 MULTI
  ELSE
  - 1 NOMULTI
  ENDIF
  - 1 SDFAC $POSTREF_SDFAC($N)

  IF { $POSTREF_FIX_ALL($N) || $POSTREF_FIX_MOSAIC($N) }
  $POSTREF($N) POSTREF FIX
  - $POSTREF_FIX_ALL($N) ALL
  - $POSTREF_FIX_MOSAIC($N) MOSAIC
  ENDIF

  - { [IfSet $POSTREF_WIDTH($N)] } WIDTH $POSTREF_WIDTH($N)
  - { [IfSet $POSTREF_MOSADD($N)] } MOSADD $POSTREF_MOSADD($N)
  - { [IfSet $POSTREF_MOSSMOOTH($N)] } MOSSMOOTH $POSTREF_MOSSMOOTH($N)

  ###########################
  # PROCESS COMMANDS
  ########################### 
  LOOP I 1 $NPROCESS($N)
    1 PROCESS $PROCESS_FIRST($N,$I) $PROCESS_LAST($N,$I)
    - { [IfSet $PROCESS_START($N,$I)] } START $PROCESS_START($N,$I)
    - { [IfSet $PROCESS_ANGLE($N,$I)] } ANGLE $PROCESS_ANGLE($N,$I)
    - $PROCESS_USE_ADD($N,$I) ADD $PROCESS_ADD($N,$I)
    - $PROCESS_USE_BLOCK($N,$I) BLOCK $PROCESS_BLOCK($N,$I)
  ENDLOOP
  1 RUN
ENDLOOP
