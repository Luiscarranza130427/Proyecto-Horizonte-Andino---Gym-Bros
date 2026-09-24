<?php

namespace App\Mail;

use App\Models\OrdenCompra;
use Illuminate\Mail\Mailable;

class ConfirmacionCompra extends Mailable
{
    public function __construct(public OrdenCompra $orden, public string $acceso) {}
    public function build(): static
    {
        return $this->subject('GYM-BROS: compra confirmada')->view('emails.confirmacion-compra');
    }
}
