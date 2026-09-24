import {
  Bell,
  Building2,
  ClipboardCheck,
  CreditCard,
  Dumbbell,
  Image,
  LayoutGrid,
  User,
  Users,
  Utensils,
} from 'lucide-vue-next'

export const SECCIONES = [
  {
    name: 'dashboard',
    path: 'dashboard',
    title: 'Dashboard',
    icono: LayoutGrid,
    vista: () => import('@/modules/dashboard/views/DashboardView.vue'),
  },
  {
    name: 'empresas',
    path: 'empresas',
    title: 'Empresas',
    icono: Building2,
    arbolPropio: true,
  },
  {
    name: 'usuarios',
    path: 'usuarios',
    title: 'Usuarios',
    icono: Users,
    arbolPropio: true,
  },
  {
    name: 'ejercicios',
    path: 'ejercicios',
    title: 'Ejercicios',
    icono: Dumbbell,
    arbolPropio: true,
  },
  {
    name: 'alimentacion',
    path: 'alimentacion',
    title: 'Alimentación',
    icono: Utensils,
    arbolPropio: true,
  },
  {
    name: 'notificaciones',
    path: 'notificaciones',
    title: 'Notificaciones',
    icono: Bell,
    vista: () => import('@/modules/notificaciones/views/NotificacionesView.vue'),
  },
  {
    name: 'banners',
    path: 'banners',
    title: 'Banners',
    icono: Image,
    arbolPropio: true,
  },
  {
    name: 'planes',
    path: 'planes',
    title: 'Planes',
    icono: ClipboardCheck,
    arbolPropio: true,
  },
  {
    name: 'planes-administrar',
    path: 'planes/administrar',
    title: 'Administrar planes',
    icono: ClipboardCheck,
    permission: 'memberships.manage',
  },
  {
    name: 'pagos',
    path: 'pagos',
    title: 'Reportes de pagos',
    icono: CreditCard,
    vista: null,
  },
]

export const SECCIONES_DE_USUARIO = [
  {
    name: 'perfil',
    path: 'perfil',
    title: 'Mi perfil',
    icono: User,
    vista: () => import('@/modules/perfil/views/PerfilView.vue'),
  },
]
