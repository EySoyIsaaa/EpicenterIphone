# Cola, ajustes automáticos y calibración de audio

## Comportamiento

- La cola presenta la pista actual fija sobre la lista desplazable de próximas canciones.
  El historial se conserva internamente para Anterior y Repetir, pero no aparece en esa lista.
- Siguiente recoloca una canción existente inmediatamente después de la actual; Agregar
  a cola la recoloca al final. No se duplica ni se desplaza la canción que está sonando.
- Borrar y reordenar sólo afecta canciones futuras, incluso si auto-next ocurre durante
  el gesto. Las mutaciones se resuelven sobre la cola viva en el controlador nativo.
- Auto EQ y Auto Epicenter comparten el análisis de cada archivo y tienen controles
  independientes. Ninguno enciende su procesador. Auto EQ requiere EQ activo y actualiza
  las 31 bandas, la curva y los faders. Al apagarlo se restaura la curva manual.
- Auto Epicenter ajusta Intensidad en Audífonos; en Car Audio también ajusta Sweep, Width
  y Balance. Al apagarlo se recuperan los parámetros manuales. Editar una perilla o fader
  vuelve a modo manual en su procesador. Un resultado de análisis tardío respeta los switches.
- El análisis abre un lector independiente en segundo plano y toma hasta 120 ventanas
  de 4096 muestras. Usa menos de 4 MB en estéreo y también permite analizar Hi-Res streaming.
- Concert Hall aumenta su retorno máximo de 0.50 a 0.75 (+50% de señal reverberada).
  La señal seca sigue a ganancia unitaria y el limitador de salida sigue conectado.
- Car Audio multiplica sólo el subgrave reconstruido por `1 + 0.33 * intensidad²`
  (intensidad normalizada 0–1). A 100% el máximo es 1.33; no amplifica toda la canción
  ni cambia el motor Audífonos. Conserva el slew de 1.5 ms y la protección subsónica.
- La apertura usa capas de Core Animation con `preferredFrameRateRange` de 60/60/60.
  Anima transformaciones y opacidad; evita layout SwiftUI y blur completo por fotograma.
  Respeta Reducir movimiento y cancela sus animaciones al cerrar.

## Validación automática

El workflow `Native iOS` compila la aplicación SwiftUI para el simulador de iOS. También
ejecuta regresiones de cola/arrastre obsoleto, análisis de archivos 44.1/192 kHz y DSP
en 44.1/48/96/192 kHz (silencio, bypass, salida finita y presencia del subarmónico).

En Windows se compiló el DSP con `g++ -std=c++17 -O2 -Wall -Wextra -Wpedantic -Werror`.
Un tono de 80 Hz a amplitud 0.1 produjo estas amplitudes del subarmónico de 40 Hz:

| Sample rate | Anterior | Nuevo | Cambio |
|---|---:|---:|---:|
| 44.1 kHz | 0.0362423 | 0.0481954 | +32.98% |
| 48 kHz | 0.0364035 | 0.0484075 | +32.97% |
| 96 kHz | 0.0361091 | 0.0480071 | +32.95% |
| 192 kHz | 0.0365223 | 0.0485362 | +32.89% |

Estos valores se miden antes del limitador del host y no equivalen a un aumento de
sonoridad total de 33% en toda grabación.

## Comprobar en iPhone

1. Abrir la cola mientras suena una pista intermedia: la actual siempre queda visible
   al desplazar la lista; al avanzar desaparece de la lista la anterior.
2. Usar Siguiente con una canción que ya está más abajo y con una ya reproducida:
   ambas deben quedar justo después de la actual, sin reiniciarla. Agregar a cola debe
   colocarlas al final. Borrar/reordenar nunca debe mover la actual.
3. Probar las cuatro combinaciones Auto EQ/Auto Epicenter, con sus procesadores activos
   y apagados; apagar un automático mientras analiza y cambiar canción rápidamente.
   Ningún resultado tardío debe volver a activar ni modificar el procesador apagado.
4. Auto EQ debe mover visualmente los 31 faders y la curva. Apagar Auto EQ debe recuperar
   el ajuste manual. Cambiar Car Audio/Audífonos con Auto Epicenter activo debe adaptar
   la intensidad al modo elegido y no tocar el ecualizador.
5. Comparar Concert Hall en 25/50/75/100 y Car Audio al máximo con música real. Comprobar
   claridad, presión del subgrave y ausencia de saturación en el sistema de destino.
6. Medir la apertura con Instruments/Core Animation en el iPhone: objetivo 60 fps.
   El sistema puede reducir la frecuencia por ahorro de energía o límites térmicos;
   la preferencia de la animación no garantiza una medición física sin esa prueba.

Después de añadir estos archivos, ejecutar `xcodegen generate` dentro de `ios-native`
antes de abrir/compilar el proyecto.
