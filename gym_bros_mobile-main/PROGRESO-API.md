# Tu progreso: datos para la siguiente conexión

## Pantalla implementada

Archivo: lib/screens/progress_screen.dart.
Peso destacado, fecha de evaluación, composición corporal, IMC, porcentaje de grasa,
masa muscular, altura y perímetros. Colores heredados del tema de la empresa.
Los valores ausentes se omiten. Sin puntuaciones ni métricas inventadas. El IMC incluye su categoría para adultos de 20 años o más, según CDC; no es un diagnóstico.

Actualmente se usa GET /api/usuarios/{id_usuario}/evaluaciones/perfil para identificar
id_evaluacion y GET /api/evaluacionesfisicas para recuperar ese registro completo.
La pantalla permite actualizar y refleja nuevas evaluaciones o correcciones del perfil.
El índice actual no incluye id_usuarios, por eso no sirve para agrupar todo el historial por usuario.
Los registros antiguos de /api/progresos se conservan en un desplegable independiente.

## Ruta solicitada al backend (propuesta, aún NO conectada ni creada)

GET /api/usuarios/{id_usuario}/evaluaciones/historial
Ejemplo: http://192.168.1.70:8000/api/usuarios/1/evaluaciones/historial

Debe devolver únicamente evaluaciones_fisicas del usuario solicitado, ordenadas
por fecha_evaluacion DESC y luego id DESC, con todas sus evaluaciones en esta primera versión.
HTTP 200 con data: [] si el usuario existe pero no tiene evaluaciones; 404 si no existe.
Aplicar la autorización correspondiente al usuario autenticado.

Ejemplo de contrato (datos ilustrativos):

```json
{
  "data": [
    {
      "id": 3,
      "id_usuarios": 1,
      "fecha_evaluacion": "2026-09-10",
      "peso": 78.5,
      "altura": 175.0,
      "edad": 28,
      "porcentaje_grasa": 18.2,
      "masa_muscular": 35.2,
      "cintura": 90.0,
      "pecho": 100.0,
      "brazo": 33.0,
      "muslo": 55.0,
      "cadera": 96.0
    }
  ]
}
```

- id e id_usuarios: enteros. fecha_evaluacion: YYYY-MM-DD.
- peso y masa_muscular: kg. altura y todos los perímetros: cm.
- porcentaje_grasa: porcentaje de 0 a 100.
- Medidas desconocidas: null, nunca 0 como sustituto de un dato ausente.
- Mantener el mismo id al editar la última evaluación; crear uno nuevo al registrar otra.
- Confirmar que masa_muscular representa kg y mantener el mismo método de medición.

Con esta respuesta se puede reemplazar la consulta del índice general y mostrar
historial, gráficas y variaciones comparando las dos evaluaciones más recientes.
No mostrar tendencias si hay menos de dos evaluaciones válidas para la métrica.
Para diferencias de grasa porcentual usar puntos porcentuales.
No mezclar filas de progresos con evaluaciones_fisicas para construir ese historial.

## Cálculos actuales (misma evaluación)

IMC = peso / (altura_cm / 100)^2.
Grasa en kg = peso * porcentaje_grasa / 100.
Peso libre de grasa = peso - grasa_kg (no equivale a masa muscular).
Se omiten cálculos si falta algún dato necesario y se redondea solo para presentación.

Para clasificar IMC, incluir edad (años cumplidos en la evaluación). Si falta o es menor de 20, no se aplica la clasificación adulta. Bajo peso: <18.5; peso saludable: >=18.5 y <25; sobrepeso: >=25 y <30; obesidad: >=30. Clasificar antes de redondear. Referencia: https://www.cdc.gov/bmi/adult-calculator/bmi-categories.html

