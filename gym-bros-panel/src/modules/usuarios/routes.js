export const usuariosRoutes = [
  {
    path: 'usuarios',
    name: 'usuarios',
    redirect: { name: 'usuarios-listado' },
    meta: { title: 'Usuarios', requiresAuth: true },
    children: [
      {
        path: '',
        name: 'usuarios-listado',
        component: () => import('@/modules/usuarios/views/UsuariosView.vue'),
        meta: { title: 'Usuarios', requiresAuth: true },
      },
      {
        path: 'nuevo',
        name: 'usuario-nuevo',
        component: () => import('@/modules/usuarios/views/UsuarioCreateView.vue'),
        meta: { title: 'Nuevo usuario', requiresAuth: true },
      },
      {
        path: ':id',
        name: 'usuario-detalle',
        component: () => import('@/modules/usuarios/views/UsuarioDetailView.vue'),
        props: true,
        meta: { title: 'Perfil de usuario', requiresAuth: true },
      },
      {
        path: ':id/plan-alimentacion',
        name: 'usuario-plan-alimentacion',
        component: () => import('@/modules/usuarios/views/UsuarioPlanAlimentacionView.vue'),
        props: true,
        meta: { title: 'Plan de alimentación', requiresAuth: true },
      },
      {
        path: ':id/editar',
        name: 'usuario-editar',
        component: () => import('@/modules/usuarios/views/UsuarioEditView.vue'),
        props: true,
        meta: { title: 'Editar usuario', requiresAuth: true },
      },
    ],
  },
]
