#!/bin/bash

terminateTree() {
	for cpid in $(/usr/bin/pgrep -P $1); do
		terminateTree $cpid
	done
	kill -9 $1 > /dev/null 2>&1
}

# shellcheck disable=SC2048
for pid in $*; do
	terminateTree $pid
done