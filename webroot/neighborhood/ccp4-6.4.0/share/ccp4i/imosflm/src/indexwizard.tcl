# $Id: indexwizard.tcl,v 1.13 2012/03/26 16:36:39 ccb Exp $
package provide indexwizard 0.1

class Indexwizard {
    inherit itk::Widget
    
    # Layout variables
    private variable grid_search 0
    private variable grid_counter 0
    private variable index_workflow "true"
    private variable mosaicity_workflow "true"
    public method indexingRelay
    public method mosaicityRelay
    private variable index_done 0
    private variable mosaicity_done 0
    public method protrial
    public method promosaicity
    public method trial

    private variable showbeamsearch 0

    private variable margin 7
    private variable indent 20
    private variable panel 0

    # List of images to be indexed
    private variable images_list {}
    private variable image_objects_by_number ; # NB array - don't initialize
    private variable image_objects_by_item ; # NB array - don't initialize
    private variable image_items_by_number ; # NB array - don't initialize
    private variable image_items_by_object ; # NB array - don't initialize

    private variable choosing_images "0"
    private variable chosen_images_text ""
    private variable chosen_search_images ""

    # List of images being searched
    private variable images_being_searched {}
    # list of images being autoindexed
    private variable images_being_autoindexed {}

    # Temporary spotfile for indexing
    private variable spotfilename ""
    private variable l_first_image 0
    private variable haveNewSpotfilename 0

    # List of flags indicating whether spotlists should be used
    private variable use_spotlists {}

    # Solution list variables
    private variable solution_objects_by_number ; # N.B. array - do not initialize
    private variable solution_items_by_number ; # N.B. array - do not initialize
    private variable solution_numbers_by_item ; # N.B. array - do not initialize
    private variable solution_objects_by_item ; # N.B. array - do not initialize
    private variable solution_item_types ; # N.B. array - do not initialize
    private variable suggested_solution_number ""
    public variable solutions_cell_view "0"

    # chosen solution object
    private variable chosen_solution ""
    # chosen solution type (raw, reg, ref)
    private variable chosen_solution_type ""

    # Processing options
    private variable estimate_mosaicity "1"

    private variable result_update_checks {}
    private variable result_update_types {}

    private variable mosaicity ""
    private variable previous_mosaicity ""
    private variable mosaicity_has_been_set 0
    
    private variable max_mosaicity_tested "0"
    private variable mosaicity_values {} ; # N.B. NOT array - do not NOTinitialize
    private variable mosaicity_intensities {} ; # N.B. NOT array - do not NOTinitialize
    private variable mosaicity_intensities_2nd_derivative {} ; # N.B. NOT array - do not NOT initialize

    # array holding result items
    private variable result_items_by_name ; # N.B. array - do not initialize

    # image tree rollover variables
    private variable prev_rollover_item ""
    private variable prev_rollover_element ""

    # Search types
    private variable searchtype "beam-centre"

    # Methods

    # Start and end
    public method launch
    public method hide
    private method complete
    public method clear

    public method disable
    public method enable
    private method toggleAbility
    private method updateIndexButton
    public method updateMosaicityButton

    # Option methods
    private method fixMaxCellEdge

    # Do job (spot finding, indexing and refinement)
    public method findSpots
    public method autoindex
    public method queueAutoindex


    private method pickFirstImage
    private method pickNinetyDegreeImages
    private method chooseImages

    # Process results
    public method readSpotsFile
    public method processSpotsFile
    public method processSpotfindingResults
    public method processIndexingResults
    public method processPrerefinementResult
    public method processRefinedResult
    public method processMosaicityEstimation

    # Show results
    private method refreshSolutions 
    private method showRefinementResults

    # Spot finding methods
    public method addImage
    public method removeImage
    public method getIncludedImages
    private method buildImageTree
    private method imageTreeClick
    private method imageTreeDoubleClick
    private method checkSpotlistInclusion
    private method uncheckSpotlistInclusion
    private method toggleSpotlistInclusion
    private method toggleImageSelection
    public method updateSpotSummary
    private method updateTotal
    public method updateSpotlists
    public method updateSpotFindingResult
    public method updateSpotReportIsigi
    public method sortSpotFindingResults
    public method editSpots
    public method createImageCheck
    private method updateSpotlistSelection
    private method updateSpotlistInclusions
    private method updateImageNumbers

    public method imageTreeRollover

    # Indexing results methods
    private method sortSolutionItems
    public method toggleSolution
    private method toggleSpacegroup
    private method doubleClickSolution
    private method refine
    private method refineAll

    # Mosaicity and summary methods
    public method updateMosaicity
    public method estimateMosaicity
    private method createUpdateCheck
    public method refreshMosaicity

    # Debugging method
    public method hack

    private variable do_not_process_indexing 0
    private variable beam_list {}
    private variable preloop_beam_x
    private variable preloop_beam_y
    public method beamSearchLaunch

    public method getNewSpotfilename
    public method getSpotfileFirstImage

    public method gridSearchRelay
    public method sigmaISearchRelay
    public method sigmaISearchAutoindex
    public method beamSearchAutoindex
    public method showBeamSearch
    public method hideBeamSearch
    public method abortBeamSearch
    public method toggleBeamSearchTable
    public method beamTreeDoubleClick

    constructor {args} { }

}

body Indexwizard::hack { } {
    # debugging method
}

body Indexwizard::constructor { args } {

    itk_option add hull.width hull.height
    
    # Toolbars ###############################################

    itk_component add spotfinding_toolbar {
	frame [.c component toolbar_frame].spotfinding
    }

    # Divider

    itk_component add spotfinding_divider1 {
	frame $itk_component(spotfinding_toolbar).div1 \
	    -width 2 \
	    -relief sunken \
	    -bd 1
    }

    itk_component add beam_x_e {
        SettingEntry $itk_component(spotfinding_toolbar).bxe beam_x \
	    -image ::img::beam_x16x16 \
	    -balloonhelp "Beam x position" \
	    -type real \
	    -precision 2 \
	    -width 6 \
	    -justify right 
    }

    itk_component add beam_y_e {
        SettingEntry $itk_component(spotfinding_toolbar).bye beam_y \
	    -image ::img::beam_y16x16 \
	    -balloonhelp "Beam y position" \
	    -type real \
	    -precision 2 \
	    -width 6 \
	    -justify right 
    }

    itk_component add distance_e {
        SettingEntry $itk_component(spotfinding_toolbar).de distance \
	    -image ::img::distance16x16 \
	    -balloonhelp "Crystal to detector distance" \
	    -type real \
	    -precision 2 \
	    -width 6 \
	    -justify right 
    }

    itk_component add spotfinding_divider2 {
	frame $itk_component(spotfinding_toolbar).div2 \
	    -width 2 \
	    -relief sunken \
	    -bd 1
    }

    itk_component add threshold_e {
        SettingEntry $itk_component(spotfinding_toolbar).te threshold \
	    -image ::img::spot_threshold16x16 \
	    -balloonhelp "Spot finding threshold" \
	    -type "real" \
	    -precision "2" \
	    -minimum "1.00" \
	    -width 4 \
	    -justify right \
	    -state normal 
    }

    itk_component add spot_size_e {
        MultiSettingEntry $itk_component(spotfinding_toolbar).size_e \
	    {spot_size_max_x spot_size_max_y} {} \
	    -image ::img::spot_size16x16 \
	    -balloonhelp "Spot size limit (\u221d median size)" \
	    -type "real" \
	    -precision "2" \
	    -allowblank "0" \
	    -minimum "1.00" \
	    -maximum 10.00 \
	    -defaultvalue "10.00" \
	    -width 4 \
	    -justify right \
	    -state normal
    }

    itk_component add peak_sep_x_e {
        SettingEntry $itk_component(spotfinding_toolbar).psxe spot_separation_x \
	    -image ::img::spot_sep_x16x16 \
	    -balloonhelp "Min spot separation in x" \
	    -type real \
	    -precision 2 \
	    -maximum 10.00 \
	    -minimum 0.00 \
	    -width 4 \
	    -justify right 
    }

    itk_component add peak_sep_y_e {
        SettingEntry $itk_component(spotfinding_toolbar).psye spot_separation_y \
	    -image ::img::spot_sep_y16x16 \
	    -balloonhelp "Min spot separation in y" \
	    -type real \
	    -precision 2 \
	    -maximum 10.00 \
	    -minimum 0.00 \
	    -width 4 \
	    -justify right 
    }

    
    itk_component add splitting_e {
	MultiSettingEntry $itk_component(spotfinding_toolbar).split_e \
	    {spot_splitting_x spot_splitting_y} {} \
	    -image ::img::splitting16x16 \
	    -balloonhelp "Max within-spot peak separation (splitting)" \
	    -type real \
	    -precision 2 \
	    -allowblank 0 \
	    -defaultvalue "0.00" \
	    -maximum 1.00 \
	    -minimum 0.00 \
	    -width 4 \
	    -justify right \
	    -state normal
    }

    itk_component add indexing_toolbar {
	frame [.c component toolbar_frame].indexing
    }

    # Divider

    itk_component add indexing_divider1 {
	frame $itk_component(indexing_toolbar).div1 \
	    -width 2 \
	    -relief sunken \
	    -bd 1
    }

    # Toolbuttons
    
    itk_component add i_sig_i_e {
        SettingEntry $itk_component(indexing_toolbar).isie i_sig_i \
	    -image ::img::res_cutoff16x16 \
	    -balloonhelp "I/sig(i) threshold for including spots in indexing" \
	    -type "real" \
	    -width "4" \
	    -minimum "0" \
	    -justify right \
	    -state normal \
		-editcommand [code .c uncheckAutothreshCheckbutton]
    }

    itk_component add exclude_ice_tb {
	SettingToolbutton $itk_component(indexing_toolbar).eitb "exclude_ice" \
	    -image ::img::exclude_ice16x16 \
	    -activeimage ::img::exclude_ice_on16x16 \
	    -balloonhelp "Exclude ice rings during spot finding"
    }

    itk_component add exclude_auto_tb {
	SettingToolbutton $itk_component(indexing_toolbar).eatb "exclude_auto" \
	    -image ::img::exclude_auto16x16 \
	    -activeimage ::img::exclude_auto_on16x16 \
	    -balloonhelp "Exclude any spot rings during indexing"
    }

    itk_component add fix_distance_tb {
	SettingToolbutton $itk_component(indexing_toolbar).fdtb "fix_distance_indexing" \
	    -image ::img::fix_distance16x16 \
	    -activeimage ::img::fix_distance_on16x16 \
	    -balloonhelp "Fix distance during indexing"
    }

    itk_component add fix_cell_tb {
	SettingToolbutton $itk_component(indexing_toolbar).fctb "fix_cell_indexing" \
	    -image ::img::fix_cell16x16 \
	    -activeimage ::img::fix_cell_on16x16 \
	    -balloonhelp "Fix cell during indexing"
    }

    itk_component add fix_max_cell_edge_tb {
	SettingToolbutton $itk_component(indexing_toolbar).fmcetb "fix_max_cell_edge" \
	    -image ::img::fix_max_cell_edge16x16 \
	    -activeimage ::img::fix_max_cell_edge_on16x16 \
	    -balloonhelp "Fix the maximum cell edge"
    }

    itk_component add cell_edge_e {
        SettingEntry $itk_component(indexing_toolbar).mce max_cell_edge \
	    -image ::img::max_cell_edge16x16 \
	    -balloonhelp "Max cell edge" \
	    -type "int" \
	    -width 4 \
	    -minimum "0" \
	    -maximum "9999" \
	    -justify right \
	    -state normal \
	    -linkcommand [code $this fixMaxCellEdge]
    }

    itk_component add sigma_cutoff_e {
        SettingEntry $itk_component(indexing_toolbar).sce sigma_cutoff \
	    -image ::img::sigma16x16 \
	    -balloonhelp "Sigma cutoff during refinement" \
	    -type "real" \
	    -precision "2" \
	    -allowblank 0 \
	    -defaultvalue "2.50" \
	    -minimum "0.00" \
	    -maximum "100.00" \
	    -width 4 \
	    -justify right \
	    -state normal 
    }

    # Heading

    itk_component add heading_f {
	frame $itk_interior.hf \
	    -bd 1 \
	    -relief solid
    }

    itk_component add heading_l {
	label $itk_interior.hf.fl \
	    -text "Autoindexing" \
	    -font title_font
    } {
	usual
	ignore -font
    }



    # Spot finding panel
    ##########################################################
    
    itk_component add spotfindingpanel {
	frame $itk_interior.sfp \
	    -borderwidth 0 \
	    -relief raised
    }

    itk_component add image_selection_f {
	frame $itk_interior.sfp.isf
    }

    itk_component add spotfindinglabel {
	label $itk_interior.sfp.isf.sfl \
	    -text "Images: "
    }

    itk_component add image_numbers {
	ImagenumbersSingle $itk_interior.sfp.isf.in \
	    -command [code $this chooseImages]
    }

    itk_component add single_image_button {
	Toolbutton $itk_interior.sfp.isf.sib \
	    -type "amodal" \
	    -image ::img::single_image24x24 \
	    -disabledimage ::img::single_image_disabled24x24 \
	    -command [code $this pickFirstImage] \
	    -balloonhelp " Pick first image "
    }
    
    itk_component add ninety_degrees_button {
	Toolbutton $itk_interior.sfp.isf.ndb \
	    -type "amodal" \
	    -image ::img::two_images24x24 \
	    -disabledimage ::img::two_images_disabled24x24 \
	    -command [code $this pickNinetyDegreeImages] \
	    -balloonhelp " Pick two images ~90\u00b0 apart "
    }
    
    itk_component add spotfinding_palette_tb {
	Toolbutton $itk_interior.sfp.isf.sptb \
	    -image ::img::many_images24x24 \
	    -disabledimage ::img::many_images_disabled24x24 \
	    -type "modal" \
	    -state "normal" \
	    -balloonhelp " Select images... "
    }

    itk_component add add_spots_tb {
	Toolbutton $itk_interior.sfp.isf.aspf \
	    -image ::img::openfile24x24trans \
	    -balloonhelp "Read spots file..." \
	    -command [code .c addSpots]
    }

    itk_component add spotfinding_palette {
	SpotfindingPalette .sfp \
	    -alignwidget $itk_component(spotfindinglabel)
    } { }

     $itk_component(spotfinding_palette_tb) configure \
 	-command [list $itk_component(spotfinding_palette) launch $itk_component(spotfinding_palette_tb)]	    

    itk_component add tree_frame {
	frame $itk_interior.sfp.tf
    }


    itk_component add image_tree {
	treectrl $itk_interior.sfp.tf.itree \
	    -showroot 0 \
	    -showline 0 \
	    -showbutton 0 \
	    -selectmode single \
	    -width 430 \
	    -height 72 \
	    -itemheight 18
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    }

    $itk_component(image_tree) column create -text "Image" -justify left -minwidth 80 -expand 1
    $itk_component(image_tree) column create -text "\u03c6" -justify left -minwidth 120 -expand 1
    $itk_component(image_tree) column create -text "Auto" -justify center -minwidth 60 -expand 1 
    $itk_component(image_tree) column create -text "Manual" -justify center -minwidth 60 -expand 1
    $itk_component(image_tree) column create -text "Deleted" -justify center -minwidth 60 -expand 1
    $itk_component(image_tree) column create -text "> I/\u03c3(I)" -justify center -minwidth 80 -expand 1
    $itk_component(image_tree) column create -text "Search"  -justify center -minwidth 60 -tag search
    $itk_component(image_tree) column create -text "Use"  -justify center -minwidth 30 -tag use

    $itk_component(image_tree) state define CHECKED
    $itk_component(image_tree) state define AVAILABLE

    $itk_component(image_tree) element create e_icon image -image ::img::image
    $itk_component(image_tree) element create e_text text -fill {white selected}
    $itk_component(image_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
    $itk_component(image_tree) element create e_auto_search image -image { ::img::spot_search_auto {} }
    $itk_component(image_tree) element create e_check image -image { ::img::embed_check_on {CHECKED AVAILABLE} ::img::embed_check_off {AVAILABLE !CHECKED} ::img::embed_check_off_disabled {!AVAILABLE} }
	
    $itk_component(image_tree) style create s1
    $itk_component(image_tree) style elements s1 { e_highlight e_icon e_text }
    $itk_component(image_tree) style layout s1 e_icon -expand ns -padx {0 6}
    $itk_component(image_tree) style layout s1 e_text -expand ns
    $itk_component(image_tree) style layout s1 e_highlight -union [list e_icon e_text] -iexpand nse -ipadx 2
    
    $itk_component(image_tree) style create s2
    $itk_component(image_tree) style elements s2 {e_highlight e_text}
    $itk_component(image_tree) style layout s2 e_text -expand ns
    $itk_component(image_tree) style layout s2 e_highlight -union [list e_text] -iexpand nsew -ipadx 2

    $itk_component(image_tree) style create s3
    $itk_component(image_tree) style elements s3 {e_highlight e_auto_search }
    $itk_component(image_tree) style layout s3 e_highlight -union [list e_auto_search] -iexpand nsew -ipadx 2
    $itk_component(image_tree) style layout s3 e_auto_search -expand ns -padx {2 2}

    $itk_component(image_tree) style create s4
    $itk_component(image_tree) style elements s4 {e_highlight e_check}
    $itk_component(image_tree) style layout s4 e_highlight -union [list e_check] -iexpand nsew -ipadx 2
    $itk_component(image_tree) style layout s4 e_check -expand ns -padx {2 2}

    bind $itk_component(image_tree) <ButtonPress-1> [code $this imageTreeClick %W %x %y]
    bind $itk_component(image_tree) <Double-ButtonPress-1> [code $this imageTreeDoubleClick %W %x %y]
    bind $itk_component(image_tree) <ButtonRelease-1> { break }
    bind $itk_component(image_tree) <Motion> [code $this imageTreeRollover %W %x %y]

    itk_component add image_scroll {
	scrollbar $itk_interior.sfp.tf.iscroll \
	    -command [code $this component image_tree yview] \
	    -orient vertical
    }
    
    $itk_component(image_tree) configure \
	-yscrollcommand [list autoscroll $itk_component(image_scroll)]

    # Set up selection binding
    $itk_component(image_tree) notify bind $itk_component(image_tree) <Selection> [code $this toggleImageSelection %S %D] 

    itk_component add total_tree {
	treectrl $itk_interior.sfp.tf.ttree \
	    -showheader 0 \
	    -showroot 1 \
	    -showline 0 \
	    -showbutton 0 \
	    -selectmode single \
	    -width 430 \
	    -height 22 \
	    -itemheight 18
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    }

    $itk_component(total_tree) column create -text Image -justify left -minwidth 80 -expand 1 ;#-itembackground {"\#ffffff" "\#e8e8e8"}
    $itk_component(total_tree) column create -text "\u03c6" -justify left -minwidth 120 -expand 1
    $itk_component(total_tree) column create -text "Auto" -justify center -minwidth 60 -expand 1 
    $itk_component(total_tree) column create -text "Manual" -justify center -minwidth 60 -expand 1
    $itk_component(total_tree) column create -text "Deleted" -justify center -minwidth 60 -expand 1
    $itk_component(total_tree) column create -text "> I/\u03c3(I)" -justify center -minwidth 80 -expand 1
    $itk_component(total_tree) column create -text "Search"  -justify center -minwidth 60 -tag search
    $itk_component(total_tree) column create -text "Use"  -justify center -minwidth 30 -tag use

    $itk_component(total_tree) element create e_icon image -image ::img::spotlist
    $itk_component(total_tree) element create e_text text -fill {white selected}
    $itk_component(total_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
	
    $itk_component(total_tree) style create s1
    $itk_component(total_tree) style elements s1 { e_highlight e_icon e_text }
    $itk_component(total_tree) style layout s1 e_icon -expand ns -padx {0 6}
    $itk_component(total_tree) style layout s1 e_text -expand ns
    $itk_component(total_tree) style layout s1 e_highlight -union [list e_icon e_text] -iexpand nse -ipadx 2
    
    $itk_component(total_tree) style create s2
    $itk_component(total_tree) style elements s2 {e_highlight e_text}
    $itk_component(total_tree) style layout s2 e_text -expand ns
    $itk_component(total_tree) style layout s2 e_highlight -union [list e_text] -iexpand nsew -ipadx 2

    $itk_component(total_tree) item style set root 0 s1 1 s2 2 s2 3 s2 4 s2 5 s2 6 s2 7 s2
    $itk_component(total_tree) item text root 0 "Total" 1 "" 2 0 3 0 4 0 5 0
    

    itk_component add spotselectionlabel {
	label $itk_interior.sfp.ssl \
	    -text "Spots:"
    }

    itk_component add spotselectionframe {
	frame $itk_interior.sfp.ssf \
	    -bd 2 \
	    -relief sunken
    } {
	usual
	rename -background -textbackground textBackground Background
    }

    itk_component add spotcanvas {
	canvas $itk_interior.sfp.ssf.spotcanvas \
	    -width 200 \
	    -height 200 \
	    -borderwidth 0 \
	    -relief solid \
	    -highlightthickness 0
    } {
	usual
	rename -background -textbackground textBackground Background
    }

    itk_component add index_button {
	button $itk_interior.sfp.ib \
	    -text "Index" \
	    -width 7 \
	    -padx 0 \
	    -pady 2 \
	    -command [code $this queueAutoindex]
    }

    # Solutions panel
    ##########################################################
    
    itk_component add solutionspanel {
	frame $itk_interior.slp \
	    -borderwidth 0 \
	    -relief raised
    }

    itk_component add solutionslabel {
	    label $itk_interior.slp.solutionslabel \
		-text "Solutions:"
    }
    
    itk_component add searchlabel {
	    label $itk_interior.slp.searchlabel \
		-text "Re-try:"
    }

    itk_component add searchtype_combo {
	Combo $itk_interior.slp.searchtype_combo \
	    -width 15 \
	    -items {"select option" beam-centre "higher I/sigma(I)" "lower I/sigma(I)"} \
	    -editable 0 -highlightcolor black \
	    -textvariable [scope searchtype]
    } {
	usual
	ignore -textbackground -foreground
    }

    itk_component add beamsearchlabel {
	    label $itk_interior.slp.bsl \
		-text "Search beam-centre"
    }

    itk_component add beamsearchexpander {
	    label $itk_interior.slp.bse \
		-text "\[+\]"
    }

    itk_component add beamsearch_tree {
	    treectrl $itk_interior.slp.bstree \
		    -showline 0 \
		-showbutton 1 \
		-selectmode single \
		-width 670 \
		-height 150
    } {
	    rename -background -textbackground textBackground Background
	    rename -font -entryfont entryFont Font
    }

    $itk_component(beamsearch_tree) column create -text "Beam x" -tag start_beamx -justify center -minwidth 40 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(beamsearch_tree) column create -text "Beam y" -tag start_beamy -justify center -minwidth 40 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(beamsearch_tree) column create -text "Beam x ref" -tag ref_beamx -justify center -minwidth 40 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(beamsearch_tree) column create -text "Beam y ref" -tag ref_beamy -justify center -minwidth 40 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1

    $itk_component(beamsearch_tree) column create -text "a" -tag a -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(beamsearch_tree) column create -text "b" -tag b -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(beamsearch_tree) column create -text "c" -tag c -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(beamsearch_tree) column create -text "\u03b1" -tag alpha -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1
    $itk_component(beamsearch_tree) column create -text "\u03b2" -tag beta -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1
    $itk_component(beamsearch_tree) column create -text "\u03b3" -tag gamma -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1
    $itk_component(beamsearch_tree) column create -text "\u03c3(x,y)" -tag sigma_xy -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1
    $itk_component(beamsearch_tree) column create -text "\u03c3(\u03c6)" -tag sigma_phi -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1
    $itk_component(beamsearch_tree) column create -text "\u03b4 beam" -tag delta_beam -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1

    $itk_component(beamsearch_tree) configure -treecolumn 0

    $itk_component(beamsearch_tree) element create e_text text -fill {white selected}
    $itk_component(beamsearch_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }

    $itk_component(beamsearch_tree) style create s2
    $itk_component(beamsearch_tree) style elements s2 {e_highlight e_text}
    $itk_component(beamsearch_tree) style layout s2 e_text -expand ns
    $itk_component(beamsearch_tree) style layout s2 e_highlight -union [list e_text] -iexpand nsew -ipadx 2

    bind $itk_component(beamsearch_tree) <Double-ButtonPress-1> [code $this beamTreeDoubleClick %W %x %y]
	
    itk_component add solution_tree {
	treectrl $itk_interior.slp.stree \
	    -showline 0 \
	    -showbutton 1 \
	    -selectmode single \
	    -width 670 \
	    -height 200
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    }

    $itk_component(solution_tree) notify bind $itk_component(solution_tree) <Selection> [code $this toggleSolution %c %S]

    $itk_component(solution_tree) column create -text Solution -tag solution -justify left -minwidth 100 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(solution_tree) column create -text Lat. -tag lattice -justify center -minwidth 40 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(solution_tree) column create -text Pen. -tag penalty -justify center -minwidth 40 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(solution_tree) column create -text "a" -tag a -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(solution_tree) column create -text "b" -tag b -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(solution_tree) column create -text "c" -tag c -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(solution_tree) column create -text "\u03b1" -tag alpha -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1
    $itk_component(solution_tree) column create -text "\u03b2" -tag beta -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1
    $itk_component(solution_tree) column create -text "\u03b3" -tag gamma -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1
    $itk_component(solution_tree) column create -text "\u03c3(x,y)" -tag sigma_xy -justify center -minwidth 55 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1
    $itk_component(solution_tree) column create -text "\u03c3(\u03c6)" -tag sigma_phi -justify center -minwidth 55 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1
    $itk_component(solution_tree) column create -text "\u03b4 beam" -tag delta_beam -justify center -minwidth 90 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1

    $itk_component(solution_tree) configure -treecolumn 0

    $itk_component(solution_tree) element create e_icon image -image ::img::raw_solution
    $itk_component(solution_tree) element create e_text text -fill {white selected}
    $itk_component(solution_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
	
    $itk_component(solution_tree) style create s1
    $itk_component(solution_tree) style elements s1 { e_highlight e_icon e_text }
    $itk_component(solution_tree) style layout s1 e_icon -expand ns -padx {0 6} -pady {1 1}
    $itk_component(solution_tree) style layout s1 e_text -expand ns
    $itk_component(solution_tree) style layout s1 e_highlight -union [list e_text] -iexpand nse -ipadx 2
    
    $itk_component(solution_tree) style create s2
    $itk_component(solution_tree) style elements s2 {e_highlight e_text}
    $itk_component(solution_tree) style layout s2 e_text -expand ns
    $itk_component(solution_tree) style layout s2 e_highlight -union [list e_text] -iexpand nsew -ipadx 2
    
    bind $itk_component(solution_tree) <Double-ButtonPress-1> [code $this doubleClickSolution %W %x %y]

    itk_component add solutionsscrollbar {
	scrollbar $itk_interior.slp.solutionsscrollbar \
	    -command [code $this component solution_tree yview] \
	    -orient vertical
    }
    
    itk_component add beamsearchscrollbar {
	scrollbar $itk_interior.slp.beamsearchscrollbar \
	    -command [code $this component beamsearch_tree yview] \
	    -orient vertical
    }

    $itk_component(solution_tree) configure \
	-yscrollcommand [code $this component solutionsscrollbar set]
    
    $itk_component(beamsearch_tree) configure \
	-yscrollcommand [code $this component beamsearchscrollbar set]

    itk_component add spacegroupslabel {
	    label $itk_interior.slp.spacegroupslabel \
		-text "Spacegroup: "
    }
   
    itk_component add spacegroupcombo {
	combobox::combobox $itk_interior.slp.spacegroupcombo \
	    -width 8 \
	    -editable 1 \
	    -highlightcolor black \
	    -command [code $this toggleSpacegroup]
    } {
	keep -background -cursor -foreground -font
	keep -selectbackground -selectborderwidth -selectforeground
	keep -highlightcolor -highlightthickness
	rename -highlightbackground -background background Background
	rename -background -textbackground textBackground Background
    }

    itk_component add mosaicity_l {
	label $itk_interior.slp.ml \
	    -text "Mosaicity: "
    }

    itk_component add mosaicity_e {
	SettingEntry $itk_interior.slp.me mosaicity \
	    -image ::img::mosaicity \
	    -type real \
	    -precision 2 \
	    -width 8 \
	    -minimum 0 \
	    -maximum 10 \
	    -justify right
    }

    itk_component add mosaicity_estimate_b {
	button $itk_interior.slp.meb \
	    -text "Estimate" \
	    -width 7 \
	    -pady 2 \
	    -command [code $this estimateMosaicity] \
	    -state disabled
    }

    # Spotfinding Toolbar
    pack $itk_component(spotfinding_divider1) \
	-side left \
	-fill y \
	-padx 2 \
	-pady 1

    pack $itk_component(add_spots_tb) \
	-side left \
	-fill y \
	-padx 2 \
	-pady 1

    pack $itk_component(beam_x_e) $itk_component(beam_y_e) $itk_component(distance_e) -side left -padx 2

    pack $itk_component(spotfinding_divider2) \
	-side left \
	-fill y \
	-padx 2 \
	-pady 1

    pack $itk_component(threshold_e) $itk_component(spot_size_e) $itk_component(peak_sep_x_e) $itk_component(peak_sep_y_e) $itk_component(splitting_e) $itk_component(exclude_ice_tb) \
 	-side left \
	-padx 2

    # Indexing Toolbar
    pack $itk_component(indexing_divider1) \
	-side left \
	-fill y \
	-padx 2 \
	-pady 1

    pack $itk_component(i_sig_i_e) $itk_component(exclude_auto_tb) $itk_component(fix_distance_tb) $itk_component(fix_cell_tb) $itk_component(fix_max_cell_edge_tb) $itk_component(cell_edge_e) $itk_component(sigma_cutoff_e) \
 	-side left \
	-padx 2

    # Heading
    pack $itk_component(heading_f) -side top -fill x -padx 7 -pady {7 0}
    pack $itk_component(heading_l) -side left -padx 5 -pady 5

    # Panels
    # pack the button panel only, the other panels will be packed
    # and unpacked according to other events
    ###############################################################

    # Frames
    pack $itk_component(spotfindingpanel) -side top -fill both -pady [list $margin 0]
    pack $itk_component(solutionspanel) -side top -fill both -expand 1 -pady [list 0 $margin]

    # Spot finding panel
    ###############################################################
	
    grid x $itk_component(image_selection_f) x $itk_component(index_button) x -sticky we
    grid x $itk_component(tree_frame) x $itk_component(spotselectionframe) x -sticky nswe
    grid columnconfigure $itk_component(spotfindingpanel) { 0 2 4 } -minsize $margin
    grid columnconfigure $itk_component(spotfindingpanel) { 1 } -weight 1
    grid rowconfigure $itk_component(spotfindingpanel) { 2 } -weight 1

    pack $itk_component(spotfindinglabel) -side left -anchor n -pady 10
    pack $itk_component(image_numbers) -side left -fill x -expand 1 -anchor n -pady 6
    pack $itk_component(add_spots_tb) $itk_component(spotfinding_palette_tb) $itk_component(ninety_degrees_button) \
	$itk_component(single_image_button) -side right -anchor n

    grid $itk_component(image_tree) $itk_component(image_scroll) -sticky nswe
    grid $itk_component(total_tree) ^ -sticky nswe
    grid columnconfigure $itk_component(tree_frame) { 0 } -weight 1
    grid rowconfigure $itk_component(tree_frame) { 0 } -weight 1

    grid $itk_component(spotcanvas) -sticky nswe
    grid columnconfigure $itk_component(spotselectionframe) { 0 } -weight 1
    grid rowconfigure $itk_component(spotselectionframe) { 0 }  -weight 1
    
    # Solutions panel
    ###############################################################
        
    grid x $itk_component(solutionslabel) - - - x -sticky w
    grid x $itk_component(solution_tree) - - $itk_component(solutionsscrollbar) x -sticky nswe
    grid x $itk_component(beamsearch_tree) - - $itk_component(beamsearchscrollbar) x -sticky nswe
#   grid x $itk_component(searchtype_combo) x -sticky w
    grid x $itk_component(spacegroupslabel) $itk_component(spacegroupcombo) -sticky we
    grid x x x $itk_component(beamsearchlabel) $itk_component(beamsearchexpander) -row 3 -sticky e
    grid x $itk_component(mosaicity_l) $itk_component(mosaicity_e) $itk_component(mosaicity_estimate_b) -sticky w

    grid columnconfigure $itk_component(solutionspanel) {0 5} -minsize $margin
    grid columnconfigure $itk_component(solutionspanel) 3 -weight 1
    grid rowconfigure $itk_component(solutionspanel) 1 -weight 1
    grid remove $itk_component(beamsearch_tree)
    grid remove $itk_component(beamsearchscrollbar)

    bind $itk_component(beamsearchlabel) <ButtonPress-1> [code $this beamSearchLaunch]
    bind $itk_component(beamsearchexpander) <ButtonPress-1> [code $this toggleBeamSearchTable]

    eval itk_initialize $args

}

# Launch and completion methods #####################################

body Indexwizard::launch { } {

    if {[.ats component indexing getAutoindexingRelayBool]} {
	trace add variable [scope index_workflow] write "indexingRelay"
	trace add variable [scope mosaicity_workflow] write "mosaicityRelay"
    } else {
	trace remove variable [scope index_workflow] write "indexingRelay"
	trace remove variable [scope mosaicity_workflow] write "mosaicityRelay"
    }
    # Show stage
    grid $itk_component(hull) -row 0 -column 1 -sticky nswe

    # show toolbars
    pack $itk_component(spotfinding_toolbar) -in [.c component toolbar_frame] -side left
    pack $itk_component(indexing_toolbar) -in [.c component toolbar_frame] -side left

    $itk_component(spot_size_e) update
    $itk_component(splitting_e) update

    # if no images are selected...
    if {$images_list == {}} {
	# and no spot search is taking place...
	if {![$::mosflm busy "spot_finding"]} {
	    if {[.ats component spotfinding getSpotfindingRelayBool]} {
		# pick two 90 degrees apart
		$itk_component(ninety_degrees_button) invoke
	    } else {
		#no images in box, not busy spot finding & not searching for two reference images
		$itk_component(index_button) configure -state disabled
	    }
	}
    }	
}

body Indexwizard::indexingRelay {name1 name2 ops} {
    #puts "Called indexingRelay \"$name1\" \"$name2\" \"$ops\" IndexingRelayBool [$::session getIndexingRelayBool]"
    if {[$::session getIndexingRelayBool] == 0} {
	queueAutoindex
	$::session setIndexingRelayBool "1"
	#puts "IndexingRelayBool [$::session getIndexingRelayBool]"
    }
}

body Indexwizard::mosaicityRelay {name1 name2 ops} {
    if {[$::session getMosaicityRelayBool] == 0} {
	estimateMosaicity
	$::session setMosaicityRelayBool "1"
    }
}

body Indexwizard::hide { } {

    grid forget $itk_component(hull)
    pack forget $itk_component(spotfinding_toolbar) 
    pack forget $itk_component(indexing_toolbar) 
}

body Indexwizard::clear { } {
    # clear image numbers
    $itk_component(image_numbers) clear
    # delete tree items
    $itk_component(image_tree) item delete all
    $itk_component(solution_tree) item delete all
    $itk_component(total_tree) item text root 0 "Total" 1 0 2 0 3 0 4 0
    # clear associated arrays
    array unset images_list *
    array unset image_objects_by_number *
    array unset image_objects_by_item *
    array unset image_items_by_number *
    array unset image_items_by_object *
    array unset solution_objects_by_number *
    array unset solution_items_by_number *
    array unset solution_numbers_by_item *
    array unset solution_objects_by_item *
    array unset solution_item_types *
    # clear the spot summary canvas
    $itk_component(spotcanvas) delete all
    # clear the spacegroup
    $itk_component(spacegroupcombo) delete 0 end
    # clear the spacegroup combobox's list and disable it
    $itk_component(spacegroupcombo) list delete 0 end
    $itk_component(spacegroupcombo) configure \
	-state disabled
}

# Disabling / enabling ###############################
body Indexwizard::protrial {name1 name2 ops} {
    if {$index_done == 0} {
	queueAutoindex
	set index_done 1
    }
}

body Indexwizard::promosaicity {name1 name2 ops} {
    if {$mosaicity_done == 0} {
	estimateMosaicity
	set mosaicity_done 1
    }
}

body Indexwizard::trial {} {
#	trace add variable [scope index_workflow] write "$this protrial"
#	trace add variable [scope mosaicity_workflow] write "$this promosaicity"
    launch
}

body Indexwizard::disable { } {
    toggleAbility disabled
}

body Indexwizard::enable { } {
    toggleAbility normal
    updateIndexButton
    updateMosaicityButton
    $itk_component(beamsearchlabel) configure -fg \#000000
    if {![set grid_search]} {
	bind $itk_component(beamsearchlabel) <ButtonPress-1> [code $this beamSearchLaunch]
    }
}

body Indexwizard::toggleAbility { a_state } {
    $itk_component(index_button) configure -state $a_state
    $itk_component(image_numbers) configure -state $a_state
    $itk_component(single_image_button) configure -state $a_state
    $itk_component(ninety_degrees_button) configure -state $a_state
    $itk_component(spotfinding_palette_tb) configure -state $a_state
    $itk_component(spacegroupcombo) configure -state $a_state
    $itk_component(mosaicity_estimate_b) configure -state $a_state
}

# #########################

body Indexwizard::addImage { an_image } {

    # Only add if it isn't already there!
    if {![info exists image_items_by_object($an_image)]} {
	#puts "addImage: item for image object $an_image does not exist"
	# Choose labelling method depending on number of templates
	if {[llength [$::session getSectors]] > 1} {
	    set l_labelMethod "getShortName"
	} else {
	    set l_labelMethod "getNumber"
	}

	# create a new item
	set t_item [$itk_component(image_tree) item create]
	# set the item's style
	$itk_component(image_tree) item style set $t_item 0 s1 1 s2 2 s2 3 s2 4 s2 5 s2 6 s3 7 s4
	# get the label to be used
	set l_label [$an_image $l_labelMethod]
	# update the text summaries
	$itk_component(image_tree) item text $t_item 0 $l_label 
	$itk_component(image_tree) item text $t_item 1 [$an_image reportPhis -mode "range"]
	# Set state to indicate spots are available from this image (and checked)
	$itk_component(image_tree) item state set $t_item [list AVAILABLE CHECKED]
	# add the new item to the tree
	$itk_component(image_tree) item lastchild root $t_item
	# Store pointer to image objects and items by number, item or object
	set image_objects_by_number([$an_image getNumber]) $an_image
	set image_objects_by_item($t_item) $an_image
	set image_items_by_number([$an_image getNumber]) $t_item
	set image_items_by_object($an_image) $t_item
    } else {
	#puts "addImage: image_items_by_object($an_image) $image_items_by_object($an_image)"
    }

    # Update the spot finding results
    updateSpotFindingResult $an_image

    # check for inclusion in the palette
    $itk_component(spotfinding_palette) checkImage $an_image

    # update the spot summary
    updateSpotSummary

    # Update summary labels
    updateImageNumbers

}

body Indexwizard::removeImage { an_image } {

    #puts "removeImage $an_image"
    # Delete item from tree
    $itk_component(image_tree) item delete $image_items_by_object($an_image)

    #puts "removeImage - unsetting the following:"
    #puts "image_objects_by_number([$an_image getNumber]) $image_objects_by_number([$an_image getNumber])"
    #puts "image_objects_by_item($image_items_by_object($an_image)) $image_objects_by_item($image_items_by_object($an_image))"
    #puts "image_items_by_number([$an_image getNumber]) $image_items_by_number([$an_image getNumber])"
    #puts "image_items_by_object($an_image) $image_items_by_object($an_image)"

    # clear array entries
    array unset image_objects_by_number [$an_image getNumber]
    array unset image_objects_by_item $image_items_by_object($an_image)
    array unset image_items_by_number [$an_image getNumber]
    array unset image_items_by_object $an_image

    #puts "array names image_items_by_number [array names image_items_by_number]"
    #puts "array names image_items_by_object [array names image_items_by_object]"

    # uncheck in palette
    $itk_component(spotfinding_palette) uncheckImage $an_image

    # Update the spot summary
    updateSpotSummary
    # Update summary labels
    updateImageNumbers

}

body Indexwizard::getIncludedImages { } {
    return [array names image_items_by_object]
}

body Indexwizard::updateTotal { } {
    set l_auto 0
    set l_manual 0
    set l_deleted 0
    set l_total 0
    foreach i_image [array names image_items_by_object] {
	set l_spotlist [$i_image getSpotlist]
	incr l_auto [format %3d [$l_spotlist getAuto]]
	incr l_manual [format %3d [$l_spotlist getManual]]
	incr l_deleted [format %3d [$l_spotlist getDeleted]]
	incr l_total [format %3d [$l_spotlist getTotalAboveIsigi]]
    }
    $itk_component(total_tree) item text root 1 "" 2 $l_auto 3 $l_manual 4 $l_deleted 5 $l_total 

    #if not spot finding...
    if {![$::mosflm busy "spot_finding"]} {
	# Update index button if enough spots are selected
	updateIndexButton
    }
}

body Indexwizard::checkSpotlistInclusion { an_item } {
    # if the spotlist is not available and unchecked don't bother!
    if {(![$itk_component(image_tree) item state get $an_item AVAILABLE]) } {
	#puts "Item $an_item is not available for inclusion"
	return
    }
    if {[$itk_component(image_tree) item state get $an_item CHECKED]} {
	#puts "Item $an_item is already checked & included"
	return
    }
    # get the item's label
    set l_label [$itk_component(image_tree) item text $an_item 0]
    # make the item  cheked...
    $itk_component(image_tree) item state set $an_item CHECKED
    # pick colour according to selectedness
    if {[$itk_component(image_tree) item state get $an_item selected]} {
	set l_colour_over "blue"
	set l_colour_under "green"
    } else {
	set l_colour_over "red"
	set l_colour_under "gold"
    } 
    # Show spots in canvas 
    $itk_component(spotcanvas) itemconfigure "auto_over$l_label" -image ::img::spot_${l_colour_over}_plus3x3
    $itk_component(spotcanvas) itemconfigure "manual_over$l_label" -image ::img::spot_${l_colour_under}_cross3x3
    $itk_component(spotcanvas) itemconfigure "auto_under$l_label" -image ::img::spot_${l_colour_over}_plus3x3
    $itk_component(spotcanvas) itemconfigure "manual_under$l_label" -image ::img::spot_${l_colour_under}_cross3x3
    $itk_component(spotcanvas) raise "all$l_label"
    # Update summary labels
    updateImageNumbers
}

body Indexwizard::uncheckSpotlistInclusion { an_item } {
    # if the spotlist is not available and checked don't bother!
    if {(![$itk_component(image_tree) item state get $an_item AVAILABLE])} { return }
    if {(![$itk_component(image_tree) item state get $an_item CHECKED])} { return }
    # remove item from tree
    #puts "$this remove item $an_item from tree"
    removeImage $image_objects_by_item($an_item)
}


body Indexwizard::toggleSpotlistInclusion { an_item } {
    set choosing_images 0
    if {[$itk_component(image_tree) item state get $an_item CHECKED]} {
	uncheckSpotlistInclusion $an_item
    } else {
	checkSpotlistInclusion $an_item
    }
}

body Indexwizard::toggleImageSelection { a_selected { a_deselected "" } } {
    # if the selected item is checked...
    if {($a_selected != "") && [$itk_component(image_tree) item state get $a_selected CHECKED]} {
	# get its label
	set l_label [$itk_component(image_tree) item text $a_selected 0]
	# colour its spots
	$itk_component(spotcanvas) itemconfigure "auto_over$l_label" -image ::img::spot_blue_plus3x3
	$itk_component(spotcanvas) itemconfigure "manual_over$l_label" -image ::img::spot_blue_cross3x3
	$itk_component(spotcanvas) itemconfigure "auto_under$l_label" -image ::img::spot_green_plus3x3
	$itk_component(spotcanvas) itemconfigure "manual_under$l_label" -image ::img::spot_green_cross3x3
	# raise them
	$itk_component(spotcanvas) raise "all$l_label"
    }
    # if the deselected item is checked...
    if {($a_deselected != "") && [$itk_component(image_tree) item state get $a_deselected CHECKED]} {
	# get its label
	set l_label [$itk_component(image_tree) item text $a_deselected 0]
	# colour its spots black
	$itk_component(spotcanvas) itemconfigure "auto_over$l_label" -image ::img::spot_red_plus3x3
	$itk_component(spotcanvas) itemconfigure "manual_over$l_label" -image ::img::spot_red_cross3x3
	$itk_component(spotcanvas) itemconfigure "auto_under$l_label" -image ::img::spot_gold_plus3x3
	$itk_component(spotcanvas) itemconfigure "manual_under$l_label" -image ::img::spot_gold_cross3x3
    }
}
    
body Indexwizard::imageTreeClick { w x y } {
    set id [$w identify $x $y]
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "header"} {
    } else {
	$w activate [$w index [list nearest $x $y]]
	foreach {what item where arg1 arg2 arg3} $id break
	if {[lindex $id 5] == "e_check"} {
	    #puts "toggleSpotlistInclusion $item"
	    toggleSpotlistInclusion $item
	} elseif {[lindex $id 5] == "e_auto_search"} {
	    set choosing_images "0"
	    findSpots $image_objects_by_item($item)
	}
    }
}

body Indexwizard::imageTreeDoubleClick { w x y } {
    set id [$w identify $x $y]
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "header"} {
    } else {
	foreach {what item where arg1 arg2 arg3} $id {}
	if {[lindex $id 5] == "e_auto_search"} {
	    set choosing_images "0"
	    findSpots $image_objects_by_item($item)
	} elseif {[lindex $id 5] == "e_check"} {
	    toggleSpotlistInclusion $item
	}
    }
}

body Indexwizard::beamTreeDoubleClick { w x y } {
    if {![set grid_search]} {
	set id [$w identify $x $y]
	if {$id eq ""} {
	} elseif {[lindex $id 0] eq "header"} {
	} else {
	    set beam_x_search [$itk_component(beamsearch_tree) item text [lindex $id 1] 2]
	    set beam_y_search [$itk_component(beamsearch_tree) item text [lindex $id 1] 3]
	    if {[string is double $beam_x_search] && [string is double $beam_y_search]} {
		$::session updateSetting beam_x $beam_x_search 1 1
		$::session updateSetting beam_y $beam_y_search 1 1
		$itk_component(index_button) invoke
	    }
	}
    }
}

body Indexwizard::buildImageTree { } {
    error "buildImageTree"
}

body Indexwizard::complete  { } {
    # Update client-side variables to reflect results

    # update the cell
    $::session updateCell "Indexing" [$chosen_solution getCell] 1 1 0

    # Get a list of sectors used
    set l_sectors_to_update {}
    foreach i_image $images_being_autoindexed {
	if {[lsearch $l_sectors_to_update [$i_image getSector]] < 0} {
	    lappend l_sectors_to_update [$i_image getSector]
	}
    }

    # update all used sectors with new matrix
    foreach i_sector $l_sectors_to_update {
	eval $i_sector updateMatrix "Indexing" [$chosen_solution getMatrix] 1 1 0
    }
    
    # update the spacegroup
    set l_spacegroup [namespace current]::[Spacegroup \#auto "initialize" "unnamed" [$itk_component(spacegroupcombo) get]]
    $::session updateSpacegroup "Indexing" $l_spacegroup 1 1 0
    delete object $l_spacegroup
    
    if {$mosaicity_has_been_set} {
	# Update the mosaicity
	$::session updateSetting mosaicity $mosaicity 1 1 "Indexing" 0
    }

    # if the solution was refined (so the beam was changed)...
    if {$chosen_solution_type == "ref"} {
	# update the beam position
	foreach { l_beam_x l_beam_y } [$chosen_solution getBeam] break
	$::session updateSetting beam_x $l_beam_x 1 1 "Indexing" 0
	$::session updateSetting beam_y $l_beam_y 1 1 "Indexing" 0
    }
    
    $::session updatePredictions

    hide
}

# Spot finding methods ##############################################

body Indexwizard::pickFirstImage { } {
    # Clear any currently checked items
    foreach i_image [array names image_items_by_object] {
	catch {removeImage $i_image}
    }
    # Get a list of images in the session and sort
    set imgnumlist {}
    
    set l_images [[$::session getCurrentSector] getImages]
    if {[llength $l_images] > 0} {
    # if there are any images to use...
	set a_template [[lindex $l_images 0] getTemplate]
	foreach i_image $l_images {
	    lappend imgnumlist [$i_image getNumber]
	}
	set imgnumsort [ lsort -integer $imgnumlist]
	# select the first image
	set first_num [lindex $imgnumsort 0]
	set first_image [$::session getImageByTemplateAndNumber $a_template $first_num]
	# If it's got a spotlist, just add it
	if {[$first_image getSpotlist] != ""} {
	    addImage $first_image
	} else {
	    # search for spots on the image
	    findSpots $first_image
	}
    }
}

body Indexwizard::pickNinetyDegreeImages { } {
    # Clear any currently checked items
    foreach i_image [array names image_items_by_object] {
	catch {removeImage $i_image}
	#puts "Checked image $i_image"
    }
    # Get a list of images in the session and sort
    set imgnumlist {}
    set l_images [[$::session getCurrentSector] getImages]
    #puts "Images:\n$l_images"
    if {[llength $l_images] > 0} {
    # if there are any images to use...
	set a_template [[lindex $l_images 0] getTemplate]
	foreach i_image $l_images {
	    lappend imgnumlist [$i_image getNumber]
	}
	#puts "Numbrs:\n$imgnumlist"
	set imgnumsort [ lsort -integer $imgnumlist]
	#puts "Sorted:\n$imgnumsort"
	# select the first image
	set first_num [lindex $imgnumsort 0]
	set first_image [$::session getImageByTemplateAndNumber $a_template $first_num]
	#puts "Image $first_num $first_image"
	# If it's got a spotlist, just add it
	if {[$first_image getSpotlist] != ""} {
	    addImage $first_image
	} else {
	    # search for spots on the image
	    findSpots $first_image
	}
	# Get phi start of first image
	foreach { l_phi_start l_phi_end } [$first_image getPhi] break
	set next_image ""
	set wedge 0.0
	if { $l_phi_end > $l_phi_start } {
	    set wedge [ expr $wedge + $l_phi_end - $l_phi_start]
	}
	# Loop through remaining images until the wedge >= 90 or we run out of images
	foreach num [lrange $imgnumsort 1 end] {
	    set next_image [$::session getImageByTemplateAndNumber $a_template $num]
		foreach { l_phi_start l_phi_end } [$next_image getPhi] break
		#puts "Image $num: Phi-start $l_phi_start - Phi-end $l_phi_end"
		if { $l_phi_end > $l_phi_start } {
		    # for simplicity skip counting if an image's phi values cross zero in phi
		    set wedge [ expr $wedge + $l_phi_end - $l_phi_start]
		}
		if { [expr $wedge >= 90.0] } {
		    #puts "Break at $next_image phi-start $l_phi_start wedge of $wedge degrees"
		    break
		}
	}
	# if we found an image >= 90 deg or the last in the list
	if {$next_image != ""} {
	    #puts "Image $num $next_image"
	    # If it's got a spotlist, just add it
	    if {[$next_image getSpotlist] != ""} {
		addImage $next_image
	    } else {
		# search for spots on the image
		#puts "Finding spots on image [$next_image getNumber]"
		findSpots $next_image
	    }
	} else {
	    #puts "Cannot find a second image"
	}
    } else {
    }
}

body Indexwizard::chooseImages { a_template a_num_list } {

    # Set flag to indicate image choosing is going on
    set choosing_images 1
    # Initialize list of images to search
    set l_chosen_image_numbers {}
    set chosen_search_images {}
    #puts "a_template $a_template a_num_list $a_num_list"
    # get the relevent sector 
    set l_sector [$::session getSectorByTemplate $a_template]
    #puts "l_sector is $l_sector"
    # Select numbers that match exisiting images
    foreach i_num $a_num_list {
	set l_image [$::session getImageByTemplateAndNumber $a_template $i_num]
	# image exists in session
	lappend l_chosen_image_numbers $i_num
    }
    # Update the image list entry
    $itk_component(image_numbers) updateSector $a_template [compressNumList $l_chosen_image_numbers]

    # Remove all previously included images from all sectors
    foreach i_image [array names image_items_by_object] {
	#puts "catch removal of $i_image"
	catch { removeImage $i_image }
    }

    # Should we trap too many images entered for spot finding ...
    set num_for_sptfdg [llength $l_chosen_image_numbers]
    #puts "$num_for_sptfdg images input for spot finding"

    # Loop through chosen image numbers
    foreach i_num $l_chosen_image_numbers {
	# get image
	set l_image [$::session getImageByTemplateAndNumber $a_template $i_num]
	# if image exists for this number - it could have been deleted in the Images pane
	if { $l_image != "" } {
	    #puts "$i_num. $l_image got by name and number from Session"
	    # if it has a spotlist already...
	    if {[$l_image getSpotlist] != ""} {
		# add the image
		#puts "calls addImage"
		addImage $l_image
	    } else {
		# otherwise, search the image
		#puts "calls findSpots"
		findSpots $l_image
	    }
	} else {
	    #puts "$i_num. l_image has no value"
	}
    } 
}

body Indexwizard::findSpots { an_image } {

    # disable controls
    disable

    # Keep list of images being list
    set images_being_searched [concat $images_being_searched $an_image]

    # Update the status indicators
    .c busy "Finding spots on image [$an_image getNumber]"
    
    # Tell mosflm to find spots on the picked images
    $::mosflm findspots $an_image
}

body Indexwizard::processSpotsFile { spots_file } {
    
    #puts "Session image height [$::session getImageHeight]"

    # Read the user's input file into a string
    set l_in_file [open $spots_file]
    set content [read $l_in_file]
    close $l_in_file
    
    # Split into records on newlines
    set records [split $content "\n"]

    # Make first spots list file name & handle
    set temp_spt [file join $::mosflm_directory "tmp[expr int(rand()*99999)].spt"]
    set l_out_file [open $temp_spt w]

    # Iterate over the records
    set penult 0
    foreach rec $records {
	#puts $rec
	puts $l_out_file $rec
	if { [string match *-99* $rec] > 0 } {
	    close $l_out_file
	    # then create the spot list object etc.
	    readSpotsFile $temp_spt
	    # Make a new file for the spots for the next phi_centre/image in the input file
	    set temp_spt [file join $::mosflm_directory "tmp[expr int(rand()*99999)].spt"]
	    set l_out_file [open $temp_spt w]
	}
    }
}

body Indexwizard::readSpotsFile { spots_file } {
    
    #puts "File $spots_file used for spot list"
    set new_spotlist [namespace current]::[Spotlist \#auto "file" [$::session getImageHeight] $spots_file]
    #puts "New spotlist object $new_spotlist"
    set num_new_spots [llength [$new_spotlist getSpots]]
    #puts "New spotlist has $num_new_spots spots"
    if { $num_new_spots == 0 } {
	.m confirm \
	    -type "1button" \
	    -title "No Spots Found" \
	    -text "No spots could be read from file." \
	    -button1of1 "Dismiss"
	delete object $new_spotlist
	return
    }
    set l_spotlist_phi [$new_spotlist getPhi]
    set l_image [$::session getImageByPhi $l_spotlist_phi]
    if { $l_image == "" } {
	#puts "Spots list phi of $l_spotlist_phi does not correspond to any image in the session"
	return
    } else {
	#puts "Spotlist phi $l_spotlist_phi corresponds to Image $l_image"
    }

    #Add an event to the session history recording old and new spotlists
    set l_image_displayed [.image getImage]
    set old_spotlist [$l_image_displayed getSpotlist]
    #puts "old_spotlist: $old_spotlist"
    $::session addHistoryEvent "SpotSearchEvent" "Input" [$l_image getFullPathName] $old_spotlist $new_spotlist

    # Update the image's spotlist
    $l_image setSpotlist $new_spotlist
    
    # Add the searched image to the indexing list
    addImage $l_image

    # Update the image tree
    $itk_component(spotfinding_palette) updateSpotFindingResult $l_image

    # Update summary labels
    updateImageNumbers
    
    # Update image viewer with spots if they are for this image
    set image_displayed_number [$l_image_displayed getNumber]
    set image_spotlist_number [$l_image getNumber]
    if { $image_displayed_number == $image_spotlist_number } {
	.image plotSpots
    }
}

body Indexwizard::processSpotfindingResults { a_dom } {
    
    # Check on status of task
    set status_code [$a_dom selectNodes string(/spot_search_response/status/code)]
    if {$status_code == "error"} {
	set message [$a_dom selectNodes string(/spot_search_response/status/message)]
	# Skip responses from the successive lowering of the threshold by Mosflm
	if { [string compare [string range $message 0 16] "Too few spots for"] == 0 } {
	    # skip pop-up
	} else {
	    .m confirm -type "1button" \
		-title "Spot search failed" \
		-text "$message" \
		-button1of1 "Dismiss"
	    enable
	}
    } else {
	# Update spot finding parameters

	# Separation
	set l_separation [$a_dom selectNodes normalize-space(//separation)]
	if {$l_separation != ""} {
	    foreach { l_sep_x l_sep_y } $l_separation break
	    if {[$::session getParameterValue "spot_separation_x"] != $l_sep_x} {
		$::session updateSetting "spot_separation_x" $l_sep_x "1" "1" "Spotfinding"
	    }
	    if {[$::session getParameterValue "spot_separation_y"] != $l_sep_y} {
		$::session updateSetting "spot_separation_y" $l_sep_y "1" "1" "Spotfinding"
	    }
	} else {
	}

	# "Close"
	set l_close [$a_dom selectNodes normalize-space(//close)]
	if {$l_close != ""} {
	    if {[$::session getParameterValue "separation_close"] != $l_close} {
		$::session updateSetting "separation_close" $l_close "1" "1" "Spotfinding"
	    }
	} else {
	}

	# Raster
	set l_raster [$a_dom selectNodes normalize-space(//raster)]
	if {[llength $l_raster] == 5} {
	    foreach { l_raster_nxs l_raster_nys l_raster_nc l_raster_nrx l_raster_nry } $l_raster break
	    $::session updateSetting "raster_nxs" $l_raster_nxs "1" "1" "Spotfinding"
	    $::session updateSetting "raster_nys" $l_raster_nys "1" "1" "Spotfinding"
	    $::session updateSetting "raster_nc" $l_raster_nc "1" "1" "Spotfinding"
	    $::session updateSetting "raster_nrx" $l_raster_nrx "1" "1" "Spotfinding"
	    $::session updateSetting "raster_nry" $l_raster_nry "1" "1" "Spotfinding"
	} else {
	}

	# Get the name of the spot file returned
	set received_file [$a_dom selectNodes string(//spotfile)]
	
	# Get the name of the image it belongs to
	set l_image_path [$a_dom selectNodes string(//imagefile)]
	#puts $l_image_path
	set l_image [Image::getImageByPath $l_image_path]
	#puts $l_image

	# Get the autothreshold value returned
	
	set local_auto_thresh [$a_dom selectNodes normalize-space(//indexing_threshold_value)]
	$::session updateSetting "i_sig_i" $local_auto_thresh "1" "1" "Spotfinding" "0"
	$::session updateSetting "auto_thresh_value" $local_auto_thresh "0" "0" "Spotfinding" "0"

	# Create a spotlist from the file
	#puts "Image [$l_image getNumber] \($l_image\) used for spot list"
	#puts "Image image height [$l_image getImageHeight]"
	set new_spotlist [namespace current]::[Spotlist \#auto "file" [$l_image getImageHeight] [$l_image makeAuxiliaryFileName "spt" $::mosflm_directory]]

	#Add an event to the session history recording old and new spotlists
	set old_spotlist [$l_image getSpotlist]
	$::session addHistoryEvent "SpotSearchEvent" "Indexing" [$l_image getFullPathName] $old_spotlist $new_spotlist

	# Update the image's spotlist
	$l_image setSpotlist $new_spotlist

	# If there are no more results awaited
	if {![$::mosflm busy "spot_finding"]} {
	    # Turn off activity indicator
	    #.c idle
	    # enable controls
	    enable
	    set index_workflow "true"
	} else {
	}
	
	# Add the searched image to the indexing list
	addImage $l_image

	# Update the image tree
	$itk_component(spotfinding_palette) updateSpotFindingResult $l_image

	# Update summary labels
	updateImageNumbers
	
	# Update image viewer with spots if now available
	.image plotSpots
    }
}

body Indexwizard::updateSpotlists { an_image } {
    # Don't bother if we can't find the image item
    if {[array get image_items_by_object $an_image] != ""} {
	# Get the label
	set l_label [$an_image getNumber]
	# get any existing spotlist
	set l_spotlist [$an_image getSpotlist]
	# depending on whether there's a spotlist or not...
	if {$l_spotlist != ""} {
	    # Manual spot editing implies we want to use these spots!
	    $itk_component(image_tree) item state set $image_items_by_object($an_image) [list AVAILABLE CHECKED]
	    # Get the text summary for display in the image tree
	    set l_icon ::img::spotlist
	    set l_auto [format %3d [$l_spotlist getAuto]]
	    set l_manual [format %3d [$l_spotlist getManual]]
	    set l_deleted [format %3d [$l_spotlist getDeleted]]
	    set l_total [format %3d [$l_spotlist getTotal]]
	    # plot the spots in the canvas (tagged by label)
	    $l_spotlist plotSummary $itk_component(spotcanvas) $l_label
	    # Move the spots to avoid the canvas border
	    $itk_component(spotcanvas) move "all$l_label" 1 1
	    # Scale the spot summary canvas
	    set l_scale_factor [expr 250.0 / [$an_image getImageHeight]]
	    $itk_component(spotcanvas) scale "all$l_label" 1 1 $l_scale_factor $l_scale_factor
	    # If the item is checked for inclusion...
	    if {[$itk_component(image_tree) item state get $image_items_by_object($an_image) CHECKED]} {
		# If the item is currently selected...
		if {[$itk_component(image_tree) item state get $image_items_by_object($an_image) selected]} {
		    # colour its spots blue
		    $itk_component(spotcanvas) itemconfigure "auto$l_label" -image ::img::summary_spot_blue_plus
		    $itk_component(spotcanvas) itemconfigure "manual$l_label" -image ::img::summary_spot_blue_cross    
		}
	    } else {
		$itk_component(spotcanvas) itemconfigure "manual$l_label" -image ""
	    }
	} else {
	    # Set state to indicate spots are NOT available from this image
	    $itk_component(image_tree) item state set $image_items_by_object($an_image) [list !AVAILABLE !CHECKED] 
	    # Make text summary indicating no spots searched for yet
	    set l_icon ::img::image
	    set l_auto " - "
	    set l_manual " - "
	    set l_deleted " - "
	    set l_total " - "
	}
	# update the image icon
	$itk_component(image_tree) item element configure $image_items_by_object($an_image) 0 e_icon -image $l_icon
	# update the text summaries
	$itk_component(image_tree) item text $image_items_by_object($an_image) 2 $l_auto 3 $l_manual 4 $l_deleted 5 $l_total
    }
    # Update summary canvas
    updateSpotlistSelection

}
   
body Indexwizard::updateSpotFindingResult { a_image } {
    # Only bother if the image is in the wizard's list!
    #puts "updateSpotFindingResult: image_items_by_object($a_image) is $image_items_by_object($a_image)"
    if { [info exists image_items_by_object($a_image)] } {
	# get the image's item
	set l_item $image_items_by_object($a_image)
	# get the image's spotlist
	set l_spotlist [$a_image getSpotlist]
	# get the image's label in the image tree
	set l_label [$itk_component(image_tree) item text $l_item 0]
	if {$l_spotlist != ""} {
	    $itk_component(image_tree) item state set $l_item AVAILABLE
	    set l_icon ::img::spotlist
	    set l_auto [format %3d [$l_spotlist getAuto]]
	    set l_manual [format %3d [$l_spotlist getManual]]
	    set l_deleted [format %3d [$l_spotlist getDeleted]]
	    set l_total [format %3d [$l_spotlist getTotal]]
	} else {
	    $itk_component(image_tree) item state set $l_item !AVAILABLE
	    set l_icon ::img::image
	    set l_auto " - "
	    set l_manual " - "
	    set l_deleted " - "
	    set l_total " - "
	}
	updateSpotSummary
	set l_total [format %3d [$l_spotlist getTotalAboveIsigi]] 
	$itk_component(image_tree) item element configure $l_item 0 e_icon -image $l_icon
	$itk_component(image_tree) item text $l_item 2 $l_auto 3 $l_manual 4 $l_deleted 5 $l_total
	# Sort the image tree
	$itk_component(image_tree) item sort root -command [code $this sortSpotFindingResults]
	# update the summary
	#updateSpotSummary
    }
}

body Indexwizard::updateSpotReportIsigi { a_image } {
    # Only bother if the image is in the wizard's list!
    if {[info exists image_items_by_object($a_image)]} {
	# get the image's item
	set l_item $image_items_by_object($a_image)
	#puts "updateSpotReportIsigi: object for item $l_item $image_objects_by_item($l_item)"
	# get the image's spotlist
	set l_spotlist [$a_image getSpotlist]
	# get the image's label in the image tree
	set l_label [$itk_component(image_tree) item text $l_item 0]
	if {$l_spotlist != ""} {
	    $itk_component(image_tree) item state set $l_item AVAILABLE
	    set l_icon ::img::spotlist
	    set l_auto [format %3d [$l_spotlist getAuto]]
	    set l_manual [format %3d [$l_spotlist getManual]]
	    set l_deleted [format %3d [$l_spotlist getDeleted]]
	    set l_total [format %3d [$l_spotlist getTotal]]
	} else {
	    $itk_component(image_tree) item state set $l_item !AVAILABLE
	    set l_icon ::img::image
	    set l_auto " - "
	    set l_manual " - "
	    set l_deleted " - "
	    set l_total " - "
	}
	set l_total [format %3d [$l_spotlist getTotalAboveIsigi]] 
	$itk_component(image_tree) item element configure $l_item 0 e_icon -image $l_icon
	$itk_component(image_tree) item text $l_item 2 $l_auto 3 $l_manual 4 $l_deleted 5 $l_total

	# Sort the image tree
	$itk_component(image_tree) item sort root -command [code $this sortSpotFindingResults]
    }
}

body Indexwizard::sortSpotFindingResults { a_item b_item } {
    #puts "IW:sort a_item $a_item b_item $b_item"
    set a_available [$itk_component(image_tree) item state get $a_item AVAILABLE]
    set b_available [$itk_component(image_tree) item state get $b_item AVAILABLE]
    if {$a_available && !$b_available} {
	return -1
    } elseif {!$a_available && $b_available} {
	return +1
    } else {
	set a_image_num [$image_objects_by_item($a_item) getNumber]
	set b_image_num [$image_objects_by_item($b_item) getNumber]
	if {$a_image_num < $b_image_num} {
	    return -1
	} elseif {$a_image_num > $b_image_num} {
	    return +1
	} else {
	    return 0
	}
    }
}

body Indexwizard::editSpots { } {
    .image openImage [lindex $images_list [$itk_component(imageslist) curselection]]
}

body Indexwizard::createImageCheck { tbl row col w } {
    error "Obselete method Indexwizard::createImageCheck called"
}

body Indexwizard::updateSpotlistInclusions { a_row a_value } {
    # update the list of which spotlists to use
    set use_spotlists [lreplace $use_spotlists $a_row $a_row $a_value]
    # Update summary canvas
    updateSpotlistSelection
}

body Indexwizard::updateSpotSummary { } {
    # clear the spot summary canvas
    $itk_component(spotcanvas) delete all
    # initialize iterator to "", to allow later test for any iterations
    set i_image ""
    # Loop through chosen images
    foreach i_image [array names image_items_by_object] {
	#puts "updateSpotSummary: Image from array names of image_items_by_object: $i_image"
	#puts "updateSpotSummary - image is $i_image, item_by_object is $image_items_by_object($i_image)"
	# Choose labelling method depending on number of templates
	if {[llength [$::session getSectors]] > 1} {
	    set l_labelMethod "getShortName"
	} else {
	    set l_labelMethod "getNumber"
	}
	# get the label to be used
	set l_label [$i_image $l_labelMethod]
	# get the spotlist
	set l_spotlist [$i_image getSpotlist]
	# plot the spots in the canvas (tagged by label)
	$l_spotlist plotSummary $itk_component(spotcanvas) $l_label [$::session getParameterValue "i_sig_i"]
	set l_total [format %3d [$l_spotlist getTotalAboveIsigi]]
	updateSpotReportIsigi $i_image
    }
    # if any summaries were plotted
    if {$i_image != ""} {
	set l_x_scale [expr double([winfo width $itk_component(spotcanvas)]) / [$::session getImageWidth]]
	set l_y_scale [expr double([winfo height $itk_component(spotcanvas)]) / [$::session getImageHeight]]
	# Scale the summaries to fit the canvas
	$itk_component(spotcanvas) scale all 0 0 $l_x_scale $l_y_scale
    }

    bind $itk_component(spotcanvas) <Configure> [code $this updateSpotSummary]

    # Update the total
    updateTotal
}

body Indexwizard::updateSpotlistSelection {  } {
    # initialize the index used to count through spot lists
    set i_index 0
    # loop through images 
    foreach i_image $images_list {
	# if the images's spotlist is to be used...
	if {[lindex $use_spotlists $i_index] == "1"} {
	    if {[$itk_component(imageslist) curselection] == $i_index} {
		# show the markers
		$itk_component(spotcanvas) itemconfigure "auto[$i_image getNumber]" -image ::img::summary_spot_blue_plus
		$itk_component(spotcanvas) itemconfigure "manual[$i_image getNumber]" -image ::img::summary_spot_blue_cross
		$itk_component(spotcanvas) raise "all[$i_image getNumber]"
	    } else {
		$itk_component(spotcanvas) itemconfigure "auto[$i_image getNumber]" -image ::img::summary_spot_black_plus
		$itk_component(spotcanvas) itemconfigure "manual[$i_image getNumber]" -image ::img::summary_spot_black_cross
	    }
	} else {
	    $itk_component(spotcanvas) itemconfigure "all[$i_image getNumber]" -image ::img::summary_spot_blank
	}
	incr i_index
    }
} 

body Indexwizard::updateImageNumbers { } {
    # Loop through images in tree, building:
    #  - count of images included, and
    #  - lists of image numbers per sector (template)
    set current_sector [$::session getCurrentSector]

    foreach i_sector [$::session getSectors] {
	set l_image_numbers_by_template([$i_sector getTemplate]) {}
    }
    set l_image_count 0
    foreach i_item [$itk_component(image_tree) item children root] {
	incr l_image_count
	if {[$itk_component(image_tree) item state get $i_item CHECKED]} {
	    set l_image $image_objects_by_item($i_item)
	    lappend l_image_numbers_by_template([$l_image getTemplate]) [$l_image getNumber]
	}
    }
    foreach i_template [array names l_image_numbers_by_template] {
	$itk_component(image_numbers) updateSector $i_template [compressNumList $l_image_numbers_by_template($i_template)]
    }
    set i_template [$current_sector getTemplate] ;# reset to the current sector and reset image numbers
    $itk_component(image_numbers) updateSector $i_template [compressNumList $l_image_numbers_by_template($i_template)]
}

body Indexwizard::imageTreeRollover { a_w a_x a_y } {
    set l_new_item ""
    set l_new_element ""

    # get item and element rolled over
    set id [$a_w identify $a_x $a_y]
    if {$id != ""} {
	if {[lindex $id 0] eq "item"} {
	    set l_new_item [lindex $id 1]
	    if {[lindex $id 4] eq "elem"} {
		set l_new_element [lindex $id 5]
	    }
	}
    }
    
    # if changed, get rid of previous highlights / tooltips
    if {($prev_rollover_item != "") && ($prev_rollover_element != "")} {
	if {($prev_rollover_item != $l_new_item) || ($prev_rollover_element != $l_new_element)} {
	    if {$prev_rollover_element == "e_auto_search"} {
		$a_w item element configure $prev_rollover_item search e_auto_search -image ::img::spot_search_auto
		$a_w configure -cursor left_ptr
	    }
	}
    }
    
    # setup new highlights / tooltips
    if {$l_new_element == "e_auto_search"} {
	$a_w item element configure $l_new_item search e_auto_search -image  ::img::spot_search_auto_highlighted
	$a_w configure -cursor hand2
    }
    
    # update record of old item and element
    set prev_rollover_item $l_new_item
    set prev_rollover_element $l_new_element
}


# Autoindexing methods #############################################

body Indexwizard::queueAutoindex { } {
    set images [$itk_component(image_numbers) getContent]
    if { $images  == {} } {
	# No images entered, selected nor chosen. Cannot Index - do nothing
	return
    }
    # shift focus to index button to force setting updates
    focus $itk_component(index_button)
    # trap zero crystal-to-detector distance
    $::session forceDistanceSetting
    if {[$::session distanceIsSet]} {
	# schedule autoindexing in event loop to allow updates to take place first
	after 0 [code $this autoindex]
    } else {
    }
}

body Indexwizard::autoindex { } {
    set do_not_process_indexing 0

    # disable controls
    disable

    # Remove solution selection binding
    $itk_component(image_tree) notify bind $itk_component(image_tree) <Selection> {}

    # Clear the solutions list
    $itk_component(solution_tree) item delete all

    # Get new spotfile in case choice of image changed
    set spotfilename [getNewSpotfilename]
    set l_first_image [getSpotfileFirstImage $spotfilename]
    #puts "autoindex: $l_first_image $spotfilename"
    # Trap if this image does not have a spotfile
    if { $l_first_image == 0 } { return }

    # Send command to Mosflm
    ########################
    $::mosflm index $l_first_image $spotfilename 0
}

body Indexwizard::sigmaISearchAutoindex { } {

    set do_not_process_indexing 1
    #puts "$this set do_not_process_indexing 1"
    # disable controls
    disable

    # Remove solution selection binding
    $itk_component(image_tree) notify bind $itk_component(image_tree) <Selection> {}

    # Get new spotfile in case choice of image changed
    set spotfilename [getNewSpotfilename]
    set l_first_image [getSpotfileFirstImage $spotfilename]
    #puts "autoindex: $l_first_image $spotfilename"

    # Send command to Mosflm
    ########################
    $::mosflm index $l_first_image $spotfilename 0
}

body Indexwizard::beamSearchAutoindex { a_beam_x a_beam_y } {

    # disable controls
    disable

    # Remove solution selection binding
    $itk_component(image_tree) notify bind $itk_component(image_tree) <Selection> {}

    # Send command to Mosflm
    ########################
    after 0 [code $::mosflm index3 $a_beam_x $a_beam_y $l_first_image $spotfilename 0]
}

body Indexwizard::getNewSpotfilename { } {

# Open randomly named temporary spot file
    expr srand([clock clicks])
    set file_creation_incomplete 1
    set file_creation_attempts 0
    while {$file_creation_incomplete} {
	if {$file_creation_attempts > 50} {
	    .m confirm \
		-type "1button" \
		-title "Error" \
		-text "Could not create spotfile:\n$out_file" \
		-button1of1 "Dismiss"
	    return 0
	}
	set spotfilename [file join $::mosflm_directory "msf[expr int(rand()*99999)].tmp"]
	set file_creation_incomplete [catch {open $spotfilename {WRONLY CREAT EXCL}} out_file]
	incr file_creation_attempts
    }
    # close file
    close $out_file
    set haveNewSpotfilename 1
    return $spotfilename
}

body Indexwizard::getSpotfileFirstImage { spotfilename } {

    # Open randomly named temporary spot file
    set file_creation_incomplete 1
    set file_creation_incomplete [catch {open $spotfilename {WRONLY CREAT}} out_file]

    # write header info
    #        3072        3072 0.10260000    1.000000    0.000000
    #           1           1
    #  157.32001  157.05000
    #
    #3072 = number of pixels in X, Y - <image_width> & <image_height> in <header_response>
    #0.1026 = pixel size in mm <pixel_size> in <header_response>
    #1.000 = YSCALE <yscale>
    #0.000 = OMEGA <omega> 
    set iw [$::session getParameterValue "image_width"]
    set ih [$::session getParameterValue "image_height"]
    set px [$::session getParameterValue "pixel_size"]
    set ys [$::session getParameterValue "yscale"]
    set do [$::session getParameterValue "detector_omega"]
    puts $out_file "[format %12d $iw][format %12d $ih][format %11.8f $px][format %12.6f $ys][format %12.6f $do]"
    #
    #1 = "invertx" flag <invertx>
    #1 = "swung out coordinates" - always 1 for iMosflm, not sent in XML
    set ix [string match T [$::session getInvertX]]
    set so 1
    puts $out_file "[format %12d $ix][format %12d $so]"
    #
    #157.32001  157.05000 = beam X & Y - <beam_x> <beam_y>
    set bx [$::session getParameterValue "beam_x"]
    set by [$::session getParameterValue "beam_y"]
    puts $out_file "[format %11.5f $bx][format %11.5f $by]"

    # loop through images, generating spot lists
    set first_image 1
    set i_index 0
    set images_being_autoindexed {}
    foreach i_item [$itk_component(image_tree) item children root] {
	if {[$itk_component(image_tree) item state get $i_item CHECKED]} {
	    set l_image $image_objects_by_item($i_item)
	    lappend images_being_autoindexed $l_image
	    if {$first_image} {
		set first_image 0
		set l_first_image $l_image
	    } else {
		puts $out_file "[format %11.2f -99.00][format %10.2f -99.00][format %9.3f -99.00][format %9.3f -99.00][format %12.1f -99.00][format %10.1f -99.00]"
	    }
	    foreach { l_phi_start l_phi_end } [$l_image getPhi] break
		if { $l_phi_end > $l_phi_start } {
		    set oscrange [expr $l_phi_end - $l_phi_start]
		} else {
		    # oscillation range may have crossed phi=0
		    set oscrange [expr $l_phi_end + 360.0 - $l_phi_start]
		}
		#puts $oscrange
	    set l_spotlist [$l_image getSpotlist]
	    $l_spotlist writeToFile $out_file $oscrange
	}
	incr i_index
    }
    puts $out_file "[format %11.2f -999.00][format %10.2f -999.00][format %9.3f -999.00][format %9.3f -999.00][format %12.1f -999.00][format %10.1f -999.00]"
    puts $out_file "[format %7d $iw][format %6d $ih][format %10.4f $px][format %5d [expr int($ys)]]"
    
    # close file
    close $out_file
    return $l_first_image
}

body Indexwizard::processIndexingResults { a_dom } {
    # Check on status of task
    set status_code [$a_dom selectNodes string(/preselection_index_response/status/code)]
    if {$status_code == "error"} {
	# get message
	set status_message [$a_dom selectNodes string(/preselection_index_response/status/message)]
	if {$do_not_process_indexing != 1} {
	    if {[regexp {found in spot file} $status_message]} {
		.m configure \
		    -type "1button" \
		    -text "Mosflm is not able to index with so few spots.\nPlease try again with more spots." \
		    -button1of1 "Dismiss"
	    } elseif {[regexp {Failed to index image} $status_message]} {
		.m configure \
		    -type "1button" \
		    -text "Indexing failed.\nPlease check the beam position, distance, and max cell edge." \
		    -button1of1 "Dismiss"
	    } elseif {[regexp {Bravais failure} $status_message]} {
		.m configure \
		    -type "1button" \
		    -text "Mosflm failed to index correctly, sorry.\nIncreasing the max cell edge and/or decreasing the threshold may help." \
		    -button1of1 "Dismiss"
	    } else {
		.m configure \
		    -type "1button" \
		    -text "The indexing process has failed. It might be worthwhile trying again with:\n1. A large or smaller longest cell edge\n2. Using more or fewer reflections (200 - 1000 is best)\n3. Using more and/or different images\n4. Checking your direct beam position carefully" \
		    -button1of1 "Dismiss"
	    }
	    if {[.m confirm]} {
		# If no more refinement results are expected...
		if {![$::mosflm busy "indexing" "index_refinement"]} {
		    # enable the controls
		    enable
		}
	    }
        } else {
	    set start_beam_x [format %5.1f [lindex [lindex $beam_list [expr $grid_counter - 1] 0]]]
	    set start_beam_y [format %5.1f [lindex [lindex $beam_list [expr $grid_counter - 1] 1]]]
#			puts "$start_beam_x $start_beam_y $bs_beam_x $bs_beam_y [format %4.2f $bs_beam_shift_rel] [format %4.2f $bs_spot_deviation_pos] [format %4.2f $bs_spot_deviation_phi]"

	    set bs_item [$itk_component(beamsearch_tree) item create]
	    $itk_component(beamsearch_tree) item style set $bs_item 0 s2 1 s2 2 s2 3 s2 4 s2 5 s2 6 s2 7 s2 8 s2 9 s2 10 s2 11 s2 12 s2
	    $itk_component(beamsearch_tree) item text $bs_item 0 $start_beam_x
	    $itk_component(beamsearch_tree) item text $bs_item 1 $start_beam_y
	    $itk_component(beamsearch_tree) item text $bs_item 2 "-"
	    $itk_component(beamsearch_tree) item text $bs_item 3 "-"			
	    $itk_component(beamsearch_tree) item text $bs_item 4 "-"
	    $itk_component(beamsearch_tree) item text $bs_item 5 "-"
	    $itk_component(beamsearch_tree) item text $bs_item 6 "-"
	    $itk_component(beamsearch_tree) item text $bs_item 7 "-"
	    $itk_component(beamsearch_tree) item text $bs_item 8 "-"
	    $itk_component(beamsearch_tree) item text $bs_item 9 "-"
	    $itk_component(beamsearch_tree) item text $bs_item 10 "-"
	    $itk_component(beamsearch_tree) item text $bs_item 11 "-"
	    $itk_component(beamsearch_tree) item text $bs_item 12 "-"
	    
	    $itk_component(beamsearch_tree) item lastchild root $bs_item

	    $itk_component(beamsearch_tree) yview moveto 1.0

	    if {![$::mosflm busy "indexing" "index_refinement"]} {
		enable
	    }
	    gridSearchRelay
	}
    } else {
	if {$do_not_process_indexing != 1} {

	    # Parse updated settings
	    set l_max_cell_edge [$a_dom selectNodes normalize-space(//maximum_cell_edge)]
	    if {[$::session getParameterValue "fix_max_cell_edge"] != "1"} {
		$::session updateSetting max_cell_edge [expr int(round($l_max_cell_edge))] "1" "1" "Indexing"
	    }
    
	    # Handle indexing solutions
    
	    # Clear any previous solutions
	    foreach i_solution [array names solution_items_by_object] {
		delete object $i_solution
	    }
	    array unset solution_objects_by_number *
	    array unset solution_objects_by_item *
	    array unset solution_items_by_number *
	    array unset solution_item_types *
    
    
	    # Get the lattice_characters element
	    set lattice_character_nodes [$a_dom selectNodes //lattice_character]
	
	    # Parse solutions
	    foreach i_lattice_character_node $lattice_character_nodes {
		# create solution objects
		set l_raw_solution [namespace current]::[Solution \#auto "build" "raw" $images_being_autoindexed $i_lattice_character_node]
		set l_reg_solution [namespace current]::[Solution \#auto "build" "reg" $images_being_autoindexed $i_lattice_character_node]
		set l_reg_cell [$l_reg_solution getCell]
		set l_raw_cell [$l_raw_solution getCell]
		
		# Add solution event to history
		$::session addHistoryEventQuickly "SolutionEvent" "Indexing" $l_reg_solution
    
		# add an item to the solutions tree for the regularized solution
		set l_reg_item [$itk_component(solution_tree) item create -button 1]
		$itk_component(solution_tree) item style set $l_reg_item 0 s1 1 s2 2 s2 3 s2 4 s2 5 s2 6 s2 7 s2 8 s2 9 s2 10 s2 11 s2
		foreach { l_a l_b l_c l_alpha l_beta l_gamma } [$l_reg_cell listCell] break 
		$itk_component(solution_tree) item complex $l_reg_item \
		    [list [list e_icon -image ::img::reg_solution] [list e_text -text "[$l_reg_solution getNumber] (reg)"]] \
		    [list [list e_text -text "[$l_reg_solution getLattice]"]] \
		    [list [list e_text -text "[format %3d [$l_reg_solution getPenalty]]"]] \
		    [list [list e_text -text "[format %5.1f $l_a]"]] \
		    [list [list e_text -text "[format %5.1f $l_b]"]] \
		    [list [list e_text -text "[format %5.1f $l_c]"]] \
		    [list [list e_text -text "[format %5.1f $l_alpha]"]] \
		    [list [list e_text -text "[format %5.1f $l_beta]"]] \
		    [list [list e_text -text "[format %5.1f $l_gamma]"]] \
		    [list [list e_text -text "-"]] \
		    [list [list e_text -text "-"]] \
		    [list [list e_text -text "-"]]
    
		$itk_component(solution_tree) item firstchild root $l_reg_item
    
		# Store pointers to solutions and solution items
		set solution_objects_by_number(reg,[$l_reg_solution getNumber]) $l_reg_solution
		set solution_items_by_number(reg,[$l_reg_solution getNumber]) $l_reg_item
		set solution_numbers_by_item($l_reg_item) [$l_reg_solution getNumber]
		set solution_objects_by_item($l_reg_item) $l_reg_solution
		set solution_item_types($l_reg_item) reg
    
		# add an item to the solutions tree for the raw solution
		set l_raw_item [$itk_component(solution_tree) item create]
		$itk_component(solution_tree) item style set $l_raw_item 0 s1 1 s2 2 s2 3 s2 4 s2 5 s2 6 s2 7 s2 8 s2 9 s2 10 s2 11 s2
		foreach { l_a l_b l_c l_alpha l_beta l_gamma } [$l_raw_cell listCell] break 
		$itk_component(solution_tree) item complex $l_raw_item \
		    [list [list e_icon -image ::img::raw_solution] [list e_text -text "(raw)"]] \
		    [list [list e_text -text "[$l_raw_solution getLattice]"]] \
		    [list [list e_text -text "[format %3d [$l_raw_solution getPenalty]]"]] \
		    [list [list e_text -text "[format %5.1f $l_a]"]] \
		    [list [list e_text -text "[format %5.1f $l_b]"]] \
		    [list [list e_text -text "[format %5.1f $l_c]"]] \
		    [list [list e_text -text "[format %5.1f $l_alpha]"]] \
		    [list [list e_text -text "[format %5.1f $l_beta]"]] \
		    [list [list e_text -text "[format %5.1f $l_gamma]"]] \
		    [list [list e_text -text "-"]] \
		    [list [list e_text -text "-"]] \
		    [list [list e_text -text "-"]]
		# Add raw item to reg item in tree
		$itk_component(solution_tree) item lastchild $l_reg_item $l_raw_item
		# Collapse regularized solution item
		$itk_component(solution_tree) item collapse $l_reg_item
		# Store pointer to item in an array indexed by solution number
		set solution_objects_by_number(raw,[$l_raw_solution getNumber]) $l_reg_solution
		set solution_items_by_number(raw,[$l_raw_solution getNumber]) $l_raw_item
		set solution_numbers_by_item($l_raw_item) [$l_raw_solution getNumber]
		set solution_objects_by_item($l_raw_item) $l_raw_solution
		set solution_item_types($l_raw_item) raw
	    }
	    
	    # Save the session (as history events have been added quickly)
	    $::session writeToFile
    
	    # Get the suggest solution number
	    set suggested_solution_number [$a_dom selectNodes {normalize-space(/preselection_index_response/suggested_solution/number)}]
	    
	    # Refine all solutions <=50
	    # HRP 31.08.2006 was < 200
	    refineAll
	} else {
	    #puts "IN AUTOINDEXING AND NOT PROCESSING RESULTS"
	    set solution_number_nodes [$a_dom selectNodes //lattice_character]
	    $::mosflm index2 1 [$::session getSigmaCutoff]
	    if {![$::mosflm busy "indexing" "index_refinement"]} {
		# enable the controls
		enable
	    }
	}
    }
}


body Indexwizard::toggleSolution { a_selection_count a_selected } {
    if {$a_selection_count > 0} {
	# if a raw solution is selected, move selection to reg.
	if {$solution_item_types($a_selected) == "raw"} {
	    set l_solution $solution_objects_by_item($a_selected)
	    set l_solution_number [$l_solution getNumber]
	    $itk_component(solution_tree) selection modify $solution_items_by_number(reg,$l_solution_number) all
	} else {
	    # Get the selected solution object and type
	    set t_item $a_selected
	    set chosen_solution $solution_objects_by_item($t_item)
	    set chosen_solution_type $solution_item_types($t_item)

	    # update the cell before the spacegroup to avoid validateCellAndSpacegroup error
	    $::session updateCell "Indexing" [$chosen_solution getCell] 1 1 0

	    # Get lattice type
	    set l_lattice_type [$chosen_solution getLattice]
	    # get the list of possible spacegroups for the selected solution
	    $itk_component(spacegroupcombo) list delete 0 end
	    eval $itk_component(spacegroupcombo) list insert 0 $::spacegroup($l_lattice_type)
	    # select the minimal one as default
	    $itk_component(spacegroupcombo) select 0
	    # enable the spacegroup combobox
	    $itk_component(spacegroupcombo) configure \
		-state normal

	    # Update client-side variables to reflect results

	    # Get a list of sectors used
	    set l_sectors_to_update {}
	    foreach i_image $images_being_autoindexed {
		if {[lsearch $l_sectors_to_update [$i_image getSector]] < 0} {
		    lappend l_sectors_to_update [$i_image getSector]
		}
	    }

	    # update all used sectors with new matrix
	    foreach i_sector $l_sectors_to_update {
		eval $i_sector updateMatrix "Indexing" [$chosen_solution getMatrix] 1 1 0
	    }
	    
	    # update the spacegroup
	    set l_spacegroup [namespace current]::[Spacegroup \#auto "initialize" "unnamed" [$itk_component(spacegroupcombo) get]]
	    $::session updateSpacegroup "Indexing" $l_spacegroup 1 1 0
	    delete object $l_spacegroup
	    
	    if {$mosaicity_has_been_set} {
		# Update the mosaicity
		$::session updateSetting mosaicity $mosaicity 1 1 "Indexing" 0
	    }

	    # if the solution was refined (so the beam was changed)...
	    if {$chosen_solution_type == "ref"} {
		# update the beam position
		foreach { l_beam_x l_beam_y } [$chosen_solution getBeam] break
		$::session updateSetting beam_x $l_beam_x 1 1 "Indexing" 0
		$::session updateSetting beam_y $l_beam_y 1 1 "Indexing" 0
	    }

	    # Get new predictions
	    $::session updatePredictions
	}
    }
    updateMosaicityButton
    set mosaicity_workflow "true"
}

body Indexwizard::toggleSpacegroup { a_widget a_value } {
    set l_prev_lattice [$::session getLattice]
    set l_current_spacegroup [[$::session getSpacegroup] reportSpacegroup]
    # Needs to be editable see bug 269
    regsub -all " " $a_value "" trim_value
    if { [string length $trim_value] == 0 } { return }
    if { [string index $trim_value 0] != "h" } {
	set trim_value [string toupper $trim_value]
    }
    if { [string index $trim_value 0] == "H" } {
	set trim_value [string tolower $trim_value]
    }
    if {[lsearch $::spacegroups $trim_value] > -1} {
	# Known to iMosflm
	if {$trim_value != $l_current_spacegroup} {
	    # & different
	    if {[[$::session getCell] reportCell] != "Unknown"} {
		# I think cell is Unknown when first space group value is inserted from chosen solution
		foreach { l_a l_b l_c l_alpha l_beta l_gamma } [[$::session getCell] listCell] break
		$::session validateCellAndSpacegroup $l_a $l_b $l_c $l_alpha $l_beta $l_gamma $trim_value
	    }
	    set l_curr_lattice [$::session getLattice]
	    if { $l_curr_lattice != "" } {
		#puts "Space group $trim_value chosen in lattice $l_curr_lattice"
	    }
        }
    } else {
	# Not known to iMosflm
	if { ($l_prev_lattice != "") && ($l_current_spacegroup != "Unknown") } {
	    if {[[$::session getCell] reportCell] != "Unknown"} {
		# I think cell is Unknown when first space group value is inserted from chosen solution
		foreach { l_a l_b l_c l_alpha l_beta l_gamma } [[$::session getCell] listCell] break
		$::session validateCellAndSpacegroup $l_a $l_b $l_c $l_alpha $l_beta $l_gamma $trim_value
	    }
	}
    }
    #puts "leaving Indexwizard::toggleSpacegroup a_widget a_value $a_widget $a_value"
}

body Indexwizard::doubleClickSolution { w x y } {
    set id [$w identify $x $y]
    if {$id eq ""} {
	return
    }
    if {[lindex $id 0] eq "item"} {
	foreach {what item where arg1 arg2 arg3} $id break
	if {$arg1 != "button"} {
	    set suggested_solution_number $solution_numbers_by_item($item)
	    refine
	}
    }
}

body Indexwizard::sortSolutionItems { a b } {
    set a_num [$solution_objects_by_item($a) getNumber]
    set b_num [$solution_objects_by_item($b) getNumber]
    if {$a_num < $b_num} {
	return -1
    } elseif {$a_num > $b_num} {
	return +1
    } else {
	return 0
    }
}

body Indexwizard::refineAll { } {
    foreach i_item [$itk_component(solution_tree) item children root] {
	set l_penalty [$itk_component(solution_tree) item text $i_item penalty]
	# HRP 31.08.2006 was < 200
	if {$l_penalty <= 50} {
	    refine $i_item
	}
    }
}

body Indexwizard::refine { { an_item "" } } {
    
    #if no item is provided use the selected item
    if {$an_item != ""} {
	set l_item $an_item
    } else {
	# Get the selected item
	set l_item [$itk_component(solution_tree) selection get]
    }
    set l_solution_number $solution_numbers_by_item($l_item)

    # Send a refinement request
    $::mosflm index2 $l_solution_number [$::session getSigmaCutoff]
}

body Indexwizard::showBeamSearch { } {

    grid $itk_component(beamsearch_tree)
    grid $itk_component(beamsearchscrollbar)
    set showbeamsearch 1
}

body Indexwizard::hideBeamSearch { } {

    grid remove $itk_component(beamsearch_tree)
    grid remove $itk_component(beamsearchscrollbar)
    set showbeamsearch 0
}

body Indexwizard::abortBeamSearch { } {
    set grid_search 0
    puts [$::mosflm busy]
    if {[$::mosflm busy]} {
	bind $itk_component(beamsearchlabel) <ButtonPress-1> ""
	$itk_component(beamsearchlabel) configure -fg grey	
	$itk_component(beamsearchlabel) configure -text "Search beam-centre"
    } else {
	$itk_component(beamsearchlabel) configure -text "Search beam-centre"
	bind $itk_component(beamsearchlabel) <ButtonPress-1> [code $this beamSearchLaunch]
    }
}

body Indexwizard::toggleBeamSearchTable { } {
    if {[set showbeamsearch]} {
	hideBeamSearch
	$itk_component(beamsearchexpander) configure -text "\[+\]"
    } else {
	showBeamSearch 
	$itk_component(beamsearchexpander) configure -text "\[-\]"
    }
}

body Indexwizard::beamSearchLaunch { } {
	$itk_component(beamsearchlabel) configure -text "Abort beam-centre"
	bind $itk_component(beamsearchlabel) <ButtonPress-1> [code $this abortBeamSearch]
	set grid_search 1
	set grid_counter 0
	set haveNewSpotfilename 0
	set do_not_process_indexing 1
	#puts "$this set do_not_process_indexing 1"

	if {$searchtype == "beam-centre"} {
		showBeamSearch
		$itk_component(beamsearch_tree) item delete all
		$itk_component(beamsearchexpander) configure -text "\[-\]"
		set beam_list {}
		gridSearchRelay
	} elseif {$searchtype == "higher I/sigma(I)"} {
		sigmaISearchRelay {up}
	} elseif {$searchtype == "lower I/sigma(I)"} {
		sigmaISearchRelay {down}
	} else {
	}
}

body Indexwizard::sigmaISearchRelay { dir } {

    set sig1 [$::session getISigmaI]
    set sigdel [$::session getISigmaIdelta]
    set delta [expr { int ( $sig1 * $sigdel / 100 ) }]
    if {$dir == "up"} {
	set sig3 [expr { $sig1 + $delta }]
    }
    if {$dir == "down"} {
	set sig3 [expr { $sig1 - $delta }]
    }

    $::session updateSetting i_sig_i $sig3 1 1 "Indexing" 0
    queueAutoindex
    $itk_component(beamsearchlabel) configure -text "Search beam-centre"
    bind $itk_component(beamsearchlabel) <ButtonPress-1> [code $this beamSearchLaunch]
    return
}

body Indexwizard::gridSearchRelay { } {

    set beam_centre [$::session getBeamPosition]
    set stepsize [$::session getParameterValue beamsearch_stepsize]
    set stepnumx [$::session getParameterValue beamsearch_stepnumx]
    set stepnumy [$::session getParameterValue beamsearch_stepnumy]

    set preloop_beam_x [expr [lindex $beam_centre 0] - [expr $stepnumx * $stepsize] ]
    set preloop_beam_y [expr [lindex $beam_centre 1] - [expr $stepnumy * $stepsize] ]

    #puts $beam_centre
    #puts $preloop_beam_x
    #puts $preloop_beam_y

    # Doing a grid search so one temporary spot file will suffice for each search
    if {$haveNewSpotfilename == 0} {
	set spotfilename [getNewSpotfilename]
	set l_first_image [getSpotfileFirstImage $spotfilename]
	#puts "beamSearchLaunch: $l_first_image,$spotfilename"
    }
    

    if {$grid_counter == 0} {
	for {set local_beam_x $preloop_beam_x} {$local_beam_x <= [expr $preloop_beam_x + [expr 2*($stepnumx * $stepsize)]]} {set local_beam_x [expr $local_beam_x + $stepsize]} {
	    for {set local_beam_y $preloop_beam_y} {$local_beam_y <= [expr $preloop_beam_y + [expr 2*($stepnumy * $stepsize)]]} {set local_beam_y [expr $local_beam_y + $stepsize]} {
		lappend beam_list [list $local_beam_x $local_beam_y]
	    }
	}
    }

#	puts $beam_list
    set list_length [llength $beam_list]

    if {$grid_counter < $list_length} {
	#puts $grid_counter
	#puts [list [lindex $beam_list $grid_counter]]
	if {$grid_search != 0} {
	    beamSearchAutoindex [lindex [lindex $beam_list $grid_counter] 0] [lindex [lindex $beam_list $grid_counter] 1]
	    incr grid_counter
	}
    } else {
	set do_not_process_indexing 0
	set grid_search 0
	$itk_component(beamsearchlabel) configure -text "Search beam-centre"
	bind $itk_component(beamsearchlabel) <ButtonPress-1> [code $this beamSearchLaunch]
	return
    }
}

body Indexwizard::processPrerefinementResult { a_dom} {

    # Check on status of task
    set status_code [$a_dom selectNodes string(/prerefinement_index_response/status/code)]
    if {$status_code == "error"} {
	# Update activity indicator

	# get message
	set status_message [$a_dom selectNodes string(/prerefinement_index_response/status/message)]
	if {[regexp {found in spotfile} $status_message]} {
	    .m configure \
		-type "1button" \
		-text "Mosflm is not able to index with so few spots.\nPlease try again with more spots." \
		-button1of1 "Dismiss"
	} elseif {[regexp {Failed to index image} $status_message]} {
	    .m configure \
		-type "1button" \
		-text "Indexing failed.\nPlease check the beam position, distance, and max cell edge." \
		-button1of1 "Dismiss"
	} elseif {[regexp {Bravais failure} $status_message]} {
	    .m configure \
		-type "1button" \
		-text "Mosflm failed to index correctly, sorry.\nIncreasing the max cell edge and/or decreasing the threshold may help." \
		-button1of1 "Dismiss"
	} else {
	    .m configure \
		-type "1button" \
		-text "Mosflm failed in a new and unusual way.\nNoyce!" \
		-button1of1 "Dismiss"
	}
	if {[.m confirm]} {
	    # was showSpotSearchResults
	}
    } else {
	puts "Stray prerefinement_index_response issued by mosflm: [$a_dom asHTML]"
    }
}

body Indexwizard::processRefinedResult { a_dom } {
    if {$do_not_process_indexing != 1} {
	# Check on status of task
	set status_code [$a_dom selectNodes string(/refined_index_response/status/code)]
	if {$status_code == "error"} {
	    .m confirm -type "1button" \
		-text "Refinement of indexing solution failed, sorry.\n[$a_dom selectNodes string(/refined_index_response/status/message)]" \
		-button1of1 "Dismiss"
	} else {
	    # Get number of current selection
    
	    # Find out which solution it belongs to
	    set l_sol_num [$a_dom selectNodes normalize-space(/refined_index_response/solution_number)]
	    # Get the reg solution object for this result
	    set l_reg_solution $solution_objects_by_number(reg,$l_sol_num)
	    # Create refined solution object
	    set l_ref_solution [namespace current]::[RefinedSolution \#auto "build" $l_reg_solution $a_dom]
	    set l_ref_cell [$l_ref_solution getCell]
    
	    # Add solution event to history
	    $::session addHistoryEventQuickly "SolutionEvent" "Indexing" $l_ref_solution
	       
	    # See if refined solution item already exists
	    if {![info exists solution_items_by_number(ref,$l_sol_num)]} {
		
		# add an item to the solutions tree for the regularized solution
		set l_ref_item [$itk_component(solution_tree) item create -button 1]
		# Add this new solution to the tree
		$itk_component(solution_tree) item lastchild root $l_ref_item
		# Move reg item for this solution to subtree
		$itk_component(solution_tree) item lastchild $l_ref_item $solution_items_by_number(reg,$l_sol_num)
		# Remove button from raw solution
		$itk_component(solution_tree) item configure  $solution_items_by_number(raw,$l_sol_num) -button 0
		# Remove solution number from reg solution
		$itk_component(solution_tree) item element configure $solution_items_by_number(reg,$l_sol_num) 0 e_text -text "(reg)"
		# Collapse refined solution item
		$itk_component(solution_tree) item collapse $l_ref_item
	    } else {
		set l_ref_item $solution_items_by_number(ref,$l_sol_num)
		# Delete previous solution object
		delete object $solution_objects_by_item($l_ref_item)
	    }
    
	    # Update item's details
	    $itk_component(solution_tree) item style set $l_ref_item 0 s1 1 s2 2 s2 3 s2 4 s2 5 s2 6 s2 7 s2 8 s2 9 s2 10 s2 11 s2
	    foreach { l_a l_b l_c l_alpha l_beta l_gamma } [$l_ref_cell listCell] break 
    
	    $itk_component(solution_tree) item complex $l_ref_item \
		[list [list e_icon -image ::img::ref_solution] [list e_text -text "[$l_ref_solution getNumber] (ref)"]] \
		[list [list e_text -text "[$l_ref_solution getLattice]"]] \
		[list [list e_text -text "[format %3d [$l_ref_solution getPenalty]]"]] \
		[list [list e_text -text "[format %5.1f $l_a]"]] \
		[list [list e_text -text "[format %5.1f $l_b]"]] \
		[list [list e_text -text "[format %5.1f $l_c]"]] \
		[list [list e_text -text "[format %5.1f $l_alpha]"]] \
		[list [list e_text -text "[format %5.1f $l_beta]"]] \
		[list [list e_text -text "[format %5.1f $l_gamma]"]] \
		[list [list e_text -text "[format %4.2f [$l_ref_solution getSpotDevPos]]"]] \
		[list [list e_text -text "[format %4.2f [$l_ref_solution getSpotDevPhi]]"]] \
		[list [list e_text -text "[format %4.2f [$l_ref_solution getBeamShiftAbs]] ([format %4.1f [$l_ref_solution getBeamShiftRel]])"]]
    
	    # Store pointer to item in an array indexed by solution number
	    set solution_items_by_number(ref,$l_sol_num) $l_ref_item
	    set solution_numbers_by_item($l_ref_item) $l_sol_num
	    # Store pointer to solution in an array indexed by item tag
	    set solution_objects_by_item($l_ref_item) $l_ref_solution
	    set solution_objects_by_number($l_sol_num) $l_ref_solution
	    # Store item type info
	    set solution_item_types($l_ref_item) ref
    
	    # Resort the solutions
	    $itk_component(solution_tree) item sort root -dictionary

	    # Get any new suggested solution number which has been added to this response
	    set new_suggested_solution_number [$a_dom selectNodes {normalize-space(/refined_index_response/suggested_solution/number)}]
	    if { $new_suggested_solution_number != "" } {
		# Reset solution suggested
		set suggested_solution_number $new_suggested_solution_number
		#puts "Suggested solution set to number $new_suggested_solution_number"
	    } else {
		#puts "No suggested solution sent"
	    }

	    # If no more refinement results are expected...
	    if {![$::mosflm busy "indexing" "index_refinement"]} {
		# get the suggested solution (refined or regularized)
		if {[info exists solution_items_by_number(ref,$suggested_solution_number)]} {
		    set l_suggested_solution_item $solution_items_by_number(ref,$suggested_solution_number)
		} else {
		    set l_suggested_solution_item $solution_items_by_number(reg,$suggested_solution_number)
		}
		# Clear the current selection
		$itk_component(solution_tree) selection clear all
    
		# Select the chosen solution
		$itk_component(solution_tree) selection add $l_suggested_solution_item $l_suggested_solution_item
		
		# enable controls
		enable
    
		# Save the session (as history events have been added quickly)
		$::session writeToFile
	    }
	    
	    focus $itk_component(solution_tree)

	} 
    } else {
	#puts [$a_dom asXML]
	set bs_spot_deviation_pos [format %4.2f [$a_dom selectNodes normalize-space(//spot_deviation_pos)]]
	set bs_spot_deviation_phi [format %4.2f [$a_dom selectNodes normalize-space(//spot_deviation_phi)]]
	set bs_beam_x [$a_dom selectNodes normalize-space(//beam_x)]
	set bs_beam_y [$a_dom selectNodes normalize-space(//beam_y)]
	set bs_beam_shift_abs [format %4.2f [$a_dom selectNodes normalize-space(//beam_shift_abs)]]
	set bs_beam_shift_rel [$a_dom selectNodes normalize-space(//beam_shift_rel)]
	set bs_reflections_used [$a_dom selectNodes normalize-space(//reflections_used)]

	set bs_a [format %5.1f [$a_dom selectNodes {normalize-space(//a)}]]
	set bs_b [format %5.1f [$a_dom selectNodes {normalize-space(//b)}]]
	set bs_c [format %5.1f [$a_dom selectNodes {normalize-space(//c)}]]
	set bs_alpha [format %5.1f [$a_dom selectNodes {normalize-space(//alpha)}]]
	set bs_beta [format %5.1f [$a_dom selectNodes {normalize-space(//beta)}]]
	set bs_gamma [format %5.1f [$a_dom selectNodes {normalize-space(//gamma)}]]

	set start_beam_x [format %5.1f [lindex [lindex $beam_list [expr $grid_counter - 1] 0]]]
	set start_beam_y [format %5.1f [lindex [lindex $beam_list [expr $grid_counter - 1] 1]]]

	set bs_item [$itk_component(beamsearch_tree) item create]
	$itk_component(beamsearch_tree) item style set $bs_item 0 s2 1 s2 2 s2 3 s2 4 s2 5 s2 6 s2 7 s2 8 s2 9 s2 10 s2 11 s2 12 s2
	$itk_component(beamsearch_tree) item text $bs_item 0 $start_beam_x
	$itk_component(beamsearch_tree) item text $bs_item 1 $start_beam_y
	$itk_component(beamsearch_tree) item text $bs_item 2 $bs_beam_x
	$itk_component(beamsearch_tree) item text $bs_item 3 $bs_beam_y			
	$itk_component(beamsearch_tree) item text $bs_item 4 $bs_a
	$itk_component(beamsearch_tree) item text $bs_item 5 $bs_b
	$itk_component(beamsearch_tree) item text $bs_item 6 $bs_c
	$itk_component(beamsearch_tree) item text $bs_item 7 $bs_alpha
	$itk_component(beamsearch_tree) item text $bs_item 8 $bs_beta
	$itk_component(beamsearch_tree) item text $bs_item 9 $bs_gamma
	$itk_component(beamsearch_tree) item text $bs_item 10 $bs_spot_deviation_pos
	$itk_component(beamsearch_tree) item text $bs_item 11 $bs_spot_deviation_phi
	$itk_component(beamsearch_tree) item text $bs_item 12 $bs_beam_shift_abs
	
	$itk_component(beamsearch_tree) item lastchild root $bs_item
	$itk_component(beamsearch_tree) yview moveto 1.0

	if {![$::mosflm busy "indexing" "index_refinement"]} {
	enable
	}
	gridSearchRelay
    }
}

# Mosaicity & completion methods ######################################################

body Indexwizard::estimateMosaicity { } {
    # Launch mosaicity estimation with first image used in indexing
    set l_image [lindex $images_being_autoindexed 0]
    if {$l_image == ""} {
	set l_image [.image getImage]
    }
    eval .me launch $l_image
}

body Indexwizard::updateMosaicity { { a_mosaicity "" } } {
    set mosaicity_has_been_set 1
    if {$a_mosaicity != ""} {
	set mosaicity $a_mosaicity
    }
    if {$mosaicity != $previous_mosaicity} {
	set l_selected_solutions [$itk_component(solution_tree) selection get]
	toggleSolution [llength $l_selected_solutions] $l_selected_solutions
    }
}

body Indexwizard::updateIndexButton { } {
    # Count total spots
    set l_total 0
    foreach i_image [array names image_items_by_object] {
	set l_spotlist [$i_image getSpotlist]
	    incr l_total [format %3d [$l_spotlist getTotal]]
    }
    # Update button
    if {$l_total >= 12} {
	$itk_component(index_button) configure -state normal
    } else {
	$itk_component(index_button) configure -state disabled
    }
}

body Indexwizard::updateMosaicityButton { } {
    if {[$::session mosaicityEstimationPossible]} {
	$itk_component(mosaicity_estimate_b) configure -state normal
    } else {
	$itk_component(mosaicity_estimate_b) configure -state disabled
    }
}

body Indexwizard::fixMaxCellEdge { } {
    $itk_component(fix_max_cell_edge_tb) invoke
}

usual Indexwizard { 
} 

class SpotfindingPalette {
    inherit Palette

    private variable image_objects_by_number ; # NB array - don't initialize
    private variable image_objects_by_item ; # NB array - don't initialize
    private variable image_items_by_number ; # NB array - don't initialize
    private variable image_items_by_object ; # NB array - don't initialize

    public method launch
    public method buildImageList
    public method sortSpotFindingResults
    public method checkImage
    public method uncheckImage
    public method updateSpotFindingResult

    private method imageTreeClick
    private method imageTreeDoubleClick
    private method toggleSpotlistInclusion
    private method toggleImageSelection

    constructor { args } { }

}

body SpotfindingPalette::launch { a_button args } {
    buildImageList
    Palette::launch $a_button
}
    

body SpotfindingPalette::constructor { args } {

    itk_component add image_tree {
	treectrl .sfp.itree \
	    -showroot 0 \
	    -showline 0 \
	    -showbutton 0 \
	    -selectmode single \
	    -width 430 \
	    -height 356 \
	    -itemheight 18
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    }

    $itk_component(image_tree) column create -text "Image" -justify left -minwidth 80 -expand 1 ;#-itembackground {"\#ffffff" "\#e8e8e8"}
    $itk_component(image_tree) column create -text "\u03c6" -justify left -minwidth 120 -expand 1
    $itk_component(image_tree) column create -text "Auto" -justify center -minwidth 60 -expand 1 
    $itk_component(image_tree) column create -text "Manual" -justify center -minwidth 60 -expand 1
    $itk_component(image_tree) column create -text "Deleted" -justify center -minwidth 60 -expand 1
    $itk_component(image_tree) column create -text "> I/\u03c3(I)" -justify center -minwidth 80 -expand 1
    $itk_component(image_tree) column create -text "Search"  -justify center -minwidth 60 -tag search
    $itk_component(image_tree) column create -text "Use"  -justify center -minwidth 30 -tag use

    $itk_component(image_tree) state define CHECKED
    $itk_component(image_tree) state define AVAILABLE

    $itk_component(image_tree) element create e_icon image -image ::img::image
    $itk_component(image_tree) element create e_text text -fill {white selected}
    $itk_component(image_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
    $itk_component(image_tree) element create e_auto_search image -image { ::img::spot_search_auto {} }
    $itk_component(image_tree) element create e_check image -image { ::img::embed_check_on {CHECKED AVAILABLE} ::img::embed_check_off {AVAILABLE !CHECKED} ::img::embed_check_off_disabled {!AVAILABLE} }
	
    $itk_component(image_tree) style create s1
    $itk_component(image_tree) style elements s1 { e_highlight e_icon e_text }
    $itk_component(image_tree) style layout s1 e_icon -expand ns -padx {0 6}
    $itk_component(image_tree) style layout s1 e_text -expand ns
    $itk_component(image_tree) style layout s1 e_highlight -union [list e_icon e_text] -iexpand nse -ipadx 2
    
    $itk_component(image_tree) style create s2
    $itk_component(image_tree) style elements s2 {e_highlight e_text}
    $itk_component(image_tree) style layout s2 e_text -expand ns
    $itk_component(image_tree) style layout s2 e_highlight -union [list e_text] -iexpand nsew -ipadx 2

    $itk_component(image_tree) style create s3
    $itk_component(image_tree) style elements s3 {e_highlight e_auto_search}
    $itk_component(image_tree) style layout s3 e_highlight -union [list e_auto_search] -iexpand nsew -ipadx 2
    $itk_component(image_tree) style layout s3 e_auto_search -expand ns -padx {2 2}

    $itk_component(image_tree) style create s4
    $itk_component(image_tree) style elements s4 {e_highlight e_check}
    $itk_component(image_tree) style layout s4 e_highlight -union [list e_check] -iexpand nsew -ipadx 2
    $itk_component(image_tree) style layout s4 e_check -expand ns -padx {2 2}

    bind $itk_component(image_tree) <ButtonPress-1> [code $this imageTreeClick %W %x %y]
    bind $itk_component(image_tree) <Double-ButtonPress-1> [code $this imageTreeDoubleClick %W %x %y]
    bind $itk_component(image_tree) <ButtonRelease-1> { break }

    itk_component add image_scroll {
	scrollbar .sfp.iscroll \
	    -command [code $this component image_tree yview] \
	    -orient vertical
    }
    
    $itk_component(image_tree) configure \
	-yscrollcommand [list autoscroll $itk_component(image_scroll)]
    
    if {[tk windowingsystem] == "aqua"} {
	# Add a closing X as there was a problem dismissing the pop-up on an earlier aqua
	itk_component add exit_button {
	    button .sfp.eb -text "x"  \
		-command [code $this dismiss]
	}
	grid $itk_component(exit_button) -sticky ne -columnspan 2
    }

    grid $itk_component(image_tree) $itk_component(image_scroll)  -sticky nswe
    grid columnconfigure $itk_component(hull) 0 -weight 1

    eval itk_initialize $args
}

body SpotfindingPalette::buildImageList { } {

    # Configure the treectrl with apprpriate column width, and remove buttons/lines
    $itk_component(image_tree) configure -showlines 0 -showbuttons 0
    $itk_component(image_tree) column configure 0 -width {}

    # clear existing image arrays 
    array unset image_objects_by_number *
    array unset image_objects_by_item *
    array unset image_items_by_number *
    array unset image_items_by_object *

    # clear the image tree
    $itk_component(image_tree) item delete all


    ### Build list of images for tree

    # Choose labelling method depending on number of templates
    if {[llength [$::session getSectors]] > 1} {
	set l_labelMethod "getShortName"
    } else {
	set l_labelMethod "getNumber"
    }

    # loop through session's images...
    foreach i_image [$::session getImages] {
	# create a new item
	set t_item [$itk_component(image_tree) item create]
	# set the item's style
	$itk_component(image_tree) item style set $t_item 0 s1 1 s2 2 s2 3 s2 4 s2 5 s2 6 s3 7 s4
	# get the label to be used
	set l_label [$i_image $l_labelMethod]
	set l_phis [$i_image reportPhis -mode "range"]

	# get any existing spotlist
	set l_spotlist [$i_image getSpotlist]
	# depending on whether there's a spotlist or not...
	if {$l_spotlist != ""} {
	    # Set state to indicate spots are available from this image (but none checked yet)
	    $itk_component(image_tree) item state set $t_item [list AVAILABLE !CHECKED]
	    # Get the text summary for display in the image tree
	    set l_icon ::img::spotlist
	    set l_auto [format %3d [$l_spotlist getAuto]]
	    set l_manual [format %3d [$l_spotlist getManual]]
	    set l_deleted [format %3d [$l_spotlist getDeleted]]
	    set l_total [format %3d [$l_spotlist getTotalAboveIsigi]]
	} else {
	    # Set state to indicate spots are NOT available from this image
	    $itk_component(image_tree) item state set $t_item [list !AVAILABLE !CHECKED] 
	    # Make text summary indicating no spots searched for yet
	    set l_icon ::img::image
	    set l_auto " - "
	    set l_manual " - "
	    set l_deleted " - "
	    set l_total " - "
	}
	# update the image icon
	$itk_component(image_tree) item element configure $t_item 0 e_icon -image $l_icon
	# update the text summaries
	$itk_component(image_tree) item text $t_item 0 $l_label 1 $l_phis 2 $l_auto 3 $l_manual 4 $l_deleted 5 $l_total
	# add the new item to the tree
	$itk_component(image_tree) item lastchild root $t_item
	# Store pointer to image objects and items by number, item or object
	set image_objects_by_number([$i_image getNumber]) $i_image
	set image_objects_by_item($t_item) $i_image
	set image_items_by_number([$i_image getNumber]) $t_item
	set image_items_by_object($i_image) $t_item
    }
    
    # Check all images listed in main window
    foreach i_image [[.c component indexing] getIncludedImages] {
	checkImage $i_image
    }

    # Sort the image tree
    $itk_component(image_tree) item sort root -command [code $this sortSpotFindingResults]

    # Scroll to top of tree
    $itk_component(image_tree) yview moveto 0
    
}

body SpotfindingPalette::sortSpotFindingResults { a_item b_item } {
    #puts "SP:sort a_item $a_item b_item $b_item"
    set a_available [$itk_component(image_tree) item state get $a_item AVAILABLE]
    set b_available [$itk_component(image_tree) item state get $b_item AVAILABLE]
    if {$a_available && !$b_available} {
	return -1
    } elseif {!$a_available && $b_available} {
	return +1
    } else {
	if {[info exists image_objects_by_item($a_item)]} {
	    set a_image $image_objects_by_item($a_item)
	    set a_image_num [$a_image getNumber]
	}
	if {[info exists image_objects_by_item($b_item)]} {
	    set b_image $image_objects_by_item($b_item)
	    set b_image_num [$b_image getNumber]
	}
	if {$a_image_num < $b_image_num} {
	    return -1
	} elseif {$a_image_num > $b_image_num} {
	    return +1
	} else {
	    return 0
	}
    }
}

body SpotfindingPalette::imageTreeClick { w x y } {
    set id [$w identify $x $y]
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "header"} {
    } else {
	$w activate [$w index [list nearest $x $y]]
	foreach {what item where arg1 arg2 arg3} $id break
	if {[lindex $id 5] == "e_check"} {
	    toggleSpotlistInclusion $item
	}
    }
}

body SpotfindingPalette::imageTreeDoubleClick { w x y } {
    set id [$w identify $x $y]
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "header"} {
    } else {
	foreach {what item where arg1 arg2 arg3} $id {}
	if {[lindex $id 5] == "e_auto_search"} {
	    set choosing_images "0"
	    [.c component indexing] findSpots $image_objects_by_item($item)
	} elseif {[lindex $id 5] == "e_check"} {
	    toggleSpotlistInclusion $item
	}
    }
}

body SpotfindingPalette::toggleSpotlistInclusion { an_item } {
    set choosing_images 0
    # if the item is available...
    if {[$itk_component(image_tree) item state get $an_item AVAILABLE]} {
	if {[$itk_component(image_tree) item state get $an_item CHECKED]} {
	    uncheckImage $image_objects_by_item($an_item)
	    #puts "Item $an_item AVAILABLE now UNchecked"
	    [.c component indexing] removeImage $image_objects_by_item($an_item)
	} else {
	    checkImage $image_objects_by_item($an_item)
	    #puts "Item $an_item AVAILABLE  now  checked"
	    [.c component indexing] addImage $image_objects_by_item($an_item)
	}
    } else {
	#puts "Item $an_item not AVAILABLE"
    }
}

body SpotfindingPalette::checkImage { an_image } {
    catch {$itk_component(image_tree) item state set $image_items_by_object($an_image) CHECKED}
}

body SpotfindingPalette::uncheckImage { an_image } {
    catch {$itk_component(image_tree) item state set $image_items_by_object($an_image) !CHECKED}
}

body SpotfindingPalette::updateSpotFindingResult { a_image } {
    # Only bother if the image is in the wizard's list!
    if {[info exists image_items_by_object($a_image)]} {
	# get the image's item
	set l_item $image_items_by_object($a_image)
	# get the image's spotlist
	set l_spotlist [$a_image getSpotlist]
	# get the image's label in the image tree
	set l_label [$itk_component(image_tree) item text $l_item 0]
	if {$l_spotlist != ""} {
	    $itk_component(image_tree) item state set $l_item AVAILABLE
	    set l_icon ::img::spotlist
	    set l_auto [format %3d [$l_spotlist getAuto]]
	    set l_manual [format %3d [$l_spotlist getManual]]
	    set l_deleted [format %3d [$l_spotlist getDeleted]]
	    set l_total [format %3d [$l_spotlist getTotalAboveIsigi]]
	} else {
	    $itk_component(image_tree) item state set $l_item !AVAILABLE
	    set l_icon ::img::image
	    set l_auto " - "
	    set l_manual " - "
	    set l_deleted " - "
	    set l_total " - "
	}

	$itk_component(image_tree) item element configure $l_item 0 e_icon -image $l_icon
	$itk_component(image_tree) item text $l_item 2 $l_auto 3 $l_manual 4 $l_deleted 5 $l_total
	# Sort the image tree
	$itk_component(image_tree) item sort root -command [code $this sortSpotFindingResults]
    }
}
