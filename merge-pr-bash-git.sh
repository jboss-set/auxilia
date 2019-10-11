#!/bin/bash
#
# This script expects:
#
# 0. jq commandline JSON processor, see https://stedolan.github.io/jq
#
# 1. .netrc with configuration as follows:
#    machine	api.github.com
#    login	UID
#    password	ACCESS_TOKEN
#
# 2. Remote URLs in your jboss-eap clone using git protocol instead of https, ie. something like:
#    origin	git@github.com:istudens/jboss-eap7.git (fetch)
#    origin	git@github.com:istudens/jboss-eap7.git (push)
#    upstream	git@github.com:jbossas/jboss-eap7.git (fetch)
#    upstream	git@github.com:jbossas/jboss-eap7.git (push)
#
# 3. In case of remotes like above, the first parameter should be 'upstream' and the second parameter should be a number of PR being merged.
#

usage() {
    local script_name=$(basename "${0}")
    echo 1>&2 "Usage: ${script_name} <remote> <pr>"
    echo 1>&2 'Ex:'
    echo 1>&2 "${script_name} upstream 3"
}

isNetrcPresent() {
  echo todo
}

checkEapRemotes() {
  echo todo
}

isJqInstalled() {
  local jq_url='https://stedolan.github.io/jq'
  which jq > /dev/null
  if [  "${?}" != 0 ]; then
    echo "No jq commandline install - please install JQ before using this script: ${jq_url}"
  fi
}

sanity_check() {
  isJqInstalled
  isNetrcPresent
  checkEapRemotes
}

sanity_check
set -eo pipefail

if [ ${#} != 2 ]; then
    echo 1>&2 "Usage: $0 <remote> <pr>"
    exit 1
fi

readonly BRANCH=$(git rev-parse --abbrev-ref HEAD)
readonly REMOTE=${1}
readonly PR=${2}

if [ -z "${REMOTE}" ]; then
  echo "No REMOTE provided."
  usage
  exit 2
fi

if [ -z "${PR}" ]; then
  echo "No PR provided."
  usage
  exit 3
fi

echo "Merging ${PR} from ${REMOTE} onto ${BRANCH}"
readonly FETCH_URL=$(git remote -v | grep "${REMOTE}" | grep 'fetch' | cut -f2 | cut -d" " -f1)
readonly OWNER=$(echo "${FETCH_URL}" | cut -d: -f2 | cut -d/ -f1)
readonly REPO=$(echo "${FETCH_URL}" | cut -d: -f2 | cut -d/ -f2)
readonly PR_GITHUB_API_URL="https://api.github.com/repos/${OWNER}/${REPO}/pulls/${PR}"
set -e
echo -n "Retrieving PR information from ${PR_GITHUB_API_URL}..."
readonly PULL=$(curl -s -n ${PR_GITHUB_API_URL})
if [ "${?}" -ne 0 ]; then
  echo "Failed."
  exit 2
fi
echo 'Done.'
set +e

readonly MSG="Merge pull request #${PR} from $(echo ${PULL} | jq -r .head.label) $(echo $PULL | jq -r .title)"
echo "Git commit message will be: ${MSG}"
echo -n "Continue..." && read _
set -x
git fetch "${REMOTE}" "pull/${PR}/head"
git merge --no-ff -m "${MSG}" 'FETCH_HEAD'
