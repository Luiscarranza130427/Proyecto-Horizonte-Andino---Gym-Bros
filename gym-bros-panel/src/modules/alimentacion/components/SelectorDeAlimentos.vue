<script setup>
import { CloudOff, List, Plus, RotateCw, XCircle } from 'lucide-vue-next'
import { computed, ref, useId, useTemplateRef } from 'vue'
import { RouterLink } from 'vue-router'

import { TIPOS_ALIMENTO, UNIDADES, etiquetaDe } from '@/modules/alimentacion/catalogos'

/**
 * Qué alimentos componen una comida y en qué cantidad.
 *
 * Componente CONTROLADO: nunca toca el array que recibe. Emite siempre uno
 * nuevo. Esto no es purismo: `useFormulario` copia `modeloVacio` con propagación
 * superficial, así que el array del formulario y el del modelo vacío son el
 * mismo objeto. Un `push` aquí dejaría contaminado el modelo vacío y la segunda
 * vez que se abriera el formulario aparecerían los alimentos de la primera.
 */

const props = defineProps({
  modelValue: { type: Array, default: () => [] },
  /** Catálogo completo y sin paginar, tal como lo entrega el servicio. */
  catalogo: { type: Array, default: () => [] },
  cargandoCatalogo: { type: Boolean, default: false },
  errorCatalogo: { type: String, default: '' },
  invalido: { type: Boolean, default: false },
  /** Id del mensaje de error que pinta el formulario, para el `aria-describedby`. */
  describedBy: { type: String, default: '' },
})

const emit = defineEmits(['update:modelValue', 'recargar-catalogo'])

/**
 * Cantidad de partida al añadir un alimento. Es un valor inicial editable, no
 * una regla: 100 en las medidas continuas y 1 cuando se cuenta por piezas.
 */
const CANTIDAD_INICIAL = { gramos: 100, mililitros: 100, unidad: 1 }

const identificador = useId()
const alimentoElegido = ref('')
const selectAlimento = useTemplateRef('selectAlimento')

/** Agrupado por tipo: un desplegable plano de treinta alimentos no se recorre. */
const porTipo = computed(() =>
  TIPOS_ALIMENTO.map(({ valor, etiqueta }) => ({
    valor,
    etiqueta,
    alimentos: props.catalogo.filter((alimento) => alimento.tipo === valor),
  })).filter((grupo) => grupo.alimentos.length),
)

/**
 * El alimento de una porción. El guion final cubre el caso real de que el
 * catálogo no haya podido cargarse: la línea sigue siendo editable y no miente
 * sobre lo que hay dentro.
 */
function alimentoDe(id) {
  return props.catalogo.find((alimento) => alimento.id === Number(id)) ?? null
}

function nombreDe(id) {
  return alimentoDe(id)?.nombre ?? `Alimento #${id}`
}

function tipoDe(id) {
  const alimento = alimentoDe(id)
  return alimento ? etiquetaDe(TIPOS_ALIMENTO, alimento.tipo) : 'Fuera del catálogo cargado'
}

function anadir() {
  const alimento = alimentoDe(alimentoElegido.value)
  if (!alimento) return

  emit('update:modelValue', [
    ...props.modelValue,
    {
      alimentoId: alimento.id,
      cantidad: CANTIDAD_INICIAL[alimento.unidadBase] ?? 100,
      unidad: alimento.unidadBase,
    },
  ])
  alimentoElegido.value = ''
}

function cambiar(indice, campo, valor) {
  emit(
    'update:modelValue',
    props.modelValue.map((porcion, i) => (i === indice ? { ...porcion, [campo]: valor } : porcion)),
  )
}

function quitar(indice) {
  emit(
    'update:modelValue',
    props.modelValue.filter((_, i) => i !== indice),
  )
}

/** `useFormulario` lleva el foco aquí cuando la lista es el primer campo con error. */
defineExpose({ focus: () => selectAlimento.value?.focus() })
</script>

<template>
  <div class="selector" :class="{ 'selector--invalido': invalido }">
    <div v-if="cargandoCatalogo" class="selector__aviso" aria-busy="true">
      <span class="spinner-border spinner-border-sm" aria-hidden="true"></span>
      <p>Cargando el catálogo de alimentos…</p>
    </div>

    <div v-else-if="errorCatalogo" class="selector__aviso selector__aviso--error" role="alert">
      <CloudOff :size="24" aria-hidden="true" />
      <p>{{ errorCatalogo }}</p>
      <button type="button" class="btn btn-ghost" @click="emit('recargar-catalogo')">
        <RotateCw :size="16" aria-hidden="true" />
        Reintentar
      </button>
    </div>

    <div v-else-if="!catalogo.length" class="selector__aviso" role="status">
      <List :size="24" aria-hidden="true" />
      <p>No hay alimentos disponibles en el catálogo.</p>
      <RouterLink class="btn btn-ghost" :to="{ name: 'alimentos-listado' }">
        Ir al catálogo
      </RouterLink>
    </div>

    <div v-else class="selector__anadir">
      <div class="campo">
        <label class="form-label" :for="`${identificador}-alimento`">Añadir alimento</label>
        <select
          :id="`${identificador}-alimento`"
          ref="selectAlimento"
          v-model="alimentoElegido"
          class="form-select"
          :aria-invalid="invalido || undefined"
          :aria-describedby="describedBy || undefined"
        >
          <option value="">Selecciona un alimento</option>
          <optgroup v-for="grupo in porTipo" :key="grupo.valor" :label="grupo.etiqueta">
            <option v-for="alimento in grupo.alimentos" :key="alimento.id" :value="alimento.id">
              {{ alimento.nombre }}
            </option>
          </optgroup>
        </select>
      </div>
      <button type="button" class="btn btn-ghost" :disabled="!alimentoElegido" @click="anadir">
        <Plus :size="16" aria-hidden="true" />
        Añadir
      </button>
    </div>

    <ul v-if="modelValue.length" class="selector__lista">
      <li v-for="(porcion, indice) in modelValue" :key="`${indice}-${porcion.alimentoId}`">
        <div class="linea__alimento">
          <strong>{{ nombreDe(porcion.alimentoId) }}</strong>
          <small>{{ tipoDe(porcion.alimentoId) }}</small>
        </div>

        <div class="linea__campo">
          <label class="form-label" :for="`${identificador}-cantidad-${indice}`">Cantidad</label>
          <input
            :id="`${identificador}-cantidad-${indice}`"
            class="form-control"
            type="number"
            min="0"
            step="any"
            inputmode="decimal"
            :value="porcion.cantidad"
            @input="cambiar(indice, 'cantidad', $event.target.value)"
          />
        </div>

        <div class="linea__campo">
          <label class="form-label" :for="`${identificador}-unidad-${indice}`">Unidad</label>
          <select
            :id="`${identificador}-unidad-${indice}`"
            class="form-select"
            :value="porcion.unidad"
            @change="cambiar(indice, 'unidad', $event.target.value)"
          >
            <option v-for="opcion in UNIDADES" :key="opcion.valor" :value="opcion.valor">
              {{ opcion.nombre }}
            </option>
          </select>
        </div>

        <button
          type="button"
          class="gb-boton-icono linea__quitar"
          :aria-label="`Quitar ${nombreDe(porcion.alimentoId)} de la comida`"
          title="Quitar"
          @click="quitar(indice)"
        >
          <XCircle :size="16" aria-hidden="true" />
        </button>
      </li>
    </ul>

    <p v-else class="selector__vacio">
      Una comida necesita al menos un alimento. Elige uno arriba para empezar.
    </p>
  </div>
</template>

<style scoped>
.selector {
  display: grid;
  gap: 1rem;
  padding: 1rem;
  background-color: var(--gb-surface-lowest);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
}

.selector--invalido {
  border-color: var(--gb-error);
}

.selector__aviso {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}

.selector__aviso > svg {
  flex: none;
  color: var(--gb-text-soft);
  font-size: 1.25rem;
}

.selector__aviso p {
  flex: 1 1 auto;
  margin: 0;
}

.selector__aviso .btn {
  flex: none;
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  min-height: 2.25rem;
  padding-inline: 0.875rem;
  font-size: var(--gb-tipo-xxs);
  text-decoration: none;
}

.selector__aviso--error {
  color: var(--gb-error);
}

.selector__aviso--error > svg {
  color: var(--gb-error);
}

.selector__anadir {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: end;
  gap: 0.75rem;
}

.selector__anadir .btn {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  min-height: 3rem;
  padding-inline: 1rem;
  font-size: var(--gb-tipo-xxs);
}

.selector__lista {
  display: grid;
  gap: 0.625rem;
  margin: 0;
  padding: 0;
  list-style: none;
}

.selector__lista > li {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 7.5rem 9rem auto;
  align-items: end;
  gap: 0.75rem;
  padding: 0.75rem;
  background-color: var(--gb-surface);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius);
}

.linea__alimento {
  display: grid;
  min-width: 0;
  padding-bottom: 0.625rem;
}

.linea__alimento strong {
  overflow: hidden;
  color: var(--gb-text);
  font-size: var(--gb-tipo-sm);
  text-overflow: ellipsis;
  white-space: nowrap;
}

.linea__alimento small {
  margin-top: 0.125rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.linea__campo {
  min-width: 0;
}

.linea__campo .form-control,
.linea__campo .form-select {
  min-height: 2.5rem;
  padding: 0.5rem 0.625rem;
  background-color: var(--gb-surface-lowest);
  font-size: var(--gb-tipo-sm);
}

.linea__quitar {
  width: 2.5rem;
  height: 2.5rem;
  color: var(--gb-text-muted);
}

.linea__quitar:hover {
  color: var(--gb-error);
}

.selector__vacio {
  margin: 0;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}

@media (max-width: 60rem) {
  .selector__lista > li {
    grid-template-columns: minmax(0, 1fr) minmax(0, 1fr) auto;
  }

  .linea__alimento {
    grid-column: 1 / -1;
    padding-bottom: 0;
  }
}

@media (max-width: 36rem) {
  .selector__anadir {
    grid-template-columns: 1fr;
  }

  .selector__anadir .btn {
    justify-content: center;
  }
}
</style>
