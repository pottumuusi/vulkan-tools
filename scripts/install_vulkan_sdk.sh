#!/bin/bash

# TODO shellcheck
# * Local make target
# * Ran in automation

# Install based on: https://vulkan.lunarg.com/doc/sdk/1.3.261.1/linux/getting_started.html
#
# Directories supposedly (other locations also possible) containing Vulkan
# driver manifests:
# 	/etc/vulkan/icd.d/
# 	/usr/share/vulkan/icd.d/

set -e

# TODO
# * Temporarily store downloaded resources to a common place.
#     * Add config.sh which tells the common place for resources.
# * Write in functions
# * Perform the download in 'deps_install_workarea'
main() {
	local -r vulkan_tar_checksum_from_web='d72e6c05c05e4ffc30a11fb52758bd67b04d76601d5c42a5306b58a0099dd9bc'
	local -r vulkansdk_web='vulkansdk-linux-x86_64-1.3.261.1'
	local -r vulkansdk_tar="${vulkansdk_web}.tar.xz"
	local -r vulkansdk_destination="${HOME}/my/tools"
	local -r vulkansdk_local_renamed="${vulkansdk_web}"
	vulkansdk_local=''
	vulkan_tar_checksum_local=''

	if [ ! -d vulkan ] ; then
		mkdir vulkan
	fi

	pushd vulkan

	sudo apt update
	sudo apt -y upgrade
	sudo apt -y install qtbase5-dev libxcb-xinput0 libxcb-xinerama0

	if [ ! -f ./${vulkansdk_tar} ] ; then
		curl -o ${vulkansdk_tar} https://sdk.lunarg.com/sdk/download/1.3.261.1/linux/${vulkansdk_tar}
		vulkan_tar_checksum_local="$(sha256sum ${vulkansdk_tar} | cut -d ' ' -f 1)"

		if [ "${vulkan_tar_checksum_from_web}" != "${vulkan_tar_checksum_local}" ] ; then
			echo "Downloaded vulkan sdk package has unexpected checksum: ${vulkan_tar_checksum_local}"
			exit 1
		fi
	fi

	vulkansdk_local="$(tar --list --file ${vulkansdk_tar} \
		| head -1 \
		| sed -e 's|/$||')"
	tar xf ./${vulkansdk_tar}

	if [ ! -d "${vulkansdk_destination}" ] ; then
		echo ""
		echo "[!] No destination directory for Vulkan SDK [!]"
		echo -n "Please create the directory and set it's path to be "
		echo "value of 'vulkansdk_destination'"
		echo ""
		exit 1
	fi

	mv --verbose "${vulkansdk_local}" "${vulkansdk_local_renamed}"
	mv --verbose \
		"${vulkansdk_local_renamed}" \
		"${vulkansdk_destination}/${vulkansdk_local_renamed}"

	# TODO continue here

	popd # vulkan
}

main "${@}"
