# Port del modo Audífonos a Android

Este documento conserva las reglas del paquete local `epicenter audifonos/`
sin versionar copias duplicadas del código. Los archivos canónicos viven en
las rutas siguientes:

```text
plugins/epicenter-native-ios/ios/DSP/EpicenterHeadphonesCore.hpp
plugins/epicenter-native-ios/ios/DSP/EpicenterDSPCore.hpp
plugins/epicenter-native-ios/ios/DSP/EpicenterDSPCore.cpp
plugins/epicenter-native-ios/ios/DSP/EpicenterDSPBridge.h
plugins/epicenter-native-ios/ios/DSP/EpicenterDSPBridge.mm
plugins/epicenter-native-ios/ios/Plugins/EpicenterNativePlugin.swift
client/src/native/iosNativeAudio.ts
client/src/components/home/HomeDspView.tsx
```

## Objetivo

Implementar en Android el selector entre:

| Modo | Motor | Uso |
|---|---|---|
| Car Audio | Epicenter clásico | Equipos con subwoofer |
| Audífonos | `EpicenterHeadphonesCore` | Audífonos y bocinas portátiles |

Solo un motor puede procesar audio a la vez.

## Integración C++

El core requiere C++17:

```cpp
epicenter::HeadphonesBassCore headphones;
headphones.prepare(sampleRate, channelCount);
headphones.setIntensity(100.0f);

float* channels[2] = { left, right };
headphones.process(channels, 2, frameCount);
headphones.reset();
```

Debe compilarse junto con `EpicenterDSPCore.cpp`.

## Bridge

La capa nativa Android debe exponer al bridge de Capacitor:

```ts
setEpicenterMode({ mode: "car" | "headphones" })
```

La UI compartida ya usa los valores `"car"` y `"headphones"`.

## Reglas de fidelidad

1. No modificar la matemática de `EpicenterHeadphonesCore.hpp` sin una
   validación sonora aprobada.
2. Nunca ejecutar ambos motores simultáneamente.
3. Ejecutar `reset()` en ambos motores al cambiar de modo o de pista.
4. En modo Audífonos, la perilla Intensidad controla `setIntensity`.
5. Sweep, Width y Balance pertenecen al motor Car Audio.
6. El comportamiento de Car Audio debe permanecer sin cambios.
7. Con Epicenter apagado, la señal debe pasar sin procesamiento.

## Referencia del preset validado

Para Intensidad al 100 %:

```text
subBoost = 18 dB
subGen = 2.4
subDepth = 0.9
monoHz = 105
scoop = 10 dB
```

## Validación

- Comparar la misma pista en iOS y Android.
- El espectro promedio por bandas debe mantenerse aproximadamente dentro de
  1 dB.
- El crest factor esperado de la banda grave es aproximadamente 7–8 dB.
- El grave debe permanecer prácticamente mono.
- Cambiar de modo no debe producir clics ni arrastrar estado de filtros.
