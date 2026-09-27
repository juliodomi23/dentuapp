# Qué funciones conviene sumar a Dentu

Investigación del 26 de septiembre de 2026. Son señales de estudios con poblaciones específicas, no una encuesta a usuarios de Dentu. La decisión final debe validarse con usuarios reales de la app.

## Lo que ya cubre la app

Plan semanal, registro de comidas con foto, agua, peso, síntomas, progreso, recordatorios, lista de compra, tipo y minutos de ejercicio. En esta entrega se añadió cuenta personal, importación revisable de dieta externa y captura **manual** de calorías activas que muestra un smartwatch.

## Prioridades propuestas

| Prioridad | Función | Motivo y alcance sugerido |
| --- | --- | --- |
| 1 | Repetir una comida anterior | Un botón «Comí lo mismo» que copie texto y porción de un registro previo, con edición antes de guardar. Reduce pasos diarios. Un estudio de usabilidad encontró frustración por el tiempo necesario para registrar y por opciones limitadas; otro prototipo incluye explícitamente «Repeat previous food». [Estudio de usabilidad](https://pmc.ncbi.nlm.nih.gov/articles/PMC10832442/), [Diet DQ Tracker](https://pmc.ncbi.nlm.nih.gov/articles/PMC10346141/). |
| 2 | Sincronizar actividad con Apple Salud y Health Connect | Con permiso explícito, leer sesiones, duración y **calorías activas** del día; mostrar origen, hora y opción de corregir el dato manual. Evitar duplicados y no sumar calorías en reposo. Apple Watch registra muestras de energía activa en HealthKit; Health Connect dispone de `ExerciseSessionRecord` y `ActiveCaloriesBurnedRecord`. [HealthKit](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/activeenergyburned), [permisos de HealthKit](https://developer.apple.com/documentation/HealthKit/authorizing-access-to-health-data), [Health Connect](https://developer.android.com/health-and-fitness/health-connect/aggregate-data). |
| 3 | Historial semanal de ejercicio y hábitos | Mostrar días con actividad, minutos y calorías capturadas, junto con comida y agua. La app ya guarda esos datos por día; falta una vista que permita reconocer patrones sin registrar nada nuevo. En un estudio de uso, el compromiso con el registro de dieta varió mucho entre personas; simplificar el seguimiento es una hipótesis para validar. [Estudio de seguimiento](https://pmc.ncbi.nlm.nih.gov/articles/PMC10546506/). |
| 4 | Mejorar la importación de dieta | Guardar varias versiones de plan con fecha y permitir volver a uno anterior; mostrar una alerta cuando el PDF sea ilegible o falten días. La transcripción actual exige revisión humana y no calcula nutrientes que el documento no proporciona. |
| 5 | Lista de compra útil sin pasos extra | La app ya tiene lista de compra. Conviene probar con usuarios si quieren marcar artículos comprados, ajustar cantidades y compartirla. En una prueba con 133 padres, la organización, los planes de comidas y listas de compra se asociaron con ahorro de tiempo, pero el esfuerzo de uso influyó en la aceptación. [Prueba con usuarios](https://pubmed.ncbi.nlm.nih.gov/33960951/). |

## Lo que dejaría para después

- **Reconocimiento automático de alimentos y calorías a partir de una foto.** Puede resultar atractivo, pero no debe mostrarse como medición precisa sin validación de porciones. Una evaluación encontró opiniones divididas por errores de reconocimiento; un estudio con nutriólogos señala dificultades para estimar volumen y porciones desde imágenes. [Evaluación](https://pmc.ncbi.nlm.nih.gov/articles/PMC10832442/), [estudio con nutriólogos](https://pmc.ncbi.nlm.nih.gov/articles/PMC11602110/).
- **Contador de calorías o macros universales.** Dentu trabaja a partir de un plan profesional. Un estudio de 196 personas con diabetes tipo 1 valoró análisis nutricional y personalización, pero sus necesidades clínicas no representan a todos los usuarios de Dentu. No tomar sus porcentajes como demanda general ni añadir cálculo de insulina. [Encuesta](https://pmc.ncbi.nlm.nih.gov/articles/PMC11992487/).
- **Más recordatorios por defecto.** Conviene hacerlos configurables; participantes de un estudio cualitativo valoraron avisos útiles, pero indicaron que demasiados resultan molestos. [Estudio cualitativo](https://pmc.ncbi.nlm.nih.gov/articles/PMC12352858/).

## Cómo validarlo con usuarios de Dentu

Entrevistar a 5-8 personas (clientes clínicos y cuentas personales) después de una semana de uso. Pedirles que muestren la última comida que registraron, cuánto tardaron y qué omitieron; preguntar si tienen reloj y dónde ven las calorías activas. Ordenar las funciones según problemas observados y medir en la app: tiempo para registrar comida, días con registro por semana, uso de importación, correcciones al borrador y fallos de lectura. Estas métricas evitan construir funciones que se piden en abstracto pero no ayudan en el uso diario.
