<script setup>
import { Building2, Globe, Info, Mail, MapPin, Phone, RotateCcw, Save, User } from 'lucide-vue-next'
import { reactive, watch } from 'vue'

const props = defineProps({
  perfil: {
    type: Object,
    required: true,
  },
  guardando: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits(['guardar'])

const formulario = reactive({
  nombre: '',
  nombre_gerente: '',
  ruc: '',
  telefono: '',
  correo: '',
  region: '',
  direccion: '',
  enlace_web: '',
})

const errores = reactive({})

function sincronizarFormulario() {
  formulario.nombre = props.perfil.nombre ?? ''
  formulario.nombre_gerente = props.perfil.nombre_gerente ?? props.perfil.gerente ?? ''
  formulario.ruc = props.perfil.ruc ?? ''
  formulario.telefono = props.perfil.telefono ?? ''
  formulario.correo = props.perfil.correo ?? ''
  formulario.region = props.perfil.region ?? ''
  formulario.direccion = props.perfil.direccion ?? ''
  formulario.enlace_web = props.perfil.enlace_web ?? ''
  limpiarErrores()
}

watch(() => props.perfil, sincronizarFormulario, { immediate: true })

function limpiarErrores() {
  Object.keys(errores).forEach((k) => delete errores[k])
}

function validar() {
  limpiarErrores()
  let valido = true

  if (!formulario.nombre.trim()) {
    errores.nombre = 'El nombre de la empresa es obligatorio.'
    valido = false
  }

  if (!formulario.nombre_gerente.trim()) {
    errores.nombre_gerente = 'El nombre del gerente es obligatorio.'
    valido = false
  }

  if (formulario.telefono && !/^[+0-9\s-]{6,20}$/.test(formulario.telefono.trim())) {
    errores.telefono = 'Ingresa un formato de teléfono válido.'
    valido = false
  }

  return valido
}

function enviar() {
  if (!validar()) return
  emit('guardar', { ...formulario })
}
</script>

<template>
  <form class="perfil-form gb-tarjeta" novalidate @submit.prevent="enviar">
    <header class="perfil-form__cabecera">
      <div class="perfil-form__icono-cabecera" aria-hidden="true">
        <Building2 :size="20" />
      </div>
      <div>
        <h2 class="perfil-form__titulo">Datos de la Empresa / Sede</h2>
        <p class="perfil-form__descripcion">
          Información comercial, fiscal y de contacto de tu gimnasio en la plataforma.
        </p>
      </div>
    </header>

    <div class="perfil-form__cuerpo">
      <div class="perfil-form__rejilla">
        <!-- Nombre del Gimnasio -->
        <div class="campo">
          <label class="form-label" for="empresa-nombre">Nombre Comercial del Gimnasio *</label>
          <div class="input-icono-wrapper">
            <Building2 :size="16" class="input-icono" aria-hidden="true" />
            <input
              id="empresa-nombre"
              v-model="formulario.nombre"
              type="text"
              class="form-control form-control--con-icono"
              :class="{ 'is-invalid': errores.nombre }"
              placeholder="Ej. Titan Gym"
              required
              :aria-invalid="Boolean(errores.nombre)"
              :aria-describedby="errores.nombre ? 'error-empresa-nombre' : null"
              @input="delete errores.nombre"
            />
          </div>
          <p v-if="errores.nombre" id="error-empresa-nombre" class="campo__error">
            {{ errores.nombre }}
          </p>
        </div>

        <!-- Gerente / Administrador -->
        <div class="campo">
          <label class="form-label" for="empresa-gerente">Gerente / Administrador *</label>
          <div class="input-icono-wrapper">
            <User :size="16" class="input-icono" aria-hidden="true" />
            <input
              id="empresa-gerente"
              v-model="formulario.nombre_gerente"
              type="text"
              class="form-control form-control--con-icono"
              :class="{ 'is-invalid': errores.nombre_gerente }"
              placeholder="Ej. Carlos Mendoza"
              required
              :aria-invalid="Boolean(errores.nombre_gerente)"
              :aria-describedby="errores.nombre_gerente ? 'error-empresa-gerente' : null"
              @input="delete errores.nombre_gerente"
            />
          </div>
          <p v-if="errores.nombre_gerente" id="error-empresa-gerente" class="campo__error">
            {{ errores.nombre_gerente }}
          </p>
        </div>

        <!-- RUC -->
        <div class="campo">
          <label class="form-label" for="empresa-ruc">Número de RUC</label>
          <input
            id="empresa-ruc"
            v-model="formulario.ruc"
            type="text"
            class="form-control"
            placeholder="RUC de 11 dígitos"
          />
        </div>

        <!-- Teléfono / WhatsApp -->
        <div class="campo">
          <label class="form-label" for="empresa-telefono">Teléfono / WhatsApp de la Sede</label>
          <div class="input-icono-wrapper">
            <Phone :size="16" class="input-icono" aria-hidden="true" />
            <input
              id="empresa-telefono"
              v-model="formulario.telefono"
              type="tel"
              class="form-control form-control--con-icono"
              :class="{ 'is-invalid': errores.telefono }"
              placeholder="+51 976 123 456"
              :aria-invalid="Boolean(errores.telefono)"
              :aria-describedby="errores.telefono ? 'error-empresa-telefono' : null"
              @input="delete errores.telefono"
            />
          </div>
          <p v-if="errores.telefono" id="error-empresa-telefono" class="campo__error">
            {{ errores.telefono }}
          </p>
        </div>

        <!-- Correo corporativo -->
        <div class="campo">
          <label class="form-label" for="empresa-correo">Correo Corporativo Oficial</label>
          <div class="input-icono-wrapper">
            <Mail :size="16" class="input-icono" aria-hidden="true" />
            <input
              id="empresa-correo"
              v-model="formulario.correo"
              type="email"
              class="form-control form-control--con-icono"
              placeholder="contacto@gymbros.pe"
            />
          </div>
          <p class="campo__ayuda">
            <Info :size="13" aria-hidden="true" />
            <span>Correo utilizado para notificaciones del SaaS y facturación.</span>
          </p>
        </div>

        <!-- Región / Departamento -->
        <div class="campo">
          <label class="form-label" for="empresa-region">Región / Departamento</label>
          <input
            id="empresa-region"
            v-model="formulario.region"
            type="text"
            class="form-control"
            placeholder="Cajamarca"
          />
        </div>

        <!-- Dirección física -->
        <div class="campo campo--completo">
          <label class="form-label" for="empresa-direccion">Dirección Física de la Sede</label>
          <div class="input-icono-wrapper">
            <MapPin :size="16" class="input-icono" aria-hidden="true" />
            <input
              id="empresa-direccion"
              v-model="formulario.direccion"
              type="text"
              class="form-control form-control--con-icono"
              placeholder="Calle, número, distrito"
            />
          </div>
        </div>

        <!-- Sitio Web Oficial -->
        <div class="campo campo--completo">
          <label class="form-label" for="empresa-web">Página Web Oficial</label>
          <div class="input-icono-wrapper">
            <Globe :size="16" class="input-icono" aria-hidden="true" />
            <input
              id="empresa-web"
              v-model="formulario.enlace_web"
              type="url"
              class="form-control form-control--con-icono"
              placeholder="https://gymbros.pe"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Botonera de acciones -->
    <footer class="perfil-form__acciones">
      <button
        type="button"
        class="btn btn-secondary"
        :disabled="guardando"
        @click="sincronizarFormulario"
      >
        <RotateCcw :size="16" aria-hidden="true" />
        <span>Restablecer</span>
      </button>

      <button type="submit" class="btn btn-primary" :disabled="guardando">
        <span v-if="guardando" class="spinner-border spinner-border-sm" aria-hidden="true"></span>
        <Save v-else :size="16" aria-hidden="true" />
        <span>{{ guardando ? 'Guardando cambios…' : 'Guardar datos de la sede' }}</span>
      </button>
    </footer>
  </form>
</template>

<style scoped>
.perfil-form {
  padding: 1.75rem;
  border-radius: var(--gb-radius-xl);
  border: 1px solid var(--gb-border);
  background-color: var(--gb-surface);
}

.perfil-form__cabecera {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding-bottom: 1.25rem;
  margin-bottom: 1.5rem;
  border-bottom: 1px solid var(--gb-border);
}

.perfil-form__icono-cabecera {
  display: grid;
  place-items: center;
  width: 2.75rem;
  height: 2.75rem;
  border-radius: var(--gb-radius-lg);
  background-color: rgba(225, 29, 20, 0.12);
  color: var(--gb-red);
  flex-shrink: 0;
}

.perfil-form__titulo {
  margin: 0;
  font-size: var(--gb-tipo-lg);
  font-weight: 800;
  text-transform: uppercase;
  color: var(--gb-text);
}

.perfil-form__descripcion {
  margin: 0.25rem 0 0;
  font-size: var(--gb-tipo-xs);
  color: var(--gb-text-muted);
}

.perfil-form__rejilla {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 1.25rem;
}

.campo--completo {
  grid-column: 1 / -1;
}

.input-icono-wrapper {
  position: relative;
}

.input-icono {
  position: absolute;
  top: 50%;
  left: 0.875rem;
  color: var(--gb-text-muted);
  transform: translateY(-50%);
  pointer-events: none;
}

.form-control--con-icono {
  padding-left: 2.5rem;
}

.campo__error {
  margin-top: 0.35rem;
  color: var(--gb-error);
  font-size: var(--gb-tipo-xs);
}

.campo__ayuda {
  display: flex;
  align-items: center;
  gap: 0.35rem;
  margin-top: 0.35rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
}

.perfil-form__acciones {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 0.75rem;
  margin-top: 1.75rem;
  padding-top: 1.25rem;
  border-top: 1px solid var(--gb-border);
}

.perfil-form__acciones .btn {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
}

@media (max-width: 48rem) {
  .perfil-form {
    padding: 1.25rem;
  }

  .perfil-form__rejilla {
    grid-template-columns: 1fr;
  }

  .perfil-form__acciones {
    flex-direction: column-reverse;
  }

  .perfil-form__acciones .btn {
    width: 100%;
    justify-content: center;
  }
}
</style>
