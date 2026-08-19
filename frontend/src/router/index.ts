import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

declare module 'vue-router' {
  interface RouteMeta {
    requiresAuth?: boolean
    roles?: string[]
  }
}

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'dashboard',
      component: () => import('../views/DashboardView.vue'),
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/LoginView.vue'),
    },
    {
      path: '/register',
      name: 'register',
      component: () => import('../views/RegisterView.vue'),
    },
    {
      path: '/workshops-catalog',
      name: 'attendee-catalog',
      component: () => import('../views/AttendeeCatalogView.vue'),
    },
    {
      path: '/workshops-catalog/:workshopId/sessions',
      name: 'workshop-sessions',
      component: () => import('../views/WorkshopSessions.vue'),
    },
    {
      path: '/workshops-catalog/:workshopId/sessions/:sessionId',
      name: 'workshop-sessions-attendee',
      component: () => import('../views/SessionsView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/sessions',
      name: 'sessions-browse',
      component: () => import('../views/SessionsBrowseView.vue'),
    },
    {
      path: '/workshops',
      name: 'admin-workshops',
      component: () => import('../views/WorkshopAdminView.vue'),
      meta: { requiresAuth: true, roles: ['admin'] },
    },
    {
      path: '/workshops/new',
      name: 'admin-workshop-new',
      component: () => import('../views/WorkshopsNewView.vue'),
      meta: { requiresAuth: true, roles: ['admin'] },
    },
    {
      path: '/workshops/:workshopId/edit',
      name: 'admin-workshop-edit',
      component: () => import('../views/WorkshopsEditView.vue'),
      meta: { requiresAuth: true, roles: ['admin'] },
    },
    {
      path: '/workshops/:workshopId/sessions',
      name: 'admin-workshop-sessions',
      component: () => import('../views/AdminSessionsView.vue'),
      meta: { requiresAuth: true, roles: ['admin'] },
    },
    {
      path: '/workshops/:workshopId/sessions/new',
      name: 'admin-workshop-sessions-new',
      component: () => import('../views/SessionsNewView.vue'),
      meta: { requiresAuth: true, roles: ['admin'] },
    },
    {
      path: '/workshops/:workshopId/sessions/:sessionId/attendees',
      name: 'admin-session-attendees',
      component: () => import('../views/SessionAttendeesView.vue'),
      meta: { requiresAuth: true, roles: ['admin'] },
    },
    {
      path: '/attendee-history',
      name: 'attendee-history',
      component: () => import('../views/AttendeeHistoryView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/components',
      name: 'components-guide',
      component: () => import('../components/ComponentsGuideView.vue'),
    },
  ],
})

router.beforeEach((to) => {
  const auth = useAuthStore()

  if (to.meta.requiresAuth && !auth.isAuthenticated) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }

  if (to.meta.roles && !to.meta.roles.includes(auth.user?.role ?? '')) {
    return { name: 'dashboard' }
  }

  if ((to.name === 'login' || to.name === 'register') && auth.isAuthenticated) {
    return { name: 'dashboard' }
  }

  return true
})

export default router