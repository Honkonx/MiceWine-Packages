
# Bug real corregido 2026-08-30: mismo bug que box64-0.4.5-1 (mismo commit exacto de
# ptitSeb/box64) -- el CMakeLists.txt no genera target "install" real para este commit
# ("make: *** No rule to make target 'install'. Stop."), aunque el build en si termina
# 100% completo (confirmado: "[100%] Built target box64" en el log real). El binario
# "wowbox64.dll" real lo produce el ExternalProject_Add anidado en
# build/wowbox64-prefix/src/wowbox64-build/ (mismo layout confirmado contra el workflow
# oficial real de The412Banner/Nightlies, Box64all-standalone-nightly.yml linea 165).
# Ruta destino real confirmada extrayendo el .rat viejo que YA funcionaba
# (built-pkgs/WOWBox64/WOWBox64-0.3.6-aarch64.rat, tar -tf real): "files/x64/wowbox64.dll"
# -- NO "wine/system32" como se asumio primero sin verificar.
DLL=$(find . -maxdepth 6 -iname "wowbox64.dll" | head -n 1)
if [ -z "$DLL" ]; then
	echo "E: no se encontro wowbox64.dll compilado -- build.sh de WOWBox64 mal armado."
	exit 1
fi

mkdir -p "$DESTDIR$PREFIX/../x64"
cp "$DLL" "$DESTDIR$PREFIX/../x64/wowbox64.dll"
