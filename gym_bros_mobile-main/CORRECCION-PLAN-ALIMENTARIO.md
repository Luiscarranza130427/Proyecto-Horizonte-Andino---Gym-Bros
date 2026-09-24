# Corrección de la referencia del plan alimentario

La pantalla ya no consulta el listado global para escoger un plan. Lee exclusivamente la referencia guardada después del POST exitoso, separada por URL de API e ID de usuario.

POST /api/planesalimentacion/generar/{id_usuario}: conserva data.id y muestra data inmediatamente. Al reabrir usa GET /api/usuarios/{id_usuario}/planesalimentacion/{id_plan}. Un 404 elimina esa referencia y muestra «Sin plan disponible»; conexión, autenticación y servidor mantienen errores distintos. No hay reintentos automáticos de generación.

Diagnóstico HTTP real: usuario 1 / plan 1 -> 404; usuario 1 / plan 5 -> 200 con siete días. Los IDs fueron utilizados únicamente para diagnóstico. La lógica anterior seleccionaba el único resumen del listado global, que podía corresponder a un plan antiguo, y no persistía el ID generado.

Integración pendiente: las rutas actuales no identifican el plan vigente creado desde otro dispositivo o antes de esta corrección. Laravel debe devolver esa referencia asociada al usuario mediante un contrato autorizado. No se inventó una ruta ni se fijó el plan 5 en Flutter.

Archivos: lib/screens/nutrition_screen.dart; lib/services/nutrition_plan_reference.dart; lib/services/nutrition_api.dart; pubspec.yaml; pubspec.lock; test/nutrition_test.dart; test/widget_test.dart. Flutter también actualiza los registradores de complementos necesarios para shared_preferences.

Validación: 63 pruebas aprobadas. La generación se comprueba con HTTP simulado para no crear planes de prueba en cuentas reales; las consultas de diagnóstico fueron GET reales. Backend sin modificaciones.
