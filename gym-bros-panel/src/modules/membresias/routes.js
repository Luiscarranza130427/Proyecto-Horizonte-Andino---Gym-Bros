export const membresiasRoutes = [
  {
    path: 'planes',
    name: 'planes',
    redirect: { name: 'planes-listado' },
    meta: { title: 'Planes', requiresAuth: true },
    children: [
      {
        path: '',
        name: 'planes-listado',
        component: () => import('@/modules/membresias/views/PlanesView.vue'),
        meta: { title: 'Planes', requiresAuth: true },
      },
      {
        path: 'administrar',
        name: 'planes-administrar',
        component: () => import('@/modules/membresias/views/PlanesView.vue'),
        props: { esAdministracion: true },
        meta: {
          title: 'Administrar planes',
          requiresAuth: true,
          permission: 'memberships.manage',
        },
      },
      {
        path: 'nuevo',
        name: 'plan-nuevo',
        component: () => import('@/modules/membresias/views/PlanCreateView.vue'),
        meta: { title: 'Nuevo plan', requiresAuth: true, permission: 'memberships.manage' },
      },
      {
        path: ':id/editar',
        name: 'plan-editar',
        component: () => import('@/modules/membresias/views/PlanEditView.vue'),
        props: true,
        meta: { title: 'Editar plan', requiresAuth: true, permission: 'memberships.manage' },
      },
    ],
  },
]
