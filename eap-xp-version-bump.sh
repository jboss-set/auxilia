#!/bin/bash

usage() {
  echo "usage: ${0}: [current-version] [next-version]"
}

editFileIfExistWithSED() {
  local file="${1}"
  local query="${2}"
  local statusIfFileMissing="${3:-1}"

  if [ -e "${file}" ]; then
    sed -i "${file}" -e "${query}"
  else
    if [ "${statusIfFileMissing}" -ne 0 ]; then
      echo "There is no such file '${file}'"
      exit "${statusIfFileMissing}"
    fi
  fi
}

readonly VERSION_SUFFIX=${VERSION_SUFFIX:-'.GA-redhat-SNAPSHOT'}
PREVIOUS_VERSION=${1}
NEXT_VERSION=${2}

if [ -z "${PREVIOUS_VERSION}" ]; then
  echo 'Current EAP version not provided - aborting.'
  usage
  exit 1
fi

if [ -z "${NEXT_VERSION}" ]; then
  echo 'Next EAP version not provided - aborting.'
  usage
  exit 2
fi

readonly JBOSS_EAP_WORKSPACE=${JBOSS_EAP_WORKSPACE:-$(pwd)}

if [ ! -e "${JBOSS_EAP_WORKSPACE}" ] && [ ! -d "${JBOSS_EAP_WORKSPACE}" ]; then
  echo "The provided JBOSS_EAP_WORKSPACE does not exists or is not a directory: ${JBOSS_EAP_WORKSPACE}"
  echo 'Please provide the appropriate path (or cd to the workspace).'
  usage
  exit 3
fi

cd "${JBOSS_EAP_WORKSPACE}" > /dev/null || exit

readonly FROM="${PREVIOUS_VERSION}${VERSION_SUFFIX}"
readonly TO="${NEXT_VERSION}${VERSION_SUFFIX}"
echo -n "Updating all pom.xml files from ${FROM} to ${TO}..."

find . -name pom.xml -exec sed -i "s/${FROM}/${TO}/g" '{}' \;
echo 'Done.'

readonly PRODUCT_POM=${PRODUCT_POM:-'./pom.xml'}
readonly PRODUCT_VERSION="${NEXT_VERSION}.GA"

echo -n "Update ${PRODUCT_POM} to XP version ${PRODUCT_VERSION}..."
editFileIfExistWithSED "${PRODUCT_POM}" "s;\(<expansion.pack.release.version>\)[^<]*\(.*$\);\1${PRODUCT_VERSION}\2;"
echo 'Done.'
