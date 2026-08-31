#!/bin/bash
# check-package-updates.sh — Chequeo de solo lectura de versiones upstream.
#
# Recorre las recetas reales en packages/*/build.sh, extrae PKG_VER (o el tag
# real del GIT_COMMIT vía el propio nombre de carpeta) junto con GIT_URL/SRC_URL,
# y consulta la API pública de GitHub (releases/tags) para reportar si existe
# una versión más nueva publicada upstream. NO modifica ningún build.sh, NO
# compila nada, NO descarga fuentes de paquete — solo hace GET a
# api.github.com. Requiere `curl` y `jq` (o hace fallback a grep si falta jq).
#
# Uso:
#   ./tools/check-package-updates.sh                # todos los paquetes con mapeo conocido
#   ./tools/check-package-updates.sh box64 wine-10.10  # solo estos paquetes (por nombre de carpeta)
#
# Cómo extender: agregar una línea al array MAP más abajo con el formato
#   "carpeta|owner/repo|tipo"
# donde tipo es "releases" (usa GET /repos/{owner}/{repo}/releases/latest,
# sirve para paquetes con versionado semver estándar y "latest release"
# marcado en GitHub) o "tags" (usa GET /repos/{owner}/{repo}/tags, sirve para
# repos que no marcan ninguna release como "latest" o que versionan con tags
# no-semver, como los forks de Wine). El script no adivina el repo: si un
# paquete usa GIT_URL apuntando directo a GitHub, se puede derivar owner/repo
# de esa URL automáticamente (ver función `owner_repo_from_giturl`), así que
# en muchos casos no hace falta tocar el MAP a mano.
#
# Limitación conocida (documentada, no oculta): paquetes hospedados fuera de
# GitHub (gitlab.freedesktop.org, gitlab.com/gnutls, sourceforge, mirrors.kernel.org,
# archive.mesa3d.org) no tienen chequeo automático acá — quedan listados en la
# sección "sin chequeo automático" del reporte final, para revisión manual
# (ver docs/investigacion/auditoria-versiones-paquetes-2026-08-24.md, tiene los
# comandos manuales usados para cada uno de estos en esta ronda).

set -u
cd "$(dirname "$0")/.." || exit 1
PACKAGES_DIR="$PWD/packages"

have_jq=0
command -v jq >/dev/null 2>&1 && have_jq=1

# owner/repo derivado de una URL de GitHub (https://github.com/OWNER/REPO[.git])
owner_repo_from_giturl() {
	local url="$1"
	if [[ "$url" =~ github\.com/([^/]+)/([^/.]+) ]]; then
		echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
	fi
}

# GET a la API de GitHub con manejo básico de rate limit (no autenticado: 60 req/h)
gh_api() {
	local path="$1"
	curl -s -H "Accept: application/vnd.github+json" "https://api.github.com/$path"
}

extract_field() {
	# extract_field <build.sh> <NOMBRE_VAR>
	grep -m1 -E "^${2}=" "$1" 2>/dev/null | sed -E "s/^${2}=//; s/^\"//; s/\"\$//"
}

# Paquetes con mapeo curado a mano (repo real + tipo de endpoint más confiable),
# priorizados según el pedido del usuario (Box64, Wine variants, DXVK/VKD3D vía
# tools/download-external-dependencies.sh, y los paquetes Core más grandes).
# Formato: "carpeta|owner/repo|tipo"
declare -a MAP=(
	"box64-0.4.2|ptitSeb/box64|tags"
	"libadrenotools|bylaws/libadrenotools|tags"
	"mangohud|flightlessmango/MangoHud|releases"
	"openssl|openssl/openssl|releases"
	"zlib|madler/zlib|releases"
	"freetype|freetype/freetype|releases"
	"libpng|glennrp/libpng|releases"
	"libxml2|GNOME/libxml2|releases"
	"brotli|google/brotli|releases"
	"glib|GNOME/glib|releases"
	"libffi|libffi/libffi|releases"
	"opus|xiph/opus|releases"
	"libvorbis|xiph/vorbis|tags"
	"libogg|xiph/ogg|releases"
	"libsndfile|libsndfile/libsndfile|releases"
	"pcre2|PCRE2Project/pcre2|releases"
	"zstd|facebook/zstd|releases"
	"libevent|libevent/libevent|releases"
	"libarchive|libarchive/libarchive|releases"
	"Vulkan-Headers|KhronosGroup/Vulkan-Headers|tags"
	"Vulkan-Loader|KhronosGroup/Vulkan-Loader|tags"
	"Vulkan-Tools|KhronosGroup/Vulkan-Tools|tags"
	"Vulkan-Volk|zeux/volk|tags"
	"libglvnd|NVIDIA/libglvnd|tags"
	"xkbcommon|xkbcommon/libxkbcommon|tags"
	"libtool|-|skip"
)

# Paquetes que declaran GIT_URL de un fork de Wine: se reportan comparando
# GIT_COMMIT contra el HEAD real de la rama declarada en el propio build.sh
# (comentario "rama wine-X.Y" o similar), no contra "última release", porque
# estos forks no usan tags de versión (ver docs/investigacion/*wine* previos).
declare -a WINE_PKGS=(wine-9.20 wine-9.20-aarch64 wine-10.10 proton-wine-10.0 wine-10.1-arm64ec-firetest wine-arm64ec-andrerh-hangover)

check_releases() {
	local repo="$1"
	local resp
	resp=$(gh_api "repos/$repo/releases/latest")
	if [ $have_jq -eq 1 ]; then
		echo "$resp" | jq -r '.tag_name // empty'
	else
		echo "$resp" | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/'
	fi
}

check_tags() {
	local repo="$1"
	local resp
	resp=$(gh_api "repos/$repo/tags?per_page=1")
	if [ $have_jq -eq 1 ]; then
		echo "$resp" | jq -r '.[0].name // empty'
	else
		echo "$resp" | grep -m1 '"name"' | sed -E 's/.*"name": *"([^"]+)".*/\1/'
	fi
}

echo "== check-package-updates.sh — chequeo de solo lectura contra GitHub =="
echo "(no autenticado: límite 60 requests/hora a api.github.com)"
echo

filter="${*:-}"

printf "%-32s %-22s %-22s %s\n" "PAQUETE" "VERSION MICEWINE" "ULTIMA UPSTREAM" "ESTADO"
printf "%-32s %-22s %-22s %s\n" "--------" "----------------" "---------------" "------"

for entry in "${MAP[@]}"; do
	IFS='|' read -r folder repo type <<<"$entry"
	[ -n "$filter" ] && [[ " $filter " != *" $folder "* ]] && continue
	[ "$type" = "skip" ] && continue

	build="$PACKAGES_DIR/$folder/build.sh"
	if [ ! -f "$build" ]; then
		printf "%-32s %-22s %-22s %s\n" "$folder" "?" "?" "receta no encontrada"
		continue
	fi
	local_ver=$(extract_field "$build" "PKG_VER")

	if [ "$type" = "releases" ]; then
		upstream=$(check_releases "$repo")
	else
		upstream=$(check_tags "$repo")
	fi
	[ -z "$upstream" ] && upstream="(sin dato/rate-limit)"

	estado="revisar a mano"
	if [ -n "$local_ver" ] && [ -n "$upstream" ]; then
		# comparación textual simple: si el upstream normalizado contiene la
		# versión local, se asume al día. No es un compare semver real
		# (evita falsos positivos de "actualizar" por diffs de formato tipo
		# v1.2.3 vs 1.2.3), pero tampoco reemplaza la revisión humana.
		norm_local=$(echo "$local_ver" | tr -d 'v')
		norm_up=$(echo "$upstream" | tr -d 'v')
		if [ "$norm_local" = "$norm_up" ]; then
			estado="al dia"
		else
			estado="posible actualizacion -> $upstream"
		fi
	fi

	printf "%-32s %-22s %-22s %s\n" "$folder" "$local_ver" "$upstream" "$estado"
done

echo
echo "== Paquetes de Wine (forks sin tags de version, comparar rama/commit a mano) =="
for pkg in "${WINE_PKGS[@]}"; do
	[ -n "$filter" ] && [[ " $filter " != *" $pkg "* ]] && continue
	build="$PACKAGES_DIR/$pkg/build.sh"
	[ -f "$build" ] || continue
	giturl=$(extract_field "$build" "GIT_URL")
	commit=$(extract_field "$build" "GIT_COMMIT")
	echo "$pkg: GIT_URL=$giturl GIT_COMMIT=$commit"
	echo "  -> comparar con: git ls-remote --heads $giturl"
done

echo
echo "== DXVK / VKD3D / WineD3D / FEXCore =="
echo "No son recetas de packages/ (se instalan como .rat prebuilt vía"
echo "tools/download-external-dependencies.sh, que ya mantiene listas explícitas"
echo "de TODAS las versiones ofrecidas en paralelo, no solo 'la última'). Para"
echo "ver si esas listas (DXVK_LIST, VKD3D_LIST, WINED3D_LIST, FEXCore) están"
echo "al día, comparar el tope de cada lista contra:"
echo "  curl -s https://api.github.com/repos/doitsujin/dxvk/releases/latest"
echo "  curl -s https://api.github.com/repos/HansKristian-Work/vkd3d-proton/releases/latest"
echo "  (WineD3D y FEXCore no tienen API de releases estándar consultable, ver"
echo "   comentarios dentro de tools/download-external-dependencies.sh)"
