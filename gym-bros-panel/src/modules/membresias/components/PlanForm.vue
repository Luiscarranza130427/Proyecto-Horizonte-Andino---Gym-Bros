<script setup>
import { CheckCircle2, ClipboardCheck, Plus, X, XCircle } from 'lucide-vue-next'
import { computed, nextTick, onBeforeUnmount, ref, useTemplateRef } from 'vue'

import { useFormulario } from '@/shared/composables/useFormulario'
import { SERVICIOS_PLAN, serviciosDesdeContenido } from '@/modules/membresias/catalogos'
import { esUrlValida } from '@/shared/utils/validaciones'

const props = defineProps({
  modo: {
    type: String,
    default: 'create',
    validator: (valor) => ['create', 'edit'].includes(valor),
  },
  valoresIniciales: { type: Object, default: () => ({}) },
  enviando: { type: Boolean, default: false },
  erroresServidor: { type: Object, default: () => ({}) },
})

const emit = defineEmits(['submit', 'cancel'])

const nombreInput = useTemplateRef('nombreInput')
const descripcionInput = useTemplateRef('descripcionInput')
const precioOriginalInput = useTemplateRef('precioOriginalInput')
const precioInicialInput = useTemplateRef('precioInicialInput')
const duracionInput = useTemplateRef('duracionInput')
const limiteInput = useTemplateRef('limiteInput')
const serviciosInput = useTemplateRef('serviciosInput')
const enlaceInput = useTemplateRef('enlaceInput')
const inputModalServicio = useTemplateRef('inputModalServicio')

const modalAgregarAbierto = ref(false)
const nombreServicioNuevo = ref('')
const errorServicioNuevo = ref('')
const serviciosPersonalizados = ref([])

const MODELO_VACIO = {
  nombre: '',
  descripcion: '',
  precioOriginal: '',
  precioInicial: '',
  duracionDias: '',
  limiteUsuarios: '',
  activo: false,
  servicios: [],
  enlaceWhatsapp: '',
}

function esPrecioValido(valor) {
  const numero = Number(valor)
  return valor !== '' && Number.isFinite(numero) && numero >= 0
}

function esEnteroPositivo(valor) {
  const numero = Number(valor)
  return Number.isInteger(numero) && numero > 0
}

function validar(datos, errores) {
  const nombre = datos.nombre.trim()
  if (nombre.length < 3) errores.nombre = 'Introduce un nombre de al menos 3 caracteres.'
  else if (nombre.length > 100) errores.nombre = 'El nombre no puede superar 100 caracteres.'

  if (!datos.descripcion.trim()) errores.descripcion = 'Describe brevemente el plan.'
  if (!esPrecioValido(datos.precioOriginal)) {
    errores.precioOriginal = 'Introduce un precio igual o mayor que cero.'
  }
  if (!esPrecioValido(datos.precioInicial)) {
    errores.precioInicial = 'Introduce un precio igual o mayor que cero.'
  }
  if (!esEnteroPositivo(datos.duracionDias)) {
    errores.duracionDias = 'Introduce una duración entera mayor que cero.'
  }
  if (!esEnteroPositivo(datos.limiteUsuarios)) {
    errores.limiteUsuarios = 'Introduce un límite entero mayor que cero.'
  }
  if (!datos.servicios.length) errores.servicios = 'Selecciona al menos un servicio.'
  if (!esUrlValida(datos.enlaceWhatsapp.trim())) {
    errores.enlaceWhatsapp = 'Introduce un enlace http o https válido.'
  }
}

const { formulario, errorDe, limpiarError, validarParaEnviar } = useFormulario({
  modeloVacio: MODELO_VACIO,
  valoresIniciales: () => props.valoresIniciales,
  erroresServidor: () => props.erroresServidor,
  referencias: {
    nombre: nombreInput,
    descripcion: descripcionInput,
    precioOriginal: precioOriginalInput,
    precioInicial: precioInicialInput,
    duracionDias: duracionInput,
    limiteUsuarios: limiteInput,
    servicios: serviciosInput,
    enlaceWhatsapp: enlaceInput,
  },
  validar,
  alCargarValores(formulario, valores) {
    const cargados = serviciosDesdeContenido(valores.contenido)
    formulario.servicios = cargados
    cargados.forEach((servicio) => {
      if (!SERVICIOS_PLAN.includes(servicio) && !serviciosPersonalizados.value.includes(servicio)) {
        serviciosPersonalizados.value.push(servicio)
      }
    })
  },
})

const todasLasOpciones = computed(() => {
  const opciones = [...SERVICIOS_PLAN]
  for (const servicio of serviciosPersonalizados.value) {
    if (!opciones.includes(servicio)) opciones.push(servicio)
  }
  for (const servicio of formulario.servicios) {
    if (!opciones.includes(servicio)) opciones.push(servicio)
  }
  return opciones
})

function abrirModalAgregar() {
  nombreServicioNuevo.value = ''
  errorServicioNuevo.value = ''
  modalAgregarAbierto.value = true
  window.addEventListener('keydown', manejarTeclaModal)
  nextTick(() => {
    inputModalServicio.value?.focus()
  })
}

function cerrarModalAgregar() {
  modalAgregarAbierto.value = false
  nombreServicioNuevo.value = ''
  errorServicioNuevo.value = ''
  window.removeEventListener('keydown', manejarTeclaModal)
}

function manejarTeclaModal(evento) {
  if (modalAgregarAbierto.value && evento.key === 'Escape') {
    cerrarModalAgregar()
  }
}

onBeforeUnmount(() => {
  window.removeEventListener('keydown', manejarTeclaModal)
})

function guardarServicioDesdeModal() {
  const texto = nombreServicioNuevo.value.trim()
  if (!texto) {
    errorServicioNuevo.value = 'Introduce el nombre del servicio.'
    return
  }
  if (texto.length < 2) {
    errorServicioNuevo.value = 'El nombre debe tener al menos 2 caracteres.'
    return
  }
  if (todasLasOpciones.value.some((s) => s.toLowerCase() === texto.toLowerCase())) {
    errorServicioNuevo.value = 'Este servicio ya existe en la lista.'
    return
  }

  serviciosPersonalizados.value.push(texto)
  if (!formulario.servicios.includes(texto)) {
    formulario.servicios.push(texto)
  }
  cerrarModalAgregar()
  limpiarError('servicios')
}

function eliminarServicioPersonalizado(servicio) {
  serviciosPersonalizados.value = serviciosPersonalizados.value.filter((s) => s !== servicio)
  formulario.servicios = formulario.servicios.filter((s) => s !== servicio)
  limpiarError('servicios')
}

function seleccionarTodos() {
  formulario.servicios = [...todasLasOpciones.value]
  limpiarError('servicios')
}

function desmarcarTodos() {
  formulario.servicios = []
  limpiarError('servicios')
}

async function enviar() {
  if (props.enviando) return
  if (!(await validarParaEnviar())) return

  emit('submit', {
    nombre: formulario.nombre.trim(),
    descripcion: formulario.descripcion.trim(),
    precioOriginal: Number(formulario.precioOriginal),
    precioInicial: Number(formulario.precioInicial),
    duracionDias: Number(formulario.duracionDias),
    limiteUsuarios: Number(formulario.limiteUsuarios),
    activo: formulario.activo,
    contenido: formulario.servicios.join('\n'),
    enlaceWhatsapp: formulario.enlaceWhatsapp.trim(),
  })
}
</script>

<template>
  <form class="plan-form" novalidate @submit.prevent="enviar">
    <section class="plan-form__seccion gb-tarjeta" aria-labelledby="titulo-plan">
      <header class="plan-form__cabecera">
        <span aria-hidden="true"><ClipboardCheck :size="20" /></span>
        <div>
          <h2 id="titulo-plan">Información del plan</h2>
          <p>Define la oferta comercial y la capacidad que tendrá cada empresa.</p>
        </div>
      </header>

      <div class="plan-form__campos">
        <div class="campo campo--completo">
          <label class="form-label" for="plan-nombre">Nombre *</label>
          <input
            id="plan-nombre"
            ref="nombreInput"
            v-model="formulario.nombre"
            class="form-control"
            :class="{ 'is-invalid': errorDe('nombre') }"
            name="nombre"
            maxlength="100"
            autocomplete="off"
            :aria-invalid="Boolean(errorDe('nombre'))"
            :aria-describedby="errorDe('nombre') ? 'error-nombre' : null"
            @input="limpiarError('nombre')"
          />
          <p v-if="errorDe('nombre')" id="error-nombre" class="campo__error" role="alert">
            {{ errorDe('nombre') }}
          </p>
        </div>

        <div class="campo campo--completo">
          <label class="form-label" for="plan-descripcion">Descripción *</label>
          <textarea
            id="plan-descripcion"
            ref="descripcionInput"
            v-model="formulario.descripcion"
            class="form-control"
            :class="{ 'is-invalid': errorDe('descripcion') }"
            name="descripcion"
            rows="3"
            :aria-invalid="Boolean(errorDe('descripcion'))"
            :aria-describedby="errorDe('descripcion') ? 'error-descripcion' : null"
            @input="limpiarError('descripcion')"
          ></textarea>
          <p v-if="errorDe('descripcion')" id="error-descripcion" class="campo__error" role="alert">
            {{ errorDe('descripcion') }}
          </p>
        </div>

        <div class="campo">
          <label class="form-label" for="plan-precio-original">Precio original (S/) *</label>
          <input
            id="plan-precio-original"
            ref="precioOriginalInput"
            v-model="formulario.precioOriginal"
            class="form-control"
            :class="{ 'is-invalid': errorDe('precioOriginal') }"
            name="precioOriginal"
            type="number"
            min="0"
            step="0.01"
            inputmode="decimal"
            :aria-invalid="Boolean(errorDe('precioOriginal'))"
            :aria-describedby="errorDe('precioOriginal') ? 'error-precio-original' : null"
            @input="limpiarError('precioOriginal')"
          />
          <p
            v-if="errorDe('precioOriginal')"
            id="error-precio-original"
            class="campo__error"
            role="alert"
          >
            {{ errorDe('precioOriginal') }}
          </p>
        </div>

        <div class="campo">
          <label class="form-label" for="plan-precio-inicial">Precio inicial (S/) *</label>
          <input
            id="plan-precio-inicial"
            ref="precioInicialInput"
            v-model="formulario.precioInicial"
            class="form-control"
            :class="{ 'is-invalid': errorDe('precioInicial') }"
            name="precioInicial"
            type="number"
            min="0"
            step="0.01"
            inputmode="decimal"
            :aria-invalid="Boolean(errorDe('precioInicial'))"
            :aria-describedby="errorDe('precioInicial') ? 'error-precio-inicial' : null"
            @input="limpiarError('precioInicial')"
          />
          <p
            v-if="errorDe('precioInicial')"
            id="error-precio-inicial"
            class="campo__error"
            role="alert"
          >
            {{ errorDe('precioInicial') }}
          </p>
        </div>

        <div class="campo">
          <label class="form-label" for="plan-duracion">Duración en días *</label>
          <input
            id="plan-duracion"
            ref="duracionInput"
            v-model="formulario.duracionDias"
            class="form-control"
            :class="{ 'is-invalid': errorDe('duracionDias') }"
            name="duracionDias"
            type="number"
            min="1"
            step="1"
            inputmode="numeric"
            :aria-invalid="Boolean(errorDe('duracionDias'))"
            :aria-describedby="errorDe('duracionDias') ? 'error-duracion' : 'ayuda-duracion'"
            @input="limpiarError('duracionDias')"
          />
          <p id="ayuda-duracion" class="campo__ayuda">
            La duración se registra en días, no en meses.
          </p>
          <p v-if="errorDe('duracionDias')" id="error-duracion" class="campo__error" role="alert">
            {{ errorDe('duracionDias') }}
          </p>
        </div>

        <div class="campo">
          <label class="form-label" for="plan-limite">Límite de usuarios *</label>
          <input
            id="plan-limite"
            ref="limiteInput"
            v-model="formulario.limiteUsuarios"
            class="form-control"
            :class="{ 'is-invalid': errorDe('limiteUsuarios') }"
            name="limiteUsuarios"
            type="number"
            min="1"
            step="1"
            inputmode="numeric"
            :aria-invalid="Boolean(errorDe('limiteUsuarios'))"
            :aria-describedby="errorDe('limiteUsuarios') ? 'error-limite' : null"
            @input="limpiarError('limiteUsuarios')"
          />
          <p v-if="errorDe('limiteUsuarios')" id="error-limite" class="campo__error" role="alert">
            {{ errorDe('limiteUsuarios') }}
          </p>
        </div>

        <fieldset
          id="plan-servicios"
          ref="serviciosInput"
          class="campo campo--completo plan-form__servicios"
          :class="{ 'plan-form__servicios--invalido': errorDe('servicios') }"
          tabindex="-1"
          :aria-invalid="Boolean(errorDe('servicios'))"
          :aria-describedby="errorDe('servicios') ? 'error-servicios' : 'ayuda-servicios'"
        >
          <div class="plan-form__servicios-header">
            <div class="plan-form__servicios-titulo-wrap">
              <legend class="form-label mb-0">Servicios incluidos *</legend>
              <span class="plan-form__contador-tag">
                {{ formulario.servicios.length }} / {{ todasLasOpciones.length }} seleccionados
              </span>
            </div>

            <div class="plan-form__servicios-toolbar">
              <button type="button" class="btn-accion-servicio" @click="seleccionarTodos">
                Seleccionar todos
              </button>
              <span class="separador-punto" aria-hidden="true">•</span>
              <button
                type="button"
                class="btn-accion-servicio"
                :disabled="formulario.servicios.length === 0"
                @click="desmarcarTodos"
              >
                Limpiar
              </button>
              <button
                type="button"
                class="btn btn-primary plan-form__btn-abrir-modal"
                @click="abrirModalAgregar"
              >
                <Plus :size="16" />
                <span>Agregar servicio</span>
              </button>
            </div>
          </div>

          <div
            class="plan-form__servicios-grid"
            role="group"
            aria-label="Servicios incluidos en el plan"
          >
            <label
              v-for="servicio in todasLasOpciones"
              :key="servicio"
              class="plan-form__servicio-card"
              :class="{
                'plan-form__servicio-card--activo': formulario.servicios.includes(servicio),
                'plan-form__servicio-card--custom': serviciosPersonalizados.includes(servicio),
              }"
            >
              <input
                v-model="formulario.servicios"
                type="checkbox"
                class="visually-hidden"
                name="servicios"
                :value="servicio"
                @change="limpiarError('servicios')"
              />

              <span class="plan-form__servicio-check" aria-hidden="true">
                <CheckCircle2 v-if="formulario.servicios.includes(servicio)" :size="16" />
              </span>

              <span class="plan-form__servicio-nombre">{{ servicio }}</span>

              <button
                v-if="serviciosPersonalizados.includes(servicio)"
                type="button"
                class="plan-form__servicio-btn-borrar"
                :title="`Eliminar servicio ${servicio}`"
                :aria-label="`Eliminar servicio ${servicio}`"
                @click.stop.prevent="eliminarServicioPersonalizado(servicio)"
              >
                <XCircle :size="14" />
              </button>
            </label>
          </div>

          <p id="ayuda-servicios" class="campo__ayuda">
            Selecciona los servicios incluidos en el plan o pulsa "+ Agregar servicio" para crear
            uno nuevo.
          </p>
          <p v-if="errorDe('servicios')" id="error-servicios" class="campo__error" role="alert">
            {{ errorDe('servicios') }}
          </p>
        </fieldset>

        <div class="campo campo--completo">
          <label class="form-label" for="plan-whatsapp">Enlace de WhatsApp *</label>
          <input
            id="plan-whatsapp"
            ref="enlaceInput"
            v-model="formulario.enlaceWhatsapp"
            class="form-control"
            :class="{ 'is-invalid': errorDe('enlaceWhatsapp') }"
            name="enlaceWhatsapp"
            type="url"
            placeholder="https://wa.me/51900000000"
            autocomplete="url"
            :aria-invalid="Boolean(errorDe('enlaceWhatsapp'))"
            :aria-describedby="errorDe('enlaceWhatsapp') ? 'error-whatsapp' : null"
            @input="limpiarError('enlaceWhatsapp')"
          />
          <p v-if="errorDe('enlaceWhatsapp')" id="error-whatsapp" class="campo__error" role="alert">
            {{ errorDe('enlaceWhatsapp') }}
          </p>
        </div>

        <label class="plan-form__estado campo--completo">
          <input v-model="formulario.activo" type="checkbox" name="activo" />
          <span>
            <strong>Plan activo</strong>
            <small>Indica si la oferta está disponible para las empresas.</small>
          </span>
        </label>
      </div>

      <footer class="plan-form__acciones">
        <button type="button" class="btn btn-secondary" @click="emit('cancel')">Cancelar</button>
        <button type="submit" class="btn btn-primary" :disabled="enviando">
          {{ enviando ? 'Guardando…' : 'Guardar cambios' }}
        </button>
      </footer>
    </section>

    <!-- Modal Popup para Registrar Servicio Personalizado -->
    <Teleport to="body">
      <div
        v-if="modalAgregarAbierto"
        class="modal-servicio-fondo"
        @mousedown.self="cerrarModalAgregar"
      >
        <div
          class="modal-servicio gb-tarjeta"
          role="dialog"
          aria-modal="true"
          aria-labelledby="titulo-modal-servicio"
        >
          <header class="modal-servicio__cabecera">
            <span class="modal-servicio__icono" aria-hidden="true">
              <Plus :size="20" />
            </span>
            <div class="modal-servicio__titulos">
              <h3 id="titulo-modal-servicio">Agregar nuevo servicio</h3>
              <p>Define un beneficio o servicio adicional para este plan comercial.</p>
            </div>
            <button
              type="button"
              class="modal-servicio__btn-cerrar gb-boton-icono"
              aria-label="Cerrar ventana"
              @click="cerrarModalAgregar"
            >
              <X :size="18" />
            </button>
          </header>

          <form class="modal-servicio__cuerpo" @submit.prevent="guardarServicioDesdeModal">
            <div class="campo">
              <label class="form-label" for="nombre-servicio-modal">Nombre del servicio *</label>
              <input
                id="nombre-servicio-modal"
                ref="inputModalServicio"
                v-model="nombreServicioNuevo"
                type="text"
                class="form-control"
                :class="{ 'is-invalid': errorServicioNuevo }"
                placeholder="Ej. Acceso 24/7, Evaluación nutricional..."
                maxlength="80"
                autocomplete="off"
                @input="errorServicioNuevo = ''"
              />
              <p v-if="errorServicioNuevo" class="campo__error" role="alert">
                {{ errorServicioNuevo }}
              </p>
            </div>

            <footer class="modal-servicio__acciones">
              <button type="button" class="btn btn-ghost" @click="cerrarModalAgregar">
                Cancelar
              </button>
              <button type="submit" class="btn btn-primary">
                <Plus :size="16" />
                <span>Agregar servicio</span>
              </button>
            </footer>
          </form>
        </div>
      </div>
    </Teleport>
  </form>
</template>

<style scoped>
.plan-form,
.plan-form__seccion {
  display: grid;
  gap: 1.5rem;
}

.plan-form__seccion {
  padding: 1.5rem;
  border-radius: var(--gb-radius-xl);
}

.plan-form__cabecera {
  display: flex;
  align-items: center;
  gap: 0.875rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid var(--gb-border);
}

.plan-form__cabecera > span {
  display: grid;
  place-items: center;
  width: 2.75rem;
  height: 2.75rem;
  background-color: var(--gb-surface-high);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
  color: var(--gb-red-text);
  font-size: 1.125rem;
}

.plan-form__cabecera h2,
.plan-form__cabecera p,
.campo p {
  margin: 0;
}

.plan-form__cabecera h2 {
  font-size: var(--gb-tipo-md);
  text-transform: uppercase;
}

.plan-form__cabecera p {
  margin-top: 0.25rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}

.plan-form__campos {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 1.125rem;
}

.campo {
  min-width: 0;
}

.campo--completo {
  grid-column: 1 / -1;
}

.campo textarea {
  min-height: auto;
  resize: vertical;
}

/* Servicios incluidos - Sección estructurada */
.plan-form__servicios {
  min-width: 0;
  margin: 0;
  padding: 0;
  border: 0;
  outline: none;
}

.plan-form__servicios-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  margin-bottom: 0.875rem;
  flex-wrap: wrap;
}

.plan-form__servicios-titulo-wrap {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex-wrap: nowrap;
}

.plan-form__contador-tag {
  display: inline-flex;
  align-items: center;
  padding: 0.25rem 0.625rem;
  background-color: var(--gb-surface-high);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-pill);
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
  font-weight: 600;
  white-space: nowrap;
  letter-spacing: 0.02em;
}

.plan-form__servicios-toolbar {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex-wrap: wrap;
}

.btn-accion-servicio {
  padding: 0;
  background: transparent;
  border: none;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
  font-weight: 600;
  cursor: pointer;
  text-decoration: underline;
  text-underline-offset: 2px;
  white-space: nowrap;
  transition: color 0.18s ease;
}

.btn-accion-servicio:hover:not(:disabled) {
  color: var(--gb-text);
}

.btn-accion-servicio:disabled {
  opacity: 0.35;
  cursor: not-allowed;
  text-decoration: none;
}

.separador-punto {
  color: var(--gb-border);
  font-size: var(--gb-tipo-xs);
}

.plan-form__btn-abrir-modal {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  min-height: 2.125rem;
  height: 2.125rem;
  padding-inline: 0.875rem;
  font-size: var(--gb-tipo-xs);
  border-radius: var(--gb-radius-pill);
  white-space: nowrap;
}

.plan-form__servicios-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 0.75rem;
}

.plan-form__servicio-card {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  min-height: 3.25rem;
  padding: 0.75rem 1rem;
  background-color: var(--gb-surface);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
  color: var(--gb-text-muted);
  cursor: pointer;
  user-select: none;
  transition:
    background-color 0.18s ease,
    border-color 0.18s ease,
    color 0.18s ease,
    box-shadow 0.18s ease,
    transform 0.18s ease;
}

.plan-form__servicio-card:hover {
  background-color: var(--gb-surface-high);
  border-color: var(--gb-border-soft);
  color: var(--gb-text);
  transform: translateY(-1px);
}

.plan-form__servicio-card:focus-within {
  outline: 2px solid var(--gb-focus);
  outline-offset: 2px;
}

.plan-form__servicio-card--activo {
  background-color: rgba(var(--gb-red-rgb), 0.12);
  border-color: var(--gb-red);
  color: #ffffff;
  box-shadow: 0 2px 10px rgba(var(--gb-red-rgb), 0.18);
}

.plan-form__servicio-card--activo:hover {
  background-color: rgba(var(--gb-red-rgb), 0.18);
  border-color: var(--gb-red);
  color: #ffffff;
}

.plan-form__servicio-check {
  display: grid;
  place-items: center;
  width: 1.25rem;
  height: 1.25rem;
  border: 1.5px solid var(--gb-border);
  border-radius: var(--gb-radius-sm);
  background-color: var(--gb-surface-lowest);
  flex-shrink: 0;
  transition: all 0.18s ease;
}

.plan-form__servicio-card:hover .plan-form__servicio-check {
  border-color: var(--gb-text-muted);
}

.plan-form__servicio-card--activo .plan-form__servicio-check {
  border-color: var(--gb-red);
  background-color: var(--gb-red);
  color: var(--gb-on-red);
}

.plan-form__servicio-check :deep(svg) {
  width: 0.875rem;
  height: 0.875rem;
  color: #ffffff;
}

.plan-form__servicio-nombre {
  flex: 1;
  font-size: var(--gb-tipo-sm);
  font-weight: 500;
  line-height: 1.35;
}

.plan-form__servicio-btn-borrar {
  display: grid;
  place-items: center;
  width: 1.5rem;
  height: 1.5rem;
  padding: 0;
  background: transparent;
  border: none;
  color: var(--gb-text-muted);
  font-size: 0.875rem;
  cursor: pointer;
  opacity: 0.6;
  flex-shrink: 0;
  transition:
    opacity 0.15s ease,
    color 0.15s ease;
}

.plan-form__servicio-btn-borrar:hover {
  opacity: 1;
  color: var(--gb-error);
}

.plan-form__servicios--invalido .plan-form__servicio-card {
  border-color: var(--gb-error);
}

.campo__ayuda,
.campo__error {
  margin-top: 0.375rem !important;
  font-size: var(--gb-tipo-xs);
}

.campo__ayuda {
  color: var(--gb-text-muted);
}

.campo__error {
  color: var(--gb-error);
}

.plan-form__estado {
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
  padding: 1rem;
  background-color: var(--gb-surface-lowest);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
  cursor: pointer;
}

.plan-form__estado input {
  width: 1.125rem;
  height: 1.125rem;
  margin-top: 0.125rem;
  accent-color: var(--gb-red);
}

.plan-form__estado span {
  display: grid;
  gap: 0.25rem;
}

.plan-form__estado strong {
  font-size: var(--gb-tipo-sm);
}

.plan-form__estado small {
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}

.plan-form__acciones {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
  margin-top: 0.5rem;
  padding-top: 1.25rem;
  border-top: 1px solid var(--gb-border);
}

.plan-form__acciones .btn {
  min-height: 2.75rem;
  padding-inline: 1.5rem;
}

.modal-servicio-fondo {
  position: fixed;
  inset: 0;
  z-index: 1100;
  display: grid;
  place-items: center;
  padding: 1rem;
  background-color: var(--gb-overlay-strong);
  backdrop-filter: blur(4px);
}

.modal-servicio {
  width: min(100%, 28rem);
  padding: 1.5rem;
  border-radius: var(--gb-radius-xl);
  background-color: var(--gb-surface);
  border: 1px solid var(--gb-border);
  box-shadow: 0 16px 40px rgba(0, 0, 0, 0.6);
  animation: modalAparecer 0.18s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes modalAparecer {
  from {
    opacity: 0;
    transform: scale(0.96) translateY(8px);
  }
  to {
    opacity: 1;
    transform: scale(1) translateY(0);
  }
}

.modal-servicio__cabecera {
  display: flex;
  align-items: flex-start;
  gap: 0.875rem;
  margin-bottom: 1.25rem;
}

.modal-servicio__icono {
  display: grid;
  place-items: center;
  width: 2.5rem;
  height: 2.5rem;
  background-color: rgba(var(--gb-red-rgb), 0.12);
  border: 1px solid rgba(var(--gb-red-rgb), 0.32);
  border-radius: var(--gb-radius-lg);
  color: var(--gb-red-text);
  font-size: 1.125rem;
  flex-shrink: 0;
}

.modal-servicio__titulos {
  flex: 1;
}

.modal-servicio__titulos h3 {
  margin: 0;
  font-size: var(--gb-tipo-md);
  text-transform: uppercase;
  font-family: var(--gb-fuente-titulo);
  color: var(--gb-text);
}

.modal-servicio__titulos p {
  margin: 0.25rem 0 0;
  font-size: var(--gb-tipo-xs);
  color: var(--gb-text-muted);
}

.modal-servicio__btn-cerrar {
  width: 2rem;
  height: 2rem;
  flex-shrink: 0;
  color: var(--gb-text-muted);
}

.modal-servicio__cuerpo {
  display: grid;
  gap: 1.25rem;
}

.modal-servicio__acciones {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
}

.modal-servicio__acciones .btn {
  min-height: 2.5rem;
  padding-inline: 1.25rem;
  font-size: var(--gb-tipo-xs);
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
}

@media (max-width: 64rem) {
  .plan-form__servicios-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 48rem) {
  .plan-form__seccion {
    padding: 1rem;
  }

  .plan-form__campos {
    grid-template-columns: 1fr;
  }

  .campo--completo {
    grid-column: auto;
  }

  .plan-form__servicios-grid {
    grid-template-columns: 1fr;
  }

  .plan-form__servicios-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.75rem;
  }
}

@media (max-width: 28rem) {
  .plan-form__acciones {
    align-items: stretch;
    flex-direction: column-reverse;
  }

  .modal-servicio__acciones {
    flex-direction: column-reverse;
    align-items: stretch;
  }
}
</style>
