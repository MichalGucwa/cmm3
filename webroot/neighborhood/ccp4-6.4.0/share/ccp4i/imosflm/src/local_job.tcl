#!/bin/sh
# $Id: local_job.tcl,v 1.8 2010/01/21 16:02:25 rmk65 Exp $
echo "${MOSFLM_ROOT}mosflm < $HOME/.mosflm/batch.scr &> $HOME/.mosflm/remote.log"
${MOSFLM_ROOT}mosflm < $HOME/.mosflm/batch.scr &> $HOME/.mosflm/remote.log
echo `date` >> $HOME/.mosflm/remote.log
