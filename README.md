# EpicenterDSP Player para iOS

Reproductor local de música para iPhone y iPad con una interfaz React y un
motor de audio completamente nativo en iOS. La aplicación conserva la
portabilidad de Capacitor para la interfaz, pero la reproducción, biblioteca,
procesamiento DSP y controles del sistema se ejecutan con tecnologías de Apple.

## Funciones principales

- Importación manual de archivos de audio desde el selector de documentos.
- Biblioteca local persistente con SQLite.
- Reproducción nativa con `AVAudioEngine`.
- Epicenter DSP con modos Car Audio y Audífonos.
- Ecualizador gráfico de 31 bandas.
- Reverb y Concert Hall.
- Detección de metadatos Hi-Res y Auto-EQ.
- Audio en segundo plano, Now Playing y controles remotos.
- Interfaz en español e inglés.
- Integración CarPlay en desarrollo.

La aplicación trabaja con archivos importados por el usuario. No intenta
procesar canciones protegidas por DRM ni audio perteneciente a otras apps.

## Arquitectura

```text
React + TypeScript + Vite
            |
        Capacitor 6
            |
   EpicenterNativeIos Pod
            |
Swift + Objective-C++ + C++17
            |
AVFoundation / MediaPlayer / SQLite
```

Directorios principales:

- `client/`: interfaz React y bridge TypeScript.
- `plugins/epicenter-native-ios/`: fuente nativa compilada del plugin iOS.
- `ios/App/`: workspace y configuración de Xcode.
- `docs/migration/`: documentación técnica de la migración nativa.
- `epicenter-lab/`: herramientas de análisis y validación del DSP.
- `server/` y `shared/`: servicios web opcionales y tipos compartidos.
- `android/`: implementación histórica y referencia para Android.

## Requisitos

- macOS.
- Xcode 15 o posterior.
- iOS Deployment Target 15.6.
- Node.js 24 LTS recomendado; mínimo `22.12.0`.
- pnpm `10.4.1`.
- CocoaPods.

Consulta [COMANDOS_MAC_XCODE.txt](COMANDOS_MAC_XCODE.txt) para preparar una
Mac nueva paso a paso.

## Instalación

```bash
pnpm install --frozen-lockfile
pnpm build
pnpm exec cap sync ios

cd ios/App
pod install
open App.xcworkspace
```

Abre siempre `App.xcworkspace`, no `App.xcodeproj`.

Para ejecutar en un iPhone físico, inicia sesión en Xcode, selecciona tu Team
en **Signing & Capabilities** y utiliza un Bundle Identifier perteneciente a
tu cuenta.

## Validación

```bash
pnpm check
pnpm test
pnpm build
node scripts/verify-ios-native-plugin.mjs
```

El workflow de GitHub Actions ejecuta typecheck, las pruebas y el build web en
cada pull request.

La compilación completa de Xcode requiere macOS y debe validarse además en un
iPhone físico para probar audio en segundo plano, cambios de ruta y controles
remotos.

## Variables opcionales

La ruta iOS local no necesita secretos para compilar. Las funciones web y de
servidor pueden configurarse copiando `.env.example` a `.env`; nunca publiques
el archivo `.env` real.

## CarPlay

El código del scene delegate está incluido, pero una distribución con CarPlay
requiere que Apple conceda el entitlement
`com.apple.developer.carplay-audio` y que el perfil de firma lo contenga.

## Documentación técnica

- [Validación del plugin en Xcode](docs/migration/IOS_XCODE_VALIDATION.md)
- [Grafo de audio iOS](docs/migration/IOS_AUDIO_GRAPH.md)
- [Mapa del Epicenter DSP](docs/migration/EPICENTER_DSP_PORT_MAP.md)
- [Reproducción en segundo plano](docs/migration/IOS_BACKGROUND_PLAYBACK.md)
- [Estrategia de importación](docs/migration/IOS_IMPORT_STRATEGY.md)
- [Referencia para portar el modo Audífonos a Android](docs/android/HEADPHONES_PORT.md)

## Licencia

Distribuido bajo la [licencia MIT](LICENSE).
