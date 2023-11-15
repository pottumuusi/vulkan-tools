#!/bin/bash

# TODO shellcheck
# * Local make target
# * Ran in automation
# * tabs to spaces

# Install based on: https://vulkan.lunarg.com/doc/sdk/1.3.261.1/linux/getting_started.html
#
# Directories supposedly (other locations also possible) containing Vulkan
# driver manifests:
# 	/etc/vulkan/icd.d/
# 	/usr/share/vulkan/icd.d/

set -e

readonly vulkansdk_web='vulkansdk-linux-x86_64-1.3.261.1'
readonly vulkansdk_tar="${vulkansdk_web}.tar.xz"

download_sdk_tar_package() {
	echo "Dropping the SDK tar package to host"
	if [ ! -f ./"${vulkansdk_tar}" ] ; then
		curl -o "${vulkansdk_tar}" https://sdk.lunarg.com/sdk/download/1.3.261.1/linux/"${vulkansdk_tar}"
	fi
}

verify_sdk_tar_package() {
	local -r vulkan_tar_checksum_from_web='d72e6c05c05e4ffc30a11fb52758bd67b04d76601d5c42a5306b58a0099dd9bc'
	local -r vulkan_tar_checksum_local="$(sha256sum "${vulkansdk_tar}" | cut -d ' ' -f 1)"

	echo "Verifying SDK tar package checksum"

	if [ "${vulkan_tar_checksum_from_web}" != "${vulkan_tar_checksum_local}" ] ; then
		echo "Downloaded vulkan sdk package has unexpected checksum: ${vulkan_tar_checksum_local}"
		exit 1
	fi
}

# TODO
# * Temporarily store downloaded resources to a common place.
#     * Add config.sh which tells the common place for resources.
# * Write in functions
# * Perform the download in 'deps_install_workarea'
main() {
	local -r vulkansdk_destination="${HOME}/my/tools"
	local -r vulkansdk_local_renamed="${vulkansdk_web}"
	vulkansdk_local=''

	# TODO consider a more descriptive name
	if [ ! -d vulkan ] ; then
		mkdir vulkan
	fi

	pushd vulkan

	echo "Updating currently installed packages via apt"
	sudo apt update
	sudo apt -y upgrade

	echo "Installing pre-requisites via apt"
	sudo apt -y install qtbase5-dev libxcb-xinput0 libxcb-xinerama0

	download_sdk_tar_package
	verify_sdk_tar_package

	vulkansdk_local="$(tar --list --file ${vulkansdk_tar} \
		| head -1 \
		| sed -e 's|/$||')"

	echo "Extracting SDK tar package"
	tar xf ./${vulkansdk_tar}

	if [ ! -d "${vulkansdk_destination}" ] ; then
		echo ""
		echo "[!] No destination directory for Vulkan SDK [!]"
		echo -n "Please create the directory and set it's path to be "
		echo "value of 'vulkansdk_destination'"
		echo ""
		exit 1
	fi

	# TODO
	# Experiencing the following:
	# mv: cannot move 'vulkansdk-linux-x86_64-1.3.261.1' to '/home/tank/my/tools/vulkansdk-linux-x86_64-1.3.261.1/vulkansdk-linux-x86_64-1.3.261.1': Directory not empty
	#
	# Remove the destination directory or figure out something else.
	echo "What might be happening here?"
	mv --verbose "${vulkansdk_local}" "${vulkansdk_local_renamed}"
	mv --verbose \
		"${vulkansdk_local_renamed}" \
		"${vulkansdk_destination}/${vulkansdk_local_renamed}"

	# TODO continue here

	popd # vulkan
}

main "${@}"
