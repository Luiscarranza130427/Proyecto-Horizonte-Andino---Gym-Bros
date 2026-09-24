<script setup>
import { Calendar, Send } from 'lucide-vue-next'
import { computed, onMounted, ref, useTemplateRef, watch } from 'vue'

import { useFormulario } from '@/shared/composables/useFormulario'
import { DESTINATARIOS_ALCANCE, TIPOS_NOTIFICACION } from '@/modules/notificaciones/catalogos'
import NotificacionPreview from '@/modules/notificaciones/components/NotificacionPreview.vue'
import { obtenerEmpresas } from '@/modules/empresas/services/empresas.service'

const props = defineProps({
  valoresIniciales: { type: Object, default: () => ({}) },
  enviando: { type: Boolean, default: false },
  erroresServidor: { type: Object, default: () => ({}) },
  esAdministrador: { type: Boolean, default: false },
  nombreRemitente: { type: String, default: 'GYM BROS' },
})

const emit = defineEmits(['submit', 'cancel'])

const tituloInput = useTemplateRef('tituloInput')
const mensajeInput = useTemplateRef('mensajeInput')
const empresaSelect = useTemplateRef('empresaSelect')
const fechaInput = useTemplateRef('fechaInput')

const listaEmpresas = ref([])
const cargandoDestinatarios = ref(false)

const MODELO_VACIO = {
  alcance: 'todos',
  idEmpresas: '',
  tipo: 'recordatorio',
  titulo: '',
  mensaje: '',
  programar: false,
  fechaEnvio: '',
}

function validar(datos, errores) {
  const titulo = datos.titulo.trim()
  if (!titulo) errores.titulo = 'Introduce un título para la notificación.'
  else if (titulo.length < 3) errores.titulo = 'El título debe tener al menos 3 caracteres.'
  else if (titulo.length > 100) errores.titulo = 'El título no puede superar 100 caracteres.'

  const mensaje = datos.mensaje.trim()
  if (!mensaje) errores.mensaje = 'Escribe el contenido del mensaje.'
  else if (mensaje.length < 5) errores.mensaje = 'El mensaje debe tener al menos 5 caracteres.'
  else if (mensaje.length > 500) errores.mensaje = 'El mensaje no puede superar 500 caracteres.'

  if (datos.alcance === 'empresa' && !datos.idEmpresas) {
    errores.idEmpresas = 'Selecciona una empresa destinataria.'
  }

  if (datos.programar) {
    if (!datos.fechaEnvio) {
      errores.fechaEnvio = 'Selecciona la fecha y hora de envío.'
    } else {
      const fechaSeleccionada = new Date(datos.fechaEnvio).getTime()
      if (Number.isNaN(fechaSeleccionada) || fechaSeleccionada <= Date.now()) {
        errores.fechaEnvio = 'La fecha de programación debe ser en el futuro.'
      }
    }
  }
}

const { formulario, errorDe, limpiarError, validarParaEnviar } = useFormulario({
  modeloVacio: MODELO_VACIO,
  valoresIniciales: () => props.valoresIniciales,
  erroresServidor: () => props.erroresServidor,
  referencias: {
    titulo: tituloInput,
    mensaje: mensajeInput,
    idEmpresas: empresaSelect,
    fechaEnvio: fechaInput,
  },
  validar,
  alCargarValores(formulario, valores) {
    if (props.esAdministrador && valores.idEmpresas) {
      formulario.alcance = 'empresa'
    } else {
      formulario.alcance = 'todos'
    }
  },
})

// Fecha mínima para el input datetime-local (ahora + 5 min)
const fechaMinima = computed(() => {
  const ahora = new Date(Date.now() + 5 * 60 * 1000)
  const pad = (n) => String(n).padStart(2, '0')
  const yyyy = ahora.getFullYear()
  const MM = pad(ahora.getMonth() + 1)
  const dd = pad(ahora.getDate())
  const hh = pad(ahora.getHours())
  const mm = pad(ahora.getMinutes())
  return `${yyyy}-${MM}-${dd}T${hh}:${mm}`
})

const alcancesDisponibles = computed(() =>
  props.esAdministrador
    ? DESTINATARIOS_ALCANCE
    : DESTINATARIOS_ALCANCE.filter((opcion) => opcion.valor === 'todos'),
)

const destinatarioTexto = computed(() => {
  if (formulario.alcance === 'todos') {
    return props.esAdministrador ? 'Todos los usuarios' : 'Todos los usuarios de mi empresa'
  }
  if (formulario.alcance === 'empresa') {
    const emp = listaEmpresas.value.find((e) => Number(e.id) === Number(formulario.idEmpresas))
    return emp ? `Empresa: ${emp.nombre}` : 'Empresa seleccionada'
  }
  return 'Destinatario'
})

onMounted(async () => {
  if (!props.esAdministrador) return
  cargandoDestinatarios.value = true
  try {
    const empresasRes = await obtenerEmpresas({ porPagina: 100 })
    listaEmpresas.value = empresasRes.items || []
  } catch {
    // Si falla la carga de empresas, se mantiene el envío para el alcance general.
  } finally {
    cargandoDestinatarios.value = false
  }
})

watch(
  () => formulario.alcance,
  (nuevoAlcance) => {
    limpiarError('idEmpresas')
    if (nuevoAlcance === 'todos') {
      formulario.idEmpresas = ''
    }
  },
)

async function enviar() {
  const esValido = await validarParaEnviar()
  if (!esValido) return

  const payload = {
    alcance: formulario.alcance,
    tipo: formulario.tipo,
    titulo: formulario.titulo.trim(),
    mensaje: formulario.mensaje.trim(),
    idEmpresas:
      formulario.alcance === 'empresa' && formulario.idEmpresas
        ? Number(formulario.idEmpresas)
        : null,
    programar: formulario.programar,
    fechaEnvio: formulario.programar ? new Date(formulario.fechaEnvio).toISOString() : null,
  }

  // Agregar nombres legibles para optimismo en mocks
  if (payload.idEmpresas) {
    const emp = listaEmpresas.value.find((e) => Number(e.id) === payload.idEmpresas)
    if (emp) payload.nombreEmpresa = emp.nombre
  }
  emit('submit', payload)
}
</script>

<template>
  <div class="notificacion-editor-grid">
    <!-- Formulario principal -->
    <form class="notificacion-form gb-tarjeta" novalidate @submit.prevent="enviar">
      <header class="notificacion-form__cabecera">
        <span class="notificacion-form__icono-cabecera" aria-hidden="true">
          <Send :size="20" />
        </span>
        <div>
          <h2>Redactar notificación</h2>
          <p>Comunica avisos, rutinas o actualizaciones a tus clientes y sedes.</p>
        </div>
      </header>

      <div class="notificacion-form__campos">
        <!-- Selector de Alcance / Destinatarios -->
        <fieldset class="campo campo--completo notificacion-form__alcance-grupo">
          <legend class="form-label">Destinatarios *</legend>
          <div class="notificacion-form__alcance-opciones" role="radiogroup">
            <label
              v-for="opcion in alcancesDisponibles"
              :key="opcion.valor"
              class="notificacion-form__alcance-card"
              :class="{
                'notificacion-form__alcance-card--activo': formulario.alcance === opcion.valor,
              }"
            >
              <input
                v-model="formulario.alcance"
                type="radio"
                name="alcance"
                :value="opcion.valor"
                class="visually-hidden"
              />
              <span class="notificacion-form__alcance-icono" aria-hidden="true">
                <component :is="opcion.icono" :size="18" />
              </span>
              <span class="notificacion-form__alcance-textos">
                <strong>{{ opcion.etiqueta }}</strong>
                <small>{{ opcion.descripcion }}</small>
              </span>
            </label>
          </div>
        </fieldset>

        <div v-if="esAdministrador && formulario.alcance === 'empresa'" class="campo">
          <label class="form-label" for="notif-empresa">Empresa / Sede *</label>
          <select
            id="notif-empresa"
            ref="empresaSelect"
            v-model="formulario.idEmpresas"
            class="form-select"
            :class="{ 'is-invalid': errorDe('idEmpresas') }"
            name="idEmpresas"
            :disabled="cargandoDestinatarios"
            :aria-invalid="Boolean(errorDe('idEmpresas'))"
            :aria-describedby="errorDe('idEmpresas') ? 'error-empresa' : null"
            @change="limpiarError('idEmpresas')"
          >
            <option value="">
              {{ cargandoDestinatarios ? 'Cargando empresas…' : 'Selecciona una empresa' }}
            </option>
            <option v-for="emp in listaEmpresas" :key="emp.id" :value="emp.id">
              {{ emp.nombre }}
            </option>
          </select>
          <p v-if="errorDe('idEmpresas')" id="error-empresa" class="campo__error" role="alert">
            {{ errorDe('idEmpresas') }}
          </p>
        </div>

        <!-- Selector de Tipo de Notificación -->
        <fieldset class="campo campo--completo notificacion-form__tipo-grupo">
          <legend class="form-label">Tipo de notificación *</legend>
          <div class="notificacion-form__tipos-grid" role="radiogroup">
            <label
              v-for="tipo in TIPOS_NOTIFICACION"
              :key="tipo.valor"
              class="notificacion-form__tipo-card"
              :class="{
                'notificacion-form__tipo-card--activo': formulario.tipo === tipo.valor,
              }"
            >
              <input
                v-model="formulario.tipo"
                type="radio"
                name="tipo"
                :value="tipo.valor"
                class="visually-hidden"
              />
              <span
                class="notificacion-form__tipo-icono"
                :style="{ color: tipo.color, backgroundColor: tipo.colorFondo }"
                aria-hidden="true"
              >
                <component :is="tipo.icono" :size="16" />
              </span>
              <div class="notificacion-form__tipo-info">
                <strong>{{ tipo.etiqueta }}</strong>
                <small>{{ tipo.descripcion }}</small>
              </div>
            </label>
          </div>
        </fieldset>

        <!-- Título -->
        <div class="campo campo--completo">
          <div class="notificacion-form__campo-header">
            <label class="form-label mb-0" for="notif-titulo">Título *</label>
            <span class="notificacion-form__conteo">{{ formulario.titulo.length }} / 100</span>
          </div>
          <input
            id="notif-titulo"
            ref="tituloInput"
            v-model="formulario.titulo"
            type="text"
            class="form-control"
            :class="{ 'is-invalid': errorDe('titulo') }"
            name="titulo"
            placeholder="Ej. Nueva rutina asignada, Aviso de feriado..."
            maxlength="100"
            autocomplete="off"
            :aria-invalid="Boolean(errorDe('titulo'))"
            :aria-describedby="errorDe('titulo') ? 'error-titulo' : null"
            @input="limpiarError('titulo')"
          />
          <p v-if="errorDe('titulo')" id="error-titulo" class="campo__error" role="alert">
            {{ errorDe('titulo') }}
          </p>
        </div>

        <!-- Mensaje -->
        <div class="campo campo--completo">
          <div class="notificacion-form__campo-header">
            <label class="form-label mb-0" for="notif-mensaje">Mensaje *</label>
            <span class="notificacion-form__conteo">{{ formulario.mensaje.length }} / 500</span>
          </div>
          <textarea
            id="notif-mensaje"
            ref="mensajeInput"
            v-model="formulario.mensaje"
            class="form-control"
            :class="{ 'is-invalid': errorDe('mensaje') }"
            name="mensaje"
            rows="4"
            placeholder="Escribe el texto detallado que verán los usuarios..."
            maxlength="500"
            :aria-invalid="Boolean(errorDe('mensaje'))"
            :aria-describedby="errorDe('mensaje') ? 'error-mensaje' : null"
            @input="limpiarError('mensaje')"
          ></textarea>
          <p v-if="errorDe('mensaje')" id="error-mensaje" class="campo__error" role="alert">
            {{ errorDe('mensaje') }}
          </p>
        </div>

        <!-- Conmutador de Programación -->
        <div class="campo campo--completo notificacion-form__programacion">
          <label class="notificacion-form__programar-toggle">
            <input
              v-model="formulario.programar"
              type="checkbox"
              name="programar"
              @change="limpiarError('fechaEnvio')"
            />
            <span class="notificacion-form__programar-info">
              <span class="notificacion-form__programar-titulo">
                <Calendar :size="16" />
                <strong>Programar envío para una fecha futura</strong>
              </span>
              <small>
                Si se desmarca, la notificación se enviará de inmediato a los destinatarios.
              </small>
            </span>
          </label>

          <div v-if="formulario.programar" class="notificacion-form__fecha-input-wrap">
            <label class="form-label" for="notif-fecha">Fecha y hora de envío *</label>
            <input
              id="notif-fecha"
              ref="fechaInput"
              v-model="formulario.fechaEnvio"
              type="datetime-local"
              class="form-control"
              :class="{ 'is-invalid': errorDe('fechaEnvio') }"
              name="fechaEnvio"
              :min="fechaMinima"
              :aria-invalid="Boolean(errorDe('fechaEnvio'))"
              :aria-describedby="errorDe('fechaEnvio') ? 'error-fecha' : null"
              @input="limpiarError('fechaEnvio')"
            />
            <p v-if="errorDe('fechaEnvio')" id="error-fecha" class="campo__error" role="alert">
              {{ errorDe('fechaEnvio') }}
            </p>
          </div>
        </div>
      </div>

      <footer class="notificacion-form__acciones">
        <button type="button" class="btn btn-ghost" :disabled="enviando" @click="$emit('cancel')">
          Limpiar
        </button>
        <button type="submit" class="btn btn-primary" :disabled="enviando">
          <component :is="formulario.programar ? Calendar : Send" :size="16" />
          <span>
            {{
              enviando
                ? 'Procesando…'
                : formulario.programar
                  ? 'Programar notificación'
                  : 'Enviar notificación ahora'
            }}
          </span>
        </button>
      </footer>
    </form>

    <!-- Previsualización en tiempo real -->
    <NotificacionPreview
      :titulo="formulario.titulo"
      :mensaje="formulario.mensaje"
      :tipo="formulario.tipo"
      :destinatario-texto="destinatarioTexto"
      :programar="formulario.programar"
      :fecha-envio="formulario.fechaEnvio"
      :nombre-remitente="nombreRemitente"
    />
  </div>
</template>

<style scoped>
.notificacion-editor-grid {
  display: grid;
  grid-template-columns: minmax(0, 1.4fr) minmax(0, 0.9fr);
  gap: 1.5rem;
  align-items: start;
}

.notificacion-form {
  display: grid;
  gap: 1.5rem;
  padding: 1.5rem;
  border-radius: var(--gb-radius-xl);
}

.notificacion-form__cabecera {
  display: flex;
  align-items: center;
  gap: 0.875rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid var(--gb-border);
}

.notificacion-form__icono-cabecera {
  display: grid;
  place-items: center;
  width: 2.75rem;
  height: 2.75rem;
  background-color: var(--gb-surface-high);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
  color: var(--gb-red-text);
  font-size: 1.125rem;
  flex-shrink: 0;
}

.notificacion-form__cabecera h2,
.notificacion-form__cabecera p {
  margin: 0;
}

.notificacion-form__cabecera h2 {
  font-size: var(--gb-tipo-md);
  text-transform: uppercase;
}

.notificacion-form__cabecera p {
  margin-top: 0.25rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}

.notificacion-form__campos {
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

.notificacion-form__campo-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 0.375rem;
}

.notificacion-form__conteo {
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
  font-variant-numeric: tabular-nums;
}

/* Selector de alcance */
.notificacion-form__alcance-grupo {
  margin: 0;
  padding: 0;
  border: 0;
}

.notificacion-form__alcance-opciones {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 0.75rem;
}

.notificacion-form__alcance-card {
  display: flex;
  align-items: flex-start;
  gap: 0.625rem;
  padding: 0.875rem 1rem;
  background-color: var(--gb-surface-lowest);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
  cursor: pointer;
  user-select: none;
  transition:
    border-color 0.18s ease,
    background-color 0.18s ease;
}

.notificacion-form__alcance-card:hover {
  background-color: var(--gb-surface-high);
  border-color: var(--gb-text-muted);
}

.notificacion-form__alcance-card--activo {
  background-color: rgba(var(--gb-red-rgb), 0.1);
  border-color: var(--gb-red);
}

.notificacion-form__alcance-icono {
  display: grid;
  place-items: center;
  color: var(--gb-red-text);
  font-size: 1.125rem;
  margin-top: 0.125rem;
}

.notificacion-form__alcance-textos {
  display: grid;
  gap: 0.125rem;
}

.notificacion-form__alcance-textos strong {
  font-size: var(--gb-tipo-xs);
  color: var(--gb-text);
}

.notificacion-form__alcance-textos small {
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
  line-height: 1.3;
}

/* Selector de tipo */
.notificacion-form__tipo-grupo {
  margin: 0;
  padding: 0;
  border: 0;
}

.notificacion-form__tipos-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 0.625rem;
}

.notificacion-form__tipo-card {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  padding: 0.625rem 0.75rem;
  background-color: var(--gb-surface-lowest);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
  cursor: pointer;
  user-select: none;
  transition:
    border-color 0.18s ease,
    background-color 0.18s ease;
}

.notificacion-form__tipo-card:hover {
  background-color: var(--gb-surface-high);
}

.notificacion-form__tipo-card--activo {
  border-color: var(--gb-red);
  background-color: rgba(var(--gb-red-rgb), 0.1);
}

.notificacion-form__tipo-icono {
  display: grid;
  place-items: center;
  width: 2rem;
  height: 2rem;
  border-radius: var(--gb-radius-md);
  font-size: 0.875rem;
  flex-shrink: 0;
}

.notificacion-form__tipo-info {
  display: grid;
  min-width: 0;
}

.notificacion-form__tipo-info strong {
  font-size: var(--gb-tipo-xs);
  color: var(--gb-text);
}

.notificacion-form__tipo-info small {
  color: var(--gb-text-muted);
  font-size: 0.6875rem;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* Programación */
.notificacion-form__programacion {
  display: grid;
  gap: 0.875rem;
  padding: 1rem;
  background-color: var(--gb-surface-lowest);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
}

.notificacion-form__programar-toggle {
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
  cursor: pointer;
  user-select: none;
  margin: 0;
}

.notificacion-form__programar-toggle input {
  width: 1.125rem;
  height: 1.125rem;
  margin-top: 0.125rem;
  accent-color: var(--gb-red);
}

.notificacion-form__programar-info {
  display: grid;
  gap: 0.25rem;
}

.notificacion-form__programar-titulo {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  color: var(--gb-text);
  font-size: var(--gb-tipo-sm);
}

.notificacion-form__programar-info small {
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}

.notificacion-form__fecha-input-wrap {
  padding-top: 0.75rem;
  border-top: 1px dashed var(--gb-border);
}

.campo__error {
  margin-top: 0.375rem !important;
  font-size: var(--gb-tipo-xs);
  color: var(--gb-error);
}

.notificacion-form__acciones {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
  margin-top: 0.5rem;
  padding-top: 1.25rem;
  border-top: 1px solid var(--gb-border);
}

.notificacion-form__acciones .btn {
  min-height: 2.75rem;
  padding-inline: 1.5rem;
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
}

@media (max-width: 78rem) {
  .notificacion-editor-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 48rem) {
  .notificacion-form {
    padding: 1rem;
  }

  .notificacion-form__campos {
    grid-template-columns: 1fr;
  }

  .notificacion-form__alcance-opciones,
  .notificacion-form__tipos-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 28rem) {
  .notificacion-form__acciones {
    flex-direction: column-reverse;
    align-items: stretch;
  }
}
</style>
