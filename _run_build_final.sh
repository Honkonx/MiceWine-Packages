#!/bin/bash
cd /mnt/c/Users/honkon/Desktop/micewine/MiceWine-Packages || exit 1
rm -f build-aarch64-wine920.log
setsid nohup ./build-all.sh aarch64 > build-aarch64-wine920.log 2>&1 < /dev/null &
disown
echo "LAUNCHED_PID=$!"
