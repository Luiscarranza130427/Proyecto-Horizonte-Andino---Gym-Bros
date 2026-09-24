<?php

namespace App\Mail;

use Illuminate\Mail\Mailable;

class SolicitudDemo extends Mailable
{
    public function __construct(public object $solicitud) {}

    public function build()
    {
        return $this->subject('Nueva solicitud de demostración de GYM-BROS')->view('emails.solicitud-demo');
    }
}
