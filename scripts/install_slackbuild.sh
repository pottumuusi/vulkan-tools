#!/bin/bash

set -e

# readonly DEBUG='false'

error_exit() {
    echo "[!] ${1}"
    exit 1
}

assert_variable() {
    if [ -z "${!1}" ] ; then
        error_exit "Variable ${1} is not set."
    fi
}

assert_mandatory_variables() {
    assert_variable "SLKBLDSCRIPT_BUILD_NAME"
    assert_variable "SLKBLDSCRIPT_BUILD_ARCHIVE"
    assert_variable "SLKBLDSCRIPT_SOURCE_ARCHIVE"
    assert_variable "SLKBLDSCRIPT_REMOTE_BUILD_ARCHIVE"
    assert_variable "SLKBLDSCRIPT_REMOTE_SOURCE_ARCHIVE"
    assert_variable "SLKBLDSCRIPT_SOURCE_ARCHIVE_CHECKSUM"
}

install_slackbuild() {
    local -r slackbuild_output_file='output_slackbuild.txt'
    local -r slackbuilds_path="$HOME/my/tools/slackbuilds"
    local -r slackbuilds_finished_path="$HOME/my/tools/slackbuilds_finished"

    local calculated_md5sum=''
    local slackware_package_file=''
    local slackware_package_path=''
    local slackware_package_announcement=''

    local WORKAREA=''

    mkdir ${slackbuilds_path}/${SLKBLDSCRIPT_BUILD_NAME}
    pushd ${slackbuilds_path}/${SLKBLDSCRIPT_BUILD_NAME}

    echo "Downloading slackbuild tar package"
    wget "${SLKBLDSCRIPT_REMOTE_BUILD_ARCHIVE}"

    echo "Extracting slackbuild tar package"
    tar xf "${SLKBLDSCRIPT_BUILD_ARCHIVE}"

    pushd ./${SLKBLDSCRIPT_BUILD_NAME}
    WORKAREA="$(pwd)"

    echo "Downloading source tar package"
    wget ${SLKBLDSCRIPT_REMOTE_SOURCE_ARCHIVE}

    echo "Verifying download"
    calculated_md5sum="$(md5sum "${SLKBLDSCRIPT_SOURCE_ARCHIVE}" | cut -d ' ' -f 1)"
    if [ "${SLKBLDSCRIPT_SOURCE_ARCHIVE_CHECKSUM}" != "${calculated_md5sum}" ] ; then
        error_exit "Checksum mismatch. Calculated value: ${calculated_md5sum}"
    fi

    echo "Running slackbuild as root (directing output to a file)"
    su -l -c " \
        pushd ${WORKAREA} && \
        ./${SLKBLDSCRIPT_BUILD_NAME}.SlackBuild &> ${slackbuild_output_file} && \
        exit"

    if [ ! -f "${slackbuild_output_file}" ] ; then
        error_exit "Slackbuild log/output file not found"
    fi

    echo "Setting slackware package related variables"
    slackware_package_announcement="$( \
        grep 'Slackware package' ${slackbuild_output_file} | \
        grep 'created\.$')"

    slackware_package_path="$( \
        echo "${slackware_package_announcement}" | \
        cut -d ' ' -f 3)"

    slackware_package_file="$( \
        echo "${slackware_package_path}" | \
        cut -d / -f 3)"

    if [ "true" == "${DEBUG}" ] ; then
        echo "slackware_package_announcement is: ${slackware_package_announcement}"
        echo "slackware_package_path is: ${slackware_package_path}"
        echo "slackware_package_file is: ${slackware_package_file}"
    fi

    echo Copying built slackware package to finished slackbuilds
    cp --verbose ${slackware_package_path} ${slackbuilds_finished_path}/

    echo "Running slackware package install as root"
    su -l -c " \
        pushd ${slackbuilds_finished_path} && \
        installpkg ./${slackware_package_file} && \
        exit"

    popd
    popd
}

main() {
    echo "$0 running..."

    assert_mandatory_variables

    install_slackbuild
}

main "${@}"
