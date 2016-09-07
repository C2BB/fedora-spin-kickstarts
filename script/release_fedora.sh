#!/bin/bash

set -e
set -x

SCRIPT_PATH="$(dirname $(readlink -f "$0"))"
TOOL_PATH="$(dirname $SCRIPT_PATH)"
TOP_DIR=${TOOL_PATH}/../

TARGET_DIR=
TARGET_PACKAGE=
SKIP_FEDORA_BUILD=
SKIP_CLEAN=
KICKSTART_DIR=$TOP_DIR/spin-kickstarts
KICKSTART_FILE=$KICKSTART_DIR/fedora-arm-artik.ks
FEDORA_PACKAGE_FILE=$TOOL_PATH/configs/artik_fedora.package

print_usage()
{
	echo "-h/--help         Show help options"
	echo "-o		Target directory"
	echo "-b		Target board. artik5 | artik10 | artik710 | artik530"
	echo "-r		Prebuilt rpm directory"
	echo "--skip-build	Skip package build"
	echo "--skip-clean	Skip local repository clean-up"
	exit 0
}

parse_options()
{
	for opt in "$@"
	do
		case "$opt" in
			-h|--help)
				print_usage
				shift ;;
			-o)
				TARGET_DIR=`readlink -e "$2"`
				shift ;;
			-p)
				TARGET_PACKAGE=`readlink -e "$2"`
				shift ;;
			-b)
				TARGET_BOARD="$2"
				shift ;;
			-r)
				FEDORA_PREBUILT_RPM_DIR=`readlink -e "$2"`
				shift ;;
			--skip-build)
				SKIP_CLEAN=--skip-clean
				shift ;;
			--skip-clean)
				SKIP_FEDORA_BUILD=--skip-build
				shift ;;
			-v|--fullver)
				BUILD_VERSION="$2"
				shift ;;
			-d|--date)
				BUILD_DATE="$2"
				shift ;;
			*)
				shift ;;
		esac
	done
}

package_check()
{
	command -v $1 >/dev/null 2>&1 || { echo >&2 "${1} not installed. Aborting."; exit 1; }
}

build_package()
{
	local pkg=$1

	pushd $TOP_DIR/$pkg
	echo "Build $pkg.."
	fed-artik-build
	popd
}

package_check fed-artik-creator

parse_options "$@"

if [ "$BUILD_DATE" == "" ]; then
	BUILD_DATE=`date +"%Y%m%d.%H%M%S"`
fi

if [ "$BUILD_VERSION" == "" ]; then
	BUILD_VERSION=UNRELEASED
fi

FEDORA_TARGET_BOARD=$TARGET_BOARD

FEDORA_NAME=fedora-arm-$FEDORA_TARGET_BOARD-rootfs-$BUILD_VERSION-$BUILD_DATE
if [ "$FEDORA_PREBUILT_RPM_DIR" != "" ]; then
	PREBUILD_ADD_CMD="-r $FEDORA_PREBUILT_RPM_DIR"
fi
$SCRIPT_PATH/build_fedora.sh -o $TARGET_DIR -b $FEDORA_TARGET_BOARD \
	-p $FEDORA_PACKAGE_FILE -n $FEDORA_NAME $SKIP_CLEAN $SKIP_FEDORA_BUILD \
	-k fedora-arm-${FEDORA_TARGET_BOARD}.ks \
	$PREBUILD_ADD_CMD

MD5_SUM=$(md5sum $TARGET_DIR/${FEDORA_NAME}.tar.gz | awk '{print $1}')
FEDORA_TARBALL=${FEDORA_NAME}-${MD5_SUM}.tar.gz
mv $TARGET_DIR/${FEDORA_NAME}.tar.gz $TARGET_DIR/$FEDORA_TARBALL

echo "A new fedora image has been created"
