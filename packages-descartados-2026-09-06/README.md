# packages-descartados-2026-09-06/

Paquetes retirados de la cola de build el 2026-09-06 porque su configuración **no puede funcionar**, no por un bug de compilación puntual.

## Qué hay acá

- `wine-9.20-aarch64`
- `wine-10.10-aarch64`

## Por qué: configuración híbrida inválida

Ambos estaban configurados así:

```
--host=aarch64                  # lado unix/host compilado ARM64 nativo
--enable-archs=i386,x86_64      # lado guest PE x86
                                # (sin arm64ec)
```

Eso produce un binario que **ningún traductor puede ejecutar**:

- **Box64 no aplica.** Box64 traduce ELF x86_64 → ARM64. Acá `bin/wine` ya es un ELF ARM64 nativo, así que Box64 lo rechaza — error real observado en el log de escritorio del dispositivo: `[BOX64] Not an x86_64 ELF (183)` seguido de `Try to launch natively instead` y `wine: failed to open L"C:\\windows\\system32\\wineboot.exe": c0000135`.
- **FEXCore/WOWBox64 tampoco aplican.** Entran como unixlibs WoW64 (`libarm64ecfex.dll` / `libwow64fex.dll`) que Wine carga por nombre vía `HODLL` — y ese punto de entrada **solo existe si Wine se compiló con `arm64ec`**. Sin esa arch, no hay dónde engancharlos.

Verificación directa sobre el `.rat` real de `wine-10.10-aarch64` (411 MB):

```
$ tar -tf wine-10.10-aarch64-10.10-1-aarch64.rat | grep -oE "files/wine/lib/wine/[^/]+/" | sort -u
files/wine/lib/wine/aarch64-unix/
files/wine/lib/wine/i386-windows/
files/wine/lib/wine/x86_64-windows/
```

No existe `aarch64-windows/` — confirma que no hay lado ARM nativo del guest.

## Confirmación cruzada contra el ecosistema

Los cuatro forks de referencia (winlator_bionic/Pipetto, Bannerlator, Winlator-Ludashi, CronyX) soportan **exactamente dos** formas válidas de Wine:

1. **arm64ec** — ARM nativo con WoW64 vía FEXCore/WOWBox64.
2. **x86_64** — bajo Box64.

`WineInfo.java:21` es idéntico en todos: `Pattern.compile("^(wine|proton)-...-(x86|x86_64|arm64ec)$")`. Un `grep -rn "aarch64" --include=WineInfo.java` sobre los 4 forks da **cero** resultados. Esta tercera forma la inventó MiceWine y no es una configuración soportada de Wine.

## Por qué no se reconfiguraron a `--enable-archs=aarch64,arm64ec`

No es un cambio de flag: requiere que el cross-compiler PE arm64ec funcione contra esas bases de Wine concretas. Ya hay precedente real de que eso falla — `wine-10.1-arm64ec-firetest` (ver `packages-descartados-2026-08-31/README.md`) murió con asm inline x86 (`int $0x29`, `__fastfail`) sin guardas `#ifdef` en `winnt.h:7336` al compilar para arm64ec. Intentarlo acá era trabajo especulativo que bloqueaba el camino que sí sabemos correcto (`proton-wine-9.0-arm64ec`).

Si en el futuro se quiere un Wine vanilla ARM (no Proton), el camino es reconfigurar estos dos a `aarch64,arm64ec` y resolver los errores de compilación que aparezcan — el código fuente y los patches quedan intactos acá.

## Nada se borró

Regla 02 del proyecto: el código fuente y los patches siguen completos en esta carpeta. `build-all.sh` no los ve mientras estén fuera de `packages/`.

Los `.rat` ya construidos con la configuración inválida siguen en `built-pkgs/` (carpeta gitignoreada, artefactos locales) — no se distribuyen desde acá, pero conviene no instalarlos: no pueden arrancar.
