#
#     Copyright (C) 2004  Kevin Cowtan
#     sfweight script template
#

1 mtzin  $HKLIN
1 colin-fo /*/*/\\\[$FP,$SIGFP\\\]
1 colin-fc /*/*/\\\[$FC,$PHIC\\\]
$MODEFREE colin-free /*/*/\\\[$FREE\\\]
1 mtzout $HKLOUT
1 colout $COLOUT

$MODENRFL num-reflns $VALUNRFL
