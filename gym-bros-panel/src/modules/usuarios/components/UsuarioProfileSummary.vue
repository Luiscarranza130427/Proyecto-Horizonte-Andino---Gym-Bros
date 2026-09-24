<script setup>
import { ArrowUpRight, IdCard, ShieldCheck } from 'lucide-vue-next'
import { computed } from 'vue'
import { RouterLink } from 'vue-router'

import UsuarioAvatar from '@/modules/usuarios/components/UsuarioAvatar.vue'
import UsuarioStatusBadge from '@/modules/usuarios/components/UsuarioStatusBadge.vue'
import { formatearFecha } from '@/shared/utils/formato'

const props = defineProps({
  usuario: { type: Object, required: true },
})

const nombreCompleto = computed(
  () =>
    [props.usuario.nombre, props.usuario.apellido].filter(Boolean).join(' ').trim() ||
    'Usuario sin nombre',
)
const empresa = computed(() => props.usuario.empresa ?? null)

const etiquetasRol = {
  admin: 'Administrador',
  administrator: 'Administrador',
  administrador: 'Administrador',
  company: 'Empresa',
  empresa: 'Empresa',
  manager: 'Empresa',
  trainer: 'Entrenador',
  entrenador: 'Entrenador',
  user: 'Usuario',
  usuario: 'Usuario',
  member: 'Usuario',
}
const etiquetasDocumento = { dni: 'DNI', passport: 'Pasaporte', other: 'Otro' }

const rolLegible = computed(
  () => etiquetasRol[props.usuario.rol] ?? props.usuario.rol ?? 'No especificado',
)

function fechaLegible(fecha) {
  return fecha ? formatearFecha(fecha) : 'No especificada'
}
</script>

<template>
  <div class="perfil">
    <!-- Cabecera de perfil -->
    <section class="perfil__cabecera gb-tarjeta" aria-labelledby="usuario-nombre">
      <UsuarioAvatar
        :nombre="usuario.nombre"
        :apellido="usuario.apellido"
        :url="usuario.fotoPerfil"
        grande
      />

      <div class="perfil__identidad">
        <p>Perfil administrativo</p>
        <h2 id="usuario-nombre">{{ nombreCompleto }}</h2>
        <span v-if="usuario.apodo" class="perfil__apodo">@{{ usuario.apodo }}</span>
        <div class="perfil__metadatos">
          <UsuarioStatusBadge :estado="usuario.estado" />
          <span class="perfil__rol"
            ><ShieldCheck :size="14" aria-hidden="true" />{{ rolLegible }}</span
          >
        </div>
      </div>

      <div class="perfil__empresa">
        <span>Empresa</span>
        <RouterLink
          v-if="empresa?.id && empresa?.nombre"
          :to="{ name: 'empresa-detalle', params: { id: empresa.id } }"
        >
          {{ empresa.nombre }}
          <ArrowUpRight :size="14" aria-hidden="true" />
        </RouterLink>
        <strong v-else>{{ empresa?.nombre || 'No asignada' }}</strong>
      </div>
    </section>

    <!-- Rejilla nivelada de datos principales -->
    <div class="perfil__rejilla">
      <!-- Tarjeta izquierda: Información personal (nivelada a altura 100%) -->
      <section
        class="perfil__panel perfil__panel--principal gb-tarjeta"
        aria-labelledby="titulo-personal"
      >
        <header>
          <span class="perfil__icono"><IdCard :size="18" aria-hidden="true" /></span>
          <div>
            <p>Datos de gestión</p>
            <h2 id="titulo-personal">Información personal</h2>
          </div>
        </header>

        <dl class="perfil__datos">
          <div>
            <dt>Nombres</dt>
            <dd>{{ usuario.nombre || 'No especificados' }}</dd>
          </div>
          <div>
            <dt>Apellidos</dt>
            <dd>{{ usuario.apellido || 'No especificados' }}</dd>
          </div>
          <div>
            <dt>Apodo</dt>
            <dd>{{ usuario.apodo || 'No especificado' }}</dd>
          </div>
          <div>
            <dt>Género</dt>
            <dd>
              {{ usuario.genero === 'Varon' ? 'Varón' : usuario.genero || 'No especificado' }}
            </dd>
          </div>
          <div>
            <dt>Correo</dt>
            <dd>
              <a v-if="usuario.correo" :href="`mailto:${usuario.correo}`">{{ usuario.correo }}</a>
              <span v-else>No especificado</span>
            </dd>
          </div>
          <div>
            <dt>Teléfono</dt>
            <dd>
              <a v-if="usuario.telefono" :href="`tel:${usuario.telefono}`">{{
                usuario.telefono
              }}</a>
              <span v-else>No especificado</span>
            </dd>
          </div>
          <div>
            <dt>Tipo de documento</dt>
            <dd>
              {{
                etiquetasDocumento[usuario.tipoDocumento] ||
                usuario.tipoDocumento ||
                'No especificado'
              }}
            </dd>
          </div>
          <div>
            <dt>Número de documento</dt>
            <dd class="tabular">{{ usuario.numeroDocumento || 'No especificado' }}</dd>
          </div>
          <div>
            <dt>Fecha de nacimiento</dt>
            <dd>{{ fechaLegible(usuario.fechaNacimiento) }}</dd>
          </div>
          <div>
            <dt>Inicio de suscripción</dt>
            <dd>{{ fechaLegible(usuario.inicioSuscripcion) }}</dd>
          </div>
          <div>
            <dt>Fin de suscripción</dt>
            <dd>{{ fechaLegible(usuario.finSuscripcion) }}</dd>
          </div>
          <div class="perfil__dato-completo">
            <dt>Dirección</dt>
            <dd>{{ usuario.direccion || 'No especificada' }}</dd>
          </div>
          <div>
            <dt>Empresa</dt>
            <dd>{{ empresa?.nombre || 'No asignada' }}</dd>
          </div>
          <div>
            <dt>ID de empresa</dt>
            <dd>{{ empresa?.id ?? 'No asignada' }}</dd>
          </div>
        </dl>
      </section>
    </div>
  </div>
</template>

<style scoped>
.perfil {
  display: grid;
  gap: var(--gb-gutter, 1.25rem);
}

.perfil__cabecera {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr) minmax(12rem, auto);
  align-items: center;
  gap: 1.25rem;
  padding: 1.5rem;
  border-radius: var(--gb-radius-xl);
}

.perfil__identidad > p,
.perfil__identidad h2,
.perfil__empresa > span,
.perfil__empresa strong {
  margin: 0;
}

.perfil__identidad > p,
.perfil__panel header p,
.perfil__empresa > span {
  color: var(--gb-red-text);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.perfil__identidad h2 {
  margin-top: 0.25rem;
  font-size: var(--gb-tipo-lg);
  text-transform: uppercase;
}

.perfil__metadatos {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.5rem;
  margin-top: 0.625rem;
}

.perfil__apodo {
  display: block;
  margin-top: 0.2rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}

.perfil__rol {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
  font-weight: 600;
}

.perfil__empresa {
  min-width: 0;
  padding-left: 1.25rem;
  border-left: 1px solid var(--gb-border);
}

.perfil__empresa > span {
  display: block;
}

.perfil__empresa a,
.perfil__empresa strong {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  margin-top: 0.375rem;
  overflow-wrap: anywhere;
  color: var(--gb-text);
  font-size: var(--gb-tipo-sm);
  font-weight: 700;
  text-decoration: none;
}

.perfil__empresa a:hover {
  color: var(--gb-link-hover);
  text-decoration: underline;
}

/* Rejilla principal con tarjetas al mismo nivel */
.perfil__rejilla {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  align-items: stretch;
  gap: var(--gb-gutter, 1.25rem);
}

.perfil__panel {
  min-width: 0;
  padding: 1.25rem 1.5rem;
  border-radius: var(--gb-radius-xl);
  display: flex;
  flex-direction: column;
}

.perfil__panel--principal {
  height: 100%;
}

.perfil__panel header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  min-height: 3.5rem;
  padding-bottom: 0.875rem;
  border-bottom: 1px solid var(--gb-border);
  flex-shrink: 0;
}

.perfil__panel header > :last-child:not(:nth-child(2)) {
  margin-left: auto;
}

.perfil__panel header p,
.perfil__panel header h2 {
  margin: 0;
}

.perfil__panel header h2 {
  margin-top: 0.125rem;
  font-size: var(--gb-tipo-md);
  text-transform: uppercase;
}

.perfil__icono {
  flex: none;
  display: grid;
  place-items: center;
  width: 2.5rem;
  height: 2.5rem;
  background-color: var(--gb-surface-high);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
  color: var(--gb-red-text);
}

.perfil__panel dl {
  margin: 0;
}

.perfil__datos {
  flex: 1;
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  align-content: space-between;
}

.perfil__datos > div {
  min-width: 0;
  padding: 0.85rem 0;
  border-bottom: 1px solid var(--gb-border);
}

.perfil__datos > div:nth-child(odd):not(.perfil__dato-completo) {
  padding-right: 1rem;
}

.perfil__datos > div:nth-child(even):not(.perfil__dato-completo) {
  padding-left: 1rem;
}

.perfil__datos .perfil__dato-completo {
  grid-column: 1 / -1;
}

.perfil__datos > div:last-child {
  border-bottom: 0;
}

.perfil__panel dt {
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.perfil__panel dd {
  margin: 0.25rem 0 0;
  overflow-wrap: anywhere;
  color: var(--gb-text);
  font-size: var(--gb-tipo-sm);
}

.perfil__panel dd a {
  color: var(--gb-red-text);
  text-decoration: none;
}

.perfil__panel dd a:hover {
  color: var(--gb-link-hover);
  text-decoration: underline;
}

.tabular {
  font-variant-numeric: tabular-nums;
}

@media (max-width: 52rem) {
  .perfil__cabecera {
    grid-template-columns: auto minmax(0, 1fr);
  }

  .perfil__empresa {
    grid-column: 1 / -1;
    padding-top: 1rem;
    padding-left: 0;
    border-top: 1px solid var(--gb-border);
    border-left: 0;
  }

  .perfil__datos {
    grid-template-columns: 1fr;
  }

  .perfil__datos > div {
    grid-column: auto;
    padding-right: 0 !important;
    padding-left: 0 !important;
  }
}

@media (max-width: 34rem) {
  .perfil__cabecera {
    grid-template-columns: 1fr;
  }
}
</style>
