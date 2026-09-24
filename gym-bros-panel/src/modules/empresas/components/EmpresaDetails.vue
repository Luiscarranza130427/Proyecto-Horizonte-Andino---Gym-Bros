<script setup>
import { Clock3, ExternalLink } from 'lucide-vue-next'
import { computed } from 'vue'

import EmpresaLogo from '@/modules/empresas/components/EmpresaLogo.vue'
import EmpresaStatusBadge from '@/modules/empresas/components/EmpresaStatusBadge.vue'
import { formatearFecha, formatearNumero } from '@/shared/utils/formato'

const props = defineProps({
  empresa: { type: Object, required: true },
})

const DIAS = [
  { valor: 'lunes', etiqueta: 'Lunes' },
  { valor: 'martes', etiqueta: 'Martes' },
  { valor: 'miercoles', etiqueta: 'Miércoles' },
  { valor: 'jueves', etiqueta: 'Jueves' },
  { valor: 'viernes', etiqueta: 'Viernes' },
  { valor: 'sabado', etiqueta: 'Sábado' },
  { valor: 'domingo', etiqueta: 'Domingo' },
]

const sitioSeguro = computed(() => {
  try {
    const url = new URL(props.empresa.sitioWeb)
    return ['http:', 'https:'].includes(url.protocol) ? url.href : ''
  } catch {
    return ''
  }
})
</script>

<template>
  <div class="detalle">
    <section class="detalle__resumen gb-tarjeta">
      <EmpresaLogo :nombre="empresa.nombre" :url="empresa.logoUrl" grande />
      <div>
        <p>Empresa registrada</p>
        <h2>{{ empresa.nombre }}</h2>
        <span>{{ empresa.region || 'Región no especificada' }}</span>
      </div>
      <EmpresaStatusBadge :estado="empresa.estado" />
    </section>

    <div class="detalle__rejilla">
      <section
        class="detalle__panel detalle__panel--principal gb-tarjeta"
        aria-labelledby="titulo-contacto"
      >
        <header>
          <p>Datos administrativos</p>
          <h2 id="titulo-contacto">Información y contacto</h2>
        </header>
        <dl>
          <div>
            <dt>Gerente</dt>
            <dd>{{ empresa.gerente || 'No especificado' }}</dd>
          </div>
          <div>
            <dt>RUC</dt>
            <dd class="tabular">{{ empresa.ruc || 'No especificado' }}</dd>
          </div>
          <div>
            <dt>Correo</dt>
            <dd>
              <a :href="`mailto:${empresa.correo}`">{{ empresa.correo }}</a>
            </dd>
          </div>
          <div>
            <dt>Teléfono</dt>
            <dd>
              <a :href="`tel:${empresa.telefono}`">{{ empresa.telefono }}</a>
            </dd>
          </div>
          <div class="detalle__completo">
            <dt>Región</dt>
            <dd>{{ empresa.region || 'No especificada' }}</dd>
          </div>
          <div class="detalle__completo">
            <dt>Dirección</dt>
            <dd>{{ empresa.direccion || 'No especificada' }}</dd>
          </div>
          <div class="detalle__completo">
            <dt>Sitio web</dt>
            <dd>
              <a v-if="sitioSeguro" :href="sitioSeguro" target="_blank" rel="noopener noreferrer">
                {{ empresa.sitioWeb }} <ExternalLink :size="14" aria-hidden="true" />
              </a>
              <span v-else>{{ empresa.sitioWeb || 'No especificado' }}</span>
            </dd>
          </div>
        </dl>
      </section>

      <aside class="detalle__lateral">
        <section class="detalle__panel gb-tarjeta" aria-labelledby="titulo-generales">
          <header>
            <p>Resumen operativo</p>
            <h2 id="titulo-generales">Datos generales</h2>
          </header>
          <dl class="detalle__metricas">
            <div>
              <dt>Usuarios</dt>
              <dd>
                {{ empresa.usuarios == null ? 'Sin datos' : formatearNumero(empresa.usuarios) }}
              </dd>
            </div>
            <div>
              <dt>Fecha de registro</dt>
              <dd>{{ formatearFecha(empresa.fechaRegistro) }}</dd>
            </div>
          </dl>
        </section>

        <section class="detalle__panel gb-tarjeta" aria-labelledby="titulo-marca">
          <header>
            <p>Configuración visual</p>
            <h2 id="titulo-marca">Identidad visual</h2>
          </header>
          <dl class="detalle__colores">
            <div>
              <dt>Principal</dt>
              <dd>
                <span :style="{ backgroundColor: empresa.colorPrimario }"></span>
                <span>{{ empresa.colorPrimario }}</span>
              </dd>
            </div>
            <div>
              <dt>Secundario</dt>
              <dd>
                <span :style="{ backgroundColor: empresa.colorSecundario }"></span>
                <span>{{ empresa.colorSecundario }}</span>
              </dd>
            </div>
          </dl>
        </section>
      </aside>
    </div>

    <section class="detalle__panel gb-tarjeta" aria-labelledby="titulo-horarios">
      <header>
        <p>Atención al público</p>
        <h2 id="titulo-horarios"><Clock3 :size="17" aria-hidden="true" /> Horarios semanales</h2>
      </header>
      <dl class="detalle__horarios">
        <div v-for="dia in DIAS" :key="dia.valor">
          <dt>{{ dia.etiqueta }}</dt>
          <dd>
            <template
              v-if="empresa[`horario_inicio_${dia.valor}`] && empresa[`horario_fin_${dia.valor}`]"
            >
              {{ empresa[`horario_inicio_${dia.valor}`] }}–{{ empresa[`horario_fin_${dia.valor}`] }}
            </template>
            <span v-else>Sin información</span>
          </dd>
        </div>
      </dl>
    </section>
  </div>
</template>

<style scoped>
.detalle {
  display: grid;
  gap: var(--gb-gutter, 1.25rem);
}

.detalle__resumen {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr) auto;
  align-items: center;
  gap: 1.25rem;
  padding: 1.5rem;
  border-radius: var(--gb-radius-xl);
}

.detalle__resumen p,
.detalle__resumen h2,
.detalle__resumen span {
  margin: 0;
}

.detalle__resumen p,
.detalle__panel header p {
  color: var(--gb-red-text);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.detalle__resumen h2 {
  margin-top: 0.25rem;
  font-size: var(--gb-tipo-lg);
  text-transform: uppercase;
}

.detalle__resumen div > span {
  display: block;
  margin-top: 0.25rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}

/* Rejilla principal con tarjetas al mismo nivel */
.detalle__rejilla {
  display: grid;
  grid-template-columns: minmax(0, 1.4fr) minmax(20rem, 1fr);
  gap: var(--gb-gutter, 1.25rem);
  align-items: stretch;
}

.detalle__lateral {
  display: grid;
  grid-template-rows: 1fr 1fr;
  gap: var(--gb-gutter, 1.25rem);
  height: 100%;
}

.detalle__panel {
  min-width: 0;
  padding: 1.25rem 1.5rem;
  border-radius: var(--gb-radius-xl);
  display: flex;
  flex-direction: column;
}

.detalle__panel--principal {
  height: 100%;
}

.detalle__panel header {
  min-height: 3.5rem;
  padding-bottom: 0.875rem;
  border-bottom: 1px solid var(--gb-border);
  flex-shrink: 0;
}

.detalle__panel header p,
.detalle__panel header h2 {
  margin: 0;
}

.detalle__panel header h2 {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  margin-top: 0.125rem;
  font-size: var(--gb-tipo-md);
  text-transform: uppercase;
}

.detalle__panel dl {
  flex: 1;
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  align-content: space-between;
  gap: 0;
  margin: 0;
}

.detalle__panel dl > div {
  min-width: 0;
  padding: 0.85rem 0;
  border-bottom: 1px solid var(--gb-border);
}

.detalle__panel dl > div:last-child {
  border-bottom: 0;
}

.detalle__panel dl > div:nth-child(even):not(.detalle__completo) {
  padding-left: 1rem;
}

.detalle__panel dl > div:nth-child(odd):not(.detalle__completo) {
  padding-right: 1rem;
}

.detalle__panel .detalle__completo {
  grid-column: 1 / -1;
  padding-right: 0;
  padding-left: 0;
}

.detalle__panel dt {
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.detalle__panel dd {
  margin: 0.25rem 0 0;
  overflow-wrap: anywhere;
  color: var(--gb-text);
  font-size: var(--gb-tipo-sm);
}

.detalle__panel a {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  color: var(--gb-red-text);
  text-decoration: none;
}

.detalle__panel a:hover {
  color: var(--gb-link-hover);
  text-decoration: underline;
}

.detalle__metricas {
  grid-template-columns: 1fr !important;
  align-content: space-around;
}

.detalle__metricas > div {
  padding: 0.75rem 0 !important;
}

.detalle__metricas dd {
  font-family: var(--gb-fuente-titulo);
  font-size: var(--gb-tipo-lg);
  font-variant-numeric: tabular-nums;
  font-weight: 800;
}

.detalle__colores {
  grid-template-columns: 1fr !important;
  align-content: space-around;
}

.detalle__colores > div {
  padding: 0.75rem 0 !important;
}

.detalle__colores dd {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-family: monospace;
}

.detalle__colores dd span:first-child {
  width: 1.5rem;
  height: 1.5rem;
  border: 1px solid var(--gb-border-soft, #404040);
  border-radius: var(--gb-radius, 0.5rem);
  flex-shrink: 0;
}

.detalle__horarios {
  grid-template-columns: repeat(7, minmax(7rem, 1fr)) !important;
  gap: 0.75rem !important;
  margin-top: 0.5rem !important;
}

.detalle__horarios > div {
  padding: 0.75rem !important;
  background-color: var(--gb-surface-lowest);
  border: 1px solid var(--gb-border) !important;
  border-radius: var(--gb-radius-lg);
}

.detalle__horarios dd {
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}

.tabular {
  font-variant-numeric: tabular-nums;
}

@media (max-width: 78rem) {
  .detalle__rejilla {
    grid-template-columns: 1fr;
  }

  .detalle__lateral {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    grid-template-rows: auto;
  }

  .detalle__horarios {
    grid-template-columns: repeat(4, minmax(7rem, 1fr)) !important;
  }
}

@media (max-width: 52rem) {
  .detalle__resumen {
    grid-template-columns: auto minmax(0, 1fr);
  }

  .detalle__resumen > :last-child {
    grid-column: 1 / -1;
    justify-self: start;
  }

  .detalle__lateral,
  .detalle__panel dl {
    grid-template-columns: 1fr;
  }

  .detalle__panel dl > div {
    grid-column: auto;
    padding-right: 0 !important;
    padding-left: 0 !important;
  }

  .detalle__horarios {
    grid-template-columns: repeat(2, minmax(0, 1fr)) !important;
  }
}
</style>
