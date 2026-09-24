export const dashboardRoutes = [
  {
    path: 'dashboard',
    name: 'dashboard',
    component: () => import('@/modules/dashboard/views/DashboardView.vue'),
    meta: { title: 'Dashboard', requiresAuth: true },
  },
]
