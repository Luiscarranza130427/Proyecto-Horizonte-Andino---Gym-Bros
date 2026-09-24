export const billingRoutes = [
  {
    path: 'pagos',
    name: 'pagos',
    component: () => import('@/modules/billing/views/PagosView.vue'),
    meta: { title: 'Reportes de pagos', requiresAuth: true },
  },
]
