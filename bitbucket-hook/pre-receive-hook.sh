#!/bin/bash
set -e
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
(
    source ${__dir}/lib/find_binaries.sh
    while read from_ref to_ref ref_name; do
        find_binaries "$to_ref"
   done ) | tee -a /tmp/pre-receive-hook.log
result=${PIPESTATUS[0]}
exit $result