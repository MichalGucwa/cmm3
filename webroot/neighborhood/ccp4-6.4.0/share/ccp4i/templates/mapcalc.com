#
#     Copyright (C) 2004  Kevin Cowtan
#     mapcalc script template
#

1 mtzin $HKLIN
{ [StringSame $MODECOEFF MAPCOEFF] } colin-fc /*/*/\\\[$FMAP,$PHIMAP\\\]
{ [StringSame $MODECOEFF HLCOEFF]  } colin-fo /*/*/\\\[$FP,$SIGFP\\\]
{ [StringSame $MODECOEFF HLCOEFF]  } colin-hl /*/*/\\\[$HLA,$HLB,$HLC,$HLD\\\]
$MODEMAP    mapout $MAPOUT
$MODESTAT   stats
$MODESTAT   stats-radius $RADIUS
$RESOLUTION resolution $RESOLUTION_MAX
$GRID       grid $GRID_1,$GRID_2,$GRID_3
$MODEEFILTER  e-limit  $VALUEFILTER
$MODEEWEIGHT  e-weight $VALUEWEIGHT
$MODEORIGREM  origin-removal
