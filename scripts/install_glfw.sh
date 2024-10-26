#!/bin/bash

set -e

readonly DEBUG='false'

error_exit() {
    echo "[!] ${1}"
    exit 1
}

detect_distro() {
    distro_name="$(grep '^NAME=' /etc/os-release | cut -d = -f 2)"
}

assert_distro_support() {
    if [ "Slackware" == "${distro_name}" ] ; then
        return
    fi

    error_exit "Unsupported Linux distribution: ${distro_name}"
}

install_glfw_slackware() {
    local -r slackbuild_output_file='output_slackbuild.txt'
    local -r slackbuilds_path="$HOME/my/tools/slackbuilds"
    local -r slackbuilds_finished_path="$HOME/my/tools/slackbuilds_finished"

    local calculated_md5sum=''
    local glfw_slackware_package_file=''
    local glfw_slackware_package_path=''
    local glfw_slackware_package_announcement=''

    mkdir ${slackbuilds_path}/glfw3
    pushd ${slackbuilds_path}/glfw3

    echo "Downloading tar package"
    wget http://slackbuilds.org/slackbuilds/15.0/libraries/glfw3.tar.gz

    echo "Extracting tar package"
    tar xf glfw3.tar.gz

    pushd glfw3

    echo "Downloading source tar package"
    wget https://github.com/glfw/glfw/archive/3.3.8/glfw-3.3.8.tar.gz

    echo "Verifying download"
    calculated_md5sum="$(md5sum glfw-3.3.8.tar.gz | cut -d ' ' -f 1)"
    if [ "55d99dc968f4cec01a412562a7cf851c" != "${calculated_md5sum}" ] ; then
        error_exit "Checksum mismatch. Calculated value: ${calculated_md5sum}"
    fi

    echo "Running slackbuild as root (directing output to a file)"
    su -l -c " \
        pushd ${slackbuilds_path}/glfw3/glfw3 && \
        ./glfw3.SlackBuild &> ${slackbuild_output_file} && \
        exit"

    if [ ! -f "${slackbuild_output_file}" ] ; then
        error_exit "Slackbuild log/output file not found"
    fi

    echo "Setting slackware package related variables"
    glfw_slackware_package_announcement="$( \
        grep 'Slackware package' ${slackbuild_output_file} | \
        grep 'created\.$')"

    glfw_slackware_package_path="$( \
        echo "${glfw_slackware_package_announcement}" | \
        cut -d ' ' -f 3)"

    glfw_slackware_package_file="$( \
        echo "${glfw_slackware_package_path}" | \
        cut -d / -f 3)"

    if [ "true" == "${DEBUG}" ] ; then
        echo "glfw_slackware_package_announcement is: ${glfw_slackware_package_announcement}"
        echo "glfw_slackware_package_path is: ${glfw_slackware_package_path}"
        echo "glfw_slackware_package_file is: ${glfw_slackware_package_file}"
    fi

    echo Copying built slackware package to finished slackbuilds
    cp --verbose ${glfw_slackware_package_path} ${slackbuilds_finished_path}/

    echo "Running slackware package install as root"
    su -l -c " \
        pushd ${slackbuilds_finished_path} && \
        installpkg ./${glfw_slackware_package_file} && \
        exit"

    popd
    popd
}

install_glfw() {
    if [ "Slackware" == "${distro_name}" ] ; then
        install_glfw_slackware
        return
    fi

    error_exit "No install logic for Linux distribution: ${distro_name}"
}

main() {
    local distro_name=''

    echo "$0 running..."

    detect_distro
    if [ -z "${distro_name}" ] ; then
        error_exit "Failed to detect Linux distribution"
    fi

    assert_distro_support

    install_glfw
}

main "${@}"
