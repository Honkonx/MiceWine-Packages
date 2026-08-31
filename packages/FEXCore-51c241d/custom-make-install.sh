# Reemplaza el "make install" default de setupPackage() (build-all.sh) porque hacen
# falta 2 compilaciones cruzadas distintas para los 2 DLLs que este paquete necesita
# -- ver la explicacion completa en build.sh. Ninguna parte de esto se ejecuto de
# verdad en esta tarea (pedido explicito: dejar listo para un build coordinado
# posterior, no lanzarlo ahora) -- es un dry-run/plumbing documentado, no build
# verificado. set -e para fallar ruidosamente ante cualquier paso que no de el
# archivo esperado, en vez de generar un .rat "exitoso" pero vacio (mismo bug real
# ya documentado en packages/proton-wine-10.0/build.sh para
# --disable-amd_ags_x64 / el header de esync -- ninguno de los 2 build.sh generados
# por setupPackage() tiene "set -e" propio, asi que hay que ponerlo nosotros).
set -e

# 1) Build primario (ARM64EC, MINGW_TRIPLE=arm64ec-w64-mingw32) -- el "cmake .. &&
#    make -j N" ya corrio antes de este script (parte del build.sh generado por
#    setupPackage()), cwd = build_dir. Solo falta el "make install" (DESTDIR ya
#    viene exportado por el propio build.sh generado, ver build-all.sh setupPackage()
#    linea "echo \"export DESTDIR=...\" >> build.sh").
make -j $(nproc) install

ARM64ECFEX_DLL="$(find "$DESTDIR" -name 'libarm64ecfex.dll' -print -quit)"

if [ -z "$ARM64ECFEX_DLL" ]; then
	echo "E: 'make install' no genero libarm64ecfex.dll -- revisar que ARCHITECTURE_arm64ec se haya activado de verdad (CMAKE_SYSTEM_PROCESSOR debe terminar siendo 'arm64ec-w64-mingw32', ver Data/CMake/toolchain_mingw.cmake) y que arm64ec-w64-mingw32-clang exista en cache/llvm-mingw/bin (agregado a build-all.sh 2026-08-26 para wine-10.1-arm64ec-firetest -- confirmar que el release cacheado sigue soportando este triple exacto)."
	exit 1
fi

mkdir -p $DESTDIR/$APP_ROOT_DIR/files/x64
cp "$ARM64ECFEX_DLL" $DESTDIR/$APP_ROOT_DIR/files/x64/libarm64ecfex.dll

# 2) Segundo arbol de build independiente para el target WOW64 (libwow64fex.dll,
#    MINGW_TRIPLE=aarch64-w64-mingw32) -- ver la explicacion de por que hacen falta
#    2 builds separados en build.sh. Se configura desde cero en un build_dir
#    hermano (no se reusa el build_dir del build ARM64EC: CMAKE_SYSTEM_PROCESSOR
#    no se puede cambiar en una cache de CMake ya configurada).
WOW64FEX_BUILD_DIR="$PWD/../build_dir_wow64fex"
mkdir -p "$WOW64FEX_BUILD_DIR"

(
	cd "$WOW64FEX_BUILD_DIR"

	cmake -DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_INSTALL_LIBDIR=$PREFIX/lib -DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_TOOLCHAIN_FILE=../Data/CMake/toolchain_mingw.cmake \
		-DMINGW_TRIPLE=aarch64-w64-mingw32 \
		-DBUILD_TESTING=OFF -DBUILD_THUNKS=OFF -DBUILD_FEXCONFIG=OFF -DENABLE_LTO=OFF -DENABLE_OFFLINE_TELEMETRY=OFF \
		..

	make -j $(nproc)
	make -j $(nproc) install
)

WOW64FEX_DLL="$(find "$DESTDIR" -name 'libwow64fex.dll' -print -quit)"

if [ -z "$WOW64FEX_DLL" ]; then
	echo "E: 'make install' del segundo build (WOW64, aarch64-w64-mingw32) no genero libwow64fex.dll -- revisar que ARCHITECTURE_arm64ec haya quedado APAGADO en este segundo arbol (si algun cache de CMake se filtro del primer build, podria construir ARM64EC de nuevo en vez de WOW64) y que aarch64-w64-mingw32-clang exista en cache/llvm-mingw/bin."
	exit 1
fi

cp "$WOW64FEX_DLL" $DESTDIR/$APP_ROOT_DIR/files/x64/libwow64fex.dll
