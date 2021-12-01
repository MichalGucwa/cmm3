#
#     Copyright (C) 2004  Kevin Cowtan
#     Hltofom script template
#

1 mtzin $HKLIN
{ [StringSame $CONVERT HLTOFOM] } colin-hl /*/*/\\\[$HLA,$HLB,$HLC,$HLD\\\]
{ [StringSame $CONVERT FOMTOHL] } colin-phifom /*/*/\\\[$PHI,$FOM\\\]
1 mtzout $HKLOUT
1 colout $COLOUT
