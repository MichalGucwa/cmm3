#Declaration of all methods 
proc createMainWindow { } {
global tcl_platform
	frame .right
	frame .left -width 250
	frame .left.movieoptions -width 250 -height 200
	frame .left.imageoptions -width 250 -height 200
					
	label .left.imtypetext -justify left -text "Image format: " -wraplength 120
	label .left.imtype -justify left -foreground blue -wraplength 130
	label .left.manuftext -justify left -text "Manufacturer: " -wraplength 120
	label .left.manufacturer -justify left -foreground blue -wraplength 120
	bindBubble .left.manuftext "Detector Manufacturer"
	label .left.sntext -justify left -text "Detector S/N: " -wraplength 120
	label .left.detectsn -justify left -foreground blue -wraplength 130
	bindBubble .left.sntext "Serial Number of Detector"
	label .left.datetext -justify left -text "Collection time: " -wraplength 120
	label .left.date -justify left -foreground blue -wraplength 130
	label .left.imagetext -justify left -text "Image size: " -wraplength 120
	label .left.image -foreground blue -justify left -wraplength 130
	label .left.pixeltext -justify left -text "Pixel size: " -wraplength 120
	label .left.pixel -foreground blue -justify left -wraplength 130
	label .left.beamtext -justify left -text "Beam center:   " -wraplength 120
	label .left.beam -foreground blue -justify left -wraplength 130 
	label .left.expostext -justify left -text "Exposure time: " -wraplength 120
	label .left.exposure -justify left -foreground blue -wraplength 130
	label .left.wavetext -justify left -text "Wavelength: " -wraplength 120
	label .left.wavelength -justify left -foreground blue -wraplength 130
	label .left.disttext -justify left -text "Detector distance: " -wraplength 120
	label .left.distance -justify left -foreground blue -wraplength 130
	label .left.twothtext -justify left -text "2 Theta value: " -wraplength 120
	label .left.twotheta -justify left -foreground blue -wraplength 130
	label .left.angletext -justify left -text "scan :" -wraplength 120
	label .left.phistartend -foreground blue -justify left -wraplength 130
	bindBubble .left.angletext "Give the scanning angles and axis used for this image/sector"
	label .left.imgoptzoomtxt -justify left -text "Current zoom: " -wraplength 120
	label .left.imgoptzoom -justify left -foreground blue
	label .left.pixstatus -justify left
		   
#	label .left.imgoptgain -justify right -foreground blue
#	button .left.imageoptions.gain -text "Estimate gain" -padx 10 
#		   -command "gain"
		   
	scale .left.imgoptspotsigma -label "I / sigma" -from 0 -to 10.0 \
		  -orient horizontal -tickinterval 2.5 -showvalue false -resolution 0.25 \
		  -sliderlength 8 -length 240 -command "handleSlider"
		  
	bindBubble .left.imgoptspotsigma "Threshold used for peaks detections in the image"
		  
	scale .left.movieoptions.speed -label "interval between frames (s)" \
 	      -from 0.05 -to 0.5 -orient horizontal -tickinterval 0.1 \
		  -showvalue false -resolution 0.01 -sliderlength 8 -length 240
	scale .left.movieoptions.slidethrough -label "slide through images" \
 	      -from 0 -to 1 -orient horizontal -tickinterval 1 \
		  -showvalue false -resolution 1 -sliderlength 8 -length 240 
	checkbutton .left.movieoptions.rollback -text "Roll back" \
	            -variable PARAMS(MOVIE_ROLL)
	
	place .left.movieoptions.rollback -in .left.movieoptions -relx 0.0 -y 0
	place .left.movieoptions.speed -in .left.movieoptions -relx 0.0 -y 30
	place .left.movieoptions.slidethrough -in .left.movieoptions -relx 0.0 -y 85
	
	frame .toolbar -height 32
	
	set zoomimg1 [image create photo zoomimg1 -format ppm -file "zoombox.ppm"]
	set zoomimg2 [image create photo zoomimg2 -format ppm -file "zoom-in.ppm"]
	set zoomimg3 [image create photo zoomimg3 -format ppm -file "zoom-out.ppm"]
	set drag [image create photo drag -format ppm -file "handdrag.ppm"]
	set spots [image create photo spots -format ppm -file "spots.ppm"]
	set previmg [image create photo previmg -format ppm -file "previous.ppm"]
	set nextimg [image create photo nextimg -format ppm -file "next.ppm"]
	set openimg [image create photo openimg -format ppm -file "open.ppm"]
	set openimg1 [image create photo openimg1 -format ppm -file "openimg.ppm"]
	set openimg2 [image create photo openimg2 -format ppm -file "opsector.ppm"]
	set openimg3 [image create photo openimg3 -format ppm -file "opmovie.ppm"]
	set openimg4 [image create photo openimg4 -format ppm -file "oprecent.ppm"]
	set saveimg [image create photo saveimg -format ppm -file "save.ppm"]
	set saveimg1 [image create photo saveimg1 -format ppm -file "savejpg.ppm"]
	set saveimg2 [image create photo saveimg2 -format ppm -file "savegif.ppm"]
	set playimg [image create photo playimg -format ppm -file "play.ppm"]
	set resolimg [image create photo resolimg -format ppm -file "resolcircles.ppm"]
	set stopimg [image create photo stopimg -format ppm -file "stop.ppm"]
	set profimg [image create photo profimg -format ppm -file "profile.ppm"]
	set confimg [image create photo confimg -format ppm -file "config.ppm"]
	set helpimg [image create photo helpimg -format ppm -file "help.ppm"]
	
	button .toolbar.zoomin -width 32 -height 32 -image $zoomimg2 \
	       -command "zoom 1" -state disabled
	bindBubble .toolbar.zoomin "Zoom in"
	button .toolbar.zoomout -width 32 -height 32 -image $zoomimg3 \
	       -command "zoom -1"  -state disabled
	bindBubble .toolbar.zoomout "Zoom out"
	button .toolbar.zoombox -width 32 -height 32 -image $zoomimg1 \
	        -state disabled -command "switchZoomBox"
	bindBubble .toolbar.zoombox "Zoom on selection"
	button .toolbar.handdrag -width 32 -height 32 -image $drag \
	        -state disabled -command "switchHandDrag"
	bindBubble .toolbar.handdrag "Switch hand dragging on"
	button .toolbar.previous -width 32 -height 32 -image $previmg \
			 -state disabled
	button .toolbar.next -width 32 -height 32 -image $nextimg \
	         -state disabled
	button .toolbar.findspots -width 32 -height 32 -image $spots \
	        -command "switchSpots"  -state disabled
	bindBubble .toolbar.findspots "Find peaks on image"
	button .toolbar.play -width 32 -height 32 -image $playimg \
	        -command "playMovie"  -state disabled
	bindBubble .toolbar.play "Play movie sequence"
	
	button .toolbar.circles -width 32 -height 32 -image $resolimg \
	        -command "switchCircle"  -state disabled
	bindBubble .toolbar.circles "Show/Clear resolution circles"
	button .toolbar.stop -width 32 -height 32 -image $stopimg \
	        -command "stopMovie"  -state disabled
	bindBubble .toolbar.stop "Stop movie sequence"
	
	button .toolbar.profile -width 32 -height 32 -image $profimg \
	        -command "switchProfile"  -state disabled
	bindBubble .toolbar.profile "Two clicks to define a line and then\n \
	                             Display a window with the profile of the line"
	
	button .toolbar.conf -width 32 -height 32 -image $confimg \
	        -command "switchConfig"  -state active
	bindBubble .toolbar.conf "Open configuration window"
	
	button .toolbar.help -width 32 -height 32 -image $helpimg \
	        -command "showHelp"  -state active
	bindBubble .toolbar.help "Open documentation in web browser"
	
	menubutton .toolbar.openfile -image $openimg -menu .toolbar.openfile.mymenu \
	           -relief raised -width 35 -height 35
	bindBubble .toolbar.openfile "Open"
	set menulist [menu .toolbar.openfile.mymenu -tearoff 0]
	$menulist add command -label "open Image..." -command "openImages 1" \
	              -background #ffcc66 -foreground black
	$menulist add command -label "open Sector as image..." -command "openImages 2" \
	              -background #ffcc66 -foreground black
	$menulist add command -label "open Sector as 'Movie'..." -command "openImages 2 -movie" \
	              -background #ffcc66 -foreground black
	$menulist add separator -background #ffcc66
	$menulist add cascade -label "open recent" -menu .toolbar.openfile.mymenu.recent  \
	              -background #ffcc66 -foreground black	
	set menurecent [menu .toolbar.openfile.mymenu.recent -tearoff 0 \
	                     -background #ffcc66 -foreground black]
	readRecents
		
	menubutton .toolbar.savefile -image $saveimg -menu .toolbar.savefile.mymenu \
	           -relief raised -width 35 -height 35
	bindBubble .toolbar.savefile "Save"
	set menulist2 [menu .toolbar.savefile.mymenu -tearoff 0]	 
	$menulist2 add command -image $saveimg1 -command "saveImageasJpeg" \
	                       -state disabled -hidemargin 1
	$menulist2 add command -image $saveimg2 -command "saveMovieasGif" \
	                       -state disabled -hidemargin 1
	bindBubble .toolbar.savefile.mymenu "  1. Save image as Jpeg...\r \
	                                     2. Save Movie sequence as gif..."
	if {$tcl_platform(platform) == "windows" || $tcl_platform(platform) == "Darwin"} {	
		$menulist2 add separator
		}
										 
	canvas .right.diffcanvas -xscrollcommand [list .right.xscroll set] \
					   -yscrollcommand [list .right.yscroll set] \
					   -xscrollincrement 1	\
					   -yscrollincrement 1
	scrollbar .right.xscroll -orient horizontal -command [list .right.diffcanvas xview]
	scrollbar .right.yscroll -orient vertical -command [list .right.diffcanvas yview]
	
	pack .toolbar -side top -anchor nw
	pack .toolbar.openfile -side left -anchor ne
	pack .toolbar.savefile -side left -anchor ne
	pack .toolbar.zoombox -side left -anchor ne
	pack .toolbar.zoomin -side left -anchor ne
	pack .toolbar.zoomout -side left -anchor ne
#pack .toolbar.handdrag -side left -anchor ne
	pack .toolbar.findspots -side left -anchor ne
	pack .toolbar.circles -side left -anchor ne
	pack .toolbar.profile -side left -anchor ne
	pack .toolbar.play -side left -anchor ne
#pack .toolbar.stop -side left -anchor ne
	pack .toolbar.previous -side left -anchor ne
	pack .toolbar.next -side left -anchor ne	
	pack .toolbar.conf -side left -anchor ne
	pack .toolbar.help -side left -anchor ne
	
	pack .left -expand false -fill y -side left -anchor nw
	pack .right -side right -fill both -expand true -anchor ne
	grid .right.diffcanvas .right.yscroll -sticky news
	grid .right.xscroll -sticky ew
	grid rowconfigure .right 0 -weight 1
	grid columnconfigure .right 0 -weight 1
	
	bind .right.diffcanvas <B1-Motion> "handleDrag %x %y"
	bind .right.diffcanvas <ButtonPress-1> "handleB1Down %x %y"
	bind .right.diffcanvas <ButtonRelease-1> "handleB1Up %x %y"
	bind .right.diffcanvas <Motion> "handleMouseMove %x %y"
	bind .right.diffcanvas <MouseWheel> "handleWheel %D"
	bind .right.diffcanvas <Button-4> "handleWheel 1"
	bind .right.diffcanvas <Button-5> "handleWheel -1"
	bind . <KeyPress-plus> "handleWheel 1"
	bind . <KeyPress-minus> "handleWheel -1"
	
	wm deiconify .
	wm protocol . WM_DELETE_WINDOW "myExit"
	
	option add *Balloonhelp*background "#ffcc66" widgetDefault
	option add *Balloonhelp*foreground black widgetDefault
	option add *Balloonhelp.txt.wrapLength 3i widgetDefault
	option add *Balloonhelp.txt.justify left widgetDefault
	
	toplevel .bubble -class Balloonhelp -borderwidth 1 -relief flat -background black
	label .bubble.txt -background "#ffcc66"
	pack .bubble.txt -side left -fill y
	wm overrideredirect .bubble 1
	wm withdraw .bubble
	
	toplevel .profile
	canvas .profile.can -background white
	pack .profile.can -side left -fill both
	wm withdraw .profile
	wm protocol .profile WM_DELETE_WINDOW "wm withdraw .profile"
	
	createColorConfig
}

proc openImages { one args } {
global PARAMS
	if {$one > 1} {
		set thefiles [tk_getOpenFile -parent . -multiple true \
		  -initialdir $PARAMS(LAST_DIR) \
		  -filetypes {{"Diffraction Image files" {.osc .OSC .img .IMG .mar* .MAR* \
												  .mccd .MCCD .cbf .CBF .sfrm .SFRM \
												  .pck .PCK} }}]
	} else {
		set thefiles [tk_getOpenFile -parent . -initialdir $PARAMS(LAST_DIR) \
		  -filetypes {{"Diffraction Image files" {.osc .OSC .img .IMG .mar* .MAR* \
												  .mccd .MCCD .cbf .CBF .sfrm .SFRM \
												  .pck .PCK} }}]
		}

	if {"$args" == "-movie" } {
		if { [llength $thefiles] < 1 } {
			return
			}
		openMovie $thefiles
		addtoRecent "openMovie $thefiles"
	} else {
		if {[llength $thefiles] > 1 } {
			openSector $thefiles
			addtoRecent "openSector $thefiles"
		} elseif { [llength $thefiles] < 1 } {
			return
		} else {
			openImagefile [lindex $thefiles 0]
			addtoRecent "openImagefile [lindex $thefiles 0]"
			}
		}
	set PARAMS(LAST_DIR) [file dirname [lindex $thefiles 0]]
}

proc openImagefile { filename } {

	if { $filename == "" } {
	    return
	}
	showMessage "Opening $filename ..."
	global garbage
	global PARAMS
	.toolbar.savefile.mymenu entryconfigure 0 -state active
	.toolbar.findspots configure -state active
	.toolbar.zoomout configure -state active
	.toolbar.zoomin configure -state active
	.toolbar.circles configure -state active
	.toolbar.play configure -state disabled
	.toolbar.stop configure -state disabled
	.toolbar.zoombox configure -state active
	.toolbar.handdrag configure -state active
	.toolbar.profile configure -state active
	.toolbar.previous configure -state active -command "showPreviousImage"
	.toolbar.next configure -state active -command "showNextImage"
	bindBubble .toolbar.previous "Display previous image in directory"
	bindBubble .toolbar.next "Display next image in directory"
	
	wm title . "idiffdisp: $filename"
	if {$PARAMS(IMAGE) != "nothing"} {
	    $PARAMS(IMAGE) destructor
	}
	set currentimage [new_DiffractionImage $filename]
	set PARAMS(IMAGE) $currentimage
	set myzoom [adjustZoom [$currentimage getWidth]]
	set w [expr [$currentimage getWidth] * $myzoom]
	set h [expr [$currentimage getHeight] * $myzoom]
	.left.imtype configure -text "[$currentimage getFormat]"
	.left.manufacturer configure -text "[$currentimage getManufacturer]"
	.left.detectsn configure -text "[$currentimage getSerialNo]"
	.left.date configure -text "[$currentimage getDate]"
	.left.image configure -text "[$currentimage getWidth] x [$currentimage getHeight] px"
	.left.pixel configure -text "[format %.3f [$currentimage getPixelX]] x \
								 [format %.3f [$currentimage getPixelY]] mm"
	.left.beam configure -text \
	"[format %.2f [$currentimage getBeamX]] x [format %.2f [$currentimage getBeamY]] mm"
	.left.exposure configure -text "[format %.1f [$currentimage getExposureTime]] s"
	.left.wavelength configure -text "[format %.5f [$currentimage getWavelength]] Angstroms"
	.left.distance configure -text "[format %.2f [$currentimage getDistance]] mm"
	.left.twotheta configure -text "[format %.5f [$currentimage getTwoTheta]] deg"
	.left.angletext configure -text "[$currentimage getOscAxis] scan :"
	.left.phistartend configure \
	-text "[format %.2f [$currentimage getOscStart]] -> [format %.2f [$currentimage getOscEnd]] deg"
	set myCimage [$currentimage getImage $myzoom 0 0 [$currentimage getWidth] \
	                                     [$currentimage getHeight]]
	.right.diffcanvas delete all
	set tclimage [image create photo tclimage -format ppm -file $myCimage]
	.right.diffcanvas configure -scrollregion "0 0 $w $h"
#	.left.imageoptions.gain configure -state active
	.left.imgoptspotsigma set 2.0
	.left.imgoptzoom configure -text "[expr $myzoom * 100 ]%"
	if {$PARAMS(FIRSTOPEN) == 0} {
		placeAll
		set PARAMS(FIRSTOPEN) 1
		}
	place forget .left.imgoptspotsigma
	place forget .left.movieoptions
	
	lappend garbage $myCimage
	.right.diffcanvas configure -xscrollincrement 1
	.right.diffcanvas configure -yscrollincrement 1
	if {$PARAMS(LAST_DIR) != [file dirname $filename]} {
		set PARAMS(LAST_DIR) [file dirname $filename]
		}
	calculateResolCircles
	set bx [expr [$currentimage getBeamX] / [$currentimage getPixelX]]
	set by [expr [$currentimage getBeamY] / [$currentimage getPixelY]]
	set PARAMS(SCREEN_BEAM) "[expr round($bx*$myzoom)] [expr round($by*$myzoom)]"
	set PARAMS(SCREEN_CORNER) "0 0"
	clearMessage
	refreshDisplay
}

proc showNextImage {} {
global PARAMS

	set ext [file extension [$PARAMS(IMAGE) getFilename]]
	set imgindir [glob -directory $PARAMS(LAST_DIR) "*$ext"]
	set imgindir [lsort -dictionary $imgindir]
	set index [lsearch -exact $imgindir [$PARAMS(IMAGE) getFilename]]
	openImagefile [lindex $imgindir [expr $index + 1]]
	if {[expr $index + 1] == [expr [llength $imgindir] -1] } {
		.toolbar.next configure -state disabled
		}
	.toolbar.previous configure -state active
	
}

proc showPreviousImage {} {
global PARAMS

	set ext [file extension [$PARAMS(IMAGE) getFilename]]
	set imgindir [glob -directory $PARAMS(LAST_DIR) "*$ext"]
	set imgindir [lsort -dictionary $imgindir]
	set index [lsearch -exact $imgindir [$PARAMS(IMAGE) getFilename]]
	openImagefile [lindex $imgindir [expr $index - 1]]
	if {[expr $index - 1] == 0 } {
		.toolbar.previous configure -state disabled
		}
	.toolbar.next configure -state active
}

proc openSector { filesunsorted } {
	global garbage
	global PARAMS
	
	wm title . "idiffdisp: [llength $filesunsorted] images"
	.toolbar.savefile.mymenu entryconfigure 0 -state active
	.toolbar.findspots configure -state active
	.toolbar.zoomout configure -state active
	.toolbar.zoomin configure -state active
	.toolbar.zoombox configure -state active
	.toolbar.handdrag configure -state active
	.toolbar.circles configure -state active
	.toolbar.play configure -state disabled
	.toolbar.previous configure -state disabled
	.toolbar.next configure -state disabled
	.toolbar.profile configure -state disabled
	
	showMessage "Calculating maximum image"
	set files [lsort -dictionary $filesunsorted]
        if {$PARAMS(IMAGE) != "nothing"} {
	    $PARAMS(IMAGE) destructor
	}
	set currentimage [new_DiffractionImage [lindex $files 0]]
	set floatx [$currentimage getBeamX]
	set floaty [$currentimage getBeamY]
	set PARAMS(IMAGE) $currentimage
	set myzoom [adjustZoom [$currentimage getWidth]]
	set w [expr [$currentimage getWidth] * $myzoom]
	set h [expr [$currentimage getHeight] * $myzoom]
	.left.imtype configure -text "[$currentimage getFormat]"
	.left.manufacturer configure -text "[$currentimage getManufacturer]"
	.left.detectsn configure -text "[$currentimage getSerialNo]"
	.left.date configure -text "[$currentimage getDate]"
	.left.image configure -text "[$currentimage getWidth] x [$currentimage getHeight] px"
	.left.pixel configure -text "[format %.3f [$currentimage getPixelX]] x \
								 [format %.3f [$currentimage getPixelY]] mm"
	.left.beam configure -text \
	"[format %.2f [$currentimage getBeamX]] x [format %.2f [$currentimage getBeamY]] mm"
	.left.exposure configure -text "[format %.1f [$currentimage getExposureTime]] s"
	.left.wavelength configure -text "[format %.5f [$currentimage getWavelength]] Angstroms"
	.left.distance configure -text "[format %.2f [$currentimage getDistance]] mm"
	.left.twotheta configure -text "[format %.5f [$currentimage getTwoTheta]] deg"
	set startosc [$currentimage getOscStart]
	set sector "\""
	set currenttype [$currentimage getFormat]
	for {set n 1} {$n < [llength $files]} {incr n} {
		set otherimg [new_DiffractionImage [lindex $files $n]]
		$currentimage max $otherimg
		if {$currenttype !=[$currentimage getFormat]} {
			showMessage "Selected images are not all of the same detector type!!" 
			return
			}
		set floatx [expr [$otherimg getBeamX] + $floatx]
		set floaty [expr [$otherimg getBeamY] + $floaty]
	        $otherimg destructor
		}
	.left.angletext configure -text "[$currentimage getOscAxis] scan :"
	.left.phistartend configure \
	-text "[format %.2f $startosc] -> [format %.2f [$otherimg getOscEnd]] deg"
	set floatx [expr $floatx / [llength $files] ]
	set floaty [expr $floaty / [llength $files] ]
	set bx [expr $floatx / [$currentimage getPixelX]]
	set by [expr $floaty / [$currentimage getPixelY]]
	set PARAMS(SCREEN_BEAM) "[expr round($bx*$myzoom)] [expr round($by*$myzoom)]"
	set myCimage [$currentimage getImage $myzoom 0 0 [$currentimage getWidth] \
	                                     [$currentimage getHeight]]
	.right.diffcanvas delete all
	set tclimage [image create photo tclimage -format ppm -file $myCimage]
	.right.diffcanvas configure -scrollregion "0 0 $w $h"
	.left.imgoptzoom configure -text "[expr $myzoom * 100 ]%"
#	.left.imageoptions.gain configure -state disabled
	.left.imgoptspotsigma set 2.0
	if {$PARAMS(FIRSTOPEN) == 0} {
		placeAll
		set PARAMS(FIRSTOPEN) 1
		}	
	#N.B the beam centre being displayed for a sector is the average of all
	#beam centre coordinates of the images
	place forget .left.imgoptspotsigma
	place forget .left.movieoptions
	clearMessage
	lappend garbage $myCimage
	if {$PARAMS(LAST_DIR) != [file dirname [lindex $files 0]]} {
		set PARAMS(LAST_DIR) [file dirname [lindex $files 0]]
		}
		
	calculateResolCircles
	set PARAMS(SCREEN_CORNER) "0 0"
	refreshDisplay
}

proc saveImageasJpeg { } {
	global garbage
	global PARAMS
	global tcl_platform
	
	set thefile [tk_getSaveFile -parent . -initialdir $PARAMS(LAST_DIR) \
		  -filetypes {{"jpeg files" ".jpg" }}]
	if { [llength $thefile] == 0 } {
		return 
		}
	set tmpfile [lindex $garbage end]
	if {$PARAMS(CONVERT) != "N/A"} {
		set command " exec \"$PARAMS(CONVERT)\" -colorspace GRAY $tmpfile $thefile"
		set status 0
		eval $command
	} else {
		$PARAMS(IMAGE) jpeg "$thefile"
		}
}



#Calcuate the resolution circles now so they are ready for display
proc calculateResolCircles { } {
global PARAMS

	set PARAMS(RES_CIRC) {}
	#First loop to search what resolution we got at the edge
	set xdist [expr [$PARAMS(IMAGE) getWidth] * [$PARAMS(IMAGE) getPixelX]]
	set ydist [expr [$PARAMS(IMAGE) getHeight] * [$PARAMS(IMAGE) getPixelY]]
	set xdist [expr $xdist - [$PARAMS(IMAGE) getBeamX] ]
	set ydist [expr $ydist - [$PARAMS(IMAGE) getBeamY] ]
	set xdist [expr $xdist * $xdist]
	set ydist [expr $ydist * $ydist]
	set outrad [expr sqrt([expr $xdist + $ydist])]
	set outres [$PARAMS(IMAGE) resolOnRadius $outrad]
	set inres [$PARAMS(IMAGE) resolOnRadius [expr $outrad / 11.0] ]
	set outres [expr round([expr $outres * 10])]
	set outres [expr $outres / 10.0]
	set inres [expr round([expr $inres * 10])]
	set inres [expr $inres / 10.0]
	set inrad [expr $outrad / 11.0]
	set inrad [expr $inrad / [$PARAMS(IMAGE) getPixelX] ]
	
	lappend PARAMS(RES_CIRC) "$inres $inrad"
	set lastrad $inrad
	set step [expr $outrad / 11.0]
	set step [expr $step / [$PARAMS(IMAGE) getPixelX] ]

	for {set n $inres} {$n > [expr 10 * $outres / 11.0]} {set n [expr $n - 0.05]} {
		set rad [expr [$PARAMS(IMAGE) resolRingRadius $n] / [$PARAMS(IMAGE) getPixelX]]
		if {$rad >= [expr $lastrad + $step]} {
			lappend PARAMS(RES_CIRC) "$n $rad"
			set lastrad $rad
			}
		}
}

proc placeAll { } {
	place .left.imtypetext -in .left  -relx 0.0 -y 5
	place .left.imtype -in .left -x 120 -y 5
	place .left.manuftext -in .left  -relx 0.0 -y 30
	place .left.manufacturer -in .left -x 120 -y 30
	place .left.sntext -in .left -relx 0.0 -y 70
	place .left.detectsn -in .left -x 120 -y 70
	place .left.datetext -in .left -relx 0.0 -y 95
	place .left.date -in .left -x 120 -y 95
	place .left.imagetext -in .left -relx 0.0 -y 130
	place .left.image -in .left -x 120 -y 130
	place .left.pixeltext -in .left -relx 0.0 -y 155
	place .left.pixel -in .left -x 120 -y 155
	place .left.beamtext -in .left -relx 0.0 -y 180
	place .left.beam -in .left -x 120 -y 180
	place .left.expostext -in .left -relx 0.0 -y 205
	place .left.exposure -in .left -x 120 -y 205
	place .left.wavetext -in .left -relx 0.0 -y 230
	place .left.wavelength -in .left -x 120 -y 230
	place .left.disttext -in .left -relx 0.0 -y 255
	place .left.distance -in .left -x 120 -y 255
	place .left.twothtext -in .left -relx 0.0 -y 280
	place .left.twotheta -in .left -x 120 -y 280
	place .left.angletext -in .left -relx 0.0 -y 305
	place .left.phistartend -in .left -x 120 -y 305
	place .left.imgoptzoomtxt -in .left -relx 0.0 -y 330
	place .left.imgoptzoom -in .left -x 120 -y 330
	place .left.pixstatus -in .left -relx 0.0 -rely 0.96
}

proc emptyGarbage { } {
	global garbage
	foreach tempfile $garbage {
		file delete $tempfile
		}
}

proc gain { } {
	global PARAMS
	set mygain [$PARAMS(IMAGE) gain]
	.left.imageoptions.gainvalue configure -text "[format %.5f $mygain]"
	set coordlist ""
	lappend coordlist [expr [$PARAMS(IMAGE) gainX] * [lindex $PARAMS(MAGNIFY) $PARAMS(ZOOM)]]
	lappend coordlist [expr [$PARAMS(IMAGE) gainY] * [lindex $PARAMS(MAGNIFY) $PARAMS(ZOOM)]]
	set temp [expr [$PARAMS(IMAGE) gainX] + 20]
	lappend coordlist [expr $temp  * [lindex $PARAMS(MAGNIFY) $PARAMS(ZOOM)]]
	set temp [expr [$PARAMS(IMAGE) gainY] + 20]
	lappend coordlist [expr $temp  * [lindex $PARAMS(MAGNIFY) $PARAMS(ZOOM)]]
	.right.diffcanvas create rectangle $coordlist -outline blue -width 1
}

proc myExit { } {
global PARAMS
        if {$PARAMS(IMAGE) != "nothing"} {
	    $PARAMS(IMAGE) destructor
	}
	emptyGarbage
	saveRecents
	exit
}

##############################################################################
# Procedures for handling zooms
##############################################################################

proc adjustZoom { imgsize } {
global PARAMS
	set maxsize [expr [winfo screenwidth .] - 280]
	if {[expr [winfo screenheight .] - 30] < $maxsize } {
		set maxsize [expr [winfo screenheight .] - 65]
	}
	set zoomind -1
	foreach whichzoom $PARAMS(MAGNIFY) {
		set size [expr $imgsize * $whichzoom]
		if {$size < $maxsize && $whichzoom < 2} {
			set myzoom $whichzoom
			incr zoomind
		}
	}
	if {$zoomind == -1} {
		set zoomind 0
		set myzoom [lindex $PARAMS(MAGNIFY) 0]
	}
	set PARAMS(ZOOM) $zoomind
	set PARAMS(ZOOM_TO) [expr $PARAMS(ZOOM) + 1]
	set w [expr [$PARAMS(IMAGE) getWidth] * $myzoom]
	set h [expr [$PARAMS(IMAGE) getHeight] * $myzoom]
	.right.diffcanvas configure -height $h
	.right.diffcanvas configure -width $w
	if {$zoomind == 0} {
		.toolbar.zoomout configure -state disabled
	}
	return $myzoom
}

proc zoom {direction} {
	global PARAMS
	global garbage
		
	set maxzoom [expr [llength $PARAMS(MAGNIFY)] - 1]
	set oldzoom $PARAMS(ZOOM)
	set currentzoom [expr $PARAMS(ZOOM) + $direction]
	if {$currentzoom == 0} {
		.toolbar.zoomout configure -state disabled
	} else {
		.toolbar.zoomout configure -state active
	}
	if {$currentzoom == $maxzoom} {
		.toolbar.zoomin configure -state disabled
		.toolbar.zoombox configure -state disabled
	} else {
		.toolbar.zoomin configure -state active
		.toolbar.zoombox configure -state active
	}
	set bx [expr [$PARAMS(IMAGE) getBeamX] / [$PARAMS(IMAGE) getPixelX]]
	set by [expr [$PARAMS(IMAGE) getBeamY] / [$PARAMS(IMAGE) getPixelY]]
	if {$oldzoom != $currentzoom} {
		set w [$PARAMS(IMAGE) getWidth]
		set h [$PARAMS(IMAGE) getHeight]
		set w [expr $w * [lindex $PARAMS(MAGNIFY) $currentzoom] ]
		set h [expr $h * [lindex $PARAMS(MAGNIFY) $currentzoom] ]
		set myCimage [$PARAMS(IMAGE) getImage \
		              [lindex $PARAMS(MAGNIFY) $currentzoom] 0 0 \
					  [$PARAMS(IMAGE) getWidth] [$PARAMS(IMAGE) getHeight]]
		.right.diffcanvas delete tclimage
		set tclimage [image create photo tclimage -format ppm -file $myCimage]
		.right.diffcanvas configure -scrollregion "0 0 $w $h"
		.left.imgoptzoom configure \
		-text "[expr [lindex $PARAMS(MAGNIFY) $currentzoom] * 100 ]%"
		lappend garbage $myCimage
		set PARAMS(SCREEN_BEAM) "[expr round($bx*[lindex $PARAMS(MAGNIFY) $currentzoom])]"
		lappend PARAMS(SCREEN_BEAM) "[expr round($by*[lindex $PARAMS(MAGNIFY) $currentzoom])]"
		set PARAMS(SCREEN_CORNER) "0 0"
	}

	set PARAMS(ZOOM) $currentzoom
	set PARAMS(ZOOM_TO) [expr $PARAMS(ZOOM) + 1]
	refreshDisplay
}

proc zoomOnBox { } {
global PARAMS
global garbage

	set zoomto [lindex $PARAMS(MAGNIFY) $PARAMS(ZOOM_TO)] 
	set w [expr [.right.diffcanvas cget -width] / $zoomto]
	set h [expr [.right.diffcanvas cget -height] / $zoomto]
	set w2 [expr $w / 2]
	set h2 [expr $h / 2]
	set x [expr $PARAMS(BOX_X) / [lindex $PARAMS(MAGNIFY) $PARAMS(ZOOM)]]
	set x [expr $x - $w2]
	set y [expr $PARAMS(BOX_Y) / [lindex $PARAMS(MAGNIFY) $PARAMS(ZOOM)]]
	set y [expr $y - $h2]
	set myCimage [$PARAMS(IMAGE) getImage $zoomto [expr round($x)] \
										  [expr round($y)] [expr round($w)] \
										  [expr round($h)]]
	set PARAMS(SCREEN_CORNER) "[expr round($x)] [expr round($y)]"
	lappend garbage $myCimage									  
	if {[.toolbar.play cget -state] == "disabled"} {
		set bx [expr [$PARAMS(IMAGE) getBeamX] / [$PARAMS(IMAGE) getPixelX]]
		set by [expr [$PARAMS(IMAGE) getBeamY] / [$PARAMS(IMAGE) getPixelY]]
		set bx [expr $bx - $x]
		set by [expr $by - $y]
		set bx [expr $bx * $zoomto]
		set by [expr $by * $zoomto]
		set PARAMS(SCREEN_BEAM) "[expr round($bx)] [expr round($by)]"
		set tclimage [image create photo tclimage -format ppm -file $myCimage]
	} else {
		lappend PARAMS(MOVIE_FRAMES) $myCimage
		}
}

proc zoomOnBoxFrames { } {
global PARAMS

	showMessage "Preparing movie frames ..."
	set PARAMS(MOVIE_FRAMES) {}
	emptyGarbage
	foreach img $PARAMS(MOVIE_FILES) {
		set PARAMS(IMAGE) [new_DiffractionImage $img]
		zoomOnBox
		}
	clearMessage
	
	showFrame 0
}

##############################################################################
# Procedures for movies handling
##############################################################################

proc openMovie { filesunsorted } {
	global garbage
	global PARAMS
	
	wm title . "idiffdisp: Movie sequence"
	.toolbar.savefile.mymenu entryconfigure 0 -state disabled
	.toolbar.findspots configure -state disabled
	.toolbar.play configure -state active
	.toolbar.circles configure -state disabled
	.toolbar.zoomin configure -state disabled
	.toolbar.zoomout configure -state disabled
	.toolbar.zoombox configure -state active
	.toolbar.handdrag configure -state disabled
	.toolbar.profile configure -state disabled
	.toolbar.previous configure -state active -command "showPreviousFrame"
	.toolbar.next configure -state active -command "showNextFrame"
	bindBubble .toolbar.previous "Display previous frame"
	bindBubble .toolbar.next "Display next frame"
	.toolbar.zoomout configure -state disabled
	.toolbar.zoomin configure -state disabled
	if {$PARAMS(CONVERT) != "N/A"} {
		.toolbar.savefile.mymenu entryconfigure 1 -state active
	} else {
		.toolbar.savefile.mymenu entryconfigure 1 -state disabled
		}
			
	emptyGarbage
	set PARAMS(MOVIE_FILES) {}
	set PARAMS(MOVIE_FRAMES) {}
        if {$PARAMS(IMAGE) != "nothing"} {
	    $PARAMS(IMAGE) destructor
	    set PARAMS(IMAGE) "nothing"
	}
	set myzoom [lindex $PARAMS(MAGNIFY) 0]
	set currentimage [new_DiffractionImage]
	set files [lsort -dictionary $filesunsorted]
	$currentimage loadHeader [lindex $files 0]
	set imgsize [expr [$currentimage getWidth] * $myzoom]
	set currentzoom 0
	while {$imgsize < 400} {
		incr currentzoom
		set myzoom [lindex $PARAMS(MAGNIFY) $currentzoom]
		set imgsize [expr [$currentimage getWidth] * $myzoom]	
	}
	set imgsize2 [expr [$currentimage getHeight] * $myzoom]
	if {$imgsize2 < 465 && $imgsize < 480} {
		.right.diffcanvas configure -width 480 -height 465 -scrollregion "0 0 480 465"
	} else {
		.right.diffcanvas configure -scrollregion "0 0 480 465"
		}
	set PARAMS(ZOOM) $currentzoom
	.left.imgoptzoom configure \
		-text "[expr [lindex $PARAMS(MAGNIFY) $currentzoom] * 100 ]%"
	set PARAMS(ZOOM_TO) [expr $PARAMS(ZOOM) + 1]
	set currenttype [$currentimage getFormat]
	showMessage "Preparing movie sequence frames"
	set n 1
	foreach img $files {
		$currentimage load $img
		.msg.txt configure -text "Preparing movie sequence frames\r Frame $n of[llength $files]"
		update idletasks
		if {$currenttype !=[$currentimage getFormat]} {
			bgerror "Selected images are not all of the same detector type!!" 
			return
		} else {
		   lappend PARAMS(MOVIE_FILES) $img
		   set myCimage [$currentimage getImage $myzoom 0 0 \
		                              [$currentimage getWidth] \
	                                  [$currentimage getHeight]]
		   lappend PARAMS(MOVIE_FRAMES) $myCimage
		   lappend garbage $myCimage
		}
		set currenttype [$currentimage getFormat]
		incr n
	}
        $currentimage destructor
	if {$PARAMS(FIRSTOPEN) == 0} {
		placeAll
		set PARAMS(FIRSTOPEN) 1
		}
	.left.movieoptions.slidethrough configure -to [expr [llength $files] - 1] \
	                                -tickinterval [expr [llength $files] / 5] \
				-command "showFrame"
	place forget .left.imgoptspotsigma
	place forget .left.movieoptions
	place .left.movieoptions -in .left -relx 0.0 -y 360	
	clearMessage
	set PARAMS(SCREEN_CORNER) "0 0"
	showFrame 0
	if {$PARAMS(LAST_DIR) != [file dirname [lindex $files 0]]} {
		set PARAMS(LAST_DIR) [file dirname [lindex $files 0]]
		}
}

proc saveMovieasGif { } {
	global garbage
	global PARAMS
	global tcl_platform
	
	set thefile [tk_getSaveFile -parent . -initialdir $PARAMS(LAST_DIR) \
		  -filetypes {{"gif files" ".gif" }}]
	if { [llength $thefile] == 0 } {
		return 
		}
	set delay [expr [.left.movieoptions.speed get] * 100]
	set delay2 [expr round($delay)]
	set command "exec \"$PARAMS(CONVERT)\" -colorspace GRAY -delay $delay2 -write $thefile -combine "
	foreach oneimg $PARAMS(MOVIE_FRAMES) {
		append command "$oneimg "
		}
	if {$PARAMS(MOVIE_ROLL)} {
		for {set index [expr [llength $PARAMS(MOVIE_FILES)] - 1]} {$index < 0 } {incr index -1} {
			append command "[lindex $PARAMS(MOVIE_FRAMES) $index] "
			}
		}
	showMessage "Saving gif movie $thefile"
	eval "$command"
	clearMessage
}

proc showFrame {index} {
global PARAMS
   	set currentimage [new_DiffractionImage]
   	set myzoom [lindex $PARAMS(MAGNIFY) $PARAMS(ZOOM)]
	set img [lindex $PARAMS(MOVIE_FILES) $index]
   	$currentimage loadHeader $img
        if {$PARAMS(IMAGE) != "nothing"} {
	    $PARAMS(IMAGE) destructor
	}
	set PARAMS(IMAGE) $currentimage

	.left.imtype configure -text "[$currentimage getFormat]"
	.left.manufacturer configure -text "[$currentimage getManufacturer]"
	.left.detectsn configure -text "[$currentimage getSerialNo]"
	.left.date configure -text "[$currentimage getDate]"
	.left.image configure -text "[$currentimage getWidth] x [$currentimage getHeight] px"
	.left.pixel configure -text "[format %.3f [$currentimage getPixelX]] x \
								 [format %.3f [$currentimage getPixelY]] mm"
	.left.beam configure -text \
	"[format %.2f [$currentimage getBeamX]] x [format %.2f [$currentimage getBeamY]] mm"
	.left.exposure configure -text "[format %.1f [$currentimage getExposureTime]] s"
	.left.wavelength configure -text "[format %.5f [$currentimage getWavelength]] Angstroms"
	.left.distance configure -text "[format %.2f [$currentimage getDistance]] mm"
	.left.twotheta configure -text "[format %.5f [$currentimage getTwoTheta]] deg"
	.left.angletext configure -text "[$currentimage getOscAxis] scan :"
	.left.phistartend configure \
	-text "[format %.2f [$currentimage getOscStart]] -> [format %.2f [$currentimage getOscEnd]] deg"
	if {[expr [$currentimage getWidth] * $myzoom] > 480} {
		set w [expr [$currentimage getWidth] * $myzoom]
		set h [expr [$currentimage getHeight] * $myzoom]
		.right.diffcanvas configure -height $h -width $w 
	} else {
		set w [.right.diffcanvas cget -width]
		set h [.right.diffcanvas cget -height]
		}
	.right.diffcanvas delete all
	.right.diffcanvas configure -scrollregion "0 0 $w $h"
	if {[lindex $PARAMS(SCREEN_CORNER) 0] != 0 || [lindex $PARAMS(SCREEN_CORNER) 1] != 0} {
		set posX [.right.diffcanvas cget -width] 
		set posY [.right.diffcanvas cget -height]
	} else {
		set posX [expr [$currentimage getWidth] * $myzoom] 
		set posY [expr [$currentimage getHeight] * $myzoom]
		}
	set posX [expr $posX/2]
	set posY [expr $posY/2]
	set tclimage [image create photo tclimage -format ppm -file [lindex $PARAMS(MOVIE_FRAMES) $index]]
	.right.diffcanvas create image $posX $posY -image tclimage
}

proc showNextFrame {} {
	set index [.left.movieoptions.slidethrough get]
	.left.movieoptions.slidethrough set [expr $index + 1]
}

proc showPreviousFrame {} {
	set index [.left.movieoptions.slidethrough get]
	.left.movieoptions.slidethrough set [expr $index - 1]
}

proc playMovie { } {
global PARAMS
   .toolbar.play configure -relief sunken -state disabled
   set myzoom [lindex $PARAMS(MAGNIFY) $PARAMS(ZOOM)]
   set done 0
   for {set index 0} {$index < [llength $PARAMS(MOVIE_FILES)]} {incr index} {
    if {$done == 1} {
		set myindex [expr [expr [llength $PARAMS(MOVIE_FILES)] - 1] - $index]
	} else {
		set myindex $index
		}
	showFrame $myindex
	update idle
	set delay [expr [.left.movieoptions.speed get] * 1000]
	after [expr round($delay)]
	if {$PARAMS(MOVIE_ROLL) && $done != 1 &&
	    [expr $index + 1] == [llength $PARAMS(MOVIE_FILES)]} {
		set index -1
		set done 1
		}
   	}
	.toolbar.play configure -relief raised -state active
}

##############################################################################
# Procedures to handle drawing and display
##############################################################################

proc refreshDisplay { args } {
global PARAMS
		
	if {[.toolbar.play cget -state] == "disabled" && [lsearch [array names PARAMS] "IMAGE"] != -1} {
		set scrollreg [.right.diffcanvas cget -scrollregion]
		set w [lindex $scrollreg 2]
		set h [lindex $scrollreg 3]
		.right.diffcanvas delete all
		.right.diffcanvas create image [expr $w / 2] [expr $h / 2] -image tclimage
		if { [.toolbar.findspots cget -relief] == "sunken"} {
			drawSpots
			}
		if { [.toolbar.circles cget -relief] == "sunken"} {
			drawResolCircles
			}
		if { [.toolbar.zoombox cget -relief] == "sunken"} {
			drawZoomBox
			}
		if { [.toolbar.profile cget -relief] == "sunken" } {
			drawLine
			}
		drawBeamCenter
	} elseif {[.toolbar.play cget -state] == "active"} {
		set scrollreg [.right.diffcanvas cget -scrollregion]
		set w [lindex $scrollreg 2]
		set h [lindex $scrollreg 3]
		.right.diffcanvas delete all
		showFrame [.left.movieoptions.slidethrough get]
		if { [.toolbar.zoombox cget -relief] == "sunken"} {
			drawZoomBox
			}
		}
}

proc drawZoomBox { } {
	global PARAMS
	
	set zoomto "[expr [lindex $PARAMS(MAGNIFY) $PARAMS(ZOOM_TO)] * 100 ]%"
	set newzoom [lindex $PARAMS(MAGNIFY) $PARAMS(ZOOM_TO)]
	set oldzoom [lindex $PARAMS(MAGNIFY) $PARAMS(ZOOM)]
	set relzoom [expr $oldzoom*1.0 / $newzoom*1.0]
	set x $PARAMS(BOX_X)
	set y $PARAMS(BOX_Y)
	set w [expr [.right.diffcanvas cget -width] * $relzoom]
	set h [expr [.right.diffcanvas cget -height] * $relzoom]
	set w [expr $w/2]
	set h [expr $h/2]
	.right.diffcanvas create rectangle "[expr $x - $w] [expr $y - $h] \
	                                    [expr $x + $w] [expr $y + $h]" \
										-outline $PARAMS(ZOOMBOXC) -width 1
	.right.diffcanvas create text "[expr $x] [expr $y + $w + 5]" \
										-fill $PARAMS(ZOOMBOXC) -justify center \
										-text "$zoomto" -font bold
	}

proc drawBeamCenter { } {
	global PARAMS
	
	set x2 [lindex $PARAMS(SCREEN_BEAM) 0]
	set y2 [lindex $PARAMS(SCREEN_BEAM) 1]
	if {[$PARAMS(IMAGE) getManufacturer] == "ADSC" && [$PARAMS(IMAGE) getFormat] == "SMV"} {
		set y2 [expr $y2 + [lindex $PARAMS(SCREEN_CORNER) 1]]
		set y [expr [$PARAMS(IMAGE) getHeight] * [lindex $PARAMS(MAGNIFY) $PARAMS(ZOOM)]]
		set y2 [expr $y - $y2]
		set y2 [expr $y2 - [lindex $PARAMS(SCREEN_CORNER) 1]]
		}
	
	.right.diffcanvas create line "[expr $x2 - 5] [expr $y2 - 5] [expr $x2 + 5] \
	                               [expr $y2 + 5]" -fill $PARAMS(BEAM_COL) -width 2
	.right.diffcanvas create line "[expr $x2 + 5] [expr $y2 - 5] [expr $x2 - 5] \
	                               [expr $y2 + 5]" -fill $PARAMS(BEAM_COL) -width 2
}

proc drawLine { } {
	global PARAMS
	
	if {[llength $PARAMS(PROFILE)] == 2} {
	set coordlist "[expr [lindex $PARAMS(PROFILE) 0] - 1] \
	               [expr [lindex $PARAMS(PROFILE) 1] - 1] \
				   [expr [lindex $PARAMS(PROFILE) 0] + 1] \
	               [expr [lindex $PARAMS(PROFILE) 1] + 1]"
	.right.diffcanvas create rectangle $coordlist -outline $PARAMS(PROFLINE) \
								     -width 2 
	.right.diffcanvas create line "[lindex $PARAMS(PROFILE) 0] \
								   [lindex $PARAMS(PROFILE) 1] \
	                               [lindex $PARAMS(MOUSE) 0] \
								   [lindex $PARAMS(MOUSE) 1]" -fill $PARAMS(PROFLINE)
	set coordlist "[expr [lindex $PARAMS(MOUSE) 0] - 1] \
	               [expr [lindex $PARAMS(MOUSE) 1] - 1] \
				   [expr [lindex $PARAMS(MOUSE) 0] + 1] \
	               [expr [lindex $PARAMS(MOUSE) 1] + 1]"
	.right.diffcanvas create rectangle $coordlist -outline $PARAMS(PROFLINE) \
								     -width 2 
	} elseif {[llength $PARAMS(PROFILE)] == 4}  {
	set coordlist "[expr [lindex $PARAMS(PROFILE) 0] - 1] \
	               [expr [lindex $PARAMS(PROFILE) 1] - 1] \
				   [expr [lindex $PARAMS(PROFILE) 0] + 1] \
	               [expr [lindex $PARAMS(PROFILE) 1] + 1]"
	.right.diffcanvas create rectangle $coordlist -outline $PARAMS(PROFLINE) \
								     -width 2 
	.right.diffcanvas create line "[lindex $PARAMS(PROFILE) 0] \
								   [lindex $PARAMS(PROFILE) 1] \
	                               [lindex $PARAMS(PROFILE) 2] \
								   [lindex $PARAMS(PROFILE) 3]" -fill $PARAMS(PROFLINE)
	set coordlist "[expr [lindex $PARAMS(PROFILE) 2] - 1] \
	               [expr [lindex $PARAMS(PROFILE) 3] - 1] \
				   [expr [lindex $PARAMS(PROFILE) 2] + 1] \
	               [expr [lindex $PARAMS(PROFILE) 3] + 1]"
	.right.diffcanvas create rectangle $coordlist -outline $PARAMS(PROFLINE) \
								     -width 2 
	}
}

proc drawResolCircles { } {
global PARAMS
	
	set myzoom [lindex $PARAMS(MAGNIFY) $PARAMS(ZOOM)]
	set x2 [lindex $PARAMS(SCREEN_BEAM) 0]
	set y2 [lindex $PARAMS(SCREEN_BEAM) 1]
	if {[$PARAMS(IMAGE) getManufacturer] == "ADSC" && [$PARAMS(IMAGE) getFormat] == "SMV"} {
		set y2 [expr $y2 + [lindex $PARAMS(SCREEN_CORNER) 1]]
		set y [expr [$PARAMS(IMAGE) getHeight] * [lindex $PARAMS(MAGNIFY) $PARAMS(ZOOM)]]
		set y2 [expr $y - $y2]
		set y2 [expr $y2 - [lindex $PARAMS(SCREEN_CORNER) 1]]
		}
	set sq2div2 [expr sqrt(2.0) / 2.0]
	foreach circle $PARAMS(RES_CIRC) {
		set resol [lindex $circle 0]
		set rad [lindex $circle 1]
		set rad [expr round($rad) * $myzoom]
		set corner [expr $rad * $sq2div2]
		.right.diffcanvas create oval "[expr $x2 - $rad] [expr $y2 - $rad] [expr $x2 + $rad] \
									   [expr $y2 + $rad]" -outline $PARAMS(CIRCLE) -width 1
		.right.diffcanvas create text "[expr $x2 + $corner] [expr $y2 + $corner]" \
										-fill $PARAMS(CIRCVAL) -justify center \
										-text "$resol A" -font bold
		}
}

proc drawSpots { } {
	global PARAMS
	if {[$PARAMS(IMG_PEAKS) length] == 0 || $PARAMS(IMG_PEAKS_IMG) != $PARAMS(IMAGE)} {
		showMessage "Doing initial peak search"
		set PARAMS(IMG_PEAKS) [new_PeakList]
		$PARAMS(IMG_PEAKS) find $PARAMS(IMAGE) 100000 0.1
		clearMessage
		set PARAMS(IMG_PEAKS_IMG) $PARAMS(IMAGE)
		}
	set can .right.diffcanvas
	set myzoom [lindex $PARAMS(MAGNIFY) $PARAMS(ZOOM)]
	set threshold [.left.imgoptspotsigma get]
	set n 0
	set onepeak [$PARAMS(IMG_PEAKS) get $n]
	while {[$onepeak cget -intensity] >= $threshold && $n < [$PARAMS(IMG_PEAKS) length]} {
		set onepeak [$PARAMS(IMG_PEAKS) get $n]
		incr n
		set x [$onepeak cget -x]
		set y [$onepeak cget -y]
		set x [expr $x / [$PARAMS(IMAGE) getPixelX] ] 
		set x [expr round($x*$myzoom) ]
		set x [expr $x + [lindex $PARAMS(SCREEN_BEAM) 0] ]
		set y [expr $y / [$PARAMS(IMAGE) getPixelY] ] 
		set y [expr round($y*$myzoom)]
		set y [expr $y + [lindex $PARAMS(SCREEN_BEAM) 1]]
		
		$can create line "[expr $x - 5] $y [expr $x + 5] $y" \
						 -fill $PARAMS(SPOTS) -width 1
		$can create line "$x [expr $y - 5] $x [expr $y + 5]" \
						 -fill $PARAMS(SPOTS) -width 1
		}
}

proc showProfile { } {
global PARAMS

	set myzoom [lindex $PARAMS(MAGNIFY) $PARAMS(ZOOM)]
	set fromx [expr [lindex $PARAMS(PROFILE) 0] / $myzoom ]
	set fromx [expr round($fromx) + [lindex $PARAMS(SCREEN_CORNER) 0]]
	set fromy [expr [lindex $PARAMS(PROFILE) 1] / $myzoom ]
	set fromy [expr round($fromy) + [lindex $PARAMS(SCREEN_CORNER) 1]]
	set tox [expr [lindex $PARAMS(PROFILE) 2] / $myzoom ]
	set tox [expr round($tox) + [lindex $PARAMS(SCREEN_CORNER) 0]]
	set toy [expr [lindex $PARAMS(PROFILE) 3] / $myzoom ]
	set toy [expr round($toy) + [lindex $PARAMS(SCREEN_CORNER) 1]]
	set prof [new_Profile $PARAMS(IMAGE) $fromx $fromy $tox $toy]
	set coords {}	
	set intense [$prof getIntensities]
	set scaly [expr [$prof getMax] / 200.0]
	set scalx 1
	while {[expr [$prof getLength] * $scalx] < 300} {
		incr scalx
		}
	.profile.can configure -height 225 -width [expr [$prof getLength] * $scalx]
	set x [expr [winfo rootx .right.diffcanvas] + 10]
	set y [expr [winfo rooty .right.diffcanvas] + 10]
	for {set n 0} {$n < [$prof getLength]} {incr n} {
		set height [expr [atPos $n $intense] / $scaly]
		set height [expr round(200 - $height)]
		lappend coords [expr $n * $scalx]
		lappend coords [expr $height + 25]
		}
	.profile.can create line $coords -fill black 
	for {set n 0} {$n < [expr [$prof getNPeaks] - 1]} {incr n} {
		set pn [$prof get $n]
		set pnplus1 [$prof get [expr $n + 1]]
		set height [$pn cget -intensity]
		if {[$pnplus1 cget -intensity] < $height} {
			set height [$pnplus1 cget -intensity]
		}
		set height [expr $height / $scaly]
		set height [expr round(225 - $height)]
		set x1 [expr [$pn cget -indInt] * $scalx]
		set x2 [expr [$pnplus1 cget -indInt] * $scalx]
		.profile.can create line "$x1 $height $x2 $height" -fill blue -arrow both
		set x3 [expr $x2 - $x1]
		set x3 [expr $x3 / 2]
		set x3 [expr $x1 + $x3]
		.profile.can create text "$x3 [expr $height -5]" -anchor c -fill blue \
		                   -text "[$pnplus1 cget -distFromPrevious] A"
		}
	wm geometry .profile +$x+$y
	wm deiconify .profile
	raise .profile
	
	
}

##############################################################################
# Procedures to handle toolbar buttons response
##############################################################################

proc switchCircle { } {
	if { [.toolbar.circles cget -relief] == "raised" } {
		.toolbar.circles configure -relief sunken
	} else {
		.toolbar.circles configure -relief raised
		}
	refreshDisplay
}

proc switchProfile { } {
global PARAMS
	if { [.toolbar.profile cget -relief] == "raised" } {
		.toolbar.profile configure -relief sunken
	} else {
		.toolbar.profile configure -relief raised
		set PARAMS(PROFILE) {}
		.profile.can delete all
		}
	refreshDisplay
}

proc switchConfig { } {
	if { [.toolbar.conf cget -relief] == "raised" } {
		.toolbar.conf configure -relief sunken
		wm deiconify .colour
		raise .colour
	} else {
		.toolbar.conf configure -relief raised
		wm withdraw .colour
		loadColorConfig
		}
	refreshDisplay
}
	
proc switchSpots { } {

	if { [.toolbar.findspots cget -relief] == "raised" } {
		.toolbar.findspots configure -relief sunken
		place .left.imgoptspotsigma -in .left -relx 0.0 -y 360
	} else {
		.toolbar.findspots configure -relief raised
		place forget .left.imgoptspotsigma
		}
	refreshDisplay
}

proc switchZoomBox { } {
global PARAMS

	if { [.toolbar.zoombox cget -relief] == "raised" } {
		.toolbar.zoombox configure -relief sunken
		.toolbar.handdrag configure -relief raised
		set PARAMS(BOX_X) [expr round([.right.diffcanvas canvasx 0])]
		set PARAMS(BOX_Y) [expr round([.right.diffcanvas canvasy 0])]
	} else {
		.toolbar.zoombox configure -relief raised
		}
	refreshDisplay
}

proc switchHandDrag { } {

	if { [.toolbar.handdrag cget -relief] == "raised" } {
		.toolbar.handdrag configure -relief sunken
		.toolbar.zoombox configure -relief raised
	} else {
		.toolbar.handdrag configure -relief raised
		}
	refreshDisplay
}

proc showHelp { } {
global env
global tcl_platform
	set top $env(CCP4I_TOP)
	set help [file join $top help general "idiffdisp.html"]
	if { [info exists env(CCP4_BROWSER)] } {
		exec $env(CCP4_BROWSER) $help
	} elseif { $tcl_platform(os) == "Darwin" } {
		exec open $help
	} elseif { [regexp -nocase windows $tcl_platform(os)] } {
		eval exec [auto_execok start] [list $help] &
	} else {
		exec firefox $help
	}
}

proc handleSlider { args } {
global PARAMS

	if {[.left.imgoptspotsigma get] != $PARAMS(LAST_ISGMA)} {
		refreshDisplay
		set PARAMS(LAST_ISGMA) [.left.imgoptspotsigma get]
		}
}

proc handleDrag {xcoord ycoord} {
	if {[.toolbar.handdrag cget -relief] == "sunken"} {
		set realx [.right.diffcanvas canvasx $xcoord]
		set realx [expr round($realx)]
		set realy [.right.diffcanvas canvasy $ycoord]
		set realy [expr round($realy)]
		.right.diffcanvas scan dragto $realx $realy 1
		.right.diffcanvas scan mark $realx $realy
		update idletasks
		}
}

##############################################################################
# Procedures to handle mouse bindings
##############################################################################

proc handleB1Down {xcoord ycoord} {
global PARAMS

	set maxzoom [expr [llength $PARAMS(MAGNIFY)] - 1]
	if {[.toolbar.zoombox cget -relief] == "sunken"} {
		if {[.toolbar.play cget -state] == "disabled"} {
			zoomOnBox
			.right.diffcanvas configure -scrollregion "0 0 [.right.diffcanvas cget -width] \                                   [.right.diffcanvas cget -height]"
			.left.imgoptzoom configure \
				-text "[expr [lindex $PARAMS(MAGNIFY) $PARAMS(ZOOM_TO)] * 100 ]%"
			set PARAMS(ZOOM) $PARAMS(ZOOM_TO)
			if {$PARAMS(ZOOM_TO) == $maxzoom} {
				.toolbar.zoomin configure -state disabled
				.toolbar.zoombox configure -state disabled
			} else {
				.toolbar.zoomin configure -state active
				.toolbar.zoombox configure -state active
				incr PARAMS(ZOOM_TO)
				}
			.toolbar.zoomout configure -state active
			.toolbar.zoombox configure -relief raised
		} else {
			zoomOnBoxFrames
			.toolbar.zoombox configure -relief raised
			}
		refreshDisplay
	} elseif {[.toolbar.handdrag cget -relief] == "sunken"} {
		set realx [.right.diffcanvas canvasx $xcoord]
		set realx [expr round($realx)]
		set realy [.right.diffcanvas canvasy $ycoord]
		set realy [expr round($realy)]
		.right.diffcanvas scan mark $realx $realy
	} elseif { [.toolbar.profile cget -relief] == "sunken" } {
		if {[llength $PARAMS(PROFILE)] < 4} {
			lappend PARAMS(PROFILE) [.right.diffcanvas canvasx $xcoord]
			lappend PARAMS(PROFILE) [.right.diffcanvas canvasy $ycoord]
			refreshDisplay
			if {[llength $PARAMS(PROFILE)] == 4} {
				showProfile
				}
			}
		}
	update idletasks
}

proc handleB1Up {xcoord ycoord} {
	set realx [.right.diffcanvas canvasx $xcoord]
	set realx [expr round($realx)]
	set realy [.right.diffcanvas canvasy $ycoord]
	set realy [expr round($realy)]
	.right.diffcanvas scan mark $realx $realy
}

proc handleWheel { dir } {
global PARAMS
	if {[.toolbar.zoombox cget -relief] == "sunken"} {	
		if {$dir > 0} {
			set add 1
		} else {
			set add -1
		}
		incr PARAMS(ZOOM_TO) $add
		if {$PARAMS(ZOOM_TO) > [expr [llength $PARAMS(MAGNIFY)] - 1]} {
			set PARAMS(ZOOM_TO) [expr [llength $PARAMS(MAGNIFY)] - 1]
		} elseif {$PARAMS(ZOOM_TO) <= $PARAMS(ZOOM)} {
			set PARAMS(ZOOM_TO) [expr $PARAMS(ZOOM) + 1]
			}
		refreshDisplay
	}
}

proc handleMouseMove {xcoord ycoord} {
global PARAMS

	if {[.toolbar.zoombox cget -relief] == "sunken"} {
		set realx [.right.diffcanvas canvasx $xcoord]
		set PARAMS(BOX_X) [expr round($realx)]
		set realy [.right.diffcanvas canvasy $ycoord]
		set PARAMS(BOX_Y) [expr round($realy)]
		refreshDisplay
	} elseif {[.toolbar.profile cget -relief] == "sunken"} {
		set PARAMS(MOUSE) "[.right.diffcanvas canvasx $xcoord] \
		                   [.right.diffcanvas canvasy $ycoord]"
		refreshDisplay
	}
	if {$PARAMS(FIRSTOPEN)} {
		set myx [expr [.right.diffcanvas canvasx $xcoord] / [lindex $PARAMS(MAGNIFY) $PARAMS(ZOOM)]]
		set myy [expr [.right.diffcanvas canvasy $ycoord] / [lindex $PARAMS(MAGNIFY) $PARAMS(ZOOM)]]
		set myx [expr [lindex $PARAMS(SCREEN_CORNER) 0] + $myx]
		set myy [expr [lindex $PARAMS(SCREEN_CORNER) 1] + $myy]
		set xdist [expr $myx * [$PARAMS(IMAGE) getPixelX]]
		set ydist [expr $myy * [$PARAMS(IMAGE) getPixelY]]
		set xdist [expr $xdist - [$PARAMS(IMAGE) getBeamX] ]
		if {[$PARAMS(IMAGE) getManufacturer] == "ADSC" && [$PARAMS(IMAGE) getFormat] == "SMV"} {
			set ybeam [expr [$PARAMS(IMAGE) getHeight] * [$PARAMS(IMAGE) getPixelY]]
			set ybeam [expr $ybeam - [$PARAMS(IMAGE) getBeamY]]
			set ydist [expr $ydist - $ybeam ]
		} else {
			set ydist [expr $ydist - [$PARAMS(IMAGE) getBeamY] ]
		}
		if {$myx < [$PARAMS(IMAGE) getWidth] && $myx < [$PARAMS(IMAGE) getHeight]} {
			set xdist [expr $xdist * $xdist]
			set ydist [expr $ydist * $ydist]
			set dist [expr sqrt([expr $xdist + $ydist])]
			set res [format %.5f [$PARAMS(IMAGE) resolOnRadius $dist]]
			set myx [expr round($myx)]
			set myy [expr round($myy)]
			.left.pixstatus configure -text "($myx,$myy) -> $res Angstroms"
		}
	}
}

##############################################################################
# Procedures to handle bubble help and messages display       
##############################################################################

proc showMessage {textmsg} {
	# to prevent conflicts, destroy previously created .msg (if any)
	destroy .msg
	toplevel .msg -width 250 -height 70
	label .msg.txt -text "$textmsg ..."
	pack .msg.txt
	wm resizable .msg 0 0
	wm protocol .msg WM_DELETE_WINDOW ""
	raise .msg
	update idletasks
}

proc clearMessage {} {
	destroy .msg
}

proc bindBubble {widget msg} {
global BUBBLEMSG

	set BUBBLEMSG($widget) $msg
	bind $widget <Enter> "waitBubble %W"
	bind $widget <Leave> "hideBubble"
}

proc showBubble {widget} {
global BUBBLEMSG

	.bubble.txt configure -text $BUBBLEMSG($widget)
	set x [expr [winfo rootx $widget] + 10]
	set y [expr [winfo rooty $widget] + [winfo height $widget] ]
	wm geometry .bubble +$x+$y
	wm deiconify .bubble
	raise .bubble
	unset BUBBLEMSG(waiting)
}

proc hideBubble {} {
global BUBBLEMSG

	if {[info exists BUBBLEMSG(waiting)]} {
		after cancel $BUBBLEMSG(waiting)
		unset BUBBLEMSG(waiting)
		}
	wm withdraw .bubble
}

proc waitBubble {widget} {
global BUBBLEMSG

	hideBubble
	set BUBBLEMSG(waiting) [after 1000 "showBubble $widget"]
}

##############################################################################
# Procedures to handle the recent menu stuff       
##############################################################################

proc addtoRecent {args} {
global PARAMS

	if {[lsearch $PARAMS(RECENT) [lindex $args 0] ] != -1} {
		return
		}
	if {[llength $PARAMS(RECENT)] == 15} {
		set PARAMS(RECENT) [lrange $PARAMS(RECENT) 0 13]
		.toolbar.openfile.mymenu.recent delete 0 end
		foreach argstoo $PARAMS(RECENT) {
			addoneRecent $argstoo
			}
		}
	addOneRecent [lindex $args 0]
}

proc addOneRecent {args} {
global PARAMS

	set myargs [lindex $args 0]
	set command [lindex $myargs 0]
	set commargs [lrange $myargs 1 end]
	lappend PARAMS(RECENT) "$myargs"
	if {[lindex $command 0] == "openImagefile"} {
		set lab $commargs
	} elseif {[lindex $command 0] == "openMovie"} {
		set length [expr [llength $myargs] - 1]
		set lab "Movie ($length frames) from "
		append lab [file dirname [lindex $myargs 1]]
	} else {
		set length [expr [llength $myargs] - 1]
		set lab "Sector ($length images) from "
		append lab [file dirname [lindex $myargs 1]]
		}
	.toolbar.openfile.mymenu.recent add command -label "$lab" \
	-command "$command \"$commargs\""
}

proc saveRecents {} {
global PARAMS
global tcl_platform
global env
	
	if {$tcl_platform(platform) == "windows"} {
		set recfile [file join $env(USERPROFILE) CCP4 idiffdisp.rec]
	} else {
		set recfile [file join $env(HOME) .CCP4 idiffdisp.rec]
		}

    # check that the directory exists, and if it does not make it!
    # bug # 3636
    
    if {$tcl_platform(platform) == "windows"} {
	set ccp4 [file join $env(USERPROFILE) CCP4]
    } else {
	set ccp4 [file join $env(HOME) .CCP4]
    }

    if { ! [file exists "$ccp4"] } {
	file mkdir "$ccp4"
    }

	set f [open "$recfile" "w"]
	foreach onecmd $PARAMS(RECENT) {
		puts $f $onecmd
		}
	close $f

}

proc readRecents {} {
global PARAMS
global tcl_platform
global env
	
	if {$tcl_platform(platform) == "windows"} {
		set recfile [file join $env(USERPROFILE) CCP4 idiffdisp.rec]
	} else {
		set recfile [file join $env(HOME) .CCP4 idiffdisp.rec]
		}
	if {[file exists $recfile] } {
		set f [open "$recfile" "r"]
		while { [eof $f] != 1} {
			# Go through the file and load each line
			set x [gets $f]
			if {$x != ""} {
				addtoRecent "$x"
				}
			}
		close $f
		}
}

##############################################################################
# Procedures to handle configuration stuff
##############################################################################

proc createColorConfig {} {
global PARAMS
	
	loadColorConfig
	toplevel .colour -width 300 -height 300
	wm minsize .colour 300 300
	frame .colour.spots
	addColorMenu .colour.spots SPOTS "Colour for spots: "
	frame .colour.beam
	addColorMenu .colour.beam BEAM_COL "Colour for beam centre: "
	frame .colour.rescircle
	addColorMenu .colour.rescircle CIRCLE "Colour for resolution circles: "
	frame .colour.resvalue
	addColorMenu .colour.resvalue CIRCVAL "Colour for resolution values: "
	frame .colour.profline
	addColorMenu .colour.profline PROFLINE "Colour for profiling line: "
	frame .colour.zoombox
	addColorMenu .colour.zoombox ZOOMBOXC "Colour for zoom box: "
	grid .colour.spots -sticky ne -ipady 10
	grid .colour.beam -sticky ne -ipady 10
	grid .colour.rescircle -sticky ne -ipady 10
	grid .colour.resvalue -sticky ne -ipady 10
	grid .colour.profline -sticky ne -ipady 10
	grid .colour.zoombox -sticky ne -ipady 10
	frame .colour.buttons
	button .colour.buttons.save -text "Save Settings" -command "saveColorConfig"
	button .colour.buttons.cancel -text "Close" -command "switchConfig"
	grid .colour.buttons.save .colour.buttons.cancel -sticky ew
	grid .colour.buttons -sticky new -ipady 10
	wm protocol .colour WM_DELETE_WINDOW "switchConfig"
	wm withdraw .colour
}


proc addColorMenu { path name labl } {
global PARAMS
  set color $PARAMS($name)
  if {$color!=""} {
    set infotext "Colour: $color"
  }
  
  label $path.lbl -text $labl
  menubutton $path.colorButton -text "$infotext" -foreground $color \
  			-relief raised -padx 7 -pady 2 -borderwidth 1 -width 15 \
			-anchor center -menu $path.colorButton.m
  grid $path.lbl $path.colorButton -sticky e
  set colours [list red green blue yellow orange darkred darkgreen \
                    darkblue gray black white]
  set me [menu $path.colorButton.m -tearoff 0]
  foreach colour $colours {
  $me add command \
         -command "applyColour $colour $path $name" \
         -background "$colour" \
         -activebackground "$colour" 
  }
  $me add command \
        -label "Other Color"  \
        -command "applyColour tk_choose $path $name"
}

proc applyColour { col widg name } {
global PARAMS

	if {$col == "tk_choose"} {
    	set color [tk_chooseColor]
		raise .colour .
	} else {
		set color $col
	}
	set PARAMS($name) $color
	$widg.colorButton configure -text "Colour: $color" -foreground $color
}

proc loadColorConfig { } {
global PARAMS
global tcl_platform
global env
	
	if {$tcl_platform(platform) == "windows"} {
		set colfile [file join $env(USERPROFILE) CCP4 idiffdisp.col]
	} else {
		set colfile [file join $env(HOME) .CCP4 idiffdisp.col]
		}
	if {[file exists $colfile] } {
		set f [open "$colfile" "r"]
		while { [eof $f] != 1} {
			# Go through the file and load each line
			set x [gets $f]
			if {$x != ""} {
				set PARAMS([lindex $x 0]) [lindex $x 1]
				}
			}
		close $f
	} else {
		#This will create the configuration file since it does not exists
		saveColorConfig
		loadColorConfig
	}
}

proc saveColorConfig { } {
global PARAMS
global tcl_platform
global env
	
	if {$tcl_platform(platform) == "windows"} {
		set colfile [file join $env(USERPROFILE) CCP4 idiffdisp.col]
	} else {
		set colfile [file join $env(HOME) .CCP4 idiffdisp.col]
		}

    # check that the directory exists, and if it does not make it!
    # bug # 3636
    
    if {$tcl_platform(platform) == "windows"} {
	set ccp4 [file join $env(USERPROFILE) CCP4]
    } else {
	set ccp4 [file join $env(HOME) .CCP4]
    }

    if { ! [file exists "$ccp4"] } {
	file mkdir "$ccp4"
    }


	set f [open "$colfile" "w"]
	
	if {[lsearch [array names PARAMS] SPOTS] != -1} {
		puts $f "SPOTS $PARAMS(SPOTS)\n"
	} else {
		puts $f "SPOTS blue\n"
	}
	if {[lsearch [array names PARAMS] BEAM_COL] != -1} {
		puts $f "BEAM_COL $PARAMS(BEAM_COL)\n"
	} else {
		puts $f "BEAM_COL red\n"
	}
	if {[lsearch [array names PARAMS] CIRCLE] != -1} {
		puts $f "CIRCLE $PARAMS(CIRCLE)\n"
	} else {
		puts $f "CIRCLE darkgreen\n"
	}
	if {[lsearch [array names PARAMS] CIRCVAL] != -1} {
		puts $f "CIRCVAL $PARAMS(CIRCVAL)\n"
	} else {
		puts $f "CIRCVAL green\n"
	}
	if {[lsearch [array names PARAMS] PROFLINE] != -1} {
		puts $f "PROFLINE $PARAMS(PROFLINE)\n"
	} else {
		puts $f "PROFLINE orange\n"
	}
	if {[lsearch [array names PARAMS] ZOOMBOXC] != -1} {
		puts $f "ZOOMBOXC $PARAMS(ZOOMBOXC)\n"
	} else {
		puts $f "ZOOMBOXC orange\n"
	}

	close $f

}

##############################################################################
#Procedure to handle call from command line rather than from ccp4i
##############################################################################

proc commandLine { myargs } {
global PARAMS
	if {[lindex $myargs 0] == "-image"} {
		openImagefile [lindex $myargs 1]
		addtoRecent "openImagefile [lindex $myargs 1]"
	} elseif {[lindex $myargs 0] == "-sector"} {
		set sublist [lrange $myargs 1 end]
		openSector $sublist
		addtoRecent "openSector $sublist"
	} elseif {[lindex $myargs 0] == "-movie"} {
		set sublist [lrange $myargs 1 end]
		openMovie $sublist
		addtoRecent "openMovie $sublist"
	} else {
		showMessage "Unknown keyword [lindex $myargs 0]"
	}
	set PARAMS(LAST_DIR) [file dirname [lindex $myargs 1]]
}

################################################################################
#Now starting the program

if {$tcl_platform(platform) == "windows"} {
	package require registry
	set libname DiffractionImage.dll
	#Searching for the convert program on windows
	set keyPath {HKEY_LOCAL_MACHINE\SOFTWARE\ImageMagick\Current}
	catch {set imgMgck_key [registry get $keyPath BinPath]} errmsg
	if {[string first "unable" $errmsg] != -1} {
		set PARAMS(CONVERT) "N/A"
		#showMessage "Image Magick not found, saving movie as gif is disabled"
	} else {
		set PARAMS(CONVERT) [file join [file normalize $imgMgck_key] convert.exe]
		}
} elseif {$tcl_platform(os) == "Darwin"} {
	set libname DiffractionImage.so
	set PARAMS(CONVERT) "N/A"
} else {
	set libname DiffractionImage.so
	set PARAMS(CONVERT) convert
}

set libpath [file join $env(CLIB) $libname]
if {[catch {load $libpath} ]==1} {
	showMessage "Impossible to load Diffraction Image library:\n $libpath"
	return
}
	
set garbage {}

set PARAMS(MAGNIFY) {0.125 0.25 0.333 0.5 1.0 2.0}
set PARAMS(ZOOM) 1
set PARAMS(ZOOM_TO) 2
set PARAMS(FIRSTOPEN) 0
set PARAMS(MOVIE_FILES) {}
set PARAMS(MOVIE_FRAMES) {}
set PARAMS(RECENT) {}
set PARAMS(PROFILE) {}
set PARAMS(LAST_ISGMA) 2.0
set PARAMS(LAST_DIR) [pwd]
set PARAMS(RES_CIRC) {}
set PARAMS(IMG_PEAKS) [new_PeakList]
set PARAMS(IMG_PEAKS_IMG) ""
set PARAMS(IMAGE) "nothing"

cd [file join "$env(CCP4I_TOP)" idiffdisp]
createMainWindow
cd $PARAMS(LAST_DIR)

wm title . "idiffdisp"
wm minsize . 730 500
wm deiconify .
wm protocol . WM_DELETE_WINDOW "myExit"
if {[llength $argv] > 1} {
	commandLine $argv
	}
