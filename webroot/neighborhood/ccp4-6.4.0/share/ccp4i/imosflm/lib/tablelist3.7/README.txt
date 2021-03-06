               The Multi-Column Listbox Package Tablelist

                                   by

                             Csaba Nemethi

                       csaba.nemethi@t-online.de 


What is Tablelist?
------------------

Tablelist is a library package for Tcl/Tk version 8.0 or higher,
written in pure Tcl/Tk code.  It contains:

  - the implementation of the "tablelist" mega-widget, including a
    general utility module for mega-widgets;
  - a demo script containing a useful procedure that displays the
    configuration options of an arbitrary widget in a tablelist and
    enables you to edit their values interactively;
  - a second demo script, implementing a simple widget browser based on
    a tablelist;
  - a third demo script, showing several ways to improve the appearance
    of a tablelist widget;
  - three further demo scripts, illustrating the interactive cell
    editing with the aid of various widgets from the Tk core and from
    the packages BWidget, Iwidgets, combobox (by Bryan Oakley), and
    Mentry;
  - one further demo script, with a tablelist widget containing
    embedded windows;
  - a tutorial in HTML format;
  - reference pages in HTML format.

A tablelist widget is a multi-column listbox.  The width of each column
can be dynamic (i.e., just large enough to hold all its elements,
including the header) or static (specified in characters or pixels).
The columns are, per default, resizable.  The alignment of each column
can be specified as "left", "right", or "center".

The columns, rows, and cells can be configured individually.  Several
of the global and column-specific options refer to the headers,
implemented as label widgets.  For instance, the "-labelcommand" option
specifies a Tcl command to be invoked when mouse button 1 is released
over a label.  The most common value of this option is
"tablelist::sortByColumn", which sorts the items based on the
respective column.

Interactive editing of the elements of a tablelist widget can be
enabled for individual cells and for entire columns.  A great variety
of widgets from the Tk core and from the packages BWidget, Iwidgets,
combobox, and Mentry is supported for being used as embedded edit
window.  In addition, a rich set of keyboard bindings is provided for a
comfortable navigation between the editable cells.

The Tcl command corresponding to a tablelist widget is very similar to
the one associated with a normal listbox.  There are column-, row-, and
cell-specific counterparts of the "configure" and "cget" subcommands
("columnconfigure", "rowconfigure", "cellconfigure", ...).  They can be
used, among others, to insert images into the cells and the header
labels, or to insert embedded windows into the cells.  The "index",
"nearest", and "see" command options refer to the rows, but similar
subcommands are provided for the columns and cells ("columnindex",
"cellindex", ...).  The items can be sorted with the "sort" and
"sortbycolumn" command options.

The bindings defined for the body of a tablelist widget make it behave
just like a normal listbox.  This includes the support for the virtual
event <<ListboxSelect>> (which is equivalent to <<TablelistSelect>>).
In addition, version 2.3 or higher of the widget callback package Wcb
(written in pure Tcl/Tk code as well) can be used to define callbacks
for the "activate", "selection set", and "selection clear" commands,
and Wcb version 3.0 or higher also supports callbacks for the
"activatecell", "cellselection set", and "cellselection clear"
commands.  The download location of Wcb is

    http://www.nemethi.de

How to get it?
--------------

Tablelist is available for free download from the same URL as Wcb.  The
distribution file is "tablelist3.7.tar.gz" for UNIX and
"tablelist3_7.zip" for Windows.  These files contain the same
information, except for the additional carriage return character
preceding the linefeed at the end of each line in the text files for
Windows.

How to install it?
------------------

Install the package as a subdirectory of one of the directories given
by the "auto_path" variable.  For example, you can install it as a
directory at the same level as the Tcl and Tk script libraries.  The
locations of these library directories are given by the "tcl_library"
and "tk_library" variables, respectively.

To install Tablelist on UNIX, "cd" to the desired directory and unpack
the distribution file "tablelist3.7.tar.gz":

    gunzip -c tablelist3.7.tar.gz | tar -xf -

This command will create a directory named "tablelist3.7", with the
subdirectories "demos", "doc", "images", and "scripts".

On Windows, use WinZip or some other program capable of unpacking the
distribution file "tablelist3_7.zip" into the directory "tablelist3.7",
with the subdirectories "demos", "doc", "images", and "scripts".

Note that the directory "images" and the file "tablelistEdit.tcl" in
the "scripts" directory are only needed for applications making use of
interactive cell editing.  Similarly, the file "tablelistMove.tcl" in
the same directory is only needed for applications invoking the "move"
or "movecolumn" tablelist command.

Next, you should check the exact version number of your Tcl/Tk
distribution, given by the "tcl_patchLevel" and "tk_patchLevel"
variables.  If you are using Tcl/Tk version 8.2.X, 8.3.0 - 8.3.2, or
8.4a1, then you should proceed as described in the "How to install it?"
section of the file "tablelist.html", located in the "doc" directory.

How to use it?
--------------

To be able to use the commands and variables implemented in the package
Tablelist, your scripts must contain one of the lines

    package require Tablelist
    package require tablelist

Since the package Tablelist is implemented in its own namespace called
"tablelist", you must either import the procedures you need, or use
qualified names like "tablelist::tablelist".

For a detailed description of the commands and variables provided by
Tablelist and of the examples contained in the "demos" directory, see
the tutorial "tablelist.html" and the reference pages, all located in
the "doc" directory.
