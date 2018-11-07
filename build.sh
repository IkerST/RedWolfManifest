#!/usr/bin/env bash

# Set variables

CORES=$( nproc --all)
THREADS=$( echo $CORES + $CORES | bc )

# Finish setting variables

# Define functions

simplepush () {
	curl 'https://api.simplepush.io/send/'$1'/'$2'/'$3
}

repo_sync () {
	if [ "$nofif" == "notify" ]; then
		notify -t "Sync Started"
	elif [ "$notif" == "simplepush" ]; then
		simplepush $key "Repo" "Sync Started"
	fi
	repo sync -c -j12 -q && (
	echo "===================================================="
	echo "===================Sync Finished===================="
	echo "===================================================="
	if [ "$nofif" == "notify" ]; then
		notify -t "Sync Finished"
	elif [ "$notif" == "simplepush" ]; then
		simplepush $key "Repo" "Sync Finished"
	fi
	) || (
	echo "===================================================="
	echo "====================Sync Error======================"
	echo "===================================================="
	if [ "$nofif" == "notify" ]; then
		notify -t "Sync Failed"
	elif [ "$notif" == "simplepush" ]; then
		simplepush $key "Repo" "Sync Failed"
	fi
	return 1
	)
}

build_device () {
	device=$1 
	if [ "$nofif" == "notify" ]; then
		notify -t "Build Started"
	elif [ "$notif" == "simplepush" ]; then
		simplepush $key $device "Build Started"
	fi
	(
	breakfast $device && \
	make -j$THREADS recoveryimage
	) && (
	echo "===================================================="
	echo "==================Build Finished===================="
	echo "===================================================="
	if [ "$nofif" == "notify" ]; then
		notify -t "Build Finished"
	elif [ "$notif" == "simplepush" ]; then
		simplepush $key $device "Build Finished"
	fi
	) || (
	echo "===================================================="
	echo "===================Build Error======================"
	echo "===================================================="
	if [ "$nofif" == "notify" ]; then
		notify -t "Build Error"
	elif [ "$notif" == "simplepush" ]; then
		simplepush $key $device "Build Error"
	fi
	return 1
	)
}

install_repo () {
	mkdir ~/bin
	curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
	chmod a+x ~/bin/repo
	alias repo="~/bin/repo"
}

error () { 
	return 1
}


toolchain_install () {
	wget https://releases.linaro.org/components/toolchain/binaries/latest-7/arm-eabi/gcc-linaro-7.3.1-2018.05-x86_64_arm-eabi.tar.xz
	tar xvf gcc-linaro-7.3.1-2018.05-x86_64_arm-eabi.tar.xz
	export CROSS_COMPILE=$(pwd)/gcc-linaro-7.3.1-2018.05-x86_64_arm-linux-gnueabihf/bin/arm-eabi- 
}
# End functions

# Start script
(
install_repo && \
figlet "Red Wolf Recovery" && \
echo "Syncing RedWolfRecovery Sources (rw_n)" && \
tar xvf repo.tar && \
# repo init --depth=1 -u git://github.com/RedWolfRecovery/rw_manifest.git -b rw-n && \
mkdir .repo/local_manifests/ && cp redwolf.xml .repo/local_manifests/ && \
repo_sync && \
echo "Starting Build" && \
toolchain_install && \
source build/envsetup.sh && \
build_device harpia && \
build_device merlin && \
build_device osprey && \
build_device surnia && \
build_device lux && \
tree out/target/product/
) || ( error )

# Finish script
