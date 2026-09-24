<script setup>
import { Ban, Eye, Pencil } from 'lucide-vue-next'
import { computed } from 'vue'
import { RouterLink } from 'vue-router'

import UsuarioAvatar from '@/modules/usuarios/components/UsuarioAvatar.vue'
import UsuarioStatusBadge from '@/modules/usuarios/components/UsuarioStatusBadge.vue'
import { formatearFecha, formatearNumero } from '@/shared/utils/formato'

const props = defineProps({
  items: { type: Array, required: true },
  paginacion: { type: Object, required: true },
  cargando: { type: Boolean, default: false },
})

defineEmits(['cambiar-pagina', 'desactivar'])

const paginas = computed(() => {
  const total = props.paginacion.ultimaPagina
  const actual = props.paginacion.pagina
  if (total <= 5) return Array.from({ length: total }, (_, indice) => indice + 1)

  let inicio = Math.max(1, actual - 2)
  const fin = Math.min(total, inicio + 4)
  inicio = Math.max(1, fin - 4)
  return Array.from({ length: fin - inicio + 1 }, (_, indice) => inicio + indice)
})

const etiquetasRol = {
  admin: 'Administrador',
  administrator: 'Administrador',
  manager: 'Empresa',
  company: 'Empresa',
  trainer: 'Entrenador',
  member: 'Usuario',
  user: 'Usuario',
}

const etiquetasDocumento = { dni: 'DNI', passport: 'Pasaporte', other: 'Otro' }

function nombreCompleto(usuario) {
  return [usuario.nombre, usuario.apellido].filter(Boolean).join(' ')
}

function etiquetaRol(rol) {
  return etiquetasRol[rol] ?? rol ?? 'Sin rol'
}

function etiquetaDocumento(tipo) {
  return etiquetasDocumento[tipo] ?? tipo ?? 'Documento'
}
</script>

<template>
  <section class="tabla gb-tarjeta" aria-label="Listado de usuarios" :aria-busy="cargando">
    <div class="tabla__desplazamiento">
      <table>
        <caption class="visually-hidden">
          Usuarios registrados en Gym Bros
        </caption>
        <thead>
          <tr>
            <th scope="col">Usuario</th>
            <th scope="col" class="tabla__secundaria">Documento</th>
            <th scope="col">Empresa</th>
            <th scope="col">Rol</th>
            <th scope="col">Estado</th>
            <th scope="col" class="tabla__secundaria">Registro</th>
            <th scope="col" class="tabla__acciones-titulo">Acciones</th>
          </tr>
        </thead>
        <tbody v-if="cargando">
          <tr v-for="fila in 6" :key="fila" class="tabla__skeleton" aria-hidden="true">
            <td><span class="skeleton skeleton--usuario"></span></td>
            <td class="tabla__secundaria"><span class="skeleton"></span></td>
            <td><span class="skeleton"></span></td>
            <td><span class="skeleton skeleton--corto"></span></td>
            <td><span class="skeleton skeleton--corto"></span></td>
            <td class="tabla__secundaria"><span class="skeleton"></span></td>
            <td><span class="skeleton skeleton--acciones"></span></td>
          </tr>
        </tbody>
        <tbody v-else>
          <tr v-for="usuario in items" :key="usuario.id">
            <td>
              <RouterLink
                class="tabla__usuario"
                :to="{ name: 'usuario-detalle', params: { id: usuario.id } }"
              >
                <UsuarioAvatar
                  :nombre="usuario.nombre"
                  :apellido="usuario.apellido"
                  :url="usuario.fotoPerfil"
                />
                <span>
                  <strong>{{ nombreCompleto(usuario) }}</strong>
                  <small v-if="usuario.apodo" class="tabla__apodo">@{{ usuario.apodo }}</small>
                  <small>{{ usuario.correo }}</small>
                </span>
              </RouterLink>
            </td>
            <td class="tabla__secundaria tabla__tabular">
              {{ etiquetaDocumento(usuario.tipoDocumento) }} {{ usuario.numeroDocumento }}
            </td>
            <td>{{ usuario.empresa?.nombre || 'Sin empresa' }}</td>
            <td>{{ etiquetaRol(usuario.rol) }}</td>
            <td><UsuarioStatusBadge :estado="usuario.estado" /></td>
            <td class="tabla__secundaria tabla__fecha">
              {{ formatearFecha(usuario.fechaRegistro) }}
            </td>
            <td>
              <div class="tabla__acciones">
                <RouterLink
                  class="gb-boton-icono"
                  :to="{ name: 'usuario-detalle', params: { id: usuario.id } }"
                  :aria-label="`Ver perfil de ${nombreCompleto(usuario)}`"
                  title="Ver perfil"
                >
                  <Eye :size="16" aria-hidden="true" />
                </RouterLink>
                <RouterLink
                  class="gb-boton-icono"
                  :to="{ name: 'usuario-editar', params: { id: usuario.id } }"
                  :aria-label="`Editar a ${nombreCompleto(usuario)}`"
                  title="Editar"
                >
                  <Pencil :size="16" aria-hidden="true" />
                </RouterLink>
                <button
                  type="button"
                  class="gb-boton-icono tabla__desactivar"
                  :disabled="usuario.estado === 'inactive'"
                  :aria-label="`Desactivar a ${nombreCompleto(usuario)}`"
                  :title="usuario.estado === 'inactive' ? 'Usuario inactivo' : 'Desactivar'"
                  @click="$emit('desactivar', usuario)"
                >
                  <Ban :size="16" aria-hidden="true" />
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <footer v-if="!cargando && paginacion.total" class="tabla__paginacion">
      <p>
        Mostrando {{ formatearNumero(paginacion.desde) }}–{{ formatearNumero(paginacion.hasta) }} de
        {{ formatearNumero(paginacion.total) }} usuarios
      </p>
      <nav aria-label="Paginación de usuarios">
        <button
          type="button"
          class="btn btn-ghost"
          :disabled="paginacion.pagina <= 1"
          @click="$emit('cambiar-pagina', paginacion.pagina - 1)"
        >
          Anterior
        </button>
        <button
          v-for="pagina in paginas"
          :key="pagina"
          type="button"
          class="tabla__pagina"
          :class="{ 'tabla__pagina--activa': pagina === paginacion.pagina }"
          :aria-current="pagina === paginacion.pagina ? 'page' : null"
          :aria-label="`Página ${pagina}`"
          @click="$emit('cambiar-pagina', pagina)"
        >
          {{ pagina }}
        </button>
        <button
          type="button"
          class="btn btn-ghost"
          :disabled="paginacion.pagina >= paginacion.ultimaPagina"
          @click="$emit('cambiar-pagina', paginacion.pagina + 1)"
        >
          Siguiente
        </button>
      </nav>
    </footer>
  </section>
</template>

<style scoped>
.tabla {
  overflow: hidden;
  border-radius: var(--gb-radius-lg);
}

.tabla__desplazamiento {
  max-width: 100%;
  overflow-x: auto;
}

table {
  width: 100%;
  min-width: 72rem;
  border-collapse: collapse;
}

th,
td {
  padding: 0.75rem 0.875rem;
  border-bottom: 1px solid var(--gb-border);
  text-align: left;
  vertical-align: middle;
}

th {
  background-color: var(--gb-surface-lowest);
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  white-space: nowrap;
}

td {
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}

tbody tr {
  background-color: var(--gb-surface);
  transition: background-color 0.18s ease;
}

tbody tr:hover {
  background-color: var(--gb-surface-high-50);
}

tbody tr:last-child td {
  border-bottom: 0;
}

.tabla__usuario {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  min-width: 13rem;
  color: var(--gb-text);
  text-decoration: none;
}

.tabla__usuario > span:last-child {
  min-width: 0;
}

.tabla__usuario strong,
.tabla__usuario small {
  display: block;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.tabla__usuario strong {
  max-width: 13rem;
  font-family: var(--gb-fuente-titulo);
  font-size: var(--gb-tipo-sm);
}

.tabla__usuario small {
  max-width: 13rem;
  margin-top: 0.125rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}

.tabla__usuario:hover strong {
  color: var(--gb-red-text);
}

.tabla__numero {
  text-align: right;
}

.tabla__tabular {
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}

.tabla__fecha {
  white-space: nowrap;
}

.tabla__acciones-titulo {
  text-align: right;
}

.tabla__acciones {
  display: flex;
  justify-content: flex-end;
  gap: 0.25rem;
}

.tabla__acciones .gb-boton-icono {
  width: 2.125rem;
  height: 2.125rem;
  color: var(--gb-text-muted);
  text-decoration: none;
}

.tabla__desactivar:not(:disabled):hover {
  color: var(--gb-error);
}

.tabla__desactivar:disabled {
  cursor: not-allowed;
  opacity: 0.35;
}

.tabla__paginacion {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.875rem 1rem;
  background-color: var(--gb-surface-lowest);
  border-top: 1px solid var(--gb-border);
}

.tabla__paginacion p {
  margin: 0;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}

.tabla__paginacion nav {
  display: flex;
  align-items: center;
  gap: 0.375rem;
}

.tabla__paginacion .btn {
  min-height: 2.125rem;
  padding: 0.375rem 0.75rem;
  font-size: var(--gb-tipo-xxs);
}

.tabla__pagina {
  display: grid;
  place-items: center;
  width: 2.125rem;
  height: 2.125rem;
  background-color: transparent;
  border: 1px solid transparent;
  border-radius: var(--gb-radius);
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}

.tabla__pagina:hover {
  background-color: var(--gb-surface-high);
  color: var(--gb-text);
}

.tabla__pagina--activa {
  background-color: var(--gb-red);
  color: var(--gb-on-red);
}

.tabla__skeleton:hover {
  background-color: var(--gb-surface);
}

.skeleton {
  display: block;
  width: 6rem;
  height: 0.75rem;
  background-color: var(--gb-surface-highest);
  border-radius: var(--gb-radius-pill);
  animation: pulso 1.2s ease-in-out infinite alternate;
}

.skeleton--usuario {
  width: 12rem;
  height: 2.5rem;
  border-radius: var(--gb-radius);
}

.skeleton--corto {
  width: 3.5rem;
}

.skeleton--acciones {
  width: 6rem;
  margin-left: auto;
}

@keyframes pulso {
  to {
    opacity: 0.45;
  }
}

@media (max-width: 90rem) {
  .tabla__secundaria {
    display: none;
  }

  table {
    min-width: 50rem;
  }
}

@media (max-width: 64rem) {
  th:nth-child(4),
  td:nth-child(4),
  th:nth-child(6),
  td:nth-child(6) {
    display: none;
  }

  table {
    min-width: 41rem;
  }

  .tabla__paginacion {
    align-items: flex-start;
    flex-direction: column;
  }
}
</style>
