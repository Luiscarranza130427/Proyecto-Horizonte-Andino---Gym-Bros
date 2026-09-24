<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Añade ejercicios de cardio básicos al catálogo.
 *
 * Sin ninguno, las rutinas con objetivo «resistencia» o «perdida_peso» (que
 * piden 5 minutos de cardio por sesión) se generaban sin ese bloque y con la
 * advertencia «No hay cardio compatible disponible».
 *
 * - Nivel principiante: sirven a todos los niveles.
 * - Se activan para las empresas que ya tienen catálogo de ejercicios.
 * - Imagen genérica actual y sin video: se pueden cambiar desde el panel.
 *
 * Idempotente: no duplica si ya existen con el mismo nombre.
 *
 *   php artisan db:seed --class=EjerciciosCardioSeeder
 */
class EjerciciosCardioSeeder extends Seeder
{
    private const IMAGEN = 'ejercicios/trabajar-musculo.webp';

    public function run(): void
    {
        // nombre => [grupo principal, equipamiento, descripcion, instrucciones]
        $ejercicios = [
            'Caminata en cinta' => ['cuadriceps', 'cinta de correr',
                'Cardio de bajo impacto en cinta.',
                'Caminar a paso ligero con la espalda recta, sin apoyarse en las barras. Aumentar la inclinacion en lugar de la velocidad si se busca mas intensidad.'],
            'Bicicleta estatica' => ['cuadriceps', 'bicicleta estatica',
                'Cardio sentado de bajo impacto para piernas.',
                'Ajustar el asiento a la altura de la cadera y pedalear con cadencia constante, sin balancear el tronco.'],
            'Eliptica' => ['gluteos', 'eliptica',
                'Cardio de cuerpo completo sin impacto.',
                'Mantener los pies apoyados en toda la pisada, empujar y tirar de los brazos de forma coordinada y conservar la postura erguida.'],
            'Remo en maquina' => ['espalda', 'remo ergometro',
                'Cardio de cuerpo completo con traccion.',
                'Empujar primero con las piernas, luego inclinar levemente el tronco y terminar tirando con los brazos; volver en orden inverso y sin redondear la espalda.'],
        ];

        DB::transaction(function () use ($ejercicios) {
            $grupos = DB::table('grupos_musculares')->pluck('id', 'tipo');
            $empresas = DB::table('empresa_ejercicio')->distinct()->pluck('id_empresas');

            foreach ($ejercicios as $nombre => [$grupo, $equipo, $descripcion, $instrucciones]) {
                $id = DB::table('ejercicios')->where('nombre', $nombre)->value('id')
                    ?? DB::table('ejercicios')->insertGetId([
                        'nombre' => $nombre,
                        'descripcion' => $descripcion,
                        'tipo' => 'cardio',
                        'instrucciones' => $instrucciones,
                        'nivel' => 'principiante',
                        'equipamiento' => $equipo,
                        'estado' => true,
                        'enlace_video' => null,
                        'imagen_ejercicio' => self::IMAGEN,
                        'id_grupos_musculares' => $grupos[$grupo],
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);

                foreach ($empresas as $empresa) {
                    DB::table('empresa_ejercicio')->updateOrInsert(
                        ['id_empresas' => $empresa, 'id_ejercicios' => $id],
                        ['estado' => true, 'updated_at' => now(), 'created_at' => now()],
                    );
                }
            }
        });
    }
}
