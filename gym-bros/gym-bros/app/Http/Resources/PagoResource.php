<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PagoResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id'=>$this->id,
            'id_empresas'=>$this->id_empresas,
            'id_suscripciones'=>$this->id_suscripciones,
            'monto'=>$this->monto,
            'moneda'=>$this->moneda,
            'metodo_pago'=>$this->metodo_pago,
            'referencia'=>$this->referencia,
            'estado'=>$this->estado,
            'fecha_pago'=>$this->fecha_pago,
            'empresa'=> new EmpresaResource($this->whenLoaded('empresa')),
            'suscripcion'=> new SuscripcionResource($this->whenLoaded('suscripcion')),
        ];
    }
}
