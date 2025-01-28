#!/bin/bash

# TODO
# * [ ] shellcheck
# * [ ] Local make target
# * [ ] Ran in automation
# * [ ] tabs to spaces

# Install based on: https://vulkan.lunarg.com/doc/sdk/1.3.261.1/linux/getting_started.html
#
# Directories supposedly (other locations also possible) containing Vulkan
# driver manifests:
# 	/etc/vulkan/icd.d/
# 	/usr/share/vulkan/icd.d/

set -e

readonly vulkansdk_web='vulkansdk-linux-x86_64-1.3.261.1'
readonly vulkansdk_tar="${vulkansdk_web}.tar.xz"

error_exit() {
	echo "${1}"
	exit 1
}

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
		error_exit "Downloaded vulkan sdk package has unexpected checksum: ${vulkan_tar_checksum_local}"
	fi
}

install_runtime_dependencies_debian_bookworm() {
	echo "Updating currently installed packages via apt"
	sudo apt update
	sudo apt -y upgrade

	echo "Installing pre-requisites via apt"
	sudo apt -y install qtbase5-dev qtwayland5
}

install_runtime_dependencies_ubuntu_2204() {
	echo "Updating currently installed packages via apt"
	sudo apt update
	sudo apt -y upgrade

	echo "Installing pre-requisites via apt"
	sudo apt -y install qtbase5-dev qtwayland5
}

install_runtime_dependencies_ubuntu_2004() {
	# Ubuntu 20.04:	qt5-default qtwayland5

	echo "Function not yet implemented: install_runtime_dependencies_ubuntu_2004()"
}

install_runtime_dependencies_fedora() {
	# Fedora:	qt xinput libXinerama

	echo "Function not yet implemented: install_runtime_dependencies_fedora()"
}

install_runtime_dependencies_arch() {
	# Arch:		qt5-base libxcb libxinerama

	echo "Function not yet implemented: install_runtime_dependencies_arch()"
}

install_runtime_dependencies_slackware() {
	# Libraries checked with `slackpkg search <pkgname>`:
	#     qt5-5.15.3_20211130_014c375b-x86_64-2 was preinstalled
	#     libxcb-1.14-x86_64-3 was preinstalled
	#     libXinerama-1.1.4-x86_64-3 was preinstalled

	echo "Assuming runtime dependencies to already be present. Not installing."
}

install_runtime_dependencies() {
	local -r distro_name="$(grep '^NAME=' /etc/os-release | cut -d = -f 2)"

	echo "Installing runtime dependencies"

	# if [ # Ubuntu 22.04 # ] ; then
	# 	install_runtime_dependencies_ubuntu_2204
	# 	return
	# fi

	if [ "Debian GNU/Linux" == "${distro_name}" ] ; then
		install_runtime_dependencies_debian_bookworm
		return
	fi

	if [ "Slackware" == "${distro_name}" ] ; then
		install_runtime_dependencies_slackware
		return
	fi

	error_exit "Unsupported Linux distribution: ${distro_name}"
}

# TODO
# * Temporarily store downloaded resources to a common place.
#     * Add config.sh which tells the common place for resources.
main() {
	local -r vulkansdk_workarea="/tmp/vulkansdk_workarea"
	local -r vulkansdk_destination="${HOME}/my/tools"
	local -r vulkansdk_extracted_renamed="${vulkansdk_web}"
	local vulkansdk_extracted=''

	echo "Starting Vulkan SDK install"

	# TODO consider a more descriptive name
	if [ ! -d "${vulkansdk_workarea}" ] ; then
		mkdir "${vulkansdk_workarea}"
	fi

	pushd "${vulkansdk_workarea}"

	install_runtime_dependencies

	download_sdk_tar_package
	verify_sdk_tar_package

	vulkansdk_extracted="$(tar --list --file ${vulkansdk_tar} \
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

	echo "Giving a more descriptive name to extracted SDK directory"
	mv --verbose "${vulkansdk_extracted}" "${vulkansdk_extracted_renamed}"

	echo "Moving SDK directory under destination directory"
	mv --verbose \
		"${vulkansdk_extracted_renamed}" \
		"${vulkansdk_destination}/${vulkansdk_local_renamed}"

	popd # vulkan

	# TODO
	# * [ ] Slackware runtime dependencies install
	# * [ ] Check if there are more steps to SDK install
	# * [ ] Finalize the ending echo
	echo "[?] Finished Vulkan SDK install"
}

main "${@}"
