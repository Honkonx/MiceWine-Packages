#!/bin/bash
customDxvkDownload() {
	if [ -e "DXVK/$1" ]; then
		echo "$1 already downloaded."
	else
		echo "Downloading DXVK-$1..."

		cd "DXVK"

		curl -# -L -O "$3"

		if [ $? != 0 ]; then
			echo "Error on Downloading DXVK-$1."
		else
			mkdir -p "dxvk/files"

			tar -xf "$(basename $3)"

			mv "dxvk"*"/x32" "dxvk"*"/x64" "dxvk/files"

			$INIT_DIR/tools/create-rat-pkg.sh "DXVK" "DXVK" "" "any" "$1-$2" "DXVK" "dxvk" "$INIT_DIR/components/DXVK"

			rm -rf "dxvk"*
		fi

		cd "$OLDPWD"
	fi
}

dxvkDownload() {
	if [ -e "DXVK/DXVK-$1" ]; then
		echo "DXVK-$1 already downloaded."
	else
		echo "Downloading DXVK-$1..."

		cd "DXVK"

		curl -# -L -O "https://github.com/doitsujin/dxvk/releases/download/v$1/dxvk-$1.tar.gz"

		if [ $? != 0 ]; then
			echo "Error on Downloading DXVK-$1."
		else
			mkdir -p "dxvk/files"

			tar -xf "dxvk-$1.tar.gz"

			mv "dxvk"*"/x32" "dxvk"*"/x64" "dxvk/files"

			$INIT_DIR/tools/create-rat-pkg.sh "DXVK" "DXVK" "" "any" "$1" "DXVK" "dxvk" "$INIT_DIR/components/DXVK"

			rm -rf "dxvk"*
		fi

		cd "$OLDPWD"
	fi
}

dxvkAsyncDownload() {
	if [ -e "DXVK/DXVK-$1-async" ]; then
		echo "DXVK-$1-async already downloaded."
	else
		echo "Downloading DXVK-$1-async..."

		cd "DXVK"

		curl -# -L -O "https://github.com/Sporif/dxvk-async/releases/download/$1/dxvk-async-$1.tar.gz"

		if [ $? != 0 ]; then
			echo "Error on Downloading DXVK-$1-async."
		else
			mkdir -p "dxvk/files"

			tar -xf "dxvk-async-$1.tar.gz"

			mv "dxvk"*"/x32" "dxvk"*"/x64" "dxvk/files"

			$INIT_DIR/tools/create-rat-pkg.sh "DXVK" "DXVK" "" "any" "$1-async" "DXVK" "dxvk" "$INIT_DIR/components/DXVK"

			rm -rf "dxvk"*
		fi

		cd "$OLDPWD"
	fi
}

dxvkGplAsyncDownload() {
	if [ -e "DXVK/DXVK-$1-gplasync" ]; then
		echo "DXVK-$1-gplasync already downloaded."
	else
		echo "Downloading DXVK-$1-gplasync..."

		cd "DXVK"

		curl -# -L -O "https://github.com/KreitinnSoftware/dxvk-gplasync/raw/refs/heads/main/dxvk-gplasync-v$1.tar.gz"

		if [ $? != 0 ]; then
			echo "Error on Downloading DXVK-$1-gplasync."
		else
			mkdir -p "dxvk/files"

			tar -xf "dxvk-gplasync-v$1.tar.gz"

			mv "dxvk"*"/x32" "dxvk"*"/x64" "dxvk/files"

			$INIT_DIR/tools/create-rat-pkg.sh "DXVK" "DXVK" "" "any" "$1-gplasync" "DXVK" "dxvk" "$INIT_DIR/components/DXVK"

			rm -rf "dxvk"*
		fi

		cd "$OLDPWD"
	fi
}

wined3dDownload() {
	if [ -e "WineD3D/WineD3D-($1)" ]; then
		echo "WineD3D-$1 already downloaded."
	else
		echo "Downloading WineD3D-$1..."

		cd "WineD3D"

		curl -# -L -O "https://downloads.fdossena.com/Projects/WineD3D/Builds/WineD3DForWindows_$1.zip"
		curl -# -L -O "https://downloads.fdossena.com/Projects/WineD3D/Builds/WineD3DForWindows_$1-x86_64.zip"

		if [ $? != 0 ]; then
			echo "Error on Downloading WineD3D-($1)."
		else
			mkdir -p "wined3d/files/x64"
			mkdir -p "wined3d/files/x32"

			7z x "WineD3D*$1-x86_64.zip" -o"wined3d-x64" -aoa &> /dev/zero
			7z x "WineD3D*$1.zip" -o"wined3d-x32" -aoa &> /dev/zero

			for i in $(find "wined3d-x64" -name "*.dll"); do
				cp -f "$i" "wined3d/files/x64"
			done

			for i in $(find "wined3d-x32" -name "*.dll"); do
				cp -f "$i" "wined3d/files/x32"
			done

			$INIT_DIR/tools/create-rat-pkg.sh "WineD3D" "WineD3D" "" "any" "$1" "WineD3D" "wined3d" "$INIT_DIR/components/WineD3D"

			rm -rf "wined3d"* *".zip"
		fi

		cd "$OLDPWD"
	fi
}

vkd3dDownload() {
	if [ -e "VKD3D/VKD3D-$1" ]; then
		echo "VKD3D-$1 already downloaded."
	else
		cd "VKD3D"

		echo "Downloading VKD3D-$1..."

		curl -# -L -O "https://github.com/HansKristian-Work/vkd3d-proton/releases/download/v$1/vkd3d-proton-$1.tar.zst"

		if [ $? != 0 ]; then
			echo "Error on Downloading VKD3D-$1."
		else
			mkdir -p "vkd3d/files"

			tar -xf "vkd3d-proton-$1.tar.zst"

			mv "vkd3d"*"/x64" "vkd3d/files/"
			mv "vkd3d"*"/x86" "vkd3d/files/x32"

			$INIT_DIR/tools/create-rat-pkg.sh "VKD3D" "VKD3D" "" "any" "$1" "VKD3D" "vkd3d" "$INIT_DIR/components/VKD3D"

			rm -rf "vkd3d"*
		fi

		cd "$OLDPWD"
	fi
}

# FEXCore (arm64ec CPU translation layer for Windows-on-ARM Wine builds).
#
# NOT built from FEX-Emu/FEX source here: FEX-Emu's own GitHub Releases ship
# zero binary assets (confirmed via `curl https://api.github.com/repos/FEX-Emu/FEX/releases/latest`
# -> "assets": []; their real distribution channel is a glibc/Ubuntu PPA, see
# docs/investigacion/wine-arm64ec-fexcore-proton.md section 3.2). The only
# ready-to-use arm64ec-Windows-PE build of FEXCore is published by the
# third-party repo The412Banner/Nightlies (cloned for reference at
# referencia/The412Banner-Nightlies, no LICENSE file present in that repo --
# see docs/investigacion/wine-arm64ec-fexcore-proton.md section "Tarea 1" for
# the caveat this implies). Its CI (.github/workflows/fexcore-standalone-nightly.yml)
# clones FEX-Emu/FEX from source and cross-compiles it with llvm-mingw against
# the arm64ec-w64-mingw32 / aarch64-w64-mingw32 triples -- the output is a
# .wcp (zstd tar) containing two Windows PE DLLs for system32, NOT Android
# .so files:
#   system32/libarm64ecfex.dll  (PE32+, x86-64 -- confirmed with `file`)
#   system32/libwow64fex.dll    (PE32+, ARM64  -- confirmed with `file`)
# This is why it fits the same "download prebuilt PE binaries, repackage as
# .rat" pattern already used for DXVK/WineD3D/VKD3D above, instead of the
# "compile from source with the NDK" pattern used for Box64/Wine.
#
# IMPORTANT CAVEAT (documented, not silently assumed away): these DLLs are
# only useful to an arm64ec Wine build (Windows-on-ARM), which MiceWine does
# not build yet (see docs/investigacion/wine-arm64ec-fexcore-proton.md
# section 4b, "proton-wine-arm64ec" -- not implemented). Installing this .rat
# package today has no effect on a normal x86_64 MiceWine Wine prefix; it is
# infrastructure prepared ahead of that follow-up work, not a usable feature
# yet.
fexCoreDownload() {
	local label="$1"
	local url="$2"

	if [ -e "FEXCore/FEXCore-$label" ]; then
		echo "FEXCore-$label already downloaded."
	else
		echo "Downloading FEXCore-$label..."

		cd "FEXCore"

		curl -# -L -o "FEXCore-$label.wcp" "$url"

		if [ $? != 0 ]; then
			echo "Error on Downloading FEXCore-$label."
		else
			mkdir -p "fexcore/files/x64"

			tar -xf "FEXCore-$label.wcp" -C "fexcore-extracted"  2>/dev/null || {
				mkdir -p "fexcore-extracted"
				tar -xf "FEXCore-$label.wcp" -C "fexcore-extracted"
			}

			# Both DLLs land in the same "x64" slot used by DXVK/VKD3D's 64-bit
			# side: libarm64ecfex.dll is the x86_64-on-arm64ec translator,
			# libwow64fex.dll is the aarch64 WOW64 companion. Neither has a
			# 32-bit (x32) counterpart -- the upstream build only produces
			# these two files (see profile.json inside the .wcp).
			cp -f "fexcore-extracted/system32/"*.dll "fexcore/files/x64/"

			$INIT_DIR/tools/create-rat-pkg.sh "FEXCore" "FEXCore" "" "any" "$label" "FEXCore" "fexcore" "$INIT_DIR/components/FEXCore"

			rm -rf "fexcore" "fexcore-extracted" "FEXCore-$label.wcp"
		fi

		cd "$OLDPWD"
	fi
}

export INIT_DIR="$PWD"

mkdir -p "components"

cd "components"

mkdir -p "DXVK" "WineD3D" "VKD3D" "FEXCore"

export DXVK_GPLASYNC_LIST="3.0-1 2.6-1 2.5.3-1 2.5.2-1 2.5.1-2 2.5-1 2.4.1-1 2.4-1 2.3.1-1 2.3-1 2.2-4 2.1-4"
export DXVK_ASYNC_LIST="2.0 1.10.3 1.10.2 1.10.1 1.10 1.9.4 1.9.3 1.9.2 1.9.1 1.9"
export DXVK_LIST="3.0.2 3.0.1 3.0 2.7.1 2.7 2.6.2 2.6.1 2.6 2.5.3 2.5.2 2.5.1 2.5 2.4.1 2.4 2.3.1 2.3 2.2 2.1 2.0 1.10.3 1.10.2 1.10.1 1.10 1.9.4 1.9.3 1.9.2 1.9.1 1.9 1.8.1 1.8 1.7.3 1.7.2 1.7.1 1.7 1.6.1 1.6 1.5.5 1.5.4 1.5.3 1.5.2 1.5.1 1.5 1.4.6 1.4.5 1.4.4 1.4.3 1.4.2 1.4.1 1.4"
export WINED3D_LIST="11.0 10.20 10.15 10.10 10.4 10.3 10.2 10.1 10.0 10.0-rc3 9.20 9.16 9.3 9.1 9.0 8.15 7.11 3.17"
export VKD3D_LIST="3.0.1 3.0b 3.0a 3.0 2.14.1 2.14 2.13 2.12 2.11.1 2.11 2.10 2.9 2.8"

for i in $DXVK_GPLASYNC_LIST; do
	dxvkGplAsyncDownload "$i"
done

for i in $DXVK_ASYNC_LIST; do
	dxvkAsyncDownload "$i"
done

for i in $DXVK_LIST; do
	dxvkDownload "$i"
done

for i in $WINED3D_LIST; do
	wined3dDownload "$i"
done

for i in $VKD3D_LIST; do
	vkd3dDownload "$i"
done

customDxvkDownload "DXVK-1.10.6-Sarek" "https://github.com/pythonlover02/DXVK-Sarek/releases/download/v1.10.6/dxvk-sarek-v1.10.6.tar.gz"
customDxvkDownload "DXVK-1.10.6-Sarek-ASync" "https://github.com/pythonlover02/DXVK-Sarek/releases/download/v1.10.6/dxvk-sarek-async-v1.10.6.tar.gz"
