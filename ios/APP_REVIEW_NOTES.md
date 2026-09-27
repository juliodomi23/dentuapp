# App Review: acceso personal y acceso Dentu

## Preparación antes de enviar la compilación

1. Desplegar **esta versión** del backend y comprobar que la URL compilada en `API_URL` apunta a ella. La URL predeterminada está en `lib/config/app_config.dart`.
2. Configurar `OPENROUTER_API_KEY` en el backend. Sin ella, la importación de PDF e imágenes devuelve 503. Mantener `OPENROUTER_DIET_MODEL=openai/gpt-4o` salvo que se haya probado otro modelo.
3. Crear desde el panel un paciente clínico de prueba, con plan semanal y registros ficticios. Configurar `DEMO_REVIEWER_PHONE` (su teléfono de 10 dígitos) y `DEMO_REVIEWER_CODE` (6 dígitos) en el backend. Ese par permite entrar varias veces sin consumir el código; no usar datos de un paciente real.
4. Probar ambos accesos en un iPhone con la misma compilación que se enviará. Registrar una comida, agua, tipo de ejercicio y calorías del reloj; importar el PDF de muestra, revisar y guardar; comprobar el borrado de la cuenta personal.
5. Adjuntar `ReviewSampleDiet.pdf` en la sección **Attachments** de App Store Connect. Sustituir los marcadores entre corchetes de la nota siguiente por el teléfono y código reales. Mantener el backend y la cuenta de prueba activos durante toda la revisión.
6. Revisar en App Store Connect la ficha de privacidad y la URL pública del aviso para que reflejen el acceso personal, los datos de salud y el envío temporal del documento al proveedor de inteligencia artificial.
7. Crear la suscripción mensual `com.ambarrojo.dentu.personal.monthly`, probar compra y restauración con Sandbox y configurar `APPLE_SHARED_SECRET` + `APPLE_IAP_PRODUCT_IDS` en el backend. Activar `APPLE_IAP_REQUIRED=true` solamente después de que esa prueba pase.
8. Crear una cuenta personal precargada para revisión y poner su correo en `APPLE_IAP_REVIEW_EMAIL`; así Apple puede probar el import sin comprar. Entregar ese correo y contraseña junto con el acceso clínico `9611000099 / 123456`.

## Texto para pegar en Review Notes (inglés)

```text
Dentu has two sign-in paths on the first screen:

1. "Soy paciente de Dentu" > "Entrar con código" is for patients whose nutrition plan is managed by the Dentu clinic. For review, use phone [10-DIGIT DEMO PHONE] and six-digit code [DEMO CODE]. This demo account has a sample weekly plan and can be used repeatedly. Accept the data consent, then enter the phone and code.

2. "Tengo mi propia dieta" > "Usar mi dieta" is for people who are not Dentu clinic patients. Accept the separate consent, create a personal account with an email address and password of at least eight characters, open "Semana", and tap the import action. Select the attached ReviewSampleDiet.pdf, wait for the weekly draft, check or edit the meals, and tap "Guardar y usar este plan". The plan then appears in Semana and Hoy. The reviewer can log meals, water and exercise; on the Exercise screen they can enter the activity, minutes and active calories shown by a smartwatch. The app currently supports manual entry of smartwatch calories; it does not read HealthKit data.

The import service transcribes the user's existing diet. It does not prescribe a new diet. The user reviews and confirms the extracted text before it becomes their plan. Personal accounts are separate from Dentu clinic patient records. Personal account deletion is available in Perfil > Borrar cuenta. For clinic-linked accounts, the same action removes app-origin data while the clinic retains its clinical record.

The backend, demo clinical account and document import service are active for review. If access fails, contact [REVIEW CONTACT EMAIL/PHONE].

The personal review account [PERSONAL REVIEW EMAIL] is preloaded and exempt from payment for App Review. The normal customer path presents the monthly auto-renewable subscription and supports Restore Purchases. Apple sandbox testers can also complete the purchase flow without a real charge.
```

## Alcance de la explicación a Apple

El acceso por correo y contraseña propio de la app y el código de la clínica son métodos internos; no se ofrece inicio de sesión social. Si se añade Google, Facebook u otro proveedor externo, volver a evaluar la regla 4.8 de Apple. Apple pide acceso completo para revisar funciones con sesión y que los servicios estén disponibles durante la revisión. También exige una opción de eliminación de cuenta cuando la app permite crearla. Referencias: [App Review](https://developer.apple.com/app-store/review/), [directrices](https://developer.apple.com/app-store/review/guidelines/es/) y [eliminación de cuenta](https://developer.apple.com/support/offering-account-deletion-in-your-app).

No enviar una ficha que prometa lectura automática del reloj: en esta versión se captura el valor que la persona ve en su smartwatch.
