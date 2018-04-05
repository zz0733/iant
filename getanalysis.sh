#!/bin/bash
LOG_PATH=$1
cat $LOG_PATH|sed 's/^.*STARTBODY://g'|sed 's/:ENDBODY.*$//g'