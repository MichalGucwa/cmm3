#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$

proc Blt_ActiveLegend { graph } {
    blt::ActiveLegend $graph
}

proc Blt_Crosshairs { graph } {
    blt::Crosshairs $graph 
}

proc Blt_ZoomStack { graph } {
    blt::ZoomStack $graph
}

proc Blt_EnableZoom { graph } {
    blt::EnableZoom $graph
}

proc Blt_PrintKey { graph } {
    blt::PrintKey $graph
}

proc Blt_ClosestPoint { graph } {
    blt::ClosestPoint $graph
}

proc Blt_ResetZoom { graph } {
    blt::ResetZoom $graph
}

#
# The following procedures that reside in the "blt" namespace are
# supposed to be private.
#

proc blt::ActiveLegend { graph } {
    global activeEntry

    set activeEntry($graph) "-1"
    bind bltActiveLegend <Motion>  {
        blt::ActivateLegend %W %x %y
    }    
    blt::AddBindTag $graph bltActiveLegend 
}

proc blt::Crosshairs { graph } {
    $graph crosshairs on
    bind bltCrosshairs <Any-Motion>   {
        %W crosshairs configure -position @%x,%y 
    }
    $graph crosshairs configure -color red
    blt::AddBindTag $graph bltCrosshairs  
}

proc blt::ZoomStack { graph } {
    global zoomInfo

    set zoomInfo($graph,A,x) {}
    set zoomInfo($graph,A,y) {}
    set zoomInfo($graph,B,x) {}
    set zoomInfo($graph,B,y) {}
    set zoomInfo($graph,stack) {}
    set zoomInfo($graph,corner) A
    
    # This binding now in EnableZoom (pjx)
#    bind $graph <1> { 
#       blt::SetZoomPoint %W %x %y 
#    }
    bind $graph <ButtonPress-3> {
        blt::ResetZoom %W 
    }
}

proc blt::EnableZoom { graph } {
    bind $graph <1> { 
        blt::SetZoomPoint %W %x %y 
    }
    set title "Click in window to set \n corner of zoom"
    $graph marker create text -name "zoomTitle" -text $title \
        -bg yellow  \
        -justify left \
        -coords {-Inf Inf} -anchor nw -bg {} 
}

proc blt::PrintKey { graph } {
    bind bltPrintGraph <Shift-ButtonRelease-3>  {
        %W postscript output "out.ps"  -landscape yes -maxpect yes -decorations
yes
        puts stdout "wrote file \"out.ps\"."
        flush stdout
        break
    }
    blt::AddBindTag $graph bltPrintGraph 
}

proc blt::ClosestPoint { graph } {
    bind bltClosestPoint <Control-ButtonPress-1>  {
        blt::FindElement %W %x %y
        break
    }
    blt::AddBindTag $graph bltClosestPoint 
}

proc blt::AddBindTag { graph name } {
    set oldtags [bindtags $graph]
    if { [lsearch $oldtags $name] < 0 } {
        bindtags $graph [concat $name $oldtags]
    }
}

proc blt::ActivateLegend { graph x y } {
    global activeEntry
    
    set old $activeEntry($graph)
    set new [$graph legend get @$x,$y]
    if { $old != $new } {
        if { $old != "-1" } {
            eval $graph legend deactivate $old
            eval $graph element deactivate $old
        }
        if { $new != "" } {
            eval $graph legend activate $new
            eval $graph element activate $new
        }
    }
    set activeEntry($graph) $new
}

proc blt::FindElement { graph x y } {
    if ![$graph element closest $x $y info -interpolate yes] {
        beep
        return
    }
    # --------------------------------------------------------------
    # find(name)                - element Id
    # find(index)               - index of closest point
    # find(x) find(y)           - coordinates of closest point
    #                             or closest point on line segment.
    # find(dist)                - distance from sample coordinate
    # --------------------------------------------------------------
    set markerName "bltClosest_$info(name)"
    catch { $graph marker delete $markerName }
    $graph marker create text -coords { $info(x) $info(y) } \
        -name $markerName \
        -text "$info(name): $info(dist)\nindex $info(index)" \
        -font *lucida*-r-*-10-* \
        -anchor center -justify left \
        -yoffset 0 -bg {}

    set coords [$graph invtransform $x $y]
    set nx [lindex $coords 0]
    set ny [lindex $coords 1]

    $graph marker create line -coords "$nx $ny $info(x) $info(y)" \
        -name line.$markerName 

    blt::FlashPoint $graph $info(name) $info(index) 10
    blt::FlashPoint $graph $info(name) [expr $info(index) + 1] 10
}

proc blt::FlashPoint { graph name index count } {
    if { $count & 1 } {
        $graph element deactivate $name 
    } else {
        $graph element activate $name $index
    }
    incr count -1
    if { $count > 0 } {
        after 200 blt::FlashPoint $graph $name $index $count
        update
    } else {
        eval $graph marker delete [$graph marker names "bltClosest_*"]
    }
}

proc blt::GetCoords { graph x y index } {
    #
    # We're using the default axes, instead of transforming through
    # the specific axes, because it handles inverted axes automatically
    #
    #puts stderr "$x,$y ==>" nonewline

    set coords [$graph invtransform $x $y]
    set nx [lindex $coords 0]
    set ny [lindex $coords 1]

    set x $nx
    set y $ny

    scan [$graph xaxis limits] "%s %s" xmin xmax
    scan [$graph yaxis limits] "%s %s" ymin ymax

     set padx [expr ($xmax - $xmin) * 0.02]
     set pady [expr ($ymax - $ymin) * 0.02]
     if { $x > $xmax } { 
        set x [expr $xmax + $padx]
     } elseif { $x < $xmin } { 
        set x [expr $xmin - $padx]
     }
     if { $y > $ymax } { 
        set y [expr $ymax + $pady]
     } elseif { $y < $ymin } { 
        set y [expr $ymin - $pady]
     }

    global zoomInfo
    set zoomInfo($graph,$index,x) $x
    set zoomInfo($graph,$index,y) $y
}

proc blt::MarkPoint { graph index } {
    global zoomInfo
    set x $zoomInfo($graph,$index,x)
    set y $zoomInfo($graph,$index,y)

    set marker "zoomText_$index"
    set text [format "x=%.4g\ny=%.4g" $x $y] 

    if [$graph marker exists $marker] {
        $graph marker configure $marker -coords { $x $y } -text $text 
    } else {
        $graph marker create text -coords { $x $y } -name $marker \
            -font *lucida*-r-*-10-* \
            -text $text -anchor center -bg {} -justify left
    }
}

proc blt::DestroyZoomTitle { graph } {
    global zoomInfo

    if { $zoomInfo($graph,corner) == "A" } {
        catch { $graph marker delete "zoomTitle" }
    }
}

proc blt::PopZoom { graph } {
    global zoomInfo

    set zoomStack $zoomInfo($graph,stack)
    if { [llength $zoomStack] > 0 } {
        set cmd [lindex $zoomStack 0]
        set zoomInfo($graph,stack) [lrange $zoomStack 1 end]
        eval $cmd
        blt::ZoomTitleLast $graph
        busy hold $graph
        update
        after 2000 "blt::DestroyZoomTitle $graph"
        busy release $graph
    } else {
        catch { $graph marker delete "zoomTitle" }
    }
}

# Push the old axis limits on the stack and set the new ones

proc blt::PushZoom { graph } {
    eval $graph marker delete [$graph marker names "zoom*"]

    global zoomInfo
    set x1 $zoomInfo($graph,A,x)
    set y1 $zoomInfo($graph,A,y)
    set x2 $zoomInfo($graph,B,x)
    set y2 $zoomInfo($graph,B,y)

    if { ($x1 == $x2) && ($y1 == $y2) } { 
        # No delta, revert to start
        return
    }

    set cmd [format {
        %s xaxis configure -min "%s" -max "%s"
        %s yaxis configure -min "%s" -max "%s"
    } $graph [$graph xaxis cget -min] [$graph xaxis cget -max] \
                 $graph [$graph yaxis cget -min] [$graph yaxis cget -max] ]

    if { $x1 > $x2 } { 
        $graph xaxis configure -min $x2 -max $x1 
    } elseif { $x1 < $x2 } {
        $graph xaxis configure -min $x1 -max $x2
    } 
    if { $y1 > $y2 } { 
        $graph yaxis configure -min $y2 -max $y1
    } elseif { $y1 < $y2 } {
        $graph yaxis configure -min $y1 -max $y2
    } 
    set zoomInfo($graph,stack) [linsert $zoomInfo($graph,stack) 0 $cmd]

    busy hold $graph
    update
    busy release $graph
}

proc blt::ResetZoom { graph } {
    global zoomInfo

    eval $graph marker delete [$graph marker names "zoom*"]
    if { $zoomInfo($graph,corner) == "A" } {
        # Reset the whole axis
        blt::PopZoom $graph
    } else {
        set zoomInfo($graph,corner) A
        bind $graph <Motion> { }
    }
    # Need to unbind the <1> button too
    bind $graph <1> {  }
}

proc blt::ZoomTitleNext { graph } {
    global zoomInfo

    set level [expr [llength $zoomInfo($graph,stack)] + 1]
    set title "Zoom #$level"
    $graph marker create text -name "zoomTitle" -text $title \
        -font -*-helvetica-bold-o-*-*-18-*-*-*-*-*-*-* \
        -bg yellow  \
        -coords {-Inf Inf} -anchor nw -bg {} 
}

proc blt::ZoomTitleLast { graph } {
    global zoomInfo

    set level [llength $zoomInfo($graph,stack)]
    if { $level > 0 } {
        set title "Zoom #$level"
        $graph marker create text -name "zoomTitle" -text $title \
                -coords {-Inf Inf} -anchor nw -bg {} 
    }
}

proc blt::SetZoomPoint { graph x y } {
    global zoomInfo

    blt::GetCoords $graph $x $y $zoomInfo($graph,corner)
    if { $zoomInfo($graph,corner) == "A" } {

        # First corner selected, start watching motion events

        #blt::MarkPoint $graph A
        blt::ZoomTitleNext $graph 
        bind $graph <Any-Motion> { 
            blt::GetCoords %W %x %y B
            #blt::MarkPoint $graph B
            blt::Box %W
        }
        set zoomInfo($graph,corner) B
    } else {
        bind $graph <Any-Motion> { }
        blt::PushZoom $graph 
        set zoomInfo($graph,corner) A
        # Unbind button-1 to disable the zoom
        bind $graph <1> { }
    }
}

proc blt::Box { graph } {
    global zoomInfo

    if { $zoomInfo($graph,A,x) > $zoomInfo($graph,B,x) } { 
        set x1 $zoomInfo($graph,B,x)
        set x2 $zoomInfo($graph,A,x)
        set y1 $zoomInfo($graph,B,y)
        set y2 $zoomInfo($graph,A,y)
    } else {
        set x1 $zoomInfo($graph,A,x)
        set x2 $zoomInfo($graph,B,x)
        set y1 $zoomInfo($graph,A,y)
        set y2 $zoomInfo($graph,B,y)
    }
    set coords { $x1 $y1 $x2 $y1 $x2 $y2 $x1 $y2 $x1 $y1 }
    if { [$graph marker exists "zoomOutline"] } {
        $graph marker configure "zoomOutline" -coords $coords
    } else {
        $graph marker create line -coords $coords -name "zoomOutline" \
            -dashes { 6 4 } -linewidth 2 \
            -mapx [$graph xaxis use] -mapy [$graph yaxis use]
    }
    $graph marker before "zoomOutline"
}
