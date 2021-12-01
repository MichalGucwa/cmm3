#
#     Copyright (C) 2004  Kevin Cowtan
#     sfcalcmodel script template
#

1 mtzin  $HKLIN
1 pdbin  $XYZIN
1 colin-fo /*/*/\\\[$FP,$SIGFP\\\]
$MODEFREE colin-free /*/*/\\\[$FREE\\\]
1 mtzout $HKLOUT
1 colout $COLOUT

{!$MODEBULK} no-bulk
$MODENRFL num-reflns $VALUNRFL
