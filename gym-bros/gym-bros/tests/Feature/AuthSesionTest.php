<?php

namespace Tests\Feature;

use App\Models\Usuario;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\{Auth,Cache,DB,Hash,Schema};
use Tests\TestCase;

class AuthSesionTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        config(['database.default'=>'sqlite','database.connections.sqlite.database'=>':memory:',
            'database.connections.sqlite.url'=>null,'cache.default'=>'array']);
        DB::purge('sqlite'); Cache::flush();
        Schema::create('empresas', function (Blueprint $t) { $t->id(); });
        DB::table('empresas')->insert(['id'=>1]);
        (require database_path('migrations/2026_08_21_224236_create_usuarios.php'))->up();
        (require database_path('migrations/2026_09_22_195900_create_personal_access_tokens.php'))->up();
        DB::table('usuarios')->insert(['id'=>1,'nombres'=>'Prueba','apellidos'=>'Login','apodo'=>'QA','genero'=>'Varon',
            'correo'=>'Empresa@example.test','password_hash'=>Hash::make('ClavePrueba123!'),'tipo_documento'=>'DNI',
            'numero_documento'=>'00123456','telefono'=>'999999999','fecha_registro'=>'2026-01-01',
            'fecha_nacimiento'=>'2000-01-01','tipo_usuario'=>'Empresa','estado'=>1,'id_empresas'=>1]);
    }

    private function login()
    {
        Auth::forgetGuards();
        return $this->postJson('/api/auth/login',['correo'=>' EMPRESA@example.test ','password'=>'ClavePrueba123!']);
    }

    private function tokenRequest(string $token, string $uri, string $method = 'GET')
    {
        Auth::forgetGuards();
        return $this->json($method,$uri,[],['Authorization'=>'Bearer '.$token]);
    }

    public function test_sesiones_independientes_me_exportacion_y_logout(): void
    {
        $primero = $this->login()->assertOk()->assertJsonPath('data.usuario.id',1)
            ->assertJsonMissingPath('data.usuario.password_hash')->json('data.token');
        $segundo = $this->login()->assertOk()->json('data.token');
        $this->assertNotSame($primero,$segundo);
        $this->assertDatabaseCount('personal_access_tokens',2);
        $this->assertNotSame(explode('|',$primero,2)[1], DB::table('personal_access_tokens')->value('token'));
        $this->tokenRequest($primero,'/api/auth/me')->assertOk()->assertJsonPath('data.correo','Empresa@example.test');
        $this->tokenRequest($primero,'/api/usuarios/exportar')->assertOk()->assertDownload();
        $this->tokenRequest($primero,'/api/auth/logout','POST')->assertOk();
        $this->tokenRequest($primero,'/api/auth/me')->assertUnauthorized();
        $this->tokenRequest($segundo,'/api/auth/me')->assertOk();
    }

    public function test_rechaza_credenciales_invalidas_y_no_admite_texto_plano(): void
    {
        $this->postJson('/api/auth/login',['correo'=>'Empresa@example.test','password'=>'otra'])->assertUnauthorized();
        $this->postJson('/api/auth/login',['correo'=>'desconocido@example.test','password'=>'otra'])->assertUnauthorized();
        DB::table('usuarios')->where('id',1)->update(['password_hash'=>'ClavePrueba123!']);
        $this->login()->assertUnauthorized();
        $this->assertDatabaseCount('personal_access_tokens',0);
    }

    public function test_validacion_y_limite(): void
    {
        $this->postJson('/api/auth/login',[])->assertUnprocessable()->assertJsonValidationErrors(['correo','password']);
        $this->postJson('/api/auth/login',['correo'=>'incorrecto','password'=>'x'])->assertUnprocessable();
        for ($i=0;$i<3;$i++) { $this->postJson('/api/auth/login',['correo'=>'otro@example.test','password'=>'x'])->assertUnauthorized(); }
        $this->login()->assertStatus(429);
    }

    public function test_expiracion_cuenta_inactiva_y_token_falso(): void
    {
        $token = $this->login()->assertOk()->json('data.token');
        DB::table('usuarios')->where('id',1)->update(['estado'=>0]);
        $this->tokenRequest($token,'/api/auth/me')->assertForbidden();
        $this->login()->assertForbidden();
        DB::table('usuarios')->where('id',1)->update(['estado'=>1]);
        $this->travel(9)->hours();
        $this->tokenRequest($token,'/api/auth/me')->assertUnauthorized();
        $this->tokenRequest('desarrollo-sin-backend-1','/api/auth/me')->assertUnauthorized();
        Auth::forgetGuards();
        $this->get('/api/auth/me')->assertUnauthorized()->assertJsonStructure(['message']);
    }

    public function test_correo_duplicado_no_autentica_cuenta_arbitraria(): void
    {
        $fila = (array) DB::table('usuarios')->first(); unset($fila['id']);
        $fila['correo'] = 'empresa@example.test';
        DB::table('usuarios')->insert($fila);
        $this->login()->assertUnauthorized();
        $this->assertDatabaseCount('personal_access_tokens',0);
    }

    public function test_migracion_tokens_reversible(): void
    {
        $m = require database_path('migrations/2026_09_22_195900_create_personal_access_tokens.php');
        $m->down(); $this->assertFalse(Schema::hasTable('personal_access_tokens'));
        $m->up(); $this->assertTrue(Schema::hasTable('personal_access_tokens'));
    }
}
