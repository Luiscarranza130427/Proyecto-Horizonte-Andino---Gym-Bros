<script setup>
import { Activity, Utensils } from 'lucide-vue-next'
import { ref, useTemplateRef } from 'vue'

import { useFormulario } from '@/shared/composables/useFormulario'
import { TIPOS_ALIMENTO, UNIDADES, valoresDe } from '@/modules/alimentacion/catalogos'

const props = defineProps({
  valoresIniciales: { type: Object, default: () => ({}) },
  enviando: { type: Boolean, default: false },
  erroresServidor: { type: Object, default: () => ({}) },
  modo: { type: String, default: 'create' },
})

const emit = defineEmits(['submit', 'cancel'])

/**
 * Los siete campos que el servicio envía (`CAMPOS_EDITABLES_ALIMENTO`).
 *
 * No hay control de estado ni de unidad a propósito: el servicio no los manda
 * —la unidad la deriva el backend del tipo— y un campo que nadie lee haría creer
 * al administrador que ha cambiado algo.
 *
 * Los macros arrancan vacíos y no en cero: un cero prerrellenado se envía sin
 * mirar, y «0 g de proteínas» es un dato, no un campo sin rellenar.
 */
const MODELO_VACIO = {
  nombre: '',
  tipo: '',
  calorias: '',
  proteinas: '',
  carbohidratos: '',
  grasas: '',
  fibra: '',
  activo: '',
  unidadBase: '',
  estadoPreparacion: '',
  gramosPorUnidad: '',
  densidadGml: '',
  fuenteNutricional: '',
  nutricionVerificada: '',
  restriccionesVerificadas: '',
  grupoMenu: '',
  tiposComida: [],
  porcionMin: '',
  porcionMax: '',
  pasoPorcion: '',
}

const CAMPOS_CONFIGURACION = [
  { clave: 'estadoPreparacion', etiqueta: 'Estado de preparación' },
  { clave: 'grupoMenu', etiqueta: 'Grupo de menú' },
  { clave: 'tiposComida', etiqueta: 'Tipos de comida' },
  { clave: 'fuenteNutricional', etiqueta: 'Fuente nutricional' },
]

const CAMPOS_PORCION = [
  { clave: 'gramosPorUnidad', etiqueta: 'Gramos por unidad', sufijo: 'g' },
  { clave: 'densidadGml', etiqueta: 'Densidad', sufijo: 'g/ml' },
  { clave: 'porcionMin', etiqueta: 'Porción mínima', sufijo: 'g' },
  { clave: 'porcionMax', etiqueta: 'Porción máxima', sufijo: 'g' },
  { clave: 'pasoPorcion', etiqueta: 'Paso de porción', sufijo: 'g' },
]

const TIPOS_COMIDA_DISPONIBLES = [
  { valor: 'desayuno', etiqueta: 'Desayuno' },
  { valor: 'media_manana', etiqueta: 'Media mañana' },
  { valor: 'almuerzo', etiqueta: 'Almuerzo' },
  { valor: 'media_tarde', etiqueta: 'Media tarde' },
  { valor: 'cena', etiqueta: 'Cena' },
]

const nombreInput = useTemplateRef('nombreInput')
const tipoInput = useTemplateRef('tipoInput')
const caloriasInput = useTemplateRef('caloriasInput')
const proteinasInput = useTemplateRef('proteinasInput')
const carbohidratosInput = useTemplateRef('carbohidratosInput')
const grasasInput = useTemplateRef('grasasInput')
const fibraInput = useTemplateRef('fibraInput')

/**
 * Macro admisible: número mayor o igual que cero, con decimales.
 *
 * El vacío se rechaza explícitamente porque `Number('')` es 0: sin esta
 * comprobación, borrar el campo se guardaría como un cero silencioso. Y son
 * decimales, no enteros: 3,6 g de grasa por 100 g es un valor corriente.
 */
function esNumeroNoNegativo(valor) {
  const texto = String(valor).trim()
  if (!texto) return false
  const numero = Number(texto)
  return Number.isFinite(numero) && numero >= 0
}

const MACROS = ['calorias', 'proteinas', 'carbohidratos', 'grasas', 'fibra']
const tiposComidaOriginal = ref([])

function normalizarTiposComida(valor) {
  if (!Array.isArray(valor)) return []
  const permitidos = new Set(TIPOS_COMIDA_DISPONIBLES.map((opcion) => opcion.valor))
  return [...new Set(valor.filter((opcion) => permitidos.has(opcion)))]
}

function sonIgualesLosTiposComida(a, b) {
  return a.length === b.length && a.every((valor) => b.includes(valor))
}

function valoresParaFormulario() {
  const valores = props.valoresIniciales
  return {
    ...valores,
    tiposComida: normalizarTiposComida(valores.tiposComida),
  }
}

function validar(datos, errores) {
  if (datos.nombre.trim().length < 3) {
    errores.nombre = 'Introduce un nombre de al menos 3 caracteres.'
  }

  if (!valoresDe(TIPOS_ALIMENTO).includes(datos.tipo)) {
    errores.tipo = 'Selecciona un tipo válido.'
  }

  MACROS.forEach((campo) => {
    if (!esNumeroNoNegativo(datos[campo])) {
      errores[campo] = 'Introduce un número igual o mayor que 0.'
    }
  })

  if (
    props.modo === 'edit' &&
    !sonIgualesLosTiposComida(datos.tiposComida, tiposComidaOriginal.value) &&
    !datos.tiposComida.length
  ) {
    errores.tiposComida = 'Selecciona al menos un tipo de comida o conserva la selección actual.'
  }
}

const { formulario, erroresLocales, erroresRemotos, errorDe, limpiarError, validarParaEnviar } =
  useFormulario({
    modeloVacio: MODELO_VACIO,
    valoresIniciales: valoresParaFormulario,
    erroresServidor: () => props.erroresServidor,
    referencias: {
      nombre: nombreInput,
      tipo: tipoInput,
      calorias: caloriasInput,
      proteinas: proteinasInput,
      carbohidratos: carbohidratosInput,
      grasas: grasasInput,
      fibra: fibraInput,
    },
    validar,
    alCargarValores: (datos) => {
      datos.tiposComida = normalizarTiposComida(datos.tiposComida)
      tiposComidaOriginal.value = [...datos.tiposComida]
    },
  })

async function enviar() {
  if (props.enviando) return
  if (!(await validarParaEnviar())) return

  const datos = {
    ...formulario,
    nombre: formulario.nombre.trim(),
    ...Object.fromEntries(MACROS.map((campo) => [campo, Number(formulario[campo])])),
  }

  if (props.modo !== 'edit') {
    Object.keys(MODELO_VACIO)
      .filter((campo) => !['nombre', 'tipo', ...MACROS].includes(campo))
      .forEach((campo) => delete datos[campo])
  } else {
    datos.tiposComida = normalizarTiposComida(datos.tiposComida)
    if (sonIgualesLosTiposComida(datos.tiposComida, tiposComidaOriginal.value)) {
      delete datos.tiposComida
    }
    /*
     * La configuración del generador (base, preparación, porciones...) sólo
     * viaja si el administrador la cambió. Antes se reenviaba entera, con
     * vacíos incluidos, y editar las calorías de un alimento sin esa
     * configuración devolvía 422 exigiendo seis campos que nadie había tocado.
     */
    const original = valoresParaFormulario()
    Object.keys(MODELO_VACIO)
      .filter((campo) => !['nombre', 'tipo', 'tiposComida', ...MACROS].includes(campo))
      .forEach((campo) => {
        const valor = datos[campo]
        const vacio = valor === '' || valor === null || valor === undefined
        if (vacio || String(valor) === String(original[campo] ?? '')) delete datos[campo]
      })
  }

  emit('submit', datos)
}
</script>

<template>
  <form class="formulario" autocomplete="off" novalidate @submit.prevent="enviar">
    <p class="visually-hidden" aria-live="polite">
      {{
        Object.keys(erroresRemotos).length || Object.keys(erroresLocales).length
          ? 'Revisa los campos marcados en el formulario.'
          : ''
      }}
    </p>

    <section class="formulario__seccion gb-tarjeta" aria-labelledby="titulo-alimento">
      <header>
        <span aria-hidden="true"><Utensils :size="20" /></span>
        <div>
          <h2 id="titulo-alimento">Identificación del alimento</h2>
          <p>Cómo se llama y en qué grupo entra dentro del catálogo.</p>
        </div>
      </header>

      <div class="formulario__rejilla">
        <div class="campo">
          <label class="form-label" for="alimento-nombre">Nombre del alimento *</label>
          <input
            id="alimento-nombre"
            ref="nombreInput"
            v-model="formulario.nombre"
            class="form-control"
            :class="{ 'is-invalid': errorDe('nombre') }"
            type="text"
            name="nombre"
            maxlength="80"
            required
            :aria-invalid="Boolean(errorDe('nombre'))"
            :aria-describedby="errorDe('nombre') ? 'error-nombre' : null"
            @input="limpiarError('nombre')"
          />
          <p v-if="errorDe('nombre')" id="error-nombre" class="campo__error" role="alert">
            {{ errorDe('nombre') }}
          </p>
        </div>

        <div class="campo">
          <label class="form-label" for="alimento-tipo">Tipo *</label>
          <select
            id="alimento-tipo"
            ref="tipoInput"
            v-model="formulario.tipo"
            class="form-select"
            :class="{ 'is-invalid': errorDe('tipo') }"
            name="tipo"
            required
            :aria-invalid="Boolean(errorDe('tipo'))"
            :aria-describedby="errorDe('tipo') ? 'error-tipo' : 'ayuda-tipo'"
            @change="limpiarError('tipo')"
          >
            <option value="">Selecciona un tipo</option>
            <option v-for="opcion in TIPOS_ALIMENTO" :key="opcion.valor" :value="opcion.valor">
              {{ opcion.etiqueta }}
            </option>
          </select>
          <p id="ayuda-tipo" class="campo__ayuda">
            De él depende la unidad en que se mide el alimento al añadirlo a una comida.
          </p>
          <p v-if="errorDe('tipo')" id="error-tipo" class="campo__error" role="alert">
            {{ errorDe('tipo') }}
          </p>
        </div>
      </div>
    </section>

    <section class="formulario__seccion gb-tarjeta" aria-labelledby="titulo-nutricion">
      <header>
        <span aria-hidden="true"><Activity :size="20" /></span>
        <div>
          <h2 id="titulo-nutricion">Información nutricional</h2>
          <p>
            Todos los valores se entienden <b>por cada 100 g o 100 ml</b> del alimento. Al armar una
            comida se escalan según la cantidad servida.
          </p>
        </div>
      </header>

      <div class="formulario__rejilla formulario__rejilla--macros">
        <div class="campo">
          <label class="form-label" for="alimento-calorias">Energía (kcal) *</label>
          <input
            id="alimento-calorias"
            ref="caloriasInput"
            v-model="formulario.calorias"
            class="form-control"
            :class="{ 'is-invalid': errorDe('calorias') }"
            type="number"
            name="calorias"
            inputmode="decimal"
            min="0"
            step="0.1"
            required
            :aria-invalid="Boolean(errorDe('calorias'))"
            :aria-describedby="errorDe('calorias') ? 'error-calorias' : null"
            @input="limpiarError('calorias')"
          />
          <p v-if="errorDe('calorias')" id="error-calorias" class="campo__error" role="alert">
            {{ errorDe('calorias') }}
          </p>
        </div>

        <div class="campo">
          <label class="form-label" for="alimento-proteinas">Proteínas (g) *</label>
          <input
            id="alimento-proteinas"
            ref="proteinasInput"
            v-model="formulario.proteinas"
            class="form-control"
            :class="{ 'is-invalid': errorDe('proteinas') }"
            type="number"
            name="proteinas"
            inputmode="decimal"
            min="0"
            step="0.1"
            required
            :aria-invalid="Boolean(errorDe('proteinas'))"
            :aria-describedby="errorDe('proteinas') ? 'error-proteinas' : null"
            @input="limpiarError('proteinas')"
          />
          <p v-if="errorDe('proteinas')" id="error-proteinas" class="campo__error" role="alert">
            {{ errorDe('proteinas') }}
          </p>
        </div>

        <div class="campo">
          <label class="form-label" for="alimento-carbohidratos">Carbohidratos (g) *</label>
          <input
            id="alimento-carbohidratos"
            ref="carbohidratosInput"
            v-model="formulario.carbohidratos"
            class="form-control"
            :class="{ 'is-invalid': errorDe('carbohidratos') }"
            type="number"
            name="carbohidratos"
            inputmode="decimal"
            min="0"
            step="0.1"
            required
            :aria-invalid="Boolean(errorDe('carbohidratos'))"
            :aria-describedby="errorDe('carbohidratos') ? 'error-carbohidratos' : null"
            @input="limpiarError('carbohidratos')"
          />
          <p
            v-if="errorDe('carbohidratos')"
            id="error-carbohidratos"
            class="campo__error"
            role="alert"
          >
            {{ errorDe('carbohidratos') }}
          </p>
        </div>

        <div class="campo">
          <label class="form-label" for="alimento-grasas">Grasas (g) *</label>
          <input
            id="alimento-grasas"
            ref="grasasInput"
            v-model="formulario.grasas"
            class="form-control"
            :class="{ 'is-invalid': errorDe('grasas') }"
            type="number"
            name="grasas"
            inputmode="decimal"
            min="0"
            step="0.1"
            required
            :aria-invalid="Boolean(errorDe('grasas'))"
            :aria-describedby="errorDe('grasas') ? 'error-grasas' : null"
            @input="limpiarError('grasas')"
          />
          <p v-if="errorDe('grasas')" id="error-grasas" class="campo__error" role="alert">
            {{ errorDe('grasas') }}
          </p>
        </div>

        <div class="campo">
          <label class="form-label" for="alimento-fibra">Fibra (g) *</label>
          <input
            id="alimento-fibra"
            ref="fibraInput"
            v-model="formulario.fibra"
            class="form-control"
            :class="{ 'is-invalid': errorDe('fibra') }"
            type="number"
            name="fibra"
            inputmode="decimal"
            min="0"
            step="0.1"
            required
            :aria-invalid="Boolean(errorDe('fibra'))"
            :aria-describedby="errorDe('fibra') ? 'error-fibra' : 'ayuda-fibra'"
            @input="limpiarError('fibra')"
          />
          <p id="ayuda-fibra" class="campo__ayuda">Cero en los alimentos que no aportan fibra.</p>
          <p v-if="errorDe('fibra')" id="error-fibra" class="campo__error" role="alert">
            {{ errorDe('fibra') }}
          </p>
        </div>
      </div>
    </section>

    <template v-if="modo === 'edit'">
      <section class="formulario__seccion gb-tarjeta" aria-labelledby="titulo-configuracion">
        <header>
          <span aria-hidden="true"><Utensils :size="20" /></span>
          <div>
            <h2 id="titulo-configuracion">Configuración del catálogo</h2>
            <p>Datos operativos, de preparación y clasificación del alimento.</p>
          </div>
        </header>

        <div class="formulario__rejilla formulario__rejilla--tres">
          <div class="campo">
            <label class="form-label" for="alimento-activo">Activo</label>
            <select
              id="alimento-activo"
              v-model="formulario.activo"
              class="form-select"
              name="activo"
              @change="limpiarError('activo')"
            >
              <option value="">No especificado</option>
              <option :value="true">Sí</option>
              <option :value="false">No</option>
            </select>
            <p v-if="errorDe('activo')" class="campo__error" role="alert">
              {{ errorDe('activo') }}
            </p>
          </div>

          <div class="campo">
            <label class="form-label" for="alimento-unidad-base">Unidad base</label>
            <select
              id="alimento-unidad-base"
              v-model="formulario.unidadBase"
              class="form-select"
              name="unidadBase"
              @change="limpiarError('unidadBase')"
            >
              <option value="">No especificada</option>
              <option v-for="unidad in UNIDADES" :key="unidad.valor" :value="unidad.valor">
                {{ unidad.nombre }} ({{ unidad.etiqueta }})
              </option>
            </select>
            <p v-if="errorDe('unidadBase')" class="campo__error" role="alert">
              {{ errorDe('unidadBase') }}
            </p>
          </div>

          <div
            v-for="campo in CAMPOS_CONFIGURACION.filter((campo) => campo.clave !== 'tiposComida')"
            :key="campo.clave"
            class="campo"
          >
            <label class="form-label" :for="`alimento-${campo.clave}`">{{ campo.etiqueta }}</label>
            <input
              :id="`alimento-${campo.clave}`"
              v-model="formulario[campo.clave]"
              class="form-control"
              :class="{ 'is-invalid': errorDe(campo.clave) }"
              type="text"
              :name="campo.clave"
              :aria-invalid="Boolean(errorDe(campo.clave))"
              @input="limpiarError(campo.clave)"
            />
            <p v-if="errorDe(campo.clave)" class="campo__error" role="alert">
              {{ errorDe(campo.clave) }}
            </p>
          </div>

          <div class="campo campo--completo">
            <label class="form-label" for="alimento-tipos-comida">Tipos de comida</label>
            <select
              id="alimento-tipos-comida"
              v-model="formulario.tiposComida"
              class="form-select"
              :class="{ 'is-invalid': errorDe('tiposComida') }"
              name="tiposComida"
              multiple
              size="5"
              :aria-invalid="Boolean(errorDe('tiposComida'))"
              @change="limpiarError('tiposComida')"
            >
              <option
                v-for="opcion in TIPOS_COMIDA_DISPONIBLES"
                :key="opcion.valor"
                :value="opcion.valor"
              >
                {{ opcion.etiqueta }}
              </option>
            </select>
            <p class="campo__ayuda">Usa Ctrl o Cmd para seleccionar más de una opción.</p>
            <p v-if="errorDe('tiposComida')" class="campo__error" role="alert">
              {{ errorDe('tiposComida') }}
            </p>
          </div>
        </div>
      </section>

      <section class="formulario__seccion gb-tarjeta" aria-labelledby="titulo-porcion">
        <header>
          <span aria-hidden="true"><Activity :size="20" /></span>
          <div>
            <h2 id="titulo-porcion">Porciones y validación</h2>
            <p>Define límites de uso, medidas y el estado de verificación nutricional.</p>
          </div>
        </header>

        <div class="formulario__rejilla formulario__rejilla--tres">
          <div v-for="campo in CAMPOS_PORCION" :key="campo.clave" class="campo">
            <label class="form-label" :for="`alimento-${campo.clave}`">
              {{ campo.etiqueta }} ({{ campo.sufijo }})
            </label>
            <input
              :id="`alimento-${campo.clave}`"
              v-model="formulario[campo.clave]"
              class="form-control"
              :class="{ 'is-invalid': errorDe(campo.clave) }"
              type="number"
              min="0"
              step="0.01"
              :name="campo.clave"
              :aria-invalid="Boolean(errorDe(campo.clave))"
              @input="limpiarError(campo.clave)"
            />
            <p v-if="errorDe(campo.clave)" class="campo__error" role="alert">
              {{ errorDe(campo.clave) }}
            </p>
          </div>

          <div class="campo">
            <label class="form-label" for="alimento-nutricion-verificada"
              >Nutrición verificada</label
            >
            <select
              id="alimento-nutricion-verificada"
              v-model="formulario.nutricionVerificada"
              class="form-select"
              name="nutricionVerificada"
              @change="limpiarError('nutricionVerificada')"
            >
              <option value="">No especificado</option>
              <option :value="true">Sí</option>
              <option :value="false">No</option>
            </select>
            <p v-if="errorDe('nutricionVerificada')" class="campo__error" role="alert">
              {{ errorDe('nutricionVerificada') }}
            </p>
          </div>

          <div class="campo">
            <label class="form-label" for="alimento-restricciones-verificadas">
              Restricciones verificadas
            </label>
            <select
              id="alimento-restricciones-verificadas"
              v-model="formulario.restriccionesVerificadas"
              class="form-select"
              name="restriccionesVerificadas"
              @change="limpiarError('restriccionesVerificadas')"
            >
              <option value="">No especificado</option>
              <option :value="true">Sí</option>
              <option :value="false">No</option>
            </select>
            <p v-if="errorDe('restriccionesVerificadas')" class="campo__error" role="alert">
              {{ errorDe('restriccionesVerificadas') }}
            </p>
          </div>
        </div>
      </section>
    </template>

    <div class="formulario__acciones">
      <button type="button" class="btn btn-secondary" :disabled="enviando" @click="emit('cancel')">
        Cancelar
      </button>
      <button type="submit" class="btn btn-primary" :disabled="enviando">
        <span v-if="enviando" class="spinner-border spinner-border-sm" aria-hidden="true"></span>
        {{ enviando ? 'Guardando…' : modo === 'edit' ? 'Guardar cambios' : 'Guardar alimento' }}
      </button>
    </div>
  </form>
</template>

<style scoped>
.formulario {
  display: grid;
  gap: var(--gb-gutter);
}

.formulario__seccion {
  padding: 1.25rem;
  border-radius: var(--gb-radius-xl);
}

.formulario__seccion > header {
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
  margin-bottom: 1.25rem;
}

.formulario__seccion > header > span {
  display: grid;
  place-items: center;
  width: 2.5rem;
  height: 2.5rem;
  background-color: var(--gb-surface-high);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
  color: var(--gb-red-text);
}

.formulario__seccion h2,
.formulario__seccion p {
  margin: 0;
}

.formulario__seccion h2 {
  font-size: var(--gb-tipo-md);
  text-transform: uppercase;
}

.formulario__seccion header p {
  max-width: 46rem;
  margin-top: 0.25rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}

.formulario__seccion header b {
  color: var(--gb-text);
}

.formulario__rejilla {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 1rem;
}

.formulario__rejilla--macros {
  grid-template-columns: repeat(3, minmax(0, 1fr));
}

.formulario__rejilla--tres {
  grid-template-columns: repeat(3, minmax(0, 1fr));
}

.campo {
  min-width: 0;
}

.campo--completo {
  grid-column: 1 / -1;
}

.campo__ayuda,
.campo__error {
  margin: 0.375rem 0 0;
  font-size: var(--gb-tipo-xxs);
}

.campo__ayuda {
  color: var(--gb-text-muted);
}

.campo__error {
  color: var(--gb-error);
}

.formulario__acciones {
  position: sticky;
  bottom: 0;
  z-index: 5;
  isolation: isolate;
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
  padding: 1rem 0;
  background-color: var(--gb-bg);
  border-top: 1px solid var(--gb-border);
}

/* El contenido principal conserva un margen inferior. Al quedar pegada la
   barra, este fondo sólido prolonga su superficie hasta el borde visible y
   evita que el formulario que pasa por debajo aparezca como una franja. */
.formulario__acciones::after {
  position: absolute;
  top: 100%;
  right: 0;
  left: 0;
  height: var(--gb-margen);
  background-color: var(--gb-bg);
  content: '';
  pointer-events: none;
}

.formulario__acciones .btn {
  min-height: 2.75rem;
  padding-inline: 1.25rem;
}

@media (max-width: 64rem) {
  .formulario__acciones::after {
    height: var(--gb-gutter);
  }
}

@media (max-width: 52rem) {
  .formulario__rejilla,
  .formulario__rejilla--macros,
  .formulario__rejilla--tres {
    grid-template-columns: 1fr;
  }
}
</style>
