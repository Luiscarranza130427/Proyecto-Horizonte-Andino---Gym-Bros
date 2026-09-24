<script setup>
import { Eye, User } from 'lucide-vue-next'
import { computed } from 'vue'

import { obtenerMetadatosTipo } from '@/modules/notificaciones/catalogos'

const props = defineProps({
  titulo: { type: String, default: '' },
  mensaje: { type: String, default: '' },
  tipo: { type: String, default: 'otro' },
  destinatarioTexto: { type: String, default: 'Todos los usuarios' },
  programar: { type: Boolean, default: false },
  fechaEnvio: { type: String, default: '' },
  nombreRemitente: { type: String, default: 'GYM BROS' },
})

const metaTipo = computed(() => obtenerMetadatosTipo(props.tipo))
</script>

<template>
  <aside class="notificacion-preview" aria-label="Vista previa en tiempo real">
    <div class="notificacion-preview__cabecera">
      <span class="notificacion-preview__icono-ojo" aria-hidden="true">
        <Eye :size="18" />
      </span>
      <div>
        <h4>Vista previa en vivo</h4>
        <p>Así recibirán la notificación los usuarios en sus dispositivos.</p>
      </div>
    </div>

    <div class="notificacion-preview__mockup">
      <!-- Tarjeta simulada de notificación móvil -->
      <div class="push-card">
        <header class="push-card__header">
          <div class="push-card__app">
            <span class="push-card__icono-app" :style="{ backgroundColor: metaTipo.color }">
              <component :is="metaTipo.icono" :size="12" aria-hidden="true" />
            </span>
            <span class="push-card__nombre-app">{{ nombreRemitente }}</span>
            <span class="push-card__punto">•</span>
            <span class="push-card__tiempo">
              {{ programar && fechaEnvio ? 'Programada' : 'Ahora' }}
            </span>
          </div>

          <span
            class="push-card__tipo-tag"
            :style="{ color: metaTipo.color, backgroundColor: metaTipo.colorFondo }"
          >
            {{ metaTipo.etiqueta }}
          </span>
        </header>

        <div class="push-card__cuerpo">
          <strong class="push-card__titulo">
            {{ titulo.trim() || 'Título de la notificación…' }}
          </strong>
          <p class="push-card__mensaje">
            {{ mensaje.trim() || 'Escribe un mensaje para previsualizar el contenido aquí…' }}
          </p>
        </div>

        <footer class="push-card__footer">
          <span class="push-card__destinatario">
            <User :size="12" aria-hidden="true" />
            <span>{{ destinatarioTexto }}</span>
          </span>
          <span class="push-card__accion-falsa">Desliza para ver</span>
        </footer>
      </div>
    </div>
  </aside>
</template>

<style scoped>
.notificacion-preview {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  padding: 1.5rem;
  background-color: var(--gb-surface);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-xl);
  height: fit-content;
}

.notificacion-preview__cabecera {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.notificacion-preview__icono-ojo {
  display: grid;
  place-items: center;
  width: 2.25rem;
  height: 2.25rem;
  background-color: var(--gb-surface-high);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
  color: var(--gb-text-soft);
  font-size: 1rem;
  flex-shrink: 0;
}

.notificacion-preview__cabecera h4 {
  margin: 0;
  font-size: var(--gb-tipo-sm);
  text-transform: uppercase;
  color: var(--gb-text);
}

.notificacion-preview__cabecera p {
  margin: 0.125rem 0 0;
  font-size: var(--gb-tipo-xs);
  color: var(--gb-text-muted);
}

.notificacion-preview__mockup {
  padding: 1.25rem;
  background:
    radial-gradient(circle at top, rgba(229, 9, 20, 0.08), transparent 70%),
    var(--gb-surface-lowest);
  border: 1px dashed var(--gb-border);
  border-radius: var(--gb-radius-lg);
}

/* Tarjeta push móvil */
.push-card {
  display: flex;
  flex-direction: column;
  gap: 0.625rem;
  padding: 1rem;
  background-color: rgba(35, 35, 35, 0.95);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: var(--gb-radius-lg);
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.5);
  animation: pushAparecer 0.2s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes pushAparecer {
  from {
    opacity: 0.7;
    transform: translateY(4px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.push-card__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.5rem;
}

.push-card__app {
  display: flex;
  align-items: center;
  gap: 0.375rem;
}

.push-card__icono-app {
  display: grid;
  place-items: center;
  width: 1.25rem;
  height: 1.25rem;
  border-radius: var(--gb-radius-sm);
  color: #000000;
  font-size: 0.75rem;
}

.push-card__nombre-app {
  font-family: var(--gb-fuente-titulo);
  font-size: 0.6875rem;
  font-weight: 800;
  letter-spacing: 0.05em;
  color: var(--gb-text);
}

.push-card__punto,
.push-card__tiempo {
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
}

.push-card__tipo-tag {
  padding: 0.15rem 0.45rem;
  border-radius: var(--gb-radius-pill);
  font-size: 0.625rem;
  font-weight: 700;
  text-transform: uppercase;
}

.push-card__cuerpo {
  display: grid;
  gap: 0.25rem;
}

.push-card__titulo {
  font-size: var(--gb-tipo-sm);
  font-weight: 700;
  color: #ffffff;
  line-height: 1.3;
  word-break: break-word;
}

.push-card__mensaje {
  margin: 0;
  font-size: var(--gb-tipo-xs);
  color: var(--gb-text-muted);
  line-height: 1.45;
  white-space: pre-wrap;
  word-break: break-word;
}

.push-card__footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.5rem;
  padding-top: 0.5rem;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
}

.push-card__destinatario {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  color: var(--gb-text-soft);
  font-size: 0.6875rem;
}

.push-card__accion-falsa {
  color: var(--gb-text-muted);
  font-size: 0.625rem;
  font-style: italic;
}
</style>
