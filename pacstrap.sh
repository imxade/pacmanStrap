#!/bin/sh

# SPDX-FileCopyrightText: 2022 XADE <xad3play@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later

# usage: sh pacstrap.sh <directory>
# requirements: sh curl gawk tar gzip xz zstd

# check requirements
type sh curl awk tar gzip xz zstd || exit 1
mkdir -p "$1/var/cache/pacman/pkg"
cd "$1" || exit 1
DIR="$(pwd)"
TMP="$DIR/tmp"
# don't redownload the packages
cd "var/cache/pacman/pkg" || exit 1
ARCH="(i686|x86_64|any)"
URL=${2:-https://mirrors.tuna.tsinghua.edu.cn/artixlinux/system/os/x86_64}
curl -L "$URL" >"repo_content" || exit 1
PACKAGES="[a-z].*-mirrorlist acl bash brotli bzip2 ca-certificates ca-certificates-mozilla ca-certificates-utils coreutils curl e2fsprogs expat filesystem findutils glibc gcc-libs gpgme keyutils krb5 libarchive libassuan libffi libgpg-error libidn2 libnghttp2 libnghttp3 libp11-kit libpsl libssh2 libtasn1 libunistring libxml2 lz4 ncurses openssl p11-kit pacman readline xz zlib zstd icu"
# unpack
EXTRACT() {
  for COMPRESSION in --zstd --gzip --xz; do
    tar -C "$DIR" --force-local -xf "$1" "$COMPRESSION" && break
  done
}
# substitute string of a file in rootfs
SUB() {
  FILE="${TMP}${1##*/}"
  awk '{gsub("'"$2"'", "'"$3"'", $0);}1' "${DIR}$1" >|"${FILE}"
  cp "${FILE}" "${DIR}$1"
  # usage: SUB <path/to/file> <string> <new_string>
}
# filter url
FILTER() {
    awk -v REGEX="$1" '{match($0,REGEX,m); printf substr(m[0],2,length(m[0])-2)" "}' "repo_content" | awk '{printf $NF}'
}
# fetch & unpack packages
for PKG in $PACKAGES; do
  REGEX=">$PKG-[0-9].*-$ARCH.*(gz|xz|zst)<"
  PKGVER=$(FILTER "$REGEX")
  printf '%s\n' "$PKGVER"
  curl -LOC - --progress-bar "$URL/$PKGVER"
  EXTRACT "$PKGVER" || exit 1
done
# DNS
printf 'nameserver 9.9.9.9' >"$DIR/etc/resolv.conf"
# Replace Patterns
for PATTERN in "/etc/pacman.conf ^.*CheckSpace #CheckSpace" "/etc/pacman.conf Required.*DatabaseOptional Never" "/etc/pacman.d/mirrorlist ^#Server Server"; do
  SUB $PATTERN
done
