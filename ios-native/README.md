# EpicenterDSP — app SwiftUI

Esta es la app nativa actual: reproductor, biblioteca, cola, Epicenter Car Audio/Audífonos,
ecualizador de 31 bandas, efectos, ajustes y playlists. Reutiliza el motor Swift/ObjC++/C++
de `../plugins/epicenter-native-ios/ios` sin el envoltorio de Capacitor.

## Actualizar y abrir en la Mac

Desde la raíz del repositorio:

```bash
git switch feat/native-ui
git pull --ff-only
bash ABRIR_APP_NATIVA.command
```

El comando verifica que la copia incluya los arreglos del commit `f9afc46`, regenera el
proyecto y abre `ios-native/EpicenterDSP.xcodeproj` por su ruta absoluta. El commit
`7672833` es anterior a los ocho arreglos. La app nueva se identifica como **4.0 (2)**
en Música → Ajustes → Acerca de y en la apertura.

## Requisitos

Xcode con sus componentes instalados y XcodeGen:

```bash
brew install xcodegen
```

Para abrir manualmente, desde esta carpeta:

```bash
xcodegen generate
open EpicenterDSP.xcodeproj
```

Regenera el proyecto después de actualizar el repositorio. `project.yml` define las
fuentes, recursos, frameworks y el identificador; el `.xcodeproj` generado no se versiona.

## Ejecutar en Xcode

1. Esquema **EpicenterDSP** y destino iPhone/simulador.
2. Target **EpicenterDSP** → **Signing & Capabilities** → elige tu Team.
3. **⇧⌘K** para limpiar la compilación si estás comprobando una actualización.
4. **⌘R** para instalar y ejecutar. Comprueba **4.0 (2)** en la app.

La configuración actual usa `com.epicenterdsp.player`. Conserva el Bundle Identifier
de la app que estés actualizando para que iOS la reconozca como la misma instalación.

## Validación

El workflow [Native iOS](../.github/workflows/native-ios.yml) ejecuta las regresiones de
cola, ajuste automático, análisis Hi-Res y DSP, compila SwiftUI para iOS Simulator y
comprueba la versión de la aplicación generada.

Los ocho ajustes y las comprobaciones de escucha/dispositivo están documentados en
[VALIDACION-AJUSTES.md](VALIDACION-AJUSTES.md).

La compilación web y `cap sync ios` pertenecen al proyecto anterior de `../ios/App`;
no actualizan esta interfaz SwiftUI.
