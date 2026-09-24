export const notificacionesRoutes = [
  {
    path: 'notificaciones',
    name: 'notificaciones',
    component: () => import('@/modules/notificaciones/views/NotificacionesView.vue'),
    meta: { title: 'Notificaciones', requiresAuth: true },
  },
]
