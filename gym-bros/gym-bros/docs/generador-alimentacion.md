# Generador de planes de alimentacion

> DOCUMENTO HISTORICO: el contrato actual es [perfil-alimentario-flutter.md](perfil-alimentario-flutter.md).
> Por solicitud del propietario se retiraron las tres tablas de restricciones y sus
> endpoints. Ya no se excluyen alergias/intolerancias automaticamente: solo alimentos
> rechazados o inactivos. Las secciones de restricciones de este diagnostico ya no aplican.

## Estado actual

Implementacion aditiva al proyecto C:/laragon/www/gym-bros. Conserva los endpoints
anteriores, los modelos originales y el historial. La adaptacion Flutter se detalla
en [perfil-alimentario-flutter.md](perfil-alimentario-flutter.md), incluyendo QA,
autorizacion por usuario y ejemplos JSON exactos.

El esquema real contiene 35 alimentos, 3 evaluaciones, 2 planes, 4 comidas y
7 relaciones comida-alimento al momento del diagnostico. No habia generador.
Las alturas 1.76, 1.62 y 165.00 no tenian unidad explicita. Los nutrientes de
los alimentos de prueba no tienen procedencia ni base verificadas en columnas.

Las dos migraciones ya fueron aplicadas en la base real con autorizacion del
propietario y respaldo previo. El API esta habilitado; no espera mas aprobaciones
de despliegue. ALIMENTACION_HABILITADA controla exclusivamente disponibilidad
tecnica y su valor por defecto es true. No certifica una revision nutricional.

Para generar para una persona, sus datos deben estar completos:

1. Confirmar las alturas historicas y marcar su unidad; el algoritmo NO convierte
   automaticamente 1.76 en 176 ni presupone que 165 representa centimetros.
2. Registrar un catalogo de restricciones sin sinonimos duplicados, revisar cada
   alimento y registrar su procedencia nutricional, base, preparacion y porciones.
3. Registrar el perfil alimentario y preferencias explicitas de cada usuario.
   La revision profesional es metadata opcional, no un requisito del generador.
4. Utilizar las reglas dentro de su alcance con seguimiento profesional, sin
   confundir resultados matematicos con una prescripcion clinica individual.

La variable ALIMENTACION_REGLAS_REVISADAS fue retirada para no equiparar
aprobacion tecnica con revision profesional. Tras desplegar habia cero perfiles
alimentarios y cero alimentos con metadatos verificados; no se inventaron esos datos.

No se certifican ni completan los alimentos historicos automaticamente. El SQL
anterior de 30 alimentos contiene valores aproximados de prueba y no sirve como
certificacion nutricional. Si faltan datos, el generador devuelve 422 con su causa,
no un 503 de aprobacion pendiente. No se crearon planes ficticios en la base real.

## Rutas

```text
POST /api/planesalimentacion/generar/{id_usuario}
GET /api/usuarios/{id_usuario}/planesalimentacion/{id_plan}
GET /api/usuarios/{id_usuario}/perfil-alimentario
PUT /api/usuarios/{id_usuario}/perfil-alimentario
PUT /api/alimentos/{id_alimento}/nutricion
GET /api/restriccionesalimentarias
POST /api/restriccionesalimentarias
```

Las rutas nuevas devuelven JSON incluso sin Accept. Los recursos ausentes devuelven
404; los datos incompatibles, 422. Un 503 queda reservado para deshabilitacion
tecnica o instalaciones sin el esquema necesario. Crear un
plan devuelve 201. El GET de detalle se limita al par usuario-plan y a planes del
nuevo generador; el listado anterior sigue disponible para planes historicos.

IMPORTANTE: no hay login activo para estas rutas. El acceso anonimo solo se conserva
en local/testing sin Authorization y puede deshabilitarse por configuracion. Una
identidad autenticada debe ser el Usuario propietario o tener permiso explicito
del Gate gestionar-alimentacion. El User de Laravel no se equipara por numero de ID.
Antes de produccion conectar la identidad real al guard y revisar los permisos del
catalogo; fuera de local/testing las rutas por usuario exigen autenticacion.
revision_profesional sigue siendo metadata declarada, no certificacion de identidad.

## Solicitud de generacion

- fecha_inicio: fecha Y-m-d, desde hoy hasta 30 dias adelante.
- duracion_dias: entero 1 a 14, independiente de los dias de entrenamiento.
- cantidad_comidas: 3, 4 o 5.
- horarios: objeto con todos los tipos correspondientes y horas H:i, distintas
  y cronologicas. No hay horarios implicitos.
- Para 3: desayuno, almuerzo, cena.
- Para 4: desayuno, almuerzo, media_tarde, cena.
- Para 5: desayuno, media_manana, almuerzo, media_tarde, cena.

El objetivo, peso, altura y actividad se obtienen de la ultima evaluacion del
usuario (fecha_evaluacion DESC, id DESC). No se aceptan desde el body del generador.
La edad se calcula con fecha_nacimiento; debe coincidir con la edad registrada
al momento de evaluar. sexo_calculo se registra explicitamente, no se deduce de genero.
Se valida la vigencia hasta el ultimo dia solicitado.

Cada llamada valida crea un plan NUEVO. No reemplaza, elimina ni desactiva planes
anteriores. No hay idempotencia: un reintento de POST puede crear otro plan.
El cliente debe evitar reintentos automaticos y consultar el ID obtenido.
Si cambia el perfil o una alergia, se debe generar y revisar un nuevo plan; el
historial conserva las condiciones y cantidades anteriores, no se actualiza solo.

## Perfil alimentario

PUT recibe sexo_calculo (masculino/femenino), embarazo, lactancia,
requiere_plan_clinico, apto_plan_general (booleanos obligatorios) y preferencias
(array de objetos id_alimentos, tipo: preferido/rechazado). No admite alimentos
repetidos; permite enviar el catalogo completo. revision_profesional (hasta 200
caracteres) y revisado_en (Y-m-d no futura) son opcionales y nullable: omitirlos o
enviar null conserva valores anteriores, sin fechas ni revisiones automaticas.
alergias e intolerancias son arrays opcionales de IDs de restricciones_alimentarias,
no de alimentos: omitirlos o enviar [] conserva antecedentes; otros IDs se agregan.

PUT crea o actualiza el perfil dentro de una transaccion. Actualiza solo las
preferencias enviadas de ese usuario y conserva las omitidas; activo no se
interpreta como rechazo. GET devuelve las preferencias activas dentro de data.
Una preferencia historica activa con tipo null bloquea
la generacion hasta que el operador confirme su significado mediante este endpoint.
Un rechazo siempre prevalece sobre una preferencia. Alergias e intolerancias se
excluyen con las mismas reglas estrictas; las restricciones fisicas no se reutilizan.

## Catalogo nutricional y restricciones

POST de restricciones recibe codigo unico (minusculas, numeros y guion bajo,
comenzando por una letra) y nombre. No hay un catalogo universal precargado.
Al crear una categoria nueva, los alimentos quedan con restricciones_verificadas=false
para obligar a revisarlos frente a esa nueva categoria. No se alteran sus nutrientes.
Definir primero las categorias evita repetir la revision de todos los alimentos.

PUT de nutricion requiere los cinco valores originales: calorias (kcal), proteinas,
carbohidratos, grasas y fibra (g); todos corresponden a 100 unidades de base_unidad,
que debe ser gramos o mililitros. Tambien requiere:

- estado_preparacion: identifica el alimento tal como se consume o pesa.
- fuente_nutricional: referencia concreta, identificador/version/fecha o etiqueta
  comprobada. Un texto no vacio no sustituye la revision de su veracidad.
- nutricion_verificada y restricciones_verificadas: booleanos.
- gramos_por_unidad y densidad_g_ml: numeros positivos o null explicito.
- grupo_menu: proteina, carbohidrato, grasa, fruta o verdura; es el papel en el menu,
  no sustituye el campo tipo original (un lacteo podria cumplir el papel proteina).
- tipos_comida: array no vacio de los tipos de comida admitidos para ese alimento.
- porcion_min, porcion_max, paso_porcion: cantidades en la misma base_unidad, con
  dos decimales, positivas y con al menos una cantidad representable entre limites.
- restricciones: array explicito de IDs existentes, incluyendo ingredientes y
  riesgos de trazas identificados en la revision. [] significa revision sin
  coincidencias dentro del catalogo definido, NO una garantia universal de seguridad.

PUT conserva nombre y tipo originales; no cambia alimentos ni perfiles ajenos al
ID solicitado. El generador excluye alimentos no verificados, con metadatos ausentes,
rechazados o asociados a cualquier restriccion del usuario.

No hay conversion automatica entre crudo/cocido: deben ser entradas nutricionales
distintas. La cantidad generada se expresa en la base original, sin conversion.
El servicio de conversion requiere gramos_por_unidad para unidades y densidad_g_ml
para pasar entre peso y volumen; nunca asume que un mililitro equivale a un gramo.

## Calculo, limites y fuentes

Se utiliza la ecuacion simplificada de Mifflin-St Jeor para gasto en reposo:
10*peso_kg + 6.25*altura_cm - 5*edad + constante (5 masculino, -161 femenino).
Es una estimacion en adultos sanos, no una medicion individual.
Fuente primaria: https://pubmed.ncbi.nlm.nih.gov/2305711/?format=pubmed

El gasto estimado se multiplica por un factor de actividad y un ajuste de objetivo.
FAO describe la estimacion mediante actividad habitual; el mapeo de nuestros CUATRO
valores de actividad a factores es una decision provisional del producto, no una
tabla literal de FAO ni una validacion de combinar cualquier formula con esos factores.
Fuente: https://www.fao.org/4/y5686e/y5686e07.htm

Las fracciones de energia se convierten en gramos usando 4 kcal/g para proteinas
y carbohidratos y 9 kcal/g para grasas. Los repartos iniciales por objetivo NO son
prescripciones de perdida de peso o rendimiento. Los rangos generales de referencia
son contexto, no justifican individualmente esos repartos:
https://www.ncbi.nlm.nih.gov/books/NBK208874/

Los valores reales de energia del alimento se suman desde su fuente, no se sustituyen
por la aproximacion 4/4/9. El control de coherencia admite diferencias: no certifica
la exactitud de la fuente. USDA documenta bases y porciones de sus conjuntos:
https://fdc.nal.usda.gov/portal-data/external/dataDictionary
https://fdc.nal.usda.gov/GBFPD_Documentation/

config/alimentacion.php centraliza:
- Alcance provisional: 19-65 anos, 40-200 kg, 130-220 cm y evaluacion
  de hasta 90 dias. La revision profesional ya no condiciona la generacion.
  Son limites operativos de esta version, no diagnosticos.
- Embarazo, lactancia, necesidad de plan clinico o falta de aptitud declarada
  bloquean el plan general. No se infiere ausencia de enfermedad a partir del peso.
- Factores de actividad: 1.4, 1.6, 1.8 y 2.0. Ajustes iniciales: -10% perdida,
  +5% ganancia/fuerza y 0% para los demas. TODOS requieren revision profesional.
- Distribucion 3 comidas: 30/40/30; 4: 25/35/10/30; 5: 25/10/30/10/25.
- Tolerancias de QA: energia 8%; cada macronutriente 15%, por comida y por dia.

La seleccion usa plantillas de grupos y tipos_comida revisados. Alterna alimentos
menos usados y favorece preferencias entre candidatos de igual uso. La variedad
depende del catalogo; no inventa recetas ni garantiza un menu distinto cada dia.
Un descenso por coordenadas acotado ajusta cantidades; despues redondea al paso de
porcion y vuelve a sumar nutrientes. La busqueda usa como maximo cuatro candidatos
por grupo y 80 iteraciones por combinacion. Un 422 significa que la busqueda limitada
no encontro una combinacion, no demuestra que ninguna solucion matematica exista.

No se garantiza suficiencia de micronutrientes, sodio, agua, calidad de grasas,
seguridad culinaria o ausencia de contaminacion cruzada. Estos puntos requieren
revision profesional y ampliacion de datos antes de ofrecer un plan integral.

## Persistencia y compatibilidad

Las nuevas columnas son nullable o tienen defaults de no verificado. Los registros
antiguos no se transforman. La cadena plan -> comidas -> comida_alimentos se conserva.
Se agregan fecha/dia, vinculo con evaluacion y snapshots de calculo y nutrientes.
Una transaccion guarda todo; un fallo revierte incluso inserciones ya realizadas.
Consultar un plan no recalcula con un catalogo editado posteriormente.

Antes de aplicar migraciones, las rutas nuevas devuelven 503 y las anteriores
conservan su comportamiento. Despues, crear/actualizar una altura exige centimetros
entre 30 y 250 y registra altura_unidad=cm. Ese rango de captura es distinto del
alcance adulto del generador. Editar otro campo NO confirma una altura historica.

## Auditoria y despliegue realizado

`php artisan alimentacion:auditar-alturas` es solo lectura, incluso antes de migrar.
Revisar cada ID con su valor original. Tras confirmar la unidad,
una correccion debe actualizar el ID exacto y comprobar el valor antiguo en el WHERE,
ejecutarse dentro de transaccion y verificar una sola fila afectada. No hacer UPDATE
masivos multiplicando todas las alturas. Guardar el valor anterior para reversibilidad.

Migraciones ejecutadas con respaldo y aprobacion del propietario:

```text
php artisan migrate --path=database/migrations/2026_09_12_000001_add_altura_unidad_to_evaluaciones_fisicas.php
php artisan migrate --path=database/migrations/2026_09_12_000002_prepare_meal_plan_generation.php
```

Hacer respaldo antes. El rollback DDL elimina las nuevas columnas/tablas y perderia
los metadatos nuevos: no es una operacion automatica ni un procedimiento de rescate
para produccion. MySQL no revierte DDL completo mediante una transaccion ordinaria.
No se uso migrate:fresh. Solo se aplicaron las dos migraciones de alimentacion;
las huellas de las columnas originales confirmaron que sus registros se conservaron.
