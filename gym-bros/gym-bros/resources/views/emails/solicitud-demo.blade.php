<!doctype html>
<html lang="es"><head><meta charset="utf-8"></head><body>
<h1>Nueva solicitud de demostración de GYM-BROS</h1>
<p>Correo: {{ $solicitud->correo }}</p>
<p>Fecha y hora: {{ $solicitud->created_at }} ({{ config('app.timezone') }})</p>
<p>Identificador: {{ $solicitud->id }}</p>
</body></html>
