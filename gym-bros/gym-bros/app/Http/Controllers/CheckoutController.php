<?php

namespace App\Http\Controllers;

use App\Http\Requests\{CheckoutRequest,ReembolsoRequest,CheckoutLoginRequest,EstablecerPasswordRequest};
use App\Jobs\ProcesarPagoMercadoPago;
use App\Models\{OrdenCompra,Pago,Suscripcion,Usuario};
use App\Services\Pagos\{CheckoutService,MercadoPagoService,RefundService};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\{DB,Hash};

class CheckoutController extends Controller
{
    public function store(CheckoutRequest $request, CheckoutService $service)
    {
        $orden = $service->crear($request->validated());
        return response()->json(['data'=>['orden_id'=>$orden->uuid,'checkout_url'=>$orden->checkout_url,'estado'=>$orden->estado]],201);
    }

    public function estado(string $orden_uuid)
    {
        $orden = OrdenCompra::where('uuid',$orden_uuid)->first();
        abort_unless($orden,404);
        $estado = $orden->estado;
        if (in_array($estado,['pendiente','checkout_creado'],true) && $orden->expira_en->isPast()) { $estado = 'expirado'; }
        return response()->json(['data'=>['estado'=>$estado,'plan'=>$orden->plan_nombre,'monto'=>$orden->monto,
            'moneda'=>$orden->moneda,'estado_suscripcion'=>$orden->id_suscripciones ? Suscripcion::whereKey($orden->id_suscripciones)->value('estado') : null]]);
    }

    public function webhook(Request $request, MercadoPagoService $service)
    {
        $id = $service->validarFirma($request);
        ProcesarPagoMercadoPago::dispatch($id)->onConnection('database');
        return response()->json(['recibido'=>true]);
    }

    public function reembolso(ReembolsoRequest $request, string $pago, RefundService $service)
    {
        $registro = Pago::find($pago);
        abort_unless($registro,404);
        $actor = $request->user();
        abort_unless($actor instanceof Usuario,403);
        $service->solicitar($actor,$registro,$request->validated('motivo'));
        return response()->json(['data'=>['id'=>$registro->id,'estado'=>'reembolsado']]);
    }

    public function login(CheckoutLoginRequest $request)
    {
        $datos = $request->validated();
        $usuario = Usuario::where('correo_normalizado',mb_strtolower(trim($datos['correo'])))->first();
        abort_unless($usuario && $usuario->estado && Hash::check($datos['password'],$usuario->password_hash),401);
        $token = $usuario->createToken('checkout',['pagos:reembolsar'],now()->addHours(8));
        return response()->json(['data'=>['token'=>$token->plainTextToken,'token_type'=>'Bearer']])->header('Cache-Control','no-store');
    }

    public function password(EstablecerPasswordRequest $request, string $orden_uuid)
    {
        $datos = $request->validated();
        DB::transaction(function () use ($orden_uuid,$request,$datos) {
            $orden = OrdenCompra::where('uuid',$orden_uuid)->lockForUpdate()->first();
            abort_unless($orden && $orden->estado === 'aprobado' && !$orden->password_establecida_en
                && $orden->password_token_expira && $orden->password_token_expira->isFuture()
                && is_string($request->query('token'))
                && hash_equals((string) $orden->password_token_hash,hash('sha256',$request->query('token'))),403);
            Usuario::whereKey($orden->id_usuarios)->update(['password_hash'=>Hash::make($datos['password'])]);
            $orden->update(['password_establecida_en'=>now(),'password_token_hash'=>null]);
        });
        return response()->json(['message'=>'Contrasena establecida. Ya puede iniciar sesion.']);
    }
}
