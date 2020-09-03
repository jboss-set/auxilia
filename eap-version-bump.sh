#!/bin/bash

usage() {
  echo TODO
}

readonly VERSION_SUFFIX=${VERSION_SUFFIX:-'.GA-redhat-SNAPSHOT'}
PREVIOUS_VERSION=${1}
NEXT_VERSION=${2}
PREVIOUS_XP_VERSION=${3}
NEXT_XP_VERSION=${4}

readonly PRODUCT_VERSION_ALT_TXT=${PRODUCT_VERSION_ALT_TXT:-'galleon-pack/src/main/resources/packages/version.txt/content/version.txt'}
readonly PRODUCT_VERSION_REGEXP='Red Hat JBoss Enterprise Application Platform - Version (.*)'
CURRENT_PRODUCT_VERSION=$(cat "${PRODUCT_VERSION_ALT_TXT}")

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

if [ ! -e "${JBOSS_EAP_WORKSPACE}"  -a ! -d "${JBOSS_EAP_WORKSPACE}" ]; then
  echo "The provided JBOSS_EAP_WORKSPACE does not exists or is not a directory: ${JBOSS_EAP_WORKSPACE}"
  echo 'Please provide the appropriate path (or cd to the workspace).'
  usage
  exit 3
fi

cd "${JBOSS_EAP_WORKSPACE}" > /dev/null

readonly FROM="${PREVIOUS_VERSION}${VERSION_SUFFIX}"
readonly TO="${NEXT_VERSION}${VERSION_SUFFIX}"
echo -n "Updating all pom.xml files from ${FROM} to ${TO}..."

find . -name pom.xml -exec sed -i "s/${FROM}/${TO}/g" '{}' \;
echo 'Done.'

readonly PRODUCT_POM=${PRODUCT_POM:-'./pom.xml'}
readonly PRODUCT_VERSION_TXT=${PRODUCT_VERSION_TXT:-'feature-pack/src/main/resources/content/version.txt'}
readonly PRODUCT_VERSION="${NEXT_VERSION}.GA"

echo -n "Update ${PRODUCT_POM} and ${PRODUCT_VERSION_TXT} to ${PRODUCT_VERSION}..."
sed -i "${PRODUCT_POM}" -e "s;\(<full.dist.product.release.version>\)[^<]*\(.*$\);\1${PRODUCT_VERSION}\2;"
sed -i "${PRODUCT_VERSION_TXT}" -e "s;\(^.* Version \).*;\1${PRODUCT_VERSION};"
sed -i "${PRODUCT_VERSION_ALT_TXT}" -e "s;\(Red Hat JBoss Enterprise Application Platform - Version \).*;\1${PRODUCT_VERSION};"

echo -n "Update ${PRODUCT_POM} to XP version ${XP_PRODUCT_VERSION}..."
sed -i "${PRODUCT_POM}" -e "s;\(<expansion.pack.release.version>\)[^<]*\(.*$\);\1${NEXT_XP_VERSION}\2;"
echo 'Done.'
