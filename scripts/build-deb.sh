#! /bin/bash

set -x

### Update sources

wget -qO /etc/apt/sources.list.d/nitrux-main-compat-repo.list https://raw.githubusercontent.com/Nitrux/iso-tool/development/configs/files/sources.list.nitrux

wget -qO /etc/apt/sources.list.d/nitrux-testing-repo.list https://raw.githubusercontent.com/Nitrux/iso-tool/development/configs/files/sources.list.nitrux.testing

DEBIAN_FRONTEND=noninteractive apt-key adv --keyserver keyserver.ubuntu.com --recv-keys \
	55751E5D > /dev/null

curl -L https://packagecloud.io/nitrux/repo/gpgkey | apt-key add -;
curl -L https://packagecloud.io/nitrux/compat/gpgkey | apt-key add -;
curl -L https://packagecloud.io/nitrux/testing/gpgkey | apt-key add -;

DEBIAN_FRONTEND=noninteractive apt -qq update

### Install Package Build Dependencies #2

DEBIAN_FRONTEND=noninteractive apt -qq -yy install --no-install-recommends \
	mauikit-git \
	mauikit-filebrowsing-git \
	taglib

### Download Source

git clone --depth 1 --branch $CLIP_BRANCH https://invent.kde.org/maui/clip.git

### Compile Source

mkdir -p build && cd build

cmake \
	-DCMAKE_INSTALL_PREFIX=/usr \
	-DENABLE_BSYMBOLICFUNCTIONS=OFF \
	-DQUICK_COMPILER=ON \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_SYSCONFDIR=/etc \
	-DCMAKE_INSTALL_LOCALSTATEDIR=/var \
	-DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON \
	-DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=ON \
	-DCMAKE_INSTALL_RUNSTATEDIR=/run "-GUnix Makefiles" \
	-DCMAKE_VERBOSE_MAKEFILE=ON \
	-DCMAKE_INSTALL_LIBDIR=lib/x86_64-linux-gnu ../clip/

make -j$(nproc)

### Run checkinstall and Build Debian Package

>> description-pak printf "%s\n" \
	'MauiKit Video Player.' \
	'' \
	'Clip allows you to manage and play videos using MPV as a backend.' \
	'' \
	'Clip works on desktops, Android and Plasma Mobile.' \
	'' \
	''

checkinstall -D -y \
	--install=no \
	--fstrans=yes \
	--pkgname=clip-git \
	--pkgversion=$PACKAGE_VERSION \
	--pkgarch=amd64 \
	--pkgrelease="1" \
	--pkglicense=LGPL-3 \
	--pkggroup=utils \
	--pkgsource=clip \
	--pakdir=. \
	--maintainer=probal31@gmail.com \
	--provides=clip \
	--requires="ffmpeg,libavcodec58,libavdevice58,libavfilter7,libavformat58,libavutil56,libc6,libgcc-s1,libkf5coreaddons5,libkf5i18n5,libmpv1,libpostproc55,libqt5core5a,libqt5gui5,libqt5multimedia5,libqt5qml5,libqt5quick5,libqt5widgets5,libstdc++6,libswscale5,taglib \(\>= 1.12.0\),mauikit-git \(\>= 2.2.0+git\),mauikit-filebrowsing-git \(\>= 2.2.0+git\),qml-module-qt-labs-platform" \
	--nodoc \
	--strip=no \
	--stripso=yes \
	--reset-uids=yes \
	--deldesc=yes
