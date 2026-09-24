-- 30 alimentos nuevos para GYM-BROS.
-- Valores nutricionales aproximados por cada 100 gramos.
-- En alimentos liquidos, los valores corresponden a 100 mililitros.
-- No se insertan comidas, planes ni preferencias en esta consulta.
-- Las tablas relacionadas usaran el id generado en alimentos.id cuando corresponda.

INSERT INTO alimentos (
    nombre,
    tipo,
    calorias,
    proteinas,
    carbohidratos,
    grasas,
    fibra,
    created_at,
    updated_at
)
SELECT
    nuevos.nombre,
    nuevos.tipo,
    nuevos.calorias,
    nuevos.proteinas,
    nuevos.carbohidratos,
    nuevos.grasas,
    nuevos.fibra,
    NOW(),
    NOW()
FROM (
    SELECT 'Pechuga de pavo' AS nombre, 'proteina' AS tipo, 135.00 AS calorias, 29.00 AS proteinas, 0.00 AS carbohidratos, 1.80 AS grasas, 0.00 AS fibra
    UNION ALL SELECT 'Atun en agua', 'proteina', 116.00, 25.50, 0.00, 0.80, 0.00
    UNION ALL SELECT 'Salmon', 'proteina', 208.00, 20.50, 0.00, 13.40, 0.00
    UNION ALL SELECT 'Carne de res magra', 'proteina', 172.00, 26.00, 0.00, 7.00, 0.00
    UNION ALL SELECT 'Huevo entero', 'proteina', 143.00, 12.60, 0.70, 9.50, 0.00
    UNION ALL SELECT 'Claras de huevo', 'proteina', 52.00, 10.90, 0.70, 0.20, 0.00
    UNION ALL SELECT 'Yogur griego natural', 'lacteo', 59.00, 10.00, 3.60, 0.40, 0.00
    UNION ALL SELECT 'Leche descremada', 'lacteo', 34.00, 3.40, 5.00, 0.10, 0.00
    UNION ALL SELECT 'Queso fresco', 'lacteo', 265.00, 18.00, 3.40, 20.00, 0.00
    UNION ALL SELECT 'Quinua cocida', 'cereal', 120.00, 4.40, 21.30, 1.90, 2.80
    UNION ALL SELECT 'Avena', 'cereal', 389.00, 16.90, 66.30, 6.90, 10.60
    UNION ALL SELECT 'Papa sancochada', 'carbohidrato', 87.00, 1.90, 20.10, 0.10, 1.80
    UNION ALL SELECT 'Camote', 'carbohidrato', 86.00, 1.60, 20.10, 0.10, 3.00
    UNION ALL SELECT 'Pasta integral cocida', 'carbohidrato', 149.00, 5.80, 30.10, 1.60, 3.90
    UNION ALL SELECT 'Pan integral', 'carbohidrato', 247.00, 13.00, 41.00, 4.20, 7.00
    UNION ALL SELECT 'Lentejas cocidas', 'legumbre', 116.00, 9.00, 20.10, 0.40, 7.90
    UNION ALL SELECT 'Garbanzos cocidos', 'legumbre', 164.00, 8.90, 27.40, 2.60, 7.60
    UNION ALL SELECT 'Frijol negro cocido', 'legumbre', 132.00, 8.90, 23.70, 0.50, 8.70
    UNION ALL SELECT 'Manzana', 'fruta', 52.00, 0.30, 13.80, 0.20, 2.40
    UNION ALL SELECT 'Naranja', 'fruta', 47.00, 0.90, 11.80, 0.10, 2.40
    UNION ALL SELECT 'Fresas', 'fruta', 32.00, 0.70, 7.70, 0.30, 2.00
    UNION ALL SELECT 'Arandanos', 'fruta', 57.00, 0.70, 14.50, 0.30, 2.40
    UNION ALL SELECT 'Espinaca', 'verdura', 23.00, 2.90, 3.60, 0.40, 2.20
    UNION ALL SELECT 'Zanahoria', 'verdura', 41.00, 0.90, 9.60, 0.20, 2.80
    UNION ALL SELECT 'Tomate', 'verdura', 18.00, 0.90, 3.90, 0.20, 1.20
    UNION ALL SELECT 'Coliflor', 'verdura', 25.00, 1.90, 5.00, 0.30, 2.00
    UNION ALL SELECT 'Aceite de oliva', 'grasa', 884.00, 0.00, 0.00, 100.00, 0.00
    UNION ALL SELECT 'Almendras', 'grasa', 579.00, 21.20, 21.60, 49.90, 12.50
    UNION ALL SELECT 'Mantequilla de mani', 'grasa', 588.00, 25.10, 20.00, 50.00, 6.00
    UNION ALL SELECT 'Agua de coco', 'bebida', 19.00, 0.70, 3.70, 0.20, 1.10
) AS nuevos
WHERE NOT EXISTS (
    SELECT 1
    FROM alimentos existentes
    WHERE existentes.nombre = nuevos.nombre
);

-- Verificacion posterior: debe mostrar hasta 30 filas insertadas por esta consulta.
SELECT id, nombre, tipo, calorias, proteinas, carbohidratos, grasas, fibra
FROM alimentos
WHERE nombre IN (
    'Pechuga de pavo', 'Atun en agua', 'Salmon', 'Carne de res magra', 'Huevo entero',
    'Claras de huevo', 'Yogur griego natural', 'Leche descremada', 'Queso fresco',
    'Quinua cocida', 'Avena', 'Papa sancochada', 'Camote', 'Pasta integral cocida',
    'Pan integral', 'Lentejas cocidas', 'Garbanzos cocidos', 'Frijol negro cocido',
    'Manzana', 'Naranja', 'Fresas', 'Arandanos', 'Espinaca', 'Zanahoria', 'Tomate',
    'Coliflor', 'Aceite de oliva', 'Almendras', 'Mantequilla de mani', 'Agua de coco'
)
ORDER BY id;
