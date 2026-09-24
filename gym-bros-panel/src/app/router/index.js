import { createRouter, createWebHistory } from 'vue-router'

import { aplicarTitulo, guardAutenticacion, guardPermiso, guardTenant } from '@/app/guards'
import { alimentacionRoutes } from '@/modules/alimentacion/routes'
import { bannersRoutes } from '@/modules/banners/routes'
import { auditoriaRoutes } from '@/modules/auditoria/routes'
import { authRoutes } from '@/modules/auth/routes'
import { billingRoutes } from '@/modules/billing/routes'
import { dashboardRoutes } from '@/modules/dashboard/routes'
import { ejerciciosRoutes } from '@/modules/ejercicios/routes'
import { empresasRoutes } from '@/modules/empresas/routes'
import { membresiasRoutes } from '@/modules/membresias/routes'
import { notificacionesRoutes } from '@/modules/notificaciones/routes'
import { perfilRoutes } from '@/modules/perfil/routes'
import { suscripcionesRoutes } from '@/modules/suscripciones/routes'
import { usuariosRoutes } from '@/modules/usuarios/routes'

const routes = [
  ...authRoutes,
  {
    path: '/',
    component: () => import('@/app/layouts/DashboardLayout.vue'),
    meta: { requiresAuth: true },
    children: [
      { path: '', redirect: { name: 'dashboard' } },
      ...dashboardRoutes,
      ...bannersRoutes,
      ...empresasRoutes,
      ...usuariosRoutes,
      ...ejerciciosRoutes,
      ...alimentacionRoutes,
      ...membresiasRoutes,
      ...notificacionesRoutes,
      ...billingRoutes,
      ...perfilRoutes,
      ...suscripcionesRoutes,
      ...auditoriaRoutes,
    ],
  },
  {
    path: '/403',
    name: 'forbidden',
    component: () => import('@/views/ForbiddenView.vue'),
    meta: { title: 'Acceso restringido' },
  },
  {
    path: '/500',
    name: 'server-error',
    component: () => import('@/views/ServerErrorView.vue'),
    meta: { title: 'Error del servidor' },
  },
  {
    path: '/404',
    name: 'not-found',
    component: () => import('@/views/NotFoundView.vue'),
    meta: { title: 'Página no encontrada' },
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'catch-all',
    component: () => import('@/views/NotFoundView.vue'),
    meta: { title: 'Página no encontrada' },
  },
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
  scrollBehavior: () => ({ top: 0 }),
})

router.beforeEach(guardAutenticacion)
router.beforeEach(guardTenant)
router.beforeEach(guardPermiso)
router.afterEach(aplicarTitulo)

export default router
