export const empresasRoutes = [
  {
    path: 'empresas',
    name: 'empresas',
    redirect: { name: 'empresas-listado' },
    meta: { title: 'Empresas', requiresAuth: true },
    children: [
      {
        path: '',
        name: 'empresas-listado',
        component: () => import('@/modules/empresas/views/EmpresasView.vue'),
        meta: { title: 'Empresas', requiresAuth: true },
      },
      {
        path: 'nueva',
        name: 'empresa-nueva',
        component: () => import('@/modules/empresas/views/EmpresaCreateView.vue'),
        meta: { title: 'Nueva empresa', requiresAuth: true },
      },
      {
        path: ':id',
        name: 'empresa-detalle',
        component: () => import('@/modules/empresas/views/EmpresaDetailView.vue'),
        props: true,
        meta: { title: 'Detalle empresa', requiresAuth: true },
      },
      {
        path: ':id/editar',
        name: 'empresa-editar',
        component: () => import('@/modules/empresas/views/EmpresaEditView.vue'),
        props: true,
        meta: { title: 'Editar empresa', requiresAuth: true },
      },
    ],
  },
]
