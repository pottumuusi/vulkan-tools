#!/bin/bash

# Google's glslc is a shader compiler for compiling GLSL to bytecode.
#
# A couple of downloads are available from:
# https://github.com/google/shaderc/blob/main/downloads.md
#
# This script downloads 'Linux gcc release' archive found from page above.

set -e

main() {
    echo "$0 running..."

    if [ ! -d /tmp/install_glslc ] ; then
        mkdir /tmp/install_glslc
    fi

    pushd /tmp/install_glslc

    if [ ! -f install.tgz ] ; then
        wget https://storage.googleapis.com/shaderc/artifacts/prod/graphics_shader_compiler/shaderc/linux/continuous_gcc_release/443/20231201-072543/install.tgz
    fi

    if [ ! -d install ] ; then
        tar xvf ./install.tgz
    fi

    echo "Copying glslc to privileged directory as root"
    su -l -c " \
        pushd /tmp/install_glslc/install && \
        cp --verbose ./bin/glslc /usr/local/bin/"
}

main "${@}"
