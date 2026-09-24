<script setup>
import {
  CheckCircle2,
  Eye,
  EyeOff,
  KeyRound,
  Laptop,
  Lock,
  LogOut,
  Shield,
  Smartphone,
} from 'lucide-vue-next'
import { computed, reactive, ref } from 'vue'

defineProps({
  sesiones: {
    type: Array,
    default: () => [],
  },
  cambiandoClave: {
    type: Boolean,
    default: false,
  },
  cerrandoSesiones: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits(['cambiar-clave', 'cerrar-otras-sesiones'])

const formulario = reactive({
  actual: '',
  nueva: '',
  confirmacion: '',
})

const mostrarActual = ref(false)
const mostrarNueva = ref(false)
const mostrarConfirmacion = ref(false)
const errores = reactive({})

const fortaleza = computed(() => {
  const clave = formulario.nueva
  if (!clave) return { nivel: 0, texto: 'Ingresa una contraseña', color: 'transparent' }
  if (clave.length < 6) return { nivel: 1, texto: 'Demasiado corta', color: 'var(--gb-error)' }

  let puntos = 0
  if (clave.length >= 8) puntos++
  if (/[A-Z]/.test(clave)) puntos++
  if (/[0-9]/.test(clave)) puntos++
  if (/[^A-Za-z0-9]/.test(clave)) puntos++

  if (puntos <= 1) return { nivel: 2, texto: 'Débil', color: 'var(--gb-error)' }
  if (puntos <= 3) return { nivel: 3, texto: 'Media', color: 'var(--gb-amber, #f59e0b)' }
  return { nivel: 4, texto: 'Excelente y segura', color: 'var(--gb-green)' }
})

function limpiarErrores() {
  Object.keys(errores).forEach((k) => delete errores[k])
}

function validar() {
  limpiarErrores()
  let valido = true

  if (!formulario.actual) {
    errores.actual = 'Ingresa tu contraseña actual.'
    valido = false
  }

  if (!formulario.nueva) {
    errores.nueva = 'Ingresa la nueva contraseña.'
    valido = false
  } else if (formulario.nueva.length < 6) {
    errores.nueva = 'La contraseña debe tener al menos 6 caracteres.'
    valido = false
  }

  if (!formulario.confirmacion) {
    errores.confirmacion = 'Confirma tu nueva contraseña.'
    valido = false
  } else if (formulario.nueva !== formulario.confirmacion) {
    errores.confirmacion = 'Las contraseñas no coinciden.'
    valido = false
  }

  return valido
}

function enviarClave() {
  if (!validar()) return
  emit('cambiar-clave', { ...formulario })
  formulario.actual = ''
  formulario.nueva = ''
  formulario.confirmacion = ''
}
</script>

<template>
  <div class="perfil-seguridad">
    <!-- Formulario de cambio de contraseña -->
    <form class="gb-tarjeta seguridad-card" novalidate @submit.prevent="enviarClave">
      <header class="seguridad-card__cabecera">
        <div class="seguridad-card__icono-cabecera" aria-hidden="true">
          <KeyRound :size="20" />
        </div>
        <div>
          <h2 class="seguridad-card__titulo">Cambiar Contraseña</h2>
          <p class="seguridad-card__descripcion">
            Protege tu cuenta actualizando tu contraseña periódicamente.
          </p>
        </div>
      </header>

      <div class="seguridad-card__campos">
        <!-- Contraseña actual -->
        <div class="campo">
          <label class="form-label" for="seguridad-actual">Contraseña actual *</label>
          <div class="seguridad-card__input-wrap">
            <input
              id="seguridad-actual"
              v-model="formulario.actual"
              :type="mostrarActual ? 'text' : 'password'"
              class="form-control"
              :class="{ 'is-invalid': errores.actual }"
              placeholder="••••••••"
              required
              :aria-invalid="Boolean(errores.actual)"
              :aria-describedby="errores.actual ? 'error-seguridad-actual' : null"
              @input="delete errores.actual"
            />
            <button
              type="button"
              class="btn btn-ghost btn-sm btn-ojo"
              :title="mostrarActual ? 'Ocultar contraseña' : 'Ver contraseña'"
              :aria-label="mostrarActual ? 'Ocultar contraseña' : 'Ver contraseña'"
              @click="mostrarActual = !mostrarActual"
            >
              <component :is="mostrarActual ? EyeOff : Eye" :size="16" aria-hidden="true" />
            </button>
          </div>
          <p v-if="errores.actual" id="error-seguridad-actual" class="campo__error">
            {{ errores.actual }}
          </p>
        </div>

        <!-- Nueva contraseña -->
        <div class="campo">
          <label class="form-label" for="seguridad-nueva">Nueva contraseña *</label>
          <div class="seguridad-card__input-wrap">
            <input
              id="seguridad-nueva"
              v-model="formulario.nueva"
              :type="mostrarNueva ? 'text' : 'password'"
              class="form-control"
              :class="{ 'is-invalid': errores.nueva }"
              placeholder="Mínimo 6 caracteres"
              required
              :aria-invalid="Boolean(errores.nueva)"
              :aria-describedby="errores.nueva ? 'error-seguridad-nueva' : null"
              @input="delete errores.nueva"
            />
            <button
              type="button"
              class="btn btn-ghost btn-sm btn-ojo"
              :title="mostrarNueva ? 'Ocultar contraseña' : 'Ver contraseña'"
              :aria-label="mostrarNueva ? 'Ocultar contraseña' : 'Ver contraseña'"
              @click="mostrarNueva = !mostrarNueva"
            >
              <component :is="mostrarNueva ? EyeOff : Eye" :size="16" aria-hidden="true" />
            </button>
          </div>

          <!-- Medidor de fortaleza -->
          <div v-if="formulario.nueva" class="fortaleza-indicador">
            <div class="fortaleza-barra">
              <div
                class="fortaleza-progreso"
                :style="{
                  width: `${(fortaleza.nivel / 4) * 100}%`,
                  backgroundColor: fortaleza.color,
                }"
              ></div>
            </div>
            <span class="fortaleza-texto" :style="{ color: fortaleza.color }">
              {{ fortaleza.texto }}
            </span>
          </div>

          <p v-if="errores.nueva" id="error-seguridad-nueva" class="campo__error">
            {{ errores.nueva }}
          </p>
        </div>

        <!-- Confirmar nueva contraseña -->
        <div class="campo">
          <label class="form-label" for="seguridad-confirmacion"
            >Confirmar nueva contraseña *</label
          >
          <div class="seguridad-card__input-wrap">
            <input
              id="seguridad-confirmacion"
              v-model="formulario.confirmacion"
              :type="mostrarConfirmacion ? 'text' : 'password'"
              class="form-control"
              :class="{ 'is-invalid': errores.confirmacion }"
              placeholder="Repite la nueva contraseña"
              required
              :aria-invalid="Boolean(errores.confirmacion)"
              :aria-describedby="errores.confirmacion ? 'error-seguridad-confirmacion' : null"
              @input="delete errores.confirmacion"
            />
            <button
              type="button"
              class="btn btn-ghost btn-sm btn-ojo"
              :title="mostrarConfirmacion ? 'Ocultar contraseña' : 'Ver contraseña'"
              :aria-label="mostrarConfirmacion ? 'Ocultar contraseña' : 'Ver contraseña'"
              @click="mostrarConfirmacion = !mostrarConfirmacion"
            >
              <component :is="mostrarConfirmacion ? EyeOff : Eye" :size="16" aria-hidden="true" />
            </button>
          </div>
          <p v-if="errores.confirmacion" id="error-seguridad-confirmacion" class="campo__error">
            {{ errores.confirmacion }}
          </p>
        </div>
      </div>

      <footer class="seguridad-card__acciones">
        <button type="submit" class="btn btn-primary" :disabled="cambiandoClave">
          <span
            v-if="cambiandoClave"
            class="spinner-border spinner-border-sm"
            aria-hidden="true"
          ></span>
          <Lock v-else :size="16" aria-hidden="true" />
          <span>{{ cambiandoClave ? 'Actualizando contraseña…' : 'Actualizar contraseña' }}</span>
        </button>
      </footer>
    </form>

    <!-- Dispositivos y sesiones activas -->
    <section class="gb-tarjeta seguridad-card" aria-label="Sesiones activas">
      <header class="seguridad-card__cabecera">
        <div
          class="seguridad-card__icono-cabecera seguridad-card__icono-cabecera--azul"
          aria-hidden="true"
        >
          <Shield :size="20" />
        </div>
        <div class="seguridad-card__cabecera-texto">
          <div>
            <h2 class="seguridad-card__titulo">Dispositivos y Sesiones Activas</h2>
            <p class="seguridad-card__descripcion">
              Revisa los dispositivos con sesión iniciada en tu cuenta.
            </p>
          </div>
          <button
            v-if="sesiones.length > 1"
            type="button"
            class="btn btn-secondary btn-sm btn-cerrar-sesiones"
            :disabled="cerrandoSesiones"
            @click="emit('cerrar-otras-sesiones')"
          >
            <LogOut :size="14" aria-hidden="true" />
            <span>{{ cerrandoSesiones ? 'Cerrando…' : 'Cerrar otras sesiones' }}</span>
          </button>
        </div>
      </header>

      <div class="sesiones-lista">
        <article
          v-for="sesion in sesiones"
          :key="sesion.id"
          class="sesion-item"
          :class="{ 'sesion-item--actual': sesion.esActual }"
        >
          <div class="sesion-item__icono" aria-hidden="true">
            <component
              :is="
                sesion.dispositivo.includes('Móvil') || sesion.dispositivo.includes('iOS')
                  ? Smartphone
                  : Laptop
              "
              :size="20"
            />
          </div>

          <div class="sesion-item__detalles">
            <div class="sesion-item__nombre-fila">
              <h3 class="sesion-item__nombre">{{ sesion.dispositivo }}</h3>
              <span v-if="sesion.esActual" class="badge-sesion-actual">
                <CheckCircle2 :size="12" aria-hidden="true" /> Esta sesión
              </span>
            </div>
            <p class="sesion-item__meta">
              <span>{{ sesion.ubicacion }}</span>
              <span>· IP: {{ sesion.ip }}</span>
              <span>· {{ sesion.ultimoAcceso }}</span>
            </p>
          </div>
        </article>
      </div>
    </section>
  </div>
</template>

<style scoped>
.perfil-seguridad {
  display: grid;
  gap: 1.5rem;
}

.seguridad-card {
  padding: 1.75rem;
  border-radius: var(--gb-radius-xl);
  border: 1px solid var(--gb-border);
  background-color: var(--gb-surface);
}

.seguridad-card__cabecera {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding-bottom: 1.25rem;
  margin-bottom: 1.5rem;
  border-bottom: 1px solid var(--gb-border);
}

.seguridad-card__cabecera-texto {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  flex: 1;
}

.seguridad-card__icono-cabecera {
  display: grid;
  place-items: center;
  width: 2.75rem;
  height: 2.75rem;
  border-radius: var(--gb-radius-lg);
  background-color: rgba(225, 29, 20, 0.12);
  color: var(--gb-red);
  flex-shrink: 0;
}

.seguridad-card__icono-cabecera--azul {
  background-color: rgba(14, 165, 233, 0.12);
  color: var(--gb-sky, #0ea5e9);
}

.seguridad-card__titulo {
  margin: 0;
  font-size: var(--gb-tipo-lg);
  font-weight: 800;
  text-transform: uppercase;
  color: var(--gb-text);
}

.seguridad-card__descripcion {
  margin: 0.25rem 0 0;
  font-size: var(--gb-tipo-xs);
  color: var(--gb-text-muted);
}

.seguridad-card__campos {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(16rem, 1fr));
  gap: 1.25rem;
}

.seguridad-card__input-wrap {
  position: relative;
  display: flex;
  align-items: center;
}

.seguridad-card__input-wrap .form-control {
  padding-right: 2.5rem;
}

.btn-ojo {
  position: absolute;
  right: 0.35rem;
  padding: 0.35rem;
  color: var(--gb-text-muted);
}

.fortaleza-indicador {
  display: grid;
  gap: 0.25rem;
  margin-top: 0.4rem;
}

.fortaleza-barra {
  height: 0.3rem;
  background-color: var(--gb-surface-highest);
  border-radius: var(--gb-radius-pill);
  overflow: hidden;
}

.fortaleza-progreso {
  height: 100%;
  transition:
    width 0.3s ease,
    background-color 0.3s ease;
}

.fortaleza-texto {
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.campo__error {
  margin-top: 0.35rem;
  color: var(--gb-error);
  font-size: var(--gb-tipo-xs);
}

.seguridad-card__acciones {
  display: flex;
  justify-content: flex-end;
  margin-top: 1.75rem;
  padding-top: 1.25rem;
  border-top: 1px solid var(--gb-border);
}

.seguridad-card__acciones .btn {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
}

/* Sesiones activas */
.sesiones-lista {
  display: grid;
  gap: 0.85rem;
}

.sesion-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem 1.25rem;
  border-radius: var(--gb-radius-lg);
  border: 1px solid var(--gb-border);
  background-color: var(--gb-surface-high);
}

.sesion-item--actual {
  border-color: rgba(34, 197, 94, 0.35);
  background: linear-gradient(90deg, rgba(34, 197, 94, 0.05) 0%, var(--gb-surface-high) 100%);
}

.sesion-item__icono {
  display: grid;
  place-items: center;
  width: 2.5rem;
  height: 2.5rem;
  border-radius: var(--gb-radius-md);
  background-color: var(--gb-surface-highest);
  color: var(--gb-text-soft);
  flex-shrink: 0;
}

.sesion-item--actual .sesion-item__icono {
  background-color: rgba(34, 197, 94, 0.15);
  color: #22c55e;
}

.sesion-item__detalles {
  min-width: 0;
  flex: 1;
}

.sesion-item__nombre-fila {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.sesion-item__nombre {
  margin: 0;
  font-size: var(--gb-tipo-sm);
  font-weight: 700;
  color: var(--gb-text);
}

.badge-sesion-actual {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.15rem 0.5rem;
  border-radius: var(--gb-radius-pill);
  background-color: rgba(34, 197, 94, 0.15);
  border: 1px solid rgba(34, 197, 94, 0.3);
  color: #22c55e;
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  text-transform: uppercase;
}

.sesion-item__meta {
  margin: 0.25rem 0 0;
  font-size: var(--gb-tipo-xs);
  color: var(--gb-text-muted);
}

@media (max-width: 48rem) {
  .seguridad-card {
    padding: 1.25rem;
  }

  .seguridad-card__cabecera-texto {
    flex-direction: column;
    align-items: flex-start;
  }

  .btn-cerrar-sesiones {
    width: 100%;
    justify-content: center;
  }

  .seguridad-card__acciones .btn {
    width: 100%;
    justify-content: center;
  }

  .sesion-item {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>
