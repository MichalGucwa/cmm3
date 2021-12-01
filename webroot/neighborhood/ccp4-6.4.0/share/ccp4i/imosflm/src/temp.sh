#!/bin/sh

# N.B. If you want to setup a site-wide installation, you'll probably want to
#  edit and uncomment the following lines to point to the site-wide wish8.4
#  and Mosflm 6.2.6 executables

#export MOSFLM_WISH=/path/to/your/wish8.4
#export MOSFLM_EXEC=/path/to/your/ipmosflm

case $0 in
  /*) abspath=$0 ;;
  *) abspath=$PWD/$0 ;;
esac

# function to test wish executable
test_wish()
{
WISH_FAIL=0
$1<<EOF
exit [catch {package require Itcl 3.3}]
EOF
ITCL_FAIL=$?
if [ $ITCL_FAIL -eq 1 ]
then WISH_FAIL=1
fi
$1<<EOF
exit [catch {package require Itk 3.3}]
EOF
ITK_FAIL=$?
if [ $ITK_FAIL -eq 1 ]
then WISH_FAIL=1
fi
$1<<EOF
exit [catch {package require Iwidgets 4.0}]
EOF
IWIDGETS_FAIL=$?
if [ $IWIDGETS_FAIL -eq 1 ]
then WISH_FAIL=1
fi
$1<<EOF
exit [catch {package require Img 1.3}]
EOF
IMG_FAIL=$?
if [ $IMG_FAIL -eq 1 ]
then WISH_FAIL=1
fi
$1<<EOF
exit [catch {package require tdom 0.8}]
EOF
TDOM_FAIL=$?
if [ $TDOM_FAIL -eq 1 ]
then WISH_FAIL=1
fi
$1<<EOF
exit [catch {package require treectrl 2.3}]
EOF
TREECTRL_FAIL=$?	
if [ $TREECTRL_FAIL -eq 1 ]
then WISH_FAIL=1
fi
return $WISH_FAIL
}

# method to report on wish shortcomings
diagnoze_failure()
{
    if [ $ITCL_FAIL -eq 1 ]
    then echo "Itcl 3.3"
    fi
    if [ $ITK_FAIL -eq 1 ]
    then echo "Itk 3.3"
    fi
    if [ $IWIDGETS_FAIL -eq 1 ]
    then echo "Iwidgets 4.0"
    fi
    if [ $IMG_FAIL -eq 1 ]
    then echo "Img 1.3"
    fi
    if [ $TDOM_FAIL -eq 1 ]
    then echo "tdom 0.8"
    fi
    if [ $TREECTRL_FAIL -eq 1 ]
    then echo "treectrl 2.1"
    fi
}

# Get wish executale pointed to by MOSFLM_WISH environment variable
FOUND_WISH=0
if [ "$MOSFLM_WISH" != "" ]
then
    # Check it's a valid executable
    type $MOSFLM_WISH &> /dev/null
    if [ $? == 0 ]
    then
	# Test that it has all require packages
	test_wish $MOSFLM_WISH
	if [ $WISH_FAIL -eq 1 ]
	then
	    echo ""
	    echo "Cannot use wish8.4 executable pointed to by"
	    echo "MOSFLM_WISH environment variable."
	    echo "Your tcl/tk installation ($MOSFLM_WISH) is"
	    echo "missing the following required tcl/tk packages:"
	    diagnoze_failure
	    echo "To use a different tcl/tk installation set the"
	    echo "environment variable \"MOSFLM_WISH\" to the"
	    echo "full pathname of your prefered wish8.4 executable"
	    echo ""
	else
	    FOUND_WISH=1
	    exec $MOSFLM_WISH ${abspath}.tcl
	fi
    else
	echo ""
	echo "Environment variable MOSFLM_WISH does not point to"
	echo "a valid wish8.4 executable!"
	echo ""
    fi
fi
if [ $FOUND_WISH != 1 ]
then
    # Test wish8.4 in path
    type wish8.4 &> /dev/null
    if [ $? == 0 ]
    then
	# Test found wish8.4
	DEFAULT_WISH=`which wish8.4`
	echo "Testing default wish8.4 executable ($DEFAULT_WISH)."
	test_wish $DEFAULT_WISH
	if [ $WISH_FAIL -eq 1 ]
	then
	    echo "The default wish8.4 installation is missing the"
	    echo "following required tcl/tk packages:"
	    diagnoze_failure
	    echo ""
	else
	    echo "Running imosflm with default wish8.4 executable ($DEFAULT_WISH)."
	    FOUND_WISH=1
	    exec $DEFAULT_WISH ${abspath}.tcl
	fi
    fi
fi
if [ $FOUND_WISH != 1 ]
then
    echo "Please enter the path of a wish8.4 executable from"
    echo "the tcl/tk installation you wish to use:"
    echo "(Or just hit <Return> to exit):"
    read MY_WISH
    if [ "$MY_WISH" != "" ]
    then
	type $MY_WISH &> /dev/null
	if [ $? == 0 ]
	then
	    test_wish $MY_WISH
	    if [ $WISH_FAIL -eq 1 ]
	    then
		echo "Your wish8.4 executable ($MY_WISH) is missing"
		echo "the following required packages:"
		diagnoze_failure
		echo ""
	    else
		FOUND_WISH=1
		exec $MY_WISH ${abspath}.tcl
	    fi
	else
	    echo "Could not run $MY_WISH"
	    echo "Please check file permissions and try again."
	    echo ""
	    exit
	fi
    fi
fi
if [ $FOUND_WISH -ne 1 ]
then
    echo "No wish8.4 executable with all required packages was found."
    echo "You can download a \"batteries included\" tcl/tk distribution"
    echo "which includes wish8.4 executable and all require packages from:"
    echo "www.activestate.com"
    echo ""
fi
