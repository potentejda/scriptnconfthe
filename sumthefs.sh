#!/bin/bash
# SUMTHEFS
# This scripts maps the filesystem tree from / node
# and writes down cryptograhpic checksums for files
# and also linker info for executables
## 
# First parameter $1 - sum name
# Second parameter $2 - config file

#MAIN
set -e
RUNDATE=`date +%x`
SUPERSTART=`pwd`
CONFIG=$SUPERSTART"/"$2
if [ -x /usr/bin/ld ]; then
  LD=/usr/bin/ld
  $LD -V
else
  LD=""
fi

function ldfile {
  # First parameter $1 - log path
  # Second paramter $2 - file path
  # Third parameter $3 - linker
  echo "$3 -M $2" >> $1
  set +e
  $3 -M $2 -o /dev/null >> $1
  set -e
}

function sumthefile {
  # First parameter $1 - log path
  # Second parameter $2 - file path
  # Third patameter $3 - linker
  echo $2
  if [ -x /bin/sha256sum ]; then
    /bin/sha256sum $2 >> $1
  elif [ -x /usr/bin/cksum ]; then
    /usr/bin/cksum -a sha256 $2 >> $1
  fi
  #sha224sum $2 >> $1
  #sha256sum $2 >> $1
  #sha384sum $2 >> $1
  #sha512sum $2 >> $1
  if [ -z $3 ]; then
    echo "Not checking linker"
  elif [ -x $LD ]; then
    echo "Linker Info"
    ldfile $1 $2 $3
  else
    echo "No linker checks considered"
  fi
}

function search {
  # First parameter $1 - path to log
  # Second parameter $2 - path to dir
  LOGFILENAME=$1
  start=$2
  if [ -h $start ]; then
    echo "Symlink found."
    echo "Symlink "`ls -lsah $start` >> $LOGFILENAME
  else
    for i in `ls $start`; do
      ANALYZED=$start"/"${i}
      echo $ANALYZED >> $LOGFILENAME
      echo $ANALYZED
      if [ -d $ANALYZED ]; then
        echo $ANALYZED
        search $LOGFILENAME $ANALYZED &
      elif [ -x $ANALYZED ]; then
        sumthefile $LOGFILENAME $ANALYZED $LD
      elif [ -f $ANALYZED ]; then
        sumthefile $LOGFILENAME $ANALYZED $LD
      else
        echo $ANALYZED
        echo "Node does not match to anything interesting in this version"
      fi
    done
    cd $start
  fi
}

#MAIN

RUNDATE=`./cutslash.sh $RUNDATE`
LOGDIR=`pwd`"/summedfs_"$RUNDATE$1
LOGFILENAME=$LOGDIR"/AllPaths$RUNDATE.log"
mkdir $LOGDIR
touch $LOGDIR/error$RUNDATE"_"$1.log
time {
  echo "Log name: $1" >> $LOGFILENAME
  echo "Config text:" >> $LOGFILENAME
  cat $CONFIG && >> $LOGFILENAME
  echo "Tree:" >> $LOGFILENAME
  find / >> $LOGFILENAME
  echo "Cryptographic checksums and linker info:" >> $LOGFILENAME
  for i in `cat $CONFIG`; do
    search $LOGFILENAME $i
    echo `pwd`$i
  done
  echo "Sumfs Finished"
} 2>$LOGDIR/error$RUNDATE"_"$1.log 
