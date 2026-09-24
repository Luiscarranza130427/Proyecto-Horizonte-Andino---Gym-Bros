export const auditoriaRoutes = [
  {
    path: 'auditoria',
    name: 'auditoria',
    component: () => import('@/views/EnConstruccionView.vue'),
    meta: { title: 'Auditoría', requiresAuth: true },
  },
]
