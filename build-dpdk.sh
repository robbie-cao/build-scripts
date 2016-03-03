#!/bin/sh -e
#
# Read doc/build-sdk-quick.txt in the tarball for quick notes about the build
# system of DPDK.  Build system of DPDK may change in a substantial way so be
# careful when doing version bump or downgrade
#
# - 27. Development Kit Build System, http://dpdk.org/doc/guides/prog_guide/dev_kit_build_system.html
#
# If you are building inside an VM and get the following error, try specifying
# `-cpu host' for QEMU or building on a physical host
#
#	cc1: error: CPU you selected does not support x86-64 instruction set
#
# - [dpdk-dev] CPU does not support x86-64 instruction set,
#	http://dpdk.org/ml/archives/dev/2014-June/003748.html
#
# Building for x86_64-ivshmem-linuxapp-gcc will generate kenrel modules
# rte_kni.ko, igb_uio.ko, etc.
#
PKG_NAME=dpdk
PKG_VERSION=2.2.0
PKG_SOURCE="$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_SOURCE_URL="http://dpdk.org/browse/dpdk/snapshot/$PKG_SOURCE"
PKG_SOURCE_MD5SUM=22e2fd68cd5504f43fe9a5a6fd6dd938
PKG_PLATFORM=linux

. "$PWD/env.sh"
. "$PWD/utils-kconfig.sh"

dpdk_target=x86_64-native-linuxapp-gcc
dpdk_prefix="$INSTALL_PREFIX/dpdk/dpdk-$PKG_VERSION-$dpdk_target"

configure() {
	local dotc="$PKG_BUILD_DIR/config/common_linuxapp"

	cd "$PKG_BUILD_DIR"
	set_option CONFIG_RTE_BUILD_COMBINE_LIBS y "$dotc"
	set_option CONFIG_RTE_LIBRTE_VHOST y "$dotc"
	$MAKEJ config "T=$dpdk_target"
}

#RTE_KERNELDIR='linux headers path'

# dpdk passes $EXTRA_LDFLAGS directly to the linker, but -Wl,-rpath,xxx is for
# the compiler
EXTRA_LDFLAGS="$(echo "$EXTRA_LDFLAGS" | sed -e 's/-Wl,-rpath,/-rpath=/g')"
MAKE_VARS="								\\
	EXTRA_CPPFLAGS='$EXTRA_CPPFLAGS'	\\
	EXTRA_CFLAGS='$EXTRA_CFLAGS -fPIC'	\\
	EXTRA_LDFLAGS='$EXTRA_LDFLAGS'		\\
	prefix='$dpdk_prefix'				\\
	T='$dpdk_target'					\\
	V=1									\\
"

# Changes in build method from 2.0.0 to 2.2.0
#
# - 2.2.0 supports prefix= variable when doing compile and install.  We can use
#	the mechanism to install it to $dpdk_prefix and use it with openvswitch.
# - With 2.0.0, we'd better just use the default ./ for installation
# - Maybe T= is not needed in 2.2.0.
# - By default only static libraries will be built, and it's good for
#	simplicity.  But building libopenvswitch.so requires object files in
#	archive to be built with -fPIC
# - Openvswitch 2.4.0 is supposed to only work with DPDK 2.0.0 because it
#	requires libintel_dpdk but in DPDK 2.2.0, the name is changed to libdpdk
#
# see mk/rte.sdkinstall.mk for detailed if.else.
