<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Deja listo para el generador de planes el catálogo real de alimentos.
 *
 * Los 35 alimentos reales tenían los nutrientes correctos (valores de USDA
 * FoodData Central por 100 g) pero no servían para generar menús: grupo de
 * menú cruzado (brócoli «carbohidrato», aceite «fruta»…), sin comidas
 * asignadas, porciones genéricas de 1 a 600, unidad en mililitros para sólidos
 * y `nutricion_verificada` = 100 en vez de 1. El generador sólo encontraba los
 * alimentos «[DEMO]» del script de datos sintéticos.
 *
 * - Corrige esos campos sin tocar los nutrientes.
 * - Desactiva (no borra) los alimentos «[DEMO]».
 *
 * Idempotente: se puede ejecutar varias veces. Busca por nombre, así que no
 * depende de los ids de cada entorno.
 *
 *   php artisan db:seed --class=CatalogoAlimentosRealSeeder
 */
class CatalogoAlimentosRealSeeder extends Seeder
{
    private const FUENTE_G = 'USDA FoodData Central (SR Legacy), valores por 100 g';

    private const FUENTE_ML = 'USDA FoodData Central (SR Legacy), valores por 100 ml';

    private const DESAYUNO = 'desayuno';

    private const ALMUERZO = 'almuerzo';

    private const CENA = 'cena';

    private const MEDIA_MANANA = 'media_manana';

    private const MEDIA_TARDE = 'media_tarde';

    public function run(): void
    {
        $principal = [self::ALMUERZO, self::CENA];
        $snack = [self::DESAYUNO, self::MEDIA_MANANA, self::MEDIA_TARDE];

        // nombre => [grupo_menu, tipos_comida, [min, max, paso], estado_preparacion, gramos_por_unidad]
        $catalogo = [
            'Pechuga de pollo' => ['proteina', $principal, [80, 350, 10], 'cocida, sin piel', null],
            'Pechuga de pavo' => ['proteina', [self::DESAYUNO, ...$principal], [60, 250, 10], 'cocida, sin piel', null],
            'Atun en agua' => ['proteina', $principal, [60, 200, 10], 'en conserva, escurrido', null],
            'Salmon' => ['proteina', $principal, [80, 250, 10], 'crudo, peso antes de cocinar', null],
            'Carne de res magra' => ['proteina', $principal, [80, 250, 10], 'cocida', null],
            'Huevo entero' => ['proteina', [self::DESAYUNO, self::CENA, self::MEDIA_MANANA], [50, 200, 50], 'crudo, sin cascara', 50],
            'Claras de huevo' => ['proteina', [self::DESAYUNO, self::CENA, self::MEDIA_MANANA], [30, 240, 30], 'crudas', null],
            'Yogur griego natural' => ['proteina', $snack, [100, 300, 25], 'natural, sin azucar', null],
            'Leche descremada' => ['proteina', [self::DESAYUNO, self::MEDIA_TARDE], [150, 400, 50], 'liquida', null],
            'Queso fresco' => ['proteina', $snack, [30, 120, 10], 'fresco', null],
            'Arroz integral' => ['carbohidrato', $principal, [80, 600, 10], 'cocido', null],
            'Quinua cocida' => ['carbohidrato', [self::DESAYUNO, ...$principal], [80, 600, 10], 'cocida', null],
            'Avena' => ['carbohidrato', [self::DESAYUNO, self::MEDIA_MANANA], [30, 100, 5], 'en hojuelas, seca', null],
            'Papa sancochada' => ['carbohidrato', $principal, [100, 600, 10], 'sancochada, con piel', null],
            'Camote' => ['carbohidrato', $principal, [100, 500, 10], 'crudo, peso antes de cocinar', null],
            'Pasta integral cocida' => ['carbohidrato', $principal, [80, 600, 10], 'cocida', null],
            'Pan integral' => ['carbohidrato', [self::DESAYUNO, self::CENA], [30, 120, 30], 'rebanada', 30],
            'Lentejas cocidas' => ['carbohidrato', [self::ALMUERZO], [100, 500, 10], 'cocidas', null],
            'Garbanzos cocidos' => ['carbohidrato', [self::ALMUERZO], [80, 450, 10], 'cocidos', null],
            'Frijol negro cocido' => ['carbohidrato', [self::ALMUERZO], [100, 500, 10], 'cocido', null],
            'Platano' => ['fruta', $snack, [60, 240, 10], 'crudo, sin cascara', 118],
            'Manzana' => ['fruta', $snack, [100, 250, 10], 'cruda, con cascara', 180],
            'Naranja' => ['fruta', $snack, [100, 260, 10], 'cruda, sin cascara', 130],
            'Fresas' => ['fruta', $snack, [80, 250, 10], 'crudas', null],
            'Arandanos' => ['fruta', $snack, [50, 200, 10], 'crudos', null],
            'Brocoli' => ['verdura', $principal, [50, 300, 10], 'crudo', null],
            'Espinaca' => ['verdura', $principal, [50, 300, 10], 'cruda', null],
            'Zanahoria' => ['verdura', $principal, [50, 300, 10], 'cruda', null],
            'Tomate' => ['verdura', $principal, [50, 300, 10], 'crudo', null],
            'Coliflor' => ['verdura', $principal, [50, 300, 10], 'cruda', null],
            'Palta' => ['grasa', [self::DESAYUNO, ...$principal, self::MEDIA_TARDE], [25, 200, 5], 'cruda, sin pepa', null],
            'Aceite de oliva' => ['grasa', $principal, [5, 40, 5], 'crudo', null],
            'Almendras' => ['grasa', $snack, [10, 40, 5], 'crudas', null],
            'Mantequilla de mani' => ['grasa', $snack, [10, 40, 5], 'natural', null],
            // Bebida: nutrientes verificados, pero no forma parte de los grupos
            // de menú, así que el generador no la elige.
            'Agua de coco' => [null, null, [200, 500, 50], 'natural', null],
        ];
        $liquidos = ['Leche descremada' => 1.035, 'Agua de coco' => 1.02];

        DB::transaction(function () use ($catalogo, $liquidos) {
            // Errata heredada del dato original.
            DB::table('alimentos')->where('nombre', 'Pechuga de pollos')
                ->update(['nombre' => 'Pechuga de pollo', 'updated_at' => now()]);

            foreach ($catalogo as $nombre => [$grupo, $comidas, [$min, $max, $paso], $estado, $gramosUnidad]) {
                $liquido = array_key_exists($nombre, $liquidos);
                DB::table('alimentos')->where('nombre', $nombre)->update([
                    'grupo_menu' => $grupo,
                    'tipos_comida' => $comidas === null ? null : json_encode($comidas),
                    'porcion_min' => $min,
                    'porcion_max' => $max,
                    'paso_porcion' => $paso,
                    'base_unidad' => $liquido ? 'mililitros' : 'gramos',
                    'densidad_g_ml' => $liquido ? $liquidos[$nombre] : null,
                    'gramos_por_unidad' => $gramosUnidad,
                    'estado_preparacion' => $estado,
                    'fuente_nutricional' => $liquido ? self::FUENTE_ML : self::FUENTE_G,
                    'nutricion_verificada' => true,
                    'activo' => true,
                    'updated_at' => now(),
                ]);
            }

            // Datos sintéticos de `database/gym_bros_datos_ficticios_alimentacion.sql`:
            // se retiran de los menús sin borrarlos (los planes antiguos los citan).
            DB::table('alimentos')->where('nombre', 'like', '[DEMO]%')
                ->update(['activo' => false, 'updated_at' => now()]);
        });
    }
}
