#!/bin/sh -e
#
# Copyright 2015-2016 (c) Yousong Zhou
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# Vim on Debian Wheezy 7 has version 7.3.547 (Fetched with command "vim --version")
#
#	sudo apt-get build-dep vim-nox
#	sudo apt-get install gawk liblua5.2-dev libncurses5-dev
#
# Vim on CentOS 7 has version 7.4.160
#
#	sudo yum-builddep vim-enhanced
#	# or use the following method if you are on CentOS 6.5
#	sudo yum install -y lua-devel ruby-devel python-devel ncurses-devel perl-devel perl-ExtUtils-Embed
#
# Delete dl/patches-$VER_ND/MD5SUMS to check for new patches
#
# Patch 1425 of vim 7.4 seems malformed at the moment (2016-09-14) when
# patching csdpmi4b.zip
#
# 7.3 is the release version.
# 547 is the number of applied patches provided by vim.org.
PKG_NAME=vim
PKG_VERSION=8.0
PKG_SOURCE="vim-${PKG_VERSION}.tar.bz2"
PKG_SOURCE_URL="ftp://ftp.vim.org/pub/vim/unix/$PKG_SOURCE"
PKG_SOURCE_MD5SUM=808d2ebdab521e18bc5e0eaede0db867
PKG_SOURCE_UNTAR_FIXUP=1
PKG_DEPENDS='libiconv LuaJIT ncurses python2'

. "$PWD/env.sh"

# version without dot
VER_ND="$(echo $PKG_VERSION | tr -d .)"
PATCH_DIR="$BASE_DL_DIR/vim$VER_ND-patches"
# vim-8.0.tar.bz2 at the moment already has patch 0001 and 0002 applied
VIM_NEXT_PATCH=3

patches_all_fetched() {
	if [ -s "MD5SUMS" ] && md5sum --status -c MD5SUMS; then
		return 0
	else
		return 1
	fi
}

fetch_patches() {
	local ver="$PKG_VERSION"
	local baseurl="ftp://ftp.vim.org/pub/vim/patches/$PKG_VERSION"
	local num_patches
	local num_process
	local i l

	mkdir -p "$PATCH_DIR"
	cd "$PATCH_DIR"

	if patches_all_fetched; then
		__errmsg "All fetched, skip fetching patches"
		return 0
	fi

	# delete MD5SUMS to check for new patches
	wget -c "$baseurl/MD5SUMS"
	num_patches="$(wc -l MD5SUMS | cut -f1 -d' ')"
	num_process="$(($num_patches / 100))"
	for i in $(seq 1 100 $num_patches); do
		# Each wget fetches at most 100 patches.
		sed -n "$i,$(($i+99))p" MD5SUMS | \
			while read l; do echo "$l" | md5sum --status -c || echo "$baseurl/${l##* }"; done | \
			wget --no-verbose -c -i - &
	done
	wait

	if ! patches_all_fetched; then
		__errmsg "Some patches were missing"
		return 1
	fi
}

apply_patches() {
	local f

	cd "$PKG_BUILD_DIR"

	if [ -f ".patched" ]; then
		__errmsg "$PKG_BUILD_DIR/.patched exists, skip patching."
		return 0
	fi

	for f in $(ls "$PATCH_DIR/$PKG_VERSION."* | sort --version-sort | tail -n "+$VIM_NEXT_PATCH"); do
		__errmsg "applying patch $f"
		patch -p0 -i "$f"
		__errmsg
	done
	touch .patched
}

do_patch() {
	fetch_patches
	apply_patches

	# Include those from INSTALL_PREFIX first
	patch -p0 <<"EOF"
--- src/Makefile.orig	2016-09-18 16:06:43.122195344 +0800
+++ src/Makefile	2016-09-18 17:20:17.143576880 +0800
@@ -1858,7 +1858,7 @@ myself:
 
 
 # The normal command to compile a .c file to its .o file.
-CCC = $(CC) -c -I$(srcdir) $(ALL_CFLAGS)
+CCC = $(CC) -c -I$(srcdir) $(1) $(ALL_CFLAGS)
 
 
 # Link the target for normal use or debugging.
@@ -2971,36 +2971,36 @@ objects/if_xcmdsrv.o: if_xcmdsrv.c
 	$(CCC) -o $@ if_xcmdsrv.c
 
 objects/if_lua.o: if_lua.c
-	$(CCC) $(LUA_CFLAGS) -o $@ if_lua.c
+	$(call CCC,$(LUA_CFLAGS)) -o $@ if_lua.c
 
 objects/if_mzsch.o: if_mzsch.c $(MZSCHEME_EXTRA)
-	$(CCC) -o $@ $(MZSCHEME_CFLAGS_EXTRA) if_mzsch.c
+	$(call CCC,$(MZSCHEME_CFLAGS_EXTRA)) -o $@ if_mzsch.c
 
 mzscheme_base.c:
 	$(MZSCHEME_MZC) --c-mods mzscheme_base.c ++lib scheme/base
 
 objects/if_perl.o: auto/if_perl.c
-	$(CCC) $(PERL_CFLAGS) -o $@ auto/if_perl.c
+	$(call CCC,$(PERL_CFLAGS)) -o $@ auto/if_perl.c
 
 objects/if_perlsfio.o: if_perlsfio.c
-	$(CCC) $(PERL_CFLAGS) -o $@ if_perlsfio.c
+	$(call CCC,$(PERL_CFLAGS)) -o $@ if_perlsfio.c
 
 objects/py_getpath.o: $(PYTHON_CONFDIR)/getpath.c
-	$(CCC) $(PYTHON_CFLAGS) -o $@ $(PYTHON_CONFDIR)/getpath.c \
+	$(call CCC,$(PYTHON_CFLAGS)) -o $@ $(PYTHON_CONFDIR)/getpath.c \
 		-I$(PYTHON_CONFDIR) -DHAVE_CONFIG_H -DNO_MAIN \
 		$(PYTHON_GETPATH_CFLAGS)
 
 objects/if_python.o: if_python.c if_py_both.h
-	$(CCC) $(PYTHON_CFLAGS) $(PYTHON_CFLAGS_EXTRA) -o $@ if_python.c
+	$(call CCC,$(PYTHON_CFLAGS)) $(PYTHON_CFLAGS_EXTRA) -o $@ if_python.c
 
 objects/if_python3.o: if_python3.c if_py_both.h
-	$(CCC) $(PYTHON3_CFLAGS) $(PYTHON3_CFLAGS_EXTRA) -o $@ if_python3.c
+	$(call CCC,$(PYTHON3_CFLAGS)) $(PYTHON3_CFLAGS_EXTRA) -o $@ if_python3.c
 
 objects/if_ruby.o: if_ruby.c
-	$(CCC) $(RUBY_CFLAGS) -o $@ if_ruby.c
+	$(call CCC,$(RUBY_CFLAGS)) -o $@ if_ruby.c
 
 objects/if_tcl.o: if_tcl.c
-	$(CCC) $(TCL_CFLAGS) -o $@ if_tcl.c
+	$(call CCC,$(TCL_CFLAGS)) -o $@ if_tcl.c
 
 objects/integration.o: integration.c
 	$(CCC) -o $@ integration.c
EOF
}

# +profile feature is only available through HUGE features set.  It cannot
# enabled standalone through configure options
CONFIGURE_ARGS="$CONFIGURE_ARGS	\\
	--enable-fail-if-missing	\\
	--enable-luainterp			\\
	--enable-perlinterp			\\
	--enable-pythoninterp		\\
	--enable-rubyinterp			\\
	--enable-cscope				\\
	--enable-multibyte			\\
	--disable-gui				\\
	--disable-gtktest			\\
	--disable-xim				\\
	--without-x					\\
	--disable-netbeans			\\
	--with-luajit				\\
	--with-lua-prefix='$INSTALL_PREFIX'	\\
	--with-tlib=ncurses			\\
	--with-features=big			\\
"

configure_pre() {
	cd "$PKG_SOURCE_DIR/src"
	$MAKEJ autoconf
}
