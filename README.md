# MiFIR

App de práctica (Flutter, Android) para el examen FIR de Farmacia, con preguntas
reales de convocatorias anteriores, explicaciones, y modos de estudio por
asignatura, por año o repasando solo las preguntas que has fallado.

## Qué incluye

- **8.228 preguntas** en total: **6.098 oficiales** (convocatorias reales del
  Ministerio) + **2.130 no oficiales** (simulacros de una academia privada).
  En la app puedes elegir practicar solo con oficiales, solo con no
  oficiales, o con ambas — el selector aparece en la pantalla de inicio y en
  "Practicar por asignatura", y afecta también al test aleatorio y al examen
  simulacro. "Practicar por año" solo incluye convocatorias oficiales reales.
  La app no muestra en ningún sitio el nombre de la academia de origen de
  las preguntas no oficiales.
- **Preguntas oficiales (6.098)**, extraídas y verificadas contra las
  plantillas oficiales de respuestas del Ministerio de Sanidad y los
  materiales de AFIR que adjuntaste:
  - FIR 2000 a FIR 2008: examen completo de cada convocatoria (260 preguntas
    de 5 opciones por año), verificado contra la plantilla oficial de
    respuestas de cada año, **con explicación redactada para todas las
    preguntas no anuladas** (2000: 257/260, 2001: 255/260, 2002: 258/260,
    2003: 258/260, 2004: 252/260, 2005: 255/260, 2006: 253/260, 2007: 257/260,
    2008: 254/260; el resto están anuladas). El PDF del año 2000 era un
    escaneo sin capa de texto, así que sus preguntas se transcribieron
    directamente de la imagen del cuadernillo oficial.
  - FIR 2009 a FIR 2019 (Libro Gordo AFIR), con asignatura, tema y explicación.
  - FIR 2020: examen completo (185 preguntas: 175 + 10 de reserva), con la
    respuesta oficial verificada **y explicación redactada para todas las
    preguntas no anuladas** (182 de 185; las 3 restantes están anuladas).
  - FIR 2021: examen completo (210 preguntas) con explicación, cruzado contra
    el cuadernillo oficial y el documento comentado.
  - FIR 2022, 2023 y 2024: examen completo con la respuesta oficial correcta
    verificada (incluyendo preguntas anuladas) **y explicación redactada
    para todas las preguntas no anuladas** (620 explicaciones añadidas),
    ya que los PDF originales de esos años no traían comentarios, solo la
    plantilla de respuestas al final.
  - FIR 2025 (convocatoria 2025): examen completo con explicación.
- **Preguntas no oficiales (2.130)**, simulacros de una academia privada (no
  son exámenes reales del Ministerio), con explicación redactada para todas.
  En la app todas aparecen etiquetadas por igual como "Preguntas no
  oficiales", sin distinguir entre simulacros y minisimulacros ni hacer
  ninguna referencia a la academia de origen:
  - 8 simulacros completos (4 de 185 preguntas, 4 de 235), con la respuesta
    correcta verificada contra la plantilla de cada simulacro.
  - 9 minisimulacros de 50 preguntas cada uno (450 preguntas).
- Las preguntas **anuladas** por el Ministerio no se incluyen en las
  prácticas (no tienen una única respuesta correcta).
- La **asignatura** de cada pregunta de 2022-2025 se ha asignado de forma
  automática por palabras clave (no viene indicada en esos documentos), así
  que puede haber alguna clasificación mejorable.

## Ranking online (opcional)

La app incluye un ranking online opcional: cualquiera puede pulsar
"Conectarse", elegir un nombre de usuario (sin email ni contraseña) y a
partir de ahí su progreso (aciertos totales y por asignatura) se sube a un
ranking general y a un ranking por asignatura visibles para el resto de
gente conectada. Quien no se conecta sigue usando la app exactamente igual
que antes, en local.

Esto usa Firebase (gratis) como servidor. **La app compila y funciona sin
esto** — hasta que lo configures, el botón de ranking simplemente avisará
de que no está disponible. Pasos para activarlo:

1. Ve a [console.firebase.google.com](https://console.firebase.google.com) →
   "Añadir proyecto" → dale un nombre (por ejemplo `mifir-app`) → puedes
   desactivar Google Analytics, no hace falta.
2. Dentro del proyecto, pulsa el icono de Android ("Añadir app") →
   introduce como "nombre del paquete de Android" exactamente:
   `com.mariabenitonutricion.fir_test` → "Registrar app".
3. Descarga el archivo `google-services.json` que te ofrece. Súbelo a tu
   repositorio de GitHub dentro de la carpeta `android/app/` (mismo método
   que usaste para crear el workflow: "Add file" → "Upload files", o
   "Create new file" con el nombre `android/app/google-services.json` y
   pegando el contenido del archivo descargado).
4. En el menú lateral de Firebase, ve a **Firestore Database** → "Crear base
   de datos" → elige una ubicación (por ejemplo `eur3 (europe-west)`) →
   empieza en "modo de producción".
5. Dentro de Firestore, pestaña **Reglas**, sustituye el contenido por esto
   y pulsa "Publicar":
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /usernames/{name} {
         allow read: if true;
         allow create: if request.auth != null
           && request.resource.data.uid == request.auth.uid;
         allow update, delete: if false;
       }
       match /players/{uid} {
         allow read: if true;
         allow write: if request.auth != null && request.auth.uid == uid;
       }
       match /subject_scores/{subject}/players/{uid} {
         allow read: if true;
         allow write: if request.auth != null && request.auth.uid == uid;
       }
     }
   }
   ```
6. En el menú lateral, ve a **Authentication** → "Comenzar" → pestaña
   "Sign-in method" → habilita el proveedor **Anónimo** (esto deja que cada
   móvil tenga una identidad interna sin pedir email; el nombre público que
   se ve en el ranking es el que el usuario elige, no tiene relación con
   esto).
7. Relanza el workflow de GitHub Actions (pestaña Actions → "Run workflow")
   para generar un APK ya con el ranking activo.

Nada de esto es necesario para que el resto de la app funcione — puedes
saltarte esta sección si no te interesa el ranking.

## Monetización: suscripción anual "Premium"

La app funciona con un modelo freemium. Gratis incluye únicamente:
- Preguntas oficiales de las convocatorias 2024 y 2025 ("Practicar por
  año" y "Test aleatorio general").
- "Practicar por asignatura" limitado a Técnicas Instrumentales y Química
  Farmacéutica.

La suscripción anual "Premium" desbloquea, mientras esté activa: el resto
de convocatorias (2000-2023), el resto de asignaturas, las preguntas no
oficiales, el examen simulacro cronometrado, repasar falladas y el ranking
online.

Esto usa Google Play Billing a través del paquete `in_app_purchase`. Para
activarlo:

1. Sube la app por primera vez a Play Console como mínimo hasta la pista de
   pruebas internas (los productos de compra dentro de la app no se pueden
   configurar hasta que exista al menos una versión subida).
2. En Play Console, entra en tu app → menú lateral **Monetizar** →
   **Productos** → **Suscripciones** → "Crear suscripción".
3. Como **ID del producto** escribe exactamente `mifir_premium_anual`
   (tiene que coincidir con la constante `kPremiumProductId` de
   `lib/services/purchase_service.dart`).
4. Ponle nombre ("Premium") y descripción, y guarda.
5. Dentro de la suscripción, crea un **plan base**: dale un ID (por
   ejemplo `anual`), tipo de facturación **automática recurrente**,
   periodo de facturación **1 año**, y fija el precio (por ejemplo con un
   precio base para España y dejando que Google calcule el resto de
   países).
6. **Activa** tanto el plan base como la suscripción — si el plan base
   queda en borrador, la app no encontrará nada que vender.
7. Para poder probar la suscripción antes de publicar de verdad, añade tu
   cuenta de Gmail como "tester de licencia" en Play Console →
   Configuración → Cuentas de prueba de licencia, e instala la app desde
   la pista de pruebas (interna o cerrada) en un móvil con esa cuenta. En
   modo prueba las suscripciones se renuevan de forma acelerada (un año se
   simula en minutos) y no se cobra de verdad.

Cómo decide la app si alguien es Premium: al arrancar consulta a Google
Play las compras activas. Si hay una suscripción activa, concede Premium;
si Google Play responde y no hay ninguna, lo revoca. Si no hay conexión,
mantiene el último estado conocido para que la app siga usable sin
internet, y lo vuelve a comprobar cuando haya red.

Si quieres cambiar qué queda gratis y qué es Premium, la lista de años
gratuitos está en `kFreeYears` y la de asignaturas gratuitas en
`kFreeSubjects` (`lib/services/purchase_service.dart`).

## Firmar la app para Play Store (sin instalar nada en tu ordenador)

Play Store no acepta la clave de firma "de debug" que se usa para pruebas.
Necesitas tu propia clave, y tiene que ser SIEMPRE la misma en todas las
futuras actualizaciones de la app (si la pierdes, no podrás volver a
actualizar la app publicada — solo publicar una app nueva desde cero). Todo
esto se hace desde GitHub, sin instalar Java ni Flutter en tu ordenador:

1. Ve a tu repositorio en GitHub → **Settings** → **Secrets and variables**
   → **Actions** → "New repository secret", y crea estos 3 secrets (te los
   inventas tú, apúntalos en un sitio seguro — un gestor de contraseñas,
   por ejemplo):
   - `KEYSTORE_PASSWORD`: una contraseña larga, por ejemplo generada por tu
     gestor de contraseñas.
   - `KEY_PASSWORD`: puede ser la misma que la anterior.
   - `KEY_ALIAS`: un nombre corto, por ejemplo `mifir`.
2. Ve a la pestaña **Actions** → en la lista de workflows de la izquierda
   pulsa **"Generar clave de firma (solo una vez)"** → botón "Run workflow"
   → "Run workflow" de nuevo para confirmar.
3. Cuando termine (círculo verde), entra en esa ejecución y descarga el
   artefacto `mifir-keystore` (al final de la página). Descomprímelo: dentro
   hay dos archivos.
   - `upload-keystore.jks`: **esta es tu clave real. Guárdala para
     siempre** en un sitio seguro con copia de seguridad (Google Drive,
     por ejemplo) — sin ella no podrás publicar futuras actualizaciones.
   - `keystore-base64.txt`: un archivo de texto con un contenido larguísimo
     en una sola línea.
4. Abre `keystore-base64.txt`, copia todo su contenido, y crea un 4º
   secret en GitHub llamado `KEYSTORE_BASE64` pegando ahí ese contenido.
5. Ve a la pestaña **Actions** → **"Build APK"** → "Run workflow". Esta vez
   el build detectará los secrets y firmará la app con tu clave real. Verás
   en el registro del paso "Preparar la firma de release" el mensaje "Firma
   de release configurada."
6. Al terminar, descarga el artefacto `fir-test-aab` (el archivo
   `app-release.aab`) — este es el que subes a Play Console. El artefacto
   `fir-test-apk` sigue estando disponible para instalar y probar
   directamente en un móvil.

Puedes borrar el workflow "Generar clave de firma" (o dejarlo, no hace
nada a menos que lo ejecutes) una vez tengas tu keystore guardado.

## Cómo abrir y ejecutar el proyecto

Necesitas tener [Flutter](https://docs.flutter.dev/get-started/install)
instalado en tu ordenador (con Android Studio o el Android SDK configurado).
Este entorno de trabajo en la nube no tiene acceso para descargar el SDK de
Flutter, así que el proyecto no se ha podido compilar aquí — pero el código
está completo y lo puedes ejecutar tal cual en tu máquina:

```bash
cd fir_test
flutter pub get
flutter run          # para probarlo en un emulador o móvil conectado
```

Si al abrir el proyecto Flutter te da algún problema con la carpeta
`android/` (por ejemplo, por una versión de Gradle/AGP distinta a la que
tengas instalada), la forma más segura es:

```bash
flutter create --platforms=android --org com.mariabenitonutricion fir_test_new
# copia lib/, pubspec.yaml y assets/ de este proyecto dentro de fir_test_new
cd fir_test_new
flutter pub get
flutter run
```

## Cómo generar el APK/AAB para subir a Play Store

Ver la sección "Firmar la app para Play Store" más arriba — todo el proceso
de firma y generación del `.aab` se hace desde el workflow de GitHub
Actions, sin instalar nada en tu ordenador. Solo necesitas una cuenta de
desarrollador de Google Play (cuota única de inscripción) para subir el
`.aab` que descargas del workflow.

## Estructura del proyecto

```
lib/
  models/question.dart          Modelo de datos de una pregunta
  data/question_repository.dart Carga el JSON y filtra por asignatura/año
  services/progress_service.dart Guarda localmente las preguntas falladas y estadísticas
  screens/                      Pantallas: inicio, elegir asignatura/año, test, resultados
  widgets/count_selector.dart    Selector de "cuántas preguntas quiero hacer"
assets/data/fir_questions.json  Banco de preguntas (no lo modifiques a mano; ver abajo)
android/                        Proyecto Android estándar (nombre app "MiFIR")
```

## Actualizar el banco de preguntas más adelante

Todo el dataset vive en `assets/data/fir_questions.json` como una lista de
objetos con esta forma:

```json
{
  "id": 1,
  "year": 2021,
  "qnum": 1,
  "subject": "Química Farmacéutica",
  "question": "¿Qué ventaja tiene el empleo de aciloximetilésteres...?",
  "options": ["Disminuye la velocidad...", "Aumenta la estabilidad...", "...", "..."],
  "answerIndex": 2,
  "annulled": false,
  "explanation": "Los profármacos son...",
  "hasExplanation": true,
  "source": "comentado2122"
}
```

Si más adelante me pasas las explicaciones de 2022-2024, o el cuadernillo
completo de 2020, puedo regenerar este fichero y me basta con que sustituyas
`assets/data/fir_questions.json` por la versión nueva — la app no necesita
ningún otro cambio.
