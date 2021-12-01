# $Id: combobox.tcl,v 1.8 2012/05/21 13:23:38 ccb Exp $
# This is a (slightly) improved version of Jeff's vanilla Tk combobox
# (less problems with binding clashes, uses a bitmap on the button, a
# few other features...) but the real effort is his, so I:
#    a) include his original news posting (with as much in the way of
#       headers as my newsreader presents on verbose :^). This also
#       acts as documentation...
#    b) acknowledge that he is the prior author
#
# If you want to use this code commercially, you'll probably need to
# obtain permission from both of us (I imagine that I'd agree without
# any problems, but I can't speak for Jeffrey).
#
# Enjoy!
#
# Donal.  ( mailto:fellowsd@cs.man.ac.uk  -  http://r8h.cs.man.ac.uk:8000/ )

#comp.lang.tcl #32821 (0 + 394 more)
#Path: cs.man.ac.uk!yama.mcc.ac.uk!zippy.dct.ac.uk!btnet!tank.news.pipex.net!
#+     pipex!news.mathworks.com!newsfeed.internetmci.com!chi-news.cic.net!news.
#+     uoregon.edu!cs.uoregon.edu!cs.uoregon.edu!news
#Newsgroups: comp.lang.tcl
#Subject: CODE: Vanilla Tk4 ComboBox
#Message-ID: <46lr31$30t@psychotix.cs.uoregon.edu>
#From: jhobbs@cs.uoregon.edu (Jeffrey Hobbs)
#Date: 25 Oct 1995 10:10:57 -0700
#Organization: University of Oregon Computer and Information Sciences Dept.
#NNTP-Posting-Host: psychotix.cs.uoregon.edu
#Lines: 101
#
#Several people were asking about alternatives to the combobox if they
#didn't have Tix or something.  Since they are so useful, and relatively
#easy to make, I coded some *example* code for a vanilla Tk combobox.
#For the uninitiated, a combobox is just an entry box linked to a popup
#listbox that hold history and such.
#
#This is not a good replacement for Tix's tixComboBox or the incrTk2
#combobox, but is useful starting point for those extensionless users.
#It's mostly an example of an overrideredirected toplevel.
#
#Some notes: double-1 or <Escape> in the entry widget, or selecting the
#button will toggle the listbox portion.  <Escape> will close the listbox
#without a selection.  <Return> in the entry widget adds items (no
#duplicates) to the listbox.  <Tab> in the entry widget searches the listbox
#for a unique match.  <Double-1> in the listbox selects that item.  The
#listbox scrollbar appears when more than 5 items are in the listbox when it
#pops up.  Any args beyond the window name go directly to the entry widget.
#
#Example use:
#pack [combobox .combo]
#pack [combobox .combo -width 20 -textvariable myvar]
#
### BEGIN COMBOBOX CODE ----------8<----------8<-----------8<-----------

set comboboxbuttonimage [image create bitmap -data {#define downbut_width 14
#define downbut_height 14
static char downbut_bits[] = {
   0x00, 0x00, 0xe0, 0x01, 0xe0, 0x01, 0xe0, 0x01, 0xe0, 0x01, 0xfc, 0x0f,
   0xf8, 0x07, 0xf0, 0x03, 0xe0, 0x01, 0xc0, 0x00, 0x00, 0x00, 0xfe, 0x1f,
   0xfe, 0x1f, 0x00, 0x00};
}]

bind ComboEntry <Double-1> {combobox_popup [winfo parent %W]}
bind ComboEntry <Escape>   {combobox_popup [winfo parent %W]}
bind ComboEntry <Tab>      {combobox_find  %W; break}
bind ComboEntry <Return>   {combobox_add   %W}

bind ComboList  <Escape>   {combobox_popup [winfo parent [winfo parent %W]]}
bind ComboList  <Double-1> {combobox_get   %W %y}

proc combobox {w args} {
    global comboboxbuttonimage
    if [winfo exists $w] { error "window $w already exists" }

    frame $w -class ComboBox

    ## Entry Widget, it gets all the args
    eval entry $w.e $args
    pack $w.e -side left -fill x -expand 1

    ## Button.  With the symbol font, it should be a down arrow
    button $w.b -image $comboboxbuttonimage \
	    -command [list combobox_popup $w]
    pack $w.b -side right -fill y

    ## Removable List Box
    toplevel $w.btm -cursor arrow
    wm withdraw $w.btm
    wm overrideredirect $w.btm 1
    wm transient $w.btm [winfo toplevel $w]
  
    listbox $w.btm.lbox -bd 2 -relief sunken -width 5 -height 5 \
	    -yscrollcommand [list $w.btm.vs set] -selectmode single
    scrollbar $w.btm.vs -orient vertical -command [list $w.btm.lbox yview]
    pack $w.btm.lbox -side left -fill both -expand 1

    bindtags $w.e [linsert [bindtags $w.e] 1 ComboEntry]
    bindtags $w.btm.lbox [linsert [bindtags $w.btm.lbox] 1 ComboList]

    return $w
}

proc combobox_setlist {w args} {
    if {[winfo class $w] != "ComboBox"} {
	return -code error "$w not a ComboBox"
    }
    if [winfo ismapped $w.btm] {
	wm withdraw $w.btm
	$w.b configure -relief raised
    }
    $w.btm.lbox delete 0 end
    eval $w.btm.lbox insert end $args
}

proc combobox_getlist w {
    if {[winfo class $w] != "ComboBox"} {
	return -code error "$w not a ComboBox"
    }
    return [$w.btm.lbox get 0 end]
}    

proc combobox_popup w {
    if {[winfo class $w] != "ComboBox"} {
	return -code error "$w not a ComboBox"
    }
    if [winfo ismapped $w.btm] {
	wm withdraw $w.btm
	$w.b configure -relief raised
    } else {
	wm geometry $w.btm [winfo width $w.e]x[winfo reqheight $w.btm]+[winfo rootx $w]+[expr [winfo rooty $w]+[winfo reqheight $w]]
	if {[$w.btm.lbox size] > 5} {
	    pack $w.btm.vs -side right -fill y
	} elseif {[winfo manager $w.btm.vs] == "pack"} {
	    pack forget $w.btm.vs
	}
	wm deiconify $w.btm
	raise $w.btm
	$w.b configure -relief sunken
    }
}

proc combobox_find W {
    set found 0
    set tmp [$W get]
    set lbox [winfo parent $W].btm.lbox
    foreach item [$lbox get 0 end] {
	if ![string first $tmp $item] {
	    incr found
	    set match $item
	}
    }
    switch $found {
	0 {}
	1 {
	    $W delete 0 end
	    $W insert end $match
	}
	default {
	    bell
	}
    }
}
proc combobox_add W {
    set i 1
    set tmp [$W get]
    foreach item [[winfo parent $W].btm.lbox get 0 end] {
	if ![string compare $item $tmp] {
	    set i 0
	    break
	}
    }
    if $i {
	[winfo parent $W].btm.lbox insert end $tmp
    }
    wm withdraw [winfo parent $W].btm
}

proc combobox_get {W y} {
    set e [winfo parent [winfo parent $W]].e
    if [$W size] {
	$e delete 0 end
	$e insert end [$W get [$W nearest $y]]
    }
    wm withdraw [winfo parent $W]
    [winfo parent $e].b configure -relief raised
}

#### END COMBOBOX CODE ------8<------------8<---------8<-------------
#-- 
#     Jeffrey Hobbs                           Office: 503/346-3998
#     Univ of Oregon CIS GTF                  email: jhobbs@cs.uoregon.edu
#                URL: http://www.cs.uoregon.edu/~jhobbs/
