#!/bin/bash
#set -x
set -e

MAX_DEEP=${MAX_DEEP-100}
EXCLUDE_REGEX=${EXCLUDE_REGEX-'AcceptanceTests\.xls$|\.png$|\.jpeg$|\.jpg$|\.gif$|\.svg$|\.swf$|\.bmp$'}
MAX_BINARY_SIZE=${MAX_BINARY_SIZE-250000}

function check_the_commit_binaries()
{
	local sha1=$1
	if [ -z $sha1 ]; then
		echo "Function $0 requires one parameter - sha1 of the commit!"
		return 1
	fi
	echo "Processing (${deep}) ${sha1}"

	files=`git log -1 --numstat --pretty="" $sha1 | grep -v -E '^[0-9]+' | grep -v -E ${EXCLUDE_REGEX}` || true
	if [ ! -z "$files" ]; then
		echo "=========================================================="
		echo "($deep) SHA1=$sha1"
		echo "$files"
		echo "=========================================================="
		echo "ERROR: This commit contains not allowed binary files!"
		echo "=========================================================="
		exit 1
	fi
	
	files=`git log -1 --numstat --pretty="" $sha1 | grep -v -E '^[0-9]+' ` || true
	if [ ! -z "$files" ]; then
		for the_file in "$files"; do
			the_file=$(echo $the_file | sed 's/-\s*-\s*//g')
			the_size=$(git show ${sha1}:${the_file} | wc -c)
			if [[ $the_size -gt $MAX_BINARY_SIZE ]]; then
				echo "=========================================================="
				echo " ERROR: "
				echo " The binary file is too big (max allowed size is $MAX_BINARY_SIZE) "
				echo " ${the_file}"
				echo "=========================================================="
				exit 1
			fi
		done
	fi

}

## First call with one parameter - SHA1
function find_binaries()
{
	local sha1=$1
	if [ "${sha1}" = "0000000000000000000000000000000000000000" ]; then
		# Do nothing in case of deleting the branch
		exit 0
	fi
	local deep=${2-0}
	deep=$((deep+1))
	if [ "$deep" -lt "$MAX_DEEP" ]; then
		contain_branches=`git branch --contain $sha1` || true
		if [ "${contain_branches}" != "" ]; then
			echo "------------------------------------------------------------------------"
			echo "The following branch(es) contain the commit ${sha1} already:"
			echo "${contain_branches}"
			echo "------------------------------------------------------------------------"
			return 0
		fi
		check_the_commit_binaries $sha1

		local parents=`git log --pretty=%P -n 1 $sha1`
		for i in $parents; do
		#	echo $0 $sha1 $deep
			find_binaries $i $deep
		done
	else
		echo "ERROR: the maximum deep of search is $MAX_DEEP!"
		exit 1
	fi
}