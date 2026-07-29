import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: () => import('../views/HomeView.vue'),
    },
    {
      path: '/components',
      name: 'components-guide',
      component: () => import('../components/ComponentsGuideView.vue'),
    },
    {
      path: '/workshops',
      name: 'workshops',
      component: () => import('../views/WorkshopsView.vue'),
    },
    {
      path: '/workshops/:id/sessions',
      name: 'workshop-sessions',
      component: () => import('../views/WorkshopSessionsView.vue'),
    },
    {
      path: '/attendees',
      name: 'attendees',
      component: () => import('../views/AttendeesView.vue'),
    },
  ],
})

export default router
