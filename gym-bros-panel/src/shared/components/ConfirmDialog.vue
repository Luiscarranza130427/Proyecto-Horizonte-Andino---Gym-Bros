<script setup>
import { AlertTriangle } from 'lucide-vue-next'
import { computed, nextTick, ref, watch } from 'vue'

const props = defineProps({
  abierto: { type: Boolean, default: false },
  titulo: { type: String, required: true },
  mensaje: { type: String, default: '' },
  descripcion: { type: String, default: '' },
  etiquetaConfirmar: { type: String, default: 'Confirmar' },
  etiquetaConfirmando: { type: String, default: 'Confirmando…' },
  etiquetaCancelar: { type: String, default: 'Cancelar' },
  tono: {
    type: String,
    default: 'peligro',
    validator: (v) => ['peligro', 'aviso', 'neutro'].includes(v),
  },
  cargando: { type: Boolean, default: false },
  confirmando: { type: Boolean, default: false },
})

const emit = defineEmits(['confirmar', 'cancelar'])

const botonCancelar = ref(null)
const textoMensaje = computed(() => props.mensaje || props.descripcion || '')
const estaCargando = computed(() => props.cargando || props.confirmando || false)
const textoConfirmacion = computed(() =>
  estaCargando.value ? props.etiquetaConfirmando : props.etiquetaConfirmar,
)

watch(
  () => props.abierto,
  async (abierto) => {
    if (abierto) {
      await nextTick()
      botonCancelar.value?.focus()
    }
  },
)

function alPulsarTecla(e) {
  if (e.key === 'Escape' && props.abierto && !estaCargando.value) {
    emit('cancelar')
  }
}
</script>

<template>
  <Teleport to="body">
    <div
      v-if="abierto"
      class="gb-confirm-dialog-telon"
      role="alertdialog"
      aria-modal="true"
      :aria-labelledby="'confirm-dialog-titulo'"
      :aria-describedby="'confirm-dialog-mensaje'"
      @keydown="alPulsarTecla"
    >
      <div class="gb-confirm-dialog gb-tarjeta" :class="`gb-confirm-dialog--${tono}`">
        <div class="gb-confirm-dialog__icono-contenedor">
          <AlertTriangle :size="24" class="gb-confirm-dialog__icono" aria-hidden="true" />
        </div>

        <div class="gb-confirm-dialog__cuerpo">
          <h2 id="confirm-dialog-titulo" class="gb-confirm-dialog__titulo">{{ titulo }}</h2>
          <p id="confirm-dialog-mensaje" class="gb-confirm-dialog__mensaje">{{ textoMensaje }}</p>
        </div>

        <div class="gb-confirm-dialog__acciones dialogo__acciones">
          <button
            ref="botonCancelar"
            type="button"
            class="btn btn-ghost"
            :disabled="estaCargando"
            @click="emit('cancelar')"
          >
            {{ etiquetaCancelar }}
          </button>
          <button
            type="button"
            class="btn"
            :class="tono === 'peligro' ? 'btn-primary btn-danger' : 'btn-secondary'"
            :disabled="estaCargando"
            @click="emit('confirmar')"
          >
            <span
              v-if="estaCargando"
              class="spinner-border spinner-border-sm"
              aria-hidden="true"
            ></span>
            <span>{{ textoConfirmacion }}</span>
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<style scoped>
.gb-confirm-dialog-telon {
  position: fixed;
  inset: 0;
  z-index: 1050;
  display: grid;
  place-items: center;
  padding: 1rem;
  background-color: rgba(0, 0, 0, 0.7);
  backdrop-filter: blur(4px);
}

.gb-confirm-dialog {
  width: min(100%, 28rem);
  padding: 1.5rem;
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-xl);
  box-shadow: var(--gb-sombra-elevada);
}

.gb-confirm-dialog__icono-contenedor {
  display: grid;
  place-items: center;
  width: 3rem;
  height: 3rem;
  margin-bottom: 1rem;
  border-radius: var(--gb-radius-full);
}

.gb-confirm-dialog--peligro .gb-confirm-dialog__icono-contenedor {
  background-color: rgba(220, 38, 38, 0.15);
  color: var(--gb-red);
}

.gb-confirm-dialog--aviso .gb-confirm-dialog__icono-contenedor {
  background-color: rgba(234, 179, 8, 0.15);
  color: var(--gb-yellow);
}

.gb-confirm-dialog--neutro .gb-confirm-dialog__icono-contenedor {
  background-color: var(--gb-surface-highest);
  color: var(--gb-text-soft);
}

.gb-confirm-dialog__titulo {
  margin: 0 0 0.5rem;
  font-size: var(--gb-tipo-lg);
  font-weight: 800;
  text-transform: uppercase;
}

.gb-confirm-dialog__mensaje {
  margin: 0 0 1.5rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
  line-height: 1.5;
}

.gb-confirm-dialog__acciones {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
}

.gb-confirm-dialog__acciones .btn {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
}

@media (max-width: 28rem) {
  .gb-confirm-dialog {
    padding: 1.25rem;
  }

  .gb-confirm-dialog__acciones {
    flex-direction: column-reverse;
  }

  .gb-confirm-dialog__acciones .btn {
    width: 100%;
    justify-content: center;
  }
}
</style>
