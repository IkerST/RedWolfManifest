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
	if [ "$nofif" -eq "notify" ]; then
		notify -t "Sync Started"
	elif [ "$notif" -eq "simplepush" ]; then
		simplepush $key "Repo" "Sync Started"
	fi
	repo sync -c -j12 && (
	echo "===================================================="
	echo "===================Sync Finished===================="
	echo "===================================================="
	if [ "$nofif" -eq "notify" ]; then
		notify -t "Sync Finished"
	elif [ "$notif" -eq "simplepush" ]; then
		simplepush $key "Repo" "Sync Finished"
	fi
	) || (
	echo "===================================================="
	echo "====================Sync Error======================"
	echo "===================================================="
	if [ "$nofif" -eq "notify" ]; then
		notify -t "Sync Failed"
	elif [ "$notif" -eq "simplepush" ]; then
		simplepush $key "Repo" "Sync Failed"
	fi
	return 1
	)
}

build_device () {
	device=$1 
	if [ "$nofif" -eq "notify" ]; then
		notify -t "Build Started"
	elif [ "$notif" -eq "simplepush" ]; then
		simplepush $key $device "Build Started"
	fi
	(
	breakfast $device
	make -j$THREADS recoveryimage
	) && (
	echo "===================================================="
	echo "==================Build Finished===================="
	echo "===================================================="
	if [ "$nofif" -eq "notify" ]; then
		notify -t "Build Finished"
	elif [ "$notif" -eq "simplepush" ]; then
		simplepush $key $device "Build Finished"
	fi
	) || (
	echo "===================================================="
	echo "===================Build Error======================"
	echo "===================================================="
	if [ "$nofif" -eq "notify" ]; then
		notify -t "Build Error"
	elif [ "$notif" -eq "simplepush" ]; then
		simplepush $key $device "Build Error"
	fi
	return 1
	)
}

# End functions

# Start script

figlet "RedWolfRecovery"
echo "Syncing RedWolfRecovery Sources (rw_n)"
repo init --depth=1 -u git://github.com/RedWolfRecovery/rw_manifest.git -b rw-n
mkdir .repo/local_manifests/ && cp redwolf.xml .repo/local_manifests/
repo_sync
echo "Starting Build"
build_device harpia
build_device merlin
build_device osprey
build_device surnia
build_device lux

# Finish script
