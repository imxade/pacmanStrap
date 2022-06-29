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
# don't redownload the packages
cd "var/cache/pacman/pkg" || exit 1
ARCH="(i686|x86_64|any)"
URL="https://mirrors.tuna.tsinghua.edu.cn/artixlinux/system/os/x86_64"
curl -L "$URL" > "repo_content" || exit 1
PACKAGES="acl artix-mirrorlist bash brotli bzip2 ca-certificates ca-certificates-mozilla ca-certificates-utils coreutils curl e2fsprogs expat filesystem findutils glibc gpgme keyutils krb5 libarchive libassuan libffi libgpg-error libidn2 libnghttp2 libp11-kit libpsl libssh2 libtasn1 libunistring lz4 ncurses openssl p11-kit pacman readline xz zlib zstd"
# fetch & unpack packages
for PKG in $PACKAGES
do
	REGEX=">$PKG-[0-9].*-$ARCH.*(gz|xz|zst)<"
	FILTER="$(awk -v REGEX="$REGEX" '{match($0,REGEX,m); printf substr(m[0],2,length(m[0])-2)" "}' "repo_content" | awk '{printf $NF}')" &&
	curl -LO --progress-bar "$URL/$FILTER" &&
	TAR="tar -C $DIR --force-local -xf $PKG*"
	eval "$TAR" --zstd ||
	eval "$TAR" --gzip ||
	eval "$TAR" --xz   || exit 1
done
# DNS
printf 'nameserver 9.9.9.9' > "$DIR/etc/resolv.conf"
# Disabling signature checking for now
cp "$DIR/etc/pacman.conf" .
awk '{gsub ("^[[:space:]]*SigLevel.*$", "SigLevel = Never", $0); gsub ("^[[:space:]]*CheckSpace.*$", "#CheckSpace", $0);}1' "pacman.conf" > "$DIR/etc/pacman.conf" 
