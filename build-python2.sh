#!/bin/sh -e
#
# Copyright 2015-2016 (c) Yousong Zhou
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
PKG_NAME=python2
PKG_VERSION=2.7.10
PKG_SOURCE="Python-${PKG_VERSION}.tar.xz"
PKG_SOURCE_URL="https://www.python.org/ftp/python/$PKG_VERSION/$PKG_SOURCE"
PKG_SOURCE_MD5SUM=c685ef0b8e9f27b5e3db5db12b268ac6
PKG_DEPENDS='bzip2 db openssl ncurses readline sqlite zlib'

. "$PWD/env.sh"

do_patch() {
	if ! os_is_darwin; then
		return 0
	fi

	cd "$PKG_SOURCE_DIR"

	# for building pyexpat module
	# taken from: https://github.com/LibreOffice/core/blob/master/external/python3/python-3.3.5-pyexpat-symbols.patch.1
	patch -p0 <<"EOF"
HACK: Fix build breakage on MacOS:

*** WARNING: renaming "pyexpat" since importing it failed: dlopen(build/lib.macosx-10.6-i386-3.3/pyexpat.so, 2): Symbol not found: _XML_ErrorString

This reverts c242a8f30806 from the python hg repo:

restore namespacing of pyexpat symbols (closes #19186)


See http://bugs.python.org/issue19186#msg214069

The recommendation to include Modules/inc at first broke the Linux build...

So do it this way, as it was before. Needs some realignment later.

--- Modules/expat/expat_external.h
+++ Modules/expat/expat_external.h
@@ -7,10 +7,6 @@

 /* External API definitions */

-/* Namespace external symbols to allow multiple libexpat version to
-   co-exist. */
-#include "pyexpatns.h"
-
 #if defined(_MSC_EXTENSIONS) && !defined(__BEOS__) && !defined(__CYGWIN__)
 #define XML_USE_MSC_EXTENSIONS 1
 #endif
EOF
}

CONFIGURE_ARGS="$CONFIGURE_ARGS		\\
	--enable-unicode=ucs4			\\
	--with-ensurepip=upgrade		\\
"
