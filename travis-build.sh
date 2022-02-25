#!/bin/bash

set -x

### Install Build Tools #1

DEBIAN_FRONTEND=noninteractive apt -qq update
DEBIAN_FRONTEND=noninteractive apt -qq -yy install --no-install-recommends \
	appstream \
	automake \
	autotools-dev \
	build-essential \
	checkinstall \
	cmake \
	curl \
	devscripts \
	equivs \
	extra-cmake-modules \
	gettext \
	git \
	gnupg2 \
	lintian \
	wget

### Add Neon Sources

wget -qO /etc/apt/sources.list.d/neon-user-repo.list https://raw.githubusercontent.com/Nitrux/iso-tool/development/configs/files/sources.list.neon.user

DEBIAN_FRONTEND=noninteractive apt-key adv --keyserver keyserver.ubuntu.com --recv-keys \
	55751E5D > /dev/null

curl -L https://packagecloud.io/nitrux/testing/gpgkey | apt-key add -;

wget -qO /etc/apt/sources.list.d/nitrux-testing-repo.list https://raw.githubusercontent.com/Nitrux/iso-tool/development/configs/files/sources.list.nitrux.testing

DEBIAN_FRONTEND=noninteractive apt -qq update

### Install Package Build Dependencies #2
### Clip needs ECM > 5.70

DEBIAN_FRONTEND=noninteractive apt -qq -yy install --no-install-recommends \
	ffmpeg \
	libavcodec-dev \
	libavdevice-dev \
	libavfilter-dev \
	libavformat-dev \
	libavutil-dev \
	libkf5config-dev \
	libkf5coreaddons-dev \
	libkf5i18n-dev \
	libkf5kio-dev \
	libkf5notifications-dev \
	libkf5service-dev \
	libmpv-dev \
	libpostproc-dev \
	libqt5svg5-dev \
	libswscale-dev \
	taglib \
	mauikit-git \
	mauikit-filebrowsing-git \
	qtbase5-dev \
	qtdeclarative5-dev \
	qtmultimedia5-dev \
	qtquickcontrols2-5-dev

DEBIAN_FRONTEND=noninteractive apt -qq -yy install --only-upgrade \
	extra-cmake-modules

### Clone repo.

git clone --single-branch --branch v2.1 https://invent.kde.org/maui/clip.git

rm -rf clip/{android_files,macos_files,windows_files,examples,LICENSES,README.md}

### Compile Source

mkdir -p clip/build && cd clip/build

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
	-DCMAKE_INSTALL_LIBDIR=lib/x86_64-linux-gnu ..

make

### Run checkinstall and Build Debian Package
### DO NOT USE debuild, screw it

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
	--pkgversion=2.1.1+git+2 \
	--pkgarch=amd64 \
	--pkgrelease="1" \
	--pkglicense=LGPL-3 \
	--pkggroup=utils \
	--pkgsource=clip \
	--pakdir=../.. \
	--maintainer=uri_herrera@nxos.org \
	--provides=clip \
	--requires="ffmpeg,libavcodec58,libavdevice58,libavfilter7,libavformat58,libavutil56,libc6,libgcc-s1,libkf5coreaddons5,libkf5i18n5,libmpv1,libpostproc55,libqt5core5a,libqt5gui5,libqt5multimedia5,libqt5qml5,libqt5quick5,libqt5widgets5,libstdc++6,libswscale5,taglib \(\>= 1.12.0\),mauikit-git \(\>= 2.1.1+git+1\),mauikit-filebrowsing-git \(\>= 2.1.1+git+1\),qml-module-qt-labs-platform" \
	--nodoc \
	--strip=no \
	--stripso=yes \
	--reset-uids=yes \
	--deldesc=yes
