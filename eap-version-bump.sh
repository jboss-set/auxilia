#!/bin/bash

usage() {
  echo TODO
}

readonly VERSION_SUFFIX=${VERSION_SUFFIX:-'.GA-redhat-SNAPSHOT'}
readonly PREVIOUS_VERSION=${1}
readonly NEXT_VERSION=${2}

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
SED="sed -i"
if [[ ${OSTYPE} == "darwin"* ]]; then
  SED="sed -i ''"
fi

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

eval "find . -name pom.xml -exec $SED "s/${FROM}/${TO}/g" '{}' \;"
echo 'Done.'

readonly PRODUCT_POM=${PRODUCT_POM:-'./pom.xml'}
readonly PRODUCT_VERSION_TXT=${PRODUCT_VERSION_TXT:-'feature-pack/src/main/resources/content/version.txt'}
readonly PRODOCT_VERSION_ALT_TXT=${PRODOCT_VERSION_ALT_TXT:-'galleon-pack/src/main/resources/packages/version.txt/content/version.txt'}
readonly PRODUCT_VERSION="${NEXT_VERSION}.GA"

echo -n "Update ${PRODUCT_POM} and ${PRODUCT_VERSION_TXT} to ${PRODUCT_VERSION}..."
eval "$SED -e \"s;\(<full.dist.product.release.version>\)[^<]*\(.*$\);\1${PRODUCT_VERSION}\2;\" \"${PRODUCT_POM}\""
eval "$SED -e \"s;\(^.* Version \).*;\1${PRODUCT_VERSION};\" \"${PRODUCT_VERSION_TXT}\""
eval "$SED -e \"s;\(Red Hat JBoss Enterprise Application Platform - Version \).*;\1${PRODUCT_VERSION};\" \"${PRODOCT_VERSION_ALT_TXT}\""

echo 'Done.'
