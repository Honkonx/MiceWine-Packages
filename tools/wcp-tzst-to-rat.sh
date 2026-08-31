#!/bin/bash
# wcp-tzst-to-rat.sh
#
# Convierte un paquete .wcp (Winlator, tar+xz) o .tzst (Winlator/forks, tar+zstd)
# "pelado" (sin profile.json, árbol de directorios crudo) a un .rat válido para
# RatPackageManager de MiceWine.
#
# Contexto / evidencia (ver docs/investigacion/formatos-wcp-tzst-a-rat.md y
# docs/investigacion/wine-arm-fexcore-dxvk-arm-plan-2026-08-19.md):
#   - .wcp  = tar comprimido con xz (o a veces zstd, Winlator acepta ambos).
#   - .tzst = tar comprimido con zstd (magic bytes 28 b5 2f fd).
#   - .rat  = tar comprimido con xz (RatPackageManager NO sabe leer zstd, solo
#             xz o zip -> TarUtils.isXZ() comprueba el magic FD 37 7A 58 5A 00),
#             con un "pkg-header" de texto plano de 5 líneas posicionales
#             (name=/category=/version=/architecture=/vkDriverLib=) y un árbol
#             "files/" que mapea 1:1 con APP_ROOT_DIR.
#
# Soporta estos modos, todos casos confirmados de "conversión directa"
# (sin pérdida, sin necesidad de parsear profile.json de forma genérica):
#
#   vulkan-driver : el .tzst trae un árbol "usr/lib/*.so" (+ opcionalmente
#                   "usr/share/..."), típico de graphics_driver/*.tzst
#                   (wrapper.tzst, wrapper-leegao.tzst, extra_libs.tzst, etc.
#                   en Bannerlator/GameNative). Todo el árbol pasa tal cual a
#                   "files/", igual que categoría VulkanDriver de MiceWine.
#                   Requiere el argumento vkDriverLib (nombre del .so principal,
#                   ej. libvulkan_wrapper.so).
#
#   dxvk / vkd3d / wowbox64 : el .wcp trae SIEMPRE un profile.json con
#                   entradas "files" cuya forma es exactamente
#                   source="system32/X" -> target="${system32}/X" y/o
#                   source="syswow64/X" -> target="${syswow64}/X" (dxvk-sarek,
#                   vkd3d-proton-arm64ec confirmados en
#                   The412Banner/Nightlies), o un único archivo suelto ->
#                   "${system32}/X" (WOWBox64, un solo wowbox64.dll). Se valida
#                   ESA forma exacta con python3 antes de copiar -- si el
#                   profile.json trae cualquier otra plantilla o ruta, el
#                   script falla explícito en vez de adivinar. category queda
#                   fija según el modo (DXVK / VKD3D / WOWBox64).
#
#   fexcore       : mismo sub-caso que dxvk/vkd3d/wowbox64 pero solo con
#                   "system32/" (sin "syswow64/"), category="FEXCore".
#
#   wine-prefixpack : caso REAL de Wine/Proton arm64ec completo de
#                   The412Banner/Nightlies (ver docs/investigacion/
#                   wine-arm-fexcore-dxvk-arm-plan-2026-08-19.md sección 2):
#                   NO trae una lista "files" en profile.json -- trae en su
#                   lugar una clave "wine": {"binPath","libPath","prefixPack"}
#                   apuntando a 3 carpetas sueltas (bin/, lib/, share/
#                   opcional) más un prefix Wine YA INICIALIZADO empaquetado
#                   aparte (prefixPack.txz, tar+xz real pese a la extensión,
#                   con un único directorio raíz ".wine/" envolviendo
#                   drive_c/dosdevices/system.reg/etc.). Se mapea
#                   bin/->files/wine/bin/, lib/->files/wine/lib/,
#                   share/->files/wine/share/ (si existe), y el prefixPack se
#                   reempaqueta SIN el directorio ".wine/" envolvente (mismo
#                   layout plano que ya espera
#                   WinePrefixManagerFragment.extractContainerPattern():
#                   drive_c/, system.reg, dosdevices/ en la raíz) como
#                   "files/container_pattern.tar.xz". category="Wine".
#
# NO soporta (documentado, no se fuerza una conversión rota):
#   - .wcp con profile.json de forma genérica (mapeo source->target dinámico
#     con múltiples plantillas ${system32}/${libdir}/${prefix}/etc. distintas
#     de las validadas arriba). Si el paquete de entrada no calza con ninguno
#     de los sub-casos simples descritos, este script debe fallar
#     explícitamente en vez de intentar adivinar el mapeo.
#
# Convención de nombre de versión para Wine arm64ec (regla de exclusión mutua
# Box64/FEXCore-WOWBox64/DXVK-ARM, ver plan): el VERSION pasado a este script
# para modo wine-prefixpack DEBE incluir el sufijo "arm64ec" (ej.
# "10.0-arm64ec"), igual que hace Winlator-Ludashi (WineInfo.isArm64EC()) --
# MiceWine deriva la arquitectura del Wine por ese sufijo en el nombre de
# versión, no por un campo nuevo en el pkg-header.
#
# Uso:
#   ./tools/wcp-tzst-to-rat.sh <input.wcp|input.tzst> <modo> <pretty-name> <version> <arch> <output-dir> [vkDriverLib]
#
# Ejemplos:
#   ./tools/wcp-tzst-to-rat.sh wrapper-leegao.tzst vulkan-driver "Leegao ICD" 2025-10 aarch64 ./out libvulkan_wrapper.so
#   ./tools/wcp-tzst-to-rat.sh dxvk-sarek-1.12.wcp dxvk "DXVK Sarek" 1.12-sarek aarch64 ./out
#   ./tools/wcp-tzst-to-rat.sh vkd3d-proton-arm64ec-3.0.1.wcp vkd3d "VKD3D Proton" 3.0.1-arm64ec aarch64 ./out
#   ./tools/wcp-tzst-to-rat.sh wowbox64-0.3.6.wcp wowbox64 "WOWBox64" 0.3.6 aarch64 ./out
#   ./tools/wcp-tzst-to-rat.sh fexcore.wcp fexcore "FEXCore" 2607 aarch64 ./out
#   ./tools/wcp-tzst-to-rat.sh proton-10.0-arm64ec.wcp wine-prefixpack "Wine Proton (10.0 arm64ec)" 10.0-arm64ec aarch64 ./out

set -euo pipefail

VALID_MODES="vulkan-driver dxvk vkd3d wowbox64 fexcore wine-prefixpack"

showHelp() {
    echo "Uso: $0 <input.wcp|input.tzst> <modo> <pretty-name> <version> <arch> <output-dir> [vkDriverLib]"
    echo ""
    echo "Modos: $VALID_MODES"
    echo "modo vulkan-driver requiere vkDriverLib (nombre del .so principal)."
    echo "modo wine-prefixpack: VERSION debe incluir el sufijo 'arm64ec' si corresponde."
}

if [ "$#" -lt 6 ]; then
    showHelp
    exit 1
fi

INPUT="$1"
MODE="$2"
PRETTY_NAME="$3"
VERSION="$4"
ARCH="$5"
OUTDIR="$6"
VK_DRIVER_LIB="${7:-}"

if [ ! -f "$INPUT" ]; then
    echo "Error: no existe el archivo de entrada '$INPUT'"
    exit 1
fi

case " $VALID_MODES " in
    *" $MODE "*) ;;
    *)
        echo "Error: modo desconocido '$MODE' (esperado: $VALID_MODES)"
        showHelp
        exit 1
        ;;
esac

if [ "$MODE" = "vulkan-driver" ] && [ -z "$VK_DRIVER_LIB" ]; then
    echo "Error: el modo 'vulkan-driver' requiere el argumento vkDriverLib (ej. libvulkan_wrapper.so)"
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: se necesita python3 para este script (validación de profile.json)."
    exit 1
fi

mkdir -p "$OUTDIR"

# --- Detección de compresión real por magic bytes (mismo criterio que
#     TarUtils.isXZ() en MiceWine-Application: FD 37 7A 58 5A 00 = xz;
#     28 B5 2F FD = zstd). No confiamos en la extensión del archivo. ---
detectCompression() {
    local file="$1"
    local magic
    magic="$(head -c 6 "$file" | od -An -tx1 | tr -d ' \n')"
    if [[ "$magic" == fd377a585a00* ]]; then
        echo "xz"
    elif [[ "$magic" == 28b52ffd* ]]; then
        echo "zstd"
    else
        echo ""
    fi
}

extractTo() {
    local file="$1" dest="$2" compression
    compression="$(detectCompression "$file")"
    if [ "$compression" = "xz" ]; then
        tar -xJf "$file" -C "$dest"
    elif [ "$compression" = "zstd" ]; then
        if ! command -v zstd >/dev/null 2>&1; then
            echo "Error: se necesita el binario 'zstd' para descomprimir '$file' (apt-get install zstd)"
            exit 1
        fi
        tar --zstd -xf "$file" -C "$dest"
    else
        echo "Error: '$file' no es un tar.xz ni un tar.zstd reconocible"
        exit 1
    fi
}

COMPRESSION="$(detectCompression "$INPUT")"
if [ -z "$COMPRESSION" ]; then
    echo "Error: '$INPUT' no es un tar.xz ni un tar.zstd reconocible"
    exit 1
fi
echo "Entrada: $INPUT (compresión detectada: $COMPRESSION)"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

EXTRACT_DIR="$TMPDIR/extract"
PACK_DIR="$TMPDIR/pack"
mkdir -p "$EXTRACT_DIR" "$PACK_DIR/files"

echo "Extrayendo..."
extractTo "$INPUT" "$EXTRACT_DIR"

# Validador compartido: confirma que TODAS las entradas "files" de un
# profile.json mapean system32/X -> ${system32}/X y/o syswow64/X ->
# ${syswow64}/X (dxvk/vkd3d/fexcore), o un archivo suelto en la raíz ->
# ${system32}/X (wowbox64). Falla explícito ante cualquier otra forma.
validateSimpleProfileJson() {
    local profile="$1" extract_dir="$2" allow_syswow64="$3"
    python3 - "$profile" "$extract_dir" "$allow_syswow64" <<'PYEOF'
import json, sys, os

profile_path, extract_dir, allow_syswow64 = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
with open(profile_path, "r", encoding="utf-8") as f:
    profile = json.load(f)

entries = profile.get("files", [])
if not entries:
    print("Error: profile.json no tiene ninguna entrada 'files'.")
    sys.exit(1)

for entry in entries:
    source = entry.get("source", "")
    target = entry.get("target", "")

    if source.startswith("system32/"):
        filename = source[len("system32/"):]
        expected_target = "${system32}/" + filename
    elif allow_syswow64 and source.startswith("syswow64/"):
        filename = source[len("syswow64/"):]
        expected_target = "${syswow64}/" + filename
    elif "/" not in source:
        # archivo suelto en la raíz del paquete (caso WOWBox64: un solo .dll)
        expected_target = "${system32}/" + source
    else:
        print(f"Error: entrada con source inesperado: {entry}")
        sys.exit(1)

    if target != expected_target:
        print(f"Error: entrada con target inesperado (no es '{expected_target}'): {entry}")
        sys.exit(1)

    if not os.path.isfile(os.path.join(extract_dir, source)):
        print(f"Error: profile.json referencia '{source}' pero el archivo no existe en el paquete.")
        sys.exit(1)

print(f"OK: {len(entries)} entrada(s) de profile.json validadas.")
PYEOF
}

case "$MODE" in
    vulkan-driver)
        if [ ! -d "$EXTRACT_DIR/usr" ]; then
            echo "Error: se esperaba un árbol 'usr/' en '$INPUT' para el modo vulkan-driver, no se encontró."
            exit 1
        fi
        cp -a "$EXTRACT_DIR/usr" "$PACK_DIR/files/usr"
        CATEGORY="VulkanDriver"
        DRIVER_LIB_HEADER="$VK_DRIVER_LIB"
        ;;
    dxvk|vkd3d)
        if [ ! -f "$EXTRACT_DIR/profile.json" ]; then
            echo "Error: modo '$MODE' esperaba un profile.json en '$INPUT' y no se encontró."
            exit 1
        fi
        if [ ! -d "$EXTRACT_DIR/system32" ] || [ ! -d "$EXTRACT_DIR/syswow64" ]; then
            echo "Error: se esperaban 'system32/' y 'syswow64/' en '$INPUT' para el modo $MODE, no se encontraron."
            exit 1
        fi
        validateSimpleProfileJson "$EXTRACT_DIR/profile.json" "$EXTRACT_DIR" 1
        mkdir -p "$PACK_DIR/files/x64" "$PACK_DIR/files/x32"
        cp -a "$EXTRACT_DIR/system32/." "$PACK_DIR/files/x64/"
        cp -a "$EXTRACT_DIR/syswow64/." "$PACK_DIR/files/x32/"
        if [ "$MODE" = "dxvk" ]; then CATEGORY="DXVK"; else CATEGORY="VKD3D"; fi
        DRIVER_LIB_HEADER=""
        ;;
    wowbox64)
        if [ ! -f "$EXTRACT_DIR/profile.json" ]; then
            echo "Error: modo 'wowbox64' esperaba un profile.json en '$INPUT' y no se encontró."
            exit 1
        fi
        validateSimpleProfileJson "$EXTRACT_DIR/profile.json" "$EXTRACT_DIR" 0
        mkdir -p "$PACK_DIR/files/x64"
        # Las entradas ya se validaron como archivo suelto -> ${system32}/X;
        # copiamos cada "source" listado en profile.json (no todo el árbol,
        # por si trae otros archivos sueltos irrelevantes).
        python3 - "$EXTRACT_DIR/profile.json" <<'PYEOF' | while read -r src; do cp -a "$EXTRACT_DIR/$src" "$PACK_DIR/files/x64/"; done
import json, sys
d = json.load(open(sys.argv[1] if len(sys.argv) > 1 else "profile.json"))
for e in d.get("files", []):
    print(e["source"])
PYEOF
        CATEGORY="WOWBox64"
        DRIVER_LIB_HEADER=""
        ;;
    fexcore)
        if [ ! -d "$EXTRACT_DIR/system32" ]; then
            echo "Error: se esperaba un árbol 'system32/' en '$INPUT' para el modo fexcore, no se encontró."
            exit 1
        fi
        if [ -d "$EXTRACT_DIR/syswow64" ]; then
            echo "Error: modo 'fexcore' no espera 'syswow64/' (sub-caso simple, ver comentario de cabecera)."
            echo "Este .wcp trae más contenido del validado -- revisar a mano en vez de forzar la conversión."
            exit 1
        fi
        if [ ! -f "$EXTRACT_DIR/profile.json" ]; then
            echo "Error: modo 'fexcore' esperaba un profile.json en '$INPUT' y no se encontró."
            exit 1
        fi
        validateSimpleProfileJson "$EXTRACT_DIR/profile.json" "$EXTRACT_DIR" 0
        mkdir -p "$PACK_DIR/files/x64"
        cp -a "$EXTRACT_DIR/system32/." "$PACK_DIR/files/x64/"
        CATEGORY="FEXCore"
        DRIVER_LIB_HEADER=""
        ;;
    wine-prefixpack)
        if [[ "$VERSION" != *arm64ec* ]]; then
            echo "Error: modo 'wine-prefixpack' requiere que VERSION incluya el sufijo 'arm64ec'"
            echo "(convención de MiceWine para derivar la arquitectura del Wine por nombre, ver"
            echo "docs/investigacion/wine-arm-fexcore-dxvk-arm-plan-2026-08-19.md)."
            exit 1
        fi
        if [ ! -f "$EXTRACT_DIR/profile.json" ]; then
            echo "Error: modo 'wine-prefixpack' esperaba un profile.json en '$INPUT' y no se encontró."
            exit 1
        fi
        WINE_INFO_JSON="$(python3 -c "
import json
d = json.load(open('$EXTRACT_DIR/profile.json'))
w = d.get('wine')
if not w or 'binPath' not in w or 'libPath' not in w or 'prefixPack' not in w:
    raise SystemExit('Error: profile.json no tiene la clave \"wine\" esperada (binPath/libPath/prefixPack).')
print(w['binPath'])
print(w['libPath'])
print(w.get('sharePath', 'share'))
print(w['prefixPack'])
")"
        BIN_PATH="$(echo "$WINE_INFO_JSON" | sed -n 1p)"
        LIB_PATH="$(echo "$WINE_INFO_JSON" | sed -n 2p)"
        SHARE_PATH="$(echo "$WINE_INFO_JSON" | sed -n 3p)"
        PREFIX_PACK="$(echo "$WINE_INFO_JSON" | sed -n 4p)"

        if [ ! -d "$EXTRACT_DIR/$BIN_PATH" ] || [ ! -d "$EXTRACT_DIR/$LIB_PATH" ]; then
            echo "Error: no se encontraron '$BIN_PATH/' y/o '$LIB_PATH/' dentro de '$INPUT'."
            exit 1
        fi
        if [ ! -f "$EXTRACT_DIR/$PREFIX_PACK" ]; then
            echo "Error: no se encontró el prefixPack '$PREFIX_PACK' dentro de '$INPUT'."
            exit 1
        fi

        mkdir -p "$PACK_DIR/files/wine"
        cp -a "$EXTRACT_DIR/$BIN_PATH" "$PACK_DIR/files/wine/bin"
        cp -a "$EXTRACT_DIR/$LIB_PATH" "$PACK_DIR/files/wine/lib"
        if [ -d "$EXTRACT_DIR/$SHARE_PATH" ]; then
            cp -a "$EXTRACT_DIR/$SHARE_PATH" "$PACK_DIR/files/wine/share"
        fi

        # Reempaquetar el prefixPack SIN el directorio envolvente ".wine/"
        # (o el que sea, se detecta el único directorio raíz real) para que
        # quede el mismo layout plano (drive_c/, system.reg, dosdevices/ en
        # la raíz) que ya espera
        # WinePrefixManagerFragment.extractContainerPattern().
        PREFIX_COMPRESSION="$(detectCompression "$EXTRACT_DIR/$PREFIX_PACK")"
        PREFIX_EXTRACT_DIR="$TMPDIR/prefixpack"
        mkdir -p "$PREFIX_EXTRACT_DIR"
        if [ "$PREFIX_COMPRESSION" = "xz" ]; then
            tar -xJf "$EXTRACT_DIR/$PREFIX_PACK" -C "$PREFIX_EXTRACT_DIR"
        elif [ "$PREFIX_COMPRESSION" = "zstd" ]; then
            tar --zstd -xf "$EXTRACT_DIR/$PREFIX_PACK" -C "$PREFIX_EXTRACT_DIR"
        else
            echo "Error: prefixPack '$PREFIX_PACK' no es tar.xz ni tar.zstd reconocible."
            exit 1
        fi

        # Si hay un único directorio raíz (ej. ".wine/", nombre con punto
        # inicial confirmado en el prefixPack.txz real de The412Banner), su
        # contenido pasa a ser la raíz del container_pattern; si ya viene
        # plano, se usa tal cual. shopt dotglob: el glob normal de bash NO
        # matchea entradas que empiezan con "." (como ".wine"), hace falta
        # habilitarlo explícito o el chequeo de "único directorio" falla mal.
        shopt -s dotglob
        ROOT_ENTRIES=("$PREFIX_EXTRACT_DIR"/*)
        shopt -u dotglob
        if [ "${#ROOT_ENTRIES[@]}" -eq 1 ] && [ -d "${ROOT_ENTRIES[0]}" ]; then
            PREFIX_ROOT="${ROOT_ENTRIES[0]}"
        else
            PREFIX_ROOT="$PREFIX_EXTRACT_DIR"
        fi

        if [ ! -d "$PREFIX_ROOT/drive_c" ]; then
            echo "Error: el prefixPack reempaquetado no tiene 'drive_c/' en su raíz -- layout inesperado, no se fuerza la conversión."
            exit 1
        fi

        # Fix real encontrado (2026-08-19) empaquetando proton-10.0-arm64ec de
        # The412Banner/Nightlies: los symlinks dosdevices/d:, e:, z: del
        # prefixPack original apuntan a rutas ABSOLUTAS hardcodeadas del
        # paquete de OTRA app (ej. "/data/data/com.winlator.cmod/storage",
        # "/data/user/0/com.winlator.cmod/files/..."), package name que
        # MiceWine no tiene (com.micewine.emu) -- quedarían symlinks rotos en
        # runtime. El container_pattern.tar.xz propio de MiceWine (generado
        # para proton-wine-10.0 x86_64) usa la convención "z: -> /" y no
        # define d:/e: -- se alinea acá al mismo criterio en vez de arrastrar
        # rutas de otra app.
        if [ -L "$PREFIX_ROOT/dosdevices/z:" ]; then
            rm "$PREFIX_ROOT/dosdevices/z:"
            ln -s / "$PREFIX_ROOT/dosdevices/z:"
        fi
        [ -L "$PREFIX_ROOT/dosdevices/d:" ] && rm "$PREFIX_ROOT/dosdevices/d:"
        [ -L "$PREFIX_ROOT/dosdevices/e:" ] && rm "$PREFIX_ROOT/dosdevices/e:"

        (cd "$PREFIX_ROOT" && tar -cJf "$PACK_DIR/files/container_pattern.tar.xz" .)

        CATEGORY="Wine"
        DRIVER_LIB_HEADER=""
        ;;
esac

cd "$PACK_DIR"

echo "name=$PRETTY_NAME" > pkg-header
echo "category=$CATEGORY" >> pkg-header
echo "version=$VERSION" >> pkg-header
echo "architecture=$ARCH" >> pkg-header
echo "vkDriverLib=$DRIVER_LIB_HEADER" >> pkg-header

# makeSymlinks.sh vacío: no se detectaron symlinks reales dentro de los .tzst
# "pelados" inspeccionados (graphics_driver/*, dxwrapper/*). Si el paquete de
# entrada sí trae symlinks (ej. el prefixPack de wine-prefixpack), quedan
# preservados como symlinks reales dentro de container_pattern.tar.xz (tar
# real, no se pierden) -- el fix de TarUtils.untar() (2026-08-19) ya los sabe
# extraer bien en runtime.
: > makeSymlinks.sh

SAFE_NAME="$(echo "$PRETTY_NAME" | tr ' /' '__')"
OUTPUT_FILE="$OUTDIR/$SAFE_NAME-$VERSION-$ARCH.rat"

echo "Empaquetando -> $OUTPUT_FILE"
tar -cJf "$OUTPUT_FILE" pkg-header files makeSymlinks.sh

cd - >/dev/null

echo "Listo: $OUTPUT_FILE ($(du -h "$OUTPUT_FILE" | cut -f1))"
