# $Id: hack.tcl,v 1.8 2010/01/21 16:02:24 rmk65 Exp $
set phi 279.0
foreach i_image [$::session getImages] {
    $i_image setPhi $phi [expr $phi + 1.0]
    set phi [expr $phi + 1.0]
}
