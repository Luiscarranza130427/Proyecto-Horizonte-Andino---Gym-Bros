<?php

namespace Tests\Feature;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class ActualizarBannerEmpresaTest extends ActualizarLogoEmpresaTest
{
    public function test_banner_se_guarda_como_archivo_sin_modificar_logo(): void
    {
        $this->post('/api/empresas/1/personalizacion', [
            '_method' => 'PUT',
            'banner_1' => UploadedFile::fake()->image('banner.png', 650, 520),
        ])->assertOk();
        $empresa = DB::table('empresas')->find(1);
        $this->assertStringStartsWith('empresas/', $empresa->banner_1);
        $this->assertNotSame('empresas/anterior.webp', $empresa->banner_1);
        $this->assertSame('empresas/anterior.webp', $empresa->logo);
        Storage::disk('public')->assertExists($empresa->banner_1);
    }
}
