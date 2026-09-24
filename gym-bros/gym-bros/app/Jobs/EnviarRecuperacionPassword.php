<?php

namespace App\Jobs;

use App\Mail\RecuperacionPassword;
use App\Models\Usuario;
use Illuminate\Contracts\Queue\{ShouldQueue,ShouldBeEncrypted};
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\{Log,Mail,Password};

class EnviarRecuperacionPassword implements ShouldQueue, ShouldBeEncrypted
{
    use Queueable;
    public int $tries = 5;
    public int $timeout = 60;
    public bool $alta = false;
    public function __construct(private int $usuarioId, private string $correo, private string $token, bool $alta = false) { $this->alta = $alta; }
    public function backoff(): array { return [60,300,900,1800]; }

    public function handle(): void
    {
        try {
            $cuentas = Usuario::whereRaw('LOWER(TRIM(correo)) = ?', [$this->correo])->limit(2)->get();
            if ($cuentas->count() !== 1) { return; }
            $usuario = $cuentas->first();
            if ($usuario->id !== $this->usuarioId || ! Password::broker('usuarios')->tokenExists($usuario, $this->token)) { return; }
            $base = config('auth.password_reset_url');
            if (! is_string($base) || ! filter_var($base,FILTER_VALIDATE_URL)
                || parse_url($base,PHP_URL_SCHEME) !== 'https' || parse_url($base,PHP_URL_QUERY)
                || parse_url($base,PHP_URL_FRAGMENT) || parse_url($base,PHP_URL_USER)) {
                throw new \RuntimeException('URL de recuperacion no configurada.');
            }
            $url = $base.'#'.http_build_query(['correo'=>$this->correo,'token'=>$this->token], '', '&', PHP_QUERY_RFC3986);
            Mail::mailer('smtp')->to($this->correo)->send(new RecuperacionPassword($url, $this->alta));
        } catch (\Throwable $e) {
            Log::error('Envio de recuperacion pendiente.', ['exception'=>get_class($e)]);
            throw new \RuntimeException('No se pudo enviar la recuperacion.');
        }
    }
}
