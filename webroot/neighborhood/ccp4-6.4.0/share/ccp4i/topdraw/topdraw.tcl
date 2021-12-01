# TopDraw - a sketchpad for protein topology diagrams
# Copyright (c) Charlie Bond 2001 - 2002 
# Please cite
#               Bond, C.S. (2003) Bioinformatics, 19, 311-312 
# if used for publication.

#  This file is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2, or (at your option)
#  any later version.

#  This file is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#  A copy of the GNU General Public License is available from
#  the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
#  Boston, MA 02111-1307, USA.

#cvs_rcs "TopDraw $Date$"

set topdraw_version "Sep 2002"

global o count e moveall SW SH
set e expr
set SW [$e [winfo screenwidth .] -20]
set SH [$e [winfo screenheight .] -60]
wm geometry . ${SW}x${SH}+10-30

puts "TopDraw ($topdraw_version). Copyright (c) Charlie Bond, Dundee, 2000-2002.\nC.S.Bond@dundee.ac.uk\nhttp://stein.bioch.dundee.ac.uk/~charlie/scripts/topdraw.html\nPlease cite: Bond, C.S. (2003) Bioinformatics, 19, 311-312 if used for publication.\n"

# Make sure we have suitable Tk version 
if { [catch "set system(TK_VERSION) $tk_version"] } {
    puts "TopDraw error initialising Tcl/TK 
perhaps because DISPLAY variable is not set appropriately"
  exit 1
}
if {$system(TK_VERSION) < 8.0} {
    puts "TopDraw requires Tk 8.0 or higher, this is only $tk_version"
    exit 1
}

set o(c,ft) Helvetica-Medium
set o(c,w) 2
set o(c,lc) Black
set o(c,tc) Black
set o(c,oc) Red
set o(c,fn) 16
set o(c,ty) uparrowhead
set count 0
set moveall "single object"
wm title . "TopDraw ($topdraw_version)"
frame .td 
pack configure .td  -anchor nw

# but is the frame holding the buttons
set but .td.buttons
frame $but -w 150 -he $SH -bg white
# canv is the canvas where the diagrams are drawn
set canv .canvas
canvas $canv -w [$e $SW - 150] -he $SH  -bg white -closeenough 100.0
# vport is the scrollable canvas used to hold the buttons
# scrl is the scrollbar
set scrl .td.ysbar
set vport $but.vport
canvas $vport -yscrollcommand "$scrl set" -he $SH
scrollbar $scrl -command "$vport yview"
# frame is another frame which will be embedded into vport
set frame $vport.f
frame $frame
pack $frame -side left -expand yes -fill both
$vport create window 0 0 -anchor nw -window $frame
# Pack everything into the window
pack $scrl -side left -fill y
pack $but -in .td -side left -padx 0 -fill x
pack $canv -in .td -side left -expand yes -fill both

# Bindings for the canvas
bind $canv <Button-1> {ButtonClick %x %y}
bind $canv <Motion> {DrawBox %x %y}
bind $canv <Button-2> {Button2Click %x %y}
bind $canv <Button2-Motion> {Button2Motion %x %y}
# Cant tell if a 3-button mouse is used, so bind button3 too for
# PC types with 2-button mice
bind $canv <Button-3> {Button2Click %x %y}
bind $canv <Button3-Motion> {Button2Motion %x %y}

# =====================================================
# Initialise names of buttons labels and other widgets
# If we want to change the widget names or paths later
# then we only need to do it once

# Frames in control panel for grouping different controls
# Frame 1: buttons for drawing
set frame1 [frame $frame.f1 -bg white]
# Frame 2: controls for style etc
set frame2 [frame $frame.f2 -bg white]
# Frame 3: controls for program function
set frame3 [frame $frame.f3 -bg white]
pack $frame1 $frame2 $frame3 -side top -expand yes -fill x

# Drawing controls (frame 1)
set title   $frame1.title
set delete  $frame1.delete
set uparrowhead $frame1.uparrowhead
set dnarrowtail $frame1.dnarrowtail
set helixtop $frame1.helixtop
set nterm $frame1.nterm
set cterm $frame1.cterm
set uparrowshaft $frame1.uparrowshaft
set dnarrowshaft $frame1.dnarrowshaft
set helixshaft $frame.helixshaft
set line7 $frame1.line7
set line8 $frame1.line8
set uparrowtail $frame1.uparrowtail
set dnarrowhead $frame1.dhnarrowhead
set helixbottom $frame1.helixbottom
set line10 $frame1.line10
set line11 $frame1.line11
set ltarrowhead $frame1.ltarrowhead
set ltarrowshaft $frame1.ltarrowshaft
set ltarrowtail $frame1.ltarrowtail
set ltnterm $frame1.ltnterm
set ltcterm $frame1.ltcterm
set rtarrowtail $frame1.rtarrowtail
set rtarrowshaft $frame1.rtarrowshaft
set rtarrowhead $frame1.rtarrowhead
set line7b $frame1.line7b
set line8b $frame1.line8b
set lthelixtop $frame1.lthelixtop
set lthelixshaft $frame1.lthelixshaft
set lthelixbottom $frame1.lthelixbottom
set line10b $frame1.line10b
set line11b $frame1.line11b
set line01 $frame1.line01
set line02 $frame1.line02
set line4 $frame1.line4
set line6 $frame1.line6
set line03 $frame1.line03
set line5 $frame1.line5

set line12a $frame1.line12a
set line12b $frame1.line12b

set line13a $frame1.line13a 
set line13b $frame1.line13b
set line14a $frame1.line14a
set line14b $frame1.line14b
set line15a $frame1.line15a
set line15b $frame1.line15b
set line16a $frame1.line16a
set line16b $frame1.line16b

# Style controls (frame 2)
set move      $frame2.move
set txt       $frame2.txt
set txtstr    $frame2.txtstr
set linewidth $frame2.linewidth
set textfn    $frame2.textfn
set textft    $frame2.textft
set lwtext    $frame2.lwtext
set lctext    $frame2.lctext
set tctext    $frame2.tctext
set ctext     $frame2.ctext
set fntext    $frame2.fntext
set movetext  $frame2.movetext
set linec     $frame2.linec
set colour    $frame2.colour
set textc     $frame2.textc

# Program controls (frame 3)
set save    $frame3.save
set open    $frame3.open
set help    $frame3.help
set example $frame3.example
set clear   $frame3.clear
set print   $frame3.print
set exit    $frame3.exit

# End of widget name initialisation section
#==========================================

# Define the buttons
#Base64 encoded GIFs
button $uparrowhead   -command {set o(c,ty) "uparrowhead"} -image  [image create photo -format gif -data "R0lGODlhHgAeAKUAAP7+/v///8zMzPT09KOjowAAAFFRUcHBwY6OjigAABQAAAoKCh4AAOAA
ALcAABQUFLe3t9YAAP8AAMEAAP4AAK2tra0AAMsAAIQAANbW1piYmDIAAMvLy5mZmTIeHv6Z
mf6YmP//////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////yH+Dk1hZGUgd2l0
aCBHSU1QACwAAAAAHgAeAAAGzUBAQDgEGImBpDJ5bDqJzqW0+KxGp0qrUXrFUrXQppcJ1o6/
5S42bZUKBln2c0koGA5kuTiJKCQUBXhgZ3wLDA0OCg8Qg2d1DBESEhMFDwdmY30JDZKSE4CX
VZmGnJ2SiYuiWI+Rpp2UlnNTmqWukhSfgWqFh7amFBSojEdSrL6/wLChSAG0x8jJoFtJFQsF
FhfZrb4U2dkYlRlNGgXl5hvA6eoU5u0ce0sd6OvqBQJcYPL09QJ6AB0ePggcOBCEPX8IEypc
yLChw4dVggAAOw=="]
button $dnarrowtail -command {set o(c,ty) "dnarrowtail"} -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v///zMzM4SEhAAAAAB6AQCYAgA9AGZmZgDLAwD/BABlAQD+AyjL
KzP+NhRlFZmZmerq6sHBwf//////////////////////////////////////////////////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAFkCAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi5ZEzifUOeA2SIUDNhs9oCgnggJhXg8XnRrQzB5bbalw+vy+fWOy90+tV3R
Rufhdn10f3t8c0oyeoGHQoR7gogrinGQjTiTbIxJYAydnp6VmwmfpKFFBA0OqqurD5pFEBE6
EhJetre4ubq7vL23IQA7"]
button $helixtop     -command {set o(c,ty) "helixtop"} -image  [image create photo -format gif -data "R0lGODlhHgAeAKUAAP7+/v///9bW1szMzODg4MHBwWZmZhQUFAAAACgoKHp6egUGEh0fXAsM
JRcZSh4eHgIDCQ4PLjs/uT5CwkpP6EdL3iksgaOjo0lO52VlZURI1RESN0FFzBQWQDg8sAgJ
Gy8ylJKTxLa49UlJYv//////////////////////////////////////////////////////
/////////////////////////////////////////////////////////yH+Dk1hZGUgd2l0
aCBHSU1QACwAAAAAHgAeAAAG4UBAQDgEGImBpDJ5bDqJzqW0+KxGp0qrUXrFUrXQppcJ1o6/
5S42bVUKBvABAc0GFAz4A2KPSODpVgIKewsMhg0NhgwOewoCT1MPEBESExSXhpcUFRIWEA8E
agEXCBaampmaGBgWCBmipKans5erGhuvYlIIEBYctKccEh2uogF8iQy0HgwNCB+4xggSIIt8
1wiFIBQMuUdT05ecEuTllasY3dISwLPo6rpL4e2qq/Dfu+z0tfbeVtPoAgp8568KwIEI0xV8
cjChwHv/QoiYSLGixREL62jcyLGjx48gQ3IMAgA7"]
button $nterm  -command {set o(c,ty) "nterm"} -image  [image create photo -format gif -data "R0lGODlhHgAeAMYAAP////7+/qmpqZOTkzMzMwAAAHh4eBgYGK6urqGhoSoqKg0NDQUFBWZm
ZsbGxvT09HBwcI6OjsnJyaurqxUVFba2tvn5+WhoaEhISOzs7GVlZZiYmObm5oaGhnt7exAQ
EC0tLczMzAoKCtHR0dzc3CAgIKOjo1tbWxoaGtnZ2cPDw8vLy3Nzc76+vmNjY87OzkVFRe7u
7lBQUBISEmBgYCgoKDg4OPb29jU1NV1dXZmZmfHx8UtLS7OzszAwMOTk5P//////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
/////////////////////////yH/C05FVFNDQVBFMi4wAwEAAAAh/g5NYWRlIHdpdGggR0lN
UAAh+QQACgD/ACwAAAAAHgAeAAAH/oABAIKDAYaEAImKiYeNjoSOi5KFj5WRk4qWhpiMjQID
nJqUnYcEBaGim5SGpqiWko0GBwUImJqIjAkKCwW9DAsNDou3jQ8QBQoREssSExQUFZnEARYX
BRgZqokOGtCkh8OGG9cBHB3RAB0ciR4F0Y/hAR8gDwEhBSIjAAUhiSQlDVZpK8ShgAlD9w6c
2NcvkQYUKeBJ08APYYENFFTwU0QxhMROFFdYDMCiV0MALSpe6hRB5YoCAVKg2OhQZaN4BVwY
GoFC0AsU+gBYOAEjxkdKMg5IuCnpZcCjh1rMoMFUUYoaNm4IxNWoAgUcFbQ9kFBCRK2tmhws
oJBDx44dLzl4XOsh7dWkAT56FfBhwMCkaY5i/ABRIIYtwI9aHUbcSPFfxpAjS55MubLlSoEA
ACH5BAEKAEAALAQAAwAVABYAAAf8gACCggGFhQIDg4oAhgGEjQQFi4OOhY+GkZOEi40GBwUI
mo6KAQkKCwWpDAsNDqSNDxAFChESthITFBQVlIYWFwUYGZaDDhq7lwEbwQEcHbwAHRyCHgW8
jR8gDwEhBSIjAAUhgiQlDYyFHAUmhd0HJ+HjghooKYYa4u0FGxQq4oP4QtwrsEJfABap5AFo
ka9QhIYrCgRIgeLfvIaFCrgoNAKFoxcowAGwcAJGjEYyDkhoNCniuUYtZtBgqShFDRs30Bmq
QAFHBWIAHkgoISKUTkMOFlDIoWPHjhw8gvWgpGmAj1QFfBgwMKlRoxg/QBSIIcqr10xlzWKS
JCoQADs="]
button $cterm   -command {set o(c,ty) "cterm"} -image  [image create photo -format gif -data "R0lGODlhHgAeAKUAAP////7+/tTU1JOTk5mZmQAAAJiYmEhISK6urqGhoSoqKg0NDQUFBWZm
ZsbGxvT09HBwcI6OjsnJyVNTUxUVFba2tvn5+WhoaAgICOzs7GVlZYaGhjIyMhAQEF1dXXZ2
diAgIFBQUAoKCsvLy8zMzNnZ2RoaGn5+foCAgKurq76+vqmpqfb29lVVVUtLS7u7u7Ozs87O
zu7u7ltbW0VFRTMzMygoKDg4ODU1Nenp6fHx8TAwMHh4eOTk5C0tLf///yH+Dk1hZGUgd2l0
aCBHSU1QACwAAAAAHgAeAAAG/sAAQDgMGImApDJ5bDqJzqW0+KxGp0qrEcs8CgYCrpbaNRIK
BPF4Sw2cDWqrtHkoHBBYLZKZUCwKgAwLDQ5Lek0PEAUKERKOEhMUFBVZhwEWFxgJGWxJDhqT
ZUeGRgYFBkcbqpRJHAWinVQdHg9GHyAhISIJSSMgH22xRhEFJEYlJidJKClKGiYlT6QaxUYk
BXvO1Vdd1CPWBSpJAyvaxtxF1OcsLS4vLwUw5tKVMQUvRzEm+y0ySRYzaMigV6ZADXS9CjQI
tudIBQoNmkgpYeMGC4akjDzEUaFTIhA2csDS42ABBQ8EdOjw4MKOvJESpwzYAajADh48plhy
IqOHGo8C/nTufFLjVZ6hTorGQcq0qdOnUKNKdRIEADs="]
#6
button $uparrowshaft  -command {set o(c,ty) "arrowshaft"}  -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v///8zMzPTMzP/MzODLy+Dg4AAAAMsAAP8AAGUAAGZmZv4AAMso
KP4zM2UUFJmZmerq6sHBwf//////////////////////////////////////////////////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAFjiAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi5ZEwwI0Gi0YGC2DoiEdrtVLKwnLHfstQ3F4+63ds6mtWW2D/2Ov9pv+Po+
d9f3SjJ0aXaBK4NkgEJ9eQmFiziIXI8neHmURVgMm5ycmECanZ2fOgcNDqipqQ+KSRAROhIS
YLS1tre4ubq7tSEAOw==
"]
button $dnarrowshaft -command {set o(c,ty) "arrowshaft"} -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v///8zMzMz0zMz/zMvgzODg4AAAAADLAwD/BABlAWZmZgD+AyjL
KzP+NhRlFZmZmerq6sHBwf//////////////////////////////////////////////////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAFjiAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi5ZEwwI0Gi0YGC2DoiEdrtVLKwnLHfstQ3F4+63ds6mtWW2D/2Ov9pv+Po+
d9f3SjJ0aXaBK4NkgEJ9eQmFiziIXI8neHmURVgMm5ycmECanZ2fOgcNDqipqQ+KSRAROhIS
YLS1tre4ubq7tSEAOw==
"]
button $helixshaft   -command {set o(c,ty) "helixshaft"} -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v///zMzM7m60trb+nZ2goSEhAAAADs/uUlO50pP6B0fXGVlZVhb
vW5y7CwtXpiYmOrq6sHBwf//////////////////////////////////////////////////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAFnCAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi7ZEgwI0Kh0WjAUD4hEQsHterWJBeOa3XrPYLEyhT27FemxUNZ+f7Xq+apu
58bXAXx9f3oqgnaEJzOHb4k7dAh9XY4ohpGScHhyipCYmWGbj3uXkpQvWGCpqqYuqKuvoFcN
DrS1trcPoTUQEUwmEhK+wsPExcbHyMnKIQA7
"]
button $line7   -command {set o(c,ty) "line7"} -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v///+Dg4GZmZoSEhMzMzAAAAGVlZTIyMnp6eurq6j09PcHBwRQU
FJmZmcvLy1tbWx4eHkdHR/T09FFRUaOjo3BwcCgoKJiYmDMzM///////////////////////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAFjyAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi5pOzJrzqdyBjxGmzPBALUEELbTVMFwiCIML9y4PDQhEumZYsH2ARgNR3w2
MDzaEA0MezICERIKOBMPBhRQPg4GCxUzFgYGBY8+BBeXBhgRngtIJ1YCBRQZqhkWBQpSsLGy
s7S1tre4ubq7vDYhADs=
"]
button $line8   -command {set o(c,ty) "line8"} -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v///8zMzPT09KOjo2ZmZgAAAFFRUeDg4JmZmR4eHpiYmCgoKI6O
jkdHR4SEhMvLy+rq6j09PTMzM3p6etbW1v//////////////////////////////////////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAFjiAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi5pOzJrzqdyBjzKBIOc8UgoeA0HL6LqSygM3nTBoFggTz6EgdGYCRyGR3OG
YBggPhESDGMvOAIGBFwGE1AzBwYoSxSNhjMTkU4LlVMpExKSVAsKFZYyFRFWABECEVKvsLGy
s7S1tre4ubq7LiEAOw==
"]
#11
button $uparrowtail -command {set o(c,ty) "uparrowtail"} -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v///zMzM9atrf/MzIRwcISEhAAAAMsAAP8AAGUAAGZmZv4AACgA
ADIAABQAAJmZmZiYmMHBwf//////////////////////////////////////////////////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAFkCAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi5ZEwwI0Gi0YGC2DoiEdrtVLKwnLHfstQ3F4+63ds6mtWW2D/2Ov9pv+Po+
d9f3SjJ0aXaBK4NkgEJ9eQmFiziIXI8neHmURVgMm5ycmECanZ2fOgcNDqipqQ+KSRCvsLEQ
ERJgtre4ubq7vL23IQA7
"]
button $dnarrowhead   -command {set o(c,ty) "dnarrowhead"} -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v///2ZmZuDg4KOjowAAAADLAwD/BABlASgoKAA9AABmAQDgAwCj
AgAUAI6OjgoKCgAeAAD+AwCOAgoUCgAoAADWA///////////////////////////////////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAFriAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi5pOzJfgsGQQHieCoaDdrtFCJo+LHfsBQcE6LR43E2k0VVUoaBY2BcM9rZx
XzgKcSoPEBF5emMSiRITFA8nKw8FFYaHWooNBY6PKwQFERaVlouASimDhaGLjS84kZOVmJql
Kp2fehOkNUOnlFqMslYArgyXmcEutRajccctp7/NNZHG0dXW19jZ2ttJIQA7
"]
button $helixbottom   -command {set o(c,ty) "helixbottom"} -image  [image create photo -format gif -data "R0lGODlhHgAeAKUAAP7+/v///+rq6s7P1drb+svLy/T09JiYmA4PLklO50pP6AAAAJmZmVtb
Wx4eHgsMJURI1UdL3iAiZhESNy8ylDg8sBcZSj09PeDg4CgoKBocUywvixQUFGZmZszMzFFR
UTMzM9bW1v//////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////yH+Dk1hZGUgd2l0
aCBHSU1QACwAAAAAHgAeAAAGxEBAQDgEGImBpDJ5bDqJzqW0+KxGp0qrUXrFUrXQppcJ1o6/
5S423RQMCPC4fE4oGMAHRCKh6Pv/e3sLBXh6fH+IgQmDYlIMCIiRCoqMR1OPkomBlVuOkJl+
lISWnqChm6OdS5imk6iNq5+morBKrLOvpLGtroKpSEoNsqC0ukoODxCtexESnFUHCxMUitV7
FRYLFwJlGBkLCxob4+TjEwscHWwAGB4fICDf4AvwIB4h608CDPwMaPkAAwocSLCgwYP5ggAA
Ow==
"]
button $line10  -command {set o(c,ty) "line10"} -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v///8HBwWZmZpiYmBQUFDMzMz09PWVlZQAAAHBwcOrq6q2trVFR
UfT09FtbW4SEhI6OjigoKB4eHszMzKOjo9bW1uDg4P//////////////////////////////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAFkCAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi5pOzJrTsFA8NwNAYQCVXmcYQ3Qrg9wAL/EPkRCEUarFoxCw9EWCxCIQ+Kx
PQ8XBAmCgwMQSEI+ERITBg0UjxRETTgVCRMWY0YzCwcSF1eaMhQJhqBVCglVTAapqkUGE65F
DBaytre4ubq7vL0nIQA7
"]
button $line11  -command {set o(c,ty) "line11"} -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v///9bW1urq6jMzM5iYmAAAAFFRUczMzKOjo2ZmZo6OjuDg4B4e
HgoKCjIyMsvLy3p6emVlZcHBwfT09CgoKISEhD09Pa2trf//////////////////////////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAFiyAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi7pEgxQS+aJUIDOpFODlWecHbRHIA5hSIS7M4VhMRTjGA3HA0Ln2oaCiGFv
kPjNbkcTCoRfBg0CaEcqFAgLFQ0Wd4s4AxcVDDWUPglrmptXDQRYTAWjpEUFiKhAGAQYrLGy
s7S1tre4rCEAOw==
"]
#16
button $ltarrowhead   -command {set o(c,ty) "ltarrowhead"} -image  [image create photo -format gif -data "R0lGODlhHgAeAKUAAP7+/v///9bW1pmZmeDg4B4eHgAAACgoKKAAozEAMgoACowAjvoA//oA
/tEA1h0AHltbW6kArTIKMq2trfkA/voz/jIyMlFRUW0AcPAA9Orq6j09PVkAW0dHR5iYmO8A
9Hp6eszMzG4AcFoAWycAKMvLy///////////////////////////////////////////////
/////////////////////////////////////////////////////////yH+Dk1hZGUgd2l0
aCBHSU1QACwAAAAAHgAeAAAG30BAQDgEGImBpDJ5bDqJzqW0+KxGp0qrUXqdCgYC7ZHZxBIK
hoFYOyUcDOm1VSpAIxJq+XN5ViwYeHp7SW4Gf4B5gmMBdQYIDQwODxADYINYhAV+DJwRCZ8S
E5dmb4ecnBQUFVWYjHansKmro3yaprAMsqxtpbixqrtSFo6+v7NdSxcGGBnFqMC0SRoby865
0MhS1BzOutFKGh3LzbjeitPLqerqx4oB2w3qCXAGHopH4csfqQkgISEa7uGjJoJfIoFNqI1A
hPBJPhEkDjY0gi7OxCfUJF4EoKFEwI33ggAAOw==
"]
button $ltarrowshaft  -command {set o(c,ty) "ltarrowshaft"}  -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v///8kzzAAAAJmZmfEz9McAy8goy+rq6vsz//oA//kA/voz/twz
4GMAZWQUZcHBwd6E4GZmZv//////////////////////////////////////////////////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAFiSAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi5pOzJrzqdJMKhar1jCC1cweL9g8AGxnSUU6LQavVgwoOa1XNF+l2XnuboO
x+v3bn0reX90gXeDhWyHSiqEf3yIjoqGdo0pj3qRSQ0Onp+goA8QTBESp6ipqqRSra6vsLGy
s7S1trYhADs=
"]
button $ltarrowtail -command {set o(c,ty) "ltarrowtail"} -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v///8zMzAAAAJmZmfTM9McAyycAKP7M//oA//kA/jEAMt/L4GMA
ZRMAFJiYmODg4GZmZsHBwf//////////////////////////////////////////////////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAFiyAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi5pOzJrzqdJMKhar1jCC1cweL9g8EGrVCES6LQarVAsyMLZeU1vv7dyet0N
P+Hmeml2fTt5gYJ8eDKAh4OKK4yBjmUpkXqTcYuHiHdJDA2goaKiDg9MEBGpqqusElKvsLGy
s7S1tre4uSEAOw==
"]
button $ltnterm  -command {set o(c,ty) "ltnterm"} -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v///8zMzHBwcODg4GZmZgAAACgoKISEhNbW1h4eHmVlZaOjoz09
PcHBwQoKCo6Ojurq6q2trRQUFLe3tzMzM5mZmcvLy5iYmFFRUXp6ejIyMltbW/T09EdHR///
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAF5yAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi5pSwmegycByTQRCoas9oCouhIKw6JrYjSyjiaOoHhAZhHJZEKp+bBvR8ER
uKYcBhV2MwIGDCkWWQEXBiwYBhYvOBkGJBYPEwiMLBEHGpIzFZWIFQsHEo0lG2ILCycqj1oW
KhYVAWepJqtarykSFcAPCpa2Eg+5AKtPAr0yosQpEMgbHKAyhQtHAI+RSiodGXRDbB4RVYAT
aS8EBwbMXg4TBg0SJw4cWQxeJwkDbRsA52R4t4+fhYMH1RVcyLChw4cQI0oMAQA7
"]
button $ltcterm   -command {set o(c,ty) "ltcterm"} -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v///8zMzHBwcODg4GZmZgAAACgoKISEhNbW1h4eHmVlZaOjoz09
PcHBwY6Ojurq6q2trRQUFMvLyzIyMlFRUZiYmJmZmfT09FtbWzMzMwoKCnp6ere3t///////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAF8yAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi5pSwmegycByTQRCoas9oCouhIKw4JwYjSyjiaOoDg8ZpCIRJKorQ+GSepa
KDhSDgYDdjMCBgwqFA0FFQZ/ABYGFy84jSRyEQEYA1MAEAeTPQ4LpBIZJBcaMyaKpGk7KRda
BhYqFwoJARAWjwAUWhYnKhBPDxscJJ8cEwwGnb4KTxDCMxoGKA9aGSwOEqFChY5HABkSr+Ay
GBUSHUMEBhVegeY1BAcN0/IStBEmuxkGGjDwciLBAAUbKFDAI6FCPoIFL0iUeA6ixYsYM2rc
yJFjCAA7
"]
#21
button $rtarrowtail -command {set o(c,ty) "rtarrowtail"} -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v///zMzMwAAAJmZmXp0AMvBAMvDKOrq6piRAP/yAP7xAP70M//x
AJiYmNbW1szMzP//////////////////////////////////////////////////////////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAFkiAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi5pOzJrzqdJMKhar1jCCycoGL7gMPiA2M4ECYV6zVYsFgzoOd1uv+NmGbpu
h8v1dHxqd38re4KDfnmGCQ2IbopKKoeIhIuTgYKWkilojpWRRWhvpKWleElUWKtWDkwPELGy
s7RlUre4ubq7vL2+v7shADs=
"]
button $rtarrowshaft -command {set o(c,ty) "ltarrowshaft"} -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v///8zIjgAAAJmZmfTqM8vBAMvDKOrq6v/0M//yAP7xAP70M//x
AMvEM5iYmPTz1szMzP//////////////////////////////////////////////////////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAFjiAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi5pOzJrzqdJMKhar1jCC1cweL9g8AGxnSUU6LQavVgwoOa1XNF+l2XnuboO
x+v3bn0reX90gXeDCg2FfIgqhH+NSo+FbIeTKWeLkZdFDG2goaJ2SQ5Yp1cPTBARra6vsGRS
s7S1tre4ubq7tyEAOw==
"]
button $rtarrowhead   -command {set o(c,ty) "rtarrowhead"} -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v///8zMzAAAAMHBwRQUFLe3t1tXAP/yAHBqAPToAKOjo2ZmZlFR
Uf78zKOaAGVgAP7xAP/8zJmZmf/xAEdHR+rq6j09Pf78y/794KOgZuDg4GVlZf//////////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAFtyAQiCNgkkGqpmfrku4ql28dz6ptyq4w
EDhdi9XyFQwzodB3KABXSp0PkfhBo7WpInHMYVsLRmOAKDef35PjAWmXEZEqUIiTvO+I7ZE+
s+PvZzp1f3hyNoOEb3oGNYiJZRGBNzJ+j3AHAxMvgxSPWwMVFpt9llQDF6KjlJaYFzSTK3ad
eJ+haQAYbG0RvHGnqWkZGmIDva2vtwA+EbXAySbLVajPPQPH1NWgztjKv9wuGxzf4+Q6IQA7
"]
button $line7b   -command {set o(c,ty) "line7b"} -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v///+rq6szMzPT09KOjoz09PQAAANbW1h4eHmVlZcHBweDg4AoK
Co6OjmZmZlFRURQUFLe3tzMzM5iYmCgoKDIyMpmZmf//////////////////////////////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAFjiAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi5pkwkGUAKztioYDtjB9JVCJA4KxUIEPAYYiYaDZzw+Dmt2czg4PJZtX/0+
K9MPC3hzegc+foSGeTh1BYJUf3xyjz4EEBESfVsuCwcTmkkLEQcUAp86EhMHFRYWCKY1FBey
pa+1tre4ubq7OiEAOw==
"]
button $line8b   -command {set o(c,ty) "line8b"} -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v///+Dg4MzMzGZmZgAAAISEhGVlZVtbW8vLy0dHR+rq6j09PSgo
KKOjo62trTMzM46OjsHBwfT09FFRURQUFNbW1nBwcDIyMpmZmf//////////////////////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAFiSAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi5pCwgGUB7zFSAUrgRBbhozGQ5XBLF5XCUUBS2wLFswGoI1e+UoDORzVeGB
zwcKEH15gIJzhEZ+KQURhWUSdo1DExQVFlxFFwUElzqPBQxInAYYGBUQDwucLxIZraGqsLGy
s7S1tpchADs=
"]
#26
button $lthelixtop     -command {set o(c,ty) "lthelixtop"} -image  [image create photo -format gif -data "R0lGODlhHgAeAKUAAP7+/v///9bW1np6egAAAJiYmB4eHgAKCQAyMAAoJgDLwSjLw+rq6qOj
owCOhwD/8gBbVwAUEwDBtwD+8TP+9D09PQBlYAD/8czMzACEfQBRTXBwcDMzMwBmYAAeHQCY
kQB6dADMwQDq3gDWy1FRUQDg1MvLywBwagA9OvT09ACZkcHBwRQUFP//////////////////
/////////////////////////////////////////////////////////yH+Dk1hZGUgd2l0
aCBHSU1QACwAAAAAHgAeAAAG9EBAQDgEGImBpDJ5bDqJzqW0+KxGp0qrUXrFUrXQppcJ1o6/
5aZgQGi73+1C+mg4IAgJhX6vXzDmAA0EDg8QERIPiYkTExSADBUWFw8SERCKi41VWBgEGYoa
BJgPjI5PWBsEE4oKopilm1McqqwEHa+ap7Ieq4mtt4qwulIcH5i/uKZdS7Ntxg8WwJnKYrIg
ISEiDyMR0qS5y0rFx7bJscS0vuXB4NVSJOkPrSXmcyaqjBMnovn51GD3LORDgOJbv39aUpCI
MGKCgwMq+vkDBGAFAQ0WCHhoKLFdmhUs4IgkIIeiABMoU6pE+Yeiy5cwY8qUGQQAOw==
"]
button $lthelixshaft   -command {set o(c,ty) "lthelixshaft"} -image  [image create photo -format gif -data "R0lGODlhHgAeAOMAAP7+/v///zMzMwAAAJiYmDPWzQDLwSjLw+rq6jP+9AD+8QD/8jP/9AD/
8dbW1svLyyH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAElxAEOYGlIet8u6feJlZfGY6a
aYknSqpg53KwOr+1JQx87/+EHKBgKBqPxwNCmFAoFtCo1JkQAppPqZZaQjG04AX34w1vFVXy
6GuOjlsbdluM7q7n0Lfsjtdfyg1zfit8gnVqInJtgxhxC4GLhzlYTpWWlWmTl5uYVpSclpk1
n6CMJTs/qT1BOQ4Pr7CxsktWtba3uLm6HxEAOw==
"]
button $lthelixbottom   -command {set o(c,ty) "lthelixbottom"} -image  [image create photo -format gif -data "R0lGODlhHgAeAKUAAP7+/v///9/f37u7u+vr6/T+/iqTjgAaGQEaGQESEUpKSvLy8vD//gD/
8gD+8QH+8QHb0AEnJT8/P/f39wGCewAAALi4uO/+/gHn2wAZF1lZWQB4cSEhIdnZ2QC3rgAH
BsLCwgAPDmxsbAH47ABeWUdHRwDZzmFhYQDb0AAnJQASETg4OKysrP//////////////////
/////////////////////////////////////////////////////////yH+Dk1hZGUgd2l0
aCBHSU1QACwAAAAAHgAeAAAG1kBAQDgEGImBpDJ5bDqJzqW0+KxGp0qrcQrVNqnPrGBALpsH
hCM4HCgYDgeEfC5PKBZbb5LRaDgegIGAEBESE0J6AXx+go0UFRaIXgAXDpaNghgZGpJelZeY
gRscHWtIRRehmB4fIKZLRqmqgg4hrmxMlLO0tq9ZuruAtSK+ubLBw8WowcK9uMvMtbdXxswP
rNNfv8e7GxXZatvMIyQlC6ZPn5br7A4mFSedVXt99fZ9KCmGuV5ucP8AD6hYwSLPJABjzpxJ
Y/Cgw4YPI0qcSLGixYsOgwAAOw==
"]
button $line10b  -command {set o(c,ty) "line10b"} -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v////T09MzMzOrq6gAAAD09PaOjo4SEhCgoKI6OjuDg4Hp6egoK
Cq2trdbW1h4eHsvLy8HBwWZmZmVlZVFRUUdHR1tbW3BwcJiYmDIyMpmZmf//////////////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAFjyAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi7pEgyeBB+zNShYDYfl1IVIFBQz4DGwYDQcPOP4ATGkbeNUpCBZiePziV09
zu/hcQEUejl8YxQVAoWAcRQFA4s1gYKPkS+TCwUWUUhbLhcFbp5iGKEZGaM2ThBWGhepNQ8b
pw6wtre4ubq7vDUhADs=
"]
button $line11b  -command {set o(c,ty) "line11b"} -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v///+rq6szMzMvLy9bW1qOjoz09PQAAADMzMzIyMigoKISEhI6O
jhQUFODg4GVlZWZmZh4eHpmZmZiYmHBwcPT09P//////////////////////////////////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAFkCAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi5p8wkGBEKBKZwZDohsgnqaKRALBvAoazgaD6SSjEjkjOQUBDF4N+MBiKNg
r+HzEStjcQIHgX0veAQIh0R3ZIuNalVkDQg8cEcCCxKYXC5YE582FBRYFZNcBV8IEgMWoy8C
pRNTsbe4ubq7vL29IQA7
"]
#31
button $line01  -command {set o(c,ty) "line01"}  -image  [image create photo -format gif -data "R0lGODlhHgAeAMIAAP7+/v///2VlZeDg4AAAAMzMzJiYmOrq6iH+Dk1hZGUgd2l0aCBHSU1Q
ACwAAAAAHgAeAAADXgihC84hyviqZXbqdnvekudoH8iJWGVSqLiebQnG3kt3mjCEtxwQBV7t
NQEKcUSJkTVM/oJMpHMJ872oKGcE69Jym8mvNAytqrzlHgqojrHb6wIcZTjM7/i8fs/v0xIA
Ow==
"]
button $line02   -command {set o(c,ty) "line02"} -image  [image create photo -format gif -data "R0lGODlhHgAeAMIAAP7+/v///+Dg4GVlZYSEhGZmZv///////yH+Dk1hZGUgd2l0aCBHSU1Q
ACwAAAAAHgAeAAADVQihC84hyviqZXbqdnvekudoH8iJWGVSqLiebQnG3kt39i1v6JvXPlMv
OHMReUaNYMBsOp0E3EZQqFqv1+jliARyQ8kvbMfVmc/otHrNbrvf8LhclAAAOw==
"]
button $line4   -command {set o(c,ty) "line4"} -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v///4SEhMHBwTIyMpiYmJmZmQAAAAoKCq2trT09PTMzM3BwcBQU
FNbW1uDg4CgoKGZmZh4eHvT09I6OjlFRUUdHR+rq6v//////////////////////////////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAFjyAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi5pOzJrToBg8NwNTYTC6xglGLZcH/arDK8AhQNZaJ6hEQlw+6xYQOfnA+OO
TwkaDnx4DxARTX0OEgdIJ3gTDBIIFFU6AxUHCnGULQMFBQoHDQOMSQ8WBAQNBxALDIGbJ50G
sxewtre4ubq7vLshADs=
"]
button $line6    -command {set o(c,ty) "line6"} -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v///9bW1jMzM3BwcMzMzOrq6piYmD09PQAAAGZmZuDg4GVlZVtb
W8HBwcvLy62trRQUFLe3t4SEhCgoKKOjo1FRUQoKCv//////////////////////////////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAFkCAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi7pEgyeA0KhwGOeDIcsIsFVLHLWmGnB4DYcSOUx8IBEIhLgeuZIRBzGucwR
SaR3ejIQCRM2gTIGCBQLNYcyFQkFjY45CRaTlCMJA5iUAAecL5ksBxcQYUkHCQeoRaqsrToQ
A6extre4ubq7vL2tIQA7
"]
button $line03    -command {set o(c,ty) "line03"} -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v////T09MzMzAAAAISEhGVlZeDg4CgoKGZmZhQUFNbW1svLyzIy
Mnp6egoKCo6Ojh4eHj09Pa2trVtbW5iYmOrq6jMzM///////////////////////////////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAFjCAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi7pEgxQS+ZpQIDOpNPqEYijFrbGGdUAtuEOCPKQi0soFuvwLEFgxM0+QuNe
GzoeED5sOAsRBIJyZwgSE1eJZxEPDQcrWDULDgQIBZZFARIEoQQUFRULnS0WAwMNF64XE6iy
s7S1tre4uaghADs=
"]
#36
button $line5    -command {set o(c,ty) "line5"} -image  [image create photo -format gif -data "R0lGODlhHgAeAIQAAP7+/v///2VlZWZmZsHBwVtbWwAAABQUFOrq6lFRUcvLy9bW1qOjoz09
PczMzCgoKODg4EdHRx4eHpmZmTIyMoSEhK2trf//////////////////////////////////
/yH+Dk1hZGUgd2l0aCBHSU1QACwAAAAAHgAeAAAFiyAQiCNgkkGqpmfrku4ql28dz6ptyjdO
67CWjwXUDX/FHi5pOzJrPsFgOiA8dypCwcA9CL5WpQ+ROBwSCsUCeAwwGoYCYcUeOgwPyKyO
Q0QkentGPhMGEz58MwYUQ4krFQYWjYMzAwYKk004U06UKwtenVcKBgJXSaQMp0Wkq6wGrrGy
s7S1tre4JyEAOw==
"]

#### DUMMY IMAGES
button $line12a    -command {set o(c,ty) "line12a"} -image  [image create photo -format gif -data "R0lGODlhFAAUAPMKAAwMDCQkJC0tLTw8PEdHR8vLy9LS0ufn5+7u7vDw8P7+/gAAAAAAAAAA
AAAAAAAAACH5BAAAAAAALAAAAAAUABQAAAQ1UMlJq70463tG2RYSAAZYHQJpUkharlKrwor8
0fIL50qyu7QakIaa/YwrW1BECCoOB6fUEgEAOw==
"]

button $line12b    -command {set o(c,ty) "line12b"} -image  [image create photo -format gif -data "R0lGODlhFAAUAPMKAAwMDCQkJC0tLTw8PEdHR8vLy9LS0ufn5+7u7vDw8P7+/gAAAAAAAAAA
AAAAAAAAACH5BAAAAAAALAAAAAAUABQAAAQ1UMlJq70463P0RQHhVYgAFONUAkYqra27ou5h
tkkKu8ou3zyfDvhj8Q4BYy51GNB40Kj0EgEAOw==
"]

button $line13a    -command {set o(c,ty) "line13a"} -image  [image create photo -format gif -data "R0lGODlhFAAUAPQXAAAAAAkJCRISEiQkJCkpKTk5OVNTU1hYWGRkZHp6eoSEhIyMjJKSkp2d
na2trbKysrq6us/Pz9HR0djY2OXl5ezs7PPz8/7+/gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
ACH5BAAAAAAALAAAAAAUABQAAAVM4CWOZGmO1amODTAYSrqSlXMYQoDMp6UABh7JIoIIgsLS
AwBJjoiGgcx5iQAW1BEuK5IAHtyLoRC2MsKJgIRbIQzCFUAiDJmE7/hSCAA7
"]

button $line13b    -command {set o(c,ty) "line13b"} -image  [image create photo -format gif -data "R0lGODlhFAAUAPQXAAAAAAkJCRISEiQkJCkpKTk5OVNTU1hYWGRkZHp6eoSEhIyMjJKSkp2d
na2trbKysrq6us/Pz9HR0djY2OXl5ezs7PPz8/7+/gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
ACH5BAAAAAAALAAAAAAUABQAAAVQ4CWOpGiVaEpWamolxgA0LYkEwnE4bH0ZAMXJNzoIIKNh
DQJ4XJQ+y+BALC0AkSpJYNA+L0yJV1TojhnYsSSQGF8IBCgxAaC4J0i3fs+/hAAAOw==
"]

button $line14a    -command {set o(c,ty) "line14a"} -image  [image create photo -format gif -data "R0lGODlhFAAUAPQXAAAAAA0NDRISEiUlJSoqKjQ0NEtLS1JSUltbW2JiYnV1dYWFhYyMjJSU
lJycnLOzs7y8vMHBwdPT09jY2Ofn5+rq6vPz8/7+/gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
ACH5BAAAAAAALAAAAAAUABQAAAVQ4CWOZGmeaKqalkOtLPDA5oBcFo1fx6GTC0Huhwssdr+E
DKk7CGZM2AFwmPxyEALVGk1ZGAGAgfuDFACK4UrdABAq14tEC4lbFGSiXqS+hAAAOw==
"]

button $line14b    -command {set o(c,ty) "line14b"} -image  [image create photo -format gif -data "R0lGODlhFAAUAPQXAAAAAA0NDRISEiUlJSoqKjQ0NEtLS1JSUltbW2JiYnV1dYWFhYyMjJSU
lJycnLOzs7y8vMHBwdPT09jY2Ofn5+rq6vPz8/7+/gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
ACH5BAAAAAAALAAAAAAUABQAAAVK4CWOZGmeaKquKuWw5gNYMIkMNXkcF11bgkWOtgj4arJE
7vIQ8GqSA+DJigIGEZjEAAgwjioFoACpVQiAxgh8glwly4lCxF7aayEAOw==
"]

button $line15a    -command {set o(c,ty) "line15a"} -image  [image create photo -format gif -data "R0lGODlhFAAUAPQXAAAAAAkJCRISEiQkJCkpKTk5OVNTU1hYWGRkZHp6eoSEhIyMjJKSkp2d
na2trbKysrq6us/Pz9HR0djY2OXl5ezs7PPz8/7+/gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
ACH5BAAAAAAALAAAAAAUABQAAAVJ4CWOZGmeaKquKjSxJQUk8GgRQz0mQaRfEQDjdzEUiEEI
0SBAAhTLgaU2fQCUrOkFIjD8FADvquI4MAMIWAMwMCi0sAqRBFeFAAA7
"]

button $line15b    -command {set o(c,ty) "line15b"} -image  [image create photo -format gif -data "R0lGODlhFAAUAPQXAAAAAAkJCRISEiQkJCkpKTk5OVNTU1hYWGRkZHp6eoSEhIyMjJKSkp2d
na2trbKysrq6us/Pz9HR0djY2OXl5ezs7PPz8/7+/gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
ACH5BAAAAAAALAAAAAAUABQAAAVK4CWOZGmeaKqeE7SeCUC95kBYNBkFSU4ygIjvgisYhiII
QIK8CI7IRRBZGRyIQ+WjeRC4kAaAooJEBASHw4NMqyQMA0ADaWE3SSEAOw==
"]

button $line16a    -command {set o(c,ty) "line16a"} -image  [image create photo -format gif -data "R0lGODlhFAAUAPQXAAAAAA0NDRISEiUlJSoqKjQ0NEtLS1JSUltbW2JiYnV1dYWFhYyMjJSU
lJycnLOzs7y8vMHBwdPT09jY2Ofn5+rq6vPz8/7+/gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
ACH5BAAAAAAALAAAAAAUABQAAAVL4CWOZGmeaJpayqSa0gBAL9kABFWLUAEoOwsjADC4ahBC
USKyvA6Aw3F3EDx2owTgir1YAgtvdyFwYp2HQ3c0QKy92/fFoZPb7/IQADs=
"]

button $line16b    -command {set o(c,ty) "line16b"} -image  [image create photo -format gif -data "R0lGODlhFAAUAPQXAAAAAA0NDRISEiUlJSoqKjQ0NEtLS1JSUltbW2JiYnV1dYWFhYyMjJSU
lJycnLOzs7y8vMHBwdPT09jY2Ofn5+rq6vPz8/7+/gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
ACH5BAAAAAAALAAAAAAUABQAAAVK4CVe1mieaKqek7KuEDBIb1oRQFOnClBAu5PEAAgwSjuk
5CADBkcT5uFJEj0EU2rpAUhQR4tA5UsSLMiXgwGNGKC5SGrFga7bTyEAOw==
"]

# Configure the height width and colour of all the buttons
foreach button [list $uparrowhead $dnarrowtail $helixtop \
	$nterm $cterm $uparrowshaft $dnarrowshaft $helixshaft \
	$line7 $line8 $uparrowtail $dnarrowhead $helixbottom \
	$line10 $line11 $ltarrowhead $ltarrowshaft $ltarrowtail \
	$ltnterm $ltcterm $rtarrowtail $rtarrowshaft $rtarrowhead \
	$line7b $line8b $lthelixtop $lthelixshaft $lthelixbottom \
	$line10b $line11b $line01 $line02 $line4 $line6 $line03 \
	$line5 $line12a $line12b $line13a $line13b $line14a \
	$line14b $line15a $line15b $line16a $line16b] {
    $button configure -height 30 -width 30 -bg white
}

# Menubuttons
tk_optionMenu $linewidth o(c,w) 1 2 3 4 5
tk_optionMenu $textfn o(c,fn) 8 10 12 14 16 18 20 25 30
tk_optionMenu $textft o(c,ft) Helvetica-Medium Helvetica-Bold Symbol Times-Medium Times-Bold

# Labels
label $lwtext -text "Linewidth:"  -bg white
label $lctext -text "Linecolour:"  -bg white
label $tctext -text "Textcolour:"  -bg white
label $ctext -text "Fillcolour:"  -bg white
label $fntext -text "Fontsize:"  -bg white
label $movetext -text "Move"  -bg white

foreach j [list "$linec o(c,lc)" "$colour o(c,oc)" "$textc o(c,tc)"] {
    set m [tk_optionMenu [lindex $j 0] [lindex $j 1] Black red4 DarkGreen NavyBlue gray75 Red Green Blue gray50 Yellow Cyan Magenta White Brown DarkSeaGreen DarkViolet]
    if {$tcl_platform(platform) == "macintosh"} {
	set topBorderColor Black
	set bottomBorderColor Black
    } else {
	set topBorderColor gray50
	set bottomBorderColor gray75
    }
    for {set i 0} {$i <= [$m index last]} {incr i} {
	set name [$m entrycget $i -label]
	image create photo image_$name -height 16 -width 16
	image_$name put $topBorderColor -to 0 0 16 1
	image_$name put $topBorderColor -to 0 1 1 16
	image_$name put $bottomBorderColor -to 0 15 16 16
	image_$name put $bottomBorderColor -to 15 1 16 16
	image_$name put $name -to 1 1 15 15

	image create photo image_${name}_s -height 16 -width 16
	image_${name}_s put Black -to 0 0 16 2
	image_${name}_s put Black -to 0 2 2 16
	image_${name}_s put Black -to 2 14 16 16
	image_${name}_s put Black -to 14 2 16 14
	image_${name}_s put $name -to 2 2 14 14

	$m entryconfigure $i -image image_$name -selectimage image_${name}_s -hidemargin 1
    }
    $m configure -tearoff 1
    foreach i {Black gray75 gray50 White} {
        $m entryconfigure $i -columnbreak 1
    }
}

# Other buttons labels etc
button $save    -text "Save"   -bg white         -command SaveFile
tk_optionMenu $move moveall "single object" "all objects"
# Force the move-menu to always have the same width regardless
# of the text that is displayed
$move configure -width 10
button $open    -text "Open"    -bg white        -command OpenFile
button $help    -text "HELP!"   -bg white        -command Help
button $example    -text "Example"   -bg white   -command Example
button $delete -text "Delete" -bg White  -command {set o(c,ty) "delete" }
button $clear   -text "Clear"  -bg white         -command Clear
button $print   -text "Write PS"  -bg white      -command WritePS
button $exit    -text "Exit"  -bg white          -command exit
label $txt    -text "Text:"  -bg white 
label $title    -text "TopDraw" -anchor w -bg white -font -*-Helvetica-Bold-R-Normal--30-120-*-*-*-*-*-*
entry $txtstr -textvariable o(c,ts)  -bg white -relief sunken -width 10
bind $txtstr <Return> "set o(c,ty) text" 

#=========================================================
# Grid everything in the window

# Drawing buttons (frame 1)
grid $title
grid configure $title -columnspan 5 -sticky nsew

grid $uparrowhead  $dnarrowtail  $helixtop    $nterm   $cterm
grid $uparrowshaft $dnarrowshaft $helixshaft  $line7   $line8
grid $uparrowtail  $dnarrowhead  $helixbottom $line10  $line11

grid $ltarrowhead  $ltarrowshaft $ltarrowtail $ltnterm $ltcterm
grid $rtarrowtail  $rtarrowshaft $rtarrowhead $line7b  $line8b
grid $lthelixtop   $lthelixshaft $lthelixbottom $line10b $line11b

# NB the delete button should be 2 columns wide and 2 columns high
grid $delete $line01 $line5 $line6
grid $line02 $line03 $line4
# Reconfigure to get delete button 2x2 and everything else
# arranged appropriately
grid configure $delete -rowspan 2 -columnspan 2 -sticky nsew -padx 3 -pady 3
grid configure $line01 -column 2
grid configure $line5 -column 3
grid configure $line6 -column 4
grid configure $line02 -column 2
grid configure $line03 -column 3
grid configure $line4 -column 4

grid $line12a $line15b $line16b $line13a $line14a
grid $line12b $line13b $line14b $line15a $line16a

# Style controls (frame 2)
# NB the label/linewidth options etc should lie in a single box under
# the others - this isn't quite working!!
grid $lwtext $linewidth
grid configure $lwtext -sticky e
grid configure $linewidth -sticky ew
grid $lctext $linec
grid configure $lctext -sticky e
grid configure $linec -sticky ew
grid $ctext $colour
grid configure $ctext -sticky e
grid configure $colour -sticky ew
grid $tctext $textc
grid configure $tctext -sticky e
grid configure $textc -sticky ew
grid $fntext $textfn
grid configure $fntext -sticky e
grid configure $textfn -sticky ew
grid $txt $txtstr
grid configure $txt -sticky e
grid configure $txtstr -sticky ew
grid $textft -columnspan 2 -sticky ew
$textft configure -width 20
grid $movetext $move
grid configure $movetext -sticky e
grid configure $move -sticky ew

# Program controls (frame 3)
# First configure all the buttons to have the same width
foreach w [winfo children $frame3] {
  $w configure -width 10
}
# Then grid these buttons as pairs on each line
grid $help $example -sticky nsew
grid $open -sticky nsew
grid $save $print -sticky nsew
grid $clear $exit -sticky nsew

# Finished gridding controls
#=========================================================

# Finish configuring the scrolling
update idletasks
set canvas [winfo parent $frame]
$canvas configure -scrollregion \
        [$canvas bbox all]
$canvas configure -width [winfo width $frame]
$canvas yview moveto 0.0
pack $canvas -side left

proc SaveFile {} {
    global o count 
    set types {
        {"TopDraw data"         {.dat}     }
        {"All files"            *}
    }
    set file [tk_getSaveFile -filetypes $types \
            -initialfile topdraw -defaultextension .dat]
    if [catch {open $file "w"} file] {
	return
    }
    set i 0
# Dont change Nov 2001 unless format changes
    puts $file "\# TopDraw (Nov 2001) Input File"
    while {$i < $count} { 
	incr i 1
	if {[info exist o(tag$i,type)]} {
	    if {[string match "0" $o(tag$i,type)] == 1 } {continue}
	    if {[string match "text" $o(tag$i,type)] ==1 } {puts $file "$o(tag$i,type) $o(tag$i,tc) $o(tag$i,x) $o(tag$i,y) $o(tag$i,fn) $o(tag$i,ft) $o(tag$i,ts)"}
	    if {[string match "text" $o(tag$i,type)] ==0 } {puts $file "$o(tag$i,type) $o(tag$i,oc) $o(tag$i,x) $o(tag$i,y) $o(tag$i,w) $o(tag$i,lc)"}
	}
    }
    close $file
    return
}

proc OpenFile {} {
    global o count e
    set types {
        {"TopDraw data"         {.dat}     }
        {"All files"            *}
    }
    set file [tk_getOpenFile -filetypes $types \
             -defaultextension .dat]
    if [catch {open $file "r"} file] {
	return
    }
    Clear
    gets $file line
    if {[string match "# TopDraw" $line] > 1} {
	puts stderr "$file is not a TopDraw file"
	return
    } 
    switch $line {
	"# TopDraw Input File" {
# Sort out backward compatibility
	    puts "Old format"
	    while {[gets $file line] > -1} {
		if {[string match "#" [lindex $line 0]]==1} {continue}
		set o(c,ty) [lindex $line 0]
		set o(c,oc) [lindex $line 1]
		set o(c,x) [lindex $line 2]
		set o(c,y) [lindex $line 3]
		set o(c,ts) [lrange $line 4 end]
		set o(c,tc) $o(c,oc)
		set o(c,fn) 12 
		set o(c,ft) Helvetica-Medium 
		set o(c,w)  1
		set o(c,lc) Black 
		switch $o(c,ty) {
		    "text"  {set o(c,y) [$e $o(c,y) - 12]}
		    "line02" {set o(c,y) [$e $o(c,y) - 25]}
		    "line4" {set o(c,x) [$e $o(c,x) - 25]}
		    "line03" {set o(c,x) [$e $o(c,x) + 25]}
		    "line7" {set o(c,y) [$e $o(c,y) - 25]}
		    "line10" {set o(c,x) [$e $o(c,x) - 25]}
		}
		ButtonClick $o(c,x) $o(c,y)
	    }}
# Dont change Nov 2001 unless format changes
	"# TopDraw (Nov 2001) Input File" {    
	    while {[gets $file line] > -1} {
		if {[string match "#" [lindex $line 0]]==1} {continue}
		set o(c,ty) [lindex $line 0]	
		set o(c,oc) [lindex $line 1]
		set o(c,x) [lindex $line 2]
		set o(c,y) [lindex $line 3]
		if { $o(c,ty) == "text"} {
		    set o(c,tc) $o(c,oc)
		    set o(c,fn) [lindex $line 4] 
		    set o(c,ft) [lindex $line 5] 
		    set o(c,ts) [lrange $line 6 end] 
		} else {
		    set o(c,w) [lindex $line 4] 
		    set o(c,lc) [lindex $line 5] 
		}
		ButtonClick $o(c,x) $o(c,y)
	    }}}
    close $file
    return
}

proc Button2Click {x y} {
    global  moveall tobemoved o e oldx oldy
    .canvas delete transient
    if {[info exist tobemoved]} {unset tobemoved}
    if {$moveall == "all objects"} {
	foreach item [.canvas find all] {
	if {[info exist tobemoved]} {
	if {[lsearch $tobemoved [.canvas gettags $item]] ==  -1} {lappend tobemoved [.canvas gettags $item]}
	} else {
	lappend tobemoved [.canvas gettags $item]
	}}}
    if {$moveall == "single object"} {
	foreach item [.canvas gettags [.canvas find closest $x $y 5]] {
	    if {[string match "tag" [string range $item 0 2]] == 1} {
		if {[$e $x-$o($item,x)] <= 25 && [$e $y-$o($item,y)] <= 25} {
		    lappend tobemoved $item
		}}
	}
    }
    set oldx $x
    set oldy $y
    return
}

proc Button2Motion {x y} {
    global o tobemoved e oldx oldy moveall
    .canvas delete transient
    set colour gray
    if {[info exist tobemoved]} {
	foreach item $tobemoved {
	    if {$moveall == "all objects" || [string match "text" $o($item,type)] == 0} {
		set x0 [Pixelise $oldx]
		set y0 [Pixelise $oldy]
		set x1 [Pixelise $x]
		set y1 [Pixelise $y]
		.canvas create rectangle [$e $x1-26] [$e $y1-26] [$e $x1+26] [$e $y1+26] -outline grey50 -tag transient -fill white -stipple gray50
		.canvas create line [$e  $x1-26] [$e $y1] [$e  $x1+26] [$e $y1] -fill grey50 -tag transient  -stipple gray50
		.canvas create line [$e  $x1] [$e $y1-26] [$e  $x1] [$e $y1+26] -fill gray50 -tag transient  -stipple gray50
	    } else {    
		set x0 $oldx
		set y0 $oldy
		set x1 $x
		set y1 $y
		.canvas create oval [$e $x-25] [$e $y-25] [$e $x+25] [$e $y+25] -fill $colour -outline $colour -stipple gray50 -tag transient
	    }
		.canvas move $item [$e $x1-$x0] [$e $y1-$y0]
		set o($item,x) [$e $o($item,x) + $x1 - $x0]
		set o($item,y) [$e $o($item,y) + $y1 - $y0]
	}
                set oldx $x1
                set oldy $y1
    }
    return
}

proc ButtonClick {x y } {
    global o  count e

    set x1 [Pixelise $x]
    set y1 [Pixelise $y]

    switch $o(c,ty) {

	"delete" {
	    .canvas delete transient
	    foreach item [.canvas  find overlapping [$e $x-5] [$e $y-5] [$e $x+5] [$e $y+5]] {
		set item2 [.canvas gettags $item]
		    set o($item2,type) 0 
		    set o($item2,oc) 0 
		    set o($item2,x) 0
		    set o($item2,y) 0
		    set o($item2,ts) 0
		    set o($item2,w) 0
		    set o($item2,tc) 0
		    set o($item2,fn) 0
		    set o($item2,ft) 0
		    .canvas delete $item2 
    }
	    return
	}
	
    }
    incr count 1
    set o(tag$count,type) $o(c,ty)
    set o(tag$count,oc) $o(c,oc)
    set o(tag$count,x) $x1
    set o(tag$count,y) $y1
    set o(tag$count,w) $o(c,w)
    set o(tag$count,lc) $o(c,lc)

    if {[string match "text" $o(c,ty)] == 1} {
	$o(c,ty) $x $y $o(c,tc) tag$count $o(c,fn) $o(c,ft) $o(c,ts)
	set o(tag$count,x) $x
	set o(tag$count,y) $y
	set o(tag$count,ts) $o(c,ts)
	set o(tag$count,fn) $o(c,fn)
	set o(tag$count,tc) $o(c,tc)
	set o(tag$count,ft) $o(c,ft)
	return
    }
    $o(c,ty) $x1 $y1 $o(c,oc) tag$count $o(c,w) $o(c,lc)
}

proc cterm {x1 y1 c i w lc} {
    global e
    .canvas create oval [$e $x1 + -13] [$e $y1 + 0] [$e $x1 + 13] [$e $y1 + -25] -tags $i -width $w -outline $lc
    .canvas create text $x1 [$e $y1 -12] -text "C" -font -*-Helvetica-Bold-R-Normal--20-120-*-*-*-*-*-* -justify center -anchor center -tags $i -fill $lc
    return
}
proc nterm {x1 y1 c i w lc} {
    global e
    .canvas create oval [$e $x1 + -13] [$e $y1 + 0] [$e $x1 + 13] [$e $y1 + -25] -tags $i -width $w -outline $lc
    .canvas create text $x1 [$e $y1 -12] -text "N" -font -*-Helvetica-Bold-R-Normal--20-120-*-*-*-*-*-* -justify center -anchor center -tags $i -fill $lc
    return
}

proc ltcterm {x1 y1 c i w lc} {
    global e
    cterm [$e $x1 -12]  [$e $y1 +12] $c $i $w $lc
    return
}
proc ltnterm {x1 y1 c i w lc} {
    global e
    nterm [$e $x1 -12]  [$e $y1 +12] $c $i $w $lc
    return
}

proc line01 {x1 y1 c i w lc} {
    global e
    .canvas create line $x1 [$e $y1 + 0]  $x1 [$e $y1 + -25] -t $i -j bev -sm yes -w $w -fill $lc
} 
proc line02 {x1 y1 c i w lc} {
    global e
    .canvas create line [$e $x1 + -25] [$e $y1 + 0]  [$e $x1] [$e $y1 + 0] -tags $i  -joinstyle bevel -smooth yes -width $w -fill $lc
} 
proc line03 {x1 y1 c i w lc}  {
    global e
    .canvas create line [$e $x1 + -25] [$e $y1 + -25 ] [$e $x1 + -25] [$e $y1 + -12] [$e $x1 + -12] [$e $y1 + 0 ] [$e $x1 + 0] [$e $y1 + 0] -tags $i -joinstyle bevel -smooth yes -width $w -fill $lc
} 
proc line4 {x1 y1 c i w lc}  {
    global e
    .canvas create line [$e $x1 + 25] [$e $y1 + -25 ] [$e $x1 + 25] [$e $y1 + -12] [$e $x1 + 12] [$e $y1 + 0 ] [$e $x1 + 0] [$e $y1 + 0] -tags $i -joinstyle bevel -smooth yes -width $w -fill $lc
} 
proc line5 {x1 y1 c i w lc}  {
    global e
    .canvas create line $x1 [$e $y1 + 0 ] $x1 [$e $y1 + -13] [$e $x1 + 12] [$e $y1 - 25 ] [$e $x1 + 25] [$e $y1 + -25] -t $i -j b -sm y -w $w -f $lc
} 

proc line6 {x1 y1 c i w lc}  {
    global e
    .canvas create line $x1 [$e $y1 + 0 ] $x1 [$e $y1 + -13]  [$e $x1 + -12] [$e $y1 + -25 ] [$e $x1 + -25] [$e $y1 + -25] -tags $i -joinstyle bevel -smooth yes -width $w -fill $lc
}

proc line7 {x1 y1 c i w lc}  {	
    global e
    .canvas create line $x1 [$e $y1 + 0 ] $x1 [$e $y1 + 13] [$e $x1 + -25] [$e $y1 + 13] [$e $x1 + -25] [$e $y1 + 0] -tags $i -joinstyle bevel -smooth yes -width $w -fill $lc
} 

proc line8 {x1 y1 c i w lc}  {
    global e
    .canvas create line $x1 [$e $y1 + 0 ] $x1 [$e $y1 + -13] [$e $x1 + -25] [$e $y1 + -13] [$e $x1 + -25] [$e $y1 + 0] -tags $i -joinstyle bevel -smooth yes -width $w -fill $lc
} 

proc line10 {x1 y1 c i w lc}  {
    global e
    .canvas create line [$e $x1 + 0] [$e $y1 + 0] [$e $x1 + 0] [$e $y1 + -13] [$e $x1 + 25] [$e $y1 + -13] [$e $x1 + 25] [$e $y1 + -25]  -tags  $i -joinstyle bevel -smooth yes -width $w -fill $lc
} 

proc line11 {x1 y1 c i w lc}  {
    global e
    .canvas create line [$e $x1 + 0] [$e $y1 + 0] [$e $x1 + 0] [$e $y1 + -13] [$e $x1 + -25] [$e $y1 + -13] [$e $x1 + -25] [$e $y1 + -25]  -tags  $i -joinstyle bevel -smooth yes -width $w -fill $lc
} 

proc line7b {x1 y1 c i w lc}  {	
    global e
    .canvas create line [$e $x1 + 0] [$e $y1 + 0 ] [$e $x1 + -13] [$e $y1 + 0] [$e $x1 + -13] [$e $y1 + -25] [$e $x1 + 0] [$e $y1 + -25] -tags $i -joinstyle bevel -smooth yes -width $w -fill $lc
} 

proc line8b {x1 y1 c i w lc}  {	
    global e
    .canvas create line [$e $x1 + 0] [$e $y1 + 0 ] [$e $x1 + 13] [$e $y1 + 0] [$e $x1 + 13] [$e $y1 + -25] [$e $x1 + 0] [$e $y1 + -25] -tags $i -joinstyle bevel -smooth yes -width $w -fill $lc
} 

proc line10b {x1 y1 c i w lc}  {
    global e
    .canvas create line [$e $x1 + 0] [$e $y1 + 0] [$e $x1 + -13] [$e $y1 + 0] [$e $x1 + -13] [$e $y1 + -25] [$e $x1 + -25] [$e $y1 + -25]  -tags  $i -joinstyle bevel -smooth yes -width $w -fill $lc
} 

proc line11b {x1 y1 c i w lc}  {
    global e
    .canvas create line [$e $x1 + 0] [$e $y1 + 0] [$e $x1 + -13] [$e $y1 + 0] [$e $x1 + -13] [$e $y1 + 25] [$e $x1 + -25] [$e $y1 + 25]  -tags  $i -joinstyle bevel -smooth yes -width $w -fill $lc
} 

proc line12a  {x1 y1 c i w lc}  {
# diagonal tl-br
    global e
    .canvas create line $x1 $y1 [$e $x1 + -25] [$e $y1 + -25]  -tags  $i  -joinstyle bevel -smooth yes -width $w -fill $lc
}

proc line13a  {x1 y1 c i w lc}  {
# diagonal tl-br
    global e
    .canvas create line $x1 $y1 [$e $x1 + -5] [$e $y1 + -5] [$e $x1 + -13] [$e $y1 + -25] [$e $x1 + -25] [$e $y1 + -25]  -tags  $i  -joinstyle bevel -smooth yes -width $w -fill $lc
}

proc line14a  {x1 y1 c i w lc}  {
# diagonal tl-br
    global e
    .canvas create line $x1 $y1 [$e $x1 + -5] [$e $y1 + -5] [$e $x1 + -25] [$e $y1 + -13] [$e $x1 + -25] [$e $y1 + -25]  -tags  $i  -joinstyle bevel -smooth yes -width $w -fill $lc
}

proc line15a  {x1 y1 c i w lc}  {
# diagonal tl-br
    global e
    .canvas create line $x1 $y1 [$e $x1 + -5] [$e $y1 + 5] [$e $x1 + -13] [$e $y1 + 25] [$e $x1 + -25] [$e $y1 + 25]  -tags  $i  -joinstyle bevel -smooth yes -width $w -fill $lc
}

proc line16a  {x1 y1 c i w lc}  {
# diagonal tl-br
    global e
    .canvas create line $x1 $y1 [$e $x1 + -5] [$e $y1 + 5] [$e $x1 + -25] [$e $y1 + 13] [$e $x1 + -25] [$e $y1 + 25]  -tags  $i  -joinstyle bevel -smooth yes -width $w -fill $lc
}

proc line12b  {x1 y1 c i w lc}  {
# diagonal tl-br
    global e
    .canvas create line $x1 $y1 [$e $x1 + 25] [$e $y1 + -25]  -tags  $i  -joinstyle bevel -smooth yes -width $w -fill $lc
}

proc line13b  {x1 y1 c i w lc}  {
# diagonal tl-br
    global e
    .canvas create line $x1 $y1 [$e $x1 + 5] [$e $y1 + -5] [$e $x1 + 13] [$e $y1 + -25] [$e $x1 + 25] [$e $y1 + -25]  -tags  $i  -joinstyle bevel -smooth yes -width $w -fill $lc
}

proc line14b  {x1 y1 c i w lc}  {
# diagonal tl-br
    global e
    .canvas create line $x1 $y1 [$e $x1 + 5] [$e $y1 + -5] [$e $x1 + 25] [$e $y1 + -13] [$e $x1 + 25] [$e $y1 + -25]  -tags  $i  -joinstyle bevel -smooth yes -width $w -fill $lc
}

proc line15b  {x1 y1 c i w lc}  {
# diagonal tl-br
    global e
    .canvas create line $x1 $y1 [$e $x1 + 5] [$e $y1 + 5] [$e $x1 + 13] [$e $y1 + 25] [$e $x1 + 25] [$e $y1 + 25]  -tags  $i  -joinstyle bevel -smooth yes -width $w -fill $lc
}

proc line16b  {x1 y1 c i w lc}  {
# diagonal tl-br
    global e
    .canvas create line $x1 $y1 [$e $x1 + 5] [$e $y1 + 5] [$e $x1 + 25] [$e $y1 + 13] [$e $x1 + 25] [$e $y1 + 25]  -tags  $i  -joinstyle bevel -smooth yes -width $w -fill $lc
}

proc helixtop {x1 y1 c i w lc}  {
    global e
    .canvas create polygon \
	[$e $x1 + 15] [$e $y1 + -19] [$e $x1 + -15] [$e $y1 + -19 ]\
	[$e $x1 + -15] [$e $y1 + 0] [$e $x1 + 15] [$e $y1 + 0]\
	-fill $c -tag $i -outline $c
    .canvas create line\
	[$e $x1 + 15] [$e $y1 + -19] [$e $x1 + 15] [$e $y1 + 1]\
	-tags $i  -width $w -fill $lc
    .canvas create line\
	[$e $x1 + -15] [$e $y1 + -19] [$e $x1 + -15] [$e $y1 + 1]\
	-tags $i  -width $w -fill $lc
    .canvas create oval \
	[$e $x1 + -15] [$e $y1 + -13] [$e $x1 + 15] [$e $y1 + -25]\
	-fill $c -tags $i -outline $lc   -width $w
    .canvas create line \
	[$e $x1] [$e $y1 + -19] [$e $x1] [$e $y1 + -25]\
	-tags $i  -width $w -fill $lc
}

proc helixshaft {x1 y1 c i w lc}  {
    global e
    .canvas create polygon \
	[$e $x1 + 15] [$e $y1 + 0] [$e $x1 + -15] [$e $y1 + 0]\
	[$e $x1 + -15] [$e $y1 + -25] [$e $x1 + 15] [$e $y1 + -25]\
	-fill $c -tag $i -outline $c
    .canvas create line\
	[$e $x1 + 15] [$e $y1 + 1] [$e $x1 + 15] [$e $y1 + -26]\
	-tags $i -width $w -fill $lc
    .canvas create line\
	[$e $x1 + -15] [$e $y1 + 1] [$e $x1 + -15] [$e $y1 + -26]\
	-tags $i -width $w -fill $lc
}

proc helixbottom {x1 y1 c i w lc}  {
    global e
    .canvas create oval \
	[$e $x1 + -15] [$e $y1 + -12] [$e $x1 + 15] [$e $y1 + 0]\
	-fill $c -tags $i -width $w -outline $lc
    .canvas create polygon \
	[$e $x1 + 15] [$e $y1 + -6] [$e $x1 + -15] [$e $y1 + -6 ]\
	[$e $x1 + -15] [$e $y1 + -25] [$e $x1 + 15] [$e $y1 + -25]\
	-fill $c -tag $i -outline $c
    .canvas create line\
	[$e $x1 + 15] [$e $y1 + -5] [$e $x1 + 15] [$e $y1 + -26]\
	-tags $i -width $w -fill $lc
    .canvas create line\
	[$e $x1 + -15] [$e $y1 + -5] [$e $x1 + -15] [$e $y1 + -26]\
	-tags $i -width $w -fill $lc
}

proc dnarrowhead {x1 y1 c i w lc}  {
    global e
    .canvas create polygon \
	[$e $x1 + -10] [$e $y1 + -25] [$e $x1 + -10] [$e $y1 + -20]\
	[$e $x1 + -20] [$e $y1 + -20] [$e $x1 + 0] [$e $y1 + 0] \
	[$e $x1 + 20] [$e $y1 + -20] [$e $x1 + 10] [$e $y1 + -20] \
	[$e $x1 + 10] [$e $y1 + -25] [$e $x1 + -10] [$e $y1 + -25]\
	-fill $c -tag $i -outline $c
    .canvas create line\
	 [$e $x1 + -10] [$e $y1 + -26] [$e $x1 + -10] [$e $y1 + -20]\
         [$e $x1 + -20] [$e $y1 + -20] [$e $x1 + 0] [$e $y1 + 0]\
         [$e $x1 + 20] [$e $y1 + -20] [$e $x1 + 10] [$e $y1 + -20] \
         [$e $x1 + 10] [$e $y1 + -26] \
	-tags $i -width $w -fill $lc
}
proc uparrowhead {x1 y1 c i w lc} {
    global e
    .canvas create polygon \
	[$e $x1 + -10] [$e $y1 + 0] [$e $x1 + -10] [$e $y1 + -5] \
	[$e $x1 + -20] [$e $y1 + -5] [$e $x1 + 0] [$e $y1 + -25] \
	[$e $x1 + 20] [$e $y1 + -5] [$e $x1 + 10] [$e $y1 + -5] \
	[$e $x1 + 10] [$e $y1 + 0] [$e $x1 + -10] [$e $y1 + 0]\
	-fill $c -tag $i -outline $c
    .canvas create line \
 	 [$e $x1 + -10] [$e $y1 + 1 ] [$e $x1 + -10] [$e $y1 - 5]\
          [$e $x1 + -20] [$e $y1 - 5] [$e $x1 + 0] [$e $y1 - 25]\
           [$e $x1 + 20] [$e $y1 - 5] [$e $x1 + 10] [$e $y1 -5]\
           [$e $x1 + 10] [$e $y1 + 1]\
 	-tags $i -width $w -fill $lc
}


proc uparrowtail {x1 y1 c i w lc}  {
    global e
    .canvas create polygon \
	[$e $x1 + 10] [$e $y1 + 0] [$e $x1 + -10] [$e $y1 + 0]\
	[$e $x1 + -10] [$e $y1 + -25] [$e $x1 + 10] [$e $y1 + -25]\
	-fill $c -tag $i -outline $c
    .canvas create line \
	[$e $x1 + 10] [$e $y1 + -26] [$e $x1 + 10] [$e $y1 + 0]\
        [$e $x1 + -10] [$e $y1 + 0] [$e $x1 + -10] [$e $y1 + -26] \
	 -tags $i -width $w -fill $lc
}

proc dnarrowtail {x1 y1 c i w lc}  {
    global e
    .canvas create polygon \
	[$e $x1 + 10] [$e $y1 + 0] [$e $x1 + -10] [$e $y1 + 0]\
	[$e $x1 + -10] [$e $y1 + -25] [$e $x1 + 10] [$e $y1 + -25]\
	-fill $c -tag $i -outline $c
    .canvas create line \
        [$e $x1 + -10] [$e $y1 + 1] [$e $x1 + -10] [$e $y1 + -25] \
	[$e $x1 + 10] [$e $y1 + -25] [$e $x1 + 10] [$e $y1 + 1]\
	 -tags $i -width $w -fill $lc
}

proc arrowshaft {x1 y1 c i w lc}  {
    global e
    .canvas create polygon \
	[$e $x1 + 10] [$e $y1 + 0] [$e $x1 + -10] [$e $y1 + 0]\
	[$e $x1 + -10] [$e $y1 + -25] [$e $x1 + 10] [$e $y1 + -25]\
	-fill $c -tag $i -outline $c
    .canvas create line \
	[$e  $x1 + 10]  [$e $y1 + 1] [$e $x1 + 10] [$e $y1 + -26]\
	-tags $i -width $w -fill $lc
    .canvas create line \
	[$e  $x1 + -10]  [$e $y1 + 1] [$e $x1 + -10] [$e $y1 + -26]\
	-tags $i -width $w -fill $lc
}


proc lthelixtop {x1 y1 c i w lc}  {
    global e
    .canvas create polygon \
	[$e $x1 + -19] [$e $y1 + 15] [$e $x1 + -19 ] [$e $y1 + -15] \
	[$e $x1 + 0] [$e $y1 + -15] [$e $x1 + 0] [$e $y1 + 15] \
	-fill $c -tag $i -outline $c
    .canvas create line\
	[$e $x1 + -19] [$e $y1 + 15] [$e $x1 + 1] [$e $y1 + 15]\
	-tags $i -width $w -fill $lc
    .canvas create line\
	 [$e $x1 + -19] [$e $y1 + -15] [$e $x1 + 1] [$e $y1 + -15]\
	-tags $i -width $w -fill $lc
    .canvas create oval \
	[$e $x1 + -13] [$e $y1 + -15] [$e $x1 + -25] [$e $y1 + 15]\
	-fill $c -tags $i -width $w -outline $lc
    .canvas create line \
	[$e $x1 + -19] [$e $y1] [$e $x1 + -25] [$e $y1]\
	-tags $i -width $w -fill $lc
}

proc lthelixshaft {x1 y1 c i w lc}  {
    global e
    .canvas create polygon \
	[$e $x1 + 0] [$e $y1 + 15] [$e $x1 + 0] [$e $y1 + -15]\
	[$e $x1 + -25] [$e $y1 + -15] [$e $x1 + -25] [$e $y1 + 15] \
	-fill $c -tag $i -outline $c
    .canvas create line\
	[$e $x1 + 1] [$e $y1 + 15] [$e $x1 + -26] [$e $y1 + 15] \
	-tags $i -width $w -fill $lc
    .canvas create line\
	[$e $x1 + 1] [$e $y1 + -15] [$e $x1 + -26] [$e $y1 + -15]\
	-tags $i -width $w -fill $lc
}

proc lthelixbottom {x1 y1 c i w lc}  {
    global e
    .canvas create oval \
[$e $x1 + -12] [$e $y1 + -15] [$e $x1 + 0] [$e $y1 + 15] \
        -fill $c -tags $i -width $w -outline $lc
    .canvas create polygon \
[$e $x1 + -6] [$e $y1 + 15] [$e $x1 + -6 ] [$e $y1 + -15] \
[$e $x1 + -25] [$e $y1 + -15] [$e $x1 + -25] [$e $y1 + 15] \
        -fill $c -tag $i -outline $c
    .canvas create line\
[$e $x1 + -5] [$e $y1 + 15] [$e $x1 + -25] [$e $y1 + 15] \
        -tags $i -width $w -fill $lc
    .canvas create line\
[$e $x1 + -5] [$e $y1 + -15] [$e $x1 + -25] [$e $y1 + -15] \
        -tags $i -width $w -fill $lc
}

proc rtarrowhead {x1 y1 c i w lc}  {
    global e
    .canvas create polygon \
[$e $x1 + -25] [$e $y1 + -10] [$e $x1 + -20]  [$e $y1 + -10] \
[$e $x1 + -20] [$e $y1 + -20] [$e $x1 + 0]  [$e $y1 + 0] \
[$e $x1 + -20] [$e $y1 + 20] [$e $x1 + -20]  [$e $y1 + 10] \
[$e $x1 + -25] [$e $y1 + 10] [$e $x1 + -25] [$e $y1 + -10] \
        -fill $c -tag $i -outline $c
    .canvas create line \
[$e $x1 + -25] [$e $y1 + -10] [$e $x1 + -20] [$e $y1 + -10] \
[$e $x1 + -20] [$e $y1 + -20] [$e $x1 + 0] [$e $y1 + 0] \
[$e $x1 + -20] [$e $y1 + 20] [$e $x1 + -20]  [$e $y1 + 10] \
[$e $x1 + -25] [$e $y1 + 10] \
        -tags $i -width $w -fill $lc
}
proc ltarrowtail {x1 y1 c i w lc}  {
    global e
    .canvas create polygon \
[$e $x1 + 0] [$e $y1 + 10] [$e $x1 + 0] [$e $y1 + -10] \
[$e $x1 + -25] [$e $y1 + -10] [$e $x1 + -25] [$e $y1 + 10] \
        -fill $c -tag $i -outline $c
    .canvas create line \
[$e $x1 + -26] [$e $y1 + 10] [$e $x1 + 0] [$e $y1 + 10] \
[$e $x1 + 0] [$e $y1 + -10] [$e $x1 + -26]  [$e $y1 + -10] \
         -tags $i -width $w -fill $lc
}

proc rtarrowtail {x1 y1 c i w lc}  {
    global e
    .canvas create polygon \
[$e $x1 + 0] [$e $y1 + 10] [$e $x1 + 0] [$e $y1 + -10] \
[$e $x1 + -25] [$e $y1 + -10] [$e $x1 + -25] [$e $y1 + 10] \
        -fill $c -tag $i -outline $c
    .canvas create line \
[$e $x1 + 1] [$e $y1 + -10] [$e $x1 + -25]  [$e $y1 + -10] \
[$e $x1 + -25] [$e $y1 + 10] [$e $x1 + 1] [$e $y1 + 10] \
         -tags $i -width $w -fill $lc
}

proc ltarrowshaft {x1 y1 c i w lc}  {
    global e
    .canvas create polygon \
[$e $x1 + 0] [$e $y1 + 10] [$e $x1 + 0] [$e $y1 + -10] \
[$e $x1 + -25] [$e $y1 + -10] [$e $x1 + -25] [$e $y1 + 10] \
        -fill $c -tag $i -outline $c
    .canvas create line \
[$e $x1 + 1] [$e  $y1 + 10]  [$e $x1 + -25] [$e $y1 + 10] \
        -tags $i -width $w -fill $lc
    .canvas create line \
[$e $x1 + 1] [$e  $y1 + -10]  [$e $x1 + -25] [$e $y1 + -10] \
        -tags $i -width $w -fill $lc
}

proc ltarrowhead {x1 y1 c i w lc} {
    global e
    .canvas create polygon \
[$e $x1] [$e $y1-10] [$e $x1-5] [$e $y1-10] \
[$e $x1-5] [$e $y1-20] [$e $x1 - 25] [$e $y1+0] \
[$e $x1-5] [$e $y1+20] [$e $x1-5] [$e $y1+10] \
[$e $x1] [$e $y1+10] [$e $x1] [$e $y1-10] \
        -fill $c -tag $i -outline $c
    .canvas create line \
[$e $x1 +1] [$e $y1 + -10] [$e $x1 - 5] [$e $y1 + -10] \
[$e $x1 - 5] [$e $y1 + -20] [$e $x1 - 25] [$e $y1 + 0] \
[$e $x1 - 5] [$e $y1 + 20] [$e $x1 -5] [$e $y1 + 10] \
[$e $x1 +1] [$e $y1 + 10] \
        -tags $i -width $w -fill $lc
}


proc text {x1 y1 c i fn ft t} {
    global e
    .canvas create text $x1 $y1 -fill $c -text $t -anchor ce -tags $i -font \
-*-$ft-R-Normal--$fn-120-*-*-*-*-*-*}

proc DrawBox {x y} {
    global o e
    .canvas delete transient
    set colour $o(c,oc)
    switch $o(c,ty) {
	"text" {
	    $o(c,ty) $x $y $o(c,tc) transient $o(c,fn) $o(c,ft) $o(c,ts)	    
	    .canvas create oval [$e $x-25] [$e $y-25] [$e $x+25] [$e $y+25] -outline $colour -tag transient -fill white -stipple gray50
	    return}
	"delete" {
	    .canvas create oval [$e $x-8] [$e $y-8] [$e $x+8] [$e $y+8] -outline pink -tag transient -fill white -stipple gray50
	    return}
    }
    set x1 [Pixelise $x]
    set y1 [Pixelise $y]
    if {[string match "delete" $o(c,ty)]==0} {$o(c,ty)  $x1 $y1 $o(c,oc) transient $o(c,w) $o(c,lc)}
     .canvas create rectangle [$e $x1-26] [$e $y1-26] [$e $x1+26] [$e $y1+26] -outline pink -tag transient -fill white -stipple gray50
     .canvas create line [$e  $x1-26] [$e $y1] [$e  $x1+26] [$e $y1] -fill pink -tag transient  -stipple gray50
     .canvas create line [$e  $x1] [$e $y1-26] [$e  $x1] [$e $y1+26] -fill pink -tag transient  -stipple gray50
    return
}

proc WritePS {} {
    .canvas delete transient 
    set types {
        {"Postscript File"         {.ps}     }
        {"All files"            *}
    }
    set file [tk_getSaveFile -filetypes $types \
            -initialfile topdraw -defaultextension .ps]
    .canvas postscript -pageanchor sw -pagex 0 -pagey 0 -file "$file"
}

proc Clear {} {
    global count
    foreach item [.canvas  find all] { .canvas delete $item }
    foreach item "type colour x y text" {
	set i 0
	while {$i<$count} {
	    incr i 1
	    set o(tag$i,$item) 0
	}
    }
    set count 0
}

proc Pixelise {in} {
    global e
    set out [$e (abs(($in+12)/25)*25)]
    return $out
}

proc Example {} {
global o
if {[ tk_messageBox -icon warning -type yesno \
	-title Message -parent .td\
	      -message "(This will clobber your current drawing. If you haven't saved it, select \"No\" and save it first.)\nContinue?"] == "no"} {return}

.canvas delete transient
Clear
    foreach line {"arrowshaft magenta 175 225 3 Red" "arrowshaft magenta 225 225 3 Red" "arrowshaft magenta 275 225 3 Red" "arrowshaft magenta 325 225 3 Red" "arrowshaft magenta 375 225 3 Red" "arrowshaft magenta 375 200 3 Red" "arrowshaft magenta 325 200 3 Red" "uparrowhead magenta 175 200 3 Red" "uparrowhead magenta 275 200 3 Red" "uparrowhead magenta 325 175 3 Red" "dnarrowtail magenta 375 175 3 Red" "dnarrowtail magenta 225 200 3 Red" "uparrowtail magenta 175 250 3 Red" "uparrowtail magenta 275 250 3 Red" "uparrowtail magenta 325 250 3 Red" "dnarrowhead magenta 225 250 3 Red" "dnarrowhead magenta 375 250 3 Red" "line5 magenta 325 150 3 Red" "line6 magenta 375 150 3 Red" "line8 magenta 300 175 3 Red" "line6 magenta 225 175 3 Red" "line5 magenta 175 175 3 Red" "line01 magenta 175 275 3 Red" "helixtop green 175 300 3 DarkGreen" "helixtop green 325 325 3 DarkGreen" "helixshaft green 175 325 3 DarkGreen" "helixshaft green 325 350 3 DarkGreen" "helixbottom green 175 350 3 DarkGreen" "helixbottom green 325 375 3 DarkGreen" "line10 green 275 300 3 DarkGreen" "line10 green 275 300 3 DarkGreen" "line10 green 275 300 3 DarkGreen" "line01 green 275 325 3 DarkGreen" "helixbottom green 325 375 3 DarkGreen" "line01 green 275 325 3 DarkGreen" "line01 green 275 350 3 DarkGreen" "line01 green 275 375 3 DarkGreen" "line03 green 400 325 3 DarkGreen" "line02 green 425 325 3 DarkGreen" "line6 green 450 350 3 DarkGreen" "line01 green 175 375 3 DarkGreen" "dnarrowtail Cyan 275 425 3 Blue" "dnarrowtail Cyan 375 425 3 Blue" "dnarrowhead Cyan 275 450 3 Blue" "dnarrowhead Cyan 375 450 3 Blue" "uparrowtail Cyan 325 450 3 Blue" "uparrowtail Cyan 425 450 3 Blue" "uparrowhead Cyan 325 425 3 Blue" "uparrowhead Cyan 425 425 3 Blue" "line03 black 250 275 3 Red" "line4 black 250 275 3 Red" "line01 black 300 200 3 Red" "line01 black 300 225 3 Red" "line01 black 300 250 3 Red" "line01 black 300 275 3 Red" "line01 black 325 275 3 Red" "line01 black 375 275 3 Red" "line01 black 325 300 3 DarkGreen" "line01 black 375 300 3 DarkGreen" "line01 black 325 400 3 Blue" "line01 black 275 400 3 Blue" "line03 black 300 475 3 Blue" "line4 black 300 475 3 Blue" "line5 black 375 400 3 Blue" "line6 black 425 400 3 Blue" "line7 black 450 450 3 Blue" "line01 black 450 450 3 Blue" "line01 black 450 425 3 Blue" "line01 black 450 400 3 Blue" "line01 black 450 375 3 DarkGreen" "line01 black 375 475 3 Blue" "helixtop Green 375 500 3 DarkGreen" "helixbottom Green 375 525 3 DarkGreen" "text black 376 503 18 Helvetica-Bold 3" "text black 177 313 18 Helvetica-Bold 1" "text black 326 341 18 Helvetica-Bold 2" "nterm Green 175 400 3 Blue" "cterm Green 375 575 3 Red" "line01 Green 375 550 3 DarkGreen" "text Blue 275 417 18 Helvetica-Bold D" "text Blue 326 432 18 Helvetica-Bold E" "text Blue 376 416 18 Helvetica-Bold H" "text Blue 425 432 18 Helvetica-Bold I" "text red4 177 212 18 Helvetica-Bold A" "text red4 225 211 18 Helvetica-Bold B" "text red4 275 211 18 Helvetica-Bold C" "text red4 325 211 18 Helvetica-Bold F" "text red4 375 212 18 Helvetica-Bold G" "text Black 181 486 20 Times-Bold 1HH1" "text Black 219 512 18 Times-Medium Bond et al (2001)" "text Black 215 537 18 Times-Medium PNAS, 98, 5509"} {
    set o(c,ty) [lindex $line 0]	
    set o(c,oc) [lindex $line 1]
    set o(c,x) [lindex $line 2]
    set o(c,y) [lindex $line 3]
    if { $o(c,ty) == "text"} {
	set o(c,tc) $o(c,oc)
	set o(c,fn) [lindex $line 4] 
	set o(c,ft) [lindex $line 5] 
	set o(c,ts) [lrange $line 6 end] 
    } else {
	set o(c,w) [lindex $line 4] 
	set o(c,lc) [lindex $line 5] 
    }
    ButtonClick $o(c,x) $o(c,y)
}
}

proc Help {} {
set t "=======================================================
TopDraw (Sep 2002) ==================================== 
(c) Charlie Bond, University of Dundee, 2000-2002 =====
C.S.Bond@dundee.ac.uk =================================
=======================================================
Select an item type by clicking on it.
(Colours are determined by the selection boxes, not the
colour on the icon!)

Select fillcolour, linecolour and linewidth, then 
place the item on the canvas by clicking at the correct
position.

Move it by dragging it with middle mouse button.

Delete it by clicking 'Delete' then clicking the 
unwanted item.

To place text, set the fontsize and colour and type the 
text in the box, followed by Enter/Return.
Then you can place/move/delete it as described above.

Objects can't be pushed underneath previously drawn 
objects. Place background objects first.

If you wish to move everything (e.g. you started too close
to the edge), activate the \"Move all objects\" button.

Keep your drawing to the lower left side of the canvas
to make further processing of postscript files easier.

Please cite:
Bond, C.S. (2003) Bioinformatics, 19, 311-312
if used for publication
"
    .canvas delete transient
    .canvas create rectangle 10 10 650 800 -stipple gray75 -fill white -tags transient
    .canvas create text 15 15 -anchor nw -fill black -font [font create -size 12 -weight bold] -text $t -tags transient
}
#Just so Help shows up on startup
Help
