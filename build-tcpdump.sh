#!/bin/sh -e

PKG_NAME=tcpdump
PKG_VERSION=4.7.4
PKG_SOURCE="$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_SOURCE_URL="http://www.tcpdump.org/release/$PKG_SOURCE"
PKG_SOURCE_MD5SUM=58af728de36f499341918fc4b8e827c3
PKG_DEPENDS='libnl3 libpcap openssl'

. "$PWD/env.sh"