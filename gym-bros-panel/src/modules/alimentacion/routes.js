import { RouterView } from 'vue-router'

export const alimentacionRoutes = [
  {
    path: 'alimentacion',
    name: 'alimentacion',
    component: RouterView,
    redirect: { name: 'alimentacion-listado' },
    meta: { title: 'Alimentación', requiresAuth: true },
    children: [
      {
        path: '',
        name: 'alimentacion-listado',
        component: () => import('@/modules/alimentacion/views/PlanesView.vue'),
        meta: { title: 'Planes de alimentación', requiresAuth: true },
      },
      {
        path: 'planes/:id',
        name: 'plan-alimentacion-detalle',
        component: () => import('@/modules/alimentacion/views/PlanDetailView.vue'),
        meta: { title: 'Plan de alimentación', requiresAuth: true },
      },
      {
        path: 'planes/:idPlan/comidas/nueva',
        name: 'comida-nueva',
        component: () => import('@/modules/alimentacion/views/ComidaCreateView.vue'),
        meta: { title: 'Nueva comida', requiresAuth: true },
      },
      {
        path: 'planes/:idPlan/comidas/:idComida/editar',
        name: 'comida-editar',
        component: () => import('@/modules/alimentacion/views/ComidaEditView.vue'),
        meta: { title: 'Editar comida', requiresAuth: true },
      },
      {
        path: 'alimentos',
        name: 'alimentos-listado',
        component: () => import('@/modules/alimentacion/views/AlimentosView.vue'),
        meta: { title: 'Catálogo de alimentos', requiresAuth: true },
      },
      {
        path: 'alimentos/nuevo',
        name: 'alimento-nuevo',
        component: () => import('@/modules/alimentacion/views/AlimentoCreateView.vue'),
        meta: { title: 'Nuevo alimento', requiresAuth: true },
      },
      {
        path: 'alimentos/:id/editar',
        name: 'alimento-editar',
        component: () => import('@/modules/alimentacion/views/AlimentoEditView.vue'),
        meta: { title: 'Editar alimento', requiresAuth: true },
      },
      {
        path: 'alimentos/:id',
        name: 'alimento-detalle',
        component: () => import('@/modules/alimentacion/views/AlimentoDetailView.vue'),
        meta: { title: 'Detalle del alimento', requiresAuth: true },
      },
    ],
  },
]
