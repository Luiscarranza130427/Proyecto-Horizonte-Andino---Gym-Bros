<?php

namespace App\Http\Controllers;

use App\Http\Requests\ImportarUsuariosRequest;
use App\Models\Usuario;
use App\Services\Usuarios\{LeerArchivoUsuarios,ImportarUsuariosService};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class ImportarUsuariosController extends Controller
{
    public function store(ImportarUsuariosRequest $request, LeerArchivoUsuarios $lector, ImportarUsuariosService $service)
    {
        $actor = $request->user('sanctum');
        $empresaId = $actor->tipo_usuario === 'Administrador' ? (int)$request->validated('id_empresas') : $actor->id_empresas;
        if (!$empresaId) { return response()->json(['message'=>'No tiene una empresa asociada.'],403); }
        try {
            $cantidad = $service->importar($lector->leer($request->file('archivo')), (int)$empresaId);
            return response()->json(['data'=>['importados'=>$cantidad,'id_empresas'=>(int)$empresaId,
                'correos_encolados'=>$cantidad,'mensaje'=>'Usuarios importados correctamente. Los correos para establecer contrasena quedaron en cola.']],201);
        } catch (ValidationException $e) {
            return response()->json(['message'=>'No se importo ningun usuario. Corrige los errores indicados.', 'errors'=>$e->errors()],422);
        } catch (\Throwable $e) {
            Log::error('Fallo de importacion de usuarios.', ['exception'=>get_class($e)]);
            return response()->json(['message'=>'No se pudo completar la importacion. No se guardaron usuarios.'],503);
        }
    }

    public function plantilla(Request $request)
    {
        $actor = $request->user('sanctum');
        if (!$actor instanceof Usuario || !in_array($actor->tipo_usuario,['Administrador','Empresa'],true)) {
            return response()->json(['message'=>'No tiene permiso para importar usuarios.'],403);
        }
        return response()->streamDownload(function () {
            $out = fopen('php://output','w'); fwrite($out,"\xEF\xBB\xBF");
            fputcsv($out,array_merge(LeerArchivoUsuarios::OBLIGATORIAS,LeerArchivoUsuarios::OPCIONALES),';','"','');
            fclose($out);
        },'plantilla-usuarios.csv',['Content-Type'=>'text/csv; charset=UTF-8','Cache-Control'=>'no-store']);
    }
}
