# EpicenterDSP — app nativa (SwiftUI)

Reescritura de la UI a **SwiftUI 100% nativo** (sin Capacitor/WebView). El backend de audio, DSP,
biblioteca y CarPlay se irá trayendo por fases; el resto del código nativo actual vive todavía en
`../plugins/epicenter-native-ios` y `../ios`.

El proyecto de Xcode **se genera desde `project.yml` con XcodeGen** (así se puede editar todo desde
cualquier equipo y queda limpio en git — no hay `.xcodeproj` versionado con conflictos).

## Requisitos (una sola vez, en la Mac)

```bash
brew install xcodegen
```

## Generar y abrir el proyecto

```bash
cd ios-native
xcodegen generate        # crea EpicenterDSP.xcodeproj a partir de project.yml
open EpicenterDSP.xcodeproj
```

> Cada vez que yo agregue, mueva o quite archivos, vuelve a correr `xcodegen generate`.

## Antes de compilar

1. En Xcode: selecciona el target **EpicenterDSP** → pestaña **Signing & Capabilities**.
2. Marca **Automatically manage signing** y elige tu **Team**.
3. Verifica el **Bundle Identifier** (`com.epicenterdsp.player`). ⚠️ Debe ser **idéntico** al de tu
   app en App Store Connect para que sea una actualización de la app publicada.

## Compilar

`⌘R` en un simulador o dispositivo. **Hito de esta fase:** la app arranca y muestra el shell de
**5 pestañas** (Inicio · Mi Música · Buscar · DSP · Ajustes), cada una con un placeholder.

## Estructura

```
ios-native/
├── project.yml            definición del proyecto (XcodeGen)
├── Support/
│   └── Info.plist         config del bundle (modo audio en segundo plano, etc.)
└── Sources/
    └── App/
        ├── EpicenterApp.swift   @main (entry SwiftUI)
        ├── RootView.swift       shell de 5 pestañas
        └── Theme.swift          paleta de marca
```

## Estado / roadmap

- [x] **Fase 0a** — esqueleto que compila y muestra las 5 pestañas.
- [ ] Fase 0b — traer los servicios nativos (motor, biblioteca, DSP) fuera del pod de Capacitor.
- [ ] Fase 1 — reproductor + reproducción base.
- [ ] Fase 2 — biblioteca. Fase 3 — cola. Fase 4 — DSP. Fase 5 — playlists. Fase 6 — ajustes.
- [ ] Fase 7 — CarPlay + pulido. Fase 8 — retirar la capa web y publicar.

Plan completo en `../PLAN-UI-NATIVA-IOS.md`.
