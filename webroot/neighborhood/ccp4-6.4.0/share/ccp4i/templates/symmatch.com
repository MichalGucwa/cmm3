#
#     Copyright (C) 2010  Kevin Cowtan
#     symmatch script template
#

1 pdbin $XYZIN1
1 pdbin-ref $XYZIN2
1 pdbout $XYZOUT
$ORIGINHAND origin-hand
1 connectivity-radius $CONNECTRAD
