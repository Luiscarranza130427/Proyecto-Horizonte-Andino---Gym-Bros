<!DOCTYPE html>
<html lang="es"><head><meta charset="utf-8"></head><body>
<h1>GYM-BROS</h1>
<p>Hola, {{ $orden->comprador['nombres'] }}. Tu compra est&aacute; confirmada.</p>
<p>Empresa: {{ $orden->empresa_datos['nombre'] }}</p>
<p>Plan: {{ $orden->plan_nombre }}. Duraci&oacute;n: {{ $orden->duracion_dias }} d&iacute;as.</p>
<p>Monto pagado: {{ $orden->moneda }} {{ $orden->monto }}</p>
@php($suscripcion = \App\Models\Suscripcion::find($orden->id_suscripciones))
<p>Inicio: {{ $suscripcion?->fecha_inicio }}. Vencimiento: {{ $suscripcion?->fecha_fin }}.</p>
<p>Referencia: {{ $orden->uuid }}</p>
<p><a href="{{ $acceso }}">Establecer contrase&ntilde;a o acceder al portal</a></p>
<p>El enlace para establecer contrase&ntilde;a es de un solo uso y vence en 48 horas.</p>
<p>Soporte: info@novawavedev.com</p>
</body></html>
