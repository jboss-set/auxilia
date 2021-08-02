#!/bin/bash

usage() {
  echo TODO
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
PREVIOUS_XP_VERSION=${3}
NEXT_XP_VERSION=${4}

readonly FEATURE_PACK_VERSION_FILE='feature-pack/src/main/resources/content/version.txt'
readonly EE_FEATURE_PACK_VERSION_FILE='ee-feature-pack/common/src/main/resources/content/version.txt'

if [ -e "${FEATURE_PACK_VERSION_FILE}" ]; then
  readonly PRODUCT_VERSION_TXT=${FEATURE_PACK_VERSION_FILE}
elif [ -e "${EE_FEATURE_PACK_VERSION_FILE}" ]; then
  readonly PRODUCT_VERSION_TXT=${EE_FEATURE_PACK_VERSION_FILE}
else
  echo 'current EAP version is not found from config file version.txt - aborting.'
  usage
  exit 1
fi

readonly PRODUCT_VERSION_ALT_TXT=${PRODUCT_VERSION_ALT_TXT:-'galleon-pack/src/main/resources/packages/version.txt/content/version.txt'}
readonly PRODUCT_VERSION_REGEXP='Red Hat JBoss Enterprise Application Platform - Version (.*)'
CURRENT_PRODUCT_VERSION=$(cat "${PRODUCT_VERSION_TXT}")

if [[ "${CURRENT_PRODUCT_VERSION}" =~ ${PRODUCT_VERSION_REGEXP} ]]; then
  version="${BASH_REMATCH[1]}"
  major=$(echo "${version}" | cut -d '.' -f 1)
  minor=$(echo "${version}" | cut -d '.' -f 2)
  micro=$(echo "${version}" | cut -d '.' -f 3)

  PREVIOUS_VERSION="${major}.${minor}.${micro}"
  NEXT_VERSION="${major}.${minor}.$((micro+1))"

  PREVIOUS_XP_VERSION="1.0.$((micro-1))"
  NEXT_XP_VERSION="1.0.${micro}.GA"
fi

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
readonly XP_MINOR_VERSION="${NEXT_VERSION##*.}"
readonly XP_PRODUCT_VERSION="1.0.$( expr "${XP_MINOR_VERSION}" - 1 ).GA"

echo -n "Update ${PRODUCT_POM} and ${PRODUCT_VERSION_TXT} to ${PRODUCT_VERSION}..."
editFileIfExistWithSED "${PRODUCT_POM}" "s;\(<full.dist.product.release.version>\)[^<]*\(.*$\);\1${PRODUCT_VERSION}\2;"
editFileIfExistWithSED "${PRODUCT_VERSION_TXT}" "s;\(^.* Version \).*;\1${PRODUCT_VERSION};"
editFileIfExistWithSED "${PRODUCT_VERSION_ALT_TXT}" "s;\(Red Hat JBoss Enterprise Application Platform - Version \).*;\1${PRODUCT_VERSION};" 0
echo 'Done.'

echo -n "Update ${PRODUCT_POM} to XP version ${XP_PRODUCT_VERSION}..."
editFileIfExistWithSED "${PRODUCT_POM}" "s;\(<expansion.pack.release.version>\)[^<]*\(.*$\);\1${NEXT_XP_VERSION}\2;"
echo 'Done.'
echo -n "Update ${PRODUCT_POM} to XP version ${XP_PRODUCT_VERSION}..."
editFileIfExistWithSED "${PRODUCT_POM}" "s;\(<expansion.pack.release.version>\)[^<]*\(.*$\);\1${XP_PRODUCT_VERSION}\2;"
echo 'Done.'
