#!/usr/bin/env bash

set -e   # set -o errexit
set -u   # set -o nounset
#set -o pipefail
[ "x${DEBUG:-}" = "x" ] || set -x

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__script="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__start_dir=`pwd`

bfg_jar=${__dir}/bfg-1.12.15.jar
if [[ ! -f "${bfg_jar}" ]]; then
  wget http://repo1.maven.org/maven2/com/madgag/bfg/1.12.15/bfg-1.12.15.jar -O ${bfg_jar}
fi

repo_name=repo_with_binaries.git
git clone --mirror https://github.com/ivantikal/${repo_name} ${__dir}/${repo_name}
cd ${__dir}/${repo_name}
git remote remove origin
java -jar ${bfg_jar} --no-blob-protection --delete-files '*.{avi,chm,class,dll,doc,docx,exe,EXE,gz,gzip,iso,jar,lib,msi,o,pdb,pdf,pptx,ptt,so,swf,tar,tff,tgz,war,wmv,woff,xls,xlsx,zip}'

git reflog expire --expire=now --all && git gc --prune=now --aggressive
git remote add origin https://github.com/ivantikal/repo_without_binaries

echo ""
echo "To finish the process:"
echo " 1) check the 'origin' remote is pointing to the new repo"
echo "    cd ${__dir}/${repo_name}"
echo "    git remote -vv"
echo " 2) enter to the folder and push all changes to the new repo:"
echo "    cd ${__dir}/${repo_name}"
echo "    git push --all"
echo "    git push --tags"

cd ${__start_dir}
