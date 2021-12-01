#! /bin/bash
source ~/.bashrc
export NEIGHBORHOOD_DEBUG=0
NEIGH_ROOT="/home/dust/neighborhood_current"
NEIGH_SCRIPT_DIR="/home/dust/neighborhood_current"
NEIGH_LOG_DIR="$NEIGH_ROOT/logs"
NEIGH_LOG_FILE="$NEIGH_LOG_DIR/log`date +%F`.txt"
PERL_COMMAND="`which perl`"

#checks all the directory are set up properly

if test -d $NEIGH_ROOT; then
  echo "$NEIGH_ROOT exists" >/dev/null
else
  echo "ERROR! $MPDB_ROOT does NOT exists"
  exit 1
fi

if test -d $NEIGH_LOG_DIR; then
  echo "$NEIGH_LOG_DIR exists" > /dev/null
else
  echo "ERROR! $MPDB_LOG_DIR does NOT exists"
  exit 1
fi

if ! [ -f $NEIGH_LOG_FILE ]; then
  touch $NEIGH_LOG_FILE
fi

echo "neighborhood update started on `date +%D\ %r`" >> $NEIGH_LOG_FILE 2>&1
cd  $NEIGH_SCRIPT_DIR

echo "running $NEIGH_SCRIPT_DIR/neighborhood_update.pl ..."
echo "running $NEIGH_SCRIPT_DIR/neighborhood_update.pl ..." >> $NEIGH_LOG_FILE 2>&1
$PERL_COMMAND neighborhood_update.pl 0 >> $NEIGH_LOG_FILE 2>&1
if [ $? -ne 0 ] ; then
  echo "Further neighborhood update aborted on `date +%D\ %r`" >> $NEIGH_LOG_FILE 2>&1
  exit 1
fi

echo "neighborhood update ended on `date +%D\ %r`" >> $NEIGH_LOG_FILE 2>&1
