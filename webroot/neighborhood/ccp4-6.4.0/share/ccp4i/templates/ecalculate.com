#
#     Copyright (C) 2004  Kevin Cowtan
#     ecalculate script template
#

1 mtzin $HKLIN
1 mtzout $HKLOUT
1 colin-fo /*/*/\\\[$FP,$SIGFP\\\]
1 colout $COLOUT
