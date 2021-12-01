# package name
package provide controller 3.0

# Class
class Controller {
    inherit itk::Widget

    # variables
    ###########

    # user profile
    private variable user_profile ""

    # launcher option variable
    private variable choice "1"
    
    # current stage
    private variable current_stage "hull"
    private variable previous_stage "hull"

    # status update queue
    private variable status_update_queue ""

    # main control first display flag
    private variable displayed_yet "0"

    # view menu options
    private variable showvariables "0"

    # name of session file
    private variable sessionfile ""

    # visual controls variables
    public variable image_files ""
    public variable selected_images ""
    public variable images_to_index ""

    # session tree variables
    private variable session_items_by_object ; # array
    private variable session_objects_by_item ; # array

    public variable temp_strategy_file ""
    public variable haveTempStrategyfile 0
    
    # methods
    #########

    # Initialization and shutdown

    public method initialize
    public method shutdown
    public method saveProfile

    # Interface configuration
    
    private method updateSessionMenu

    public method launch
    public method hide

    # activity and status methods
    public method busy
    public method errorMessage
    public method pause
    public method progress
    public method idle
    public method updateStatusMessage
    public method addWarning
    public method deleteWarning

    public method showAbout
    public method showWebpage

    public method disable
    public method enable
    private method toggleState

    public method showStage
    public method enableStage
    public method disableStage
    public method rollover
    public method rolloutof

    public method showIndexSettings
    public method showIntegrationSettings
    public method showExperimentSettings
    public method showHistory
    public method toggleIndexingSettings
    public method toggleExperimentSettings
    public method toggleIntegrationSettings
    public method toggleHistory

    public method enableIndexing
    public method disableIndexing
    public method enableProcessing
    public method disableProcessing

    # Session configuration

    public method addImages
    public method addSpots
    #public method deleteImages
    private method promptSaving
    public method saveSession
    public method saveSessionAs
    public method closeSession
    public method newSession
    public method openSession
    public method foo
    private method openSessionFile
    private method openTempStrategyFile
    public method getTempStrFilename
    public method existsTempStrFilename
    public method wroteTempStrFile    

    # Session tree methods
    public method displaySession
    public method addSector
    public method addImage
    public method updateCell
    public method updateSpacegroup
    public method updateMosaicity
    public method updateMosaicblock
    public method updateSector
    public method updateMatrix
    public method updateImage

    public method getObjectByItem

    public method doubleClickSession
    public method editTree

    public method editMatrixProperties

    # for context-sensitive right-click
    public method rightClickSession
    public method singleClickSession
    private variable lukesingle ""
    private variable lukesingle2 ""

    ###########################
    # Button callbacks
    public method estimateMosaicity

    public method uncheckAutothreshCheckbutton


    # Private methods
    
    private method refreshDialogs
    
    constructor { args } { }
    
}

# Bodies

body Controller::constructor { args } {
    
    # Prevent killing of main window
    wm protocol [winfo toplevel $itk_component(hull)]  WM_DELETE_WINDOW [code $this shutdown]

    # Set up width and height
    itk_option add hull.width hull.height
    $itk_component(hull) configure -width 1050 -height 768	
    wm minsize [winfo toplevel $itk_component(hull)] 1024 600
    pack propagate $itk_interior 0

    ### Menu bar and menus ####################################

    itk_component add menu {
	menu $itk_interior.menu \
	    -tearoff 0 \
	    -borderwidth 1
    } 
    
    [winfo toplevel $itk_component(hull)] configure \
	 -menu $itk_component(menu)
    
    itk_component add sessionmenu {
	menu $itk_interior.menu.session \
	    -tearoff 0
    }
    
    $itk_component(menu) add cascade \
	-label "Session" \
	-menu $itk_component(sessionmenu)

        
    if {[tk windowingsystem] == "aqua"} {
	set newSessionAccelerator "Command-N"
	set openSessionAccelerator "Command-O"
	set saveSessionAccelerator "Command-S"
	set exitAccelerator "Command-F4"
    } {
	set newSessionAccelerator "Control-N"
	set openSessionAccelerator "Control-O"
	set saveSessionAccelerator "Control-S"
	set exitAccelerator "Alt-F4"
    }

    $itk_component(sessionmenu) add command \
	-label New \
	-underline 0 \
	-accelerator $newSessionAccelerator \
	-command [code $this newSession]
    
    $itk_component(sessionmenu) add command \
	-label "Open..." \
	-underline 0 \
	-accelerator $openSessionAccelerator \
	-command [code $this openSession]
    
    $itk_component(sessionmenu) add command \
	-label "Save" \
	-underline 0 \
	-accelerator $saveSessionAccelerator \
	-command [code $this saveSession]
    
    $itk_component(sessionmenu) add command \
	-label "Save as..." \
	-underline 5 \
	-command [code $this saveSessionAs]
    
    $itk_component(sessionmenu) add separator
    
    $itk_component(sessionmenu) add command \
	-label "Add images..." \
	-underline 4 \
	-command [code $this addImages]

    $itk_component(sessionmenu) add command \
	-label "Read spots file..." \
	-underline 6 \
	-command [code $this addSpots]

    $itk_component(sessionmenu) add separator
    
    $itk_component(sessionmenu) add command \
	-label "Exit" \
	-underline 1 \
	-accelerator $exitAccelerator \
	-command [code $this shutdown]
    
    # Settings menu - was View #################################
    
    itk_component add viewmenu {
	menu $itk_interior.menu.view \
	    -tearoff false
    }
    
    $itk_component(menu) add cascade \
	-label "Settings" \
	-menu $itk_component(viewmenu)

    $itk_component(viewmenu) add command \
	-label "Experiment settings" \
	-underline 2 \
	-command {.ass show}

    $itk_component(viewmenu) add command \
	-label "Processing options" \
	-underline 2 \
	-command {.ats show}

    $itk_component(viewmenu) add command \
	-label "Environment variables" \
	-underline 2 \
	-command {.evs show}

    # Help menu ################################################
    
    itk_component add helpmenu {
            menu $itk_interior.menu.help \
		-tearoff false
    }
    
    $itk_component(menu) add cascade \
	-label "Help" \
	-menu $itk_component(helpmenu)

    # Nothing to separate from yet
    #$itk_component(helpmenu) add separator
    
    $itk_component(helpmenu) add command \
	-label "iMosflm web pages" \
	-underline 0 \
	-command [code $this showWebpage "$::env(MOSFLM_GUI)/meta.html"]

    $itk_component(helpmenu) add command \
	-label "About iMosflm" \
	-underline 0 \
	-command [code $this showAbout]

    # Add menu icons on linux

    if {($::tcl_platform(os) != "Darwin") &&
	($::tcl_platform(os) != "Windows NT")} {
	
	$itk_component(sessionmenu) entryconfigure 0 \
	    -compound left \
	    -image ::img::file16x16

	$itk_component(sessionmenu) entryconfigure 1 \
	    -compound left \
	    -image ::img::folder16x16

	$itk_component(sessionmenu) entryconfigure 2 \
	    -compound left \
	    -image ::img::disk16x16

	$itk_component(sessionmenu) entryconfigure 3 \
	    -compound left \
	    -image ::img::blank16x16

	$itk_component(sessionmenu) entryconfigure 5 \
	    -compound left \
	    -image ::img::add_image

	$itk_component(sessionmenu) entryconfigure 6 \
	    -compound left \
	    -image ::img::spot16x16

	$itk_component(sessionmenu) entryconfigure 8 \
	    -compound left \
	    -image ::img::blank16x16

	$itk_component(sessionmenu) entryconfigure 10 \
	    -compound left \
	    -image ::img::blank16x16

	$itk_component(viewmenu) entryconfigure 0 \
	    -compound left \
	    -image ::img::experimentsettings

	$itk_component(viewmenu) entryconfigure 1 \
	    -compound left \
	    -image ::img::settings16x16

	$itk_component(viewmenu) entryconfigure 2 \
	    -compound left \
	    -image ::img::pinetree16x16
    }

    ### Tool bar and toolbuttons ##############################
    ###########################################################

    itk_component add toolbar_frame {
	frame $itk_interior.tbf \
	    -relief raised \
	    -borderwidth 1
    }

    itk_component add toolbar {
	frame $itk_interior.tbf.toolbar
    }
    
    itk_component add new_tb {
	Toolbutton $itk_interior.tbf.toolbar.ntb \
	    -image ::img::file16x16 \
	    -command [code $this newSession] \
	    -balloonhelp "New session"
    }
    
    itk_component add open_tb {
	Toolbutton $itk_interior.tbf.toolbar.otb \
	    -image ::img::folder16x16 \
	    -command [code $this openSession] \
	    -balloonhelp "Open saved session"
    }
    
    itk_component add save_tb {
	Toolbutton $itk_interior.tbf.toolbar.stb \
	    -image ::img::disk16x16 \
	    -command [code $this saveSession] \
	    -balloonhelp "Save session"
    }
            
    ### Activity indicator ####################################
    ###########################################################

    itk_component add activity_l {
	Activity $itk_interior.tbf.al \
    }
    $itk_component(activity_l) idle

    # Main area frame
    ###########################################################


    itk_component add body {
	frame $itk_interior.body \
	    -borderwidth 1 \
	    -relief raised
    }

    ### Stage Menu controls ###################################

    itk_component add stages {
	canvas $itk_interior.body.stages \
	    -relief sunken \
	    -bd 2 \
	    -bg white \
	    -width 100 \
	    -highlightthickness 0
    }

    set l_stage_name(hull) "Images"
    set l_stage_name(indexing) "Indexing"
    set l_stage_name(strategy) "Strategy"
    set l_stage_name(cell_refinement) "Cell Refinement"
    set l_stage_name(integration) "Integration"
    #set l_stage_name(pointless) "Pointless"
    set l_stage_name(history) "History"

    set i_y 10
    foreach i_stage { hull indexing strategy cell_refinement integration  history} {
	$itk_component(stages) create rectangle \
	    -5 $i_y 105 [expr $i_y + 5 + 32 + 14 + 5] \
	    -fill {} \
	    -outline {} \
	    -tags box($i_stage)
	$itk_component(stages) create image 50 [expr $i_y + 5] \
	    -image ::img::stage_${i_stage} \
	    -anchor n \
	    -tags icon($i_stage)
	$itk_component(stages) create text 50 [expr $i_y + 5 + 32] \
	    -text $l_stage_name($i_stage) \
	    -anchor n \
	    -tags label($i_stage)
	$itk_component(stages) create rectangle \
	    -5 $i_y 105 [expr $i_y + 5 + 32 + 14 + 5] \
	    -fill {} \
	    -outline {} \
	    -tags overlay($i_stage)
	$itk_component(stages) bind overlay($i_stage) <Enter> \
	    [code $this rollover $i_stage]
	$itk_component(stages) bind overlay($i_stage) <Leave> \
	    [code $this rolloutof $i_stage]
	$itk_component(stages) bind overlay($i_stage) <1> \
	    [code $this showStage $i_stage]
	set i_y [expr $i_y + 5 + 32 + 10 + 5 + 10]
    }
    

    foreach i_stage { indexing strategy cell_refinement integration } {
	disableStage $i_stage
    }

    ### Indexing controls ##################################
    
    itk_component add indexing {
	Indexwizard $itk_interior.body.indexing
    }

    ### Strategy controls ##################################
    
    itk_component add strategy {
	StrategyWidget $itk_interior.body.strategy
    }

    ### Cellrefinement controls ##################################
    
    itk_component add cell_refinement {
	Cellrefinementwizard $itk_interior.body.cellref
    }

    ### Integration controls ##################################
    
    itk_component add integration {
	Integrationwizard $itk_interior.body.integration 
    }

    ### Mosflm output log #####################################
    
    itk_component add history {
	HistoryViewer $itk_interior.body.outputlog
    }

#    itk_component add pointless {
#	    Pointlesswizard $itk_interior.body.pointless
#    }

    # Status bar ##############################################

    itk_component add status_bar {
	frame $itk_interior.body.sb \
	    -relief flat \
	    -borderwidth 0
    } {
	usual
	ignore -borderwidth
    }

    itk_component add status_message {
	label $itk_interior.body.sb.m \
	    -relief sunken \
	    -borderwidth 2 \
	    -anchor w \
	    -highlightthickness 0
    }

    itk_component add progress_bar {
	Progressbar $itk_interior.body.sb.p \
	    -borderwidth 2 \
	    -relief sunken \
	    -height 10 \
	    -width 200
    }

    itk_component add warnings {
	WarningWidget $itk_interior.body.sb.ww \
	    -deletecommand [code $this deleteWarning]
    }

    ### Main controls #########################################
    
    itk_component add main {
	frame $itk_interior.body.main \
	    -borderwidth 0 \
	    -relief raised
        } {
            keep -background
            keep -width
        }
    
    # Toolbars ###############################################

    itk_component add images_toolbar {
	frame $itk_component(toolbar_frame).images
    }

    # Divider

    itk_component add divider {
	frame $itk_component(images_toolbar).div1 \
	    -width 2 \
	    -relief sunken \
	    -bd 1
    }

    itk_component add add_images_tb {
	Toolbutton $itk_component(images_toolbar).aitb \
	    -image ::img::add_image \
	    -balloonhelp "Add images..." \
	    -command [code $this addImages]
    }

    itk_component add beam_x_e {
        SettingEntry $itk_component(images_toolbar).bxe beam_x \
	    -image ::img::beam_x16x16 \
	    -balloonhelp "Beam x position" \
	    -type real \
	    -precision 2 \
	    -width 6 \
	    -justify right 
    }

    itk_component add beam_y_e {
        SettingEntry $itk_component(images_toolbar).bye beam_y \
	    -image ::img::beam_y16x16 \
	    -balloonhelp "Beam y position" \
	    -type real \
	    -precision 2 \
	    -width 6 \
	    -justify right 
    }

    itk_component add distance_e {
        SettingEntry $itk_component(images_toolbar).de distance \
	    -image ::img::distance16x16 \
	    -balloonhelp "Crystal to detector distance" \
	    -type real \
	    -precision 2 \
	    -width 6 \
	    -justify right 
    }

    # Images frame ####################################################    

    itk_component add heading_f {
	frame $itk_interior.body.main.hf \
	    -bd 1 \
	    -relief solid 
    }

    itk_component add heading_l {
	label $itk_interior.body.main.hf.fl \
	    -text "Images" \
	    -font title_font \
	    -anchor w
    } {
	usual
	ignore -font
    }

    itk_component add session_tree {
	treectrl $itk_interior.body.main.st \
	    -showroot 0 \
	    -showrootlines 0 \
	    -showheader 0 \
	    -selectmode single \
	    -width 800 \
	    -height 414
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    }
    
    $itk_component(session_tree) column create -text Session -tag session -justify left -width 300 -expand 1 ;# -itembackground {"\#ffffff" "\#e8e8e8"} 
    $itk_component(session_tree) column create -text Value -tag value -justify left  -visible 1 -expand 1;#-itembackground {"\#ffffff" "\#e8e8e8"}
    $itk_component(session_tree) column create -text Order -tag order_column -justify left  -visible 0 ;#-itembackground {"\#ffffff" "\#e8e8e8"}

    $itk_component(session_tree) element create e_icon image -image ::img::raw_solution
    $itk_component(session_tree) element create e_text text -fill {white selected}
    $itk_component(session_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
	
    $itk_component(session_tree) style create s1
    $itk_component(session_tree) style elements s1 { e_highlight e_icon e_text }
    $itk_component(session_tree) style layout s1 e_icon -expand ns -padx {0 6} -pady {1 1}
    $itk_component(session_tree) style layout s1 e_text -expand ns
    $itk_component(session_tree) style layout s1 e_highlight -union [list e_text] -iexpand nse -ipadx 2
    
    $itk_component(session_tree) style create s2
    $itk_component(session_tree) style elements s2 {e_highlight e_text}
    $itk_component(session_tree) style layout s2 e_text -expand ns
    $itk_component(session_tree) style layout s2 e_highlight -union [list e_text] -iexpand nsew -ipadx 2
    
    $itk_component(session_tree) style create s3
    $itk_component(session_tree) style elements s3 {e_highlight e_text}
    $itk_component(session_tree) style layout s3 e_text -expand ns
    $itk_component(session_tree) style layout s3 e_highlight -union [list e_text] -iexpand nsew -ipadx 2
    
    bind $itk_component(session_tree) <Double-ButtonPress-1> [code $this doubleClickSession %W %x %y]

    bindtags $itk_component(session_tree) [list $itk_component(session_tree) TreeCtrlFileList TreeCtrl [winfo toplevel $itk_component(session_tree)] all]
    # Editing bindings

    $itk_component(session_tree) notify install <Edit-begin>
    $itk_component(session_tree) notify install <Edit-end>
    $itk_component(session_tree) notify install <Edit-accept>

    # List of lists: {column style element ...} specifying text elements
    # the user can edit
    TreeCtrl::SetEditable $itk_component(session_tree) {
	{value s3 e_text}
    }
    
    # List of lists: {column style element ...} specifying elements
    # the user can click on or select with the selection rectangle
    TreeCtrl::SetSensitive $itk_component(session_tree) {
	{session s1 e_icon e_text e_highlight} {value s2 e_text e_highlight} {value s3 e_text e_highlight}
    }
    
    # List of lists: {column style element ...} specifying elements
    # added to the drag image when dragging selected items
    TreeCtrl::SetDragImage $itk_component(session_tree) {
	{session s1 e_icon e_text}
    }
    
    # During editing, hide the text and selection-rectangle elements.
    $itk_component(session_tree) notify bind $itk_component(session_tree) <Edit-begin> {
	%T item element configure %I %C e_text -draw no;# + e_highlight -draw no
    }
    $itk_component(session_tree) notify bind $itk_component(session_tree) <Edit-accept> [code $this editTree %I %C %E %t]

    $itk_component(session_tree) notify bind $itk_component(session_tree) <Edit-end> {
	%T item element configure %I %C e_text -draw yes;# + e_highlight -draw yes
    }

    #added by luke 19 October 2007
    itk_component add contextmenu {
	menu $itk_component(session_tree).context -tearoff 0
    }
    
    $itk_component(contextmenu) add command -label "delete" -command [code $this rightClickSession]
    
    ########################################################################
    bind $itk_component(session_tree) <3> [code tk_popup $itk_component(contextmenu) %X %Y]
    bind $itk_component(session_tree) <1> [code $this singleClickSession %W %x %y]
    #####################################################################
   
    itk_component add session_scroll {
	scrollbar $itk_interior.body.main.sscroll \
	    -command [code $this component session_tree yview] \
	    -orient vertical
    }
    
    $itk_component(session_tree) configure \
	-treecolumn 0 \
	-yscrollcommand [list autoscroll $itk_component(session_scroll)]

    # Toolbar layout
    pack $itk_component(divider) \
	-side left \
	-fill y \
	-padx 2 \
	-pady 1

    pack $itk_component(add_images_tb) $itk_component(beam_x_e) $itk_component(beam_y_e) $itk_component(distance_e) \
 	-side left \
	-padx 2

    # Images panel layout 
    grid $itk_component(heading_f) - -sticky nswe -padx 7 -pady {7 0}
    pack $itk_component(heading_l) -side left -padx 5 -pady 5 -fill both -expand 1
    grid $itk_component(session_tree) $itk_component(session_scroll) -sticky news -padx 7 -pady 7
    grid columnconfigure $itk_component(main) 0 -weight 1
    grid rowconfigure $itk_component(main) 1 -weight 1
           
    # Set up global accelerator bindings - Macs use "Command" not "Control" usually
    if {[tk windowingsystem] == "aqua"} {
    bind [winfo toplevel $itk_component(hull)] <Command-n> [code $this newSession]
    bind [winfo toplevel $itk_component(hull)] <Command-N> [code $this newSession]
    bind [winfo toplevel $itk_component(hull)] <Command-o> [code $this openSession]
    bind [winfo toplevel $itk_component(hull)] <Command-O> [code $this openSession]
    bind [winfo toplevel $itk_component(hull)] <Command-s> [code $this saveSession]
    bind [winfo toplevel $itk_component(hull)] <Command-S> [code $this saveSession]
    bind [winfo toplevel $itk_component(hull)] <Command-F4> [code $this shutdown]
    } {
    bind [winfo toplevel $itk_component(hull)] <Control-n> [code $this newSession]
    bind [winfo toplevel $itk_component(hull)] <Control-N> [code $this newSession]
    bind [winfo toplevel $itk_component(hull)] <Control-o> [code $this openSession]
    bind [winfo toplevel $itk_component(hull)] <Control-O> [code $this openSession]
    bind [winfo toplevel $itk_component(hull)] <Control-s> [code $this saveSession]
    bind [winfo toplevel $itk_component(hull)] <Control-S> [code $this saveSession]
    bind [winfo toplevel $itk_component(hull)] <Alt-F4> [code $this shutdown]
    }
    bind [winfo toplevel $itk_component(hull)] <Alt-i> [code $this showStage "hull"]
    bind [winfo toplevel $itk_component(hull)] <Alt-I> [code $this showStage "hull"]
    bind [winfo toplevel $itk_component(hull)] <Alt-a> [code $this showStage "indexing"]
    bind [winfo toplevel $itk_component(hull)] <Alt-A> [code $this showStage "indexing"]
    bind [winfo toplevel $itk_component(hull)] <Alt-s> [code $this showStage "strategy"]
    bind [winfo toplevel $itk_component(hull)] <Alt-S> [code $this showStage "strategy"]
    bind [winfo toplevel $itk_component(hull)] <Alt-c> [code $this showStage "cell_refinement"]
    bind [winfo toplevel $itk_component(hull)] <Alt-C> [code $this showStage "cell_refinement"]
    bind [winfo toplevel $itk_component(hull)] <Alt-p> [code $this showStage "integration"]
    bind [winfo toplevel $itk_component(hull)] <Alt-P> [code $this showStage "integration"]
    bind [winfo toplevel $itk_component(hull)] <Alt-h> [code $this showStage "history"]
    bind [winfo toplevel $itk_component(hull)] <Alt-H> [code $this showStage "history"]

#    bind [winfo toplevel $itk_component(hull)] <Alt-l> [code $this showStage "pointless"]

    # Controller layout ###############################################
    # Tools
    pack $itk_component(toolbar_frame) -side top -fill x
    pack $itk_component(toolbar) -side left
    pack $itk_component(new_tb) -side left
    pack $itk_component(open_tb) -side left
    pack $itk_component(save_tb) -side left
    # Activity indicator
    pack $itk_component(activity_l) -side right -padx {0 7}
    # Body
    pack $itk_component(body) -side top -fill both -expand 1
    # Stages menu
    grid $itk_component(stages) -row 0 -column 0 -padx {7 0} -pady 7 -sticky ns
    # Main frame
    grid $itk_component(main) -row 0 -column 1 -sticky nswe
    # Status bar
    grid $itk_component(status_bar) -row 1 -column 0 -columnspan 2  -padx 7 -pady {0 7} -sticky we
    grid columnconfigure $itk_component(body) 1 -weight 1
    grid rowconfigure $itk_component(body) 0 -weight 1

    grid $itk_component(status_message) -row 0 -column 0 -stick we -padx {0 2}
    grid $itk_component(progress_bar) -row 0 -column 1 -stick nswe -padx {0 2}
    grid $itk_component(warnings) -row 0 -column 2 -stick we
    grid columnconfigure $itk_component(status_bar) 0 -weight 1
    grid remove $itk_component(progress_bar)

    eval itk_initialize $args

}

########################################################################
# Initialization and shutdown                                          #
########################################################################

body Controller::initialize { } {
    # Check to see if .mosflm directory exists in user home directory
    set ::mosflm_directory [file join $::env(HOME) ".mosflm"] 
    # If .mosflm directory doesn't exist, make it.
    if {![file exists $::mosflm_directory]} {
	if {[catch {file mkdir $::mosflm_directory} message]} {
	    # report failure to create .mosflm directory 
	    error "Could not create .mosflm directory in $::env(HOME)\nPlease check your permissions and HOME environment variable."
	    exit
	} else {
	    # success
	    # Set flag indicating no clean up necessary
	    set l_cleanup 0
	}
    } else {
	# Set flag indicating clean up may be necessary
	set l_cleanup 1
    }

#Below I am writing a file and checking whether the operation is successful. 
#If the write is successful then we can safely launch mosflm which writes out
#a number of files.
#If the write opearation is unsuccesful, a message window pops up
#advising the user to change to a directory in which he/she has write
#permission.
    if { ![regexp -nocase windows $::tcl_platform(os)] } {
	if {![catch {open dirwrite.test w} errormessage]} {
	    file delete dirwrite.test
	} else {
	    .m configure \
		-type "1button" \
		-title "Startup Error" \
		-text "You do not have write permission for the directory from which you launched imosflm. \n Move to a directory for which you have write permission and relaunch imosflm" \
		-button1of1 "Exit"
	    if {[.m confirm]} {
		exit
	    } else {
		#I put in the exit command below in case the user clicks on the x button
		#at the top right of the message window rather than hitting the exit button
		exit
	    }
	}
    }
#   # Try and read saved execuable location
#   if {[file exists [file join $::mosflm_directory .mosflm_executable]]} {
# 	# if there's a  .mosflm_executable file, read the executbale from it
# 	set l_file [open [file join $::mosflm_directory .mosflm_executable] r]
# 	gets $l_file l_executable
#     } else {
# 	set l_executable ""
#     }

    # Try and read MOSFLM_EXEC environment variable
    if {[info exists ::env(MOSFLM_EXEC)]} {
	if { [regexp -nocase windows $::tcl_platform(os)] } {
	    set l_executable [string map {"\\" "/"} $::env(MOSFLM_EXEC)]
	} else {
	    set l_executable $::env(MOSFLM_EXEC)
	}
	
    } else {
	set l_executable ""
    }

    set l_valid_exe_found 0
    while {!$l_valid_exe_found} {
	# If an executable has been named...
	if {$l_executable != ""} {
	    # test the executable, by running it
	    if {![catch {exec $l_executable << exit} l_result]} {
		if { [regexp -nocase windows $::tcl_platform(os)] } {
		    set summary_filename [file join $::env(MOSDIR) "SUMMARY"]
		    #set summary_filename [list $summary_filename]
		    if {[file exists $summary_filename]} {
			file delete $summary_filename
		    }
		}
		# search output for correct version number
		set mos_req "ersion $::env(MOSFLM_VERSION_REQUIRED)"
		if { [regexp "$mos_req" $l_result] } {
		    # XML output of image_template in bad_spots_response required 7.0.8
		    # but 7.0.8 bugfix release is now 7.0.9 & was released in May 2012
		    set ::mosflm_executable $l_executable
		    break
		} else {
		    set l_message ""
		    append l_message "$::env(IMOSFLM_VERSION)\n\n"
		    append l_message "\"$l_executable\" is not compatible.\n\n"
		    append l_message "Please configure iMosflm with the correct executable.\n\n"
		}
	    } else {
		set l_message ""
		append l_message "$::env(IMOSFLM_VERSION)\n\n"
		append l_message "iMosflm cannot run \"$l_executable\":\n\n"
		append l_message "$l_result\n\n"
		append l_message "Please configure iMosflm with the correct executable."
	    }
	} else {
	    set l_message ""
	    append l_message "$::env(IMOSFLM_VERSION)\n\n"
	    append l_message "Please configure iMosflm with the correct executable.\n\n"
	    append l_message "(You can avoid having to configure iMosflm each time by\n"
	    append l_message "setting the full pathname of your mosflm executable in\n"
	    append l_message "the environment variable MOSFLM_EXEC.)"
	}
	# No executbale found yet, so prompt user configuration
	.m configure \
	    -type "2button" \
	    -text $l_message \
	    -button1of2 "Configure" \
	    -button2of2 "Exit"

	if {![.m confirm]} {
	    # User didn't want to configure, so quit
	    exit
	} else {
	    # Get exectuable file from user
	    if {![winfo exists .mosflmExecutable]} {
		Fileopen .mosflmExecutable \
		    -type open \
		    -initialdir [pwd] \
		    -filtertypes {{"All Files" {.*}}}
	    }
	    set l_executable [.mosflmExecutable get]    
	}
    }

    # Create user profile
    set l_profile_file [file join $::mosflm_directory .profile]
    set user_profile [namespace current]::[UserProfile \#auto $l_profile_file]
    # Add recent sessions to session menu
    updateSessionMenu
    # Add batch destinations to batch dialogs
    .bcd initialize

    if { [info exists ::env(MOSFLMFILE)] && $::env(MOSFLMFILE) == 1 } {
	set l_initfile 1
    } else {
	set l_initfile 0
    }

    # If there was an existing .mosflm directory (then the cleanup flag will be set)
    if {($l_cleanup == 1)} {
	# check for spot files, and delete any found
	set l_spotfiles [glob -nocomplain -directory $::mosflm_directory -- msf*.tmp]
	set l_spotfiles [concat $l_spotfiles [glob -nocomplain -directory $::mosflm_directory -- *.spt]]
	set l_spotfiles [concat $l_spotfiles [glob -nocomplain -directory $::mosflm_directory -- spt*.lst]]
	set l_spotfiles [concat $l_spotfiles [glob -nocomplain -directory $::mosflm_directory -- spt*.hdr]]
	foreach i_spotfile $l_spotfiles {
	    file delete -- $i_spotfile
	}
	# check for strategy files, and delete any found
	set l_strategyfiles [glob -nocomplain -directory $::mosflm_directory -- *.str]
	foreach i_strategyfile $l_strategyfiles {
	    file delete -- $i_strategyfile
	}
	# Check for 'unsaved' sessions
	set l_sessions [glob -nocomplain -directory $::mosflm_directory -- *.mpr]
	set l_num_sessions [llength $l_sessions]
	if {$l_num_sessions == 0} {
	    # No recoverable sessions, so make a new one
	    newSession
	} else {
	    # Offer user chance to recover previous unsaved work
	    set l_temp_file [.srd confirm]
	    if {$l_temp_file != "0"} {
		debug "Controller: Recovering saved session"
		openSessionFile $l_temp_file
	    } else {
		debug "Controller: Starting new session"
		newSession
	    }
	}
    } else {
	# No clean up required - just start new session
	newSession
    }
    #puts "MOSFLMFILE environment variable is $::env(MOSFLMFILE)"
    if { $l_initfile } {
	puts "Initializing from copy in $::mosflm_directory/initfile"
        $::session initializeFromFile "$::mosflm_directory/initfile"
    }
}

body Controller::shutdown { } {
    # If there is a user profile, try and save it.
    if {$user_profile != ""} {
	if [catch {$user_profile serialize} error] {
	    puts "Failed to save iMosflm user profile: $error"
	}
    }
    # Close the session
    if {![closeSession]} {
	# If the user didn't cancel, exit
	exit
    }
}

body Controller::saveProfile { } {
    if {$user_profile != ""} {
	$user_profile queueSave
    }
}

########################################################################
# Interface configuration                                              #
########################################################################

body Controller::updateSessionMenu { } {

    # Remove recent session entries
    while {([$itk_component(sessionmenu) type end] == "separator") || ([$itk_component(sessionmenu) entrycget end -label] != "Exit")} {
	$itk_component(sessionmenu) delete end
    }

    # Get list of recent files
    set l_file_list [$user_profile getRecentSessions]

    # If there are any recent sessions...
    if {[llength $l_file_list] > 0} {

	# Add a separator
	$itk_component(sessionmenu) add separator

	set i_count 0
	# Loop through files...
	foreach i_file $l_file_list {
	    # ...adding command entries
	    $itk_component(sessionmenu) add command \
		-label "$i_count [::abbreviatePath $i_file 50]" \
		-underline 0 \
		-command [code $this openSession $i_file]
	    # If it's unix or linux, add an icon too
	    if {($::tcl_platform(os) != "Darwin") &&
		($::tcl_platform(os) != "Windows NT")} {
		$itk_component(sessionmenu) entryconfigure end \
		    -compound left \
		    -image ::img::mosflm_session_file16x16
	    }
	    incr i_count
	}
    }
}

body Controller::launch { } {
    # Launch images panel and toolbar
    grid $itk_component(main) -row 0 -column 1 -sticky  nswe
    pack $itk_component(images_toolbar) -side left
}

body Controller::hide { } {
    # Hide images panel and toolbar
    grid forget $itk_component(main)
    pack forget $itk_component(images_toolbar) 
}

body Controller::busy { { a_message "" } } {
    # Set activity indicator to busy (with tooltip message)
    $itk_component(activity_l) busy $a_message
    # Also display message in status bar
    if {$a_message != ""} {
	$itk_component(status_message) configure -text $a_message
    }
}

body Controller::errorMessage { { a_message "Error" } } {
    # Set activity indicator to "warning" (with tooltip message)
    $itk_component(activity_l) warn $a_message
    # Also set message in status bar
    $itk_component(status_message) configure -text $a_message
}

body Controller::pause { { a_message "Paused" } } {
    # Set activity indicator to "paused"
    $itk_component(activity_l) pause
    # Also set message in status bar
    $itk_component(status_message) configure -text $a_message
}

body Controller::progress { a_percent } {
    # Display the progress bar
    grid $itk_component(progress_bar)
    # Update the progress bar
    $itk_component(progress_bar) update [expr $a_percent / 100.0]
}

body Controller::idle { } {
    # Set the activity indicator to "idle"
    $itk_component(activity_l) idle
    # Remove progress bar
    grid remove $itk_component(progress_bar)
    # Set status message to "Done"
    $itk_component(status_message) configure -text "Done"
    # Schedule removal of "Done" message after 2.5 seconds
    set status_update_queue [after 2500 [code $this updateStatusMessage]]
}

body Controller::updateStatusMessage { { a_message "" } } {
    # Cancel any scheduled changes to the status bar message
    if {$status_update_queue != ""} {
	after cancel $status_update_queue
	set status_update_queue ""
    }
    # Put the message in the status bar
    $itk_component(status_message) configure -text $a_message
}

body Controller::addWarning { a_warning } {
    $itk_component(warnings) addWarning $a_warning
}

body Controller::deleteWarning { a_warning } {
    if {$::session != ""} {
	$::session deleteWarning $a_warning
    }
}

body Controller::showAbout { } {
    # Show the "About" dialog
    .about show
}

body Controller::showWebpage { url } {
    # Open given URL
    # The following line within the [catch "..." message] always failed on Windows7
    # with the misleading Dismiss popup that it could not launch Internet Explorer
    if { [regexp -nocase windows $::tcl_platform(os)] } {
    # Also in pointlesswizard which does not seem to work with open_url
	exec [regsub -all \" $::env(CCP4_BROWSER) ""] $url &
    } else {
        open_url $url
    }
}

# disbaling and enabling ##################################

body Controller::disable { } {
    # disable tools and menus
    toggleState "disabled"
    # call disable for stages and image display
    foreach i_stage { indexing strategy cell_refinement integration } {
	$itk_component($i_stage) disable
    }
    .image disable
}

body Controller::enable { } {
    # enable tools and menus
    toggleState "normal"
    # call enable for stages and image display
    foreach i_stage { indexing strategy cell_refinement integration } {
	$itk_component($i_stage) enable
    }
    .image enable
}

body Controller::toggleState { a_state } { 
    # sets the state of all tools and menus

    # session menu
    $itk_component(menu) entryconfigure 0 -state $a_state

    # session toolbuttons
    $itk_component(new_tb) configure -state $a_state
    $itk_component(open_tb) configure -state $a_state
    $itk_component(save_tb) configure -state $a_state
    $itk_component(add_images_tb) configure -state $a_state
}   

# stages ##################################################

body Controller::showStage { a_stage } {
    # Send focus to stages menu, to force SettingEntry update
    focus $itk_component(stages)

    # Restore current stage's icon to unselected state
    $itk_component(stages) itemconfigure box($current_stage) \
	-fill {} \
	-outline {}

    # hide current stage
    $itk_component($current_stage) hide

    # Store previous stage (in case of reversion)
    set previous_state $current_stage

    # update the record of current stage
    set current_stage $a_stage

    # Update new stage's icon
    $itk_component(stages) itemconfigure box($current_stage) \
	-fill "\#dcdcdc" \
	-outline "\#bbbbbb"

    # display the panel
    $itk_component($a_stage) launch

}

body Controller::disableStage { a_stage } {
    # disable stage icon in menu
    $itk_component(stages) itemconfigure icon($a_stage) \
	-image ::img::stage_${a_stage}_haze
    # grey out text
    $itk_component(stages) itemconfigure label($a_stage) \
	-fill "lightgrey"    
    # disable bindings
    $itk_component(stages) bind overlay($a_stage) <Enter> {}
    $itk_component(stages) bind overlay($a_stage) <Leave> {}
    $itk_component(stages) bind overlay($a_stage) <1> {}
}

body Controller::enableStage { a_stage } {
    # enable stage icon in menu
    $itk_component(stages) itemconfigure icon($a_stage) \
	-image ::img::stage_${a_stage}
    # colour text black
    $itk_component(stages) itemconfigure label($a_stage) \
	-fill "black"
    # set up bindings
	$itk_component(stages) bind overlay($a_stage) <Enter> \
	[code $this rollover $a_stage]
    $itk_component(stages) bind overlay($a_stage) <Leave> \
	[code $this rolloutof $a_stage]
    $itk_component(stages) bind overlay($a_stage) <1> \
	[code $this showStage $a_stage]
}

body Controller::rollover { a_stage } {
    # Shades stage button (if not already current stage or disabled)
    if {$a_stage != $current_stage} {
	if {[$itk_component(stages) itemcget icon($a_stage) -image] != "::img::stage_${a_stage}_haze"} {
	    $itk_component(stages) itemconfigure box($a_stage) \
		-fill "\#eeeeee" \
		-outline "\#dcdcdc"
	}
    }
}

body Controller::rolloutof { a_stage } {
    # Undshades stage button (if not already current stage or disabled)
    if {$a_stage != $current_stage} {
	if {[$itk_component(stages) itemcget icon($a_stage) -image] != "::img::stage_${a_stage}_haze"} {
	    $itk_component(stages) itemconfigure box($a_stage) \
		-fill {} \
		-outline {}
	}
    }
}


# Methods to show various dialogs

body Controller::showIndexSettings { } {
    .ais show
}

body Controller::showIntegrationSettings { } {
    .is show
}

body Controller::showHistory { } {
    .hv show
}

body Controller::showExperimentSettings { } {
    .ass show
}

# Methods to enable levels of processing

body Controller::enableIndexing { } {
    enableStage "indexing"
}

body Controller::disableIndexing { } {
    disableStage "indexing"
}

body Controller::enableProcessing { } {
    enableStage strategy
    enableStage cell_refinement
    enableStage integration
}

body Controller::disableProcessing { } {
    disableStage strategy
    disableStage cell_refinement
    disableStage integration
}

########################################################################
# Session configuration                                                #
########################################################################

body Controller::addImages { } {
    # Create image-file selection dialog, if not yet created.
    
    if { [info exists ::env(IMAGEDIR)] && $::env(IMAGEDIR) != "" } {
	set initial_dir $::env(IMAGEDIR)
	unset ::env(IMAGEDIR)
    } else {
	set initial_dir [pwd]
    }

    if {![winfo exists .addImages]} {
	Fileopen .addImages \
	    -title "Add images" \
	    -type image_open \
	    -initialdir $initial_dir \
	    -filtertypes {{"Image files" {.img .mar* .mccd .osc .SFRM .sfrm .image .ipf .cbf}} {"ADSC" {.img}} {"Bruker" {.SFRM .sfrm}} {"Mar" {.mar* .mccd .image}} {"Oxford" {.img}} {"Rigaku" {.osc .img}} {"DIP" {.ipf}} {"imgCIF/CBF" {.cbf}} {"Numbered files" {*\.[0-9]+}} {"All Files" {.*}}}
    }
    # get a filename and location (as full path) from the user
    set l_image_file [.addImages get]
    #puts "addImages get: $l_image_file"
    # If the user picked one or more files
    if {$l_image_file != ""} {
	# add image(s) to the current session
	#puts "File dir  gives: [file dirname $l_image_file]"
	#puts "File tail gives: [file tail $l_image_file]"
	# can be a full path to a single file or be followed a list of image filenames
	set listofimages [file tail $l_image_file]
	# set first image to be head of the sorted list
	set first_image [file join [file dirname $l_image_file] [lindex $listofimages 0]]
	#puts "first_image $l_image_file"
	# check for >1 images in the list without 'Select images' box checked
	#puts "Number in list of files: [llength $listofimages]"
	#puts "First in list of images: $first_image"
	if {[llength $listofimages] > 1 } {
	    if { [.addImages getSingleImage] == 0 } {
		set listofimages $first_image
	    } else {
		# save list
		$::session writeImageList [ lrange $listofimages 1 end ]
	    }
	}
	# load the first one
	$::session addImage $first_image
    }
}

body Controller::addSpots { } {

    # Only permit if some images have been loaded
    if { [llength [$::session getImages]] < 1 } {
	.m confirm \
	    -type "1button" \
	    -title "No Images Found" \
	    -text "Please load some images before attempting to read a spots file." \
	    -button1of1 "Dismiss"
	return
    }

    # Use normal File open dialog
    set initial_dir [pwd]
    if {![winfo exists .addSpots]} {
	Fileopen .addSpots \
	    -title "Read spots file" \
	    -type open \
	    -initialdir $initial_dir \
	    -filtertypes {{"Spot files" {.spt}} {"All Files" {.*}}}
    }
    # get a filename and location (as full path) from the user
    set l_spots_file [.addSpots get]
    #puts "addSpots get: $l_spot_file"
    # If the user picked one or more files - not doing this yet ...
    if {$l_spots_file != ""} {
	## add spot file(s) to the current session
	#puts "File dir  gives: [file dirname $l_spots_file]"
	#puts "File tail gives: [file tail $l_spots_file]"
	## can be a full path to a single file or be followed by a list of file names
	#set listofspotfiles [file tail $l_spots_file]
	## set first spots file to be head of the sorted list
	set full_path [file join [file dirname $l_spots_file] [file tail $l_spots_file]]
	##puts "first_spots_file $l_spots_file"
	## check for >1 spots files in the list without 'Select spots files' box checked
	##puts "Number in list of files: [llength $listofspotfiles]"
	##puts "First in list of spots files: $first_spot_file"
	#if {[llength $listofspotfiles] > 1 } {
	#    if { [.addSpots getSingleImage] == 0 } {
	#	set listofimages $first_image
	#    } else {
	#	# save list
	#	$::session writeImageList [ lrange $listofspotfiles 1 end ]
	#    }
	#}

	# Move main window to the Indexing pane
	.c showStage indexing
	# File may contain spots from > 1 image so extract these
	[.c component indexing] processSpotsFile $full_path
    }
}

#body Controller::deleteImages { } {
#    set images_to_delete $selected_images
#    $::session deleteImages $images_to_delete
#    #$::session updateVisualSessionTrees - just does not exist
#    $::session addHistoryEvent "ImageDeleteEvent" "User action" $images_to_delete
#}

body Controller::saveSessionAs { } {
    # Create save session dialgo if necessary
    if {![winfo exists .saveSession]} {
	Fileopen .saveSession  \
	    -title "Save session as" \
	    -type save \
	    -initialdir [pwd] \
	    -filtertypes {{"Mosflm sessions" {.mos}} {"All Files" {.*}}}
    }
    # Get the user to pick a new filename and location (as full path)
    set l_session_file [.saveSession get]
    # If the user picked a file
    if {$l_session_file != ""} {
	# If the session has not previously been saved, get the name
	#  of the temporary file it's stored in 
	if {![$::session isSaved]} {
	    set l_temporary_file [$::session getFilename]
	} else {
	    set l_temporary_file ""
	}
	# Save the session as new file chosen by user
	if {[$::session writeToFile $l_session_file "1"]} {
	    # non-zero return value indicates error!
	    # return error code
	    return 2
	}
	# If there was a temporary file, delete it
	if {$l_temporary_file != ""} {
	    file delete $l_temporary_file
	}
	# Append file to recent session list and update the session menu
	$user_profile addRecentSession $l_session_file
	updateSessionMenu
	# success: return zero
	return 0
    } else {
	# return cancellation code  
	return 1
    }
}

body Controller::saveSession { } {
    # See if the session has already been saved in a named file
    if {[$::session isSaved]} {
	# Re-save it again in the same place
	set result [$::session writeToFile]
    } else {
	# Do a 'save as'
	set result [saveSessionAs]
    }
    return $result
}


body Controller::promptSaving { } {
    # If the session has been saved, or nothing has happened in it,
    #  report success
    if {[$::session isSaved] || (![$::session hasHistoryEvents])} {
	set result 0
    } else {
	# Ask user if they want to save the session
	set l_save_choice [.psd confirm -title "Save session" -text "Save session before closing?"]
	if {$l_save_choice == "Cancel"} {
	    # return cancellation code
	    set result 1
	} elseif {$l_save_choice == "Yes"} {
	    # Save the session
	    set result [saveSession]	    
	} elseif {$l_save_choice == "No"} {
	    set result 0
	} else {
	    error "Prompt save dialog returned invalid code: $l_save_choice"
	}
    }
    return $result
}

body Controller::openSession { { a_file "" } } {
    # if there is a session open, prompt saving
    if {$::session != ""} {
	set l_save_result [promptSaving]
    } else {
	set l_save_result 0
    }
    # if the user didn't cancel...
    if {$l_save_result == 0} {
	# if no file was provided, pick a file to open
	if {$a_file == ""} {
	    # If necessary create the "Open project" dialog
	    if {![winfo exists .openSession]} {
		Fileopen .openSession \
		    -title "Open session" \
		    -type open \
		    -initialdir [pwd] \
		    -filtertypes {{"Mosflm sessions" {.mos}} {"All Files" {.*}}}
	    }
	    # Get file name (as full path) from user
	    set l_session_file [.openSession get]
	    #puts "openSession get: $l_session_file"
	} else {
	    set l_session_file $a_file
	}
	# If the user picked a file
	if {$l_session_file != ""} {
	    # Close the session
	    closeSession
	    # Create a new session from the chosen file
	    set result [openSessionFile $l_session_file]
	} else {
	    # if the user didn't pick a session, report cancellation.
	    set result 1
	}
    } else {
	set result 1
    }
    return $result
}
    
body Controller::closeSession { } {    
    # Close the image display
    .image closeImage

    # clear the stage panels
    foreach i_stage { indexing strategy cell_refinement integration} {
	$itk_component($i_stage) clear
    }

    # clear the status_bar
    $itk_component(warnings) clear

    # Disable stages
    foreach i_stage { indexing strategy cell_refinement integration } {
	disableStage $i_stage
    }

    # Show images stage
    showStage hull

    # Delete the session object (session will delete own file if temporary)
    if {$::session != ""} {
	delete object $::session
    }

    # Wipe the session pointer
    set ::session ""

    # Disable the controls and canvases
    $itk_component(session_tree) configure -background "\#dcdcdc"

    return 0
}

body Controller::newSession { { a_image_file "" } } {
    # if there is a session open, prompt saving
    if {$::session != ""} {
	$::session updateSetting ccp4_bin [file normalize [$::session getParameterValue ccp4_bin]] 0 0 "Processing_options"
	set ::env(CBIN) [$::session getParameterValue ccp4_bin]

	set ::env(CCP4_BROWSER) [$::session getParameterValue web_browser]

	$::session updateSetting mosflm_exec [file normalize [$::session getParameterValue mosflm_exec]] 0 0 "Processing_options"
	set ::env(MOSFLM_EXEC) [$::session getParameterValue mosflm_exec]

	$::session updateSetting mosdir [file normalize [$::session getParameterValue mosdir]] 0 0 "Processing_options"
	set ::env(MOSDIR) [$::session getParameterValue mosdir]

	set ::env(MOSFLM_LOGGING) [$::session getParameterValue mosflm_logging]
	debug "Controller: Prompting saving of existing session"
	set l_save_result [promptSaving]
    } else {
	set l_save_result 0
    }
    # if the user didn't cancel, close the current session and make a new one
    if {$l_save_result == 0} {
	# close any current sessoin
	debug "Controller: Closing any existing session"
	closeSession
	# Create random temporary file for new session 
	# Create new seed for ranfom number generator based on the current clock state
	expr srand([clock clicks])
	# set flag to indicate file create is incomplete
	set file_creation_incomplete 1
	# initialize the counter for the number of attempts
	set file_creation_attempts 0
	# loop until a file has been created
	while {$file_creation_incomplete} {
	    # Check we haven't tried too many times already
	    if {$file_creation_attempts > 50} {
		# Inform the user of failure
		.m confirm \
		    -type "1button" \
		    -title "Error" \
		    -text "Could not create session file:\n$out_file" \
		    -button1of1 "Dismiss"
		# Stop trying as it has failed.
		return 0
	    }
	    # Create a new random filename pointing to in the hidden mosflm directory 
	    set l_randomfilename [file join $::mosflm_directory "temp[format %05u [expr int(rand()*99999)]].mpr"]
	    # try and create the file recording result (will fail if file exists)
	    set file_creation_incomplete [catch {open $l_randomfilename {WRONLY CREAT EXCL}} out_file]
	    # Keep tally of creation attempts
	    incr file_creation_attempts
	}
	# Close the file created
	close $out_file
	debug "Controller: Creating new session object"
 	# create a new session with that file
 	set ::session [namespace current]::[Session \#auto -name "New session"]
	debug "Controller: Writing session to hidden file"
	$::session writeToFile $l_randomfilename

	# open randomly named temporary strategy file
	openTempStrategyFile
	#puts "Temporary strategy file [getTempStrFilename]"
    
	# Colour the session tree background white
	$itk_component(session_tree) configure -background "white"
	# if there was an image file to be opened...
	if {$a_image_file != ""} {
	    # Create image object and query mosflm for header information
	    $::session addImage $a_image_file
	}
	# display the session
	debug "Controller: Displaying session"
	displaySession
	# Update all the dialogs
	debug "Controller: Updating interface"
	SettingWidget::refreshAll
	# set result to indicate success
	debug "Controller: Session successfully created"
	set result 0
    } else {
	debug "Controller: Session creation aborted"
	# set result to indicate result of saving existing session
	set result $l_save_result
    }
    return $result
}

body Controller::openSessionFile { a_file } {
    # Create a new session
    set ::session [namespace current]::[Session \#auto]
    # If successful, display the new session
    displaySession
    # Colour the canvases white
    $itk_component(session_tree) configure -background "white"
    # Try and initialize the new session with information from the file...
    if {[$::session initializeFromFile $a_file]} {
	# Refresh dialogs
	SettingWidget::refreshAll
	# Enable controls as appropriate
	if {[$::session getImages] != {}} {
	    enableIndexing
	}
	if {[$::session MatrixIsSet]} {
	    enableProcessing
	}
	# Update recent session files
	$user_profile addRecentSession $a_file
	updateSessionMenu
	return 0
    } else {
	# If unsuccessful, report failure.
	.m confirm \
	    -type "1button" \
	    -title "Failed to open session" \
	    -button1of1 "Dismiss" \
	    -text "Could not read session from file\n$a_file"
	return 1
    }
}

body Controller::openTempStrategyFile { } {

# Open randomly named temporary strategy file
    expr srand([clock clicks])
    set file_creation_incomplete 1
    set file_creation_attempts 0
    while {$file_creation_incomplete} {
	if {$file_creation_attempts > 50} {
	    .m confirm \
		-type "1button" \
		-title "Error" \
		-text "Could not create strategy file:\n$out_file" \
		-button1of1 "Dismiss"
	    return 0
	}
	set temp_strategy_file [file join $::mosflm_directory "msf[expr int(rand()*99999)].str"]
	set file_creation_incomplete [catch {open $temp_strategy_file {WRONLY CREAT EXCL}} out_file]
	incr file_creation_attempts
    }
# close file
    close $out_file
    return $temp_strategy_file
}

body Controller::existsTempStrFilename { } {
    return $haveTempStrategyfile
}

body Controller::wroteTempStrFile { } {
    set haveTempStrategyfile 1
}

body Controller::getTempStrFilename { } {
    return $temp_strategy_file
}

########################################################################
# Button callbacks                                                     #
########################################################################

body Controller::estimateMosaicity { } {
    # call session's estimate mosaicity method
    $::session estimateMosaicity
}


# Session tree methods ##################################################

body Controller::displaySession { } {

    # clear any existing session tree
    $itk_component(session_tree) item delete all
    
    # clear arrays mapping tree items
    array unset session_items_by_object *
    array unset session_obects_by_item *

    # create cell
    set l_item [$itk_component(session_tree) item create]
    $itk_component(session_tree) item style set $l_item 0 s1 1 s3 2 s2
    $itk_component(session_tree) item text $l_item 0 "Cell" 1 "[[$::session getCell] reportCell]" 2 "1"
    $itk_component(session_tree) item element configure $l_item 0 e_icon -image ::img::cell
    $itk_component(session_tree) item lastchild root $l_item
    set session_items_by_object([$::session getCell]) $l_item
    set session_objects_by_item($l_item) [$::session getCell]

    # create spacegroup
    set l_item [$itk_component(session_tree) item create]
    $itk_component(session_tree) item style set $l_item 0 s1 1 s3 2 s2
    $itk_component(session_tree) item text $l_item 0 "Spacegroup" 1 "[[$::session getSpacegroup] reportSpacegroup]" 2 "2"
    $itk_component(session_tree) item element configure $l_item 0 e_icon -image ::img::spacegroup
    $itk_component(session_tree) item lastchild root $l_item
    set session_items_by_object([$::session getSpacegroup]) $l_item
    set session_objects_by_item($l_item) [$::session getSpacegroup]

    # create mosaicity
    set l_item [$itk_component(session_tree) item create]
    $itk_component(session_tree) item style set $l_item 0 s1 1 s3 2 s2
    $itk_component(session_tree) item text $l_item 0 "Mosaicity" 1 "[$::session getMosaicity]" 2 "3"
    $itk_component(session_tree) item element configure $l_item 0 e_icon -image ::img::mosaicity
    $itk_component(session_tree) item lastchild root $l_item
    set session_items_by_object(mosaicity) $l_item
    set session_objects_by_item($l_item) [namespace current]::[SessionParameter \#auto "mosaicity"]

    # create mosaic block size
    set l_item [$itk_component(session_tree) item create]
    $itk_component(session_tree) item style set $l_item 0 s1 1 s3 2 s2
    $itk_component(session_tree) item text $l_item 0 "Mosaic block size" 1 "100" 2 "3"
    $itk_component(session_tree) item element configure $l_item 0 e_icon -image ::img::mosaicblock
    $itk_component(session_tree) item lastchild root $l_item
    set session_items_by_object(mosaicblock) $l_item
    set session_objects_by_item($l_item) [namespace current]::[SessionParameter \#auto "mosaicblock"]

    # Add sectors
    foreach i_sector [$::session getSectors] {
	addSector $i_sector
	foreach i_image [$i_sector getImages] {
	    addImage $i_sector $i_image
	}
    }
}

body Controller::addSector { a_sector } {
    # Create sector item
    #puts "addSector $a_sector"
    set l_sector_item [$itk_component(session_tree) item create -button 1]
    $itk_component(session_tree) item style set $l_sector_item 0 s1 1 s2 2 s2
    foreach { l_phi_start l_phi_end } [$a_sector getPhi] break
    $itk_component(session_tree) item text $l_sector_item 0 "Sector [$a_sector getTemplate]" 1 "\u03c6:$l_phi_start->$l_phi_end" 2 "[$a_sector getTemplate]"
    $itk_component(session_tree) item element configure $l_sector_item 0 e_icon -image ::img::dataset
    $itk_component(session_tree) item lastchild root $l_sector_item
    set session_items_by_object($a_sector) $l_sector_item
    set session_objects_by_item($l_sector_item) $a_sector

    # Create matrix item
    set l_matrix_item [$itk_component(session_tree) item create]
    $itk_component(session_tree) item style set $l_matrix_item 0 s1 1 s2 2 s2
    $itk_component(session_tree) item text $l_matrix_item 0 "Matrix" 1 "[[$a_sector getMatrix] getName]" 2 "0"
    $itk_component(session_tree) item element configure $l_matrix_item 0 e_icon -image ::img::orientation
    $itk_component(session_tree) item lastchild $l_sector_item $l_matrix_item
    set session_items_by_object([$a_sector getMatrix]) $l_matrix_item
    set session_objects_by_item($l_matrix_item) [$a_sector getMatrix]

    # update other user interface components
    [$itk_component(indexing) component image_numbers] addSector $a_sector
    [$itk_component(cell_refinement) component image_numbers] addSector $a_sector
    [$itk_component(integration) component image_numbers] addSector $a_sector
}

body Controller::addImage { a_sector a_image args } {
    options {-sort 1} $args
    # adds image to treectrl
    # create image item
    set l_image_item [$itk_component(session_tree) item create]
    $itk_component(session_tree) item style set $l_image_item 0 s1 1 s3 2 s2
    foreach { l_phi_start l_phi_end } [$a_image getPhi] break
    $itk_component(session_tree) item text $l_image_item 0 "Image [$a_image getNumber]" 1 "[$a_image reportPhis]" 2 "[$a_image getNumber]"
    # add image item to sector item
    $itk_component(session_tree) item lastchild $session_items_by_object($a_sector) $l_image_item
    if {$options(-sort)} {
	# sort sector item's image items
	$itk_component(session_tree) item sort $session_items_by_object($a_sector) -column order_column -dictionary
	# update the sector (phi range)
	updateSector [$a_image getSector]
    }
    # keep record of which item belongs to which image object
    set session_items_by_object($a_image) $l_image_item
    set session_objects_by_item($l_image_item) $a_image
    #puts "Item $session_items_by_object($a_image) is $session_objects_by_item($l_image_item)"
    
    if {[$a_image getNumber] == "0"} {
	$itk_component(session_tree) item element configure $l_image_item 0 e_icon -image ::img::status_warning_on16x16
	$::session generateWarning "You have added an image file with an index of zero. The batch number offset has been automatically set to a value of 1000" -reason "Images"
	$::session updateSetting "batch_number" 1000 "1" "1" "Images"
    } else {
	$itk_component(session_tree) item element configure $l_image_item 0 e_icon -image ::img::image
	# Update status message - good for thousands of images!
	$itk_component(status_message) configure -text "Added image [$a_image getNumber]"
	#puts "Image [$a_image getNumber] phi start: $l_phi_start - phi end: $l_phi_end"		    
    }
}

body Controller::updateCell { a_cell } {
    # update treectrl's cell item
    $itk_component(session_tree) item text $session_items_by_object($a_cell) 1 "[$a_cell reportCell]"
}
    
body Controller::updateSpacegroup { a_spacegroup } {
    # update treectrl's spacegroup item
    $itk_component(session_tree) item text $session_items_by_object($a_spacegroup) 1 "[$a_spacegroup reportSpacegroup]"
}
    
body Controller::updateMosaicity { a_mosaicity } {
    #update treectrl's mosaicity item
    $itk_component(session_tree) item text $session_items_by_object(mosaicity) 1 "$a_mosaicity"
}

body Controller::updateMosaicblock { a_mosaicblock} {
    #update treectrl's mosaicblock item
    $itk_component(session_tree) item text $session_items_by_object(mosaicblock) 1 "$a_mosaicblock"
}
    
body Controller::updateImage { a_image } {
    # update image's phi values
    $itk_component(session_tree) item text $session_items_by_object($a_image) 1 "[$a_image reportPhis]"
    updateSector [$a_image getSector]
}

body Controller::updateSector { a_sector } {
    #update treectrl's sector item's phi range
    foreach { l_phi_start l_phi_end } [$a_sector getPhi] break
    $itk_component(session_tree) item text  $session_items_by_object($a_sector) 1 "\u03c6:$l_phi_start->$l_phi_end"
}

body Controller::updateMatrix { a_sector a_matrix } {
    # update treectrl's matrix name
    $itk_component(session_tree) item text $session_items_by_object($a_matrix) 1 [$a_matrix getName]
}   

body Controller::singleClickSession { w x y} {
    # callback for single click on session treectrl
    set lukesingle $w
    set lukesingle2 [$w identify $x $y]
    set id $lukesingle2
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "header"} {
    } else {
	foreach {what item where arg1 arg2 arg3} $id {}
	#puts "id: $id"
	# get the object belonging to the item double clicked on
	set l_object $session_objects_by_item($item)
	# if anything but a Sector line
	if {[$l_object isa Sector]} {
	    if {$where != "button"} {
		# Avoid misleading message when clicking on the [+] or [-] expand & collapse buttons
		updateStatusMessage "Right-click to delete sector"
	    }
	} elseif {[$l_object isa Image]} {
	    updateStatusMessage "Right-click to delete image or click again on values to edit"
	} elseif {[$l_object isa Matrix]} {
	    updateStatusMessage "Double-click for Matrix properties menu"
	} else {
	    updateStatusMessage "Click again on highlighted values to edit"
	}
    }
}

body Controller::rightClickSession { } {
    # callback for single click on session treectrl
    set id $lukesingle2
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "header"} {
    } else {
	foreach {what item where arg1 arg2 arg3} $id {}
	# get the object belonging to the item double clicked on
	set l_object $session_objects_by_item($item)
	# if anything but a Sector line
	#puts "l_object: $l_object where: $where" 
	if {[$l_object isa Sector]} {
	    if {$where == "column"} {
		$itk_component(session_tree) item remove $item	
		foreach i_sector [$::session getSectors] {
		    #puts $i_sector
		    if {$i_sector == $l_object} {
			#puts "found a match and will delete $i_sector from session and stages"
			foreach i_imagename [$itk_component(indexing) getIncludedImages] {
			    #puts $i_imagename	
			    foreach l_imagename [$i_sector getImages] {
				if {$i_imagename == $l_imagename} {
				    $itk_component(indexing) removeImage $i_imagename
				}
			    }
			}
			[$itk_component(indexing) component image_numbers] deleteSector $i_sector
			[$itk_component(cell_refinement) component image_numbers] deleteSector $i_sector
			[$itk_component(integration) component image_numbers] deleteSector $i_sector
			
		        foreach l_imagename [$i_sector getImages] {
			    $::session addHistoryEvent "ImageDeleteEvent" "User action" $l_imagename
			}
			$::session deleteSector $i_sector
			#puts "Sector item was $session_items_by_object($i_sector)"
			array unset session_items_by_object $i_sector
			array unset session_objects_by_item $item
		    }
		}
	    }
	} elseif {[$l_object isa Image]} {
	    if {$where == "column"} {
		$itk_component(session_tree) item remove $item	
		foreach i_sector [$::session getSectors] {
		    foreach i_image [$i_sector getImages] {
			if {$i_image == $l_object} {
			    #puts "Image item was $session_items_by_object($i_image)"
			    #puts "found image $i_image in sector $i_sector matches object $l_object"
			    foreach i_imagename [$itk_component(indexing) getIncludedImages] {
				#puts $i_imagename	
				if {$i_image == $i_imagename} {
				    #puts "attempt removal of $i_imagename from indexing component"
				    $itk_component(indexing) removeImage $i_imagename
				}
			    }
			    set status [$i_sector deleteImage $i_image]
			    if { $status == "-1" } {
				# Deleted last image in this sector
				$::session deleteSector $i_sector
				set sector_item $session_items_by_object($i_sector)
				$itk_component(session_tree) item remove $sector_item
				# unset array pointers - image and sector
				array unset session_items_by_object $i_image
				array unset session_objects_by_item $item
				array unset session_items_by_object $i_sector
				array unset session_objects_by_item $sector_item
			    } elseif { $status == "1" } {
				# unset array pointers - just the image
				array unset session_items_by_object $i_image
				array unset session_objects_by_item $item
			    } else {
				# 0 means nothing deleted
			    }
			}
		    }
		}
	    }
	} else {
	    #
	}
	.image updateImageList
	
	if {[llength [$::session getSectors]] > 0} {
	    .image openImage [lindex [[lindex [$::session getSectors] 0] getImages] 0]
	} else {
	    .image closeImage
	    disableIndexing
	    disableProcessing
	}
    }
}

################################################################################

body Controller::doubleClickSession { w x y } {
    # callback for double click on session treectrl
    set id [$w identify $x $y]
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "header"} {
    } else {
	foreach {what item where arg1 arg2 arg3} $id {}
	# get the object belonging to the item double clicked on
	set l_object $session_objects_by_item($item)
	# if it's an image
	if {[$l_object isa Image]} {
	    .image openImage $l_object
	} elseif {[$l_object isa Matrix]} {
	    # if it's a matrix, get parent sector 
	    set l_sector $session_objects_by_item([$w item parent $item])
	    # and edit sector's matrix
	    editMatrixProperties $l_sector $l_object 
	}
    }
}

body Controller::editTree { an_item a_column an_element a_text} {
    # Updated the item's text
    set l_object $session_objects_by_item($an_item)
    #puts "$an_item $a_column $an_element $a_text"
    #puts $l_object
    # check user input according to item class
    if {[$l_object isa Cell]} {
	if {[regexp {^[^\d\.]*(\d+\.?\d*|\.\d+)[^\d\.]*(\d+\.?\d*|\.\d+)[^\d\.]*(\d+\.?\d*|\.\d+)[^\d\.]*(\d+\.?\d*|\.\d+)[^\d\.]*(\d+\.?\d*|\.\d+)[^\d\.]*(\d+\.?\d*|\.\d+)[^\d\.]*$} $a_text match l_a l_b l_c l_alpha l_beta l_gamma]} {
	    foreach i_x { l_a l_b l_c l_alpha l_beta l_gamma } {
		set $i_x [format %.2f [set $i_x]]
	    }
	    set t_cell [namespace current]::[Cell \#auto "initialize" "temp" $l_a $l_b $l_c $l_alpha $l_beta $l_gamma]
	    delete object $t_cell
	    $::session validateCellAndSpacegroup $l_a $l_b $l_c $l_alpha $l_beta $l_gamma [$::session reportSpacegroup]
	} else {
	    # ignore input
	}
    } elseif {[$l_object isa Spacegroup]} {
        regsub -all " " $a_text "" b_text
	if { [string length $b_text] == 0 } { return }
	set l_text [string toupper $b_text]
	if { [string index $l_text 0] == "H" } {
	    set l_text [string tolower $l_text]
	}
	# Search in iMosflm's list
	set nfound [lsearch $::spacegroups $l_text]
	#if { $nfound > -1} {
	#    puts "Spacegroup text found in iMosflm: $nfound"
	#} else {
	#    puts "Spacegroup text  NOT  in iMosflm"
	#}
	foreach { l_a l_b l_c l_alpha l_beta l_gamma } [[$::session getCell] listCell] break
	$::session validateCellAndSpacegroup $l_a $l_b $l_c $l_alpha $l_beta $l_gamma $l_text
    } elseif {[$l_object isa Image]} {
	#puts "Input: $a_text"
	set l_phi {}
	set l_phi [regexp -inline -all -- {[-+]?\d*\.?\d+} $a_text]
	#puts "Phi's: $l_phi"
	if { [llength $l_phi] == 2 } {
	    [$l_object getSector] propagatePhi $l_object [lindex $l_phi 0] [lindex $l_phi 1]
	} elseif { [llength $l_phi] == 5 } {
	    $l_object setPhi [lindex $l_phi 0] [lindex $l_phi 1] 1 1 "User"
	    $l_object updateMissets [lindex $l_phi 2] [lindex $l_phi 3] [lindex $l_phi 4] 1 1 "User"
	} else {
	}	    
    } elseif {[$l_object isa SessionParameter]} {
	# Must be mosaicity
	if {[$l_object getName] eq "mosaicity"} {
	if {[string is double $a_text]} {
	    $::session updateSetting "mosaicity" $a_text
	}
	} else {
	    if {[string is double $a_text]} {
	        $::session updateSetting "mosaicblock" $a_text
	    }
        }
    }
}

body Controller::getObjectByItem { an_item } {
    return $session_objects_by_item($an_item)
}

body Controller::editMatrixProperties { a_sector a_matrix } {
    # Create matrix properties dialog if necessary
    if {![winfo exists .matrixProperties]} {
	MatrixDialog .matrixProperties -title "Matrix properties"
    }
    # load in the matrix to be edited
    .matrixProperties load $a_matrix
    # Get a matrix from the user
    set l_new_matrix [.matrixProperties get]
    # if the user provided a 'new' matrix
    if {$l_new_matrix != ""} {
	# get the 'old' matrix
	set l_old_matrix [$a_sector getMatrix]
	# if the new matrix is really different from the old one..
	if {![$l_old_matrix equals $l_new_matrix]} {
	    # update the sector's matrix
	    $a_sector updateMatrix "User" $l_new_matrix
	}
    }
}

body Controller::uncheckAutothreshCheckbutton {} {
    $::session updateSetting "auto_thresh_indexing" "0" 0 1 "User" 0
}

# About dialog ################################

class About {
    inherit Amodaldialog 

    constructor { args } { }
}

body About::constructor { args } {
    
    itk_component add frame {
	frame $itk_interior.f \
	    -bd 2
    }

    itk_component add icon {
	label $itk_interior.f.icon \
	    -image ::img::activity_idle16x16
    }

    itk_component add version {
	label $itk_interior.f.version \
	    -text "$::env(IMOSFLM_VERSION)" \
	    -font "helvetica -14 bold"
    } {
	usual
	ignore -font
    }

    itk_component add credits {
	label $itk_interior.f.credits \
	    -text "New GUI developed by Geoff Battye and Luke Kontogiannis"
    }
    
    itk_component add button {
	button $itk_interior.button \
	    -text "Close" \
	    -relief raised \
	    -command [code $this hide]
    }

    pack $itk_component(frame) -fill both -expand 1
    pack $itk_component(button) -pady 5

    pack $itk_component(version) -side top -padx {20 20} -pady 20
    pack $itk_component(credits) -side bottom -pady {10 20}
    
    eval itk_initialize $args
}
