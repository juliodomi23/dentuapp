# Checklist en Mac: build 2, iPhone y App Store Connect

## Decisión de producto aplicada

El código está preparado para una **suscripción mensual** que desbloquea la importación de dietas. Es la opción recomendada porque la transcripción con OpenRouter genera costo recurrente y porque Apple permite restaurar una suscripción en otro dispositivo.

Antes de crear el producto, los dueños deben confirmar el precio. Si prefieren pago único por importación, hay que cambiar el modelo antes de crear el Product ID en App Store Connect.

## 1. Actualizar y preparar el proyecto

```bash
git pull origin main
flutter pub get
cd ios
pod install
open Runner.xcworkspace
```

Usar siempre `Runner.xcworkspace` después de instalar Pods. El bundle ID esperado es `com.ambarrojo.dentu.dentuApp` y este código tiene versión `1.0.0`, build `2`.

## 2. Crear la suscripción en App Store Connect

1. Abrir Dentu > Monetization > Subscriptions.
2. Crear el grupo `Dentu Personal`.
3. Crear una suscripción auto-renovable mensual:
   - Reference Name: `Dentu Personal Mensual`
   - Product ID: `com.ambarrojo.dentu.personal.monthly`
   - Duration: `1 Month`
   - Display Name: `Dentu Personal`
   - Description: `Importa tu dieta en PDF o foto y organízala como plan semanal.`
4. Definir el precio aprobado por los dueños, disponibilidad y localización en español de México.
5. Subir una captura de la pantalla de suscripción para App Review.
6. Generar el App-Specific Shared Secret y guardarlo como `APPLE_SHARED_SECRET` en EasyPanel.

## 3. Variables del backend

Primero desplegar con:

```text
OPENROUTER_API_KEY=<secreto>
OPENROUTER_DIET_MODEL=openai/gpt-4o
OPENROUTER_APP_URL=https://www.dentu.mx
APPLE_IAP_REQUIRED=false
APPLE_IAP_PRODUCT_IDS=com.ambarrojo.dentu.personal.monthly
APPLE_SHARED_SECRET=<secreto de App Store Connect>
APPLE_IAP_REVIEW_EMAIL=<correo de la cuenta personal demo>
DEMO_REVIEWER_PHONE=9611000099
DEMO_REVIEWER_CODE=123456
```

Después de completar la compra sandbox y Restore Purchases, cambiar `APPLE_IAP_REQUIRED=true` y volver a desplegar.

## 4. Prueba en iPhone físico

1. Seleccionar el iPhone como destino en Xcode y ejecutar la app.
2. Cuenta personal: crear/iniciar sesión, importar `ReviewSampleDiet.pdf`, editar una comida y guardar.
3. Repetir con una foto HEIC tomada por ese iPhone.
4. Con IAP activo: comprar con Sandbox, cerrar sesión, volver a entrar y usar `Restaurar compras`.
5. Cuenta Dentu: entrar con `9611000099 / 123456`; comprobar plan, comida, agua, ejercicio, peso y síntomas.
6. Borrar una cuenta personal de prueba y confirmar que ya no puede iniciar sesión.

## 5. Envío

1. Archivar desde Xcode con el esquema Runner en Release.
2. Subir build 2 a App Store Connect.
3. Adjuntar `ReviewSampleDiet.pdf` y pegar el texto de `APP_REVIEW_NOTES.md` con los marcadores reemplazados.
4. Mantener backend, cuenta clínica demo y cuenta personal demo activos durante toda la revisión.
