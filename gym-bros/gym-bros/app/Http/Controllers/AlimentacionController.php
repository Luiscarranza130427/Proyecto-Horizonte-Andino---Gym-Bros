<?php

namespace App\Http\Controllers;

use App\Http\Requests\ActualizarNutricionAlimentoRequest;
use App\Http\Requests\GuardarPerfilAlimentarioRequest;
use App\Models\Alimento;
use App\Models\PerfilAlimentario;
use App\Models\PreferenciaAlimentaria;
use App\Models\Usuario;
use Illuminate\Support\Facades\DB;

class AlimentacionController extends Controller
{
    public function nutricion(ActualizarNutricionAlimentoRequest $request, string $id_alimento)
    {
        return DB::transaction(function () use ($request, $id_alimento) {
            $alimento = Alimento::lockForUpdate()->findOrFail($id_alimento);
            $datos = $request->validated();
            unset($datos['restricciones']);
            $alimento->update($datos);

            return response()->json(['data' => $alimento->refresh()]);
        });
    }

    public function perfil(string $id_usuario)
    {
        Usuario::findOrFail($id_usuario);
        $perfil = PerfilAlimentario::where('id_usuarios', $id_usuario)->firstOrFail();

        return response()->json(['data' => $perfil->toArray() + [
            'restricciones' => [],
            'preferencias' => PreferenciaAlimentaria::where('id_usuarios', $id_usuario)->where('activo', true)
                ->orderBy('id_alimentos')->orderBy('id')->get(),
        ]]);
    }

    public function guardarPerfil(GuardarPerfilAlimentarioRequest $request, string $id_usuario)
    {
        return DB::transaction(function () use ($request, $id_usuario) {
            $usuario = Usuario::lockForUpdate()->findOrFail($id_usuario);
            $datos = $request->validated();
            $preferencias = $datos['preferencias'];
            unset($datos['alergias'], $datos['intolerancias'], $datos['preferencias']);
            // Omitted/null legacy review fields never erase existing history.
            foreach (['revision_profesional', 'revisado_en'] as $campo) {
                if (($datos[$campo] ?? null) === null) {
                    unset($datos[$campo]);
                }
            }
            PerfilAlimentario::updateOrCreate(['id_usuarios' => $usuario->id], $datos);
            foreach ($preferencias as $preferencia) {
                // Normalize historical duplicates only for the submitted user/food pair.
                PreferenciaAlimentaria::where('id_usuarios', $usuario->id)
                    ->where('id_alimentos', $preferencia['id_alimentos'])->update(['activo' => false]);
                PreferenciaAlimentaria::updateOrCreate(['id_usuarios' => $usuario->id, 'id_alimentos' => $preferencia['id_alimentos']],
                    ['activo' => true, 'tipo' => $preferencia['tipo']]);
            }

            return $this->perfil($id_usuario);
        });
    }
}
