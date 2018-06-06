#!/bin/bash
# SPDX-License-Identifier: LGPL-3.0
# First parameter $1 - archive name
# Second parameter $2 - list of dirs to be backed up
set -e
RUNDATE=`date +%x`
RUNDATE=`./cutslash.sh $RUNDATE`
echo $RUNDATE
FILENAME="/backup/backup_"$RUNDATE"_"$1".tar"
DIR=""
tar -cvf $FILENAME /backup/scriptnconfthe
touch $FILENAME
for i in `cat $2`
do
  DIR="/"$i
  echo $DIR
  tar -rvf $FILENAME $DIR 
done
echo ""gzip $FILENAME
