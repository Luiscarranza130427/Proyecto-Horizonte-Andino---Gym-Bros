<?php

namespace Tests\Unit;

use App\Support\RutaPublica;
use Tests\TestCase;

class RutaPublicaTest extends TestCase
{
    public function test_normaliza_rutas_historicas_de_windows_y_relativas(): void
    {
        $casos = [
            'C:\\laragon\\www\\gym-bros\\storage\\app\\public\\usuario\\B716.jpg' => 'usuario/B716.jpg',
            '\\storage\\app\\public\\usuario\\prueba-gym.png' => 'usuario/prueba-gym.png',
            '/storage/empresas/logo.webp' => 'empresas/logo.webp',
            'storage/empresas/logo.webp' => 'empresas/logo.webp',
            'empresas/logo.webp' => 'empresas/logo.webp',
            '/empresas//logo.webp' => 'empresas/logo.webp',
            'public/storage/banners/b.webp' => 'banners/b.webp',
        ];
        foreach ($casos as $entrada => $esperado) {
            $this->assertSame($esperado, RutaPublica::relativa($entrada), $entrada);
        }
    }

    public function test_url_publica_sin_duplicar_storage_y_codificando_espacios(): void
    {
        $this->assertSame('http://localhost/storage/usuario/B716.jpg',
            RutaPublica::url('C:\\laragon\\www\\gym-bros\\storage\\app\\public\\usuario\\B716.jpg'));
        $this->assertSame('http://localhost/storage/empresas/logo.webp', RutaPublica::url('/storage/empresas/logo.webp'));
        $this->assertSame('http://localhost/storage/panel_rutinas/rutina%20de%20salud.webp',
            RutaPublica::url('panel_rutinas/rutina de salud.webp'));
        $this->assertStringNotContainsString('/storage/storage', (string) RutaPublica::url('storage/app/public/x.png'));
    }

    public function test_urls_absolutas_se_conservan_y_rutas_peligrosas_o_vacias_se_descartan(): void
    {
        $this->assertSame('https://cdn.example.test/a.png', RutaPublica::url('https://cdn.example.test/a.png'));
        foreach ([null, '', '   ', '../.env', 'usuario/../../.env', 'C:\\Windows\\system32\\a.dll'] as $ruta) {
            $this->assertNull(RutaPublica::url($ruta), var_export($ruta, true));
        }
    }
}
