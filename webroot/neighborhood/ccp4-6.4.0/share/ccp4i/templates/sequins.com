#
#     Copyright (C) 2006-2007  Kevin Cowtan
#     Sequins script template
#

1 title $TITLE
1 pdbin-ref $XYZINref 
1 mtzin-ref $HKLINref 
1 colin-ref-fo /*/*/\\\[$FPref,$SIGFPref\\\]
1 colin-ref-hl /*/*/\\\[$HLAref,$HLBref,$HLCref,$HLDref\\\]
1 pdbin-wrk $XYZINwrk
1 mtzin-wrk $HKLINwrk
1 colin-wrk-fo /*/*/\\\[$FPwrk,$SIGFPwrk\\\]
$USEWRKHL colin-wrk-hl /*/*/\\\[$HLAwrk,$HLBwrk,$HLCwrk,$HLDwrk\\\]

$USEOMIT side-chain-omit
$USECORR correlation-mode
1 resolution $RESOLUTION_MAX
