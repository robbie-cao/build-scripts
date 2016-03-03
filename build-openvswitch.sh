#!/bin/sh -e
#
# On building kernel module
#
#  - Build on CentOS 7 will not work.  CentOS 7 already ships a
#    openvswitch.ko module with GRE and VXLAN support (kernel 3.10).
#  - Build on Debian requires to install
#
#       sudo apt-get install "linux-headers-$(uname -r)"
#
#    OVS has checks to determine if the vxlan module has required features
#    available.  If all rquired features are in the module then only OVS
#    uses it.
#
#    Search for `USE_KERNEL_TUNNEL_API` in the source code.
#
#    - [ovs-discuss] VxLAN kernel module.
#      http://openvswitch.org/pipermail/discuss/2015-March/016947.html
#
#    You may need to upgrade the kernel
#
#    - skb_copy_ubufs() not exported by the Debian Linux kernel 3.2.57-3,
#      https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=746602
#
#  - See INSTALL in openvswtich source tree for details.
#
# On hot upgrade and ovs-ctl
#
#     sudo apt-get install uuid-runtime
#     /usr/local/share/openvswitch/scripts/ovs-ctl force-reload-kmod --system-id=random
#
PKG_NAME=openvswitch
PKG_VERSION=2.5.0
PKG_SOURCE="$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_SOURCE_URL="http://openvswitch.org/releases/$PKG_SOURCE"
PKG_SOURCE_MD5SUM=d86045933aa8f582f1d74ab77f998e44
PKG_AUTOCONF_FIXUP=1
PKG_DEPENDS=openssl
PKG_PLATFORM=linux

. "$PWD/env.sh"

do_patch_include_dpdk() {
	patch -p0 <<"EOF"
--- acinclude.m4.orig	2016-03-03 11:33:33.991889501 +0800
+++ acinclude.m4	2016-03-03 11:33:37.528954440 +0800
@@ -170,14 +170,14 @@ AC_DEFUN([OVS_CHECK_DPDK], [
   if test X"$with_dpdk" != X; then
     RTE_SDK=$with_dpdk
 
-    DPDK_INCLUDE=$RTE_SDK/include
+    DPDK_INCLUDE=$RTE_SDK/include/dpdk
     DPDK_LIB_DIR=$RTE_SDK/lib
     DPDK_LIB="-ldpdk"
     DPDK_EXTRA_LIB=""
     RTE_SDK_FULL=`readlink -f $RTE_SDK`
 
     AC_COMPILE_IFELSE(
-      [AC_LANG_PROGRAM([#include <$RTE_SDK_FULL/include/rte_config.h>
+      [AC_LANG_PROGRAM([#include <$RTE_SDK_FULL/include/dpdk/rte_config.h>
 #if !RTE_LIBRTE_VHOST_USER
 #error
 #endif], [])],
EOF
}

do_patch_dev_get_stats64() {
	patch -p1 <<"EOF"
From: Sabyasachi Sengupta <sabyasachi.sengupta at alcatel-lucent.com>

The build was failing with following error:

----
  CC [M]  /home/sabyasse/Linux/src/sandbox/ovs_v1/datapath/linux/vport.o
/home/sabyasse/Linux/src/sandbox/ovs_v1/datapath/linux/vport.c: In
function ‘ovs_vport_get_stats’:
/home/sabyasse/Linux/src/sandbox/ovs_v1/datapath/linux/vport.c:328:
error: implicit declaration of function ‘dev_get_stats64’
----

The issue is fixed by checking for existence of dev_get_stats64 in
netdevice.h and then using it (in C6.7+, 2.6.32-594 kernels). For
previous kernels use compat rpl_dev_get_stats.
---
This patch was originally submitted at:
	https://github.com/openvswitch/ovs/pull/105
I'm submitting here because I don't think any datapath reviewers
follow github pull requests.

 acinclude.m4                                    | 1 +
 datapath/linux/compat/include/linux/netdevice.h | 6 ++++++
 2 files changed, 7 insertions(+)

diff --git a/acinclude.m4 b/acinclude.m4
index 9d652c2..51cb950 100644
--- a/acinclude.m4
+++ b/acinclude.m4
@@ -375,6 +375,7 @@ AC_DEFUN([OVS_CHECK_LINUX_COMPAT], [
                   [OVS_DEFINE([HAVE_SOCK_CREATE_KERN_NET])])
   OVS_GREP_IFELSE([$KSRC/include/linux/netdevice.h], [dev_disable_lro])
   OVS_GREP_IFELSE([$KSRC/include/linux/netdevice.h], [dev_get_stats])
+  OVS_GREP_IFELSE([$KSRC/include/linux/netdevice.h], [dev_get_stats64])
   OVS_GREP_IFELSE([$KSRC/include/linux/netdevice.h], [dev_get_by_index_rcu])
   OVS_GREP_IFELSE([$KSRC/include/linux/netdevice.h], [dev_recursion_level])
   OVS_GREP_IFELSE([$KSRC/include/linux/netdevice.h], [__skb_gso_segment])
diff --git a/datapath/linux/compat/include/linux/netdevice.h b/datapath/linux/compat/include/linux/netdevice.h
index 19a7b8e..6143343 100644
--- a/datapath/linux/compat/include/linux/netdevice.h
+++ b/datapath/linux/compat/include/linux/netdevice.h
@@ -268,7 +268,13 @@ struct rtnl_link_stats64 *rpl_dev_get_stats(struct net_device *dev,
 
 #if RHEL_RELEASE_CODE < RHEL_RELEASE_VERSION(7,0)
 /* Only required on RHEL 6. */
+#ifdef HAVE_DEV_GET_STATS64
 #define dev_get_stats dev_get_stats64
+#else
+#define dev_get_stats rpl_dev_get_stats
+struct rtnl_link_stats64 *rpl_dev_get_stats(struct net_device *dev,
+					struct rtnl_link_stats64 *storage);
+#endif
 #endif
 
 #ifndef netdev_dbg
-- 
2.1.3
EOF
}

do_patch() {
	cd "$PKG_SOURCE_DIR"
	do_patch_dev_get_stats64
	do_patch_include_dpdk
}

# build only userspace tools by default
#
# the Linux kernel versions against which the given versions of the Open
# vSwitch kernel module will successfully build.
#
#    1.11.x        2.6.18 to 3.8
#    2.3.x         2.6.32 to 3.14
#    2.4.x         2.6.32 to 4.0
#    2.5.x         2.6.32 to 4.3
#
# the datapath supported features from an Open vSwitch user's perspective
#
#    Feature                    Linux upstream    Linux OVS tree
#    Connection tracking        4.3               3.10
#    Tunnel - VXLAN             3.12              YES
#
# - What Linux kernel versions does each Open vSwitch release work with?
#   https://github.com/openvswitch/ovs/blob/master/FAQ.md#q-what-linux-kernel-versions-does-each-open-vswitch-release-work-with
# - Are all features available with all datapaths?
#	https://github.com/openvswitch/ovs/blob/master/FAQ.md#q-are-all-features-available-with-all-datapaths

openvswitch_with_kmod="/lib/modules/$(uname -r)/build"
openvswitch_with_dpdk="$INSTALL_PREFIX/dpdk/dpdk-2.2.0-x86_64-native-linuxapp-gcc"

CONFIGURE_ARGS="$CONFIGURE_ARGS		\\
	--enable-shared					\\
	--enable-ndebug					\\
"

if [ -n "$openvswitch_with_kmod" ]; then
	# --with-linux, the Linux kernel build directory
	# --with-linux-source, the Linux kernel source directory
	CONFIGURE_ARGS="$CONFIGURE_ARGS				\\
		--with-linux="$openvswitch_with_kmod"	\\
	"
fi

if [ -n "$openvswitch_with_dpdk" ]; then
	# --with-dpdk, the DPDK build directory
	CONFIGURE_ARGS="$CONFIGURE_ARGS				\\
		--with-dpdk="$openvswitch_with_dpdk"	\\
	"
	PKG_DEPENDS="$PKG_DEPENDS dpdk"
fi

# kernel modules has to be installed with make modules_install.  We may need to
# reword install() in env.sh to `cpdir $PKG_STAGING_DIR /`
