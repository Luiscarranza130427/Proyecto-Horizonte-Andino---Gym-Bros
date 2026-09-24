<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="color-scheme" content="dark">
    <meta name="supported-color-schemes" content="dark">
    <title>{{ $alta ? 'Establece tu contraseña de GYM-BROS' : 'Recupera tu contraseña de GYM-BROS' }}</title>
    <style>
        @media only screen and (max-width: 480px) {
            .outer { padding: 20px 12px !important; }
            .content { padding: 28px 20px !important; }
            .heading { font-size: 28px !important; line-height: 34px !important; }
        }
    </style>
</head>
<body style="margin:0;padding:0;background-color:#131313;color:#e5e2e1;font-family:Inter,Arial,sans-serif;letter-spacing:0;">
    <div style="display:none;font-size:1px;color:#131313;line-height:1px;max-height:0;max-width:0;opacity:0;overflow:hidden;mso-hide:all;">Crea una nueva contraseña. Tu enlace es de un solo uso y vence en 60 minutos.</div>
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" bgcolor="#131313">
        <tr><td class="outer" align="center" style="padding:40px 16px;">
            <!--[if mso]><table role="presentation" width="600" align="center"><tr><td><![endif]-->
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width:600px;">
                <tr><td style="padding:0 0 24px;font-family:Montserrat,Arial,sans-serif;font-size:28px;line-height:34px;font-weight:800;color:#e5e2e1;">GYM-BROS</td></tr>
                <tr><td class="content" bgcolor="#1c1b1b" style="padding:40px 36px;border:1px solid #333333;border-top:4px solid #e50914;">
                    <h1 class="heading" style="margin:0 0 20px;font-family:Montserrat,Arial,sans-serif;font-size:34px;line-height:40px;font-weight:800;color:#e5e2e1;">{{ $alta ? 'Establece tu' : 'Recupera tu' }}<br>contraseña</h1>
                    <p style="margin:0 0 28px;font-size:16px;line-height:26px;font-weight:400;color:#c6c6c6;">{{ $alta ? 'Tu gimnasio ha creado tu cuenta en GYM-BROS. Establece tu contraseña para iniciar sesión.' : 'Recibimos una solicitud para restablecer la contraseña de tu cuenta. Usa el siguiente botón para crear una nueva.' }}</p>
                    <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                        <tr><td align="center" bgcolor="#e50914" style="border-radius:6px;mso-padding-alt:17px 12px;">
                            <a href="{{ $url }}" style="display:block;padding:17px 12px;border:1px solid #e50914;border-radius:6px;font-family:Inter,Arial,sans-serif;font-size:16px;line-height:24px;font-weight:700;color:#fff7f6;text-decoration:none;">{{ $alta ? 'Establecer contraseña' : 'Restablecer contraseña' }}</a>
                        </td></tr>
                    </table>
                    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin-top:28px;">
                        <tr><td bgcolor="#2a2a2a" style="padding:18px 20px;border-left:3px solid #e9bcb6;">
                            <p style="margin:0 0 6px;font-size:15px;line-height:23px;font-weight:700;color:#e9bcb6;">Tu enlace es personal y de un solo uso.</p>
                            <p style="margin:0;font-size:14px;line-height:23px;font-weight:400;color:#c6c6c6;">Vence 60 minutos después de su generación. Al cambiar la contraseña se cerrarán tus sesiones anteriores.</p>
                        </td></tr>
                    </table>
                    <p style="margin:26px 0 0;font-size:14px;line-height:23px;color:#c6c6c6;">{{ $alta ? 'Si no reconoces este registro, no uses el enlace y contacta con tu gimnasio. Si el enlace vence, puedes solicitar otro desde Olvidé mi contraseña.' : 'Si no solicitaste este cambio, ignora este mensaje. Tu contraseña no ha cambiado.' }}</p>
                </td></tr>
                <tr><td style="padding:22px 0 0;font-family:Inter,Arial,sans-serif;font-size:12px;line-height:20px;color:#c6c6c6;">GYM-BROS · Seguridad de tu cuenta<br>No compartas este correo ni su enlace de recuperación.</td></tr>
            </table>
            <!--[if mso]></td></tr></table><![endif]-->
        </td></tr>
    </table>
</body>
</html>
