
# Bug real corregido 2026-08-30: confirmado con el repo OFICIAL de KreitinnSoftware
# (MiceWine-RootFS-Generator) que nunca paso de box64-0.3.9 -- las versiones 0.4.x
# se agregaron en una ronda anterior de este proyecto sin verificar el mecanismo real
# de instalacion de box64 para Android/CMake. Confirmado: el Makefile generado por
# CMake para este commit no trae target "install" real (0 reglas install() se disparan
# ni con "cmake --install . -v"), aunque box64-0.4.2 (version anterior, ya funcionaba
# con make install normal) SI las tenia -- cambio real de como box64 empaqueta su
# build para Android en commits mas nuevos, no un bug de MiceWine-Packages.
#
# Fix real: copiar el binario "box64" ya compilado (confirmado que build_dir/box64
# existe tras "make") directo al layout que box64-0.4.2 ya usa (bin/box64 +
# etc/box64.box64rc), sin depender del mecanismo install() de CMake que no dispara
# nada util para esta version.
# Chequeo agregado 2026-08-30 (gap real confirmado contra Box64all-standalone-nightly.yml
# linea 136, variant Bionic): el binario debe linkear contra libc.so real de Android, no
# la libc del host de build -- sin esto, un binario mal linkeado se empaquetaria en
# silencio en vez de fallar ruidoso ahora mismo.
readelf -d box64 | grep -q "NEEDED.*libc.so" || { echo "E: box64 no linkeo contra libc.so de Android -- build mal armado."; exit 1; }

mkdir -p "$DESTDIR$PREFIX/bin" "$DESTDIR$PREFIX/etc"
cp box64 "$DESTDIR$PREFIX/bin/box64"
chmod +x "$DESTDIR$PREFIX/bin/box64"
touch "$DESTDIR$PREFIX/etc/box64.box64rc"
