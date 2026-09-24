<?php

use App\Http\Controllers\AlimentacionController;
use App\Http\Controllers\AlimentoController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\BannerController;
use App\Http\Controllers\CheckoutController;
use App\Http\Controllers\ComidaAlimentoController;
use App\Http\Controllers\EjercicioController;
use App\Http\Controllers\EjercicioGrupoMuscularController;
use App\Http\Controllers\EjercicioRutinaController;
use App\Http\Controllers\EmpresaController;
use App\Http\Controllers\EmpresaEjercicioController;
use App\Http\Controllers\EvaluacionFisicaController;
use App\Http\Controllers\GrupoMuscularController;
use App\Http\Controllers\HistorialCambioController;
use App\Http\Controllers\ImportarUsuariosController;
use App\Http\Controllers\NotificacionController;
use App\Http\Controllers\PagoController;
use App\Http\Controllers\PasswordRecoveryController;
use App\Http\Controllers\PlanAlimentacionController;
use App\Http\Controllers\PlanController;
use App\Http\Controllers\PreferenciaAlimentariaController;
use App\Http\Controllers\ProgresoController;
use App\Http\Controllers\ResumenWebController;
use App\Http\Controllers\RutinaController;
use App\Http\Controllers\SensacionController;
use App\Http\Controllers\SolicitudDemoController;
use App\Http\Controllers\SuscripcionController;
use App\Http\Controllers\UsuarioController;
use App\Http\Middleware\AlimentacionDisponible;
use App\Http\Middleware\AutorizarUsuarioAlimentacion;
use App\Http\Middleware\CheckoutJson;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Rutas publicas
|--------------------------------------------------------------------------
| Solo lo que necesita un visitante sin sesion: iniciar sesion, recuperar la
| contrasena, pedir una demo, ver la oferta comercial y comprar un plan.
*/
Route::middleware(['sesion:publico', 'throttle:recuperacion-password'])->group(function () {
    Route::post('/auth/forgot-password', [PasswordRecoveryController::class, 'forgot']);
    Route::post('/auth/reset-password', [PasswordRecoveryController::class, 'reset']);
});
Route::post('/auth/login', [AuthController::class, 'login'])->middleware(['sesion:publico', 'throttle:login-sesion']);
Route::post('/solicitudes-demo', [SolicitudDemoController::class, 'store'])->middleware('throttle:solicitudes-demo');
Route::get('/planes', [PlanController::class, 'index']);
Route::get('/planes/{id_plan}', [PlanController::class, 'show'])->whereNumber('id_plan');

Route::middleware([CheckoutJson::class])->group(function () {
    Route::post('/checkout/mercado-pago', [CheckoutController::class, 'store'])->middleware('throttle:10,1');
    Route::get('/checkout/{orden_uuid}/estado', [CheckoutController::class, 'estado'])->whereUuid('orden_uuid')->middleware('throttle:60,1');
    Route::post('/webhooks/mercado-pago', [CheckoutController::class, 'webhook'])->middleware('throttle:120,1');
    Route::post('/checkout/login', [CheckoutController::class, 'login'])->middleware('throttle:5,1');
    Route::post('/checkout/{orden_uuid}/password', [CheckoutController::class, 'password'])->whereUuid('orden_uuid')->name('checkout.password')->middleware('throttle:5,1');
    Route::post('/pagos/{pago}/reembolso', [CheckoutController::class, 'reembolso'])->whereNumber('pago')->middleware(['auth:sanctum', 'throttle:5,1']);
});

/*
|--------------------------------------------------------------------------
| Rutas con sesion
|--------------------------------------------------------------------------
| `sesion` exige un token Sanctum valido de una cuenta activa. `acceso`
| comprueba rol y pertenencia del usuario o empresa de la URL.
*/
Route::middleware(['sesion', 'throttle:api-sesion'])->group(function () {
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::post('/perfil/cambiar-contrasena', [AuthController::class, 'cambiarContrasena'])->middleware('throttle:5,1');
    Route::post('/perfil/cerrar-otras-sesiones', [AuthController::class, 'cerrarOtrasSesiones']);

    // Empresas
    Route::get('/empresas', [EmpresaController::class, 'index']);
    Route::post('/empresas', [EmpresaController::class, 'store'])->middleware('acceso:rol,Administrador');
    Route::get('/empresas/{empresas}', [EmpresaController::class, 'show'])->whereNumber('empresas')->middleware('acceso:empresa,ver');
    Route::put('/empresas/{id_empresa}', [EmpresaController::class, 'update'])->whereNumber('id_empresa')->middleware('acceso:empresa,gestionar');
    Route::delete('/empresas/{id_empresa}', [EmpresaController::class, 'destroy'])->whereNumber('id_empresa')->middleware('acceso:rol,Administrador');
    Route::post('/empresas/{id_empresa}/logo', [EmpresaController::class, 'actualizarLogo'])->whereNumber('id_empresa')->middleware('acceso:empresa,gestionar');
    Route::put('/empresas/{id_empresa}/personalizacion', [EmpresaController::class, 'actualizarPersonalizacion'])->whereNumber('id_empresa')->middleware('acceso:empresa,gestionar');
    Route::put('/empresas/{id_empresa}/ejercicios/{id_ejercicio}/estado', [EmpresaEjercicioController::class, 'update'])
        ->whereNumber('id_empresa')->whereNumber('id_ejercicio')->middleware('acceso:empresa,gestionar');
    Route::put('/empresa/banners/{id_empresa}', [EmpresaController::class, 'updateBanners'])->whereNumber('id_empresa')->middleware('acceso:empresa,gestionar');
    Route::get('/empresa/banners/{id_usuario}', [EmpresaController::class, 'banners'])->whereNumber('id_usuario')->middleware('acceso:usuario,seguir');

    // Usuarios
    Route::get('/usuarios', [UsuarioController::class, 'index']);
    Route::post('/usuarios', [UsuarioController::class, 'store'])->middleware('acceso:rol,Administrador,Empresa');
    Route::middleware(['acceso:rol,Administrador,Empresa', 'throttle:5,1'])->group(function () {
        Route::get('/usuarios/importar/plantilla', [ImportarUsuariosController::class, 'plantilla']);
        Route::post('/usuarios/importar', [ImportarUsuariosController::class, 'store']);
        Route::get('/usuarios/exportar', [UsuarioController::class, 'exportar']);
    });
    Route::get('/usuarios/{id_usuario}', [UsuarioController::class, 'show'])->whereNumber('id_usuario')->middleware('acceso:usuario,seguir');
    Route::put('/usuarios/{id_usuario}', [UsuarioController::class, 'update'])->whereNumber('id_usuario')->middleware('acceso:usuario,gestionar');
    Route::put('/usuarios/{id_usuario}/estado', [UsuarioController::class, 'actualizarEstado'])->whereNumber('id_usuario')->middleware('acceso:usuario,administrar');
    Route::post('/usuarios/{id_usuario}/foto-perfil', [UsuarioController::class, 'actualizarFoto'])->whereNumber('id_usuario')->middleware('acceso:usuario,gestionar');
    Route::get('/usuarios/{id_usuario}/empresa', [UsuarioController::class, 'empresaUsuario'])->whereNumber('id_usuario')->middleware('acceso:usuario,seguir');
    Route::get('/usuarios/{id_usuario}/historial', [UsuarioController::class, 'historial'])->whereNumber('id_usuario')->middleware('acceso:usuario,gestionar');
    Route::get('/usuarios/{id_usuario}/resumen-web', [ResumenWebController::class, 'index'])->whereNumber('id_usuario')->middleware('acceso:usuario,seguir');

    // Evaluaciones fisicas
    Route::get('/evaluacionesfisicas', [EvaluacionFisicaController::class, 'index']);
    Route::middleware('acceso:usuario,seguir')->group(function () {
        Route::post('/usuarios/{id_usuario}/evaluaciones', [EvaluacionFisicaController::class, 'store'])->whereNumber('id_usuario');
        Route::put('/usuarios/{id_usuario}/evaluaciones/ultima', [EvaluacionFisicaController::class, 'update'])->whereNumber('id_usuario');
        Route::get('/usuarios/{id_usuario}/evaluaciones/perfil', [EvaluacionFisicaController::class, 'perfil'])->whereNumber('id_usuario');
        Route::get('/usuarios/{id_usuario}/evaluaciones/peso-grasa', [EvaluacionFisicaController::class, 'pesoGrasa'])->whereNumber('id_usuario');
    });

    // Ejercicios y grupos musculares (catalogo)
    Route::get('/ejercicios', [EjercicioController::class, 'index']);
    Route::post('/ejercicios', [EjercicioController::class, 'store'])->middleware('acceso:rol,Administrador,Empresa,Entrenador');
    Route::get('/ejercicios/{id_ejercicio}', [EjercicioController::class, 'show'])->whereNumber('id_ejercicio');
    Route::middleware('acceso:rol,Administrador')->group(function () {
        // PUT llega como POST con _method=PUT: PHP no interpreta multipart en PUT.
        Route::put('/ejercicios/{id_ejercicio}', [EjercicioController::class, 'update'])->whereNumber('id_ejercicio');
        Route::delete('/ejercicios/{id_ejercicio}', [EjercicioController::class, 'destroy'])->whereNumber('id_ejercicio');
    });
    Route::get('/ejerciciogruposMusculares', [EjercicioGrupoMuscularController::class, 'index']);
    Route::get('/gruposmusculares', [GrupoMuscularController::class, 'index']);
    Route::get('/gruposmusculares/tipos', [GrupoMuscularController::class, 'tipos']);

    // Rutinas
    Route::get('/rutinas', [RutinaController::class, 'index']);
    Route::get('/ejerciciorutinas', [EjercicioRutinaController::class, 'index']);
    Route::middleware('acceso:usuario,seguir')->group(function () {
        Route::post('/rutinas/generar/{id_usuario}', [RutinaController::class, 'generar'])->whereNumber('id_usuario');
        Route::get('/rutinas/generar/{id_usuario}/estado', [RutinaController::class, 'estadoGeneracion'])->whereNumber('id_usuario');
        Route::get('/usuarios/{id_usuario}/rutinas/{id_rutina}/sesiones/{dia}', [RutinaController::class, 'sesion'])
            ->whereNumber(['id_usuario', 'id_rutina', 'dia']);
    });

    // Alimentacion
    Route::get('/alimentos', [AlimentoController::class, 'index']);
    Route::middleware('acceso:rol,Administrador')->group(function () {
        Route::post('/alimentos', [AlimentoController::class, 'store']);
        Route::put('/alimentos/{id_alimento}', [AlimentoController::class, 'update'])->whereNumber('id_alimento');
        Route::delete('/alimentos/{id_alimento}', [AlimentoController::class, 'destroy'])->whereNumber('id_alimento');
    });
    Route::get('/comidaAlimentos', [ComidaAlimentoController::class, 'index']);
    Route::get('/planesalimentacion', [PlanAlimentacionController::class, 'index']);
    Route::get('/preferenciasalimentarias', [PreferenciaAlimentariaController::class, 'index']);
    Route::middleware([AlimentacionDisponible::class, AutorizarUsuarioAlimentacion::class])->group(function () {
        Route::get('/usuarios/{id_usuario}/plan-alimentacion', [PlanAlimentacionController::class, 'ultimoPorUsuario'])
            ->whereNumber('id_usuario')->name('usuarios.plan-alimentacion');
        Route::post('/planesalimentacion/generar/{id_usuario}', [PlanAlimentacionController::class, 'generar'])->whereNumber('id_usuario');
        Route::get('/usuarios/{id_usuario}/planesalimentacion/{id_plan}', [PlanAlimentacionController::class, 'detalle'])->whereNumber(['id_usuario', 'id_plan']);
        Route::get('/usuarios/{id_usuario}/perfil-alimentario', [AlimentacionController::class, 'perfil'])->whereNumber('id_usuario');
        Route::put('/usuarios/{id_usuario}/perfil-alimentario', [AlimentacionController::class, 'guardarPerfil'])->whereNumber('id_usuario');
        Route::put('/alimentos/{id_alimento}/nutricion', [AlimentacionController::class, 'nutricion'])->whereNumber('id_alimento')
            ->middleware('acceso:rol,Administrador');
    });

    // Seguimiento
    Route::get('/progresos', [ProgresoController::class, 'index']);
    Route::get('/sensaciones', [SensacionController::class, 'index']);
    Route::get('/historialcambios', [HistorialCambioController::class, 'index'])->middleware('acceso:rol,Administrador,Empresa');

    // Notificaciones y banners
    Route::get('/notificaciones', [NotificacionController::class, 'index']);
    Route::get('/notificaciones/activas', [NotificacionController::class, 'notificacionesActivas']);
    Route::middleware('acceso:rol,Administrador,Empresa,Entrenador')->group(function () {
        Route::get('/notificaciones/programadas', [NotificacionController::class, 'programadas']);
        Route::post('/notificaciones', [NotificacionController::class, 'store'])->middleware('throttle:30,1');
        Route::post('/notificaciones/{id}/enviar-ahora', [NotificacionController::class, 'enviarAhora'])->whereNumber('id');
        Route::delete('/notificaciones/{id}', [NotificacionController::class, 'destroy'])->whereNumber('id');
    });
    Route::get('/banners', [BannerController::class, 'index']);
    Route::middleware('acceso:rol,Administrador')->group(function () {
        Route::post('/banners', [BannerController::class, 'store']);
        Route::put('/banners/{id_banner}', [BannerController::class, 'update'])->whereNumber('id_banner');
        Route::delete('/banners/{id_banner}', [BannerController::class, 'destroy'])->whereNumber('id_banner');
    });

    // Planes, suscripciones y pagos
    Route::middleware('acceso:rol,Administrador')->group(function () {
        Route::post('/planes', [PlanController::class, 'store']);
        Route::put('/planes/{id_plan}', [PlanController::class, 'update'])->whereNumber('id_plan');
        Route::delete('/planes/{id_plan}', [PlanController::class, 'destroy'])->whereNumber('id_plan');
    });
    Route::middleware('acceso:rol,Administrador,Empresa')->group(function () {
        Route::get('/suscripciones', [SuscripcionController::class, 'index']);
        Route::get('/pagos', [PagoController::class, 'index']);
        Route::get('/pagos/metricas', [PagoController::class, 'metricas']);
        Route::get('/pagos/{id_pago}', [PagoController::class, 'show'])->whereNumber('id_pago');
    });
});
