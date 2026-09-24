<?php

namespace Tests\Feature;

use App\Models\Usuario;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\{DB,Schema};
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ExportarUsuariosTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        config(['database.default'=>'sqlite','database.connections.sqlite.database'=>':memory:',
            'database.connections.sqlite.url'=>null,'cache.default'=>'array']);
        DB::purge('sqlite');
        Schema::create('empresas', function (Blueprint $t) { $t->id(); });
        DB::table('empresas')->insert([['id'=>1],['id'=>2]]);
        (require database_path('migrations/2026_08_21_224236_create_usuarios.php'))->up();
        foreach ([1,2] as $id) {
            DB::table('usuarios')->insert(['id'=>$id,'nombres'=>$id === 1 ? '=1+1' : 'Otra empresa',
                'apellidos'=>'Prueba','apodo'=>'Prueba','genero'=>'Varon','correo'=>"persona$id@example.test",
                'password_hash'=>'SECRETO-NO-EXPORTAR','tipo_documento'=>'DNI','numero_documento'=>'00123456',
                'telefono'=>'999999999','fecha_registro'=>'2026-01-01','fecha_nacimiento'=>'2000-01-01',
                'tipo_usuario'=>'Empresa','estado'=>1,'id_empresas'=>$id]);
        }
    }

    private function actor(string $tipo, bool $activo = true, ?int $empresa = 1): void
    {
        $actor = Usuario::findOrFail(1);
        $actor->tipo_usuario = $tipo;
        $actor->estado = $activo;
        $actor->id_empresas = $empresa;
        Sanctum::actingAs($actor, ['sesion']);
    }

    public function test_empresa_solo_descarga_sus_usuarios_sin_secrets_ni_formulas(): void
    {
        $this->actor('Empresa');
        $respuesta = $this->get('/api/usuarios/exportar?id_empresas=2&tipo_usuario=Administrador')->assertOk();
        $respuesta->assertDownload();
        $csv = $respuesta->streamedContent();
        $this->assertStringStartsWith("\xEF\xBB\xBF", $csv);
        $this->assertStringContainsString('persona1@example.test', $csv);
        $this->assertStringNotContainsString('persona2@example.test', $csv);
        $this->assertStringNotContainsString('password_hash', $csv);
        $this->assertStringNotContainsString('SECRETO-NO-EXPORTAR', $csv);
        $this->assertStringContainsString("'=1+1", $csv);
        $this->assertStringContainsString('00123456', $csv);
    }

    public function test_administrador_descarga_todas_las_empresas_incluso_inactivos(): void
    {
        DB::table('usuarios')->where('id',2)->update(['estado'=>0]);
        $this->actor('Administrador');
        $csv = $this->get('/api/usuarios/exportar')->assertOk()->streamedContent();
        $this->assertStringContainsString('persona1@example.test', $csv);
        $this->assertStringContainsString('persona2@example.test', $csv);
    }

    public function test_rechaza_anonimo_roles_no_permitidos_e_inactivos(): void
    {
        $this->get('/api/usuarios/exportar')->assertUnauthorized();
        foreach (['Usuario','Entrenador'] as $tipo) {
            $this->actor($tipo);
            $this->get('/api/usuarios/exportar')->assertForbidden();
        }
        $this->actor('Empresa', false);
        $this->get('/api/usuarios/exportar')->assertForbidden();
    }

    public function test_empresa_sin_relacion_no_descarga_todos(): void
    {
        $this->actor('Empresa', true, null);
        $this->get('/api/usuarios/exportar')->assertForbidden();
        $this->actor('Empresa', true, 999);
        $this->get('/api/usuarios/exportar')->assertForbidden();
    }
}
