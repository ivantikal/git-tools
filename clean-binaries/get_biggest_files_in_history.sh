#!/usr/bin/env bash

set -e   # set -o errexit
set -u   # set -o nounset
#set -o pipefail
[ "x${DEBUG:-}" = "x" ] || set -x

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__script="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__script_name="$(basename "${BASH_SOURCE[0]}")"
__start_dir=`pwd`

function ShowUsage
{
    echo "Usage: $0 -r <path to local repo> -n <number of biggest files to show>"
}

THE_DIR=
FILES_TO_SHOW=

while getopts r:n:h o
do  case "$o" in
   r)  THE_DIR="$OPTARG";;
   n)  FILES_TO_SHOW="$OPTARG";;
   [?] | h) ShowUsage ; exit 1;;
   esac
done

if [[ -z "${THE_DIR}" ]]; then
  ShowUsage
  exit 1
fi

if [[ ! -d "${THE_DIR}" ]]; then
  echo "ERROR: Folder [${THE_DIR}] does not exist!"
  exit 1
fi

if [[ ! ${FILES_TO_SHOW} =~ ^-?[0-9]+$ ]]; then
  echo "ERROR: number if files to show is not correct [${FILES_TO_SHOW}]!"
  exit 1
fi

tmp_dir=${__dir}/${__script_name}.tmp
mkdir -p ${tmp_dir}

cd ${THE_DIR}

git rev-list --objects --all | sort -k 2 > ${tmp_dir}/allfileshas.txt
git gc && git verify-pack -v .git/objects/pack/pack-*.idx | egrep "^\w+ blob\W+[0-9]+ [0-9]+ [0-9]+$" | sort -k 3 -n -r > ${tmp_dir}/bigobjects.txt

[[ -f ${tmp_dir}/bigtosmall.txt ]] && rm ${tmp_dir}/bigtosmall.txt

for SHA in `cut -f 1 -d\  < ${tmp_dir}/bigobjects.txt | head -n ${FILES_TO_SHOW}`; do
	echo $(grep $SHA ${tmp_dir}/bigobjects.txt) $(grep $SHA ${tmp_dir}/allfileshas.txt) | awk '{print $1,$3,$7}' >> ${tmp_dir}/bigtosmall.txt
done;

echo ""
echo "=============================================================="
echo "Please see the file:"
echo "   ${tmp_dir}/bigtosmall.txt"
echo "=============================================================="

cd ${__start_dir}


