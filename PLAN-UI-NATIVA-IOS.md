# Plan: UI 100% nativa (SwiftUI) — solo iOS

Objetivo: reemplazar la capa web (React + Capacitor WebView) por una UI nativa en SwiftUI,
conservando **todos** los detalles actuales. El backend (audio, DSP, biblioteca, CarPlay) ya es
nativo y se reutiliza.

## Decisiones tomadas
- **Playlists**: se construyen con **persistencia nativa real** (hoy son un stub en memoria).
- **Presets del EQ**: **empezar limpios** (no se migran los de localStorage).
- **Privacidad / Términos**: **enlaces a página externa** (no pantallas in-app).
- **Framework**: **SwiftUI** (target iOS 15.6), con interop a UIKit solo donde convenga (perilla, sliders EQ).
- **Cutover "big bang"**: la app publicada sigue en la versión web hasta que la nativa esté completa
  y probada; se lanza todo junto en una sola actualización. **Mismo bundle id `com.epicenter.hifi`**,
  misma cuenta y entitlements (es una actualización de la app existente, no una app nueva).

---

# Inventario (referencia)

## Pantallas a reconstruir
| Pantalla | Ref web | Contenido |
|---|---|---|
| Inicio / Reproductor | `HomePlayerView.tsx` | Carátula, título/artista, badges de calidad (LOSSLESS·bits·kHz·kbps), progreso (seek), transporte, repeat, shuffle, panel de cola (reordenar/quitar/tocar), visualizador. Mini-player. |
| Mi Música / Biblioteca | `HomeLibraryView.tsx` | Divisiones: Canciones, Artistas, Álbumes, Hi-Res, Playlists. Orden. Filas deslizables. Importar. |
| Buscar | `HomeSearchView.tsx` | Input + resultados de la biblioteca. |
| DSP / Epicenter | `HomeDspView.tsx` | Switch Car/Audífonos, perilla Intensidad, perillas secundarias, botón Auto, visualizador, accesos a EQ/Efectos. |
| EQ | `HomeEqView.tsx` | 31 bandas, presets, preamp/reset, enable. |
| Efectos | `HomeEffectsView.tsx`/`HomeFxView.tsx` | Reverb (enable+amount), Concert Hall (enable+amount). |
| Ajustes | `HomeSettingsView.tsx` | Tema (oscuro/claro), idioma (es/en), versión, enlaces Privacidad/Términos, onboarding. |

## Modales
Onboarding · Import Progress · Library Preparing · Duplicates · Playlist Name / Add To Playlist /
Add Songs To Playlist / Delete Playlist · DSP Auto.

## Controles custom
KnobControl (perilla) · 31 sliders EQ · SwipeableTrackItem (gestos) · barras visualizador ·
switch segmentado Car/Audífonos · badges de calidad.

## Backend nativo (ya existe, se reutiliza)
`NativePlaybackController`, `NativeAudioEngine`, `NativeTrackRepository`, `NativeLibraryDatabase`,
`NativeTrackImporter`, DSP (`EpicenterDSPCore`, `EpicenterHeadphonesCore`, EQ, `EpicenterAutoEQAnalyzer`),
`NowPlayingManager`, `RemoteCommandManager`, `NativeAudioSessionManager`, CarPlay. Hoy viven dentro
del **pod de Capacitor**; hay que sacarlos a la app.

---

# Arquitectura destino

```
EpicenterDSP.app (SwiftUI, sin Capacitor)
├── App/                  entry point, contenedor de servicios, theme, localización
├── Services/  (movidos desde el pod de Capacitor, SIN el envoltorio CAPPlugin)
│   ├── Playback  (NativePlaybackController, Engine, Session, NowPlaying, RemoteCommand)
│   ├── Library   (Repository, Database, Importer)
│   ├── DSP        (EpicenterDSPCore, EpicenterHeadphonesCore, EQ, AutoEQ  —  C++/ObjC++)
│   └── CarPlay
├── ViewModels/  (ObservableObject; traducen los hooks actuales)
│   ├── PlaybackViewModel, QueueViewModel, LibraryViewModel, DspViewModel,
│   ├── EqViewModel, EffectsViewModel, PlaylistsViewModel, SettingsViewModel
├── Views/       (las 7 pantallas + reproductor + modales)
└── Components/  (KnobControl, EqSliders, SwipeableRow, Visualizer, QualityBadges, ModeSwitch)
```

Los eventos nativos (`playbackStateChanged`, `currentTrackChanged`, `progressChanged`, …) se
conectan a los ViewModels con closures/Combine en vez del puente JS.

---

# Fases

### Fase 0 — Cimientos (proyecto + servicios)
- Crear proyecto Xcode SwiftUI limpio (o reconvertir `ios/App`), **mismo bundle id/entitlements/CarPlay**.
- **Sacar los servicios nativos del pod de Capacitor** al target de la app (o a un Swift Package
  `EpicenterKit`), quitando solo el envoltorio `CAPPlugin`/`CAPPluginCall` (la lógica se queda).
- Compilar el DSP (C++/ObjC++) dentro del target. Localización `Localizable.strings` (es/en). Theme.
- **Hito:** app SwiftUI vacía que ya puede reproducir un archivo por el motor nativo (pantalla de prueba).

### Fase 1 — Reproductor + reproducción base
- `PlaybackViewModel` sobre `NativePlaybackController` (estado + transporte + eventos).
- Pantalla de reproductor completa (carátula, badges, seek, transporte, repeat, shuffle) + mini-player.
- Verificar Now Playing / pantalla de bloqueo / comandos remotos ya nativos.

### Fase 2 — Biblioteca
- `LibraryViewModel` sobre `NativeTrackRepository` (paginación, orden, búsqueda).
- Pantalla con divisiones: Canciones, Artistas, Álbumes, Hi-Res (agrupado en Swift).
- Filas con gestos (a cola / siguiente / a playlist / eliminar). Importar + overlays.

### Fase 3 — Cola
- Panel de cola (reordenar, quitar, tocar), shuffle, modos de repeat.

### Fase 4 — Suite DSP
- DSP/Epicenter (switch de modo, perilla Intensidad, perillas secundarias, Auto).
- EQ (31 bandas, presets limpios, preamp, reset, enable).
- Efectos (reverb, concert hall).
- Controles custom (perilla, sliders EQ, visualizador). Persistencia de presets/config → UserDefaults/SQLite.

### Fase 5 — Playlists (nuevo, con persistencia real)
- Tabla nueva en SQLite para playlists (id, nombre, trackIds, fechas).
- CRUD + modales (nombre, agregar a playlist, agregar canciones, eliminar). División en biblioteca.

### Fase 6 — Ajustes / onboarding
- Ajustes: tema, idioma, versión, **enlaces externos** a Privacidad/Términos (Safari).
- Onboarding. Review prompt. Permiso de notificaciones.

### Fase 7 — CarPlay + pulido
- Verificar CarPlay con la estructura nueva (usa `NativePlaybackController.shared`).
- Pulido: animaciones, hápticos, transiciones, accesibilidad, Dynamic Type, tema claro/oscuro.
- **Repaso de regresión pantalla por pantalla** contra este inventario.

### Fase 8 — Limpieza / cutover
- Retirar el proyecto web (`client/`, `server/`, config Capacitor, vite, deps web) del build.
- Actualizar build/CI. Archivar (o borrar) lo web. Enviar a App Store.

---

# Riesgos y mitigación
- **Perder detalles finos** (gestos, overlays, orden, badges) → este inventario + revisión 1:1 por pantalla.
- **Sacar los servicios del pod de Capacitor** → es mecánico, pero hay que cuidar imports y el bridge ObjC++.
- **Es un reemplazo total** → la versión publicada no cambia hasta terminar; se hace en una rama y se
  lanza completo. El motor de audio/DSP/skip/Hi-Res **no se tocan** (ya validados) → gran de-riesgo.

# Estimación (relativa)
El grueso son las **7 pantallas + reproductor/cola + controles custom + playlists**. Como el backend
ya está, es sobre todo UI y traducción de lógica. Trabajo de **semanas**, por fases, cada una probable
de forma aislada en la rama antes del cutover.
