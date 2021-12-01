#
#     Copyright (C) 2004  Kevin Cowtan
#     phaseweight script template
#

1 mtzin $HKLIN
1 colin-fo /*/*/\\\[$FP,$SIGFP\\\]
{ [StringSame $MODECOEFF1 MAPCOEFF] } colin-fc-1 /*/*/\\\[$FMAP1,$PHIMAP1\\\]
{ [StringSame $MODECOEFF1 HLCOEFF]  } colin-hl-1 /*/*/\\\[$HLA1,$HLB1,$HLC1,$HLD1\\\]
{ [StringSame $MODECOEFF1 PWCOEFF]  } colin-phifom-1 /*/*/\\\[$PHI1,$FOM1\\\]
{ [StringSame $MODECOEFF2 MAPCOEFF] } colin-fc-2 /*/*/\\\[$FMAP2,$PHIMAP2\\\]
{ [StringSame $MODECOEFF2 HLCOEFF]  } colin-hl-2 /*/*/\\\[$HLA2,$HLB2,$HLC2,$HLD2\\\]
{ [StringSame $MODECOEFF2 PWCOEFF]  } colin-phifom-2 /*/*/\\\[$PHI2,$FOM2\\\]
$MODEMATCH mtzout $HKLOUT
$MODEMATCH colout $COLOUT
{!$MODEMATCH} no-origin-hand
1 resolution-bins $NRESBINS
