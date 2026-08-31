# Índice de tools/

- `README.md`
- `create-rat-pkg.sh` — empaqueta un `destdir-pkg` compilado a `.rat` (usado por `build-all.sh` para cada paquete).
- `create-repository-index.sh` — genera el índice de repositorio para `RatDownloaderFragment`.
- `download-external-dependencies.sh` — descarga binarios oficiales prebuilt (DXVK, VKD3D, WineD3D, DXVK-GPLAsync) y los re-empaqueta a `.rat`, sin compilar.
- `move-components-rat.sh` — mueve/organiza `.rat` ya generados.
- `wcp-tzst-to-rat.sh` — convierte `.wcp`/`.tzst` de Winlator (y forks) a `.rat` de MiceWine para los casos mecánicos: `vulkan-driver`, `dxvk` (DXVK/VKD3D/WineD3D), y `fexcore` (sub-caso simple de `profile.json`, ver `docs/investigacion/formatos-wcp-tzst-a-rat.md` y `docs/investigacion/wine-arm64ec-fexcore-proton.md`).
- `check-package-updates.sh` — chequeo de solo lectura (curl a `api.github.com`, no compila ni toca ninguna receta) que compara el `PKG_VER`/`GIT_COMMIT` real de cada `build.sh` contra la última release/tag publicada upstream, para ~26 paquetes con mapeo curado (Box64, MangoHud, Vulkan-Headers/Loader/Tools/Volk, openssl, zlib, freetype, libpng, libxml2, brotli, glib, libffi, opus, libvorbis/libogg, libsndfile, pcre2, zstd, libevent, libarchive, libglvnd, xkbcommon, libadrenotools) más los 6 paquetes de Wine (reporta `GIT_URL`/`GIT_COMMIT` y el comando `git ls-remote` para comparar a mano, porque los forks de Wine no usan tags de versión). Uso: `./tools/check-package-updates.sh [carpeta1 carpeta2 ...]`. Ver `docs/investigacion/auditoria-versiones-paquetes-2026-08-24.md` para el resultado de la primera corrida y cómo extender el mapeo.
