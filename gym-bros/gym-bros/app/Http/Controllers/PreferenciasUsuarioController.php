<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PreferenciasUsuarioController extends Controller
{
    private const PREDETERMINADAS = ['idioma' => 'es', 'tema' => 'oscuro', 'notifEmail' => true,
        'notifPush' => true, 'notifPagos' => true, 'notifSeguridad' => true];

    private function leer(): array
    {
        $json = DB::table('preferencias_usuario')->where('id_usuarios', $this->actor()->id)->value('preferencias');

        return array_replace(self::PREDETERMINADAS, $json ? json_decode($json, true, 512, JSON_THROW_ON_ERROR) : []);
    }

    public function show()
    {
        return response()->json(['data' => $this->leer()]);
    }

    public function update(Request $request)
    {
        $datos = $request->validate(['idioma' => ['sometimes', 'required', 'in:es'],
            'tema' => ['sometimes', 'required', 'in:oscuro'], 'notifEmail' => ['sometimes', 'boolean'],
            'notifPush' => ['sometimes', 'boolean'], 'notifPagos' => ['sometimes', 'boolean'],
            'notifSeguridad' => ['sometimes', 'boolean']]);
        $preferencias = DB::transaction(function () use ($datos) {
            \App\Models\Usuario::whereKey($this->actor()->id)->lockForUpdate()->firstOrFail();
            $actual = array_replace($this->leer(), $datos);
            DB::table('preferencias_usuario')->upsert([['id_usuarios' => $this->actor()->id,
                'preferencias' => json_encode($actual, JSON_THROW_ON_ERROR), 'created_at' => now(), 'updated_at' => now()]],
                ['id_usuarios'], ['preferencias', 'updated_at']);

            return $actual;
        });

        return response()->json(['data' => $preferencias]);
    }
}
