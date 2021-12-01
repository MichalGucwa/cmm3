# $Id: temp.tcl,v 1.8 2010/01/21 16:02:26 rmk65 Exp $
package require Itcl
package require Itk
namespace import itcl::*
namespace import itk::*

lappend auto_path .
package require balloonwidget

package require toolbutton

proc ex { args } {
    puts stdout $args
}

Toolbutton .t1 \
    -type radio \
    -group g1 \
    -command [list ex .t1]

Toolbutton .t2 \
    -type radio \
    -group g1 \
    -command [list ex .t2]

Toolbutton .t3 \
    -type radio \
    -group g2 \
    -command [list ex .t3]

Toolbutton .t4 \
    -type radio \
    -group g2 \
    -command [list ex .t4]

grid .t1 .t2
grid .t3 .t4

