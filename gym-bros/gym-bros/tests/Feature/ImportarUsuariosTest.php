<?php

namespace Tests\Feature;

use App\Jobs\ProcesarRecuperacionPassword;
use App\Mail\RecuperacionPassword;
use App\Models\Usuario;
use App\Services\Auth\PasswordRecoveryService;
use App\Services\Usuarios\LeerArchivoUsuarios;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\{Auth,Cache,Crypt,DB,Hash,Mail,Schema};
use Laravel\Sanctum\Sanctum;
use OpenSpout\Common\Entity\Row;
use OpenSpout\Writer\XLSX\Writer;
use Tests\TestCase;

class ImportarUsuariosTest extends TestCase
{
    private array $temporales = [];

    protected function setUp(): void
    {
        parent::setUp();
        config(['database.default'=>'sqlite','database.connections.sqlite.database'=>':memory:',
            'database.connections.sqlite.url'=>null,'queue.connections.database.connection'=>null,'cache.default'=>'array']);
        DB::purge('sqlite'); Cache::flush(); Mail::fake();
        Schema::create('empresas',fn (Blueprint $t)=>$t->id());
        DB::table('empresas')->insert([['id'=>1],['id'=>2]]);
        (require database_path('migrations/2026_08_21_224236_create_usuarios.php'))->up();
        (require database_path('migrations/2026_09_24_000000_unique_correo_usuarios.php'))->up();
        (require database_path('migrations/2026_09_22_195900_create_personal_access_tokens.php'))->up();
        Schema::create('password_reset_tokens',function (Blueprint $t) {
            $t->string('email')->primary(); $t->string('token'); $t->timestamp('created_at')->nullable();
        });
        Schema::create('jobs',function (Blueprint $t) {
            $t->id(); $t->string('queue'); $t->longText('payload'); $t->unsignedTinyInteger('attempts');
            $t->unsignedInteger('reserved_at')->nullable(); $t->unsignedInteger('available_at'); $t->unsignedInteger('created_at');
        });
        DB::table('usuarios')->insert($this->fila(['correo'=>'actor@example.test']) + [
            'id'=>1,'id_empresas'=>1,'tipo_usuario'=>'Empresa','estado'=>1,'password_hash'=>Hash::make('PruebaActor123!')]);
        $this->actor();
    }

    protected function tearDown(): void
    {
        Usuario::flushEventListeners();
        foreach ($this->temporales as $path) { if (is_file($path)) { unlink($path); } }
        parent::tearDown();
    }

    private function actor(string $rol = 'Empresa', ?int $empresa = 1): void
    {
        $actor=Usuario::findOrFail(1); $actor->tipo_usuario=$rol; $actor->id_empresas=$empresa;
        Sanctum::actingAs($actor,['sesion']);
    }

    private function fila(array $cambios = []): array
    {
        return array_merge(['nombres'=>'Ana','apellidos'=>'Prueba','apodo'=>'Ana','genero'=>'Mujer',
            'correo'=>'ana@example.test','tipo_documento'=>'DNI','numero_documento'=>'00123456',
            'telefono'=>'987654321','fecha_nacimiento'=>'2000-01-01','direccion'=>'Calle; prueba',
            'fecha_registro'=>'2026-01-01','inicio_suscripcion'=>null,'fin_suscripcion'=>null],$cambios);
    }

    private function archivo(array $filas, string $tipo = 'csv', ?array $cabecera = null): UploadedFile
    {
        $cabecera ??= array_merge(LeerArchivoUsuarios::OBLIGATORIAS,LeerArchivoUsuarios::OPCIONALES);
        $path=tempnam(sys_get_temp_dir(),'gym-import-'); $this->temporales[]=$path;
        if ($tipo === 'xlsx') {
            $writer=new Writer(); $writer->openToFile($path); $writer->addRow(Row::fromValues($cabecera));
            foreach ($filas as $fila) {
                $styles=[];
                foreach (array_values($fila) as $i=>$v) {
                    if ($v instanceof \DateTimeInterface) { $styles[$i]=(new \OpenSpout\Common\Entity\Style\Style())->setFormat('yyyy-mm-dd'); }
                }
                $writer->addRow(Row::fromValuesWithStyles(array_values($fila),null,$styles));
            }
            $writer->close();
        } else {
            $f=fopen($path,'w'); fwrite($f,"\xEF\xBB\xBF"); fputcsv($f,$cabecera,';','"','');
            foreach ($filas as $fila) { fputcsv($f,array_values($fila),';','"',''); }
            fclose($f);
        }
        return new UploadedFile($path,'usuarios.'.$tipo,null,null,true);
    }

    private function importar(UploadedFile $archivo, array $extra = [])
    {
        return $this->post('/api/usuarios/importar',['archivo'=>$archivo]+$extra,['Accept'=>'application/json']);
    }

    private function job(): object
    {
        $row=DB::table('jobs')->orderBy('id')->first();
        $this->assertStringNotContainsString('ana@example.test',$row->payload);
        $job=unserialize(Crypt::decrypt(json_decode($row->payload,true)['data']['command']));
        DB::table('jobs')->where('id',$row->id)->delete();
        return $job;
    }

    public function test_csv_atomico_empresa_y_alta_por_correo(): void
    {
        $this->importar($this->archivo([$this->fila(),$this->fila(['correo'=>'otro@example.test'])]))
            ->assertCreated()->assertJsonPath('data.importados',2)->assertJsonPath('data.correos_encolados',2);
        $this->assertDatabaseHas('usuarios',['correo'=>'ana@example.test','tipo_usuario'=>'Usuario','id_empresas'=>1,'numero_documento'=>'00123456']);
        $this->assertDatabaseCount('jobs',2); Mail::assertNothingSent();
        $usuario=Usuario::where('correo','ana@example.test')->first();
        $this->assertFalse((bool)password_get_info($usuario->password_hash)['algo']);
        $job=$this->job(); $this->assertTrue($job->alta); $job->handle(app(PasswordRecoveryService::class));
        $this->job()->handle(app(PasswordRecoveryService::class));
        $this->job()->handle();
        $mail=Mail::sent(RecuperacionPassword::class)->first(); $this->assertTrue($mail->alta);
        $this->assertStringContainsString('Establecer contraseña',$mail->render());
        parse_str(parse_url($mail->url,PHP_URL_FRAGMENT),$link);
        $this->postJson('/api/auth/reset-password',$link+['password'=>'NuevaClave12345!','password_confirmation'=>'NuevaClave12345!'])->assertOk();
        $this->assertTrue(Hash::check('NuevaClave12345!',$usuario->fresh()->password_hash));
    }

    public function test_xlsx_admin_empresa_seleccionada_y_fechas_excel(): void
    {
        $this->actor('Administrador');
        $fila=$this->fila(['fecha_nacimiento'=>new \DateTimeImmutable('2000-01-01')]);
        $this->importar($this->archivo([$fila],'xlsx'),['id_empresas'=>2])->assertCreated();
        $this->assertDatabaseHas('usuarios',['correo'=>'ana@example.test','id_empresas'=>2,'fecha_nacimiento'=>'2000-01-01']);
    }

    public function test_errores_por_fila_y_rechazo_de_duplicados(): void
    {
        $this->importar($this->archivo([$this->fila(),$this->fila(['correo'=>' ANA@example.test '])]))
            ->assertUnprocessable()->assertJsonValidationErrors('filas.3.correo');
        $this->importar($this->archivo([$this->fila(),$this->fila(['correo'=>'ACTOR@example.test'])]))
            ->assertUnprocessable()->assertJsonValidationErrors('filas.3.correo');
        $this->importar($this->archivo([$this->fila(),$this->fila(['correo'=>'invalido','genero'=>'invalido'])]))
            ->assertUnprocessable()->assertJsonValidationErrors(['filas.3.correo','filas.3.genero']);
        $this->assertDatabaseCount('usuarios',1); $this->assertDatabaseCount('jobs',0);
    }

    public function test_aislamiento_permisos_y_campos_prohibidos(): void
    {
        $this->importar($this->archivo([$this->fila()]),['id_empresas'=>2])->assertUnprocessable();
        $fila=$this->fila()+['tipo_usuario'=>'Administrador'];
        $this->importar($this->archivo([$fila],'csv',array_keys($fila)))->assertUnprocessable();
        $this->actor('Entrenador'); $this->importar($this->archivo([$this->fila()]))->assertForbidden();
        $this->actor('Empresa',null); $this->importar($this->archivo([$this->fila()]))->assertForbidden();
        $this->actor('Administrador'); $this->importar($this->archivo([$this->fila()]))->assertUnprocessable();
        $this->assertDatabaseCount('usuarios',1);
    }

    public function test_fallo_cola_revierte_toda_la_carga(): void
    {
        Schema::drop('jobs');
        $this->importar($this->archivo([$this->fila()]))->assertStatus(503)->assertJsonMissingPath('exception');
        $this->assertDatabaseCount('usuarios',1);
    }

    public function test_excel_formulas_documentos_numericos_y_archivo_vacio(): void
    {
        $this->importar($this->archivo([$this->fila(['nombres'=>'=1+1'])],'xlsx'))->assertUnprocessable();
        $this->importar($this->archivo([$this->fila(['numero_documento'=>123456])],'xlsx'))->assertUnprocessable();
        $this->importar($this->archivo([]))->assertUnprocessable();
        $this->assertDatabaseCount('usuarios',1);
    }

    public function test_limite_filas_plantilla_y_reenvio_no_duplica(): void
    {
        $this->get('/api/usuarios/importar/plantilla')->assertOk()->assertDownload('plantilla-usuarios.csv');
        $filas=[]; for ($i=0;$i<201;$i++) { $filas[]=$this->fila(['correo'=>"usuario$i@example.test"]); }
        $this->importar($this->archivo($filas))->assertUnprocessable();
        $this->importar($this->archivo([$this->fila()]))->assertCreated();
        $this->importar($this->archivo([$this->fila()]))->assertUnprocessable();
        $this->assertDatabaseCount('usuarios',2); $this->assertDatabaseCount('jobs',1);
    }

    public function test_indice_unico_reversible_sin_perder_usuarios(): void
    {
        $migration=require database_path('migrations/2026_09_24_000000_unique_correo_usuarios.php');
        $migration->down(); $migration->up();
        $this->assertDatabaseCount('usuarios',1);
        $this->expectException(\Illuminate\Database\UniqueConstraintViolationException::class);
        $fila=(array)DB::table('usuarios')->first(); unset($fila['id']); DB::table('usuarios')->insert($fila);
    }

    public function test_error_en_segunda_fila_revierte_usuarios_y_correos(): void
    {
        Usuario::creating(function ($usuario) {
            if ($usuario->correo === 'falla@example.test') { throw new \RuntimeException('Fallo simulado.'); }
        });
        $this->importar($this->archivo([$this->fila(),$this->fila(['correo'=>'falla@example.test'])]))->assertStatus(503);
        $this->assertDatabaseCount('usuarios',1); $this->assertDatabaseCount('jobs',0);
    }

    public function test_archivo_corrupto_tamano_y_anonimo(): void
    {
        $this->importar(UploadedFile::fake()->createWithContent('datos.xlsx','No es un Excel'))->assertUnprocessable();
        $this->importar(UploadedFile::fake()->create('datos.csv',5121,'text/csv'))->assertUnprocessable();
        Auth::forgetGuards();
        $this->importar($this->archivo([$this->fila()]))->assertUnauthorized();
        $this->assertDatabaseCount('usuarios',1);
    }
}
