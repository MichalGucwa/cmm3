#
#     Copyright (C) 2004  Kevin Cowtan
#     mapcalc script template
#

1 mtzin $HKLIN
1 mapout $MAPOUT
1 colin-fo /*/*/\\\[$FP,$SIGFP\\\]
$RESOLUTION resolution $RESOLUTION_MAX
$GRID       grid $GRID_1,$GRID_2,$GRID_3
