<?php

namespace App\Mail;

use Illuminate\Mail\Mailable;

class RecuperacionPassword extends Mailable
{
    public function __construct(public string $url, public bool $alta = false) {}
    public function build()
    {
        return $this->subject($this->alta ? 'Establece tu contraseña de GYM-BROS' : 'Recupera tu contraseña de GYM-BROS')->view('emails.recuperacion-password');
    }
}
