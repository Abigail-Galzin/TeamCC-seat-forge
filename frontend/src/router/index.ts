import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'dashboard',
      component: () => import('../views/DashboardView.vue'),
    },
    {
      path: '/workshops-catalog',
      name: 'attendee-catalog',
      component: () => import('../views/AttendeeCatalogView.vue'),
    },
    {
      path: '/workshops-catalog/:workshopId/sessions',
      name: 'attendee-workshop-sessions',
      component: () => import('../views/SessionsView.vue'),
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
    },
    {
      path: '/workshops/new',
      name: 'admin-workshop-new',
      component: () => import('../views/WorkshopsNewView.vue'),
    },
    {
      path: '/workshops/:workshopId/edit',
      name: 'admin-workshop-edit',
      component: () => import('../views/WorkshopsEditView.vue'),
    },
    {
      path: '/workshops/:workshopId/sessions',
      name: 'admin-workshop-sessions',
      component: () => import('../views/AdminSessionsView.vue'),
    },
    {
      path: '/workshops/:workshopId/sessions/new',
      name: 'admin-workshop-sessions-new',
      component: () => import('../views/SessionsNewView.vue'),
    },
    {
      path: '/sessions/:sessionId/attendees',
      name: 'admin-session-attendees',
      component: () => import('../views/SessionAttendeesView.vue'),
    },
    {
      path: '/attendee-history',
      name: 'attendee-history',
      component: () => import('../views/AttendeeHistoryView.vue'),
    },
    {
      path: '/components',
      name: 'components-guide',
      component: () => import('../components/ComponentsGuideView.vue'),
    },
  ],
})

export default router
