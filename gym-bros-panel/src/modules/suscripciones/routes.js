export const suscripcionesRoutes = [
  {
    path: 'suscripciones',
    name: 'suscripciones',
    component: () => import('@/views/EnConstruccionView.vue'),
    meta: { title: 'Suscripciones SaaS', requiresAuth: true },
  },
]
