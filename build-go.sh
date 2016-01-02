#!/bin/sh -e
#
# Building go1.5 and newer versions requires go1.4 to bootstrap
#
PKG_NAME=go
PKG_VERSION=1.5.2
PKG_SOURCE="$PKG_NAME$PKG_VERSION.src.tar.gz"
PKG_SOURCE_URL="https://storage.googleapis.com/golang/go1.5.2.src.tar.gz"
PKG_SOURCE_MD5SUM=38fed22e7b80672291e7cba7fb9c3475

. "$PWD/env.sh"
. "$PWD/utils-go.sh"

GOROOT_BOOTSTRAP="$INSTALL_PREFIX/go/goroot-1.4.3"