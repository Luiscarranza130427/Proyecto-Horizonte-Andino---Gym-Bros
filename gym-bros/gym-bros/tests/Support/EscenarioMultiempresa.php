<?php

namespace Tests\Support;

use App\Models\Usuario;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;

/**
 * Dos empresas con Administrador, Empresa, Entrenador y Usuarios, pagos,
 * rutinas y notificaciones en SQLite en memoria (todas las migraciones reales).
 */
trait EscenarioMultiempresa
{
    protected const ADMIN = 1;

    protected const EMPRESA_A = 2;

    protected const ENTRENADOR_A = 3;

    protected const USUARIO_A1 = 4;

    protected const USUARIO_A2 = 5;

    protected const EMPRESA_B = 6;

    protected const USUARIO_B1 = 7;

    protected function prepararEscenario(): void
    {
        config(['database.default' => 'sqlite', 'database.connections.sqlite.database' => ':memory:',
            'database.connections.sqlite.url' => null, 'cache.default' => 'array']);
        DB::purge('sqlite');
        Cache::flush();
        $this->assertSame(':memory:', DB::connection()->getDatabaseName());
        Artisan::call('migrate', ['--force' => true]);
        Storage::fake('public');

        $empresa = ['nombre_gerente' => 'Gerente QA', 'telefono' => '999999999', 'correo' => 'gym@qa.test',
            'estado' => true, 'fecha_registro' => '2026-09-01', 'logo' => 'empresas/logo.webp',
            'color_1' => '#111111', 'color_2' => '#eeeeee', 'banner_1' => 'empresas/b1.webp',
            'link_boton_1' => 'https://qa.test/1'];
        DB::table('empresas')->insert([['id' => 1, 'nombre' => '[QA] Empresa A'] + $empresa, ['id' => 2, 'nombre' => '[QA] Empresa B'] + $empresa]);

        $usuarios = [
            [self::ADMIN, 'Administrador', 1], [self::EMPRESA_A, 'Empresa', 1], [self::ENTRENADOR_A, 'Entrenador', 1],
            [self::USUARIO_A1, 'Usuario', 1], [self::USUARIO_A2, 'Usuario', 1], [self::EMPRESA_B, 'Empresa', 2],
            [self::USUARIO_B1, 'Usuario', 2],
        ];
        foreach ($usuarios as [$id, $rol, $empresaId]) {
            DB::table('usuarios')->insert(['id' => $id, 'nombres' => '[QA] '.$rol, 'apellidos' => 'Usuario '.$id,
                'apodo' => 'qa'.$id, 'genero' => 'Varon', 'correo' => "qa{$id}@gymbros.test",
                'password_hash' => Hash::make('ClaveQa123!'), 'tipo_documento' => 'DNI', 'numero_documento' => '0000000'.$id,
                'telefono' => '900000000', 'fecha_registro' => '2026-09-01', 'fecha_nacimiento' => '1995-01-01',
                'tipo_usuario' => $rol, 'estado' => true, 'id_empresas' => $empresaId,
                'foto_perfil' => 'C:\\laragon\\www\\gym-bros\\storage\\app\\public\\usuario\\foto'.$id.'.jpg']);
        }

        DB::table('planes')->insert(['id' => 1, 'nombre' => 'Plan QA', 'descripcion' => 'QA', 'precio_original' => 100,
            'precio_inicial' => 90, 'duracion_dias' => 30, 'limite_usuarios' => 50, 'activo' => true, 'enlace_whatsapp' => 'https://qa.test']);
        foreach ([1 => 1, 2 => 2] as $id => $empresaId) {
            DB::table('suscripciones')->insert(['id' => $id, 'id_empresas' => $empresaId, 'id_planes' => 1,
                'fecha_inicio' => '2026-09-01', 'fecha_fin' => '2026-09-30', 'estado' => 'activa', 'renovacion_automatica' => false]);
            DB::table('pagos')->insert(['id' => $id, 'id_empresas' => $empresaId, 'id_suscripciones' => $id, 'monto' => 90,
                'moneda' => 'PEN', 'metodo_pago' => 'tarjeta', 'referencia' => 'QA-'.$id, 'estado' => 'aprobado', 'fecha_pago' => '2026-09-01']);
        }
        foreach ([self::USUARIO_A1, self::USUARIO_B1] as $id) {
            DB::table('rutinas')->insert(['id' => $id, 'id_usuarios' => $id, 'nombre' => '[QA] Rutina '.$id, 'descripcion' => 'QA', 'objetivo' => 'salud',
                'dias_semana' => 3, 'duracion_estimada' => 60, 'fecha_inicio' => '2026-09-01', 'fecha_fin' => '2026-12-01', 'estado' => true]);
        }
        DB::table('notificaciones')->insert([
            ['id' => 1, 'id_empresas' => 1, 'id_usuarios' => self::USUARIO_A1, 'tipo' => 'recordatorio', 'titulo' => 'Para A1', 'mensaje' => 'QA', 'fecha_envio' => '2026-09-01', 'leida' => 0, 'enviada' => 1],
            ['id' => 2, 'id_empresas' => 2, 'id_usuarios' => self::USUARIO_B1, 'tipo' => 'recordatorio', 'titulo' => 'Para B1', 'mensaje' => 'QA', 'fecha_envio' => '2026-09-01', 'leida' => 0, 'enviada' => 1],
            ['id' => 3, 'id_empresas' => 1, 'id_usuarios' => null, 'tipo' => 'recordatorio', 'titulo' => 'General A', 'mensaje' => 'QA', 'fecha_envio' => '2026-09-01', 'leida' => 0, 'enviada' => 1],
        ]);
    }

    protected function como(int $id): Usuario
    {
        $this->app['auth']->forgetGuards();
        $usuario = Usuario::findOrFail($id);
        Sanctum::actingAs($usuario, ['sesion']);

        return $usuario;
    }

    protected function ids(string $uri): array
    {
        return collect($this->getJson($uri)->assertOk()->json('data'))->pluck('id')->sort()->values()->all();
    }
}
