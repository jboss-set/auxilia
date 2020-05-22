#!/bin/bash

usage() {
  echo TODO
}

sed_edit_file_if_exists() {
  local file=${1}
  local sed_query=${2}
  if [ -e "${file}" ]; then
    sed -i "${file}" -e "${sed_query}"
  else
    echo "Warning: No such file ${file}."
  fi
}

readonly VERSION_SUFFIX=${VERSION_SUFFIX:-'.GA-redhat-SNAPSHOT'}
readonly PREVIOUS_VERSION=${1}
readonly NEXT_VERSION=${2}
readonly EAP7_RELEASE=${EAP7_RELEASE:-'true'}
readonly PRODUCT_VERSION=${PRODUCT_VERSION:-'6.4.24.Alpha1'}

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
else
  echo "JBoss EAP workspace lives in ${JBOSS_EAP_WORKSPACE}."
fi

cd "${JBOSS_EAP_WORKSPACE}" > /dev/null || exit 4

readonly FROM="${PREVIOUS_VERSION}${VERSION_SUFFIX}"
readonly TO="${NEXT_VERSION}${VERSION_SUFFIX}"
echo "Updating all pom.xml files from ${FROM} to ${TO}:"
find . -name pom.xml | \
while
  read -r pomFile
do
  echo -n "- ${pomFile}: "
  sed -i "${pomFile}" -e "s;${FROM};${TO};g"
  echo 'Done.'
done

if [ "${EAP7_RELEASE}" = 'true' ]; then
  readonly PRODUCT_POM=${PRODUCT_POM:-'./pom.xml'}
  readonly PRODUCT_VERSION_TXT=${PRODUCT_VERSION_TXT:-'feature-pack/src/main/resources/content/version.txt'}
  readonly GALLEON_PACK_PRODUCT_VERSION_TXT=${GALLEON_PACK_PRODUCT_VERSION_TXT:-'galleon-pack/src/main/resources/packages/version.txt/content/version.txt'}
  readonly PRODUCT_VERSION="${NEXT_VERSION}.GA"

  echo -n "Update ${PRODUCT_POM} and ${PRODUCT_VERSION_TXT} to ${PRODUCT_VERSION}..."
  sed_edit_file_if_exists "${PRODUCT_POM}" "s;\(<product.release.version>\)[^<]*\(.*$\);\1${PRODUCT_VERSION}\2;"
  sed_edit_file_if_exists "${PRODUCT_VERSION_TXT}" "s;\(^.* Version \).*;\1${PRODUCT_VERSION};"
  sed_edit_file_if_exists "${GALLEON_PACK_PRODUCT_VERSION_TXT}" "s;\(^.* Version \).*;\1${PRODUCT_VERSION};"
  echo 'Done.'
else
  if [ -z "${PRODUCT_VERSION}" ]; then
    echo 'Undefined PRODUCT_VERSION - aborting.'
    exit 1
  fi
  readonly BUILD_MANIFEST='build/src/main/resources/modules/system/layers/base/org/jboss/as/product/eap/dir/META-INF/MANIFEST.MF'
  readonly BUILD_VERSION='build/src/main/resources/version.txt'
  echo "Set product version to ${PRODUCT_VERSION} in ${BUILD_MANIFEST} and ${BUILD_VERSION}."
  sed_edit_file_if_exists "${BUILD_MANIFEST}" "s;\(JBoss-Product-Release-Version: \).*$;\1${PRODUCT_VERSION};g"
  sed_edit_file_if_exists "${BUILD_VERSION}" "s;^\(Red Hat JBoss Enterprise Application Platform - Version \).*$;\1${PRODUCT_VERSION};g"
  echo 'Done.'
fi
