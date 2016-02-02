#!/bin/sh -e

PKG_NAME=autoconf
PKG_VERSION=2.69
PKG_SOURCE="$PKG_NAME-$PKG_VERSION.tar.xz"
PKG_SOURCE_URL="http://ftp.gnu.org/gnu/autoconf/$PKG_SOURCE"
PKG_SOURCE_MD5SUM=50f97f4159805e374639a73e2636f22e
PKG_DEPENS=m4

. "$PWD/env.sh"
