<script setup>
import { Clock, Utensils } from 'lucide-vue-next'
import { useTemplateRef } from 'vue'

import { useFormulario } from '@/shared/composables/useFormulario'
import { TIPOS_COMIDA, UNIDADES, valoresDe } from '@/modules/alimentacion/catalogos'
import SelectorDeAlimentos from '@/modules/alimentacion/components/SelectorDeAlimentos.vue'

const props = defineProps({
  /** Comida tal como la entrega el servicio, o `{}` al crear una nueva. */
  valoresIniciales: { type: Object, default: () => ({}) },
  enviando: { type: Boolean, default: false },
  erroresServidor: { type: Object, default: () => ({}) },
  modo: { type: String, default: 'create' },
  catalogo: { type: Array, default: () => [] },
  cargandoCatalogo: { type: Boolean, default: false },
  errorCatalogo: { type: String, default: '' },
})

const emit = defineEmits(['submit', 'cancel', 'recargar-catalogo'])

const MODELO_VACIO = {
  tipoComida: '',
  horaSugerida: '',
  alimentos: [],
}

/** Hora del día válida en formato 'HH:MM', que es lo que guarda el esquema. */
const HORA = /^([01]\d|2[0-3]):[0-5]\d$/

const tipoComidaInput = useTemplateRef('tipoComidaInput')
const horaInput = useTemplateRef('horaInput')
const selectorAlimentos = useTemplateRef('selectorAlimentos')

function esCantidadValida(valor) {
  const texto = String(valor).trim()
  if (!texto) return false
  const numero = Number(texto)
  return Number.isFinite(numero) && numero > 0
}

function validar(datos, errores) {
  if (!valoresDe(TIPOS_COMIDA).includes(datos.tipoComida)) {
    errores.tipoComida = 'Selecciona un tipo de comida válido.'
  }

  if (!HORA.test(String(datos.horaSugerida ?? ''))) {
    errores.horaSugerida = 'Indica la hora en formato HH:MM.'
  }

  if (datos.alimentos.length === 0) {
    errores.alimentos = 'Añade al menos un alimento a la comida.'
  } else if (datos.alimentos.some((porcion) => !esCantidadValida(porcion.cantidad))) {
    errores.alimentos = 'Cada alimento necesita una cantidad mayor que cero.'
  } else if (datos.alimentos.some((porcion) => !valoresDe(UNIDADES).includes(porcion.unidad))) {
    errores.alimentos = 'Alguna de las unidades elegidas no es válida.'
  }
}

/**
 * `useFormulario` copia `modeloVacio` con propagación SUPERFICIAL: sin este
 * paso, `formulario.alimentos` y `MODELO_VACIO.alimentos` serían el mismo array.
 * Aquí se reasigna SIEMPRE uno nuevo —también al crear, donde `valores` viene
 * vacío—, y las porciones del servicio se traducen a lo que espera el payload.
 */
function alCargarValores(formulario, valores) {
  formulario.alimentos = (valores.alimentos ?? []).map((porcion) => ({
    alimentoId: porcion.alimento.id,
    cantidad: porcion.cantidad,
    unidad: porcion.unidad,
  }))
}

const { formulario, erroresLocales, erroresRemotos, errorDe, limpiarError, validarParaEnviar } =
  useFormulario({
    modeloVacio: MODELO_VACIO,
    valoresIniciales: () => props.valoresIniciales,
    erroresServidor: () => props.erroresServidor,
    referencias: {
      tipoComida: tipoComidaInput,
      horaSugerida: horaInput,
      alimentos: selectorAlimentos,
    },
    validar,
    alCargarValores,
  })

/** El selector es controlado: llega un array nuevo, nunca el mismo mutado. */
function cambiarAlimentos(alimentos) {
  formulario.alimentos = alimentos
  limpiarError('alimentos')
}

async function enviar() {
  if (props.enviando) return
  if (!(await validarParaEnviar())) return

  emit('submit', {
    tipoComida: formulario.tipoComida,
    horaSugerida: formulario.horaSugerida,
    alimentos: formulario.alimentos.map((porcion) => ({
      alimentoId: Number(porcion.alimentoId),
      cantidad: Number(porcion.cantidad),
      unidad: porcion.unidad,
    })),
  })
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

    <section class="formulario__seccion gb-tarjeta" aria-labelledby="titulo-momento">
      <header>
        <span aria-hidden="true"><Clock :size="20" /></span>
        <div>
          <h2 id="titulo-momento">Momento del día</h2>
          <p>Qué comida es y a qué hora toca. De aquí sale el orden del horario.</p>
        </div>
      </header>

      <div class="formulario__rejilla">
        <div class="campo">
          <label class="form-label" for="comida-tipo">Tipo de comida *</label>
          <select
            id="comida-tipo"
            ref="tipoComidaInput"
            v-model="formulario.tipoComida"
            class="form-select"
            :class="{ 'is-invalid': errorDe('tipoComida') }"
            name="tipoComida"
            required
            :aria-invalid="Boolean(errorDe('tipoComida'))"
            :aria-describedby="errorDe('tipoComida') ? 'error-tipo-comida' : null"
            @change="limpiarError('tipoComida')"
          >
            <option value="">Selecciona un tipo</option>
            <option v-for="opcion in TIPOS_COMIDA" :key="opcion.valor" :value="opcion.valor">
              {{ opcion.etiqueta }}
            </option>
          </select>
          <p v-if="errorDe('tipoComida')" id="error-tipo-comida" class="campo__error" role="alert">
            {{ errorDe('tipoComida') }}
          </p>
        </div>

        <div class="campo">
          <label class="form-label" for="comida-hora">Hora sugerida *</label>
          <input
            id="comida-hora"
            ref="horaInput"
            v-model="formulario.horaSugerida"
            class="form-control"
            :class="{ 'is-invalid': errorDe('horaSugerida') }"
            type="time"
            name="horaSugerida"
            required
            :aria-invalid="Boolean(errorDe('horaSugerida'))"
            :aria-describedby="errorDe('horaSugerida') ? 'error-hora' : 'ayuda-hora'"
            @input="limpiarError('horaSugerida')"
          />
          <p id="ayuda-hora" class="campo__ayuda">
            Es una sugerencia para el usuario, no una alarma.
          </p>
          <p v-if="errorDe('horaSugerida')" id="error-hora" class="campo__error" role="alert">
            {{ errorDe('horaSugerida') }}
          </p>
        </div>
      </div>
    </section>

    <section class="formulario__seccion gb-tarjeta" aria-labelledby="titulo-alimentos">
      <header>
        <span aria-hidden="true"><Utensils :size="20" /></span>
        <div>
          <h2 id="titulo-alimentos">Alimentos de la comida</h2>
          <p>Los macros de la comida los calcula el backend a partir de estas cantidades.</p>
        </div>
      </header>

      <SelectorDeAlimentos
        ref="selectorAlimentos"
        :model-value="formulario.alimentos"
        :catalogo="catalogo"
        :cargando-catalogo="cargandoCatalogo"
        :error-catalogo="errorCatalogo"
        :invalido="Boolean(errorDe('alimentos'))"
        :described-by="errorDe('alimentos') ? 'error-alimentos' : ''"
        @update:model-value="cambiarAlimentos"
        @recargar-catalogo="emit('recargar-catalogo')"
      />

      <p v-if="errorDe('alimentos')" id="error-alimentos" class="campo__error" role="alert">
        {{ errorDe('alimentos') }}
      </p>
    </section>

    <div class="formulario__acciones">
      <button type="button" class="btn btn-secondary" :disabled="enviando" @click="emit('cancel')">
        Cancelar
      </button>
      <button type="submit" class="btn btn-primary" :disabled="enviando">
        <span v-if="enviando" class="spinner-border spinner-border-sm" aria-hidden="true"></span>
        {{ enviando ? 'Guardando…' : modo === 'edit' ? 'Guardar cambios' : 'Añadir comida' }}
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
  margin-top: 0.25rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}

.formulario__rejilla {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 1rem;
}

.campo {
  min-width: 0;
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
   barra, este fondo sólido prolonga su superficie hasta el borde visible. */
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
  .formulario__rejilla {
    grid-template-columns: 1fr;
  }
}
</style>
