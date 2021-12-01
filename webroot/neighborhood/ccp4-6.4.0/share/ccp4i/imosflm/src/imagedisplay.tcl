package provide imagedisplay 3.0

set ::first_view_update 0

namespace eval img {}

itk::usual ImageDisplay { }
#itk::usual QuickDraw { }gmin\

# Create cursors for magnifier
namespace eval cursor {}
if {($::tcl_platform(os) != "Darwin") &&
    ($::tcl_platform(os) != "Windows NT")} {
    set ::cursor::box "@[file join $env(MOSFLM_GUI) bitmaps box.cursor] [file join $env(MOSFLM_GUI) bitmaps box.mask] black white"
    set ::cursor::zoom "@[file join $env(MOSFLM_GUI) bitmaps zoom.xbm] [file join $env(MOSFLM_GUI) bitmaps zoom_mask.xbm] black white"
    set ::cursor::mask "@[file join $env(MOSFLM_GUI) bitmaps mask_cursor.xbm] [file join $env(MOSFLM_GUI) bitmaps mask_mask.xbm] black white"
    set ::cursor::eraser "@[file join $env(MOSFLM_GUI) bitmaps eraser.xbm] [file join $env(MOSFLM_GUI) bitmaps eraser_mask.xbm] black pink"
} else {
    set ::cursor::box "dotbox"
    set ::cursor::zoom "dotbox"
    set ::cursor::mask "right_ptr"
    set ::cursor::eraser "cross_reverse"
}


##################################################
# Class ImageDisplay
# The class to represent the display for the image
# and all of the associated bits and bobs.
##################################################

class ImageDisplay {
    inherit itk::Toplevel

    #############################################
    # member variables
    #############################################

    # CURRENT IMAGE
    private variable predictions_by_type ; # array
    private variable predictions_height ""
    private variable predictions_width ""
    private variable prediction_nodes ""
    private variable currenthkl {}

    private variable imagegamma "1"

    # Flag to indicate if image has been opened
    private variable image_has_been_opened "0"
    # Flag to indicate if image is open
    private variable image_is_open "0"
    # Pointer to the image object currently displayed
    private variable image_object ""
    private variable next_image_object ""
    # Current template (textvariable)
    private variable current_template ""
    # Current image number (textvariable)
    private variable current_image_number ""
    private variable hide_active_mask "0"
    private variable show_info_labels "0"

    # Image lists
    private variable image_list {}

    # PANNING

    # variables to store cursor and bindings for restoration after panning
    private variable last_cursor ""
    private variable last_motion_binding ""
    # variables to store panning anchor
    private variable grab_x ""
    private variable grab_y ""
    private variable grab_left_x ""
    private variable grab_top_y ""
    private variable grab_right_x ""
    private variable grab_bottom_y ""

    # TK IMAGES

    # 3 images: master, view and zoom
    public variable master_image ""
    public variable view_image ""
    public variable zoom_image ""

    # IMAGE PROPERTIES

    # Size of master image
    private variable detector_size_x ""
    private variable detector_size_y ""
    # Size of displayed image
    private variable display_size_x ""
    private variable display_size_y ""

    # VIEW

    # Master coordinates of corners of view image
    private variable left_x 1
    private variable top_y 1
    private variable right_x 0
    private variable bottom_y 0

    # Zoom factor and min/max
    public variable zoom ""
    private variable max_zoom 64
    private variable min_zoom 0.25

    # Zoom dragging variables
    private variable zoom_click_x ""
    private variable zoom_click_y ""

    # variables to hold previous zoom and view position
    # NB. Used for plotting spots and predictions, so items can be
    # scaled and moved rather than redrawn
    private variable old_zoom ""
    private variable old_left_x 1
    private variable old_top_y 1

#     private variable zoom_queue ""

    # INFO LABELS

    # variables to hold bindings for resotring after showing info labels
    private variable pre_info_bindings ; # array
    private variable info_cursor ""

    private variable pre_zoom_bindings ; #array
    private variable pre_magnify_bindings ; #array


    # PREDICTIONS

    private variable prediction_width 0
    private variable prediction_height 0

    # set colours for types of prediction
    private variable predictioncolour_fulls "\#0000ff" ;# blue
    private variable predictioncolour_partials "\#ffff00" ;# yellow
    private variable predictioncolour_overlaps "\#ff0000" ;# red
    private variable predictioncolour_wide "\#00ff00" ;# green

    # CURSORS

    # Variable storing cursor to use when not showing hourglass
    private variable current_cursor ""

    # SETTINGS

    # variables used for interactive parameter setting
    private variable origin ""
    private variable axis_order ""
    private variable two_theta_direction ""
    private variable beam_x ""
    private variable beam_y ""
    private variable backstop_x ""
    private variable backstop_y ""
    private variable backstop_radius "5.00"
    private variable search_area_min_radius ""
    private variable search_area_max_radius ""
    private variable exclusion_segment_horizontal_check "0"
    private variable exclusion_segment_horizontal "0.00"
    private variable exclusion_segment_vertical_check "0"
    private variable exclusion_segment_vertical "0.00"
    private variable orientation "North"
    private variable offset "0.00"
    private variable distance ""
    private variable wavelength ""
    private variable pixel_size ""

    private variable high_resolution_limit ""
    private variable high_resolution_radius ""
    private variable low_resolution_limit ""
    private variable low_resolution_radius ""

    private variable i_sig_i "20"

    # variables for overlay editing
    private variable current_spot_search_parameter ""
    private variable new_spot_search_parameter ""
    
    private variable old_horizontal_exclusion "0"
    private variable old_vertical_exclusion "0"

    # marker deleting
    private variable highlighted_cross ""
    private variable highlighted_cross_colour ""
    private variable highlighted_mask ""

    # INTERACTIONS

    # interactive spot finding variables
    # radius used for searching near a mouse click for
    #  spot finding/deleting
    private variable search_radius "5"
    # timer for switching spot placement mode
    private variable spot_placing_timer "2000"
    # flag to indicate spot placing mode
    private variable spot_placing_mode "auto"
    # job queue for dynamic automatic spot placing
    private variable spot_placing_queue ""
    # job queue for stippling
    private variable stipple_queue ""

    #############################################
    # methods
    #############################################

    # accessor methods
    public method getImage ;# image shown
    public method getNextImage ;# image to be shown
    public method getCanvases ;# view and zoom canvases

    # reports whether an image is shown or not
    public method isOpen
    # reports whether an image is zoomed or not
    public method isZoomed

    # showing/hiding the viewer window
    public method show
    public method hide

    # enabling/disablingh the viewer window
    public method disable
    public method enable
    private method toggleAbility

    # Open an image
    public method openImage
    public method openCurrentImage
    public method recreateCurrentImage

    # Close the image
    public method closeImage

    # Jump to another image
    public method gotoImage

    # Image combo methods
    public method updateImageList
    public method selectImage
    public method updateImageArrows

    # Edit spots
    public method editSpots

    # Show a new image
    public method updateImage { newImage }
    public method updateFirstImage

    # Refresh the view
    public method updateView

    # Interaction utility functions
    public method getMasterPixel

    # Zooming methods
    #public method resetView
    public method zoomView { x1 y1 x2 y2 new_zoom}
    public method zoom
    public method zoomClick
    public method zoomDrag
    public method zoomRelease

    # panning
    public method panningClick
    public method panningRelease
    public method pan

    # Marker displaying methods
    public method plotSpots { }
    public method positionMarkers

    # Methods used for showing bad spots
    public method getBadSpots
    public method clearBadSpots
    public method processBadSpots
    
    private method plotBadSpots 
    
    # Methods used for showing predictions
    public method getPredictions
    public method clearPredictions
    public method processPredictions
    public method redrawPredictions
    public method setPredictionColour
    private method plotPredictions
    private method colourPredictions
    private method getRectangleCorners
    private method plotRectangle

    # Pick methods
    public method processPick

    # Magnifier methods
    public method magnifyStart
    public method magnifyMove
    public method magnifyEnd

    # Tool toggle methods
    # overlays
    public method toggleSpots
    public method toggleBadSpots
    public method togglePredictions
    public method toggleBeam
    public method toggleMasks
    public method toggleSpotfindingParameters
    public method toggleResolutionLimits
    public method toggleActiveMask
    public method toggleInfoLabels
    # tools
    public method toggleZoomTool
    public method tryAutoBackstop
    public method togglePointerTool
    public method toggleMaskingTool
    public method toggleSpotAddingTool
    public method toggleCircleFittingTool
    public method toggleEraserTool
    public method togglePanningTool

    public method toggleTools ; # obsolete

    # constant interaction bindings

    private method storePreBindings
    private method restorePreBindings

    public method startInfoLabels
    public method endInfoLabels
    public method showInfoLabels

    # tool bindings
    private method setupZoomToolBindings
    private method removeZoomToolBindings
    private method setupSpotAddingBindings
    private method removeSpotAddingBindings
    private method setupEraserBindings
    private method removeEraserBindings
    private method setupPanningBindings
    private method removePanningBindings

    private method enableZoomMagnifier
    private method disableZoomMagnifier

    private method clearCanvasBindings

    # Data access methods
    public method parseHistogram
    public method parseBackstop

    # NEW METHODS FOR INTERACTIVE SPOTFIND PARAM SETTING
    public method updateSetting
    public method plotBeam
    public method plotBackstop
    public method plotSpotSearchSettings
    public method plotResolutionLimits
    public method plotBackstopRadius
    public method plotBackstopCentre
    public method plotMaxSearchRadius
    public method plotMinSearchRadius
    public method plotExclusionSegment
    public method plotHighResolutionLimit
    public method plotLowResolutionLimit
    public method plotCircle
    public method plotExclusion
    public method stippleOut
    public method stippleOutSly
    public method getCurrentViewCentrePixel

    public method editSpotSearchParameterStart
    public method editSpotSearchParameterMove
    public method editSpotSearchParameterClick
    public method editSpotSearchParameterRelease
    public method editSpotSearchParameterDrag
    public method editSpotSearchParameterEnd

    public method query

    # Methods used for interactive spot finding

    public method placeSpotStart
    public method placeSpotMove
    public method getSpotLineEnds
    public method placeSpotClick
    public method placeSpotRelease
    public method placeSpotEnd
    public method placeSpot
    public method localSpotSearch
    public method deleteMarkerStart
    public method deleteMarkerMove
    public method deleteMarkerClick
    public method deleteMarkerRelease
    public method deleteMarkerEnd

    private method findClosestNearItem

#added by luke on 31 October 2007
	public method getCoorx
	public method getCoory
	private method startInfoLabelsScroll
	private method showInfoLabelsScroll
	private method endInfoLabelsScroll
	private method resetViewerSizeLuke
	private method resizeWindow
	
	public method adjustContrast

	private variable abs_min_zoom

	private method FindMyHKL
	private variable hvariable ""
	private variable kvariable ""
	private variable lvariable ""
    ################

	public method findHKL
	public method plotHKL

	public method mousePick

    #############################################

    constructor { args } {

	itk_option add hull.menu

	#itk_option add hull.borderwidth
	#$itk_component(hull) configure -borderwidth 0

	wm title .image "\[No image\] - Mosflm"
	wm resizable .image 1 1
	wm iconbitmap $itk_component(hull) [wm iconbitmap .]
	wm iconmask $itk_component(hull) [wm iconmask .]
	wm group $itk_component(hull) .
	wm protocol $itk_component(hull) \
	    WM_DELETE_WINDOW [code $this hide]
	hide

	wm minsize .image 600 600

	### Menu bar and menus ####################################
	###########################################################

	itk_component add menu {
	    menu $itk_interior.menu \
		-tearoff 0 \
		-borderwidth 1
	}

	.image configure \
	    -menu $itk_component(menu)
	
	# Image menu ###############################################

	itk_component add imagemenu {
	    menu $itk_interior.menu.image \
		-tearoff false \
		-relief raised \
		-borderwidth 1 \
		-activeborderwidth 0
	}

	$itk_component(menu) add cascade \
	    -label "Image" \
	    -menu $itk_component(imagemenu)
	
	$itk_component(imagemenu) add command \
	    -label Next \
	    -underline 0 \
	    -accelerator "Alt-right" \
	    -command [code $this gotoImage "next"]
    
	$itk_component(imagemenu) add command \
	    -label Preceding \
	    -underline 0 \
	    -accelerator "Alt-left" \
	    -command [code $this gotoImage "prev"]
    
	bind $itk_component(hull) <Alt-Right> [code $this gotoImage "next"]
	bind $itk_component(hull) <Alt-Left> [code $this gotoImage "prev"]


    # Add menu icons on linux

	if {($::tcl_platform(os) != "Darwin") &&
	    ($::tcl_platform(os) != "Windows NT")} {
	    
	    $itk_component(imagemenu) entryconfigure 0 \
		-compound left \
		-image ::img::next_arrow

	    $itk_component(imagemenu) entryconfigure 1 \
		-compound left \
		-image ::img::prev_arrow
	}

	itk_component add viewmenu {
	    menu $itk_interior.menu.view \
		-tearoff false \
		-relief raised \
		-borderwidth 1 \
		-activeborderwidth 0
	}

	$itk_component(menu) add cascade \
	    -label "View" \
	    -menu $itk_component(viewmenu)

 	# Tools menu ##############################################

	itk_component add toolsmenu {
	    menu $itk_interior.menu.tools \
		-tearoff false \
		-relief raised \
		-borderwidth 1 \
		-activeborderwidth 0
	}

 	$itk_component(menu) add cascade \
 		-label "Tools" \
 		-menu $itk_component(toolsmenu)
 
	$itk_component(toolsmenu) add command \
	    -label "Colour predictions" \
	    -underline 0 \
	    -command [code $this colourPredictions]

	# Tool bar components #####################################
	###########################################################

	# Toolbar rows
	
	itk_component add toolbar_row_1 {
	    frame $itk_interior.tbr1 \
		    -relief flat \
		    -borderwidth 0
	} {
	    ignore -background
	}
	pack $itk_component(toolbar_row_1) -side top -fill x -expand 0
	
	itk_component add toolbar_row_2 {
	    frame $itk_interior.tbr2 \
		    -relief flat \
		    -borderwidth 0
	}
	pack $itk_component(toolbar_row_2) -side top -fill x -expand 0
	
	itk_component add toolbar_row_3 {
	    frame $itk_interior.tbr3 \
		    -relief flat \
		    -borderwidth 0
	}

	# Image toolbar

	itk_component add image_toolbar {
	    frame $itk_component(toolbar_row_1).itb \
		    -relief raised \
		    -borderwidth 1
	} {
	    keep -background
	}
	pack $itk_component(image_toolbar) -side left

	itk_component add preceding_image {
	    Toolbutton $itk_component(image_toolbar).prev \
		-image ::img::prev_arrow \
		-disabledimage ::img::prev_arrow_disabled \
		-type "amodal" \
		-state "normal" \
		-balloonhelp " Preceding image " \
		-command [code $this gotoImage "prev"]
	}
	pack $itk_component(preceding_image) -side left -padx 1
	
	itk_component add next_image {
	    Toolbutton $itk_component(image_toolbar).next \
		-image ::img::next_arrow \
		-disabledimage ::img::next_arrow_disabled \
		-type "amodal" \
		-state "normal" \
		-balloonhelp " Next image " \
		-command [code $this gotoImage "next"]
	}
	pack $itk_component(next_image) -side left -padx 1
		
	itk_component add image_combo {
	    combobox::combobox $itk_component(image_toolbar).ic \
		-width 40 \
		-editable 0 \
		-highlightcolor black \
		-command [code $this selectImage]
	} {
	    keep -background -cursor -foreground -font
	    keep -selectbackground -selectborderwidth -selectforeground
	    keep -highlightcolor -highlightthickness
	    rename -highlightbackground -background background Background
	    rename -background -textbackground textBackground Background
	}
	pack $itk_component(image_combo) -side left -padx 1

	# markers toolbar
		
	itk_component add markers_toolbar {
	    frame $itk_component(toolbar_row_2).mtb \
		    -relief raised \
		    -borderwidth 1
	}
	pack $itk_component(markers_toolbar) -side left 
				
	itk_component add beam {
	    Toolbutton $itk_component(markers_toolbar).beam \
		-image ::img::beam16x16 \
		-activeimage ::img::beam_on16x16 \
		-disabledimage ::img::beam16x16 \
		-state "normal" \
		-type "modal" \
		-balloonhelp " Show beam centre " \
		-command [code $this toggleBeam]
	}
	pack $itk_component(beam) -side left -padx 1

	itk_component add backstop {
	    Toolbutton $itk_component(markers_toolbar).backstop \
		-image ::img::backstop16x16 \
		-state "normal" \
		-type "modal" \
		-balloonhelp " Show backstop centre " \
		-command [code $this toggleBackstop]
	}

	itk_component add spots {
	    Toolbutton $itk_component(markers_toolbar).spots \
		-image ::img::spot16x16 \
		-activeimage ::img::spot_on16x16 \
		-disabledimage ::img::spot16x16 \
		-state "normal" \
		-type "modal" \
 		-balloonhelp " Show spots " \
		-command [code $this toggleSpots]
	}
	pack $itk_component(spots) -side left -padx 1

	itk_component add badspots {
	    Toolbutton $itk_component(markers_toolbar).badspots \
		-image ::img::badspots_16x16 \
		-state "normal" \
		-type "modal" \
 		-balloonhelp " Show Bad spots " \
		-command [code $this toggleBadSpots]
	}
	pack $itk_component(badspots) -side left -padx 1

	itk_component add predictions {
	    Toolbutton $itk_component(markers_toolbar).prediction \
		-image ::img::boxes16x16 \
		-activeimage ::img::boxes_on16x16 \
		-disabledimage ::img::boxes_disabled16x16 \
		-state "disabled" \
		-type "modal" \
		-balloonhelp " Show predictions " \
		-command [code $this togglePredictions]
	}
	pack $itk_component(predictions) -side left -padx 1
	
	itk_component add masks {
	    Toolbutton $itk_component(markers_toolbar).masks \
		-image ::img::masks16x16 \
		-activeimage ::img::masks_on16x16 \
		-disabledimage ::img::masks16x16 \
		-type "modal" \
		-state "normal" \
		-balloonhelp " Show masked areas (including backstop)" \
		-command [code $this toggleMasks]
	}
	pack $itk_component(masks) -side left -padx 1
	
	itk_component add spotfinding_settings {
	    Toolbutton $itk_component(markers_toolbar).spotfinding \
		-image ::img::spot_search_area16x16 \
		-activeimage ::img::spot_search_area_on16x16 \
		-state "normal" \
		-type "modal" \
		-balloonhelp " Show spotfinding search area " \
		-command [code $this toggleSpotfindingParameters]
	}
	pack $itk_component(spotfinding_settings) -side left -padx 1

	itk_component add resolution_limits {
	    Toolbutton $itk_component(markers_toolbar).resolution \
		-image ::img::resolution_limits16x16 \
		-activeimage ::img::resolution_limits_on16x16 \
		-state "normal" \
		-type "modal" \
		-balloonhelp " Show resolution limits " \
		-command [code $this toggleResolutionLimits]
	}
	pack $itk_component(resolution_limits) -side left -padx 1

	itk_component add active_mask {
	    Toolbutton $itk_component(markers_toolbar).actmsk \
		-image ::img::rigaku16x16 \
		-activeimage ::img::rigaku16x16 \
		-disabledimage ::img::rigaku_grey16x16 \
		-state "normal" \
		-type "modal" \
 		-balloonhelp " Hide active mask on Rigaku detector " \
		-command [code $this toggleActiveMask]
	}
	pack $itk_component(active_mask) -side left -padx 1

	itk_component add info_labels {
	    Toolbutton $itk_component(markers_toolbar).il \
		-image ::img::info_labels \
		-disabledimage ::img::info_labels \
		-type "modal" \
		-state "normal" \
		-balloonhelp " Show info labels " \
		-command [code $this toggleInfoLabels]
	}
# 	pack $itk_component(info_labels) -side left -padx 1


	# Tools toolbar

	itk_component add tools_toolbar {
	    frame $itk_component(toolbar_row_2).ttb \
		    -relief raised \
		    -borderwidth 1
	}
	pack $itk_component(tools_toolbar) -side left 
	
	itk_component add zoom_tool {
	    Toolbutton $itk_component(tools_toolbar).zoomtool \
		-image ::img::magnifier \
		-activeimage ::img::magnifier_on \
		-disabledimage ::img::magnifier \
		-type "radio" \
		-group "image_tools" \
		-state "normal" \
		-balloonhelp " Zoom tool " \
		-command [code $this toggleZoomTool]
	}
	pack $itk_component(zoom_tool) -side left -padx 1
	
	itk_component add panning_tool {
	    Toolbutton $itk_component(tools_toolbar).pt \
		-image ::img::fleur16x16 \
		-activeimage ::img::fleur_on16x16 \
		-disabledimage ::img::fleur16x16 \
		-type "radio" \
		-group "image_tools" \
		-state "normal" \
		-balloonhelp " Panning tool " \
		-command [code $this togglePanningTool]
	}
 	pack $itk_component(panning_tool) -side left -padx 1

	itk_component add pointer {
	    Toolbutton $itk_component(tools_toolbar).pointer \
		-image ::img::pointer16x16 \
		-activeimage ::img::pointer_on16x16 \
		-disabledimage ::img::pointer16x16 \
		-type "radio" \
		-group "image_tools" \
		-state "normal" \
		-balloonhelp " Selection tool for editing search area, processing limits and masks " \
		-command [code $this togglePointerTool]
	}
	pack $itk_component(pointer) -side left -padx 1
		
	itk_component add spotfinding {
	    Toolbutton $itk_component(tools_toolbar).spotfinding \
		-image ::img::pencil16x16 \
		-activeimage ::img::pencil_on16x16 \
		-disabledimage ::img::pencil16x16 \
		-type "radio" \
		-group "image_tools" \
		-state "normal" \
		-balloonhelp " Manually add spots " \
		-command [code $this toggleSpotAddingTool]
	}
	pack $itk_component(spotfinding) -side left -padx 1
	
	itk_component add masking_tool {
	    Toolbutton $itk_component(tools_toolbar).mt \
		-image ::img::masking16x16 \
		-activeimage ::img::masking_on16x16 \
		-disabledimage ::img::masking16x16 \
		-type "radio" \
		-group "image_tools" \
		-state "normal" \
		-balloonhelp " Masking tool " \
		-command [code $this toggleMaskingTool]
	}
 	pack $itk_component(masking_tool) -side left -padx 1

	itk_component add circle_fitting {
	    Toolbutton $itk_component(tools_toolbar).cf \
		-image ::img::circle_fitting16x16 \
		-activeimage ::img::circle_fitting_on16x16 \
		-disabledimage ::img::circle_fitting16x16 \
		-type "radio" \
		-group "image_tools" \
		-state "normal" \
		-balloonhelp " Circle fitting " \
		-command [code $this toggleCircleFittingTool]
	}
 	pack $itk_component(circle_fitting) -side left -padx 1

	itk_component add spotdeleting {
	    Toolbutton $itk_component(tools_toolbar).spotdeleting \
		-image ::img::eraser16x16 \
		-activeimage ::img::eraser_on16x16 \
		-disabledimage ::img::eraser16x16 \
		-type "radio" \
		-group "image_tools" \
		-state "normal" \
		-balloonhelp " Spots and mask eraser " \
		-command [code $this toggleEraserTool]
	}
	pack $itk_component(spotdeleting) -side left -padx 1

	# buttons toolbar
		
	itk_component add buttons_toolbar {
	    frame $itk_component(toolbar_row_2).btb \
		    -relief raised \
		    -borderwidth 1
	}
	pack $itk_component(buttons_toolbar) -side left

	# We are still not yet quite ready to release this ...
	#itk_component add autobackstop {
	#    Toolbutton $itk_component(buttons_toolbar).autobackstop \
	#	-image ::img::autobackstop \
	#	-balloonhelp " Automatic backstop detection " \
	#	-command [code $this tryAutoBackstop]
	#}
	#pack $itk_component(autobackstop) -side left -padx 1

	# findHKL toolbar
		
	itk_component add findHKL_toolbar {
	    frame $itk_component(toolbar_row_2).fhkl \
		-relief raised \
		-borderwidth 1
	}
	pack $itk_component(findHKL_toolbar) -side left -padx 1

	itk_component add h_label {
	    label $itk_component(findHKL_toolbar).hl \
		-text "h"
	}
	pack $itk_component(h_label) -side left

	itk_component add h_entry {
	    gEntry $itk_component(findHKL_toolbar).hentry \
		-type int \
		-width 3 \
		-justify right \
		-linkcommand [code $this FindMyHKL] \
		-textvariable [scope hvariable]
	}
	pack $itk_component(h_entry) -side left
    
	itk_component add k_label {
	    label $itk_component(findHKL_toolbar).kl \
		-text "k"
	}
	pack $itk_component(k_label) -side left

	itk_component add k_entry {
	    gEntry $itk_component(findHKL_toolbar).kentry \
		-type int \
		-width 3 \
		-justify right \
		-linkcommand [code $this FindMyHKL] \
		-textvariable [scope kvariable]
	}
	pack $itk_component(k_entry) -side left

	itk_component add l_label {
	    label $itk_component(findHKL_toolbar).ll \
		-text "l"
	}
	pack $itk_component(l_label) -side left

	itk_component add l_entry {
	    gEntry $itk_component(findHKL_toolbar).lentry \
		-type int \
		-width 3 \
		-justify right \
		-linkcommand [code $this FindMyHKL] \
		-textvariable [scope lvariable]
        }
	pack $itk_component(l_entry) -side left

	itk_component add find {
	    Toolbutton $itk_component(findHKL_toolbar).find \
		-image ::img::status_warning_on16x16 \
		-balloonhelp " Find hkl " \
		-command [code $this FindMyHKL]
	}
	pack $itk_component(find) -side left
    
	# Zoom toolbar

	itk_component add zoom_toolbar {
	    frame $itk_interior.tbr1.ztb \
		-relief raised \
		-borderwidth 1
	}
	pack $itk_component(zoom_toolbar) -side left 
		
	
	itk_component add zoom_in_tool {
	    Toolbutton $itk_component(zoom_toolbar).zit \
		-image ::img::zoom_in16x16 \
		-disabledimage ::img::zoom_in_disabled16x16 \
		-type "amodal" \
		-state "normal" \
		-balloonhelp " Zoom in " \
		-command [code $this zoom "in"]
	}
	pack $itk_component(zoom_in_tool) -side left -padx 1
	
	itk_component add zoom_out_tool {
	    Toolbutton $itk_component(zoom_toolbar).zot \
		-image ::img::zoom_out16x16 \
		-disabledimage ::img::zoom_out_disabled16x16 \
		-type "amodal" \
		-state "normal" \
		-balloonhelp " Zoom out " \
		-command [code $this zoom "out"]
	}
	pack $itk_component(zoom_out_tool) -side left -padx 1
	
	itk_component add fit_image {
	    Toolbutton $itk_component(zoom_toolbar).fi \
		-image ::img::fit_image16x16 \
		-disabledimage ::img::fit_image16x16 \
		-type "amodal" \
		-state "normal" \
		-balloonhelp " Fit image " \
		-command [code $this resetViewerSizeLuke]
#The above command used to be resetView but I changed it to resetViewerSizeLuke
	}
	pack $itk_component(fit_image) -side left -padx 1
	
	itk_component add contrast_button {
	    Toolbutton $itk_component(zoom_toolbar).contrast \
		-image ::img::contrast16x16 \
		-disabledimage ::img::contrast16x16 \
		-type "modal" \
		-state "normal" \
		-balloonhelp " Contrast "
	}
	pack $itk_component(contrast_button) -side left -padx 1

	itk_component add contrast_entry {
		entry $itk_component(zoom_toolbar).contrastentry
	}
	bind $itk_component(contrast_entry) <Return> [code $this adjustContrast]
	
	itk_component add contrast_spin {
		spinbox $itk_component(zoom_toolbar).contrastspin \
		-from 0.00 -to 5.00 \
		-increment 0.5 -format %5.2f -width 10
	} {
		keep -background
	}

	itk_component add contrast_palette {
	    Contrast .contrast_palette
	}
	$itk_component(contrast_button) configure \
	    -command [list $itk_component(contrast_palette) launch $itk_component(contrast_button)]

	# filler toolbars

	itk_component add toolbarX1 {
	    frame $itk_component(toolbar_row_1).tbx \
		    -relief raised \
		    -borderwidth 1
	}
	pack $itk_component(toolbarX1) -side left -fill both -expand 1
		
	itk_component add toolbarX2 {
	    frame $itk_component(toolbar_row_2).tbx \
		    -relief raised \
		    -borderwidth 1
	}
	pack $itk_component(toolbarX2) -side left -fill both -expand 1
		
	itk_component add toolbarX3 {
	    frame $itk_component(toolbar_row_3).tbx \
		    -relief raised \
		    -borderwidth 1
	}
	pack $itk_component(toolbarX3) -side right -fill both -expand 1

	itk_component add main {
	    frame $itk_interior.main \
		    -relief raised \
		    -borderwidth 1 \
		    -width 502 \
		    -height 502
	} {
	    keep -background
	}
	pack $itk_component(main) -fill both -expand true

	# Canvas component ########################################
	###########################################################

	itk_component add canvas {
	    canvas $itk_interior.main.canvas \
		-width 500 \
		-height 500 \
		-bg #a9a9a9 \
		-relief sunken \
		-bd 0 \
		-highlightthickness 0
	}
	pack $itk_component(canvas) -expand true

	bind $itk_component(main) <Configure> [code $this resizeWindow]

	# intialize cursor for initial tool (zoom)
	if {[tk windowingsystem] == "x11"} {
	    $itk_component(canvas) configure -cursor $::cursor::zoom
	}	    

	# Magnifier component #####################################
	###########################################################
	
	itk_component add magnifier {
	    toplevel .magnifier -bg #a9a9a9 -borderwidth 0
	} {
	}
	wm overrideredirect $itk_component(magnifier) 1
	if {[tk windowingsystem] == "aqua"} {
	    ::tk::unsupported::MacWindowStyle style $itk_component(magnifier) help none 
	}
	wm withdraw $itk_component(magnifier)
	
	itk_component add border {
	    frame .magnifier.border \
		    -bg #000000
	} {
	}
	pack $itk_component(border)

	itk_component add mag_canvas {
	    canvas .magnifier.border.c \
		    -width 80\
		    -height 80\
		    -bg #a9a9a9 \
		    -relief sunken \
		    -bd 0 \
		    -highlightthickness 0 \
		    -highlightbackground #dcdcdc \
		    -cursor "left_ptr" \
		    -xscrollincrement 1 \
		    -yscrollincrement 1
	}
	pack $itk_component(mag_canvas) -padx 1 -pady 1 -fill both -expand 1
	
	# Info labels component ########################################
	################################################################

	itk_component add data_labels {
	    toplevel .dataLabel \
		-border 0
	}
	wm overrideredirect $itk_component(data_labels) 1
	if {[tk windowingsystem] == "aqua"} {
	    ::tk::unsupported::MacWindowStyle style $itk_component(data_labels) help none
	}
	wm withdraw $itk_component(data_labels)

	itk_component add data_label_1 {
	    label .dataLabel.l1 \
		-text "?"\
		-relief solid \
		-highlightthickness 0 \
		-bd 2 \
		-font font_b
	} {
	    usual
	    ignore -font -highlightthickness
	}
	pack $itk_component(data_label_1) -fill x

	itk_component add data_label_2 {
	    label .dataLabel.l2 \
		-text "?"\
		-relief solid \
		-highlightthickness 0 \
		-bd 2 \
		-font font_b
	} {
	    usual
	    ignore -font -highlightthickness
	}
	itk_component add data_label_3 {
	    label .dataLabel.l3 \
		-text "?"\
		-relief solid \
		-highlightthickness 0 \
		-bd 2 \
		-font font_b
	} {
	    usual
	    ignore -font -highlightthickness
	}
	itk_component add data_label_4 {
	    label .dataLabel.l4 \
		-text "?"\
		-relief solid \
		-highlightthickness 0 \
		-bd 2 \
		-font font_b
	} {
	    usual
	    ignore -font -highlightthickness
	}
	itk_component add data_label_5 {
	    label .dataLabel.l5 \
		-text "?"\
		-relief solid \
		-highlightthickness 0 \
		-bd 2 \
		-font font_b
	} {
	    usual
	    ignore -font -highlightthickness
	}
	
	# Overlays #####################################################
	################################################################

	Overlay::initialize $itk_component(canvas)

	# Header component #############################################
	################################################################
	
	# Create images (to be filled with data on demand) #############
	set master_image [image create photo]
	set view_image [image create photo]
	set zoom_image [image create photo]

	# Display the images in their canvases #########################
	$itk_component(canvas) create image 0 0 \
	    -image $view_image -tags view_image -anchor nw 
	$itk_component(mag_canvas) create image 0 0 \
	    -image $zoom_image -anchor nw -tags zoom_image

	# Plot the origin on the mag canvas ############################
	$itk_component(mag_canvas) create text 0 0 -text "X" -tags [list origin marker]

	# Evalutate options ############################################
	eval itk_initialize $args

	set ::image_open 0

    }
}

body ImageDisplay::FindMyHKL { } {

    #puts "FindMyHKL $hvariable $kvariable $lvariable"
    if {[.image findHKL $hvariable $kvariable $lvariable]} {
	$itk_component(findHKL_toolbar).find configure -image ::img::status_ok16x16
	plotHKL
    } else {
	$itk_component(findHKL_toolbar).find configure -image ::img::status_warning_on16x16
    }
}

body ImageDisplay::mousePick {a_x a_y} {
    
    set mp_image_number [$image_object getNumber]
    set l_pixel_coords [getMasterPixel $a_x $a_y]
    set pixel_coord_x [lindex $l_pixel_coords 0]
    set pixel_coord_y [lindex $l_pixel_coords 1]
    #puts "pick on image $mp_image_number got Master pixels x,y $pixel_coord_x $pixel_coord_y"

    # Now box size can be set in x and y the offset for detecting the edge of the image is not fixed
    set x_offset [expr {[$::session getParameterValue pickbox_size_x]/2}]
    set y_offset [expr {[$::session getParameterValue pickbox_size_y]/2}]

    #puts "x,y-offsets: $x_offset,$y_offset"
    if {$zoom != $max_zoom} {
	while {[expr {$pixel_coord_x - $x_offset}] < 1} {
	    incr pixel_coord_x
	}

	while {[expr {$pixel_coord_y - $y_offset}] < 1} {
	    incr pixel_coord_y
	}

	while {[expr {$pixel_coord_y + $y_offset}] > [expr {[$::session getImageHeight] - 1}]} {
	    incr pixel_coord_y -1
	}

	while {[expr {$pixel_coord_x + $x_offset}] > [expr {[$::session getImageWidth] - 1}]} {
	    incr pixel_coord_x -1
	}

	$::mosflm sendCommand "pick $mp_image_number $pixel_coord_x $pixel_coord_y [$::session getParameterValue pickbox_size_x] [$::session getParameterValue pickbox_size_y] \n"
	$::mosflm sendCommand "go \n"
    }
}

body ImageDisplay::adjustContrast {} {
	set gammavalue [$itk_component(contrast_entry) get]
	set dest [image create photo -gamma 1]
	$dest copy $view_image
	image delete $view_image
	set view_image [image create photo -gamma $gammavalue]
	$view_image copy $dest
	$itk_component(canvas) itemconfigure view_image -image $view_image
	image delete $dest
}

##############################################################################
# Accessor methods
##############################################################################

body ImageDisplay::getImage { } {
    return $image_object
}

body ImageDisplay::getNextImage { } {
    return $next_image_object
}

body ImageDisplay::getCanvases { } {
    return [list $itk_component(canvas) $itk_component(mag_canvas)]
}

##############################################################################
# Method to report whther an image is open 
##############################################################################

body ImageDisplay::isOpen { } {
    return $image_is_open
}

body ImageDisplay::isZoomed { } {
    #puts "isZoomed zoom: $zoom min: $min_zoom"
    if { $zoom > $min_zoom } {
	return 1
    } else {
	return 0
    }
}

##############################################################################
# Methods to show and hide image viewer 
##############################################################################

body ImageDisplay::show { } {
    wm deiconify $itk_component(hull)
}

body ImageDisplay::hide { } {
    wm withdraw $itk_component(hull)
}

##############################################################################
# enabling/disablingh the viewer window
##############################################################################

body ImageDisplay::disable { } {
    toggleAbility "disabled"
    $itk_component(preceding_image) configure -state disabled
    $itk_component(next_image) configure -state disabled
}

body ImageDisplay::enable { } {
    toggleAbility "normal"
	updateImageArrows
}

body ImageDisplay::toggleAbility { a_state } {
    $itk_component(menu) entryconfigure 0 -state $a_state
    $itk_component(image_combo) configure -state $a_state
    $itk_component(contrast_button) configure -state $a_state

}

##############################################################################
# Method to open a new image in the viewer
##############################################################################

body ImageDisplay::openImage { an_image } {

    # disable viewer 
    .image disable

    # Update image controls and title
    set next_image_object $an_image
    
    # Getcontrast limits
    foreach { l_min l_max } [$itk_component(contrast_palette) getContrast] break

    # Get the image from mosflm
    $::mosflm getImage $an_image $l_min $l_max

    # If there is an a-matrix, get predictions
    if {[[$an_image getSector] reportMatrix] != "Unknown"} {
	#puts "OPENIMAGE GET PREDICTIONS"
	getPredictions
    }

    # N.B. receipt of image data and updateImage

    # Disable the Rigaku active mask toggle button if image not from a Rigaku detector
    set detector_model [$::session getParameterValue detector_model]
    #puts $detector_model
    set rigakus {JUPITER SATURN MERCURY A200}
    if { [lsearch $rigakus $detector_model] < 0 } {
	$itk_component(active_mask) configure -state "disabled"
    }

}

body ImageDisplay::openCurrentImage { an_image } {

    # Update image controls and title
    set next_image_object $an_image

    # Getcontrast limits
    foreach { l_min l_max } [$itk_component(contrast_palette) getContrast] break
    
    # Get the current image from mosflm
    $::mosflm getCurrentImage $l_min $l_max
    # Get the current predictions
    #puts "OPENCURRENTIMAGE and getCurrentPredictions"
    $::mosflm getCurrentPredictions

    # N.B. receipt of image data and updateImage

}    

body ImageDisplay::recreateCurrentImage { } {
	set image_object [.image getImage]
	set l_directory [$image_object getDirectory]
	set l_template [$image_object getTemplate]
	set l_image_number [$image_object getNumber]
	$::mosflm sendCommand "directory $l_directory"
	$::mosflm sendCommand "template $l_template"
	$::mosflm sendCommand "image $l_image_number"
	$::mosflm sendCommand "xgui on"
	$::mosflm sendCommand "go"
	$::mosflm sendCommand "create_grey_image 0 0 smooth [$::mosflm setSmoothLevel]"
	$::mosflm sendCommand "return"
	# re-display predictions
	if {[$::session predictionPossible]} {
	    getPredictions
	}
}

body ImageDisplay::closeImage { } {
    set image_object ""
    wm title .image "No image displayed - Mosflm"
    hide

    #clearTemplates

    # Clear master image
    image delete $master_image
    set master_image [image create photo]

    # Reset view image
    image delete $view_image
    set view_image [image create photo]
    $itk_component(canvas) itemconfigure view_image -image $view_image

    # Reset the contrast palette
    $itk_component(contrast_palette) reset

    # Set flag to indicate no image has been opened in current session
    set image_has_been_opened 0

    # Turn off image bindings
    foreach i_event [bind $itk_component(canvas)] {
	bind $itk_component(canvas) $i_event {}
    }

    # Disable image combo
    $itk_component(image_combo) configure -state disabled

    # Turn off overlays
    foreach i_toolbutton {spots predictions spotfinding_settings resolution_limits info_labels spotfinding spotdeleting zoom_tool pointer } {
	$itk_component($i_toolbutton) cancel
    }

    # Disable tools
    foreach i_toolbutton {preceding_image next_image image_combo spots predictions spotfinding_settings resolution_limits info_labels spotfinding spotdeleting zoom_tool pointer zoom_in_tool zoom_out_tool fit_image contrast_button } {
	$itk_component($i_toolbutton) configure -state disabled
    }

    # Reset initialize flag
    #puts "Here - set image_has_been_opened 0"
    set image_has_been_opened 0
}

body ImageDisplay::gotoImage { which } {
    #puts $image_list
    set curr_posn [lsearch $image_list $image_object]
    #puts "At posn. $curr_posn $image_object"
# not always moving thro sequential images so do not incr/decr image no., rather the position in list
    if {$which == "prev"} {
	set new_posn [expr $curr_posn - 1]
	if { $new_posn < 0 } { return }
	set l_new_image_num [[lindex $image_list $new_posn] getNumber]
    } elseif {$which == "next"} {
	set new_posn [expr $curr_posn + 1]
	if { $new_posn > [expr [llength $image_list] - 1] } { return }
	set l_new_image_num [[lindex $image_list $new_posn] getNumber]
    } else {
	error "Bad argument passed to gotoImage: $which"
    }
    #puts "New posn. $new_posn New image no. $l_new_image_num"
    set l_template [[lindex $image_list $new_posn] getTemplate]
    set l_new_image [$::session getImageByTemplateAndNumber $l_template $l_new_image_num]
    if {$l_new_image != ""} {
	openImage $l_new_image
    }
}

body ImageDisplay::updateImageList { } {
    # Get new image list from session
    set image_list [$::session getImages]
    # Update combo box's listvar
    set l_image_names {}
    foreach i_image $image_list {
	lappend l_image_names [$i_image getShortName]
    }
    $itk_component(image_combo) list delete 0 end
    eval $itk_component(image_combo) list insert 0 $l_image_names
    # Update image arrows
    updateImageArrows
}

body ImageDisplay::selectImage { a_combo a_filename } {
    set l_selected_image_object [$::session getImageByName $a_filename]
    if {$l_selected_image_object != $image_object} {
	openImage $l_selected_image_object
    }
}

body ImageDisplay::updateImageArrows { } {
    if {$image_object != ""} {
	set l_pos [lsearch $image_list $image_object]
	if {$l_pos > 0} {
	    # enable previous arrow
	    $itk_component(preceding_image) configure -state "normal"
	    $itk_component(imagemenu) entryconfigure 1 -state "normal"
	} else {
	    # disable previous arrow
	    $itk_component(preceding_image) configure -state "disabled"
	    $itk_component(imagemenu) entryconfigure 1 -state "disabled"
	}
	if {$l_pos < [expr [llength $image_list] -1]} {
	    # enable next arrow
	    $itk_component(next_image) configure -state "normal"
	    $itk_component(imagemenu) entryconfigure 0 -state "normal"
	} else {
	    # disable next arrow
	    $itk_component(next_image) configure -state "disabled"
	    $itk_component(imagemenu) entryconfigure 0 -state "disabled"
	}
    }
}

##############################################################################
# Method to edit spots on an image in the viewer
##############################################################################

body ImageDisplay::editSpots { { an_image "" } } {

    # if necessary open the image
    if {($an_image != "") && ($an_image != $image_object)} {
	openImage $an_image
    }

    # Select the spot adding tool
    $itk_component(spotfinding) invoke
}    

##############################################################################
# Method to display received jpeg
##############################################################################

body ImageDisplay::updateFirstImage { } {

    #puts "ImageDisplay::updateFirstImage"
    # Calculate detector size
    set detector_size_x [image width $master_image]
    set detector_size_y [image height $master_image]
    #puts "detector_size_y $detector_size_y"

    set l_screen_height [winfo screenheight $itk_component(canvas)]
    #puts "l_screen_height $l_screen_height"
    
    set l_screen_gubbins 200
    set l_max_space_per_pixel [expr double($l_screen_height - $l_screen_gubbins) / $detector_size_y]
    #puts "l_max_space_per_pixel $l_max_space_per_pixel"
    
    set min_zoom [expr pow(2,floor(log($l_max_space_per_pixel)/log(2)))]
	
    set abs_min_zoom $min_zoom

    # Set up view menu
    $itk_component(viewmenu) delete 0 end
    $itk_component(viewmenu) add radiobutton \
	-variable [scope min_zoom] \
	-value [expr $min_zoom / 2] \
	-label "Too small" \
	-command [code $this resetViewerSizeLuke [expr $min_zoom / 2]] ;# was -Luke
    $itk_component(viewmenu) add radiobutton \
	-variable [scope min_zoom] \
	-value $min_zoom \
	-label "Just right" \
	-command [code $this resetViewerSizeLuke $min_zoom] ;# was -Luke
    $itk_component(viewmenu) add radiobutton \
	-variable [scope min_zoom] \
	-value [expr $min_zoom * 2] \
	-label "Too big" \
	-command [code $this resetViewerSizeLuke [expr $min_zoom * 2]] ;# was -Luke

    # Reset the image viewer size
    resetViewerSizeLuke ;# was minus the Luke

    # Set up canvas bindings for zooming and magnifying
    $itk_component(zoom_tool) invoke
    set current_cursor $::cursor::zoom
#    $itk_component(pointer) invoke
#    set current_cursor left_ptr
    #bind $itk_component(canvas) <ButtonPress-2> [code $this grabClick %x %y]
	# added by luke 13 November 2007
	# bug 87: middle mouse button reset view on mac whereas right mouse button does
	# the same job on all other platforms. It seems that button 2 is the right button 
	# on the mac whereas button 3 is the right button on linux and windows.
	# The same statement occurs one more time in this file
    if {[tk windowingsystem] == "aqua"} {
	bind $itk_component(canvas) <ButtonPress-2> [code $this resetViewerSizeLuke]
    } else {
	bind $itk_component(canvas) <ButtonPress-3> [code $this resetViewerSizeLuke]
#the above two lines used to be the only two calls to 'resetView' but I changed them to resetViewerSizeLuke OJ
    }

    # Setup info labels binding
    if {[tk windowingsystem] != "aqua"} {
	bind $itk_component(canvas) <Alt-Motion> [code $this startInfoLabelsScroll "Motion" %x %y]
	#bind $itk_component(canvas) <M2-Motion> [code $this startInfoLabels "Motion" %x %y]
	bind $itk_component(canvas) <Control-Motion> [code $this startInfoLabels "Motion" %x %y]
    } else {
	bind $itk_component(canvas) <Alt-Motion> [code $this startInfoLabelsScroll "Motion" %x %y]
	bind $itk_component(canvas) <M2-Motion> [code $this startInfoLabels "Motion" %x %y]
	#bind $itk_component(canvas) <M2-1> [code $this startInfoLabels "ButtonPress-1" %x %y]
    }
    # Activate spots button here ready for spot finding
    $itk_component(spots) invoke
    # Activate badspots button here ready for display
    $itk_component(badspots) invoke
    #$itk_component(toolsmenu) entryconfigure 0 -state normal
    #$itk_component(canvas) configure -cursor $::cursor::target

    # Put image on canvas
    $itk_component(canvas) create image 0 0 \
	-image $view_image -tags view_image -anchor nw 
    # added by luke on 12 November 2007
    # The line below forces the geometry of the window to be set to 
    # the dimensions that are calculated when the first image is fired up
    # Without this statement the window resizes to the max when the user
    # chooses to zoom in and I didn't like this behaviour
    wm geometry .image [winfo reqwidth .image]x[winfo reqheight .image]
    ###################################################################
    #puts "wm geometry [winfo reqwidth .image]x[winfo reqheight .image]"
}

body ImageDisplay::updateImage { new_image_data } {

    set image_object $next_image_object

    # update image combo
    $itk_component(image_combo) configure -state normal -editable 1
    # the following causes a blink on Mac especially
    $itk_component(image_combo) delete 0 end
    $itk_component(image_combo) insert 0 [$image_object getShortName]
    $itk_component(image_combo) configure -editable 0

    # Update image changing tools (number limits + arrows)
    updateImageArrows

    # Enable tools
    foreach i_toolbutton { spots spotfinding_settings resolution_limits info_labels spotfinding spotdeleting zoom_tool pointer fit_image contrast_button } {
	$itk_component($i_toolbutton) configure -state normal
    }

    # Update the window title to reflect its content
    foreach { l_phi_start l_phi_end } [$image_object getPhi] break
    wm title .image "Image [$image_object getNumber] (\u03c6:$l_phi_start-$l_phi_end) - $::env(IMOSFLM_VERSION)"

    set ::stopwatch2 [clock clicks -milli]
    # Called when jpeg received from server

    # Remove markers from the canvases too
    $itk_component(canvas) delete marker

    # Build an actual-size image of the whole detector from the jpeg
    $master_image put $new_image_data
    set ::timer003 [clock clicks -milli]

    if {!$image_has_been_opened} {
	#puts "First image detected"
	updateFirstImage
	set image_has_been_opened 1
	set ::first_view_update 1
    } else {
	# Update view (and magnifying) images 
	#puts "updateView from updateImage [$image_object getShortName]"
	updateView
	# Plot spotlist if available
	plotSpots
	# Any bad spots on this image?
	plotBadSpots
    }

    if {[info exists ::stopwatch3]} {
	set ::stopwatch4 [clock clicks -milli]
    }

    # Deiconfiy the window if it is withdrawn
    if {[wm state $itk_component(hull)] == "withdrawn"} {
	wm deiconify $itk_component(hull)
    }

    # enable image viewer
    enable

    # Wait a while for predictions to be plotted then try to find any hkl displayed in the entry boxes
    if { $hvariable != "" && $kvariable != "" && $lvariable != "" } {
	after 500 [eval code $this FindMyHKL]
    }

    .c enableIndexing
}


body ImageDisplay::resetViewerSizeLuke { { a_zoom ""} } {

    # This setting of the min_zoom from the passed argument was done in resetViewerSize
    # but not incorporated when replacing by resetViewerSizeLuke
    if {$a_zoom != ""} {
	set min_zoom $a_zoom
    }

    if { $zoom == $min_zoom } {
	# Check if we are already zoomed right out before drawing everything
	#return - but what if just got the first image in a New session?!
	# If the smooth level has been decreased through zooming, reset it by reloading the image

    }
    
    #set current_cursor_remember [$itk_component(canvas) cget -cursor]

    $itk_component(canvas) delete marker

    # Initialise position records, and previous position records for use in
    # marker positioning
    set left_x 1
    set top_y 1
    set old_left_x 1
    set old_top_y 1
    set right_x $detector_size_x
    set bottom_y $detector_size_y
    set zoom $min_zoom
    set old_zoom $zoom

    if { $a_zoom == "" } {
	# 'Fit image' button use to reset to min_zoom and default smooth level
	if { [$::mosflm getSmoothLevel] == 1 } {
	    #puts "resetViewerSizeLuke: Zoom $zoom, min $min_zoom smooth level 1 now [$::mosflm setSmoothLevel]"
	    if { [$::mosflm getSmoothLevel] == 5 } {
		recreateCurrentImage
	    }
	}
    }


    # Calculate desired canvas size (To fit image at 1:4 resolution)
    set display_size_x [expr $detector_size_x * $min_zoom]
    set display_size_y [expr $detector_size_y * $min_zoom]

    # Set the canvas size
    $itk_component(canvas) configure \
	-width $display_size_x \
	-height $display_size_y
    update

    set cnvsfrm_width [winfo width $itk_component(main)]
    set cnvsfrm_height [winfo height $itk_component(main)]	
    #puts "main width $cnvsfrm_width height $cnvsfrm_height"

    if {$display_size_x > $cnvsfrm_width} {
	set display_size_x $cnvsfrm_width
    }
	
    if {$display_size_y > $cnvsfrm_height} {
	set display_size_y $cnvsfrm_height
    }

    $itk_component(canvas) configure \
	-width $display_size_x \
	-height $display_size_y
    #puts "canvas width $display_size_x height $display_size_y"
    
    # Redisplay spots
    plotSpots

    # Redisplay bad spots
    plotBadSpots

    # Redisplay predictions
    redrawPredictions

    # Refresh view
    #puts "updateView called from resetViewerSizeLuke zoom $zoom"
    updateView ;# needed for [O] Fit image button

    $itk_component(canvas) configure \
	-scrollregion "0 0 $display_size_x $display_size_y" 

    #puts "zoom is $zoom - in then out"
    #zoomluke "in"
    #zoomluke "out"
    #plotSpots - why again?

    $itk_component(zoom_out_tool) configure -state "disabled"

    #$itk_component(canvas) configure -cursor $current_cursor_remember
    #set current_cursor $current_cursor_remember

}

body ImageDisplay::resizeWindow {} {

    $itk_component(canvas) delete marker

    set zoom $zoom
    set old_zoom $zoom

    # Calculate desired canvas size (To fit image at 1:4 resolution)
    set display_size_x [expr $detector_size_x * $zoom]
    set display_size_y [expr $detector_size_y * $zoom]

    # Set the canvas size
    $itk_component(canvas) configure \
	-width $display_size_x \
	-height $display_size_y
    update

    set cnvsfrm_width [winfo width $itk_component(main)]
    set cnvsfrm_height [winfo height $itk_component(main)]	
    #puts "main width $cnvsfrm_width height $cnvsfrm_height"

    if {$display_size_x > $cnvsfrm_width} {
	set display_size_x $cnvsfrm_width
    }
    
    if {$display_size_y > $cnvsfrm_height} {
	set display_size_y $cnvsfrm_height
    }

    $itk_component(canvas) configure \
	-width $display_size_x \
	-height $display_size_y
    #puts "canvas width $display_size_x height $display_size_y"

    $itk_component(canvas) configure \
	-scrollregion "0 0 $display_size_x $display_size_y"

# Why all this zooming in/out ?
#    if {$zoom < 64} {
#	puts "zoom is $zoom - in then out"
#	zoomluke "in"
#	zoomluke "out"
#    } else {
#	puts "zoom is $zoom - out then in"
#	zoomluke "out"
#	zoomluke "in"
#    }

    #puts "updateView from resizeWindow zoom $zoom"
    updateView
    plotSpots
    plotBadSpots
    redrawPredictions
}

##############################################################################
# Method to refresh the view in the viewer
##############################################################################

body ImageDisplay::updateView { { update_markers "1" } } {

    # Braced all expr in here 30 Jun 2011

    # hide magnifier, setting flag to indicate that it should be reshown at end
    if {[wm state $itk_component(magnifier)] == "normal"} {
	set mag_shown 1
	wm withdraw $itk_component(magnifier)
    } else {
	set mag_shown 0
    }
    
    # Remove zoom rectangle from the canvas
    $itk_component(canvas) delete zoom_box

    # Remove pick's raw data
    $itk_component(canvas) delete pick

    # Mag exp 18/10/04
    #$itk_component(mag_canvas) delete zoom_image

    # Increment right and bottom margins by 1, unless at limit
    if {$right_x < $detector_size_x} {
	set l_uber_right_x [expr {$right_x + 1}]
    } else {
	set l_uber_right_x $right_x
    }
    if {$bottom_y < $detector_size_y} {
	set l_uber_bottom_y [expr {$bottom_y + 1}]
    } else {
	set l_uber_bottom_y $bottom_y
    }

    # Trap if max coords larger than detector size
    if {$l_uber_right_x > $detector_size_x} {
	set l_uber_right_x $detector_size_x
    }
    if {$l_uber_bottom_y > $detector_size_y} {
	set l_uber_bottom_y $detector_size_y
    }

    # Create new image for main view
    if {($::tcl_platform(os) == "Linux") && ([$::session getParameterValue detector_manufacturer] == "ADSC") && ($::env(TKIMAGELOAD) == "1")} {
	set l_x1 $top_y
	set l_x2 $l_uber_bottom_y
	set l_y1 $left_x
	set l_y2 $l_uber_right_x
    } else {
	set l_x1 $left_x
	set l_x2 $l_uber_right_x
	set l_y1 $top_y
	set l_y2 $l_uber_bottom_y
    }

    # Trap if min coords less than 1,1
    if {$l_x1 < 1} {
	set l_x1 1
    }
    if {$l_y1 < 1} {
	set l_y1 1
    }

    #puts "Zoom:$zoom min-x,y: $l_x1 $l_y1 max-x,y: $l_x2 $l_y2"

    if {$zoom < 1} {
	$view_image copy $master_image \
	    -from $l_x1 $l_y1 $l_x2 $l_y2 \
	    -subsample [expr {int(1 / $zoom)}] [expr {int(1 / $zoom)}]
    } else {
	$view_image copy $master_image \
	    -from $l_x1 $l_y1 $l_x2 $l_y2 \
	    -zoom [expr {int($zoom)}]
    }
    if {($::tcl_platform(os) == "Linux") && ([$::session getParameterValue detector_manufacturer] == "ADSC") && ($::env(TKIMAGELOAD) == "1")} {
	imageTranspose $view_image
    }
    if {$::first_view_update} {
	set ::timer004 [clock clicks -milli]
	set ::first_view_update 0
    }

    # If at max zoom, send pick command
    if {$zoom == $max_zoom} {
	#puts "left_x $left_x top_y $top_y"
 	#$::mosflm pick $image_object [expr {$left_x + 6}] [expr {$top_y + 6}] 13 13
 	#puts "pick [expr {$left_x + 6}] [expr {$top_y + 6}] 13 13"
 	$::mosflm pick $image_object [expr {$left_x + 10}] [expr {$top_y + 10}] 21 21
    }

    # Repositions markers ####################

    if {$update_markers} {

	# Move markers back so their origin is at 0,0, so that scaling can be done
	# relative to 0,0.
	$itk_component(canvas) move marker [expr {($old_zoom * ($old_left_x - 1)) - ($old_zoom / 2) * ($old_zoom > 1)}] [expr {($old_zoom * ($old_top_y - 1)) - ($old_zoom / 2) * ($old_zoom > 1)}]
	
	# Scale markers to match current zoom
	$itk_component(canvas) scale marker 0 0 [expr {$zoom / $old_zoom}] [expr {$zoom / $old_zoom}]
	
	# Move spots to match current view position
	$itk_component(canvas) move marker [expr {(-$zoom * ($left_x - 1)) + ($zoom / 2) * ($zoom > 1)}] [expr {(-$zoom * ($top_y - 1)) + ($zoom / 2) * ($zoom > 1)}]
    }
    # #############

    # Raise spots to make them viewable, if their toolbutton is pushed in
    if {[$itk_component(spots) query]} {
	$itk_component(canvas) raise crosses view_image
    } else {
	$itk_component(canvas) lower crosses view_image
    }

    if {[$itk_component(predictions) query] == "active"} {
	$itk_component(canvas) raise predictions
    }

    # Replot any hkl requested
    plotHKL

    # Update overlays with new view information
    Marking::updateViewInformation $left_x $top_y $zoom $pixel_size $display_size_x $display_size_y $detector_size_x $detector_size_y

    # Plot beam if necessary
    if {[$itk_component(beam) query]} {
	Overlay::plotParameter beam_x
    } else {
	Overlay::clearParameter beam_x
    }

    # Plot backstop if necessary
    if {[$itk_component(backstop) query]} {
	#plotBackstop
    } else {
    }

    # Plot masks if necessary
    if {[$itk_component(masks) query]} {
	Overlay::plotParameter backstop_radius
	Overlay::plotParameter backstop_x
	Mask::plotAll
    } else {
	Overlay::clearParameter backstop_x
	Overlay::clearParameter backstop_radius
	Mask::clearAll
    }

    # Plot spot search boundaries if necessary
    if {[$itk_component(spotfinding_settings) query]} {
	Overlay::plotParameter search_area_min_radius
	Overlay::plotParameter search_area_max_radius
	Overlay::plotParameter bbox_orientation
    } else {
	Overlay::clearParameter search_area_min_radius
	Overlay::clearParameter search_area_max_radius
	Overlay::clearParameter bbox_orientation
    }

    # Plot resolution limits if necessary
    if {[$itk_component(resolution_limits) query]} {
	Overlay::plotParameter high_resolution_limit
	Overlay::plotParameter low_resolution_limit
    } else {
	Overlay::clearParameter high_resolution_limit
	Overlay::clearParameter low_resolution_limit
    }
   
    # Plot circlefitting if necessary
    if {[$itk_component(circle_fitting) query]} {
	CircleFit::replot
    }

    # Timing info
    if {[info exists ::stopwatch1]} {
	set ::stopwatch3 [clock clicks -milli]
    } else {
    }

    set t0 [clock clicks -milli]	

    # Display the magnification image in the magnifier canvas
    
    set mag_zoom [expr {int($zoom * 4)}]
    set zoom_factor [expr {$zoom / $old_zoom}]
    set mag_origin [$itk_component(mag_canvas) coords "origin"]
    if {[llength $mag_origin] == 2} {
	$itk_component(mag_canvas) scale marker [lindex $mag_origin 0] [lindex $mag_origin 1] $zoom_factor $zoom_factor
    }
    
    if {$mag_shown} {
	wm deiconify $itk_component(magnifier)
	#raise $itk_component(magnifier) .image
	raise $itk_component(magnifier)
    }

    #update
    
    # Fix zoom bindings and buttons #########################

    set old_zoom $zoom

    # zoom tool
    if {[$itk_component(zoom_tool) query]} {
	setupZoomToolBindings
    }

    # scroll zooming and toolbutton zooms
    if {$zoom < $max_zoom} {
	bind $itk_component(canvas) <ButtonPress-4> [code $this zoom "in" %x %y]
	bind $itk_component(canvas) <Control-ButtonPress-1> [code $this zoom "in" %x %y]
	$itk_component(zoom_in_tool) configure -state normal
    } else {
	bind $itk_component(canvas) <ButtonPress-4> {}
	bind $itk_component(canvas) <Control-ButtonPress-1> {}
	$itk_component(zoom_in_tool) configure -state disabled
    }
    if {$zoom > $min_zoom} {
	bind $itk_component(canvas) <ButtonPress-5> [code $this zoom "out" %x %y]
	bind $itk_component(canvas) <Shift-ButtonPress-1> [code $this zoom "out" %x %y]
	$itk_component(zoom_out_tool) configure -state normal
    } else {
	bind $itk_component(canvas) <ButtonPress-5> {}
	bind $itk_component(canvas) <Shift-ButtonPress-1> {}
	$itk_component(zoom_out_tool) configure -state disabled
    }
	# added by luke on 13 November 2007.
	# Bug 87. Reset view on mac is middle buttor whereas on other platforms it is the 
	# right mouse button
	# By trial and error I figured out that buttonpress-2 is the right button on the mac
	# so I had to include this if statement to check
	if {[tk windowingsystem] == "aqua"} {
	    bind $itk_component(canvas) <ButtonPress-2> [code $this resetViewerSizeLuke]
	} else {
	    bind $itk_component(canvas) <ButtonPress-3> [code $this resetViewerSizeLuke]
#The above line used to be bound to resetView but I changed it to resetViewerSizeLuke
	}
#    $itk_component(canvas) configure -cursor $current_cursor

}

##############################################################################
# Method to get the master pixel that contains a given canvas point
##############################################################################

body ImageDisplay::getMasterPixel { x y { a_multi "multi" } } {

    # Braced all expr in here 30 Jun 2011

    # Calculated as the distance, scaled by the zoom, from the top left pixel
    #  of the displayed image, plus the position of that top left pixel,
    #  remembering to increment initial values to move from the 0-indexed
    #  canvas to the 1-indexed image, and adding half the reciprocal of the zoom
    #  to account for when 1 pixel representes multiple master pixels.
    
    #      set x [expr $left_x + int( floor( (double([incr x])/$zoom) ) )]
    #      set y [expr $top_y + int( floor( (double([incr y])/$zoom) ) )]
    set old_x $x
    set old_y $y
    if {$a_multi == "multi"} {
	set x [expr {$left_x + int(floor((double($x+1)/$zoom) - (1.0 / ($zoom * 2))))}]
	set y [expr {$top_y + int(floor((double($y+1)/$zoom) - (1.0 / ($zoom * 2))))}]
    } else {
	set x [expr {$left_x + int(floor(double($x)/$zoom))}]
	set y [expr {$top_y + int(floor(double($y)/$zoom))}]
    }

    return [list $x $y]
}

##############################################################################
# Click zoom methods
##############################################################################

body ImageDisplay::zoom { in_or_out_or_zoom { x "" } { y "" } } {

    #puts "Calling zoom to zoom $in_or_out_or_zoom"
    set current_cursor_remember [$itk_component(canvas) cget -cursor]

    if {($x == "") || ($y == "")} {
	set x [expr {int($display_size_x / 2)}]
	set y [expr {int($display_size_y / 2)}]
    }

    # Calculate new zoom level
    if {$in_or_out_or_zoom == "in"} {
	set new_zoom [expr {$zoom * 2}]
    } elseif {$in_or_out_or_zoom == "out"} {
	set new_zoom [expr {$zoom * 0.5}]
    } else {
	set new_zoom $in_or_out_or_zoom
    }

    # Limit further zooming if at max (64x)
    if {$new_zoom >= $max_zoom} {
	set new_zoom $max_zoom
	# unbind the zoom
	bind $itk_component(canvas) <ButtonPress-4> {}
	# NB still need a binding (just one that does nothing)!
	bind $itk_component(canvas) <Control-ButtonPress-1> [code $this noZoom]
	$itk_component(zoom_in_tool) configure -state "disabled"
    } else {
	$itk_component(zoom_in_tool) configure -state "normal"
    }
    if {$new_zoom <= $min_zoom} {
	set new_zoom $min_zoom
	# unbind the zoom
	bind $itk_component(canvas) <ButtonPress-5> {}
	# NB still need a binding (just one that does nothing)!
	bind $itk_component(canvas) <Shift-ButtonPress-1> [code $this noZoom]
	$itk_component(zoom_out_tool) configure -state "disabled"
    } else {
	$itk_component(zoom_out_tool) configure -state "normal"
    }

    #Calculate the centre master pixel
    foreach { pix_c_x pix_c_y } [getMasterPixel [expr {int($display_size_x / 2)}] [expr {int($display_size_y / 2)}]] break

    #Calculate which master pixel was clicked on
    foreach { pix_x pix_y } [getMasterPixel $x $y] { }

    # Calculate new centre pixel
    set pix_x [expr {int($pix_x + (($pix_c_x - $pix_x) * (double($zoom) / $new_zoom)))}]
    set pix_y [expr {int($pix_y + (($pix_c_y - $pix_y) * (double($zoom) / $new_zoom)))}]

    #puts $display_size_x
    set display_size_x [winfo width $itk_component(main)]
    set display_size_y [winfo height $itk_component(main)]

    # Calculate number of pixels in new view
    set new_num_pix_x [expr {double($display_size_x) / $new_zoom}]
    set new_num_pix_y [expr {double($display_size_y) / $new_zoom}]

    # Calculate index of new top-left pixel
    set new_left_x [expr {$pix_x - round(double($new_num_pix_x-1)/2)}]
    set new_top_y [expr {$pix_y - round(double($new_num_pix_y-1)/2)}]

    # Calculate index of new bottom-right pixel
    set new_right_x [expr {$new_left_x + int(ceil($new_num_pix_x))}]
    set new_bottom_y [expr {$new_top_y + int(ceil($new_num_pix_y))}]

    # If the position of the new top-left pixel means the new zoom
    #  area extends outside the detector, change it accordingly
    if {$new_left_x < 1} {
	set new_left_x 1
	set new_right_x [expr {int(ceil($new_num_pix_x))}]
    } elseif {$new_right_x > $detector_size_x} {
	set new_right_x $detector_size_x
	set new_left_x [expr {$detector_size_x - int(ceil($new_num_pix_x)) + 1}]
    }
    if {$new_top_y < 1} {
	set new_top_y 1
	set new_bottom_y [expr {int(ceil($new_num_pix_y))}]
    } elseif {$new_bottom_y > $detector_size_y} {
	set new_bottom_y $detector_size_y
	set new_top_y [expr {$detector_size_y - int(ceil($new_num_pix_y)) + 1}]
    }
    zoomView $new_left_x $new_top_y $new_right_x $new_bottom_y $new_zoom ;# why not zVLuke?

    $itk_component(canvas) configure -cursor $current_cursor_remember
    set current_cursor $current_cursor_remember

}

body ImageDisplay::zoomView { x1 y1 x2 y2 new_zoom } {

    #puts "zoomView: cursor was    [file tail [lindex $current_cursor 0]]"
    set current_cursor [$itk_component(canvas) cget -cursor]
    #puts "zoomView: cursor set to [file tail [lindex $current_cursor 0]]"

    set zoom $new_zoom
    set num_zoom_clicks 0
    set old_left_x $left_x
    set old_top_y $top_y
    set left_x $x1
    set top_y $y1
    set right_x $x2
    set bottom_y $y2

    set smoothlvl [$::mosflm getSmoothLevel]
    #puts "resizeWindow from zoomView min: $min_zoom lvl: $zoom SmoothLevel $smoothlvl"

    # If zooming out on a Pilatus image smooth level should be reset to 5
    if { ($zoom == $min_zoom) && ($smoothlvl == 1) } {
	if { [$::mosflm setSmoothLevel] == 5 } {
	    recreateCurrentImage
	}
    }
    # If zooming in on a Pilatus image smooth level should be reset to 1
    if { ($zoom > $min_zoom) && ($smoothlvl == 5) } {
	if { [$::mosflm setSmoothLevel] == 1 } {
	    recreateCurrentImage
	}
    }
   
    resizeWindow

}

body ImageDisplay::zoomClick { a_x a_y } {
    storePreBindings "zoom"
    # Store coordinates of initial zoom click
    set zoom_click_x [getCoorx $a_x]
    set zoom_click_y [getCoory $a_y]
 
   # Create the zoom rectangles (clicked rectangle and prospective view)
    $itk_component(canvas) create rectangle \
	$zoom_click_x $zoom_click_y $zoom_click_x $zoom_click_y \
	-tags zoom_click_rectangle \
	-outline gold \
	-dash { 1 3 }
    $itk_component(canvas) create rectangle \
	$zoom_click_x $zoom_click_y $zoom_click_x $zoom_click_y \
	-tags zoom_view_rectangle \
	-outline gold
    # Setup bindings for drag and release    
    bind $itk_component(canvas) <Motion> [code $this zoomDrag %x %y]
    bind $itk_component(canvas) <ButtonRelease-1> [code $this zoomRelease %x %y]
}

body ImageDisplay::zoomDrag { a_x a_y } {
    $itk_component(canvas) coords zoom_click_rectangle \
	$zoom_click_x $zoom_click_y $a_x $a_y
    if {($a_x != $zoom_click_x) || ($a_y != $zoom_click_y)} {
	# Calculate max zoom that will fit select rectangle
	set l_width [expr $a_x - $zoom_click_x]
	set l_height [expr $a_y - $zoom_click_y]
	set l_centre_x [expr $zoom_click_x + ($l_width / 2)]
	set l_centre_y [expr $zoom_click_y + ($l_height / 2)]
	set l_max_dim [expr abs($l_width) > abs($l_height) ? $l_width : $l_height]
	set l_num_pix_to_show [expr abs($l_max_dim) / $zoom]
	if {$l_num_pix_to_show == 0} {
	    set l_num_pix_to_show 1
	}
	set l_min_display_dim [expr $display_size_x < $display_size_y ? $display_size_x : $display_size_y]
	set l_new_zoom [expr $l_min_display_dim / $l_num_pix_to_show]
	set l_old_new_zoom $l_new_zoom
	set l_new_zoom [expr pow(2,int(floor(log($l_new_zoom) / log(2))))]
	if {$l_new_zoom > $max_zoom} {
	    set l_new_zoom $max_zoom
	} elseif {$l_new_zoom < $min_zoom} {
	    set l_new_zoom $min_zoom
	}
	# Calculate draw size of new rectangle
	set l_real_width [expr int($display_size_x * ($zoom / $l_new_zoom))]
	set l_real_height [expr int($display_size_y * ($zoom / $l_new_zoom))]
	# Calculate new corner positions
	set l_new_x1 [expr $l_centre_x - ($l_real_width / 2)]
	set l_new_x2 [expr $l_new_x1 + $l_real_width - 1]
	set l_new_y1 [expr $l_centre_y - ($l_real_height / 2)]
	set l_new_y2 [expr $l_new_y1 + $l_real_height - 1]
	if {$l_new_x1 < 0} {
	    set l_new_x1 0
	    set l_new_x2 [expr $l_real_width - 1]
	} elseif {$l_new_x2 >= $display_size_x} {
	    set l_new_x2 [expr $display_size_x - 1]
	    set l_new_x1 [expr $display_size_x - $l_real_width]
	}
	if {$l_new_y1 < 0} {
	    set l_new_y1 0
	    set l_new_y2 [expr $l_real_height - 1]
	} elseif {$l_new_y2 >= $display_size_y} {
	    set l_new_y2 [expr $display_size_y - 1]
	    set l_new_y1 [expr $display_size_y - $l_real_height]
	}
	# Draw real view rectangle
	$itk_component(canvas) coords zoom_view_rectangle \
	    $l_new_x1 $l_new_y1 $l_new_x2 $l_new_y2
	# Return upper left corner and new zoom
	set l_return [eval list [getMasterPixel $l_new_x1 $l_new_y1 "not_multi"] $l_new_zoom]
	foreach { l_mpx l_mpy } $l_return break
	return $l_return 
    } else {
	return {}
    }
}

body ImageDisplay::zoomRelease { a_x a_y } {
    $itk_component(canvas) delete zoom_click_rectangle zoom_view_rectangle
    set l_zoom ""
    foreach { l_x1 l_y1 l_zoom } [zoomDrag $a_x $a_y] break
	if {$l_zoom != ""} {
	    set l_x2 [expr int(ceil($l_x1 + ($display_size_x / $l_zoom) - 1))]
	    set l_y2 [expr int(ceil($l_y1 + ($display_size_y / $l_zoom) - 1))]
	    if {$l_x2 > $detector_size_x} {
		set l_x1 [expr $l_x1 - ($l_x2 - $detector_size_x)]
		set l_x2 $detector_size_x
	    }
	    if {$l_y2 > $detector_size_y} {
		set l_y1 [expr $l_y1 - ($l_y2 - $detector_size_y)]
		set l_y2 $detector_size_y
	    }
	    zoomView $l_x1 $l_y1 $l_x2 $l_y2 $l_zoom ;# need to resize after release of dragged zoom
	}
    # Setup bindings for drag and release
    bind $itk_component(canvas) <Motion> {}
    bind $itk_component(canvas) <ButtonRelease-1> {}
    restorePreBindings "zoom"
}

body ImageDisplay::toggleSpots { state } {
    if {$state == "1"} {
	$itk_component(canvas) raise crosses view_image
	$itk_component(mag_canvas) raise crosses zoom_image
    } else {
	$itk_component(canvas) lower crosses view_image
	$itk_component(mag_canvas) lower crosses zoom_image
	$itk_component(spotfinding) cancel
	$itk_component(spotfinding) cancel
	$itk_component(spotdeleting) cancel
    }
}

body ImageDisplay::toggleBadSpots { state } {
   if {$state == "1"} {
	$itk_component(canvas) raise badspots
	$itk_component(mag_canvas) raise badspots
   } else {
	$itk_component(canvas) lower badspots
	$itk_component(mag_canvas) lower badspots
   }
}

body ImageDisplay::togglePredictions { state } {
   if {$state == "1"} {
	$itk_component(canvas) raise prediction
	$itk_component(mag_canvas) raise prediction
   } else {
	$itk_component(canvas) lower prediction
	$itk_component(mag_canvas) lower prediction
   }
}

body ImageDisplay::magnifyStart { a_type x y } {
    storePreBindings "magnify"
    if {$a_type == "ButtonPress-1"} {
	# Setup bindings to cancel magnification on non-shift motion or Leave
	bind $itk_component(canvas) <Motion> [code $this magnifyMove %x %y 13 13]
	bind $itk_component(canvas) <ButtonRelease-1> [code $this magnifyEnd] 
	bind $itk_component(canvas) <Leave> [code $this magnifyEnd] 
    } else {
	bind $itk_component(canvas) <Shift-Motion> [code $this magnifyMove %x %y 13 13]
	bind $itk_component(canvas) <Motion> [code $this magnifyEnd] 
	bind $itk_component(canvas) <Leave> [code $this magnifyEnd] 
    }
    # N.B. magnifyMove called twice, as single call inexplicably fails to work!
    magnifyMove $x $y 13 13
    magnifyMove $x $y 13 13
    # SHow magnifier window if necessary
    wm deiconify $itk_component(magnifier)
    raise $itk_component(magnifier)
    # Change cursor
    if {[tk windowingsystem] == "x11"} {
	$itk_component(canvas) configure -cursor $::cursor::box
	set current_cursor $::cursor::box
    } else {
	$itk_component(canvas) configure -cursor cross
	set current_cursor cross
    }	    
}

body ImageDisplay::magnifyMove { x y dx dy} {
    # Move magnifier position
    wm geometry $itk_component(magnifier) +[expr [winfo pointerx $itk_component(magnifier)] + $dx]\+[expr [winfo pointery $itk_component(magnifier)] + $dy]
    # raise $itk_component(magnifier) $itk_component(canvas)
    # raise $itk_component(magnifier)

    # Calculate image pixel mouse is over
    foreach { xi yi } [getMasterPixel $x $y] { }

    # Calculate area to be shown
    set left_border [expr int($xi - (10 / $zoom))]
    set top_border [expr int($yi - (10 / $zoom))]
    set right_border [expr  int($xi + (10 / $zoom) + 1)]
    set bottom_border [expr int($yi + (10 / $zoom) + 1)]

    if {($::tcl_platform(os) == "Linux") && ([$::session getParameterValue detector_manufacturer] == "ADSC") && ($::env(TKIMAGELOAD) == "1")} {
	set im_left_border [expr int($yi - (10 / $zoom))]
	set im_top_border [expr int($xi - (10 / $zoom))]
	set im_right_border [expr int($yi + (10 / $zoom) + 1)]
	set im_bottom_border [expr  int($xi + (10 / $zoom) + 1)]
    } else {
	set im_left_border [expr int($xi - (10 / $zoom))]
	set im_top_border [expr int($yi - (10 / $zoom))]
	set im_right_border [expr  int($xi + (10 / $zoom) + 1)]
	set im_bottom_border [expr int($yi + (10 / $zoom) + 1)]
    }

    if {$left_border < 0 || $top_border < 0 || $right_border > $detector_size_x || $bottom_border > $detector_size_y} {
	return
    }

    # Update zoom image to reflect new position
    if {($zoom * 4) >= 1} {
	$zoom_image copy $master_image \
	    -from $im_left_border $im_top_border $im_right_border $im_bottom_border \
	    -zoom [expr int($zoom * 4)]
    } else {
	$zoom_image copy $master_image \
	    -from $im_left_border $im_top_border $im_right_border $im_bottom_border \
	    -subsample [expr int(1 /($zoom*4))] [expr int(1 /($zoom*4))] 
    }

    # Transpose if necessary
    if {($::tcl_platform(os) == "Linux") && ([$::session getParameterValue detector_manufacturer] == "ADSC") && ($::env(TKIMAGELOAD) == "1")} {
	imageTranspose $zoom_image
    }

    # Move markers to new position
    foreach { origin_x origin_y } [$itk_component(mag_canvas) coords "origin"] { }
    # N.B. Shift of 1.5 added to make result match view image... :O
    $itk_component(mag_canvas) move marker [expr -$origin_x - (($left_border-1.5) * ($zoom * 4))] [expr -$origin_y - (($top_border-1.5) * ($zoom * 4))] 

}

body ImageDisplay::magnifyEnd { } {

    bind $itk_component(canvas) <Motion> {}
    bind $itk_component(canvas) <Shift-Motion> {}
    bind $itk_component(canvas) <ButtonRelease-1> {}
    bind $itk_component(canvas) <Leave> {}
    restorePreBindings "magnify"
    $itk_component(canvas) configure -cursor $::cursor::zoom
    wm withdraw $itk_component(magnifier)
}


body ImageDisplay::plotSpots { } {

    # Don't bother if there is no image
    if {$image_object == ""} {
	return
    }

    # Remove existing spots
    $itk_component(canvas) delete crosses
    $itk_component(mag_canvas) delete crosses

    # Get any spotlist associated with the current image
    set l_spotlist [$image_object getSpotlist]
    
    # If there is a spotlist...
    if {$l_spotlist != ""} {

	# plot spots on each canvas
	$l_spotlist plotSpots $i_sig_i $itk_component(canvas) $itk_component(mag_canvas)

	# position the spots
	positionMarkers crosses

	# Raise spots to make them viewable, if their toolbutton is pushed in
	if {[$itk_component(spots) query]} {
	    $itk_component(canvas) raise crosses view_image
	} else {
	    $itk_component(canvas) lower crosses view_image
	}
    }    
}

body ImageDisplay::positionMarkers { a_tag } {

    # Braced all expr in here 30 Jun 2011 & calculate mag_zoom once only

    # position spots plotted in their 1:1 pixel location to match current zoom and view position 

    # Scale crosses to match current zoom
    $itk_component(canvas) scale $a_tag 0 0 $zoom $zoom

    set mag_zoom [expr {$zoom * 4}]
    $itk_component(mag_canvas) scale $a_tag 0 0 $mag_zoom $mag_zoom
	
    # Move spots on view canvas to match current view position
    $itk_component(canvas) move $a_tag [expr {(-$zoom * ($left_x - 1)) + ($zoom / 2) * ($zoom > 1)}] [expr {(-$zoom * ($top_y - 1)) + ($zoom / 2) * ($zoom > 1)}]

    # Move spots on mag canvas to match current origin
    eval $itk_component(mag_canvas) move $a_tag  [$itk_component(mag_canvas) coords "origin"]
}

body ImageDisplay::parseBackstop { a_dom } {

    set message ""
    set message [$a_dom selectNodes string(/backstop_response/message)]
    if { $message != "" } {
	.m confirm \
	    -type "1button" -title "ImageDisplay::parseBackstop" -button1of1 "OK" \
	    -text "Message: $message"
	return
    } else {
	set back_x [$a_dom selectNodes normalize-space(/backstop_response/circle_centre_x)]
	if { $back_x != "" } {
	    set back_y [$a_dom selectNodes normalize-space(/backstop_response/circle_centre_y)]
	    set back_r [$a_dom selectNodes normalize-space(/backstop_response/radius)]
	    #puts "Before: [$::session getBackstopCommand]"
	    $::session updateSetting backstop_x $back_x 1 1 "User" 0
	    $::session updateSetting backstop_y $back_y 1 1 "User" 0
	    $::session updateSetting backstop_radius $back_r 1 1 "User"
	    #puts "After : [$::session getBackstopCommand]"
	} else {
	    set x1 [$a_dom selectNodes normalize-space(/backstop_response/quadrilateral_x_1)]
	    if { $x1 != "" } {
		set y1 [$a_dom selectNodes normalize-space(/backstop_response/quadrilateral_y_1)]
		set x2 [$a_dom selectNodes normalize-space(/backstop_response/quadrilateral_x_2)]
		set y2 [$a_dom selectNodes normalize-space(/backstop_response/quadrilateral_y_2)]
		set x3 [$a_dom selectNodes normalize-space(/backstop_response/quadrilateral_x_3)]
		set y3 [$a_dom selectNodes normalize-space(/backstop_response/quadrilateral_y_3)]
		set x4 [$a_dom selectNodes normalize-space(/backstop_response/quadrilateral_x_4)]
		set y4 [$a_dom selectNodes normalize-space(/backstop_response/quadrilateral_y_4)]
		#puts "$x1 $y1 $x2 $y2 $x3 $y3 $x4 $y4"
		Mask::BackstopMask $x1 $y1 $x2 $y2 $x3 $y3 $x4 $y4
	    } else {
		# what other types of backstop_response are there ...
	    }
	}
    }
}

body ImageDisplay::parseHistogram { a_dom } {

    # Read the intensity histogram and contrast info
    $itk_component(contrast_palette) updateHistogram \
	[$a_dom selectNodes string(//pixel_intensities)]

    # Set the flag to indicate that there's an image displayed
    set image_is_open "1"

}

#########################################################
#########################################################
# Functions for interactively setting spot finding params
#########################################################
#########################################################

body ImageDisplay::query { var } {
    return [set $var]
}

################################################################################
################################################################################
################################################################################

body ImageDisplay::updateSetting { a_parameter a_value } {
    set $a_parameter $a_value
    if {[$itk_component(backstop) query]} {
	#plotBackstop
    }
    if {[$itk_component(spotfinding_settings) query]} {
	#plotSpotSearchSettings
	#Overlay::plotParameter search_area_min_radius
    }
    if {[$itk_component(resolution_limits) query]} {
	#plotResolutionLimits
    }
    
    #Overlay::updateParameter $a_parameter $a_value

}

body ImageDisplay::toggleSpotfindingParameters { state } {
   if {$state == "1"} {
       if {[$::session forceBeamSetting]} {
	   Overlay::plotParameter search_area_min_radius
	   Overlay::plotParameter search_area_max_radius
	   Overlay::plotParameter bbox_orientation

       } else {
	   $itk_component(spotfinding_settings) cancel
       }
   } else {
       Overlay::clearParameter search_area_min_radius
       Overlay::clearParameter search_area_max_radius
       Overlay::clearParameter bbox_orientation
   }
}

body ImageDisplay::toggleBeam { state } {
#	puts "Show beam state is $state"
   if {$state == "1"} {
       if {[$::session forceBeamSetting]} {
	   Overlay::plotParameter beam_x
       } else {
	   $itk_component(beam) cancel
       }
   } else {
       Overlay::clearParameter beam_x
   }
}

body ImageDisplay::toggleMasks { state } {
   if {$state == "1"} {
       if {[$::session forceBeamSetting]} {
	   Overlay::plotParameter backstop_radius
	   Overlay::plotParameter backstop_x
	   Mask::plotAll
	   #plotBackstop
       } else {
	   $itk_component(backstop) cancel
       }
   } else {
       Overlay::clearParameter backstop_x
       Overlay::clearParameter backstop_radius
       Mask::clearAll
   }
}

body ImageDisplay::toggleResolutionLimits { state } {
   if {$state == "1"} {
       if {[$::session forceBeamSetting]} {
	   Overlay::plotParameter high_resolution_limit
	   Overlay::plotParameter low_resolution_limit
       } else {
	   $itk_component(resolution_limits) cancel
       }
   } else {
       Overlay::clearParameter high_resolution_limit
       Overlay::clearParameter low_resolution_limit
   }
}

body ImageDisplay::toggleActiveMask { state } {
    set detector_model [$::session getParameterValue detector_model]
    #puts $detector_model
    set rigakus {JUPITER SATURN MERCURY A200}
    if { [lsearch $rigakus $detector_model] >= 0 } {
	#puts "$detector_model found in Rigaku list $rigakus"
	set image_object [.image getImage]
	set l_directory [$image_object getDirectory]
	set l_template [$image_object getTemplate]
	set l_image_number [$image_object getNumber]
	$::mosflm sendCommand "directory $l_directory"
	$::mosflm sendCommand "template $l_template"
	$::mosflm sendCommand "image $l_image_number"
	if {$state == "1"} {
	    set hide_active_mask 1
	    $::mosflm sendCommand "noactive"
	} else {
	    set hide_active_mask 0
	    $::mosflm sendCommand "active"
	}
	$::mosflm sendCommand "xgui on"
	$::mosflm sendCommand "go"
	$::mosflm sendCommand "create_grey_image 0 0 smooth [$::mosflm setSmoothLevel]"
	$::mosflm sendCommand "return"
	# re-display predictions
	if {[$::session predictionPossible]} {
	    getPredictions
	}
    } else {
	#puts "$detector_model not in Rigaku list $rigakus"
    }
}

body ImageDisplay::toggleInfoLabels { state } {
   if {$state == "1"} {
       if {[$::session forceBeamSetting]} {
	   set show_info_labels 1
       } else {
	   set show_info_labels 0
	   $itk_component(info_labels) cancel noexecute
       }
   } else {
       set show_info_labels 0
   }
}

body ImageDisplay::plotBeam { { a_colour "green" } } {
    $itk_component(canvas) delete beam
    foreach {xc_p yc_p} [getCurrentViewCentrePixel "beam"] break
    $itk_component(canvas) create image $xc_p $yc_p \
	-image ::img::beam_${a_colour}7x7 \
	-tags [list beam_param clickable_spotfinding_param beam]
}

body ImageDisplay::plotBackstop { } {
    plotBackstopRadius green
    plotBackstopCentre green
}

body ImageDisplay::plotSpotSearchSettings { } {

    plotMinSearchRadius red
    plotMaxSearchRadius red
    plotExclusionSegment "vertical" red
    plotExclusionSegment "horizontal" red
    #plotBackgroundBox red
}

body ImageDisplay::plotResolutionLimits { } {
    if {($high_resolution_limit != "") && ([string is double $high_resolution_limit])} {
	plotHighResolutionLimit blue
    } else {
	$itk_component(canvas) delete high_resolution_limit
    }
    if {($low_resolution_limit != "") && ([string is double $low_resolution_limit])} {
	plotLowResolutionLimit blue
    } else {
	$itk_component(canvas) delete low_resolution_limit
    }
}

body ImageDisplay::plotBackstopRadius { a_colour { a_fill "" } } {
    if {$a_fill == ""} {
	set a_fill $a_colour
    }
    $itk_component(canvas) delete backstop_radius
    plotCircle "backstop" $backstop_radius \
	-stipple @[file join $::env(MOSFLM_GUI) bitmaps stipple2.xbm] \
	-outline $a_colour \
	-fill $a_fill \
	-tags [list backstop_param backstop_radius backstop_radius_stipple]
    plotCircle "backstop" $backstop_radius \
	-outline $a_colour \
	-tags [list backstop_param clickable_spotfinding_param backstop_radius backstop_radius_ring]
    $itk_component(canvas) raise backstop_centre
}

body ImageDisplay::plotBackstopCentre { a_colour } {
    $itk_component(canvas) delete backstop_centre
    foreach {xc_p yc_p} [getCurrentViewCentrePixel "backstop"] break
    $itk_component(canvas) create image $xc_p $yc_p \
	-image ::img::backstop_centre_${a_colour}7x7 \
	-tags [list backstop_param clickable_spotfinding_param backstop_centre]
}

body ImageDisplay::plotMaxSearchRadius { a_colour { a_fill "" } } {
    if {$a_fill == ""} {
	set a_fill $a_colour
    }
    $itk_component(canvas) delete search_area_max_radius
    stippleOut $search_area_max_radius 1 \
	-stipple @[file join $::env(MOSFLM_GUI) bitmaps stipple1.xbm] \
	-fill $a_fill \
	-tags [list spotfinding_param search_area_max_radius search_area_max_radius_stipple]
    plotCircle "beam" $search_area_max_radius \
	-outline $a_colour \
	-tags [list spotfinding_param clickable_spotfinding_param search_area_max_radius search_area_max_radius_ring]
}

body ImageDisplay::plotMinSearchRadius { a_colour { a_fill "" } } {
    if {$a_fill == ""} {
	set a_fill $a_colour
    }
    $itk_component(canvas) delete search_area_min_radius
    plotCircle "beam" $search_area_min_radius \
	-stipple @[file join $::env(MOSFLM_GUI) bitmaps stipple2.xbm] \
	-outline $a_colour \
	-fill $a_fill \
	-tags [list spotfinding_param search_area_min_radius search_area_min_radius_stipple]
    plotCircle "beam" $search_area_min_radius \
	-outline $a_colour \
	-tags [list spotfinding_param clickable_spotfinding_param search_area_min_radius search_area_min_radius_ring]
}

body ImageDisplay::plotExclusionSegment { a_direction a_colour { a_fill "" } } {
    if {$a_fill == ""} {
	set a_fill $a_colour
    }
    $itk_component(canvas) delete ${a_direction}_exclusion
    set l_width [set exclusion_segment_${a_direction}]
    if {$l_width < 0.00000001} {
	set l_dash { 1 9 1 9 }
    } else {
	set l_dash { 1 }
	plotExclusion $a_direction $l_width \
	    -stipple @[file join $::env(MOSFLM_GUI) bitmaps stipple1.xbm] \
	    -fill $a_fill \
	    -tags [list spotfinding_param ${a_direction}_exclusion ${a_direction}_exclusion_stipple] \
	    -outline {}
    }
    plotExclusion $a_direction $l_width \
	-dash $l_dash \
	-outline $a_colour \
	-tags [list spotfinding_param clickable_spotfinding_param ${a_direction}_exclusion ${a_direction}_exclusion_ring]
}
  
body ImageDisplay::plotHighResolutionLimit { a_colour { a_fill "" } } {
    if {$a_fill == ""} {
	set a_fill $a_colour
    }

    # Calculate radius
    set high_resolution_radius [expr $distance * tan(2 * asin($wavelength / (2 * $high_resolution_limit)))]

    $itk_component(canvas) delete high_resolution_limit
    stippleOut $high_resolution_radius 1 \
	-stipple @[file join $::env(MOSFLM_GUI) bitmaps stipple2.xbm] \
	-fill $a_fill \
	-tags [list resolution_limit high_resolution_limit high_resolution_limit_stipple]
    plotCircle "beam" $high_resolution_radius \
	-outline $a_colour \
	-tags [list resolution_limit clickable_spotfinding_param high_resolution_limit high_resolution_limit_ring]
}

body ImageDisplay::plotLowResolutionLimit { a_colour { a_fill "" } } {
    if {$a_fill == ""} {
	set a_fill $a_colour
    }
    # Calculate radius
    set low_resolution_radius [expr $distance * tan(2 * asin($wavelength / (2 * $low_resolution_limit)))]

    $itk_component(canvas) delete low_resolution_limit
    plotCircle "beam" $low_resolution_radius \
	-stipple @[file join $::env(MOSFLM_GUI) bitmaps stipple1.xbm] \
	-outline $a_colour \
	-fill $a_fill \
	-tags [list resolution_limit low_resolution_limit low_resolution_limit_stipple]
    plotCircle "beam" $low_resolution_radius \
	-outline $a_colour \
	-tags [list resolution_limit clickable_spotfinding_param low_resolution_limit low_resolution_limit_ring]
}

body ImageDisplay::plotCircle { a_item a_radius args } {
    foreach {xc_p yc_p} [getCurrentViewCentrePixel "$a_item"] break
    set radius_p [expr ($a_radius / $pixel_size) * $zoom]
    set x1 [expr $xc_p - $radius_p]
    set y1 [expr $yc_p - $radius_p]
    set x2 [expr $xc_p + $radius_p]
    set y2 [expr $yc_p + $radius_p]
    eval $itk_component(canvas) create oval $x1 $y1 $x2 $y2 $args
}

body ImageDisplay::plotExclusion { a_direction a_width args } {
    foreach {xc_p yc_p} [getCurrentViewCentrePixel "beam"] break
    if {$a_direction == "horizontal"} {
	set x1 -1
	set y1 [expr $yc_p - ((double($a_width) / $pixel_size) * $zoom)]
	set x2 [expr $display_size_x + 1]
	set y2 [expr $yc_p + ((double($a_width) / $pixel_size) * $zoom)]
    } elseif {$a_direction == "vertical"} {
	set x1 [expr $xc_p - ((double($a_width) / $pixel_size) * $zoom)]
	set y1 -1
	set x2 [expr $xc_p + ((double($a_width) / $pixel_size) * $zoom)]
	set y2 [expr $display_size_y + 1]
    }
    eval $itk_component(canvas) create rectangle $x1 $y1 $x2 $y2 $args
}

body ImageDisplay::stippleOutSly { a_radius args } {

    after cancel $stipple_queue

    eval stippleOut [expr $a_radius + 1] 20 $args

    set stipple_queue [after 66 [eval code $this stippleOut $a_radius 1 $args]]
}

body ImageDisplay::stippleOut { a_radius a_step args } {

    #$itk_component(canvas) delete search_area_max_radius_stipple

    foreach {x0 y0} [getCurrentViewCentrePixel "beam"] break
    set r [expr ($a_radius / $pixel_size) * $zoom]
    set coords {}
    set ix [expr $x0 - $r]
    if {$ix < 0} {
	set ix 0
    }
    while {($ix < ($x0 + $r)) && ($ix <= $display_size_y)} {
	set t_side_squared [expr pow($r,2)-pow($ix-$x0,2)]
	if {$t_side_squared < 0} {
	    set t_side_squared 0
	}
	set iy_p [expr $y0 + sqrt($t_side_squared)]
	set iy_n [expr $y0 - sqrt($t_side_squared)]
	if {$iy_p < 0 } {
	    set iy_p 0 
	} elseif {$iy_p > $display_size_y } {
	    set iy_p $display_size_y
	}
	if {$iy_n < 0 } {
	    set iy_n 0
	} elseif {$iy_n > $display_size_y } {
	    set iy_n $display_size_y
	}
	set coords [linsert $coords 0 $ix]
	set coords [linsert $coords 1 $iy_p]
	set coords [linsert $coords end $ix]
	set coords [linsert $coords end $iy_n]
	set ix [expr $ix + $a_step]
    }

    lappend coords [expr $x0 + $r] 
    lappend coords $y0
    lappend coords $display_size_x 
    lappend coords $y0
    lappend coords $display_size_x
    lappend coords 0
    lappend coords 0
    lappend coords 0
    lappend coords 0
    lappend coords $display_size_y
    lappend coords $display_size_x
    lappend coords $display_size_y
    lappend coords $display_size_x
    lappend coords $y0
    lappend coords [expr $x0 + $r] 
    lappend coords $y0

    eval $itk_component(canvas) create polygon $coords $args
}

body ImageDisplay::getCurrentViewCentrePixel { a_item } {
    set t_x [expr ((([set ${a_item}_x] / $pixel_size) - $left_x) * $zoom) + ($zoom / 2)] 
    set t_y [expr ((([set ${a_item}_y] / $pixel_size) - $top_y) * $zoom) + ($zoom / 2)]
    return [list $t_x $t_y]
}
# Interactions #####################################

body ImageDisplay::editSpotSearchParameterStart { a_x a_y } {
    # Do what???
}

body ImageDisplay::editSpotSearchParameterEnd { a_x a_y } {
    # Do what???
    wm withdraw $itk_component(data_labels)
}

body ImageDisplay::showInfoLabelsScroll { a_x a_y} {
	set scrolledx [getCoorx $a_x]
	set scrolledy [getCoory $a_y]
	showInfoLabels $scrolledx $scrolledy
}

body ImageDisplay::showInfoLabels { a_x a_y } {
    # Show resoluion info 
    set l_coords_mm [Marking::c2mCoords [list $a_x $a_y]]
    foreach { l_x_mm l_y_mm} $l_coords_mm { }
    set l_resolution [$::session calcResolution $l_coords_mm]
    if {$l_resolution == "infinity"} {
	set l_resolution "\u221e"
    }
    foreach { pix_x pix_y } [getMasterPixel $a_x $a_y] { }
    $itk_component(data_label_1) configure \
	-text "Resolution: $l_resolution x,y(mm): [format %.2f $l_x_mm],[format %.2f $l_y_mm] (pixels): $pix_x,$pix_y" \
	-fg black \
	-bg white \
	-anchor w
    # Show info for any markers
    set i_label 2
    # Loop through overlapping items- add a small tolerance for when the 
# image is zoomed right out.
    foreach i_item [$itk_component(canvas) find overlapping [expr $a_x - 1] [expr $a_y - 1] [expr $a_x + 1] [expr $a_y + 1]] {
	set l_info_found 0
	# Search for an info class tag, and extract class
	foreach i_tag [$itk_component(canvas) gettags $i_item] {
	    if {[regexp {info_class\((.*)\)} $i_tag l_match l_class]} {
		if {$l_class == "spot"} {
		    if {[$itk_component(spots) query]} {
			set l_info_found 1
		    }
		} elseif {$l_class == "prediction"} {
		    if {[$itk_component(predictions) query]} {
			set l_info_found 1
		    }
		} elseif {$l_class == "badspot"} {
		    if {[$itk_component(badspots) query]} {
			set l_info_found 1
		    }
		}
	    }
	}
	if {$l_info_found} {
	    # Search for an info label tag, and extract label
	    foreach i_tag [$itk_component(canvas) gettags $i_item] {
		if {[regexp {info_label\((.*)\)} $i_tag l_match l_label]} {
		    set l_info_label $l_label
		}
	    }
	    # Search for a info colour tag, and extract colour
	    foreach i_tag [$itk_component(canvas) gettags $i_item] {
		if {[regexp {info_colour\((.*)\)} $i_tag l_match l_colour]} {
		    set l_info_colour $l_colour
		}
	    }
	    # Search for a fg colour tag, and extract colour
	    set l_fg_colour black
	    foreach i_tag [$itk_component(canvas) gettags $i_item] {
		#puts "Tag: $i_tag"
		if {[regexp {info_alt_colour\((.*)\)} $i_tag l_match l_colour]} {
		    set l_fg_colour $l_colour
		}
	    }
	    $itk_component(data_label_$i_label) configure \
		-text "$l_info_label" \
		-fg $l_fg_colour \
		-bg $l_info_colour \
		-anchor w
	    pack $itk_component(data_label_$i_label) -fill x
	    incr i_label
	    #puts "$l_info_label $l_fg_colour $l_info_colour"
	}
    }
    # Remove unused labels
    while {$i_label <= 5} {
	pack forget $itk_component(data_label_$i_label)
	incr i_label
    }
    # Show labels by cursor
# must withdraw it first because of bugs with some window managers
    wm withdraw $itk_component(data_labels)
#this is the right one for the labels by the cursor
    set jabberwockx [expr [winfo pointerx $itk_component(canvas)] + 20]
    set jabberwocky [expr [winfo pointery $itk_component(canvas)] + 20]
    wm geometry $itk_component(data_labels) \+$jabberwockx\+$jabberwocky 
    wm deiconify $itk_component(data_labels)
    raise $itk_component(data_labels)
}

body ImageDisplay::editSpotSearchParameterMove { a_x a_y } {
    # Get 'normal colour' for current spot search parameter
    #  (so it can be reset if it's no longer the current one)
    if {[regexp {resolution} $current_spot_search_parameter]} {
	set l_normal_colour blue
    } elseif {[regexp {backstop} $current_spot_search_parameter]} {
	set l_normal_colour green
    } elseif {[string match mask_polygon(*) $current_spot_search_parameter]} {
	set l_normal_colour green
    } else {
	set l_normal_colour red
    }
    # Get closest clickable marker if there is one
    set l_marker [findClosestNearItem $a_x $a_y clickable_spotfinding_param]
    # If there was one...
    if {$l_marker != ""} {
	wm withdraw $itk_component(data_labels)
	# Work out which one it is
	set l_tags [$itk_component(canvas) gettags $l_marker]
	if {[lsearch $l_tags beam] != -1} {
	    set new_spot_search_parameter beam
	} elseif {[lsearch $l_tags backstop_centre] != -1} {
	    set new_spot_search_parameter backstop_centre
	} elseif {[lsearch $l_tags backstop_radius] != -1} {
	    set new_spot_search_parameter backstop_radius
	} elseif {[lsearch $l_tags search_area_max_radius] != -1} {
	    set new_spot_search_parameter search_area_max_radius
	} elseif {[lsearch $l_tags search_area_min_radius] != -1} {
	    set new_spot_search_parameter search_area_min_radius
	} elseif {[lsearch $l_tags vertical_exclusion] != -1} {
	    set new_spot_search_parameter vertical_exclusion
	} elseif {[lsearch $l_tags horizontal_exclusion] != -1} {
	    set new_spot_search_parameter horizontal_exclusion
	} elseif {[lsearch $l_tags high_resolution_limit] != -1} {
	    set new_spot_search_parameter high_resolution_limit
	} elseif {[lsearch $l_tags low_resolution_limit] != -1} {
	    set new_spot_search_parameter low_resolution_limit
	} elseif {[lsearch -glob $l_tags mask_polygon(*)] != -1} {
	    set new_spot_search_parameter [lsearch -inline -glob $l_tags mask_polygon(*)]
	} else {
	    error "Haven't implemented edits of this marker yet!"
	}
	# If it's changed
	if {$new_spot_search_parameter != $current_spot_search_parameter} {
	    # Restore old parameter marker image or colour
	    if {$current_spot_search_parameter == "beam"} {
		$itk_component(canvas) itemconfigure beam \
		    -image ::img::beam_green7x7
	    } elseif {$current_spot_search_parameter == "backstop_centre"} {
		$itk_component(canvas) itemconfigure backstop_centre \
		    -image ::img::backstop_centre_green7x7
	    } else {
		$itk_component(canvas) itemconfigure ${current_spot_search_parameter}_ring \
		    -outline $l_normal_colour
	    }
	    # Colour in active clickable marker (with new image or colour)
	    set l_active_colour gold 
	    if {$new_spot_search_parameter == "beam"} {
		$itk_component(canvas) itemconfigure beam \
		    -image ::img::beam_gold7x7
	    } elseif {$new_spot_search_parameter == "backstop_centre"} {
		$itk_component(canvas) itemconfigure backstop_centre \
		    -image ::img::backstop_centre_gold7x7
	    } elseif {[string match mask_polygon(*) $new_spot_search_parameter]} {
		$itk_component(canvas) itemconfigure $new_spot_search_parameter \
		    -outline $l_active_colour \
		    -fill $l_active_colour 
	    } else {
		$itk_component(canvas) itemconfigure ${new_spot_search_parameter}_ring \
		    -outline $l_active_colour
	    }
	    # update record of current marker
	    set current_spot_search_parameter $new_spot_search_parameter
	}
    } else {
	# Un-colour last current marker, and clear record of current marker
	$itk_component(canvas) itemconfigure ${current_spot_search_parameter}_ring \
	    -outline $l_normal_colour
	$itk_component(canvas) itemconfigure backstop_centre \
		-image ::img::backstop_centre_green7x7
	$itk_component(canvas) itemconfigure beam \
		-image ::img::beam_green7x7
	if {[string match mask_polygon(*) $current_spot_search_parameter]} {
	    $itk_component(canvas) itemconfigure $current_spot_search_parameter \
		-outline $l_normal_colour \
		-fill $l_normal_colour 
	}
	set current_spot_search_parameter ""

	# Show info labels if necessary
	if {$show_info_labels} {
	    set l_info_labels ""
	    # Show resoluion info 
	    foreach {beam_x_p beam_y_p} [getCurrentViewCentrePixel "beam"] break
	    set radius_p [expr sqrt(pow($a_x - $beam_x_p,2)+pow($a_y - $beam_y_p,2))]
	    set radius_mm [expr ($radius_p / $zoom) * $pixel_size]
	    if {[catch {set l_resolution [format %.2f [expr $wavelength / (2 * sin(0.5 * atan($radius_mm / $distance)))]]}]} {
		set l_resolution "\u221e"
	    }

	    $itk_component(data_label_1) configure \
		-text "Resolution: $l_resolution" \
		-fg black \
		-bg white \
		-anchor w
	    # Show info for any markers
	    set i_label 2
	    # Loop through overlaping items
	    foreach i_item [$itk_component(canvas) find overlapping [expr $a_x - 1] [expr $a_y - 1] [expr $a_x + 1] [expr $a_y + 1]] {

		set l_info_found 0
		# Search for an info class tag, and extract class
		foreach i_tag [$itk_component(canvas) gettags $i_item] {
		    if {[regexp {info_class\((.*)\)} $i_tag l_match l_class]} {
			if {$l_class == "spot"} {
			    if {[$itk_component(spots) query]} {
				set l_info_found 1
			    }
			} elseif {$l_class == "prediction"} {
			    if {[$itk_component(predictions) query]} {
				set l_info_found 1
			    }
			}			    
		    }
		}
		if {$l_info_found} {
		    # Search for an info label tag, and extract label
		    foreach i_tag [$itk_component(canvas) gettags $i_item] {
			if {[regexp {info_label\((.*)\)} $i_tag l_match l_label]} {
			    set l_info_label $l_label
			}
		    }
		    # Search for a info colour tag, and extract colout
		    foreach i_tag [$itk_component(canvas) gettags $i_item] {
			if {[regexp {info_colour\((.*)\)} $i_tag l_match l_colour]} {
			    set l_info_colour $l_colour
			}
		    }
		    # Search for a fg colour tag, and extract colout
		    set l_fg_colour black
		    foreach i_tag [$itk_component(canvas) gettags $i_item] {
			if {[regexp {info_alt_colour\((.*)\)} $i_tag l_match l_colour]} {
			    set l_fg_colour $l_colour
			}
		    }
		    $itk_component(data_label_$i_label) configure \
			-text "$l_info_label" \
			-fg $l_fg_colour \
			-bg $l_info_colour \
			-anchor w
		    pack $itk_component(data_label_$i_label) -fill x
		    incr i_label
		}
	    }
	    # Remove unused labels
	    while {$i_label <= 5} {
		pack forget $itk_component(data_label_$i_label)
		incr i_label
	    }
	    # Show labels by cursor
	    wm deiconify $itk_component(data_labels)
	    raise $itk_component(data_labels)
	    wm geometry $itk_component(data_labels) +[expr [winfo pointerx $itk_component(data_labels)] + 20]\+[expr [winfo pointery $itk_component(data_labels)] + 20]
	}
    }
}

body ImageDisplay::editSpotSearchParameterClick { a_x a_y } {
    # work out if click was "negative" or "positive" for exclusion segments
    foreach {beam_x_p beam_y_p} [getCurrentViewCentrePixel "beam"] break
    if {$a_x < $beam_x_p} {
	set old_vertical_exclusion -1
    } else {
	set old_vertical_exclusion 1
    }
    if {$a_y < $beam_y_p} {
	set old_horizontal_exclusion -1
    } else {
	set old_horizontal_exclusion 1
    }

    # If parameter was clicked on, set up bindings to drag it
    if {$current_spot_search_parameter != ""} {
	bind $itk_component(canvas) <Motion> [code $this editSpotSearchParameterDrag %x %y]
	editSpotSearchParameterDrag $a_x $a_y
    } else {
	# otherwise it must be a zoom click!
	zoomClick $a_x $a_y
    }
}

body ImageDisplay::editSpotSearchParameterDrag { a_x a_y } {
    foreach {beam_x_p beam_y_p} [getCurrentViewCentrePixel "beam"] break
    if {$current_spot_search_parameter == "beam"} {
	foreach {l_master_x l_master_y } [getMasterPixel $a_x $a_y] break
	set beam_x [format %.2f [expr $l_master_x * $pixel_size]]
	set beam_y [format %.2f [expr $l_master_y * $pixel_size]]
	$itk_component(beam_x_e) setValue $beam_x
	$itk_component(beam_y_e) setValue $beam_y
	plotBeam gold
    } elseif {$current_spot_search_parameter == "backstop_centre"} {
	foreach {l_master_x l_master_y } [getMasterPixel $a_x $a_y] break
	set backstop_x [format %.2f [expr $l_master_x * $pixel_size]]
	set backstop_y [format %.2f [expr $l_master_y * $pixel_size]]
	$itk_component(backstop_x_e) setValue $backstop_x
	$itk_component(backstop_y_e) setValue $backstop_y
	plotBackstopRadius green
	plotBackstopCentre gold
    } elseif {$current_spot_search_parameter == "backstop_radius"} {
	foreach {backstop_x_p backstop_y_p} [getCurrentViewCentrePixel "backstop"] break
	set radius_p [expr sqrt(pow($a_x - $backstop_x_p,2)+pow($a_y - $backstop_y_p,2))]
	set $current_spot_search_parameter [format %.2f [expr ($radius_p / $zoom) * $pixel_size]]
	$itk_component(backstop_r_e) setValue $backstop_radius
	plotBackstopRadius gold green
    } elseif {$current_spot_search_parameter == "search_area_max_radius"} {
	set radius_p [expr sqrt(pow($a_x - $beam_x_p,2)+pow($a_y - $beam_y_p,2))]
	set $current_spot_search_parameter [format %.2f [expr ($radius_p / $zoom) * $pixel_size]]
	$itk_component(max_radius_e) setValue $search_area_max_radius
	plotMaxSearchRadius gold red
    } elseif {$current_spot_search_parameter == "search_area_min_radius"} {
	set radius_p [expr sqrt(pow($a_x - $beam_x_p,2)+pow($a_y - $beam_y_p,2))]
	set $current_spot_search_parameter [format %.2f [expr ($radius_p / $zoom) * $pixel_size]]
	$itk_component(min_radius_e) setValue $search_area_min_radius
	plotMinSearchRadius gold red
    } elseif {$current_spot_search_parameter == "vertical_exclusion"} {
	set width_p [expr $a_x - $beam_x_p]
	if {$old_vertical_exclusion < 0} {
	    if {$width_p > 0} {
		set width_p 0
	    }
	    set width_p [expr -1 * $width_p]
	} else {
	    if {$width_p < 0} {
		set width_p 0
	    }
	}
	set exclusion_segment_vertical [format %.2f [expr ($width_p / $zoom) * $pixel_size]]
	$itk_component(exclusion_segment_vertical_e) setValue $exclusion_segment_vertical
	plotExclusionSegment "vertical" gold red
    } elseif {$current_spot_search_parameter == "horizontal_exclusion"} {
	set width_p [expr $a_y - $beam_y_p]
	if {$old_horizontal_exclusion < 0} {
	    if {$width_p > 0} {
		set width_p 0
	    }
	    set width_p [expr -1 * $width_p]
	} else {
	    if {$width_p < 0} {
		set width_p 0
	    }
	}
	set exclusion_segment_horizontal [format %.2f [expr ($width_p / $zoom) * $pixel_size]]
	$itk_component(exclusion_segment_horizontal_e) setValue $exclusion_segment_horizontal
	plotExclusionSegment "horizontal" gold red
    } elseif {$current_spot_search_parameter == "high_resolution_limit"} {
	set radius_p [expr sqrt(pow($a_x - $beam_x_p,2)+pow($a_y - $beam_y_p,2))]
	set radius_mm [expr ($radius_p / $zoom) * $pixel_size]
	set high_resolution_limit [format %.2f [expr $wavelength / (2 * sin(0.5 * atan($radius_mm / $distance)))]]
	$itk_component(max_res_e) setValue $high_resolution_limit
	plotHighResolutionLimit gold blue
    } elseif {$current_spot_search_parameter == "low_resolution_limit"} {
	set radius_p [expr sqrt(pow($a_x - $beam_x_p,2)+pow($a_y - $beam_y_p,2))]
	set radius_mm [expr ($radius_p / $zoom) * $pixel_size]
	set low_resolution_limit [format %.2f [expr $wavelength / (2 * sin(0.5 * atan($radius_mm / $distance)))]]
	$itk_component(min_res_e) setValue $low_resolution_limit
	plotLowResolutionLimit gold blue
    }
}

body ImageDisplay::editSpotSearchParameterRelease { } {
    if {$current_spot_search_parameter == "beam"} {
	$::session updateSetting beam_x $beam_x 1 1 "User" 0
	$::session updateSetting beam_y $beam_y 1 1 "User" 0

	if {[$::session predictionPossible]} {
	    getPredictions
	}
    } elseif {$current_spot_search_parameter == "backstop_centre"} {
	$::session updateSetting backstop_x $backstop_x 1 1 "User" 0
	$::session updateSetting backstop_y $backstop_y 1 1 "User" 0

	if {[$::session predictionPossible]} {
	    getPredictions
	}
    } elseif {$current_spot_search_parameter == "backstop_radius"} {
	$::session updateSetting backstop_radius $backstop_radius 1 1 "User"
	plotBackstopRadius gold green
    } elseif {$current_spot_search_parameter == "search_area_max_radius"} {
	$::session updateSetting search_area_max_radius $search_area_max_radius 1 1 "User"
	plotMaxSearchRadius gold red
    } elseif {$current_spot_search_parameter == "search_area_min_radius"} {
	$::session updateSetting search_area_min_radius $search_area_min_radius 1 1 "User"
	plotMinSearchRadius gold red
    } elseif {$current_spot_search_parameter == "vertical_exclusion"} {
	$::session updateSetting exclusion_segment_vertical $exclusion_segment_vertical 1 1 "User"
	plotExclusionSegment "vertical" gold red
    } elseif {$current_spot_search_parameter == "horizontal_exclusion"} {
	$::session updateSetting exclusion_segment_horizontal $exclusion_segment_horizontal 1 1 "User"
	plotExclusionSegment "horizontal" gold red
    } elseif {$current_spot_search_parameter == "high_resolution_limit"} {
	$::session updateSetting high_resolution_limit $high_resolution_limit 1 1 "User"
	plotHighResolutionLimit gold blue
    } elseif {$current_spot_search_parameter == "low_resolution_limit"} {
	$::session updateSetting low_resolution_limit $low_resolution_limit 1 1 "User"
	plotLowResolutionLimit gold blue
    }
    bind $itk_component(canvas) <Motion> [code $this editSpotSearchParameterMove %x %y]
}

#########################################################
#########################################################
# Functions for interactive spot finding
#########################################################
#########################################################

body ImageDisplay::toggleZoomTool { a_state } {
    if {$a_state == 1} {
	setupZoomToolBindings
    } else {
	removeZoomToolBindings
    }
}

body ImageDisplay::togglePointerTool { a_state } {
    if {$a_state == 1} {
	Overlay::setupEditBindings
 	bind $itk_component(canvas) <ButtonPress-2> [code $this mousePick %x %y]
    } else {
	Overlay::removeEditBindings
	bind $itk_component(canvas) <ButtonPress-2> ""
    }
}

body ImageDisplay::toggleSpotAddingTool { a_state } {
    if {$a_state == 1} {
	$itk_component(spots) invoke
	setupSpotAddingBindings
    } else {
	removeSpotAddingBindings
    }
}

body ImageDisplay::toggleMaskingTool { a_state } {
    if {$a_state == 1} {
	$itk_component(masks) invoke
	Mask::setupCreationBindings
    } else {
	Mask::removeCreationBindings
    }
}

body ImageDisplay::tryAutoBackstop { } {
	.m configure \
	    -type "2button" \
	    -title "Warning" \
	    -text "This option is not fully implemented. It might appear to \nwork but you may get unexpected or inappropriate results" \
	    -button1of2 "OK" \
	    -button2of2 "Cancel"
	if {![.m confirm]} {
	    # User didn't want to try it so return
	} else {
	    toggleMasks 1
	    $::mosflm sendCommand "backstop auto"
	}
}

body ImageDisplay::toggleCircleFittingTool { a_state } {
    if {$a_state == 1} {
	CircleFit::launch $itk_component(canvas)
    } else {
	CircleFit::clear
    }
}

body ImageDisplay::toggleEraserTool { a_state } {
    if {$a_state == 1} {
	setupEraserBindings
    } else {
	removeEraserBindings
    }
}

body ImageDisplay::togglePanningTool { a_state } {
    if {$a_state == 1} {
	setupPanningBindings
    } else {
	removePanningBindings
    }
}

# Global tool bindings (info labels and zoom mod-clicks}

body ImageDisplay::storePreBindings { a_type } {
    array unset pre_${a_type}_bindings *
    foreach i_event [bind $itk_component(canvas)] {
	set pre_${a_type}_bindings($i_event) [bind $itk_component(canvas) $i_event]
	bind $itk_component(canvas) $i_event {}
    }
}

body ImageDisplay::restorePreBindings { a_type } {
    foreach i_event [array names pre_${a_type}_bindings] {
	bind $itk_component(canvas) $i_event [set pre_${a_type}_bindings($i_event)]
    }
}

body ImageDisplay::startInfoLabelsScroll { a_type a_x a_y} {
    set scrolledx [getCoorx $a_x]
    set scrolledy [getCoory $a_y]
    startInfoLabels $a_type $scrolledx $scrolledy
}

body ImageDisplay::startInfoLabels { a_type a_x a_y } {
    # Trigger current leave binding (if there is one), to "mute"
    #  current tool bindings effects
    set l_leave_binding [bind $itk_component(canvas) <Leave>]
    if {$l_leave_binding != ""} {
	uplevel \#0 $l_leave_binding
    }
    # Store cursor for restoring later
    set info_cursor [$itk_component(canvas) cget -cursor]
    # Set question cursor
    $itk_component(canvas) configure -cursor "question_arrow"
    # Store currrent bindings for restoring later
    storePreBindings "info"
    # Show the info label
    showInfoLabels $a_x $a_y
    # Setup bindings for future info labels
    if {$a_type == "Motion"} {
	bind $itk_component(canvas) <Alt-Motion> [code $this showInfoLabelsScroll %x %y]
	bind $itk_component(canvas) <M2-Motion> [code $this showInfoLabels %x %y]
	bind $itk_component(canvas) <Control-Motion> [code $this showInfoLabels %x %y]
	bind $itk_component(canvas) <Motion> [code $this endInfoLabelsScroll %x %y]
	bind $itk_component(canvas) <Leave> [code $this endInfoLabelsScroll %x %y]
    } else {
	bind $itk_component(canvas) <Motion> [code $this showInfoLabelsScroll %x %y]
	bind $itk_component(canvas) <Leave> [code $this endInfoLabelsScroll %x %y]
	bind $itk_component(canvas) <ButtonRelease-1> [code $this endInfoLabelsScroll %x %y]
    }
}

body ImageDisplay::endInfoLabelsScroll { a_x a_y} {
	set scrolledx [getCoorx $a_x]
	set scrolledy [getCoory $a_y]
	endInfoLabels $scrolledx $scrolledy
}

body ImageDisplay::endInfoLabels { a_x a_y } {
    # Restore cursor
    $itk_component(canvas) configure -cursor $info_cursor
    # Hide data labels
    wm withdraw $itk_component(data_labels)
    # Remove info label bindings
    bind $itk_component(canvas) <Alt-Motion> {}
    bind $itk_component(canvas) <M2-Motion> {}
    bind $itk_component(canvas) <Control-Motion> {}
    bind $itk_component(canvas) <Motion> {}
    bind $itk_component(canvas) <Leave> {}
    bind $itk_component(canvas) <ButtonRelease-1> {}
    # Rstore previous bindings
    restorePreBindings "info"
}

# Tool Binding Methods

body ImageDisplay::getCoorx {a_coor} {
#	puts $a_coor
#	puts [$itk_component(canvas) canvasx $a_coor]
	return [$itk_component(canvas) canvasx $a_coor]
	
}

body ImageDisplay::getCoory {a_coor} {
#	puts $a_coor
#	puts [$itk_component(canvas) canvasy $a_coor]
	return [$itk_component(canvas) canvasy $a_coor]
}

body ImageDisplay::setupZoomToolBindings { } {
    $itk_component(canvas) configure -cursor $::cursor::zoom
    bind $itk_component(canvas) <ButtonPress-1> [code $this zoomClick %x %y]
 
    if {[tk windowingsystem] != "aqua"} {
	bind $itk_component(canvas) <Shift-Motion> [code $this magnifyStart Motion %x %y]
    } else {
	bind $itk_component(canvas) <Shift-Motion> [code $this magnifyStart Motion %x  %y]
	#bind $itk_component(canvas) <M1-ButtonPress-1> [code $this magnifyStart "ButtonPress-1" %x %y]
    }
}

body ImageDisplay::removeZoomToolBindings { } {
    $itk_component(canvas) configure -cursor left_ptr
    bind $itk_component(canvas) <ButtonPress-1> {}
    bind $itk_component(canvas) <Button1-Motion> {}
    bind $itk_component(canvas) <Shift-Motion> {}
    bind $itk_component(canvas) <ButtonRelease-1> {}
}

body ImageDisplay::setupSpotAddingBindings { } {   
    $itk_component(canvas) configure -cursor pencil
    bind $itk_component(canvas) <Enter> [code $this placeSpotStart %x %y]
    bind $itk_component(canvas) <ButtonPress-1> [code $this placeSpotClick %x %y]
    bind $itk_component(canvas) <ButtonRelease-1> [code $this placeSpotRelease %x %y]
    bind $itk_component(canvas) <Motion> [code $this placeSpotMove %x %y]
    bind $itk_component(canvas) <Leave> [code $this placeSpotEnd %x %y]
}

body ImageDisplay::removeSpotAddingBindings { } {   
    $itk_component(canvas) configure -cursor left_ptr
    bind $itk_component(canvas) <Enter> {}
    bind $itk_component(canvas) <ButtonPress-1> {}
    bind $itk_component(canvas) <ButtonRelease-1> {}
    bind $itk_component(canvas) <Motion> {}
    bind $itk_component(canvas) <Leave> {}
}

body ImageDisplay::setupEraserBindings { } {
    $itk_component(canvas) configure -cursor $::cursor::eraser
    bind $itk_component(canvas) <Enter> [code $this deleteMarkerStart %x %y]
    bind $itk_component(canvas) <ButtonPress-1> [code $this deleteMarkerClick %x %y]
    bind $itk_component(canvas) <ButtonRelease-1> [code $this deleteMarkerRelease %x %y]
    bind $itk_component(canvas) <Motion> [code $this deleteMarkerMove %x %y]
    bind $itk_component(canvas) <Leave> [code $this deleteMarkerEnd]
}

body ImageDisplay::removeEraserBindings { } {
    $itk_component(canvas) configure -cursor left_ptr
    bind $itk_component(canvas) <Enter> {}
    bind $itk_component(canvas) <ButtonPress-1> {}
    bind $itk_component(canvas) <ButtonRelease-1> {}
    bind $itk_component(canvas) <Motion> {}
    bind $itk_component(canvas) <Leave> {}
}

body ImageDisplay::setupPanningBindings { } {
    $itk_component(canvas) configure -cursor fleur
    bind $itk_component(canvas) <ButtonPress-1> [code $this panningClick %x %y]
    bind $itk_component(canvas) <ButtonRelease-1> [code $this panningRelease]
}

body ImageDisplay::removePanningBindings { } {
    $itk_component(canvas) configure -cursor left_ptr
    bind $itk_component(canvas) <Enter> {}
    bind $itk_component(canvas) <ButtonPress-1> {}
    bind $itk_component(canvas) <ButtonRelease-1> {}
    bind $itk_component(canvas) <Motion> {}
    bind $itk_component(canvas) <Leave> {}
}

body ImageDisplay::panningClick { a_x a_y } {
    # store pixel that was grabbed
    #foreach { grab_x grab_y } [getMasterPixel $a_x $a_y] break
    set grab_x $a_x
    set grab_y $a_y
    # store view position at grab
    set grab_left_x $left_x
    set grab_top_y $top_y
    set grab_right_x $right_x
    set grab_bottom_y $bottom_y
    # setup pan motion binding
    bind $itk_component(canvas) <Motion> [code $this pan %x %y]
}

body ImageDisplay::panningRelease { } {
    bind $itk_component(canvas) <Motion> {}
}

body ImageDisplay::pan { a_x a_y } {

    set l_dx [expr int(($grab_x - $a_x) / $zoom)]
    set l_dy [expr int(($grab_y - $a_y) / $zoom)]

    set l_new_left_x [expr $grab_left_x + $l_dx]
    set l_new_top_y [expr $grab_top_y + $l_dy]
    set l_new_right_x [expr $grab_right_x + $l_dx]
    set l_new_bottom_y [expr $grab_bottom_y + $l_dy]

    if {$l_new_left_x < 1} {
	set l_dx [expr 1 - $l_new_left_x ]
	set l_new_left_x [expr $l_new_left_x + $l_dx]
	set l_new_right_x [expr $l_new_right_x + $l_dx]
    } elseif  {$l_new_right_x > $detector_size_x} {
	set l_dx [expr $detector_size_x - $l_new_right_x ]
	set l_new_left_x [expr $l_new_left_x + $l_dx]
	set l_new_right_x [expr $l_new_right_x + $l_dx]
    }
    
    if {$l_new_top_y < 1} {
	set l_dy [expr 1 - $l_new_top_y ]
	set l_new_top_y [expr $l_new_top_y + $l_dy]
	set l_new_bottom_y [expr $l_new_bottom_y + $l_dy]
    } elseif  {$l_new_bottom_y > $detector_size_y} {
	set l_dy [expr $detector_size_y - $l_new_bottom_y ]
	set l_new_top_y [expr $l_new_top_y + $l_dy]
	set l_new_bottom_y [expr $l_new_bottom_y + $l_dy]
    }

    if {($l_new_left_x != $left_x) || ($l_new_top_y != $top_y)} {
	set old_left_x $left_x
	set old_top_y $top_y
	set left_x $l_new_left_x
	set top_y $l_new_top_y
	set right_x $l_new_right_x
	set bottom_y $l_new_bottom_y
	set current_cursor fleur
	#puts "updateView from pan"
	updateView
    }
}

body ImageDisplay::toggleTools { tool args } {
    set clear_canvas_bindings 0
    if {$tool != "circle_fitting"} {
	CircleFit::clear
    }
    if {$tool == "magnifiertool"} {
	if {[tk windowingsystem] == "x11"} {
	    $itk_component(canvas) configure -cursor $::cursor::box
	    set current_cursor $::cursor::box
	} else {
	    $itk_component(canvas) configure -cursor cross
	    set current_cursor cross
	}	    
	bind $itk_component(canvas) <Enter> [code $this magnifyStart %x %y]
	bind $itk_component(canvas) <Motion> [code $this magnifyMove %x %y 13 13]
	bind $itk_component(canvas) <ButtonPress-1> {}
	bind $itk_component(canvas) <ButtonRelease-1> {}
	bind $itk_component(canvas) <Leave> [code $this magnifyEnd %X %Y]
	bind $itk_component(mag_canvas) <Leave> [code $this magnifyEnd %X %Y]
    } elseif {$tool == "spotfinding"} {
	$itk_component(spots) invoke
	$itk_component(canvas) configure -cursor pencil
	set current_cursor pencil
	bind $itk_component(canvas) <Enter> [code $this placeSpotStart %x %y]
	bind $itk_component(canvas) <ButtonPress-1> [code $this placeSpotClick %x %y]
	bind $itk_component(canvas) <ButtonRelease-1> [code $this placeSpotRelease %x %y]
	bind $itk_component(canvas) <Motion> [code $this placeSpotMove %x %y]
	bind $itk_component(canvas) <Leave> [code $this placeSpotEnd %x %y]
    } elseif {$tool == "spotdeleting"} {
	$itk_component(spots) invoke
	$itk_component(canvas) configure -cursor hand2
	set current_cursor hand2
	bind $itk_component(canvas) <Enter> [code $this deleteMarkerStart %x %y]
	bind $itk_component(canvas) <ButtonPress-1> [code $this deleteMarkerClick %x %y]
	bind $itk_component(canvas) <ButtonRelease-1> [code $this deleteMarkerRelease %x %y]
	bind $itk_component(canvas) <Motion> [code $this deleteMarkerMove %x %y]
	bind $itk_component(canvas) <Leave> [code $this deleteMarkerEnd]
    } elseif {$tool == "pointer"} {
	#$itk_component(spotfinding_settings) invoke
	$itk_component(canvas) configure -cursor left_ptr
	set current_cursor left_ptr
	Overlay::setupEditBindings
 	bind $itk_component(canvas) <ButtonPress-2> [code $this mousePick %x %y]
    } elseif {$tool == "masking_tool"} {
	$itk_component(masks) invoke
	$itk_component(canvas) configure -cursor left_ptr
	set current_cursor left_ptr
	Mask::setupCreationBindings
    } elseif {$tool == "circle_fitting"} {
	$itk_component(canvas) configure -cursor left_ptr
	set current_cursor left_ptr
	CircleFit::launch $itk_component(canvas)
    } elseif {$tool == "panning_tool"} {
	$itk_component(canvas) configure -cursor fleur
	set current_cursor fleur
	bind $itk_component(canvas) <Enter> {}
	bind $itk_component(canvas) <ButtonPress-1> [code $this grabClick %x %y]
	bind $itk_component(canvas) <ButtonRelease-1> [code $this grabRelease %x %y]
	bind $itk_component(canvas) <Motion> {}
	bind $itk_component(canvas) <Leave> {}
    } elseif {$tool == "masking"} {
	clearCanvasBindings
	Mask::setCreationBindings $itk_component(canvas)
    }
}

body ImageDisplay::clearCanvasBindings { } {
    bind $itk_component(canvas) <Enter> {}
    bind $itk_component(canvas) <ButtonPress-1> {}
    bind $itk_component(canvas) <ButtonRelease-1> {}
    bind $itk_component(canvas) <Motion> {}
    bind $itk_component(canvas) <Leave> {}
}

body ImageDisplay::placeSpotStart { x y } {
    
    placeSpot $x $y
    placeSpot $x $y
    #wm deiconify $itk_component(magnifier)
}

body ImageDisplay::placeSpotMove { x y } {
    after cancel $spot_placing_queue
    set spot_placing_queue [after 5 [code $this placeSpot $x $y]]
    # placeSpot $x $y
}

body ImageDisplay::getSpotLineEnds { spot_x spot_y offset } {

    set hix [expr {$spot_x - $offset}]
    set lox [expr {$spot_x + $offset}]
    set hiy [expr {$spot_y - $offset}]
    set loy [expr {$spot_y + $offset}]
    
    return [list $hix $hiy $lox $loy]
}

body ImageDisplay::placeSpot { x y } {

    if {[catch {localSpotSearch $x $y} result]} {
	# Cursor out of canvas area
    } else {
	set offset 10
	foreach { spot_x spot_y } $result { }
	foreach { hix hiy lox loy } [getSpotLineEnds $spot_x $spot_y $offset] { }
	# create crosses
	$itk_component(canvas) delete proto_cross
	$itk_component(mag_canvas) delete proto_cross
	$itk_component(canvas) create line $hix $hiy $lox $loy $spot_x $spot_y $lox $hiy $hix $loy -capstyle round -fill yellow -tags proto_cross
	$itk_component(mag_canvas) create line $hix $hiy $lox $loy $spot_x $spot_y $lox $hiy $hix $loy -capstyle round -fill yellow -tags [list proto_cross marker]
	
	positionMarkers proto_cross

    }

    # Begin magnification
    magnifyMove $x $y 20 20
}

body ImageDisplay::placeSpotClick { x y } {
    magnifyMove $x $y 20 20
    wm deiconify $itk_component(magnifier)
    raise $itk_component(magnifier)
    $itk_component(spots) invoke
}
    
body ImageDisplay::placeSpotRelease { x y } {

    if {$x > 0 && $y > 0 && $x < [image width $view_image] && $y < [image height $view_image]} {
	# refocus magnification
	magnifyMove $x $y 20 20
	
	# Find the best place to put a spot near the cursor
	foreach { spot_x spot_y } [localSpotSearch $x $y] { }
	
	# Create new spotlist for image, if one doesn't exist
	set l_spotlist [$image_object getSpotlist]
	if {$l_spotlist == ""} {
	    foreach { l_phi_start l_phi_end } [$image_object getPhi] break
	    set l_spotlist [namespace current]::[Spotlist \#auto "empty" [$image_object getImageHeight] [expr {double($l_phi_start + $l_phi_end) / 2.0}] $pixel_size]
	    $image_object setSpotlist $l_spotlist
	}

	# Add a spot to the spotlist with that location
	set l_new_spot [$l_spotlist addSpotManually $spot_x $spot_y]
	# if successful (i.e. not already got a spot there) draw the spot
	if {$l_new_spot != ""} {
	    $l_new_spot plot $itk_component(canvas)
	    $l_new_spot plot $itk_component(mag_canvas)
	    positionMarkers "cross[$l_new_spot getId]"
	    [.c component indexing] updateSpotFindingResult $image_object
	    # record the spot edit in the history
	    $::session addHistoryEvent "SpotAddEvent" "User action" [$image_object getFullPathName] $l_new_spot
	} else {
	    # Cannot add spot at same location as existing spot
	}
	
    } else {
	# Outside of image
    }

    $itk_component(canvas) delete proto_cross
    $itk_component(mag_canvas) delete proto_cross
    
    wm withdraw $itk_component(magnifier)
}

body ImageDisplay::placeSpotEnd { x y } {
    
    if {$x >= 0 && \
	    $x <= [winfo width $itk_component(canvas)] && \
	    $y >= 0 && \
	    $y <= [winfo height $itk_component(canvas)]
    } {
 	bind $itk_component(canvas) <Enter> { }
 	#placeSpotMove $x $y
 	#bind $itk_component(canvas) <Enter> [code $this placeSpotStart %x %y]
    } else {
	bind $itk_component(canvas) <Enter> [code $this placeSpotStart %x %y]
	after cancel $spot_placing_queue
	
	$itk_component(canvas) delete proto_cross
	$itk_component(mag_canvas) delete proto_cross
    }
}

body ImageDisplay::localSpotSearch { x y } {
    # Get pixel clicked on
    foreach { xi yi } [getMasterPixel $x $y] { }
    # Correct for subsampling
    if {$zoom < 1} {
	set xi [expr int($xi - (0.5 * (1.0/$zoom)))] 
	set yi [expr int($yi - (0.5 * (1.0/$zoom)))] 
    }

    # Get neighbourhood data (correcting for 'data -from' 
    #  not including bottom-right column + row

    set left_border [expr (($xi - $search_radius) < 0) ? 0 : ($xi - $search_radius)]
    set top_border [expr (($yi - $search_radius) < 0) ? 0 : ($yi - $search_radius)]
    set right_border [expr ((($xi + $search_radius) + 1) > $detector_size_x) ? $detector_size_x : (($xi + $search_radius) + 1)]
    set bottom_border [expr ((($yi + $search_radius) + 1) > $detector_size_y) ? $detector_size_y : (($yi + $search_radius) + 1)]

    set neighbourhood [$master_image data -from \
			   $left_border \
			   $top_border \
			   $right_border \
			   $bottom_border]

    # Calcluate spot centre

    # initialize row and column arrays
    array unset mrow
    array unset mcol
    set x_count 0
    set y_count 0
    while {$y_count < [llength $neighbourhood]} {
	set mcol($y_count) 0
	incr y_count
    }
    while {$x_count < [llength [lindex $neighbourhood 0]]} {
	set mrow($x_count) 0
	incr x_count
    }

    # add up image neighbourhood in a 'row sums' array and 'col sums' array
    set y_count 0
    foreach row $neighbourhood {
	set x_count 0
	foreach item $row {
	    scan [string range $item 1 end] %x value
	    incr mrow($x_count) $value
	    incr mcol($y_count) $value
	    incr x_count
	}
	incr y_count
    }

    # find the blackest column
    scan "ffffff" %x minval
    set mincol [expr $minval * (($search_radius * 2) + 1)]
    set minrow [expr $minval * (($search_radius * 2) + 1)]
    set minx [expr $search_radius]
    set miny $minx
    foreach name [array names mrow] {
	if {$mrow($name) < $mincol} {
	    set mincol $mrow($name)
	    set minx $name
	}
    }
    # find the blackest row
    foreach name [array names mcol] {
	if {$mcol($name) < $minrow} {
	    set minrow $mcol($name)
	    set miny $name
	}
    }

    set spot_x [expr $left_border + $minx - 1] 
    set spot_y [expr $top_border + $miny - 1] 

    return [list $spot_x $spot_y]
}

########################################################

body ImageDisplay::deleteMarkerStart { x y } {

    #Cursor rubber $itk_component(canvas)

    # N.B. deleteMarkerMove called twice, as single call inexplicably fails to work!
    deleteMarkerMove $x $y
    deleteMarkerMove $x $y
}

body ImageDisplay::deleteMarkerMove { x y } {
    
    #$itk_component(canvas) itemconfigure real_crosses -fill red
    #$itk_component(mag_canvas) itemconfigure real_crosses -fill red

    # Test for masks
    set l_mask [Mask::overMask $x $y]
    if {$l_mask != ""} {
	# unclour any cross
	if {$highlighted_cross != ""} {
	    $itk_component(canvas) itemconfigure real_cross$highlighted_cross -fill $highlighted_cross_colour
	    set highlighted_cross ""
	}
	#  if mask has changed, unhighlight any prev mask and highlight new one
	if {$l_mask != $highlighted_mask} {
	    if {$highlighted_mask != ""} {
		$highlighted_mask unhighlightMask
	    }
	    $l_mask highlightMask
	    set highlighted_mask $l_mask
	} else {
	}
    } else {
	# unhighlight any highlighted mask
	if {$highlighted_mask != ""} {
	    $highlighted_mask unhighlightMask
	    set highlighted_mask ""
	}
	# test for near cross
	set chosen [findClosestNearItem $x $y real_crosses]
	if {$chosen != ""} {
	    # get cross's id
	    set l_tags [$itk_component(canvas) gettags $chosen]
	    foreach i_tag $l_tags {
		if {[regexp {real_cross(\d+)} $i_tag match l_id]} {
		    break
		}
	    }
	    # if cross has changed...
	    if {$l_id != $highlighted_cross} {
		if {$highlighted_cross != ""} {
		    # restore previous cross's colour
		    $itk_component(canvas) itemconfigure real_cross$highlighted_cross -fill $highlighted_cross_colour
		    $itk_component(mag_canvas) itemconfigure real_cross$highlighted_cross -fill $highlighted_cross_colour
		}
		#update record of highlighted cross
		set highlighted_cross $l_id
		# store new cross's colour
		set highlighted_cross_colour [$itk_component(canvas) itemcget real_cross$l_id -fill]
		# colour new cross
		$itk_component(canvas) itemconfigure real_cross$highlighted_cross -fill pink
		$itk_component(mag_canvas) itemconfigure real_cross$highlighted_cross -fill pink
		
		
		$itk_component(canvas) raise $chosen crosses
		$itk_component(mag_canvas) raise $chosen crosses
	    }
	} else {
	    if {$highlighted_cross != ""} {
		# restore previous cross's colour
		$itk_component(canvas) itemconfigure real_cross$highlighted_cross -fill $highlighted_cross_colour
		$itk_component(mag_canvas) itemconfigure real_cross$highlighted_cross -fill $highlighted_cross_colour
		set highlighted_cross ""
	    }    
	}
	magnifyMove $x $y 20 20
    }
}

body ImageDisplay::deleteMarkerEnd { } {
    if {$highlighted_cross != ""} {
	$itk_component(canvas) itemconfigure real_cross$highlighted_cross -fill $highlighted_cross_colour
	$itk_component(mag_canvas) itemconfigure real_cross$highlighted_cross -fill $highlighted_cross_colour
	set highlighted_cross ""
    } elseif {$highlighted_mask != ""} {
	$highlighted_mask unhighlightMask
	set highlighted_mask ""
    }
}

body ImageDisplay::deleteMarkerClick { x y } {

    $itk_component(spots) invoke

    magnifyMove $x $y 20 20
    wm deiconify $itk_component(magnifier)
    raise $itk_component(magnifier)
}

body ImageDisplay::deleteMarkerRelease { x y } {
    if {$highlighted_mask != ""} {
	Mask::deleteMask [$highlighted_mask getNumber]
	set highlighted_mask ""
    } elseif {$highlighted_cross != ""} {
	set l_spotlist [$image_object getSpotlist]
	if {$l_spotlist != ""} {
	    # Find the spot to be deleted
	    set l_spot_to_be_deleted [$l_spotlist getSpotById $highlighted_cross]
	    # add spot edit event to the history
	    $::session addHistoryEvent "SpotDeleteEvent" "User action" [$image_object getFullPathName] $l_spot_to_be_deleted 
	    $l_spotlist deleteSpot "id" $highlighted_cross
	    $itk_component(canvas) delete real_cross$highlighted_cross
	    $itk_component(mag_canvas) delete real_cross$highlighted_cross
	    [.c component indexing] updateSpotFindingResult $image_object
	}
	set highlighted_cross ""
    }
    wm withdraw $itk_component(magnifier)
}

body ImageDisplay::findClosestNearItem { x y tag } {
    set chosen ""
    set l_distance "999"
    set items [$itk_component(canvas) find overlapping \
		   [expr $x - $search_radius] \
		   [expr $y - $search_radius] \
		   [expr $x + $search_radius] \
		   [expr $y + $search_radius]]
    foreach item $items {
	if {[lsearch [$itk_component(canvas) itemcget $item -tags] $tag] != -1} {
	    if {$tag == "real_crosses"} {
		foreach { loc_x loc_y } [lrange [$itk_component(canvas) coords $item] 4 5] break
		set dist [expr sqrt(pow($x-$loc_x,2) + pow($y-$loc_y,2))]
	    } elseif {$tag == "clickable_spotfinding_param"} {
		set l_tags [$itk_component(canvas) gettags $item]
		if {[lsearch $l_tags "beam"] != -1} {
		    foreach {xc_p yc_p} [getCurrentViewCentrePixel "beam"] break
		    set radius_p [expr sqrt(pow($xc_p - $x,2) + pow($yc_p - $y,2))]
		    set radius_mm [expr (double($radius_p) / $zoom) * $pixel_size]
		    set dist $radius_mm
		} elseif {[lsearch $l_tags "backstop_centre"] != -1} {
		    foreach {xc_p yc_p} [getCurrentViewCentrePixel "backstop"] break
		    set radius_p [expr sqrt(pow($xc_p - $x,2) + pow($yc_p - $y,2))]
		    set radius_mm [expr (double($radius_p) / $zoom) * $pixel_size]
		    set dist $radius_mm
		} elseif {[lsearch $l_tags "backstop_radius"] != -1} {
		    foreach {xc_p yc_p} [getCurrentViewCentrePixel "backstop"] break
		    set radius_p [expr sqrt(pow($xc_p - $x,2) + pow($yc_p - $y,2))]
		    set radius_mm [expr (double($radius_p) / $zoom) * $pixel_size]
		    set dist [expr abs($search_area_min_radius - $radius_mm)]
		} elseif {[lsearch $l_tags "search_area_min_radius"] != -1} {
		    foreach {xc_p yc_p} [getCurrentViewCentrePixel "beam"] break
		    set radius_p [expr sqrt(pow($xc_p - $x,2) + pow($yc_p - $y,2))]
		    set radius_mm [expr (double($radius_p) / $zoom) * $pixel_size]
		    set dist [expr abs($search_area_min_radius - $radius_mm)]
		} elseif {[lsearch $l_tags "search_area_max_radius"] != -1} {
		    foreach {xc_p yc_p} [getCurrentViewCentrePixel "beam"] break
		    set radius_p [expr sqrt(pow($xc_p - $x,2) + pow($yc_p - $y,2))]
		    set radius_mm [expr (double($radius_p) / $zoom) * $pixel_size]
		    set dist [expr abs($search_area_max_radius - $radius_mm)]
		} elseif {[lsearch $l_tags vertical_exclusion] != -1} {
		    foreach {xc_p yc_p} [getCurrentViewCentrePixel "beam"] break
		    set width_p [expr abs($xc_p - $x)]
		    set width_mm [expr (double($width_p) / $zoom) * $pixel_size]
		    set dist [expr abs($exclusion_segment_vertical - $width_mm)]
		} elseif {[lsearch $l_tags horizontal_exclusion] != -1} {
		    foreach {xc_p yc_p} [getCurrentViewCentrePixel "beam"] break
		    set width_p [expr abs($yc_p - $y)]
		    set width_mm [expr (double($width_p) / $zoom) * $pixel_size]
		    set dist [expr abs($exclusion_segment_horizontal - $width_mm)]
		} elseif {[lsearch $l_tags high_resolution_limit] != -1} {
		    foreach {xc_p yc_p} [getCurrentViewCentrePixel "beam"] break
		    set radius_p [expr sqrt(pow($xc_p - $x,2) + pow($yc_p - $y,2))]
		    set radius_mm [expr (double($radius_p) / $zoom) * $pixel_size]
		    set dist [expr abs($high_resolution_radius - $radius_mm)]
		} elseif {[lsearch $l_tags low_resolution_limit] != -1} {
		    foreach {xc_p yc_p} [getCurrentViewCentrePixel "beam"] break
		    set radius_p [expr sqrt(pow($xc_p - $x,2) + pow($yc_p - $y,2))]
		    set radius_mm [expr (double($radius_p) / $zoom) * $pixel_size]
		    set dist [expr abs($low_resolution_radius - $radius_mm)]
		} elseif {[lsearch -glob $l_tags mask_polygon(*)] != -1} {
		    set l_poly_tag [lsearch -inline -glob $l_tags mask_polygon(*)]
		    set l_really_overlapped_items [$itk_component(canvas) find overlapping $x $y $x $y]
		    set dist 999
		    foreach i_really_overlapped_item $l_really_overlapped_items {
			set l_really_overlapped_tags [$itk_component(canvas) gettags $i_really_overlapped_item]
			if {[lsearch $l_really_overlapped_tags $l_poly_tag]} {
			    set dist 0
			}
		    }
		} else {
		    set dist 999
		}
	    } else {
		set dist 999
	    }
	    if {$dist < $l_distance} {
		set l_distance $dist
		set chosen $item
	    }
	}
    }
    return $chosen
}

#########################################################
# Pick                                                  #
#########################################################

body ImageDisplay::processPick { a_dom } {
    if {$zoom == $max_zoom} {

	# Clear existing pick
	$itk_component(canvas) delete pick
	# Check on status of task
	set status_code [$a_dom selectNodes string(/pick_region/status/code)]
	if {$status_code == "error"} {
	    .m confirm \
		-type "1button" \
		-text "[$a_dom selectNodes string(/pick_region/status/message)]" \
		-button1of2 "Dismiss"
    
	} else {
	    set boxsize 21
	    # Extract data
	    set l_data [$a_dom selectNodes normalize-space(/pick_region)]
	    # Getcontrast limits
	    foreach { l_min l_max } [$itk_component(contrast_palette) getContrast] break
	    # get colour threshold
	    set l_threshold [expr ($l_min + $l_max) / 2]
	    #puts "black/white threshold: $l_threshold"
	    set l_pixel_size $zoom
	    set l_y 0
	    while {$l_y < $boxsize} {
		set l_x 0
		while {$l_x < $boxsize} {
		    set l_datum [lindex $l_data [expr {($l_x*$boxsize) + $l_y + 6} ]]
		    if {$l_datum < $l_threshold} {
			set l_colour black
		    } else {
			set l_colour white
		    }
		    $itk_component(canvas) create text \
			[expr ($l_x + 0.5) * $l_pixel_size] \
			[expr ($l_y + 0.5) * $l_pixel_size] \
			-text $l_datum \
			-fill $l_colour \
			-tags pick
		    incr l_x
		}
		incr l_y
	    }
	}
    } else {
	.pw processPick $a_dom
    }

}

#########################################################
# Methods to be used for displaying bad spots in future #
#########################################################

body ImageDisplay::processBadSpots { a_dom } {

    # Get bad spot information
    set imgtempl [$a_dom selectNodes normalize-space(/bad_spots_response/image_template)]
    set imgno [$a_dom selectNodes normalize-space(/bad_spots_response/image_number)]
    set badspotlist_node [$a_dom selectNodes /bad_spots_response/bad_spot_list]
    set image_object [$::session getImageByTemplateAndNumber $imgtempl $imgno]
    set badspotlist [namespace current]::[BadSpotlist \#auto "xml" $badspotlist_node]

    $image_object setBadSpotlist $badspotlist
    # try $image_object setbadspotlist in Image::

}

body ImageDisplay::plotBadSpots { } {

    # Don't bother if there is no image
    if {$image_object == ""} {
	return
    }

    clearBadSpots

    # Get any bad spot list associated with the current image
    set l_badspotlist [$image_object getBadSpotlist]

    if { $l_badspotlist != "" } {

	set l_num_badspots [llength [$l_badspotlist getBadSpots]]

	#puts "$image_object number [$image_object getNumber] has $l_num_badspots bad spots"

	# If there is a spotlist...
	if { $l_num_badspots > 0 } {
	    # plot spots on each canvas
	    $l_badspotlist plotSpots $i_sig_i $itk_component(canvas) $itk_component(mag_canvas)
    
	    # position the spots
	    positionMarkers badspots
    
	    # Raise spots to make them viewable, if their toolbutton is pushed in
	    if {[$itk_component(badspots) query]} {
		$itk_component(canvas) raise badspots view_image
	    } else {
		$itk_component(canvas) lower badspots view_image
	    }
	} else {
	    #puts "$image_object number [$image_object getNumber] has no bad spots"
	}
    }
}

body ImageDisplay::clearBadSpots { } {

    #puts "IMAGE CLEAR BAD SPOTS"
    $itk_component(canvas) delete badspots
    $itk_component(mag_canvas) delete badspots

    update

}

#########################################################
# Methods used for displaying predicitons               #
#########################################################

body ImageDisplay::getPredictions { } {
    #puts "IMAGE GET PREDICTIONS"
    # Get prediction lists and xml response with width and height from Mosflm
    eval $::mosflm getPredictions
}

body ImageDisplay::clearPredictions { } {
    #puts "IMAGE CLEAR PREDICTIONS"

    # Unset list of all predictions used by findHKL
    set prediction_nodes {}
    # Unset predictions by type array
    array unset predictions_by_type *

    $itk_component(canvas) delete prediction
    $itk_component(mag_canvas) delete prediction
    $itk_component(predictions) cancel
    $itk_component(predictions) configure -state "disabled"

    $itk_component(canvas) delete pinpointhkl
    update

}    

body ImageDisplay::findHKL { s_h s_k s_l } {
    
    $itk_component(canvas) delete pinpointhkl
    set found 0
    set currenthkl {}
    foreach type [array names predictions_by_type] {
	#puts "Searching predictions of type $type"
	#puts $predictions_by_type($type)
	foreach {i_x i_y i_h i_k i_l} [set predictions_by_type($type)] {
	    #puts "$i_h $i_k $i_l"
	    if {$i_h == $s_h && $i_k == $s_k && $i_l == $s_l} {
		set currenthkl [list $i_x $i_y]
		#puts "$currenthkl found in $type"
		set found 1
		break
	    }
	}
	if { $found == 1 } {
	    break
	}
    }
    return $found
}

body ImageDisplay::plotHKL { } {

    $itk_component(canvas) delete pinpointhkl

    # span is the side length of the rectangle in which the cross will be drawn
    set span 30
    foreach { i_x i_y } $currenthkl {
	foreach { hix hiy lox loy } [getRectangleCorners $i_x $i_y $span $span] { }
	#puts $currenthkl
	# Draw cross as two lines as the more precise position calculated now means the lines do not cross at (i_x,i_y)
	$itk_component(canvas) create line $hix $hiy $lox $loy -capstyle projecting -fill black -width 2 -tags pinpointhkl
	$itk_component(canvas) create line $lox $hiy $hix $loy -capstyle projecting -fill black -width 2 -tags pinpointhkl
    }
    positionMarkers "pinpointhkl"
}		

body ImageDisplay::processPredictions { a_dom } {

    # List of all predictions for findHKL
    set prediction_nodes {}
    # Predictions by type for this image
    array unset predictions_by_type *
    
    # Delete existing predictions
    $itk_component(canvas) delete prediction
    $itk_component(mag_canvas) delete prediction

    # Check on status of task
    set status_code [$a_dom selectNodes string(/prediction_response/status/code)]
    if {$status_code == "error"} {
	.m confirm \
	    -type "1button" \
	    -text "[$a_dom selectNodes string(/prediction_response/status/message)]" \
	    -button1of2 "Dismiss"

    } else {
	set l_width [$a_dom selectNodes normalize-space(//width)]
	set predictions_width $l_width
	set l_height [$a_dom selectNodes normalize-space(//height)]
	set predictions_height $l_height
	foreach i_box_list_node [$a_dom selectNodes //boxes/*] {
	    #puts "processPredictions: i_box_list_node $i_box_list_node"
	    set l_type [$i_box_list_node nodeName]
	    #puts "l_type $prediction_colour_$l_type"
	    set l_boxes [$i_box_list_node text]
	    #puts "l_boxes $l_boxes"
	    set predictions_by_type($l_type) $l_boxes
	    lappend prediction_nodes $l_boxes

	    # Plot each prediction list in their pixel positions
	    #Blue:   Fully recorded reflection (these comments from the tutorial)
	    #Yellow: Partially recorded reflection
	    #Red:    Spatially overlapped reflection... these will NOT be integrated
	    #Green:  Reflection width too large (more than 5 degrees)... not integrated.
	    #puts "$l_type will use colour "
	    
	    set l_colour [subst "\$predictioncolour_$l_type"]
	    # Test here if fg text colour should be black or white for predictions at present

	    if {[llength $l_boxes] > 0} {
		if {$l_type == "fulls"} {
		    # [blue] box & label background with white info text
		    set l_alt_colour "white"
		} elseif  {$l_type == "partials"} {
		    # yellow
		    set l_alt_colour "black"
		} elseif  {$l_type == "overlaps"} {
		    # red
		    set l_alt_colour "black"
		} elseif  {$l_type == "wide"} {
		    # green
		    set l_alt_colour "black"
		} else {
		    error "Dodgy prediction type: $l_type"
		}
		plotPredictions $l_width $l_height $l_colour $l_alt_colour $l_boxes
	    } else {
	    }    
	}
    }
    
    # use positionMarkers to relocate them to match the current view
    positionMarkers "prediction"

    # Activate predictions toolbutton if previsouly disabled
    if {[$itk_component(predictions) cget -state] == "disabled"} {
	$itk_component(predictions) configure -state "normal"
	$itk_component(predictions) invoke
    }
    
    # Hide the predictions if the toolbutton was activated
    if {![$itk_component(predictions) query]} {
	$itk_component(canvas) lower prediction view_image
    }

}

body ImageDisplay::redrawPredictions { } {

    # Delete existing predictions
    $itk_component(canvas) delete prediction
    $itk_component(mag_canvas) delete prediction

    foreach l_type [array names predictions_by_type] {

	# Plot each prediction list in their pixel positions
	#Blue:   Fully recorded reflection (these comments from the tutorial)
	#Yellow: Partially recorded reflection
	#Red:    Spatially overlapped reflection... these will NOT be integrated
	#Green:  Reflection width too large (more than 5 degrees)... not integrated.
	#puts "$l_type will use colour "
	set l_colour [subst "\$predictioncolour_$l_type"]
	    
	if {$l_type == "fulls"} {
	    set l_alt_colour "white"
	} elseif  {$l_type == "partials"} {
	    set l_alt_colour "black"
	} elseif  {$l_type == "overlaps"} {
	    set l_alt_colour "black"
	} elseif  {$l_type == "wide"} {
	    set l_alt_colour "black"
	} else {
	    error "Dodgy prediction type: $l_type"
	}
	set l_boxes [set predictions_by_type($l_type)]
	if {[llength $l_boxes] > 0} {
	    plotPredictions $predictions_width $predictions_height $l_colour $l_alt_colour $l_boxes
	}
    }

    # use positionMarkers to relocate them to match the current view
    positionMarkers "prediction"

    # Activate predictions toolbutton if previsouly disabled
    if {[$itk_component(predictions) cget -state] == "disabled"} {
	$itk_component(predictions) configure -state "normal"
	$itk_component(predictions) invoke
    }
    
    # Hide the predictions if the toolbutton was activated
    if {![$itk_component(predictions) query]} {
	$itk_component(canvas) lower prediction view_image
    }

}

body ImageDisplay::plotPredictions { a_width a_height a_colour a_alt_colour a_coord_list } {
    # Plot markers in pixel positions
    foreach {i_x i_y i_h i_k i_l } $a_coord_list {
	plotRectangle $i_x $i_y $a_width $a_height $a_colour $a_alt_colour $i_h $i_k $i_l $itk_component(canvas) $itk_component(mag_canvas)
    }
}

body ImageDisplay::colourPredictions { } {
    set p_colours {}
    foreach type {fulls partials overlaps wide} {
	#set var "\$predictioncolour_$type"
	lappend p_colours $type [subst "\$predictioncolour_$type"]
    }
    #puts $p_colours
    # Display a menu enabling colour setting
    if {![winfo exists .cpd]} {
        ColourPredictionsDialog .cpd $p_colours
        .cpd confirm p_colours
    } else {
	raise .cpd
        .cpd confirm p_colours
    }
    #puts $p_colours
    redrawPredictions
}

body ImageDisplay::setPredictionColour { type colour } {
    #Set colour for predictions of type to colour
    set [subst predictioncolour_$type] $colour
}

body ImageDisplay::getRectangleCorners { a_x a_y a_width a_height } {
    # Calculate coords of opposite corners
    set hix [expr {$a_x - (double($a_width) / 2) - 1}]
    set lox [expr {$a_x + (double($a_width) / 2) - 1}]
    set hiy [expr {$a_y - (double($a_height) / 2) - 1}]
    set loy [expr {$a_y + (double($a_height) / 2) - 1}]

    return [list $hix $hiy $lox $loy]
}

body ImageDisplay::plotRectangle { a_x a_y a_width a_height a_colour a_alt_colour a_h a_k a_l args } {

    foreach i_canvas $args {
	$i_canvas create rectangle [getRectangleCorners $a_x $a_y $a_width $a_height] -outline "" -fill "" -tags [list prediction info_colour($a_colour) info_alt_colour($a_alt_colour) marker info_class(prediction) info_label(Prediction:$a_h,$a_k,$a_l)]
	$i_canvas create rectangle [getRectangleCorners $a_x $a_y $a_width $a_height] -outline $a_colour -tags [list prediction marker]
    }
}

class ColourPredictionsDialog {
    inherit Dialog

    private variable l_types {fulls partials overlaps wide}
    private variable fullscolour
    private variable partialscolour
    private variable overlapscolour
    private variable widecolour

    private method ok
    private method cancel
    private method setColour
    public method confirm

    constructor { args } { }
}

body ColourPredictionsDialog::constructor { pcolist args } {

    .cpd configure -title "Set colours"

    #puts $pcolist

    # Build type and colour labels
    foreach {type colour} $pcolist {

	# Prediction type
	itk_component add $type {
	    button $itk_interior.$type \
		-text "$type" \
		-width 7 \
		-highlightbackground "#dcdcdc" \
		-command [code $this setColour $type]
	}
	   
	# Prediction colour
	itk_component add [subst $type]colour {
	    label $itk_interior.[subst $type]col \
		-text "\[ \] \[ \] \[ \] . . . " \
		-fg $colour
	}

	grid $itk_component($type) $itk_component([subst $type]colour) -stick w

	set [subst $type]colour $colour
    }

    # Buttons
    itk_component add button_frame {
	frame $itk_interior.bf
    }
    grid $itk_component(button_frame) - -sticky we

    itk_component add ok {
	button $itk_interior.bf.ok \
	    -text "Ok" \
	    -width 7 \
	    -highlightbackground "#dcdcdc" \
	    -command [code $this ok]
    }

    itk_component add cancel {
	button $itk_interior.bf.cancel \
	    -text "Cancel" \
	    -width 7 \
	    -highlightbackground "#dcdcdc" \
	    -command [code $this cancel] 
    }

    pack $itk_component(ok) $itk_component(cancel) -side right

}

body ColourPredictionsDialog::setColour { type } {
    # Get current colour for this type
    set colour [subst "\$${type}colour"]
    #puts "$type predictions current colour $colour"

#    if {[tk windowingsystem] == "aqua"} {
#	set colour [tk_chooseColor -initialcolor $colour]
#    } else {
#	# Display color_demo if not aqua
#	if {![winfo exists .coldemo]} {
#	    puts ".coldemo does not exist"
#	    ColorDemoDialog .coldemo $colour
#	    .coldemo confirm $colour
#	} else {
#	    puts ".coldemo   does   exist"
#	    raise .coldemo
#	    .coldemo confirm $colour
#	}
#	puts "Colour from .coldemo $colour"
#    }

    set colour [tk_chooseColor -initialcolor $colour]

    #puts "$type predictions set  to colour $colour"

    if {[string equal $colour ""]} {
	# Cancel means do nothing
    } else {
	# colour the label
	$itk_component([subst $type]colour) configure -fg $colour
	# set the colour for this type of prediction
	set [subst $type]colour $colour
    }
    raise .cpd
}

body ColourPredictionsDialog::ok { } {
    set retlist {}
    foreach type $l_types {
	.image setPredictionColour $type [subst "\$${type}colour"]
	lappend retlist $type [subst "\$${type}colour"]
    }
    dismiss ""
}

body ColourPredictionsDialog::cancel { } {
    dismiss ""
}

body ColourPredictionsDialog::confirm { args } {
    Dialog::confirm
}

class ColorDemoDialog {

    inherit Dialog

    public method confirm
    private method ok

    constructor { args } { }
}

body ColorDemoDialog::constructor { args } {

    global RGB COLOR
    
    puts "ColDemDial:: cons args $args"

    set cols {
        000000 black
        0000ff blue
        8b4513 {saddle brown}
        00ffff cyan
        00ff00 green
        ff00ff magenta
        ffa500 orange
        a020f0 purple
        ff0000 red
        ffff00 yellow
        ffffff white
        fffafa snow
        f8f8ff {ghost white}
        f5f5f5 {white smoke}
        dcdcdc gainsboro
        fffaf0 {floral white}
        fdf5e6 {old lace}
        faf0e6 linen
        faebd7 {antique white}
        ffefd5 {papaya whip}
        ffebcd {blanched almond}
        ffe4c4 bisque
        ffdab9 {peach puff}
        ffdead {navajo white}
        ffe4b5 moccasin
        fff8dc cornsilk
        fffff0 ivory
        fffacd {lemon chiffon}
        fff5ee seashell
        f0fff0 honeydew
        f5fffa {mint cream}
        f0ffff azure
        f0f8ff {alice blue}
        e6e6fa lavender
        fff0f5 {lavender blush}
        ffe4e1 {misty rose}
        2f4f4f {dark slate gray}
        696969 {dim gray}
        708090 {slate gray}
        778899 {light slate gray}
        bebebe gray
        d3d3d3 {light grey}
        191970 {midnight blue}
        000080 navy
        6495ed {cornflower blue}
        483d8b {dark slate blue}
        6a5acd {slate blue}
        7b68ee {medium slate blue}
        8470ff {light slate blue}
        0000cd {medium blue}
        4169e1 {royal blue}
        1e90ff {dodger blue}
        00bfff {deep sky blue}
        87ceeb {sky blue}
        87cefa {light sky blue}
        4682b4 {steel blue}
        b0c4de {light steel blue}
        add8e6 {light blue}
        b0e0e6 {powder blue}
        afeeee {pale turquoise}
        00ced1 {dark turquoise}
        48d1cc {medium turquoise}
        40e0d0 turquoise
        e0ffff {light cyan}
        5f9ea0 {cadet blue}
        66cdaa {medium aquamarine}
        7fffd4 aquamarine
        006400 {dark green}
        556b2f {dark olive green}
        8fbc8f {dark sea green}
        2e8b57 {sea green}
        3cb371 {medium sea green}
        20b2aa {light sea green}
        98fb98 {pale green}
        00ff7f {spring green}
        7cfc00 {lawn green}
        7fff00 chartreuse
        00fa9a {medium spring green}
        adff2f {green yellow}
        32cd32 {lime green}
        9acd32 {yellow green}
        228b22 {forest green}
        6b8e23 {olive drab}
        bdb76b {dark khaki}
        f0e68c khaki
        eee8aa {pale goldenrod}
        fafad2 {light goldenrod yellow}
        ffffe0 {light yellow}
        ffd700 gold
        eedd82 {light goldenrod}
        daa520 goldenrod
        b8860b {dark goldenrod}
        bc8f8f {rosy brown}
        cd5c5c {indian red}
        a0522d sienna
        cd853f peru
        deb887 burlywood
        f5f5dc beige
        f5deb3 wheat
        f4a460 {sandy brown}
        d2b48c tan
        d2691e chocolate
        b22222 firebrick
        a52a2a brown
        e9967a {dark salmon}
        fa8072 salmon
        ffa07a {light salmon}
        ff8c00 {dark orange}
        ff7f50 coral
        f08080 {light coral}
        ff6347 tomato
        ff4500 {orange red}
        ff69b4 {hot pink}
        ff1493 {deep pink}
        ffc0cb pink
        ffb6c1 {light pink}
        db7093 {pale violet red}
        b03060 maroon
        c71585 {medium violet red}
        d02090 {violet red}
        ee82ee violet
        dda0dd plum
        da70d6 orchid
        ba55d3 {medium orchid}
        9932cc {dark orchid}
        9400d3 {dark violet}
        8a2be2 {blue violet}
        9370db {medium purple}
        d8bfd8 thistle
        eee9e9 snow2 cdc9c9 snow3 8b8989 snow4
        eee5de seashell2 cdc5bf seashell3 8b8682 seashell4
        ffefdb AntiqueWhite1 eedfcc AntiqueWhite2
        cdc0b0 AntiqueWhite3 8b8378 AntiqueWhite4
        eed5b7 bisque2 cdb79e bisque3 8b7d6b bisque4
        eecbad PeachPuff2 cdaf95 PeachPuff3 8b7765 PeachPuff4
        eecfa1 NavajoWhite2 cdb38b NavajoWhite3 8b795e NavajoWhite4
        eee9bf LemonChiffon2 cdc9a5 LemonChiffon3 8b8970 LemonChiffon4
        eee8cd cornsilk2 cdc8b1 cornsilk3 8b8878 cornsilk4
        eeeee0 ivory2 cdcdc1 ivory3 8b8b83 ivory4
        e0eee0 honeydew2 c1cdc1 honeydew3 838b83 honeydew4
        eee0e5 LavenderBlush2 cdc1c5 LavenderBlush3 8b8386 LavenderBlush4
        eed5d2 MistyRose2 cdb7b5 MistyRose3 8b7d7b MistyRose4
        e0eeee azure2 c1cdcd azure3 838b8b azure4
        836fff SlateBlue1 7a67ee SlateBlue2 6959cd SlateBlue3 473c8b SlateBlue4
        4876ff RoyalBlue1 436eee RoyalBlue2 3a5fcd RoyalBlue3 27408b RoyalBlue4
        0000ee blue2 00008b blue4
        1c86ee DodgerBlue2 1874cd DodgerBlue3 104e8b DodgerBlue4
        63b8ff SteelBlue1 5cacee SteelBlue2 4f94cd SteelBlue3 36648b SteelBlue4
        00b2ee DeepSkyBlue2 009acd DeepSkyBlue3 00688b DeepSkyBlue4
        87ceff SkyBlue1 7ec0ee SkyBlue2 6ca6cd SkyBlue3 4a708b SkyBlue4
        b0e2ff LightSkyBlue1 a4d3ee LightSkyBlue2
        8db6cd LightSkyBlue3 607b8b LightSkyBlue4
        c6e2ff SlateGray1 b9d3ee SlateGray2 9fb6cd SlateGray3 6c7b8b SlateGray4
        cae1ff LightSteelBlue1 bcd2ee LightSteelBlue2
        a2b5cd LightSteelBlue3 6e7b8b LightSteelBlue4
        bfefff LightBlue1 b2dfee LightBlue2 9ac0cd LightBlue3 68838b LightBlue4
        d1eeee LightCyan2 b4cdcd LightCyan3 7a8b8b LightCyan4
        bbffff PaleTurquoise1 aeeeee PaleTurquoise2
        96cdcd PaleTurquoise3 668b8b PaleTurquoise4
        98f5ff CadetBlue1 8ee5ee CadetBlue2 7ac5cd CadetBlue3 53868b CadetBlue4
        00f5ff turquoise1 00e5ee turquoise2 00c5cd turquoise3 00868b turquoise4
        00eeee cyan2 00cdcd cyan3 008b8b cyan4
        97ffff DarkSlateGray1 8deeee DarkSlateGray2
        79cdcd DarkSlateGray3 528b8b DarkSlateGray4
        76eec6 aquamarine2 458b74 aquamarine4
        c1ffc1 DarkSeaGreen1 b4eeb4 DarkSeaGreen2
        9bcd9b DarkSeaGreen3 698b69 DarkSeaGreen4
        54ff9f SeaGreen1 4eee94 SeaGreen2 43cd80 SeaGreen3
        9aff9a PaleGreen1 90ee90 PaleGreen2 7ccd7c PaleGreen3 548b54 PaleGreen4
        00ee76 SpringGreen2 00cd66 SpringGreen3 008b45 SpringGreen4
        00ee00 green2 00cd00 green3 008b00 green4
        76ee00 chartreuse2 66cd00 chartreuse3 458b00 chartreuse4
        c0ff3e OliveDrab1 b3ee3a OliveDrab2 698b22 OliveDrab4
        caff70 DarkOliveGreen1 bcee68 DarkOliveGreen2
        a2cd5a DarkOliveGreen3 6e8b3d DarkOliveGreen4
        fff68f khaki1 eee685 khaki2 cdc673 khaki3 8b864e khaki4
        ffec8b LightGoldenrod1 eedc82 LightGoldenrod2
        cdbe70 LightGoldenrod3 8b814c LightGoldenrod4
        eeeed1 LightYellow2 cdcdb4 LightYellow3 8b8b7a LightYellow4
        eeee00 yellow2 cdcd00 yellow3 8b8b00 yellow4
        eec900 gold2 cdad00 gold3 8b7500 gold4
        ffc125 goldenrod1 eeb422 goldenrod2 cd9b1d goldenrod3 8b6914 goldenrod4
        ffb90f DarkGoldenrod1 eead0e DarkGoldenrod2
        cd950c DarkGoldenrod3 8b6508 DarkGoldenrod4
        ffc1c1 RosyBrown1 eeb4b4 RosyBrown2 cd9b9b RosyBrown3 8b6969 RosyBrown4
        ff6a6a IndianRed1 ee6363 IndianRed2 cd5555 IndianRed3 8b3a3a IndianRed4
        ff8247 sienna1 ee7942 sienna2 cd6839 sienna3 8b4726 sienna4
        ffd39b burlywood1 eec591 burlywood2 cdaa7d burlywood3 8b7355 burlywood4
        ffe7ba wheat1 eed8ae wheat2 cdba96 wheat3 8b7e66 wheat4
        ffa54f tan1 ee9a49 tan2 8b5a2b tan4
        ff7f24 chocolate1 ee7621 chocolate2 cd661d chocolate3
        ff3030 firebrick1 ee2c2c firebrick2 cd2626 firebrick3 8b1a1a firebrick4
        ff4040 brown1 ee3b3b brown2 cd3333 brown3 8b2323 brown4
        ff8c69 salmon1 ee8262 salmon2 cd7054 salmon3 8b4c39 salmon4
        ee9572 LightSalmon2 cd8162 LightSalmon3 8b5742 LightSalmon4
        ee9a00 orange2 cd8500 orange3 8b5a00 orange4
        ff7f00 DarkOrange1 ee7600 DarkOrange2
        cd6600 DarkOrange3 8b4500 DarkOrange4
        ff7256 coral1 ee6a50 coral2 cd5b45 coral3 8b3e2f coral4
        ee5c42 tomato2 cd4f39 tomato3 8b3626 tomato4
        ee4000 OrangeRed2 cd3700 OrangeRed3 8b2500 OrangeRed4
        ee0000 red2 cd0000 red3 8b0000 red4
        ee1289 DeepPink2 cd1076 DeepPink3 8b0a50 DeepPink4
        ff6eb4 HotPink1 ee6aa7 HotPink2 cd6090 HotPink3 8b3a62 HotPink4
        ffb5c5 pink1 eea9b8 pink2 cd919e pink3 8b636c pink4
        ffaeb9 LightPink1 eea2ad LightPink2
        cd8c95 LightPink3 8b5f65 LightPink4
        ff82ab PaleVioletRed1 ee799f PaleVioletRed2
        cd6889 PaleVioletRed3 8b475d PaleVioletRed4
        ff34b3 maroon1 ee30a7 maroon2 cd2990 maroon3 8b1c62 maroon4
        ff3e96 VioletRed1 ee3a8c VioletRed2
        cd3278 VioletRed3 8b2252 VioletRed4
        ee00ee magenta2 cd00cd magenta3 8b008b magenta4
        ff83fa orchid1 ee7ae9 orchid2 cd69c9 orchid3 8b4789 orchid4
        ffbbff plum1 eeaeee plum2 cd96cd plum3 8b668b plum4
        e066ff MediumOrchid1 d15fee MediumOrchid2
        b452cd MediumOrchid3 7a378b MediumOrchid4
        bf3eff DarkOrchid1 b23aee DarkOrchid2
        9a32cd DarkOrchid3 68228b DarkOrchid4
        9b30ff purple1 912cee purple2 7d26cd purple3 551a8b purple4
        ab82ff MediumPurple1 9f79ee MediumPurple2
        8968cd MediumPurple3 5d478b MediumPurple4
        ffe1ff thistle1 eed2ee thistle2 cdb5cd thistle3 8b7b8b thistle4
        030303 gray1 050505 gray2 080808 gray3 0a0a0a gray4 0d0d0d gray5
        0f0f0f gray6 121212 gray7 141414 gray8 171717 gray9 1a1a1a gray10
        1c1c1c gray11 1f1f1f gray12 212121 gray13 242424 gray14 262626 gray15
        292929 gray16 2b2b2b gray17 2e2e2e gray18 303030 gray19 333333 gray20
        363636 gray21 383838 gray22 3b3b3b gray23 3d3d3d gray24 404040 gray25
        424242 gray26 454545 gray27 474747 gray28 4a4a4a gray29 4d4d4d gray30
        4f4f4f gray31 525252 gray32 545454 gray33 575757 gray34 595959 gray35
        5c5c5c gray36 5e5e5e gray37 616161 gray38 636363 gray39 666666 gray40
        6b6b6b gray42 6e6e6e gray43 707070 gray44 737373 gray45 757575 gray46
        787878 gray47 7a7a7a gray48 7d7d7d gray49 7f7f7f gray50 828282 gray51
        858585 gray52 878787 gray53 8a8a8a gray54 8c8c8c gray55 8f8f8f gray56
        919191 gray57 949494 gray58 969696 gray59 999999 gray60 9c9c9c gray61
        9e9e9e gray62 a1a1a1 gray63 a3a3a3 gray64 a6a6a6 gray65 a8a8a8 gray66
        ababab gray67 adadad gray68 b0b0b0 gray69 b3b3b3 gray70 b5b5b5 gray71
        b8b8b8 gray72 bababa gray73 bdbdbd gray74 bfbfbf gray75 c2c2c2 gray76
        c4c4c4 gray77 c7c7c7 gray78 c9c9c9 gray79 cccccc gray80 cfcfcf gray81
        d1d1d1 gray82 d4d4d4 gray83 d6d6d6 gray84 d9d9d9 gray85 dbdbdb gray86
        dedede gray87 e0e0e0 gray88 e3e3e3 gray89 e5e5e5 gray90 e8e8e8 gray91
        ebebeb gray92 ededed gray93 f0f0f0 gray94 f2f2f2 gray95 f7f7f7 gray97
        fafafa gray98 fcfcfc gray99
    }
    array set RGB $cols

    pack [frame .coldemo.top] -fill both
    pack [frame .coldemo.top.left]  -side left -fill both
    pack [frame .coldemo.top.right] -side left -fill both -expand 1
    set arg {-from 0 -to 255 -showvalue 0 -orient horizontal}
    foreach i {red green blue} {
        set COLOR($i) 0
        eval scale .coldemo.top.left.$i $arg -var COLOR($i) -troughcolor $i \
            -command set_color_aux;#-label [string toup $i]:
        pack .coldemo.top.left.$i -fill y -expand 1
    }
    frame .coldemo.top.right.top
    pack .coldemo.top.right.top -fill x
    button .coldemo.top.right.top.about -text "About" -highlightthickness 0 -command \
       {tk_messageBox -message "Color Demo\n\u00a9 1996 University of Oregon\nOriginal concept by Spencer Smith\nRewrite by Jeffrey Hobbs July 1996" -parent .coldemo}
    button .coldemo.top.right.top.set -text "OK" -highlightthickness 0 -command [ code $this ok ]
    pack .coldemo.top.right.top.about -in .coldemo.top.right.top -side left -fill x -expand 1
    pack .coldemo.top.right.top.set -in .coldemo.top.right.top -side right -fill x -expand 1
    set color_label [label .coldemo.top.right.color]
    pack $color_label -fill x -expand 1
    pack [label .coldemo.top.right.cname -width 9 -textvar COLOR(rgb)]
    
    #pack [frame .coldemo -relief ridge -bd 2] -fill both -expand 1
    set canvas [canvas .coldemo.canvas -yscrollcommand ".coldemo.sy set" \
        -width 200 -height 330 -relief raised -bd 2]
    scrollbar .coldemo.sy -orient vert -command "$canvas yview" -bd 1
    pack .coldemo.sy -side right -fill y
    pack $canvas -fill both -expand 1

    set mark 0
    foreach {i j} $cols {
        scan $i "%2x%2x%2x" r g b
        if {($r+$g+$b)<350} { set col white } else { set col black }
        
        set i \#$i
        $canvas create rect 0 $mark 400 [incr mark 30] \
            -fill $i -outline {} -tags $i
        $canvas create text 100 [expr $mark-15] -text $j -fill $col -tags $i
        $canvas bind $i <ButtonPress-1> "set_color $i"
    }
    $canvas config -scrollregion "0 0 200 $mark"

    bind Canvas <Button-2>   [bind Text <Button-2>]
    bind Canvas <B2-Motion>  [bind Text <B2-Motion>]
    bind Canvas <MouseWheel> [bind Text <MouseWheel>]

    # Set the incoming colour
    puts "Colour in $args"
    scan $args "\#%2x%2x%2x" red green blue
    puts "red green blue $red $green $blue"
    foreach c {red green blue} { set COLOR($c) [format %d [set $c]] }
    #set incolour \#[format "%.2X%.2X%.2X" $COLOR(red) $COLOR(green) $COLOR(blue)]
    set incolour $args
    puts "set to  $incolour"
    set_color $incolour
    .coldemo configure -title "Set colours"
    focus .coldemo.sy
}

proc set_color {{rgb {}}} {
    global RGB COLOR
    
    if [string comp {} $rgb] {
        scan $rgb "\#%2x%2x%2x" red green blue
        foreach c {red green blue} { set COLOR($c) [format %d [set $c]] }
    } else {
        set rgb \#[format "%.2X%.2X%.2X" $COLOR(red) $COLOR(green) $COLOR(blue)]
    }
    puts "set_color to $rgb"
    .coldemo.top.right.color config -bg $rgb
    set COLOR(rgb) $rgb
    .coldemo.top.right.cname configure -fg $rgb
    update
}

proc set_color_aux args { set_color }

body ColorDemoDialog::ok { } {
    global RGB COLOR
    #upvar 1 colour colset
    puts "ok COLOR(rgb) set $COLOR(rgb)"
    scan $COLOR(rgb) "\#%2x%2x%2x" red green blue
    foreach c {red green blue} { set COLOR($c) [format %d [set $c]] }
    set colset \#[format "%.2x%.2x%.2x" $COLOR(red) $COLOR(green) $COLOR(blue)]
    puts "ok colour set $colset"
    dismiss ""
}

body ColorDemoDialog::confirm { colset } {
    global RGB COLOR
    #upvar 1 colour colset
    puts "confirm COLOR(rgb) set $COLOR(rgb)"
    scan $COLOR(rgb) "\#%2x%2x%2x" red green blue
    foreach c {red green blue} { set COLOR($c) [format %d [set $c]] }
    set colset \#[format "%.2x%.2x%.2x" $COLOR(red) $COLOR(green) $COLOR(blue)]
    puts "confirm colour set $colset"
    Dialog::confirm
}
