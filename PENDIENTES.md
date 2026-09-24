# Pendientes — Gym Bros

Estado al 24/09/2026. La API, el panel y la app móvil pasan sus pruebas, su análisis
y su build. Lo de abajo es lo que quedó para después, a propósito.

## 1. Pagos (Mercado Pago)

- [ ] Integrar la API de Mercado Pago en el checkout.
  - El flujo actual de checkout **no se tocó**; se integrará sobre esa lógica.
  - No se hizo ninguna transacción real durante las pruebas.

## 2. App móvil (`gym_bros_mobile-main`)

- [ ] **Mantener la sesión al reabrir la app** (decisión de producto).
  - Hoy el token se guarda en `flutter_secure_storage` (`auth_token`), pero nunca
    se lee: la app siempre abre en el login.
  - Propuesta: al iniciar, leer el token, llamar `GET /api/auth/me`; si responde
    200, ir directo al inicio; si 401, borrar el token y mostrar el login.
  - El token dura 8 horas (Sanctum, `sanctum:prune-expired` diario).
- [ ] **Compilar para un teléfono físico** (el APK de depuración solo llega al
      emulador por `10.0.2.2`):
  ```bash
  flutter build apk --debug --dart-define=API_BASE_URL=http://<IP-del-PC>:8000
  ```
- [ ] **Build de producción (release)**
  - Instalar las `cmdline-tools` de Android (Android Studio → SDK Manager) y
    aceptar licencias: `flutter doctor --android-licenses`.
  - Tener la API publicada con **HTTPS** (release rechaza HTTP a propósito).
  - Compilar:
    ```bash
    flutter build apk --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://<dominio-api>
    ```
- [ ] Si se publica la app **en web**: el servidor de la API debe enviar
      `Access-Control-Allow-Origin` en `/storage/` o las imágenes (ejercicios,
      fotos, logos, banners) no cargan. Ver `gym-bros/gym-bros/docs/despliegue-produccion.md`.
      En desarrollo ya lo hace `scripts/router-dev.php`.
- [ ] Probar en dispositivo real los flujos que escriben datos (no se ejecutaron
      contra la base real para no modificarla): generar rutina, generar plan de
      alimentación, registrar/editar evaluación, editar datos personales y foto.
- [ ] Planes de alimentación antiguos: el listado global (solo en desarrollo)
      muestra un plan sin `calculo` que al abrirlo responde 404. En producción ese
      listado está desactivado; decidir si se migran o se ocultan esos planes.

### Catálogo para generar planes y rutinas (corregido el 24/09/2026)

- Ya aplicado con `CatalogoAlimentosRealSeeder` y `EjerciciosCardioSeeder`
  (respaldo previo de las tablas en la carpeta temporal de la sesión):
  los 35 alimentos reales quedaron listos para el generador y los 18 «[DEMO]»
  desactivados (no borrados); se añadieron 4 ejercicios de cardio.
- [ ] **Que un nutricionista revise el catálogo.** Los nutrientes son de USDA
      FoodData Central por 100 g y se marcaron como verificados; las porciones
      mínimas/máximas y en qué comidas va cada alimento son criterio técnico.
- [ ] Subir imágenes y videos reales de los ejercicios desde el panel: 34 de 39
      usan la imagen genérica `trabajar-musculo.webp` y el cardio no tiene video.
- [ ] Los planes ya generados antes de la corrección conservan sus alimentos
      «[DEMO]» (son históricos). Generar uno nuevo para ver solo alimentos reales.
- [ ] Móvil: avisar al elegir días de entrenamiento que no permiten descanso
      (p. ej. 3 días de cuerpo completo en lunes y martes). Hoy el error
      aparece recién al generar la rutina.
- [ ] La empresa 3 no tiene ejercicios asignados: sus usuarios no pueden
      generar rutina hasta que se le asigne catálogo.

## 3. Panel web (`gym-bros-panel`)

- [ ] **Componentes huérfanos** (no los importa nadie; todos del commit `5fdc2eb`).
      Confirmar si alguno se usará y borrar el resto:
  - `src/app/layouts/AppLayout.vue` (el router usa `DashboardLayout.vue`)
  - `src/modules/alimentacion/components/PlanFilters.vue`
  - `src/modules/alimentacion/components/PlanTable.vue`
  - `src/modules/billing/components/PagosFilters.vue`
  - `src/modules/dashboard/components/PopularExercises.vue`
  - `src/modules/dashboard/components/ProgressChart.vue`
  - `src/modules/dashboard/components/RecentActivity.vue`
  - `src/modules/usuarios/components/UsuarioSubscriptionBadge.vue`
  - `src/shared/components/IconoMancuerna.vue`
  - `src/shared/components/LogoGymBros.vue` — además importa
    `gym-bros-lockup.svg`, que **no existe** (solo hay `.webp`); por eso la
    cobertura muestra «Failed to parse … LogoGymBros.vue».
  - Tras borrarlos: `npm run lint`, `npm run format:check`,
    `npm run test:coverage`, `npm run build`, y subir los umbrales de
    `vitest.config.js` a 1–2 puntos por debajo de lo medido.
- [ ] Probar en vivo los formularios que envían correos o notificaciones reales
      (alta de usuario → correo de activación; «Redactar» notificación). Están
      cubiertos por pruebas automáticas, pero no se enviaron de verdad.

## 4. API / despliegue (`gym-bros/gym-bros`)

- [ ] Configurar el servidor de producción siguiendo
      `docs/despliegue-produccion.md` y `.env.production.example`:
  - `APP_ENV=production`, `APP_DEBUG=false`, `APP_URL` con HTTPS.
  - `CORS_ALLOWED_ORIGINS` con el dominio del panel.
  - `TRUSTED_PROXIES` si hay balanceador o proxy delante.
  - `php artisan storage:link`, `config:cache`, `route:cache`.
  - Cola (`queue:work`) y programador (`schedule:run` cada minuto).
- [ ] Configurar **SMTP real** y verificar de punta a punta el correo de
      recuperación de contraseña y el de activación de cuenta nueva.
- [ ] Verificar de punta a punta la generación real de rutinas y planes de
      alimentación en el servidor (solo se probó con pruebas automáticas).

## Cómo levantar todo en desarrollo

```bash
# MySQL (Laragon)
"C:\laragon\bin\mysql\mysql-8.0.30-winx64\bin\mysqld.exe" --defaults-file="C:\laragon\bin\mysql\mysql-8.0.30-winx64\my.ini" --standalone
```
```bash
# API en http://127.0.0.1:8000
powershell -NoProfile -ExecutionPolicy Bypass -File gym-bros/gym-bros/scripts/serve-dev.ps1 -Puerto 8000
```
```bash
# Panel en http://localhost:5173 (ejecutar desde PowerShell, no Git Bash)
npm --prefix gym-bros-panel run dev -- --host
```
```bash
# App móvil en el emulador
cd gym_bros_mobile-main && flutter run
```
