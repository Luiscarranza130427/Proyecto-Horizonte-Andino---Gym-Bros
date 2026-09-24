<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class ListarPlanesTest extends TestCase
{
    public function test_devuelve_todos_los_campos_sin_modificar_datos(): void
    {
        config(['database.default'=>'sqlite','database.connections.sqlite.database'=>':memory:',
            'database.connections.sqlite.url'=>null]);
        DB::purge('sqlite');
        $this->assertSame(':memory:',DB::connection()->getDatabaseName());
        (require database_path('migrations/2026_08_21_224524_create_planes.php'))->up();
        foreach ([true,false] as $activo) {
            DB::table('planes')->insert([
                'nombre'=>'Plan QA','descripcion'=>'Descripcion QA','precio_original'=>100,
                'precio_inicial'=>80,'duracion_dias'=>30,'limite_usuarios'=>50,'activo'=>$activo,
                'contenido'=>null,'enlace_whatsapp'=>'https://wa.me/51912345678',
                'created_at'=>'2026-09-01 10:00:00','updated_at'=>'2026-09-02 10:00:00',
            ]);
        }
        $antes=DB::table('planes')->get()->toJson();
        $response=$this->getJson('/api/planes')->assertOk()->assertJsonCount(2,'data')
            ->assertJsonPath('data.0.duracion_dias',30)->assertJsonPath('data.0.contenido',null);
        foreach ($response->json('data') as $plan) {
            $this->assertEqualsCanonicalizing(Schema::getColumnListing('planes'),array_keys($plan));
            $this->assertStringStartsWith('2026-09-01',$plan['created_at']);
            $this->assertStringStartsWith('2026-09-02',$plan['updated_at']);
        }
        $this->assertSame($antes,DB::table('planes')->get()->toJson());
        DB::disconnect('sqlite');
    }
}
