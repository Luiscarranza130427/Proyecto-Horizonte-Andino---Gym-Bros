<script setup>
import { Bell, CreditCard, Globe, Mail, Save, ShieldAlert, Sliders } from 'lucide-vue-next'
import { reactive, watch } from 'vue'

const props = defineProps({
  preferencias: {
    type: Object,
    default: () => ({
      idioma: 'es',
      tema: 'oscuro',
      notifEmail: true,
      notifPush: true,
      notifPagos: true,
      notifSeguridad: true,
    }),
  },
  guardando: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits(['guardar'])

const formulario = reactive({
  idioma: 'es',
  tema: 'oscuro',
  notifEmail: true,
  notifPush: true,
  notifPagos: true,
  notifSeguridad: true,
})

function sincronizar() {
  if (!props.preferencias) return
  formulario.idioma = props.preferencias.idioma || 'es'
  formulario.tema = props.preferencias.tema || 'oscuro'
  formulario.notifEmail = props.preferencias.notifEmail !== false
  formulario.notifPush = props.preferencias.notifPush !== false
  formulario.notifPagos = props.preferencias.notifPagos !== false
  formulario.notifSeguridad = props.preferencias.notifSeguridad !== false
}

watch(() => props.preferencias, sincronizar, { immediate: true })

function enviar() {
  emit('guardar', { ...formulario })
}
</script>

<template>
  <form class="perfil-pref gb-tarjeta" novalidate @submit.prevent="enviar">
    <header class="perfil-pref__cabecera">
      <div class="perfil-pref__icono-cabecera" aria-hidden="true">
        <Sliders :size="20" />
      </div>
      <div>
        <h2 class="perfil-pref__titulo">Preferencias del Sistema</h2>
        <p class="perfil-pref__descripcion">
          Personaliza tu experiencia de navegación, alertas y canales de notificación.
        </p>
      </div>
    </header>

    <div class="perfil-pref__secciones">
      <!-- Ajustes generales -->
      <fieldset class="perfil-pref__grupo">
        <legend class="perfil-pref__grupo-titulo">
          <Globe :size="16" aria-hidden="true" />
          <span>Configuración Regional</span>
        </legend>

        <div class="perfil-pref__grid-campos">
          <div class="campo">
            <label class="form-label" for="pref-idioma">Idioma de la interfaz</label>
            <select id="pref-idioma" v-model="formulario.idioma" class="form-select">
              <option value="es">Español (Latinoamérica)</option>
              <option value="en" disabled>English (Próximamente)</option>
            </select>
          </div>

          <div class="campo">
            <label class="form-label" for="pref-tema">Tema visual</label>
            <select id="pref-tema" v-model="formulario.tema" class="form-select">
              <option value="oscuro">Gym Bros Dark (Predeterminado)</option>
            </select>
          </div>
        </div>
      </fieldset>

      <!-- Notificaciones -->
      <fieldset class="perfil-pref__grupo">
        <legend class="perfil-pref__grupo-titulo">
          <Bell :size="16" aria-hidden="true" />
          <span>Canales y Notificaciones</span>
        </legend>

        <div class="perfil-pref__toggles">
          <!-- Notificaciones por Email -->
          <label class="pref-toggle">
            <input v-model="formulario.notifEmail" type="checkbox" class="form-check-input" />
            <div class="pref-toggle__info">
              <div class="pref-toggle__titulo">
                <Mail :size="16" aria-hidden="true" />
                <span>Notificaciones por correo electrónico</span>
              </div>
              <p class="pref-toggle__desc">
                Recibe resúmenes semanales de actividad y novedades del SaaS.
              </p>
            </div>
          </label>

          <!-- Notificaciones Push -->
          <label class="pref-toggle">
            <input v-model="formulario.notifPush" type="checkbox" class="form-check-input" />
            <div class="pref-toggle__info">
              <div class="pref-toggle__titulo">
                <Bell :size="16" aria-hidden="true" />
                <span>Alertas en tiempo real (Push)</span>
              </div>
              <p class="pref-toggle__desc">
                Avisos instantáneos cuando un cliente registre un pago o ingrese al gimnasio.
              </p>
            </div>
          </label>

          <!-- Notificaciones de Pagos -->
          <label class="pref-toggle">
            <input v-model="formulario.notifPagos" type="checkbox" class="form-check-input" />
            <div class="pref-toggle__info">
              <div class="pref-toggle__titulo">
                <CreditCard :size="16" aria-hidden="true" />
                <span>Alertas financieras y facturación</span>
              </div>
              <p class="pref-toggle__desc">
                Reportes automáticos de vencimiento de planes y cierres de caja.
              </p>
            </div>
          </label>

          <!-- Notificaciones de Seguridad -->
          <label class="pref-toggle">
            <input v-model="formulario.notifSeguridad" type="checkbox" class="form-check-input" />
            <div class="pref-toggle__info">
              <div class="pref-toggle__titulo">
                <ShieldAlert :size="16" aria-hidden="true" />
                <span>Alertas críticas de seguridad</span>
              </div>
              <p class="pref-toggle__desc">
                Notificación inmediata de inicios de sesión sospechosos o cambios de clave.
              </p>
            </div>
          </label>
        </div>
      </fieldset>
    </div>

    <!-- Botonera -->
    <footer class="perfil-pref__acciones">
      <button type="submit" class="btn btn-primary" :disabled="guardando">
        <span v-if="guardando" class="spinner-border spinner-border-sm" aria-hidden="true"></span>
        <Save v-else :size="16" aria-hidden="true" />
        <span>{{ guardando ? 'Guardando…' : 'Guardar preferencias' }}</span>
      </button>
    </footer>
  </form>
</template>

<style scoped>
.perfil-pref {
  padding: 1.75rem;
  border-radius: var(--gb-radius-xl);
  border: 1px solid var(--gb-border);
  background-color: var(--gb-surface);
}

.perfil-pref__cabecera {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding-bottom: 1.25rem;
  margin-bottom: 1.5rem;
  border-bottom: 1px solid var(--gb-border);
}

.perfil-pref__icono-cabecera {
  display: grid;
  place-items: center;
  width: 2.75rem;
  height: 2.75rem;
  border-radius: var(--gb-radius-lg);
  background-color: rgba(168, 85, 247, 0.12);
  color: var(--gb-purple, #a855f7);
  flex-shrink: 0;
}

.perfil-pref__titulo {
  margin: 0;
  font-size: var(--gb-tipo-lg);
  font-weight: 800;
  text-transform: uppercase;
  color: var(--gb-text);
}

.perfil-pref__descripcion {
  margin: 0.25rem 0 0;
  font-size: var(--gb-tipo-xs);
  color: var(--gb-text-muted);
}

.perfil-pref__secciones {
  display: grid;
  gap: 1.5rem;
}

.perfil-pref__grupo {
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
  padding: 1.25rem;
  background-color: var(--gb-surface-high);
}

.perfil-pref__grupo-titulo {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0 0.5rem;
  font-size: var(--gb-tipo-xs);
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--gb-text-soft);
}

.perfil-pref__grid-campos {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(15rem, 1fr));
  gap: 1rem;
  margin-top: 0.75rem;
}

.perfil-pref__toggles {
  display: grid;
  gap: 1rem;
  margin-top: 0.75rem;
}

.pref-toggle {
  display: flex;
  align-items: flex-start;
  gap: 0.85rem;
  padding: 0.85rem 1rem;
  border-radius: var(--gb-radius-md);
  background-color: var(--gb-surface);
  border: 1px solid var(--gb-border);
  cursor: pointer;
  transition: border-color 0.2s ease;
}

.pref-toggle:hover {
  border-color: var(--gb-border-focus, #555555);
}

.pref-toggle input {
  margin-top: 0.2rem;
  flex-shrink: 0;
  width: 1.15rem;
  height: 1.15rem;
  accent-color: var(--gb-red);
  cursor: pointer;
}

.pref-toggle__info {
  min-width: 0;
}

.pref-toggle__titulo {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  font-size: var(--gb-tipo-sm);
  font-weight: 700;
  color: var(--gb-text);
}

.pref-toggle__desc {
  margin: 0.2rem 0 0;
  font-size: var(--gb-tipo-xs);
  color: var(--gb-text-muted);
}

.perfil-pref__acciones {
  display: flex;
  justify-content: flex-end;
  margin-top: 1.75rem;
  padding-top: 1.25rem;
  border-top: 1px solid var(--gb-border);
}

.perfil-pref__acciones .btn {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
}

@media (max-width: 48rem) {
  .perfil-pref {
    padding: 1.25rem;
  }

  .perfil-pref__acciones .btn {
    width: 100%;
    justify-content: center;
  }
}
</style>
