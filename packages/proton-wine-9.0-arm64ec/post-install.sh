# NO es copia literal de packages/proton-wine-10.0/post-install.sh -- se
# verifico (2026-08-30) que dlls/appwiz.cpl/addons.c de esta rama de Pipetto
# usa un formato de addon DISTINTO al de KreitinnSoftware/proton-wine:
#   - Archivos .msi (no .tar.xz) -- Wine los usa directos, sin descomprimir.
#   - Gecko: URL real confirmada por analogia con el patron oficial WineHQ
#     (dl.winehq.org/wine/wine-gecko/$VERSION/wine-gecko-$VERSION-$ARCH.msi);
#     el "url_default" que trae el propio addons.c
#     (http://source.winehq.org/winegecko.php) es un script de redireccion
#     dinamica, no una URL de archivo descargable directo.
#   - Mono: URL literal tomada directo del codigo fuente de addons.c
#     (github.com/madewokherd/wine-mono/releases/download/...), NO un patron
#     inventado.
#   - Wine verifica SHA256 contra un hash hardcodeado en el binario
#     (BCRYPT_SHA256_ALG_HANDLE + addon->sha en dlls/appwiz.cpl/addons.c) antes
#     de instalar cada addon -- si el .msi descargado no matchea byte a byte
#     con el que Pipetto embebio, Wine lo va a rechazar en tiempo de ejecucion.
#     Esto NO se puede confirmar sin un build real + prueba en dispositivo
#     (pendiente, ver docs/investigacion/wine-proton9-pipetto-plan.md), se
#     documenta como riesgo conocido en vez de asumir que funciona.
#
# GECKO_ARCH/MONO_ARCH salen fijos por los #ifdef de addons.c (no dependen del
# host que compila, sino del target de Windows-guest que corre adentro):
#   GECKO_ARCH: "x86_64" para cualquier build __x86_64__ o __aarch64__ (nuestro caso)
#   MONO_ARCH:  "x86" para cualquier build __i386__/__x86_64__/__aarch64__ (nuestro caso)

MONO_VERSION=$(grep -R "#define MONO_VERSION" "../dlls/appwiz.cpl/addons.c" | cut -d " " -f 3)
MONO_VERSION=${MONO_VERSION:1:-1}

GECKO_VERSION=$(grep -R "#define GECKO_VERSION" "../dlls/appwiz.cpl/addons.c" | cut -d " " -f 3)
GECKO_VERSION=${GECKO_VERSION:1:-1}

GECKO_ARCH="x86_64"
MONO_ARCH="x86"

curl -LO# "https://dl.winehq.org/wine/wine-gecko/$GECKO_VERSION/wine-gecko-$GECKO_VERSION-$GECKO_ARCH.msi"
curl -LO# "https://github.com/madewokherd/wine-mono/releases/download/wine-mono-$MONO_VERSION/wine-mono-$MONO_VERSION-$MONO_ARCH.msi"

mkdir -p ../destdir-pkg/$PREFIX
mkdir -p ../destdir-pkg/$PREFIX/../wine/share/wine/{mono,gecko}

# Los .msi van sueltos, con el mismo nombre de archivo que espera addons.c
# (L"wine-gecko-" VERSION "-" ARCH ".msi" / L"wine-mono-" ... ".msi") -- no se
# descomprimen (a diferencia de proton-wine-10.0, que usa tar.xz).
cp "wine-gecko-$GECKO_VERSION-$GECKO_ARCH.msi" ../destdir-pkg/$PREFIX/../wine/share/wine/gecko/
cp "wine-mono-$MONO_VERSION-$MONO_ARCH.msi" ../destdir-pkg/$PREFIX/../wine/share/wine/mono/

rm -rf ../destdir-pkg/$PREFIX

rm -f "wine-gecko-$GECKO_VERSION-$GECKO_ARCH.msi" "wine-mono-$MONO_VERSION-$MONO_ARCH.msi"
