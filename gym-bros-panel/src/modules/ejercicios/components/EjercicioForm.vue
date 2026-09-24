<script setup>
import { Dumbbell } from 'lucide-vue-next'
import { computed, onBeforeUnmount, ref, useTemplateRef } from 'vue'

import { useFormulario } from '@/shared/composables/useFormulario'
import { EQUIPOS, NIVELES, valoresDe } from '@/modules/ejercicios/catalogos'

const props = defineProps({
  valoresIniciales: { type: Object, default: () => ({}) },
  enviando: { type: Boolean, default: false },
  erroresServidor: { type: Object, default: () => ({}) },
  modo: { type: String, default: 'create' },
  gruposMusculares: { type: Array, default: () => [] },
  cargandoGrupos: { type: Boolean, default: false },
  errorGrupos: { type: String, default: '' },
})

const emit = defineEmits(['submit', 'cancel', 'reintentar-grupos'])

const MODELO_VACIO = {
  nombre: '',
  tipo: '',
  instrucciones: '',
  nivel: '',
  equipamiento: '',
  descripcion: '',
  enlaceVideo: '',
  idGruposMusculares: '',
  // Activo en el catálogo global: cada empresa lo habilita aparte (empresa_ejercicio).
  // Con 'inactive' el alta quedaba inutilizable, porque la interfaz no permite reactivarlo.
  estado: 'active',
}

const nombreInput = useTemplateRef('nombreInput')
const tipoInput = useTemplateRef('tipoInput')
const nivelInput = useTemplateRef('nivelInput')
const equipamientoInput = useTemplateRef('equipamientoInput')
const descripcionInput = useTemplateRef('descripcionInput')
const instruccionesInput = useTemplateRef('instruccionesInput')
const grupoInput = useTemplateRef('grupoInput')
const imagenInput = useTemplateRef('imagenInput')
const archivoImagen = ref(null)
const vistaPreviaImagen = ref('')

/** Reglas propias de un ejercicio. Los catálogos son el vocabulario cerrado. */
function validar(datos, errores) {
  if (datos.nombre.trim().length < 3) {
    errores.nombre = 'Introduce un nombre de al menos 3 caracteres.'
  }

  if (!['fuerza', 'cardio', 'flexibilidad', 'equilibrio'].includes(datos.tipo)) {
    errores.tipo = 'Selecciona un tipo válido.'
  }
  if (!valoresDe(NIVELES).includes(datos.nivel)) {
    errores.nivel = 'Selecciona un nivel válido.'
  }
  if (!datos.equipamiento.trim()) {
    errores.equipamiento = 'Selecciona un equipamiento válido.'
  }
  if (!datos.instrucciones.trim()) {
    errores.instrucciones = 'Indica las instrucciones del ejercicio.'
  }
  // Al editar se conserva la imagen actual si no se elige otra (la API la trata como opcional).
  if (props.modo !== 'edit' && !(archivoImagen.value instanceof File)) {
    errores.imagenEjercicio = 'Selecciona una imagen para el ejercicio.'
  }
  if (!Number.isInteger(Number(datos.idGruposMusculares)) || Number(datos.idGruposMusculares) < 1) {
    errores.idGruposMusculares = 'Indica un ID de grupo muscular válido.'
  }
}

const { formulario, erroresLocales, erroresRemotos, errorDe, limpiarError, validarParaEnviar } =
  useFormulario({
    modeloVacio: MODELO_VACIO,
    valoresIniciales: () => props.valoresIniciales,
    erroresServidor: () => props.erroresServidor,
    referencias: {
      nombre: nombreInput,
      tipo: tipoInput,
      nivel: nivelInput,
      equipamiento: equipamientoInput,
      descripcion: descripcionInput,
      instrucciones: instruccionesInput,
      idGruposMusculares: grupoInput,
      imagenEjercicio: imagenInput,
    },
    validar,
  })

/*
 * En la base el equipamiento es texto libre («barra y banco», «polea alta»…) y
 * el catálogo sólo tiene seis valores. Si el guardado no está en el catálogo se
 * ofrece como opción: sin ella el select quedaba vacío y editar cualquier otro
 * campo obligaba a cambiar un dato real.
 */
const opcionesEquipo = computed(() => {
  const actual = String(props.valoresIniciales?.equipamiento ?? '').trim()
  if (!actual || valoresDe(EQUIPOS).includes(actual)) return EQUIPOS
  return [...EQUIPOS, { valor: actual, etiqueta: actual.charAt(0).toUpperCase() + actual.slice(1) }]
})

async function enviar() {
  if (props.enviando) return
  if (!(await validarParaEnviar())) return

  emit('submit', {
    ...formulario,
    nombre: formulario.nombre.trim(),
    descripcion: formulario.descripcion.trim(),
    instrucciones: formulario.instrucciones.trim(),
    equipamiento: formulario.equipamiento.trim(),
    enlaceVideo: formulario.enlaceVideo.trim(),
    idGruposMusculares: Number(formulario.idGruposMusculares),
    imagenEjercicio: archivoImagen.value,
  })
}

function cambiarImagen(evento) {
  const [archivo] = evento.target.files ?? []
  if (!archivo) return
  const valido =
    ['image/jpeg', 'image/png', 'image/webp'].includes(archivo.type) &&
    archivo.size <= 5 * 1024 * 1024
  if (!valido) {
    quitarImagen()
    return
  }
  if (vistaPreviaImagen.value) URL.revokeObjectURL(vistaPreviaImagen.value)
  archivoImagen.value = archivo
  vistaPreviaImagen.value = URL.createObjectURL(archivo)
  limpiarError('imagenEjercicio')
}

function quitarImagen() {
  if (vistaPreviaImagen.value) URL.revokeObjectURL(vistaPreviaImagen.value)
  archivoImagen.value = null
  vistaPreviaImagen.value = ''
  if (imagenInput.value) imagenInput.value.value = ''
}

onBeforeUnmount(quitarImagen)
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

    <section class="formulario__seccion gb-tarjeta" aria-labelledby="titulo-ejercicio">
      <header>
        <span aria-hidden="true"><Dumbbell :size="20" /></span>
        <div>
          <h2 id="titulo-ejercicio">Información del ejercicio</h2>
          <p>Cómo se identifica y se clasifica dentro del catálogo.</p>
        </div>
      </header>

      <div class="formulario__rejilla">
        <div class="campo campo--completo">
          <label class="form-label" for="ejercicio-nombre">Nombre del ejercicio *</label>
          <input
            id="ejercicio-nombre"
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
          <label class="form-label" for="ejercicio-tipo">Tipo *</label>
          <select
            id="ejercicio-tipo"
            ref="tipoInput"
            v-model="formulario.tipo"
            class="form-select"
            :class="{ 'is-invalid': errorDe('tipo') }"
            name="tipo"
            required
            :aria-invalid="Boolean(errorDe('tipo'))"
            :aria-describedby="errorDe('tipo') ? 'error-tipo' : null"
            @change="limpiarError('tipo')"
          >
            <option value="">Selecciona un tipo</option>
            <option value="fuerza">Fuerza</option>
            <option value="cardio">Cardio</option>
            <option value="flexibilidad">Flexibilidad</option>
            <option value="equilibrio">Equilibrio</option>
          </select>
          <p v-if="errorDe('tipo')" id="error-tipo" class="campo__error" role="alert">
            {{ errorDe('tipo') }}
          </p>
        </div>

        <div class="campo">
          <label class="form-label" for="ejercicio-nivel">Nivel *</label>
          <select
            id="ejercicio-nivel"
            ref="nivelInput"
            v-model="formulario.nivel"
            class="form-select"
            :class="{ 'is-invalid': errorDe('nivel') }"
            name="nivel"
            required
            :aria-invalid="Boolean(errorDe('nivel'))"
            :aria-describedby="errorDe('nivel') ? 'error-nivel' : null"
            @change="limpiarError('nivel')"
          >
            <option value="">Selecciona un nivel</option>
            <option v-for="opcion in NIVELES" :key="opcion.valor" :value="opcion.valor">
              {{ opcion.etiqueta }}
            </option>
          </select>
          <p v-if="errorDe('nivel')" id="error-nivel" class="campo__error" role="alert">
            {{ errorDe('nivel') }}
          </p>
        </div>

        <div class="campo">
          <label class="form-label" for="ejercicio-equipamiento">Equipamiento *</label>
          <select
            id="ejercicio-equipamiento"
            ref="equipamientoInput"
            v-model="formulario.equipamiento"
            class="form-select"
            :class="{ 'is-invalid': errorDe('equipamiento') }"
            name="equipamiento"
            required
            :aria-invalid="Boolean(errorDe('equipamiento'))"
            :aria-describedby="errorDe('equipamiento') ? 'error-equipamiento' : null"
            @change="limpiarError('equipamiento')"
          >
            <option value="">Selecciona un equipamiento</option>
            <option v-for="opcion in opcionesEquipo" :key="opcion.valor" :value="opcion.valor">
              {{ opcion.etiqueta }}
            </option>
          </select>
          <p
            v-if="errorDe('equipamiento')"
            id="error-equipamiento"
            class="campo__error"
            role="alert"
          >
            {{ errorDe('equipamiento') }}
          </p>
        </div>

        <div class="campo">
          <label class="form-label" for="ejercicio-grupo">Grupo muscular *</label>
          <select
            id="ejercicio-grupo"
            ref="grupoInput"
            v-model="formulario.idGruposMusculares"
            class="form-select"
            :class="{ 'is-invalid': errorDe('idGruposMusculares') }"
            name="idGruposMusculares"
            required
            :disabled="cargandoGrupos || Boolean(errorGrupos)"
            @change="limpiarError('idGruposMusculares')"
          >
            <option value="">
              {{ cargandoGrupos ? 'Cargando grupos…' : 'Selecciona un grupo muscular' }}
            </option>
            <option v-for="grupo in gruposMusculares" :key="grupo.id" :value="grupo.id">
              {{ grupo.tipo.charAt(0).toUpperCase() + grupo.tipo.slice(1) }}
            </option>
          </select>
          <p v-if="errorDe('idGruposMusculares')" class="campo__error" role="alert">
            {{ errorDe('idGruposMusculares') }}
          </p>
          <p v-if="errorGrupos" class="campo__error" role="alert">
            {{ errorGrupos }}
            <button type="button" class="campo__reintentar" @click="emit('reintentar-grupos')">
              Reintentar
            </button>
          </p>
        </div>

        <div class="campo campo--completo">
          <label class="form-label" for="ejercicio-descripcion">Descripción</label>
          <textarea
            id="ejercicio-descripcion"
            ref="descripcionInput"
            v-model="formulario.descripcion"
            class="form-control"
            :class="{ 'is-invalid': errorDe('descripcion') }"
            name="descripcion"
            rows="3"
            :aria-invalid="Boolean(errorDe('descripcion'))"
            :aria-describedby="errorDe('descripcion') ? 'error-descripcion' : 'ayuda-descripcion'"
            @input="limpiarError('descripcion')"
          ></textarea>
          <p id="ayuda-descripcion" class="campo__ayuda">
            Qué trabaja y cómo se ejecuta. Es lo que verá el entrenador en la ficha.
          </p>
          <p v-if="errorDe('descripcion')" id="error-descripcion" class="campo__error" role="alert">
            {{ errorDe('descripcion') }}
          </p>
        </div>

        <div class="campo campo--completo">
          <label class="form-label" for="ejercicio-instrucciones">Instrucciones *</label>
          <textarea
            id="ejercicio-instrucciones"
            ref="instruccionesInput"
            v-model="formulario.instrucciones"
            class="form-control"
            :class="{ 'is-invalid': errorDe('instrucciones') }"
            name="instrucciones"
            rows="3"
            required
            @input="limpiarError('instrucciones')"
          ></textarea>
          <p v-if="errorDe('instrucciones')" class="campo__error" role="alert">
            {{ errorDe('instrucciones') }}
          </p>
        </div>

        <div class="campo campo--completo">
          <label class="form-label" for="ejercicio-imagen"
            >Imagen del ejercicio{{ modo === 'edit' ? '' : ' *' }}</label
          >
          <div class="imagen-ejercicio">
            <img
              v-if="vistaPreviaImagen"
              :src="vistaPreviaImagen"
              alt="Vista previa del ejercicio"
            />
            <img
              v-else-if="modo === 'edit' && valoresIniciales.imagen"
              :src="valoresIniciales.imagen"
              alt="Imagen actual del ejercicio"
            />
            <p v-if="vistaPreviaImagen" class="imagen-ejercicio__medida">
              Medida recomendada: 380 × 500 px.
            </p>
            <input
              id="ejercicio-imagen"
              ref="imagenInput"
              class="form-control"
              :class="{ 'is-invalid': errorDe('imagenEjercicio') }"
              type="file"
              accept="image/jpeg,image/png,image/webp,.jpg,.jpeg,.png,.webp"
              :disabled="enviando"
              @change="cambiarImagen"
            />
            <button
              v-if="archivoImagen"
              type="button"
              class="btn btn-ghost"
              :disabled="enviando"
              @click="quitarImagen"
            >
              Quitar imagen
            </button>
          </div>
          <p class="campo__ayuda">JPG, JPEG, PNG o WebP. Máximo 5 MB.</p>
          <p v-if="errorDe('imagenEjercicio')" class="campo__error" role="alert">
            {{ errorDe('imagenEjercicio') }}
          </p>
        </div>

        <div class="campo">
          <label class="form-label" for="ejercicio-video">Enlace de video</label>
          <input
            id="ejercicio-video"
            v-model="formulario.enlaceVideo"
            class="form-control"
            type="url"
            name="enlaceVideo"
            maxlength="350"
            @input="limpiarError('enlaceVideo')"
          />
        </div>
      </div>
    </section>

    <div class="formulario__acciones">
      <button type="button" class="btn btn-secondary" :disabled="enviando" @click="emit('cancel')">
        Cancelar
      </button>
      <button type="submit" class="btn btn-primary" :disabled="enviando">
        <span v-if="enviando" class="spinner-border spinner-border-sm" aria-hidden="true"></span>
        {{ enviando ? 'Guardando…' : modo === 'edit' ? 'Guardar cambios' : 'Guardar ejercicio' }}
      </button>
    </div>
  </form>
</template>

<style scoped>
.formulario {
  display: grid;
  gap: var(--gb-gutter, 1.25rem);
}

.formulario__seccion {
  padding: 1.25rem 1.5rem;
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

.imagen-ejercicio {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 0.75rem;
  align-items: center;
}

.imagen-ejercicio img {
  grid-column: 1 / -1;
  width: min(100%, 20rem);
  max-height: 15rem;
  border: 1px solid var(--gb-border);
  border-radius: 5px;
  object-fit: contain;
}

.imagen-ejercicio__medida {
  grid-column: 1 / -1;
  margin: -0.25rem 0 0;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}

.campo__reintentar {
  margin-left: 0.375rem;
  padding: 0;
  border: 0;
  background: transparent;
  color: inherit;
  font: inherit;
  text-decoration: underline;
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
  .formulario__rejilla {
    grid-template-columns: 1fr;
  }

  .campo--completo {
    grid-column: auto;
  }
}
</style>
